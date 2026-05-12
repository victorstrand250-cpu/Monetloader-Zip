script_name('InfiniteRun')
script_author('claude')
script_version('1.0')

local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local fa = require('Fawesome6_solid')
local jsoncfg = require 'jsoncfg'

local cfg = jsoncfg.load({
    main = {
        sprint = true,
        breath = true,
    }
}, 'InfiniteRun.json')

function save()
    jsoncfg.save(cfg, 'InfiniteRun.json')
end

local mds = MONET_DPI_SCALE
local win = imgui.new.bool(false)
local chkSprint = imgui.new.bool(cfg.main.sprint)
local chkBreath = imgui.new.bool(cfg.main.breath)

imgui.OnFrame(
    function() return win[0] end,
    function(self)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 440 * mds, 235 * mds
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        if imgui.Begin('IR_win', win, imgui.WindowFlags.NoTitleBar) then
            if imgui.BeginChild('IR_title', imgui.ImVec2(0, 45 * mds), true) then
                imgui.SetCursorPos(imgui.ImVec2(0, 12 * mds))
                imgui.CenterText(fa.PERSON_RUNNING .. u8' Áåñêîíå÷íûé áåã / äûõàëêà')
                imgui.SetCursorPos(imgui.ImVec2(5 * mds, 7 * mds))
                if imgui.Button(fa.XMARK .. '', imgui.ImVec2(30 * mds, 30 * mds)) then
                    win[0] = false
                end
                imgui.EndChild()
            end
            if imgui.BeginChild('IR_main', imgui.ImVec2(), true) then
                if imgui.Checkbox(fa.PERSON_RUNNING .. u8' Áåñêîíå÷íûé áåã (âûíîñëèâîñòü)', chkSprint) then
                    cfg.main.sprint = chkSprint[0]
                    save()
                end
                imgui.Spacing()
                if imgui.Checkbox(fa.WIND .. u8' Áåñêîíå÷íàÿ äûõàëêà (ïîä âîäîé)', chkBreath) then
                    cfg.main.breath = chkBreath[0]
                    save()
                end
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                imgui.TextDisabled(u8'Àêòèâàöèÿ: /infrun')
                imgui.EndChild()
            end
            imgui.End()
        end
    end
)

imgui.OnInitialize(function()
    SoftDarkTheme()
    imgui.GetIO().IniFilename = nil
    fa.Init(15 * mds)
end)

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function main()
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand('infrun', function()
        win[0] = not win[0]
    end)

    while not sampIsLocalPlayerSpawned() do wait(0) end

    msg(u8'Çàãðóæåí! Àêòèâàöèÿ: /infrun')

    while true do
        local ped = PLAYER_PED

        if cfg.main.sprint then
            -- keep sprint stamina at maximum so the bar never empties
            setCharStamina(ped, 150)
        end

        if cfg.main.breath then
            -- raise lung capacity stat to maximum so the player never drowns
            setPlayerStat(0, 24, 1000)
        end

        wait(50)
    end
end

function msg(text)
    sampAddChatMessage('{00FF7F}[InfiniteRun]: {FFFFFF}' .. text, -1)
end

function SoftDarkTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding     = imgui.ImVec2(15, 15)
    style.WindowRounding    = 20.0
    style.ChildRounding     = 20.0
    style.FramePadding      = imgui.ImVec2(8, 7)
    style.FrameRounding     = 20.0
    style.ItemSpacing       = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing  = imgui.ImVec2(10, 6)
    style.IndentSpacing     = 25.0
    style.ScrollbarSize     = 30.0
    style.ScrollbarRounding = 20.0
    style.GrabMinSize       = 10.0
    style.GrabRounding      = 6.0
    style.PopupRounding     = 20
    style.WindowTitleAlign  = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign   = imgui.ImVec2(0.5, 0.5)

    style.Colors[imgui.Col.Text]                 = imgui.ImVec4(0.90, 0.90, 0.93, 1.00)
    style.Colors[imgui.Col.TextDisabled]         = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.WindowBg]             = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ChildBg]              = imgui.ImVec4(0.18, 0.20, 0.22, 0.30)
    style.Colors[imgui.Col.PopupBg]              = imgui.ImVec4(0.13, 0.13, 0.15, 1.00)
    style.Colors[imgui.Col.Border]               = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.BorderShadow]         = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    style.Colors[imgui.Col.FrameBg]              = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.FrameBgHovered]       = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.FrameBgActive]        = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.TitleBg]              = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.TitleBgCollapsed]     = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    style.Colors[imgui.Col.TitleBgActive]        = imgui.ImVec4(0.15, 0.15, 0.17, 1.00)
    style.Colors[imgui.Col.MenuBarBg]            = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarBg]          = imgui.ImVec4(0.12, 0.12, 0.14, 1.00)
    style.Colors[imgui.Col.ScrollbarGrab]        = imgui.ImVec4(0.30, 0.30, 0.35, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.ScrollbarGrabActive]  = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.CheckMark]            = imgui.ImVec4(0.40, 0.90, 0.60, 1.00)
    style.Colors[imgui.Col.SliderGrab]           = imgui.ImVec4(0.40, 0.90, 0.60, 1.00)
    style.Colors[imgui.Col.SliderGrabActive]     = imgui.ImVec4(0.50, 1.00, 0.70, 1.00)
    style.Colors[imgui.Col.Button]               = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    style.Colors[imgui.Col.ButtonHovered]        = imgui.ImVec4(0.30, 0.80, 0.50, 1.00)
    style.Colors[imgui.Col.ButtonActive]         = imgui.ImVec4(0.25, 0.70, 0.45, 1.00)
    style.Colors[imgui.Col.Header]               = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.HeaderHovered]        = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.HeaderActive]         = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.Separator]            = imgui.ImVec4(0.40, 0.40, 0.45, 1.00)
    style.Colors[imgui.Col.SeparatorHovered]     = imgui.ImVec4(0.50, 0.50, 0.55, 1.00)
    style.Colors[imgui.Col.SeparatorActive]      = imgui.ImVec4(0.60, 0.60, 0.65, 1.00)
    style.Colors[imgui.Col.ResizeGrip]           = imgui.ImVec4(0.20, 0.20, 0.23, 1.00)
    style.Colors[imgui.Col.ResizeGripHovered]    = imgui.ImVec4(0.25, 0.25, 0.28, 1.00)
    style.Colors[imgui.Col.ResizeGripActive]     = imgui.ImVec4(0.30, 0.30, 0.34, 1.00)
    style.Colors[imgui.Col.Tab]                  = imgui.ImVec4(0.18, 0.20, 0.22, 1.00)
    style.Colors[imgui.Col.TabHovered]           = imgui.ImVec4(0.30, 0.80, 0.50, 1.00)
    style.Colors[imgui.Col.TabActive]            = imgui.ImVec4(0.25, 0.70, 0.45, 1.00)
end
