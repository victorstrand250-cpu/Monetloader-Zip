script_name('TramPilot')
script_author('Victor Strand')
script_version('3.0-monet')
script_version_number(10)
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

local apc       = false
local callBobek = false
local stopFlag  = false
local checkpointCounter = 0
local atStop    = false

local cpX, cpY, cpZ = nil, nil, nil
local cpActive = false

local route       = {}

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
local take_point = {-2263.2526855469, 513.08807373047, 1487.6917724609}

local curBrakeX, curBrakeY, curBrakeZ = nil, nil, nil
local braking = false
local cpIndex  = 0

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
            local ok2b, v1, v2 = pcall(getTargetBlipCoordinatesFixed)
            if ok2b then by, bz = v1, v2 end
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

function sampev.onSetRaceCheckpoint(cpType, x, y, z, nx, ny, nz, radius)
    local function toNum(v, idx)
        if type(v) == 'number' then return v end
        if type(v) == 'table' then
            return v.x or v.y or v.z or v[idx] or 0
        end
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

local function bobek()
    lua_thread.create(function()
        if callBobek then return end
        callBobek = true
        wait(200)
        printStringNow('~p~TramPilot ~w~waiting...', 1000)
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
        if accepted then
            wait(math.random(5000, 10000))
            sampSendChat('/beer')
        end
        checkpointCounter = 0
        callBobek = false
    end)
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if not text then return end
    local isAdmin = text:find('A:')
        or text:find('\xe0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
        or text:find('\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
        or text:find('\xf2\xf3\xf2')
        or text:find('\xe2\xfb \xf2\xf3\xf2')
    if isAdmin and apc then
        stopFlag = true; apc = false
                local _car = getTramCar()
                if _car then taskCarDriveToCoord(PLAYER_PED, _car, 0, 0, 0, 0, 0, 7, 0); clearCharTasks(PLAYER_PED) end
        printStringNow('~p~TramPilot ~w~Stopped!', 1000)
    end
end

function sampev.onServerMessage(clr, text)
    if not text then return end
    local lo = text:lower()
    if lo:find('\xe0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
       and not lo:find('\xf2\xf0\xe0\xed\xf1\xef\xee\xf0\xf2')
       and not lo:find('\xe5\xf0\xee\xef\xf0\xe8\xff\xf2\xe8\xe5')
       and apc then
        stopFlag = true; apc = false
                local _car = getTramCar()
                if _car then taskCarDriveToCoord(PLAYER_PED, _car, 0, 0, 0, 0, 0, 7, 0); clearCharTasks(PLAYER_PED) end
        printStringNow('~p~TramPilot ~w~Stopped!', 1000)
    end
end

local WinMain    = imgui.new.bool(false)
local wasMenuOpen = false
local resx, resy = getScreenResolution()

imgui.OnInitialize(function()
    local imgio = imgui.GetIO()
    imgio.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    local st = imgui.GetStyle()
    -- Arizona: скруглённые углы как в игре
    st.WindowRounding   = 12;  st.FrameRounding  = 8
    st.ChildRounding    = 8;   st.GrabRounding   = 6
    st.PopupRounding    = 8
    -- симметричный паддинг слева и справа одинаковый
    st.WindowPadding    = imgui.ImVec2(16, 14)
    st.FramePadding     = imgui.ImVec2(10, 6)
    st.ItemSpacing      = imgui.ImVec2(8, 6)
    st.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    st.ButtonTextAlign  = imgui.ImVec2(0.5, 0.5)
    local C = st.Colors; local cl = imgui.Col; local V4 = imgui.ImVec4
    -- Arizona: настоящий бирюзово-синий фон как в игре (#0a2030 центр, #163d4a края)
    C[cl.WindowBg]         = V4(0.07,0.20,0.29,0.96)
    C[cl.ChildBg]          = V4(0.05,0.15,0.22,0.98)
    C[cl.TitleBg]          = V4(0.04,0.13,0.20,1.00)
    C[cl.TitleBgActive]    = V4(0.06,0.17,0.25,1.00)
    C[cl.Text]             = V4(1.00,1.00,1.00,1.00)
    C[cl.TextDisabled]     = V4(1.00,1.00,1.00,0.50)
    -- Arizona: тонкая белая обводка
    C[cl.Border]           = V4(1.00,1.00,1.00,0.07)
    C[cl.FrameBg]          = V4(0.05,0.16,0.24,1.00)
    C[cl.FrameBgHovered]   = V4(0.08,0.21,0.31,1.00)
    C[cl.FrameBgActive]    = V4(0.10,0.25,0.36,1.00)
    -- кнопки — чуть светлее фона окна
    C[cl.Button]           = V4(0.08,0.22,0.32,1.00)
    C[cl.ButtonHovered]    = V4(0.11,0.28,0.40,1.00)
    C[cl.ButtonActive]     = V4(0.05,0.14,0.22,1.00)
    -- акцентный жёлтый #fbd600
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
        local W  = 320 * MDS
        local V4 = imgui.ImVec4; local V2 = imgui.ImVec2
        imgui.SetNextWindowPos(V2(resx*0.5, resy*0.5),
            imgui.Cond.FirstUseEver, V2(0.5, 0.5))
        imgui.SetNextWindowSize(V2(W, -1), imgui.Cond.Always)
        imgui.Begin('TramPilot  |  Victor Strand', WinMain,
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.AlwaysAutoResize)

        -- IW = ширина контента: окно минус WindowPadding с обеих сторон (16*2=32)
        local IW = W - 32*MDS

        -- статус
        -- Arizona: активный = жёлтый акцент, неактивный = красный
        local statusClr = apc and V4(0.98,0.84,0.00,1) or V4(1.00,0.30,0.30,1)
        local statusTxt = apc
            and u8('\xc1\xce\xd2: \xc0\xca\xd2\xc8\xc2\xc5\xcd')
            or  u8('\xc1\xce\xd2: \xce\xd1\xd2\xc0\xcd\xce\xc2\xcb\xc5\xcd')
        imgui.PushStyleColor(imgui.Col.ChildBg, V4(0.04,0.14,0.21,0.98))
        if imgui.BeginChild('##st', V2(IW, 36*MDS), true) then
            imgui.PushStyleColor(imgui.Col.Text, statusClr)
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 3*MDS)
            imgui.SetCursorPosX((IW - imgui.CalcTextSize(statusTxt).x)*0.5)
            imgui.Text(statusTxt)
            imgui.PopStyleColor(1)
            imgui.EndChild()
        end
        imgui.PopStyleColor(1)

        imgui.Spacing()

        -- СТАРТ / СТОП  — Arizona стиль
        local bH = 44*MDS
        if apc then
            -- Arizona красный: #ff4d4d
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.65,0.10,0.10,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.80,0.14,0.14,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.48,0.06,0.06,1))
            imgui.PushStyleColor(imgui.Col.Text,          V4(1.00,1.00,1.00,1))
            if imgui.Button(u8('\xd1\xd2\xce\xcf'), V2(IW, bH)) then
                apc = false; stopFlag = false; atStop = false
                local car = getTramCar()
                if car then taskCarDriveToCoord(PLAYER_PED, car, 0, 0, 0, 0, 0, 7, 0); clearCharTasks(PLAYER_PED) end
                sampAddChatMessage('{cc66ff}[TramPilot]: {ff4444}\xd1\xd2\xce\xcf', -1)
            end
            imgui.PopStyleColor(4)
        else
            -- Arizona жёлтый: #fbd600, текст тёмный
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.98,0.84,0.00,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.93,0.80,0.00,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.85,0.72,0.00,1))
            imgui.PushStyleColor(imgui.Col.Text,          V4(0.08,0.08,0.08,1))
            if imgui.Button(u8('\xd1\xd2\xc0\xd0\xd2'), V2(IW, bH)) then
                if not inTram() then
                    sampAddChatMessage(
                        '{ff4444}[TramPilot]: \xd1\xed\xe0\xf7\xe0\xeb\xe0 \xf1\xff\xe4\xfc \xe2 \xf2\xf0\xe0\xec\xe2\xe0\xe9!', -1)
                else
                    stopFlag = false; atStop = false; apc = true
                    sampAddChatMessage('{cc66ff}[TramPilot]: {44ff44}\xd1\xd2\xc0\xd0\xd2', -1)
                end
            end
            imgui.PopStyleColor(4)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- автор — приглушённый белый
        imgui.PushStyleColor(imgui.Col.Text, V4(1.00,1.00,1.00,0.45))
        local a = u8('\xc0\xe2\xf2\xee\xf0: Victor Strand')
        imgui.SetCursorPosX((IW - imgui.CalcTextSize(a).x)*0.5)
        imgui.Text(a)
        imgui.PopStyleColor(1)

        imgui.Spacing()

        -- TG кнопки — Arizona бирюзово-синие с жёлтым текстом
        local bw2 = (IW - 6*MDS)*0.5
        imgui.PushStyleColor(imgui.Col.Button,        V4(0.05,0.16,0.24,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.08,0.22,0.33,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.03,0.10,0.16,1))
        imgui.PushStyleColor(imgui.Col.Text,          V4(0.98,0.84,0.00,1))
        if imgui.Button(u8('@victor_st0'), V2(bw2, 30*MDS)) then
            openLink('https://t.me/victor_st0')
        end
        imgui.PopStyleColor(4)
        imgui.SameLine(0, 6*MDS)
        imgui.PushStyleColor(imgui.Col.Button,        V4(0.05,0.16,0.24,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.08,0.22,0.33,1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.03,0.10,0.16,1))
        imgui.PushStyleColor(imgui.Col.Text,          V4(0.98,0.84,0.00,1))
        if imgui.Button(u8('strand_scripts'), V2(bw2, 30*MDS)) then
            openLink('https://t.me/strand_scripts')
        end
        imgui.PopStyleColor(4)

        imgui.End()
    end
)

EXPORTS = {
    canToggle = function() return true end,
    getToggle = function() return apc end,
    toggle    = function()
        if apc then
            apc = false; stopFlag = false; atStop = false
            local car = getTramCar()
            if car then
                taskCarDriveToCoord(PLAYER_PED, car, 0, 0, 0, 0, 0, 7, 0)
                clearCharTasks(PLAYER_PED)
            end
        else if inTram() then stopFlag = false; apc = true end end
    end,
}

local function drawTargetLine()
    local res, mx, my, mz = getMarker()
    if res and type(mx) == 'number' then
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        if isPointOnScreen(mx, my, mz, 1) then
            local sx, sy   = convert3DCoordsToScreen(mx, my, mz)
            local px2, py2 = convert3DCoordsToScreen(px, py, pz + 1)
            if braking then
                -- Режим торможения: Arizona красный #ff4d4d с glow
                -- glow-слой (полупрозрачный толстый)
                renderDrawLine(px2, py2, sx, sy, 6 * MDS, 0x33ff4d4d)
                -- основная линия
                renderDrawLine(px2, py2, sx, sy, 2 * MDS, 0xFFff4d4d)
            else
                -- Обычный ход: Arizona жёлтый #fbd600 с glow
                renderDrawLine(px2, py2, sx, sy, 6 * MDS, 0x33fbd600)
                renderDrawLine(px2, py2, sx, sy, 2 * MDS, 0xFFfbd600)
            end
            -- точка-цель на чекпоинте: маленький ромб из 2 линий
            local dotR = 5 * MDS
            renderDrawLine(sx - dotR, sy, sx + dotR, sy, 2*MDS, braking and 0xFFff4d4d or 0xFFfbd600)
            renderDrawLine(sx, sy - dotR, sx, sy + dotR, 2*MDS, braking and 0xFFff4d4d or 0xFFfbd600)
        end
        -- маркер точки торможения: Arizona жёлтый крест вместо розового
        if curBrakeX and isPointOnScreen(curBrakeX, curBrakeY, curBrakeZ, 1) and not braking then
            local bsx, bsy = convert3DCoordsToScreen(curBrakeX, curBrakeY, curBrakeZ)
            local cr = 9 * MDS
            -- glow крест
            renderDrawLine(bsx - cr, bsy, bsx + cr, bsy, 4*MDS, 0x33fbd600)
            renderDrawLine(bsx, bsy - cr, bsx, bsy + cr, 4*MDS, 0x33fbd600)
            -- основной крест
            renderDrawLine(bsx - cr, bsy, bsx + cr, bsy, 2*MDS, 0xCCfbd600)
            renderDrawLine(bsx, bsy - cr, bsx, bsy + cr, 2*MDS, 0xCCfbd600)
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end
    wait(500)

    sampAddChatMessage('{cc66ff}[TramPilot]: {ffffff}v1.8 by Victor Strand | /tram', -1)
    sampRegisterChatCommand('tram', function()
        WinMain[0] = not WinMain[0]
        if not WinMain[0] then wasMenuOpen = false end
    end)

    sampRegisterChatCommand('tramdbg', function()
        local ok, r = pcall(getTargetBlipCoordinatesFixed)
        if ok and r then
            if type(r) == 'table' then
                local info = 'table keys: '
                for k,v in pairs(r) do info = info..tostring(k)..'='..tostring(v)..' ' end
                sampAddChatMessage('{ffaa00}[TramDBG] blip: '..info, -1)
            else
                sampAddChatMessage('{ffaa00}[TramDBG] blip type='..type(r)..' val='..tostring(r), -1)
            end
        else
            sampAddChatMessage('{ff4444}[TramDBG] blip failed: '..tostring(r), -1)
        end
        local ok2, cx, cy, cz = pcall(getCheckpointCoordinates)
        if ok2 then
            sampAddChatMessage('{ffaa00}[TramDBG] checkpoint: '..type(cx)..' '..tostring(cx)..' '..tostring(cy)..' '..tostring(cz), -1)
        else
            sampAddChatMessage('{ff4444}[TramDBG] checkpoint failed', -1)
        end
        if type(cpX) == 'table' then
            local info = 'cpX table: '
            for k,v in pairs(cpX) do info = info..tostring(k)..'='..tostring(v)..' ' end
            sampAddChatMessage('{ffaa00}[TramDBG] '..info, -1)
        else
            sampAddChatMessage('{ffaa00}[TramDBG] cpActive='..tostring(cpActive)..' cpX='..tostring(cpX)..' cpY='..tostring(cpY)..' cpZ='..tostring(cpZ), -1)
        end
    end)

    lua_thread.create(function()
        local lastCpX, lastCpY = nil, nil

        while true do
            wait(0)

            if not apc or stopFlag then
            elseif not isCharInAnyCar(PLAYER_PED) or not inTram() then
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
                                    local cx, cy = getCharCoordinates(PLAYER_PED)
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
                            sampAddChatMessage('{cc66ff}[TramPilot] At desk, waiting dialog...', -1)
                            wait(math.random(500, 1000))

                            local gotDialog = false
                            for _try = 1, 5 do
                                sendAlt()
                                wait(600)
                                if sampIsDialogActive() then
                                    gotDialog = true
                                    break
                                end
                                wait(500)
                            end

                            if gotDialog then
                                local did = sampGetCurrentDialogId()
                                sampAddChatMessage('{44ff44}[TramPilot] Dialog '..tostring(did)..', taking route', -1)
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
                            else
                                sampAddChatMessage('{ff4444}[TramPilot] Dialog не открылся!', -1)
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
                            local px, py, pz = getCharCoordinates(PLAYER_PED)
                            local dist = getDistanceBetweenCoords3d(px, py, pz, mx, my, mz)

                            if not braking and dist < 55 then
                                braking = true
                            end

                            if dist > 0.5 then
                                local spd
                                if not braking then
                                    spd = 24
                                elseif dist > 40 then spd = 16
                                elseif dist > 25 then spd = 10
                                elseif dist > 15 then spd = 6
                                elseif dist > 8  then spd = 3
                                elseif dist > 3  then spd = 2
                                else                   spd = 1
                                end
                                taskCarDriveToCoord(PLAYER_PED, car, mx, my, mz, spd, 0, 7, 0)
                                wait(100)
                            else
                                taskCarDriveToCoord(PLAYER_PED, car, mx, my, mz, 0, 0, 7, 0)
                                wait(500)
                                for _i = 1, 20 do
                                    wait(200)
                                    local c2 = getTramCar()
                                    if not c2 or getCarSpeed(c2) < 0.05 then break end
                                end

                                atStop  = true
                                braking = false
                                checkpointCounter = checkpointCounter + 1

                                local rnd = math.random(1, 20)
                                if rnd == 1 then
                                    sampSendChat('/invent')
                                    wait(math.random(1000, 2500))
                                elseif rnd == 2 then
                                    sampSendChat('/phone')
                                    wait(math.random(1000, 2500))
                                elseif rnd == 3 then
                                    wait(math.random(2000, 5000))
                                elseif rnd == 4 then
                                    sampSendChat('/smoke')
                                    wait(math.random(2000, 4000))
                                else
                                    wait(math.random(500, 1500))
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(0)
            if apc and not atStop and isCharInAnyCar(PLAYER_PED) then
                drawTargetLine()
            end
        end
    end)

    while true do
        if isWidgetSwipedLeft(WIDGET_RADAR) then
            WinMain[0] = not WinMain[0]
        end

        wait(0)
    end
end
