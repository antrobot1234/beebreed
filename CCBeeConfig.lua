local config = {
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
        rocks = 2.0,
        flowers = 1.0,
        ["end"] = -2.0
    },
	apiaryDir = "south",
	analyzerDir = "north"
}

return config
