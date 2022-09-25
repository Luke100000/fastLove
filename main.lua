require("run")

local fastLove = require("fastLove")(512)

local textures = { }
for _, v in ipairs(love.filesystem.getDirectoryItems("textures")) do
	textures[v:sub(1, -5)] = love.graphics.newImage("textures/" .. v)
end

love.graphics.setBackgroundColor(0, 84 / 255, 108 / 255)
love.window.setMode(1200, 800)
love.window.setVSync(0)

local w, h = love.graphics.getDimensions()

local delta = 0

local guns = {
	{ "ship_gun_dual_gray", -36, -26, 17, 32, math.pi / 4 * 3 },
	{ "ship_gun_dual_gray", -36 + 70, -26, 17, 32, -math.pi / 4 * 3 },
	{ "ship_gun_gray", -44, 45, 8, 20, math.pi / 2 },
	{ "ship_gun_gray", -44 + 88, 45, 8, 20, -math.pi / 2 },
	{ "ship_gun_gray", -44, 45 + 27, 8, 20, math.pi / 2 },
	{ "ship_gun_gray", -44 + 88, 45 + 27, 8, 20, -math.pi / 2 },
	{ "ship_gun_dual_gray", 0, -65, 17, 32, -math.pi },
	{ "ship_gun_dual_gray", 0, 40, 17, 32, -math.pi },
	{ "ship_gun_dual_gray", 0, 75, 17, 32, 0 },
}

local ships = 1000

local function drawFastLove()
	fastLove:origin()
	fastLove:translate(w / 2, h / 2)
	
	local t = love.timer.getTime() * 0.1
	for i = 1, ships do
		local r = i * 7 + t * ((i * math.pi) % 1)
		local dist = 100 + (i * 77.7) % 300
		fastLove:push()
		fastLove:translate(math.cos(r) * dist * 1.5, math.sin(r) * dist)
		fastLove:rotate(r + math.pi)
		fastLove:scale(0.5)
		
		fastLove:add(textures.ship_large_body, 0, 0, 0, 1, 1, 61, 184)
		for _, gun in ipairs(guns) do
			local rot = gun[6] or 0
			fastLove:add(textures["ship_gun_base_dark"], gun[2], gun[3], 0, 1, 1, 12, 12)
			fastLove:add(textures[gun[1]], gun[2], gun[3], rot, 1, 1, gun[4], gun[5])
		end
		fastLove:pop()
	end
	fastLove:render()
	fastLove:clear()
	
	love.graphics.printf(string.format("%.1f", 1 / delta), 0, h / 2, w, "center")
	love.graphics.printf("FastLove", 0, h / 2 + 15, w, "center")
end

local function drawLove()
	love.graphics.origin()
	love.graphics.translate(w / 2, h / 2)
	
	local t = love.timer.getTime() * 0.1
	for i = 1, ships do
		local r = i * 7 + t * ((i * math.pi) % 1)
		local dist = 100 + (i * 77.7) % 300
		love.graphics.push()
		love.graphics.translate(math.cos(r) * dist * 1.5, math.sin(r) * dist)
		love.graphics.rotate(r + math.pi)
		love.graphics.scale(0.5)
		
		love.graphics.draw(textures.ship_large_body, 0, 0, 0, 1, 1, 61, 184)
		for _, gun in ipairs(guns) do
			local rot = gun[6] or 0
			love.graphics.draw(textures["ship_gun_base_dark"], gun[2], gun[3], 0, 1, 1, 12, 12)
			love.graphics.draw(textures[gun[1]], gun[2], gun[3], rot, 1, 1, gun[4], gun[5])
		end
		love.graphics.pop()
	end
	
	love.graphics.origin()
	love.graphics.printf(string.format("%.1f", 1 / delta), 0, h / 2, w, "center")
	love.graphics.printf("Love2d draw()" .. tostring(jit.status()), 0, h / 2 + 15, w, "center")
end

local quads = {}
local function getQuad(s, quad)
	local q = quad and fastLove:getQuad(s) or s.quad
	if not quads[q] then
		quads[q] = love.graphics.newQuad(
				q[1] * fastLove.resolution, q[2] * fastLove.resolution,
				(q[3] - q[1]) * fastLove.resolution, (q[4] - q[2]) * fastLove.resolution,
				fastLove.resolution, fastLove.resolution
		)
	end
	return quads[q]
end

local spritebatch = love.graphics.newSpriteBatch(fastLove.image)
local function drawSpritebatches()
	local t = love.timer.getTime() * 0.1
	for i = 1, ships do
		--since spritebatches do not support transformations, we skip them here
		local r = i * 7 + t * ((i * math.pi) % 1) + math.pi
		local dist = 100 + (i * 77.7) % 300
		local x, y = math.cos(r) * dist * 1.5, math.sin(r) * dist
		local size = 0.5
		
		spritebatch:add(getQuad(fastLove:getSprite(textures.ship_large_body)), x, y, r, size, size, 61, 184)
		for _, gun in ipairs(guns) do
			local rot = (gun[6] or 0) + r
			spritebatch:add(getQuad(fastLove:getSprite(textures["ship_gun_base_dark"])), gun[2] + x, gun[3] + y, 0, size, size, 12, 12)
			spritebatch:add(getQuad(fastLove:getSprite(textures[gun[1]])), gun[2] + x, gun[3] + y, rot, size, size, gun[4], gun[5])
		end
	end
	
	love.graphics.origin()
	love.graphics.translate(w / 2, h / 2)
	love.graphics.draw(spritebatch)
	spritebatch:clear()
	
	love.graphics.origin()
	love.graphics.printf(string.format("%.1f", 1 / delta), 0, h / 2, w, "center")
	love.graphics.printf("Love2d Spritebatch", 0, h / 2 + 15, w, "center")
end

local mode = 1
function love.draw()
	w, h = love.graphics.getDimensions()
	local dt = math.min(1, love.timer.getDelta())
	delta = delta * (1 - dt) + love.timer.getDelta() * dt
	if mode == 1 then
		drawFastLove()
	elseif mode == 2 then
		drawLove()
	elseif mode == 3 then
		drawSpritebatches()
	end
end

function love.keypressed(key)
	if key == "1" then
		mode = 1
	elseif key == "2" then
		mode = 2
	elseif key == "3" then
		mode = 3
	end
end

function love.mousepressed()
	mode = (mode + 1) % 3 + 1
end