script_name('ObjectMenu')
script_author('Victor Strand')
require('lib.moonloader')

local imgui    = require('mimgui')
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8

local ffi  = require 'ffi'
local faR  = require('fAwesome6')
local fa   = require('fAwesome6_solid')
local new  = imgui.new
local MDS  = MONET_DPI_SCALE or 1.0

local fMain = nil  -- основной шрифт с кириллицей + FA merge

-- Безопасные иконки (pcall — если иконки нет, пустая строка)
local function safeIcon(name)
    local ok, v = pcall(function() return fa[name] end)
    return (ok and v) or ''
end
local I = {}  -- таблица иконок для скрипта
-- заполняем после загрузки модуля
local function initIcons()
    I.list     = safeIcon('LIST')
    I.cube     = safeIcon('CUBE')
    I.plus     = safeIcon('PLUS')
    I.trash    = safeIcon('TRASH')
    I.copy     = safeIcon('COPY')
    I.pin      = safeIcon('LOCATION_DOT')
    I.rotate   = safeIcon('ROTATE')
    I.gear     = safeIcon('GEAR')
    I.sliders  = safeIcon('SLIDERS')
    I.arrow_u  = safeIcon('ARROW_UP')
    I.xmark    = safeIcon('XMARK')
    I.plane    = safeIcon('PAPER_PLANE')
    I.pen      = safeIcon('PEN')
    -- fallback Unicode символы если иконка не нашлась
    if I.list    == '' then I.list    = '*' end
    if I.cube    == '' then I.cube    = '#' end
    if I.plus    == '' then I.plus    = '+' end
    if I.trash   == '' then I.trash   = 'X' end
    if I.copy    == '' then I.copy    = '+' end
    if I.pin     == '' then I.pin     = '@' end
    if I.rotate  == '' then I.rotate  = 'O' end
    if I.gear    == '' then I.gear    = '*' end
    if I.sliders == '' then I.sliders = '~' end
    if I.arrow_u == '' then I.arrow_u = '^' end
    if I.xmark   == '' then I.xmark   = 'X' end
    if I.plane   == '' then I.plane   = '>' end
    if I.pen     == '' then I.pen     = '/' end
end
initIcons()

-- ─────────────────────────────────────────────
--  Android openLink
-- ─────────────────────────────────────────────
local _gta = nil
pcall(function()
    _gta = ffi.load('GTASA')
    ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
end)
local function openLink(url)
    if _gta then pcall(_gta._Z12AND_OpenLinkPKc, url) end
end

-- ─────────────────────────────────────────────
--  Chat helper
-- ─────────────────────────────────────────────
local function chatMsg(text, color)
    color = color or 0xFFFFFF
    sampAddChatMessage(text, color)
end

-- =============================================
--  ImGui Variables
-- =============================================
local window         = new.bool(false)
local selected       = 0
local add_name       = new.char[256]()
local show_add_modal = new.bool(false)

local editor = {
    name      = new.char[256](),
    model     = new.int(14467),
    posX      = new.float(0.0),
    posY      = new.float(0.0),
    posZ      = new.float(0.0),
    rotX      = new.float(0.0),
    rotY      = new.float(0.0),
    rotZ      = new.float(0.0),
    scale     = new.float(1.0),
    collision = new.bool(false),
    anim_mode  = new.int(0),
    anim_axis  = new.int(2),
    anim_speed = new.float(1.0),
    anim_range = new.float(45.0),
    move_mode  = new.int(0),
    move_dist  = new.float(2.0),
    move_speed = new.float(0.05),
    move_offset= new.float(0.0),
}

local axis_names      = {'X','Y','Z'}

-- =============================================
--  Config
-- =============================================
local config_dir  = getWorkingDirectory()..'/config/ObjectMenu'
local config_file = config_dir..'/settings.json'

-- =============================================
--  Theme palette — Arizona dark style (тёмная + акцент по цвету)
-- =============================================
-- bg, panel, border_a (прозрачность бордера), accent {r,g,b},
-- btn, btnH, btnA, frame, title_grad_left {r,g,b}
local themes = {
    { name=u8('\xca\xf0\xe0\xf1\xed\xfb\xe9'),
      bg={0.059,0.059,0.059},
      panel={0.082,0.082,0.082},
      frame={0.12,0.07,0.07},
      accent={1.0,0.30,0.30},
      btn={0.38,0.10,0.10}, btnH={0.50,0.15,0.15}, btnA={0.60,0.18,0.18},
      tgrad={0.11,0.16,0.22} },
    { name=u8('\xd1\xe8\xed\xe8\xe9'),
      bg={0.059,0.059,0.059},
      panel={0.082,0.082,0.082},
      frame={0.07,0.09,0.18},
      accent={0.40,0.65,1.0},
      btn={0.10,0.20,0.44}, btnH={0.14,0.28,0.58}, btnA={0.18,0.34,0.68},
      tgrad={0.11,0.16,0.22} },
    { name=u8('\xc7\xee\xeb\xee\xf2\xee'),
      bg={0.059,0.059,0.059},
      panel={0.082,0.082,0.082},
      frame={0.16,0.13,0.04},
      accent={0.96,0.80,0.25},
      btn={0.36,0.28,0.06}, btnH={0.48,0.38,0.10}, btnA={0.56,0.44,0.14},
      tgrad={0.11,0.16,0.22} },
    { name=u8('\xc7\xe5\xeb\xb8\xed\xfb\xe9'),
      bg={0.059,0.059,0.059},
      panel={0.082,0.082,0.082},
      frame={0.06,0.15,0.07},
      accent={0.28,0.85,0.35},
      btn={0.10,0.30,0.12}, btnH={0.14,0.42,0.16}, btnA={0.18,0.50,0.20},
      tgrad={0.11,0.16,0.22} },
    { name=u8('\xd1\xe5\xf0\xfb\xe9'),
      bg={0.059,0.059,0.059},
      panel={0.082,0.082,0.082},
      frame={0.14,0.14,0.14},
      accent={0.75,0.75,0.75},
      btn={0.22,0.22,0.22}, btnH={0.32,0.32,0.32}, btnA={0.40,0.40,0.40},
      tgrad={0.11,0.16,0.22} },
}
local current_theme = 1

-- dot colours for theme picker
local theme_dot = {
    {1.0,0.30,0.30},
    {0.40,0.65,1.0},
    {0.96,0.80,0.25},
    {0.28,0.85,0.35},
    {0.75,0.75,0.75},
}

-- =============================================
--  Projects
-- =============================================
local projects         = {}
local current_project  = 'default'
local show_proj_modal  = new.bool(false)
local new_proj_name    = new.char[64]()
local projects_dir     = config_dir..'/projects'

local function projectFile(name)
    return projects_dir..'/'..name..'.json'
end
local function list_file_for(name)
    return projectFile(name)
end
local list_file = list_file_for(current_project)

-- =============================================
--  Settings save/load
-- =============================================
local function saveSettings()
    local d = {theme=current_theme, project=current_project}
    local f = io.open(config_file,'w')
    if f then f:write(encodeJson(d)); f:flush(); f:close() end
end

local function loadSettings()
    if doesFileExist(config_file) then
        local f = io.open(config_file,'r')
        if f then
            local s=f:read('*a'); f:close()
            local ok,d = pcall(decodeJson,s)
            if ok and d then
                current_theme   = d.theme   or 1
                current_project = d.project or 'default'
            end
        end
    end
    list_file = list_file_for(current_project)
end

local function scanProjects()
    projects = {}
    table.insert(projects, 'default')
    local i = 0
    while true do
        i = i + 1
        local name = 'project'..i
        if doesFileExist(projectFile(name)) then
            local found = false
            for _,v in ipairs(projects) do if v==name then found=true; break end end
            if not found then table.insert(projects, name) end
        else
            break
        end
    end
    local found = false
    for _,v in ipairs(projects) do if v==current_project then found=true; break end end
    if not found then table.insert(projects, current_project) end
end

local list = {}

-- Runtime animation state
local anim_state = {}
local move_state = {}

-- =============================================
--  JSON
-- =============================================
function jsonSave(t, fname)
    fname = fname or list_file
    local s = {}
    for i,v in ipairs(t) do
        s[i] = {
            name=v.name, model=v.model,
            posX=v.posX, posY=v.posY, posZ=v.posZ,
            rotX=v.rotX, rotY=v.rotY, rotZ=v.rotZ,
            scale=v.scale, collision=v.collision,
            anim_mode=v.anim_mode or 0, anim_axis=v.anim_axis or 2,
            anim_speed=v.anim_speed or 1.0, anim_range=v.anim_range or 45.0,
            move_mode=v.move_mode or 0, move_dist=v.move_dist or 2.0,
            move_speed=v.move_speed or 0.05, move_offset=v.move_offset or 0.0,
        }
    end
    local f = io.open(fname,"w")
    if f then f:write(encodeJson(s)); f:flush(); f:close() end
end

function jsonRead(fname)
    fname = fname or list_file
    if not doesFileExist(fname) then return {} end
    local f = io.open(fname,"r")
    if f then local s=f:read("*a"); f:close(); return decodeJson(s) end
    return {}
end

-- =============================================
--  Tick — animations
-- =============================================
function tickAnimations()
    for i = 1, #list do
        local d = list[i]
        if not (d.handle and doesObjectExist(d.handle)) then goto cont end
        local mode = d.anim_mode or 0
        if mode ~= 0 then
            if not anim_state[i] then anim_state[i]={angle=0,dir=1} end
            local st = anim_state[i]
            local sp = d.anim_speed or 1.0
            local ax = d.anim_axis  or 2
            if mode == 1 then
                st.angle = (st.angle + sp) % 360
            else
                local rng = d.anim_range or 45.0
                st.angle = st.angle + sp * st.dir
                if st.angle >=  rng then st.angle=rng;  st.dir=-1 end
                if st.angle <= -rng then st.angle=-rng; st.dir= 1 end
            end
            local bx,by,bz = d.rotX or 0, d.rotY or 0, d.rotZ or 0
            if     ax==0 then setObjectRotation(d.handle, bx+st.angle, by, bz)
            elseif ax==1 then setObjectRotation(d.handle, bx, by+st.angle, bz)
            else              setObjectRotation(d.handle, bx, by, bz+st.angle) end
        end
        local mm = d.move_mode or 0
        if mm ~= 0 then
            if not move_state[i] then move_state[i]={offset=0,dir=1} end
            local ms  = move_state[i]
            local dst = d.move_dist  or 2.0
            local spd = d.move_speed or 0.05
            local off = d.move_offset or 0.0
            ms.offset = ms.offset + spd * ms.dir
            if ms.offset >= dst then ms.offset=dst; ms.dir=-1 end
            if ms.offset <= 0   then ms.offset=0;   ms.dir= 1 end
            local ox,oy,oz = d.posX or 0, d.posY or 0, d.posZ or 0
            if     mm==1 then setObjectCoordinates(d.handle, ox, oy, oz+ms.offset)
            elseif mm==2 then setObjectCoordinates(d.handle, ox+ms.offset+off, oy, oz)
            else              setObjectCoordinates(d.handle, ox, oy+ms.offset+off, oz) end
        end
        ::cont::
    end
end

-- =============================================
--  Main
-- =============================================
function main()
    while not isSampAvailable() do wait(200) end

    sampRegisterChatCommand('obj', function()
        window[0] = not window[0]
    end)

    if not doesDirectoryExist(getWorkingDirectory()..'/config') then
        createDirectory(getWorkingDirectory()..'/config')
    end
    if not doesDirectoryExist(config_dir) then createDirectory(config_dir) end
    if not doesDirectoryExist(projects_dir) then createDirectory(projects_dir) end

    loadSettings()
    scanProjects()
    list_file = list_file_for(current_project)

    if not doesFileExist(list_file) then
        jsonSave({{
            name='BigSmoke on grove street', model=14467,
            posX=2529, posY=-1675, posZ=20,
            rotX=0, rotY=0, rotZ=0, scale=1, collision=false,
            anim_mode=0, anim_axis=2, anim_speed=1.0, anim_range=45.0,
            move_mode=0, move_dist=2.0, move_speed=0.05,
        }}, list_file)
    end

    list = jsonRead(list_file)
    refreshObjects()

    lua_thread.create(function()
        while true do wait(0); tickAnimations() end
    end)

    chatMsg('[ObjectMenu] \xc7\xe0\xe3\xf0\xf3\xe6\xe5\xed! /obj | Victor Strand', 0xFFFFFF)
    wait(-1)
end

-- =============================================
--  Helper lambdas
-- =============================================
function loadToEditor(d)
    imgui.StrCopy(editor.name, d.name)
    editor.model[0]      = d.model
    editor.posX[0]       = d.posX
    editor.posY[0]       = d.posY
    editor.posZ[0]       = d.posZ
    editor.rotX[0]       = d.rotX
    editor.rotY[0]       = d.rotY
    editor.rotZ[0]       = d.rotZ
    editor.scale[0]      = d.scale
    editor.collision[0]  = d.collision
    editor.anim_mode[0]  = d.anim_mode  or 0
    editor.anim_axis[0]  = d.anim_axis  or 2
    editor.anim_speed[0] = d.anim_speed or 1.0
    editor.anim_range[0] = d.anim_range or 45.0
    editor.move_mode[0]  = d.move_mode  or 0
    editor.move_dist[0]  = d.move_dist  or 2.0
    editor.move_speed[0] = d.move_speed or 0.05
    editor.move_offset[0]= d.move_offset or 0.0
end

function saveAndRefresh()
    if list[selected] then
        local d = list[selected]
        d.name        = ffi.string(editor.name)
        d.model       = editor.model[0]
        d.posX        = editor.posX[0]; d.posY = editor.posY[0]; d.posZ = editor.posZ[0]
        d.rotX        = editor.rotX[0]; d.rotY = editor.rotY[0]; d.rotZ = editor.rotZ[0]
        d.scale       = editor.scale[0]
        d.collision   = editor.collision[0]
        d.anim_mode   = editor.anim_mode[0];  d.anim_axis  = editor.anim_axis[0]
        d.anim_speed  = editor.anim_speed[0]; d.anim_range = editor.anim_range[0]
        d.move_mode   = editor.move_mode[0];  d.move_dist  = editor.move_dist[0]
        d.move_speed  = editor.move_speed[0]; d.move_offset= editor.move_offset[0]
        jsonSave(list, list_file)
        refreshObjects()
    end
end

function refreshObjects()
    if list then
        for i=1,#list do
            local d = list[i]
            if d.handle and doesObjectExist(d.handle) then deleteObject(d.handle) end
            d.handle = createObject(d.model, d.posX, d.posY, d.posZ)
            if d.handle and doesObjectExist(d.handle) then
                setObjectRotation(d.handle, d.rotX, d.rotY, d.rotZ)
                setObjectScale(d.handle, d.scale)
                setObjectCollision(d.handle, d.collision)
            end
            anim_state[i] = nil
            move_state[i] = nil
        end
    end
end

function onScriptTerminate(s,q)
    if s == thisScript() then
        for i=1,#list do
            local d = list[i]
            if d.handle and doesObjectExist(d.handle) then deleteObject(d.handle) end
        end
    end
end

-- =============================================
--  OnInitialize — точно как в TruckHelper
-- =============================================
imgui.OnInitialize(function()
    imgui.SwitchContext()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)

    local io2    = imgui.GetIO()
    local ranges = io2.Fonts:GetGlyphRangesCyrillic()
    local fpath  = getWorkingDirectory() .. '/../trebucbd.ttf'

    if doesFileExist(fpath) then
        fMain = io2.Fonts:AddFontFromFileTTF(fpath, 14 * MDS, nil, ranges)
    end

    -- FA merge — всегда, даже если основной шрифт не загрузился
    local cfg = imgui.ImFontConfig()
    cfg.MergeMode  = true
    cfg.PixelSnapH = true
    local r = imgui.new.ImWchar[3](faR.min_range, faR.max_range, 0)
    io2.Fonts:AddFontFromMemoryCompressedBase85TTF(
        faR.get_font_data_base85('solid'), 14 * MDS, cfg, r)

    -- Стили после ScaleAllSizes
    local st = imgui.GetStyle()
    st.WindowPadding    = imgui.ImVec2(0, 0)
    st.WindowRounding   = 8  * MDS
    st.ChildRounding    = 5  * MDS
    st.FramePadding     = imgui.ImVec2(6 * MDS, 3 * MDS)
    st.FrameRounding    = 4  * MDS
    st.ItemSpacing      = imgui.ImVec2(6 * MDS, 5 * MDS)
    st.IndentSpacing    = 8  * MDS
    st.ScrollbarSize    = 13 * MDS
    st.GrabMinSize      = 18 * MDS
    st.WindowBorderSize = 1
    st.ChildBorderSize  = 1
end)

-- =============================================
--  ImGui — Arizona dark style
-- =============================================

imgui.OnFrame(function() return window[0] end,
function(self)

    if fMain then imgui.PushFont(fMain) end

    local th = themes[current_theme]
    local v4 = imgui.ImVec4
    local v2 = imgui.ImVec2
    local st = imgui.GetStyle()
    local col = st.Colors
    local c = imgui.Col

    -- ── Live colour palette ─────────────────────────────────────
    local bg  = th.bg
    local pn  = th.panel
    local fr  = th.frame
    local ac  = th.accent
    local bt  = th.btn
    local bh  = th.btnH
    local ba  = th.btnA

    -- border = accent с низкой прозрачностью
    col[c.WindowBg]             = v4(bg[1],  bg[2],  bg[3],  0.97)
    col[c.ChildBg]              = v4(pn[1],  pn[2],  pn[3],  1)
    col[c.PopupBg]              = v4(bg[1],  bg[2],  bg[3],  0.96)
    col[c.Border]               = v4(ac[1],  ac[2],  ac[3],  0.18)
    col[c.BorderShadow]         = v4(0,0,0,0)
    col[c.FrameBg]              = v4(fr[1],  fr[2],  fr[3],  1)
    col[c.FrameBgHovered]       = v4(fr[1]+.06, fr[2]+.04, fr[3]+.04, 1)
    col[c.FrameBgActive]        = v4(fr[1]+.10, fr[2]+.06, fr[3]+.06, 1)
    col[c.TitleBg]              = v4(bg[1],bg[2],bg[3],1)
    col[c.TitleBgActive]        = v4(bg[1],bg[2],bg[3],1)
    col[c.TitleBgCollapsed]     = v4(bg[1],bg[2],bg[3],0.8)
    col[c.ScrollbarBg]          = v4(pn[1],pn[2],pn[3],1)
    col[c.ScrollbarGrab]        = v4(ac[1]*.5, ac[2]*.5, ac[3]*.5, 1)
    col[c.ScrollbarGrabHovered] = v4(ac[1]*.7, ac[2]*.7, ac[3]*.7, 1)
    col[c.ScrollbarGrabActive]  = v4(ac[1],    ac[2],    ac[3],    1)
    col[c.CheckMark]            = v4(ac[1], ac[2], ac[3], 1)
    col[c.SliderGrab]           = v4(bt[1], bt[2], bt[3], 1)
    col[c.SliderGrabActive]     = v4(ba[1], ba[2], ba[3], 1)
    col[c.Button]               = v4(bt[1], bt[2], bt[3], 1)
    col[c.ButtonHovered]        = v4(bh[1], bh[2], bh[3], 1)
    col[c.ButtonActive]         = v4(ba[1], ba[2], ba[3], 1)
    col[c.Header]               = v4(bt[1], bt[2], bt[3], 1)
    col[c.HeaderHovered]        = v4(bh[1], bh[2], bh[3], 1)
    col[c.HeaderActive]         = v4(ba[1], ba[2], ba[3], 1)
    col[c.Separator]            = v4(ac[1], ac[2], ac[3], 0.20)
    col[c.SeparatorHovered]     = v4(ac[1], ac[2], ac[3], 0.40)
    col[c.SeparatorActive]      = v4(ac[1], ac[2], ac[3], 0.70)
    col[c.ResizeGrip]           = v4(bt[1], bt[2], bt[3], 0.4)
    col[c.ResizeGripHovered]    = v4(bh[1], bh[2], bh[3], 0.7)
    col[c.ResizeGripActive]     = v4(ba[1], ba[2], ba[3], 1)
    col[c.Text]                 = v4(0.93, 0.93, 0.93, 1)
    col[c.TextDisabled]         = v4(0.40, 0.40, 0.40, 1)
    col[c.TextSelectedBg]       = v4(bt[1], bt[2], bt[3], 0.85)
    col[c.ModalWindowDimBg]     = v4(0,0,0,0.65)

    -- ── Window size ─────────────────────────────────────────────
    local resX, resY = getScreenResolution()
    -- -20% от предыдущего 820x580
    local BASE_W = 594
    local BASE_H = 418
    local winW  = math.min(BASE_W * MDS, resX - 16)
    local winH  = math.min(BASE_H * MDS, resY - 16)
    local listW = math.floor(winW * 0.37)

    imgui.SetNextWindowPos(v2(resX/2 - winW/2, resY/2 - winH/2), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(v2(winW, winH), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSizeConstraints(v2(560*MDS, 420*MDS), v2(resX, resY))

    local flags = imgui.WindowFlags.NoTitleBar
    if imgui.Begin('##objmenu', window, flags) then

        winW = imgui.GetWindowWidth()
        winH = imgui.GetWindowHeight()
        listW = math.floor(winW * 0.36)

        local dl  = imgui.GetWindowDrawList()
        local wp  = imgui.GetWindowPos()
        local HDR = math.floor(38*MDS)  -- высота шапки

        -- ── DrawList: шапка-градиент ────────────────────────────
        -- Левая часть (тёмно-синяя), правая (тёмно-красная/акцент)
        local tg_left  = th.tgrad   -- {r,g,b}
        local tg_right = {ac[1]*0.55, ac[2]*0.10, ac[3]*0.10}
        local tg_mid   = {bg[1], bg[2], bg[3]}

        local function U32(r,g,b,a)
            a = a or 1.0
            local ai = math.floor(a*255+0.5)
            local ri = math.floor(r*255+0.5)
            local gi = math.floor(g*255+0.5)
            local bi = math.floor(b*255+0.5)
            return ai*0x1000000 + ri*0x10000 + gi*0x100 + bi  -- ARGB
        end

        -- Исправленный формат ABGR для ImDrawList
        local function ABGR(r,g,b,a)
            a = a or 1.0
            return math.floor(a*255+0.5)*0x1000000
                 + math.floor(b*255+0.5)*0x10000
                 + math.floor(g*255+0.5)*0x100
                 + math.floor(r*255+0.5)
        end

        -- Рисуем шапку через два прямоугольника с цветами по углам
        local x0 = wp.x; local y0 = wp.y
        local x1 = wp.x + winW; local y1 = wp.y + HDR

        local colL = ABGR(tg_left[1],  tg_left[2],  tg_left[3],  1)
        local colM = ABGR(tg_mid[1],   tg_mid[2],   tg_mid[3],   1)
        local colR = ABGR(ac[1]*0.50,  ac[2]*0.04,  ac[3]*0.04,  1)

        -- левая половина: от tg_left до tg_mid
        dl:AddRectFilledMultiColor(
            imgui.ImVec2(x0, y0), imgui.ImVec2(x0 + winW/2, y1),
            colL, colM, colM, colL)
        -- правая половина: от tg_mid до акцент
        dl:AddRectFilledMultiColor(
            imgui.ImVec2(x0 + winW/2, y0), imgui.ImVec2(x1, y1),
            colM, colR, colR, colM)

        -- Нижняя граница шапки
        dl:AddLine(imgui.ImVec2(x0, y1), imgui.ImVec2(x1, y1),
            ABGR(ac[1], ac[2], ac[3], 0.25), 1*MDS)

        -- Заголовок текстом (поверх DrawList через ImGui)
        imgui.SetCursorPos(v2(0, 0))
        imgui.Dummy(v2(winW, HDR))  -- занимаем место под шапку

        -- Текст поверх: ставим курсор обратно
        local titleText = u8('OBJECT MENU  |  by Victor Strand  ')
        local proText   = u8('PRO')
        local tw   = imgui.CalcTextSize(titleText).x
        local tpw  = imgui.CalcTextSize(proText).x
        local lineH = imgui.GetTextLineHeight()
        local tyPos = (HDR - lineH) / 2
        imgui.SetCursorPos(v2(winW/2 - (tw + tpw)/2, tyPos))
        imgui.TextColored(v4(0.93,0.93,0.93,1), titleText)
        imgui.SameLine(0, 0)
        imgui.SetCursorPosY(tyPos)
        imgui.TextColored(v4(0.96, 0.80, 0.10, 1), proText)

        -- Кнопка закрытия [X] справа в шапке
        local closeW = 22*MDS
        imgui.SetCursorPos(v2(winW - closeW - 8*MDS, (HDR - closeW)/2))
        imgui.PushStyleColor(c.Button,        v4(1,1,1,0.08))
        imgui.PushStyleColor(c.ButtonHovered, v4(ac[1], ac[2], ac[3], 0.85))
        imgui.PushStyleColor(c.ButtonActive,  v4(ac[1], ac[2], ac[3], 1))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 4*MDS)
        if imgui.Button('X##close', v2(closeW, closeW)) then
            window[0] = false
        end
        imgui.PopStyleVar()
        imgui.PopStyleColor(3)

        -- ── Content area starts after header ────────────────────
        local PAD   = 8*MDS
        local contentY = HDR + PAD
        local contentH = winH - contentY - PAD

        -- ────────────────────────────────────────────────────────
        --  LEFT PANEL
        -- ────────────────────────────────────────────────────────
        local FOOTER_H = 172*MDS   -- высота нижней части левой панели
        local listAreaH = contentH - FOOTER_H

        imgui.SetCursorPos(v2(PAD, contentY))
        imgui.PushStyleColor(c.ChildBg, v4(pn[1], pn[2], pn[3], 1))
        imgui.PushStyleColor(c.Border,  v4(ac[1], ac[2], ac[3], 0.15))
        imgui.BeginChild('##list', v2(listW, listAreaH), true)
            -- Метка секции
            imgui.PushStyleColor(c.Text, v4(ac[1], ac[2], ac[3], 0.70))
            imgui.Text(I.list..'  '..u8('\xce\xc1\xda\xc5\xca\xd2\xdb'))
            imgui.PopStyleColor()
            imgui.Separator()
            imgui.Spacing()

            for i = 1, #list do
                local d = list[i]
                if d.model then
                    local icon = ''
                    if     (d.anim_mode or 0)==1 then icon=icon..' [R]'
                    elseif (d.anim_mode or 0)==2 then icon=icon..' [S]' end
                    local mm = d.move_mode or 0
                    if     mm==1 then icon=icon..' [Z]'
                    elseif mm==2 then icon=icon..' [X]'
                    elseif mm==3 then icon=icon..' [Y]' end

                    -- Выделенный элемент — с акцентом
                    if selected == i then
                        imgui.PushStyleColor(c.Header,        v4(bt[1], bt[2], bt[3], 1))
                        imgui.PushStyleColor(c.HeaderHovered, v4(bh[1], bh[2], bh[3], 1))
                        imgui.PushStyleColor(c.HeaderActive,  v4(ba[1], ba[2], ba[3], 1))
                    else
                        imgui.PushStyleColor(c.Header,        v4(0,0,0,0))
                        imgui.PushStyleColor(c.HeaderHovered, v4(bt[1]*.5, bt[2]*.5, bt[3]*.5, 0.6))
                        imgui.PushStyleColor(c.HeaderActive,  v4(bt[1], bt[2], bt[3], 0.8))
                    end

                    if imgui.Selectable(
                        i..'.  '..d.name..' ['..d.model..']'..icon..'##sel'..i,
                        selected==i,
                        imgui.SelectableFlags.None,
                        v2(0, 30*MDS)
                    ) then
                        selected = i
                        loadToEditor(d)
                    end
                    imgui.PopStyleColor(3)
                end
            end
        imgui.EndChild()
        imgui.PopStyleColor(2)

        -- ── Нижняя левая панель (кнопки + проект + тема + TG) ──
        local bottomY = contentY + listAreaH + 4*MDS

        -- ADD OBJECT
        imgui.SetCursorPos(v2(PAD, bottomY))
        imgui.PushStyleColor(c.Button,        v4(ac[1]*0.45, ac[2]*0.06, ac[3]*0.06, 1))
        imgui.PushStyleColor(c.ButtonHovered, v4(ac[1]*0.65, ac[2]*0.10, ac[3]*0.10, 1))
        imgui.PushStyleColor(c.ButtonActive,  v4(ac[1]*0.80, ac[2]*0.14, ac[3]*0.14, 1))
        if imgui.Button(I.plus..' '..u8('\xc4\xce\xc1\xc0\xc2\xc8\xd2\xdc \xce\xc1\xda\xc5\xca\xd2'), v2(listW, 32*MDS)) then
            imgui.StrCopy(add_name, u8('Object #'..tostring(#list+1)))
            show_add_modal[0] = true
        end
        imgui.PopStyleColor(3)

        -- Add popup
        if show_add_modal[0] then imgui.OpenPopup(u8('\xcd\xee\xe2\xfb\xe9 \xee\xe1\xfa\xe5\xea\xf2')) end
        if imgui.BeginPopupModal(u8('\xcd\xee\xe2\xfb\xe9 \xee\xe1\xfa\xe5\xea\xf2'), show_add_modal, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.Text(u8('\xcd\xe0\xe7\xe2\xe0\xed\xe8\xe5:'))
            imgui.SetNextItemWidth(320*MDS)
            imgui.InputText('##addname', add_name, 256)
            imgui.Spacing()
            if imgui.Button(u8('\xc4\xce\xc1\xc0\xc2\xc8\xd2\xdc'), v2(200*MDS, 38*MDS)) then
                local x,y,z = getCharCoordinates(PLAYER_PED)
                local nm = ffi.string(add_name)
                table.insert(list,{
                    name=nm, model=14467,
                    posX=x, posY=y, posZ=z,
                    rotX=0, rotY=0, rotZ=0, scale=1, collision=false,
                    anim_mode=0, anim_axis=2, anim_speed=1.0, anim_range=45.0,
                    move_mode=0, move_dist=2.0, move_speed=0.05,
                })
                jsonSave(list, list_file); refreshObjects()
                show_add_modal[0] = false
            end
            imgui.SameLine()
            if imgui.Button(u8('\xce\xd2\xcc\xc5\xcd\xc0'), v2(110*MDS, 38*MDS)) then show_add_modal[0]=false end
            imgui.EndPopup()
        end

        -- ── Проект ──────────────────────────────────────────────
        imgui.SetCursorPos(v2(PAD, bottomY + 38*MDS))
        imgui.PushStyleColor(c.Text, v4(ac[1], ac[2], ac[3], 0.65))
        imgui.Text(I.gear..'  '..u8('\xcf\xd0\xce\xc5\xca\xd2'))
        imgui.PopStyleColor()

        imgui.SetCursorPos(v2(PAD, bottomY + 55*MDS))
        imgui.SetNextItemWidth(listW - 60*MDS)
        imgui.PushStyleColor(c.FrameBg,        v4(fr[1], fr[2], fr[3], 1))
        imgui.PushStyleColor(c.FrameBgHovered, v4(fr[1]+.05, fr[2]+.03, fr[3]+.03, 1))
        if imgui.BeginCombo('##proj', current_project) then
            for _,pname in ipairs(projects) do
                local sel = (pname == current_project)
                if imgui.Selectable(pname..'##psel', sel) and pname ~= current_project then
                    jsonSave(list, list_file)
                    current_project = pname
                    list_file = list_file_for(current_project)
                    if not doesFileExist(list_file) then jsonSave({}, list_file) end
                    list = jsonRead(list_file)
                    selected = 0; refreshObjects(); saveSettings()
                end
                if sel then imgui.SetItemDefaultFocus() end
            end
            imgui.EndCombo()
        end
        imgui.PopStyleColor(2)

        imgui.SameLine(0, 4*MDS)
        -- Кнопка + новый проект
        if imgui.Button('+##np', v2(26*MDS, 26*MDS)) then
            imgui.StrCopy(new_proj_name, 'project'..tostring(#projects+1))
            show_proj_modal[0] = true
        end
        imgui.SameLine(0, 2*MDS)
        -- Удалить проект
        local canDelete = (current_project ~= 'default') and (#projects > 1)
        imgui.PushStyleColor(c.Button,        canDelete and v4(ba[1],ba[2]*0.3,ba[3]*0.3,1) or v4(0.18,0.08,0.08,1))
        imgui.PushStyleColor(c.ButtonHovered, canDelete and v4(1,0.2,0.2,1) or v4(0.18,0.08,0.08,1))
        imgui.PushStyleColor(c.ButtonActive,  canDelete and v4(1,0.1,0.1,1) or v4(0.18,0.08,0.08,1))
        if imgui.Button('X##dp', v2(22*MDS, 26*MDS)) and canDelete then
            local delFile = list_file_for(current_project)
            for i=1,#list do local d=list[i]; if d.handle and doesObjectExist(d.handle) then deleteObject(d.handle) end end
            local f=io.open(delFile,'w'); if f then f:write('[]'); f:flush(); f:close() end
            for idx,v in ipairs(projects) do if v==current_project then table.remove(projects,idx); break end end
            current_project='default'; list_file=list_file_for(current_project)
            if not doesFileExist(list_file) then jsonSave({},list_file) end
            list=jsonRead(list_file); selected=0; refreshObjects(); saveSettings()
        end
        imgui.PopStyleColor(3)

        -- Popup нового проекта
        if show_proj_modal[0] then imgui.OpenPopup(u8('\xcd\xee\xe2\xfb\xe9 \xef\xf0\xee\xe5\xea\xf2')) end
        if imgui.BeginPopupModal(u8('\xcd\xee\xe2\xfb\xe9 \xef\xf0\xee\xe5\xea\xf2'), show_proj_modal, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.Text(u8('\xcd\xe0\xe7\xe2\xe0\xed\xe8\xe5 \xef\xf0\xee\xe5\xea\xf2\xe0:'))
            imgui.SetNextItemWidth(260*MDS)
            imgui.InputText('##newproj', new_proj_name, 64)
            imgui.Spacing()
            if imgui.Button(u8('\xd1\xce\xc7\xc4\xc0\xd2\xdc'), v2(160*MDS, 38*MDS)) then
                local nm = ffi.string(new_proj_name)
                if nm ~= '' then
                    jsonSave(list, list_file); current_project=nm
                    list_file=list_file_for(nm); jsonSave({},list_file)
                    list={}; selected=0; refreshObjects(); scanProjects(); saveSettings()
                    show_proj_modal[0]=false
                end
            end
            imgui.SameLine()
            if imgui.Button(u8('\xce\xd2\xcc\xc5\xcd\xc0'), v2(110*MDS, 38*MDS)) then show_proj_modal[0]=false end
            imgui.EndPopup()
        end

        -- ── Выбор темы (цветные кнопки) ─────────────────────────
        imgui.SetCursorPos(v2(PAD, bottomY + 86*MDS))
        imgui.PushStyleColor(c.Text, v4(ac[1], ac[2], ac[3], 0.65))
        imgui.Text(u8('\xd2\xc5\xcc\xc0'))
        imgui.PopStyleColor()

        -- Короткие имена тем (ASCII, без кириллицы — рисуются всегда)
        local theme_short = {'Red','Blue','Gold','Green','Gray'}

        imgui.SetCursorPos(v2(PAD, bottomY + 102*MDS))
        local dotW = math.floor((listW - (4*(#themes-1))) / #themes)
        for ti=1,#themes do
            local dc = theme_dot[ti]
            local isActive = (current_theme == ti)
            local alpha = isActive and 1.0 or 0.28
            local tAlpha = isActive and 1.0 or 0.55
            imgui.PushStyleColor(c.Button,        v4(dc[1]*alpha, dc[2]*alpha, dc[3]*alpha, 1))
            imgui.PushStyleColor(c.ButtonHovered, v4(dc[1]*0.75,  dc[2]*0.75,  dc[3]*0.75,  1))
            imgui.PushStyleColor(c.ButtonActive,  v4(dc[1],       dc[2],       dc[3],       1))
            imgui.PushStyleColor(c.Text,          v4(1, 1, 1, tAlpha))
            local lbl = theme_short[ti]..'##t'..ti
            if imgui.Button(lbl, v2(dotW, 22*MDS)) then
                current_theme = ti; saveSettings()
            end
            imgui.PopStyleColor(4)
            if ti < #themes then imgui.SameLine(0, 4*MDS) end
        end

        -- ── TG кнопки ────────────────────────────────────────────
        local tgY = bottomY + 132*MDS
        local tgW = math.floor((listW - 4*MDS) / 2)

        imgui.SetCursorPos(v2(PAD, tgY))
        imgui.PushStyleColor(c.Button,        v4(0.10, 0.30, 0.44, 1))
        imgui.PushStyleColor(c.ButtonHovered, v4(0.14, 0.42, 0.60, 1))
        imgui.PushStyleColor(c.ButtonActive,  v4(0.18, 0.52, 0.72, 1))
        if imgui.Button(I.plane..' @victor_st0', v2(tgW, 28*MDS)) then
            openLink('https://t.me/victor_st0')
        end
        imgui.PopStyleColor(3)

        imgui.SameLine(0, 4*MDS)
        imgui.PushStyleColor(c.Button,        v4(0.10, 0.30, 0.44, 1))
        imgui.PushStyleColor(c.ButtonHovered, v4(0.14, 0.42, 0.60, 1))
        imgui.PushStyleColor(c.ButtonActive,  v4(0.18, 0.52, 0.72, 1))
        if imgui.Button(I.plane..' strand_scripts', v2(tgW, 28*MDS)) then
            openLink('https://t.me/strand_scripts')
        end
        imgui.PopStyleColor(3)

        -- ────────────────────────────────────────────────────────
        --  RIGHT PANEL (Editor)
        -- ────────────────────────────────────────────────────────
        local edX  = PAD + listW + PAD
        local edW  = winW - edX - PAD
        local edH  = contentH

        imgui.SetCursorPos(v2(edX, contentY))
        imgui.PushStyleColor(c.ChildBg, v4(pn[1], pn[2], pn[3], 1))
        imgui.PushStyleColor(c.Border,  v4(ac[1], ac[2], ac[3], 0.15))
        imgui.BeginChild('##editor', v2(edW, edH), true)

        if selected ~= 0 and list[selected] then

            local IW = edW - 20*MDS  -- ширина для виджетов

            -- ── Секция: Основное ────────────────────────────────
            imgui.PushStyleColor(c.Text, v4(ac[1], ac[2], ac[3], 0.70))
            imgui.Text(I.cube..'  '..u8('\xce\xd1\xcd\xce\xc2\xcd\xce\xc5'))
            imgui.PopStyleColor()
            imgui.Separator(); imgui.Spacing()

            -- Название
            imgui.Text(u8('\xcd\xe0\xe7\xe2\xe0\xed\xe8\xe5:'))
            imgui.SameLine(120*MDS)
            imgui.SetNextItemWidth(IW - 120*MDS)
            if imgui.InputText('##name', editor.name, 256) then saveAndRefresh() end

            -- Модель
            imgui.Text(u8('\xcc\xee\xe4\xe5\xeb\xfc ID:'))
            imgui.SameLine(120*MDS)
            imgui.SetNextItemWidth(IW - 120*MDS)
            if imgui.InputInt('##model', editor.model) then saveAndRefresh() end

            imgui.Spacing()

            -- ── Секция: Позиция ──────────────────────────────────
            imgui.PushStyleColor(c.Text, v4(ac[1], ac[2], ac[3], 0.70))
            imgui.Text(I.pin..'  '..u8('\xcf\xce\xc7\xc8\xd6\xc8\xdf'))
            imgui.PopStyleColor()
            imgui.Separator(); imgui.Spacing()

            local function posRow(lbl, val, id, minv, maxv)
                imgui.Text(lbl)
                imgui.SameLine(80*MDS)
                imgui.SetNextItemWidth(IW - 80*MDS - 70*MDS)
                if imgui.InputFloat('##pos'..id, val, 0, 0, '%.1f') then saveAndRefresh() end
                imgui.SameLine(0, 4*MDS)
                imgui.PushStyleColor(c.Button,        v4(bt[1], bt[2], bt[3], 1))
                imgui.PushStyleColor(c.ButtonHovered, v4(bh[1], bh[2], bh[3], 1))
                imgui.PushStyleColor(c.ButtonActive,  v4(ba[1], ba[2], ba[3], 1))
                if imgui.Button('+##p'..id, v2(30*MDS, 26*MDS)) then val[0]=val[0]+0.1; saveAndRefresh() end
                imgui.SameLine(0, 2*MDS)
                if imgui.Button('-##p'..id, v2(30*MDS, 26*MDS)) then val[0]=val[0]-0.1; saveAndRefresh() end
                imgui.PopStyleColor(3)
            end

            posRow('X:', editor.posX, 'x')
            posRow('Y:', editor.posY, 'y')
            posRow('Z:', editor.posZ, 'z', -100, 1000)

            imgui.Spacing()
            imgui.PushStyleColor(c.Button,        v4(bt[1]*0.7, bt[2]*0.7, bt[3]*0.7, 1))
            imgui.PushStyleColor(c.ButtonHovered, v4(bh[1], bh[2], bh[3], 1))
            imgui.PushStyleColor(c.ButtonActive,  v4(ba[1], ba[2], ba[3], 1))
            if imgui.Button(I.pin..' '..u8('\xcd\xc0 \xcc\xce\xde \xcf\xce\xc7\xc8\xd6\xc8\xde'), v2(-1, 30*MDS)) then
                editor.posX[0],editor.posY[0],editor.posZ[0] = getCharCoordinates(PLAYER_PED)
                saveAndRefresh()
            end
            imgui.PopStyleColor(3)

            imgui.Spacing()

            -- ── Секция: Вращение/Масштаб ────────────────────────
            imgui.PushStyleColor(c.Text, v4(ac[1], ac[2], ac[3], 0.70))
            imgui.Text(I.rotate..'  '..u8('\xd3\xc3\xce\xcb / \xcc\xc0\xd1\xd8\xd2\xc0\xc1'))
            imgui.PopStyleColor()
            imgui.Separator(); imgui.Spacing()

            local function rotRow(lbl, val, id)
                imgui.Text(lbl)
                imgui.SameLine(80*MDS)
                imgui.SetNextItemWidth(IW - 80*MDS)
                if imgui.SliderFloat('##rot'..id, val, 0, 360, '%.1f') then saveAndRefresh() end
            end
            rotRow('Rot X:', editor.rotX, 'x')
            rotRow('Rot Y:', editor.rotY, 'y')
            rotRow('Rot Z:', editor.rotZ, 'z')

            imgui.Text(u8('\xcc\xe0\xf1\xf8\xf2\xe0\xe1:'))
            imgui.SameLine(80*MDS)
            imgui.SetNextItemWidth(IW - 80*MDS)
            if imgui.SliderFloat('##scale', editor.scale, 0.1, 10, '%.2f') then saveAndRefresh() end

            if imgui.Checkbox(u8('\xca\xee\xeb\xeb\xe8\xe7\xe8\xff'), editor.collision) then saveAndRefresh() end

            imgui.Spacing()

            -- ── Секция: Движение ─────────────────────────────────
            imgui.PushStyleColor(c.Text, v4(0.30, 1.0, 0.50, 0.80))
            imgui.Text(I.arrow_u..'  '..u8('\xc4\xc2\xc8\xc6\xc5\xcd\xc8\xc5'))
            imgui.PopStyleColor()
            imgui.Separator(); imgui.Spacing()

            local mm = editor.move_mode[0]
            local modeLabels = {u8('\xd1\xd2\xce\xcf'), u8('\xc2\xc2\xc5\xd0\xd5/\xc2\xcd\xc8\xc7'), u8('\xd1\xd2\xce\xd0\xce\xcd\xc0 X'), u8('\xd1\xd2\xce\xd0\xce\xcd\xc0 Y')}
            local modeColors = {
                v4(0.3,0.3,0.3,1),
                v4(0.10,0.50,0.15,1),
                v4(0.10,0.30,0.70,1),
                v4(0.55,0.28,0.05,1),
            }
            local mW = math.floor((IW - 6*MDS) / 4)
            for mi=0,3 do
                local isA = (mm == mi)
                local mc  = modeColors[mi+1]
                if isA then
                    imgui.PushStyleColor(c.Button, mc)
                    imgui.PushStyleColor(c.ButtonHovered, v4(mc.x+.10, mc.y+.05, mc.z+.05, 1))
                    imgui.PushStyleColor(c.ButtonActive,  v4(mc.x+.15, mc.y+.08, mc.z+.08, 1))
                else
                    imgui.PushStyleColor(c.Button,        v4(0.14,0.14,0.14,1))
                    imgui.PushStyleColor(c.ButtonHovered, v4(mc.x*.55, mc.y*.55, mc.z*.55, 1))
                    imgui.PushStyleColor(c.ButtonActive,  v4(mc.x*.80, mc.y*.80, mc.z*.80, 1))
                end
                if imgui.Button(modeLabels[mi+1]..'##mv'..mi, v2(mW, 28*MDS)) then
                    editor.move_mode[0]=mi
                    if mi==0 then move_state[selected]=nil else move_state[selected]={offset=0,dir=1} end
                    saveAndRefresh()
                end
                imgui.PopStyleColor(3)
                if mi < 3 then imgui.SameLine(0, 2*MDS) end
            end

            imgui.Spacing()
            imgui.Text(u8('\xc4\xe8\xf1\xf2\xe0\xed\xf6\xe8\xff:'))
            imgui.SameLine(120*MDS); imgui.SetNextItemWidth(IW - 120*MDS)
            if imgui.SliderFloat('##mdist', editor.move_dist, 0.5, 20.0, '%.1f') then
                move_state[selected]={offset=0,dir=1}; saveAndRefresh()
            end
            imgui.Text(u8('\xd1\xea\xee\xf0\xee\xf1\xf2\xfc:'))
            imgui.SameLine(120*MDS); imgui.SetNextItemWidth(IW - 120*MDS)
            if imgui.SliderFloat('##mspd', editor.move_speed, 0.01, 1.0, '%.3f') then saveAndRefresh() end
            imgui.Text(u8('\xd1\xec\xe5\xf9\xe5\xed\xe8\xe5:'))
            imgui.SameLine(120*MDS); imgui.SetNextItemWidth(IW - 120*MDS)
            if imgui.SliderFloat('##moff', editor.move_offset, -20.0, 20.0, '%.1f') then
                move_state[selected]={offset=0,dir=1}; saveAndRefresh()
            end

            imgui.Spacing()

            -- ── Секция: Анимация вращения ────────────────────────
            imgui.PushStyleColor(c.Text, v4(1.0, 0.40, 0.40, 0.80))
            imgui.Text(I.rotate..'  '..u8('\xc0\xcd\xc8\xcc\xc0\xd6\xc8\xdf \xc2\xd0\xc0\xd9\xc5\xcd\xc8\xdf'))
            imgui.PopStyleColor()
            imgui.Separator(); imgui.Spacing()

            local am = editor.anim_mode[0]
            local animLabels  = {u8('\xd1\xd2\xce\xcf'), u8('SPIN 360'), u8('SWING')}
            local animColors  = {
                v4(0.3,0.3,0.3,1),
                v4(0.10,0.35,0.70,1),
                v4(0.60,0.34,0.05,1),
            }
            local aW = math.floor((IW - 4*MDS) / 3)
            for ai=0,2 do
                local isA = (am == ai)
                local mc  = animColors[ai+1]
                if isA then
                    imgui.PushStyleColor(c.Button,        mc)
                    imgui.PushStyleColor(c.ButtonHovered, v4(mc.x+.10, mc.y+.05, mc.z+.05, 1))
                    imgui.PushStyleColor(c.ButtonActive,  v4(mc.x+.15, mc.y+.08, mc.z+.08, 1))
                else
                    imgui.PushStyleColor(c.Button,        v4(0.14,0.14,0.14,1))
                    imgui.PushStyleColor(c.ButtonHovered, v4(mc.x*.55, mc.y*.55, mc.z*.55, 1))
                    imgui.PushStyleColor(c.ButtonActive,  v4(mc.x*.80, mc.y*.80, mc.z*.80, 1))
                end
                if imgui.Button(animLabels[ai+1]..'##am'..ai, v2(aW, 28*MDS)) then
                    editor.anim_mode[0]=ai
                    if ai==0 then anim_state[selected]=nil else anim_state[selected]={angle=0,dir=1} end
                    saveAndRefresh()
                end
                imgui.PopStyleColor(3)
                if ai < 2 then imgui.SameLine(0, 2*MDS) end
            end

            imgui.Spacing()
            -- Ось вращения
            imgui.Text(u8('\xce\xf1\xfc:'))
            imgui.SameLine(80*MDS)
            local axW = math.floor((IW - 80*MDS - 4*MDS) / 3)
            for ai=0,2 do
                local isA = (editor.anim_axis[0] == ai)
                imgui.PushStyleColor(c.Button,        isA and v4(0.55,0.10,0.10,1) or v4(0.14,0.14,0.14,1))
                imgui.PushStyleColor(c.ButtonHovered, v4(0.65,0.15,0.15,1))
                imgui.PushStyleColor(c.ButtonActive,  v4(0.75,0.20,0.20,1))
                if imgui.Button(axis_names[ai+1]..'##ax'..ai, v2(axW, 26*MDS)) then
                    editor.anim_axis[0]=ai
                    if anim_state[selected] then anim_state[selected]={angle=0,dir=1} end
                    saveAndRefresh()
                end
                imgui.PopStyleColor(3)
                if ai < 2 then imgui.SameLine(0, 2*MDS) end
            end

            imgui.Text(u8('\xd1\xea\xee\xf0\xee\xf1\xf2\xfc:'))
            imgui.SameLine(120*MDS); imgui.SetNextItemWidth(IW - 120*MDS)
            if imgui.SliderFloat('##aspd', editor.anim_speed, 0.1, 20.0, '%.1f deg/fr') then saveAndRefresh() end
            if am == 2 then
                imgui.Text(u8('\xc4\xe8\xe0\xef\xe0\xe7\xee\xed:'))
                imgui.SameLine(120*MDS); imgui.SetNextItemWidth(IW - 120*MDS)
                if imgui.SliderFloat('##arng', editor.anim_range, 5.0, 180.0, '%.0f deg') then
                    if anim_state[selected] then anim_state[selected]={angle=0,dir=1} end
                    saveAndRefresh()
                end
            end

            imgui.Spacing()
            imgui.Separator(); imgui.Spacing()

            -- ── ДУБЛИРОВАТЬ / УДАЛИТЬ ────────────────────────────
            imgui.PushStyleColor(c.Button,        v4(bt[1]*0.7, bt[2]*0.7, bt[3]*0.7, 1))
            imgui.PushStyleColor(c.ButtonHovered, v4(bh[1], bh[2], bh[3], 1))
            imgui.PushStyleColor(c.ButtonActive,  v4(ba[1], ba[2], ba[3], 1))
            if imgui.Button(I.copy..' '..u8('\xc4\xd3\xc1\xcb\xc8\xd0\xce\xc2\xc0\xd2\xdc'), v2((IW - 4*MDS)/2, 34*MDS)) then
                if list[selected] then
                    local src = list[selected]
                    table.insert(list, {
                        name=src.name..u8(' (\xea\xee\xef\xe8\xff)'),
                        model=src.model,
                        posX=src.posX+0.5, posY=src.posY+0.5, posZ=src.posZ,
                        rotX=src.rotX, rotY=src.rotY, rotZ=src.rotZ,
                        scale=src.scale, collision=src.collision,
                        anim_mode=src.anim_mode,  anim_axis=src.anim_axis,
                        anim_speed=src.anim_speed, anim_range=src.anim_range,
                        move_mode=src.move_mode,  move_dist=src.move_dist,
                        move_speed=src.move_speed,
                    })
                    jsonSave(list, list_file); refreshObjects()
                end
            end
            imgui.PopStyleColor(3)

            imgui.SameLine(0, 4*MDS)

            imgui.PushStyleColor(c.Button,        v4(0.44,0.06,0.06,1))
            imgui.PushStyleColor(c.ButtonHovered, v4(0.65,0.10,0.10,1))
            imgui.PushStyleColor(c.ButtonActive,  v4(0.80,0.14,0.14,1))
            if imgui.Button(I.trash..' '..u8('\xd3\xc4\xc0\xcb\xc8\xd2\xdc'), v2((IW - 4*MDS)/2, 34*MDS)) then
                if list[selected] then
                    if list[selected].handle and doesObjectExist(list[selected].handle) then
                        deleteObject(list[selected].handle)
                    end
                    table.remove(list, selected)
                    anim_state[selected]=nil; move_state[selected]=nil
                    jsonSave(list, list_file); selected=0
                end
            end
            imgui.PopStyleColor(3)

        else
            -- Нет выбранного объекта
            imgui.Spacing()
            local hint = u8('<-- \xc2\xfb\xe1\xe5\xf0\xe8\xf2\xe5 \xee\xe1\xfa\xe5\xea\xf2 \xe8\xe7 \xf1\xef\xe8\xf1\xea\xe0')
            local hw = imgui.CalcTextSize(hint).x
            imgui.SetCursorPosX((edW - hw) / 2)
            imgui.PushStyleColor(c.Text, v4(0.40,0.40,0.40,1))
            imgui.Text(hint)
            imgui.PopStyleColor()
        end

        imgui.EndChild()
        imgui.PopStyleColor(2)

        imgui.End()
    end
    if fMain then imgui.PopFont() end
end).HideCursor = true
