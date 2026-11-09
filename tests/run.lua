package.path = "./src/?.lua;./src/?/init.lua;./tests/?.lua;" .. package.path

local files = {
    "tests.test_lifecycle_turns",
    "tests.test_space_generation",
    "tests.test_inventory_combat",
    "tests.test_game_instances",
    "tests.test_player_module",
    "tests.test_core",
}

for _, file in ipairs(files) do
    require(file)
end

print("All baseline tests passed.")
