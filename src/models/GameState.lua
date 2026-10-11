local GameState = {}

GameState.ticks  = 0
GameState.state = "waiting"   -- "waiting" (player input) | "running" (command queue draining) | "inventory" (list open)
GameState.selected_slot = nil  -- inventory slot highlighted while the list is open

return GameState