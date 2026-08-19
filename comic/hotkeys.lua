-- ============================================
-- Comic Hotkeys
-- Stable Module Version
-- ============================================

local M = {}

local CHROME_BUNDLE_ID = "com.google.Chrome"
local NEXT_KEY = "left"
local PREV_KEY = NEXT_KEY == "left" and "right" or "left"
local URL_CHECK_INTERVAL = 0.25
local AUTOREPEAT_INTERVAL = 0.45

local HOTKEY_NAMES = {
    "q", "w", "e",
    "a", "s", "d",
    "z", "x", "c",
    "space",
}

M.state = {
    enabled = true,
    currentURL = "",
    viewerActive = false,
    lastRepeatAt = {},
}

local hotkeyCodes = {}
for _, name in ipairs(HOTKEY_NAMES) do
    local code = hs.keycodes.map[name]
    if code then hotkeyCodes[code] = true end
end

local function frontmostIsChrome()
    local app = hs.application.frontmostApplication()
    return app ~= nil and app:bundleID() == CHROME_BUNDLE_ID
end

local function parseURL(url)
    if type(url) ~= "string" or url == "" then return nil, nil end
    local host, path = url:match("^https?://([^/%?#:]+)([^?#]*)")
    if not host then return nil, nil end
    host = host:lower()
    if path == "" then path = "/" end
    return host, path
end

local function hostMatches(host, domain)
    return host == domain or host:sub(-(#domain + 1)) == "." .. domain
end

local function pathStartsWith(path, prefix)
    return path:sub(1, #prefix) == prefix
end

local function isViewerURL(url)
    local host, path = parseURL(url)
    if not host or not path then return false end

    if hostMatches(host, "cmoa.jp") and pathStartsWith(path, "/bib/speedreader/") then
        return true
    end

    if hostMatches(host, "booklive.jp") and pathStartsWith(path, "/bviewer/") then
        return true
    end

    return false
end

local function readChromeURL()
    if not frontmostIsChrome() then return "" end

    local ok, result = hs.osascript.applescript([[
        tell application "Google Chrome"
            if (count of windows) = 0 then
                return ""
            end if
            return URL of active tab of front window
        end tell
    ]])

    if ok and type(result) == "string" then return result end
    return ""
end

function M.refreshState()
    if not frontmostIsChrome() then
        M.state.currentURL = ""
        M.state.viewerActive = false
        return
    end

    local url = readChromeURL()
    M.state.currentURL = url
    M.state.viewerActive = isViewerURL(url)
end

local function isAutoRepeat(event)
    local property = hs.eventtap.event.properties.keyboardEventAutorepeat
    local value = event:getProperty(property)
    return value ~= nil and value ~= 0
end

local function turnPage(previous)
    if previous then
        hs.eventtap.keyStroke({}, PREV_KEY, 0)
    else
        hs.eventtap.keyStroke({}, NEXT_KEY, 0)
    end
end

local function handleKeyDown(event)
    if not M.state.enabled then return false end
    if not frontmostIsChrome() then return false end
    if not M.state.viewerActive then return false end

    local keyCode = event:getKeyCode()
    if not hotkeyCodes[keyCode] then return false end

    local flags = event:getFlags()
    if flags.fn then return false end
    if flags.cmd or flags.ctrl or flags.alt then return false end

    local now = hs.timer.secondsSinceEpoch()

    if isAutoRepeat(event) then
        local last = M.state.lastRepeatAt[keyCode] or 0
        if now - last < AUTOREPEAT_INTERVAL then return true end
        M.state.lastRepeatAt[keyCode] = now
    else
        M.state.lastRepeatAt[keyCode] = now
    end

    turnPage(flags.shift == true)
    return true
end

local function toggle()
    M.state.enabled = not M.state.enabled
    if M.state.enabled then
        hs.alert.show("Comic Hotkeys ON", 0.6)
    else
        hs.alert.show("Comic Hotkeys OFF", 0.6)
    end
end

function M.status()
    M.refreshState()
    print("=== Comic Hotkeys ===")
    print("Enabled         : " .. tostring(M.state.enabled))
    print("Chrome frontmost: " .. tostring(frontmostIsChrome()))
    print("Viewer active   : " .. tostring(M.state.viewerActive))
    print("Current URL     : " .. tostring(M.state.currentURL))
    return {
        enabled = M.state.enabled,
        chrome = frontmostIsChrome(),
        active = M.state.viewerActive,
        url = M.state.currentURL,
    }
end

function M.start()
    M.refreshState()

    M.urlWatcher = hs.timer.doEvery(URL_CHECK_INTERVAL, function()
        M.refreshState()
    end)

    M.appWatcher = hs.application.watcher.new(function()
        hs.timer.doAfter(0.03, function()
            M.refreshState()
        end)
    end)
    M.appWatcher:start()

    M.toggleHotkey = hs.hotkey.bind({"cmd", "alt"}, "p", toggle)

    M.keyTap = hs.eventtap.new({
        hs.eventtap.event.types.keyDown
    }, handleKeyDown)
    M.keyTap:start()

    print("Comic Hotkeys stable module loaded")
end

function M.stop()
    if M.urlWatcher then M.urlWatcher:stop() end
    if M.appWatcher then M.appWatcher:stop() end
    if M.keyTap then M.keyTap:stop() end
    if M.toggleHotkey then M.toggleHotkey:delete() end
    print("Comic Hotkeys stopped")
end

M.start()
return M
