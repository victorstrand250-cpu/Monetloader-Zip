script_name('DBG')
script_author('Victor Strand')
script_version('1.4')
script_properties('work-in-pause')

local sampev = require('lib.samp.events')

local enabled    = false
local logRPC     = false   -- /dbgrpc — логировать исходящие RPC
local font       = renderCreateFont('Arial', 9, 4)
local resx, resy = getScreenResolution()

local COL_OBJ = 0xFFFFFFFF
local COL_3DT = 0xFF88FFCC
local COL_PLR = 0xFFFFDD44
local COL_DLG = 0xFFAADDFF
local COL_CP  = 0xFF44FF88
local COL_RPC = 0xFFFF8844

local DIST = 10

-- последний диалог
local lastDialog = {id=0, style=0, title='', b1='', b2=''}
function sampev.onShowDialog(id, style, title, b1, b2, text)
    lastDialog = {id=id, style=style, title=title or '', b1=b1 or '', b2=b2 or ''}
end

-- чекпоинт обычный
local cp = { active=false, x=0, y=0, z=0, size=0, kind='none' }
function sampev.onSetCheckpoint(pos, size)
    cp.active = true
    cp.x, cp.y, cp.z = pos.x, pos.y, pos.z
    cp.size = size or 0
    cp.kind = 'NORMAL'
end
function sampev.onDisableCheckpoint()
    if cp.kind == 'NORMAL' then cp.active = false end
end

-- гоночный чекпоинт
function sampev.onSetRaceCheckpoint(cpType, pos, nextPos, radius)
    cp.active = true
    if type(pos) == 'table' then
        cp.x = pos.x or pos[1] or 0
        cp.y = pos.y or pos[2] or 0
        cp.z = pos.z or pos[3] or 0
    end
    cp.size = radius or 0
    cp.kind = 'RACE type=' .. tostring(cpType)
end
function sampev.onDisableRaceCheckpoint()
    if cp.kind ~= 'NORMAL' then cp.active = false end
end

-- ── Лог исходящих RPC ────────────────────────────────────────
-- Перехватываем onSendRpc чтобы видеть что игра сама шлёт серверу
local rpcLog = {}
local rpcLogMax = 8

function sampev.onSendRpc(id, bs)
    if not logRPC then return end
    -- читаем первые байты для информации
    local info = string.format('RPC out: id=%d', id)
    table.insert(rpcLog, 1, info)
    if #rpcLog > rpcLogMax then table.remove(rpcLog) end
end

function sampev.onSendPacket(id, bs)
    if not logRPC then return end
    local info = string.format('PKT out: id=%d', id)
    table.insert(rpcLog, 1, info)
    if #rpcLog > rpcLogMax then table.remove(rpcLog) end
end

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end

    sampRegisterChatCommand('dbg', function()
        enabled = not enabled
        sampAddChatMessage('[DBG] ' .. (enabled and 'ON' or 'OFF'), -1)
    end)

    -- включить лог RPC — подъедь к чекпоинту, проедь через него
    -- и смотри какой RPC id появился в момент засчитывания
    sampRegisterChatCommand('dbgrpc', function()
        logRPC = not logRPC
        rpcLog = {}
        sampAddChatMessage('[DBG] RPC log: ' .. (logRPC and 'ON' or 'OFF'), -1)
        if logRPC then
            sampAddChatMessage('[DBG] Теперь проедь через чекпоинт и смотри лог', -1)
        end
    end)

    sampAddChatMessage('[DBG] /dbg — оверлей  /dbgrpc — лог RPC при проезде чекпоинта', -1)

    while true do
        wait(0)
        if not enabled then goto continue end
        if not sampIsLocalPlayerSpawned() then goto continue end

        local px, py, pz = getCharCoordinates(PLAYER_PED)

        -- чекпоинт
        if cp.active then
            local d = getDistanceBetweenCoords3d(px, py, pz, cp.x, cp.y, cp.z)
            local sx, sy
            local ok, onscr = pcall(isPointOnScreen, cp.x, cp.y, cp.z, 1)
            if ok and onscr then
                sx, sy = convert3DCoordsToScreen(cp.x, cp.y, cp.z)
            else
                sx, sy = resx * 0.5, 30
            end
            renderFontDrawText(font,
                string.format('[%s] x:%.1f y:%.1f z:%.1f dist:%.1fm sz:%.1f',
                    cp.kind, cp.x, cp.y, cp.z, d, cp.size),
                sx, sy, COL_CP)
        else
            renderFontDrawText(font, 'CP: none', resx * 0.5, 30, COL_CP)
        end

        -- RPC лог (левый верхний угол)
        if logRPC then
            renderFontDrawText(font, '-- RPC/PKT log (newest top) --', 10, 10, COL_RPC)
            for i, line in ipairs(rpcLog) do
                renderFontDrawText(font, line, 10, 10 + i * 14, COL_RPC)
            end
        end

        -- объекты в DIST
        local ok0, objs = pcall(getAllObjects)
        if ok0 and objs then
            for _, handle in ipairs(objs) do
                local ok2, _, ox, oy, oz = pcall(getObjectCoordinates, handle)
                if ok2 then
                    local dist = getDistanceBetweenCoords3d(px, py, pz, ox, oy, oz)
                    if dist <= DIST then
                        local ok3, onscr2 = pcall(isObjectOnScreen, handle)
                        if ok3 and onscr2 then
                            local sx2, sy2 = convert3DCoordsToScreen(ox, oy, oz)
                            local model = 0
                            local ok4, m = pcall(getObjectModel, handle); if ok4 then model = m end
                            local sampId = -1
                            local ok5, sid = pcall(sampGetObjectSampIdByHandle, handle); if ok5 then sampId = sid end
                            local txt = sampId ~= -1
                                and string.format('obj id:%d model:%d dist:%.1fm', sampId, model, dist)
                                or  string.format('obj id:- model:%d dist:%.1fm', model, dist)
                            renderFontDrawText(font, txt, sx2, sy2, COL_OBJ)
                        end
                    end
                end
            end
        end

        -- 3D тексты в DIST
        for id = 0, 1023 do
            local ok, def = pcall(sampIs3dTextDefined, id)
            if ok and def then
                local ok2, text, color, x, y, z = pcall(sampGet3dTextInfoById, id)
                if ok2 and x then
                    local dist = getDistanceBetweenCoords3d(px, py, pz, x, y, z)
                    if dist <= DIST then
                        local ok3, onscr2 = pcall(isPointOnScreen, x, y, z, 1)
                        if ok3 and onscr2 then
                            local sx2, sy2 = convert3DCoordsToScreen(x, y, z)
                            local str = (text or ''):gsub('{%x%x%x%x%x%x}',''):sub(1, 20)
                            renderFontDrawText(font,
                                string.format('3dt id:%d dist:%.1fm [%s]', id, dist, str),
                                sx2, sy2, COL_3DT)
                        end
                    end
                end
            end
        end

        -- игроки в DIST
        for pid = 0, 999 do
            local ok, ped = pcall(sampGetCharHandleBySampPlayerId, pid)
            if ok and ped and ped ~= PLAYER_PED then
                local ok2, qx, qy, qz = pcall(getCharCoordinates, ped)
                if ok2 then
                    local dist = getDistanceBetweenCoords3d(px, py, pz, qx, qy, qz)
                    if dist <= DIST then
                        local ok3, onscr2 = pcall(isPointOnScreen, qx, qy, qz, 1)
                        if ok3 and onscr2 then
                            local sx2, sy2 = convert3DCoordsToScreen(qx, qy, qz + 1.0)
                            local ok4, name = pcall(sampGetPlayerNickname, pid)
                            local nick = (ok4 and name) and name or '?'
                            renderFontDrawText(font,
                                string.format('player id:%d %s dist:%.1fm', pid, nick, dist),
                                sx2, sy2, COL_PLR)
                        end
                    end
                end
            end
        end

        -- диалог
        if sampIsDialogActive() then
            local did = sampGetCurrentDialogId()
            renderFontDrawText(font,
                string.format('DLG id:%d sty:%d [%s] %s/%s',
                    did, lastDialog.style,
                    lastDialog.title:sub(1, 18),
                    lastDialog.b1:sub(1, 8),
                    lastDialog.b2:sub(1, 8)),
                10, resy - 30, COL_DLG)
        end

        ::continue::
    end
end


local sampev = require('lib.samp.events')

local enabled = false
local DIST    = 10   -- метров — фильтр для всех сущностей
local font    = renderCreateFont('Arial', 9, 4)
local resx, resy = getScreenResolution()

-- цвета
local COL_OBJ = 0xFFFFFFFF
local COL_3DT = 0xFF88FFCC
local COL_PLR = 0xFFFFDD44
local COL_DLG = 0xFFAADDFF
local COL_CP  = 0xFF44FF88

-- последний диалог
local lastDialog = {id=0, style=0, title='', b1='', b2=''}
function sampev.onShowDialog(id, style, title, b1, b2, text)
    lastDialog = {id=id, style=style, title=title or '', b1=b1 or '', b2=b2 or ''}
end

-- чекпоинт обычный
local cp = { active=false, x=0, y=0, z=0, size=0, kind='normal' }
function sampev.onSetCheckpoint(pos, size)
    cp.active = true
    cp.x, cp.y, cp.z = pos.x, pos.y, pos.z
    cp.size  = size or 0
    cp.kind  = 'normal'
end
function sampev.onDisableCheckpoint()
    if cp.kind == 'normal' then cp.active = false end
end

-- гоночный чекпоинт (именно его использует TramPilot и большинство серверных работ)
function sampev.onSetRaceCheckpoint(cpType, pos, nextPos, radius)
    cp.active = true
    if type(pos) == 'table' then
        cp.x = pos.x or pos[1] or 0
        cp.y = pos.y or pos[2] or 0
        cp.z = pos.z or pos[3] or 0
    end
    cp.size = radius or 0
    cp.kind = 'race (type=' .. tostring(cpType) .. ')'
end
function sampev.onDisableRaceCheckpoint()
    if cp.kind ~= 'normal' then cp.active = false end
end

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end

    sampRegisterChatCommand('dbg', function()
        enabled = not enabled
        sampAddChatMessage('[DBG] ' .. (enabled and 'ON' or 'OFF'), -1)
    end)
    sampAddChatMessage('[DBG] /dbg — вкл/выкл  (фильтр ' .. DIST .. 'm)', -1)

    while true do
        wait(0)
        if not enabled then goto continue end
        if not sampIsLocalPlayerSpawned() then goto continue end

        local px, py, pz = getCharCoordinates(PLAYER_PED)

        -- ── Чекпоинт (всегда показываем если есть) ──────────────
        if cp.active then
            local d = getDistanceBetweenCoords3d(px, py, pz, cp.x, cp.y, cp.z)
            local ok, onscr = pcall(isPointOnScreen, cp.x, cp.y, cp.z, 1)
            local sx, sy
            if ok and onscr then
                sx, sy = convert3DCoordsToScreen(cp.x, cp.y, cp.z)
            else
                sx, sy = resx * 0.5, 30
            end
            renderFontDrawText(font,
                string.format('CHECKPOINT  x:%.1f y:%.1f z:%.1f  dist:%.1fm  size:%.1f',
                    cp.x, cp.y, cp.z, d, cp.size),
                sx, sy, COL_CP)
        else
            renderFontDrawText(font, 'CHECKPOINT: нет активного', resx * 0.5, 30, COL_CP)
        end

        -- ── GTA объекты в радиусе DIST ───────────────────────────
        local ok0, objs = pcall(getAllObjects)
        if ok0 and objs then
            for _, handle in ipairs(objs) do
                local ok2, _, ox, oy, oz = pcall(getObjectCoordinates, handle)
                if ok2 then
                    local dist = getDistanceBetweenCoords3d(px, py, pz, ox, oy, oz)
                    if dist <= DIST then
                        local ok3, onscr = pcall(isObjectOnScreen, handle)
                        if ok3 and onscr then
                            local sx, sy = convert3DCoordsToScreen(ox, oy, oz)
                            local model  = 0
                            local ok4, m = pcall(getObjectModel, handle)
                            if ok4 then model = m end
                            local sampId = -1
                            local ok5, sid = pcall(sampGetObjectSampIdByHandle, handle)
                            if ok5 then sampId = sid end
                            local txt
                            if sampId ~= -1 then
                                txt = string.format('obj id:%d model:%d dist:%.1fm', sampId, model, dist)
                            else
                                txt = string.format('obj id:- model:%d dist:%.1fm', model, dist)
                            end
                            renderFontDrawText(font, txt, sx, sy, COL_OBJ)
                        end
                    end
                end
            end
        end

        -- ── 3D Texts в радиусе DIST ──────────────────────────────
        for id = 0, 1023 do
            local ok, def = pcall(sampIs3dTextDefined, id)
            if ok and def then
                local ok2, text, color, x, y, z = pcall(sampGet3dTextInfoById, id)
                if ok2 and x then
                    local dist = getDistanceBetweenCoords3d(px, py, pz, x, y, z)
                    if dist <= DIST then
                        local ok3, onscr = pcall(isPointOnScreen, x, y, z, 1)
                        if ok3 and onscr then
                            local sx, sy = convert3DCoordsToScreen(x, y, z)
                            local str = (text or ''):gsub('{%x%x%x%x%x%x}',''):sub(1, 20)
                            renderFontDrawText(font,
                                string.format('3dt id:%d dist:%.1fm [%s]', id, dist, str),
                                sx, sy, COL_3DT)
                        end
                    end
                end
            end
        end

        -- ── Игроки в радиусе DIST ────────────────────────────────
        for pid = 0, 999 do
            local ok, ped = pcall(sampGetCharHandleBySampPlayerId, pid)
            if ok and ped and ped ~= PLAYER_PED then
                local ok2, qx, qy, qz = pcall(getCharCoordinates, ped)
                if ok2 then
                    local dist = getDistanceBetweenCoords3d(px, py, pz, qx, qy, qz)
                    if dist <= DIST then
                        local ok3, onscr = pcall(isPointOnScreen, qx, qy, qz, 1)
                        if ok3 and onscr then
                            local sx, sy = convert3DCoordsToScreen(qx, qy, qz + 1.0)
                            local ok4, name = pcall(sampGetPlayerNickname, pid)
                            local nick = (ok4 and name) and name or '?'
                            renderFontDrawText(font,
                                string.format('player id:%d %s dist:%.1fm', pid, nick, dist),
                                sx, sy, COL_PLR)
                        end
                    end
                end
            end
        end

        -- ── Диалог ───────────────────────────────────────────────
        if sampIsDialogActive() then
            local did = sampGetCurrentDialogId()
            renderFontDrawText(font,
                string.format('DLG id:%d sty:%d [%s] %s/%s',
                    did, lastDialog.style,
                    lastDialog.title:sub(1, 18),
                    lastDialog.b1:sub(1, 8),
                    lastDialog.b2:sub(1, 8)),
                10, 10, COL_DLG)
        end

        ::continue::
    end
end
