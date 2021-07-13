local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()

local replicatedStorage = game:GetService("ReplicatedStorage")

local structureFolder = replicatedStorage.Structures
local DummyFolder = replicatedStorage.Dummys

local currentModel = nil
local defaultModelName = "floor"

local gameplay = true
local buildMode = false
local editMode = false

local lastPos = nil

local Grid = 12

local rot = 0

for _,v in ipairs(structureFolder:GetChildren()) do
	if v:IsA("Model") then
		local dummy = v:Clone()
		dummy.Parent = DummyFolder
		for _,p in ipairs(dummy:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 1 then
				p.Transparency = .5
				p.Material = "Neon"
				p.Color = Color3.fromRGB(129, 255, 159)
				p.CanCollide = false
			elseif p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end
end

local function SwitchDummy(name)
	
	if name == nil then
		name = defaultModelName
	end
	
	if currentModel then
		currentModel:Destroy()
	end
	currentModel = DummyFolder:FindFirstChild(name):Clone()
	currentModel.Parent = workspace
	
	local thisModel = currentModel
	
	if lastPos then
		thisModel:SetPrimaryPartCFrame(lastPos)
	end
	
	mouse.TargetFilter = thisModel
	
	spawn(function()
		repeat wait() 
			local mousePos = mouse.Hit.p
			local charPos = plr.Character.HumanoidRootPart.Position
			local direction = (mousePos - charPos).Unit
			local dist = (charPos - mousePos).magnitude
			mousePos = charPos + direction * math.clamp(dist,0, Grid/2)
			rot = math.floor(plr.Character.HumanoidRootPart.Orientation.Y / 90 +.5)*90
			local NewCFrame = CFrame.new(math.floor(mousePos.X / Grid+.5) * Grid, math.floor(mousePos.Y / Grid + .5) * Grid, math.floor(mousePos.Z / Grid+.5) * Grid) * CFrame.Angles(0,math.rad(rot),0)
			if thisModel.PrimaryPart ~= nil then
				thisModel:SetPrimaryPartCFrame(NewCFrame)
				lastPos = NewCFrame
			end
		until thisModel == nil or gameplay or editMode
	end)
end

local function UpdatePosition()
	
end

local function StartBuilding(modelName)
	gameplay = false
	buildMode = true
	SwitchDummy(modelName)
end

local function StopBuilding()
	gameplay = true
	buildMode = false
	editMode = false
	if currentModel then
		currentModel:Destroy()
	end
end

mouse.Button1Down:connect(function()
	down = true
	if buildMode then
		workspace.Building.BuildStructure:FireServer(lastPos.p, currentModel.Name, rot)
	end
end)

mouse.Button1Up:connect(function()
	down = false
end)

mouse.KeyDown:connect(function(k)
	if string.lower(k) == "q" or string.lower(k) == "c" or string.lower(k) == "v" then
		for _,v in ipairs(script.Parent.Frame:GetChildren()) do
			if v:IsA("Frame") then
				if v.Name == string.lower(k) then
					v.Size = UDim2.new(1.2,0,1.2,0)
				else
					v.Size = UDim2.new(1,0,1,0)
				end
			end
		end
	elseif string.lower(k) == "f" then
		for _,v in ipairs(script.Parent.Frame:GetChildren()) do
			if v:IsA("Frame") then
				v.Size = UDim2.new(1,0,1,0)
			end
		end
	end
	if string.lower(k) == "q" then
		StartBuilding("wall")
	elseif string.lower(k) == "c" then
		StartBuilding("floor")
	elseif string.lower(k) == "v" then
		StartBuilding("stairs")
	elseif string.lower(k) == "f" then
		StopBuilding()
	end
end)

