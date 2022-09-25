local mat4 = _G.mat4 or require("libs/luaMatrices/mat4")

local ffi = _G.ffi or require("ffi")

ffi.cdef([[
	typedef struct {
		float x, y;
		float u, v;
		unsigned char r, g, b, a;
	} vertex;
]])

local meta = { }

local function add(children, x, y, w, h)
	if w > 0 and h > 0 then
		local c = {
			x = x,
			y = y,
			width = w,
			height = h,
			free = true
		}
		table.insert(children, c)
		return c
	end
end

local function findChunk(space, w, h)
	if space.free and space.width == w and space.height == h then
		space.free = false
		return space.x, space.y
	elseif space.free and space.width >= w and space.height >= h then
		if space.children then
			local x, y
			for _, c in ipairs(space.children) do
				x, y = findChunk(c, w, h)
				if x then
					break
				end
			end
			
			--update free flag
			space.free = false
			for _, c in ipairs(space.children) do
				if c.free then
					space.free = true
					break
				end
			end
			
			return x, y
		else
			space.children = { }
			
			add(space.children, space.x, space.y, w, h).free = false
			
			if space.width - w > space.height - h then
				add(space.children, space.x, space.y + h, w, space.height - h)
				add(space.children, space.x + w, space.y, space.width - w, space.height)
			else
				add(space.children, space.x + w, space.y, space.width - w, h)
				add(space.children, space.x, space.y + h, space.width, space.height - h)
			end
			
			return space.x, space.y
		end
	end
end

function meta:getSprite(texture)
	if not self.atlas[texture] then
		--find free chunk
		local w, h = texture:getDimensions()
		local x, y = findChunk(self.space, w, h)
		
		assert(x, "Atlas full!")
		
		--register texture
		self.atlas[texture] = {
			quads = { },
			quad = {
				x / self.resolution,
				y / self.resolution,
				(x + w) / self.resolution,
				(y + h) / self.resolution
			},
			width = w,
			height = h,
			x = x,
			y = y,
		}
		
		love.graphics.push("all")
		love.graphics.reset()
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(self.image)
		love.graphics.draw(texture, x, y)
		love.graphics.pop()
	end
	
	return self.atlas[texture]
end

function meta:getQuad(p, quad)
	if not p.quads[quad] then
		local q = p.quad
		local x, y, w, h = quad:getViewport()
		local tw, th = quad:getTextureDimensions()
		p.quads[quad] = {
			x / tw * (q[3] - q[1]) + q[1],
			y / th * (q[4] - q[2]) + q[2],
			(x + w) / tw * (q[3] - q[1]) + q[1],
			(y + h) / th * (q[4] - q[2]) + q[2]
		}
	end
	return p.quads[quad]
end

function meta:addQuad(texture, quad, x, y, r, sx, sy, ox, oy, kx, ky)
	local p = self:getSprite(texture)
	local q = self:getQuad(p, quad)
	self:addSprite(p, q, x, y, r, sx, sy, ox, oy, kx, ky)
end

function meta:add(texture, x, y, r, sx, sy, ox, oy, kx, ky)
	local p = self:getSprite(texture)
	self:addSprite(p, p.quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

function meta:addSprite(p, quad, x, y, r, sx, sy, ox, oy, kx, ky)
	if self.size >= self.capacity then
		self:resize()
	end
	
	local t = self.transform:transform(x, y, r, sx, sy, ox, oy, kx, ky)
	
	local v1 = self.vertices[self.size * 4]
	local v2 = self.vertices[self.size * 4 + 1]
	local v3 = self.vertices[self.size * 4 + 2]
	local v4 = self.vertices[self.size * 4 + 3]
	
	v1.x = t[4]
	v1.y = t[8]
	
	v2.x = t[1] * p.width + t[4]
	v2.y = t[5] * p.width + t[8]
	
	v3.x = t[1] * p.width + t[2] * p.height + t[4]
	v3.y = t[5] * p.width + t[6] * p.height + t[8]
	
	v4.x = t[2] * p.height + t[4]
	v4.y = t[6] * p.height + t[8]
	
	v1.u, v1.v, v1.r, v1.g, v1.b, v1.a = quad[1], quad[2], self.color[1], self.color[2], self.color[3], self.color[4]
	v2.u, v2.v, v2.r, v2.g, v2.b, v2.a = quad[3], quad[2], self.color[1], self.color[2], self.color[3], self.color[4]
	v3.u, v3.v, v3.r, v3.g, v3.b, v3.a = quad[3], quad[4], self.color[1], self.color[2], self.color[3], self.color[4]
	v4.u, v4.v, v4.r, v4.g, v4.b, v4.a = quad[1], quad[4], self.color[1], self.color[2], self.color[3], self.color[4]
	
	self.size = self.size + 1
	self.dirty = true
end

function meta:render(...)
	if self.size > 0 then
		if self.dirty then
			self.mesh:setVertices(self.byteData)
			self.dirty = false
		end
		self.mesh:setDrawRange(1, self.size * 6)
		love.graphics.draw(self.mesh, ...)
	end
end

function meta:translate(x, y)
	self.transform = self.transform:translate(x, y)
end

function meta:scale(x, y)
	self.transform = self.transform:scale(x, y)
end

function meta:rotate(rot)
	self.transform = self.transform:rotateZ(-rot)
end

function meta:origin()
	self.transform = mat4.getIdentity()
end

function meta:push()
	table.insert(self.stack, self.transform)
end

function meta:pop()
	self.transform = table.remove(self.stack)
end

function meta:clear()
	self.size = 0
end

function meta:setColor(r, g, b, a)
	self.color = { r * 255, g * 255, b * 255, a * 255 }
end

function meta:reset()
	self.space = {
		x = 0,
		y = 0,
		width = self.resolution,
		height = self.resolution,
		free = true,
	}
	
	self.byteData = false
	self.capacity = 1
	self:resize()
end

function meta:resize()
	self.capacity = self.capacity * 2
	
	local oldByteData = self.byteData
	local oldVertexMapByteData = self.vertexMapByteData
	local oldVertex = self.vertices
	local oldIndices = self.indices
	
	--create
	self.byteData = love.data.newByteData(ffi.sizeof("vertex") * self.capacity * 4)
	self.vertexMapByteData = love.data.newByteData(ffi.sizeof("uint32_t") * self.capacity * 6)
	
	--provide access to data
	self.vertices = ffi.cast("vertex*", self.byteData:getFFIPointer())
	self.indices = ffi.cast("uint32_t*", self.vertexMapByteData:getFFIPointer())
	
	--copy old part
	if oldByteData and oldVertexMapByteData then
		ffi.copy(self.vertices, oldVertex, ffi.sizeof("vertex") * self.capacity * 4 / 2)
		ffi.copy(self.indices, oldIndices, ffi.sizeof("uint32_t") * self.capacity * 6 / 2)
	end
	
	--new mesh
	self.mesh = love.graphics.newMesh({
		{ "VertexPosition", "float", 2 },
		{ "VertexTexCoord", "float", 2 },
		{ "VertexColor", "byte", 4 },
	}, self.byteData, "triangles", "static")
	
	--set atlas
	self.mesh:setTexture(self.image)
	
	--create rest of index map
	for i = oldByteData and (self.capacity / 2 - 1) or 0, self.capacity - 1 do
		self.indices[i * 6 + 0] = i * 4 + 0
		self.indices[i * 6 + 1] = i * 4 + 1
		self.indices[i * 6 + 2] = i * 4 + 2
		self.indices[i * 6 + 3] = i * 4 + 0
		self.indices[i * 6 + 4] = i * 4 + 2
		self.indices[i * 6 + 5] = i * 4 + 3
	end
	self.mesh:setVertexMap(self.vertexMapByteData, "uint32")
end

return function(resolution)
	assert(type(resolution) == "number", "Missing atlas resolution")
	
	local image = love.graphics.newCanvas(resolution, resolution)
	local fl = setmetatable({
		resolution = resolution,
		capacity = 1,
		image = image,
		transform = mat4:getIdentity(),
		size = 0,
		color = { 255, 255, 255, 255 },
		stack = { },
		atlas = { },
		dirty = false
	}, { __index = meta })
	
	fl:reset()
	
	return fl
end