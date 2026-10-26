local GameState = {}

GameState.ticks  = 0
GameState.state = "waiting"   -- "waiting" | "running" | "inventory" | "dead"
GameState.selected_slot = nil  -- inventory slot highlighted while the list is open

return GameState