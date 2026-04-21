local addonName, PoisonVendor = ...

assert(PoisonVendor, "PoisonVendor namespace is not initialized")

local PANEL_WIDTH = 280
local CONTENT_MARGIN = 14
local TITLE_HEIGHT = 20
local ROW_ICON_SIZE = 22
local BUTTON_WIDTH = 48
local BUTTON_HEIGHT = 22
local BUTTON_SPACING = 4
local ROW_SPACING = 6
local DIVIDER_HEIGHT = 1
local DIVIDER_SPACING = 6
local RANK_ARROW_SIZE = 14
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local MF_RIGHT_OVERLAP = 6

local function GetBatchSizes()
	return PoisonVendor.GetSupportedBatchSizes and PoisonVendor.GetSupportedBatchSizes() or { 5, 10, 20, 40 }
end

local function GetCoinText(amount)
	if type(GetCoinTextureString) == "function" then
		return GetCoinTextureString(tonumber(amount) or 0)
	end

	return tostring(amount or 0)
end

local function IsPlanAvailable(plan)
	return type(plan) == "table" and plan.available == true
end

local function TryExecutePlan(plan)
	if not IsPlanAvailable(plan) then
		return false
	end

	if type(PoisonVendor.TryExecutePurchasePlan) == "function" then
		return PoisonVendor.TryExecutePurchasePlan(plan)
	end

	return false
end

local function GetRowItemName(rowData)
	local itemName = GetItemInfo and GetItemInfo(rowData.itemID)
	return itemName or rowData.displayName or "Unknown Poison"
end

local function GetPlanRequiredQuantity(line)
	local quantity = tonumber(line and line.requiredUnits or 0)
	return quantity and quantity > 0 and quantity or 0
end

local function GetPlanLineItemName(line)
	if type(GetItemInfo) == "function" then
		local itemName = GetItemInfo(line and (line.itemLink or line.itemID))
		if itemName then
			return itemName
		end
	end

	if type(line and line.itemLink) == "string" then
		local itemName = line.itemLink:match("%[(.+)%]")
		if itemName then
			return itemName
		end
	end

	if line and tonumber(line.itemID or 0) then
		return ("Item %d"):format(line.itemID)
	end

	return "Unknown reagent"
end

local function GetPlanReagentLines(plan)
	local reagentLines = {}

	for _, line in ipairs(plan and plan.lines or {}) do
		reagentLines[#reagentLines + 1] = ("%dx %s"):format(GetPlanRequiredQuantity(line), GetPlanLineItemName(line))
	end

	return reagentLines
end

local function GetRowIcon(rowData)
	if type(GetItemIcon) == "function" then
		local itemIcon = GetItemIcon(rowData.itemID)
		if itemIcon then
			return itemIcon
		end
	end

	return rowData.familyIcon or DEFAULT_ICON
end

local function CreateBatchButton(parent, batchSize)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button.batchSize = batchSize
	button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	button:SetText(("x%d"):format(batchSize))
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	button:SetScript("OnClick", function(self, mouseButton)
		local pair = self.plan
		if type(pair) ~= "table" then
			return
		end

		local chosen
		if mouseButton == "RightButton" then
			chosen = pair.delta
		else
			chosen = pair.full
		end

		if chosen then
			TryExecutePlan(chosen)
		end
	end)

	button:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(("Buy x%d"):format(self.batchSize), 1, 1, 1)

		local pair = self.plan
		local fullPlan = pair and pair.full or nil
		local deltaPlan = pair and pair.delta or nil

		if fullPlan then
			GameTooltip:AddDoubleLine("Output", ("x%d"):format(fullPlan.totalOutput or self.batchSize), 0.8, 0.8, 0.8, 1, 1, 1)
			GameTooltip:AddDoubleLine("Cost", GetCoinText(fullPlan.totalCost), 0.8, 0.8, 0.8, 1, 1, 1)

			local reagentLines = GetPlanReagentLines(fullPlan)
			if #reagentLines > 0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Reagents", 0.8, 0.8, 0.8)
				for _, text in ipairs(reagentLines) do
					GameTooltip:AddLine(("  %s"):format(text), 1, 1, 1)
				end
			end

			if not fullPlan.available then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Unavailable at this vendor.", 1, 0.2, 0.2, true)
			end

			GameTooltip:AddLine(" ")
			if deltaPlan then
				GameTooltip:AddLine("Right-click: top up to this batch", 0.6, 0.85, 1)
				GameTooltip:AddDoubleLine("  Output", ("x%d"):format(deltaPlan.totalOutput or 0), 0.8, 0.8, 0.8, 1, 1, 1)
				GameTooltip:AddDoubleLine("  Cost", GetCoinText(deltaPlan.totalCost), 0.8, 0.8, 0.8, 1, 1, 1)
				if not deltaPlan.available then
					GameTooltip:AddLine("  Unavailable at this vendor.", 1, 0.2, 0.2, true)
				end
			else
				GameTooltip:AddLine("Right-click: already stocked", 0.6, 0.85, 1)
			end
		else
			GameTooltip:AddLine("No purchase plan available.", 1, 0.2, 0.2, true)
		end

		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function(self)
		if GameTooltip and GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end)

	return button
end

local function CreateRankArrow(parent, direction)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(RANK_ARROW_SIZE, RANK_ARROW_SIZE)
	button:EnableMouse(true)

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.text:SetPoint("CENTER", 0, 0)
	button.text:SetText(direction == "left" and "<" or ">")
	button.text:SetTextColor(0.6, 0.5, 0.35)

	button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.highlight:SetAllPoints()
	button.highlight:SetColorTexture(1, 1, 1, 0.08)

	return button
end

local function CreateRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:EnableMouse(false)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_ICON_SIZE, ROW_ICON_SIZE)
	row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

	row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.title:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.title:SetJustifyH("LEFT")

	-- Rank selector aligned with icon center
	row.rankRight = CreateRankArrow(row, "right")
	row.rankRight:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	row.rankRight:SetPoint("TOP", row.icon, "TOP", 0, (RANK_ARROW_SIZE - ROW_ICON_SIZE) / 2)

	row.rankLeft = CreateRankArrow(row, "left")

	row.rankLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.rankLabel:SetJustifyH("CENTER")
	row.rankLabel:SetTextColor(0.6, 0.5, 0.35)

	row.rankLeft:SetPoint("RIGHT", row.rankLabel, "LEFT", -2, 0)
	row.rankLabel:SetPoint("RIGHT", row.rankRight, "LEFT", -2, 0)
	row.rankLeft:SetPoint("TOP", row.rankRight, "TOP")

	row.title:SetPoint("RIGHT", row.rankLeft, "LEFT", -4, 0)

	row.rankLeft:SetScript("OnClick", function()
		if row.rowData and row.rowData.allRanks and #row.rowData.allRanks > 1 then
			local currentIdx = row.currentRankListIndex or #row.rowData.allRanks
			local newIdx = currentIdx - 1
			if newIdx >= 1 then
				local entry = row.rowData.allRanks[newIdx]
				PoisonVendor.SetSelectedRank(row.rowData.familyKey, entry.rankIndex)
			end
		end
	end)

	row.rankRight:SetScript("OnClick", function()
		if row.rowData and row.rowData.allRanks and #row.rowData.allRanks > 1 then
			local currentIdx = row.currentRankListIndex or #row.rowData.allRanks
			local newIdx = currentIdx + 1
			if newIdx <= #row.rowData.allRanks then
				local entry = row.rowData.allRanks[newIdx]
				PoisonVendor.SetSelectedRank(row.rowData.familyKey, entry.rankIndex)
			end
		end
	end)

	-- Batch buttons (centered)
	row.buttonContainer = CreateFrame("Frame", nil, row)
	row.buttons = {}
	local batchSizes = GetBatchSizes()
	local totalButtonsWidth = #batchSizes * BUTTON_WIDTH + (#batchSizes - 1) * BUTTON_SPACING
	local contentWidth = PANEL_WIDTH - CONTENT_MARGIN * 2
	row.buttonContainer:SetSize(totalButtonsWidth, BUTTON_HEIGHT)
	row.buttonContainer:SetPoint("TOP", row.icon, "BOTTOM", 0, -4)
	row.buttonContainer:SetPoint("LEFT", row, "LEFT", math.floor((contentWidth - totalButtonsWidth) / 2), 0)

	for index, batchSize in ipairs(batchSizes) do
		local button = CreateBatchButton(row.buttonContainer, batchSize)
		button:SetPoint("TOPLEFT", row.buttonContainer, "TOPLEFT", (index - 1) * (BUTTON_WIDTH + BUTTON_SPACING), 0)
		row.buttons[index] = button
	end

	-- Divider below row
	row.divider = row:CreateTexture(nil, "ARTWORK")
	row.divider:SetHeight(DIVIDER_HEIGHT)
	row.divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, -(DIVIDER_SPACING))
	row.divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, -(DIVIDER_SPACING))
	row.divider:SetColorTexture(0.35, 0.3, 0.2, 0.5)

	return row
end

local function GetRowHeight()
	return ROW_ICON_SIZE + 4 + BUTTON_HEIGHT
end

local function UpdateRow(row, rowData, isLast)
	row.rowData = rowData
	row.icon:SetTexture(GetRowIcon(rowData))
	row.icon:SetDesaturated(not rowData.available)
	row.title:SetText(GetRowItemName(rowData))

	if rowData.available then
		row.title:SetTextColor(1, 0.82, 0)
	else
		row.title:SetTextColor(0.75, 0.35, 0.35)
	end

	-- Rank selector
	local allRanks = rowData.allRanks or {}
	local currentListIndex = #allRanks

	for i, entry in ipairs(allRanks) do
		if entry.rankIndex == rowData.rankIndex then
			currentListIndex = i
			break
		end
	end

	row.currentRankListIndex = currentListIndex

	if #allRanks > 1 then
		row.rankLabel:SetText(("Rank %d"):format(rowData.rankIndex))
		row.rankLabel:Show()
		row.rankLeft:Show()
		row.rankRight:Show()
		row.rankLeft:SetAlpha(currentListIndex > 1 and 1 or 0.3)
		row.rankLeft:EnableMouse(currentListIndex > 1)
		row.rankRight:SetAlpha(currentListIndex < #allRanks and 1 or 0.3)
		row.rankRight:EnableMouse(currentListIndex < #allRanks)
	else
		row.rankLabel:Hide()
		row.rankLeft:Hide()
		row.rankRight:Hide()
	end

	-- Batch buttons
	local batchSizes = GetBatchSizes()
	for index, batchSize in ipairs(batchSizes) do
		local button = row.buttons[index]
		local pair = rowData.batchPlans and rowData.batchPlans[batchSize] or nil
		local fullPlan = pair and pair.full or nil
		local enabled = IsPlanAvailable(fullPlan)

		button.plan = pair
		button:SetText(("x%d"):format(batchSize))
		button:SetEnabled(enabled)
		button:SetAlpha(enabled and 1 or 0.45)
	end

	-- Show divider except on last row
	row.divider:SetShown(not isLast)
end

local function UpdateCollapseButtonPosition(panel)
	panel.collapseButton:ClearAllPoints()
	if panel.collapsed then
		panel.collapseButton:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", -MF_RIGHT_OVERLAP, -20)
	else
		panel.collapseButton:SetPoint("TOPLEFT", panel, "TOPRIGHT", -6, -20)
	end
end

local function SetPanelCollapsed(panel, collapsed)
	panel.collapsed = collapsed

	if collapsed then
		panel.collapseButton.arrow:SetText(">")
		for _, row in ipairs(panel.rows) do
			row:Hide()
		end
		panel.content:Hide()
		panel.border:Hide()
		panel:SetSize(1, 1)
	else
		panel.collapseButton.arrow:SetText("<")
		panel.content:Show()
		panel.border:Show()
		panel:SetWidth(PANEL_WIDTH)
		PoisonVendor.RefreshCurrentRows()
	end

	UpdateCollapseButtonPosition(panel)
end

local function EnsurePanel()
	if PoisonVendor.vendorPanel then
		return PoisonVendor.vendorPanel
	end

	if not MerchantFrame then
		return nil
	end

	local panel = CreateFrame("Frame", addonName .. "VendorPanel", UIParent)
	panel:SetSize(PANEL_WIDTH, 100)
	panel:SetFrameStrata(MerchantFrame:GetFrameStrata())
	panel:SetFrameLevel(MerchantFrame:GetFrameLevel() + 1)
	panel:SetClampedToScreen(true)
	panel:Hide()

	-- Background + border matching the merchant frame style
	panel.border = CreateFrame("Frame", nil, panel, BackdropTemplateMixin and "BackdropTemplate" or nil)
	if panel.border.SetBackdrop then
		panel.border:SetAllPoints()
		panel.border:SetBackdrop({
			bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		panel.border:SetBackdropColor(1, 1, 1, 1)
		panel.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	end

	-- Content container
	panel.content = CreateFrame("Frame", nil, panel)
	panel.content:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_MARGIN, -CONTENT_MARGIN)
	panel.content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -CONTENT_MARGIN, CONTENT_MARGIN)

	panel.title = nil

	-- Collapse button anchored to MerchantFrame so it stays put when panel collapses
	panel.collapsed = false

	panel.collapseButton = CreateFrame("Button", nil, UIParent)
	panel.collapseButton:SetSize(24, 48)
	panel.collapseButton:SetFrameStrata(panel:GetFrameStrata())
	panel.collapseButton:SetFrameLevel(panel:GetFrameLevel() - 1)

	panel.collapseButton.borderFrame = CreateFrame("Frame", nil, panel.collapseButton, BackdropTemplateMixin and "BackdropTemplate" or nil)
	if panel.collapseButton.borderFrame.SetBackdrop then
		panel.collapseButton.borderFrame:SetAllPoints()
		panel.collapseButton.borderFrame:SetBackdrop({
			bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		panel.collapseButton.borderFrame:SetBackdropColor(1, 1, 1, 1)
		panel.collapseButton.borderFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	end

	panel.collapseButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	panel.collapseButton:GetHighlightTexture():SetAlpha(0.2)

	panel.collapseButton.arrow = (panel.collapseButton.borderFrame or panel.collapseButton):CreateFontString(nil, "OVERLAY", "GameFontNormal")
	panel.collapseButton.arrow:SetPoint("CENTER", 0, 0)
	panel.collapseButton.arrow:SetText("<")
	panel.collapseButton.arrow:SetTextColor(0.85, 0.8, 0.65)

	panel.collapseButton:SetScript("OnEnter", function(self)
		self.arrow:SetTextColor(1, 0.95, 0.8)
	end)

	panel.collapseButton:SetScript("OnLeave", function(self)
		self.arrow:SetTextColor(0.85, 0.8, 0.65)
	end)

	panel.collapseButton:SetScript("OnClick", function()
		SetPanelCollapsed(panel, not panel.collapsed)
	end)

	panel.rows = {}

	PoisonVendor.vendorPanel = panel
	return panel
end

function PoisonVendor.UpdateVendorPanelExpansion()
end

function PoisonVendor.HideVendorPanel()
	local panel = PoisonVendor.vendorPanel
	if not panel then
		return
	end

	panel:Hide()
	if panel.collapseButton then
		panel.collapseButton:Hide()
	end
end

function PoisonVendor.RenderVendorPanel(rows)
	local panel = EnsurePanel()
	if not panel or not MerchantFrame then
		return
	end

	if type(rows) ~= "table" or #rows == 0 then
		panel:Hide()
		return
	end

	-- Anchor to merchant frame top edge, overlapping slightly for seamless look
	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", -MF_RIGHT_OVERLAP, 0)
	panel:SetParent(UIParent)
	panel:Show()
	panel.collapseButton:Show()
	UpdateCollapseButtonPosition(panel)

	if panel.collapsed then
		return
	end

	local rowHeight = GetRowHeight()
	local topOffset = CONTENT_MARGIN
	local dividerExtra = DIVIDER_HEIGHT + DIVIDER_SPACING * 2

	for index, rowData in ipairs(rows) do
		local row = panel.rows[index]
		if not row then
			row = CreateRow(panel)
			panel.rows[index] = row
		end

		local contentWidth = PANEL_WIDTH - CONTENT_MARGIN * 2
		row:SetSize(contentWidth, rowHeight)
		row:ClearAllPoints()

		local yOffset = topOffset + ((index - 1) * (rowHeight + ROW_SPACING))
		if index > 1 then
			yOffset = yOffset + ((index - 1) * dividerExtra)
		end

		row:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_MARGIN, -yOffset)

		local isLast = (index == #rows)
		UpdateRow(row, rowData, isLast)
		row:Show()
	end

	for index = #rows + 1, #panel.rows do
		panel.rows[index].rowData = nil
		panel.rows[index]:Hide()
	end

	local totalHeight = topOffset
		+ (#rows * rowHeight)
		+ (math.max(#rows - 1, 0) * ROW_SPACING)
		+ (math.max(#rows - 1, 0) * dividerExtra)
		+ CONTENT_MARGIN
	panel:SetHeight(totalHeight)
end
