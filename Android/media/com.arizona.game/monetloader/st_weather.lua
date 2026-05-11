script_name('Weather & Time Changer')
script_author('Victor Strand')
script_version('3.0')
script_version_number(3)

local imgui    = require('mimgui')
local ini      = require('inicfg')
local ffi      = require('ffi')
local requests = require('requests')
local encoding = require('encoding')
local lfs      = require('lfs')

encoding.default = 'CP1251'
local u8  = encoding.UTF8
local MDS = MONET_DPI_SCALE or 1
local sw, sh = getScreenResolution()

local folder = getWorkingDirectory() .. '/ST-WeatherTime'
if not lfs.attributes(folder) then lfs.mkdir(folder) end
local configPath = folder .. '/config.ini'

local function readBool(v, d)
    if v == true  or v == 'true'  then return true  end
    if v == false or v == 'false' then return false end
    return d
end
local function readInt(v, d) return math.floor(tonumber(v) or d) end
local function readNum(v, d) return tonumber(v) or d end

local config = ini.load({
    settings = {
        enabled = 'false',
        weather = '0',
        hour    = '12',
        minute  = '0',
        alpha   = '0.90',
    }
}, configPath)
ini.save(config, configPath)

local function saveConfig() ini.save(config, configPath) end

local enabled       = readBool(config.settings.enabled, false)
local customWeather = imgui.new.int(readInt(config.settings.weather, 0))
local customHour    = imgui.new.int(readInt(config.settings.hour,    12))
local customMinute  = imgui.new.int(readInt(config.settings.minute,  0))
local showMenu      = imgui.new.bool(false)
local menuAlpha     = readNum(config.settings.alpha, 0.90)

local SOUND_URL  = 'https://files.catbox.moe/52dk8h.mp3'
local SOUND_FILE = folder .. '/open_sound.mp3'
local bass, menuStream = nil, 0

pcall(function()
    bass = ffi.load('libbass.so')
    ffi.cdef[[
        int           BASS_Init(int device, unsigned long freq, unsigned long flags, void* win, void* clsid);
        unsigned long BASS_StreamCreateFile(int mem, const char* file, unsigned long long offset, unsigned long long length, unsigned long flags);
        unsigned long BASS_StreamCreateURL(const char* url, unsigned long offset, unsigned long flags, void* proc, void* user);
        int           BASS_ChannelPlay(unsigned long handle, int restart);
        int           BASS_ChannelStop(unsigned long handle);
        int           BASS_ChannelSetAttribute(unsigned long handle, unsigned long attrib, float value);
        int           BASS_StreamFree(unsigned long handle);
    ]]
    bass.BASS_Init(-1, 44100, 0, nil, nil)
end)

local function playOpenSound()
    if not bass then return end
    pcall(function()
        if menuStream ~= 0 then
            bass.BASS_ChannelStop(menuStream)
            bass.BASS_StreamFree(menuStream)
            menuStream = 0
        end
        menuStream = doesFileExist(SOUND_FILE)
            and bass.BASS_StreamCreateFile(0, SOUND_FILE, 0, 0, 0)
            or  bass.BASS_StreamCreateURL(SOUND_URL, 0, 0, nil, nil)
        if menuStream ~= 0 then
            bass.BASS_ChannelSetAttribute(menuStream, 2, 0.8)
            bass.BASS_ChannelPlay(menuStream, 1)
        end
    end)
end

local gta = nil
pcall(function()
    gta = ffi.load('GTASA')
    ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
end)
local function openLink(url)
    if gta then pcall(gta._Z12AND_OpenLinkPKc, url) end
end

local function rgba(r, g, b, a)
    a = a or 1.0
    return math.floor(r*255)
         + math.floor(g*255)*256
         + math.floor(b*255)*65536
         + math.floor(a*255)*16777216
end

local HDR_COL_L  = rgba(0.106, 0.157, 0.220, 1.0)
local HDR_COL_M  = rgba(0.086, 0.102, 0.129, 1.0)
local HDR_COL_R  = rgba(0.545, 0.176, 0.176, 1.0)
local ACCENT_RED = rgba(1.0,   0.302, 0.302, 1.0)
local AC = {0.82, 0.68, 0.22}

local function applyStyle()
    imgui.SwitchContext()
    local st = imgui.GetStyle()
    st.WindowRounding    = 12 * MDS
    st.ChildRounding     = 0
    st.FrameRounding     = 4  * MDS
    st.PopupRounding     = 4  * MDS
    st.GrabRounding      = 4  * MDS
    st.ScrollbarRounding = 4  * MDS
    st.WindowPadding     = imgui.ImVec2(0, 0)
    st.FramePadding      = imgui.ImVec2(8 * MDS, 6 * MDS)
    st.ItemSpacing       = imgui.ImVec2(6 * MDS, 5 * MDS)
    st.ScrollbarSize     = 10 * MDS
    st.WindowBorderSize  = 1
    st.ChildBorderSize   = 0

    local c = st.Colors
    local function v4(r,g,b,a) return imgui.ImVec4(r,g,b,a or 1) end
    c[imgui.Col.WindowBg]             = v4(0.059, 0.059, 0.059, menuAlpha)
    c[imgui.Col.ChildBg]              = v4(0, 0, 0, 0.30)
    c[imgui.Col.PopupBg]              = v4(0.059, 0.059, 0.059, 1.0)
    c[imgui.Col.TitleBg]              = v4(0.059, 0.059, 0.059, 1.0)
    c[imgui.Col.TitleBgActive]        = v4(0.059, 0.059, 0.059, 1.0)
    c[imgui.Col.TitleBgCollapsed]     = v4(0.059, 0.059, 0.059, 1.0)
    c[imgui.Col.Text]                 = v4(0.95, 0.92, 0.82)
    c[imgui.Col.TextDisabled]         = v4(0.38, 0.37, 0.33)
    c[imgui.Col.Border]               = v4(1, 1, 1, 0.10)
    c[imgui.Col.FrameBg]              = v4(1, 1, 1, 0.05)
    c[imgui.Col.FrameBgHovered]       = v4(1, 1, 1, 0.10)
    c[imgui.Col.FrameBgActive]        = v4(AC[1], AC[2], AC[3], 0.6)
    c[imgui.Col.Button]               = v4(1, 1, 1, 0.05)
    c[imgui.Col.ButtonHovered]        = v4(1, 1, 1, 0.10)
    c[imgui.Col.ButtonActive]         = v4(AC[1], AC[2], AC[3], 1.0)
    c[imgui.Col.Header]               = v4(1, 1, 1, 0.05)
    c[imgui.Col.HeaderHovered]        = v4(1, 1, 1, 0.10)
    c[imgui.Col.HeaderActive]         = v4(AC[1], AC[2], AC[3], 1.0)
    c[imgui.Col.CheckMark]            = v4(AC[1], AC[2], AC[3])
    c[imgui.Col.SliderGrab]           = v4(AC[1], AC[2], AC[3])
    c[imgui.Col.SliderGrabActive]     = v4(AC[1], AC[2], AC[3])
    c[imgui.Col.Separator]            = v4(1, 1, 1, 0.10)
    c[imgui.Col.ScrollbarBg]          = v4(0, 0, 0, 0)
    c[imgui.Col.ScrollbarGrab]        = v4(1, 1, 1, 0.15)
    c[imgui.Col.ScrollbarGrabHovered] = v4(1, 1, 1, 0.25)
    c[imgui.Col.ScrollbarGrabActive]  = v4(AC[1], AC[2], AC[3])
end

imgui.OnInitialize(function()
    applyStyle()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
end)

local function colorBtn(label, w, h, r, g, b)
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(r,       g,       b,       0.9))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r+0.10,  g+0.10,  b+0.10,  1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(r+0.20,  g+0.20,  b+0.20,  1.0))
    local res = imgui.Button(label, imgui.ImVec2(w, h))
    imgui.PopStyleColor(3)
    return res
end

local function tgBtn(label, url, w, h)
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.12, 0.49, 0.88, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.62, 1.00, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.08, 0.38, 0.76, 1.0))
    if imgui.Button(label, imgui.ImVec2(w, h)) then openLink(url) end
    imgui.PopStyleColor(3)
end

local weatherNames = {
    [0]='Sunny',[1]='Cloudy',[2]='Rainy',[3]='Foggy',[4]='Extra Sunny',
    [5]='Hurricane',[6]='Extra Colors',[7]='Halloween',[8]='Thunderstorm',
    [9]='Sunny2',[10]='Cloudy2',[11]='Sunny3',[12]='Extra Sunny2',
    [13]='Overcast',[14]='Rainy2',[15]='Thunderstorm2',[16]='Foggy2',
    [17]='Foggy3',[18]='Cloudy3',[19]='Sunny4',[20]='Sunny5',
    [21]='Sunny6',[22]='Sunny7',[23]='Sunny8',[24]='Sunny9',
    [25]='Sunny10',[26]='Sunny11',[27]='Sunny12',[28]='Sunny13',
    [29]='Sunny14',[30]='Sunny15',[31]='Sunny16',[32]='Sunny17',
    [33]='Sunny18',[34]='Sunny19',[35]='Sunny20',[36]='Sunny21',
    [37]='Sunny22',[38]='Sunny23',[39]='Sunny24',[40]='Sunny25',
    [41]='Sunny26',[42]='Sunny27',[43]='Sunny28',[44]='Sunny29',
    [45]='Sunny30',
}
local function wName(id) return weatherNames[id] or ('Weather '..id) end

local WIN_W     = 540 * MDS
local WIN_H     = 420 * MDS
local HDR_H     = 44  * MDS
local FOOTER_H  = 40  * MDS
local CONTENT_H = WIN_H - HDR_H - FOOTER_H

imgui.OnFrame(function() return showMenu[0] end, function(self)
    self.HideCursor = true
    applyStyle()

    imgui.SetNextWindowPos(imgui.ImVec2(sw*0.5, sh*0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(WIN_W, WIN_H), imgui.Cond.Always)
    imgui.Begin('##stmain', showMenu,
        imgui.WindowFlags.NoResize +
        imgui.WindowFlags.NoScrollbar +
        imgui.WindowFlags.NoTitleBar)

    local dl = imgui.GetWindowDrawList()
    local wp = imgui.GetWindowPos()

    local midX = wp.x + WIN_W * 0.5
    dl:AddRectFilledMultiColor(
        imgui.ImVec2(wp.x,  wp.y), imgui.ImVec2(midX,       wp.y+HDR_H),
        HDR_COL_L, HDR_COL_M, HDR_COL_M, HDR_COL_L)
    dl:AddRectFilledMultiColor(
        imgui.ImVec2(midX,  wp.y), imgui.ImVec2(wp.x+WIN_W, wp.y+HDR_H),
        HDR_COL_M, HDR_COL_R, HDR_COL_R, HDR_COL_M)

    local titleTxt = u8('WEATHER & TIME CHANGER')
    local tsz = imgui.CalcTextSize(titleTxt)
    imgui.SetCursorScreenPos(imgui.ImVec2(wp.x+(WIN_W-tsz.x)*0.5, wp.y+(HDR_H-tsz.y)*0.5))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1,1,1,1))
    imgui.SetWindowFontScale(0.95)
    imgui.Text(titleTxt)
    imgui.SetWindowFontScale(1.0)
    imgui.PopStyleColor(1)

    local mpos    = imgui.GetIO().MousePos
    local closeSz = 26*MDS
    local closeX  = wp.x + WIN_W - closeSz - 10*MDS
    local closeY  = wp.y + (HDR_H - closeSz)*0.5
    local hovClose = mpos.x >= closeX and mpos.x <= closeX+closeSz
                 and mpos.y >= closeY and mpos.y <= closeY+closeSz
    dl:AddRectFilled(
        imgui.ImVec2(closeX, closeY), imgui.ImVec2(closeX+closeSz, closeY+closeSz),
        hovClose and ACCENT_RED or rgba(1,1,1,0.10), 4*MDS)
    local cp = 7*MDS
    dl:AddLine(imgui.ImVec2(closeX+cp,         closeY+cp),         imgui.ImVec2(closeX+closeSz-cp, closeY+closeSz-cp), rgba(1,1,1, hovClose and 1.0 or 0.6), 1.8)
    dl:AddLine(imgui.ImVec2(closeX+closeSz-cp, closeY+cp),         imgui.ImVec2(closeX+cp,         closeY+closeSz-cp), rgba(1,1,1, hovClose and 1.0 or 0.6), 1.8)
    imgui.SetCursorScreenPos(imgui.ImVec2(closeX, closeY))
    if imgui.InvisibleButton('##close', imgui.ImVec2(closeSz, closeSz)) then
        showMenu[0] = false
    end

    dl:AddLine(imgui.ImVec2(wp.x, wp.y+HDR_H), imgui.ImVec2(wp.x+WIN_W, wp.y+HDR_H), rgba(1,1,1,0.10), 1)

    imgui.SetCursorScreenPos(imgui.ImVec2(wp.x+20*MDS, wp.y+HDR_H+12*MDS))
    local childW = WIN_W - 40*MDS
    local childH = CONTENT_H - 12*MDS

    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0,0,0,0))
    if imgui.BeginChild('##content', imgui.ImVec2(childW, childH), false,
            imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse) then

        local bw = childW

        if enabled then
            if colorBtn(u8('[ \xc2\xdb\xca\xcb\xde\xd7\xc8\xd2\xdc ]'), bw, 44*MDS, 0.55, 0.06, 0.06) then
                enabled = false
                config.settings.enabled = 'false'
                saveConfig()
                sampAddChatMessage('{FF8800}[ST]{FFFFFF} \xc2\xfb\xea\xeb\xfe\xf7\xe5\xed\xee', -1)
            end
        else
            if colorBtn(u8('[ \xc2\xca\xcb\xde\xd7\xc8\xd2\xdc ]'), bw, 44*MDS, 0.06, 0.46, 0.10) then
                enabled = true
                config.settings.enabled = 'true'
                saveConfig()
                sampAddChatMessage('{FF8800}[ST]{FFFFFF} \xc2\xea\xeb\xfe\xf7\xe5\xed\xee', -1)
            end
        end

        imgui.Dummy(imgui.ImVec2(0, 10*MDS))
        local sep = imgui.GetCursorScreenPos()
        imgui.GetWindowDrawList():AddRectFilled(
            imgui.ImVec2(sep.x, sep.y), imgui.ImVec2(sep.x+childW, sep.y+1), rgba(1,1,1,0.10))
        imgui.Dummy(imgui.ImVec2(0, 8*MDS))

        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(AC[1], AC[2], AC[3], 1))
        imgui.Text(u8('\xcf\xee\xe3\xee\xe4\xe0: ') .. wName(customWeather[0]) .. '  [' .. customWeather[0] .. ']')
        imgui.PopStyleColor(1)
        imgui.SetNextItemWidth(childW)
        if imgui.SliderInt('##weather', customWeather, 0, 45) then
            config.settings.weather = tostring(customWeather[0])
            saveConfig()
        end

        imgui.Dummy(imgui.ImVec2(0, 8*MDS))

        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(AC[1], AC[2], AC[3], 1))
        imgui.Text(string.format(u8('\xc2\xf0\xe5\xec\xff: %02d:%02d'), customHour[0], customMinute[0]))
        imgui.PopStyleColor(1)
        imgui.SetNextItemWidth(childW)
        if imgui.SliderInt('##hour', customHour, 0, 23) then
            config.settings.hour = tostring(customHour[0])
            saveConfig()
        end
        imgui.SetNextItemWidth(childW)
        if imgui.SliderInt('##min', customMinute, 0, 59) then
            config.settings.minute = tostring(customMinute[0])
            saveConfig()
        end

        imgui.Dummy(imgui.ImVec2(0, 12*MDS))
        local sep2 = imgui.GetCursorScreenPos()
        imgui.GetWindowDrawList():AddRectFilled(
            imgui.ImVec2(sep2.x, sep2.y), imgui.ImVec2(sep2.x+childW, sep2.y+1), rgba(1,1,1,0.10))
        imgui.Dummy(imgui.ImVec2(0, 8*MDS))

        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(AC[1], AC[2], AC[3], 1))
        local atxt = u8('\xc0\xe2\xf2\xee\xf0: Victor Strand')
        local asz  = imgui.CalcTextSize(atxt)
        imgui.SetCursorPosX((childW - asz.x)*0.5)
        imgui.Text(atxt)
        imgui.PopStyleColor(1)
        imgui.Spacing()

        local bw2 = (childW - 4*MDS) * 0.5
        tgBtn('@victor_st0',    'https://t.me/victor_st0',     bw2, 34*MDS)
        imgui.SameLine(0, 4*MDS)
        tgBtn('strand_scripts', 'https://t.me/strand_scripts', bw2, 34*MDS)

        imgui.EndChild()
    end
    imgui.PopStyleColor(1)

    local footerY1 = wp.y + WIN_H - FOOTER_H
    dl:AddRectFilled(
        imgui.ImVec2(wp.x, footerY1), imgui.ImVec2(wp.x+WIN_W, wp.y+WIN_H),
        rgba(0,0,0,0.40), 0, 12)
    dl:AddLine(
        imgui.ImVec2(wp.x, footerY1), imgui.ImVec2(wp.x+WIN_W, footerY1),
        rgba(1,1,1,0.10), 1)

    local fStatusTxt = enabled
        and u8('\xe0\xea\xf2\xe8\xe2\xed\xee  \xe2\xea\xeb\xfe\xf7\xe5\xed\xee')
        or  u8('\xef\xee\xe3\xee\xe4\xe0  \xe2\xfb\xea\xeb\xfe\xf7\xe5\xed\xe0')
    local fStatusSz  = imgui.CalcTextSize(fStatusTxt)
    local fStatusCol = enabled and rgba(0.18,0.88,0.32,0.7) or rgba(1,1,1,0.25)
    dl:AddText(
        imgui.ImVec2(wp.x+(WIN_W-fStatusSz.x)*0.5, footerY1+(FOOTER_H-fStatusSz.y)*0.5),
        fStatusCol, fStatusTxt)

    local verTxt = 'v3.0'
    local verSz  = imgui.CalcTextSize(verTxt)
    dl:AddText(
        imgui.ImVec2(wp.x+WIN_W-verSz.x-14*MDS, footerY1+(FOOTER_H-verSz.y)*0.5),
        rgba(1,1,1,0.20), verTxt)

    imgui.End()
end)

function main()
    while not isSampAvailable() do wait(100) end

    lua_thread.create(function()
        wait(2000)
        if not doesFileExist(SOUND_FILE) then
            local ok, resp = pcall(requests.get, SOUND_URL)
            if ok and resp and resp.status_code == 200 then
                local f = io.open(SOUND_FILE, 'wb')
                if f then f:write(resp.text); f:close() end
            end
        end
    end)

    sampRegisterChatCommand('stmenu', function()
        showMenu[0] = not showMenu[0]
        if showMenu[0] then lua_thread.create(playOpenSound) end
    end)

    sampAddChatMessage('{FF8800}[ST]{FFFFFF} Weather & Time v3.0  |  /stmenu  |  by Victor Strand', -1)

    while true do
        wait(0)
        if enabled then
            forceWeatherNow(customWeather[0])
            setTimeOfDay(customHour[0], customMinute[0])
        end
    end
end

function onScriptTerminate(script)
    if script == thisScript() then saveConfig() end
end
