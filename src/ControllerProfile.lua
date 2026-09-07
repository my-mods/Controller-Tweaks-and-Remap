-- Controller profile application. MIT; see LICENSE.txt.
-- Uses the game's existing profile and controller slot; never saves settings.
local M = {}
local function text(v) return type(v)=='string' and v or v:ToString() end
local function valid(v) return v and v:IsValid() end
function M.acquire(input)
    if not valid(input) then return nil end
    local settings=input:GetUserSettings()
    if not valid(settings) then return nil end
    local profile=settings:GetCurrentKeyProfile()
    if not valid(profile) then return nil end
    local tag=text(profile:GetProfileIdentifer().TagName)
    if tag~='RebelInput.Profile' then error('Unsupported controller profile: '..tag) end
    return {settings=settings,profile=profile,tag=tag}
end
local function args(p,alias,key)
    return {MappingName=FName(alias),Slot=1,NewKey={KeyName=FName(key)},
        HardwareDeviceId=FName('None'),ProfileId={TagName=FName(p.tag)},
        bCreateMatchingSlotIfNeeded=false,bDeferOnSettingsChangedBroadcast=true}
end
local function current(p,a)
    -- OutKeyMapping precedes InArgs in this build's reflected signature.
    local row={}
    p.profile:K2_FindKeyMapping(row,a)
    if not row.MappingName or text(row.MappingName):lower()~=text(a.MappingName):lower() or row.Slot~=1 then
        error('Missing controller profile slot for '..text(a.MappingName))
    end
    return text(row.CurrentKey.KeyName)
end
function M.inspect(p,alias,key)
    local a=args(p,alias,key)
    return current(p,a)
end
function M.apply(p,alias,key)
    local a=args(p,alias,key)
    if current(p,a)==key then return false end
    local failures={}
    p.settings:MapPlayerKey(a,failures)
    if failures.GameplayTags and #failures.GameplayTags>0 then
        error('Controller mapping rejected for '..alias)
    end
    if current(p,a)~=key then error('Controller profile readback failed for '..alias) end
    return true
end
function M.finish(p)
    p.settings:ApplySettings()
end
return M
