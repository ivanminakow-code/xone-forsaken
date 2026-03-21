

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

repeat wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ========== ПРОВЕРКА ИГРЫ ==========
local SUPPORTED_GAME_IDS = {[18687417158]=true, [88713106702323]=true}
local currentGameId = game.PlaceId
if not SUPPORTED_GAME_IDS[currentGameId] then
    warn("❌ Игра не поддерживается. ID: " .. currentGameId)
    return
end

-- ========== БЫСТРЫЕ ФУНКЦИИ ==========
local function fireRemote(ability)
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("Modules")
        if remote then remote = remote:FindFirstChild("Network") end
        if remote then remote = remote:FindFirstChild("RemoteEvent") end
        if remote then remote:FireServer("UseActorAbility", ability) end
    end)
end

-- ========== ИЗВЛЕЧЕННЫЕ ФУНКЦИИ ==========
local StaminaEnabled = false
local StaminaLoop = nil
local function toggleStamina(state)
    pcall(function()
        local SM = require(game.ReplicatedStorage.Systems.Character.Game.Sprinting)
        if state then
            SM.StaminaLossDisabled = true
            StaminaLoop = task.spawn(function()
                while StaminaEnabled do
                    task.wait(0.1)
                    SM.Stamina = SM.MaxStamina
                    SM.StaminaChanged:Fire()
                end
            end)
        else
            SM.StaminaLossDisabled = false
            if StaminaLoop then task.cancel(StaminaLoop); StaminaLoop = nil end
        end
    end)
end

local Speed05Enabled = false
local Speed05Conn = nil
local function speed05()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    Speed05Conn = RunService.Stepped:Connect(function()
        if Speed05Enabled and char and hum and hrp then
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (dir * 0.5) end
        end
    end)
end

local Speed1Enabled = false
local Speed1Conn = nil
local function speed1()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    Speed1Conn = RunService.Stepped:Connect(function()
        if Speed1Enabled and char and hum and hrp then
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (dir * 1) end
        end
    end)
end

local TPShedEnabled = false
local TPShedCooldown = false
local function shedSlash()
    if TPShedCooldown then return end
    local players = workspace:FindFirstChild("Players")
    if not players then return end
    local killers = players:FindFirstChild("Killers")
    if not killers then return end
    local killer = nil
    for _, k in ipairs(killers:GetChildren()) do
        if k:IsA("Model") and k:FindFirstChild("HumanoidRootPart") then
            killer = k
            break
        end
    end
    if not killer then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local kroot = killer:FindFirstChild("HumanoidRootPart")
    if not root or not kroot then return end
    TPShedCooldown = true
    local orig = root.CFrame
    local start = tick()
    while tick() - start < 2 do
        local elapsed = tick() - start
        local angle = elapsed * math.pi * 4
        local pred = kroot.Position + (kroot.Velocity * 0.3)
        local offset = Vector3.new(math.cos(angle)*3, 0, math.sin(angle)*3)
        root.CFrame = CFrame.new(pred + offset, pred)
        task.wait(0.03)
    end
    if root and root.Parent then root.CFrame = orig end
    task.delay(40, function() TPShedCooldown = false end)
end

-- ========== ОСНОВНЫЕ ПЕРЕМЕННЫЕ ==========
local MenuVisible = false
local FlyEnabled = false
local NoclipEnabled = false
local ESPEnabled = false
local AimbotEnabled = false
local AimbotActive = false
local TPHitEnabled = false
local CtrlClickTPEnabled = false
local GodModeEnabled = false
local InfiniteUpEnabled = false
local AutoBlockEnabled = false
local AutoPunchEnabled = false
local TPHitCooldown = false
local BodyFly = nil
local NoclipConn = nil
local GodModeLoop = nil
local InfiniteUpLoop = nil
local CurrentTab = "ИГРОК"
local AimbotTarget = nil
local ESPHighlights = {}
local lastBlock = 0
local lastPunch = 0

-- ========== ФУНКЦИИ ==========
local function tryBlock()
    if not AutoBlockEnabled then return end
    local now = tick()
    if now - lastBlock < 0.5 then return end
    fireRemote("Block")
    lastBlock = now
end
local function tryPunch()
    if not AutoPunchEnabled then return end
    local now = tick()
    if now - lastPunch < 0.5 then return end
    fireRemote("Punch")
    lastPunch = now
end

local function getRandomPlayer()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then table.insert(list, p) end
        end
    end
    if #list > 0 then return list[math.random(1, #list)] end
    return nil
end

local function tpHit()
    if TPHitCooldown or not TPHitEnabled then return end
    local target = getRandomPlayer()
    if not target then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local troot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root or not troot then return end
    TPHitCooldown = true
    local orig = root.CFrame
    root.CFrame = troot.CFrame + Vector3.new(2,1,2)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part ~= root then part.CFrame = root.CFrame end
    end
    task.wait(0.2)
    if root and root.Parent then
        root.CFrame = orig
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and part ~= root then part.CFrame = root.CFrame end
        end
    end
    task.delay(3, function() TPHitCooldown = false end)
end

local function UpdateFly()
    if not FlyEnabled then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        if BodyFly then BodyFly:Destroy(); BodyFly = nil end
        return
    end
    local root = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = true end
    local vec = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vec = vec + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vec = vec - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vec = vec - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vec = vec + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vec = vec + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vec = vec + Vector3.new(0,-1,0) end
    if vec.Magnitude > 0 then vec = vec.Unit * 75 end
    if BodyFly then BodyFly.Velocity = vec end
end

-- ========== ESP (ОБЪЕДИНЕННЫЙ) ==========
local function createHighlight(model, oc, fc)
    for _, ex in pairs(model:GetChildren()) do if ex:IsA("Highlight") then ex:Destroy() end end
    local h = Instance.new("Highlight")
    h.Parent = model
    h.Adornee = model
    h.FillTransparency = 0.65
    h.FillColor = fc
    h.OutlineColor = oc
    h.OutlineTransparency = 0
    table.insert(ESPHighlights, h)
    return h
end

local function updateESP()
    if not ESPEnabled then
        for _, h in pairs(ESPHighlights) do pcall(function() h:Destroy() end) end
        ESPHighlights = {}
        return
    end
    for _, h in pairs(ESPHighlights) do pcall(function() h:Destroy() end) end
    ESPHighlights = {}
    
    local pg = workspace:FindFirstChild("Players")
    if pg then
        local kg = pg:FindFirstChild("Killers")
        if kg then
            for _, obj in pairs(kg:GetChildren()) do
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and obj:FindFirstChild("HumanoidRootPart") and hum.Health > 0 then
                    createHighlight(obj, Color3.new(1,0,0), Color3.new(1,0.5,0.5))
                end
            end
        end
        local sg = pg:FindFirstChild("Survivors")
        if sg then
            for _, obj in pairs(sg:GetChildren()) do
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and obj:FindFirstChild("HumanoidRootPart") and hum.Health > 0 then
                    createHighlight(obj, Color3.new(0,1,0), Color3.new(0.5,1,0.5))
                end
            end
        end
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local isGroup = false
                local pg = workspace:FindFirstChild("Players")
                if pg then
                    local kg = pg:FindFirstChild("Killers")
                    if kg then for _, obj in pairs(kg:GetChildren()) do if obj == char then isGroup = true break end end end
                    if not isGroup then
                        local sg = pg:FindFirstChild("Survivors")
                        if sg then for _, obj in pairs(sg:GetChildren()) do if obj == char then isGroup = true break end end end
                    end
                end
                if not isGroup then
                    createHighlight(char, Color3.new(1,1,1), Color3.new(0.8,0.8,0.8))
                end
            end
        end
    end
    
    local map = workspace:FindFirstChild("Map")
    if map then
        local ingame = map:FindFirstChild("Ingame")
        if ingame then
            local m = ingame:FindFirstChild("Map")
            if m then
                for _, obj in pairs(m:GetChildren()) do
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        createHighlight(obj, Color3.new(1,1,0), Color3.new(1,1,0.5))
                    end
                end
            end
        end
    end
end

-- ========== AIMBOT ==========
function GetNearestPlayer()
    local nearest = nil
    local best = math.huge
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if tr and hum and hum.Health > 0 then
                local dist = (root.Position - tr.Position).Magnitude
                if dist < best then
                    local onScr = Camera:WorldToViewportPoint(tr.Position)
                    if onScr and dist < 150 then
                        local ray = Ray.new(Camera.CFrame.Position, (tr.Position - Camera.CFrame.Position).Unit * dist)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {char, Camera})
                        if hit == nil or hit:IsDescendantOf(p.Character) then
                            best = dist
                            nearest = p
                        end
                    end
                end
            end
        end
    end
    return nearest
end

-- ========== GUI ==========
local scrW, scrH = Camera.ViewportSize.X, Camera.ViewportSize.Y
local MenuW = math.min(500, scrW * 0.9)
local MenuH = math.min(600, scrH * 0.9)
local BtnSize = math.min(60, scrW * 0.1)
local AimSize = math.min(70, scrW * 0.1)

local colors = {bg=Color3.fromRGB(18,18,22), bg2=Color3.fromRGB(25,25,32), accent=Color3.fromRGB(0,162,255), text=Color3.fromRGB(220,220,220), text2=Color3.fromRGB(150,150,150), border=Color3.fromRGB(45,45,55)}

local SG = Instance.new("ScreenGui")
SG.Name = "XONEMobile"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then pcall(function() SG.Parent = LocalPlayer:FindFirstChild("PlayerGui") end) end
if not SG.Parent then SG.Parent = Instance.new("Folder", LocalPlayer) end

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, BtnSize, 0, BtnSize)
OpenBtn.Position = UDim2.new(0, 20, 0.5, -BtnSize/2)
OpenBtn.BackgroundColor3 = colors.accent
OpenBtn.BackgroundTransparency = 0.2
OpenBtn.Text = "X"
OpenBtn.TextColor3 = Color3.new(1,1,1)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = BtnSize * 0.5
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Parent = SG
local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, BtnSize/2)
OpenCorner.Parent = OpenBtn

local AimBtn = Instance.new("TextButton")
AimBtn.Size = UDim2.new(0, AimSize, 0, AimSize)
AimBtn.Position = UDim2.new(1, -AimSize - 20, 1, -AimSize - 20)
AimBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
AimBtn.Text = "АИМ"
AimBtn.TextColor3 = Color3.new(1,1,1)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = AimSize * 0.25
AimBtn.Visible = false
AimBtn.Active = true
AimBtn.Draggable = true
AimBtn.Parent = SG
local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius = UDim.new(0, AimSize/2)
AimCorner.Parent = AimBtn
local AimInd = Instance.new("Frame")
AimInd.Size = UDim2.new(0, AimSize*0.25, 0, AimSize*0.25)
AimInd.Position = UDim2.new(0.5, -AimSize*0.125, 0.5, -AimSize*0.125)
AimInd.BackgroundColor3 = Color3.fromRGB(255,255,255)
AimInd.BackgroundTransparency = 0.5
AimInd.Visible = false
AimInd.Parent = AimBtn
local IndCorner = Instance.new("UICorner")
IndCorner.CornerRadius = UDim.new(0, AimSize*0.125)
IndCorner.Parent = AimInd

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, MenuW, 0, MenuH)
Main.Position = UDim2.new(0.5, -MenuW/2, 0.5, -MenuH/2)
Main.BackgroundColor3 = colors.bg
Main.BorderSizePixel = 1
Main.BorderColor3 = colors.border
Main.Active = true
Main.Draggable = true
Main.Visible = false
Main.Parent = SG
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local Title = Instance.new("Frame")
Title.Size = UDim2.new(1,0,0, MenuH*0.06)
Title.BackgroundColor3 = colors.bg2
Title.BorderSizePixel = 0
Title.Parent = Main
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title
local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, MenuW*0.14, 1,0)
Logo.Position = UDim2.new(0,8,0,0)
Logo.BackgroundTransparency = 1
Logo.Text = "XONE"
Logo.TextColor3 = colors.accent
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = MenuH*0.03
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = Title
local GameTitle = Instance.new("TextLabel")
GameTitle.Size = UDim2.new(0, MenuW*0.25, 1,0)
GameTitle.Position = UDim2.new(0, MenuW*0.15,0,0)
GameTitle.BackgroundTransparency = 1
GameTitle.Text = "| FORSAKEN"
GameTitle.TextColor3 = colors.text2
GameTitle.Font = Enum.Font.GothamSemibold
GameTitle.TextSize = MenuH*0.025
GameTitle.TextXAlignment = Enum.TextXAlignment.Left
GameTitle.Parent = Title
local Ver = Instance.new("TextLabel")
Ver.Size = UDim2.new(0, MenuW*0.15, 1,0)
Ver.Position = UDim2.new(0, MenuW*0.4,0,0)
Ver.BackgroundTransparency = 1
Ver.Text = "v47.0"
Ver.TextColor3 = colors.text2
Ver.Font = Enum.Font.Gotham
Ver.TextSize = MenuH*0.02
Ver.TextXAlignment = Enum.TextXAlignment.Left
Ver.Parent = Title
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, MenuH*0.04, 0, MenuH*0.04)
Close.Position = UDim2.new(1, -MenuH*0.05, 0.5, -MenuH*0.02)
Close.BackgroundColor3 = Color3.fromRGB(40,40,48)
Close.Text = "✕"
Close.TextColor3 = colors.text
Close.Font = Enum.Font.GothamBold
Close.TextSize = MenuH*0.018
Close.Parent = Title
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, MenuH*0.006)
CloseCorner.Parent = Close

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1,0,0, MenuH*0.06)
Tabs.Position = UDim2.new(0,0,0, MenuH*0.06)
Tabs.BackgroundColor3 = colors.bg2
Tabs.BorderSizePixel = 0
Tabs.Parent = Main
local TabW = (MenuW - 40) / 4
local PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.new(0, TabW, 1,0)
PlayerTab.Position = UDim2.new(0,8,0,0)
PlayerTab.BackgroundTransparency = 1
PlayerTab.Text = "ИГРОК"
PlayerTab.TextColor3 = colors.accent
PlayerTab.Font = Enum.Font.GothamBold
PlayerTab.TextSize = MenuH*0.018
PlayerTab.Parent = Tabs
local VisualTab = Instance.new("TextButton")
VisualTab.Size = UDim2.new(0, TabW, 1,0)
VisualTab.Position = UDim2.new(0,12+TabW,0,0)
VisualTab.BackgroundTransparency = 1
VisualTab.Text = "ВИЗУАЛ"
VisualTab.TextColor3 = colors.text2
VisualTab.Font = Enum.Font.GothamBold
VisualTab.TextSize = MenuH*0.018
VisualTab.Parent = Tabs
local TeleportTab = Instance.new("TextButton")
TeleportTab.Size = UDim2.new(0, TabW, 1,0)
TeleportTab.Position = UDim2.new(0,16+TabW*2,0,0)
TeleportTab.BackgroundTransparency = 1
TeleportTab.Text = "ТЕЛЕПОРТ"
TeleportTab.TextColor3 = colors.text2
TeleportTab.Font = Enum.Font.GothamBold
TeleportTab.TextSize = MenuH*0.018
TeleportTab.Parent = Tabs
local CombatTab = Instance.new("TextButton")
CombatTab.Size = UDim2.new(0, TabW, 1,0)
CombatTab.Position = UDim2.new(0,20+TabW*3,0,0)
CombatTab.BackgroundTransparency = 1
CombatTab.Text = "БОЙ"
CombatTab.TextColor3 = colors.text2
CombatTab.Font = Enum.Font.GothamBold
CombatTab.TextSize = MenuH*0.018
CombatTab.Parent = Tabs
local TabInd = Instance.new("Frame")
TabInd.Size = UDim2.new(0, TabW, 0, 2)
TabInd.Position = UDim2.new(0,8,1,-2)
TabInd.BackgroundColor3 = colors.accent
TabInd.BorderSizePixel = 0
TabInd.Parent = Tabs

local ContY = MenuH*0.13
local ContH = MenuH*0.8
local PlayerCont = Instance.new("Frame")
PlayerCont.Size = UDim2.new(1,-20,0,ContH)
PlayerCont.Position = UDim2.new(0,10,0,ContY)
PlayerCont.BackgroundTransparency = 1
PlayerCont.Visible = true
PlayerCont.Parent = Main
local VisualCont = Instance.new("Frame")
VisualCont.Size = UDim2.new(1,-20,0,ContH)
VisualCont.Position = UDim2.new(0,10,0,ContY)
VisualCont.BackgroundTransparency = 1
VisualCont.Visible = false
VisualCont.Parent = Main
local TeleportCont = Instance.new("Frame")
TeleportCont.Size = UDim2.new(1,-20,0,ContH)
TeleportCont.Position = UDim2.new(0,10,0,ContY)
TeleportCont.BackgroundTransparency = 1
TeleportCont.Visible = false
TeleportCont.Parent = Main
local CombatCont = Instance.new("Frame")
CombatCont.Size = UDim2.new(1,-20,0,ContH)
CombatCont.Position = UDim2.new(0,10,0,ContY)
CombatCont.BackgroundTransparency = 1
CombatCont.Visible = false
CombatCont.Parent = Main

local function Check(parent, name, y, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0, ContH*0.05)
    f.Position = UDim2.new(0,0,0,y)
    f.BackgroundTransparency = 1
    f.Parent = parent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0,180,1,0)
    l.Position = UDim2.new(0,25,0,0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = colors.text
    l.Font = Enum.Font.Gotham
    l.TextSize = ContH*0.025
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, ContH*0.03, 0, ContH*0.03)
    box.Position = UDim2.new(0,0,0.5, -ContH*0.015)
    box.BackgroundColor3 = colors.bg2
    box.BorderSizePixel = 1
    box.BorderColor3 = colors.border
    box.Parent = f
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0,3)
    boxCorner.Parent = box
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, ContH*0.02, 0, ContH*0.02)
    fill.Position = UDim2.new(0.5, -ContH*0.01, 0.5, -ContH*0.01)
    fill.BackgroundColor3 = colors.accent
    fill.Visible = def
    fill.Parent = box
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0,2)
    fillCorner.Parent = fill
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f
    local state = def
    btn.MouseButton1Click:Connect(function()
        state = not state
        fill.Visible = state
        cb(state)
    end)
    return f
end

-- ========== PLAYER TAB ==========
local py = 5
Check(PlayerCont, "Полет", py, false, function(v) 
    FlyEnabled = v
    if v then
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            if BodyFly then BodyFly:Destroy() end
            BodyFly = Instance.new("BodyVelocity")
            BodyFly.Velocity = Vector3.new(0,0,0)
            BodyFly.MaxForce = Vector3.new(5000,5000,5000)
            BodyFly.P = 1250
            BodyFly.Parent = c.HumanoidRootPart
            local h = c:FindFirstChild("Humanoid")
            if h then h.PlatformStand = true end
        end
    else
        if BodyFly then BodyFly:Destroy(); BodyFly = nil end
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChild("Humanoid")
            if h then h.PlatformStand = false end
        end
    end
end)
py = py + ContH*0.05
Check(PlayerCont, "Сквозь стены", py, false, function(v)
    NoclipEnabled = v
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    if v then
        NoclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if c then
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        local c = LocalPlayer.Character
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)
py = py + ContH*0.05
Check(PlayerCont, "⚡ Бесконечная выносливость", py, false, function(v) StaminaEnabled = v; toggleStamina(v) end)
py = py + ContH*0.05
Check(PlayerCont, "⚡ Скорость 0.5", py, false, function(v)
    if Speed05Enabled then if Speed05Conn then Speed05Conn:Disconnect() end end
    Speed05Enabled = v
    if v then speed05() end
end)
py = py + ContH*0.05
Check(PlayerCont, "⚡ Скорость 1", py, false, function(v)
    if Speed1Enabled then if Speed1Conn then Speed1Conn:Disconnect() end end
    Speed1Enabled = v
    if v then speed1() end
end)
py = py + ContH*0.05
Check(PlayerCont, "👑 РЕЖИМ БОГА", py, false, function(v)
    GodModeEnabled = v
    if GodModeLoop then GodModeLoop:Disconnect(); GodModeLoop = nil end
    if v then
        GodModeLoop = RunService.Heartbeat:Connect(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChild("Humanoid")
                if h and h.Health > 0 then
                    h.MaxHealth = math.huge
                    h.Health = math.huge
                end
            end
        end)
    end
end)
py = py + ContH*0.05
Check(PlayerCont, "∞ Телепорт вверх (10000)", py, false, function(v)
    InfiniteUpEnabled = v
    if InfiniteUpLoop then InfiniteUpLoop:Disconnect(); InfiniteUpLoop = nil end
    if v then
        InfiniteUpLoop = RunService.Heartbeat:Connect(function()
            local c = LocalPlayer.Character
            if c then
                local r = c:FindFirstChild("HumanoidRootPart")
                if r then r.CFrame = CFrame.new(r.Position.X, r.Position.Y + 10000, r.Position.Z) end
            end
            task.wait(0.1)
        end)
    end
end)
py = py + ContH*0.05
Check(PlayerCont, "Ctrl+Click TP", py, false, function(v) CtrlClickTPEnabled = v end)

-- ========== VISUAL TAB ==========
py = 5
Check(VisualCont, "ESP (Подсветка)", py, false, function(v) ESPEnabled = v end)

-- ========== TELEPORT TAB ==========
local TeleList = Instance.new("ScrollingFrame")
TeleList.Size = UDim2.new(1,0,1,-ContH*0.05)
TeleList.Position = UDim2.new(0,0,0,ContH*0.05)
TeleList.BackgroundColor3 = colors.bg2
TeleList.BorderSizePixel = 1
TeleList.BorderColor3 = colors.border
TeleList.ScrollBarThickness = 4
TeleList.ScrollBarImageColor3 = colors.accent
TeleList.CanvasSize = UDim2.new(0,0,0,0)
TeleList.Parent = TeleportCont
local TeleCorner = Instance.new("UICorner")
TeleCorner.CornerRadius = UDim.new(0,6)
TeleCorner.Parent = TeleList

local function UpdateList()
    for _, c in pairs(TeleList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local yp = 5
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1,0,0, ContH*0.07)
            f.Position = UDim2.new(0,0,0,yp)
            f.BackgroundColor3 = colors.bg2
            f.BorderSizePixel = 1
            f.BorderColor3 = colors.border
            f.Parent = TeleList
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(0,6)
            fCorner.Parent = f
            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1,-80,1,0)
            name.Position = UDim2.new(0,10,0,0)
            name.BackgroundTransparency = 1
            name.Text = p.Name
            name.TextColor3 = colors.text
            name.Font = Enum.Font.Gotham
            name.TextSize = ContH*0.025
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = f
            local tp = Instance.new("TextButton")
            tp.Size = UDim2.new(0,55,0, ContH*0.04)
            tp.Position = UDim2.new(1,-65,0.5, -ContH*0.02)
            tp.BackgroundColor3 = colors.accent
            tp.Text = "ТП"
            tp.TextColor3 = colors.text
            tp.Font = Enum.Font.GothamBold
            tp.TextSize = ContH*0.022
            tp.Parent = f
            local tpCorner = Instance.new("UICorner")
            tpCorner.CornerRadius = UDim.new(0,5)
            tpCorner.Parent = tp
            tp.MouseButton1Click:Connect(function()
                local tc = p.Character
                local lc = LocalPlayer.Character
                if tc and lc and lc:FindFirstChild("HumanoidRootPart") then
                    local tr = tc:FindFirstChild("HumanoidRootPart")
                    local lr = lc:FindFirstChild("HumanoidRootPart")
                    if tr then
                        lr.CFrame = tr.CFrame + Vector3.new(0,3,2)
                        for _, pt in pairs(lc:GetChildren()) do
                            if pt:IsA("BasePart") and pt ~= lr then pt.CFrame = lr.CFrame end
                        end
                    end
                end
            end)
            yp = yp + ContH*0.08
        end
    end
    TeleList.CanvasSize = UDim2.new(0,0,0, yp+10)
end

-- ========== COMBAT TAB ==========
py = 5
Check(CombatCont, "Аимбот", py, false, function(v)
    AimbotEnabled = v
    AimBtn.Visible = v
    if not v then
        AimbotActive = false
        AimbotTarget = nil
        AimBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        AimInd.Visible = false
    end
end)
py = py + ContH*0.05
Check(CombatCont, "Auto Block", py, false, function(v) AutoBlockEnabled = v end)
py = py + ContH*0.05
Check(CombatCont, "Auto Punch", py, false, function(v) AutoPunchEnabled = v end)
py = py + ContH*0.05
Check(CombatCont, "⚔️ TP Slash Shedletsky (Q)", py, false, function(v) TPShedEnabled = v end)
py = py + ContH*0.05
Check(CombatCont, "TP Hit (ЛКМ) - рывок", py, false, function(v) TPHitEnabled = v end)

-- ========== ОБРАБОТЧИКИ ==========
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Q then
        if TPShedEnabled and not TPShedCooldown then shedSlash() end
    end
    if inp.KeyCode == Enum.KeyCode.Insert then
        MenuVisible = not MenuVisible
        Main.Visible = MenuVisible
    end
end)

AimBtn.MouseButton1Click:Connect(function()
    if not AimbotEnabled then return end
    AimbotActive = not AimbotActive
    if AimbotActive then
        AimBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
        AimInd.Visible = true
        AimbotTarget = GetNearestPlayer()
    else
        AimBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        AimInd.Visible = false
        AimbotTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if AimbotEnabled and AimbotActive and AimbotTarget then
        local t = AimbotTarget.Character
        if t and t:FindFirstChild("Head") and t:FindFirstChild("Humanoid") and t.Humanoid.Health > 0 then
            local pos = t.Head.Position
            local lc = LocalPlayer.Character
            local h = lc and lc:FindFirstChild("Humanoid")
            if h and h.Health > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, pos), 0.5)
            end
        else
            AimbotTarget = GetNearestPlayer()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local kf = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not kf then return end
    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    for _, k in pairs(kf:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - r.Position).Magnitude < 12 then
            tryBlock()
            tryPunch()
            break
        end
    end
end)

Mouse.Button1Down:Connect(function()
    if CtrlClickTPEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Mouse.Target then
        local c = LocalPlayer.Character
        if c then
            c:MoveTo(Mouse.Hit.p)
            local r = c:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = CFrame.new(Mouse.Hit.p + Vector3.new(0,3,0)) end
        end
    end
end)
Mouse.Button1Down:Connect(function()
    if TPHitEnabled and not CtrlClickTPEnabled then tpHit() end
end)

RunService.RenderStepped:Connect(function() pcall(UpdateFly) end)
spawn(function() while true do pcall(updateESP); wait(0.5) end end)
spawn(function() while true do if CurrentTab == "ТЕЛЕПОРТ" then pcall(UpdateList) end; wait(2) end end)

PlayerTab.MouseButton1Click:Connect(function()
    CurrentTab = "ИГРОК"
    PlayerTab.TextColor3 = colors.accent
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    PlayerCont.Visible = true
    VisualCont.Visible = false
    TeleportCont.Visible = false
    CombatCont.Visible = false
    TweenService:Create(TabInd, TweenInfo.new(0.2), {Position = UDim2.new(0,8,1,-2)}):Play()
end)
VisualTab.MouseButton1Click:Connect(function()
    CurrentTab = "ВИЗУАЛ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.accent
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.text2
    PlayerCont.Visible = false
    VisualCont.Visible = true
    TeleportCont.Visible = false
    CombatCont.Visible = false
    TweenService:Create(TabInd, TweenInfo.new(0.2), {Position = UDim2.new(0,12+TabW,1,-2)}):Play()
end)
TeleportTab.MouseButton1Click:Connect(function()
    CurrentTab = "ТЕЛЕПОРТ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.accent
    CombatTab.TextColor3 = colors.text2
    PlayerCont.Visible = false
    VisualCont.Visible = false
    TeleportCont.Visible = true
    CombatCont.Visible = false
    TweenService:Create(TabInd, TweenInfo.new(0.2), {Position = UDim2.new(0,16+TabW*2,1,-2)}):Play()
    UpdateList()
end)
CombatTab.MouseButton1Click:Connect(function()
    CurrentTab = "БОЙ"
    PlayerTab.TextColor3 = colors.text2
    VisualTab.TextColor3 = colors.text2
    TeleportTab.TextColor3 = colors.text2
    CombatTab.TextColor3 = colors.accent
    PlayerCont.Visible = false
    VisualCont.Visible = false
    TeleportCont.Visible = false
    CombatCont.Visible = true
    TweenService:Create(TabInd, TweenInfo.new(0.2), {Position = UDim2.new(0,20+TabW*3,1,-2)}):Play()
end)

OpenBtn.MouseButton1Click:Connect(function()
    MenuVisible = not MenuVisible
    Main.Visible = MenuVisible
end)
Close.MouseButton1Click:Connect(function()
    MenuVisible = false
    Main.Visible = false
end)

LocalPlayer.CharacterAdded:Connect(function()
    if BodyFly then BodyFly:Destroy(); BodyFly = nil end
    FlyEnabled = false
    if GodModeLoop then GodModeLoop:Disconnect(); GodModeLoop = nil end
    GodModeEnabled = false
    if InfiniteUpLoop then InfiniteUpLoop:Disconnect(); InfiniteUpLoop = nil end
    InfiniteUpEnabled = false
    if Speed05Conn then Speed05Conn:Disconnect(); Speed05Conn = nil end
    Speed05Enabled = false
    if Speed1Conn then Speed1Conn:Disconnect(); Speed1Conn = nil end
    Speed1Enabled = false
    AimbotTarget = nil
    AimbotActive = false
    if AimbotEnabled then
        AimBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        AimInd.Visible = false
    end
    TPShedCooldown = false
    TPHitCooldown = false
end)


