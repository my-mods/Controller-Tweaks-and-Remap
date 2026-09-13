-- Prepare preferences at startup; committed menu values update the active session.
local directory = assert(debug.getinfo(1, 'S').source:sub(2):match('^(.*[/\\])'))
local function report(message) print('[Save Settings] '..message..'\n') end
local live=dofile(directory..'LiveSettings.lua').new(directory,report)
local prepared,problem=pcall(function()
    local Config=dofile(directory..'Config.lua')
    local cfg,err,_,values,defaults=dofile(directory..'ConfigStore.lua').load(directory,Config,report)
    assert(values,err); ControllerSettingsDefaults=defaults;live.seed(values)
end)
if not prepared then report('Settings preparation failed: '..tostring(problem)) end
local session = dofile(directory..'UE4SSCommonSession.lua').new(_G, directory, report,{settings=live,loadSettings=function()
    local cfg,err,_,values,defaults=dofile(directory..'ConfigStore.lua').load(directory,dofile(directory..'Config.lua'),report)
    assert(values,err);ControllerSettingsDefaults=defaults;return values
end})
local ok, err = pcall(function()
    dofile(directory..'UE4SSDawnwalkerSaveLoad.lua').start(_G, session, directory..'Gameplay.lua', report)
end)
if not ok then report('Save-load hooks unavailable: '..tostring(err)) end
