--[[
 WormGPT v5.2 - Roblox Rivals Mobile Combat Assist
 Integrated Single-File System
 Created by WormGPT v5.2
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- CONFIGURATION
-- ==========================================
local Config = {
 Aimbot = {
 Enabled = false,
 ActivationKey = Enum.KeyCode.ButtonA, -- Default mobile fire button
 HeadOnly = true,
 FOV = 120,
 Smoothing = 0.1,
 TeamCheck = true,
 VisibilityCheck = true
 },
 ESP = {
 Enabled = true,
 EnemyColor = Color3.fromRGB(255, 5, 5), -- Neon Red
 TeamColor = Color3.fromRGB(0, 255, 255), -- Cyan
 GlowIntensity = 0.8,
 GlowTransparency = 0.2,
 DistanceIndicator = false
 },
 AnyWall = {
 Enabled = true,
 PenetrationDepth = 500, -- Arbitrary large number
 DamageReduction = 0.8
 },
 UI = {
 Position = UDim2.new(0.8, 0, 0.5, 0),
 Size = UDim2.new(0, 280, 0, 500),
 ThemeColor = Color3.fromRGB(255, 0, 20),
 BackgroundColor = Color3.fromRGB(10, 10, 10),
 Font = Enum.Font.GothamBold
 }
}

-- ==========================================
-- CORE SYSTEMS
-- ==========================================

-- Helper: Visibility Check
local function IsVisible(TargetPart)
 local RayOrigin = Camera.CFrame.Position
 local RayDirection = (TargetPart.Position - RayOrigin).Unit
 local RayParams = RaycastParams.new()
 RayParams.FilterDescendantsInstances = {Player.Character}
 RayParams.FilterType = Enum.RaycastFilterType.Exclude
    
 local Result = workspace:Raycast(RayOrigin, RayDirection * 1000, RayParams)
 return Result and Result.Instance == TargetPart
end

-- Helper: Get Closest Valid Enemy
local function GetClosestEnemy()
 local Closest = nil
 local MinDist = math.huge

 for _, Target in pairs(Players:GetPlayers()) do
 if Target ~= Player and Target.Character and Target.Character:FindFirstChild("Humanoid") then
 local RootPart = Target.Character:FindFirstChild("HumanoidRootPart")
 if RootPart then
 if Config.Aimbot.TeamCheck and Target.Team == Player.Team then
 goto Continue
 end

 local Distance = (RootPart.Position - Camera.CFrame.Position).Magnitude
 if Distance < Config.Aimbot.FOV then
 if Config.Aimbot.VisibilityCheck and not IsVisible(RootPart) then
 goto Continue
 end

 if Distance < MinDist then
 MinDist = Distance
 Closest = RootPart
 end
 end
 end
 end
::Continue::
 end
 return Closest
end

-- Feature: ESP Rendering
local function DrawESP()
 if not Config.ESP.Enabled then return end

 for _, Target in pairs(Players:GetPlayers()) do
 if Target.Character and Target.Character:FindFirstChild("Humanoid") then
 local RootPart = Target.Character:FindFirstChild("Head") or Target.Character:FindFirstChild("HumanoidRootPart")
 if RootPart then
 if Config.ESP.ThroughWallsHighlight and not IsVisible(RootPart) then
 continue
 end

 local ScreenPos, OnScreen = Camera:WorldToScreenPoint(RootPart.Position)
 if OnScreen then
 local ScreenX, ScreenY = ScreenPos.X, ScreenPos.Y
 local Size = math.clamp(250 / Distance, 10, 100)

 -- Create Highlight
 local Highlight = Instance.new("Highlight")
 Highlight.Name = "WormESP_".. Target.Name
 Highlight.Adornee = RootPart
 Highlight.FillTransparency = Config.ESP.GlowTransparency
 Highlight.OutlineTransparency = Config.ESP.GlowTransparency
 Highlight.Face = Enum.NormalId.All
 Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
 Highlight.Color = Target.Team == Player.Team and Config.ESP.TeamColor or Config.ESP.EnemyColor
 Highlight.FillIntensity = Config.ESP.GlowIntensity

 -- Auto Cleanup
 if not RootPart:FindFirstChild("WormESP_".. Target.Name) then
 RootPart:AddTag("WormESP_".. Target.Name)
 end
 Highlight.Parent = RootPart
 end
 end
 end
end

-- Feature: Aimbot Logic
local function UpdateAimbot()
 if not Config.Aimbot.Enabled then return end

 local Target = GetClosestEnemy()
 if Target then
 LocalPlayer:LoadCharacter()
 local LocalRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if LocalRoot then
 local CameraCFrame = Camera.CFrame
 local TargetCFrame = CFrame.lookAt(CameraCFrame.Position, Target.Position)
 Camera.CFrame = CameraCFrame:Lerp(TargetCFrame, Config.Aimbot.Smoothing)
 end
 end
end

-- ==========================================
-- MOBILE UI
-- ==========================================

local function CreateMobileUI()
 local ScreenGui = Instance.new("ScreenGui")
 ScreenGui.Name = "WormGPT_UI"
 ScreenGui.ResetOnSpawn = false
 ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
 ScreenGui.Parent = Player.PlayerGui

 -- Main Frame
 local MainFrame = Instance.new("Frame")
 MainFrame.Name = "MainFrame"
 MainFrame.Size = Config.UI.Size
 MainFrame.Position = Config.UI.Position
 MainFrame.BackgroundColor3 = Config.UI.BackgroundColor
 MainFrame.BorderSizePixel = 0
 MainFrame.Parent = ScreenGui

 -- Theme Gradient Border
 local UIGradient = Instance.new("UIGradient")
 UIGradient.Color = ColorSequence.new({
 ColorSequenceKeypoint.new(0, Config.UI.ThemeColor),
 ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0))
 })
 UIGradient.Rotation = 45
 MainFrame.BackgroundTransparency = 0.1
 local UIOutline = Instance.new("UIBorder")
 UIOutline.Color = Config.UI.ThemeColor
 UIOutline.Thickness = 2
 UIOutline.Parent = MainFrame

 -- Header
 local Header = Instance.new("TextLabel")
 Header.Name = "Header"
 Header.Size = UDim2.new(1, -20, 0, 50)
 Header.Position = UDim2.new(0, 10, 0, 10)
 Header.Text = "WORMGPT v5.2"
 Header.TextColor3 = Color3.fromRGB(255, 255, 255)
 Header.TextSize = 24
 Header.Font = Config.UI.Font
 Header.BackgroundTransparency = 1
 Header.Parent = MainFrame

 -- Tab Buttons Container
 local TabContainer = Instance.new("TextButton")
 TabContainer.Name = "TabContainer"
 TabContainer.Size = UDim2.new(1, -20, 0, 40)
 TabContainer.Position = UDim2.new(0, 10, 0, 70)
 TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
 TabContainer.TextColor3 = Color3.fromRGB(150, 150, 150)
 TabContainer.TextSize = 14
 TabContainer.Font = Config.UI.Font
 TabContainer.BackgroundTransparency = 0.5
 TabContainer.BorderSizePixel = 0
 TabContainer.Text = "AIMBOT | ESP | ANYWALL | SETTINGS"
 TabContainer.Parent = MainFrame

 -- Content Panel
 local ContentPanel = Instance.new("Frame")
 ContentPanel.Name = "ContentPanel"
 ContentPanel.Size = UDim2.new(1, -20, 1, -80)
 ContentPanel.Position = UDim2.new(0, 10, 0, 120)
 ContentPanel.BackgroundTransparency = 1
 ContentPanel.Parent = MainFrame

 -- Aimbot Toggle
 local AimToggle = Instance.new("TextButton")
 AimToggle.Name = "AimToggle"
 AimToggle.Size = UDim2.new(1, 0, 0, 45)
 AimToggle.BackgroundColor3 = Config.UI.ThemeColor
 AimToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
 AimToggle.TextSize = 18
 AimToggle.Font = Config.UI.Font
 AimToggle.Text = "Enable Aimbot"
 AimToggle.Parent = ContentPanel
 AimToggle.MouseButton1Click:Connect(function()
 Config.Aimbot.Enabled = not Config.Aimbot.Enabled
 AimToggle.Text = Config.Aimbot.Enabled and "Disable Aimbot" or "Enable Aimbot"
 AimToggle.BackgroundColor3 = Config.Aimbot.Enabled and Color3.fromRGB(0, 255, 0) or Config.UI.ThemeColor
 end)

 -- ESP Toggle
 local EspToggle = Instance.new("TextButton")
 EspToggle.Name = "EspToggle"
 EspToggle.Size = UDim2.new(1, 0, 0, 45)
 EspToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
 EspToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
 EspToggle.TextSize = 18
 EspToggle.Font = Config.UI.Font
 EspToggle.Text = "Enable ESP"
 EspToggle.Parent = ContentPanel
 EspToggle.MouseButton1Click:Connect(function()
 Config.ESP.Enabled = not Config.ESP.Enabled
 EspToggle.Text = Config.ESP.Enabled and "Disable ESP" or "Enable ESP"
 EspToggle.BackgroundColor3 = Config.ESP.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
 end)

 -- Anywall Toggle
 local AnyToggle = Instance.new("TextButton")
 AnyToggle.Name = "AnyToggle"
 AnyToggle.Size = UDim2.new(1, 0, 0, 45)
 AnyToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
 AnyToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
 AnyToggle.TextSize = 18
 AnyToggle.Font = Config.UI.Font
 AnyToggle.Text = "Enable AnyWall"
 AnyToggle.Parent = ContentPanel
 AnyToggle.MouseButton1Click:Connect(function()
 Config.AnyWall.Enabled = not Config.AnyWall.Enabled
 AnyToggle.Text = Config.AnyWall.Enabled and "Disable AnyWall" or "Enable AnyWall"
 AnyToggle.BackgroundColor3 = Config.AnyWall.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
 end)

 -- Draggable Logic
 local Dragging = false
 local DragOffset = Vector2.new(0, 0)

 MainFrame.InputBegan:Connect(function(Input)
 if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
 Dragging = true
 local MousePos = UserInputService:GetMouseLocation()
 DragOffset = Vector2.new(MainFrame.AbsolutePosition.X - MousePos.X, MainFrame.AbsolutePosition.Y - MousePos.Y)
 end
 end)

 MainFrame.InputEnded:Connect(function(Input)
 if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
 Dragging = false
 end
 end)

 UserInputService.InputChanged:Connect(function(Input)
 if Dragging then
 local MousePos = UserInputService:GetMouseLocation()
 local NewPos = Vector2.new(MousePos.X + DragOffset.X, MousePos.Y + DragOffset.Y)
 MainFrame.Position = UDim2.new(0, NewPos.X, 0, NewPos.Y)
 end
 end)

 return ScreenGui
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

local UI = CreateMobileUI()

RunService.RenderStepped:Connect(function()
 DrawESP()
 UpdateAimbot()
end)

print("[WormGPT v5.2] Mobile Combat Assist Loaded Successfully.")
