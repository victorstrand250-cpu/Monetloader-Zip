-- ============================================================
-- minebot.lua — бот для GTA SA:MP через MoonLoader
-- ============================================================
-- Требования:
--   - GTA San Andreas + SA:MP
--   - MoonLoader (moonloader.log должен существовать)
--   - bot_helper.dll в той же папке что и этот скрипт
-- ============================================================

-- Настройки
local DLL_PATH    = "moonloader/lib/bot_helper.dll"   -- путь к DLL
local COMMAND_ID  = 358                                -- номер команды SA:MP

-- ============================================================

-- Проверяем что MoonLoader запущен
local function is_moonloader_running()
    local f = io.open("moonloader.log", "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Проверяем что DLL существует на диске
local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Отправляем команду через DLL
local function send_command(command_id)
    local lib_ok, lib_handle = loadDynamicLibrary(DLL_PATH)
    if not lib_ok then
        print("[minebot] Ошибка: не удалось загрузить " .. DLL_PATH)
        return false
    end

    local proc_ok, proc_handle = getDynamicLibraryProcedure("_sendCommand@4", lib_handle)
    if not proc_ok or not proc_handle then
        print("[minebot] Ошибка: функция _sendCommand@4 не найдена в DLL")
        return false
    end

    -- callFunction(функция, конвенция_вызова, тип_возврата, аргумент)
    -- конвенция 1 = stdcall, тип возврата 0 = void
    callFunction(proc_handle, 1, 0, command_id)
    return true
end

-- ============================================================
-- Точка входа
-- ============================================================

if not is_moonloader_running() then
    print("[minebot] MoonLoader не запущен, выход")
    return
end

if not file_exists(DLL_PATH) then
    print("[minebot] Файл не найден: " .. DLL_PATH)
    print("[minebot] Положи bot_helper.dll в папку moonloader/lib/")
    return
end

local ok = send_command(COMMAND_ID)
if ok then
    print("[minebot] Команда " .. COMMAND_ID .. " отправлена")
end
