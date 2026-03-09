--[[
    FORSAKEN MOBILE MENU v24.0
    ИЗМЕНЕНИЯ:
    - TP Slash: после орбиты возвращает на исходную позицию
    - Убран Auto Generator
    - TP Hit по ЛКМ (рывок к игроку и обратно)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local TouchEnabled = UserInputService.TouchEnabled
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

repeat wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- АНТИ-АФК
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ПЕРЕМЕННЫЕ
local MenuVisible = false
local FlyEnabled = false
local NoclipEnabled = false
local TPWalkEnabled = false
local ESPEnabled = false
local AimbotEnabled = false
local AimbotActive = false
local TPSlashEnabled = false
local TPHitEnabled = false
local CtrlClickTPEnabled = false
local TPSlashCooldown = false
local TPHitCooldown = false
local TPWalkSpeed = 0.02
local BodyFly = nil
local NoclipConnection = nil
local TPWalkConnection = nil
local CurrentTab = "ИГРОК"
local AimbotTarget = nil
local ESPHighlights = {}

-- ПАРАМЕТРЫ TP SLASH (С ВОЗВРАТОМ)
local ORBIT_RADIUS = 5
local ORBIT_SPEED = 8
local ORBIT_DURATION = 2.5
local ORBIT_COOLDOWN = 20
local ORBIT_HEIGHT = 2

-- ПАРАМЕТРЫ TP HIT
local TP_HIT_DURATION = 0.5
local TP_HIT_COOLDOWN = 3

-- РАЗМЕРЫ GUI
local ViewportSize = Camera.ViewportSize
local ScreenWidth = ViewportSize.X
local ScreenHeight = ViewportSize.Y

local MenuWidth = math.min(500, ScreenWidth * 0.9)
local MenuHeight = math.min(450, ScreenHeight * 0.8)
local ButtonSize = math.min(60, ScreenWidth * 0.1)
local AimbotButtonSize = math.min(70, ScreenWidth * 0.1)

-- ЦВЕТОВАЯ СХЕМА
local colors = {
    bg = Color3.fromRGB(18, 18, 22),
    bg2 = Color3.fromRGB(25, 25, 32),
    accent = Color3.fromRGB(0, 162, 255),
    text = Color3.fromRGB(220, 220, 220),
    text2 = Color3.fromRGB(150, 150, 150),
    red = Color3.fromRGB(240, 80, 80),
    green = Color3.fromRGB(80, 200, 120),
    white = Color3.fromRGB(255, 255, 255),
    border = Color3.fromRGB(45, 45, 55),
    purple = Color3.fromRGB(160, 100, 255),
    orange = Color3.fromRGB(255, 140, 0)
}

-- ========== СОЗДАНИЕ GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XONEMobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

if TouchEnabled then
    ScreenGui.IgnoreGuiInset = true
end

local parentSuccess = false
local possibleParents = {
    game:GetService("CoreGui"),
    LocalPlayer:FindFirstChild("PlayerGui"),
    LocalPlayer.PlayerGui
}

for _, parent in pairs(possibleParents) do
    if parent then
        local success = pcall(function()
            ScreenGui.Parent = parent
        end)
        if success then
            parentSuccess = true
            break
        end
    end
end

if not parentSuccess then
    local folder = Instance.new("Folder")
    folder.Name = "MenuFolder"
    folder.Parent = LocalPlayer
    ScreenGui.Parent = folder
end

-- ========== КНОПКА ОТКРЫТИЯ ==========
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, ButtonSize, 0, ButtonSize)
OpenButton.Position = UDim2.new(0, 20, 0.5, -ButtonSize/2)
OpenButton.BackgroundColor3 = colors.accent
OpenButton.BackgroundTransparency = 0.2
OpenButton.Text = "X"
OpenButton.TextColor3 = Color3.new(1, 1, 1)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = ButtonSize * 0.5
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, ButtonSize/2)
OpenCorner.Parent = OpenButton

-- ========== КНОПКА АИМБОТА ==========
local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(0, AimbotButtonSize, 0, AimbotButtonSize)
AimbotButton.Position = UDim2.new(1, -AimbotButtonSize - 20, 1, -AimbotButtonSize - 20)
AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AimbotButton.Text = "АИМ"
AimbotButton.TextColor3 = Color3.new(1, 1, 1)
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.TextSize = AimbotButtonSize * 0.25
AimbotButton.Visible = false
AimbotButton.Active = true
AimbotButton.Draggable = true
AimbotButton.Parent = ScreenGui

local AimbotCorner = Instance.new("UICorner")
AimbotCorner.CornerRadius = UDim.new(0, AimbotButtonSize/2)
AimbotCorner.Parent = AimbotButton

local AimbotIndicator = Instance.new("Frame")
AimbotIndicator.Size = UDim2.new(0, AimbotButtonSize * 0.25, 0, AimbotButtonSize * 0.25)
AimbotIndicator.Position = UDim2.new(0.5, -AimbotButtonSize * 0.125, 0.5, -AimbotButtonSize * 0.125)
AimbotIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AimbotIndicator.BackgroundTransparency = 0.5
AimbotIndicator.Visible = false
AimbotIndicator.Parent = AimbotButton

local IndicatorCorner = Instance.new("UICorner")
IndicatorCorner.CornerRadius = UDim.new(0, AimbotButtonSize * 0.125)
IndicatorCorner.Parent = AimbotIndicator

-- ========== ОСНОВНОЕ МЕНЮ ==========
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, MenuWidth, 0, MenuHeight)
MainFrame.Position = UDim2.new(0.5, -MenuWidth/2, 0.5, -MenuHeight/2)
MainFrame.BackgroundColor3 = colors.bg
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = colors.border
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

-- Верхняя полоса
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, MenuHeight * 0.09)
TitleBar.BackgroundColor3 = colors.bg2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, MenuWidth * 0.14, 1, 0)
Logo.Position = UDim2.new(0, 8, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "XONE"
Logo.TextColor3 = colors.accent
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = MenuHeight * 0.045
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = TitleBar

local GameTitle = Instance.new("TextLabel")
GameTitle.Size = UDim2.new(0, MenuWidth * 0.25, 1, 0)
GameTitle.Position = UDim2.new(0, MenuWidth * 0.15, 0, 0)
GameTitle.BackgroundTransparency = 1
GameTitle.Text = "| FORSAKEN"
GameTitle.TextColor3 = colors.text2
GameTitle.Font = Enum.Font.GothamSemibold
GameTitle.TextSize = MenuHeight * 0.04
GameTitle.TextXAlignment = Enum.TextXAlignment.Left
GameTitle.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, MenuWidth * 0.15, 1, 0)
VersionLabel.Position = UDim2.new(0, MenuWidth * 0.4, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v24.0"
VersionLabel.TextColor3 = colors.text2
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextSize = MenuHeight * 0.035
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, MenuHeight * 0.06, 0, MenuHeight * 0.06)
CloseButton.Position = UDim2.new(1, -MenuHeight * 0.08, 0.5, -MenuHeight * 0.03)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseButton.Text = "✕"
CloseButton.TextColor3 = colors.text
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = MenuHeight * 0.03
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, MenuHeight * 0.01)
CloseCorner.Parent = CloseButton

-- ========== ВКЛАДКИ ==========
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(1, 0, 0, MenuHeight * 0.08)
TabsFrame.Position = UDim2.new(0, 0, 0, MenuHeight * 0.09)
TabsFrame.BackgroundColor3 = colors.bg2
TabsFrame.BorderSizePixel = 0
TabsFrame.Parent = MainFrame

local TabWidth = (MenuWidth - 50) / 5

local PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.new(0, TabWidth, 1, 0)
PlayerTab.Position = UDim2.new(0, 8, 0, 0)
PlayerTab.BackgroundTransparency = 1
PlayerTab.Text = "ИГРОК"
PlayerTab.TextColor3 = colors.accent
PlayerTab.Font = Enum.Font.GothamBold
PlayerTab.TextSize = MenuHeight * 0.022
PlayerTab.Parent = TabsFrame

local VisualTab = Instance.new("TextButton")
VisualTab.Size = UDim2.new(0, TabWidth, 1, 0)
VisualTab.Position = UDim2.new(0, 12 + TabWidth, 0, 0)
VisualTab.BackgroundTransparency = 1
VisualTab.Text = "ВИЗУАЛ"
VisualTab.TextColor3 = colors.text2
VisualTab.Font = Enum.Font.GothamBold
VisualTab.TextSize = MenuHeight * 0.022
VisualTab.Parent = TabsFrame

local TeleportTab = Instance.new("TextButton")
TeleportTab.Size = UDim2.new(0, TabWidth, 1, 0)
TeleportTab.Position = UDim2.new(0, 16 + (TabWidth * 2), 0, 0)
TeleportTab.BackgroundTransparency = 1
TeleportTab.Text = "ТЕЛЕПОРТ"
TeleportTab.TextColor3 = colors.text2
TeleportTab.Font = Enum.Font.GothamBold
TeleportTab.TextSize = MenuHeight * 0.022
TeleportTab.Parent = TabsFrame

local CombatTab = Instance.new("TextButton")
CombatTab.Size = UDim2.new(0, TabWidth, 1, 0)
CombatTab.Position = UDim2.new(0, 20 + (TabWidth * 3), 0, 0)
CombatTab.BackgroundTransparency = 1
CombatTab.Text = "БОЙ"
CombatTab.TextColor3 = colors.text2
CombatTab.Font = Enum.Font.GothamBold
CombatTab.TextSize = MenuHeight * 0.022
CombatTab.Parent = TabsFrame

local ItemsTab = Instance.new("TextButton")
ItemsTab.Size = UDim2.new(0, TabWidth, 1, 0)
ItemsTab.Position = UDim2.new(0, 24 + (TabWidth * 4), 0, 0)
ItemsTab.BackgroundTransparency = 1
ItemsTab.Text = "ПРЕДМЕТЫ"
ItemsTab.TextColor3 = colors.text2
ItemsTab.Font = Enum.Font.GothamBold
ItemsTab.TextSize = MenuHeight * 0.022
ItemsTab.Parent = TabsFrame

local TabIndicator = Instance.new("Frame")
TabIndicator.Size = UDim2.new(0, TabWidth, 0, 2)
TabIndicator.Position = UDim2.new(0, 8, 1, -2)
TabIndicator.BackgroundColor3 = colors.accent
TabIndicator.BorderSizePixel = 0
TabIndicator.Parent = TabsFrame

-- ========== КОНТЕЙНЕРЫ ==========
local ContainerY = MenuHeight * 0.18
local ContainerHeight = MenuHeight * 0.73

local PlayerContainer = Instance.new("Frame")
PlayerContainer.Size = UDim2.new(1, -20, 0, ContainerHeight)
PlayerContainer.Position = UDim2.new(0, 10, 0, ContainerY)
PlayerContainer.BackgroundTransparency = 1
PlayerContainer.Visible = true
PlayerContainer.Parent = MainFrame

local VisualContainer = Instance.new("Frame")
VisualContainer.Size = UDim2.new(1, -20, 0, ContainerHeight)
VisualContainer.Position = UDim2.new(0, 10, 0, ContainerY)
VisualContainer.BackgroundTransparency = 1
VisualContainer.Visible = false
VisualContainer.Parent = MainFrame

local TeleportContainer = Instance.new("Frame")
TeleportContainer.Size = UDim2.new(1, -20, 0, ContainerHeight)
TeleportContainer.Position = UDim2.new(0, 10, 0, ContainerY)
TeleportContainer.BackgroundTransparency = 1
TeleportContainer.Visible = false
TeleportContainer.Parent = MainFrame

local CombatContainer = Instance.new("Frame")
CombatContainer.Size = UDim2.new(1, -20, 0, ContainerHeight)
CombatContainer.Position = UDim2.new(0, 10, 0, ContainerY)
CombatContainer.BackgroundTransparency = 1
CombatContainer.Visible = false
CombatContainer.Parent = MainFrame

local ItemsContainer = Instance.new("Frame")
ItemsContainer.Size = UDim2.new(1, -20, 0, ContainerHeight)
ItemsContainer.Position = UDim2.new(0, 10, 0, ContainerY)
ItemsContainer.BackgroundTransparency = 1
ItemsContainer.Visible = false
ItemsContainer.Parent = MainFrame

-- Разделители
local function addSeparator(parent, yPos)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = UDim2.new(0, 0, 0, yPos)
    sep.BackgroundColor3 = colors.border
    sep.BorderSizePixel = 0
    sep.Parent = parent
end

addSeparator(PlayerContainer, 0)
addSeparator(VisualContainer, 0)
addSeparator(TeleportContainer, 0)
addSeparator(CombatContainer, 0)
addSeparator(ItemsContainer, 0)

-- ========== ФУНКЦИЯ СОЗДАНИЯ ЧЕКБОКСА ==========
local function CreateXONECheckbox(parent, name, posY, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.06)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 1, 0)
    label.Position = UDim2.new(0, 25, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = colors.text
    label.Font = Enum.Font.Gotham
    label.TextSize = ContainerHeight * 0.03
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local checkbox = Instance.new("Frame")
    checkbox.Size = UDim2.new(0, ContainerHeight * 0.035, 0, ContainerHeight * 0.035)
    checkbox.Position = UDim2.new(0, 0, 0.5, -ContainerHeight * 0.0175)
    checkbox.BackgroundColor3 = colors.bg2
    checkbox.BorderSizePixel = 1
    checkbox.BorderColor3 = colors.border
    checkbox.Parent = frame
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 3)
    checkCorner.Parent = checkbox
    
    local checkFill = Instance.new("Frame")
    checkFill.Size = UDim2.new(0, ContainerHeight * 0.022, 0, ContainerHeight * 0.022)
    checkFill.Position = UDim2.new(0.5, -ContainerHeight * 0.011, 0.5, -ContainerHeight * 0.011)
    checkFill.BackgroundColor3 = colors.accent
    checkFill.Visible = defaultValue
    checkFill.Parent = checkbox
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = checkFill
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = frame
    
    local state = defaultValue
    
    button.MouseButton1Click:Connect(function()
        state = not state
        checkFill.Visible = state
        callback(state)
    end)
    
    return frame, checkFill
end

-- ========== ФУНКЦИЯ СОЗДАНИЯ КНОПКИ ТЕЛЕПОРТА ==========
local function CreateTeleportButton(parent, playerName, posY, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.08)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundColor3 = colors.bg2
    frame.BorderSizePixel = 1
    frame.BorderColor3 = colors.border
    frame.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = colors.text
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = ContainerHeight * 0.03
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local tpButton = Instance.new("TextButton")
    tpButton.Size = UDim2.new(0, 60, 0, ContainerHeight * 0.045)
    tpButton.Position = UDim2.new(1, -70, 0.5, -ContainerHeight * 0.0225)
    tpButton.BackgroundColor3 = colors.accent
    tpButton.Text = "ТП"
    tpButton.TextColor3 = colors.text
    tpButton.Font = Enum.Font.GothamBold
    tpButton.TextSize = ContainerHeight * 0.025
    tpButton.Parent = frame
    
    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 5)
    tpCorner.Parent = tpButton
    
    tpButton.MouseButton1Click:Connect(function()
        callback()
    end)
    
    tpButton.MouseEnter:Connect(function()
        tpButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    end)
    tpButton.MouseLeave:Connect(function()
        tpButton.BackgroundColor3 = colors.accent
    end)
    
    return frame
end

-- ========== PLAYER TAB ==========
local MovementTitle = Instance.new("TextLabel")
MovementTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
MovementTitle.Position = UDim2.new(0, 0, 0, 5)
MovementTitle.BackgroundTransparency = 1
MovementTitle.Text = "ДВИЖЕНИЕ"
MovementTitle.TextColor3 = colors.accent
MovementTitle.Font = Enum.Font.GothamBold
MovementTitle.TextSize = ContainerHeight * 0.03
MovementTitle.TextXAlignment = Enum.TextXAlignment.Left
MovementTitle.Parent = PlayerContainer

-- FLY
local flyFrame, flyCheck = CreateXONECheckbox(PlayerContainer, "Полет", ContainerHeight * 0.05, false, function(state)
    FlyEnabled = state
    
    if FlyEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            if BodyFly then BodyFly:Destroy() end
            BodyFly = Instance.new("BodyVelocity")
            BodyFly.Velocity = Vector3.new(0,0,0)
            BodyFly.MaxForce = Vector3.new(5000,5000,5000)
            BodyFly.P = 1250
            BodyFly.Parent = root
            
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then humanoid.PlatformStand = true end
        end
    else
        if BodyFly then
            BodyFly:Destroy()
            BodyFly = nil
        end
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end
end)

-- NOCLIP
local noclipFrame, noclipCheck = CreateXONECheckbox(PlayerContainer, "Сквозь стены", ContainerHeight * 0.11, false, function(state)
    NoclipEnabled = state
    
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    if NoclipEnabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

-- TP WALK
local tpFrame, tpCheck = CreateXONECheckbox(PlayerContainer, "ТП Ходьба (0.02)", ContainerHeight * 0.17, false, function(state)
    TPWalkEnabled = state
    
    if TPWalkConnection then
        TPWalkConnection:Disconnect()
        TPWalkConnection = nil
    end
    
    if TPWalkEnabled then
        TPWalkConnection = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character
            if not character then return end
            
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
                local moveDir = humanoid.MoveDirection
                local tpDistance = 0.02
                
                rootPart.CFrame = rootPart.CFrame + (moveDir * tpDistance)
                
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part ~= rootPart then
                        part.CFrame = part.CFrame + (moveDir * tpDistance)
                    end
                end
            end
        end)
    end
end)

-- ========== CTRL+CLICK TP ==========
local CtrlTitle = Instance.new("TextLabel")
CtrlTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
CtrlTitle.Position = UDim2.new(0, 0, 0, ContainerHeight * 0.23)
CtrlTitle.BackgroundTransparency = 1
CtrlTitle.Text = "ТЕЛЕПОРТ"
CtrlTitle.TextColor3 = colors.accent
CtrlTitle.Font = Enum.Font.GothamBold
CtrlTitle.TextSize = ContainerHeight * 0.03
CtrlTitle.TextXAlignment = Enum.TextXAlignment.Left
CtrlTitle.Parent = PlayerContainer

local ctrlClickFrame, ctrlClickCheck = CreateXONECheckbox(PlayerContainer, "Ctrl+Click TP", ContainerHeight * 0.28, false, function(state)
    CtrlClickTPEnabled = state
end)

local ctrlInfo = Instance.new("TextLabel")
ctrlInfo.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
ctrlInfo.Position = UDim2.new(0, 25, 0, ContainerHeight * 0.33)
ctrlInfo.BackgroundTransparency = 1
ctrlInfo.Text = "Зажми Ctrl + ЛКМ для телепорта"
ctrlInfo.TextColor3 = colors.text2
ctrlInfo.Font = Enum.Font.Gotham
ctrlInfo.TextSize = ContainerHeight * 0.025
ctrlInfo.TextXAlignment = Enum.TextXAlignment.Left
ctrlInfo.Parent = PlayerContainer

-- ========== VISUAL TAB ==========
local RenderTitle = Instance.new("TextLabel")
RenderTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
RenderTitle.Position = UDim2.new(0, 0, 0, 5)
RenderTitle.BackgroundTransparency = 1
RenderTitle.Text = "ОТОБРАЖЕНИЕ"
RenderTitle.TextColor3 = colors.accent
RenderTitle.Font = Enum.Font.GothamBold
RenderTitle.TextSize = ContainerHeight * 0.03
RenderTitle.TextXAlignment = Enum.TextXAlignment.Left
RenderTitle.Parent = VisualContainer

local espFrame, espCheck = CreateXONECheckbox(VisualContainer, "ESP (Подсветка)", ContainerHeight * 0.05, false, function(state)
    ESPEnabled = state
    if not state then
        clearAllHighlights()
    end
end)

-- ========== COMBAT TAB ==========
local CombatTitle = Instance.new("TextLabel")
CombatTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
CombatTitle.Position = UDim2.new(0, 0, 0, 5)
CombatTitle.BackgroundTransparency = 1
CombatTitle.Text = "БОЙ"
CombatTitle.TextColor3 = colors.accent
CombatTitle.Font = Enum.Font.GothamBold
CombatTitle.TextSize = ContainerHeight * 0.03
CombatTitle.TextXAlignment = Enum.TextXAlignment.Left
CombatTitle.Parent = CombatContainer

local aimbotFrame, aimbotCheck = CreateXONECheckbox(CombatContainer, "Аимбот", ContainerHeight * 0.05, false, function(state)
    AimbotEnabled = state
    AimbotButton.Visible = state
    
    if not state then
        AimbotActive = false
        AimbotTarget = nil
        AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AimbotIndicator.Visible = false
    end
end)

-- TP Slash (с возвратом)
local tpSlashFrame, tpSlashCheck = CreateXONECheckbox(CombatContainer, "TP Slash (Q) - орбита", ContainerHeight * 0.11, false, function(state)
    TPSlashEnabled = state
end)

-- TP Hit (по ЛКМ)
local tpHitFrame, tpHitCheck = CreateXONECheckbox(CombatContainer, "TP Hit (ЛКМ) - рывок к игроку", ContainerHeight * 0.17, false, function(state)
    TPHitEnabled = state
end)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.12)
infoLabel.Position = UDim2.new(0, 0, 0, ContainerHeight * 0.24)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Аимбот: красная кнопка\nTP Slash: нажми Q (орбита + возврат)\nTP Hit: нажми ЛКМ (рывок 0.2 сек и обратно)"
infoLabel.TextColor3 = colors.text2
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = ContainerHeight * 0.025
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = CombatContainer

-- ========== ITEMS TAB ==========
local ItemsTitle = Instance.new("TextLabel")
ItemsTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
ItemsTitle.Position = UDim2.new(0, 0, 0, 5)
ItemsTitle.BackgroundTransparency = 1
ItemsTitle.Text = "ПРЕДМЕТЫ"
ItemsTitle.TextColor3 = colors.accent
ItemsTitle.Font = Enum.Font.GothamBold
ItemsTitle.TextSize = ContainerHeight * 0.03
ItemsTitle.TextXAlignment = Enum.TextXAlignment.Left
ItemsTitle.Parent = ItemsContainer

local soonLabel = Instance.new("TextLabel")
soonLabel.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.1)
soonLabel.Position = UDim2.new(0, 0, 0, ContainerHeight * 0.05)
soonLabel.BackgroundTransparency = 1
soonLabel.Text = "Скоро появятся новые предметы..."
soonLabel.TextColor3 = colors.text2
soonLabel.Font = Enum.Font.Gotham
soonLabel.TextSize = ContainerHeight * 0.03
soonLabel.TextXAlignment = Enum.TextXAlignment.Left
soonLabel.Parent = ItemsContainer

-- ========== TELEPORT TAB ==========
local TeleportTitle = Instance.new("TextLabel")
TeleportTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.05)
TeleportTitle.Position = UDim2.new(0, 0, 0, 5)
TeleportTitle.BackgroundTransparency = 1
TeleportTitle.Text = "ТЕЛЕПОРТ К ИГРОКАМ"
TeleportTitle.TextColor3 = colors.accent
TeleportTitle.Font = Enum.Font.GothamBold
TeleportTitle.TextSize = ContainerHeight * 0.03
TeleportTitle.TextXAlignment = Enum.TextXAlignment.Left
TeleportTitle.Parent = TeleportContainer

local TeleportList = Instance.new("ScrollingFrame")
TeleportList.Size = UDim2.new(1, 0, 1, -ContainerHeight * 0.07)
TeleportList.Position = UDim2.new(0, 0, 0, ContainerHeight * 0.05)
TeleportList.BackgroundColor3 = colors.bg2
TeleportList.BorderSizePixel = 1
TeleportList.BorderColor3 = colors.border
TeleportList.ScrollBarThickness = 4
TeleportList.ScrollBarImageColor3 = colors.accent
TeleportList.CanvasSize = UDim2.new(0, 0, 0, 0)
TeleportList.Parent = TeleportContainer

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = TeleportList

-- Функция обновления списка игроков
local function UpdateTeleportList()
    for _, child in pairs(TeleportList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local yPos = 5
    local playerCount = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            playerCount = playerCount + 1
            
            CreateTeleportButton(TeleportList, player.Name, yPos, function()
                local targetChar = player.Character
                local localChar = LocalPlayer.Character
                
                if targetChar and localChar and localChar:FindFirstChild("HumanoidRootPart") then
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
                    
                    if targetRoot then
                        localRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 2)
                        
                        for _, part in pairs(localChar:GetChildren()) do
                            if part:IsA("BasePart") and part ~= localRoot then
                                part.CFrame = localRoot.CFrame
                            end
                        end
                    end
                end
            end)
            
            yPos = yPos + ContainerHeight * 0.09
        end
    end
    
    if playerCount == 0 then
        local noPlayers = Instance.new("TextLabel")
        noPlayers.Size = UDim2.new(1, -20, 0, 40)
        noPlayers.Position = UDim2.new(0, 10, 0, 10)
        noPlayers.BackgroundTransparency = 1
        noPlayers.Text = "Нет игроков"
        noPlayers.TextColor3 = colors.text2
        noPlayers.Font = Enum.Font.Gotham
        noPlayers.TextSize = ContainerHeight * 0.035
        noPlayers.Parent = TeleportList
    end
    
    TeleportList.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
end

-- ========== CTRL+CLICK TP ==========
local Mouse = LocalPlayer:GetMouse()

Mouse.Button1Down:Connect(function()
    if not CtrlClickTPEnabled then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
    if not Mouse.Target then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    character:MoveTo(Mouse.Hit.p)
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.new(Mouse.Hit.p + Vector3.new(0, 3, 0))
    end
end)

-- ========== TP SLASH (С ВОЗВРАТОМ) ==========
local function getFirstKiller()
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then return nil end
    
    local killersFolder = playersFolder:FindFirstChild("Killers")
    if not killersFolder then return nil end
    
    for _, killer in ipairs(killersFolder:GetChildren()) do
        if killer:IsA("Model") and killer:FindFirstChild("HumanoidRootPart") then
            return killer
        end
    end
    return nil
end

local function orbitKiller()
    if TPSlashCooldown then return end
    
    local killer = getFirstKiller()
    if not killer then 
        return 
    end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local killerHRP = killer:FindFirstChild("HumanoidRootPart")
    
    if not rootPart or not killerHRP then return end
    
    TPSlashCooldown = true
    
    -- Сохраняем исходную позицию
    local originalCFrame = rootPart.CFrame
    local startTime = tick()
    local center = killerHRP.Position
    
    -- Создаем эффект свечения
    local beam = Instance.new("Part")
    beam.Size = Vector3.new(1, 1, 1)
    beam.BrickColor = BrickColor.new("Bright violet")
    beam.Material = Enum.Material.Neon
    beam.Anchored = true
    beam.CanCollide = false
    beam.Parent = workspace
    
    -- Основной цикл орбиты
    while (tick() - startTime) < ORBIT_DURATION do
        local elapsed = tick() - startTime
        local angle = elapsed * math.pi * ORBIT_SPEED
        
        -- Позиция на орбите
        local orbitPos = center + Vector3.new(
            math.cos(angle) * ORBIT_RADIUS,
            ORBIT_HEIGHT + math.sin(angle * 2) * 1,
            math.sin(angle) * ORBIT_RADIUS
        )
        
        -- Плавное перемещение
        rootPart.CFrame = CFrame.new(orbitPos, center)
        
        -- Перемещаем остальные части
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part ~= rootPart then
                part.CFrame = rootPart.CFrame
            end
        end
        
        -- Анимируем эффект
        beam.Position = orbitPos
        beam.Size = Vector3.new(2 + math.sin(elapsed * 10) * 1, 2 + math.sin(elapsed * 10) * 1, 2 + math.sin(elapsed * 10) * 1)
        
        task.wait(0.02)
    end
    
    -- ВОЗВРАЩАЕМСЯ НА ИСХОДНУЮ ПОЗИЦИЮ
    if rootPart and rootPart.Parent then
        rootPart.CFrame = originalCFrame
        
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part ~= rootPart then
                part.CFrame = rootPart.CFrame
            end
        end
    end
    
    -- Убираем эффект
    beam:Destroy()
    
    task.delay(ORBIT_COOLDOWN, function()
        TPSlashCooldown = false
    end)
end

-- ========== TP HIT ПО ЛКМ ==========
local function getRandomPlayer()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(players, player)
            end
        end
    end
    
    if #players > 0 then
        return players[math.random(1, #players)]
    end
    return nil
end

local function tpHitRush()
    if TPHitCooldown then return end
    if not TPHitEnabled then return end
    
    local target = getRandomPlayer()
    if not target then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local targetChar = target.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    
    if not rootPart or not targetRoot then return end
    
    TPHitCooldown = true
    
    -- Сохраняем оригинальную позицию
    local originalCFrame = rootPart.CFrame
    
    -- Телепортируемся к игроку
    rootPart.CFrame = targetRoot.CFrame + Vector3.new(2, 1, 2)
    
    -- Синхронизируем остальные части
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part ~= rootPart then
            part.CFrame = rootPart.CFrame
        end
    end
    
    -- Ждем 0.2 секунды
    task.wait(TP_HIT_DURATION)
    
    -- Возвращаемся обратно
    if rootPart and rootPart.Parent then
        rootPart.CFrame = originalCFrame
        
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part ~= rootPart then
                part.CFrame = rootPart.CFrame
            end
        end
    end
    
    -- Кулдаун
    task.delay(TP_HIT_COOLDOWN, function()
        TPHitCooldown = false
    end)
end

-- Обработка ЛКМ для TP Hit
Mouse.Button1Down:Connect(function()
    if TPHitEnabled and not CtrlClickTPEnabled then
        tpHitRush()
    end
end)

-- ========== ОБРАБОТКА НАЖАТИЙ ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Q and TPSlashEnabled and not TPSlashCooldown then
        orbitKiller()
    end
end)

-- ========== ЛОГИКА КНОПКИ АИМБОТА ==========
AimbotButton.MouseButton1Click:Connect(function()
    if not AimbotEnabled then return end
    
    AimbotActive = not AimbotActive
    
    if AimbotActive then
        AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        AimbotIndicator.Visible = true
        AimbotTarget = GetNearestPlayer()
    else
        AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AimbotIndicator.Visible = false
        AimbotTarget = nil
    end
end)

-- ========== ESP ФУНКЦИИ ==========
local function createHighlight(model, outlineColor, fillColor)
    for _, existing in pairs(model:GetChildren()) do
        if existing:IsA("Highlight") then
            existing:Destroy()
        end
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = model
    highlight.Adornee = model
    highlight.FillTransparency = 0.65
    highlight.FillColor = fillColor
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    
    table.insert(ESPHighlights, highlight)
    
    return highlight
end

local function highlightGroup(group, outlineColor, fillColor)
    if group then
        for _, obj in pairs(group:GetChildren()) do
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and obj:FindFirstChild("HumanoidRootPart") and humanoid.Health > 0 then
                createHighlight(obj, outlineColor, fillColor)
            end
        end
    end
end

local function highlightGenerators()
    local generatorsFolder = workspace:FindFirstChild("Map") and 
                             workspace.Map:FindFirstChild("Ingame") and 
                             workspace.Map.Ingame:FindFirstChild("Map")

    if generatorsFolder then
        for _, obj in pairs(generatorsFolder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                createHighlight(obj, Color3.new(1, 1, 0), Color3.new(1, 1, 0.5))
            end
        end
    end
end

local function highlightOtherPlayers()
    local playersGroup = workspace:FindFirstChild("Players")
    if not playersGroup then return end
    
    local killersGroup = playersGroup:FindFirstChild("Killers")
    local survivorsGroup = playersGroup:FindFirstChild("Survivors")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local isInGroup = false
                
                if killersGroup then
                    for _, obj in pairs(killersGroup:GetChildren()) do
                        if obj == character then
                            isInGroup = true
                            break
                        end
                    end
                end
                
                if not isInGroup and survivorsGroup then
                    for _, obj in pairs(survivorsGroup:GetChildren()) do
                        if obj == character then
                            isInGroup = true
                            break
                        end
                    end
                end
                
                if not isInGroup then
                    createHighlight(character, Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
                end
            end
        end
    end
end

local function clearAllHighlights()
    for _, highlight in pairs(ESPHighlights) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    ESPHighlights = {}
end

local function updateESP()
    if not ESPEnabled then 
        clearAllHighlights()
        return 
    end
    
    clearAllHighlights()
    
    local playersGroup = workspace:FindFirstChild("Players")
    if playersGroup then
        local killersGroup = playersGroup:FindFirstChild("Killers")
        highlightGroup(killersGroup, Color3.new(1, 0, 0), Color3.new(1, 0.5, 0.5))
        
        local survivorsGroup = playersGroup:FindFirstChild("Survivors")
        highlightGroup(survivorsGroup, Color3.new(0, 1, 0), Color3.new(0.5, 1, 0.5))
    end
    
    highlightOtherPlayers()
    highlightGenerators()
end

spawn(function()
    while true do
        pcall(updateESP)
        wait(0.5)
    end
end)

-- ========== AIMBOT ФУНКЦИЯ ==========
function GetNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    
    if not localRoot then return nil end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetChar = player.Character
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local humanoid = targetChar:FindFirstChild("Humanoid")
            
            if targetRoot and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetRoot.Position)
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                
                if onScreen and distance < 150 then
                    local ray = Ray.new(Camera.CFrame.Position, (targetRoot.Position - Camera.CFrame.Position).Unit * distance)
                    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {localChar, Camera})
                    
                    if hit == nil or hit:IsDescendantOf(targetChar) then
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearestPlayer = player
                        end
                    end
                end
            end
        end
    end
    
    return nearestPlayer
end

RunService.RenderStepped:Connect(function()
    if AimbotEnabled and AimbotActive and AimbotTarget then
        if AimbotTarget.Character and AimbotTarget.Character:FindFirstChild("Head") and 
           AimbotTarget.Character:FindFirstChild("Humanoid") and 
           AimbotTarget.Character.Humanoid.Health > 0 then
            
            local headPos = AimbotTarget.Character.Head.Position
            local localChar = LocalPlayer.Character
            local humanoid = localChar and localChar:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local lookAt = CFrame.lookAt(Camera.CFrame.Position, headPos)
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, 0.5)
            end
        else
            AimbotTarget = GetNearestPlayer()
        end
    end
end)

-- ========== ОБНОВЛЕНИЕ СПИСКА ==========
spawn(function()
    while true do
        if CurrentTab == "ТЕЛЕПОРТ" then
            pcall(UpdateTeleportList)
        end
        wait(2)
    end
end)

-- ========== ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ==========
PlayerTab.MouseButton1Click:Connect(function()
    CurrentTab = "ИГРОК"
    PlayerTab.TextColor3 = colors.accent
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    ItemsTab.TextColor3 = colors.text2
    PlayerContainer.Visible = true
    VisualContainer.Visible = false
    TeleportContainer.Visible = false
    CombatContainer.Visible = false
    ItemsContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 8, 1, -2)}):Play()
end)

VisualTab.MouseButton1Click:Connect(function()
    CurrentTab = "ВИЗУАЛ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.accent
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    ItemsTab.TextColor3 = colors.text2
    PlayerContainer.Visible = false
    VisualContainer.Visible = true
    TeleportContainer.Visible = false
    CombatContainer.Visible = false
    ItemsContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 12 + TabWidth, 1, -2)}):Play()
end)

TeleportTab.MouseButton1Click:Connect(function()
    CurrentTab = "ТЕЛЕПОРТ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.accent
    CombatTab.TextColor3 = colors.text2
    ItemsTab.TextColor3 = colors.text2
    PlayerContainer.Visible = false
    VisualContainer.Visible = false
    TeleportContainer.Visible = true
    CombatContainer.Visible = false
    ItemsContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 16 + (TabWidth * 2), 1, -2)}):Play()
    UpdateTeleportList()
end)

CombatTab.MouseButton1Click:Connect(function()
    CurrentTab = "БОЙ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.accent
    ItemsTab.TextColor3 = colors.text2
    PlayerContainer.Visible = false
    VisualContainer.Visible = false
    TeleportContainer.Visible = false
    CombatContainer.Visible = true
    ItemsContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 20 + (TabWidth * 3), 1, -2)}):Play()
end)

ItemsTab.MouseButton1Click:Connect(function()
    CurrentTab = "ПРЕДМЕТЫ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    ItemsTab.TextColor3 = colors.accent
    PlayerContainer.Visible = false
    VisualContainer.Visible = false
    TeleportContainer.Visible = false
    CombatContainer.Visible = false
    ItemsContainer.Visible = true
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 24 + (TabWidth * 4), 1, -2)}):Play()
end)

-- ========== УПРАВЛЕНИЕ МЕНЮ ==========
OpenButton.MouseButton1Click:Connect(function()
    MenuVisible = not MenuVisible
    MainFrame.Visible = MenuVisible
end)

CloseButton.MouseButton1Click:Connect(function()
    MenuVisible = false
    MainFrame.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MenuVisible = not MenuVisible
        MainFrame.Visible = MenuVisible
    end
end)

-- ========== FLY ЛОГИКА ==========
local function UpdateFly()
    if not FlyEnabled then return end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        if BodyFly then
            BodyFly:Destroy()
            BodyFly = nil
        end
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    local moveVector = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveVector = moveVector + Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveVector = moveVector - Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveVector = moveVector - Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveVector = moveVector + Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveVector = moveVector + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        moveVector = moveVector + Vector3.new(0, -1, 0)
    end
    
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit * 75
    end
    
    if BodyFly then
        BodyFly.Velocity = moveVector
    end
end

-- Сброс при смерти
LocalPlayer.CharacterAdded:Connect(function()
    if BodyFly then
        BodyFly:Destroy()
        BodyFly = nil
    end
    FlyEnabled = false
    if flyCheck then flyCheck.Visible = false end
    
    if TPWalkConnection then
        TPWalkConnection:Disconnect()
        TPWalkConnection = nil
    end
    TPWalkEnabled = false
    if tpCheck then tpCheck.Visible = false end
    
    AimbotTarget = nil
    AimbotActive = false
    if AimbotEnabled then
        AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AimbotIndicator.Visible = false
    end
    
    TPSlashCooldown = false
    TPHitCooldown = false
end)

-- Главный цикл
RunService.RenderStepped:Connect(function()
    pcall(UpdateFly)
end)

print([[

    ╔══════════════════════════════════════╗
    ║      XONE MOBILE v24.0              ║
    ║                                      ║
    ║  ИЗМЕНЕНИЯ:                          ║
    ║  🔄 TP Slash: теперь ВОЗВРАЩАЕТ      ║
    ║     на исходную позицию после орбиты ║
    ║                                      ║
    ║  ФУНКЦИИ:                            ║
    ║  ⚔️ TP Slash (Q) - орбита + возврат  ║
    ║  🏃 TP Hit (ЛКМ) - рывок к игроку    ║
    ║  🖱️ Ctrl+Click TP                     ║
    ║  🎯 Аимбот                            ║
    ║  🔴 ESP подсветка                     ║
    ║                                      ║
    ║  [КНОПКА X] - Открыть меню           ║
    ╚══════════════════════════════════════╝
]])
