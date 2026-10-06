-- Controller item taps. MIT. Ability quickslots never enter this item-only hook.
local M={}
local PATH='/Script/DogwoodInventory.InventoryQuickslotSubsystem:TriggerQuickslot'
local actions={'Player_Quickslot_Left','Player_Quickslot_Top','Player_Quickslot_Right','Player_Quickslot_Bottom'}
local keyNames={'Gamepad_DPad_Left','Gamepad_DPad_Up','Gamepad_DPad_Right','Gamepad_DPad_Down'}
local function live(v) return v~=nil and v:IsValid() end
local function same(a,b) return live(a) and live(b) and a:GetAddress()==b:GetAddress() end
local function unwrap(v) if type(v)=='number' then return v end;return v:get() end
function M.new(options)
    local Link=options.link
    local pending,frames={},{}
    local handle,registered,unavailable,replaying
    local warned={}
    local keys={}
    local counts={press=0,tap=0,long=0,cancel=0,polls=0,seconds=0}
    local function log(text) options.log(text) end
    local function warn(text) if not warned[text] then warned[text]=true;log(text) end end
    local function debug() return options.logging()==true end
    local function report()
        if not debug() then return end
        log(string.format('Item input: %d presses, %d short releases, %d holds cancelled, %d interrupted; %d samples, %.3f ms Lua CPU.',
            counts.press,counts.tap,counts.long,counts.cancel,counts.polls,counts.seconds*1000))
    end
    local function cancel(job)
        if job.link then Link.finish(job.link,3) end
        if debug() then counts.cancel=counts.cancel+1 end
    end
    local function clear()
        if handle then CancelDelayedAction(handle);handle=nil end
        for _,job in pairs(pending) do cancel(job) end
        pending={}
    end
    local function valid(job)
        local scope=options.context()
        if not scope or not same(scope.world,job.world) or not same(scope.controller,job.controller)
            or not same(scope.pawn,job.pawn) or not same(job.controller.Pawn,job.pawn)
            or not live(job.component) or not same(job.component:GetWorld(),job.world) then return false end
        return not scope.gameplay:IsGamePaused(job.world) and job.controller.bShowMouseCursor~=true
            and not job.controller:IsMoveInputIgnored() and job.component:AreQuickslotsEnabled()==true
    end
    local schedule
    local function poll()
        handle=nil
        local track=debug();local started=track and os.clock()
        local ok,err=pcall(function()
            for slot,job in pairs(pending) do
                if track then counts.polls=counts.polls+1 end
                if not valid(job) then cancel(job);pending[slot]=nil
                else
                    local now=job.gameplay:GetRealTimeSeconds(job.world)
                    local elapsed=now-job.started
                    local down=job.controller:IsInputKeyDown(job.key)
                    if elapsed<0 then cancel(job);pending[slot]=nil
                    elseif elapsed>=0.6 and not job.long then
                        job.long=true
                        if track then counts.long=counts.long+1 end
                        if job.link then Link.finish(job.link,2) end
                    end
                    if pending[slot] and not down then
                        pending[slot]=nil
                        if not job.long then
                            if job.link then Link.finish(job.link,4) end
                            -- The normal item function owns inventory, cooldowns and
                            -- item restrictions. No item counts or saved data are edited.
                            replaying=true
                            local played,result=pcall(function() return job.component:TriggerQuickslot(slot) end)
                            replaying=false
                            if not played then error(result) end
                            if track then counts.tap=counts.tap+1 end
                        end
                    end
                end
            end
        end)
        if track then counts.seconds=counts.seconds+(os.clock()-started) end
        if not ok then clear();warn('Item short-press handling cancelled: '..tostring(err));return end
        if next(pending) then schedule() else report() end
    end
    schedule=function()
        if not handle then handle=ExecuteInGameThreadWithDelay(16,poll) end
    end
    local function pre(context,slotParam)
        local owner,slot=unwrap(context),tonumber(unwrap(slotParam))
        if not live(owner) or not slot then frames[#frames+1]=0;return end
        local token=_CTQuickslotBegin(owner:GetAddress(),slot)
        frames[#frames+1]=token
        if token==0 or replaying or slot<0 or slot>3 then return end
        local ok,err=pcall(function()
            local existing=pending[slot]
            if existing then
                -- Suppress repeated callbacks, including a release callback, until
                -- our one pending action has been classified and cleared.
                if same(existing.component,owner) then _CTQuickslotArm(token);return end
                cancel(existing);pending[slot]=nil
            end
            local scope=options.context()
            if not scope or not same(owner:GetWorld(),scope.world) then return end
            local keyName=scope.bindings[actions[slot+1]]
            local key=keys[keyName]
            if not key or not scope.controller:IsInputKeyDown(key) then return end
            local job={component=owner,controller=scope.controller,pawn=scope.pawn,world=scope.world,
                gameplay=scope.gameplay,key=key,started=scope.gameplay:GetRealTimeSeconds(scope.world)}
            if not valid(job) then return end
            pending[slot]=job
            schedule()
            if not _CTQuickslotArm(token) then pending[slot]=nil;return end
            if keyName=='Gamepad_DPad_Down' then job.link=Link.begin(job.world,job.pawn) end
            if debug() then counts.press=counts.press+1 end
        end)
        if not ok then clear();warn('Item input handling failed: '..tostring(err)) end
    end
    local function post()
        local token=frames[#frames]
        if token~=nil then frames[#frames]=nil;_CTQuickslotEnd(token) end
    end
    local function setup()
        if registered or unavailable then return end
        if type(_CTQuickslotReady)~='function' then unavailable=true;log('Item short-press handling requires the bundled native helper.');return end
        local ok,result=pcall(function()
            if not _CTQuickslotReady() then return false end
            for _,name in ipairs(keyNames) do keys[name]={KeyName=FName(name)} end
            local a,b=RegisterHook(PATH,pre,post)
            if not a or not b then return false end
            registered=true;return true
        end)
        if not ok or not result then unavailable=true;log('Item short-press handling could not start: '..tostring(result)) end
    end
    return {setup=setup,clear=clear}
end
return M
