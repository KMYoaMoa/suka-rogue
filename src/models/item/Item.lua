-- Compatibility path: item definitions live in content/items and runtime
-- behavior lives in modules/items.
local Item = require "modules.items.Item"
local Rules = require "modules.items.rules"
Item.behavior = Rules.behavior
return Item
