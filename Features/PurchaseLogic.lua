local _, PoisonVendor = ...

assert(PoisonVendor, "PoisonVendor namespace is not initialized")

local SUPPORTED_BATCH_SIZES = { 5, 10, 20, 40 }
local BATCH_TO_COMBINES = {
	[5] = 5,
	[10] = 10,
	[20] = 20,
	[40] = 40,
}

local function CopyBatchSizes()
	local copy = {}

	for index, batchSize in ipairs(SUPPORTED_BATCH_SIZES) do
		copy[index] = batchSize
	end

	return copy
end

local function NormalizeMerchantBundleSize(quantity)
	if type(quantity) ~= "number" or quantity < 1 then
		return 1
	end

	return quantity
end

local function NormalizeMerchantPurchaseQuantity(requiredUnits, bundleSize)
	local normalizedBundleSize = NormalizeMerchantBundleSize(bundleSize)

	if type(requiredUnits) ~= "number" or requiredUnits < 1 then
		return normalizedBundleSize
	end

	return math.ceil(requiredUnits / normalizedBundleSize) * normalizedBundleSize
end

local function RefreshRowsAfterPlanMismatch()
	if type(PoisonVendor.RefreshCurrentRows) == "function" then
		PoisonVendor.RefreshCurrentRows()
	end
end

local function BuildValidatedExecutionLines(plan)
	if type(PoisonVendor.BuildMerchantMap) ~= "function" then
		return nil
	end

	local liveMerchantMap = PoisonVendor.BuildMerchantMap()
	local executionLines = {}

	for _, line in ipairs(plan.lines or {}) do
		local expectedItemID = tonumber(line and line.itemID or 0)
		local expectedMerchantIndex = tonumber(line and line.merchantIndex or 0)
		local expectedBundleSize = NormalizeMerchantBundleSize(line and line.bundleSize or 1)
		local purchaseQuantity = tonumber(line and (line.normalizedPurchaseQuantity or line.purchaseQuantity) or 0)
		local liveMerchantLine = expectedItemID > 0 and liveMerchantMap[expectedItemID] or nil
		local liveBundleSize = NormalizeMerchantBundleSize(liveMerchantLine and liveMerchantLine.quantity or 1)
		local liveAvailable = liveMerchantLine and tonumber(liveMerchantLine.numAvailable) or nil
		local isLimited = type(liveAvailable) == "number" and liveAvailable >= 0

		if expectedMerchantIndex < 1 or not liveMerchantLine then
			return nil
		end

		if purchaseQuantity == nil or purchaseQuantity < 1 then
			purchaseQuantity = NormalizeMerchantPurchaseQuantity(line and line.requiredUnits or 0, expectedBundleSize)
		end

		if liveMerchantLine.index ~= expectedMerchantIndex or liveBundleSize ~= expectedBundleSize then
			return nil
		end

		if isLimited and liveAvailable < purchaseQuantity then
			return nil
		end

		executionLines[#executionLines + 1] = {
			merchantIndex = liveMerchantLine.index,
			purchaseQuantity = purchaseQuantity,
			bundleSize = liveBundleSize,
		}
	end

	return #executionLines > 0 and executionLines or nil
end

function PoisonVendor.GetSupportedBatchSizes()
	return CopyBatchSizes()
end

function PoisonVendor.GetCombineMultiplierForBatch(batchSize)
	return BATCH_TO_COMBINES[tonumber(batchSize or 0)]
end

function PoisonVendor.ExecutePurchasePlan(plan)
	if type(BuyMerchantItem) ~= "function" or type(plan) ~= "table" or plan.available ~= true then
		return false
	end

	local executionLines = BuildValidatedExecutionLines(plan)
	if not executionLines then
		RefreshRowsAfterPlanMismatch()
		return false
	end

	local MAX_PER_CALL = 20

	for _, line in ipairs(executionLines) do
		local remaining = line.purchaseQuantity
		while remaining > 0 do
			local qty = math.min(remaining, MAX_PER_CALL)
			BuyMerchantItem(line.merchantIndex, qty)
			remaining = remaining - qty
		end
	end

	return true
end

function PoisonVendor.BuildPurchasePlan(rank, merchantMap, batchSize)
	if type(rank) ~= "table" or type(merchantMap) ~= "table" then
		return nil
	end

	local combineMultiplier = PoisonVendor.GetCombineMultiplierForBatch(batchSize)
	if not combineMultiplier then
		return nil
	end

	local outputCount = tonumber(rank.outputCount or 0) or 0
	local totalOutput = outputCount * combineMultiplier
	local plan = {
		batchSize = batchSize,
		combineMultiplier = combineMultiplier,
		outputCount = outputCount,
		totalOutput = totalOutput,
		totalCost = 0,
		available = true,
		lines = {},
	}

	for _, reagent in ipairs(rank.reagents or {}) do
		local merchantLine = merchantMap[reagent.itemID]
		if not merchantLine then
			return nil
		end

		local bundleSize = NormalizeMerchantBundleSize(merchantLine.quantity)
		local requiredUnits = reagent.count * combineMultiplier
		local purchaseQuantity = NormalizeMerchantPurchaseQuantity(requiredUnits, bundleSize)
		local purchaseCount = purchaseQuantity / bundleSize
		local purchasedUnits = purchaseQuantity
		local numAvailable = merchantLine.numAvailable
		local isLimited = type(numAvailable) == "number" and numAvailable >= 0

		if isLimited and numAvailable < purchaseQuantity then
			plan.available = false
		end

		local lineTotalCost = (merchantLine.price or 0) * purchaseCount
		plan.totalCost = plan.totalCost + lineTotalCost
		plan.lines[#plan.lines + 1] = {
			itemID = reagent.itemID,
			requiredUnits = requiredUnits,
			bundleSize = bundleSize,
			purchaseCount = purchaseCount,
			purchaseQuantity = purchaseQuantity,
			normalizedPurchaseQuantity = purchaseQuantity,
			purchasedUnits = purchasedUnits,
			merchantIndex = merchantLine.index,
			numAvailable = numAvailable,
			price = merchantLine.price or 0,
			lineTotalCost = lineTotalCost,
			extendedCost = merchantLine.extendedCost,
			itemLink = merchantLine.itemLink,
		}
	end

	return plan
end
