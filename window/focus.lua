-- ============================================
-- Window Auto Focus
--
-- ウィンドウを閉じたり最小化したあと、
-- フォーカスされているウィンドウがなければ
-- 次の表示中ウィンドウを自動で選択する
-- ============================================

local M = {}

-- 現在のMission Control Spaceにある
-- 通常のウィンドウを対象にする
M.filter = hs.window.filter.defaultCurrentSpace

-- ============================================
-- 次のウィンドウへフォーカス
-- ============================================

function M.focusNextWindow()
    -- macOSが既に正常なウィンドウを
    -- フォーカスしているなら何もしない
    local current = hs.window.focusedWindow()

    if current
        and current:isVisible()
        and not current:isMinimized()
        and current:isStandard()
    then
        return
    end

    -- 最近フォーカスした順に取得
    local windows = M.filter:getWindows(
        hs.window.filter.sortByFocusedLast
    )

    for _, win in ipairs(windows) do
        if win
            and win:isVisible()
            and not win:isMinimized()
            and win:isStandard()
        then
            win:focus()

            print(
                "[Window Focus] Focused: "
                .. tostring(win:title())
            )

            return
        end
    end

    print("[Window Focus] No window to focus")
end

-- ============================================
-- イベント後に少し待って確認
-- ============================================

function M.scheduleFocusCheck()
    if M.pendingTimer then
        M.pendingTimer:stop()
        M.pendingTimer = nil
    end

    M.pendingTimer = hs.timer.doAfter(
        0.10,
        function()
            M.pendingTimer = nil
            M.focusNextWindow()
        end
    )
end

-- ============================================
-- ウィンドウイベント監視
-- ============================================

function M.start()
    M.filter:subscribe(
        {
            hs.window.filter.windowDestroyed,
            hs.window.filter.windowMinimized,
        },
        function()
            M.scheduleFocusCheck()
        end
    )

    print("Window Auto Focus loaded")
end

-- ============================================
-- 停止
-- ============================================

function M.stop()
    M.filter:unsubscribeAll()

    if M.pendingTimer then
        M.pendingTimer:stop()
        M.pendingTimer = nil
    end

    print("Window Auto Focus stopped")
end

M.start()

return M
