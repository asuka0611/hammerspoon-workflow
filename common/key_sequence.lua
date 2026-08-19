-- ============================================
-- Key Sequence
-- Command単独 -> 英数 -> Space
-- ============================================

local M = {}

function M.new(options)
    local obj = {}
    local TIMEOUT = options.timeout or 1.0
    local EISU_KEYCODE = hs.keycodes.map["eisu"] or 102
    local SPACE_KEYCODE = hs.keycodes.map["space"]

    local stage = 0
    local lastTime = 0
    local cmdDown = false
    local cmdEligible = false
    local cmdUsedWithOtherKey = false
    local consumeEisuUp = false
    local consumeSpaceUp = false

    local function allowed()
        if not options.condition then return true end
        return options.condition()
    end

    local function reset()
        stage = 0
        lastTime = 0
        consumeEisuUp = false
        consumeSpaceUp = false
    end

    obj.tap = hs.eventtap.new({
        hs.eventtap.event.types.flagsChanged,
        hs.eventtap.event.types.keyDown,
        hs.eventtap.event.types.keyUp,
    }, function(event)
        local eventType = event:getType()
        local keyCode = event:getKeyCode()
        local flags = event:getFlags()
        local now = hs.timer.secondsSinceEpoch()

        if eventType == hs.eventtap.event.types.flagsChanged then
            local commandIsDown = flags.cmd == true

            if commandIsDown and not cmdDown then
                cmdDown = true
                cmdUsedWithOtherKey = false
                cmdEligible = not flags.shift and not flags.ctrl and not flags.alt
            elseif not commandIsDown and cmdDown then
                cmdDown = false
                if cmdEligible and not cmdUsedWithOtherKey and allowed() then
                    stage = 1
                    lastTime = now
                    print("[Key Sequence] 1/3 Command")
                else
                    reset()
                end
            end
            return false
        end

        if eventType == hs.eventtap.event.types.keyDown and cmdDown then
            cmdUsedWithOtherKey = true
            reset()
            return false
        end

        if stage > 0 and now - lastTime > TIMEOUT then
            reset()
        end

        if eventType == hs.eventtap.event.types.keyUp and keyCode == EISU_KEYCODE and consumeEisuUp then
            consumeEisuUp = false
            return true
        end

        if eventType == hs.eventtap.event.types.keyUp and keyCode == SPACE_KEYCODE and consumeSpaceUp then
            consumeSpaceUp = false
            return true
        end

        if eventType ~= hs.eventtap.event.types.keyDown then
            return false
        end

        if stage > 0 and not allowed() then
            reset()
            return false
        end

        if stage == 1 then
            if keyCode == EISU_KEYCODE then
                stage = 2
                lastTime = now
                consumeEisuUp = true
                print("[Key Sequence] 2/3 Eisu")
                return true
            end
            reset()
            return false
        end

        if stage == 2 then
            if keyCode == SPACE_KEYCODE then
                consumeSpaceUp = true
                reset()
                print("[Key Sequence] 3/3 Space")
                if options.action then options.action() end
                return true
            end
            reset()
            return false
        end

        return false
    end)

    obj.tap:start()

    function obj.stop()
        if obj.tap then obj.tap:stop() end
    end

    return obj
end

return M
