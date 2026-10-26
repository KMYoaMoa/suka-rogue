local Player         = require "models.Player"
local GameState      = require "models.GameState"
local MessageService = require "services.MessageService"

local PlayerStatsService = {}

PlayerStatsService.get_defense = function ()
    local armor = Player.equipped.armor
    return (armor and armor.def.stats.defense) or 0
end

-- Mob attacks always hit. Damage is reduced by the equipped armor's defense,
-- absorbed by the ARM shield first, and only the remainder hits HP.
PlayerStatsService.apply_damage = function (attack, source_name)
    local damage = math.max(1, attack - PlayerStatsService.get_defense())

    local absorbed = math.min(Player.armor, damage)
    Player.armor = Player.armor - absorbed
    local hp_damage = damage - absorbed
    Player.health = math.max(0, Player.health - hp_damage)

    MessageService.add(string.format(
        "The %s hits you for %d (ARM %d/%d, HP %d/%d).",
        source_name, damage, Player.armor, Player.armor_max,
        Player.health, Player.health_max), "combat")

    if Player.health <= 0 then
        GameState.state = "dead"
        MessageService.add("You die.", "bad")
    end
end

return PlayerStatsService
