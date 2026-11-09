local t = require "tests.support"
local Game = require "game.Game"
local Items = require "modules.items"
local World = require "game.World"
local Player = require "modules.player.Player"

t.test("items module exposes content-backed instances, tags, and behavior", function ()
    local game = Game.new(771)
    game:init()
    local Item = Items.Item
    local Rules = Items.Rules

    local sword = Item.new("sword")
    t.equal(sword.type, "Rusty Sword")
    t.truthy(Item.is_equippable(sword))
    t.falsy(Item.is_usable(sword))
    t.falsy(Item.is_stackable(sword))

    Rules.behavior(sword).equip(sword, Player)
    t.equal(Player.equipped.melee, sword)

    local medkit = Item.new("medkit")
    t.truthy(Item.is_usable(medkit))
    t.truthy(Item.is_stackable(medkit))
    Player.health = 50
    Rules.behavior(medkit).use(medkit, Player)
    t.equal(Player.health, 80)
end)

t.test("World owns ground item placement and retrieval", function ()
    local game = Game.new(772)
    game:init()
    local item = Items.Item.new("coin")
    World.place_item(item, 12, 12)
    local entries = World.items_at(12, 12)
    t.equal(#entries, 1)
    t.equal(entries[1].item, item)

    local taken = World.take_items_at(12, 12)
    t.equal(#taken, 1)
    t.equal(#World.items_at(12, 12), 0)
end)
