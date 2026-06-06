local _, PoisonVendor = ...

assert(PoisonVendor, "PoisonVendor namespace is not initialized")

local function IsPoisonSpellKnown(spellID)
	if IsSpellKnown and IsSpellKnown(spellID) then
		return true
	end

	local name = GetSpellInfo(spellID)
	if not name then
		return false
	end

	if IsPlayerSpell and IsPlayerSpell(spellID) then
		return true
	end

	if FindSpellBookSlotBySpellID then
		local slot = FindSpellBookSlotBySpellID(spellID)
		if slot then
			return true
		end
	end

	-- Search spellbook tabs for the spell name
	local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
	for tab = 1, numTabs do
		local _, _, offset, numSpells = GetSpellTabInfo(tab)
		for i = 1, numSpells do
			local slotType, slotSpellID = GetSpellBookItemInfo(offset + i, "spell")
			if slotSpellID == spellID then
				return true
			end
		end
	end

	return false
end

function PoisonVendor.GetAllKnownPoisonRanks()
	local allKnown = {}

	if select(2, UnitClass("player")) ~= "ROGUE" then
		return allKnown
	end

	for familyKey, family in pairs(PoisonVendor.PoisonCatalog) do
		local ranks = {}
		for rankIndex = 1, #family.ranks do
			local rank = family.ranks[rankIndex]
			if IsPoisonSpellKnown(rank.spellID) then
				ranks[#ranks + 1] = { rankIndex = rankIndex, rank = rank }
			end
		end
		if #ranks > 0 then
			allKnown[familyKey] = ranks
		end
	end

	return allKnown
end

function PoisonVendor.GetHighestKnownPoisons()
	local known = {}
	local allKnown = PoisonVendor.GetAllKnownPoisonRanks()

	for familyKey, ranks in pairs(allKnown) do
		known[familyKey] = ranks[#ranks].rank
	end

	return known
end
