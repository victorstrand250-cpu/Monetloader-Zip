script_name('TramPilot')
script_author('Victor Strand')
script_version('4.1-monet')
script_version_number(15)
script_properties('work-in-pause')

local imgui   = require('mimgui')
local sampev  = require('lib.samp.events')
local enc     = require('encoding')
local widgets = require('widgets')
enc.default   = 'CP1251'
local u8  = enc.UTF8
local MDS = MONET_DPI_SCALE
local ffi = require('ffi')

local gta = ffi.load('GTASA')
ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
local function openLink(url) pcall(gta._Z12AND_OpenLinkPKc, url) end

local requests   = require('requests')
local bass       = nil
local menuStream = 0
local SOUND_URL  = 'https://files.catbox.moe/52dk8h.mp3'
local SOUND_FILE = '/trampilot/menu_sound.mp3'

pcall(function()
    bass = ffi.load('libbass.so')
    ffi.cdef[[
        int          BASS_Init(int device, unsigned long freq, unsigned long flags, void* win, void* clsid);
        unsigned long BASS_StreamCreateFile(int mem, const char* file, unsigned long long offset, unsigned long long length, unsigned long flags);
        unsigned long BASS_StreamCreateURL(const char* url, unsigned long offset, unsigned long flags, void* proc, void* user);
        int          BASS_ChannelPlay(unsigned long handle, int restart);
        int          BASS_ChannelStop(unsigned long handle);
        int          BASS_ChannelSetAttribute(unsigned long handle, unsigned long attrib, float value);
        int          BASS_StreamFree(unsigned long handle);
    ]]
    bass.BASS_Init(-1, 44100, 0, nil, nil)
end)

lua_thread.create(function()
    wait(2000)
    local wd  = getWorkingDirectory()
    local dir = wd .. '/trampilot'
    local path = wd .. SOUND_FILE
    if not doesDirectoryExist(dir) then createDirectory(dir) end
    if not doesFileExist(path) then
        local ok, resp = pcall(requests.get, SOUND_URL)
        if ok and resp and resp.status_code == 200 then
            local f = io.open(path, 'wb')
            if f then f:write(resp.text); f:close() end
        end
    end
end)

local function playMenuSound()
    if not bass then return end
    pcall(function()
        if menuStream ~= 0 then
            bass.BASS_ChannelStop(menuStream)
            bass.BASS_StreamFree(menuStream)
            menuStream = 0
        end
        local path = getWorkingDirectory() .. SOUND_FILE
        if doesFileExist(path) then
            menuStream = bass.BASS_StreamCreateFile(0, path, 0, 0, 0)
        else
            menuStream = bass.BASS_StreamCreateURL(SOUND_URL, 0, 0, nil, nil)
        end
        if menuStream ~= 0 then
            bass.BASS_ChannelSetAttribute(menuStream, 2, 0.8)
            bass.BASS_ChannelPlay(menuStream, 1)
        end
    end)
end

local function sendAlt()
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220); raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, 8);   raknetBitStreamWriteInt32(bs, 7)
    raknetBitStreamWriteInt32(bs, -1); raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteString(bs, '')
    raknetSendBitStreamEx(bs, 1, 7, 1); raknetDeleteBitStream(bs)
end

-- =============================================
-- СОСТОЯНИЕ БОТА
-- =============================================
local apc       = false
local callBobek = false
local stopFlag  = false
local checkpointCounter = 0
local atStop    = false

local cpX, cpY, cpZ = nil, nil, nil
local cpActive = false

local curBrakeX, curBrakeY, curBrakeZ = nil, nil, nil
local braking = false
local controlActive  = false
local lastTargetTime = 0

local TRAM_MODEL = 449

local function getTramCar()
    if not isCharInAnyCar(PLAYER_PED) then return nil end
    local ok, car = pcall(storeCarCharIsInNoSave, PLAYER_PED)
    if not ok or not car then return nil end
    local ok2, model = pcall(getCarModel, car)
    if ok2 and model == TRAM_MODEL then return car end
    return nil
end

local function inTram() return getTramCar() ~= nil end

local function getMarker()
    if cpActive and cpX then
        return true, cpX, cpY, cpZ
    end
    local ok2, r2 = pcall(getTargetBlipCoordinatesFixed)
    if ok2 and r2 then
        local bx, by, bz
        if type(r2) == 'table' then
            if type(r2.x) == 'number' then
                bx, by, bz = r2.x, r2.y, r2.z
            elseif type(r2[1]) == 'number' then
                bx, by, bz = r2[1], r2[2], r2[3]
            else
                local vals = {}
                for k,v in pairs(r2) do
                    if type(v) == 'number' then vals[#vals+1] = v end
                end
                bx, by, bz = vals[1], vals[2], vals[3]
            end
        elseif type(r2) == 'number' then
            bx = r2
        end
        if bx and type(bx) == 'number' and not (math.abs(bx) < 0.1 and math.abs(by or 0) < 0.1) then
            return true, bx, by or 0, bz or 0
        end
    end
    local ok3, r3 = pcall(getCheckpointCoordinates)
    if ok3 and r3 then
        local cx, cy, cz
        if type(r3) == 'table' then
            if type(r3.x) == 'number' then
                cx, cy, cz = r3.x, r3.y, r3.z
            elseif type(r3[1]) == 'number' then
                cx, cy, cz = r3[1], r3[2], r3[3]
            end
        elseif type(r3) == 'number' then
            cx = r3
        end
        if cx and type(cx) == 'number' and not (math.abs(cx) < 0.1 and math.abs(cy or 0) < 0.1) then
            return true, cx, cy or 0, cz or 0
        end
    end
    return false, 0, 0, 0
end

-- =============================================
-- ТОЧКИ ТОРМОЖЕНИЯ
-- =============================================
local brake_coords = {
    {-2264.9506835938, 732.50493164063,  49.79679107666},
    {-2264.875,        977.96145019531,  70.373799133301},
    {-2042.9405517578, 1305.6669921875,   7.6223087310791},
    {-1679.6846923828, 1292.7875976563,   7.4973087310791},
    {-1573.2088623047, 1011.6076660156,   7.4973087310791},
    {-1687.3196533203,  921.125,          25.122308731079},
    {-1972.1208496094,  921,              44.641761779785},
    {-1911.8176269531,  848.875,          35.49730682373},
    {-1658.4816894531,  848.875,          19.5728931427},
    {-1572.5378417969,  728.75,            7.6708054542542},
    {-1809.8125976563,  603.25,           34.998847961426},
    {-2004.6945800781,  265.88493652344,  31.753614425659},
    {-2006.5,           115.27388916016,  27.997308731079},
    {-2166.625,         -48.292022705078, 35.62230682373},
    {-2251.8759765625,   96.16723632813,  35.62230682373},
    {-2361.2368164063,  483.1110534668,   30.597286224365},
}

local foot_coords = {
    {-2265.5398, 501.7881, 1487.6927},
    {-2263.1133, 502.4485, 1487.6927},
    {-2261.7168, 504.5564, 1487.6927},
    {-2262.8914, 506.7906, 1487.6927},
}

-- =============================================
-- АВТО-ЕДА
-- =============================================
local autoEat            = false
local autoEatFood        = 0
local autoEatMinSatiety  = 80
local autoEatSatiety     = -1
local autoEatWaitSat     = false
local autoEatWaitEat     = false
local autoEatLastEat     = 0

-- Названия еды (CP1251): Чипсы, Рыба, Оленина
local FOOD_NAMES = {
    u8'\xd7\xe8\xef\xf1\xfb',
    u8'\xd0\xfb\xe1\xe0',
    u8'\xce\xeb\xe5\xed\xe8\xed\xe0',
}

-- =============================================
-- АНТИ-АДМИН
-- =============================================
local aaState  = false
local aaAngry  = 0
local aaNonrp  = nil
local aaTimes  = os.clock()
local antiAdminEnableTime = 0

local aaAdminTriggers = {
    '\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0',
    '\xf2\xe5\xeb\xe5\xef\xee\xf0\xf2\xe8\xf0\xee\xe2\xe0\xeb \xe2\xe0\xf1 \xed\xe0 \xea\xee\xee\xf0\xe4\xe8\xed\xe0\xf2\xfb',
    '\xee\xf2\xe2\xe5\xf2\xe8\xeb \xe2\xe0\xec:',
}
local aaOtveti1 = {'\xd7\xf2\xee \xed\xe0\xe4\xee?','\xd5\xf6\xee?','?','\xd5\xed\xee','\xc4\xe0?','\xe0','\xd7\xf2\xee?','\xe0\xf1\xfc??','\xcd?'}
local aaOtveti2 = {'\xe4\xe0 \xf2\xf3\xf2 \xff','\xfb \xf2\xf3\xf2 \xe7\xe0\xe4\xee\xeb\xe1\xe0\xeb\xe8','\xc4\xe0 \xc6\xc5 \xd5\xd0\xc5\xd0','\xed\xee\xf0\xec\xe0\xeb\xfc\xed\xee\xe5 \xf3\xe6\xe5','\xe2\xf0\xee\xf2\xfc \xf2\xfb\xf1?'}
local aaOtveti3 = {'\xce\xd5 \xdf \xc2 \xd8\xce\xca\xc5','\xd8\xd0\xc8 \xcf\xd0\xc8\xd8\xc5\xcb','\xcd\xd3 \xd8\xd2\xc0 \xd2\xc5\xd1\xd2\xc8\xd2\xc5 \xc5\xd9\xc5','\xd5\xe2\xe0\xf2\xe8\xf2 \xe4\xee\xed\xe8\xec\xe0\xf2\xfc!','\xe4\xe0 \xe1\xeb\xff \xff \xf4\xe8\xeb \xf3\xf1\xf2\xe0\xeb'}

math.randomseed(os.time() - os.clock() * 1000)

local function aaIsAdmin(text)
    for _, w in ipairs(aaAdminTriggers) do
        if text:find(w) then return true end
    end
    return false
end

local function aaSendReply(isNonRp)
    aaAngry = aaAngry + 1
    wait(math.random(3200, 4000))
    local mesg
    if aaAngry == 1 then
        mesg = aaOtveti1[math.random(#aaOtveti1)]
    elseif aaAngry == 2 then
        mesg = aaOtveti2[math.random(#aaOtveti2)]
    else
        mesg = aaOtveti3[math.random(#aaOtveti3)]
        aaAngry = 0
    end
    if isNonRp then
        sampSendChat('/b ' .. mesg)
    else
        sampSendChat(mesg)
    end
    aaTimes = os.clock()
end

lua_thread.create(function()
    while true do
        wait(0)
        if aaState then
            if sampIsDialogActive() then
                if os.clock() - aaTimes > 5 then
                    lua_thread.create(function() aaSendReply(aaNonrp ~= nil) end)
                    aaTimes = os.clock()
                end
            end
        end
    end
end)

-- =============================================
-- СОБЫТИЯ
-- =============================================
function sampev.onSetRaceCheckpoint(cpType, x, y, z, nx, ny, nz, radius)
    local function toNum(v, idx)
        if type(v) == 'number' then return v end
        if type(v) == 'table' then return v.x or v.y or v.z or v[idx] or 0 end
        local ok, n = pcall(function() return tonumber(v) end)
        if ok and n then return n end
        return 0
    end
    if type(x) == 'table' then
        cpX = x.x or x[1] or 0
        cpY = x.y or x[2] or 0
        cpZ = x.z or x[3] or 0
    else
        cpX = toNum(x, 1)
        cpY = toNum(y, 2)
        cpZ = toNum(z, 3)
    end
    cpActive = (type(cpX) == 'number' and cpX ~= 0)
end

function sampev.onDisableRaceCheckpoint()
    cpActive = false
    cpX, cpY, cpZ = nil, nil, nil
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    -- Авто-еда: Сытость
    if title and (title:find('\xd1\xfb\xf2\xee\xf1\xf2\xfc') or
        (text and (text:find('\xf1\xfb\xf2\xee\xf1\xf2\xfc') or text:find('\xd1\xfb\xf2\xee\xf1\xf2\xfc')))) then
        local val = (text or ''):match('\xf1\xfb\xf2\xee\xf1\xf2\xfc%s*:%s*(%d+%.?%d*)')
                 or (text or ''):match('(%d+%.%d+)%s*/')
                 or (text or ''):match('(%d+)%s*/')
        if val then autoEatSatiety = tonumber(val) end
        autoEatWaitSat = false
        lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 1, -1, '') end)
        return false
    end

    -- Авто-еда: Кушать
    if title and (title:find('\xca\xf3\xf8\xe0\xf2\xfc') or title:find('\xca\xf3\xf8')) then
        autoEatWaitEat = false
        if autoEat and (os.clock() - autoEatLastEat) > 10 then
            autoEatLastEat = os.clock()
            local row = autoEatFood
            lua_thread.create(function()
                wait(150)
                sampSendDialogResponse(dialogId, 1, row, '')
                wait(300)
                setGameKeyState(23, 255)
                wait(100)
                setGameKeyState(23, 0)
                wait(400)
                if sampIsDialogActive() then
                    sampSendDialogResponse(dialogId, 0, -1, '')
                end
            end)
        else
            lua_thread.create(function()
                wait(150)
                setGameKeyState(23, 255)
                wait(100)
                setGameKeyState(23, 0)
            end)
        end
        return false
    end

    -- Анти-админ: автоответ
    if aaState then
        lua_thread.create(function()
            aaNonrp = text and text:match('/b')
            wait(3000)
            sampSendDialogResponse(dialogId, 1, 0, '')
        end)
    end

    -- Остановить бота при подозрении на админа (если AA выключен)
    local isAdmin = (text or ''):find('A:')
        or (text or ''):find('\xe0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
        or (text or ''):find('\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
        or (text or ''):find('\xf2\xf3\xf2')
        or (text or ''):find('\xe2\xfb \xf2\xf3\xf2')
    if isAdmin and apc and not aaState then
        stopFlag = true; apc = false; controlActive = false
        local _car = getTramCar()
        if _car then
            taskCarDriveToCoord(PLAYER_PED, _car, 0, 0, 0, 0, 0, 7, 0)
            clearCharTasks(PLAYER_PED)
        end
    end
end

function sampev.onServerMessage(clr, text)
    if not text then return end
    if aaState and aaIsAdmin(text) then
        lua_thread.create(function() aaSendReply(false) end)
    end
    if aaState and (text:find('\xc2\xfb \xf2\xf3\xf2') or text:find('\xc2\xfb \xe7\xe4\xe5\xf1\xfc')
        or text:find('\xe2\xfb \xf2\xf3\xf2') or text:find('\xe2\xfb \xe7\xe4\xe5\xf1\xfc')) then
        lua_thread.create(function() aaSendReply(false) end)
    end
    if not aaState then
        local lo = text:lower()
        if lo:find('\xe0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
           and not lo:find('\xf2\xf0\xe0\xed\xf1\xef\xee\xf0\xf2')
           and not lo:find('\xe5\xf0\xee\xef\xf0\xe8\xff\xf2\xe8\xe5')
           and apc then
            stopFlag = true; apc = false; controlActive = false
            local _car = getTramCar()
            if _car then
                taskCarDriveToCoord(PLAYER_PED, _car, 0, 0, 0, 0, 0, 7, 0)
                clearCharTasks(PLAYER_PED)
            end
        end
    end
end

-- =============================================
-- UI
-- =============================================
local WinMain    = imgui.new.bool(false)
local wasMenuOpen = false
local resx, resy = getScreenResolution()

-- Константа: ширина окна и реальная ширина контента
-- WindowPadding = 16*MDS с каждой стороны => IW = W - 32*MDS
-- НО: BeginChild добавляет ещё свой внутренний padding.
-- Чтобы Child занимал ПОЛНУЮ ширину контента без смещения,
-- задаём ширину Child = IW и НЕ добавляем border (false) либо
-- учитываем border вручную. Проще: не использовать BeginChild
-- для блоков, а рисовать напрямую через Separator+Spacing.

imgui.OnInitialize(function()
    local imgio = imgui.GetIO()
    imgio.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    local st = imgui.GetStyle()
    st.WindowRounding   = 12;  st.FrameRounding  = 8
    st.ChildRounding    = 8;   st.GrabRounding   = 6
    st.PopupRounding    = 8
    -- ВАЖНО: одинаковый padding слева и справа
    st.WindowPadding    = imgui.ImVec2(14, 12)
    st.FramePadding     = imgui.ImVec2(8, 5)
    st.ItemSpacing      = imgui.ImVec2(8, 5)
    st.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    st.ButtonTextAlign  = imgui.ImVec2(0.5, 0.5)
    local C = st.Colors; local cl = imgui.Col; local V4 = imgui.ImVec4
    C[cl.WindowBg]         = V4(0.07,0.20,0.29,0.96)
    C[cl.ChildBg]          = V4(0.05,0.15,0.22,0.98)
    C[cl.TitleBg]          = V4(0.04,0.13,0.20,1.00)
    C[cl.TitleBgActive]    = V4(0.06,0.17,0.25,1.00)
    C[cl.Text]             = V4(1.00,1.00,1.00,1.00)
    C[cl.TextDisabled]     = V4(1.00,1.00,1.00,0.50)
    C[cl.Border]           = V4(1.00,1.00,1.00,0.07)
    C[cl.FrameBg]          = V4(0.05,0.16,0.24,1.00)
    C[cl.FrameBgHovered]   = V4(0.08,0.21,0.31,1.00)
    C[cl.FrameBgActive]    = V4(0.10,0.25,0.36,1.00)
    C[cl.Button]           = V4(0.08,0.22,0.32,1.00)
    C[cl.ButtonHovered]    = V4(0.11,0.28,0.40,1.00)
    C[cl.ButtonActive]     = V4(0.05,0.14,0.22,1.00)
    C[cl.CheckMark]        = V4(0.98,0.84,0.00,1.00)
    C[cl.SliderGrab]       = V4(0.98,0.84,0.00,1.00)
    C[cl.SliderGrabActive] = V4(1.00,0.92,0.20,1.00)
    C[cl.Header]           = V4(0.08,0.22,0.32,0.85)
    C[cl.HeaderHovered]    = V4(0.11,0.28,0.40,1.00)
    C[cl.Separator]        = V4(1.00,1.00,1.00,0.10)
    C[cl.ScrollbarGrab]    = V4(0.11,0.28,0.40,1.00)
end)

imgui.OnFrame(
    function() return WinMain[0] end,
    function(self)
        self.HideCursor = true
        if not wasMenuOpen then
            wasMenuOpen = true
            lua_thread.create(playMenuSound)
        end
        local W  = 330 * MDS
        local V4 = imgui.ImVec4; local V2 = imgui.ImVec2
        imgui.SetNextWindowPos(V2(resx*0.5, resy*0.5),
            imgui.Cond.FirstUseEver, V2(0.5, 0.5))
        imgui.SetNextWindowSize(V2(W, -1), imgui.Cond.Always)
        imgui.Begin('TramPilot  |  Victor Strand', WinMain,
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.AlwaysAutoResize)

        -- IW = ширина контента (без WindowPadding * 2)
        -- WindowPadding = 14*MDS с каждой стороны
        local IW = imgui.GetContentRegionAvail().x

        -- ---- СТАТУС ----
        local statusClr = apc and V4(0.98,0.84,0.00,1) or V4(1.00,0.30,0.30,1)
        local statusTxt = apc
            and u8('\xc1\xce\xd2: \xc0\xca\xd2\xc8\xc2\xc5\xcd')
            or  u8('\xc1\xce\xd2: \xce\xd1\xd2\xc0\xcd\xce\xc2\xcb\xc5\xcd')
        imgui.PushStyleColor(imgui.Col.ChildBg, V4(0.04,0.14,0.21,0.98))
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, V2(0, 6*MDS))
        if imgui.BeginChild('##st', V2(IW, 32*MDS), false) then
            imgui.PushStyleColor(imgui.Col.Text, statusClr)
            local ts = imgui.CalcTextSize(statusTxt)
            imgui.SetCursorPosX((IW - ts.x) * 0.5)
            imgui.Text(statusTxt)
            imgui.PopStyleColor(1)
            imgui.EndChild()
        end
        imgui.PopStyleVar(1)
        imgui.PopStyleColor(1)

        imgui.Spacing()

        -- ---- СТАРТ / СТОП ----
        local bH = 42*MDS
        if apc then
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.65,0.10,0.10,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.80,0.14,0.14,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.48,0.06,0.06,1))
            imgui.PushStyleColor(imgui.Col.Text,          V4(1.00,1.00,1.00,1))
            if imgui.Button(u8('\xd1\xd2\xce\xcf'), V2(IW, bH)) then
                apc = false; stopFlag = false; atStop = false; controlActive = false
                local car = getTramCar()
                if car then
                    taskCarDriveToCoord(PLAYER_PED, car, 0, 0, 0, 0, 0, 7, 0)
                    clearCharTasks(PLAYER_PED)
                end
            end
            imgui.PopStyleColor(4)
        else
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.98,0.84,0.00,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.93,0.80,0.00,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.85,0.72,0.00,1))
            imgui.PushStyleColor(imgui.Col.Text,          V4(0.08,0.08,0.08,1))
            if imgui.Button(u8('\xd1\xd2\xc0\xd0\xd2'), V2(IW, bH)) then
                if inTram() then
                    stopFlag = false; atStop = false; apc = true; controlActive = false
                    antiAdminEnableTime = os.clock()
                end
            end
            imgui.PopStyleColor(4)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- ---- АВТО-ЕДА ----
        -- Заголовок секции по центру
        local aeHdr = u8('\xc0\xc2\xd2\xce-\xc5\xc4\xc0')
        imgui.PushStyleColor(imgui.Col.Text, V4(0.98,0.84,0.00,1))
        local aeHdrSz = imgui.CalcTextSize(aeHdr)
        imgui.SetCursorPosX((IW - aeHdrSz.x) * 0.5)
        imgui.Text(aeHdr)
        imgui.PopStyleColor(1)
        imgui.Spacing()

        -- Строка 1: Вкл | Насыщ.: - 80% +
        local aeBuf = imgui.new.bool(autoEat)
        if imgui.Checkbox(u8('\xc2\xea\xeb\xfe\xf7\xe8\xf2\xfc'), aeBuf) then
            autoEat = aeBuf[0]
            if autoEat then
                lua_thread.create(function()
                    autoEatWaitSat = true
                    sampSendChat('/satiety')
                    local t = 0
                    while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
                    autoEatWaitSat = false
                end)
            end
        end
        imgui.SameLine()
        -- Выравниваем правую часть (кнопки насыщенности) по правому краю
        -- Ширина правой группы: текст "Насыщ.:" + "-" + "80%" + "+"
        local satLbl = u8('\xcd\xe0\xf1\xfb\xf9.:')
        local satVal = tostring(autoEatMinSatiety) .. '%'
        local btnSz  = V2(22*MDS, 22*MDS)
        local satGrpW = imgui.CalcTextSize(satLbl).x + btnSz.x*2 + imgui.CalcTextSize(satVal).x + 16*MDS
        imgui.SetCursorPosX(IW - satGrpW)
        imgui.PushStyleColor(imgui.Col.Text, V4(0.70,0.70,0.70,1))
        imgui.Text(satLbl)
        imgui.PopStyleColor(1)
        imgui.SameLine(0, 4*MDS)
        imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, V2(2*MDS, 2*MDS))
        if imgui.Button('-##ae_m', btnSz) then
            autoEatMinSatiety = math.max(20, autoEatMinSatiety - 5)
        end
        imgui.SameLine(0, 4*MDS)
        imgui.PushStyleColor(imgui.Col.Text, V4(0.98,0.84,0.00,1))
        imgui.Text(satVal)
        imgui.PopStyleColor(1)
        imgui.SameLine(0, 4*MDS)
        if imgui.Button('+##ae_p', btnSz) then
            autoEatMinSatiety = math.min(100, autoEatMinSatiety + 5)
        end
        imgui.PopStyleVar(1)

        -- Строка 2: текущая сытость
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col.Text, V4(0.55,0.55,0.55,1))
        local satCurTxt
        if autoEatSatiety < 0 then
            satCurTxt = u8('\xd1\xfb\xf2\xee\xf1\xf2\xfc: --')
        else
            satCurTxt = u8('\xd1\xfb\xf2\xee\xf1\xf2\xfc: ') .. string.format('%d%%', math.floor(autoEatSatiety))
        end
        imgui.Text(satCurTxt)
        imgui.PopStyleColor(1)

        -- Строка 3: выбор еды — кнопки < Чипсы >
        imgui.Spacing()
        local foodLbl = FOOD_NAMES[autoEatFood + 1] or u8('\xd7\xe8\xef\xf1\xfb')
        local arrowW  = 26*MDS
        local foodLblW = imgui.CalcTextSize(foodLbl).x
        local foodRowW = arrowW * 2 + foodLblW + 12*MDS
        imgui.SetCursorPosX((IW - foodRowW) * 0.5)
        imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, V2(2*MDS, 2*MDS))
        imgui.PushStyleColor(imgui.Col.Button,        V4(0.05,0.16,0.24,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.11,0.28,0.40,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.03,0.10,0.16,1))
        if imgui.Button('<##fd_prev', V2(arrowW, 22*MDS)) then
            autoEatFood = (autoEatFood - 1 + #FOOD_NAMES) % #FOOD_NAMES
        end
        imgui.PopStyleColor(3)
        imgui.SameLine(0, 6*MDS)
        imgui.PushStyleColor(imgui.Col.Text, V4(1.00,1.00,1.00,1))
        imgui.Text(foodLbl)
        imgui.PopStyleColor(1)
        imgui.SameLine(0, 6*MDS)
        imgui.PushStyleColor(imgui.Col.Button,        V4(0.05,0.16,0.24,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.11,0.28,0.40,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.03,0.10,0.16,1))
        if imgui.Button('>##fd_next', V2(arrowW, 22*MDS)) then
            autoEatFood = (autoEatFood + 1) % #FOOD_NAMES
        end
        imgui.PopStyleColor(3)
        imgui.PopStyleVar(1)

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- ---- АНТИ-АДМИН ----
        local aaHdr = u8('\xc0\xcd\xd2\xc8-\xc0\xc4\xcc\xc8\xcd')
        imgui.PushStyleColor(imgui.Col.Text, V4(0.98,0.84,0.00,1))
        local aaHdrSz = imgui.CalcTextSize(aaHdr)
        imgui.SetCursorPosX((IW - aaHdrSz.x) * 0.5)
        imgui.Text(aaHdr)
        imgui.PopStyleColor(1)
        imgui.Spacing()

        local aaBuf = imgui.new.bool(aaState)
        if imgui.Checkbox(u8('\xc0\xe2\xf2\xee\xee\xf2\xe2\xe5\xf2'), aaBuf) then
            aaState = aaBuf[0]
            if aaState then aaAngry = 0; aaTimes = os.clock() end
        end
        imgui.SameLine()
        imgui.PushStyleColor(imgui.Col.Text, V4(0.55,0.55,0.55,1))
        -- выравниваем справа
        local aaDescTxt = u8('\xee\xf2\xe2\xe5\xf7\xe0\xe5\xf2 \xea\xe0\xea \xe6\xe8\xe2\xee\xe9')
        local aaDescW = imgui.CalcTextSize(aaDescTxt).x
        imgui.SetCursorPosX(IW - aaDescW)
        imgui.Text(aaDescTxt)
        imgui.PopStyleColor(1)

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- ---- АВТОР ----
        imgui.PushStyleColor(imgui.Col.Text, V4(1.00,1.00,1.00,0.40))
        local a = u8('\xc0\xe2\xf2\xee\xf0: Victor Strand')
        local aSz = imgui.CalcTextSize(a)
        imgui.SetCursorPosX((IW - aSz.x) * 0.5)
        imgui.Text(a)
        imgui.PopStyleColor(1)
        imgui.Spacing()

        -- TG кнопки: строго половина контента каждая
        local bw2 = (IW - 6*MDS) * 0.5
        imgui.PushStyleColor(imgui.Col.Button,        V4(0.05,0.16,0.24,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.08,0.22,0.33,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.03,0.10,0.16,1))
        imgui.PushStyleColor(imgui.Col.Text,          V4(0.98,0.84,0.00,1))
        if imgui.Button(u8('@victor_st0'), V2(bw2, 28*MDS)) then
            openLink('https://t.me/victor_st0')
        end
        imgui.PopStyleColor(4)
        imgui.SameLine(0, 6*MDS)
        imgui.PushStyleColor(imgui.Col.Button,        V4(0.05,0.16,0.24,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.08,0.22,0.33,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.03,0.10,0.16,1))
        imgui.PushStyleColor(imgui.Col.Text,          V4(0.98,0.84,0.00,1))
        if imgui.Button(u8('strand_scripts'), V2(bw2, 28*MDS)) then
            openLink('https://t.me/strand_scripts')
        end
        imgui.PopStyleColor(4)

        imgui.End()
    end
)

-- =============================================
-- EXPORTS
-- =============================================
EXPORTS = {
    canToggle = function() return true end,
    getToggle = function() return apc end,
    toggle    = function()
        if apc then
            apc = false; stopFlag = false; atStop = false; controlActive = false
            local car = getTramCar()
            if car then
                taskCarDriveToCoord(PLAYER_PED, car, 0, 0, 0, 0, 0, 7, 0)
                clearCharTasks(PLAYER_PED)
            end
        elseif inTram() then
            stopFlag = false; apc = true; controlActive = false
            antiAdminEnableTime = os.clock()
        end
    end,
}

-- =============================================
-- ОТРИСОВКА ЛИНИИ К ЦЕЛИ
-- =============================================
local function drawTargetLine()
    local res, mx, my, mz = getMarker()
    if not (res and type(mx) == 'number') then return end
    local ok, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
    if not ok then return end
    if isPointOnScreen(mx, my, mz, 1) then
        local sx, sy   = convert3DCoordsToScreen(mx, my, mz)
        local px2, py2 = convert3DCoordsToScreen(px, py, pz + 1)
        if braking then
            renderDrawLine(px2, py2, sx, sy, 6 * MDS, 0x33ff4d4d)
            renderDrawLine(px2, py2, sx, sy, 2 * MDS, 0xFFff4d4d)
        else
            renderDrawLine(px2, py2, sx, sy, 6 * MDS, 0x33fbd600)
            renderDrawLine(px2, py2, sx, sy, 2 * MDS, 0xFFfbd600)
        end
        local dotR = 5 * MDS
        renderDrawLine(sx-dotR, sy, sx+dotR, sy, 2*MDS, braking and 0xFFff4d4d or 0xFFfbd600)
        renderDrawLine(sx, sy-dotR, sx, sy+dotR, 2*MDS, braking and 0xFFff4d4d or 0xFFfbd600)
    end
    if curBrakeX and isPointOnScreen(curBrakeX, curBrakeY, curBrakeZ, 1) and not braking then
        local bsx, bsy = convert3DCoordsToScreen(curBrakeX, curBrakeY, curBrakeZ)
        local cr = 9 * MDS
        renderDrawLine(bsx-cr, bsy, bsx+cr, bsy, 4*MDS, 0x33fbd600)
        renderDrawLine(bsx, bsy-cr, bsx, bsy+cr, 4*MDS, 0x33fbd600)
        renderDrawLine(bsx-cr, bsy, bsx+cr, bsy, 2*MDS, 0xCCfbd600)
        renderDrawLine(bsx, bsy-cr, bsx, bsy+cr, 2*MDS, 0xCCfbd600)
    end
end

-- =============================================
-- BOBEK (взятие маршрута)
-- =============================================
local function bobek()
    lua_thread.create(function()
        if callBobek then return end
        callBobek = true
        wait(math.random(3000, 7000))
        local accepted = false
        if sampIsDialogActive() then
            local did = sampGetCurrentDialogId()
            if did == 4297 and getCharActiveInterior(PLAYER_PED) == 138 then
                sampSendDialogResponse(did, 1, 0, '')
                wait(math.random(1000, 7000))
                if inTram() then accepted = true end
            end
        end
        checkpointCounter = 0
        callBobek = false
    end)
end

-- =============================================
-- MAIN
-- =============================================
function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end
    wait(500)

    sampRegisterChatCommand('tram', function()
        WinMain[0] = not WinMain[0]
        if not WinMain[0] then wasMenuOpen = false end
    end)

    -- ---- АВТО-ЕДА луп ----
    lua_thread.create(function()
        wait(4000)
        autoEatWaitSat = true
        sampSendChat('/satiety')
        local t0 = 0
        while autoEatWaitSat and t0 < 60 do wait(100); t0 = t0+1 end
        autoEatWaitSat = false

        while true do
            wait(0)
            if autoEat then
                for i = 1, 300 do
                    wait(100)
                    if not autoEat then break end
                end
                if not autoEat then goto ae_skip end
                if sampIsLocalPlayerSpawned() then
                    lua_thread.create(function()
                        autoEatWaitSat = true
                        sampSendChat('/satiety')
                        local t = 0
                        while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
                        autoEatWaitSat = false
                        wait(400)
                        if autoEatSatiety >= 0 and autoEatSatiety >= autoEatMinSatiety then return end
                        autoEatWaitEat = true
                        sampSendChat('/eat')
                        local t2 = 0
                        while autoEatWaitEat and t2 < 60 do wait(100); t2 = t2+1 end
                        autoEatWaitEat = false
                        wait(300)
                        if sampIsDialogActive() then sampSendChat('/eat') end
                    end)
                end
            end
            ::ae_skip::
        end
    end)

    -- ---- ОСНОВНОЙ БОТ-ЛУП ----
    lua_thread.create(function()
        local lastCpX, lastCpY = nil, nil

        while true do
            wait(0)

            if not apc or stopFlag then
                -- выключен

            elseif not isCharInAnyCar(PLAYER_PED) or not inTram() then
                -- вышли из трамвая
                controlActive = false
                if not callBobek then
                    if #foot_coords > 0 then
                        lua_thread.create(function()
                            if callBobek then return end
                            callBobek = true
                            wait(math.random(1000, 3000))
                            for i, pt in ipairs(foot_coords) do
                                local isLast = (i == #foot_coords)
                                local maxT = 0
                                while true do
                                    wait(1)
                                    if not apc or isCharInAnyCar(PLAYER_PED) then break end
                                    local ok, cx, cy = pcall(getCharCoordinates, PLAYER_PED)
                                    if not ok then break end
                                    local dist = getDistanceBetweenCoords2d(cx, cy, pt[1], pt[2])
                                    if dist <= (isLast and 0.5 or 1.0) then break end
                                    setCameraPositionUnfixed(0, math.rad(getHeadingFromVector2d(pt[1]-cx, pt[2]-cy) - 90))
                                    setGameKeyState(1, -255)
                                    if not isLast then setGameKeyState(16, 1) end
                                    maxT = maxT + 1
                                    if maxT > 8000 then break end
                                end
                                setGameKeyState(1, 0); setGameKeyState(16, 0)
                                wait(30)
                                if not apc or isCharInAnyCar(PLAYER_PED) then break end
                            end
                            setGameKeyState(1, 0); setGameKeyState(16, 0)
                            wait(math.random(500, 1000))

                            local gotDialog = false
                            for _try = 1, 5 do
                                sendAlt()
                                wait(600)
                                if sampIsDialogActive() then gotDialog = true; break end
                                wait(500)
                            end

                            if gotDialog then
                                local did = sampGetCurrentDialogId()
                                wait(math.random(300, 700))
                                if did == 185 then
                                    sampSendDialogResponse(did, 1, 6, '')
                                    wait(600)
                                    local w2 = 0
                                    while w2 < 40 do
                                        wait(200); w2 = w2 + 1
                                        if sampIsDialogActive() then
                                            local did2 = sampGetCurrentDialogId()
                                            wait(300)
                                            sampSendDialogResponse(did2, 1, 0, '')
                                            break
                                        end
                                    end
                                else
                                    sampSendDialogResponse(did, 1, 0, '')
                                end
                            end

                            wait(math.random(1000, 2000))
                            checkpointCounter = 0
                            callBobek = false
                        end)
                    else
                        bobek()
                    end
                end
            else
                -- едем
                local car = getTramCar()
                if car then
                    local res, mx, my, mz = getMarker()
                    if res and (type(mx) ~= 'number' or type(my) ~= 'number' or type(mz) ~= 'number') then
                        res = false
                    end

                    if res then
                        if mx ~= lastCpX or my ~= lastCpY then
                            lastCpX, lastCpY = mx, my
                            atStop  = false
                            braking = false
                            controlActive = false
                            local bestDist, bestIdx = 9999, nil
                            for bi, bc in ipairs(brake_coords) do
                                local d = getDistanceBetweenCoords3d(mx, my, mz, bc[1], bc[2], bc[3])
                                if d < bestDist then bestDist = d; bestIdx = bi end
                            end
                            if bestIdx and bestDist < 200 then
                                curBrakeX = brake_coords[bestIdx][1]
                                curBrakeY = brake_coords[bestIdx][2]
                                curBrakeZ = brake_coords[bestIdx][3]
                            else
                                curBrakeX = nil
                            end
                        end

                        if not atStop then
                            local ok, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
                            if not ok then wait(100); goto cont end
                            local dist = getDistanceBetweenCoords3d(px, py, pz, mx, my, mz)

                            -- Торможение с 80м
                            if not braking and dist < 80 then
                                braking = true
                            end

                            -- ============================================
                            -- КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: порог остановки 1.2м
                            -- вместо 0.5м — трамвай большой, центр игрока
                            -- смещён от центра вагона
                            -- ============================================
                            if dist > 1.2 then
                                local spd
                                if not braking then
                                    spd = 24
                                elseif dist > 65 then spd = 18
                                elseif dist > 45 then spd = 11
                                elseif dist > 28 then spd = 6
                                elseif dist > 15 then spd = 3.5
                                elseif dist > 8  then spd = 2.0
                                elseif dist > 4  then spd = 1.2
                                elseif dist > 2  then spd = 0.6
                                else                   spd = 0.3
                                end

                                taskCarDriveToCoord(PLAYER_PED, car, mx, my, mz, spd, 0, 7, 0)
                                controlActive = true
                                lastTargetTime = os.clock()

                                -- Блокируем газ игрока при торможении
                                if braking and dist < 50 then
                                    setGameKeyState(4, 0)
                                end

                                -- На финальных метрах: очень частые апдейты
                                if dist < 10 then
                                    wait(16)
                                elseif dist < 25 then
                                    wait(33)
                                else
                                    wait(80)
                                end
                            else
                                -- ПОЛНАЯ ОСТАНОВКА
                                taskCarDriveToCoord(PLAYER_PED, car, mx, my, mz, 0, 0, 7, 0)
                                setGameKeyState(4, 0)
                                setGameKeyState(5, 255)
                                wait(250)
                                setGameKeyState(5, 0)

                                local sw = 0
                                while sw < 60 do
                                    wait(100); sw = sw + 1
                                    local c2 = getTramCar()
                                    if not c2 then break end
                                    local ok2, spd2 = pcall(getCarSpeed, c2)
                                    if ok2 and spd2 < 0.04 then break end
                                end

                                setGameKeyState(4, 0); setGameKeyState(5, 0)
                                controlActive = false
                                atStop  = true
                                braking = false
                                checkpointCounter = checkpointCounter + 1

                                -- Пауза на остановке (без /команд в чат)
                                wait(math.random(600, 1800))
                            end
                        end
                    end
                end
            end
            ::cont::
        end
    end)

    -- ---- ЗАЩИТА ОТ РУЧНОГО ГАЗА ----
    lua_thread.create(function()
        while true do
            wait(0)
            if apc and controlActive and braking and not atStop then
                local car = getTramCar()
                if car then
                    local res, mx, my, mz = getMarker()
                    if res then
                        local ok, px, py, pz = pcall(getCharCoordinates, PLAYER_PED)
                        if ok then
                            local dist = getDistanceBetweenCoords3d(px, py, pz, mx, my, mz)
                            if dist < 50 then
                                setGameKeyState(4, 0)
                            end
                            if dist < 20 then
                                local ok2, spd2 = pcall(getCarSpeed, car)
                                if ok2 and spd2 > 0.9 then
                                    setGameKeyState(5, 100)
                                    wait(40)
                                    setGameKeyState(5, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ---- ОТРИСОВКА ----
    lua_thread.create(function()
        while true do
            wait(0)
            if apc and not atStop and isCharInAnyCar(PLAYER_PED) then
                drawTargetLine()
            end
        end
    end)

    -- ---- ГЛАВНЫЙ ЦИКЛ ----
    while true do
        if not apc then controlActive = false end
        if controlActive and (os.clock() - lastTargetTime) > 2.0 then
            controlActive = false
        end
        if isWidgetSwipedLeft(WIDGET_RADAR) then
            WinMain[0] = not WinMain[0]
        end
        wait(0)
    end
end
