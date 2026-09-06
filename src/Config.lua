-- Dawnwalker Controller Tweaks configuration. MIT; see LICENSE.txt.
local M = {}
M.defaults = {
    Camera_Look = "Gamepad_Right2D",
    Traversal_Movement_Axis = "Gamepad_Left2D",
    Traversal_Sprint = "Gamepad_LeftThumbstick",
    Traversal_Jump = "Gamepad_FaceButton_Bottom",
    Traversal_Crouch = "Gamepad_FaceButton_Right",
    Traversal_Planeshift = "Gamepad_FaceButton_Top",
    Combat_Draw_Weapon = "Gamepad_FaceButton_Top",
    Combat_Block = "Gamepad_LeftTriggerAxis",
    Combat_Dodge = "Gamepad_FaceButton_Right",
    Combat_Target_Previous = "Gamepad_RightStick_Left",
    Combat_Target_Next = "Gamepad_RightStick_Right",
    Combat_Target_Lock = "Gamepad_RightThumbstick",
    Player_Drink_Blood = "Gamepad_FaceButton_Left",
    Player_Focus_Mode = "Gamepad_LeftShoulder",
    Player_Interact = "Gamepad_FaceButton_Left",
    Player_Shadowstep = "Gamepad_RightShoulder",
    Combat_Attack = "Gamepad_RightTriggerAxis",
    Combat_Abilities = "Gamepad_LeftShoulder",
    Player_Abilities_Gamepad = "Gamepad_RightTriggerAxis",
    Player_Hub_Launch = "Gamepad_Special_Left",
    Player_Quickslot_Top = "Gamepad_DPad_Up",
    Player_Quickslot_Left = "Gamepad_DPad_Left",
    Player_Quickslot_Right = "Gamepad_DPad_Right",
    Player_Quickslot_Bottom = "Gamepad_DPad_Down",
    Combat_Switch_Weapon = "Gamepad_FaceButton_Left",
    Toggle_Quickslot = "Gamepad_FaceButton_Bottom",
    Toggle_Controls_Legend = "Gamepad_Special_Right",
    Photo_Vertical_Rise = "Gamepad_RightShoulder",
    Photo_Vertical_Fall = "Gamepad_LeftShoulder",
    Photo_Exit = "Gamepad_FaceButton_Right",
    Player_Hub_Map = "Gamepad_Special_Left",
}
local aliases = {
    a = "Gamepad_FaceButton_Bottom",
    b = "Gamepad_FaceButton_Right",
    x = "Gamepad_FaceButton_Left",
    y = "Gamepad_FaceButton_Top",
    lb = "Gamepad_LeftShoulder",
    lt = "Gamepad_LeftTriggerAxis",
    rb = "Gamepad_RightShoulder",
    rt = "Gamepad_RightTriggerAxis",
    ls = "Gamepad_LeftThumbstick",
    rs = "Gamepad_RightThumbstick",
    view = "Gamepad_Special_Left",
    menu = "Gamepad_Special_Right",
    dpadup = "Gamepad_DPad_Up",
    dpaddown = "Gamepad_DPad_Down",
    dpadleft = "Gamepad_DPad_Left",
    dpadright = "Gamepad_DPad_Right",
    leftstick = "Gamepad_Left2D",
    rightstick = "Gamepad_Right2D",
    rightstickleft = "Gamepad_RightStick_Left",
    rightstickright = "Gamepad_RightStick_Right",
}
-- Native Alternative preset overrides seven entries of the stock default preset.
-- Resolve its complete layout here so the packaged default shoulder swap does not
-- leak through inheritance. Only personal entries override this alternate layout.
M.alternatePresetEntries = {
    Combat_Switch_Weapon = "Gamepad_FaceButton_Bottom",
    Toggle_Quickslot = "Gamepad_LeftShoulder",
    Combat_Block = "Gamepad_FaceButton_Top",
    Combat_Attack = "Gamepad_FaceButton_Left",
    Combat_Draw_Weapon = "Gamepad_RightTriggerAxis",
    Player_Shadowstep = "Gamepad_RightShoulder",
    Player_Abilities_Gamepad = "Gamepad_RightTriggerAxis",
}
M.alternateDefaults = {}
for action, key in pairs(M.defaults) do M.alternateDefaults[action] = key end
for action, key in pairs(M.alternatePresetEntries) do M.alternateDefaults[action] = key end
M.alternateDefaults.Player_Focus_Mode = "Gamepad_LeftTriggerAxis"
M.alternateDefaults.Combat_Abilities = "Gamepad_LeftTriggerAxis"
M.alternateDefaults.Photo_Vertical_Rise = "Gamepad_RightTriggerAxis"
M.alternateDefaults.Photo_Vertical_Fall = "Gamepad_LeftTriggerAxis"
-- X is Attack in Alternative. Use LB for Bite/feeding/Necrospeak in Focus.
M.alternateDefaults.Player_Drink_Blood = "Gamepad_LeftShoulder"

local actions, keys = {}, {}
for action in pairs(M.defaults) do actions[action:lower()] = action end
for _, key in pairs(aliases) do keys[key:lower()] = key end
local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end
local function boolean(s)
    if s == 'true' or s == '1' then return true end
    if s == 'false' or s == '0' then return false end
    error('expected true or false', 0)
end

function M.parse(text, base)
    base = base or {enabled = true, debugLogging = false, bindings = M.defaults}
    local config = {enabled = base.enabled, debugLogging = base.debugLogging, bindings = {}}
    for action, key in pairs(base.bindings) do config.bindings[action] = key end
    local section, seen, lineNumber = '', {}, 0
    text = text:gsub('^\239\187\191', '')
    for line in (text .. '\n'):gmatch('(.-)\n') do
        lineNumber = lineNumber + 1
        local ok, err = pcall(function()
            line = trim(line:gsub('[;#].*$', ''))
            if line == '' then return end
            local header = line:match('^%[([^%]]+)%]$')
            if header then
                section = trim(header):lower()
                if section ~= 'general' and section ~= 'bindings' then error('unknown section: ' .. header, 0) end
                return
            end
            local name, value = line:match('^([%w_]+)%s*=%s*(.-)$')
            if not name then error('expected Name = Value', 0) end
            name, value = name:lower(), trim(value):lower()
            local id = section .. '.' .. name
            if seen[id] then error('duplicate entry: ' .. name, 0) end
            seen[id] = true
            if section == 'general' then
                if name == 'enabled' then config.enabled = boolean(value)
                elseif name == 'debuglogging' then config.debugLogging = boolean(value)
                else error('unknown setting: ' .. name, 0) end
            elseif section == 'bindings' then
                local action, key = actions[name], aliases[value] or keys[value]
                if not action then error('unknown action: ' .. name, 0) end
                if not key then error('unknown controller control: ' .. value, 0) end
                local axisAction = action == 'Camera_Look' or action == 'Traversal_Movement_Axis'
                local axisKey = key == 'Gamepad_Left2D' or key == 'Gamepad_Right2D'
                if axisAction ~= axisKey then error('stick axes can only be assigned to movement or camera', 0) end
                config.bindings[action] = key
            else error('entry outside [General] or [Bindings]', 0) end
        end)
        if not ok then return nil, 'line ' .. lineNumber .. ': ' .. tostring(err) end
    end
    return config
end

return M
