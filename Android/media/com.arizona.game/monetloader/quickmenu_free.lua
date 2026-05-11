script_name('\xc1\xfb\xf1\xf2\xf0\xee\xe5 \xec\xe5\xed\xfe FREE')
script_author('Victor Strand')
script_version('1.0-free')
script_properties('work-in-pause')

local imgui   = require('mimgui')
local encoding= require('encoding')
local faicons = require('fAwesome6')
local fa      = require('fAwesome6_solid')
local ffi     = require('ffi')

encoding.default = 'CP1251'
local u8  = encoding.UTF8
local MDS = MONET_DPI_SCALE
local sw, sh = getScreenResolution()

local MAX_SLOTS = 10
local MAX_PAGES = 1

local subConfirmed = false
local subWinOpen   = imgui.new.bool(false)
local subTG        = imgui.new.bool(false)
local subYT        = imgui.new.bool(false)

local THEMES = {
    {  
        name         = u8('\xc1\xe0\xe7\xee\xe2\xe0\xff'),
        imgUrl       = nil,
        border       = {0.35, 0.35, 0.35, 0.70},
        sectorEdge   = {0.50, 0.50, 0.50, 0.90},
        sectorDiv    = {0.30, 0.30, 0.30, 0.20},
        sector       = {0.18, 0.18, 0.18, 0.40},
        center       = {0.04, 0.04, 0.04, 0.97},
        centerHov    = {0.12, 0.12, 0.12, 0.97},
        centerBrd    = {0.40, 0.40, 0.40, 0.55},
        centerBrdHov = {0.70, 0.70, 0.70, 0.95},
        icon         = {1.00, 1.00, 1.00, 1.00},
        iconHov      = {1.00, 1.00, 1.00, 1.00},
        dots         = {0.80, 0.80, 0.80, 1.00},
        btnBorder    = {0.40, 0.40, 0.40, 0.50},
        btnBordHov   = {0.70, 0.70, 0.70, 0.80},
        btnBordHeld  = {1.00, 1.00, 1.00, 1.00},
        btnBgHeld    = {0.10, 0.10, 0.10, 0.95},
        tabBg        = {0.12, 0.12, 0.12, 1.00},
        tabHov       = {0.22, 0.22, 0.22, 1.00},
        tabActive    = {0.38, 0.38, 0.38, 1.00},
        accent       = {0.25, 0.25, 0.25, 1.00},
        accentHov    = {0.40, 0.40, 0.40, 1.00},
        accentAct    = {0.15, 0.15, 0.15, 1.00},
        winBorder    = {0.45, 0.45, 0.45, 0.80},
    },
}

local loadedTextures = {} 

local function urlToFilename(url)
    return url:match('[^/]+$') or 'img.png'
end

local function ensureTexture(themeIdx)
    local url = THEMES[themeIdx] and THEMES[themeIdx].imgUrl
    if not url then
        return { tex = nil, loaded = false, failed = true }
    end

    if not loadedTextures[url] then
        loadedTextures[url] = { tex = nil, loaded = false, failed = false }
    end
    local entry = loadedTextures[url]
    if entry.loaded or entry.failed then return entry end

    local cacheDir = getWorkingDirectory()..'/quickmenu_img/'
    os.execute('mkdir -p "'..cacheDir..'"')
    local fname = cacheDir..urlToFilename(url)

    if not doesFileExist(fname) then
        local ok = os.execute('wget -q -O "'..fname..'" "'..url..'" 2>/dev/null')
        if ok ~= 0 then
            ok = os.execute('curl -s -o "'..fname..'" "'..url..'" 2>/dev/null')
        end
        if ok ~= 0 and not doesFileExist(fname) then
            entry.failed = true; return entry
        end
    end

    pcall(function()
        local tex = imgui.CreateTextureFromFile(fname)
        if tex then
            entry.tex    = tex
            entry.loaded = true
        else
            entry.failed = true
        end
    end)
    if not entry.loaded then entry.failed = true end
    return entry
end

local CFG_PATH = getWorkingDirectory()..'/config/quickmenu_free_cfg.json'
os.execute('mkdir -p "'..getWorkingDirectory()..'/config"')

local function defaultCfg()
    local slots = {}
    local defs = {
        { icon='BRIEFCASE', cmd='/inventory', label='Inventory' },
        { icon='USER',      cmd='/stats',     label='Stats'     },
        { icon='MOBILE',    cmd='/phone',     label='Phone'     },
        { icon='CAR',       cmd='/cars',      label='Vehicle'   },
        { icon='USERS',     cmd='/fammenu',   label='Family'    },
        { icon='GEAR',      cmd='/settings',  label='Settings'  },
        { icon='STAR',      cmd='/quests',    label='Quests'    },
        { icon='HOUSE',     cmd='/house',     label='House'     },
    }
    for i = 1, MAX_SLOTS do
        slots[i] = defs[i] or { icon='STAR', cmd='', label='' }
    end
    return {
        main = {
            remember_page = false,
            last_page     = 1,
            btn_x         = math.floor(sw * 0.93),
            btn_y         = math.floor(sh * 0.42),
            sub_confirmed = false,
        },
        page = {
            enabled = true,
            count   = 8,
            slots   = slots,
        }
    }
end

local cfg

local function loadCfg()
    local f = io.open(CFG_PATH, 'r')
    if f then
        local s = f:read('*a'); f:close()
        if s and #s > 0 then
            local ok, t = pcall(decodeJson, s)
            if ok and type(t) == 'table' then
                cfg = t
                local def = defaultCfg()
                if not cfg.main then cfg.main = def.main end
                if cfg.main.remember_page == nil then cfg.main.remember_page = false end
                if cfg.main.last_page     == nil then cfg.main.last_page     = 1     end
                if cfg.main.btn_x         == nil then cfg.main.btn_x         = math.floor(sw*0.93) end
                if cfg.main.btn_y         == nil then cfg.main.btn_y         = math.floor(sh*0.42) end
                if cfg.main.sub_confirmed == nil then cfg.main.sub_confirmed = false end
                if not cfg.page then cfg.page = def.page end
                if cfg.page.enabled == nil then cfg.page.enabled = true end
                if cfg.page.count   == nil then cfg.page.count   = 8    end
                if not cfg.page.slots then cfg.page.slots = def.page.slots end
                for i = 1, MAX_SLOTS do
                    if not cfg.page.slots[i] then cfg.page.slots[i] = { icon='STAR', cmd='', label='' } end
                    local sl = cfg.page.slots[i]
                    if sl.icon  == nil then sl.icon  = 'STAR' end
                    if sl.cmd   == nil then sl.cmd   = ''     end
                    if sl.label == nil then sl.label = ''     end
                end
                return
            end
        end
    end
    cfg = defaultCfg()
end

local function saveCfg()
    local ok, s = pcall(encodeJson, cfg)
    if ok and s then
        local f = io.open(CFG_PATH, 'w')
        if f then f:write(s); f:close() end
    end
end

loadCfg()

subConfirmed = cfg.main.sub_confirmed == true

local curThemeIdx = 1
local function getTheme() return THEMES[1] end

local BTN_PX = cfg.main.btn_x or math.floor(sw * 0.93)
local BTN_PY = cfg.main.btn_y or math.floor(sh * 0.42)
local BTN_R  = 26 * MDS

local function getOuterR() return 148 * MDS end
local function getInnerR() return  44 * MDS end
local function getIconR()  return  96 * MDS end

local HOLD_SEC = 0.18

local btnDragMode = false

local function pageEnabled(p)
    return p == 1 and cfg.page.enabled == true
end

local function pageCount(p)
    return p == 1 and math.max(1, math.min(MAX_SLOTS, cfg.page.count or 8)) or 1
end

local PAGES_ITEMS = {}

local function rebuildItems()
    PAGES_ITEMS = {}
    for p = 1, MAX_PAGES do
        local items = {}
        if pageEnabled(p) then
            local n = pageCount(p)
            for i = 1, n do
                local s = p == 1 and cfg.page.slots and cfg.page.slots[i] or nil
                if s then
                    local iconName = s.icon or 'STAR'
                    table.insert(items, {
                        icon  = fa[iconName] or fa.STAR,
                        cmd   = s.cmd   or '',
                        label = s.label or '',
                    })
                end
            end
        end
        PAGES_ITEMS[p] = items
    end
end
rebuildItems()


local N, SLICE, A0
local function recalcGeom(items)
    N = #items
    if N < 1 then N = 1 end
    SLICE = (math.pi * 2) / N
    A0    = -math.pi * 0.5 - SLICE * 0.5
end

local menuOpen  = false
local openAnim  = 0.0
local hovIdx    = -1
local curPage   = 1
local btnHeld   = false
local btnHeldT  = 0.0
local DBL_TAP_SEC = 0.35
local lastTapT    = -999.0
local fIconsBig, fIconsMed, fMain

local _gtaLib = nil
local function openLink(url)
    pcall(function()
        if not _gtaLib then
            _gtaLib = ffi.load('GTASA')
            ffi.cdef[[ void _Z12AND_OpenLinkPKc(const char* link); ]]
        end
        _gtaLib._Z12AND_OpenLinkPKc(url)
    end)
end

local editOpen         = imgui.new.bool(false)
local editPageTab      = imgui.new.int(0)
local editRememberPage = imgui.new.bool(false)
local editBtnX = imgui.new.int(BTN_PX)
local editBtnY = imgui.new.int(BTN_PY)

local ICON_LIST = {
    'BRIEFCASE','USER','USERS','MOBILE','CAR','GEAR','STAR','HOUSE',
    'HEART','SHIELD','MAP','LOCATION_DOT','FLAG','MAGNIFYING_GLASS',
    'TRUCK','MOTORCYCLE','PLANE','TRAIN_SUBWAY','BUS','PERSON_WALKING',
    'MONEY_BILL','COINS','SHOP','CHART_LINE','BELL','CLOCK','CALENDAR',
    'SCREWDRIVER_WRENCH','RADIO','GUN','SKULL','CROWN','BOLT','FIRE',
    'DROPLET','LEAF','FISH','PIZZA_SLICE','CHAMPAGNE_GLASSES',
    'SUITCASE','ENVELOPE','PHONE','GLOBE','LOCK','KEY','HAMMER',
    'PLUG','CIRCLE_CHECK','CIRCLE_XMARK','CIRCLE_INFO','TRIANGLE_EXCLAMATION',
}

local editBufs, editCounts, editEnabled = {}, {}, {}

local function iconIdxByName(name)
    for i, v in ipairs(ICON_LIST) do if v == name then return i end end
    return 1
end

local function initEditBufs()
    editBufs, editCounts, editEnabled = {}, {}, {}
    editRememberPage[0] = cfg.main.remember_page == true
    editBtnX[0] = BTN_PX
    editBtnY[0] = BTN_PY
    for p = 1, MAX_PAGES do
        editBufs[p]    = {}
        editCounts[p]  = imgui.new.int(pageCount(p))
        editEnabled[p] = imgui.new.bool(pageEnabled(p))
        for i = 1, MAX_SLOTS do
            local s = (p == 1 and cfg.page.slots and cfg.page.slots[i]) or { icon='STAR', cmd='', label='' }
            editBufs[p][i] = {
                cmd     = imgui.new.char[128](s.cmd   or ''),
                label   = imgui.new.char[64] (s.label or ''),
                iconIdx = imgui.new.int(iconIdxByName(s.icon or 'STAR') - 1),
            }
        end
    end
end

local function bufToStr(buf, maxlen)
    local t = {}
    for i = 0, maxlen-1 do
        local b = buf[i]
        if not b or b == 0 then break end
        t[#t+1] = string.char(b)
    end
    return table.concat(t)
end

local function col(r, g, b, a)
    return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, a))
end

local function tc(tbl, al)
    al = al or 1.0
    return col(tbl[1], tbl[2], tbl[3], tbl[4] * al)
end

local function tv(tbl, al)
    al = al or 1.0
    return imgui.ImVec4(tbl[1], tbl[2], tbl[3], tbl[4] * al)
end

local function easeOut(t) return 1-(1-t)*(1-t) end

local function getSector(cx, cy)
    local io = imgui.GetIO()
    local dx = io.MousePos.x - cx
    local dy = io.MousePos.y - cy
    local d2 = dx*dx + dy*dy
    local IR = getInnerR(); local OR = getOuterR()
    if d2 < IR*IR then return 0  end
    if d2 > OR*OR then return -1 end
    local rel = math.atan2(dy, dx) - A0
    rel = rel % (math.pi*2)
    return math.max(1, math.min(N, math.floor(rel/SLICE)+1))
end

local function sectorFill(dl, cx, cy, r1, r2, a0, a1, clr, steps)
    steps = steps or 24
    local stp = (a1-a0)/steps
    for s = 0, steps-1 do
        local sa = a0+s*stp; local ea = sa+stp
        local c0,s0 = math.cos(sa),math.sin(sa)
        local c1,s1 = math.cos(ea),math.sin(ea)
        dl:AddQuadFilled(
            imgui.ImVec2(cx+r1*c0, cy+r1*s0), imgui.ImVec2(cx+r2*c0, cy+r2*s0),
            imgui.ImVec2(cx+r2*c1, cy+r2*s1), imgui.ImVec2(cx+r1*c1, cy+r1*s1), clr)
    end
end

local function drawArc(dl, cx, cy, r, a0, a1, clr, thick, steps)
    steps = steps or 24
    local stp = (a1-a0)/steps
    for s = 0, steps-1 do
        local sa = a0+s*stp; local ea = sa+stp
        dl:AddLine(
            imgui.ImVec2(cx+r*math.cos(sa), cy+r*math.sin(sa)),
            imgui.ImVec2(cx+r*math.cos(ea), cy+r*math.sin(ea)),
            clr, thick)
    end
end

local function nextEnabledPage(from)
    for delta = 1, MAX_PAGES do
        local p = ((from-1+delta) % MAX_PAGES)+1
        if pageEnabled(p) then return p end
    end
    return from
end

imgui.OnInitialize(function()
    imgui.SwitchContext() 
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
    local io2    = imgui.GetIO()
    local ttf    = getWorkingDirectory()..'/lib/mimgui/trebucbd.ttf'
    local ranges = io2.Fonts:GetGlyphRangesCyrillic()
    if doesFileExist(ttf) then
        fMain = io2.Fonts:AddFontFromFileTTF(ttf, 13*MDS, nil, ranges)
    end
    do
        local c = imgui.ImFontConfig(); c.MergeMode=false; c.PixelSnapH=true
        local rng = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
        fIconsBig = io2.Fonts:AddFontFromMemoryCompressedBase85TTF(
            faicons.get_font_data_base85('solid'), 26*MDS, c, rng)
    end
    do
        local c = imgui.ImFontConfig(); c.MergeMode=false; c.PixelSnapH=true
        local rng = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
        fIconsMed = io2.Fonts:AddFontFromMemoryCompressedBase85TTF(
            faicons.get_font_data_base85('solid'), 16*MDS, c, rng)
    end
end)

local editSelSlot = {}
for p = 1, MAX_PAGES do editSelSlot[p] = imgui.new.int(0) end

imgui.OnFrame(
    function() return editOpen[0] end,
    function(self)
        self.HideCursor = false
        local W = 644*MDS
        local H = 430*MDS
        local th = getTheme()

        imgui.SetNextWindowPos(imgui.ImVec2(sw*0.5, sh*0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5,0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)

        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding,   9*MDS)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,    6*MDS)
        imgui.PushStyleVarFloat(imgui.StyleVar.GrabRounding,     5*MDS)
        imgui.PushStyleVarFloat(imgui.StyleVar.TabRounding,      6*MDS)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 1.5*MDS)

        imgui.PushStyleColor(imgui.Col.WindowBg,        imgui.ImVec4(0.07, 0.07, 0.09, 0.98))
        imgui.PushStyleColor(imgui.Col.TitleBg,         imgui.ImVec4(0.05, 0.05, 0.08, 1))
        imgui.PushStyleColor(imgui.Col.TitleBgActive,   tv(th.tabActive))
        imgui.PushStyleColor(imgui.Col.Border,          tv(th.winBorder))

        local flags = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoResize

        if imgui.Begin(u8('\xd0\xe5\xe4\xe0\xea\xf2\xee\xf0  QuickMenu FREE  |  Victor Strand'), editOpen, flags) then
            if not subConfirmed then
                if fMain then imgui.PushFont(fMain) end
                local cx2 = W * 0.5
                local cy2 = H * 0.40
                imgui.SetCursorPos(imgui.ImVec2(cx2 - 120*MDS, cy2))
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.75, 0.80, 0.95, 1))
                imgui.TextWrapped(u8('\xcf\xee\xe4\xef\xe8\xf8\xe8\xf1\xfc \xed\xe0 \xea\xe0\xed\xe0\xeb\xfb \xee\xf2\xea\xf0\xfb\xe2\xe0\xe5\xf2 \xf0\xe5\xe4\xe0\xea\xf2\xee\xf0.'))
                imgui.PopStyleColor()
                imgui.SetCursorPos(imgui.ImVec2(cx2 - 80*MDS, cy2 + 40*MDS))
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10,0.22,0.42,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.16,0.34,0.62,1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.07,0.15,0.30,1))
                if imgui.Button(u8('\xcf\xee\xe4\xf2\xe2\xe5\xf0\xe4\xe8\xf2\xfc \xef\xee\xe4\xef\xe8\xf1\xea\xe8'), imgui.ImVec2(160*MDS, 32*MDS)) then
                    subWinOpen[0] = true
                end
                imgui.PopStyleColor(3)
                if fMain then imgui.PopFont() end
            else
                if fMain then imgui.PushFont(fMain) end
                imgui.PushStyleColor(imgui.Col.FrameBg,              imgui.ImVec4(0.10, 0.10, 0.13, 1))
                imgui.PushStyleColor(imgui.Col.FrameBgHovered,       imgui.ImVec4(0.14, 0.14, 0.20, 1))
                imgui.PushStyleColor(imgui.Col.FrameBgActive,        tv(th.tabHov))
                imgui.PushStyleColor(imgui.Col.Button,               tv(th.accent))
                imgui.PushStyleColor(imgui.Col.ButtonHovered,        tv(th.accentHov))
                imgui.PushStyleColor(imgui.Col.ButtonActive,         tv(th.accentAct))
                imgui.PushStyleColor(imgui.Col.Tab,                  tv(th.tabBg))
                imgui.PushStyleColor(imgui.Col.TabHovered,           tv(th.tabHov))
                imgui.PushStyleColor(imgui.Col.TabActive,            tv(th.tabActive))
                imgui.PushStyleColor(imgui.Col.Header,               tv(th.tabActive))
                imgui.PushStyleColor(imgui.Col.HeaderHovered,        tv(th.accentHov))
                imgui.PushStyleColor(imgui.Col.Separator,            tv(th.winBorder, 0.5))
                imgui.PushStyleColor(imgui.Col.ScrollbarBg,          imgui.ImVec4(0.04, 0.04, 0.06, 1))
                imgui.PushStyleColor(imgui.Col.ScrollbarGrab,        tv(th.tabBg))
                imgui.PushStyleColor(imgui.Col.ScrollbarGrabHovered, tv(th.tabHov))
                imgui.PushStyleColor(imgui.Col.CheckMark,            tv(th.sectorEdge))
                imgui.PushStyleColor(imgui.Col.SliderGrab,           tv(th.tabActive))
                imgui.PushStyleColor(imgui.Col.SliderGrabActive,     tv(th.accentHov))

                imgui.PushStyleColor(imgui.Col.Text, tv(th.sectorEdge))
                imgui.Text(u8('\xd2\xe5\xec\xe0: \xc1\xe0\xe7\xee\xe2\xe0\xff'))
                imgui.PopStyleColor()
                imgui.SameLine(0, 8*MDS)
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00, 0.85, 0.00, 1))
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18,0.14,0.00,1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.10,0.08,0.00,1))
                if imgui.Button(u8('\xe7\xe0\xea\xe0\xe7\xe0\xf2\xfc \xea\xe0\xf1\xf2\xee\xec...'), imgui.ImVec2(110*MDS, 0)) then
                    openLink('https://t.me/victor_st0')
                end
                imgui.PopStyleColor(4)

            imgui.SameLine(0, 14*MDS)
            imgui.PushStyleColor(imgui.Col.Text, tv(th.sectorEdge))
            imgui.Text('X:')
            imgui.PopStyleColor()
            imgui.SameLine(0, 3*MDS)
            imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(3*MDS, 2*MDS))
            imgui.SetNextItemWidth(58*MDS)
            if imgui.InputInt('##bx', editBtnX, 0, 0) then
                editBtnX[0] = math.max(BTN_R, math.min(sw - BTN_R, editBtnX[0]))
                BTN_PX = editBtnX[0]
            end
            imgui.SameLine(0, 6*MDS)
            imgui.PushStyleColor(imgui.Col.Text, tv(th.sectorEdge))
            imgui.Text('Y:')
            imgui.PopStyleColor()
            imgui.SameLine(0, 3*MDS)
            imgui.SetNextItemWidth(58*MDS)
            if imgui.InputInt('##by', editBtnY, 0, 0) then
                editBtnY[0] = math.max(BTN_R, math.min(sh - BTN_R, editBtnY[0]))
                BTN_PY = editBtnY[0]
            end
            imgui.PopStyleVar()
            imgui.SameLine(0, 6*MDS)
            local dragLabel = btnDragMode
                and u8('\xe2\xfb\xf5\xee\xe4')
                or  u8('\xef\xe5\xf0\xe5\xf2\xe0\xf9\xe8\xf2\xfc')
            local dragBtnClr = btnDragMode
                and imgui.ImVec4(0.65, 0.10, 0.08, 1)
                or  tv(th.accent)
            imgui.PushStyleColor(imgui.Col.Button,        dragBtnClr)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, btnDragMode and imgui.ImVec4(0.85,0.14,0.10,1) or tv(th.accentHov))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  btnDragMode and imgui.ImVec4(0.50,0.08,0.06,1) or tv(th.accentAct))
            if imgui.Button(dragLabel, imgui.ImVec2(90*MDS, 0)) then
                btnDragMode = not btnDragMode
                if btnDragMode then
                    editOpen[0] = false
                    sampAddChatMessage('{00AAFF}[QM] \xd2\xe0\xf9\xe8 \xea\xed\xee\xef\xea\xf3. \xd2\xe0\xef \xed\xe0 \xed\xe5\xe9 \xe4\xeb\xff \xf4\xe8\xea\xf1\xe0\xf6\xe8\xe8.', -1)
                end
            end
            imgui.PopStyleColor(3)

            imgui.Separator()

            if imgui.BeginTabBar('##pages') then
                if imgui.BeginTabItem(u8('\xd1\xf2\xf0. 1')) then
                    local p = 1
                    editPageTab[0] = 0
                    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(6*MDS, 5*MDS))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.42, 0.48, 0.58, 1))
                    imgui.Text(u8('\xca\xed\xee\xef\xee\xea:'))
                    imgui.PopStyleColor()
                    imgui.SameLine(0, 4*MDS)
                    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(4*MDS, 2*MDS))
                    imgui.SetNextItemWidth(70*MDS)
                    if imgui.SliderInt('##cntfree', editCounts[1], 1, MAX_SLOTS) then
                        cfg.page.count = editCounts[1][0]
        saveCfg()
                        rebuildItems()
                    end
                    imgui.PopStyleVar()
                    imgui.PopStyleVar()
                    imgui.Separator()

                    local listW  = W * 0.36
                    local innerH = H - 188*MDS
                    local th2 = getTheme()

                    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.05, 0.05, 0.07, 1))
                    imgui.BeginChild('##slotlist1', imgui.ImVec2(listW, innerH), false)
                    local count = editCounts[p] and editCounts[p][0] or pageCount(p)
                    for i = 1, count do
                        local buf = editBufs[p] and editBufs[p][i]
                        if not buf then goto nextSlotFree end
                        local isSel = (editSelSlot[p][0] == i-1)
                        local rowBg = isSel
                            and tv(th2.tabActive)
                            or ((i%2==0) and imgui.ImVec4(0.09,0.09,0.13,1) or imgui.ImVec4(0.06,0.06,0.09,1))
                        imgui.PushStyleColor(imgui.Col.Header,        rowBg)
                        imgui.PushStyleColor(imgui.Col.HeaderHovered, tv(th2.tabHov))
                        imgui.PushStyleColor(imgui.Col.HeaderActive,  tv(th2.accent))
                        local lbl = bufToStr(buf.label, 64)
                        local rowText = i..'.  '..(lbl~='' and lbl or (ICON_LIST[buf.iconIdx[0]+1] or 'STAR'))
                        if imgui.Selectable(rowText..'##row1_'..i, isSel, 0, imgui.ImVec2(0, 20*MDS)) then
                            editSelSlot[p][0] = i-1
                        end
                        imgui.PopStyleColor(3)
                        ::nextSlotFree::
                    end
                    imgui.EndChild()
                    imgui.PopStyleColor()

                    imgui.SameLine()
                    local selIdx = editSelSlot[p][0]+1
                    local buf = editBufs[p] and editBufs[p][selIdx]
                    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.08,0.08,0.11,1))
                    imgui.BeginChild('##slotdet1', imgui.ImVec2(0, innerH), false)
                    if buf then
                        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(6*MDS,6*MDS))
                        imgui.PushStyleColor(imgui.Col.Text, tv(th2.sectorEdge))
                        imgui.Text(u8('\xca\xed\xee\xef\xea\xe0 ')..selIdx)
                        imgui.PopStyleColor()
                        imgui.Separator(); imgui.Spacing()
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.70,0.74,0.82,1))
                        imgui.Text(u8('\xcd\xe0\xe7\xe2\xe0\xed\xe8\xe5:'))
                        imgui.PopStyleColor()
                        imgui.SetNextItemWidth(-1)
                        imgui.InputText('##lbl1_'..selIdx, buf.label, 64)
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.70,0.74,0.82,1))
                        imgui.Text(u8('\xc4\xe5\xe9\xf1\xf2\xe2\xe8\xe5:'))
                        imgui.PopStyleColor()
                        imgui.SetNextItemWidth(-1)
                        imgui.InputText('##cmd1_'..selIdx, buf.cmd, 128)
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.35,0.38,0.45,1))
                        imgui.Text(u8('  /\xea\xee\xec\xe0\xed\xe4\xe0 \xe8\xeb\xe8 \xf1\xee\xee\xe1\xf9\xe5\xed\xe8\xe5'))
                        imgui.PopStyleColor()
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.70,0.74,0.82,1))
                        imgui.Text(u8('\xc8\xea\xee\xed\xea\xe0:'))
                        imgui.PopStyleColor()
                        imgui.SameLine()
                        local curIconName = ICON_LIST[buf.iconIdx[0]+1] or 'STAR'
                        if fIconsMed then imgui.PushFont(fIconsMed) end
                        imgui.Text(fa[curIconName] or fa.STAR)
                        if fIconsMed then imgui.PopFont() end
                        imgui.SameLine()
                        imgui.SetNextItemWidth(-1)
                        if imgui.BeginCombo('##ico1_'..selIdx, curIconName) then
                            for j, name in ipairs(ICON_LIST) do
                                local selected = (j-1) == buf.iconIdx[0]
                                if imgui.Selectable(name, selected) then buf.iconIdx[0] = j-1 end
                                if selected then imgui.SetItemDefaultFocus() end
                            end
                            imgui.EndCombo()
                        end
                        imgui.PopStyleVar()
                        local avail = imgui.GetContentRegionAvail()
                        imgui.SetCursorPosY(imgui.GetCursorPosY() + avail.y - 30*MDS)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.09,0.42,0.20,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12,0.56,0.27,1))
                        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.07,0.33,0.16,1))
                        if imgui.Button(u8('\xd1\xee\xf5\xf0\xe0\xed\xe8\xf2\xfc'), imgui.ImVec2(-1, 30*MDS)) then
                            cfg.main.remember_page = editRememberPage[0]
                            cfg.main.btn_x = BTN_PX
                            cfg.main.btn_y = BTN_PY
                            if editCounts[1] then cfg.page.count = editCounts[1][0] end
                            for i = 1, MAX_SLOTS do
                                local b = editBufs[1] and editBufs[1][i]
                                if b then
                                    cfg.page.slots[i].cmd   = bufToStr(b.cmd, 128)
                                    cfg.page.slots[i].label = bufToStr(b.label, 64)
                                    cfg.page.slots[i].icon  = ICON_LIST[b.iconIdx[0]+1] or 'STAR'
                                end
                            end
                            saveCfg()
                            rebuildItems()
                            recalcGeom(PAGES_ITEMS[1] or {})
                            sampAddChatMessage('{00FF88}[QM] \xd1\xee\xf5\xf0\xe0\xed\xe5\xed\xee!', -1)
                        end
                        imgui.PopStyleColor(3)
                    else
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.35,0.38,0.45,1))
                        imgui.Spacing()
                        imgui.Text(u8('\x2190 \xd2\xe0\xef\xed\xe8\xf2\xe5 \xea\xed\xee\xef\xea\xf3'))
                        imgui.PopStyleColor()
                    end
                    imgui.EndChild()
                    imgui.PopStyleColor()
                    imgui.EndTabItem()
                end

                if imgui.BeginTabItem(u8('\xce VIP')) then
                    imgui.Spacing()
                    local cx3 = W * 0.5
                    imgui.SetCursorPosX(cx3 - 60*MDS)
                    if fIconsMed then imgui.PushFont(fIconsMed) end
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,0.85,0.00,1))
                    imgui.Text(fa.STAR)
                    imgui.PopStyleColor()
                    if fIconsMed then imgui.PopFont() end
                    imgui.SameLine(0,4*MDS)
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,0.85,0.00,1))
                    imgui.Text('QuickMenu VIP')
                    imgui.PopStyleColor()
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                    local function vipRow(icon, text, gold)
                        if fIconsMed then imgui.PushFont(fIconsMed) end
                        imgui.PushStyleColor(imgui.Col.Text, gold and imgui.ImVec4(1.00,0.85,0.00,1) or imgui.ImVec4(0.55,0.88,0.55,1))
                        imgui.Text(icon)
                        imgui.PopStyleColor()
                        if fIconsMed then imgui.PopFont() end
                        imgui.SameLine(0,6*MDS)
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.85,0.88,0.95,1))
                        imgui.Text(text)
                        imgui.PopStyleColor()
                    end

                    vipRow(fa.CIRCLE_CHECK, u8('5 \xf1\xf2\xf0\xe0\xed\xe8\xf6 \xef\xee 8 \xea\xed\xee\xef\xee\xea'), false)
                    vipRow(fa.CIRCLE_CHECK, u8('\xc2\xf1\xe5 \xf2\xe5\xec\xfb + \xea\xe0\xf1\xf2\xee\xec'), false)
                    vipRow(fa.CIRCLE_CHECK, u8('\xc8\xe7\xec\xe5\xed\xe5\xed\xe8\xe5 \xf0\xe0\xe7\xec\xe5\xf0\xe0 \xe4\xe8\xf1\xea\xe0'), false)
                    vipRow(fa.CIRCLE_CHECK, u8('\xcf\xf0\xe8\xee\xf0\xe8\xf2\xe5\xf2\xed\xe0\xff \xf1\xf2\xf0\xe0\xed\xe8\xf6\xe0'), false)
                    vipRow(fa.CIRCLE_XMARK, u8('\xc2 FREE: 1 \xf1\xf2\xf0\xe0\xed\xe8\xf6\xe0, 10 \xea\xed\xee\xef\xee\xea, \xf2\xee\xeb\xfc\xea\xee \xc1\xe0\xe7\xee\xe2\xe0\xff \xf2\xe5\xec\xe0'), true)

                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                    imgui.SetCursorPosX(cx3 - 60*MDS)
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.00,0.85,0.00,1))
                    imgui.Text(u8('2$ / \xec\xe5\xf1\xff\xf6'))
                    imgui.PopStyleColor()
                    imgui.Spacing()
                    imgui.SetCursorPosX(cx3 - 80*MDS)
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.40,0.28,0.00,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.60,0.42,0.00,1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.28,0.18,0.00,1))
                    if imgui.Button(u8('\xcf\xf0\xe8\xee\xe1\xf0\xe5\xf1\xf2\xe8 VIP'), imgui.ImVec2(160*MDS, 32*MDS)) then
                        openLink('https://t.me/victor_st0')
                    end
                    imgui.PopStyleColor(3)
                    imgui.EndTabItem()
                end

                imgui.EndTabBar()
            end
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            local tgBtnW = 120*MDS
            local tgBtnH = 24*MDS
            local gap    = 6*MDS

            imgui.SetCursorPosX(W - (tgBtnW*2 + gap + 130*MDS + gap + 12*MDS))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.40, 0.28, 0.00, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.60, 0.42, 0.00, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.28, 0.18, 0.00, 1))
            if imgui.Button(u8('\xcf\xf0\xe8\xee\xe1\xf0\xe5\xf1\xf2\xe8 VIP'), imgui.ImVec2(130*MDS, tgBtnH)) then
                openLink('https://t.me/victor_st0')
            end
            imgui.PopStyleColor(3)
            imgui.SameLine(0, gap)
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.08, 0.22, 0.42, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.32, 0.60, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.06, 0.18, 0.34, 1))
            if imgui.Button(u8('@victor_st0'), imgui.ImVec2(tgBtnW, tgBtnH)) then
                openLink('https://t.me/victor_st0')
            end
            imgui.PopStyleColor(3)
            imgui.SameLine(0, gap)
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.08, 0.22, 0.42, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.32, 0.60, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.06, 0.18, 0.34, 1))
            if imgui.Button(u8('@strand_scripts'), imgui.ImVec2(tgBtnW, tgBtnH)) then
                openLink('https://t.me/strand_scripts')
            end
            imgui.PopStyleColor(3)
                imgui.PopStyleColor(18)
                if fMain then imgui.PopFont() end
            end -- else licOK
        end
        imgui.End()
        imgui.PopStyleVar(5)
        imgui.PopStyleColor(4)
    end
)


imgui.OnFrame(
    function() return subWinOpen[0] end,
    function(self)
        self.HideCursor = false
        local W = 380*MDS
        local H = 220*MDS
        imgui.SetNextWindowPos(imgui.ImVec2(sw*0.5, sh*0.5), imgui.Cond.Always, imgui.ImVec2(0.5,0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(W, H), imgui.Cond.Always)
        if fMain then imgui.PushFont(fMain) end
        imgui.PushStyleColor(imgui.Col.WindowBg,      imgui.ImVec4(0.07, 0.07, 0.09, 0.98))
        imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.10, 0.22, 0.42, 1))
        imgui.PushStyleColor(imgui.Col.Border,        imgui.ImVec4(0.25, 0.45, 0.85, 0.80))
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding,   9*MDS)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,    6*MDS)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 1.5*MDS)
        local wflags = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoResize
        if imgui.Begin(u8('\xcf\xee\xe4\xef\xe8\xf1\xea\xe8  QuickMenu FREE'), subWinOpen, wflags) then
            local dl3 = imgui.GetWindowDrawList()
            local skipW = 70*MDS
            local skipH = 18*MDS
            imgui.SetCursorPos(imgui.ImVec2(W - skipW - 8*MDS, H - skipH - 28*MDS))
            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.35, 0.38, 0.42, 1))
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12,0.12,0.14,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.08,0.08,0.10,1))
            if imgui.Button(u8('\xef\xf0\xee\xef\xf3\xf1\xf2\xe8\xf2\xfc'), imgui.ImVec2(skipW, skipH)) then
                subConfirmed = true
                cfg.main.sub_confirmed = true
                saveCfg()
                subWinOpen[0] = false
            end
            imgui.PopStyleColor(4)
            imgui.SetCursorPos(imgui.ImVec2(14*MDS, 30*MDS))
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.75, 0.80, 0.95, 1))
            imgui.TextWrapped(u8('\xc4\xeb\xff \xe8\xf1\xef\xee\xeb\xfc\xe7\xee\xe2\xe0\xed\xe8\xff \xcf\xee\xe4\xef\xe8\xf8\xe8\xf1\xfc \xed\xe0 \xea\xe0\xed\xe0\xeb\xfb:'))
            imgui.PopStyleColor()
            imgui.Spacing()

            local tgOK = subTG[0]
            local ytOK = subYT[0]

            imgui.PushStyleColor(imgui.Col.Button,        tgOK and imgui.ImVec4(0.09,0.42,0.20,1) or imgui.ImVec4(0.12,0.22,0.42,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, tgOK and imgui.ImVec4(0.12,0.56,0.27,1) or imgui.ImVec4(0.18,0.32,0.60,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  tgOK and imgui.ImVec4(0.07,0.33,0.16,1) or imgui.ImVec4(0.08,0.18,0.34,1))
            if imgui.Button(u8('\xcf\xee\xe4\xef\xe8\xf1\xe0\xf2\xfc\xf1\xff \xed\xe0 Telegram'), imgui.ImVec2(W - 28*MDS, 30*MDS)) then
                openLink('https://t.me/strand_scripts')
                subTG[0] = true
            end
            imgui.PopStyleColor(3)
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button,        ytOK and imgui.ImVec4(0.09,0.42,0.20,1) or imgui.ImVec4(0.55,0.06,0.06,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, ytOK and imgui.ImVec4(0.12,0.56,0.27,1) or imgui.ImVec4(0.75,0.10,0.10,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  ytOK and imgui.ImVec4(0.07,0.33,0.16,1) or imgui.ImVec4(0.40,0.04,0.04,1))
            if imgui.Button(u8('\xcf\xee\xe4\xef\xe8\xf1\xe0\xf2\xfc\xf1\xff \xed\xe0 YouTube'), imgui.ImVec2(W - 28*MDS, 30*MDS)) then
                openLink('https://youtube.com/@strand_samp')
                subYT[0] = true
            end
            imgui.PopStyleColor(3)

            imgui.Spacing(); imgui.Separator(); imgui.Spacing()

            local bothOK = tgOK and ytOK
            local btnW = 160*MDS
            imgui.SetCursorPosX((W - btnW) * 0.5)
            imgui.PushStyleColor(imgui.Col.Button,        bothOK and imgui.ImVec4(0.09,0.42,0.20,1) or imgui.ImVec4(0.22,0.24,0.28,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, bothOK and imgui.ImVec4(0.12,0.56,0.27,1) or imgui.ImVec4(0.22,0.24,0.28,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  bothOK and imgui.ImVec4(0.07,0.33,0.16,1) or imgui.ImVec4(0.22,0.24,0.28,1))
            if imgui.Button(u8('\xcf\xee\xe4\xef\xe8\xf1\xe0\xeb\xf1\xff'), imgui.ImVec2(btnW, 30*MDS)) then
                if bothOK then
                    subConfirmed = true
                    cfg.main.sub_confirmed = true
                    saveCfg()
                    subWinOpen[0] = false
                    sampAddChatMessage('{00AAFF}[QuickMenu FREE] {00FF88}\xc4\xee\xf1\xf2\xf3\xef \xee\xf2\xea\xf0\xfb\xf2!', -1)
                end
            end
            imgui.PopStyleColor(3)
        end
        imgui.End()
        imgui.PopStyleVar(3)
        imgui.PopStyleColor(3)
        if fMain then imgui.PopFont() end
    end
)

imgui.OnFrame(
    function() return true end,
    function(self)
        self.HideCursor = menuOpen or btnDragMode
        if not subConfirmed then
            subWinOpen[0] = true
        end
        local dt  = imgui.GetIO().DeltaTime
        local io  = imgui.GetIO()

        local mx  = io.MousePos.x
        local my  = io.MousePos.y
        local cx  = sw*0.5
        local cy  = sh*0.5
        local items = PAGES_ITEMS[curPage] or {}
        recalcGeom(items)

        if menuOpen then
            openAnim = math.min(1.0, openAnim + dt*14)
        else
            openAnim = math.max(0.0, openAnim - dt*18)
        end

        local bx = BTN_PX
        local by = BTN_PY

        if btnDragMode then
            local dl = imgui.GetForegroundDrawList()
            local th = getTheme()
            if io.MouseDown[0] then
                BTN_PX = math.max(BTN_R, math.min(sw - BTN_R, math.floor(mx)))
                BTN_PY = math.max(BTN_R, math.min(sh - BTN_R, math.floor(my)))
                bx = BTN_PX; by = BTN_PY
                editBtnX[0] = BTN_PX
                editBtnY[0] = BTN_PY
            end
            local pulse = 0.55 + 0.45 * math.abs(math.sin(os.clock() * 3.5))
            dl:AddCircle(imgui.ImVec2(bx,by), BTN_R + 6*MDS, tc(th.btnBordHeld, pulse), 32, 2.5*MDS)
            if fMain then
                local hint = u8('\xd2\xe0\xef \xe4\xeb\xff \xf4\xe8\xea\xf1\xe0\xf6\xe8\xe8')
                local hw = #hint * 6.5 * MDS
                local hx = bx - hw*0.5
                local hy = by + BTN_R + 10*MDS
                dl:AddRectFilled(imgui.ImVec2(hx-6*MDS,hy), imgui.ImVec2(hx+hw+6*MDS,hy+14*MDS), col(0,0,0,0.80), 4*MDS)
                dl:AddTextFontPtr(fMain, 13*MDS, imgui.ImVec2(hx, hy+1*MDS), col(1,1,1,1), hint)
            end
            if io.MouseReleased[0] then
                local moved = math.abs(mx - bx) + math.abs(my - by)
                if moved < 10*MDS then
                    btnDragMode = false
                    cfg.main.btn_x = BTN_PX
                    cfg.main.btn_y = BTN_PY
                    saveCfg()
                    sampAddChatMessage('{00FF88}[QM] \xc1\xf3\xf2\xee\xed \xf1\xee\xf5\xf0\xe0\xed\xb8\xed: '..BTN_PX..', '..BTN_PY, -1)
                end
            end
        end

        local noWinFlags =
            imgui.WindowFlags.NoTitleBar  + imgui.WindowFlags.NoResize   +
            imgui.WindowFlags.NoMove      + imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoNav

        imgui.SetNextWindowPos(imgui.ImVec2(bx-BTN_R, by-BTN_R), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(BTN_R*2, BTN_R*2), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(0,0,0,0))
        imgui.Begin('##qmbtn', nil, noWinFlags)
        imgui.SetCursorPos(imgui.ImVec2(0,0))
        imgui.InvisibleButton('##qmbtnhold', imgui.ImVec2(BTN_R*2, BTN_R*2))
        local isActive = imgui.IsItemActive()
        imgui.End()
        imgui.PopStyleColor(2)

        if menuOpen then
            local hitR  = getOuterR() + 8*MDS
            local hitSz = hitR*2
            imgui.SetNextWindowPos(imgui.ImVec2(cx-hitR, cy-hitR), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(hitSz, hitSz), imgui.Cond.Always)
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(0,0,0,0))
            imgui.Begin('##qmoverlay', nil, noWinFlags)
            imgui.SetCursorPos(imgui.ImVec2(0,0))
            imgui.InvisibleButton('##qmoverlayhold', imgui.ImVec2(hitSz, hitSz))
            local isActive2 = imgui.IsItemActive()
            imgui.End()
            imgui.PopStyleColor(2)
            if isActive2 then isActive = true end
        end

        if not btnDragMode then
            if isActive then
                if not btnHeld then
                    btnHeld  = true
                    btnHeldT = os.clock()
                end
                if not menuOpen and (os.clock()-btnHeldT) >= HOLD_SEC then
                    menuOpen = true
                    if not (cfg.main.remember_page == true) then
                        local pp = 0
                        if pp >= 1 and pp <= MAX_PAGES and pageEnabled(pp) then
                            curPage = pp
                        else
                            local first = nextEnabledPage(0)
                            if first ~= 0 then curPage = first end
                        end
                    end
                end
                if menuOpen then
                    local newIdx = getSector(cx, cy)
                    if newIdx ~= hovIdx then hovIdx = newIdx end
                end
            else
                if btnHeld then
                    btnHeld = false
                    if menuOpen then
                        if hovIdx == 0 then
                            local next = nextEnabledPage(curPage)
                            if next ~= curPage then
                                curPage = next
                                if cfg.main.remember_page == true then
                                    cfg.main.last_page = curPage
                                    saveCfg()
                                end
                                items = PAGES_ITEMS[curPage] or {}
                                recalcGeom(items)
                                sampAddChatMessage('{00AAFF}[QM] \xd1\xf2\xf0\xe0\xed\xe8\xf6\xe0 '..curPage, -1)
                            end
                            hovIdx = -1
                        elseif hovIdx >= 1 and hovIdx <= N then
                            local cmd = items[hovIdx] and items[hovIdx].cmd or ''
                            if cmd ~= '' then
                                lua_thread.create(function()
                                    wait(50)
                                    local decoded = u8:decode(cmd)
                                    if decoded:sub(1,1) == '/' then
                                        sampProcessChatInput(decoded)
                                    else
                                        sampSendChat(decoded)
                                    end
                                end)
                            end
                            menuOpen = false; hovIdx = -1
                            if not (cfg.main.remember_page == true) then
                                local pp = 0
                                if pp >= 1 and pp <= MAX_PAGES and pageEnabled(pp) then
                                    curPage = pp
                                else
                                    local first = nextEnabledPage(0)
                                    if first ~= 0 then curPage = first end
                                end
                            end
                        else
                            menuOpen = false; hovIdx = -1
                            if not (cfg.main.remember_page == true) then
                                local pp = 0
                                if pp >= 1 and pp <= MAX_PAGES and pageEnabled(pp) then
                                    curPage = pp
                                else
                                    local first = nextEnabledPage(0)
                                    if first ~= 0 then curPage = first end
                                end
                            end
                        end
                    else
                        local now = os.clock()
                        if (now-lastTapT) <= DBL_TAP_SEC then
                            lastTapT = -999.0
                            editOpen[0] = not editOpen[0]
                            if editOpen[0] then initEditBufs() end
                        else
                            lastTapT = now
                        end
                    end
                end
            end
        end

        local dl = imgui.GetForegroundDrawList()
        local bdx = mx - bx
        local bdy = my - by
        local bHov = bdx*bdx + bdy*bdy < (BTN_R+3*MDS)*(BTN_R+3*MDS)
        local th = getTheme()

        dl:AddCircleFilled(imgui.ImVec2(bx+2*MDS, by+3*MDS), BTN_R, col(0,0,0,0.45), 32)
        local bgR, bgG, bgB = 0.07, 0.07, 0.08
        if btnHeld or menuOpen then
            bgR = th.btnBgHeld[1]; bgG = th.btnBgHeld[2]; bgB = th.btnBgHeld[3]
        end
        dl:AddCircleFilled(imgui.ImVec2(bx,by), BTN_R, col(bgR,bgG,bgB,0.95), 32)

        local tEntry = ensureTexture(curThemeIdx)
        if tEntry and tEntry.loaded and tEntry.tex then
            local ir = BTN_R - 3*MDS
            dl:AddImageRounded(
                tEntry.tex,
                imgui.ImVec2(bx - ir, by - ir),
                imgui.ImVec2(bx + ir, by + ir),
                imgui.ImVec2(0,0), imgui.ImVec2(1,1),
                col(1,1,1,0.92),
                ir, 15
            )
        end

        local brdClr
        if btnDragMode then                brdClr = tc(th.btnBordHeld)
        elseif btnHeld or menuOpen then    brdClr = tc(th.btnBordHeld)
        elseif bHov then                   brdClr = tc(th.btnBordHov)
        else                               brdClr = tc(th.btnBorder)  end
        dl:AddCircle(imgui.ImVec2(bx,by), BTN_R, brdClr, 32, 2.5*MDS)
        if not (tEntry and tEntry.loaded and tEntry.tex) then
            local lCol = (btnHeld or menuOpen or btnDragMode) and tc(th.btnBordHeld) or col(0.88,0.88,0.88,0.78)
            for i = -1, 1 do
                dl:AddLine(imgui.ImVec2(bx-9*MDS, by+i*5.5*MDS), imgui.ImVec2(bx+9*MDS, by+i*5.5*MDS), lCol, 2*MDS)
            end
        end

        if openAnim <= 0.001 then return end
        local ease = easeOut(openAnim)
        local al   = ease
        local curR = getOuterR()*ease
        local curI = getInnerR()*ease

        dl:AddCircleFilled(imgui.ImVec2(cx,cy), curR, col(0.04,0.04,0.05,0.92*al), 64)
        dl:AddCircle(imgui.ImVec2(cx,cy), curR, tc(th.border, al), 64, 2*MDS)

        if hovIdx >= 1 and hovIdx <= N then
            local sa = A0+(hovIdx-1)*SLICE
            local ea = sa+SLICE
            sectorFill(dl, cx, cy, curI+1*MDS, curR-1*MDS, sa, ea, tc(th.sector, al), 24)
            drawArc(dl, cx, cy, curR-1.5*MDS, sa+0.04, ea-0.04, tc(th.sectorEdge, al), 2.5*MDS, 24)
        end

        for i = 0, N-1 do
            local a = A0+i*SLICE
            dl:AddLine(
                imgui.ImVec2(cx+curI*math.cos(a), cy+curI*math.sin(a)),
                imgui.ImVec2(cx+curR*math.cos(a), cy+curR*math.sin(a)),
                tc(th.sectorDiv, al), 1*MDS)
        end

        local isCenter = (hovIdx == 0)
        dl:AddCircleFilled(imgui.ImVec2(cx,cy), curI, isCenter and tc(th.centerHov,al) or tc(th.center,al), 32)

        local tec = ensureTexture(curThemeIdx)
        if tec and tec.loaded and tec.tex then
            local ci2 = curI - 3*MDS
            local imgAlpha = isCenter and (al * 0.70) or (al * 0.90)
            dl:AddImageRounded(
                tec.tex,
                imgui.ImVec2(cx - ci2, cy - ci2),
                imgui.ImVec2(cx + ci2, cy + ci2),
                imgui.ImVec2(0,0), imgui.ImVec2(1,1),
                col(1,1,1, imgAlpha),
                ci2, 15
            )
        end

        dl:AddCircle(imgui.ImVec2(cx,cy), curI, isCenter and tc(th.centerBrdHov,al) or tc(th.centerBrd,al), 32, 1.8*MDS)

        if fIconsBig then
            for i, item in ipairs(items) do
                local midA = A0+(i-0.5)*SLICE
                local isH  = (i == hovIdx)
                local ix   = cx + getIconR()*ease*math.cos(midA)
                local iy   = cy + getIconR()*ease*math.sin(midA)
                local clr  = isH and tc(th.iconHov, al) or tc(th.icon, al)
                dl:AddTextFontPtr(fIconsBig, 26*MDS, imgui.ImVec2(ix-13*MDS, iy-13*MDS), clr, item.icon)
            end
        end

        do
            local enabledCount = 0
            for p = 1, MAX_PAGES do if pageEnabled(p) then enabledCount = enabledCount+1 end end
            if enabledCount > 1 then
                local dotW = 6*MDS; local dotGap = 4*MDS
                local pagesShown = {}
                for p = 1, MAX_PAGES do if pageEnabled(p) then table.insert(pagesShown, p) end end
                local totalW = #pagesShown*dotW + (#pagesShown-1)*dotGap
                local dx0 = cx - totalW*0.5
                local dy0 = cy + curI + 8*MDS
                for pi, pv in ipairs(pagesShown) do
                    local dxc = dx0+(pi-1)*(dotW+dotGap)+dotW*0.5
                    local dotClr = (pv==curPage) and tc(th.dots, al) or col(0.5,0.5,0.5,al*0.5)
                    dl:AddCircleFilled(imgui.ImVec2(dxc, dy0), dotW*0.5, dotClr, 8)
                end
            end
        end

        if hovIdx >= 1 and hovIdx <= N and fMain then
            local label = items[hovIdx] and items[hovIdx].label or ''
            if label ~= '' then
                local th2 = 13*MDS
                local tw = #label*7.5*MDS
                local lx = cx - tw*0.5
                local ly = cy + curR + 8*MDS
                dl:AddRectFilled(imgui.ImVec2(lx-8*MDS,ly), imgui.ImVec2(lx+tw+8*MDS,ly+th2+8*MDS), col(0,0,0,0.80*al), 5*MDS)
                dl:AddTextFontPtr(fMain, 13*MDS, imgui.ImVec2(lx, ly+4*MDS), col(1,1,1,al), label)
            end
        end
    end
)

function main()
    while not isSampAvailable()          do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0)   end

    
    if sw2 and sw2 > 0 then sw = sw2 end
    if sh2 and sh2 > 0 then sh = sh2 end
    if sw == 0 or sw == nil then sw = 1280 end
    if sh == 0 or sh == nil then sh  = 720  end


    if not cfg.main.btn_x or cfg.main.btn_x == 0 then
        cfg.main.btn_x = math.floor(sw * 0.93)
    end
    if not cfg.main.btn_y or cfg.main.btn_y == 0 then
        cfg.main.btn_y = math.floor(sh * 0.42)
    end

    initEditBufs()
    ensureTexture(curThemeIdx)
    BTN_PX = math.max(BTN_R, math.min(sw - BTN_R, cfg.main.btn_x))
    BTN_PY = math.max(BTN_R, math.min(sh - BTN_R, cfg.main.btn_y))

    curPage = nextEnabledPage(0)
    if curPage == 0 then curPage = 1 end

    if cfg.main.remember_page == true then
        local saved = cfg.main.last_page or 1
        if saved >= 1 and saved <= MAX_PAGES and pageEnabled(saved) then
            curPage = saved
        end
    end

    sampRegisterChatCommand('qm', function()
        menuOpen = not menuOpen
        hovIdx   = menuOpen and hovIdx or -1
        sampAddChatMessage('{00AAFF}[QM] '..(menuOpen and '\xee\xf2\xea\xf0\xfb\xf2\xee' or '\xe7\xe0\xea\xf0\xfb\xf2\xee'), -1)
    end)

    sampRegisterChatCommand('qem', function()
        editOpen[0] = not editOpen[0]
        if editOpen[0] then initEditBufs() end
    end)

    sampRegisterChatCommand('qmpage', function(args)
        local n = tonumber(args)
        if n and n >= 1 and n <= MAX_PAGES then
            if pageEnabled(n) then
                curPage = n
                if cfg.main.remember_page == true then
                    cfg.main.last_page = n; saveCfg()
                end
                sampAddChatMessage('{00AAFF}[QM] \xd1\xf2\xf0\xe0\xed\xe8\xf6\xe0 '..n, -1)
            else
                sampAddChatMessage('{FF4444}[QM] \xd1\xf2\xf0\xe0\xed\xe8\xf6\xe0 '..n..' \xed\xe5 \xe0\xea\xf2\xe8\xe2\xed\xe0', -1)
            end
        end
    end)

    sampRegisterChatCommand('qmtheme', function(args)
        local n = tonumber(args)
        if n and n >= 1 and n <= #THEMES then
            curThemeIdx = n; saveCfg()
            ensureTexture(curThemeIdx)
            sampAddChatMessage('{00AAFF}[QM] \xd2\xe5\xec\xe0: '..THEMES[n].name, -1)
        else
            sampAddChatMessage('{FFAA00}[QM] /qmtheme 1..'..#THEMES, -1)
        end
    end)

    sampRegisterChatCommand('qmdrag', function()
        btnDragMode = not btnDragMode
        if btnDragMode then
            editOpen[0] = false
            sampAddChatMessage('{00AAFF}[QM] \xd2\xe0\xf9\xe8 \xea\xed\xee\xef\xea\xf3. \xd2\xe0\xef \xed\xe0 \xed\xe5\xe9 \xe4\xeb\xff \xf4\xe8\xea\xf1\xe0\xf6\xe8\xe8.', -1)
        else
            sampAddChatMessage('{FFAA00}[QM] \xd0\xe5\xe6\xe8\xec \xef\xe5\xf0\xe5\xf2\xe0\xf1\xea\xe8\xe2\xe0\xed\xe8\xff \xee\xf2\xec\xe5\xed\xb8\xed.', -1)
        end
    end)

    sampRegisterChatCommand('qmclearcache', function()
        local cacheDir = getWorkingDirectory()..'/quickmenu_img/'
        os.execute('rm -f "'..cacheDir..'"*.png 2>/dev/null')
        os.execute('rm -f "'..cacheDir..'"*.jpg 2>/dev/null')
        loadedTextures = {}
        ensureTexture(curThemeIdx)
        sampAddChatMessage('{00FF88}[QM] \xca\xfd\xf8 \xea\xe0\xf0\xf2\xee\xed\xee\xea \xf1\xe1\xf0\xee\xf8\xe5\xed, \xf2\xe5\xea\xf1\xf2\xf3\xf0\xfb \xe7\xe0\xe3\xf0\xf3\xe6\xe0\xfe\xf2\xf1\xff \xe7\xe0\xed\xee\xe2\xee.', -1)
    end)

    sampAddChatMessage('{00AAFF}[QuickMenu FREE]{FFFFFF} /qm /qem /qmpage N /qmdrag /qmclearcache', -1)

    if not subConfirmed then
        subWinOpen[0] = true
    end

    while true do wait(0) end
end