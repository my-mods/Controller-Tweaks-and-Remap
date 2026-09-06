-- Persistent personal settings for Windows. MIT; see LICENSE.txt.
-- Only the shipped defaults belong to the mod manager. Never open a personal
-- file for writing: create a temporary file and rename it without replacement.
local M = {}

local function read(path)
    local file, err, code = io.open(path, 'rb')
    if not file then return nil, err, code end
    local text, readError = file:read('*a')
    file:close()
    return text, readError
end

local function createIfMissing(path, text)
    -- Windows CRT rename fails if the destination exists, including when it
    -- appears after our existence check. Do not use this on POSIX, where rename
    -- replaces the destination. No shell commands or Vortex-managed writes.
    if package.config:sub(1, 1) ~= '\\' then return nil, 'Windows is required for no-replace file creation' end
    local reserved, token = pcall(os.tmpname)
    if not reserved then return nil, token end
    os.remove(token) -- Remove only the scratch file reserved by os.tmpname, if any.
    local basename = assert(token:match('([^/\\]+)$'), 'Invalid temporary filename')
    local temporary = path .. '.' .. basename .. '.tmp'
    local file, err = io.open(temporary, 'a+b')
    if not file then return nil, err end
    if file:seek('end') ~= 0 then
        file:close()
        return nil, 'Temporary filename is already occupied; retrying without modifying it'
    end
    local written, writeError = file:write(text)
    local closed, closeError = file:close()
    if not written or not closed then
        os.remove(temporary)
        return nil, writeError or closeError
    end
    local renamed, renameError = os.rename(temporary, path)
    if not renamed then
        os.remove(temporary)
        -- A concurrent launch/user may have created the personal file first.
        local existing, existingError = read(path)
        if existing ~= nil then return existing end
        return nil, renameError or existingError
    end
    return text
end

local function personalTemplate(defaults)
    local lines = {
        '; PERSONAL CONTROLLER TWEAKS OVERRIDES - preserved across mod updates.',
        '; Uncomment only settings you want to override, then restart the game.',
        '; Commented/omitted settings inherit the current shipped defaults.',
        '; The reference below was copied on first launch and is not rewritten.',
        '; For the latest reference, see ControllerTweaks.defaults.ini in the mod.',
        '',
    }
    local reference = defaults:match('(; KEY REFERENCE.-)$') or defaults
    for line in (reference .. '\n'):gmatch('(.-)\n') do
        if line:match('^%s*[%w_]+%s*=') then line = '; ' .. line end
        lines[#lines + 1] = line
    end
    return table.concat(lines, '\n')
end

function M.load(directory, Config, log)
    local defaultsPath = directory .. 'ControllerTweaks.defaults.ini'
    local defaultsText, defaultsError = read(defaultsPath)
    if not defaultsText then return nil, 'Cannot read shipped defaults: ' .. tostring(defaultsError), 'invalid' end
    local defaults, parseError = Config.parse(defaultsText)
    if not defaults then return nil, 'Shipped defaults rejected: ' .. parseError, 'invalid' end

    local localAppData = os.getenv('LOCALAPPDATA')
    if not localAppData or not (localAppData:match('^%a:[/\\]') or localAppData:match('^\\\\')) then
        return nil, 'LOCALAPPDATA is unavailable; refusing to use a Vortex-managed fallback path', 'invalid'
    end
    local path = localAppData:gsub('[/\\]+$', '') .. '/Dawnwalker/Saved/Config/ControllerTweaks.ini'
    local personal, personalError, personalCode = read(path)
    if personal == nil then
        if personalCode ~= 2 then return nil, 'Cannot read personal INI: ' .. tostring(personalError), 'retry' end
        local legacyPath = directory .. 'ControllerTweaks.ini'
        local legacy, legacyError, legacyCode = read(legacyPath)
        local initial, migrated
        if legacy ~= nil then
            local valid, legacyParseError = Config.parse(legacy, defaults)
            if not valid then return nil, 'Legacy INI rejected; preserve/fix it before migration: ' .. legacyParseError, 'invalid' end
            initial, migrated = legacy, true -- Preserve legacy values AND comments byte for byte.
        elseif legacyCode ~= 2 then
            return nil, 'Cannot read legacy INI: ' .. tostring(legacyError), 'retry'
        else
            initial = personalTemplate(defaultsText)
        end
        personal, personalError = createIfMissing(path, initial)
        if personal == nil then
            return nil, 'Cannot create personal INI at ' .. path .. ': ' .. tostring(personalError)
                .. '. Waiting for the game\'s Saved/Config folder to be available.', 'retry'
        end
        if personal == initial then
            log((migrated and 'Copied legacy INI to ' or 'Created personal override reference at ') .. path)
        end
    end
    local config, err = Config.parse(personal, defaults)
    if not config then return nil, 'Personal INI rejected; file left untouched: ' .. err, 'invalid' end
    log('Loaded shipped defaults + personal overrides from ' .. path)
    return config
end

return M
