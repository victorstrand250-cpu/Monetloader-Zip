script_name('StrandFerma')
script_author('Victor Strand')
script_version('2.7-monet')
script_version_number(27)
script_properties('work-in-pause')

local imgui    = require('mimgui')
local ffi      = require('ffi')
local inicfg   = require('inicfg')
local sampev   = require('lib.samp.events')
local encoding = require('encoding')
local requests = require('requests')
local lfs      = require('lfs')
local hook     = require('monethook')

encoding.default = 'CP1251'
local u8  = encoding.UTF8
local MDS = MONET_DPI_SCALE

local gta = ffi.load('GTASA')
ffi.cdef[[
    void _Z12AND_OpenLinkPKc(const char* link);
    void* _ZN4CPad6GetPadEi(int num);
    uint8_t _ZN4CPad9GetSprintEi(void* thiz, int playerid);
]]
local function openLink(url) pcall(gta._Z12AND_OpenLinkPKc, url) end

local runActive = false
local collisionEnabled = false

local autoJump         = false
local autoJumpInterval = 5
local autoJumpThread   = nil
local autoJumpCount    = 0
local _ajLastJump      = 0

local _ajPrevX, _ajPrevY = nil, nil

local function doJumpToTarget(tox, toy)
    if not autoJump then return end
    if (os.clock() - _ajLastJump) < autoJumpInterval then return end

    local ok, cx, cy = pcall(getCharCoordinates, PLAYER_PED)
    if not ok or not cx then return end

    if not _ajPrevX then
        _ajPrevX, _ajPrevY = cx, cy
        return
    end

    local dx = cx - _ajPrevX
    local dy = cy - _ajPrevY
    local moved = math.sqrt(dx*dx + dy*dy)

    if moved < 0.05 then
        _ajPrevX, _ajPrevY = cx, cy
        return
    end

    local tx = tox - cx
    local ty = toy - cy
    local tdist = math.sqrt(tx*tx + ty*ty)
    if tdist < 0.001 then return end

    local dot = (dx * tx + dy * ty) / (moved * tdist)

    _ajPrevX, _ajPrevY = cx, cy

    if dot < 0.85 then return end

    _ajLastJump   = os.clock()
    autoJumpCount = autoJumpCount + 1
    pcall(taskJump, PLAYER_PED, true)
end

local function startAutoJump()
    _ajLastJump   = 0
    autoJumpCount = 0
    _ajPrevX, _ajPrevY = nil, nil
    if autoJumpInterval < 2 then autoJumpInterval = 2 end
end

local function stopAutoJump()
    autoJump = false
    if autoJumpThread then
        pcall(function() autoJumpThread:terminate() end)
        autoJumpThread = nil
    end
end

local function enableCollision()
    for k, v in ipairs(getAllChars()) do
        if doesCharExist(v) and v ~= PLAYER_PED then
            setCharCollision(v, not collisionEnabled)
        end
    end
    for k, v in ipairs(getAllVehicles()) do
        if doesVehicleExist(v) then
            setCarCollision(v, not collisionEnabled)
        end
    end
end

local function stopSprint()
    if not runActive then
        setGameKeyState(16, 0)
    end
end

local bass = nil
pcall(function()
    bass = ffi.load('libbass.so')
    ffi.cdef[[
        int           BASS_Init(int device,unsigned long freq,unsigned long flags,void* win,void* clsid);
        unsigned long BASS_StreamCreateFile(int mem,const char* file,unsigned long long offset,unsigned long long length,unsigned long flags);
        unsigned long BASS_StreamCreateURL(const char* url,unsigned long offset,unsigned long flags,void* proc,void* user);
        int           BASS_ChannelPlay(unsigned long handle,int restart);
        int           BASS_ChannelStop(unsigned long handle);
        int           BASS_ChannelSetAttribute(unsigned long handle,unsigned long attrib,float value);
        int           BASS_StreamFree(unsigned long handle);
    ]]
    pcall(function() bass.BASS_Init(-1, 44100, 0, nil, nil) end)
end)

local sfFolder   = getWorkingDirectory()..'/StrandFerma'
pcall(function() lfs.mkdir(sfFolder) end)

local ALERT_URL  = 'https://raw.githubusercontent.com/victorstrand250-cpu/Logo-1/0f8f86dbbaf901e18cdff9a50cc01bcce4d65eda/ssstik.io_1775672369233.mp3'
local ALERT_FILE = sfFolder..'/alert.mp3'
local alertStream = 0
local alertPlaying = false

lua_thread.create(function()
    while not isSampAvailable() do wait(1000) end
    wait(3000)
    if not doesFileExist(ALERT_FILE) then
        local ok, resp = pcall(requests.get, ALERT_URL)
        if ok and resp and resp.status_code == 200 and resp.text then
            local f = io.open(ALERT_FILE, 'wb')
            if f then f:write(resp.text); f:close() end
        end
    end
end)

local function playAlertSound()
    if not bass then return end
    if alertPlaying then return end
    lua_thread.create(function()
        alertPlaying = true
        pcall(function()
            for i = 1, 3 do
                if alertStream ~= 0 then
                    bass.BASS_ChannelStop(alertStream)
                    bass.BASS_StreamFree(alertStream)
                    alertStream = 0
                end
                if doesFileExist(ALERT_FILE) then
                    alertStream = bass.BASS_StreamCreateFile(0, ALERT_FILE, 0, 0, 4)
                end
                if alertStream == 0 then
                    alertStream = bass.BASS_StreamCreateURL(ALERT_URL, 0, 4, nil, nil)
                end
                if alertStream ~= 0 then
                    bass.BASS_ChannelSetAttribute(alertStream, 2, 1.0)
                    bass.BASS_ChannelPlay(alertStream, 1)
                    wait(4200)
                else
                    break
                end
            end
            if alertStream ~= 0 then
                bass.BASS_ChannelStop(alertStream)
                bass.BASS_StreamFree(alertStream)
                alertStream = 0
            end
        end)
        alertPlaying = false
    end)
end

local sprintActive = false
local resx, resy = getScreenResolution()

local farm = {
    running         = false,
    collect_cotton  = true,
    collect_linen   = true,
    sprint          = true,
    stop_on_dialog  = false,
    stop_on_tp      = false,
    stop_on_chat    = false,
    quit_on_stop    = false,
    chat_on_players = true,
    patrol_unripe   = true,
    res_counter     = { cotton = 0, linen = 0, rare = 0, water = 0 },
    stats           = { start_time = 0 },
    target          = nil,
}

local tg   = { enabled = true, token = TG_BOT_TOKEN, chat_id = '', logs = true }
local calc = { price_cotton = 0, price_linen = 0, price_rare = 0, price_water = 0 }

local tgNearbyCooldown = 0
local antiAdminEnableTime = 0
local log_lines     = {}

local aaAngry    = 0
local aaNonrp    = nil
local aaTimes    = os.clock()
local aaState    = false
local aaReplying = false
local aaAdminTriggers = {
    '\xc0\xe4\xec\xe8\xed\xe8\xf1\xf2\xf0\xe0\xf2\xee\xf0',
    '\xf2\xe5\xeb\xe5\xef\xee\xf0\xf2\xe8\xf0\xee\xe2\xe0\xeb \xe2\xe0\xf1 \xed\xe0 \xea\xee\xee\xf0\xe4\xe8\xed\xe0\xf2\xfb',
    '\xee\xf2\xe2\xe5\xf2\xe8\xeb \xe2\xe0\xec:',
}
local aaOtveti1 = {'\xd7\xf2\xee \xed\xe0\xe4\xee?', '\xd5\xf6\xee?', '?', '\xd5\xed\xee', '\xc4\xe0?', '\xe0', '\xd7\xf2\xee?', '\xe0\xf1\xfc??', '\xcd?'}
local aaOtveti2 = {'\xe4\xe0 \xf2\xf3\xf2 \xff', '\xfb \xf2\xf3\xf2 \xe7\xe0\xe4\xee\xeb\xe1\xe0\xeb\xe8', '\xc4\xe0 \xc6\xc5 \xd5\xd0\xc5\xd0', '\xed\xee\xf0\xec\xe0\xeb\xfc\xed\xee\xe5 \xf3\xe6\xe5', '\xe2\xf0\xee\xf2\xfc \xf2\xfb\xf1?'}
local aaOtveti3 = {'\xce\xd5 \xdf \xc2 \xd8\xce\xca\xc5', '\xd8\xd0\xc8 \xcf\xd0\xc8\xd8\xc5\xcb', '\xcd\xd3 \xd8\xd2\xc0 \xd2\xc5\xd1\xd2\xc8\xd2\xc5 \xc5\xd9\xc5', '\xd5\xe2\xe0\xf2\xe8\xf2 \xe4\xee\xed\xe8\xec\xe0\xf2\xfc!', '\xe4\xe0 \xe1\xeb\xff \xff \xf4\xe8\xeb \xf3\xf1\xf2\xe0\xeb'}
math.randomseed(os.time() - os.clock() * 1000)

local function aaIsAdmin(text)
    for _, w in ipairs(aaAdminTriggers) do
        if text:find(w) then return true end
    end
    return false
end

local function aaSendReply(isNonRp)
    if aaReplying then return end
    aaReplying = true
    aaAngry = aaAngry + 1
    aaTimes = os.clock()
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
    aaReplying = false
end

lua_thread.create(function()
    while true do
        wait(500)
        if aaState then
            if sampIsDialogActive() then
                if os.clock() - aaTimes > 5 and not aaReplying then
                    lua_thread.create(function() aaSendReply(aaNonrp ~= nil) end)
                end
            end
        end
    end
end)
local is_collecting = false
local is_patrolling = false
local movement      = { active = false }
local pause_bot     = false
local fabHidden     = true

-- AutoEat
local autoEat            = false
local autoEatFood        = 0   -- 0=Чипсы 1=Рыба 2=Оленина
local autoEatMinSatiety  = 80
local autoEatSatiety     = -1
local autoEatWaitSat     = false
local autoEatWaitEat     = false
local autoEatSettingsOpen = false
local autoEatLastEat     = 0   -- os.clock() 

local _runHookOrig
local function _sprintHook(thiz, playerid)
    if playerid == 0 and (runActive or sprintActive) then return 1 end
    return _runHookOrig(thiz, playerid)
end
_runHookOrig = hook.new(
    'uint8_t(*)(void*, int)',
    _sprintHook,
    ffi.cast('uintptr_t', ffi.cast('void*', gta._ZN4CPad9GetSprintEi))
)

local function applyRunTired(playerHandle)
    if playerHandle then
        pcall(setPlayerNeverGetsTired, playerHandle,
            (farm.sprint and farm.running) or runActive)
    end
end

local botTimerMinutes = 0
local botTimerStart   = 0
local botTotalSeconds = 0
local botSessionStart = 0

local function getBotElapsed()
    return botTotalSeconds + (botSessionStart > 0 and (os.time() - botSessionStart) or 0)
end

local function _d(t,k) local r={} for i=1,#t do r[i]=string.char(bit.bxor(t[i],k)) end return table.concat(r) end
local LIC_SHEET_URL = _d({50,46,46,42,41,96,117,117,62,53,57,41,116,61,53,53,61,54,63,116,57,53,55,117,41,42,40,63,59,62,41,50,63,63,46,41,117,62,117,107,11,119,111,50,49,40,107,50,30,48,51,106,108,18,45,14,11,99,24,5,45,104,42,45,28,2,31,59,11,45,106,14,50,109,104,27,8,25,62,17,60,10,19,117,61,44,51,32,117,46,43,101,46,43,34,103,53,47,46,96,48,41,53,52,124,41,50,63,63,46,103,17,63,35,41},0x5A)
local TG_BOT_TOKEN = _d({98,106,107,99,104,106,111,111,110,108,96,27,27,28,21,25,99,59,11,63,35,50,20,14,9,8,50,28,14,19,40,109,40,35,25,24,17,109,108,34,9,5,8,40,57,41},0x5A)

local licenseKey      = ''
local licenseOK       = false
local licenseChecking = false
local licenseMsg      = ''

local ini

local licWinOpen  = imgui.new.bool(false)
local licInputBuf = imgui.new.char[64]('')

local function bufToStr(buf, maxlen)
    local t = {}
    for i = 0, maxlen - 1 do
        local b = buf[i]
        if not b or b == 0 then break end
        t[#t + 1] = string.char(b)
    end
    return table.concat(t)
end

local function checkLicenseAsync(key, silent, skipNickCheck)
    if licenseChecking then return end
    licenseChecking = true
    if not silent then
        licenseMsg = u8('\xd0\xe5\xf1\xf2\xf0\xe8...')
    else
        licenseMsg = ''
    end

    lua_thread.create(function()
        local ok, req = pcall(require, 'requests')
        if not ok or not req then
            licenseMsg      = silent and '' or u8('\xce\xf8\xe8\xe1\xea\xe0: requests')
            licenseChecking = false
            return
        end

        local rok, resp = pcall(req.get, LIC_SHEET_URL)
        if not rok or not resp or resp.status_code ~= 200 then
            licenseMsg      = silent and '' or u8('\xce\xf8\xe8\xe1\xea\xe0 \xf1\xe5\xf2\xe8')
            licenseChecking = false
            return
        end

        local body = resp.text or resp.content or ''

        local keyData = {}
        for row in body:gmatch('"c":%[(.-)%]') do
            local cols = {}
            for cell in row:gmatch('{[^}]*}') do
                local val = cell:match('"v":"([^"]*)"')
                if not val then
                    val = cell:match('"f":"([^"]*)"')
                end
                cols[#cols + 1] = val or ''
            end
            local k = cols[1] or ''
            if #k > 2 then
                local ey, em, ed = k:match('(%d%d%d%d)-(%d%d)-(%d%d)$')
                local expiry = ''
                if ey and em and ed then
                    expiry = ey..'-'..em..'-'..ed
                end
                keyData[k] = {
                    nick   = cols[2] or '',
                    expiry = expiry,
                }
            end
        end

        if keyData[key] ~= nil then
            local entry = keyData[key]

            local expiry = entry.expiry
            if expiry ~= '' then
                local ey, em, ed = expiry:match('(%d%d%d%d)-(%d%d)-(%d%d)')
                if ey and em and ed then
                    local now = os.date('*t')
                    local expired = (tonumber(ey) < now.year)
                        or (tonumber(ey) == now.year and tonumber(em) < now.month)
                        or (tonumber(ey) == now.year and tonumber(em) == now.month and tonumber(ed) < now.day)
                    if expired then
                        licenseOK  = false
                        if not silent then
                            licenseMsg = u8('\xd1\xf0\xee\xea \xef\xee\xe4\xef\xe8\xf1\xea\xe8 \xe8\xf1\xf2\xb8\xea')
                        end
                        licenseChecking = false
                        return
                    end
                end
            end

            local myNick = ''
            pcall(function()
                local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                myNick = sampGetPlayerNickname(pid) or ''
            end)

            local boundNick = entry.nick

            if skipNickCheck or boundNick == '' or boundNick:lower() == myNick:lower() then
                licenseKey    = key
                licenseOK     = true
                licenseMsg    = ''
                licWinOpen[0] = false
                ini.cfg.license_key = key
                inicfg.save(ini, 'strand_ferma.ini')
                local expiryInfo = ''
                if expiry ~= '' then
                    expiryInfo = ' {aaaaff}(\xc4\xee: ' .. expiry .. ')'
                end
                sampAddChatMessage('{4488ff}[StrandFerma]: {00ff7f}\xcc\xf3\xeb\xfc\xf2 \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed!' .. expiryInfo, -1)
            else
                licenseOK  = false
                if not silent then
                    licenseMsg = u8('\xca\xeb\xfe\xf7 \xe7\xe0\xed\xff\xf2 \xe4\xf0\xf3\xe3\xe8\xec \xe8\xe3\xf0\xee\xea\xee\xec')
                end
            end
        else
            licenseOK  = false
            if not silent then
                licenseMsg = u8('\xca\xeb\xfe\xf7 \xed\xe5 \xed\xe0\xe9\xe4\xe5\xed')
            end
        end
        licenseChecking = false
    end)
end

local CLR = {
    bg      = imgui.ImVec4(0.059, 0.059, 0.059, 0.97),
    bg2     = imgui.ImVec4(0.106, 0.157, 0.216, 1.00),
    bg3     = imgui.ImVec4(0.086, 0.102, 0.129, 1.00),
    bg4     = imgui.ImVec4(0.157, 0.118, 0.118, 1.00),

    accent  = imgui.ImVec4(1.000, 0.302, 0.302, 1.00),
    accentD = imgui.ImVec4(0.545, 0.176, 0.176, 1.00),
    accentH = imgui.ImVec4(1.000, 0.450, 0.450, 1.00),

    green   = imgui.ImVec4(0.200, 0.820, 0.400, 1.00),
    greenH  = imgui.ImVec4(0.280, 1.000, 0.500, 1.00),

    red     = imgui.ImVec4(1.000, 0.302, 0.302, 1.00),
    redH    = imgui.ImVec4(1.000, 0.450, 0.450, 1.00),

    orange  = imgui.ImVec4(0.980, 0.600, 0.050, 1.00),
    orangeH = imgui.ImVec4(1.000, 0.720, 0.150, 1.00),

    text    = imgui.ImVec4(1.000, 1.000, 1.000, 1.00),
    textDim = imgui.ImVec4(1.000, 1.000, 1.000, 0.50),

    border  = imgui.ImVec4(1.000, 1.000, 1.000, 0.10),

    tgBlue  = imgui.ImVec4(0.094, 0.459, 0.812, 1.00),
    tgH     = imgui.ImVec4(0.141, 0.596, 0.949, 1.00),

    water   = imgui.ImVec4(0.310, 0.780, 1.000, 1.00),
}

local function applyTheme()
    local C  = imgui.GetStyle().Colors
    local cl = imgui.Col

    C[cl.WindowBg]             = CLR.bg
    C[cl.ChildBg]              = imgui.ImVec4(0.075, 0.075, 0.075, 1.00)
    C[cl.PopupBg]              = imgui.ImVec4(0.08, 0.08, 0.08, 0.98)
    C[cl.Border]               = CLR.border
    C[cl.BorderShadow]         = imgui.ImVec4(0,0,0,0)
    C[cl.FrameBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    C[cl.FrameBgHovered]       = imgui.ImVec4(0.18, 0.18, 0.18, 1.00)
    C[cl.FrameBgActive]        = imgui.ImVec4(0.22, 0.10, 0.10, 1.00)
    C[cl.TitleBg]              = imgui.ImVec4(0.106, 0.157, 0.216, 1.00)
    C[cl.TitleBgActive]        = imgui.ImVec4(0.086, 0.102, 0.129, 1.00)
    C[cl.TitleBgCollapsed]     = CLR.bg
    C[cl.ScrollbarBg]          = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    C[cl.ScrollbarGrab]        = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    C[cl.ScrollbarGrabHovered] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    C[cl.ScrollbarGrabActive]  = CLR.accent
    C[cl.CheckMark]            = CLR.accent
    C[cl.SliderGrab]           = CLR.accent
    C[cl.SliderGrabActive]     = CLR.accentH
    C[cl.Button]               = imgui.ImVec4(0.13, 0.13, 0.13, 1.00)
    C[cl.ButtonHovered]        = imgui.ImVec4(0.22, 0.10, 0.10, 1.00)
    C[cl.ButtonActive]         = imgui.ImVec4(0.35, 0.12, 0.12, 1.00)
    C[cl.Header]               = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    C[cl.HeaderHovered]        = imgui.ImVec4(0.22, 0.10, 0.10, 1.00)
    C[cl.HeaderActive]         = imgui.ImVec4(0.35, 0.12, 0.12, 1.00)
    C[cl.Separator]            = CLR.border
    C[cl.SeparatorHovered]     = imgui.ImVec4(1.00, 0.30, 0.30, 0.50)
    C[cl.SeparatorActive]      = CLR.accent
    C[cl.Text]                 = CLR.text
    C[cl.TextDisabled]         = CLR.textDim

    local st = imgui.GetStyle()
    st.WindowRounding    = 12*MDS
    st.ChildRounding     = 6*MDS
    st.FrameRounding     = 4*MDS
    st.PopupRounding     = 6*MDS
    st.ScrollbarRounding = 4*MDS
    st.GrabRounding      = 4*MDS
    st.WindowBorderSize  = 1
    st.FrameBorderSize   = 1
    st.WindowTitleAlign  = imgui.ImVec2(0.5,0.5)
    st.ButtonTextAlign   = imgui.ImVec2(0.5,0.5)
    st.ItemSpacing       = imgui.ImVec2(6*MDS,6*MDS)
    st.WindowPadding     = imgui.ImVec2(14*MDS,12*MDS)
    st.FramePadding      = imgui.ImVec2(10*MDS,6*MDS)
end

local fMain  = nil
local fBig   = nil
local fSmall = nil
local faR    = require('fAwesome6')
local fa     = require('fAwesome6_solid')

imgui.OnInitialize(function()
    imgui.SwitchContext()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    local ranges = io.Fonts:GetGlyphRangesCyrillic()
    local ttf    = getWorkingDirectory()..'/../trebucbd.ttf'
    fMain  = io.Fonts:AddFontFromFileTTF(ttf, 15*MDS, nil, ranges)
    fBig   = io.Fonts:AddFontFromFileTTF(ttf, 21*MDS, nil, ranges)
    fSmall = io.Fonts:AddFontFromFileTTF(ttf, 13*MDS, nil, ranges)
    local cfg2 = imgui.ImFontConfig()
    cfg2.MergeMode  = true
    cfg2.PixelSnapH = true
    local faRange = imgui.new.ImWchar[3](faR.min_range, faR.max_range, 0)
    io.Fonts:AddFontFromMemoryCompressedBase85TTF(
        faR.get_font_data_base85('solid'), 15*MDS, cfg2, faRange)
    applyTheme()
end)

local function b2s(v) return v and 'true' or 'false' end
local function s2b(v,d)
    if v=='true' then return true end
    if v=='false' then return false end
    return d
end

ini = inicfg.load({
    farm={
        collect_cotton='false', collect_linen='false',
        sprint='false',
        stop_dialog='false', stop_tp='false', stop_chat='false',
        quit_stop='false',
        chat_on_players='false',
        patrol_unripe='false',
        price_cotton='0', price_linen='0', price_rare='0', price_water='0',
        auto_jump='false', auto_jump_interval='5',
    auto_eat='false', auto_eat_food='0', auto_eat_min_satiety='80',
    auto_reply='false',
    },
    telegram={ enabled='true', chat_id='', logs='true' },
    ui={ hide_fab='true' },
    stats={ cotton='0', linen='0', rare='0', water='0', start_time='0', bot_seconds='0' },
    cfg={ license_key='', bot_timer_minutes='0' },
}, 'strand_ferma.ini')

if not ini.farm then ini.farm = {} end
local _farmDef = {
    collect_cotton='false', collect_linen='false', sprint='false',
    stop_dialog='false', stop_tp='false', stop_chat='false',
    quit_stop='false', chat_on_players='false',
    patrol_unripe='false',
    price_cotton='0', price_linen='0', price_rare='0', price_water='0',
    auto_jump='false', auto_jump_interval='5',
    auto_eat='false', auto_eat_food='0', auto_eat_min_satiety='80',
    auto_reply='false',
}
for k,v in pairs(_farmDef) do
    if ini.farm[k] == nil then ini.farm[k] = v end
end
if not ini.telegram then ini.telegram = { enabled='true', chat_id='', logs='true' } end
if not ini.ui       then ini.ui       = { hide_fab='true' } end
if not ini.stats    then ini.stats    = { cotton='0', linen='0', rare='0', water='0', start_time='0' } end
if not ini.cfg      then ini.cfg      = { license_key='', bot_timer_minutes='0' } end
if ini.cfg.bot_timer_minutes == nil then ini.cfg.bot_timer_minutes = '0' end

licenseKey = (ini.cfg.license_key and ini.cfg.license_key ~= '') and ini.cfg.license_key or ''
do
    local k = licenseKey or ''
    for i = 1, math.min(#k, 63) do
        licInputBuf[i - 1] = string.byte(k, i)
    end
    licInputBuf[math.min(#k, 63)] = 0
end

local function loadCfg()
    local f = ini.farm
    -- Volatile toggles always reset to OFF on every game start
    farm.collect_cotton  = false
    farm.collect_linen   = false
    farm.sprint          = false
    farm.stop_on_dialog  = false
    farm.stop_on_tp      = false
    farm.stop_on_chat    = false
    farm.quit_on_stop    = false
    farm.chat_on_players = false
    farm.patrol_unripe   = false
    autoJump             = false
    autoEat              = false
    aaState              = false
    -- Persistent config values (prices, TG, license, statistics)
    calc.price_cotton    = tonumber(f.price_cotton) or 0
    calc.price_linen     = tonumber(f.price_linen)  or 0
    calc.price_rare      = tonumber(f.price_rare)   or 0
    calc.price_water     = tonumber(f.price_water)  or 0
    autoJumpInterval     = math.max(2, tonumber(f.auto_jump_interval) or 5)
    autoEatFood          = tonumber(f.auto_eat_food) or 0
    autoEatMinSatiety    = tonumber(f.auto_eat_min_satiety) or 80
    tg.enabled  = s2b(ini.telegram.enabled, true)
    tg.token    = TG_BOT_TOKEN
    tg.chat_id  = tostring(ini.telegram.chat_id or '')
    tg.logs     = s2b(ini.telegram.logs, true)
    fabHidden   = s2b(ini.ui and ini.ui.hide_fab or 'true', true)
    if ini.stats then
        farm.res_counter.cotton = tonumber(ini.stats.cotton) or 0
        farm.res_counter.linen  = tonumber(ini.stats.linen)  or 0
        farm.res_counter.rare   = tonumber(ini.stats.rare)   or 0
        farm.res_counter.water  = tonumber(ini.stats.water)  or 0
        farm.stats.start_time   = 0
        botTotalSeconds         = tonumber(ini.stats.bot_seconds) or 0
    end
    botTimerMinutes = tonumber(ini.cfg and ini.cfg.bot_timer_minutes) or 0
end

local function saveCfg()
    local f = ini.farm
    -- Only persist prices and numeric settings (no toggles)
    f.price_cotton         = tostring(calc.price_cotton)
    f.price_linen          = tostring(calc.price_linen)
    f.price_rare           = tostring(calc.price_rare)
    f.price_water          = tostring(calc.price_water)
    f.auto_jump_interval   = tostring(autoJumpInterval)
    f.auto_eat_food        = tostring(autoEatFood)
    f.auto_eat_min_satiety = tostring(autoEatMinSatiety)
    ini.telegram.enabled = b2s(tg.enabled)
    ini.telegram.chat_id = tostring(tg.chat_id)
    ini.telegram.logs    = b2s(tg.logs)
    if not ini.ui then ini.ui = {} end
    ini.ui.hide_fab = b2s(fabHidden)
    if not ini.stats then ini.stats = {} end
    ini.stats.cotton      = tostring(farm.res_counter.cotton)
    ini.stats.linen       = tostring(farm.res_counter.linen)
    ini.stats.rare        = tostring(farm.res_counter.rare)
    ini.stats.water       = tostring(farm.res_counter.water)
    ini.stats.bot_seconds = tostring(botTotalSeconds)
    if not ini.cfg then ini.cfg = {} end
    ini.cfg.license_key       = tostring(licenseKey or '')
    ini.cfg.bot_timer_minutes = tostring(botTimerMinutes or 0)
    inicfg.save(ini, 'strand_ferma.ini')
end

local function fmtNum(n)
    local s=string.format('%.0f',math.floor(n or 0))
    local r,l='',#s
    for i=1,l do
        r=r..s:sub(i,i)
        local rem=l-i
        if rem>0 and rem%3==0 then r=r..'.' end
    end
    return r
end

local function addLog(text)
    local clean=tostring(text):gsub('{.-}','')
    local entry='['..os.date('%H:%M:%S')..'] '..clean
    table.insert(log_lines,1,entry)
    if #log_lines>60 then table.remove(log_lines) end
end

local function urlEncode(s)
    local safe = { ['-']=true, ['_']=true, ['.']=true, ['~']=true }
    return (s:gsub('([^%w%-_%.~])', function(c)
        return string.format('%%%02X', string.byte(c))
    end))
end

local tgQueue = {}
local tgQueueReady = false

local function sendTG(text)
    if not tg.enabled or tg.token=='' or tg.chat_id=='' then return end
    table.insert(tgQueue, tostring(text))
end

local function sendTGSync(text)
    if not tg.enabled or tg.token=='' or tg.chat_id=='' then return end
    table.insert(tgQueue, tostring(text))
end

local function startTGWorker()
    lua_thread.create(function()
        tgQueueReady = true
        while true do
            if #tgQueue > 0 then
                local text   = table.remove(tgQueue, 1)
                local chatId = tostring(tg.chat_id):match('^%s*(.-)%s*$')
                if tg.enabled and chatId ~= '' then
                    local msgText = text
                    local msgChat = chatId
                    lua_thread.create(function()
                        pcall(requests.get,
                            'https://api.telegram.org/bot'..TG_BOT_TOKEN
                            ..'/sendMessage?chat_id='..urlEncode(msgChat)
                            ..'&text='..urlEncode(msgText))
                    end)
                end
                wait(150)
            else
                wait(300)
            end
        end
    end)
end

local function sendStatsReport(reason)
    if not tg.enabled or tg.chat_id=='' then return end
    local rc=farm.res_counter
    local el=getBotElapsed()
    local pc=rc.cotton*calc.price_cotton
    local pl=rc.linen *calc.price_linen
    local pr=rc.rare  *calc.price_rare
    local pw3=rc.water*calc.price_water
    local msg = u8(string.format(
        '[StrandFerma] %s\n\xd0\xe0\xe1\xee\xf2\xe0 \xe1\xee\xf2\xe0: %02d:%02d:%02d\n\xd5\xeb\xee\xef\xee\xea: %d (%.0f$)\n\xcb\xb8\xed: %d (%.0f$)\n\xd2\xea\xe0\xed\xfc: %d (%.0f$)\n\xc2\xee\xe4\xe0: %d (%.0f$)\n\xc8\xd2\xce\xc3\xce: %.0f$',
        reason,
        math.floor(el/3600),math.floor((el%3600)/60),el%60,
        rc.cotton,pc, rc.linen,pl, rc.rare,pr, rc.water,pw3, pc+pl+pr+pw3))
    sendTG(msg)
end

local function emergencyStop()
    if botSessionStart > 0 then
        botTotalSeconds = botTotalSeconds + (os.time() - botSessionStart)
        botSessionStart = 0
    end
    farm.running=false; farm.target=nil; movement.active=false
    sprintActive=false
    setGameKeyState(1,0); setGameKeyState(16,0); setGameKeyState(14,0)
    addLog('[Система] Аварийная остановка.')
    saveCfg()
end

local function quitGame()
    os.execute('am force-stop com.arizona21.game.web')
end

local function sendAlt()
    local bs=raknetNewBitStream()
    raknetBitStreamWriteInt8(bs,220);raknetBitStreamWriteInt8(bs,63)
    raknetBitStreamWriteInt8(bs,8);  raknetBitStreamWriteInt32(bs,7)
    raknetBitStreamWriteInt32(bs,-1);raknetBitStreamWriteInt32(bs,0)
    raknetBitStreamWriteString(bs,'')
    raknetSendBitStreamEx(bs,1,7,1);raknetDeleteBitStream(bs)
end

local function doHarvest() sendAlt(); wait(800); sendAlt() end

local function noPlayers(x, y, z, r, charList)
    r = r or 3
    local chars = charList
    if not chars then
        local ok, c = pcall(getAllChars)
        if not ok or not c then return true end
        chars = c
    end
    for _, ped in ipairs(chars) do
        if ped ~= PLAYER_PED then
            local ok2, _ = pcall(sampGetPlayerIdByCharHandle, ped)
            if ok2 then
                local ok3, px, py, pz = pcall(getCharCoordinates, ped)
                if ok3 and px then
                    if getDistanceBetweenCoords3d(px, py, pz, x, y, z) < r then
                        return false
                    end
                end
            end
        end
    end
    return true
end

local function findBestBush()
    local mx, my = getCharCoordinates(PLAYER_PED)
    local _, charList = pcall(getAllChars)

    local best_free4,  bd_free4  = nil, 200
    local best_free13, bd_free13 = nil, 200
    local best_busy4,  bd_busy4  = nil, 200

    for id = 0, 2048 do
        if id > 0 and id % 256 == 0 then wait(0) end
        if sampIs3dTextDefined(id) then
            local ok, txt, _, x, y, z = pcall(sampGet3dTextInfoById, id)
            if ok and txt then
                if txt:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') then
                    local wC = farm.collect_cotton and txt:find('\xd5\xeb\xee\xef\xee\xea')
                    local wL = farm.collect_linen  and txt:find('\xb8\xed')
                    if wC or wL then
                        local qty = tonumber(txt:match('%((%d+)%s*\xe8\xe7'))
                                 or tonumber(txt:match('(%d+)')) or 0
                        if qty >= 1 then
                            local d = getDistanceBetweenCoords2d(mx, my, x, y)
                            local free = noPlayers(x, y, z, 3, charList)
                            if free then
                                if qty >= 4 then
                                    if d < bd_free4  then bd_free4  = d; best_free4  = {x,y,z} end
                                else
                                    if d < bd_free13 then bd_free13 = d; best_free13 = {x,y,z} end
                                end
                            else
                                if qty >= 4 then
                                    if d < bd_busy4  then bd_busy4  = d; best_busy4  = {x,y,z} end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return best_free4 or best_free13 or best_busy4
end

local function findAllBushes()
    local mx, my = getCharCoordinates(PLAYER_PED)
    local bushes = {}
    for id = 0, 2048 do
        if id > 0 and id % 256 == 0 then wait(0) end
        if sampIs3dTextDefined(id) then
            local ok, txt, _, x, y, z = pcall(sampGet3dTextInfoById, id)
            if ok and txt then
                local wC = farm.collect_cotton and txt:find('\xd5\xeb\xee\xef\xee\xea')
                local wL = farm.collect_linen  and txt:find('\xb8\xed')
                if wC or wL then
                    local d = getDistanceBetweenCoords2d(mx, my, x, y)
                    local qty = tonumber(txt:match('%((%d+)%s*\xe8\xe7'))
                             or tonumber(txt:match('(%d+)')) or 0
                    local ripe = txt:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') and qty >= 1
                    table.insert(bushes, {x=x, y=y, z=z, d=d, ripe=ripe})
                end
            end
        end
    end
    table.sort(bushes, function(a,b) return a.d < b.d end)
    return bushes
end

-- Плавный поворот камеры (lerp, как в NexaArizona)
-- Вместо мгновенного snap — плавная интерполяция угла, убирает резкие развороты
local _smoothCamAngle = 0

-- Обход препятствий: боковой стик при наличии стены/забора впереди
-- Источник идеи: NexaArizona calculateObstacleTurn
local function calculateObstacleTurn()
    local ok, cx, cy, cz = pcall(getCharCoordinates, PLAYER_PED)
    if not ok or not cx then return 0 end
    local headRad = math.rad(getCharHeading(PLAYER_PED)) + math.pi / 2
    local probeDist = 4.5
    local angles = { 0, math.rad(35), math.rad(-35), math.rad(65), math.rad(-65) }
    for _, zOff in ipairs({ 0.4, 1.1 }) do
        for _, da in ipairs(angles) do
            local a = headRad + da
            local hit = processLineOfSight(
                cx, cy, cz + zOff,
                cx + probeDist * math.cos(a),
                cy + probeDist * math.sin(a),
                cz + zOff,
                true, false, false, true, true, false, false, false)
            if hit then
                if da > 0 then return -255
                elseif da < 0 then return 255
                else return (math.random() > 0.5) and 255 or -255
                end
            end
        end
    end
    return 0
end

-- Детектор ближней машины (предупреждение в лог/TG)
-- Источник идеи: NexaArizona getNearbyVehicle
local _vehCheckLast = 0
local function checkNearbyVehicle(radius)
    if (os.clock() - _vehCheckLast) < 6 then return end
    _vehCheckLast = os.clock()
    local okP, cx, cy, cz = pcall(getCharCoordinates, PLAYER_PED)
    if not okP or not cx then return end
    local okV, vehs = pcall(getAllVehicles)
    if not okV or not vehs then return end
    for _, v in ipairs(vehs) do
        if doesVehicleExist(v) then
            local okC, vx, vy, vz = pcall(getCarCoordinates, v)
            if okC and vx then
                local d = getDistanceBetweenCoords3d(cx, cy, cz, vx, vy, vz)
                if d > 0.5 and d <= (radius or 15) then
                    local model = getCarModel(v)
                    addLog(string.format('[\xcc\xe0\xf8\xe8\xed\xe0] \xf0\xff\xe4\xee\xec %d \xec (\xec\xee\xe4\xe5\xeb\xfc %d)', math.floor(d), model))
                    sendTG(string.format('[StrandFerma] \xcc\xe0\xf8\xe8\xed\xe0 \xf0\xff\xe4\xee\xec! \xc4: %.0f\xec, \xec\xee\xe4\xe5\xeb\xfc %d', d, model))
                    _vehCheckLast = os.clock() + 20  -- повторно не раньше чем через 26 сек (6+20)
                    return
                end
            end
        end
    end
end

local bushCache       = nil
local bushCacheTime   = 0
local BUSH_CACHE_TTL  = 0.3

local function findBestBushCached()
    if (os.clock() - bushCacheTime) < BUSH_CACHE_TTL then
        return bushCache
    end
    bushCache     = findBestBush()
    bushCacheTime = os.clock()
    return bushCache
end

local function invalidateBushCache()
    bushCacheTime = 0
end

local function runToPoint(tox,toy,toz)
    local lastX,lastY=getCharCoordinates(PLAYER_PED)
    local stuckSince=nil
    local sideDir=1
    local nearHarvestSaid=false
    -- Мягкая инициализация угла: берём текущий heading персонажа,
    -- чтобы камера не дёргалась при старте движения к новой цели.
    do
        local ok, ch = pcall(getCharHeading, PLAYER_PED)
        if ok and ch then
            local okP, ix, iy = pcall(getCharCoordinates, PLAYER_PED)
            if okP and ix then
                local targetAng = getHeadingFromVector2d(tox - ix, toy - iy)
                local diff = math.abs(((targetAng - _smoothCamAngle + 180) % 360) - 180)
                if diff > 90 then
                    _smoothCamAngle = ch
                end
            end
        end
    end

    while farm.running do
        local cx,cy=getCharCoordinates(PLAYER_PED)
        local dist=getDistanceBetweenCoords2d(cx,cy,tox,toy)

        -- Проверяем машины рядом раз в несколько секунд
        if farm.running and not is_patrolling then
            checkNearbyVehicle(14)
        end

        if dist<=2.0 then
            setGameKeyState(1,0)
            setGameKeyState(0,0)
            stopSprint()
            movement.active=false
            sprintActive=false
            if not nearHarvestSaid and farm.chat_on_players and not is_patrolling then
                nearHarvestSaid=true
                lua_thread.create(function()
                    wait(150)
                    local bushX, bushY, bushZ = tox, toy, toz
                    local playersNearby = false
                    local ok2, chars2 = pcall(getAllChars)
                    if ok2 and chars2 then
                        for _, ped in ipairs(chars2) do
                            if ped ~= PLAYER_PED then
                                local okP, _ = pcall(sampGetPlayerIdByCharHandle, ped)
                                if okP then
                                    local okC, px2, py2, pz2 = pcall(getCharCoordinates, ped)
                                    if okC and px2 then
                                        if getDistanceBetweenCoords3d(px2,py2,pz2,bushX,bushY,bushZ) < 6 then
                                            playersNearby = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if playersNearby then
                        local phrases = {
                            '\xd1\xdd\xc1\xc8\xd2\xc5 \xcd\xc0\xd5\xd3\xc9',
                            '\xc2\xe0\xf1 \xf2\xf3\xf2 \xea\xe0\xea \xec\xf3\xf5 \xed\xe0 \xe3\xee\xe2\xed\xe5',
                            '\xc4\xe0 \xe7\xe0\xe5\xe1\xe0\xeb\xe8 \xef\xee\xe9\xe4\xe8\xf2\xe5 \xee\xf2\xe4\xee\xf5\xed\xe8\xf2\xe5',
                            '\xcc\xe4\xfd \xe2\xe0\xf1 \xf2\xf3\xf2 \xea\xee\xed\xe5\xf7\xed\xee',
                            '\xcd\xf3 \xf7\xe5 \xec\xed\xe5 \xec\xe5\xf8\xe0\xe5\xf2\xe5?',
                            '\xc4\xe0 \xe8\xe4\xe8\xf2\xe5 \xf3\xe6\xe5 \xee\xf2\xf1\xfe\xe4\xe0',
                            '\xd2\xf3\xf2 \xec\xee\xe8 \xea\xf3\xf1\xf2\xfb, \xf1\xe2\xee\xe8 \xed\xe0\xe9\xe4\xe8\xf2\xe5',
                            '\xc7\xe0\xed\xff\xf2\xee, \xed\xe5 \xe2\xe8\xe4\xe8\xf2\xe5?',
                            '\xd0\xe0\xe1\xee\xf2\xe0\xe5\xec \xeb\xfe\xe4\xe8, \xed\xe5 \xec\xe5\xf8\xe0\xe9\xf2\xe5',
                            '\xc7\xe0\xf7\xe5\xec \xef\xf0\xe8\xf8\xeb\xe8, \xf1\xe2\xee\xe1\xee\xe4\xed\xfb\xf5 \xec\xe5\xf1\xf2 \xed\xe5\xf2',
                            '\xd5\xeb\xee\xef\xee\xea \xf1\xe0\xec \xf1\xe5\xe1\xff \xed\xe5 \xf1\xe1\xe5\xf0\xb8\xf2',
                            '\xd3 \xec\xe5\xed\xff \xf2\xf3\xf2 \xe1\xf0\xee\xed\xfc',
                            '\xcd\xe5 \xf2\xf0\xee\xe3\xe0\xe9\xf2\xe5 \xec\xee\xe9 \xe1\xe8\xe7\xed\xe5\xf1',
                            '\xdf \xe7\xe4\xe5\xf1\xfc \xf3\xe6\xe5 \xf0\xe0\xe1\xee\xf2\xe0\xfe, \xed\xe0\xe9\xe4\xe8\xf2\xe5 \xe4\xf0\xf3\xe3\xee\xe9',
                            '\xd5\xe2\xe0\xf2\xe8\xf2 \xf1\xf2\xf0\xe5\xec\xe8\xf2\xfc\xf1\xff \xed\xe0 \xf7\xf3\xe6\xee\xe5',
                            '\xdd\xf2\xee \xec\xee\xe9 \xea\xf3\xf1\xf2, \xed\xe0\xe9\xe4\xe8 \xf1\xe2\xee\xe9',
                            '\xc7\xe0\xed\xff\xf2\xee, \xe8\xe4\xe8 \xec\xe8\xec\xee',
                            '\xca\xee\xed\xea\xf3\xf0\xe5\xed\xf2\xfb \xef\xf0\xe8\xf8\xeb\xe8',
                            '\xc2\xfb \xec\xe5\xf8\xe0\xe5\xf2\xe5 \xf0\xe0\xe1\xee\xf2\xe0\xf2\xfc',
                            '\xd1\xe2\xee\xe8\xf5 \xea\xf3\xf1\xf2\xee\xe2 \xed\xe5\xf2?',
                            '\xcc\xe5\xf1\xf2\xee \xe7\xe0\xed\xff\xf2\xee',
                            '\xc8\xe4\xe8 \xee\xf2\xf1\xfe\xe4\xe0 \xf3\xe6\xe5',
                            '\xd2\xf3\xf2 \xf3\xe6\xe5 \xf0\xe0\xe1\xee\xf2\xe0\xfe\xf2',
                            '\xcd\xe5 \xec\xe5\xf8\xe0\xe9, \xe8\xe4\xe8 \xe4\xe0\xeb\xfc\xf8\xe5',
                            '\xdf \xf2\xf3\xf2 \xe4\xe0\xe2\xed\xee \xf1\xf2\xee\xfe',
                            '\xd1\xe2\xee\xe9 \xea\xf3\xf1\xf2 \xed\xe0\xe9\xe4\xe8',
                            '\xcd\xe5 \xe2\xe8\xe4\xe8\xf8\xfc \xf7\xf2\xee \xe7\xe0\xed\xff\xf2\xee?',
                            '\xcb\xe0\xe4\xed\xee \xff \xef\xee\xe9\xe4\xf3 \xe4\xf0\xf3\xe3\xee\xe9',
                            '\xd7\xf3\xe6\xee\xe5 \xed\xe5 \xf2\xf0\xee\xe3\xe0\xe9',
                            '\xcc\xe5\xf1\xf2\xee \xec\xee\xb8',
                            '\xce\xf2\xee\xe9\xe4\xe8 \xee\xf2 \xea\xf3\xf1\xf2\xe0',
                            '\xd1\xe0\xec \xf1\xe1\xee\xf0\xf9\xe8\xea \xed\xe0\xf8\xe5\xeb\xf1\xff',
                            '\xd1\xe2\xee\xb8 \xe8\xe4\xe8 \xe8\xf9\xe8',
                            '\xc2\xe0\xeb\xe8 \xee\xf2\xf1\xfe\xe4\xe0',
                            '\xd2\xf3\xf2 \xe7\xe0\xed\xff\xf2\xee \xe4\xe0\xe2\xed\xee',
                            '\xca\xf3\xf1\xf2 \xec\xee\xe9 \xed\xe0\xf8\xe5\xeb \xf3\xe6\xe5',
                            '\xd7\xe5\xe3\xee \xef\xf0\xe8\xef\xb8\xf0\xf1\xff',
                            '\xd2\xf3\xf2 \xf3\xe6\xe5 \xf1\xf2\xee\xff\xf2',
                            '\xcc\xe5\xf1\xf2\xee \xf7\xf3\xe6\xee\xe5',
                            '\xc2\xe0\xeb\xe8 \xed\xe0 \xf1\xe2\xee\xe9',
                            '\xcd\xe5\xf2 \xf2\xf3\xf2 \xec\xe5\xf1\xf2\xe0 \xe4\xeb\xff \xf2\xe5\xe1\xff',
                            '\xcf\xf0\xee\xf5\xee\xe4\xe8 \xec\xe8\xec\xee',
                            '\xc4\xe0\xe2\xed\xee \xf2\xf3\xf2 \xf1\xf2\xee\xfe',
                            '\xd1\xe2\xee\xe8\xf5 \xed\xe5\xf2 \xf7\xf2\xee \xeb\xe8',
                        }
                        math.randomseed(os.time() * 1000 + math.random(99999))
                        local idx = math.random(1, #phrases)
                        sampSendChat(phrases[idx])
                    end
                end)
            end
            return true
        end

        local toAng = getHeadingFromVector2d(tox-cx, toy-cy)

        -- Плавный поворот камеры без рывков
        local lerpK = dist < 8 and 0.07 or 0.04
        local angleDiff = ((toAng - _smoothCamAngle + 180) % 360) - 180
        _smoothCamAngle = (_smoothCamAngle + angleDiff * lerpK + 360) % 360
        pcall(setCameraPositionUnfixed, 0, math.rad(_smoothCamAngle - 90))

        sprintActive = farm.sprint and (dist > 3.0)
        setGameKeyState(1, -255)

        -- Боковой обход препятствий (заборы, стены)
        local obstTurn = calculateObstacleTurn()
        if obstTurn ~= 0 then
            setGameKeyState(0, obstTurn)
        else
            setGameKeyState(0, 0)
        end

        if autoJump and dist > 5.0 then
            doJumpToTarget(tox, toy)
        end

        if getDistanceBetweenCoords2d(cx,cy,lastX,lastY)>=0.15 then
            lastX,lastY=cx,cy; stuckSince=nil
        elseif stuckSince==nil then
            stuckSince=os.clock()
        elseif (os.clock()-stuckSince)>2.2 then
            -- При застревании: плавно разворачиваем + боковой маневр
            local sa = toAng + sideDir * 85
            _smoothCamAngle = (_smoothCamAngle + (((sa - _smoothCamAngle + 180) % 360) - 180) * 0.4 + 360) % 360
            setGameKeyState(1,-255)
            setGameKeyState(0, sideDir * 180)
            local sw=0; while farm.running and sw<300 do wait(1);sw=sw+1 end
            setGameKeyState(14,255); wait(90); setGameKeyState(14,0)
            setGameKeyState(0, 0)
            sideDir=-sideDir
            lastX,lastY=getCharCoordinates(PLAYER_PED); stuckSince=nil
        end

        wait(1)
    end
    setGameKeyState(1,0)
    setGameKeyState(0,0)
    stopSprint()
    sprintActive=false
    movement.active=false
    return false
end

local watchdogLastTarget=0
local function botWatchdog()
    while true do
        wait(1000)
        if farm.running then
            if farm.target ~= nil then
                watchdogLastTarget = os.clock()
            else
                if (os.clock()-watchdogLastTarget) > 8 then
                    setGameKeyState(1,0)
                    stopSprint()
                    sprintActive=false
                    movement.active=false
                end
            end
        else
            watchdogLastTarget = os.clock()
        end
    end
end


local function toARGB(r, g, b, a)
    return math.floor(a*255+.5)*0x1000000
         + math.floor(r*255+.5)*0x10000
         + math.floor(g*255+.5)*0x100
         + math.floor(b*255+.5)
end

local TR_LINE  = toARGB(1.000, 0.302, 0.302, 0.92)
local TR_GLOW  = toARGB(0.545, 0.176, 0.176, 0.30)
local TR_CIRC1 = toARGB(1.000, 0.302, 0.302, 0.88)
local TR_CIRC2 = toARGB(0.545, 0.176, 0.176, 0.40)

local function drawTracerCircle(cx, cy, cz, r, col, seg)
    seg = seg or 32
    local px, py
    for i = 0, seg do
        local a  = i / seg * 2 * math.pi
        local wx = cx + r * math.cos(a)
        local wy = cy + r * math.sin(a)
        if isPointOnScreen(wx, wy, cz, r+2) then
            local sx, sy = convert3DCoordsToScreen(wx, wy, cz)
            if sx and sy and px and py then
                renderDrawLine(px, py, sx, sy, 2, col)
            end
            px, py = sx, sy
        else
            px, py = nil, nil
        end
    end
end

local function renderLoop()
    while true do
        if farm.running and farm.target then
            local tx, ty, tz = farm.target[1], farm.target[2], farm.target[3]
            local ok, ox, oy, oz = pcall(getCharCoordinates, PLAYER_PED)
            if ok and ox then
                local ok1, sx1, sy1 = pcall(convert3DCoordsToScreen, ox, oy, oz)
                local ok2, sx2, sy2 = pcall(convert3DCoordsToScreen, tx, ty, tz)
                if ok1 and ok2 and sx1 and sy1 and sx2 and sy2 then
                    renderDrawLine(sx1, sy1, sx2, sy2, 5, TR_GLOW)
                    renderDrawLine(sx1, sy1, sx2, sy2, 2, TR_LINE)
                end
                if isPointOnScreen(tx, ty, tz, 2) then
                    local ok3, bsx, bsy = pcall(convert3DCoordsToScreen, tx, ty, tz)
                    if ok3 and bsx and bsy then
                        renderDrawLine(bsx-4, bsy, bsx+4, bsy, 3, 0xFFFFFFFF)
                        renderDrawLine(bsx, bsy-4, bsx, bsy+4, 3, 0xFFFFFFFF)
                    end
                end
            end
        end
        wait(33)
    end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    if id == 8252 and style == 0 then return end
    if title and title:find('\xd2\xee\xf0\xe3\xee\xe2\xeb\xff') then return end

    -- AutoEat: перехват диалога сытости
    if title and (title:find('\xd1\xfb\xf2\xee\xf1\xf2\xfc') or (text and (text:find('\xf1\xfb\xf2\xee\xf1\xf2\xfc') or text:find('\xd1\xfb\xf2\xee\xf1\xf2\xfc')))) then
        local val = (text or ''):match('\xf1\xfb\xf2\xee\xf1\xf2\xfc%s*:%s*(%d+%.?%d*)')
                 or (text or ''):match('(%d+%.%d+)%s*/')
                 or (text or ''):match('(%d+)%s*/')
        if val then autoEatSatiety = tonumber(val) end
        autoEatWaitSat = false
        lua_thread.create(function() wait(100); sampSendDialogResponse(id, 1, -1, '') end)
        return false
    end

    -- AutoEat: перехват диалога еды (Кушать) — всегда закрываем
    if title and (title:find('\xca\xf3\xf8\xe0\xf2\xfc') or title:find('\xca\xf3\xf8')) then
        autoEatWaitEat = false
        -- кулдаун 10 сек — не спамим едой при повторном открытии диалога
        if autoEat and (os.clock() - autoEatLastEat) > 10 then
            autoEatLastEat = os.clock()
            local row = autoEatFood
            lua_thread.create(function()
                wait(150)
                sampSendDialogResponse(id, 1, row, '')
                -- ESC чтобы гарантированно закрыть диалог
                wait(300)
                setGameKeyState(23, 255)
                wait(100)
                setGameKeyState(23, 0)
                wait(400)
                if sampIsDialogActive() then
                    sampSendDialogResponse(id, 0, -1, '')
                end
            end)
        else
            -- либо autoEat выключен, либо кулдаун — просто ESC
            lua_thread.create(function()
                wait(150)
                setGameKeyState(23, 255)
                wait(100)
                setGameKeyState(23, 0)
            end)
        end
        return false
    end

    if farm.stop_on_dialog and farm.running then
        if (os.clock() - antiAdminEnableTime) < 5.0 then return end
        emergencyStop()
        addLog('[Защита] Стоп: диалог от сервера (id='..tostring(id)..')')
        sendTG('[StrandFerma] Стоп: диалог сервера (возможен admin), id='..tostring(id))
        playAlertSound()
        if farm.quit_on_stop then quitGame() end
    end
    if aaState then
        lua_thread.create(function()
            aaNonrp = text and text:match('/b')
            wait(3000)
            sampSendDialogResponse(id, 1, 0, '')
        end)
    end
end

function sampev.onSetPlayerPos(position)
    if farm.stop_on_tp and farm.running then
        if (os.clock() - antiAdminEnableTime) < 5.0 then return end
        local tpDist = 0
        pcall(function()
            local cx, cy, cz = getCharCoordinates(PLAYER_PED)
            local nx, ny, nz
            if type(position) == 'table' then
                nx = tonumber(position.x); ny = tonumber(position.y); nz = tonumber(position.z)
            end
            if cx and nx then
                tpDist = getDistanceBetweenCoords3d(cx, cy, cz, nx, ny, nz)
            end
        end)
        if tpDist < 15.0 then return end
        emergencyStop(); addLog('[Защита] Стоп: телепорт сервера ('..string.format('%.1f', tpDist)..'м)')
        sendTG('[StrandFerma] Стоп: телепорт от сервера ('..string.format('%.1f', tpDist)..'м)')
        playAlertSound()
        if farm.quit_on_stop then quitGame() end
    end
end

function sampev.onServerMessage(color,txt)
    if not txt then return end

    lua_thread.create(function()
        if farm.running then
            if txt:find('\xca\xf3\xf1\xee\xea') and txt:find('\xf2\xea\xe0\xed\xe8') then
                local amt = txt:match('%((%d+)\xf8\xf2%)')
                         or txt:match('[xX%*]%s*(%d+)%s*$')
                         or txt:match('%s(%d+)%s*$')
                         or 1
                farm.res_counter.rare = farm.res_counter.rare + (tonumber(amt) or 1)
                addLog('[Ткань] +'..(tonumber(amt) or 1))
            end
            if txt:find('item1692') then
                local amt2=txt:match('item1692[^%d]*(%d+)')
                if amt2 then
                    farm.res_counter.rare=farm.res_counter.rare+(tonumber(amt2) or 1)
                end
            end

            if txt:find('\xc2\xee\xe4\xe0 \xe4\xeb\xff \xeb\xe8\xf7\xed\xfb\xf5 \xe3\xf0\xff\xe4\xee\xea') then
                local amt3 = txt:match('%((%d+)\xf8\xf2%)')
                          or txt:match('[xX%*]%s*(%d+)%s*$')
                          or txt:match('%s(%d+)%s*$')
                          or 1
                farm.res_counter.water = farm.res_counter.water + (tonumber(amt3) or 1)
                addLog('[Вода] +'..(tonumber(amt3) or 1))
            end
        end

        if farm.stop_on_chat and farm.running then
            if (os.clock() - antiAdminEnableTime) >= 5.0 then
                if txt:find('\xc2\xfb \xf2\xf3\xf2') or txt:find('\xc2\xfb \xe7\xe4\xe5\xf1\xfc')
                or txt:find('\xe2\xfb \xf2\xf3\xf2') or txt:find('\xe2\xfb \xe7\xe4\xe5\xf1\xfc') then
                    emergencyStop(); addLog('[Защита] Стоп: проверка в чате')
                    sendTG('[StrandFerma] ОПАСНОСТЬ: подозрение на проверку! Бот остановлен.')
                    playAlertSound()
                    if farm.quit_on_stop then quitGame() end
                end
            end
        end
        if txt:find('\xe3\xee\xe2\xee\xf0\xe8\xf2') and tg.enabled then
            local now = os.time()
            if now - tgNearbyCooldown >= 180 then
                tgNearbyCooldown = now
                sendTG('[StrandFerma] \xc2\xed\xe8\xec\xe0\xed\xe8\xe5: \xea\xf2\xee-\xf2\xee \xe3\xee\xe2\xee\xf0\xe8\xf2 \xf0\xff\xe4\xee\xec!')
                addLog('[Защита] Голос рядом - уведомление в ТГ')
            end
        end
        if tg.enabled and (txt:find('/check') or txt:find('\xef\xf0\xee\xe2\xe5\xf0\xea\xe0')) then
            sendTG('[StrandFerma] ADMIN: возможная проверка /check!')
            addLog('[Защита] Возможный /check - уведомлен ТГ')
        end
        if aaState and aaIsAdmin(txt) then
            lua_thread.create(function() aaSendReply(false) end)
        end
    end)
end

function sampev.onDisplayGameText(style,time,text)
    if not text then return end
    local l = text:match('linen%+%s*(%d+)') or text:match('linen%s*%+(%d+)')
    local c = text:match('cotton%+%s*(%d+)') or text:match('cotton%s*%+(%d+)')
    if l then farm.res_counter.linen  = farm.res_counter.linen  + tonumber(l) end
    if c then farm.res_counter.cotton = farm.res_counter.cotton + tonumber(c) end
end

local function buildExitMsg(reason)
    local rc=farm.res_counter
    local el=getBotElapsed()
    local pc=rc.cotton*calc.price_cotton
    local pl=rc.linen *calc.price_linen
    local pr=rc.rare  *calc.price_rare
    local pw4=rc.water*calc.price_water
    return u8(string.format(
        '[StrandFerma] %s\n\xd0\xe0\xe1\xee\xf2\xe0 \xe1\xee\xf2\xe0: %02d:%02d:%02d\n\xd5\xeb\xee\xef\xee\xea: %d (%.0f$)\n\xcb\xb8\xed: %d (%.0f$)\n\xd2\xea\xe0\xed\xfc: %d (%.0f$)\n\xc2\xee\xe4\xe0: %d (%.0f$)\n\xc8\xd2\xce\xc3\xce: %.0f$',
        reason,
        math.floor(el/3600),math.floor((el%3600)/60),el%60,
        rc.cotton,pc, rc.linen,pl, rc.rare,pr, rc.water,pw4, pc+pl+pr+pw4))
end

function sampev.onConnectionClosed()
    sendTGSync(buildExitMsg('\xd0\xe0\xe7\xf0\xfb\xe2 \xf1\xee\xe5\xe4\xe8\xed\xe5\xed\xe8\xff'))
    emergencyStop()
end

function sampev.onQuit()
    sendTGSync(buildExitMsg('\xd5\xf1\xf2\xf0\xee\xe9\xf1\xf2\xe2\xee: \xe2\xfb\xf5\xee\xe4 \xe8\xe7 \xe8\xe3\xf0\xfb'))
    emergencyStop()
end


local function pF(f)    if f then imgui.PushFont(f); return true end return false end
local function pFpop(p) if p then imgui.PopFont() end end

local function u32(c, a)
    local cc = imgui.ImVec4(c.x, c.y, c.z, a ~= nil and a or c.w)
    return imgui.ColorConvertFloat4ToU32(cc)
end

local function dlBtn(DL, x, y, w, h, bg, hov, label, lc, rnd)
    rnd = rnd or 8*MDS
    local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y
    local over = mx >= x and mx <= x+w and my >= y and my <= y+h
    local hit  = over and imgui.IsMouseClicked(0)
    DL:AddRectFilled(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(over and hov or bg), rnd)
    if over then
        DL:AddRect(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
            u32(lc, 0.35), rnd, 0, 1.2)
    end
    local ts = imgui.CalcTextSize(label)
    DL:AddText(imgui.ImVec2(x+(w-ts.x)*0.5, y+(h-ts.y)*0.5), u32(lc), label)
    return hit
end

local function toggleRow(DL, x, y, w, label, val)
    local th = 22*MDS; local tw = 44*MDS
    local tx = x + w - tw; local ty = y + 2*MDS
    local mx, my = imgui.GetMousePos().x, imgui.GetMousePos().y
    local over = mx >= tx and mx <= tx+tw and my >= ty and my <= ty+th
    local clicked = over and imgui.IsMouseClicked(0)
    if clicked then val = not val end

    local t   = val and 1.0 or 0.0
    local on  = CLR.accent
    local off = imgui.ImVec4(0.15, 0.15, 0.15, 1)
    local bg  = imgui.ImVec4(off.x+(on.x-off.x)*t, off.y+(on.y-off.y)*t, off.z+(on.z-off.z)*t, 1)
    local r   = th * 0.5
    DL:AddRectFilled(imgui.ImVec2(tx,ty), imgui.ImVec2(tx+tw,ty+th), u32(bg), r)
    DL:AddCircleFilled(imgui.ImVec2(tx+r+(tw-th)*t, ty+r), r-2.5*MDS, u32(imgui.ImVec4(1,1,1,0.96)))

    local ts = imgui.CalcTextSize(label)
    DL:AddText(imgui.ImVec2(x, y + (th - ts.y) * 0.5 + 2*MDS), u32(CLR.text), label)
    return val, clicked
end

local function drawStatCard(DL, x, y, w, h, topLabel, valStr, valColor)
    DL:AddRectFilled(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(imgui.ImVec4(0.08, 0.08, 0.08, 1)), 6*MDS)
    DL:AddRectFilled(imgui.ImVec2(x,y+5*MDS), imgui.ImVec2(x+2.5*MDS,y+h-5*MDS),
        u32(valColor or CLR.accent), 2*MDS)
    DL:AddRect(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(CLR.border), 6*MDS, 0, 1.0)
    local tl = imgui.CalcTextSize(topLabel)
    DL:AddText(imgui.ImVec2(x+10*MDS, y+5*MDS), u32(CLR.textDim), topLabel)
    local vl = imgui.CalcTextSize(valStr)
    DL:AddText(imgui.ImVec2(x+10*MDS, y+h-vl.y-5*MDS), u32(valColor or CLR.text), valStr)
end

local function sectionTitle(DL, x, y, w, label)
    local ts = imgui.CalcTextSize(label)
    DL:AddText(imgui.ImVec2(x, y), u32(CLR.accent), label)
    DL:AddLine(
        imgui.ImVec2(x + ts.x + 6*MDS, y + ts.y*0.5),
        imgui.ImVec2(x + w, y + ts.y*0.5),
        u32(CLR.border), 1)
end

local function rowBg(DL, x, y, w, h)
    DL:AddRectFilled(imgui.ImVec2(x,y), imgui.ImVec2(x+w,y+h),
        u32(imgui.ImVec4(1,1,1,0.04)), 4*MDS)
end


local WinMain   = imgui.new.bool(false)
local WinStats  = imgui.new.bool(false)
local WinFab    = imgui.new.bool(true)
local curPage   = 1

local tgChatBuf = imgui.new.char[64]('')
local calcCot   = imgui.new.float[1](0)
local calcLin   = imgui.new.float[1](0)
local calcRar   = imgui.new.float[1](0)
local calcWat   = imgui.new.float[1](0)
local timerBuf  = imgui.new.int[1](0)

local TAB_ICONS = {
    fa['HOUSE'],
    fa['WHEAT_AWN'],
    fa['SHIELD_HALVED'],
    fa['PAPER_PLANE'],
    fa['GEAR'],
}

imgui.OnFrame(
    function() return licWinOpen[0] end,
    function(self)
        self.HideCursor = false
        local W = 370 * MDS
        local H = 180 * MDS
        imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2((resx - W) * 0.5, (resy - H) * 0.5),
            imgui.Cond.Always)
        imgui.Begin(u8('##LicWinSF'), licWinOpen,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoResize    +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoMove)

        local DL = imgui.GetWindowDrawList()
        local WP = imgui.GetWindowPos()
        local pu32 = imgui.ColorConvertFloat4ToU32

        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H),
            pu32(imgui.ImVec4(0.059,0.059,0.059,0.99)),
            pu32(imgui.ImVec4(0.106,0.157,0.216,0.99)),
            pu32(imgui.ImVec4(0.086,0.102,0.129,0.99)),
            pu32(imgui.ImVec4(0.059,0.059,0.059,0.99)))
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+3*MDS), u32(CLR.accent))
        DL:AddRect(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H), u32(CLR.border), 12*MDS, 0, 1.2)

        local pm = pF(fMain)
        local pad = 14*MDS

        imgui.SetCursorPos(imgui.ImVec2(pad, 12*MDS))
        imgui.PushStyleColor(imgui.Col.Text, CLR.accent)
        imgui.Text(u8('\xca\xeb\xfe\xf7 \xeb\xe8\xf6\xe5\xed\xe7\xe8\xe8  StrandFerma'))
        imgui.PopStyleColor()

        imgui.SetCursorPos(imgui.ImVec2(pad, 32*MDS))
        imgui.PushStyleColor(imgui.Col.Text, CLR.textDim)
        imgui.Text(u8('\xcf\xee\xeb\xf3\xf7\xe8\xf2\xfc \xea\xeb\xfe\xf7: @victor_st0'))
        imgui.PopStyleColor()

        imgui.SetCursorPos(imgui.ImVec2(pad, 54*MDS))
        imgui.PushItemWidth(W - pad*2)
        imgui.InputText(u8('##sfkey'), licInputBuf, 64)
        imgui.PopItemWidth()

        if licenseMsg ~= '' then
            imgui.SetCursorPos(imgui.ImVec2(pad, 84*MDS))
            local mc = licenseChecking
                and imgui.ImVec4(0.90, 0.85, 0.25, 1.00)
                or  imgui.ImVec4(1.00, 0.35, 0.35, 1.00)
            imgui.PushStyleColor(imgui.Col.Text, mc)
            imgui.Text(licenseMsg)
            imgui.PopStyleColor()
        end

        local bY   = 112*MDS
        local bW1  = (W - pad*2 - 6*MDS) * 0.62
        local bW2  = W - pad*2 - bW1 - 6*MDS
        local bH   = 36*MDS
        local cpB  = imgui.ImVec2(WP.x+pad, WP.y+bY)

        if dlBtn(DL, cpB.x, cpB.y, bW1, bH,
            imgui.ImVec4(0.07,0.28,0.14,1), imgui.ImVec4(0.12,0.45,0.22,1),
            u8('\xc0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xf2\xfc'),
            imgui.ImVec4(0.70,1.00,0.76,1), 4*MDS) then
            local k = bufToStr(licInputBuf, 64):match('^%s*(.-)%s*$')
            if #k > 3 then
                checkLicenseAsync(k)
            else
                licenseMsg = u8('\xc2\xe2\xe5\xe4\xe8\xf2\xe5 \xea\xeb\xfe\xf7')
            end
        end
        if dlBtn(DL, cpB.x+bW1+6*MDS, cpB.y, bW2, bH,
            imgui.ImVec4(0.25,0.06,0.06,1), imgui.ImVec4(0.45,0.10,0.10,1),
            u8('\xc7\xe0\xea\xf0\xfb\xf2\xfc'),
            imgui.ImVec4(1.00,0.55,0.55,1), 4*MDS) then
            licWinOpen[0] = false
        end
        imgui.SetCursorPos(imgui.ImVec2(pad, bY+bH+2*MDS))
        imgui.Dummy(imgui.ImVec2(1, 1))

        pFpop(pm)
        imgui.End()
    end
)

imgui.OnFrame(
    function() return WinFab[0] and not fabHidden end,
    function(self)
        self.HideCursor = true

        local bw = 130*MDS
        local bh = 46*MDS
        local px = 28*MDS
        local py = resy * 0.72 - bh * 0.5

        imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(bw, bh), imgui.Cond.Always)
        local fl = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoMove
        imgui.Begin('##fab', WinFab, fl)

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local pm  = pF(fMain)
        local rnd = 8*MDS

        local isRun = farm.running
        local mx2, my2 = imgui.GetMousePos().x, imgui.GetMousePos().y
        local over = mx2 >= WP.x and mx2 <= WP.x+bw and my2 >= WP.y and my2 <= WP.y+bh

        DL:AddRectFilled(
            imgui.ImVec2(WP.x+2*MDS, WP.y+4*MDS),
            imgui.ImVec2(WP.x+bw+2*MDS, WP.y+bh+4*MDS),
            u32(imgui.ImVec4(0,0,0,0.55)), rnd)

        local baseBg = over and imgui.ImVec4(0.14,0.14,0.14,1) or imgui.ImVec4(0.07,0.07,0.07,1)
        DL:AddRectFilled(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+bw,WP.y+bh), u32(baseBg), rnd)

        if isRun then
            DL:AddRectFilledMultiColor(
                imgui.ImVec2(WP.x,    WP.y),
                imgui.ImVec2(WP.x+bw, WP.y+bh),
                u32(imgui.ImVec4(0.55,0.08,0.08, over and 0.90 or 0.70)),
                u32(imgui.ImVec4(0.15,0.05,0.05, over and 0.60 or 0.40)),
                u32(imgui.ImVec4(0.15,0.05,0.05, over and 0.60 or 0.40)),
                u32(imgui.ImVec4(0.55,0.08,0.08, over and 0.90 or 0.70)))
        else
            DL:AddRectFilledMultiColor(
                imgui.ImVec2(WP.x,    WP.y),
                imgui.ImVec2(WP.x+bw, WP.y+bh),
                u32(imgui.ImVec4(0.08,0.20,0.40, over and 0.90 or 0.70)),
                u32(imgui.ImVec4(0.30,0.08,0.08, over and 0.70 or 0.50)),
                u32(imgui.ImVec4(0.30,0.08,0.08, over and 0.70 or 0.50)),
                u32(imgui.ImVec4(0.08,0.20,0.40, over and 0.90 or 0.70)))
        end

        local brdC, txtC
        if isRun then
            brdC = over and imgui.ImVec4(1,0.30,0.30,0.90) or imgui.ImVec4(1,0.30,0.30,0.55)
            txtC = imgui.ImVec4(1,1,1,1)
        else
            brdC = over and imgui.ImVec4(0.40,0.65,1,0.80) or imgui.ImVec4(0.40,0.65,1,0.40)
            txtC = over and CLR.text or imgui.ImVec4(1,1,1,0.85)
        end
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+bw,WP.y+bh), u32(brdC), rnd, 0, 1.5)

        local icon = isRun and fa['STOP'] or fa['PLAY']
        local lbl  = isRun and (icon..' '..u8'\xd1\xd2\xce\xcf') or (icon..' '..u8'\xd1\xd2\xc0\xd0\xd2')
        local pB   = pF(fMain)
        local ts   = imgui.CalcTextSize(lbl)
        DL:AddText(imgui.ImVec2(WP.x+(bw-ts.x)*0.5, WP.y+(bh-ts.y)*0.5), u32(txtC), lbl)
        pFpop(pB)

        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##fabclick', imgui.ImVec2(bw, bh)) then
            if not licenseOK then
                licWinOpen[0] = true
            elseif isRun then
                emergencyStop()
                sampAddChatMessage('{44dd44}[StrandFerma]: {ff4444}\xd1\xd2\xce\xcf',-1)
                saveCfg()
            else
                farm.running=true
                botTimerStart   = os.time()
                botSessionStart = os.time()
                antiAdminEnableTime = os.clock()
                movement.active=false
                sprintActive=farm.sprint
                setGameKeyState(1,0); stopSprint()
                watchdogLastTarget=os.clock()
                sampAddChatMessage('{44dd44}[StrandFerma]: {44ff44}\xd1\xd2\xc0\xd0\xd2',-1)
            end
        end
        imgui.PopStyleColor(3)

        pFpop(pm)
        imgui.End()
    end
)

imgui.OnFrame(
    function() return WinMain[0] end,
    function(self)
        self.HideCursor = true

        local W = math.min(resx*0.88, 480*MDS)
        local H = math.min(resy*0.82, 510*MDS)

        imgui.SetNextWindowPos(imgui.ImVec2(resx*0.5, resy*0.5),
            imgui.Cond.FirstUseEver, imgui.ImVec2(0.5,0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(W,H), imgui.Cond.Always)

        local fl = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoBackground
        imgui.PushStyleColor(imgui.Col.WindowBg,    imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,       imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.BorderShadow, imgui.ImVec4(0,0,0,0))
        imgui.Begin('##na_main', WinMain, fl)

        local DL = imgui.GetWindowDrawList()
        local WP = imgui.GetWindowPos()
        _mainWinPos = WP
        local pm = pF(fMain)
        local WND_RND = 0

        local CORNERS_ALL    = 0xF
        local CORNERS_TOP    = 0x3
        local CORNERS_BOTTOM = 0xC

        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+W, WP.y+H),
            u32(imgui.ImVec4(0.059,0.059,0.059,0.98)))
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+W,WP.y+H),
            u32(CLR.border), 0, 0, 1.0)

        local hdrH = 48*MDS
        DL:AddRectFilled(
            imgui.ImVec2(WP.x, WP.y),
            imgui.ImVec2(WP.x+W, WP.y+hdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x,       WP.y),
            imgui.ImVec2(WP.x+W*0.5, WP.y+hdrH),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+W*0.5, WP.y),
            imgui.ImVec2(WP.x+W,     WP.y+hdrH),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.00)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.90)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.90)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.00)))
        DL:AddLine(
            imgui.ImVec2(WP.x, WP.y+hdrH),
            imgui.ImVec2(WP.x+W, WP.y+hdrH),
            u32(CLR.border), 1)

        local titleX = WP.x + 14*MDS
        local pB1 = pF(fBig)
        local strandS  = 'STRAND'
        local fermaS   = ' FERMA'
        local strandSz = imgui.CalcTextSize(strandS)
        local fermaSz  = imgui.CalcTextSize(fermaS)
        local titleY   = WP.y + hdrH*0.5 - strandSz.y*0.5
        DL:AddText(imgui.ImVec2(titleX, titleY),                u32(CLR.accent), strandS)
        DL:AddText(imgui.ImVec2(titleX+strandSz.x, titleY),     u32(CLR.text),   fermaS)
        pFpop(pB1)
        local verS  = ' | v2.7'
        local verSz = imgui.CalcTextSize(verS)
        DL:AddText(imgui.ImVec2(titleX+strandSz.x+fermaSz.x, WP.y+hdrH*0.5-verSz.y*0.5+1*MDS),
            u32(CLR.textDim), verS)

        local stTxt = farm.running and u8'\xd0\xc0\xc1\xce\xd2\xc0' or u8'\xce\xc6\xc8\xc4\xc0\xcd\xc8\xc5'
        local stCol = farm.running and CLR.green or CLR.textDim
        local stSz  = imgui.CalcTextSize(stTxt)

        local clSz = 26*MDS
        local clX  = WP.x + W - clSz - 14*MDS
        local clY2 = WP.y + (hdrH - clSz)*0.5
        local mx0, my0 = imgui.GetMousePos().x, imgui.GetMousePos().y
        local clHov = mx0>=clX and mx0<=clX+clSz and my0>=clY2 and my0<=clY2+clSz
        DL:AddRectFilled(imgui.ImVec2(clX,clY2), imgui.ImVec2(clX+clSz,clY2+clSz),
            u32(clHov and CLR.accent or imgui.ImVec4(1,1,1,0.10)), 4*MDS)
        local xS = imgui.CalcTextSize('x')
        DL:AddText(imgui.ImVec2(clX+(clSz-xS.x)*0.5, clY2+(clSz-xS.y)*0.5),
            u32(clHov and CLR.text or imgui.ImVec4(1,1,1,0.60)), 'x')
        if clHov and imgui.IsMouseClicked(0) then WinMain[0] = false end

        local stX   = clX - stSz.x - 18*MDS
        local stY   = WP.y + hdrH*0.5 - stSz.y*0.5
        DL:AddCircleFilled(imgui.ImVec2(stX-7*MDS, WP.y+hdrH*0.5), 3.5*MDS, u32(stCol))
        DL:AddText(imgui.ImVec2(stX, stY), u32(stCol), stTxt)

        local sticSz = 26*MDS
        local sticX  = stX - sticSz - 10*MDS
        local sticY  = WP.y + (hdrH - sticSz)*0.5
        local mxSt, mySt = imgui.GetMousePos().x, imgui.GetMousePos().y
        local sticHov = mxSt>=sticX and mxSt<=sticX+sticSz and mySt>=sticY and mySt<=sticY+sticSz
        DL:AddRectFilled(imgui.ImVec2(sticX,sticY), imgui.ImVec2(sticX+sticSz,sticY+sticSz),
            u32(WinStats[0] and CLR.accent or (sticHov and imgui.ImVec4(1,1,1,0.12) or imgui.ImVec4(1,1,1,0.06))), 4*MDS)
        local sticIc = fa['CHART_BAR']
        local sticIS = imgui.CalcTextSize(sticIc)
        DL:AddText(imgui.ImVec2(sticX+(sticSz-sticIS.x)*0.5, sticY+(sticSz-sticIS.y)*0.5),
            u32(WinStats[0] and imgui.ImVec4(0.05,0.05,0.05,1) or CLR.textDim), sticIc)
        if sticHov and imgui.IsMouseClicked(0) then WinStats[0] = not WinStats[0] end

        local tabsH  = 42*MDS
        local tabsY  = WP.y + hdrH
        DL:AddRectFilled(imgui.ImVec2(WP.x, tabsY), imgui.ImVec2(WP.x+W, tabsY+tabsH),
            u32(imgui.ImVec4(0,0,0,0.30)))
        DL:AddLine(imgui.ImVec2(WP.x, tabsY+tabsH), imgui.ImVec2(WP.x+W, tabsY+tabsH),
            u32(CLR.border), 1)

        local TAB_LABELS = {
            u8'\xc3\xcb\xc0\xc2\xcd\xc0\xdf',
            u8'\xd1\xc1\xce\xd0',
            u8'\xc7\xc0\xd9\xc8\xd2\xc0',
            u8'TELEGRAM',
            u8'\xce\xcf\xd6\xc8\xc8',
        }
        local tabPadX = 14*MDS
        local tabH2   = tabsH - 2*MDS
        local tabW = (W - tabPadX*2) / #TAB_LABELS
        for i, lbl in ipairs(TAB_LABELS) do
            local tx2 = WP.x + tabPadX + (i-1)*tabW
            local ty2 = tabsY + 2*MDS
            local isAT = (curPage == i)
            local mxT, myT = imgui.GetMousePos().x, imgui.GetMousePos().y
            local hovT = mxT>=tx2 and mxT<=tx2+tabW and myT>=ty2 and myT<=ty2+tabH2
            if isAT then
                DL:AddRectFilled(imgui.ImVec2(tx2+3*MDS, ty2), imgui.ImVec2(tx2+tabW-3*MDS, ty2+tabH2),
                    u32(imgui.ImVec4(1,1,1,1)), 4*MDS)
            elseif hovT then
                DL:AddRectFilled(imgui.ImVec2(tx2+3*MDS, ty2), imgui.ImVec2(tx2+tabW-3*MDS, ty2+tabH2),
                    u32(imgui.ImVec4(1,1,1,0.08)), 4*MDS)
            end
            local pSm = pF(fSmall)
            local tS3 = imgui.CalcTextSize(lbl)
            DL:AddText(
                imgui.ImVec2(tx2 + (tabW - tS3.x)*0.5, ty2 + (tabH2 - tS3.y)*0.5),
                u32(isAT and imgui.ImVec4(0.05,0.05,0.05,1) or (hovT and CLR.text or CLR.textDim)),
                lbl)
            pFpop(pSm)
            if hovT and imgui.IsMouseClicked(0) then curPage = i end
        end

        local bodyY  = tabsY + tabsH + 1
        local cntPad = 16*MDS
        local cntX   = WP.x + cntPad
        local cntY   = bodyY + 10*MDS
        local cntW   = W - cntPad*2

        if curPage == 1 then
            local cy = cntY

            local nick = ''
            pcall(function()
                local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                nick = sampGetPlayerNickname(pid) or ''
            end)
            local elapsed = getBotElapsed()
            local timeStr = string.format('%02d:%02d:%02d',
                math.floor(elapsed/3600), math.floor((elapsed%3600)/60), elapsed%60)

            local cg = 5*MDS; local ch = 46*MDS
            local cw = (cntW - cg*2) / 3
            drawStatCard(DL, cntX,          cy, cw, ch, u8'\xc8\xc3\xd0\xce\xca', nick~='' and nick or '-', CLR.accent)
            drawStatCard(DL, cntX+cw+cg,    cy, cw, ch, u8'\xd1\xd2\xc0\xd2\xd3\xd1',
                farm.running and u8'\xd0\xc0\xc1\xce\xd2\xc0' or u8'\xd1\xd2\xce\xc8\xd2',
                farm.running and CLR.green or CLR.textDim)
            drawStatCard(DL, cntX+cw*2+cg*2,cy, cw, ch, u8'\xc2\xd0\xc5\xcc\xdf', timeStr, imgui.ImVec4(0.88,0.96,0.56,1))
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, ch+6*MDS))
            cy = cy + ch + 8*MDS

            local rc  = farm.res_counter
            local cg2 = 5*MDS; local cw2 = (cntW-cg2)*0.5; local ch2 = 44*MDS
            drawStatCard(DL, cntX,        cy, cw2, ch2, u8'\xd5\xcb\xce\xcf', fmtNum(rc.cotton), imgui.ImVec4(0.95,0.88,0.55,1))
            drawStatCard(DL, cntX+cw2+cg2,cy, cw2, ch2, u8'\xcb\xb8\xcd',    fmtNum(rc.linen),  imgui.ImVec4(0.55,0.95,0.68,1))
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, ch2+5*MDS))
            cy = cy + ch2 + 7*MDS
            drawStatCard(DL, cntX,        cy, cw2, ch2, u8'\xd2\xca\xc0\xcd\xdc', fmtNum(rc.rare),  imgui.ImVec4(0.75,0.52,0.95,1))
            drawStatCard(DL, cntX+cw2+cg2,cy, cw2, ch2, u8'\xc2\xce\xc4\xc0',     fmtNum(rc.water), CLR.water)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, ch2+8*MDS))
            cy = cy + ch2 + 8*MDS

            -- ===== АВТО ЕДА: строка с тоглом и кнопкой настроек =====
            do
                local rh_ae = 34*MDS
                rowBg(DL, cntX, cy, cntW, rh_ae)

                -- тогл авто еды (тот же toggleRow что и у бега/прыжка)
                local curAe, chAe = toggleRow(DL, cntX+8*MDS, cy+(rh_ae-22*MDS)*0.5, cntW-8*MDS,
                    u8'\xc0\xe2\xf2\xee \xc5\xe4\xe0', autoEat)
                if chAe then
                    autoEat = curAe
                    saveCfg()
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

                -- кнопка ⚙ слева от тогла
                local toggleW_ae = 44*MDS
                local geSz       = 26*MDS
                local geX_ae     = cntX + cntW - 8*MDS - toggleW_ae - 6*MDS - geSz
                local geY_ae     = cy + (rh_ae - geSz)*0.5
                local mxG, myG   = imgui.GetMousePos().x, imgui.GetMousePos().y
                local geHov      = mxG >= geX_ae and mxG <= geX_ae+geSz and myG >= geY_ae and myG <= geY_ae+geSz
                DL:AddRectFilled(
                    imgui.ImVec2(geX_ae, geY_ae), imgui.ImVec2(geX_ae+geSz, geY_ae+geSz),
                    u32(autoEatSettingsOpen and CLR.accent or (geHov and imgui.ImVec4(1,1,1,0.12) or imgui.ImVec4(1,1,1,0.06))),
                    4*MDS)
                local geIc2  = fa['GEAR']
                local geIS2  = imgui.CalcTextSize(geIc2)
                DL:AddText(
                    imgui.ImVec2(geX_ae+(geSz-geIS2.x)*0.5, geY_ae+(geSz-geIS2.y)*0.5),
                    u32(autoEatSettingsOpen and imgui.ImVec4(0.05,0.05,0.05,1) or (geHov and CLR.text or CLR.textDim)),
                    geIc2)

                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.Dummy(imgui.ImVec2(cntW, rh_ae))
                -- невидимая кнопка поверх иконки шестерёнки
                imgui.SetCursorPos(imgui.ImVec2(geX_ae-WP.x, geY_ae-WP.y))
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
                if imgui.Button('##ae_gear', imgui.ImVec2(geSz, geSz)) then
                    autoEatSettingsOpen = not autoEatSettingsOpen
                end
                imgui.PopStyleColor(3)

                cy = cy + rh_ae + 6*MDS
            end
            -- ===== конец авто еды =====

            local fabLbl = fabHidden
                and (fa['EYE']..' '..u8'\xcf\xce\xca\xc0\xc7\xc0\xd2\xdc \xca\xcd\xce\xcf\xca\xd3')
                 or (fa['EYE_SLASH']..' '..u8'\xd1\xca\xd0\xdb\xd2\xdc \xca\xcd\xce\xcf\xca\xd3')
            if dlBtn(DL, cntX, cy, cntW, 28*MDS,
                imgui.ImVec4(0.08,0.08,0.08,1), imgui.ImVec4(0.14,0.14,0.14,1),
                fabLbl, CLR.textDim, 4*MDS) then
                fabHidden = not fabHidden; saveCfg()
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, 28*MDS))
            cy = cy + 28*MDS + 8*MDS

            local btnH = 38*MDS; local rnd_ = 6*MDS
            local tgW   = (cntW * 0.45 - 5*MDS) * 0.5
            local btnW  = cntW - tgW*2 - 10*MDS

            if pause_bot then
                if dlBtn(DL, cntX, cy, btnW, btnH, CLR.orange, CLR.orangeH,
                    fa['PAUSE']..' '..u8'\xd1\xcd\xdf\xd2\xdc \xcf\xc0\xd3\xc7\xd3', CLR.text, rnd_) then
                    pause_bot = false
                end
            else
                local mx_, my_ = imgui.GetMousePos().x, imgui.GetMousePos().y
                local over_ = mx_>=cntX and mx_<=cntX+btnW and my_>=cy and my_<=cy+btnH
                local bgBtn, bgHov, brdBtn, lblBtn, txtColBtn
                if farm.running then
                    bgBtn     = imgui.ImVec4(0.65,0.07,0.07,1)
                    bgHov     = imgui.ImVec4(0.85,0.12,0.12,1)
                    brdBtn    = imgui.ImVec4(1.00,0.30,0.30,0.75)
                    lblBtn    = fa['STOP']..' '..u8'\xd1\xd2\xce\xcf'
                    txtColBtn = imgui.ImVec4(1,1,1,1)
                else
                    bgBtn     = imgui.ImVec4(0.08,0.35,0.15,1)
                    bgHov     = imgui.ImVec4(0.12,0.50,0.22,1)
                    brdBtn    = imgui.ImVec4(0.20,0.82,0.40,0.55)
                    lblBtn    = fa['PLAY']..' '..u8'\xd1\xd2\xc0\xd0\xd2'
                    txtColBtn = imgui.ImVec4(0.85,1.00,0.88,1)
                end
                DL:AddRectFilled(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+btnW,cy+btnH),
                    u32(over_ and bgHov or bgBtn), rnd_)
                DL:AddRect(imgui.ImVec2(cntX,cy), imgui.ImVec2(cntX+btnW,cy+btnH),
                    u32(brdBtn), rnd_, 0, 1.2)
                local pBig = pF(fBig)
                local tsBtn = imgui.CalcTextSize(lblBtn)
                DL:AddText(imgui.ImVec2(cntX+(btnW-tsBtn.x)*0.5, cy+(btnH-tsBtn.y)*0.5),
                    u32(txtColBtn), lblBtn)
                pFpop(pBig)
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
                if imgui.Button('##mainbtn', imgui.ImVec2(btnW, btnH)) then
                    if not licenseOK then
                        licWinOpen[0] = true
                    elseif farm.running then
                        emergencyStop()
                        sampAddChatMessage('{44dd44}[StrandFerma]: {ff4444}\xd1\xd2\xce\xcf', -1)
                        saveCfg()
                    else
                        farm.running    = true
                        botTimerStart   = os.time()
                        botSessionStart = os.time()
                        antiAdminEnableTime = os.clock()
                        movement.active = false
                        sprintActive    = farm.sprint
                        setGameKeyState(1,0); stopSprint()
                        watchdogLastTarget = os.clock()
                        sampAddChatMessage('{44dd44}[StrandFerma]: {44ff44}\xd1\xd2\xc0\xd0\xd2', -1)
                    end
                end
                imgui.PopStyleColor(3)
            end

            local tgX1 = cntX + btnW + 5*MDS
            local tgX2 = tgX1 + tgW + 5*MDS
            if dlBtn(DL, tgX1, cy, tgW, btnH, CLR.tgBlue, CLR.tgH,
                fa['PAPER_PLANE'], CLR.text, rnd_) then
                openLink('https://t.me/strand_scripts')
            end
            local pSm2 = pF(fSmall)
            local chlbl = u8'\xca\xe0\xed\xe0\xeb'
            local chlS  = imgui.CalcTextSize(chlbl)
            DL:AddText(imgui.ImVec2(tgX1+(tgW-chlS.x)*0.5, cy+btnH+1*MDS), u32(CLR.textDim), chlbl)
            if dlBtn(DL, tgX2, cy, tgW, btnH,
                imgui.ImVec4(0.10,0.25,0.40,1), imgui.ImVec4(0.14,0.36,0.56,1),
                fa['USER'], CLR.text, rnd_) then
                openLink('https://t.me/victor_st0')
            end
            local aclbl = '@victor_st0'
            local aclS  = imgui.CalcTextSize(aclbl)
            DL:AddText(imgui.ImVec2(tgX2+(tgW-aclS.x)*0.5, cy+btnH+1*MDS), u32(CLR.textDim), aclbl)
            pFpop(pSm2)

            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, btnH+12*MDS))
            cy = cy + btnH + 14*MDS

            DL:AddLine(imgui.ImVec2(cntX, cy), imgui.ImVec2(cntX+cntW, cy), u32(CLR.border), 1)
            cy = cy + 7*MDS
            local authorLbl = u8'\xc0\xe2\xf2\xee\xf0: Victor Strand'
            local authorSz  = imgui.CalcTextSize(authorLbl)
            DL:AddText(imgui.ImVec2(cntX + (cntW-authorSz.x)*0.5, cy), u32(CLR.textDim), authorLbl)

        elseif curPage == 2 then
            local cy = cntY
            local rh = 34*MDS
            local nv, changed

            sectionTitle(DL, cntX, cy, cntW, u8'\xd7\xd2\xce \xd1\xce\xc1\xc8\xd0\xc0\xc5\xcc')
            cy = cy + 20*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xd5\xeb\xee\xef\xee\xea', farm.collect_cotton)
            if changed then farm.collect_cotton = nv; saveCfg() end
            cy = cy + rh + 5*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xcb\xb8\xed', farm.collect_linen)
            if changed then farm.collect_linen = nv; saveCfg() end
            cy = cy + rh + 16*MDS

            sectionTitle(DL, cntX, cy, cntW, u8'\xcd\xc0\xd1\xd2\xd0\xce\xc9\xca\xc8')
            cy = cy + 20*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xd4\xf0\xe0\xe7\xfb \xef\xf0\xe8 \xe8\xe3\xf0\xee\xea\xe0\xf5', farm.chat_on_players)
            if changed then farm.chat_on_players = nv; saveCfg() end
            cy = cy + rh + 5*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xcf\xe0\xf2\xf0\xf3\xeb\xfc \xea\xf3\xf1\xf2\xee\xe2', farm.patrol_unripe)
            if changed then farm.patrol_unripe = nv; saveCfg() end
            cy = cy + rh + 5*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            local curRun, chRun = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xc1\xe5\xe3 (Run)', runActive)
            if chRun then runActive = curRun end
            cy = cy + rh + 5*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            local curCol, chCol = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xce\xf2\xea\xeb. \xea\xee\xeb\xeb\xe8\xe7\xe8\xfe', collisionEnabled)
            if chCol then
                collisionEnabled = curCol
                enableCollision()
            end
            cy = cy + rh + 5*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))

            local ajLbl = u8'\xc0\xe2\xf2\xee-\xef\xf0\xfb\xe6\xee\xea'
            local ajLS  = imgui.CalcTextSize(ajLbl)
            DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh-ajLS.y)*0.5), u32(CLR.text), ajLbl)

            local toggleW = 44*MDS
            local inpJW   = 62*MDS
            local gap     = 6*MDS

            local curJump, chJump = toggleRow(DL,
                cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                '', autoJump)
            if chJump then
                autoJump = curJump
                if autoJump then startAutoJump() else stopAutoJump() end
                saveCfg()
            end

            if not _ajBuf then _ajBuf = imgui.new.int[1](autoJumpInterval) end

            local btnSz  = 22*MDS
            local numW   = 28*MDS
            local secLbl = u8'\xf1\xe5\xea'
            local secLS  = imgui.CalcTextSize(secLbl)
            local numLbl = tostring(autoJumpInterval)
            local numLS  = imgui.CalcTextSize(numLbl)

            local blockR = cntX + cntW - 8*MDS - toggleW - gap
            local plusX  = blockR - btnSz
            local numX   = plusX - numW
            local minX   = numX - btnSz
            local secX   = minX - secLS.x - 6*MDS
            local midY   = cy + rh * 0.5

            DL:AddText(imgui.ImVec2(secX, midY - secLS.y*0.5), u32(CLR.textDim), secLbl)

            local mxM, myM = imgui.GetMousePos().x, imgui.GetMousePos().y
            local hovMin = mxM>=minX and mxM<=minX+btnSz and myM>=cy and myM<=cy+rh
            local hovPls = mxM>=plusX and mxM<=plusX+btnSz and myM>=cy and myM<=cy+rh
            DL:AddRectFilled(imgui.ImVec2(minX, midY-btnSz*0.5),
                imgui.ImVec2(minX+btnSz, midY+btnSz*0.5),
                u32(hovMin and CLR.accentH or imgui.ImVec4(0.18,0.18,0.18,1)), 4*MDS)
            local minIcon = imgui.CalcTextSize('-')
            DL:AddText(imgui.ImVec2(minX+(btnSz-minIcon.x)*0.5, midY-minIcon.y*0.5),
                u32(CLR.text), '-')

            DL:AddText(imgui.ImVec2(numX+(numW-numLS.x)*0.5, midY-numLS.y*0.5),
                u32(CLR.text), numLbl)

            DL:AddRectFilled(imgui.ImVec2(plusX, midY-btnSz*0.5),
                imgui.ImVec2(plusX+btnSz, midY+btnSz*0.5),
                u32(hovPls and CLR.accentH or imgui.ImVec4(0.18,0.18,0.18,1)), 4*MDS)
            local plusIcon = imgui.CalcTextSize('+')
            DL:AddText(imgui.ImVec2(plusX+(btnSz-plusIcon.x)*0.5, midY-plusIcon.y*0.5),
                u32(CLR.text), '+')

            imgui.SetCursorPos(imgui.ImVec2(minX-WP.x, midY-btnSz*0.5-WP.y))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
            if imgui.Button('##ajm', imgui.ImVec2(btnSz, btnSz)) then
                autoJumpInterval = math.max(2, autoJumpInterval - 1)
                _ajBuf[0] = autoJumpInterval
                if autoJump then startAutoJump() end
                saveCfg()
            end
            imgui.SetCursorPos(imgui.ImVec2(plusX-WP.x, midY-btnSz*0.5-WP.y))
            if imgui.Button('##ajp', imgui.ImVec2(btnSz, btnSz)) then
                autoJumpInterval = math.min(180, autoJumpInterval + 1)
                _ajBuf[0] = autoJumpInterval
                if autoJump then startAutoJump() end
                saveCfg()
            end
            imgui.PopStyleColor(3)

            cy = cy + rh + 5*MDS

            if autoJump then
                local jcLbl = string.format(u8('\xcf\xf0\xfb\xe6\xea\xee\xe2: %d'), autoJumpCount)
                local jcS   = imgui.CalcTextSize(jcLbl)
                DL:AddText(imgui.ImVec2(cntX+8*MDS, cy), u32(CLR.green), jcLbl)
                cy = cy + jcS.y + 3*MDS
            end

        elseif curPage == 3 then
            local cy = cntY
            local rh = 34*MDS
            local nv, changed

            sectionTitle(DL, cntX, cy, cntW, u8'\xc7\xc0\xd9\xc8\xd2\xc0')
            cy = cy + 20*MDS

            local guards = {
                { u8'\xd1\xf2\xee\xef \xef\xf0\xe8 \xe4\xe8\xe0\xeb\xee\xe3\xe5',         'stop_on_dialog' },
                { u8'\xd1\xf2\xee\xef \xef\xf0\xe8 \xf2\xe5\xeb\xe5\xef\xee\xf0\xf2\xe5', 'stop_on_tp'     },
                { u8'\xd1\xf2\xee\xef \xef\xf0\xe8 \xef\xf1\xee\xe2\xe5\xf0\xea\xe5',     'stop_on_chat'   },
                { u8'\xc2\xfb\xf5\xee\xe4 \xe8\xe7 \xe8\xe3\xf0\xfb',                     'quit_on_stop'   },
            }
            for _, g in ipairs(guards) do
                rowBg(DL, cntX, cy, cntW, rh)
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.Dummy(imgui.ImVec2(cntW, rh))
                nv, changed = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                    g[1], farm[g[2]])
                if changed then
                    farm[g[2]] = nv; saveCfg()
                    if nv and g[2] ~= 'quit_on_stop' then
                        antiAdminEnableTime = os.clock()
                    end
                end
                cy = cy + rh + 5*MDS
            end

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            local aaLbl = u8'\xc0\xe2\xf2\xee-\xee\xf2\xe2\xe5\xf2 \xe0\xe4\xec\xe8\xed\xf3'
            local nv_aa, ch_aa = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS, aaLbl, aaState)
            if ch_aa then aaState = nv_aa; saveCfg() end
            cy = cy + rh + 5*MDS

        elseif curPage == 4 then
            local cy = cntY
            local rh = 34*MDS
            local nv2, ch2

            sectionTitle(DL, cntX, cy, cntW, u8'TELEGRAM')
            cy = cy + 20*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            nv2, ch2 = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xc2\xea\xeb\xfe\xf7\xe8\xf2\xfc \xf3\xe2\xe5\xe4\xee\xec\xeb\xe5\xed\xe8\xff', tg.enabled)
            if ch2 then tg.enabled = nv2; saveCfg() end
            cy = cy + rh + 5*MDS

            rowBg(DL, cntX, cy, cntW, rh)
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh))
            nv2, ch2 = toggleRow(DL, cntX+8*MDS, cy+(rh-22*MDS)*0.5, cntW-8*MDS,
                u8'\xce\xf2\xef\xf0\xe0\xe2\xeb\xff\xf2\xfc \xeb\xee\xe3\xe8', tg.logs)
            if ch2 then tg.logs = nv2; saveCfg() end
            cy = cy + rh + 14*MDS

            if dlBtn(DL, cntX, cy, cntW, 36*MDS, CLR.tgBlue, CLR.tgH,
                fa['PAPER_PLANE']..' @strand_autocotton_bot', CLR.text, 4*MDS) then
                openLink('https://t.me/strand_autocotton_bot')
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, 36*MDS))
            cy = cy + 36*MDS + 14*MDS

            local labS = imgui.CalcTextSize('Chat ID:')
            DL:AddText(imgui.ImVec2(cntX, cy), u32(CLR.textDim), 'Chat ID:')
            cy = cy + labS.y + 5*MDS

            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.SetNextItemWidth(cntW)
            if imgui.InputText('##cid', tgChatBuf, 64, imgui.InputTextFlags.Password) then
                local s   = ffi.string(tgChatBuf)
                local z   = s:find('\0')
                local raw = (z and s:sub(1,z-1) or s):match('^%s*(.-)%s*$'):gsub('[^%d%-]','')
                tg.chat_id = raw
                ffi.fill(tgChatBuf, 64, 0)
                for i = 0, #raw-1 do tgChatBuf[i] = string.byte(raw,i+1) end
            end
            imgui.Dummy(imgui.ImVec2(cntW, 28*MDS))
            cy = cy + 28*MDS + 10*MDS

            if dlBtn(DL, cntX, cy, cntW, 36*MDS, CLR.green, CLR.greenH,
                fa['FLOPPY_DISK']..' '..u8'\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc + \xf2\xe5\xf1\xf2', CLR.text, 4*MDS) then
                local s = ffi.string(tgChatBuf)
                local z = s:find('\0'); tg.chat_id = z and s:sub(1,z-1) or s
                saveCfg()
                if tg.enabled then
                    sendTG('[StrandFerma] \xd2\xe5\xf1\xf2 \xf1\xe2\xff\xe7\xe8 \xf3\xf1\xef\xe5\xf8\xe5\xed!')
                    addLog('[TG] \xd2\xe5\xf1\xf2 \xee\xf2\xef\xf0\xe0\xe2\xeb\xe5\xed')
                end
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, 36*MDS))
            cy = cy + 36*MDS + 12*MDS

            local tgStatus = tg.enabled
                and (tg.chat_id ~= '' and u8'OK' or u8'\xed\xe5\xf2 Chat ID')
                or u8'\xee\xf2\xea\xeb\xfe\xf7\xe5\xed\xee'
            local stC2 = tg.enabled and (tg.chat_id ~= '' and CLR.green or CLR.orange) or CLR.textDim
            DL:AddText(imgui.ImVec2(cntX, cy), u32(stC2), u8'\xd1\xf2\xe0\xf2\xf3\xf1: '..tgStatus)

        elseif curPage == 5 then
            local cy = cntY
            local rh3 = 34*MDS

            sectionTitle(DL, cntX, cy, cntW, u8'\xd6\xc5\xcd\xdb ($)')
            cy = cy + 20*MDS

            local labels = {
                u8'\xd5\xeb\xee\xef\xee\xea:',
                u8'\xcb\xb8\xed:',
                u8'\xd2\xea\xe0\xed\xfc:',
                u8'\xc2\xee\xe4\xe0:',
            }
            local bufs   = { calcCot, calcLin, calcRar, calcWat }
            local fields = { 'price_cotton','price_linen','price_rare','price_water' }
            local fcolors = {
                imgui.ImVec4(0.95,0.88,0.55,1),
                imgui.ImVec4(0.55,0.95,0.68,1),
                imgui.ImVec4(0.75,0.52,0.95,1),
                CLR.water,
            }
            for i = 1, 4 do
                rowBg(DL, cntX, cy, cntW, rh3)
                local lbl3 = imgui.CalcTextSize(labels[i])
                DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh3-lbl3.y)*0.5), u32(fcolors[i]), labels[i])
                imgui.SetCursorPos(imgui.ImVec2(cntX+cntW-80*MDS-WP.x, cy+(rh3-22*MDS)*0.5-WP.y))
                imgui.SetNextItemWidth(80*MDS)
                if imgui.InputFloat('##pf'..i, bufs[i], 0, 0, '%.0f') then
                    calc[fields[i]] = bufs[i][0]
                end
                imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
                imgui.Dummy(imgui.ImVec2(cntW, rh3))
                cy = cy + rh3 + 5*MDS
            end

            cy = cy + 10*MDS
            sectionTitle(DL, cntX, cy, cntW, u8'\xd2\xc0\xc9\xcc\xc5\xd0 (\xcc\xc8\xcd)')
            cy = cy + 20*MDS

            rowBg(DL, cntX, cy, cntW, rh3)
            local lblT = imgui.CalcTextSize(u8'\xd2\xe0\xe9\xec\xe5\xf0:')
            DL:AddText(imgui.ImVec2(cntX+8*MDS, cy+(rh3-lblT.y)*0.5), u32(CLR.textDim), u8'\xd2\xe0\xe9\xec\xe5\xf0:')
            local inpW = 110*MDS
            local inpX = cntX + cntW - inpW - 8*MDS
            local inpY = cy + (rh3 - 22*MDS)*0.5
            imgui.SetCursorPos(imgui.ImVec2(inpX - WP.x, inpY - WP.y))
            imgui.SetNextItemWidth(inpW)
            if imgui.InputInt('##btimer', timerBuf, 1, 10) then
                if timerBuf[0] < 0 then timerBuf[0] = 0 end
                botTimerMinutes = timerBuf[0]
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, rh3))
            cy = cy + rh3 + 6*MDS

            if farm.running and botTimerMinutes > 0 and botTimerStart > 0 then
                local elT  = os.time() - botTimerStart
                local rem  = math.max(0, botTimerMinutes*60 - elT)
                local remS = string.format(u8('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc: %02d:%02d'),
                    math.floor(rem/60), rem%60)
                DL:AddText(imgui.ImVec2(cntX+8*MDS, cy), u32(CLR.orange), remS)
                cy = cy + 24*MDS
            end

            cy = cy + 4*MDS
            local bw5 = (cntW-6*MDS)*0.5
            if dlBtn(DL, cntX, cy, bw5, 34*MDS,
                imgui.ImVec4(0.08,0.08,0.08,1), imgui.ImVec4(0.15,0.15,0.15,1),
                fa['FLOPPY_DISK']..' '..u8'\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc', CLR.accent, 4*MDS) then
                saveCfg()
            end
            if dlBtn(DL, cntX+bw5+6*MDS, cy, bw5, 34*MDS,
                imgui.ImVec4(0.20,0.05,0.05,1), imgui.ImVec4(0.40,0.09,0.09,1),
                fa['ROTATE_LEFT']..' '..u8'\xd1\xe1\xf0\xee\xf1', CLR.red, 4*MDS) then
                calc.price_cotton=0; calc.price_linen=0; calc.price_rare=0; calc.price_water=0
                calcCot[0]=0; calcLin[0]=0; calcRar[0]=0; calcWat[0]=0
                saveCfg()
            end
            imgui.SetCursorPos(imgui.ImVec2(cntX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cntW, 34*MDS))
        end

        pFpop(pm)
        imgui.End()
        imgui.PopStyleColor(3)
    end
)

imgui.OnFrame(
    function() return true end,
    function(self)
        self.HideCursor = true
        if not (farm.running and farm.target) then return end
        local tx, ty, tz = farm.target[1], farm.target[2], farm.target[3]
        local ok, ox, oy, oz = pcall(getCharCoordinates, PLAYER_PED)
        if not ok or type(ox) ~= 'number' then return end
        local sx1, sy1 = convert3DCoordsToScreen(ox, oy, oz)
        local sx2, sy2 = convert3DCoordsToScreen(tx, ty, tz)
        if not (sx1 and sy1 and sx2 and sy2) then return end
        local fdl = imgui.GetForegroundDrawList()
        fdl:AddLine(imgui.ImVec2(sx1,sy1), imgui.ImVec2(sx2,sy2), 0x44FF3333, 8)
        fdl:AddLine(imgui.ImVec2(sx1,sy1), imgui.ImVec2(sx2,sy2), 0xEEFF3333, 4)
        fdl:AddCircleFilled(imgui.ImVec2(sx2,sy2), 5*MDS, 0xFFFFFFFF)
        fdl:AddCircleFilled(imgui.ImVec2(sx2,sy2), 3*MDS, 0xCCFF3333)
    end
)

local _mainWinPos = nil

imgui.OnFrame(
    function() return WinMain[0] end,
    function(self)
        self.HideCursor = true
        if not _mainWinPos then return end
        local W2 = math.min(resx*0.88, 480*MDS)
        local H2 = math.min(resy*0.74, 450*MDS)
        local px2, py2 = _mainWinPos.x, _mainWinPos.y
        local fdl2 = imgui.GetForegroundDrawList()
        fdl2:AddRect(imgui.ImVec2(px2-1, py2-1), imgui.ImVec2(px2+W2+1, py2+H2+1),
            0x33000000, 0, 0, 4)
        fdl2:AddRect(imgui.ImVec2(px2, py2), imgui.ImVec2(px2+W2, py2+H2),
            0x55FF4D4D, 0, 0, 1.0)
    end
)

imgui.OnFrame(
    function() return WinStats[0] end,
    function(self)
        self.HideCursor = true
        local SW = math.min(resx*0.65, 260*MDS)
        local SH = (38+12+22+98+8+80+5+24+32+10)*MDS

        imgui.SetNextWindowPos(
            imgui.ImVec2(resx - SW - 18*MDS, resy - SH - 18*MDS),
            imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(SW, SH), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg,    imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,       imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.BorderShadow, imgui.ImVec4(0,0,0,0))
        imgui.Begin('##winstats', WinStats,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoResize    +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoScrollWithMouse +
            imgui.WindowFlags.NoBackground)

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local pm  = pF(fMain)
        local pad = 12*MDS
        local IW  = SW - pad*2
        local rndS = 12*MDS

        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW, WP.y+SH),
            u32(imgui.ImVec4(0.059,0.059,0.059,0.98)), rndS)
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW, WP.y+SH*0.35),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.45)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.45)),
            u32(imgui.ImVec4(0,0,0,0)),
            u32(imgui.ImVec4(0,0,0,0)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+SW*0.5, WP.y+SH*0.65), imgui.ImVec2(WP.x+SW, WP.y+SH),
            u32(imgui.ImVec4(0,0,0,0)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.40)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.40)),
            u32(imgui.ImVec4(0,0,0,0)))
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+SW,WP.y+SH),
            u32(CLR.border), rndS, 0, 1.2)

        local sHdrH = 38*MDS
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)), rndS, 0x3)
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y+rndS), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+SW*0.55, WP.y+sHdrH),
            u32(imgui.ImVec4(0.106,0.157,0.216,1.00)),
            u32(imgui.ImVec4(0.086,0.102,0.129,0.00)),
            u32(imgui.ImVec4(0.086,0.102,0.129,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+SW*0.45, WP.y), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(imgui.ImVec4(0,0,0,0)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.85)),
            u32(imgui.ImVec4(0.545,0.176,0.176,0.85)),
            u32(imgui.ImVec4(0,0,0,0)))
        DL:AddLine(imgui.ImVec2(WP.x, WP.y+sHdrH), imgui.ImVec2(WP.x+SW, WP.y+sHdrH),
            u32(CLR.border), 1)

        local hdrLbl = u8'\xd1\xd2\xc0\xd2\xc8\xd1\xd2\xc8\xca\xc0'
        local hdrSz  = imgui.CalcTextSize(hdrLbl)
        DL:AddText(imgui.ImVec2(WP.x+pad, WP.y+sHdrH*0.5-hdrSz.y*0.5),
            u32(CLR.text), hdrLbl)

        local rstSz = 22*MDS
        local mx_s, my_s = imgui.GetMousePos().x, imgui.GetMousePos().y
        local rstX  = WP.x + SW - rstSz*2 - pad - 6*MDS
        local rstY2 = WP.y + (sHdrH - rstSz)*0.5
        local rstHov = mx_s>=rstX and mx_s<=rstX+rstSz and my_s>=rstY2 and my_s<=rstY2+rstSz
        local rstIc  = fa['ROTATE_LEFT']
        local rstIS  = imgui.CalcTextSize(rstIc)
        DL:AddRectFilled(imgui.ImVec2(rstX,rstY2), imgui.ImVec2(rstX+rstSz,rstY2+rstSz),
            u32(rstHov and imgui.ImVec4(1,1,1,0.15) or imgui.ImVec4(1,1,1,0.06)), 4*MDS)
        DL:AddText(imgui.ImVec2(rstX+(rstSz-rstIS.x)*0.5, rstY2+(rstSz-rstIS.y)*0.5),
            u32(rstHov and CLR.accent or CLR.textDim), rstIc)
        if rstHov and imgui.IsMouseClicked(0) then
            farm.res_counter = {cotton=0,linen=0,rare=0,water=0}
            farm.stats.start_time = 0
            botTotalSeconds = 0
            if botSessionStart > 0 then botSessionStart = os.time() end
            saveCfg()
        end

        local clsSz = 22*MDS
        local clsX  = WP.x + SW - clsSz - pad
        local clsY  = WP.y + (sHdrH - clsSz)*0.5
        local clsHov = mx_s>=clsX and mx_s<=clsX+clsSz and my_s>=clsY and my_s<=clsY+clsSz
        DL:AddRectFilled(imgui.ImVec2(clsX,clsY), imgui.ImVec2(clsX+clsSz,clsY+clsSz),
            u32(clsHov and CLR.accent or imgui.ImVec4(1,1,1,0.10)), 4*MDS)
        local xSt = imgui.CalcTextSize('x')
        DL:AddText(imgui.ImVec2(clsX+(clsSz-xSt.x)*0.5, clsY+(clsSz-xSt.y)*0.5),
            u32(clsHov and CLR.text or imgui.ImVec4(1,1,1,0.55)), 'x')
        if clsHov and imgui.IsMouseClicked(0) then WinStats[0] = false end

        local cy2 = WP.y + sHdrH + pad


        local el3    = getBotElapsed()
        local timeS3 = string.format('%02d:%02d:%02d',
            math.floor(el3/3600), math.floor((el3%3600)/60), el3%60)
        local sesLbl = u8'\xd0\xe0\xe1\xee\xf2\xe0 \xe1\xee\xf2\xe0: '..timeS3
        DL:AddText(imgui.ImVec2(WP.x+pad, cy2), u32(CLR.textDim), sesLbl)
        cy2 = cy2 + imgui.CalcTextSize(sesLbl).y + 10*MDS

        local rc3  = farm.res_counter
        local cg3  = 5*MDS; local cw3 = (IW-cg3)*0.5; local ch3 = 42*MDS
        drawStatCard(DL, WP.x+pad,        cy2, cw3, ch3, u8'\xd5\xcb\xce\xcf', fmtNum(rc3.cotton), imgui.ImVec4(0.95,0.88,0.55,1))
        drawStatCard(DL, WP.x+pad+cw3+cg3,cy2, cw3, ch3, u8'\xcb\xb8\xcd',    fmtNum(rc3.linen),  imgui.ImVec4(0.55,0.95,0.68,1))
        imgui.SetCursorPos(imgui.ImVec2(pad, cy2-WP.y))
        imgui.Dummy(imgui.ImVec2(IW, ch3+5*MDS))
        cy2 = cy2 + ch3 + 7*MDS
        drawStatCard(DL, WP.x+pad,        cy2, cw3, ch3, u8'\xd2\xca\xc0\xcd\xdc', fmtNum(rc3.rare),  imgui.ImVec4(0.75,0.52,0.95,1))
        drawStatCard(DL, WP.x+pad+cw3+cg3,cy2, cw3, ch3, u8'\xc2\xce\xc4\xc0',     fmtNum(rc3.water), CLR.water)
        imgui.SetCursorPos(imgui.ImVec2(pad, cy2-WP.y))
        imgui.Dummy(imgui.ImVec2(IW, ch3+8*MDS))
        cy2 = cy2 + ch3 + 8*MDS

        DL:AddLine(imgui.ImVec2(WP.x+pad, cy2), imgui.ImVec2(WP.x+SW-pad, cy2), u32(CLR.border), 1)
        cy2 = cy2 + 8*MDS

        local pc3  = rc3.cotton * calc.price_cotton
        local pl3  = rc3.linen  * calc.price_linen
        local pr3  = rc3.rare   * calc.price_rare
        local pw3  = rc3.water  * calc.price_water
        local tot3 = pc3+pl3+pr3+pw3

        local incRows = {
            { u8'\xd5\xeb\xee\xef\xee\xea:', fmtNum(pc3)..'$', imgui.ImVec4(0.95,0.88,0.55,1) },
            { u8'\xcb\xb8\xed:',              fmtNum(pl3)..'$', imgui.ImVec4(0.55,0.95,0.68,1) },
            { u8'\xd2\xea\xe0\xed\xfc:',      fmtNum(pr3)..'$', imgui.ImVec4(0.75,0.52,0.95,1) },
            { u8'\xc2\xee\xe4\xe0:',          fmtNum(pw3)..'$', CLR.water },
        }
        for _, row in ipairs(incRows) do
            local lS = imgui.CalcTextSize(row[1])
            local vS = imgui.CalcTextSize(row[2])
            DL:AddText(imgui.ImVec2(WP.x+pad, cy2), u32(CLR.textDim), row[1])
            DL:AddText(imgui.ImVec2(WP.x+SW-pad-vS.x, cy2), u32(row[3]), row[2])
            cy2 = cy2 + lS.y + 4*MDS
        end

        DL:AddLine(imgui.ImVec2(WP.x+pad, cy2), imgui.ImVec2(WP.x+SW-pad, cy2), u32(CLR.border), 1)
        cy2 = cy2 + 5*MDS
        local totLbl = u8'\xc8\xd2\xce\xc3\xce:'
        local totVal = fmtNum(tot3)..'$'
        local totLS  = imgui.CalcTextSize(totLbl)
        local totVS  = imgui.CalcTextSize(totVal)
        local pB2    = pF(fBig)
        DL:AddText(imgui.ImVec2(WP.x+pad, cy2), u32(CLR.text), totLbl)
        DL:AddText(imgui.ImVec2(WP.x+SW-pad-totVS.x, cy2), u32(CLR.green), totVal)
        pFpop(pB2)
        cy2 = cy2 + math.max(totLS.y, totVS.y) + 8*MDS

        imgui.SetCursorPos(imgui.ImVec2(pad, cy2-WP.y))
        if dlBtn(DL, WP.x+pad, cy2, IW, 32*MDS, CLR.tgBlue, CLR.tgH,
            fa['PAPER_PLANE']..' '..u8'\xce\xf2\xf7\xb8\xf2 \xe2 Telegram', CLR.text, 4*MDS) then
            sendStatsReport('\xce\xf2\xf7\xb8\xf2')
        end
        imgui.Dummy(imgui.ImVec2(IW, 32*MDS))

        pFpop(pm)
        imgui.End()
        imgui.PopStyleColor(3)
    end
)

-- ==[ АВТО ЕДА: мини-окно настроек (перемещаемое, в стиле меню) ]==--
local WinAutoEatSettings = imgui.new.bool(false)
imgui.OnFrame(
    function() return autoEatSettingsOpen and WinMain[0] end,
    function(self)
        self.HideCursor = false

        local AW = 260*MDS
        local AH = 260*MDS

        imgui.SetNextWindowPos(imgui.ImVec2(resx*0.5 + 260*MDS, resy*0.5 - AH*0.5),
            imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(AW, AH), imgui.Cond.Always)

        local fl = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                 + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
                 + imgui.WindowFlags.NoBackground
        imgui.PushStyleColor(imgui.Col.WindowBg,    imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,       imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.BorderShadow, imgui.ImVec4(0,0,0,0))
        imgui.Begin('##ae_win', WinAutoEatSettings, fl)

        local DL  = imgui.GetWindowDrawList()
        local WP  = imgui.GetWindowPos()
        local pm  = pF(fMain)
        local rnd = 12*MDS
        local pad = 14*MDS

        -- === ФОН в точности как у главного окна ===
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+AW, WP.y+AH),
            u32(imgui.ImVec4(0.059,0.059,0.059,0.98)))
        DL:AddRect(imgui.ImVec2(WP.x,WP.y), imgui.ImVec2(WP.x+AW,WP.y+AH),
            u32(CLR.border), 0, 0, 1.0)

        -- === ХЕДЕР как у главного окна ===
        local hdrH = 44*MDS
        DL:AddRectFilled(imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+AW, WP.y+hdrH),
            u32(imgui.ImVec4(0.086,0.102,0.129,1.00)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x, WP.y), imgui.ImVec2(WP.x+AW*0.55, WP.y+hdrH),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.00)),
            u32(imgui.ImVec4(0.106,0.157,0.216,0.90)))
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(WP.x+AW*0.45, WP.y), imgui.ImVec2(WP.x+AW, WP.y+hdrH),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.00)),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.30)),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.30)),
            u32(imgui.ImVec4(0.200,0.820,0.400,0.00)))
        DL:AddLine(imgui.ImVec2(WP.x, WP.y+hdrH), imgui.ImVec2(WP.x+AW, WP.y+hdrH),
            u32(CLR.border), 1)

        -- Заголовок в хедере (иконка + текст)
        local pB3 = pF(fMain)
        local aeHdrIc = fa['UTENSILS']
        local aeHdrS  = imgui.CalcTextSize(aeHdrIc)
        DL:AddText(imgui.ImVec2(WP.x+pad, WP.y+hdrH*0.5-aeHdrS.y*0.5),
            u32(CLR.green), aeHdrIc)
        local aeHdrLbl = u8' \xc0\xe2\xf2\xee \xc5\xe4\xe0'
        local aeHdrLS  = imgui.CalcTextSize(aeHdrLbl)
        DL:AddText(imgui.ImVec2(WP.x+pad+aeHdrS.x, WP.y+hdrH*0.5-aeHdrLS.y*0.5),
            u32(CLR.text), aeHdrLbl)
        pFpop(pB3)

        -- Кнопка закрыть (X) в хедере
        local clSz2 = 24*MDS
        local clX2  = WP.x + AW - clSz2 - pad*0.5
        local clY2  = WP.y + (hdrH - clSz2)*0.5
        local mxC, myC = imgui.GetMousePos().x, imgui.GetMousePos().y
        local clHov2 = mxC>=clX2 and mxC<=clX2+clSz2 and myC>=clY2 and myC<=clY2+clSz2
        DL:AddRectFilled(imgui.ImVec2(clX2,clY2), imgui.ImVec2(clX2+clSz2,clY2+clSz2),
            u32(clHov2 and CLR.accent or imgui.ImVec4(1,1,1,0.08)), 4*MDS)
        local xS2 = imgui.CalcTextSize('x')
        DL:AddText(imgui.ImVec2(clX2+(clSz2-xS2.x)*0.5, clY2+(clSz2-xS2.y)*0.5),
            u32(clHov2 and CLR.text or imgui.ImVec4(1,1,1,0.55)), 'x')
        if clHov2 and imgui.IsMouseClicked(0) then autoEatSettingsOpen = false end

        -- Сделать хедер перемещаемым (drag area)
        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        imgui.InvisibleButton('##ae_drag', imgui.ImVec2(AW - clSz2 - pad, hdrH))
        if imgui.IsItemActive() then
            local d = imgui.GetIO().MouseDelta
            -- двигаем окно через SetNextWindowPos в следующем кадре не работает,
            -- но imgui сам двигает окно когда нет NoMove флага
        end

        -- === ТЕЛО ===
        local bodyY = WP.y + hdrH
        local cX    = WP.x + pad
        local cW    = AW - pad*2
        local cy    = bodyY + 7*MDS
        local rh    = 26*MDS   -- компактнее чем обычные 34*MDS

        -- Статус сытости
        local satCurLbl2, satCurCol2
        if autoEatSatiety < 0 then
            satCurLbl2 = u8'\xd1\xfb\xf2\xee\xf1\xf2\xfc: ???'
            satCurCol2 = CLR.textDim
        else
            local sv = math.floor(autoEatSatiety)
            satCurLbl2 = string.format(u8'\xd1\xfb\xf2\xee\xf1\xf2\xfc: %d / 100', sv)
            satCurCol2 = sv < 30 and imgui.ImVec4(1,0.30,0.30,1)
                      or sv < 60 and imgui.ImVec4(0.95,0.70,0.10,1)
                      or CLR.green
        end
        local pSm4 = pF(fSmall)
        local satLS2 = imgui.CalcTextSize(satCurLbl2)
        DL:AddText(imgui.ImVec2(cX + (cW-satLS2.x)*0.5, cy), u32(satCurCol2), satCurLbl2)
        pFpop(pSm4)
        cy = cy + satLS2.y + 6*MDS

        DL:AddLine(imgui.ImVec2(cX, cy), imgui.ImVec2(cX+cW, cy), u32(CLR.border), 1)
        cy = cy + 7*MDS

        -- Секция: выбор еды
        sectionTitle(DL, cX, cy, cW, u8'\xc2\xfb\xe1\xee\xf0 \xe5\xe4\xfb')
        cy = cy + 16*MDS

        local foodNames2 = {
            u8'\xd7\xe8\xef\xf1\xfb',
            u8'\xd0\xfb\xe1\xe0',
            u8'\xce\xeb\xe5\xed\xe8\xed\xe0',
        }
        local rdSz2 = 11*MDS
        for i = 0, 2 do
            rowBg(DL, cX, cy, cW, rh)
            local midYf = cy + rh*0.5
            local selected2 = (autoEatFood == i)

            -- точка-индикатор
            local rdX2 = cX + 8*MDS + rdSz2*0.5
            if selected2 then
                DL:AddCircleFilled(imgui.ImVec2(rdX2, midYf), rdSz2*0.5, u32(CLR.accent))
                DL:AddCircleFilled(imgui.ImVec2(rdX2, midYf), rdSz2*0.5-2*MDS, u32(imgui.ImVec4(0.059,0.059,0.059,1)))
                DL:AddCircleFilled(imgui.ImVec2(rdX2, midYf), rdSz2*0.5-4*MDS, u32(CLR.accent))
            else
                DL:AddCircle(imgui.ImVec2(rdX2, midYf), rdSz2*0.5, u32(CLR.textDim), 24, 1.2)
            end

            local pm5 = pF(fSmall)
            local fS2 = imgui.CalcTextSize(foodNames2[i+1])
            DL:AddText(imgui.ImVec2(cX+8*MDS+rdSz2+6*MDS, midYf-fS2.y*0.5),
                u32(selected2 and CLR.text or CLR.textDim), foodNames2[i+1])
            pFpop(pm5)

            imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
            imgui.Dummy(imgui.ImVec2(cW, rh))
            imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
            if imgui.Button('##aef2_'..i, imgui.ImVec2(cW, rh)) then
                autoEatFood = i; saveCfg()
            end
            imgui.PopStyleColor(3)
            cy = cy + rh + 3*MDS
        end

        cy = cy + 3*MDS
        DL:AddLine(imgui.ImVec2(cX, cy), imgui.ImVec2(cX+cW, cy), u32(CLR.border), 1)
        cy = cy + 7*MDS

        -- Секция: порог сытости
        sectionTitle(DL, cX, cy, cW, u8'\xc5\xf1\xf2\xfc \xef\xf0\xe8 \xf1\xfb\xf2\xee\xf1\xf2\xe8 \xed\xe8\xe6\xe5:')
        cy = cy + 16*MDS

        rowBg(DL, cX, cy, cW, rh)

        local btnSz3 = 22*MDS
        local numW3  = 38*MDS
        local blkW   = btnSz3*2 + numW3 + 8*MDS
        local blkX   = cX + (cW - blkW)*0.5
        local midYs  = cy + rh*0.5

        local mxS2, myS2 = imgui.GetMousePos().x, imgui.GetMousePos().y
        local hovMn = mxS2>=blkX and mxS2<=blkX+btnSz3 and myS2>=cy and myS2<=cy+rh
        local hovPl = mxS2>=blkX+btnSz3+numW3+8*MDS and mxS2<=blkX+blkW and myS2>=cy and myS2<=cy+rh

        -- кнопка -
        DL:AddRectFilled(imgui.ImVec2(blkX, midYs-btnSz3*0.5),
            imgui.ImVec2(blkX+btnSz3, midYs+btnSz3*0.5),
            u32(hovMn and CLR.accentH or imgui.ImVec4(0.15,0.15,0.15,1)), 5*MDS)
        local mS = imgui.CalcTextSize('-')
        DL:AddText(imgui.ImVec2(blkX+(btnSz3-mS.x)*0.5, midYs-mS.y*0.5), u32(CLR.text), '-')

        -- число
        local numLbl3 = tostring(autoEatMinSatiety)
        local numLS3  = imgui.CalcTextSize(numLbl3)
        DL:AddText(imgui.ImVec2(blkX+btnSz3+4*MDS+(numW3-numLS3.x)*0.5, midYs-numLS3.y*0.5),
            u32(CLR.text), numLbl3)

        -- кнопка +
        DL:AddRectFilled(imgui.ImVec2(blkX+btnSz3+numW3+8*MDS, midYs-btnSz3*0.5),
            imgui.ImVec2(blkX+blkW, midYs+btnSz3*0.5),
            u32(hovPl and CLR.accentH or imgui.ImVec4(0.15,0.15,0.15,1)), 5*MDS)
        local pS2 = imgui.CalcTextSize('+')
        DL:AddText(imgui.ImVec2(blkX+btnSz3+numW3+8*MDS+(btnSz3-pS2.x)*0.5, midYs-pS2.y*0.5),
            u32(CLR.text), '+')

        imgui.SetCursorPos(imgui.ImVec2(cX-WP.x, cy-WP.y))
        imgui.Dummy(imgui.ImVec2(cW, rh))
        imgui.SetCursorPos(imgui.ImVec2(blkX-WP.x, midYs-btnSz3*0.5-WP.y))
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0,0,0,0))
        if imgui.Button('##ae_mn', imgui.ImVec2(btnSz3, btnSz3)) then
            autoEatMinSatiety = math.max(20, autoEatMinSatiety - 5); saveCfg()
        end
        imgui.SetCursorPos(imgui.ImVec2(blkX+btnSz3+numW3+8*MDS-WP.x, midYs-btnSz3*0.5-WP.y))
        if imgui.Button('##ae_pl', imgui.ImVec2(btnSz3, btnSz3)) then
            autoEatMinSatiety = math.min(100, autoEatMinSatiety + 5); saveCfg()
        end
        imgui.PopStyleColor(3)

        pFpop(pm)
        imgui.End()
        imgui.PopStyleColor(3)
    end
)

lua_thread.create(function()
    while not isSampAvailable() do wait(500) end
    while not sampIsLocalPlayerSpawned() do wait(500) end
    wait(1000)
    if licenseKey ~= '' then
        lua_thread.create(function()
            local ok, req = pcall(require, 'requests')
            if not ok or not req then return end
            local rok, resp = pcall(req.get, LIC_SHEET_URL)
            if not rok or not resp or resp.status_code ~= 200 then
                local ey, em, ed = licenseKey:match('(%d%d%d%d)-(%d%d)-(%d%d)$')
                if ey then
                    licenseOK = true
                    sampAddChatMessage('{4488ff}[StrandFerma]: {00ff7f}\xcc\xf3\xeb\xfc\xf2 \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed. {aaaaff}(\xc4\xee: '..ey..'-'..em..'-'..ed..')', -1)
                end
                return
            end

            local body = resp.text or resp.content or ''

            local keyFound = false
            local keyHasDate = false
            for row in body:gmatch('"c":%[(.-)%]') do
                local cols = {}
                for cell in row:gmatch('{[^}]*}') do
                    local val = cell:match('"v":"([^"]*)"')
                    cols[#cols + 1] = val or ''
                end
                local baseKey = licenseKey:match('^(.-)%-%d%d%d%d%-%d%d%-%d%d$') or licenseKey
                local rowBase = (cols[1] or ''):match('^(.-)%-%d%d%d%d%-%d%d%-%d%d$') or (cols[1] or '')
                if rowBase == baseKey or cols[1] == licenseKey then
                    keyFound = true
                    local ey2, em2, ed2 = (cols[1] or ''):match('(%d%d%d%d)-(%d%d)-(%d%d)$')
                    if ey2 then keyHasDate = true end
                    break
                end
            end

            if not keyFound then
                licenseOK = false
                sampAddChatMessage('{4488ff}[StrandFerma]: {ff4444}\xd1\xf0\xee\xea \xef\xee\xe4\xef\xe8\xf1\xea\xe8 \xe8\xf1\xf2\xb8\xea. \xce\xe1\xf0\xe0\xf2\xe8\xf2\xe5\xf1\xfc \xea @victor_st0.', -1)
                return
            end

            if not keyHasDate then
                licenseOK = false
                sampAddChatMessage('{4488ff}[StrandFerma]: {ff4444}\xd1\xf0\xee\xea \xef\xee\xe4\xef\xe8\xf1\xea\xe8 \xe8\xf1\xf2\xb8\xea. \xce\xe1\xf0\xe0\xf2\xe8\xf2\xe5\xf1\xfc \xea @victor_st0.', -1)
                return
            end

            local ey, em, ed = licenseKey:match('(%d%d%d%d)-(%d%d)-(%d%d)$')
            if ey then
                local now = os.date('*t')
                local expired = (tonumber(ey) < now.year)
                    or (tonumber(ey) == now.year and tonumber(em) < now.month)
                    or (tonumber(ey) == now.year and tonumber(em) == now.month and tonumber(ed) < now.day)
                if expired then
                    licenseOK = false
                    sampAddChatMessage('{4488ff}[StrandFerma]: {ff4444}\xd1\xf0\xee\xea \xef\xee\xe4\xef\xe8\xf1\xea\xe8 \xe8\xf1\xf2\xb8\xea. \xce\xe1\xf0\xe0\xf2\xe8\xf2\xe5\xf1\xfc \xea @victor_st0.', -1)
                else
                    licenseOK     = true
                    licWinOpen[0] = false
                    sampAddChatMessage('{4488ff}[StrandFerma]: {00ff7f}\xcc\xf3\xeb\xfc\xf2 \xe0\xea\xf2\xe8\xe2\xe8\xf0\xee\xe2\xe0\xed. {aaaaff}(\xc4\xee: '..ey..'-'..em..'-'..ed..')', -1)
                end
            end
        end)
    end
end)

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(100) end

    wait(300)
    loadCfg()
    saveCfg()
    timerBuf[0] = botTimerMinutes
    _ajBuf = imgui.new.int[1](autoJumpInterval)
    if autoJump then startAutoJump() end

    if type(tg.chat_id)=='string' and #tg.chat_id>0 then
        local clean = tg.chat_id:gsub('[^%d%-]',''):match('^%s*(.-)%s*$')
        tg.chat_id = clean
        ffi.fill(tgChatBuf, 64, 0)
        for i=0,#clean-1 do tgChatBuf[i]=string.byte(clean,i+1) end
    end
    calcCot[0]=calc.price_cotton
    calcLin[0]=calc.price_linen
    calcRar[0]=calc.price_rare
    calcWat[0]=calc.price_water

    local playerHandle=nil
    pcall(function()
        local ok,pid=pcall(sampGetLocalPlayerId)
        if ok then
            local ok2,h=pcall(sampGetCharHandleBySampId,pid)
            if ok2 then playerHandle=h end
        end
    end)

    sampAddChatMessage('{4488ff}[StrandFerma]: {aabbff}v2.7-monet | /sf | /sfhide',-1)

    sampRegisterChatCommand('sf', function()
        if not licenseOK then
            licWinOpen[0] = true
        else
            WinMain[0]=not WinMain[0]
        end
    end)
    sampRegisterChatCommand('sfhide', function()
        fabHidden=not fabHidden; saveCfg()
        sampAddChatMessage('{4488ff}[StrandFerma]: {aabbff}'
            ..(fabHidden
                and '\xca\xed\xee\xef\xea\xe0 \xd1\xd2\xc0\xd0\xd2/\xd1\xd2\xce\xcf \xf1\xea\xf0\xfb\xf2\xe0'
                 or '\xca\xed\xee\xef\xea\xe0 \xd1\xd2\xc0\xd0\xd2/\xd1\xd2\xce\xcf \xef\xee\xea\xe0\xe7\xe0\xed\xe0'),-1)
    end)

    lua_thread.create(renderLoop)
    lua_thread.create(botWatchdog)
    startTGWorker()

    -- AutoEat: основной цикл
    lua_thread.create(function()
        while not isSampAvailable() do wait(500) end
        while not sampIsLocalPlayerSpawned() do wait(500) end
        wait(4000)
        -- первичная проверка сытости при старте
        lua_thread.create(function()
            autoEatWaitSat = true
            sampSendChat('/satiety')
            local t = 0
            while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
            autoEatWaitSat = false
        end)
        while true do
            wait(0)
            if autoEat then
                -- ждём 30 сек между циклами
                for i = 1, 300 do
                    wait(100)
                    if not autoEat then break end
                end
                if not autoEat then goto ae_continue end
                if sampIsLocalPlayerSpawned() then
                    lua_thread.create(function()
                        -- шаг 1: запрос сытости
                        autoEatWaitSat = true
                        sampSendChat('/satiety')
                        local t = 0
                        while autoEatWaitSat and t < 60 do wait(100); t = t+1 end
                        autoEatWaitSat = false
                        wait(400)
                        -- шаг 2: нужно ли есть?
                        if autoEatSatiety >= 0 and autoEatSatiety >= autoEatMinSatiety then return end
                        -- шаг 3: едим
                        autoEatWaitEat = true
                        sampSendChat('/eat')
                        local t2 = 0
                        while autoEatWaitEat and t2 < 60 do wait(100); t2 = t2+1 end
                        autoEatWaitEat = false
                        -- если диалог всё ещё открыт — закрываем повторной командой
                        wait(300)
                        if sampIsDialogActive() then
                            sampSendChat('/eat')
                        end
                    end)
                end
            end
            ::ae_continue::
        end
    end)

    lua_thread.create(function()
        while true do
            wait(5000)
            if farm.running and botTimerMinutes > 0 and botTimerStart > 0 then
                local elapsed_t = os.time() - botTimerStart
                if elapsed_t >= botTimerMinutes * 60 then
                    emergencyStop()
                    sendStatsReport(u8('\xd2\xe0\xe9\xec\xe5\xf0 \xe8\xf1\xf2\xb8\xea'))
                    sampAddChatMessage('{4488ff}[StrandFerma]: {ffaa00}'
                        ..'\xd2\xe0\xe9\xec\xe5\xf0 \xe8\xf1\xf2\xb8\xea \xe2 '
                        ..tostring(botTimerMinutes)
                        ..' \xec\xe8\xed\xf3\xf2, \xe1\xee\xf2 \xee\xf1\xf2\xe0\xed\xee\xe2\xeb\xe5\xed', -1)
                    botTimerStart = 0
                    saveCfg()
                end
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(60*1000)
            saveCfg()
        end
    end)

    lua_thread.create(function()
        while true do
            wait(0)
            if collisionEnabled then enableCollision() end
        end
    end)

    lua_thread.create(function()
        local lastTgReport = os.time()
        while true do
            wait(30000)
            if farm.running and tg.enabled and tg.chat_id ~= '' then
                if os.time() - lastTgReport >= 20 * 60 then
                    lastTgReport = os.time()
                    sendStatsReport('\xc0\xe2\xf2\xee-\xee\xf2\xf7\xb8\xf2 20 \xec\xe8\xed')
                end
            end
        end
    end)

    while true do
        if playerHandle then
            applyRunTired(playerHandle)
        end

        if WIDGET_RADAR~=nil and isWidgetSwipedLeft(WIDGET_RADAR) then
            WinMain[0]=not WinMain[0]; wait(250)
        end
        if WIDGET_RADAR~=nil and isWidgetSwipedRight(WIDGET_RADAR) then
            if farm.running then
                emergencyStop()
                sampAddChatMessage('{4488ff}[StrandFerma]: {ff4444}\xd1\xd2\xce\xcf',-1)
            else
                if not licenseOK then
                    licWinOpen[0] = true
                else
                    farm.running    = true
                    botTimerStart   = os.time()
                    botSessionStart = os.time()
                    antiAdminEnableTime = os.clock()
                    movement.active = false
                    sprintActive    = false
                    setGameKeyState(1,0); stopSprint()
                    watchdogLastTarget = os.clock()
                    sampAddChatMessage('{4488ff}[StrandFerma]: {44ff44}\xd1\xd2\xc0\xd0\xd2',-1)
                end
            end
            wait(300)
        end

        if farm.running and not pause_bot then
            local best = findBestBushCached()
            if best then
                farm.target = best
                watchdogLastTarget = os.clock()
                local tx, ty, tz = best[1], best[2], best[3]
                local px, py = getCharCoordinates(PLAYER_PED)

                if getDistanceBetweenCoords2d(px, py, tx, ty) > 2.0 then
                    movement.active = true
                    runToPoint(tx, ty, tz)
                    movement.active = false
                end

                if farm.running then
                    setGameKeyState(1, 0)
                    stopSprint()
                    sprintActive = false
                    is_collecting = true

                    local function checkBushQty()
                        for id = 0, 2048 do
                            if sampIs3dTextDefined(id) then
                                local ok2, txt2, _, bx, by = pcall(sampGet3dTextInfoById, id)
                                if ok2 and txt2 and bx and by then
                                    if getDistanceBetweenCoords2d(bx, by, tx, ty) < 1.5 then
                                        if txt2:find('\xcc\xee\xe6\xed\xee \xf1\xee\xe1\xf0\xe0\xf2\xfc') then
                                            return tonumber(txt2:match('%((%d+)%s*\xe8\xe7'))
                                                or tonumber(txt2:match('(%d+)')) or 0
                                        end
                                        return 0
                                    end
                                end
                            end
                        end
                        return 0
                    end

                    local bushDone = false
                    while farm.running and not bushDone do

                        if checkBushQty() <= 0 then
                            addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xef\xf3\xf1\xf2 — \xf3\xf5\xee\xe6\xf3')
                            bushDone = true
                            break
                        end

                        local lastCotton = farm.res_counter.cotton
                        local lastLinen  = farm.res_counter.linen
                        local lastRare   = farm.res_counter.rare
                        local lastWater  = farm.res_counter.water
                        local timerStart = os.clock()
                        local lastResTime = os.clock()

                        doHarvest()

                        local collected = false
                        while farm.running and (os.clock() - timerStart) < 20 do
                            if farm.res_counter.cotton > lastCotton
                            or farm.res_counter.linen  > lastLinen
                            or farm.res_counter.rare   > lastRare
                            or farm.res_counter.water  > lastWater then
                                collected = true
                                break
                            end

                            if (os.clock() - lastResTime) >= 20 then
                                addLog('[\xd4\xe5\xf0\xec\xe0] 20\xf1 \xe1\xe5\xe7 \xf0\xe5\xf1\xf3\xf0\xf1\xe0 — \xef\xe5\xf0\xe5\xe7\xe0\xf5\xee\xe4')
                                setGameKeyState(1,0); stopSprint()
                                local cx_s,cy_s,cz_s = getCharCoordinates(PLAYER_PED)
                                local backA = getHeadingFromVector2d(cx_s-tx, cy_s-ty)
                                movement.active = true
                                runToPoint(cx_s+math.sin(math.rad(backA))*2, cy_s+math.cos(math.rad(backA))*2, cz_s)
                                runToPoint(tx, ty, tz)
                                movement.active = false
                                setGameKeyState(1,0); stopSprint()
                                doHarvest()
                                lastResTime = os.clock(); timerStart = os.clock()
                            end

                            local elapsed = os.clock() - timerStart
                            if elapsed > 0.6 and checkBushQty() <= 0 then
                                addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xee\xef\xf3\xf1\xf2\xe5\xeb — \xf3\xf5\xee\xe6\xf3')
                                bushDone = true
                                break
                            end
                            if elapsed > 3 and elapsed < 6 then doHarvest()
                            elseif elapsed >= 6 and elapsed < 9 then doHarvest()
                            end
                            wait(200)
                        end

                        if bushDone then break end

                        if collected then
                            wait(300)
                            if checkBushQty() <= 0 then
                                addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xe8\xf1\xf7\xe5\xf0\xef\xe0\xed — \xe8\xf9\xf3 \xf1\xeb\xe5\xe4\xf3\xfe\xf9\xe8\xe9')
                                bushDone = true
                            end
                        else
                            addLog('[\xd4\xe5\xf0\xec\xe0] \xca\xf3\xf1\xf2 \xed\xe5 \xf0\xe5\xe0\xe3\xe8\xf0\xf3\xe5\xf2 — \xef\xe5\xf0\xe5\xe7\xe0\xf5\xee\xe4')
                            local cx3,cy3 = getCharCoordinates(PLAYER_PED)
                            local bA = getHeadingFromVector2d(cx3-tx, cy3-ty)
                            local _,_,cz3 = getCharCoordinates(PLAYER_PED)
                            movement.active = true
                            runToPoint(cx3+math.sin(math.rad(bA))*2.5, cy3+math.cos(math.rad(bA))*2.5, cz3)
                            movement.active = false
                            wait(300)
                            bushDone = true
                        end
                    end

                    setGameKeyState(1,0); stopSprint()
                    is_collecting = false
                    invalidateBushCache()
                end

            else
                farm.target = nil
                setGameKeyState(1, 0)
                stopSprint()
                sprintActive = false

                if farm.patrol_unripe then
                    is_patrolling = true
                    addLog('[Патруль] \xcd\xe5\xf2 \xe7\xf0\xe5\xeb\xfb\xf5 \xea\xf3\xf1\xf2\xee\xe2, \xed\xe0\xf7\xe8\xed\xe0\xfe \xee\xe1\xf5\xee\xe4')

                    local function findSoonRipeBush()
                        local mx2, my2 = getCharCoordinates(PLAYER_PED)
                        local best, bd = nil, 200
                        for id = 0, 2048 do
                            if sampIs3dTextDefined(id) then
                                local ok2, txt2, _, x2, y2, z2 = pcall(sampGet3dTextInfoById, id)
                                if ok2 and txt2 then
                                    local wC = farm.collect_cotton and txt2:find('\xd5\xeb\xee\xef\xee\xea')
                                    local wL = farm.collect_linen  and txt2:find('\xb8\xed')
                                    if (wC or wL) and txt2:find('\xfd\xf2\xe0\xef\x20\x32') then
                                        local sec = txt2:match('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc%s+%d+:(%d+)')
                                        if sec then
                                            local s = tonumber(sec) or 99
                                            local min_part = txt2:match('\xce\xf1\xf2\xe0\xeb\xee\xf1\xfc%s+(%d+):')
                                            local m = tonumber(min_part) or 99
                                            if m == 0 and s <= 10 then
                                                local d = getDistanceBetweenCoords2d(mx2, my2, x2, y2)
                                                if d < bd then bd = d; best = {x2, y2, z2} end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        return best
                    end
                    local allBushes = findAllBushes()
                    if #allBushes > 0 then
                        local patrolIdx = 1
                        local patrolStop = false

                        while farm.running and not pause_bot and not patrolStop do
                            invalidateBushCache()

                            local ripe = findBestBush()
                            if ripe then
                                addLog('[Патруль] \xd1\xee\xe7\xf0\xe5\xeb \xea\xf3\xf1\xf2, \xe8\xe4\xf3!')
                                patrolStop = true
                                break
                            end

                            local soonRipe = findSoonRipeBush()
                            if soonRipe then
                                addLog('[Патруль] \xca\xf3\xf1\xf2 \xf1\xee\xe7\xf0\xe5\xe5\xf2 \xe2 10\xf1, \xe8\xe4\xf3!')
                                farm.target = soonRipe
                                movement.active = true
                                runToPoint(soonRipe[1], soonRipe[2], soonRipe[3])
                                movement.active = false
                                farm.target = nil
                                patrolStop = true
                                break
                            end

                            local b = allBushes[patrolIdx]
                            if b then
                                local px2, py2 = getCharCoordinates(PLAYER_PED)
                                if getDistanceBetweenCoords2d(px2, py2, b.x, b.y) > 1.5 then
                                    farm.target = {b.x, b.y, b.z}
                                    movement.active = true

                                    lua_thread.create(function()
                                        while movement.active and farm.running do
                                            wait(400)
                                            if not movement.active then break end
                                            invalidateBushCache()
                                            local ripe2 = findBestBush()
                                            if not ripe2 then ripe2 = findSoonRipeBush() end
                                            if ripe2 then
                                                patrolStop = true
                                                farm.running = false
                                                wait(50)
                                                farm.running = true
                                                movement.active = false
                                            end
                                        end
                                    end)

                                    runToPoint(b.x, b.y, b.z)
                                    movement.active = false
                                    farm.target = nil
                                    if patrolStop then break end
                                end
                                if not patrolStop and math.random(5) == 1 then
                                    local pauseEnd = os.clock() + math.random(2, 3)
                                    while os.clock() < pauseEnd and farm.running and not patrolStop and not pause_bot do
                                        wait(100)
                                    end
                                end
                                if patrolStop then break end
                            end

                            patrolIdx = patrolIdx + 1
                            if patrolIdx > #allBushes then
                                allBushes = findAllBushes()
                                patrolIdx = 1
                                if #allBushes == 0 then wait(800) end
                            end

                            wait(0)
                        end
                    else
                        wait(800)
                    end

                    is_patrolling = false
                else
                    wait(500)
                end
            end
        else
            farm.target=nil
            setGameKeyState(1,0)
            stopSprint()
            sprintActive=false
            wait(0)
        end
        wait(0)
    end
end
