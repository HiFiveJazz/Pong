-- Ball Properties

digits = {
	[0] = {{1,1,1},{1,0,1},{1,0,1},{1,0,1},{1,1,1},},
	[1] = {{1,1,0},{0,1,0},{0,1,0},{0,1,0},{1,1,1},},
	[2] = {{1,1,1},{0,0,1},{1,1,1},{1,0,0},{1,1,1},},
	[3] = {{1,1,1},{0,0,1},{1,1,1},{0,0,1},{1,1,1},},
	[4] = {{1,0,1},{1,0,1},{1,1,1},{0,0,1},{0,0,1},},
	[5] = {{1,1,1},{1,0,0},{1,1,1},{0,0,1},{1,1,1},},
	[6] = {{1,1,1},{1,0,0},{1,1,1},{1,0,1},{1,1,1},},
	[7] = {{1,1,1},{0,0,1},{0,0,1},{0,0,1},{0,0,1},},
	[8] = {{1,1,1},{1,0,1},{1,1,1},{1,0,1},{1,1,1},},
	[9] = {{1,1,1},{1,0,1},{1,1,1},{0,0,1},{0,0,1},},
}

left_score     = 0
right_score    = 0
joystick       = nil
joystick_left  = nil
joystick_right = nil

love.mouse.setVisible(false)

function love.load()
	hit_sounds = {
		love.audio.newSource("sound/paddle_hit/variant_1.wav", "static"),
		love.audio.newSource("sound/paddle_hit/variant_2.wav", "static"),
		love.audio.newSource("sound/paddle_hit/variant_3.wav", "static"),
	}

	success_sounds = {
		love.audio.newSource("sound/success/variant_1.wav", "static"),
		love.audio.newSource("sound/success/variant_2.wav", "static"),
		love.audio.newSource("sound/success/variant_3.wav", "static"),
		love.audio.newSource("sound/success/variant_4.wav", "static"),
		love.audio.newSource("sound/success/variant_5.wav", "static"),
	}

	wall_sounds = {
		love.audio.newSource("sound/wall_hit/variant_1.wav", "static"),
		love.audio.newSource("sound/wall_hit/variant_2.wav", "static"),
		love.audio.newSource("sound/wall_hit/variant_3.wav", "static"),
		love.audio.newSource("sound/wall_hit/variant_4.wav", "static"),
	}

	refresh_gamepads()
	get_dimensions()
	BALL_SPEED          = width / 4
	BALL_SIZE           = width / 100
	player_left_height  = height/2
	player_right_height = height/2

	-- Initial Player Positions
	reset_ball_rand()
	spawn_timer         = 5
end

function love.update(dt)
	-- Allows for game to be hot-resizable window!
	get_dimensions()
	BALL_SIZE     = width / 100
	PADDLE_X_SIZE = BALL_SIZE

	-- Score Properties
	DIGIT_SIZE    = BALL_SIZE
	paddle_y_size = 0.07 * height
	paddle_speed = (2/3) * height
	left_paddle_x        = width/80
	right_paddle_x       = width - left_paddle_x - PADDLE_X_SIZE

	-- Ball is waiting to respawn
	if not ball_active then
		spawn_timer = spawn_timer - dt

		if spawn_timer <= 0 then
			ball_active = true
		end
	else
		local previous_ball_x = ball_x
		ball_x = ball_x + ball_dx*dt;
		ball_y = ball_y + ball_dy*dt;

		wall_collision_check(success_sounds, wall_sounds)
		paddle_collision_check(previous_ball_x,hit_sounds)
	end

	-- Controller State determines
	-- what controller layout we use.
	-- See refresh_gamepads() for 
	-- more information
	if controller_state == 2 then
		double_joystick(dt)

	elseif controller_state == 1 then
		single_joystick(dt)
	else
		no_joystick(dt)
	end

	bind_paddles()
end

function love.draw()
	clear_screen()
	draw_ball()
	draw_net()
	draw_paddles()
	-- Left Player's Score
	local score_gap = 2 * DIGIT_SIZE
	local left_score_width = get_score_width(left_score)

	draw_score(
		left_score,
		width/2 - score_gap - left_score_width,
		10
	)
	-- Right Player's Score
	draw_score(
		right_score,
		width/2 + score_gap,
		10
	)
	-- debug_menu()
end

-- When Joystick is added, hot-reload it!
function love.joystickadded(joystick)
	print("Joystick added:", joystick:getName())
	refresh_gamepads()
end

-- When Joystick is removed, hot-reload it!
function love.joystickremoved(joystick)
	print("Joystick removed:", joystick:getName())
	refresh_gamepads()
end

function love.resize(w, h)
	width = w
	height = h
	BALL_SPEED          = width / 4
end

-- Counts the Number of Gamepads 
-- connected that Love2D supports
-- determining how controllers controller
-- the pong game
function refresh_gamepads()
	joysticks = love.joystick.getJoysticks()
	gamepads = {}

	local i = 1

	-- Count the total number of Gamepads
	-- that Love2D supports
	while #gamepads < 2 and i <= #joysticks do
		if joysticks[i]:isGamepad() then
			table.insert(gamepads, joysticks[i])
		end

		i = i + 1
	end

	if #gamepads >= 2 then
		controller_state = 2
		double_decide_players()

	elseif #gamepads == 1 then
		controller_state = 1
		single_decide_players()

	else
		controller_state = 0
	end
end

-- Only Keyboard!
function no_joystick(dt)
	-- Left Keyboard Side, Left Player
	-- Right Keyboard Side, Right Player

	-- Left Player Controls
	if love.keyboard.isDown("w") then
		player_left_height = player_left_height - paddle_speed*dt
	end
	if love.keyboard.isDown("s") then
		player_left_height = player_left_height + paddle_speed*dt
	end

	-- Right Player Controls
	if love.keyboard.isDown("up") or love.keyboard.isDown("k") then
		player_right_height = player_right_height - paddle_speed*dt
	end
	if love.keyboard.isDown("down") or love.keyboard.isDown("j") then
		player_right_height = player_right_height + paddle_speed*dt
	end
end

-- Assign Players to Controller and Keyboard
function single_decide_players()
	-- Randomly determine who gets left and right player
	-- I think that's fair!
	side = love.math.random(0, 1)
	controller = gamepads[1]
end

-- One Controller, One Keyboard!
function single_joystick(dt)
	-- Keyboard Left, Controller Right
	left_stick_y  = controller:getGamepadAxis("lefty")  -- P1 Left Analog Stick
	right_stick_y = controller:getGamepadAxis("righty") -- P1 Right Analog Stick
	if side == 0 then
		-- Keyboard Controls
		if love.keyboard.isDown("w")
		or love.keyboard.isDown("up")
		or love.keyboard.isDown("k") then -- For Vim enjoyers
			player_left_height = player_left_height - paddle_speed*dt
		end
		if love.keyboard.isDown("s")
		or love.keyboard.isDown("down")
		or love.keyboard.isDown("j") then -- For Vim enjoyers
			player_left_height = player_left_height + paddle_speed*dt
		end

		-- Controller Controls
		if controller:isGamepadDown("dpup")
		or (left_stick_y < -0.125)
		or (right_stick_y < -0.125) then
			player_right_height = player_right_height - paddle_speed*dt
		end

		if controller:isGamepadDown("dpdown")
		or (left_stick_y > 0.125)
		or (right_stick_y > 0.125) then
			player_right_height = player_right_height + paddle_speed*dt
		end
	else
		-- Controller Left, Keyboard Right

		-- Controller Controls
		if controller:isGamepadDown("dpup")
		or (left_stick_y < -0.125)
		or (right_stick_y < -0.125) then
			player_left_height = player_left_height - paddle_speed*dt
		end

		if controller:isGamepadDown("dpdown")
		or (left_stick_y > 0.125)
		or (right_stick_y > 0.125) then
			player_left_height = player_left_height + paddle_speed*dt
		end

		-- Keyboard Controls
		if love.keyboard.isDown("w")
		or love.keyboard.isDown("up")
		or love.keyboard.isDown("k") then -- For Vim enjoyers
			player_right_height = player_right_height - paddle_speed*dt
		end
		if love.keyboard.isDown("s")
		or love.keyboard.isDown("down")
		or love.keyboard.isDown("j") then -- For Vim enjoyers
			player_right_height = player_right_height + paddle_speed*dt
		end

	end
end

-- Assigns Players to 2 Joysticks!
function double_decide_players()
	-- Randomly determine who gets left and right player
	-- I think that's fair!
    local random_player = love.math.random(0,1)
	if random_player == 0 then
		player1_controller = gamepads[1]
		player2_controller = gamepads[2]
	else
		player1_controller = gamepads[2]
		player2_controller = gamepads[1]
	end
end

-- Yay, we have two joysticks to play with :) enjoy with a 
-- friend or loved one!
function double_joystick(dt)

	-- Joystick Controls
	-- Player 1 Controls
	player1_left_stick_y  = player1_controller:getGamepadAxis("lefty")   -- P1 Left Analog Stick
	player1_right_stick_y = player1_controller:getGamepadAxis("righty") -- P1 Right Analog Stick

	if player1_controller:isGamepadDown("dpup")
	or (player1_left_stick_y < -0.125)
	or (player1_right_stick_y < -0.125) then
		player_left_height = player_left_height - paddle_speed*dt
	end

	if player1_controller:isGamepadDown("dpdown")
	or (player1_left_stick_y > 0.125)
	or (player1_right_stick_y > 0.125) then
		player_left_height = player_left_height + paddle_speed*dt
	end

	-- Player 2 Controls
	player2_left_stick_y  = player2_controller:getGamepadAxis("lefty")   -- P2 Left Analog Stick
	player2_right_stick_y = player2_controller:getGamepadAxis("righty") -- P2 Right Analog Stick

	if player2_controller:isGamepadDown("dpup")
	or (player2_left_stick_y < -0.125)
	or (player2_right_stick_y < -0.125) then
		player_right_height = player_right_height - paddle_speed*dt
	end

	if player2_controller:isGamepadDown("dpdown")
	or (player2_left_stick_y > 0.125)
	or (player2_right_stick_y > 0.125) then
		player_right_height = player_right_height + paddle_speed*dt
	end
end

function clear_screen()
	love.graphics.clear(67/255, 81/255, 83/255, 1)
end

function draw_net()
	local net_width = BALL_SIZE/2;
	x_position = width/2 - net_width/2;
	local net_height = height/50;
	local i = 0
	while i < height do
		love.graphics.rectangle("fill", x_position, i, net_width, net_height)
		i = i + 2*net_height;
	end
end

function draw_ball()
	-- Update Ball
	ball = love.graphics.rectangle("fill", ball_x, ball_y, BALL_SIZE, BALL_SIZE) 
end

function draw_paddles()
	love.graphics.rectangle("fill", left_paddle_x, player_left_height, PADDLE_X_SIZE, paddle_y_size) -- Left Player 
	love.graphics.rectangle("fill", right_paddle_x, player_right_height, PADDLE_X_SIZE, paddle_y_size) -- Right Player 
end

function draw_score(score,x,y)
	local score_string = tostring(score)
	for i = 1, #score_string do
		local digit_number = tonumber(score_string:sub(i,i))
		local digit = digits[digit_number]

		for cell_y,row in ipairs(digit) do
			for cell_x,cell in ipairs(row) do
				if cell ~= 0 then
					love.graphics.rectangle("fill",
							x+(i-1)*4*DIGIT_SIZE + (cell_x-1)*DIGIT_SIZE,
							y+ (cell_y-1)*DIGIT_SIZE,
							DIGIT_SIZE,
							DIGIT_SIZE
						)
				end
			end
		end
	end
end

function get_dimensions()
	width, height = love.graphics.getDimensions()
end

-- Increases the Speed of the Ball as Players hit the Ball
function rally_speed_increase()
	rally_hits = rally_hits + 1
	speed_multiplier = 1 + 0.30 / (1 + rally_hits / 10)
	ball_dx  = ball_dx * speed_multiplier
	ball_dy  = ball_dy * speed_multiplier
end

-- Resets the Ball, Ball Will Go to a Random Player
function reset_ball_rand()
	rally_hits = 0;
	ball_active = false
	local direction = love.math.random(0, 1)
	if direction == 0 then
		direction = 1
	else
		direction = -1
	end
	local range  = love.math.random()
	ball_x   = (width/2) - BALL_SIZE/2
	ball_y   = (height/2)
	ball_dx  = direction*(width/4)
	ball_dy  = range*(width/4)
end

-- Resets the Ball, Ball Will Go to the Right Player
function reset_ball_right()
	rally_hits = 0;
	ball_active = false
	local range  = love.math.random()
	ball_x  = (width/2) - BALL_SIZE/2
	ball_y  = (height/2)
	ball_dx = (width/4)
	ball_dy = range * (width/4)
end

-- Resets the Ball, Ball Will Go to the Left Player
function reset_ball_left()
	rally_hits = 0;
	ball_active = false
	local range  = love.math.random()
	ball_x  = (width/2) - BALL_SIZE/2
	ball_y  = (height/2)
	ball_dx = -1 * (width/4)
	ball_dy = range * (width/4)
end

-- Determines whether the Ball bounces off a top or bottom wall
-- or whether Right or Left scored
function wall_collision_check(success_sounds, wall_sounds)
	local success_sound = success_sounds[love.math.random(1, #success_sounds)]
	local wall_sound = wall_sounds[love.math.random(1, #wall_sounds)]
	
	-- Left Player Scored
	if ball_x > width - BALL_SIZE then
		left_score = left_score + 1
		spawn_timer = 2
		success_sound:stop()
		success_sound:play()
		if controller_state == 2 then
			if player1_controller:isVibrationSupported() then
				player1_controller:setVibration(0.25, 0.25, 2)
			end
		elseif controller_state == 1 and side ~= 0 then
			if controller:isVibrationSupported() then
				controller:setVibration(0.25,0.25,2)
			end
		end
		reset_ball_right()
	end

	-- Right Player Scored
	if ball_x <= 0 then
		right_score = right_score + 1
		spawn_timer = 2
		success_sound:stop()
		success_sound:play()
		if controller_state == 2 then
			if player2_controller:isVibrationSupported() then
				player2_controller:setVibration(0.25, 0.25, 2)
			end
		elseif controller_state == 1 and side == 0 then
			if controller:isVibrationSupported() then
				controller:setVibration(0.25, 0.25, 2)
			end
		end
		reset_ball_left()
	end

	-- Top Wall Collision Check
	if ball_y > height - BALL_SIZE then
		wall_sound:stop()
		wall_sound:play()
		ball_y  = height - BALL_SIZE
		ball_dy = ball_dy * -1
	end

	-- Bottom Wall Collision Check
	if ball_y <= 0 then
		wall_sound:stop()
		wall_sound:play()
		ball_y = 0
		ball_dy = ball_dy * -1
	end
end

-- Ensures that Left and Right Paddles cannot
-- go off the screen!
function bind_paddles()
	-- Bind Left Player
	-- Can't go off the bottom of the screen
	if player_left_height < 0 then
		player_left_height = 0
	end
	-- Can't go off the top of the screen
	if player_left_height > height - paddle_y_size then
		player_left_height = height - paddle_y_size
	end

	-- Bind Right Player
	-- Can't go off the bottom of the screen
	if player_right_height < 0 then
		player_right_height = 0
	end
	-- Can't go off the top of the screen
	if player_right_height > height - paddle_y_size then
		player_right_height = height - paddle_y_size
	end
end

function get_score_width(score)
	local digit_count = #tostring(score)

	return digit_count * 3 * DIGIT_SIZE
	     + (digit_count - 1) * DIGIT_SIZE
end

function paddle_collision_check(previous_ball_x, hit_sounds)
	-- Player Left's Hitbox
	if ball_x < left_paddle_x + PADDLE_X_SIZE        -- Right Edge 
	and ball_x + BALL_SIZE > left_paddle_x           -- Left Edge
	and ball_y < player_left_height + paddle_y_size  -- Top Edge
	and ball_y + BALL_SIZE > player_left_height then -- Bottom Edge

		-- Ball came from the LEFT side of the paddle
		if previous_ball_x + BALL_SIZE <= left_paddle_x then
			ball_x  = left_paddle_x - BALL_SIZE
			ball_dx = -math.abs(ball_dx)
			local sound = hit_sounds[love.math.random(1, #hit_sounds)]
			sound:stop()
			sound:play()
			rally_speed_increase()

		-- Ball came from the RIGHT side of the paddle
		elseif previous_ball_x >= left_paddle_x + PADDLE_X_SIZE then
			ball_x  = left_paddle_x + PADDLE_X_SIZE
			ball_dx = math.abs(ball_dx)
			local sound = hit_sounds[love.math.random(1, #hit_sounds)]
			sound:stop()
			sound:play()
			rally_speed_increase()
		end
	end

	-- Player Right's Hitbox
	if ball_x < right_paddle_x + PADDLE_X_SIZE        -- Right Edge
	and ball_x + BALL_SIZE > right_paddle_x           -- Left Edge
	and ball_y < player_right_height + paddle_y_size  -- Top Edge
	and ball_y + BALL_SIZE > player_right_height then -- Bottom Edge

		-- Ball came from the LEFT side
		if previous_ball_x + BALL_SIZE <= right_paddle_x then
			ball_x  = right_paddle_x - BALL_SIZE
			ball_dx = -math.abs(ball_dx)
			local sound = hit_sounds[love.math.random(1, #hit_sounds)]
			sound:stop()
			sound:play()
			rally_speed_increase()

		-- Ball came from the RIGHT side
		elseif previous_ball_x >= right_paddle_x + PADDLE_X_SIZE then
			ball_x  = right_paddle_x + PADDLE_X_SIZE
			ball_dx = math.abs(ball_dx)
			local sound = hit_sounds[love.math.random(1, #hit_sounds)]
			sound:stop()
			sound:play()
			rally_speed_increase()
		end
	end
end

function debug_menu()
	-- Debug Information
	debug_ball_position_x = love.graphics.print(ball_x, 0, 0)
	debug_ball_position_y = love.graphics.print(ball_y, 100, 0)
	debug_rally           = love.graphics.print(rally_hits, 0, 30)
	debug_ball_dx         = love.graphics.print(ball_dx, 0, 40)
	debug_ball_dy         = love.graphics.print(ball_dx, 100, 40)
	debug_fps             = love.graphics.print(love.timer.getFPS(), 0, 50)
	debug_frame_time      = love.graphics.print(love.timer.getDelta(), 0, 60)
	debug_average_time    = love.graphics.print(love.timer.getAverageDelta(), 0, 70)
end
