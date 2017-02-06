
-- GLOBALS: UIParent GameTooltip print
-- GLOBALS: LibStub
-- GLOBALS: SLASH_KrosusAssist1 SLASH_KrosusAssist2
-- GLOBALS: BigWigsKrosusFirstBeamWasLeft DBMUpdateKrosusBeam

-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin = CreateFrame("Frame", "KrosusAssist")

plugin.defaultDB = {
	profile = {
		posx = nil,
		posy = nil,
		lock = nil,
		width = 180,
		height = 160,
		disabled = false,
		font = nil,
		fontSize = nil,
	},
}

-------------------------------------------------------------------------------
-- Helper functions
--

function plugin:Print(...)
	print("|cffffff00KrosusAssist:|r", ...)
end

-------------------------------------------------------------------------------
-- Locals
--

local db = nil
local display = nil
local media = LibStub("LibSharedMedia-3.0")
local inConfigMode = nil

local L = LibStub("AceLocale-3.0"):NewLocale("KrosusAssist", "enUS", true)
if L then
	L["Krosus Assist"] = true
	L["Disabled"] = true
	L["Disable the plugin."] = true
	L["Lock"] = true
	L["Locks the display in place, preventing moving and resizing."] = true
	L["Font"] = true
	L["Font size"] = true
	L["X Position"] = true
	L["Y Position"] = true
	L["Exact Positioning"] = true
	L["Type in the box or move the slider if you need exact positioning from the anchor."] = true
	L["Close"] = true
	L["Closes the display.\n\nTo disable it completely, you have to go into the options and toggle the 'disabled' checkbox."] = true
	L["The display will show next time. To disable it completely, you have to go into the options and toggle the 'disabled' checkbox."] = true
	L["Where was the first Fel Beam?"] = true
	L["left"] = true
	L["right"] = true
	L["You are using no or an outdated version of a boss mod. Please update your existing mod or download BigWigs."] = true
	L["Reset"] = true
	L["Resets the display to its default position"] = true
end
L = LibStub("AceLocale-3.0"):GetLocale("KrosusAssist")

plugin.displayName = L["Krosus Assist"]

-------------------------------------------------------------------------------
-- Display Window
--

local function onDragStart(self) self:StartMoving() end
local function onDragStop(self)
	self:StopMovingOrSizing()
	local s = self:GetEffectiveScale()
	db.posx = self:GetLeft() * s
	db.posy = self:GetTop() * s
	plugin:RestyleWindow()
end
local function OnDragHandleMouseDown(self) self.frame:StartSizing("BOTTOMRIGHT") end
local function OnDragHandleMouseUp(self, button) self.frame:StopMovingOrSizing() end
local function onResize(self, width, height)
	db.width = width
	db.height = height
end

local locked = nil
local function lockDisplay()
	if locked then return end
	if not inConfigMode then
		display:EnableMouse(false) -- Keep enabled during config mode
	end
	display:SetMovable(false)
	display:SetResizable(false)
	display:RegisterForDrag()
	display:SetScript("OnSizeChanged", nil)
	display:SetScript("OnDragStart", nil)
	display:SetScript("OnDragStop", nil)
	display.drag:Hide()
	locked = true
end
local function unlockDisplay()
	if not locked then return end
	display:EnableMouse(true)
	display:SetMovable(true)
	display:SetResizable(true)
	display:RegisterForDrag("LeftButton")
	display:SetScript("OnSizeChanged", onResize)
	display:SetScript("OnDragStart", onDragStart)
	display:SetScript("OnDragStop", onDragStop)
	display.drag:Show()
	locked = nil
end

local function onControlEnter(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:AddLine(self.tooltipHeader)
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local function createHighlightTexture(self)
	local texture = self:CreateTexture(nil, "OVERLAY")
	self.highlight = texture
	texture:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
	texture:SetBlendMode("ADD")
	texture:SetAllPoints(self)
	texture:SetAlpha(.15)
	return texture
end

local function onButtonEnter(self)
	if not self.highlight then
		createHighlightTexture(self)
	end
	self.highlight:Show()
	self:SetBackdropBorderColor(1, 1, 1)
end

local function onButtonLeave(self)
	if self.highlight then
		self.highlight:Hide()
	end
	self:SetBackdropBorderColor(0, 0, 0)
end

function plugin:RestyleWindow()
	if not display then return end

	display.question:SetFont(media:Fetch("font", db.font), db.fontSize)
	local font = CreateFont("KrosusAssistFont")
	font:SetFont(media:Fetch("font", db.font), db.fontSize)
	display.buttonLeft:SetNormalFontObject(font)
	display.buttonRight:SetNormalFontObject(font)

	if db.lock then
		locked = nil
		lockDisplay()
	else
		locked = true
		unlockDisplay()
	end

	local x = db.posx
	local y = db.posy
	if x and y then
		local s = display:GetEffectiveScale()
		display:ClearAllPoints()
		display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
	else
		display:ClearAllPoints()
		display:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
	end

	local question = display.question
	question:SetWidth(display:GetWidth())
	display.buttonLeft:ClearAllPoints()
	display.buttonLeft:SetPoint("TOPLEFT", display, "TOPLEFT", 2, -question:GetHeight()-2)
	display.buttonLeft:SetPoint("BOTTOMRIGHT", display, "BOTTOM", 1, 2)
	display.buttonRight:ClearAllPoints()
	display.buttonRight:SetPoint("TOPLEFT", display, "TOP", 1, -question:GetHeight()-2)
	display.buttonRight:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -2, 2)
end

local function updateProfile()
	db = plugin.db.profile

	if not db.font then
		db.font = media:GetDefault("font")
	end
	if not db.fontSize then
		db.fontSize = 18
	end

	plugin:RestyleWindow()
end

local function resetAnchor()
	display:ClearAllPoints()
	display:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
	db.width = plugin.defaultDB.profile.width
	db.height = plugin.defaultDB.profile.height
	display:SetWidth(db.width)
	display:SetHeight(db.height)
	db.posx = nil
	db.posy = nil
end

-------------------------------------------------------------------------------
-- Initialization
--

local createAnchor = function()
	local anchor = CreateFrame("Frame", "KrosusAssistAnchor", UIParent)
	anchor:SetWidth(db.width)
	anchor:SetHeight(db.height)
	anchor:SetMinResize(100, 30)
	anchor:SetClampedToScreen(true)
	anchor:EnableMouse(true)

	local bg = anchor:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(anchor)
	bg:SetColorTexture(0, 0, 0, 0.3)
	anchor.background = bg

	local close = CreateFrame("Button", nil, anchor)
	close:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", -2, 2)
	close:SetFrameLevel(anchor:GetFrameLevel() + 5) -- place this above everything
	close:SetHeight(16)
	close:SetWidth(16)
	close.tooltipHeader = L["Close"]
	close.tooltipText = L["Closes the display.\n\nTo disable it completely, you have to go into the options and toggle the 'disabled' checkbox."]
	close:SetScript("OnEnter", onControlEnter)
	close:SetScript("OnLeave", onControlLeave)
	close:SetScript("OnClick", function()
		plugin:Print(L["The display will show next time. To disable it completely, you have to go into the options and toggle the 'disabled' checkbox."])
		plugin:Close(true)
	end)
	close:SetNormalTexture("Interface\\AddOns\\KrosusAssist\\Textures\\close")
	anchor.close = close

	local header = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	header:SetText(L["Krosus Assist"])
	header:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
	anchor.title = header

	local question = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	question:SetText(L["Where was the first Fel Beam?"])
	question:SetPoint("TOP", anchor, "TOP")
	anchor.question = question

	local buttonLeft = CreateFrame("Button", nil, anchor)
	buttonLeft:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, question:GetHeight())
	buttonLeft:SetPoint("BOTTOMRIGHT", anchor, "BOTTOM")
	buttonLeft:SetNormalFontObject("GameFontHighlightSmall")
	buttonLeft:SetText(L["left"])
	buttonLeft:SetScript("OnEnter", onButtonEnter)
	buttonLeft:SetScript("OnLeave", onButtonLeave)
	buttonLeft:SetScript("OnClick", function()
		plugin:BeamWasLeft(true)
	end)
	buttonLeft:SetBackdrop({
		bgFile = [[Interface/DialogFrame/UI-DialogBox-Background]],
		edgeFile = [[Interface/Buttons/WHITE8X8]],
		edgeSize = 3,
	})
	buttonLeft:SetBackdropColor(0.15, 0.15, 0.15, .5)
	buttonLeft:SetBackdropBorderColor(0, 0, 0)
	anchor.buttonLeft = buttonLeft

	local buttonRight = CreateFrame("Button", nil, anchor)
	buttonRight:SetPoint("TOPLEFT", anchor, "TOP", 0, question:GetHeight())
	buttonRight:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT")
	buttonRight:SetNormalFontObject("GameFontHighlightSmall")
	buttonRight:SetText(L["right"])
	buttonRight:SetScript("OnEnter", onButtonEnter)
	buttonRight:SetScript("OnLeave", onButtonLeave)
	buttonRight:SetScript("OnClick", function()
		plugin:BeamWasLeft(false)
	end)
	buttonRight:SetBackdrop({
		bgFile = [[Interface/DialogFrame/UI-DialogBox-Background]],
		edgeFile = [[Interface/Buttons/WHITE8X8]],
		edgeSize = 3,
	})
	buttonRight:SetBackdropColor(0.15, 0.15, 0.15, .5)
	buttonRight:SetBackdropBorderColor(0, 0, 0)
	anchor.buttonRight = buttonRight

	local function showAnimParent(frame) frame:GetParent():Show() frame.playing = true end
	local function hideAnimParent(frame) frame:GetParent():Hide() frame.playing = nil end

	local drag = CreateFrame("Frame", nil, anchor)
	drag.frame = anchor
	drag:SetFrameLevel(anchor:GetFrameLevel() + 5) -- place this above everything
	drag:SetWidth(16)
	drag:SetHeight(16)
	drag:SetPoint("BOTTOMRIGHT", anchor, -1, 1)
	drag:EnableMouse(true)
	drag:SetScript("OnMouseDown", OnDragHandleMouseDown)
	drag:SetScript("OnMouseUp", OnDragHandleMouseUp)
	drag:SetAlpha(0.5)
	anchor.drag = drag

	local tex = drag:CreateTexture(nil, "OVERLAY")
	tex:SetTexture("Interface\\AddOns\\KrosusAssist\\Textures\\draghandle")
	tex:SetWidth(16)
	tex:SetHeight(16)
	tex:SetBlendMode("ADD")
	tex:SetPoint("CENTER", drag)

	plugin:RestyleWindow()

	anchor:Hide()
	display = anchor
end

function plugin:OnPluginDisable()
	self:Close(true)
end

-------------------------------------------------------------------------------
-- Options
--

function plugin:StartConfigureMode()
	inConfigMode = true
	self:Test()
end

function plugin:StopConfigureMode()
	inConfigMode = nil
	if db.lock then
		display:EnableMouse(false) -- Mouse disabled whilst locked, but we enable it in test mode. Re-disable it.
	end
	self:Close(true)
end

local disabled = function() return plugin.db.profile.disabled end
local function GetOptions()
	local options = {
		name = L["Krosus Assist"],
		type = "group",
		get = function(info)
			local key = info[#info]
			if key == "font" then
				for i, v in next, media:List("font") do
					if v == db.font then return i end
				end
			elseif key == "soundName" then
				for i, v in next, media:List("sound") do
					if v == db.soundName then return i end
				end
			else
				return db[key]
			end
		end,
		set = function(info, value)
			local key = info[#info]
			if key == "font" then
				db.font = media:List("font")[value]
			elseif key == "soundName" then
				db.soundName = media:List("sound")[value]
			else
				db[key] = value
			end
			plugin:RestyleWindow()
		end,
		args = {
			disabled = {
				type = "toggle",
				name = L["Disabled"],
				desc = L["Disable the plugin."],
				order = 1,
			},
			lock = {
				type = "toggle",
				name = L["Lock"],
				desc = L["Locks the display in place, preventing moving and resizing."],
				order = 2,
				disabled = disabled,
				set = function(info, value)
					local key = info[#info]
					db[key] = value
					if value then
						plugin:StopConfigureMode()
					else
						plugin:StartConfigureMode()
					end
					plugin:RestyleWindow()
				end,
			},
			reset = {
				type = "execute",
				name = L["Reset"],
				desc = L["Resets the display to its default position"],
				order = 3,
				func = resetAnchor,
			},
			font = {
				type = "select",
				name = L["Font"],
				order = 10,
				values = media:HashTable("font"),
				width = "full",
				dialogControl = 'LSM30_Font',
			},
			fontSize = {
				type = "range",
				name = L["Font size"],
				order = 11,
				max = 40,
				min = 8,
				step = 1,
				width = "full",
			},
			exactPositioning = {
				type = "group",
				name = L["Exact Positioning"],
				order = 20,
				inline = true,
				args = {
					posx = {
						type = "range",
						name = L["X Position"],
						desc = L["Type in the box or move the slider if you need exact positioning from the anchor."],
						min = 0,
						max = 2048,
						step = 1,
						order = 1,
						width = "full",
					},
					posy = {
						type = "range",
						name = L["Y Position"],
						desc = L["Type in the box or move the slider if you need exact positioning from the anchor."],
						min = 0,
						max = 2048,
						step = 1,
						order = 2,
						width = "full",
					},
				},
			},
		},
	}
	return options
end

-------------------------------------------------------------------------------
-- Events
--

function plugin:ADDON_LOADED(...)
	if select(1,...) == "KrosusAssist" then
		self:UnregisterEvent("ADDON_LOADED")
		plugin.db = LibStub("AceDB-3.0"):New("KrosusAssistDB", plugin.defaultDB, true)
		LibStub("AceConfig-3.0"):RegisterOptionsTable("Krosus Assist", GetOptions())
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Krosus Assist", "Krosus Assist")
		updateProfile()

		if createAnchor then createAnchor() createAnchor = nil end

		self:RestyleWindow()

		self:RegisterEvent("ENCOUNTER_START")
		self:RegisterEvent("ENCOUNTER_END")
	end
end

function plugin:ENCOUNTER_START(encounterID)
	if db.disabled or encounterID ~= 1842 then return end
	self:Open()
end

function plugin:ENCOUNTER_END(encounterID)
	self:Close()
end

-------------------------------------------------------------------------------
-- API
--

function plugin:Close()
	display:Hide()
end

function plugin:Open()
	self:RestyleWindow()
	display:Show()
end

function plugin:Test()
	self:Close()
	if db.lock then
		display:EnableMouse(true) -- Mouse disabled whilst locked, enable it in test mode
	end
	self:Open()
end

function plugin:BeamWasLeft(wasLeft)
	if BigWigsKrosusFirstBeamWasLeft then -- BigWigs
		BigWigsKrosusFirstBeamWasLeft(wasLeft)
	elseif DBMUpdateKrosusBeam then -- DBM
		DBMUpdateKrosusBeam(wasLeft)
	else
		plugin:Print(L["You are using no or an outdated version of a boss mod. Please update your existing mod or download BigWigs."])
	end
	self:Close()
end

-------------------------------------------------------------------------------
-- Slash command
--

SlashCmdList.KrosusAssist = function(input)
	input = input:lower()

	LibStub("AceConfigDialog-3.0"):Open("Krosus Assist")
	if not db.lock then plugin:StartConfigureMode() end
end
SLASH_KrosusAssist1 = "/krosus"
SLASH_KrosusAssist2 = "/krosusassist"

plugin:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...); -- call one of the functions above
end);
plugin:RegisterEvent("ADDON_LOADED")
