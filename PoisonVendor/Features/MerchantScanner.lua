local _, PoisonVendor = ...

assert(PoisonVendor, "PoisonVendor namespace is not initialized")

local function GetItemIDFromLink(itemLink)
	if type(itemLink) ~= "string" then
		return nil
	end

	return tonumber(itemLink:match("item:(%d+)"))
end

local function GetBagCount(itemID)
	if type(GetItemCount) == "function" and itemID then
		return tonumber(GetItemCount(itemID)) or 0
	end
	return 0
end

function PoisonVendor.BuildMerchantMap()
	local merchantMap = {}
	local itemCount = GetMerchantNumItems and GetMerchantNumItems() or 0

	for merchantIndex = 1, itemCount do
		local itemLink = GetMerchantItemLink(merchantIndex)
		local itemID = GetItemIDFromLink(itemLink)

		if itemID then
			local _, _, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(merchantIndex)

			merchantMap[itemID] = {
				index = merchantIndex,
				itemID = itemID,
				price = price or 0,
				quantity = quantity or 1,
				numAvailable = numAvailable,
				isUsable = isUsable,
				extendedCost = extendedCost,
				itemLink = itemLink,
			}
		end
	end

	return merchantMap
end

local selectedRanks = {}

local function BuildRowForRank(familyKey, family, rank, rankIndex, allRanks, merchantMap, batchSizes)
	local batchPlans = {}
	local existingOutput = GetBagCount(rank.itemID)

	for _, batchSize in ipairs(batchSizes) do
		local full = PoisonVendor.BuildPurchasePlan(rank, merchantMap, batchSize)
		local delta = PoisonVendor.BuildPurchasePlan(rank, merchantMap, batchSize, existingOutput, true)
		batchPlans[batchSize] = { full = full, delta = delta }
	end

	local defaultBatchSize = batchSizes[1]
	local defaultPair = batchPlans[defaultBatchSize]
	local defaultPlan = defaultPair and defaultPair.full

	if not defaultPlan then
		return nil
	end

	return {
		familyKey = familyKey,
		displayName = family.displayName,
		familyIcon = family.iconTexture,
		itemID = rank.itemID,
		rank = rank,
		rankIndex = rankIndex,
		allRanks = allRanks,
		available = defaultPlan.available,
		defaultBatchSize = defaultBatchSize,
		defaultPlan = defaultPlan,
		batchPlans = batchPlans,
	}
end

function PoisonVendor.SetSelectedRank(familyKey, rankIndex)
	selectedRanks[familyKey] = rankIndex
	PoisonVendor.RefreshCurrentRows()
end

function PoisonVendor.BuildCurrentRows()
	local rows = {}
	local allKnown = PoisonVendor.GetAllKnownPoisonRanks()
	local merchantMap = PoisonVendor.BuildMerchantMap()
	local batchSizes = PoisonVendor.GetSupportedBatchSizes and PoisonVendor.GetSupportedBatchSizes() or { 5, 10, 20, 40 }

	for familyKey, knownRanks in pairs(allKnown) do
		local family = PoisonVendor.PoisonCatalog and PoisonVendor.PoisonCatalog[familyKey]
		if family and #knownRanks > 0 then
			local chosenIndex = selectedRanks[familyKey]
			local chosenEntry = nil

			if chosenIndex then
				for _, entry in ipairs(knownRanks) do
					if entry.rankIndex == chosenIndex then
						chosenEntry = entry
						break
					end
				end
			end

			if not chosenEntry then
				chosenEntry = knownRanks[#knownRanks]
			end

			local row = BuildRowForRank(familyKey, family, chosenEntry.rank, chosenEntry.rankIndex, knownRanks, merchantMap, batchSizes)
			if row then
				rows[#rows + 1] = row
			end
		end
	end

	table.sort(rows, function(left, right)
		return left.displayName < right.displayName
	end)

	-- Append supply items (direct-buy, no crafting)
	for _, supply in ipairs(PoisonVendor.SupplyCatalog or {}) do
		local merchantLine = merchantMap[supply.itemID]
		if merchantLine then
			local bundleSize = merchantLine.quantity or 1
			if bundleSize < 1 then bundleSize = 1 end

			local function BuildSupplyPlan(requiredUnits, exactQuantity)
				if requiredUnits <= 0 then
					return nil
				end

				local purchaseQuantity
				if exactQuantity then
					purchaseQuantity = requiredUnits
				else
					purchaseQuantity = math.ceil(requiredUnits / bundleSize) * bundleSize
				end
				local purchaseCount = purchaseQuantity / bundleSize
				local lineCost = (merchantLine.price or 0) * purchaseCount
				local numAvailable = merchantLine.numAvailable
				local isLimited = type(numAvailable) == "number" and numAvailable >= 0
				local available = not isLimited or numAvailable >= purchaseQuantity

				return {
					batchSize = requiredUnits,
					totalOutput = purchaseQuantity,
					totalCost = lineCost,
					available = available,
					isSupply = true,
					lines = {
						{
							itemID = supply.itemID,
							merchantIndex = merchantLine.index,
							bundleSize = bundleSize,
							purchaseQuantity = purchaseQuantity,
							normalizedPurchaseQuantity = purchaseQuantity,
							purchaseCount = purchaseCount,
							requiredUnits = requiredUnits,
							purchasedUnits = purchaseQuantity,
							numAvailable = numAvailable,
							price = merchantLine.price or 0,
							lineTotalCost = lineCost,
							extendedCost = merchantLine.extendedCost,
							itemLink = merchantLine.itemLink,
						},
					},
				}
			end

			local supplyBatchPlans = {}
			local owned = GetBagCount(supply.itemID)

			for _, batchSize in ipairs(batchSizes) do
				local full = BuildSupplyPlan(batchSize, false)
				local missing = math.max(0, batchSize - owned)
				local delta = (missing > 0) and BuildSupplyPlan(missing, true) or nil
				supplyBatchPlans[batchSize] = { full = full, delta = delta }
			end

			local defaultBatchSize = batchSizes[1]
			local defaultPair = supplyBatchPlans[defaultBatchSize]
			local defaultPlan = defaultPair and defaultPair.full

			if defaultPlan then
				rows[#rows + 1] = {
					familyKey = "_supply_" .. supply.itemID,
					displayName = supply.displayName,
					familyIcon = supply.iconTexture,
					itemID = supply.itemID,
					isSupply = true,
					available = defaultPlan.available,
					defaultBatchSize = defaultBatchSize,
					defaultPlan = defaultPlan,
					batchPlans = supplyBatchPlans,
				}
			end
		end
	end

	return rows
end
