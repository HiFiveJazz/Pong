-- Ball Properties
BALL_SIZE     = 10
BALL_SPEED    = 200

-- Paddle Properties
PADDLE_X_SIZE = BALL_SIZE
PADDLE_Y_SIZE = 150

-- Score Properties
DIGIT_SIZE    = BALL_SIZE
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

left_score  = 0
right_score = 0
joystick = nil

function love.load()
	-- Joystick Handling
	local joysticks = love.joystick.getJoysticks()
	joystick = joysticks[1]
	if joystick then
		print("Joystick FOUND:", joystick)
		print("Is gamepad:", joystick:isGamepad())
		print("Axis Count:", joystick:getAxisCount())
	else
		print("Joystick NOT FOUND")
	end

	-- Initial Player Positions
	get_dimensions()
	rally_hits = 0;
	player_left_height  = height/2
	player_right_height = height/2
	paddle_speed = (5/3) * height
	ball_active = true
	spawn_timer = 2

	ball_x   = (width/2) - BALL_SIZE/2
	ball_y   = (height/2)
	ball_dx  = (width/4)
	ball_dy  = (width/4)
	ball_active = false
	spawn_timer = 10
end

function love.update(dt)
	get_dimensions()
	left_paddle_x        = width/80
	right_paddle_x       = width - left_paddle_x - PADDLE_X_SIZE

	-- Ball is waiting to respawn
	if not ball_active then
		spawn_timer = spawn_timer - dt

		if spawn_timer <= 0 then
			ball_x = width / 2
			ball_y = height / 2
			ball_dx = width / 4
			ball_dy = width / 4

			ball_active = true
		end

	else
		local previous_ball_x = ball_x

		ball_x = ball_x + ball_dx*dt;
		ball_y = ball_y + ball_dy*dt;

		-- Ball Bouncing Off Wall Logic
		if ball_x > width - BALL_SIZE then
			left_score = left_score + 1
			ball_active = false
			spawn_timer = 2
			rally_hits = 0
		end

		if ball_x <= 0 then
			right_score = right_score + 1
			ball_active = false
			spawn_timer = 2
			rally_hits = 0;
		end

		if ball_y > height - BALL_SIZE then
			ball_y = height - BALL_SIZE
			ball_dy = ball_dy * -1
		end

		if ball_y <= 0 then
			ball_y = 0
			ball_dy = ball_dy * -1
		end

		-- Ball Bouncing off Players Logic
		-- Player Left's Hitbox
		if ball_x < left_paddle_x + PADDLE_X_SIZE        -- Right Edge 
		and ball_x + BALL_SIZE > left_paddle_x           -- Left Edge
		and ball_y < player_left_height + PADDLE_Y_SIZE  -- Top Edge
		and ball_y + BALL_SIZE > player_left_height then -- Bottom Edge
		
			-- Ball came from the LEFT side of the paddle
			if previous_ball_x + BALL_SIZE <= left_paddle_x then
				ball_x = left_paddle_x - BALL_SIZE
				ball_dx = -math.abs(ball_dx)
				rally_hits = rally_hits + 1
				speed_multiplier = 1 + 0.30 / (1 + rally_hits / 10) 
				ball_dx  = ball_dx * speed_multiplier
				ball_dy  = ball_dy * speed_multiplier

			-- Ball came from the RIGHT side of the paddle
			elseif previous_ball_x >= left_paddle_x + PADDLE_X_SIZE then
				ball_x = left_paddle_x + PADDLE_X_SIZE
				ball_dx = math.abs(ball_dx)
				rally_hits = rally_hits + 1
				speed_multiplier = 1 + 0.30 / (1 + rally_hits / 10) 
				ball_dx  = ball_dx * speed_multiplier
				ball_dy  = ball_dy * speed_multiplier

			end
		end

		-- Player Right's Hitbox
		if ball_x < right_paddle_x + PADDLE_X_SIZE         -- Right Edge
		and ball_x + BALL_SIZE > right_paddle_x            -- Left Edge
		and ball_y < player_right_height + PADDLE_Y_SIZE   -- Top Edge
		and ball_y + BALL_SIZE > player_right_height then  -- Bottom Edge

			-- Ball came from the LEFT side
			if previous_ball_x + BALL_SIZE <= right_paddle_x then
				ball_x = right_paddle_x - BALL_SIZE
				ball_dx = -math.abs(ball_dx)
				rally_hits = rally_hits + 1
				speed_multiplier = 1 + 0.30 / (1 + rally_hits / 10) 
				ball_dx  = ball_dx * speed_multiplier
				ball_dy  = ball_dy * speed_multiplier

			-- Ball came from the RIGHT side
			elseif previous_ball_x >= right_paddle_x + PADDLE_X_SIZE then
				ball_x = right_paddle_x + PADDLE_X_SIZE
				ball_dx = math.abs(ball_dx)
				rally_hits = rally_hits + 1
				speed_multiplier = 1 + 0.30 / (1 + rally_hits / 10) 
				ball_dx  = ball_dx * speed_multiplier
				ball_dy  = ball_dy * speed_multiplier
			end
		end
	end

	
	-- Left Player Controls
	if love.keyboard.isDown("w") then
		player_left_height = player_left_height - paddle_speed*dt
	end
	if love.keyboard.isDown("s") then
		player_left_height = player_left_height + paddle_speed*dt
	end

	-- TODO: Ensure that controller scheme is 
	-- either Mouse or Keyboard, not both like 
	-- it currently is 

	-- Joy Stick Controls
	if joystick then
		left_stick_y  = joystick:getGamepadAxis("lefty")   -- Left Analog Stick
		right_stick_y = joystick:getGamepadAxis("righty") -- Right Analog Stick

		-- Left Player
		if joystick:isGamepadDown("dpup") or (left_stick_y < -0.125) then
			player_left_height = player_left_height - paddle_speed*dt
		end

		if joystick:isGamepadDown("dpdown") or (left_stick_y > 0.125) then
			player_left_height = player_left_height + paddle_speed*dt
		end

		-- Right Player
		if (right_stick_y < -0.125) then
			player_right_height = player_right_height - paddle_speed*dt
		end

		if (right_stick_y > 0.125) then
			player_right_height = player_right_height + paddle_speed*dt
		end
	end

	-- Right Player Controls
	if love.keyboard.isDown("up") or love.keyboard.isDown("k") then
		player_right_height = player_right_height - paddle_speed*dt
	end
	if love.keyboard.isDown("down") or love.keyboard.isDown("j") then
		player_right_height = player_right_height + paddle_speed*dt
	end

	-- Bind Left Player
	if player_left_height < 0 then
		player_left_height = 0
	end
	if player_left_height > height - PADDLE_Y_SIZE then
		player_left_height = height - PADDLE_Y_SIZE
	end

	-- Bind Right Player
	if player_right_height < 0 then
		player_right_height = 0
	end
	if player_right_height > height - PADDLE_Y_SIZE then
		player_right_height = height - PADDLE_Y_SIZE
	end
end

function love.draw()
	clear_screen()
	draw_ball()
	draw_net()
	draw_paddles()
	-- Left Player's Score
	draw_score(digits[left_score], width/2 - 3*DIGIT_SIZE - 10,10)
	-- Right Player's Score
	draw_score(digits[right_score], width/2 + 10, 10)
	debug_menu()
end

function draw_net()
	local net_width = 2;
	x_position = width/2 - net_width/2;
	local net_height = 4;
	local i = 0
	while i < height do
		love.graphics.rectangle("fill", x_position, i, net_width, net_height)
		i = i + 8;
	end
end

function clear_screen()
	love.graphics.clear(67/255, 81/255, 83/255, 1)
end


function draw_ball()
	-- Update Ball
	ball = love.graphics.rectangle("fill", ball_x, ball_y, BALL_SIZE, BALL_SIZE) 
end

function draw_paddles()
	love.graphics.rectangle("fill", left_paddle_x, player_left_height, PADDLE_X_SIZE, PADDLE_Y_SIZE) -- Left Player 
	love.graphics.rectangle("fill", right_paddle_x, player_right_height, PADDLE_X_SIZE, PADDLE_Y_SIZE) -- Right Player 
	-- love.graphics.rectangle("fill", width-(width/8), player_right_height, PADDLE_X_SIZE, PADDLE_Y_SIZE) -- Right Player Score 
end

-- TODO: How to handle scores bigger than 9? maybe first to 9 wins? 
function draw_score(digit,x,y)
	for cell_y,row in ipairs(digit) do
		for cell_x,cell in ipairs(row) do
			if cell ~= 0 then
				love.graphics.rectangle("fill", x+ (cell_x-1)*DIGIT_SIZE, y+ (cell_y-1)*DIGIT_SIZE, DIGIT_SIZE, DIGIT_SIZE)
			end
		end
	end
end

function get_dimensions()
	width, height = love.graphics.getDimensions()
end

function collision_logic()
end

function debug_menu()
	-- time = love.time.getFPS()
	-- Debug
	debug_ball_position_x = love.graphics.print(ball_x, 0, 0)
	debug_ball_position_y = love.graphics.print(ball_y, 100, 0)
	debug_left_y          = love.graphics.print(joystick:getGamepadAxis("lefty"), 0, 10)
	debug_right_y         = love.graphics.print(joystick:getGamepadAxis("righty"), 0, 20)
	debug_rally           = love.graphics.print(rally_hits, 0, 30)
	debug_ball_dx         = love.graphics.print(ball_dx, 0, 40)
	debug_ball_dy         = love.graphics.print(ball_dx, 100, 40)
	debug_fps             = love.graphics.print(love.timer.getFPS(), 0, 50)
	debug_frame_time      = love.graphics.print(love.timer.getDelta(), 0, 60)
	debug_average_time    = love.graphics.print(love.timer.getAverageDelta(), 0, 70)
end
