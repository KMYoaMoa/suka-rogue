local t = require "tests.support"
local Game = require "game.Game"
local PlayerModule = require "modules.player"
local Item = require "models.item.Item"

t.test("player module facade owns the aggregate, inventory, stats, and controller", function ()
    local game = Game.new(551)
    game:init()
    local Player = PlayerModule.Player
    local Inventory = PlayerModule.Inventory
    local Stats = PlayerModule.Stats
    local Controller = PlayerModule.Controller

    t.truthy(PlayerModule.Player == Player)
    t.truthy(PlayerModule.Inventory == Inventory)
    t.truthy(PlayerModule.Stats == Stats)
    t.truthy(PlayerModule.Controller == Controller)

    Inventory.add_item(Item.new("sword"))
    local ok, item = Inventory.equip(1)
    t.truthy(ok)
    t.equal(item.type, "Rusty Sword")
    t.equal(Player.equipped.melee.type, "Rusty Sword")
    t.equal(#Player.inventory, 0)

    Player.armor = 4
    Player.health = 10
    Stats.apply_damage(6, "test")
    t.equal(Player.armor, 0)
    t.equal(Player.health, 8)

    local x, y = Controller.getPosition()
    t.truthy(x ~= nil and y ~= nil)
end)
