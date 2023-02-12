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


local function feed(text)
	return managers.chat:feed_system_message(ChatManager.GAME, text)
end

local function fine_text(text)
	local x, y, w, h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end	

function WorRep:_dialog_word_list()
	local dialog_data = {
		title = managers.localization:text("WorRep_list_title"),
		text = managers.localization:text(table.size(WorRep.settings.strings) > 0 and "WorRep_list_text" or "WorRep_list_is_empty"),
		focus_button = 1,
		button_list = {}
	}
	
	if table.size(WorRep.settings.strings) > 0 then
		for word, rep in pairs(WorRep.settings.strings) do
			table.insert(dialog_data.button_list, 1, {
				text = tostring(word .. " " .. (type(rep) == "table" and "(" .. table.size(rep) .. ")" or "(1)")),
				callback_func = function()
					self:_dialog_check_replacements(word)
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

function WorRep:_dialog_check_replacements(word)
	local dialog_data = {
		title = managers.localization:text("WorRep_list_confirm_title"),
		text = type(WorRep.settings.strings[word]) ~= "table" and tostring(word .. " -> " .. WorRep.settings.strings[word]) or "",
		focus_button = 1,
		button_list = {
			{
				text = managers.localization:text("cn_menu_accept_contract"),
				callback_func = function()
					WorRep.settings.strings[word] = nil
					WorRep:Save()
					self:_dialog_word_list()
				end
			}
		}
	}

	if type(WorRep.settings.strings[word]) == "table" then
		dialog_data.title = managers.localization:text("WorRep_manage_saved_replacements")
		dialog_data.button_list = {}
		for _, name in pairs(WorRep.settings.strings[word]) do
			table.insert(dialog_data.button_list, {
				text = name,
				callback_func = function()
					self:_dialog_confirm_remove(word, name)
				end
			})
		end
	end
	
	table.insert(dialog_data.button_list, {})
	table.insert(dialog_data.button_list, {
		text = managers.localization:text("menu_back"),
		cancel_button = true,
		callback_func = function()
			self:_dialog_word_list()
		end
	})
	
	managers.system_menu:show_buttons(dialog_data)
end

function WorRep:_dialog_confirm_remove(word, name)
	local dialog_data = {
		title = managers.localization:text("WorRep_list_confirm_title"),
		text = type(name) ~= "table" and tostring(word .. " -> " .. name) or "",
		focus_button = 1,
		button_list = {
			{
				text = managers.localization:text("cn_menu_accept_contract"),
				callback_func = function()
					if table.size(WorRep.settings.strings[word]) > 2 then
						table.delete(WorRep.settings.strings[word], name)
					else
						table.delete(WorRep.settings.strings[word], name)
						WorRep.settings.strings[word] = WorRep.settings.strings[word][1]
					end
					
					WorRep:Save()
					self:_dialog_check_replacements(word, WorRep.settings.strings[word])
				end
			},
			{},
			{
				text = managers.localization:text("menu_back"),
				cancel_button = true,
				callback_func = function()
					self:_dialog_check_replacements(word, WorRep.settings.strings[word])
				end
			}
		}
	}
	
	managers.system_menu:show_buttons(dialog_data)
end

function WorRep:_add_words_to_the_list(list)
	if table.size(list) > 1 then
		for id, replacement in pairs(list) do
			if id ~= 1 then
				if not WorRep.settings.strings[list[1]] then
					WorRep.settings.strings[list[1]] = replacement
				elseif type(WorRep.settings.strings[list[1]]) == "string" then
					if WorRep.settings.strings[list[1]] == replacement then
						WorRep.settings.strings[list[1]] = nil
					else
						WorRep.settings.strings[list[1]] = {WorRep.settings.strings[list[1]], replacement}
					end
				elseif type(WorRep.settings.strings[list[1]]) == "table" then
					if table.contains(WorRep.settings.strings[list[1]], replacement) then
						if table.size(WorRep.settings.strings[list[1]]) > 2 then
							table.delete(WorRep.settings.strings[list[1]], replacement)
						else
							table.delete(WorRep.settings.strings[list[1]], replacement)
							WorRep.settings.strings[list[1]] = WorRep.settings.strings[list[1]][1]
						end
					else
						table.insert(WorRep.settings.strings[list[1]], replacement)
					end
				end

				WorRep:Save()
			end
		end
	else
		feed(managers.localization:text("WorRep_type_the_word"))
	end
end

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_WorRep", function(...)
	WorRep:Load()
end)

local console = false
local data = ChatManager.send_message
function ChatManager:send_message(channel_id, sender, message)
	if message == "`" or message == "~" then
		if not console then
			console = true
			return
		else
			console = false
			return
		end
	end
	
	if console then
		if message:find("help") == 1 and 4 then
			if message == "help /" then
				feed("\nAdd replacements: [word]/[replacement1]/[replacement2]/...\nIf you typing existing replacement word it will be removed from the table.")
			elseif message == "help list" or message == "help l" or message == "help 1" then
				feed("Opens replacements list.")
			elseif message == "help file" then
				feed("Opens replacements save file.")
			else
				feed("\n/" .. "\nlist, l, 1," .. "\nfile")
			end
		elseif message:find("/") then
			WorRep:_add_words_to_the_list(string.split(message, "/"))
		elseif message == "1" or message == "l" or message == "list" then
			WorRep:_dialog_word_list()
		elseif message == "file" then
			os.execute("start "..WorRep._setting_path)
		else
			LocalizationManager:add_localized_strings({WorRep_check_word = message})
			feed(managers.localization:text("WorRep_check_word"))
		end
	else
		data(self, channel_id, sender, message)
	end
end

Hooks:PostHook(ChatGui, "enter_key_callback", "WoRe_change_chat_mode_text", function(self, ...)
	local say = self._input_panel:child("say")
	local input_text = self._input_panel:child("input_text")
	
	if console then
		say:set_text(utf8.to_upper("Console:"))
		fine_text(say)
		say:set_rotation(360)
		say:set_right(input_text:left() - 4)
		say:set_color(tweak_data.screen_colors.skill_color)
	else
		say:set_text(utf8.to_upper(managers.localization:text("debug_chat_say")))
		fine_text(say)
		say:set_right(input_text:left() - 4)
		say:set_color(tweak_data.screen_colors.text)
	end
end)

-- local data = ChatManager.send_message
-- function ChatManager:send_message(channel_id, sender, message)
	-- local sep = string.find(message, "~") and "~" or string.find(message, "|||") and "|||" or string.find(message, "   ") and "   " or false
	
	-- local function m(str)
		-- return message == str
	-- end
	
	-- local function exclude(t, e)
		-- local filtered = {}

		-- for _, v in ipairs(t) do
			-- if v ~= e then
				-- table.insert(filtered, v)
			-- end
		-- end

		-- return filtered
	-- end

	-- local list = sep and (m(sep.."1") or m(sep.."l") or m(sep.."list"))
	-- local check = sep and (message:match(sep.."check") or message:match(sep.."2") or message:match(sep.."c"))
	-- local find = sep and (m(sep.."3") or m(sep.."f") or m(sep.."find"))
	
	-- local words = sep and string.split(message, sep) or {}

	-- if words[1] and words[2] then
		-- WorRep.settings.strings[words[1]] = tostring(words[2])
		-- WorRep:Save()
		-- managers.chat:feed_system_message(ChatManager.GAME, words[1]..managers.localization:text("WorRep_string_replaced")..words[2])
	-- elseif words[1] then
		-- if table.has(WorRep.settings.strings, words[1]) then
			-- WorRep.settings.strings[words[1]] = nil
			-- WorRep:Save()
			-- managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_string_deleted", {WRD = words[1]}))
		-- elseif list then
			-- WorRep:_dialog_word_list()
		-- elseif check then
			-- if message:gsub(tostring(check), "") ~= "" then
				-- LocalizationManager:add_localized_strings({WorRep_check_word = message:gsub(tostring(check), "")})
				-- managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_check_word"))
			-- else
				-- managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_type_the_word"))
			-- end
		-- elseif find then
			-- os.execute("start "..WorRep._setting_path)
		-- else
			-- managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("WorRep_string_not_exist"))
		-- end
	-- else
		-- data(self, channel_id, sender, message)
	-- end
-- end