-- LibFlyPaper 2.0
-- Functionality for sticking one frame to another frame

-- Copyright 2018 Jason Greer

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

--This version has been created by Tim Spicer (aka: Goranaws)
    --The intent is to create aversion to let multiple addons dock with each other, seamlessly!

local LibFlyPaper = _G.LibStub:NewLibrary('LibFlyPaper-2.0', 0)
if not LibFlyPaper then return end

-- how far away a frame can be from another frame/edge to trigger anchoring
local stickyTolerance = 9

LibFlyPaper.framesDatabase = {}
local framesDatabase = LibFlyPaper.framesDatabase

local AllowCornerToCorner = nil
local AllowCornerToSide = true

local viableStickPoints = {
	{"TopLeft",     {
		"TopRight",
		"Right",
		"Bottom",
		"BottomLeft",
		"BottomRight", --Corner to Corner

	}},
	{"Top",         {
		"BottomLeft",
		"Bottom",
		"BottomRight",
	}},
	{"TopRight",    {
		"BottomRight",
		"Bottom",
		"Left",
		"TopLeft",
		"BottomLeft", --Corner to Corner

	}},
	{"Right",       {
		"BottomLeft",
		"Left",
		"TopLeft",
	}},
	{"BottomRight", {
		"BottomLeft",
		"Left",
		"Top",
		"TopRight",
		"TopLeft", --Corner to Corner

	}},
	{"Bottom",      {
		"TopLeft",
		"Top",
		"TopRight",
	}},
	{"BottomLeft",  {
		"TopLeft",
		"Top",
		"Right",
		"BottomRight",
		"TopRight", --Corner to Corner

	}},
	{"Left",        {
		"BottomRight",
		"Right",
		"TopRight",
	}},
}

local position = {
	BottomLeft  = { 0,  0},
	Bottom      = {.5,  0},
	BottomRight = { 1,  0},
	Right       = { 1, .5},
	TopRight    = { 1,  1},
	Top         = {.5,  1},
	TopLeft     = { 0,  1},
	Left        = { 0, .5},
}

-- returns true if <frame> or one of the frames that <frame> is dependent on
-- is anchored to <otherFrame> and nil otherwise
local function FrameIsDependentOnFrame(frame, otherFrame)
    if (frame and otherFrame) then
        if frame == otherFrame then
            return true
        end
        local points = frame:GetNumPoints()
        for i = 1, points do
            local parent = select(2, frame:GetPoint(i))
            if FrameIsDependentOnFrame(parent, otherFrame) then
                return true
            end
        end
    end
end

-- returns true if its actually possible to attach the two frames without error
local function CanAttach(frame, otherFrame)
    if not (frame and otherFrame) then
        return
    elseif FrameIsDependentOnFrame(otherFrame, frame) then
        return
    end
    return true
end

local function GetPoint(index)
	local pointIndex, oPointindex = index:sub(1, 1), index:sub(2)
	pointIndex = pointIndex and tonumber(pointIndex)
	oPointindex = oPointindex and tonumber(oPointindex)
	
	if viableStickPoints[pointIndex] then
		local point, points  = unpack(viableStickPoints[pointIndex])
		oPoint = points[oPointindex]
		return point, oPoint
	end
end

local function StickToPoint(frame, otherFrame, index)
	local point, oPoint = GetPoint(index)
    -- check to make sure its actually possible to attach the frames
    if (point and CanAttach(frame, otherFrame)) then
        frame:ClearAllPoints()
        frame:oldSetPoint(point, otherFrame, oPoint)
        return index
    end
end

-- attempts to attach <frame> to <otherFrame>
-- tolerance: how close the frames need to be to attach
-- xOff: horizontal spacing to include between each frame
-- yOff: vertical spacing to include between each frame
-- returns an anchor point if attached and nil otherwise

--Greatly Improves accuracy.
local function FindBestStick(frame, xOff, yOff)
	local range = math.huge
	local oFrame, index
	local l, b, w, h = frame:GetScaledRect() --Love this function! so much math effort saved
	
	for _, f in pairs(framesDatabase) do
		if f ~= frame and CanAttach(frame, f) then
			local point, r = nil, math.huge
			local oL, oB, oW, oH = f:GetScaledRect()
			
			
			local stickyRange = math.huge
			local pointIndex, oPointindex
			if oL and oB and oW and oH then
				for i, info in ipairs(viableStickPoints) do
					local possiblePoint, points = unpack(info)
					local num = #points
					for j, oPossiblePoint in ipairs(points) do
						local ignoreCornerToSide = (not AllowCornerToSide) and ((num == 5 and (j == 2 or j == 3)) or ((num == 3) and (j ~= 2)))
						local ignoreCornerToCorner = (not AllowCornerToCorner) and (num == 5 and (j == 5))
						
						if not (ignoreCornerToCorner or ignoreCornerToSide) then
							local x, y = unpack(position[possiblePoint])
							x = l + (w * x)
							y = b + (h * y)
							
							local oX, oY = unpack(position[oPossiblePoint])
							oX = oL + (oW * oX)
							oY = oB + (oH * oY)
							
							xDist = math.abs(oX - x)
							yDist = math.abs(oY - y)
							
							local d = math.min(xDist, yDist)
							if (xDist < stickyTolerance and yDist < stickyTolerance and d < stickyRange) then
								stickyRange = d
								pointIndex, oPointindex = i, j
							end
						end
					end
				end
			end
			if pointIndex and oPointindex then
				point, r = pointIndex..oPointindex, stickyRange
			end
			
			if point and r <= range then
				range = r
				oFrame = f
				index = point
			end
		end
	end
	
	if oFrame then
		StickToPoint(frame, oFrame, index, xOff, yOff)
		frame:SetAnchor(oFrame, index)
		frame:UpdateDocked()
	else
		frame:ClearAnchor()
	end
end

local FlyPaperMixin = {}
do
	--------------------------------------------------------------------------------
	-- Positioning Mix In

	--FlyPaper must handle all positioning, so that saved
	--frame position and anchors are consistent between addons.
	--------------------------------------------------------------------------------
	
	-- how far away a frame can be from another frame/edge to trigger anchoring
	FlyPaperMixin.stickyTolerance = stickyTolerance

	-- edge anchoring
	function FlyPaperMixin:StickToEdge()
		local point, x, y = self:GetRelativeFramePosition()
		local rTolerance = self.stickyTolerance
		local changed = false

		if abs(x) <= rTolerance then
			x = 0
			changed = true
		end

		if abs(y) <= rTolerance then
			y = 0
			changed = true
		end

		--save this junk if we've done something
		if changed then
			self:SetAndSaveFramePosition(point, x, y)
		end
	end

	-- bar anchoring
	function FlyPaperMixin:Stick()
		self:ClearAnchor()
		-- only do sticky code if the alt key is not currently down
		if self:Sticky() and not IsAltKeyDown() then
			-- try to stick to a bar, then try to stick to a screen edge
			FindBestStick(self)	
			if not self:GetAnchor() then
				self:StickToEdge()
			end
		end
		self:SaveRelativeFramePosition()
	end

	function FlyPaperMixin:Reanchor()
		local f, point = self:GetAnchor()

		if not (f and StickToPoint(self, f, point)) then
			self:ClearAnchor()
			self:Reposition()
		else
			self:SetAnchor(f, point)
		end
	end

	function FlyPaperMixin:UpdateDocked(initiator)
		if self ~= initiator and self.docked then
			for i, b in pairs(self.docked) do
				if b ~= self then
					if b.docked then
						b:UpdateDocked(initiator or self)
					end
					b:SaveRelativeFramePosition()
				end
			end
		end
	end

	function FlyPaperMixin:SetAnchor(anchor, point)
		self:ClearAnchor()
		if anchor.docked then
			local found = false
			for i, f in pairs(anchor.docked) do
				if f == self then
					found = i
					break
				end
			end
			if not found then
				tinsert(anchor.docked, self)
			end
		else
			anchor.docked = {self}
		end

		self.sets.anchor = anchor.AddonName .. anchor.id .. point
		if self.UpdateWatched then
			self:UpdateWatched()
			self:UpdateAlpha()
		end
	end

	function FlyPaperMixin:ClearAnchor(anchor)
		local anchor = anchor or self:GetAnchor()

		if anchor and anchor.docked then
			for i, f in pairs(anchor.docked) do
				if f == self then
					tremove(anchor.docked, i)
					break
				end
			end

			if not next(anchor.docked) then
				anchor.docked = nil
			end
		end

		self.sets.anchor = nil
		if self.UpdateWatched then
			self:UpdateWatched()
			self:UpdateAlpha()
		end
	end

	local function Get(id)

		return framesDatabase[id]
	end

	function FlyPaperMixin:GetAnchor()
		local anchorString = self.sets.anchor
		if anchorString then
			local pointStart = #anchorString
			local oFrame, pointIndex = Get(anchorString:sub(1, pointStart - 2)), anchorString:sub(pointStart-1)
			if oFrame and GetPoint(pointIndex) then
				return oFrame, pointIndex
			else
				self:ClearAnchor(anchorString:sub(pointStart-1))
			end
		end
	end

	-- absolute positioning
	function FlyPaperMixin:SetFramePosition(...)
		--if not self:GetAnchor() then
			self:ClearAllPoints()
			self:oldSetPoint(...)
		--end
	end

	function FlyPaperMixin:SetAndSaveFramePosition(point, x, y)
		self:SetFramePosition(point, x, y)
		self:SaveFramePosition(point, x, y)
	end

	-- relative positioning
	function FlyPaperMixin:SaveRelativeFramePosition()
		self:SaveFramePosition(self:GetRelativeFramePosition())
	end

	function FlyPaperMixin:GetRelativeFramePosition()
		local scale = self:GetScale() or 1
		local left = self:GetLeft() or 0
		local top = self:GetTop() or 0
		local right = self:GetRight() or 0
		local bottom = self:GetBottom() or 0

		local parent = self:GetParent() or UIParent
		local pwidth = parent:GetWidth() / scale
		local pheight = parent:GetHeight() / scale

		local x, y, point
		if left < (pwidth - right) and left < abs((left + right) / 2 - pwidth / 2) then
			x = left
			point = 'LEFT'
		elseif (pwidth - right) < abs((left + right) / 2 - pwidth / 2) then
			x = right - pwidth
			point = 'RIGHT'
		else
			x = (left + right) / 2 - pwidth / 2
			point = ''
		end

		if bottom < (pheight - top) and bottom < abs((bottom + top) / 2 - pheight / 2) then
			y = bottom
			point = 'BOTTOM' .. point
		elseif (pheight - top) < abs((bottom + top) / 2 - pheight / 2) then
			y = top - pheight
			point = 'TOP' .. point
		else
			y = (bottom + top) / 2 - pheight / 2
		end

		if point == '' then
			point = 'CENTER'
		end

		return point, x, y
	end

	-- loading and positioning
	local function roundPoint(point)
		point = point or 0

		if point > 0 then
			point = floor(point + 0.5)
		else
			point = ceil(point - 0.5)
		end

		return point
	end

	function FlyPaperMixin:AttemptRescale()
		return self.Rescale and self:Rescale() or function() end
	end

	function FlyPaperMixin:Reposition()
		--self:AttemptRescale()
		self:SetFramePosition(self:GetSavedFramePosition())
	end

	function FlyPaperMixin:SaveFramePosition(point, x, y)
		point = point or 'CENTER'
		--x = roundPoint(x) --why intentionally loose precision? loss is not worth data saved.
		--y = roundPoint(y) --why intentionally loose precision? loss is not worth data saved.

		local sets = self.sets
		sets.point = point ~= 'CENTER' and point or nil
		sets.x = x ~= 0 and x or nil
		sets.y = y ~= 0 and y or nil

		self:SetUserPlaced(true)
	end

	function FlyPaperMixin:GetSavedFramePosition()
		local sets = self.sets
		local point = sets.point or 'CENTER'
		local x = sets.x or 0
		local y = sets.y or 0

		return point, x, y
	end
end

-- quick method to add all functions to each frame.
local embed
embed = function(source, destination)
	destination.storeForDisembed = destination.storeForDisembed or {} -- need to restore anything rewritten when a frame is removed
	for i, b in pairs(source) do
		destination.storeForDisembed[i] = destination[i]
		if type(b) == "table" then
			destination[i] = embed(b, {})
		else
			destination[i] = b
		end
 	end
	return destination
end

-- quick method to remove all functions from a frame.
local disembed
disembed = function(source, destination)
	if destination.storeForDisembed then
		for i, b in pairs(source) do
			if type(b) == "table" then
				disembed(b, destination[i])
			else
				destination[i] = destination.storeForDisembed[i]
			end
		end
		return destination
	end
end

local function frameHasMovedOrResized(frame, reason)
	if not LibFlyPaper.Ready then return end
	print(frame.id, reason)
	if reason == "isMoving" then
		--placeholder for now
			--Perhaps allow active snapping attempts, while frame is moving
	elseif reason == "Save" then
		frame:SaveRelativeFramePosition()
	elseif reason == "hasMoved" then
		frame:Stick()
	elseif reason == "sizeChanged" then
		frame:Reanchor()
	end
end

local addons = {}

local names = {}
local ids = {}
local NameGenerator
NameGenerator = function (AddonName)
	ids[AddonName] = ids[AddonName] or {}
	names[AddonName] = names[AddonName] and names[AddonName] + 1 or 1

	if ids[AddonName][names[AddonName]] then
		return NameGenerator(AddonName)
	end

	return AddonName..names[AddonName]
end

function LibFlyPaper:RegisterFrame(AddonName, Addon, frame)
	
	frame.id = frame.id or frame.ID or frame.Id or frame.iD or frame:GetName()
	if not frame.id then
		--frame.id =  NameGenerator(AddonName)
	else
		ids[AddonName] = ids[AddonName] or {}
	end

	if frame.id and framesDatabase[AddonName..(frame.id)] then
		return
	end

	embed(FlyPaperMixin, frame) --as frames are added, add the positioning functions to each frame.
	if frame.id then
		ids[AddonName][frame.id] = frame.id
		addons[AddonName] = addons[AddonName] or false --Lets FlyPaper know that this addon has begun adding frames.
		frame.oldSticky = frame.Sticky
		function frame:Sticky() return Addon.Sticky and Addon:Sticky() or true end
		frame.oldGetFrameScale = frame.GetFrameScale
		frame.GetFrameScale = frame.GetFrameScale or frame.GetScale
		frame:SetMovable(true)
		frame:SetUserPlaced(true)
		frame.AddonName = AddonName
		framesDatabase[AddonName..(frame.id)] = frame
		frame.sets = frame.sets or {}
		frame.embeded = true
		do --add call backs to any functions an addon might call, so that FlyPaper can handle sticky
			frame.oldSetPoint = frame.SetPoint
			function frame:SetPoint(...)
				 local parent = select(2, {...})
			
				if  (not _G[parent])  or CanAttach(frame, parent) then
					local f = {frame:oldSetPoint(...)}
					if frame.embeded then
						frameHasMovedOrResized(frame, "Save")
					end
					return unpack(f)
				end
			end

			frame.oldSetAllPoints = frame.SetAllPoints
			function frame:SetAllPoints(...)
				local f = {frame:oldSetAllPoints(...)}
				if frame.embeded then
					frameHasMovedOrResized(frame, "hasMoved")
				end
				return unpack(f)
			end
			
			frame.oldStopMovingOrSizing = frame.StopMovingOrSizing
			function frame:StopMovingOrSizing(...)
				local f = {frame:oldStopMovingOrSizing(...)}
				if frame.embeded then
					frameHasMovedOrResized(frame, "hasMoved")
				end
				return unpack(f)
			end

			frame.oldSetScale = frame.SetScale
			local lastScale = frame:GetScale()
			function frame:SetScale(scale)
				if lastScale~=scale then
					local f = {frame:oldSetScale(scale)}
					if frame.embeded then
						frameHasMovedOrResized(frame, "sizeChanged")
					end
					lastScale = scale
					return unpack(f)
				end
			end

			frame.oldSetWidth = frame.SetWidth                       --save the old function and make it accessible
			local lastW, last = frame:GetSize()                      --store the start values
			function frame:SetWidth(w)                               --create the replacement
				if lastW~=w then                                     --ignore the call, unless something is going to change.
					local f = {frame:oldSetWidth(w)}                 --call the old function, and store any return values
					if frame.embeded then                            --if we've unregistered a frame, ignore callback
						frameHasMovedOrResized(frame, "sizeChanged") --make the callBack
					end
					lastW = w                                         --store new value, so we can track changes
					return unpack(f)                                  --return any return values from old function call
				end
			end

			frame.oldSetHeight = frame.SetHeight
			function frame:SetHeight(h)
				if lastH~=h then
					local f = {frame:oldSetHeight(h)}
					if frame.embeded then
						frameHasMovedOrResized(frame, "sizeChanged")
					end
					lastH = h
					return unpack(f)
				end
			end

			frame.oldSetSize = frame.SetSize
			function frame:SetSize(w, h)
				if lastH~=h or lastW ~=w then
					local f = {frame:oldSetSize(w, h)}
					if frame.embeded then
						frameHasMovedOrResized(frame, "sizeChanged")
					end
					lastH = h
					lastW = W
					return unpack(f)
				end
			end
		end
	end
end

function LibFlyPaper:UnRegisterFrame(AddonName, Addon, frame) --this has been tested to work. it does work!
	if framesDatabase[AddonName..(frame.id)] then
		disembed(FlyPaperMixin, frame)
		frame.Sticky = frame.oldSticky
		frame.GetFrameScale = frame.oldGetFrameScale
		framesDatabase[AddonName..(frame.id)] = nil		
		frame.embeded = nil
	end
end

local registeredAddons = {}
local numAddons = 0
function LibFlyPaper:FindDependencies()
	--locate any addons that rely on FlyPaper, and count them.
		--this function is only run once, so the two tables made here are only made once.
	local num = GetNumAddOns()
	for i = 1, num do
		for _, depName in pairs({GetAddOnDependencies(i)}) do
			if tostring(depName) == "LibFlyPaper" then
				--if an addon needs FlyPaper, add it to the list
				numAddons = numAddons + 1
			end			
		end
		for _, depName in pairs({GetAddOnOptionalDependencies(i)}) do
			if tostring(depName) == "LibFlyPaper" then
				--if an addon needs FlyPaper, add it to the list
				numAddons = numAddons + 1
			end			
		end
	end
end

local _count = 0 
local function count(_table)
	_count = 0
	
	for i, b in pairs(_table) do
		_count = _count + 1
	end
	
	return _count
end

function LibFlyPaper:PositionAllFrames()
	for i, b in pairs(framesDatabase) do
		b:Reanchor()
	end
end

function LibFlyPaper:ValidatePositions()
	for i, b in pairs(framesDatabase) do
		b:ClearAllPoints()
		b:SetUserPlaced(true)
		b:SetMovable(true)
		b:oldSetPoint("Center", UIParent)
	end
end

local paper = embed(LibFlyPaper, CreateFrame("Frame"))

paper:RegisterEvent("ADDON_LOADED")

local runOnce
paper:SetScript("OnEvent", function(self, event, name, ...)
	self:FindDependencies()
	self:UnregisterEvent("ADDON_LOADED")
end)

local triggered = 0
local complete
function LibFlyPaper:ActivateForAddon(AddonName)
	--Signals to FlyPaper that an Addon is ready, all its frames are made, and settings are active.
	if addons[AddonName] == false then
		addons[AddonName] = true
		triggered = triggered + 1
	end
	
	local ready = true
	for i, b in pairs(addons) do
		if b == false then
			ready = nil
		end
	end

	if (not complete) and ready and count(addons) == triggered then
		--once all addons are ready, trigger FlyPaper to place everything.
		self:ValidatePositions() -- Make sure all frames are on screen, before placing them.
		self:PositionAllFrames() -- Place all frames.
		complete = true
	end
	
	self.Ready = complete
end




--[[ Usage
	LibFlyPaper:RegisterFrame(AddonName, Addon, frame)
		--Register frames with FlyPaper
		
	LibFlyPaper:ActivateForAddon(AddonName)
		--Tells FlyPaper that an addon is ready with all frames made, and settings in place.
--]]
