script_name('InfiniteRun')
script_author('claude')
script_version('1.1')

local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local enabled = false

function main()
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand('infrun', function()
        enabled = not enabled
        if enabled then
            msg(u8'Áåñêîíå÷íûé áåã: {00FF7F}ÂÊË')
        else
            setPlayerNeverGetsTired(PLAYER_HANDLE, false)
            msg(u8'Áåñêîíå÷íûé áåã: {FF4444}ÂÛÊË')
        end
    end)

    while not sampIsLocalPlayerSpawned() do wait(0) end

    msg(u8'Çàãðóæåí! /infrun — âêë/âûêë áåñêîíå÷íûé áåã')

    while true do
        if enabled then
            setPlayerNeverGetsTired(PLAYER_HANDLE, true)
        end
        wait(200)
    end
end

function msg(text)
    sampAddChatMessage('{00FF7F}[InfiniteRun]: {FFFFFF}' .. text, -1)
end
