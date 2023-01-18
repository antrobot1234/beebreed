
local apiary = peripheral.find("tile_for_apiculture_0_name") or peripheral.find("for_alveary_0") or peripheral.find("magicBees_magicapiary") --component does not exist in CC. use peripherals

local function getInput()
    term.write("> ")
    return io.read()
end

local function printMutation(mutation)
    print("- " .. mutation.allele1.name)
    print("- " .. mutation.allele2.name)
    print("Chance: " .. tostring(mutation.chance))

    local special = mutation.specialConditions
    for k, v in pairs(special) do
        print("Extra: " .. v[i])
    end
end

local function getConfirmation()
    local confirmation = getInput()
    if confirmation:lower():sub(1, 1) == "y" then
        return true
    end
    return false
end

local function getTargetMutation()
    local skipMutation = false

    local mutations = nil
    local result = nil
    while mutations == nil and not skipMutation do
        print("What bee would you like to breed?")
        result = getInput()
        local possible = apiary.getBeeParents(result)
        if next(possible) ~= nil then
            mutations = possible
        else
            print("There is no mutation that results in this bee.")
            print("Would you like to set it as the target anyway? (y/n)")
            skipMutation = getConfirmation()
        end
    end
    
    local selected = nil
    while selected == nil and not skipMutation do
        for k,v in pairs(mutations) do
            printMutation(v)
            print("(" .. tostring(i).. ")")
            print("")
            print("Is this the mutation you want? (y/n)")
            if getConfirmation() then
                selected = v
                break
            end
        end
        if selected == nil then
            print("")
            print("There are no other mutations that result in this bee.")
            print("Would you like to target it without a mutation? (y/n)")
            skipMutation = getConfirmation()
        end
    end

    if skipMutation then
        selected = {
            allele1 = {
                name = "n/a"
            },
            allele2 = {
                name = "n/a"
            },
            chance = 0.0
        }
    end

    return selected, result
end

-- script runs here
local selected, result = getTargetMutation()

print("")
local mutation = {
    [1] = selected.allele1.name:lower(),
    [2] = selected.allele2.name:lower(),
    result = result:lower(),
    chance = selected.chance / 100.0
}
beebreed = dofile("CCBreed")
config = dofile("CCBeeConfig")
beebreed.mainLoop(mutation, config)
