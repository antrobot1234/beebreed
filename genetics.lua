local genetics = {}

local function pairMatchesMutation(genome, mate, mutation)
    return (genome.species:lower() == mutation[1] and mate.species:lower() == mutation[2]) or (mate.species:lower() == mutation[1] and genome.species:lower() == mutation[2])
end

local function speciesScore(individual, desired)
    local score = 0
    if individual.active.species:lower() == desired then
        score = score + 0.5
    end
    if individual.inactive.species:lower() == desired then
        score = score + 0.5
    end
    return score
end

local function areAllelesEqual(a, b)
    for k, v in pairs(a.territory) do
        if b.territory[k] ~= v then return false end
    for k, v in pairs(a) do
        if b[k] ~= v then
                if v ~= a.territory then return false end
        end
    end
    return true
end

function genetics.areGenesEqual(a, b)
    if a == nil or b == nil then return false end
    return areAllelesEqual(a.active, b.active) and areAllelesEqual(a.inactive, b.inactive) and areAllelesEqual(a.active,b.inactive) and areAllelesEqual(a.inactive,b.active)
end

function genetics.traitScore(individual, values)
    local speed = values.speed * ((individual.active.speed + individual.inactive.speed) / 2)
    local fertility = values.fert * (-1 + (individual.active.fertility + individual.inactive.fertility) / 2)

    local caveDwelling = 0
    if individual.active.caveDwelling then caveDwelling = values.cave / 2 end
    if individual.inactive.caveDwelling then caveDwelling = caveDwelling + values.cave / 2 end

    local tolerant = 0
    if individual.active.tolerantFlyer then tolerant = values.rain / 2 end
    if individual.inactive.tolerantFlyer then tolerant = tolerant + values.rain / 2 end

    local nocturnal = 0
    if individual.active.nocturnal then nocturnal = values.night / 2 end
    if individual.inactive.nocturnal then nocturnal = nocturnal + values.night / 2 end

    local flowering = values.flowering * (individual.active.flowering + individual.inactive.flowering) / 2

    local effect = ((values.effect[individual.active.effect:lower()] or 0) + (values.effect[individual.inactive.effect:lower()] or 0)) / 2
    local flowers = ((values.flowers[individual.active.flowerProvider:lower()] or 0) + (values.flowers[individual.inactive.flowerProvider:lower()] or 0)) / 2

    return (speed + fertility + caveDwelling + tolerant + nocturnal + flowering + effect + flowers) * values.total
end

function genetics.mutationScore(individual, mate, mutation)
    local score = 0
    local mutationChance = 0
    -- breaks with dominant alleles, since they always appear as active when paired with a recessive allele
    if pairMatchesMutation(individual.active, mate.inactive, mutation) then
        score = score + 0.5 * mutation.chance
        mutationChance = mutationChance + 0.5 * mutation.chance
    end
    if pairMatchesMutation(individual.inactive, mate.active, mutation) then
        score = score + 0.5 * mutation.chance
        mutationChance = mutationChance + 0.5 * mutation.chance
    end
    score = score + (1 - mutationChance) * speciesScore(individual, mutation.result)
    return score
end

function genetics.pairMutationScore(princess, drone, mutation)
    return (genetics.mutationScore(princess, drone, mutation) + genetics.mutationScore(drone, princess, mutation)) / 2
end

function genetics.individualTotalScore(princess, drone, mutation, values)
    if not princess.isAnalyzed then
        print("Princess not analyzed")
        return nil
    end
    if not drone.isAnalyzed then
        print("A drone not analyzed")
        return nil
    end
    local mut = genetics.pairMutationScore(princess, drone, mutation)
    local trait = genetics.traitScore(drone, values)
    return mut + trait
end

function genetics._getOfAlleles(s1, s2)
    return {active = {species = s1}, inactive = {species = s2}}
end

return genetics
