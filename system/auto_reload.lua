-- ============================================
-- Auto Reload
-- .hammerspoon 内の Lua ファイル保存を検知して
-- Hammerspoon設定を自動Reloadする
-- ============================================

local M = {}

local WATCH_PATH = hs.configdir

local function containsLuaChange(paths)
    for _, path in ipairs(paths) do
        if path:sub(-4) == ".lua" then
            return true
        end
    end

    return false
end

local function scheduleReload(paths)
    if not containsLuaChange(paths) then
        return
    end

    -- エディタによっては保存時に複数イベントが発生するため、
    -- 直前のReload予約をキャンセルする
    if M.reloadTimer then
        M.reloadTimer:stop()
        M.reloadTimer = nil
    end

    M.reloadTimer = hs.timer.doAfter(0.25, function()
        M.reloadTimer = nil
        hs.reload()
    end)
end

function M.start()
    if M.watcher then
        M.watcher:stop()
    end

    M.watcher = hs.pathwatcher.new(
        WATCH_PATH,
        scheduleReload
    )

    M.watcher:start()

    print("[Auto Reload] Watching: " .. WATCH_PATH)
end

function M.stop()
    if M.watcher then
        M.watcher:stop()
        M.watcher = nil
    end

    if M.reloadTimer then
        M.reloadTimer:stop()
        M.reloadTimer = nil
    end
end

M.start()

return M
