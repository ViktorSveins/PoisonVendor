local _, PoisonVendor = ...

assert(PoisonVendor, "PoisonVendor namespace is not initialized")

PoisonVendor.PoisonCatalog = {
	instant = {
		familyKey = "instant",
		displayName = "Instant Poison",
		iconTexture = "Interface\\Icons\\Ability_Poisons",
		ranks = {
			{
				spellID = 8681,
				itemID = 6947,
				outputCount = 1,
				reagents = {
					{ itemID = 2928, count = 1 },
					{ itemID = 3371, count = 1 },
				},
			},
			{
				spellID = 8687,
				itemID = 6949,
				outputCount = 1,
				reagents = {
					{ itemID = 2928, count = 1 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 8691,
				itemID = 6950,
				outputCount = 1,
				reagents = {
					{ itemID = 8924, count = 2 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 11341,
				itemID = 8926,
				outputCount = 1,
				reagents = {
					{ itemID = 8924, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 11342,
				itemID = 8927,
				outputCount = 1,
				reagents = {
					{ itemID = 8924, count = 2 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 11343,
				itemID = 8928,
				outputCount = 1,
				reagents = {
					{ itemID = 8924, count = 2 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 26892,
				itemID = 21927,
				outputCount = 1,
				reagents = {
					{ itemID = 2931, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
		},
	},
	deadly = {
		familyKey = "deadly",
		displayName = "Deadly Poison",
		iconTexture = "Interface\\Icons\\Ability_Poisons",
		ranks = {
			{
				spellID = 2835,
				itemID = 2892,
				outputCount = 1,
				reagents = {
					{ itemID = 5173, count = 1 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 2837,
				itemID = 2893,
				outputCount = 1,
				reagents = {
					{ itemID = 5173, count = 2 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 11357,
				itemID = 8984,
				outputCount = 1,
				reagents = {
					{ itemID = 5173, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 11358,
				itemID = 8985,
				outputCount = 1,
				reagents = {
					{ itemID = 5173, count = 2 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 25347,
				itemID = 20844,
				outputCount = 1,
				reagents = {
					{ itemID = 5173, count = 2 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 26969,
				itemID = 22053,
				outputCount = 1,
				reagents = {
					{ itemID = 2931, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 27282,
				itemID = 22054,
				outputCount = 1,
				reagents = {
					{ itemID = 2931, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
		},
	},
	crippling = {
		familyKey = "crippling",
		displayName = "Crippling Poison",
		iconTexture = "Interface\\Icons\\Ability_Poisons",
		ranks = {
			{
				spellID = 3420,
				itemID = 3775,
				outputCount = 1,
				reagents = {
					{ itemID = 2930, count = 1 },
					{ itemID = 3371, count = 1 },
				},
			},
			{
				spellID = 3421,
				itemID = 3776,
				outputCount = 1,
				reagents = {
					{ itemID = 8923, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
		},
	},
	mindNumbing = {
		familyKey = "mindNumbing",
		displayName = "Mind-numbing Poison",
		iconTexture = "Interface\\Icons\\Ability_Poisons",
		ranks = {
			{
				spellID = 5763,
				itemID = 5237,
				outputCount = 1,
				reagents = {
					{ itemID = 2928, count = 1 },
					{ itemID = 3371, count = 1 },
				},
			},
			{
				spellID = 8694,
				itemID = 6951,
				outputCount = 1,
				reagents = {
					{ itemID = 8923, count = 1 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 11400,
				itemID = 9186,
				outputCount = 1,
				reagents = {
					{ itemID = 8923, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
		},
	},
	wound = {
		familyKey = "wound",
		displayName = "Wound Poison",
		iconTexture = "Interface\\Icons\\Ability_Poisons",
		ranks = {
			{
				spellID = 13220,
				itemID = 10918,
				outputCount = 1,
				reagents = {
					{ itemID = 2930, count = 1 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 13228,
				itemID = 10920,
				outputCount = 1,
				reagents = {
					{ itemID = 2930, count = 1 },
					{ itemID = 5173, count = 1 },
					{ itemID = 3372, count = 1 },
				},
			},
			{
				spellID = 13229,
				itemID = 10921,
				outputCount = 1,
				reagents = {
					{ itemID = 8923, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 13230,
				itemID = 10922,
				outputCount = 1,
				reagents = {
					{ itemID = 8923, count = 1 },
					{ itemID = 5173, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
			{
				spellID = 27283,
				itemID = 22055,
				outputCount = 1,
				reagents = {
					{ itemID = 8923, count = 2 },
					{ itemID = 8925, count = 1 },
				},
			},
		},
	},
	anesthetic = {
		familyKey = "anesthetic",
		displayName = "Anesthetic Poison",
		iconTexture = "Interface\\Icons\\Ability_Poisons",
		ranks = {
			{
				spellID = 26786,
				itemID = 21835,
				outputCount = 1,
				reagents = {
					{ itemID = 2931, count = 1 },
					{ itemID = 5173, count = 1 },
					{ itemID = 8925, count = 1 },
				},
			},
		},
	},
}

PoisonVendor.SupplyCatalog = {
	{
		itemID = 5140,
		displayName = "Flash Powder",
		iconTexture = "Interface\\Icons\\INV_Misc_Powder_Black",
	},
}
