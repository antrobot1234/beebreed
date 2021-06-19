local component = require("component")
local fs = require("filesystem")
local genetics = require("genetics")

local transposer = component.transposer
local apiary = component.proxy(component.list("tile_for_apiculture_0_name")() or component.list("for_alveary_0")())


local chest_inv = 2
local apiary_inv = 3


local beebreed = {}

local max_wait_time = 240

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
            local score
            score = genetics.individualTotalScore(princess, bee, mutation, values)
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
    while true do
        os.sleep(5)
        local queen = apiary.getQueen()
        if queen == nil then
            print("Queen or princess not found. Waiting...")
            for i = 1, max_wait_time do
                os.sleep(1)
                queen = apiary.getQueen()
                if queen ~= nil then break end
            end

            if queen == nil then
                print("Queen not found after " .. tostring(max_wait_time) .. " seconds. Aborting...")
                break
            end

            print("Cycle completed. Searching for the best drone...")
            local best, score, genome = compareDrones(queen, mutation, values)
            transposer.transferItem(chest_inv, apiary_inv, 1, best)
            print("Best drone found with a score of " .. tostring(score) .. ". A new cycle begins.")

            if genetics.areGenesEqual(genome, queen) then
                sameStreak = sameStreak + 1
            else
                sameStreak = 0
            end

            if sameStreak > 2 then
                print("Stabilized.")
            end

            print("")
        end
    end
end

return beebreed