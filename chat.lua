Hooks:Add("LocalizationManagerPostInit", "WorRep_loc", function(...)				
	LocalizationManager:add_localized_strings({
		WorRep_string_replaced = " will be replaced to ",
		WorRep_string_deleted = "$WRD; will be removed from the word replacement list.",
		WorRep_string_not_exist = "This word is not exist in the list.",
		WorRep_type_the_word = "Please type the words after the tag.",
		WorRep_list_title = "Word Replacer List",
		WorRep_list_text = "Choose one of the replacer \n to remove it from the list.",
		WorRep_list_is_empty = "The list is empty.",
		WorRep_list_confirm_title = "Confirm the removal",
	})
		
	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			WorRep_string_replaced = " будет заменено на ",
			WorRep_string_deleted = "$WRD; будет удален из списка замены слов.",
			WorRep_string_not_exist = "Этого слова нет в списке.",
			WorRep_type_the_word = "Пожалуйста введите слова после тэга.",
			WorRep_list_title = "Список заменителей слов",
			WorRep_list_text = "Выберете один из заменителей, \n чтобы удалить его из списка.",
			WorRep_list_is_empty = "Список пуст.",
			WorRep_list_confirm_title = "Подтвердите удаление",
		})
	end
end)

_G.WorRep = _G.WorRep or {}
WorRep._mod_path = WorRep._mod_path or ModPath
WorRep._setting_path = SavePath .. "string_replacer.json"
WorRep.settings = WorRep.settings or {}

function WorRep:Save()
	local file = io.open(self._setting_path, "w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

function WorRep:Load()
	local file = io.open(self._setting_path, "r")
	if file then
		for k, v in pairs(json.decode(file:read("*all")) or {}) do
			self.settings[k] = v
		end
		file:close()
	else
		self.settings = {
			strings = {}
		}
		self:Save()
	end
end

function WorRep:_dialog_word_list()
	local dialog_data = {
		title = managers.localization:text("WorRep_list_title"),
		text = managers.localization:text(table.size(WorRep.settings.strings) > 0 and "WorRep_list_text" or "WorRep_list_is_empty"),
		focus_button = 1,
		button_list = {}
	}
	
	if table.size(WorRep.settings.strings) > 0 then
		for word, replacement in pairs(WorRep.settings.strings) do
			table.insert(dialog_data.button_list, 1, {
				text = tostring(word .. " -> " .. replacement),
				callback_func = function()
					self:_dialog_remove_confirm(word, replacement)
				end
			})
		end
		
		table.insert(dialog_data.button_list, {})
	end
	
	table.insert(dialog_data.button_list, {
		text = managers.localization:text("menu_back"),
		cancel_button = true
	})		
	
	managers.system_menu:show_buttons(dialog_data)
end

function WorRep:_dialog_remove_confirm(word, replacement)
	local dialog_data = {
		title = managers.localization:text("WorRep_list_confirm_title"),
		text = tostring(word .. " -> " .. replacement),
		focus_button = 1,
		button_list = {
			{
				text = managers.localization:text("cn_menu_accept_contract"),
				callback_func = function()
					WorRep.settings.strings[word] = nil
					WorRep:Save()
					self:_dialog_word_list()
				end
			},
			{},
			{
				text = managers.localization:text("menu_back"),
				cancel_button = true,
				callback_func = function()
					self:_dialog_word_list()
				end
			}
		}
	}
	managers.system_menu:show_buttons(dialog_data)
end

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_WorRep", function(...)
	WorRep:Load()
end)

local data = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	local sep = string.find(message, "~") and "~" or string.find(message, "|||") and "|||" or string.find(message, "   ") and "   " or false
	
	local function m(str)
		return message == str
	end
	
	local function exclude(t, e)
		local filtered = {}

		for _, v in ipairs(t) do
			if v ~= e then
				table.insert(filtered, v)
			end
		end

		return filtered
	end

	local list = sep and (m(sep.."1") or m(sep.."l") or m(sep.."list"))
	local check = sep and (message:match(sep.."check") or message:match(sep.."2") or message:match(sep.."c"))
	local find = sep and (m(sep.."3") or m(sep.."f") or m(sep.."find"))
	
	local words = sep and string.split(message, sep) or {}

	if words[1] and words[2] then
		WorRep.settings.strings[words[1]] = tostring(words[2])
		WorRep:Save()
		managers.chat:feed_system_message(ChatManager.GAME, words[1]..managers.localization:text("WorRep_string_replaced")..words[2])
	elseif words[1] then
		if table.has(WorRep.settings.strings, words[1]) then
			WorRep.settings.strings[words[1]] = nil
			WorRep:Save()
			managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_string_deleted", {WRD = words[1]}))
		elseif list then
			WorRep:_dialog_word_list()
		elseif check then
			if message:gsub(tostring(check), "") ~= "" then
				LocalizationManager:add_localized_strings({WorRep_check_word = message:gsub(tostring(check), "")})
				managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_check_word"))
			else
				managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_type_the_word"))
			end
		elseif find then
			os.execute("start "..WorRep._setting_path)
		else
			managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_string_not_exist"))
		end
	else
		data(self, channel_id, sender, message)
	end
end