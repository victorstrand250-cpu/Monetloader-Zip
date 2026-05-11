script_name('InterfaceLogger')
script_author('Victor Strand')
script_version('2.1')
script_version_number(21)
script_description('Arizona packet 220 logger with UI')

local imgui = require('mimgui')
local enc   = require('encoding')

enc.default = 'CP1251'
local u8  = enc.UTF8
local new = imgui.new
local MDS = MONET_DPI_SCALE
local sw, sh = getScreenResolution()

-- ===================================================
--  СТРОКИ (все корректные CP1251 hex)
-- ===================================================
local S = {
    title      = u8('\xc8\xed\xf2\xe5\xf0\xf4\xe5\xe9\xf1 \xcb\xee\xe3\xe3\xe5\xf0'),
    rec_on     = u8('\xc7\xe0\xef\xe8\xf1\xfc \xc2\xca\xcb'),
    rec_off    = u8('\xc7\xe0\xef\xe8\xf1\xfc \xc2\xdb\xca\xcb'),
    clear      = u8('\xce\xf7\xe8\xf1\xf2\xe8\xf2\xfc'),
    save_file  = u8('\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc \xe2 \xf4\xe0\xe9\xeb'),
    entries    = u8('\xe7\xe0\xef\xe8\xf1\xe5\xe9'),
    filter_iid = u8('\xd4\xe8\xeb\xfc\xf2\xf0 \xef\xee IID'),
    all_iid    = u8('\xc2\xf1\xe5 IID'),
    autoscroll = u8('\xc0\xe2\xf2\xee\xef\xf0\xee\xea\xf0\xf3\xf2\xea\xe0'),
    types      = u8('\xd2\xe8\xef\xfb \xf1\xee\xe1\xfb\xf2\xe8\xe9'),
    client     = u8('\xea\xeb\xe8\xe5\xed\xf2'),
    server     = u8('\xf1\xe5\xf0\xe2\xe5\xf0'),
    saved      = u8('\xd1\xee\xf5\xf0\xe0\xed\xe5\xed\xee'),
    rows_saved = u8('\xf1\xf2\xf0\xee\xea \xf1\xee\xf5\xf0\xe0\xed\xe5\xed\xee'),
    filters    = u8('\xd4\xe8\xeb\xfc\xf2\xf0\xfb'),
    -- чат (CP1251 напрямую, без u8)
    chat_on    = '\xc7\xe0\xef\xe8\xf1\xfc \xc2\xca\xcb\xfe\xc7\xc5\xcd\xc0',
    chat_off   = '\xc7\xe0\xef\xe8\xf1\xfc \xc2\xdb\xca\xcb\xfe\xc7\xc5\xcd\xc0',
    chat_hint  = '/il \xe2\xea\xeb/\xe2\xfb\xea\xeb \xee\xea\xed\xee | /ilstart /ilstop',
}

-- ===================================================
--  ЦВЕТА
-- ===================================================
local COL = {
    accent   = imgui.ImVec4(0.18, 0.82, 0.45, 1.0),
    fm       = imgui.ImVec4(0.35, 0.72, 1.00, 1.0),
    toggle   = imgui.ImVec4(1.00, 0.82, 0.20, 1.0),
    click    = imgui.ImVec4(0.88, 0.42, 1.00, 1.0),
    state    = imgui.ImVec4(1.00, 0.48, 0.20, 1.0),
    muted    = imgui.ImVec4(0.42, 0.42, 0.48, 1.0),
    dir_in   = imgui.ImVec4(0.40, 0.82, 1.00, 0.80),
    dir_out  = imgui.ImVec4(1.00, 0.60, 0.40, 0.80),
    data     = imgui.ImVec4(0.55, 0.88, 0.68, 0.92),
    hdr_bg   = 0xFF182818,
    hdr_bar  = 0xFF28E060,
    hdr_text = imgui.ImVec4(0.30, 1.00, 0.55, 1.0),
}

local function typeCol(t)
    if t == 'FM'     then return COL.fm
    elseif t == 'TOGGLE' then return COL.toggle
    elseif t == 'CLICK'  then return COL.click
    elseif t == 'STATE'  then return COL.state
    end
    return COL.muted
end

-- ===================================================
--  СОСТОЯНИЕ
-- ===================================================
local MAX_ENTRIES = 300
local enabled     = false
local log         = {}
local iidSeen     = {}

local mainWindow = new.bool(false)
local autoScroll = new.bool(true)
local showFM     = new.bool(true)
local showToggle = new.bool(true)
local showClick  = new.bool(true)
local showState  = new.bool(true)
local filterIID  = new.int(-1)

-- ===================================================
--  ШРИФТЫ
-- ===================================================
local fMain, fMono, fTitle

imgui.OnInitialize(function()
    imgui.SwitchContext()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)

    local ttf = getWorkingDirectory()..'/lib/mimgui/trebucbd.ttf'
    if doesFileExist(ttf) then
        local ranges = io.Fonts:GetGlyphRangesCyrillic()
        fTitle = io.Fonts:AddFontFromFileTTF(ttf, 17*MDS, nil, ranges)
        fMain  = io.Fonts:AddFontFromFileTTF(ttf, 14*MDS, nil, ranges)
        fMono  = io.Fonts:AddFontFromFileTTF(ttf, 12*MDS, nil, ranges)
    end

    local s = imgui.GetStyle()
    s.WindowPadding     = imgui.ImVec2(10*MDS, 10*MDS)
    s.FramePadding      = imgui.ImVec2(7*MDS,  5*MDS)
    s.ItemSpacing       = imgui.ImVec2(6*MDS,  5*MDS)
    s.WindowRounding    = 8*MDS
    s.ChildRounding     = 5*MDS
    s.FrameRounding     = 5*MDS
    s.ScrollbarRounding = 3*MDS
    s.ScrollbarSize     = 12*MDS
    s.GrabMinSize       = 20*MDS
    s.WindowBorderSize  = 1
    s.FrameBorderSize   = 0
    s.ChildBorderSize   = 1

    local c = s.Colors
    local I = imgui.Col
    c[I.WindowBg]             = imgui.ImVec4(0.07, 0.07, 0.09, 0.97)
    c[I.ChildBg]              = imgui.ImVec4(0.04, 0.04, 0.06, 1.00)
    c[I.Border]               = imgui.ImVec4(0.18, 0.18, 0.24, 1.00)
    c[I.FrameBg]              = imgui.ImVec4(0.11, 0.11, 0.15, 1.00)
    c[I.FrameBgHovered]       = imgui.ImVec4(0.18, 0.18, 0.24, 1.00)
    c[I.FrameBgActive]        = imgui.ImVec4(0.22, 0.22, 0.30, 1.00)
    c[I.TitleBg]              = imgui.ImVec4(0.04, 0.04, 0.07, 1.00)
    c[I.TitleBgActive]        = imgui.ImVec4(0.06, 0.06, 0.10, 1.00)
    c[I.Button]               = imgui.ImVec4(0.13, 0.13, 0.18, 1.00)
    c[I.ButtonHovered]        = imgui.ImVec4(0.20, 0.20, 0.28, 1.00)
    c[I.ButtonActive]         = imgui.ImVec4(0.09, 0.09, 0.13, 1.00)
    c[I.Header]               = imgui.ImVec4(0.13, 0.13, 0.18, 1.00)
    c[I.HeaderHovered]        = imgui.ImVec4(0.20, 0.20, 0.28, 1.00)
    c[I.HeaderActive]         = imgui.ImVec4(0.15, 0.52, 0.32, 1.00)
    c[I.CheckMark]            = imgui.ImVec4(0.18, 0.82, 0.45, 1.00)
    c[I.SliderGrab]           = imgui.ImVec4(0.18, 0.82, 0.45, 1.00)
    c[I.SliderGrabActive]     = imgui.ImVec4(0.22, 1.00, 0.55, 1.00)
    c[I.Text]                 = imgui.ImVec4(0.87, 0.87, 0.90, 1.00)
    c[I.TextDisabled]         = imgui.ImVec4(0.38, 0.38, 0.44, 1.00)
    c[I.ScrollbarBg]          = imgui.ImVec4(0.04, 0.04, 0.06, 1.00)
    c[I.ScrollbarGrab]        = imgui.ImVec4(0.18, 0.82, 0.45, 0.75)
    c[I.ScrollbarGrabHovered] = imgui.ImVec4(0.18, 0.82, 0.45, 1.00)
    c[I.ScrollbarGrabActive]  = imgui.ImVec4(0.22, 1.00, 0.55, 1.00)
    c[I.Separator]            = imgui.ImVec4(0.20, 0.20, 0.28, 1.00)
end)

-- ===================================================
--  ХЕЛПЕРЫ
-- ===================================================
local function addEntry(t, iid, sub, extra)
    if not iidSeen[iid] then
        iidSeen[iid] = {FM=0, TOGGLE=0, CLICK=0, STATE=0}
    end
    if iidSeen[iid][t] then
        iidSeen[iid][t] = iidSeen[iid][t] + 1
    end
    if #log >= MAX_ENTRIES then table.remove(log, 1) end
    table.insert(log, {
        type  = t,
        iid   = iid,
        sub   = sub,
        time  = os.date('%H:%M:%S'),
        extra = extra or '',
    })
end

local function entryVisible(e)
    local fi = filterIID[0]
    if fi >= 0 and e.iid ~= fi      then return false end
    if e.type == 'FM'     and not showFM[0]     then return false end
    if e.type == 'TOGGLE' and not showToggle[0] then return false end
    if e.type == 'CLICK'  and not showClick[0]  then return false end
    if e.type == 'STATE'  and not showState[0]  then return false end
    return true
end

local function saveToFile()
    local dir = getWorkingDirectory()..'/InterfaceLogger'
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    local f = io.open(dir..'/log.txt', 'a')
    if not f then return 0 end
    local n = 0
    for _, e in ipairs(log) do
        if entryVisible(e) then
            f:write(string.format('[%s] IID=%-3d [%s] sub=%-4s %s\n',
                e.time, e.iid, e.type,
                tostring(e.sub ~= nil and e.sub or '-'),
                e.extra))
            n = n + 1
        end
    end
    f:close()
    return n
end

local function colorBtn(label, w, h, bg, hov)
    imgui.PushStyleColor(imgui.Col.Button,        bg)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, hov)
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(bg.x*0.7, bg.y*0.7, bg.z*0.7, 1))
    local clicked = imgui.Button(label, imgui.ImVec2(w, h))
    imgui.PopStyleColor(3)
    return clicked
end

local function iidBtn(label, active)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 4*MDS)
    if active then
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.15, 0.50, 0.30, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.60, 0.36, 1))
    else
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10, 0.10, 0.14, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.18, 0.26, 1))
    end
    local clicked = imgui.Button(label, imgui.ImVec2(-1, 26*MDS))
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(1)
    return clicked
end

-- ===================================================
--  UI
-- ===================================================
local WW = 660 * MDS
local WH = 500 * MDS

imgui.OnFrame(
    function() return mainWindow[0] end,
    function(self)
        self.HideCursor = false

        imgui.SetNextWindowSize(imgui.ImVec2(WW, WH), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(
            imgui.ImVec2(sw/2, sh/2),
            imgui.Cond.FirstUseEver,
            imgui.ImVec2(0.5, 0.5)
        )

        local wf = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
        if fTitle then imgui.PushFont(fTitle) end
        imgui.Begin(S.title, mainWindow, wf)
        if fTitle then imgui.PopFont() end

        if fMain then imgui.PushFont(fMain) end

        -- ============================================
        --  ШАПКА
        -- ============================================
        local bH = 30 * MDS

        -- Кнопка Запись ВКЛ/ВЫКЛ
        if enabled then
            if colorBtn(S.rec_on, 130*MDS, bH,
                imgui.ImVec4(0.06, 0.42, 0.22, 1),
                imgui.ImVec4(0.08, 0.55, 0.28, 1)
            ) then
                enabled = false
                sampAddChatMessage('{E74C3C}[IL] '..S.chat_off, -1)
            end
        else
            if colorBtn(S.rec_off, 130*MDS, bH,
                imgui.ImVec4(0.32, 0.07, 0.07, 1),
                imgui.ImVec4(0.45, 0.10, 0.10, 1)
            ) then
                enabled = true
                sampAddChatMessage('{2ECC71}[IL] '..S.chat_on, -1)
            end
        end

        imgui.SameLine()

        -- Кнопка Очистить
        if colorBtn(S.clear, 95*MDS, bH,
            imgui.ImVec4(0.16, 0.16, 0.22, 1),
            imgui.ImVec4(0.24, 0.24, 0.34, 1)
        ) then
            log = {}
            iidSeen = {}
        end

        imgui.SameLine()

        -- Кнопка Сохранить в файл
        if colorBtn(S.save_file, 160*MDS, bH,
            imgui.ImVec4(0.08, 0.24, 0.16, 1),
            imgui.ImVec4(0.12, 0.34, 0.22, 1)
        ) then
            local n = saveToFile()
            sampAddChatMessage('{2ECC71}[IL] '..S.saved..': '..n..' '..S.rows_saved, -1)
        end

        imgui.SameLine()

        -- Счётчик записей
        local vis = 0
        for _, e in ipairs(log) do if entryVisible(e) then vis = vis + 1 end end
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5*MDS)
        imgui.PushStyleColor(imgui.Col.Text, COL.muted)
        imgui.Text(vis..' / '..#log..' '..S.entries)
        imgui.PopStyleColor()

        imgui.Separator()

        -- ============================================
        --  ТЕЛО: левая панель + лог
        -- ============================================
        local leftW = 190 * MDS
        local avail = imgui.GetContentRegionAvail()
        local bodyH = avail.y
        local rightW = avail.x - leftW - 8*MDS

        -- ---------- ЛЕВАЯ ПАНЕЛЬ ----------
        imgui.BeginChild('##sidebar', imgui.ImVec2(leftW, bodyH), true)

        imgui.PushStyleColor(imgui.Col.Text, COL.accent)
        imgui.Text(S.filters)
        imgui.PopStyleColor()
        imgui.Separator()
        imgui.Spacing()

        -- Кнопка "Все IID"
        if iidBtn(S.all_iid, filterIID[0] == -1) then
            filterIID[0] = -1
        end
        imgui.Spacing()

        -- Кнопки по каждому IID
        local sortedIIDs = {}
        for iid in pairs(iidSeen) do table.insert(sortedIIDs, iid) end
        table.sort(sortedIIDs)

        for _, iid in ipairs(sortedIIDs) do
            local cnt = iidSeen[iid]
            local active = (filterIID[0] == iid)
            if iidBtn('IID = '..iid, active) then
                filterIID[0] = (filterIID[0] == iid) and -1 or iid
            end
            if fMono then imgui.PushFont(fMono) end
            imgui.PushStyleColor(imgui.Col.Text, COL.muted)
            imgui.Text(string.format('  FM:%-3d  TG:%-3d', cnt.FM, cnt.TOGGLE))
            imgui.Text(string.format('  CL:%-3d  ST:%-3d', cnt.CLICK, cnt.STATE))
            imgui.PopStyleColor()
            if fMono then imgui.PopFont() end
            imgui.Spacing()
        end

        imgui.Separator()
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Text, COL.accent)
        imgui.Text(S.types)
        imgui.PopStyleColor()
        imgui.Separator()
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Text, COL.fm)
        imgui.Checkbox('FM  ('..S.server..')', showFM)
        imgui.PopStyleColor()

        imgui.PushStyleColor(imgui.Col.Text, COL.toggle)
        imgui.Checkbox('TOGGLE', showToggle)
        imgui.PopStyleColor()

        imgui.PushStyleColor(imgui.Col.Text, COL.click)
        imgui.Checkbox('CLICK  ('..S.client..')', showClick)
        imgui.PopStyleColor()

        imgui.PushStyleColor(imgui.Col.Text, COL.state)
        imgui.Checkbox('STATE  ('..S.client..')', showState)
        imgui.PopStyleColor()

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Text, COL.muted)
        imgui.Checkbox(S.autoscroll, autoScroll)
        imgui.PopStyleColor()

        imgui.EndChild()

        imgui.SameLine()

        -- ---------- ЛОГ ----------
        imgui.BeginChild('##logpanel', imgui.ImVec2(rightW, bodyH), true)

        local prevIID = -9999

        for _, e in ipairs(log) do
            if entryVisible(e) then

                -- Заголовок при смене IID
                if e.iid ~= prevIID then
                    if prevIID ~= -9999 then
                        imgui.Spacing()
                        imgui.Spacing()
                    end
                    local dl = imgui.GetWindowDrawList()
                    local cp = imgui.GetCursorScreenPos()
                    local cw = imgui.GetContentRegionAvail().x
                    local hh = 24 * MDS

                    dl:AddRectFilled(
                        imgui.ImVec2(cp.x,      cp.y),
                        imgui.ImVec2(cp.x + cw, cp.y + hh),
                        COL.hdr_bg, 4*MDS
                    )
                    dl:AddRectFilled(
                        imgui.ImVec2(cp.x,           cp.y),
                        imgui.ImVec2(cp.x + 3*MDS,   cp.y + hh),
                        COL.hdr_bar, 2*MDS
                    )
                    imgui.Dummy(imgui.ImVec2(cw, hh))
                    imgui.SetCursorScreenPos(imgui.ImVec2(cp.x + 10*MDS, cp.y + (hh - 14*MDS)/2))
                    imgui.PushStyleColor(imgui.Col.Text, COL.hdr_text)
                    if fMain then imgui.PushFont(fMain) end
                    imgui.Text('Interface ID = '..e.iid)
                    if fMain then imgui.PopFont() end
                    imgui.PopStyleColor()

                    imgui.Spacing()
                    prevIID = e.iid
                end

                -- Строка лога
                if fMono then imgui.PushFont(fMono) end

                imgui.PushStyleColor(imgui.Col.Text, COL.muted)
                imgui.Text('['..e.time..']')
                imgui.PopStyleColor()
                imgui.SameLine()

                imgui.PushStyleColor(imgui.Col.Text, typeCol(e.type))
                imgui.Text(string.format('[%-6s]', e.type))
                imgui.PopStyleColor()
                imgui.SameLine()

                local isIn = (e.type == 'FM' or e.type == 'TOGGLE')
                imgui.PushStyleColor(imgui.Col.Text, isIn and COL.dir_in or COL.dir_out)
                imgui.Text(isIn and '[IN ]' or '[OUT]')
                imgui.PopStyleColor()
                imgui.SameLine()

                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.84, 0.84, 0.90, 1.0))
                imgui.Text('sub='..(e.sub ~= nil and tostring(e.sub) or '-'))
                imgui.PopStyleColor()

                if fMono then imgui.PopFont() end

                if e.extra ~= '' then
                    imgui.PushStyleColor(imgui.Col.Text, COL.data)
                    if fMono then imgui.PushFont(fMono) end
                    imgui.PushTextWrapPos(imgui.GetCursorPosX() + rightW - 18*MDS)
                    imgui.Text('    '..e.extra:sub(1, 400))
                    imgui.PopTextWrapPos()
                    if fMono then imgui.PopFont() end
                    imgui.PopStyleColor()
                end
            end
        end

        if autoScroll[0] then
            imgui.SetScrollHereY(1.0)
        end

        imgui.EndChild()

        if fMain then imgui.PopFont() end

        imgui.End()
    end
)

-- ===================================================
--  ПАРСИНГ ПАКЕТОВ
-- ===================================================
addEventHandler('onReceivePacket', function(pid, bs)
    if pid ~= 220 or not enabled then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _  = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1 = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 then return end

    if b1 == 84 then
        local oi, iid = pcall(raknetBitStreamReadInt8, bs)
        local os, sub = pcall(raknetBitStreamReadInt8, bs)
        if not oi or not os then return end
        local ol, len = pcall(raknetBitStreamReadInt32, bs)
        local extra = ''
        if ol and len > 0 and len < 8192 then
            local oj, json = pcall(raknetBitStreamReadString, bs, len)
            if oj and json then extra = json:sub(1, 400) end
        end
        addEntry('FM', iid, sub, extra)

    elseif b1 == 62 then
        local oi, iid = pcall(raknetBitStreamReadInt8, bs)
        if not oi then return end
        local ob, st = pcall(raknetBitStreamReadBool, bs)
        addEntry('TOGGLE', iid, nil, ob and (st and 'ON' or 'OFF') or '?')
    end
end)

addEventHandler('onSendPacket', function(pid, bs)
    if pid ~= 220 or not enabled then return end
    raknetBitStreamSetReadOffset(bs, 0)
    local ok0, _  = pcall(raknetBitStreamReadInt8, bs)
    local ok1, b1 = pcall(raknetBitStreamReadInt8, bs)
    if not ok0 or not ok1 then return end

    if b1 == 63 then
        local oi, iid = pcall(raknetBitStreamReadInt8,  bs)
        local ob, bid = pcall(raknetBitStreamReadInt32, bs)
        local os, sub = pcall(raknetBitStreamReadInt32, bs)
        if not oi then return end
        local ol, len = pcall(raknetBitStreamReadInt32, bs)
        local extra = 'id='..(ob and tostring(bid) or '?')..' sub='..(os and tostring(sub) or '?')
        if ol and len > 0 and len < 8192 then
            local od, data = pcall(raknetBitStreamReadString, bs, len)
            if od and data and #data > 0 then
                extra = extra..' | '..data:sub(1, 300)
            end
        end
        addEntry('CLICK', iid, os and sub or nil, extra)

    elseif b1 == 66 then
        local oi, iid = pcall(raknetBitStreamReadInt8, bs)
        if not oi then return end
        local ob, st  = pcall(raknetBitStreamReadBool, bs)
        addEntry('STATE', iid, nil, ob and (st and 'ON' or 'OFF') or '?')
    end
end)

-- ===================================================
--  MAIN
-- ===================================================
function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(500) end

    sampRegisterChatCommand('il', function()
        mainWindow[0] = not mainWindow[0]
    end)

    sampRegisterChatCommand('ilstart', function()
        enabled = true
        sampAddChatMessage('{2ECC71}[IL] '..S.chat_on, -1)
    end)

    sampRegisterChatCommand('ilstop', function()
        enabled = false
        sampAddChatMessage('{E74C3C}[IL] '..S.chat_off, -1)
    end)

    sampAddChatMessage('{2ECC71}[InterfaceLogger v2.1]{FFFFFF} '..S.chat_hint, -1)

    while true do wait(0) end
end
