# LibFlyPaper-2.0

--[[
I realize that many of the changes are drastic. Many can be reverted back to LibFlyPaper-1.0 style
     
    Design Description
		Step one: Addons register each frame
			  A: FlyPaper checks that each frame has a valid id
			  B: FlyPaper takes note that an addon has begun registering frames
			  C: FlyPaper embeds the mixin into a registered frame
			  D: FLyPaper ensures a few Dominos specific things get attention
			  E: Frame is add to the framesDatabase
			  F: Flypaper adds script hooks to specific frame functions, to help enable seamless sticky
		Step two: Addons signal that they have created all frames, and all settings have been activated.
			  A: This first addon to activate, triggers FlyPaper to check ALL addons for any that rely on FlyPaper and counts them.
			  B: As addons activate, FlyPaper counts them.
			  C: Once the counts from A & B match, FlyPaper begins placing all frames.
                  
    frame placement:
		-Register frames with FlyPaper:RegisterFrame(AddonName, Addon, frame)
		-once all frame are made, Activate with FlyPaper:ActivateForAddon(AddonName)
		-Addons don't need to make any calls to set a frame's position. 
		-Addons only need to ensure that a frame's StopMovingOrSizing function is called, to trigger FlyPaper to attempt sticking a frame to another frame.
		-if a frame's size or scale is changed, it triggers FlyPaper to update the frames position accurately.
 
		Step one: a frame's StopMovingOrSizing is called
		Step two: FlyPaper is hooked to know when StopMovingOrSizing is called, so it triggers frame:Stick()
		Step three: FlyPaper checks frameDatabase for any frame in sticky range, and sticks to the nearest one.
			A: Compare all viable combinations(listed in viableStickPoints) of "points" of a "frame" to all "otherPoints" on all "otherFrames"(listed in framesDatabase) ex: frame:SetPoint(point, otherFrame, otherPoint)
			B: if points are in stickyTolerance, the stickyRange is recorded.
			C: as stickyRange is recorded, we check for the combination that is closest.
			D: once all combinations have been checked, select and save the one that is closest. if none is found, clear any existing anchor save data
			E: if no points are in range, check for screen snapping.
			F:if no no sticky or screen snap, drop the frame where it is.
			F: save the frames location.
			  -frame anchors are no longer stored with letters. the format now follows:
			  
					 sets.anchor = "Dominos111" --this refers to dominos frame 1, stickied TopRight to TopLeft (1 = TopRight, 1  = "TopLeft") as listed in table below
					 sets.anchor = "Dominos122" --this refers to dominos frame 1, stickied Top to Bottom (2 = Top, 2  = "Bottom") as listed in table below
					
						local viableStickPoints = {
								{"TopLeft", {
									"TopRight",
									"Right",
									"Bottom",
									"BottomLeft",
									"BottomRight", --Corner to Corner -- can bet set enabled or not.

								}},
								{"Top", {
									"BottomLeft",
									"Bottom",
									"BottomRight",
								}},
								{"TopRight", {
									"BottomRight",
									"Bottom",
									"Left",
									"TopLeft",
									"BottomLeft", --Corner to Corner

								}},
								{"Right", {
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
								{"Bottom", {
									"TopLeft",
									"Top",
									"TopRight",
								}},
								{"BottomLeft", {
									"TopLeft",
									"Top",
									"Right",
									"BottomRight",
									"TopRight", --Corner to Corner

								}},
								{"Left", {
									"BottomRight",
									"Right",
									"TopRight",
								}},
						  }
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
			  
			  
			  
			G: save the location of any frames that are anchored to this frame.
--]]



--[[
 Sticky Points
		I'm not sure how best to describe what i have written, so I'll just make a list of what i can think of. I may clarify and organize this later.
		The diagram below details all viable stick points.
		They are numbered clockwise, starting with  the TopLeft corner and TopRight corner
		the numbers inside the rectangle are for otherFrame, the numbers on the outside reference different points of the moving frame that can stick to otherFrame
		
		when saved, they are stored in pairs.
		"otherFrameName43" = frame:SetPoint("TopLeft", otherFrame, "Right")
		"otherFrameName81" = frame:SetPoint("Right", otherFrame, "Left")
 
--     _3_       _2_       _2_
--      |         |         |
--   |_5|4_______1|3_______1|5_|3     --the count on corners go 1 2 5 3 4, intentionally out of sequence.
--  2| 1|1        2        3|4 |       --i want corner to corner options listed last later one.
--      |                   |         --allows me to make corner to corner optional 
--  2|_3|                   |1_|2
--   | 1|8                 4|3 |
--      |                   |
--      |                   |
--  3|_4|7________6________5|1
--   | 5|1       3|1       4|5 |2
--     _|_       _|_       _|_
--     2         2         4
	  
	  the table below is derived from the previous diagram.
				
			local viableStickPoints = {
				[1] = {"TopLeft",
					{
						[1] = "TopRight",
						[2] = "Right",
						[5] = "BottomRight", --Corner to corner --Intentionally labeled out of sequence.
						[3] = "Bottom",
						[4] = "BottomLeft",
					},
				},
				[2] = {"Top",
					{
						[1] = "BottomLeft",  
						[2] = "Bottom",      
						[3] = "BottomRight", 
					},
				},
				[3] = {"TopRight",
					{
						[1] = "BottomRight", 
						[2] = "Bottom", 
						[5] = "BottomLeft",  --Corner to corner
						[3] = "Left",       
						[4] = "TopLeft",    
					}
				},
				[4] = {"Right",
					{
						[1] = "BottomLeft",  
						[2] = "Left",        
						[3] = "TopLeft",     
					},
				},
				[5] = {"BottomRight",
					{
						[1] = "BottomLeft",  
						[2] = "Left",        
						[5] = "TopLeft",     --Corner to corner
						[3] = "Top",         
						[4] = "TopRight",    
					},
				},
				[6] = {"Bottom",
					{
						[1] = "TopLeft",     -- [1]
						[3] = "Top",         -- [2]
						[4] = "TopRight",    -- [3]
					},
				},
				[7] = {"BottomLeft",
					{
						[1] = "TopLeft",     
						[2] = "Top",         
						[5] = "TopRight",    --Corner to corner
						[3] = "Right",       
						[4] = "BottomRight",
					},
				},
				[8] = {"Left",
					{
						[1] = "BottomRight",
						[2] = "Right",       
						[3] = "TopRight",    
					},
				},
			}
	  
		Saved anchors are decode with the following function:
		
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

	  ex. GetPoint(52) returns "BottomRight", "Left"
	  
	  
	  Function FindBestStick at line 161, replaces the old sticky code.
		It takes a frame and checks it against all points on all otherFrames for any that are in stickyTolerance range.
		If any are found, it selects the most likely one, based on which set of points on frame are nearest to points on otherFrame.
		The old version only checked for the first possible option in range. new version checks ALL and prioritizes the nearest.
--]]

