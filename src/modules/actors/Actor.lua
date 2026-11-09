-- Generic Actor contract helpers. Actors are duck-typed tables with x/y and
-- optional dead; this avoids inheritance between Player/Mob/NPC/Construct.
local Actor = {}

function Actor.is_alive(actor)
    return actor and not actor.dead
end

function Actor.at(actor, x, y)
    return actor and not actor.dead and actor.x == x and actor.y == y
end

return Actor
