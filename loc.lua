local data = LocalizationManager.text
function LocalizationManager:text(string_id, macros)
	local str = data(self, string_id, macros)

	if WorRep.settings.strings then
		for word, replacement in pairs(WorRep.settings.strings) do
			if type(replacement) == "table" then
				str = str:gsub(word, table.random(replacement))
			else
				str = str:gsub(word, replacement)
			end
		end
	end
	
	return str
end 