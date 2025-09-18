-----------------------------------------------------------------------------
------------------------------  AwesomePlates  ------------------------------
-----------------------------------------------------------------------------
----  Features:                                                          ----
----    • Modified nameplate appearance                                  ----
----    • Improved nameplate scanning and handling                       ----
----    • Optional nameplate scaling and fading based on distance        ----
----    • Optional distance text displayed on nameplates                 ----
----    • Custom glow for the target, focus and mouseover nameplates     ----
----    • TotemPlates-style functionality for totems and specific NPCs   ----
----    • Optional class icons on friendly players in PvP instances      ----
----    • Optional player-only nameplate filter                          ----
----    • Optional minimum nameplate level filter                        ----
----                                                                     ----
----  Slash Commands:                                                    ----
----    • /ap           : Lists available commands in chat               ----
----    • /ap scaling   : Enables/disables dynamic scaling               ----
----    • /ap icons     : Enables/disables class icons on PvP allies     ----
----    • /ap distance  : Enables/disables distance text                 ----
----    • /ap players   : Enables/disables player-only filter            ----
----    • /ap level <#> : Set minimum nameplate level filter             ----
----                                                                     ----
----  Based on _VirtualPlates, originally created by Saiket              ----
----                                                                     ----
----  Developed for WoW 3.3.5a modified with AwesomeWotlk v0.1.4-f3      ----
----  by Khal                                                            ----
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

local AddonName, AP = ...
if AP.disabled then return end

-- Lua API
local math_min, math_max, math_floor, tonumber, select, sort, wipe, next, pairs, ipairs, unpack, tremove, tinsert =
      math.min, math.max, math.floor, tonumber, select, sort, wipe, next, pairs, ipairs, unpack, tremove, tinsert
-- WoW API
local CreateFrame, GetCVar, UnitCanAttack, UnitIsPlayer, UnitIsUnit, UnitName, UnitClass =
      CreateFrame, GetCVar, UnitCanAttack, UnitIsPlayer, UnitIsUnit, UnitName, UnitClass
-- Nameplates API
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local C_NamePlate_GetNamePlatesDistance = C_NamePlate.GetNamePlatesDistance

AP.OptionsCharacter = {}
AP.OptionsCharacterDefault = {
	ScaleNormDist = 33;		-- Distance (or camera depth pivot) at which nameplates are forced to default scaling
	MinScale = 0.2;			-- Minimum scale factor for nameplates at long distances
	MaxScaleEnabled = true;	-- Enables/disables changing the default scale factor
	MaxScale = 1;			-- Default scale factor for nameplates at close range (defined by ScaleNormDist)
	DynamicScaling = true;	-- Enables/disables dynamic scaling of nameplates (/ap scaling)
	ShowClassIcons = true;	-- Enables/disables class icons on allies in PvP instances (/ap icons)
	LevelFilter = 1;		-- Minimum unit level to show its nameplate (/ap level <#>)
}

-- Sensitive Settings (can be changed, but handle with care)
local distanceLimit = math_min(tonumber(GetCVar("nameplateDistance")) or 41, 100) -- Distance at which nameplates reach minimum scale
local fadeStart = 60 	-- Distance at which nameplate regions start to fade (some regions for players, all regions for NPCs)
local fadeEnd = 80 		-- Distance at which nameplate regions are fully faded out (some regions for players, all regions for NPCs)
local CameraClip = 4 	-- Yards from camera when nameplates begin fading out
local UpdateRate = 0.05	-- Minimum time between plates are updated.

-- Defined in AwesomePlates_Customize.lua or Totems.xml
local VirtualPlates = AP.VirtualPlates
local RealPlates = AP.RealPlates
local TotemPlates = AP.TotemPlates
local NP_WIDTH = AP.NP_WIDTH
local NP_HEIGHT = AP.NP_HEIGHT
local globalYoffset = AP.globalYoffset
local texturePath = AP.texturePath
local nameText_colorR, nameText_colorG, nameText_colorB = unpack(AP.nameText_color)
local CustomizePlate = AP.CustomizePlate
local SetupTotemPlate = AP.SetupTotemPlate

-- Internal State and Constants
local PlatesVisible = {}
local PlateOverrides = {} -- [MethodName] = Function overrides for Virtuals
local NextUpdate = 0
local totemsTexPath = texturePath .. "Totems\\"
local classesTexPath = texturePath .. "Classes\\"
local InCombat = false
local inPvPinstance = false
local showDistanceText = false -- Toggles the visibility of distance text (/ap distance)
local filterPlayers = false -- Toggles the visibility of non-player nameplates (/ap players)
AP.PlatesVisible = PlatesVisible -- reference for AwesomePlates_Config.lua
AP.Frame = CreateFrame("Frame", nil, WorldFrame)

-- Backup of original methods
local WorldFrame_GetChildren = WorldFrame.GetChildren
local SetAlpha = AP.Frame.SetAlpha
local SetFrameLevel = AP.Frame.SetFrameLevel
local SetScale = AP.Frame.SetScale

-- Individual plate methods
--- If an anchor ataches to the original plate (by WoW), re-anchor to the Virtual.
local function ResetPoint(Plate, Region, Point, RelFrame, ...)
	if RelFrame == Plate then
		local point, xOfs, yOfs = ...
		Region:SetPoint(Point, VirtualPlates[Plate], point, xOfs + 11, yOfs + globalYoffset)
	end
end
--- Re-anchors regions when a plate is shown.
-- WoW re-anchors most regions when it shows a nameplate, so restore those anchors to the Virtual frame.
function AP:PlateOnShow()
	NextUpdate = 0 -- Resize instantly
	local Virtual = VirtualPlates[self]
	PlatesVisible[self] = Virtual
	Virtual:Show()
	-- Reposition all regions
	for Index, Region in ipairs(self) do
		for Point = 1, Region:GetNumPoints() do
			ResetPoint(self, Region, Region:GetPoint(Point))
		end
	end
	------------------------ TotemPlates Handling ------------------------
	local nameText = Virtual.nameText:GetText()
	local totemTex = TotemPlates[nameText]
	if totemTex then
		if not self.totemPlate then
			SetupTotemPlate(self) -- Setup TotemPlate on the fly
		end
		Virtual:Hide()
		-- Delay frame to ensure namePlateUnitToken is available and UnitCanAttack returns valid data
		self.delayFrame:SetScript("OnUpdate", function(delayFrame)
			delayFrame:SetScript("OnUpdate", nil)
			local unitToken = self.namePlateUnitToken
			if unitToken then
				local isEnemy = UnitCanAttack("player", unitToken) == 1
				if totemTex ~= "" and isEnemy then
					self.totemPlate:Show()
					self.totemPlate.icon:SetTexture(totemsTexPath .. totemTex)
				end	
			end
		end)
	else
		if self.totemPlate then self.totemPlate:Hide() end
		-------------- Nameplate Visibility Filter --------------
		local levelText = Virtual.levelText:GetText()
		local levelNumber = tonumber(levelText)
		if levelNumber and levelNumber < AP.OptionsCharacter.LevelFilter then
			Virtual:Hide() -- Hide low level nameplates
		else
			-- Delay frame to ensure namePlateUnitToken is available and UnitIsPlayer returns valid data
			self.delayFrame:SetScript("OnUpdate", function(delayFrame)
				delayFrame:SetScript("OnUpdate", nil)
				local unitToken = self.namePlateUnitToken
				if unitToken then
					local isPlayer = UnitIsPlayer(unitToken) == 1
					if filterPlayers and not isPlayer then
						Virtual:Hide() -- Hide non-players nameplates
					else
						------------------- Show class icons on allies during PvP -------------------
						if Virtual.classIcon then
							local isFriendly = not UnitCanAttack("player", unitToken)
							local ShowClassIcons = AP.OptionsCharacter.ShowClassIcons
							if isPlayer and isFriendly and inPvPinstance and ShowClassIcons then
								local class = select(2, UnitClass(unitToken))
								Virtual.classIcon:SetTexture(classesTexPath .. class)
								Virtual.classIcon:Show()
							else
								Virtual.classIcon:Hide()
							end
						end
					end
				end
			end)
		end	
	end
	if not AP.OptionsCharacter.DynamicScaling then
		if totemTex then
			SetScale(Virtual, 0.001)
		else
			SetScale(Virtual, AP.OptionsCharacter.MaxScaleEnabled and AP.OptionsCharacter.MaxScale or 1)
		end
		if self.totemPlate then
			SetScale(self.totemPlate, AP.OptionsCharacter.MaxScaleEnabled and AP.OptionsCharacter.MaxScale or 1)
		end 
	end	
end
--- Removes the plate from the visible list when hidden.
function AP:PlateOnHide()
	PlatesVisible[self] = nil
	local Virtual = VirtualPlates[self]
	if self.totemPlate then self.totemPlate:Hide() end
	if Virtual.classIcon then Virtual.classIcon:Hide() end
	Virtual:Hide() -- Explicitly hide so IsShown returns false.
end

-- Main plate handling and updating	
do
	do
		local PlatesUpdate
		do
			function PlatesUpdate()
				if not next(PlatesVisible) then return end
				if AP.OptionsCharacter.DynamicScaling then
					-------------- Scales and fades plates based on distance to the player --------------
					local MinScale = AP.OptionsCharacter.MinScale or 0.2
					local MaxScale = AP.OptionsCharacter.MaxScaleEnabled and AP.OptionsCharacter.MaxScale
					local ScaleNormDist = AP.OptionsCharacter.ScaleNormDist
					local Distances = C_NamePlate_GetNamePlatesDistance()
					for Plate, Virtual in pairs(PlatesVisible) do
						local healthBar = Virtual.healthBar
						local castBar = Virtual.castBar
						local castBarBorder = Virtual.castBarBorder
						local healthBarHighlight = Virtual.healthBarHighlight
						local classIcon = Virtual.classIcon
						local Depth = Virtual:GetEffectiveDepth() -- Depth of the real plate is blacklisted, so use child Virtual instead
						local Distance = Distances and Distances[Plate]
						local nameText_alpha = 1
						local totemPlate_alpha
						local Scale
						if Distance then
							if showDistanceText then 
								Virtual.distanceText:SetText(string.format("%.0f yd", Distance)) 
							end
							local function SetRegionsAlpha(alpha)
								if healthBar.healthBarBorder then healthBar.healthBarBorder:SetAlpha(alpha) end
								if healthBar.nameText then healthBar.nameText:SetAlpha(alpha) end
								if healthBar.healthText then healthBar.healthText:SetAlpha(alpha) end
								if castBarBorder then castBarBorder:SetAlpha(alpha) end
								if castBar.castTimerText then castBar.castTimerText:SetAlpha(alpha) end
								if castBar.castText then castBar.castText:SetAlpha(alpha) end
								if classIcon then classIcon:SetAlpha(alpha) end
							end
							if Depth > CameraClip then
								if Distance <= fadeEnd or UnitIsPlayer(Plate.namePlateUnitToken) == 1 then
									local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeStart) / (fadeEnd - fadeStart))))
									SetRegionsAlpha(alpha)
									SetAlpha(Virtual, 1)
									nameText_alpha = alpha
									totemPlate_alpha = alpha
								else
									local alpha = math_max(0, math_min(1, 1 - ((Distance - fadeEnd) / 30)))
									SetRegionsAlpha(0)
									SetAlpha(Virtual, alpha)
									nameText_alpha = 0
								end
							elseif Depth > 0 then -- Begin fading as nameplate passes behind screen
								SetRegionsAlpha(1)
								SetAlpha(Virtual, Depth/CameraClip)
							else
								SetAlpha(Virtual, 0) -- Too close to camera; Completely hidden
							end
							MaxScale = MaxScale or 1
							if ScaleNormDist < distanceLimit then
								if Distance <= ScaleNormDist then
									Scale = MaxScale
								elseif Distance >= distanceLimit then
									Scale = MinScale
								else
									Scale = MaxScale - (MaxScale - MinScale) * (Distance - ScaleNormDist) / (distanceLimit - ScaleNormDist)
								end
							else
								Scale = MaxScale
							end
						end
						------------------ TotemPlates Visual Update ------------------
						local totemTex = TotemPlates[healthBar.nameText:GetText()]
						if Plate.totemPlate and totemTex then
							if totemTex ~= "" then
								SetScale(Plate.totemPlate, Scale)
								if Distance then
									local alpha = totemPlate_alpha or math_max(0, math_min(1, 1 - ((Distance - fadeStart) / (fadeEnd - fadeStart))))
									SetAlpha(Plate.totemPlate, alpha)
								end
							end
							Scale = 0.001 -- Shrinks the nameplate hitbox to effectively disable interaction
						end
						----------------------- Improved mouseover highlight handling -----------------------
						if Plate == C_NamePlate_GetNamePlateForUnit("mouseover") and not UnitIsUnit("target","mouseover") then
							healthBarHighlight:Show()
							healthBar.nameText:SetTextColor(1, 1, 0, nameText_alpha) -- yellow
							if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Show() end
						else
							healthBarHighlight:Hide()
							healthBar.nameText:SetTextColor(nameText_colorR, nameText_colorG, nameText_colorB, nameText_alpha)
							if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Hide() end
						end
						if not Virtual:IsShown() then 
							Scale = 0.001
						end
						SetScale(Virtual, Scale)
						if not InCombat then
							local Width, Height = Virtual:GetSize()
							Plate:SetSize(0.88 * Width * Scale, 0.8 * Height * Scale)
						end
					end
				else
					local Distances = showDistanceText and C_NamePlate_GetNamePlatesDistance()	
					for Plate, Virtual in pairs(PlatesVisible) do
						local Depth = Virtual:GetEffectiveDepth()
						if Depth > CameraClip then
							SetAlpha(Virtual, 1)
						elseif Depth > 0 then
							SetAlpha(Virtual, Depth / CameraClip)
						else
							SetAlpha(Virtual, 0)
						end
						------------------------ Distance Text Update ------------------------
						if Distances then
							Virtual.distanceText:SetText(string.format("%.0f yd", Distances[Plate])) 
						end
						---------------------------- Improved mouseover highlight handling ----------------------------
						local healthBar = Virtual.healthBar
						local healthBarHighlight = Virtual.healthBarHighlight
						if Plate == C_NamePlate_GetNamePlateForUnit("mouseover") and not UnitIsUnit("target","mouseover") then
							healthBarHighlight:Show()
							healthBar.nameText:SetTextColor(1, 1, 0, 1) -- yellow
							if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Show() end
						else
							healthBarHighlight:Hide()
							healthBar.nameText:SetTextColor(nameText_colorR, nameText_colorG, nameText_colorB, 1)
							if Plate.totemPlate then Plate.totemPlate.mouseoverGlow:Hide() end
						end
					end
				end
			end
		end

		--- Parents all plate children to the Virtual, and saves references to them in the plate.
		-- @ param Plate  Original nameplate children are being removed from.
		-- @ param ...  Children of Plate to be reparented.
		local function ReparentChildren(Plate, ...)
			local Virtual = VirtualPlates[Plate]
			for Index = 1, select("#", ...) do
				local Child = select(Index, ...)
				if Child ~= Virtual then
					local LevelOffset = Child:GetFrameLevel() - Plate:GetFrameLevel()
					Child:SetParent( Virtual )
					Child:SetFrameLevel(Virtual:GetFrameLevel() + LevelOffset) -- Maintain relative frame levels
					Plate[#Plate + 1] = Child;
				end
			end
		end
		--- Parents all plate regions to the Virtual, similar to ReparentChildren.
		-- @ see ReparentChildren
		local function ReparentRegions(Plate, ...)
			local Virtual = VirtualPlates[Plate]
			for Index = 1, select("#", ...) do
				local Region = select(Index, ...)
				Region:SetParent(Virtual)
				Plate[#Plate + 1] = Region
			end
		end

		-- Creates a semi-transparent hitbox texture for debugging
		local function SetupHitboxTexture(Plate)
			Plate.hitBox = Plate:CreateTexture(nil, "BACKGROUND")
			Plate.hitBox:SetTexture(0,0,0,0.5)
			Plate.hitBox:SetAllPoints(Plate)
		end

		--- Adds and skins a new nameplate.
		-- @ param Plate  Newly found default nameplate to be hooked.
		local function PlateAdd(Plate)
			local Virtual = CreateFrame("Frame", nil, Plate)

			VirtualPlates[Plate] = Virtual
			RealPlates[Virtual] = Plate
			Plate.VirtualPlate = Plate.VirtualPlate or Virtual
			Virtual.RealPlate = Virtual.RealPlate or Plate
			
			Virtual:Hide() -- Gets explicitly shown on plate show
			Virtual:SetPoint("TOP")
			Virtual:SetSize(Plate:GetSize())

			ReparentChildren(Plate, Plate:GetChildren())
			ReparentRegions(Plate, Plate:GetRegions())
			Virtual:EnableDrawLayer("HIGHLIGHT") -- Allows the highlight to show without enabling mouse events

			Plate:SetScript("OnShow", AP.PlateOnShow)
			Plate:SetScript("OnHide", AP.PlateOnHide)

			-- Hook methods
			for Key, Value in pairs(PlateOverrides) do
				Virtual[Key] = Value
			end

			CustomizePlate(Virtual)
			Plate.delayFrame = CreateFrame("Frame")
			--SetupHitboxTexture(Plate)

			-- Force recalculation of effective depth for all child frames
			local Depth = WorldFrame:GetDepth()
			WorldFrame:SetDepth(Depth + 1)
			WorldFrame:SetDepth(Depth)
		end

		------------------------------------ Improved NamePlates Scan ------------------------------------
		-- Efficient event-based nameplate scan (almost always fires before WorldFrame's children update)
		local NamePlate_Events = CreateFrame("Frame")
		NamePlate_Events:RegisterEvent("NAME_PLATE_CREATED")
		NamePlate_Events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		NamePlate_Events:SetScript("OnEvent", function(_, event, arg)
			if event == "NAME_PLATE_CREATED" then	
				local Plate = arg
				if not VirtualPlates[Plate] then
					PlateAdd(Plate)
				end
			elseif event == "NAME_PLATE_UNIT_ADDED" then
				local token = arg
				local Plate = C_NamePlate_GetNamePlateForUnit(token)
				if Plate and not Plate.namePlateUnitToken then
					Plate.namePlateUnitToken = token
					if Plate:IsVisible() then
						AP.PlateOnShow(Plate)
					end
				end
			end
		end)
		-- Backup scan with WorldFrame's children (sometimes fires first when many plates spawn at once)
		local function IsNamePlate(frame)
			if frame:GetName() then return false end
			local region = select(2, frame:GetRegions())
			return region and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
		end
		local ChildCount, NewChildCount = 0;
		WorldFrame:HookScript("OnUpdate", function()
			NewChildCount = WorldFrame:GetNumChildren()
			if ChildCount ~= NewChildCount then
				local WFchildren = {WorldFrame_GetChildren(WorldFrame)}
				for i = ChildCount + 1, NewChildCount do
					local child = WFchildren[i]
					if not VirtualPlates[child] and IsNamePlate(child) then
						PlateAdd(child)
					end
				end
				ChildCount = NewChildCount
			end
		end)
		--------------------------------------------------------------------------------------------------

		function AP:WorldFrameOnUpdate(elapsed)
			-- Apply depth to found plates
			NextUpdate = NextUpdate - elapsed
			if NextUpdate <= 0 then
				NextUpdate = UpdateRate
				return PlatesUpdate()
			end
		end
	end

	local Children = {}
	--- Filters the results of WorldFrame:GetChildren to replace plates with their virtuals.
	local function ReplaceChildren(...)
		local Count = select("#", ...)
		for Index = 1, Count do
			local Frame = select(Index, ...)
			Children[Index] = VirtualPlates[Frame] or Frame
		end
		for Index = Count + 1, #Children do -- Remove any extras from the last call
			Children[Index] = nil
		end
		return unpack(Children)
	end
	--- Returns Virtual frames in place of real nameplates.
	-- @ return The results of WorldFrame:GetChildren with any reference to a plate replaced with its virtuals.
	function WorldFrame:GetChildren(...)
		return ReplaceChildren(WorldFrame_GetChildren(self, ...))
	end
end

--- Initializes settings once loaded.
function AP.Frame:ADDON_LOADED(Event, Addon)
	if Addon ~= AddonName then return end
	self:UnregisterEvent(Event)
	self[Event] = nil
	local OptionsCharacter = AwesomePlatesOptionsCharacter
	AwesomePlatesOptionsCharacter = AP.OptionsCharacter
	AP.Synchronize(OptionsCharacter) -- Loads defaults if either are nil
	print(" |cffCCCC88AwesomePlates|r v" .. AP.Version .. " by |cffc41f3bKhal|r")
end
--- Caches in-combat status when leaving combat.
function AP.Frame:PLAYER_REGEN_ENABLED()
	InCombat = false
end
--- Restores plates to their real size before entering combat.
function AP.Frame:PLAYER_REGEN_DISABLED()
	InCombat = true
end
--- Tracks PvP instance
function AP.Frame:PLAYER_ENTERING_WORLD()
	local instanceType = select(2, IsInInstance())
	inPvPinstance = (instanceType == "pvp")
end
--- Global event handler.
function AP.Frame:OnEvent(Event, ...)
	if self[Event] then
		return self[Event](self, Event, ...)
	end
end

--- Sets the minimum scale plates will be shrunk to.
-- @ param Value  New mimimum scale to use.
-- @ return True if setting changed.
function AP.SetMinScale(Value)
	if Value ~= AP.OptionsCharacter.MinScale then
		AP.OptionsCharacter.MinScale = Value
		AP.Config.MinScale:SetValue(Value)
		return true
	end
end
--- Sets the maximum scale plates will grow to.
-- @ param Value  New maximum scale to use.
-- @ return True if setting changed.
function AP.SetMaxScale(Value)
	if Value ~= AP.OptionsCharacter.MaxScale then
		AP.OptionsCharacter.MaxScale = Value
		AP.Config.MaxScale:SetValue(Value)
		return true
	end
end
--- Enables clamping nameplates to a maximum scale.
-- @ param Enable  Boolean to allow using the MaxScale setting.
-- @ return True if setting changed.
function AP.SetMaxScaleEnabled(Enable)
	if Enable ~= AP.OptionsCharacter.MaxScaleEnabled then
		AP.OptionsCharacter.MaxScaleEnabled = Enable
		AP.Config.MaxScaleEnabled:SetChecked(Enable)
		AP.Config.MaxScaleEnabled.setFunc(Enable and "1" or "0")
		return true
	end
end
--- Sets the scale factor apply to plates.
-- @ param Value  When nameplates are this many yards from the screen, they'll be normal sized.
-- @ return True if setting changed.
function AP.SetScaleNormDist(Value)
	if Value ~= AP.OptionsCharacter.ScaleNormDist then
		AP.OptionsCharacter.ScaleNormDist = Value
		AP.Config.ScaleNormDist:SetValue(Value)
		return true
	end
end

function AP.SetShowClassIcons(Enable)
	if Enable ~= AP.OptionsCharacter.ShowClassIcons then
		AP.OptionsCharacter.ShowClassIcons = Enable
		return true
	end
end

function AP.SetDynamicScaling(Enable)
	if Enable ~= AP.OptionsCharacter.DynamicScaling then
		AP.OptionsCharacter.DynamicScaling = Enable
		return true
	end
end

function AP.SetLevelFilter(Value)
	if Value ~= AP.OptionsCharacter.LevelFilter then
		AP.OptionsCharacter.LevelFilter = Value
		return true
	end
end

--- Synchronizes addon settings with an options table.
-- @ param OptionsCharacter  An options table to synchronize with, or nil to use defaults.
function AP.Synchronize (OptionsCharacter)
	-- Load defaults if settings omitted
	if not OptionsCharacter then
		OptionsCharacter = AP.OptionsCharacterDefault
	end

	for key, defaultValue in pairs(AP.OptionsCharacterDefault) do
		if OptionsCharacter[key] == nil then
			OptionsCharacter[key] = defaultValue
		end
	end

	AP.SetMinScale(OptionsCharacter.MinScale)
	AP.SetMaxScale(OptionsCharacter.MaxScale)
	AP.SetMaxScaleEnabled(OptionsCharacter.MaxScaleEnabled)
	AP.SetScaleNormDist(OptionsCharacter.ScaleNormDist)
	AP.SetShowClassIcons(OptionsCharacter.ShowClassIcons)
	AP.SetDynamicScaling(OptionsCharacter.DynamicScaling)
	AP.SetLevelFilter(OptionsCharacter.LevelFilter)
end

WorldFrame:HookScript("OnUpdate", AP.WorldFrameOnUpdate) -- First OnUpdate handler to run
AP.Frame:SetScript("OnEvent", AP.Frame.OnEvent)
AP.Frame:RegisterEvent("ADDON_LOADED")
AP.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
AP.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
AP.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local GetParent = AP.Frame.GetParent
do
	--- Add method overrides to be applied to plates' Virtuals.
	local function AddPlateOverride(MethodName)
		PlateOverrides[MethodName] = function(self, ...)
			local Plate = GetParent(self)
			return Plate[MethodName](Plate, ...)
		end
	end
	AddPlateOverride("GetParent")
	AddPlateOverride("SetAlpha")
	AddPlateOverride("GetAlpha")
	AddPlateOverride("GetEffectiveAlpha")
end
-- Method overrides to use plates' OnUpdate script handlers instead of their Virtuals' to preserve handler execution order
do
	--- Wrapper for plate OnUpdate scripts to replace their self parameter with the plate's Virtual.
	local function OnUpdateOverride(self, ...)
		self.OnUpdate(VirtualPlates[self], ...)
	end
	local type = type

	local SetScript = AP.Frame.SetScript
	--- Redirects all SetScript calls for the OnUpdate handler to the original plate.
	function PlateOverrides:SetScript(Script, Handler, ...)
		if type(Script) == "string" and Script:lower() == "onupdate" then
			local Plate = GetParent(self)
			Plate.OnUpdate = Handler
			return Plate:SetScript(Script, Handler and OnUpdateOverride or nil, ...)
		else
			return SetScript(self, Script, Handler, ...)
		end
	end

	local GetScript = AP.Frame.GetScript
	--- Redirects calls to GetScript for the OnUpdate handler to the original plate's script.
	function PlateOverrides:GetScript(Script, ...)
		if type(Script) == "string" and Script:lower() == "onupdate" then
			return GetParent(self).OnUpdate
		else
			return GetScript(self, Script, ...)
		end
	end

	local HookScript = AP.Frame.HookScript;
	--- Redirects all HookScript calls for the OnUpdate handler to the original plate.
	-- Also passes the virtual to the hook script instead of the plate.
	function PlateOverrides:HookScript(Script, Handler, ...)
		if type(Script) == "string" and Script:lower() == "onupdate" then
			local Plate = GetParent(self)
			if Plate.OnUpdate then
				-- Hook old OnUpdate handler
				local Backup = Plate.OnUpdate
				function Plate:OnUpdate(...)
					Backup(self, ...) -- Technically we should return Backup's results to match HookScript's hook behavior,
					return Handler(self, ... ) -- but the overhead isn't worth it when these results get discarded.
				end
			else
				Plate.OnUpdate = Handler
			end
			return Plate:SetScript(Script, OnUpdateOverride, ...)
		else
			return HookScript(self, Script, Handler, ...)
		end
	end
end

local HelpTextList = {
    '  |cffCCCC88========== AwesomePlates Commands ==========|r',
    '  |cff00FF98  /ap scaling|r    : Toggle dynamic scaling',
    '  |cff00FF98  /ap icons|r       : Toggle class icons on PvP allies',
    '  |cff00FF98  /ap players|r    : Toggle player-only filter',
    '  |cff00FF98  /ap distance|r  : Toggle distance text',
    '  |cff00FF98  /ap level <#>|r : Set minimum nameplate level filter',
    '  |cffCCCC88============================================|r'
}

local function APprint(...)
	print("|cffCCCC88[AwesomePlates]:|r", ...)
end

SLASH_AP1 = "/ap"
SlashCmdList["AP"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    if cmd == "scaling" then
        AP.OptionsCharacter.DynamicScaling = not AP.OptionsCharacter.DynamicScaling
        if AP.OptionsCharacter.DynamicScaling then
            APprint("Dynamic scaling |cff88FF88enabled|r")
        else
            for Plate, Virtual in pairs(VirtualPlates) do
                local castBarBorder = Virtual.castBarBorder
                local classIcon = Virtual.classIcon
                local healthBar = Virtual.healthBar
                local castBar = Virtual.castBar
                if healthBar.healthBarBorder then healthBar.healthBarBorder:SetAlpha(1) end
                if healthBar.nameText then healthBar.nameText:SetAlpha(1) end
                if healthBar.healthText then healthBar.healthText:SetAlpha(1) end
                if castBarBorder then castBarBorder:SetAlpha(1) end
                if castBar.castTimerText then castBar.castTimerText:SetAlpha(1) end
                if castBar.castText then castBar.castText:SetAlpha(1) end
                if classIcon then classIcon:SetAlpha(1) end
                SetAlpha(Virtual, 1)
                if TotemPlates[healthBar.nameText:GetText()] then
                    SetScale(Virtual, 0.001)
                else
                    SetScale(Virtual, AP.OptionsCharacter.MaxScaleEnabled and AP.OptionsCharacter.MaxScale or 1)
                end
                if Plate.totemPlate then
                    SetAlpha(Plate.totemPlate, 1)
                    SetScale(Plate.totemPlate, AP.OptionsCharacter.MaxScaleEnabled and AP.OptionsCharacter.MaxScale or 1)
                end
                if not InCombat then
                    Plate:SetSize(NP_WIDTH, NP_HEIGHT)
                end
            end
            APprint("Dynamic scaling |cffff4444disabled|r")
        end
    elseif cmd == "icons" then
        AP.OptionsCharacter.ShowClassIcons = not AP.OptionsCharacter.ShowClassIcons
        for Plate, _ in pairs(PlatesVisible) do
            AP.PlateOnShow(Plate)
        end	
        if AP.OptionsCharacter.ShowClassIcons then
            APprint("Class icons in PvP instance |cff88FF88enabled|r")
        else
            APprint("Class icons in PvP instance |cffff4444disabled|r")
        end
    elseif cmd == "distance" then
        showDistanceText = not showDistanceText
        if not showDistanceText then
            for _, Virtual in pairs(VirtualPlates) do
                if Virtual.distanceText then
                    Virtual.distanceText:SetText("")
                end
            end
        end
    elseif cmd == "players" then
        filterPlayers = not filterPlayers
        for Plate, _ in pairs(PlatesVisible) do
            AP.PlateOnShow(Plate)
        end
        if filterPlayers then
            APprint("Player filter |cff88FF88enabled|r")
        else
            APprint("Player filter |cffff4444disabled|r")
        end
	elseif cmd == "level" then
		if arg == "" then
			APprint("Current minimum nameplate level filter is |cff3399ff" .. AP.OptionsCharacter.LevelFilter .. "|r")
			return
		end
		local num = tonumber(arg)
		if not num then
			APprint("Invalid argument. Please enter a number.")
			return
		end
		local level = math_floor(num)
		if level < 1 then
			level = 1
		elseif level > 80 then
			level = 80
		end
		AP.OptionsCharacter.LevelFilter = level
        for Plate, _ in pairs(PlatesVisible) do
            AP.PlateOnShow(Plate)
        end
		APprint("Minimum nameplate level filter set to |cff3399ff" .. AP.OptionsCharacter.LevelFilter .. "|r")
    else
        for _, line in ipairs(HelpTextList) do
            print(line)
        end
    end
end