-- Dawnwalker Controller Tweaks. MIT; see LICENSE.txt.
-- Uses reflected input APIs and a separate personal INI; never saves game settings.
local source = debug.getinfo(1, 'S').source:gsub('^@', '')
local directory = assert(source:match('^(.*[/\\])'), 'Controller Tweaks: missing script directory')
local Config = dofile(directory .. 'Config.lua')
local ConfigStore = dofile(directory .. 'ConfigStore.lua')
local ControllerProfile = dofile(directory .. 'ControllerProfile.lua')
local Diagnostics = dofile(directory .. 'UE4SSCommonDiagnostics.lua')
local diagnostics = Diagnostics.new({prefix='[ControllerTweaks] ',output=function(text) print(text .. '\n') end})
local function log(message) diagnostics.log(message) end
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
diagnostics = Diagnostics.new({debugLogging=config.debugLogging,prefix='[ControllerTweaks] ',output=function(text) print(text .. '\n') end})

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
local stats = {ticks=0, steps=0, names=0, rebuilds=0, ignored=0, maxMs=0,profileWrites=0}
local wake, tick
local ownerChecked = false
local wakeStarted = 0
local readyAt
local scheduled, scheduleSerial = false, 0
local schedule
local phaseMax = {prepare=0, validate=0, step=0}

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
    readyAt=nil
    retries, exhausted, nextTry, recoveryContext = 20, false, 0, nil
    bootstrapAttempts = 0
    if not live(engine) then engineAttempts = 0 end
end

local function validState(checkOwner)
    return state and same(currentWorld(), state.world) and live(state.object)
        and same(state.object:GetWorld(), state.world) and same(state.object:GetOuter(), state.owner)
        and state.profile and live(state.profile.settings) and live(state.profile.profile)
        and same(state.object.InputSystem:GetUserSettings(),state.profile.settings)
        and same(state.profile.settings:GetCurrentKeyProfile(),state.profile.profile)
        and (not checkOwner or same(resolve(state.world), state.object))
end

local function beginPreset()
    local preset = state.object:GetActiveGamepadPreset()
    if not live(preset) then return false end
    local full = preset:GetFullName()
    local alternative = full:sub(-#alternatePath) == alternatePath
    if not alternative and full:sub(-#presetPath) ~= presetPath then
        state.rediscover=false
        state.preset, state.unsupported = preset, true; return true
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
    state.profileTargets={}
    state.rediscover=false
    state.slot=0
    state.alternative, state.unsupported = alternative, false
    job = {phase='validate', index=1, actions=actions, changes={}, inherited=inherited, steps=0}
    readyAt=readyAt or os.clock()
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
    state.profile=ControllerProfile.acquire(state.input)
    if not state.profile then state=nil;return false end
    if beginPreset() then return true end
    -- A discovered subsystem is not proof that its preset is ready.
    state=nil
    return false
end

local function startContext(context, index, all)
    job.context, job.contextIndex, job.all = context, index, all
    job.phase, job.index, job.changed, job.didRebuild = 'mapping', 1, false, false
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
        if #aliases == 0 or #aliases > 64 then error('Missing or excessive input aliases for '..row.action) end
        local function add(alias,profileAlias)
            alias=name(alias):lower()
            if alias=='' or alias=='none' then error('Invalid mapping name') end
            local previous=state.targets[alias]
            if previous and previous.desired~=row.desired then error('Conflicting controls for shared mapping '..alias) end
            state.targets[alias]={id=id,desired=row.desired}
            if profileAlias then state.profileTargets[alias]=row.desired end
        end
        add(row.action)
        for i=1,#aliases do add(at(aliases,i),true) end
        job.index=job.index+1
    elseif job.phase == 'preset' then
        local change=job.changes[job.index]
        if not change then
            job.profileAliases={};for alias in pairs(state.profileTargets) do job.profileAliases[#job.profileAliases+1]=alias end
            table.sort(job.profileAliases)
            job.phase,job.index='profileCheck',1;return
        end
        local mappings=state.preset.PresetMapping
        mappings:Add(change.id,{Key={KeyName=FName(change.desired)}})
        if keyName(unwrap(mappings:Find(change.id)).Key)~=change.desired then error('Preset write failed') end
        job.index=job.index+1
    elseif job.phase == 'profileCheck' then
        local alias=job.profileAliases[job.index]
        if not alias then job.phase,job.index='profileApply',1;return end
        ControllerProfile.inspect(state.profile,alias,state.profileTargets[alias])
        job.index=job.index+1
    elseif job.phase == 'profileApply' then
        local alias=job.profileAliases[job.index]
        if not alias then
            local changed=job.profileChanged
            if job.profileOnly then job=nil else job.phase,job.index='contexts',1 end
            if changed then ControllerProfile.finish(state.profile);stats.rebuilds=stats.rebuilds+1;return true end
            return
        end
        local changed=ControllerProfile.apply(state.profile,alias,state.profileTargets[alias])
        if changed then
            job.profileChanged=true;stats.profileWrites=stats.profileWrites+1
        end
        job.index=job.index+1
        return changed -- one profile write/readback per frame; native notifications may rebuild
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
                active.didRebuild=true
                library:RequestRebuildControlMappingsUsingContext(context,false)
                stats.rebuilds=stats.rebuilds+1
            end
            if job~=active then return true end -- a native rebuild can dispatch travel
            if job.all then job.phase,job.index='contexts',job.contextIndex+1 else job=nil end
            return active.didRebuild -- no second rebuild in this engine frame
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
    if state.refreshProfile then
        state.refreshProfile=false
        state.profile=assert(ControllerProfile.acquire(state.object.InputSystem),'Controller profile unavailable')
        local aliases={};for alias in pairs(state.profileTargets) do aliases[#aliases+1]=alias end
        table.sort(aliases)
        job={phase='profileCheck',index=1,profileAliases=aliases,steps=0,profileOnly=true}
        return
    end
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
    if not running or stopped or suspended or configStopped then running=false;return true end
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
            local preparing=os.clock()
            local prepared=prepare()
            phaseMax.prepare=math.max(phaseMax.prepare,(os.clock()-preparing)*1000)
            if not prepared then return end
        end
        local validating=os.clock()
        local frame=system:GetFrameCount()
        if type(frame)~='number' then error('Frame counter unavailable') end
        if frame==lastFrame then return end
        lastFrame=frame
        if not validState(not ownerChecked) then
            -- Owner churn must not renew the finite readiness budget indefinitely.
            state,job,requested=nil,nil,{};return
        end
        ownerChecked=true
        if not same(state.object:GetActiveGamepadPreset(),state.preset) then
            job,requested=nil,{}; if not beginPreset() then state=nil;return end
        end
        if state.unsupported then requested={};return end
        phaseMax.validate=math.max(phaseMax.validate,(os.clock()-validating)*1000)
        for unit=1,MAX_STEPS do
            -- The clock includes preparation. Reserve one bounded step when a
            -- native prelude overruns the soft target, rather than starving the
            -- job forever. Later steps must fit the remaining elapsed budget.
            if unit>1 and os.clock()-started>=MAX_SECONDS then break end
            if not job then nextJob() end
            if not job then break end
            stats.steps=stats.steps+1
            local stepping=os.clock()
            local yielded=step()
            phaseMax.step=math.max(phaseMax.step,(os.clock()-stepping)*1000)
            if yielded then break end
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
    if exhausted or (state and not job and not next(requested) and not state.rediscover and not state.refreshProfile) or configStopped then
        running=false
        if config and config.debugLogging then
            log('Experimental controller profile: '..stats.profileWrites..' verified slot updates.')
            local now=os.clock()
            local ready=readyAt or now
            log(string.format('Work summary: wake completed in %.1f ms (readiness %.1f ms, processing %.1f ms); %d callbacks, %d steps, %d mapping queries, %d rebuilds, %d ignored events; max callback %.3f ms; max prepare/validate/step %.3f/%.3f/%.3f ms.',
                (now-wakeStarted)*1000,(ready-wakeStarted)*1000,(now-ready)*1000,
                stats.ticks,stats.steps,stats.names,stats.rebuilds,stats.ignored,stats.maxMs,
                phaseMax.prepare,phaseMax.validate,phaseMax.step))
        end
        if exhausted and not lastError then log('Input setup not ready; stopped until a new input owner, load or possession.') end
        return true
    end
    return false
end

schedule=function(delay)
    if scheduled or not running then return end
    scheduled=true
    scheduleSerial=scheduleSerial+1
    local ticket=scheduleSerial
    -- UE4SS delayed loops ignore callback return values. Use a one-shot action
    -- and explicitly schedule a successor only while work remains.
    ExecuteInGameThreadWithDelay(delay,function()
        if ticket~=scheduleSerial or not scheduled then return end
        scheduled=false
        if tick() then return end
        local nextDelay=16
        if not state then nextDelay=math.max(16,math.min(250,math.ceil((nextTry-os.clock())*1000))) end
        schedule(nextDelay)
    end)
end

wake=function()
    if stopped or suspended or configStopped or exhausted or running then return end
    running=true
    ownerChecked=false
    wakeStarted=os.clock()
    readyAt=state and wakeStarted or nil
    schedule(16)
end

for _,api in ipairs({'ExecuteInGameThreadWithDelay','NotifyOnNewObject','RegisterLoadMapPreHook','RegisterLoadMapPostHook','RegisterHook','FindFirstOf','StaticFindObject'}) do
    if type(_G[api])~='function' then log('This UE4SS build lacks '..api..'; remapping disabled.');return end
end
local hooks = dofile(directory .. 'UE4SSCommonHooks.lua').new({RegisterHook=RegisterHook,UnregisterHook=UnregisterHook})
local function noop() end
local function hook(path,callback,before)
    local pre,post=hooks.register(path,path,before or noop,callback)
    assert(pre, 'Could not register '..path..': '..tostring(post))
end
local hooksOK,hookError=pcall(function()
    local function refreshProfile()
        if stopped or suspended or configStopped or lastError then return end
        if state and not state.unsupported then state.refreshProfile=true end
        wake()
    end
    local focusError
    local function isFocus(target)
        return live(target) and target:GetFullName():match('/IMC_FocusMode%.IMC_FocusMode$')
    end
    hook('/Script/DogwoodSystem.DWSystemBlueprintFunctionLibrary:AddInputMappingContext',function(_,worldContext,mappingContext)
        if not isFocus(unwrap(mappingContext)) then return end
        local ok,owned=pcall(function()
            local pawn=unwrap(worldContext)
            return live(pawn) and same(pawn:GetWorld(),currentWorld()) and pawn:IsLocallyControlled()
        end)
        if ok and owned then refreshProfile() end
    end,function(_,worldContext,mappingContext,priority)
        if stopped or suspended or configStopped or not config then return end
        local ok,err=pcall(function()
            local pawn,target=unwrap(worldContext),unwrap(mappingContext)
            if not isFocus(target) or not live(pawn) or not same(pawn:GetWorld(),currentWorld()) or not pawn:IsLocallyControlled() then return end
            if unwrap(priority)==0 then
                priority:set(1)
                if config.debugLogging then log('Focus input context priority: 0 -> 1.') end
            end
        end)
        if not ok and not focusError then focusError=true;log('Focus priority adjustment unavailable: '..tostring(err)) end
    end)
    hook('/Script/RebelInput.RebelInputMappingSubsystem:ApplyPendingKeyboardMappings',function(context)
        if state and same(unwrap(context),state.object) then refreshProfile() end
    end)
    hook('/Script/EnhancedInput.EnhancedInputSubsystemInterface:OnUserKeyProfileChanged',function(context)
        if state and same(unwrap(context),state.object.InputSystem) then refreshProfile() end
    end)
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
        if not live(target) then return end
        -- Coalesce before reflected owner/property reads. Native wrapper identity
        -- can change between calls, so use the target's native address.
        local id=target:GetAddress()
        if requested[id] then return end
        if not live(state.object) then state,job,requested=nil,nil,{};wake();return end
        if not same(caller,state.object.InputSystem) then stats.ignored=stats.ignored+1;return end
        state.refreshProfile=true
        -- World/controller/subsystem resolution belongs to the worker, once per
        -- wake. Continuing slices validate cached world and owner references.
        -- A bounded inbox prevents asset/event floods retaining unlimited objects.
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
        if stopped or suspended or configStopped or object==lastConstruction then return end
        lastConstruction=object
        -- A still-valid old subsystem can be replaced while a slice is pending.
        -- Re-resolve on the next worker frame, never inside construction.
        ownerChecked=false
        if running then return end
        -- Keep a successful owner; an unrelated construction must not rebuild it.
        if not state then retries,exhausted,nextTry=20,false,0 end
        wake()
    end)
    RegisterLoadMapPreHook(function() suspended=true;reset() end)
    RegisterLoadMapPostHook(function() suspended=false;reset();wake() end)
end)
if not hooksOK then
    stopped=true
    local cleared,failures=hooks.clear()
    if not cleared then for _,failure in ipairs(failures) do log('Hook cleanup failed: '..tostring(failure.key)..': '..tostring(failure.error)) end end
    log('Could not register input lifecycle callbacks; remapping disabled: '..tostring(hookError));return
end
wake()
log('Waiting for input setup. Context updates are bounded and scoped to the active player; no continuous polling.')
