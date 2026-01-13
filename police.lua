-- ================== First Hub | Auto TP Outlaw + Auto Rejoin ==================

-- 🔥 ใส่ลิงก์ RAW ของสคริปต์นี้ตรงนี้
local SCRIPT_URL = "https://raw.githubusercontent.com/Ploykapok/FIRSTPROZX/refs/heads/main/police"

-- ให้รันซ้ำหลัง teleport
if queue_on_teleport then
    queue_on_teleport(game:HttpGet(SCRIPT_URL))
end

if getgenv().FirstHub_OutlawLoaded then return end
getgenv().FirstHub_OutlawLoaded = true

if getgenv().AutoTPOutlaw == nil then
    getgenv().AutoTPOutlaw = true
end

-- ================== Services ==================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FirstHub_OutlawTP"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 380)
Frame.Position = UDim2.new(0.7, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.AnchorPoint = Vector2.new(0.5,0)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundTransparency = 1
Title.Text = "First Hub | Outlaw Tracker"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = Frame

-- ================== Toggle ==================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8,0,0,40)
ToggleBtn.Position = UDim2.new(0.1,0,0.15,0)
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = Frame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0,8)

local function UpdateToggle()
    ToggleBtn.Text = getgenv().AutoTPOutlaw and "AUTO TP: ON" or "AUTO TP: OFF"
    ToggleBtn.BackgroundColor3 = getgenv().AutoTPOutlaw and Color3.fromRGB(0,150,0) or Color3.fromRGB(70,70,70)
end
UpdateToggle()

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoTPOutlaw = not getgenv().AutoTPOutlaw
    UpdateToggle()
end)

-- ================== Outlaw List ==================
local OutlawList = Instance.new("ScrollingFrame")
OutlawList.Size = UDim2.new(0.9,0,0.55,0)
OutlawList.Position = UDim2.new(0.05,0,0.35,0)
OutlawList.BackgroundColor3 = Color3.fromRGB(50,50,50)
OutlawList.BorderSizePixel = 0
OutlawList.Parent = Frame
OutlawList.ScrollBarThickness = 6
Instance.new("UICorner", OutlawList).CornerRadius = UDim.new(0,6)

local UIListLayout = Instance.new("UIListLayout", OutlawList)
UIListLayout.Padding = UDim.new(0,4)

-- ================== Closest Outlaw ==================
local function GetClosestOutlaw()
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return nil end

    local closest, shortest = nil, math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Outlaw" and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (char.PrimaryPart.Position - hrp.Position).Magnitude
                if d < shortest then
                    shortest = d
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- ================== Team Button ==================
local function CreateTeamButton(teamName, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8,0,0,35)
    btn.Position = UDim2.new(0.1,0,yPos,0)
    btn.Text = "Join "..teamName
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.MouseButton1Click:Connect(function()
        pcall(function()
            ReplicatedStorage.Remotes.RequestStartJobSession:FireServer(teamName,"jobPad")
        end)
    end)
end

CreateTeamButton("Security", 0.75)

-- ================== Main Loop ==================
task.spawn(function()
    while true do
        task.wait(0.6)

        -- refresh list
        for _, c in pairs(OutlawList:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end

        local hasOutlaw = false
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Team and plr.Team.Name == "Outlaw" then
                hasOutlaw = true
                local lb = Instance.new("TextLabel")
                lb.Size = UDim2.new(1,0,0,25)
                lb.BackgroundTransparency = 1
                lb.TextColor3 = Color3.fromRGB(255,200,50)
                lb.Font = Enum.Font.SourceSans
                lb.TextSize = 16
                lb.Text = plr.Name
                lb.Parent = OutlawList
            end
        end
        OutlawList.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y)

        if getgenv().AutoTPOutlaw then

            -- ❗ ไม่มี Outlaw → เปลี่ยนเซิร์ฟ
            if not hasOutlaw then
                task.wait(2)
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                return
            end

            -- เปลี่ยนทีม
            if LocalPlayer.Team and LocalPlayer.Team.Name ~= "Security" then
                pcall(function()
                    ReplicatedStorage.Remotes.RequestStartJobSession:FireServer("Security","jobPad")
                end)
            end

            -- TP ไป Outlaw
            local target = GetClosestOutlaw()
            local char = LocalPlayer.Character
            if target and target.Character and char and char.PrimaryPart then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    char:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0,0,-18))
                end
            end
        end
    end
end)
