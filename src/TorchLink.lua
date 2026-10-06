-- Optional Ignite / Controller Tweaks input coordination. MIT.
-- Shared values are owned numbers, accessed only on the game thread.
local M={}
local prefix='ControllerTweaks.Ignite.1.'
local function available()
    return ModRef and type(ModRef.GetSharedVariable)=='function' and type(ModRef.SetSharedVariable)=='function'
end
local function get(key) return tonumber(ModRef:GetSharedVariable(prefix..key)) or 0 end
local function set(key,value) ModRef:SetSharedVariable(prefix..key,value) end
function M.begin(world,pawn)
    if not available() then return nil end
    local id=get('press')+1
    set('world',world:GetAddress());set('pawn',pawn:GetAddress());set('state',1);set('press',id)
    return id
end
function M.finish(id,state)
    if not id or not available() or get('press')~=id then return end
    if get('state')~=1 then return end
    set('state',state) -- 2=long, 3=cancelled, 4=short
    if state==2 then set('request',get('request')+1) end
end
function M.consumer()
    local lastRequest,lastPress,managed
    return function(scope,down)
        if not available() then return false,false end
        local request,press=get('request'),get('press')
        if lastRequest==nil then lastRequest,lastPress=request,0 end
        local matches=get('world')==scope.world:GetAddress() and get('pawn')==scope.pawn:GetAddress()
        local toggle=matches and request~=lastRequest
        lastRequest=request
        if press~=lastPress then lastPress=press;managed=matches and press or nil end
        if not matches then managed=nil end
        local handled=managed~=nil and managed==press
        if not down then managed=nil end
        return toggle,handled
    end
end
return M
