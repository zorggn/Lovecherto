-- Audition Lua TestBed

-- Mouse values to test against

local mouse_x
local mouse_y
local mouse_dragging
local draggedObject

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

function checkColor(color1, color2)
	return (color1[1] == color2[1] and color1[2] == color2[2] and color1[3] == color2[3])
end

-- Modifier symbol drawing functions

function drawTriangle(centerx, centery, angle, pointlen)
	local x1 = centerx + pointlen * math.cos(angle)
	local y1 = centery - pointlen * -math.sin(angle)
	local x2 = centerx + pointlen/2 * math.cos(angle+math.rad(120))
	local y2 = centery - pointlen/2 * -math.sin(angle+math.rad(120))
	local x3 = centerx + pointlen/2 * math.cos(angle+math.rad(240))
	local y3 = centery - pointlen/2 * -math.sin(angle+math.rad(240))
	love.graphics.triangle('fill', x1, y1, x2, y2, x3, y3)
end

-- Containment checking: point - circle

function bound_point_circle(px,py,cx,cy,cr)
	local dx = cx - px
	local dy = cy - py
	return (dx^2 + dy^2) < cr^2
end

-- Sink definition

local Sink = {
	array = {},
	new = function(self,X,Y,Radius,Color,Attack,Sustain,Decay,Release,SoundPath) -- Sensitivity: 1.0 = 1 pixel/second
		self.array[#self.array+1] = {
			x = X,
			y = Y,
			r = Radius,
			c = Color,
			a = Attack,
			s = Sustain,
			d = Decay,
			e = Release,
			p = 0, -- particle accumulator (held for s, decaying at rate d)
			song = love.audio.newSource(SoundPath,'stream') or false,
			setLMB = function(self,X,Y) self.x = X self.y = Y print("sink position = " .. self.x .. ", " .. self.y) end,
			setLMBS = function(self,X,Y) self.r = math.sqrt((self.x-X)^2+(self.y-Y)^2) print("sink radius = " .. self.r) end,
			setLMBC = function(self,X,Y)  end,
		}
	end,
	init = function(self)
		for i,v in ipairs(self.array) do
			if v.song then
				v.song:setLooping(true)
				v.song:setVolume(0.0)
				v.song:play()
			end
		end
	end,
	event = function(self,particle)
		for i,v in ipairs(self.array) do
			if bound_point_circle(particle.x,particle.y,v.x,v.y,v.r) then
				-- if particle is the correct color, then add to the accumulator
				if checkColor(particle.c, v.c) then
					v.p = math.min(v.p + v.s, v.e*v.s)
					return true
				end
			end
		end
		return false
	end,
	update = function(self,dt)
		for i,v in ipairs(self.array) do
			-- if at least one particle was detected, then if volume is not at max,
			-- then increase by attack rate and delete particles after sustain rate,
			-- else decrease by decay rate
			local vol = v.song:getVolume()
			if v.p > 0 then
				if vol < 1.0 then v.song:setVolume(math.min(vol + 0.1 / v.a * dt, 1.0)) end

				v.p = math.max(v.p - v.d, 0.0)
			else
				if vol > 0.0 then v.song:setVolume(math.max(vol - 0.1 * v.e * dt, 0.0)) end
			end
			print("particle count: " .. v.p)
			print("volume of sink: " .. vol)
		end
	end,
	draw = function(self,dt)
		for i,v in ipairs(self.array) do
			-- only the drain hole
			saveColor()
			love.graphics.setColor(v.c[1],v.c[2],v.c[3],255)
			love.graphics.circle('line', v.x, v.y, v.r, v.r * 5)
			local vol = v.song:getVolume()
			-- two "non-opaque" methods to draw a partially visible line corresponding to smaller volume changes
			love.graphics.setColor(v.c[1],v.c[2],v.c[3],255/(vol*(v.r*2*0.75)%1))
			love.graphics.rectangle('fill',v.x-v.r*0.25,v.y-v.r*0.75*vol,v.r*0.5,1) -- top
			love.graphics.rectangle('fill',v.x-v.r*0.25,(v.y+v.r*0.75*vol)-(1),v.r*0.5,1) -- bottom
			-- two opaque methods to draw the normal line fill and the outline
			love.graphics.setColor(v.c[1],v.c[2],v.c[3],255)
			love.graphics.rectangle('fill',v.x-v.r*0.25,v.y-(v.r-1)*0.75*vol,v.r*0.5,(v.r-1)*1.5*vol)
			love.graphics.rectangle('line',v.x-v.r*0.25,v.y-v.r*0.75,v.r*0.5,v.r*1.5)
			restoreColor()
		end
	end,
	capture = function(self,X,Y)
		for i,v in ipairs(self.array) do
			--print "capture: Sink"
			if bound_point_circle(X,Y,v.x,v.y,v.r) then
				return v
			end
		end
		return false
	end
}

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
			sinked = false,
			temp_r = 0,
		}
	end,
	update = function(self,dt)
		for i,v in ipairs(self.array) do
			if v.live then
				-- apply relevant modifications
				if not v.sinked then v.sinked = Sink:event(v) end
				-- compute movement
				v.x = v.x + v.r * math.cos(v.phi) * (dt/(1/75))
				v.y = v.y - v.r * math.sin(v.phi) * (dt/(1/75))
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

-- Redirector definition

local Redirector = {
	array = {},
	new = function(self,X,Y,Angle,Radius,Acceleration)
		self.array[#self.array+1] = {
			x = X,
			y = Y,
			phi = Angle,
			r = Radius,
			a = Acceleration,
			setLMB = function(self,X,Y) self.x = X self.y = Y print("redirector position = " .. self.x .. ", " .. self.y) end,
			setLMBS = function(self,X,Y) self.phi = math.atan2(Y-self.y,X-self.x) print("redirector angle = " .. self.phi) end,
			setLMBC = function(self,X,Y) self.r = math.sqrt((self.x-X)^2+(self.y-Y)^2) print("redirector radius = " .. self.r) end,
		}
	end,
	update = function(self,dt)
		for j, w in ipairs(self.array) do
			for i,v in ipairs(Particle.array) do
				if v.live --[[and checkolor(w.c,v.c)--]] then
					if bound_point_circle(v.x, v.y, w.x, w.y, w.r) then
						v.tempr = v.r
						v.r = ((v.r * math.cos(v.phi) + w.a * (1 - (((v.x - w.x)^2+(v.y - w.y)^2)^(1/2))/w.r) * 75 * dt * math.cos(w.phi))^2 + (v.r * math.sin(v.phi) + w.a *(1 - (((v.x - w.x)^2+(v.y - w.y)^2)^(1/2))/w.r) * 75 *dt * math.sin(w.phi))^2 )^(0.5)
						v.phi = math.atan2((v.tempr * math.sin(v.phi) + w.a * dt * 75 * -math.sin(w.phi)),(v.tempr * math.cos(v.phi) + w.a * 75 * dt * math.cos(w.phi)))
						--v.tempr = 0
					end
				end
			end
		end
	end,
	draw = function(self,dt)
		for i,v in ipairs(self.array) do
			saveColor()
			love.graphics.setColor(255,255,255,127)
			-- Draw influence circle
			love.graphics.circle('line', v.x, v.y, v.r, v.r * 5)
			-- Draw directional triangle
			drawTriangle(v.x, v.y, v.phi, v.r)
			restoreColor()
		end
	end,
	capture = function(self,X,Y)
		for i,v in ipairs(self.array) do
			--print "capture: Emitter"
			if bound_point_circle(X,Y,v.x,v.y,v.r) then
				return v
			end
		end
		return false
	end
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
			setLMB = function(self,X,Y) self.x = X self.y = Y print("emitter position = " .. self.x .. ", " .. self.y) end,
			setLMBS = function(self,X,Y) self.phi = math.atan2(-(Y-self.y),X-self.x) print("emitter angle = " .. self.phi) end,
			setLMBC = function(self,X,Y) self.d = 0.5-1/math.sqrt((self.x-X)^2+(self.y-Y)^2) print("emitter density = " .. self.d) end,
		}
	end,
	update = function(self,dt,counter)
		for i,v in ipairs(self.array) do
			local rand = math.random()
			--print(i .. "density eq: " .. rand .. " <= " .. v.d)
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
			love.graphics.setColor(v.c[1],v.c[2],v.c[3],127)
			love.graphics.circle('fill', v.x, v.y, 5, 25)
			restoreColor()
		end
	end,
	capture = function(self,X,Y)
		for i,v in ipairs(self.array) do
			--print "capture: Emitter"
			if bound_point_circle(X,Y,v.x,v.y,5) then
				return v
			end
		end
		return false
	end
}

-- Object Capturing for mouse cursor

function Capture(x,y)
	return (Emitter:capture(x,y) or Sink:capture(x,y) or Redirector:capture(x,y))
end

-- Main things

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

	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()

	Redirector:new(2*width/3,height/2,math.rad(120),25,0.01)

	Emitter:new(width/2,height/6,2*math.pi/2,1,-0.5,{127,127,255,255},1/32,1/16,1/5,'rand')
	Emitter:new(width/2,height/4,2*math.pi/2,1,-0.5,{255,127,127,255},1/32,1/16,1/5,'rand')
	Emitter:new(width/2,height/3,2*math.pi/2,1,-0.5,{127,255,127,255},1/32,1/16,1/5,'rand')

	Sink:new(width/3,height/6,25,{127,127,255,255},0.75,5.0,0.5,3.0,'audio/piano_high.mp3')
	Sink:new(width/3,height/4,25,{255,127,127,255},0.75,5.0,0.5,3.0,'audio/piano_low.mp3')
	Sink:new(width/3,height/3,25,{127,255,127,255},0.75,5.0,0.5,3.0,'audio/piano_medium.mp3')

	Sink:init()

end

do
local counter = 0
function love.update(dt)

	-- if mouse coordinates doesn't correspond to the saved values, then we started dragging something

	local mX = love.mouse.getX()
	local mY = love.mouse.getY()

	if love.mouse.isDown('l') and (mouse_x ~= mX or mouse_y ~= mY) then
		if draggedObject == nil then draggedObject = Capture(mX,mY) end
		mouse_x,mouse_y = nil,nil
		if type(draggedObject) == 'table' then
			if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
				draggedObject:setLMBS(mX,mY)
			elseif love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
				draggedObject:setLMBC(mX,mY)
			else
				draggedObject:setLMB(mX,mY)
			end
		end
	end

	-- Element updates

	Redirector:update(dt)
	Emitter:update(dt,counter)
	Sink:update(dt)

	Particle:update(dt)

	counter = counter + dt

end
end

function love.draw()

	love.graphics.push()

	Redirector:draw()
	Emitter:draw()
	Sink:draw()

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
	-- save pressed position
	mouse_x = X
	mouse_y = Y
	-- mouse state _may_ be dragging
	mouse_dragging = true
	--print("mousepressed at " .. X .. " , " .. Y)
end

function love.mousereleased(X,Y,Button)
	if mouse_x == X and mouse_y == Y then
		-- trigger click behaviour based on buttons
	else
		-- release the drag
		draggedObject = nil
	end
	mouse_dragging = false
	--print("mousereleased at " .. X .. " , " .. Y)
end

function love.keypressed(Key,Unicode)
	if key == 'space' then Emitter.array = {} end
end

function love.keyreleased(Key,Unicode)

end