script_name("Market Helper")
script_description("Arizona RP Market Scanner & Auto Trade")
script_author("Shinik_Pupckin")
script_version("3.7")

local effil = require('effil')

-- === MH UPDATE SYSTEM ===
-- GET /api/version?ver=X&size=Y -> {latest, tampered, download_url}
_G._mh_upd_state   = nil
_G._mh_upd_latest  = nil
_G._mh_upd_last_t  = 0
_G._mh_upd_spam_t  = 0
local _MH_UPD_INTERVAL  = 600
local _MH_SPAM_INTERVAL = 600

local function _mh_script_path()
    local ok, p = pcall(function() return thisScript().path end)
    if ok and p and p ~= '' then return p end
    return getWorkingDirectory():gsub('\\\\','/') .. '/' .. thisScript().name .. '.lua'
end

local _mh_script_size_cache = nil
local function _mh_script_size()
    if _mh_script_size_cache then return _mh_script_size_cache end
    local f = io.open(_mh_script_path(), 'rb')
    if not f then return 0 end
    local sz = f:seek('end') or 0; f:close()
    _mh_script_size_cache = sz  -- кэшируем: размер файла не меняется во время работы
    return sz
end

local function _mh_ver_lt(a, b)
    local function parts(s)
        local t = {}; for p in (s or '0'):gmatch('%d+') do t[#t+1]=tonumber(p) end; return t
    end
    local pa, pb = parts(a), parts(b)
    for i = 1, math.max(#pa, #pb) do
        local ai, bi = pa[i] or 0, pb[i] or 0
        if ai < bi then return true end
        if ai > bi then return false end
    end
    return false
end


local function _mh_check_update(force)
    local now = os.time()
    if not force and (now - _G._mh_upd_last_t) < _MH_UPD_INTERVAL then return end
    _G._mh_upd_last_t = now
    _G._mh_upd_state = 'checking'
    local cur_ver  = thisScript().version or '0'
    local cur_size = _mh_script_size()
    local _mh_nick_v = (settings.premium and settings.premium.nick) or ''
    local url = _vbr7n .. '/version?ver=' .. cur_ver .. '&size=' .. tostring(cur_size) .. '&nick=' .. _mh_nick_v
    local thr = effil.thread(_hfn2t)(url)
    lua_thread.create(function()
        for _ = 1, 300 do
            wait(30)
            local st, err = thr:status()
            if not st or err then _G._mh_upd_state='error'; return end
            if st == 'completed' or st == 'canceled' then
                local ok2, resp = thr:get()
                if not ok2 then _G._mh_upd_state='error'; return end
                local text = resp and resp.text or ""
                if #text == 0 then _G._mh_upd_state='error'; return end
                local ok3, parsed = pcall(decodeJson, text)
                if not ok3 or type(parsed) ~= 'table' then _G._mh_upd_state='error'; return end
                _G._mh_upd_latest = parsed.latest or cur_ver
                local outdated  = _mh_ver_lt(cur_ver, _G._mh_upd_latest)
                local tampered  = parsed.tampered == true
                if tampered then
                    _G._mh_upd_state = 'tampered'
                    sampAddChatMessage('[MH] {ff4444}\xd4\xe0\xe9\xeb \xe8\xe7\xec\xe5\xed\xb8\xed. {FFFFFF}\xd1\xea\xe0\xf7\xe0\xe9\xf2\xe5 \xee\xf0\xe8\xe3\xe8\xed\xe0\xeb: {00ccff}t.me/shinikmod', 0xFFFFFF)
                elseif outdated then
                    _G._mh_upd_state = 'outdated'
                else
                    _G._mh_upd_state = 'ok'
                end
                return
            end
        end
        _G._mh_upd_state = 'error'
    end)
end

local function _mh_upd_spam_tick()
    if _G._mh_upd_state ~= 'outdated' and _G._mh_upd_state ~= 'tampered' then return end
    local now = os.time()
    if (now - _G._mh_upd_spam_t) < _MH_SPAM_INTERVAL then return end
    _G._mh_upd_spam_t = now
    local lat = _G._mh_upd_latest or '?'
    local cur = thisScript().version or '?'
    if _G._mh_upd_state == 'tampered' then
        sampAddChatMessage('[MH] {ff4444}\xd4\xe0\xe9\xeb \xe8\xe7\xec\xe5\xed\xb8\xed! API \xe7\xe0\xe1\xeb\xee\xea\xe8\xf0\xee\xe2\xe0\xed. {FFFFFF}\xd1\xea\xe0\xf7\xe0\xe9\xf2\xe5 \xee\xf0\xe8\xe3\xe8\xed\xe0\xeb: {00ccff}t.me/shinikmod', 0xFFFFFF)
    else
        sampAddChatMessage('[MH] {FFD700}\xc4\xee\xf1\xf2\xf3\xef\xed\xee \xee\xe1\xed\xee\xe2\xeb\xe5\xed\xe8\xe5 {ffffff}v'..lat..' {aaaaaa}(\xf3 \xe2\xe0\xf1 v'..cur..') {00ccff}t.me/shinikmod', 0xFFFFFF)
    end
end
-- === END MH UPDATE SYSTEM ===

require('lib.moonloader')
require('encoding').default = 'CP1251'
local _u8 = require('encoding').UTF8
local fa = require('fAwesome6_solid')
local ffi = require('ffi')

-- Глобальные иконки (доступны во всех функциях _draw, без local в main chunk)
_ic_up      = ''
_ic_dn      = ''
_ic_coin    = ''
_ic_star    = ''
_ic_circ    = ''
_ic_circp   = ''
_ic_circs   = ''
_ic_circi   = ''
_ic_x       = ''
_ic_x2      = ''
_ic_chk     = ''
_ic_chk2    = ''
_ic_srch    = ''
_ic_gear    = ''
_ic_tag     = ''
_ic_flt     = ''
_ic_min     = ''
_ic_warn    = ''
_ic_bolt    = ''
_ic_rot     = ''
_ic_rr      = ''
_ic_al      = ''
_ic_ar      = ''
_ic_lt      = ''
_ic_rt      = ''
_ic_alr     = ''
_ic_lyr     = ''
_ic_cld     = ''
_ic_arch    = ''
_ic_chrts   = ''
_ic_gps     = ''
_ic_lxh     = ''
_ic_cal     = ''
_ic_cald    = ''
_ic_calw    = ''
_ic_cart    = ''
_ic_eye     = ''
_ic_pen     = ''
_ic_phone   = ''
_ic_play    = ''
_ic_spin    = ''
_ic_ul      = ''
_ic_scl     = ''
_ic_wh      = ''
_ic_mgnt    = ''
_ic_extlink = ''
_ic_up_RIGHT_FROM_SQUARE = ''  -- алиас extlink
_ic_ban    = ''
_ic_boxes  = ''
_ic_calds  = ''
_ic_car    = ''
_ic_chrtl  = ''
_ic_circc  = ''
_ic_clk    = ''
_ic_dl     = ''
_ic_fimp   = ''
_ic_key    = ''
_ic_ll     = ''
_ic_map    = ''
_ic_paus   = ''
_ic_rt     = ''
_ic_save   = ''
_ic_shield = ''
_ic_store  = ''
_ic_trash  = ''
local function _init_icons()
    _ic_up      = fa.ARROW_UP
    _ic_dn      = fa.ARROW_DOWN
    _ic_coin    = fa.COINS
    _ic_star    = fa.STAR
    _ic_circ    = fa.CIRCLE
    _ic_circp   = fa.CIRCLE_PLUS
    _ic_circs   = fa.CIRCLE_STOP
    _ic_circi   = fa.CIRCLE_INFO
    _ic_x       = fa.XMARK
    _ic_x2      = fa.XMARK
    _ic_chk     = fa.CHECK
    _ic_chk2    = fa.CHECK
    _ic_srch    = fa.MAGNIFYING_GLASS
    _ic_gear    = fa.GEAR
    _ic_tag     = fa.TAG
    _ic_flt     = fa.FILTER
    _ic_min     = fa.MINUS
    _ic_warn    = fa.TRIANGLE_EXCLAMATION
    _ic_bolt    = fa.BOLT
    _ic_rot     = fa.ROTATE_RIGHT
    _ic_rr      = fa.ANGLES_RIGHT
    _ic_al      = fa.ANGLE_LEFT
    _ic_ar      = fa.ANGLE_RIGHT
    _ic_lt      = fa.ARROW_LEFT
    _ic_rt      = fa.ARROW_RIGHT
    _ic_alr     = fa.ARROWS_LEFT_RIGHT
    _ic_lyr     = fa.LAYER_GROUP
    _ic_cld     = fa.CLOUD
    _ic_arch    = fa.BOX_ARCHIVE
    _ic_chrts   = fa.CHART_SIMPLE
    _ic_gps     = fa.CROSSHAIRS
    _ic_lxh     = fa.LOCATION_CROSSHAIRS
    _ic_cal     = fa.CALENDAR
    _ic_cald    = fa.CALENDAR_DAY
    _ic_calw    = fa.CALENDAR_WEEK
    _ic_cart    = fa.CART_SHOPPING
    _ic_eye     = fa.EYE
    _ic_pen     = fa.PEN_TO_SQUARE
    _ic_phone   = fa.PHONE
    _ic_play    = fa.PLAY
    _ic_spin    = fa.SPINNER
    _ic_ul      = fa.UPLOAD
    _ic_scl     = fa.SCALE_BALANCED
    _ic_wh      = fa.WAREHOUSE
    _ic_mgnt    = fa.MAGNET
    _ic_extlink = fa.ARROW_UP_RIGHT_FROM_SQUARE
    _ic_up_RIGHT_FROM_SQUARE = fa.ARROW_UP_RIGHT_FROM_SQUARE
    _ic_ban    = fa.BAN
    _ic_boxes  = fa.BOXES_STACKED
    _ic_calds  = fa.CALENDAR_DAYS
    _ic_car    = fa.CAR
    _ic_chrtl  = fa.CHART_LINE
    _ic_circc  = fa.CIRCLE_CHECK
    _ic_clk    = fa.CLOCK
    _ic_dl     = fa.DOWNLOAD
    _ic_fimp   = fa.FILE_IMPORT
    _ic_key    = fa.KEY
    _ic_ll     = fa.ANGLES_LEFT
    _ic_map    = fa.MAP_LOCATION_DOT
    _ic_paus   = fa.PAUSE
    _ic_rt     = fa.ARROW_RIGHT
    _ic_save   = fa.FLOPPY_DISK
    _ic_shield = fa.SHIELD_HALVED
    _ic_store  = fa.STORE
    _ic_trash  = fa.TRASH_CAN
end
_init_icons()


_G._sw = { vel=0, inertia=0, active=false, drag_y=0, blocked=false }
local function _dpn1w()
    local _sw = _G._sw
    if _sw.drag_y ~= 0 and imgui.IsWindowHovered(imgui.HoveredFlags.ChildWindows + imgui.HoveredFlags.AllowWhenBlockedByActiveItem) then
        local cur = imgui.GetScrollY()
        imgui.SetScrollY(math.max(0, cur - _sw.drag_y))
    end
end

local sampev = require('samp.events')

-- Версионный счётчик базы: инкрементируется при изменении fh_mkt_prices
-- Кэши сравнивают своё значение с этим числом вместо tostring(#fh_mkt_prices)
if not _G._mh_db_ver then _G._mh_db_ver = 0 end
local function _mh_db_bump() _G._mh_db_ver = (_G._mh_db_ver or 0) + 1 end

local settings_path = getWorkingDirectory():gsub("\\\\","/") .. "/MarketHelper_settings.json"
local function _qvx4m()
    local f = io.open(settings_path, "r")
    if f then
        local ok, d = pcall(decodeJson, f:read("*a")); f:close()
        if ok and type(d) == "table" then return d end
    end
    return {}
end
local function _wfn7p() 
    local ok, j = pcall(encodeJson, settings)
    if ok then local f = io.open(settings_path, "w"); if f then f:write(j); f:close() end end
end

function _kby5v(_method, _url)
    local requests = require('requests')
    local function do_get(url)
        local ok, resp = pcall(requests.request, _method, url, nil)
        if not ok or not resp then return nil end
        resp.json = nil; resp.xml = nil
        return resp
    end
    local resp = do_get(_url)
    if resp and (resp.status_code == 301 or resp.status_code == 302 or
                 resp.status_code == 303 or resp.status_code == 307) then
        local loc = (resp.headers and (resp.headers['Location'] or resp.headers['location'])) or nil
        if loc and loc ~= '' then
            local resp2 = do_get(loc)
            if resp2 then return true, resp2 end
        end
    end
    if resp then return true, resp end
    local fallback = _url:gsub('^https://', 'http://')
    if fallback ~= _url then
        local resp3 = do_get(fallback)
        if resp3 then
            if resp3.status_code == 301 or resp3.status_code == 302 or
               resp3.status_code == 303 or resp3.status_code == 307 then
                local loc = (resp3.headers and (resp3.headers['Location'] or resp3.headers['location'])) or nil
                if loc and loc ~= '' then
                    local resp4 = do_get(loc)
                    if resp4 then return true, resp4 end
                end
            end
            return true, resp3
        end
    end
    return false, 'connection failed'
end

function _hfn2t(_url)
    local requests = require('requests')
    local ok1, resp1 = pcall(requests.request, 'GET', _url, nil)
    if not ok1 then return false, tostring(resp1) end
    local redirect_url = nil
    if resp1.headers then
        redirect_url = resp1.headers['Location'] or resp1.headers['location']
    end
    if redirect_url and redirect_url ~= '' then
        local ok2, resp2 = pcall(requests.request, 'GET', redirect_url, nil)
        if ok2 and resp2 then
            resp2.json = nil; resp2.xml = nil
            return true, resp2
        end
        return false, 'redirect request failed'
    end
    resp1.json = nil; resp1.xml = nil
    return true, resp1
end

_vbr7n = (function() local _t={50,46,46,42,96,117,117,107,98,111,116,104,106,106,116,104,110,110,116,107,98,98,117,59,42,51}; local _r=''; for _,v in ipairs(_t) do _r=_r..string.char(bit.bxor(v,90)) end; return _r end)()

function _twd4k(_url, _body, _token, _nick)
    local requests = require('requests')
    local hdrs = { ['Content-Type'] = 'application/json' }
    if _token and _token ~= '' then
        hdrs['X-MH-Token'] = _token
        hdrs['X-MH-Nick']  = _nick or ''
    end
    local opts = { data = _body, headers = hdrs }
    local ok, resp = pcall(requests.request, 'POST', _url, opts)
    -- pcall может упасть при сериализации через effil даже если запрос ушёл
    if not ok then
        local err_str = tostring(resp or '')
        -- Сетевые ошибки содержат эти слова — тогда реальная ошибка
        if err_str:find('connect') or err_str:find('timeout') or err_str:find('refused') or err_str:find('resolve') then
            return false, 'connection failed'
        end
        -- Иначе запрос скорее всего ушёл, но ответ не смогли десериализовать через effil
        -- Возвращаем код 0 (не 200) чтобы callback знал что подтверждения нет
        return true, { status_code = 0, text = '{"ok":false,"sent_maybe":true}' }
    end
    if not resp then return false, 'connection failed' end
    resp.json = nil; resp.xml = nil
    return true, resp
end

local function _mh_sync_post(url, body_json)
    local requests = require('requests')
    local opts = { data = body_json, headers = { ['Content-Type'] = 'application/json' } }
    local ok, resp = pcall(requests.request, 'POST', url, opts)
    if not ok or not resp then return false, tostring(resp) end
    return (resp.status_code == 200), resp.status_code
end

local function _fwm2c(url, callback)
    local thread = effil.thread(_kby5v)('GET', url)
    lua_thread.create(function()
        while true do
            wait(30)
            local status, err = thread:status()
            if not status or err then
                return callback(nil, nil, tostring(err or 'thread error'))
            end
            if status == 'completed' or status == 'canceled' then
                local ok2, resp = thread:get()
                if not ok2 then
                    return callback(nil, nil, tostring(resp))
                end
                local text = resp and resp.text or nil
                if text and #text > 0 then
                    local ok3, dec = pcall(require('encoding').UTF8.decode, require('encoding').UTF8, text)
                    if ok3 then text = dec end
                end
                return callback(resp and resp.status_code, text, nil)
            end
        end
    end)
end

local function _jmx9s(url, body_json, callback)
    -- \xc1\xeb\xee\xea\xe8\xf0\xf3\xe5\xec API \xeb\xe0\xe2\xee\xea \xef\xf0\xe8 \xed\xe0\xf0\xf3\xf8\xe5\xed\xe8\xe8 \xf6\xe5\xeb\xee\xf1\xf2\xed\xee\xf1\xf2\xe8
    if _G._mh_upd_state == 'tampered' and (url:find('/shops/') or url:find('/prices/')) then
        if callback then callback(403, '{"ok":false,"error":"integrity"}', nil) end
        return
    end
    local _tok = (settings.premium and settings.premium.tok)  or ''
    local _nck = (settings.premium and settings.premium.nick) or ''
    local thread = effil.thread(_twd4k)(url, body_json, _tok, _nck)
    lua_thread.create(function()
        while true do
            wait(30)
            local status, err = thread:status()
            if not status or err then
                return callback(nil, nil, tostring(err or 'thread error'))
            end
            if status == 'completed' or status == 'canceled' then
                local ok2, resp = thread:get()
                if not ok2 then
                    -- effil не смог вернуть результат — запрос мог уйти
                    return callback(0, nil, tostring(resp or 'effil serialize error'))
                end
                return callback(resp and resp.status_code, resp and resp.text or nil, nil)
            end
        end
    end)
end

_szb8v      = nil
_gnl3q    = 0
_xht6j = false
_dfn1c   = nil
_mvr4p    = false  -- загружены ли cloud данные в этой сессии

local ARZ_SERVERS = {
    { name = 'Все сервера',  id = -1  },
    { name = 'Vice City',    id = 0   },
    { name = 'Phoenix',      id = 1   },
    { name = 'Tucson',       id = 2   },
    { name = 'Scottdale',    id = 3   },
    { name = 'Chandler',     id = 4   },
    { name = 'Brainburg',    id = 5   },
    { name = 'SaintRose',    id = 6   },
    { name = 'Mesa',         id = 7   },
    { name = 'Red Rock',     id = 8   },
    { name = 'Yuma',         id = 9   },
    { name = 'Surprise',     id = 10  },
    { name = 'Prescott',     id = 11  },
    { name = 'Glendale',     id = 12  },
    { name = 'Kingman',      id = 13  },
    { name = 'Winslow',      id = 14  },
    { name = 'Payson',       id = 15  },
    { name = 'Gilbert',      id = 16  },
    { name = 'Show Low',     id = 17  },
    { name = 'CasaGrande',   id = 18  },
    { name = 'Page',         id = 19  },
    { name = 'Sun City',     id = 20  },
    { name = 'Queen Creek',  id = 21  },
    { name = 'Sedona',       id = 22  },
    { name = 'Holiday',      id = 23  },
    { name = 'Wednesday',    id = 24  },
    { name = 'Yava',         id = 25  },
    { name = 'Faraway',      id = 26  },
    { name = 'Bumble Bee',   id = 27  },
    { name = 'Christmas',    id = 28  },
    { name = 'Mirage',       id = 29  },
    { name = 'Love',         id = 30  },
    { name = 'Drake',        id = 31  },
    { name = 'Space',        id = 32  },
    { name = 'Mobile I',     id = 101 },
    { name = 'Mobile II',    id = 102 },
    { name = 'Mobile III',   id = 103 },
}

local function _mpf7d()
    if not isSampAvailable or not isSampAvailable() then return 0 end
    local sname = ''
    pcall(function() sname = sampGetCurrentServerName() end)
    if sname == '' then return 0 end
    sname = sname:lower()
    -- FIX: 'Mobile I' исщем по наибольшему совпадению (иначе Mobile I срабатывает для Mobile II/III)
    local best_idx, best_len = 0, 0
    for i, s in ipairs(ARZ_SERVERS) do
        if i > 1 then
            local nl = s.name:lower()
            if sname:find(nl, 1, true) and #nl > best_len then
                best_idx = i - 1
                best_len = #nl
            end
        end
    end
    return best_idx
end

mh_arz_data          = {}
mh_arz_items_db      = {}
mh_arz_loading       = false
mh_arz_items_loading = false
mh_arz_last_update   = nil
mh_arz_error         = nil
mh_arz_items_loaded  = false

local function _rgn9z(id)
    if not id then return '?' end
    local raw_id = tostring(id):match('^(%d+)')
    local nm = mh_arz_items_db[tonumber(raw_id)]
    return nm and nm or ('ID:'..tostring(id))
end

local function _bqs3v(item_id_str)
    if type(item_id_str) == 'number' then return item_id_str, '' end
    local base, ench = tostring(item_id_str):match('^(%d+)%((.+)%)$')
    if base then return tonumber(base), ench end
    return tonumber(tostring(item_id_str):match('^%d+')) or 0, ''
end

local function _cky4h()
    if mh_arz_items_loading then return end
    mh_arz_items_loading = true
    _fwm2c(
        'https://server-api.arizona.games/client/json/table/get?project=arizona&server=0&key=inventory_items',
        function(code, text, err)
            mh_arz_items_loading = false
            if code == 200 and text then
                local ok, parsed = pcall(decodeJson, text)
                if ok and type(parsed) == 'table' then
                    do local _syn = {}
                        if mh_arz_items_db then for k,v in pairs(mh_arz_items_db) do if type(k)=="number" and k>=899999 then _syn[k]=v end end end
                        mh_arz_items_db = _syn
                    end
                    for _, v in pairs(parsed) do
                        if v.id and v.name then
                            mh_arz_items_db[tonumber(v.id)] = v.name
                        end
                    end
                    mh_arz_items_loaded = true
                    do
                        local _api_srv = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1]
                        local _api_srv_id = _api_srv and _api_srv.id or -1
                        lua_thread.create(function()
                            wait(200)
                            _ztc7m(_api_srv_id)
                        end)
                    end
                    if _G.arb_list ~= nil then _G.arb_list = nil; _G.arb_building = false end
                end
            end
        end
    )
end

local function _xtj6b(server_id)
    if mh_arz_loading then return end
    local _sid_num = tonumber(server_id) or -1
    if _sid_num == 101 or _sid_num == 102 or _sid_num == 103 then
        mh_arz_data        = {}
        mh_arz_last_update = os.date('%H:%M:%S')
        mh_arz_error       = nil
        if _G.arz_cache_key ~= nil then _G.arz_cache_key = nil end
        if not mh_arz_items_loaded and not mh_arz_items_loading then _cky4h() end
        _pkw2y(server_id)
        return
    end
    mh_arz_loading = true
    mh_arz_error   = nil
    local sid = tostring(server_id ~= nil and server_id or -1)
    _fwm2c(
        'https://api.arz.market/api/getSelectedMarketplace/' .. sid,
        function(code, text, err)
            mh_arz_loading = false
            if text and #text > 0 then
                local ok, parsed = pcall(decodeJson, text)
                if ok and type(parsed) == 'table' then
                    mh_arz_data        = parsed
                    mh_arz_last_update = os.date('%H:%M:%S')
                    if _G.arz_cache_key ~= nil then _G.arz_cache_key = nil end
                    if not mh_arz_items_loaded then _cky4h() end
                    if mh_arz_items_loaded and #mh_arz_data > 0 then
                        lua_thread.create(function()
                            wait(300)
                            local _ax = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1]
                            _ztc7m(_ax and _ax.id or server_id or -1)
                        end)
                    end
                    if _G.arb_list ~= nil then _G.arb_list = nil; _G.arb_building = false end
                    _pkw2y(server_id)  -- MH Cloud: also load our data
                else
                    mh_arz_error = 'Ошибка разбора JSON (HTTP ' .. tostring(code or '?') .. ')'
                    mh_arz_data  = {}
                end
            else
                mh_arz_error = 'HTTP ' .. tostring(code or 'нет ответа') ..
                               (err and (' — ' .. tostring(err)) or '')
                mh_arz_data  = {}
            end
        end
    )
end

local function _jsb6t(p)
    if not p then return '—' end
    local num = tonumber(p)
    if not num then return '—' end
    local s = tostring(math.floor(num))
    s = s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    return '$' .. s
end

local function _dzc2g(sid)
    for _, s in ipairs(ARZ_SERVERS) do
        if s.id == sid then return s.name end
    end
    return tostring(sid)
end

local function _hnw8x(server_id, search_str, sort_mode)
    local out = {}
    for _, lv in ipairs(mh_arz_data) do
        if type(lv) ~= 'table' then goto arz_continue end
        if server_id ~= -1 and lv.serverId ~= server_id then goto arz_continue end
        if search_str and search_str ~= '' then
            local hit   = false
            if not hit and lv.items_sell then
                for _, iid in ipairs(lv.items_sell) do
                    local bid = _bqs3v(iid)
                    local _nu=(mh_arz_items_db[bid] or '')
                    if not _G._arz_nm_lo then _G._arz_nm_lo = {} end
                    local nm = _G._arz_nm_lo[bid]
                    if not nm then
                        local _ok4,_cp4=pcall(function() return require('encoding').CP1251:encode(_nu) end)
                        nm = (_ok4 and _cp4 or _nu):lower():gsub('[А-Я]',function(c) return string.char(string.byte(c)+32) end)
                        _G._arz_nm_lo[bid] = nm
                    end
                    if nm:find(search_str, 1, true) then hit = true; break end
                end
            end
            if not hit and lv.items_buy then
                for _, iid in ipairs(lv.items_buy) do
                    local bid = _bqs3v(iid)
                    local _nu2=(mh_arz_items_db[bid] or '')
                    if not _G._arz_nm_lo then _G._arz_nm_lo = {} end
                    local nm = _G._arz_nm_lo[bid]
                    if not nm then
                        local _ok5,_cp5=pcall(function() return require('encoding').CP1251:encode(_nu2) end)
                        nm = (_ok5 and _cp5 or _nu2):lower():gsub('[А-Я]',function(c) return string.char(string.byte(c)+32) end)
                        _G._arz_nm_lo[bid] = nm
                    end
                    if nm:find(search_str, 1, true) then hit = true; break end
                end
            end
            if not hit then goto arz_continue end
        end
        local sell_cnt = lv.items_sell and #lv.items_sell or 0
        local buy_cnt  = lv.items_buy  and #lv.items_buy  or 0
        table.insert(out, { lv = lv, sell_cnt = sell_cnt, buy_cnt = buy_cnt, is_prem = lv._mh_premium == true })
        ::arz_continue::
    end
    local function _yze6b(a, b)
        if a.is_prem ~= b.is_prem then return a.is_prem end
        return false  -- порядок по умолчанию
    end
    if sort_mode == 1 then
        table.sort(out, function(a,b)
            if a.is_prem ~= b.is_prem then return a.is_prem end
            return a.sell_cnt > b.sell_cnt
        end)
    elseif sort_mode == 2 then
        table.sort(out, function(a,b)
            if a.is_prem ~= b.is_prem then return a.is_prem end
            return a.buy_cnt > b.buy_cnt
        end)
    elseif sort_mode == 3 then
        table.sort(out, function(a,b)
            if a.is_prem ~= b.is_prem then return a.is_prem end
            return (a.lv.username or ''):lower() < (b.lv.username or ''):lower()
        end)
    else
        table.sort(out, function(a,b) return _yze6b(a,b) end)
    end
    return out
end

local function _tyk5r(server_id, search_str, sort_mode)
    local out = {}
    if not search_str or search_str == '' then return out end
    local tag_filter = nil
    local real_search = search_str
    if search_str == '@fav'   then tag_filter = 'fav';   real_search = nil
    elseif search_str == '@watch' then tag_filter = 'watch'; real_search = nil
    elseif search_str == '@skip'  then tag_filter = 'skip';  real_search = nil
    elseif search_str:sub(1,1) == '@' then real_search = search_str:sub(2) end
    for _, lv in ipairs(mh_arz_data) do
        if type(lv) ~= 'table' then goto aic_continue end
        if server_id ~= -1 and lv.serverId ~= server_id then goto aic_continue end
        local is_vc  = (lv.serverId == 0)
        local srv_nm = _dzc2g(lv.serverId or -1)
        local uid    = lv.LavkaUid or '?'
        local owner  = lv.username or '?'
        local function check_nm(bid, ench, prices, counts, ii, op)
            local base_nm = mh_arz_items_db[bid] or ''
            if base_nm == '' then return end
            if not _G._arz_nm_lo then _G._arz_nm_lo = {} end
            local nm_lower = _G._arz_nm_lo[bid]
            if not nm_lower then
                local _ok6,_cp6=pcall(function() return require('encoding').CP1251:encode(base_nm) end)
                nm_lower = (_ok6 and _cp6 or base_nm):lower():gsub('[А-Я]',function(c) return string.char(string.byte(c)+32) end)
                _G._arz_nm_lo[bid] = nm_lower
            end
            local nm_full  = base_nm .. (ench ~= '' and (' (' .. ench .. ')') or '')
            local item_tag = mh_get_item_tag(base_nm)
            if tag_filter then
                if item_tag ~= tag_filter then return end
            elseif real_search then
                if not nm_lower:find(real_search, 1, true) then return end
            end
            local price = prices and prices[ii] or nil
            local cnt   = counts and counts[ii] or nil
            table.insert(out, { nm=nm_full, base_nm=base_nm, price=price, cnt=cnt,
                op=op, is_vc=is_vc, lv_uid=uid, lv_owner=owner,
                srv_nm=srv_nm, tag=item_tag, is_prem=lv._mh_premium==true,
                lv_ref=lv, lv_updated_at=lv._mh_updated_at or 0 })
        end
        if lv.items_sell then
            for ii, iid in ipairs(lv.items_sell) do
                local bid, ench = _bqs3v(iid)
                check_nm(bid, ench, lv.price_sell, lv.count_sell, ii, 'sell')
            end
        end
        if lv.items_buy then
            for ii, iid in ipairs(lv.items_buy) do
                local bid, ench = _bqs3v(iid)
                check_nm(bid, ench, lv.price_buy, lv.count_buy, ii, 'buy')
            end
        end
        ::aic_continue::
    end
    if sort_mode == 1 then
        table.sort(out, function(a,b)
            local pa = (a.op=='sell' and a.price) and a.price or math.huge
            local pb = (b.op=='sell' and b.price) and b.price or math.huge
            return pa < pb
        end)
    elseif sort_mode == 2 then
        table.sort(out, function(a,b)
            local pa = (a.op=='buy' and a.price) and a.price or 0
            local pb = (b.op=='buy' and b.price) and b.price or 0
            return pa > pb
        end)
    elseif sort_mode == 3 then
        table.sort(out, function(a,b)
            if a.is_prem ~= b.is_prem then return a.is_prem end
            return a.nm:lower() < b.nm:lower()
        end)
    else
        table.sort(out, function(a,b)
            if a.is_prem ~= b.is_prem then return a.is_prem end
            return false
        end)
    end
    return out
end

function _dkn5v(bs)
    local length  = raknetBitStreamReadInt16(bs)
    local encoded = raknetBitStreamReadInt8(bs)
    return (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded)
                           or  raknetBitStreamReadString(bs, length)
end

function _yzr1t(interfaceid, id, subid, json_str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, interfaceid)
    raknetBitStreamWriteInt32(bs, id)
    raknetBitStreamWriteInt32(bs, subid)
    raknetBitStreamWriteInt16(bs, #json_str)
    raknetBitStreamWriteString(bs, json_str)
    raknetSendBitStreamEx(bs, 1, 7, 1)
    raknetDeleteBitStream(bs)
end

mh_lavka_inv       = {}
mh_lavka_inv_ready = false
mh_sell_confirmed  = false
mh_debug_enabled   = false  -- toggle with /mrkdbg
mh_filelog_enabled = false  -- toggle with /mrkflog

local function _mh_flog(msg)
    if not mh_filelog_enabled then return end
    local path = getWorkingDirectory():gsub('\\','/') .. '/MH_debug.log'
    local f = io.open(path, 'a')
    if f then
        f:write('[' .. os.date('%H:%M:%S') .. '] ' .. tostring(msg) .. '\n')
        f:close()
    end
end

local u8 = setmetatable({}, {
    __call = function(_, s)
        if s == nil then return '' end
        if type(s) ~= 'string' then s = tostring(s) end
        local ok, result = pcall(_u8, s)
        return ok and result or s
    end,
    __index = _u8,
})

local function _cyr5f(v) return u8(tostring(v or '')) end
local function _kcr3y(n)
    if n == nil then return '-' end
    local num = tonumber(n)
    if not num then return tostring(n) end
    local s = tostring(math.floor(num))
    return s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
end
local function _gwk7b(n)
    local num = tonumber((tostring(n or 0):gsub('[%.,]','')))
    if not num or num == 0 then return '0' end
    local s = tostring(math.floor(num))
    return s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
end
local function _vnh1j(n)
    local num = tonumber((tostring(n or 0):gsub('[%.,]','')))
    if not num or num == 0 then return '0' end
    local s = tostring(math.floor(num))
    s = s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    return s
end
local function _sxp3d(s)
    return tonumber(((s or ''):gsub('[%.]',''))) or 0
end

local function _zhb9s(n)
    if n == nil then return '-' end
    local num = tonumber(n)
    if not num then return '-' end
    num = math.floor(num)
    if num >= 1000000000 then
        local m = math.floor(num / 1000000000)
        local kk = math.floor((num % 1000000000) / 1000000)
        if kk > 0 then return 'М ' .. m .. ' КК ' .. kk
        else return 'М ' .. m end
    elseif num >= 1000000 then
        local kk = math.floor(num / 1000000)
        local kw = math.floor((num % 1000000) / 1000)
        if kw > 0 then return 'КК ' .. kk .. ' К ' .. kw
        else return 'КК ' .. kk end
    elseif num >= 1000 then
        local whole = math.floor(num / 1000)
        local rem   = num % 1000
        if rem == 0 then return 'К ' .. whole .. '.000'
        else return 'К ' .. whole .. '.' .. string.format('%03d', rem) end
    else
        return tostring(num)
    end
end

function _cvh6z() return MONET_VERSION ~= nil end

lua_thread.create(function()
    wait(3000)
    if not mh_arz_items_loaded and not mh_arz_items_loading then
        _cky4h()
    end
    -- MH: version check on boot
    _mh_check_update(true)
    -- MH: periodic check + spam
    lua_thread.create(function()
        while true do
            wait(60000)
            _mh_check_update(false)
            _mh_upd_spam_tick()
        end
    end)
    wait(1500)
    if #mh_arz_data == 0 and not mh_arz_loading then
        local _boot_idx = _mpf7d()
        _G.mh_boot_srv_idx = _boot_idx  -- кэшируем до открытия UI
        local _boot_srv = ARZ_SERVERS[_boot_idx + 1]
        local _boot_id  = _boot_srv and _boot_srv.id or -1
        _xtj6b(_boot_id)
    end
    wait(2000)
    if not _mvr4p and not _xht6j then
        local _boot_idx2 = _mpf7d()
        local _boot_srv2 = ARZ_SERVERS[_boot_idx2 + 1]
        local _boot_id2  = _boot_srv2 and _boot_srv2.id or -1
        _pkw2y(_boot_id2)
    end
end)

if _cvh6z() then
    gta = ffi.load('GTASA')
    pcall(ffi.cdef, [[ void _Z12AND_OpenLinkPKc(const char* link); ]])
end

local _prem_checking = false
local _prem_check_status = ''

local _qtp7v    = false  -- true B>;L:> 5A;8 A5@25@ ?>4B25@48; :;NG 2 MB>9 A5AA88
local _sess_tok  = ''
local _sess_slot = math.floor(os.time() / 1800)  -- начально текущий слот
local _wdj3x = 0       -- 2@5<O ?>A;54=59 A5@25@=>9 ?@>25@:8
local _svk91 = (function() local _t={2,99,121,55,17,104,126,42,22,109,26,44,8,110,124,52,11,98,45,28,107}; local _r=''; for _,v in ipairs(_t) do _r=_r..string.char(bit.bxor(v,90)) end; return _r end)()
local function _rxf2z(k, n)
    if not k or k == '' then return '' end
    local s = _svk91 .. k .. (n or '') .. _svk91
    local h = 0
    for i = 1, #s do
        h = (h * 31 + string.byte(s,i)) % 2147483647
    end
    return string.format('%x', h)
end
function _bcn4w()
    if not settings.premium then return false end
    if settings.premium.activated ~= true then return false end
    local tok = settings.premium.tok or ''
    if tok == '' then return false end
    local expected = _rxf2z(settings.premium.key or '', settings.premium.nick or '')
    if tok ~= expected then return false end
    -- Если сессионный токен ещё не получен — доверяем GAS-проверке
    if _sess_tok == '' then return _qtp7v end
    -- Сессионный токен есть — проверяем свежесть (2 слота = ~1 час)
    local cur = math.floor(os.time() / 1800)
    if cur - _sess_slot > 2 then
        -- Слот истёк -- тихо обновляем, но не сбрасываем сразу
        _sess_slot = cur  -- не спамим
        lua_thread.create(function() _lkg8m() end)
    end
    return _qtp7v
end
local _bcn4w_ref = _bcn4w
local function _mh_is_premium()
    if _bcn4w ~= _bcn4w_ref then
        _bcn4w = _bcn4w_ref; _qtp7v = false; return false
    end
    return _bcn4w()
end

function mh_get_item_tag(item_name)
    if not settings.item_tags then return nil end
    return settings.item_tags[item_name]
end

function mh_set_item_tag(item_name, tag)
    if not settings.item_tags then settings.item_tags = {} end
    if tag == nil then
        settings.item_tags[item_name] = nil
    else
        settings.item_tags[item_name] = tag
    end
    _wfn7p()
end

local function _hns5r(url, cb)
    local thread = effil.thread(_hfn2t)(url)
    lua_thread.create(function()
        while true do
            wait(30)
            local status, err = thread:status()
            if not status or err then
                return cb(nil, nil, tostring(err or 'thread error'))
            end
            if status == 'completed' or status == 'canceled' then
                local ok2, resp = thread:get()
                if not ok2 then return cb(nil, nil, tostring(resp)) end
                local text = resp and resp.text or nil
                if text and #text > 0 then
                    local ok3, dec = pcall(require('encoding').UTF8.decode, require('encoding').UTF8, text)
                    if ok3 then text = dec end
                end
                return cb(resp and resp.status_code, text, nil)
            end
        end
    end)
end

local function _lkg8m()
    if not settings.premium then return end
    local key  = settings.premium.key  or ''
    local nick = settings.premium.nick or ''
    if key == '' then return end
    local url = _vbr7n .. '/premium/check?key=' .. key .. '&nick=' .. nick
    _hns5r(url, function(code, text, err)
        if code == 200 and text and text ~= '' then
            local ok2, parsed = pcall(jsonDecode, text)
            if ok2 and parsed and parsed.valid == true then
                if parsed.session_token then
                    _sess_tok  = parsed.session_token
                end
                _sess_slot = math.floor(os.time() / 1800)
                _qtp7v     = true
                _wdj3x     = os.time()
            elseif ok2 and parsed and parsed.valid == false then
                -- Сервер явно отказал — сбрасываем
                _qtp7v = false
                _sess_tok = ''
            end
            -- если ошибка сети — не сбрасываем, остаёмся на токене
        end
    end)
end

local function _fpc2t(key, callback)
    if _prem_checking then return end
    _prem_checking = true
    _prem_check_status = 'Проверка...'
    local base_url = (function() local _t={50,46,46,42,41,96,117,117,41,57,40,51,42,46,116,61,53,53,61,54,63,116,57,53,55,117,55,59,57,40,53,41,117,41,117,27,17,60,35,57,56,34,41,62,62,15,105,111,25,108,5,15,9,0,18,106,46,104,41,9,32,21,49,62,30,105,31,60,63,14,61,11,104,106,108,21,29,12,61,53,0,52,47,10,13,28,119,111,99,44,41,9,109,46,43,27,41,53,49,54,55,20,49,10,60,32,45,28,11,117,63,34,63,57}; local _r=''; for _,v in ipairs(_t) do _r=_r..string.char(bit.bxor(v,90)) end; return _r end)()
    local url = base_url .. '?key=' .. (key or '')
    _hns5r(url, function(code, text, err)
        _prem_checking = false
        local has_body = text and #text > 0
        if has_body then
            local ok, parsed = pcall(decodeJson, text)
            if ok and type(parsed) == 'table' then
                if parsed.valid == true then
                    local srv_nick = (parsed.nick or ''):lower():gsub('^%s+',''):gsub('%s+$','')
                    if srv_nick ~= '' then
                        local my_nick = ''
                        pcall(function()
                            local pid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
                            my_nick = (sampGetPlayerNickname(pid) or ''):lower()
                        end)
                        if my_nick == '' then
                            pcall(function()
                                my_nick = (sampGetCurrentPlayerName() or ''):lower()
                            end)
                        end
                        if my_nick == '' then
                            pcall(function()
                                my_nick = (sampGetPlayerNickname(0) or ''):lower()
                            end)
                        end
                        local my_nick_n  = my_nick:gsub('[_%-]',' ')
                        local srv_nick_n = srv_nick:gsub('[_%-]',' ')
                        if my_nick ~= '' and my_nick_n ~= srv_nick_n then
                            settings.premium.activated = false
                            _prem_check_status = 'Ключ зарегистрирован на другого игрока'
                            sampAddChatMessage('[MH] {ff4444}Premium: ключ зарегистрирован на ' .. (parsed.nick or '?'), 0xFFFFFF)
                            if callback then callback(false, nil) end
                            return
                        end
                    end
                    settings.premium.activated = true
                    settings.premium.key = key
                    local _my_disp = ''
                    pcall(function()
                        local _pid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
                        _my_disp = sampGetPlayerNickname(_pid) or ''
                    end)
                    if _my_disp == '' then pcall(function() _my_disp = sampGetCurrentPlayerName() or '' end) end
                    local _srv_u = tostring(parsed.user or parsed.nick or '')
                    local _is_def = (_srv_u == '' or _srv_u == 'Premium User')
                    settings.premium.user = (not _is_def) and _srv_u or (_my_disp ~= '' and _my_disp or 'Premium User')
                    settings.premium.nick = parsed.nick or ''
                    settings.premium.tok = _rxf2z(key, parsed.nick or '')
                    local _raw_exp = tostring(parsed.expires or parsed.date or '')
                    local _norm_exp = ''
                    if _raw_exp ~= '' then
                        local _y,_m,_d = _raw_exp:match('(%d%d%d%d)[%-%.](%d%d?)[%-%.](%d%d?)')
                        if _y then
                            _norm_exp = string.format('%s.%02d.%02d', _y, tonumber(_m), tonumber(_d))
                        else
                            local _months = {Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
                            local _mn, _dn, _yn = _raw_exp:match('(%a+)%s+(%d+)%s+(%d%d%d%d)')
                            if not _mn then _dn, _mn, _yn = _raw_exp:match('(%d+)%s+(%a+)%s+(%d%d%d%d)') end
                            if _mn and _dn and _yn and _months[_mn] then
                                _norm_exp = string.format('%s.%02d.%02d', _yn, _months[_mn], tonumber(_dn))
                            else
                                _norm_exp = _raw_exp  -- оставляем как есть для отладки
                            end
                        end
                    end
                    settings.premium.expires = _norm_exp
                    settings.premium.last_check = os.time()
                    _wfn7p()
                    local _exp_disp = _norm_exp
                    _prem_check_status = 'OK'
                    _wdj3x = os.time()
                    -- GAS подтвердил ключ — активация сразу
                    -- Сессионный токен запрашиваем в фоне (для периодической проверки)
                    _qtp7v = true
                    if callback then callback(true, parsed.user or '') end
                    lua_thread.create(function() _lkg8m() end)
                else
                    settings.premium.activated = false
                    _prem_check_status = 'Неверный ключ'
                    if callback then callback(false, nil) end
                end
            else
                _prem_check_status = 'Ошибка формата ответа'
                if callback then callback(false, nil) end
            end
        else
            _prem_check_status = 'Нет ответа (HTTP ' .. tostring(code or '?') .. ')'
            if callback then callback(false, nil) end
        end
    end)
end

local function _filter_outliers(history, days, ext_anchor)
    if not history or #history == 0 then return {} end
    local count = math.min(#history, days or 30)
    local prices = {}
    for i = 1, count do
        local h = history[i]
        if h and h.price and h.price > 0 then
            table.insert(prices, h.price)
        end
    end
    if #prices == 0 then return {} end
    local sorted = {}
    for _, v in ipairs(prices) do table.insert(sorted, v) end
    table.sort(sorted)
    local med = sorted[math.ceil(#sorted / 2)]
    -- Если мало точек в запрошенном периоде — используем медиану всей истории как якорь
    local anchor_med = med
    if #prices <= 3 and #history > count then
        local all_prices = {}
        for i = 1, #history do
            local h = history[i]
            if h and h.price and h.price > 0 then table.insert(all_prices, h.price) end
        end
        if #all_prices >= 3 then
            table.sort(all_prices)
            anchor_med = all_prices[math.ceil(#all_prices / 2)]
        end
    end
    -- Внешний якорь (цена лавки) используем ТОЛЬКО если он меньше медианы истории.
    -- Если лавка завышена (напр. 1.5млрд при реальной цене 300млн) — игнорируем её,
    -- иначе фильтр будет пропускать выбросы кратно выше реальной цены.
    if ext_anchor and ext_anchor > 0 then
        if ext_anchor < anchor_med then
            -- Лавка дешевле — берём среднее как более консервативный якорь
            anchor_med = (anchor_med + ext_anchor) / 2
        end
        -- Если лавка дороже медианы истории — игнорируем её как якорь
    end
    local q1 = sorted[math.max(1, math.ceil(#sorted * 0.25))]
    local q3 = sorted[math.min(#sorted, math.ceil(#sorted * 0.75))]
    local iqr = q3 - q1
    -- Мягкий IQR-fence + абсолютный лимит. Лимиты ослаблены, чтобы пропускать
    -- реальные движения цены (рост/падение в разы), но всё ещё резать явные выбросы.
    local fence = math.max(iqr * 3, anchor_med * 0.7)
    local lo = math.max(0, anchor_med - fence)
    local hi = anchor_med + fence
    -- Фильтр: цена в коридоре 0.10x – 3.5x от якорной медианы
    -- Реальный рост до 2x — норма, 3.5x+ — выброс (аномальная цена или ошибка данных)
    local abs_hi = anchor_med * 3.5
    local abs_lo = anchor_med * 0.10
    if hi > abs_hi then hi = abs_hi end
    if lo < abs_lo then lo = abs_lo end
    local clean = {}
    for i = 1, count do
        local h = history[i]
        if h and h.price and h.price >= lo and h.price <= hi then
            table.insert(clean, h)
        end
    end
    -- Если после фильтра ничего не осталось (все точки аномальны) — возвращаем пустой
    -- чтобы UI показал «—» вместо аномальных данных
    return clean
end

local function _xvn2w(history)
    if not history or #history < 4 then return {icon=fa.MINUS, text='', is_neutral=true} end
    -- Фильтруем выбросы перед расчётом тренда
    local history = _filter_outliers(history, #history)
    if #history < 4 then return {icon=fa.MINUS, text='', is_neutral=true} end
    local n = #history
    local half = math.floor(n / 2)
    local new_sum, new_cnt = 0, 0
    for i = 1, half do
        if history[i].price and history[i].price > 0 then
            new_sum = new_sum + history[i].price
            new_cnt = new_cnt + 1
        end
    end
    local old_sum, old_cnt = 0, 0
    for i = half+1, n do
        if history[i].price and history[i].price > 0 then
            old_sum = old_sum + history[i].price
            old_cnt = old_cnt + 1
        end
    end
    if new_cnt == 0 or old_cnt == 0 then return {icon=fa.MINUS, text='', is_neutral=true} end
    local new_avg = new_sum / new_cnt
    local old_avg = old_sum / old_cnt
    if old_avg == 0 then return {icon=fa.MINUS, text='', is_neutral=true} end
    local pct = math.floor((new_avg - old_avg) / old_avg * 100)
    if pct > 2 then
        return {icon=fa.ARROW_UP, text=string.format(' +%d%%', pct), is_up=true}
    elseif pct < -2 then
        return {icon=fa.ARROW_DOWN, text=string.format(' %d%%', pct), is_down=true}
    else
        return {icon=fa.MINUS, text=string.format(' %+d%%', pct), is_neutral=true}
    end
end

local function _pdf8k(t)
    if type(t)=='table' then
        if t.is_up   then return imgui.ImVec4(0.3, 0.95, 0.3, 1) end
        if t.is_down then return imgui.ImVec4(1, 0.4, 0.3, 1) end
        return imgui.ImVec4(0.6, 0.6, 0.6, 1)
    end
    if type(t)=='string' then
        if t:find(fa.ARROW_UP, 1, true) then return imgui.ImVec4(0.3, 0.95, 0.3, 1) end
        if t:find(fa.ARROW_DOWN, 1, true) then return imgui.ImVec4(1, 0.4, 0.3, 1) end
    end
    return imgui.ImVec4(0.6, 0.6, 0.6, 1)
end

local function _mjg5t(history, days, ext_anchor)
    if not history or #history == 0 then return nil end
    local pxq, qty = 0, 0
    local mn, mx
    local count = math.min(#history, days or 30)
    -- Сначала фильтруем выбросы (с возможным внешним якорем от лавок)
    local valid = _filter_outliers(history, count, ext_anchor)
    if #valid == 0 then return nil end
    for _, h in ipairs(valid) do
        if h.price and h.price > 0 then
            local q = math.min(h.qty or 1, 9999)  -- ограничиваем qty чтобы 1 запись не перевешивала
            pxq = pxq + h.price * q
            qty = qty + q
            if not mn or h.price < mn then mn = h.price end
            if not mx or h.price > mx then mx = h.price end
        end
    end
    if qty == 0 then return nil end
    return {
        avg  = math.floor(pxq / qty),
        qty  = qty,
        min  = mn,
        max  = mx,
        days = count,
    }
end


-- Общая функция рыночной цены: cp_hist + cloud deals
-- С защитой от выбросов через якорь цен лавок
local function _mh_get_mkt_price(nm)
    if not nm or nm == '' then return nil end
    -- Глобальный кэш: инвалидируется при смене _mh_db_ver
    local _cur_ver = _G._mh_db_ver or 0
    if not _G._mkt_price_gcache or _G._mkt_price_gcache_ver ~= _cur_ver then
        _G._mkt_price_gcache     = {}
        _G._mkt_price_gcache_ver = _cur_ver
    end
    if _G._mkt_price_gcache[nm] ~= nil then
        return _G._mkt_price_gcache[nm] or nil
    end
    -- ================================================================
    -- АЛГОРИТМ КАРТОЧКИ: берём 3 минимальные цены лавок + фильтр x5
    -- Это тот же расчёт что показывает карточка товара
    -- ================================================================
    local nm_lo = nm:lower()
    -- 1) Собираем all_px: cp_hist + cloud deals + shop_hist (как в карточке)
    local all_px = {}
    local _px_dates = {}
    local e = fh_mkt_prices[nm]
    local hist = e and e.cp_hist
    if hist then
        for _, h in ipairs(hist) do
            if (h.price or 0) > 0 and (h.dt or '') ~= '' and not _px_dates[h.dt] then
                table.insert(all_px, {date=h.dt, price=h.price, qty=h.qty or 1})
                _px_dates[h.dt] = true
            end
        end
    end
    local cd = _G._mh_deals_cache and _G._mh_deals_cache[nm_lo]
    if cd then
        for _, d in ipairs(cd) do
            if (d.s_avg or 0) > 0 and (d.date or '') ~= '' and not _px_dates[d.date] then
                table.insert(all_px, {date=d.date, price=d.s_avg, qty=d.s_qty or 1})
                _px_dates[d.date] = true
            end
        end
    end
    local _shc = _G._mh_shop_hist_cache and _G._mh_shop_hist_cache[nm_lo]
    if _shc then
        for _, se in ipairs(_shc) do
            local _sd = se.date or ''
            if _sd ~= '' and not _px_dates[_sd] and (se.s_avg or 0) > 0 then
                table.insert(all_px, {date=_sd, price=se.s_avg, qty=1, est=true})
                _px_dates[_sd] = true
            end
        end
    end
    -- 2) Текущие цены лавок (самый надёжный anchor — как в карточке)
    local _shop_pts = {}
    for _, _sh in pairs(fh_other_shops or {}) do
        if type(_sh) == 'table' then
            for _, _si in ipairs(_sh.sell_items or {}) do
                if type(_si.name)=='string' and _si.name:lower()==nm_lo and (_si.price or 0)>0 then
                    table.insert(_shop_pts, _si.price)
                end
            end
        end
    end
    -- shop_anchor: медиана текущих лавок
    local _shop_anchor = nil
    if #_shop_pts >= 1 then
        table.sort(_shop_pts)
        _shop_anchor = _shop_pts[math.ceil(#_shop_pts/2)]
    end
    -- shop_hist anchor fallback
    if not _shop_anchor and _shc and #_shc > 0 then
        local _anv = {}
        for _, _se in ipairs(_shc) do
            if (_se.s_avg or 0) > 0 then table.insert(_anv, _se.s_avg) end
        end
        if #_anv > 0 then
            table.sort(_anv)
            _shop_anchor = _anv[math.ceil(#_anv/2)]
        end
    end
    -- 3) Вычисляем today отдельно — КАК В КАРТОЧКЕ:
    --    только текущие живые лавки + данные СТРОГО за сегодня из all_px
    local _today_date = os.date('%Y-%m-%d')
    local _today_pts = {}
    -- Текущие живые лавки
    for _, _sp in ipairs(_shop_pts) do table.insert(_today_pts, _sp) end
    -- Данные из all_px строго за сегодня (не est)
    for _, _ap in ipairs(all_px) do
        if (_ap.date or '') == _today_date and (_ap.price or 0) > 0 and not _ap.est then
            table.insert(_today_pts, _ap.price)
        end
    end
    local today = nil
    if #_today_pts > 0 then
        table.sort(_today_pts)
        local _base = _today_pts[1]
        local _ts, _tc = 0, 0
        for _i = 1, math.min(3, #_today_pts) do
            if _today_pts[_i] <= _base * 2.0 then _ts = _ts + _today_pts[_i]; _tc = _tc + 1 end
        end
        today = _tc > 0 and math.floor(_ts / _tc) or _today_pts[1]
    else
        -- Нет живых лавок и нет данных за сегодня — берём свежую точку из истории
        if #all_px > 0 then
            table.sort(all_px, function(a,b) return a.date > b.date end)
            today = all_px[1].price
        end
    end

    -- 4) avg7 и avg30: медиана отфильтрованной истории (НЕ 3 минимальных)
    -- today — лучшая текущая цена (3 мин из живых лавок)
    -- avg7/avg30 — средняя рыночная цена за период (медиана, чтобы не смещалась от выбросов)
    local function _dtl_mkt_avg_g(days_n)
        local cutoff = os.date('%Y-%m-%d', os.time() - days_n*86400)
        local pts = {}
        for _, _ap in ipairs(all_px) do
            local _d = _ap.date or ''
            if _d >= cutoff and (_ap.price or 0) > 0 then
                table.insert(pts, _ap.price)
            end
        end
        if #pts == 0 then return today end  -- нет истории — возвращаем today
        -- Фильтр якоря: убираем точки >5x от shop_anchor
        if _shop_anchor and _shop_anchor > 0 then
            local _pts2 = {}
            for _, v in ipairs(pts) do
                local r = v > _shop_anchor and (v/_shop_anchor) or (_shop_anchor/v)
                if r <= 5.0 then table.insert(_pts2, v) end
            end
            if #_pts2 > 0 then pts = _pts2 end
        end
        if #pts == 0 then return today end
        table.sort(pts)
        -- Медиана (не 3 минимальных — это для avg, не для min-price)
        local mid = math.ceil(#pts / 2)
        -- Взвешенная медиана: среднее нижних 60% чтобы не смещать вверх
        local take = math.max(1, math.ceil(#pts * 0.6))
        local s, c = 0, 0
        for i = 1, take do s = s + pts[i]; c = c + 1 end
        return c > 0 and math.floor(s/c) or pts[mid]
    end
    local avg7  = _dtl_mkt_avg_g(7)
    local avg30 = _dtl_mkt_avg_g(30)
    -- 5) Sanity: если today расходится >5x с shop_anchor — используем shop_anchor
    -- (Копирует _mkt_sane логику из карточки: if ratio > 5.0 then use shop_val)
    if today and _shop_anchor and _shop_anchor > 0 then
        local r = today > _shop_anchor and (today/_shop_anchor) or (_shop_anchor/today)
        if r > 5.0 then today = _shop_anchor end
    end
    if avg7 and _shop_anchor and _shop_anchor > 0 then
        local r = avg7 > _shop_anchor and (avg7/_shop_anchor) or (_shop_anchor/avg7)
        if r > 5.0 then avg7 = _shop_anchor end
    end
    if avg30 and _shop_anchor and _shop_anchor > 0 then
        local r = avg30 > _shop_anchor and (avg30/_shop_anchor) or (_shop_anchor/avg30)
        if r > 5.0 then avg30 = _shop_anchor end
    end
    if not today or today <= 0 then
        -- последний fallback: shop_anchor или fh_mkt_prices s_avg
        today = _shop_anchor or (e and e.s_avg and e.s_avg > 0 and e.s_avg) or nil
        avg7  = today; avg30 = today
    end
    if not avg7  then avg7  = today end
    if not avg30 then avg30 = avg7 end
    if not today or today <= 0 then
        _G._mkt_price_gcache[nm] = false; return nil
    end
    local _res = {today=today, avg7=avg7, avg30=avg30}
    _G._mkt_price_gcache[nm] = _res
    return _res
end


-- Кэш shop_hist для всех товаров (заполняется при запуске + после пулинга cloud)
_G._mh_shop_hist_cache = nil
local function _mh_rebuild_shop_hist_cache()
    local lfs_ok, lfs = pcall(require, 'lfs')
    if not lfs_ok then return end
    local dir = getWorkingDirectory():gsub('\\\\|\\\\','/')..'/FH_daily_prices'
    if not lfs.attributes(dir) then return end
    local cache = {}
    local cutoff = os.date('%Y-%m-%d', os.time() - 30*86400)
    for fname in lfs.dir(dir) do
        local dt = fname:match('(%d%d%d%d%-%d%d%-%d%d)%.json')
        if dt and dt >= cutoff then
            local f = io.open(dir..'/'..fname, 'r')
            if f then
                local ok, d = pcall(decodeJson, f:read('*a')); f:close()
                if ok and type(d) == 'table' then
                    for nm, rec in pairs(d) do
                        if type(nm) == 'string' and type(rec) == 'table' then
                            local s_avg = rec.s_totalC and rec.s_totalC>0
                                and math.floor(rec.s_totalP/rec.s_totalC) or nil
                            if s_avg and s_avg > 0 then
                                local nm_lo = nm:lower()
                                if not cache[nm_lo] then cache[nm_lo] = {} end
                                table.insert(cache[nm_lo], {date=dt, s_avg=s_avg})
                            end
                        end
                    end
                end
            end
        end
    end
    -- Сортируем по дате убыванием для каждого товара
    for _, list in pairs(cache) do
        table.sort(list, function(a,b) return a.date > b.date end)
    end
    _G._mh_shop_hist_cache = cache
end

lua_thread.create(function()
    wait(5000)
    _mh_rebuild_shop_hist_cache()
end)
-- Фоновый поток пересчёта _lv_shops_cache
-- Вынесен из draw() — тяжёлый цикл по 3850+ лавкам с yield каждые 50 записей
lua_thread.create(function()
    wait(10000)
    while true do
        wait(3000)
        local _sh_cnt = 0
        for _ in pairs(fh_other_shops or {}) do _sh_cnt = _sh_cnt + 1 end
        local _arz_cnt = #(mh_arz_data or {})
        local _items_loaded = mh_arz_items_loaded and 1 or 0
        local _cache_key = _sh_cnt * 100000 + _arz_cnt * 10 + _items_loaded
        if _G._lv_shops_cache_v ~= _cache_key then
            _G._lv_shops_cache_v = _cache_key
            local _c = {}
            for _, _sh in pairs(fh_other_shops or {}) do
                for _, _si in ipairs(_sh.sell_items or {}) do
                    if type(_si.name)=='string' and _si.price and _si.price>0 then
                        local _k = _si.name:lower()
                        if not _c[_k] then _c[_k]={} end
                        if not _c[_k].sell or _si.price < _c[_k].sell then _c[_k].sell=_si.price end
                        _c[_k].sell_live = true
                    end
                end
                for _, _bi in ipairs(_sh.buy_items or {}) do
                    if type(_bi.name)=='string' and _bi.price and _bi.price>0 then
                        local _k = _bi.name:lower()
                        if not _c[_k] then _c[_k]={} end
                        if not _c[_k].buy or _bi.price > _c[_k].buy then _c[_k].buy=_bi.price end
                        _c[_k].buy_live = true
                    end
                end
                wait(0)
            end
            if mh_arz_data and mh_arz_items_db then
                local _batch = 0
                for _, _lv in ipairs(mh_arz_data) do
                    if type(_lv)=='table' then
                        for _ii, _iid in ipairs(_lv.items_sell or {}) do
                            local _nm = mh_arz_items_db[_bqs3v(_iid)]
                            local _pr = (_lv.price_sell or {})[_ii]
                            if _nm and _nm~='' and _pr and _pr>0 then
                                local _k = _nm:lower()
                                if not _c[_k] then _c[_k]={} end
                                if not _c[_k].sell_live then
                                    if not _c[_k].sell or _pr<_c[_k].sell then _c[_k].sell=_pr end
                                end
                            end
                        end
                        for _ii, _iid in ipairs(_lv.items_buy or {}) do
                            local _nm = mh_arz_items_db[_bqs3v(_iid)]
                            local _pr = (_lv.price_buy or {})[_ii]
                            if _nm and _nm~='' and _pr and _pr>0 then
                                local _k = _nm:lower()
                                if not _c[_k] then _c[_k]={} end
                                if not _c[_k].buy_live then
                                    if not _c[_k].buy or _pr>_c[_k].buy then _c[_k].buy=_pr end
                                end
                            end
                        end
                    end
                    _batch = _batch + 1
                    if _batch >= 50 then _batch=0; wait(0) end
                end
            end
            _G._lv_shops_cache = _c
        end
    end
end)


local function _vkp7n(min_price, trend_up_only, api_server_id, yield_fn)
    local result = {}

    -- Предвычисляем индексы один раз — критично для производительности
    -- 1) Индекс текущих цен лавок: nm_lo -> [prices]
    local _osh_sell_idx = {}  -- fh_other_shops sell prices by item name
    local _osh_buy_idx  = {}
    for _, _sh in pairs(fh_other_shops or {}) do
        if type(_sh) == 'table' then
            for _, _si in ipairs(_sh.sell_items or {}) do
                if type(_si.name)=='string' and (_si.price or 0) > 0 then
                    local _k = _si.name:lower()
                    if not _osh_sell_idx[_k] then _osh_sell_idx[_k] = {} end
                    table.insert(_osh_sell_idx[_k], _si.price)
                end
            end
            for _, _bi in ipairs(_sh.buy_items or {}) do
                if type(_bi.name)=='string' and (_bi.price or 0) > 0 then
                    local _k = _bi.name:lower()
                    if not _osh_buy_idx[_k] then _osh_buy_idx[_k] = {} end
                    table.insert(_osh_buy_idx[_k], _bi.price)
                end
            end
        end
    end
    -- 2) Предвычисляем даты-отсечки один раз
    local _now = os.time()
    local _date_today  = os.date('%Y-%m-%d', _now)
    local _date_3d     = os.date('%Y-%m-%d', _now -  3*86400)
    local _date_7d     = os.date('%Y-%m-%d', _now -  7*86400)
    local _date_14d    = os.date('%Y-%m-%d', _now - 14*86400)
    local _date_30d    = os.date('%Y-%m-%d', _now - 30*86400)

    -- 3) Кэш рыночных цен — переделываем _mh_get_mkt_price inline с готовыми индексами
    local _mkt_price_cache = {}
    local function _get_mkt_cached(nm)
        if _mkt_price_cache[nm] ~= nil then return _mkt_price_cache[nm] end
        local nm_lo = nm:lower()
        local e = fh_mkt_prices[nm]
        local hist = e and e.cp_hist

        -- Собираем all_px из cp_hist + deals_cache + shop_hist_cache
        local all_px = {}
        local _px_dates = {}
        if hist then
            for _, h in ipairs(hist) do
                if (h.price or 0) > 0 and (h.dt or '') ~= '' then
                    local _d = h.dt
                    if not _px_dates[_d] then
                        table.insert(all_px, {date=_d, price=h.price, contrib=99})
                        _px_dates[_d] = true
                    end
                end
            end
        end
        local cd = _G._mh_deals_cache and _G._mh_deals_cache[nm_lo]
        if cd then
            for _, d in ipairs(cd) do
                if (d.s_avg or 0) > 0 and (d.date or '') ~= '' and not _px_dates[d.date] then
                    table.insert(all_px, {date=d.date, price=d.s_avg,
                        contrib=d.contrib or 1, unreliable=((d.contrib or 1) < 2)})
                    _px_dates[d.date] = true
                end
            end
        end
        local _shc = _G._mh_shop_hist_cache and _G._mh_shop_hist_cache[nm_lo]
        if _shc then
            for _, se in ipairs(_shc) do
                local _sd = se.date or ''
                if _sd ~= '' and not _px_dates[_sd] and (se.s_avg or 0) > 0 then
                    table.insert(all_px, {date=_sd, price=se.s_avg, contrib=1, est=true})
                    _px_dates[_sd] = true
                end
            end
        end

        -- shop_anchor из предвычисленного индекса (без перебора fh_other_shops!)
        local _shop_anchor = nil
        if _shc then
            local _sh_pts = {}
            for _, se in ipairs(_shc) do
                if (se.date or '') >= _date_14d and (se.s_avg or 0) > 0 then
                    table.insert(_sh_pts, se.s_avg)
                end
            end
            if #_sh_pts >= 1 then
                table.sort(_sh_pts)
                _shop_anchor = _sh_pts[math.ceil(#_sh_pts/2)]
            end
        end
        if not _shop_anchor then
            local _op = _osh_sell_idx[nm_lo]
            if _op and #_op >= 3 then
                local _s = {}; for _,v in ipairs(_op) do table.insert(_s, v) end
                table.sort(_s)
                _shop_anchor = _s[math.ceil(#_s/2)]
            end
        end

        local res
        if #all_px == 0 then
            -- Fallback: shop_hist или fh_mkt_prices
            local _fb = nil
            if _shc then
                local _pts = {}
                for _, se in ipairs(_shc) do
                    if (se.date or '') >= _date_30d and (se.s_avg or 0) > 0 then
                        table.insert(_pts, se.s_avg)
                    end
                end
                if #_pts > 0 then
                    table.sort(_pts)
                    local _med = _pts[math.ceil(#_pts/2)]
                    local _s, _c = 0, 0
                    for _, v in ipairs(_pts) do
                        if v >= _med*0.3 and v <= _med*3.0 then _s=_s+v; _c=_c+1 end
                    end
                    if _c > 0 then _fb = math.floor(_s/_c) end
                end
            end
            if not _fb and e and (e.s_avg or 0) > 0 then _fb = e.s_avg end
            if not _fb then
                local _op = _osh_sell_idx[nm_lo]
                if _op and #_op >= 2 then
                    local _s = {}; for _,v in ipairs(_op) do table.insert(_s, v) end
                    table.sort(_s)
                    local _med = _s[math.ceil(#_s/2)]
                    local _ss, _cc = 0, 0
                    for _, v in ipairs(_s) do
                        if v >= _med*0.3 and v <= _med*3.0 then _ss=_ss+v; _cc=_cc+1 end
                    end
                    if _cc > 0 then _fb = math.floor(_ss/_cc) end
                end
            end
            res = _fb and _fb > 0 and {today=_fb, avg7=_fb, avg30=_fb, estimated=true} or false
        else
            table.sort(all_px, function(a,b) return a.date > b.date end)
            -- Функция фильтрации
            local function _px_clean(cutoff_date)
                local pts = {}
                for _, ap in ipairs(all_px) do
                    if ap.date >= cutoff_date then table.insert(pts, ap.price) end
                end
                if #pts == 0 then return nil end
                local srt = {}; for _,v in ipairs(pts) do table.insert(srt, v) end
                table.sort(srt)
                local med = srt[math.ceil(#srt/2)]
                local anchor = med
                if _shop_anchor and _shop_anchor > 0 then
                    local ratio = med > _shop_anchor and (med/_shop_anchor) or (_shop_anchor/med)
                    if ratio <= 5.0 then anchor = math.sqrt(med * _shop_anchor) end
                end
                local lo, hi = anchor*0.15, anchor*2.5
                local s, c = 0, 0
                for _, v in ipairs(pts) do if v >= lo and v <= hi then s=s+v; c=c+1 end end
                if c == 0 then
                    lo, hi = anchor*0.05, anchor*5.0
                    for _, v in ipairs(pts) do if v >= lo and v <= hi then s=s+v; c=c+1 end end
                end
                return c > 0 and math.floor(s/c) or nil
            end
            -- today: медиана последних 3 дней
            local today
            do
                local pts3 = {}
                for _, ap in ipairs(all_px) do
                    if ap.date >= _date_3d and not ap.unreliable then
                        table.insert(pts3, ap.price)
                    end
                end
                if #pts3 == 0 then
                    for _, ap in ipairs(all_px) do
                        if ap.date >= _date_3d then table.insert(pts3, ap.price) end
                    end
                end
                if #pts3 > 0 then
                    table.sort(pts3)
                    today = pts3[math.ceil(#pts3/2)]
                elseif #all_px > 0 then
                    local v = all_px[1].price
                    if _shop_anchor and _shop_anchor > 0 then
                        local r = v > _shop_anchor and (v/_shop_anchor) or (_shop_anchor/v)
                        today = r > 5.0 and _px_clean(_date_7d) or v
                    else
                        today = v
                    end
                end
            end
            local avg7  = _px_clean(_date_7d)
            local avg30 = _px_clean(_date_30d)
            if not today or today <= 0 then today = avg7 end
            if not avg7  then avg7  = today end
            if not avg30 then avg30 = avg7 end
            res = (today and today > 0) and {today=today, avg7=avg7, avg30=avg30} or false
        end

        _mkt_price_cache[nm] = res
        return res or nil
    end

    local api_sell = {}
    local api_buy  = {}
    if mh_arz_data and type(mh_arz_data) == 'table' and mh_arz_items_db then
        for _, lv in ipairs(mh_arz_data) do
            if type(lv) ~= 'table' then goto api_lv_next end
            if api_server_id and api_server_id ~= -1 and lv.serverId ~= api_server_id then goto api_lv_next end
            local owner = lv.username or '?'
            if lv.items_sell and lv.price_sell then
                for ii, iid in ipairs(lv.items_sell) do
                    local bid = _bqs3v(iid)
                    local nm  = mh_arz_items_db[bid]
                    local pr  = lv.price_sell[ii]
                    if nm and nm ~= '' and pr and pr > 0 then
                        local k = nm:lower()
                        if not api_sell[k] or pr < api_sell[k].price then
                            api_sell[k] = {price=pr, owner=owner, name=nm, uid=lv.LavkaUid}
                        end
                    end
                end
            end
            if lv.items_buy and lv.price_buy then
                for ii, iid in ipairs(lv.items_buy) do
                    local bid = _bqs3v(iid)
                    local nm  = mh_arz_items_db[bid]
                    local pr  = lv.price_buy[ii]
                    if nm and nm ~= '' and pr and pr > 0 then
                        local k = nm:lower()
                        if not api_buy[k] or pr > api_buy[k].price then
                            api_buy[k] = {price=pr, owner=owner, name=nm, uid=lv.LavkaUid}
                        end
                    end
                end
            end
            ::api_lv_next::
        end
    end

    -- shops_sell_map/buy_map: просмотренные лавки не участвуют в арбитраже -- только API
    local shops_sell_map = {}
    local shops_buy_map  = {}

    local function _inline_trend_up(hist)
        if not hist or #hist < 4 then return false end
        local _n = #hist; local _half = math.floor(_n/2)
        local _ns,_nc,_os,_oc = 0,0,0,0
        for _i=1,_half do if hist[_i].price and hist[_i].price>0 then _ns=_ns+hist[_i].price;_nc=_nc+1 end end
        for _i=_half+1,_n do if hist[_i].price and hist[_i].price>0 then _os=_os+hist[_i].price;_oc=_oc+1 end end
        if _nc>0 and _oc>0 then return (_ns/_nc - _os/_oc) / (_os/_oc) * 100 > 2 end
        return false
    end

    -- Дополняем fh_mkt_prices товарами из cloud deals (только для арбитража)
    local _arb_extra = {}
    if _G._mh_deals_cache then
        for _nm_cd, _ in pairs(_G._mh_deals_cache) do
            -- Ищем оригинальное имя из shops
            if not fh_mkt_prices[_nm_cd] then
                -- Попробуем найти имя с правильным регистром из лавок
                local _found_nm = nil
                for _snm, _ in pairs(fh_other_shops) do break end  -- заглушка
                _arb_extra[_nm_cd] = true
            end
        end
    end
    -- Объединяем: fh_mkt_prices + cloud-only товары
    local _arb_names = {}
    for nm in pairs(fh_mkt_prices) do _arb_names[nm] = fh_mkt_prices[nm] end
    if _G._mh_deals_cache then
        for _nm_cd, _cd_hist in pairs(_G._mh_deals_cache) do
            if not _arb_names[_nm_cd] then
                -- Найти точное имя с нужным регистром из shops или использовать как есть
                local _real_nm = _nm_cd
                for _, _sh in pairs(fh_other_shops) do
                    if type(_sh)=='table' then
                        for _, _si in ipairs(_sh.sell_items or {}) do
                            if type(_si.name)=='string' and _si.name:lower()==_nm_cd then
                                _real_nm = _si.name; break
                            end
                        end
                    end
                end
                _arb_names[_real_nm] = _arb_names[_real_nm] or {}
            end
        end
    end
    -- Конвертируем pairs в список для чанкового обхода
    local _arb_list = {}
    for nm, e in pairs(_arb_names) do
        if type(nm) == 'string' and type(e) == 'table' then
            table.insert(_arb_list, {nm=nm, e=e})
        end
    end
    if yield_fn then yield_fn() end  -- yield после тяжёлого построения индексов
    -- Обрабатываем чанками по 80 товаров
    local CHUNK = 80
    local _vkp_aborted = false
    for ci = 1, #_arb_list do
        if _vkp_aborted then break end
        local _item = _arb_list[ci]
        local nm = _item.nm
        local e  = _item.e
        local mkt_price = nil
        local nm_lo = nm:lower()
        local hist = e.cp_hist
        do
            -- Используем _mh_get_mkt_price — ту же функцию что в карточке товара
            local _mp = _mh_get_mkt_price(nm)
            if _mp then
                -- today = текущие лавки + данные за сегодня (как строка "День" в карточке)
                -- avg7 используем только как fallback когда today пустой
                mkt_price = (_mp.today and _mp.today > 0) and _mp.today
                         or (_mp.avg7  and _mp.avg7  > 0) and _mp.avg7
                         or nil
            end
            if not mkt_price or mkt_price <= 0 then
                if e.cp_sp and e.cp_sp > 0 then mkt_price = e.cp_sp end
            end
        end
        if mkt_price and mkt_price > 0 then
            do
                local ss = shops_sell_map[nm_lo]
                local as = api_sell[nm_lo]
                local shop_price, shop_owner, shop_qty, shop_uid
                if ss then shop_price=ss.price; shop_owner=ss.owner; shop_qty=ss.qty; shop_uid=ss.uid end
                if as and (not shop_price or as.price < shop_price) then
                    shop_price=as.price; shop_owner=as.owner; shop_qty=nil; shop_uid=as.uid
                end
                if shop_price then
                    local margin = mkt_price - shop_price
                    local ok = margin > 0
                        and (not min_price or min_price == 0 or shop_price >= min_price)
                        and (not trend_up_only or _inline_trend_up(hist))
                    if ok then
                        table.insert(result, {
                            nm=nm, mkt=mkt_price, shop=shop_price,
                            margin=margin, margin_pct=shop_price>0 and margin/shop_price*100 or 0,
                            owner=shop_owner or '?', shop_qty=shop_qty, uid=shop_uid, dir='buy'
                        })
                    end
                end
            end
            do
                local sb = shops_buy_map[nm_lo]
                local ab = api_buy[nm_lo]
                local buy_price, buy_owner, buy_qty, buy_uid
                if sb then buy_price=sb.price; buy_owner=sb.owner; buy_qty=sb.qty; buy_uid=sb.uid end
                if ab and (not buy_price or ab.price > buy_price) then
                    buy_price=ab.price; buy_owner=ab.owner; buy_qty=nil; buy_uid=ab.uid
                end
                if buy_price then
                    local margin = buy_price - mkt_price
                    local ok = margin > 0
                        and (not min_price or min_price == 0 or mkt_price >= min_price)
                    if ok then
                        table.insert(result, {
                            nm=nm, mkt=mkt_price, shop=buy_price,
                            margin=margin, margin_pct=mkt_price>0 and margin/mkt_price*100 or 0,
                            owner=buy_owner or '?', shop_qty=buy_qty, uid=buy_uid, dir='sell'
                        })
                    end
                end
            end
        end
        -- Yield каждые CHUNK товаров чтобы не фризить рендер
        if yield_fn and ci % CHUNK == 0 then
            if yield_fn() == false then _vkp_aborted = true end
        end
    end

    -- combined_sell: только из API
    local combined_sell = {}
    for k, v in pairs(api_sell) do
        combined_sell[k] = {price=v.price, owner=v.owner, qty=nil, name=v.name, uid=v.uid}
    end
    -- combined_buy: только из API, фёд лавки не участвуют
    local combined_buy = {}
    for k, v in pairs(api_buy) do
        combined_buy[k] = {price=v.price, owner=v.owner, qty=nil, name=v.name, uid=v.uid}
    end
    for k, sell_e in pairs(combined_sell) do
        local buy_e = combined_buy[k]
        if buy_e and sell_e.owner ~= buy_e.owner and sell_e.price < buy_e.price then
            local margin = buy_e.price - sell_e.price
            local ok = margin > 0
                and (not min_price or min_price == 0 or sell_e.price >= min_price)
            if ok then
                table.insert(result, {
                    nm=sell_e.name, mkt=buy_e.price, shop=sell_e.price,
                    margin=margin, margin_pct=sell_e.price>0 and margin/sell_e.price*100 or 0,
                    owner=sell_e.owner, owner2=buy_e.owner,
                    uid=sell_e.uid, uid2=buy_e.uid,
                    shop_qty=sell_e.qty, dir='shop2shop'
                })
            end
        end
    end

    table.sort(result, function(a,b) return a.margin > b.margin end)
    return result
end

local function _tcv8f()
    if not settings.presets then settings.presets = {} end
    if not settings.presets[fh_active_preset_idx] then
        settings.presets[fh_active_preset_idx] = {name="Пресет "..fh_active_preset_idx, items={}}
    end
    settings.presets[fh_active_preset_idx].items = fh_lv_autosell_preset
    settings.active_preset = fh_active_preset_idx
    _wfn7p()
end
settings = _qvx4m()
if not settings.general then settings.general = {} end
if not settings.premium then settings.premium = {} end
if settings.premium.key == nil then settings.premium.key = '' end
if settings.premium.activated == true and settings.premium.key ~= '' then
    -- Восстанавливаем состояние: если tok совпадает — сразу активны
    local _boot_tok = settings.premium.tok or ''
    local _boot_exp = _rxf2z(settings.premium.key, settings.premium.nick or '')
    if _boot_tok ~= '' and _boot_tok == _boot_exp then
        _qtp7v = true
    end
    lua_thread.create(_lkg8m)  -- фоновое обновление сессии
end
if settings.premium.activated == nil then settings.premium.activated = false end
if settings.premium.activated == true and (settings.premium.tok == nil or settings.premium.tok == '') then
    settings.premium.activated = false
    _wfn7p()
end
if settings.premium.expires == nil then settings.premium.expires = '' end
if not settings.item_tags then settings.item_tags = {} end
if not settings.market_filters then settings.market_filters = {} end
if settings.market_filters.min_price == nil then settings.market_filters.min_price = 0 end
if settings.market_filters.trend_up_only == nil then settings.market_filters.trend_up_only = false end
if not settings.interface then settings.interface = {} end
if not settings.piar_templates then
    settings.piar_templates = {
        { name = 'Пиар /vr', enable = true, auto = false, auto_interval = 600, auto_interval_max = 0, waiting = 1.5, last_time = 0, lines = {
            '/vr Хочешь в орг? Пиши в /pm!',
        }},
        { name = 'Пиар /s', enable = true, auto = false, auto_interval = 300, auto_interval_max = 0, waiting = 1.5, last_time = 0, lines = {
            '/s Приглашаем всех активных игроков!',
        }},
    }
end
for _, t in ipairs(settings.piar_templates or {}) do
    t.name=t.name or''; t.lines=t.lines or{}; t.waiting=t.waiting or 1.5
    t.auto_interval=t.auto_interval or 300; t.last_time=t.last_time or 0
    if t.enable==nil then t.enable=true end
    if t.auto==nil then t.auto=false end
end
if settings.general.auto_vr_confirm == nil then settings.general.auto_vr_confirm = true end
if settings.general.auto_ad_confirm == nil then settings.general.auto_ad_confirm = false end
if settings.general.auto_storage_collect == nil then settings.general.auto_storage_collect = false end
if settings.general.auto_ad_station_idx == nil then settings.general.auto_ad_station_idx = 2 end
if settings.general.auto_ad_type == nil then settings.general.auto_ad_type = 0 end
if settings.general.autostart_enabled ~= nil then fh_lv_autostart_enabled = settings.general.autostart_enabled end
if not settings.overlay then settings.overlay = {} end
if settings.overlay.enabled == nil then settings.overlay.enabled = false end
if not settings.overlay.pos_x  then settings.overlay.pos_x  = 10  end
if not settings.overlay.pos_y  then settings.overlay.pos_y  = 200 end
if not settings.overlay.width  then settings.overlay.width  = 420 end
if not settings.overlay.height then settings.overlay.height = 180 end
if not settings.overlay.alpha  then settings.overlay.alpha  = 0.6 end
if not settings.overlay.lines  then settings.overlay.lines  = 8   end
if not settings.overlay.sell_r then settings.overlay.sell_r = 0.3 end
if not settings.overlay.sell_g then settings.overlay.sell_g = 0.9 end
if not settings.overlay.sell_b then settings.overlay.sell_b = 0.3 end
if not settings.overlay.buy_r  then settings.overlay.buy_r  = 0.3 end
if not settings.overlay.buy_g  then settings.overlay.buy_g  = 0.6 end
if not settings.overlay.buy_b  then settings.overlay.buy_b  = 1.0 end
if not settings.overlay.log_price_r then settings.overlay.log_price_r = 1.0 end
if not settings.overlay.log_price_g then settings.overlay.log_price_g = 0.85 end
if not settings.overlay.log_price_b then settings.overlay.log_price_b = 0.2 end
if not settings.overlay then settings.overlay = {} end
if settings.overlay.enabled == nil then settings.overlay.enabled = false end
if not settings.overlay.pos_x   then settings.overlay.pos_x   = 10 end
if not settings.overlay.pos_y   then settings.overlay.pos_y   = 200 end
if not settings.overlay.width   then settings.overlay.width   = 420 end
if not settings.overlay.height  then settings.overlay.height  = 180 end
if not settings.overlay.alpha   then settings.overlay.alpha   = 0.6 end
if not settings.overlay.lines   then settings.overlay.lines   = 8 end
if not settings.overlay.sell_r  then settings.overlay.sell_r  = 0.3 end
if not settings.overlay.sell_g  then settings.overlay.sell_g  = 0.9 end
if not settings.overlay.sell_b  then settings.overlay.sell_b  = 0.3 end
if not settings.overlay.buy_r   then settings.overlay.buy_r   = 0.3 end
if not settings.overlay.buy_g   then settings.overlay.buy_g   = 0.6 end
if not settings.overlay.buy_b   then settings.overlay.buy_b   = 1.0 end
if not settings.interface.accent_r then settings.interface.accent_r = 1.0 end
if not settings.interface.accent_g then settings.interface.accent_g = 0.65 end
if not settings.interface.accent_b then settings.interface.accent_b = 0.0 end
if not settings.interface.sell_btn_r then settings.interface.sell_btn_r = 0.10 end
if not settings.interface.sell_btn_g then settings.interface.sell_btn_g = 0.45 end
if not settings.interface.sell_btn_b then settings.interface.sell_btn_b = 0.10 end
if not settings.interface.buy_btn_r  then settings.interface.buy_btn_r  = 0.00 end
if not settings.interface.buy_btn_g  then settings.interface.buy_btn_g  = 0.28 end
if not settings.interface.buy_btn_b  then settings.interface.buy_btn_b  = 0.50 end

if not settings.general.autofind_dpi then
    settings.general.custom_dpi = 1.50
    settings.general.autofind_dpi = true; _wfn7p()
end

imgui = require('mimgui')
local sizeX, sizeY = getScreenResolution()
local MainWindow = imgui.new.bool()
local sl = {
    dpi          = imgui.new.float(tonumber(settings.general.custom_dpi) or 1),
    window_alpha = imgui.new.float(settings.interface.window_alpha or 0.97),
    bg_bright    = imgui.new.float(settings.interface.bg_brightness or 0.13),
}
local accent_color = imgui.new.float[3](
    settings.interface.accent_r or 1.0,
    settings.interface.accent_g or 0.65,
    settings.interface.accent_b or 0.0
)

local function _ltz8m()
    if not _cvh6z() then imgui.SetWindowFontScale(settings.general.custom_dpi) end
end

function imgui.CenterColumnSmallButton(t)
    local d=(t or''):match('(.+)##') or t or''; imgui.SetCursorPosX((imgui.GetColumnOffset()+(imgui.GetColumnWidth()/2))-imgui.CalcTextSize(d).x/2); return imgui.SmallButton(t or'')
end
function imgui.GetMiddleButtonX(c)
    local w=imgui.GetWindowContentRegionWidth(); local s=imgui.GetStyle().ItemSpacing.x; return c==1 and w or w/c-((s*(c-1))/c)
end

function _fwb3h()
    imgui.SwitchContext()
    local s=imgui.GetStyle(); local d=settings.general.custom_dpi
    local bg=settings.interface.bg_brightness or 0.06
    local wa=settings.interface.window_alpha or 0.98
    local ar=settings.interface.accent_r or 1; local ag=settings.interface.accent_g or .55; local ab=settings.interface.accent_b or 0
    local sb_r=settings.interface.sell_btn_r or 0.10; local sb_g=settings.interface.sell_btn_g or 0.45; local sb_b=settings.interface.sell_btn_b or 0.10
    local bb_r=settings.interface.buy_btn_r or 0.00;  local bb_g=settings.interface.buy_btn_g or 0.28; local bb_b=settings.interface.buy_btn_b or 0.50
    s.WindowPadding=imgui.ImVec2(8*d,8*d); s.FramePadding=imgui.ImVec2(6*d,5*d)
    s.ItemSpacing=imgui.ImVec2(6*d,5*d); s.ItemInnerSpacing=imgui.ImVec2(3*d,3*d)
    s.ScrollbarSize=12*d; s.GrabMinSize=12*d
    s.WindowBorderSize=2*d; s.ChildBorderSize=1*d; s.PopupBorderSize=1*d; s.FrameBorderSize=0*d; s.TabBorderSize=0*d
    s.WindowRounding=4*d; s.ChildRounding=4*d; s.FrameRounding=4*d; s.PopupRounding=4*d
    s.ScrollbarRounding=3*d; s.GrabRounding=3*d; s.TabRounding=4*d
    s.WindowTitleAlign=imgui.ImVec2(.5,.5); s.ButtonTextAlign=imgui.ImVec2(.5,.5); s.SelectableTextAlign=imgui.ImVec2(.5,.5)
    local tr=settings.interface.text_r or .93; local tg=settings.interface.text_g or .88; local tb_=settings.interface.text_b or .78
    local bgr=settings.interface.bg_r or bg; local bgg=settings.interface.bg_g or (bg*0.95); local bgb_=settings.interface.bg_b or (bg*0.80)
    local brr=settings.interface.border_r or (ar*.70); local brg=settings.interface.border_g or (ag*.70); local brb=settings.interface.border_b or (ab*.70)
    local rnd=settings.interface.rounding or 4; local bsz=settings.interface.border_size or 1
    s.WindowRounding=rnd*d; s.ChildRounding=rnd*d; s.FrameRounding=rnd*d; s.PopupRounding=rnd*d; s.TabRounding=rnd*d
    s.WindowBorderSize=bsz*d; s.ChildBorderSize=bsz*d
    s.Colors[imgui.Col.Text]               =imgui.ImVec4(tr,tg,tb_,1)
    s.Colors[imgui.Col.TextDisabled]       =imgui.ImVec4(tr*.45,tg*.45,tb_*.45,1)
    s.Colors[imgui.Col.WindowBg]           =imgui.ImVec4(bgr,bgg,bgb_,wa)
    s.Colors[imgui.Col.ChildBg]            =imgui.ImVec4(bgr+.03,bgg+.028,bgb_+.015,wa)
    s.Colors[imgui.Col.PopupBg]            =imgui.ImVec4(bgr+.02,bgg+.018,bgb_+.01,wa)
    s.Colors[imgui.Col.Border]             =imgui.ImVec4(brr,brg,brb,.90)
    s.Colors[imgui.Col.BorderShadow]       =imgui.ImVec4(0,0,0,0)
    s.Colors[imgui.Col.FrameBg]            =imgui.ImVec4(bg+.06,bg+.055,bg+.03,1)
    s.Colors[imgui.Col.FrameBgHovered]     =imgui.ImVec4(bg+.10,bg+.09,bg+.05,1)
    s.Colors[imgui.Col.FrameBgActive]      =imgui.ImVec4(bg+.14,bg+.12,bg+.07,1)
    s.Colors[imgui.Col.TitleBg]            =imgui.ImVec4(bg*.8,bg*.8,bg*.8,1)
    s.Colors[imgui.Col.TitleBgActive]      =imgui.ImVec4(ar*.18,ag*.18,ab*.18,1)
    s.Colors[imgui.Col.TitleBgCollapsed]   =imgui.ImVec4(bg*.7,bg*.7,bg*.7,1)
    s.Colors[imgui.Col.MenuBarBg]          =imgui.ImVec4(bg+.04,bg+.035,bg+.02,1)
    s.Colors[imgui.Col.ScrollbarBg]        =imgui.ImVec4(bg+.01,bg+.01,bg+.005,1)
    s.Colors[imgui.Col.ScrollbarGrab]      =imgui.ImVec4(ar*.30, ag*.30, ab*.30, 1)
    s.Colors[imgui.Col.ScrollbarGrabHovered]=imgui.ImVec4(ar*.50, ag*.50, ab*.50, 1)
    s.Colors[imgui.Col.ScrollbarGrabActive]=imgui.ImVec4(ar*.70, ag*.70, ab*.70, 1)
    s.Colors[imgui.Col.CheckMark]          =imgui.ImVec4(ar, ag, ab, 1)
    s.Colors[imgui.Col.SliderGrab]         =imgui.ImVec4(ar*.5, ag*.5, ab*.5, 1)
    s.Colors[imgui.Col.SliderGrabActive]   =imgui.ImVec4(ar*.75, ag*.75, ab*.75, 1)
    s.Colors[imgui.Col.Button]             =imgui.ImVec4(bg+.08,bg+.07,bg+.04,1)
    s.Colors[imgui.Col.ButtonHovered]      =imgui.ImVec4(ar*.30, ag*.30, ab*.30, 1)
    s.Colors[imgui.Col.ButtonActive]       =imgui.ImVec4(ar*.50, ag*.50, ab*.50, 1)
    s.Colors[imgui.Col.Header]             =imgui.ImVec4(ar*.20, ag*.20, ab*.20, 1)
    s.Colors[imgui.Col.HeaderHovered]      =imgui.ImVec4(ar*.35, ag*.35, ab*.35, 1)
    s.Colors[imgui.Col.HeaderActive]       =imgui.ImVec4(ar*.50, ag*.50, ab*.50, 1)
    s.Colors[imgui.Col.Separator]          =imgui.ImVec4(ar*.25, ag*.25, ab*.25, .60)
    s.Colors[imgui.Col.Tab]                =imgui.ImVec4(bg+.04,bg+.035,bg+.02,1)
    s.Colors[imgui.Col.TabHovered]         =imgui.ImVec4(ar*.40, ag*.40, ab*.40, 1)
    s.Colors[imgui.Col.TabActive]          =imgui.ImVec4(ar*.30, ag*.30, ab*.30, 1)
    s.Colors[imgui.Col.ModalWindowDimBg]   =imgui.ImVec4(.04,.04,.04,.90)
end

imgui.OnInitialize(function() imgui.GetIO().IniFilename = nil; _fwb3h(); fa.Init(16.0) end)

local message_color = 0xFFAA00
local message_color_hex = "{FFAA00}"
local fh_last_dlg_title     = ""   -- clean title (без цветовых кодов)
local fh_last_dlg_title_raw = ""   -- raw title
local fh_last_dlg_text      = ""   -- raw text
local fh_last_dlg_id        = -1   -- dialog ID
fh_other_dlg_signal         = nil  -- {id,title,text} от onShowDialog для авто-скана

if not sampGetDialogTitle then
    function sampGetDialogTitle() return fh_last_dlg_title_raw end
end
if not sampGetDialogText then
    function sampGetDialogText() return fh_last_dlg_text end
end

fh_mkt_prices     = {}
fh_mkt_lavka      = {}
fh_mkt_log        = {}
fh_mkt_lavka_log  = {}
fh_mkt_last_update = nil
fh_mkt_lavka_ids  = {}
fh_mkt_lavka_sep  = {}
fh_mkt_lavka_page_id = -1
fh_mkt_cp_scanning  = false
fh_mkt_cp_page      = 0
fh_mkt_cp_prev_text = nil
fh_mkt_cp_go_idx    = nil
fh_mkt_lv_scanning  = false
fh_mkt_lv_done      = 0
fh_mkt_lv_total     = 0
fh_mkt_lv_cur_dialog = 3082
fh_lv_autosell_running = false
fh_lv_autostart_enabled = false  -- тумблер автозапуска
fh_lv_autosell_done    = 0
fh_lv_autobuy_running  = false
fh_ab_search_idx       = 0   -- текущий индекс товара в цикле авто-скупки
fh_lv_autosell_status  = ''
fh_lv_autobuy_status   = ''
fh_lv_trade_log        = {}
local _mh_chat_persist_path = getWorkingDirectory():gsub("\\\\","/") .. "/MarketHelper_chat.json"
local function _lvn7s()
    local ok, j = pcall(encodeJson, fh_session_chat)
    if ok then local f = io.open(_mh_chat_persist_path,"w"); if f then f:write(j); f:close() end end
end
local function _gzp1k()
    local f = io.open(_mh_chat_persist_path,"r")
    if f then
        local ok, d = pcall(decodeJson, f:read("*a")); f:close()
        if ok and type(d) == "table" then return d end
    end
    return {}
end
fh_session_chat        = _gzp1k()  -- chat buffer current session (persistent)
fh_session_start_dt    = os.date('%d.%m %H:%M')  -- метка старта сессии
fh_session_log_start   = nil  -- индекс старта сессии в fh_mkt_log
fh_overlay_log         = {}  -- строки для плавающего оверлея
fh_lv_autosell_preset  = {}
fh_active_preset_idx   = 1
if not settings.presets or type(settings.presets) ~= "table" or #settings.presets == 0 then
    local old = settings.autosell_preset
    settings.presets = {{name="Пресет 1", items=(old and type(old)=="table") and old or {}}}
    settings.active_preset = 1
    _wfn7p()
end
if not settings.active_preset then settings.active_preset = 1 end
fh_active_preset_idx = settings.active_preset
local _ap = settings.presets[fh_active_preset_idx]
fh_lv_autosell_preset = (_ap and _ap.items) or {}
fh_lv_autobuy_preset   = {}
fh_ab_preset_idx       = 1
if settings and settings.autobuy_preset and type(settings.autobuy_preset) == "table" then
    fh_lv_autobuy_preset = settings.autobuy_preset
end
fh_lv_sell_confirmed   = false   -- "успешно выставлен на продажу"
fh_lv_sell_forbidden   = false   -- "запрещено продавать"
fh_lv_sell_no_slots    = false   -- "нет доступных ячеек"
fh_mkt_lavka_all_tds   = {}      -- {id -> data} все TD пока лавка открыта
fh_mkt_lavka_slot_w    = nil     -- lineWidth эталонного слота
fh_mkt_lavka_slot_h    = nil     -- lineHeight эталонного слота
fh_mkt_lavka_page_ready = false  -- страница переключилась (LD_BEAT:chit)
fh_mkt_shop_dlg_id     = -1      -- ID меню лавки (3040)
fh_mkt_shop_inv_tds    = {}      -- TD инвентаря (правая часть), по порядку
fh_mkt_shop_ui_open    = false   -- UI лавки открыт
fh_mkt_shop_price_dlg  = -1      -- диалог ввода цены (26545 или другой)
fh_mkt_shop_price_item = ''      -- название товара из диалога цены
fh_mkt_put_td_id       = -1      -- TD с text=="PUT" (кнопка открытия UI лавки)
fh_mkt_shop_price_qty  = true    -- true = формат "кол-во,цена", false = только цена
fh_lv_autobuy_preset   = {}     -- [{name, qty, max_price}]
fh_lv_inventory        = {}     -- инвентарь лавки из диалога 25494
fh_lv_inv_scanning     = false
fh_lv_allitems_srch    = ''
fh_mkt_cp_deep_scanning  = false   -- новый глубокий скан
fh_mkt_cp_deep_page_idx  = 0      -- индекс товара на текущей странице
fh_mkt_cp_deep_cur_page_items = {}
fh_mkt_cp_deep_items    = {}      -- список товаров из списка
fh_mkt_cp_deep_idx      = 0       -- текущий индекс
fh_mkt_cp_deep_total    = 0       -- всего товаров
fh_mkt_cp_deep_done     = 0       -- обработано
fh_mkt_cp_deep_dlg_id   = nil     -- ID диалога списка
fh_mkt_cp_deep_state    = 'idle'  -- idle | list | item_detail
fh_mkt_cp_deep_item_dlg = nil     -- ID диалога деталей
fh_mkt_lavka_slot_w  = nil
fh_mkt_lavka_slot_h  = nil
local function _bmj2p(e, price, qty, side)
    qty = qty or 1
    if side == 'buy' then
        e.b_totalP=(e.b_totalP or 0)+price*qty; e.b_totalC=(e.b_totalC or 0)+qty
        e.b_avg=math.floor(e.b_totalP/e.b_totalC)
        e.b_min=e.b_min and math.min(e.b_min,price) or price
        e.b_max=e.b_max and math.max(e.b_max,price) or price
        e.b_last=price; e.b_scans=(e.b_scans or 0)+1
    else
        e.s_totalP=(e.s_totalP or 0)+price*qty; e.s_totalC=(e.s_totalC or 0)+qty
        e.s_avg=math.floor(e.s_totalP/e.s_totalC)
        e.s_min=e.s_min and math.min(e.s_min,price) or price
        e.s_max=e.s_max and math.max(e.s_max,price) or price
        e.s_last=price; e.s_scans=(e.s_scans or 0)+1
    end
    e.date=os.date("%d.%m.%Y %H:%M"); return e
end
fh_other_shops = {}
if settings and settings.other_shops and type(settings.other_shops) == 'table' then
    fh_other_shops = settings.other_shops
    -- Clean dirty owner names: "Торговая лавка - Nick" -> "Nick"
    -- Use explicit [A-Za-z] NOT %a: on Android Russian locale, %a matches Cyrillic!
    for k, sh in pairs(fh_other_shops) do
        if sh.owner then
            local clean = sh.owner:match('%-%s*([A-Za-z_][A-Za-z0-9_]+)')
                       or sh.owner:match('^([A-Za-z_][A-Za-z0-9_]+)')
            if clean and clean ~= sh.owner then sh.owner = clean end
        end
    end
    for _, sh in pairs(fh_other_shops) do
        for _, it in ipairs(sh.sell_items or {}) do
            if it.name and it.name ~= '' and it.price and it.price > 0 then
                fh_mkt_lavka[it.name] = _bmj2p(fh_mkt_lavka[it.name] or {}, it.price, it.qty or 1, 'sell')
            end
        end
        for _, it in ipairs(sh.buy_items or {}) do
            if it.name and it.name ~= '' and it.price and it.price > 0 then
                fh_mkt_lavka[it.name] = _bmj2p(fh_mkt_lavka[it.name] or {}, it.price, it.qty or 1, 'buy')
            end
        end
    end
end
fh_other_shop_cur = nil    -- текущий парсинг (не сохранённый)
fh_other_shop_scanning = false  -- идёт автоскан
fh_player_dlg_open     = false  -- реальный диалог дошёл до игрока (не скрыт сканом)
fh_other_scan_done     = 0      -- сколько слотов обработано
fh_other_scan_total    = 0      -- всего слотов в текущем скане
fh_other_shop_owner = ''   -- имя владельца из сообщения чата
fh_other_shop_price_tds = {}   -- {td_id -> {price,x,y}} ценовые TD чужой лавки
fh_other_shop_pending_num = nil -- номер лавки (из TD / чата / счётчика)
mh_own_shop_num        = nil -- номер ????? ????? (?????? ?? ??????? 3040)
mh_pending_lavka_buf    = {}   -- Буфер слотов 60/sub=0 до прихода 60/sub=1

cm_radius_enabled    = false   -- показывать радиусы лавок
cm_catch_enabled     = false   -- авто-ловля (диалог 3010)
cm_render_enabled    = false   -- рендер линий к свободным лавкам
cm_catch_status      = ''      -- статус последнего события

fh_mkt_auto                = {}
fh_mkt_auto_last_upd       = nil
fh_mkt_auto_scanning       = false
fh_mkt_auto_page           = 0
fh_mkt_auto_prev_text      = nil
fh_mkt_auto_go_idx         = nil
fh_mkt_auto_deep_scanning  = false
fh_mkt_auto_deep_go_idx    = nil
fh_mkt_auto_deep_done      = 0

fh_storage_running = false
fh_storage_idx     = 0

local function _zdb1r(file)
    return getWorkingDirectory():gsub('\\\\','/') .. '/FH_' .. file
end

local function _ryb5t()
    for _,p in ipairs({
        {'mkt_prices.json',    fh_mkt_prices},
        {'mkt_log.json',       fh_mkt_log},
        {'mkt_lavka.json',     fh_mkt_lavka},
        {'mkt_lavka_log.json', fh_mkt_lavka_log},
        {'mkt_auto.json',      fh_mkt_auto},
    }) do
        local ok,j = pcall(encodeJson, p[2])
        if ok then local f=io.open(_zdb1r(p[1]),'w'); if f then f:write(j); f:close() end end
    end
    if fh_mkt_last_update then
        local f=io.open(_zdb1r('mkt_last_update.txt'),'w')
        if f then f:write(fh_mkt_last_update); f:close() end
    end
end

local function _lkz7q()
    for _,p in ipairs({
        {'mkt_prices.json',    'fh_mkt_prices'},
        {'mkt_log.json',       'fh_mkt_log'},
        {'mkt_lavka.json',     'fh_mkt_lavka'},
        {'mkt_lavka_log.json', 'fh_mkt_lavka_log'},
        {'mkt_auto.json',      'fh_mkt_auto'},
    }) do
        local f=io.open(_zdb1r(p[1]),'r')
        if f then local ok,d=pcall(decodeJson,f:read('*a')); f:close()
            if ok and type(d)=='table' then _G[p[2]]=d end end
    end
    local fu=io.open(_zdb1r('mkt_last_update.txt'),'r')
    if fu then fh_mkt_last_update=fu:read('*a'); fu:close() end
    local clean_auto = {}
    for k,v in pairs(fh_mkt_auto) do
        if type(k) == 'string' and type(v) == 'table' then
            local ck = k:gsub('##%a%d+$','')
            if ck ~= '' then
                if clean_auto[ck] then
                    local ex = clean_auto[ck]
                    ex.s_avg = v.s_avg or ex.s_avg
                    ex.s_min = (ex.s_min and v.s_min) and math.min(ex.s_min,v.s_min) or ex.s_min or v.s_min
                    ex.s_max = (ex.s_max and v.s_max) and math.max(ex.s_max,v.s_max) or ex.s_max or v.s_max
                    ex.date = ex.date or v.date
                else clean_auto[ck] = v end
            end
        end
    end
    fh_mkt_auto = clean_auto
    _mh_db_bump()  -- данные загружены — уведомляем кэши
end

local function _gfr3j(date_str)
    return getWorkingDirectory():gsub('\\\\','/') .. '/FH_daily_prices/' .. date_str .. '.json'
end

local function _nvw9k()
    local lfs = require('lfs')
    local dir = getWorkingDirectory():gsub('\\\\','/') .. '/FH_daily_prices'
    if not lfs.attributes(dir) then lfs.mkdir(dir) end
end

local function _kyb5x()
    _nvw9k()
    local today = os.date('%Y-%m-%d')
    local path = _gfr3j(today)

    local existing = {}
    local f = io.open(path, 'r')
    if f then
        local ok, d = pcall(decodeJson, f:read('*a')); f:close()
        if ok and type(d) == 'table' then existing = d end
    end

    for name, e in pairs(fh_mkt_lavka) do
        if not existing[name] then existing[name] = {} end
        local rec = existing[name]
        if e.s_totalP and e.s_totalC and e.s_totalC > 0 then
            rec.s_totalP = (rec.s_totalP or 0) + e.s_totalP
            rec.s_totalC = (rec.s_totalC or 0) + e.s_totalC
        end
        if e.b_totalP and e.b_totalC and e.b_totalC > 0 then
            rec.b_totalP = (rec.b_totalP or 0) + e.b_totalP
            rec.b_totalC = (rec.b_totalC or 0) + e.b_totalC
            if e.b_max then rec.b_max = rec.b_max and math.max(rec.b_max, e.b_max) or e.b_max end
        end
    end
    local _save_srv_id = (ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1] or {}).id or -1
    local _sp_idx = {}
    local _bp_idx = {}
    for _, sh in pairs(fh_other_shops) do
        if type(sh) ~= 'table' then goto _save_sh_next end
        if _save_srv_id ~= -1 and sh.server_id and sh.server_id ~= -1 and sh.server_id ~= _save_srv_id then goto _save_sh_next end
        for _, si in ipairs(sh.sell_items or {}) do
            if si.name and si.name ~= '' and si.price and si.price > 0 then
                if not existing[si.name] then existing[si.name] = {} end
                local rec = existing[si.name]
                local q = si.qty or 1
                rec.s_totalP = (rec.s_totalP or 0) + si.price * q
                rec.s_totalC = (rec.s_totalC or 0) + q
                if sh.server_id then rec.server_id = sh.server_id end
                if not _sp_idx[si.name] then _sp_idx[si.name] = {} end
                local _seen = false
                for _, _pp in ipairs(_sp_idx[si.name]) do if _pp == si.price then _seen=true; break end end
                if not _seen and #_sp_idx[si.name] < 10 then table.insert(_sp_idx[si.name], si.price) end
            end
        end
        for _, bi in ipairs(sh.buy_items or {}) do
            if bi.name and bi.name ~= '' and bi.price and bi.price > 0 then
                if not existing[bi.name] then existing[bi.name] = {} end
                local rec = existing[bi.name]
                local q = bi.qty or 1
                rec.b_totalP = (rec.b_totalP or 0) + bi.price * q
                rec.b_totalC = (rec.b_totalC or 0) + q
                rec.b_max = rec.b_max and math.max(rec.b_max, bi.price) or bi.price
                if not _bp_idx[bi.name] then _bp_idx[bi.name] = {} end
                local _seen = false
                for _, _pp in ipairs(_bp_idx[bi.name]) do if _pp == bi.price then _seen=true; break end end
                if not _seen and #_bp_idx[bi.name] < 10 then table.insert(_bp_idx[bi.name], bi.price) end
            end
        end
        ::_save_sh_next::
    end
    for nm, prices in pairs(_sp_idx) do
        if existing[nm] then table.sort(prices); existing[nm].s_prices = prices end
    end
    for nm, prices in pairs(_bp_idx) do
        if existing[nm] then table.sort(prices, function(a,b) return a>b end); existing[nm].b_prices = prices end
    end

    local ok, j = pcall(encodeJson, existing)
    if ok then
        local fw = io.open(path, 'w')
        if fw then fw:write(j); fw:close() end
    end
end

-- Загрузка суточных цен лавок на сервер (раз в час + после скана)
_G._mh_daily_push_last = 0
local function _mh_upload_daily_prices()
    local now = os.time()
    if now - (_G._mh_daily_push_last or 0) < 3600 then return end
    local srv_id = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1))
        or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or 1] or {}).id or -1
    if srv_id == -1 then return end
    local today = os.date('%Y-%m-%d')
    local path = _gfr3j(today)
    local f = io.open(path, 'r')
    if not f then return end
    local ok, data = pcall(decodeJson, f:read('*a')); f:close()
    if not ok or type(data) ~= 'table' then return end
    local items = {}
    for nm, rec in pairs(data) do
        if type(nm) == 'string' and type(rec) == 'table' then
            local s_avg = (rec.s_totalC and rec.s_totalC > 0)
                and math.floor(rec.s_totalP / rec.s_totalC) or nil
            local b_avg = (rec.b_totalC and rec.b_totalC > 0)
                and math.floor(rec.b_totalP / rec.b_totalC) or nil
            if s_avg or b_avg then
                table.insert(items, {
                    name  = nm,
                    s_avg = s_avg or 0,
                    s_cnt = rec.s_totalC or 0,
                    b_avg = b_avg or 0,
                    b_cnt = rec.b_totalC or 0,
                    b_max = rec.b_max or 0,
                })
            end
        end
    end
    if #items == 0 then return end
    local ok_j, body = pcall(encodeJson, {server_id=srv_id, date=today, items=items})
    if not ok_j then return end
    _G._mh_daily_push_last = now
    _jmx9s(_vbr7n .. '/daily/push', body, function(code, text, err)
        if mh_debug_enabled then
            if code == 200 then
                sampAddChatMessage('[MH Cloud] {00cc88}Суточные: '..#items..' товаров', 0xFFFFFF)
            else
                sampAddChatMessage('[MH Cloud] {ff6666}Ошибка daily: '..(code or err or '?'), 0xFFFFFF)
            end
        end
    end)
end

-- Таймер: загружать суточные цены раз в час
lua_thread.create(function()
    wait(60000)
    while true do
        _mh_upload_daily_prices()
        wait(3600000)
    end
end)

-- Скачивание суточных цен лавок других игроков с сервера
_G._mh_daily_cache     = {}   -- [item_lower] -> [{date, s_avg, s_cnt, b_avg, b_cnt, contrib}]
_G._mh_daily_cache_srv = -1
_G._mh_daily_pull_last = 0
local _mh_daily_pulling = false

local function _mh_daily_pull(silent)
    if _mh_daily_pulling then return end
    local now = os.time()
    if now - (_G._mh_daily_pull_last or 0) < 1800 then return end  -- не чаще раза в 30 мин
    local sid = _mh_get_srv_id and _mh_get_srv_id() or -1
    if sid == -1 then return end
    _mh_daily_pulling = true
    _fwm2c(_vbr7n..'/daily/pull?server='..sid..'&days=30', function(code, body, _e)
        _mh_daily_pulling = false
        _G._mh_daily_pull_last = os.time()
        if not body or #body == 0 then return end
        local ok, resp = pcall(decodeJson, body)
        if not ok or type(resp) ~= 'table' or not resp.ok then return end
        local cache = {}
        for _, itm in ipairs(resp.items or {}) do
            local nm = itm.name or ''
            if nm ~= '' then
                cache[nm:lower()] = itm.history or {}
            end
        end
        _G._mh_daily_cache     = cache
        _G._mh_daily_cache_srv = sid
        _G._dtl_cache_nm = nil  -- сброс кэша карточки товара
        if not silent and mh_debug_enabled then
            sampAddChatMessage('[MH Cloud] {00cc88}Daily: '..tostring(#(resp.items or {}))..' товаров', 0xFFFFFF)
        end
    end)
end

-- Таймер: тянем суточные данные раз в 30 минут
lua_thread.create(function()
    wait(90000)  -- первый запрос через 90 сек после старта
    while true do
        _mh_daily_pull(true)
        wait(1800000)
    end
end)


_G._mh_deals_push_last = 0
_G._mh_deals_cache     = {}   -- [item_lower] = history_array
_G._mh_deals_cache_srv = -1

local _utf8 = function(s) if not s then return '' end; local ok,r=pcall(function() return require('encoding').UTF8:encode(tostring(s)) end); return ok and r or tostring(s) end

local function _mh_get_srv_id()
    return (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1))
        or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or 1] or {}).id or -1
end

-- src='log': push реальных сделок из deals_srvN.json
local function _mh_deals_collect_log(sid)
    local path = _zdb1r('deals_srv'..tostring(sid)..'.json')
    local f = io.open(path, 'r')
    if not f then return {} end
    local ok, deals = pcall(decodeJson, f:read('*a')); f:close()
    if not ok or type(deals) ~= 'table' then return {} end
    local cutoff = os.date('%Y-%m-%d', os.time() - 30*86400)
    local agg = {}
    for date, day_list in pairs(deals) do
        if type(date)=='string' and date>=cutoff and type(day_list)=='table' then
            for _, d in ipairs(day_list) do
                local nm = d.item or ''; local op = d.op or 'sell'
                if nm~='' and (d.price or 0)>0 then
                    local k = date..'|'..nm:lower()..'|'..op
                    agg[k] = agg[k] or {sum=0,qty=0,date=date,name=nm,op=op}
                    local q = d.qty or 1
                    agg[k].sum = agg[k].sum + d.price*q
                    agg[k].qty = agg[k].qty + q
                end
            end
        end
    end
    local items = {}
    for _, v in pairs(agg) do
        if v.qty>0 then
            table.insert(items,{date=v.date,name=_utf8(v.name),op=v.op,
                src='log',avg_price=math.floor(v.sum/v.qty),total_qty=v.qty})
        end
    end
    return items
end

-- src='deep': push данных углублённого скана ЦР (cp_hist)
local function _mh_deals_collect_deep()
    local items = {}
    local cutoff = os.date('%Y-%m-%d', os.time() - 30*86400)
    for nm, e in pairs(fh_mkt_prices) do
        if e and e.cp_hist then
            for _, h in ipairs(e.cp_hist) do
                local date = h.dt or ''
                if date>=cutoff and (h.price or 0)>0 then
                    table.insert(items,{date=date,name=_utf8(nm),op='sell',
                        src='deep',avg_price=h.price,total_qty=(h.qty or 1)})
                end
            end
        end
    end
    return items
end

local _mh_deals_pushing = false
local function _mh_upload_deals()
    local now = os.time()
    if now-(_G._mh_deals_push_last or 0)<3600 then return end
    if _mh_deals_pushing then return end
    local sid = _mh_get_srv_id()
    if sid==-1 then return end
    local all = {}
    for _,v in ipairs(_mh_deals_collect_log(sid))  do table.insert(all,v) end
    for _,v in ipairs(_mh_deals_collect_deep())    do table.insert(all,v) end
    if #all==0 then return end
    _G._mh_deals_push_last = now
    _mh_deals_pushing = true
    local ok_j, body = pcall(encodeJson,{server_id=sid,items=all})
    if not ok_j then _mh_deals_pushing=false; return end
    _jmx9s(_vbr7n..'/deals/push', body, function(code,_r,_e)
        _mh_deals_pushing = false
        if mh_debug_enabled and code==200 then
            sampAddChatMessage('[MH Cloud] {00cc88}Deals push: '..#all..' records', 0xFFFFFF)
        end
    end)
end

local _mh_deals_pulling = false
local function _mh_deals_pull(silent)
    if _mh_deals_pulling then return end
    local sid = _mh_get_srv_id()
    if sid==-1 then return end
    _mh_deals_pulling = true
    _fwm2c(_vbr7n..'/deals/pull?server='..sid..'&days=30', function(code, body, _e)
        _mh_deals_pulling = false
        if not body or #body==0 then return end
        local ok, resp = pcall(decodeJson, body)
        if not ok or type(resp)~='table' or not resp.ok then return end
        local cache = {}
        for _, itm in ipairs(resp.items or {}) do
            local nm = itm.name or ''
            if nm~='' then cache[nm:lower()] = itm.history or {} end
        end
        _G._mh_deals_cache     = cache
        _G._mh_deals_cache_srv = sid
        _G._dtl_cache_nm = nil  -- сброс кэша карточки
        lua_thread.create(function() wait(100); _mh_rebuild_shop_hist_cache() end)
        if not silent then
            sampAddChatMessage('[MH Cloud] {00cc88}Deals: '..tostring(#(resp.items or {}))..' items', 0xFFFFFF)
        end
    end)
end

lua_thread.create(function()
    wait(90000)
    _mh_deals_pull(true)
    _mh_upload_deals()
    while true do
        wait(3600000)
        _mh_deals_pull(true)
        _mh_upload_deals()
    end
end)


function _ztc7m(server_id)
    if not mh_arz_data or #mh_arz_data == 0 then return end
    if not mh_arz_items_db or not mh_arz_items_loaded then return end
    _nvw9k()
    local today = os.date('%Y-%m-%d')
    local path  = _gfr3j(today)
    -- ВАЖНО: каждый скан = свежий полный срез цен.
    -- НЕ читаем старые данные за сегодня чтобы не накапливать устаревшие цены.
    -- Если хочется усреднить несколько сканов в день — просто берём последний.
    local existing = {}
    -- Сохраняем фактические сделки (s_total_real) из старого файла отдельно
    local old_f = io.open(path, 'r')
    if old_f then
        local ok, d = pcall(decodeJson, old_f:read('*a')); old_f:close()
        if ok and type(d) == 'table' then
            -- Переносим только данные фактических сделок (из лога)
            for nm, e in pairs(d) do
                if type(nm) == 'string' and type(e) == 'table' and e._from_log then
                    existing[nm] = e
                end
            end
        end
    end
    -- Сканируем mh_arz_data — актуальные цены в лавках прямо сейчас
    local fresh = {}  -- свежий срез из текущего скана
    for _, lv in ipairs(mh_arz_data) do
        if type(lv) ~= 'table' then goto _api_daily_next end
        if server_id and server_id ~= -1 and lv.serverId ~= server_id then goto _api_daily_next end
        if lv.items_sell and lv.price_sell then
            for ii, iid in ipairs(lv.items_sell) do
                local bid = _bqs3v(iid)
                local nm  = mh_arz_items_db[bid]
                local pr  = lv.price_sell[ii]
                local q   = (lv.count_sell and lv.count_sell[ii]) or 1
                if nm and nm ~= '' and pr and pr > 0 then
                    if not fresh[nm] then fresh[nm] = {s_totalP=0,s_totalC=0,b_totalP=0,b_totalC=0} end
                    fresh[nm].s_totalP = fresh[nm].s_totalP + pr * q
                    fresh[nm].s_totalC = fresh[nm].s_totalC + q
                end
            end
        end
        if lv.items_buy and lv.price_buy then
            for ii, iid in ipairs(lv.items_buy) do
                local bid = _bqs3v(iid)
                local nm  = mh_arz_items_db[bid]
                local pr  = lv.price_buy[ii]
                local q   = (lv.count_buy and lv.count_buy[ii]) or 1
                if nm and nm ~= '' and pr and pr > 0 then
                    if not fresh[nm] then fresh[nm] = {s_totalP=0,s_totalC=0,b_totalP=0,b_totalC=0} end
                    fresh[nm].b_totalP = fresh[nm].b_totalP + pr * q
                    fresh[nm].b_totalC = fresh[nm].b_totalC + q
                end
            end
        end
        ::_api_daily_next::
    end
    -- Объединяем: свежий скан перезаписывает данные лавок за сегодня
    for nm, v in pairs(fresh) do
        if not existing[nm] then existing[nm] = {} end
        existing[nm].s_totalP = v.s_totalP
        existing[nm].s_totalC = v.s_totalC
        existing[nm].b_totalP = v.b_totalP
        existing[nm].b_totalC = v.b_totalC
        existing[nm]._scan_ts = os.time()  -- время скана
    end
    local ok2, j2 = pcall(encodeJson, existing)
    if ok2 then
        local fw = io.open(path, 'w')
        if fw then fw:write(j2); fw:close() end
    end
    _G._dtl_cache_nm = nil
    lua_thread.create(function() wait(200); _mh_rebuild_shop_hist_cache() end)
end

local function fh_get_daily_avg_price(item_name)
    local lfs = require('lfs')
    local dir = getWorkingDirectory():gsub('\\\\','/') .. '/FH_daily_prices'
    if not lfs.attributes(dir) then return nil end

    local total_p, total_c = 0, 0
    for fname in lfs.dir(dir) do
        if fname:match('^%d%d%d%d%-%d%d%-%d%d%.json$') then
            local f = io.open(dir .. '/' .. fname, 'r')
            if f then
                local ok, data = pcall(decodeJson, f:read('*a')); f:close()
                if ok and type(data) == 'table' and data[item_name] then
                    local e = data[item_name]
                    if e.s_totalP and e.s_totalC and e.s_totalC > 0 then
                        total_p = total_p + e.s_totalP
                        total_c = total_c + e.s_totalC
                    end
                end
            end
        end
    end

    if total_c > 0 then return math.floor(total_p / total_c) end
    return nil
end

-- Кеши для fh_get_daily_shop_history.
-- _dly_file_cache: разобранные JSON-файлы, инвалидируются по mtime файла.
-- _dly_item_cache: готовый ответ по item_name, инвалидируется по сигнатуре каталога.
-- _dly_dir_sig:    сводная сигнатура (fname:mtime|...) — пересчитывается раз в 30с.
local _dly_file_cache  = {}
local _dly_item_cache  = {}
local _dly_dir_sig     = nil
local _dly_dir_sig_ts  = 0
local function fh_get_daily_shop_history(item_name)
    if not item_name or item_name == '' then return {} end
    local lfs_ok, lfs = pcall(require, 'lfs')
    if not lfs_ok then return {} end
    local dir = getWorkingDirectory():gsub('\\\\','/') .. '/FH_daily_prices'
    if not lfs.attributes(dir) then return {} end
    -- 1) Обновляем сигнатуру каталога не чаще, чем раз в 30 секунд.
    local now = os.time()
    if not _dly_dir_sig or (now - _dly_dir_sig_ts) > 30 then
        local sig_parts = {}
        for fname in lfs.dir(dir) do
            if fname:match('^%d%d%d%d%-%d%d%-%d%d%.json$') then
                local attr = lfs.attributes(dir .. '/' .. fname)
                local mt = (attr and attr.modification) or 0
                table.insert(sig_parts, fname..':'..tostring(mt))
            end
        end
        table.sort(sig_parts)
        local new_sig = table.concat(sig_parts, '|')
        if new_sig ~= _dly_dir_sig then
            _dly_dir_sig    = new_sig
            _dly_item_cache = {}  -- каталог изменился — сбрасываем item-кеш
        end
        _dly_dir_sig_ts = now
    end
    -- 2) Если ответ по item_name уже посчитан под текущую сигнатуру — отдаём его.
    local hit = _dly_item_cache[item_name]
    if hit and hit.sig == _dly_dir_sig then return hit.days end
    -- 3) Считаем заново, переиспользуя разобранные JSON-файлы.
    local days = {}
    for fname in lfs.dir(dir) do
        local y,m,d2 = fname:match('^(%d%d%d%d)-(%d%d)-(%d%d)%.json$')
        if y then
            local path = dir .. '/' .. fname
            local attr = lfs.attributes(path)
            local mt = (attr and attr.modification) or 0
            local fc = _dly_file_cache[path]
            if not fc or fc.mtime ~= mt then
                local f = io.open(path, 'r')
                if f then
                    local raw = f:read('*a'); f:close()
                    local ok, dat = pcall(decodeJson, raw)
                    if ok and type(dat) == 'table' then
                        fc = {mtime=mt, data=dat}
                        _dly_file_cache[path] = fc
                    else
                        fc = nil
                    end
                end
            end
            if fc and fc.data and fc.data[item_name] then
                local e = fc.data[item_name]
                local s_avg = (e.s_totalC and e.s_totalC>0) and math.floor(e.s_totalP/e.s_totalC) or nil
                local b_avg = (e.b_totalC and e.b_totalC>0) and math.floor(e.b_totalP/e.b_totalC) or nil
                local b_max = e.b_max or nil
                local s_prices = e.s_prices or nil
                local b_prices = e.b_prices or nil
                if s_avg or b_avg then
                    table.insert(days, {date=y..'-'..m..'-'..d2, s_avg=s_avg, b_avg=b_avg, b_max=b_max,
                        s_prices=s_prices, b_prices=b_prices})
                end
            end
        end
    end
    table.sort(days, function(a,b) return a.date > b.date end)
    _dly_item_cache[item_name] = {sig=_dly_dir_sig, days=days}
    return days
end

local function _ngw1x(item, qty, price, op, partner, is_vc, own)
    if not item or not price or price<=0 then return end
    local dt=os.date("%d.%m %H:%M"); local dt_day=os.date("%Y-%m-%d"); qty=qty or 1
    local side=(op=='buy') and 'buy' or 'sell'
    local _cur_srv_id = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or 1] or {}).id or -1
    table.insert(fh_mkt_log,{dt=dt,item=item,qty=qty,price=price,op=op,own=own,partner=partner or "",vc=is_vc,srv=_cur_srv_id})
    while #fh_mkt_log>2000 do table.remove(fh_mkt_log,1) end
    fh_mkt_prices[item]=_bmj2p(fh_mkt_prices[item] or {},price,qty,side)
    fh_mkt_last_update=dt
    -- Сохраняем сделку в файл по серверу и дню
    if _cur_srv_id ~= -1 then
        local _srv_deals_path = _zdb1r('deals_srv'..tostring(_cur_srv_id)..'.json')
        local _srv_deals = {}
        local _fd = io.open(_srv_deals_path, 'r')
        if _fd then local _ok,_dd=pcall(decodeJson,_fd:read('*a')); _fd:close(); if _ok and type(_dd)=='table' then _srv_deals=_dd end end
        if not _srv_deals[dt_day] then _srv_deals[dt_day]={} end
        table.insert(_srv_deals[dt_day], {t=dt,item=item,qty=qty,price=price,op=op,partner=partner or ""})
        -- Храним только последние 30 дней
        local _days_sorted = {}
        for k in pairs(_srv_deals) do
            local _ks = tostring(k)
            -- пропускаем числовые и нестроковые ключи (мусор от JSON)
            if _ks:match('^%d%d%d%d%-%d%d%-%d%d$') then
                table.insert(_days_sorted, _ks)
            end
        end
        table.sort(_days_sorted)
        while #_days_sorted > 30 do
            local _old = _days_sorted[1]
            _srv_deals[_old] = nil
            table.remove(_days_sorted, 1)
        end
        local _ok2,_j2=pcall(encodeJson,_srv_deals)
        if _ok2 then local _fw=io.open(_srv_deals_path,'w'); if _fw then _fw:write(_j2); _fw:close() end end
    end
end

local function fh_find_listitem(text, needle)
    local iline = 0
    for ln in text:gmatch('[^\n]+') do
        iline = iline + 1
        if iline > 1 and ln:find(needle, 1, true) then
            return iline - 2
        end
    end
    return nil
end

local _parse_mkt_price  -- forward declaration (defined below)

local function _jfw5v(text, title_text)
    if not text or text == "" then return nil end
    local item_name = ""
    if title_text then
        local tn = title_text:gsub("{%x+}",""):match("^%s*(.-)%s*$") or ""
        local nm = tn:match("'(.+)'") or tn:match('"(.+)"')
        if nm and nm ~= "" then item_name = nm
        elseif not tn:find("Продажа") and not tn:find("последние") and tn ~= "" then item_name = tn
        end
    end
    if item_name == "" then return nil end
    local history = {}
    for line in text:gmatch("[^\n]+") do
        local clean = line:gsub("{%x%x%x%x%x%x}",""):match("^%s*(.-)%s*$") or ""
        if clean ~= "" then
            local dt_s, qty_s, price_s
            -- Формат: YYYY-MM-DD TAB QTY TAB price (поддерживает :КК: N :К: N.NNN и другие)
            dt_s, qty_s, price_s = clean:match("^(%d%d%d%d%-%d%d%-%d%d)%s*\t%s*(%d+)%s*\t%s*(.+)")
            if not dt_s then
                dt_s, qty_s, price_s = clean:match("^(%d%d%d%d%-%d%d%-%d%d)%s+(%d+)%s+(.+)")
            end
            if not dt_s then
                dt_s, qty_s, price_s = clean:match("^(%d%d%d%d%-%d%d%-%d%d)%s*|%s*(%d+)%s*|%s*(.+)")
            end
            if not dt_s then
                local p2; dt_s, p2 = clean:match("^(%d%d%d%d%-%d%d%-%d%d)%s*\t%s*(.+)")
                if dt_s then qty_s = "1"; price_s = p2 end
            end
            if dt_s and price_s then
                local price = _parse_mkt_price(price_s)
                local qty = tonumber(qty_s) or 1
                if price and price > 0 then
                    table.insert(history, {dt=dt_s, qty=qty, price=price})
                end
            end
        end
    end
    return { name = item_name, history = history }
end

-- Функция парсинга цены маркета (КК/К/М + число)
_parse_mkt_price = function(s)
    if not s or s == '' then return nil end
    local c = s:gsub('{%x%x%x%x%x%x}', ' '):match('^%s*(.-)%s*$') or ''
    if c == '' then return nil end
    c = c:gsub('[Kk][Kk]', 'КК')
    c = c:gsub('([^%a])([Kk])([^%a])', function(a,k,b) return a..'К'..b end)
    c = c:gsub('^([Kk])([^%a])', function(k,b) return 'К'..b end)
    c = c:gsub('([^%a])([Mm])([^%a])', function(a,m,b) return a..'М'..b end)
    c = c:gsub('^([Mm])([^%a])', function(m,b) return 'М'..b end)
    -- КК N [icon] N.NNN
    local kk_i,frac_i = c:match('КК%D*(%d+)%D+(%d[%d%.%,]*)')  -- %D+ = любой не-цифровой (иконки, пробелы)
    if kk_i and frac_i then
        return math.floor(tonumber(kk_i)*1e6)+(tonumber((frac_i:gsub('[.,]',''))) or 0)
    end
    -- М N [icon] N.NNN
    local m_i,frac_m = c:match('М%D*(%d+)%D+(%d[%d%.%,]*)')
    if m_i and frac_m then
        return math.floor(tonumber(m_i)*1e9)+(tonumber((frac_m:gsub('[.,]',''))) or 0)
    end
    local kk_s,k_s = c:match('КК%D*([%d%.%,]+)%D+К%D*([%d%.%,]+)')
    if kk_s and k_s then
        return math.floor((tonumber((kk_s:gsub(',','.'))or 0))*1e6)+(tonumber((k_s:gsub('[.,]',''))) or 0)
    end
    local m_s,k2_s = c:match('М%D*([%d%.%,]+)%D+К%D*([%d%.%,]+)')
    if m_s and k2_s then
        return math.floor((tonumber((m_s:gsub(',','.'))or 0))*1e9)+(tonumber((k2_s:gsub('[.,]',''))) or 0)
    end
    local kk = c:match('КК%D*([%d%.%,]+)')
    if kk then return math.floor((tonumber((kk:gsub(',','.'))) or 0)*1e6) end
    local m = c:match('М%D*([%d%.%,]+)')
    if m then return math.floor((tonumber((m:gsub(',','.'))) or 0)*1e9) end
    local k = c:match('К%s*([%d%.%,]+)')
    if k then
        if k:find('[.,]') then return tonumber((k:gsub('[.,]',''))) or 0
        else return (tonumber(k) or 0)*1000 end
    end
    local d = c:gsub('^%$',''):gsub('%s','')
    local nd=0; for _ in d:gmatch('%.') do nd=nd+1 end
    if nd>1 then d=d:gsub('[.,]','')
    elseif nd==1 then local a=d:match('%.(%d+)$'); if a and #a==3 then d=d:gsub('%.','') end end
    d=d:gsub(',','')
    return tonumber(d)
end
local function _hbr6z(text)
    if not text or text=="" then return 0 end
    local count=0; local iline=0
    for raw in text:gmatch("[^\n]+") do
        iline=iline+1
        if iline>3 then
            local clean=raw:gsub("{%x+}","")
            local is_vc=clean:find("[Vv][Cc]%$") ~= nil
            local name,price_s
            -- Парсинг с учётом КК/К/М
            local price_raw
            if is_vc then
                name, price_raw = clean:match('^(.-)%s+[Vv][Cc]%s*%$?(.+)$')
                if not name then name,price_raw=clean:match('^(.-)       [Vv][Cc]%$?(.+)$') end
            else
                name, price_raw = clean:match('^(.-)%s* (.+)$')  -- TAB разделитель
                if not name then name, price_raw = clean:match('^(.-)%s%s+(.+)$') end  -- 2+ пробела
            end
            name = name and name:match('^%s*(.-)%s*$') or ''
            local price = price_raw and _parse_mkt_price(price_raw) or nil
            if name~="" and price and price>10 then
                local e=fh_mkt_prices[name] or {}
                if is_vc then
                    if not e.vc_st or (os.time()-e.vc_st)>60 then e.vc_st=os.time(); e.vc_sp=nil end
                    if e.vc_sp then
                        e.vc_min=e.vc_min and math.min(e.vc_min,price) or math.min(e.vc_sp,price)
                        e.vc_max=e.vc_max and math.max(e.vc_max,price) or math.max(e.vc_sp,price)
                    else e.vc_sp=price end
                    e.vc_totalP=(e.vc_totalP or 0)+price; e.vc_totalC=(e.vc_totalC or 0)+1
                    e.vc_avg=math.floor(e.vc_totalP/e.vc_totalC)
                    e.vc_min=e.vc_min or price; e.vc_max=e.vc_max or price
                else
                    if not e.cp_st or (os.time()-e.cp_st)>60 then
                        -- Новая сессия скана: сбрасываем накопленные суммы
                        e.cp_st=os.time(); e.cp_sp=nil
                        e.s_totalP=nil; e.s_totalC=nil
                        e.s_min=nil; e.s_max=nil
                    end
                    if e.cp_sp then
                        e.s_min=e.s_min and math.min(e.s_min,price) or math.min(e.cp_sp,price)
                        e.s_max=e.s_max and math.max(e.s_max,price) or math.max(e.cp_sp,price)
                    else e.cp_sp=price end
                    e.s_totalP=(e.s_totalP or 0)+price; e.s_totalC=(e.s_totalC or 0)+1
                    e.s_avg=math.floor(e.s_totalP/e.s_totalC)
                    e.s_min=e.s_min or price; e.s_max=e.s_max or price
                end
                e.date=os.date("%d.%m.%Y"); fh_mkt_prices[name]=e; count=count+1
            end
        end
    end
    if count>0 then fh_mkt_last_update=os.date("%d.%m %H:%M") end
    return count
end

local function fh_mkt_save_cp_detail(item_name, history)
    if not item_name or item_name == "" or not history then return end
    local dt = os.date("%d.%m %H:%M")
    local e = fh_mkt_prices[item_name] or {}
    e.cp_hist = history
    local total_pxq, total_q = 0, 0
    local s_min, s_max
    for _, h in ipairs(history) do
        if h.price and h.price > 0 then
            local q = h.qty or 1
            total_pxq = total_pxq + h.price * q; total_q = total_q + q
            if not s_min or h.price < s_min then s_min = h.price end
            if not s_max or h.price > s_max then s_max = h.price end
        end
    end
    if total_q > 0 then
        e.s_avg=math.floor(total_pxq/total_q); e.s_min=s_min; e.s_max=s_max
        e.s_totalC=total_q; e.date=dt
        fh_mkt_prices[item_name]=e; fh_mkt_last_update=dt
    end
end

local function _nqh8s(text, style)
    local items = {}
    if not text or text == "" then return items end
    local iline = 0; local list_idx = -1
    for raw in text:gmatch("[^\n]+") do
        iline = iline + 1
        if iline == 1 then
        else
            list_idx = list_idx + 1
            local clean = raw:gsub("{%x+}",""):match("^%s*(.-)%s*$") or ""
            local skip = clean=="" or clean:find("^Поиск по") or clean:find("^Следующая страница") or
                clean:find("^Предыдущая страница") or clean:find("^>>") or clean:find("^<<") or
                clean:find("Проанализировать все цены") or clean:find("Углублённый скан")
            if not skip and clean ~= "" then
                local nm = clean:match("^(.-)%s*\t") or clean:match("^(.-)%s*%$") or clean
                nm = nm:match("^%s*(.-)%s*$") or ""
                if nm ~= "" and #nm > 1 then table.insert(items, {name=nm, idx=list_idx}) end
            end
        end
    end
    return items
end

local function _gyc9t(text)
    if not text or text == "" then return 0 end
    local count = 0; local iline = 0
    for raw in text:gmatch("[^\n]+") do
        iline = iline + 1
        if iline > 1 then
            local clean = raw:gsub("{%x+}", "")
            local price_raw2
            name, price_raw2 = clean:match('^(.-)%s*    (.+)$')  -- TAB разделитель
            if not name then name, price_raw2 = clean:match('^(.-)%s%s+(.+)$') end  -- 2+ пробела
            name = name and name:match("^%s*(.-)%s*$") or ""
            name = name:gsub('##%a%d+$','')
            local price = _parse_mkt_price(price_raw2 or '')
            if name ~= "" and price and price > 1000 then
                local e = fh_mkt_auto[name] or {}
                if not e.cp_st or (os.time() - (e.cp_st or 0)) > 60 then
                    e.cp_st = os.time(); e.cp_sp = nil
                    e.s_totalP = nil; e.s_totalC = nil
                    e.s_min = nil; e.s_max = nil
                end
                if e.cp_sp then
                    e.s_min = e.s_min and math.min(e.s_min, price) or math.min(e.cp_sp, price)
                    e.s_max = e.s_max and math.max(e.s_max, price) or math.max(e.cp_sp, price)
                else e.cp_sp = price end
                e.s_totalP = (e.s_totalP or 0) + price
                e.s_totalC = (e.s_totalC or 0) + 1
                e.s_avg = math.floor(e.s_totalP / e.s_totalC)
                e.s_min = e.s_min or price; e.s_max = e.s_max or price
                if not e.hist then e.hist = {} end
                local dt_now = os.date("%d.%m")
                if not e.hist[1] or e.hist[1].dt ~= dt_now then
                    table.insert(e.hist, 1, {dt = dt_now, price = price})
                    while #e.hist > 30 do table.remove(e.hist) end
                else e.hist[1].price = price end
                e.date = os.date("%d.%m.%Y"); fh_mkt_auto[name] = e; count = count + 1
            end
        end
    end
    if count > 0 then fh_mkt_auto_last_upd = os.date("%d.%m %H:%M") end
    return count
end

local function fh_mkt_parse_auto_list(text)
    local items = {}
    if not text or text == '' then return items end
    local iline = 0; local list_idx = -1
    for raw in text:gmatch('[^\n]+') do
        iline = iline + 1
        if iline == 1 then
        else
            list_idx = list_idx + 1
            local clean = raw:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
            local skip = clean == '' or
                clean:find('^Поиск по') or
                clean:find('^Следующая страница') or
                clean:find('^Предыдущая страница') or
                clean:find('Сканировать все авто') or
                clean:find('Углублённый скан')
            if not skip and clean ~= '' then
                local nm = clean:match('^(.-)%s*\t') or clean:match('^(.-)%s*%$') or clean
                nm = nm:gsub('##%a%d+$',''):match('^%s*(.-)%s*$') or ''
                if nm ~= '' and #nm > 1 then table.insert(items, {name=nm, idx=list_idx}) end
            end
        end
    end
    return items
end

local function fh_mkt_parse_auto_detail(text, title_text)
    if not text or text == '' then return nil end
    local item_name = ''
    if title_text then
        local tn = title_text:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
        local nm = tn:match("'(.+)'") or tn:match('"(.+)"')
        if nm and nm ~= '' then item_name = nm
        elseif tn ~= '' and not tn:find('Продажа') and not tn:find('последние') then item_name = tn end
    end
    if item_name == '' then return nil end
    item_name = item_name:gsub('##%a%d+$','')
    local history = {}
    for line in text:gmatch('[^\n]+') do
        local clean = line:gsub('{%x%x%x%x%x%x}',''):match('^%s*(.-)%s*$') or ''
        if clean ~= '' then
            local dt_s, qty_s, price_s
            -- Формат сервера: YYYY-MM-DD        QTY     :КК: N :К: N.NNN (захватываем всё после 2-го таба)
            dt_s, qty_s, price_s = clean:match('^(%d%d%d%d%-%d%d%-%d%d)%s*\t%s*(%d+)%s*\t%s*(.+)')
            if not dt_s then dt_s, qty_s, price_s = clean:match('^(%d%d%d%d%-%d%d%-%d%d)%s+(%d+)%s+(.+)') end
            if not dt_s then dt_s, qty_s, price_s = clean:match('^(%d%d%d%d%-%d%d%-%d%d)%s*|%s*(%d+)%s*|%s*(.+)') end
            if not dt_s then
                local p2; dt_s, p2 = clean:match('^(%d%d%d%d%-%d%d%-%d%d)%s*\t%s*(.+)')
                if dt_s then qty_s = '1'; price_s = p2 end
            end
            if dt_s and price_s then
                local price = _parse_mkt_price(price_s)  -- поддерживает :КК: N :К: N.NNN и другие форматы
                local qty = tonumber(qty_s) or 1
                if price and price > 0 then table.insert(history, {dt=dt_s, qty=qty, price=price}) end
            end
        end
    end
    return { name=item_name, history=history }
end

local function fh_mkt_save_auto_detail(item_name, history)
    if not item_name or item_name == '' or not history or #history == 0 then return end
    local dt = os.date('%d.%m %H:%M')
    local e = fh_mkt_auto[item_name] or {}
    e.cp_hist = history
    local total_pxq, total_q = 0, 0; local s_min, s_max
    for _, h in ipairs(history) do
        if h.price and h.price > 0 then
            local q = h.qty or 1
            total_pxq = total_pxq + h.price * q; total_q = total_q + q
            if not s_min or h.price < s_min then s_min = h.price end
            if not s_max or h.price > s_max then s_max = h.price end
        end
    end
    if total_q > 0 then
        e.s_avg = math.floor(total_pxq/total_q); e.s_min = s_min; e.s_max = s_max
        e.s_totalC = total_q; e.date = dt
    end
    fh_mkt_auto[item_name] = e; fh_mkt_auto_last_upd = dt
end

local mh_isActiveCommand = false
local function _tcz2r(text, waiting, callback)
    if mh_isActiveCommand then return end
    lua_thread.create(function()
        mh_isActiveCommand = true
        local lines = {}
        for line in text:gmatch("[^&]+") do table.insert(lines, line) end
        for i, line in ipairs(lines) do
            if i > 1 then wait((waiting or 1.5) * 1000) end
            sampSendChat(line)
        end
        mh_isActiveCommand = false
        if callback then callback() end
    end)
end

local function _xjg7y(index)
    local t = settings.piar_templates and settings.piar_templates[index]
    if not t or not t.enable then return end
    _tcz2r(table.concat(t.lines, '&'), t.waiting, function() t.last_time = os.time() end)
end

local function _pxm3k(text, title_clean)
    if not text or text=="" then return nil end
    local name=""
    for line in text:gmatch("[^\n]+") do
        local n=line:match(":%s*{[^}]+}(.-)%s*{[^}]+}")
        if not n or n=="" then n=line:match("{[^}]+}(.-)%s*{[^}]+}") end
        if n and n~="" then name=n; break end
    end
    local price_s=""
    for line in text:gmatch("[^\n]+") do
        local p=line:match("Стоимость:.-$([%d,%.]+)")
        if not p then p=line:match("Стоимость:[^\n]-(%d[%d,%.]+)") end
        if p then price_s=p; break end
    end
    local qty_s="1"
    for line in text:gmatch("[^\n]+") do
        local q=line:match("В%s*наличии:%s*(.-)%s*шт")
        if not q then q=line:match("Игрок%s*покупает:%s*(.-)%s*шт") end
        if q then qty_s=q; break end
    end
    local price=tonumber((price_s:gsub("[,.]",""))); local qty=tonumber(qty_s) or 1
    if name=="" or not price or price<=0 then return nil end
    local op=(title_clean and title_clean:find("Покупка")) and "sell" or "buy"
    return {name=name,price=price,qty=qty,op=op}
end

local function _jnw7r(name,price,qty,op)
    if not name or name=="" or not price or price<=0 then return end
    local dt=os.date("%d.%m %H:%M")
    fh_mkt_lavka[name]=_bmj2p(fh_mkt_lavka[name] or {},price,qty or 1,op)
    table.insert(fh_mkt_lavka_log,{dt=dt,item=name,price=price,qty=qty or 1,op=op})
    while #fh_mkt_lavka_log>1000 do table.remove(fh_mkt_lavka_log,1) end
end

local function _xgf3s(dtext)
    if not dtext or dtext == '' then return nil end
    for line in dtext:gmatch('[^\n]+') do
        local n = line:match('[Кк]упить%s+предмет%s+{[^}]+}(.-)%s*{[^}]+}%s*%(ID:')
        if not n then n = line:match('[Кк]упить%s+предмет%s+(.-)%s+%(ID:') end
        if not n then n = line:match('[Пп]родать%s+предмет%s+{[^}]+}(.-)%s*{[^}]+}') end
        if not n then n = line:match('[Пп]родать%s+предмет%s+(.-)%s+%(ID:') end
        if n and n ~= '' then return n:match('^%s*(.-)%s*$') end
    end
    for line in dtext:gmatch('[^\n]+') do
        local n = line:match('{[^}]+}([^{]+){[^}]+}')
        if n then
            n = n:match('^%s*(.-)%s*$')
            if n and #n > 1 and not n:find('^%d') and not n:find('^%[') then
                return n
            end
        end
    end
    return nil
end

local function _qrm8t(text, title_clean)
    if not text or text == "" then return nil end
    local name = _xgf3s(text) or ""
    if name == "" then return nil end
    local slot_type
    if title_clean and title_clean:find("Продажа") and not title_clean:find("предмета") then
        slot_type = "buy_items"
    else
        slot_type = "sell_items"
    end
    local price = 0
    local clean = text:gsub('{%x+}', '')
    for line in clean:gmatch("[^\n]+") do
        local p = line:match("[Сс]тоимость%s*:%s*%$?([%d%s,]+)")
              or  line:match("[Цц]ена%s*:%s*%$?([%d%s,]+)")
        if p then price = tonumber((p:gsub('[%s,]',''))) or 0; break end
    end
    if price == 0 then
        local best = 0
        for p_s in clean:gmatch("%$([%d,]+)") do
            local pn = tonumber((p_s:gsub(',',''))) or 0
            if pn > best then best = pn end
        end
        price = best
    end
    local qty = tonumber(clean:match("[Вв]%s*наличии%s*:%s*(%d+)")) or 1
    return {name=name, price=price, qty=qty, slot_type=slot_type}
end

local function _qbh9f()
    if not fh_other_shop_cur then
        if mh_debug_enabled then sampAddChatMessage('[MH DBG] _qbh9f: fh_other_shop_cur=nil', 0xFF6600) end
        return
    end
    local s = fh_other_shop_cur
    if not s.owner or s.owner == "" then
        if mh_debug_enabled then sampAddChatMessage('[MH DBG] _qbh9f: owner пустой', 0xFF6600) end
        return
    end
    if #s.sell_items == 0 and #s.buy_items == 0 then
        if mh_debug_enabled then sampAddChatMessage('[MH DBG] _qbh9f: sell=0 buy=0, не сохраняем', 0xFF6600) end
        return
    end
    if mh_debug_enabled then
        sampAddChatMessage('[MH DBG] _qbh9f: '..s.owner..' sell='..#s.sell_items..' buy='..#s.buy_items..' srv='..tostring(s.server_id), 0x66FF66)
    end
    local new_key = s.owner .. '_' .. tostring(s.shop_num or '?')
    local owner_lo = s.owner:lower()
    local snum_s   = tostring(s.shop_num or '?')
    for k, v in pairs(fh_other_shops) do
        if k ~= new_key then
            local same_owner = v.owner and v.owner:lower() == owner_lo
            local same_num  = snum_s ~= '?' and v.shop_num
                              and tostring(v.shop_num) == snum_s
            if same_owner or same_num then
                fh_other_shops[k] = nil
            end
        end
    end
    fh_other_shops[new_key] = s
    for _, it in ipairs(s.sell_items or {}) do
        if it.name and it.name ~= '' and it.price and it.price > 0 then
            _jnw7r(it.name, it.price, it.qty or 1, 'sell')
        end
    end
    for _, it in ipairs(s.buy_items or {}) do
        if it.name and it.name ~= '' and it.price and it.price > 0 then
            _jnw7r(it.name, it.price, it.qty or 1, 'buy')
        end
    end
    settings.other_shops = fh_other_shops
    _wfn7p()
    _crf5h(s)  -- auto-push to MH Cloud
end

local function _to_utf8(s)
    if not s then return '' end
    local ok, r = pcall(function() return require('encoding').UTF8:encode(tostring(s)) end)
    return ok and r or tostring(s)
end

-- ================================================================
-- MH CLOUD: Синхронизация цен ЦР с облаком
-- ================================================================
local _mh_pprices_pushing = false
local _mh_pprices_pulling = false

local function _mh_prices_push()
    if _mh_pprices_pushing then return end
    local srv_id = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or 1] or {}).id or -1
    local items = {}
    for nm, e in pairs(fh_mkt_prices) do
        -- Берём только товары с реальными данными
        if e and (e.s_avg and e.s_avg > 0 or e.cp_sp and e.cp_sp > 0
                  or e.cp_hist and #e.cp_hist > 0) then
            local entry = { name = _to_utf8(nm) }
            if e.cp_hist and #e.cp_hist > 0 then
                entry.cp_hist = e.cp_hist
            end
            if e.cp_sp  and e.cp_sp  > 0 then entry.cp_sp  = e.cp_sp  end
            if e.s_avg  and e.s_avg  > 0 then entry.s_avg  = e.s_avg  end
            if e.s_min  and e.s_min  > 0 then entry.s_min  = e.s_min  end
            if e.s_max  and e.s_max  > 0 then entry.s_max  = e.s_max  end
            table.insert(items, entry)
        end
    end
    if #items == 0 then
        sampAddChatMessage('[MH Cloud] {ffaa00}Нет данных ЦР для отправки', 0xFFFFFF)
        return
    end
    local ok_j, j = pcall(encodeJson, { server_id = srv_id, items = items })
    if not ok_j then
        sampAddChatMessage('[MH Cloud] {ff4444}Ошибка JSON при пуше цен', 0xFFFFFF)
        return
    end
    _mh_pprices_pushing = true
    _jmx9s(_vbr7n .. '/prices/push', j, function(code, body, _e)
        _mh_pprices_pushing = false
        if code == 200 then
            sampAddChatMessage('[MH Cloud] {00cc00}Цены ЦР загружены ('..#items..' товаров)', 0xFFFFFF)
        elseif code == nil and _e and (tostring(_e):find('connect') or tostring(_e):find('timeout') or tostring(_e):find('refused') or tostring(_e):find('resolve')) then
            -- Реальная сетевая ошибка
            sampAddChatMessage('[MH Cloud] {ff4444}Нет связи с сервером: '..tostring(_e), 0xFFFFFF)
        else
            -- Ошибка сериализации effil или code=0 — данные скорее всего ушли
            if mh_debug_enabled then
                sampAddChatMessage('[MH Cloud] {ffaa00}Цены отправлены (нет подтверждения)', 0xFFFFFF)
            end
        end
    end)
end

local function _mh_prices_pull(silent)
    if _mh_pprices_pulling then return end
    local srv_id = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or 1] or {}).id or -1
    _mh_pprices_pulling = true
    if not silent then
        sampAddChatMessage('[MH Cloud] {aaaaff}Загружаю цены ЦР...', 0xFFFFFF)
    end
    _fwm2c(_vbr7n .. '/prices/pull?server=' .. tostring(srv_id), function(code, body, _e)
        _mh_pprices_pulling = false
        if _e or not body or #body == 0 then
            if not silent then
                sampAddChatMessage('[MH Cloud] {ff4444}Ошибка загрузки цен', 0xFFFFFF)
            end
            return
        end
        local ok, parsed = pcall(decodeJson, body)
        if not ok or type(parsed) ~= 'table' or not parsed.items then
            if not silent then
                sampAddChatMessage('[MH Cloud] {ff4444}Ошибка парсинга цен', 0xFFFFFF)
            end
            return
        end
        local merged = 0
        for _, item in ipairs(parsed.items) do
            local nm = item.name
            if nm and nm ~= '' then
                -- Декодируем из UTF-8 обратно в CP1251
                local ok_d, nm_cp = pcall(function()
                    return require('encoding').CP1251:encode(nm)
                end)
                if ok_d and nm_cp then nm = nm_cp end
                local existing = fh_mkt_prices[nm]
                -- Мержим: не перезаписываем если у нас данные новее
                local srv_upd = item.updated_at or 0
                local our_upd = existing and existing._upd_ts or 0
                if not existing or srv_upd > our_upd then
                    local e = existing or {}
                    if item.cp_hist and #item.cp_hist > 0 then
                        e.cp_hist = item.cp_hist
                    end
                    if item.cp_sp and item.cp_sp > 0 then e.cp_sp = item.cp_sp end
                    if item.s_avg and item.s_avg > 0 then
                        e.s_avg = item.s_avg
                        e.s_min = item.s_min or e.s_min
                        e.s_max = item.s_max or e.s_max
                    end
                    e._upd_ts = srv_upd
                    fh_mkt_prices[nm] = e
                    merged = merged + 1
                end
            end
        end
        _wfn7p()  -- обновить кэш списка
        if not silent then
            sampAddChatMessage('[MH Cloud] {00cc00}Цены ЦР получены: '..merged..' обновлено из '..#parsed.items, 0xFFFFFF)
        end
    end)
end
-- ================================================================


function _crf5h(s)
    if not s or not s.owner or s.owner == '' then return end
    if mh_debug_enabled then
        sampAddChatMessage('[MH DBG] _crf5h: '..tostring(s.owner)..' srv='..tostring(s.server_id or -1)..' sell='..#(s.sell_items or {})..' buy='..#(s.buy_items or {}), 0x66AAFF)
    end
    local _owner_u8 = _to_utf8(s.owner)
    local _sell_u8, _buy_u8 = {}, {}
    for _, it in ipairs(s.sell_items or {}) do
        table.insert(_sell_u8, { name = _to_utf8(it.name), price = it.price, qty = it.qty, item_id = it.item_id or 0 })
    end
    for _, it in ipairs(s.buy_items or {}) do
        table.insert(_buy_u8, { name = _to_utf8(it.name), price = it.price, qty = it.qty, item_id = it.item_id or 0 })
    end
    -- Fallback: if server_id==-1, try auto-detect
    local _sid = s.server_id or -1
    if _sid == -1 then
        local _auto = _mpf7d()
        if _auto and _auto > 0 then
            _sid = (ARZ_SERVERS[_auto + 1] or {}).id or -1
        end
    end
    -- Не блокируем push при _sid==-1: сервер принимает и логирует
    -- (до 3.6.5 так и работало, данные всегда доходили)
    if mh_debug_enabled and _sid == -1 then
        sampAddChatMessage('[MH Cloud] {ffaa00}Push с server_id=-1 (' .. (s.owner or '?') .. ') — сервер примет', 0xFFFFFF)
    end
    local payload = {
        server_id  = _sid,
        owner      = _owner_u8,
        shop_num   = tostring(s.shop_num or '?'),
        sell_slots = _sell_u8,
        buy_slots  = _buy_u8,
        scanned_at = os.time(),
    }
    local ok_j, j = pcall(encodeJson, payload)
    if not ok_j then
        sampAddChatMessage('[MH Cloud] {ff6644}JSON encode err', 0xFFFFFF)
        return
    end
    _jmx9s(_vbr7n .. '/shops/push', j, function(code, body, _e)
        _szb8v   = (code == 200)
        _gnl3q = os.time()
        if code == 200 then
            if mh_debug_enabled then
                sampAddChatMessage('[MH Cloud] {aaffaa}Push OK: ' .. _owner_u8, 0xFFFFFF)
            end
        elseif code == nil and _e and (tostring(_e):find('connect') or tostring(_e):find('timeout') or tostring(_e):find('refused') or tostring(_e):find('resolve')) then
            -- Реальная сетевая ошибка — сервер не доступен
            sampAddChatMessage('[MH Cloud] {ff4444}Нет связи с сервером: ' .. tostring(_e), 0xFFFFFF)
        elseif code == 0 or (code ~= 200 and code ~= nil) then
            -- code=0: effil не вернул ответ, но запрос скорее всего ушёл
            -- Другой code: сервер вернул ошибку (4xx/5xx)
            if code == 0 then
                -- Молчим — данные вероятно на сервере
                _szb8v = true  -- считаем успехом
            else
                sampAddChatMessage('[MH Cloud] {ff6644}Push: сервер вернул ' .. tostring(code), 0xFFFFFF)
            end
        else
            -- nil code + не сетевая ошибка = effil serialize issue
            _szb8v = true  -- считаем что ушло
        end
    end)
end

-- Собрать данные своей лавки из пресетов и отправить на облачный сервер
local function mh_push_own_preset_shop()
    local my_nick = ''
    pcall(function()
        my_nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) or ''
    end)
    if my_nick == '' then return end
    -- Номер лавки: 1) диалог 3040 (надёжно), 2) pending, 3) 3D текст
    local my_shop_num = mh_own_shop_num or fh_other_shop_pending_num
    if not my_shop_num then
        pcall(function()
            local _px, _py = getCharCoordinates(PLAYER_PED)
            local _bd, _bn = 8.0, nil
            for _tid = 0, 2047 do
                local _ok, _tt, _, _tpx, _tpy = pcall(sampGet3dTextInfoById, _tid)
                if _ok and _tt and _tpx then
                    local _n = tostring(_tt):match('[#\xe2\x84\x96]%s*(%d+)')
                    if not _n then _n = tostring(_tt):match('(%d+)$') end
                    if _n then
                        local _num = tonumber(_n)
                        if _num and _num >= 1 and _num <= 9999 then
                            local _d = math.sqrt((_tpx-_px)^2+(_tpy-_py)^2)
                            if _d < _bd then _bd=_d; _bn=_num end
                        end
                    end
                end
            end
            if _bn then my_shop_num = _bn end
        end)
    end
    local sell_items = {}
    if _G._mh_sell_ran_session then
        for _, p in ipairs(fh_lv_autosell_preset or {}) do
            if p.name and p.name ~= '' and (p.price or 0) > 0 then
                table.insert(sell_items, {name=p.name, price=p.price, qty=p.qty or 1})
            end
        end
    end
    local buy_items = {}
    if _G._mh_buy_ran_session then
        for _, p in ipairs(fh_lv_autobuy_preset or {}) do
            if p.name and p.name ~= '' and (p.max_price or 0) > 0 then
                table.insert(buy_items, {name=p.name, price=p.max_price, qty=p.qty or 1})
            end
        end
    end
    if #sell_items == 0 and #buy_items == 0 then return end
    local shop_obj = {
        owner      = my_nick,
        shop_num   = my_shop_num or '?',
        dt         = os.date('%d.%m %H:%M'),
        ts         = os.time(),
        sell_items = sell_items,
        buy_items  = buy_items,
        server_id  = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or (_mpf7d()+1)] or {}).id or -1,
    }
    -- Сохраняем локально
    local new_key = my_nick .. '_' .. tostring(my_shop_num or '?')
    fh_other_shops[new_key] = shop_obj
    settings.other_shops = fh_other_shops
    _wfn7p()
    -- Пушим на облако
    _crf5h(shop_obj)
    sampAddChatMessage('[MH Cloud] {aaffaa}Своя лавка отправлена: '
        ..my_nick..' #'..tostring(my_shop_num or '?')
        ..' ('..#sell_items..' прод / '..#buy_items..' скуп)', 0xFFFFFF)
end

_wyk7z = 899999
function _pkw2y(server_id)
    local sid = tostring(server_id ~= nil and server_id or -1)
    _xht6j = true
    _dfn1c   = nil
    _fwm2c(_vbr7n .. '/shops/pull?server=' .. sid, function(c2, t2, e2)
        _xht6j = false
        if e2 then _dfn1c = tostring(e2); return end
        if not t2 or #t2 == 0 then _dfn1c = 'Пустой ответ'; return end
        local ok2, parsed = pcall(decodeJson, t2)
        if not ok2 or type(parsed) ~= 'table' or not parsed.shops then
            _dfn1c = 'JSON err: ' .. tostring(c2)
            return
        end
        if not mh_arz_items_db then mh_arz_items_db = {} end
        if not mh_arz_items_loaded and not mh_arz_items_loading then
            _cky4h()
        end
        local added = 0
        for _, sh in ipairs(parsed.shops) do
            if sh.owner and sh.owner ~= '' then
                -- Clean corrupted owner from server (e.g. "?????- Nick" -> "Nick")
                  do
                      local _co = sh.owner:match('%-%s*([A-Za-z_][A-Za-z0-9_]+)')
                               or sh.owner:match('^([A-Za-z_][A-Za-z0-9_]+)')
                      if _co and _co ~= '' then sh.owner = _co end
                  end
                local found_idx = nil
                local _sh_uid_s = tostring(sh.shop_num or '')
                local _sh_uid_valid = _sh_uid_s ~= '' and _sh_uid_s ~= '0' and _sh_uid_s ~= '?'
                local _sh_srv = sh.server_id  -- server_id с сервера
                for idx, lv in ipairs(mh_arz_data) do
                    -- Совпадение сервера обязательно: не пытаемся попасть в чужой сервер
                    if _sh_srv and _sh_srv ~= -1 and lv.serverId and lv.serverId ~= _sh_srv then
                        goto _merge_next
                    end
                    local nick_match = lv.username and lv.username:lower() == sh.owner:lower()
                    local uid_match  = _sh_uid_valid and lv.LavkaUid
                                       and tostring(lv.LavkaUid) == _sh_uid_s
                    if nick_match or uid_match then
                        found_idx = idx; break
                    end
                    ::_merge_next::
                end
                local sell_ids, sell_pr, sell_cnt = {}, {}, {}
                for _, slot in ipairs(sh.sell_slots or {}) do
                    local _nm = slot.name
                    if _nm and _nm ~= '' and _nm ~= '?' then
                        _wyk7z = _wyk7z + 1
                        mh_arz_items_db[_wyk7z] = _nm
                        table.insert(sell_ids, _wyk7z)
                        table.insert(sell_pr,  slot.price or 0)
                        table.insert(sell_cnt, slot.qty   or 0)
                    end
                end
                local buy_ids, buy_pr, buy_cnt = {}, {}, {}
                for _, slot in ipairs(sh.buy_slots or {}) do
                    local _nm = slot.name
                    if _nm and _nm ~= '' and _nm ~= '?' then
                        _wyk7z = _wyk7z + 1
                        mh_arz_items_db[_wyk7z] = _nm
                        table.insert(buy_ids, _wyk7z)
                        table.insert(buy_pr,  slot.price or 0)
                        table.insert(buy_cnt, slot.qty   or 0)
                    end
                end
                local entry = {
                    -- fix: server_id=-1 is truthy in Lua so use explicit check
                    serverId    = (sh.server_id and sh.server_id ~= -1) and sh.server_id or (tonumber(sid) or -1),
                    username    = sh.owner,
                    LavkaUid    = sh.shop_num or 0,
                    items_sell  = sell_ids,
                    price_sell  = sell_pr,
                    count_sell  = sell_cnt,
                    items_buy   = buy_ids,
                    price_buy   = buy_pr,
                    count_buy   = buy_cnt,
                    _mh_cloud   = true,
                    _mh_premium    = sh.is_premium == true,
                    _mh_updated_at = sh.updated_at or sh.scanned_at or 0,
                }
                if found_idx then
                    local _ex = mh_arz_data[found_idx]
                    _ex._mh_cloud      = true
                    _ex._mh_premium    = entry._mh_premium or _ex._mh_premium
                    _ex._mh_updated_at = entry._mh_updated_at or _ex._mh_updated_at
                    -- Всегда обновляем товары из облака если там есть данные
                    -- (раньше обновляли только если список был пуст — поэтому свежие данные не появлялись)
                    if #sell_ids > 0 then
                        _ex.items_sell = sell_ids; _ex.price_sell = sell_pr; _ex.count_sell = sell_cnt
                    end
                    if #buy_ids > 0 then
                        _ex.items_buy = buy_ids; _ex.price_buy = buy_pr; _ex.count_buy = buy_cnt
                    end
                    if not _ex.LavkaUid or _ex.LavkaUid == 0 then
                        _ex.LavkaUid = entry.LavkaUid
                    end
                    added = added + 1  -- сбрасываем кэш и при обновлении тоже
                else
                    table.insert(mh_arz_data, entry)
                    added = added + 1
                end
            end
        end
        _mvr4p = true
        _G._dtl_cache_nm = nil
        _G.arz_cache_key = nil  -- всегда сбрасываем после pull
        if mh_debug_enabled then
            sampAddChatMessage('[MH DBG] pull done: added='..added..' total_cloud='..#parsed.shops, 0x66FF99)
        end
        if mh_arz_items_loaded then
            lua_thread.create(function()
                wait(100)
                _ztc7m(tonumber(sid) or -1)
            end)
        end
    end)
end

local function _bky4d(txt)
    if not txt then return nil end
    local s = txt:gsub('{%x%x%x%x%x%x}',' '):gsub(',','.'):match('^%s*(.-)%s*$') or ''
    s = s:gsub('[Kk][Kk]','КК')
    s = s:gsub('([^%a])([Kk])([^%a])',function(a,k,b) return a..'К'..b end)
    s = s:gsub('^([Kk])([^%a])',function(k,b) return 'К'..b end)
    s = s:gsub('([^%a])([Mm])([^%a])',function(a,m,b) return a..'М'..b end)
    s = s:gsub('^([Mm])([^%a])',function(m,b) return 'М'..b end)
    local kk_i,frac_i = s:match('КК%D*(%d+)%D+(%d[%d%.]*)')  -- %D+ = любой не-цифровой
    if kk_i and frac_i then
        return math.floor(tonumber(kk_i)*1e6)+(tonumber((frac_i:gsub('%.',''))) or 0)
    end
    local m_i,frac_m = s:match('М%D*(%d+)%D+(%d[%d%.]*)')
    if m_i and frac_m then
        return math.floor(tonumber(m_i)*1e9)+(tonumber((frac_m:gsub('%.',''))) or 0)
    end
    local kk_s,k_s = s:match('КК%D*([%d%.]+)%D+К%D*([%d%.]+)')
    if kk_s and k_s then
        return math.floor((tonumber(kk_s) or 0)*1e6)+(tonumber((k_s:gsub('%.',''))) or 0)
    end
    local kk2 = s:match('КК%D*([%d%.]+)')
    if kk2 then local p=math.floor((tonumber(kk2) or 0)*1e6); if p>=500 then return p end end
    local ms = s:match('М%D*([%d%.]+)')
    if ms then local p=math.floor((tonumber(ms) or 0)*1e9); if p>=500 then return p end end
    local ks = s:match('К%s*([%d][%d%.]*)')
    if ks then
        local p=tonumber((ks:gsub('%.',''))) or 0
        if p==0 then p=math.floor((tonumber(ks) or 0)*1000) end
        if p>=500 then return p end
    end
    local plain=s:gsub('[%s]','')
    local p=tonumber(plain:match('^%$([%d%.]+)$'))
    if not p then p=tonumber(plain:match('^([%d%.]+)$')) end
    if p and p<500 then
        local s2=plain:gsub('[%$]',''):gsub('%.',''); local p2=tonumber(s2)
        if p2 and p2>=500 then p=p2 end
    end
    if p and p>=500 then return p end
    return nil
end
local function _ntx3c(owner, shop_num)
    fh_other_shop_price_tds = {}
    fh_other_shop_cur = {
        owner      = owner or fh_other_shop_owner or "?",
        shop_num   = shop_num or (function() _G.mh_shop_scan_cnt = (_G.mh_shop_scan_cnt or 0) + 1; return tostring(_G.mh_shop_scan_cnt) end)(),
        dt         = os.date('%d.%m %H:%M'),
        ts         = os.time(),  -- unix timestamp для очистки старых лавок
        sell_items = {},
        buy_items  = {},
        server_id  = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or (_mpf7d()+1)] or {}).id or -1,
    }
    fh_other_shop_scanning = true
    sampAddChatMessage('[MH] {aaaaff}Лавка ' .. (owner or '?') .. ' #' .. tostring(shop_num or '?')
        .. ' — нажми "Меню товаров" для скана', 0xFFFFFF)

    lua_thread.create(function()
        local wait_ms = 0
        while wait_ms < 15000 do
            wait(200); wait_ms = wait_ms + 200
            if not fh_other_shop_scanning or not fh_other_shop_cur then return end
            if next(fh_other_shop_price_tds) ~= nil then break end
        end

        if not fh_other_shop_scanning or not fh_other_shop_cur then return end

        for td_id, td_data in pairs(fh_mkt_lavka_all_tds) do
            if td_data.text and td_data.position then
                local p = _bky4d(td_data.text)
                if p and not fh_other_shop_price_tds[td_id] then
                    fh_other_shop_price_tds[td_id] = {price=p, x=td_data.position.x, y=td_data.position.y}
                end
            end
        end

        local sorted_prices = {}
        for td_id, info in pairs(fh_other_shop_price_tds) do
            table.insert(sorted_prices, {td_id=td_id, price=info.price, x=info.x, y=info.y})
        end
        table.sort(sorted_prices, function(a, b)
            if math.abs(a.y - b.y) < 8 then return a.x < b.x end
            return a.y < b.y
        end)
        local deduped = {}
        local seen_price_row = {}
        for _, ptd2 in ipairs(sorted_prices) do
            local row_key = tostring(ptd2.price) .. '_' .. tostring(math.floor(ptd2.y / 40))
            if not seen_price_row[row_key] then
                seen_price_row[row_key] = true
                table.insert(deduped, ptd2)
            end
        end
        sorted_prices = deduped

        if mh_debug_enabled then
            sampAddChatMessage('[MH Скан] Ценовых TD: ' .. #sorted_prices, 0xFFAAFF)
            for i, ptd in ipairs(sorted_prices) do
                if i <= 10 then
                    sampAddChatMessage('  [Цена ' .. i .. '] td=' .. ptd.td_id
                        .. ' $' .. ptd.price .. ' x=' .. math.floor(ptd.x) .. ' y=' .. math.floor(ptd.y), 0xaaaaff)
                end
            end
        end

        wait(400) -- небольшой буфер после появления первой цены

        local _dlg_send_done = false

        local MAX_WAIT_MS = 2000  -- 2 сек макс на слот (было 5000)
        local function click_and_wait_dlg(td_id)
            fh_other_dlg_signal = nil
            sampSendClickTextdraw(td_id)
            local elapsed = 0
            while elapsed < MAX_WAIT_MS do
                wait(10); elapsed = elapsed + 10
                if fh_other_dlg_signal then break end
                if not fh_other_shop_scanning then return nil end
                if not fh_mkt_shop_ui_open then return nil end
            end
            local sig = fh_other_dlg_signal
            fh_other_dlg_signal = nil
            return sig
        end

        local function close_and_wait(dlg_id)
            _dlg_send_done = false
            fh_other_dlg_signal = nil
            sampSendDialogResponse(dlg_id, 0, 0, '')
            local elapsed = 0
            while elapsed < 1500 do
                wait(10); elapsed = elapsed + 10
                if _dlg_send_done or fh_other_dlg_signal then break end
                if not fh_other_shop_scanning then break end
            end
        end

        local function insert_item(sig, price_override)
            local tc   = sig.title or ''
            local dtext = sig.text or ''
            local item_id = tonumber(dtext:match('%(?ID:%s*(%d+)%)')) or 0
            local nm
            if item_id > 0 then
                nm = _rgn9z(item_id)
                if nm == ('ID:'..tostring(item_id)) then nm = nil end
            end
            if not nm or nm == '' then nm = _xgf3s(dtext) end
            if not nm or nm == '' then return false end
            if not fh_other_shop_cur then return false end
            local st = (tc:find('\xcf\xf0\xee\xe4\xe0\xe6\xe0') and not tc:find('\xef\xf0\xe5\xe4\xec\xe5\xf2\xe0')) and 'buy_items' or 'sell_items'
            local lst = fh_other_shop_cur[st]
            local qty = tonumber(dtext:match('[\xc2\xe2]%s*\xed\xe0\xeb\xe8\xf7\xe8\xe8%s*:%s*(%d+)')) or 1
            local price_val = price_override or 0
            local ex_item = nil
            for _, it in ipairs(lst) do
                if it.name:lower() == nm:lower() and it.price == price_val then
                    ex_item = it; break
                end
            end
            if ex_item then
                ex_item.qty = (ex_item.qty or 1) + qty
                if item_id > 0 and (not ex_item.item_id or ex_item.item_id == 0) then
                    ex_item.item_id = item_id
                end
            else
                table.insert(lst, {name=nm, price=price_val, qty=qty, item_id=item_id})
                if mh_debug_enabled then
                    sampAddChatMessage('[MH] '..st..': '..nm:sub(1,26)..'  $'..tostring(price_val)..' ID:'..tostring(item_id), 0x88CCFF)
                end
            end
            return true
        end

        if #sorted_prices == 0 then
            sampAddChatMessage('[MH Скан] {ffaa00}Ценовые TD не найдены. Пробуем все слоты...', 0xFFFFFF)
            for _, td_id in ipairs(fh_mkt_shop_inv_tds) do
                if not fh_other_shop_scanning or not fh_other_shop_cur then break end
                local sig2 = click_and_wait_dlg(td_id)
                if sig2 and (sig2.title:find('Покупка') or sig2.title:find('Продажа')) then
                    insert_item(sig2, 0)
                    close_and_wait(sig2.id)
                elseif sig2 then
                    close_and_wait(sig2.id)
                end
            end
        else
            for _, ptd in ipairs(sorted_prices) do
                if not fh_other_shop_scanning or not fh_other_shop_cur then break end

                local candidates = {}
                local has_self = false
                for other_id, other_data in pairs(fh_mkt_lavka_all_tds) do
                    if other_data.position then
                        local dx = math.abs(other_data.position.x - ptd.x)
                        local dy = math.abs(other_data.position.y - ptd.y)
                        if dx <= 25 and dy <= 35 then
                            table.insert(candidates, other_id)
                            if other_id == ptd.td_id then has_self = true end
                        end
                    end
                end
                if not has_self then table.insert(candidates, ptd.td_id) end

                local got_name = false
                for _, cand_id in ipairs(candidates) do
                    if got_name then break end
                    if not fh_other_shop_scanning then break end

                    local sig = click_and_wait_dlg(cand_id)
                    if sig then
                        if sig.title:find('Покупка') or sig.title:find('Продажа') then
                            got_name = insert_item(sig, ptd.price)
                            close_and_wait(sig.id)
                        else
                            close_and_wait(sig.id)
                        end
                    end
                end
            end
        end

        if fh_other_shop_scanning and fh_other_shop_cur then
            _qbh9f()
            fh_other_shop_scanning = false
        end
    end)
end

local function _rcw6d(key)
    fh_other_shops[key] = nil
    settings.other_shops = fh_other_shops
    _wfn7p()
end

local function _dsf3y(item, price, qty, op, status)
    local entry = {
        dt     = os.date('%d.%m %H:%M'),
        item   = item,
        price  = price,
        qty    = qty,
        op     = op,
        status = status
    }
    table.insert(fh_lv_trade_log, 1, entry)
    -- trade log: no 500 limit
end

local function fh_parse_inventory_dialog(dlg_text)
    local raw_items = {}
    for line in dlg_text:gmatch('[^\r\n]+') do
        local clean = line:gsub('{' .. '%x+}', '')
        local slot_s, name, cnt_s
        slot_s, name, cnt_s = clean:match('%[(%d+)%]%s+(.-)%s+%{[^}]*%}%[(%d+)%s+')
        if not slot_s then
            slot_s, name, cnt_s = clean:match('%[(%d+)%]%s+(.-)%s+%[(%d+)%s+')
        end
        if slot_s and name and cnt_s then
            name = name:match('^%s*(.-)%s*$') or name
            if name ~= '' and name ~= 'Название' then
                local _slot = tonumber(slot_s)
                local _cnt = tonumber(cnt_s) or 1
                if mh_debug_enabled then sampAddChatMessage('[INV] slot='..tostring(_slot)..' x'..tostring(_cnt)..' '..name:sub(1,20), 0x888888) end
                table.insert(raw_items, {slot=_slot, name=name, count=_cnt})
            end
        end
    end
    local grouped = {}
    local name_map = {}
    for _, item in ipairs(raw_items) do
        if name_map[item.name] then
            local g = name_map[item.name]
            g.count = g.count + item.count
            g.slots = g.slots .. ';' .. tostring(item.slot)
            table.insert(g.stacks, {slot=item.slot, count=item.count})
        else
            local g = {name=item.name, count=item.count, slots=tostring(item.slot),
                       stacks={{slot=item.slot, count=item.count}}}
            table.insert(grouped, g)
            name_map[item.name] = g
        end
    end
    for _, g in ipairs(grouped) do
        local found = false
        for _, v in ipairs(fh_lv_inventory) do
            if v.name == g.name then
                v.count = v.count + g.count
                v.slots = v.slots .. ';' .. g.slots
                for _, st in ipairs(g.stacks) do table.insert(v.stacks, st) end
                found = true; break
            end
        end
        if not found then table.insert(fh_lv_inventory, g) end
    end
end

fh_lv_inv_dialog_step = 0

local function _vcz9h()
    if fh_lv_inv_scanning then return end
    fh_lv_inv_scanning = true
    fh_lv_inv_dialog_step = 0
    fh_lv_inventory = {}
    sampAddChatMessage('[FH Авто] {ffaa00}Сканирую инвентарь...', 0xFFFFFF)
    sampSendChat('/mm')
    lua_thread.create(function()
        local w = 0
        while fh_lv_inv_scanning and w < 1000 do wait(10); w=w+1 end
        if fh_lv_inv_scanning then
            fh_lv_inv_scanning = false
            fh_lv_inv_dialog_step = 0
            sampAddChatMessage('[FH Авто] {ff4444}Инвентарь не получен (таймаут).', 0xFFFFFF)
        end
    end)
end

local function fh_get_allitems_list()
    local list = {}
    for nm, _ in pairs(fh_mkt_prices) do
        if type(nm) == 'string' then
            table.insert(list, nm)
        end
    end
    table.sort(list)
    return list
end

local function fh_is_slot_dialog(cid)
    if cid == 25665 then return true end
    local title = fh_last_dlg_title or ''
    return title:find('Продажа') ~= nil
        or title:find('Slot') ~= nil
        or title:find('Слот') ~= nil
        or title:find('Товар') ~= nil
end

local function fh_get_slot_item_name(dlg_text, dlg_title)
    local name = ''
    if dlg_title and dlg_title ~= '' then
        local t = dlg_title:gsub('{' .. '%x+}',''):match('^%s*(.-)%s*$') or ''
        local n = t:match(':(.+)$') or ''
        n = n:match('^%s*(.-)%s*$') or ''
        if n ~= '' and not n:find('Продажа') and not n:find('Slot') then name = n end
    end
    if name == '' then name = dlg_text:match('{' .. '57FF6B}(.-){%x+}') or '' end
    if name == '' then
        for line in dlg_text:gmatch('[^\n]+') do
            local n = line:gsub('{' .. '%x+}',''):match('^%s*(.-)%s*$')
            if n and n ~= '' and not n:find(':') and #n > 1 then name = n; break end
        end
    end
    return name:match('^%s*(.-)%s*$') or ''
end

local function _wmc7r()
    if fh_lv_autosell_running or fh_lv_autobuy_running then return end
    if #fh_lv_autosell_preset == 0 then
        sampAddChatMessage('[MH Авто] {ff4444}Пресет пуст.', 0xFFFFFF); return
    end
    if #fh_lv_inventory == 0 then
        sampAddChatMessage('[MH Авто] {ff4444}Сначала нажмите "Скан инвентаря"!', 0xFFFFFF); return
    end
    if not mh_lavka_inv_ready then
        sampAddChatMessage('[MH Авто] {ff4444}Откройте UI: ВЗАИМОДЕЙСТВИЕ -> [1]', 0xFFFFFF)
        return
    end

    local queue = {}
    for _, preset in ipairs(fh_lv_autosell_preset) do
        if preset.enabled ~= false and (preset.price or 0) >= 10 then
            for _, inv in ipairs(fh_lv_inventory) do
                if inv.name:lower() == preset.name:lower() then
                    local stacks = inv.stacks
                    local _preset_left = math.min(preset.qty or inv.count, inv.count)
                    if stacks and #stacks > 0 then
                        for _, st in ipairs(stacks) do
                            if _preset_left <= 0 then break end
                            local _take = math.min(st.count, _preset_left)
                            if _take > 0 then
                                table.insert(queue, {
                                    name    = preset.name,
                                    price   = preset.price,
                                    qty     = _take,
                                    slot    = st.slot,
                                    item_id = 0,
                                })
                                _preset_left = _preset_left - _take
                            end
                        end
                    else
                        local slot = tonumber((inv.slots or ''):match('(%d+)'))
                        if slot and _preset_left > 0 then
                            table.insert(queue, {
                                name    = preset.name,
                                price   = preset.price,
                                qty     = _preset_left,
                                slot    = slot,
                                item_id = 0,
                            })
                        end
                    end
                    break
                end
            end
        end
    end

    if #queue == 0 then
        sampAddChatMessage('[MH Авто] {ff8800}Нет товаров для выставления.', 0xFFFFFF)
        return
    end

    fh_lv_autosell_running = true
    fh_lv_autosell_done    = 0
    fh_lv_autosell_status  = 'Запуск...'
    local total = #queue
    sampAddChatMessage('[MH Авто] {ffaa00}Выставляю ' .. total .. ' стаков...', 0xFFFFFF)

    lua_thread.create(function()
        for _, item in ipairs(queue) do
            if not fh_lv_autosell_running then break end
            fh_lv_autosell_status = item.name .. ' x' .. item.qty .. ' (' .. fh_lv_autosell_done .. '/' .. total .. ')'

            local json_str = '{"amount":' .. item.qty ..
                ',"id":' .. item.item_id ..
                ',"slot":' .. item.slot ..
                ',"type":1}'

            local prev_dlg_text = sampIsDialogActive() and sampGetDialogText() or ''

            _mh_flog('SELL_CLICK item=' .. item.name .. ' slot=' .. item.slot .. ' qty=' .. item.qty .. ' price=' .. item.price .. ' json=' .. json_str)
            _yzr1t(60, -1, 2, json_str)

            local dlg_text = ''
            local open_t = os.clock() + 1.5
            while os.clock() < open_t do
                wait(40)
                -- Check cached text from onShowDialog first
                if _G._mh_dlg26545_text and _G._mh_dlg26545_text ~= '' and
                   (_G._mh_dlg26545_time or 0) > (os.clock() - 2) then
                    dlg_text = _G._mh_dlg26545_text
                    _G._mh_dlg26545_text = nil
                    break
                end
                if sampIsDialogActive() and sampGetCurrentDialogId() == 26545 then
                    local cur_text = sampGetDialogText() or ''
                    if cur_text ~= '' and cur_text ~= prev_dlg_text then
                        dlg_text = cur_text
                        break
                    end
                end
            end

            _mh_flog('SELL_WAIT result: active=' .. tostring(sampIsDialogActive()) .. ' dlg_id=' .. tostring(sampIsDialogActive() and sampGetCurrentDialogId() or -1) .. ' text=[' .. dlg_text:sub(1,80) .. ']')
            if sampIsDialogActive() and sampGetCurrentDialogId() == 26545 and dlg_text ~= '' then
                local has_qty = dlg_text:find("запятую") ~= nil
                local resp = has_qty
                    and (tostring(item.qty) .. ',' .. tostring(item.price))
                    or  tostring(item.price)
                sampAddChatMessage('[MH Авто] {00cc00}' .. item.name .. ' x' .. item.qty .. ' @ $' .. tostring(item.price) .. ' slot=' .. item.slot, 0xFFFFFF)
                fh_lv_sell_confirmed = false
                fh_lv_sell_forbidden = false
                fh_lv_sell_no_slots  = false
                mh_sell_confirmed = false
                sampSendDialogResponse(26545, 1, 0, resp)
                fh_lv_autosell_done = fh_lv_autosell_done + 1
                _dsf3y(item.name, item.price, item.qty, 'sell', 'ok')
                local confirm_t = os.clock() + 3
                while not mh_sell_confirmed and os.clock() < confirm_t do wait(40) end
                if not fh_lv_sell_confirmed then
                    local extra_t = os.clock() + 1.5
                    while not fh_lv_sell_confirmed and os.clock() < extra_t do wait(30) end
                end
                sampSendDialogResponse(26545, 0, 0, '')
                if fh_lv_sell_no_slots then
                    sampAddChatMessage('[MH Авто] {ff4444}Нет свободных ячеек, останавливаю.', 0xFFFFFF)
                    fh_lv_autosell_running = false; break
                end
                wait(300)
            else
                sampAddChatMessage('[MH] {ff8800}Диалог не открылся: ' .. item.name .. ' (попытка...)', 0xFFFFFF)
                wait(350)
                if sampIsDialogActive() then
                    sampSendDialogResponse(sampGetCurrentDialogId(), 0, 0, '')
                    wait(100)
                end
                _yzr1t(60, -1, 2, json_str)
                local retry_t = os.clock() + 1.75
                local retry_text = ''
                while os.clock() < retry_t do
                    wait(30)
                    if sampIsDialogActive() and sampGetCurrentDialogId() == 26545 then
                        retry_text = sampGetDialogText() or ''
                        if retry_text ~= '' then break end
                    end
                end
                if sampIsDialogActive() and sampGetCurrentDialogId() == 26545 and retry_text ~= '' then
                    local has_qty2 = retry_text:find('запятую') ~= nil
                    local resp2 = has_qty2
                        and (tostring(item.qty) .. ',' .. tostring(item.price))
                        or  tostring(item.price)
                    sampAddChatMessage('[MH Авто] {00ff88}(retry ok) ' .. item.name .. ' x' .. item.qty .. ' @ $' .. tostring(item.price), 0xFFFFFF)
                    fh_lv_sell_confirmed = false
                    fh_lv_sell_forbidden = false
                    fh_lv_sell_no_slots  = false
                    mh_sell_confirmed = false
                    sampSendDialogResponse(26545, 1, 0, resp2)
                    fh_lv_autosell_done = fh_lv_autosell_done + 1
                    _dsf3y(item.name, item.price, item.qty, 'sell', 'retry')
                    local ct2 = os.clock() + 3
                    while not mh_sell_confirmed and os.clock() < ct2 do wait(40) end
                    sampSendDialogResponse(26545, 0, 0, '')
                    if fh_lv_sell_no_slots then
                        sampAddChatMessage('[MH Авто] {ff4444}Нет свободных ячеек, останавливаю.', 0xFFFFFF)
                        fh_lv_autosell_running = false; break
                    end
                    wait(300)
                else
                    sampAddChatMessage('[MH] {ff4444}Скип: ' .. item.name .. ' slot=' .. item.slot, 0xFFFFFF)
                    wait(200)
                end
            end

        end

        fh_lv_autosell_running = false
        fh_lv_autosell_status  = 'Готово: ' .. fh_lv_autosell_done .. '/' .. total
        sampAddChatMessage('[MH Авто] {00cc00}Выкладка: ' .. fh_lv_autosell_done .. ' стаков выложено.', 0xFFFFFF)
        fh_lv_autostart_enabled = false
        settings.general.autostart_enabled = false
        _wfn7p()
        -- Отправляем свою лавку на сервер
        _G._mh_sell_ran_session = true
        lua_thread.create(function() wait(800); mh_push_own_preset_shop() end)
    end)
end

local function _jtb4n()
    if fh_lv_autosell_running or fh_lv_autobuy_running then return end
    if #fh_lv_autobuy_preset == 0 then
        sampAddChatMessage('[FH Авто] {ff4444}Список авто-покупки пуст. Добавьте товары.', 0xFFFFFF)
        return
    end
    fh_lv_autobuy_running = true
    fh_lv_autobuy_status  = 'Запуск...'

    lua_thread.create(function()
        if #fh_mkt_lavka_ids == 0 then
            fh_lv_autobuy_status = 'Открываю лавку...'
            sampSendChat('/mm')
            local w=0
            while #fh_mkt_lavka_ids==0 and w<600 do wait(10); w=w+1 end
            if #fh_mkt_lavka_ids==0 then
                sampAddChatMessage('[FH Авто] {ff4444}Лавка не открылась!', 0xFFFFFF)
                fh_lv_autobuy_running=false
                fh_lv_autobuy_status='Лавка не доступна'
                return
            end
            wait(400)
        end

        local done, total = 0, #fh_lv_autobuy_preset
        sampAddChatMessage('[FH Авто] {ffaa00}Авто-покупка стартует: '..total..' позиций', 0xFFFFFF)

        for pi, buy_item in ipairs(fh_lv_autobuy_preset) do
            if not fh_lv_autobuy_running then break end
            fh_lv_autobuy_status = buy_item.name..' ('..pi..'/'..total..')'

            local found = false
            for _, td_id in ipairs(fh_mkt_lavka_ids) do
                if not fh_lv_autobuy_running then break end
                if sampIsDialogActive() then
                    sampSendDialogResponse(sampGetCurrentDialogId(),0,0,'')
                    wait(100)
                end
                sampSendClickTextdraw(td_id)
                wait(150)  -- give server time to process TD click
                do local _w=0 while _w<800 and not sampIsDialogActive() do wait(40);_w=_w+40 end end

                local wd, dlg_id, dlg_price = 0, nil, nil
                while wd<3000 do
                    wait(50); wd=wd+50
                    if sampIsDialogActive() then
                        local cid = sampGetCurrentDialogId()
                        local ctxt = sampGetDialogText() or ''
                        if fh_is_slot_dialog(cid) then
                            local ctitle_ab = sampGetDialogTitle() or ''
                            ctitle_ab = ctitle_ab:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
                            local slot_name = fh_get_slot_item_name(ctxt, ctitle_ab)
                            if slot_name:lower()==buy_item.name:lower() then
                                for line in ctxt:gmatch('[^\n]+') do
                                    local p=line:match('Стоимость:%s*%$([%d,%.]+)')
                                         or line:match('[Цц]ена[^%d]*([%d]+)')
                                         or line:match('%$([%d]+)')
                                    if p then dlg_price=tonumber((p:gsub('[,.]',''))); break end
                                end
                                dlg_id=cid; break
                            else
                                sampSendDialogResponse(cid,0,0,'')
                                wait(300)
                            end
                        elseif cid~=fh_mkt_lv_cur_dialog then
                            sampSendDialogResponse(cid,0,0,'')
                            wait(300)
                        end
                    end
                end

                if dlg_id then
                    if buy_item.max_price and buy_item.max_price > 0 and dlg_price and dlg_price > buy_item.max_price then
                        sampAddChatMessage('[FH Авто] {ffaa00}Пропуск: '..buy_item.name..' цена $'.._kcr3y(dlg_price)..' > макс $'.._kcr3y(buy_item.max_price), 0xFFFFFF)
                        _dsf3y(buy_item.name, dlg_price or 0, buy_item.qty or 1, 'buy', 'skip')
                        sampSendDialogResponse(dlg_id,0,0,'')
                        wait(100)
                        found=true; break
                    end
                    sampSendDialogResponse(dlg_id,1,2,'')  -- listItem 2 = Покупить
                    wait(700)

                    if sampIsDialogActive() then
                        local inp = sampGetCurrentDialogId()
                        sampSendDialogResponse(inp,1,0,tostring(buy_item.qty or 1))
                    wait(600)
                    end

                    _dsf3y(buy_item.name, dlg_price or 0, buy_item.qty or 1, 'buy', 'ok')
                    done=done+1
                    found=true
                    wait(500)
                    break
                end
            end

            if not found then
                _dsf3y(buy_item.name, 0, buy_item.qty or 1, 'buy', 'skip')
                sampAddChatMessage('[FH Авто] {ffaa00}Пропуск покупки: '..buy_item.name, 0xFFFFFF)
            end
        end

        if sampIsDialogActive() then
            sampSendDialogResponse(sampGetCurrentDialogId(),0,0,'')
            wait(100)
        end
        sampSendClickTextdraw(65535)

        fh_lv_autobuy_running=false
        fh_lv_autobuy_status='Завершµно: '..done..'/'..total
        sampAddChatMessage('[FH Авто] {00cc00}Авто-покупка завершена. Успешно: '..done..'/'..total, 0xFFFFFF)
    end)
end

local function _xpk6g()
    if fh_lv_autosell_running or fh_lv_autobuy_running then return end
    if #fh_lv_autobuy_preset == 0 then
        sampAddChatMessage('[MH \xc0\xe2\xf2\xee] {ff4444}\xcf\xf0\xe5\xf1\xe5\xf2 \xf1\xea\xf3\xef\xe0 \xef\xf3\xf1\xf2.', 0xFFFFFF); return
    end
    fh_lv_autobuy_running = true
    fh_ab_search_idx      = 1
    fh_lv_autobuy_status  = '\xc7\xe0\xef\xf3\xf1\xea...'
    local total = #fh_lv_autobuy_preset
    sampAddChatMessage('[MH \xc0\xe2\xf2\xee] {ffaa00}\xc0\xe2\xf2\xee-\xf1\xea\xf3\xef\xea\xe0: ' .. total .. ' \xf2\xee\xe2\xe0\xf0\xee\xe2...', 0xFFFFFF)

    local function wait_dlg(ids, ms)
        local el = 0
        while el < ms do
            wait(30); el = el + 30
            if _G.mh_ab_caught_dlg then
                local c = _G.mh_ab_caught_dlg
                if ids == nil then _G.mh_ab_caught_dlg = nil; return c end
                for _, id in ipairs(ids) do
                    if c == id then _G.mh_ab_caught_dlg = nil; return c end
                end
            end
            if sampIsDialogActive() then
                local c = sampGetCurrentDialogId()
                if ids == nil then return c end
                for _, id in ipairs(ids) do
                    if c == id then return c end
                end
            end
        end
        return nil
    end

    local function close_dlg()
        _G.mh_ab_caught_dlg = nil
        if sampIsDialogActive() then
            sampSendDialogResponse(sampGetCurrentDialogId(), 0, 0, '')
            wait(200)
        end
    end

    local function open_shop_menu()
        close_dlg()
        _yzr1t(8, 7, -1, '')
        local d = wait_dlg({3040}, 2500)
        _mh_flog('AB open_menu dlg=' .. tostring(d))
        return d
    end

    lua_thread.create(function()
        if not open_shop_menu() then
            sampAddChatMessage('[MH] {ff4444}\xcb\xe0\xe2\xea\xe0 \xed\xe5 \xee\xf2\xea\xf0\xfb\xeb\xe0\xf1\xfc!', 0xFFFFFF)
            fh_lv_autobuy_running = false; return
        end

        for pi = 1, total do
            if not fh_lv_autobuy_running then break end
            local buy_item = fh_lv_autobuy_preset[pi]
            if not buy_item then break end
            fh_ab_search_idx     = pi
            fh_lv_autobuy_status = buy_item.name .. ' (' .. pi .. '/' .. total .. ')'
            local search_str = buy_item.search or buy_item.name:sub(1, 24)
            local dlg = nil  -- объявляем заранее чтобы goto не прыгал чхрез local

            -- \xd8\xe0\xe3 1: \xe2 \xec\xe5\xed\xfe 3040 \xe2\xfb\xe1\xe8\xf0\xe0\xe5\xec \xef\xf3\xed\xea\xf2 3 (\xe8\xed\xe4\xe5\xea\xf1 2) = \xc4\xee\xe1\xe0\xe2\xe8\xf2\xfc \xed\xe0 \xf1\xea\xf3\xef\xea\xf3 (\xef\xee\xe8\xf1\xea)
            if not sampIsDialogActive() or sampGetCurrentDialogId() ~= 3040 then
                if not open_shop_menu() then
                    sampAddChatMessage('[MH] {ff8800}\xd0\xe5\xec\xee\xed\xf2\xed\xee \xed\xe0\xf8\xb8\xeb ' .. buy_item.name, 0xFFFFFF)
                    goto next_item
                end
            end
            wait(100)  -- пауза перед кликом (диалог должен быть готов)
            _G.mh_ab_caught_dlg = nil  -- сброс ПОСЛЕ проверки диалога, ДО отправки
            sampSendDialogResponse(3040, 1, 2, '')

            -- Шаг 2: ждём поисковый диалог 25665 (с повтором если сервер тормозит)
            dlg = wait_dlg({25665}, 3000)
            _mh_flog('AB s2 dlg=' .. tostring(dlg))
            if not dlg then
                -- Повтор: переоткрываем меню и пробуем ещё раз
                _mh_flog('AB s2 retry')
                if not open_shop_menu() then goto next_item end
                wait(150)
                _G.mh_ab_caught_dlg = nil
                sampSendDialogResponse(3040, 1, 2, '')
                dlg = wait_dlg({25665}, 4000)
                _mh_flog('AB s2 retry dlg=' .. tostring(dlg))
                if not dlg then
                    sampAddChatMessage('[MH] {ff4444}\xd1\xf2\xf0\xee\xea\xe0 \xef\xee\xe8\xf1\xea\xe0 \xed\xe5 \xee\xf2\xea\xf0\xfb\xeb\xe0\xf1\xfc: ' .. buy_item.name, 0xFFFFFF)
                    goto next_item
                end
            end
            wait(200)
            _G.mh_ab_caught_dlg = nil
            sampSendDialogResponse(25665, 1, 0, search_str)

            -- \xd8\xe0\xe3 3: \xe2\xfb\xe1\xe8\xf0\xe0\xe5\xec \xf2\xee\xe2\xe0\xf0 \xe8\xe7 \xf1\xef\xe8\xf1\xea\xe0 25666
            dlg = wait_dlg({25666}, 3000)
            _mh_flog('AB s3 dlg=' .. tostring(dlg))
            if not dlg then
                sampAddChatMessage('[MH] {ff8800}\xd0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2\xee\xe2 \xed\xe5\xf2: ' .. buy_item.name, 0xFFFFFF)
                goto next_item
            end
            do
                local list_text = sampGetDialogText() or ''
                local bnl = buy_item.name:lower()
                local found_idx = nil
                local fi = 0
                for line in list_text:gmatch('[^\n]+') do
                    local nm = line:gsub('{[^}]+}',''):match('^%d+[%.%)%s]+(.-)%s*$')
                             or line:gsub('{[^}]+}',''):match('^%s*(.-)%s*$')
                    if nm and nm:lower():find(bnl, 1, true) then
                        found_idx = fi; break
                    end
                    fi = fi + 1
                end
                if found_idx == nil then
                    local fw = bnl:match('^(%S+)')
                    if fw and #fw >= 4 then
                        fi = 0
                        for line in list_text:gmatch('[^\n]+') do
                            if line:gsub('{[^}]+}',''):lower():find(fw, 1, true) then
                                found_idx = fi; break
                            end
                            fi = fi + 1
                        end
                    end
                end
                _mh_flog('AB s3 found=' .. tostring(found_idx) .. ' item=' .. buy_item.name)
                if found_idx ~= nil then
                    _G.mh_ab_caught_dlg = nil
                    sampSendDialogResponse(25666, 1, found_idx, '')
                else
                    sampAddChatMessage('[MH] {ff8800}\xcd\xe5 \xed\xe0\xf8\xb8\xeb: ' .. buy_item.name, 0xFFFFFF)
                    sampSendDialogResponse(25666, 0, 0, '')
                    goto next_item
                end
            end

            -- \xd8\xe0\xe3 4: \xe4\xe8\xe0\xeb\xee\xe3 \xf6\xe5\xed\xfb / \xef\xee\xe4\xf2\xe2\xe5\xf0\xe6\xe4\xe5\xed\xe8\xff
            dlg = wait_dlg({26558, 26560, 26561, 26563, 3060}, 3000)
            _mh_flog('AB s4 dlg=' .. tostring(dlg))
            if not dlg then
                sampAddChatMessage('[MH] {ff4444}\xc4\xe8\xe0\xeb\xee\xe3 \xf6\xe5\xed\xfb \xed\xe5 \xef\xee\xff\xe2\xe8\xeb\xf1\xff: ' .. buy_item.name, 0xFFFFFF)
                goto next_item
            end
            if dlg == 26558 or dlg == 26560 then
                _G.mh_ab_caught_dlg = nil
                sampSendDialogResponse(dlg, 1, 0, '')
                dlg = wait_dlg({26561, 26563, 3060}, 2000)
                _mh_flog('AB s4b dlg=' .. tostring(dlg))
            end
            if dlg == 26561 or dlg == 26563 or dlg == 3060 then
                if not sampIsDialogActive() then goto next_item end
                local txt = sampGetDialogText() or ''
                local has_qty = txt:find('\xcf\xf0\xe8\xec\xe5\xf0:') ~= nil  -- \'\xcf\xf0\xe8\xec\xe5\xf0:\' Есть только для обычных товаров, не для авто-товаров
                local _ab_qty = buy_item.qty or 1
                local _ab_price = buy_item.max_price or 0
                if has_qty then
                    -- Обычный товар: вводим qty,price одной командой
                    local resp = tostring(_ab_qty) .. ',' .. tostring(_ab_price)
                    sampAddChatMessage('[MH \xc0\xe2\xf2\xee] {00cc00}\xd1\xea\xf3\xef: ' .. buy_item.name .. ' x' .. _ab_qty .. ' -> ' .. resp, 0xFFFFFF)
                    _G.mh_ab_caught_dlg = nil
                    sampSendDialogResponse(dlg, 1, 0, resp)
                    _dsf3y(buy_item.name, _ab_price, _ab_qty, 'buy', 'ok')
                    wait(500)
                else
                    -- Авто-товар (sport+): вводим только price, повторяем qty раз
                    for _ab_i = 1, _ab_qty do
                        if not fh_lv_autobuy_running then break end
                        if _ab_i > 1 then
                            -- Реоткрыть меню и заново пройти весь поиск для следующего экземпляра
                            wait(800)
                            close_dlg()
                            wait(500)
                            if not open_shop_menu() then break end
                            wait(200)
                            _G.mh_ab_caught_dlg = nil
                            sampSendDialogResponse(3040, 1, 2, '')
                            dlg = wait_dlg({25665}, 4000)
                            if not dlg then break end
                            wait(300)
                            _G.mh_ab_caught_dlg = nil
                            sampSendDialogResponse(25665, 1, 0, search_str)
                            dlg = wait_dlg({25666}, 4000)
                            if not dlg then break end
                            wait(200)
                            do
                                local _lt = sampGetDialogText() or ''
                                local _bnl = buy_item.name:lower()
                                local _fidx = nil
                                local _fi = 0
                                for _line in _lt:gmatch('[^\n]+') do
                                    local _nm = _line:gsub('{[^}]+}',''):match('^%d+[%.%)%s]+(.-)%s*$')
                                             or _line:gsub('{[^}]+}',''):match('^%s*(.-)%s*$')
                                    if _nm and _nm:lower():find(_bnl, 1, true) then
                                        _fidx = _fi; break
                                    end
                                    _fi = _fi + 1
                                end
                                if _fidx == nil then
                                    sampSendDialogResponse(25666, 0, 0, '')
                                    break
                                end
                                _G.mh_ab_caught_dlg = nil
                                sampSendDialogResponse(25666, 1, _fidx, '')
                            end
                            dlg = wait_dlg({26558, 26560, 26561, 26563, 3060}, 4000)
                            if not dlg then break end
                            if dlg == 26558 or dlg == 26560 then
                                _G.mh_ab_caught_dlg = nil
                                sampSendDialogResponse(dlg, 1, 0, '')
                                dlg = wait_dlg({26561, 26563, 3060}, 3000)
                                if not dlg then break end
                            end
                            if not sampIsDialogActive() then break end
                        end
                        sampAddChatMessage('[MH \xc0\xe2\xf2\xee] {00cc00}\xd1\xea\xf3\xef \xf8\xf2 ' .. _ab_i .. '/' .. _ab_qty .. ': ' .. buy_item.name .. ' -> ' .. tostring(_ab_price), 0xFFFFFF)
                        _G.mh_ab_caught_dlg = nil
                        sampSendDialogResponse(dlg, 1, 0, tostring(_ab_price))
                        _dsf3y(buy_item.name, _ab_price, 1, 'buy', 'ok')
                        wait(600)
                    end
                end
            end

            ::next_item::
            close_dlg()
            if pi < total and fh_lv_autobuy_running then
                open_shop_menu()
                wait(100)
            end
        end

        close_dlg()
        fh_lv_autobuy_running = false
        fh_lv_autobuy_status  = '\xc3\xee\xf2\xee\xe2\xee'
        sampAddChatMessage('[MH \xc0\xe2\xf2\xee] {00cc00}\xc0\xe2\xf2\xee-\xf1\xea\xf3\xef\xea\xe0 \xe7\xe0\xe2\xe5\xf0\xf8\xe5\xed\xe0.', 0xFFFFFF)
        _G._mh_buy_ran_session = true
        lua_thread.create(function() wait(800); mh_push_own_preset_shop() end)
    end)
end

local function fh_mkt_run_lavka_scan()
    if fh_mkt_lv_scanning then return end
    fh_mkt_lv_scanning = true
    lua_thread.create(function()
        if #fh_mkt_lavka_ids == 0 then
            sampAddChatMessage('[FH Market] {ffaa00}Открываю лавку...', 0xFFFFFF)
            fh_mkt_lavka_ids = {}; fh_mkt_lavka_sep = {}
            fh_mkt_lavka_slot_w = nil; fh_mkt_lavka_slot_h = nil
            sampSendChat('/mm')
            local waited = 0
            while #fh_mkt_lavka_ids == 0 and waited < 500 do
                wait(10); waited = waited + 1
            end
            if #fh_mkt_lavka_ids == 0 then
                sampAddChatMessage('[FH Market] {ff4444}Лавка не открылась. Подойдите к прилавке и повторите.', 0xFFFFFF)
                fh_mkt_lv_scanning = false; return
            end
            wait(500) -- доп. задержка после открытия
        end
        local ids_snap = {}
        for _,v in ipairs(fh_mkt_lavka_ids) do table.insert(ids_snap, v) end
        fh_mkt_lv_done = 0; fh_mkt_lv_total = #ids_snap
        sampAddChatMessage('[FH Market] {ffaa00}Сканирую лавку... Слотов: ' .. #ids_snap, 0xFFFFFF)
        for _, td_id in ipairs(ids_snap) do
            if not fh_mkt_lv_scanning then break end -- остановка
            local snap = fh_mkt_lv_done
            if sampIsDialogActive() then
                sampSendDialogResponse(sampGetCurrentDialogId(), 0, 0, '')
                wait(80)
            end
            sampSendClickTextdraw(td_id)
            local w = 0
            while fh_mkt_lv_done == snap and w < 400 do wait(10); w = w + 1 end
            wait(50)
        end
        if sampIsDialogActive() then
            sampSendDialogResponse(sampGetCurrentDialogId(), 0, 0, '')
        end
        sampSendClickTextdraw(65535)
        wait(100)
        fh_mkt_lv_scanning = false; _ryb5t(); _kyb5x()
        -- После скана сразу загружаем суточные данные (сбрасываем таймер)
        _G._mh_daily_push_last = 0
        lua_thread.create(function() wait(500); _mh_upload_daily_prices() end)
        local tot = 0; for _ in pairs(fh_mkt_lavka) do tot = tot + 1 end
        sampAddChatMessage('[FH Market] {00cc00}Скан лавки завершён. Товаров: '..tot, 0xFFFFFF)
    end)
end

if not _G.mkt_detail_open  then _G.mkt_detail_open  = false end
if not _G.mkt_detail_item  then _G.mkt_detail_item  = '' end
if not _G.mkt_detail_src   then _G.mkt_detail_src   = 'cp' end
if not _G.mkt_cp_page      then _G.mkt_cp_page      = 1 end
if not _G.mkt_lv_page      then _G.mkt_lv_page      = 1 end
local MKT_PAGE_SIZE = 50

local SPARK_CHARS = {'.', ',', '_', '-', '=', '~', '+', '#'}

local function fh_spark(history, max_days)
    max_days = max_days or 10
    if not history or #history == 0 then return '—' end
    local slice = {}
    for i = math.min(#history, max_days), 1, -1 do
        table.insert(slice, history[i].price or 0)
    end
    if #slice == 0 then return '—' end
    local mn, mx = slice[1], slice[1]
    for _, v in ipairs(slice) do
        if v < mn then mn = v end
        if v > mx then mx = v end
    end
    local range = mx - mn
    local result = ''
    for _, v in ipairs(slice) do
        local idx = 1
        if range > 0 then
            idx = math.floor((v - mn) / range * 7) + 1
        else
            idx = 4
        end
        result = result .. SPARK_CHARS[idx]
    end
    return result
end

-- Фильтрация выбросов по IQR: убирает точки далеко от медианы
-- ext_anchor (опц.): внешняя цена-якорь (напр. средняя цена лавок). Используется
-- когда в выборке слишком мало точек, чтобы доверять внутренней медиане.

-- Кеш статистики (s7/s30/s1/trend) по таблице history.
-- Ключ — сама таблица (weak), сбрасывается при смене длины или элемента [1].
-- Это убирает 4 sort-вызова на каждую строку списка рынка на каждом кадре.
local _stats_cache = setmetatable({}, {__mode='k'})
local function _cached_stats(hist, anchor)
    if not hist or #hist == 0 then return nil, nil, nil, nil end
    local n = #hist
    local h1 = hist[1]
    local c = _stats_cache[hist]
    if c and c.n == n and c.h1 == h1 and c.anchor == anchor then
        return c.s7, c.s30, c.s1, c.trend
    end
    local s7  = _mjg5t(hist, 7,  anchor)
    local s30 = _mjg5t(hist, 30, anchor)
    local s1  = _mjg5t(hist, 1,  anchor)
    local trend = _xvn2w(hist)
    _stats_cache[hist] = {n=n, h1=h1, anchor=anchor, s7=s7, s30=s30, s1=s1, trend=trend}
    return s7, s30, s1, trend
end

-- Формат цены как в игре: КК 2, К 6.720, М 2.5, $236
local function _fmt_price_arz(n)
    if not n or n <= 0 then return '$0' end
    n = math.floor(n)
    if n >= 1000000000 then
        -- Миллиарды: М N КК N К N
        local m   = math.floor(n / 1000000000)
        local rem = n % 1000000000
        local kk  = math.floor(rem / 1000000)
        local k   = rem % 1000000
        local s   = 'М ' .. tostring(m)
        if kk > 0 then s = s .. ' КК ' .. tostring(kk) end
        if k > 0 then
            local kw = math.floor(k/1000); local kr = k%1000
            s = s .. ' К ' .. tostring(kw) .. '.' .. string.format('%03d',kr)
        end
        return s
    elseif n >= 1000000 then
        -- Миллионы: КК N К N
        local kk  = math.floor(n / 1000000)
        local rem = n % 1000000
        local s   = 'КК ' .. tostring(kk)
        if rem > 0 then
            -- Показываем остаток в формате К X.YYY (как в ARP)
            local kw = math.floor(rem/1000); local kr = rem%1000
            s = s .. ' К ' .. tostring(kw) .. '.' .. string.format('%03d',kr)
        end
        return s
    elseif n >= 1000 then
        -- Тысячи: К N.NNN
        local whole = math.floor(n / 1000)
        local rem   = n % 1000
        if rem == 0 then
            return 'К ' .. tostring(whole) .. '.000'
        else
            return 'К ' .. tostring(whole) .. '.' .. string.format('%03d', rem)
        end
    else
        return '$' .. tostring(n)
    end
end


local function _hmc6p(item_name, src)
    local d  = settings.general.custom_dpi
    local ar = settings.interface.accent_r or 1
    local ag = settings.interface.accent_g or .65
    local ab = settings.interface.accent_b or 0.0
    local sb_r = settings.interface.sell_btn_r or 0.10
    local sb_g = settings.interface.sell_btn_g or 0.45
    local sb_b = settings.interface.sell_btn_b or 0.10
    local bb_r = settings.interface.buy_btn_r  or 0.00
    local bb_g = settings.interface.buy_btn_g  or 0.28
    local bb_b = settings.interface.buy_btn_b  or 0.50
    local lp_r = settings.overlay and settings.overlay.log_price_r or 1.0
    local lp_g = settings.overlay and settings.overlay.log_price_g or 0.85
    local lp_b = settings.overlay and settings.overlay.log_price_b or 0.2
    -- fa icon cache (anti stack-overflow)
    local _ic_up    = fa.ARROW_UP;      local _ic_dn     = fa.ARROW_DOWN
    local _ic_al    = fa.ANGLE_LEFT
    local _ic_ban   = fa.BAN;           local _ic_bolt   = fa.BOLT
    local _ic_cart  = fa.CART_SHOPPING; local _ic_chk    = fa.CHECK
    local _ic_circ  = fa.CIRCLE;        local _ic_circp  = fa.CIRCLE_PLUS
    local _ic_circs = fa.CIRCLE_STOP;   local _ic_coin   = fa.COINS
    local _ic_eye   = fa.EYE;           local _ic_flt    = fa.FILTER
    local _ic_save  = fa.FLOPPY_DISK;   local _ic_min    = fa.MINUS
    local _ic_pen   = fa.PEN_TO_SQUARE; local _ic_rot    = fa.ROTATE_RIGHT
    local _ic_scl   = fa.SCALE_BALANCED; local _ic_star  = fa.STAR
    local _ic_store = fa.STORE;         local _ic_tag    = fa.TAG
    local _ic_trash = fa.TRASH_CAN;     local _ic_warn   = fa.TRIANGLE_EXCLAMATION
    local _ic_wh    = fa.WAREHOUSE;     local _ic_x      = fa.XMARK
    local _ic_extlink = fa.ARROW_UP_RIGHT_FROM_SQUARE
    local _ic_key   = fa.KEY;           local _ic_play   = fa.PLAY
    local _ic_shield= fa.SHIELD_HALVED; local _ic_spin   = fa.SPINNER
    -- also shared with _qbs9k cache names:
    local _ic_clk   = fa.CLOCK;         local _ic_phone  = fa.PHONE
    local _ic_gps   = fa.CROSSHAIRS;    local _ic_srch   = fa.MAGNIFYING_GLASS
    local _ic_gear  = fa.GEAR;          local _ic_cld    = fa.CLOUD
    local _ic_chrtl = fa.CHART_LINE;    local _ic_chrts  = fa.CHART_SIMPLE
    local _ic_calds = fa.CALENDAR_DAYS; local _ic_cald   = fa.CALENDAR_DAY
    local _ic_calw  = fa.CALENDAR_WEEK; local _ic_cal    = fa.CALENDAR
    local _ic_dl    = fa.DOWNLOAD;      local _ic_ul     = fa.UPLOAD
    local _ic_fimp  = fa.FILE_IMPORT;   local _ic_lyr    = fa.LAYER_GROUP
    local _ic_map   = fa.MAP_LOCATION_DOT; local _ic_mgnt = fa.MAGNET
    local _ic_paus  = fa.PAUSE;         local _ic_lxh    = fa.LOCATION_CROSSHAIRS
    local _ic_ll    = fa.ANGLES_LEFT;   local _ic_rr     = fa.ANGLES_RIGHT
    local _ic_ar    = fa.ANGLE_RIGHT;   local _ic_lt     = fa.ARROW_LEFT
    local _ic_rt    = fa.ARROW_RIGHT;   local _ic_alr    = fa.ARROWS_LEFT_RIGHT
    local _ic_circc = fa.CIRCLE_CHECK;  local _ic_circi  = fa.CIRCLE_INFO
    local _ic_boxes = fa.BOXES_STACKED; local _ic_arch   = fa.BOX_ARCHIVE
    local _ic_car   = fa.CAR;           local _ic_chk2   = fa.CHECK
    local _ic_x2    = fa.XMARK

    local ac = imgui.ImVec4(ar, ag, ab, 1)

    local cp_e   = fh_mkt_prices[item_name]
    local lv_e   = fh_mkt_lavka[item_name]
    local cp_hist = (cp_e and cp_e.cp_hist) or {}  -- защита от nil

    if not _G.dtl_tab then _G.dtl_tab = imgui.new.int(0) end
    local _dtl_cur_srv = _G.arz_srv_sel and _G.arz_srv_sel[0] or -1
    -- Убрали #mh_arz_data из ключа: лавки меняются часто и вызывали пересчёт каждый кадр
    -- Пересчёт триггерится вручную через _dtl_cache_nm = nil (при pull/push)
    local _dtl_cache_key = item_name .. '|' .. tostring(_dtl_cur_srv)
    if _G._dtl_cache_nm ~= _dtl_cache_key then
        _G._dtl_cache_nm = _dtl_cache_key
        local _nm_lo = item_name:lower()
        local _sr, _br = {}, {}
        _G._dtl_shop_hist = fh_get_daily_shop_history(item_name)
        -- При открытии карточки: если кэш deals устарел (>10 мин) — обновляем
        if not _G._mh_deals_pull_ts or (os.time() - _G._mh_deals_pull_ts) > 600 then
            _G._mh_deals_pull_ts = os.time()
            _mh_deals_pull(true)
            -- Заодно пушим свои данные если они ещё не залиты
            _mh_upload_deals()
        end
        -- Дополняем _dtl_shop_hist данными из fh_mkt_log (местные сделки)
        do
            local _nm_lo_log = item_name:lower()
            -- Буфер: {["YYYY-MM-DD"] = {sP=0, sC=0, bP=0, bC=0}}
            local _log_days = {}
            for _, _le in ipairs(fh_mkt_log) do
                if _le and _le.item and _le.item:lower() == _nm_lo_log and _le.price and _le.price > 0 then
                    -- dt формат "DD.MM HH:MM", нам нужно "YYYY-MM-DD"
                    local _dm = _le.dt and _le.dt:match('^(%d%d)%.(%d%d)')
                    local _day_d, _day_m
                    if _le.dt then _day_d, _day_m = _le.dt:match('^(%d%d)%.(%d%d)') end
                    local _day_key
                    if _day_d and _day_m then
                        local _yr = os.date('%Y')
                        _day_key = _yr..'-'.._day_m..'-'.._day_d
                    end
                    if _day_key then
                        if not _log_days[_day_key] then _log_days[_day_key] = {sP=0,sC=0,bP=0,bC=0,bMax=0,sMin=math.huge} end
                        local _q = _le.qty or 1
                        local _is_sell = (_le.op == 'SELL') or (_le.op == 'sell')
                        if _is_sell then
                            _log_days[_day_key].sP = _log_days[_day_key].sP + _le.price * _q
                            _log_days[_day_key].sC = _log_days[_day_key].sC + _q
                            if _le.price < _log_days[_day_key].sMin then _log_days[_day_key].sMin = _le.price end
                        else
                            _log_days[_day_key].bP = _log_days[_day_key].bP + _le.price * _q
                            _log_days[_day_key].bC = _log_days[_day_key].bC + _q
                            if _le.price > _log_days[_day_key].bMax then _log_days[_day_key].bMax = _le.price end
                        end
                    end
                end
            end
            -- Мерж в _dtl_shop_hist: если дата есть в обоих сточниках — берём макс. Если только в логе — добавляем
            local _sh_idx = {}
            for _i, _e in ipairs(_G._dtl_shop_hist) do _sh_idx[_e.date] = _i end
            for _dk, _dv in pairs(_log_days) do
                local _log_s    = _dv.sC > 0 and math.floor(_dv.sP / _dv.sC) or nil
                local _log_sMin = _dv.sMin and _dv.sMin < math.huge and _dv.sMin or nil
                local _log_b    = _dv.bC > 0 and math.floor(_dv.bP / _dv.bC) or nil
                local _log_bMax = _dv.bMax and _dv.bMax > 0 and _dv.bMax or nil
                local _ei = _sh_idx[_dk]
                if _ei then
                    local _e = _G._dtl_shop_hist[_ei]
                    if _log_s and not _e.s_avg then
                        _e.s_avg = _log_s; _e.s_src = 'log'
                    end
                    if _log_sMin and (not _e.s_min or _log_sMin < _e.s_min) then
                        _e.s_min = _log_sMin
                    end
                    if _log_b and not _e.b_avg then
                        _e.b_avg = _log_b; _e.b_src = 'log'
                    end
                    if _log_bMax and (not _e.b_max or _log_bMax > _e.b_max) then
                        _e.b_max = _log_bMax
                    end
                else
                    if _log_s or _log_b then
                        table.insert(_G._dtl_shop_hist, {
                            date=_dk, s_avg=_log_s, s_min=_log_sMin,
                            b_avg=_log_b, b_max=_log_bMax,
                            s_src='log', b_src='log'
                        })
                    end
                end
            end
            -- Сортируем по дате убывающим
            table.sort(_G._dtl_shop_hist, function(a,b) return a.date > b.date end)
        end
        -- Merge cloud deals into _dtl_shop_hist
        do
            -- src='deep'->sh.deep_price (scan ЦР другого игрока -> Рынок $)
            -- src='log' ->sh.deal_s/deal_b (реальные сделки -> Рынок $)
            -- s_avg/b_avg остаются только для цен лавок -> Продажа/Скупка
            local _cloud_h = (_G._mh_deals_cache or {})[item_name:lower()] or {}
            local _sh_idx2 = {}
            for _i,_e in ipairs(_G._dtl_shop_hist) do _sh_idx2[_e.date]=_i end
            for _, cd in ipairs(_cloud_h) do
                local dt  = cd.date or ''
                local src = cd.src  or 'log'
                if dt == '' then goto _cloud_merge_next end
                local ei = _sh_idx2[dt]
                local sh
                if ei then
                    sh = _G._dtl_shop_hist[ei]
                else
                    sh = {date=dt}
                    table.insert(_G._dtl_shop_hist, sh)
                    _sh_idx2[dt] = #_G._dtl_shop_hist
                end
                if src == 'deep' then
                    if (cd.s_avg or 0)>0 and not sh.deep_price then sh.deep_price=cd.s_avg end
                else
                    if (cd.s_avg or 0)>0 and not sh.deal_s then
                        sh.deal_s=cd.s_avg; sh.deal_s_qty=(cd.s_qty or cd.total_qty or 0)
                    end
                    if (cd.b_avg or 0)>0 and not sh.deal_b then
                        sh.deal_b=cd.b_avg; sh.deal_b_qty=(cd.b_qty or cd.total_qty or 0)
                    end
                end
                ::_cloud_merge_next::
            end
            if #_cloud_h > 0 then
                table.sort(_G._dtl_shop_hist, function(a,b) return a.date > b.date end)
            end
        end
        -- Merge cloud daily shop prices (от других игроков) в _dtl_shop_hist
        -- Это данные из /daily/pull — цены продажи/скупки в лавках по дням, собранные несколькими игроками
        do
            local _cd_srv = _G._mh_daily_cache_srv or -1
            local _cur_sid = _mh_get_srv_id and _mh_get_srv_id() or -1
            local _daily_h = (_cd_srv == _cur_sid or _cur_sid == -1)
                and ((_G._mh_daily_cache or {})[item_name:lower()] or {})
                or {}
            if #_daily_h > 0 then
                local _sh_idx3 = {}
                for _i, _e in ipairs(_G._dtl_shop_hist) do _sh_idx3[_e.date] = _i end
                for _, dh in ipairs(_daily_h) do
                    local dt  = dh.date or ''
                    if dt == '' then goto _daily_merge_next end
                    local ei = _sh_idx3[dt]
                    local sh
                    if ei then
                        sh = _G._dtl_shop_hist[ei]
                    else
                        sh = {date=dt}
                        table.insert(_G._dtl_shop_hist, sh)
                        _sh_idx3[dt] = #_G._dtl_shop_hist
                    end
                    -- s_avg (Продажа): берём облако если локальных данных нет
                    -- или если вклад игроков больше (contrib > 1 = несколько игроков)
                    local cloud_s = (dh.s_avg or 0) > 0 and dh.s_avg or nil
                    local cloud_b = (dh.b_avg or 0) > 0 and dh.b_avg or nil
                    local cloud_contrib = dh.contrib or 1
                    if cloud_s then
                        if not sh.s_avg then
                            sh.s_avg = cloud_s
                            sh.s_cnt = dh.s_cnt or 0
                            sh.s_src = cloud_contrib > 1 and 'cloud+'..cloud_contrib or 'cloud'
                        elseif cloud_contrib > 1 then
                            -- Несколько игроков -> weighted average с нашими данными
                            local loc_cnt = sh.s_cnt or 0
                            local cld_cnt = dh.s_cnt or 0
                            if loc_cnt > 0 and cld_cnt > 0 then
                                sh.s_avg = math.floor((sh.s_avg * loc_cnt + cloud_s * cld_cnt) / (loc_cnt + cld_cnt))
                                sh.s_cnt = loc_cnt + cld_cnt
                            end
                            sh.s_src = 'cloud+'..cloud_contrib
                        end
                    end
                    if cloud_b then
                        if not sh.b_avg then
                            sh.b_avg = cloud_b
                            sh.b_cnt = dh.b_cnt or 0
                            sh.b_src = cloud_contrib > 1 and 'cloud+'..cloud_contrib or 'cloud'
                        elseif cloud_contrib > 1 then
                            local loc_cnt = sh.b_cnt or 0
                            local cld_cnt = dh.b_cnt or 0
                            if loc_cnt > 0 and cld_cnt > 0 then
                                sh.b_avg = math.floor((sh.b_avg * loc_cnt + cloud_b * cld_cnt) / (loc_cnt + cld_cnt))
                                sh.b_cnt = loc_cnt + cld_cnt
                            end
                            sh.b_src = 'cloud+'..cloud_contrib
                        end
                    end
                    ::_daily_merge_next::
                end
                table.sort(_G._dtl_shop_hist, function(a,b) return a.date > b.date end)
            end
            -- Триггер: если daily_cache устарел >30 мин — тихо обновляем
            if not _G._mh_daily_pull_last or (os.time() - (_G._mh_daily_pull_last or 0)) > 1800 then
                lua_thread.create(function() wait(200); _mh_daily_pull(true) end)
            end
        end
        local _dtl_cur_srv_id = (ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1] or {}).id or -1
        for _, sh in pairs(fh_other_shops) do
            if type(sh) ~= 'table' then goto _dtl_sh_next end
            if _dtl_cur_srv_id ~= -1 and sh.server_id and sh.server_id ~= -1 and sh.server_id ~= _dtl_cur_srv_id then goto _dtl_sh_next end
            for _, si in ipairs(sh.sell_items or {}) do
                if type(si.name)=='string' and si.name:lower()==_nm_lo and si.price and si.price>0 then
                    table.insert(_sr, {price=si.price, owner=sh.owner or '?', qty=si.qty, src=''})
                end
            end
            for _, bi in ipairs(sh.buy_items or {}) do
                if type(bi.name)=='string' and bi.name:lower()==_nm_lo and bi.price and bi.price>0 then
                    table.insert(_br, {price=bi.price, owner=sh.owner or '?', qty=bi.qty, src=''})
                end
            end
            ::_dtl_sh_next::
        end
        if mh_arz_data and mh_arz_items_db then
            local _ui_srv = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1]
            local _ui_srv_id = _ui_srv and _ui_srv.id or -1
            local _dtl_srv_id = _ui_srv_id
            if _dtl_srv_id == -1 then
                local _auto_idx = _mpf7d()
                local _auto_srv = ARZ_SERVERS[_auto_idx + 1]
                _dtl_srv_id = _auto_srv and _auto_srv.id or -1
            end
            local _dtl_owners_seen = {}
            for _, _r in ipairs(_sr) do
                if _r.owner then _dtl_owners_seen[_r.owner:lower()] = true end
            end
            for _, lv in ipairs(mh_arz_data) do
                if type(lv)=='table' then
                    if _dtl_srv_id ~= -1 and lv.serverId ~= _dtl_srv_id then goto _dtl_api_next end
                    local _lv_own_lo = (lv.username or '?'):lower()
                    if _dtl_owners_seen[_lv_own_lo] then goto _dtl_api_next end
                    local owner = lv.username or '?'
                    if lv.items_sell and lv.price_sell then
                        for ii, iid in ipairs(lv.items_sell) do
                            local nm2 = mh_arz_items_db[_bqs3v(iid)]
                            if nm2 and nm2:lower()==_nm_lo then
                                local pr = lv.price_sell[ii]
                                if pr and pr>0 then table.insert(_sr, {price=pr, owner=owner, qty=lv.count_sell and lv.count_sell[ii], src='[API]'}) end
                            end
                        end
                    end
                    if lv.items_buy and lv.price_buy then
                        for ii, iid in ipairs(lv.items_buy) do
                            local nm2 = mh_arz_items_db[_bqs3v(iid)]
                            if nm2 and nm2:lower()==_nm_lo then
                                local pr = lv.price_buy[ii]
                                if pr and pr>0 then table.insert(_br, {price=pr, owner=owner, qty=lv.count_buy and lv.count_buy[ii], src='[API]'}) end
                            end
                        end
                    end
                    ::_dtl_api_next::
                end
            end
        end
        table.sort(_sr, function(a,b) return a.price < b.price end)
        table.sort(_br, function(a,b) return a.price > b.price end)
        _G._dtl_sell_rows = _sr
        _G._dtl_buy_rows  = _br
    end
    local sell_rows = _G._dtl_sell_rows or {}
    local buy_rows  = _G._dtl_buy_rows  or {}

    imgui.TextColored(ac, _cyr5f('Товар: ' .. item_name))
    local _hdr_date = (cp_e and cp_e.date)
                   or (lv_e and lv_e.date)
    if not _hdr_date then
        local _nm_lo_hdr = item_name:lower()
        for _, _sh_hdr in pairs(fh_other_shops) do
            local _has = false
            for _, _si in ipairs(_sh_hdr.sell_items or {}) do
                if type(_si.name)=='string' and _si.name:lower()==_nm_lo_hdr then _has=true; break end
            end
            if not _has then
                for _, _bi in ipairs(_sh_hdr.buy_items or {}) do
                    if type(_bi.name)=='string' and _bi.name:lower()==_nm_lo_hdr then _has=true; break end
                end
            end
            if _has and _sh_hdr.dt then _hdr_date = 'скан лавки ' .. _sh_hdr.dt; break end
        end
    end
    if _hdr_date then
        imgui.SameLine(); imgui.TextDisabled(_cyr5f('  обновлено ' .. _hdr_date))
    end
    imgui.Spacing()









































    if not _G.dtl_tab then _G.dtl_tab = imgui.new.int(0) end
    _G.dtl_tab[0] = 1  -- Лавки вкладка всегда активна (для совместимости)
    imgui.Spacing()

    do -- stats block (cp_hist or mkt_prices or shop_hist)
    local _has_any_stats = (cp_hist and #cp_hist > 0)
        or (fh_mkt_prices[item_name] and (fh_mkt_prices[item_name].s_avg or fh_mkt_prices[item_name].b_avg))
        or (#(_G._dtl_shop_hist or {}) > 0)
    if _has_any_stats then
        -- Якорь цены из реальных данных лавок: используется фильтром выбросов
        -- когда в cp_hist мало записей. Без него один аномальный «Рынок $» (напр. 1.7М)
        -- проходит как валидный, потому что сам же является своей медианой.
        local _sh_pre   = _G._dtl_shop_hist or {}
        local _shop_anchor = nil
        -- Якорь — медиана по всей доступной истории (fix: всегда история, не только [1])
        if #_sh_pre > 0 then
            local _anch_vals = {}
            for _, _ae in ipairs(_sh_pre) do
                if _ae.s_avg and _ae.s_avg > 0 then table.insert(_anch_vals, _ae.s_avg)
                elseif _ae.b_avg and _ae.b_avg > 0 then table.insert(_anch_vals, _ae.b_avg) end
            end
            if #_anch_vals > 0 then
                table.sort(_anch_vals)
                _shop_anchor = _anch_vals[math.ceil(#_anch_vals/2)]
            end
        end
        if (not _shop_anchor or _shop_anchor <= 0) and lv_e then
            _shop_anchor = lv_e.s_avg or lv_e.b_avg
        end
        if (not _shop_anchor or _shop_anchor <= 0) and cp_e then
            -- последний рубеж: средняя по сделкам в кэше игрока
            _shop_anchor = cp_e.s_avg or cp_e.b_avg
        end
    local trend = cp_hist and #cp_hist>0 and _xvn2w(cp_hist) or nil
    local tc    = trend and _pdf8k(trend) or imgui.ImVec4(0.6,0.6,0.6,1)
    -- Строим _all_px: cp_hist + cloud deals по датам (та ю логика что в арбитраже)
    local _nm_lo_arb = item_name:lower()
    local _all_px_dtl = {}
    if cp_hist then
        for _, _h in ipairs(cp_hist) do
            if (_h.price or 0)>0 and (_h.dt or '')~='' then
                table.insert(_all_px_dtl, {date=_h.dt, price=_h.price, qty=_h.qty or 1})
            end
        end
    end
    local _cd_dtl = _G._mh_deals_cache and _G._mh_deals_cache[_nm_lo_arb]
    if _cd_dtl then
        for _, _cd in ipairs(_cd_dtl) do
            if (_cd.s_avg or 0)>0 and (_cd.date or '')~='' then
                local _dup = false
                for _, _ap in ipairs(_all_px_dtl) do
                    if _ap.date == _cd.date then _dup=true; break end
                end
                if not _dup then
                    table.insert(_all_px_dtl, {date=_cd.date, price=_cd.s_avg, qty=_cd.s_qty or 1})
                end
            end
        end
    end
    -- Дополняем _all_px_dtl из _dtl_shop_hist для дат без скана ЦР/cloud
    -- Используем s_avg лавок как оценку рынка (те же данные что видит пользователь в таблице)
    do
        local _px_dates = {}
        for _, _ap in ipairs(_all_px_dtl) do _px_dates[_ap.date] = true end
        local _dsh3 = _G._dtl_shop_hist or {}
        for _, _se in ipairs(_dsh3) do
            local _sd = _se.date or ''
            -- Берём s_avg только если нет данных скана за эту дату
            if _sd ~= '' and not _px_dates[_sd] and (_se.s_avg or 0) > 0 then
                table.insert(_all_px_dtl, {date=_sd, price=_se.s_avg, qty=1, est=true})
                _px_dates[_sd] = true
            end
        end
    end
    -- Для каждой даты строим объединённый список точек: cp_hist + s_avg лавок
    -- Это нужно чтобы одна дорогая сделка ЦР не была единственной точкой за день
    local _px_by_date = {}  -- date -> {prices}
    for _, _ap in ipairs(_all_px_dtl) do
        local _d = _ap.date or ''
        if _d ~= '' and (_ap.price or 0) > 0 then
            if not _px_by_date[_d] then _px_by_date[_d] = {} end
            table.insert(_px_by_date[_d], _ap.price)
        end
    end
    -- Добавляем s_avg лавок как дополнительную точку за каждый день
    for _, _se in ipairs(_G._dtl_shop_hist or {}) do
        local _d = _se.date or ''
        if _d ~= '' and (_se.s_avg or 0) > 0 then
            if not _px_by_date[_d] then _px_by_date[_d] = {} end
            table.insert(_px_by_date[_d], _se.s_avg)
        end
    end

    local function _dtl_mkt_avg(days_n)
        local cutoff = os.date('%Y-%m-%d', os.time() - days_n*86400)
        local pts = {}
        for _d, _prices in pairs(_px_by_date) do
            if _d >= cutoff then
                for _, _p in ipairs(_prices) do
                    table.insert(pts, _p)
                end
            end
        end
        if #pts == 0 then return nil end
        if #pts == 1 then return pts[1] end
        table.sort(pts)
        -- Берём до 3 самых дешёвых с фильтром x2 от минимума
        local base = pts[1]
        local take = math.min(3, #pts)
        local s, c = 0, 0
        for i = 1, take do
            if pts[i] <= base * 2.0 then
                s = s + pts[i]; c = c + 1
            end
        end
        return c > 0 and math.floor(s / c) or pts[1]
    end
    -- s7/s30 теперь с правильными датами, не просто первыми N записыми
    local _s1_avg  = _dtl_mkt_avg(1)
    local _s7_avg  = _dtl_mkt_avg(7)
    local _s30_avg = _dtl_mkt_avg(30)
    -- Считаем qty фактически проданных за 7/30 дней
    local function _dtl_qty(days_n)
        local cutoff = os.date('%Y-%m-%d', os.time() - days_n*86400)
        local total = 0
        for _, _ap in ipairs(_all_px_dtl) do
            if _ap.date >= cutoff then total = total + (_ap.qty or 1) end
        end
        return total > 0 and total or nil
    end
    local _qty7  = _dtl_qty(7)
    local _qty30 = _dtl_qty(30)
    local s7  = _s7_avg  and {avg=_s7_avg,  qty=_qty7}  or nil
    local s30 = _s30_avg and {avg=_s30_avg, qty=_qty30} or nil

        imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), u8'  Статистика рынка (история по дням)')
        imgui.Spacing()
        local _sh = _G._dtl_shop_hist or {}
        local function _sh_avg(days_n, field)
            local cutoff = os.date('%Y-%m-%d', os.time() - days_n*86400)
            local vals = {}
            for _, e in ipairs(_sh) do
                if e.date >= cutoff and e[field] and e[field] > 0 then
                    table.insert(vals, e[field])
                end
            end
            if #vals == 0 then return nil end
            table.sort(vals)
            -- Берём до 3 самых дешёвых, не больше половины, фильтр x2 от минимума
            local take = math.min(3, math.max(1, math.floor(#vals / 2)))
            local base = vals[1]
            local s, c = 0, 0
            for i = 1, take do
                if vals[i] <= base * 2.0 then
                    s = s + vals[i]; c = c + 1
                end
            end
            return c > 0 and math.floor(s / c) or nil
        end
        -- Продажа сегодня: лучшая цена (s_min), fallback s_avg
        local sh_s_today = #_sh>0 and (_sh[1].s_min or _sh[1].s_avg) or nil
        -- Рынок сегодня (fallback): среднее s_avg
        local sh_s_today_avg = #_sh>0 and _sh[1].s_avg or nil
        -- b_max = лучшая цена скупки (max по лавкам); fallback b_avg
        local sh_b_today = #_sh>0 and (_sh[1].b_max or _sh[1].b_avg) or nil
        local sh_s_7  = _sh_avg(7,  's_avg')
        local sh_b_7  = _sh_avg(7,  'b_max') or _sh_avg(7,  'b_avg')
        local sh_s_30 = _sh_avg(30, 's_avg')
        local sh_b_30 = _sh_avg(30, 'b_max') or _sh_avg(30, 'b_avg')
        -- Примечание: fallback из fh_mkt_prices убран — колонки Продажа/Скупка
        -- должны показывать только реальные цены лавок, а не исторические сделки.
        imgui.Columns(5, '##dtl_stat2', false)
        local _cw6 = imgui.GetWindowContentRegionWidth()
        local _c0w = 58*d
        local _crest = _cw6 - _c0w
        imgui.SetColumnWidth(0, _c0w)
        imgui.SetColumnWidth(1, math.floor(_crest*0.28))
        imgui.SetColumnWidth(2, math.floor(_crest*0.27))
        imgui.SetColumnWidth(3, math.floor(_crest*0.27))
        imgui.SetColumnWidth(4, math.floor(_crest*0.18))

        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), u8''); imgui.NextColumn()
        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), u8'Рынок $'); imgui.NextColumn()
        imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), u8'Продажа $'); imgui.NextColumn()
        imgui.TextColored(imgui.ImVec4(1,0.5,0.2,1),   u8'Скупка $'); imgui.NextColumn()
        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), u8'Продано'); imgui.NextColumn()

        -- Рынок $: из cp_hist (точно) или s_avg из лавок (приближение)
        -- Рынок $: берём hist[1].price напрямую — это реальная цена ЦР за этот день
        -- Фильтр применяется только для 7д/30д средних, но НЕ для строки День
        local today_h = cp_hist and cp_hist[1] or nil
        local _mkt_today = nil
        local _mkt_today_est = false
        do
            -- Собираем индивидуальные цены продажи из текущих лавок напрямую
            local _today_pts = {}
            local _nm_lo_today = item_name:lower()
            local _dtl_cur_srv2 = (ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1] or {}).id or -1
            for _, _osh in pairs(fh_other_shops or {}) do
                if type(_osh) ~= 'table' then goto _mkt_today_sh_next end
                if _dtl_cur_srv2 ~= -1 and _osh.server_id and _osh.server_id ~= -1 and _osh.server_id ~= _dtl_cur_srv2 then goto _mkt_today_sh_next end
                for _, _si in ipairs(_osh.sell_items or {}) do
                    if type(_si.name)=='string' and _si.name:lower()==_nm_lo_today and (_si.price or 0)>0 then
                        table.insert(_today_pts, _si.price)
                    end
                end
                ::_mkt_today_sh_next::
            end
            -- Добавляем cp_hist за сегодня как дополнительную точку
            local _today_date = os.date('%Y-%m-%d')
            for _, _ap in ipairs(_all_px_dtl) do
                if (_ap.date or '') == _today_date and (_ap.price or 0) > 0 and not _ap.est then
                    table.insert(_today_pts, _ap.price)
                end
            end
            if #_today_pts == 0 then
                -- Нет текущих лавок — берём самую свежую точку из истории
                if #_all_px_dtl > 0 and (_all_px_dtl[1].price or 0) > 0 then
                    _mkt_today = _all_px_dtl[1].price
                    _mkt_today_est = _all_px_dtl[1].est == true
                elseif sh_s_today_avg and sh_s_today_avg > 0 then
                    _mkt_today = sh_s_today_avg
                    _mkt_today_est = true
                end
            else
                table.sort(_today_pts)
                local _base = _today_pts[1]
                local _ts, _tc = 0, 0
                for _i = 1, math.min(3, #_today_pts) do
                    if _today_pts[_i] <= _base * 2.0 then
                        _ts = _ts + _today_pts[_i]; _tc = _tc + 1
                    end
                end
                _mkt_today = _tc > 0 and math.floor(_ts / _tc) or _today_pts[1]
                _mkt_today_est = false
            end
        end
        -- Рынок 7д/30д: из _dtl_mkt_avg (фильтр по датам, fallback из _dtl_shop_hist)
        local _mkt_7  = _s7_avg  or sh_s_7   -- sh_s_7 = среднее s_avg за 7дн
        local _mkt_30 = _s30_avg or sh_s_30  -- sh_s_30 = среднее s_avg за 30дн
        -- Anomaly guard: if mkt deviates >5x from shop sell avg, use shop avg
        local function _mkt_sane(mkt_val, shop_val)
            if not mkt_val or mkt_val <= 0 then return shop_val, true end
            if not shop_val or shop_val <= 0 then return mkt_val, false end
            local ratio = mkt_val > shop_val and (mkt_val/shop_val) or (shop_val/mkt_val)
            if ratio > 5.0 then return shop_val, true end
            return mkt_val, false
        end
        local _anom_t, _anom_7, _anom_30
        _mkt_today, _anom_t  = _mkt_sane(_mkt_today, sh_s_today)
        _mkt_7,     _anom_7  = _mkt_sane(_mkt_7,     sh_s_7)
        _mkt_30,    _anom_30 = _mkt_sane(_mkt_30,    sh_s_30)
        if _anom_t  then _mkt_today_est = true end
        imgui.TextColored(imgui.ImVec4(0.4,0.95,1,1), u8' День'); imgui.NextColumn()
        if _mkt_today and _mkt_today > 0 then
            local _mkt_pfx = '$'
            local _mkt_col = _mkt_today_est and imgui.ImVec4(0.65,0.85,0.65,1) or imgui.ImVec4(0.4,0.95,1,1)
            imgui.TextColored(_mkt_col, _cyr5f(' '.._mkt_pfx.._kcr3y(_mkt_today))); imgui.NextColumn()
        else imgui.TextDisabled(u8' —'); imgui.NextColumn() end
        if sh_s_today then imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f(' $'.._kcr3y(sh_s_today)))
        else imgui.TextDisabled(u8' —') end; imgui.NextColumn()
        if sh_b_today then imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), _cyr5f(' $'.._kcr3y(sh_b_today)))
        else imgui.TextDisabled(u8' —') end; imgui.NextColumn()
        if today_h and (today_h.qty or 0) > 0 then
            imgui.TextColored(imgui.ImVec4(1,1,1,0.8), _cyr5f(' '..(today_h.qty or 0))); imgui.NextColumn()
        elseif _sh[1] and (_sh[1].s_qty or _sh[1].s_cnt or 0)>0 then
            imgui.TextColored(imgui.ImVec4(1,1,1,0.6), _cyr5f(' '..(_sh[1].s_qty or _sh[1].s_cnt or 0)..' *')); imgui.NextColumn()
        else
            imgui.TextDisabled(u8' —'); imgui.NextColumn()
        end

        imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), u8' 7дн.'); imgui.NextColumn()
        if _mkt_7 and _mkt_7>0 then
            local _m7pfx = '$'
            local _m7col = _mkt_7_est and imgui.ImVec4(lp_r*0.75,lp_g*0.75,lp_b*0.5,1) or imgui.ImVec4(lp_r,lp_g,lp_b,1)
            imgui.TextColored(_m7col, _cyr5f(' '.._m7pfx.._kcr3y(_mkt_7))); imgui.NextColumn()
        else imgui.TextDisabled(u8' —'); imgui.NextColumn() end
        if sh_s_7 then imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f(' $'.._kcr3y(sh_s_7)))
        else imgui.TextDisabled(u8' —') end; imgui.NextColumn()
        if sh_b_7 then imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), _cyr5f(' $'.._kcr3y(sh_b_7)))
        else imgui.TextDisabled(u8' —') end; imgui.NextColumn()
        if s7 then
            imgui.TextColored(imgui.ImVec4(1,1,1,0.8), _cyr5f(' '.._kcr3y(s7.qty))); imgui.NextColumn()
        else
            imgui.TextDisabled(u8' —'); imgui.NextColumn()
        end

        imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), u8' 30дн.'); imgui.NextColumn()
        if _mkt_30 and _mkt_30>0 then
            local _m30pfx = '$'
            local _m30col = _mkt_30_est and imgui.ImVec4(0.35,0.75,0.35,1) or imgui.ImVec4(0.4,0.95,0.4,1)
            imgui.TextColored(_m30col, _cyr5f(' '.._m30pfx.._kcr3y(_mkt_30))); imgui.NextColumn()
        else imgui.TextDisabled(u8' —'); imgui.NextColumn() end
        if sh_s_30 then imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f(' $'.._kcr3y(sh_s_30)))
        else imgui.TextDisabled(u8' —') end; imgui.NextColumn()
        if sh_b_30 then imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), _cyr5f(' $'.._kcr3y(sh_b_30)))
        else imgui.TextDisabled(u8' —') end; imgui.NextColumn()
        if s30 then
            imgui.TextColored(imgui.ImVec4(1,1,1,0.8), _cyr5f(' '.._kcr3y(s30.qty))); imgui.NextColumn()
        else
            imgui.TextDisabled(u8' —'); imgui.NextColumn()
        end

        imgui.Columns(1)
        imgui.Spacing()

        imgui.Spacing()
        -- Строим единый список дат из cp_hist + _dtl_shop_hist (до 30 дней)
        local _sh2 = _G._dtl_shop_hist or {}
        local _sh_date_idx = {}
        for _, e in ipairs(_sh2) do
            if e.date and e.date ~= '' then _sh_date_idx[e.date] = e end
        end
        -- Для сегодняшней даты: подставляем данные из живых лавок (sell_rows/buy_rows)
        -- Это синхронизирует колонки Продажа/Скупка с блоком "Цены в лавках игроков"
        do
            local _td = os.date('%Y-%m-%d')
            -- s_min = лучшая (минимальная) цена продажи для колонки Продажа
            -- s_avg = среднее по всем лавкам для колонки Рынок (fallback)
            local _s_min_live = sell_rows and #sell_rows > 0 and sell_rows[1].price or nil
            local _s_avg_live = nil
            if sell_rows and #sell_rows > 0 then
                local _ss, _sc = 0, 0
                for _, _sr2 in ipairs(sell_rows) do
                    if (_sr2.price or 0) > 0 then _ss = _ss + _sr2.price; _sc = _sc + 1 end
                end
                if _sc > 0 then _s_avg_live = math.floor(_ss / _sc) end
            end
            local _b_live = buy_rows  and #buy_rows  > 0 and buy_rows[1].price  or nil
            -- b_max = максимальная цена скупки  (buy_rows отсортированы по убыванию)
            if _s_min_live or _b_live then
                if not _sh_date_idx[_td] then
                    local _new = {date=_td, s_avg=nil, s_min=nil, b_avg=nil, b_max=nil}
                    _sh_date_idx[_td] = _new
                    table.insert(_sh2, 1, _new)
                end
                local _e = _sh_date_idx[_td]
                if _s_min_live then _e.s_min = _s_min_live end
                if _s_avg_live then _e.s_avg = _s_avg_live end
                if _b_live then _e.b_max = _b_live; if not _e.b_avg then _e.b_avg = _b_live end end
                -- Синхронизируем _G._dtl_shop_hist чтобы _sh_avg() в блоке День/7дн/30дн
                -- тоже видел live данные из sell_rows/buy_rows
                local _dsh = _G._dtl_shop_hist
                if _dsh then
                    local _found_today = false
                    for _, _de in ipairs(_dsh) do
                        if _de.date == _td then
                            if _s_min_live then _de.s_min = _s_min_live end
                            if _s_avg_live then _de.s_avg = _s_avg_live end
                            if _b_live then _de.b_max = _b_live; if not _de.b_avg then _de.b_avg = _b_live end end
                            _found_today = true; break
                        end
                    end
                    if not _found_today then
                        local _ne = {date=_td, s_avg=_s_avg_live, s_min=_s_min_live,
                                     b_avg=_b_live, b_max=_b_live}
                        table.insert(_dsh, 1, _ne)
                    end
                end
            end
        end
        -- Сбор уникальных дат из обоих источников
        local _all_chart_dates = {}
        local _acd_set = {}
        for _, h in ipairs(cp_hist or {}) do
            local dt = h.dt or ''
            if dt ~= '' and not _acd_set[dt] then
                table.insert(_all_chart_dates, dt); _acd_set[dt] = true
            end
        end
        for _, e in ipairs(_sh2) do
            local dt = e.date or ''
            if dt ~= '' and not _acd_set[dt] then
                table.insert(_all_chart_dates, dt); _acd_set[dt] = true
            end
        end
        -- Сортируем по убыванию и берём 30 последних
        table.sort(_all_chart_dates, function(a,b) return a > b end)
        if #_all_chart_dates > 30 then
            local _tmp = {}
            for i=1,30 do _tmp[i]=_all_chart_dates[i] end
            _all_chart_dates = _tmp
        end
        -- Обратный порядок для графика (старые слева -> новые справа)
        local _chart_dates = {}
        for i = #_all_chart_dates, 1, -1 do table.insert(_chart_dates, _all_chart_dates[i]) end
        local plot_n = math.max(#_chart_dates, 1)

        -- Индекс cp_hist по дате (+ cloud deals как fallback)
        local _cp_by_date = {}
        for _, h in ipairs(cp_hist or {}) do
            if h.dt and h.dt ~= '' then _cp_by_date[h.dt] = h end
        end
        -- Дополняем cloud deals: если даты нет в cp_hist — берём s_avg
        do
            local _cd2 = _G._mh_deals_cache and _G._mh_deals_cache[item_name:lower()]
            if _cd2 then
                for _, _cde in ipairs(_cd2) do
                    local _cdt = _cde.date or ''
                    if _cdt ~= '' and not _cp_by_date[_cdt] and (_cde.s_avg or 0) > 0 then
                        _cp_by_date[_cdt] = {dt=_cdt, price=_cde.s_avg, qty=_cde.s_qty or 0}
                    end
                end
            end
        end

        -- Вычисляем допустимый диапазон (только рыночные цены, без лавок)
        local _all_prices_chart = {}
        for _, dt in ipairs(_chart_dates) do
            local mh = _cp_by_date[dt]
            if mh and mh.price and mh.price > 0 then table.insert(_all_prices_chart, mh.price) end
        end
        -- Если нет рыночных данных — берём все данные для масштаба
        if #_all_prices_chart == 0 then
            for _, dt in ipairs(_chart_dates) do
                local se = _sh_date_idx[dt]
                if se and se.s_avg and se.s_avg > 0 then table.insert(_all_prices_chart, se.s_avg) end
                if se and se.b_avg and se.b_avg > 0 then table.insert(_all_prices_chart, se.b_avg) end
            end
        end
        local _chart_lo, _chart_hi = 0, math.huge
        if #_all_prices_chart > 0 then
            local _srt = {}; for _,v in ipairs(_all_prices_chart) do table.insert(_srt, v) end
            table.sort(_srt)
            local _med = _srt[math.ceil(#_srt/2)]
            local _q1 = _srt[math.max(1, math.ceil(#_srt*0.25))]
            local _q3 = _srt[math.min(#_srt, math.ceil(#_srt*0.75))]
            local _iqr = _q3 - _q1
            local _fence = math.max(_iqr*3, _med*0.7)
            _chart_lo = math.max(0, _med - _fence)
            _chart_hi = _med + _fence
        end

        local p_min, p_max = math.huge, -math.huge
        local plot_tbl = {}
        local _plot_s = {}; local _plot_b = {}
        local _has_shop_data = false
        for _, dt in ipairs(_chart_dates) do
            local mh = _cp_by_date[dt]
            local v = (mh and mh.price) or 0
            -- Отбрасываем аномальные точки
            if v > 0 and (v < _chart_lo or v > _chart_hi) then v = 0 end
            local se = _sh_date_idx[dt]
            local sv = (se and se.s_avg) or 0
            local bv = (se and (se.b_max or se.b_avg)) or 0  -- b_max приоритет
            -- Линии Продажа/Скупка НЕ обрезаем — они независимы от ЦР
            -- Если нет точной цены ЦР — используем цену продажи из лавок
            local v_plot = v
            if v_plot == 0 and sv > 0 then
                v_plot = sv
            end
            table.insert(plot_tbl, v_plot)
            if v_plot > 0 then if v_plot<p_min then p_min=v_plot end; if v_plot>p_max then p_max=v_plot end end
            table.insert(_plot_s, sv)
            table.insert(_plot_b, bv)
            if sv > 0 or bv > 0 then _has_shop_data = true end
            if sv > 0 then if sv<p_min then p_min=sv end; if sv>p_max then p_max=sv end end
            if bv > 0 then if bv<p_min then p_min=bv end; if bv>p_max then p_max=bv end end
        end

        local plot_scale, overlay_s
        local p_real_max = (p_max ~= -math.huge) and p_max or 0
        if p_real_max >= 1000000000 then
            plot_scale = 1000000; overlay_s = _cyr5f('млн $')
        elseif p_real_max >= 1000000 then
            plot_scale = 1000;    overlay_s = _cyr5f('тыс $')
        else
            plot_scale = 1;       overlay_s = _cyr5f('$')
        end
        -- p_min_sc2/p_max_sc2 включают все три линии
        local p_min_sc2 = (p_min ~= math.huge)  and (p_min / plot_scale * 0.92) or 0
        local p_max_sc2 = (p_max ~= -math.huge) and (p_max / plot_scale * 1.08) or 1
        if p_max_sc2 <= p_min_sc2 then p_max_sc2 = p_min_sc2 + 1 end

        -- Рынок PlotLines (синяя линия imgui)
        -- Заполнюем нули ближайшим известным значением (forward+backward fill)
        local _plot_filled = {}
        for i = 1, plot_n do _plot_filled[i] = plot_tbl[i] end
        -- forward fill: пропагация вперёд
        local _last_v = nil
        for i = 1, plot_n do
            if _plot_filled[i] and _plot_filled[i] > 0 then
                _last_v = _plot_filled[i]
            elseif _last_v then
                _plot_filled[i] = _last_v
            end
        end
        -- backward fill: если начало серии нулевое
        local _first_v = nil
        for i = 1, plot_n do
            if _plot_filled[i] and _plot_filled[i] > 0 then _first_v = _plot_filled[i]; break end
        end
        if _first_v then
            for i = 1, plot_n do
                if not _plot_filled[i] or _plot_filled[i] == 0 then _plot_filled[i] = _first_v
                else break end
            end
        end
        local plot_vals = ffi.new('float[?]', plot_n)
        for i = 0, plot_n - 1 do
            plot_vals[i] = (_plot_filled[i + 1] or 0) / plot_scale
        end

        imgui.TextColored(imgui.ImVec4(0.5, 0.8, 1, 1), _cyr5f('  График цен (' .. plot_n .. ' дн):'))
        -- Легенда: Рынок всегда (если есть), Продажа/Скупка если есть данные лавок
        -- _has_mkt_data: true если хоть одна точка графика Рынок ненулевая
        local _has_mkt_data = false
        for _, _ptv in ipairs(plot_tbl) do if _ptv > 0 then _has_mkt_data = true; break end end
        if _has_mkt_data or _has_shop_data then
            imgui.SameLine(0,8*d)
            if _has_mkt_data then
                imgui.TextColored(imgui.ImVec4(1,0.73,0.33,1), u8'— Рынок')
                imgui.SameLine(0,8*d)
            end
            if _has_shop_data then
                imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), u8'— Продажа')
                imgui.SameLine(0,8*d)
                imgui.TextColored(imgui.ImVec4(1,0.5,0.2,1), u8'— Скупка')
            end
        end

        imgui.PushStyleColor(imgui.Col.PlotLines, imgui.ImVec4(0.3, 0.8, 1, 1))
        imgui.PushStyleColor(imgui.Col.PlotLinesHovered, imgui.ImVec4(lp_r,lp_g,lp_b,1))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.06, 0.06, 0.10, 1))
        local _chart_w = imgui.GetWindowContentRegionWidth() - 16*d
        local _chart_h = 80*d
        local _cp_chart = imgui.GetCursorScreenPos()
        imgui.PlotLines('##fhspark', plot_vals, plot_n, 0, overlay_s,
            p_min_sc2, p_max_sc2, imgui.ImVec2(_chart_w, _chart_h))
        imgui.PopStyleColor(3)

        if (_has_mkt_data or _has_shop_data) and plot_n >= 1 then
            local _dl = imgui.GetWindowDrawList()
            local _rng = (p_max_sc2 - p_min_sc2)
            if _rng <= 0 then _rng = 1 end
            local function _chart_pt(xi, val_raw)
                local v = (val_raw / plot_scale)
                local nx = (plot_n > 1) and ((xi - 1) / (plot_n - 1)) or 0.5
                local ny = 1 - (v - p_min_sc2) / _rng
                ny = math.max(0, math.min(1, ny))
                return _cp_chart.x + nx * _chart_w, _cp_chart.y + ny * _chart_h
            end
            -- Рисуем линии (или точки если только 1 день)
            local function _draw_line_or_dot(pts_tbl, col, thick)
                if plot_n == 1 then
                    local v = pts_tbl[1]
                    if v and v > 0 then
                        local x, y = _chart_pt(1, v)
                        _dl:AddCircleFilled(imgui.ImVec2(x, y), thick*2, col)
                    end
                else
                    for xi = 1, plot_n - 1 do
                        local v1, v2 = pts_tbl[xi], pts_tbl[xi+1]
                        if v1 and v1>0 and v2 and v2>0 then
                            local x1,y1 = _chart_pt(xi,v1); local x2,y2 = _chart_pt(xi+1,v2)
                            _dl:AddLine(imgui.ImVec2(x1,y1), imgui.ImVec2(x2,y2), col, thick)
                        end
                    end
                end
            end
            if _has_mkt_data  then _draw_line_or_dot(plot_tbl, 0xFFFFBB55, 1.5) end
            if _has_shop_data then _draw_line_or_dot(_plot_s,   0xFF44EE66, 1.5) end
            if _has_shop_data then _draw_line_or_dot(_plot_b,   0xFF3380FF, 2.0) end
        end
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        local _sh2_hist = _G._dtl_shop_hist or {}
        local _all_dates = {}
        local _date_seen = {}  -- dt_string -> index in _all_dates
        local _total_hist_rows = (cp_hist and #cp_hist or 0)
        local _tmp_dt_seen = {}
        if cp_hist then for _,_hh in ipairs(cp_hist) do _tmp_dt_seen[_hh.dt or '']=true end end
        for _, _ese in ipairs(_sh2_hist) do
            if _ese.date and not _tmp_dt_seen[_ese.date] then _total_hist_rows=_total_hist_rows+1; _tmp_dt_seen[_ese.date]=true end
        end
        imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f('  История по дням (' .. _total_hist_rows .. '):'))
        for _, h in ipairs(cp_hist or {}) do
            local dt = h.dt or ''
            if dt ~= '' and not _date_seen[dt] then
                _date_seen[dt] = #_all_dates + 1
                table.insert(_all_dates, {dt=dt, mkt=h, sh=nil})
            end
        end
        for _, e in ipairs(_sh2_hist) do
            local dt = e.date or ''
            if dt == '' then goto _ad_sh_next end
            local ei = _date_seen[dt]
            if ei then
                -- дата уже есть из cp_hist — просто ставим sh
                _all_dates[ei].sh = e
            else
                _date_seen[dt] = #_all_dates + 1
                table.insert(_all_dates, {dt=dt, mkt=nil, sh=e})
            end
            ::_ad_sh_next::
        end
        table.sort(_all_dates, function(a,b) return a.dt > b.dt end)
        -- Пересчитываем s7/s30 из ВСЕХ данных (cp_hist + cloud + лавки) по дням
        do
            local _now = os.time()
            local _cut7  = os.date('%Y-%m-%d', _now - 7*86400)
            local _cut30 = os.date('%Y-%m-%d', _now - 30*86400)
            local _p7, _p30 = {}, {}
            for _, _row in ipairs(_all_dates) do
                -- Берём цену: только реальные данные рынка (скан / deep / сделки)
                local _px = nil
                if _row.mkt and (_row.mkt.price or 0) > 0 then
                    _px = _row.mkt.price
                elseif _row.sh and (_row.sh.deep_price or 0) > 0 then
                    _px = _row.sh.deep_price
                elseif _row.sh and (_row.sh.deal_s or 0) > 0 then
                    _px = _row.sh.deal_s
                end
                if _px and _px > 0 and _row.dt then
                    if _row.dt >= _cut7  then table.insert(_p7,  _px) end
                    if _row.dt >= _cut30 then table.insert(_p30, _px) end
                end
            end
            -- Считаем среднее с фильтром выбросов (медиана ±3x)
            local function _avg_clean(pts)
                if #pts == 0 then return nil end
                table.sort(pts)
                local med = pts[math.ceil(#pts/2)]
                local s, c = 0, 0
                for _, v in ipairs(pts) do
                    if v >= med*0.20 and v <= med*3.5 then s=s+v; c=c+1 end
                end
                return c>0 and math.floor(s/c) or med
            end
            local _s7_full  = _avg_clean(_p7)
            local _s30_full = _avg_clean(_p30)
            -- Всегда используем пересчитанные данные из всех источников
            -- (cp_hist + cloud deals + лавки) — они точнее одного старого скана
            if _s7_full  and #_p7  > 0 then s7  = {avg=_s7_full,  qty=#_p7}  end
            if _s30_full and #_p30 > 0 then s30 = {avg=_s30_full, qty=#_p30} end
            -- Обновляем stat bar (7дн / 30дн)
            local _mkt_7_base2  = (s7  and s7.avg>0  and s7.avg)  or sh_s_7
            local _mkt_30_base2 = (s30 and s30.avg>0 and s30.avg) or sh_s_30
            if _mkt_7_base2  then _mkt_7  = _mkt_7_base2  end
            if _mkt_30_base2 then _mkt_30 = _mkt_30_base2 end
            -- "День" = самая свежая цена из ВСЕХ источников (cp_hist + cloud + лавки)
            -- _all_dates уже отсортирован по убыванию даты ? [1] = самая свежая
            if #_all_dates > 0 then
                local _newest = _all_dates[1]
                local _new_px = nil
                if _newest.mkt and (_newest.mkt.price or 0) > 0 then
                    _new_px = _newest.mkt.price
                elseif _newest.sh and (_newest.sh.deep_price or 0) > 0 then
                    _new_px = _newest.sh.deep_price
                elseif _newest.sh and (_newest.sh.deal_s or 0) > 0 then
                    _new_px = _newest.sh.deal_s
                end
                if _new_px and _new_px > 0 then _mkt_today = _new_px end
            end
        end
        local _today_str = os.date('%Y-%m-%d')
        local hist_h = math.min(#_all_dates * 18*d + 30*d, 155*d)
        if imgui.BeginChild('##dtl_hist_days', imgui.ImVec2(-1, hist_h), true) then
            _dpn1w()  -- swipe scroll
            imgui.Columns(4, '##dtl_hd', false)
            local _cwhd = imgui.GetWindowContentRegionWidth()
            local _dt_col = 120*d  -- Фиксировандая колонка Фата
            local _rest3 = (_cwhd - _dt_col) / 3
            imgui.SetColumnWidth(0, _dt_col)
            imgui.SetColumnWidth(1, math.floor(_rest3))
            imgui.SetColumnWidth(2, math.floor(_rest3))
            imgui.SetColumnWidth(3, math.floor(_rest3))
            imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8' Дата'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.8,0.8,0.5,1), _ic_store..' '..u8'Рынок $'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _ic_tag..' '..u8'Продажа'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1,0.5,0.2,1),   _ic_cart..' '..u8'Скупка'); imgui.NextColumn()
            imgui.Separator()
            -- Медиана 3 дешёвых цен из списка
            local function _prices_med3(prices)
                if not prices or #prices == 0 then return nil end
                local _s = {}; for _, v in ipairs(prices) do table.insert(_s, v) end
                table.sort(_s)
                local _cnt = math.min(3, #_s)
                local _sum = 0
                for i = 1, _cnt do _sum = _sum + _s[i] end
                return math.floor(_sum / _cnt)
            end
            -- Текущие цены лавок для этого товара (для строки is_fresh)
            local _osh_now_prices = {}
            for _, _osp in pairs(fh_other_shops or {}) do
                if type(_osp) == 'table' then
                    for _, _osi in ipairs(_osp.sell_items or {}) do
                        if type(_osi.name)=='string' and _osi.name==item_name and (_osi.price or 0) > 0 then
                            local _seen = false
                            for _, _ep in ipairs(_osh_now_prices) do if _ep==_osi.price then _seen=true; break end end
                            if not _seen then table.insert(_osh_now_prices, _osi.price) end
                        end
                    end
                end
            end
            local _osh_now_med = _prices_med3(_osh_now_prices)

            for ri, row in ipairs(_all_dates) do
                local is_today = (row.dt == _today_str)
                local is_fresh = (ri == 1)
                local dt_col = is_today and imgui.ImVec4(0.4,0.95,1,1)
                           or (is_fresh and imgui.ImVec4(lp_r,lp_g,lp_b,1)
                           or imgui.ImVec4(0.65,0.65,0.65,1))
                local dt_lbl = row.dt
                imgui.TextColored(dt_col, _cyr5f(' '..dt_lbl)); imgui.NextColumn()
                -- Аномалия: цена уникальна И сильно отличается от медианы
                -- Не аномалия если та же цена стоит у соседних дней (просто нет свежего скана)
                local _mkt_price_anomaly = false
                if row.mkt and row.mkt.price and row.mkt.price > 0 and cp_hist and #cp_hist >= 3 then
                    local _all_p = {}
                    for _, _hh in ipairs(cp_hist) do
                        if _hh.price and _hh.price > 0 then table.insert(_all_p, _hh.price) end
                    end
                    table.sort(_all_p)
                    -- Используем медиану нижних 60% как эталон (не даём верхним ценам смещать медиану)
                    local _take60 = math.max(1, math.ceil(#_all_p * 0.6))
                    local _s60, _c60 = 0, 0
                    for _i = 1, _take60 do _s60 = _s60 + _all_p[_i]; _c60 = _c60 + 1 end
                    local _med2 = _c60 > 0 and math.floor(_s60 / _c60) or _all_p[math.ceil(#_all_p/2)]
                    if _med2 > 0 then
                        local _ratio = row.mkt.price / _med2
                        if _ratio > 2.0 or _ratio < 0.35 then
                            local _prev = _all_dates[ri - 1]
                            local _next = _all_dates[ri + 1]
                            local _p = row.mkt.price
                            local _same_prev = _prev and _prev.mkt and _prev.mkt.price == _p
                            local _same_next = _next and _next.mkt and _next.mkt.price == _p
                            if not _same_prev and not _same_next then
                                _mkt_price_anomaly = true
                            end
                        end
                    end
                end
                -- Рынок $: cp_hist > deep_price > deal_s (сделки из лога). s_avg НЕ попадает.
                do
                    local _rp=nil; local _rp_dim=false; local _rp_anom=false
                    local _rp_src=''
                    -- Для строки сегодня (is_fresh) — приоритет текущим ценам лавок
                    if is_fresh and _osh_now_med and _osh_now_med > 0 then
                        _rp = _osh_now_med; _rp_dim = true; _rp_src = 's_prices'
                    elseif row.mkt and (row.mkt.price or 0)>0 then
                        _rp=row.mkt.price; _rp_anom=_mkt_price_anomaly
                        _rp_src='scan'
                    elseif row.sh and (row.sh.deep_price or 0)>0 then
                        _rp=row.sh.deep_price
                        _rp_src='deep'
                    elseif row.sh and (row.sh.deal_s or 0)>0 then
                        _rp=row.sh.deal_s; _rp_dim=true
                        _rp_src='log'
                    elseif row.sh and (row.sh.s_avg or 0)>0 then
                        _rp=row.sh.s_avg; _rp_dim=true
                        _rp_src='s_avg'
                    elseif row.sh and (row.sh.s_min or 0)>0 then
                        _rp=row.sh.s_min; _rp_dim=true
                        _rp_src='s_avg'
                    end
                    -- Для прошлых дней с аномальным cp_hist: заменяем медианой s_prices из файла
                    if _rp_anom then
                        local _sp_med = _prices_med3(row.sh and row.sh.s_prices)
                        if _sp_med and _sp_med > 0 then
                            _rp = _sp_med; _rp_anom = false; _rp_dim = true; _rp_src = 's_prices'
                        elseif row.sh and (row.sh.s_avg or 0) > 0 then
                            _rp = row.sh.s_avg; _rp_anom = false; _rp_dim = true; _rp_src = 's_avg'
                        end
                    end
                    if _rp then
                        local rc = _rp_dim
                            and imgui.ImVec4(0.55,0.75,0.55,1)
                            or (is_fresh and imgui.ImVec4(lp_r,lp_g,lp_b,1) or imgui.ImVec4(0.85,0.85,0.85,1))
                        if _rp_anom then
                            imgui.TextColored(imgui.ImVec4(1,0.4,0.2,1), _ic_warn..' ')
                            imgui.SameLine(0,1*d)
                            imgui.TextColored(imgui.ImVec4(0.7,0.45,0.35,1), _cyr5f('$'.._kcr3y(_rp)))
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Возможный выброс: цена резко отличается')) end
                        else
                            imgui.TextColored(rc, _cyr5f(' $'.._kcr3y(_rp)))
                            if imgui.IsItemHovered() then
                                if _rp_src=='log' then
                                    imgui.SetTooltip(_cyr5f('Средняя цена реальных сделок (лог игроков)'))
                                elseif _rp_src=='deep' then
                                    imgui.SetTooltip(_cyr5f('Данные углублённого скана другого игрока'))
                                elseif _rp_src=='s_avg' then
                                    imgui.SetTooltip(_cyr5f('~Ср. цена продажи в лавках (скан ЦР недоступен)'))
                                end
                            end
                        end
                    else imgui.TextDisabled(u8' —') end
                end; imgui.NextColumn()
                -- Продажа: лучшая цена (s_min) если есть, иначе s_avg
                do
                    local _sp_best = row.sh and (row.sh.s_min or row.sh.s_avg)
                    local _is_best = row.sh and row.sh.s_min ~= nil
                    if _sp_best then
                        local lc=is_today and imgui.ImVec4(0.5,1,0.5,1) or imgui.ImVec4(0.4,0.9,0.4,1)
                        imgui.TextColored(lc, _cyr5f(' $'.._kcr3y(_sp_best)))
                        if imgui.IsItemHovered() then
                            if _is_best then
                                imgui.SetTooltip(_cyr5f('Лучшая цена продажи в лавках'))
                            else
                                imgui.SetTooltip(_cyr5f('Ср. цена продажи в лавках'))
                            end
                        end
                    else imgui.TextDisabled(u8' —') end
                end; imgui.NextColumn()
                -- Скупка: b_max (лучшая цена скупки дня) если есть, иначе b_avg
                do
                    local _bmax = row.sh and row.sh.b_max
                    local _bavg = row.sh and row.sh.b_avg
                    local _bp   = (_bmax and _bmax > 0) and _bmax or _bavg
                    local _is_max = _bmax and _bmax > 0
                    if _bp then
                        local bc=is_today and imgui.ImVec4(0.5,0.8,1,1) or imgui.ImVec4(0.4,0.7,1,1)
                        imgui.TextColored(bc, _cyr5f(' $'.._kcr3y(_bp)))
                        if imgui.IsItemHovered() then
                            if _is_max then
                                imgui.SetTooltip(_cyr5f('Лучшая цена скупки в лавках за день'))
                            else
                                imgui.SetTooltip(_cyr5f('Ср. цена скупки в лавках (b_max нет)'))
                            end
                        end
                    else imgui.TextDisabled(u8' —') end
                end; imgui.NextColumn()
            end
            imgui.Columns(1); imgui.EndChild()
        end
    elseif cp_e then
        imgui.TextColored(imgui.ImVec4(1,0.75,0,1), u8'  Только поверхностный скан (нет истории по дням)')
        imgui.TextDisabled(u8'  Запустите Углублённый скан для получения истории')
        imgui.Spacing()
        if cp_e.s_avg then
            imgui.Text(_cyr5f('  Ср. цена (shallow): $' .. _kcr3y(cp_e.s_avg)))
            if cp_e.s_min then imgui.Text(_cyr5f('  Мин: $'.._kcr3y(cp_e.s_min)..'   Макс: $'.._kcr3y(cp_e.s_max))) end
        end
        imgui.Separator()
    else
        imgui.TextDisabled(u8'  Нет данных с чекпоинта.')
        imgui.Separator()
    end
    if #sell_rows > 0 or #buy_rows > 0 then
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), u8'  Цены в лавках игроков:')
        imgui.Spacing()
        -- Кнопка Рынок/Лавки открывает ARZ с поиском
        -- Открыть лавку конкретного игрока и поставить флаг "назад"
        _G._goto_owner_lavka = function(owner_name)
            local _found_lv = nil
            local _own_lo = (owner_name or ''):lower()
            for _, _lv in ipairs(mh_arz_data or {}) do
                if type(_lv)=='table' and _lv.username and _lv.username:lower()==_own_lo then
                    _found_lv = _lv; break
                end
            end
            if not _found_lv then
                for _, _sh in pairs(fh_other_shops or {}) do
                    if type(_sh)=='table' and _sh.owner and _sh.owner:lower()==_own_lo then
                        _found_lv = {username=_sh.owner, LavkaUid=_sh.shop_num or 0,
                            serverId=_sh.server_id or -1, items_sell={}, items_buy={},
                            price_sell={}, price_buy={}, count_sell={}, count_buy={}, _mh_cloud=true}
                        if mh_arz_items_db then
                            local _fi = 910000
                            for _,si in ipairs(_sh.sell_items or {}) do
                                _fi=_fi+1; mh_arz_items_db[_fi]=si.name or '?'
                                table.insert(_found_lv.items_sell,_fi)
                                table.insert(_found_lv.price_sell,si.price or 0)
                                table.insert(_found_lv.count_sell,si.qty or 1)
                            end
                            for _,bi in ipairs(_sh.buy_items or {}) do
                                _fi=_fi+1; mh_arz_items_db[_fi]=bi.name or '?'
                                table.insert(_found_lv.items_buy,_fi)
                                table.insert(_found_lv.price_buy,bi.price or 0)
                                table.insert(_found_lv.count_buy,bi.qty or 1)
                            end
                        end
                        break
                    end
                end
            end
            if _found_lv then
                _G.mh_tab=2; _G.arz_detail=_found_lv; _G.arz_detail_tab=0
                _G.arz_detail_back=true; _G.arz_back_item=item_name; _G.arz_back_src=src
                _G.arz_page=1; _G.arz_cache_key=nil; _G.mkt_detail_open=false
            else
                _G.mh_tab=2; _G.arz_detail=nil; _G.arz_page=1; _G.arz_cache_key=nil
                local _ok_e,_cp_e = pcall(function()
                    return require('encoding').CP1251:encode(require('encoding').UTF8:decode(item_name))
                end)
                if _G.arz_srch then ffi.copy(_G.arz_srch,(_ok_e and _cp_e) and _cp_e or item_name) end
                _G.arz_srch_s=item_name:lower(); _G.mkt_detail_open=false
            end
        end
        _G._goto_arz = function()
            _G.mh_tab = 2
            local _ok_e,_cp_e = pcall(function()
                return require('encoding').CP1251:encode(require('encoding').UTF8:decode(item_name))
            end)
            if _G.arz_srch then ffi.copy(_G.arz_srch,(_ok_e and _cp_e) and _cp_e or item_name) end
            _G.arz_srch_s = item_name:lower()
            _G.arz_detail=nil; _G.arz_page=1; _G.arz_cache_key=nil; _G.mkt_detail_open=false
        end
    end

    if _G.dtl_tab[0] == 1 then
        local col_w2 = (imgui.GetWindowContentRegionWidth() - 8*d) / 2
        local rows_h = math.min(math.max(#sell_rows,#buy_rows),3)*16*d + 42*d + 20

        if imgui.BeginChild('##lv_sell', imgui.ImVec2(col_w2, rows_h), true) then
            _dpn1w()  -- swipe scroll
            imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _ic_tag..' '..u8'Продаёт')
            imgui.Separator()
            if #sell_rows == 0 then
                imgui.TextDisabled(u8'  Нет данных')
            else
                for ri, r in ipairs(sell_rows) do
                    imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f('$'.._kcr3y(r.price)))
                    imgui.SameLine(0,6*d)
                    -- Кнопка-владелец ведёт во вкладку Рынок/Лавки с поиском
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.2,0.5,0.2,0.4))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.65,0.65,0.65,1))
                    local _row_lbl = _cyr5f(r.owner..(r.src~='' and ' '..r.src or '')..(r.qty and ' x'..r.qty or ''))
                    if imgui.Button(_row_lbl..'##sr'..ri, imgui.ImVec2(0,0)) then
                        if _G._goto_owner_lavka then _G._goto_owner_lavka(r.owner) end
                    end
                    imgui.PopStyleColor(3)
                end
            end
            imgui.EndChild()
        end
        imgui.SameLine(0, 8*d)
        if imgui.BeginChild('##lv_buy', imgui.ImVec2(col_w2, rows_h), true) then
            _dpn1w()  -- swipe scroll
            imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), _ic_store..' '..u8'Скупает')
            imgui.Separator()
            if #buy_rows == 0 then
                imgui.TextDisabled(u8'  Нет данных')
            else
                for ri, r in ipairs(buy_rows) do
                    imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), _cyr5f('$'.._kcr3y(r.price)))
                    imgui.SameLine(0,6*d)
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.1,0.2,0.5,0.4))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.65,0.65,0.65,1))
                    local _row_lbl2 = _cyr5f(r.owner..(r.src~='' and ' '..r.src or '')..(r.qty and ' x'..r.qty or ''))
                    if imgui.Button(_row_lbl2..'##br'..ri, imgui.ImVec2(0,0)) then
                        if _G._goto_owner_lavka then _G._goto_owner_lavka(r.owner) end
                    end
                    imgui.PopStyleColor(3)
                end
            end
            imgui.EndChild()
        end
        imgui.Spacing()
    end  -- end if _has_any_stats
    end  -- end do stats block

    imgui.Spacing()
    local my_hist = {}
    local nm_low = item_name:lower()
    for i = #fh_mkt_log, 1, -1 do
        local le = fh_mkt_log[i]
        if le and le.item and le.item:lower() == nm_low then
            table.insert(my_hist, le)
            if #my_hist >= 50 then break end
        end
    end
    imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f('  Мои сделки (' .. #my_hist .. '):'))
    local log_h = math.min(#my_hist, 3) * 18*d + 50*d
    if imgui.BeginChild('##dtl_mylog', imgui.ImVec2(-1, log_h), true) then
        _dpn1w()  -- swipe scroll
        if #my_hist == 0 then
            imgui.TextDisabled(u8'  Сделок по этому товару нет')
        else
            imgui.Columns(4, '##dtl_ml', false)
            imgui.SetColumnWidth(0,80*d); imgui.SetColumnWidth(1,38*d)
            imgui.SetColumnWidth(2,100*d); imgui.SetColumnWidth(3,90*d)
            imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'Дата'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'Кол.'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'Цена $'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'Тип'); imgui.NextColumn()
            imgui.Separator()
            for _, le in ipairs(my_hist) do
                local is_sell = (le.op == 'sell') or (le.op ~= 'buy')
                local tc2 = is_sell and imgui.ImVec4(0.4,0.95,0.4,1) or imgui.ImVec4(0.4,0.7,1,1)
                imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), _cyr5f(' '..(le.dt or ''))); imgui.NextColumn()
                imgui.TextColored(imgui.ImVec4(1,1,1,0.7), _cyr5f(' '..(le.qty or 1))); imgui.NextColumn()
                imgui.TextColored(tc2, _cyr5f(' '.._fmt_price_arz(le.price))); imgui.NextColumn()
                imgui.TextColored(tc2, is_sell and u8'Продажа' or u8'Покупка'); imgui.NextColumn()
            end
            imgui.Columns(1)
        end
        imgui.EndChild()
    end
end

local function _uwj4x()   return os.date('%d.%m.%Y') end
local function _onv2g()   return os.date('%H:%M:%S') end
local function fh_datetime_now() return os.date('%d.%m.%Y [%H:%M:%S]') end

local function _hxn2b(text)
    if not text or text == '' then return {''} end
    text = text:gsub('\r\n', '\n'):gsub('\r', '\n')
    local lines = {}
    for line in (text .. '\n'):gmatch('(.-)\n') do
        table.insert(lines, line)
    end
    return lines
end

local function fh_clean_log_line(s)
    s = s:gsub('%[%d%d:%d%d:%d%d%]', '')
    s = s:gsub('%[Color:%-?%d+%]', '')
    s = s:gsub('{%x%x%x%x%x%x}', '')
    return s:match('^%s*(.-)%s*$') or ''
end

local function fh_lower(s)
    if not s then return '' end
    s = tostring(s):lower()
    local result = ''
    for i = 1, #s do
        local b = s:byte(i)
        if b >= 192 and b <= 223 then
            result = result .. string.char(b + 32)
        else
            result = result .. string.char(b)
        end
    end
    return result
end

local function fh_prepare_text(s)
    return fh_lower(tostring(s or ''))
end

local function fh_get_files(dir)
    local lfs = require('lfs')
    local files = {}
    if not lfs.attributes(dir) then return files end
    for f in lfs.dir(dir) do
        if f ~= '.' and f ~= '..' then
            table.insert(files, f)
        end
    end
    return files
end

local function fh_wait_for(timeout_ms, condition, on_timeout)
    local t = timeout_ms
    while not condition() do
        wait(1)
        t = t - 1
        if t <= 0 then
            if on_timeout then on_timeout() end
            return false
        end
    end
    return true
end

fh_sort_mode = 1   -- 1=имя, 2=цена+, 3=цена-, 4=сумма+, 5=сумма-, 6=кол-во
fh_sort_asc  = true

local function fh_sort_items(items, mode, asc)
    local comparators = {
        [1] = function(a, b) return fh_lower(a.name or '') < fh_lower(b.name or '') end,
        [2] = function(a, b) return (a.price or 0) < (b.price or 0) end,
        [3] = function(a, b) return ((a.price or 0) * (a.qty or 0)) < ((b.price or 0) * (b.qty or 0)) end,
        [4] = function(a, b) return (a.qty or 0) < (b.qty or 0) end,
    }
    local cmp = comparators[mode] or comparators[1]
    if not asc then
        local orig = cmp
        cmp = function(a, b) return orig(b, a) end
    end
    table.sort(items, cmp)
end

local function fh_sort_lavka(mode, asc)
    local list = {}
    for name, e in pairs(fh_mkt_lavka) do
        table.insert(list, {name = name, e = e})
    end
    local comparators = {
        [1] = function(a, b) return fh_lower(a.name) < fh_lower(b.name) end,
        [2] = function(a, b) return (a.e.s_avg or 0) < (b.e.s_avg or 0) end,
        [3] = function(a, b) return (a.e.b_avg or 0) < (b.e.b_avg or 0) end,
        [4] = function(a, b) return (a.e.s_scans or 0) < (b.e.s_scans or 0) end,
    }
    local cmp = comparators[mode] or comparators[1]
    if not asc then
        local orig = cmp
        cmp = function(a, b) return orig(b, a) end
    end
    table.sort(list, cmp)
    return list
end

local function fh_search_items(query, items)
    local result = {}
    if not query or query == '' then return items end
    local q = fh_prepare_text(query)
    for _, item in ipairs(items) do
        local n = fh_prepare_text(item.name or '')
        if n:find(q, 1, true) then
            table.insert(result, item)
        end
    end
    return result
end

local function fh_search_lavka(query)
    local list = {}
    for name, e in pairs(fh_mkt_lavka) do
        table.insert(list, {name = name, e = e})
    end
    return fh_search_items(query, list)
end

local function fh_search_log(query, log_table)
    local result = {}
    log_table = log_table or fh_mkt_log
    if not query or query == '' then return log_table end
    local q = fh_prepare_text(query)
    for _, entry in ipairs(log_table) do
        local s = fh_prepare_text((entry.item or '') .. ' ' .. (entry.partner or ''))
        if s:find(q, 1, true) then
            table.insert(result, entry)
        end
    end
    return result
end

local function _npb4c()
    local wd = getWorkingDirectory()
    wd = wd:gsub('\\', '/'):gsub('/$', '')
    return wd .. '/MH_chatlogs/'
end

local function _ekf6d(day, month, year)
    return string.format('%s%02d.%02d.%04d.json', _npb4c(), day, month, year)
end

local function _wjx3t()
    local dir = _npb4c()
    local ok, lfs = pcall(require, 'lfs')
    if ok then
        if not lfs.attributes(dir) then pcall(lfs.mkdir, dir) end
    else
        os.execute('mkdir "' .. dir:gsub('/', '\\') .. '" 2>nul')
    end
end

local function _vsm8w(line)
    pcall(function()
        _wjx3t()
        local t = os.date('*t')
        local path = _ekf6d(t.day, t.month, t.year)
        local enc = line:gsub('\\', '\\\\'):gsub('"', '\\"')
        local f = io.open(path, 'a')
        if f then f:write('"[' .. _onv2g() .. '] ' .. enc .. '"\n'); f:close() end
    end)
end

local function _rqh9z(day, month, year)
    local path = _ekf6d(day, month, year)
    local f = io.open(path, 'r')
    if not f then return {} end
    local lines = {}
    for raw in f:lines() do
        local s = raw:match('^"(.*)"$')
        if s then
            s = s:gsub('\\"', '"'):gsub('\\\\', '\\')
            table.insert(lines, s)
        end
    end
    f:close()
    return lines
end

local function _cby5m()
    local ok, lfs = pcall(require, 'lfs')
    if not ok then return {} end
    local dir = _npb4c()
    local dates = {}
    if not lfs.attributes(dir) then return dates end
    for entry in lfs.dir(dir) do
        local d, m, y = entry:match('^(%d%d)%.(%d%d)%.(%d%d%d%d)%.json$')
        if d then
            table.insert(dates, {label=d..'.'..m..'.'..y, day=tonumber(d), month=tonumber(m), year=tonumber(y)})
        end
    end
    table.sort(dates, function(a, b)
        if a.year  ~= b.year  then return a.year  > b.year  end
        if a.month ~= b.month then return a.month > b.month end
        return a.day > b.day
    end)
    return dates
end

fh_log_view = {
    dates    = {},   -- список {label, day, month, year}
    sel_date = nil,  -- выбранная дата
    lines    = {},   -- загруженные строки (новые первые)
}

local function _wdk4v()
    fh_log_view.dates = _cby5m()
end

local function _tjr8f()
    local v = fh_log_view
    if not v.sel_date then v.lines = {}; return end
    local raw = _rqh9z(v.sel_date.day, v.sel_date.month, v.sel_date.year)
    local lines = {}
    for i = #raw, 1, -1 do table.insert(lines, raw[i]) end
    v.lines = lines
end

-- Helper: parse sum from string
-- Поддерживает новый формат ARP: К 6.720 / КК 1 / М 2.5 / $1.234.567
-- Точка = разделитель тысяч (не десятичная), К/КК/М = валюта (не множитель)
local function _parse_trade_sum(s)
    if not s then return 0 end
    local c = tostring(s):match('^%s*(.-)%s*$') or ''
    c = c:match('^(.-)%s*%([^%)]*%)%s*$') or c
    c = c:match('^%s*(.-)%s*$') or c
    if c == '' then return 0 end
    -- Нормализация: латинские KK/K/M -> кириллические КК/К/М
    c = c:gsub('[Mm][Mm]', 'МК') -- MM->МК
    c = c:gsub('[Kk][Kk]', 'КК') -- KK->КК
    -- Safe M->\xcc: replace standalone M/m not adjacent to letters
    c = c:gsub('([^%a])([Mm])([^%a])', function(a,m,b) return a..'М'..b end)
    c = c:gsub('^([Mm])([^%a])', function(m,b) return 'М'..b end)
    c = c:gsub('([^%a])([Mm])$', function(a,m) return a..'М' end)
    if c:match('^[Mm]$') then c = 'М' end
    -- Safe K->\xca: replace standalone K/k not adjacent to letters
    c = c:gsub('([^%a])([Kk])([^%a])', function(a,k,b) return a..'К'..b end)
    c = c:gsub('^([Kk])([^%a])', function(k,b) return 'К'..b end)
    c = c:gsub('([^%a])([Kk])$', function(a,k) return a..'К' end)
    if c:match('^[Kk]$') then c = 'К' end

    -- КК N К N = millions + thousands
    do
        local kk_s, k_s = c:match('КК%s*([%d%.%,]+)%s+К%s*([%d%.%,]+)')
        if kk_s and k_s then
            local kk_num = tonumber((kk_s:gsub(',','.'))) or 0
            local k_num  = tonumber((k_s:gsub('[.,]',''))) or 0
            return math.floor(kk_num * 1000000) + k_num
        end
        -- М N К N
        local m_s, k2_s = c:match('М%s*([%d%.%,]+)%s+К%s*([%d%.%,]+)')
        if m_s and k2_s then
            local m_num  = tonumber((m_s:gsub(',','.'))) or 0
            local k2_num = tonumber((k2_s:gsub('[.,]',''))) or 0
            return math.floor(m_num * 1000000000) + k2_num
        end
        -- М N КК N
        local m2_s, kk2_s = c:match('М%s*([%d%.%,]+)%s+КК%s*([%d%.%,]+)')
        if m2_s and kk2_s then
            local m2_num  = tonumber((m2_s:gsub(',','.'))) or 0
            local kk2_num = tonumber((kk2_s:gsub(',','.'))) or 0
            return math.floor(m2_num * 1000000000) + math.floor(kk2_num * 1000000)
        end
    end

    -- Single suffix at end
    local tail = c:match('КК%s*([%d][%d%.%,]*)%s*$')
    if tail then
        tail = tail:gsub(',','.')
        local nd=0; for _ in tail:gmatch('%.') do nd=nd+1 end
        if nd > 1 then tail = tail:gsub('%.','') end
        return math.floor((tonumber(tail) or 0) * 1000000)
    end
    tail = c:match('М%s*([%d][%d%.%,]*)%s*$')
    if tail then
        tail = tail:gsub(',','.')
        local nd=0; for _ in tail:gmatch('%.') do nd=nd+1 end
        if nd > 1 then tail = tail:gsub('%.','') end
        return math.floor((tonumber(tail) or 0) * 1000000000)
    end
    tail = c:match('К%s*([%d][%d%.%,]*)%s*$')
    if tail then
        -- dot/comma = thousands separator, strip them
        if tail:find('[.,]') then
            return tonumber((tail:gsub('[.,]',''))) or 0
        else
            return (tonumber(tail) or 0) * 1000
        end
    end

    -- plain number at end of string
    c = c:match('([%d][%d%.%,]*)%s*$') or c
    c = c:gsub('^[%$]+', '')
    local ndots = 0
    for _ in c:gmatch('%.') do ndots=ndots+1 end
    if ndots > 1 then
        c = c:gsub('[.,]', '')
    elseif ndots == 1 then
        local after = c:match('%.(%d+)$')
        if after and #after == 3 then c = c:gsub('%.', '') end
    end
    c = c:gsub(',', '')
    return tonumber(c) or 0
end
local FH_TRADE_PATTERNS = {
    -- Свои сделки на лавке (другой игрок купил у вас)
    { own=true,  op='SELL', pat='([%a_]+) купил у вас (.+) %((%d+) шт%.%), вы получили .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=true,  op='SELL', pat='([%a_]+) купил у вас (.+) %((%d+) шт%.%), вы получили .-([%d][%d%.%,]*)' },
    { own=true,  op='SELL', pat='([%a_]+) купил у вас (.+), вы получили .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=true,  op='SELL', pat='([%a_]+) купил у вас (.+), вы получили .-([%d][%d%.%,]*)' },
    -- Вы купили у игрока
    { own=true,  op='BUY',  pat='Вы купили (.+) %((%d+) шт%.%) у игрока ([%a_]+) за .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=true,  op='BUY',  pat='Вы купили (.+) %((%d+) шт%.%) у игрока ([%a_]+) за .-([%d][%d%.%,]*)' },
    { own=true,  op='BUY',  pat='Вы купили (.+) у игрока ([%a_]+) за .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=true,  op='BUY',  pat='Вы купили (.+) у игрока ([%a_]+) за .-([%d][%d%.%,]*)' },
    -- Продажа в чужую лавку (торговцу)
    { own=false, op='BUY',  pat='Вы успешно продали (.+) %((%d+) шт%.%) торговцу ([%a_]+), с продажи получили .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=false, op='BUY',  pat='Вы успешно продали (.+) %((%d+) шт%.%) торговцу ([%a_]+), с продажи получили .-([%d][%d%.%,]*)' },
    { own=false, op='BUY',  pat='Вы успешно продали (.+) торговцу ([%a_]+), с продажи получили .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=false, op='BUY',  pat='Вы успешно продали (.+) торговцу ([%a_]+), с продажи получили .-([%d][%d%.%,]*)' },
    -- Покупка в чужой лавке
    { own=false, op='SELL', pat='Вы успешно купили (.+) %((%d+) шт%.%) у ([%a_]+) за .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=false, op='SELL', pat='Вы успешно купили (.+) %((%d+) шт%.%) у ([%a_]+) за .-([%d][%d%.%,]*)' },
    { own=false, op='SELL', pat='Вы успешно купили (.+) у ([%a_]+) за .-([КМ][К]?%s*[%d][%d%.%,]*%s*[КМ]?[К]?%s*[%d]?[%d%.%,]*)' },
    { own=false, op='SELL', pat='Вы успешно купили (.+) у ([%a_]+) за .-([%d][%d%.%,]*)' },
}



local function _wsn4d(text)
    if not text then return nil end
    local is_vc = text:find('VC$') ~= nil
    -- Нормализация: латинские KK/K/M -> кириллические КК/К/М перед матчингом паттернов
    text = text:gsub('[Kk][Kk]', '\xca\xca')
    text = text:gsub('[Kk](%s+[%d%.%,])', '\xca%1')
    text = text:gsub('[Mm](%s+[%d%.%,])', '\xcc%1')

    for _, p in ipairs(FH_TRADE_PATTERNS) do
        local a, b, c, d = text:match(p.pat)
        if a then
            local item, qty, partner, total
            if d then
                if p.pat:find('купил у вас') then
                    partner, item, qty, total = a, b, tonumber(c) or 1, d
                else
                    item, qty, partner, total = a, tonumber(b) or 1, c, d
                end
            else
                if p.pat:find('купил у вас') then
                    partner, item, total = a, b, c
                else
                    item, partner, total = a, b, c
                end
                qty = 1
            end
            local sum = _parse_trade_sum(total)
            local price = qty > 0 and math.ceil(sum / qty) or 0
            if item and price > 0 then
                return {
                    item    = item:match('^%s*(.-)%s*$'),
                    qty     = qty,
                    price   = price,
                    partner = partner or '',
                    op      = p.op,
                    own     = p.own,
                    is_vc   = is_vc,
                }
            end
        end
    end
    return nil
end

local function fh_merge_by_date(sell_arr, buy_arr)
    local map = {}
    for _, entry in ipairs(sell_arr or {}) do
        local d = entry.dateCreate__date or entry.date or ''
        map[d] = map[d] or {}
        map[d].sell = entry
    end
    for _, entry in ipairs(buy_arr or {}) do
        local d = entry.dateCreate__date or entry.date or ''
        map[d] = map[d] or {}
        map[d].buy = entry
    end
    local result = {}
    for date, v in pairs(map) do
        table.insert(result, {date=date, sell=v.sell, buy=v.buy})
    end
    table.sort(result, function(a, b) return a.date > b.date end)
    return result
end

local function _btm6q(name, preset)
    for i, item in ipairs(preset) do
        if fh_lower(item.name or '') == fh_lower(name or '') then
            return item, i
        end
    end
    return nil, nil
end

local function _qmh2p(name, qty, price)
    if _btm6q(name, fh_lv_autosell_preset) then return false end
    table.insert(fh_lv_autosell_preset, {
        name  = name,
        qty   = tonumber(qty) or 1,
        price = tonumber(price) or 0,
    })
    local new_idx = #fh_lv_autosell_preset
    if _G.as_price_buf then _G.as_price_buf[new_idx] = nil end
    if _G.as_qty_buf   then _G.as_qty_buf[new_idx]   = nil end
    return true
end

local function _sbn6y(name, qty, max_price)
    if _btm6q(name, fh_lv_autobuy_preset) then return false end
    table.insert(fh_lv_autobuy_preset, {
        name      = name,
        qty       = tonumber(qty) or 1,
        max_price = tonumber(max_price) or 0,
    })
    _G.ab_price_buf = nil; _G.ab_qty_buf = nil
    return true
end

local function _lwf4z(preset, idx)
    table.remove(preset, idx)
    if _G.as_price_buf then
        local nb = {}
        for i, v in pairs(_G.as_price_buf) do
            if type(i)=='number' then
                if i < idx then nb[i]=v elseif i > idx then nb[i-1]=v end
            end
        end
        _G.as_price_buf = nb
    end
    if _G.as_qty_buf then
        local nb = {}
        for i, v in pairs(_G.as_qty_buf) do
            if type(i)=='number' then
                if i < idx then nb[i]=v elseif i > idx then nb[i-1]=v end
            end
        end
        _G.as_qty_buf = nb
    end
    _G.ab_price_buf = nil; _G.ab_qty_buf = nil
end

local function _xtv8g(preset)
    for i = #preset, 1, -1 do table.remove(preset, i) end
    _G.as_price_buf = nil; _G.as_qty_buf = nil
    _G.ab_price_buf = nil; _G.ab_qty_buf = nil
end

local function _ryc4z(name)
    local lv = fh_mkt_lavka[name]
    if lv and (lv.s_avg or lv.b_avg) then
        return lv.s_avg or lv.b_avg
    end
    local cp = fh_mkt_prices[name]
    if cp then
        if cp.cp_hist and #cp.cp_hist > 0 then
            local s = _mjg5t(cp.cp_hist, 7)
            if s then return s.avg end
        end
        if cp.s_avg or cp.b_avg then return cp.s_avg or cp.b_avg end
    end
    return fh_get_daily_avg_price(name)
end

local function fh_is_my_sell(e)
    local op = (e.op or ''):upper()
    local own = e.own
    if own == true  then return op == 'SELL' end
    if own == false then return op == 'BUY'  end
    return op == 'SELL'  -- fallback
end

local function _qbs9k()
    local d  = settings.general.custom_dpi
    local bg = settings.interface.bg_brightness or 0.06
    local ar = settings.interface.accent_r or 1
    local ag = settings.interface.accent_g or 0.55
    local ab = settings.interface.accent_b or 0.0
    local sb_r = settings.interface.sell_btn_r or 0.10
    local sb_g = settings.interface.sell_btn_g or 0.45
    local sb_b = settings.interface.sell_btn_b or 0.10
    local bb_r = settings.interface.buy_btn_r  or 0.00
    local bb_g = settings.interface.buy_btn_g  or 0.28
    local bb_b = settings.interface.buy_btn_b  or 0.50
    local lp_r = settings.overlay and settings.overlay.log_price_r or 1.0
    local lp_g = settings.overlay and settings.overlay.log_price_g or 0.85
    local lp_b = settings.overlay and settings.overlay.log_price_b or 0.2
    -- cache fa icons to avoid __index stack overflow per frame
    local _ic_up    = fa.ARROW_UP;      local _ic_dn    = fa.ARROW_DOWN
    local _ic_lt    = fa.ARROW_LEFT;    local _ic_rt    = fa.ARROW_RIGHT
    local _ic_ll    = fa.ANGLES_LEFT;   local _ic_rr    = fa.ANGLES_RIGHT
    local _ic_al    = fa.ANGLE_LEFT;    local _ic_ar    = fa.ANGLE_RIGHT
    local _ic_ban   = fa.BAN;           local _ic_bolt  = fa.BOLT
    local _ic_boxes = fa.BOXES_STACKED; local _ic_arch  = fa.BOX_ARCHIVE
    local _ic_cal   = fa.CALENDAR;      local _ic_cald  = fa.CALENDAR_DAY
    local _ic_calds = fa.CALENDAR_DAYS; local _ic_calw  = fa.CALENDAR_WEEK
    local _ic_car   = fa.CAR;           local _ic_cart  = fa.CART_SHOPPING
    local _ic_chrtl = fa.CHART_LINE;    local _ic_chrts = fa.CHART_SIMPLE
    local _ic_chk   = fa.CHECK;         local _ic_circ  = fa.CIRCLE
    local _ic_circc = fa.CIRCLE_CHECK;  local _ic_circi = fa.CIRCLE_INFO
    local _ic_circp = fa.CIRCLE_PLUS;   local _ic_circs = fa.CIRCLE_STOP
    local _ic_clk   = fa.CLOCK;         local _ic_cld   = fa.CLOUD
    local _ic_coin  = fa.COINS;         local _ic_gps   = fa.CROSSHAIRS
    local _ic_dl    = fa.DOWNLOAD;      local _ic_eye   = fa.EYE
    local _ic_fimp  = fa.FILE_IMPORT;   local _ic_flt   = fa.FILTER
    local _ic_save  = fa.FLOPPY_DISK;   local _ic_gear  = fa.GEAR
    local _ic_lyr   = fa.LAYER_GROUP;   local _ic_lxh   = fa.LOCATION_CROSSHAIRS
    local _ic_mgnt  = fa.MAGNET;        local _ic_srch  = fa.MAGNIFYING_GLASS
    local _ic_map   = fa.MAP_LOCATION_DOT; local _ic_min = fa.MINUS
    local _ic_paus  = fa.PAUSE;         local _ic_pen   = fa.PEN_TO_SQUARE
    local _ic_phone = fa.PHONE;         local _ic_rot   = fa.ROTATE_RIGHT
    local _ic_scl   = fa.SCALE_BALANCED; local _ic_star = fa.STAR
    local _ic_store = fa.STORE;         local _ic_tag   = fa.TAG
    local _ic_trash = fa.TRASH_CAN;     local _ic_warn  = fa.TRIANGLE_EXCLAMATION
    local _ic_ul    = fa.UPLOAD;        local _ic_wh    = fa.WAREHOUSE
    local _ic_x     = fa.XMARK;         local _ic_alr   = fa.ARROWS_LEFT_RIGHT


    if not _G.mkt_srch      then _G.mkt_srch      = imgui.new.char[256]('') end
    if not _G.mkt_srch_s    then _G.mkt_srch_s    = '' end
    if not _G.mkt_lv_srch   then _G.mkt_lv_srch   = imgui.new.char[256]('') end
    if not _G.mkt_lv_ss     then _G.mkt_lv_ss     = '' end
    if not _G.mkt_log_f     then _G.mkt_log_f     = imgui.new.char[128](''); _G.mkt_log_fs = '' end
    if not _G.mkt_cp_page   then _G.mkt_cp_page   = 1 end
    if not _G.mkt_lv_page   then _G.mkt_lv_page   = 1 end
    if not _G.mkt_log_f2    then _G.mkt_log_f2    = imgui.new.char[128](''); _G.mkt_log_fs2 = '' end
    if not _G.mkt_log_page  then _G.mkt_log_page  = 1 end
    if not _G.mkt_cp_filter then _G.mkt_cp_filter = 0 end  -- 0=все 1=только с историей
    if not _G.mkt_cp_sort   then _G.mkt_cp_sort   = 0 end  -- 0=Последние продажи 1=Прод.30д 2=Цена 3=А-Я
    local cw = imgui.GetWindowContentRegionWidth()

    if _G.mh_tab == 1 then
        if imgui.BeginTabBar('##market_subtabs') then
        if imgui.BeginTabItem(_ic_chrtl..' '..u8'Рынок##sub_market') then
        -- Кэшируем cp_tot чтобы не перебирать всё fh_mkt_prices каждый кадр
        local _mkt_data_ver = _G._mh_db_ver or 0
        if _G._mkt_cp_tot_ver ~= _mkt_data_ver then
            _G._mkt_cp_tot_ver  = _mkt_data_ver
            _G._mkt_cp_tot_c    = 0
            _G._mkt_cp_deep_c   = 0
            for _, e in pairs(fh_mkt_prices) do
                _G._mkt_cp_tot_c = _G._mkt_cp_tot_c + 1
                if e.cp_hist and #e.cp_hist > 0 then _G._mkt_cp_deep_c = _G._mkt_cp_deep_c + 1 end
            end
            _G.mkt_cp_cache_srch = nil
            -- НЕ вызываем _mh_db_bump() здесь — это создаёт бесконечную петлю!
            -- Сброс кэша списка произойдёт через cache_key при следующем рендере
        end
        local cp_tot   = _G._mkt_cp_tot_c  or 0
        local deep_tot = _G._mkt_cp_deep_c or 0

        local scan_active   = fh_mkt_cp_scanning or fh_mkt_cp_deep_scanning
        local autosell_on   = settings.autosell and settings.autosell.enabled
        local autobuy_off   = not (settings.autobuy and settings.autobuy.enabled)
        local dot_g = imgui.ImVec4(0.20, 0.90, 0.35, 1)
        local dot_y = imgui.ImVec4(0.95, 0.75, 0.10, 1)
        local dot_d = imgui.ImVec4(0.30, 0.28, 0.22, 1)
        if fh_mkt_cp_deep_scanning then
            imgui.Spacing()
            local done = fh_mkt_cp_deep_done or 0
            imgui.TextColored(dot_g, _cyr5f('\xd1\xca\xc0\xcd\xc8\xd0\xce\xc2\xc0\xcd\xc8\xc5: ' .. done .. '/' .. cp_tot))
            local _stop_w = 65*d
            imgui.SameLine(0,10*d)
            imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(imgui.GetContentRegionAvail().x - _stop_w - 8*d, 8*d))
            imgui.SameLine(0,8*d)
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.65,0.15,0.10,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.80,0.20,0.15,1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.90,0.25,0.20,1))
            if imgui.Button(u8'СТОП##cpdeepstop', imgui.ImVec2(_stop_w, 0)) then
                fh_mkt_cp_deep_scanning = false
            end
            imgui.PopStyleColor(3)
            imgui.Spacing()
        elseif fh_mkt_cp_scanning then
            imgui.Spacing()
            imgui.TextColored(dot_g, _cyr5f('\xd1\xca\xc0\xcd\xc8\xd0\xce\xc2\xc0\xcd\xc8\xc5 (' .. cp_tot .. ')'))
            imgui.SameLine(0,10*d); imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(imgui.GetContentRegionAvail().x, 8*d))
            imgui.Spacing()
        end

        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(ar*0.7, ag*0.7, ab*0.7, 1), _ic_srch)
        imgui.SameLine(0, 6*d)
        -- Поле поиска: растягивается на всю строку минус крестик
        local _cp_srch_w = cw - 140*d  -- место для крестика рядом
        imgui.PushItemWidth(_cp_srch_w)
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(bg+.08,bg+.07,bg+.04,1))
        if imgui.InputTextWithHint(u8'##cp_srch', _cyr5f('Поиск товара...'), _G.mkt_srch, 256) then
            do
                local _r = u8:decode(ffi.string(_G.mkt_srch))
                local _ok,_cp = pcall(function() return require('encoding').CP1251:encode(_r) end)
                local _s = (_ok and _cp or _r):lower()
                _G.mkt_srch_s = _s:gsub('[А-Я]',function(c) return string.char(string.byte(c)+32) end)
            end
            _G.mkt_cp_page = 1
            _G.mkt_cp_cache_srch = nil; _G._mkt_trend_cache = nil
        end
        imgui.PopStyleColor(); imgui.PopItemWidth()
        imgui.SameLine(0, 3*d)
        -- Крестик очистить поиск
        local _has_cp_srch = ffi.string(_G.mkt_srch) ~= ''
        imgui.PushStyleColor(imgui.Col.Button, _has_cp_srch
            and imgui.ImVec4(0.38,0.08,0.08,1) or imgui.ImVec4(0.12,0.12,0.12,1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55,0.12,0.12,1))
        imgui.PushStyleColor(imgui.Col.Text, _has_cp_srch
            and imgui.ImVec4(1,0.4,0.4,1) or imgui.ImVec4(0.3,0.3,0.3,1))
        if imgui.Button(_ic_x..'##cpsrchclr', imgui.ImVec2(28*d, 0)) and _has_cp_srch then
            ffi.fill(_G.mkt_srch, 256, 0)
            _G.mkt_srch_s = ''; _G.mkt_cp_page = 1; _G.mkt_cp_cache_srch = nil; _G._mkt_trend_cache = nil
        end
        imgui.PopStyleColor(3)
        local filter_active = _G.mkt_cp_filter == 1
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            if filter_active then
                imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), u8'\xd4\xc8\xcb\xd2\xd0: \xd2\xce\xc2\xc0\xd0\xdb \xd1 \xc8\xd1\xd2\xce\xd0\xc8\xc5\xc9 \xd6\xc5\xcd')
                imgui.TextDisabled(u8'\xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xfe\xf2\xf1\xff \xf2\xee\xeb\xfc\xea\xee \xf2\xee\xe2\xe0\xf0\xfb \xf1 \xe8\xf1\xf2\xee\xf0\xe8\xe5\xe9')
            else
                imgui.TextColored(imgui.ImVec4(0.65,0.65,0.65,1), u8'\xd4\xc8\xcb\xd2\xd0: \xc2\xd1\xc5 \xd2\xce\xc2\xc0\xd0\xdb')
                imgui.TextDisabled(u8'\xcf\xee\xea\xe0\xe7\xfb\xe2\xe0\xfe\xf2\xf1\xff \xe2\xf1\xe5 \xf2\xee\xe2\xe0\xf0\xfb')
            end
            imgui.TextDisabled(u8'\xcd\xe0\xe6\xec\xe8\xf2\xe5 \xe4\xeb\xff \xef\xe5\xf0\xe5\xea\xeb\xfe\xf7\xe5\xed\xe8\xff')
            imgui.EndTooltip()
        end
        if filter_active then imgui.PopStyleColor(3) end
        imgui.Spacing()
        local sort_labels = {
            u8'\xcf\xce\xd1\xcb\xc5\xc4\xcd\xc8\xc5##s0',
            u8'30 \xc4\xcd\xc5\xc9##s1',
            u8'\xd6\xc5\xcd\xc0##s2',
            u8'\xc0-\xdf##s3',
        }
        local sw4 = (cw - 18*d) / 4
        for si = 0, 3 do
            if si > 0 then imgui.SameLine(0, 6*d) end
            local is_active = (_G.mkt_cp_sort == si)
            if is_active then
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(ar*0.6, ag*0.6, ab*0.6, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar*0.8, ag*0.8, ab*0.8, 1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(ar, ag, ab, 1))
            end
            if imgui.Button(sort_labels[si+1], imgui.ImVec2(sw4, 0)) then
                _G.mkt_cp_sort = si
                _G.mkt_cp_cache_srch = nil; _G._mkt_trend_cache = nil
                _G.mkt_cp_page = 1
            end
            if is_active then imgui.PopStyleColor(3) end
        end
        imgui.Separator()

        if not _G.mkt_cp_cache_srch then _G.mkt_cp_cache_srch = nil; _G._mkt_trend_cache = nil end
        if not _G.mkt_cp_cache_list then _G.mkt_cp_cache_list = {} end
        local srch = _G.mkt_srch_s or ''
        -- data_ver включён чтобы список перестраивался при новых данных,
        -- но сброс страницы происходит ТОЛЬКО при смене фильтра/поиска (не при data_ver)
        local _cur_data_ver = _G._mh_db_ver or 0
        local cache_key = srch .. '|' .. (_G.mkt_cp_filter or 0) .. '|' .. (_G.mkt_cp_sort or 0)
        local cache_key_full = cache_key .. '|' .. _cur_data_ver
        local _page_reset_needed = (_G.mkt_cp_cache_srch ~= cache_key)  -- только при смене фильтра/поиска
        if _G._mkt_cp_cache_full_key ~= cache_key_full then
            _G._mkt_cp_cache_full_key = cache_key_full
            _G.mkt_cp_cache_srch = cache_key  -- фиксируем фильтровый ключ
            local mf_new = {}
            local _filt = _G.mkt_cp_filter or 0
            local _sort = _G.mkt_cp_sort or 0
            local _min_p = (_bcn4w() and settings.market_filters and settings.market_filters.min_price) or 0
            local _tup   = _bcn4w() and settings.market_filters and settings.market_filters.trend_up_only
            -- Кэш нижнего регистра имён (CP1251-aware) — строим один раз при смене данных
            local _mkt_data_ver_lo = _G._mh_db_ver or 0
            if not _G._mkt_nm_lo_cache or _G._mkt_nm_lo_cache_ver ~= _mkt_data_ver_lo then
                _G._mkt_nm_lo_cache_ver = _mkt_data_ver_lo
                _G._mkt_nm_lo_cache = {}
                for nm2, _ in pairs(fh_mkt_prices) do
                    if type(nm2) == 'string' then
                        _G._mkt_nm_lo_cache[nm2] = nm2:lower():gsub('[А-Я]', function(c)
                            return string.char(string.byte(c)+32)
                        end)
                    end
                end
            end
            local _nm_lo_cache = _G._mkt_nm_lo_cache
            -- Кэш тренда: вычисляем _xvn2w только если нужно и только один раз
            if not _G._mkt_trend_cache then _G._mkt_trend_cache = {} end
            local _trd_cache = _G._mkt_trend_cache
            for nm, e in pairs(fh_mkt_prices) do
                if type(nm)=='string' and type(e)=='table' then
                    local has_deep = e.cp_hist and #e.cp_hist > 0
                    if _filt == 1 and not has_deep then goto mf_skip end
                    if srch ~= '' then
                        local nm_lo = _nm_lo_cache[nm] or nm:lower()
                        if not nm_lo:find(srch, 1, true) then goto mf_skip end
                    end
                    if not has_deep and not e.s_avg and not e.b_avg then goto mf_skip end
                    if _min_p > 0 then
                        local _chk_p = (has_deep and e.cp_hist[1].price) or e.cp_sp or e.s_avg or 0
                        if _chk_p < _min_p then goto mf_skip end
                    end
                    if _tup then
                        if not (e.cp_hist and #e.cp_hist >= 4) then goto mf_skip end
                        if not _trd_cache[nm] then
                            _trd_cache[nm] = _xvn2w(e.cp_hist)
                        end
                        local _trd = _trd_cache[nm]
                        if not (type(_trd)=='table' and _trd.is_up) then goto mf_skip end
                    end
                    table.insert(mf_new, {nm=nm, e=e})
                    ::mf_skip::
                end
            end
            if _sort == 0 then
                table.sort(mf_new, function(a, b)
                    local da = (a.e.cp_hist and a.e.cp_hist[1] and a.e.cp_hist[1].dt) or ''
                    local db = (b.e.cp_hist and b.e.cp_hist[1] and b.e.cp_hist[1].dt) or ''
                    if da ~= db then return da > db end
                    return a.nm < b.nm
                end)
            elseif _sort == 1 then
                table.sort(mf_new, function(a, b)
                    local qa = a.e.s_totalC or 0; local qb = b.e.s_totalC or 0
                    if qa ~= qb then return qa > qb end; return a.nm < b.nm
                end)
            elseif _sort == 2 then
                table.sort(mf_new, function(a, b)
                    local pa = a.e.s_avg or 0; local pb = b.e.s_avg or 0
                    if pa ~= pb then return pa > pb end; return a.nm < b.nm
                end)
            else
                table.sort(mf_new, function(a, b) return a.nm < b.nm end)
            end
            _G.mkt_cp_cache_list = mf_new
            -- Сбрасываем страницу ТОЛЬКО если изменился фильтр/поиск, а не просто данные
            if _page_reset_needed then
                _G.mkt_cp_page = 1
            end
        end
        -- Сброс кэша тренда при обновлении данных
        local _mkt_ver2 = tostring(_G._mh_db_ver or 0)
        if _G._mkt_trend_cache_ver ~= _mkt_ver2 then
            _G._mkt_trend_cache_ver = _mkt_ver2
            _G._mkt_trend_cache = {}
        end
        local mf = _G.mkt_cp_cache_list
        local MKT_PAGE_SIZE = 50
        local cp_pages = math.max(1, math.ceil(#mf / MKT_PAGE_SIZE))
        if _G.mkt_cp_page > cp_pages then _G.mkt_cp_page = cp_pages end
        local cp_from = (_G.mkt_cp_page-1)*MKT_PAGE_SIZE+1
        local cp_to   = math.min(_G.mkt_cp_page*MKT_PAGE_SIZE, #mf)

        do
            if not _G.mkt_minp then _G.mkt_minp = imgui.new.int(settings.market_filters and settings.market_filters.min_price or 0) end
            if not _G.mkt_tup  then _G.mkt_tup  = imgui.new.bool(settings.market_filters and settings.market_filters.trend_up_only or false) end
            imgui.TextDisabled(_cyr5f('Мин. цена $:'))
            imgui.SameLine(0,6*d)
            imgui.PushItemWidth(110*d)
            if imgui.InputInt('##mkt_minp', _G.mkt_minp, 0, 0) then
                if _G.mkt_minp[0] < 0 then _G.mkt_minp[0] = 0 end
                settings.market_filters.min_price = _G.mkt_minp[0]; _wfn7p()
            end
            imgui.PopItemWidth()
            imgui.SameLine(0,12*d)
            if imgui.Checkbox(_ic_up..' '.._cyr5f('Тренд вверх##mkt_tup'), _G.mkt_tup) then
                settings.market_filters.trend_up_only = _G.mkt_tup[0]; _wfn7p()
            end
            imgui.SameLine(0, 14*d)
            -- Кнопка: скачать цены с облака
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.05,0.22,0.48,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.08,0.35,0.72,1))
            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.55,0.85,1,1))
            local _pull_lbl = fa.DOWNLOAD..' '.._cyr5f('\xd6\xe5\xed\xfb ##mkt_pricepull')
            if imgui.Button(_pull_lbl, imgui.ImVec2(0, 0)) then
                _mh_prices_pull(false)
            end
            local _pull_lbl = fa.DOWNLOAD..' '.._cyr5f('Цены ##mkt_pricepull')
            if imgui.IsItemHovered() then
                local _srv_nm = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or 1] or {}).name or '?'
                local _srv_id = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or 1] or {}).id or -1
                imgui.SetTooltip(_cyr5f('Загрузить цены ЦР с облака\n'.._srv_nm..' (id='.._srv_id..')'))
            end
            imgui.SameLine(0, 6*d)
            -- Кнопка: выгрузить цены на облако
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.05,0.30,0.10,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.08,0.50,0.16,1))
            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.55,1,0.60,1))
            local _push_lbl = fa.UPLOAD..' '.._cyr5f('\xd6\xe5\xed\xfb ##mkt_pricepush')
            if imgui.Button(_push_lbl, imgui.ImVec2(0, 0)) then
                _mh_prices_push()
            end
            local _push_lbl = fa.UPLOAD..' '.._cyr5f('Цены ##mkt_pricepush')
            if imgui.IsItemHovered() then
                local _srv_nm2 = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or 1] or {}).name or '?'
                local _srv_id2 = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or 1] or {}).id or -1
                imgui.SetTooltip(_cyr5f('Выгрузить цены ЦР на облако\n'.._srv_nm2..' (id='.._srv_id2..')'))
            end
            imgui.Spacing()
        end
        local list_h = imgui.GetWindowHeight() - imgui.GetCursorPosY() - 85*d
        if imgui.BeginChild('##cp_list', imgui.ImVec2(-1, list_h), true) then
            _dpn1w()  -- swipe scroll
            imgui.Columns(8, '##cphdr', false)
            local _cw_total = imgui.GetWindowContentRegionWidth()
            local _cw_qty   = math.floor(_cw_total * 0.048)   -- ШТ (x3)
            local _cw_price = math.floor(_cw_total * 0.158)   -- СЕГОДНЯ/7Д/30Д (x3)
            local _cw_trend = math.floor(_cw_total * 0.120)   -- ТРЕНД
            local _cw_nm    = _cw_total - (_cw_price+_cw_qty)*3 - _cw_trend
            imgui.SetColumnWidth(0, _cw_nm)
            imgui.SetColumnWidth(1, _cw_price)
            imgui.SetColumnWidth(2, _cw_qty)
            imgui.SetColumnWidth(3, _cw_price)
            imgui.SetColumnWidth(4, _cw_qty)
            imgui.SetColumnWidth(5, _cw_price)
            imgui.SetColumnWidth(6, _cw_qty)
            imgui.SetColumnWidth(7, _cw_trend)
            local hc = imgui.ImVec4(0.42, 0.40, 0.32, 1)
            local hca = imgui.ImVec4(ar*0.85, ag*0.85, ab*0.85, 1)
            imgui.TextColored(hca, u8'  \xd2\xce\xc2\xc0\xd0'); imgui.NextColumn()
            imgui.TextColored(hca, u8' \xd1\xc5\xc3\xce\xc4\xcd\xdf'); imgui.NextColumn()
            imgui.TextColored(hc,  u8' \xd8\xd2.'); imgui.NextColumn()
            imgui.TextColored(hca, u8' 7\xc4'); imgui.NextColumn()
            imgui.TextColored(hc,  u8' \xd8\xd2.'); imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0.35,0.90,0.40,1), u8' 30\xc4'); imgui.NextColumn()
            imgui.TextColored(hc,  u8' \xd8\xd2.'); imgui.NextColumn()
            imgui.TextColored(hc, _ic_chrts..' '.._cyr5f(' \xd2\xd0\xc5\xcd\xc4')); imgui.NextColumn()
            imgui.Separator()

            if #mf == 0 then
                imgui.TextDisabled(u8'  База пуста. Запустите скан на чекпоинте.')
                for _=1,7 do imgui.NextColumn() end
            end

            for ri = cp_from, cp_to do
                local r = mf[ri]; if not r then break end
                local e = r.e
                local hist = e.cp_hist
                local has_deep = hist and #hist > 0

                local today_price = nil
                local s7, s30, _today_s_cached, _trd_cached
                -- _mh_get_mkt_price: today = текущие лавки + данные за сегодня (= "День" в карточке)
                local _mp_row = _mh_get_mkt_price(r.nm)
                if _mp_row then
                    -- today_price = строка "День" карточки (только текущие лавки + сегодня)
                    -- avg7/avg30 используются только для колонок 7д/30д
                    today_price = (_mp_row.today and _mp_row.today > 0) and _mp_row.today or nil
                    -- fallback: avg7 только если today совсем пустой (нет живых лавок и нет данных сегодня)
                    if not today_price then
                        today_price = (_mp_row.avg7 and _mp_row.avg7 > 0) and _mp_row.avg7 or nil
                    end
                    s7  = _mp_row.avg7  and {avg=_mp_row.avg7}  or nil
                    s30 = _mp_row.avg30 and {avg=_mp_row.avg30} or nil
                end
                -- Продано: из cp_hist (количество)
                if has_deep then
                    local _row_anchor = today_price
                    s7, s30, _today_s_cached, _trd_cached = _cached_stats(hist, _row_anchor)
                    -- Перезаписываем avg из _mh_get_mkt_price чтобы цена была единой
                    if _mp_row then
                        if _mp_row.avg7  then s7  = {avg=_mp_row.avg7,  qty=s7  and s7.qty  or nil} end
                        if _mp_row.avg30 then s30 = {avg=_mp_row.avg30, qty=s30 and s30.qty or nil} end
                    end
                end
                -- Fallback if market price empty
                if not today_price then
                    if e.cp_sp and e.cp_sp > 0 then today_price = e.cp_sp
                    elseif e.s_avg and e.s_avg > 0 then today_price = e.s_avg end
                end
                if not s7  and e.s_avg then s7  = {avg=e.s_avg} end
                if not s30 and e.s_avg then s30 = {avg=e.s_avg, min=e.s_min, max=e.s_max, qty=e.s_totalC or 0} end

                local _trd = _trd_cached or {icon=_ic_min, text='', is_neutral=true}
                local tc = _pdf8k(_trd)

                do
                      local _rsp  = imgui.GetCursorScreenPos()
                      local _rlh  = imgui.GetTextLineHeight()
                      local _itag_mk = mh_get_item_tag(r.nm or '')
                      local _tag_px = ''
                      if _itag_mk == 'watch' then _tag_px = fa.EYE..' '
                      elseif _itag_mk == 'skip' then _tag_px = fa.BAN..' '
                      elseif _itag_mk == 'fav'  then _tag_px = fa.STAR..' ' end
                      _rstr = _tag_px.._cyr5f('  ' .. (r.nm or ''))
                      local _rtw  = imgui.CalcTextSize(_rstr).x
                      local _rnm_c32 = has_deep and 0xFFFFFFFF or 0xFFBFBFBF
                      if _itag_mk == 'fav'  then _rnm_c32 = 0xFFD9C41A
                      elseif _itag_mk == 'watch' then _rnm_c32 = 0xFFD9BE6A
                      elseif _itag_mk == 'skip' then _rnm_c32 = 0xFF7A7A7A end
                      local _rcw  = 180*d - 6
                      imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0,0,0,0))
                      if imgui.Selectable('##cp'..ri, false,
                          imgui.SelectableFlags.SpanAllColumns + imgui.SelectableFlags.AllowDoubleClick,
                          imgui.ImVec2(0, 0)) then
                          _G.mkt_detail_item = r.nm
                          _G.mkt_detail_src  = 'cp'
                          _G.mkt_detail_open = true
                      end
                      imgui.PopStyleColor()
                      local _rdl = imgui.GetWindowDrawList()
                      _rdl:PushClipRect(_rsp, imgui.ImVec2(_rsp.x + _rcw, _rsp.y + _rlh + 2), true)
                      local _roff = 0
                      if _rtw > _rcw then
                          local _rsd  = _rtw - _rcw + 8
                          local _rspd = 1.5
                          local _rspt = _rsd / 40 + 2 * _rspd
                          local _rph  = math.fmod(imgui.GetTime() + ri * 0.53, _rspt)
                          if _rph > _rspd then _roff = math.min((_rph - _rspd) * 40, _rsd) end
                          if _rph >= _rspt - _rspd then _roff = _rsd end
                      end
                      _rdl:AddText(imgui.ImVec2(_rsp.x - _roff, _rsp.y), _rnm_c32, _rstr)
                      _rdl:PopClipRect()
                  end
                  imgui.NextColumn()

                if today_price then
                    imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), _cyr5f(' $'.._kcr3y(today_price)))
                else
                    imgui.TextDisabled(u8' —')
                end
                imgui.NextColumn()

                local _today_s = _today_s_cached
                local today_qty = _today_s and _today_s.qty or nil
                if today_qty and today_qty > 0 then
                    imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1), _cyr5f(' '.._kcr3y(today_qty)))
                else
                    imgui.TextDisabled(u8' —')
                end
                imgui.NextColumn()

                if s7 then
                    imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), _cyr5f(' $'.._kcr3y(s7.avg)))
                else
                    imgui.TextDisabled(u8' —')
                end
                imgui.NextColumn()

                if s7 and s7.qty and s7.qty > 0 then
                    imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1), _cyr5f(' '.._kcr3y(s7.qty)))
                else
                    imgui.TextDisabled(u8' —')
                end
                imgui.NextColumn()

                if s30 then
                    imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f(' $'.._kcr3y(s30.avg)))
                else
                    imgui.TextDisabled(u8' —')
                end
                imgui.NextColumn()

                if s30 and s30.qty and s30.qty > 0 then
                    imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1), _cyr5f(' '.._kcr3y(s30.qty)))
                else
                    imgui.TextDisabled(u8' —')
                end
                imgui.NextColumn()

                imgui.TextColored(tc, _trd.icon..' '.._cyr5f(_trd.text))
                imgui.NextColumn()
            end
            imgui.Columns(1)
            imgui.EndChild()
        end

        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        local pw = 38*d
        if imgui.Button(u8'\xab##cpp',  imgui.ImVec2(pw,0)) then _G.mkt_cp_page=1 end
        imgui.SameLine(0,4*d)
        if imgui.Button(u8'\xab##cppr',  imgui.ImVec2(pw,0)) then if _G.mkt_cp_page>1 then _G.mkt_cp_page=_G.mkt_cp_page-1 end end
        imgui.SameLine(0,10*d)
        imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f(_G.mkt_cp_page..'/'..cp_pages))
        imgui.SameLine(0,4*d)
        imgui.TextColored(imgui.ImVec4(0.40,0.38,0.30,1), _cyr5f('('..#mf..' \xf2\xee\xe2\xe0\xf0\xee\xe2)'))
        imgui.SameLine(0,10*d)
        if imgui.Button(u8'\xbb##cpnx',  imgui.ImVec2(pw,0)) then if _G.mkt_cp_page<cp_pages then _G.mkt_cp_page=_G.mkt_cp_page+1 end end
        imgui.SameLine(0,4*d)
        if imgui.Button(u8'\xbb##cpls', imgui.ImVec2(pw,0)) then _G.mkt_cp_page=cp_pages end
        imgui.Spacing()
        imgui.EndTabItem()
        end -- end sub-tab Рынок##sub_market

        if imgui.BeginTabItem(_ic_car..' '..u8'Автомобили##sub_auto') then
            local cw_a = imgui.GetWindowContentRegionWidth()
            if not _G.mkt_auto_srch    then _G.mkt_auto_srch    = imgui.new.char[256]('') end
            if not _G.mkt_auto_srch_s  then _G.mkt_auto_srch_s  = '' end
            if not _G.mkt_auto_page    then _G.mkt_auto_page    = 1 end
            if not _G.mkt_auto_sort    then _G.mkt_auto_sort    = 0 end
            if not _G.mkt_auto_cache_k then _G.mkt_auto_cache_k = nil end
            if not _G.mkt_auto_cache_l then _G.mkt_auto_cache_l = {} end

            local auto_tot = 0; for _ in pairs(fh_mkt_auto) do auto_tot = auto_tot + 1 end

            if fh_mkt_auto_scanning then
                imgui.TextColored(imgui.ImVec4(1,0.75,0,1),
                    _cyr5f('  Скан авторынка... стр. ' .. fh_mkt_auto_page))
                imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(-1, 6*d))
            elseif fh_mkt_auto_deep_scanning then
                imgui.TextColored(imgui.ImVec4(1,0.55,0,1),
                    _cyr5f('  Угл. скан... ' .. fh_mkt_auto_deep_done .. ' авто'))
                imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(-1, 6*d))
                if imgui.Button(_ic_circs..' '.._cyr5f('Стоп гл. скан##autodeepstop'), imgui.ImVec2(-1,0)) then
                    fh_mkt_auto_deep_scanning = false
                end
            else
                local upd_a = fh_mkt_auto_last_upd or '—'
                imgui.TextDisabled(_cyr5f('  Авто: ' .. auto_tot .. ' | Обновлено: ' .. upd_a))
                imgui.TextDisabled(u8'  Путь: /gps > Поиск > Авторынок — откройте список авто')
            end

            imgui.Spacing()
            imgui.PushItemWidth(cw_a - 6*d)
            if imgui.InputText(u8'##auto_srch', _G.mkt_auto_srch, 256) then
                _G.mkt_auto_srch_s = u8:decode(ffi.string(_G.mkt_auto_srch)):lower()
                _G.mkt_auto_page = 1; _G.mkt_auto_cache_k = nil
            end
            imgui.PopItemWidth()

            imgui.Spacing()
            local auto_sort_labels = { u8'Цена(уб.)##as0', u8'Цена(воз.)##as1', u8'А-Я##as2' }
            local sw3 = (cw_a - 12*d) / 3
            for si = 0, 2 do
                if si > 0 then imgui.SameLine(0, 6*d) end
                local is_act = (_G.mkt_auto_sort == si)
                if is_act then
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar*0.6, ag*0.6, ab*0.6, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar*0.8, ag*0.8, ab*0.8, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(ar, ag, ab, 1))
                end
                if imgui.Button(auto_sort_labels[si+1], imgui.ImVec2(sw3, 0)) then
                    _G.mkt_auto_sort = si; _G.mkt_auto_cache_k = nil; _G.mkt_auto_page = 1
                end
                if is_act then imgui.PopStyleColor(3) end
            end
            imgui.Separator()

            local auto_srch = _G.mkt_auto_srch_s or ''
            local auto_ck = auto_srch .. '|' .. (_G.mkt_auto_sort or 0)
            if _G.mkt_auto_cache_k ~= auto_ck then
                _G.mkt_auto_cache_k = auto_ck
                local al = {}
                for nm, e in pairs(fh_mkt_auto) do
                    if type(nm)=='string' and type(e)=='table' then
                        if auto_srch=='' or nm:lower():find(auto_srch,1,true) then
                            if e.s_avg or e.cp_sp then table.insert(al, {nm=nm,e=e}) end
                        end
                    end
                end
                local sm = _G.mkt_auto_sort or 0
                if sm == 0 then
                    table.sort(al, function(a,b)
                        local pa=(a.e.s_avg or a.e.cp_sp or 0); local pb=(b.e.s_avg or b.e.cp_sp or 0)
                        if pa~=pb then return pa > pb end; return tostring(a.nm)<tostring(b.nm)
                    end)
                elseif sm == 1 then
                    table.sort(al, function(a,b)
                        local pa=(a.e.s_avg or a.e.cp_sp or 0); local pb=(b.e.s_avg or b.e.cp_sp or 0)
                        if pa~=pb then return pa < pb end; return tostring(a.nm)<tostring(b.nm)
                    end)
                else
                    table.sort(al, function(a,b) return tostring(a.nm)<tostring(b.nm) end)
                end
                _G.mkt_auto_cache_l = al
            end
            local amf = _G.mkt_auto_cache_l or {}
            local AUTO_PAGE = 30
            local auto_pages = math.max(1, math.ceil(#amf / AUTO_PAGE))
            if _G.mkt_auto_page > auto_pages then _G.mkt_auto_page = auto_pages end
            local a_from = (_G.mkt_auto_page-1)*AUTO_PAGE+1
            local a_to   = math.min(_G.mkt_auto_page*AUTO_PAGE, #amf)

            local list_h_a = imgui.GetWindowHeight() - imgui.GetCursorPosY() - 45*d
            if imgui.BeginChild('##auto_list', imgui.ImVec2(-1, list_h_a), true) then
                _dpn1w()  -- swipe scroll
                imgui.Columns(5,'##autohdr',false)
                imgui.SetColumnWidth(0, cw_a*0.35 - 30*d); imgui.SetColumnWidth(1, cw_a*0.20)
                imgui.SetColumnWidth(2, cw_a*0.15 + 10*d); imgui.SetColumnWidth(3, cw_a*0.15 + 10*d); imgui.SetColumnWidth(4, cw_a*0.15 + 10*d)
                local hc = imgui.ImVec4(0.6,0.6,0.6,1)
                imgui.TextColored(hc, u8'  Автомобиль'); imgui.NextColumn()
                imgui.TextColored(hc, u8'  Цена $'); imgui.NextColumn()
                imgui.TextColored(hc, u8'  Мин'); imgui.NextColumn()
                imgui.TextColored(hc, u8'  Макс'); imgui.NextColumn()
                imgui.TextColored(hc, u8'  Обнов.'); imgui.NextColumn()
                imgui.Separator()
                if #amf == 0 then
                    imgui.TextDisabled(u8'  Список пуст. Откройте Авторынок.')
                    for _=1,4 do imgui.NextColumn() end
                end
                for ri = a_from, a_to do
                    local r = amf[ri]; if not r then break end
                    local e = r.e
                    local price = e.s_avg or e.cp_sp
                    local p_min = e.s_min; local p_max = e.s_max
                    do
                          local _asp  = imgui.GetCursorScreenPos()
                          local _alh  = imgui.GetTextLineHeight()
                          local _astr = _cyr5f('  ' .. (r.nm or ''))
                          local _atw  = imgui.CalcTextSize(_astr).x
                          local _acw  = cw_a * 0.35 - 30*d - 6
                          imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0,0,0,0))
                          if imgui.Selectable('##asel'..ri, false,
                              imgui.SelectableFlags.SpanAllColumns) then
                              _G.mkt_auto_detail_item = r.nm
                              _G.mkt_auto_detail_open = true
                          end
                          imgui.PopStyleColor()
                          local _adl = imgui.GetWindowDrawList()
                          _adl:PushClipRect(_asp, imgui.ImVec2(_asp.x + _acw, _asp.y + _alh + 2), true)
                          local _aoff = 0
                          if _atw > _acw then
                              local _asd  = _atw - _acw + 8
                              local _aspd = 1.5
                              local _aspt = _asd / 40 + 2 * _aspd
                              local _aph  = math.fmod(imgui.GetTime() + ri * 0.53, _aspt)
                              if _aph > _aspd then _aoff = math.min((_aph - _aspd) * 40, _asd) end
                              if _aph >= _aspt - _aspd then _aoff = _asd end
                          end
                          _adl:AddText(imgui.ImVec2(_asp.x - _aoff, _asp.y), 0xFFFFFFFF, _astr)
                          _adl:PopClipRect()
                      end
                      imgui.NextColumn()
                    if price then imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), _cyr5f('  $'.._kcr3y(price)))
                    else imgui.TextDisabled(u8'  —') end
                    imgui.NextColumn()
                    if p_min then imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f('  $'.._zhb9s(p_min)))
                    else imgui.TextDisabled(u8'  —') end
                    imgui.NextColumn()
                    if p_max then imgui.TextColored(imgui.ImVec4(1,0.5,0.5,1), _cyr5f('  $'.._zhb9s(p_max)))
                    else imgui.TextDisabled(u8'  —') end
                    imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), _cyr5f('  '..(e.date or '—')))
                    imgui.NextColumn()
                end
                imgui.Columns(1); imgui.EndChild()
            end
            local pw_a = 42*d
            imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f('Стр. '.._G.mkt_auto_page..'/'..auto_pages..' ('..#amf..' авто)'))
            imgui.SameLine(0,8*d)
            if imgui.Button(_ic_ll..'##alp',imgui.ImVec2(pw_a,0)) then _G.mkt_auto_page=1 end
            imgui.SameLine(0,4*d)
            if imgui.Button(_ic_al..'##alpr',imgui.ImVec2(pw_a,0)) then if _G.mkt_auto_page>1 then _G.mkt_auto_page=_G.mkt_auto_page-1 end end
            imgui.SameLine(0,4*d)
            if imgui.Button(_ic_ar..'##alnx',imgui.ImVec2(pw_a,0)) then if _G.mkt_auto_page<auto_pages then _G.mkt_auto_page=_G.mkt_auto_page+1 end end
            imgui.SameLine(0,4*d)
            if imgui.Button(_ic_rr..'##alls',imgui.ImVec2(pw_a,0)) then _G.mkt_auto_page=auto_pages end
            imgui.SameLine(0,12*d)
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45,0.08,0.08,1))
            if imgui.Button(_ic_trash..' '.._cyr5f('Очистить ·Авто##autoclear'), imgui.ImVec2(0,0)) then
                fh_mkt_auto={}; _ryb5t()
                sampAddChatMessage('[MH Auto] {ff4444}База авто очищена.',0xFFFFFF)
            end
            imgui.PopStyleColor()
            imgui.EndTabItem()
        end -- end sub-tab Автомобили##sub_auto

        if _bcn4w() then
        if imgui.BeginTabItem(_ic_scl..' '..u8'Арбитраж##sub_arb') then
            local d2 = settings.general.custom_dpi
            local cw_a = imgui.GetWindowContentRegionWidth()
            if not _G.arb_min_price then _G.arb_min_price = imgui.new.int(settings.market_filters and settings.market_filters.min_price or 0) end
            if not _G.arb_trend_up  then _G.arb_trend_up  = imgui.new.bool(settings.market_filters and settings.market_filters.trend_up_only or false) end
            if not _G.arb_page      then _G.arb_page = 1 end
            if not _G.arz_srv_sel then
                _G.arz_srv_sel = imgui.new.int(_mpf7d())
            end
            if not _G.arz_srv_ptr then
                local _names = {}
                for _, s in ipairs(ARZ_SERVERS) do table.insert(_names, u8(s.name)) end
                _G.arz_srv_ptr   = imgui.new['const char*'][#_names](_names)
                _G.arz_srv_count = #_names
            end
            if not _G.arb_first_load_done then
                _G.arb_first_load_done = true
                if not mh_arz_loading then
                    local _al_srv = ARZ_SERVERS[_G.arz_srv_sel[0] + 1]
                    local _al_id  = _al_srv and _al_srv.id or -1
                    lua_thread.create(function() wait(0); _xtj6b(_al_id) end)
                end
            end
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), _ic_flt..' ')
            imgui.SameLine(0,4*d2)
            imgui.TextDisabled(_cyr5f('Мин. цена лавки $:'))
            imgui.SameLine(0,6*d2)
            imgui.PushItemWidth(120*d2)
            if imgui.InputInt('##arb_minp', _G.arb_min_price, 0, 0) then
                if _G.arb_min_price[0] < 0 then _G.arb_min_price[0] = 0 end
                settings.market_filters.min_price = _G.arb_min_price[0]; _wfn7p()
                _G.arb_list = nil
            end
            imgui.PopItemWidth()
            imgui.SameLine(0, 8*d2)
            if imgui.Checkbox('##arb_tup', _G.arb_trend_up) then
                settings.market_filters.trend_up_only = _G.arb_trend_up[0]; _wfn7p()
                _G.arb_list = nil
            end
            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Только тренд вверх')) end
            imgui.SameLine(0, 6*d2)
            if imgui.Button(_ic_rot..'##arb_ref', imgui.ImVec2(22*d2, 0)) then
                _G.arb_list = nil; _G.arb_building = false; _G.arb_page = 1
            end
            imgui.Spacing()
            if not _G.arb_dir_filter then _G.arb_dir_filter = imgui.new.int(0) end
            do
                local dds = {
                    {i=_ic_lyr,                              t=_cyr5f('Все'),                            v=0, r=0.55,g=0.55,b=0.55},
                    {i=_ic_store.._ic_rt.._ic_chrtl,    t=_cyr5f('Покупка в лавке'), v=1, r=0.35,g=0.70,b=1.00},
                    {i=_ic_chrtl.._ic_rt.._ic_store,    t=_cyr5f('Скуп дороже рынка'), v=2, r=1.00,g=0.70,b=0.25},
                    {i=_ic_store.._ic_alr.._ic_store,   t=_cyr5f('Лавка-Лавка'),   v=3, r=0.75,g=0.45,b=1.00},
                }
                for _di,_dd in ipairs(dds) do
                    if _di > 1 then imgui.SameLine(0, 4*d2) end
                    local _da = (_G.arb_dir_filter[0] == _dd.v)
                    local r,g,b = _dd.r,_dd.g,_dd.b
                    if _da then
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(r*.30,g*.30,b*.30,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r*.45,g*.45,b*.45,1))
                        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(r*.60,g*.60,b*.60,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(r,g,b,1))
                    else
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.09,0.09,0.11,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r*.16,g*.16,b*.16,1))
                        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(r*.28,g*.28,b*.28,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(r*.60,g*.60,b*.60,1))
                    end
                    if imgui.Button(_dd.i..'##ddf'..tostring(_dd.v), imgui.ImVec2(0, 20*d2)) then
                        _G.arb_dir_filter[0] = _dd.v; _G.arb_list = nil; _G.arb_building = false; _G.arb_page = 1
                    end
                    imgui.PopStyleColor(4)
                    if imgui.IsItemHovered() then imgui.SetTooltip(_dd.t) end
                end
            end
            imgui.Spacing()
            imgui.TextDisabled(_cyr5f('Сервер:'))
            imgui.SameLine(0, 6*d2)
            imgui.PushItemWidth(140*d2)
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.12, 0.12, 0.15, 1))
            if imgui.Combo(u8'##arb_srv', _G.arz_srv_sel, _G.arz_srv_ptr, _G.arz_srv_count) then
                _G.arb_list = nil; _G.arb_building = false; _G.arb_page = 1
                if not mh_arz_loading then
                    local _chg_id = ARZ_SERVERS[_G.arz_srv_sel[0] + 1] and ARZ_SERVERS[_G.arz_srv_sel[0] + 1].id or -1
                    lua_thread.create(function() wait(0); _xtj6b(_chg_id) end)
                end
            end
            imgui.PopStyleColor()
            imgui.PopItemWidth()
            imgui.SameLine(0, 6*d2)
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.08, 0.18, 0.32, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.28, 0.50, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.16, 0.38, 0.65, 1))
            if imgui.Button(_ic_gps .. ' ' .. u8'Авто##arb_auto', imgui.ImVec2(80*d2, 0)) then
                local _aidx = _mpf7d()
                _G.arz_srv_sel[0] = _aidx
                _G.arb_list = nil; _G.arb_building = false; _G.arb_page = 1
                if not mh_arz_loading then
                    local _auto_id = ARZ_SERVERS[_aidx + 1] and ARZ_SERVERS[_aidx + 1].id or -1
                    lua_thread.create(function() wait(0); _xtj6b(_auto_id) end)
                end
            end
            imgui.PopStyleColor(3)
            imgui.Separator(); imgui.Spacing()
            do
                local _api_n = mh_arz_data and #mh_arz_data or 0
                if mh_arz_loading then
                    imgui.TextColored(imgui.ImVec4(ar,ag,0.2,1), _ic_rot..'  '.._cyr5f('Загрузка лавок с API...'))
                elseif mh_arz_items_loading then
                    imgui.TextColored(imgui.ImVec4(ar*0.7,ag*0.7,0.2,1), _ic_rot..'  '.._cyr5f('Загрузка базы предметов...'))
                elseif _api_n == 0 then
                    imgui.TextColored(imgui.ImVec4(1,0.4,0.4,1), _ic_warn..'  '.._cyr5f('Нет данных API — нажмите Авто или смените сервер'))
                else
                    local _idb = mh_arz_items_loaded and _cyr5f('Предметы: ОК') or _cyr5f('Предметы: загрузка...')
                    imgui.TextDisabled(_ic_store..'  '.._cyr5f('API: '.._api_n..' лавок  |  ').._idb)
                end
                imgui.Spacing()
            end
            if not _G.arb_list and not _G.arb_building then
                _G.arb_building = true
                _G.arb_list = {}  -- пустой пока строится
                _G.arb_gen = (_G.arb_gen or 0) + 1
                local _gen   = _G.arb_gen
                local _arb_srv = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1]
                local _arb_sid = _arb_srv and _arb_srv.id or -1
                local _min_p = settings.market_filters.min_price or 0
                local _tup   = settings.market_filters.trend_up_only or false
                local _df    = _G.arb_dir_filter and _G.arb_dir_filter[0] or 0
                lua_thread.create(function()
                    wait(0)  -- yield один фрейм чтобы рендер не застрял
                    if _G.arb_gen ~= _gen then return end
                    local _aborted = false
                    local _arb_raw = _vkp7n(_min_p, _tup, _arb_sid, function()
                        wait(0)
                        if _G.arb_gen ~= _gen then _aborted = true; return false end
                    end)
                    if _aborted or _G.arb_gen ~= _gen then return end
                    local _res
                    if _df == 0 then
                        _res = _arb_raw
                    elseif _df == 1 then
                        _res = {}; for _,_a in ipairs(_arb_raw) do if _a.dir == 'buy'       then table.insert(_res,_a) end end
                    elseif _df == 2 then
                        _res = {}; for _,_a in ipairs(_arb_raw) do if _a.dir == 'sell'      then table.insert(_res,_a) end end
                    elseif _df == 3 then
                        _res = {}; for _,_a in ipairs(_arb_raw) do if _a.dir == 'shop2shop' then table.insert(_res,_a) end end
                    end
                    _G.arb_list     = _res
                    _G.arb_page     = 1
                    _G.arb_building = false
                end)
            end
            if _G.arb_building then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), _ic_rot..'  ')
                imgui.SameLine(0,4*d2)
                imgui.TextDisabled(_cyr5f('Строю список...'))
                imgui.Spacing()
            elseif #(_G.arb_list or {}) == 0 then
                -- Подсказка почему нет результатов
                local _api_n2 = mh_arz_data and #mh_arz_data or 0
                local _mkt_n  = 0; for _ in pairs(fh_mkt_prices) do _mkt_n=_mkt_n+1 end
                imgui.TextDisabled(_cyr5f('Нет результатов. API лавок: '.._api_n2..', товаров в базе: '.._mkt_n))
            end
            local arb = _G.arb_list or {}
            local ARB_PG = 50
            local arb_pages = math.max(1, math.ceil(#arb / ARB_PG))
            if _G.arb_page > arb_pages then _G.arb_page = arb_pages end
            local af = (_G.arb_page-1)*ARB_PG+1
            local at = math.min(_G.arb_page*ARB_PG, #arb)
            local list_h = imgui.GetWindowHeight() - imgui.GetCursorPosY() - 45*d2
            local _is_s2s = (_G.arb_dir_filter and _G.arb_dir_filter[0]==3)
            if imgui.BeginChild('##arb_list', imgui.ImVec2(-1,list_h), true) then
                _dpn1w()  -- swipe scroll
                local hc = imgui.ImVec4(ar,ag,ab,0.8)
                if _is_s2s then
                    imgui.Columns(5,'##s2s_hdr',false)
                    local _cw_nm  = cw_a*0.21 - 4*d2
                    local _cw_s   = cw_a*0.31
                    local _cw_b   = cw_a*0.31
                    local _cw_m   = cw_a*0.10
                    local _cw_pct = cw_a - _cw_nm - _cw_s - _cw_b - _cw_m
                    imgui.SetColumnWidth(0, _cw_nm)
                    imgui.SetColumnWidth(1, _cw_s)
                    imgui.SetColumnWidth(2, _cw_b)
                    imgui.SetColumnWidth(3, _cw_m)
                    imgui.SetColumnWidth(4, _cw_pct)
                    imgui.TextColored(hc, _cyr5f(' Товар')); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,0.9), _cyr5f('Продаёт')); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.4,0.7,1,0.9), _cyr5f('Скупает')); imgui.NextColumn()
                    imgui.TextColored(hc, _cyr5f('Маржа')); imgui.NextColumn()
                    imgui.TextColored(hc, _cyr5f('%%')); imgui.NextColumn()
                    imgui.Separator()
                    if #arb==0 then
                        imgui.TextDisabled(_cyr5f('  Лавки не найдены. Сканируйте Обзор -> Просмотренные лавки.'))
                        for _=1,4 do imgui.NextColumn() end
                    end
                    for i=af,at do
                        local a=arb[i]; if not a then break end
                        local mc=a.margin>=0 and imgui.ImVec4(0.3,0.95,0.3,1) or imgui.ImVec4(1,0.4,0.3,1)
                        local tag=mh_get_item_tag(a.nm)
                        local nm_c=imgui.ImVec4(1,1,1,0.9)
                        if tag=='watch' then nm_c=imgui.ImVec4(0.4,0.85,1,1)
                        elseif tag=='skip' then nm_c=imgui.ImVec4(0.5,0.5,0.5,0.6)
                        elseif tag=='fav' then nm_c=imgui.ImVec4(1,0.85,0.1,1) end
                        local tpfx=''
                        if tag=='watch' then tpfx=_ic_eye..' '
                        elseif tag=='skip' then tpfx=_ic_ban..' '
                        elseif tag=='fav' then tpfx=_ic_star..' ' end
                        imgui.PushStyleColor(imgui.Col.Text,nm_c)
                        local _cw2=imgui.GetColumnWidth()-4*d2
                        local _ft=tpfx.._cyr5f(' '..a.nm)
                        local _cx,_cy=imgui.GetCursorPosX(),imgui.GetCursorPosY()
                        if imgui.Selectable('##s2s'..i,false,imgui.SelectableFlags.AllowDoubleClick,imgui.ImVec2(_cw2,0)) then
                            _G.mkt_detail_item=a.nm; _G.mkt_detail_src='cp'; _G.mkt_detail_open=true
                        end
                        imgui.SetCursorPos(imgui.ImVec2(_cx,_cy))
                        imgui.TextUnformatted(_ft)
                        imgui.PopStyleColor()
                        imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f('$'.._kcr3y(a.shop)))
                        imgui.SameLine(0,5*d2)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.1,0.35,0.1,0.85))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.1,0.55,0.1,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.4,1))
                        if imgui.SmallButton(_ic_phone..'##p1_'..i) then
                            local _o=a.owner or ''
                            if _o~='' then lua_thread.create(function()
                                for _p=0,999 do local _ok,_pn=pcall(sampGetPlayerNickname,_p)
                                    if _ok and _pn and _pn:lower()==_o:lower() then
                                        _G._mh_call_pending_nick=_o:lower(); sampSendChat('/number '.._p); break
                                    end end end) end
                        end
                        imgui.PopStyleColor(3)
                        imgui.SameLine(0,4*d2)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06,0.20,0.08,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10,0.38,0.14,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.5,1))
                        if imgui.SmallButton(_ic_gps..'##g1_'..i) then
                            if a.uid then sampSendChat('/findilavka '..a.uid) end
                        end
                        imgui.PopStyleColor(3)
                        local _uid1 = a.uid and _cyr5f(' #'..tostring(a.uid)) or ''
                        imgui.TextColored(imgui.ImVec4(0.55,0.55,0.55,1), _cyr5f(' '..a.owner).._uid1)
                        imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), _cyr5f('$'.._kcr3y(a.mkt)))
                        imgui.SameLine(0,5*d2)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.1,0.35,0.1,0.85))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.1,0.55,0.1,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.4,1))
                        if imgui.SmallButton(_ic_phone..'##p2_'..i) then
                            local _o2=a.owner2 or ''
                            if _o2~='' then lua_thread.create(function()
                                for _p=0,999 do local _ok,_pn=pcall(sampGetPlayerNickname,_p)
                                    if _ok and _pn and _pn:lower()==_o2:lower() then
                                        _G._mh_call_pending_nick=_o2:lower(); sampSendChat('/number '.._p); break
                                    end end end) end
                        end
                        imgui.PopStyleColor(3)
                        imgui.SameLine(0,4*d2)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06,0.20,0.08,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10,0.38,0.14,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.5,1))
                        if imgui.SmallButton(_ic_gps..'##g2_'..i) then
                            if a.uid2 then sampSendChat('/findilavka '..a.uid2) end
                        end
                        imgui.PopStyleColor(3)
                        local _uid2 = a.uid2 and _cyr5f(' #'..tostring(a.uid2)) or ''
                        imgui.TextColored(imgui.ImVec4(0.55,0.55,0.55,1), _cyr5f(' '..(a.owner2 or '?')).._uid2)
                        imgui.NextColumn()
                        imgui.TextColored(mc, _cyr5f('$'.._kcr3y(a.margin))); imgui.NextColumn()
                        imgui.TextColored(mc, _cyr5f(string.format('%.1f%%',a.margin_pct))); imgui.NextColumn()
                    end
                    imgui.Columns(1)
                else
                    imgui.Columns(9,'##arb_hdr',false)
                    -- Берём ширину ВНУТРИ BeginChild (точнее чем cw_a снаружи)
                    local _cw_inner = imgui.GetWindowContentRegionWidth()
                    -- Товар фиксирован 18%, цены шире, иконки = остаток
                    local _arb_nm_w   = math.floor(_cw_inner * 0.190)  -- Товар  -- ? GPS
                    local _arb_typ_w  = math.floor(_cw_inner * 0.038)  -- Тип
                    local _arb_prc_w  = 0  -- вычислим из остатка  -- Лавка/Рынок
                    local _arb_mrg_w  = 0  -- вычислим из остатка  -- Маржа
                    local _arb_pct_w  = math.floor(_cw_inner * 0.058)  -- %
                    local _arb_own_w  = math.floor(_cw_inner * 0.120)  -- Овнер
                    local _arb_icon_w = 28*d2  -- иконки фиксированные
                    -- цены и маржа делят весь остаток: 40% / 40% / 20%
                    local _arb_price_pool = _cw_inner - _arb_nm_w - _arb_typ_w - _arb_pct_w - _arb_own_w - _arb_icon_w*2
                    _arb_prc_w = math.floor(_arb_price_pool / 3)
                    _arb_mrg_w = _arb_price_pool - _arb_prc_w*2  -- остаток = третья часть
                    local cws={_arb_nm_w,_arb_typ_w,_arb_prc_w,_arb_prc_w,_arb_mrg_w,_arb_pct_w,_arb_own_w,_arb_icon_w,_arb_icon_w}
                    for ci,cw2 in ipairs(cws) do imgui.SetColumnWidth(ci-1,cw2) end
                    imgui.TextColored(hc,_cyr5f(' Товар')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' Тип')); imgui.NextColumn()
                    do
                        local _df2 = _G.arb_dir_filter and _G.arb_dir_filter[0] or 0
                        if _df2 == 2 then
                            imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,0.9),_cyr5f(' Скуп. $')); imgui.NextColumn()
                            imgui.TextColored(imgui.ImVec4(0.6,0.85,1,0.9),_cyr5f(' Рынок $')); imgui.NextColumn()
                        else
                            imgui.TextColored(imgui.ImVec4(0.6,0.85,1,0.9),_cyr5f(' Лавка $')); imgui.NextColumn()
                            imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,0.9),_cyr5f(' Рынок $')); imgui.NextColumn()
                        end
                    end
                    imgui.TextColored(hc,_cyr5f(' Маржа $')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' %%')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' Овнер')); imgui.NextColumn()
                    imgui.TextColored(hc,_ic_phone); imgui.NextColumn()
                    imgui.TextColored(hc,_ic_gps); imgui.NextColumn()
                    imgui.Separator()
                    if #arb==0 then
                        imgui.TextDisabled(_cyr5f('  Данных нет. Сначала сканируйте лавки (ВЛАВПОРОБ -> Чужие лавки).'))
                        for _=1,8 do imgui.NextColumn() end
                    end
                    for i=af,at do
                        local a=arb[i]; if not a then break end
                        local mc=a.margin>=0 and imgui.ImVec4(0.3,0.95,0.3,1) or imgui.ImVec4(1,0.4,0.3,1)
                        local tag=mh_get_item_tag(a.nm)
                    local nm_c = imgui.ImVec4(1,1,1,0.9)
                    if tag == 'watch'   then nm_c = imgui.ImVec4(0.4,0.85,1,1)
                    elseif tag == 'skip'   then nm_c = imgui.ImVec4(0.5,0.5,0.5,0.6)
                    elseif tag == 'fav'    then nm_c = imgui.ImVec4(1,0.85,0.1,1) end
                    local tag_prefix = ''
                    if tag == 'watch' then tag_prefix = fa.EYE..' '
                    elseif tag == 'skip' then tag_prefix = fa.BAN..' '
                    elseif tag == 'fav'  then tag_prefix = fa.STAR..' ' end
                    imgui.PushStyleColor(imgui.Col.Text, nm_c)
                    local _col_w = imgui.GetColumnWidth() - 8*d2
                    local _full_txt = tag_prefix.._cyr5f(' '..a.nm)
                    local _txt_w = imgui.CalcTextSize(_full_txt).x
                    local _cx = imgui.GetCursorPosX()
                    local _cy = imgui.GetCursorPosY()
                    if imgui.Selectable('##arb'..i, false,
                        imgui.SelectableFlags.AllowDoubleClick,
                        imgui.ImVec2(_col_w, 0)) then
                        _G.mkt_detail_item = a.nm; _G.mkt_detail_src = 'cp'; _G.mkt_detail_open = true
                    end
                    imgui.SetCursorPos(imgui.ImVec2(_cx, _cy))
                    if _txt_w > _col_w then
                        local _t = os.clock() % (4 + 1)
                        local _scroll = 0
                        if _t > 1 then
                            _scroll = math.min((_t - 1) / 3 * (_txt_w - _col_w + 8*d2), _txt_w - _col_w + 8*d2)
                        end
                        local _sp = imgui.GetCursorScreenPos()
                        imgui.PushClipRect(imgui.ImVec2(_sp.x, _sp.y - 2), imgui.ImVec2(_sp.x + _col_w, _sp.y + 20*d2), true)
                        imgui.SetCursorPos(imgui.ImVec2(_cx - _scroll, _cy))
                        imgui.TextUnformatted(_full_txt)
                        imgui.PopClipRect()
                    else
                        imgui.TextUnformatted(_full_txt)
                    end
                    imgui.PopStyleColor()
                    imgui.NextColumn()
                    if a.dir == 'buy' then
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.35,0.70,1,1))
                        imgui.TextUnformatted(' '.._ic_store.._ic_rt.._ic_chrtl)
                        imgui.PopStyleColor()
                    elseif a.dir == 'sell' then
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1,0.70,0.25,1))
                        imgui.TextUnformatted(' '.._ic_chrtl.._ic_rt.._ic_store)
                        imgui.PopStyleColor()
                    else
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.75,0.45,1,1))
                        imgui.TextUnformatted(' '.._ic_store.._ic_alr.._ic_store)
                        imgui.PopStyleColor()
                    end
                    if imgui.IsItemHovered() then
                        local _itip
                        if a.dir == 'buy' then
                            _itip = _cyr5f('Покупаешь в лавке, продаёшь на рынке')
                        elseif a.dir == 'sell' then
                            _itip = _cyr5f('Лавка скупает дороже рынка: купи на рынке, сдай в лавку')
                        else
                            _itip = _cyr5f('Покупаешь у '..a.owner..', продаёшь в '..(a.owner2 or '?'))
                        end
                        imgui.SetTooltip(_itip)
                    end
                    imgui.NextColumn()
                    local shop_c = a.dir == 'sell' and imgui.ImVec4(0.4,0.95,0.4,1) or imgui.ImVec4(0.5,0.8,1,1)
                    local mkt_c  = a.dir == 'sell' and imgui.ImVec4(0.5,0.8,1,1)   or imgui.ImVec4(0.4,0.95,0.4,1)
                    imgui.TextColored(shop_c, _cyr5f(' $'.._kcr3y(a.shop))); imgui.NextColumn()
                    imgui.TextColored(mkt_c,  _cyr5f(' $'.._kcr3y(a.mkt)));  imgui.NextColumn()
                    imgui.TextColored(mc, _cyr5f(' $'.._kcr3y(a.margin))); imgui.NextColumn()
                    imgui.TextColored(mc, _cyr5f(string.format(' %.1f%%', a.margin_pct))); imgui.NextColumn()
                    local _uid_s  = a.uid  and _cyr5f(' #'..tostring(a.uid))  or ''
                    local _uid_s2 = a.uid2 and _cyr5f(' #'..tostring(a.uid2)) or ''
                    if a.dir == 'shop2shop' and a.owner2 then
                        imgui.TextColored(imgui.ImVec4(0.65,0.65,0.65,1), _cyr5f(' '..a.owner).._uid_s)
                        imgui.SameLine(0,2*d2)
                        imgui.TextColored(imgui.ImVec4(0.4,0.4,0.4,1), '>')
                        imgui.SameLine(0,2*d2)
                        imgui.TextColored(imgui.ImVec4(0.75,0.45,1,1), _cyr5f(a.owner2).._uid_s2)
                    else
                        imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1), _cyr5f(' '..a.owner).._uid_s)
                    end
                    imgui.NextColumn()
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.1,0.35,0.1,0.85))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.1,0.55,0.1,1))
                    imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.4,1))
                    if imgui.SmallButton(_ic_phone..'##call'..i) then
                        local _owner_nick = a.owner or ''
                        if _owner_nick ~= '' and _owner_nick ~= '?' then
                            lua_thread.create(function()
                                local _found_id = nil
                                for _pid = 0, 999 do
                                    local _ok, _pnick = pcall(sampGetPlayerNickname, _pid)
                                    if _ok and _pnick and _pnick:lower() == _owner_nick:lower() then
                                        _found_id = _pid; break
                                    end
                                end
                                if _found_id then
                                    _G._mh_call_pending_nick = _owner_nick:lower()
                                    sampSendChat('/number ' .. _found_id)
                                    sampAddChatMessage('[MH] {aaffaa}Звонок: ' .. _owner_nick, 0xFFFFFF)
                                else
                                    sampAddChatMessage('[MH] {ffaa00}' .. _owner_nick .. ' не в сети (офлайн)', 0xFFFFFF)
                                end
                            end)
                        end
                    end
                    imgui.PopStyleColor(3)
                    imgui.NextColumn()
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06,0.20,0.08,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10,0.38,0.14,1))
                    imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.5,1))
                    if imgui.SmallButton(_ic_gps..'##arbgps'..i) then
                        local _uid = a.uid
                        if _uid then sampSendChat('/findilavka '.._uid) end
                    end
                    imgui.PopStyleColor(3)
                    imgui.NextColumn()
                end
                end -- end if _is_s2s / else
                    imgui.Columns(1)
                imgui.EndChild()
            end
            imgui.Spacing()
            local pw5 = 36*d2
            if imgui.Button(_ic_ll..'##arbpp', imgui.ImVec2(pw5,0)) then _G.arb_page=1 end
            imgui.SameLine(0,3*d2)
            if imgui.Button(_ic_al..'##arbpr', imgui.ImVec2(pw5,0)) then if _G.arb_page>1 then _G.arb_page=_G.arb_page-1 end end
            imgui.SameLine(0,5*d2)
            imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), _cyr5f('Стр. '.._G.arb_page..'/'..arb_pages..' ('..#arb..' товаров)'))
            imgui.SameLine(0,5*d2)
            if imgui.Button(_ic_ar..'##arbnx', imgui.ImVec2(pw5,0)) then if _G.arb_page<arb_pages then _G.arb_page=_G.arb_page+1 end end
            imgui.SameLine(0,3*d2)
            if imgui.Button(_ic_rr..'##arbls', imgui.ImVec2(pw5,0)) then _G.arb_page=arb_pages end
            imgui.EndTabItem()
        end
        end -- end premium arbitrage tab

        imgui.EndTabBar()
        end -- end BeginTabBar ##market_subtabs
    end

    if _G.mh_tab == 2 then
        if imgui.BeginTabBar('##lavki_subtabs') then

        if imgui.BeginTabItem(_ic_store .. ' ' .. u8'Лавки##sub_arz') then

            -- Кнопка Назад если пришли из карточки товара
            if _G.arz_detail_back and _G.arz_back_item and _G.arz_back_item ~= '' then
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10,0.22,0.40,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15,0.32,0.55,1))
                if imgui.Button(_ic_lt..' '..u8'Назад к товару##dtl_back', imgui.ImVec2(0,0)) then
                    _G.arz_detail_back  = false
                    _G.mkt_detail_item  = _G.arz_back_item
                    _G.mkt_detail_src   = _G.arz_back_src or 'cp'
                    _G.mkt_detail_open  = true
                    _G.arz_detail       = nil
                end
                imgui.PopStyleColor(2)
                imgui.SameLine(0, 10*settings.general.custom_dpi)
                imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),
                    u8'Лавка: '..((_G.arz_detail and _G.arz_detail.username) or ''))
                imgui.Spacing()
            end

            if not _G.arz_srv_sel       then _G.arz_srv_sel       = imgui.new.int(_mpf7d()) end
            if not _G.arz_srch          then _G.arz_srch          = imgui.new.char[256]('') end
            if not _G.arz_srch_s        then _G.arz_srch_s        = '' end
            if not _G.arz_sort          then _G.arz_sort          = 0 end
            if not _G.arz_page          then _G.arz_page          = 1 end
            if not _G.arz_detail        then _G.arz_detail        = nil end
            if not _G.arz_detail_tab    then _G.arz_detail_tab    = 0 end  -- 0=продаёт 1=скупает
            if not _G.arz_cache_key     then _G.arz_cache_key     = nil end
            if not _G.arz_cache_list    then _G.arz_cache_list    = {} end
            if not _G.arz_first_load_done then
                _G.arz_first_load_done = true
                if #mh_arz_data == 0 and not mh_arz_loading then
                    local _auto_sid = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0] + 1) or 1]
                    local _auto_id  = _auto_sid and _auto_sid.id or -1
                    lua_thread.create(function() wait(0); _xtj6b(_auto_id) end)
                end
            end
            if not _G.arz_srv_ptr       then
                local names = {}
                for _, s in ipairs(ARZ_SERVERS) do table.insert(names, u8(s.name)) end
                _G.arz_srv_ptr = imgui.new['const char*'][#names](names)
                _G.arz_srv_count = #names
            end

            local cw_arz = imgui.GetWindowContentRegionWidth()

            imgui.Spacing()
            if mh_arz_loading then
                imgui.TextColored(imgui.ImVec4(ar, ag, 0.1, 1), _ic_rot .. '  ' .. u8'Загрузка данных лавок...')
                imgui.ProgressBar(-1 * os.clock(), imgui.ImVec2(-1, 5 * d))
            elseif mh_arz_items_loading then
                imgui.TextColored(imgui.ImVec4(ar * 0.7, ag * 0.7, 0.1, 1), _ic_rot .. '  ' .. u8'Загрузка базы предметов...')
                imgui.ProgressBar(-1 * os.clock(), imgui.ImVec2(-1, 5 * d))
            elseif mh_arz_error then
                imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), _ic_warn .. '  ' .. u8(mh_arz_error))
            else
                local lavka_total = #mh_arz_data
                local _st_srv_idx = _G.arz_srv_sel and (_G.arz_srv_sel[0] + 1) or 1
                local _st_srv = ARZ_SERVERS[_st_srv_idx]
                local _st_srv_nm = _st_srv and _st_srv.name or '?'
                local upd_str = mh_arz_last_update and (u8'Обновлено: ' .. mh_arz_last_update) or u8'Не загружено'
                local items_ok = mh_arz_items_loaded and (u8' | ' .. _ic_boxes .. ' ' .. u8'Предметы: ОК') or
                                                         (u8' | ' .. _ic_boxes .. ' ' .. u8'Предметы: —')
                imgui.TextColored(imgui.ImVec4(ar * 0.6, ag * 0.6, ab * 0.6, 1),
                    _ic_store .. '  ' .. u8('Лавок: ' .. lavka_total .. '  [' .. _st_srv_nm .. ']') .. '  |  ' .. upd_str .. items_ok)
                if _xht6j then
                    imgui.TextColored(imgui.ImVec4(1,0.75,0,1),
                        _ic_rot .. '  ' .. u8'MH Cloud: загрузка...')
                elseif _dfn1c then
                    imgui.TextColored(imgui.ImVec4(1,0.4,0.4,1),
                        _ic_warn .. '  ' .. u8'MH Cloud: ' .. _cyr5f(_dfn1c))
                elseif _mvr4p then
                    -- Кешируем cloud_cnt — пересчёт только при изменении размера mh_arz_data
                    if not _G._cloud_cnt_cache or _G._cloud_cnt_sz ~= #mh_arz_data then
                        _G._cloud_cnt_sz = #mh_arz_data
                        local _cc = 0
                        for _, lv in ipairs(mh_arz_data) do if lv._mh_cloud then _cc = _cc + 1 end end
                        _G._cloud_cnt_cache = _cc
                    end
                    imgui.TextColored(imgui.ImVec4(0.5,0.9,0.5,1),
                        _ic_cld .. '  ' .. _cyr5f('MH Cloud: ' .. _G._cloud_cnt_cache .. ' лавок'))
                    imgui.SameLine(0, 8*d)
                    if imgui.SmallButton(_ic_rot .. '##cloud_refresh') then
                        local _new_arz = {}
                        for _, lv in ipairs(mh_arz_data) do
                            if not lv._mh_cloud then table.insert(_new_arz, lv) end
                        end
                        mh_arz_data = _new_arz
                        _mvr4p = false
                        local _rf_srv = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1]
                        _pkw2y(_rf_srv and _rf_srv.id or -1)
                    end
                else
                    imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),
                        _ic_cld .. '  ' .. u8'MH Cloud: не загружен')
                    imgui.SameLine(0, 8*d)
                    if imgui.SmallButton(u8'Загрузить##cloud_load') then
                        local _ld_srv = ARZ_SERVERS[_G.arz_srv_sel and (_G.arz_srv_sel[0]+1) or 1]
                        _pkw2y(_ld_srv and _ld_srv.id or -1)
                    end
                end
            end
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            local combo_w = cw_arz * 0.42
            local btn_ref_w = 120 * d
            imgui.PushItemWidth(combo_w)
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(bg + .07, bg + .065, bg + .035, 1))
            if imgui.Combo(u8'##arz_srv', _G.arz_srv_sel, _G.arz_srv_ptr, _G.arz_srv_count) then
                _G.arz_page      = 1
                _G.arz_cache_key = nil
                _G.arz_detail    = nil
                if not mh_arz_loading then
                    local new_srv_id = ARZ_SERVERS[_G.arz_srv_sel[0] + 1] and ARZ_SERVERS[_G.arz_srv_sel[0] + 1].id or -1
                    lua_thread.create(function() wait(0); _xtj6b(new_srv_id) end)
                end
            end
            imgui.PopStyleColor()
            imgui.PopItemWidth()
            imgui.SameLine(0, 6 * d)

            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(ar * 0.22, ag * 0.22, ab * 0.12, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar * 0.45, ag * 0.45, ab * 0.25, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(ar * 0.65, ag * 0.65, ab * 0.35, 1))
            local loading_any = mh_arz_loading or mh_arz_items_loading
            if loading_any then
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.45, 0.45, 0.45, 1))
            end
            if imgui.Button(_ic_rot .. ' ' .. u8'Обновить##arz_refresh', imgui.ImVec2(btn_ref_w, 0)) then
                if not loading_any then
                    local sel_srv_id = ARZ_SERVERS[_G.arz_srv_sel[0] + 1] and ARZ_SERVERS[_G.arz_srv_sel[0] + 1].id or -1
                    _G.arz_cache_key = nil
                    _G.arz_page      = 1
                    _G.arz_detail    = nil
                    _xtj6b(sel_srv_id)
                end
            end
            if loading_any then imgui.PopStyleColor() end
            imgui.PopStyleColor(3)

            imgui.SameLine(0, 6 * d)
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.08, 0.18, 0.32, 1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.28, 0.50, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.16, 0.38, 0.65, 1))
            if imgui.Button(_ic_gps .. ' ' .. u8'Авто##arz_auto', imgui.ImVec2(80 * d, 0)) then
                local idx = _mpf7d()
                _G.arz_srv_sel[0] = idx
                _G.arz_cache_key  = nil
                _G.arz_page       = 1
                _G.arz_detail     = nil
            end
            imgui.PopStyleColor(3)

            if #mh_arz_data == 0 and not mh_arz_loading then
                imgui.SameLine(0, 10 * d)
                imgui.TextColored(imgui.ImVec4(1, 0.75, 0.2, 0.8), u8'<- нажмите Обновить')
            end

            imgui.Spacing()

            imgui.TextColored(imgui.ImVec4(ar * 0.65, ag * 0.65, ab * 0.65, 1), _ic_srch)
            imgui.SameLine(0, 5 * d)
            imgui.PushItemWidth(cw_arz * 0.38 - 32*d)
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(bg + .08, bg + .075, bg + .04, 1))
            if imgui.InputTextWithHint(u8'##arz_srch', u8'Поиск товара...', _G.arz_srch, 256) then
                do
                    local _r3 = u8:decode(ffi.string(_G.arz_srch))
                    local _ok3,_cp3 = pcall(function() return require('encoding').CP1251:encode(_r3) end)
                    local _s3 = (_ok3 and _cp3 or _r3):lower()
                    _G.arz_srch_s = _s3:gsub('[А-Я]',function(c) return string.char(string.byte(c)+32) end)
                end
                _G.arz_page = 1; _G.arz_cache_key = nil; _G.arz_detail = nil
            end
            imgui.PopStyleColor(); imgui.PopItemWidth()
            imgui.SameLine(0, 3*d)
            local _has_arz_srch = ffi.string(_G.arz_srch) ~= ''
            imgui.PushStyleColor(imgui.Col.Button, _has_arz_srch
                and imgui.ImVec4(0.38,0.08,0.08,1) or imgui.ImVec4(0.12,0.12,0.12,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55,0.12,0.12,1))
            imgui.PushStyleColor(imgui.Col.Text, _has_arz_srch
                and imgui.ImVec4(1,0.4,0.4,1) or imgui.ImVec4(0.3,0.3,0.3,1))
            if imgui.Button(_ic_x..'##arzsrchclr', imgui.ImVec2(28*d, 0)) and _has_arz_srch then
                ffi.fill(_G.arz_srch, 256, 0)
                _G.arz_srch_s = ''; _G.arz_page = 1; _G.arz_cache_key = nil; _G.arz_detail = nil
            end
            imgui.PopStyleColor(3)

            local sort_labels = { u8'По умолч.##as0', u8'Продаёт##as1', u8'Скупает##as2', u8'А-Я##as3' }
            local sw = (cw_arz - cw_arz * 0.38 - 30 * d - 10 * d) / 4
            for si = 0, 3 do
                if si > 0 then imgui.SameLine(0, 4 * d) end
                local is_act = (_G.arz_sort == si)
                if is_act then
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(ar * 0.55, ag * 0.55, ab * 0.3, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar * 0.75, ag * 0.75, ab * 0.4, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(ar, ag, ab, 1))
                end
                if imgui.Button(sort_labels[si + 1], imgui.ImVec2(sw, 0)) then
                    _G.arz_sort      = si
                    _G.arz_cache_key = nil
                    _G.arz_page      = 1
                end
                if is_act then imgui.PopStyleColor(3) end
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            if _G.arz_detail then
                local lv = _G.arz_detail
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(bg + .06, bg + .055, bg + .03, 1))
                if imgui.BeginChild('##arz_detail_card', imgui.ImVec2(-1, 52 * d), true) then
                    local srv_nm = _dzc2g(lv.serverId or -1)
                    local is_vc  = (lv.serverId == 0)
                    imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1),
                        _ic_store .. '  ' .. u8(lv.username or '?') .. '   ')
                    imgui.SameLine()
                    do
                        local _upd = lv._mh_updated_at or 0
                        -- FA иконки нельзя передавать через u8() — они уже UTF-8
                        -- Поэтому: кириллица через u8(), иконка + время — снаружи
                        local _base = u8('Лавка #' .. tostring(lv.LavkaUid or '?') ..
                            '   Сервер: ' .. srv_nm ..
                            '   ' .. (is_vc and 'VC$' or 'SA$'))
                        if _upd > 0 then
                            local _age = os.time() - _upd
                            local _time_lbl = _age < 86400 and os.date('%H:%M', _upd) or os.date('%d.%m %H:%M', _upd)
                            imgui.TextDisabled(_base .. '   ')
                            imgui.SameLine(0, 0)
                            imgui.TextDisabled(_ic_clk .. ' ' .. _time_lbl)
                        else
                            imgui.TextDisabled(_base)
                        end
                    end
                    imgui.SameLine()
                    -- Кнопки: Позвонить | GPS | Закрыть — все три правее текста
                    imgui.SetCursorPosX(cw_arz - 192 * d)
                    -- Кнопка Позвонить
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10, 0.35, 0.10, 0.85))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10, 0.55, 0.10, 1))
                    imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4, 1, 0.4, 1))
                    if imgui.Button(_ic_phone .. '##arz_call', imgui.ImVec2(28 * d, 0)) then
                        local _owner_nick = lv.username or ''
                        if _owner_nick ~= '' then
                            lua_thread.create(function()
                                local _fid = nil
                                for _pid = 0, 999 do
                                    local _ok, _pn = pcall(sampGetPlayerNickname, _pid)
                                    if _ok and _pn and _pn:lower() == _owner_nick:lower() then
                                        _fid = _pid; break
                                    end
                                end
                                if _fid then
                                    sampSendChat('/call ' .. _fid)
                                else
                                    sampAddChatMessage('[MH] {ff9966}Игрок ' .. _owner_nick .. ' не онлайн', 0xFFFFFF)
                                end
                            end)
                        end
                    end
                    imgui.PopStyleColor(3)
                    imgui.SameLine(0, 4 * d)
                    -- Кнопка GPS
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06, 0.20, 0.08, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10, 0.38, 0.14, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.14, 0.55, 0.20, 1))
                    if imgui.Button(_ic_gps .. ' ' .. u8'GPS##arz_gps', imgui.ImVec2(62 * d, 0)) then
                        sampSendChat('/findilavka ' .. tostring(lv.LavkaUid or 1))
                    end
                    imgui.PopStyleColor(3)
                    imgui.SameLine(0, 6 * d)
                    -- Кнопка Закрыть
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.25, 0.06, 0.06, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.45, 0.10, 0.10, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.65, 0.14, 0.14, 1))
                    if imgui.Button(_ic_x .. ' ' .. u8'Закрыть##arz_dc', imgui.ImVec2(88 * d, 0)) then
                        _G.arz_detail = nil
                    end
                    imgui.PopStyleColor(3)
                    imgui.EndChild()
                end
                imgui.PopStyleColor()

                local tab_sell_lbl = fa.TAG .. ' ' .. u8('Продаёт (' .. tostring(lv.items_sell and #lv.items_sell or 0) .. ')##arz_dtab0')
                local tab_buy_lbl  = fa.STORE .. ' ' .. u8('Скупает (' .. tostring(lv.items_buy and #lv.items_buy or 0) .. ')##arz_dtab1')
                local tw2 = (cw_arz - 6 * d) / 2
                for ti = 0, 1 do
                    if ti > 0 then imgui.SameLine(0, 6 * d) end
                    local is_a = (_G.arz_detail_tab == ti)
                    if is_a then
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(ar * 0.5, ag * 0.5, ab * 0.28, 1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar * 0.7, ag * 0.7, ab * 0.38, 1))
                        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(ar, ag, ab, 1))
                    end
                    local lbl = ti == 0 and tab_sell_lbl or tab_buy_lbl
                    if imgui.Button(lbl, imgui.ImVec2(tw2, 28 * d)) then _G.arz_detail_tab = ti end
                    if is_a then imgui.PopStyleColor(3) end
                end
                -- Кнопка копировать пресет по текущему табу
                do
                    local _is_sell_tab = (_G.arz_detail_tab == 0)
                    local _cp_items  = _is_sell_tab and (lv.items_sell or {}) or (lv.items_buy or {})
                    local _cp_prices = _is_sell_tab and (lv.price_sell or {}) or (lv.price_buy or {})
                    local _cp_counts = _is_sell_tab and (lv.count_sell or {}) or (lv.count_buy or {})
                    local _cp_icon   = _is_sell_tab and _ic_fimp or _ic_fimp
                    local _cp_lbl    = _is_sell_tab
                        and (_cp_icon..' '..u8'НОВ. пресет ПРОДАЖИ##arz_cp_s')
                        or  (_cp_icon..' '..u8'НОВ. пресет СКУПКИ##arz_cp_b')
                    local _cp_col = _is_sell_tab
                        and imgui.ImVec4(0.10, 0.32, 0.10, 1)
                        or  imgui.ImVec4(0.00, 0.22, 0.42, 1)
                    local _cp_colh = _is_sell_tab
                        and imgui.ImVec4(0.16, 0.46, 0.16, 1)
                        or  imgui.ImVec4(0.00, 0.30, 0.56, 1)
                    if #_cp_items > 0 then
                        imgui.PushStyleColor(imgui.Col.Button,        _cp_col)
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, _cp_colh)
                        if imgui.Button(_cp_lbl, imgui.ImVec2(-1, 0)) then
                            local _owner_nm = lv.username or '?'
                            local _added, _skipped = 0, 0
                            if _is_sell_tab then
                                -- Новый пресет ПРОДАЖИ
                                local _np = {name=_owner_nm..' Продажа', items={}}
                                for _ci, _iid in ipairs(_cp_items) do
                                    local _bid, _ench = _bqs3v(_iid)
                                    local _nm = _rgn9z(_bid)
                                    if _ench ~= '' then _nm = _nm..' ('.. _ench..')'  end
                                    local _pr = _cp_prices[_ci] or 0
                                    local _qt = _cp_counts[_ci] or 1
                                    if not _btm6q(_nm, _np.items) then
                                        table.insert(_np.items, {name=_nm, qty=_qt, price=_pr})
                                        _added = _added + 1
                                    else _skipped = _skipped + 1 end
                                end
                                table.insert(settings.presets, _np)
                                fh_active_preset_idx = #settings.presets
                                settings.active_preset = fh_active_preset_idx
                                fh_lv_autosell_preset = _np.items
                                _G.as_price_buf = nil; _G.as_qty_buf = nil
                                _wfn7p()
                                sampAddChatMessage('[MH] {00cc00}Продажи -> новый пресет #'..tostring(fh_active_preset_idx)..': +'.._added
                                    ..((_skipped>0) and ' ({aaaaaa}'.._skipped..' уже есть{ffffff})' or ''), 0xFFFFFF)
                            else
                                -- Новый пресет СКУПКИ
                                if not settings.buy_presets then settings.buy_presets = {} end
                                local _nbp = {name=_owner_nm..' Скупка', items={}}
                                for _ci, _iid in ipairs(_cp_items) do
                                    local _bid, _ench = _bqs3v(_iid)
                                    local _nm = _rgn9z(_bid)
                                    if _ench ~= '' then _nm = _nm..' ('.. _ench..')'  end
                                    local _pr = _cp_prices[_ci] or 0
                                    local _qt = _cp_counts[_ci] or 1
                                    if not _btm6q(_nm, _nbp.items) then
                                        table.insert(_nbp.items, {name=_nm, qty=_qt, max_price=_pr})
                                        _added = _added + 1
                                    else _skipped = _skipped + 1 end
                                end
                                table.insert(settings.buy_presets, _nbp)
                                fh_ab_preset_idx = #settings.buy_presets
                                fh_lv_autobuy_preset = _nbp.items
                                settings.autobuy_preset = fh_lv_autobuy_preset
                                _G.ab_price_buf = nil; _G.ab_qty_buf = nil
                                _wfn7p()
                                sampAddChatMessage('[MH] {4488ff}Скупка -> новый пресет #'..tostring(fh_ab_preset_idx)..': +'.._added
                                    ..((_skipped>0) and ' ({aaaaaa}'.._skipped..' уже есть{ffffff})' or ''), 0xFFFFFF)
                            end
                        end
                        imgui.PopStyleColor(2)
                    end
                end
                imgui.Spacing()

                local is_vc       = (lv.serverId == 0)
                local currency    = is_vc and 'VC$' or 'SA$'
                local items_arr   = _G.arz_detail_tab == 0 and (lv.items_sell or {}) or (lv.items_buy or {})
                local prices_arr  = _G.arz_detail_tab == 0 and (lv.price_sell or {}) or (lv.price_buy or {})
                local counts_arr  = _G.arz_detail_tab == 0 and (lv.count_sell or {}) or (lv.count_buy or {})
                local list_h_det  = imgui.GetWindowHeight() - imgui.GetCursorPosY() - 12 * d

                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(bg + .04, bg + .037, bg + .02, 1))
                if imgui.BeginChild('##arz_items_list', imgui.ImVec2(-1, list_h_det), false) then
                    _dpn1w()  -- swipe scroll
                    local show_tags = true
                    local col_w = show_tags
                        and {cw_arz*0.36, cw_arz*0.17, cw_arz*0.12, cw_arz*0.09, cw_arz*0.24}
                        or  {cw_arz*0.46, cw_arz*0.20, cw_arz*0.18, cw_arz*0.14}
                    local ncols = show_tags and 5 or 4
                    imgui.Columns(ncols, '##arz_items_hdr', false)
                    for ci, cw_v in ipairs(col_w) do imgui.SetColumnWidth(ci - 1, cw_v) end
                    local hc = imgui.ImVec4(ar * 0.55, ag * 0.55, ab * 0.35, 1)
                    imgui.TextColored(hc, u8'  Предмет'); imgui.NextColumn()
                    imgui.TextColored(hc, u8'  Цена'); imgui.NextColumn()
                    imgui.TextColored(hc, u8'  Кол-во'); imgui.NextColumn()
                    imgui.TextColored(hc, u8'  Валюта'); imgui.NextColumn()
                    if show_tags then imgui.TextColored(hc, u8'  Тег'); imgui.NextColumn() end
                    imgui.Columns(1)
                    imgui.Separator()

                    if #items_arr == 0 then
                        imgui.Spacing()
                        imgui.TextDisabled(u8'  Список пуст.')
                    end

                    for ii, iid in ipairs(items_arr) do
                        local bid, ench = _bqs3v(iid)
                        local nm        = _rgn9z(bid)
                        local price     = prices_arr[ii]
                        local cnt       = counts_arr[ii]
                        local nm_full   = nm .. (ench ~= '' and (' (' .. ench .. ')') or '')
                        local _tag_nm   = mh_arz_items_db[bid] or nm  -- имя для тега

                        local row_bg = (ii % 2 == 0)
                                       and imgui.ImVec4(bg + .06, bg + .055, bg + .03, 0.5)
                                       or  imgui.ImVec4(0, 0, 0, 0)
                        imgui.PushStyleColor(imgui.Col.ChildBg, row_bg)

                        imgui.Columns(ncols, '##arz_items_row' .. ii, false)
                        for ci, cw_v in ipairs(col_w) do imgui.SetColumnWidth(ci - 1, cw_v) end

                        local cur_sp  = imgui.GetCursorScreenPos()
                        local cur_lh  = imgui.GetTextLineHeight()
                        local _arz_tag = mh_get_item_tag(_tag_nm)
                        local _arz_tpfx = ''
                        if _arz_tag == 'watch' then _arz_tpfx = fa.EYE..' '
                        elseif _arz_tag == 'skip' then _arz_tpfx = fa.BAN..' '
                        elseif _arz_tag == 'fav'  then _arz_tpfx = fa.STAR..' ' end
                        local nm_str  = _arz_tpfx..u8('  ' .. nm_full)
                        local nm_tw   = imgui.CalcTextSize(nm_str).x
                        local nm_cw   = col_w[1] - 6
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0, 0, 0, 0))
                        if imgui.Selectable('##arzr' .. ii, false,
                                imgui.SelectableFlags.AllowDoubleClick,
                                imgui.ImVec2(nm_cw, cur_lh + 2)) then
                            if _tag_nm and _tag_nm ~= '' and _tag_nm ~= '?' then
                                _G.mkt_detail_item = _tag_nm
                                _G.mkt_detail_src  = 'cp'
                                _G.mkt_detail_open = true
                            end
                        end
                        imgui.PopStyleColor()
                        local dl_arz = imgui.GetWindowDrawList()
                        dl_arz:PushClipRect(cur_sp, imgui.ImVec2(cur_sp.x + nm_cw, cur_sp.y + cur_lh + 2), true)
                        local txt_off = 0
                        if nm_tw > nm_cw then
                            local sd  = nm_tw - nm_cw + 8
                            local spd = 1.8
                            local spt = sd / 38 + 2 * spd
                            local sph = math.fmod(imgui.GetTime() + ii * 0.6, spt)
                            if sph > spd then txt_off = math.min((sph - spd) * 38, sd) end
                            if sph >= spt - spd then txt_off = sd end
                        end
                        local _arz_col32 = 0xFFFFFFFF
                        if _arz_tag == 'fav'   then _arz_col32 = 0xFFFFD700
                        elseif _arz_tag == 'skip' then _arz_col32 = 0xFF888888
                        elseif _arz_tag == 'watch' then _arz_col32 = 0xFF6ACFFF end
                        dl_arz:AddText(imgui.ImVec2(cur_sp.x - txt_off, cur_sp.y), _arz_col32, nm_str)
                        dl_arz:PopClipRect()

                        imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(lp_r, lp_g, lp_b, 1),
                            u8('  ' .. _jsb6t(price)))
                        imgui.NextColumn()
                        imgui.Text(u8('  ' .. tostring(cnt or '?') .. ' шт.'))
                        imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.55, 1), u8('  ' .. currency))
                        imgui.NextColumn()
                        if show_tags then
                            local _tbw = (col_w[5] - 8*d) / 3
                            local _wc = _arz_tag=='watch' and imgui.ImVec4(0.15,0.50,0.85,1) or imgui.ImVec4(0.08,0.16,0.30,1)
                            imgui.PushStyleColor(imgui.Col.Button, _wc)
                            if imgui.SmallButton(_ic_eye..'##tw'..ii) then
                                mh_set_item_tag(_tag_nm, _arz_tag=='watch' and nil or 'watch')
                                _G.arz_cache_key = nil
                            end
                            imgui.PopStyleColor()
                            imgui.SameLine(0, 3*d)
                            local _sc = _arz_tag=='skip' and imgui.ImVec4(0.50,0.12,0.12,1) or imgui.ImVec4(0.22,0.06,0.06,1)
                            imgui.PushStyleColor(imgui.Col.Button, _sc)
                            if imgui.SmallButton(_ic_ban..'##ts'..ii) then
                                mh_set_item_tag(_tag_nm, _arz_tag=='skip' and nil or 'skip')
                                _G.arz_cache_key = nil
                            end
                            imgui.PopStyleColor()
                            imgui.SameLine(0, 3*d)
                            local _fc = _arz_tag=='fav' and imgui.ImVec4(0.55,0.42,0.04,1) or imgui.ImVec4(0.22,0.17,0.02,1)
                            imgui.PushStyleColor(imgui.Col.Button, _fc)
                            if imgui.SmallButton(_ic_star..'##tf'..ii) then
                                mh_set_item_tag(_tag_nm, _arz_tag=='fav' and nil or 'fav')
                                _G.arz_cache_key = nil
                            end
                            imgui.PopStyleColor()
                            imgui.NextColumn()
                        end
                        imgui.Columns(1)
                        imgui.PopStyleColor()
                    end
                    imgui.EndChild()
                end
                imgui.PopStyleColor()

            else
                local cur_srv_id  = ARZ_SERVERS[_G.arz_srv_sel[0] + 1] and ARZ_SERVERS[_G.arz_srv_sel[0] + 1].id or -1
                local srch_active = (_G.arz_srch_s or '') ~= ''
                local cache_key   = tostring(cur_srv_id) .. '|' .. (_G.arz_srch_s or '') .. '|' .. tostring(_G.arz_sort) .. '|' .. tostring(srch_active)
                if _G.arz_cache_key ~= cache_key then
                    _G.arz_cache_key  = cache_key
                    if srch_active then
                        _G.arz_cache_list = _tyk5r(cur_srv_id, _G.arz_srch_s or '', _G.arz_sort)
                    else
                        _G.arz_cache_list = _hnw8x(cur_srv_id, _G.arz_srch_s or '', _G.arz_sort)
                    end
                end

                local all_lavki  = _G.arz_cache_list
                local ARZ_PER_P  = 30
                local total_p    = math.max(1, math.ceil(#all_lavki / ARZ_PER_P))
                if _G.arz_page > total_p then _G.arz_page = total_p end
                local from_i     = (_G.arz_page - 1) * ARZ_PER_P + 1
                local to_i       = math.min(_G.arz_page * ARZ_PER_P, #all_lavki)

                local hc2 = imgui.ImVec4(ar * 0.5, ag * 0.5, ab * 0.3, 1)
                if srch_active then
                    imgui.Columns(6, '##arz_items_hdr', false)
                    local cwI = {cw_arz*0.22, cw_arz*0.08, cw_arz*0.15, cw_arz*0.07, cw_arz*0.25, cw_arz*0.21}
                    for ci, v in ipairs(cwI) do imgui.SetColumnWidth(ci-1, v) end
                    imgui.TextColored(hc2, u8'  Товар');      imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Тип');        imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Цена');       imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Кол-во');     imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Лавка');      imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  GPS');        imgui.NextColumn()
                    imgui.Columns(1)
                else
                    imgui.Columns(6, '##arz_list_hdr', false)
                    local cw6 = {cw_arz*0.26, cw_arz*0.14, cw_arz*0.12, cw_arz*0.14, cw_arz*0.14, cw_arz*0.18}
                    for ci, v in ipairs(cw6) do imgui.SetColumnWidth(ci-1, v) end
                    imgui.TextColored(hc2, u8'  Владелец');    imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Сервер');      imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  ID');          imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Продаёт');     imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Скупает');     imgui.NextColumn()
                    imgui.TextColored(hc2, u8'  Действие');    imgui.NextColumn()
                    imgui.Columns(1)
                end
                imgui.Separator()

                local list_h_main = imgui.GetWindowHeight() - imgui.GetCursorPosY() - 42 * d
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(bg + .025, bg + .022, bg + .012, 1))
                if imgui.BeginChild('##arz_main_list', imgui.ImVec2(-1, list_h_main), false) then
                    _dpn1w()  -- swipe scroll
                    if #all_lavki == 0 then
                        imgui.Spacing()
                        if #mh_arz_data == 0 then
                            imgui.TextDisabled(u8'  Нет данных — нажмите «Обновить» для загрузки')
                        elseif srch_active then
                            imgui.TextDisabled(u8'  Товары не найдены. Попробуйте другой запрос.')
                        else
                            imgui.TextDisabled(u8'  Лавки не найдены по заданным фильтрам.')
                        end
                    end

                    if srch_active then
                        local cwI = {cw_arz*0.22, cw_arz*0.08, cw_arz*0.15, cw_arz*0.07, cw_arz*0.25, cw_arz*0.21}
                        for ri = from_i, to_i do
                            local it = all_lavki[ri]
                            if not it then break end

                            local row_col = (ri % 2 == 0)
                                            and imgui.ImVec4(bg+.05, bg+.045, bg+.025, 0.6)
                                            or  imgui.ImVec4(0, 0, 0, 0)
                            imgui.PushStyleColor(imgui.Col.ChildBg, row_col)

                            imgui.Columns(6, '##arzir'..ri, false)
                            for ci, v in ipairs(cwI) do imgui.SetColumnWidth(ci-1, v) end

                            local rsp  = imgui.GetCursorScreenPos()
                            local rlh  = imgui.GetTextLineHeight()
                            local nm_str = u8('  ' .. it.nm)
                            local ntw  = imgui.CalcTextSize(nm_str).x
                            local ncw  = cwI[1] - 6
                            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0,0,0,0))
                            if imgui.Selectable('##arzis'..ri, false,
                                    imgui.SelectableFlags.AllowDoubleClick, imgui.ImVec2(0, rlh+2)) then
                                local _snm = it.nm:match('^(.-)%s*%(') or it.nm
                                if _snm and _snm ~= '' then
                                    _G.mkt_detail_item = _snm:match('^%s*(.-)%s*$')
                                    if not fh_mkt_prices[_G.mkt_detail_item] then
                                        _G.mkt_detail_item = it.nm
                                    end
                                    _G.mkt_detail_src  = 'cp'
                                    _G.mkt_detail_open = true
                                end
                            end
                            imgui.PopStyleColor()
                            local dlI = imgui.GetWindowDrawList()
                            dlI:PushClipRect(rsp, imgui.ImVec2(rsp.x+ncw, rsp.y+rlh+2), true)
                            local n_off = 0
                            if ntw > ncw then
                                local nsd  = ntw - ncw + 8
                                local nspd = 1.8
                                local nspt = nsd / 38 + 2 * nspd
                                local nsph = math.fmod(imgui.GetTime() + ri * 0.5, nspt)
                                if nsph > nspd then n_off = math.min((nsph - nspd) * 38, nsd) end
                                if nsph >= nspt - nspd then n_off = nsd end
                            end
                            local _itag_col = 0xFFFFFFFF
                            local _itag = it.tag or mh_get_item_tag(it.base_nm or it.nm)
                            if _itag == 'fav'   then _itag_col = 0xFFFFD700
                            elseif _itag == 'skip'  then _itag_col = 0xFF888888
                            elseif _itag == 'watch' then _itag_col = 0xFF6ACFFF end
                            local _tpfx = ''
                            if _itag == 'fav'   then _tpfx = fa.STAR..' '
                            elseif _itag == 'skip'  then _tpfx = fa.BAN..' '
                            elseif _itag == 'watch' then _tpfx = fa.EYE..' ' end
                            local nm_str_tagged = _tpfx ~= '' and (_tpfx..nm_str:match('^%s*(.*)')) or nm_str
                            dlI:AddText(imgui.ImVec2(rsp.x - n_off, rsp.y), _itag_col, nm_str_tagged)
                            dlI:PopClipRect()
                            imgui.NextColumn()

                            if it.op == 'sell' then
                                imgui.TextColored(imgui.ImVec4(lp_r, lp_g, lp_b, 1), _ic_tag .. u8(' Прод.'))
                            else
                                imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1.0, 1), _ic_store .. u8(' Скуп.'))
                            end
                            imgui.NextColumn()

                            local currency = it.is_vc and 'VC$' or 'SA$'
                            if it.price then
                                imgui.TextColored(imgui.ImVec4(lp_r, lp_g, lp_b, 1),
                                    u8('  ' .. _jsb6t(it.price) .. ' ' .. currency))
                            else
                                imgui.TextDisabled(u8'  —')
                            end
                            imgui.NextColumn()

                            if it.cnt then
                                imgui.Text(u8('  ' .. tostring(it.cnt) .. ' шт.'))
                            else
                                imgui.TextDisabled(u8'  —')
                            end
                            imgui.NextColumn()

                            do
                                local _oc = it.is_prem and imgui.ImVec4(1,0.84,0,1) or imgui.ImVec4(0.55,0.75,0.55,1)
                                local _olbl = u8('  #'..tostring(it.lv_uid)..' '..it.lv_owner)
                                -- Кликабельный владелец — открывает карточку лавки
                                imgui.PushStyleColor(imgui.Col.Text, _oc)
                                if imgui.Selectable(_olbl..'##arzown'..ri, false,
                                        imgui.SelectableFlags.AllowDoubleClick,
                                        imgui.ImVec2(cwI[5]-4, 0)) then
                                    if it.lv_ref then
                                        _G.arz_detail     = it.lv_ref
                                        _G.arz_detail_tab = 0
                                    end
                                end
                                imgui.PopStyleColor()
                                if it.is_prem then imgui.SameLine(0,2*d); imgui.TextColored(imgui.ImVec4(1,0.84,0,1), _ic_star) end
                                -- Время обновления лавки
                                if (it.lv_updated_at or 0) > 0 then
                                    local _age = os.time() - it.lv_updated_at
                                    local _tl = _age < 86400 and os.date('%H:%M', it.lv_updated_at)
                                                              or  os.date('%d.%m', it.lv_updated_at)
                                    imgui.SameLine(0, 3*d)
                                    imgui.TextColored(imgui.ImVec4(0.45,0.45,0.45,1), _ic_clk..' '.._tl)
                                end
                            end
                            imgui.NextColumn()

                            if (it.lv_updated_at or 0) > 0 then
                                local _age2 = os.time() - it.lv_updated_at
                                local _tl2 = _age2 < 86400 and os.date('%H:%M', it.lv_updated_at)
                                                              or  os.date('%d.%m', it.lv_updated_at)
                                imgui.TextColored(imgui.ImVec4(0.45,0.45,0.45,1), _ic_clk..' '.._tl2)
                                imgui.SameLine(0, 4*d)
                            end
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10, 0.35, 0.10, 0.85))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10, 0.55, 0.10, 1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,  1.0,  0.4,  1))
                            if imgui.SmallButton(_ic_phone .. '##igtel' .. ri) then
                                local _on = it.lv_owner or ''
                                if _on ~= '' and _on ~= '?' then
                                    lua_thread.create(function()
                                        for _p = 0, 999 do
                                            local _ok, _pn = pcall(sampGetPlayerNickname, _p)
                                            if _ok and _pn and _pn:lower() == _on:lower() then
                                                _G._mh_call_pending_nick = _on:lower()
                                                sampSendChat('/number ' .. _p)
                                                break
                                            end
                                        end
                                    end)
                                end
                            end
                            imgui.PopStyleColor(3)
                            imgui.SameLine(0, 4 * d)
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06, 0.18, 0.08, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10, 0.32, 0.14, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.14, 0.48, 0.20, 1))
                            if imgui.SmallButton(_ic_gps .. '##igps' .. ri) then
                                sampSendChat('/findilavka ' .. tostring(it.lv_uid))
                            end
                            imgui.PopStyleColor(3)
                            imgui.NextColumn()

                            imgui.Columns(1)
                            imgui.PopStyleColor()
                        end

                    else
                        local cw6 = {cw_arz*0.26, cw_arz*0.14, cw_arz*0.12, cw_arz*0.14, cw_arz*0.14, cw_arz*0.18}
                        for ri = from_i, to_i do
                            local row = all_lavki[ri]
                            if not row then break end
                            local lv     = row.lv
                            local srv_nm = _dzc2g(lv.serverId or -1)

                            local row_col = (ri % 2 == 0)
                                            and imgui.ImVec4(bg+.05, bg+.045, bg+.025, 0.6)
                                            or  imgui.ImVec4(0, 0, 0, 0)
                            imgui.PushStyleColor(imgui.Col.ChildBg, row_col)

                            imgui.Columns(6, '##arz_row' .. ri, false)
                            for ci, v in ipairs(cw6) do imgui.SetColumnWidth(ci-1, v) end

                            local _is_prow = row.is_prem
                            local rsp    = imgui.GetCursorScreenPos()
                            local rlh    = imgui.GetTextLineHeight()
                            local owner_str = u8('  ' .. (lv.username or '?'))
                            local otw    = imgui.CalcTextSize(owner_str).x
                            local ocw    = cw6[1] - (_is_prow and 22*d or 6)
                            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0,0,0,0))
                            if imgui.Selectable('##arzsel'..ri, false,
                                    imgui.SelectableFlags.AllowDoubleClick, imgui.ImVec2(ocw, rlh+2)) then
                                _G.arz_detail     = lv
                                _G.arz_detail_tab = 0
                            end
                            imgui.PopStyleColor()
                            local dl2 = imgui.GetWindowDrawList()
                            dl2:PushClipRect(rsp, imgui.ImVec2(rsp.x + ocw, rsp.y + rlh + 2), true)
                            local o_off = 0
                            if otw > ocw then
                                local osd  = otw - ocw + 8
                                local ospd = 1.8
                                local ospt = osd / 38 + 2 * ospd
                                local osph = math.fmod(imgui.GetTime() + ri * 0.7, ospt)
                                if osph > ospd then o_off = math.min((osph - ospd) * 38, osd) end
                                if osph >= ospt - ospd then o_off = osd end
                            end
                            local _oc = _is_prow and 0xFFD700FF or 0xFFFFFFFF
                            dl2:AddText(imgui.ImVec2(rsp.x - o_off, rsp.y), _oc, owner_str)
                            if _is_prow then
                                dl2:AddRect(
                                    imgui.ImVec2(rsp.x - 2, rsp.y - 1),
                                    imgui.ImVec2(rsp.x + cw6[1] - 4, rsp.y + rlh + 2),
                                    0xFFD700CC, 3.0
                                )
                            end
                            dl2:PopClipRect()
                            if _is_prow then
                                imgui.SameLine(0, 3*d)
                                imgui.TextColored(imgui.ImVec4(1, 0.84, 0, 1), _ic_star)
                            end
                            imgui.NextColumn()

                            imgui.TextColored(imgui.ImVec4(0.55, 0.75, 0.55, 1), u8('  ' .. srv_nm))
                            imgui.NextColumn()
                            imgui.TextDisabled(u8('  #' .. tostring(lv.LavkaUid or '?')))
                            imgui.NextColumn()

                            if row.sell_cnt > 0 then
                                imgui.TextColored(imgui.ImVec4(lp_r, lp_g, lp_b, 1),
                                    u8('  ' .. row.sell_cnt .. ' поз.'))
                            else
                                imgui.TextDisabled(u8'  —')
                            end
                            imgui.NextColumn()

                            if row.buy_cnt > 0 then
                                imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1.0, 1),
                                    u8('  ' .. row.buy_cnt .. ' поз.'))
                            else
                                imgui.TextDisabled(u8'  —')
                            end
                            imgui.NextColumn()

                            -- Время обновления лавки
                            do
                                local _rts = lv._mh_updated_at or 0
                                if _rts > 0 then
                                    local _rage = os.time() - _rts
                                    local _rtl = _rage < 86400 and os.date('%H:%M', _rts)
                                                               or  os.date('%d.%m', _rts)
                                    imgui.TextColored(imgui.ImVec4(0.45,0.45,0.45,1), _ic_clk..' '.._rtl)
                                    imgui.SameLine(0, 4*d)
                                end
                            end
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10, 0.35, 0.10, 0.85))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10, 0.55, 0.10, 1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,  1.0,  0.4,  1))
                            if imgui.SmallButton(_ic_phone .. '##arztel' .. ri) then
                                local _on = lv.username or ''
                                if _on ~= '' and _on ~= '?' then
                                    lua_thread.create(function()
                                        for _p = 0, 999 do
                                            local _ok, _pn = pcall(sampGetPlayerNickname, _p)
                                            if _ok and _pn and _pn:lower() == _on:lower() then
                                                _G._mh_call_pending_nick = _on:lower()
                                                sampSendChat('/number ' .. _p)
                                                break
                                            end
                                        end
                                    end)
                                end
                            end
                            imgui.PopStyleColor(3)
                            imgui.SameLine(0, 4 * d)
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06, 0.18, 0.08, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10, 0.32, 0.14, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.14, 0.48, 0.20, 1))
                            if imgui.SmallButton(_ic_gps .. '##arzgps' .. ri) then
                                sampSendChat('/findilavka ' .. tostring(lv.LavkaUid or 1))
                            end
                            imgui.PopStyleColor(3)
                            imgui.NextColumn()
                            imgui.Columns(1)
                            imgui.PopStyleColor()
                        end
                    end  -- if srch_active

                    imgui.EndChild()
                end
                imgui.PopStyleColor()

                imgui.Spacing()
                local pw_arz = 38 * d
                local count_label = srch_active
                    and u8('Стр. ' .. _G.arz_page .. '/' .. total_p .. '  (' .. #all_lavki .. ' товаров)')
                    or  u8('Стр. ' .. _G.arz_page .. '/' .. total_p .. '  (' .. #all_lavki .. ' лавок)')
                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), count_label)
                imgui.SameLine(0, 8 * d)
                if imgui.Button(_ic_ll .. '##arz_fp', imgui.ImVec2(pw_arz, 0)) then _G.arz_page = 1 end
                imgui.SameLine(0, 3 * d)
                if imgui.Button(_ic_al .. '##arz_pp', imgui.ImVec2(pw_arz, 0)) then
                    if _G.arz_page > 1 then _G.arz_page = _G.arz_page - 1 end
                end
                imgui.SameLine(0, 3 * d)
                if imgui.Button(_ic_ar .. '##arz_np', imgui.ImVec2(pw_arz, 0)) then
                    if _G.arz_page < total_p then _G.arz_page = _G.arz_page + 1 end
                end
                imgui.SameLine(0, 3 * d)
                if imgui.Button(_ic_rr .. '##arz_lp', imgui.ImVec2(pw_arz, 0)) then _G.arz_page = total_p end
            end  -- конец if arz_detail else

            imgui.EndTabItem()
        end -- end sub-tab Лавки ARZ


        if imgui.BeginTabItem(_ic_wh .. ' ' .. u8'Просмотренные##sub_other') then
            local cw_os = imgui.GetWindowContentRegionWidth()
            local shops_cnt = 0; for _ in pairs(fh_other_shops) do shops_cnt = shops_cnt + 1 end

            do
                local _now = os.time()
                if not _G._os_clean_t then _G._os_clean_t = 0 end
                if (_now - _G._os_clean_t) >= 60 then
                    _G._os_clean_t = _now
                    local _stale = 2 * 3600  -- 2 hours
                    local _cleaned = 0
                    for k, v in pairs(fh_other_shops) do
                        local _ts = v.ts or 0
                        if _ts > 0 and (_now - _ts) > _stale then
                            fh_other_shops[k] = nil
                            _cleaned = _cleaned + 1
                        end
                    end
                    if _cleaned > 0 then
                        settings.other_shops = fh_other_shops
                        _wfn7p()
                    end
                end
            end
            if fh_other_shop_scanning and not fh_other_shop_cur then
                fh_other_shop_scanning = false
                fh_other_shop_price_tds = {}
                fh_other_dlg_signal = nil
            end
            if fh_other_shop_scanning and fh_other_shop_cur then
                local _paused = fh_player_dlg_open
                local _sc = fh_other_scan_done
                local _st = fh_other_scan_total
                local _pause_str = _paused and (_ic_paus .. ' {ПАУЗА}  ') or ''
                local _prog_str = _st > 0 and ('  [' .. _sc .. '/' .. _st .. ']') or ''
                local _col = _paused and imgui.ImVec4(0.4,0.7,1,1) or imgui.ImVec4(1,0.75,0,1)
                imgui.TextColored(_col,
                    _ic_rot .. '  ' .. _cyr5f(
                        (_paused and 'ПАУЗА — закройте окно  ' or 'Скан: ') ..
                        (fh_other_shop_cur.owner or '?') ..
                        '  #' .. tostring(fh_other_shop_cur.shop_num or '?') ..
                        _prog_str))
                if _st > 0 then
                    local _frac = _paused and -1 * os.clock() or (_sc / _st)
                    imgui.ProgressBar(_frac, imgui.ImVec2(cw_os * 0.55, 5*d), '')
                    imgui.SameLine(0, 8*d)
                end
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.50,0.10,0.10,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.75,0.15,0.15,1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.95,0.20,0.20,1))
                if imgui.Button(_ic_circs..' '.._cyr5f('Стоп##os_stop'), imgui.ImVec2(0,0)) then
                    fh_other_shop_scanning = false
                    fh_other_dlg_signal    = nil
                    fh_other_shop_cur      = nil
                    fh_other_shop_price_tds = {}
                    sampAddChatMessage('[MH] {ff4444}Скан остановлен.', 0xFFFFFF)
                end
                imgui.PopStyleColor(3)
            else
                imgui.TextDisabled(_cyr5f('  Сохранёно лавок: ' .. shops_cnt))
            end
            imgui.TextDisabled(u8'  Работает автомат: подойдите к чужой лавке и откройте меню товаров')
            imgui.Spacing()

            if not _G.os_srch_buf then _G.os_srch_buf = imgui.new.char[128]('') end
            if not _G.os_srch then _G.os_srch = '' end
            imgui.PushItemWidth(-1)
            if imgui.InputTextWithHint('##os_srch', _cyr5f('Поиск по товару, нику, лавке...'), _G.os_srch_buf, 128) then
                _G.os_srch = u8:decode(ffi.string(_G.os_srch_buf)):lower()
            end
            imgui.PopItemWidth()
            imgui.Separator()

            local os_list = {}
            for key, shop in pairs(fh_other_shops) do
                if type(key) ~= 'string' or type(shop) ~= 'table' then goto os_next end
                local match = false
                if _G.os_srch == '' or #_G.os_srch < 3 then
                    match = true
                else
                    if key:lower():find(_G.os_srch,1,true)
                        or (shop.owner or ''):lower():find(_G.os_srch,1,true) then
                        match = true
                    end
                    if not match then
                        for _, it in ipairs(shop.sell_items or {}) do
                            if it.name:lower():find(_G.os_srch,1,true) then match=true; break end
                        end
                    end
                    if not match then
                        for _, it in ipairs(shop.buy_items or {}) do
                            if it.name:lower():find(_G.os_srch,1,true) then match=true; break end
                        end
                    end
                end
                if match then
                    table.insert(os_list, {key=key, shop=shop})
                end
                ::os_next::
            end
            table.sort(os_list, function(a,b) return (a.shop.dt or '') > (b.shop.dt or '') end)

            local panel_h_os = imgui.GetWindowHeight() - 150*d
            local left_w_os = math.floor(cw_os * 0.38)
            local right_w_os = cw_os - left_w_os - 8*d
            if not _G.os_selected_key then _G.os_selected_key = nil end
            if not _G.os_selected_tab then _G.os_selected_tab = 'sell' end

            if imgui.BeginChild('##os_left', imgui.ImVec2(left_w_os, panel_h_os), true) then
                _dpn1w()  -- swipe scroll
                if #os_list == 0 then
                    imgui.TextDisabled(_cyr5f('  Пусто.'))
                    imgui.TextDisabled(_cyr5f('  Подойдите к чужой лавке'))
                    imgui.TextDisabled(_cyr5f('  и откройте меню товаров'))
                end
                for _, os_e in ipairs(os_list) do
                    local shop = os_e.shop
                    local is_sel = (_G.os_selected_key == os_e.key)
                    local lbl = _cyr5f((shop.owner or '?') .. ' #' .. tostring(shop.shop_num or '?'))
                    local sub = _cyr5f('  ' .. (shop.dt or '') .. '  '
                        .. #shop.sell_items .. ' Прод. / ' .. #shop.buy_items .. ' Скуп.')
                    if is_sel then
                        imgui.PushStyleColor(imgui.Col.Header,        imgui.ImVec4(ar*0.3, ag*0.3, ab*0.3, 1))
                        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(ar*0.5, ag*0.5, ab*0.5, 1))
                    end
                    if imgui.Selectable(lbl..'##osshop_'..os_e.key, is_sel, 0, imgui.ImVec2(0,0)) then
                        _G.os_selected_key = os_e.key
                    end
                    if is_sel then imgui.PopStyleColor(2) end
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5,0.5,0.5,1))
                    imgui.TextUnformatted(sub)
                    imgui.PopStyleColor()
                    imgui.Separator()
                end
                imgui.EndChild()
            end

            imgui.SameLine(0, 8*d)

            if imgui.BeginChild('##os_right', imgui.ImVec2(right_w_os, panel_h_os), true) then
                _dpn1w()  -- swipe scroll
                local sel_shop = _G.os_selected_key and fh_other_shops[_G.os_selected_key]
                if not sel_shop then
                    imgui.TextDisabled(_cyr5f('  Тут будут товары'))
                    imgui.TextDisabled(_cyr5f('  Выберите лавку слева'))
                else
                    imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1),
                        _cyr5f((sel_shop.owner or '?') .. ' Лавка #' ..
                                tostring(sel_shop.shop_num or '?') .. '  ' .. (sel_shop.dt or '')))
                    imgui.SameLine(0, 6*d)
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.06,0.20,0.08,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10,0.38,0.14,1))
                    if imgui.SmallButton(_ic_gps..' GPS##osgps') then
                        local _snum = sel_shop.shop_num
                        if _snum then sampSendChat('/findilavka '.._snum) end
                    end
                    imgui.PopStyleColor(2)
                    imgui.SameLine(0, 4*d)
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10,0.35,0.10,0.85))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.10,0.55,0.10,1))
                    imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.4,1))
                    if imgui.SmallButton(_ic_phone..'##oscall') then
                        local _owner_nick = sel_shop.owner or ''
                        if _owner_nick ~= '' then
                            lua_thread.create(function()
                                local _fid = nil
                                for _pid = 0, 999 do
                                    local _ok, _pn = pcall(sampGetPlayerNickname, _pid)
                                    if _ok and _pn and _pn:lower()==_owner_nick:lower() then _fid=_pid; break end
                                end
                                if _fid then
                                    _G._mh_call_pending_nick = _owner_nick:lower()
                                    sampSendChat('/number '.._fid)
                                    sampAddChatMessage('[MH] {aaffaa}Звонок: '.._owner_nick, 0xFFFFFF)
                                else
                                    sampAddChatMessage('[MH] {ffaa00}'.._owner_nick..' не в сети', 0xFFFFFF)
                                end
                            end)
                        end
                    end
                    imgui.PopStyleColor(3)
                    imgui.SameLine(0, 6*d)
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45,0.08,0.08,1))
                    if imgui.SmallButton(_ic_trash..'##osdel') then
                        _rcw6d(_G.os_selected_key)
                        _G.os_selected_key = nil
                    end
                    imgui.PopStyleColor()
                    imgui.Separator()

                    local tw = (right_w_os - 20*d) / 2
                    imgui.PushStyleColor(imgui.Col.Button,
                        _G.os_selected_tab=='sell' and imgui.ImVec4(sb_r, sb_g, sb_b, 1) or imgui.ImVec4(0.1,0.1,0.1,1))
                    if imgui.Button(_ic_tag..' '.._cyr5f('Продаёт (' .. #sel_shop.sell_items .. ')##ostabs'), imgui.ImVec2(tw,0)) then
                        _G.os_selected_tab = 'sell'
                    end
                    imgui.PopStyleColor()
                    imgui.SameLine(0, 4*d)
                    imgui.PushStyleColor(imgui.Col.Button,
                        _G.os_selected_tab=='buy' and imgui.ImVec4(0,0.25,0.5,1) or imgui.ImVec4(0.1,0.1,0.1,1))
                    if imgui.Button(_ic_cart..' '.._cyr5f('Скупает (' .. #sel_shop.buy_items .. ')##ostabb'), imgui.ImVec2(tw,0)) then
                        _G.os_selected_tab = 'buy'
                    end
                    imgui.PopStyleColor()
                    imgui.Separator()

                    local item_list = (_G.os_selected_tab=='sell') and sel_shop.sell_items or sel_shop.buy_items
                    local tab_color = (_G.os_selected_tab=='sell') and imgui.ImVec4(0.4,0.9,0.4,1) or imgui.ImVec4(0.4,0.7,1,1)

                    if #item_list > 0 then
                        if _G.os_selected_tab == 'sell' then
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10,0.32,0.10,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.16,0.46,0.16,1))
                            if imgui.Button(_ic_fimp..' '..u8('Импорт -> НОВЫЙ пресет ПРОДАЖИ##osimp_s'), imgui.ImVec2(-1, 0)) then
                                -- Создаём новый пресет с именем лавки
                                local _new_preset_name = sel_shop.owner and (sel_shop.owner..' Продажа') or ('Пресет '..tostring(#settings.presets+1))
                                local _new_preset = {name=_new_preset_name, items={}}
                                local added, skipped = 0, 0
                                for _, it in ipairs(item_list) do
                                    if not _btm6q(it.name, _new_preset.items) then
                                        table.insert(_new_preset.items, {name=it.name, qty=it.qty or 1, price=it.price or 0})
                                        added = added + 1
                                    else skipped = skipped + 1 end
                                end
                                table.insert(settings.presets, _new_preset)
                                fh_active_preset_idx = #settings.presets
                                settings.active_preset = fh_active_preset_idx
                                fh_lv_autosell_preset = _new_preset.items
                                _G.as_price_buf = nil; _G.as_qty_buf = nil
                                _wfn7p()
                                sampAddChatMessage('[MH] {00cc00}Продажи -> новый пресет #'..tostring(fh_active_preset_idx)..': +'..added
                                    ..(skipped>0 and ' ({aaaaaa}'..skipped..' уже есть{ffffff})' or ''), 0xFFFFFF)
                            end
                            imgui.PopStyleColor(2)
                        else
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.00,0.22,0.42,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.00,0.30,0.56,1))
                            if imgui.Button(_ic_fimp..' '..u8('Импорт -> НОВЫЙ пресет СКУПКИ##osimp_b'), imgui.ImVec2(-1, 0)) then
                                -- Создаём новый пресет скупки
                                if not settings.buy_presets then settings.buy_presets = {} end
                                local _bp_name = sel_shop.owner and (sel_shop.owner..' Скупка') or ('Скупка '..tostring(#settings.buy_presets+1))
                                local _new_bp = {name=_bp_name, items={}}
                                local added, skipped = 0, 0
                                for _, it in ipairs(item_list) do
                                    if not _btm6q(it.name, _new_bp.items) then
                                        table.insert(_new_bp.items, {name=it.name, qty=it.qty or 1, max_price=it.price or 0})
                                        added = added + 1
                                    else skipped = skipped + 1 end
                                end
                                table.insert(settings.buy_presets, _new_bp)
                                fh_ab_preset_idx = #settings.buy_presets
                                fh_lv_autobuy_preset = _new_bp.items
                                settings.autobuy_preset = fh_lv_autobuy_preset
                                _G.ab_price_buf = nil; _G.ab_qty_buf = nil
                                _wfn7p()
                                sampAddChatMessage('[MH] {4488ff}Скупка -> новый пресет #'..tostring(fh_ab_preset_idx)..': +'..added
                                    ..(skipped>0 and ' ({aaaaaa}'..skipped..' уже есть{ffffff})' or ''), 0xFFFFFF)
                            end
                            imgui.PopStyleColor(2)
                        end
                        imgui.Spacing()
                    end

                    if #item_list == 0 then
                        imgui.TextDisabled(_cyr5f('  Пусто'))
                    end
                    for _, it in ipairs(item_list) do
                        local cp_e = fh_mkt_prices[it.name]
                        local mkt_p = nil
                        do
                            local _mp2 = _mh_get_mkt_price(it.name)
                            if _mp2 then
                                mkt_p = (_mp2.avg7 and _mp2.avg7 > 0) and _mp2.avg7 or _mp2.today
                            end
                        end
                        -- НЕ используем cp_e.s_avg как цену рынка (это цена лавок)
                        local diff_str = ''
                        local diff_col = imgui.ImVec4(0.6,0.6,0.6,1)
                        if mkt_p and mkt_p > 0 and it.price > 0 then
                            local diff = mkt_p - it.price
                            local pct  = math.floor(math.abs(diff) / mkt_p * 100)
                            if _G.os_selected_tab == 'sell' then
                                if diff > 0 then diff_str='-'..pct..'%'; diff_col=imgui.ImVec4(0.3,0.95,0.3,1)
                                elseif diff < 0 then diff_str='+'..pct..'%'; diff_col=imgui.ImVec4(1,0.45,0.3,1)
                                else diff_str='=' end
                            else
                                if diff < 0 then diff_str='+'..pct..'%'; diff_col=imgui.ImVec4(0.3,0.95,0.3,1)
                                elseif diff > 0 then diff_str='-'..pct..'%'; diff_col=imgui.ImVec4(1,0.45,0.3,1)
                                else diff_str='=' end
                            end
                        end
                        local _os_tag = mh_get_item_tag(it.name)
                        local _os_tpfx = ''
                        if _os_tag == 'watch' then _os_tpfx = fa.EYE..' '
                        elseif _os_tag == 'skip' then _os_tpfx = fa.BAN..' '
                        elseif _os_tag == 'fav'  then _os_tpfx = fa.STAR..' ' end
                        local _os_tc = imgui.ImVec4(1,1,1,0.9)
                        if _os_tag=='fav'   then _os_tc = imgui.ImVec4(1,0.85,0.1,1)
                        elseif _os_tag=='skip' then _os_tc = imgui.ImVec4(0.5,0.5,0.5,0.6)
                        elseif _os_tag=='watch' then _os_tc = imgui.ImVec4(0.4,0.85,1,1) end
                        imgui.PushStyleColor(imgui.Col.Text, _os_tc)
                        if imgui.Selectable(_os_tpfx.._cyr5f(it.name .. '##osit_'.._ ), false, 0, imgui.ImVec2(0,0)) then
                            if fh_mkt_prices[it.name] then
                                _G.mkt_detail_item = it.name
                                _G.mkt_detail_src  = 'cp'
                                _G.mkt_detail_open = true
                            end
                        end
                        imgui.PopStyleColor()
                        imgui.SameLine(0,8*d)
                        imgui.TextColored(tab_color, _cyr5f('$'.._kcr3y(it.price)))
                        if mkt_p then
                            imgui.TextColored(imgui.ImVec4(0.38,0.38,0.38,1), _cyr5f('   Рын: $'.._kcr3y(mkt_p)))
                            imgui.SameLine(0,6*d)
                            imgui.TextColored(diff_col, _cyr5f(diff_str))
                            if cp_e and cp_e.cp_hist and #cp_e.cp_hist >= 4 then
                                local _trd = _xvn2w(cp_e.cp_hist)
                                local _tc  = _pdf8k(_trd)
                                imgui.SameLine(0,6*d)
                                imgui.TextColored(_tc, _trd.icon .. _cyr5f(_trd.text))
                            end
                        else
                            imgui.TextColored(imgui.ImVec4(0.28,0.28,0.28,1), _cyr5f('   Рын: нет данных'))
                        end
                    end
                end
                imgui.EndChild()
            end

            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45,0.08,0.08,1))
            if imgui.Button(_ic_trash..' '.._cyr5f('Очистить всё##os_clearall'), imgui.ImVec2(0,0)) then
                fh_other_shops = {}
                settings.other_shops = {}
                _wfn7p()
                _G.os_selected_key = nil
                sampAddChatMessage('[MH] {ff4444}Чужие лавки очищены.', 0xFFFFFF)
            end
            imgui.PopStyleColor()
            imgui.EndTabItem()
        end -- end sub-tab Чужие лавки

        if imgui.BeginTabItem(_ic_star .. ' ' .. u8'\xcf\xee\xe4\xe1\xee\xf0\xea\xe0##sub_wish') then
            -- === WISHLIST ===
            if not _G.mh_wish_filter then _G.mh_wish_filter = 0 end
            if not _G.mh_wish_srch   then _G.mh_wish_srch = imgui.new.char[128](''); _G.mh_wish_srch_s = '' end
            if not _G.mh_wish_sort   then _G.mh_wish_sort = 0 end

            local cw_w = imgui.GetWindowContentRegionWidth()

            -- \xd1\xee\xe1\xe8\xf0\xe0\xe5\xec \xf1\xef\xe8\xf1\xee\xea \xf2\xe5\xe3\xee\xe2
            local tagged = {}
            if settings.item_tags then
                for nm, tg in pairs(settings.item_tags) do
                    if nm and nm ~= '' and tg then
                        table.insert(tagged, {name=nm, tag=tg})
                    end
                end
            end

            -- \xd4\xe8\xeb\xfc\xf2\xf0 + \xef\xee\xe8\xf1\xea
            local srch_lo = _G.mh_wish_srch_s or ''
            local filtered = {}
            for _, it in ipairs(tagged) do
                local tag_ok = (_G.mh_wish_filter == 0)
                    or (_G.mh_wish_filter == 1 and it.tag == 'watch')
                    or (_G.mh_wish_filter == 2 and it.tag == 'fav')
                    or (_G.mh_wish_filter == 3 and it.tag == 'skip')
                local srch_ok = srch_lo == '' or it.name:lower():find(srch_lo, 1, true)
                if tag_ok and srch_ok then table.insert(filtered, it) end
            end

            -- \xd1\xee\xf0\xf2\xe8\xf0\xee\xe2\xea\xe0
            if _G.mh_wish_sort == 0 then
                table.sort(filtered, function(a,b) return a.name < b.name end)
            else
                local order = {watch=1, fav=2, skip=3}
                table.sort(filtered, function(a,b)
                    local oa = order[a.tag] or 9; local ob = order[b.tag] or 9
                    if oa ~= ob then return oa < ob end
                    return a.name < b.name
                end)
            end

            -- \xca\xed\xee\xef\xea\xe8 \xf4\xe8\xeb\xfc\xf2\xf0\xe0
            local function wfbtn(lbl, mode)
                local act = _G.mh_wish_filter == mode
                if act then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar*0.5,ag*0.5,ab*0.5,0.9)) end
                if imgui.Button(lbl..'##wf'..mode, imgui.ImVec2(0,0)) then _G.mh_wish_filter = mode end
                if act then imgui.PopStyleColor() end
            end

            wfbtn(u8('\xc2\xf1\xe5 ('..#tagged..')'), 0)
            imgui.SameLine(0, 4*d)
            wfbtn(_ic_eye .. ' ' .. u8'\xd1\xec\xee\xf2\xf0\xe5\xf2\xfc', 1)
            imgui.SameLine(0, 4*d)
            wfbtn(_ic_star .. ' ' .. u8'\xc8\xe7\xe1\xf0\xe0\xed\xed\xee\xe5', 2)
            imgui.SameLine(0, 4*d)
            wfbtn(_ic_ban .. ' ' .. u8'\xcd\xe5 \xe1\xf0\xe0\xf2\xfc', 3)
            imgui.SameLine(0, 10*d)
            local sort_lbl = _G.mh_wish_sort == 0 and (_ic_dn .. ' ' .. u8'\xc0-\xdf') or (_ic_lyr .. ' ' .. u8'\xd2\xe5\xe3')
            if imgui.Button(sort_lbl .. '##wsort', imgui.ImVec2(0,0)) then
                _G.mh_wish_sort = (_G.mh_wish_sort == 0) and 1 or 0
            end

            -- \xcf\xee\xe8\xf1\xea
            imgui.PushItemWidth(-1)
            if imgui.InputText(u8'##wish_srch', _G.mh_wish_srch, 128) then
                _G.mh_wish_srch_s = u8:decode(ffi.string(_G.mh_wish_srch)):lower()
            end
            imgui.PopItemWidth()
            imgui.Separator()
            imgui.TextDisabled(u8('\xd0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2\xee\xe2: '..#filtered))
            imgui.Spacing()

            -- \xd1\xef\xe8\xf1\xee\xea
            local list_h = imgui.GetWindowHeight() - 185*d
            if imgui.BeginChild('##wish_list', imgui.ImVec2(-1, list_h), false) then
                _dpn1w()
                if #filtered == 0 then
                    imgui.Spacing()
                    imgui.TextDisabled(u8'\xcf\xf3\xf1\xf2\xee. \xc4\xee\xe1\xe0\xe2\xfc\xf2\xe5 \xf2\xee\xe2\xe0\xf0\xfb, \xef\xee\xec\xe5\xf7\xe0\xff \xe8\xf5 \xed\xe0 \xea\xe0\xf0\xf2\xee\xf7\xea\xe5 \xf2\xee\xe2\xe0\xf0\xe0.')
                end

                local tag_colors = {
                    watch = imgui.ImVec4(0.15, 0.50, 0.85, 1),
                    fav   = imgui.ImVec4(0.75, 0.58, 0.05, 1),
                    skip  = imgui.ImVec4(0.65, 0.15, 0.15, 1),
                }
                local tag_icons = { watch=_ic_eye, fav=_ic_star, skip=_ic_ban }
                local tag_labels = {
                    watch = u8'\xd1\xec\xee\xf2\xf0\xe5\xf2\xfc',
                    fav   = u8'\xc8\xe7\xe1\xf0\xe0\xed\xed\xee\xe5',
                    skip  = u8'\xcd\xe5 \xe1\xf0\xe0\xf2\xfc',
                }

                for _, it in ipairs(filtered) do
                    local tc  = tag_colors[it.tag] or imgui.ImVec4(0.5,0.5,0.5,1)
                    local ico = tag_icons[it.tag]  or _ic_circ

                    -- \xca\xed\xee\xef\xea\xe0 \xee\xf2\xea\xf0\xfb\xf2\xfc \xea\xe0\xf0\xf2\xee\xf7\xea\xf3 (\xe2\xe5\xf1\xfc \xf0\xff\xe4 \xea\xee\xec\xe5 \xea\xf0\xe5\xf1\xf2\xe8\xea\xe0)
                    local row_w = cw_w - 30*d
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.08,0.08,0.12,0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar*0.15,ag*0.15,ab*0.15,0.6))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(ar*0.25,ag*0.25,ab*0.25,0.8))
                    -- \xd1\xf2\xf0\xee\xea\xe0 \xea\xe0\xea \xea\xed\xee\xef\xea\xe0: \xe8\xea\xee\xed\xea\xe0 + \xed\xe0\xe7\xe2\xe0\xed\xe8\xe5 + \xec\xe5\xf2\xea\xe0
                    local row_lbl = ico .. '  ' .. it.name .. '   '
                    if it.tag ~= 'skip' then
                        row_lbl = row_lbl .. tag_labels[it.tag]
                    else
                        imgui.PushStyleColor(imgui.Col.Text, tc)
                        row_lbl = row_lbl .. tag_labels[it.tag]
                        imgui.PopStyleColor()
                    end
                    imgui.PushStyleColor(imgui.Col.Text, tc)
                    local clicked = imgui.Button(ico .. '##ico'..it.name, imgui.ImVec2(20*d, 0))
                    imgui.PopStyleColor()
                    imgui.SameLine(0, 6*d)
                    -- \xcd\xe0\xe7\xe2\xe0\xed\xe8\xe5 + \xec\xe5\xf2\xea\xe0
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0,0,0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar*0.1,ag*0.1,ab*0.1,0.5))
                    local nm_clicked = imgui.Button(u8(it.name) .. '   ' .. tag_labels[it.tag] .. '##nm'..it.name, imgui.ImVec2(row_w - 26*d, 0))
                    imgui.PopStyleColor(2)
                    if clicked or nm_clicked then
                        _G.mkt_detail_item = it.name
                        _G.mkt_detail_src  = 'tags'
                        _G.mkt_detail_pos  = nil  -- \xf1\xe1\xf0\xee\xf1 \xef\xee\xe7\xe8\xf6\xe8\xe8 \xe2 \xf6\xe5\xed\xf2\xf0
                        _G.mkt_detail_open = true
                    end
                    imgui.PopStyleColor(3)

                    -- \xca\xf0\xe5\xf1\xf2\xe8\xea (\xf3\xe4\xe0\xeb\xe5\xed\xe8\xe5 \xf2\xe5\xe3\xe0)
                    imgui.SameLine(0, 4*d)
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.3,0.07,0.07,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.6,0.1,0.1,1))
                    if imgui.Button(_ic_x..'##wdel'..it.name, imgui.ImVec2(22*d, 0)) then
                        mh_set_item_tag(it.name, nil)
                    end
                    imgui.PopStyleColor(2)
                end

                imgui.EndChild()
            end

            imgui.EndTabItem()
        end -- end Wishlist tab

        imgui.EndTabBar()
        end -- end BeginTabBar ##lavki_subtabs
    end

    if _G.mh_tab == 3 then
            local cw_lv = imgui.GetWindowContentRegionWidth()
            local left_w = math.floor(cw_lv * 0.42)
            local right_w = cw_lv - left_w - 8*d
            if fh_lv_autosell_running then
                imgui.TextColored(imgui.ImVec4(1,0.75,0,1), _cyr5f('  Авто-выкладка: '..fh_lv_autosell_status))
                imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(-1, 5*d))
                if imgui.Button(_ic_circs..' '.._cyr5f('Стоп##asstop'), imgui.ImVec2(-1,0)) then fh_lv_autosell_running=false end
            else
                if fh_lv_autosell_status ~= '' then
                    imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f('  '..fh_lv_autosell_status))
                else
                    imgui.TextDisabled(_cyr5f('  Лево: инвентарь лавки  |  Право: пресет'))
                end
                local bw = (cw_lv - 8*d) / 2
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(bb_r, bb_g, bb_b, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(bb_r*1.35, bb_g*1.35, bb_b*1.3, 1))
                if imgui.Button(_ic_boxes..' '.._cyr5f('Скан инвентаря##asinv'), imgui.ImVec2(bw,0)) then _vcz9h() end
                imgui.PopStyleColor(2)
                imgui.SameLine(0,8*d)
                local as_auto = imgui.new.bool(fh_lv_autostart_enabled)
                if imgui.Checkbox(_cyr5f('Автозапуск##asauto'), as_auto) then
                    fh_lv_autostart_enabled = as_auto[0]
                    settings.general.autostart_enabled = fh_lv_autostart_enabled
                    _wfn7p()
                end
            end
            imgui.Separator()
            if #fh_lv_autosell_preset > 0 then
                local total_sell = 0
                for _, asp in ipairs(fh_lv_autosell_preset) do
                    total_sell = total_sell + (asp.price or 0) * (asp.qty or 1)
                end
                imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f('  Итого выкладки: $' .. _kcr3y(total_sell)))
            end
            local panel_h = imgui.GetWindowHeight() - 130*d
            if imgui.BeginChild('##inv_panel', imgui.ImVec2(left_w, panel_h), true) then
                _dpn1w()  -- swipe scroll
                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f('Инвентарь ('..#fh_lv_inventory..'):'))
                imgui.Separator()
                if not _G.as_inv_srch_buf then _G.as_inv_srch_buf = imgui.new.char[64]('') end
                if not _G.as_inv_srch then _G.as_inv_srch = '' end
                imgui.PushItemWidth(-1)
                if imgui.InputTextWithHint('##asinvsrch', _cyr5f('Поиск...'), _G.as_inv_srch_buf, 64) then
                    _G.as_inv_srch = u8:decode(ffi.string(_G.as_inv_srch_buf)):lower()
                end
                imgui.PopItemWidth()
                if fh_lv_inv_scanning then
                    imgui.TextColored(imgui.ImVec4(1,0.7,0,1), _cyr5f('  Скан...'))
                    imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(-1,5*d))
                elseif #fh_lv_inventory == 0 then
                    imgui.TextDisabled(_cyr5f('  Пусто.'))
                    imgui.TextDisabled(_cyr5f('  Нажмите "Скан лавки"'))
                    imgui.TextDisabled(_cyr5f('  или /mm у прилавка'))
                else
                    for _, inv in ipairs(fh_lv_inventory) do
                        if _G.as_inv_srch and _G.as_inv_srch ~= '' and not inv.name:lower():find(_G.as_inv_srch, 1, true) then
                        else
                        local already = false
                        for _, p in ipairs(fh_lv_autosell_preset) do
                            if p.name == inv.name then already=true; break end
                        end
                        local lbl = _cyr5f(inv.name..'  '..inv.count..' шт.')
                        imgui.Spacing()
                        if not already then
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(sb_r, sb_g, sb_b, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.5, sb_g*1.5, sb_b*1.5, 1))
                            if imgui.Button(lbl..'##ainv_'..inv.name, imgui.ImVec2(-1,0)) then
                                local _add_cp_e = fh_mkt_prices[inv.name]
                                local _add_best = 0
                                if _add_cp_e then
                                    if _add_cp_e.cp_hist and #_add_cp_e.cp_hist > 0 then
                                        local _add_s7 = _mjg5t(_add_cp_e.cp_hist, 7)
                                        if _add_s7 then _add_best = _add_s7.avg end
                                    end
                                    if _add_best == 0 then _add_best = _add_cp_e.s_avg or _add_cp_e.b_avg or 0 end
                                end
                                if _add_best == 0 then
                                    local _lv = fh_mkt_lavka[inv.name]
                                    if _lv then _add_best = _lv.b_avg or _lv.s_avg or 0 end
                                end
                                table.insert(fh_lv_autosell_preset,{name=inv.name,price=_add_best,qty=inv.count})
                                if not _G.as_price_buf then _G.as_price_buf={} end
                                if not _G.as_qty_buf   then _G.as_qty_buf={}   end
                                local _new_idx = #fh_lv_autosell_preset
                                _G.as_price_buf[_new_idx]=imgui.new.char[32](_vnh1j(_add_best))
                                _G.as_qty_buf[_new_idx]=imgui.new.char[16](tostring(inv.count))
                                _tcv8f()
                            end
                            imgui.PopStyleColor(2)
                        else
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.12,0.12,0.12,1))
                            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.45,0.45,0.45,1))
                            imgui.Button(lbl..'##ainv_'..inv.name, imgui.ImVec2(-1,0))
                            imgui.PopStyleColor(2)
                        end
                        end  -- filter
                    end
                end
                imgui.EndChild()
            end
            imgui.SameLine(0,8*d)
            if imgui.BeginChild('##as_preset', imgui.ImVec2(right_w, panel_h), true) then
                _dpn1w()  -- swipe scroll
                    local cw_p = right_w - 12*d
                    imgui.PushItemWidth(cw_p * 0.50)
                    local preset_names = {}
                    for pi, pr in ipairs(settings.presets or {}) do
                        local pnm = pr.name or ('Пресет '..pi)
                        preset_names[pi] = u8(pnm)
                    end
                    local cur_name = preset_names[fh_active_preset_idx] or u8('Пресет 1')
                    if imgui.BeginCombo('##preset_sel', cur_name) then
                        for pi, pname in ipairs(preset_names) do
                            if imgui.Selectable(pname..'##ps'..pi, pi==fh_active_preset_idx) then
                                fh_active_preset_idx = pi
                                settings.active_preset = pi
                                fh_lv_autosell_preset = settings.presets[pi].items or {}
                                _G.as_price_buf = nil; _G.as_qty_buf = nil
                                _wfn7p()
                            end
                        end
                        imgui.EndCombo()
                    end
                    imgui.PopItemWidth()
                    imgui.SameLine(0,3*d)
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(bb_r, bb_g, bb_b, 1))
                    if imgui.Button(_ic_circp..'##addp', imgui.ImVec2(cw_p*0.18,0)) then
                        local np = {name='Preset '..((#(settings.presets or {}))+1), items={}}
                        if not settings.presets then settings.presets={} end
                        table.insert(settings.presets, np)
                        fh_active_preset_idx = #settings.presets
                        settings.active_preset = fh_active_preset_idx
                        fh_lv_autosell_preset = {}
                        _G.as_price_buf=nil; _G.as_qty_buf=nil
                        _wfn7p()
                    end
                    imgui.PopStyleColor()
                    imgui.SameLine(0,2*d)
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5,0.08,0.08,1))
                    if imgui.Button(_ic_trash..'##delp', imgui.ImVec2(cw_p*0.15,0)) then
                        if #(settings.presets or {}) > 1 then
                            table.remove(settings.presets, fh_active_preset_idx)
                            fh_active_preset_idx = math.max(1, fh_active_preset_idx - 1)
                            settings.active_preset = fh_active_preset_idx
                            fh_lv_autosell_preset = settings.presets[fh_active_preset_idx].items or {}
                            _G.as_price_buf=nil; _G.as_qty_buf=nil
                            _wfn7p()
                        else
                            sampAddChatMessage('[MH] {ff4444}Нельзя удалить единственный пресет.', 0xFFFFFF)
                        end
                    end
                    imgui.PopStyleColor()
                    imgui.SameLine(0,2*d)
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.25,0.15,0,1))
                    if imgui.Button(_ic_pen..' '.._cyr5f('Имя##renp'), imgui.ImVec2(-1,0)) then
                        _G._renaming_preset = not _G._renaming_preset
                        local cur = settings.presets and settings.presets[fh_active_preset_idx]
                        _G._new_preset_name_buf = imgui.new.char[32](cur and cur.name or '')
                    end
                    imgui.PopStyleColor()
                    if _G._renaming_preset then
                        if not _G._new_preset_name_buf then _G._new_preset_name_buf=imgui.new.char[32]('') end
                        imgui.PushItemWidth(-1)
                        if imgui.InputText('##pren', _G._new_preset_name_buf, 32, imgui.InputTextFlags.EnterReturnsTrue) then
                            local nm = ffi.string(_G._new_preset_name_buf):match('^%s*(.-)%s*$')
                            local _ok_nm, nm_dec = pcall(function() return require('encoding').UTF8:decode(nm) end)
                            if _ok_nm and nm_dec and #nm_dec > 0 then nm = nm_dec end
                            if nm~='' and settings.presets and settings.presets[fh_active_preset_idx] then
                                settings.presets[fh_active_preset_idx].name = nm
                                _wfn7p()
                            end
                            _G._renaming_preset = false
                        end
                        imgui.PopItemWidth()
                    end
                if not _G.as_sort_mode then _G.as_sort_mode = 0 end  -- 0=назв, 1=цена, 2=популяр
                local sort_labels = {_cyr5f('Сорт: А-Я'), _cyr5f('Сорт: Цена'), _cyr5f('Сорт: Рынок')}
                if imgui.Button(sort_labels[_G.as_sort_mode+1]..'##assort', imgui.ImVec2(0,0)) then
                    _G.as_sort_mode = (_G.as_sort_mode + 1) % 3
                    if _G.as_sort_mode == 1 then
                        table.sort(fh_lv_autosell_preset, function(a,b) return (a.price or 0) > (b.price or 0) end)
                    elseif _G.as_sort_mode == 2 then
                        -- Префетчим qty по каждому товару ОДИН раз, чтобы _mjg5t
                        -- не вызывался O(N log N) раз внутри компаратора (тормоза).
                        local _qty_cache = {}
                        for _i_qc = 1, #fh_lv_autosell_preset do
                            local _it = fh_lv_autosell_preset[_i_qc]
                            local _e  = _it and fh_mkt_prices[_it.name]
                            local _s  = _e and _e.cp_hist and _mjg5t(_e.cp_hist, 30) or nil
                            _qty_cache[_it] = (_s and _s.qty) or 0
                        end
                        table.sort(fh_lv_autosell_preset, function(a,b)
                            return (_qty_cache[a] or 0) > (_qty_cache[b] or 0)
                        end)
                    else
                        table.sort(fh_lv_autosell_preset, function(a,b) return (a.name or '') < (b.name or '') end)
                    end
                    _G.as_price_buf=nil; _G.as_qty_buf=nil
                    local active_p = settings.presets and settings.presets[fh_active_preset_idx]
                    if active_p then active_p.items = fh_lv_autosell_preset end
                    settings.autosell_preset = fh_lv_autosell_preset
                    _wfn7p()
                end
                imgui.SameLine(0,6*d)
                imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f('Пресет ('..#fh_lv_autosell_preset..')'))
                imgui.SameLine(0,6*d)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(sb_r, sb_g, sb_b, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.4, sb_g*1.4, sb_b*1.4, 1))
                if imgui.Button(_ic_save..' '.._cyr5f('\xd1\xee\xf5\xf0.\xcf\xf0\xe5\xf1\xe5\xf2##assave'), imgui.ImVec2(0,0)) then
                    _tcv8f()
                    sampAddChatMessage('[MH] {00cc00}\xcf\xf0\xe5\xf1\xe5\xf2 \xf1\xee\xf5\xf0\xe0\xed\xb8\xed.', 0xFFFFFF)
                end
                imgui.PopStyleColor(2)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(sb_r, sb_g, sb_b, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.4, sb_g*1.4, sb_b*1.4, 1))
                if imgui.Button(_ic_warn..' '.._cyr5f('\xcc\xe0\xea\xf1 \xe2\xf1\xe5##asmaxall'), imgui.ImVec2(-1, 0)) then
                    local updated = 0
                    for _maxasi, _maxasp in ipairs(fh_lv_autosell_preset) do
                        for _, _inv in ipairs(fh_lv_inventory) do
                            if _inv.name:lower() == _maxasp.name:lower() and _inv.count > 0 then
                                _maxasp.qty = _inv.count
                                if _G.as_qty_buf and _G.as_qty_buf[_maxasi] then
                                    _G.as_qty_buf[_maxasi] = imgui.new.char[16](tostring(_inv.count))
                                end
                                updated = updated + 1
                                break
                            end
                        end
                    end
                    _G.as_qty_buf = nil
                    _tcv8f()
                    sampAddChatMessage('[MH] {00cc00}\xcc\xe0\xea\xf1 \xe2\xf1\xe5: \xee\xe1\xed\xee\xe2\xeb\xe5\xed\xee ' .. updated .. ' \xf2\xee\xe2\xe0\xf0\xee\xe2.', 0xFFFFFF)
                end
                imgui.PopStyleColor(2)
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(_cyr5f('\xd3\xf1\xf2\xe0\xed\xee\xe2\xe8\xf2\xfc \xea\xee\xeb-\xe2\xee \xe8\xe7 \xe8\xed\xe2\xe5\xed\xf2\xe0\xf0\xff\n\xe4\xeb\xff \xe2\xf1\xe5\xf5 \xf2\xee\xe2\xe0\xf0\xee\xe2 \xef\xf0\xe5\xf1\xe5\xf2\xe0 \xf1\xf0\xe0\xe7\xf3'))
                end
                imgui.Separator()
                if not _G.as_preset_srch_buf then _G.as_preset_srch_buf = imgui.new.char[64]('') end
                if not _G.as_preset_srch then _G.as_preset_srch = '' end
                imgui.PushItemWidth(-1)
                if imgui.InputTextWithHint('##aspresetsrch', _cyr5f('Поиск...'), _G.as_preset_srch_buf, 64) then
                    _G.as_preset_srch = u8:decode(ffi.string(_G.as_preset_srch_buf)):lower()
                end
                imgui.PopItemWidth()
                if #fh_lv_autosell_preset == 0 then
                    imgui.TextDisabled(_cyr5f('  Пусто. Кликните'))
                    imgui.TextDisabled(_cyr5f('  товар слева.'))
                end
                -- _lv_shops_cache пересчитывается в фоне (см. lua_thread ниже).
                -- В draw только читаем готовый кеш — никаких тяжёлых циклов.
                local del_as_i = nil
                for asi, asp in ipairs(fh_lv_autosell_preset) do
                    if _G.as_preset_srch and _G.as_preset_srch ~= '' and not asp.name:lower():find(_G.as_preset_srch, 1, true) then
                    else
                    if not _G.as_price_buf then _G.as_price_buf={} end
                    if not _G.as_qty_buf   then _G.as_qty_buf={} end
                    if not _G.as_price_buf[asi] then _G.as_price_buf[asi]=imgui.new.char[32](_vnh1j(asp.price or 0)) end
                    if not _G.as_qty_buf[asi]   then _G.as_qty_buf[asi]=imgui.new.char[16](tostring(asp.qty or 1)) end
                    local _asp_mkt_e = fh_mkt_prices[asp.name]
                    local _asp_avg_cp = nil
                    local _asp_today_cp = nil  -- цена сегодня
                    if _asp_mkt_e then
                        if _asp_mkt_e.cp_hist and #_asp_mkt_e.cp_hist > 0 then
                            local _s7 = _mjg5t(_asp_mkt_e.cp_hist, 7)
                            _asp_avg_cp = _s7 and _s7.avg
                            local _last = _asp_mkt_e.cp_hist[#_asp_mkt_e.cp_hist]
                            if type(_last) == "table" then
                                _asp_today_cp = tonumber(_last.avg) or tonumber(_last.v) or tonumber(_last.price) or nil
                            else
                                _asp_today_cp = tonumber(_last) or nil
                            end
                        end
                        if not _asp_avg_cp then _asp_avg_cp = _asp_mkt_e.s_avg or _asp_mkt_e.b_avg end
                        if not _asp_today_cp then _asp_today_cp = _asp_avg_cp end
                    end
                    local _nm_lo_asp = asp.name:lower()
                    local _lv_entry = _G._lv_shops_cache and _G._lv_shops_cache[_nm_lo_asp]
                    local _sell_lv  = _lv_entry and _lv_entry.sell
                    local _buy_lv   = _lv_entry and _lv_entry.buy
                    local _asp_avg_lv = _sell_lv or _buy_lv
                    imgui.TextColored(imgui.ImVec4(1,1,1,1), _cyr5f(asp.name))
                    if _asp_avg_cp then
                        imgui.SameLine(0,8*d)
                        imgui.TextColored(imgui.ImVec4(1,0.75,0.2,1), _cyr5f('Рынок:$'.._kcr3y(_asp_avg_cp)))
                    end
                    if _asp_avg_lv then
                        if _buy_lv then
                            imgui.TextColored(imgui.ImVec4(0.5,0.7,1,1), _cyr5f('Скупают:$'.._kcr3y(_buy_lv)))
                            imgui.SameLine(0,6*d)
                        end
                        if _sell_lv then
                            imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f('Продают:$'.._kcr3y(_sell_lv)))
                        end
                    end
                    do
                        local fw = right_w - 14*d
                        local x_w2  = 26*d
                        local qty_w2 = 50*d
                        local price_w2 = fw - qty_w2 - x_w2 - 6*d
                        if price_w2 < 40*d then price_w2 = 40*d end
                        imgui.PushItemWidth(price_w2)
                        if imgui.InputText('##asp'..asi, _G.as_price_buf[asi], 32) then
                            local _raw = ffi.string(_G.as_price_buf[asi])
                            local _val = _sxp3d(_raw)
                            if _val > 0 then asp.price = _val end
                            _G.as_price_buf[asi] = imgui.new.char[32](_vnh1j(asp.price or 0))
                            _tcv8f()
                        end
                        imgui.PopItemWidth()
                        imgui.SameLine(0,3*d)
                        imgui.PushItemWidth(qty_w2)
                        if imgui.InputText('##asq'..asi, _G.as_qty_buf[asi], 16) then
                            asp.qty = tonumber(ffi.string(_G.as_qty_buf[asi])) or asp.qty
                            _tcv8f()
                        end
                        imgui.PopItemWidth()
                        imgui.SameLine(0,3*d)
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45,0.08,0.08,1))
                        if imgui.Button(_ic_x..'##asd'..asi, imgui.ImVec2(x_w2, 0)) then del_as_i=asi end
                        imgui.PopStyleColor()
                    end
                    do
                        local _has_nw = _asp_avg_cp ~= nil
                        local _has_rn = _asp_avg_cp ~= nil
                        local _has_sg = _asp_today_cp ~= nil
                        local _has_lv = _asp_avg_lv ~= nil
                        local _has_sk = _buy_lv ~= nil
                        local _has_pr = _sell_lv ~= nil
                        local _btn_cnt = (_has_nw and 1 or 0) + (_has_rn and 1 or 0)
                                       + (_has_sg and 1 or 0) + (_has_sk and 1 or 0)
                                       + (_has_pr and 1 or 0)
                        if _btn_cnt < 1 then _btn_cnt = 1 end
                        local _bw4 = (right_w - 14*d - math.max(0,_btn_cnt-1)*3*d) / _btn_cnt
                        if _has_nw then
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.40,0.25,0.02,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55,0.35,0.04,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1,0.85,0.3,1))
                            if imgui.Button(_cyr5f('Неделя##ascp'..asi), imgui.ImVec2(_bw4, 0)) then
                                asp.price = _asp_avg_cp
                                _G.as_price_buf[asi] = imgui.new.char[32](_vnh1j(_asp_avg_cp))
                                _tcv8f()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Ср. 7 дн: $'.._kcr3y(_asp_avg_cp))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_rn then
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.05,0.35,0.18,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.08,0.50,0.26,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.6,1))
                            local _n_shown = _has_nw and 1 or 0
                            local _rn_w = (_n_shown > 0) and _bw4 or (right_w - 14*d)
                            if imgui.Button(_cyr5f('Рынок##asrn'..asi), imgui.ImVec2(_rn_w, 0)) then
                                asp.price = _asp_avg_cp
                                _G.as_price_buf[asi] = imgui.new.char[32](_vnh1j(_asp_avg_cp))
                                _tcv8f()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Рынок (7дн): $'.._kcr3y(_asp_avg_cp))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_sg then
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.0,0.28,0.50,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.0,0.40,0.70,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.5,0.85,1,1))
                            if imgui.Button(_cyr5f('Сегодня##astoday'..asi), imgui.ImVec2(_bw4, 0)) then
                                local _tcp = tonumber(_asp_today_cp) or 0
                                asp.price = math.floor(_tcp)
                                _G.as_price_buf[asi] = imgui.new.char[32](_vnh1j(math.floor(_tcp)))
                                _tcv8f()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Цена сегодня: $'.._kcr3y(_asp_today_cp))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_sk then
                            local _sk_price = _buy_lv
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.30,0.08,0.42,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.42,0.12,0.58,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.85,0.55,1,1))
                            if imgui.Button(_cyr5f('Скупка##assk'..asi), imgui.ImVec2(_bw4, 0)) then
                                asp.price = _sk_price
                                _G.as_price_buf[asi] = imgui.new.char[32](_vnh1j(_sk_price))
                                _tcv8f()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Ср. цена скупки: $'.._kcr3y(_sk_price))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_pr then
                            local _pr_price = _sell_lv
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(sb_r*0.8, sb_g*0.9, sb_b*0.8, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.2, sb_g*1.2, sb_b*1.2, 1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.5,1,0.5,1))
                            if imgui.Button(_cyr5f('Продажа##aspr'..asi), imgui.ImVec2(_bw4, 0)) then
                                asp.price = _pr_price
                                _G.as_price_buf[asi] = imgui.new.char[32](_vnh1j(_pr_price))
                                _tcv8f()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Ср. цена продажи: $'.._kcr3y(_pr_price))) end
                        end
                    end
                    imgui.Separator()
                end
                end  -- filter preset
                if del_as_i then table.remove(fh_lv_autosell_preset,del_as_i); _G.as_price_buf=nil; _G.as_qty_buf=nil
    _tcv8f() end
                imgui.EndChild()
            end
        end

        if _G.mh_tab == 4 then
            local cw_lv2 = imgui.GetWindowContentRegionWidth()
            local left_w2 = math.floor(cw_lv2 * 0.42)
            local right_w2 = cw_lv2 - left_w2 - 8*d
            if fh_lv_autobuy_running then
                imgui.TextColored(imgui.ImVec4(1,0.75,0,1), _cyr5f('  Авто-скуп: '..fh_lv_autobuy_status))
                imgui.ProgressBar(-1*os.clock(), imgui.ImVec2(-1, 5*d))
                if imgui.Button(_ic_circs..' '.._cyr5f('Стоп##abstop'), imgui.ImVec2(-1,0)) then fh_lv_autobuy_running=false end
            else
                if fh_lv_autobuy_status ~= '' then
                    imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f('  '..fh_lv_autobuy_status))
                else
                    imgui.TextDisabled(_cyr5f('  Лево: база цен  |  Право: пресет скупа'))
                end
                do
                    local _bal = 0
                    pcall(function() _bal = getPlayerMoney(PLAYER_PED) end)
                    local _preset_cnt = #fh_lv_autobuy_preset
                    local _has_preset = _preset_cnt > 0
                    if not _G.ab_budget_open then _G.ab_budget_open = false end
                    if not _G.ab_budget_buf  then _G.ab_budget_buf  = imgui.new.char[32](_vnh1j(_bal)) end

                    local _bw_dist = imgui.GetWindowContentRegionWidth() * 0.42
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.25,0.15,0.42,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.38,0.22,0.62,1))
                    if imgui.Button(_ic_coin..' '.._cyr5f('Распределить бюджет##abdist'), imgui.ImVec2(_bw_dist, 0)) then
                        if not _has_preset then
                            sampAddChatMessage('[MH] {ffaa44}Пресет скупки пуст', 0xFFFFFF)
                        else
                            _G.ab_budget_open = not _G.ab_budget_open
                            if _G.ab_budget_open then
                                _G.ab_budget_buf = imgui.new.char[32](_vnh1j(_bal))
                            end
                        end
                    end
                    imgui.PopStyleColor(2)
                    imgui.SameLine(0, 6*d)

                    if _G.ab_budget_open then
                        imgui.Spacing()
                        imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.12,0.08,0.20,1))
                        imgui.PushStyleColor(imgui.Col.Border,  imgui.ImVec4(0.55,0.30,0.90,0.8))
                        if imgui.BeginChild('##ab_budget_pop', imgui.ImVec2(-1, 60*d), true) then
                            imgui.Spacing()
                            imgui.TextColored(imgui.ImVec4(0.75,0.55,1,1), _ic_coin..'  ')
                            imgui.SameLine(0,4*d)
                            imgui.TextDisabled(_cyr5f('Бюджет на скупку $:'))
                            imgui.SameLine(0,6*d)
                            imgui.PushItemWidth(130*d)
                            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.18,0.10,0.30,1))
                            if imgui.InputText('##ab_budget_inp', _G.ab_budget_buf, 32) then
                                local _raw_v = ffi.string(_G.ab_budget_buf)
                                local _num_v = tonumber((_raw_v:gsub('[%.]','')))
                                if _num_v and _num_v > 0 then
                                    local _fmt_v = _vnh1j(_num_v)
                                    if _fmt_v ~= _raw_v and not _raw_v:match('%.$') then
                                        _G.ab_budget_buf = imgui.new.char[32](_fmt_v)
                                    end
                                end
                            end
                            imgui.PopStyleColor()
                            imgui.PopItemWidth()
                            imgui.SameLine(0,6*d)
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.20,0.45,0.20,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.28,0.65,0.28,1))
                            if imgui.Button(_ic_chk..' '.._cyr5f('Применить##abdoapply'), imgui.ImVec2(0,0)) then
                                local _inp_raw = ffi.string(_G.ab_budget_buf)
                                local _budget = _sxp3d(_inp_raw)
                                if _budget > 0 and _has_preset then
                                    local _n = #fh_lv_autobuy_preset
                                    local _share_each = _budget / _n
                                    for _abi, _abp in ipairs(fh_lv_autobuy_preset) do
                                        local _price = math.max(1, _abp.max_price or 1)
                                        local _new_qty = math.max(1, math.floor(_share_each / _price))
                                        _abp.qty = _new_qty
                                        if _G.ab_qty_buf and _G.ab_qty_buf[_abi] then
                                            _G.ab_qty_buf[_abi] = imgui.new.char[16](tostring(_new_qty))
                                        end
                                    end
                                    settings.autobuy_preset = fh_lv_autobuy_preset
                                    _wfn7p()
                                    sampAddChatMessage('[MH] {aaffaa}Бюджет $'.._kcr3y(_budget)..' распределён по '..#fh_lv_autobuy_preset..' товарам (по $'.._kcr3y(math.floor(_share_each))..' на товар)', 0xFFFFFF)
                                    _G.ab_budget_open = false
                                else
                                    sampAddChatMessage('[MH] {ff4444}Введите сумму больше 0', 0xFFFFFF)
                                end
                            end
                            imgui.PopStyleColor(2)
                            imgui.SameLine(0,4*d)
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.35,0.08,0.08,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55,0.12,0.12,1))
                            if imgui.Button(_ic_x..'##abbudgetclose', imgui.ImVec2(0,0)) then
                                _G.ab_budget_open = false
                            end
                            imgui.PopStyleColor(2)
                            imgui.EndChild()
                        end
                        imgui.PopStyleColor(2)
                        imgui.Spacing()
                    end
                end
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(bb_r, bb_g, bb_b, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(bb_r*1.35, bb_g*1.35, bb_b*1.35, 1))
                if imgui.Button(_ic_bolt..' '.._cyr5f('Запустить авто-скуп##abrun'), imgui.ImVec2(-1,0)) then _xpk6g() end
                imgui.PopStyleColor(2)
            end
            if #fh_lv_autobuy_preset > 0 then
                local total_buy = 0
                for _, abp in ipairs(fh_lv_autobuy_preset) do
                    total_buy = total_buy + (abp.max_price or 0) * (abp.qty or 1)
                end
                imgui.TextColored(imgui.ImVec4(0.4,0.9,0.4,1), _cyr5f('  Итого скуп: $' .. _kcr3y(total_buy)))
            end
            imgui.Separator()
            local panel_h2 = imgui.GetWindowHeight() - 105*d
            if imgui.BeginChild('##ab_all', imgui.ImVec2(left_w2, panel_h2), true) then
                _dpn1w()  -- swipe scroll
                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f('База цен:'))
                imgui.Separator()
                if not _G.ab_srch_buf then _G.ab_srch_buf = imgui.new.char[64]('') end
                imgui.PushItemWidth(-1)
                if imgui.InputTextWithHint('##absrch', _cyr5f('Поиск...'), _G.ab_srch_buf, 64) then
                    fh_lv_allitems_srch = u8:decode(ffi.string(_G.ab_srch_buf)):lower()
                end
                imgui.PopItemWidth()
                local srch_ab = fh_lv_allitems_srch or ''
                if not _G.ab_sort_popular then _G.ab_sort_popular = false end
                local sort_color = _G.ab_sort_popular
                    and imgui.ImVec4(sb_r*1.4, sb_g*1.4, sb_b*1.4, 1)
                    or  imgui.ImVec4(0.2, 0.2, 0.2, 1)
                imgui.PushStyleColor(imgui.Col.Button, sort_color)
                local sort_lbl = _G.ab_sort_popular
                    and _cyr5f('в Рейтинг: по популярности')
                    or  _cyr5f('Рейтинг: по названию')
                if imgui.Button(sort_lbl..'##absort', imgui.ImVec2(-1, 0)) then
                    _G.ab_sort_popular = not _G.ab_sort_popular
                    _G.ab_sorted_cache = nil
                end
                imgui.PopStyleColor()
                if #srch_ab < 2 and not _G.ab_sort_popular then
                    imgui.Spacing()
                    imgui.TextDisabled(_cyr5f('  Рвведите минимум 2 символа'))
                    imgui.TextDisabled(_cyr5f('  для поиска товара'))
                else
                    local all_items
                    if _G.ab_sort_popular then
                        if not _G.ab_sorted_cache then
                            local raw = fh_get_allitems_list()
                            local scored = {}
                            for _, nm in ipairs(raw) do
                                local e = fh_mkt_prices[nm]
                                local qty30 = 0
                                if e and e.cp_hist then
                                    local s = _mjg5t(e.cp_hist, 30)
                                    qty30 = s and s.qty or 0
                                end
                                table.insert(scored, {name=nm, qty=qty30})
                            end
                            table.sort(scored, function(a,b) return a.qty > b.qty end)
                            _G.ab_sorted_cache = scored
                        end
                        all_items = {}
                        for _, v in ipairs(_G.ab_sorted_cache) do
                            table.insert(all_items, v.name)
                        end
                    else
                        all_items = fh_get_allitems_list()
                    end
                    local all_items = all_items
                    local shown = 0
                    for _, nm in ipairs(all_items) do
                        if nm:lower():find(srch_ab, 1, true) then
                            local already2 = false
                            for _, p2 in ipairs(fh_lv_autobuy_preset) do
                                if p2.name == nm then already2=true; break end
                            end
                            local e2 = fh_mkt_prices[nm]
                            local ph = e2 and (e2.s_avg or e2.b_avg) or 0
                            local lbl2 = _cyr5f(nm..(ph>0 and ('  $'.._kcr3y(ph)) or ''))
                            imgui.Spacing()
                            if not already2 then
                                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(bb_r, bb_g*0.85, bb_b*0.85, 1))
                                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(bb_r*1.35, bb_g*1.2, bb_b*1.1, 1))
                                if imgui.Button(lbl2..'##aball_'..nm, imgui.ImVec2(-1,0)) then
                                    table.insert(fh_lv_autobuy_preset,{name=nm,max_price=0,qty=1})
                                    _G.ab_max_buf=nil; _G.ab_qty_buf=nil; _G.ab_srch_item_buf=nil
                                    settings.autobuy_preset=fh_lv_autobuy_preset
                                    if settings.buy_presets and settings.buy_presets[fh_ab_preset_idx] then
                                        settings.buy_presets[fh_ab_preset_idx].items=fh_lv_autobuy_preset
                                    end
                                    _wfn7p()
                                end
                                imgui.PopStyleColor(2)
                            else
                                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.12,0.12,0.12,1))
                                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.45,0.45,0.45,1))
                                imgui.Button(lbl2..'##aball_'..nm, imgui.ImVec2(-1,0))
                                imgui.PopStyleColor(2)
                            end
                            shown = shown + 1
                            if shown >= 50 then
                                imgui.Spacing()
                                imgui.TextDisabled(_cyr5f('  ... уточните поиск'))
                                break
                            end
                        end
                    end
                    if shown == 0 then
                        imgui.Spacing()
                        imgui.TextDisabled(_cyr5f('  Ничего не найдено'))
                    end
                end
                imgui.EndChild()
            end
            imgui.SameLine(0,8*d)
            if imgui.BeginChild('##ab_preset', imgui.ImVec2(right_w2, panel_h2), true) then
                _dpn1w()  -- swipe scroll
                if not settings.buy_presets then settings.buy_presets = {{name='\xcf\xf0\xe5\xf1\xe5\xf2 1', items={}}} end
                if not _G.ab_preset_synced then
                    local cur = settings.buy_presets[fh_ab_preset_idx]
                    if cur then fh_lv_autobuy_preset = cur.items or {} end
                    _G.ab_preset_synced = true
                end
                local ab_names = {}
                for pi, pr in ipairs(settings.buy_presets) do
                    ab_names[pi] = _cyr5f(pr.name or ('\xcf\xf0\xe5\xf1\xe5\xf2 '..pi))
                end
                imgui.PushItemWidth(right_w2 * 0.50)
                if imgui.BeginCombo('##abpreset_sel', ab_names[fh_ab_preset_idx] or _cyr5f('\xcf\xf0\xe5\xf1\xe5\xf2 1')) then
                    for pi, pname in ipairs(ab_names) do
                        if imgui.Selectable(pname..'##abps'..pi, pi==fh_ab_preset_idx) then
                            fh_ab_preset_idx = pi
                            fh_lv_autobuy_preset = settings.buy_presets[pi].items or {}
                            settings.autobuy_preset = fh_lv_autobuy_preset
                            _G.ab_max_buf=nil; _G.ab_qty_buf=nil; _wfn7p()
                        end
                    end
                    imgui.EndCombo()
                end
                imgui.PopItemWidth()
                imgui.SameLine(0,3*d)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(bb_r, bb_g, bb_b, 1))
                if imgui.Button(_ic_circp..'##addabp', imgui.ImVec2(right_w2*0.18,0)) then
                    table.insert(settings.buy_presets, {name='\xcf\xf0\xe5\xf1\xe5\xf2 '..((#settings.buy_presets)+1), items={}})
                    fh_ab_preset_idx = #settings.buy_presets
                    fh_lv_autobuy_preset = {}
                    settings.autobuy_preset = fh_lv_autobuy_preset
                    _G.ab_max_buf=nil; _G.ab_qty_buf=nil; _wfn7p()
                end
                imgui.PopStyleColor()
                imgui.SameLine(0,2*d)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.5,0.08,0.08,1))
                if imgui.Button(_ic_trash..'##delabp', imgui.ImVec2(right_w2*0.15,0)) then
                    if #(settings.buy_presets or {}) > 1 then
                        table.remove(settings.buy_presets, fh_ab_preset_idx)
                        fh_ab_preset_idx = math.max(1, fh_ab_preset_idx - 1)
                        fh_lv_autobuy_preset = settings.buy_presets[fh_ab_preset_idx].items or {}
                        settings.autobuy_preset = fh_lv_autobuy_preset
                        _G.ab_max_buf=nil; _G.ab_qty_buf=nil
                        _wfn7p()
                    else
                        sampAddChatMessage('[MH] {ff4444}Нельзя удалить единственный пресет.', 0xFFFFFF)
                    end
                end
                imgui.PopStyleColor()
                imgui.SameLine(0,2*d)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.25,0.15,0,1))
                if imgui.Button(_ic_pen..' '.._cyr5f('\xc8\xec\xff##renabp'), imgui.ImVec2(-1,0)) then
                    _G._ren_abp = not _G._ren_abp
                    local cur = settings.buy_presets[fh_ab_preset_idx]
                    _G._abp_name_buf = imgui.new.char[32](cur and cur.name or '')
                end
                imgui.PopStyleColor()
                if _G._ren_abp then
                    if not _G._abp_name_buf then _G._abp_name_buf=imgui.new.char[32]('') end
                    imgui.PushItemWidth(-1)
                    if imgui.InputText('##abpren', _G._abp_name_buf, 32, imgui.InputTextFlags.EnterReturnsTrue) then
                        local nm = ffi.string(_G._abp_name_buf):match('^%s*(.-)%s*$')
                        local _ok_nm, nm_dec = pcall(function() return require('encoding').UTF8:decode(nm) end)
                        if _ok_nm and nm_dec and #nm_dec > 0 then nm = nm_dec end
                        if nm~='' and settings.buy_presets[fh_ab_preset_idx] then
                            settings.buy_presets[fh_ab_preset_idx].name = nm; _wfn7p()
                        end
                        _G._ren_abp = false
                    end
                    imgui.PopItemWidth()
                end
                if #fh_lv_autobuy_preset==0 then
                    imgui.TextDisabled(_cyr5f('  \xcf\xf3\xf1\xf2\xee. \xca\xeb\xe8\xea\xed\xe8\xf2\xe5'))
                    imgui.TextDisabled(_cyr5f('  \xf2\xee\xe2\xe0\xf0 \xf1\xeb\xe5\xe2\xe0.'))
                end
                if not _G.ab_preset_srch_buf2 then _G.ab_preset_srch_buf2 = imgui.new.char[64]('') end
                if not _G.ab_preset_srch2 then _G.ab_preset_srch2 = '' end
                if not _G.ab_preset_sort then _G.ab_preset_sort = 0 end  -- 0=А-Я 1=цена+ 2=цена- 3=сумма-
                imgui.PushItemWidth(right_w2 * 0.55)
                if imgui.InputTextWithHint('##abpresetsrch', _cyr5f('Поиск...'), _G.ab_preset_srch_buf2, 64) then
                    _G.ab_preset_srch2 = u8:decode(ffi.string(_G.ab_preset_srch_buf2)):lower()
                end
                imgui.PopItemWidth()
                imgui.SameLine(0, 4*d)
                local _ab_sort_lbls = {_cyr5f('А-Я'), _cyr5f('Цена+'), _cyr5f('Цена-'), _cyr5f('Сумма-')}
                imgui.PushStyleColor(imgui.Col.Button,
                    _G.ab_preset_sort > 0
                    and imgui.ImVec4(bb_r*0.6, bb_g*0.6, bb_b*0.6, 1)
                    or  imgui.ImVec4(0.18, 0.18, 0.18, 1))
                if imgui.Button(_ab_sort_lbls[_G.ab_preset_sort+1]..'##abpsort', imgui.ImVec2(-1, 0)) then
                    _G.ab_preset_sort = (_G.ab_preset_sort + 1) % 4
                end
                imgui.PopStyleColor()
                if not _G.ab_flt_min_buf then _G.ab_flt_min_buf = imgui.new.char[20]('') end
                if not _G.ab_flt_max_buf then _G.ab_flt_max_buf = imgui.new.char[20]('') end
                if not _G.ab_flt_min then _G.ab_flt_min = 0 end
                if not _G.ab_flt_max then _G.ab_flt_max = 0 end
                local _flt_hw = (right_w2 - 10*d) / 2
                imgui.PushItemWidth(_flt_hw)
                imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.10, 0.08, 0.06, 1))
                if imgui.InputTextWithHint('##abfltmin', _cyr5f('Мин цена...'), _G.ab_flt_min_buf, 20) then
                    _G.ab_flt_min = tonumber(ffi.string(_G.ab_flt_min_buf):match('%d+') or '0') or 0
                end
                imgui.PopStyleColor(); imgui.PopItemWidth()
                imgui.SameLine(0, 4*d)
                imgui.PushItemWidth(_flt_hw)
                imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.10, 0.08, 0.06, 1))
                if imgui.InputTextWithHint('##abfltmax', _cyr5f('Макс цена...'), _G.ab_flt_max_buf, 20) then
                    _G.ab_flt_max = tonumber(ffi.string(_G.ab_flt_max_buf):match('%d+') or '0') or 0
                end
                imgui.PopStyleColor(); imgui.PopItemWidth()
                local del_ab_i = nil
                local _ab_render_ids = {}
                for _abi_raw = 1, #fh_lv_autobuy_preset do
                    local _abp_r = fh_lv_autobuy_preset[_abi_raw]
                    if _G.ab_preset_srch2 and _G.ab_preset_srch2 ~= '' and not _abp_r.name:lower():find(_G.ab_preset_srch2, 1, true) then
                    elseif (_G.ab_flt_min or 0) > 0 and (_abp_r.max_price or 0) < _G.ab_flt_min then
                    elseif (_G.ab_flt_max or 0) > 0 and (_abp_r.max_price or 0) > _G.ab_flt_max then
                    else
                        table.insert(_ab_render_ids, _abi_raw)
                    end
                end
                local _ab_srt = _G.ab_preset_sort or 0
                if _ab_srt == 1 then  -- цена +
                    table.sort(_ab_render_ids, function(a,b)
                        return (fh_lv_autobuy_preset[a].max_price or 0) < (fh_lv_autobuy_preset[b].max_price or 0)
                    end)
                elseif _ab_srt == 2 then  -- цена -
                    table.sort(_ab_render_ids, function(a,b)
                        return (fh_lv_autobuy_preset[a].max_price or 0) > (fh_lv_autobuy_preset[b].max_price or 0)
                    end)
                elseif _ab_srt == 3 then  -- сумма -
                    table.sort(_ab_render_ids, function(a,b)
                        local _sa = (fh_lv_autobuy_preset[a].max_price or 0) * (fh_lv_autobuy_preset[a].qty or 1)
                        local _sb = (fh_lv_autobuy_preset[b].max_price or 0) * (fh_lv_autobuy_preset[b].qty or 1)
                        return _sa > _sb
                    end)
                else  -- А-Я
                    table.sort(_ab_render_ids, function(a,b)
                        return (fh_lv_autobuy_preset[a].name or '') < (fh_lv_autobuy_preset[b].name or '')
                    end)
                end
                for _, abi in ipairs(_ab_render_ids) do
                    local abp = fh_lv_autobuy_preset[abi]
                    if true then
                    if not _G.ab_max_buf then _G.ab_max_buf={} end
                    if not _G.ab_qty_buf then _G.ab_qty_buf={} end
                    if not _G.ab_max_buf[abi] then _G.ab_max_buf[abi]=imgui.new.char[32](_vnh1j(abp.max_price or 0)) end
                    if not _G.ab_qty_buf[abi] then _G.ab_qty_buf[abi]=imgui.new.char[16](tostring(abp.qty or 1)) end
                    local _abp_mkt_e = fh_mkt_prices[abp.name]
                    local _abp_avg_cp = nil
                    if _abp_mkt_e then
                        if _abp_mkt_e.cp_hist and #_abp_mkt_e.cp_hist > 0 then
                            local _abs7 = _mjg5t(_abp_mkt_e.cp_hist, 7)
                            _abp_avg_cp = _abs7 and _abs7.avg
                        end
                        if not _abp_avg_cp then _abp_avg_cp = _abp_mkt_e.s_avg or _abp_mkt_e.b_avg end
                    end
                    local _nm_lo_abp = abp.name:lower()
                    local _lv_entry2 = _G._lv_shops_cache and _G._lv_shops_cache[_nm_lo_abp]
                    local _sell_lv2  = _lv_entry2 and _lv_entry2.sell
                    local _buy_lv2   = _lv_entry2 and _lv_entry2.buy
                    local _abp_avg_lv = _sell_lv2 or _buy_lv2
                    imgui.TextColored(imgui.ImVec4(1,1,1,1), _cyr5f(abp.name))
                    if _abp_avg_cp then
                        imgui.SameLine(0,8*d)
                        imgui.TextColored(imgui.ImVec4(1,0.75,0.2,1), _cyr5f('Рынок:$'.._kcr3y(_abp_avg_cp)))
                    end
                    if _abp_avg_lv then
                        if _sell_lv2 then
                            imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f('Продают:$'.._kcr3y(_sell_lv2)))
                            imgui.SameLine(0,6*d)
                        end
                        if _buy_lv2 then
                            imgui.TextColored(imgui.ImVec4(0.5,0.7,1,1), _cyr5f('Скупают:$'.._kcr3y(_buy_lv2)))
                        end
                    end
                    do
                        local _item_total = (abp.max_price or 0) * (abp.qty or 1)
                        local _n_presets = #fh_lv_autobuy_preset
                        local _total_budget = 0
                        for _, _p in ipairs(fh_lv_autobuy_preset) do
                            _total_budget = _total_budget + ((_p.max_price or 0) * (_p.qty or 1))
                        end
                        local _pct = (_total_budget > 0) and math.floor(_item_total / _total_budget * 100) or 0
                        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1),
                            _cyr5f('Сумма: $'.._kcr3y(_item_total)..'  '..tostring(_pct)..'%'))
                    end
                    do
                        local fw2 = right_w2 - 14*d
                        local x_w3  = 26*d
                        local qty_w3 = 50*d
                        local price_w3 = fw2 - qty_w3 - x_w3 - 6*d
                        if price_w3 < 40*d then price_w3 = 40*d end
                        imgui.PushItemWidth(price_w3)
                        if imgui.InputText('##abm'..abi, _G.ab_max_buf[abi], 32) then
                            local _raw2 = ffi.string(_G.ab_max_buf[abi])
                            local _val2 = _sxp3d(_raw2)
                            if _val2 > 0 then abp.max_price = _val2 end
                            _G.ab_max_buf[abi] = imgui.new.char[32](_vnh1j(abp.max_price or 0))
                            settings.autobuy_preset=fh_lv_autobuy_preset; _wfn7p()
                        end
                        imgui.PopItemWidth()
                        imgui.SameLine(0,3*d)
                        imgui.PushItemWidth(qty_w3)
                        if imgui.InputText('##abq'..abi, _G.ab_qty_buf[abi], 16) then
                            abp.qty=tonumber(ffi.string(_G.ab_qty_buf[abi])) or abp.qty
                            settings.autobuy_preset=fh_lv_autobuy_preset; _wfn7p()
                        end
                        imgui.PopItemWidth()
                        imgui.SameLine(0,3*d)
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45,0.08,0.08,1))
                        if imgui.Button(_ic_x..'##abd'..abi, imgui.ImVec2(x_w3, 0)) then del_ab_i=abi end
                        imgui.PopStyleColor()
                    end
                    do
                        local _bw4b = (right_w2 - 14*d - 3*3*d) / 4
                        local _has_pr2 = _sell_lv2 ~= nil
                        local _has_sk2 = _buy_lv2 ~= nil
                        local _has_nw2 = _abp_avg_cp ~= nil
                        local _has_rn2 = _abp_avg_cp ~= nil
                        if _has_pr2 then
                            local _pr2 = _sell_lv2
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(sb_r*0.8, sb_g*0.9, sb_b*0.8, 1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.2, sb_g*1.2, sb_b*1.2, 1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.5,1,0.5,1))
                            if imgui.Button(_cyr5f('Продажа##abpr'..abi), imgui.ImVec2(_bw4b, 0)) then
                                abp.max_price = _pr2
                                _G.ab_max_buf[abi] = imgui.new.char[32](_vnh1j(_pr2))
                                settings.autobuy_preset=fh_lv_autobuy_preset; _wfn7p()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Ср. цена продажи: $'.._kcr3y(_pr2))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_sk2 then
                            local _sk2 = _buy_lv2
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.30,0.08,0.42,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.42,0.12,0.58,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.85,0.55,1,1))
                            if imgui.Button(_cyr5f('Скупка##absk'..abi), imgui.ImVec2(_bw4b, 0)) then
                                abp.max_price = _sk2
                                _G.ab_max_buf[abi] = imgui.new.char[32](_vnh1j(_sk2))
                                settings.autobuy_preset=fh_lv_autobuy_preset; _wfn7p()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Ср. цена скупки: $'.._kcr3y(_sk2))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_nw2 then
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.40,0.25,0.02,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55,0.35,0.04,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1,0.85,0.3,1))
                            if imgui.Button(_cyr5f('Неделя##abcp'..abi), imgui.ImVec2(_bw4b, 0)) then
                                abp.max_price = _abp_avg_cp
                                _G.ab_max_buf[abi] = imgui.new.char[32](_vnh1j(_abp_avg_cp))
                                settings.autobuy_preset=fh_lv_autobuy_preset; _wfn7p()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Ср. 7 дн: $'.._kcr3y(_abp_avg_cp))) end
                            imgui.SameLine(0,3*d)
                        end
                        if _has_rn2 then
                            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.05,0.35,0.18,1))
                            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.08,0.50,0.26,1))
                            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.4,1,0.6,1))
                            if imgui.Button(_cyr5f('Рынок##abrn'..abi), imgui.ImVec2(-1, 0)) then
                                abp.max_price = _abp_avg_cp
                                _G.ab_max_buf[abi] = imgui.new.char[32](_vnh1j(_abp_avg_cp))
                                settings.autobuy_preset=fh_lv_autobuy_preset; _wfn7p()
                            end
                            imgui.PopStyleColor(3)
                            if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('Рынок (7дн): $'.._kcr3y(_abp_avg_cp))) end
                        end
                    end
                    imgui.Separator()
                end
                   end  -- ab filter
                if del_ab_i then
                    table.remove(fh_lv_autobuy_preset,del_ab_i)
                    if _G.ab_qty_buf then
                        local nb={}
                        for i,v in pairs(_G.ab_qty_buf) do
                            if type(i)=='number' then
                                if i < del_ab_i then nb[i]=v
                                elseif i > del_ab_i then nb[i-1]=v end
                            end
                        end
                        _G.ab_qty_buf=nb
                    end
                    if _G.ab_max_buf then
                        local nb={}
                        for i,v in pairs(_G.ab_max_buf) do
                            if type(i)=='number' then
                                if i < del_ab_i then nb[i]=v
                                elseif i > del_ab_i then nb[i-1]=v end
                            end
                        end
                        _G.ab_max_buf=nb
                    end
                    _G.ab_srch_item_buf=nil
                    settings.autobuy_preset=fh_lv_autobuy_preset
                    if settings.buy_presets and settings.buy_presets[fh_ab_preset_idx] then
                        settings.buy_presets[fh_ab_preset_idx].items=fh_lv_autobuy_preset
                    end
                    _wfn7p()
                end
                imgui.EndChild()
            end
        end

        if _G.mh_tab == 5 then
            if not _G.log_overlay_open then _G.log_overlay_open = false end
            if not _G.ov_alpha_buf then _G.ov_alpha_buf = imgui.new.float(settings.overlay.alpha) end
            if not _G.ov_lines_buf then _G.ov_lines_buf = imgui.new.int(settings.overlay.lines) end
            if not _G.ov_sell_col  then _G.ov_sell_col  = imgui.new.float[3](settings.overlay.sell_r, settings.overlay.sell_g, settings.overlay.sell_b) end
            if not _G.ov_buy_col   then _G.ov_buy_col   = imgui.new.float[3](settings.overlay.buy_r,  settings.overlay.buy_g,  settings.overlay.buy_b)  end
            local ov_en = imgui.new.bool(settings.overlay.enabled)
            if imgui.Checkbox(_cyr5f('Плавающий лог##ovcheck'), ov_en) then
                settings.overlay.enabled = ov_en[0]; _wfn7p()
            end
            if settings.overlay.enabled then
                imgui.SameLine(0,10*d)
                if imgui.Button(_ic_gear..' '.._cyr5f('Настройки##ovset'), imgui.ImVec2(0,0)) then
                    _G.log_overlay_open = not _G.log_overlay_open
                end
                if _G.log_overlay_open then
                    imgui.Separator()
                    imgui.TextDisabled(_cyr5f('  Прозрачность:'))
                    imgui.PushItemWidth(-1)
                    if imgui.SliderFloat('##ovalpha', _G.ov_alpha_buf, 0.05, 1.0) then
                        settings.overlay.alpha=_G.ov_alpha_buf[0]; _wfn7p()
                    end
                    imgui.PopItemWidth()
                    imgui.TextDisabled(_cyr5f('  \xd1\xf2\xf0\xee\xea (\xec\xe0\xea\xf1):'))
                    imgui.PushItemWidth(-1)
                    if imgui.SliderInt('##ovlines', _G.ov_lines_buf, 3, 20) then
                        settings.overlay.lines=_G.ov_lines_buf[0]; _wfn7p()
                    end
                    imgui.PopItemWidth()
                    -- фильтр по периоду
                    imgui.TextDisabled(_cyr5f('  \xd4\xe8\xeb\xfc\xf2\xf0 \xef\xe5\xf0\xe8\xee\xe4\xe0:'))
                    do
                        local _ovfl = {
                            [0] = _cyr5f('\xc2\xf1\xe5'),
                            [1] = _cyr5f('\xd1\xe5\xe3\xee\xe4\xed\xff'),
                            [2] = _cyr5f('\xcd\xe5\xe4\xe5\xeb\xff'),
                            [3] = _cyr5f('\xcc\xe5\xf1\xff\xf6'),
                        }
                        for _ofi2 = 0, 3 do
                            if _ofi2 > 0 then imgui.SameLine(0, 3*d) end
                            local _ofa2 = _G.ov_day_filter == _ofi2
                            if _ofa2 then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15,0.45,0.15,0.9)) end
                            if imgui.Button(_ovfl[_ofi2]..'##ovdfs'.._ofi2, imgui.ImVec2(0,0)) then
                                _G.ov_day_filter = _ofi2
                                if not settings.overlay then settings.overlay = {} end
                                settings.overlay.day_filter = _ofi2; _wfn7p()
                            end
                            if _ofa2 then imgui.PopStyleColor() end
                        end
                    end
                    imgui.TextDisabled(_cyr5f('  \xc6\xe2\xe5\xf2 \xef\xf0\xee\xe4\xe0\xe6:'))
                    imgui.PushItemWidth(-1)
                    if imgui.ColorEdit3('##ovsell', _G.ov_sell_col) then
                        settings.overlay.sell_r=_G.ov_sell_col[0]; settings.overlay.sell_g=_G.ov_sell_col[1]; settings.overlay.sell_b=_G.ov_sell_col[2]; _wfn7p()
                    end
                    imgui.PopItemWidth()
                    imgui.TextDisabled(_cyr5f('  Цвет покупки:'))
                    imgui.PushItemWidth(-1)
                    if imgui.ColorEdit3('##ovbuy', _G.ov_buy_col) then
                        settings.overlay.buy_r=_G.ov_buy_col[0]; settings.overlay.buy_g=_G.ov_buy_col[1]; settings.overlay.buy_b=_G.ov_buy_col[2]; _wfn7p()
                    end
                    imgui.PopItemWidth()
                    imgui.TextDisabled(_cyr5f('  Расположение/размер - тащите оверлей в игре'))
                    imgui.Separator()
                end
            end
            if not _G.log_tab_mode then _G.log_tab_mode = 1 end  -- 0=сессия, 1=сделки
            if not _G.mkt_log_f2    then _G.mkt_log_f2 = imgui.new.char[128](''); _G.mkt_log_fs2='' end
            if not _G.mkt_log_page  then _G.mkt_log_page = 1 end
            local ar3 = settings.interface.accent_r or 1
            local ag3 = settings.interface.accent_g or .65
            local ab3 = settings.interface.accent_b or 0.0
            local sb_r = settings.interface.sell_btn_r or 0.10
            local sb_g = settings.interface.sell_btn_g or 0.45
            local sb_b = settings.interface.sell_btn_b or 0.10
            local bb_r = settings.interface.buy_btn_r  or 0.00
            local bb_g = settings.interface.buy_btn_g  or 0.28
            local bb_b = settings.interface.buy_btn_b  or 0.50
            local function tab_btn(label, mode)
                local active = _G.log_tab_mode == mode
                if active then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar3*.5, ag3*.5, ab3*.5, .9)) end
                if imgui.Button(_cyr5f(label)..'##lmode'..mode, imgui.ImVec2(0,0)) then _G.log_tab_mode=mode end
                if active then imgui.PopStyleColor() end
            end
            do
                tab_btn('\xd1\xe4\xe5\xeb\xea\xe8', 1)
                imgui.SameLine(0, 4*d)
                tab_btn('\xd7\xe0\xf2', 2)
                imgui.SameLine(0, 4*d)
                tab_btn('TG', 3)
            end
            imgui.Separator()

            if _G.log_tab_mode == 0 then
                local log_h = imgui.GetWindowHeight() - 120*d
                if imgui.BeginChild('##lv_tlog', imgui.ImVec2(-1, log_h), true) then
                    _dpn1w()  -- swipe scroll
                    local cw_sl = imgui.GetWindowContentRegionWidth()
                    local col1_sl = math.max(185*d, cw_sl - (105 + 130 + 48 + 95)*d - 8*d)
                    imgui.Columns(5,'##tlhdr',false)
                    imgui.SetColumnWidth(0,105*d); imgui.SetColumnWidth(1,col1_sl)
                    imgui.SetColumnWidth(2,130*d); imgui.SetColumnWidth(3,48*d); imgui.SetColumnWidth(4,95*d)
                    local hc=imgui.ImVec4(0.6,0.6,0.6,1)
                    imgui.TextColored(hc,_cyr5f(' \xc2\xf0.')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' \xd2\xee\xe2\xe0\xf0')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' \xd6\xe5\xed\xe0 $')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' \xd8\xf2.')); imgui.NextColumn()
                    imgui.TextColored(hc,_cyr5f(' \xd2\xe8\xef')); imgui.NextColumn()
                    imgui.Separator()
                    if #fh_lv_trade_log==0 then
                        imgui.TextDisabled(_cyr5f('  \xcb\xee\xe3 \xef\xf3\xf1\xf2.'))
                        for _=1,4 do imgui.NextColumn() end
                    end
                    for _,tl in ipairs(fh_lv_trade_log) do
                        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1),_cyr5f(' '..tl.dt)); imgui.NextColumn()
                        imgui.Text(_cyr5f(' '..tl.item)); imgui.NextColumn()
                        local _price_str = (tl.price and tl.price > 0)
                            and ('$'.._kcr3y(tl.price))
                            or '...'
                        imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1),_cyr5f(' '.._price_str)); imgui.NextColumn()
                        imgui.Text(_cyr5f(' '..tl.qty)); imgui.NextColumn()
                        local tc_l = tl.op=='sell' and imgui.ImVec4(0.3,0.92,0.3,1) or imgui.ImVec4(0.35,0.65,1,1)
                        local op_icon = tl.op=='sell' and (_ic_up..' ') or (_ic_dn..' ')
                        local op_l = tl.op=='sell' and _cyr5f('Продажа') or _cyr5f('Покупка')
                        if tl.status=='skip' then tc_l=imgui.ImVec4(0.55,0.55,0.55,1); op_icon=_ic_min..' '; op_l=_cyr5f('Прп.') end
                        imgui.TextColored(tc_l, op_icon.._cyr5f(op_l)); imgui.NextColumn()
                    end
                    imgui.Columns(1); imgui.EndChild()
                end
            elseif _G.log_tab_mode == 1 then
                local tot_log = #fh_mkt_log
                imgui.TextDisabled(_cyr5f(tot_log..' \xe7\xe0\xef.'))
                imgui.SameLine(0, 8*d)
                if imgui.Button(_ic_trash..' '.._cyr5f('\xce\xf7\xe8\xf1\xf2\xe8\xf2\xfc##lgclr'), imgui.ImVec2(0,0)) then
                    fh_mkt_log={}; _ryb5t()
                end
                -- day filter
                if not _G.log_day_filter then _G.log_day_filter = 1 end
                if not _G.log_day_sel_date then _G.log_day_sel_date = '' end
                -- collect unique dates from log
                local _all_dates = {}
                local _dates_seen = {}
                for _di = #fh_mkt_log, 1, -1 do
                    local _de = fh_mkt_log[_di]
                    if _de and _de.dt then
                        local _dk = _de.dt:sub(1,5)
                        if _dk ~= '' and not _dates_seen[_dk] then
                            _dates_seen[_dk] = true
                            table.insert(_all_dates, _dk)
                        end
                    end
                end
                local _ldf_labels = {
                    [0] = _cyr5f('\xc2\xf1\xe5'),
                    [1] = fa.CALENDAR_DAY..' '.._cyr5f('\xd1\xe5\xe3.'),
                    [2] = fa.CALENDAR_WEEK..' '.._cyr5f('\xcd\xe5\xe4.'),
                    [3] = fa.CALENDAR..' '.._cyr5f('\xcc\xe5\xf1.'),
                }
                for _fi = 0, 3 do
                    if _fi > 0 then imgui.SameLine(0, 5*d) end
                    local _fa2 = _G.log_day_filter == _fi
                    if _fa2 then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar3*.5, ag3*.5, ab3*.5, .9)) end
                    if imgui.Button(_ldf_labels[_fi]..'##ldf'.._fi, imgui.ImVec2(68*d, 0)) then
                        _G.log_day_filter = _fi; _G.mkt_log_page = 1
                    end
                    if _fa2 then imgui.PopStyleColor() end
                end
                imgui.SameLine(0, 5*d)
                do
                    local _fd4 = _G.log_day_filter == 4
                    if _fd4 then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar3*.5, ag3*.5, ab3*.5, .9)) end
                    if imgui.Button(_ic_calds..' '.._cyr5f('\xc4\xe0\xf2\xe0##ldf4'), imgui.ImVec2(68*d, 0)) then
                        _G.log_day_filter = 4; _G.mkt_log_page = 1
                        _G.log_day_popup_open = true
                    end
                    if _fd4 then imgui.PopStyleColor() end
                    if _G.log_day_filter == 4 and _G.log_day_sel_date ~= '' then
                        imgui.SameLine(0, 4*d)
                        imgui.TextDisabled(_G.log_day_sel_date)
                    end
                end
                if _G.log_day_popup_open and #_all_dates > 0 then
                    imgui.OpenPopup('##ldpick')
                    _G.log_day_popup_open = false
                end
                if imgui.BeginPopup('##ldpick') then
                    imgui.TextDisabled(_cyr5f('\xc2\xfb\xe1\xe5\xf0\xe8\xf2\xe5 \xe4\xe0\xf2\xf3:'))
                    imgui.Separator()
                    for _, _dd in ipairs(_all_dates) do
                        local _sel = _G.log_day_sel_date == _dd
                        if _sel then imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(ar3, ag3, ab3, 1)) end
                        if imgui.Selectable(_dd..'##dsel', _sel, 0, imgui.ImVec2(80*d, 0)) then
                            _G.log_day_sel_date = _dd; _G.log_day_filter = 4; _G.mkt_log_page = 1
                            imgui.CloseCurrentPopup()
                        end
                        if _sel then imgui.PopStyleColor() end
                    end
                    imgui.EndPopup()
                end
                imgui.PushItemWidth(-1)
                if imgui.InputText(u8'##log_srch2', _G.mkt_log_f2, 128) then
                    _G.mkt_log_fs2=u8:decode(ffi.string(_G.mkt_log_f2)):lower(); _G.mkt_log_page=1
                end
                imgui.PopItemWidth()
                -- day filter helper
                local function _mh_log_day_ok(le_dt)
                    if _G.log_day_filter == 0 then return true end
                    if not le_dt or le_dt == '' then return false end
                    -- le.dt format: "DD.MM HH:MM" or "DD.MM.YY HH:MM"
                    local now = os.time()
                    local t = os.date('*t', now)
                    local d_day  = string.format('%02d.%02d', t.day, t.month)
                    -- parse entry date prefix "DD.MM"
                    local e_day = le_dt:sub(1,5)
                    if _G.log_day_filter == 1 then
                        return e_day == d_day
                    elseif _G.log_day_filter == 2 then
                        local e_d = tonumber(le_dt:sub(1,2)) or 0
                        local e_m = tonumber(le_dt:sub(4,5)) or 0
                        local e_ts = os.time({year=t.year, month=e_m, day=e_d, hour=0, min=0, sec=0})
                        if e_ts > now then e_ts = os.time({year=t.year-1, month=e_m, day=e_d, hour=0, min=0, sec=0}) end
                        return (now - e_ts) <= (7 * 86400)
                    elseif _G.log_day_filter == 3 then
                        local e_d = tonumber(le_dt:sub(1,2)) or 0
                        local e_m = tonumber(le_dt:sub(4,5)) or 0
                        local e_ts = os.time({year=t.year, month=e_m, day=e_d, hour=0, min=0, sec=0})
                        if e_ts > now then e_ts = os.time({year=t.year-1, month=e_m, day=e_d, hour=0, min=0, sec=0}) end
                        return (now - e_ts) <= (30 * 86400)
                    elseif _G.log_day_filter == 4 then
                        return e_day == (_G.log_day_sel_date or '')
                    end
                    return true
                end
                local log_filt={}
                local lfs=_G.mkt_log_fs2 or ''
                for i=#fh_mkt_log,1,-1 do
                    local le=fh_mkt_log[i]
                    if le and le.item
                        and (lfs=='' or le.item:lower():find(lfs,1,true))
                        and _mh_log_day_ok(le.dt)
                    then
                        table.insert(log_filt,le)
                    end
                end
                local LOG_PAGE=60
                local log_pages=math.max(1,math.ceil(#log_filt/LOG_PAGE))
                if _G.mkt_log_page>log_pages then _G.mkt_log_page=log_pages end
                local lf_from=(_G.mkt_log_page-1)*LOG_PAGE+1
                local lf_to=math.min(_G.mkt_log_page*LOG_PAGE,#log_filt)
                local total_sell_sum, total_buy_sum, total_sell_cnt, total_buy_cnt = 0, 0, 0, 0
                for _, le2 in ipairs(log_filt) do
                    local is_s = fh_is_my_sell(le2)
                    if is_s then total_sell_sum=total_sell_sum+(le2.price or 0)*(le2.qty or 1); total_sell_cnt=total_sell_cnt+(le2.qty or 1)
                    else total_buy_sum=total_buy_sum+(le2.price or 0)*(le2.qty or 1); total_buy_cnt=total_buy_cnt+(le2.qty or 1) end
                end
                -- stats block above the list
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.0, 0.18, 0.05, 0.55))
                if imgui.BeginChild('##log_stat_bar', imgui.ImVec2(-1, 36*d), false) then
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4*d)
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.3,0.92,0.3,1))
                    imgui.Text(_ic_up..' '.._cyr5f('\xcf\xf0\xee\xe4\xe0\xe6\xe8: ').._cyr5f(total_sell_cnt..' \xf8\xf2.')..'  '.._ic_coin..' '.._cyr5f(_kcr3y(total_sell_sum)))
                    imgui.PopStyleColor()
                    imgui.SameLine(0, 20*d)
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.35,0.65,1.0,1))
                    imgui.Text(_ic_dn..' '.._cyr5f('\xcf\xee\xea\xf3\xef\xea\xe8: ').._cyr5f(total_buy_cnt..' \xf8\xf2.')..'  '.._ic_coin..' '.._cyr5f(_kcr3y(total_buy_sum)))
                    imgui.PopStyleColor()
                    imgui.EndChild()
                end
                imgui.PopStyleColor()
                local list_h3=imgui.GetWindowHeight()-imgui.GetCursorPosY()-48*d
                if imgui.BeginChild('##log_list2',imgui.ImVec2(-1,list_h3),true) then
                    _dpn1w()  -- swipe scroll
                    local cw_lg2 = imgui.GetWindowContentRegionWidth()
                    -- Фиксированные: Дата(120) Кол(40) Цена(125) Тип(88)
                    local fixed_lg2 = (120 + 40 + 125 + 98) * d
                    local flex_lg2 = math.max(cw_lg2 - fixed_lg2 - 8*d, (140 + 130) * d)
                    local col1_lg2 = math.floor(flex_lg2 * 0.52)  -- Товар
                    local col5_lg2 = flex_lg2 - col1_lg2           -- Ник
                    imgui.Columns(6,'##loghdr2',false)
                    imgui.SetColumnWidth(0,120*d); imgui.SetColumnWidth(1,col1_lg2)
                    imgui.SetColumnWidth(2,40*d);  imgui.SetColumnWidth(3,125*d)
                    imgui.SetColumnWidth(4,98*d);  imgui.SetColumnWidth(5,col5_lg2)
                    local ac3=imgui.ImVec4(ar3, ag3, ab3, 1)
                    imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'\xc4\xe0\xf2\xe0'); imgui.NextColumn()
                    imgui.TextColored(ac3,u8'\xd2\xee\xe2\xe0\xf0'); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'\xca\xee\xeb.'); imgui.NextColumn()
                    imgui.TextColored(ac3,u8'\xd6\xe5\xed\xe0 $'); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'\xd2\xe8\xef'); imgui.NextColumn()
                    imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),u8'\xcd\xe8\xea'); imgui.NextColumn()
                    imgui.Separator()
                    if #log_filt==0 then
                        imgui.TextDisabled(u8'  \xcb\xee\xe3 \xef\xf3\xf1\xf2.')
                        for _=1,5 do imgui.NextColumn() end
                    end
                    for ri=lf_from,lf_to do
                        local le=log_filt[ri]; if not le then break end
                        local is_sell = fh_is_my_sell(le)
                        local tc3=is_sell and imgui.ImVec4(0.4,0.95,0.4,1) or imgui.ImVec4(0.4,0.7,1,1)
                        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1),_cyr5f(' '..(le.dt or ''))); imgui.NextColumn()
                        do
                              local _istr = _cyr5f(' '..(le.item or ''))
                              local _itw  = imgui.CalcTextSize(_istr).x
                              local _isp  = imgui.GetCursorScreenPos()
                              local _ilh  = imgui.GetTextLineHeight()
                              imgui.InvisibleButton('##lgib'..ri, imgui.ImVec2(col1_lg2 - 4, _ilh))
                              if imgui.IsItemClicked(0) then
                                  _G.mkt_detail_item = le.item
                                  _G.mkt_detail_src  = 'cp'
                                  _G.mkt_detail_open = true
                              end
                              local _idl = imgui.GetWindowDrawList()
                              _idl:PushClipRect(_isp, imgui.ImVec2(_isp.x + col1_lg2 - 5, _isp.y + _ilh + 2), true)
                              local _ioff = 0
                              if _itw > col1_lg2 - 8 then
                                  local _isd  = _itw - col1_lg2 + 10
                                  local _ispd = 1.5
                                  local _ispt = _isd / 40 + 2 * _ispd
                                  local _iph  = math.fmod(imgui.GetTime() + ri * 0.47, _ispt)
                                  if _iph > _ispd then
                                      _ioff = math.min((_iph - _ispd) * 40, _isd)
                                  end
                                  if _iph >= _ispt - _ispd then _ioff = _isd end
                              end
                              _idl:AddText(imgui.ImVec2(_isp.x - _ioff, _isp.y), 0xE6FFFFFF, _istr)
                              _idl:PopClipRect()
                          end
                          imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(1,1,1,0.7),_cyr5f(' '..(le.qty or 1))); imgui.NextColumn()
                        local _total_price = (le.price or 0) * (le.qty or 1)
                        imgui.TextColored(tc3,_cyr5f(' $'.._kcr3y(_total_price))); imgui.NextColumn()
                        local _tc4 = is_sell and imgui.ImVec4(0.3,0.92,0.3,1) or imgui.ImVec4(0.35,0.65,1,1)
                        local _op4 = is_sell and (_ic_up..' '.._cyr5f('Продажа')) or (_ic_dn..' '.._cyr5f('Покупка'))
                        imgui.TextColored(_tc4, _op4); imgui.NextColumn()
                        local _partner = le.partner or ''
                          do
                              local _nstr = _partner ~= '' and _cyr5f(' '.._partner) or ' —'
                              local _ncol = _partner ~= '' and 0xFFDADADA or 0xFF808080
                              local _ntw  = imgui.CalcTextSize(_nstr).x
                              local _nsp  = imgui.GetCursorScreenPos()
                              local _nlh  = imgui.GetTextLineHeight()
                              imgui.Dummy(imgui.ImVec2(col5_lg2 - 4, _nlh))
                              local _ndl = imgui.GetWindowDrawList()
                              _ndl:PushClipRect(_nsp, imgui.ImVec2(_nsp.x + col5_lg2 - 5, _nsp.y + _nlh + 2), true)
                              local _noff = 0
                              if _ntw > col5_lg2 - 8 then
                                  local _nsd  = _ntw - col5_lg2 + 10
                                  local _nspd = 1.5
                                  local _nspt = _nsd / 40 + 2 * _nspd
                                  local _nph  = math.fmod(imgui.GetTime() + ri * 0.47 + 0.3, _nspt)
                                  if _nph > _nspd then
                                      _noff = math.min((_nph - _nspd) * 40, _nsd)
                                  end
                                  if _nph >= _nspt - _nspd then _noff = _nsd end
                              end
                              _ndl:AddText(imgui.ImVec2(_nsp.x - _noff, _nsp.y), _ncol, _nstr)
                              _ndl:PopClipRect()
                          end
                          imgui.NextColumn()
                    end
                    imgui.Columns(1); imgui.EndChild()
                end
                local pw3=42*d
                if imgui.Button(_ic_ll..'##lgpp',imgui.ImVec2(pw3,0)) then _G.mkt_log_page=1 end
                imgui.SameLine(0,4*d)
                if imgui.Button(_ic_al..'##lgpr',imgui.ImVec2(pw3,0)) then if _G.mkt_log_page>1 then _G.mkt_log_page=_G.mkt_log_page-1 end end
                imgui.SameLine(0,6*d)
                imgui.TextColored(imgui.ImVec4(ar3, ag3, ab3, 1),_cyr5f('\xd1\xf2\xf0. '.._G.mkt_log_page..'/'..log_pages..' ('..#log_filt..')'))
                imgui.SameLine(0,6*d)
                if imgui.Button(_ic_ar..'##lgnx',imgui.ImVec2(pw3,0)) then if _G.mkt_log_page<log_pages then _G.mkt_log_page=_G.mkt_log_page+1 end end
                imgui.SameLine(0,4*d)
                if imgui.Button(_ic_rr..'##lgls',imgui.ImVec2(pw3,0)) then _G.mkt_log_page=log_pages end
            elseif _G.log_tab_mode == 2 then
                if not _G.fh_chat_subtab then _G.fh_chat_subtab = 0 end  -- 0=чат, 1=история
                if not _G.fh_chat_filter then _G.fh_chat_filter = 0 end
                if not _G.fh_chat_srch   then _G.fh_chat_srch = imgui.new.char[128](''); _G.fh_chat_srch_s = '' end

                local function chsubbtn(lbl, mode)
                    local act = _G.fh_chat_subtab == mode
                    if act then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar3*.5, ag3*.5, ab3*.5, .9)) end
                    if imgui.Button(_cyr5f(lbl)..'##chsub'..mode, imgui.ImVec2(0,0)) then _G.fh_chat_subtab = mode end
                    if act then imgui.PopStyleColor() end
                end
                chsubbtn('\xd7\xe0\xf2', 0)
                imgui.SameLine(0, 3*d)
                chsubbtn('\xc8\xf1\xf2\xee\xf0\xe8\xff', 1)
                imgui.Separator()

                if _G.fh_chat_subtab == 0 then
                local function chfbtn(lbl, mode)
                    local act = _G.fh_chat_filter == mode
                    if act then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(ar3*.5, ag3*.5, ab3*.5, .9)) end
                    if imgui.Button(_cyr5f(lbl)..'##chf'..mode, imgui.ImVec2(0,0)) then
                        _G.fh_chat_filter = mode; _G.fh_chat_page = 1
                    end
                    if act then imgui.PopStyleColor() end
                end
                chfbtn('\xc2\xf1\xe5', 0)
                imgui.SameLine(0, 3*d)
                chfbtn('VIP ADV', 1)
                imgui.SameLine(0, 3*d)
                chfbtn('\xd2\xee\xf0\xe3\xee\xe2\xeb\xff', 2)
                imgui.SameLine(0, 3*d)
                chfbtn('\xcf\xee\xe4\xf1\xea\xe0\xe7\xea\xe0', 3)
                imgui.SameLine(0, 10*d)
                if imgui.Button(_ic_trash..'##chclr', imgui.ImVec2(0,0)) then fh_session_chat = {}; _G.fh_chat_page=1; _lvn7s() end
                imgui.SameLine(0, 4*d)
                imgui.TextDisabled(_cyr5f(#fh_session_chat..' \xf1\xee\xee\xe1\xf9.'))
                imgui.PushItemWidth(-1)
                if imgui.InputText(u8'##chat_srch', _G.fh_chat_srch, 128) then
                    _G.fh_chat_srch_s = u8:decode(ffi.string(_G.fh_chat_srch)):lower()
                    _G.fh_chat_page = 1  -- сброс страницы при поиске
                end
                imgui.PopItemWidth()
                imgui.Separator()

                local function _msc6g(raw)
                    local segments = {}
                    local cur_r, cur_g, cur_b = 0.85, 0.85, 0.85
                    local pos = 1
                    while pos <= #raw do
                        local ts8,te8,rh8,gh8,bh8 = raw:find('{(%x%x)(%x%x)(%x%x)%x%x}', pos)
                        local ts6,te6,rh6,gh6,bh6 = raw:find('{(%x%x)(%x%x)(%x%x)}', pos)
                        local ts,te,rh,gh,bh
                        if ts8 and ts6 then
                            if ts8 <= ts6 then ts,te,rh,gh,bh = ts8,te8,rh8,gh8,bh8
                            else ts,te,rh,gh,bh = ts6,te6,rh6,gh6,bh6 end
                        elseif ts8 then ts,te,rh,gh,bh = ts8,te8,rh8,gh8,bh8
                        elseif ts6 then ts,te,rh,gh,bh = ts6,te6,rh6,gh6,bh6
                        end
                        if ts then
                            if ts > pos then
                                table.insert(segments, {r=cur_r,g=cur_g,b=cur_b, t=raw:sub(pos,ts-1)})
                            end
                            cur_r = tonumber(rh,16)/255
                            cur_g = tonumber(gh,16)/255
                            cur_b = tonumber(bh,16)/255
                            pos = te + 1
                        else
                            table.insert(segments, {r=cur_r,g=cur_g,b=cur_b, t=raw:sub(pos)})
                            break
                        end
                    end
                    if #segments == 0 then return end
                    for si, seg in ipairs(segments) do
                        if seg.t ~= '' then
                            imgui.TextColored(imgui.ImVec4(seg.r,seg.g,seg.b,1), _cyr5f(seg.t))
                            if si < #segments then imgui.SameLine(0,0) end
                        end
                    end
                end

                local trade_words = {
                    '\xcf\xf0\xee\xe4\xe0\xec', '\xcf\xf0\xee\xe4\xe0\xfd\xf8\xfc', '\xca\xf3\xef\xeb\xfe', '\xca\xf3\xef\xeb\xfe',
                    '\xd1\xe4\xe0\xec', '\xd1\xe4\xe0\xb8\xf8\xfc', '\xce\xe1\xec\xe5\xed', '\xee\xe1\xec\xe5\xed\xff\xfe',
                    '\xd1\xe5\xeb\xeb', 'sell', 'buy', '/sell', '/buy', '/findilavka', '/findibiz',
                    '\xef\xf0\xee\xe4\xe0\xfc', '\xef\xf0\xee\xe4\xe0\xeb', '\xea\xf3\xef\xeb\xfe', '\xea\xf3\xef\xe8\xec',
                    '\xf2\xee\xf0\xe3', 'trade', '\xf1\xe4\xe5\xeb\xea\xe0', '\xc2\xfb\xe3\xee\xe4\xed\xee'
                }

                if not _G.fh_chat_page then _G.fh_chat_page = 1 end
                local CHAT_PAGE = 80  -- строк на страницу

                local chat_h = imgui.GetWindowHeight() - 220*d
                if imgui.BeginChild('##fh_chat_list', imgui.ImVec2(-1, chat_h), true) then
                    _dpn1w()  -- swipe scroll
                    local filtered = {}
                    for _, _cmsg in ipairs(fh_session_chat) do
                        local _plain = _cmsg:gsub('{%x%x%x%x%x%x%x?%x?}', ''):lower()
                        local srch_ok = _G.fh_chat_srch_s == '' or _plain:find(_G.fh_chat_srch_s, 1, true)
                        local filt_ok = false
                        if _G.fh_chat_filter == 0 then
                            filt_ok = true
                        elseif _G.fh_chat_filter == 1 then
                            filt_ok = _plain:find('vip adv', 1, true) ~= nil
                        elseif _G.fh_chat_filter == 2 then
                            for _, w in ipairs(trade_words) do
                                if _plain:find(w:lower(), 1, true) then filt_ok = true; break end
                            end
                        elseif _G.fh_chat_filter == 3 then
                            filt_ok = _plain:find(('\xcf\xee\xe4\xf1\xea\xe0\xe7\xea\xe0'):lower(), 1, true) ~= nil
                        end
                        if filt_ok and srch_ok then
                            table.insert(filtered, _cmsg)
                        end
                    end
                    local chat_pages = math.max(1, math.ceil(#filtered / CHAT_PAGE))
                    if _G.fh_chat_page > chat_pages then _G.fh_chat_page = chat_pages end
                    local cf_from = (_G.fh_chat_page - 1) * CHAT_PAGE + 1
                    local cf_to   = math.min(_G.fh_chat_page * CHAT_PAGE, #filtered)
                    local shown = 0
                    for ri = cf_from, cf_to do
                        local _cmsg = filtered[ri]
                        if _cmsg then
                            _msc6g(_cmsg)
                            shown = shown + 1
                        end
                    end
                    if shown == 0 then
                        imgui.TextDisabled(_cyr5f('  \xd1\xee\xee\xe1\xf9\xe5\xed\xe8\xe9 \xed\xe5\xf2.'))
                    end
                    imgui.EndChild()
                end
                local _chat_pages_now = math.max(1, math.ceil(#fh_session_chat / CHAT_PAGE))
                local pw4 = 36*d
                if imgui.Button(_ic_ll..'##chpp', imgui.ImVec2(pw4,0)) then _G.fh_chat_page=1 end
                imgui.SameLine(0,3*d)
                if imgui.Button(_ic_al..'##chpr', imgui.ImVec2(pw4,0)) then if _G.fh_chat_page>1 then _G.fh_chat_page=_G.fh_chat_page-1 end end
                imgui.SameLine(0,5*d)
                imgui.TextColored(imgui.ImVec4(ar3,ag3,ab3,1), _cyr5f('\xd1\xf2\xf0. '.._G.fh_chat_page..'/'.._chat_pages_now))
                imgui.SameLine(0,5*d)
                if imgui.Button(_ic_ar..'##chnx', imgui.ImVec2(pw4,0)) then if _G.fh_chat_page<_chat_pages_now then _G.fh_chat_page=_G.fh_chat_page+1 end end
                imgui.SameLine(0,3*d)
                if imgui.Button(_ic_rr..'##chls', imgui.ImVec2(pw4,0)) then _G.fh_chat_page=_chat_pages_now end

                else
                if not _G.fh_hist_init then
                    _G.fh_hist_init = true
                    _wdk4v()
                    _G.fh_hist_srch = imgui.new.char[256]('')
                    _G.fh_hist_srch_s = ''
                end

                local function _ptz9q(raw)
                    local segs = {}
                    local cr,cg,cb = 0.75,0.75,0.75
                    local pos = 1
                    while pos <= #raw do
                        local ts8,te8,rh8,gh8,bh8 = raw:find('{(%x%x)(%x%x)(%x%x)%x%x}', pos)
                        local ts6,te6,rh6,gh6,bh6 = raw:find('{(%x%x)(%x%x)(%x%x)}', pos)
                        local ts,te,rh,gh,bh
                        if ts8 and ts6 then
                            if ts8<=ts6 then ts,te,rh,gh,bh=ts8,te8,rh8,gh8,bh8
                            else ts,te,rh,gh,bh=ts6,te6,rh6,gh6,bh6 end
                        elseif ts8 then ts,te,rh,gh,bh=ts8,te8,rh8,gh8,bh8
                        elseif ts6 then ts,te,rh,gh,bh=ts6,te6,rh6,gh6,bh6
                        end
                        if ts then
                            if ts>pos then table.insert(segs,{r=cr,g=cg,b=cb,t=raw:sub(pos,ts-1)}) end
                            cr=tonumber(rh,16)/255; cg=tonumber(gh,16)/255; cb=tonumber(bh,16)/255
                            pos=te+1
                        else
                            table.insert(segs,{r=cr,g=cg,b=cb,t=raw:sub(pos)}); break
                        end
                    end
                    if #segs==0 then return end
                    for si,seg in ipairs(segs) do
                        if seg.t~='' then
                            imgui.TextColored(imgui.ImVec4(seg.r,seg.g,seg.b,1), _cyr5f(seg.t))
                            if si<#segs then imgui.SameLine(0,0) end
                        end
                    end
                end

                if imgui.Button(_ic_rot..'##hrefr', imgui.ImVec2(0,0)) then
                    _wdk4v()
                    fh_log_view.sel_date = nil
                    fh_log_view.lines = {}
                end
                imgui.SameLine(0, 6*d)
                imgui.TextDisabled(_cyr5f('Доступно: '..#fh_log_view.dates..' дн.'))
                imgui.SameLine(0, 8*d)
                imgui.PushItemWidth(-1)
                if imgui.InputText(u8'##hist_srch', _G.fh_hist_srch, 256) then
                    _G.fh_hist_srch_s = u8:decode(ffi.string(_G.fh_hist_srch)):lower()
                end
                imgui.PopItemWidth()
                imgui.Separator()

                local hist_h = imgui.GetWindowHeight() - imgui.GetCursorPosY() - 10*d
                local date_list_w = 110*d
                if imgui.BeginChild('##hist_dates', imgui.ImVec2(date_list_w, hist_h), true) then
                    _dpn1w()
                    if #fh_log_view.dates == 0 then
                        imgui.TextDisabled(_cyr5f(' Нет логов'))
                    end
                    for _, dt in ipairs(fh_log_view.dates) do
                        local sel = fh_log_view.sel_date and fh_log_view.sel_date.label == dt.label
                        if imgui.Selectable(u8(dt.label)..'##histdt'..dt.label, sel) then
                            fh_log_view.sel_date = dt
                            fh_log_view.lines   = {}
                            fh_log_view.loading = true
                            lua_thread.create(function()
                                _tjr8f()
                                fh_log_view.loading = false
                            end)
                        end
                        if sel then imgui.SetItemDefaultFocus() end
                    end
                    imgui.EndChild()
                end
                imgui.SameLine(0, 4*d)
                if imgui.BeginChild('##fh_hist_list', imgui.ImVec2(-1, hist_h), true) then
                    _dpn1w()
                    if not fh_log_view.sel_date then
                        imgui.TextDisabled(_cyr5f('  Выберите дату слева'))
                    elseif #fh_log_view.lines == 0 then
                        imgui.TextDisabled(_cyr5f('  Сообщений нет.'))
                    else
                        local srch = _G.fh_hist_srch_s or ''
                        local shown_h = 0
                        for _, hline in ipairs(fh_log_view.lines) do
                            if hline ~= '' then
                                local pl = hline:gsub('{%x%x%x%x%x%x%x?%x?}', ''):lower()
                                if srch == '' or pl:find(srch, 1, true) then
                                    _ptz9q(hline)
                                    shown_h = shown_h + 1
                                end
                            end
                        end
                        if shown_h == 0 then
                            imgui.TextDisabled(_cyr5f('  Ничего не найдено.'))
                        end
                    end
                    imgui.EndChild()
                end
                if fh_log_view.sel_date then
                    imgui.TextDisabled(_cyr5f(string.format(
                        '  %s %s  |  %d стр.',
                        _ic_calds, fh_log_view.sel_date.label, #fh_log_view.lines)))
                end
                end -- else (История subtab)
            elseif _G.log_tab_mode == 3 then
                if not settings.telegram then settings.telegram={} end
                local tg=settings.telegram
                if not _G.tg_bot_buf  then _G.tg_bot_buf =imgui.new.char[128](tg.bot_token or '') end
                if not _G.tg_chat_buf then _G.tg_chat_buf=imgui.new.char[64](tg.chat_id   or '') end
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.4,0.7,1,1), u8'  Telegram Bot')
                imgui.Separator(); imgui.Spacing()
                imgui.TextDisabled(u8'  Bot Token:'); imgui.SetNextItemWidth(-1)
                if imgui.InputText('##tgbot',_G.tg_bot_buf,128) then tg.bot_token=ffi.string(_G.tg_bot_buf);_wfn7p() end
                imgui.TextDisabled(u8'  Chat ID:'); imgui.SetNextItemWidth(-1)
                if imgui.InputText('##tgchat',_G.tg_chat_buf,64) then tg.chat_id=ffi.string(_G.tg_chat_buf);_wfn7p() end
                imgui.Spacing()
                imgui.TextDisabled(u8'  @BotFather->/newbot->token | Chat ID: @userinfobot')
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                local en=tg.enabled or false; local enb=imgui.new.bool(en)
                if imgui.Checkbox(u8'Включить##tgen',enb) then tg.enabled=enb[0];_wfn7p() end
                imgui.Spacing()
                local function tgck(lbl,key) local v=tg[key] or false; local vb=imgui.new.bool(v)
                    if imgui.Checkbox(u8('  '..lbl)..'##tgc_'..key,vb) then tg[key]=vb[0];_wfn7p() end end
                tgck('Мои продажи / покупки','notify_trades')
                tgck('Арбитраж (Premium)','notify_arb')
                tgck('Товар из вотчлиста в лавке','notify_watch')
                imgui.Spacing()
                imgui.TextDisabled(u8'Порог арб. $:'); imgui.SameLine(0,4*d)
                if not _G.tg_thr_buf then _G.tg_thr_buf=imgui.new.float(tg.arb_threshold or 0) end
                imgui.SetNextItemWidth(120*d)
                if imgui.InputFloat('##tgthr',_G.tg_thr_buf,0,0,'%.0f') then tg.arb_threshold=_G.tg_thr_buf[0];_wfn7p() end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Button,imgui.ImVec4(0.1,0.4,0.8,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered,imgui.ImVec4(0.15,0.55,1,1))
                if imgui.Button(u8'  Тест TG  ##tgtest',imgui.ImVec2(-1,0)) then
                    mh_tg_send('[MH] Тест Telegram!',false)
                end
                imgui.PopStyleColor(2)
            end
        end

-- =================== TG MODULE ===================
function mh_tg_send(tcp,silent)
    local c=settings.telegram; if not c or not c.enabled or (c.bot_token or '')=='' or (c.chat_id or '')=='' then return end
    local ok_enc,u8s=pcall(function() return require('encoding').UTF8:encode(tcp) end); if not ok_enc then u8s=tcp end
    u8s=u8s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')
    local tok=c.bot_token; local cid=c.chat_id
    lua_thread.create(function()
        local b='{"chat_id":"'..cid..'","text":"'..u8s..'","parse_mode":"HTML"}'
        local r_ok,r=pcall(require,'requests')
        if not r_ok then
            if not silent then sampAddChatMessage('[MH TG] {ff4444}requests not found',0xFFFFFF) end; return
        end
        local ok2,res=pcall(r.request,'POST','https://api.telegram.org/bot'..tok..'/sendMessage',{body=b,headers={['Content-Type']='application/json'}})
        if not silent then
            if ok2 and res and res.status_code==200 then sampAddChatMessage('[MH TG] {00cc00}Отправлено',0xFFFFFF)
            else sampAddChatMessage('[MH TG] {ff4444}Ошибка TG',0xFFFFFF) end
        end
    end)
end
function mh_tg_on_arb(nm,margin,shop,mkt)
    if not settings.telegram or not settings.telegram.notify_arb then return end
    if (margin or 0)<(settings.telegram.arb_threshold or 0) then return end
    mh_tg_send('[MH] Арб: '..(nm or '?')..'\nПриб: $'..(margin or 0)..'\nЛавка: '..(shop or '?')..'  Рын: $'..(mkt or 0),true)
end
local function mh_tg_on_trade(le)
    if not settings.telegram or not settings.telegram.notify_trades then return end
    local op=le.op=='SELL' and 'Рродажа' or 'Покупка'
    mh_tg_send('[MH] '..op..': '..(le.item or '?')..' x'..(le.qty or 1)..' $'..(le.price or 0)..' '..(le.partner or ''),true)
end
-- ===================================================

        if _G.mh_tab == 8 then
            local d = settings.general.custom_dpi
            local cw_cm = imgui.GetWindowContentRegionWidth()
            local ar_cm = settings.interface.accent_r or 1
            local ag_cm = settings.interface.accent_g or 0.65
            local ab_cm = settings.interface.accent_b or 0.0
            local sb_r = settings.interface.sell_btn_r or 0.10
            local sb_g = settings.interface.sell_btn_g or 0.45
            local sb_b = settings.interface.sell_btn_b or 0.10
            local bb_r = settings.interface.buy_btn_r  or 0.00
            local bb_g = settings.interface.buy_btn_g  or 0.28
            local bb_b = settings.interface.buy_btn_b  or 0.50
            local ac_cm = imgui.ImVec4(ar_cm, ag_cm, ab_cm, 1)

            imgui.Spacing()

            if cm_catch_status ~= '' then
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.08, 0.18, 0.08, 1))
                if imgui.BeginChild('##cm_status', imgui.ImVec2(-1, 32*d), false) then
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 5*d)
                    imgui.TextColored(imgui.ImVec4(0.3, 0.95, 0.3, 1),
                        _ic_circc..' '.._cyr5f(cm_catch_status))
                    imgui.EndChild()
                end
                imgui.PopStyleColor()
                imgui.Spacing()
            end

            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.14, 0.14, 0.17, 1))
            if imgui.BeginChild('##cm_block1', imgui.ImVec2(-1, 68*d), true) then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.75, 1, 1),
                    _ic_lxh..' '..u8'\xd0\xe0\xe4\xe8\xf3\xf1 \xeb\xe0\xe2\xee\xea')
                imgui.SameLine(cw_cm - 90*d)
                if cm_radius_enabled then
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(sb_r, sb_g, sb_b, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.4, sb_g*1.4, sb_b*1.4, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(sb_r*0.85, sb_g*0.85, sb_b*0.85, 1))
                    if imgui.Button(_ic_circc..' '..u8'\xc2\xea\xeb##cm_r', imgui.ImVec2(85*d, 0)) then
                        cm_radius_enabled = false
                    end
                    imgui.PopStyleColor(3)
                else
                    if imgui.Button(_ic_circ..' '..u8'\xc2\xea\xeb##cm_r', imgui.ImVec2(85*d, 0)) then
                        cm_radius_enabled = true
                    end
                end
                imgui.TextDisabled(u8'  \xce\xf2\xee\xe1\xf0\xe0\xe6\xe0\xe5\xf2 \xea\xf0\xf3\xe3 \xf0\xe0\xe4\xe8\xf3\xf1\xe0 5\xec \xe2\xee\xea\xf0\xf3\xe3 \xea\xe0\xe6\xe4\xee\xe9 \xeb\xe0\xe2\xea\xe8 \xd6\xd0')
                imgui.EndChild()
            end
            imgui.PopStyleColor()
            imgui.Spacing()

            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.14, 0.14, 0.17, 1))
            if imgui.BeginChild('##cm_block2', imgui.ImVec2(-1, 68*d), true) then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(1, 0.65, 0.1, 1),
                    _ic_mgnt..' '..u8'\xc0\xe2\xf2\xee-\xeb\xee\xe2\xeb\xff')
                imgui.SameLine(cw_cm - 90*d)
                if cm_catch_enabled then
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.5, 0.25, 0.0, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.35, 0.0, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.4, 0.2, 0.0, 1))
                    if imgui.Button(_ic_circc..' '..u8'\xc2\xea\xeb##cm_c', imgui.ImVec2(85*d, 0)) then
                        cm_catch_enabled = false
                        cm_catch_status = ''
                        sampAddChatMessage('[MH] {ff8800}\xc0\xe2\xf2\xee-\xeb\xee\xe2\xeb\xff \xe2\xfb\xea\xeb\xfe\xf7\xe5\xed\xe0', 0xFFFFFF)
                    end
                    imgui.PopStyleColor(3)
                else
                    if imgui.Button(_ic_circ..' '..u8'\xc2\xea\xeb##cm_c', imgui.ImVec2(85*d, 0)) then
                        cm_catch_enabled = true
                        sampAddChatMessage('[MH] {00cc00}\xc0\xe2\xf2\xee-\xeb\xee\xe2\xeb\xff \xe2\xea\xeb\xfe\xf7\xe5\xed\xe0', 0xFFFFFF)
                    end
                end
                imgui.TextDisabled(u8'  \xc0\xe2\xf2\xee\xec\xe0\xf2\xe8\xf7\xe5\xf1\xea\xe8 \xe7\xe0\xed\xe8\xec\xe0\xe5\xf2 \xeb\xe0\xe2\xea\xf3 \xef\xf0\xe8 \xef\xee\xff\xe2\xeb\xe5\xed\xe8\xe8 \xe4\xe8\xe0\xeb\xee\xe3\xe0 3010')
                imgui.EndChild()
            end
            imgui.PopStyleColor()
            imgui.Spacing()

            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.14, 0.14, 0.17, 1))
            if imgui.BeginChild('##cm_block3', imgui.ImVec2(-1, 68*d), true) then
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.3, 0.85, 1, 1),
                    _ic_map..' '..u8'\xd0\xe5\xed\xe4\xe5\xf0 \xeb\xe0\xe2\xee\xea')
                imgui.SameLine(cw_cm - 90*d)
                if cm_render_enabled then
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(bb_r, bb_g, bb_b, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(bb_r*1.35, bb_g*1.35, bb_b*1.3, 1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(bb_r*0.85, bb_g*0.85, bb_b*0.85, 1))
                    if imgui.Button(_ic_circc..' '..u8'\xc2\xea\xeb##cm_rn', imgui.ImVec2(85*d, 0)) then
                        cm_render_enabled = false
                    end
                    imgui.PopStyleColor(3)
                else
                    if imgui.Button(_ic_circ..' '..u8'\xc2\xea\xeb##cm_rn', imgui.ImVec2(85*d, 0)) then
                        cm_render_enabled = true
                    end
                end
                imgui.TextDisabled(u8'  \xd0\xe8\xf1\xf3\xe5\xf2 \xeb\xe8\xed\xe8\xe8 \xea \xf1\xe2\xee\xe1\xee\xe4\xed\xfb\xec \xeb\xe0\xe2\xea\xe0\xec \xed\xe0 \xd6\xd0')
                imgui.EndChild()
            end
            imgui.PopStyleColor()
            imgui.Spacing()

              imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.14, 0.14, 0.17, 1))
              if imgui.BeginChild('##cm_block4', imgui.ImVec2(-1, 68*d), true) then
                  imgui.Spacing()
                  imgui.TextColored(imgui.ImVec4(0.85, 0.6, 0.1, 1),
                      _ic_arch..' '..u8'\xc0\xe2\xf2\xee /storage \xf1\xe1\xee\xf0')
                  imgui.SameLine(cw_cm - 90*d)
                  local st_on = settings.general and settings.general.auto_storage_collect
                  if st_on then
                      imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(sb_r, sb_g, sb_b, 1))
                      imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(sb_r*1.4, sb_g*1.4, sb_b*1.4, 1))
                      imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(sb_r*0.85, sb_g*0.85, sb_b*0.85, 1))
                      if imgui.Button(_ic_circc..' '..u8'\xc2\xea\xeb##cm_st', imgui.ImVec2(85*d, 0)) then
                          settings.general.auto_storage_collect = false; _wfn7p()
                      end
                      imgui.PopStyleColor(3)
                  else
                      if imgui.Button(_ic_circ..' '..u8'\xc2\xea\xeb##cm_st', imgui.ImVec2(85*d, 0)) then
                          settings.general.auto_storage_collect = true; _wfn7p()
                      end
                  end
                  imgui.TextDisabled(u8'  \xc0\xe2\xf2\xee-\xf1\xe1\xee\xf0 \xef\xf0\xe5\xe4\xec\xe5\xf2\xee\xe2 \xe8\xe7 /storage \xf5\xf0\xe0\xed\xe8\xeb\xe8\xf9\xe0')
                  imgui.EndChild()
              end
              imgui.PopStyleColor()
              imgui.Spacing()

              imgui.TextDisabled(_cyr5f('  ' .. _ic_circi .. ' \xcf\xee\xe4\xee\xe9\xe4\xe8\xf2\xe5 \xea \xeb\xe0\xe2\xea\xe5 \xef\xf0\xe8 \xe2\xea\xeb\xfe\xf7\xb8\xed\xed\xee\xe9 \xe0\xe2\xf2\xee-\xeb\xee\xe2\xeb\xe5'))

        end

end -- _qbs9k

local function cm_isCentralMarket(x, y)
    return (x > 1090 and x < 1180 and y > -1550 and y < -1429)
end

local function cm_drawCircle3d(x, y, z, radius, color)
    local step = 10
    local sX_old, sY_old
    for angle = 0, 360, step do
        local lX = radius * math.cos(math.rad(angle)) + x
        local lY = radius * math.sin(math.rad(angle)) + y
        local _, sX, sY, sZ = convert3DCoordsToScreenEx(lX, lY, z)
        if sZ and sZ > 1 then
            if sX_old and sY_old then
                renderDrawLine(sX, sY, sX_old, sY_old, 1.5, color)
            end
            sX_old, sY_old = sX, sY
        end
    end
end

local function cm_get_distance_to(posX, posY, posZ)
    local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
    return math.sqrt((posX-pX)^2 + (posY-pY)^2)
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    -- GC: снижаем паузы мусоросборщика в Lua 5.1
    -- pause=105 = GC срабатывает чаще (дефолт 200), stepmul=250 = больше работы за шаг
    collectgarbage('setpause', 105)
    collectgarbage('setstepmul', 250)
    fh_session_log_start = #fh_mkt_log + 1  -- Всё с этого индекса — текущая сессия
    while not isSampAvailable() do wait(0) end
    while not sampIsLocalPlayerSpawned() do wait(0) end

    sampAddChatMessage("[Market Helper] {ffffff}v" .. thisScript().version .. " | {FFAA00}/mrk | {aaaaaa}debug: /mrkdbg", message_color)
    _lkz7q()

    -- Автозагрузка цен с облака при входе в игру (тихий режим)
    lua_thread.create(function()
        wait(6000)  -- ждём стабилизации подключения
        _mh_prices_pull(true)
    end)

    lua_thread.create(function()
        wait(3000)
        local key = settings.premium and settings.premium.key or ''
        if key == '' then return end

        if settings.premium.activated and (settings.premium.nick or '') ~= '' then
            local ok_n, my_id = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
            if ok_n and my_id then
                local ok_n2, my_nick = pcall(sampGetPlayerNickname, my_id)
                if ok_n2 and my_nick then
                    local saved_nick = (settings.premium.nick or ''):lower():gsub('^%s+',''):gsub('%s+$','')
                    local cur_nick   = my_nick:lower():gsub('^%s+',''):gsub('%s+$','')
                    if saved_nick ~= '' and cur_nick ~= '' and cur_nick ~= saved_nick then
                        settings.premium.activated = false
                        settings.premium.key       = ''
                        settings.premium.user      = ''
                        settings.premium.nick      = ''
                        settings.premium.expires   = ''
                        _wfn7p()
                        sampAddChatMessage('[MH] {ff4444}Premium: ключ недействителен (не ваш ник).', 0xFFFFFF)
                        return  -- выходим из thread, дальнейшее не проверяем
                    end
                end
            end
        end

        local last = settings.premium.last_check or 0
        if (os.time() - last) < 86400 then
            local exp = settings.premium.expires or ''
            if exp ~= '' then
                pcall(function()
                    local y,m,d = exp:match('(%d+)[%-%.](%d+)[%-%.](%d+)')
                    if y then
                        local exp_ts = os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=23,min=59,sec=59})
                        local days_left = math.ceil((exp_ts - os.time()) / 86400)
                        if days_left <= 3 and days_left >= 0 then
                            local msg = days_left == 0
                                and '[MH] {ff4444}Premium истекает сегодня!'
                                or '[MH] {ffaa00}Premium истекает через ' .. days_left .. ' дн. (' .. exp .. ')'
                            sampAddChatMessage(msg, 0xFFFFFF)
                        end
                    end
                end)
            end
            return
        end
        _fpc2t(key, function(valid, user)
            if valid then
                if mh_debug_enabled then
                    sampAddChatMessage('[MH] {aaaaff}Premium OK: ' .. (user or ''), 0xFFFFFF)
                end
                local exp = settings.premium.expires or ''
                if exp ~= '' then
                    pcall(function()
                        local y,m,d = exp:match('(%d+)[%-%.](%d+)[%-%.](%d+)')
                        if y then
                            local exp_ts = os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=23,min=59,sec=59})
                            local days_left = math.ceil((exp_ts - os.time()) / 86400)
                            if days_left <= 3 and days_left >= 0 then
                                local msg = days_left == 0
                                    and '[MH] {ff4444}Premium истекает сегодня!'
                                    or '[MH] {ffaa00}Premium истекает через ' .. days_left .. ' дн. (' .. exp .. ')'
                                sampAddChatMessage(msg, 0xFFFFFF)
                            end
                        end
                    end)
                end
            else
                settings.premium.activated = false
                _wfn7p()
                sampAddChatMessage('[MH] {ff4444}Premium деактивирован: ключ недействителен.', 0xFFFFFF)
            end
        end)
    end)

    sampRegisterChatCommand("mrk", function()
        MainWindow[0] = not MainWindow[0]
    end)

    sampRegisterChatCommand("mrkdbg", function()
        mh_debug_enabled = not mh_debug_enabled
        if mh_debug_enabled then
            sampAddChatMessage("[Market Helper] {00cc00}Debug ON", message_color)
        else
            sampAddChatMessage("[Market Helper] {ff4444}Debug OFF", message_color)
        end
    end)
    sampRegisterChatCommand("mrkflog", function()
        mh_filelog_enabled = not mh_filelog_enabled
        local path = getWorkingDirectory():gsub('\\\\','/') .. '/MH_debug.log'
        if mh_filelog_enabled then
            -- clear log on enable
            local f = io.open(path, 'w'); if f then f:write('[' .. os.date('%H:%M:%S') .. '] === MH FILE LOG START ===\n'); f:close() end
            sampAddChatMessage("[Market Helper] {00cc00}File log ON -> MH_debug.log", message_color)
        else
            sampAddChatMessage("[Market Helper] {ff4444}File log OFF", message_color)
        end
    end)

      sampRegisterChatCommand("mrkpush", function()
          local count = 0
          for _, s in pairs(fh_other_shops) do
              if s and s.owner and s.owner ~= '' then count = count + 1 end
          end
          if count == 0 then
              sampAddChatMessage('[MH Cloud] {ff6644}Нет лавок для отправки.', 0xFFFFFF)
              return
          end
          sampAddChatMessage('[MH Cloud] {aaaaff}Отправляю ' .. count .. ' лавок на сервер...', 0xFFFFFF)
          lua_thread.create(function()
              local sent = 0
              local srv_id = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or 1] or {}).id or -1
              for _, s in pairs(fh_other_shops) do
                  if s and s.owner and s.owner ~= '' then
                      if not s.server_id then s.server_id = srv_id end
                      local payload = {
                          server_id  = s.server_id or -1,
                          owner      = s.owner,
                          shop_num   = s.shop_num,
                          sell_slots = s.sell_items or {},
                          buy_slots  = s.buy_items  or {},
                      }
                      local ok_j, j = pcall(encodeJson, payload)
                      if ok_j then
                          local ok, code = _mh_sync_post(_vbr7n .. '/shops/push', j)
                          if ok then sent = sent + 1 end
                      end
                      wait(150)
                  end
              end
              wait(500)
              sampAddChatMessage('[MH Cloud] {00cc00}Готово! Отправлено: ' .. sent .. ' из ' .. count .. '. Нажми "Обновить" во вкладке Лавки.', 0xFFFFFF)
          end)
      end)
    while true do wait(0)
        if cm_radius_enabled then
            for IDTEXT = 0, 2048 do
                if sampIs3dTextDefined(IDTEXT) then
                    local text3d, _, posX, posY, posZ = sampGet3dTextInfoById(IDTEXT)
                    if text3d == "\xd3\xef\xf0\xe0\xe2\xeb\xe5\xed\xe8\xff \xf2\xee\xe2\xe0\xf0\xe0\xec\xe8." and not cm_isCentralMarket(posX, posY) then
                        local pX, pY = getCharCoordinates(PLAYER_PED)
                        local dist = math.sqrt((posX-pX)^2 + (posY-pY)^2)
                        local col = dist > 5 and 0xFFFFFFFF or 0xFFFF2222
                        cm_drawCircle3d(posX, posY, posZ - 1.3, 5, col)
                    end
                end
            end
        end
        if cm_render_enabled then
            for id = 0, 2304 do
                if sampIs3dTextDefined(id) then
                    local text3d, _, posX, posY, posZ = sampGet3dTextInfoById(id)
                    if math.floor(posZ) == 17 and text3d == '' then
                        if isPointOnScreen(posX, posY, posZ, 100000) then
                            local pX2, pY2 = convert3DCoordsToScreen(getCharCoordinates(PLAYER_PED))
                            local lX2, lY2 = convert3DCoordsToScreen(posX, posY, posZ)
                            renderDrawLine(pX2, pY2, lX2, lY2, 1, 0xFF52FF4D)
                            renderDrawPolygon(lX2, lY2, 10, 10, 10, 0, 0xFFFFFFFF)
                        end
                    end
                end
            end
        end

        if not mh_isActiveCommand then
            for idx, t in ipairs(settings.piar_templates or {}) do
                local _piar_iv = t.auto_interval or 300
                if (t.auto_interval_max or 0) > _piar_iv then
                    if not t._next_interval then t._next_interval = _piar_iv + math.random(0, t.auto_interval_max - _piar_iv) end
                    _piar_iv = t._next_interval
                end
                if t.enable and t.auto and os.time() - (t.last_time or 0) >= _piar_iv then
                    t._next_interval = nil
                    _xjg7y(idx); break
                end
            end
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    fh_last_dlg_title_raw = title or ""
    fh_last_dlg_title     = title and title:gsub("{%x+}",""):match("^%s*(.-)%s*$") or ""
    fh_last_dlg_text      = text or ""
    fh_last_dlg_id        = dialogId or -1
    -- File log: all dialogs
    local _t = (title or ''):gsub('{%x+}',''):sub(1,60)
    local _tx = (text  or ''):gsub('{%x+}',''):sub(1,120):gsub('\n',' | ')
    _mh_flog('DLG id=' .. tostring(dialogId) .. ' style=' .. tostring(style) .. ' title=[' .. _t .. '] text=[' .. _tx .. ']')
    if dialogId == 3040 and title and title ~= '' then
        local t_clean = title:gsub('{%x+}', ''):match('^%s*(.-)%s*$') or ''
        local n = t_clean:match('[\xe2\x84\x96#]%s*(%d+)')
                or t_clean:match('(%d+)%s*$')
        if n then
            local num = tonumber(n)
            if num and num >= 1 and num <= 99999 then
                fh_other_shop_pending_num = num
                mh_own_shop_num = num  -- надёжный номер ????? ?????
                if fh_other_shop_cur then
                    fh_other_shop_cur.shop_num = num
                end
                for k, s in pairs(fh_other_shops) do
                    if s.owner and fh_other_shop_owner ~= '' and s.owner:lower() == fh_other_shop_owner:lower() then
                        local old_num = tostring(s.shop_num or '')
                        if old_num ~= tostring(num) then
                            s.shop_num = num
                            local new_key = s.owner .. '_' .. num
                            fh_other_shops[new_key] = s
                            fh_other_shops[k] = nil
                            settings.other_shops = fh_other_shops
                            _wfn7p()
                        end
                        break
                    end
                end
                if mh_debug_enabled then
                    sampAddChatMessage('[MH DLG3040] shopNum='..num..' title='..t_clean:sub(1,30), 0xAAFFAA)
                end
            end
        end
    end
    if fh_other_shop_scanning then
        fh_other_dlg_signal = {id=dialogId, title=fh_last_dlg_title, title_raw=fh_last_dlg_title_raw, text=text or ""}
        local _tc = fh_last_dlg_title or ''
        local _is_slot = _tc:find('Продажа%s+товара')   ~= nil
                      or _tc:find('Продажа%s+предмета')  ~= nil
                      or _tc:find('Покупка')              ~= nil
                      or _tc:find('[Тт]овар')             ~= nil
                      or dialogId == 3082
        if _is_slot then return false end
        fh_player_dlg_open = true
    end

    -- FIX: Increment lv_done when shop slot dialog arrives during scan
    if fh_mkt_lv_scanning and dialogId == fh_mkt_lv_cur_dialog then
        fh_mkt_lv_done = fh_mkt_lv_done + 1
        lua_thread.create(function() wait(80); sampSendDialogResponse(dialogId, 0, 0, '') end)
        return false
    end

    if dialogId == 3010 and cm_catch_enabled then
        lua_thread.create(function()
            wait(100)
            sampSendDialogResponse(dialogId, 1, 0, "")
            cm_catch_status = os.date("%H:%M") .. " \xeb\xe0\xe2\xea\xe0 \xef\xee\xe9\xec\xe0\xed\xe0!"
            sampAddChatMessage('[MH] {00cc00}\xc2\xfb \xef\xee\xe9\xec\xe0\xeb\xe8 \xeb\xe0\xe2\xea\xf3!', 0xFFFFFF)
        end)
        return false
    end

    if mh_debug_enabled and (dialogId == 26545 or dialogId == 25493) then
        local t = title and title:gsub("{%x+}",""):sub(1,30) or ""
        sampAddChatMessage("[FH DEBUG] Dialog ID: " .. dialogId .. " style: " .. style, 0xFF8888)
        sampAddChatMessage("[FH DEBUG] Title: " .. t, 0xFF8888)
        if text and text ~= "" then
            local first = text:gsub("{%x+}",""):match("^%s*(.-)%s*$") or ""
            sampAddChatMessage("[FH DEBUG] [1] " .. first:sub(1,60), 0xFF8888)
            local cnt = 0; for _ in text:gmatch('[^\n]+') do cnt=cnt+1 end
            sampAddChatMessage("[FH DEBUG] ... Всего строк: " .. cnt, 0xFF8888)
        end
    end

    if fh_lv_autosell_running and dialogId == 25493 and text then
        local found_name, found_idx = nil, nil
        local li = 0
        for ln in text:gmatch("[^\n]+") do
            local nm = ln:gsub("{%x+}", ""):match("%[%d+%]%s+(.-)%s+%[")
            if nm then
                nm = nm:match("^%s*(.-)%s*$") or ""
                for _, p in ipairs(fh_lv_autosell_preset) do
                    if p.name:lower() == nm:lower() and p.enabled ~= false and (p.price or 0) >= 10 then
                        found_name = p.name; found_idx = li; break
                    end
                end
            end
            if found_name then break end
            li = li + 1
        end
        if found_name then
            sampAddChatMessage("[MH] 25493 -> выбираю: " .. found_name, 0xFFFFFF)
            lua_thread.create(function() wait(300); sampSendDialogResponse(dialogId, 1, found_idx, "") end)
        else
            lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 0, 0, "") end)
        end
        return false
    end

    if dialogId == 26545 and text then
        local has_qty = text:find("запятую") ~= nil
        fh_mkt_shop_price_qty = has_qty
        _G._mh_dlg26545_text = text  -- cache for autosell
        _G._mh_dlg26545_time = os.clock()
        if fh_mkt_shop_price_dlg == -2 then
            fh_mkt_shop_price_dlg = dialogId
        end
    end
    if fh_lv_inv_scanning then
        if mh_debug_enabled then sampAddChatMessage('[FH Дебаг] {aaaaaa}dlg='..tostring(dialogId)..' step='..tostring(fh_lv_inv_dialog_step)..' title='..tostring(title):sub(1,30), 0xFFFFFF) end
        if dialogId == 722 or dialogId == 600 or dialogId == 235 then
            fh_lv_inv_dialog_step = fh_lv_inv_dialog_step + 1
            lua_thread.create(function() wait(150); sampSendDialogResponse(dialogId, 1, 0, '') end)
            return false
        end
        -- Инвентарный диалог: 25494, 25493, или любой с признаками инвентаря
        local _is_inv_dlg = dialogId == 25494 or dialogId == 25493
            or (text and (
                text:find('%[%d+%]') and text:find('%[%d+ шт%]')   -- страница с вещами
                or text:find('\xc8\xed\xe2\xe5\xed\xf2\xe0\xf0\xfc:')     -- "Инвентарь:"
                or text:find('\xd1\xeb\xe5\xe4\xf3\xfe\xf9\xe0\xff \xf1\xf2\xf0\xe0\xed\xe8\xf6\xe0')  -- "Следующая страница"
                or text:find('\xcf\xf0\xe5\xe4\xfb\xe4\xf3\xf9\xe0\xff \xf1\xf2\xf0\xe0\xed\xe8\xf6\xe0') -- "Предыдущая страница"
            ))
        if _is_inv_dlg then
            fh_parse_inventory_dialog(text or '')
            local next_idx = nil
            if text then
                local iline = 0
                for ln in text:gmatch('[^\n]+') do
                    iline = iline + 1
                    if iline > 1 and ln:find('\xd1\xeb\xe5\xe4\xf3\xfe\xf9\xe0\xff \xf1\xf2\xf0\xe0\xed\xe8\xf6\xe0', 1, true) then
                        next_idx = iline - 2  -- 0-based
                        break
                    end
                end
            end
            if next_idx then
                sampAddChatMessage('[FH Авто] {aaaaaa}Стр. ' .. #fh_lv_inventory .. ' позиций, листаю...', 0xFFFFFF)
                lua_thread.create(function() wait(150); sampSendDialogResponse(dialogId, 1, next_idx, '') end)
            else
                -- Последняя страница — закрываем диалог и завершаем скан
                fh_lv_inv_scanning = false
                fh_lv_inv_dialog_step = 0
                sampAddChatMessage('[FH Авто] {00cc00}Инвентарь: ' .. #fh_lv_inventory .. ' позиций', 0xFFFFFF)
                lua_thread.create(function() wait(80); sampSendDialogResponse(dialogId, 0, 0, '') end)
            end
            return false
        end
    end
    if fh_mkt_cp_scanning and title and text then
        local ct2 = title:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
        local is_our = (dialogId == 15073) or ct2:find('\xf0\xe5\xe4\xed\xff\xff') ~= nil
        if not is_our then
            fh_mkt_cp_prev_text = nil
            lua_thread.create(function()
                wait(150)
                sampSendDialogResponse(dialogId, 0, 0, '')
                wait(300)
            end)
            return false
        end
    end

    if text ~= nil and settings.general.auto_vr_confirm then
        if string.find(text, "Ваше сообщение является рекламой?") then
            sampSendDialogResponse(dialogId, 1, "", "")
            return false
        end
    end

    if title and settings.general.auto_ad_confirm then
        local ct_ad = title:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
        if ct_ad:find('Подача') and not ct_ad:find('Подтв') then
            lua_thread.create(function() wait(400)
                sampSendDialogResponse(dialogId, 1, 0, text and text:match('^%s*(.-)%s*$') or '') end)
            return false
        end
        if ct_ad:find('радио') or ct_ad:find('Радио') then
            lua_thread.create(function() wait(400)
                sampSendDialogResponse(dialogId, 1, settings.general.auto_ad_station_idx or 2, '') end)
            return false
        end
        if ct_ad:find('тип') or ct_ad:find('Тип') then
            lua_thread.create(function() wait(400)
                sampSendDialogResponse(dialogId, 1, settings.general.auto_ad_type or 0, '') end)
            return false
        end
        if ct_ad:find('Подтв') then
            lua_thread.create(function() wait(400)
                sampSendDialogResponse(dialogId, 1, -1, '') end)
            return false
        end
    end

    if settings.general.auto_storage_collect then
        local ct_st = title and title:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
        if text and text:find('Основное хранилище') then
            local pick_st, idx_st = nil, 0
            for line_st in text:gmatch('[^\n]+') do
                local cl_st = line_st:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
                if cl_st:find('Основное хранилище') then pick_st = idx_st; break end
                idx_st = idx_st + 1
            end
            fh_storage_running = true
            lua_thread.create(function() wait(300)
                sampSendDialogResponse(dialogId, 1, pick_st or 0, '') end)
            return false
        end
        if ct_st == 'Хранилище предметов' then
            local total_st = 0
            if text then for _ in text:gmatch('[^\n]+') do total_st = total_st + 1 end end
            if total_st > 0 then
                fh_storage_running = true
                sampSendDialogResponse(dialogId, 1, 0, '')
                return false
            else
                fh_storage_running = false
                sampAddChatMessage('[MH] {aaaaaa}Хранилище пусто!', 0xFFFFFF)
                sampSendDialogResponse(dialogId, 0, 0, '')
                return false
            end
        end
        if ct_st == 'Хранилище' and (style == 4 or style == 5) then
            local pick_all_st, pick_one_st = nil, nil
            local idx_st2 = 0
            if text then
                for line_st in text:gmatch('[^\n]+') do
                    local cl_st = line_st:gsub('{%x+}',''):gsub('%[%d+%]%s*',''):match('^%s*(.-)%s*$') or ''
                    if cl_st:find('Забрать все') then pick_all_st = idx_st2
                    elseif cl_st:find('Забрать') then
                        if pick_one_st == nil then pick_one_st = idx_st2 end
                    end
                    idx_st2 = idx_st2 + 1
                end
            end
            local pick_st2 = pick_all_st or pick_one_st
            if pick_st2 ~= nil then
                lua_thread.create(function() wait(200)
                    sampSendDialogResponse(dialogId, 1, pick_st2, '') end)
            else
                lua_thread.create(function() wait(200)
                    sampSendDialogResponse(dialogId, 0, 0, '') end)
            end
            return false
        end
        if ct_st:find('Хранилище') and style == 0 and text then
            local cl_st = text:gsub('{%x+}',''):lower()
            if cl_st:find('забрать') or cl_st:find('забира') then
                lua_thread.create(function() wait(200)
                    sampSendDialogResponse(dialogId, 1, 0, '') end)
                return false
            end
        end
    end

        local ct_mkt = title and title:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
        local is_mkt_list = (dialogId == 15073) or (dialogId ~= 15376 and ct_mkt:find('Средняя цена') ~= nil)
        if is_mkt_list and text then
            local scan_label = 'Проанализировать все цены [FH]'
            if fh_mkt_cp_scanning then
                if fh_mkt_cp_prev_text == text then
                    local tot = 0; for _ in pairs(fh_mkt_prices) do tot = tot + 1 end
                    sampAddChatMessage('[FH Market] {00cc00}Анализ завершён! Товаров: ' .. tot, 0xFFFFFF)
                    printStyledString('~w~FH Market: ~g~' .. tot .. ' ~w~items OK', 2500, 6)
                    fh_mkt_cp_prev_text = nil; fh_mkt_cp_scanning = false
                    _ryb5t()
                    lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 0, 0, '') end)
                    return false
                end
                _hbr6z(text)
                local tot2 = 0; for _ in pairs(fh_mkt_prices) do tot2 = tot2 + 1 end
                fh_mkt_cp_page = (fh_mkt_cp_page or 0) + 1
                printStyledString('~w~FH: ~g~' .. tot2 .. ' ~w~items | p.~r~' .. fh_mkt_cp_page, 1800, 6)
                fh_mkt_cp_prev_text = text
                local next_idx = fh_find_listitem(text, 'Следующая страница')
                if next_idx then
                    lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 1, next_idx, 0) end)
                else
                    local tot3 = 0; for _ in pairs(fh_mkt_prices) do tot3 = tot3 + 1 end
                    sampAddChatMessage('[FH Market] {00cc00}Скан завершён. Товаров: ' .. tot3, 0xFFFFFF)
                    fh_mkt_cp_scanning = false; _ryb5t()
                    lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 0, 0, 0) end)
                end
                return false
            else
                local already = false
                for ln2 in text:gmatch('[^\n]+') do
                    if ln2:find(scan_label, 1, true) then already = true; break end
                end
                if not already then
                    local deep_label = 'Углублённый скан [FH]'
                    local new_text = string.gsub(text, '(\xcf\xee\xe8\xf1\xea \xef\xee \xed\xe0\xe7\xe2\xe0\xed\xe8\xfe\t%s)\n', '%1\n{00FF00}' .. scan_label .. '\t \n{FFAA00}' .. deep_label .. '\t \n', 1)
                    if new_text == text then
                        local fl = text:match('^([^\n]*)')
                        new_text = fl .. '\n{00FF00}' .. scan_label .. '\t \n{FFAA00}' .. deep_label .. '\t \n' .. text:sub(#fl + 1)
                    end
                    fh_mkt_cp_go_idx = fh_find_listitem(new_text, scan_label)
                    fh_mkt_cp_deep_go_idx = fh_find_listitem(new_text, deep_label)
                    return { dialogId, style, title, button1, button2, new_text }
                end
            end
        end

    local is_auto_dlg = (dialogId == 15376)
    if not is_auto_dlg and title then
        local ct_a = title:gsub('{%x+}',''):match('^%s*(.-)%s*$') or ''
        is_auto_dlg = ct_a:find('Средняя цена автомобилей') ~= nil
    end
    if is_auto_dlg and text then
        local auto_scan_label = 'Сканировать все авто [MH]'
        if fh_mkt_auto_scanning then
            if fh_mkt_auto_prev_text == text then
                local tot = 0; for _ in pairs(fh_mkt_auto) do tot = tot + 1 end
                sampAddChatMessage('[MH Auto] {00cc00}Скан завершён! Авто: ' .. tot, 0xFFFFFF)
                printStyledString('~w~MH Auto: ~g~' .. tot .. ' ~w~OK', 2500, 6)
                fh_mkt_auto_prev_text = nil; fh_mkt_auto_scanning = false
                _ryb5t()
                lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 0, 0, '') end)
                return false
            end
            _gyc9t(text)
            local atot = 0; for _ in pairs(fh_mkt_auto) do atot = atot + 1 end
            fh_mkt_auto_page = (fh_mkt_auto_page or 0) + 1
            printStyledString('~w~MH Auto: ~g~' .. atot .. ' ~w~| p.~r~' .. fh_mkt_auto_page, 1800, 6)
            fh_mkt_auto_prev_text = text
            local nxt_a = fh_find_listitem(text, 'Следующая страница')
            if nxt_a then
                lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 1, nxt_a, 0) end)
            else
                local atot3 = 0; for _ in pairs(fh_mkt_auto) do atot3 = atot3 + 1 end
                sampAddChatMessage('[MH Auto] {00cc00}Скан завершён. Авто: ' .. atot3, 0xFFFFFF)
                fh_mkt_auto_scanning = false; _ryb5t()
                lua_thread.create(function() wait(100); sampSendDialogResponse(dialogId, 0, 0, 0) end)
            end
            return false
        else
            local auto_deep_label = 'Углублённый скан авто [MH]'
            local already_a = false
            for ln_a in text:gmatch('[^\n]+') do
                if ln_a:find(auto_scan_label, 1, true) then already_a = true; break end
            end
            if not already_a then
                local new_text_a = string.gsub(text,
                    '(\xcf\xee\xe8\xf1\xea \xef\xee \xed\xe0\xe7\xe2\xe0\xed\xe8\xfe\t[^\n]*)\n',
                    '%1\n{00FF00}' .. auto_scan_label .. '\t \n{FFAA00}' .. auto_deep_label .. '\t \n', 1)
                if new_text_a == text then
                    local fl_a = text:match('^([^\n]*)')
                    new_text_a = fl_a .. '\n{00FF00}' .. auto_scan_label .. '\t \n{FFAA00}' .. auto_deep_label .. '\t \n' .. text:sub(#fl_a+1)
                end
                fh_mkt_auto_go_idx      = fh_find_listitem(new_text_a, auto_scan_label)
                fh_mkt_auto_deep_go_idx = fh_find_listitem(new_text_a, auto_deep_label)
                return { dialogId, style, title, button1, button2, new_text_a }
            end
        end
    end

end
function sampev.onShowTextDraw(td_id, td_data)
    if not td_data or not td_data.position then return end
    local px = td_data.position.x or 0
    local py = td_data.position.y or 0
    local py_s = tostring(py)

    if td_data.text then
        local n = tostring(td_data.text):match('#(%d+)')
        if n then
            local num = tonumber(n)
            if num and num >= 1 and num <= 9999 then
                fh_other_shop_pending_num = num
                if mh_debug_enabled then
                    sampAddChatMessage('[MH TD#] id='..td_id..' num='..num..' txt='..tostring(td_data.text):sub(1,30), 0xAAFFAA)
                end
            end
        end
    end

    if td_data.text == 'ON_SALE' then
        fh_mkt_lavka_ids  = {}
        fh_mkt_lavka_slot_w = nil
        fh_mkt_lavka_slot_h = nil
        fh_mkt_lavka_page_id = -1
        fh_mkt_lavka_page_ready = false
    end

    if td_data.text == 'LD_BEAT:chit' and px > 320 and py > 240 then
        if fh_mkt_lavka_page_id < 0 then
            fh_mkt_lavka_page_id = td_id
            if mh_debug_enabled then sampAddChatMessage('[MH] {aaaaaa}TD страниц: ' .. td_id, 0xFFFFFF) end
        end
        fh_mkt_lavka_page_ready = true
        fh_mkt_shop_ui_open = true
    end

    if px == 325 and (py_s:find('164%.') or py_s:find('169%.') or
                      py_s:find('165%.') or py_s:find('168%.')) then
        local exists = false
        for _, v in ipairs(fh_mkt_lavka_ids) do
            if v == td_id then exists = true; break end
        end
        if not exists then
            table.insert(fh_mkt_lavka_ids, td_id)
            if not fh_mkt_lavka_slot_w then
                fh_mkt_lavka_slot_w = td_data.lineWidth
                fh_mkt_lavka_slot_h = td_data.lineHeight
            end
        end
    end

    if fh_mkt_shop_ui_open then
        local is_service = (td_data.text == 'ON_SALE' or
                            td_data.text == 'LD_BEAT:chit' or
                            td_data.text == 'LD_SPAC:white')
        if not is_service then
            local exists2 = false
            for _, v in ipairs(fh_mkt_shop_inv_tds) do
                if v == td_id then exists2 = true; break end
            end
            if not exists2 then
                table.insert(fh_mkt_shop_inv_tds, td_id)
                if #fh_mkt_shop_inv_tds <= 35 then
                    local txt_s = tostring(td_data.text or ''):sub(1,20)
                    if mh_debug_enabled then sampAddChatMessage('[TD#'..#fh_mkt_shop_inv_tds..'] id='..td_id..' x='..math.floor(px)..' y='..math.floor(py)..' txt='..txt_s, 0xFFFFFF) end
                end
            end
        end
    end

    if fh_other_shop_scanning and td_data.text then
        local p = _bky4d(td_data.text)
        if p then
            fh_other_shop_price_tds[td_id] = {price=p, x=px, y=py}
            if mh_debug_enabled then
                sampAddChatMessage('[MH TD$] id=' .. td_id .. ' $' .. p
                    .. ' x=' .. math.floor(px) .. ' y=' .. math.floor(py), 0x88ff88)
            end
        end
    end

    fh_mkt_lavka_all_tds[td_id] = td_data

end

function sampev.onTextDrawHide(td_id)
    for _,v in ipairs(fh_mkt_lavka_ids) do
        if v == td_id then
            fh_mkt_lavka_ids={}
            fh_mkt_lavka_sep={}
            fh_mkt_lavka_page_id=-1
            break
        end
    end
    if td_id == fh_mkt_lavka_page_id then
        fh_mkt_shop_ui_open = false
        fh_mkt_shop_inv_tds = {}
        fh_mkt_lavka_page_id = -1
        if fh_other_shop_scanning and fh_other_shop_cur then
            _qbh9f()
            fh_other_shop_scanning = false
            fh_other_shop_price_tds = {}
        end
    end
    local hid_td_data = fh_mkt_lavka_all_tds[td_id]
    if hid_td_data and hid_td_data.text == 'ON_SALE' then
        fh_mkt_lavka_all_tds[td_id] = nil
        if fh_other_shop_scanning and fh_other_shop_cur then
            _qbh9f()
            fh_other_shop_scanning = false
            fh_other_shop_price_tds = {}
        end
    end
    if td_id == fh_mkt_put_td_id then
        fh_mkt_put_td_id = -1
    end
end

mh_last_3dtext_num   = nil
mh_last_3dtext_time  = 0

function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
    if not text or text == '' then return end
    local n = text:match('#(%d+)')
    if not n then return end
    local num = tonumber(n)
    if not num or num < 1 or num > 9999 then return end
    local pX, pY = getCharCoordinates(PLAYER_PED)
    local dx = (position and position.x or 0) - pX
    local dy = (position and position.y or 0) - pY
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 15.0 then return end
    mh_last_3dtext_num  = num
    mh_last_3dtext_time = os.clock()
    fh_other_shop_pending_num = num
    if mh_debug_enabled then
        sampAddChatMessage('[MH 3DT] #'..num..' dist='..string.format('%.1f', dist)..' id='..id, 0xAAFFAA)
    end
end

function sampev.onSendDialogResponse(dialogId, button, listItem, inputText)
    if fh_other_shop_scanning then _dlg_send_done = true end
    fh_player_dlg_open = false
    if fh_other_shop_scanning and fh_other_shop_cur and button == 0 then
        local title_now = fh_last_dlg_title or ''
        local is_shop_dlg = title_now:find('Торговая лавка') ~= nil
                         or title_now:find('Лавка')         ~= nil
                         or title_now:find('Покупка')        ~= nil
                         or title_now:find('Продажа')        ~= nil
        if is_shop_dlg then
            lua_thread.create(function()
                wait(300)
                if fh_other_shop_scanning and fh_other_shop_cur then
                    _qbh9f()
                    fh_other_shop_scanning = false
                end
            end)
        end
    end

    local is_mkt = (dialogId == 15073)
    if not is_mkt then
        is_mkt = fh_last_dlg_title:find('Средняя цена товаров при продаже') ~= nil
    end
    if is_mkt then
    end

    if is_mkt and fh_mkt_cp_deep_scanning then
        return false
    end

    if is_mkt and not fh_mkt_cp_deep_scanning and fh_mkt_cp_deep_go_idx ~= nil then
        if button == 1 and listItem == fh_mkt_cp_deep_go_idx then
            fh_mkt_cp_deep_go_idx = nil
            fh_mkt_cp_deep_scanning = true
            fh_mkt_cp_deep_done     = 0
            sampAddChatMessage('[FH Market] {ffaa00}Углублённый скан запущен!', 0xFFFFFF)

            local _was_main_open_outer = MainWindow[0]
            MainWindow[0] = false

            local txt0 = sampGetDialogText() or ''
            local dlg0 = dialogId

            lua_thread.create(function()
                local rtt_ms = 1200; local rtt_n = 0
                local function upd_rtt(ms) rtt_n=rtt_n+1; rtt_ms=math.floor((rtt_ms*math.min(rtt_n-1,9)+ms)/math.min(rtt_n,10)) end
                local function srv_to() return math.max(3000, math.min(rtt_ms*5+1500, 20000)) end

                local function wait_for_list(old_txt)
                    local timeout_ms = srv_to(); local t0 = os.clock(); local t = 0
                    while t < timeout_ms do
                        wait(16); t = t + 16
                        if sampIsDialogActive() and sampGetCurrentDialogId() == 15073 then
                            local ntxt = sampGetDialogText() or ''
                            if not old_txt or ntxt ~= old_txt then
                                upd_rtt(math.floor((os.clock()-t0)*1000))
                                return sampGetCurrentDialogId(), ntxt
                            end
                        end
                    end
                    return nil, nil
                end

                local function wait_for_detail()
                    local timeout_ms = srv_to(); local t0 = os.clock(); local t = 0
                    while t < timeout_ms do
                        wait(16); t = t + 16
                        if sampIsDialogActive() then
                            local tt = fh_last_dlg_title or ''
                            if tt:find('Продажа товара') then
                                upd_rtt(math.floor((os.clock()-t0)*1000))
                                return sampGetCurrentDialogId(), sampGetDialogText() or '', tt
                            end
                        end
                    end
                    return nil, nil, nil
                end

                local function wait_back_to_list()
                    local timeout_ms = srv_to(); local t = 0
                    while t < timeout_ms do
                        wait(16); t = t + 16
                        if sampIsDialogActive() and sampGetCurrentDialogId() == 15073 then
                            return sampGetCurrentDialogId(), sampGetDialogText() or ''
                        end
                    end
                    return nil, nil
                end

                local cur_dlg = dlg0
                local cur_txt = txt0
                local _was_main_open = _was_main_open_outer
                local idx_offset = 2  -- onShowDialog всегда вставляет 2 кнопки на каждой странице

                while fh_mkt_cp_deep_scanning do
                    local page_items = _nqh8s(cur_txt, 5)

                    if #page_items == 0 then goto continue_deep end

                    for _, item in ipairs(page_items) do
                        if not fh_mkt_cp_deep_scanning then break end

                        sampSendDialogResponse(cur_dlg, 1, item.idx - idx_offset, 0)
                        local det_dlg, det_txt, det_title = wait_for_detail()
                        if det_dlg then
                            local detail = _jfw5v(det_txt, det_title)
                            if detail and detail.name ~= '' and #detail.history > 0 then
                                fh_mkt_save_cp_detail(detail.name, detail.history)
                            lua_thread.create(function() wait(200); _mh_upload_deals() end)
                            end
                            fh_mkt_cp_deep_done = fh_mkt_cp_deep_done + 1
                            printStyledString('~w~FH deep: ~y~'..fh_mkt_cp_deep_done, 1000, 6)
                            sampSendDialogResponse(det_dlg, 1, 0, '')
                        else
                            fh_mkt_cp_deep_done = fh_mkt_cp_deep_done + 1
                            if sampIsDialogActive() then
                                local cid2 = sampGetCurrentDialogId()
                                if cid2 ~= 15073 then
                                    sampSendDialogResponse(cid2, 1, 0, '')
                                end
                            end
                        end
                        local nld, ntxt = wait_back_to_list()
                        if nld then cur_dlg = nld; cur_txt = ntxt end
                    end

                    if not fh_mkt_cp_deep_scanning then break end

                    ::continue_deep::
                    local cur_txt2 = sampIsDialogActive() and (sampGetDialogText() or '') or cur_txt
                    local next_i = fh_find_listitem(cur_txt2, 'Следующая страница')
                    if not next_i then break end
                    local cid = sampIsDialogActive() and sampGetCurrentDialogId() or cur_dlg
                    local old_page_txt = sampIsDialogActive() and sampGetDialogText() or cur_txt
                    local nld2, ntxt2 = nil, nil
                    for _retry = 1, 3 do
                        sampSendDialogResponse(cid, 1, next_i - idx_offset, 0)
                        local _page_to_save = rtt_ms
                        rtt_ms = math.floor(rtt_ms * 2)
                        nld2, ntxt2 = wait_for_list(old_page_txt)
                        rtt_ms = _page_to_save
                        if nld2 then break end
                        sampAddChatMessage('[FH Market] {ffaa00}Попытка перехода страницы: ' .. _retry .. '/3', 0xFFFFFF)
                        wait(1000)
                    end
                    if nld2 then
                        wait(80)
                        cur_dlg = nld2; cur_txt = ntxt2
                    else break end
                end

                fh_mkt_cp_deep_scanning = false
                _ryb5t()
                if sampIsDialogActive() then
                    sampSendDialogResponse(sampGetCurrentDialogId(), 0, 0, '')
                end
                MainWindow[0] = _was_main_open
                sampAddChatMessage('[FH Market] {00cc00}Скан завершён! Товаров: '..fh_mkt_cp_deep_done, 0xFFFFFF)
                -- [MH Cloud] Авто-пуш цен после скана
                lua_thread.create(function() wait(1000); _mh_prices_push() end)
                printStyledString('~w~FH DONE: ~g~'..fh_mkt_cp_deep_done, 3000, 6)
            end)

            return false
        end
        if button == 1 and listItem > fh_mkt_cp_deep_go_idx then
            fh_mkt_cp_deep_go_idx = nil
            return { dialogId, button, listItem - 2, inputText }
        end
        fh_mkt_cp_deep_go_idx = nil
    end

    if is_mkt and not fh_mkt_cp_scanning and fh_mkt_cp_go_idx ~= nil then
        if button == 1 and listItem == fh_mkt_cp_go_idx then
            local txt = sampGetDialogText() or ''
            local nxt_raw = fh_mkt_cp_prev_text or txt
            local nxt = fh_find_listitem(nxt_raw, 'Следующая страница')
            if nxt == nil then
                sampAddChatMessage('[FH Market] {ff4444}Ошибка: не найдена след. страница!', 0xFFFFFF)
                fh_mkt_cp_go_idx = nil
                return { dialogId, 0, listItem, inputText }
            end
            fh_mkt_cp_scanning  = true
            fh_mkt_cp_prev_text = txt
            sampAddChatMessage('[FH Market] {ffaa00}Запущен анализ цен. Не открывайте другие диалоги!', 0xFFFFFF)
            _hbr6z(txt)
            local tot = 0; for _ in pairs(fh_mkt_prices) do tot = tot + 1 end
            printStyledString('~w~FH scan p.1: ~r~' .. tot, 2000, 6)
            local fixed = nxt - 2
            fh_mkt_cp_go_idx = nil
            return { dialogId, 1, fixed, inputText }
        end
        local fixed2 = listItem - 2
        fh_mkt_cp_go_idx = nil
        return { dialogId, button, fixed2, inputText }
    end

    local is_auto_resp = (dialogId == 15376)

    if is_auto_resp and fh_mkt_auto_deep_scanning then return false end

    if is_auto_resp and not fh_mkt_auto_deep_scanning and fh_mkt_auto_deep_go_idx ~= nil then
        if button == 1 and listItem == fh_mkt_auto_deep_go_idx then
            fh_mkt_auto_deep_go_idx = nil
            fh_mkt_auto_deep_scanning = true
            fh_mkt_auto_deep_done = 0
            sampAddChatMessage('[MH Auto] {ffaa00}Углублённый скан авторынка запущен!', 0xFFFFFF)
            local txt0 = sampGetDialogText() or ''
            local dlg0 = dialogId
            lua_thread.create(function()
                local rtt_ms = 500; local rtt_n = 0
                local function upd_rtt(ms) rtt_n=rtt_n+1; rtt_ms=math.floor((rtt_ms*math.min(rtt_n-1,9)+ms)/math.min(rtt_n,10)) end
                local function srv_to() return math.max(800, math.min(rtt_ms*4+500, 15000)) end

                local function wait_for_auto_list(old_txt)
                    local timeout_ms = srv_to(); local t0 = os.clock(); local t = 0
                    while t < timeout_ms do
                        wait(16); t = t + 16
                        if sampIsDialogActive() and sampGetCurrentDialogId() == 15376 then
                            local ntxt = sampGetDialogText() or ''
                            if not old_txt or ntxt ~= old_txt then
                                upd_rtt(math.floor((os.clock()-t0)*1000))
                                return sampGetCurrentDialogId(), ntxt
                            end
                        end
                    end
                    return nil, nil
                end
                local function wait_for_auto_detail()
                    local timeout_ms = srv_to(); local t0 = os.clock(); local t = 0
                    while t < timeout_ms do
                        wait(16); t = t + 16
                        if sampIsDialogActive() then
                            if sampGetCurrentDialogId() ~= 15376 then
                                upd_rtt(math.floor((os.clock()-t0)*1000))
                                return sampGetCurrentDialogId(), sampGetDialogText() or '', fh_last_dlg_title or ''
                            end
                        end
                    end
                    return nil, nil, nil
                end
                local cur_dlg = dlg0; local cur_txt = txt0
                while fh_mkt_auto_deep_scanning do
                    local page_items = fh_mkt_parse_auto_list(cur_txt)
                    if #page_items == 0 then goto continue_auto_deep end
                    for _, item in ipairs(page_items) do
                        if not fh_mkt_auto_deep_scanning then break end
                        sampSendDialogResponse(cur_dlg, 1, item.idx - 2, 0)
                        local det_dlg, det_txt, det_title = wait_for_auto_detail()
                        if det_dlg and det_txt then
                            local detail = fh_mkt_parse_auto_detail(det_txt, det_title)
                            if detail and detail.name ~= '' and #detail.history > 0 then
                                fh_mkt_save_auto_detail(detail.name, detail.history)
                            lua_thread.create(function() wait(200); _mh_upload_deals() end)
                            end
                            fh_mkt_auto_deep_done = fh_mkt_auto_deep_done + 1
                            printStyledString('~w~MH Auto deep: ~y~'..fh_mkt_auto_deep_done, 1000, 6)
                            sampSendDialogResponse(det_dlg, 1, 0, '')
                        else
                            fh_mkt_auto_deep_done = fh_mkt_auto_deep_done + 1
                            if sampIsDialogActive() and sampGetCurrentDialogId() ~= 15376 then
                                sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, '')
                            end
                        end
                        local nld, ntxt = wait_for_auto_list(nil)
                        if nld then cur_dlg = nld; cur_txt = ntxt end
                    end
                    if not fh_mkt_auto_deep_scanning then break end
                    ::continue_auto_deep::
                    local cur_txt2 = sampIsDialogActive() and (sampGetDialogText() or '') or cur_txt
                    local next_i = fh_find_listitem(cur_txt2, 'Следующая страница')
                    if not next_i then break end
                    local cid = sampIsDialogActive() and sampGetCurrentDialogId() or cur_dlg
                    local old_txt2 = sampIsDialogActive() and sampGetDialogText() or cur_txt
                    sampSendDialogResponse(cid, 1, next_i - 2, 0)
                    local nld2, ntxt2 = wait_for_auto_list(old_txt2)
                    if nld2 then cur_dlg = nld2; cur_txt = ntxt2
                    else break end
                end
                fh_mkt_auto_deep_scanning = false
                _ryb5t()
                -- [MH Cloud] Авто-пуш цен после авто-скана
                lua_thread.create(function() wait(1000); _mh_prices_push() end)
                if sampIsDialogActive() then sampSendDialogResponse(sampGetCurrentDialogId(), 0, 0, '') end
                sampAddChatMessage('[MH Auto] {00cc00}Углублённый скан завершён! Авто: '..fh_mkt_auto_deep_done, 0xFFFFFF)
                printStyledString('~w~MH Auto DONE: ~g~'..fh_mkt_auto_deep_done, 3000, 6)
            end)
            return false
        end
        if button == 1 and fh_mkt_auto_deep_go_idx and listItem > fh_mkt_auto_deep_go_idx then
            fh_mkt_auto_deep_go_idx = nil
            return { dialogId, button, listItem - 2, inputText }
        end
        fh_mkt_auto_deep_go_idx = nil
    end

    if is_auto_resp and not fh_mkt_auto_scanning and fh_mkt_auto_go_idx ~= nil then
        if button == 1 and listItem == fh_mkt_auto_go_idx then
            local txt = sampGetDialogText() or ''
            local nxt = fh_find_listitem(txt, 'Следующая страница')
            if nxt == nil then
                sampAddChatMessage('[MH Auto] {ff4444}Ошибка: нет след. страницы!', 0xFFFFFF)
                fh_mkt_auto_go_idx = nil
                return { dialogId, 0, listItem, inputText }
            end
            fh_mkt_auto_scanning  = true
            fh_mkt_auto_prev_text = txt
            fh_mkt_auto_page      = 1
            sampAddChatMessage('[MH Auto] {ffaa00}Скан авторынка запущен. Не открывайте другие диалоги!', 0xFFFFFF)
            _gyc9t(txt)
            local tot = 0; for _ in pairs(fh_mkt_auto) do tot = tot + 1 end
            printStyledString('~w~MH Auto p.1: ~r~' .. tot, 2000, 6)
            local fixed_a = nxt - 2
            fh_mkt_auto_go_idx = nil
            return { dialogId, 1, fixed_a, inputText }
        end
        fh_mkt_auto_go_idx = nil
        return { dialogId, button, listItem - 2, inputText }
    end
end

function sampev.onSetObjectMaterialText(ev, data)
    if not (cm_catch_enabled or cm_render_enabled) then return end
    local Object = sampGetObjectHandleBySampId(ev)
    if not (doesObjectExist(Object) and getObjectModel(Object) == 18663) then return end
    if not (data and data.text and data.text:find("\xd1\xe2\xee\xe1\xee\xe4\xed\xe0!")) then return end
    local posX, posY, posZ = getObjectCoordinates(Object)
    local dist = cm_get_distance_to(posX, posY, posZ)
    if dist <= 2.0 and cm_catch_enabled then
        sampAddChatMessage('[MH] {ffaa00}\xcd\xe0\xf8\xb8\xeb \xeb\xe0\xe2\xea\xf3, \xe6\xec\xf3 \xe0\xeb\xfc\xf2...', 0xFFFFFF)
        lua_thread.create(function()
            setGameKeyState(19, 255)
            wait(100)
            setGameKeyState(19, 0)
            _yzr1t(8, 7, -1, {})
        end)
    end
end

function sampev.onServerMessage(color, text)
    if not text then return end
    if fh_lv_autosell_running or fh_lv_autobuy_running then
        _mh_flog('SRV_MSG color=' .. string.format('%06X', color) .. ' text=' .. text:gsub('{%x+}',''):sub(1,100))
    end

    if _G._mh_call_pending_nick and _G._mh_call_pending_nick ~= '' then
        local raw = text:gsub('{' .. '%x+}', '')
        local nick_part, num_part = raw:match('^([%a_][%w_]+%[%d+%])%s*:%s*(%d+)%s*$')
        if num_part and #num_part >= 5 then
            local nick_in_msg = (nick_part or ''):match('^([%a_][%w_]+)')
            if nick_in_msg and nick_in_msg:lower() == _G._mh_call_pending_nick then
                _G._mh_call_pending_nick = nil
                lua_thread.create(function()
                    wait(400)
                    sampSendChat('/call ' .. num_part)
                end)
                return false
            end
        end
    end

    local _hex = string.format('%06X', bit.band(color, 0xFFFFFF))
    local _colored = '{' .. _hex .. '}' .. text
    _vsm8w(_colored)
    table.insert(fh_session_chat, 1, _colored)
    _lvn7s()  -- persist chat to disk

    local trade = _wsn4d(text)
    if trade then
        _ngw1x(trade.item, trade.qty, trade.price, trade.op, trade.partner, trade.is_vc, trade.own)
        -- Обновляем fh_lv_trade_log реальной ценой из серверного сообщения
        -- (до этого там стояла max_price из пресета)
        if trade.price and trade.price > 0 then
            for _, tl in ipairs(fh_lv_trade_log) do
                if tl.item and tl.item:lower() == trade.item:lower()
                   and tl.op == (trade.op == 'SELL' and 'sell' or 'buy')
                   and (tl.price == 0 or tl.price ~= trade.price) then
                    tl.price = trade.price
                    break
                end
            end
        end
        lua_thread.create(function() wait(300); _ryb5t() end)
        if trade.own == true and trade.op == 'SELL' then
            local active_p = settings.presets and settings.presets[fh_active_preset_idx]
            local sell_list = active_p and active_p.items or fh_lv_autosell_preset
            for _asi, asp in ipairs(sell_list) do
                if asp.name:lower() == trade.item:lower() then
                    asp.qty = math.max(0, (asp.qty or 0) - trade.qty)
                    if active_p then active_p.items = sell_list end
                    settings.autosell_preset = fh_lv_autosell_preset
                    if _G.as_qty_buf and _G.as_qty_buf[_asi] then
                        _G.as_qty_buf[_asi] = imgui.new.char[16](tostring(asp.qty))
                    end
                    _wfn7p(); break
                end
            end
        end
        if trade.own == true and trade.op == 'BUY' then
            local buy_preset = fh_lv_autobuy_preset
            local cur_buy_p = settings.buy_presets and settings.buy_presets[fh_ab_preset_idx]
            if cur_buy_p and cur_buy_p.items then buy_preset = cur_buy_p.items end
            for _abi, abp in ipairs(buy_preset) do
                if abp.name:lower() == trade.item:lower() then
                    abp.qty = math.max(0, (abp.qty or 1) - trade.qty)
                    if cur_buy_p then cur_buy_p.items = buy_preset end
                    settings.autobuy_preset = fh_lv_autobuy_preset
                    if _G.ab_qty_buf and _G.ab_qty_buf[_abi] then
                        _G.ab_qty_buf[_abi] = imgui.new.char[16](tostring(abp.qty))
                    end
                    _wfn7p(); break
                end
            end
        end
    end

    do
        local clean_os = text:gsub('{%x+}', '')
        local owner_m = clean_os:match('^([%a_][%w_]+)%s+продаёт%s+товар')
        if owner_m then
            fh_other_shop_owner = owner_m
        end
        local chat_num = clean_os:match('#(%d+)')
        if chat_num then
            local num = tonumber(chat_num)
            if num and num >= 1 and num <= 9999 then
                fh_other_shop_pending_num = num
                if mh_debug_enabled then
                    sampAddChatMessage('[MH CHAT#] num='..num..' msg='..clean_os:sub(1,40), 0xAAFFFF)
                end
            end
        end
    end

    -- Ловушка диалогов скупки: если скрипт ждёт диалог в wait_dialog
    -- и он пришёл пока wait() спал — сохраняем его ID.
    -- Ловим ВСЕ ожидаемые ID, а не только часть, чтобы при фризе сети
    -- запоздавший диалог не потерялся и не сломал следующие итерации.
    if fh_lv_autobuy_running and (
        dialogId == 25665 or dialogId == 25666 or
        dialogId == 26558 or dialogId == 26560 or
        dialogId == 26561 or dialogId == 26563 or dialogId == 3060
    ) then
        _G.mh_ab_caught_dlg = dialogId
    end

    if _G.mh_ab_wait_confirm and _G.mh_ab_confirm_data then
        local clean_srv = text:gsub('{%x+}', '')
        if clean_srv:find('выставлен на скупку') or clean_srv:find('скупк') or
           clean_srv:find('успешно') or clean_srv:find('установлен') then
            _dsf3y(
                _G.mh_ab_confirm_data.name,
                _G.mh_ab_confirm_data.price,
                _G.mh_ab_confirm_data.qty,
                'buy', 'ok'
            )
            _G.mh_ab_wait_confirm = false
            _G.mh_ab_confirm_data = nil
        end
    end

    if fh_lv_autosell_running then
        local clean = text:gsub('{%x+}', '')
        if clean:find('успешно выставлен на продажу') then
            fh_lv_sell_confirmed = true
        end
        if clean:find('Данные товары запрещено продавать') then
            fh_lv_sell_forbidden = true
            fh_lv_sell_confirmed = true  -- пропускаем
        end
        if clean:find('нет доступных ячеек') then
            fh_lv_sell_no_slots  = true
            fh_lv_sell_confirmed = true  -- пропускаем
        end
        if clean:find('Продажа деактивирована') or clean:find('закрыли лавку') then
            fh_mkt_lavka_ids = {}
            fh_mkt_lavka_all_tds = {}
            fh_mkt_lavka_page_id = -1
        end
    end
end

function sampev.onChatMessage(playerId, text)
    if not text then return end
    local ok, name = pcall(sampGetPlayerNickname, playerId)
    if not ok or not name then name = tostring(playerId) end
    local msg = '{FFFFFF}' .. name .. ': ' .. text
    table.insert(fh_session_chat, 1, msg)
    _lvn7s()
end

addEventHandler("onReceivePacket", function(packet_id, bs)
    if packet_id ~= 220 then return end
    raknetBitStreamIgnoreBits(bs, 8)
    local marker = raknetBitStreamReadInt8(bs)
    if marker ~= 84 then return end
    local iface  = raknetBitStreamReadInt8(bs)
    local subid  = raknetBitStreamReadInt8(bs)
    local json_s = _dkn5v(bs)
    if not json_s then return end
    -- File log: all 220 packets
    _mh_flog('PKT220 iface=' .. iface .. ' sub=' .. subid .. ' json=' .. json_s:sub(1,200))
    if iface == 52 then
        if mh_debug_enabled then sampAddChatMessage("[52] sub="..subid.." "..json_s:sub(1,80), 0x888888) end
    end

    if iface == 52 and subid == 2 then
          local pkt_type_52 = tonumber(json_s:match('"type"%s*:%s*(%d+)')) or 0
          _mh_flog('PKT52 type=' .. pkt_type_52 .. ' json_start=' .. json_s:sub(1,150))

          -- type=1: player lavka inventory (new after update)
          if pkt_type_52 == 1 then
              local slots_list = {}
              for item_obj in json_s:gmatch('{"[^}]+}') do
                  local slot = tonumber(item_obj:match('"slot"%s*:%s*(%d+)'))
                  local item = tonumber(item_obj:match('"item"%s*:%s*(%d+)'))
                  if slot and item then
                      table.insert(slots_list, {slot=slot, item=item})
                  end
              end
              if #slots_list > 0 then
                  table.sort(slots_list, function(a,b) return a.slot < b.slot end)
                  mh_lavka_inv = {}
                  for idx, entry in ipairs(slots_list) do
                      mh_lavka_inv[idx-1] = entry
                  end
                  mh_lavka_inv_ready = true
                  mh_sell_confirmed = true
                  if mh_debug_enabled then
                      sampAddChatMessage("[MH PKT52/1] Инвентарь: " .. #slots_list .. " предметов", 0x88CCFF)
                  end
                  _mh_flog("PKT52/type1 lavka_inv=" .. #slots_list .. " slots")
              end
          end

          if pkt_type_52 == 13 or pkt_type_52 == 28 then
              local buf_items = {}
              for item_obj in json_s:gmatch('{([^}]+)}') do
                  local item_id   = tonumber(item_obj:match('"item"%s*:%s*(%d+)'))
                  local amount_r  = tonumber(item_obj:match('"amount"%s*:%s*(%d+)')) or 0
                  local price_txt = item_obj:match('"text"%s*:%s*"([^"]*)"')
                  local price_t   = (price_txt and #price_txt > 0) and _parse_trade_sum(price_txt) or 0
                  local price     = (price_t > amount_r) and price_t or amount_r
                  local _sn       = tonumber(item_obj:match('"slot"%s*:%s*(%d+)')) or 0
                  if item_id and price and price > 0 then
                      table.insert(buf_items, {item_id=item_id, price=price, avail=1, slot_idx=_sn})
                  end
              end
              if #buf_items > 0 then
                    local was_empty = (#mh_pending_lavka_buf == 0)
                    table.insert(mh_pending_lavka_buf, {pkt_type=pkt_type_52, items=buf_items})
                    if mh_debug_enabled then
                        local lbl = pkt_type_52==13 and 'SELL' or 'BUY'
                        sampAddChatMessage('[MH buf/52] '..lbl..'+'..(#buf_items)..' pending='..(#mh_pending_lavka_buf), 0x888888)
                    end
                    if was_empty then
                        lua_thread.create(function()
                            wait(2500)
                            if #mh_pending_lavka_buf == 0 then return end  -- уже обработан
                            if fh_other_shop_cur and (#fh_other_shop_cur.sell_items > 0 or #fh_other_shop_cur.buy_items > 0) then return end
                            local fallback_owner = (fh_other_shop_owner and fh_other_shop_owner ~= '') and fh_other_shop_owner or nil
                            if not fallback_owner then
                                sampAddChatMessage('[MH] {ff9900}Не удалось определить владельца лавки.', 0xFFFFFF)
                                mh_pending_lavka_buf = {}; return
                            end
                            local my_nick = ''
                            pcall(function() my_nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) or '' end)
                            if fallback_owner:lower() == my_nick:lower() then mh_pending_lavka_buf = {}; return end
                            if mh_debug_enabled then sampAddChatMessage('[MH fb] Форс-обработка: '..fallback_owner, 0xFF9900) end
                            fh_other_shop_cur = {
                                owner      = fallback_owner,
                                shop_num   = fh_other_shop_pending_num or '?',
                                dt         = os.date('%d.%m %H:%M'),
                                ts         = os.time(),
                                sell_items = {}, buy_items = {},
                                server_id  = (ARZ_SERVERS[(_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1)) or (_mpf7d()+1)] or {}).id or -1,
                            }
                            fh_other_shop_scanning = true
                            for _, batch in ipairs(mh_pending_lavka_buf) do
                                local cur_list
                                if batch.pkt_type == 13 then cur_list = fh_other_shop_cur.sell_items
                                elseif batch.pkt_type == 28 then cur_list = fh_other_shop_cur.buy_items end
                                if cur_list then
                                    local groups, order = {}, {}
                                    for _, it in ipairs(batch.items) do
                                        local nm = _rgn9z(it.item_id)
                                        local clean_nm = nm:gsub('{[^}]+}',''):match('^%s*(.-)%s*$') or nm
                                        local key = tostring(it.item_id)..'|'..tostring(it.price)
                                        if groups[key] then groups[key].qty = groups[key].qty + 1
                                        else groups[key]={name=clean_nm,price=it.price,qty=1,item_id=it.item_id,slot_idx=it.slot_idx or 0}; table.insert(order,key) end
                                    end
                                    for _, key in ipairs(order) do table.insert(cur_list, groups[key]) end
                                end
                            end
                            mh_pending_lavka_buf = {}
                            local sc = #fh_other_shop_cur.sell_items
                            local bc = #fh_other_shop_cur.buy_items
                            sampAddChatMessage('[MH] {aaaaff}Лавка '..fallback_owner..': продажа='..sc..', скупка='..bc, 0xFFFFFF)
                            if sc > 0 or bc > 0 then _qbh9f() end
                            fh_other_shop_scanning = false
                        end)
                    end
                end
            else
          local slots_list = {}
          for item_obj in json_s:gmatch('{([^}]+)}') do
              local slot = tonumber(item_obj:match('"slot"%s*:%s*(%d+)'))
              local item = tonumber(item_obj:match('"item"%s*:%s*(%d+)'))
              if slot and item then
                  table.insert(slots_list, {slot=slot, item=item})
              end
          end
          table.sort(slots_list, function(a,b) return a.slot < b.slot end)
          mh_sell_confirmed = true
          mh_lavka_inv = {}
          for idx, entry in ipairs(slots_list) do
              mh_lavka_inv[idx-1] = entry
          end
          if mh_debug_enabled then sampAddChatMessage("[MH PKT] Инвентарь: " .. #slots_list .. " предметов", 0x888888) end
          for i=0, math.min(4, #slots_list-1) do
              local e = mh_lavka_inv[i]
              if mh_debug_enabled and e then sampAddChatMessage("  ["..i.."] slot="..e.slot.." item="..e.item, 0x888888) end
          end
          end
      end

    if iface == 60 and subid == 1 then
        _mh_flog('PKT60_1 full json=' .. json_s:sub(1,500))
        if mh_debug_enabled then sampAddChatMessage('[MH] {88CCFF}iface=60/sub=1 пришёл', 0x88CCFF) end
        mh_lavka_inv = {}
        mh_lavka_inv_ready = true
        local _enc = require('encoding')
        local _ok_enc, json_s_u8 = pcall(function() return _enc.UTF8:decode(json_s) end)
        if _ok_enc and json_s_u8 and #json_s_u8 > 0 then json_s = json_s_u8 end
        -- New format: {"name":"Nick","type":0} - owner is directly in 'name' field
        local owner_j = json_s:match('"name"%s*:%s*"([^"]+)"')
        if not owner_j or owner_j == '' then
            owner_j = json_s:match('"owner"%s*:%s*"([^"]+)"')
                   or json_s:match('"nick"%s*:%s*"([^"]+)"')
        end
        -- Strip "Торговая лавка - " prefix: after game update, name field = full title
        -- Use explicit [A-Za-z] NOT %a: on Android Russian locale, %a matches Cyrillic too!
        if owner_j then
            owner_j = owner_j:match('%-%s*([A-Za-z_][A-Za-z0-9_]+)')
                   or owner_j:match('^([A-Za-z_][A-Za-z0-9_]+)')
                   or owner_j
        end
        local shop_title = owner_j or ''
        local shopnum_j = json_s:match('"shopNum"%s*:%s*(%d+)')
                       or json_s:match('"shopId"%s*:%s*(%d+)')
                       or json_s:match('"lavkaId"%s*:%s*(%d+)')
        if owner_j and owner_j ~= '' then
            fh_other_shop_owner = owner_j
        end
        if mh_debug_enabled then
            sampAddChatMessage('[MH 60/1] title='..shop_title..' owner='..(owner_j or '?'), 0x88CCFF)
        end
        local my_nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) or ''
        local is_my_shop = (owner_j and owner_j:lower() == my_nick:lower())
        if is_my_shop then mh_pending_lavka_buf = {} end
        if not is_my_shop then
            local eff_owner = owner_j or fh_other_shop_owner or ''
            if eff_owner ~= '' then
                fh_other_shop_price_tds = {}
                local _snum = shopnum_j or fh_other_shop_pending_num
                if not _snum then
                    local _px, _py = getCharCoordinates(PLAYER_PED)
                    local _bd, _bn = 6.0, nil  -- макс 6м: соседние лавки обычно от 4м+
                    for _tid = 0, 2047 do
                        local _ok, _tt, _tc, _tpx, _tpy = pcall(sampGet3dTextInfoById, _tid)
                        if _ok and _tt and _tpx then
                            local _n = tostring(_tt):match('[#№](%d+)')
                            if _n then
                                local _num = tonumber(_n)
                                if _num and _num >= 1 and _num <= 9999 then
                                    local _d = math.sqrt((_tpx-_px)^2 + (_tpy-_py)^2)
                                    if _d < _bd then _bd = _d; _bn = _num end
                                end
                            end
                        end
                    end
                    _snum = _bn
                end
                fh_other_shop_cur = {
                    owner      = eff_owner,
                    shop_num   = _snum or '?',
                    dt         = os.date('%d.%m %H:%M'),
                    sell_items = {},
                    buy_items  = {},
                    server_id  = (function()
                        local _sel = (_G.arz_srv_sel and (_G.arz_srv_sel[0]+1)) or (_G.mh_boot_srv_idx and (_G.mh_boot_srv_idx+1))
                        local _sid2 = (_sel and (ARZ_SERVERS[_sel] or {}).id) or -1
                        if _sid2 == -1 then
                            local _au = _mpf7d()
                            if _au and _au > 0 then _sid2 = (ARZ_SERVERS[_au+1] or {}).id or -1 end
                        end
                        return _sid2
                    end)(),
                }
                fh_other_shop_scanning = true
                fh_other_shop_pending_num = nil  -- сброс после использования
                for _, batch in ipairs(mh_pending_lavka_buf) do
                    local cur_list
                    if     batch.pkt_type == 13 then cur_list = fh_other_shop_cur.sell_items
                    elseif batch.pkt_type == 28 then cur_list = fh_other_shop_cur.buy_items
                    end
                    if cur_list then
                        local groups = {}  -- key -> {nm, price, qty, item_id, slot_idx}
                        local order  = {}  -- порядок появления ключей
                        for _, it in ipairs(batch.items) do
                            local nm = _rgn9z(it.item_id)
                            local clean_nm = nm:gsub('{[^}]+}', ''):match('^%s*(.-)%s*$') or nm
                            local key = tostring(it.item_id) .. '|' .. tostring(it.price)
                            if groups[key] then
                                groups[key].qty = groups[key].qty + 1
                            else
                                groups[key] = {
                                    name     = clean_nm,
                                    price    = it.price,
                                    qty      = 1,
                                    item_id  = it.item_id,
                                    slot_idx = it.slot_idx or 0,
                                }
                                table.insert(order, key)
                            end
                        end
                        for _, key in ipairs(order) do
                            table.insert(cur_list, groups[key])
                        end
                    end
                end
                mh_pending_lavka_buf = {}
                if mh_debug_enabled then
                    sampAddChatMessage('[MH 60/1] '..eff_owner..' sell='..#fh_other_shop_cur.sell_items..' buy='..#fh_other_shop_cur.buy_items..' srv='..tostring(fh_other_shop_cur.server_id), 0x88CCFF)
                end

                lua_thread.create(function()
                    wait(300)
                    if not fh_other_shop_cur then return end
                    local sell_c = #fh_other_shop_cur.sell_items
                    local buy_c  = #fh_other_shop_cur.buy_items
                    if sell_c > 0 or buy_c > 0 then
                        _qbh9f()
                    else
                    end
                    fh_other_scan_done  = sell_c + buy_c
                    fh_other_scan_total = sell_c + buy_c
                    fh_other_shop_scanning = false
                end)
            end
        end
    end

    if iface == 60 and subid == 0 then
        local pkt_type = tonumber(json_s:match('"type"%s*:%s*(%d+)')) or 0
        if pkt_type == 13 or pkt_type == 28 then
            local buf_items = {}
            for item_obj in json_s:gmatch('{([^}]+)}') do
                local item_id   = tonumber(item_obj:match('"item"%s*:%s*(%d+)'))
                local amount_r  = tonumber(item_obj:match('"amount"%s*:%s*(%d+)')) or 0
                local price_txt = item_obj:match('"text"%s*:%s*"([^"]*)"')
                local price_t   = (price_txt and #price_txt > 0) and _parse_trade_sum(price_txt) or 0
                local price     = (price_t > amount_r) and price_t or amount_r
                local _sn       = tonumber(item_obj:match('"slot"%s*:%s*(%d+)')) or 0
                if item_id and price and price > 0 then
                    table.insert(buf_items, {item_id=item_id, price=price, avail=1, slot_idx=_sn})
                end
            end
            if #buf_items > 0 then
                table.insert(mh_pending_lavka_buf, {pkt_type=pkt_type, items=buf_items})
                if mh_debug_enabled then
                    local lbl = pkt_type==13 and 'SELL' or 'BUY'
                    sampAddChatMessage('[MH buf] '..lbl..'+'..(#buf_items)..' pending='..(#mh_pending_lavka_buf), 0x888888)
                end
            else
                if mh_debug_enabled then
                    sampAddChatMessage('[MH buf] 60/0 type='..pkt_type..' buf_items=0 (price=0 у всех?)', 0xFF8800)
                    -- Показываем первый item для диагностики
                    local _first = json_s:match('{([^}]+)}')
                    if _first then sampAddChatMessage('[MH buf raw] '.._first:sub(1,100), 0xFF8800) end
                end
            end
        end
    end

    if iface == 52 and fh_other_shop_scanning and fh_other_shop_cur then
        if mh_debug_enabled then
            sampAddChatMessage('[MH 52] инв. получен, скан лавки идёт...', 0x888888)
        end
    end

    if iface == 52 and subid == 2 and mh_lavka_inv_ready then
        if fh_lv_autostart_enabled and #fh_lv_autosell_preset > 0 and not fh_lv_autosell_running and next(mh_lavka_inv) then
            fh_lv_sell_confirmed = false
            fh_lv_sell_forbidden = false
            fh_lv_sell_no_slots  = false
            sampAddChatMessage("[MH] {00cc00}Автозапуск выкладки!", 0xFFFFFF)
            lua_thread.create(function() wait(300); _wmc7r() end)
        end
    end
end)

imgui.OnFrame(function() return MainWindow[0] end, function()
    local d = settings.general.custom_dpi
    local ar = settings.interface.accent_r or 1.0
    local ag = settings.interface.accent_g or 0.55
    local ab = settings.interface.accent_b or 0.0
    local sb_r = settings.interface.sell_btn_r or 0.10
    local sb_g = settings.interface.sell_btn_g or 0.45
    local sb_b = settings.interface.sell_btn_b or 0.10
    local bb_r = settings.interface.buy_btn_r  or 0.00
    local bb_g = settings.interface.buy_btn_g  or 0.28
    local bb_b = settings.interface.buy_btn_b  or 0.50
    local bg = settings.interface.bg_brightness or 0.06
    local lp_r = settings.overlay and settings.overlay.log_price_r or 1.0
    local lp_g = settings.overlay and settings.overlay.log_price_g or 0.85
    local lp_b = settings.overlay and settings.overlay.log_price_b or 0.2
    do
        local _mwc = settings.mh_win
        local _use_saved = _mwc and _mwc.w and _mwc.w > 200 and _mwc.h and _mwc.h > 100
        local _mw = _use_saved and _mwc.w or 900*d
        local _mh = _use_saved and _mwc.h or 520*d
        if _G._mh_win_reset then
            -- Явный сброс — применить размер из settings принудительно
            imgui.SetNextWindowPos(imgui.ImVec2(sizeX/2, sizeY/2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(_mw, _mh), imgui.Cond.Always)
            _G._mh_win_reset = false
        else
            imgui.SetNextWindowPos(imgui.ImVec2(sizeX/2, sizeY/2), imgui.Cond.Once, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(_mw, _mh), imgui.Cond.Once)
        end
    end
    imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true

    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(ar*0.80, ag*0.80, ab*0.80, 1.0))
    imgui.Begin(u8(" MARKET HELPER  v" .. thisScript().version .. " "), MainWindow, imgui.WindowFlags.NoCollapse)
    imgui.PopStyleColor()
    _ltz8m()

    -- Синхронизируем реальный размер окна -> settings + слайдеры VID
    do
        local _rws = imgui.GetWindowSize()
        if _rws.x > 200 and _rws.y > 100 then
            if not settings.mh_win then settings.mh_win = {} end
            -- Сохраняем только если изменился (не чаще 1 сек)
            local _rsw, _rsh = settings.mh_win.w, settings.mh_win.h
            if math.abs((_rsw or 0) - _rws.x) > 2 or math.abs((_rsh or 0) - _rws.y) > 2 then
                settings.mh_win.w = _rws.x; settings.mh_win.h = _rws.y
                local _now = os.clock()
                if not _G._mh_winsave_t or _now - _G._mh_winsave_t > 1.0 then
                    _wfn7p(); _G._mh_winsave_t = _now
                end
            end
            -- Обновляем буферы слайдеров чтобы показывали реальный размер
            if _G.sl_win_w then _G.sl_win_w[0] = _rws.x / d end
            if _G.sl_win_h then _G.sl_win_h[0] = _rws.y / d end
        end
    end

    do
        local _io = imgui.GetIO()
        local _sw = _G._sw
        local _dy = _io.MouseDelta.y
        local _dn = _io.MouseDown[0]

        if _dn then
            if _io.MouseClicked[0] then
                _sw.blocked = imgui.IsAnyItemActive() or imgui.IsAnyItemHovered()
                _sw.active  = false
                _sw.vel     = 0
                _sw.drag_y  = 0
            end
            if not _sw.blocked and math.abs(_dy) > 0.3 then
                _sw.active = true
                _sw.vel    = _sw.vel * 0.55 + _dy * 0.45
                _sw.drag_y = _dy
            else
                _sw.drag_y = 0
            end
        else
            if _sw.active then
                _sw.inertia = _sw.vel * 3.0
                _sw.active  = false
                _sw.vel     = 0
            end
            _sw.drag_y = 0
            if math.abs(_sw.inertia) > 0.8 then
                _sw.drag_y  = _sw.inertia
                _sw.inertia = _sw.inertia * 0.80
            else
                _sw.inertia = 0
            end
        end
    end

    local hw = imgui.GetWindowWidth()
    local dl = imgui.GetWindowDrawList()
    local wp = imgui.GetCursorScreenPos()
    imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), u8'  MARKET HELPER')
    imgui.SameLine()
    imgui.TextColored(imgui.ImVec4(ar*0.45,ag*0.45,ab*0.45,1), u8'  ·  ARIZONA RP  ·  v3.7')
    if _bcn4w() then
        imgui.SameLine(0, 10*d)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.85, 0.10, 1))
        imgui.Text(_ic_star .. ' PREMIUM')
        imgui.PopStyleColor()
    end
    imgui.SameLine(hw - 72*d)
    imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _ic_circ)
    imgui.SameLine(0,4*d)
    imgui.TextColored(imgui.ImVec4(ar*0.60, ag*0.60, ab*0.60, 1), _ic_circ)
    imgui.SameLine(0,4*d)
    imgui.TextColored(imgui.ImVec4(ar*0.25, ag*0.25, ab*0.25, 1), _ic_circ)
    imgui.Separator()
    imgui.Spacing()

    if not _G.mh_tab then _G.mh_tab = 1 end
    local sidebar_w = 130*d
    local mh_sidebar_items = {
        { icon = fa.STORE,              label = u8'\xd0\xdb\xcd\xce\xca',              id = 1 },
        { icon = fa.WAREHOUSE,          label = u8'\xcb\xc0\xc2\xca\xc8',              id = 2 },
        { icon = fa.TAG,                label = u8'\xcf\xd0\xce\xc4\xc0\xc6\xc0',   id = 3 },
        { icon = fa.CART_PLUS,          label = u8'\xd1\xca\xd3\xcf\xca\xc0',         id = 4 },
        { icon = fa.CLOCK_ROTATE_LEFT,  label = u8'\xcb\xce\xc3',                        id = 5 },
        { icon = fa.CIRCLE_PLUS,        label = u8'\xca\xc0\xcb\xdc\xca.',               id = 11 },
        { icon = fa.BULLHORN,           label = u8'\xcf\xc8\xc0\xd0',                    id = 7 },
        { icon = fa.PALETTE,            label = u8'\xc2\xc8\xc4',                        id = 6 },
        { icon = fa.CROSSHAIRS,         label = u8'\xcb\xce\xc2\xcb\xdf',               id = 8 },
        { icon = fa.CIRCLE_INFO,        label = u8'\xce \xd1\xca\xd0\xc8\xcf\xd2\xc5', id = 9 },
        { icon = fa.STAR,               label = u8'Premium',                  id = 10 },
    }
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(bg*0.7, bg*0.7, bg*0.7, 1.0))
    imgui.PushStyleColor(imgui.Col.Border,  imgui.ImVec4(ar*0.25, ag*0.25, ab*0.25, 0.5))
    if imgui.BeginChild('##mh_sidebar', imgui.ImVec2(sidebar_w, imgui.GetContentRegionAvail().y), true) then
        _dpn1w()  -- swipe scroll
        imgui.Spacing()
        for _, stab in ipairs(mh_sidebar_items) do
            local is_active = _G.mh_tab == stab.id
            if is_active then
                local _btn_r, _btn_g, _btn_b = ar, ag, ab
                if stab.id == 10 then _btn_r, _btn_g, _btn_b = 1.0, 0.82, 0.10 end
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(_btn_r, _btn_g, _btn_b, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(_btn_r*0.85, _btn_g*0.85, _btn_b*0.85, 1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(_btn_r*0.95, _btn_g*0.95, _btn_b*0.95, 1))
                imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.04,    0.04,    0.03,   1))
            else
                local _idle_text = stab.id==10 and imgui.ImVec4(1.0,0.82,0.10,0.9) or imgui.ImVec4(0.65,0.65,0.65,1)
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(bg+.05,  bg+.045, bg+.025,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar*0.20, ag*0.20, ab*0.20, 1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(ar*0.35, ag*0.35, ab*0.35, 1))
                imgui.PushStyleColor(imgui.Col.Text,          _idle_text)
            end
            local btn_lbl = stab.icon .. '  ' .. stab.label .. '##sb' .. stab.id
            if imgui.Button(btn_lbl, imgui.ImVec2(sidebar_w - 10*d, 40*d)) then
                _G.mh_tab = stab.id
            end
            imgui.PopStyleColor(4)
            imgui.Spacing()
        end
        imgui.EndChild()
    end
    imgui.PopStyleColor(2)
    imgui.SameLine(0, 6*d)

    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(bg+.025, bg+.022, bg+.012, 1.0))
    if imgui.BeginChild('##mh_content', imgui.ImVec2(-1, imgui.GetContentRegionAvail().y), false) then

        _qbs9k()
    if _G.mh_tab == 10 then
        local d_pm = settings.general.custom_dpi
        local pm_h = imgui.GetWindowHeight() - 55*d_pm
        if imgui.BeginChild('##prem_wrap', imgui.ImVec2(-1, pm_h), false) then
            _dpn1w()  -- swipe scroll
            imgui.Spacing()
            local gold    = imgui.ImVec4(1.0, 0.82, 0.10, 1)
            local gold_dim = imgui.ImVec4(0.75, 0.62, 0.08, 1)
            imgui.SetCursorPosX((imgui.GetWindowContentRegionWidth() - imgui.CalcTextSize(_ic_star..' PREMIUM '.._ic_star).x) * 0.5)
            imgui.PushStyleColor(imgui.Col.Text, gold)
            imgui.Text(_ic_star..' PREMIUM '.._ic_star)
            imgui.PopStyleColor()
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            local is_prem = _bcn4w()
            if is_prem then
                imgui.SetCursorPosX((imgui.GetWindowContentRegionWidth()-280*d_pm)*0.5)
                imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.12,0.10,0.02,1))
                imgui.PushStyleColor(imgui.Col.Border,  imgui.ImVec4(1.0,0.82,0.10,0.8))
                if imgui.BeginChild('##prem_active_box', imgui.ImVec2(310*d_pm, 120*d_pm), true) then
                    imgui.Spacing()
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.3,0.95,0.3,1))
                    imgui.SetCursorPosX((imgui.GetColumnWidth()-imgui.CalcTextSize(_ic_chk).x)*0.5)
                    imgui.Text(_ic_chk..' '.._cyr5f('Активирован'))
                    imgui.PopStyleColor()
                    local prem_user = settings.premium.user or ''
                    if prem_user ~= '' then
                        imgui.PushStyleColor(imgui.Col.Text, gold_dim)
                        imgui.SetCursorPosX((imgui.GetColumnWidth()-imgui.CalcTextSize(_cyr5f(prem_user)).x)*0.5)
                        imgui.Text(_cyr5f(prem_user))
                        imgui.PopStyleColor()
                    end
                    local prem_exp = settings.premium.expires or ''
                    if prem_exp ~= '' then
                        local exp_col = imgui.ImVec4(0.7,0.7,0.7,1)  -- грей
                        local days_left = nil
                        pcall(function()
                            local y,m,d = prem_exp:match('(%d+)[%-%.](%d+)[%-%.](%d+)')
                            if y then
                                local exp_ts = os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=23,min=59,sec=59})
                                local now_ts = os.time()
                                days_left = math.ceil((exp_ts - now_ts) / 86400)
                                if days_left <= 3 then
                                    exp_col = imgui.ImVec4(1.0,0.4,0.2,1)  -- красный
                                elseif days_left <= 7 then
                                    exp_col = imgui.ImVec4(1.0,0.75,0.1,1)  -- оранжевый
                                end
                            end
                        end)
                        local exp_suffix = ''
                        if days_left then
                            if days_left <= 0 then
                                exp_suffix = ' (истекла)'
                            elseif days_left == 1 then
                                exp_suffix = ' (1 день)'
                            elseif days_left <= 4 then
                                exp_suffix = ' (' .. days_left .. ' дня)'
                            elseif days_left <= 7 then
                                exp_suffix = ' (' .. days_left .. ' дней)'
                            end
                        end
                        local exp_lbl = _cyr5f('До: ' .. prem_exp .. exp_suffix)
                        imgui.PushStyleColor(imgui.Col.Text, exp_col)
                        imgui.SetCursorPosX((imgui.GetColumnWidth()-imgui.CalcTextSize(exp_lbl).x)*0.5)
                        imgui.Text(exp_lbl)
                        imgui.PopStyleColor()
                    end
                    imgui.Spacing(); imgui.EndChild()
                end
                imgui.PopStyleColor(2); imgui.Spacing()
                imgui.SetCursorPosX((imgui.GetWindowContentRegionWidth()-200*d_pm)*0.5)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.35,0.12,0.12,1))
                if imgui.Button(_ic_x..' '.._cyr5f('Деактивировать##prem_deact'), imgui.ImVec2(200*d_pm,0)) then
                    settings.premium.activated=false; settings.premium.key=''; settings.premium.user=''; _qtp7v=false
                    _wfn7p()
                end
                imgui.PopStyleColor(); imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            end
            if not _G.prem_key_buf then
                _G.prem_key_buf = imgui.new.char[128](_cyr5f(settings.premium.key or ''))
            end
            imgui.TextColored(gold_dim, _ic_key..' ')
            imgui.SameLine(0,6*d_pm)
            imgui.TextDisabled(_cyr5f('Лицензионный ключ:'))
            imgui.PushItemWidth(-1)
            imgui.PushStyleColor(imgui.Col.FrameBg,  imgui.ImVec4(0.10,0.08,0.02,1))
            imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(0.75,0.62,0.08,0.7))
            imgui.InputText('##prem_key_inp', _G.prem_key_buf, 128)
            imgui.PopStyleColor(2); imgui.PopItemWidth(); imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.45,0.35,0.04,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65,0.52,0.06,1))
            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.0,0.95,0.7,1))
            local _btn_lbl = _prem_checking
                and (_ic_spin..' '.._cyr5f('Проверка...'))
                or  (_ic_bolt..' '.._cyr5f('Активировать##prem_act'))
            if imgui.Button(_btn_lbl, imgui.ImVec2(-1, 36*d_pm)) and not _prem_checking then
                local key_entered = u8:decode(ffi.string(_G.prem_key_buf)):gsub('^%s+',''):gsub('%s+$','')
                if key_entered ~= '' then
                    _fpc2t(key_entered, function(ok2, user2)
                        if ok2 then
                            local _exp2 = settings.premium.expires or ''
                            local _nick2 = settings.premium.nick or ''
                            local _msg = '[MH] {FFD700}Premium Активирован!'
                            if _nick2 ~= '' then
                                _msg = _msg .. ' {ffffff}Ник: {FFD700}' .. _nick2
                            end
                            if _exp2 ~= '' then
                                _msg = _msg .. ' {aaaaaa}| {ffffff}До: ' .. _exp2
                            else
                                _msg = _msg .. ' {aaaaaa}| {ff8800}Срок: не задан'
                            end
                            sampAddChatMessage(_msg, 0xFFFFFF)
                        else sampAddChatMessage('[MH] {FF4444}Premium: Неверный ключ', 0xFFFFFF) end
                    end)
                end
            end
            imgui.PopStyleColor(3)
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.45,0.35,0.04,1))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65,0.52,0.06,1))
            imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.0,0.95,0.7,1))
            if imgui.Button(_ic_star..' '.._cyr5f('Купить Premium')..' '.._ic_star..'##prem_buy_btn', imgui.ImVec2(-1, 36*d_pm)) then
                if _cvh6z() then
                    pcall(gta._Z12AND_OpenLinkPKc, 'https://t.me/markethelper_premium_bot')
                else
                    os.execute('start https://t.me/markethelper_premium_bot')
                end
            end
            imgui.PopStyleColor(3)
            if _prem_check_status ~= '' then
                imgui.Spacing()
                local _psc_ok = (_prem_check_status == 'OK')
                local _psc = _psc_ok and imgui.ImVec4(0.3,0.95,0.3,1) or imgui.ImVec4(1,0.45,0.25,1)
                local _psc_txt = _prem_check_status
                if _psc_ok then
                    local _exp_s = settings.premium.expires or ''
                    local _usr_s = settings.premium.user or ''
                    _psc_txt = 'Ключ принят'
                    if _usr_s ~= '' and _usr_s ~= 'Premium User' then
                        _psc_txt = _psc_txt .. '  ·  ' .. _usr_s
                    end
                    if _exp_s ~= '' then
                        _psc_txt = _psc_txt .. '  ·  До: ' .. _exp_s
                    end
                end
                imgui.TextColored(_psc, _cyr5f(_psc_txt))
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(gold_dim, _cyr5f(' Что открывает Premium:'))
            imgui.Spacing()
            local feats = {
                {_ic_scl, 'Арбитраж — выгодные сделки между лавками и рынком'},
                {_ic_flt,         'Фильтры по цене и тренду в таблице Рынка'},
                {_ic_eye,            'Теги на товары: Смотреть / Не брать / Избранное'},
                {_ic_wh,      'Теги видны в Чужих лавках и АРЗ Базе при поиске'},
                {_ic_star,           'Золотая подсветка Premium в шапке окна'},
            }
            for _, fv in ipairs(feats) do
                imgui.TextColored(gold, fv[1]..' ')
                imgui.SameLine(0,6*d_pm)
                imgui.TextColored(imgui.ImVec4(0.85,0.85,0.85,1), _cyr5f(fv[2]))
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(0.4,0.4,0.4,1), _ic_shield..' ')
            imgui.SameLine(0,5*d_pm)
            imgui.TextColored(imgui.ImVec4(0.45,0.45,0.45,1), _cyr5f('Авторизация работает на инфраструктуре Google Cloud'))
            imgui.EndChild()
        end
    end

    if _G.mh_tab == 11 then
        -- \xca\xe0\xeb\xfc\xea\xf3\xeb\xff\xf2\xee\xf0
        if not _G.mh_calc then
            _G.mh_calc = {
                expr    = '',        -- \xf2\xe5\xea\xf3\xf9\xe5\xe5 \xe2\xfb\xf0\xe0\xe6\xe5\xed\xe8\xe5
                result  = nil,       -- \xef\xee\xf1\xeb\xe5\xe4\xed\xe8\xe9 \xf0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2
                err     = false,     -- \xee\xf8\xe8\xe1\xea\xe0
                fresh   = false,     -- \xf2\xee\xeb\xfc\xea\xee \xed\xe0\xe6\xe0\xeb\xe8 =
            }
        end
        local calc = _G.mh_calc

        local function calc_append(v)
            if calc.fresh then
                -- \xef\xee\xf1\xeb\xe5 = \xf1\xf0\xe0\xe7\xf3 \xed\xe0\xf7\xe8\xed\xe0\xe5\xec \xed\xee\xe2\xf3\xfe \xee\xef\xe5\xf0\xe0\xf6\xe8\xfe \xee\xf2 \xf0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2\xe0
                if v:match('[%+%-%*/]') then
                    calc.expr = tostring(calc.result or '0') .. v
                else
                    calc.expr = v
                end
                calc.fresh = false; calc.err = false
            else
                if calc.err then calc.expr = v; calc.err = false
                else calc.expr = calc.expr .. v end
            end
        end

        local function calc_eval()
            if calc.expr == '' then return end
            local s = calc.expr:gsub(',', '.')
            local fn = loadstring('return ' .. s)
            if fn then
                local ok, res = pcall(fn)
                if ok and type(res) == 'number' then
                    calc.result = res
                    calc.err    = false
                    calc.fresh  = true
                else
                    calc.err = true; calc.fresh = false
                end
            else
                calc.err = true; calc.fresh = false
            end
        end

        local function calc_back()
            if calc.fresh then calc.expr = tostring(calc.result or ''); calc.fresh = false end
            if calc.err   then calc.expr = ''; calc.err = false; return end
            calc.expr = calc.expr:sub(1, -2)
        end

        local function calc_clear()
            calc.expr = ''; calc.result = nil; calc.err = false; calc.fresh = false
        end

        -- \xc4\xe8\xf1\xef\xeb\xe5\xe9 \xe2\xfb\xf0\xe0\xe6\xe5\xed\xe8\xff
        local display_line1 = calc.expr ~= '' and _cyr5f(calc.expr) or ' '
        local display_line2
        if calc.err then
            display_line2 = _cyr5f('\xce\xf8\xe8\xe1\xea\xe0')
        elseif calc.result ~= nil then
            -- \xf4\xee\xf0\xec\xe0\xf2\xe8\xf0\xf3\xe5\xec \xf0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2 (3 \xe7\xed\xe0\xea\xe0 \xef\xee\xf1\xeb\xe5 \xe7\xe0\xef\xff\xf2\xee\xe9 = \xf2\xfb\xf1\xff\xf7\xe8)
            local r = calc.result
            if r == math.floor(r) then
                local _rs = tostring(math.floor(r)):reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
                display_line2 = _cyr5f('= ' .. _rs)
            else
                display_line2 = _cyr5f('= ' .. string.format('%.4f', r):gsub('0+$',''):gsub('%.$',''))
            end
        else
            display_line2 = ' '
        end

        local calc_h = imgui.GetWindowHeight() - 55*d
        if imgui.BeginChild('##calc_wrap', imgui.ImVec2(-1, calc_h), false) then
            _dpn1w()
            imgui.Spacing()

            -- \xd8\xe8\xf0\xe8\xed\xe0 \xee\xe1\xeb\xe0\xf1\xf2\xe8
            local cw = imgui.GetWindowContentRegionWidth()

            -- \xc4\xe8\xf1\xef\xeb\xe5\xe9
            imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.05, 0.05, 0.08, 1))
            imgui.PushStyleColor(imgui.Col.Border,  imgui.ImVec4(ar*0.6, ag*0.6, ab*0.6, 0.8))
            if imgui.BeginChild('##calc_display', imgui.ImVec2(-1, 70*d), true) then
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.6, 1))
                imgui.SetCursorPosY(imgui.GetCursorPosY() + 4*d)
                imgui.SetCursorPosX(8*d)
                imgui.Text(display_line1)
                imgui.PopStyleColor()
                local col2 = calc.err and imgui.ImVec4(1,0.35,0.35,1)
                          or (calc.fresh and imgui.ImVec4(0.3,0.95,0.5,1) or imgui.ImVec4(ar,ag,ab,1))
                imgui.PushStyleColor(imgui.Col.Text, col2)
                imgui.SetCursorPosX(8*d)
                imgui.Text(display_line2)
                imgui.PopStyleColor()
                imgui.EndChild()
            end
            imgui.PopStyleColor(2)
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()

            -- \xca\xed\xee\xef\xea\xe8: 4 \xea\xee\xeb\xee\xed\xea\xe8
            local gap   = 6*d
            local cols  = 4
            local btn_w = (cw - gap*(cols-1)) / cols
            local btn_h = 52*d

            local ac = imgui.ImVec4(ar, ag, ab, 1)
            local ac_dim = imgui.ImVec4(ar*0.6, ag*0.6, ab*0.6, 1)
            local red  = imgui.ImVec4(0.75, 0.18, 0.18, 1)
            local dark = imgui.ImVec4(0.12, 0.12, 0.16, 1)

            local function cbtn(label, on_click, col_btn, col_txt)
                col_btn = col_btn or dark
                col_txt = col_txt or imgui.ImVec4(0.9,0.9,0.9,1)
                imgui.PushStyleColor(imgui.Col.Button,        col_btn)
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(col_btn.x+0.1, col_btn.y+0.1, col_btn.z+0.1, 1))
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(col_btn.x+0.2, col_btn.y+0.2, col_btn.z+0.2, 1))
                imgui.PushStyleColor(imgui.Col.Text, col_txt)
                if imgui.Button(label .. '##cb', imgui.ImVec2(btn_w, btn_h)) then on_click() end
                imgui.PopStyleColor(4)
            end

            -- \xd1\xf2\xf0\xee\xea\xe0 1: C  \xd1\xf2\xf0\xee\xea\xe0\xf0  /  *
            cbtn(_ic_trash,                  calc_clear,                           red)
            imgui.SameLine(0, gap)
            cbtn(_ic_al .. ' del',       calc_back,                            imgui.ImVec4(0.3,0.15,0.1,1))
            imgui.SameLine(0, gap)
            cbtn('  /  ',          function() calc_append('/') end,      ac_dim, ac)
            imgui.SameLine(0, gap)
            cbtn(_ic_x,                     function() calc_append('*') end,      ac_dim, ac)
            imgui.Spacing()

            -- \xd1\xf2\xf0\xee\xea\xe0 2: 7 8 9 -
            cbtn('7', function() calc_append('7') end)
            imgui.SameLine(0, gap)
            cbtn('8', function() calc_append('8') end)
            imgui.SameLine(0, gap)
            cbtn('9', function() calc_append('9') end)
            imgui.SameLine(0, gap)
            cbtn(_ic_min,                     function() calc_append('-') end,      ac_dim, ac)
            imgui.Spacing()

            -- \xd1\xf2\xf0\xee\xea\xe0 3: 4 5 6 +
            cbtn('4', function() calc_append('4') end)
            imgui.SameLine(0, gap)
            cbtn('5', function() calc_append('5') end)
            imgui.SameLine(0, gap)
            cbtn('6', function() calc_append('6') end)
            imgui.SameLine(0, gap)
            cbtn('  +  ',            function() calc_append('+') end,      ac_dim, ac)
            imgui.Spacing()

            -- \xd1\xf2\xf0\xee\xea\xe0 4: 1 2 3 =
            cbtn('1', function() calc_append('1') end)
            imgui.SameLine(0, gap)
            cbtn('2', function() calc_append('2') end)
            imgui.SameLine(0, gap)
            cbtn('3', function() calc_append('3') end)
            imgui.SameLine(0, gap)
            local eq_c = imgui.ImVec4(ar*0.9, ag*0.9, ab*0.9, 1)
            cbtn('  =  ',          calc_eval,                            eq_c, imgui.ImVec4(0.04,0.04,0.03,1))
            imgui.Spacing()

            -- \xd1\xf2\xf0\xee\xea\xe0 5: 0 , % ( )
            cbtn('0', function() calc_append('0') end)
            imgui.SameLine(0, gap)
            cbtn(',', function() calc_append('.') end)
            imgui.SameLine(0, gap)
            cbtn('( )', function()
                -- \xf3\xec\xed\xfb\xe9 \xf1\xea\xee\xe1\xea\xe8: \xee\xf2\xea\xf0\xfb\xe2\xe0\xb5\xec \xe5\xf1\xeb\xe8 \xe1\xee\xeb\xfc\xf8\xe5 \xee\xf2\xea\xf0\xfb\xf2\xfb\xf5, \xe8\xed\xe0\xf7\xe5 \xe7\xe0\xea\xf0\xfb\xe2\xe0\xe5\xec
                local e = calc.fresh and '' or calc.expr
                local opens = 0; for _ in e:gmatch('%(') do opens=opens+1 end
                local closes = 0; for _ in e:gmatch('%)') do closes=closes+1 end
                if opens <= closes then calc_append('(') else calc_append(')') end
            end)
            imgui.SameLine(0, gap)
            cbtn('  %  ',                    function() calc_append('/100') end,   ac_dim, ac)

            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            -- \xca\xee\xef\xe8\xf0\xee\xe2\xe0\xf2\xfc \xf0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2
            if calc.result ~= nil and not calc.err then
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.55, 0.55, 0.6, 1))
                imgui.Text(_cyr5f('\xd0\xe5\xe7\xf3\xeb\xfc\xf2\xe0\xf2: '))
                imgui.SameLine(0, 4*d)
                imgui.PopStyleColor()
                local res_str = tostring(calc.result)
                imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), res_str)
                imgui.SameLine(0, 8*d)
                if imgui.Button(_ic_save .. '##calc_copy', imgui.ImVec2(0,0)) then
                    setClipboardText(res_str)
                end
            end
            imgui.EndChild()
        end
    end

        if _G.mh_tab == 6 then
            local vid_h = imgui.GetWindowHeight() - 55*d
            if imgui.BeginChild('##vid_wrap', imgui.ImVec2(-1, vid_h), false) then
                _dpn1w()  -- свайп
                local cw = imgui.GetWindowContentRegionWidth()
                local half = (cw - 8*d) * 0.5

                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f(' ЦВЕТА')); imgui.Separator(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Акцентный цвет:'))
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##acc', accent_color) then
                    settings.interface.accent_r=accent_color[0]; settings.interface.accent_g=accent_color[1]
                    settings.interface.accent_b=accent_color[2]; _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет текста:'))
                if not _G.vid_text_col then
                    _G.vid_text_col = imgui.new.float[3](
                        settings.interface.text_r or 0.93,
                        settings.interface.text_g or 0.88,
                        settings.interface.text_b or 0.78
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##textcol', _G.vid_text_col) then
                    settings.interface.text_r=_G.vid_text_col[0]
                    settings.interface.text_g=_G.vid_text_col[1]
                    settings.interface.text_b=_G.vid_text_col[2]
                    _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет фона окна:'))
                if not _G.vid_bg_col then
                    local bg = settings.interface.bg_brightness or 0.06
                    _G.vid_bg_col = imgui.new.float[3](bg, bg*0.95, bg*0.80)
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##bgcol', _G.vid_bg_col) then
                    settings.interface.bg_r = _G.vid_bg_col[0]
                    settings.interface.bg_g = _G.vid_bg_col[1]
                    settings.interface.bg_b = _G.vid_bg_col[2]
                    settings.interface.bg_brightness = _G.vid_bg_col[0]
                    _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет границы:'))
                if not _G.vid_border_col then
                    _G.vid_border_col = imgui.new.float[3](
                        settings.interface.border_r or (ar*0.70),
                        settings.interface.border_g or (ag*0.70),
                        settings.interface.border_b or 0
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##bordercol', _G.vid_border_col) then
                    settings.interface.border_r=_G.vid_border_col[0]
                    settings.interface.border_g=_G.vid_border_col[1]
                    settings.interface.border_b=_G.vid_border_col[2]
                    _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет продаж (оверлей):'))
                if not _G.vid_sell_col then
                    _G.vid_sell_col = imgui.new.float[3](
                        settings.overlay.sell_r or 0.3,
                        settings.overlay.sell_g or 0.9,
                        settings.overlay.sell_b or 0.3
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##sellcol', _G.vid_sell_col) then
                    settings.overlay.sell_r=_G.vid_sell_col[0]
                    settings.overlay.sell_g=_G.vid_sell_col[1]
                    settings.overlay.sell_b=_G.vid_sell_col[2]
                    _wfn7p()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет покупок (оверлей):'))
                if not _G.vid_buy_col then
                    _G.vid_buy_col = imgui.new.float[3](
                        settings.overlay.buy_r or 0.3,
                        settings.overlay.buy_g or 0.6,
                        settings.overlay.buy_b or 1.0
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##buycol', _G.vid_buy_col) then
                    settings.overlay.buy_r=_G.vid_buy_col[0]
                    settings.overlay.buy_g=_G.vid_buy_col[1]
                    settings.overlay.buy_b=_G.vid_buy_col[2]
                    _wfn7p()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет цен / акцента в таблицах:'))
                if not _G.vid_log_price_col then
                    _G.vid_log_price_col = imgui.new.float[3](
                        settings.overlay.log_price_r or 1.0,
                        settings.overlay.log_price_g or 0.85,
                        settings.overlay.log_price_b or 0.2
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##logpricecol', _G.vid_log_price_col) then
                    settings.overlay.log_price_r = _G.vid_log_price_col[0]
                    settings.overlay.log_price_g = _G.vid_log_price_col[1]
                    settings.overlay.log_price_b = _G.vid_log_price_col[2]
                    _G.vid_log_price_col = nil
                    _wfn7p()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет кнопок продажи:'))
                if not _G.vid_sell_btn_col then
                    _G.vid_sell_btn_col = imgui.new.float[3](
                        settings.interface.sell_btn_r or 0.10,
                        settings.interface.sell_btn_g or 0.45,
                        settings.interface.sell_btn_b or 0.10
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##sellbtncol', _G.vid_sell_btn_col) then
                    settings.interface.sell_btn_r = _G.vid_sell_btn_col[0]
                    settings.interface.sell_btn_g = _G.vid_sell_btn_col[1]
                    settings.interface.sell_btn_b = _G.vid_sell_btn_col[2]
                    _wfn7p()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цвет кнопок скупки:'))
                if not _G.vid_buy_btn_col then
                    _G.vid_buy_btn_col = imgui.new.float[3](
                        settings.interface.buy_btn_r or 0.00,
                        settings.interface.buy_btn_g or 0.28,
                        settings.interface.buy_btn_b or 0.50
                    )
                end
                imgui.PushItemWidth(-1)
                if imgui.ColorEdit3('##buybtncol', _G.vid_buy_btn_col) then
                    settings.interface.buy_btn_r = _G.vid_buy_btn_col[0]
                    settings.interface.buy_btn_g = _G.vid_buy_btn_col[1]
                    settings.interface.buy_btn_b = _G.vid_buy_btn_col[2]
                    _wfn7p()
                end
                imgui.PopItemWidth(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Цветовые пресеты:'))
                local color_presets = {
                    {_cyr5f('Оранж'), 1,.65,0},
                    {_cyr5f('Синий'), .2,.5,1},
                    {_cyr5f('Зелён'), .2,.8,.3},
                    {_cyr5f('Красн'), .9,.2,.2},
                    {_cyr5f('Фиол'), .6,.3,.9},
                    {_cyr5f('Белый'), .85,.85,.85},
                }
                local pw = (cw - 5*5*d) / #color_presets
                for pi, pr in ipairs(color_presets) do
                    if pi > 1 then imgui.SameLine(0,5*d) end
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(pr[2]*.5,pr[3]*.5,pr[4]*.5,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(pr[2]*.7,pr[3]*.7,pr[4]*.7,1))
                    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(pr[2],pr[3],pr[4],1))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(pr[2],pr[3],pr[4],1))
                    if imgui.Button(pr[1]..'##cpr'..pi, imgui.ImVec2(pw,24*d)) then
                        settings.interface.accent_r=pr[2]; settings.interface.accent_g=pr[3]; settings.interface.accent_b=pr[4]
                        accent_color[0]=pr[2]; accent_color[1]=pr[3]; accent_color[2]=pr[4]
                        _G.vid_border_col=nil; _G.vid_text_col=nil
                        _wfn7p(); _fwb3h()
                    end
                    imgui.PopStyleColor(4)
                end

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f(' ПАРАМЕТРЫ')); imgui.Separator(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Яркость фона:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if imgui.SliderFloat('##bg_v', sl.bg_bright, 0.01, 0.35, '%.2f') then
                    settings.interface.bg_brightness=sl.bg_bright[0]; _G.vid_bg_col=nil; _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth()

                imgui.TextDisabled(_cyr5f(' Прозрачность окна:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if imgui.SliderFloat('##alpha_v', sl.window_alpha, 0.3, 1.0, '%.2f') then
                    settings.interface.window_alpha=sl.window_alpha[0]; _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth()

                imgui.TextDisabled(_cyr5f(' Рруглость углов:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if not _G.sl_rounding then _G.sl_rounding = imgui.new.float[1](settings.interface.rounding or 4.0) end
                if imgui.SliderFloat('##rounding', _G.sl_rounding, 0.0, 12.0, '%.1f') then
                    settings.interface.rounding = _G.sl_rounding[0]; _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth()

                imgui.TextDisabled(_cyr5f(' Толщина рамки:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if not _G.sl_border then _G.sl_border = imgui.new.float[1](settings.interface.border_size or 1.0) end
                if imgui.SliderFloat('##bordersize', _G.sl_border, 0.0, 3.0, '%.1f') then
                    settings.interface.border_size = _G.sl_border[0]; _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth()

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f(' МАШТАБ (DPI)')); imgui.Separator(); imgui.Spacing()

                imgui.TextDisabled(_cyr5f('  Текущий: ' .. string.format('%.2f', settings.general.custom_dpi or 1.0)))
                imgui.PushItemWidth(-1)
                if imgui.SliderFloat('##dpi_sl', sl.dpi, 0.5, 3.0, '%.2f') then
                    settings.general.custom_dpi=sl.dpi[0]; _wfn7p(); _fwb3h()
                end
                imgui.PopItemWidth()

                imgui.Spacing()

                -- Быстрые кнопки масштаба
                imgui.TextDisabled(_cyr5f('  Быстрый масштаб:'))
                local _scale_btns = {
                    {_cyr5f('XS (0.6)'), 0.60},
                    {_cyr5f('S  (0.8)'), 0.80},
                    {_cyr5f('M  (1.0)'), 1.00},
                    {_cyr5f('L  (1.2)'), 1.20},
                    {_cyr5f('XL (1.5)'), 1.50},
                }
                local _sbw = (imgui.GetWindowContentRegionWidth() - 4*d*4) / #_scale_btns
                for _si, _sb in ipairs(_scale_btns) do
                    if _si > 1 then imgui.SameLine(0, 4*d) end
                    local _cur_dpi = settings.general.custom_dpi or 1.0
                    local _is_cur = math.abs(_cur_dpi - _sb[2]) < 0.05
                    local _bc = _is_cur
                        and imgui.ImVec4(ar*0.6, ag*0.6, ab*0.2, 1)
                        or  imgui.ImVec4(0.12, 0.12, 0.12, 1)
                    imgui.PushStyleColor(imgui.Col.Button, _bc)
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(ar*0.3, ag*0.3, ab*0.1, 1))
                    if imgui.Button(_sb[1]..'##scl'..tostring(_sb[2]), imgui.ImVec2(_sbw, 26*d)) then
                        settings.general.custom_dpi = _sb[2]
                        sl.dpi[0] = _sb[2]
                        _G._mh_win_reset = true
                        _wfn7p(); _fwb3h()
                        sampAddChatMessage('[MH] {aaffaa}Масштаб: '.._sb[1], 0xffffff)
                    end
                    imgui.PopStyleColor(2)
                end
                imgui.Spacing()

                -- Кнопка сброса: ставит DPI=1.0 и центрирует окно
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10,0.22,0.12,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15,0.35,0.18,1))
                if imgui.Button(_cyr5f('Сбросить масштаб по умолчанию (1.0)##win_reset'), imgui.ImVec2(-1, 26*d)) then
                    settings.general.custom_dpi = 1.0
                    sl.dpi[0] = 1.0
                    _G._mh_win_reset = true
                    _wfn7p(); _fwb3h()
                    sampAddChatMessage('[MH] {aaffaa}Масштаб сброшен до 1.0', 0xffffff)
                end
                imgui.PopStyleColor(2)

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f(' РАЗМЕР ОКНА')); imgui.Separator(); imgui.Spacing()
                -- Ширина окна
                if not _G.sl_win_w then
                    local _sw = settings.mh_win
                    _G.sl_win_w = imgui.new.float[1]((_sw and _sw.w and _sw.w/d > 200) and _sw.w/d or 900)
                end
                imgui.TextDisabled(_cyr5f(' Ширина:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if imgui.SliderFloat('##win_w', _G.sl_win_w, 400, 1200, '%.0f') then
                    local _sw = settings.mh_win or {}
                    _sw.w = _G.sl_win_w[0] * d
                    if not _sw.h then _sw.h = 520*d end
                    if not _sw.x then _sw.x = sizeX/2 - _sw.w/2 end
                    if not _sw.y then _sw.y = sizeY/2 - _sw.h/2 end
                    settings.mh_win = _sw
                    _G._mh_win_reset = true; _wfn7p()
                end
                imgui.PopItemWidth()
                -- Высота окна
                if not _G.sl_win_h then
                    local _sw = settings.mh_win
                    _G.sl_win_h = imgui.new.float[1]((_sw and _sw.h and _sw.h/d > 150) and _sw.h/d or 520)
                end
                imgui.TextDisabled(_cyr5f(' Высота:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if imgui.SliderFloat('##win_h', _G.sl_win_h, 300, 900, '%.0f') then
                    local _sw = settings.mh_win or {}
                    _sw.h = _G.sl_win_h[0] * d
                    if not _sw.w then _sw.w = 900*d end
                    if not _sw.x then _sw.x = sizeX/2 - _sw.w/2 end
                    if not _sw.y then _sw.y = sizeY/2 - _sw.h/2 end
                    settings.mh_win = _sw
                    _G._mh_win_reset = true; _wfn7p()
                end
                imgui.PopItemWidth()
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                imgui.TextColored(imgui.ImVec4(ar, ag, ab, 1), _cyr5f(' ПЛАВАЮЩИЙ ЛОГ')); imgui.Separator(); imgui.Spacing()

                local ov_en = imgui.new.bool(settings.overlay and settings.overlay.enabled or false)
                if imgui.Checkbox(_cyr5f('Чуть лог включён##ovtog'), ov_en) then
                    if not settings.overlay then settings.overlay = {} end
                    settings.overlay.enabled = ov_en[0]; _wfn7p()
                end
                imgui.Spacing()

                imgui.TextDisabled(_cyr5f(' Строк в оверлее:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if not _G.sl_ovlines then _G.sl_ovlines = imgui.new.float[1](settings.overlay and settings.overlay.lines or 8) end
                if imgui.SliderFloat('##ovlines', _G.sl_ovlines, 3, 20, '%.0f') then
                    if not settings.overlay then settings.overlay = {} end
                    settings.overlay.lines = math.floor(_G.sl_ovlines[0]); _wfn7p()
                end
                imgui.PopItemWidth()

                imgui.TextDisabled(_cyr5f(' Прозрачность оверлея:')); imgui.SameLine(); imgui.PushItemWidth(-1)
                if not _G.sl_ovalpha then _G.sl_ovalpha = imgui.new.float[1](settings.overlay and settings.overlay.alpha or 0.6) end
                if imgui.SliderFloat('##ovalpha', _G.sl_ovalpha, 0.1, 1.0, '%.2f') then
                    if not settings.overlay then settings.overlay = {} end
                    settings.overlay.alpha = _G.sl_ovalpha[0]; _wfn7p()
                end
                imgui.PopItemWidth()

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.4,0.1,0.05,1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.6,0.15,0.08,1))
                if imgui.Button(_cyr5f('Сбросить дизайн##resettheme'), imgui.ImVec2(-1, 28*d)) then
                    settings.interface.accent_r=1; settings.interface.accent_g=0.65; settings.interface.accent_b=0
                    settings.interface.bg_brightness=0.06; settings.interface.window_alpha=0.98
                    settings.interface.rounding=4; settings.interface.border_size=1
                    settings.interface.text_r=nil; settings.interface.text_g=nil; settings.interface.text_b=nil
                    settings.interface.border_r=nil; settings.interface.border_g=nil; settings.interface.border_b=nil
                    accent_color[0]=1; accent_color[1]=0.65; accent_color[2]=0
                    _G.vid_text_col=nil; _G.vid_bg_col=nil; _G.vid_border_col=nil
                    _G.sl_rounding=nil; _G.sl_border=nil
                    _wfn7p(); _fwb3h()
                end
                imgui.PopStyleColor(2)

                imgui.EndChild()
            end
        end
        if _G.mh_tab == 7 then
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), u8' Авто-функции'); imgui.Separator()
            local funcs_mh = {
                {u8'Авто /vr реклама',    'auto_vr_confirm'},
                {u8'Авто /ad подтв.',      'auto_ad_confirm'},
                }
            local cw_p = imgui.GetWindowContentRegionWidth()
            local col_w_p = (cw_p - 8*d) / 2
            imgui.Columns(2, '##mhfuncs', false)
            imgui.SetColumnWidth(0, col_w_p); imgui.SetColumnWidth(1, col_w_p)
            for fi, f in ipairs(funcs_mh) do
                if fi > 1 then imgui.NextColumn() end
                if not _G['_mhfncb'..fi] then _G['_mhfncb'..fi] = imgui.new.bool(false) end
                _G['_mhfncb'..fi][0] = settings.general and settings.general[f[2]] or false
                if imgui.Checkbox(f[1]..'##mhfn'..fi, _G['_mhfncb'..fi]) then
                    if settings.general then
                        settings.general[f[2]] = (_G['_mhfncb'..fi][0] == true)
                        _wfn7p()
                    end
                end
            end
            imgui.Columns(1)
            if settings.general and settings.general.auto_ad_confirm then
                imgui.Spacing()
                imgui.TextDisabled(u8'  Станция /ad:'); imgui.SameLine()
                local st_names = {u8'Los Santos##adst', u8'Las Venturas##adst', u8'San Fierro##adst'}
                local st_idx = settings.general.auto_ad_station_idx or 2
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(bb_r, bb_g, bb_b, 1))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(bb_r*1.35, bb_g*1.35, bb_b*1.3, 1))
                if imgui.SmallButton(st_names[st_idx + 1]) then
                    settings.general.auto_ad_station_idx = (st_idx + 1) % 3; _wfn7p()
                end
                imgui.SameLine(0, 12*d)
                local ad_type_lbl = (settings.general.auto_ad_type or 0) == 0 and u8'Обычное##adtype' or u8'VIP##adtype'
                if imgui.SmallButton(ad_type_lbl) then
                    settings.general.auto_ad_type = (settings.general.auto_ad_type or 0) == 0 and 1 or 0; _wfn7p()
                end
                imgui.PopStyleColor(2)
            end
            imgui.Separator(); imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), u8' Шаблоны автопиара')
            imgui.SameLine(); imgui.TextDisabled(u8'  /mhp [номер] — ручной запуск')
            imgui.Separator()
            local piar_h = imgui.GetWindowHeight() - 200*d
            if imgui.BeginChild('##mhpiars', imgui.ImVec2(-1, piar_h - 34*d), true) then
                _dpn1w()  -- swipe scroll
                local col_dot  = 18*d
                local col_info = cw_p - col_dot - 340*d
                if col_info < 80*d then col_info = 80*d end
                local col_btns = 340*d
                imgui.Columns(3, '##mhphdr', false)
                imgui.SetColumnWidth(0, col_dot); imgui.SetColumnWidth(1, col_info); imgui.SetColumnWidth(2, col_btns)
                imgui.NextColumn()
                imgui.TextDisabled(u8'Шаблон'); imgui.NextColumn()
                imgui.TextDisabled(u8'Действия'); imgui.NextColumn()
                imgui.Columns(1); imgui.Separator()
                for i, t in ipairs(settings.piar_templates or {}) do
                    imgui.Columns(3, '##mhpr'..i, false)
                    imgui.SetColumnWidth(0, col_dot); imgui.SetColumnWidth(1, col_info); imgui.SetColumnWidth(2, col_btns)
                    if t.auto then imgui.TextColored(imgui.ImVec4(0.2,0.85,0.2,1), u8'•')
                    else           imgui.TextColored(imgui.ImVec4(0.85,0.2,0.2,1), u8'•') end
                    imgui.NextColumn()
                    imgui.Text(_cyr5f(' ' .. (t.name or '')))
                    imgui.TextDisabled(_cyr5f('  ' .. #(t.lines or {}) .. ' стр | ' .. (t.waiting or 1.5) .. 'с'))
                    if t.auto then
                        local elapsed = os.time() - (t.last_time or 0)
                        local interval = t._next_interval or t.auto_interval or 300
                        local left = math.max(0, interval - elapsed)
                        local rng_str = (t.auto_interval_max or 0) > (t.auto_interval or 300)
                            and (' [ранд ' .. (t.auto_interval or 300) .. '-' .. t.auto_interval_max .. 'с]') or ''
                        imgui.TextDisabled(_cyr5f('  Очередь: ' .. left .. 'с / ' .. interval .. 'с' .. rng_str))
                    end
                    imgui.NextColumn()
                    local bw3 = (col_btns - 12*d) / 3
                    if imgui.Button(_ic_play..' '..u8'Пуск##mhp'..i, imgui.ImVec2(bw3, 0)) then _xjg7y(i) end
                    imgui.SameLine(0,4)
                    if t.auto then
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(sb_r, sb_g, sb_b, 1))
                        if imgui.Button(_ic_circs..' '..u8'Авто:ВКЛ##mha'..i, imgui.ImVec2(bw3, 0)) then t.auto=false; _wfn7p() end
                        imgui.PopStyleColor()
                    else
                        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.4,0.15,0.15,1))
                        if imgui.Button(_ic_play..' '..u8'Авто:ВЫКЛ##mha'..i, imgui.ImVec2(bw3, 0)) then t.auto=true; t.last_time=os.time(); t._next_interval=nil; _wfn7p() end
                        imgui.PopStyleColor()
                    end
                    imgui.SameLine(0,4)
                    if imgui.Button(_ic_pen..'##mhe'..i, imgui.ImVec2(bw3, 0)) then
                        _G.mh_piar_edit_index = i; _G.mh_piar_edit_open = true
                    end
                    imgui.NextColumn(); imgui.Columns(1); imgui.Separator()
                end
                imgui.EndChild()
            end
            if imgui.Button(_ic_circp..' '..u8'Шаблон##mhpadd', imgui.ImVec2(-1, 0)) then
                table.insert(settings.piar_templates, {name='Новый', enable=true, auto=false,
                    auto_interval=300, auto_interval_max=0, waiting=1.5, last_time=0,
                    lines={'/s Текст'}})
                _wfn7p()
                _G.mh_piar_edit_index = #settings.piar_templates
                _G.mh_piar_edit_open = true
            end
        end -- end Пиар##piartab

        if _G.mh_tab == 9 then
            local about_h = imgui.GetWindowHeight() - 80*d
            if imgui.BeginChild('##about_wrap', imgui.ImVec2(-1, about_h), false) then
                _ltz8m()
                imgui.Spacing()
                imgui.SetCursorPosX((imgui.GetWindowContentRegionWidth() - imgui.CalcTextSize(u8'Market Helper').x) / 2)
                imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), u8'Market Helper')
                imgui.SetCursorPosX((imgui.GetWindowContentRegionWidth() - imgui.CalcTextSize('v' .. thisScript().version).x) / 2)
                imgui.TextDisabled('v' .. thisScript().version)
                imgui.Spacing()
                -- update status row
                do
                    local _us = _G._mh_upd_state
                    local _ul = _G._mh_upd_latest
                    imgui.SetCursorPosX(16*d)
                    if _us == 'ok' then
                        imgui.TextColored(imgui.ImVec4(0.3,0.95,0.3,1), _ic_chk..' ')
                        imgui.SameLine(0,2*d)
                        imgui.TextColored(imgui.ImVec4(0.3,0.95,0.3,1), _cyr5f('\xc0\xea\xf2\xf3\xe0\xeb\xfc\xed\xe0\xff \xe2\xe5\xf0\xf1\xe8\xff'))
                    elseif _us == 'outdated' then
                        imgui.TextColored(imgui.ImVec4(1,0.75,0,1), _ic_up..' ')
                        imgui.SameLine(0,2*d)
                        imgui.TextColored(imgui.ImVec4(1,0.75,0,1), _cyr5f('\xc4\xee\xf1\xf2\xf3\xef\xed\xee v'..((_ul) or '?')))
                        imgui.SameLine(0,8*d)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.25,0.50,0.08,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.35,0.70,0.12,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(0.8,1,0.5,1))
                        if imgui.SmallButton(_ic_up_RIGHT_FROM_SQUARE..' '.._cyr5f('\xd1\xea\xe0\xf7\xe0\xf2\xfc##mh_dl_btn')) then
                            if _cvh6z() then
                                pcall(gta._Z12AND_OpenLinkPKc, 'https://t.me/shinikmod')
                            else
                                os.execute('start https://t.me/shinikmod')
                            end
                        end
                        imgui.PopStyleColor(3)
                    elseif _us == 'tampered' then
                        imgui.TextColored(imgui.ImVec4(1,0.3,0.3,1), _ic_shield..' ')
                        imgui.SameLine(0,2*d)
                        imgui.TextColored(imgui.ImVec4(1,0.3,0.3,1), _cyr5f('\xd4\xe0\xe9\xeb \xe8\xe7\xec\xe5\xed\xb8\xed!'))
                        imgui.SameLine(0,6*d)
                        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0,0.40,0.75,1))
                        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0,0.55,1.0,1))
                        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1,1,1,1))
                        if imgui.SmallButton(_ic_up_RIGHT_FROM_SQUARE..' t.me/shinikmod##mh_tam_btn') then
                            if _cvh6z() then
                                pcall(gta._Z12AND_OpenLinkPKc, 'https://t.me/shinikmod')
                            else
                                os.execute('start https://t.me/shinikmod')
                            end
                        end
                        imgui.PopStyleColor(3)
                    elseif _us == 'checking' then
                        imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), _cyr5f('\xcf\xf0\xee\xe2\xe5\xf0\xea\xe0...'))
                    else
                        imgui.TextDisabled(_cyr5f('v' .. (thisScript().version or '?')))
                    end
                    imgui.SameLine(0,10*d)
                    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10,0.10,0.14,1))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18,0.18,0.26,1))
                    if imgui.SmallButton(_ic_rot..'##mh_upd_btn') then
                        _mh_check_update(true)
                    end
                    if imgui.IsItemHovered() then imgui.SetTooltip(_cyr5f('\xcf\xf0\xee\xe2\xe5\xf0\xe8\xf2\xfc \xee\xe1\xed\xee\xe2\xeb\xe5\xed\xe8\xe5')) end
                    imgui.PopStyleColor(2)
                end
                imgui.Separator()
                imgui.Spacing()

                imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), u8' \xc0\xe2\xf2\xee\xf0')
                imgui.Separator()
                imgui.Spacing()
                imgui.SetCursorPosX(16*d)
                imgui.Text(u8'Shinik_Pupckin')
                imgui.Spacing()

                imgui.TextColored(imgui.ImVec4(ar,ag,ab,1), u8' \xd1\xf1\xfb\xeb\xea\xe8')
                imgui.Separator()
                imgui.Spacing()

                imgui.SetCursorPosX(16*d)
                imgui.TextDisabled(u8'\xd2\xe5\xeb\xe5\xe3\xf0\xe0\xec \xea\xe0\xed\xe0\xeb:')
                imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(0.3,0.7,1.0,1), 'https://t.me/shinikmod')
                if imgui.IsItemClicked() then
                    if _cvh6z() then
                        pcall(gta._Z12AND_OpenLinkPKc, 'https://t.me/shinikmod')
                    else
                        os.execute('start https://t.me/shinikmod')
                    end
                end
                if imgui.IsItemHovered() then imgui.SetMouseCursor(imgui.MouseCursor.Hand) end

                imgui.Spacing()

                imgui.SetCursorPosX(16*d)
                imgui.TextDisabled(u8'\xc0\xe2\xf2\xee\xf0 (\xeb\xe8\xf7\xea\xe0):')
                imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(0.3,0.7,1.0,1), 'https://t.me/shinik_1')
                if imgui.IsItemClicked() then
                    if _cvh6z() then
                        pcall(gta._Z12AND_OpenLinkPKc, 'https://t.me/shinik_1')
                    else
                        os.execute('start https://t.me/shinik_1')
                    end
                end
                if imgui.IsItemHovered() then imgui.SetMouseCursor(imgui.MouseCursor.Hand) end

                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                imgui.SetCursorPosX(16*d)
                imgui.TextDisabled(u8'\xc1\xe0\xe3\xe8 \xe8 \xef\xf0\xe5\xe4\xeb\xee\xe6\xe5\xed\xe8\xff \x97 \xe2 \xf2\xe5\xeb\xe5\xe3\xf0\xe0\xec \xea\xe0\xed\xe0\xeb')

                imgui.EndChild()
            end
        end

    imgui.EndChild()

        imgui.EndChild()
    end -- ##mh_content
    imgui.PopStyleColor()
    imgui.End()
end)

imgui.OnFrame(
    function() return _G.mkt_detail_open == true end,
    function()
        local d  = settings.general.custom_dpi * 0.73
        local sw, sh = imgui.GetIO().DisplaySize.x, imgui.GetIO().DisplaySize.y
        -- Фиксированный размер: чуть меньше экрана, не пересчитывается каждый кадр
        local pop_w = math.min(sw - 16, 853*d)
        local pop_h = math.min(sh - 20, sh * 0.88)
        imgui.SetNextWindowSize(imgui.ImVec2(pop_w, pop_h), imgui.Cond.Once)
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.Once, imgui.ImVec2(0.5, 0.5))
        imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = true
        local closed = imgui.new.bool(true)
        local _wflags = imgui.WindowFlags.NoCollapse
        if imgui.Begin(u8'\xd1\xf2\xe0\xf2\xe8\xf1\xf2\xe8\xea\xe0 \xf2\xee\xe2\xe0\xf0\xe0##dtlpop', closed, _wflags) then
            -- Один свайп: без _ltz8m() в основном окне
            local _btn_h   = 34*d
            local _btn_gap = 3*d
            local _sep_h   = 6*d   -- separator + padding
            -- Контент: всё пространство кроме полоски кнопок
            local _total_h  = imgui.GetWindowHeight()
            local _title_h  = imgui.GetCursorPosY()  -- после Begin = смещение = высота заголовка
            local _content_h = _total_h - _title_h - _btn_h - _sep_h - 20*d
            if imgui.BeginChild('##dtl_scroll', imgui.ImVec2(-1, _content_h), false) then
                _dpn1w()  -- свайп только внутри этого child
                if _G.mkt_detail_item then
                    _hmc6p(_G.mkt_detail_item, _G.mkt_detail_src)
                end
                imgui.EndChild()
            end
            -- Кнопки тегов + Закрыть (приклеены к низу)
            imgui.Separator()
            local _cw4 = (imgui.GetWindowContentRegionWidth() - _btn_gap * 3) / 4
            if _G.mkt_detail_item then
                local _dtag = mh_get_item_tag(_G.mkt_detail_item)
                local _wc = _dtag=='watch' and imgui.ImVec4(0.15,0.5,0.85,1) or imgui.ImVec4(0.12,0.28,0.48,1)
                imgui.PushStyleColor(imgui.Col.Button, _wc)
                if imgui.Button(_ic_eye..' '.._cyr5f('\xd1\xec\xee\xf2\xf0\xe5\xf2\xfc##dtw'), imgui.ImVec2(_cw4, _btn_h)) then
                    mh_set_item_tag(_G.mkt_detail_item, _dtag=='watch' and nil or 'watch')
                end
                imgui.PopStyleColor()
                imgui.SameLine(0, _btn_gap)
                local _sc = _dtag=='skip' and imgui.ImVec4(0.45,0.12,0.12,1) or imgui.ImVec4(0.28,0.08,0.08,1)
                imgui.PushStyleColor(imgui.Col.Button, _sc)
                if imgui.Button(_ic_ban..' '.._cyr5f('\xcd\xe5 \xe1\xf0\xe0\xf2\xfc##dts'), imgui.ImVec2(_cw4, _btn_h)) then
                    mh_set_item_tag(_G.mkt_detail_item, _dtag=='skip' and nil or 'skip')
                end
                imgui.PopStyleColor()
                imgui.SameLine(0, _btn_gap)
                local _fc = _dtag=='fav' and imgui.ImVec4(0.55,0.42,0.04,1) or imgui.ImVec4(0.30,0.22,0.04,1)
                imgui.PushStyleColor(imgui.Col.Button, _fc)
                if imgui.Button(_ic_star..' '.._cyr5f('\xc8\xe7\xe1\xf0\xe0\xed\xed\xee\xe5##dtf'), imgui.ImVec2(_cw4, _btn_h)) then
                    mh_set_item_tag(_G.mkt_detail_item, _dtag=='fav' and nil or 'fav')
                end
                imgui.PopStyleColor()
                imgui.SameLine(0, _btn_gap)
            end
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.32,0.08,0.08,1))
            if imgui.Button(_ic_x..' '..u8'\xc7\xe0\xea\xf0\xfb\xf2\xfc##dtlclose', imgui.ImVec2(-1, _btn_h)) then
                _G.mkt_detail_open = false
            end
            imgui.PopStyleColor()
        end
        if not closed[0] then _G.mkt_detail_open = false end
        imgui.End()
    end
)

imgui.OnFrame(
    function() return settings.overlay and settings.overlay.enabled == true end,
    function()
        local d = settings.general.custom_dpi or 1
        local sw, sh = imgui.GetIO().DisplaySize.x, imgui.GetIO().DisplaySize.y
        local px = settings.overlay.pos_x  or 10
        local py = settings.overlay.pos_y  or 200
        local pw = settings.overlay.width  or 420
        local ph = settings.overlay.height or 180
        if not _G.ov_initialized then
            imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(pw, ph), imgui.Cond.Always)
            _G.ov_initialized = true
        else
            imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Once)
            imgui.SetNextWindowSize(imgui.ImVec2(pw, ph), imgui.Cond.Once)
        end
        imgui.SetNextWindowBgAlpha(settings.overlay.alpha or 0.6)
        local s = imgui.GetStyle()
        local old_pad = s.WindowPadding
        s.WindowPadding = imgui.ImVec2(4*d, 4*d)
        imgui.Begin('##mh_overlay_log', imgui.new.bool(true),
            imgui.WindowFlags.NoTitleBar +
            imgui.WindowFlags.NoCollapse +
            imgui.WindowFlags.NoScrollbar)
        _ltz8m()
        -- overlay day filter (управление в настройках, кнопки скрыты)
        if not _G.ov_day_filter then
            _G.ov_day_filter = (settings.overlay and settings.overlay.day_filter) or 1
        end
        local function _ov_day_ok(le_dt)
            if _G.ov_day_filter == 0 then return true end
            if not le_dt or le_dt == '' then return false end
            local now = os.time()
            local t = os.date('*t', now)
            local d_day = string.format('%02d.%02d', t.day, t.month)
            local e_day = le_dt:sub(1,5)
            if _G.ov_day_filter == 1 then
                return e_day == d_day
            elseif _G.ov_day_filter == 2 then
                local e_d = tonumber(le_dt:sub(1,2)) or 0
                local e_m = tonumber(le_dt:sub(4,5)) or 0
                local e_ts = os.time({year=t.year, month=e_m, day=e_d, hour=0, min=0, sec=0})
                if e_ts > now then e_ts = os.time({year=t.year-1, month=e_m, day=e_d, hour=0, min=0, sec=0}) end
                return (now - e_ts) <= (7 * 86400)
            elseif _G.ov_day_filter == 3 then
                local e_d = tonumber(le_dt:sub(1,2)) or 0
                local e_m = tonumber(le_dt:sub(4,5)) or 0
                local e_ts = os.time({year=t.year, month=e_m, day=e_d, hour=0, min=0, sec=0})
                if e_ts > now then e_ts = os.time({year=t.year-1, month=e_m, day=e_d, hour=0, min=0, sec=0}) end
                return (now - e_ts) <= (30 * 86400)
            end
            return true
        end
        local lines = settings.overlay.lines or 8
        local ov_entries = {}
        for i = #fh_mkt_log, 1, -1 do
            local e = fh_mkt_log[i]
            if e and e.vc ~= true and _ov_day_ok(e.dt) then
                table.insert(ov_entries, e)
            end
            if #ov_entries >= lines then break end
        end
        -- Кэш суммы overlay: пересчитываем только если лог изменился или сменился фильтр
        local _ov_log_ver = tostring(#fh_mkt_log) .. '|' .. tostring(_G.ov_day_filter or 1)
        if _G._ov_sum_ver ~= _ov_log_ver then
            _G._ov_sum_ver = _ov_log_ver
            local _ss, _bs, _sc, _bc = 0, 0, 0, 0
            for i = 1, #fh_mkt_log do
                local e_sum = fh_mkt_log[i]
                if e_sum and e_sum.vc ~= true and _ov_day_ok(e_sum.dt) then
                    if fh_is_my_sell(e_sum) then
                        _ss = _ss + (e_sum.price or 0) * (e_sum.qty or 1)
                        _sc = _sc + (e_sum.qty or 1)
                    else
                        _bs = _bs + (e_sum.price or 0) * (e_sum.qty or 1)
                        _bc = _bc + (e_sum.qty or 1)
                    end
                end
            end
            _G._ov_sum_cache = {ss=_ss, bs=_bs, sc=_sc, bc=_bc}
        end
        local _ovc = _G._ov_sum_cache or {ss=0,bs=0,sc=0,bc=0}
        local sell_sum, buy_sum, sell_cnt, buy_cnt = _ovc.ss, _ovc.bs, _ovc.sc, _ovc.bc
        local total = #ov_entries
        local start = 1
        for i = start, total do
            local e = ov_entries[i]
            if e then
                local r, g, b_c
                if fh_is_my_sell(e) then
                    r = settings.overlay.sell_r or 0.3
                    g = settings.overlay.sell_g or 0.9
                    b_c = settings.overlay.sell_b or 0.3
                else
                    r = settings.overlay.buy_r or 0.3
                    g = settings.overlay.buy_g or 0.6
                    b_c = settings.overlay.buy_b or 1.0
                end
                local line = (e.dt or '') .. ' ' .. (e.item or '') .. ' x' .. (e.qty or 1) .. ' $' .. _kcr3y((e.price or 0) * (e.qty or 1))
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(r, g, b_c, 1))
                imgui.TextWrapped(_cyr5f(line))
                imgui.PopStyleColor()
            end
        end
        imgui.Separator()
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.3,0.9,0.3,1))
        imgui.TextWrapped(_ic_up..' '.._cyr5f(sell_cnt..' \xf8\xf2.')..'  '.._ic_coin..' '.._cyr5f(_kcr3y(sell_sum)))
        imgui.PopStyleColor()
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.3,0.6,1.0,1))
        imgui.TextWrapped(_ic_dn..' '.._cyr5f(buy_cnt..' \xf8\xf2.')..'  '.._ic_coin..' '.._cyr5f(_kcr3y(buy_sum)))
        imgui.PopStyleColor()
        local np = imgui.GetWindowPos()
        local ns = imgui.GetWindowSize()
        local pos_changed = np.x ~= settings.overlay.pos_x or np.y ~= settings.overlay.pos_y
        local size_changed = ns.x ~= settings.overlay.width or ns.y ~= settings.overlay.height
        if (pos_changed or size_changed) and not imgui.IsWindowFocused() then
            settings.overlay.pos_x = np.x; settings.overlay.pos_y = np.y
            settings.overlay.width = ns.x; settings.overlay.height = ns.y
            _wfn7p()
        end
        s.WindowPadding = old_pad
        imgui.End()
    end
)

imgui.OnFrame(
    function() return _G.mkt_auto_detail_open == true end,
    function()
        local d  = settings.general.custom_dpi
        local ar2 = settings.interface.accent_r or 1
        local ag2 = settings.interface.accent_g or .65
        local ab2 = settings.interface.accent_b or 0.0
        local sb_r = settings.interface.sell_btn_r or 0.10
        local sb_g = settings.interface.sell_btn_g or 0.45
        local sb_b = settings.interface.sell_btn_b or 0.10
        local bb_r = settings.interface.buy_btn_r  or 0.00
        local bb_g = settings.interface.buy_btn_g  or 0.28
        local bb_b = settings.interface.buy_btn_b  or 0.50
        local ac2 = imgui.ImVec4(ar2, ag2, ab2, 1)
        local lp_r = settings.overlay and settings.overlay.log_price_r or 1.0
        local lp_g = settings.overlay and settings.overlay.log_price_g or 0.85
        local lp_b = settings.overlay and settings.overlay.log_price_b or 0.2
        local sw, sh = imgui.GetIO().DisplaySize.x, imgui.GetIO().DisplaySize.y
        local pop_w = math.min(sw - 20*d, 510*d)
        local pop_h = math.min(sh - 40*d, 560*d)
        imgui.SetNextWindowSize(imgui.ImVec2(pop_w, pop_h), imgui.Cond.Always)
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        local closed2 = imgui.new.bool(true)
        if imgui.Begin(u8'Статистика авто##autopop', closed2,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
            _ltz8m()
            local nm = _G.mkt_auto_detail_item or ''
            local e  = fh_mkt_auto[nm]
            local cp_hist = e and e.cp_hist
            imgui.TextColored(ac2, _cyr5f('Авто: ' .. nm))
            if e and e.date then
                imgui.SameLine()
                imgui.TextDisabled(_cyr5f('  обновлено ' .. e.date))
            end
            imgui.Separator(); imgui.Spacing()
            if e then
                if cp_hist and #cp_hist > 0 then
                    local s7  = _mjg5t(cp_hist, 7)
                    local s30 = _mjg5t(cp_hist, 30)
                    local trend = _xvn2w(cp_hist)
                    local tc_tr = _pdf8k(trend)
                    local _trend_icon = type(trend)=='table' and trend.icon or _ic_min
                    local _trend_text = type(trend)=='table' and trend.text or ''
                    imgui.TextColored(ac2, u8'Статистика (мировой рынок)')
                    imgui.Spacing()
                    imgui.Columns(3, '##adtl2', false)
                    local _cw_a2 = imgui.GetWindowContentRegionWidth()
                    imgui.SetColumnWidth(0, 62*d)
                    imgui.SetColumnWidth(1, math.floor((_cw_a2-62*d)*0.58))
                    imgui.SetColumnWidth(2, math.floor((_cw_a2-62*d)*0.42))
                    local hc2 = imgui.ImVec4(0.6,0.6,0.6,1)
                    imgui.TextColored(hc2, u8''); imgui.NextColumn()
                    imgui.TextColored(hc2, u8'Ср. цена $'); imgui.NextColumn()
                    imgui.TextColored(hc2, u8'Сделок'); imgui.NextColumn()
                    local today_h = cp_hist[1]
                    imgui.TextColored(imgui.ImVec4(0.4,0.95,1,1), u8'Сегодня'); imgui.NextColumn()
                    if today_h and today_h.price and today_h.price > 0 then
                        imgui.TextColored(imgui.ImVec4(0.4,0.95,1,1), _cyr5f('$'.._kcr3y(today_h.price))); imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(1,1,1,0.8), _cyr5f(tostring(today_h.qty or 0))); imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(1,1,1,0.4), _cyr5f(today_h.dt or '')); imgui.NextColumn()
                    else
                        for _=1,3 do imgui.TextDisabled(u8'—'); imgui.NextColumn() end
                    end
                    imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), u8'7дн.'); imgui.NextColumn()
                    if s7 then
                        imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), _cyr5f('$'.._kcr3y(s7.avg))); imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(1,1,1,0.8), _cyr5f(_kcr3y(s7.qty))); imgui.NextColumn()
                        else for _=1,2 do imgui.TextDisabled(u8'—'); imgui.NextColumn() end end
                    imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), u8'30дн.'); imgui.NextColumn()
                    if s30 then
                        imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f('$'.._kcr3y(s30.avg))); imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(1,1,1,0.8), _cyr5f(_kcr3y(s30.qty))); imgui.NextColumn()
                    else for _=1,2 do imgui.TextDisabled(u8'—'); imgui.NextColumn() end end
                    imgui.Columns(1); imgui.Spacing()
                    imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), u8'Тренд: ')
                    imgui.SameLine(); imgui.TextColored(tc_tr, _trend_icon..' '.._cyr5f(_trend_text))
                    imgui.Spacing()
                    local plot_n = math.min(#cp_hist, 30)
                    local p_min_v, p_max_v = math.huge, -math.huge
                    local plot_tbl = {}
                    for i = plot_n, 1, -1 do
                        local pv = cp_hist[i].price or 0
                        table.insert(plot_tbl, pv)
                        if pv < p_min_v then p_min_v = pv end
                        if pv > p_max_v then p_max_v = pv end
                    end
                    if #plot_tbl > 1 then
                        local plot_arr = imgui.new.float[#plot_tbl]()
                        for i2, v in ipairs(plot_tbl) do plot_arr[i2-1] = v end
                        local lbl = _cyr5f('Мин: $'.._zhb9s(p_min_v)..'  Макс: $'.._zhb9s(p_max_v))
                        imgui.PlotLines('##autoplot', plot_arr, #plot_tbl, 0, lbl, p_min_v*0.98, p_max_v*1.02,
                            imgui.ImVec2(imgui.GetContentRegionAvail().x, 70*d))
                    end
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                elseif e.s_avg or e.cp_sp then
                    imgui.TextColored(ac2, u8'Цены (пов. скан)')
                    imgui.Spacing()
                    local price2 = e.s_avg or e.cp_sp
                    imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), _cyr5f('$'.._kcr3y(price2)))
                    if e.s_min then imgui.TextColored(imgui.ImVec4(0.4,0.95,0.4,1), _cyr5f('Мин: $'.._kcr3y(e.s_min))) end
                    if e.s_max then imgui.TextColored(imgui.ImVec4(1,0.5,0.5,1), _cyr5f('Макс: $'.._kcr3y(e.s_max))) end
                    imgui.Spacing()
                    imgui.TextDisabled(u8'Для графика — Углублённый скан авто [MH]')
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                end
                if cp_hist and #cp_hist > 0 then
                    imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,0.9), _cyr5f('  История по дням (' .. #cp_hist .. '):'))
                    local hist_h = math.min(#cp_hist * 18*d + 30*d, 220*d)
                    if imgui.BeginChild('##autohistch', imgui.ImVec2(-1, hist_h), true) then
                        _dpn1w()  -- swipe scroll
                        imgui.Columns(3, '##auto_hd', false)
                        imgui.SetColumnWidth(0, 120*d); imgui.SetColumnWidth(1, 70*d); imgui.SetColumnWidth(2, 110*d)
                        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8' Дата'); imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8' Сделок'); imgui.NextColumn()
                        imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), u8' Ср. цена'); imgui.NextColumn()
                        imgui.Separator()
                        for i3, h in ipairs(cp_hist) do
                            local rc = (i3==1) and imgui.ImVec4(lp_r,lp_g,lp_b,1) or imgui.ImVec4(0.85,0.85,0.85,1)
                            imgui.TextColored(imgui.ImVec4(0.65,0.65,0.65,1), _cyr5f(' '..(h.dt or ''))); imgui.NextColumn()
                            imgui.TextColored(imgui.ImVec4(1,1,1,0.75), _cyr5f(' '..(h.qty or 0))); imgui.NextColumn()
                            imgui.TextColored(rc, _cyr5f(' $'.._kcr3y(h.price or 0))); imgui.NextColumn()
                        end
                        imgui.Columns(1); imgui.EndChild()
                    end
                elseif e.hist and #e.hist > 0 then
                    local hist = e.hist
                    imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), u8'История сканов:')
                    if imgui.BeginChild('##autohistch2', imgui.ImVec2(-1, 100*d), true) then
                        _dpn1w()  -- swipe scroll
                        for hi = 1, #hist do
                            local h = hist[hi]
                            imgui.TextColored(imgui.ImVec4(0.5,0.5,0.5,1), _cyr5f(h.dt or ''))
                            imgui.SameLine(70*d)
                            imgui.TextColored(imgui.ImVec4(lp_r,lp_g,lp_b,1), _cyr5f('$'.._kcr3y(h.price or 0)))
                        end
                        imgui.EndChild()
                    end
                end
            else imgui.TextDisabled(u8'Данные не найдены') end
            imgui.Spacing()
            if imgui.Button(_ic_x..' '..u8'Закрыть##autodtlclose', imgui.ImVec2(-1, 0)) then
                _G.mkt_auto_detail_open = false
            end
        end
        if not closed2[0] then _G.mkt_auto_detail_open = false end
        imgui.End()
    end
)

imgui.OnFrame(function() return _G.mh_piar_edit_open == true and _G.mh_piar_edit_index ~= nil end, function()
    if not _G.mh_piar_edit_index or not settings.piar_templates[_G.mh_piar_edit_index] then
        _G.mh_piar_edit_open = false; _G.mh_piar_edit_index = nil; return
    end
    local t = settings.piar_templates[_G.mh_piar_edit_index]
    local d = settings.general.custom_dpi
    local sizeX2, sizeY2 = imgui.GetIO().DisplaySize.x, imgui.GetIO().DisplaySize.y
      if not _G.mh_piar_edit_pos then
          _G.mh_piar_edit_pos = {x = sizeX2/2, y = sizeY2/2}
      end
      local PiarEditWindowMH = imgui.new.bool(true)
      imgui.SetNextWindowPos(imgui.ImVec2(_G.mh_piar_edit_pos.x, _G.mh_piar_edit_pos.y), imgui.Cond.Once, imgui.ImVec2(0.5, 0.5))
      imgui.SetNextWindowSize(imgui.ImVec2(500*d, 380*d), imgui.Cond.FirstUseEver)
      imgui.GetIO().ConfigWindowsMoveFromTitleBarOnly = false
      imgui.Begin(_cyr5f(' \xcf\xe8\xe0\xf0: '..(t.name or'')), PiarEditWindowMH, imgui.WindowFlags.NoCollapse)
      _ltz8m()
    imgui.Text(u8'Название:')
    local pn = imgui.new.char[256](_cyr5f(t.name or''))
    imgui.PushItemWidth(-1)
    if imgui.InputText('##mhpn', pn, 256) then t.name=u8:decode(ffi.string(pn)); _wfn7p() end
    imgui.PopItemWidth()
    imgui.Text(u8'Задержка (с):')
    local pw2 = imgui.new.float(t.waiting or 1.5); imgui.PushItemWidth(-1)
    if imgui.SliderFloat('##mhpw', pw2, 0.5, 10) then t.waiting=pw2[0]; _wfn7p() end
    imgui.PopItemWidth()
    imgui.Text(u8'Авто-интервал мин (с):')
    local pi2 = imgui.new.int(t.auto_interval or 300); imgui.PushItemWidth(-1)
    if imgui.SliderInt('##mhpi', pi2, 30, 3600) then
        t.auto_interval=pi2[0]
        if (t.auto_interval_max or 0) < pi2[0] then t.auto_interval_max=pi2[0] end
        t._next_interval = nil
        _wfn7p()
    end
    imgui.PopItemWidth()
    imgui.Text(u8'Авто-интервал макс (0=нет рандома):')
    local pm2 = imgui.new.int(t.auto_interval_max or 0); imgui.PushItemWidth(-1)
    if imgui.SliderInt('##mhpm', pm2, 0, 3600) then t.auto_interval_max=pm2[0]; t._next_interval=nil; _wfn7p() end
    imgui.PopItemWidth()
    imgui.Separator()
    imgui.Text(u8'Строки (используй & для разделения):')
    if imgui.BeginChild('##mhpl', imgui.ImVec2(-1, 100*d), true) then
        local rm = nil
        for li, line in ipairs(t.lines or {}) do
            local inp = imgui.new.char[512](_cyr5f(line)); imgui.PushItemWidth(390*d)
            if imgui.InputText('##mhpli'..li, inp, 512) then t.lines[li]=u8:decode(ffi.string(inp)); _wfn7p() end
            imgui.SameLine()
            if imgui.SmallButton(_ic_x..'##mhpld'..li) then rm=li end
        end
        if rm then table.remove(t.lines, rm); _wfn7p() end
        imgui.EndChild()
    end
    local hw_p = (imgui.GetWindowContentRegionWidth() - 4*d) / 2
    if imgui.Button(_ic_circp..' '..u8'Строка##mhpaline', imgui.ImVec2(hw_p, 0)) then
        table.insert(t.lines, '/s Текст'); _wfn7p()
    end
    imgui.SameLine()
    if imgui.Button(_ic_trash..' '..u8'Удалить шаблон##mhpldel', imgui.ImVec2(hw_p, 0)) then
        table.remove(settings.piar_templates, _G.mh_piar_edit_index)
        _wfn7p(); _G.mh_piar_edit_open = false; _G.mh_piar_edit_index = nil
    end
    if not PiarEditWindowMH[0] then _G.mh_piar_edit_open = false end
    imgui.End()
end)
