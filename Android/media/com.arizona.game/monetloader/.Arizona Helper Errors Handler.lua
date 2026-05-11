-- DONT SEND ME THIS FILE, THIS IS NOT AN ERROR, BUT A SCRIPT TO DISPLAY THE ERROR IN DIALOG
-- НЕ ОТПРАВЛЯЙТЕ МНЕ ЭТОТ ФАЙЛ, ЭТО НЕ ОШИБКА, ЭТО СКРИПТ ДЛЯ ПОКАЗА ОШИБКИ ВАМ В ДИАЛОГЕ
function onSystemMessage(msg, type, script)
	if script and script.name == 'Arizona&Rodina Helper' and msg and ((msg:find('stack traceback')) or (type == 3 and not msg:find('Script died due to an error'))) then
		local errorMessage = ('{ffffff}Произошла непредусмотренная ошибка в работе скрипта, из-за чего он был отключён!\n\n' ..
		'Отправьте скриншот в {ff9900}тех.поддержку MTG MODS (Telegram/Discord/BlastHack){ffffff}.\n\n' ..
		'Детали возникшей ошибки:\n{ff6666}' .. msg)
		sampShowDialog(123123, '{009EFF}Arizona&Rodina Helper [' .. script.version .. ']', errorMessage, 'Закрыть диалог', '', 0)
	end
end
    