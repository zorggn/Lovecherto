--[[
	-- Roadmap
--]]

--[[ Misc Code Enhancements ]]--

-- Make a counter for the particles so they don't vanish suddenly when they reach 0 speed (else they can't reverse direction)

--[[ Manipulatable Elements ]]--

-- [ ] - Redirector		- Modifies the direction the particles are heading towards
-- [ ] - Accelerator	- Makes particles faster
-- [ ] - Colormixer		- Mixes the color of the particles
--							(uses an array that notes the different colors that are active inside it,
--							then only uses those to mix the output color)
-- [ ] - Mirror			- Sends back the particles the same direction they came from

--[[ Static Elements ]]--

-- [x] - Emitter		- Emits particles in a direction
-- [x] - Sink			- Absorbs particles and plays music, the goal condition is to have all of these playing at max volume
-- [ ] - Black Hole		- Absorbs particles
-- [ ] - Nebula			- Colorizes incoming particles to the color of the element
-- [ ] - Wormhole		- Two of these are linked, entering one transports particles to the other, and vice versa

--[[ Game Structure ]]--

-- [ ] - Basic Menu Structure
-- [ ] - Loading Mappacks
-- [ ] - Mappack (and Map) Editor