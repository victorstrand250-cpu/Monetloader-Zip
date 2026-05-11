script_name('AutoDrive')
script_author('Victor Strand')
script_version('1.0-monet')
script_version_number(1)
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

-- ──────────── state ────────────
local enabled   = false
local stopFlag  = false
local braking   = false
local arrived   = false

local cpX, cpY, cpZ = nil, nil, nil
local cpActive = false

-- скорость из ползунка (км/ч → единицы GTA ~0.5 км/ч за единицу)
local maxSpeed = imgui.new.float(60.0)

-- ──────────── helpers ────────────

local function inCar()
    return isCharInAnyCar(PLAYER_PED)
end

local function getCar()
    if not inCar() then return nil end
    local ok, car = pcall(storeCarCharIsInNoSave, PLAYER_PED)
    if ok and car then return car end
    return nil
end

local function getMarker()
    -- 1. SAMP race checkpoint
    if cpActive and cpX then
        return true, cpX, cpY, cpZ
    end

    -- 2. GPS-метка на карте
    local ok, r = pcall(getTargetBlipCoordinatesFixed)
    if ok and r then
        local bx, by, bz
        if type(r) == 'table' then
            if type(r.x) == 'number' then
                bx, by, bz = r.x, r.y, r.z
            elseif type(r[1]) == 'number' then
                bx, by, bz = r[1], r[2], r[3]
            else
                local vals = {}
                for _, v in pairs(r) do
                    if type(v) == 'number' then vals[#vals+1] = v end
                end
                bx, by, bz = vals[1], vals[2], vals[3]
            end
        elseif type(r) == 'number' then
            bx = r
        end
        if bx and type(bx) == 'number'
           and not (math.abs(bx) < 0.1 and math.abs(by or 0) < 0.1) then
            return true, bx, by or 0, bz or 0
        end
    end

    -- 3. Checkpoint
    local ok2, cx, cy, cz = pcall(getCheckpointCoordinates)
    if ok2 and cx and type(cx) == 'number'
       and not (math.abs(cx) < 0.1 and math.abs(cy or 0) < 0.1) then
        return true, cx, cy or 0, cz or 0
    end

    return false, 0, 0, 0
end

local function stopDriving()
    local car = getCar()
    if car then
        taskCarDriveToCoord(PLAYER_PED, car, 0, 0, 0, 0, 0, 7, 0)
        clearCharTasks(PLAYER_PED)
    end
end

local function adminStop(src)
    if not enabled then return end
    enabled  = false
    stopFlag = true
    stopDriving()
    sampAddChatMessage('{ff4444}[AutoDrive] \xd1\xf2\xee\xef: ' .. src, -1)
end

-- ──────────── SAMP events ────────────

function sampev.onSetRaceCheckpoint(cpType, x, y, z)
    local function n(v, i)
        if type(v) == 'number' then return v end
        if type(v) == 'table' then return v.x or v.y or v.z or v[i] or 0 end
        return tonumber(v) or 0
    end
    if type(x) == 'table' then
        cpX = x.x or x[1] or 0
        cpY = x.y or x[2] or 0
        cpZ = x.z or x[3] or 0
    else
        cpX, cpY, cpZ = n(x,1), n(y,2), n(z,3)
    end
    cpActive = type(cpX) == 'number' and cpX ~= 0
end

function sampev.onDisableRaceCheckpoint()
    cpActive = false
    cpX, cpY, cpZ = nil, nil, nil
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if not text then return end
    local isAdmin = text:find('A:')
        or text:find('\xe0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
        or text:find('\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
    if isAdmin then adminStop('dialog') end
end

function sampev.onServerMessage(clr, text)
    if not text then return end
    local lo = text:lower()
    if lo:find('\xe0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0')
       and not lo:find('\xf2\xf0\xe0\xed\xf1\xef\xee\xf0\xf2')
       and not lo:find('\xe5\xf0\xee\xef\xf0\xe8\xff\xf2\xe8\xe5') then
        adminStop('server msg')
    end
end

-- ──────────── imgui UI ────────────

local WinMain     = imgui.new.bool(false)
local resx, resy  = getScreenResolution()

imgui.OnInitialize(function()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    local st = imgui.GetStyle()
    st.WindowRounding   = 12;  st.FrameRounding  = 8
    st.ChildRounding    = 8;   st.GrabRounding   = 6
    st.PopupRounding    = 8
    st.WindowPadding    = imgui.ImVec2(16, 14)
    st.FramePadding     = imgui.ImVec2(10, 6)
    st.ItemSpacing      = imgui.ImVec2(8, 6)
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
        local W  = 300 * MDS
        local V4 = imgui.ImVec4; local V2 = imgui.ImVec2
        imgui.SetNextWindowPos(V2(resx*0.5, resy*0.5),
            imgui.Cond.FirstUseEver, V2(0.5, 0.5))
        imgui.SetNextWindowSize(V2(W, -1), imgui.Cond.Always)
        imgui.Begin(u8('AutoDrive  |  Victor Strand'), WinMain,
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.AlwaysAutoResize)

        local IW = W - 32*MDS

        -- статус
        local statusClr = enabled
            and imgui.ImVec4(0.98,0.84,0.00,1)
            or  imgui.ImVec4(1.00,0.30,0.30,1)
        local statusTxt = enabled
            and u8('\xc0\xc2\xd2\xce\xc5\xc4\xc0: \xc0\xca\xd2\xc8\xc2\xc5\xcd')
            or  u8('\xc0\xc2\xd2\xce\xc5\xc4\xc0: \xce\xd1\xd2\xc0\xcd\xce\xc2\xcb\xc5\xcd')

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

        -- ползунок скорости
        imgui.PushStyleColor(imgui.Col.Text, V4(1,1,1,0.7))
        imgui.Text(u8('\xd1\xea\xee\xf0\xee\xf1\xf2\xfc: ') .. string.format('%d km/h', math.floor(maxSpeed[0])))
        imgui.PopStyleColor(1)
        imgui.PushItemWidth(IW)
        imgui.SliderFloat('##spd', maxSpeed, 10, 200, '')
        imgui.PopItemWidth()

        imgui.Spacing()

        -- СТАРТ / СТОП
        local bH = 44*MDS
        if enabled then
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.65,0.10,0.10,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.80,0.14,0.14,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.48,0.06,0.06,1))
            imgui.PushStyleColor(imgui.Col.Text,          V4(1.00,1.00,1.00,1))
            if imgui.Button(u8('\xd1\xd2\xce\xcf'), V2(IW, bH)) then
                enabled  = false
                stopFlag = false
                arrived  = false
                stopDriving()
                sampAddChatMessage('{cc66ff}[AutoDrive]: {ff4444}\xd1\xd2\xce\xcf', -1)
            end
            imgui.PopStyleColor(4)
        else
            imgui.PushStyleColor(imgui.Col.Button,        V4(0.98,0.84,0.00,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, V4(0.93,0.80,0.00,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  V4(0.85,0.72,0.00,1))
            imgui.PushStyleColor(imgui.Col.Text,          V4(0.08,0.08,0.08,1))
            if imgui.Button(u8('\xd1\xd2\xc0\xd0\xd2'), V2(IW, bH)) then
                if not inCar() then
                    sampAddChatMessage(
                        '{ff4444}[AutoDrive]: \xd1\xed\xe0\xf7\xe0\xeb\xe0 \xf1\xff\xe4\xfc \xe2 \xec\xe0\xf8\xe8\xed\xf3!', -1)
                else
                    local res, mx, my, mz = getMarker()
                    if not res then
                        sampAddChatMessage(
                            '{ff4444}[AutoDrive]: \xd3\xf1\xf2\xe0\xed\xee\xe2\xe8 \xec\xe5\xf2\xea\xf3 \xed\xe0 \xea\xe0\xf0\xf2\xe5!', -1)
                    else
                        stopFlag = false; arrived = false; enabled = true
                        sampAddChatMessage('{cc66ff}[AutoDrive]: {44ff44}\xd1\xd2\xc0\xd0\xd2', -1)
                    end
                end
            end
            imgui.PopStyleColor(4)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- автор
        imgui.PushStyleColor(imgui.Col.Text, V4(1.00,1.00,1.00,0.45))
        local a = u8('\xc0\xe2\xf2\xee\xf0: Victor Strand')
        imgui.SetCursorPosX((IW - imgui.CalcTextSize(a).x)*0.5)
        imgui.Text(a)
        imgui.PopStyleColor(1)

        imgui.Spacing()

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

-- ──────────── HUD линия до цели ────────────

local function drawTargetLine()
    local res, mx, my, mz = getMarker()
    if not res or type(mx) ~= 'number' then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    if not isPointOnScreen(mx, my, mz, 1) then return end
    local sx, sy   = convert3DCoordsToScreen(mx, my, mz)
    local px2, py2 = convert3DCoordsToScreen(px, py, pz + 1)
    local col      = braking and 0xFFff4d4d or 0xFFfbd600
    local colGlow  = braking and 0x33ff4d4d or 0x33fbd600
    renderDrawLine(px2, py2, sx, sy, 6*MDS, colGlow)
    renderDrawLine(px2, py2, sx, sy, 2*MDS, col)
    local r = 5*MDS
    renderDrawLine(sx-r, sy, sx+r, sy, 2*MDS, col)
    renderDrawLine(sx, sy-r, sx, sy+r, 2*MDS, col)
end

-- ──────────── exports ────────────

EXPORTS = {
    canToggle = function() return true end,
    getToggle = function() return enabled end,
    toggle    = function()
        if enabled then
            enabled = false; stopFlag = false; arrived = false
            stopDriving()
        else
            if inCar() then
                local res = getMarker()
                if res then enabled = true end
            end
        end
    end,
}

-- ──────────── main ────────────

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end
    wait(500)

    sampAddChatMessage('{cc66ff}[AutoDrive]: {ffffff}v1.0 by Victor Strand | /autodrive', -1)

    sampRegisterChatCommand('autodrive', function()
        WinMain[0] = not WinMain[0]
    end)

    -- поток автоезды
    lua_thread.create(function()
        local lastMX, lastMY = nil, nil

        while true do
            wait(0)

            if not enabled or stopFlag then
                -- ничего не делаем
            elseif not inCar() then
                -- вышли из машины — пауза
                enabled = false
                sampAddChatMessage('{ff4444}[AutoDrive]: \xd2\xfb \xe2\xfb\xf8\xe5\xeb \xe8\xe7 \xec\xe0\xf8\xe8\xed\xfb!', -1)
            else
                local car     = getCar()
                local res, mx, my, mz = getMarker()

                if not res or type(mx) ~= 'number' or type(my) ~= 'number' then
                    -- нет метки — ждём
                else
                    if mx ~= lastMX or my ~= lastMY then
                        lastMX, lastMY = mx, my
                        arrived = false
                        braking = false
                    end

                    if not arrived then
                        local px, py, pz = getCharCoordinates(PLAYER_PED)
                        local dist = getDistanceBetweenCoords3d(px, py, pz, mx, my, mz)

                        -- адаптивная скорость: уменьшаем у цели
                        local topSpd = maxSpeed[0] / 0.5  -- перевод км/ч → ед. GTA
                        local spd
                        if dist > 80 then
                            braking = false
                            spd = topSpd
                        elseif dist > 50 then
                            braking = false
                            spd = topSpd * 0.75
                        elseif dist > 25 then
                            braking = true
                            spd = topSpd * 0.45
                        elseif dist > 10 then
                            braking = true
                            spd = topSpd * 0.25
                        elseif dist > 3 then
                            braking = true
                            spd = topSpd * 0.10
                        else
                            spd = 0
                        end

                        if dist > 2.5 then
                            taskCarDriveToCoord(PLAYER_PED, car, mx, my, mz, spd, 0, 7, 0)
                            wait(100)
                        else
                            -- прибыли
                            taskCarDriveToCoord(PLAYER_PED, car, mx, my, mz, 0, 0, 7, 0)
                            wait(300)
                            for _ = 1, 15 do
                                wait(200)
                                local c2 = getCar()
                                if not c2 or getCarSpeed(c2) < 0.05 then break end
                            end
                            arrived = true
                            braking = false
                            enabled = false
                            sampAddChatMessage('{cc66ff}[AutoDrive]: {44ff44}\xd5\xed\xe0\xf7\xe5 \xe4\xee\xe1\xf0\xe0\xeb\xf1\xff \xe4\xee \xf2\xee\xf7\xea\xe8!', -1)
                            stopDriving()
                        end
                    end
                end
            end
        end
    end)

    -- поток HUD
    lua_thread.create(function()
        while true do
            wait(0)
            if enabled and not arrived and inCar() then
                drawTargetLine()
            end
        end
    end)

    -- свайп радара — открыть меню
    while true do
        if isWidgetSwipedLeft(WIDGET_RADAR) then
            WinMain[0] = not WinMain[0]
        end
        wait(0)
    end
end
