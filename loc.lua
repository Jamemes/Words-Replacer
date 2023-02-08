local data = LocalizationManager.text
function LocalizationManager:text(string_id, macros)
	local str = data(self, string_id, macros)

	if WorRep.settings.strings then
		for str1, str2 in pairs(WorRep.settings.strings) do
			str = str:gsub(str1, str2)
		end
	end
	
	return str
end 