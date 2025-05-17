-- บริการที่ใช้
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- UI สร้างเมนู
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
frame.Size = UDim2.new(0, 220, 0, 360)
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

-- กล่องค่า
local function createTextBox(parent, yPos, placeholder)
	local box = Instance.new("TextBox", parent)
	box.Size = UDim2.new(1, -20, 0, 30)
	box.Position = UDim2.new(0, 10, 0, yPos)
	box.PlaceholderText = placeholder
	box.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Text = ""
	return box
end

local speedBox = createTextBox(frame, 40, "Speed (default 16)")
local jumpBox = createTextBox(frame, 80, "JumpPower (default 50)")
local flySpeedBox = createTextBox(frame, 120, "Fly Speed (default 50)")

-- ปุ่ม
local function createButton(parent, yPos, text)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1, -20, 0, 30)
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	return btn
end

local runButton = createButton(frame, 160, "Toggle Speed")
local jumpButton = createButton(frame, 200, "Toggle Jump")
local noclipButton = createButton(frame, 240, "Toggle NoClip")
local flyButton = createButton(frame, 280, "Toggle Fly(PC)")
local espButton = createButton(frame, 320, "Toggle ESP")

-- ตัวแปร
local isSpeedOn, isJumpOn, isNoClipOn, isFlying, isESPOn = false, false, false, false, false
local defaultSpeed, defaultJump, defaultFlySpeed = 16, 50, 50
local savedSpeed, savedJump, flySpeed = defaultSpeed, defaultJump, defaultFlySpeed
local highlights = {}
local flyDirection = Vector3.zero
local flyConnection
local bodyVelocity

-- ปุ่มเปิดเมนู
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
	if moveDir.Magnitude > 0 then
		flyDirection = moveDir.Unit * flySpeed
	else
		flyDirection = Vector3.zero
	end
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
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
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
local function toggleESP()
	isESPOn = not isESPOn
	espButton.Text = isESPOn and "ESP: ON" or "ESP: OFF"

	for _, h in pairs(highlights) do
		if h and h.Parent then h:Destroy() end
	end
	highlights = {}

	if isESPOn then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local highlight = Instance.new("Highlight")
				highlight.Name = "ESP_Highlight"
				highlight.Adornee = plr.Character
				highlight.FillColor = Color3.fromRGB(255, 0, 0)
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
			local highlight = Instance.new("Highlight")
			highlight.Name = "ESP_Highlight"
			highlight.Adornee = char
			highlight.FillColor = Color3.fromRGB(255, 0, 0)
			highlight.OutlineColor = Color3.new(1, 1, 1)
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = char
			table.insert(highlights, highlight)
		end
	end)
end)

-- เมื่อรีเกิด
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	if isSpeedOn then humanoid.WalkSpeed = savedSpeed else humanoid.WalkSpeed = defaultSpeed end
	if isJumpOn then humanoid.JumpPower = savedJump else humanoid.JumpPower = defaultJump end
	if isFlying then startFly() else stopFly() end
end)

-- ลากเมนู (รองรับทั้ง Mouse และ Touch)
local dragging = false
local dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

local function beginDrag(input)
	dragging = true
	dragStart = input.Position
	startPos = frame.Position
	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false
		end
	end)
end

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		update(input)
	end
end)
