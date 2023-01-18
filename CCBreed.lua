local apiary = peripheral.find("tile_for_apiculture_0_name") or peripheral.find("for_alveary_0") or peripheral.find("magicBees_magicapiary") --component does not exist in CC. use peripherals
local beechest = peripheral.find("tile_for_apiculturechest_0_name") or peripheral.find("chest")
local analyzer = peripheral.find("tile_for_core_0_name")
local isBinnie = false --doing this temporarily because CC sees a binnie analyzer as "peripheral" which isnt helpful at all.

local analyzerSlots = {no={inMin=3,inMax=8,outMin=9,outMax=12},yes={inMin=1,inMax=6,outMin=8,outMax=13}}

local beebreed = {}

local max_wait_time = 240

genetics = dofile("genetics.lua")

local function findItemName(inventory, iname, rangemin, rangemax) --redefined and refined
    local rmax = rangemax or inventory.getInventorySize()
    local rmin = rangemin or 1
	for k, v in pairs(inventory.getAllStacks()) do
		if not (k < rangemin or k > rangemax) then 
			if iname == v.basic().name then return k end
		end
	end
    return nil
end

local function getBeeSlot(side, rangemin, rangemax) --unsure what this is used for. TODO come back to this.
    local princessSlot = findItemName(side, "Forestry:beePrincessGE", rangemin, rangemax)
    local droneSlot = findItemName(side, "Forestry:beeDroneGE", rangemin, rangemax)
    if princessSlot and droneSlot then
        return math.min(princessSlot, droneSlot)
    else
        return princessSlot or droneSlot
    end
end
local function moveItemToSlotRange(inSide, inSlot, outSide, outMin, outMax) --todo improve performance. also probably not neccesary with pipes.
    local oMin = outMin or 1
    local oMax = outMax or transposer.getInventorySize(outSide)
    for i = oMin, oMax, 1 do
        if transposer.transferItem(inSide, outSide, transposer.getSlotStackSize(inSide, inSlot), inSlot, i) ~= 0 then
            return true
        end
    end
    return false
end

local function compareDrones(inventory, princess, mutation, values)
    local best_bee = -1
    local best_bee_score = -1
    local best_bee_genome = nil
    local iter = inventory.getAllStacks()


	for i, item in pairs(iter) do
		
		local bee = drone.individual

        if bee ~= nil then
            local score = nil
            while score == nil do
                score = genetics.individualTotalScore(princess, bee, mutation, values)
                if score == nil then
                    print("press any key to continue...")
                    os.pullEvent("char")
                    score = genetics.individualTotalScore(princess, bee, mutation, values)
                end
            end
            if score > best_bee_score then
                best_bee_score = score
                best_bee = i
                best_bee_genome = bee
            end
		end
	end
    return best_bee, best_bee_score, best_bee_genome
end
local function getBestPair(mutation,config)
	local bestDrone = -1
	local droneGenome = nil
	local bestPrincess = -1
	local princessGenome = nil
	
	local bestScore = -1
	
	eligible = genetics.getEligible(beechest,mutation)
	for iP, princess in pairs(eligible.princesses) do
		for iD, drone in pairs(eligible.drones) do
			local score = genetics.individualTotalScore(princess,drone,mutation,config)
			if score > bestScore then
				bestDrone = iD
				bestPrincess = iP
				bestScore = score
				droneGenome = drone
				princessGenome = princess
			end
		end
	end
	
	return bestDrone, bestPrincess, bestScore, droneGenome, princessGenome
end

local function isBee(item)
	local name = item.basic().name
	return name == "beeDroneGE" or name == "beePrincessGE"
end

local function untilAnalyzerEmpty()
	out = false
	if analyzer.getTankInfo()[1].contents.amount <= 100 then
		print("tank levels critical, please refuel")
		while analyzer.getTankInfo()[1].contents.amount <= 100 do os.sleep(10) end
	end
	while analyzer.hasWork() do
		out = true
		for j=9,12 do analyzer.pushItem("up",j) end
		os.sleep(5)
	end
	didPush = 0
	for j=9,12 do didPush = math.min(didPush,analyzer.pushItem("up",j)) end
	if didPush ~= 0 then out = true end
	if out then os.sleep(5) end
	return out
end
local sameStreak = 0
function beebreed.mainLoop(mutation, config)
while true do
	--step 0.5: make sure that there is no queen already processing
	if apiary.getQueen() ~= nil then
		print("apiary already has princess/queen. waiting until complete")
		while apiary.getQueen() ~= nil do os.sleep(2) end
	end
	--step 1: extract all bees into bee chest (pipe from apiary up to bee chest) and products into product chest (going out in the same direction as the apiary from computer side)
	print("emptying apiary")
	local didBeeExport = false
	for i, item in pairs(apiary.getAllStacks()) do
		if i >=3 and i <= 9 then
			if isBee(item) then apiary.pushItem("up",i)
			didBeeExport = true
			else apiary.pushItem(config.apiaryDir,i) end
		end
	end
	--step 2: analyze all unanalyzed bees in bee chest.
	if didBeeExport then
	print("waiting for pipe...")
	os.sleep(5) --this is so that it waits until the pipe is pushed
	else print("no new bees found in apiary")
	end
	print("analyzing bees")
	local n = 0
	didBeeExport = false
	untilAnalyzerEmpty()
	for i, item in pairs(beechest.getAllStacks()) do
		if not item.single("individual").isAnalyzed then
		if n >= 6 then untilAnalyzerEmpty() 
			n = 0
		end
		didBeeExport = true
		beechest.pushItem(config.analyzerDir,i)
		n = n + 1
		end
	end
	if didBeeExport then
		print("waiting for pipe...")
		os.sleep(5)
	else print("all bees in chest were analyzed") end
	print("final roundup")
	if untilAnalyzerEmpty() then os.sleep(5)
	print("waiting for bees to return to their home")
	end
	
	--step 3: choose best bees for breeding
	print("selecting best pair")
	droneI,princessI,score,droneGenome,princessGenome = getBestPair(mutation,config)
	print("pair ["..tostring(droneI)..","..tostring(princessI).."] found with score "..tostring(score))
	beechest.pushItem(config.apiaryDir,princessI)
	beechest.pushItem(config.apiaryDir,droneI)
	--step 4: breed the bees and wait
	
	while(apiary.breedingProgress() ~= 100) do end
	print("bees are now breeding. an eta will be provided shortly")
	start_time = os.clock()
	current_progress = (100- apiary.breedingProgress())/100
	while current_progress < 1 do
		while current_progress == (100- apiary.breedingProgress())/100 do end
		current_progress = (100- apiary.breedingProgress())/100
		totalElapsed = os.clock() - start_time
		estimated_total_time = totalElapsed / current_progress
		remaining_time = estimated_total_time - totalElapsed
		print(tostring(current_progress*100).."%| "..math.floor(totalElapsed).."/"..math.floor(estimated_total_time))
		print("ETA: " .. math.floor(remaining_time) .. " seconds")
	end
	--step 5: check if the bees have homogonized
	if genetics.areGenesEqual(droneGenome, princessGenome) then
		print("the dust has settled. enjoy your new queen!")
		break
    end
end
end
return beebreed
