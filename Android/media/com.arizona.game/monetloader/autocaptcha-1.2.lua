local inicfg = require 'inicfg'
local sampfuncs = require 'sampfuncs'

local iniName = 'autocaptcha.ini'
local cfg = inicfg.load({
    settings = {
        delay = 100,
        enabled = true,
    },
}, iniName)

if not doesFileExist(getWorkingDirectory() .. '/config/' .. iniName) then
    inicfg.save(cfg, iniName)
end

sampRegisterChatCommand("aucp", function ()
    cfg.settings.enabled = not cfg.settings.enabled
    inicfg.save(cfg, iniName)

    sampAddChatMessage("[AutoCaptcha] " .. (cfg.settings.enabled and "Включен" or "Выключен"), -1)
end)

sampRegisterChatCommand("aucp.delay", function (delay)
    delay = tonumber(delay)
    if not delay then
        sampAddChatMessage("[AutoCaptcha] Неверное значение", -1)
        return
    end

    cfg.settings.delay = delay
    inicfg.save(cfg, iniName)

    sampAddChatMessage("[AutoCaptcha] Задержка установлена на " .. delay .. " мс", -1)
end)
sampRegisterChatCommand("aucp.hud", function ()
    emulToggleInterface()
end) 

function main() wait(-1) end

function sendFrontendClick(interfaceid, id, subid, json)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, interfaceid)
    raknetBitStreamWriteInt32(bs, id)
    raknetBitStreamWriteInt32(bs, subid)
    raknetBitStreamWriteInt32(bs, #json)
    raknetBitStreamWriteString(bs, json)
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

function sendInterfaceLoaded(interfaceid, bool)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 66)
    raknetBitStreamWriteInt8(bs, interfaceid)
    raknetBitStreamWriteBool(bs, bool)
    raknetSendBitStreamEx(bs, 1, 10, 1)
    raknetDeleteBitStream(bs)
end

addEventHandler('onReceivePacket', function(id, bs)
    if not cfg.settings.enabled then return end

    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        local type = raknetBitStreamReadInt8(bs)
        
        if type == 84 then
            local interfaceid = raknetBitStreamReadInt8(bs)
            local subid = raknetBitStreamReadInt8(bs)
            --local len = raknetBitStreamReadInt32(bs)
            --local json = raknetBitStreamReadString(bs, len)
            
            if interfaceid == 81 then
                lua_thread.create(function()
                    wait(cfg.settings.delay)
                    sendFrontendClick(81, 0, 0, "")
                end)
                return false
            end
            
        elseif type == 62 then
            local interfaceid = raknetBitStreamReadInt8(bs)
            local toggle = raknetBitStreamReadBool(bs)
            
            if interfaceid == 81 then
                sendInterfaceLoaded(81, toggle)
                return false
            end
        end
    end
end)