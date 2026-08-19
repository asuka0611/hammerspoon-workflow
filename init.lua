-- ============================================
-- Hammerspoon Entry Point
-- ============================================

-- System
-- 設定保存時の自動Reload
-- 先に読み込んで、以降の設定変更を監視する
autoReload = require("system.auto_reload")

-- Comic Hotkeys
comicHotkeys = require("comic.hotkeys")

-- Terminal Capture
terminalCapture = require("terminal.capture")

-- Window Auto Focus
windowFocus = require("window.focus")
