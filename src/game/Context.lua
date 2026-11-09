-- Temporary active-Game context for the incremental refactor.
-- Services still use the legacy module singletons; each Game owns its own
-- state bundle and activation points those modules at that bundle.
local Context = {}

Context.current = nil

return Context
