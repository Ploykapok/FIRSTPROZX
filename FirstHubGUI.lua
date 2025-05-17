-- ส่วนนี้ไม่เปลี่ยน
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AbilityMenu"
gui.ResetOnSpawn = false

local openMenuButton = Instance.new("TextButton", gui)
openMenuButton.Size = UDim2.new(0, 100, 0, 40)
openMenuButton.Position = UDim2.new(0, 10, 0, 10)
openMenuButton.Text = "First Hub"
openMenuButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
openMenuButton.TextColor3 = Color3.new(1, 1, 1)
openMenuButton.TextSize = 18
openMenuButton.Font = Enum.Font.SourceSansBold

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 340)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Visible = false
frame.Active = true

local titleBar = Instance.new("TextLabel", frame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Text = "First Hub"
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.TextColor3 = Color3.new(1, 1, 1)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 22

-- ฟังก์ชันสร้าง TextBox
local function createTextBox(parent, pos, placeholder)
	local box = Instance.new("TextBox", parent)
	box.Size = UDim2.new(0, 140, 0, 30)
	box.Position = pos
	box.PlaceholderText = placeholder
	box.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Text = ""
	return box
end

-- ฟังก์ชันสร้างปุ่ม
local function createButton(parent, pos, text)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0, 140, 0, 30)
	btn.Position = pos
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	return btn
end

-- กล่องกรอกข้อมูล
local speedBox = createTextBox(frame, UDim2.new(0, 10, 0, 40), "Speed (default 16)")
local jumpBox = createTextBox(frame, UDim2.new(0, 150, 0, 40), "JumpPower (default 50)")
local flySpeedBox = createTextBox(frame, UDim2.new(0, 10, 0, 80), "Fly Speed (default 50)")

local espColorLabel = Instance.new("TextLabel", frame)
espColorLabel.Size = UDim2.new(0, 140, 0, 20)
espColorLabel.Position = UDim2.new(0, 150, 0, 80)
espColorLabel.BackgroundTransparency = 1
espColorLabel.Text = "ESP Color Hex:"
espColorLabel.TextColor3 = Color3.new(1,1,1)
espColorLabel.Font = Enum.Font.SourceSans
espColorLabel.TextSize = 14
espColorLabel.TextXAlignment = Enum.TextXAlignment.Left

local espColorInput = createTextBox(frame, UDim2.new(0, 150, 0, 100), "#FF0000")

-- ปุ่ม
local runButton = createButton(frame, UDim2.new(0, 10, 0, 130), "Toggle Speed")
local jumpButton = createButton(frame, UDim2.new(0, 150, 0, 130), "Toggle Jump")
local noclipButton = createButton(frame, UDim2.new(0, 10, 0, 170), "Toggle NoClip")
local flyButton = createButton(frame, UDim2.new(0, 150, 0, 170), "Toggle Fly(PC)")
local espButton = createButton(frame, UDim2.new(0, 10, 0, 210), "Toggle ESP")
local teleportButton = createButton(frame, UDim2.new(0, 150, 0, 210), "Click Teleport")

-- สถานะ
local isSpeedOn, isJumpOn, isNoClipOn, isFlying, isESPOn, isTeleporting = false, false, false, false, false, false
local defaultSpeed, defaultJump, defaultFlySpeed = 16, 50, 50
local savedSpeed, savedJump, flySpeed = defaultSpeed, defaultJump, defaultFlySpeed
local highlights = {}
local flyDirection = Vector3.zero
local flyConnection
local bodyVelocity

-- Toggle Menu
UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.LeftControl and not gp then
		frame.Visible = not frame.Visible
	end
end)
openMenuButton.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

-- Speed
runButton.MouseButton1Click:Connect(function()
	isSpeedOn = not isSpeedOn
	savedSpeed = tonumber(speedBox.Text) or defaultSpeed
	humanoid.WalkSpeed = isSpeedOn and savedSpeed or defaultSpeed
	runButton.Text = isSpeedOn and "Speed: ON" or "Speed: OFF"
end)

-- Jump
jumpButton.MouseButton1Click:Connect(function()
	isJumpOn = not isJumpOn
	savedJump = tonumber(jumpBox.Text) or defaultJump
	humanoid.JumpPower = isJumpOn and savedJump or defaultJump
	jumpButton.Text = isJumpOn and "Jump: ON" or "Jump: OFF"
end)

-- NoClip
noclipButton.MouseButton1Click:Connect(function()
	isNoClipOn = not isNoClipOn
	noclipButton.Text = isNoClipOn and "NoClip: ON" or "NoClip: OFF"
end)
RunService.Stepped:Connect(function()
	if isNoClipOn and character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end)

-- Fly
local flyKeys = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false }

local function updateFlyDirection()
	local cam = workspace.CurrentCamera
	local moveDir = Vector3.zero
	if flyKeys.W then moveDir += cam.CFrame.LookVector end
	if flyKeys.S then moveDir -= cam.CFrame.LookVector end
	if flyKeys.A then moveDir -= cam.CFrame.RightVector end
	if flyKeys.D then moveDir += cam.CFrame.RightVector end
	if flyKeys.Space then moveDir += Vector3.new(0, 1, 0) end
	if flyKeys.LeftShift then moveDir -= Vector3.new(0, 1, 0) end
	flyDirection = moveDir.Magnitude > 0 and moveDir.Unit * flySpeed or Vector3.zero
end

local function startFly()
	character = player.Character
	local hrp = character:WaitForChild("HumanoidRootPart")
	flySpeed = tonumber(flySpeedBox.Text) or defaultFlySpeed
	isFlying = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bodyVelocity.P = 2000
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = hrp

	flyConnection = RunService.RenderStepped:Connect(function()
		updateFlyDirection()
		if bodyVelocity then
			bodyVelocity.Velocity = flyDirection
		end
		local cam = workspace.CurrentCamera
		local look = cam.CFrame.LookVector
		hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(look.X, 0, look.Z))
	end)
end

local function stopFly()
	isFlying = false
	if flyConnection then flyConnection:Disconnect() end
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	humanoid.WalkSpeed = defaultSpeed
	humanoid.JumpPower = defaultJump
end

flyButton.MouseButton1Click:Connect(function()
	if isFlying then
		stopFly()
		flyButton.Text = "Fly(PC): OFF"
	else
		startFly()
		flyButton.Text = "Fly(PC): ON"
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if flyKeys[input.KeyCode.Name] ~= nil then
		flyKeys[input.KeyCode.Name] = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if flyKeys[input.KeyCode.Name] ~= nil then
		flyKeys[input.KeyCode.Name] = false
	end
end)

-- ESP
local function hexToColor3(hex)
	hex = hex:gsub("#","")
	if #hex ~= 6 then return Color3.new(1,0,0) end
	local r = tonumber(hex:sub(1,2),16)/255
	local g = tonumber(hex:sub(3,4),16)/255
	local b = tonumber(hex:sub(5,6),16)/255
	return Color3.new(r,g,b)
end

local function toggleESP()
	isESPOn = not isESPOn
	espButton.Text = isESPOn and "ESP: ON" or "ESP: OFF"
	for _, h in pairs(highlights) do if h and h.Parent then h:Destroy() end end
	highlights = {}
	if isESPOn then
		local color = hexToColor3(espColorInput.Text)
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local highlight = Instance.new("Highlight")
				highlight.Adornee = plr.Character
				highlight.FillColor = color
				highlight.OutlineColor = Color3.new(1, 1, 1)
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = plr.Character
				table.insert(highlights, highlight)
			end
		end
	end
end
espButton.MouseButton1Click:Connect(toggleESP)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		if isESPOn then
			task.wait(1)
			local color = hexToColor3(espColorInput.Text)
			local highlight = Instance.new("Highlight")
			highlight.Adornee = char
			highlight.FillColor = color
			highlight.OutlineColor = Color3.new(1, 1, 1)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = char
			table.insert(highlights, highlight)
		end
	end)
end)

-- Click Teleport + เสียง
local teleportSound = Instance.new("Sound", gui)
teleportSound.SoundId = "rbxassetid://9118823106"
teleportSound.Volume = 1

teleportButton.MouseButton1Click:Connect(function()
	isTeleporting = not isTeleporting
	teleportButton.Text = isTeleporting and "Click Teleport: ON" or "Click Teleport"
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if isTeleporting and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not gp then
		local mouse = player:GetMouse()
		local target = mouse.Hit
		if target then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 5, 0))
				teleportSound:Play()
			end
		end
	end
end)

-- On Respawn
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	if isSpeedOn then humanoid.WalkSpeed = savedSpeed else humanoid.WalkSpeed = defaultSpeed end
	if isJumpOn then humanoid.JumpPower = savedJump else humanoid.JumpPower = defaultJump end
	if isFlying then startFly() else stopFly() end
end)

-- Drag Menu
local dragging, dragStart, startPos = false, nil, nil
local function inputBegan(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end
local function inputChanged(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end
titleBar.InputBegan:Connect(inputBegan)
UserInputService.InputChanged:Connect(inputChanged)

-- Spectate
local spectateBox = createTextBox(frame, UDim2.new(0, 10, 0, 250), "Spectate Name")
local spectateButton = createButton(frame, UDim2.new(0, 150, 0, 250), "Spectate")
local originalCameraSubject = workspace.CurrentCamera.CameraSubject
local isSpectating = false

local function findPlayerByPartialName(partialName)
	partialName = partialName:lower()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Name:lower():sub(1, #partialName) == partialName then
			return plr
		end
	end
	return nil
end

spectateButton.MouseButton1Click:Connect(function()
	if isSpectating then
		local currentChar = player.Character
		if currentChar and currentChar:FindFirstChild("Humanoid") then
			workspace.CurrentCamera.CameraSubject = currentChar:FindFirstChild("Humanoid")
		end
		spectateButton.Text = "Spectate"
		isSpectating = false
	else
		local target = findPlayerByPartialName(spectateBox.Text)
		if target and target.Character and target.Character:FindFirstChild("Humanoid") then
			workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
			spectateButton.Text = "UnSpectate"
			isSpectating = true
		else
			spectateButton.Text = "Not Found"
			task.delay(1.5, function() if not isSpectating then spectateButton.Text = "Spectate" end end)
		end
	end
end)

-- TP to Player
local tpToPlayerBox = createTextBox(frame, UDim2.new(0, 10, 0, 290), "Teleport to Name")
local tpToPlayerButton = createButton(frame, UDim2.new(0, 150, 0, 290), "TP to Player")

tpToPlayerButton.MouseButton1Click:Connect(function()
	local target = findPlayerByPartialName(tpToPlayerBox.Text)
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
			teleportSound:Play()
			tpToPlayerButton.Text = "TP Success"
			task.delay(1.5, function() tpToPlayerButton.Text = "TP to Player" end)
		end
	else
		tpToPlayerButton.Text = "Not Found"
		task.delay(1.5, function() tpToPlayerButton.Text = "TP to Player" end)
	end
end)
