local component = require("component")
local fs = require("filesystem")
local genetics = require("genetics")
local ev = require("event")

local transposer = component.transposer
local apiary = component.proxy(component.list("tile_for_apiculture_0_name")() or component.list("for_alveary_0")() or
                                   component.list("magicBees_magicapiary")())

local function getChestSide()
    for i = 0, 5, 1 do
        local name = transposer.getInventoryName(i)
        if name == "tile.chest" or name == "tile.for.apicultureChest" then
            return i
        end
    end
end
local function getApiarySide()
    for i = 0, 5, 1 do
        local name = transposer.getInventoryName(i)
        if name == "tile.for.apiculture" or name == "tile.for.alveary" or name == "tile.magicApiary" then
            return i
        end
    end
end
local function getAnalyzerSide()
    for i = 0, 5, 1 do
        local name = transposer.getInventoryName(i)
        if name == "tile.for.core" then
            return i
        end
    end
    return nil
end

local chest_inv = getChestSide()
local apiary_inv = getApiarySide()
local analyzer_inv = getAnalyzerSide()

local beebreed = {}

local max_wait_time = 240

local function findItemName(side, iname, rangemin, rangemax)
    local cont = transposer
    local rmax = rangemax or transposer.getInventorySize(side)
    local rmin = rangemin or 1
    for i = rmin, rmax, 1 do
        if transposer.getSlotStackSize(side, i) ~= 0 then
            local name = cont.getStackInSlot(side, i).name
            if name == iname then
                return i
            end
        end
    end
    return nil
end

local function getBeeSlot(side, rangemin, rangemax)
    local princessSlot = findItemName(side, "Forestry:beePrincessGE", rangemin, rangemax)
    local droneSlot = findItemName(side, "Forestry:beeDroneGE", rangemin, rangemax)
    if princessSlot and droneSlot then
        return math.min(princessSlot, droneSlot)
    else
        return princessSlot or droneSlot
    end
end
local function moveItemToSlotRange(inSide, inSlot, outSide, outMin, outMax)
    local oMin = outMin or 1
    local oMax = outMax or transposer.getInventorySize(outSide)
    for i = oMin, oMax, 1 do
        if transposer.transferItem(inSide, outSide, transposer.getSlotStackSize(inSide, inSlot), inSlot, i) ~= 0 then
            return true
        end
    end
    return false
end

local function compareDrones(princess, mutation, values)
    local best_bee = -1
    local best_bee_score = -1
    local best_bee_genome = nil
    local iter = transposer.getAllStacks(chest_inv)

    local i = 0
    for drone in iter do
        i = i + 1
        local bee = drone.individual

        if bee ~= nil then
            local score = nil
            while score == nil do
                score = genetics.individualTotalScore(princess, bee, mutation, values)
                if score == nil then
                    print("press any key to continue...")
                    ev.pull("key_down")
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

local sameStreak = 0

function beebreed.mainLoop(mutation, values)
    local first = true
    while true do
        local queen = apiary.getQueen()
        if queen == nil or first then
            if first then
                first = false
            else
                print("Queen or princess not found. Searching in apiary...")
            end
            local beeSlot = getBeeSlot(apiary_inv, 3, 9)
            if beeSlot then
                print("bees found in apiary output. ")
                if analyzer_inv then
                    print("exporting to connected analyzer.\n")
                else
                    print("take bees out of apiary, analyze them, place drones in working chest, and finally put princess in apiary.\n")
                end
            end
            while beeSlot do
                if analyzer_inv then
                    print(analyzer_inv)
                    moveItemToSlotRange(apiary_inv, getBeeSlot(apiary_inv, 3, 9), analyzer_inv, 3, 8)
                else
                    os.sleep(5)
                end
                beeSlot = getBeeSlot(apiary_inv, 3, 9)
            end
            if analyzer_inv then
                local hasBee = getBeeSlot(analyzer_inv)
                while hasBee do
                    local tankLevel = transposer.getTankLevel(analyzer_inv)
                    if tankLevel < 100 then
                        print("honey levels critical. refuel.")
                        while tankLevel < 100 do
                            os.sleep(5) -- gets stuck here if apiary broken (even if replaced)
                            tankLevel = transposer.getTankLevel(analyzer_inv)
                        end
                    end
                    local outBee = getBeeSlot(analyzer_inv, 9, 12)
                    if outBee then
                        local outBeeName = transposer.getStackInSlot(analyzer_inv, outBee).name
                        if outBeeName == "Forestry:beeDroneGE" then
                            moveItemToSlotRange(analyzer_inv, outBee, chest_inv)
                        else
                            transposer.transferItem(analyzer_inv, apiary_inv, 1, outBee, 1)
                        end
                    end
                    hasBee = getBeeSlot(analyzer_inv)
                    if hasBee then
                        os.sleep(5)
                    end
                end
            end
            for i = 1, max_wait_time do
                os.sleep(1)
                queen = apiary.getQueen()
                if queen ~= nil then
                    break
                end
            end

            if queen == nil then
                print("Queen not found after " .. tostring(max_wait_time) .. " seconds. Aborting...")
                break
            end

            print("Cycle completed. Searching for the best drone...")
            local best, score, genome = compareDrones(queen, mutation, values)
            transposer.transferItem(chest_inv, apiary_inv, 1, best)
            if genetics.areGenesEqual(genome, queen) then
                print("the dust has settled. enjoy your new queen!")
                break
            end
            print("Best drone found with a score of " .. tostring(score) .. ". A new cycle begins.")
            print("")
        end
        os.sleep(5)
    end
end

return beebreed
