-- ============================================
-- Hammerspoon Command Palette
-- Ctrl + Option + Space
-- ============================================

local M = {}

local actions = {
    reload = function()
        hs.reload()
    end,

    console = function()
        hs.toggleConsole()
    end,

    config = function()
        hs.execute('/usr/bin/open ' .. string.format("%q", hs.configdir))
    end,

    comicStatus = function()
        if not comicHotkeys then
            hs.alert.show("Comic Hotkeys: unavailable")
            return
        end

        local status = comicHotkeys.status()

        if status.enabled then
            hs.alert.show("Comic Hotkeys: ON")
        else
            hs.alert.show("Comic Hotkeys: OFF")
        end
    end,

    terminalStatus = function()
        if not terminalCapture or not terminalCapture.state then
            hs.alert.show("Terminal Capture: unavailable")
            return
        end

        if terminalCapture.state.armed then
            hs.alert.show("Terminal Capture: ready")
        else
            hs.alert.show("Terminal Capture: waiting for Cmd+V")
        end
    end,

    windowFocus = function()
        if windowFocus and windowFocus.focusNextWindow then
            windowFocus.focusNextWindow()
        else
            hs.alert.show("Window Auto Focus: unavailable")
        end
    end,

    autoReloadStatus = function()
        if autoReload and autoReload.watcher then
            hs.alert.show("Auto Reload: ON")
        else
            hs.alert.show("Auto Reload: unavailable")
        end
    end,
}

local choices = {
    {
        text = "Reload Hammerspoon",
        subText = "設定を今すぐ再読み込み",
        id = "reload",
    },
    {
        text = "Open Console",
        subText = "Hammerspoon Consoleを開く",
        id = "console",
    },
    {
        text = "Open Config Folder",
        subText = "~/.hammerspoon をFinderで開く",
        id = "config",
    },
    {
        text = "Comic Hotkeys Status",
        subText = "漫画操作機能の状態を確認",
        id = "comicStatus",
    },
    {
        text = "Terminal Capture Status",
        subText = "Terminal Captureの待機状態を確認",
        id = "terminalStatus",
    },
    {
        text = "Focus Next Window",
        subText = "次のウィンドウへフォーカス",
        id = "windowFocus",
    },
    {
        text = "Auto Reload Status",
        subText = "自動Reload監視の状態を確認",
        id = "autoReloadStatus",
    },
}

local function onChoice(choice)
    if not choice then
        return
    end

    local action = actions[choice.id]

    if action then
        action()
    else
        hs.alert.show("Unknown command")
    end
end

function M.show()
    if not M.chooser then
        return
    end

    M.chooser:query("")
    M.chooser:show()
end

function M.start()
    M.chooser = hs.chooser.new(onChoice)

    M.chooser
        :choices(choices)
        :placeholderText("Hammerspoon command...")
        :searchSubText(true)
        :rows(7)

    M.hotkey = hs.hotkey.bind(
        {"ctrl", "alt"},
        "space",
        function()
            M.show()
        end
    )

    print("[Command Palette] Ctrl + Option + Space")
end

function M.stop()
    if M.hotkey then
        M.hotkey:delete()
        M.hotkey = nil
    end

    if M.chooser then
        M.chooser:delete()
        M.chooser = nil
    end
end

M.start()

return M
