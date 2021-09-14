roadblocks = {
	--roadblock items, categorized by factionID or -factionType
	--
	--object parameters:
	--name, model, rotation, zadd
	--
	--Faction Types: 0=GANG, 1=MAFIA, 2=LAW, 3=GOV, 4=MED, 5=OTHER, 6=NEWS
	[-2] = { --Type: Law
		{"Small roadblock", 978, 180, 0},
		{"Large roadblock", 981, 0, 0},
		{"Yellow fence", 3578, 0, 0},
		{"Small warning fence", 1228, 90, 0},
		{"Small warning fence with light", 1282, 90, 0},
		{"Ugly small fence", 1422, 0, 0},
		{"Sidewalk block", 1424, 0, 0},
		{"Detour ->", 1425, 0, 0},
		{"Warning fence", 1459, 0, 0},
		{"Vehicles ->", 3091, 0, 0},
		{"Small spikestrip", 1593, 90, -0.4},
		{"Traffic cone", 1238, 0, -0.18},
		{"Pole", 1237, 0, -0.45},
	},
	[-3] = { --Type: Government
		{"Small roadblock", 978, 180, 0},
		{"Large roadblock", 981, 0, 0},
		{"Yellow fence", 3578, 0, 0},
		{"Small warning fence", 1228, 90, 0},
		{"Small warning fence with light", 1282, 90, 0},
		{"Ugly small fence", 1422, 0, 0},
		{"Sidewalk block", 1424, 0, 0},
		{"Detour ->", 1425, 0, 0},
		{"Warning fence", 1459, 0, 0},
		{"Vehicles ->", 3091, 0, 0},
		{"Traffic cone", 1238, 0, -0.18},
		{"Pole", 1237, 0, -0.45},
		{"Rope", 2773, 90, 0},
	},
	[-4] = { --Type: Medical
		{"Small roadblock", 978, 180, 0},
		{"Large roadblock", 981, 0, 0},
		{"Yellow fence", 3578, 0, 0},
		{"Small warning fence", 1228, 90, 0},
		{"Small warning fence with light", 1282, 90, 0},
		{"Ugly small fence", 1422, 0, 0},
		{"Sidewalk block", 1424, 0, 0},
		{"Detour ->", 1425, 0, 0},
		{"Warning fence", 1459, 0, 0},
		{"Vehicles ->", 3091, 0, 0},
		{"Traffic cone", 1238, 0, -0.18},
		{"Pole", 1237, 0, -0.45},	
	},
	
	[4] = { --LSTR
		{"Small roadblock", 978, 180, 0},
		{"Large roadblock", 981, 0, 0},
		{"Yellow fence", 3578, 0, 0},
		{"Small warning fence", 1228, 90, 0},
		{"Small warning fence with light", 1282, 90, 0},
		{"Ugly small fence", 1422, 0, 0},
		{"Sidewalk block", 1424, 0, 0},
		{"Detour ->", 1425, 0, 0},
		{"Warning fence", 1459, 0, 0},
		{"Vehicles ->", 3091, 0, 0},
		{"Traffic cone", 1238, 0, -0.18},
		{"Pole", 1237, 0, -0.45},	
	},	
	[15] = { --LSIA
		{"Cone", 1238, 0, -0.18},
		{"Stairs", 3663, -90, 1.5},
		{"Rope", 2773, 90, 0},
		{"Pole with red light", 3666, 0, 0},
		{"Detour ->", 1425, 0, 0},
		{"Pole", 1237, 0, -0.45},
		{"Small warning fence", 1228, 90, 0},
		{"Small warning fence with light", 1282, 90, 0},
	},
}

--[[local roadblockNames = {
	[978] = "Small roadblock",
	[981] = "Large roadblock",
	[3578] = "Yellow fence",
	[1228] = "Small warning fence",
	[1282] = "Small warning fence with light",
	[1422] = "Ugly small fence",
	[1424] = "Sidewalk block",
	[1425] = "Detour ->",
	[1459] = "Warning fence",
	[3091] = "Vehicles ->",
	[1593] = "Small spikestrip",
	[1238] = "roadblock",
}--]]