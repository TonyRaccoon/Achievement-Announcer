ACAN = {}
ACAN.version = GetAddOnMetadata("AchievementAnnouncer","Version")
ACAN.date = GetAddOnMetadata("AchievementAnnouncer","X-Date")

ACAN.default_settings = {
	string = "has earned the achievement %a!",
	party = true,
	raid = false,
	announce_guild_achievements = false,
	custom_channels = ""
}

--- Events ---

function ACAN.OnLoad(self)					-- Fired on game load
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("ACHIEVEMENT_EARNED")
	
	SLASH_ACAN1, SLASH_ACAN2 = '/aa', '/achievementannouncer'
	SlashCmdList["ACAN"] = ACAN.OnCommand
end

function ACAN.OnEvent(self, event, ...)		-- Fired when a registered event is fired
	if event == "ACHIEVEMENT_EARNED" then
		local achID = ...
		local achLink = GetAchievementLink(achID)
		local _,_,_,_,_,_,_,_,_,_,_,isGuildAch = GetAchievementInfo(achID)
		
		if isGuildAch and not AA_Settings.announce_guild_achievements then return end -- Don't announce guild achievements if not enabled
		
		if AA_Settings.raid and IsInRaid() and GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1 then -- if announce to raid, in raid, and not queued up alone (if in LFR)
			SendChatMessage(ACAN.GetOutputString(achLink), "RAID")
		elseif AA_Settings.party and GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1 then -- if announce to party, in party, and not queued up alone (if in LFG)
			SendChatMessage(ACAN.GetOutputString(achLink), "PARTY")
		end
		
		if AA_Settings.custom_channels ~= "" then
			local channels = { strsplit(",",AA_Settings.custom_channels:gsub("%s+","")) }
			for _,v in pairs(channels) do
				local id,name = GetChannelName(v)
				if id and not name:find("^Trade - ") and not name:find("^General - ") and not name:find("^LocalDefense - ") then -- No Trade, General, or LocalDefense
					SendChatMessage(ACAN.GetOutputString(achLink), "CHANNEL", nil, id)
				end
			end
		end
		
	elseif event == "ADDON_LOADED" then
		local addonName = ...
		
		if addonName == "AchievementAnnouncer" then
			AA_Options:Hide() -- Blizzard bug: Options won't trigger OnShow unless you explicitly hide it first
			if not AA_Settings then AA_Settings = ACAN.default_settings end
			ACAN.ImportOlderSettings()
			AA_Settings.version = ACAN.version
			
			ACAN.InitializeWidgets()
		end
	end
end

function ACAN.OnCommand(cmd)				-- Fired on slash command
	if cmd == "v" or cmd == "ver" or cmd == "version" then
		ACAN.Msg(format("Version: %s (%s)", ACAN.version, ACAN.date))
	else
		InterfaceOptionsFrame_OpenToCategory("Achiev. Announcer")
		InterfaceOptionsFrame_OpenToCategory("Achiev. Announcer") -- Blizzard bug: Requires two calls to actually open to the correct panel
	end
end

--- Main functions ---

function ACAN.Msg(msg)						-- Sends a formatted message to the chat frame
	DEFAULT_CHAT_FRAME:AddMessage("|cffd2b48c[AchievementAnnouncer]|r "..msg)
end

function ACAN.GetOutputString(ach)			-- Returns the string to be sent
	if AA_Settings.string == "" then
		return ACAN.default_settings.string:gsub("%%a", ach)
	else
		return AA_Settings.string:gsub("%%a", ach)
	end
end

function ACAN.ImportOlderSettings()			-- Converts old settings
	if not AA_Settings.version then
		if AA_Settings.Party then
			AA_Settings.party = (AA_Settings.RandomParty and true or false)
		end
		
		if AA_Settings.Raid then
			AA_Settings.raid = (AA_Settings.Raid and true or false)
		end
		
		if AA_Settings.Guild then
			AA_Settings.announce_guild_achievements = (AA_Settings.Guild and true or false)
		end
		
		if AA_Settings.CustomChannels then
			if AA_Settings.CustomChannels == "" or not AA_Settings.CustomChannels then
				AA_Settings.custom_channels = ""
			else
				AA_Settings.custom_channels = AA_Settings.CustomChannels
			end
		end
		
		if AA_Settings.String then
			if AA_Settings.String == "" or not AA_Settings.String then
				AA_Settings.string = "has earned the achievement %a!"
			else
				AA_Settings.string = AA_Settings.String
			end
		end
		
		AA_Settings.Party = nil
		AA_Settings.RandomParty = nil
		AA_Settings.Raid = nil
		AA_Settings.RandomRaid = nil
		AA_Settings.Guild = nil
		AA_Settings.Say = nil
		AA_Settings.CustomChannels = nil
		AA_Settings.String = nil
		AA_Settings.BG = nil
	end
end

--- UI functions ---

function ACAN.InitializeWidgets()			-- Initializes options UI widgets
	AA_OptBut_Party:SetChecked(AA_Settings.party)
	AA_OptBut_Raid:SetChecked(AA_Settings.raid)
	AA_OptBut_Guild:SetChecked(AA_Settings.announce_guild_achievements)
	AA_Opt_String:SetText(AA_Settings.string)
	AA_Opt_CustomChannels:SetText(AA_Settings.custom_channels)
	
	AA_Opt_String:ClearFocus()
	AA_Opt_CustomChannels:ClearFocus()
end

--- UI events ---

function ACAN.OnOptionsLoaded(self)			-- Initialize Options panel
	self.name = "Achiev. Announcer"
	self.default = ACAN.OnDefaultsClicked
	InterfaceOptions_AddCategory(self)
	self.okay = ACAN.OnOptionsOkayClicked
end

function ACAN.OnOptionsShown()				-- Fired when options panel opens
	
end

function ACAN.OnOptionsHidden()				-- Fired when options panel closes
	
end

function ACAN.OnDefaultsClicked()			-- Fired when "Defaults" button is pressed
	AA_Settings = ACAN.deepcopy(ACAN.default_settings)
	AA_Settings.version = ACAN.version
	ACAN.InitializeWidgets()
end

function ACAN.OnOptionsOkayClicked()		-- Fired when "Okay" is clicked
	AA_Settings.string = AA_Opt_String:GetText()
	AA_Settings.custom_channels = AA_Opt_CustomChannels:GetText()
end

function ACAN.OnWidgetUsed(self)			-- Fired when an options panel widget is used
	PlaySound("igMainMenuOptionCheckBoxOn")
	
	if self:GetName() == "AA_OptBut_Party" then
		AA_Settings.party = (self:GetChecked() and true or false)
	
	elseif self:GetName() == "AA_OptBut_Raid" then
		AA_Settings.raid = (self:GetChecked() and true or false)
	
	elseif self:GetName() == "AA_OptBut_Guild" then
		AA_Settings.announce_guild_achievements = (self:GetChecked() and true or false)
	
	elseif self:GetName() == "AA_OptBut_DefaultString" then
		AA_Opt_String:SetText(ACAN.default_settings.string)
	
	end
end

function ACAN.OnEditboxFocused(self)		-- Fired when an editbox is focused
	self.previous_value = self:GetText()
end

function ACAN.OnEditboxEnterPressed(self)	-- Fired when Enter is pressed in an editbox
	self:ClearFocus()
	if self:GetName() == "AA_Opt_String" then
		AA_Settings.string = self:GetText()
	elseif self:GetName() == "AA_Opt_CustomChannels" then
		AA_Settings.custom_channels = self:GetText()
	end
end

function ACAN.OnEditboxEscapePressed(self)	-- Fired when Escape is pressed in an editbox
	self:SetText(self.previous_value)
	self:ClearFocus()
end

--- Debug functions ---

function ACAN.test(id)						-- Generate a fake achievement
	if id == nil then id = 123 end
	ACAN.OnEvent(self, "ACHIEVEMENT_EARNED", id)
end

--- Miscellaneous functions ---

function ACAN.deepcopy(orig)				-- Clone a table
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[ACAN.deepcopy(orig_key)] = ACAN.deepcopy(orig_value)
        end
        setmetatable(copy, ACAN.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
