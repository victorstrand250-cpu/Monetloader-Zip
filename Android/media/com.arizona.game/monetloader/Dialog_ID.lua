script_name('DialogID')
script_author('fixed by Victor Strand')
script_version('1.1')

-- Показывает ID каждого SAMP диалога в чате
-- Включить/выключить: /di

local sampev  = require('samp.events')
local toggled = false

function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('di', function()
        toggled = not toggled
        sampAddChatMessage(toggled and '\xc2\xea\xeb\xfe\xf7\xe5\xed\xee' or '\xc2\xfb\xea\xeb\xfe\xf7\xe5\xed\xee', -1)
    end)

    sampAddChatMessage('[DialogID] \xc7\xe0\xe3\xf0\xf3\xe6\xe5\xed. /di', -1)

    while true do wait(0) end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if toggled then
        sampAddChatMessage('{FF8800}[DLG] id='..dialogId
            ..' style='..style
            ..' title='..tostring(title):sub(1,40), -1)
    end
end
