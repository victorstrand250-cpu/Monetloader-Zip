script_name("NexaArizona Mobile v1.5.5")
script_author("NexaCFG / Mobile port for Monetloader")
script_version("1.5.5-monet")
script_properties("work-in-pause")

local imgui    = require("mimgui")
local sampev   = require("lib.samp.events")
local encoding = require("encoding")
local requests = require("requests")
local ffi      = require("ffi")
local inicfg   = require("inicfg")

encoding.default = "CP1251"
local u8  = encoding.UTF8
local MDS = MONET_DPI_SCALE or 1
local new = imgui.new

-- Android ffi
local gta = ffi.load("GTASA")
ffi.cdef[[
    void _Z12AND_OpenLinkPKc(const char* link);
    void* _ZN4CPad6GetPadEi(int num);
]]
local function openLink(url) pcall(gta._Z12AND_OpenLinkPKc, url) end

local CFG_FILE = "NexaArizona_mobile"
local VERSION  = "1.5.5"

-- --------------------------------------------------------------------------
-- State
-- --------------------------------------------------------------------------
local my = { ped = nil, id = -1, nick = "", satiety = 100, eating_in_progress = false }

local farmState = {
    active = false, sync_enabled = false,
    target_x = nil, target_y = nil, target_z = nil,
    locked_target = nil
}
local collectState = { active = false, start_time = 0 }
local roamState = {
    active = false, start_time = 0, roam_waypoints = {}, wp_idx = 1,
    last_scan = 0, last_roam_stop = 0, scan_interval = 0.5,
    priority_target = nil, priority_id = nil, waiting_at_target = false
}
local navState = {
    cam_angle = 0, last_px = 0, last_py = 0, last_pz = 0,
    last_check = 0, stuck_ticks = 0, last_stuck_action = 0,
    CHECK_INTERVAL = 2, MIN_MOVE_DIST = 0.5
}
local fps         = { value = 0, frames = 0, last_tick = os.clock() }
local tgBot       = { next_update_id = -1, timeout = 5 }
local isAltPress  = false
local update_avail = false
local latest_ver   = ""
local ver_status   = u8("Статус: Проверка...")

-- --------------------------------------------------------------------------
-- Config (imgui binds)
-- --------------------------------------------------------------------------
local farm = {
    running         = new.bool(false),
    collect_cotton  = new.bool(true),
    collect_linen   = new.bool(true),
    real_run        = new.bool(true),
    anti_afk        = new.bool(true),
    auto_eat        = new.bool(false),
    eat_method      = new.int(0),
    eat_percent     = new.int(20),
    anti_slap       = new.bool(true),
    telegram_logs   = new.bool(true),
    anti_freeze     = new.bool(true),
    auto_answer     = new.bool(false),
    antadmin_autooff    = new.bool(true),
    antadmin_stop_on_tp = new.bool(true),
    antadmin_tg         = new.bool(true),
    antadmin_tg_all     = new.bool(false),
    antadmin_safeexit   = new.bool(false),
    antadmin_skipdialog = new.bool(false),
    anti_stuck_jump = new.bool(true),
    auto_jump       = new.bool(false),
    auto_skin       = new.bool(false),
    auto_skin_interval = new.int(5),
    delay_chat_on_tp = new.bool(true),
    cj_run          = new.bool(false),
    inf_run         = new.bool(false),
    anti_hunger_sprint = new.bool(false),
    chat_filter     = new.bool(true),
    alarm_enabled   = new.bool(false),
    alarm_url       = new.char[256](""),
    prot_teleport   = new.bool(true),
    prot_admin_msg  = new.bool(true),
    prot_dialog     = new.bool(true),
    prot_spawn      = new.bool(true),
    prot_anti_slap  = new.bool(true),
    prot_fake_roam  = new.bool(true),
    prot_skip_busy_bush = new.bool(true),
    prot_veh_check  = new.bool(true),
    res_counter     = { cotton = 0, linen = 0, rare = 0, coal = 0 },
    stats           = { start_time = 0 },
    last_skin_time  = 0,
    last_jump_time  = 0,
}
local tg = {
    enabled = new.bool(false),
    token   = new.char[128](""),
    chat_id = new.char[64]("")
}
local timer_cfg = {
    enabled   = new.bool(false),
    startTime = 0,
    hours     = new.float(0),
    minutes   = new.float(0)
}
local calc = {
    price_cotton = new.float(0),
    price_linen  = new.float(0),
    price_rare   = new.float(0),
    price_coal   = new.float(0)
}
local theme = {
    accent       = new.float[4](0.2, 0.55, 1, 0.75),
    global_alpha = new.float(0.95)
}
local cleaner_cfg = {
    enabled              = new.bool(false),
    limit                = new.int(512),
    notificationsEnabled = new.bool(true)
}

-- UI
local ui = {
    window_open  = new.bool(false),
    stats_window = new.bool(false),
    pause_bot    = new.bool(false),
    active_tab   = "Dashboard",
    log_lines    = {}
}

-- --------------------------------------------------------------------------
-- Status messages
-- --------------------------------------------------------------------------
local STATUS = {
    IDLE       = { text = u8("Ожидание"),         color = imgui.ImVec4(0.7, 0.7, 0.7, 1) },
    RUNNING    = { text = u8("Работает"),          color = imgui.ImVec4(0.1, 0.8, 0.1, 1) },
    PAUSED     = { text = u8("На паузе"),          color = imgui.ImVec4(1, 0.6, 0, 1) },
    COLLECTING = { text = u8("Собирает ресурс"),   color = imgui.ImVec4(0.2, 0.7, 1, 1) },
    STUCK      = { text = u8("Застрял"),           color = imgui.ImVec4(1, 0.2, 0.2, 1) },
    ROAMING    = { text = u8("Ищет куст"),         color = imgui.ImVec4(0.9, 0.8, 0.1, 1) },
    IN_VEHICLE = { text = u8("В транспорте"),      color = imgui.ImVec4(1, 0.3, 0.3, 1) }
}

local EAT_CMDS = { "/cheeps", "/jfish", "/jmeat", "/meatbag" }
local CHAT_RESP = {
    "?", u8("эм"), u8("эмм"), u8("хм"), u8("эм?"), u8("??"),
    u8("а?"), u8("ааа"), u8("ое"), u8("оек"), u8("секунду"),
    u8("э"), u8("чё"), u8("да")
}

local TABS = {
    { id = "Dashboard", name = u8("О скрипте") },
    { id = "AutoFarm",  name = u8("Ферма") },
    { id = "Telegram",  name = u8("Телеграм") },
    { id = "Settings",  name = u8("Опции") },
    { id = "Logging",   name = u8("Логи") }
}

-- --------------------------------------------------------------------------
-- Utilities
-- --------------------------------------------------------------------------
local function dist3d(x1,y1,z1,x2,y2,z2)
    local d = (x1-x2)^2+(y1-y2)^2+(z1-z2)^2
    return math.sqrt(d)
end
local function dist2d(x1,y1,x2,y2)
    return math.sqrt((x1-x2)^2+(y1-y2)^2)
end
local function trim(s) return (tostring(s or "")):gsub("^%s*(.-)%s*$","%1") end
local function fstr(buf) return trim(ffi.string(buf)) end

local function fmt_money(n)
    n = math.floor(n or 0)
    local s = tostring(n)
    local r,l = "",#s
    for i=1,l do
        r=r..s:sub(i,i)
        if (l-i)%3==0 and i~=l then r=r.."." end
    end
    return r
end
local function fmt_time(s)
    return string.format("%02d:%02d:%02d",
        math.floor(s/3600), math.floor(s%3600/60), s%60)
end

-- --------------------------------------------------------------------------
-- Config save / load (INI)
-- --------------------------------------------------------------------------
local BOOL_KEYS = {
    "collect_cotton","collect_linen","real_run","anti_afk","auto_eat",
    "anti_slap","telegram_logs","anti_freeze","auto_answer","antadmin_autooff",
    "antadmin_stop_on_tp","antadmin_tg","antadmin_tg_all","antadmin_safeexit",
    "antadmin_skipdialog","anti_stuck_jump","auto_jump","auto_skin",
    "delay_chat_on_tp","cj_run","inf_run","anti_hunger_sprint","chat_filter",
    "alarm_enabled","prot_teleport","prot_admin_msg","prot_dialog","prot_spawn",
    "prot_anti_slap","prot_fake_roam","prot_skip_busy_bush","prot_veh_check"
}

local function save_cfg()
    local data = {
        farm = {
            eat_method         = farm.eat_method[0],
            eat_percent        = farm.eat_percent[0],
            auto_skin_interval = farm.auto_skin_interval[0],
            alarm_url          = fstr(farm.alarm_url),
        },
        telegram = {
            enabled = tg.enabled[0],
            token   = fstr(tg.token),
            chat_id = fstr(tg.chat_id)
        },
        timer = {
            enabled = timer_cfg.enabled[0],
            hours   = timer_cfg.hours[0],
            minutes = timer_cfg.minutes[0]
        },
        calc = {
            price_cotton = calc.price_cotton[0],
            price_linen  = calc.price_linen[0],
            price_rare   = calc.price_rare[0],
            price_coal   = calc.price_coal[0]
        },
        theme = {
            accent_r     = theme.accent[0],
            accent_g     = theme.accent[1],
            accent_b     = theme.accent[2],
            global_alpha = theme.global_alpha[0]
        },
        cleaner = {
            enabled              = cleaner_cfg.enabled[0],
            limit                = cleaner_cfg.limit[0],
            notificationsEnabled = cleaner_cfg.notificationsEnabled[0]
        }
    }
    for _, k in ipairs(BOOL_KEYS) do
        data.farm[k] = farm[k][0]
    end
    inicfg.save(data, CFG_FILE)
end

local function load_cfg()
    local ini = inicfg.load({}, CFG_FILE)
    if not ini then return false end

    local function lb(sec, key, tgt)
        if ini[sec] and ini[sec][key] ~= nil then
            local v = ini[sec][key]
            tgt[0] = (v == true or v == "true")
        end
    end
    local function ln(sec, key, tgt)
        if ini[sec] and ini[sec][key] then
            local v = tonumber(ini[sec][key])
            if v then tgt[0] = v end
        end
    end

    for _, k in ipairs(BOOL_KEYS) do lb("farm", k, farm[k]) end
    ln("farm","eat_method",farm.eat_method)
    ln("farm","eat_percent",farm.eat_percent)
    ln("farm","auto_skin_interval",farm.auto_skin_interval)
    if ini.farm and ini.farm.alarm_url then
        ffi.copy(farm.alarm_url, tostring(ini.farm.alarm_url))
    end
    lb("telegram","enabled",tg.enabled)
    if ini.telegram then
        if ini.telegram.token   then ffi.copy(tg.token,   tostring(ini.telegram.token))   end
        if ini.telegram.chat_id then ffi.copy(tg.chat_id, tostring(ini.telegram.chat_id)) end
    end
    lb("timer","enabled",timer_cfg.enabled)
    ln("timer","hours",timer_cfg.hours)
    ln("timer","minutes",timer_cfg.minutes)
    ln("calc","price_cotton",calc.price_cotton)
    ln("calc","price_linen",calc.price_linen)
    ln("calc","price_rare",calc.price_rare)
    ln("calc","price_coal",calc.price_coal)
    if ini.theme then
        if ini.theme.accent_r     then theme.accent[0]       = tonumber(ini.theme.accent_r)     or theme.accent[0]       end
        if ini.theme.accent_g     then theme.accent[1]       = tonumber(ini.theme.accent_g)     or theme.accent[1]       end
        if ini.theme.accent_b     then theme.accent[2]       = tonumber(ini.theme.accent_b)     or theme.accent[2]       end
        if ini.theme.global_alpha then theme.global_alpha[0] = tonumber(ini.theme.global_alpha) or theme.global_alpha[0] end
    end
    lb("cleaner","enabled",cleaner_cfg.enabled)
    ln("cleaner","limit",cleaner_cfg.limit)
    lb("cleaner","notificationsEnabled",cleaner_cfg.notificationsEnabled)
    add_log("{33CCFF}[Конфиг] Настройки загружены.")
    return true
end

-- --------------------------------------------------------------------------
-- Logging
-- --------------------------------------------------------------------------
function add_log(msg, force_tg)
    if type(msg) ~= "string" then msg = tostring(msg or "nil") end
    local clean = msg:gsub("{%x%x%x%x%x%x}",""):gsub("{.-}","")
    local line  = "["..os.date("%H:%M:%S").."] "..clean
    pcall(print, line)
    table.insert(ui.log_lines, 1, line)
    if #ui.log_lines > 50 then table.remove(ui.log_lines) end
    if force_tg or (farm.telegram_logs[0] and (msg:find("{FF") or msg:find(u8("БЕЗОПАСНОСТЬ")) or msg:find(u8("ЗАЩИТА")))) then
        send_telegram(clean)
    end
end

-- --------------------------------------------------------------------------
-- Telegram
-- --------------------------------------------------------------------------
local function tg_raw_send(text, token, chat_id)
    token   = token   or fstr(tg.token)
    chat_id = chat_id or fstr(tg.chat_id)
    if token == "" or chat_id == "" then return end
    local enc = encoding.encode(tostring(text or ""), "CP1251")
    local body = string.format("chat_id=%s&text=%s&parse_mode=HTML",
        chat_id,
        enc:gsub("([^%w %-%_%.%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end):gsub(" ", "+"))
    lua_thread.create(function()
        pcall(requests.post,
            "http://147.45.74.203/bot"..token.."/sendMessage",
            {body=body, headers={["Content-Type"]="application/x-www-form-urlencoded"}})
    end)
end

function send_telegram(text)
    if not tg.enabled[0] then return end
    tg_raw_send(text)
end

local function handle_tg_cmd(cmd, raw)
    local rc = farm.res_counter
    if cmd == "/status" then
        local elapsed = farm.stats.start_time > 0 and os.time()-farm.stats.start_time or 0
        local profit  = rc.cotton*calc.price_cotton[0] + rc.linen*calc.price_linen[0]
                      + rc.rare*calc.price_rare[0] + rc.coal*calc.price_coal[0]
        send_telegram(string.format(
            "<b>Статус бота</b>\n<b>Игрок:</b> %s\n<b>Бот:</b> %s\n\n"..
            "<b>Хлопок:</b> %d\n<b>Лён:</b> %d\n<b>Ткань:</b> %d\n<b>Уголь:</b> %d\n\n"..
            "<b>Прибыль:</b> %s $\n<b>Время:</b> %s",
            my.nick, farm.running[0] and u8("Работает") or u8("Стоп"),
            rc.cotton, rc.linen, rc.rare, rc.coal,
            fmt_money(profit), fmt_time(elapsed)))
    elseif cmd == "/stop" then
        if farm.running[0] then
            farm.running[0] = false
            emergency_stop()
            send_telegram(u8("Бот остановлен по /stop"))
        end
    elseif cmd == "/start_bot" then
        if not farm.running[0] then
            farm.running[0] = true
            rc.cotton=0; rc.linen=0; rc.rare=0; rc.coal=0
            farm.stats.start_time = os.time()
            resetNavPath()
            send_telegram(u8("Бот запущен по /start_bot"))
        end
    elseif cmd == "/report" then
        send_session_report(u8("Запрос из ТГ"))
    elseif cmd == "/q" then
        send_telegram(u8("Экстренный выход..."))
        lua_thread.create(function() wait(1000); sampProcessChatInput("/q") end)
    elseif cmd:match("^/msg%s+(.+)") then
        local t = cmd:match("^/msg%s+(.+)")
        sampSendChat(encoding.decode(t,"CP1251"))
        send_telegram(u8("Отправлено в чат: ")..t)
    elseif cmd:match("^/bsg%s+(.+)") then
        local t = cmd:match("^/bsg%s+(.+)")
        sampSendChat("/b "..encoding.decode(t,"CP1251"))
        send_telegram(u8("Отправлено в /b: ")..t)
    end
end

local function poll_telegram_loop()
    while true do
        local token   = fstr(tg.token)
        local chat_id = fstr(tg.chat_id)
        if not tg.enabled[0] or token=="" or chat_id=="" then
            wait(5000)
        else
            local url = string.format(
                "http://147.45.74.203/bot%s/getUpdates?timeout=%d&offset=%d&limit=10",
                token, (tgBot.next_update_id>-1 and tgBot.timeout or 0), tgBot.next_update_id)
            local ok, resp = pcall(requests.get, url)
            if ok and resp and resp.status_code==200 then
                local jok, data = pcall(function()
                    local cok,cjson = pcall(require,"cjson")
                    if cok then return cjson.decode(resp.text) end
                    return nil
                end)
                if jok and data and data.ok and data.result then
                    for _, upd in ipairs(data.result) do
                        if upd.message and upd.message.text then
                            if tostring(upd.message.chat.id)==chat_id then
                                local cmd = trim(upd.message.text):lower()
                                handle_tg_cmd(cmd, upd.message.text)
                            end
                        end
                        tgBot.next_update_id = upd.update_id + 1
                    end
                end
            end
            wait(3000)
        end
        wait(100)
    end
end

-- --------------------------------------------------------------------------
-- Session report
-- --------------------------------------------------------------------------
function send_session_report(reason)
    if not tg.enabled[0] then return end
    local rc      = farm.res_counter
    local elapsed = os.time() - (farm.stats.start_time or os.time())
    local profit  = rc.cotton*calc.price_cotton[0] + rc.linen*calc.price_linen[0]
                  + rc.rare*calc.price_rare[0] + rc.coal*calc.price_coal[0]
    send_telegram(string.format(
        u8("ОТЧЁТ СЕССИИ\nПричина: %s\nВремя: %s\n\n"..
        "Хлопок: %d - %s$\nЛён: %d - %s$\nТкань: %d - %s$\nУголь: %d - %s$\n\n"..
        "ИТОГО: %s$"),
        reason or u8("Остановка"), fmt_time(elapsed),
        rc.cotton, fmt_money(rc.cotton*calc.price_cotton[0]),
        rc.linen,  fmt_money(rc.linen*calc.price_linen[0]),
        rc.rare,   fmt_money(rc.rare*calc.price_rare[0]),
        rc.coal,   fmt_money(rc.coal*calc.price_coal[0]),
        fmt_money(profit)))
    add_log("{33FF33}[Отчёт] Отчёт отправлен в Телеграм")
end

-- --------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------
local function stopMovingKeys()
    setGameKeyState(1,0); setGameKeyState(16,0); setGameKeyState(0,0)
    farmState.sync_enabled = false
end

function resetNavPath()
    navState.cam_angle = 0
    navState.last_px = 0; navState.last_py = 0; navState.last_pz = 0
    navState.last_check = 0; navState.stuck_ticks = 0; navState.last_stuck_action = 0
    farmState.active = false; farmState.target_x = nil
    farmState.target_y = nil; farmState.target_z = nil
    setGameKeyState(1,0); setGameKeyState(16,0); setGameKeyState(0,0)
    collectgarbage("step",50)
end

local function calcObstacleTurn()
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    local heading  = math.rad(getCharHeading(PLAYER_PED)) + math.pi/2
    for _,zoff in ipairs({0.3,1}) do
        for _,aoff in ipairs({0, math.rad(30), math.rad(-30), math.rad(60), math.rad(-60)}) do
            local a = heading + aoff
            local hit = processLineOfSight(
                px,py,pz+zoff, px+5*math.cos(a),py+5*math.sin(a),pz+zoff,
                true,false,false,true,true,false,false,false)
            if hit then
                if aoff>0 then return -255 elseif aoff<0 then return 255
                else return (math.random()>0.5 and 255 or -255) end
            end
        end
    end
    return 0
end

local function runToPoint(tx,ty,tz)
    local px,py,pz = getCharCoordinates(PLAYER_PED)
    local now      = os.clock()

    -- Stuck detection
    if now-navState.last_check >= navState.CHECK_INTERVAL then
        local moved = dist3d(px,py,pz,navState.last_px,navState.last_py,navState.last_pz)
        if moved < navState.MIN_MOVE_DIST then
            navState.stuck_ticks = navState.stuck_ticks+1
        else
            navState.stuck_ticks = 0
        end
        navState.last_px=px; navState.last_py=py; navState.last_pz=pz
        navState.last_check = now
        if navState.stuck_ticks>=4 and now-navState.last_stuck_action>=2 then
            setGameKeyState(14,255)
            setGameKeyState(0,math.random(-255,255))
            navState.last_stuck_action = now
            add_log("{FFCC00}[NavMesh] Застревание - попытка прыжка")
        end
    end

    local d = dist3d(px,py,pz,tx,ty,tz)
    local diff = ((math.deg(math.atan2(ty-py,tx-px))-navState.cam_angle+180)%360)-180
    navState.cam_angle = (navState.cam_angle + diff*(d<10 and 0.18 or 0.08)+360)%360

    -- Point camera
    local cx,cy,_ = getActiveCameraCoordinates()
    setCameraPositionUnfixed(0, -math.atan2(
        (py+math.sin(math.rad(navState.cam_angle))*10)-cy,
        -((px+math.cos(math.rad(navState.cam_angle))*10)-cx)))

    setGameKeyState(1,-255)
    if d>5 and farm.real_run[0] then
        setGameKeyState(16,255)
    else
        setGameKeyState(16,0)
    end
    setGameKeyState(0, calcObstacleTurn())
end

-- --------------------------------------------------------------------------
-- Bush / Resource scanner
-- --------------------------------------------------------------------------
local function isResourceEnabled(text)
    if text:find(u8("Хлопок")) and farm.collect_cotton[0] then return "cotton" end
    if (text:find(u8("Лён")) or text:find(u8("Лен"))) and farm.collect_linen[0] then return "linen" end
    return nil
end

local function parseTimeLeft(text)
    local m,s = text:match("(%d+):(%d+)")
    if m and s then return tonumber(m)*60+tonumber(s) end
    local sec = text:match("(%d+)%s*"..u8("сек"))
    if sec then return tonumber(sec) end
    return nil
end

local function busyByOtherPlayer(bx,by,bz)
    if not farm.prot_skip_busy_bush[0] then return false end
    for pid=0,1000 do
        local ok,conn = pcall(sampIsPlayerConnected,pid)
        if ok and conn and pid~=my.id then
            -- sampGetCharHandleBySampPlayerId returns (bool, ped) in Monetloader
            local ok2, res2, ped2 = pcall(sampGetCharHandleBySampPlayerId, pid)
            if ok2 and res2 and type(ped2) == "number" then
                local ox,oy,oz = getCharCoordinates(ped2)
                if dist3d(ox,oy,oz,bx,by,bz)<2.5 then return true end
            end
        end
    end
    return false
end

local function findBestBush()
    if farmState.locked_target then
        local t = farmState.locked_target
        if sampIs3dTextDefined(t.id) then
            local text,color,bx,by,bz = sampGet3dTextInfoById(t.id)
            if text then
                if text:find(u8("этап 1")) then
                    farmState.locked_target = nil
                elseif text:find(u8("Можно собрать")) or text:find(u8("Для сбора")) then
                    local px,py,pz = getCharCoordinates(PLAYER_PED)
                    return {status="READY",id=t.id,
                        distance=dist3d(px,py,pz,bx,by,bz),
                        position={x=bx,y=by,z=bz},text=text,color=color}
                else
                    local tl = parseTimeLeft(text)
                    if tl and tl<3 and isResourceEnabled(text) and not busyByOtherPlayer(bx,by,bz) then
                        local px,py,pz = getCharCoordinates(PLAYER_PED)
                        return {status="GROWING",id=t.id,
                            distance=dist3d(px,py,pz,bx,by,bz),
                            position={x=bx,y=by,z=bz},timeLeft=tl,text=text,color=color}
                    end
                end
            end
        end
        farmState.locked_target = nil
    end

    local px,py,pz = getCharCoordinates(PLAYER_PED)
    local bestReady,bestDist  = nil, math.huge
    local bestGrow,bestTime   = nil, math.huge

    for id=0,2047 do
        if sampIs3dTextDefined(id) then
            local text,color,bx,by,bz = sampGet3dTextInfoById(id)
            if text and bx and dist3d(px,py,pz,bx,by,bz)<300
               and not text:find(u8("этап 1")) and isResourceEnabled(text)
               and not busyByOtherPlayer(bx,by,bz) then
                local d = dist3d(px,py,pz,bx,by,bz)
                if text:find(u8("Можно собрать")) or text:find(u8("Для сбора")) then
                    if d<bestDist then
                        bestDist=d
                        bestReady={status="READY",id=id,distance=d,
                            position={x=bx,y=by,z=bz},text=text,color=color}
                    end
                else
                    local tl = parseTimeLeft(text)
                    if tl and tl<bestTime and d<150 then
                        bestTime=tl
                        bestGrow={status="GROWING",id=id,distance=d,timeLeft=tl,
                            position={x=bx,y=by,z=bz},text=text,color=color}
                    end
                end
            end
        end
    end

    if bestReady then
        farmState.locked_target = {id=bestReady.id,position=bestReady.position}
        return bestReady
    elseif bestGrow then
        farmState.locked_target = {id=bestGrow.id,position=bestGrow.position}
        return bestGrow
    end
    return {status="NONE",distance=999}
end

local function findNearestGrowingBush()
    local px,py,pz = getCharCoordinates(my.ped)
    local best,bestTime = nil,11
    for id=0,2047 do
        if sampIs3dTextDefined(id) then
            local text,_,bx,by,bz = sampGet3dTextInfoById(id)
            if text and bx and isResourceEnabled(text) and dist3d(px,py,pz,bx,by,bz)<200 then
                local m,s = text:match("(%d+):(%d+)")
                if m and s then
                    local t=tonumber(m)*60+tonumber(s)
                    if t<=10 and t<bestTime then bestTime=t; best={id=id,x=bx,y=by,z=bz,timeLeft=t} end
                end
            end
        end
    end
    return best
end

-- --------------------------------------------------------------------------
-- Roam
-- --------------------------------------------------------------------------
local function buildRoamWaypoints()
    local px,py,pz = getCharCoordinates(my.ped)
    roamState.roam_waypoints={}; roamState.wp_idx=1
    local cands={}
    for id=0,2047 do
        if sampIs3dTextDefined(id) then
            local text,_,bx,by,bz = sampGet3dTextInfoById(id)
            if text and bx and isResourceEnabled(text) and dist3d(px,py,pz,bx,by,bz)<300 then
                local tl=parseTimeLeft(text)
                if tl and tl>10 then table.insert(cands,{x=bx,y=by,z=bz}) end
            end
        end
    end
    if #cands==0 then
        for _=1,math.random(2,4) do
            local a=math.random()*math.pi*2; local r=math.random(15,50)
            table.insert(roamState.roam_waypoints,{x=px+math.cos(a)*r,y=py+math.sin(a)*r,z=pz})
        end
    else
        for i=#cands,2,-1 do local j=math.random(i); cands[i],cands[j]=cands[j],cands[i] end
        local cnt=math.min(#cands,math.random(2,5))
        for i=1,cnt do table.insert(roamState.roam_waypoints,cands[i]) end
    end
    roamState.last_roam_stop=os.clock()
end

local function startRoam()
    if roamState.active or not farm.prot_fake_roam[0] then return end
    roamState.active=true; roamState.start_time=os.clock()
    roamState.priority_target=nil; roamState.priority_id=nil
    roamState.waiting_at_target=false
    buildRoamWaypoints()
    add_log("{BBBBFF}[Поиск] Начинаю поиск созревающего куста")
end

local function updateRoam()
    if not roamState.active then return false end
    local now=os.clock()
    if now-roamState.last_scan>=roamState.scan_interval then
        roamState.last_scan=now
        if roamState.priority_id then
            if sampIs3dTextDefined(roamState.priority_id) then
                local text,_,bx,by,bz = sampGet3dTextInfoById(roamState.priority_id)
                if text then
                    if text:find(u8("Можно собрать")) or text:find(u8("Для сбора")) then
                        roamState.waiting_at_target=false
                        runToPoint(bx,by,bz); farmState.sync_enabled=true
                        local px,py,pz=getCharCoordinates(my.ped)
                        if dist3d(px,py,pz,bx,by,bz)<1.3 then
                            roamState.active=false; stopMovingKeys(); resetNavPath(); return false
                        end
                        roamState.roam_waypoints={}; return true
                    else
                        local tl=parseTimeLeft(text)
                        if tl then
                            if tl>10 then
                                roamState.priority_target=nil; roamState.priority_id=nil
                                roamState.waiting_at_target=false
                                if #roamState.roam_waypoints==0 then buildRoamWaypoints() end
                            elseif not roamState.waiting_at_target then
                                local px,py,pz=getCharCoordinates(my.ped)
                                if dist2d(px,py,bx,by)<2.5 then
                                    roamState.waiting_at_target=true
                                    roamState.roam_waypoints={}
                                    stopMovingKeys(); resetNavPath()
                                    add_log("{BBBBFF}[Поиск] Жду куст ~"..tl..u8("сек"))
                                else
                                    runToPoint(bx,by,bz); farmState.sync_enabled=true; return true
                                end
                            end
                            return true
                        end
                    end
                else
                    roamState.priority_target=nil; roamState.priority_id=nil; roamState.waiting_at_target=false
                end
            else
                roamState.priority_target=nil; roamState.priority_id=nil; roamState.waiting_at_target=false
            end
        end
        if not roamState.priority_target then
            local near=findNearestGrowingBush()
            if near then
                roamState.priority_target=near; roamState.priority_id=near.id
                roamState.roam_waypoints={}
                add_log(string.format("{BBBBFF}[Поиск] Куст созревает (%d"..u8("сек").."), бегу",near.timeLeft))
            end
        end
    end
    if roamState.waiting_at_target or roamState.priority_id then return true end
    if #roamState.roam_waypoints==0 then roamState.active=false; stopMovingKeys(); resetNavPath(); return false end
    local wp=roamState.roam_waypoints[roamState.wp_idx]
    if not wp then roamState.active=false; stopMovingKeys(); resetNavPath(); return false end
    local px,py,pz=getCharCoordinates(my.ped)
    if dist2d(px,py,wp.x,wp.y)<2 then
        roamState.wp_idx=roamState.wp_idx+1
        if roamState.wp_idx>#roamState.roam_waypoints then buildRoamWaypoints() end
    end
    local nwp=roamState.roam_waypoints[roamState.wp_idx]
    if nwp then runToPoint(nwp.x,nwp.y,nwp.z); farmState.sync_enabled=true end
    return true
end

-- --------------------------------------------------------------------------
-- Press ALT (interact with bush)
-- --------------------------------------------------------------------------
local function pressAltTask()
    if isAltPress then return end
    isAltPress=true
    lua_thread.create(function()
        for _=1,math.random(5,10) do
            if ui.pause_bot[0] or not farm.running[0] then break end
            setGameKeyState(21,255); wait(math.random(60,100))
            setGameKeyState(21,0);   wait(math.random(60,100))
        end
        setGameKeyState(21,0)
        farmState.locked_target=nil
        isAltPress=false
        farmState.active=true; farmState.sync_enabled=true
        farmState.target_x=nil; farmState.target_y=nil; farmState.target_z=nil
        resetNavPath()
    end)
end

-- --------------------------------------------------------------------------
-- update_movement  (main farm tick)
-- --------------------------------------------------------------------------
local function update_movement()
    if ui.pause_bot[0] then
        farmState.active=false; stopMovingKeys()
        if not isCharSittingInAnyCar(my.ped) then clearCharTasksImmediately(my.ped) end
        return
    end
    if isCharInAnyCar(my.ped) then farmState.active=false; stopMovingKeys(); return end

    -- Auto-eat
    if farm.auto_eat[0] and my.satiety and my.satiety<=farm.eat_percent[0] and not my.eating_in_progress then
        lua_thread.create(function()
            my.eating_in_progress=true
            add_log("{FFFF00}[Авто-еда] Сытость: "..my.satiety.."%. Использую еду...")
            local item=EAT_CMDS[farm.eat_method[0]+1]
            if item then sampSendChat(item); wait(3500) end
            my.eating_in_progress=false
        end)
    end

    if updateRoam() then return end

    local px,py,pz=getCharCoordinates(my.ped)
    local target=findBestBush()
    if not target or not target.position then
        farmState.active=false; stopMovingKeys()
        if not isCharSittingInAnyCar(my.ped) then clearCharTasksImmediately(my.ped) end
        return
    end

    if target.status=="READY" then
        if dist2d(px,py,target.position.x,target.position.y)<1.3 then
            farmState.active=false; stopMovingKeys(); clearCharTasksImmediately(my.ped)
            if not collectState.active then
                collectState.active=true; collectState.start_time=os.time()
            end
            pressAltTask(); return
        end
    elseif target.status=="GROWING" then
        if (target.distance or 999)<2.5 then
            farmState.active=false; stopMovingKeys(); clearCharTasksImmediately(my.ped)
            startRoam(); return
        end
    end

    farmState.target_x=target.position.x
    farmState.target_y=target.position.y
    farmState.target_z=target.position.z
    farmState.active=true
    runToPoint(farmState.target_x,farmState.target_y,farmState.target_z)
end

function emergency_stop()
    farmState.active=false; farmState.sync_enabled=false; farmState.locked_target=nil
    collectState.active=false; roamState.active=false
    setGameKeyState(1,0); setGameKeyState(16,0); setGameKeyState(21,0)
    resetNavPath()
    add_log("{FF3333}[Система] Аварийная остановка.")
end

-- --------------------------------------------------------------------------
-- Admin action handler
-- --------------------------------------------------------------------------
local function handleAdminAction(text, isTeleport)
    add_log("{FF0000}ЗАЩИТА: "..(isTeleport and u8("Принудительная телепортация!") or u8("Сообщение от админа!")))
    ui.pause_bot[0]=true
    if farm.antadmin_autooff[0] then
        farm.running[0]=false; emergency_stop()
        add_log("{FF0000}"..u8("Бот отключён автоматически."))
        send_session_report(isTeleport and u8("Телепортация администратором") or u8("Сообщение от admin"))
    end
    if farm.antadmin_tg[0] then
        send_telegram(u8("ВНИМАНИЕ: действие админа!\nТип: ")..
            (isTeleport and u8("Телепорт") or u8("Сообщение"))..u8("\nТекст: ")..text)
    end
    if isTeleport and farm.delay_chat_on_tp[0] then
        lua_thread.create(function()
            wait(math.random(3000,8000))
            sampSendChat(CHAT_RESP[math.random(#CHAT_RESP)])
        end)
    end
    if farm.antadmin_safeexit[0] then
        lua_thread.create(function()
            wait(20000)
            if ui.pause_bot[0] then sampProcessChatInput("/q") end
        end)
    end
end

-- --------------------------------------------------------------------------
-- SAMP event handlers
-- --------------------------------------------------------------------------
function sampev.onSendPlayerSync(data)
    if farmState.sync_enabled then data.upDownKeys=65408 end
end

function sampev.onShowDialog(id, style, title, btn1, btn2, text)
    if not farm.prot_dialog[0] then return end
    local clean=text:gsub("%{.-%}","")
    if style==0 and clean:find("A: .+ "..u8("ответил вам")) then
        ui.pause_bot[0]=true; stopMovingKeys()
        if not isCharInAnyCar(my.ped) then clearCharTasksImmediately(my.ped) end
        add_log("{FF0000}"..u8("БЕЗОПАСНОСТЬ: Админ отправил диалог!"))
        if farm.antadmin_tg[0] then send_telegram(u8("Администратор отправил диалог:\n")..clean) end
        lua_thread.create(function()
            wait(math.random(4000,7500)); sampCloseCurrentDialogWithButton(1)
        end)
    end
end

function sampev.onSetPlayerPos(pos)
    if not farm.running[0] or not farm.prot_spawn[0] then return end
    local px,py,pz=getCharCoordinates(PLAYER_PED)
    local moved=dist3d(px,py,pz,pos.x,pos.y,pos.z)
    if moved>5 then
        ui.pause_bot[0]=true
        add_log("{FF0000}"..u8("БЕЗОПАСНОСТЬ: Резкое изменение позиции на ")..math.floor(moved)..u8("м!"))
        lua_thread.create(function()
            wait(math.random(3000,6000))
            sampSendChat(CHAT_RESP[math.random(#CHAT_RESP)])
            wait(2000); ui.pause_bot[0]=false
        end)
        if farm.antadmin_tg[0] then
            send_telegram(u8("Сервер переместил вас на ")..math.floor(moved)..u8(" метров!"))
        end
    end
end

function sampev.onServerMessage(color, text)
    local clean=text:gsub("%{.-%}","")

    -- Resource counters
    if text:find("item1692") or text:find(u8("Кусок редкой ткани")) then
        farm.res_counter.rare = farm.res_counter.rare + (tonumber(text:match("%((%d+)%s*"..u8("шт").."%)")  ) or 1)
    elseif text:find(u8("Уголь")) then
        farm.res_counter.coal = farm.res_counter.coal + (tonumber(text:match("%((%d+)%s*"..u8("шт").."%)")  ) or 1)
    end

    if not farm.prot_teleport[0] and not farm.prot_admin_msg[0] then return end

    -- Teleport
    if (farm.prot_teleport[0] or farm.antadmin_stop_on_tp[0]) and
       (clean:find(u8("Вы были телепортированы администратором")) or
        clean:find("A: .+%[ID: %d+%] "..u8("телепортировал вас"))) then
        if not ui.pause_bot[0] then
            ui.pause_bot[0]=true; stopMovingKeys()
            if not isCharInAnyCar(my.ped) then clearCharTasksImmediately(my.ped) end
            handleAdminAction(clean,true)
        end
        return
    end

    -- Admin messages
    if farm.prot_admin_msg[0] then
        if clean:find("^"..u8("Администратор").." .-%[%d+%]: .*") then
            if not ui.pause_bot[0] then
                ui.pause_bot[0]=true; stopMovingKeys()
                if not isCharInAnyCar(my.ped) then clearCharTasksImmediately(my.ped) end
                handleAdminAction(clean,false)
                if farm.antadmin_tg[0] then send_telegram(u8("АДМИН РЯДОМ: ")..clean) end
            end
            return
        end
        if clean:find("%(%) "..u8("Администратор").." .+%[%d+%]: .+ %(%)")  or
           clean:find("%(%( "..u8("Администратор").." .+%[%d+%]: .+ %)")    then
            if not ui.pause_bot[0] then
                ui.pause_bot[0]=true; stopMovingKeys()
                handleAdminAction(clean,false)
                if farm.antadmin_tg[0] then send_telegram(u8("АДМИН ПИШЕТ: ")..clean) end
            end
            return
        end
        if farm.antadmin_tg_all[0] and clean:find(u8("говорит")) then
            send_telegram(u8("Подозрение на проверку голосом\n")..clean)
        end
    end

    -- Auto-answer players
    if farm.auto_answer[0]
       and (clean:lower():find(my.nick:lower()) or clean:lower():find(u8("работяга")))
       and not clean:find("forever") then
        lua_thread.create(function()
            wait(math.random(5000,10000))
            sampSendChat(CHAT_RESP[math.random(#CHAT_RESP)])
        end)
    end
end

function sampev.onDisplayGameText(style, duration, text)
    local lower=text:lower()
    local linen =lower:match("linen%s+%+(%d+)")
    local cotton=lower:match("cotton%s+%+(%d+)")
    if linen  then farm.res_counter.linen  = farm.res_counter.linen  + tonumber(linen);  collectState.active=false end
    if cotton then farm.res_counter.cotton = farm.res_counter.cotton + tonumber(cotton); collectState.active=false end
end

function onReceivePacket(id, bs)
    if id~=220 or not farm.auto_eat[0] then return end
    raknetBitStreamIgnoreBits(bs,8)
    if raknetBitStreamReadInt8(bs)~=17 then return end
    raknetBitStreamIgnoreBits(bs,32)
    local len  = raknetBitStreamReadInt16(bs)
    local flag = raknetBitStreamReadInt8(bs)
    local str  = flag~=0 and raknetBitStreamDecodeString(bs,len+1) or raknetBitStreamReadString(bs,len)
    if str then
        local sat = str:match("event%.arizonahud%.playerSatiety', `%[(%d+)%]`")
        if sat then my.satiety=tonumber(sat) end
    end
end

-- --------------------------------------------------------------------------
-- Version check
-- --------------------------------------------------------------------------
local function checkUpdate()
    lua_thread.create(function()
        ver_status=u8("Статус: Проверка...")
        local ok,resp=pcall(requests.get,"https://raw.githubusercontent.com/ScriptRoblox-ay9/NexaProject/main/versions.txt")
        if ok and resp and resp.status_code==200 then
            local v=trim(resp.text)
            if v~=VERSION then
                update_avail=true; latest_ver=v
                ver_status=u8("Доступно: ")..v
                add_log("{33CCFF}[Update] Найдено обновление: "..v)
            else
                update_avail=false; ver_status=u8("У вас актуальная версия")
            end
        else
            ver_status=u8("Ошибка связи с GitHub")
        end
    end)
end

-- --------------------------------------------------------------------------
-- ImGui Style & Fonts
-- --------------------------------------------------------------------------
local font_main, font_title, font_mid

local function applyStyle()
    if imgui.GetCurrentContext()==nil then return end
    local st=imgui.GetStyle(); local c=st.Colors
    local ac=imgui.ImVec4(theme.accent[0],theme.accent[1],theme.accent[2],1)
    c[imgui.Col.WindowBg]       = imgui.ImVec4(0.07,0.07,0.08,0.96)
    c[imgui.Col.ChildBg]        = imgui.ImVec4(0.12,0.12,0.14,0.5)
    c[imgui.Col.Text]           = imgui.ImVec4(1,1,1,1)
    c[imgui.Col.FrameBg]        = imgui.ImVec4(0.14,0.14,0.16,1)
    c[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.18,0.18,0.2,1)
    c[imgui.Col.Button]         = imgui.ImVec4(0.14,0.14,0.16,1)
    c[imgui.Col.ButtonHovered]  = imgui.ImVec4(0.2,0.2,0.23,1)
    c[imgui.Col.CheckMark]      = ac
    c[imgui.Col.SliderGrab]     = ac
    c[imgui.Col.SliderGrabActive] = ac
    c[imgui.Col.Header]         = imgui.ImVec4(ac.x,ac.y,ac.z,0.3)
    c[imgui.Col.Border]         = imgui.ImVec4(0.15,0.15,0.15,0.5)
    c[imgui.Col.Separator]      = c[imgui.Col.Border]
    st.WindowRounding=8; st.ChildRounding=6; st.FrameRounding=5
end

imgui.OnInitialize(function()
    local io   = imgui.GetIO()
    local fcfg = imgui.ImFontConfig()
    fcfg.GlyphExtraSpacing.x = 0.5
    local ranges = io.Fonts:GetGlyphRangesCyrillic()
    local fp = getWorkingDirectory().."/lib/mimgui/trebucbd.ttf"
    if doesFileExist(fp) then
        font_main  = io.Fonts:AddFontFromFileTTF(fp, math.floor(16*MDS), fcfg, ranges)
        font_title = io.Fonts:AddFontFromFileTTF(fp, math.floor(26*MDS), fcfg, ranges)
        font_mid   = io.Fonts:AddFontFromFileTTF(fp, math.floor(20*MDS), fcfg, ranges)
    end
    applyStyle()
end)

-- --------------------------------------------------------------------------
-- UI helpers
-- --------------------------------------------------------------------------
local function accentCol() return imgui.ImVec4(theme.accent[0],theme.accent[1],theme.accent[2],1) end

local function CBtn(label,w,h)
    local c=accentCol()
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(c.x*.5,c.y*.5,c.z*.5,.8))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(c.x*.7,c.y*.7,c.z*.7,1))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(c.x*.4,c.y*.4,c.z*.4,1))
    local r=imgui.Button(label,imgui.ImVec2(w or 0,h or 0))
    imgui.PopStyleColor(3); return r
end

local function DBtn(label,w,h)
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(.55,.12,.12,.8))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(.75,.15,.15,1))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(.4,.08,.08,1))
    local r=imgui.Button(label,imgui.ImVec2(w or 0,h or 0))
    imgui.PopStyleColor(3); return r
end

local function GBtn(label,w,h)
    imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(.12,.5,.18,.8))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(.15,.7,.22,1))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(.08,.35,.1,1))
    local r=imgui.Button(label,imgui.ImVec2(w or 0,h or 0))
    imgui.PopStyleColor(3); return r
end

local function getStatus()
    if ui.pause_bot[0] then return STATUS.PAUSED end
    if my.ped and isCharInAnyCar(my.ped) then return STATUS.IN_VEHICLE end
    if not farm.running[0] then return STATUS.IDLE end
    if roamState.active then return STATUS.ROAMING end
    if collectState.active then return STATUS.COLLECTING end
    if farmState.active then return STATUS.RUNNING end
    return STATUS.IDLE
end

-- --------------------------------------------------------------------------
-- Tab renders
-- --------------------------------------------------------------------------
local function tabDashboard(avail)
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(), u8("Главная панель"))
    if font_mid then imgui.PopFont() end
    imgui.TextDisabled(u8("Добро пожаловать, ")..(my.nick~="" and my.nick or u8("Пользователь")))
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    -- 3 status cards
    local cardW=(avail-30*MDS)/3; local cardH=55*MDS
    local dl=imgui.GetWindowDrawList()
    local function card(title, value, vcol)
        local p=imgui.GetCursorScreenPos()
        dl:AddRectFilled(p,imgui.ImVec2(p.x+cardW,p.y+cardH),
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.ChildBg]),6)
        dl:AddText(imgui.ImVec2(p.x+8,p.y+6),
            imgui.GetColorU32Vec4(imgui.ImVec4(.6,.6,.6,1)),title)
        dl:AddText(imgui.ImVec2(p.x+8,p.y+28),
            imgui.GetColorU32Vec4(vcol or imgui.ImVec4(1,1,1,1)),value)
        imgui.Dummy(imgui.ImVec2(cardW,cardH))
    end
    local st=getStatus()
    card(u8("Статус"),st.text,st.color)
    imgui.SameLine(nil,10*MDS)
    card("FPS",tostring(fps.value), fps.value>30 and imgui.ImVec4(.4,.85,.4,1) or imgui.ImVec4(.9,.4,.4,1))
    imgui.SameLine(nil,10*MDS)
    card(u8("Сессия"),
        farm.running[0] and u8("Активна") or u8("Стоп"),
        farm.running[0] and imgui.ImVec4(.4,.85,.4,1) or imgui.ImVec4(.6,.6,.6,1))

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.TextColored(accentCol(),u8("Информация")); imgui.Spacing()

    local function row(lbl,val)
        imgui.Text(lbl); imgui.SameLine(avail*0.4)
        imgui.TextDisabled(tostring(val)); imgui.Spacing()
    end
    local elapsed = farm.running[0] and farm.stats.start_time>0 and os.time()-farm.stats.start_time or 0
    local rc=farm.res_counter
    row(u8("Аккаунт:"),    my.nick~="" and my.nick or u8("нет"))
    row(u8("Время работы:"),fmt_time(elapsed))
    row(u8("Хлопок:"),     rc.cotton..u8(" шт."))
    row(u8("Лён:"),        rc.linen..u8(" шт."))
    row(u8("Ткань:"),      rc.rare..u8(" шт."))
    row(u8("Уголь:"),      rc.coal..u8(" шт."))

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.TextColored(accentCol(),u8("Версия"))
    imgui.TextDisabled("v"..VERSION.." | "..ver_status)
    imgui.Spacing()
    if update_avail then
        if GBtn(u8("Обновление: ").." v"..latest_ver, avail*.5, 32*MDS) then
            add_log("{33CCFF}[Update] Скачайте обновление вручную")
        end
    else
        if CBtn(u8("Проверить обновление"),avail*.5,32*MDS) then checkUpdate() end
    end
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.TextColored(accentCol(),u8("Ссылки")); imgui.Spacing()
    if CBtn("Telegram @nexacfg",avail*.5,30*MDS) then openLink("https://t.me/nexacfg") end
end

local function tabFarm(avail)
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(),u8("Управление автоматизацией"))
    if font_mid then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing()

    if imgui.BeginChild("##farm_res",imgui.ImVec2(avail,120*MDS),true) then
        imgui.Columns(2,"##fc",false)
        imgui.TextColored(accentCol(),u8("Сбор ресурсов:"))
        if imgui.Checkbox(u8("Собирать Хлопок"),farm.collect_cotton) then save_cfg() end
        if imgui.Checkbox(u8("Собирать Лён"),   farm.collect_linen)  then save_cfg() end
        imgui.NextColumn()
        imgui.TextColored(accentCol(),u8("Персонаж:"))
        if imgui.Checkbox(u8("Бег"),      farm.real_run)  then save_cfg() end
        if imgui.Checkbox(u8("Авто-еда"), farm.auto_eat)  then save_cfg() end
        if farm.auto_eat[0] then
            imgui.PushItemWidth(avail/2-20)
            if imgui.BeginCombo("##eatm",EAT_CMDS[farm.eat_method[0]+1] or EAT_CMDS[1]) then
                for i,item in ipairs(EAT_CMDS) do
                    if imgui.Selectable(item, farm.eat_method[0]==i-1) then
                        farm.eat_method[0]=i-1; save_cfg()
                    end
                end
                imgui.EndCombo()
            end
            imgui.PopItemWidth()
        end
        imgui.Columns(1); imgui.EndChild()
    end

    imgui.Spacing(); imgui.TextColored(accentCol(),u8("Защита и поведение:")); imgui.Spacing()
    if imgui.BeginChild("##farm_prot",imgui.ImVec2(avail,280*MDS),true) then
        imgui.Columns(2,"##pc",false)
        imgui.TextDisabled(u8("Действия:"))
        local actions={
            {u8("Выключать при сообщении админа"),farm.antadmin_autooff},
            {u8("Стоп при телепорте"),            farm.antadmin_stop_on_tp},
            {u8("Авто-выход (20 сек)"),           farm.antadmin_safeexit},
            {u8("Авто-ответ на чек"),             farm.auto_answer},
            {u8("Прыжок при застревании"),        farm.anti_stuck_jump},
            {u8("Чат при телепортации"),          farm.delay_chat_on_tp},
            {u8("Авто-прыжок при беге"),          farm.auto_jump},
        }
        for _,it in ipairs(actions) do
            if imgui.Checkbox(it[1],it[2]) then save_cfg() end
        end
        imgui.NextColumn()
        imgui.TextDisabled(u8("Защитные модули:"))
        local prots={
            {u8("Защита от телепорта"),    farm.prot_teleport},
            {u8("Защита от сообщений"),    farm.prot_admin_msg},
            {u8("Защита от диалогов"),     farm.prot_dialog},
            {u8("Защита от спавна"),       farm.prot_spawn},
            {u8("Антислэп"),               farm.prot_anti_slap},
            {u8("Имитация поиска куста"),  farm.prot_fake_roam},
            {u8("Пропуск занятых кустов"), farm.prot_skip_busy_bush},
            {u8("Чекер машин рядом"),      farm.prot_veh_check},
        }
        for _,it in ipairs(prots) do
            if imgui.Checkbox(it[1],it[2]) then save_cfg() end
        end
        imgui.Spacing(); imgui.TextDisabled(u8("Уведомления:"))
        if imgui.Checkbox(u8("В тг при обнаружении"),farm.antadmin_tg)    then save_cfg() end
        if imgui.Checkbox(u8("Пересылать весь чат"), farm.antadmin_tg_all) then save_cfg() end
        if imgui.Checkbox(u8("Логи в тг"),           farm.telegram_logs)   then save_cfg() end
        imgui.Columns(1); imgui.EndChild()
    end

    imgui.Spacing(); imgui.TextColored(accentCol(),u8("Тревога (Звук)")); imgui.Spacing()
    if imgui.Checkbox(u8("Звук при обнаружении админа"),farm.alarm_enabled) then save_cfg() end
    imgui.PushItemWidth(avail-100)
    if imgui.InputText("##alarm_url",farm.alarm_url,256) then save_cfg() end
    imgui.PopItemWidth(); imgui.SameLine()
    if CBtn(u8("Тест"),90,25*MDS) then openLink(fstr(farm.alarm_url)) end
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,8)
    if imgui.Button(u8("Статистика"),imgui.ImVec2(avail/2-4,35*MDS)) then
        ui.stats_window[0]=not ui.stats_window[0]
    end
    imgui.PopStyleVar()
end

local function tabTelegram(avail)
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(),"Telegram "..u8("уведомления"))
    if font_mid then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing()
    if imgui.Checkbox(u8("Включить Telegram"),tg.enabled) then save_cfg() end
    imgui.Spacing()
    imgui.Text(u8("Токен бота (@BotFather):")); imgui.PushItemWidth(avail)
    if imgui.InputText("##tg_token",tg.token,128)   then save_cfg() end
    imgui.Spacing()
    imgui.Text("Chat ID:")
    if imgui.InputText("##tg_chatid",tg.chat_id,64) then save_cfg() end
    imgui.PopItemWidth(); imgui.Spacing()
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,8)
    if CBtn(u8("Тест отправить сообщение"),avail/2-3,36*MDS) then
        send_telegram(u8("Тест NexaArizona Mobile\nИгрок: ")..my.nick..
            "\n\n/status /stop /start_bot /report /q /msg /bsg")
        add_log("{33CCFF}[Telegram] Тест-сообщение отправлено")
    end
    imgui.SameLine(nil,6)
    if CBtn(u8("Отправить отчёт"),-1,36*MDS) then send_session_report(u8("Ручной запрос")) end
    imgui.PopStyleVar(); imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.TextColored(accentCol(),u8("Команды бота:")); imgui.Spacing()
    for _,cmd in ipairs({
        "/status - "..u8("текущий статус"),"/stop - "..u8("остановить"),
        "/start_bot - "..u8("запустить"),"/report - "..u8("отчёт сессии"),
        "/q - "..u8("выйти с игры"),"/msg [текст] - "..u8("в чат"),
        "/bsg [текст] - "..u8("в нон-РП чат")}) do
        imgui.TextDisabled(cmd)
    end
    imgui.Spacing()
    imgui.PushStyleColor(imgui.Col.Text,imgui.ImVec4(1,.8,.2,1))
    imgui.TextWrapped(u8("Команды работают только из вашего chat_id. Опрос каждые 3 секунды."))
    imgui.PopStyleColor()
end

local function tabSettings(avail)
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(),u8("Дополнительные настройки"))
    if font_mid then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing()

    imgui.TextColored(accentCol(),u8("Таймер работы")); imgui.Spacing()
    if imgui.Checkbox(u8("Включить таймер завершения"),timer_cfg.enabled) then
        timer_cfg.startTime = timer_cfg.enabled[0] and os.time() or 0; save_cfg()
    end
    imgui.PushItemWidth(180*MDS)
    if imgui.SliderFloat(u8("Часы##th"),timer_cfg.hours,0,360,
        string.format("%.0f "..u8("ч"),timer_cfg.hours[0]))   then save_cfg() end
    if imgui.SliderFloat(u8("Минуты##tm"),timer_cfg.minutes,0,59,
        string.format("%.0f "..u8("мин"),timer_cfg.minutes[0])) then save_cfg() end
    imgui.PopItemWidth()
    if timer_cfg.enabled[0] and timer_cfg.startTime>0 then
        local total=math.floor(timer_cfg.hours[0]+.5)*3600+math.floor(timer_cfg.minutes[0]+.5)*60
        local rem=total-(os.time()-timer_cfg.startTime)
        if rem>0 then
            imgui.TextColored(imgui.ImVec4(.3,.8,1,1),u8("До выгрузки: ")..fmt_time(rem))
        else
            imgui.TextColored(imgui.ImVec4(1,.3,.3,1),u8("Время истекло!"))
        end
    end

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.TextColored(accentCol(),u8("Физика бега")); imgui.Spacing()
    if imgui.Checkbox(u8("Стиль бега CJ"),          farm.cj_run)          then save_cfg() end
    if imgui.Checkbox(u8("Бесконечный бег"),         farm.inf_run)         then save_cfg() end
    if imgui.Checkbox(u8("Спринт при малом голоде"), farm.anti_hunger_sprint) then save_cfg() end
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    if CBtn(u8("Сбросить NavMesh путь"),avail*.5,30*MDS) then
        resetNavPath(); add_log("{33CCFF}[NavMesh] Путь сброшен вручную.")
    end
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,8)
    if GBtn(u8("Сохранить настройки"),avail/2-4,36*MDS) then
        save_cfg(); add_log("{33FF33}[Конфиг] Настройки сохранены.")
    end
    imgui.SameLine(nil,8)
    if DBtn(u8("Сбросить настройки"),avail/2-4,36*MDS) then
        farm.real_run[0]=true; farm.anti_afk[0]=true
        farm.collect_cotton[0]=true; farm.collect_linen[0]=true
        farm.auto_eat[0]=false; farm.eat_percent[0]=20
        farm.prot_teleport[0]=true; farm.prot_admin_msg[0]=true
        farm.prot_dialog[0]=true; farm.antadmin_autooff[0]=true
        farm.antadmin_tg[0]=true; farm.telegram_logs[0]=true
        save_cfg(); add_log("{FFAA00}[Конфиг] Настройки сброшены.")
    end
    imgui.PopStyleVar()
end

local function tabLogging(avail)
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(),u8("Журнал событий"))
    if font_mid then imgui.PopFont() end
    imgui.Separator(); imgui.Spacing()
    if imgui.BeginChild("##log",imgui.ImVec2(avail,-45*MDS),true) then
        if #ui.log_lines>0 then
            for _,line in ipairs(ui.log_lines) do imgui.TextWrapped(line) end
        else
            imgui.TextDisabled(u8("Журнал пуст..."))
        end
        imgui.EndChild()
    end
    imgui.Spacing()
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,8)
    if DBtn(u8("Очистить журнал"),avail,30*MDS) then ui.log_lines={} end
    imgui.PopStyleVar()
end

-- --------------------------------------------------------------------------
-- Main window
-- --------------------------------------------------------------------------
imgui.OnFrame(function() return ui.window_open[0] end, function()
    applyStyle()
    local sw,sh=getScreenResolution()
    local ww=math.min(math.floor(900*MDS),math.floor(sw*.95))
    local wh=math.min(math.floor(660*MDS),math.floor(sh*.9))
    imgui.SetNextWindowPos(imgui.ImVec2(sw/2,sh/2),imgui.Cond.FirstUseEver,imgui.ImVec2(.5,.5))
    imgui.SetNextWindowSize(imgui.ImVec2(ww,wh),imgui.Cond.Always)
    imgui.SetNextWindowBgAlpha(theme.global_alpha[0])
    if not imgui.Begin("NexaArizona v"..VERSION.."##main",ui.window_open,
        imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoResize+imgui.WindowFlags.NoTitleBar) then
        imgui.End(); return
    end

    -- Title
    imgui.SetCursorPos(imgui.ImVec2(10*MDS,10*MDS))
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(),"NexaArizona v"..VERSION.." | Mobile")
    if font_mid then imgui.PopFont() end
    imgui.SameLine(ww-40*MDS)
    if DBtn("X",30*MDS,30*MDS) then ui.window_open[0]=false end
    imgui.Separator()

    -- Tab bar
    imgui.SetCursorPosX(10*MDS)
    for i,tab in ipairs(TABS) do
        local act=ui.active_tab==tab.id
        imgui.PushStyleColor(imgui.Col.Button,
            act and imgui.ImVec4(theme.accent[0]*.6,theme.accent[1]*.6,theme.accent[2]*.6,1)
                or imgui.ImVec4(.14,.14,.16,.8))
        if imgui.Button(tab.name.."##t"..tab.id,imgui.ImVec2(0,30*MDS)) then
            ui.active_tab=tab.id
        end
        imgui.PopStyleColor()
        if i<#TABS then imgui.SameLine(nil,5*MDS) end
    end
    imgui.Separator(); imgui.Spacing()

    -- Left panel
    local lw=math.floor(185*MDS)
    if imgui.BeginChild("##left",imgui.ImVec2(lw,-10*MDS),true) then
        local av=imgui.GetContentRegionAvail().x
        imgui.TextColored(accentCol(),"NexaArizona"); imgui.TextDisabled("v"..VERSION)
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        local st=getStatus()
        imgui.Text(u8("Статус:")); imgui.TextColored(st.color,st.text)
        imgui.Spacing()
        local el=farm.running[0] and farm.stats.start_time>0 and os.time()-farm.stats.start_time or 0
        imgui.TextDisabled(fmt_time(el)); imgui.Spacing(); imgui.Separator()
        imgui.SetCursorPosY(imgui.GetWindowHeight()-80*MDS)
        local lbl,r,g,b
        if ui.pause_bot[0] then
            lbl=u8("РАЗБЛОКИРОВАТЬ"); r,g,b=1,.6,0
        elseif farm.running[0] then
            lbl=u8("Остановить"); r,g,b=.55,.12,.12
        else
            lbl=u8("Запустить"); r,g,b=.12,.55,.18
        end
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,8)
        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(r,g,b,.6))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r+.15,g+.1,b+.1,.8))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(r-.1,g-.05,b-.05,1))
        if imgui.Button(lbl,imgui.ImVec2(av,45*MDS)) then
            if ui.pause_bot[0] then
                ui.pause_bot[0]=false
            elseif farm.running[0] then
                farm.running[0]=false; emergency_stop()
                send_session_report(u8("Ручная остановка"))
            else
                farm.running[0]=true
                farm.res_counter.cotton=0; farm.res_counter.linen=0
                farm.res_counter.rare=0;   farm.res_counter.coal=0
                farm.stats.start_time=os.time(); resetNavPath()
                send_telegram(u8("Бот запущен!\nИгрок: ")..my.nick)
            end
        end
        imgui.PopStyleColor(3); imgui.PopStyleVar()
        imgui.EndChild()
    end
    imgui.SameLine()

    -- Content
    if imgui.BeginChild("##content",imgui.ImVec2(0,-10*MDS),true) then
        local av=imgui.GetContentRegionAvail().x
        if     ui.active_tab=="Dashboard" then tabDashboard(av)
        elseif ui.active_tab=="AutoFarm"  then tabFarm(av)
        elseif ui.active_tab=="Telegram"  then tabTelegram(av)
        elseif ui.active_tab=="Settings"  then tabSettings(av)
        elseif ui.active_tab=="Logging"   then tabLogging(av)
        end
        imgui.EndChild()
    end
    imgui.End()
end)

-- Statistics window
imgui.OnFrame(function() return ui.stats_window[0] end, function()
    local sw,sh=getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw/2,sh/2),imgui.Cond.FirstUseEver,imgui.ImVec2(.5,.5))
    imgui.SetNextWindowSize(imgui.ImVec2(360*MDS,520*MDS),imgui.Cond.Always)
    imgui.SetNextWindowBgAlpha(theme.global_alpha[0])
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding,8)
    if not imgui.Begin(u8("Статистика##stats"),ui.stats_window,
        imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoResize) then
        imgui.End(); imgui.PopStyleVar(); return
    end
    local av=imgui.GetContentRegionAvail().x
    local rc=farm.res_counter
    if font_mid then imgui.PushFont(font_mid) end
    imgui.TextColored(accentCol(),u8("Ресурсы и прибыль"))
    if font_mid then imgui.PopFont() end
    imgui.Spacing()
    imgui.TextDisabled(u8("Цены (Хлопок/Лён/Ткань/Уголь):"))
    imgui.PushItemWidth((av-30)/4-5)
    if imgui.InputFloat("##pc",calc.price_cotton,0,0,"%.0f") then save_cfg() end; imgui.SameLine()
    if imgui.InputFloat("##pl",calc.price_linen,0,0,"%.0f")  then save_cfg() end; imgui.SameLine()
    if imgui.InputFloat("##pr",calc.price_rare,0,0,"%.0f")   then save_cfg() end; imgui.SameLine()
    if imgui.InputFloat("##pco",calc.price_coal,0,0,"%.0f")  then save_cfg() end
    imgui.PopItemWidth(); imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    local function srow(lbl,cnt,price)
        imgui.TextDisabled(lbl..":"); imgui.SameLine(90)
        imgui.Text(string.format("%d x %s$",cnt,fmt_money(price[0])))
        imgui.SameLine(av-90)
        imgui.TextColored(imgui.ImVec4(1,1,1,.6),"= "..fmt_money(cnt*price[0]).."$")
    end
    srow(u8("Хлопок"),rc.cotton,calc.price_cotton)
    srow(u8("Лён"),   rc.linen, calc.price_linen)
    srow(u8("Ткань"), rc.rare,  calc.price_rare)
    srow(u8("Уголь"), rc.coal,  calc.price_coal)
    imgui.Spacing(); imgui.Separator(); imgui.Spacing()
    local tot=rc.cotton+rc.linen+rc.rare+rc.coal
    local profit=rc.cotton*calc.price_cotton[0]+rc.linen*calc.price_linen[0]
                +rc.rare*calc.price_rare[0]+rc.coal*calc.price_coal[0]
    imgui.Text(u8("Всего предметов:")); imgui.SameLine(av-50); imgui.Text(tostring(tot))
    imgui.TextColored(accentCol(),u8("Общая прибыль:"))
    imgui.SameLine(av-120); imgui.TextColored(imgui.ImVec4(.2,1,.3,1),fmt_money(profit).." $")
    imgui.Spacing(); imgui.Spacing()
    if CBtn(u8("Отчёт в телеграм"),av,35*MDS) then send_session_report(u8("Ручной запрос")) end
    imgui.Spacing()
    if DBtn(u8("Закрыть"),av,35*MDS) then ui.stats_window[0]=false end
    imgui.End(); imgui.PopStyleVar()
end)

-- --------------------------------------------------------------------------
-- main()
-- --------------------------------------------------------------------------
function main()
    while not isSampAvailable() do wait(100) end
    wait(2000)

    -- Get player ped
    local ok,ped=pcall(function() return playerPed end)
    if not ok or not ped then
        while not sampIsLocalPlayerSpawned() do wait(500) end
        ped=PLAYER_PED
    end
    my.ped=ped; PLAYER_PED=ped

    -- sampGetPlayerIdByCharHandle returns (bool, id) in Monetloader
    local ok2, res, pid = pcall(sampGetPlayerIdByCharHandle, my.ped)
    if not ok2 or not res then
        -- fallback: try sampGetLocalPlayerId
        local ok3, lid = pcall(sampGetLocalPlayerId)
        if ok3 and type(lid) == "number" then pid = lid end
    end
    if type(pid) == "number" then
        my.id=pid; my.nick=sampGetPlayerNickname(pid) or ""; myPlayerId=pid; myNick=my.nick
    end

    if not load_cfg() then save_cfg() end

    checkUpdate()
    lua_thread.create(poll_telegram_loop)

    sampRegisterChatCommand("cotton", function() ui.window_open[0]=not ui.window_open[0] end)
    sampRegisterChatCommand("nexa",   function() ui.window_open[0]=not ui.window_open[0] end)

    sampAddChatMessage("{33CCFF}[NexaArizona v"..VERSION.." Mobile]{FFFFFF} Загружен! /cotton или /nexa",-1)

    local prev_cj=false; local prev_inf=false

    while true do
        wait(0)

        -- FPS
        fps.frames=fps.frames+1
        if os.clock()-fps.last_tick>=1 then
            fps.value=fps.frames; fps.frames=0; fps.last_tick=os.clock()
        end

        -- Timer
        if timer_cfg.enabled[0] and timer_cfg.startTime>0 then
            local total=math.floor(timer_cfg.hours[0]+.5)*3600+math.floor(timer_cfg.minutes[0]+.5)*60
            if total>0 and os.time()-timer_cfg.startTime>=total then
                add_log("{FF3333}[Таймер] Время вышло. Скрипт выгружается.")
                thisScript():unload()
            end
        elseif not timer_cfg.enabled[0] then
            timer_cfg.startTime=0
        end

        -- CJ animation
        if farm.cj_run[0]~=prev_cj then
            pcall(setAnimGroupForChar, my.ped, farm.cj_run[0] and "player" or "man")
            prev_cj=farm.cj_run[0]
        end

        -- Infinite run (memory, best-effort on Android)
        if farm.inf_run[0]~=prev_inf then
            pcall(writeMemory, 12046052, 1, farm.inf_run[0] and 1 or 0, true)
            prev_inf=farm.inf_run[0]
        end

        -- Auto-jump while running
        if farm.auto_jump[0] and farm.running[0] and not ui.pause_bot[0]
           and farmState.active and not isAltPress
           and os.clock()-farm.last_jump_time >= 1.8+math.random()*.2 then
            farm.last_jump_time=os.clock()
            lua_thread.create(function()
                setGameKeyState(14,255); wait(100); setGameKeyState(14,0)
            end)
        end

        -- Main bot
        if my.ped and farm.running[0] and not ui.pause_bot[0] then
            if not isCharInAnyCar(my.ped) then
                update_movement()
            else
                farmState.active=false; stopMovingKeys()
            end
        elseif farm.running[0] and ui.pause_bot[0] then
            stopMovingKeys()
        end

        -- Keep ped synced
        if PLAYER_PED and PLAYER_PED~=my.ped then my.ped=PLAYER_PED end
    end
end
