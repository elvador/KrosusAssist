
-- GLOBALS: BigWigs UIParent GameTooltip SLASH_BigWigs_KrosusAssist1 SLASH_BigWigs_KrosusAssist2 BigWigsKrosusFirstBeamWasLeft

-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin = BigWigs:NewPlugin("KrosusAssist")
if not plugin then return end

plugin.defaultDB = {
	posx = nil,
	posy = nil,
	lock = nil,
	width = 140,
	height = 120,
	disabled = false,
	font = nil,
	fontSize = nil,
}

-------------------------------------------------------------------------------
-- Locals
--

local db = nil
local display = nil
local media = LibStub("LibSharedMedia-3.0")
local inConfigMode = nil

local L = BigWigsAPI:NewLocale("BigWigs: KrosusAssist", "enUS")
if L then
	L.pluginName = "KrosusAssist"
	L.disabled = "Disabled"
	L.disabledDisplayDesc = "Disable the plugin."
	L.lock = "Lock"
	L.lockDesc = "Locks the display in place, preventing moving and resizing."
	L.font = "Font"
	L.fontSize = "Font size"
	L.positionX = "X Position"
	L.positionY = "Y Position"
	L.positionExact = "Exact Positioning"
	L.positionDesc = "Type in the box or move the slider if you need exact positioning from the anchor."
	L.close = "Close"
	L.closeDesc = "Closes the display.\n\nTo disable it completely, you have to go into the options and toggle the 'disabled' checkbox."
	L.toggleDisplayPrint = "The display will show next time. To disable it completely, you have to go into the options and toggle the 'disabled' checkbox."
	L.question = "Where was the first Fel Beam?"
	L.left = "left"
	L.right = "right"
	L.outdatedBigWigs = "You are using an outdated version of BigWigs which does not support KrosusAssist. Please update it to use KrosusAssist."
end

plugin.displayName = L.pluginName

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
	texture:SetAlpha(.1)
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
	local font = CreateFont("BigWigs_KrosusAssistFont")
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
		local _, size = GameFontNormalHuge:GetFont()
		db.fontSize = size
	end

	plugin:RestyleWindow()
end

local function resetAnchor()
	display:ClearAllPoints()
	display:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
	db.width = plugin.defaultDB.width
	db.height = plugin.defaultDB.height
	display:SetWidth(db.width)
	display:SetHeight(db.height)
	db.posx = nil
	db.posy = nil
end

-------------------------------------------------------------------------------
-- Initialization
--

function plugin:OnRegister()
	self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
	updateProfile()
end


do
	local createAnchor = function()
		local anchor = CreateFrame("Frame", "BigWigsKrosusAssistAnchor", UIParent)
		anchor:SetWidth(db.width)
		anchor:SetHeight(db.height)
		anchor:SetMinResize(100, 30)
		anchor:SetClampedToScreen(true)
		anchor:EnableMouse(true)
		anchor:SetScript("OnMouseUp", function(self, button)
			if inConfigMode and button == "LeftButton" then
				plugin:SendMessage("BigWigs_SetConfigureTarget", plugin)
			end
		end)

		local bg = anchor:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(anchor)
		bg:SetColorTexture(0, 0, 0, 0.3)
		anchor.background = bg

		local close = CreateFrame("Button", nil, anchor)
		close:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", -2, 2)
		close:SetFrameLevel(anchor:GetFrameLevel() + 5) -- place this above everything
		close:SetHeight(16)
		close:SetWidth(16)
		close.tooltipHeader = L.close
		close.tooltipText = L.closeDesc
		close:SetScript("OnEnter", onControlEnter)
		close:SetScript("OnLeave", onControlLeave)
		close:SetScript("OnClick", function()
			BigWigs:Print(L.toggleDisplayPrint)
			plugin:Close(true)
		end)
		close:SetNormalTexture("Interface\\AddOns\\BigWigs\\Textures\\icons\\close")
		anchor.close = close

		local header = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		header:SetText(L.pluginName)
		header:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
		anchor.title = header

		local question = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		question:SetText(L.question)
		question:SetPoint("TOP", anchor, "TOP")
		anchor.question = question

		local buttonLeft = CreateFrame("Button", nil, anchor)
		buttonLeft:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, question:GetHeight())
		buttonLeft:SetPoint("BOTTOMRIGHT", anchor, "BOTTOM")
		buttonLeft:SetNormalFontObject("GameFontHighlightSmall")
		buttonLeft:SetText(L.left)
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
		buttonRight:SetText(L.right)
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
		tex:SetTexture("Interface\\AddOns\\BigWigs\\Textures\\draghandle")
		tex:SetWidth(16)
		tex:SetHeight(16)
		tex:SetBlendMode("ADD")
		tex:SetPoint("CENTER", drag)

		plugin:RestyleWindow()

		anchor:Hide()
		display = anchor

		-- USE THIS CALLBACK TO SKIN THIS WINDOW! NO NEED FOR UGLY HAX! E.g.
		-- local name, addon = ...
		-- if BigWigsLoader then
		-- 	BigWigsLoader.RegisterMessage(addon, "BigWigs_FrameCreated", function(event, frame, name) print(name.." frame created.") end)
		-- end
		plugin:SendMessage("BigWigs_FrameCreated", anchor, "KrosusAssist")
	end

	function plugin:OnPluginEnable()
		if createAnchor then createAnchor() createAnchor = nil end
		self:RegisterMessage("BigWigs_OnBossEngage")
		self:RegisterMessage("BigWigs_OnBossReboot", "BigWigs_OnBossDisable")
		self:RegisterMessage("BigWigs_OnBossDisable")

		self:RegisterMessage("BigWigs_StartConfigureMode")
		self:RegisterMessage("BigWigs_StopConfigureMode")
		self:RegisterMessage("BigWigs_SetConfigureTarget")
		self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
		self:RegisterMessage("BigWigs_ResetPositions", resetAnchor)
		updateProfile()
	end
end

function plugin:OnPluginDisable()
	self:Close(true)
end

-------------------------------------------------------------------------------
-- Options
--

function plugin:BigWigs_StartConfigureMode()
	inConfigMode = true
	self:Test()
end

function plugin:BigWigs_StopConfigureMode()
	inConfigMode = nil
	if db.lock then
		display:EnableMouse(false) -- Mouse disabled whilst locked, but we enable it in test mode. Re-disable it.
	end
	self:Close(true)
end

function plugin:BigWigs_SetConfigureTarget(event, module)
	if module == self then
		display.background:SetColorTexture(0.2, 1, 0.2, 0.3)
	else
		display.background:SetColorTexture(0, 0, 0, 0.3)
	end
end


local disabled = function() return plugin.db.profile.disabled end
local function GetOptions()
	local options = {
		name = L.pluginName,
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
				name = L.disabled,
				desc = L.disabledDisplayDesc,
				order = 1,
			},
			lock = {
				type = "toggle",
				name = L.lock,
				desc = L.lockDesc,
				order = 2,
				disabled = disabled,
			},
			font = {
				type = "select",
				name = L.font,
				order = 3,
				values = media:List("font"),
				width = "full",
				itemControl = "DDI-Font",
			},
			fontSize = {
				type = "range",
				name = L.fontSize,
				order = 4,
				max = 40,
				min = 8,
				step = 1,
				width = "full",
			},
			exactPositioning = {
				type = "group",
				name = L.positionExact,
				order = 8,
				inline = true,
				args = {
					posx = {
						type = "range",
						name = L.positionX,
						desc = L.positionDesc,
						min = 0,
						max = 2048,
						step = 1,
						order = 1,
						width = "full",
					},
					posy = {
						type = "range",
						name = L.positionY,
						desc = L.positionDesc,
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

plugin.subPanelOptions = {
	key = "BigWigs: KrosusAssist",
	name = L.pluginName,
	options = GetOptions,
}

-------------------------------------------------------------------------------
-- Events
--

do
	local opener = nil
	function plugin:BigWigs_OnBossEngage(event, module, difficulty)
		if db.disabled then return end
		if module.engageId ~= 1842 then return end
		opener = module
		self:Open(module)
	end

	function plugin:BigWigs_OnBossDisable(event, module)
		if module ~= opener then return end
		self:Close()
	end
end


-------------------------------------------------------------------------------
-- API
--

function plugin:Close()
	display:Hide()
end

function plugin:Open()
	display:Show()
end

function plugin:Test()
	self:Close()
	if db.lock then
		display:EnableMouse(true) -- Mouse disabled whilst locked, enable it in test mode
	end
	display:Show()
end

function plugin:BeamWasLeft(wasLeft)
	if BigWigsKrosusFirstBeamWasLeft then
		BigWigsKrosusFirstBeamWasLeft(wasLeft)
	else
		print(L.outdatedBigWigs)
	end
	self:Close()
end

-------------------------------------------------------------------------------
-- Slash command
--

SlashCmdList.BigWigs_KrosusAssist = function(input)
	input = input:lower()

	LibStub("AceConfigDialog-3.0"):Open("BigWigs", "BigWigs: KrosusAssist")
end
SLASH_BigWigs_KrosusAssist1 = "/bwkrosus"
SLASH_BigWigs_KrosusAssist2 = "/krosusassist"
