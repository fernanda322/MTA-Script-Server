mysql = exports.mysql

local null = mysql_null()
local toLoad = { }
local threads = { }
--local vehicleTempPosList = {}

function SmallestID( ) -- finds the smallest ID in the SQL instead of auto increment
	local result = mysql:query_fetch_assoc("SELECT MIN(e1.id+1) AS nextID FROM vehicles AS e1 LEFT JOIN vehicles AS e2 ON e1.id +1 = e2.id WHERE e2.id IS NULL")
	if result then
		local id = tonumber(result["nextID"]) or 1
		return id
	end
	return false
end

-- WORKAROUND ABIT
function getVehicleName(vehicle)
	return exports.global:getVehicleName(vehicle)
end

-- /makeveh
function createPermVehicle(thePlayer, commandName, ...)
	if exports.integration:isPlayerAdmin(thePlayer) or exports.integration:isPlayerLeadScripter(thePlayer) or exports.integration:isPlayerVehicleConsultant(thePlayer) then
		local args = {...}
		if (#args < 7) then
			printMakeVehError(thePlayer, commandName )
		else

			local vehShopData = exports["vehicle-manager"]:getInfoFromVehShopID(tonumber(args[1]))
			if not vehShopData then
				outputDebugString("VEHICLE SYSTEM / createPermVehicle / FAILED TO FETCH VEHSHOP DATA")
				printMakeVehError(thePlayer, commandName )
				return false
			end

			local vehicleID = tonumber(vehShopData.vehmtamodel)
			local col1, col2, userName, factionVehicle, cost, tint

			if not vehicleID then -- vehicle is specified as name
				outputDebugString("VEHICLE SYSTEM / createPermVehicle / FAILED TO FETCH VEHSHOP DATA")
				printMakeVehError(thePlayer, commandName )
				return false
			end

			col1 = tonumber(args[2])
			col2 = tonumber(args[3])
			userName = args[4]
			factionVehicle = tonumber(args[5])
			cost = tonumber(args[6])
			if cost < 0 then
				cost = tonumber(vehShopData.vehprice)
			end
			tint = tonumber(args[7])

			local id = vehicleID

			local r = getPedRotation(thePlayer)
			local x, y, z = getElementPosition(thePlayer)
			x = x + ( ( math.cos ( math.rad ( r ) ) ) * 5 )
			y = y + ( ( math.sin ( math.rad ( r ) ) ) * 5 )

			local targetPlayer, username = exports.global:findPlayerByPartialNick(thePlayer, userName)

			if targetPlayer then
				local to = nil
				local dbid = getElementData(targetPlayer, "dbid")

				if (factionVehicle==1) then
					factionVehicle = tonumber(getElementData(targetPlayer, "faction"))
					local theTeam = getPlayerTeam(targetPlayer)
					to = theTeam

					if not exports.global:takeMoney(theTeam, cost) then
						outputChatBox("[MAKEVEH] This faction cannot afford this vehicle.", thePlayer, 255, 0, 0)
						outputChatBox("Your faction cannot afford this vehicle.", targetPlayer, 255, 0, 0)
						return
					end
				else
					factionVehicle = -1
					to = targetPlayer
					if not exports.global:takeMoney(targetPlayer, cost) then
						outputChatBox("[MAKEVEH] This player cannot afford this vehicle.", thePlayer, 255, 0, 0)
						outputChatBox("You cannot afford this vehicle.", targetPlayer, 255, 0, 0)
						return
					elseif not exports.global:canPlayerBuyVehicle(targetPlayer) then
						outputChatBox("[MAKEVEH] This player has too many cars.", thePlayer, 255, 0, 0)
						outputChatBox("You have too many cars.", targetPlayer, 255, 0, 0)
						exports.global:giveMoney(targetPlayer, cost)
						return
					end
				end

				local letter1 = string.char(math.random(65,90))
				local letter2 = string.char(math.random(65,90))
				local plate = letter1 .. letter2 .. math.random(0, 9) .. " " .. math.random(1000, 9999)

				local veh = createVehicle(id, x, y, z, 0, 0, r, plate)
				if not (veh) then
					outputChatBox("Invalid Vehicle ID.", thePlayer, 255, 0, 0)
					exports.global:giveMoney(to, cost)
				else
					setVehicleColor(veh, col1, col2, col1, col2)
					local col =  { getVehicleColor(veh, true) }
					local color1 = toJSON( {col[1], col[2], col[3]} )
					local color2 = toJSON( {col[4], col[5], col[6]} )
					local color3 = toJSON( {col[7], col[8], col[9]} )
					local color4 = toJSON( {col[10], col[11], col[12]} )
					local vehicleName = getVehicleName(veh)
					destroyElement(veh)
					local dimension = getElementDimension(thePlayer)
					local interior = getElementInterior(thePlayer)
					local var1, var2 = exports['vehicle-system']:getRandomVariant(id)
					local smallestID = SmallestID()
					local insertid = mysql:query_insert_free("INSERT INTO vehicles SET id='" .. mysql:escape_string(smallestID) .. "', model='" .. mysql:escape_string(id) .. "', x='" .. mysql:escape_string(x) .. "', y='" .. mysql:escape_string(y) .. "', z='" .. mysql:escape_string(z) .. "', rotx='0', roty='0', rotz='" .. mysql:escape_string(r) .. "', color1='" .. mysql:escape_string(color1) .. "', color2='" .. mysql:escape_string(color2) .. "', color3='" .. mysql:escape_string(color3) .. "', color4='" .. mysql:escape_string(color4) .. "', faction='" .. mysql:escape_string(factionVehicle) .. "', owner='" .. mysql:escape_string(( factionVehicle == -1 and dbid or -1 )) .. "', plate='" .. mysql:escape_string(plate) .. "', currx='" .. mysql:escape_string(x) .. "', curry='" .. mysql:escape_string(y) .. "', currz='" .. mysql:escape_string(z) .. "', currrx='0', currry='0', currrz='" .. mysql:escape_string(r) .. "', locked=1, interior='" .. mysql:escape_string(interior) .. "', currinterior='" .. mysql:escape_string(interior) .. "', dimension='" .. mysql:escape_string(dimension) .. "', currdimension='" .. mysql:escape_string(dimension) .. "', tintedwindows='" .. mysql:escape_string(tint) .. "',variant1="..var1..",variant2="..var2..", creationDate=NOW(), createdBy="..getElementData(thePlayer, "account:id")..", `vehicle_shop_id`='"..args[1].."' ")
					if (insertid) then
						if (factionVehicle==-1) then
							exports.global:giveItem(targetPlayer, 3, tonumber(insertid))
						end

						local owner = ""
						if factionVehicle == -1 then
							owner = getPlayerName( targetPlayer )
						else
							owner = "Faction #" .. factionVehicle
						end

						exports.logs:logMessage("[MAKEVEH] " .. getPlayerName( thePlayer ) .. " created car #" .. insertid .. " (" .. vehicleName .. ") - " .. owner, 9)
						exports.logs:dbLog(thePlayer, 6, { "ve" .. insertid }, "SPAWNVEH '"..vehicleName.."' $"..cost.." "..owner )
						reloadVehicle(insertid)

						local hiddenAdmin = getElementData(thePlayer, "hiddenadmin")
						local adminTitle = exports.global:getPlayerAdminTitle(thePlayer)
						local adminUsername = getElementData(thePlayer, "account:username")
						local adminID = getElementData(thePlayer, "account:id")

						local addLog = mysql:query_free("INSERT INTO `vehicle_logs` (`vehID`, `action`, `actor`) VALUES ('"..tostring(insertid).."', '"..commandName.." "..vehicleName.." ($"..cost.." - to "..owner..")', '"..adminID.."')") or false
						if not addLog then
							outputDebugString("Failed to add vehicle logs.")
						end

						if (hiddenAdmin==0) then
							exports.global:sendMessageToAdmins("AdmCmd: " .. tostring(adminTitle) .. " " .. getPlayerName(thePlayer) .. " ("..adminUsername..") has spawned a "..vehicleName .. " (ID #" .. insertid .. ") to "..owner.." for $"..cost..".")
							outputChatBox(tostring(adminTitle) .. " " .. getPlayerName(thePlayer) .. " has spawned a "..vehicleName .. " (ID #" .. insertid .. ") to "..owner.." for $"..cost..".", targetPlayer, 255, 194, 14)
						else
							exports.global:sendMessageToAdmins("AdmCmd: A Hidden Admin has spawned a "..vehicleName .. " (ID #" .. insertid .. ") to "..owner.." for $"..cost..".")
							outputChatBox("A Hidden Admin has spawned a "..vehicleName .. " (ID #" .. insertid .. ") to "..owner.." for $"..cost..".", targetPlayer, 255, 194, 14)
						end
						outputChatBox("[MAKEVEH] "..vehicleName .. " (ID #" .. insertid .. ") successfully spawned to "..owner..".", thePlayer, 0, 255, 0)

						local content = "[B]Spawned to username/faction:[/B][INDENT]"..owner.."[/INDENT][B]Vehicle name: [/B][INDENT](("..vehicleName..")) "..vehShopData.vehyear.. " " ..vehShopData.vehbrand.. " " ..vehShopData.vehmodel.. "[/INDENT][B]Amount: [/B][INDENT]$"..cost.."[/INDENT][B]Unique ID: [/B][INDENT]"..insertid..".[/INDENT][INDENT][/INDENT][U][I]Note: Please make a reply to this post with any additional information you may have.[/I][/U]"
						exports["integration"]:createForumThread(thePlayer, thePlayer, 318, "/"..commandName.." $"..cost.." to ("..owner..") "..vehShopData.vehyear.. " " ..vehShopData.vehbrand.. " " ..vehShopData.vehmodel, content, "Please make a reply to this post with any additional information you may have")
						outputChatBox("Please reply to http://forums.owlgaming.net/forumdisplay.php?318-Vehicles with any information you may need to add.", thePlayer, 255, 0, 0)
						if factionVehicle == -1 then
							outputChatBox("[MAKEVEH] $"..cost.." has been taken from player's inventory.", thePlayer, 0, 255, 0)
							outputChatBox("$"..cost.." has been taken from your inventory.", targetPlayer, 0, 255, 0)
						else
							outputChatBox("[MAKEVEH] $"..cost.." has been taken from player's faction bank.", thePlayer, 0, 255, 0)
							outputChatBox("$"..cost.." has been taken from your faction bank.", targetPlayer, 0, 255, 0)
						end

						reloadVehicle(tonumber(insertid))
					end
				end
			end
		end
	end
end
addCommandHandler("makeveh", createPermVehicle, false, false)

function printMakeVehError(thePlayer, commandName )
	outputChatBox("SYNTAX: /" .. commandName .. " [ID from Veh Lib] [color1] [color2] [Owner] [Faction Vehicle (1/0)] [-1=carshop price] [Tinted Windows] ", thePlayer, 255, 194, 14)
	outputChatBox("NOTE: If it is a faction vehicle, ownership will be given to the 'owner''s faction.", thePlayer, 255, 194, 14)
	outputChatBox("NOTE: If it is a faction vehicle, the cost is taken from the faction fund, rather than the player.", thePlayer, 255, 194, 14)
end

-- /makecivveh
function createCivilianPermVehicle(thePlayer, commandName, ...)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		local args = {...}
		if (#args < 4) then
			outputChatBox("SYNTAX: /" .. commandName .. " [id/name] [color1 (-1 for random)] [color2 (-1 for random)] [Job ID -1 for none]", thePlayer, 255, 194, 14)
			outputChatBox("Job 1 = Delivery Driver", thePlayer, 255, 194, 14)
			outputChatBox("Job 2 = Taxi Driver", thePlayer, 255, 194, 14)
			outputChatBox("Job 3 = Bus Driver", thePlayer, 255, 194, 14)
		else
			local vehicleID = tonumber(args[1])
			local col1, col2, job

			if not vehicleID then -- vehicle is specified as name
				local vehicleEnd = 1
				repeat
					vehicleID = getVehicleModelFromName(table.concat(args, " ", 1, vehicleEnd))
					vehicleEnd = vehicleEnd + 1
				until vehicleID or vehicleEnd == #args
				if vehicleEnd == #args then
					outputChatBox("Invalid Vehicle Name.", thePlayer, 255, 0, 0)
					return
				else
					col1 = tonumber(args[vehicleEnd])
					col2 = tonumber(args[vehicleEnd + 1])
					job = tonumber(args[vehicleEnd + 2])
				end
			else
				col1 = tonumber(args[2])
				col2 = tonumber(args[3])
				job = tonumber(args[4])
			end

			local id = vehicleID

			local r = getPedRotation(thePlayer)
			local x, y, z = getElementPosition(thePlayer)
			local interior = getElementInterior(thePlayer)
			local dimension = getElementDimension(thePlayer)
			x = x + ( ( math.cos ( math.rad ( r ) ) ) * 5 )
			y = y + ( ( math.sin ( math.rad ( r ) ) ) * 5 )

			local letter1 = string.char(math.random(65,90))
			local letter2 = string.char(math.random(65,90))
			local plate = letter1 .. letter2 .. math.random(0, 9) .. " " .. math.random(1000, 9999)

			local veh = createVehicle(id, x, y, z, 0, 0, r, plate)
			if not (veh) then
				outputChatBox("Invalid Vehicle ID.", thePlayer, 255, 0, 0)
			else
				local vehicleName = getVehicleName(veh)
				destroyElement(veh)

				local var1, var2 = exports['vehicle-system']:getRandomVariant(id)
				local smallestID = SmallestID()
				local insertid = mysql:query_insert_free("INSERT INTO vehicles SET id='" .. mysql:escape_string(smallestID) .. "', job='" .. mysql:escape_string(job) .. "', model='" .. mysql:escape_string(id) .. "', x='" .. mysql:escape_string(x) .. "', y='" .. mysql:escape_string(y) .. "', z='" .. mysql:escape_string(z) .. "', rotx='" .. mysql:escape_string("0.0") .. "', roty='" .. mysql:escape_string("0.0") .. "', rotz='" .. mysql:escape_string(r) .. "', color1='[ [ 0, 0, 0 ] ]', color2='[ [ 0, 0, 0 ] ]', color3='[ [ 0, 0, 0 ] ]', color4='[ [0, 0, 0] ]', faction='-1', owner='-2', plate='" .. mysql:escape_string(plate) .. "', currx='" .. mysql:escape_string(x) .. "', curry='" .. mysql:escape_string(y) .. "', currz='" .. mysql:escape_string(z) .. "', currrx='0', currry='0', currrz='" .. mysql:escape_string(r) .. "', interior='" .. mysql:escape_string(interior) .. "', currinterior='" .. mysql:escape_string(interior) .. "', dimension='" .. mysql:escape_string(dimension) .. "', currdimension='" .. mysql:escape_string(dimension) .. "',variant1="..var1..",variant2="..var2..", creationDate=NOW(), createdBy="..getElementData(thePlayer, "account:id").."")
				if (insertid) then
					exports.logs:logMessage("[MAKECIVVEH] " .. getPlayerName( thePlayer ) .. " created car #" .. insertid .. " (" .. getVehicleNameFromModel( id ) .. ")", 9)
					reloadVehicle(insertid)
					exports.logs:dbLog(thePlayer, 6, { "ve" .. insertid }, "SPAWNVEH '"..vehicleName.."' CIVILLIAN")

					local adminID = getElementData(thePlayer, "account:id")
					local addLog = mysql:query_free("INSERT INTO `vehicle_logs` (`vehID`, `action`, `actor`) VALUES ('"..tostring(insertid).."', '"..commandName.." "..vehicleName.." (job "..job..")', '"..adminID.."')") or false
					if not addLog then
						outputDebugString("Failed to add vehicle logs.")
					end
				end
			end
		end
	end
end
addCommandHandler("makecivveh", createCivilianPermVehicle, false, false)

function loadAllVehicles(res)
	-- Reset player in vehicle states
	local players = exports.pool:getPoolElementsByType("player")
	for key, value in ipairs(players) do
		exports.anticheat:changeProtectedElementDataEx(value, "realinvehicle", 0, false)
	end

	local result = mysql:query("SELECT id FROM `vehicles` WHERE deleted=0 ORDER BY `id` ASC")
	if result then
		while true do
			local row = mysql:fetch_assoc(result)
			if not row then break end

			toLoad[tonumber(row["id"])] = true
			--loadOneVehicle(row)
		end
		mysql:free_result(result)

		for id in pairs( toLoad ) do

			local co = coroutine.create(loadOneVehicle)
			coroutine.resume(co, id, true)
			table.insert(threads, co)
		end
		setTimer(resume, 1000, 4)
	else
		outputDebugString( "loadAllVehicles failed" )
	end
end
addEventHandler("onResourceStart", getResourceRootElement(), loadAllVehicles)

function resume()
	for key, value in ipairs(threads) do
		coroutine.resume(value)
	end
end

function reloadVehicle(id)
	local theVehicle = exports.pool:getElement("vehicle", tonumber(id))
	if (theVehicle) then
		removeSafe(tonumber(id))
		exports['savevehicle-system']:saveVehicle(theVehicle)
		destroyElement(theVehicle)
	end
	--vehicleTempPosList = exports["admin-system"]:getVehTempPosList() or false
	loadOneVehicle(id, false)
	return true
end

function loadOneVehicle(id, hasCoroutine, loadDeletedOne)
	if (hasCoroutine==nil) then
		hasCoroutine = false
	end

	if loadDeletedOne then
		loadDeletedOne = "AND deleted = '0'"
	else
		loadDeletedOne = ""
	end

	local row = mysql:query_fetch_assoc("SELECT v.*, (CASE WHEN ((protected_until IS NULL) OR (protected_until > NOW() = 0)) THEN -1 ELSE TO_SECONDS(protected_until) END) AS protected_until, "
			.."TO_SECONDS(lastUsed) AS lastused_sec, (CASE WHEN lastlogin IS NOT NULL THEN TO_SECONDS(lastlogin) ELSE NULL END) AS owner_last_login, "
			.."l.faction AS impounder, "
			.."i.premium, i.insurancefaction "
			.."FROM vehicles v "
			.."LEFT JOIN characters c ON v.owner=c.id "
			.."LEFT JOIN leo_impound_lot l ON v.id=l.veh "
			.."LEFT JOIN insurance_data i ON v.id=i.vehicleid "
			.."WHERE v.id = " .. mysql:escape_string(id) .. " "..loadDeletedOne.." LIMIT 1" )

	if row then
		if (hasCoroutine) then
			coroutine.yield()
		end

		for k, v in pairs( row ) do
			if v == null then
				row[k] = nil
			else
				row[k] = tonumber(row[k]) or row[k]
			end
		end
		-- Valid vehicle variant?
		local var1, var2 = row.variant1, row.variant2
		if not isValidVariant(row.model, var1, var2) then
			var1, var2 = getRandomVariant(row.model)
			mysql:query_free("UPDATE vehicles SET variant1 = " .. var1 .. ", variant2 = " .. var2 .. " WHERE id='" .. mysql:escape_string(row.id) .. "'")
		end

		-- Spawn the vehicle
		local veh = createVehicle(row.model, row.currx, row.curry, row.currz, row.currrx, row.currry, row.currrz, row.plate, false, var1, var2)
		if veh then
			exports.anticheat:changeProtectedElementDataEx(veh, "dbid", row.id)
			exports.pool:allocateElement(veh, row.id)

			-- color and paintjob
			if row.paintjob ~= 0 then
				setVehiclePaintjob(veh, row.paintjob)
			end

			if row.paintjob_url then
				exports.anticheat:changeProtectedElementDataEx(veh, "paintjob:url", row.paintjob_url, true)
			end

			local color1 = fromJSON(row.color1)
			local color2 = fromJSON(row.color2)
			local color3 = fromJSON(row.color3)
			local color4 = fromJSON(row.color4)
			setVehicleColor(veh, color1[1], color1[2], color1[3], color2[1], color2[2], color2[3], color3[1], color3[2], color3[3], color4[1], color4[2], color4[3])
			-- Set the vehicle armored if it is armored
			if (armoredCars[row.model]) then
				setVehicleDamageProof(veh, true)
			end

			-- Cosmetics
			local upgrades = fromJSON(row["upgrades"])
			for slot, upgrade in ipairs(upgrades) do
				if upgrade and tonumber(upgrade) > 0 then
					addVehicleUpgrade(veh, upgrade)
				end
			end

			local panelStates = fromJSON(row["panelStates"])
			for panel, state in ipairs(panelStates) do
				setVehiclePanelState(veh, panel-1 , tonumber(state) or 0)
			end

			local doorStates = fromJSON(row["doorStates"])
			for door, state in ipairs(panelStates) do
				setVehicleDoorState(veh, door-1, tonumber(state) or 0)
			end

			local headlightColors = fromJSON(row["headlights"])
			if headlightColors then
				setVehicleHeadLightColor ( veh, headlightColors[1], headlightColors[2], headlightColors[3])
			end
			exports.anticheat:changeProtectedElementDataEx(veh, "headlightcolors", headlightColors, true)

			local wheelStates = fromJSON(row["wheelStates"])
			setVehicleWheelStates(veh, tonumber(wheelStates[1]) , tonumber(wheelStates[2]) , tonumber( wheelStates[3]) , tonumber(wheelStates[4]) )

			-- lock the vehicle if it's locked
			setVehicleLocked(veh, row.owner ~= -1 and row.locked == 1)

			-- set the sirens on if it has some
			setVehicleSirensOn(veh, row.sirens == 1)

			-- job
			if row.job > 0 then
				toggleVehicleRespawn(veh, true)
				setVehicleRespawnDelay(veh, 60000)
				setVehicleIdleRespawnDelay(veh, 15 * 60000)
				exports.anticheat:changeProtectedElementDataEx(veh, "job", row.job, true)
			else
				exports.anticheat:changeProtectedElementDataEx(veh, "job", 0, true)
			end

			setVehicleRespawnPosition(veh, row.x, row.y, row.z, row.rotx, row.roty, row.rotz)
			exports.anticheat:changeProtectedElementDataEx(veh, "respawnposition", {row.x, row.y, row.z, row.rotx, row.roty, row.rotz}, false)

			-- element data
			exports.anticheat:changeProtectedElementDataEx(veh, "vehicle_shop_id", row.vehicle_shop_id, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "fuel", row.fuel, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "oldx", row.currx, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "oldy", row.curry, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "oldz", row.currz, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "faction", tonumber(row.faction))
			exports.anticheat:changeProtectedElementDataEx(veh, "owner", tonumber(row.owner))
			exports.anticheat:changeProtectedElementDataEx(veh, "vehicle:windowstat", 0, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "plate", row.plate, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "registered", row.registered, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "show_plate", row.show_plate, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "show_vin", row.show_vin, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "description:1", row.description1, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "description:2", row.description2, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "description:3", row.description3, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "description:4", row.description4, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "description:5", row.description5, true)

			if row.lastused_sec ~= mysql_null() then
				exports.anticheat:changeProtectedElementDataEx(veh, "lastused", row.lastused_sec, true)
			end

			--outputDebugString(tostring(row.owner_last_login))
			if row.owner_last_login ~= mysql_null() then
				exports.anticheat:changeProtectedElementDataEx(veh, "owner_last_login", row.owner_last_login, true)
			end

			if row.owner > 0 and row.protected_until ~= -1 then
				exports.anticheat:changeProtectedElementDataEx(veh, "protected_until", row.protected_until, true)
			end

			local customTextures = fromJSON(row.textures) or {}
			exports.anticheat:changeProtectedElementDataEx(veh, "textures", customTextures, true) -- 30/12/14 Exciter

			exports.anticheat:changeProtectedElementDataEx(veh, "deleted", row.deleted, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "chopped", row.chopped, false)
			--exports.anticheat:changeProtectedElementDataEx(veh, "note", row.note, true)

			-- impound shizzle
			exports.anticheat:changeProtectedElementDataEx(veh, "Impounded", tonumber(row.Impounded), true)
			if tonumber(row.Impounded) > 0 then
				setVehicleDamageProof(veh, true)
				if row.impounder then
					--outputDebugString("set")
					exports.anticheat:changeProtectedElementDataEx(veh, "impounder", row.impounder, false, true)
				else
					exports.anticheat:changeProtectedElementDataEx(veh, "impounder", 4, false, true) --RT
				end
			end

			-- insurance stuff
			if exports.global:isResourceRunning("insurance") then
        		exports.anticheat:setEld(veh, "insurance:fee", row.premium or 0, false, true)
        		exports.anticheat:setEld(veh, "insurance:faction", row.insurancefaction or 0, false, true)
            end

			-- interior/dimension

			--[[if vehicleTempPosList then
				setElementInterior(veh, vehicleTempPosList[tonumber(row.id)]["int"])
				setElementDimension(veh, vehicleTempPosList[tonumber(row.id)]["dim"])
				setElementPosition(veh, vehicleTempPosList[tonumber(row.id)]["x"], vehicleTempPosList[tonumber(row.id)]["y"], vehicleTempPosList[tonumber(row.id)]["z"])
				setElementRotation(veh, vehicleTempPosList[tonumber(row.id)]["rx"], vehicleTempPosList[tonumber(row.id)]["ry"], vehicleTempPosList[tonumber(row.id)]["rz"])
			else
				setElementDimension(veh, row.currdimension)
				setElementInterior(veh, row.currinterior)
			end
			]]

			setElementDimension(veh, row.currdimension)
			setElementInterior(veh, row.currinterior)

			exports.anticheat:changeProtectedElementDataEx(veh, "dimension", row.dimension, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "interior", row.interior, false)

			-- lights
			setVehicleOverrideLights(veh, row.lights == 0 and 1 or row.lights )

			-- engine
			if row.hp <= 350 then
				setElementHealth(veh, 300)
				setVehicleDamageProof(veh, true)
				setVehicleEngineState(veh, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "engine", 0, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "enginebroke", 1, false)
			else
				setElementHealth(veh, row.hp)
				setVehicleEngineState(veh, row.engine == 1)
				exports.anticheat:changeProtectedElementDataEx(veh, "engine", row.engine, true)
				exports.anticheat:changeProtectedElementDataEx(veh, "enginebroke", 0, true)
			end
			setVehicleFuelTankExplodable(veh, false)

			-- handbrake
			exports.anticheat:changeProtectedElementDataEx(veh, "handbrake", row.handbrake, true)
			if row.handbrake > 0 then
				setElementFrozen(veh, true)
			end

			local hasInterior, interior = exports['vehicle-interiors']:add( veh )
			if hasInterior and row.safepositionX and row.safepositionY and row.safepositionZ and row.safepositionRZ then
				addSafe( row.id, row.safepositionX, row.safepositionY, row.safepositionZ, row.safepositionRZ, interior )
			end

			if row.bulletproof == 1 then
				setVehicleDamageProof(veh, true)
			end

			if row.tintedwindows == 1 then
				exports.anticheat:changeProtectedElementDataEx(veh, "tinted", true, true)
			end
			exports.anticheat:changeProtectedElementDataEx(veh, "odometer", tonumber(row.odometer), false)

			if getResourceFromName ( "vehicle-manager" ) then
				exports["vehicle-manager"]:loadCustomVehProperties(tonumber(row.id), veh) --MAXIME / LOAD CUSTOM VEHICLE PROPERTIES AND HANDLING
			end

			if #customTextures > 0 then
				for somenumber, texture in ipairs(customTextures) do
					exports['item-texture']:addTexture(veh, texture[1], texture[2])
				end
			end

			--outputDebugString("loadOneVehicle - "..row.id)
			return veh
		end
	end
end

function vehicleExploded()
	local job = getElementData(source, "job")

	if not job or job<=0 then
		setTimer(respawnVehicle, 60000, 1, source)
	end
end
addEventHandler("onVehicleExplode", getRootElement(), vehicleExploded)

function vehicleRespawn(exploded)
	local id = getElementData(source, "dbid")
	local faction = getElementData(source, "faction")
	local job = getElementData(source, "job")
	local owner = getElementData(source, "owner")
	local windowstat = getElementData(source, "vehicle:windowstat")

	if (job>0) then
		toggleVehicleRespawn(source, true)
		setVehicleRespawnDelay(source, 60000)
		setVehicleIdleRespawnDelay(source, 15 * 60000)
		setElementFrozen(source, true)
		exports.anticheat:changeProtectedElementDataEx(source, "handbrake", 1, false)
	end

	-- Set the vehicle armored if it is armored
	local vehid = getElementModel(source)
	if (armoredCars[tonumber(vehid)]) then
		setVehicleDamageProof(source, true)
	else
		setVehicleDamageProof(source, false)
	end

	setVehicleFuelTankExplodable(source, false)
	setVehicleEngineState(source, false)
	setVehicleLandingGearDown(source, true)

	exports.anticheat:changeProtectedElementDataEx(source, "enginebroke", 0, false)

	exports.anticheat:changeProtectedElementDataEx(source, "dbid", id)
	exports.anticheat:changeProtectedElementDataEx(source, "fuel", exports["fuel-system"]:getMaxFuel(vehid))
	exports.anticheat:changeProtectedElementDataEx(source, "engine", 0, false)
	exports.anticheat:changeProtectedElementDataEx(source, "vehicle:windowstat", windowstat, false)

	local x, y, z = getElementPosition(source)
	exports.anticheat:changeProtectedElementDataEx(source, "oldx", x, false)
	exports.anticheat:changeProtectedElementDataEx(source, "oldy", y, false)
	exports.anticheat:changeProtectedElementDataEx(source, "oldz", z, false)

	exports.anticheat:changeProtectedElementDataEx(source, "faction", faction)
	exports.anticheat:changeProtectedElementDataEx(source, "owner", owner, false)

	setVehicleOverrideLights(source, 1)
	setElementFrozen(source, false)

	-- Set the sirens off
	setVehicleSirensOn(source, false)

	setVehicleLightState(source, 0, 0)
	setVehicleLightState(source, 1, 0)

	local dimension = getElementDimension(source)
	local interior = getElementInterior(source)

	setElementDimension(source, dimension)
	setElementInterior(source, interior)

	-- unlock civ vehicles
	if owner == -1 then
		setVehicleLocked(source, false)
		setElementFrozen(source, true)
		exports.anticheat:changeProtectedElementDataEx(source, "handbrake", 1, false)
	end

	setElementFrozen(source, getElementData(source, "handbrake") == 1)
end
addEventHandler("onVehicleRespawn", getResourceRootElement(), vehicleRespawn)

function setEngineStatusOnEnter(thePlayer, seat)
	-- outputDebugString('server engine state')
	if seat == 0 then
		local engine = getElementData(source, "engine")
		local model = getElementModel(source)
		if not (enginelessVehicle[model]) then
			if (engine==0) then
				toggleControl(thePlayer, 'brake_reverse', false)
				setVehicleEngineState(source, false)
			else
				toggleControl(thePlayer, 'brake_reverse', true)
				setVehicleEngineState(source, true)
			end
		else
			toggleControl(thePlayer, 'brake_reverse', true)

			setVehicleEngineState(source, true)
			exports.anticheat:changeProtectedElementDataEx(source, "engine", 1, false)
		end
	end
	triggerEvent("sendCurrentInventory", thePlayer, source)
end
addEventHandler("onVehicleEnter", getRootElement(), setEngineStatusOnEnter)

function vehicleExit(thePlayer, seat)
	if (isElement(thePlayer)) then
		toggleControl(thePlayer, 'brake_reverse', true)
		-- For oldcar
		local vehid = getElementData(source, "dbid")
		exports.anticheat:changeProtectedElementDataEx(thePlayer, "lastvehid", vehid, false)
		setPedGravity(thePlayer, 0.008)
		setElementFrozen(thePlayer, false)
	end
end
addEventHandler("onVehicleExit", getRootElement(), vehicleExit)

function destroyTyre(veh)
	local tyre1, tyre2, tyre3, tyre4 = getVehicleWheelStates(veh)

	if (tyre1==1) then
		tyre1 = 2
	end

	if (tyre2==1) then
		tyre2 = 2
	end

	if (tyre3==1) then
		tyre3 = 2
	end

	if (tyre4==1) then
		tyre4 = 2
	end

	if (tyre1==2 and tyre2==2 and tyre3==2 and tyre4==2) then
		tyre3 = 0
	end

	exports.anticheat:changeProtectedElementDataEx(veh, "tyretimer")
	setVehicleWheelStates(veh, tyre1, tyre2, tyre3, tyre4)
end

function damageTyres()
	local tyre1, tyre2, tyre3, tyre4 = getVehicleWheelStates(source)
	local tyreTimer = getElementData(source, "tyretimer")

	if (tyretimer~=1) then
		if (tyre1==1) or (tyre2==1) or (tyre3==1) or (tyre4==1) then
			exports.anticheat:changeProtectedElementDataEx(source, "tyretimer", 1, false)
			local randTime = math.random(5, 15)
			randTime = randTime * 1000
			setTimer(destroyTyre, randTime, 1, source)
		end
	end
end
addEventHandler("onVehicleDamage", getRootElement(), damageTyres)

-- Bind Keys required
function bindKeys()
	local players = exports.pool:getPoolElementsByType("player")
	for k, arrayPlayer in ipairs(players) do
		if not(isKeyBound(arrayPlayer, "j", "down", toggleEngine)) then
			bindKey(arrayPlayer, "j", "down", toggleEngine)
		end

		if not(isKeyBound(arrayPlayer, "l", "down", toggleLights)) then
			bindKey(arrayPlayer, "l", "down", toggleLights)
		end

		if not(isKeyBound(arrayPlayer, "k", "down", toggleLock)) then
			bindKey(arrayPlayer, "k", "down", toggleLock)
		end
	end
end

function bindKeysOnJoin()
	bindKey(source, "j", "down", toggleEngine)
	bindKey(source, "l", "down", toggleLights)
	bindKey(source, "k", "down", toggleLock)
end
addEventHandler("onResourceStart", getResourceRootElement(), bindKeys)
addEventHandler("onPlayerJoin", getRootElement(), bindKeysOnJoin)

function toggleEngine(source, key, keystate)
	local veh = getPedOccupiedVehicle(source)
	local inVehicle = getElementData(source, "realinvehicle")

	if veh and inVehicle == 1 then
		local seat = getPedOccupiedVehicleSeat(source)

		if (seat == 0) then
			local model = getElementModel(veh)
			if not (enginelessVehicle[model]) then
				local engine = getElementData(veh, "engine")
				local vehID = getElementData(veh, "dbid")
				local vehKey = exports['global']:hasItem(source, 3, vehID)
				if engine == 0 then
					local vjob = tonumber(getElementData(veh, "job"))
					local job = getElementData(source, "job")
					local owner = getElementData(veh, "owner")
					local faction = tonumber(getElementData(veh, "faction"))
					local playerFaction = tonumber(getElementData(source, "faction"))
					-- Anthony's fix - MAXIME FIXED ANTHONY'S MESS
					if (vehKey) or (owner < 0) and (faction == -1) or (playerFaction == faction) and (faction ~= -1) or ((getElementData(source, "duty_admin") or 0) == 1) then
						local fuel = getElementData(veh, "fuel")
						local broke = getElementData(veh, "enginebroke")
						if broke == 1 then
							triggerEvent('sendAme', source, "attempts to start the engine but fails.")
							outputChatBox("The engine is broken.", source)
						elseif exports.global:hasItem(veh, 74) then
							while exports.global:hasItem(veh, 74) do
								exports.global:takeItem(veh, 74)
							end

							blowVehicle(veh)
						elseif fuel > 0 then
							toggleControl(source, 'brake_reverse', true)
							setVehicleEngineState(veh, true)
							exports.anticheat:changeProtectedElementDataEx(veh, "engine", 1, false)
							exports.anticheat:changeProtectedElementDataEx(veh, "vehicle:radio", tonumber(getElementData(veh, "vehicle:radio:old")), true)
							exports.anticheat:changeProtectedElementDataEx(veh, "lastused", exports.datetime:now(), true)
							mysql:query_free("UPDATE vehicles SET lastUsed=NOW() WHERE id="..vehID)
							exports['vehicle-manager']:addVehicleLogs(vehID, "Started engine", source)
							exports.logs:dbLog("SYSTEM", 31, { veh, source } , "STARTED ENGINE")
						elseif fuel <= 0 then
							triggerEvent('sendAme', source, "attempts to turn the engine on and fails.")
							outputChatBox("This vehicle has no fuel.", source)
						end
					else
						outputChatBox("You require a key to start this vehicle.", source, 255, 0, 0)
					end
				else
					toggleControl(source, 'brake_reverse', false)
					setVehicleEngineState(veh, false)
					exports.anticheat:changeProtectedElementDataEx(veh, "engine", 0, false)
					exports.anticheat:changeProtectedElementDataEx(veh, "vehicle:radio", 0, true)
				end
			end
		end
	end
end
addEvent("toggleEngine", true)
addEventHandler("toggleEngine", root, toggleEngine)
addCommandHandler("engine", toggleEngine)

function toggleLock(source, key, keystate)
	local veh = getPedOccupiedVehicle(source)
	local inVehicle = getElementData(source, "realinvehicle")

	if (veh) and (inVehicle==1) then
		triggerEvent("lockUnlockInsideVehicle", source, veh)
	elseif not veh then
		if getElementDimension(source) >= 19000 then
			local vehicle = exports.pool:getElement("vehicle", getElementDimension(source) - 20000)
			if vehicle and exports['vehicle-interiors']:isNearExit(source, vehicle) then
				local model = getElementModel(vehicle)
				local owner = getElementData(vehicle, "owner")
				local dbid = getElementData(vehicle, "dbid")

				--if (owner ~= -1) then
					if ( getElementData(vehicle, "Impounded") or 0 ) == 0 then
						local locked = isVehicleLocked(vehicle)
						if (locked) then
							setVehicleLocked(vehicle, false)
							triggerEvent('sendAme', source, "unlocks the vehicle doors.")
						else
							setVehicleLocked(vehicle, true)
							triggerEvent('sendAme', source, "locks the vehicle doors.")
						end
					else
						outputChatBox("(( You can't lock impounded vehicles. ))", source, 255, 195, 14)
					end
				--else
					--outputChatBox("(( You can't lock civilian vehicles. ))", source, 255, 195, 14)
				--end
				return
			end
		end

		local interiorFound, interiorDistance = exports['interior-system']:lockUnlockHouseEvent(source, true)

		local x, y, z = getElementPosition(source)
		local nearbyVehicles = exports.global:getNearbyElements(source, "vehicle", 30)

		local found = nil
		local shortest = 31
		for i, veh in ipairs(nearbyVehicles) do
			local dbid = tonumber(getElementData(veh, "dbid"))
			local distanceToVehicle = getDistanceBetweenPoints3D(x, y, z, getElementPosition(veh))
			if shortest > distanceToVehicle and ( exports.global:isStaffOnDuty(source) or exports.global:hasItem(source, 3, dbid) or (getElementData(source, "faction") > 0 and getElementData(source, "faction") == getElementData(veh, "faction")) ) then
				shortest = distanceToVehicle
				found = veh
			end
		end

		if (interiorFound and found) then
			if shortest < interiorDistance then
				triggerEvent("lockUnlockOutsideVehicle", source, found)
			else
				triggerEvent("lockUnlockHouse", source)
			end
		elseif found then
			triggerEvent("lockUnlockOutsideVehicle", source, found)
		elseif interiorFound then
			triggerEvent("lockUnlockHouse", source)
		end
	end
end
addCommandHandler("lock", toggleLock, true)
addEvent("togLockVehicle", true)
addEventHandler("togLockVehicle", getRootElement(), toggleLock)

function checkLock(thePlayer, seat, jacked)
	local locked = isVehicleLocked(source)

	if (locked) and not (jacked) then
		cancelEvent()
		outputChatBox("The door is locked.", thePlayer)
	end
end
addEventHandler("onVehicleStartExit", getRootElement(), checkLock)

function toggleLights(source, key, keystate)
	local veh = getPedOccupiedVehicle(source)
	local inVehicle = getElementData(source, "realinvehicle")

	if (veh) and (inVehicle==1) then
		local model = getElementModel(veh)
		if not (lightlessVehicle[model]) then
			local lights = getVehicleOverrideLights(veh)
			local seat = getPedOccupiedVehicleSeat(source)

			if (seat==0) then
				if (lights~=2) then
					setVehicleOverrideLights(veh, 2)
					exports.anticheat:changeProtectedElementDataEx(veh, "lights", 1, true)
					local trailer = getVehicleTowedByVehicle(veh)
					if trailer then
						setVehicleOverrideLights(trailer, 2)
					end
				elseif (lights~=1) then
					setVehicleOverrideLights(veh, 1)
					exports.anticheat:changeProtectedElementDataEx(veh, "lights", 0, true)
					local trailer = getVehicleTowedByVehicle(veh)
					if trailer then
						setVehicleOverrideLights(trailer, 1)
					end
				end
			end
		end
	end
end
addCommandHandler("lights", toggleLights, true)
addEvent('togLightsVehicle', true)
addEventHandler('togLightsVehicle', root,
	function()
		toggleLights(client)
	end)

--/////////////////////////////////////////////////////////
--Fix for spamming keys to unlock etc on entering
--/////////////////////////////////////////////////////////

-- bike lock fix
function checkBikeLock(thePlayer)
	if (isVehicleLocked(source)) and (getVehicleType(source)=="Bike" or getVehicleType(source)=="Boat" or getVehicleType(source)=="BMX" or getVehicleType(source)=="Quad" or getElementModel(source)==568 or getElementModel(source)==571 or getElementModel(source)==572 or getElementModel(source)==424 or getElementModel(source)==431 or getElementModel(source)==437) then
		if not getElementData(thePlayer, "interiormarker") then
			outputChatBox("That vehicle is locked.", thePlayer, 255, 194, 15)
		end
		cancelEvent()
	end
end
addEventHandler("onVehicleStartEnter", getRootElement(), checkBikeLock)

function setRealInVehicle(thePlayer)
	if isVehicleLocked(source) then
		exports.anticheat:changeProtectedElementDataEx(thePlayer, "realinvehicle", 0, false)
		removePedFromVehicle(thePlayer)
		setVehicleLocked(source, true)
	else
		--MAXIME 'S CUSTOM VEHICLE
		local brand = getElementData(source, "brand") or false
		local model = getElementData(source, "maximemodel")
		local year = getElementData(source, "year")
		exports.anticheat:changeProtectedElementDataEx(thePlayer, "realinvehicle", 1, false)

		-- 0000464: Car owner message.
		local owner = getElementData(source, "owner") or -1
		local faction = getElementData(source, "faction") or -1
		local carName = getVehicleName(source)

		if owner < 0 and faction == -1 then
			if brand then
				outputChatBox("(( This "..year.." "..brand.." "..model.." is a civilian vehicle. ))", thePlayer, 255, 194, 14)
			else
				outputChatBox("(( This "..carName.." is a civilian vehicle. ))", thePlayer, 255, 194, 14)
			end
		elseif (faction==-1) and (owner>0) then
			local ownerName = exports['cache']:getCharacterName(owner)

			if ownerName then
				if brand then
					outputChatBox("(( This "..year.." "..brand.." "..model.." belongs to " .. ownerName .. ". ))", thePlayer, 255, 194, 14)
				else
					outputChatBox("(( This "..carName.." belongs to " .. ownerName .. ". ))", thePlayer, 255, 194, 14)
				end
				if (getElementData(source, "Impounded") > 0) then
					local output = getRealTime().yearday-getElementData(source, "Impounded")
					if brand then
						outputChatBox("(( This "..year.." "..brand.." "..model.." has been Impounded for: " .. output .. (output == 1 and " Day." or " Days.") .. " ))", thePlayer, 255, 194, 14)
					else
						outputChatBox("(( This "..carName.." has been Impounded for: " .. output .. (output == 1 and " Day." or " Days.") .. " ))", thePlayer, 255, 194, 14)
					end
				end
			end
		end
	end
end
addEventHandler("onVehicleEnter", getRootElement(), setRealInVehicle)

function setRealNotInVehicle(thePlayer)
	local locked = isVehicleLocked(source)

	if not (locked) then
		if (thePlayer) then
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "realinvehicle", 0, false)
		end
	end
end
addEventHandler("onVehicleStartExit", getRootElement(), setRealNotInVehicle)

-- Faction vehicles removal script
function removeFromFactionVehicle(thePlayer)
	--MAXIME 'S CUSTOM VEHICLE
	local brand = getElementData(source, "brand") or false
	local model = getElementData(source, "maximemodel")
	local year = getElementData(source, "year")

	local faction = getElementData(thePlayer, "faction")
	local vfaction = tonumber(getElementData(source, "faction"))
	local CanTowDriverEnter = (call(getResourceFromName("tow-system"), "CanTowTruckDriverVehPos", thePlayer) == 2)
	if (vfaction~=-1) then
		local seat = getPedOccupiedVehicleSeat(thePlayer)
		local factionName = "None (to be deleted)"
		for key, value in ipairs(exports.pool:getPoolElementsByType("team")) do
			local id = tonumber(getElementData(value, "id"))
			if (id==vfaction) then
				factionName = getTeamName(value)
				break
			end
		end
		if (faction~=vfaction) and (seat==0) then
			if (CanTowDriverEnter) then
				if brand then
					outputChatBox("(( This "..year.." "..brand.." "..model.." belongs to '" .. factionName .. "'. ))", thePlayer, 255, 194, 14)
				else
					outputChatBox("(( This "..getVehicleName(source).." belongs to '" .. factionName .. "'. ))", thePlayer, 255, 194, 14)
				end
				exports.anticheat:changeProtectedElementDataEx(source, "enginebroke", 1, false)
				setVehicleDamageProof(source, true)
				setVehicleEngineState(source, false)
				return
			end
			if brand then
				outputChatBox("(( This "..year.." "..brand.." "..model.." belongs to '" .. factionName .. "'. ))", thePlayer, 255, 194, 14)
			else
				outputChatBox("(( This "..getVehicleName(source).." belongs to '" .. factionName .. "'. ))", thePlayer, 255, 194, 14)
			end
		end
	end
	local Impounded = getElementData(source,"Impounded")
	if (Impounded and Impounded > 0) then
		exports.anticheat:changeProtectedElementDataEx(source, "enginebroke", 1, false)
		setVehicleDamageProof(source, true)
		setVehicleEngineState(source, false)
	end
	if (CanTowDriverEnter) then -- Nabs abusing
		return
	end
	local vjob = tonumber(getElementData(source, "job")) or -1
	local job = getElementData(thePlayer, "job") or -1
	local seat = getPedOccupiedVehicleSeat(thePlayer)

	if (vjob>0) and (seat==0) then
		--[[ -- MOVED TO JOB SYSTEM / MAXIME
		if (job~=vjob) then
			if (vjob==1) then
				outputChatBox("You are not a delivery driver. Visit city hall to obtain this job.", thePlayer, 255, 0, 0)
			elseif (vjob==2) then
				outputChatBox("You are not a taxi driver. Visit city hall to obtain this job.", thePlayer, 255, 0, 0)
			elseif (vjob==3) then
				outputChatBox("You are not a bus driver. Visit city hall to obtain this job.", thePlayer, 255, 0, 0)
			end
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "realinvehicle", 0, false)
			removePedFromVehicle(thePlayer)
			local x, y, z = getElementPosition(thePlayer)
			setElementPosition(thePlayer, x, y, z)
			return
		end
		]]

		-- remove masks etc. for civilian job vehicles
		for key, value in pairs(exports['item-system']:getMasks()) do
			if getElementData(thePlayer, value[1]) then
				exports.global:sendLocalMeAction(thePlayer, value[3] .. ".")
				exports.anticheat:changeProtectedElementDataEx(thePlayer, value[1], false, true)
			end
		end
	end
end
addEventHandler("onVehicleEnter", getRootElement(), removeFromFactionVehicle)

-- engines dont break down
function doBreakdown()
	if exports.global:hasItem(source, 74) then
		while exports.global:hasItem(source, 74) do
			exports.global:takeItem(source, 74)
		end

		blowVehicle(source)
	else
		local health = getElementHealth(source)
		local broke = getElementData(source, "enginebroke")

		if (health<=350) and (broke==0 or broke==false) then
			setElementHealth(source, 300)
			setVehicleDamageProof(source, true)
			setVehicleEngineState(source, false)
			exports.anticheat:changeProtectedElementDataEx(source, "enginebroke", 1, false)
			exports.anticheat:changeProtectedElementDataEx(source, "engine", 0, false)

			local player = getVehicleOccupant(source)
			if player then
				toggleControl(player, 'brake_reverse', false)
			end
		end
	end
end
addEventHandler("onVehicleDamage", getRootElement(), doBreakdown)



------------------------------------------------
-- SELL A VEHICLE
------------------------------------------------
function sellVehicle(thePlayer, commandName, targetPlayerName)
	-- can only sell vehicles outdoor, in a dimension is property
	if isPedInVehicle(thePlayer) then
		if not targetPlayerName then
			outputChatBox("SYNTAX: /" .. commandName .. " [partial player name / id]", thePlayer, 255, 194, 14)
			outputChatBox("Sells the Vehicle you're in to that Player.", thePlayer, 255, 194, 14)
			outputChatBox("Ask the buyer to use /pay to recieve the money for the vehicle.", thePlayer, 255, 194, 14)
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, targetPlayerName)
			if targetPlayer and getElementData(targetPlayer, "dbid") then
				local px, py, pz = getElementPosition(thePlayer)
				local tx, ty, tz = getElementPosition(targetPlayer)
				if getDistanceBetweenPoints3D(px, py, pz, tx, ty, tz) < 20 then
					local theVehicle = getPedOccupiedVehicle(thePlayer)
					if theVehicle then
						local vehicleID = getElementData(theVehicle, "dbid")
						if getElementData(theVehicle, "owner") == getElementData(thePlayer, "dbid") or exports.integration:isPlayerTrialAdmin(thePlayer) then
							if getElementData(targetPlayer, "dbid") ~= getElementData(theVehicle, "owner") then
								if exports.global:hasSpaceForItem(targetPlayer, 3, vehicleID) then
									if exports.global:canPlayerBuyVehicle(targetPlayer) then
										--if exports.integration:isPlayerTrialAdmin(thePlayer) --[[or exports['carshop-system']:isForSale(theVehicle)]] then
											local query = mysql:query_free("UPDATE vehicles SET owner = '" .. mysql:escape_string(getElementData(targetPlayer, "dbid")) .. "', lastUsed=NOW() WHERE id='" .. mysql:escape_string(vehicleID) .. "'")
											if query then
												exports.anticheat:changeProtectedElementDataEx(theVehicle, "owner", getElementData(targetPlayer, "dbid"), true)
												exports.anticheat:changeProtectedElementDataEx(theVehicle, "owner_last_login", exports.datetime:now(), true)
												exports.anticheat:changeProtectedElementDataEx(theVehicle, "lastused", exports.datetime:now(), true)

												exports.global:takeItem(thePlayer, 3, vehicleID)

												if not exports.global:hasItem(targetPlayer, 3, vehicleID) then
													exports.global:giveItem(targetPlayer, 3, vehicleID)
												end

												exports.logs:logMessage("[SELL] car #" .. vehicleID .. " was sold from " .. getPlayerName(thePlayer):gsub("_", " ") .. " to " .. targetPlayerName, 9)

												outputChatBox("You've successfully sold your " .. getVehicleName(theVehicle) .. " to " .. targetPlayerName .. ".", thePlayer, 0, 255, 0)
												outputChatBox((getPlayerName(thePlayer):gsub("_", " ")) .. " sold you a " .. getVehicleName(theVehicle) .. ".", targetPlayer, 0, 255, 0)
												outputChatBox("Please remember to /park your " .. getVehicleName(theVehicle) .. ".", targetPlayer, 255, 255, 0)



												local adminID = getElementData(thePlayer, "account:id")
												local addLog = mysql:query_free("INSERT INTO `vehicle_logs` (`vehID`, `action`, `actor`) VALUES ('"..tostring(vehicleID).."', '"..commandName.." to "..getPlayerName(targetPlayer).."', '"..adminID.."')") or false
												if not addLog then
													outputDebugString("Failed to add vehicle logs.")
												end
												exports.logs:dbLog(thePlayer, 6, { theVehicle, thePlayer, targetPlayer }, "SELL '".. getVehicleName(theVehicle).."' '".. (getPlayerName(thePlayer):gsub("_", " ")) .."' => '".. targetPlayerName .."'")

											else
												outputChatBox("Unable to process request - report on bugs.mta.vg.", thePlayer, 255, 0, 0)
											end
										--else
											--outputChatBox("You can not sell special vehicles. Contact an admin via F2 to have it refunded.", thePlayer, 255, 0, 0)
										--end
									else
										outputChatBox(targetPlayerName .. " has already too much vehicles.", thePlayer, 255, 0, 0)
										outputChatBox((getPlayerName(thePlayer):gsub("_", " ")) .. " tried to sell you a car, but you have too much cars already.", targetPlayer, 255, 0, 0)
									end
								else
									outputChatBox(targetPlayerName .. " has no space for the vehicle keys.", thePlayer, 255, 0, 0)
									outputChatBox((getPlayerName(thePlayer):gsub("_", " ")) .. " tried to sell you a car, but you haven't got space for a key.", targetPlayer, 255, 0, 0)
								end
							else
								outputChatBox("You can't sell your own vehicle to yourself.", thePlayer, 255, 0, 0)
							end
						else
							outputChatBox("This vehicle is not yours.", thePlayer, 255, 0, 0)
						end
					else
						outputChatBox("You must be in a Vehicle.", thePlayer, 255, 0, 0)
					end
				else
					outputChatBox("You are too far away from " .. targetPlayerName .. ".", thePlayer, 255, 0, 0)
				end
			end
		end
	end
end
addEvent("sellVehicle", true)
addEventHandler("sellVehicle", getResourceRootElement(), sellVehicle)

function toggleSellExceptions (thePlayer, commandName, player)
	if (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) and player then
		local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, player)
		if getElementData(targetPlayer, "temporarySell") == true then
			setElementData(targetPlayer, "temporarySell", false)
			outputChatBox("You have revoked "..targetPlayerName.." temporary access to use /sell.", thePlayer)
			outputChatBox("An administrator has revoked your temporary access to use /sell.", targetPlayer)
		else
			setElementData(targetPlayer, "temporarySell", true)
			outputChatBox("You have given "..targetPlayerName.." temporary access to use /sell.", thePlayer)
			outputChatBox("An administrator has given you temporary access to use /sell.", targetPlayer)
		end
	elseif not player and (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) then
		outputChatBox("SYNTAX: /"..commandName.." [player] - This gives temporary access for old /sell.", thePlayer)
	end
end
addCommandHandler("tempsell", toggleSellExceptions)

function AdminVehicleSale(thePlayer, commandName, args)
	if isPedInVehicle(thePlayer) then
		local vehType = getVehicleType(getPedOccupiedVehicle(thePlayer))
		if ( vehType == ("Plane" or "Helicopter" or "Boat") or (getElementData(thePlayer, "temporarySell") == true ) or (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) ) and not args then
			outputChatBox("SYNTAX: /" .. commandName .. " [partial player name / id]", thePlayer, 255, 194, 14)
			outputChatBox("Sells the Vehicle you're in to that Player.", thePlayer, 255, 194, 14)
			outputChatBox("Ask the buyer to use /pay to recieve the money for the vehicle.", thePlayer, 255, 194, 14)
		elseif ( vehType == ("Plane" or "Helicopter" or "Boat") or (getElementData(thePlayer, "temporarySell") == true ) or (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) ) and args then
			triggerEvent("sellVehicle", getResourceRootElement(), thePlayer, "sell", args)
		end
	end
end
addCommandHandler("sell", AdminVehicleSale)



function lockUnlockInside(vehicle)
	local model = getElementModel(vehicle)
	local owner = getElementData(vehicle, "owner")
	local dbid = getElementData(vehicle, "dbid")

	--if (owner ~= -1) then
		if ( getElementData(vehicle, "Impounded") or 0 ) == 0 then
			if not locklessVehicle[model] or exports.global:hasItem( source, 3, dbid ) then
				if (getElementData(source, "realinvehicle") == 1) then
					local locked = isVehicleLocked(vehicle)
					local seat = getPedOccupiedVehicleSeat(source)
					if seat == 0 or exports.global:hasItem( source, 3, dbid ) then
						playCarToglockSoundFxInside(vehicle, not locked)
						if (locked) then
							setVehicleLocked(vehicle, false)
							triggerEvent('sendAme', source, "unlocks the vehicle doors.")
							exports.logs:dbLog(source, 31, {  vehicle }, "UNLOCK FROM INSIDE")
						else
							setVehicleLocked(vehicle, true)
							triggerEvent('sendAme', source, "locks the vehicle doors.")
							exports.logs:dbLog(source, 31, {  vehicle }, "LOCK FROM INSIDE")
						end
					end
				end
			end
		else
			outputChatBox("(( You can't lock impounded vehicles. ))", source, 255, 195, 14)
		end
	--else
		--outputChatBox("(( You can't lock civilian vehicles. ))", source, 255, 195, 14)
	--end

end
addEvent("lockUnlockInsideVehicle", true)
addEventHandler("lockUnlockInsideVehicle", getRootElement(), lockUnlockInside)


local storeTimers = { }

function lockUnlockOutside(vehicle)
	if (not source or exports.integration:isPlayerTrialAdmin(source)) or ( getElementData(vehicle, "Impounded") or 0 ) == 0 then
		local dbid = getElementData(vehicle, "dbid")
		blinkLightsAndSoundOnLockUnlock(vehicle) -- maxime
		--exports.global:applyAnimation(source, "GHANDS", "gsign3LH", 2000, false, false, false)

		if (isVehicleLocked(vehicle)) then
			setVehicleLocked(vehicle, false)
			triggerEvent('sendAme', source, "presses on the key to unlock the vehicle. ((" .. getVehicleName(vehicle) .. "))")
			exports.logs:dbLog(source, 31, {  vehicle }, "UNLOCK FROM OUTSIDE")
			if not (exports.global:hasItem(source, 3, dbid) or (getElementData(source, "faction") > 0 and getElementData(source, "faction") == getElementData(vehicle, "faction"))) then
				exports.logs:logMessage("[CAR-UNLOCK] car #" .. dbid .. " was unlocked by " .. getPlayerName(source), 21)
			end
		else
			setVehicleLocked(vehicle, true)
			triggerEvent('sendAme', source, "presses on the key to lock the vehicle. ((" .. getVehicleName(vehicle) .. "))")
			exports.logs:dbLog(source, 31, {  vehicle }, "LOCK FROM OUTSIDE")
			if not (exports.global:hasItem(source, 3, dbid) or (getElementData(source, "faction") > 0 and getElementData(source, "faction") == getElementData(vehicle, "faction"))) then
				exports.logs:logMessage("[CAR-LOCK] car #" .. dbid .. " was locked by " .. getPlayerName(source), 21)
			end
		end

		if (storeTimers[vehicle] == nil) or not (isTimer(storeTimers[vehicle])) then
			storeTimers[vehicle] = setTimer(storeVehicleLockState, 180000, 1, vehicle, dbid)
		end
	end
end
addEvent("lockUnlockOutsideVehicle", true)
addEventHandler("lockUnlockOutsideVehicle", getRootElement(), lockUnlockOutside)

function storeVehicleLockState(vehicle, dbid)
	if (isElement(vehicle)) then
		local newdbid = getElementData(vehicle, "dbid")
		if tonumber(newdbid) > 0 then
			local locked = isVehicleLocked(vehicle)

			local state = 0
			if (locked) then
				state = 1
			end

			local query = mysql:query_free("UPDATE vehicles SET locked='" .. mysql:escape_string(tostring(state)) .. "' WHERE id='" .. mysql:escape_string(tostring(newdbid)) .. "' LIMIT 1")
		end
		storeTimers[vehicle] = nil
	end
end

function fillFuelTank(veh, fuel)
	local currFuel = getElementData(veh, "fuel")
	local engine = getElementData(veh, "engine")
	local max = exports["fuel-system"]:getMaxFuel(getElementModel(veh))
	if (math.ceil(currFuel)==max) then
		outputChatBox("This vehicle is already full.", source)
	elseif (fuel==0) then
		outputChatBox("This fuel can is empty.", source, 255, 0, 0)
	elseif (engine==1) then
		outputChatBox("You can not fuel running vehicles. Please stop the engine first.", source, 255, 0, 0)
	else
		local fuelAdded = fuel

		if (fuelAdded+currFuel>max) then
			fuelAdded = max - currFuel
		end

		outputChatBox("You added " .. math.ceil(fuelAdded) .. " litres of petrol to your car from your fuel can.", source, 0, 255, 0 )

		local gender = getElementData(source, "gender")
		local genderm = "his"
		if (gender == 1) then
			genderm = "her"
		end
		triggerEvent('sendAme', source, "fills up " .. genderm .. " vehicle from a small petrol canister.")
		exports.global:takeItem(source, 57, fuel)
		exports.global:giveItem(source, 57, math.ceil(fuel-fuelAdded))

		exports.anticheat:changeProtectedElementDataEx(veh, "fuel", currFuel+fuelAdded, false)
		triggerClientEvent(source, "syncFuel", veh, currFuel+fuelAdded)
	end
end
addEvent("fillFuelTankVehicle", true)
addEventHandler("fillFuelTankVehicle", getRootElement(), fillFuelTank)

function getYearDay(thePlayer)
	local time = getRealTime()
	local currYearday = time.yearday

	outputChatBox("Year day is " .. currYearday, thePlayer)
end
addCommandHandler("yearday", getYearDay)

function removeNOS(theVehicle)
	removeVehicleUpgrade(theVehicle, getVehicleUpgradeOnSlot(theVehicle, 8))
	triggerEvent('sendAme', source, "removes NOS from the " .. getVehicleName(theVehicle) .. ".")
	exports['savevehicle-system']:saveVehicleMods(theVehicle)
	exports.logs:dbLog(source, 4, {  theVehicle }, "MODDING REMOVENOS")
end
addEvent("removeNOS", true)
addEventHandler("removeNOS", getRootElement(), removeNOS)

-- /VEHPOS /PARK
local destroyTimers = { }
--[[
function createShopVehicle(dbid, ...)
	local veh = createVehicle(unpack({...}))
	exports.pool:allocateElement(veh, dbid)

	exports.anticheat:changeProtectedElementDataEx(veh, "dbid", dbid)
	exports.anticheat:changeProtectedElementDataEx(veh, "requires.vehpos", 1, false)
	local timer = setTimer(checkVehpos, 3600000, 1, veh, dbid)
	table.insert(destroyTimers, {timer, dbid})

	exports['vehicle-interiors']:add( veh )

	return veh
end
]]

function checkVehpos(veh, dbid)
	local requires = getElementData(veh, "requires.vehpos")

	if (requires) then
		if (requires==1) then
			local id = tonumber(getElementData(veh, "dbid"))

			if (id==dbid) then
				exports.logs:logMessage("[VEHPOS DELETE] car #" .. id .. " was deleted", 9)
				destroyElement(veh)
				local query = mysql:query_free("DELETE FROM vehicles WHERE id='" .. mysql:escape_string(id) .. "' LIMIT 1")

				call( getResourceFromName( "item-system" ), "clearItems", veh )
				call( getResourceFromName( "item-system" ), "deleteAll", 3, id )
			end
		end
	end
end
-- VEHPOS
local PershingSquareCol = createColRectangle( 1420, -1775, 130, 257 )
local HospitalCol = createColRectangle( 1166, -1384, 52, 92 )

function setVehiclePosition(thePlayer, commandName)
	local veh = getPedOccupiedVehicle(thePlayer)
	if not veh or getElementData(thePlayer, "realinvehicle") == 0 then
		outputChatBox("You are not in a vehicle.", thePlayer, 255, 0, 0)
	else
		if call( getResourceFromName("tow-system"), "cannotVehpos", thePlayer, veh ) and not exports.integration:isPlayerTrialAdmin(thePlayer) and not exports.integration:isPlayerSupporter(thePlayer) then
			outputChatBox("It is not possible to park your vehicle here.", thePlayer, 255, 0, 0)
		elseif isElementWithinColShape( thePlayer, HospitalCol ) and getElementData( thePlayer, "faction" ) ~= 2 and not exports.integration:isPlayerTrialAdmin(thePlayer) and not exports.integration:isPlayerSupporter(thePlayer) then
			outputChatBox("Only Los Santos Emergency Service is allowed to park their vehicles in front of the Hospital.", thePlayer, 255, 0, 0)
		elseif isElementWithinColShape( thePlayer, PershingSquareCol ) and getElementData( thePlayer, "faction" ) ~= 1  and not exports.integration:isPlayerTrialAdmin(thePlayer) and not exports.integration:isPlayerSupporter(thePlayer) then
			outputChatBox("Only Los Santos Police Department is allowed to park their vehicles on Pershing Square.", thePlayer, 255, 0, 0)
		else
			local playerid = getElementData(thePlayer, "dbid")
			local playerfl = getElementData(thePlayer, "factionleader")
			local playerfid = getElementData(thePlayer, "faction")
			local owner = getElementData(veh, "owner")
			local dbid = getElementData(veh, "dbid")
			local carfid = getElementData(veh, "faction")
			local x, y, z = getElementPosition(veh)
			local TowingReturn = call(getResourceFromName("tow-system"), "CanTowTruckDriverVehPos", thePlayer) -- 2 == in towing and in col shape, 1 == colshape only, 0 == not in col shape
			if (owner==playerid and TowingReturn == 0) or (exports.global:hasItem(thePlayer, 3, dbid)) or (TowingReturn == 2) or (exports.integration:isPlayerSupporter(thePlayer) and  exports.logs:logMessage("[AVEHPOS] " .. getPlayerName( thePlayer ) .. " parked car #" .. dbid .. " at " .. x .. ", " .. y .. ", " .. z, 9)) or (exports.integration:isPlayerTrialAdmin(thePlayer) and exports.logs:logMessage("[AVEHPOS] " .. getPlayerName( thePlayer ) .. " parked car #" .. dbid .. " at " .. x .. ", " .. y .. ", " .. z, 9)) then
				if (dbid<0) then
					outputChatBox("This vehicle is not permanently spawned.", thePlayer, 255, 0, 0)
				else
					if (call(getResourceFromName("tow-system"), "CanTowTruckDriverGetPaid", thePlayer)) then
						-- pd has to pay for this impound
						exports.global:giveMoney(exports.pool:getElement("team", 4), 75)
						exports.global:takeMoney(exports.pool:getElement("team", 4), 75)
					end
					exports.anticheat:changeProtectedElementDataEx(veh, "requires.vehpos")
					local rx, ry, rz = getVehicleRotation(veh)

					local interior = getElementInterior(thePlayer)
					local dimension = getElementDimension(thePlayer)

					local query = mysql:query_free("UPDATE vehicles SET x='" .. mysql:escape_string(x) .. "', y='" .. mysql:escape_string(y) .."', z='" .. mysql:escape_string(z) .. "', rotx='" .. mysql:escape_string(rx) .. "', roty='" .. mysql:escape_string(ry) .. "', rotz='" .. mysql:escape_string(rz) .. "', currx='" .. mysql:escape_string(x) .. "', curry='" .. mysql:escape_string(y) .. "', currz='" .. mysql:escape_string(z) .. "', currrx='" .. mysql:escape_string(rx) .. "', currry='" .. mysql:escape_string(ry) .. "', currrz='" .. mysql:escape_string(rz) .. "', interior='" .. mysql:escape_string(interior) .. "', currinterior='" .. mysql:escape_string(interior) .. "', dimension='" .. mysql:escape_string(dimension) .. "', currdimension='" .. mysql:escape_string(dimension) .. "' WHERE id='" .. mysql:escape_string(dbid) .. "'")
					setVehicleRespawnPosition(veh, x, y, z, rx, ry, rz)
					exports.anticheat:changeProtectedElementDataEx(veh, "respawnposition", {x, y, z, rx, ry, rz}, false)
					exports.anticheat:changeProtectedElementDataEx(veh, "interior", interior)
					exports.anticheat:changeProtectedElementDataEx(veh, "dimension", dimension)
					outputChatBox("Vehicle spawn position set.", thePlayer)
					exports.logs:dbLog(thePlayer, 4, {  veh }, "PARK")

					local adminID = getElementData(thePlayer, "account:id")
					local addLog = mysql:query_free("INSERT INTO `vehicle_logs` (`vehID`, `action`, `actor`) VALUES ('"..tostring(dbid).."', '"..commandName.."', '"..adminID.."')") or false
					if not addLog then
						outputDebugString("Failed to add vehicle logs.")
					end

					for key, value in ipairs(destroyTimers) do
						if (tonumber(destroyTimers[key][2]) == dbid) then
							local timer = destroyTimers[key][1]

							if (isTimer(timer)) then
								killTimer(timer)
								table.remove(destroyTimers, key)
							end
						end
					end

					if ( getElementData(veh, "Impounded") or 0 ) > 0 then
						local owner = getPlayerFromName( exports['cache']:getCharacterName( getElementData( veh, "owner" ) ) )
						if isElement( owner ) and exports.global:hasItem( owner, 2 ) then
							outputChatBox("((SFT&R)) #5555 [SMS]: Your " .. getVehicleName(veh) .. " has been impounded. Head over to the impound to release it.", owner, 120, 255, 80)
						end
					end
				end
			end
		end
	end
end
addCommandHandler("vehpos", setVehiclePosition, false, false)
addCommandHandler("park", setVehiclePosition, false, false)

function autoSetVehiclePosition(thePlayer, seat, jacked)
	if thePlayer and seat == 0 then
		if getElementData(thePlayer, "autopark") == "1" then
			local dbid = getElementData(source, "dbid")
			if getElementData(source, "owner") > -1 and dbid > 0 then
				if exports.global:hasItem(thePlayer, 3, dbid) or exports.global:hasItem(source, 3, dbid) then
					local x, y, z = getElementPosition(source)
					local rx, ry, rz = getElementRotation(source)
					local interior = getElementInterior(source)
					local dimension = getElementDimension(source)
					local query = mysql:query_free("UPDATE `vehicles` SET `x`='" .. mysql:escape_string(x) .. "', `y`='" .. mysql:escape_string(y) .."', `z`='" .. mysql:escape_string(z) .. "', `rotx`='" .. mysql:escape_string(rx) .. "', `roty`='" .. mysql:escape_string(ry) .. "', `rotz`='" .. mysql:escape_string(rz) .. "', `currx`='" .. mysql:escape_string(x) .. "', `curry`='" .. mysql:escape_string(y) .. "', `currz`='" .. mysql:escape_string(z) .. "', `currrx`='" .. mysql:escape_string(rx) .. "', `currry`='" .. mysql:escape_string(ry) .. "', `currrz`='" .. mysql:escape_string(rz) .. "', `interior`='" .. mysql:escape_string(interior) .. "', `currinterior`='" .. mysql:escape_string(interior) .. "', `dimension`='" .. mysql:escape_string(dimension) .. "', `currdimension`='" .. mysql:escape_string(dimension) .. "' WHERE `id`='" .. mysql:escape_string(dbid) .. "'")
					if not query then
						outputDebugString("[VEHICLE-SYSTEM] Auto park failed, Vehicle: " .. dbid, 2)
					end
					setVehicleRespawnPosition(source, x, y, z, rx, ry, rz)
					exports.anticheat:changeProtectedElementDataEx(source, "respawnposition", {x, y, z, rx, ry, rz}, false)
					exports.anticheat:changeProtectedElementDataEx(source, "interior", interior)
					exports.anticheat:changeProtectedElementDataEx(source, "dimension", dimension)
					exports.logs:dbLog(thePlayer, 4, {  source }, "AUTO-PARK-ON-EXIT")
					--outputDebugString("Autoparked. "..dbid)
					--outputChatBox("Vehicle spawn position set.", thePlayer)
				end
			end
		end
	end
end
addEventHandler("onVehicleExit", getRootElement(), autoSetVehiclePosition)

function toggleAutoPark(thePlayer, commandName)
	--[[local autoPark = getElementData(thePlayer, "autopark")
	local autoParkString
	if autoPark == 1 then
		autoPark = 0
		autoParkString = "Auto park disabled."
	else
		autoPark = 1
		autoParkString = "Auto park enabled."
	end
	local dbid = getElementData(thePlayer, "account:id")
	local query = mysql:query_free("UPDATE accounts SET autopark='".. mysql:escape_string(autoPark) .."' WHERE id = '" .. dbid .. "'")
	if query then
		exports.anticheat:changeProtectedElementDataEx(thePlayer, "autopark", autoPark)
		outputChatBox(autoParkString, thePlayer, 0, 255, 0)
	else
		outputChatBox("MYSQL-ERROR-6969, Please report on the mantis.", thePlayer, 255, 0, 0)
	end
	]]
end
addCommandHandler("toggleautopark", toggleAutoPark, false, false)

function setVehiclePosition2(thePlayer, commandName, vehicleID)
	if exports.integration:isPlayerTrialAdmin( thePlayer ) then
		local vehicleID = tonumber(vehicleID)
		if not vehicleID or vehicleID < 0 then
			outputChatBox( "SYNTAX: /" .. commandName .. " [vehicle id]", thePlayer, 255, 194, 14 )
		else
			local veh = exports.pool:getElement("vehicle", vehicleID)
			if veh then
				exports.anticheat:changeProtectedElementDataEx(veh, "requires.vehpos")
				local x, y, z = getElementPosition(veh)
				local rx, ry, rz = getVehicleRotation(veh)

				local interior = getElementInterior(thePlayer)
				local dimension = getElementDimension(thePlayer)

				local query = mysql:query_free("UPDATE vehicles SET x='" .. mysql:escape_string(x) .. "', y='" .. mysql:escape_string(y) .."', z='" .. mysql:escape_string(z) .. "', rotx='" .. mysql:escape_string(rx) .. "', roty='" .. mysql:escape_string(ry) .. "', rotz='" .. mysql:escape_string(rz) .. "', currx='" .. mysql:escape_string(x) .. "', curry='" .. mysql:escape_string(y) .. "', currz='" .. mysql:escape_string(z) .. "', currrx='" .. mysql:escape_string(rx) .. "', currry='" .. mysql:escape_string(ry) .. "', currrz='" .. mysql:escape_string(rz) .. "', interior='" .. mysql:escape_string(interior) .. "', currinterior='" .. mysql:escape_string(interior) .. "', dimension='" .. mysql:escape_string(dimension) .. "', currdimension='" .. mysql:escape_string(dimension) .. "' WHERE id='" .. mysql:escape_string(vehicleID) .. "'")
				setVehicleRespawnPosition(veh, x, y, z, rx, ry, rz)
				exports.anticheat:changeProtectedElementDataEx(veh, "respawnposition", {x, y, z, rx, ry, rz}, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "interior", interior)
				exports.anticheat:changeProtectedElementDataEx(veh, "dimension", dimension)
				outputChatBox("Vehicle spawn position for #" .. vehicleID .. " set.", thePlayer)
				exports.logs:dbLog(thePlayer, 4, {  veh }, "PARK")
				for key, value in ipairs(destroyTimers) do
					if (tonumber(destroyTimers[key][2]) == vehicleID) then
						local timer = destroyTimers[key][1]

						if (isTimer(timer)) then
							killTimer(timer)
							table.remove(destroyTimers, key)
						end
					end
				end

				if ( getElementData(veh, "Impounded") or 0 ) > 0 then
					local owner = getPlayerFromName( exports['cache']:getCharacterName( getElementData( veh, "owner" ) ) )
					if isElement( owner ) and exports.global:hasItem( owner, 2 ) then
						outputChatBox("((SFT&R)) #5555 [SMS]: Your " .. getVehicleName(veh) .. " has been impounded. Head over to the impound to release it.", owner, 120, 255, 80)
					end
				end
				exports.logs:logMessage("[AVEHPOS] " .. getPlayerName( thePlayer ) .. " parked car #" .. vehicleID .. " at " .. x .. ", " .. y .. ", " .. z, 9)
			else
				outputChatBox("Vehicle not found.", thePlayer, 255, 0, 0 )
			end
		end
	end
end
addCommandHandler("avehpos", setVehiclePosition2, false, false)
addCommandHandler("apark", setVehiclePosition2, false, false)

function setVehiclePosition3(veh)
	if call( getResourceFromName("tow-system"), "cannotVehpos", source ) then
		outputChatBox("Only Los Santos Towing & Recovery is allowed to park their vehicles on the Impound Lot.", source, 255, 0, 0)
	elseif isElementWithinColShape( source, HospitalCol ) and getElementData( source, "faction" ) ~= 2 and not exports.integration:isPlayerTrialAdmin(source) then
		outputChatBox("Only Los Santos Emergency Service is allowed to park their vehicles in front of the Hospital.", source, 255, 0, 0)
	elseif isElementWithinColShape( source, PershingSquareCol ) and getElementData( source, "faction" ) ~= 1  and not exports.integration:isPlayerTrialAdmin(source) then
		outputChatBox("Only Los Santos Police Department is allowed to park their vehicles on Pershing Square.", source, 255, 0, 0)
	else
		local playerid = getElementData(source, "dbid")
		local owner = getElementData(veh, "owner")
		local dbid = getElementData(veh, "dbid")
		local x, y, z = getElementPosition(veh)
		local TowingReturn = call(getResourceFromName("tow-system"), "CanTowTruckDriverVehPos", source) -- 2 == in towing and in col shape, 1 == colshape only, 0 == not in col shape
		if (owner==playerid and TowingReturn == 0) or (exports.global:hasItem(source, 3, dbid)) or (TowingReturn == 2) or (exports.integration:isPlayerTrialAdmin(source) and exports.logs:logMessage("[AVEHPOS] " .. getPlayerName( source ) .. " parked car #" .. dbid .. " at " .. x .. ", " .. y .. ", " .. z, 9)) then
			if (dbid<0) then
				outputChatBox("This vehicle is not permanently spawned.", source, 255, 0, 0)
			else
				if (call(getResourceFromName("tow-system"), "CanTowTruckDriverGetPaid", source)) then
					-- pd has to pay for this impound
					exports.global:giveMoney(getTeamFromName("326 Enterprises"), 75)
					exports.global:takeMoney(getTeamFromName("Los Santos Police Department"), 75)
				end
				exports.anticheat:changeProtectedElementDataEx(veh, "requires.vehpos")
				local rx, ry, rz = getVehicleRotation(veh)

				local interior = getElementInterior(source)
				local dimension = getElementDimension(source)

				local query = mysql:query_free("UPDATE vehicles SET x='" .. mysql:escape_string(x) .. "', y='" .. mysql:escape_string(y) .."', z='" .. mysql:escape_string(z) .. "', rotx='" .. mysql:escape_string(rx) .. "', roty='" .. mysql:escape_string(ry) .. "', rotz='" .. mysql:escape_string(rz) .. "', currx='" .. mysql:escape_string(x) .. "', curry='" .. mysql:escape_string(y) .. "', currz='" .. mysql:escape_string(z) .. "', currrx='" .. mysql:escape_string(rx) .. "', currry='" .. mysql:escape_string(ry) .. "', currrz='" .. mysql:escape_string(rz) .. "', interior='" .. mysql:escape_string(interior) .. "', currinterior='" .. mysql:escape_string(interior) .. "', dimension='" .. mysql:escape_string(dimension) .. "', currdimension='" .. mysql:escape_string(dimension) .. "' WHERE id='" .. mysql:escape_string(dbid) .. "'")
				setVehicleRespawnPosition(veh, x, y, z, rx, ry, rz)
				exports.anticheat:changeProtectedElementDataEx(veh, "respawnposition", {x, y, z, rx, ry, rz}, false)
				exports.anticheat:changeProtectedElementDataEx(veh, "interior", interior)
				exports.anticheat:changeProtectedElementDataEx(veh, "dimension", dimension)
				outputChatBox("Vehicle spawn position set.", source)
				exports.logs:dbLog(thePlayer, 4, {  veh }, "PARK")
				for key, value in ipairs(destroyTimers) do
					if (tonumber(destroyTimers[key][2]) == dbid) then
						local timer = destroyTimers[key][1]

						if (isTimer(timer)) then
							killTimer(timer)
							table.remove(destroyTimers, key)
						end
					end
				end

				if ( getElementData(veh, "Impounded") or 0 ) > 0 then
					local owner = getPlayerFromName( exports['cache']:getCharacterName( getElementData( veh, "owner" ) ) )
					if isElement( owner ) and exports.global:hasItem( owner, 2 ) then
						outputChatBox("((SFT&R)) #5555 [SMS]: Your " .. getVehicleName(veh) .. " has been impounded. Head over to the impound to release it.", owner, 120, 255, 80)
					end
				end
			end
		else
			outputChatBox( "You can't park this vehicle.", source, 255, 0, 0 )
		end
	end
end
addEvent( "parkVehicle", true )
addEventHandler( "parkVehicle", getRootElement( ), setVehiclePosition3 )

function setVehiclePosition4(thePlayer, commandName)
	local veh = getPedOccupiedVehicle(thePlayer)
	if not veh or getElementData(thePlayer, "realinvehicle") == 0 then
		outputChatBox("You are not in a vehicle.", thePlayer, 255, 0, 0)
	else
		local playerid = getElementData(thePlayer, "dbid")
		local playerfl = getElementData(thePlayer, "factionleader")
		local playerfid = getElementData(thePlayer, "faction")
		local owner = getElementData(veh, "owner")
		local dbid = getElementData(veh, "dbid")
		local carfid = getElementData(veh, "faction")
		if (playerfl == 1) and (playerfid==carfid) then
			exports.anticheat:changeProtectedElementDataEx(veh, "requires.vehpos")

			local x, y, z = getElementPosition(veh)
			local rx, ry, rz = getVehicleRotation(veh)

			local interior = getElementInterior(thePlayer)
			local dimension = getElementDimension(thePlayer)

			local query = mysql:query_free("UPDATE vehicles SET x='" .. mysql:escape_string(x) .. "', y='" .. mysql:escape_string(y) .."', z='" .. mysql:escape_string(z) .. "', rotx='" .. mysql:escape_string(rx) .. "', roty='" .. mysql:escape_string(ry) .. "', rotz='" .. mysql:escape_string(rz) .. "', currx='" .. mysql:escape_string(x) .. "', curry='" .. mysql:escape_string(y) .. "', currz='" .. mysql:escape_string(z) .. "', currrx='" .. mysql:escape_string(rx) .. "', currry='" .. mysql:escape_string(ry) .. "', currrz='" .. mysql:escape_string(rz) .. "', interior='" .. mysql:escape_string(interior) .. "', currinterior='" .. mysql:escape_string(interior) .. "', dimension='" .. mysql:escape_string(dimension) .. "', currdimension='" .. mysql:escape_string(dimension) .. "' WHERE id='" .. mysql:escape_string(dbid) .. "'")
			setVehicleRespawnPosition(veh, x, y, z, rx, ry, rz)
			exports.anticheat:changeProtectedElementDataEx(veh, "respawnposition", {x, y, z, rx, ry, rz}, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "interior", interior)
			exports.anticheat:changeProtectedElementDataEx(veh, "dimension", dimension)
			outputChatBox("Vehicle spawn position for #" .. dbid .. " set.", thePlayer)
			exports.logs:dbLog(thePlayer, 4, {  veh }, "PARK")

			local adminID = getElementData(thePlayer, "account:id")
			local addLog = mysql:query_free("INSERT INTO `vehicle_logs` (`vehID`, `action`, `actor`) VALUES ('"..tostring(dbid).."', '"..commandName.."', '"..adminID.."')") or false
			if not addLog then
				outputDebugString("Failed to add vehicle logs.")
			end

			for key, value in ipairs(destroyTimers) do
				if (tonumber(destroyTimers[key][2]) == dbid) then
					local timer = destroyTimers[key][1]

					if (isTimer(timer)) then
						killTimer(timer)
						table.remove(destroyTimers, key)
					end
				end
			end

			if ( getElementData(veh, "Impounded") or 0 ) > 0 then
				local owner = getPlayerFromName( exports['cache']:getCharacterName( getElementData( veh, "owner" ) ) )
				if isElement( owner ) and exports.global:hasItem( owner, 2 ) then
					outputChatBox("((SFT&R)) #5555 [SMS]: Your " .. getVehicleName(veh) .. " has been impounded. Head over to the impound to release it.", owner, 120, 255, 80)
				end
			end
		end
	end
end
addCommandHandler("fvehpos", setVehiclePosition4, false, false)
addCommandHandler("fpark", setVehiclePosition4, false, false)

function quitPlayer ( quitReason )
	if (quitReason == "Timed out") then -- if timed out
		if (isPedInVehicle(source)) then -- if in vehicle
			local vehicleSeat = getPedOccupiedVehicleSeat(source)
			if (vehicleSeat == 0) then	-- is in driver seat?
				local theVehicle = getPedOccupiedVehicle(source)
				local dbid = tonumber(getElementData(theVehicle, "dbid"))
				--------------------------------------------
				--Take the player's key / Crash fix -> Done by Anthony
				if exports.global:hasItem(theVehicle, 3, dbid) then
					exports.global:takeItem(theVehicle, 3, dbid)
					exports.global:giveItem(source, 3, dbid)
				end
				--------------------------------------------
				local passenger1 = getVehicleOccupant( theVehicle , 1 )
				local passenger2 = getVehicleOccupant( theVehicle , 2 )
				local passenger3 = getVehicleOccupant( theVehicle , 3 )
				if not (passenger1) and not (passenger2) and not (passenger3) then
					local vehicleFaction = tonumber(getElementData(theVehicle, "faction"))
					local playerFaction = tonumber(getElementData(source, "faction"))
					if exports.global:hasItem(source, 3, dbid) or ((playerFaction == vehicleFaction) and (vehicleFaction ~= -1)) then
						if not isVehicleLocked(theVehicle) then -- check if the vehicle aint locked already
							lockUnlockOutside(theVehicle)
							exports.logs:dbLog(thePlayer, 31, {  theVehicle }, "LOCK FROM CRASH")
						end
						local engine = getElementData(theVehicle, "engine")
						if engine == 1 then -- stop the engine when its running
							setVehicleEngineState(theVehicle, false)
							exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, false)
						end
					end
					exports.anticheat:changeProtectedElementDataEx(theVehicle, "handbrake", 1, false)
					setElementVelocity(theVehicle, 0, 0, 0)
					setElementFrozen(theVehicle, true)
				end
			end
		end
	end
end
addEventHandler("onPlayerQuit",getRootElement(), quitPlayer)

function detachVehicle(thePlayer)
	if isPedInVehicle(thePlayer) and getPedOccupiedVehicleSeat(thePlayer) == 0 then
		local veh = getPedOccupiedVehicle(thePlayer)
		if getVehicleTowedByVehicle(veh) then
			detachTrailerFromVehicle(veh)
			outputChatBox("The trailer was detached.", thePlayer, 0, 255, 0)
		else
			outputChatBox("There is no trailer...", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("detach", detachVehicle)

safeTable = {}

function addSafe( dbid, x, y, z, rz, interior )
	local tempobject = createObject(2332, x, y, z, 0, 0, rz)
	setElementInterior(tempobject, interior)
	setElementDimension(tempobject, dbid + 20000)
	safeTable[dbid] = tempobject
end

function removeSafe( dbid )
	if safeTable[dbid] then
		destroyElement(safeTable[dbid])
		safeTable[dbid] = nil
	end
end

function getSafe( dbid )
	return safeTable[dbid]
end
