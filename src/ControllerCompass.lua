-- Loaded by HUDTweaks' opacity adapter. This is a temporary peek, never a visibility toggle.
local M = {}
local owner, previousTime, previousDown = nil, nil, nil
local shownAt, peekLevel = nil, nil
local installed, pending, probeLogged = false, false, false
local controller, key, gameplayStatics = nil, nil, nil
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

local function getController()
    if valid(controller) then return controller end
    controller = nil
    for _, candidate in ipairs(FindAllOf("DawnwalkerPlayerControllerBase") or {}) do
        if valid(candidate) and not candidate:GetFullName():find("Default__", 1, true)
            and candidate:IsLocalController() then
            controller = candidate
            break
        end
    end
    return controller
end

function M.Start(onChanged, getSettings)
    if installed then return end
    installed = true
    local function clear()
        if M.Step(nil, nil, nil) then onChanged() end
    end
    local function tick()
        pending = false
        local ok, err = pcall(function()
            local settings = getSettings()
            if not settings then clear(); return end
            local pc = getController()
            if not valid(pc) or not valid(pc.Pawn) then clear(); return end
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
            if not probeLogged then
                print("[ControllerCompass] Input ready: press Start/Options to reveal compass.\n")
                probeLogged = true
            end
            local changed, clicked = M.Step(down, now, pc:GetFullName(), settings)
            if changed then onChanged() end
            if clicked then print("[ControllerCompass] Compass revealed; idle fade will resume.\n") end
        end)
        if not ok then
            pcall(clear)
            if M.lastError ~= tostring(err) then
                M.lastError = tostring(err)
                print("[ControllerCompass] Input check failed: " .. tostring(err) .. "\n")
            end
        end
    end
    LoopAsync(16, function()
        if not pending then
            pending = true
            ExecuteInGameThread(tick)
        end
        return false
    end)
    print("[ControllerCompass] Loaded v1.1.0; waiting for a local player.\n")
end

return M
