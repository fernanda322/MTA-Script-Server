local objects = 
{
	-- Fox
	createObject(6400,2.3949372768402,7.6736159324646,1000.7486572266,0,0,0,2),
	createObject(6400,-0.78046905994415,6.6728477478027,1000.7486572266,0,0,0,2),
	createObject(2725,0.92446130514145,-1.4625927209854,998.86157226563,0,0,0,2),
	createObject(9254,0.72266608476639,0.34503030776978,1001.1474609375,0,180,0,2),
	createObject(6400,-1.780272603035,3.2218728065491,1000.7486572266,0,0,0,2),
	createObject(6400,-1.779296875,0.12167971581221,1000.7486572266,0,0,0,2),
	createObject(6400,-1.779296875,-5.4789047241211,1000.7486572266,0,0,0,2),
	createObject(6400,-1.954296708107,-2.7535135746002,1000.7486572266,0,0,0,2),
	createObject(6400,2.4958953857422,-4.1279349327087,1000.7486572266,0,0,0,2),
	createObject(6400,2.4951171875,0.29707083106041,1000.7486572266,0,0,0,2),
	createObject(6400,2.4951171875,3.8968782424927,1000.7486572266,0,0,0,2),
	createObject(6400,3.8451175689697,5.4464845657349,1000.7486572266,0,0,89.999969482422,2),
	createObject(6400,-1.9052728414536,5.4462890625,1000.7486572266,0,0,89.999969482422,2),
	createObject(6400,-2.9792976379395,2.7212862968445,1000.7486572266,0,0,89.999969482422,2),
	createObject(6400,0.89648616313934,7.545702457428,1000.7486572266,0,0,89.999938964844,2),
	createObject(6400,0.89648616313934,7.545702457428,1000.7486572266,0,0,89.999938964844,2),
	createObject(6400,0.89648616313934,7.545702457428,1000.7486572266,0,0,89.999938964844,2),
	createObject(1754,0.96798592805862,-0.17823004722595,998.52764892578,0,0,0,2),
	createObject(2335,-1.1492209434509,2.1697707176208,998.18029785156,0,0,89.999938964844,2),
	createObject(1793,-1.9250900745392,7.2961716651917,998.18029785156,0,0,270.26989746094,2),
	createObject(2139,-1.1295750141144,2.1740775108337,998.22991943359,0,0,89.72998046875,2),
	createObject(2139,-1.1295750141144,1.2010201215744,998.37878417969,0,0,89.72998046875,2),
	createObject(2139,-1.0303750038147,0.20902003347874,998.37878417969,0,0,89.72998046875,2),
	createObject(2139,-1.4271750450134,-1.6420249938965,998.37878417969,0,0,89.72998046875,2),
	createObject(2139,-1.4271750450134,-0.89802491664886,998.37878417969,0,0,89.72998046875,2),
	createObject(2139,-1.4271750450134,-3.6883718967438,998.37878417969,0,0,90.225982666016,2),
	createObject(2139,0.64164960384369,0.79485023021698,998.32916259766,0,0,269.68566894531,2),
	createObject(2139,1.4352496862411,0.79485023021698,998.32916259766,0,0,269.68566894531,2),
	createObject(2139,2.1792492866516,0.79485023021698,998.32916259766,0,0,269.68566894531,2),
	createObject(2139,1.7824496030807,1.8512626886368,998.32916259766,0,0,269.68566894531,2),
	createObject(2139,1.8816496133804,2.8928606510162,998.32916259766,0,0,269.68566894531,2),
	createObject(2139,1.7824496030807,3.867981672287,998.32916259766,0,0,269.68566894531,2),
	createObject(1754,1.9599858522415,-0.17823004722595,998.52764892578,0,0,0,2),
	createObject(1754,2.158385515213,-1.4151327610016,998.52764892578,0,0,270.26989746094,2),
	createObject(1754,2.158385515213,-0.4727326631546,998.52764892578,0,0,270.26989746094,2),
	createObject(1754,2.158385515213,-4.700448513031,998.52764892578,0,0,270.26989746094,2),
	createObject(1754,2.158385515213,-5.6428508758545,998.52764892578,0,0,270.26989746094,2),
	createObject(1754,1.8270316123962,-5.9404516220093,998.52764892578,0,0,180.53979492188,2),
	createObject(1754,0.88463151454926,-5.9404516220093,998.52764892578,0,0,180.53979492188,2),
	createObject(1754,-0.2065684646368,-5.9404516220093,998.52764892578,0,0,180.53979492188,2),
	createObject(1754,-1.214413523674,-5.9404516220093,998.52764892578,0,0,180.53979492188,2),
	createObject(1754,-1.4624135494232,-4.6825361251831,998.52764892578,0,0,90.809692382813,2),
	createObject(1754,-1.4624135494232,-5.5753383636475,998.52764892578,0,0,90.809692382813,2),
	createObject(6400,0.35088610649109,-6.2551684379578,1000.7486572266,0,0,89.999969482422,2),
	createObject(9254,0.72266608476639,0.34503030776978,998.86743164063,0,0,0,2)
}

local col = createColSphere(2.3949372768402,7.6736159324646,1000.7486572266,50)
local function watchChanges( )
	if getElementDimension( getLocalPlayer( ) ) > 0 and getElementDimension( getLocalPlayer( ) ) ~= getElementDimension( objects[1] ) and getElementInterior( getLocalPlayer( ) ) == getElementInterior( objects[1] ) then
		for key, value in pairs( objects ) do
			setElementDimension( value, getElementDimension( getLocalPlayer( ) ) )
		end
	elseif getElementDimension( getLocalPlayer( ) ) == 0 and getElementDimension( objects[1] ) ~= 65535 then
		for key, value in pairs( objects ) do
			setElementDimension( value, 65535 )
		end
	end
end
addEventHandler( "onClientColShapeHit", col,
	function( element )
		if element == getLocalPlayer( ) then
			addEventHandler( "onClientRender", root, watchChanges )
		end
	end
)
addEventHandler( "onClientColShapeLeave", col,
	function( element )
		if element == getLocalPlayer( ) then
			removeEventHandler( "onClientRender", root, watchChanges )
		end
	end
)
-- Put them standby for now.
for key, value in pairs( objects ) do
	setElementDimension( value, 65535 )
	setElementAlpha( value, 0 )
end