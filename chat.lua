Hooks:Add("LocalizationManagerPostInit", "WorRep_loc", function(...)				
	LocalizationManager:add_localized_strings({
		WorRep_type_the_word = "Please type the words after the tag.",
		WorRep_list_title = "Word Replacer List",
		WorRep_list_text = "Choose one of the replacer \n to remove it from the list.",
		WorRep_list_is_empty = "The list is empty.",
		WorRep_list_confirm_title = "Confirm the removal",
		WorRep_manage_saved_replacements = "Managing saved replacements",
		WorRep_manage_saved_replacements_text = "Select one of the words,\nto remove from the replacement.",
		WorRep_replacements = " replacements:",
		WorRep_added = " added",
		WorRep_removed = " removed",
	})
		
	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			WorRep_type_the_word = "Пожалуйста введите слова после тэга.",
			WorRep_list_title = "Список заменителей слов",
			WorRep_list_text = "Выберете один из заменителей, \n чтобы удалить его из списка.",
			WorRep_list_is_empty = "Список пуст.",
			WorRep_list_confirm_title = "Подтвердите удаление",
			WorRep_manage_saved_replacements = "Управление сохраненными заменами",
			WorRep_manage_saved_replacements_text = "Выберите одно из слов,\nчтобы удалить из замены.",
			WorRep_replacements = " заменители:",
			WorRep_added = " добавлено",
			WorRep_removed = " удалено",
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
		
		table.insert(dialog_data.button_list, {
			callback_func = function()
				self:_dialog_word_list()
			end
		})
	end
	
	table.insert(dialog_data.button_list, {
		text = managers.localization:text("menu_back"),
		cancel_button = true
	})		
	
	managers.system_menu:show_buttons(dialog_data)
end

function WorRep:_dialog_check_replacements(word)
	local dialog_data = {
		title = managers.localization:text("WorRep_manage_saved_replacements"),
		text = managers.localization:text("WorRep_manage_saved_replacements_text"),
		focus_button = 1,
		button_list = {}
	}

	if type(WorRep.settings.strings[word]) == "table" and table.size(WorRep.settings.strings[word]) > 0 then
		for _, name in pairs(WorRep.settings.strings[word]) do
			table.insert(dialog_data.button_list, {
				text = name,
				callback_func = function()
					self:_dialog_confirm_remove(word, name)
				end
			})
		end
	else
		table.insert(dialog_data.button_list, {
			text = WorRep.settings.strings[word],
			callback_func = function()
				self:_dialog_confirm_remove(word, WorRep.settings.strings[word])
			end
		})
	end
	
	table.insert(dialog_data.button_list, {
		callback_func = function()
			self:_dialog_check_replacements(word)
		end
	})
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
					if type(WorRep.settings.strings[word]) == "table" then
						if table.size(WorRep.settings.strings[word]) > 2 then
							table.delete(WorRep.settings.strings[word], name)
						else
							table.delete(WorRep.settings.strings[word], name)
							WorRep.settings.strings[word] = WorRep.settings.strings[word][1]
						end
					else
						WorRep.settings.strings[word] = nil
					end
					
					WorRep:Save()
					if WorRep.settings.strings[word] then
						self:_dialog_check_replacements(word, WorRep.settings.strings[word])
					else
						self:_dialog_word_list()
					end
				end
			},
			{
				callback_func = function()
					self:_dialog_confirm_remove(word, name)
				end
			},
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
	local add = 0
	local rem = 0
	if table.size(list) > 1 then
		for id, replacement in pairs(list) do
			if id ~= 1 then
				if not WorRep.settings.strings[list[1]] then
					WorRep.settings.strings[list[1]] = replacement
					add = add + 1
				elseif type(WorRep.settings.strings[list[1]]) == "string" then
					if WorRep.settings.strings[list[1]] == replacement then
						WorRep.settings.strings[list[1]] = nil
						rem = rem + 1
					else
						WorRep.settings.strings[list[1]] = {WorRep.settings.strings[list[1]], replacement}
						add = add + 1
					end
				elseif type(WorRep.settings.strings[list[1]]) == "table" then
					if table.contains(WorRep.settings.strings[list[1]], replacement) then
						if table.size(WorRep.settings.strings[list[1]]) > 2 then
							table.delete(WorRep.settings.strings[list[1]], replacement)
						else
							table.delete(WorRep.settings.strings[list[1]], replacement)
							WorRep.settings.strings[list[1]] = WorRep.settings.strings[list[1]][1]
						end
						rem = rem + 1
					else
						table.insert(WorRep.settings.strings[list[1]], replacement)
						add = add + 1
					end
				end
			end
		end

		local added = add > 0 and "\n"..add..managers.localization:text("WorRep_added") or ""
		local removed = rem > 0 and "\n"..rem..managers.localization:text("WorRep_removed") or ""
		feed("'" .. list[1] .. "'".. managers.localization:text("WorRep_replacements") .. added .. removed)
		WorRep:Save()
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
	if message == "EDIT" or message == "edit" or message == "'" or message == "`" or message == "~" then
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
	local wr = utf8.to_upper("Edit:")
	local chat = utf8.to_upper(managers.localization:text("debug_chat_say"))
	
	if console and say:text() ~= wr then
		say:set_text(wr)
		say:set_color(tweak_data.screen_colors.skill_color)
	elseif not console and say:text() ~= chat then
		say:set_text(chat)
		say:set_color(tweak_data.screen_colors.text)
	end
end)