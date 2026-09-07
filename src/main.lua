-- Dawnwalker Controller Tweaks. MIT; see LICENSE.txt.
-- Uses reflected input APIs and a separate personal INI; never writes game settings/saves.
local source = debug.getinfo(1, 'S').source:gsub('^@', '')
local directory = assert(source:match('^(.*[/\\])'), 'Controller Tweaks: missing script directory')
local Config = dofile(directory .. 'Config.lua')
local ConfigStore = dofile(directory .. 'ConfigStore.lua')
local function log(message) print('[ControllerTweaks] ' .. message .. '\n') end
local config, configStopped, configLastError
local function loadConfig()
    if config or configStopped then return end
    local err, status
    config, err, status = ConfigStore.load(directory, Config, log)
    if not config then
        if err ~= configLastError then log(err); configLastError = err end
        configStopped = status ~= 'retry'
    elseif not config.enabled then
        log('Runtime remapping disabled by personal/default configuration.')
        configStopped = true
    end
end
loadConfig()
if configStopped then return end

local function live(object)
    if object == nil then return false end
    local ok, valid = pcall(function() return object:IsValid() end)
    return ok and valid == true
end
local function unwrap(value)
    if value == nil then return nil end
    local ok, result = pcall(function() return value:get() end)
    if ok then return result end
    return value
end
local function name(value)
    value = unwrap(value)
    if type(value) == 'string' then return value end
    return value:ToString()
end
local function each(array, callback)
    if type(array) == 'table' and type(array.ForEach) ~= 'function' then
        for _, value in ipairs(array) do callback(unwrap(value)) end
    else
        array:ForEach(function(_, value) callback(unwrap(value)) end)
    end
end
local function keyName(key) return name(key.KeyName) end
local presetPath = '/Game/_Dawnwalker/Player/Input/Presets/RIP_GamepadDefault.RIP_GamepadDefault'
local alternatePath = '/Game/_Dawnwalker/Player/Input/Presets/RIP_GamepadAlternate.RIP_GamepadAlternate'
local lastError, announced = nil, false
local bindingIds = {}
local function same(a, b)
    return live(a) and live(b) and a:GetAddress() == b:GetAddress()
end

-- A single registered game-thread worker owns all reflected reads and writes.
-- Each step reacquires borrowed arrays/structs. Only scalars and UObject references
-- survive a callback. At most 32 steps and one rebuild per engine frame;
-- the 0.5 ms target stops further work after an indivisible native call returns.
local MAX_STEPS, MAX_SECONDS, MAX_JOB_STEPS = 32, 0.0005, 131072
local engine, library, system, gameplay, subsystems, subsystemClass, subsystemKind
local engineAttempts, bootstrapAttempts = 0, 0
local state, job, requested = nil, nil, {}
local running, suspended, stopped, exhausted = false, false, false, false
local retries, lastFrame, nextTry, recoveryContext = 20, nil, 0, nil
local stats = {ticks=0, steps=0, names=0, rebuilds=0, ignored=0, maxMs=0}
local wake, tick

local function cacheContext(context,index)
    local id=context:GetAddress()
    if not state.indices[id] then
        state.slot=(state.slot or 0)%128+1
        local old=state.slots[state.slot]
        if old then state.indices[old]=nil end
        state.slots[state.slot]=id
    end
    state.indices[id]={object=context,index=index}
end

local function at(array, index)
    -- UE4SS's TArray indexer grows the array on an out-of-range READ.
    if index < 1 or index > #array then return nil end
    return unwrap(array[index])
end

local function bootstrap()
    if not live(engine) then
        if engineAttempts >= 3 then return false end
        engineAttempts = engineAttempts + 1
        engine = FindFirstOf('Engine') -- bootstrap only; never search for player/subsystem objects
    end
    if not live(engine) then return false end
    if subsystemKind and live(library) and live(system) and live(gameplay) and live(subsystems) and live(subsystemClass) then return true end
    if bootstrapAttempts >= 3 then return false end
    bootstrapAttempts = bootstrapAttempts + 1
    library = StaticFindObject('/Script/EnhancedInput.Default__EnhancedInputLibrary')
    system = StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
    gameplay = StaticFindObject('/Script/Engine.Default__GameplayStatics')
    subsystems = StaticFindObject('/Script/Engine.Default__SubsystemBlueprintLibrary')
    subsystemClass = StaticFindObject('/Script/RebelInput.RebelInputMappingSubsystem')
    if not (live(library) and live(system) and live(gameplay) and live(subsystems) and live(subsystemClass)) then return false end
    -- Select the native owner accessor from reflected inheritance, not a guessed
    -- world or a global array that may still contain the previous world's objects.
    local cls = subsystemClass
    for _=1,16 do
        if not live(cls) then break end
        local n = cls:GetFName():ToString()
        if n == 'LocalPlayerSubsystem' or n == 'WorldSubsystem' or n == 'GameInstanceSubsystem' then
            subsystemKind = n; return true
        end
        cls = cls:GetSuperStruct()
    end
    error('Unsupported input subsystem owner; remapping stopped.')
end

local function currentWorld()
    if not live(engine) then return nil end
    local viewport = engine.GameViewport
    if not live(viewport) then return nil end
    local world = viewport:GetWorld()
    return live(world) and world or nil
end

local function resolve(world)
    if subsystemKind == 'WorldSubsystem' then
        return subsystems:GetWorldSubsystem(world, subsystemClass)
    elseif subsystemKind == 'GameInstanceSubsystem' then
        return subsystems:GetGameInstanceSubsystem(world, subsystemClass)
    else
        local controller = gameplay:GetPlayerController(world, 0)
        if not live(controller) or not same(controller:GetWorld(), world) or not controller:IsLocalController() then return nil end
        return subsystems:GetLocalPlayerSubSystemFromPlayerController(controller, subsystemClass)
    end
end

local function reset()
    state, job, requested = nil, nil, {}
    retries, exhausted, nextTry, recoveryContext = 20, false, 0, nil
    bootstrapAttempts = 0
    if not live(engine) then engineAttempts = 0 end
end

local function validState()
    return state and same(currentWorld(), state.world) and live(state.object)
        and same(state.object:GetWorld(), state.world) and same(state.object:GetOuter(), state.owner)
        and same(resolve(state.world), state.object)
end

local function beginPreset()
    local preset = state.object:GetActiveGamepadPreset()
    if not live(preset) then return false end
    local full = preset:GetFullName()
    local alternative = full:sub(-#alternatePath) == alternatePath
    if not alternative and full:sub(-#presetPath) ~= presetPath then
        state.unsupported = true; return true
    end
    local mappings = preset.PresetMapping
    local inherited = alternative and #mappings == 7
    if not inherited and #mappings ~= 31 then error('Controller preset differs from the supported layout; refusing to patch.') end
    if inherited then
        for action in pairs(Config.alternatePresetEntries) do
            local id = bindingIds[action] or FName(action); bindingIds[action] = id
            if not mappings:Contains(id) then error('Alternative preset is missing original action: '..action) end
        end
    end
    local bindings = alternative and config.alternateBindings or config.bindings
    local actions = {}
    for action, desired in pairs(bindings) do actions[#actions+1] = {action=action,desired=desired} end
    state.preset, state.targets, state.indices, state.slots = preset, {}, {}, {}
    state.slot=0
    state.alternative, state.unsupported = alternative, false
    job = {phase='validate', index=1, actions=actions, changes={}, inherited=inherited, steps=0}
    if not state.conflictReported and bindings.Player_Drink_Blood == bindings.Combat_Attack then
        log('Binding conflict: Player_Drink_Blood and Combat_Attack both use '..bindings.Player_Drink_Blood
            ..'. Choose different buttons in your personal INI so Focus Bite and Death from Above can both work.')
    end
    state.conflictReported = true
    return true
end

local function prepare()
    loadConfig()
    if not config or configStopped or not bootstrap() then return false end
    local world = currentWorld()
    if not live(world) then return false end
    local object = resolve(world)
    if not live(object) or not same(object:GetWorld(),world) then return false end
    local owner = object:GetOuter()
    if not live(owner) then return false end
    state = {object=object, owner=owner, world=world, input=object.InputSystem, indices={}}
    return beginPreset()
end

local function startContext(context, index, all)
    job.context, job.contextIndex, job.all = context, index, all
    job.phase, job.index, job.changed = 'mapping', 1, false
    local mappings = context.Mappings
    job.count, job.address = #mappings, mappings:GetArrayDataAddress()
end

local function step()
    job.steps = job.steps + 1
    if job.steps > MAX_JOB_STEPS then error('Input work limit reached; stopped until the next load or possession.') end
    if job.phase == 'validate' then
        local row = job.actions[job.index]
        if not row then job.phase,job.index='preset',1; return end
        local id = bindingIds[row.action] or FName(row.action); bindingIds[row.action] = id
        local mappings = state.preset.PresetMapping
        local present = mappings:Contains(id)
        if not present and not job.inherited then error('Missing preset action: '..row.action) end
        local actual = present and keyName(unwrap(mappings:Find(id)).Key) or nil
        if actual and actual:sub(1,8) ~= 'Gamepad_' then error('Unexpected preset key for '..row.action) end
        if actual ~= row.desired then job.changes[#job.changes+1] = {id=id,desired=row.desired} end
        local info = state.object:GetMappingInfo(id)
        local aliases = assert(info.MappedActionNames,'Missing MappedActionNames')
        if #aliases > 64 then error('Input alias limit exceeded') end
        local function add(alias)
            alias=name(alias):lower()
            if alias=='' or alias=='none' then error('Invalid mapping name') end
            local previous=state.targets[alias]
            if previous and previous.desired~=row.desired then error('Conflicting controls for shared mapping '..alias) end
            state.targets[alias]={id=id,desired=row.desired}
        end
        add(row.action)
        for i=1,#aliases do add(at(aliases,i)) end
        job.index=job.index+1
    elseif job.phase == 'preset' then
        local change=job.changes[job.index]
        if not change then job.phase,job.index='contexts',1; return end
        local mappings=state.preset.PresetMapping
        mappings:Add(change.id,{Key={KeyName=FName(change.desired)}})
        if keyName(unwrap(mappings:Find(change.id)).Key)~=change.desired then error('Preset write failed') end
        job.index=job.index+1
    elseif job.phase == 'contexts' then
        local contexts=state.object.RebindableContexts
        if job.index > #contexts then
            if #contexts==0 then
                if os.clock()>=nextTry then retries=retries-1;nextTry=os.clock()+0.25 end
                if retries<=0 then exhausted=true;job=nil end
                return true
            end
            job=nil
            if not announced then
                log('Configuration active for the '..(state.alternative and 'Alternative' or 'Default')
                    ..' controller preset. Restart after INI edits.')
                announced=true
            end
            return
        end
        local context=at(contexts,job.index)
        if live(context) then
            cacheContext(context,job.index)
            startContext(context,job.index,true)
        else job.index=job.index+1 end
    elseif job.phase == 'find' then
        -- Membership discovery reads one reference per step, never other mappings.
        local contexts=state.object.RebindableContexts
        if job.index > #contexts then job=nil;return end
        local candidate=at(contexts,job.index)
        if same(candidate,job.target) then
            cacheContext(candidate,job.index)
            startContext(candidate,job.index,false)
        else job.index=job.index+1 end
    elseif job.phase == 'mapping' then
        local context=job.context
        if not live(context) or not same(at(state.object.RebindableContexts,job.contextIndex),context) then
            if job.all then job.phase,job.index='contexts',job.contextIndex+1 else job=nil end
            return
        end
        local mappings=context.Mappings
        if #mappings~=job.count or mappings:GetArrayDataAddress()~=job.address then
            -- Reacquire after a container replacement; never retain a borrowed element.
            job.index,job.count,job.address=1,#mappings,mappings:GetArrayDataAddress()
        end
        if job.index > #mappings then
            local active=job
            if active.changed then
                active.changed=false
                library:RequestRebuildControlMappingsUsingContext(context,false)
                stats.rebuilds=stats.rebuilds+1
            end
            if job~=active then return true end -- a native rebuild can dispatch travel
            if job.all then job.phase,job.index='contexts',job.contextIndex+1 else job=nil end
            return true -- no second rebuild in this engine frame
        end
        local mapping=at(mappings,job.index)
        local current=keyName(mapping.Key)
        if current:sub(1,8)=='Gamepad_' then
            local target=state.targets[name(library:GetMappingName(mapping)):lower()]
            stats.names=stats.names+1
            if target and current~=target.desired then
                mapping.Key=unwrap(state.preset.PresetMapping:Find(target.id)).Key
                if keyName(mapping.Key)~=target.desired then error('Input context write failed') end
                job.changed=true
            end
        end
        job.index=job.index+1
    end
end

local function nextJob()
    local id,context=next(requested)
    if not id then
        if state.rediscover then
            state.rediscover=false
            job={phase='contexts',index=1,steps=0}
        end
        return
    end
    requested[id]=nil
    if not live(context) then return end
    local cached=state.indices[id]
    job={phase='find',index=1,target=context,steps=0}
    if cached and same(cached.object,context) and same(at(state.object.RebindableContexts,cached.index),context) then
        startContext(context,cached.index,false)
    end
end

tick = function()
    if stopped or suspended or configStopped then running=false;return true end
    local started=os.clock()
    stats.ticks=stats.ticks+1
    local ok,err=pcall(function()
        if state and not (live(engine) and live(library) and live(system) and live(gameplay) and live(subsystems) and live(subsystemClass)) then
            state,job,requested=nil,nil,{}
        end
        if not state then
            if os.clock()<nextTry then return end
            nextTry=os.clock()+0.25
            retries=retries-1
            if not prepare() then return end
        end
        local frame=system:GetFrameCount()
        if type(frame)~='number' then error('Frame counter unavailable') end
        if frame==lastFrame then return end
        lastFrame=frame
        if not validState() then
            -- Owner churn must not renew the finite readiness budget indefinitely.
            state,job,requested=nil,nil,{};return
        end
        if not same(state.object:GetActiveGamepadPreset(),state.preset) and not state.unsupported then
            job,requested=nil,{}; if not beginPreset() then state=nil;return end
        end
        if state.unsupported then requested={};return end
        for _=1,MAX_STEPS do
            if os.clock()-started>=MAX_SECONDS then break end
            if not job then nextJob() end
            if not job then break end
            stats.steps=stats.steps+1
            if step() then break end
            if not state then break end
        end
    end)
    local ms=(os.clock()-started)*1000;stats.maxMs=math.max(stats.maxMs,ms)
    if not ok then
        err=tostring(err)
        if err~=lastError then log('Remapping stopped: '..err);lastError=err end
        exhausted=true;job=nil;requested={}
    end
    if retries<=0 and not job then exhausted=true end
    if exhausted or (state and not job and not next(requested) and not state.rediscover) or configStopped then
        running=false
        if config and config.debugLogging then
            log(string.format('Work summary: %d callbacks, %d steps, %d mapping queries, %d rebuilds, %d ignored events; max callback %.3f ms.',
                stats.ticks,stats.steps,stats.names,stats.rebuilds,stats.ignored,stats.maxMs))
        end
        if exhausted and not lastError then log('Input setup not ready; stopped until a new input owner, load or possession.') end
        return true
    end
    return false
end

wake=function()
    if stopped or suspended or configStopped or exhausted or running then return end
    running=true
    LoopInGameThreadWithDelay(16,tick)
end

for _,api in ipairs({'LoopInGameThreadWithDelay','NotifyOnNewObject','RegisterLoadMapPreHook','RegisterLoadMapPostHook','RegisterHook','FindFirstOf','StaticFindObject'}) do
    if type(_G[api])~='function' then log('This UE4SS build lacks '..api..'; remapping disabled.');return end
end
local hookIds={}
local function hook(path,callback)
    local pre,post=RegisterHook(path,function() end,callback)
    assert(type(pre)=='number' and type(post)=='number','Could not register '..path)
    hookIds[#hookIds+1]={path,pre,post}
end
local hooksOK,hookError=pcall(function()
    hook('/Script/Engine.PlayerController:ClientRestart',function(context)
        local controller=unwrap(context)
        if not live(controller) or not controller:IsLocalController() then return end
        local world=currentWorld()
        if not same(controller:GetWorld(),world) then return end
        reset();wake()
    end)
    hook('/Script/EnhancedInput.EnhancedInputSubsystemInterface:AddMappingContext',function(context,mappingContext)
        if stopped or suspended or configStopped then return end
        local caller,target=unwrap(context),unwrap(mappingContext)
        if not state then wake();return end
        if not live(state.object) then state,job,requested=nil,nil,{};wake();return end
        if not same(caller,state.object.InputSystem) or not live(target) then stats.ignored=stats.ignored+1;return end
        if not validState() then state,job,requested=nil,nil,{};wake();return end
        -- Coalesce by native identity; wrapper identity is not stable across callbacks.
        -- A bounded inbox prevents asset/event floods retaining unlimited objects.
        local id=target:GetAddress()
        if exhausted then
            -- A concrete new context can recover late readiness once; repeated
            -- events for the same context cannot renew an exhausted retry chain.
            if recoveryContext==id or lastError then return end
            recoveryContext=id;exhausted=false;retries=20;nextTry=0
        end
        if not requested[id] then
            local count=0;for _ in pairs(requested) do count=count+1 end
            if count>=64 then
                -- Overflow coalesces to one bounded rediscovery instead of losing input.
                state.rediscover=true;wake();return
            end
            requested[id]=target
        end
        wake()
    end)
    local lastConstruction
    NotifyOnNewObject('/Script/RebelInput.RebelInputMappingSubsystem',function(object)
        -- Construction only schedules. Resolve the current owner later, on the game thread.
        if stopped or suspended or configStopped or running or object==lastConstruction then return end
        lastConstruction=object
        -- Keep a successful owner; an unrelated construction must not rebuild it.
        if not state then retries,exhausted,nextTry=20,false,0 end
        wake()
    end)
    RegisterLoadMapPreHook(function() suspended=true;reset() end)
    RegisterLoadMapPostHook(function() suspended=false;reset();wake() end)
end)
if not hooksOK then
    stopped=true
    if type(UnregisterHook)=='function' then for _,ids in ipairs(hookIds) do pcall(UnregisterHook,ids[1],ids[2],ids[3]) end end
    log('Could not register input lifecycle callbacks; remapping disabled: '..tostring(hookError));return
end
wake()
log('Waiting for input setup. Context updates are bounded and scoped to the active player; no continuous polling.')
