local Player = {}

Player.armor = 100
Player.armor_max = 100
Player.health = 100
Player.health_max = 100
Player.magic = 100
Player.magic_max = 100

Player.inventory = {}
Player.equipped  = { weapon = nil, armor = nil }       -- the player HAS equipment

return Player