-- MIT. Persistent menu subscription; no work is performed when this module loads.
local M={}
function M.new(directory, report)
    local Adapter=dofile(directory..'UE4SSDawnwalkerSettings.lua')
    local schema=dofile(directory..'SettingsSchema.lua')
    local live=Adapter.new({modId="oOCamilleOo_ControllerTweaksAndRemap",schema=schema,report=report,
        ids={
        ["enabled"]="enabled",
        ["Camera_Look"]="Camera_Look",
        ["Combat_Abilities"]="Combat_Abilities",
        ["Combat_Attack"]="Combat_Attack",
        ["Combat_Block"]="Combat_Block",
        ["Combat_Dodge"]="Combat_Dodge",
        ["Combat_Draw_Weapon"]="Combat_Draw_Weapon",
        ["Combat_Switch_Weapon"]="Combat_Switch_Weapon",
        ["Combat_Target_Lock"]="Combat_Target_Lock",
        ["Combat_Target_Next"]="Combat_Target_Next",
        ["Combat_Target_Previous"]="Combat_Target_Previous",
        ["Photo_Exit"]="Photo_Exit",
        ["Photo_Vertical_Fall"]="Photo_Vertical_Fall",
        ["Photo_Vertical_Rise"]="Photo_Vertical_Rise",
        ["Player_Abilities_Gamepad"]="Player_Abilities_Gamepad",
        ["Player_Drink_Blood"]="Player_Drink_Blood",
        ["Player_Focus_Mode"]="Player_Focus_Mode",
        ["Player_Hub_Launch"]="Player_Hub_Launch",
        ["Player_Hub_Map"]="Player_Hub_Map",
        ["Player_Interact"]="Player_Interact",
        ["Player_Quickslot_Bottom"]="Player_Quickslot_Bottom",
        ["Player_Quickslot_Left"]="Player_Quickslot_Left",
        ["Player_Quickslot_Right"]="Player_Quickslot_Right",
        ["Player_Quickslot_Top"]="Player_Quickslot_Top",
        ["Player_Shadowstep"]="Player_Shadowstep",
        ["Toggle_Controls_Legend"]="Toggle_Controls_Legend",
        ["Toggle_Quickslot"]="Toggle_Quickslot",
        ["Traversal_Crouch"]="Traversal_Crouch",
        ["Traversal_Jump"]="Traversal_Jump",
        ["Traversal_Movement_Axis"]="Traversal_Movement_Axis",
        ["Traversal_Planeshift"]="Traversal_Planeshift",
        ["Traversal_Sprint"]="Traversal_Sprint",
        ["debugLogging"]="debugLogging"
        }})
    live.start(function(id,callback)
        return dofile(directory..'dmm_api.lua').subscribe(id,callback)
    end)
    return live
end
return M
