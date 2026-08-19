-- ============================================
-- Terminal Capture
-- Cmd+Vで開始地点を記録
-- Cmd単独 -> 英数 -> Space で今回分をコピー
-- ============================================

local M = {}
local keySequence = require("common.key_sequence")
local TERMINAL_BUNDLE_ID = "com.apple.Terminal"

M.state = {
    baselineText = nil,
    pastedText = nil,
    armed = false,
}

local function frontmostIsTerminal()
    local app = hs.application.frontmostApplication()
    return app ~= nil and app:bundleID() == TERMINAL_BUNDLE_ID
end

local function safeAttribute(element, name)
    if not element then return nil end
    local ok, value = pcall(function()
        return element:attributeValue(name)
    end)
    if ok then return value end
    return nil
end

local function findLargestText(element, depth, result)
    depth = depth or 0
    result = result or { text = nil, length = 0 }

    if not element or depth > 15 then return result end

    local value = safeAttribute(element, "AXValue")
    if type(value) == "string" and #value > result.length then
        result.text = value
        result.length = #value
    end

    local children = safeAttribute(element, "AXChildren")
    if type(children) == "table" then
        for _, child in ipairs(children) do
            findLargestText(child, depth + 1, result)
        end
    end

    return result
end

function M.readTerminal()
    if not frontmostIsTerminal() then
        return nil, "Terminalが前面ではありません"
    end

    local app = hs.application.frontmostApplication()
    local root = hs.axuielement.applicationElement(app)
    if not root then return nil, "Accessibility情報を取得できません" end

    local result = findLargestText(root)
    if not result.text or result.text == "" then
        return nil, "Terminal本文を取得できません"
    end

    return result.text, nil
end

function M.markPasteStart()
    local text, err = M.readTerminal()
    if not text then
        print("[Terminal Capture] " .. tostring(err))
        return
    end

    M.state.baselineText = text
    M.state.pastedText = hs.pasteboard.getContents()
    M.state.armed = true
    print("[Terminal Capture] Start recorded")
end

local function findLastPlain(text, target)
    if not target or target == "" then return nil end
    local last = nil
    local start = 1
    while true do
        local position = string.find(text, target, start, true)
        if not position then break end
        last = position
        start = position + 1
    end
    return last
end

local function stripFinalPrompt(text)
    text = text:gsub("[\r\n]+$", "")
    local before, lastLine = text:match("^(.*)\n([^\n]*)$")
    if not before or not lastLine then return text end

    local normalized = lastLine:gsub("\194\160", " ")
    if normalized:match("^[^%s@]+@[^%s]+%s+.-%s+%%[%s]*$") then
        return before
    end
    return text
end

function M.extractSession()
    if not M.state.armed then
        return nil, "先にTerminalへ⌘Vしてください"
    end

    local current, err = M.readTerminal()
    if not current then return nil, err end

    local baseline = M.state.baselineText
    local delta = nil

    if baseline and current:sub(1, #baseline) == baseline then
        delta = current:sub(#baseline + 1)
    end

    if not delta or delta == "" then
        local pasted = M.state.pastedText
        if type(pasted) == "string" and pasted ~= "" then
            local position = findLastPlain(current, pasted)
            if position then delta = current:sub(position) end
        end
    end

    if not delta or delta == "" then
        return nil, "今回の実行範囲を特定できませんでした"
    end

    return stripFinalPrompt(delta), nil
end

function M.copySession()
    local text, err = M.extractSession()
    if not text then
        hs.alert.show(tostring(err), 2)
        return
    end

    hs.pasteboard.setContents(text)
    hs.alert.show("今回のコマンド + 出力をコピー", 1)
    print("[Terminal Capture] Copied " .. tostring(#text) .. " bytes")
end

M.pasteWatcher = hs.eventtap.new({
    hs.eventtap.event.types.keyDown
}, function(event)
    if not frontmostIsTerminal() then return false end

    local flags = event:getFlags()
    local keyCode = event:getKeyCode()

    if keyCode == hs.keycodes.map["v"]
        and flags.cmd
        and not flags.ctrl
        and not flags.alt
    then
        M.markPasteStart()
    end

    return false
end)
M.pasteWatcher:start()

M.copySequence = keySequence.new({
    timeout = 1.0,
    condition = function()
        return frontmostIsTerminal()
    end,
    action = function()
        M.copySession()
    end,
})

print("Terminal Capture loaded")
print("Cmd+V -> record start")
print("Cmd -> Eisu -> Space -> copy")

return M
