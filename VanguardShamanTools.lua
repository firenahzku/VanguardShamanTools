VGST_defaultConfig = {x = 0, y = 0, isUnlocked = true, scale = 1.0, defaultHeight = 50, defaultWidth = 50, defaultTextSize = 18, numTotems = 15}
VGST_TotemInfo = nil
VGST_CharacterSubgroup = nil
VGST_SubgroupCharacters = nil
VGST_UpdateInterval = 0.05
VGST_LastUpdate = GetTime()
VGST_hasMHWF = false
VGST_hasOHWF = false
VGST_ActiveTotems = nil
VGST_PlayerTotemBuffs = nil
VGST_NumActiveTotems = 0
VGST_GroupLevel = 0 -- Not in a group: 0; In a party: 1; In a raid group: 2
VGST_TotemTickIntervals = {
	["Flametongue"] = 5,
	["Stoneclaw"] = 2,
	["Magma"] = 2,
	["Windfury"] = 5,
	["Lava Spout"] = 3,
	["Disease Cleansing"] = 5,
	["Grounding"] = 10,
	["Poison Cleansing"] = 5,
	["Tremor"] = 4,
	["Earthbind"] = 3,
	["Mana Spring"] = 2,
	["Mana Tide"] = 3,
}
VGST_BuffTotems = {
	["Interface\\Icons\\Spell_FireResistanceTotem_01"] = 1,
	["Interface\\Icons\\Spell_FrostResistanceTotem_01"] = 1,
	["Interface\\Icons\\Spell_Nature_InvisibilityTotem"] = 1,
	["Interface\\Icons\\Spell_Nature_GroundingTotem"] = 1,
	["Interface\\Icons\\Spell_Nature_NatureResistanceTotem"] = 1,
	["Interface\\Icons\\Spell_Nature_EarthBindTotem"] = 1,
	["Interface\\Icons\\Spell_Nature_EarthBind"] = 1,
	["Interface\\Icons\\Spell_Nature_ManaRegenTotem"] = 1,
	["Interface\\Icons\\Spell_Frost_SummonWaterElemental"] = 1,
	["Interface\\Icons\\Spell_Nature_Brilliance"] = 1,
	["Interface\\Icons\\Spell_Nature_StoneSkinTotem"] = 1,
	["Interface\\Icons\\INV_Spear_04"] = 1,
}
VGST_ElementColors = {
	["Air"] = {r = 188/256, g = 231/256, b = 244/256},
	["Earth"] = {r = 174/256, g = 119/256, b = 96/256},
	["Fire"] = {r = 255/256, g = 80/256, b = 0/256},
	["Water"] = {r = 27/256, g = 99/256, b = 198/256},
	[16] = {r = 1, g = 1, b = 0},
	[17] = {r = 1, g = 1, b = 0},
}

VanguardShamanToolsFrame = CreateFrame("Frame", nil, UIParent)
VanguardShamanToolsFrame:RegisterEvent("VARIABLES_LOADED")
VanguardShamanToolsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
VanguardShamanToolsFrame:RegisterEvent("CHAT_MSG_ADDON")
VanguardShamanToolsFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
VanguardShamanToolsFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
VanguardShamanToolsFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
VanguardShamanToolsFrame:RegisterEvent("RAID_ROSTER_UPDATE")
VanguardShamanToolsFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
VanguardShamanToolsFrame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
VanguardShamanToolsFrame.Tooltip = CreateFrame("GameTooltip", "VGSTTooltip", nil, "GameTooltipTemplate")
VanguardShamanToolsFrame.Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

VGST_TotemBars = nil

function VGST_OnDragStart()
	if (VGSTConfig.isUnlocked == true) then
		VGST_TotemBars.mainFrame:StartMoving()
	end
end

function VGST_OnDragStop()
	VGST_TotemBars.mainFrame:StopMovingOrSizing()
	VGSTConfig.x = VGST_TotemBars.mainFrame:GetLeft()
	VGSTConfig.y = VGST_TotemBars.mainFrame:GetBottom()
end

function VGST_SecondsToTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds - m * 60
	if (m > 0) then
		if (s < 10) then
			s = "0"..s
		end
		return m..":"..s
	else
		return s
	end
end

function VGST_InitializeTotemBars()
	if (VGST_TotemBars == nil) then VGST_TotemBars = {} end
	if (VGST_TotemBars.mainFrame ~= nil) then VGST_TotemBars.mainFrame = CreateFrame("Frame", nil, UIParent) end
	VGST_TotemBars.mainFrame = CreateFrame("Frame", nil, UIParent)
	VGST_TotemBars.mainFrame:SetPoint("BOTTOMLEFT", VGSTConfig.x, VGSTConfig.y)
	VGST_TotemBars.mainFrame:SetWidth(VGSTConfig.numTotems * VGSTConfig.defaultWidth)
	VGST_TotemBars.mainFrame:SetHeight(VGSTConfig.defaultHeight * 1.2)
	VGST_TotemBars.mainFrame:SetBackdrop({bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg", tile = true, tileSize = VGSTConfig.defaultHeight})
	-- VGST_TotemBars.mainFrame:EnableMouse(true)
	VGST_TotemBars.mainFrame:RegisterForDrag("LeftButton")
	VGST_TotemBars.mainFrame:SetScript("OnDragStart", function() VGST_OnDragStart() end)
	VGST_TotemBars.mainFrame:SetScript("OnDragStop", function() VGST_OnDragStop() end)
	VGST_TotemBars.mainFrame:SetAlpha(0)
	VGST_TotemBars.mainFrame:EnableMouse(false)
	-- VGST_TotemBars.mainFrame:Hide()
	-- if (VGSTConfig.isUnlocked == false) then
	-- 	VGST_TotemBars.mainFrame:Hide()
	-- end

	VGST_TotemBars.totemFrames = {}
	for i = 1, VGSTConfig.numTotems do
		VGST_TotemBars.totemFrames[i] = CreateFrame("Frame", nil, VGST_TotemBars.mainFrame)
		local frame = VGST_TotemBars.totemFrames[i]
		frame:SetPoint("TOPLEFT", VGSTConfig.defaultWidth * (i - 1), 0)
		frame:SetWidth(VGSTConfig.defaultWidth)
		frame:SetHeight(VGSTConfig.defaultHeight * 1.2)
		frame:SetBackdrop({edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", edgeSize = "10", tile = true})
		-- frame:SetBackdrop({bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg", tile = true, tileSize = VGSTConfig.defaultHeight})

		frame.texturePath = "Interface/Icons/Spell_Nature_Windfury"
		frame.caster = "None"
		frame.element = "None"
		
		frame.texture = frame:CreateTexture(nil, "BACKGROUND")
		local texture = frame.texture
		-- texture:SetAllPoints(frame)
		texture:SetPoint("TOPLEFT", 0, 0);
		texture:SetHeight(VGSTConfig.defaultHeight)
		texture:SetWidth(VGSTConfig.defaultWidth)
		texture:SetTexture(frame.texturePath)
		
		frame.range = frame:CreateTexture(nil, "OVERLAY")
		local range = frame.range
		-- range:SetAllPoints(frame)
		range:SetPoint("TOPLEFT", 0, 0);
		range:SetWidth(VGSTConfig.defaultWidth)
		range:SetHeight(VGSTConfig.defaultHeight)
		range:SetTexture(1,0,0)
		range:SetAlpha(0.3)
		range:Hide()

		frame.timer = frame:CreateFontString(nil, "ARTWORK")
		local timer = frame.timer
		timer:SetAllPoints(frame)
		timer:SetShadowColor(0, 0, 0, 1.0)
		timer:SetShadowOffset(0.80, -0.80)
		timer:SetFont("Fonts\\FRIZQT__.TTF", VGSTConfig.defaultTextSize, "OUTLINE")
		timer:SetText(VGST_SecondsToTime(0))
		timer:SetTextColor(1, 1, 1)

		frame.cooldown = CreateFrame("StatusBar", nil, frame)
		local cooldown = frame.cooldown
		cooldown:SetPoint("BOTTOMLEFT", 3, 3);
		cooldown:SetHeight(VGSTConfig.defaultHeight * 0.2)
		cooldown:SetWidth(VGSTConfig.defaultWidth - 6)
		cooldown:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
		cooldown:SetBackdrop({bgFile = "Interface/RaidFrame/UI-RaidFrame-GroupBg", tile = true, tileSize = VGSTConfig.defaultHeight * 0.15})
		cooldown:SetAlpha(1)
		cooldown:Hide()
	end
	if (VGSTConfig.scale ~= 1.0) then
		VGST_UpdateScale()
	end
	if (VGSTConfig.isUnlocked == true) then
		VGSTConfig.isUnlocked = false
		VGST_SlashCommand("move")
	end
end

function VGST_totemFrameBar(flag)
	if (flag == true) then
		Print("locked")
		for i = 1, 9 do
			if (LunaUF.Units.headerFrames["raid"..i]) then
				LunaUF.Units.headerFrames["raid"..i]:UnregisterEvent("PARTY_MEMBERS_CHANGED")
				LunaUF.Units.headerFrames["raid"..i]:UnregisterEvent("RAID_ROSTER_UPDATE")
			end
		end
	elseif (flag == false) then
		Print("unlocked")
		for i = 1, 9 do
			if (LunaUF.Units.headerFrames["raid"..i]) then
				LunaUF.Units.headerFrames["raid"..i]:RegisterEvent("PARTY_MEMBERS_CHANGED")
				LunaUF.Units.headerFrames["raid"..i]:RegisterEvent("RAID_ROSTER_UPDATE")
				LunaUF.Units.headerFrames["raid"..i].Update(LunaUF.Units.headerFrames["raid"..i])
			end
		end
	end
end

function VGST_LoadTotemInfo()
	VGST_TotemInfo = {}
	for i = 1, MAX_SKILLLINE_TABS do
		local name, _, offset, numSpells = GetSpellTabInfo(i)
		if (not name) then break end
		for s = offset + 1, offset + numSpells do
			local spellName = GetSpellName(s, BOOKTYPE_SPELL)
			for totem in string.gfind(spellName, "(.*) Totem") do
				local tex = GetSpellTexture(s, BOOKTYPE_SPELL)
				local dur = 0
				local hp = 5
				VGSTTooltip:ClearLines();
				VGSTTooltip:SetSpell(s, i);
				if (VGSTTooltipTextLeft5:IsShown()) then
					-- Duration
					for num in string.gfind(VGSTTooltipTextLeft5:GetText(), "for ([0-9]*) sec") do
						dur = num * 1
					end
					for num in string.gfind(VGSTTooltipTextLeft5:GetText(), "for ([0-9]*) min") do
						dur = num * 60
					end
					for num in string.gfind(VGSTTooltipTextLeft5:GetText(), "asts ([0-9]*) sec") do
						dur = num * 1
					end
					for num in string.gfind(VGSTTooltipTextLeft5:GetText(), "asts ([0-9]*) min") do
						dur = num * 60
					end
					-- Health
					for num in string.gfind(VGSTTooltipTextLeft5:GetText(), "with ([0-9]*) health") do
						hp = num * 1
					end
					for num in string.gfind(VGSTTooltipTextLeft5:GetText(), "has ([0-9]*) health") do
						hp = num * 1
					end
				end
				local elem = "None"
				if (VGSTTooltipTextLeft4:IsShown()) then
					for totemType in string.gfind(VGSTTooltipTextLeft4:GetText(), "Tools: (.*) Totem") do
						elem = totemType
					end
				end
				local tick = 0
				if (VGST_TotemTickIntervals[totem] ~= nil) then tick = VGST_TotemTickIntervals[totem] end
				VGST_TotemInfo[totem] = {texture = tex, duration = dur, element = elem, tickInterval = tick, health = hp}
			end
		end
	end
	-- for totem, entry in pairs(VGST_TotemInfo) do
	-- 	DEFAULT_CHAT_FRAME:AddMessage(totem.." "..entry.element)
	--	-- /script DEFAULT_CHAT_FRAME:AddMessage(GetRaidRosterInfo(1))
	-- end
end

function VGST_LoadRosterInfo()
	local playerName = UnitName("player")
	VGST_CharacterSubgroup = {}
	VGST_SubgroupCharacters = {}
	if (GetNumRaidMembers() > 0) then
		for i = 1, 40 do
			local charName = UnitName("raid"..i)
			if (charName ~= nil and charName ~= "Unknown") then
				_,_,subgroup,_,_,charClass,_,online,dead = GetRaidRosterInfo(i)
				if (charName == playerName or charClass == "SHAMAN" and online and not dead ) then -- We only care which groups the shamans are in, and the player him/her-self
					VGST_CharacterSubgroup[charName] = subgroup
					if (VGST_SubgroupCharacters[subgroup] == nil) then VGST_SubgroupCharacters[subgroup] = {} end
					table.insert(VGST_SubgroupCharacters[subgroup], charName)
				end
			end
		end
		VGST_GroupLevel = 2

	elseif (GetNumPartyMembers() > 0) then -- In a party, we say that everyone is in raid subgroup 1
		VGST_SubgroupCharacters[1] = {}
		for i = 1, 5 do
			local charName = UnitName("party"..i)
			if (charName ~= nil and charName ~= "Unknown" and not UnitIsDead("party"..i)) then
				_,charClass = UnitClass("party"..i)
				if (charClass == "SHAMAN") then -- We only care which groups the shamans are in, and the player him/her-self
					VGST_CharacterSubgroup[charName] = 1
					table.insert(VGST_SubgroupCharacters[1], charName)
				end
			end
		end
		VGST_CharacterSubgroup[playerName] = 1
		table.insert(VGST_SubgroupCharacters[1], playerName)
		VGST_GroupLevel = 1

	else -- You're alone, but to make things consistent, we consider that as raid subgroup 1
		VGST_CharacterSubgroup[playerName] = 1
		VGST_SubgroupCharacters[1] = {}
		table.insert(VGST_SubgroupCharacters[1], playerName)
		VGST_GroupLevel = 0
	end
end

function VGST_AddTotem(caster, totemTexture, duration, element, tickInterval, castBefore, totemHealth)
	-- DEFAULT_CHAT_FRAME:AddMessage(caster.. " "..totemTexture.. " "..duration.. " "..element.." "..tickInterval)
	local skipUpdate = false
	if (VGST_ActiveTotems == nil) then VGST_ActiveTotems = {} end
	if (VGST_ActiveTotems[caster] == nil) then VGST_ActiveTotems[caster] = {} end
	if (VGST_ActiveTotems[caster][element] ~= nil and VGST_ActiveTotems[caster][element].texturePath == totemTexture) then
		skipUpdate = true -- We already have this totem up, and it only needs its duration refreshed
	end
	VGST_ActiveTotems[caster][element] = {texturePath = totemTexture, duration = tonumber(duration), tickInterval = tonumber(tickInterval), x = 0, y = 0, castAt = GetTime() - tonumber(castBefore), health = tonumber(totemHealth)}

	if (totemTexture == "Interface\\Icons\\Spell_Nature_Windfury" or totemTexture == "Interface\\Icons\\Spell_Nature_GuardianWard") then -- We need to track weapon enchantment
		VGSTTooltip:ClearLines()
		local hasItem,_,_ = VGSTTooltip:SetInventoryItem("player", 16)
		if (hasItem) then
			local weaponTexture = GetInventoryItemTexture("player", 16)
			-- VGST_AddTotem(playerName, weaponTexture, duration, i, 5, 0) -- using weapon slot as element
			VGST_ActiveTotems[caster][16] = {texturePath = weaponTexture, duration = tonumber(duration), tickInterval = 5, x = 0, y = 0, castAt = GetTime() - tonumber(castBefore), health = tonumber(totemHealth)}
		end
	end

	local playerName = UnitName("player")
	if (VGST_CharacterSubgroup[caster] == VGST_CharacterSubgroup[playerName] and skipUpdate == false) then -- the new totem affects your subgroup and your totem bar needs updating
		-- DEFAULT_CHAT_FRAME:AddMessage(1337)
		VGST_UpdateYourTotems()
	end
end

function VGST_ReduceTotemHealth(caster, element, newHealth)
	if (VGST_ActiveTotems[caster] ~= nil and VGST_ActiveTotems[caster][element] ~= nil) then
		VGST_ActiveTotems[caster][element].health = tonumber(newHealth)
		if (VGST_ActiveTotems[caster][element].health <= 0) then	-- Totem is dead and needs to be removed
			VGST_UpdateYourTotems()
		end
	end
end

function VGST_UpdateYourTotems()
	local playerName = UnitName("player")
	local playerSubgroup = VGST_CharacterSubgroup[playerName]
	local VGST_ShamansInGroup = {}
	local VGST_TotemCheck = {}
	if (VGST_ActiveTotems == nil) then VGST_ActiveTotems = {} end
	-- Make a list of all shamans in your subgroup
	for _, charName in pairs(VGST_SubgroupCharacters[playerSubgroup]) do
		-- local _,playerClass = UnitClass("player")
		-- DEFAULT_CHAT_FRAME:AddMessage(playerClass)
		-- if (charName ~= playerName or playerClass == "SHAMAN") then -- other players are always shamans
			VGST_ShamansInGroup[charName] = true
			VGST_TotemCheck[charName] = {}
			-- DEFAULT_CHAT_FRAME:AddMessage(charName)
		-- end
	end
	-- Check if any tracked totems got destroyed
	for caster, val in pairs(VGST_ActiveTotems) do
		for element, entry in pairs(val) do
			if (tonumber(VGST_ActiveTotems[caster][element].health) <= 0) then
				if (VGST_ShamansInGroup[caster] == true) then -- Shaman was in your group, and we want to be notified that his totem was destroyed
					if (BigWigsWarningSign ~= nil and BigWigsMessages ~= nil) then
						BigWigsWarningSign:BigWigs_ShowWarningSign(VGST_ActiveTotems[caster][element].texturePath, 5, true)
						BigWigsMessages:BigWigs_Message("Totem destroyed!", "Attention", true, "Long")
					else
						DEFAULT_CHAT_FRAME:AddMessage("Totem destroyed!")
					end
				end
				VGST_ActiveTotems[caster][element] = nil
			end
		end
	end
	-- Check if your currently displayed totems need to be removed (either shaman is no longer in your group, or the totem expired, or it was destroyed)
	local n = 0
	for i = 1, VGST_NumActiveTotems do
		local caster = VGST_TotemBars.totemFrames[i].caster
		local element = VGST_TotemBars.totemFrames[i].element
		local texturePath = VGST_TotemBars.totemFrames[i].texturePath

		local totemShouldRemain = (VGST_ActiveTotems[caster] ~= nil) and (VGST_ActiveTotems[caster][element] ~= nil) and (VGST_ActiveTotems[caster][element].texturePath == texturePath)

		if (VGST_ShamansInGroup[caster] == true and totemShouldRemain == true and VGST_ActiveTotems[caster][element].duration >= VGST_UpdateInterval and tonumber(VGST_ActiveTotems[caster][element].health) > 0) then
			n = n + 1
			VGST_TotemBars.totemFrames[n].caster = caster
			VGST_TotemBars.totemFrames[n].element = element
			VGST_TotemBars.totemFrames[n].texturePath = texturePath
			VGST_TotemBars.totemFrames[n].texture:SetTexture(texturePath)
			VGST_TotemBars.totemFrames[n].timer:SetText(VGST_TotemBars.totemFrames[i].timer:GetText())
			VGST_TotemBars.totemFrames[n].cooldown:SetStatusBarColor(VGST_ElementColors[element].r, VGST_ElementColors[element].g, VGST_ElementColors[element].b)
			if ((element == 16 or element == 17) or VGST_ActiveTotems[caster][element].duration < 10) then
				VGST_TotemBars.totemFrames[n].timer:SetTextColor(1, 0, 0)
			else
				VGST_TotemBars.totemFrames[n].timer:SetTextColor(1, 1, 1)
			end
			if (VGST_ActiveTotems[caster][element].tickInterval > 0) then
				VGST_TotemBars.totemFrames[n].cooldown:SetMinMaxValues(0, VGST_ActiveTotems[caster][element].tickInterval)
				VGST_TotemBars.totemFrames[n].cooldown:Show()
			end
			VGST_TotemBars.totemFrames[n]:Show()
			VGST_TotemCheck[caster][texturePath] = true
		end
	end
	-- Hide the frames for removed totems
	for i = n + 1, VGST_NumActiveTotems do
		VGST_TotemBars.totemFrames[i]:Hide()
		VGST_TotemBars.totemFrames[i].range:Hide()
	end
	VGST_NumActiveTotems = n
	-- Check if additional totems need to be added
	for charName, val in pairs(VGST_ShamansInGroup) do
		if (VGST_ActiveTotems[charName] ~= nil) then
			for element, entry in pairs(VGST_ActiveTotems[charName]) do
				if (VGST_TotemCheck[charName][entry.texturePath] ~= true) then
					VGST_NumActiveTotems = VGST_NumActiveTotems + 1
					local n = VGST_NumActiveTotems
					VGST_TotemBars.totemFrames[n].caster = charName
					VGST_TotemBars.totemFrames[n].element = element
					VGST_TotemBars.totemFrames[n].texturePath = entry.texturePath
					VGST_TotemBars.totemFrames[n].texture:SetTexture(entry.texturePath)
					VGST_TotemBars.totemFrames[n].timer:SetText(VGST_SecondsToTime(math.floor(entry.duration)))
					VGST_TotemBars.totemFrames[n].cooldown:SetStatusBarColor(VGST_ElementColors[element].r, VGST_ElementColors[element].g, VGST_ElementColors[element].b)
					if (entry.duration >= 10) then
						VGST_TotemBars.totemFrames[n].timer:SetTextColor(1, 1, 1)
					else
						VGST_TotemBars.totemFrames[n].timer:SetTextColor(1, 0, 0)
					end
					if (entry.tickInterval > 0) then
						VGST_TotemBars.totemFrames[n].cooldown:SetMinMaxValues(0, entry.tickInterval)
						VGST_TotemBars.totemFrames[n].cooldown:Show()
					end
					VGST_TotemBars.totemFrames[n]:Show()
				end
			end
		end
	end
end

function VGST_OnEvent()
	local playerName = UnitName("player")
	if (event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD") then
		if (VGSTConfig == nil) then
			VGSTConfig = VGST_defaultConfig
		else
			-- VGST_defaultConfig = {x = 0, y = 0, isUnlocked = true, scale = 1.0, defaultHeight = 50, defaultWidth = 50, defaultTextSize = 18, numTotems = 15}
			VGSTConfig.defaultHeight = VGST_defaultConfig.defaultHeight
			VGSTConfig.defaultWidth = VGST_defaultConfig.defaultWidth
			VGSTConfig.defaultTextSize = VGST_defaultConfig.defaultTextSize
			VGSTConfig.numTotems = VGST_defaultConfig.numTotems
		end
		VGST_LoadTotemInfo()
		VGST_LoadRosterInfo()
		if (VGST_TotemBars == nil) then VGST_InitializeTotemBars() end

	elseif (event == "CHAT_MSG_SPELL_SELF_BUFF") then
		for totem in string.gfind(arg1, "You cast (.*) Totem.") do
			if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
				local zone = GetZoneText()
				local channel = "RAID"
				if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
				SendAddonMessage("VGST_NewTotem", playerName.."!"..VGST_TotemInfo[totem].texture.."!"..VGST_TotemInfo[totem].duration.."!"..VGST_TotemInfo[totem].element.."!"..VGST_TotemInfo[totem].tickInterval.."!"..(0).."!"..VGST_TotemInfo[totem].health, channel)
			else
				VGST_AddTotem(playerName, VGST_TotemInfo[totem].texture, VGST_TotemInfo[totem].duration, VGST_TotemInfo[totem].element, VGST_TotemInfo[totem].tickInterval, 0, VGST_TotemInfo[totem].health)
			end
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGST_NewTotem") then
		for caster, totemTexture, duration, element, tickInterval, castBefore, health in string.gfind(arg2, "(.+)!(.+)!(.+)!(.+)!(.+)!(.+)!(.+)") do
			VGST_AddTotem(caster, totemTexture, duration, element, tickInterval, castBefore, health)
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGST_HiImBob") then -- A new player joined the group and is asking for totem info
		if (VGST_ActiveTotems ~= nil and VGST_ActiveTotems[playerName] ~= nil) then
			for element,entry in pairs(VGST_ActiveTotems[playerName]) do
				if (element ~= 16 and element ~= 17) then
					local zone = GetZoneText()
					local channel = "RAID"
					if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
					SendAddonMessage("VGST_HiBob!"..arg2, playerName.."!"..entry.texturePath.."!"..entry.duration.."!"..element.."!"..entry.tickInterval.."!"..(GetTime() - entry.castAt).."!"..entry.health, channel)
				end
			end
		end

	elseif (event == "CHAT_MSG_ADDON" and string.find(arg1, "VGST_HiBob!")) then
		for recipient in string.gfind(arg1, "VGST_HiBob!(.*)") do
			if (recipient == playerName) then -- our call for totem info sharing was answered
				for caster, totemTexture, duration, element, tickInterval, castBefore, health in string.gfind(arg2, "(.+)!(.+)!(.+)!(.+)!(.+)!(.+)!(.+)") do
					VGST_AddTotem(caster, totemTexture, duration, element, tickInterval, castBefore, health)
				end
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE") then
		for totem, damage in string.gfind(arg1, "[hcr]+its (.*) for (.*)") do
			if (totem ~= "you") then
				for totemName in string.gfind(totem, "(.*) Totem") do	-- Removing the "Totem" part from the name
					Print(totemName)
					local texture = VGST_TotemInfo[totemName].texture
					local element = VGST_TotemInfo[totemName].element
					if (VGST_ActiveTotems[playerName] ~= nil and VGST_ActiveTotems[playerName][element] ~= nil and VGST_ActiveTotems[playerName][element].texturePath == texture) then
						if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
							local zone = GetZoneText()
							local channel = "RAID"
							if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
							SendAddonMessage("VGST_TotemDamage", playerName.."!"..VGST_TotemInfo[totemName].element.."!"..(tonumber(VGST_ActiveTotems[playerName][element].health) - tonumber(damage)), channel)
						else
							VGST_ReduceTotemHealth(playerName, VGST_TotemInfo[totemName].element, tonumber(VGST_ActiveTotems[playerName][element].health) - tonumber(damage))
						end
						-- Print(VGST_ActiveTotems[playerName][element].health - tonumber(damage))
					end
				end
			end
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGST_TotemDamage") then
		for caster, element, newHealth in string.gfind(arg2, "(.+)!(.+)!(.+)") do
			VGST_ReduceTotemHealth(caster, element, newHealth)
		end

	elseif (event == "CHAT_MSG_ADDON" and arg1 == "VGST_OTH") then
		if (arg2 == "Bar") then
			VGST_totemFrameBar(true)
		elseif (arg2 == "Totem") then
			VGST_totemFrameBar(false)
		end

	elseif (event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") then
		local oldSubgroups = VGST_CharacterSubgroup
		local oldGroupLevel = VGST_GroupLevel
		VGST_LoadRosterInfo()
		VGST_UpdateYourTotems()
		local zone = GetZoneText()
		local channel = "RAID"
		if (zone == "Warsong Gulch" or zone == "Arathi Basin" or zone == "Alterac Valley") then channel = "BATTLEGROUND" end
		if (oldGroupLevel < VGST_GroupLevel) then -- Since you joined a new group, it's time to tell everyone about the totems that you bring and ask for them to share theirs
			SendAddonMessage("VGST_HiImBob", playerName, channel)
			if (VGST_ActiveTotems ~= nil and VGST_ActiveTotems[playerName] ~= nil) then
				for element, entry in pairs(VGST_ActiveTotems[playerName]) do
					if (element ~= 16 and element ~= 17) then
						SendAddonMessage("VGST_NewTotem", playerName.."!"..entry.texturePath.."!"..entry.duration.."!"..element.."!"..entry.tickInterval.."!"..entry.tickTimer.."!"..(GetTime() - entry.castAt).."!"..entry.totalDuration.."!"..entry.health, channel)
					end
				end
			end
		end

	elseif (event == "PLAYER_AURAS_CHANGED") then
		VGST_PlayerTotemBuffs = {}
		for i = 0, 31 do
			local buffId,_ = GetPlayerBuff(i, "HELPFUL|HARMFUL|PASSIVE")
			if (buffId >= 0) then
				local texture = GetPlayerBuffTexture(buffId)
				-- DEFAULT_CHAT_FRAME:AddMessage(texture.." "..VGST_BuffTotems[texture])
				if (VGST_BuffTotems[texture] == 1) then
					VGST_PlayerTotemBuffs[texture] = 1
				end
			else
				break
			end
		end
	end
end

function getWeaponEnchantmentDuration(slot)
	-- nil: there is no weapon equipped
	-- -1: There is no weapon enchantment
	-- number >= 0: duration of the Totem weapon enchantment
	VGSTTooltip:ClearLines()
	local hasItem,_,_ = VGSTTooltip:SetInventoryItem("player", slot)
	if (hasItem) then
		for lineNum = 6, 15 do
			local line = getglobal("VGSTTooltipTextLeft"..lineNum)
			if (line:IsShown()) then
				local text = line:GetText()
				if (string.find(text, "Totem")) then
					for rank, duration in string.gfind(text, "Totem (.*) %((.*) sec%)") do
						return tonumber(duration)
					end
				end
			else
				return -1
			end
		end
	else
		return nil
	end
end

function VGST_OnUpdate()
	local currentTime = GetTime()
	local delta = currentTime - VGST_LastUpdate
	local needsCleanup = false
	if (delta >= VGST_UpdateInterval) then
		local playerName = UnitName("player")
		-- Update time for ALL totems that you are aware of
		if (VGST_ActiveTotems ~= nil) then
			for caster, val in pairs(VGST_ActiveTotems) do
				for element, entry in pairs(val) do
					if (VGST_ActiveTotems[caster][element].castAt + VGST_ActiveTotems[caster][element].duration <= currentTime) then
						VGST_ActiveTotems[caster][element] = nil
					else -- Check if the weapon totem enchantment is still on
						if (element == 16 or element == 17) then
							local chantCode = getWeaponEnchantmentDuration(element)
							if (chantCode == nil or chantCode < 0) then
								VGST_ActiveTotems[caster][element] = nil
							end
						end
					end
				end
			end
		end
		-- Update timers that you have displayed
		for i = 1, VGST_NumActiveTotems do
			local caster = VGST_TotemBars.totemFrames[i].caster
			local element = VGST_TotemBars.totemFrames[i].element
			local texturePath = VGST_TotemBars.totemFrames[i].texturePath
			-- local prevDuration = tonumber(VGST_TotemBars.totemFrames[i].timer:GetText()) or 999999
			if (VGST_ActiveTotems ~= nil and VGST_ActiveTotems[caster] ~= nil and VGST_ActiveTotems[caster][element] ~= nil and VGST_ActiveTotems[caster][element].texturePath == texturePath) then
				if (VGST_ActiveTotems[caster][element].castAt + VGST_ActiveTotems[caster][element].duration > currentTime) then
					VGST_TotemBars.totemFrames[i].range:Hide()
					if (element ~= 16 and element ~= 17) then
						local remaining = math.floor(VGST_ActiveTotems[caster][element].duration - (currentTime - VGST_ActiveTotems[caster][element].castAt))
						VGST_TotemBars.totemFrames[i].timer:SetText(VGST_SecondsToTime(remaining))
						if (remaining < 10) then VGST_TotemBars.totemFrames[i].timer:SetTextColor(1, 0, 0) end
						
						if (VGST_ActiveTotems[caster][element].tickInterval > 0) then
							local ticksSoFar = math.floor((currentTime - VGST_ActiveTotems[caster][element].castAt) / VGST_ActiveTotems[caster][element].tickInterval)
							local tickProgress = currentTime - VGST_ActiveTotems[caster][element].castAt - ticksSoFar * VGST_ActiveTotems[caster][element].tickInterval
							VGST_TotemBars.totemFrames[i].cooldown:SetValue(tickProgress)
						else
							VGST_TotemBars.totemFrames[i].cooldown:SetValue(0)
						end

						if (VGST_BuffTotems[texturePath] == 1) then
							if (VGST_PlayerTotemBuffs[texturePath] == 1 and VGST_TotemBars.totemFrames[i].range:IsShown()) then
								VGST_TotemBars.totemFrames[i].range:Hide()
							elseif (VGST_PlayerTotemBuffs[texturePath] ~= 1 and not VGST_TotemBars.totemFrames[i].range:IsShown()) then
								VGST_TotemBars.totemFrames[i].range:Show()
							end
						end

						local chantCode = getWeaponEnchantmentDuration(16)
						if ((texturePath == "Interface\\Icons\\Spell_Nature_Windfury" or texturePath == "Interface\\Icons\\Spell_Nature_GuardianWard") and VGST_ActiveTotems[caster][16] == nil and chantCode ~= nil and chantCode >= 0) then
							-- If it is a weapon totem, we need to make sure that we keep tracking it when we regain the weapon buff
							local weaponTexture = GetInventoryItemTexture("player", 16)
							VGST_ActiveTotems[caster][16] = {texturePath = weaponTexture, duration = VGST_ActiveTotems[caster][element].duration, tickInterval = 5, x = 0, y = 0, castAt = VGST_ActiveTotems[caster][element].castAt, health = 1}
							VGST_UpdateYourTotems()
						end
					else -- weapon totems enchantment
						local tooltipRemaining = getWeaponEnchantmentDuration(element)
						local remaining = VGST_ActiveTotems[caster][element].duration - (currentTime - VGST_ActiveTotems[caster][element].castAt)
						if (remaining < tooltipRemaining) then VGST_ActiveTotems[caster][element].duration = VGST_ActiveTotems[caster][element].duration + 5 end

						local ticksSoFar = math.floor(remaining / VGST_ActiveTotems[caster][element].tickInterval)
						local tickProgress = remaining - ticksSoFar * VGST_ActiveTotems[caster][element].tickInterval
						VGST_TotemBars.totemFrames[i].cooldown:SetValue(5 - tickProgress)

						remaining = math.floor(remaining - math.floor(remaining / 10) * 10)
						if (tooltipRemaining > remaining) then remaining = remaining + 5 end
						VGST_TotemBars.totemFrames[i].timer:SetText(VGST_SecondsToTime(remaining))
						if (remaining < 10) then VGST_TotemBars.totemFrames[i].timer:SetTextColor(1, 0, 0) end
					end
				end
			elseif (VGST_ActiveTotems ~= nil and VGST_ActiveTotems[caster] ~= nil and VGST_ActiveTotems[caster][element] == nil) then
				needsCleanup = true
			end
		end
		VGST_LastUpdate = currentTime
		
	end
	if (VGSTConfig.isUnlocked == true) then
		for i = VGST_NumActiveTotems + 1, VGSTConfig.numTotems do
			if (not VGST_TotemBars.totemFrames[i]:IsShown()) then VGST_TotemBars.totemFrames[i]:Show() end
		end
	elseif (VGSTConfig.isUnlocked == false) then
		for i = VGST_NumActiveTotems + 1, VGSTConfig.numTotems do
			if (VGST_TotemBars.totemFrames[i]:IsShown()) then VGST_TotemBars.totemFrames[i]:Hide() end
		end
	end
	if (needsCleanup == true) then
		VGST_UpdateYourTotems()
	end
end

VanguardShamanToolsFrame:SetScript("OnEvent", VGST_OnEvent)
VanguardShamanToolsFrame:SetScript("OnUpdate", VGST_OnUpdate)

function VGST_UpdateScale()
	local scale = VGSTConfig.scale
	-- VGST_TotemBars.mainFrame:SetScale(scale)
	for i = 1, VGSTConfig.numTotems do
		local frame = VGST_TotemBars.totemFrames[i]
		local texture = frame.texture
		local range = frame.range
		local timer = frame.timer
		local cooldown = frame.cooldown
		frame:SetPoint("TOPLEFT", scale * VGSTConfig.defaultWidth * (i - 1), 0)
		frame:SetWidth(scale * VGSTConfig.defaultWidth)
		frame:SetHeight(scale * VGSTConfig.defaultHeight * 1.2)
		-- texture:SetAllPoints(frame)
		texture:SetHeight(scale * VGSTConfig.defaultHeight)
		texture:SetWidth(scale * VGSTConfig.defaultWidth)
		range:SetHeight(scale * VGSTConfig.defaultHeight)
		range:SetWidth(scale * VGSTConfig.defaultWidth)
		timer:SetFont("Fonts\\FRIZQT__.TTF", scale * VGSTConfig.defaultTextSize, "OUTLINE")
		timer:SetAllPoints(frame)
		cooldown:SetWidth(scale * VGSTConfig.defaultWidth - 6)
		cooldown:SetHeight(scale * VGSTConfig.defaultHeight * 0.2)
		cooldown:SetPoint("BOTTOMLEFT", 3, 3);
	end
	local frame = VGST_TotemBars.mainFrame
	frame:SetWidth(scale * VGSTConfig.defaultWidth * VGSTConfig.numTotems)
	frame:SetHeight(scale * VGSTConfig.defaultHeight)
end

function VGST_SlashCommand(msg)
	if (msg == "reset") then
		VGSTConfig = VGST_defaultConfig
		VGST_InitializeTotemBars()
	elseif (msg == "move") then
		if (VGSTConfig.isUnlocked == false) then
			VGSTConfig.isUnlocked = true
			VGST_TotemBars.mainFrame:SetAlpha(0.5)
			VGST_TotemBars.mainFrame:EnableMouse(true)
			for i = 1, VGSTConfig.numTotems do
				VGST_TotemBars.totemFrames[i]:SetAlpha(0.5)
			end
			-- VGST_TotemBars.mainFrame:Show()
			VGST_TotemBars.mainFrame:SetMovable(true)
		else
			VGST_TotemBars.mainFrame:EnableMouse(false)
			VGSTConfig.isUnlocked = false
			VGST_TotemBars.mainFrame:SetAlpha(0)
			for i = 1, VGSTConfig.numTotems do
				VGST_TotemBars.totemFrames[i]:SetAlpha(1)
			end
			-- VGST_TotemBars.mainFrame:Hide()
			VGST_TotemBars.mainFrame:SetMovable(false)
		end
	elseif (string.find(msg, "scale ")) then
		for scale in string.gfind( msg, "scale (.*)" ) do
			VGSTConfig.scale = scale
			VGST_UpdateScale()
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage( "VanguardShamanTools (VGST), by Threewords <Vanguard> of Kronos, Twinstar" )
		DEFAULT_CHAT_FRAME:AddMessage( "/vgst reset" )
		DEFAULT_CHAT_FRAME:AddMessage( "/vgst move" )
		DEFAULT_CHAT_FRAME:AddMessage( "/vgst scale "..VGSTConfig.scale )
	end
end

SLASH_VGST1 = "/vgst"
SlashCmdList["VGST"] = function(msg) VGST_SlashCommand(msg) end