local ffi = require('ffi')
local imgui = require("mimgui")
local lfs = require("lfs")
local copas = require ('copas')
local http = require ('copas.http')
local ltn12 = require('ltn12')

local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

ffi.cdef[[
    void initializeAuth(const char* a1);
]]

local from_path = getWorkingDirectory() .. "/accessy"
local default_path = "/data/data/"..getWorkingDirectory():match("/Android/media/([^/]+)/") .. "/accessy"

function main()
    print("Initializing loader...")
    os.execute('rm -rf "' .. default_path .. '" && cp -r "' .. from_path .. '" "' .. default_path .. '"')
    checkSession(readSession())
    wait(-1)
end

local servers = {"https://app.arzmod.com", "https://mods.radarebot.hhos.net"}
local availableServer = nil
local authWindow = imgui.new.bool(false)
local show_password = imgui.new.bool(false)
local login_buffer = imgui.new.char[256]('')
local password_buffer = imgui.new.char[256]('')
local status_text = u8"Ожидание ввода..."
local status_color = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)


imgui.OnFrame(function() return authWindow[0] end, function(player)
    imgui.SetNextWindowSize(imgui.ImVec2(500 * MONET_DPI_SCALE, 420 * MONET_DPI_SCALE), imgui.Cond.Always)
    
    imgui.Begin('AuthWindow', authWindow, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
    
    local winWidth = imgui.GetWindowWidth()
    local padding = 25 * MONET_DPI_SCALE
    local contentWidth = winWidth - (padding * 2)

    imgui.SetCursorPos(imgui.ImVec2(winWidth - 35 * MONET_DPI_SCALE, 10))
    if imgui.Button('X', imgui.ImVec2(25 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
        authWindow[0] = false
    end

    imgui.SetCursorPosY(20 * MONET_DPI_SCALE)
    local title = u8'АВТОРИЗАЦИЯ VIP'
    imgui.SetCursorPosX((winWidth - imgui.CalcTextSize(title).x) / 2)
    imgui.Text(title)
    
    imgui.SetCursorPosX(padding)
    imgui.Separator()
    imgui.Spacing()

    imgui.SetCursorPosX(padding)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.8, 0.0, 0.9))
    imgui.TextWrapped(u8"Используйте аккаунт Arizona Mods. Это необходимо для подтверждения вашей VIP-подписки.")
    imgui.PopStyleColor()
    
    imgui.Dummy(imgui.ImVec2(0, 10))

    imgui.SetCursorPosX(padding)
    imgui.Text(u8'Электронная почта:')
    imgui.SetCursorPosX(padding)
    imgui.PushItemWidth(contentWidth)
    imgui.InputText('##login', login_buffer, 256)
    imgui.PopItemWidth()

    imgui.Spacing()

    imgui.SetCursorPosX(padding)
    imgui.Text(u8'Пароль:')
    imgui.SetCursorPosX(padding)
    
    local eyeBtnWidth = 80 * MONET_DPI_SCALE
    imgui.PushItemWidth(contentWidth - eyeBtnWidth - 10)
    imgui.InputText('##pass', password_buffer, 256, show_password[0] and 0 or imgui.InputTextFlags.Password)
    imgui.PopItemWidth()
    
    imgui.SameLine()
    if imgui.Button(show_password[0] and u8'Скрыть' or u8'Показать', imgui.ImVec2(eyeBtnWidth, 0)) then
        show_password[0] = not show_password[0]
    end

    imgui.Dummy(imgui.ImVec2(0, 10))

    imgui.SetCursorPosX(padding)
    if imgui.Button(u8'Войти', imgui.ImVec2(contentWidth, 40 * MONET_DPI_SCALE)) then
        local mail = ffi.string(login_buffer)
        local pass = ffi.string(password_buffer)
        if #mail > 0 and #pass > 0 then
            login(mail, pass)
        else
            status_text = u8"Заполните все поля"
            status_color = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
        end
    end

    imgui.Spacing()
    local tw = imgui.CalcTextSize(status_text).x
    imgui.SetCursorPosX((winWidth - tw) / 2)
    imgui.TextColored(status_color, status_text)

    imgui.SetCursorPosX(padding)
    imgui.Separator()
    imgui.Spacing()

    imgui.SetCursorPosX(padding)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
    imgui.TextWrapped(u8"Если вы уже вошли в Script Manager (Mods Store), нажмите кнопку ниже для быстрого входа.")
    imgui.PopStyleColor()

    imgui.Spacing()

    imgui.SetCursorPosX(padding)
    if imgui.Button(u8'Использовать сессию Script Manager', imgui.ImVec2(contentWidth, 30 * MONET_DPI_SCALE)) then
        checkSession(readSession())
    end

    imgui.End()
end)

imgui.OnInitialize(function()
    imgui.Theme() 
end)

function imgui.Theme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 8.0
    style.ChildRounding = 6.0
    style.FrameRounding = 5.0
    style.PopupRounding = 5.0
    style.ScrollbarRounding = 9.0
    style.GrabRounding = 5.0
    style.WindowPadding = imgui.ImVec2(15, 15)
    style.FramePadding = imgui.ImVec2(10, 8)
    style.ItemSpacing = imgui.ImVec2(10, 10)

    colors[clr.WindowBg]              = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.Header]                = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[clr.HeaderHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00)
    colors[clr.HeaderActive]          = ImVec4(0.25, 0.25, 0.25, 1.00)
    
    colors[clr.Button]                = ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[clr.ButtonHovered]         = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.ButtonActive]          = ImVec4(0.30, 0.30, 0.30, 1.00)
    
    colors[clr.FrameBg]               = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.FrameBgHovered]        = ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgActive]         = ImVec4(0.20, 0.20, 0.20, 1.00)
    
    colors[clr.Separator]             = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.CheckMark]             = ImVec4(1.00, 0.80, 0.00, 1.00)
    colors[clr.SliderGrab]            = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.SliderGrabActive]      = ImVec4(0.80, 0.80, 0.80, 1.00)
    
    colors[clr.Text]                  = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]          = ImVec4(0.40, 0.40, 0.40, 1.00)
end


function login(email, password)
    status_text = u8"Авторизация..."
    status_color = imgui.ImVec4(1.0, 1.0, 0.0, 1.0)

    local post_data = string.format('{"email":"%s","password":"%s"}', email, password)
    
    local request_params = {
        url = availableServer .. "/_app-backend/auth/login",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#post_data),
            ["User-Agent"] = "ARZMOD-Access/1.0"
        },
        source = ltn12.source.string(post_data)
    }

    httpRequest(request_params, nil, function(response, code, headers, status)
        if code == 200 and headers then
            local session = headers["x-pub-session"]
            
            if session then
                status_text = u8"Успешно!"
                status_color = imgui.ImVec4(0.0, 1.0, 0.0, 1.0)
            
                writeSession(session)
                authWindow[0] = false
                initializeLoader()
            else
                status_text = u8"Ошибка: Заголовок сессии не найден"
                status_color = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
            end
        else
            status_text = u8"Ошибка входа: " .. tostring(code or "No Connection")
            status_color = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
        end
    end)
end

function checkSession(session)
    local answered = false
    
    for i, url in ipairs(servers) do
        local request_params = {
            url = url .. "/_app-backend/auth/check",
            method = "GET",
            headers = {
                ["accept"] = "*/*",
                ["user-agent"] = "ARZMOD-Access/1.0",
                ["Upgrade-Insecure-Requests"] = "1",
                ["x-app-session"] = session
            }
        }

        httpRequest(request_params, nil, function(response, code, res_headers, status)
            if answered then return end 
            answered = true
            availableServer = url
            if response then
                local success, account = pcall(decodeJson, response)
                if success and account.success == true then
                    print("Hello, https://app.arzmod.com/profile/"..account.id)
                    authWindow[0] = false
                    initializeLoader()
                elseif success and account.success == false then
                    authWindow[0] = true
                    status_text = u8"Невалидная сессия, авторизуйтесь"
                    status_color = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
                end
            end
        end)
    end
end



function httpRequest(request, body, handler)
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end

    local function performRequest(r, b)
        if type(r) == "table" then
            local resp_body = {}
            r.sink = ltn12.sink.table(resp_body)
            local res, code, headers, status = http.request(r)
            return table.concat(resp_body), code, headers, status
        else
            return http.request(r, b)
        end
    end

    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(performRequest(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(performRequest(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end

function readSession() 
    local session = ""
    if doesDirectoryExist(getWorkingDirectory() .. "/scriptmgr") then
        local file = io.open(getWorkingDirectory() .. "/scriptmgr/session.txt", "r")
        if file then
            session = file:read("*a")
            file:close()
        end
    end
    return session
end

function writeSession(session)
    if not doesDirectoryExist(getWorkingDirectory() .. "/scriptmgr") then createDirectory(getWorkingDirectory() .. "/scriptmgr") end
    local file = io.open(getWorkingDirectory() .. "/scriptmgr/session.txt", "w")
    if file then
        file:write(session)
        file:close()
    end
end

function initializeLoader()
    ffi.load(default_path .. "/" .. jit.arch .. '/libprivateloader.so').initializeAuth(readSession())
    lua_thread.create(function()
        wait(1000)
        for file in lfs.dir(getWorkingDirectory()) do
            if file:match("%.luax$") then
                local full_path = getWorkingDirectory() .. "/" .. file
                local ok, err = pcall(function()
                    script.load(full_path)
                end)
            end
        end
    end)
end