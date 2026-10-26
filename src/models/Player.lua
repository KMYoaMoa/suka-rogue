local Player = {}

Player.armor = 100
Player.armor_max = 100
Player.health = 100
Player.health_max = 100
Player.magic = 100
Player.magic_max = 100

-- Combat
Player.attack        = 3      -- base attack used by every mode
Player.unarmed_range = 1      -- body range (4-direction BFS steps)
Player.mode          = "unarmed"   -- "unarmed" | "melee" | "ranged"

Player.inventory = {}
Player.equipped  = { melee = nil, ranged = nil, armor = nil }  -- the player HAS equipment

return Player