-- Dawnwalker Controller Tweaks. MIT; see LICENSE.txt.
-- Uses reflected preset and Enhanced Input APIs; never writes game settings/saves.
local source = debug.getinfo(1, 'S').source:gsub('^@', '')
local directory = assert(source:match('^(.*[/\\])'), 'Controller Tweaks: missing script directory')
local Config = dofile(directory .. 'Config.lua')
local function log(message) print('[ControllerTweaks] ' .. message .. '\n') end
local file = io.open(directory .. 'ControllerTweaks.ini', 'rb')
local config, configError
if file then
    local text = file:read('*a')
    file:close()
    config, configError = Config.parse(text)
else
    log('ControllerTweaks.ini missing; using the packaged controller defaults.')
    config = Config.parse('')
end
if not config then
    log('Configuration rejected; runtime remapping disabled: ' .. configError)
    return
end
if not config.enabled then log('Runtime remapping disabled by configuration.'); return end

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
local lastError, announced = nil, false

local function apply(subsystem, library)
    local preset = subsystem:GetActiveGamepadPreset()
    if not live(preset) then return end
    local fullName = preset:GetFullName()
    if fullName:sub(-#presetPath) ~= presetPath then return end
    local mappings = preset.PresetMapping
    if #mappings ~= 31 then error('Default preset differs from the supported 31-entry mod preset; refusing to patch.') end

    -- Read and validate every integration point before changing the preset.
    -- The game's table links one visible action to multiple internal input names.
    local targets, changes = {}, {}
    for action, desired in pairs(config.bindings) do
        local id = FName(action)
        if not mappings:Contains(id) then error('Missing preset action: ' .. action) end
        local current = unwrap(mappings:Find(id))
        local actual = keyName(current.Key)
        if actual:sub(1, 8) ~= 'Gamepad_' then error('Unexpected preset key for ' .. action) end
        if actual ~= desired then changes[#changes + 1] = {id = id, desired = desired} end
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

    local contexts = {}
    each(subsystem.RebindableContexts, function(context)
        if live(context) then
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

    for _, change in ipairs(changes) do
        -- TMap:Add builds a fresh native value before replacing the old one.
        -- This resets FKey's cached KeyDetails, which a KeyName-only write would leave stale.
        mappings:Add(change.id, {Key = {KeyName = FName(change.desired)}})
        if keyName(unwrap(mappings:Find(change.id)).Key) ~= change.desired then error('Preset write failed') end
    end
    for _, entry in ipairs(contexts) do
        for _, edit in ipairs(entry.edits) do
            -- Copy a complete FKey; do not mutate its KeyName in place.
            edit.mapping.Key = unwrap(mappings:Find(edit.target.id)).Key
            if keyName(edit.mapping.Key) ~= edit.target.desired then error('Input context write failed') end
        end
        library:RequestRebuildControlMappingsUsingContext(entry.context, false)
    end
    if not announced then
        log('v1.4.0 configuration active for the default controller preset. Restart the game after INI edits.')
        announced = true
    end
    if config.debugLogging and (#changes > 0 or #contexts > 0) then
        log(string.format('Updated %d preset bindings and %d input contexts.', #changes, #contexts))
    end
end

local function tick()
    local ok, err = pcall(function()
        local library = StaticFindObject('/Script/EnhancedInput.Default__EnhancedInputLibrary')
        if not live(library) then return end
        local subsystems = FindAllOf('RebelInputMappingSubsystem')
        if subsystems == nil then return end
        if type(subsystems) ~= 'table' then error('Invalid input subsystem lookup result') end
        for _, subsystem in ipairs(subsystems) do
            if live(subsystem) then apply(subsystem, library) end
        end
    end)
    if not ok then
        err = tostring(err)
        if err ~= lastError then log('Remapping could not complete; will retry: ' .. err); lastError = err end
    else lastError = nil end
    return false -- Keep one persistent game-thread timer across loads and possession changes.
end

if type(LoopInGameThreadWithDelay) ~= 'function' then
    log('This UE4SS build lacks LoopInGameThreadWithDelay; install a compatible UE4SS build. Remapping disabled.')
    return
end
LoopInGameThreadWithDelay(1000, tick)
log('INI loaded. Waiting for the default controller preset; checking input contexts once per second.')
