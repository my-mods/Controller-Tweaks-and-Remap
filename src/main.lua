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

local function apply(subsystem, library, state)
    if state.cancelled then return false end
    local preset = subsystem:GetActiveGamepadPreset()
    if not live(preset) then return false end
    local fullName = preset:GetFullName()
    local alternative = fullName:sub(-#alternatePath) == alternatePath
    if not alternative and fullName:sub(-#presetPath) ~= presetPath then return true end
    if not same(state.preset, preset) then
        state.preset, state.targets, state.conflictReported = preset, nil, nil
    end
    local mappings = preset.PresetMapping
    local inherited = alternative and #mappings == 7
    if not inherited and #mappings ~= 31 then error('Controller preset differs from the supported layout; refusing to patch.') end
    if inherited then
        for action in pairs(Config.alternatePresetEntries) do
            local id = bindingIds[action] or FName(action)
            bindingIds[action] = id
            if not mappings:Contains(id) then error('Alternative preset is missing original action: ' .. action) end
        end
    end
    local bindings = alternative and config.alternateBindings or config.bindings

    -- Read and validate every integration point before changing the preset.
    -- The game's table links one visible action to multiple internal input names.
    local targets, changes = state.targets or {}, {}
    for action, desired in pairs(bindings) do
        local id = bindingIds[action]
        if not id then id = FName(action); bindingIds[action] = id end
        local present = mappings:Contains(id)
        if not present and not inherited then error('Missing preset action: ' .. action) end
        local actual = present and keyName(unwrap(mappings:Find(id)).Key) or nil
        if actual and actual:sub(1, 8) ~= 'Gamepad_' then error('Unexpected preset key for ' .. action) end
        if actual ~= desired then changes[#changes + 1] = {id = id, desired = desired} end
        if not state.targets then
            local info = subsystem:GetMappingInfo(id)
            local aliases = assert(info.MappedActionNames, 'Missing MappedActionNames for ' .. action)
            local function add(alias)
                alias = name(alias):lower()
                if alias == '' or alias == 'none' then error('Invalid mapping name for ' .. action) end
                local previous = targets[alias]
                if previous and previous.desired ~= desired then
                    error('Conflicting controls for shared mapping ' .. alias)
                end
                targets[alias] = {id = id, desired = desired}
            end
            add(action)
            each(aliases, add)
        end
    end
    -- Cache only owned names/IDs, never temporary returned structs or array elements.
    state.targets = targets

    if not state.conflictReported then
        if bindings.Player_Drink_Blood == bindings.Combat_Attack then
            log('Binding conflict: Player_Drink_Blood and Combat_Attack both use ' .. bindings.Player_Drink_Blood
                .. '. Choose different buttons in your personal INI so Focus Bite and Death from Above can both work.')
        end
        state.conflictReported = true
    end

    local contexts, ready = {}, false
    each(subsystem.RebindableContexts, function(context)
        if live(context) then
            ready = true
            local edits = {}
            each(context.Mappings, function(mapping)
                -- Keyboard/mouse mappings and all existing trigger/modifier objects stay intact.
                local current = keyName(mapping.Key)
                if current:sub(1, 8) == 'Gamepad_' then
                    local target = targets[name(library:GetMappingName(mapping)):lower()]
                    if target and current ~= target.desired then
                        edits[#edits + 1] = {mapping = mapping, target = target}
                    end
                end
            end)
            if #edits > 0 then contexts[#contexts + 1] = {context = context, edits = edits} end
        end
    end)
    if not ready or state.cancelled then return false end

    for _, change in ipairs(changes) do
        -- TMap:Add builds a fresh native value before replacing the old one.
        -- This resets FKey's cached KeyDetails, which a KeyName-only write would leave stale.
        mappings:Add(change.id, {Key = {KeyName = FName(change.desired)}})
        if keyName(unwrap(mappings:Find(change.id)).Key) ~= change.desired then error('Preset write failed') end
    end
    for _, entry in ipairs(contexts) do
        -- A native rebuild can dispatch a lifecycle callback before this pass ends.
        if state.cancelled then return false end
        if not live(entry.context) then return false end
        for _, edit in ipairs(entry.edits) do
            -- Copy a complete FKey; do not mutate its KeyName in place.
            edit.mapping.Key = unwrap(mappings:Find(edit.target.id)).Key
            if keyName(edit.mapping.Key) ~= edit.target.desired then error('Input context write failed') end
        end
        library:RequestRebuildControlMappingsUsingContext(entry.context, false)
    end
    if not announced then
        log('v1.5.0 configuration active for the ' .. (alternative and 'Alternative' or 'Default')
            .. ' controller preset. Player_Drink_Blood controls Focus Bite, feeding and Necrospeak. Restart after INI edits.')
        announced = true
    end
    if config.debugLogging and (#changes > 0 or #contexts > 0) then
        log(string.format('Updated %d preset bindings and %d input contexts.', #changes, #contexts))
    end
    return true
end

-- Configuration is immutable for this process. Work runs only during startup or
-- an input lifecycle event; a successful pass removes its timer entirely.
local library, states = nil, {}
local pendingObjects = {}
local running, suspended, stopped = false, false, false
local remaining, attempts, nextSearch, elapsed = 0, 0, 0, 0
local discover = true
local revision = 0
local wake

local function remember(object)
    if not live(object) then return end
    local owner, world = object:GetOuter(), object:GetWorld()
    if not live(owner) or not live(world) then return end
    local id = object:GetAddress()
    local state = states[id]
    if not state or not same(state.object, object) or not same(state.owner, owner) or not same(state.world, world) then
        states[id] = {object = object, owner = owner, world = world}
    end
end

local function tick()
    if stopped or configStopped or suspended then running = false; return true end
    remaining, elapsed = remaining - 1, elapsed + 1
    local startRevision, complete = revision, false
    local ok, err = pcall(function()
        loadConfig()
        if not config or configStopped then return end
        if not live(library) then
            library = StaticFindObject('/Script/EnhancedInput.Default__EnhancedInputLibrary')
        end
        if not live(library) then return end

        for id, state in pairs(states) do
            if not live(state.object) or not same(state.owner, state.object:GetOuter()) or not same(state.world, state.object:GetWorld()) then
                states[id] = nil
                discover = true
                attempts, nextSearch = 0, elapsed
            end
        end
        -- Construction callbacks only enqueue references; read them here, after construction.
        local waiting = {}
        for _, object in ipairs(pendingObjects) do
            remember(object)
            if live(object) and not states[object:GetAddress()] then waiting[#waiting + 1] = object end
        end
        pendingObjects = waiting

        -- At most four global discoveries per lifecycle, with exponential backoff.
        -- Object notifications recover later readiness without perpetual scanning.
        if discover and attempts < 4 and elapsed >= nextSearch then
            attempts = attempts + 1
            nextSearch = elapsed + 2 ^ attempts
            local subsystems = FindAllOf('RebelInputMappingSubsystem')
            if subsystems ~= nil and type(subsystems) ~= 'table' then error('Invalid input subsystem lookup result') end
            for _, subsystem in ipairs(subsystems or {}) do remember(subsystem) end
            discover = next(states) == nil
        end
        complete = next(states) ~= nil and #pendingObjects == 0
        for _, state in pairs(states) do
            if not apply(state.object, library, state) then complete = false end
        end
    end)
    if not ok then
        err = tostring(err)
        if err ~= lastError then log('Remapping could not complete; will retry: ' .. err); lastError = err end
    else lastError = nil end
    if revision ~= startRevision then return false end
    if configStopped or (ok and complete) or remaining <= 0 then
        running = false
        if not configStopped and not (ok and complete) then
            log('Input setup not ready; stopped retries. Will retry at the next input lifecycle event.')
        end
        return true
    end
    return false
end

for _, api in ipairs({'LoopInGameThreadWithDelay', 'NotifyOnNewObject', 'RegisterLoadMapPreHook', 'RegisterLoadMapPostHook', 'RegisterHook'}) do
    if type(_G[api]) ~= 'function' then
        log('This UE4SS build lacks ' .. api .. '; remapping disabled.')
        return
    end
end

wake = function(reset)
    if stopped or configStopped then return end
    revision = revision + 1
    if reset then
        for _, state in pairs(states) do state.cancelled = true end
        states, pendingObjects = {}, {}
        discover, attempts, nextSearch, elapsed = true, 0, 0, 0
    end
    if suspended then return end
    remaining = 20
    if not running then
        if discover then attempts, nextSearch, elapsed = 0, 0, 0 end
        running = true
        LoopInGameThreadWithDelay(1000, tick)
    end
end

local hookIds = {}
local function hook(path, callback)
    -- Native posthooks observe the completed state. Never override the function result.
    local pre, post = RegisterHook(path, function() end, callback)
    assert(type(pre) == 'number' and type(post) == 'number', 'Could not register ' .. path)
    hookIds[#hookIds + 1] = {path, pre, post}
end
local hooksOK, hookError = pcall(function()
    hook('/Script/Engine.PlayerController:ClientRestart', function() wake(true) end)
    hook('/Script/EnhancedInput.EnhancedInputSubsystemInterface:AddMappingContext', function() wake(false) end)
    NotifyOnNewObject('/Script/RebelInput.RebelInputMappingSubsystem', function(object)
        if stopped or suspended or configStopped then return end
        pendingObjects[#pendingObjects + 1] = object
        wake(false)
    end)
    NotifyOnNewObject('/Script/EnhancedInput.InputMappingContext', function() wake(false) end)
    NotifyOnNewObject('/Script/RebelInput.RebelInputPreset', function() wake(false) end)
    RegisterLoadMapPreHook(function()
        suspended = true
        wake(true)
    end)
    RegisterLoadMapPostHook(function()
        suspended = false
        wake(true)
    end)
end)
if not hooksOK then
    stopped = true
    if type(UnregisterHook) == 'function' then
        for _, ids in ipairs(hookIds) do pcall(UnregisterHook, ids[1], ids[2], ids[3]) end
    end
    log('Could not register input lifecycle callbacks; remapping disabled: ' .. tostring(hookError))
    return
end
wake(true)
log('Waiting for input setup. Configuration applies at startup and input lifecycle changes; no continuous polling.')
