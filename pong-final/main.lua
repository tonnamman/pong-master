-- main.lua

-- Load external libraries
Class = require 'class'
push = require 'push'

-- Load game objects
require 'Ball'
require 'Paddle'

-- Screen settings
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- Paddle settings
PADDLE_SPEED = 200

-- Tilemap settings
TILE_SIZE = 16
TILE_ROWS = math.floor(VIRTUAL_HEIGHT / TILE_SIZE)
TILE_COLS = math.floor(VIRTUAL_WIDTH / TILE_SIZE)

tilemap = {}

-- Score settings
player1Score = 0
player2Score = 0

-- Initialize game state
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong with Tilemap')

    -- Seed random generator
    math.randomseed(os.time())

    -- Initialize tilemap with random obstacles
    for y = 1, TILE_ROWS do
        tilemap[y] = {}
        for x = 1, TILE_COLS do
            tilemap[y][x] = math.random() < 0.1 and 1 or 0 -- 10% chance for an obstacle
        end
    end

    -- Ensure no obstacles near paddles
    for y = 1, TILE_ROWS do
        tilemap[y][1] = 0
        tilemap[y][TILE_COLS] = 0
    end

    -- Setup virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })

    -- Initialize paddles and ball
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 50, 5, 20)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- Game state variables
    gameState = 'start'
end

-- Update game objects
function love.update(dt)
    -- Player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- Player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- Update paddles
    player1:update(dt)
    player2:update(dt)

    -- Update ball
    if gameState == 'play' then
        ball:update(dt)

        -- Ball collision with paddles
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + player1.width

            -- Adjust ball direction based on paddle movement
            if player1.dy < 0 then
                ball.dy = ball.dy - 10
            elseif player1.dy > 0 then
                ball.dy = ball.dy + 10
            end
        end

        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - ball.width

            -- Adjust ball direction based on paddle movement
            if player2.dy < 0 then
                ball.dy = ball.dy - 10
            elseif player2.dy > 0 then
                ball.dy = ball.dy + 10
            end
        end

        -- Ball collision with screen bounds
        if ball.y <= 0 or ball.y >= VIRTUAL_HEIGHT - ball.height then
            ball.dy = -ball.dy
        end

        -- Scoring logic
        if ball.x < 0 then
            player2Score = player2Score + 1
            ball:reset()
            gameState = 'start'
        end

        if ball.x > VIRTUAL_WIDTH then
            player1Score = player1Score + 1
            ball:reset()
            gameState = 'start'
        end
    end

    -- Ball collision with tiles
    local tileX = math.floor(ball.x / TILE_SIZE) + 1
    local tileY = math.floor(ball.y / TILE_SIZE) + 1

    if tilemap[tileY] and tilemap[tileY][tileX] == 1 then
        ball.dx = -ball.dx -- Reverse ball direction
        tilemap[tileY][tileX] = 0 -- Remove the tile
    end
end

-- Render game objects
function love.draw()
    push:apply('start')

    -- Clear screen with black
    love.graphics.clear(0, 0, 0, 1)

    -- Draw tilemap
    for y = 1, TILE_ROWS do
        for x = 1, TILE_COLS do
            if tilemap[y][x] == 1 then
                love.graphics.setColor(1, 1, 1, 1) -- White color for tiles
                love.graphics.rectangle('fill', (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, TILE_SIZE, TILE_SIZE)
            end
        end
    end

    -- Draw paddles and ball
    love.graphics.setColor(1, 1, 1, 1) -- White color for paddles and ball
    player1:render()
    player2:render()
    ball:render()

    -- Draw score
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf(tostring(player1Score) .. ' - ' .. tostring(player2Score), 0, 10, VIRTUAL_WIDTH, 'center')

    push:apply('end')
end

-- Key press handler
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'play'

            -- Start ball movement
            ball.dx = math.random(2) == 1 and 100 or -100
            ball.dy = math.random(-50, 50)
        else
            gameState = 'start'

            -- Reset ball
            ball:reset()
        end
    end
end
