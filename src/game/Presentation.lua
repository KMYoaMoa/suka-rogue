-- Read-only presentation facade used by views. It hides active-Game state
-- and module internals from the rendering layer.
local PlayerModule   = require "modules.player"
local Items          = require "modules.items"
local DungeonModule  = require "modules.dungeon"
local VisionService  = require "modules.vision"
local CombatService  = require "modules.combat"
local CommandService = require "services.CommandService"
local World          = require "game.World"
local MessageLog     = require "game.MessageLog"
local GameState      = require "models.GameState"

local Player = PlayerModule.Player
local Presentation = {}

function Presentation.player_position()
    return Player.x, Player.y
end

function Presentation.state()
    return GameState.state
end

function Presentation.selected_slot()
    return GameState.selected_slot
end

function Presentation.status()
    return {
        armor = Player.armor,
        health = Player.health,
        magic = Player.magic,
    }
end

function Presentation.inventory()
    return Player.inventory
end

function Presentation.equipped()
    return Player.equipped
end

function Presentation.tile(x, y)
    return DungeonModule.Service.getTile(x, y)
end

function Presentation.tile_state(tile)
    return VisionService.state_of(tile)
end

function Presentation.tile_color(tile)
    return DungeonModule.Palette.color_for(tile.biome, tile.type) or tile.def.color
end

function Presentation.tile_glyph(tile)
    return tile.def.glyph
end

function Presentation.occupant_at(x, y)
    return World.occupant_at(x, y)
end

function Presentation.occupant_kind(occupant)
    return occupant and occupant.def and occupant.def.kind
end

function Presentation.item_at(x, y)
    local entries = World.items_at(x, y)
    return entries[1] and entries[1].item or nil
end

function Presentation.item_glyph(item)
    return Items.Item.glyph(item)
end

function Presentation.item_color(item)
    return Items.Item.color(item)
end

function Presentation.is_target(x, y)
    return CombatService.is_target(x, y)
end

function Presentation.next_tick()
    if GameState.state == "dead" then return nil end
    return CommandService.next_tick()
end

function Presentation.is_scheduled(invoker, tick)
    return CommandService.is_scheduled(invoker, tick)
end

function Presentation.is_next_actor(occupant, tick)
    return occupant
        and occupant.def
        and occupant.def.kind == "enemy"
        and occupant.invoker
        and CommandService.is_scheduled(occupant.invoker, tick)
        or false
end

function Presentation.messages(n)
    return MessageLog.recent(n)
end

function Presentation.message_color(entry)
    return MessageLog.color_of(entry)
end

return Presentation
