local app = application

local function map(v, minSrc, maxSrc, minDst, maxDst)
	return (v - minSrc) / (maxSrc - minSrc) * (maxDst - minDst) + minDst
end

local FORMAT_STRING = "\e[color=%s]Min: %03i\e[color]  \e[color=%s]Curr: %03i\e[color]  \e[color=%s]Max: %03i\e[color]"

FPSgraph = Core.class(Sprite)

function FPSgraph:init(width, height, options)
	
	assert(width and height, "Size is not defined")
	assert(width > 0 and height > 0, "Size must be > 0") 
	self.width = width
	self.height = height
	
	options = options or {}
	
	local step = options.step or 20	
	assert(step and step >= 1, "Step cant be less than 1!") 
	self.step = step
	
	self:setUp(options)
	
	local maxTextHeight = self.height - self.meshHeight
	
	self.bg = Pixel.new(self.color, self.alpha, self.width, self.height)
	self:addChild(self.bg)
	
	self.mesh = Mesh.new()
	self.mesh:setY(maxTextHeight)
	self:addChild(self.mesh)
	
	self.fpsTF = TextField.new(self.font, "")
	self.fpsTF:setTextColor(self.textColor)
	self.fpsTF:setLayout{
		w = self.width, h = maxTextHeight,
		flags = self.textAlign
	}
	self:addChild(self.fpsTF)
	
	self.cutLast = false
	
	self.timer = 0
	self.maxFps = 0
	self.minFps = 100000
	self.recentFpsData = {}
	
	self.ignoreAppScale = false
	
	self.fpsTF:setText(FORMAT_STRING:format(0,0,0,0,0,0))
end
-- ignore application scale mode and set position to 
-- top left corner of the window
function FPSgraph:setIgnoreAppScale(flag)
	if (self.ignoreAppScale == flag) then 
		return
	end
	
	if (flag) then
		self.__ox, self.__oy = self:getPosition()
		self.__sx, self.__sy = self:getScale()
		self:onAppResize()
		self:addEventListener("applicationResize", self.onAppResize, self)
	else
		self:setPosition(self.__ox, self.__oy)
		self:setScale(self.__sx, self.__sy)
		self.__ox, self.__oy = nil, nil
		self.__sx, self.__sy = nil, nil
		self:removeEventListener("applicationResize", self.onAppResize, self)
	end
	
	self.ignoreAppScale = flag
end
--
function FPSgraph:onAppResize()
	local dx = app:getLogicalScaleX()
	local dy = app:getLogicalScaleY()
	local tx = app:getLogicalTranslateX()
	local ty = app:getLogicalTranslateY()
	self:setPosition(-tx / dx, -ty / dy)
	self:setScale(1/app:getLogicalScaleX(), 1/app:getLogicalScaleY())
end
--[[  antialiased
	vertex points
	
             /------1       
             |      |\   
antialiasing-|      | \  
             |      |  \
             \------2---4---7
                    |\  |  /|
                    | \ | / |
                    |  \|/  |
                    |   5---8 <------ actual FPS value height
                    |  /|  /|
                    | / | / |
                    |/  |/  |
                    3---6---9 <------- ground
	
	triangles:
	1,2,4, 2,4,5, 2,3,5, 3,5,6,
	4,5,7, 5,7,8, 5,6,8, 6,8,9,
	etc...
]]
function FPSgraph:updateMesh()
	local prevMax = self.maxFps
	self.maxFps = 0
	self.minFps = 100000
	
	local stroke = self.antialiasing
	local m = self.mesh
	local index = 1
	local vertexIndex = 1
	local n = #self.recentFpsData
	for i, fps in ipairs(self.recentFpsData) do		
		if (i < n) then 
			m:setIndices(
				index +  0, vertexIndex + 0,
				index +  1, vertexIndex + 1,
				index +  2, vertexIndex + 3,
				index +  3, vertexIndex + 1,
				index +  5, vertexIndex + 3,
				index +  4, vertexIndex + 4,
				
				index +  6, vertexIndex + 1,
				index +  7, vertexIndex + 2,
				index +  8, vertexIndex + 4,
				index +  9, vertexIndex + 2,
				index + 10, vertexIndex + 4,
				index + 11, vertexIndex + 5
			)
		end
		
		local x = 0
		local y = map(fps, 0, prevMax, self.meshHeight - stroke, 0)
		if (self.cutLast and i == n) then
			x = self.width
		else
			x = (i - 1) * self.step
		end
		
		m:setVertices(
			vertexIndex + 0, x, y - stroke,
			vertexIndex + 1, x, y,
			vertexIndex + 2, x, self.meshHeight
		)
		
		m:setColors(
			vertexIndex + 0, self.maxColor, 0,
			vertexIndex + 1, self.maxColor, 1,
			vertexIndex + 2, self.minColor, 1
		)
		
		
		self.maxFps = self.maxFps <> fps
		self.minFps = self.minFps >< fps
		
		index += 12
		vertexIndex += 3
	end
end
--[[ (no antialiasing)
	vertex points
	
    1    
    |\   
    | \  
    |  \ 
    |   3---5 <------ actual FPS value height
    |  /|  /|
    | / | / |
    |/  |/  |
    2---4---6 <------- ground
	
	triangles:
	1,2,3, 2,3,4,
	3,4,5, 4,5,6,
	etc...
]]
function FPSgraph:updateMesh_old() -- without antialiasing
	local prevMax = self.maxFps
	self.maxFps = 0
	self.minFps = 100000
	
	local m = self.mesh
	local index = 1
	local vertexIndex = 1
	local n = #self.recentFpsData
	for i, fps in ipairs(self.recentFpsData) do		
		if (i < n) then 
			m:setIndices(
				index + 0, vertexIndex + 0,
				index + 1, vertexIndex + 1,
				index + 2, vertexIndex + 2,
				index + 3, vertexIndex + 1,
				index + 4, vertexIndex + 2,
				index + 5, vertexIndex + 3
			)
		end
		
		local x = 0
		local y = map(fps, 0, prevMax, self.meshHeight, 0)
		if (self.cutLast and i == n) then
			x = self.width
		else
			x = (i - 1) * self.step
		end
		
		m:setVertices(
			vertexIndex + 0, x, y,
			vertexIndex + 1, x, self.meshHeight
		)
		
		m:setColors(
			vertexIndex + 0, self.maxColor, 1,
			vertexIndex + 1, self.minColor, 1
		)
		
		
		self.maxFps = self.maxFps <> fps
		self.minFps = self.minFps >< fps
		
		index += 6
		vertexIndex += 2
	end
end
--
function FPSgraph:update(dt)
	self.timer += dt
	
	if (self.timer > self.updateTime) then
		self.timer = 0
		local fps = 1 / dt
		
		local n = #self.recentFpsData
		if (n < (self.width + self.step) // self.step) then 
			self.recentFpsData[n+1] = fps
			self.cutLast = false
		else
			table.remove(self.recentFpsData, 1)
			self.recentFpsData[n] = fps
			self.cutLast = true
		end
		
		self:updateMesh()
		
		self.fpsTF:setText(FORMAT_STRING:format(
			self.minTextColor,
			self.minFps // 1,
			self.currTextColor,
			fps, 
			self.maxTextColor,
			self.maxFps // 1
		))
		
	end
end
--
function FPSgraph:setup(options)	
	local antialiasing = options.antialiasing or 2
	assert(antialiasing and antialiasing >= 0, "Step cant be less than 0!") 
	
	if (self.antialiasing ~= antialiasing) then 
		self.antialiasing = antialiasing
		if (self.mesh) then 
			self:updateMesh()
		end
	end
	
	self.font = options.font or Font.getDefault()
	self.color = options.color or 0xffffff
	self.alpha = options.alpha or 0.5
	self.textColor = options.textColor or 0
	self.textAlign = options.textAlign or 1280 | FontBase.TLF_CENTER | FontBase.TLF_VCENTER
	self.minColor = options.minColor or 0xff0000
	self.maxColor = options.maxColor or 0x00ff00
	self.updateTime = options.updateTime or 0.2
	self.minTextColor = options.minTextColor or "#000"
	self.currTextColor = options.currTextColor or "#000"
	self.maxTextColor = options.maxTextColor or "#000"
	
	self.meshHeight = self.height - self.font:getLineHeight() * 2
	self.timer = 0
	
	if (self.fpsTF) then 
		local maxTextHeight = self.height - self.meshHeight
		
		self.fpsTF:setFont(self.font)
		self.fpsTF:setTextColor(self.textColor)
		self.fpsTF:setLayout{
			w = self.width,
			h = maxTextHeight,
			flags = self.textAlign,
		}
		
		self.mesh:setY(maxTextHeight)
		self:updateMesh()
	end
	
	if (self.bg) then 
		self.bg:setColor(self.color, self.alpha)
	end
end
--
function FPSgraph:cutMesh()
	local currentPoints = #self.recentFpsData
	local preferedPoints = (self.width + self.step) // self.step
	-- if mesh is out of bounds, then cut it
	if (preferedPoints < currentPoints) then
		local diff = currentPoints - preferedPoints
		
		self.mesh:clearColorArray()
		self.mesh:clearIndexArray()
		self.mesh:clearVertexArray()
		
		for i = currentPoints, currentPoints - diff, -1 do 
			table.remove(self.recentFpsData, i)
		end	
		return true
	end	
	return false
end
--
function FPSgraph:setSize(width, height)
	if (width > 0 and height > 0 and (width ~= self.width or height ~= self.height)) then
		-- if reducing width 
		if (width < self.width) then
			self.cutLast = self:cutMesh()
		else
			self.cutLast = false 
		end
		
		self.width = width
		self.height = height
		self.meshHeight = self.height - self.font:getLineHeight() * 2
		
		local maxTextHeight = self.height - self.meshHeight
		
		self.fpsTF:setLayout{
			w = self.width,
			h = maxTextHeight,
			flags = self.textAlign,
		}
		
		self.bg:setDimensions(self.width, self.height)
		self.mesh:setY(maxTextHeight)
		self:updateMesh()
	end
end
--
function FPSgraph:setDimensions(width, height)
	self:setSize(width, height)
end
--
function FPSgraph:setStep(step)
	self.step = step
	if (self:cutMesh()) then 
		self:updateMesh()
	end
end
