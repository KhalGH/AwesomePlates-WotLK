---------------------------------------------------------------------------------------------
-------------------------- AwesomePlates Appeareance Customization --------------------------
---------------------------------------------------------------------------------------------

local AP = select(2, ...) -- namespace
if not (C_NamePlate and C_NamePlate.GetNamePlatesDistance) then 
	print(" |cffCCCC88AwesomePlates|r requires AwesomeWotlk v0.1.4-f3, more info at:")
	print("                        |cff00ccffhttps://github.com/KhalGH/AwesomePlates-WotLK|r")
	AP.disabled = true
	return
end

----------------------------- API -----------------------------
local print, pairs, unpack, select, math_floor, CreateFrame, UnitCastingInfo, UnitChannelInfo, UnitName, UnitIsUnit, UnitCanAttack =
      print, pairs, unpack, select, math.floor, CreateFrame, UnitCastingInfo, UnitChannelInfo, UnitName, UnitIsUnit, UnitCanAttack
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

------------------------- Core Variables -------------------------
local VirtualPlates = {} -- Storage table for virtual nameplate frames
local RealPlates = {} -- Storage table for real nameplate frames
local texturePath = "Interface\\AddOns\\!!AwesomePlates\\Textures\\"
local NP_WIDTH = 156.65118520899 -- Nameplate original width (don't modify)
local NP_HEIGHT = 39.162796302247 -- Nameplate original height (don't modify)
AP.VirtualPlates = VirtualPlates -- reference for AwesomePlates.lua
AP.RealPlates = RealPlates -- reference for AwesomePlates.lua
AP.texturePath = texturePath -- reference for AwesomePlates.lua
AP.NP_WIDTH = NP_WIDTH -- reference for AwesomePlates.lua
AP.NP_HEIGHT = NP_HEIGHT -- reference for AwesomePlates.lua

-------------------- Customization Parameters --------------------
local fontPath = "Fonts\\ARIALN.TTF" -- Font used for nameplate text
local globalYoffset = 22 -- Global vertical offset for nameplates
AP.globalYoffset = globalYoffset -- reference for AwesomePlates.lua
-- Name Text
local nameText_fontSize = 9
local nameText_fontFlags = nil
local nameText_anchor = "CENTER"
local nameText_Xoffset = 0.2
local nameText_Yoffset = 0.7
local nameText_width = 85 -- max text width before truncation (...)
local nameText_color = {1, 1, 1} -- white
AP.nameText_color = nameText_color -- reference for AwesomePlates.lua
-- Health Text
local healthText_fontSize = 8.8
local healthText_fontFlags = nil
local healthText_anchor = "RIGHT"
local healthText_Xoffset = 0
local healthText_Yoffset = 0.3
local healthText_color = {1, 1, 1} -- white
-- Cast Text
local castText_fontSize = 9
local castText_fontFlags = nil
local castText_anchor = "CENTER"
local castText_Xoffset = -3.8
local castText_Yoffset = 1.6
local castText_width = 90 -- max text width before truncation (...)
local castText_color = {1, 1, 1} -- white
-- Cast Timer Text
local castTimerText_fontSize = 8.8
local castTimerText_fontFlags = nil
local castTimerText_anchor = "RIGHT"
local castTimerText_Xoffset = -2
local castTimerText_Yoffset = 1
local castTimerText_color = {1, 1, 1} -- white
-- Distance Text
local distanceText_fontSize = 11
local distanceText_fontFlags = "OUTLINE"
local distanceText_anchor = "CENTER"
local distanceText_Xoffset = 0
local distanceText_Yoffset = 16
local distanceText_color = {1, 1, 1} -- white
-- Target Glow
local targetGlow_alpha = 1 -- opacity
AP.targetGlow_alpha = targetGlow_alpha -- reference for AwesomePlates.lua
-- Mouseover Glow
local mouseoverGlow_alpha = 1 -- opacity
AP.mouseoverGlow_alpha = mouseoverGlow_alpha -- reference for AwesomePlates.lua
-- Focus Glow
local focusGlow_color = {0.6, 0.2, 1} -- purple (add 4th value for opacity)
-- Cast Glow (Shows when unit is targetting you)
local castGlow_friendlyColor = {0.25, 0.75, 0.25} -- friendly: green (add 4th value for opacity)
local castGlow_enemyColor = {1, 0, 0} -- enemy: red (add 4th value for opacity)
-- Boss Icon
local bossIcon_size = 18
local bossIcon_anchor = "RIGHT"
local bossIcon_Xoffset = 4.5
local bossIcon_Yoffset = -9
-- Raid Target Icon
local raidTargetIcon_size = 27
local raidTargetIcon_anchor = "RIGHT"
local raidTargetIcon_Xoffset = 16
local raidTargetIcon_Yoffset = -9
-- Class Icon
local classIcon_size = 26
local classIcon_anchor = "LEFT"
local classIcon_Xoffset = -9.6
local classIcon_Yoffset = -9
-- Totem Plates
local totemSize = 23 -- Size of the totem (or NPC) icon replacing the nameplate
local totemOffSet = -20 -- Vertical offset for totem icon
local totemGlowSize = 128 * totemSize / 88 -- Ratio 128:88 comes from texture pixels

---------------------------- Customization Functions ----------------------------
local function CreateHealthBorder(healthBar)
	if healthBar.healthBarBorder then return end
	healthBar.healthBarBorder = healthBar:CreateTexture(nil, "ARTWORK")
	healthBar.healthBarBorder:SetTexture(texturePath .. "HealthBar-Border")
	healthBar.healthBarBorder:SetSize(NP_WIDTH, NP_HEIGHT)
	healthBar.healthBarBorder:SetPoint("CENTER", 10.5, 9)
end

local function CreateBarBackground(Bar)
	if Bar.BackgroundTex then return end
	Bar.BackgroundTex = Bar:CreateTexture(nil, "BACKGROUND")
	Bar.BackgroundTex:SetTexture(texturePath .. "NamePlate-Background")
	Bar.BackgroundTex:SetSize(NP_WIDTH, NP_HEIGHT)
	Bar.BackgroundTex:SetPoint("CENTER", 10.5, 9)
end

local function CreateNameText(healthBar)
	if healthBar.nameText then return end
	healthBar.nameText = healthBar:CreateFontString(nil, "OVERLAY")
	healthBar.nameText:SetFont(fontPath, nameText_fontSize, nameText_fontFlags)
	healthBar.nameText:SetPoint(nameText_anchor, nameText_Xoffset, nameText_Yoffset)
	healthBar.nameText:SetWidth(nameText_width)
	healthBar.nameText:SetTextColor(unpack(nameText_color))
	healthBar.nameText:SetShadowOffset(0.5, -0.5)
	healthBar.nameText:SetNonSpaceWrap(false)
	healthBar.nameText:SetWordWrap(false)
end

local function UpdateHealthText(healthBar)
	local min, max = healthBar:GetMinMaxValues()
	local value = healthBar:GetValue()
	if max > 0 then
		local percent = math_floor((value / max) * 100)
		if percent < 100 and percent > 0 then
			healthBar.healthText:SetText(percent .. "%")
		else
			healthBar.healthText:SetText("")
		end
	else
		healthBar.healthText:SetText("")
	end
end

local function CreateHealthText(healthBar)
	if healthBar.healthText then return end
	healthBar.healthText = healthBar:CreateFontString(nil, "OVERLAY")
	healthBar.healthText:SetFont(fontPath, healthText_fontSize, healthText_fontFlags)
	healthBar.healthText:SetPoint(healthText_anchor, healthText_Xoffset, healthText_Yoffset)
	healthBar.healthText:SetTextColor(unpack(healthText_color))
	healthBar.healthText:SetShadowOffset(0.5, -0.5)
	UpdateHealthText(healthBar)
	healthBar:HookScript("OnValueChanged", UpdateHealthText)
	healthBar:HookScript("OnShow", UpdateHealthText)
end

local function CreateTargetGlow(healthBar)
	if healthBar.targetGlow then return end
	healthBar.targetGlow = healthBar:CreateTexture(nil, "OVERLAY")	
	healthBar.targetGlow:SetTexture(texturePath .. "HealthBar-TargetGlow")
	healthBar.targetGlow:SetSize(NP_WIDTH, NP_HEIGHT)
	healthBar.targetGlow:SetAlpha(targetGlow_alpha)
	healthBar.targetGlow:SetPoint("CENTER", 0.7, 0.5)
	healthBar.targetGlow:Hide()
end

local function UpdateTargetGlow(healthBar)
	local Virtual = healthBar:GetParent()
	local RealPlate = RealPlates[Virtual]
	healthBar.targetBorderDelay = healthBar.targetBorderDelay or CreateFrame("Frame")
	healthBar.targetBorderDelay:SetScript("OnUpdate", function(self, elapsed)
		self:SetScript("OnUpdate", nil)
		if Virtual == VirtualPlates[C_NamePlate_GetNamePlateForUnit("target")] then
			healthBar.targetGlow:Show()
			if RealPlate.totemPlate then RealPlate.totemPlate.targetGlow:Show() end
		else
			healthBar.targetGlow:Hide()
			if RealPlate.totemPlate then RealPlate.totemPlate.targetGlow:Hide() end
		end	
	end)
end

local function CreateFocusGlow(healthBar)
	if healthBar.focusGlow then return end
	healthBar.focusGlow = healthBar:CreateTexture(nil, "OVERLAY")	
	healthBar.focusGlow:SetTexture(texturePath .. "HealthBar-FocusGlow")
	healthBar.focusGlow:SetVertexColor(unpack(focusGlow_color))
	healthBar.focusGlow:SetSize(NP_WIDTH, NP_HEIGHT)
	healthBar.focusGlow:SetPoint("CENTER", 0.7, 0.5)
	healthBar.focusGlow:Hide()
end

local function UpdateFocusGlow(healthBar)
	healthBar.focusBorderDelay = healthBar.focusBorderDelay or CreateFrame("Frame")
	healthBar.focusBorderDelay:SetScript("OnUpdate", function(self, elapsed)
		self:SetScript("OnUpdate", nil)
		if healthBar:GetParent() == VirtualPlates[C_NamePlate_GetNamePlateForUnit("focus")] and not UnitIsUnit("target","focus") then		
			healthBar.focusGlow:Show()
		else
			healthBar.focusGlow:Hide()
		end
	end)
end

local function CreateCastText(castBar)
	if castBar.castText then return end
	castBar.castText = castBar:CreateFontString(nil, "OVERLAY")
	castBar.castText:SetFont(fontPath, castText_fontSize, castText_fontFlags)
	castBar.castText:SetPoint(castText_anchor, castText_Xoffset, castText_Yoffset)
	castBar.castText:SetWidth(castText_width)
	castBar.castText:SetTextColor(unpack(castText_color))
	castBar.castText:SetNonSpaceWrap(false)
	castBar.castText:SetWordWrap(false)
	castBar.castText:SetShadowOffset(0.5, -0.5)
	castBar.castTextDelay = castBar.castTextDelay or CreateFrame("Frame")
	local function UpdateCastText()
		castBar.castTextDelay:SetScript("OnUpdate", function(self, elapsed)
			self:SetScript("OnUpdate", nil)
			local unit = "target"
			local RealPlate = RealPlates[castBar:GetParent()]
			if RealPlate and RealPlate.namePlateUnitToken then
				unit = RealPlate.namePlateUnitToken
			end
			local spellName = UnitCastingInfo(unit) or UnitChannelInfo(unit)
			castBar.castText:SetText(spellName)				
		end)
	end
	UpdateCastText()
	castBar:HookScript("OnShow", UpdateCastText)
end

local function CreateCastTimer(castBar)
	if castBar.castTimerText then return end
	castBar.castTimerText = castBar:CreateFontString(nil, "OVERLAY")
	castBar.castTimerText:SetFont(fontPath, castTimerText_fontSize, castTimerText_fontFlags)
	castBar.castTimerText:SetPoint(castTimerText_anchor, castTimerText_Xoffset, castTimerText_Yoffset)
	castBar.castTimerText:SetTextColor(unpack(castTimerText_color))
	castBar.castTimerText:SetShadowOffset(0.5, -0.5)
	castBar:HookScript("OnValueChanged", function(self, value)
		local min, max = self:GetMinMaxValues()
		if max and value then
			local remaining = max - value
			if self.channeling then
				self.castTimerText:SetFormattedText("%.1f", value)
			else
				self.castTimerText:SetFormattedText("%.1f", remaining)						
			end
		end
	end)
end

local function CreateCastGlow(Virtual)
	if Virtual.castGlow then return end
	Virtual.castGlow = Virtual:CreateTexture(nil, "OVERLAY")	
	Virtual.castGlow:SetTexture(texturePath .. "CastBar-Glow")
	Virtual.castGlow:SetTexCoord(0, 0.55, 0, 1)
	Virtual.castGlow:SetSize(159.5, 40)
	Virtual.castGlow:SetPoint("CENTER", 2.75, -27.5 + globalYoffset)
	Virtual.castGlow:SetVertexColor(unpack(castGlow_enemyColor))
	Virtual.castGlow:Hide()
	local castBar = select(2, Virtual:GetChildren())
	local castBarBorder = select(3, Virtual:GetRegions())
	castBar:HookScript("OnShow", function()
		local namePlateUnit = RealPlates[Virtual].namePlateUnitToken
		if namePlateUnit then
			local namePlateTarget = UnitName(namePlateUnit.."target")
			if namePlateTarget == UnitName("player") and castBarBorder:IsShown() and not UnitIsUnit("target", namePlateUnit) then
				local isFriendly = not UnitCanAttack("player", namePlateUnit)
				if isFriendly then
					Virtual.castGlow:SetVertexColor(unpack(castGlow_friendlyColor))
				else
					Virtual.castGlow:SetVertexColor(unpack(castGlow_enemyColor))
				end
				Virtual.castGlow:Show()
			end
		end
	end)
	castBar:HookScript("OnValueChanged", function()
		local namePlateUnit = RealPlates[Virtual].namePlateUnitToken
		if namePlateUnit then
			if UnitIsUnit("target", namePlateUnit) == 1 then
				Virtual.castGlow:Hide()
			end
		end
	end)
	castBar:HookScript("OnHide", function()
		Virtual.castGlow:Hide()
	end)
end

local function CreateClassIcon(Virtual)
	if Virtual.classIcon then return end
	Virtual.classIcon = Virtual:CreateTexture(nil, "ARTWORK")	
	Virtual.classIcon:SetSize(classIcon_size, classIcon_size)
	Virtual.classIcon:SetPoint(classIcon_anchor, classIcon_Xoffset, classIcon_Yoffset + globalYoffset)
	Virtual.classIcon:Hide()
end

local function CreateDistanceText(Virtual)
	if Virtual.distanceText then return end
	Virtual.distanceText = Virtual:CreateFontString(nil, "OVERLAY")
	Virtual.distanceText:SetFont(fontPath, distanceText_fontSize, distanceText_fontFlags)
	Virtual.distanceText:SetPoint(distanceText_anchor, Virtual:GetChildren(), distanceText_Xoffset, distanceText_Yoffset)
	Virtual.distanceText:SetTextColor(unpack(distanceText_color))
end

function AP.CustomizePlate(Virtual)
	local threatGlow, healthBarBorder, castBarBorder, shieldCastBarBorder, spellIcon, healthBarHighlight, nameText, levelText, bossIcon, raidTargetIcon, eliteIcon = Virtual:GetRegions()
	Virtual.nameText = nameText
	Virtual.levelText = levelText
	Virtual.healthBar, Virtual.castBar = Virtual:GetChildren()
	Virtual.healthBar.barTex = Virtual.healthBar:GetRegions()
	Virtual.castBar.barTex = Virtual.castBar:GetRegions()
	Virtual.castBarBorder = castBarBorder
	Virtual.healthBarHighlight = healthBarHighlight
	CreateHealthBorder(Virtual.healthBar)
	CreateNameText(Virtual.healthBar)
	CreateTargetGlow(Virtual.healthBar)
	CreateFocusGlow(Virtual.healthBar)
	CreateHealthText(Virtual.healthBar)
	CreateBarBackground(Virtual.healthBar)
	CreateBarBackground(Virtual.castBar)
	CreateCastText(Virtual.castBar)
	CreateCastTimer(Virtual.castBar)
	CreateCastGlow(Virtual)
	CreateDistanceText(Virtual)
	CreateClassIcon(Virtual)
	healthBarBorder:Hide()
	nameText:Hide()
	threatGlow:SetTexture(nil)
	castBarBorder:SetTexture(texturePath .. "CastBar-Border")
	healthBarHighlight:SetTexture(texturePath .. "HealthBar-MouseoverGlow")
	healthBarHighlight:SetSize(NP_WIDTH, NP_HEIGHT)
	healthBarHighlight:SetAlpha(mouseoverGlow_alpha)
	bossIcon:ClearAllPoints()
	bossIcon:SetSize(bossIcon_size, bossIcon_size)
	bossIcon:SetPoint(bossIcon_anchor, bossIcon_Xoffset, bossIcon_Yoffset + globalYoffset)
	raidTargetIcon:ClearAllPoints()
	raidTargetIcon:SetSize(raidTargetIcon_size, raidTargetIcon_size)
	raidTargetIcon:SetPoint(raidTargetIcon_anchor, raidTargetIcon_Xoffset, raidTargetIcon_Yoffset + globalYoffset)
	eliteIcon:SetTexCoord(0.578125, 0, 0.578125, 0.84375, 0, 0, 0, 0.84375)
	eliteIcon:SetPoint("LEFT", 0, -11.5 + globalYoffset)
	Virtual.healthBar.barTex:SetTexture(texturePath .. "NamePlate-BarFill")
	Virtual.healthBar.barTex:SetDrawLayer("BORDER")
	Virtual.castBar.barTex:SetTexture(texturePath .. "NamePlate-BarFill")
	local function VirtualPlate_OnShow()
		castBarBorder:SetPoint("CENTER", 0, -19 + globalYoffset)
		castBarBorder:SetWidth(145)
		shieldCastBarBorder:SetWidth(145)
		healthBarHighlight:ClearAllPoints()
		healthBarHighlight:SetPoint("CENTER", 1.2, -8.7 + globalYoffset)
		levelText:Hide()
		Virtual.healthBar.nameText:SetText(nameText:GetText())
		UpdateTargetGlow(Virtual.healthBar)
		UpdateFocusGlow(Virtual.healthBar)
	end
	VirtualPlate_OnShow()
	Virtual:HookScript("OnShow", VirtualPlate_OnShow)
end

function AP.SetupTotemPlate(Plate)
	if Plate.totemPlate then return end
	local Virtual = VirtualPlates[Plate]
	Plate.totemPlate = CreateFrame("Frame", nil, Plate)
	Plate.totemPlate:SetPoint("CENTER", Virtual, 0, totemOffSet)
	Plate.totemPlate:SetSize(totemSize, totemSize)
	Plate.totemPlate:Hide()
	Plate.totemPlate.icon = Plate.totemPlate:CreateTexture(nil, "ARTWORK")
	Plate.totemPlate.icon:SetAllPoints(Plate.totemPlate)
	Plate.totemPlate.targetGlow = Plate.totemPlate:CreateTexture(nil, "OVERLAY")
	Plate.totemPlate.targetGlow:SetTexture(texturePath .. "TotemPlate-TargetGlow.blp")
	Plate.totemPlate.targetGlow:SetPoint("CENTER")
	Plate.totemPlate.targetGlow:SetSize(totemGlowSize, totemGlowSize)
	Plate.totemPlate.targetGlow:SetAlpha(targetGlow_alpha)
	Plate.totemPlate.targetGlow:Hide()
	Plate.totemPlate.mouseoverGlow = Plate.totemPlate:CreateTexture(nil, "OVERLAY")
	Plate.totemPlate.mouseoverGlow:SetTexture(texturePath .. "TotemPlate-MouseoverGlow.blp")
	Plate.totemPlate.mouseoverGlow:SetPoint("CENTER")
	Plate.totemPlate.mouseoverGlow:SetSize(totemGlowSize, totemGlowSize)
	Plate.totemPlate.mouseoverGlow:SetAlpha(mouseoverGlow_alpha)
	Plate.totemPlate.mouseoverGlow:Hide()
end

local NamePlateUpdater = CreateFrame("Frame")
NamePlateUpdater:RegisterEvent("PLAYER_TARGET_CHANGED")
NamePlateUpdater:RegisterEvent("PLAYER_FOCUS_CHANGED")
NamePlateUpdater:RegisterEvent("UNIT_SPELLCAST_START")
NamePlateUpdater:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
NamePlateUpdater:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
		for _, Virtual in pairs(VirtualPlates) do
			local healthBar = Virtual.healthBar
			if event == "PLAYER_TARGET_CHANGED" then
				UpdateTargetGlow(healthBar)
			end
			UpdateFocusGlow(healthBar)
		end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitID, spellName = ...
		if unitID:match("^nameplate%d+$") then
			local Virtual = VirtualPlates[C_NamePlate_GetNamePlateForUnit(unitID)]
			local castBar = Virtual and select(2, Virtual:GetChildren())
			if castBar then
				castBar.channeling = (event == "UNIT_SPELLCAST_CHANNEL_START")
			end
		end
	end
end)