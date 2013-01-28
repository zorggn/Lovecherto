-- Audition Lua TestBed

-- Color management

do
	local colorStack = {}
	local stackCounter = 0

	function saveColor()
		stackCounter = stackCounter + 1
        local temp = {}
        temp[1], temp[2], temp[3], temp[4] = love.graphics.getColor()
		colorStack[stackCounter] = temp
	end

	function restoreColor()
		if stackCounter == 0 then
			print ("Error: Trying to pop a color from an empty stack.\n" ..
					"	Check if you have the same # of saveColor() and restoreColor() functions!")
		else
			local r,g,b,a = unpack(colorStack[stackCounter])
			stackCounter = stackCounter - 1
			love.graphics.setColor(r,g,b,a)
		end
	end
end

-- Particle definition

local Particle = {
	array = {},
	new = function(self,X,Y,Angle,Magnitude,Acceleration,Color)
		self.array[#self.array+1] = {
			x = X,
			y = Y,
			phi = Angle,
			r = Magnitude,
			a = Acceleration,
			c = Color,
			live = true,
		}
	end,
	update = function(self,dt)
		for i,v in ipairs(self.array) do
			if v.live then
				-- apply relevant modifications

				-- compute movement
				v.x = v.x + v.r * math.cos(v.phi) * (dt/(1/75))
				v.y = v.y + v.r * math.sin(v.phi) * (dt/(1/75))
				v.r = v.r + v.r * v.a * dt
				if (v.r <= 0.1) then v.live = false end
			end
		end
	end,
	draw = function(self)
		for i,v in ipairs(self.array) do
			if v.live then
				saveColor()
				love.graphics.setColor(v.c[1] or 255,v.c[2] or 255,v.c[3] or 255,v.c[4] or 255)
				love.graphics.point(v.x,v.y)
				restoreColor()
			end
		end
	end,
}

-- Emitter definition

local Emitter = {
	array = {},
	new = function(self,X,Y,Angle,Magnitude,Acceleration,Color,Spread,Variation,Density,Mode)
		self.array[#self.array+1] = {
			x = X,
			y = Y,
			phi = Angle,
			r = Magnitude,
			a = Acceleration,
			s = Spread,
			v = Variation,
			d = Density,
			m = Mode,
			c = Color,
			ctr = 0
		}
	end,
	update = function(self,dt,counter)
		for i,v in ipairs(self.array) do
			local rand = math.random()
			if rand <= v.d then
				if v.m == 'sin' then
					Particle:new(v.x,v.y,v.phi+(math.sin(counter*10)*v.s),v.r+(math.random()*v.v*2)-v.v,v.a,v.c)
				else --if v.m = 'rand' then
					Particle:new(v.x,v.y,v.phi+((math.random()*v.s*2)-v.s),v.r+(math.random()*v.v*2)-v.v,v.a,v.c)
				end
			end
		end
	end,
	draw = function(self,dt)
		for i,v in ipairs(self.array) do
			-- only the emitter hole
			saveColor()
			love.graphics.setColor(127,127,127,255)
			love.graphics.circle('fill', v.x, v.y, 5, 10)
			restoreColor()
		end
	end,
}

-- Drain definition

local Drain = {
	array = {},

	draw = function(self,dt)
		for i,v in ipairs(self.array) do
			-- only the drain hole
			saveColor()
			love.graphics.setColor(127,127,127,255)
			love.graphics.circle('line', v.x, v.y, 10, 50)
			restoreColor()
		end
	end,
}

local Canvas

function love.load()

	-- Create canvas
	Canvas = love.graphics.newCanvas()

	-- Test area
	--for i=1,math.pi*2,0.1 do
	--	Particle:new(love.graphics.getWidth()/2,love.graphics.getHeight()/2,i,0.5,{255,255,255,255})
	--end

	
	--Particle:new(love.graphics.getWidth()/2,love.graphics.getHeight()/2,math.pi/2+((math.random()*2)-1)/16,1.0,-0.5,{255,255,255,255})
	--Particle:new(love.graphics.getWidth()/2,love.graphics.getHeight()/2,math.pi/2+(math.sin(counter*10)/16),1.0,-0.5,{255,255,255,255})

	Emitter:new(love.graphics.getWidth()/4,love.graphics.getHeight()/2,math.pi/2,1,-0.5,{127,127,255,255},1/32,1/16,1/5,'rand')
	Emitter:new(love.graphics.getWidth()/2,love.graphics.getHeight()/4,math.pi/2,1,-0.5,{255,127,127,255},1/32,1/16,1/5,'rand')

end

do
local counter = 0
function love.update(dt)

	Emitter:update(dt,counter)

	Particle:update(dt)

	counter = counter + dt

end
end

function love.draw()

	love.graphics.push()

	Emitter:draw()

	love.graphics.setCanvas(Canvas)

	saveColor()
	love.graphics.setColor(0,0,0,3)
	love.graphics.rectangle('fill',0,0,love.graphics.getWidth(),love.graphics.getHeight())
	restoreColor()

	Particle:draw()

	love.graphics.setCanvas()

	love.graphics.draw(Canvas)

	love.graphics.pop()

end

function love.mousepressed(X,Y,Button)
	
end

function love.mousereleased(X,Y,Button)

end

function love.keypressed(Key,Unicode)

end

function love.keyreleased(Key,Unicode)

end