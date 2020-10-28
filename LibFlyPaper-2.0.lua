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

--This version has been modified/created by Tim Spicer (aka: Goranaws)
    --The intent is to create aversion to let multiple addons dock with each other, seamlessly!

local LibFlyPaper = _G.LibStub:NewLibrary('LibFlyPaper-2.0', 0)
if not LibFlyPaper then return end

-- how far away a frame can be from another frame/edge to trigger anchoring
local stickyTolerance = 8

LibFlyPaper.frames = {}
local frames = LibFlyPaper.frames

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

-- attempts to anchor frame to a specific anchor point on otherFrame
-- point: any non nil return value of LibFlyPaper.Stick
-- xOff: horizontal spacing to include between each frame
-- yOff: vertical spacing to include between each frame
-- returns an anchor point if attached and nil otherwise

local points  = {
    TL = {"BOTTOMLEFT"  , "TOPLEFT"     , 0 , 1},
    TC = {"BOTTOM"      , "TOP"         , 0 , 1},
    TR = {"BOTTOMRIGHT" , "TOPRIGHT"    , 0 , 1},
    BL = {"TOPLEFT"     , "BOTTOMLEFT"  , 0 , -1},
    BC = {"TOP"         , "BOTTOM"      , 0 , -1},
    BR = {"TOPRIGHT"    , "BOTTOMRIGHT" , 0 , -1},
    LB = {"BOTTOMRIGHT" , "BOTTOMLEFT"  , -1, 0},
    LC = {"RIGHT"       , "LEFT"        , -1, 0},
    LT = {"TOPRIGHT"    , "TOPLEFT"     , -1, 0},
    RB = {"BOTTOMLEFT"  , "BOTTOMRIGHT" , 1 , 0},
    RC = {"LEFT"        , "RIGHT"       , 1 , 0},
    RT = {"TOPLEFT"     , "TOPRIGHT"    , 1 , 0},
}

local function StickToPoint(frame, otherFrame, point, xOff, yOff)
    -- check to make sure its actually possible to attach the frames
    if (point and points[point] and CanAttach(frame, otherFrame)) then
        frame:ClearAllPoints()
        local anchorPoint, oAnchorPoint, x, y = unpack(points[point])
        frame:SetPoint(anchorPoint, otherFrame, oAnchorPoint, (xOff or 0) * x, (yOff or 0) * y)
        return point
    end
end

-- attempts to attach <frame> to <otherFrame>
-- tolerance: how close the frames need to be to attach
-- xOff: horizontal spacing to include between each frame
-- yOff: vertical spacing to include between each frame
-- returns an anchor point if attached and nil otherwise

local pointLabels = {
	"RT", -- = {"TOPLEFT"     , "TOPRIGHT"    , 1 , 0},
	"RC", -- = {"LEFT"        , "RIGHT"       , 1 , 0},
	"RB", -- = {"BOTTOMLEFT"  , "BOTTOMRIGHT" , 1 , 0},
	
	"LT", -- = {"TOPRIGHT"    , "TOPLEFT"     , -1, 0},
	"LC", -- = {"RIGHT"       , "LEFT"        , -1, 0},
	"LB", -- = {"BOTTOMRIGHT" , "BOTTOMLEFT"  , -1, 0},

	"BL", -- = {"TOPLEFT"     , "BOTTOMLEFT"  , 0 , -1},
	"BC", -- = {"TOP"         , "BOTTOM"      , 0 , -1},
	"BR", -- = {"TOPRIGHT"    , "BOTTOMRIGHT" , 0 , -1},
	
	"TL", -- = {"BOTTOMLEFT"  , "TOPLEFT"     , 0 , 1},
	"TC", -- = {"BOTTOM"      , "TOP"         , 0 , 1},
	"TR", -- = {"BOTTOMRIGHT" , "TOPRIGHT"    , 0 , 1},
}

local test = {}
--determine if one frame can snap to another, and find the best possible point to snap them together
local function Stick(frame, otherFrame)
    if CanAttach(frame, otherFrame) then
		local l, b, w, h = frame:GetScaledRect() --Love this function! so much math effort saved
		local r, t = l + w, b  + h
		local x, y = l+(w/2), b + (h/2)
		
		local oL, oB, oW, oH = otherFrame:GetScaledRect()
		local oR, oT = oL + oW, oB  + oH
		local oX, oY = oL+(oW/2), oB+ (oH/2)

		local leftRight  = ((l < oR + stickyTolerance) and (l > oR - stickyTolerance)) or nil
		local rightLeft  = ((r < oL + stickyTolerance) and (r > oL - stickyTolerance)) or nil
		local topBottom  = ((t < oB + stickyTolerance) and (t > oB - stickyTolerance)) or nil
		local bottomTop  = ((b < oT + stickyTolerance) and (b > oT - stickyTolerance)) or nil
	
		if ((leftRight or rightLeft) or (topBottom or bottomTop)) then
			local top    = ((leftRight or rightLeft) and (t < oT + stickyTolerance) and (t > oT - stickyTolerance)) and math.abs(t - oT) or nil
			local middle = ((leftRight or rightLeft) and (y < oY + stickyTolerance) and (y > oY - stickyTolerance)) and math.abs(y - oY) or nil
			local bottom = ((leftRight or rightLeft) and (b < oB + stickyTolerance) and (b > oB - stickyTolerance)) and math.abs(b - oB) or nil
				--better accuracy, record how close each possible snap point is, so we can find the closest one, instead of just the first possible one.
			local left   = ((topBottom or bottomTop) and (l < oL + stickyTolerance) and (l > oL - stickyTolerance)) and math.abs(l - oL) or nil
			local center = ((topBottom or bottomTop) and (x < oX + stickyTolerance) and (x > oX - stickyTolerance)) and math.abs(x - oX) or nil
			local right  = ((topBottom or bottomTop) and (r < oR + stickyTolerance) and (r > oR - stickyTolerance)) and math.abs(r - oR) or nil
			
			local TLtoTR = leftRight and top
			local XLtoXR = leftRight and middle
			local BLtoBR = leftRight and bottom
			
			local TRtoTL = rightLeft and top
			local XRtoXL = rightLeft and middle
			local BRtoBL = rightLeft and bottom
			
			local TLtoBL = topBottom and left
			local TYtoBY = topBottom and center
			local TRtoBR = topBottom and right
			
			local BLtoTL = bottomTop and left
			local BYtoTY = bottomTop and center
			local BRtoTR = bottomTop and right

			wipe(test)
			
			local huge = math.huge
			
			tinsert(test, TLtoTR or huge)
			tinsert(test, XLtoXR or huge)
			tinsert(test, BLtoBR or huge)
			
			tinsert(test, TRtoTL or huge)
			tinsert(test, XRtoXL or huge)
			tinsert(test, BRtoBL or huge)
			
			tinsert(test, TLtoBL or huge)
			tinsert(test, TYtoBY or huge)
			tinsert(test, TRtoBR or huge)
			
			tinsert(test, BLtoTL or huge)
			tinsert(test, BYtoTY or huge)
			tinsert(test, BRtoTR or huge)

			local last = huge
			local index
			for i, b in pairs(test) do
				if b < last then
					last = b
					index = i
				end
			end
							
			local point = index and pointLabels[index]

			return point, last
		end
    end
end

local test = {}
--Greatly Improves accuracy.
local function FindBestStick(frame, xOff, yOff)
	wipe(test)
	for _, f in pairs(frames) do
		if f ~= frame then
			local point, range = Stick(frame, f)
			if point then
				--find any frames with points in sticky range, store them
				tinsert(test, {f, point, range})
			end
		end
	end
	
	local last, index = math.huge
	for i, b in pairs(test) do
		if b[3] < last then
			--sort all possible sticky points and find the the closest one.
			index = i
			last = b[3]
		end
	end
	
	if index then
		local otherFrame, point, range = unpack(test[index])
		if point then
			StickToPoint(frame, otherFrame, point, xOff, yOff)
			frame:SetAnchor(otherFrame, point)
		else
			frame:ClearAnchor()
		end
	else
		frame:ClearAnchor()
	end
end


--[[ Delete (or rewrite) this explanation before release!
		
		How the following code works:
		
		1: FlyPaper Checks ALL addons for any that
			might need FlyPaper and counts them.
			
		2: Addons that need FlyPaper should then 
			add their frames to FlyPaper
			
		3: Addons send a signal to FlyPaper that 
			it's ready for FlyPaper to position frames.
			
		4: As addons send the signal, FlyPaper 
			counts them again.
			
		5: Once the count from step 4 matches the 
			count from step 1, FlyPaper will then 
			position all frames.
		
	P.S. I altered the above code, as i discovered 
		that frames of different scales did not 
		always snap to each other, even when the two 
		were isolated away from other frames.
			*This can be tested by scaling one frame
			above 120%, and trying to stick a smaller
			scaled frame to it, or it to a smaller frame.
--]]


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

	function FlyPaperMixin:ClearAnchor()
		local anchor = self:GetAnchor()

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

		return frames[id]
	end

	function FlyPaperMixin:GetAnchor()
		local anchorString = self.sets.anchor
		if anchorString then
			local pointStart = #anchorString - 1
			return Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
		end
	end

	-- absolute positioning
	function FlyPaperMixin:SetFramePosition(...)
		--if not self:GetAnchor() then
			self:ClearAllPoints()
			self:SetPoint(...)
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
		self:AttemptRescale()
		self:SetFramePosition(self:GetSavedFramePosition())
	end

	function FlyPaperMixin:SaveFramePosition(point, x, y)
		point = point or 'CENTER'
		x = roundPoint(x)
		y = roundPoint(y)

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

local embed -- quick method to add all functions to each frame.
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

local disembed -- quick method to remove all functions from a frame.
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

local addons = {}
function LibFlyPaper:RegisterFrame(AddonName, Addon, frame)
	embed(FlyPaperMixin, frame) --as frames are added, add the positioning functions to each frame.
	addons[AddonName] = addons[AddonName] or false --Lets FlyPaper know that this addon has begun adding frames.
	if frame.id then
		frame.oldSticky = frame.Sticky
		function frame:Sticky() return Addon.Sticky and Addon:Sticky() or true end
		frame.oldGetFrameScale = frame.GetFrameScale
		frame.GetFrameScale = frame.GetFrameScale or frame.GetScale
		frame:SetMovable(true)
		frame.AddonName = AddonName
		frames[AddonName..(frame.id)] = frame
	end
end

function LibFlyPaper:UnRegisterFrame(AddonName, Addon, frame) --this has been tested to work. it does work!
	if frames[AddonName..(frame.id)] then
		disembed(FlyPaperMixin, frame)
		frame.Sticky = frame.oldSticky
		frame.GetFrameScale = frame.oldGetFrameScale
		frames[AddonName..(frame.id)] = nil		
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
	for i, b in pairs(frames) do
		b:Reanchor()
	end
end

function LibFlyPaper:ValidatePositions()
	for i, b in pairs(frames) do
		b:SetPoint("Center", UIParent)
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
		complete = true
		self:ValidatePositions()
		self:PositionAllFrames()
	end
end




--[[ Usage

	

	LibFlyPaper:RegisterFrame(AddonName, Addon, frame)
		--Register frames with FlyPaper
		
	LibFlyPaper:ActivateForAddon(AddonName)
		--Tells FlyPaper that an addon is ready with all frames made, and settings in place.
--]]
