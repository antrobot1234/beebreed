local beebreed = require("beebreed")
local fs = require("filesystem")
local component = require("component")
local term = require("term")

local apiary = component.proxy(component.list("tile_for_apiculture_0_name")() or component.list("for_alveary_0")())

local function getInput()
    term.write("> ")
    return io.read()
end

local function printMutation(mutation)
    print("- " .. mutation.allele1.name)
    print("- " .. mutation.allele2.name)
    print("Chance: " .. tostring(mutation.chance))

    local special = mutation.specialConditions
    for i = 1, special.n do
        print("Extra: " .. special[i])
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
    
        if possible.n ~= 0 then
            mutations = possible
        else
            print("There is no mutation that results in this bee.")
            print("Would you like to set it as the target anyway? (y/n)")
            skipMutation = getConfirmation()
        end
    end
    
    print("")
    
    local selected = nil
    while selected == nil and not skipMutation do
        for i = 1, mutations.n do
            printMutation(mutations[i])
            print("(" .. tostring(i) .. "/" .. tostring(mutations.n) .. ")")
            print("")
            print("Is this the mutation you want? (y/n)")
            if getConfirmation() then
                selected = mutations[i]
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

local selected, result = getTargetMutation()

print("")
local mutation = {
    [1] = selected.allele1.name:lower(),
    [2] = selected.allele2.name:lower(),
    result = result:lower(),
    chance = selected.chance / 100.0
}

local traitValues = {
    speed = 2.0,
    fert = 1.5,
    cave = 1.0,
    rain = 1.0,
    night = 1.5,
    flowering = 0.5,
    total = 0.001,
    effect = {
        none = 0.0,
        aggressive = -1.0,
        ends = -2.0,
        poison = -1.0,
        beatific = 1.0,
        heroic = 1.5,
        recharging = 1.5,
        ravening = -1.0,
        empowering = 2.5,
        magnification = 2.0,
        purifying = 2.5,
        transmuting = 1.0
    },
    flowers = {
        flowers = 1.0,
        ["end"] = -2.0
    }
}

beebreed.mainLoop(mutation, traitValues)