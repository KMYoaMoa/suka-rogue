local t = require "tests.support"
local Cell = require "models.dungeon.Cell"
local Item = require "models.item.Item"
local Player = require "models.Player"
local Dungeon = require "models.dungeon.Dungeon"
local GameState = require "models.GameState"
local DungeonService = require "services.DungeonService"
local PlayerService = require "services.PlayerService"
local InventoryService = require "services.InventoryService"
local CommandService = require "services.CommandService"
local MessageService = require "services.MessageService"
local CombatService = require "services.CombatService"
local MobService = require "services.MobService"

t.test("pickup, equip, use, and drop update inventory and ground items", function ()
    t.with_clean_world(function ()
        local room = t.make_room(10, 10, 7, 7)
        Player.x, Player.y = 13, 13
        local ground_medkit = Item.new("medkit")
        InventoryService.place_item(ground_medkit, Player.x, Player.y)
        PlayerService.pickup()
        GameState.state = "running"
        CommandService.process()
        t.equal(#Player.inventory, 1)
        t.equal(Player.inventory[1], ground_medkit)
        t.equal(#Dungeon.items, 0)

        Player.inventory[#Player.inventory + 1] = Item.new("sword")
        t.truthy(PlayerService.equip(2))
        GameState.state = "running"
        CommandService.process()
        t.equal(Player.equipped.melee.type, "Rusty Sword")
        t.equal(#Player.inventory, 1) -- medkit remains

        Player.health = 50
        t.truthy(PlayerService.use(1))
        GameState.state = "running"
        CommandService.process()
        t.equal(Player.health, 80)
        t.equal(#Player.inventory, 0)

        Player.inventory[1] = Item.new("coin")
        t.truthy(PlayerService.drop(1))
        GameState.state = "running"
        CommandService.process()
        t.equal(#Player.inventory, 0)
        t.equal(#InventoryService.items_at(Player.x, Player.y), 1)
    end)
end)

t.test("model-derived mob stats and combat damage/death/drop behavior", function ()
    t.with_clean_world(function ()
        local Mob = require "models.mob.Mob"
        local room = t.make_room(10, 10, 7, 7)
        Player.x, Player.y = 13, 13
        local mob = MobService.spawn("scavenger", 14, 13, room)
        t.truthy(mob)
        t.equal(Mob.attack_of(mob), 16)
        t.equal(Mob.defense_of(mob), 9)

        mob.health = 1
        CombatService.hit(mob, 1)
        t.equal(mob.dead, true)
        t.equal(#Dungeon.mobs, 0)
        t.equal(#Dungeon.items, 2)
    end)
end)

t.test("player damage drains ARM before HP and death stops the game", function ()
    t.with_clean_world(function ()
        local PlayerStatsService = require "services.PlayerStatsService"
        Player.armor = 3
        Player.health = 10
        PlayerStatsService.apply_damage(5, "test")
        t.equal(Player.armor, 0)
        t.equal(Player.health, 8)
        t.equal(GameState.state, "waiting")

        Player.health = 1
        Player.armor = 0
        PlayerStatsService.apply_damage(2, "test")
        t.equal(Player.health, 0)
        t.equal(GameState.state, "dead")
        t.truthy(#MessageService.recent() > 0)
    end)
end)

t.test("mob acts on its configured scheduler cadence and pursues without overlapping player", function ()
    t.with_clean_world(function ()
        local VisionService = require "services.VisionService"
        local room = t.make_room(10, 10, 7, 7)
        Player.x, Player.y = 13, 13
        local mob = MobService.spawn("unknown", 16, 13, room) -- speed 1
        t.truthy(mob)
        VisionService.update()

        GameState.state = "running"
        CommandService.process()
        t.equal(mob.x, 15)
        t.equal(mob.y, 13)
        t.equal(Player.armor, 100)

        GameState.state = "running"
        CommandService.process()
        t.equal(mob.x, 14)
        t.equal(Player.armor, 100)

        GameState.state = "running"
        CommandService.process()
        t.equal(mob.x, 14) -- adjacent; attacks instead of stepping onto player
        t.equal(Player.armor, 99)
        t.equal(DungeonService.occupant_at(Player.x, Player.y), Player)
    end)
end)
