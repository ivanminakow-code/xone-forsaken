--[[
    FORSAKEN MOBILE MENU v13.1
    ИСПРАВЛЕН ESP:
    - УБРАНЫ ТЕКСТОВЫЕ LABEL ( killersLabel, survivorsLabel, othersLabel )
    - ДРУГИЕ ИГРОКИ ТЕПЕРЬ ПОДСВЕЧИВАЮТСЯ БЕЛЫМ
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local TouchEnabled = UserInputService.TouchEnabled

repeat wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ПЕРЕМЕННЫЕ
local MenuVisible = false
local FlyEnabled = false
local NoclipEnabled = false
local TPWalkEnabled = false
local ESPEnabled = false
local AimbotEnabled = false
local AimbotActive = false
local TPWalkSpeed = 0.02
local BodyFly = nil
local NoclipConnection = nil
local TPWalkConnection = nil
local CurrentTab = "ИГРОК"
local AimbotTarget = nil
local ESPHighlights = {} -- Хранилище для Highlight объектов

-- ПОЛУЧАЕМ РАЗМЕР ЭКРАНА
local ViewportSize = Camera.ViewportSize
local ScreenWidth = ViewportSize.X
local ScreenHeight = ViewportSize.Y

-- РАССЧИТЫВАЕМ АДАПТИВНЫЕ РАЗМЕРЫ
local MenuWidth = math.min(500, ScreenWidth * 0.9)
local MenuHeight = math.min(450, ScreenHeight * 0.8)
local ButtonSize = math.min(60, ScreenWidth * 0.1)
local AimbotButtonSize = math.min(80, ScreenWidth * 0.12)

-- ЦВЕТОВАЯ СХЕМА
local colors = {
    bg = Color3.fromRGB(18, 18, 22),
    bg2 = Color3.fromRGB(25, 25, 32),
    accent = Color3.fromRGB(0, 162, 255),
    accent2 = Color3.fromRGB(75, 130, 200),
    text = Color3.fromRGB(220, 220, 220),
    text2 = Color3.fromRGB(150, 150, 150),
    red = Color3.fromRGB(240, 80, 80),
    green = Color3.fromRGB(80, 200, 120),
    white = Color3.fromRGB(255, 255, 255),
    border = Color3.fromRGB(45, 45, 55)
}

-- СОЗДАНИЕ GUI
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

-- ========== ПЕРЕТАСКИВАЕМАЯ КНОПКА ОТКРЫТИЯ ==========
local OpenButton = Instance.new("ImageButton")
OpenButton.Size = UDim2.new(0, ButtonSize, 0, ButtonSize)
OpenButton.Position = UDim2.new(0, 20, 0.5, -ButtonSize/2)
OpenButton.BackgroundColor3 = colors.accent
OpenButton.BackgroundTransparency = 0.2
OpenButton.Image = "rbxassetid://3926305904"
OpenButton.ImageColor3 = Color3.new(1, 1, 1)
OpenButton.ScaleType = Enum.ScaleType.Fit
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, ButtonSize/2)
OpenCorner.Parent = OpenButton

local OpenShadow = Instance.new("ImageLabel")
OpenShadow.Size = UDim2.new(1, 10, 1, 10)
OpenShadow.Position = UDim2.new(0, -5, 0, -5)
OpenShadow.BackgroundTransparency = 1
OpenShadow.Image = "rbxassetid://1316045217"
OpenShadow.ImageColor3 = Color3.new(0, 0, 0)
OpenShadow.ImageTransparency = 0.5
OpenShadow.Parent = OpenButton

local OpenText = Instance.new("TextLabel")
OpenText.Size = UDim2.new(1, 0, 1, 0)
OpenText.BackgroundTransparency = 1
OpenText.Text = "X"
OpenText.TextColor3 = Color3.new(1, 1, 1)
OpenText.Font = Enum.Font.GothamBold
OpenText.TextSize = ButtonSize * 0.5
OpenText.Parent = OpenButton

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

local AimbotShadow = Instance.new("ImageLabel")
AimbotShadow.Size = UDim2.new(1, 10, 1, 10)
AimbotShadow.Position = UDim2.new(0, -5, 0, -5)
AimbotShadow.BackgroundTransparency = 1
AimbotShadow.Image = "rbxassetid://1316045217"
AimbotShadow.ImageColor3 = Color3.new(0, 0, 0)
AimbotShadow.ImageTransparency = 0.5
AimbotShadow.Parent = AimbotButton

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
MainFrame.Visible = MenuVisible
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- Верхняя полоса
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, MenuHeight * 0.09)
TitleBar.BackgroundColor3 = colors.bg2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Логотип
local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, MenuWidth * 0.16, 1, 0)
Logo.Position = UDim2.new(0, 10, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "XONE"
Logo.TextColor3 = colors.accent
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = MenuHeight * 0.05
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = TitleBar

-- Название игры
local GameTitle = Instance.new("TextLabel")
GameTitle.Size = UDim2.new(0, MenuWidth * 0.3, 1, 0)
GameTitle.Position = UDim2.new(0, MenuWidth * 0.18, 0, 0)
GameTitle.BackgroundTransparency = 1
GameTitle.Text = "| FORSAKEN"
GameTitle.TextColor3 = colors.text2
GameTitle.Font = Enum.Font.GothamSemibold
GameTitle.TextSize = MenuHeight * 0.045
GameTitle.TextXAlignment = Enum.TextXAlignment.Left
GameTitle.Parent = TitleBar

-- Кнопка закрытия
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, MenuHeight * 0.07, 0, MenuHeight * 0.07)
CloseButton.Position = UDim2.new(1, -MenuHeight * 0.09, 0.5, -MenuHeight * 0.035)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseButton.Text = "✕"
CloseButton.TextColor3 = colors.text
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = MenuHeight * 0.04
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, MenuHeight * 0.015)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    MenuVisible = false
    MainFrame.Visible = false
end)

-- ========== ВКЛАДКИ ==========
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(1, 0, 0, MenuHeight * 0.09)
TabsFrame.Position = UDim2.new(0, 0, 0, MenuHeight * 0.09)
TabsFrame.BackgroundColor3 = colors.bg2
TabsFrame.BorderSizePixel = 0
TabsFrame.Parent = MainFrame

local TabWidth = (MenuWidth - 60) / 4

local PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.new(0, TabWidth, 1, 0)
PlayerTab.Position = UDim2.new(0, 15, 0, 0)
PlayerTab.BackgroundTransparency = 1
PlayerTab.Text = "ИГРОК"
PlayerTab.TextColor3 = colors.accent
PlayerTab.Font = Enum.Font.GothamBold
PlayerTab.TextSize = MenuHeight * 0.03
PlayerTab.Parent = TabsFrame

local VisualTab = Instance.new("TextButton")
VisualTab.Size = UDim2.new(0, TabWidth, 1, 0)
VisualTab.Position = UDim2.new(0, 15 + TabWidth + 10, 0, 0)
VisualTab.BackgroundTransparency = 1
VisualTab.Text = "ВИЗУАЛ"
VisualTab.TextColor3 = colors.text2
VisualTab.Font = Enum.Font.GothamBold
VisualTab.TextSize = MenuHeight * 0.03
VisualTab.Parent = TabsFrame

local TeleportTab = Instance.new("TextButton")
TeleportTab.Size = UDim2.new(0, TabWidth, 1, 0)
TeleportTab.Position = UDim2.new(0, 15 + (TabWidth + 10) * 2, 0, 0)
TeleportTab.BackgroundTransparency = 1
TeleportTab.Text = "ТЕЛЕПОРТ"
TeleportTab.TextColor3 = colors.text2
TeleportTab.Font = Enum.Font.GothamBold
TeleportTab.TextSize = MenuHeight * 0.03
TeleportTab.Parent = TabsFrame

local CombatTab = Instance.new("TextButton")
CombatTab.Size = UDim2.new(0, TabWidth, 1, 0)
CombatTab.Position = UDim2.new(0, 15 + (TabWidth + 10) * 3, 0, 0)
CombatTab.BackgroundTransparency = 1
CombatTab.Text = "БОЙ"
CombatTab.TextColor3 = colors.text2
CombatTab.Font = Enum.Font.GothamBold
CombatTab.TextSize = MenuHeight * 0.03
CombatTab.Parent = TabsFrame

-- Индикатор активной вкладки
local TabIndicator = Instance.new("Frame")
TabIndicator.Size = UDim2.new(0, TabWidth, 0, 2)
TabIndicator.Position = UDim2.new(0, 15, 1, -2)
TabIndicator.BackgroundColor3 = colors.accent
TabIndicator.BorderSizePixel = 0
TabIndicator.Parent = TabsFrame

-- ========== КОНТЕЙНЕРЫ ДЛЯ ВКЛАДОК ==========
local ContainerY = MenuHeight * 0.2
local ContainerHeight = MenuHeight * 0.71

local PlayerContainer = Instance.new("Frame")
PlayerContainer.Size = UDim2.new(1, -30, 0, ContainerHeight)
PlayerContainer.Position = UDim2.new(0, 15, 0, ContainerY)
PlayerContainer.BackgroundTransparency = 1
PlayerContainer.Visible = true
PlayerContainer.Parent = MainFrame

local VisualContainer = Instance.new("Frame")
VisualContainer.Size = UDim2.new(1, -30, 0, ContainerHeight)
VisualContainer.Position = UDim2.new(0, 15, 0, ContainerY)
VisualContainer.BackgroundTransparency = 1
VisualContainer.Visible = false
VisualContainer.Parent = MainFrame

local TeleportContainer = Instance.new("Frame")
TeleportContainer.Size = UDim2.new(1, -30, 0, ContainerHeight)
TeleportContainer.Position = UDim2.new(0, 15, 0, ContainerY)
TeleportContainer.BackgroundTransparency = 1
TeleportContainer.Visible = false
TeleportContainer.Parent = MainFrame

local CombatContainer = Instance.new("Frame")
CombatContainer.Size = UDim2.new(1, -30, 0, ContainerHeight)
CombatContainer.Position = UDim2.new(0, 15, 0, ContainerY)
CombatContainer.BackgroundTransparency = 1
CombatContainer.Visible = false
CombatContainer.Parent = MainFrame

-- Разделители
local function addSeparator(parent)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = colors.border
    sep.BorderSizePixel = 0
    sep.Parent = parent
end

addSeparator(PlayerContainer)
addSeparator(VisualContainer)
addSeparator(TeleportContainer)
addSeparator(CombatContainer)

-- ========== ФУНКЦИЯ СОЗДАНИЯ ЧЕКБОКСА ==========
local function CreateXONECheckbox(parent, name, posY, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.08)
    frame.Position = UDim2.new(0, 0, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = colors.text
    label.Font = Enum.Font.Gotham
    label.TextSize = ContainerHeight * 0.035
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local checkbox = Instance.new("Frame")
    checkbox.Size = UDim2.new(0, ContainerHeight * 0.05, 0, ContainerHeight * 0.05)
    checkbox.Position = UDim2.new(0, 0, 0.5, -ContainerHeight * 0.025)
    checkbox.BackgroundColor3 = colors.bg2
    checkbox.BorderSizePixel = 1
    checkbox.BorderColor3 = colors.border
    checkbox.Parent = frame
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = checkbox
    
    local checkFill = Instance.new("Frame")
    checkFill.Size = UDim2.new(0, ContainerHeight * 0.035, 0, ContainerHeight * 0.035)
    checkFill.Position = UDim2.new(0.5, -ContainerHeight * 0.0175, 0.5, -ContainerHeight * 0.0175)
    checkFill.BackgroundColor3 = colors.accent
    checkFill.Visible = defaultValue
    checkFill.Parent = checkbox
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
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
    frame.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.1)
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
    nameLabel.TextSize = ContainerHeight * 0.04
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local tpButton = Instance.new("TextButton")
    tpButton.Size = UDim2.new(0, 60, 0, ContainerHeight * 0.06)
    tpButton.Position = UDim2.new(1, -70, 0.5, -ContainerHeight * 0.03)
    tpButton.BackgroundColor3 = colors.accent
    tpButton.Text = "ТП"
    tpButton.TextColor3 = colors.text
    tpButton.Font = Enum.Font.GothamBold
    tpButton.TextSize = ContainerHeight * 0.035
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
MovementTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.06)
MovementTitle.Position = UDim2.new(0, 0, 0, 5)
MovementTitle.BackgroundTransparency = 1
MovementTitle.Text = "ДВИЖЕНИЕ"
MovementTitle.TextColor3 = colors.accent
MovementTitle.Font = Enum.Font.GothamBold
MovementTitle.TextSize = ContainerHeight * 0.035
MovementTitle.TextXAlignment = Enum.TextXAlignment.Left
MovementTitle.Parent = PlayerContainer

-- FLY
local flyFrame, flyCheck = CreateXONECheckbox(PlayerContainer, "Полет", ContainerHeight * 0.07, false, function(state)
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
local noclipFrame, noclipCheck = CreateXONECheckbox(PlayerContainer, "Сквозь стены", ContainerHeight * 0.15, false, function(state)
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
    end
end)

-- TP WALK
local tpFrame, tpCheck = CreateXONECheckbox(PlayerContainer, "ТП Ходьба (0.02)", ContainerHeight * 0.23, false, function(state)
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

-- ========== VISUAL TAB ==========
local RenderTitle = Instance.new("TextLabel")
RenderTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.06)
RenderTitle.Position = UDim2.new(0, 0, 0, 5)
RenderTitle.BackgroundTransparency = 1
RenderTitle.Text = "ОТОБРАЖЕНИЕ"
RenderTitle.TextColor3 = colors.accent
RenderTitle.Font = Enum.Font.GothamBold
RenderTitle.TextSize = ContainerHeight * 0.035
RenderTitle.TextXAlignment = Enum.TextXAlignment.Left
RenderTitle.Parent = VisualContainer

-- ESP
local espFrame, espCheck = CreateXONECheckbox(VisualContainer, "ESP (Подсветка)", ContainerHeight * 0.07, false, function(state)
    ESPEnabled = state
    if not state then
        clearAllHighlights()
    end
end)

-- ========== COMBAT TAB ==========
local CombatTitle = Instance.new("TextLabel")
CombatTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.06)
CombatTitle.Position = UDim2.new(0, 0, 0, 5)
CombatTitle.BackgroundTransparency = 1
CombatTitle.Text = "БОЙ"
CombatTitle.TextColor3 = colors.accent
CombatTitle.Font = Enum.Font.GothamBold
CombatTitle.TextSize = ContainerHeight * 0.035
CombatTitle.TextXAlignment = Enum.TextXAlignment.Left
CombatTitle.Parent = CombatContainer

-- Аимбот чекбокс
local aimbotFrame, aimbotCheck = CreateXONECheckbox(CombatContainer, "Аимбот", ContainerHeight * 0.07, false, function(state)
    AimbotEnabled = state
    AimbotButton.Visible = state
    
    if not state then
        AimbotActive = false
        AimbotTarget = nil
        AimbotButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AimbotIndicator.Visible = false
    end
end)

-- Информация
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.1)
infoLabel.Position = UDim2.new(0, 0, 0, ContainerHeight * 0.16)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Нажми на красную кнопку АИМ\nчтобы включить/выключить наведение"
infoLabel.TextColor3 = colors.text2
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = ContainerHeight * 0.03
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = CombatContainer

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

-- ========== TELEPORT TAB ==========
local TeleportTitle = Instance.new("TextLabel")
TeleportTitle.Size = UDim2.new(1, 0, 0, ContainerHeight * 0.06)
TeleportTitle.Position = UDim2.new(0, 0, 0, 5)
TeleportTitle.BackgroundTransparency = 1
TeleportTitle.Text = "ТЕЛЕПОРТ К ИГРОКАМ"
TeleportTitle.TextColor3 = colors.accent
TeleportTitle.Font = Enum.Font.GothamBold
TeleportTitle.TextSize = ContainerHeight * 0.035
TeleportTitle.TextXAlignment = Enum.TextXAlignment.Left
TeleportTitle.Parent = TeleportContainer

local TeleportList = Instance.new("ScrollingFrame")
TeleportList.Size = UDim2.new(1, 0, 1, -ContainerHeight * 0.08)
TeleportList.Position = UDim2.new(0, 0, 0, ContainerHeight * 0.07)
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
            
            yPos = yPos + ContainerHeight * 0.11
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
        noPlayers.TextSize = ContainerHeight * 0.04
        noPlayers.Parent = TeleportList
    end
    
    TeleportList.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
end

spawn(function()
    while true do
        if CurrentTab == "ТЕЛЕПОРТ" then
            pcall(UpdateTeleportList)
        end
        wait(2)
    end
end)

-- ========== ИСПРАВЛЕННЫЙ ESP (БЕЗ LABEL, С БЕЛОЙ ПОДСВЕТКОЙ) ==========

-- Функция создания Highlight
local function createHighlight(model, outlineColor, fillColor)
    -- Удаляем старые Highlight на этой модели
    for _, existing in pairs(model:GetChildren()) do
        if existing:IsA("Highlight") then
            existing:Destroy()
        end
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = model
    highlight.Adornee = model
    highlight.FillTransparency = 0.65 -- Чуть меньше прозрачности для белого
    highlight.FillColor = fillColor
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    
    -- Сохраняем в таблицу
    table.insert(ESPHighlights, highlight)
    
    return highlight
end

-- Функция подсветки группы
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

-- Функция подсветки генераторов
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

-- Функция подсветки других игроков (белым)
local function highlightOtherPlayers()
    local playersGroup = workspace:FindFirstChild("Players")
    if not playersGroup then return end
    
    local killersGroup = playersGroup:FindFirstChild("Killers")
    local survivorsGroup = playersGroup:FindFirstChild("Survivors")
    
    -- Проходим по всем игрокам
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local isInGroup = false
                
                -- Проверяем, есть ли в группе убийц
                if killersGroup then
                    for _, obj in pairs(killersGroup:GetChildren()) do
                        if obj == character then
                            isInGroup = true
                            break
                        end
                    end
                end
                
                -- Проверяем, есть ли в группе выживших
                if not isInGroup and survivorsGroup then
                    for _, obj in pairs(survivorsGroup:GetChildren()) do
                        if obj == character then
                            isInGroup = true
                            break
                        end
                    end
                end
                
                -- Если не в группах - подсвечиваем белым
                if not isInGroup then
                    createHighlight(character, Color3.new(1, 1, 1), Color3.new(0.8, 0.8, 0.8))
                end
            end
        end
    end
end

-- Функция очистки всех Highlight
local function clearAllHighlights()
    for _, highlight in pairs(ESPHighlights) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    ESPHighlights = {}
end

-- ГЛАВНАЯ ФУНКЦИЯ ESP
local function updateESP()
    if not ESPEnabled then 
        clearAllHighlights()
        return 
    end
    
    -- Очищаем старые
    clearAllHighlights()
    
    -- Подсвечиваем убийц (красный)
    local playersGroup = workspace:FindFirstChild("Players")
    if playersGroup then
        local killersGroup = playersGroup:FindFirstChild("Killers")
        highlightGroup(killersGroup, Color3.new(1, 0, 0), Color3.new(1, 0.5, 0.5))
        
        -- Подсвечиваем выживших (зеленый)
        local survivorsGroup = playersGroup:FindFirstChild("Survivors")
        highlightGroup(survivorsGroup, Color3.new(0, 1, 0), Color3.new(0.5, 1, 0.5))
    end
    
    -- Подсвечиваем других игроков (белый)
    highlightOtherPlayers()
    
    -- Подсвечиваем генераторы (желтый)
    highlightGenerators()
end

-- Запускаем ESP цикл
spawn(function()
    while true do
        pcall(updateESP)
        wait(0.5) -- Обновляем чаще для надежности
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

-- AIMBOT LOGIC
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

-- ========== ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ==========
PlayerTab.MouseButton1Click:Connect(function()
    CurrentTab = "ИГРОК"
    PlayerTab.TextColor3 = colors.accent
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    PlayerContainer.Visible = true
    VisualContainer.Visible = false
    TeleportContainer.Visible = false
    CombatContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 15, 1, -2)}):Play()
end)

VisualTab.MouseButton1Click:Connect(function()
    CurrentTab = "ВИЗУАЛ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.accent
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    PlayerContainer.Visible = false
    VisualContainer.Visible = true
    TeleportContainer.Visible = false
    CombatContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 15 + TabWidth + 10, 1, -2)}):Play()
end)

TeleportTab.MouseButton1Click:Connect(function()
    CurrentTab = "ТЕЛЕПОРТ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.accent
    CombatTab.TextColor3 = colors.text2
    PlayerContainer.Visible = false
    VisualContainer.Visible = false
    TeleportContainer.Visible = true
    CombatContainer.Visible = false
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 15 + (TabWidth + 10) * 2, 1, -2)}):Play()
    UpdateTeleportList()
end)

CombatTab.MouseButton1Click:Connect(function()
    CurrentTab = "БОЙ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.accent
    PlayerContainer.Visible = false
    VisualContainer.Visible = false
    TeleportContainer.Visible = false
    CombatContainer.Visible = true
    
    TweenService:Create(TabIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 15 + (TabWidth + 10) * 3, 1, -2)}):Play()
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
end)

-- Главный цикл
RunService.RenderStepped:Connect(function()
    pcall(UpdateFly)
end)

print([[

    ╔══════════════════════════════════════╗
    ║      XONE MOBILE v13.1              ║
    ║         ИСПРАВЛЕННЫЙ ESP             ║
    ║                                      ║
    ║  [КНОПКА X] - Открыть меню           ║
    ║                                      ║
    ║  ESP:                                ║
    ║  🔴 Красный - Убийцы                 ║
    ║  🟢 Зеленый - Выжившие               ║
    ║  ⚪ Белый - Другие игроки            ║
    ║                                      ║
    ║  ✅ ТЕКСТОВЫЕ LABEL УБРАНЫ          ║
    ║  ✅ ДРУГИЕ ИГРОКИ ПОДСВЕЧИВАЮТСЯ    ║
    ╚══════════════════════════════════════╝
]])
