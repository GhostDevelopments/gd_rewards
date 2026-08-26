Config = {
    -- The cooldown starts when an item is successfully claimed.
    CooldownSeconds = 24 * 60 * 60,
    DatabaseTable = "reward_menu_claims",
    CommandMale = "malerewards",
    CommandFemale = "femalerewards",
    MenuTitle = "Daily Character Rewards",
    MenuSubtitle = "Claim individual rewards or collect the full daily allocation",
    ClaimAllLabel = "CLAIM ALL REWARDS",

    -- Qbox character gender convention: 0 = male, 1 = female.
    RewardSets = {
        male = {
            title = "Male Collection",
            accent = "#5eead4",
            items = {
                {
                    name = "water",
                    label = "Mineral Water",
                    description = "A refreshing bottle for the road.",
                    amount = 2,
                    image = "nui://ox_inventory/web/images/water.png",
                },
                {
                    name = "sandwich",
                    label = "Club Sandwich",
                    description = "A quick meal for a long shift.",
                    amount = 2,
                    image = "nui://ox_inventory/web/images/sandwich.png",
                },
                {
                    name = "bandage",
                    label = "Field Bandage",
                    description = "Useful emergency medical supplies.",
                    amount = 3,
                    image = "nui://ox_inventory/web/images/bandage.png",
                },
            },
        },
        female = {
            title = "Female Collection",
            accent = "#f9a8d4",
            items = {
                {
                    name = "water",
                    label = "Mineral Water",
                    description = "A refreshing bottle for the road.",
                    amount = 2,
                    image = "nui://ox_inventory/web/images/water.png",
                },
                {
                    name = "coffee",
                    label = "Fresh Coffee",
                    description = "A warm boost before your next job.",
                    amount = 2,
                    image = "nui://ox_inventory/web/images/coffee.png",
                },
                {
                    name = "bandage",
                    label = "Field Bandage",
                    description = "Useful emergency medical supplies.",
                    amount = 3,
                    image = "nui://ox_inventory/web/images/bandage.png",
                },
            },
        },
    },
}
