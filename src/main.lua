local GameApplication = require "GameApplication"
local CameraView = require "views.CameraView"
local MessageView = require "views.MessageView"
local PlayerStatusView = require "views.PlayerStatusView"
local InventoryView    = require "views.InventoryView"

function love.load()
    math.randomseed(os.time())

    love.window.setTitle("Love RL")
    love.window.setMode(1280, 720)
    love.keyboard.setKeyRepeat(true)

    GameApplication.init()
end

function love.draw()
    CameraView.render()
    MessageView.render()
    PlayerStatusView.render()
    InventoryView.render()
end

function love.keypressed(key)
    GameApplication.handle_key_press(key)
end
