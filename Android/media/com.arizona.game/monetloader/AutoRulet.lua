script_name('AutoRulet')
script_author('Victor Strand')
script_version('1.0')

local sampev = require('lib.samp.events')
local active = false

function sendFrontendClick(interfaceid, id, subid, json_str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, interfaceid)
    raknetBitStreamWriteInt32(bs, id)
    raknetBitStreamWriteInt32(bs, subid)
    raknetBitStreamWriteInt32(bs, #json_str)
    raknetBitStreamWriteString(bs, json_str)
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

function main()
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand('ar', function()
        active = not active
        -- Включено / Выключено
        sampAddChatMessage(
            active
            and '[AutoRulet]: {FFFFFF}\xc2\xea\xeb\xfe\xf7\xe5\xed\xee'
            or  '[AutoRulet]: {FFFFFF}\xc2\xfb\xea\xeb\xfe\xf7\xe5\xed\xee',
            0x00CC44)
        if active then
            -- Не трогайте экран во время открытия
            msg('\xcd\xe5 \xf2\xf0\xee\xe3\xe0\xe9\xf2\xe5 \xfd\xea\xf0\xe0\xed \xe2\xee \xe2\xf0\xe5\xec\xff \xee\xf2\xea\xf0\xfb\xf2\xe8\xff')
            -- Если надо открыть несколько рулеток -- запусти /ar
            msg('\xc5\xf1\xeb\xe8 \xed\xe0\xe4\xee \xee\xf2\xea\xf0\xfb\xf2\xfc \xed\xe5\xf1\xea\xee\xeb\xfc\xea\xee \xf0\xf3\xeb\xe5\xf2\xee\xea \x97 \xe7\xe0\xef\xf3\xf1\xf2\xe8 /ar')
        end
    end)

    while not sampIsLocalPlayerSpawned() do wait(0) end

    -- Авто открытие рулеток загружен
    msg('\xc0\xe2\xf2\xee \xee\xf2\xea\xf0\xfb\xf2\xe8\xe5 \xf0\xf3\xeb\xe5\xf2\xee\xea \xe7\xe0\xe3\xf0\xf3\xe6\xe5\xed')
    -- by Victor Strand
    msg('by Victor Strand')
    -- Активация /ar
    msg('\xc0\xea\xf2\xe8\xe2\xe0\xf6\xe8\xff /ar')

    while true do
        wait(0)
        if active then
            sendFrontendClick(76, 0, 0, "0")
            wait(1000)
            sendFrontendClick(76, 0, 2, "0")
            wait(1000)
        end
    end
end

function sampev.onShowDialog(did, style, title, button1, button2, text)
    if active then
        if text:find('\xcf\xee\xe7\xe4\xf0\xe0\xe2\xeb\xff\xe5\xec \xf1 \xef\xee\xeb\xf3\xf7\xe5\xed\xe8\xe5\xec') then
            sampSendDialogResponse(did, 1, 0, 0)
            return false
        end
    end
end

function msg(text)
    sampAddChatMessage('[AutoRulet]: {FFFFFF}' .. text, 0x00CC44)
end
