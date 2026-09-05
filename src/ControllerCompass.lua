-- Loaded by HUDTweaks' opacity adapter. This is a temporary peek, never a visibility toggle.
local M = {}
local owner, previousTime, previousDown = nil, nil, nil
local shownAt, peekLevel = nil, nil
local installed, running, probeLogged = false, false, false
local waitingReason = nil
local controller, key, gameplayStatics = nil, nil, nil
local playerPawn = nil
local compassClasses = {
    WBP_Compass_C = true,
    WBP_CompassHeading_C = true,
    WBP_Compass_Mappin_C = true,
}
local function clamp(n) return math.max(0, math.min(1, n)) end

function M.IsCompass(entry)
    return entry ~= nil and not entry.compassTemplate and compassClasses[entry.class] == true
end

-- Independent of Unreal so presses, lifecycle transitions and fade timing can be tested.
function M.Step(down, now, identity, settings)
    local before = peekLevel
    if type(down) ~= "boolean" or type(now) ~= "number" or identity == nil then
        owner, previousTime, previousDown, shownAt, peekLevel = nil, nil, nil, nil, nil
        return before ~= nil, false
    end
    if owner ~= identity or (previousTime and (now < previousTime or now - previousTime > 0.25)) then
        previousDown, shownAt, peekLevel = nil, nil, nil
        owner = identity
    end
    previousTime = now
    local clicked = down and previousDown == false
    previousDown = down
    if clicked then shownAt = now end
    if shownAt then
        settings = settings or {}
        local idleAfter = math.max(0, settings.idleAfter or 2)
        local duration = math.max(0, settings.fadeOutSeconds or 0.8)
        local idle = clamp(settings.idleOpacity or 0)
        local elapsed = now - shownAt
        if elapsed <= idleAfter then
            peekLevel = 1
        elseif duration > 0 and elapsed < idleAfter + duration * (1 - idle) then
            -- Match HUDTweaks' constant-speed fade over the full 0..1 range.
            peekLevel = math.max(idle, 1 - (elapsed - idleAfter) / duration)
        else
            shownAt, peekLevel = nil, nil -- HUDTweaks owns normal visibility again
        end
    end
    return before ~= peekLevel or clicked, clicked
end

function M.Opacity(entry, target)
    if peekLevel == nil or not M.IsCompass(entry) then return nil end
    local base = target.opacity
    if base == nil and entry.snapshot then base = entry.snapshot.opacity end
    if base == nil then base = 1 end
    local normal = entry.fade
    if normal == nil then normal = 1 end
    -- Never dim a compass that HUDTweaks is keeping up (combat, disabled fade, etc.).
    return clamp(base * math.max(normal, peekLevel))
end

local function valid(obj)
    if obj == nil then return false end
    local ok, result = pcall(function() return obj:IsValid() end)
    return ok and result == true
end

local function sameObject(a, b)
    return valid(a) and valid(b) and a:GetFullName() == b:GetFullName()
end

local function controlsPawn(candidate, pawn)
    if not valid(candidate) then return false end
    local ok, result = pcall(function()
        return not candidate:GetFullName():find("Default__", 1, true)
            and candidate:IsLocalController() and sameObject(candidate.Pawn, pawn)
    end)
    return ok and result == true
end

local function findAll(className)
    local objects = FindAllOf(className)
    if objects == nil then return {} end
    if type(objects) ~= "table" then
        error("FindAllOf(" .. className .. ") returned " .. type(objects) .. "; waiting to retry")
    end
    return objects
end

local function getController(pawn)
    -- UObject validity alone is insufficient: the main-menu controller may remain
    -- alive after another controller possesses the gameplay pawn.
    if controlsPawn(controller, pawn) then return controller end
    controller = nil
    for _, candidate in pairs(findAll("PlayerController")) do
        if controlsPawn(candidate, pawn) then
            controller = candidate
            break
        end
    end
    return controller
end

-- Shared with the HUDTweaks adapter. A valid cached pawn alone does not prove
-- gameplay possession, and the first controller can still belong to the menu.
function M.PlayerPawn(className)
    if controlsPawn(controller, playerPawn) then return playerPawn end
    playerPawn, controller = nil, nil
    local pawns = findAll(className)
    local controllers = findAll("PlayerController")
    for _, pawn in pairs(pawns) do
        if valid(pawn) and not pawn:GetFullName():find("Default__", 1, true) then
            for _, candidate in pairs(controllers) do
                if controlsPawn(candidate, pawn) then
                    playerPawn, controller = pawn, candidate
                    return playerPawn
                end
            end
        end
    end
    return nil
end

function M.Start(onChanged, getSettings, getPlayerPawn)
    if installed then return end
    local function clear()
        if M.Step(nil, nil, nil) then onChanged() end
    end
    local function waitFor(reason)
        clear()
        if waitingReason ~= reason then
            waitingReason = reason
            print("[ControllerCompass] Waiting: " .. reason .. "\n")
        end
    end
    local function tick()
        if running then return end
        running = true
        local ok, err = pcall(function()
            local settings = getSettings()
            if not settings then waitFor("HUDTweaks disabled or suspended"); return end
            -- Reuse the gameplay-pawn probe already exercised by HUDTweaks' idle fade.
            local pawn = getPlayerPawn()
            if not valid(pawn) then
                controller = nil
                waitFor("HUDTweaks gameplay pawn")
                return
            end
            local pc = getController(pawn)
            if not valid(pc) then waitFor("local PlayerController possessing the gameplay pawn"); return end
            -- FName userdata is required by the native FKey parameter.
            if key == nil then key = { KeyName = FName("Gamepad_Special_Right") } end
            if not valid(gameplayStatics) then
                gameplayStatics = StaticFindObject("/Script/Engine.Default__GameplayStatics")
            end
            if not valid(gameplayStatics) then error("GameplayStatics is unavailable") end
            local down = pc:IsInputKeyDown(key)
            local now = gameplayStatics:GetRealTimeSeconds(pc)
            if type(down) ~= "boolean" or type(now) ~= "number" then
                error("Unreal input/time API returned an unexpected type")
            end
            if not probeLogged or waitingReason ~= nil then
                print("[ControllerCompass] Input ready: press Start/Options to reveal compass.\n")
                print("[ControllerCompass] Player controller: " .. pc:GetFullName() .. "\n")
                probeLogged = true
                waitingReason = nil
            end
            local changed, clicked = M.Step(down, now, pc:GetFullName(), settings)
            if changed then onChanged() end
            if clicked then print("[ControllerCompass] Compass revealed; idle fade will resume.\n") end
            M.lastError = nil
        end)
        if not ok then
            pcall(clear)
            if M.lastError ~= tostring(err) then
                M.lastError = tostring(err)
                print("[ControllerCompass] Input check failed: " .. tostring(err) .. "\n")
            end
        end
        running = false
    end
    -- Register once at startup. The old async-to-game-thread bridge repeatedly
    -- registered callbacks while the shared hook Lua stack could be executing.
    -- Use the delayed game-thread API present in the diagnosed UE4SS build.
    if type(LoopInGameThreadWithDelay) ~= "function" then
        print("[ControllerCompass] Scheduler unavailable: UE4SS must provide LoopInGameThreadWithDelay.\n")
        return
    end
    local ok, handle = pcall(LoopInGameThreadWithDelay, 16, tick)
    if not ok then
        print("[ControllerCompass] Scheduler failed: " .. tostring(handle) .. "\n")
        return
    end
    installed = true
    M.timerHandle = handle
    print("[ControllerCompass] Loaded v1.1.5; game-thread timer active; waiting for a local player.\n")
end

return M
