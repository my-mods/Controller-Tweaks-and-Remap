-- Mod Setting Menu is the authoritative store. Legacy files are import-only. MIT.
local M = {}
function M.load(directory, Config, log)
    local Store = dofile(directory .. 'SettingsStore.lua')
    local schema = dofile(directory .. 'SettingsSchema.lua')
    local keys = {"Gamepad_FaceButton_Bottom","Gamepad_FaceButton_Right","Gamepad_FaceButton_Left","Gamepad_FaceButton_Top","Gamepad_LeftShoulder","Gamepad_LeftTriggerAxis","Gamepad_RightShoulder","Gamepad_RightTriggerAxis","Gamepad_LeftThumbstick","Gamepad_RightThumbstick","Gamepad_Special_Left","Gamepad_Special_Right","Gamepad_DPad_Up","Gamepad_DPad_Down","Gamepad_DPad_Left","Gamepad_DPad_Right","Gamepad_RightStick_Left","Gamepad_RightStick_Right","Gamepad_Left2D","Gamepad_Right2D"}
    local text, err = Store.read(directory .. 'ControllerTweaks.defaults.ini')
    if not text then return nil, err, 'invalid' end
    local defaults, e = Config.parse(text)
    if not defaults then return nil, e, 'invalid' end
    local values, problem = Store.load(directory, schema, function()
        local base = os.getenv('LOCALAPPDATA')
        if not base then return nil, 'LOCALAPPDATA unavailable for legacy migration' end
        local personal, pe, pc = Store.read(base .. '/Dawnwalker/Saved/Config/ControllerTweaks.ini')
        if not personal and pc == 2 then personal, pe, pc = Store.read(directory .. 'ControllerTweaks.ini') end
        if not personal and pc ~= 2 then return nil, pe end
        local cfg, ce = Config.parse(personal or '', defaults)
        if not cfg then return nil, ce end
        local explicit = assert(Config.parse(personal or '', {enabled=defaults.enabled,debugLogging=defaults.debugLogging,bindings={}}))
        local result = {enabled=cfg.enabled and 1 or 0,debugLogging=cfg.debugLogging and 1 or 0}
        for action in pairs(cfg.bindings) do
            result[action] = 0
            local key = explicit.bindings[action]
            if key then for i, name in ipairs(keys) do if name == key then result[action] = i end end end
        end
        return result
    end)
    if not values then return nil, problem, 'invalid' end
    local cfg = {enabled=values.enabled==1,debugLogging=values.debugLogging==1,bindings={},alternateBindings={}}
    for action, key in pairs(defaults.bindings) do
        cfg.bindings[action] = values[action]==0 and key or keys[values[action]]
        cfg.alternateBindings[action] = values[action]==0 and Config.alternateDefaults[action] or keys[values[action]]
    end
    log('Loaded Mod Settings; Apply changes in the menu, then restart.')
    return cfg
end
return M
