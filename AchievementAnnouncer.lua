--[[
	1.0   Initial release
	1.01  Removed : from default output message
	1.02  Updated for 5.0.4
	1.1   Added custom channel support
	1.11  Added option to control whether guild achievements are announced
	1.12  Updated TOC version to 5.1
	1.13  Updated TOC version to 5.2
	1.14  Updated TOC version to 5.3
	1.15  Updated TOC version to 5.4
]]

function AA_OnLoad(self) -- Run when game loads up
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("ACHIEVEMENT_EARNED")
	AA_Version = GetAddOnMetadata("AchievementAnnouncer","Version")
	SLASH_AA1, SLASH_AA2 = '/aa', '/achievementannouncer'
end

function AA_OnEvent(self, event, ...) -- When an event is fired
	if (event == "ACHIEVEMENT_EARNED") then
		local achID = ...
		local achLink = GetAchievementLink(achID)
		local _,_,_,_,_,_,_,_,_,_,_,isGuildAch = GetAchievementInfo(achID)
		
		if (isGuildAch==true and AA_Settings["Guild"] == 1) or isGuildAch==false then
			if (GetNumSubgroupMembers() > 0 and IsInRaid() == false and AA_Settings["Party"] == 1) then -- in a party and not in a raid
				if ((HasLFGRestrictions() == true and AA_Settings["RandomParty"] == 1) or HasLFGRestrictions() == false) then
					SendChatMessage(AA_Str(achLink), "PARTY")
				end
			end
			
			if (GetNumGroupMembers() > 1 and IsInRaid() == true and AA_Settings["Raid"] == 1) then -- in a raid
				if ((HasLFGRestrictions() == true and AA_Settings["RandomRaid"] == 1) or HasLFGRestrictions() == false) then
					SendChatMessage(AA_Str(achLink), "RAID")
				end
			end
			
			if (AA_Settings["Say"] == 1) then
				SendChatMessage(AA_Str(achLink), "SAY")
			end
			
			if (AA_Settings["CustomChannels"] ~= "") then
				local channels = { strsplit(",",string.gsub(AA_Settings["CustomChannels"],"%s+","")) }
				for _,v in pairs(channels) do
					local id = GetChannelName(v)
					if id then
						SendChatMessage(AA_Str(achLink), "CHANNEL", nil, id)
					end
				end
			end
		end
		
	elseif (event == "ADDON_LOADED") then
		local addonName = ...
		if (addonName == "AchievementAnnouncer") then
			AA_Options:Hide()
			
			if (AA_Settings == nil) then 				AA_Settings = {} end
			if (AA_Settings["Party"] == nil) then 		AA_Settings["Party"] = 1 end
			if (AA_Settings["RandomParty"] == nil) then	AA_Settings["RandomParty"] = 0 end
			if (AA_Settings["Raid"] == nil) then		AA_Settings["Raid"] = 0 end
			if (AA_Settings["RandomRaid"] == nil) then	AA_Settings["RandomRaid"] = 0 end
			if (AA_Settings["Say"] == nil) then			AA_Settings["Say"] = 0 end
			if (AA_Settings["String"] == nil) then		AA_Settings["String"] = "has earned the achievement %a!" end
			if (AA_Settings["CustomChannels"] == nil) then AA_Settings["CustomChannels"] = "" end
			if (AA_Settings["Guild"] == nil) then		AA_Settings["Guild"] = 0 end
		end
	end
end

function AA_Msg(msg) -- Sends a formatted message to the chat frame
	DEFAULT_CHAT_FRAME:AddMessage("|cffd2b48c[AchievementAnnouncer]|r "..msg)
end

local function AA_Slash(cmd) -- Slash command handler
	if (cmd == "v" or cmd == "ver" or cmd == "version") then
		AA_Msg("Version: "..AA_Version)
	else
		InterfaceOptionsFrame_OpenToCategory("AchievementAnnouncer")
	end
end

function AA_Test(id)
	if id == nil then id = 123 end
	AA_OnEvent(self, "ACHIEVEMENT_EARNED", id)
end

function AA_Str(ach) -- Returns the string to be sent
	if AA_Settings["String"] == "" or AA_Settings["String"] == nil then
		return string.gsub("has earned the achievement %a!", "%%a", ach)
	else
		return string.gsub(AA_Settings["String"], "%%a", ach)
	end
end

-- UI STUFF --

function AA_OptionsLoad(self) -- Initialize Options panel
	self.name = "AchievementAnnouncer"
	self.default = AA_Defaults
	InterfaceOptions_AddCategory(self)
	self.okay = function(self) AA_OptionsOkay() end
end

function AA_Defaults()
	AA_OptBut_Party:SetChecked(1)
	AA_OptBut_RandomParty:SetChecked(0)
	AA_OptBut_Raid:SetChecked(0)
	AA_OptBut_RandomRaid:SetChecked(0)
	AA_OptBut_Say:SetChecked(0)
	AA_OptBut_Guild:SetChecked(0)
	AA_Opt_String:SetText("has earned the achievement %a!")
	AA_Opt_CustomChannels:SetText("")
	
	AA_Settings["Party"] = 1
	AA_Settings["RandomParty"] = 0
	AA_Settings["Raid"] = 0
	AA_Settings["RandomRaid"] = 0
	AA_Settings["Say"] = 0
	AA_Settings["Guild"] = 0
	AA_Settings["String"] = "has earned the achievement %a!"
	AA_Settings["CustomChannels"] = ""
	
	AA_OptBut_RandomParty:Enable()
	AA_OptBut_RandomRaid:Disable()
	
	AA_Opt_String:ClearFocus()
	AA_Opt_CustomChannels:ClearFocus()
end

function AA_OptionsShow() -- Fired when options panel opens
	
end

function AA_OptionsHide() -- Fired when options panel closes
	
end

function AA_OptionsOkay() -- Fired when "Okay" in options panel is pressed
	AA_Settings["String"] = AA_Opt_String:GetText()
	AA_Settings["CustomChannels"] = AA_Opt_CustomChannels:GetText()
end

function AA_ButtonClick(self) -- Fired when an options panel widget is used
	if (self:GetObjectType() ~= "Slider") then
		PlaySound("igMainMenuOptionCheckBoxOn")
	end
	
	if (self:GetName() == "AA_OptBut_Party") then
		if (AA_OptBut_Party:GetChecked()) then
			AA_Settings["Party"] = 1
		else
			AA_Settings["Party"] = 0
		end
	elseif (self:GetName() == "AA_OptBut_Raid") then
		if (AA_OptBut_Raid:GetChecked()) then
			AA_Settings["Raid"] = 1
		else
			AA_Settings["Raid"] = 0
		end
	elseif (self:GetName() == "AA_OptBut_RandomParty") then
		if (AA_OptBut_RandomParty:GetChecked()) then
			AA_Settings["RandomParty"] = 1
		else
			AA_Settings["RandomParty"] = 0
		end
	elseif (self:GetName() == "AA_OptBut_RandomRaid") then
		if (AA_OptBut_RandomRaid:GetChecked()) then
			AA_Settings["RandomRaid"] = 1
		else
			AA_Settings["RandomRaid"] = 0
		end
	elseif (self:GetName() == "AA_OptBut_Say") then
		if (AA_OptBut_Say:GetChecked()) then
			AA_Settings["Say"] = 1
		else
			AA_Settings["Say"] = 0
		end
	elseif (self:GetName() == "AA_OptBut_Guild") then
		if (AA_OptBut_Guild:GetChecked()) then
			AA_Settings["Guild"] = 1
		else
			AA_Settings["Guild"] = 0
		end
	end
end

function AA_EditBox_Focus(self)
	prevString = self:GetText()
end
function AA_EditBox_Enter(self)
	self:ClearFocus()
	AA_Settings["String"] = self:GetText()
end
function AA_EditBox_Escape(self)
	self:SetText(prevString)
	self:ClearFocus()
end


function AA_EditBox2_Focus(self)
	prevString2 = self:GetText()
end
function AA_EditBox2_Enter(self)
	self:ClearFocus()
	AA_Settings["CustomChannels"] = self:GetText()
end
function AA_EditBox2_Escape(self)
	self:SetText(prevString2)
	self:ClearFocus()
end

SlashCmdList["AA"] = AA_Slash