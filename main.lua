--[[
    MAZAMI HUB - WIND UI
    FULL VERSION WITH BACKSTAB, NOCLIP, FLY, ESP, NAMETAGS, GENERATOR ESP, ITEM ESP, AIMBOT, RAGE, MUSIC, CHAT ENABLE, CONFIG SYSTEM
    by ELPRIMO228RB
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== LOAD WINDUI =====
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
    WindUI = loadstring(game:HttpGet("https://pastebin.com/raw/6S5y4RZn"))()
end
if not WindUI then
    error("Failed to load WindUI")
end

-- ===== REGISTER PURPLE THEME =====
WindUI:AddTheme({ 
    Name = "Purple", 
    Accent = Color3.fromRGB(139, 92, 246),
    Dialog = Color3.fromRGB(46, 16, 101),
    Outline = Color3.fromRGB(124, 58, 237),
    Text = Color3.fromRGB(255, 255, 255),
    Placeholder = Color3.fromRGB(167, 139, 250),
    Background = Color3.fromRGB(15, 10, 25),
    Button = Color3.fromRGB(67, 20, 153),
    Icon = Color3.fromRGB(196, 181, 253)
})

-- ===== VARIABLES =====
local TpwalkActive = false
local TpwalkConn = nil
local TpwalkSpeed = 15

local EspEnabled = false
local EspThread = nil
local EspHighlights = {}

local GeneratorEspEnabled = false
local GeneratorEspThread = nil
local GeneratorEspHighlights = {}

local NameTagsEnabled = false
local NameTagsThread = nil
local NameTagsList = {}

local AutoGenEnabled = false
local AutoGenConnection = nil

local AimEnabled = false
local AimConn = nil
local AimRadius = 150

local FovEnabled = false
local FovTarget = 120
local FovConnection = nil
local DefaultFov = 70

local NoclipEnabled = false
local NoclipConnection = nil

local FlyEnabled = false
local FlySpeed = 50
local FlyConnection = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

local JumpPowerValue = 100

local InfiniteStaminaEnabled = false
local StaminaConnection = nil
local StaminaModule = nil

local KillersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
local SurvivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")

local TpHitEnabled = false
local TpHitConnection = nil
local TpHitRadius = 50
local TpHitDuration = 0.2

local MusicSound = nil
local MusicVolume = 50
local CurrentMusicId = "74326888232570"
local IsMusicPlaying = false
local MusicLoop = false

local RageTeleportEnabled = false
local RageTeleportRunning = false
local RageTeleportLoop = nil
local RageTeleportDelay = 0.01

-- ===== BACKSTAB VARIABLES =====
local BackstabEnabled = false
local BackstabConnection = nil
local BackstabLoopConnection = nil
local BackstabDuration = 2
local BackstabCooldown = 0
local BackstabLastUse = 0
local BackstabTarget = nil
local BackstabOriginalCF = nil
local BackstabActive = false
local BackstabDistance = 0.5
local BackstabSmoothSpeed = 0.4
local BackstabRadius = 500

-- ===== ITEM ESP VARIABLES =====
local ItemEspEnabled = false
local ItemEspConnections = {}
local ItemEspHighlights = {}
local ItemEspBillboards = {}

-- ===== CHAT ENABLE VARIABLES =====
local ChatEnabled = false
local ChatConnection = nil

-- ===== CREATE WINDOW WITH MAC BUTTONS =====
local Window = WindUI:CreateWindow({
    Title = "MAZAMI HUB",
    Author = "ELPRIMO228RB",
    Folder = "MAZAMI_HUB",
    Icon = "skull",
    Size = UDim2.fromOffset(500, 580),
    Resizable = true,
    Theme = "Purple",
    Transparent = true,
    AlwaysOnTop = true,
    ToggleKey = Enum.KeyCode.RightShift,
    
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
    
    OpenButton = {
        Title = "🔥 MAZAMI HUB",
        Icon = "skull",
        Enabled = true,
        Draggable = true,
        Scale = 1.0,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#8B5CF6"),
            Color3.fromHex("#2E1065")
        ),
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 3,
        Size = UDim2.fromOffset(180, 60)
    }
})

-- ===== VERSION TAG =====
Window:Tag({
    Title = "v2.0 | ELPRIMO228RB",
    Icon = "code",
    Color = Color3.fromHex("#8B5CF6"),
    Border = true
})

-- ===== NOTIFICATION =====
WindUI:Notify({
    Title = "MAZAMI HUB",
    Content = "Loaded! All features ready!",
    Duration = 3,
    Icon = "flame"
})

-- ===== NOTIFY FUNCTION =====
local function Notify(Title, Content, Duration)
    WindUI:Notify({
        Title = Title,
        Content = Content or "",
        Duration = Duration or 3,
        Icon = nil
    })
end

-- ===== CONFIG SYSTEM (WINDUI BUILT-IN) =====
local ConfigManager = Window.ConfigManager
local CurrentConfig = ConfigManager:CreateConfig("Default")

local function ApplyConfig(config)
    if not config then return end
    
    TpwalkSpeed = config.TpwalkSpeed or 15
    FlySpeed = config.FlySpeed or 50
    JumpPowerValue = config.JumpPower or 100
    AimRadius = config.AimRadius or 150
    BackstabDuration = config.BackstabDuration or 2
    BackstabDistance = config.BackstabDistance or 0.5
    BackstabRadius = config.BackstabRadius or 500
    BackstabCooldown = config.BackstabCooldown or 0
    FovTarget = config.FovValue or 120
    TpHitRadius = config.TpHitRadius or 50
    TpHitDuration = config.TpHitDuration or 0.2
    MusicVolume = config.MusicVolume or 50
    CurrentMusicId = config.MusicId or "74326888232570"
end

CurrentConfig:Load()
ApplyConfig(CurrentConfig.Data)

-- ============================================================
-- ITEM ESP FUNCTIONS
-- ============================================================
local function ClearItemESP()
    for _, Conn in pairs(ItemEspConnections) do
        pcall(function() Conn:Disconnect() end)
    end
    ItemEspConnections = {}
    
    for Obj, H in pairs(ItemEspHighlights) do
        pcall(function() if H and H.Parent then H:Destroy() end end)
    end
    ItemEspHighlights = {}
    
    for _, B in pairs(ItemEspBillboards) do
        pcall(function() if B and B.Parent then B:Destroy() end end)
    end
    ItemEspBillboards = {}
end

local function CreateItemHighlight(Obj, Color)
    if ItemEspHighlights[Obj] then
        local H = ItemEspHighlights[Obj]
        if H and H.Parent then
            H.FillColor = Color
            H.OutlineColor = Color
            return H
        else
            ItemEspHighlights[Obj] = nil
        end
    end
    local H = Instance.new("Highlight")
    H.Name = "ItemESP"
    H.Parent = Obj
    H.Adornee = Obj
    H.FillTransparency = 0.75
    H.FillColor = Color
    H.OutlineColor = Color
    H.OutlineTransparency = 0
    ItemEspHighlights[Obj] = H
    return H
end

local function CreateItemBillboard(Obj, Text, Color)
    local Existing = Obj:FindFirstChildOfClass("BillboardGui")
    if Existing and Existing.Name == "ItemESP" then
        local Label = Existing:FindFirstChildOfClass("TextLabel")
        if Label then
            Label.Text = Text
            Label.TextColor3 = Color
            return Existing
        end
        Existing:Destroy()
    end
    
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ItemESP"
    Billboard.Size = UDim2.new(0, 100, 0, 25)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Obj
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextScaled = true
    Label.TextColor3 = Color
    Label.Text = Text
    Label.Font = Enum.Font.Antique
    Label.Parent = Billboard
    
    table.insert(ItemEspBillboards, Billboard)
    return Billboard
end

local function GetItemColor(ItemName)
    if ItemName == "BloxyCola" then
        return Color3.fromRGB(204, 153, 0)
    elseif ItemName == "Medkit" then
        return Color3.fromRGB(128, 0, 128)
    elseif ItemName == "SubspaceTripmine" then
        return Color3.fromRGB(0, 191, 255)
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

local function AddItemESP(Obj)
    if not Obj or not Obj:IsA("Model") then return end
    if not Obj:FindFirstChildWhichIsA("BasePart") then return end
    
    local ItemName = Obj.Name
    if ItemName ~= "BloxyCola" and ItemName ~= "Medkit" and ItemName ~= "SubspaceTripmine" then
        return
    end
    
    local Color = GetItemColor(ItemName)
    CreateItemHighlight(Obj, Color)
    CreateItemBillboard(Obj, ItemName, Color)
end

local function UpdateItemESP()
    if not ItemEspEnabled then
        ClearItemESP()
        return
    end
    
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    local Ingame = Map:FindFirstChild("Ingame")
    if not Ingame then return end
    
    local CurrentObjects = {}
    
    for _, Obj in pairs(Ingame:GetDescendants()) do
        if Obj:IsA("Model") then
            local Name = Obj.Name
            if Name == "BloxyCola" or Name == "Medkit" or Name == "SubspaceTripmine" then
                if Obj:FindFirstChildWhichIsA("BasePart") then
                    CurrentObjects[Obj] = true
                    AddItemESP(Obj)
                end
            end
        end
    end
    
    for Obj, H in pairs(ItemEspHighlights) do
        if not CurrentObjects[Obj] then
            pcall(function() if H and H.Parent then H:Destroy() end end)
            ItemEspHighlights[Obj] = nil
        end
    end
end

local function ToggleItemESP(State)
    ItemEspEnabled = State
    if ItemEspEnabled then
        UpdateItemESP()
        for _, Conn in pairs(ItemEspConnections) do
            pcall(function() Conn:Disconnect() end)
        end
        ItemEspConnections = {}
        
        local DescConn = workspace.DescendantAdded:Connect(function(Obj)
            if ItemEspEnabled and Obj:IsA("Model") then
                local Name = Obj.Name
                if Name == "BloxyCola" or Name == "Medkit" or Name == "SubspaceTripmine" then
                    task.wait(0.5)
                    if ItemEspEnabled then
                        AddItemESP(Obj)
                    end
                end
            end
        end)
        table.insert(ItemEspConnections, DescConn)
        
        local RemConn = workspace.DescendantRemoving:Connect(function(Obj)
            if Obj:IsA("Model") then
                local H = ItemEspHighlights[Obj]
                if H then
                    pcall(function() H:Destroy() end)
                    ItemEspHighlights[Obj] = nil
                end
                local B = Obj:FindFirstChildOfClass("BillboardGui")
                if B and B.Name == "ItemESP" then
                    pcall(function() B:Destroy() end)
                end
            end
        end)
        table.insert(ItemEspConnections, RemConn)
    else
        ClearItemESP()
    end
end

-- ============================================================
-- CHAT ENABLE FUNCTIONS
-- ============================================================
local function ToggleChat(State)
    ChatEnabled = State
    if ChatEnabled then
        if ChatConnection then ChatConnection:Disconnect() end
        ChatConnection = RunService.Heartbeat:Connect(function()
            if ChatEnabled then
                pcall(function()
                    local TCS = game:GetService("TextChatService")
                    if TCS then
                        TCS.ChatWindowConfiguration.Enabled = true
                    end
                end)
            end
        end)
        Notify("Chat Enabled", "Chat is now enabled!")
    else
        if ChatConnection then
            ChatConnection:Disconnect()
            ChatConnection = nil
        end
        Notify("Chat Disabled", "Chat is now disabled")
    end
end

-- ============================================================
-- GET TEAM
-- ============================================================
local function GetMyTeam()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    local Wp = workspace:FindFirstChild("Players")
    if not Wp then return nil end
    local Killers = Wp:FindFirstChild("Killers")
    local Survivors = Wp:FindFirstChild("Survivors")
    if Killers and Char:IsDescendantOf(Killers) then
        return "Killer"
    elseif Survivors and Char:IsDescendantOf(Survivors) then
        return "Survivor"
    end
    return nil
end

-- ===== GET ALL KILLERS =====
local function GetAllKillers()
    local Killers = {}
    if not KillersFolder then return Killers end
    for _, K in pairs(KillersFolder:GetChildren()) do
        if K and K:IsA("Model") then
            local Hrp = K:FindFirstChild("HumanoidRootPart")
            if Hrp then
                table.insert(Killers, K)
            end
        end
    end
    return Killers
end

-- ===== GET NEAREST KILLER =====
local function GetNearestKiller()
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end
    
    local Killers = GetAllKillers()
    local Closest = nil
    local ClosestDist = BackstabRadius
    
    for _, K in pairs(Killers) do
        local Hrp = K:FindFirstChild("HumanoidRootPart")
        if Hrp then
            local Dist = (Hrp.Position - MyRoot.Position).Magnitude
            if Dist < ClosestDist then
                ClosestDist = Dist
                Closest = K
            end
        end
    end
    
    return Closest
end

-- ===== BACKSTAB FUNCTION =====
local function PerformBackstab()
    if not BackstabEnabled then return end
    if tick() - BackstabLastUse < BackstabCooldown then 
        Notify("Cooldown", "Wait " .. math.floor(BackstabCooldown - (tick() - BackstabLastUse)) .. " sec")
        return 
    end
    if BackstabActive then return end
    
    local MyChar = LocalPlayer.Character
    if not MyChar then 
        Notify("Error", "Character Not Found!")
        return 
    end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then 
        Notify("Error", "RootPart Not Found!")
        return 
    end
    
    local Target = GetNearestKiller()
    if not Target then
        Notify("Error", "No Killers Within " .. BackstabRadius .. " Studs!")
        return
    end
    
    local TargetHrp = Target:FindFirstChild("HumanoidRootPart")
    if not TargetHrp then
        Notify("Error", "Killer Has No RootPart!")
        return
    end
    
    BackstabOriginalCF = MyRoot.CFrame
    BackstabTarget = Target
    BackstabActive = true
    BackstabLastUse = tick()
    
    Notify("Backstab!", "Moving Behind Killer For " .. BackstabDuration .. " sec")
    
    if BackstabLoopConnection then
        BackstabLoopConnection:Disconnect()
        BackstabLoopConnection = nil
    end
    
    local StartTime = tick()
    BackstabLoopConnection = RunService.Heartbeat:Connect(function()
        if not BackstabActive or not BackstabTarget or not BackstabTarget.Parent then
            BackstabActive = false
            if BackstabLoopConnection then
                BackstabLoopConnection:Disconnect()
                BackstabLoopConnection = nil
            end
            return
        end
        
        if tick() - StartTime >= BackstabDuration then
            local MyCharNow = LocalPlayer.Character
            if MyCharNow then
                local MyRootNow = MyCharNow:FindFirstChild("HumanoidRootPart")
                if MyRootNow and BackstabOriginalCF then
                    MyRootNow.CFrame = BackstabOriginalCF
                end
            end
            
            BackstabActive = false
            if BackstabLoopConnection then
                BackstabLoopConnection:Disconnect()
                BackstabLoopConnection = nil
            end
            Notify("Return", "You Returned To Original Position")
            return
        end
        
        local TargetHrpNow = BackstabTarget:FindFirstChild("HumanoidRootPart")
        if TargetHrpNow then
            local LookVector = TargetHrpNow.CFrame.LookVector
            local TargetPos = TargetHrpNow.Position
            
            local BehindPos = TargetPos - (LookVector * BackstabDistance)
            BehindPos = Vector3.new(BehindPos.X, TargetPos.Y, BehindPos.Z)
            local TargetCF = CFrame.new(BehindPos, TargetPos)
            
            local MyCharNow = LocalPlayer.Character
            if MyCharNow then
                local MyRootNow = MyCharNow:FindFirstChild("HumanoidRootPart")
                if MyRootNow then
                    local CurrentCF = MyRootNow.CFrame
                    local NewCF = CurrentCF:Lerp(TargetCF, BackstabSmoothSpeed)
                    MyRootNow.CFrame = NewCF
                end
            end
        end
    end)
end

-- ===== TOGGLE BACKSTAB =====
local function ToggleBackstab(State)
    BackstabEnabled = State
    if BackstabEnabled then
        if BackstabConnection then BackstabConnection:Disconnect() end
        BackstabConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
            if GameProcessed then return end
            if Input.KeyCode == Enum.KeyCode.Q then
                PerformBackstab()
            end
        end)
        Notify("Backstab On", "Press Q To Move Behind Killer!")
    else
        if BackstabConnection then
            BackstabConnection:Disconnect()
            BackstabConnection = nil
        end
        if BackstabLoopConnection then
            BackstabLoopConnection:Disconnect()
            BackstabLoopConnection = nil
        end
        if BackstabActive then
            local MyChar = LocalPlayer.Character
            if MyChar then
                local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
                if MyRoot and BackstabOriginalCF then
                    MyRoot.CFrame = BackstabOriginalCF
                end
            end
            BackstabActive = false
            BackstabOriginalCF = nil
        end
        Notify("Backstab Off", "Function Disabled")
    end
end

-- ===== NAMETAGS =====
local function ClearNameTags()
    for _, Tag in pairs(NameTagsList) do
        if Tag and Tag.Parent then
            Tag:Destroy()
        end
    end
    NameTagsList = {}
end

local function CreateNameTag(Player)
    local Char = Player.Character
    if not Char then return nil end
    local Head = Char:FindFirstChild("Head")
    if not Head then return nil end
    
    for _, Tag in pairs(NameTagsList) do
        if Tag and Tag.Parent == Head then
            return Tag
        end
    end
    
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "NameTag"
    Billboard.Size = UDim2.new(0, 150, 0, 40)
    Billboard.AlwaysOnTop = true
    Billboard.MaxDistance = math.huge
    Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    Billboard.Parent = Head
    
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Background.BackgroundTransparency = 0.5
    Background.BorderSizePixel = 0
    Background.Parent = Billboard
    
    local BgCorner = Instance.new("UICorner")
    BgCorner.CornerRadius = UDim.new(0, 4)
    BgCorner.Parent = Background
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    NameLabel.Position = UDim2.new(0, 0, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = Player.Name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextScaled = true
    NameLabel.Parent = Billboard
    
    local HealthLabel = Instance.new("TextLabel")
    HealthLabel.Size = UDim2.new(1, 0, 0.4, 0)
    HealthLabel.Position = UDim2.new(0, 0, 0.6, 0)
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.Text = ""
    HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    HealthLabel.TextSize = 12
    HealthLabel.Font = Enum.Font.Gotham
    HealthLabel.TextScaled = true
    HealthLabel.Parent = Billboard
    
    table.insert(NameTagsList, Billboard)
    return Billboard
end

local function UpdateNameTags()
    if not NameTagsEnabled then
        ClearNameTags()
        return
    end
    
    local ToRemove = {}
    for i, Tag in pairs(NameTagsList) do
        if not Tag or not Tag.Parent then
            table.insert(ToRemove, i)
        end
    end
    for i = #ToRemove, 1, -1 do
        local Idx = ToRemove[i]
        if NameTagsList[Idx] then
            NameTagsList[Idx]:Destroy()
        end
        table.remove(NameTagsList, Idx)
    end
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Char = Player.Character
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            local Head = Char:FindFirstChild("Head")
            if Hum and Head then
                local Tag = CreateNameTag(Player)
                if Tag then
                    local HealthLabel = Tag:FindFirstChild("HealthLabel")
                    if HealthLabel then
                        local Health = math.floor(Hum.Health)
                        local MaxHealth = math.floor(Hum.MaxHealth)
                        HealthLabel.Text = Health .. "/" .. MaxHealth
                        
                        local Percent = Hum.Health / Hum.MaxHealth
                        if Percent > 0.5 then
                            HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        elseif Percent > 0.25 then
                            HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                        else
                            HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                        end
                    end
                    
                    local NameLabel = Tag:FindFirstChild("NameLabel")
                    if NameLabel then
                        local Wp = workspace:FindFirstChild("Players")
                        if Wp then
                            if Wp:FindFirstChild("Killers") and Char:IsDescendantOf(Wp.Killers) then
                                NameLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                            elseif Wp:FindFirstChild("Survivors") and Char:IsDescendantOf(Wp.Survivors) then
                                NameLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                            else
                                NameLabel.TextColor3 = Color3.fromRGB(169, 169, 169)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ===== GENERATOR ESP =====
local function ClearGeneratorESP()
    for Obj, H in pairs(GeneratorEspHighlights) do
        if H and H.Parent then
            H:Destroy()
        end
    end
    GeneratorEspHighlights = {}
end

local function UpdateGeneratorESP()
    if not GeneratorEspEnabled then
        ClearGeneratorESP()
        return
    end
    
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    local Ingame = Map:FindFirstChild("Ingame")
    if not Ingame then return end
    local GameMap = Ingame:FindFirstChild("Map")
    if not GameMap then return end
    
    local CurrentObjects = {}
    
    for _, Obj in pairs(GameMap:GetChildren()) do
        if Obj:IsA("Model") and Obj.Name == "Generator" then
            local Progress = Obj:FindFirstChild("Progress")
            local ExistingESP = Obj:FindFirstChild("ESP_Generator")
            
            local IsFixed = Progress and Progress.Value >= 100
            
            if IsFixed then
                if not ExistingESP then
                    local Highlight = Instance.new("Highlight")
                    Highlight.Name = "ESP_Generator"
                    Highlight.Adornee = Obj
                    Highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    Highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
                    Highlight.FillTransparency = 0.3
                    Highlight.OutlineTransparency = 0
                    Highlight.Parent = Obj
                    GeneratorEspHighlights[Obj] = Highlight
                else
                    ExistingESP.FillColor = Color3.fromRGB(0, 255, 0)
                    ExistingESP.OutlineColor = Color3.fromRGB(0, 200, 0)
                    ExistingESP.FillTransparency = 0.3
                    GeneratorEspHighlights[Obj] = ExistingESP
                end
                CurrentObjects[Obj] = true
            elseif Progress and Progress.Value < 100 then
                if not ExistingESP then
                    local Highlight = Instance.new("Highlight")
                    Highlight.Name = "ESP_Generator"
                    Highlight.Adornee = Obj
                    Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    Highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
                    Highlight.FillTransparency = 0.5
                    Highlight.OutlineTransparency = 0
                    Highlight.Parent = Obj
                    GeneratorEspHighlights[Obj] = Highlight
                else
                    ExistingESP.FillColor = Color3.fromRGB(255, 0, 0)
                    ExistingESP.OutlineColor = Color3.fromRGB(200, 0, 0)
                    ExistingESP.FillTransparency = 0.5
                    GeneratorEspHighlights[Obj] = ExistingESP
                end
                CurrentObjects[Obj] = true
            else
                if ExistingESP then
                    ExistingESP:Destroy()
                    GeneratorEspHighlights[Obj] = nil
                end
            end
        end
    end
    
    for Obj, H in pairs(GeneratorEspHighlights) do
        if not CurrentObjects[Obj] then
            if H and H.Parent then
                H:Destroy()
            end
            GeneratorEspHighlights[Obj] = nil
        end
    end
end

-- ===== GENERATORS FIX =====
local function FixGens()
    local Map = workspace:FindFirstChild("Map")
    if Map then
        local Ingame = Map:FindFirstChild("Ingame")
        if Ingame then
            local M = Ingame:FindFirstChild("Map")
            if M then
                for _, Obj in pairs(M:GetChildren()) do
                    if Obj:IsA("Model") and Obj.Name == "Generator" then
                        local Remotes = Obj:FindFirstChild("Remotes")
                        if Remotes then
                            local Re = Remotes:FindFirstChild("RE")
                            if Re then
                                Re:FireServer()
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ===== FOV =====
local function ToggleFov(State)
    FovEnabled = State
    if FovConnection then FovConnection:Disconnect() FovConnection = nil end
    if State then
        local Cam = workspace.CurrentCamera
        if Cam then DefaultFov = Cam.FieldOfView end
        FovConnection = RunService.RenderStepped:Connect(function()
            if FovEnabled then
                local Cam = workspace.CurrentCamera
                if Cam and Cam.FieldOfView ~= FovTarget then
                    Cam.FieldOfView = FovTarget
                end
            end
        end)
        local Cam = workspace.CurrentCamera
        if Cam then Cam.FieldOfView = FovTarget end
        Notify("FOV On", "FOV: " .. FovTarget .. "°")
    else
        local Cam = workspace.CurrentCamera
        if Cam then Cam.FieldOfView = DefaultFov end
        Notify("FOV Off", "FOV Restored")
    end
end

local function UpdateFov(Value)
    FovTarget = Value
    if FovEnabled then
        local Cam = workspace.CurrentCamera
        if Cam then Cam.FieldOfView = Value end
        Notify("FOV Updated", "New Value: " .. Value .. "°")
    end
end

-- ===== NOCLIP =====
local function ToggleNoclip(State)
    NoclipEnabled = State
    if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
    if State then
        NoclipConnection = RunService.Heartbeat:Connect(function()
            if not NoclipEnabled then return end
            local Char = LocalPlayer.Character
            if not Char then return end
            for _, Part in pairs(Char:GetDescendants()) do
                if Part:IsA("BasePart") then
                    Part.CanCollide = false
                end
            end
        end)
        Notify("Noclip On", "You May Get Banned")
    else
        local Char = LocalPlayer.Character
        if Char then
            for _, Part in pairs(Char:GetDescendants()) do
                if Part:IsA("BasePart") then
                    Part.CanCollide = true
                end
            end
        end
        Notify("Noclip Off", "Collision Restored")
    end
end

-- ===== FLY =====
local function ToggleFly(State)
    FlyEnabled = State
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    
    if State then
        local Char = LocalPlayer.Character
        if not Char then
            Notify("Error", "Character Not Found!")
            FlyEnabled = false
            return
        end
        local Hrp = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChildOfClass("Humanoid")
        if not Hrp or not Hum then
            Notify("Error", "Humanoid Not Found!")
            FlyEnabled = false
            return
        end
        
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.Parent = Hrp
        
        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        FlyBodyGyro.D = 500
        FlyBodyGyro.P = 5000
        FlyBodyGyro.CFrame = Hrp.CFrame
        FlyBodyGyro.Parent = Hrp
        
        Hum.PlatformStand = true
        Hum.WalkSpeed = 0
        Hum.JumpPower = 0
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not FlyEnabled or not Hrp or not Hrp.Parent then return end
            local MoveVector = Vector3.new(0, 0, 0)
            local Cam = workspace.CurrentCamera
            if not Cam then return end
            local Forward = Cam.CFrame.LookVector
            local Right = Cam.CFrame.RightVector
            local Up = Cam.CFrame.UpVector
            local ForwardInput = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
            local BackwardInput = UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
            local LeftInput = UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0
            local RightInput = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
            local UpInput = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0
            local DownInput = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0
            MoveVector = (Forward * (ForwardInput - BackwardInput) * FlySpeed)
            MoveVector = MoveVector + (Right * (RightInput - LeftInput) * FlySpeed)
            MoveVector = MoveVector + (Up * (UpInput - DownInput) * FlySpeed)
            if MoveVector.Magnitude > 0 then
                FlyBodyVelocity.Velocity = MoveVector
            else
                FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            if MoveVector.Magnitude > 0.1 then
                FlyBodyGyro.CFrame = CFrame.new(Hrp.Position, Hrp.Position + MoveVector.Unit)
            end
        end)
        Notify("Fly On", "WASD - Move, Space - Up, Shift - Down")
    else
        local Char = LocalPlayer.Character
        if Char then
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            if Hum then
                Hum.PlatformStand = false
                Hum.WalkSpeed = 16
                Hum.JumpPower = 50
            end
        end
        Notify("Fly Off", "Flight Mode Disabled")
    end
end

-- ===== ESP =====
local function ClearESP()
    for Obj, H in pairs(EspHighlights) do
        if H and H.Parent then
            H:Destroy()
        end
    end
    EspHighlights = {}
end

local function CreateHighlight(Obj, OutlineColor, FillColor, FillTransparency)
    if EspHighlights[Obj] then
        local H = EspHighlights[Obj]
        if H and H.Parent then
            H.OutlineColor = OutlineColor
            H.FillColor = FillColor
            if FillTransparency then H.FillTransparency = FillTransparency end
            return H
        else
            EspHighlights[Obj] = nil
        end
    end
    local H = Instance.new("Highlight")
    H.Parent = Obj
    H.Adornee = Obj
    H.FillTransparency = FillTransparency or 0.75
    H.FillColor = FillColor
    H.OutlineColor = OutlineColor
    H.OutlineTransparency = 0
    H.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    EspHighlights[Obj] = H
    return H
end

local function UpdateESP()
    if not EspEnabled then
        ClearESP()
        return
    end
    local CurrentObjects = {}
    local PlayersFolder = workspace:FindFirstChild("Players")
    if PlayersFolder then
        local Killers = PlayersFolder:FindFirstChild("Killers")
        if Killers then
            for _, Obj in pairs(Killers:GetChildren()) do
                if Obj:IsA("Model") then
                    local Hum = Obj:FindFirstChildOfClass("Humanoid")
                    if Hum and Obj:FindFirstChild("HumanoidRootPart") and Hum.Health > 0 then
                        CurrentObjects[Obj] = true
                        CreateHighlight(Obj, Color3.new(1, 0, 0), Color3.new(1, 0.3, 0.3), 0.6)
                    end
                end
            end
        end
        local Survivors = PlayersFolder:FindFirstChild("Survivors")
        if Survivors then
            for _, Obj in pairs(Survivors:GetChildren()) do
                if Obj:IsA("Model") then
                    local Hum = Obj:FindFirstChildOfClass("Humanoid")
                    if Hum and Obj:FindFirstChild("HumanoidRootPart") and Hum.Health > 0 then
                        CurrentObjects[Obj] = true
                        CreateHighlight(Obj, Color3.new(0, 1, 0), Color3.new(0.3, 1, 0.3), 0.6)
                    end
                end
            end
        end
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and Player.Character then
                local Char = Player.Character
                if Char then
                    local IsKiller = Killers and Char:IsDescendantOf(Killers)
                    local IsSurvivor = Survivors and Char:IsDescendantOf(Survivors)
                    if not IsKiller and not IsSurvivor then
                        local Hum = Char:FindFirstChildOfClass("Humanoid")
                        if Hum and Char:FindFirstChild("HumanoidRootPart") and Hum.Health > 0 then
                            CurrentObjects[Char] = true
                            CreateHighlight(Char, Color3.fromRGB(169, 169, 169), Color3.fromRGB(169, 169, 169), 0.7)
                        end
                    end
                end
            end
        end
    end
    for Obj, H in pairs(EspHighlights) do
        if not CurrentObjects[Obj] then
            if H and H.Parent then
                H:Destroy()
            end
            EspHighlights[Obj] = nil
        end
    end
end

-- ===== AIMBOT (KILLER→SURVIVORS, SURVIVOR→KILLERS) =====
local function GetAimTargets()
    local Targets = {}
    local MyTeam = GetMyTeam()
    local Wp = workspace:FindFirstChild("Players")
    if not Wp then return Targets end
    
    local TargetGroup = nil
    if MyTeam == "Killer" then
        TargetGroup = Wp:FindFirstChild("Survivors")
    elseif MyTeam == "Survivor" then
        TargetGroup = Wp:FindFirstChild("Killers")
    end
    
    if not TargetGroup then return Targets end
    
    for _, Obj in pairs(TargetGroup:GetChildren()) do
        if Obj:IsA("Model") then
            local Hum = Obj:FindFirstChild("Humanoid")
            local Hrp = Obj:FindFirstChild("HumanoidRootPart")
            if Hum and Hrp and Hum.Health > 0 then
                table.insert(Targets, Obj)
            end
        end
    end
    return Targets
end

local function AimFunc()
    if not AimEnabled then return end
    local Char = LocalPlayer.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    local Targets = GetAimTargets()
    local Closest = nil
    local BestDist = AimRadius
    for _, Target in pairs(Targets) do
        local Hrp = Target:FindFirstChild("HumanoidRootPart")
        if Hrp then
            local Dist = (Root.Position - Hrp.Position).Magnitude
            if Dist < BestDist then
                BestDist = Dist
                Closest = Target
            end
        end
    end
    if Closest then
        local Hrp = Closest:FindFirstChild("HumanoidRootPart")
        if Hrp then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Hrp.Position)
        end
    end
end

-- ===== STAMINA =====
local function ToggleInfiniteStamina(State)
    InfiniteStaminaEnabled = State
    if StaminaConnection then StaminaConnection:Disconnect() StaminaConnection = nil end
    if State then
        local Success, Module = pcall(function()
            return require(game.ReplicatedStorage.Systems.Character.Game.Sprinting)
        end)
        if Success and Module then
            StaminaModule = Module
            StaminaModule.StaminaLossDisabled = function() end
            StaminaConnection = RunService.Heartbeat:Connect(function()
                if InfiniteStaminaEnabled and StaminaModule then
                    StaminaModule.StaminaLossDisabled = function() end
                end
            end)
        end
    else
        if StaminaModule then
            StaminaModule.StaminaLossDisabled = nil
            StaminaModule = nil
        end
    end
end

-- ============================================================
-- CREATE WINDUI TABS
-- ============================================================

-- ===== PLAYER TAB =====
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
    Border = true
})

PlayerTab:Section({
    Title = "TP Walk"
})

PlayerTab:Toggle({
    Title = "TP Walk",
    Desc = "Teleports when moving WASD",
    Flag = "TpwalkToggle",
    Value = false,
    Callback = function(Value)
        TpwalkActive = Value
        if TpwalkActive then
            if TpwalkConn then TpwalkConn:Disconnect() end
            TpwalkConn = RunService.RenderStepped:Connect(function()
                if not TpwalkActive then return end
                local Char = LocalPlayer.Character
                if not Char then return end
                local Hum = Char:FindFirstChild("Humanoid")
                local Hrp = Char:FindFirstChild("HumanoidRootPart")
                if not Hum or not Hrp then return end
                local Dir = Hum.MoveDirection
                if Dir.Magnitude > 0 then
                    Hrp.CFrame = Hrp.CFrame + (Dir * (TpwalkSpeed / 100))
                end
            end)
        else
            if TpwalkConn then TpwalkConn:Disconnect() end
            TpwalkConn = nil
        end
    end
})

PlayerTab:Slider({
    Title = "TP Walk Speed",
    Desc = "Teleport speed",
    Flag = "TpwalkSpeed",
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 5,
        Max = 100,
        Default = 15
    },
    Callback = function(Value)
        TpwalkSpeed = Value
    end
})

PlayerTab:Space()
PlayerTab:Space()

PlayerTab:Section({
    Title = "Jump"
})

PlayerTab:Toggle({
    Title = "Enable Jump",
    Desc = "Enables jumping ability",
    Flag = "JumpToggle",
    Value = false,
    Callback = function(Value)
        if Value then
            local Char = LocalPlayer.Character
            if Char then
                local Hum = Char:FindFirstChildOfClass("Humanoid")
                if Hum then
                    Hum.JumpPower = 50
                    Hum.JumpEnabled = true
                    Notify("Jump On", "Jump Activated!")
                end
            end
        else
            local Char = LocalPlayer.Character
            if Char then
                local Hum = Char:FindFirstChildOfClass("Humanoid")
                if Hum then
                    Hum.JumpPower = 0
                    Hum.JumpEnabled = false
                    Notify("Jump Off", "Jump Deactivated!")
                end
            end
        end
    end
})

PlayerTab:Slider({
    Title = "Jump Power",
    Desc = "Jump strength",
    Flag = "JumpPower",
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 10,
        Max = 200,
        Default = 100
    },
    Callback = function(Value)
        JumpPowerValue = Value
        local Char = LocalPlayer.Character
        if Char then
            local Hum = Char:FindFirstChildOfClass("Humanoid")
            if Hum then
                local Power = (Value / 100) * 50
                Hum.JumpPower = Power
            end
        end
    end
})

PlayerTab:Space()
PlayerTab:Space()

PlayerTab:Section({
    Title = "Dangerous Functions"
})

PlayerTab:Toggle({
    Title = "Noclip (You May Get Banned)",
    Desc = "Walk through walls",
    Flag = "NoclipToggle",
    Value = false,
    Callback = function(Value)
        ToggleNoclip(Value)
    end
})

PlayerTab:Toggle({
    Title = "Fly (You May Get Banned)",
    Desc = "Flight mode",
    Flag = "FlyToggle",
    Value = false,
    Callback = function(Value)
        ToggleFly(Value)
    end
})

PlayerTab:Slider({
    Title = "Fly Speed",
    Desc = "Flight speed",
    Flag = "FlySpeed",
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 10,
        Max = 200,
        Default = 50
    },
    Callback = function(Value)
        FlySpeed = Value
    end
})

-- ===== VISUAL TAB =====
local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "eye",
    Border = true
})

VisualTab:Section({
    Title = "ESP"
})

VisualTab:Toggle({
    Title = "Player ESP",
    Desc = "Highlight players (Killers=RED, Survivors=GREEN, Others=GRAY)",
    Flag = "EspToggle",
    Value = false,
    Callback = function(Value)
        EspEnabled = Value
        if EspEnabled then
            UpdateESP()
            if EspThread then EspThread:Disconnect() end
            EspThread = RunService.Heartbeat:Connect(function()
                if EspEnabled then UpdateESP() end
            end)
        else
            if EspThread then EspThread:Disconnect() end
            ClearESP()
        end
    end
})

VisualTab:Space()
VisualTab:Space()

VisualTab:Section({
    Title = "Item ESP"
})

VisualTab:Toggle({
    Title = "Item ESP",
    Desc = "Highlight items (BloxyCola=Gold, Medkit=Purple, Tripmine=Blue)",
    Flag = "ItemEspToggle",
    Value = false,
    Callback = function(Value)
        ToggleItemESP(Value)
    end
})

VisualTab:Space()
VisualTab:Space()

VisualTab:Section({
    Title = "Generator ESP"
})

VisualTab:Toggle({
    Title = "Generator ESP",
    Desc = "Highlight generators (RED when incomplete, GREEN when fixed)",
    Flag = "GeneratorEspToggle",
    Value = false,
    Callback = function(Value)
        GeneratorEspEnabled = Value
        if GeneratorEspEnabled then
            UpdateGeneratorESP()
            if GeneratorEspThread then GeneratorEspThread:Disconnect() end
            GeneratorEspThread = RunService.Heartbeat:Connect(function()
                if GeneratorEspEnabled then UpdateGeneratorESP() end
            end)
        else
            if GeneratorEspThread then GeneratorEspThread:Disconnect() end
            ClearGeneratorESP()
        end
    end
})

VisualTab:Space()
VisualTab:Space()

VisualTab:Section({
    Title = "Name Tags"
})

VisualTab:Toggle({
    Title = "Show Name Tags",
    Desc = "Show name tags above players",
    Flag = "NameTagsToggle",
    Value = false,
    Callback = function(Value)
        NameTagsEnabled = Value
        if NameTagsEnabled then
            UpdateNameTags()
            if NameTagsThread then NameTagsThread:Disconnect() end
            NameTagsThread = RunService.Heartbeat:Connect(function()
                if NameTagsEnabled then UpdateNameTags() end
            end)
        else
            if NameTagsThread then NameTagsThread:Disconnect() end
            ClearNameTags()
        end
    end
})

VisualTab:Space()
VisualTab:Space()

VisualTab:Section({
    Title = "FOV"
})

VisualTab:Toggle({
    Title = "Enable FOV",
    Desc = "Increase field of view",
    Flag = "FovToggle",
    Value = false,
    Callback = function(Value)
        ToggleFov(Value)
    end
})

VisualTab:Slider({
    Title = "FOV Value",
    Desc = "Field of view angle",
    Flag = "FovValue",
    IsTooltip = true,
    Step = 1,
    Value = {
        Min = 70,
        Max = 500,
        Default = 120
    },
    Callback = function(Value)
        FovTarget = Value
        UpdateFov(Value)
    end
})

VisualTab:Space()
VisualTab:Space()

VisualTab:Section({
    Title = "Lighting & Fog"
})

VisualTab:Button({
    Title = "Full Brightness",
    Desc = "Enable maximum lighting",
    Callback = function()
        game.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        game.Lighting.Brightness = 1
        game.Lighting.FogEnd = 1e10
        game.Lighting.FogStart = 100000
        game.Lighting.TimeOfDay = "12:00:00"
        game.Lighting.Technology = Enum.Technology.Future
        Notify("Lighting", "Full Brightness Activated!")
    end
})

VisualTab:Button({
    Title = "Remove Fog",
    Desc = "Fully removes fog",
    Callback = function()
        game.Lighting.FogStart = math.huge
        game.Lighting.FogEnd = math.huge
        Notify("Fog Removed", "Fog Completely Disabled!")
    end
})

-- ===== STAMINA TAB =====
local StaminaTab = Window:Tab({
    Title = "Stamina",
    Icon = "bolt",
    Border = true
})

StaminaTab:Toggle({
    Title = "Infinite Stamina",
    Desc = "Unlimited stamina",
    Flag = "InfiniteStamina",
    Value = false,
    Callback = function(Value)
        ToggleInfiniteStamina(Value)
    end
})

-- ===== GENERATORS TAB =====
local GenTab = Window:Tab({
    Title = "Generators",
    Icon = "zap",
    Border = true
})

GenTab:Toggle({
    Title = "Auto-Fix Generators",
    Desc = "Automatically fix generators every 2.5 seconds",
    Flag = "AutoGenToggle",
    Value = false,
    Callback = function(Value)
        AutoGenEnabled = Value
        if AutoGenEnabled then
            local LastFix = 0
            AutoGenConnection = RunService.Stepped:Connect(function()
                if not AutoGenEnabled then return end
                local Now = tick()
                if Now - LastFix >= 2.5 then
                    LastFix = Now
                    FixGens()
                end
            end)
            Notify("Auto-Fix On", "Generators will be fixed every 2.5 seconds")
        else
            if AutoGenConnection then
                AutoGenConnection:Disconnect()
                AutoGenConnection = nil
            end
            Notify("Auto-Fix Off", "Auto fix disabled")
        end
    end
})

-- ===== AIMBOT TAB =====
local AimTab = Window:Tab({
    Title = "Aimbot",
    Icon = "target",
    Border = true
})

AimTab:Toggle({
    Title = "Aimbot",
    Desc = "Auto aim (Killer→Survivors, Survivor→Killers)",
    Flag = "AimToggle",
    Value = false,
    Callback = function(Value)
        AimEnabled = Value
        if AimEnabled then
            if AimConn then AimConn:Disconnect() end
            AimConn = RunService.RenderStepped:Connect(AimFunc)
            Notify("Aimbot On", "Auto aim activated!")
        else
            if AimConn then AimConn:Disconnect() end
            AimConn = nil
            Notify("Aimbot Off", "Auto aim disabled")
        end
    end
})

AimTab:Slider({
    Title = "Aim Radius",
    Desc = "Target search distance",
    Flag = "AimRadius",
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 50,
        Max = 300,
        Default = 150
    },
    Callback = function(Value)
        AimRadius = Value
    end
})

-- ===== SURVIVOR TAB =====
local SurvivorTab = Window:Tab({
    Title = "Survivor",
    Icon = "users",
    Border = true
})

SurvivorTab:Section({
    Title = "Two Time"
})

SurvivorTab:Section({
    Title = "🗡️ Backstab"
})

SurvivorTab:Toggle({
    Title = "Enable Backstab",
    Desc = "Press Q to move behind killer",
    Flag = "BackstabToggle",
    Value = false,
    Callback = function(Value)
        ToggleBackstab(Value)
    end
})

SurvivorTab:Slider({
    Title = "Duration (sec)",
    Desc = "Time behind killer",
    Flag = "BackstabDuration",
    IsTooltip = true,
    Step = 0.5,
    Value = {
        Min = 0.5,
        Max = 5,
        Default = 2
    },
    Callback = function(Value)
        BackstabDuration = Value
    end
})

SurvivorTab:Slider({
    Title = "Distance (studs)",
    Desc = "Distance from killer",
    Flag = "BackstabDistance",
    IsTooltip = true,
    Step = 0.1,
    Value = {
        Min = 0.1,
        Max = 2,
        Default = 0.5
    },
    Callback = function(Value)
        BackstabDistance = Value
    end
})

SurvivorTab:Slider({
    Title = "Search Radius (studs)",
    Desc = "Maximum distance to search for killer",
    Flag = "BackstabRadius",
    IsTooltip = true,
    Step = 10,
    Value = {
        Min = 10,
        Max = 500,
        Default = 500
    },
    Callback = function(Value)
        BackstabRadius = Value
    end
})

SurvivorTab:Slider({
    Title = "Cooldown (sec)",
    Desc = "Delay between uses",
    Flag = "BackstabCooldown",
    IsTooltip = true,
    Step = 0.5,
    Value = {
        Min = 0,
        Max = 10,
        Default = 0
    },
    Callback = function(Value)
        BackstabCooldown = Value
    end
})

SurvivorTab:Button({
    Title = "Manual Backstab",
    Desc = "Move behind killer manually",
    Callback = function()
        PerformBackstab()
    end
})

-- ===== RAGE TAB =====
local RageTab = Window:Tab({
    Title = "Rage",
    Icon = "skull",
    Border = true
})

RageTab:Section({
    Title = "Infinite Teleport Behind Back"
})

RageTab:Toggle({
    Title = "Enable Rage",
    Desc = "Infinite teleport behind survivors",
    Flag = "RageToggle",
    Value = false,
    Callback = function(Value)
        RageTeleportEnabled = Value
        if Value then
            if not RageTeleportRunning then
                RageTeleportRunning = true
                RageTeleportLoop = RunService.Heartbeat:Connect(function()
                    if RageTeleportRunning and RageTeleportEnabled then
                        local Survivors = {}
                        local SurvivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                        if SurvivorsFolder then
                            for _, Obj in pairs(SurvivorsFolder:GetChildren()) do
                                if Obj:IsA("Model") and Obj ~= LocalPlayer.Character then
                                    local Hum = Obj:FindFirstChildOfClass("Humanoid")
                                    local Hrp = Obj:FindFirstChild("HumanoidRootPart")
                                    if Hum and Hrp and Hum.Health > 0 then
                                        table.insert(Survivors, Obj)
                                    end
                                end
                            end
                        end
                        if #Survivors > 0 then
                            local Target = Survivors[math.random(1, #Survivors)]
                            local SurvivorHrp = Target:FindFirstChild("HumanoidRootPart")
                            if SurvivorHrp then
                                local MyChar = LocalPlayer.Character
                                if MyChar then
                                    local MyHrp = MyChar:FindFirstChild("HumanoidRootPart")
                                    if MyHrp then
                                        local BehindPos = SurvivorHrp.Position - (SurvivorHrp.CFrame.LookVector * 3)
                                        BehindPos = Vector3.new(BehindPos.X, BehindPos.Y + 1.5, BehindPos.Z)
                                        MyHrp.CFrame = CFrame.new(BehindPos, SurvivorHrp.Position)
                                    end
                                end
                            end
                        end
                        task.wait(RageTeleportDelay)
                    end
                end)
            end
            Notify("Rage On", "Infinite Teleport Behind Back Activated!")
        else
            RageTeleportRunning = false
            RageTeleportEnabled = false
            if RageTeleportLoop then
                RageTeleportLoop:Disconnect()
                RageTeleportLoop = nil
            end
            Notify("Rage Off", "Teleport Disabled")
        end
    end
})

RageTab:Slider({
    Title = "Teleport Delay (sec)",
    Desc = "Delay between teleports",
    Flag = "RageDelay",
    IsTooltip = true,
    Step = 0.001,
    Value = {
        Min = 0.001,
        Max = 0.5,
        Default = 0.01
    },
    Callback = function(Value)
        RageTeleportDelay = Value
    end
})

-- ===== HvH TAB =====
local HvHTab = Window:Tab({
    Title = "HvH",
    Icon = "swords",
    Border = true
})

HvHTab:Section({
    Title = "TP Hit"
})

HvHTab:Toggle({
    Title = "TP Hit",
    Desc = "Teleport to victim on hit",
    Flag = "TPHitToggle",
    Value = false,
    Callback = function(Value)
        TpHitEnabled = Value
        if TpHitEnabled then
            if TpHitConnection then TpHitConnection:Disconnect() end
            TpHitConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if GameProcessed then return end
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if TpHitEnabled then
                        local MyChar = LocalPlayer.Character
                        if not MyChar then return end
                        local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
                        if not MyRoot then return end
                        local SurvivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                        if not SurvivorsFolder then return end
                        local Target = nil
                        local TargetDist = TpHitRadius
                        for _, Survivor in pairs(SurvivorsFolder:GetChildren()) do
                            if Survivor:IsA("Model") and Survivor ~= MyChar then
                                local Hrp = Survivor:FindFirstChild("HumanoidRootPart")
                                local Hum = Survivor:FindFirstChildOfClass("Humanoid")
                                if Hrp and Hum and Hum.Health > 0 then
                                    local Dist = (Hrp.Position - MyRoot.Position).Magnitude
                                    if Dist < TargetDist then
                                        TargetDist = Dist
                                        Target = Survivor
                                    end
                                end
                            end
                        end
                        if Target then
                            local TargetHrp = Target:FindFirstChild("HumanoidRootPart")
                            if TargetHrp then
                                local OriginalCFrame = MyRoot.CFrame
                                local TargetPos = TargetHrp.Position + (TargetHrp.CFrame.LookVector * 2)
                                MyRoot.CFrame = CFrame.new(TargetPos, TargetHrp.Position)
                                task.wait(TpHitDuration)
                                if MyRoot and MyRoot.Parent then
                                    MyRoot.CFrame = OriginalCFrame
                                end
                            end
                        end
                    end
                end
            end)
        else
            if TpHitConnection then
                TpHitConnection:Disconnect()
                TpHitConnection = nil
            end
        end
    end
})

HvHTab:Slider({
    Title = "TP Hit Radius",
    Desc = "Target search radius",
    Flag = "TPHitRadius",
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 10,
        Max = 100,
        Default = 50
    },
    Callback = function(Value)
        TpHitRadius = Value
    end
})

HvHTab:Slider({
    Title = "TP Duration (sec)",
    Desc = "Time near target",
    Flag = "TPHitDuration",
    IsTooltip = true,
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 1.0,
        Default = 0.2
    },
    Callback = function(Value)
        TpHitDuration = Value
    end
})

-- ===== MUSIC TAB =====
local MusicTab = Window:Tab({
    Title = "Music",
    Icon = "music",
    Border = true
})

MusicTab:Input({
    Title = "Music ID (rbxassetid)",
    Desc = "Enter audio ID",
    Placeholder = "74326888232570",
    Flag = "MusicId",
    Callback = function(Value)
        if Value ~= "" then
            CurrentMusicId = Value
            if MusicSound and IsMusicPlaying then
                if MusicSound then MusicSound:Stop() MusicSound:Destroy() MusicSound = nil end
                MusicSound = Instance.new("Sound")
                MusicSound.SoundId = "rbxassetid://" .. CurrentMusicId
                MusicSound.Volume = MusicVolume / 100
                MusicSound.Looped = MusicLoop
                MusicSound.Parent = LocalPlayer.Character or workspace
                MusicSound:Play()
                IsMusicPlaying = true
            end
            Notify("ID Updated", "New ID: " .. CurrentMusicId)
        end
    end
})

MusicTab:Slider({
    Title = "Volume",
    Desc = "Music volume",
    Flag = "MusicVolume",
    IsTooltip = true,
    Step = 5,
    Value = {
        Min = 0,
        Max = 100,
        Default = 50
    },
    Callback = function(Value)
        MusicVolume = Value
        if MusicSound then MusicSound.Volume = MusicVolume / 100 end
    end
})

MusicTab:Button({
    Title = "▶ Play / Resume",
    Desc = "Start or resume music",
    Callback = function()
        if not MusicSound then
            MusicSound = Instance.new("Sound")
            MusicSound.SoundId = "rbxassetid://" .. CurrentMusicId
            MusicSound.Volume = MusicVolume / 100
            MusicSound.Looped = MusicLoop
            MusicSound.Parent = LocalPlayer.Character or workspace
            MusicSound:Play()
            IsMusicPlaying = true
            Notify("Music Playing", "ID: " .. CurrentMusicId)
        else
            if IsMusicPlaying then
                MusicSound:Pause()
                IsMusicPlaying = false
                Notify("Paused", "Music Paused")
            else
                MusicSound:Play()
                IsMusicPlaying = true
                Notify("Playing", "Music Resumed")
            end
        end
    end
})

MusicTab:Button({
    Title = "⏹ Stop",
    Desc = "Stop music",
    Callback = function()
        if MusicSound then MusicSound:Stop() MusicSound:Destroy() MusicSound = nil end
        IsMusicPlaying = false
        Notify("Music Stopped", "Playback Stopped")
    end
})

MusicTab:Toggle({
    Title = "Loop",
    Desc = "Loop playback",
    Flag = "MusicLoop",
    Value = false,
    Callback = function(Value)
        MusicLoop = Value
        if MusicSound then MusicSound.Looped = MusicLoop end
        Notify("Loop", MusicLoop and "On" or "Off")
    end
})

-- ===== SETTINGS TAB =====
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Border = true
})

SettingsTab:Section({
    Title = "Chat"
})

SettingsTab:Toggle({
    Title = "Enable Chat",
    Desc = "Force enable chat window",
    Flag = "ChatEnableToggle",
    Value = false,
    Callback = function(Value)
        ToggleChat(Value)
    end
})

SettingsTab:Space()
SettingsTab:Space()

SettingsTab:Section({
    Title = "Config Management"
})

local ConfigDropdown = SettingsTab:Dropdown({
    Title = "Select Config",
    Description = "Choose a config file to load",
    Options = ConfigManager:AllConfigs(),
    Default = "Default",
    Callback = function(selected)
        CurrentConfig = ConfigManager:CreateConfig(selected)
        CurrentConfig:Load()
        ApplyConfig(CurrentConfig.Data)
        Notify("Config Loaded", "Loaded: " .. selected)
    end
})

SettingsTab:Button({
    Title = "Save Current Config",
    Desc = "Save all current settings",
    Callback = function()
        CurrentConfig.Data = {
            TpwalkSpeed = TpwalkSpeed,
            FlySpeed = FlySpeed,
            JumpPower = JumpPowerValue,
            AimRadius = AimRadius,
            BackstabDuration = BackstabDuration,
            BackstabDistance = BackstabDistance,
            BackstabRadius = BackstabRadius,
            BackstabCooldown = BackstabCooldown,
            FovValue = FovTarget,
            TpHitRadius = TpHitRadius,
            TpHitDuration = TpHitDuration,
            MusicVolume = MusicVolume,
            MusicId = CurrentMusicId
        }
        CurrentConfig:Save()
        ConfigDropdown:Refresh(ConfigManager:AllConfigs())
        Notify("Config Saved", "Saved successfully!")
    end
})

SettingsTab:Space()
SettingsTab:Space()

SettingsTab:Section({
    Title = "Control"
})

SettingsTab:Button({
    Title = "Unload GUI",
    Desc = "Close interface",
    Callback = function()
        if BackstabConnection then
            BackstabConnection:Disconnect()
            BackstabConnection = nil
        end
        if BackstabLoopConnection then
            BackstabLoopConnection:Disconnect()
            BackstabLoopConnection = nil
        end
        if NoclipConnection then NoclipConnection:Disconnect() end
        if FlyConnection then FlyConnection:Disconnect() end
        if EspThread then EspThread:Disconnect() end
        if GeneratorEspThread then GeneratorEspThread:Disconnect() end
        if NameTagsThread then NameTagsThread:Disconnect() end
        if AimConn then AimConn:Disconnect() end
        if FovConnection then FovConnection:Disconnect() end
        if StaminaConnection then StaminaConnection:Disconnect() end
        if TpHitConnection then TpHitConnection:Disconnect() end
        if AutoGenConnection then AutoGenConnection:Disconnect() end
        if ChatConnection then ChatConnection:Disconnect() end
        ClearItemESP()
        RageTeleportRunning = false
        if RageTeleportLoop then RageTeleportLoop:Disconnect() end
        if MusicSound then MusicSound:Stop() MusicSound:Destroy() MusicSound = nil end
        ClearESP()
        ClearGeneratorESP()
        ClearNameTags()
        Window:Destroy()
        WindUI:Destroy()
    end
})

-- ===== RESTORE ON RESPAWN =====
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if TpwalkActive then
        if TpwalkConn then TpwalkConn:Disconnect() end
        TpwalkConn = RunService.RenderStepped:Connect(function()
            if not TpwalkActive then return end
            local Char = LocalPlayer.Character
            if not Char then return end
            local Hum = Char:FindFirstChild("Humanoid")
            local Hrp = Char:FindFirstChild("HumanoidRootPart")
            if not Hum or not Hrp then return end
            local Dir = Hum.MoveDirection
            if Dir.Magnitude > 0 then
                Hrp.CFrame = Hrp.CFrame + (Dir * (TpwalkSpeed / 100))
            end
        end)
    end
    if FlyEnabled then ToggleFly(true) end
    if NoclipEnabled then ToggleNoclip(true) end
    if EspEnabled then UpdateESP() end
    if GeneratorEspEnabled then UpdateGeneratorESP() end
    if NameTagsEnabled then UpdateNameTags() end
    if ItemEspEnabled then UpdateItemESP() end
end)

-- ===== STARTUP =====
print("[MAZAMI HUB] LOADED SUCCESSFULLY!")
print("TABS: Player 👤 | Visual 👁️ | Stamina ⚡ | Generators ⚡ | Aimbot 🎯 | Survivor 👥 | Rage ⚡ | HvH ⚔️ | Music 🎵 | Settings ⚙️")
print("Press Q for Backstab! | Item ESP highlights BloxyCola, Medkit, SubspaceTripmine")
