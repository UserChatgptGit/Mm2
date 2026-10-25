--[[
    MM2 COMBINED HUB — Footagesus WindUI
    One WindUI window containing the base ESP / Gun ESP / Anti-Fling / Cosmic Farm
    plus the integrated PulseHub, movement, combat, role tools, animation and system tabs.
    Legacy module windows are hidden/disabled; ESP overlays are separate visualization layers.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer


local ESPEnabled = true
local AntiFlingEnabled = true
local GunESPEnabled = true
local AutoKillEnabled = false

local GuiOpen = false
local Dragging = false
local DragStart = nil
local DragOffset = nil
local Font = Drawing.Fonts.Plex

-- ===== ПЕРЕМЕННЫЕ =====
local espObjects = {}
local gunESPObject = nil
local antiFlingConnection = nil
local flingGUIOpen = false
local flingGUI = nil
local sheriffDead = false
local killLoop = nil
local gunCheckTimer = 0


local function CleanupGUI()
    local oldGui = LocalPlayer.PlayerGui:FindFirstChild("ESP_GUI")
    if oldGui then
        oldGui:Destroy()
    end
end
CleanupGUI()


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Enabled = false -- UI теперь управляется через WindUI

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 260)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(60, 60, 100)
Stroke.Thickness = 1
Stroke.Transparency = 0.5
Stroke.Parent = MainFrame


local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -30, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ MM2 HUB"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 1, -6)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
CloseBtn.BackgroundTransparency = 0.5
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn


local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -42)
Content.Position = UDim2.new(0, 8, 0, 38)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame


local EspButton = Instance.new("TextButton")
EspButton.Size = UDim2.new(1, 0, 0, 24)
EspButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
EspButton.BackgroundTransparency = 0.3
EspButton.Text = "🔍 ESP: ON"
EspButton.TextColor3 = Color3.new(1, 1, 1)
EspButton.TextSize = 11
EspButton.Font = Enum.Font.GothamBold
EspButton.Parent = Content
local EspCorner = Instance.new("UICorner")
EspCorner.CornerRadius = UDim.new(0, 5)
EspCorner.Parent = EspButton

-- Кнопка Anti-Fling
local AntiFlingButton = Instance.new("TextButton")
AntiFlingButton.Size = UDim2.new(1, 0, 0, 24)
AntiFlingButton.Position = UDim2.new(0, 0, 0, 28)
AntiFlingButton.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
AntiFlingButton.BackgroundTransparency = 0.3
AntiFlingButton.Text = "🛡️ AF: ON"
AntiFlingButton.TextColor3 = Color3.new(1, 1, 1)
AntiFlingButton.TextSize = 11
AntiFlingButton.Font = Enum.Font.GothamBold
AntiFlingButton.Parent = Content
local AntiFlingCorner = Instance.new("UICorner")
AntiFlingCorner.CornerRadius = UDim.new(0, 5)
AntiFlingCorner.Parent = AntiFlingButton

-- Кнопка Gun ESP
local GunESPButton = Instance.new("TextButton")
GunESPButton.Size = UDim2.new(1, 0, 0, 24)
GunESPButton.Position = UDim2.new(0, 0, 0, 56)
GunESPButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
GunESPButton.BackgroundTransparency = 0.3
GunESPButton.Text = "🔫 Gun ESP: ON"
GunESPButton.TextColor3 = Color3.new(1, 1, 1)
GunESPButton.TextSize = 11
GunESPButton.Font = Enum.Font.GothamBold
GunESPButton.Parent = Content
local GunESPCorner = Instance.new("UICorner")
GunESPCorner.CornerRadius = UDim.new(0, 5)
GunESPCorner.Parent = GunESPButton

-- Кнопка TP to Gun
local TPButton = Instance.new("TextButton")
TPButton.Size = UDim2.new(1, 0, 0, 24)
TPButton.Position = UDim2.new(0, 0, 0, 84)
TPButton.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
TPButton.BackgroundTransparency = 0.3
TPButton.Text = "🔫 TP to Gun"
TPButton.TextColor3 = Color3.new(1, 1, 1)
TPButton.TextSize = 11
TPButton.Font = Enum.Font.GothamBold
TPButton.Parent = Content
local TPCorner = Instance.new("UICorner")
TPCorner.CornerRadius = UDim.new(0, 5)
TPCorner.Parent = TPButton

-- Кнопка Auto Kill
local KillButton = Instance.new("TextButton")
KillButton.Size = UDim2.new(1, 0, 0, 24)
KillButton.Position = UDim2.new(0, 0, 0, 112)
KillButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
KillButton.BackgroundTransparency = 0.3
KillButton.Text = "🔪 Auto Kill: OFF"
KillButton.TextColor3 = Color3.new(1, 1, 1)
KillButton.TextSize = 11
KillButton.Font = Enum.Font.GothamBold
KillButton.Parent = Content
local KillCorner = Instance.new("UICorner")
KillCorner.CornerRadius = UDim.new(0, 5)
KillCorner.Parent = KillButton

-- Кнопка Fling GUI
local FlingButton = Instance.new("TextButton")
FlingButton.Size = UDim2.new(1, 0, 0, 24)
FlingButton.Position = UDim2.new(0, 0, 0, 140)
FlingButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
FlingButton.BackgroundTransparency = 0.3
FlingButton.Text = "💥 Fling GUI"
FlingButton.TextColor3 = Color3.new(1, 1, 1)
FlingButton.TextSize = 11
FlingButton.Font = Enum.Font.GothamBold
FlingButton.Parent = Content
local FlingCorner = Instance.new("UICorner")
FlingCorner.CornerRadius = UDim.new(0, 5)
FlingCorner.Parent = FlingButton

-- Статус
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 16)
StatusLabel.Position = UDim2.new(0, 0, 0, 170)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Готов"
StatusLabel.TextColor3 = Color3.new(0.4, 0.4, 0.5)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = Content

-- ===== ПЕРЕТАСКИВАНИЕ =====
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        DragOffset = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(DragOffset.X.Scale, DragOffset.X.Offset + delta.X, DragOffset.Y.Scale, DragOffset.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

-- ===== АНТИ-ФЛИНГ =====
local function StartAntiFling()
    if antiFlingConnection then
        antiFlingConnection:Disconnect()
        antiFlingConnection = nil
    end
    
    antiFlingConnection = RunService.Heartbeat:Connect(function()
        if not AntiFlingEnabled then return end
        if not LocalPlayer.Character then return end
        
        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not player.Character then continue end
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            
            local dist = (root.Position - localRoot.Position).Magnitude
            if dist > 100 then continue end
            
            local vel = root.Velocity
            if vel.Magnitude > 50 then
                pcall(function()
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                    root.CanCollide = false
                end)
            end
        end
    end)
end


local function CheckSheriffStatus()
    sheriffDead = false
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local char = player.Character
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then continue end
        
        local hasGun = false
        local inv = player:FindFirstChild("Backpack") or player:FindFirstChild("Inventory")
        
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local nameLower = tool.Name:lower()
                if nameLower:find("gun") or nameLower:find("pistol") or nameLower:find("revolver") or nameLower:find("shotgun") then
                    hasGun = true
                    break
                end
            end
        end
        
        if not hasGun and inv then
            for _, tool in pairs(inv:GetChildren()) do
                if tool:IsA("Tool") then
                    local nameLower = tool.Name:lower()
                    if nameLower:find("gun") or nameLower:find("pistol") or nameLower:find("revolver") or nameLower:find("shotgun") then
                        hasGun = true
                        break
                    end
                end
            end
        end
        
        if hasGun and humanoid.Health <= 0 then
            sheriffDead = true
            return
        end
    end
end

-- ===== ПОИСК ПИСТОЛЕТА (GunDrop) =====
local function FindGun()
    for _, v in pairs(workspace:GetDescendants()) do
        -- Ищем объект с именем "GunDrop" (точное совпадение или содержит)
        if v.Name and string.lower(v.Name):find("gundrop") then
            -- Проверяем что это не игрок
            if v:FindFirstChild("Humanoid") or v:FindFirstChild("HumanoidRootPart") then
                continue
            end
            
            -- Если это Tool
            if v:IsA("Tool") then
                return v
            end
            
            -- Если это Model
            if v:IsA("Model") then
                return v
            end
            
            -- Если это BasePart, берем родителя
            if v:IsA("BasePart") then
                local parent = v.Parent
                if parent and parent:IsA("Model") then
                    return parent
                end
            end
        end
    end
    return nil
end

-- ===== ТП К ПИСТОЛЕТУ =====
local function TeleportToGun()
    if not sheriffDead then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "⚠️ Шериф жив!",
            Text = "Дождись смерти шерифа",
            Duration = 3
        })
        return
    end
    
    local gun = FindGun()
    if not gun then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "❌ Пистолет не найден",
            Text = "Пистолет еще не выпал",
            Duration = 3
        })
        return
    end
    
    local rootPart = gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")
    if not rootPart then
        for _, part in pairs(gun:GetChildren()) do
            if part:IsA("BasePart") then
                rootPart = part
                break
            end
        end
    end
    if not rootPart then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoidRoot = char:FindFirstChild("HumanoidRootPart")
    if not humanoidRoot then return end
    
    local targetPos = rootPart.Position + Vector3.new(0, 3, 0)
    humanoidRoot.CFrame = CFrame.new(targetPos)
    humanoidRoot.Velocity = Vector3.new(0, 0, 0)
end

-- ===== AUTO KILL =====
local function ClickLMB()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game:GetService("UserInputService").MouseIcon, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game:GetService("UserInputService").MouseIcon, 0)
end

local function TeleportAllToMe()
    local char = LocalPlayer.Character
    if not char then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local myPos = rootPart.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if pRoot then
            local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
            pRoot.CFrame = CFrame.new(myPos + offset + Vector3.new(0, 2, 0))
            pRoot.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

local function KillAll()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
        end
    end
end

local function StartAutoKill()
    if killLoop then
        killLoop:Disconnect()
        killLoop = nil
    end
    
    killLoop = RunService.Heartbeat:Connect(function()
        if not AutoKillEnabled then return end
        if not LocalPlayer.Character then return end
        
        TeleportAllToMe()
        task.wait(0.1)
        ClickLMB()
        ClickLMB()
        ClickLMB()
        KillAll()
    end)
end

local function ToggleAutoKill()
    AutoKillEnabled = not AutoKillEnabled
    
    if AutoKillEnabled then
        KillButton.Text = "🔪 Auto Kill: ON"
        KillButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        StatusLabel.Text = "✅ Auto Kill включен!"
        StartAutoKill()
    else
        KillButton.Text = "🔪 Auto Kill: OFF"
        KillButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        StatusLabel.Text = "❌ Auto Kill выключен"
        if killLoop then
            killLoop:Disconnect()
            killLoop = nil
        end
    end
end

-- ===== GUN ESP =====
local function UpdateGunESP()
    CheckSheriffStatus()
    
    local shouldShow = GunESPEnabled and sheriffDead
    
    if not shouldShow then
        if gunESPObject then
            if gunESPObject.box then gunESPObject.box:Remove() end
            if gunESPObject.label then gunESPObject.label:Remove() end
            gunESPObject = nil
        end
        return
    end
    
    gunCheckTimer = gunCheckTimer + 1
    if gunCheckTimer < 2 then return end
    gunCheckTimer = 0
    
    local gun = FindGun()
    
    if not gun then
        if gunESPObject then
            if gunESPObject.box then gunESPObject.box:Remove() end
            if gunESPObject.label then gunESPObject.label:Remove() end
            gunESPObject = nil
        end
        return
    end
    
    local rootPart = gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")
    if not rootPart then
        for _, part in pairs(gun:GetChildren()) do
            if part:IsA("BasePart") then
                rootPart = part
                break
            end
        end
    end
    if not rootPart then return end
    
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    
    if not onScreen then
        if gunESPObject then
            if gunESPObject.box then gunESPObject.box:Remove() end
            if gunESPObject.label then gunESPObject.label:Remove() end
            gunESPObject = nil
        end
        return
    end
    
    if not gunESPObject then
        local box = Drawing.new("Square")
        box.Thickness = 3
        box.Filled = false
        box.Visible = true
        box.Color = Color3.new(1, 0.8, 0)
        box.Transparency = 0.3
        box.Size = Vector2.new(50, 50)
        
        local label = Drawing.new("Text")
        label.Size = 13
        label.Center = true
        label.Outline = true
        label.OutlineColor = Color3.new(0, 0, 0)
        label.Visible = true
        label.Color = Color3.new(1, 0.8, 0)
        label.Font = Font
        label.Text = "🔫 GUN"
        
        gunESPObject = {box = box, label = label}
    end
    
    gunESPObject.box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
    gunESPObject.label.Position = Vector2.new(pos.X, pos.Y + 30)
end

-- ===== ESP =====
local function ScanInventory(player)
    local role = "Innocent"
    local char = player.Character
    if not char then return role end
    
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local nameLower = tool.Name:lower()
            if nameLower:find("knife") or nameLower:find("dagger") or nameLower:find("blade") or nameLower:find("sword") then
                return "Murderer"
            elseif nameLower:find("gun") or nameLower:find("pistol") or nameLower:find("revolver") or nameLower:find("shotgun") then
                return "Sheriff"
            end
        end
    end
    
    local inv = player:FindFirstChild("Backpack") or player:FindFirstChild("Inventory")
    if inv then
        for _, tool in pairs(inv:GetChildren()) do
            if tool:IsA("Tool") then
                local nameLower = tool.Name:lower()
                if nameLower:find("knife") or nameLower:find("dagger") or nameLower:find("blade") or nameLower:find("sword") then
                    return "Murderer"
                elseif nameLower:find("gun") or nameLower:find("pistol") or nameLower:find("revolver") or nameLower:find("shotgun") then
                    return "Sheriff"
                end
            end
        end
    end
    
    return role
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character or not player.Character:FindFirstChild("Humanoid") or not player.Character:FindFirstChild("Head") then
            if espObjects[player] then
                espObjects[player].box.Visible = false
                espObjects[player].name.Visible = false
                espObjects[player].roleText.Visible = false
            end
            continue
        end
        
        if not espObjects[player] then
            local box = Drawing.new("Square")
            box.Thickness = 2
            box.Filled = false
            box.Visible = false
            box.Transparency = 0.5
            
            local name = Drawing.new("Text")
            name.Size = 14
            name.Center = true
            name.Outline = true
            name.OutlineColor = Color3.new(0, 0, 0)
            name.Visible = false
            name.Font = Font
            
            local roleText = Drawing.new("Text")
            roleText.Size = 12
            roleText.Center = true
            roleText.Outline = true
            roleText.OutlineColor = Color3.new(0, 0, 0)
            roleText.Visible = false
            roleText.Font = Font
            
            espObjects[player] = {box = box, name = name, roleText = roleText}
        end
        
        local role = ScanInventory(player)
        local head = player.Character.Head
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        local humanoid = player.Character.Humanoid
        
        if not onScreen or humanoid.Health <= 0 then
            espObjects[player].box.Visible = false
            espObjects[player].name.Visible = false
            espObjects[player].roleText.Visible = false
            continue
        end
        
        local color, roleDisplay
        if role == "Murderer" then
            color = Color3.new(1, 0, 0)
            roleDisplay = "🔪 УБИЙЦА"
        elseif role == "Sheriff" then
            color = Color3.new(0, 0.5, 1)
            roleDisplay = "🔫 ШЕРИФ"
        else
            color = Color3.new(0, 1, 0)
            roleDisplay = "👤 Мирный"
        end
        
        local height = 4.5
        local top = head.Position + Vector3.new(0, height/2, 0)
        local bottom = head.Position - Vector3.new(0, height/2, 0)
        local topPos = Camera:WorldToViewportPoint(top)
        local bottomPos = Camera:WorldToViewportPoint(bottom)
        local boxHeight = math.abs(topPos.Y - bottomPos.Y)
        local boxWidth = boxHeight * 0.45
        local x = pos.X - boxWidth / 2
        local y = topPos.Y
        
        local box = espObjects[player].box
        box.Size = Vector2.new(boxWidth, boxHeight)
        box.Position = Vector2.new(x, y)
        box.Color = color
        box.Visible = ESPEnabled
        
        local name = espObjects[player].name
        name.Text = player.Name
        name.Color = color
        name.Position = Vector2.new(pos.X, y - 20)
        name.Visible = ESPEnabled
        
        local roleText = espObjects[player].roleText
        roleText.Text = roleDisplay
        roleText.Color = color
        roleText.Position = Vector2.new(pos.X, y - 2)
        roleText.Visible = ESPEnabled
    end
    
    UpdateGunESP()
end

-- ===== КНОПКИ =====
CloseBtn.MouseButton1Click:Connect(function()
    GuiOpen = false
    MainFrame.Visible = false
end)

EspButton.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    EspButton.Text = ESPEnabled and "🔍 ESP: ON" or "🔍 ESP: OFF"
    EspButton.BackgroundColor3 = ESPEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(80, 30, 30)
    if not ESPEnabled then
        for _, v in pairs(espObjects) do
            if v and v.box then
                v.box.Visible = false
                v.name.Visible = false
                v.roleText.Visible = false
            end
        end
    end
end)

AntiFlingButton.MouseButton1Click:Connect(function()
    AntiFlingEnabled = not AntiFlingEnabled
    AntiFlingButton.Text = AntiFlingEnabled and "🛡️ AF: ON" or "🛡️ AF: OFF"
    AntiFlingButton.BackgroundColor3 = AntiFlingEnabled and Color3.fromRGB(180, 120, 0) or Color3.fromRGB(80, 30, 30)
    
    if AntiFlingEnabled then
        StartAntiFling()
    else
        if antiFlingConnection then
            antiFlingConnection:Disconnect()
            antiFlingConnection = nil
        end
    end
end)

GunESPButton.MouseButton1Click:Connect(function()
    GunESPEnabled = not GunESPEnabled
    GunESPButton.Text = GunESPEnabled and "🔫 Gun ESP: ON" or "🔫 Gun ESP: OFF"
    GunESPButton.BackgroundColor3 = GunESPEnabled and Color3.fromRGB(0, 150, 200) or Color3.fromRGB(80, 30, 30)
    if not GunESPEnabled and gunESPObject then
        if gunESPObject.box then gunESPObject.box:Remove() end
        if gunESPObject.label then gunESPObject.label:Remove() end
        gunESPObject = nil
    end
end)

TPButton.MouseButton1Click:Connect(TeleportToGun)

KillButton.MouseButton1Click:Connect(ToggleAutoKill)

-- ===== FLING GUI =====
local function ToggleFlingGUI()
    if flingGUIOpen then
        if flingGUI then
            flingGUI:Destroy()
            flingGUI = nil
        end
        flingGUIOpen = false
        FlingButton.Text = "💥 Fling GUI"
        return
    end
    
    flingGUIOpen = true
    FlingButton.Text = "💥 Закрыть Fling"
    
    local FGui = Instance.new("ScreenGui")
    FGui.Name = "KilasikFlingGUI"
    FGui.ResetOnSpawn = false
    FGui.Parent = game:GetService("CoreGui")
    flingGUI = FGui
    
    local FMain = Instance.new("Frame")
    FMain.Size = UDim2.new(0, 300, 0, 350)
    FMain.Position = UDim2.new(0.5, -150, 0.5, -175)
    FMain.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    FMain.BorderSizePixel = 0
    FMain.Active = true
    FMain.Draggable = true
    FMain.Parent = FGui
    
    local FTitleBar = Instance.new("Frame")
    FTitleBar.Size = UDim2.new(1, 0, 0, 30)
    FTitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    FTitleBar.BorderSizePixel = 0
    FTitleBar.Parent = FMain
    
    local FTitle = Instance.new("TextLabel")
    FTitle.Size = UDim2.new(1, -30, 1, 0)
    FTitle.BackgroundTransparency = 1
    FTitle.Text = "KILASIK'S MULTI-FLING"
    FTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
    FTitle.Font = Enum.Font.SourceSansBold
    FTitle.TextSize = 18
    FTitle.Parent = FTitleBar
    
    local FClose = Instance.new("TextButton")
    FClose.Position = UDim2.new(1, -30, 0, 0)
    FClose.Size = UDim2.new(0, 30, 0, 30)
    FClose.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    FClose.BorderSizePixel = 0
    FClose.Text = "X"
    FClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    FClose.Font = Enum.Font.SourceSansBold
    FClose.TextSize = 18
    FClose.Parent = FTitleBar
    
    local FStatus = Instance.new("TextLabel")
    FStatus.Position = UDim2.new(0, 10, 0, 40)
    FStatus.Size = UDim2.new(1, -20, 0, 25)
    FStatus.BackgroundTransparency = 1
    FStatus.Text = "Select targets to fling"
    FStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
    FStatus.Font = Enum.Font.SourceSans
    FStatus.TextSize = 16
    FStatus.TextXAlignment = Enum.TextXAlignment.Left
    FStatus.Parent = FMain
    
    local FSel = Instance.new("Frame")
    FSel.Position = UDim2.new(0, 10, 0, 70)
    FSel.Size = UDim2.new(1, -20, 0, 200)
    FSel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    FSel.BorderSizePixel = 0
    FSel.Parent = FMain
    
    local FScroll = Instance.new("ScrollingFrame")
    FScroll.Position = UDim2.new(0, 5, 0, 5)
    FScroll.Size = UDim2.new(1, -10, 1, -10)
    FScroll.BackgroundTransparency = 1
    FScroll.BorderSizePixel = 0
    FScroll.ScrollBarThickness = 6
    FScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    FScroll.Parent = FSel
    
    local FStart = Instance.new("TextButton")
    FStart.Position = UDim2.new(0, 10, 0, 280)
    FStart.Size = UDim2.new(0.5, -15, 0, 40)
    FStart.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    FStart.BorderSizePixel = 0
    FStart.Text = "START FLING"
    FStart.TextColor3 = Color3.fromRGB(255, 255, 255)
    FStart.Font = Enum.Font.SourceSansBold
    FStart.TextSize = 18
    FStart.Parent = FMain
    
    local FStop = Instance.new("TextButton")
    FStop.Position = UDim2.new(0.5, 5, 0, 280)
    FStop.Size = UDim2.new(0.5, -15, 0, 40)
    FStop.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    FStop.BorderSizePixel = 0
    FStop.Text = "STOP FLING"
    FStop.TextColor3 = Color3.fromRGB(255, 255, 255)
    FStop.Font = Enum.Font.SourceSansBold
    FStop.TextSize = 18
    FStop.Parent = FMain
    
    local FSelAll = Instance.new("TextButton")
    FSelAll.Position = UDim2.new(0, 10, 0, 330)
    FSelAll.Size = UDim2.new(0.5, -15, 0, 30)
    FSelAll.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    FSelAll.BorderSizePixel = 0
    FSelAll.Text = "SELECT ALL"
    FSelAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    FSelAll.Font = Enum.Font.SourceSans
    FSelAll.TextSize = 14
    FSelAll.Parent = FMain
    
    local FDeselAll = Instance.new("TextButton")
    FDeselAll.Position = UDim2.new(0.5, 5, 0, 330)
    FDeselAll.Size = UDim2.new(0.5, -15, 0, 30)
    FDeselAll.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    FDeselAll.BorderSizePixel = 0
    FDeselAll.Text = "DESELECT ALL"
    FDeselAll.TextColor3 = Color3.fromRGB(255, 255, 255)
    FDeselAll.Font = Enum.Font.SourceSans
    FDeselAll.TextSize = 14
    FDeselAll.Parent = FMain
    
    local SelectedTargets = {}
    local PlayerCheckboxes = {}
    local FlingActive = false
    getgenv().OldPos = nil
    getgenv().FPDH = workspace.FallenPartsDestroyHeight
    
    local function RefreshPlayerList()
        for _, child in pairs(FScroll:GetChildren()) do
            child:Destroy()
        end
        PlayerCheckboxes = {}
        
        local PlayerList = Players:GetPlayers()
        table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)
        
        local yPos = 5
        for _, player in ipairs(PlayerList) do
            if player ~= LocalPlayer then
                local entry = Instance.new("Frame")
                entry.Size = UDim2.new(1, -10, 0, 30)
                entry.Position = UDim2.new(0, 5, 0, yPos)
                entry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                entry.BorderSizePixel = 0
                entry.Parent = FScroll
                
                local cb = Instance.new("TextButton")
                cb.Size = UDim2.new(0, 24, 0, 24)
                cb.Position = UDim2.new(0, 3, 0.5, -12)
                cb.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                cb.BorderSizePixel = 0
                cb.Text = ""
                cb.Parent = entry
                
                local cm = Instance.new("TextLabel")
                cm.Size = UDim2.new(1, 0, 1, 0)
                cm.BackgroundTransparency = 1
                cm.Text = "✓"
                cm.TextColor3 = Color3.fromRGB(0, 255, 0)
                cm.TextSize = 18
                cm.Font = Enum.Font.SourceSansBold
                cm.Visible = SelectedTargets[player.Name] ~= nil
                cm.Parent = cb
                
                local nl = Instance.new("TextLabel")
                nl.Size = UDim2.new(1, -35, 1, 0)
                nl.Position = UDim2.new(0, 30, 0, 0)
                nl.BackgroundTransparency = 1
                nl.Text = player.Name
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nl.TextSize = 16
                nl.Font = Enum.Font.SourceSans
                nl.TextXAlignment = Enum.TextXAlignment.Left
                nl.Parent = entry
                
                local ca = Instance.new("TextButton")
                ca.Size = UDim2.new(1, 0, 1, 0)
                ca.BackgroundTransparency = 1
                ca.Text = ""
                ca.ZIndex = 2
                ca.Parent = entry
                
                ca.MouseButton1Click:Connect(function()
                    if SelectedTargets[player.Name] then
                        SelectedTargets[player.Name] = nil
                        cm.Visible = false
                    else
                        SelectedTargets[player.Name] = player
                        cm.Visible = true
                    end
                    UpdateFStatus()
                end)
                
                PlayerCheckboxes[player.Name] = {Entry = entry, Checkmark = cm}
                yPos = yPos + 35
            end
        end
        FScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
    end
    
    local function CountSelected()
        local c = 0
        for _ in pairs(SelectedTargets) do c = c + 1 end
        return c
    end
    
    local function UpdateFStatus()
        local c = CountSelected()
        if FlingActive then
            FStatus.Text = "Flinging " .. c .. " target(s)"
            FStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            FStatus.Text = c .. " target(s) selected"
            FStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
    
    local function ToggleAll(select)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local data = PlayerCheckboxes[player.Name]
                if data then
                    if select then
                        SelectedTargets[player.Name] = player
                        data.Checkmark.Visible = true
                    else
                        SelectedTargets[player.Name] = nil
                        data.Checkmark.Visible = false
                    end
                end
            end
        end
        UpdateFStatus()
    end
    
    local function Notify(Title, Text, Time)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = Title,
            Text = Text,
            Duration = Time or 5
        })
    end
    
    local function SkidFling(TargetPlayer)
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character
        if not TCharacter then return end
        
        local THumanoid
        local TRootPart
        local THead
        local Accessory
        local Handle
        if TCharacter:FindFirstChildOfClass("Humanoid") then
            THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
        end
        if THumanoid and THumanoid.RootPart then
            TRootPart = THumanoid.RootPart
        end
        if TCharacter:FindFirstChild("Head") then
            THead = TCharacter.Head
        end
        if TCharacter:FindFirstChildOfClass("Accessory") then
            Accessory = TCharacter:FindFirstChildOfClass("Accessory")
        end
        if Accessory and Accessory:FindFirstChild("Handle") then
            Handle = Accessory.Handle
        end
        if Character and Humanoid and RootPart then
            if RootPart.Velocity.Magnitude < 50 then
                getgenv().OldPos = RootPart.CFrame
            end
            
            if THumanoid and THumanoid.Sit then
                return Notify("Error", TargetPlayer.Name .. " is sitting", 2)
            end
            
            if THead then
                workspace.CurrentCamera.CameraSubject = THead
            elseif Handle then
                workspace.CurrentCamera.CameraSubject = Handle
            elseif THumanoid and TRootPart then
                workspace.CurrentCamera.CameraSubject = THumanoid
            end
            
            if not TCharacter:FindFirstChildWhichIsA("BasePart") then
                return
            end
            
            local FPos = function(BasePart, Pos, Ang)
                RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end
            
            local SFBasePart = function(BasePart)
                local TimeToWait = 2
                local Time = tick()
                local Angle = 0
                repeat
                    if RootPart and THumanoid then
                        if BasePart.Velocity.Magnitude < 50 then
                            Angle = Angle + 100
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                        else
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                            task.wait()
                        end
                    end
                until Time + TimeToWait < tick() or not FlingActive
            end
            
            workspace.FallenPartsDestroyHeight = 0/0
            
            local BV = Instance.new("BodyVelocity")
            BV.Parent = RootPart
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            
            if TRootPart then
                SFBasePart(TRootPart)
            elseif THead then
                SFBasePart(THead)
            elseif Handle then
                SFBasePart(Handle)
            else
                return Notify("Error", TargetPlayer.Name .. " has no valid parts", 2)
            end
            
            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.CurrentCamera.CameraSubject = Humanoid
            
            if getgenv().OldPos then
                repeat
                    RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                    Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                    Humanoid:ChangeState("GettingUp")
                    for _, part in pairs(Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                        end
                    end
                    task.wait()
                until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
                workspace.FallenPartsDestroyHeight = getgenv().FPDH
            end
        else
            return Notify("Error", "Your character is not ready", 2)
        end
    end
    
    local function StartFling()
        if FlingActive then return end
        
        local count = CountSelected()
        if count == 0 then
            FStatus.Text = "No targets selected!"
            wait(1)
            FStatus.Text = "Select targets to fling"
            return
        end
        
        FlingActive = true
        UpdateFStatus()
        Notify("Started", "Flinging " .. count .. " targets", 2)
        
        spawn(function()
            while FlingActive do
                local valid = {}
                for name, player in pairs(SelectedTargets) do
                    if player and player.Parent then
                        valid[name] = player
                    else
                        SelectedTargets[name] = nil
                        local cb = PlayerCheckboxes[name]
                        if cb then cb.Checkmark.Visible = false end
                    end
                end
                
                for _, player in pairs(valid) do
                    if FlingActive then
                        SkidFling(player)
                        wait(0.1)
                    else break end
                end
                UpdateFStatus()
                wait(0.5)
            end
        end)
    end
    
    local function StopFling()
        if not FlingActive then return end
        FlingActive = false
        UpdateFStatus()
        Notify("Stopped", "Fling has been stopped", 2)
    end
    
    FStart.MouseButton1Click:Connect(StartFling)
    FStop.MouseButton1Click:Connect(StopFling)
    FSelAll.MouseButton1Click:Connect(function() ToggleAll(true) end)
    FDeselAll.MouseButton1Click:Connect(function() ToggleAll(false) end)
    
    FClose.MouseButton1Click:Connect(function()
        StopFling()
        FGui:Destroy()
        flingGUI = nil
        flingGUIOpen = false
        FlingButton.Text = "💥 Fling GUI"
    end)
    
    Players.PlayerAdded:Connect(RefreshPlayerList)
    Players.PlayerRemoving:Connect(function(player)
        if SelectedTargets[player.Name] then
            SelectedTargets[player.Name] = nil
        end
        RefreshPlayerList()
        UpdateFStatus()
    end)
    
    RefreshPlayerList()
    UpdateFStatus()
    Notify("Loaded", "KILASIK's Multi-Target Fling GUI loaded!", 3)
end

-- Legacy standalone fling UI disabled: controls are kept inside the unified WindUI interface.

-- ===== СОБЫТИЯ =====
Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then
        espObjects[player].box:Remove()
        espObjects[player].name:Remove()
        espObjects[player].roleText:Remove()
        espObjects[player] = nil
    end
end)

-- Запуск
StartAntiFling()
RunService.RenderStepped:Connect(UpdateESP)

-- Сброс состояния при смерти
LocalPlayer.CharacterAdded:Connect(function()
    sheriffDead = false
    if gunESPObject then
        if gunESPObject.box then gunESPObject.box:Remove() end
        if gunESPObject.label then gunESPObject.label:Remove() end
        gunESPObject = nil
    end
    if AutoKillEnabled then
        task.wait(1)
        StartAutoKill()
    end
end)

-- Управление старым GUI и хоткеями отключено: все переключатели перенесены в WindUI.

--[[
    Cosmic UI — Autofarm v6.1 (MM2), сборка 6.1.3

    ГЛАВНОЕ В v6.1 (правки поверх v6.0):

      A) ВАЛЮТА ИЩЕТСЯ УНИВЕРСАЛЬНО — ПО СЛОВУ "coin" В ИМЕНИ.
         • точные признаки игры (как было): атрибут CoinID, теги
           CollectionService со словом coin, ручные CONFIG.CURRENCY_NAME /
           CURRENCY_EXTRA;
         • плюс ЛЮБАЯ ИНТЕРАКТИВНАЯ часть (TouchTransmitter / ClickDetector /
           ProximityPrompt), в имени которой есть "coin": Coin, Coin_Server,
           CoinVisual, CoinPart, ServerCoinPart — это и есть семейство MM2;
         • ЯВНЫЙ ЧЁРНЫЙ СПИСОК ДЕКОРА: handle, door, knob, bucket, basket,
           lamp, sign, valve, crate, fence... — именно из-за их отсутствия
           бот летал на oct_handle (ручки дверей) и вёдра конфет;
         • авто-определение "много одинаковых мелких частей" УДАЛЕНО: это
           оно и выбирало ручки/вёдра вместо валюты.

      B) F9 БОЛЬШЕ НЕ НУЖЕН. На вкладке Farm под кнопками есть ЛОГ (6 строк)
         и кнопка Copy. Туда пишется: каким признаком найдена валюта, сколько
         её видно, к чему летим, что забрали и почему стоим.

      C) ПОЧЕМУ ПОСЛЕ РАУНДА БЫЛО "ВАЛЮТА НЕ НАЙДЕНА", А БОТ СТОЯЛ.
         Старый фильтр толпы ВЫБРАСЫВАЛ цель, если к ней был ближе другой
         игрок. На полном сервере ботов так выкидывались ВСЕ монеты: счётчик
         валюты на карте не ноль, а цель не находится. Теперь толпа — это
         ШТРАФ к дистанции при выборе цели, а не запрет: цель есть всегда.
         Плюс раз в 30..45 c бот сам уходит к случайной монете (из наименее
         людных), чтобы куча ботов не липла к одной.

      D) NOCLIP ПРОБИВАЕТ И ПОЛ. Потолок бот проходил и раньше (коллизий нет),
         а пол его "держал" не коллизией, а сам Humanoid: он подпирал корень
         на HipHeight. Пока скрипт ведёт персонажа, ставится
         PlatformStand = true — гуманоид перестаёт подпирать, и бот проходит
         пол так же, как потолок. Это же убирает "огибание" препятствий:
         запись CFrame больше не отменяется физикой.

      E) ПОЛЁТ СТАЛ ПРЯМЕЕ. Перевыбор цели раз в 0.35 c (новая монета ближе на
         25%) постоянно заворачивал бота в сторону — со стороны это выглядело
         как объезд препятствий. Теперь цель фиксируется на весь заход, а
         пересмотр — раз в 1.5 c и только если новая цель ближе на 15 студов.

      F) "СТОП В ЛОББИ" УДАЛЁН ПОЛНОСТЬЮ: нет кнопки, флага, функций
         enterLobby/leaveLobby и всей механики roundOver. Вместе с ней ушла
         и детекция надписи Intermission (она тоже ложно останавливала фарм).
         Новый раунд определяется по респавну персонажа и по счётчику валюты
         сервера.

      G) ВКЛАДКА НАСТРОЕК НАЗЫВАЕТСЯ Settings (в коде и в окне одинаково).

      H) МЕТКА СБОРКИ + САМОПРОВЕРКА (с v6.1.2). При запуске в лог пишется
         версия сборки из BUILD ("v6.1.3 загружен") и результат самопроверки.
         Если файл
         при копировании/склейке потерял функцию, то раньше это вылезало как
         "ошибка фарма: :1828: attempt to call a nil value" — по такому тексту
         нельзя понять, ЧТО именно nil. Теперь в этом случае в лог пишется
         "СБОРКА СЛОМАНА — нет функций: <имена>", а Start farm просто не
         стартует вместо потока одинаковых ошибок.

      I) «ЗАМЕР В ЛОББИ» (v6.1.3). Если ВСЕ монеты дальше COIN_RANGE (350), бот
         стоял с «валюта не найдена», хотя в кэше 30+ монет (это лобби или
         другой край карты). В v6.0 фарм в лобби просто останавливался, а в
         v6.1 стоп-в-лобби убрали — и выхода из этого состояния не осталось:
         цель есть, но ни одна не проходит фильтр радиуса. Теперь при пустом
         радиусе бот летит к САМОЙ БЛИЖНЕЙ монете вообще (дальний перелёт на
         скорости FLY_SPEED), а в лог пишется «все монеты дальше 350 ст —
         лечу к ближайшей (... , N ст)». Строка «валюта: N шт. (…)» теперь
         пишется только при смене СПОСОБА распознавания (CoinID/теги/имя), а
         не на каждое изменение количества — иначе она вытесняла из окна лога
         метку сборки и ошибки.

      J) НЕ ЛЕТИМ С ЛОББИ (v6.1.4, усилено в v6.1.5). Если в этом раунде ещё
         ничего не собрано, а ближайшая монета дальше FAR_HOLD_DIST (1500 ст),
         бот считает, что он не на карте (спавн/межраундье), и НЕ летит через
         полкарты: стоит, пока игра сама не перенесёт персонажа на карту.
         Дальний перелёт из v6.1.3 остался для честно далёких монет, когда бот
         уже на карте (после первой собранной монеты порог не действует).
         v6.1.5: таймаута БОЛЬШЕ НЕТ. В 6.1.4 через FAR_HOLD_MAX (30 c) бот всё
         равно летел — и в лобби это снова давало «лечу к ближайшей (8866 ст)».
         Теперь FAR_HOLD_MAX только печатает подробную диагностику.

      K) SMART SPEED ПО ВЕКТОРУ (v6.1.4). Скорость считается по длине 3D-пути
         (dist3), а не по горизонтальной проекции: наискосок/вверх бот получает
         ту же скорость, что и по прямой, и не «сначала вперёд, потом вверх».

      L) ПОДБОР ПО МЕШКУ (v6.1.4). Вместимость мешка берётся из события сервера,
         а если её там нет — из GUI игры (текст ровно вида «N/M»). Ресет теперь
         срабатывает по факту «мешок полон» (50/50 или 40/40 — как в сезоне), а
         RESET_AT_COINS остался страховкой для игр без вместимости в событии.
         Там же исправлено падение «:2026: attempt to index nil with 'Position'»:
         цель могла обнулиться обработчиком валюты прямо посреди полёта.

      M) В ОЖИДАНИИ БОТ НЕ ТРОГАЕТ ПЕРСОНАЖА (v6.1.5). Это и была причина
         «зафризился в лобби, когда раунд начался»: пока фарм запущен, позиция
         удерживалась записью CFrame (holdStill) каждый кадр, noclip был включён,
         а гуманоид стоял в PlatformStand. Когда сервер переносил персонажа на
         карту, наша же запись CFrame в том же кадре возвращала его назад, и бот
         оставался в лобби на весь раунд. Теперь в режиме lobbyHold бот:
           • не пишет CFrame (вместо holdStill(0.3) — просто task.wait(0.3));
           • выключает noclip (коллизии персонажа возвращаются);
           • выключает PlatformStand (гуманоид обычный: работают и MoveTo, и
             серверный перенос).
         В лог при этом идёт «жду карту: монета N ст > 1500 | я (x, y, z) |
         монет N | заякорен: false», а в статусе — «жду карту: N ст, M c».

      N) СЛАЙДЕР СКОРОСТИ СТАЛ РЕАЛЬНЫМ (v6.1.6). Значение слайдера (1..50) было
         МНОЖИТЕЛЕМ к «умной» базе (5 * (0.6..3) * слайдер), поэтому всё, что
         выше 10, упиралось в прежний SPEED_CAP = 30 ст/с: 20 и 50 давали одно и
         то же, а разница чувствовалась только на 1..7. Теперь шкала линейная и
         означает скорость в ст/с: 1 -> SPEED_LO (10), 50 -> SPEED_HI (80), шаг
         ≈1.4 ст/с. На слайдере видно «Speed: 25 (45 ст/с)», в статусе — «v=45.0».
         Smart Speed больше не «съедает» шкалу: у самой цели (ближе
         SMART_REF_DIST = 120) он добавляет до SMART_BOOST = 1.5x, потолок
         SPEED_CAP = 100. Заодно MAX_FRAME_MOVE поднят 1.5 -> 3 студа за кадр:
         старый предел обрезал верх шкалы до 45 ст/с на 30 fps (1.5 студа/кадр).
         MIN_FARM_SPEED удалён — нижнюю границу теперь задаёт SPEED_LO.

    ГЛАВНОЕ В v6.0 (осталось в силе):

      B) AUTO RESET СНОВА РАБОТАЕТ. Раньше при ALLOW_SELF_RESET = false он
         вместо ресета пытался «перенести на точку спавна», а без точки
         спавна не делал НИЧЕГО (только писал подсказку в F9). Теперь, как в
         v5.7: персонаж перерождается (Health = 0 + Dead), счётчики и цель
         сбрасываются, выдаётся льгота SPAWN_GRACE. Прогресс для IDLE_RESET
         считается по 3D-дистанции, поэтому долгий подъём к валюте больше
         не выглядит как простой.

      C) ПОЛЁТ: ПРЯМАЯ ЛИНИЯ, БЕЗ «ГОРБА» ПОСЛЕ МОНЕТЫ.
         • Раньше высота бралась от пола ПОД ПЕРСОНАЖЕМ (пересчёт раз в 0.2 c),
           поэтому пролетая над столом/лавкой/монетой бот поднимался на ~3
           студа и потом опускался — это и был «горб» между монетами.
         • Теперь высота считается ОТ ПОЛА ПОД САМОЙ ВАЛЮТОЙ (coinFloorY) и на
           весь полёт к этой валюте не меняется. Валюта в воздухе (пола нет
           или она выше пола на FLOOR_TOLERANCE) — ведём прямо к ней.
         • Движение — по 3D-прямой к точке над валютой: вертикаль
           распределена по всему пути, а не «сначала по X, потом по Y».
         • Высота корня берётся из Humanoid.HipHeight + половина корня (≈3),
           а не из замера под персонажем — она больше не «прыгает».

    ЧТО БЫЛО В v5.9: ЛЕТАЕМ ТОЛЬКО К ВАЛЮТЕ И СЧИТАЕМ ТОЛЬКО ТО, ЧТО ВЗЯЛИ.

      1) ВАЛЮТА ОПРЕДЕЛЯЕТСЯ ПО ПРИЗНАКАМ ИГРЫ (в v6.1 — ещё и по слову coin):
           • атрибут CoinID у подбираемой части (в MM2 это Coin_Server
             с CoinID = "Candy"). Это точный признак — имя не важно;
           • теги CollectionService со словом coin (ServerCoinPart, CoinVisual);
           • имя части содержит "coin" (Coin, Coin_Server, CoinVisual,
             ServerCoinPart, CandyCoin) — при условии, что часть подбираемая;
           • CONFIG.CURRENCY_NAME / CURRENCY_EXTRA — если в игре валюта
             зовётся совсем иначе (например "Candy" без CoinID и тегов).
         Чёрный список декора (CONFIG.CURRENCY_DENY) отсекает ручки, двери,
         вёдра, лампы и прочее, даже если в их имени есть "coin".
         Авто-определение "много одинаковых частей" УДАЛЕНО (ловило декор).

      2) СЧЁТ ПО ФАКТУ, А НЕ «ДОЛЕТЕЛ — ЗАСЧИТАЛ».
         Летим так же плавно, как v5.8 (тот же шаг CFrame каждый кадр,
         без телепортов и без рывков RenderStepped). Но, дойдя до валюты,
         бот ДЕРЖИТСЯ над ней и ждёт, пока игра реально её заберёт:
           • часть исчезла / атрибут Collected / CoinVisual.Collected;
           • либо пришло событие сервера CoinCollected (если такой
             RemoteEvent есть — счёт ведётся прямо по нему, это точнее всего).
         Ничего не забралось за TOUCH_TIMEOUT — это декор: НЕ засчитываем,
         цель уходит в чёрный список на FAIL_BLACKLIST секунд (не кружимся).

      3) NOCLIP БОЛЬШЕ НЕТ В НАСТРОЙКАХ: он включается САМ, как только
         фарм/полёт начинают вести персонажа, и выключается, когда всё
         стоит (иначе персонаж проваливался бы в лобби).

      4) МАРШРУТ ПО ТОЧКАМ УДАЛЁН ПОЛНОСТЬЮ: кнопки, настройки маршрута и весь код.

      Ядро фарма — v5.6/v5.8: COIN_RANGE 350, noclip в RunService.Stepped,
      CFrame + velocity-fallback, скорости, супервизор в pcall, стоп в лобби.
      Высота полёта — v6.0 (от пола под валютой, движение по 3D-прямой).

    ЧТО ОСТАЛОСЬ ИЗ v5.8:
           • АНТИ-КРУГИ — FAIL_BLACKLIST (20 c недостижимую цель не берём);
           • стоп в лобби по Intermission/смерти + Auto Start.

    ВАЖНО (v6.0): точек спавна и лобби больше нет. Никаких «Спавн здесь»,
    «Лобби здесь», «Держаться спавна», «Перенос на спавн» — и в F9, и в
    CONFIG этих настроек тоже нет.

    ГЛАВНОЕ В v5.6 (лобби):
      7) СТОП В ЛОББИ. По окончании раунда фарм встаёт и бот больше НЕ летает
         по лобби. Раньше в лобби он продолжал искать/собирать валюту.
         Признаки конца раунда (v6.0: только эти два):
           • смерть персонажа (в MM2 до нового раунда собирать нечего);
           • надпись Intermission в GUI (PlayerGui + CoreGui).
         Пока стоп активен, Auto Start НЕ перезапускает фарм на респавне
         (именно это и гнало бота по лобби). Возобновление: Intermission
         пропал — тогда, если Auto Start включён, фарм стартует сам, иначе
         ждёт кнопку Run.
         При стопе выключается Fly и гасятся скорости, персонаж не висит
         в воздухе. Тумблер "Стоп в лобби" на вкладке Farm отключает всё это.

    ГЛАВНОЕ В v5.5 (почему "не летел" v5.4.1 — построчное сравнение с v5.3):
      1) NOCLIP. В v5.3 коллизии персонажа выключались в RunService.Stepped,
         то есть КАЖДЫЙ физический шаг, пока бот ведёт персонажа. В v5.4.1
         это делал таймер раз в 0.2 c — физика успевала вернуть CanCollide,
         персонаж упирался в стены/пол и не двигался. Теперь как в v5.3:
         Stepped-хук (см. блок "NOCLIP: как в v5.3").
      2) СУПЕРВИЗОР. В v5.4.1 pollRound() вызывался ВНЕ pcall: одна ошибка —
         и поток фарма умирал навсегда, без сообщений (бот просто стоял).
         Теперь каждый шаг в pcall и любая ошибка печатается.
      3) СКОРОСТЬ. При Smart Speed = 1 множитель на дальней дистанции давал
         ~3 студа/с (медленнее ходьбы), поэтому у скорости есть нижняя граница
         и «умное» ускорение у цели (в 6.1.6 шкала слайдера переделана в
         ст/с — см. пункт N).
      4) FALLBACK ДВИЖЕНИЯ. Если CFrame-запись персонажа не сдвигает (игра/
         физика возвращает позицию), бот сам переключается на velocity-толчок
         и пишет об этом в консоль.
      5) ДИАГНОСТИКА. В окне вторая строка статуса показывает цель,
         дистанцию, скорость, режим движения и ПРИЧИНУ простоя
         ("валюта не найдена", "персонаж мёртв", "intermission" ...).
         В консоль (F9) раз в 3 c: "[Cosmic][dbg] ... сдвиг=...".
         Раньше причина простоя была не видна вообще.
      6) ВЫСОТА (главная причина "стоит на месте" после v5.2). В v5.2 бот
         ехал ПО ЗЕМЛЕ: Raycast вниз + hipOffset (корень = пол + ~3 студа).
         В v5.3/v5.4 корень ведётся на "валюта.Y + 1", то есть на уровень
         пола — тело уходит в пол по пояс, коллизии зажимают персонажа и он
         не двигается. В v5.6..v5.9 высота бралась от пола ПОД ПЕРСОНАЖЕМ
         (пересчёт раз в 0.2 c) — из-за этого бот приседал/подпрыгивал на
         предметах. В v6.0 высота — от пола ПОД ВАЛЮТОЙ (см. coinFloorY),
         а "догнал" считается по горизонтали. Валюта в воздухе (выше пола
         на FLOOR_TOLERANCE) — летим прямо к ней.

    ВАЖНО: если в статусе "валюта не найдена" — распознавание не сработало.
    Смотрим ЛОГ на вкладке Farm (F9 не нужен): там строка "не найдено,
    кандидаты: ..." с именами частей. Дальше либо добавляем слово в
    CONFIG.CURRENCY_EXTRA, либо вписываем точное имя в CONFIG.CURRENCY_NAME.

    ПРЕДЫДУЩЕЕ (v5.4.1):
      - Ресет (смерть -> спавн) в начале раунда. Причина: таймер простоя
        (IDLE_RESET = 12 c) обновлялся ТОЛЬКО когда бот собирал/догонял монету.
        Теперь: старт раунда сбрасывает roundCoins/visited и выдаёт льготу
        ROUND_GRACE, а при отсутствии монет таймер простоя тоже сбрасывается.
      - ВАЛЮТА: ручное имя можно вписать: CONFIG.CURRENCY_NAME = "Candy".

    ФУНКЦИИ: пароль, Run/Stop, Auto Start, Auto Reset (по монетам/простою/
    падению — перерождает персонажа), Smart Speed + слайдер, Anti-AFK,
    Anti-Fling, Fly, «Избегать толпы», лог на Farm, Ctrl — скрыть/показать меню.
    Noclip включается сам (тумблера нет), точек спавна/лобби и стопа в лобби нет.
]]

--========================================================
-- SERVICES
--========================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")   -- v5.9: теги валюты
local ReplicatedStorage = game:GetService("ReplicatedStorage")   -- v5.9: событие CoinCollected

local VirtualUser
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")


--========================================================
-- CONFIG (значения v5.3, кроме помеченного)
--========================================================
local CONFIG = {
    PASSWORD     = "salt",

    -- Скорость. v6.1.6: слайдер — это РЕАЛЬНАЯ скорость (ст/с), а не множитель.
    SPEED_MIN    = 1,
    SPEED_MAX    = 50,
    SPEED_LO     = 10,      -- ст/с при слайдере 1
    SPEED_HI     = 80,      -- ст/с при слайдере 50 (+1.43 ст/с на каждый шаг)
    SPEED_CAP    = 100,     -- жёсткий потолок итоговой (после «умного» ускорения)
    SMART_REF_DIST = 120,   -- ближе этого расстояния Smart Speed добавляет скорость
    SMART_BOOST  = 1.5,     -- ...и не больше чем в 1.5 раза (у самой цели)
    MAX_FRAME_MOVE = 3.0,   -- максимум студов за кадр (анти-"invalid position");
                            -- 1.5 обрезал верх слайдера на 30 fps (45 ст/с)
    FLY_SPEED    = 70,      -- скорость ручного полёта

    -- Диагностика: состояние фарма дублируется в лог окна (вкладка Farm)
    -- и, если доступна консоль, в неё — раз в DBG_INTERVAL сек.
    DEBUG         = true,
    DBG_INTERVAL  = 3,

    -- Валюта (в ивентах MM2 это не монеты, а конфеты и т.п.)
    COIN_RANGE   = 350,
    -- v6.1.3: «дальний перелёт». Если в радиусе COIN_RANGE валюты нет (персонаж
    -- в лобби или на другом краю карты), бот всё равно летит к ближайшей монете,
    -- но на скорости FLY_SPEED: обычная скорость фарма превращала 2000 студов в
    -- минуту стояния на месте. Ближе FAR_DIST ускорение не включается.
    FAR_DIST     = 400,
    -- v6.1.4: ПОРОГ «МЫ В ЛОББИ». Пока в этом раунде не собрано ни одной монеты и
    -- ближайшая валюта дальше этого значения, бот НЕ летит (иначе он уезжал из
    -- лобби к монете за 8000 студов и не давал игре перенести себя на карту).
    -- 0 = выключить проверку. 1500..2000 — рабочие значения для MM2.
    FAR_HOLD_DIST = 1500,
    -- v6.1.5: через сколько секунд стояния вывести ПОДРОБНУЮ диагностику (позиция,
    -- сколько монет, заякорен ли персонаж). Это только лог: лететь всё равно не
    -- будем — в 6.1.4 полёт после таймаута ломал перенос на карту.
    FAR_HOLD_MAX  = 30,
    STOP_DIST    = 2,       -- догнал = горизонталь <= этого (студов)
    PICKUP_LIFT  = 1,       -- насколько корень выше центра висящей валюты
    FLOOR_TOLERANCE = 2.5,  -- v6.0: валюта выше пола на столько = висит в воздухе
    STUCK_LIMIT  = 1.0,     -- сек. без прогресса рядом с целью -> бросить цель
    VISIT_COOLDOWN = 0.6,   -- не возвращаться к той же монете слишком часто

    -- v6.1: ВАЛЮТА — УНИВЕРСАЛЬНО ПО СЛОВУ "coin" + точные признаки игры.
    -- В MM2 подбираемая часть называется Coin_Server (невидимая, с Touch),
    -- её ребёнок — CoinVisual, а на сервере она помечена атрибутом CoinID.
    -- Поэтому принимаем ЛЮБОЕ из:
    --   1) атрибут CoinID (значение любое, если CURRENCY_ID = nil);
    --   2) тег CollectionService со словом coin (ServerCoinPart, CoinVisual);
    --   3) имя части содержит "coin" (Coin, Coin_Server, CoinVisual, ...);
    --   4) имена из CURRENCY_EXTRA / CURRENCY_NAME (если валюта зовётся иначе).
    -- Всё, что похоже на декор (ручки, двери, вёдра, лампы), отсекается
    -- CURRENCY_DENY — именно из-за их отсутствия бот летал на oct_handle и
    -- вёдра конфет вместо валюты.
    CURRENCY_ATTR = "CoinID",   -- имя атрибута валюты ("" = не проверять)
    CURRENCY_ID   = nil,        -- ожидаемое значение ("Candy"); nil = любое
    CURRENCY_WORD = "coin",     -- v6.1: слово валюты (Coin, Coin_Server, ...)
    CURRENCY_TAGS = { "ServerCoinPart", "CoinVisual", "Coin", "Coins" },
    CURRENCY_EXTRA = {},        -- v6.1: {"Candy", "Cash"} — если нет "coin"
    CURRENCY_NAME  = nil,       -- точное имя объекта (крайний вариант)
    CURRENCY_MAX_SIZE = 12,     -- объект крупнее (студов) валютой не считается
    CURRENCY_BIG_SIZE = 6,      -- твёрдый объект крупнее этого — декор
    CURRENCY_DENY = {           -- v6.1: слова декора (часть имени, lowercase)
        "handle", "knob", "lever", "hinge", "door", "button", "switch", "seat",
        "sign", "lamp", "light", "glass", "window", "wheel", "valve", "bucket",
        "basket", "bag", "sack", "jar", "barrel", "crate", "fence", "gate",
        "wall", "floor", "roof", "stair", "ladder", "poster", "decal", "rope",
        "chain", "wire", "bulb", "frame", "mount", "bracket", "spool", "trap",
    },

    -- v5.9: СЧЁТ ПО ФАКТУ. Дошли -> держимся над валютой и ждём, пока игра
    -- реально её заберёт (часть исчезла / Collected / событие CoinCollected).
    TOUCH_TIMEOUT      = 1.2,   -- сек. на попытку подбора (потом — в чёрный список)
    TOUCH_ASSIST       = true,  -- дёргать firetouchinterest, если исполнитель умеет
    TOUCH_ASSIST_DELAY = 0.15,  -- через сколько сек. после подлёта пробовать
    TOUCH_RETRY_AT     = 0.3,   -- повтор попытки касания

    -- Кэш: полный обход workspace дорогой, поэтому не чаще, чем раз в N сек.
    COIN_SCAN_INTERVAL = 0.75,
    COIN_RESCAN_EMPTY  = 0.75,  -- если валюты не видно — тот же шаг

    -- v6.1: перепроверка цели. Раньше 0.35 c + "ближе на 25%" -> бот постоянно
    -- заворачивал в сторону (со стороны выглядело как объезд препятствий).
    RETARGET_INTERVAL  = 1.5,   -- сек. между пересмотром цели
    RETARGET_ADVANTAGE = 15,    -- новая цель должна быть ближе минимум на столько

    -- v6.1: ТОЛПА. Монету, у которой висит другой бот, НЕ запрещаем (из-за
    -- этого после раунда выкидывались все цели и бот стоял на спавне).
    -- Просто делаем её "дороже" в выборе: штраф к дистанции за игрока рядом.
    CROWD_WEIGHT     = 3,     -- штраф (студов) за каждого игрока рядом
    CONTEST_RADIUS   = 10,    -- радиус, в котором игрок считается "рядом"
    CROWD_WANDER_MIN = 30,    -- сек.: минимум до ухода к случайной монете
    CROWD_WANDER_MAX = 45,    -- сек.: максимум (чтобы не липнуть к одной куче)

    -- Ресеты
    IDLE_RESET       = 12,  -- сек. без единой собранной монеты -> ресет
    -- v6.1.4: ресет по мешку. Если вместимость известна (событие сервера или
    -- GUI игры «N/M»), ресет идёт ровно по «мешок полон», а этот лимит не
    -- используется. Значение ниже — страховка для игр, где вместимость молчит.
    RESET_AT_COINS   = 40,  -- собрано монет за раунд -> ресет (0 = выключено)
    RESET_Y          = -50, -- ниже этой высоты персонаж считается упавшим
    FALL_CONFIRM     = 1.0, -- столько сек. ниже RESET_Y -> ресет (анти-ложные)
    SPAWN_GRACE      = 10,  -- льгота после спавна персонажа, сек.
    ROUND_GRACE      = 12,  -- льгота после старта раунда (роль/кулдаун), сек.

    -- v6.1: "СТОП В ЛОББИ" УДАЛЁН ПОЛНОСТЬЮ — вместе с ним ушла детекция
    -- надписи Intermission (она тоже иногда ложно останавливала фарм).
    -- Новый раунд определяется по респавну персонажа и по счётчику валюты
    -- сервера (CoinsStarted / уменьшение значения).

    -- Anti-Fling
    FLING_MAX_VEL = 60, FLING_MAX_ANG = 25,

    -- v6.0: точек спавна больше нет (кнопки «Спавн здесь» / «Держаться спавна»
    -- / «Перенос на спавн» удалены). Здесь остались только анти-круги.
    FAIL_BLACKLIST   = 20,    -- сек. недостижимая цель не берётся (0 = выкл)
}

local COLORS = {
    bgTop   = Color3.fromRGB(40, 12, 70),
    bgBot   = Color3.fromRGB(12, 2, 25),
    accent  = Color3.fromRGB(140, 45, 240),
    accent2 = Color3.fromRGB(95, 55, 165),
    text    = Color3.fromRGB(255, 255, 255),
    gray    = Color3.fromRGB(55, 55, 60),
    dim     = Color3.fromRGB(160, 140, 200),
    green   = Color3.fromRGB(80, 255, 120),
    red     = Color3.fromRGB(255, 100, 120),
}

--========================================================
-- STATE
--========================================================
local flags = {
    autoReset  = false,  -- как в v5.3: по умолчанию выключено
    autoStart  = false, -- в объединённом хабе автозапуск включается вручную
    avoidCrowd = true,   -- v6.1: не липнуть к куче ботов у одной монеты
    antiAFK    = true,
    antiFling  = true,
    smartSpeed = true,
    fly        = false,
}

local unlocked        = true -- экран пароля отключён: доступ через единый WindUI
local farmRunning     = false
local movingToCoin    = false   -- фарм сейчас ведёт персонажа
local speedValue      = 5       -- v6.1.6: 1..50 = скорость (10..80 ст/с), см. baseSpeed()

-- v6.1: стоп-в-лобби удалён целиком, цели-«круги» остались
local failedUntil      = {}     -- цель -> время, до которого её не берём

-- v6.1: уход от толпы раз в CROWD_WANDER_MIN..MAX секунд
local wanderNextAt     = 0      -- когда в следующий раз уходить к случайной
local wanderTarget     = nil    -- выбранная случайная цель (забирается 1 раз)

local roundCoins      = 0
local visited         = {}      -- монета -> время посещения
local currentTarget   = nil
local lastProgress    = os.clock()  -- время последнего "полезного" действия
local graceUntil      = 0           -- до этого времени авто-ресет не работает
local fallSince       = nil         -- когда персонаж оказался ниже RESET_Y

-- Кэш частей персонажа для noclip
local parts        = {}
local savedCollide = {}

-- Кэш валюты
local coinCache    = {}
local coinNextScan = 0
local currencyCount = 0     -- сколько объектов валюты видно (для статуса)
local currencyName  = nil   -- авто-определённое имя валюты
local nearestCoinDist = 0   -- v6.1.3: дистанция до ближайшей видимой валюты
local loggedCurrency = nil  -- способ распознавания, уже выведенный в лог
local lastDump      = 0
local targetLogged  = false -- первая цель раунда уже выведена в лог
local farLoggedAt   = 0     -- v6.1.3: троттлинг строки «лечу к ближайшей»
local farHoldLoggedAt = 0   -- v6.1.4: троттлинг строки «жду карту»
local farHoldDist     = 0   -- v6.1.4: дистанция, из-за которой стоим (0 = не ждём)
local farHoldSince    = nil -- v6.1.4: с какого времени ждём
local farHoldWarned   = false -- v6.1.5: подробная диагностика «нас не переносят» уже выведена
-- v6.1.5: РЕЖИМ «ЖДЁМ КАРТУ». Пока он включён, бот НЕ ТРОГАЕТ персонажа вообще:
-- noclip выключен, PlatformStand выключен, CFrame не пишется. В 6.1.4 стояние
-- держалось записью CFrame (holdStill), и эти же записи отменяли перенос на
-- карту, который делает игра: персонаж оставался в лобби и «замирал».
local lobbyHold       = false
local currencyMode  = nil   -- чем валюта найдена: CoinID / теги / имя / вручную

-- v5.9: счёт по факту. Либо событие сервера CoinCollected (самый точный
-- вариант), либо фактическое исчезновение валюты после подлёта.
local coinEventBound = false  -- найден RemoteEvent валюты
local bagCount       = 0      -- сколько валюты сервер реально выдал
local bagBaseline    = nil    -- предыдущее значение счётчика сервера
local bagCapacity    = nil    -- вместимость мешка (если сервер сообщил)
local bagCapSource   = nil    -- v6.1.4: откуда вместимость: "event" | "gui"
local bagGuiNext     = 0      -- v6.1.4: когда снова читать мешок из GUI
local bagGuiCapSeen  = nil    -- v6.1.4: последняя вместимость из GUI (для проверки)
local bagGuiCapHits  = 0      -- v6.1.4: сколько раз подряд она подтвердилась
local missStreak     = 0      -- сколько целей подряд не подобралось

-- Диагностика движения
local idleReason = "остановлен"   -- почему фарм сейчас не двигает персонажа
local dbgText    = ""             -- что показывать второй строкой статуса
local moveMode   = "cframe"       -- "cframe" | "velocity" (fallback)
local lastDbgPos = nil
local dbgNextAt  = 0              -- троттлинг обновления строки статуса

-- v6.1: ЛОГ В ОКНЕ вместо F9. Панель создаётся позже (в GUI), а писать в лог
-- нужно уже из поиска валюты, поэтому объявляем всё здесь.
-- v6.1.2: метка сборки. Печатается в лог окна при запуске — по ней видно,
-- что в исполнителе крутится ИМЕННО эта сборка, а не старая копия файла.
local BUILD = "6.1.6"

local LOG_MAX    = 6
local logLines   = {}
local logRepaint = function() end   -- заменяется, когда панель лога создана

local function addLog(msg)
    local line = ("[%s] %s"):format(os.date("%H:%M:%S"), tostring(msg))
    table.insert(logLines, 1, line)
    while #logLines > LOG_MAX do table.remove(logLines) end
    logRepaint(table.concat(logLines, "\n"))
    print("[Cosmic] " .. line)
end

-- Объявлены заранее: на них ссылаются обработчики GUI
local farmStart, farmStop, updateStatus

--========================================================
-- BASIC HELPERS
--========================================================
local function make(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Пол под точкой (как в v5.2): бот едет ПО ЗЕМЛЕ, а не проваливается в неё.
-- Луч пускаем чуть выше корня (иначе можно зацепить потолок) и исключаем
-- самого персонажа.
local function groundY(pos)
    local char = LocalPlayer.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = char and { char } or {}

    local origin = Vector3.new(pos.X, pos.Y + 2, pos.Z)
    local hit = workspace:Raycast(origin, Vector3.new(0, -200, 0), params)
    return hit and hit.Position.Y or pos.Y
end

-- Высота корня над полом, пока персонаж стоит.
-- v6.0: берём её из Humanoid.HipHeight (R6/R15 ≈ 3), а НЕ замером под
-- персонажем: замер зависел от того, что сейчас под ним (стол, монета, край
-- платформы), поэтому корень "прыгал" на ~3 студа.
local function computeHipOffset()
    local root = getRoot()
    local hum  = getHumanoid()
    if root and hum then
        local ok, h = pcall(function() return hum.HipHeight + root.Size.Y * 0.5 end)
        if ok and type(h) == "number" and h >= 1 and h <= 6 then return h end
    end
    if not root then return 3 end
    local offset = root.Position.Y - groundY(root.Position)
    if offset < 1 or offset > 6 then offset = 3 end
    return offset
end

-- v6.0: пол ПОД САМОЙ ВАЛЮТОЙ (а не под персонажем).
-- Луч стартует чуть НИЖЕ центра валюты, чтобы не зацепить её саму; сама
-- валюта и персонаж исключены из проверки. nil = пола под ней нет.
local function coinFloorY(coin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    local char = LocalPlayer.Character
    if char then exclude[#exclude + 1] = char end
    exclude[#exclude + 1] = coin
    params.FilterDescendantsInstances = exclude

    local half = 0
    pcall(function() half = coin.Size.Y * 0.5 end)
    local origin = coin.Position - Vector3.new(0, half + 0.1, 0)
    local hit = workspace:Raycast(origin, Vector3.new(0, -300, 0), params)
    return hit and hit.Position.Y or nil
end

-- v6.0: ТОЧКА, К КОТОРОЙ ВЕДЁМ КОРЕНЬ (одна на всю цель, не меняется).
--   валюта на полу   -> (X, пол + высота корня, Z): едем "по земле";
--   валюта в воздухе -> (X, валюта.Y + PICKUP_LIFT, Z): летим прямо к ней.
-- Высота НЕ зависит от того, что под персонажем, поэтому по пути она не
-- меняется: бот больше не подпрыгивает на столах/лавках и не приседает
-- после подобранной монеты.
local function flightGoal(coin, hipOffset)
    local gy = coinFloorY(coin)
    if gy and (coin.Position.Y - gy) <= CONFIG.FLOOR_TOLERANCE then
        return Vector3.new(coin.Position.X, gy + (hipOffset or 3), coin.Position.Z)
    end
    return Vector3.new(coin.Position.X, coin.Position.Y + CONFIG.PICKUP_LIFT, coin.Position.Z)
end

-- v6.1.6: СЛАЙДЕР = РЕАЛЬНАЯ СКОРОСТЬ. Раньше значение слайдера было МНОЖИТЕЛЕМ
-- к «умной» базе (SMART_BASE = 5 * 0.6..3), и всё, что выше 10, упиралось в
-- SPEED_CAP = 30: слайдеры 20 и 50 давали ровно одно и то же, а видимая разница
-- была только на 1..7. Теперь шкала линейная: 1 -> SPEED_LO (10 ст/с),
-- 50 -> SPEED_HI (80 ст/с), то есть +1.43 ст/с на каждый шаг слайдера.
local function baseSpeed()
    local v = math.clamp(speedValue, CONFIG.SPEED_MIN, CONFIG.SPEED_MAX)
    local t = (v - CONFIG.SPEED_MIN) / math.max(CONFIG.SPEED_MAX - CONFIG.SPEED_MIN, 1)
    return CONFIG.SPEED_LO + t * (CONFIG.SPEED_HI - CONFIG.SPEED_LO)
end

local function getEffectiveSpeed(dist)
    local base = baseSpeed()
    if not flags.smartSpeed then
        -- Smart OFF: слайдер и есть скорость (ст/с), без ускорения у цели.
        return math.clamp(base, 0, CONFIG.SPEED_CAP)
    end

    -- Smart ON: у самой цели +до SMART_BOOST (1.5x), дальше SMART_REF_DIST —
    -- ровно базовая скорость. Множитель больше НЕ зависит от слайдера, поэтому
    -- он не «съедает» разницу между соседними значениями.
    local d      = math.max(dist, 1)
    local factor = math.clamp(CONFIG.SMART_REF_DIST / d, 1, CONFIG.SMART_BOOST)
    return math.clamp(base * factor, CONFIG.SPEED_LO, CONFIG.SPEED_CAP)
end

--========================================================
-- GUI
--========================================================
local SIZE_PASS = UDim2.new(0, 320, 0, 220)
local SIZE_HUB  = UDim2.new(0, 300, 0, 470)

local old = PlayerGui:FindFirstChild("CosmicAutofarm")
if old then old:Destroy() end

local gui = make("ScreenGui", {
    Name = "CosmicAutofarm", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})
gui.Enabled = false -- скрываем старое окно Cosmic; управление через WindUI

local main = make("Frame", {
    Name = "Main", Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true,
    Active = true, Visible = false, Parent = gui,
}, {
    make("UICorner", { CornerRadius = UDim.new(0, 14) }),
    make("UIStroke", { Color = COLORS.accent, Thickness = 1.5 }),
    make("UIGradient", { Color = ColorSequence.new(COLORS.bgTop, COLORS.bgBot), Rotation = 60 }),
})

-- ---------- Экран пароля ----------
local passPage = make("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = main,
})

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 24), BackgroundTransparency = 1,
    Text = "COSMIC MM2 FARM", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = COLORS.text,
    Parent = passPage,
})

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 52), BackgroundTransparency = 1,
    Text = "v6.1", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = COLORS.dim, Parent = passPage,
})

local passInput = make("TextBox", {
    Size = UDim2.new(1, -48, 0, 36), Position = UDim2.new(0, 24, 0, 84), BackgroundColor3 = COLORS.gray,
    Text = "", PlaceholderText = "password", PlaceholderColor3 = COLORS.dim, Font = Enum.Font.Gotham,
    TextSize = 15, TextColor3 = COLORS.text, ClearTextOnFocus = false, Parent = passPage,
}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })

local passError = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 124), BackgroundTransparency = 1,
    Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = COLORS.red, Parent = passPage,
})

local unlockBtn = make("TextButton", {
    Size = UDim2.new(1, -48, 0, 36), Position = UDim2.new(0, 24, 0, 146), BackgroundColor3 = COLORS.accent,
    Text = "Unlock", Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = COLORS.text,
    Parent = passPage,
}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
-- ---------- Основной экран ----------
local hubPage = make("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = main,
})

-- Шапка: за неё таскаем окно
local header = make("Frame", {
    Size = UDim2.new(1, -16, 0, 24), Position = UDim2.new(0, 8, 0, 6), BackgroundTransparency = 1,
    Parent = hubPage,
})

make("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "COSMIC MM2 FARM   ·   v6.1",
    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = COLORS.text,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
})

local tabBar = make("Frame", {
    Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 32), BackgroundTransparency = 1,
    Parent = hubPage,
})

local function makeTab(text, posX)
    return make("TextButton", {
        Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(posX, 0, 0, 0),
        BackgroundColor3 = COLORS.gray, Text = text, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextColor3 = COLORS.dim, AutoButtonColor = false, Parent = tabBar,
    }, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
end

local farmTab     = makeTab("Farm", 0)
local settingsTab = makeTab("Settings", 0.5)

local function makePage()
    return make("Frame", {
        Size = UDim2.new(1, -16, 1, -76), Position = UDim2.new(0, 8, 0, 68), BackgroundTransparency = 1,
        Parent = hubPage,
    })
end

local farmPage     = makePage()
local settingsPage = makePage()
settingsPage.Visible = false

-- ---------- Универсальный тумблер ----------
local function createToggle(parent, key, label, y)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, y), BackgroundColor3 = COLORS.gray,
        Text = label, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = COLORS.text,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, Parent = parent,
    }, {
        make("UICorner", { CornerRadius = UDim.new(0, 8) }),
        make("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
    })

    local function paint()
        local on = flags[key]
        btn.BackgroundColor3 = on and COLORS.accent or COLORS.gray
        btn.Text = (on and "●  " or "○  ") .. label
    end

    btn.MouseButton1Click:Connect(function()
        flags[key] = not flags[key]
        paint()
        if key == "fly" and flags.fly and farmRunning then
            farmStop()   -- полёт и фарм одновременно конфликтуют
        end
    end)

    paint()
    return btn
end

-- ---------- Вкладка Farm ----------
local runBtn = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = COLORS.accent, Text = "Run farm",
    Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = COLORS.text, Parent = farmPage,
}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })

local statusInfo = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 44), BackgroundTransparency = 1,
    Text = "idle | +0 | вал:0\nцель: —", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = COLORS.dim,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Parent = farmPage,
})

createToggle(farmPage, "autoReset",   "Auto Reset",   74)
createToggle(farmPage, "autoStart",   "Auto Start",   112)

-- v6.1: «Стоп в лобби» удалён (кнопка, флаг и вся функция). Место занял ЛОГ:
-- F9 во многих исполнителях ничего не открывает, поэтому всё важное пишется
-- прямо в окно (и дублируется в консоль, если она есть).
make("TextLabel", {
    Size = UDim2.new(0, 40, 0, 14), Position = UDim2.new(0, 0, 0, 152), BackgroundTransparency = 1,
    Text = "Лог:", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = COLORS.dim,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = farmPage,
})

local logBox = make("Frame", {
    Size = UDim2.new(1, 0, 0, 96), Position = UDim2.new(0, 0, 0, 168), BackgroundColor3 = COLORS.gray,
    BackgroundTransparency = 0.35, Parent = farmPage,
}, {
    make("UICorner", { CornerRadius = UDim.new(0, 6) }),
    make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
                        PaddingTop = UDim.new(0, 4) }),
    make("TextLabel", {
        Name = "Body", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "(пока пусто)", Font = Enum.Font.Code, TextSize = 9, TextColor3 = COLORS.dim,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }),
})

logRepaint = function(text)
    local body = logBox:FindFirstChild("Body")
    if body then body.Text = (text ~= "" and text) or "(пока пусто)" end
end

local copyBtn = make("TextButton", {
    Size = UDim2.new(0, 52, 0, 14), Position = UDim2.new(1, -52, 0, 152), BackgroundColor3 = COLORS.gray,
    Text = "Copy", Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = COLORS.text,
    AutoButtonColor = false, Parent = farmPage,
}, { make("UICorner", { CornerRadius = UDim.new(0, 5) }) })

copyBtn.MouseButton1Click:Connect(function()
    local text = table.concat(logLines, "\n")
    local ok = pcall(function() setclipboard(text) end)
    copyBtn.Text = ok and "OK" or "нет"
    task.delay(1, function() copyBtn.Text = "Copy" end)
end)

-- v6.1: памятка — коротко, без F9.
make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 124), Position = UDim2.new(0, 0, 0, 268), BackgroundTransparency = 1,
    Text = "Валюта: CoinID / теги с «coin» / имя с «coin» (Coin, Coin_Server, CoinVisual). "
        .. "Декор (ручки, двери, вёдра) отсекается. Не нашлась — смотри лог.\n"
        .. "Счёт по факту: часть исчезла или пришло CoinCollected; мешок полон — ресет.\n"
        .. "Полёт по прямой (3D-вектор): высота от пола ПОД монетой, цель не меняется.\n"
        .. "Лобби: монета дальше 1500 ст и в раунде 0 собрано — стоим и ждём карту.\n"
        .. "Толпа: монета с ботами рядом не запрещена, только дороже; раз в 30-45 c — уход.",
    TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = COLORS.dim, Parent = farmPage,
})

-- ---------- Вкладка Settings ----------
createToggle(settingsPage, "antiAFK",    "Anti AFK",              0)
createToggle(settingsPage, "antiFling",  "Anti-Fling",            38)
-- v5.9: тумблера Noclip больше НЕТ — он включается сам (см. noclipWanted()).
createToggle(settingsPage, "fly",        "Fly (WASD + Space/Shift)", 76)
createToggle(settingsPage, "smartSpeed", "Smart Speed",           114)
createToggle(settingsPage, "avoidCrowd", "Избегать толпы",        152)

-- v6.1: «Избегать толпы» — монета, у которой висят другие боты, не запрещается,
-- а просто получает штраф при выборе; раз в 30..45 c бот уходит к случайной.
local sliderLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 196), BackgroundTransparency = 1,
    Text = "Speed: 5 (16 ст/с)", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = COLORS.dim,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = settingsPage,
})

local sliderBG = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 222), BackgroundColor3 = COLORS.gray,
    Text = "", AutoButtonColor = false, Parent = settingsPage,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })

local sliderKnob = make("Frame", {
    Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = COLORS.accent, Parent = sliderBG,
}, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })

local speedInput = make("TextBox", {
    Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 238), BackgroundColor3 = COLORS.gray,
    Text = "5", PlaceholderText = ("Speed %d-%d"):format(CONFIG.SPEED_MIN, CONFIG.SPEED_MAX),
    Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = COLORS.text, ClearTextOnFocus = false,
    Parent = settingsPage,
}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 274), BackgroundTransparency = 1,
    Text = "Speed 1-50 = 10..80 ст/с (шаг ≈1.4).\nSmart Speed: у цели +до 50%.",
    TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = COLORS.dim, Parent = settingsPage,
})

--========================================================
-- GUI LOGIC
--========================================================
function updateStatus()
    local mode = farmRunning and "running" or "остановлен"

    local line2 = idleReason
    if currentTarget and dbgText ~= "" then line2 = dbgText end

    -- v6.0: точки спавна больше нет, в статусе только счёт по факту (мешок)
    local extra = ""
    -- v6.1.4: показываем мешок и без события, если вместимость известна из GUI
    if coinEventBound or bagCapacity then
        extra = extra .. (" | мешок:%d%s"):format(bagCount,
            bagCapacity and ("/" .. tostring(bagCapacity)) or "")
    end
    -- v6.1.3: дистанция до ближайшей ВИДИМОЙ валюты. Сразу видно, что не так:
    -- «вал:36 ближ:812» = бот далеко от карты (летит), «вал:36 ближ:20» при
    -- «валюта не найдена» = все цели в чёрном списке, «вал:0» = карта не загружена.
    if farmRunning and currencyCount > 0 then
        extra = extra .. (" | ближ:%.0f"):format(nearestCoinDist)
    end

    statusInfo.Text = ("%s | +%d | вал:%d%s\n%s"):format(mode, roundCoins, currencyCount, extra, line2)
end

local function showTab(name)
    local isFarm = (name == "farm")
    farmPage.Visible     = isFarm
    settingsPage.Visible = not isFarm
    farmTab.BackgroundColor3     = isFarm and COLORS.accent or COLORS.gray
    farmTab.TextColor3           = isFarm and COLORS.text or COLORS.dim
    settingsTab.BackgroundColor3 = isFarm and COLORS.gray or COLORS.accent
    settingsTab.TextColor3       = isFarm and COLORS.dim or COLORS.text
end

farmTab.MouseButton1Click:Connect(function() showTab("farm") end)
settingsTab.MouseButton1Click:Connect(function() showTab("settings") end)

-- ---------- Пароль ----------
local function tryUnlock()
    if passInput.Text == CONFIG.PASSWORD then
        unlocked = true
        passError.Text = ""
        passPage.Visible = false
        hubPage.Visible  = true
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Size = SIZE_HUB,
        }):Play()
        if flags.autoStart then farmStart() end
    else
        passInput.Text = ""
        passError.Text = "Wrong password"
        task.delay(2, function()
            if passError.Text == "Wrong password" then passError.Text = "" end
        end)
    end
end

passInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then tryUnlock() end
end)
unlockBtn.MouseButton1Click:Connect(tryUnlock)

-- ---------- Слайдер скорости ----------
local function updateSpeedVisuals()
    local percent = (speedValue - CONFIG.SPEED_MIN) / (CONFIG.SPEED_MAX - CONFIG.SPEED_MIN)
    percent = math.clamp(percent, 0, 1)
    sliderKnob.Position = UDim2.new(percent, -8, 0.5, -8)
    sliderLabel.Text = ("Speed: %d (%d ст/с)"):format(speedValue, math.floor(baseSpeed() + 0.5))
    if not speedInput:IsFocused() then
        speedInput.Text = tostring(speedValue)
    end
end

local sliderDragging = false

local function inputX(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        return input.Position.X
    end
    return UserInputService:GetMouseLocation().X
end

local function setSpeedFromX(x)
    local ap   = sliderBG.AbsolutePosition
    local size = sliderBG.AbsoluteSize
    if size.X <= 0 then return end
    local percent = math.clamp((x - ap.X) / size.X, 0, 1)
    speedValue = math.floor(CONFIG.SPEED_MIN + percent * (CONFIG.SPEED_MAX - CONFIG.SPEED_MIN) + 0.5)
    updateSpeedVisuals()
end

sliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        setSpeedFromX(inputX(input))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sliderDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        setSpeedFromX(inputX(input))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

speedInput.FocusLost:Connect(function()
    local n = tonumber(speedInput.Text)
    if n then
        speedValue = math.clamp(math.floor(n), CONFIG.SPEED_MIN, CONFIG.SPEED_MAX)
    end
    updateSpeedVisuals()
end)

-- ---------- Перетаскивание окна за шапку ----------
local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    dragging  = true
    dragStart = input.Position
    startPos  = main.Position

    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ---------- Ctrl: скрыть/показать меню ----------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        main.Visible = not main.Visible
        sliderDragging = false
    end
end)

--========================================================
-- NOCLIP / восстановление гуманоида
--========================================================
local function refreshParts()
    parts = {}
    -- savedCollide НЕ чистим: иначе части, у которых мы уже выключили
    -- коллизию, никогда не получат её обратно.
    local char = LocalPlayer.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            parts[#parts + 1] = d
        end
    end
end

-- v5.9: NOCLIP — НЕ НАСТРОЙКА И НЕ ТУМБЛЕР. Он нужен ровно тогда, когда
-- скрипт ведёт персонажа (фарм идёт / включён Fly / летим к цели). Когда всё
-- стоит, коллизии возвращаются — иначе персонаж проседал бы сквозь пол в лобби.
local function noclipWanted()
    -- v6.1.5: в режиме «ждём карту» noclip ВЫКЛЮЧЕН. Иначе персонаж висит без
    -- коллизий и его приходится удерживать записью CFrame — а эти записи отменяют
    -- перенос на карту, который делает игра (бот «замирал» в лобби).
    if lobbyHold then return false end
    return farmRunning or flags.fly or movingToCoin
end

-- Единая точка: держит noclip, гасит "парящий" noclip и возвращает
-- AutoRotate/PlatformStand, когда они не заняты фармом/полётом.
local function maintain()
    local want = noclipWanted()

    if want then
        if #parts == 0 then refreshParts() end
        for i = 1, #parts do
            local p = parts[i]
            if p.Parent then
                if savedCollide[p] == nil then savedCollide[p] = p.CanCollide end
                if p.CanCollide then p.CanCollide = false end
            end
        end
    elseif next(savedCollide) ~= nil then
        for p, v in pairs(savedCollide) do
            if p.Parent then p.CanCollide = v end
        end
        savedCollide = {}
    end

    -- Фарм идёт, но сейчас не летим (ищем цель / пауза): гасим скорость,
    -- иначе с выключенной коллизией персонаж медленно проседает.
    if want and not flags.fly and not movingToCoin then
        local root = getRoot()
        if root then
            if root.AssemblyLinearVelocity.Magnitude > 0.01 then
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end

    -- v6.1: ПОКА ВЕДЁМ ПЕРСОНАЖА — PlatformStand = true.
    -- Потолок бот проходил и раньше (CanCollide = false у всех частей), а ПОЛ
    -- его "держал" не коллизией, а самим Humanoid: у гуманоида есть свой
    -- "пол" под ногами, и он подпирал корень на HipHeight. Из-за этого бот не
    -- опускался ниже пола и "отталкивался" от него — со стороны это и было
    -- похоже на объезд препятствий. С PlatformStand гуманоид перестаёт
    -- подпирать, поэтому пол и потолок проходятся одинаково.
    local hum = getHumanoid()
    if hum then
        -- v6.1.5: PlatformStand нужен ТОЛЬКО когда мы сами ведём персонажа.
        -- В режиме «ждём карту» гуманоид обычный: иначе игра не может двигать
        -- персонажа своими средствами (Humanoid:MoveTo при PlatformStand не работает).
        local guiding = (movingToCoin or flags.fly) and not lobbyHold
        if guiding then
            if not hum.PlatformStand then hum.PlatformStand = true end
            if hum.AutoRotate then hum.AutoRotate = false end
        else
            if hum.PlatformStand then hum.PlatformStand = false end
            if not hum.AutoRotate then hum.AutoRotate = true end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        local ok, err = pcall(maintain)
        if not ok then warn("[Cosmic] maintain error:", err) end
    end
end)

-- КАК В v5.3: пока фарм ведёт персонажа, коллизии выключаются КАЖДЫЙ
-- физический шаг. С таймером 0.2 с физика успевает вернуть CanCollide,
-- и персонаж застревает в стене/полу — со стороны это выглядит как
-- "бот не летит". Здесь же ноклип восстанавливается мгновенно.
RunService.Stepped:Connect(function()
    if not noclipWanted() then return end

    local char = LocalPlayer.Character
    if not char then return end

    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.CanCollide then
                if savedCollide[p] == nil then savedCollide[p] = true end
                p.CanCollide = false
            end
        end
    end
end)

--========================================================
-- ANTI-FLING
--========================================================
RunService.Heartbeat:Connect(function()
    if not flags.antiFling then return end
    if flags.fly or movingToCoin then return end

    local root = getRoot()
    if not root then return end

    local v = root.AssemblyLinearVelocity
    if v.Magnitude > CONFIG.FLING_MAX_VEL then
        root.AssemblyLinearVelocity = v.Unit * CONFIG.FLING_MAX_VEL
    end

    local av = root.AssemblyAngularVelocity
    if av.Magnitude > CONFIG.FLING_MAX_ANG then
        root.AssemblyAngularVelocity = av.Unit * CONFIG.FLING_MAX_ANG
    end
end)

--========================================================
-- ANTI-AFK
--========================================================
LocalPlayer.Idled:Connect(function()
    if not flags.antiAFK then return end
    if VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end)

--========================================================
-- FLY: WASD + Space (вверх) / Shift (вниз)
--========================================================
local flyKeys = {}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        flyKeys[input.KeyCode] = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        flyKeys[input.KeyCode] = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not flags.fly then return end

    local root = getRoot()
    local hum  = getHumanoid()
    if not root or not hum then return end

    hum.AutoRotate = false
    if not hum.PlatformStand then hum.PlatformStand = true end

    local cam  = workspace.CurrentCamera
    local move = Vector3.new()

    if flyKeys[Enum.KeyCode.W] then move += cam.CFrame.LookVector end
    if flyKeys[Enum.KeyCode.S] then move -= cam.CFrame.LookVector end
    if flyKeys[Enum.KeyCode.D] then move += cam.CFrame.RightVector end
    if flyKeys[Enum.KeyCode.A] then move -= cam.CFrame.RightVector end
    if flyKeys[Enum.KeyCode.Space] then move += Vector3.new(0, 1, 0) end
    if flyKeys[Enum.KeyCode.LeftShift] or flyKeys[Enum.KeyCode.RightShift] then
        move -= Vector3.new(0, 1, 0)
    end

    local look = cam.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.001 then
        flat = Vector3.new(0, 0, -1)
    end

    local pos = root.Position
    if move.Magnitude > 0 then
        pos = pos + move.Unit * (CONFIG.FLY_SPEED * math.clamp(dt, 0, 0.1))
    end

    pcall(function()
        root.CFrame = CFrame.lookAt(pos, pos + flat.Unit)
        root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
end)
--========================================================
-- CHARACTER LIFECYCLE
--========================================================
-- v6.0: АВТО-РЕСЕТ СНОВА РАБОТАЕТ.
-- В v5.8/v5.9 при ALLOW_SELF_RESET = false он вместо ресета пытался перенести
-- персонажа на точку спавна, а без точки спавна не делал НИЧЕГО (писал
-- подсказку в F9) — поэтому тумблер Auto Reset выглядел мёртвым.
-- Теперь, как в v5.7: персонаж перерождается (Health = 0 -> Dead), счётчики и
-- цель сбрасываются, выдаётся льгота SPAWN_GRACE. Точек спавна больше нет,
-- так что это единственный и правильный путь.
local function respawnNow()
    currentTarget = nil
    movingToCoin  = false
    fallSince     = nil
    lastProgress  = os.clock()
    graceUntil    = os.clock() + CONFIG.SPAWN_GRACE

    local hum  = getHumanoid()
    local char = LocalPlayer.Character
    if not hum then return end
    if hum.Health <= 0 then return end   -- уже мёртв: ждём респавн, не спамим

    print("[Cosmic] авто-ресет: перерождаю персонажа")
    pcall(function() hum.Health = 0 end)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
    if char then
        pcall(function() char:BreakJoints() end)
    end

    -- Fallback: если сервер не принял смерть, ставим на SpawnLocation карты
    -- (если он есть). Точка спавна из CONFIG больше не нужна.
    task.delay(1, function()
        local h = getHumanoid()
        if h and h.Health > 0 then
            local root  = getRoot()
            local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
            if root and spawn then
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                end)
            end
        end
    end)
end

local function onCharacterSpawn(char)
    -- v6.1: новый персонаж = новый раунд. Раньше это же делал beginRound() по
    -- надписи Intermission; теперь стоп-в-лобби и детект Intermission удалены,
    -- и точкой отсчёта раунда стал респавн персонажа.
    parts          = {}
    savedCollide   = {}
    currentTarget  = nil
    movingToCoin   = false
    visited        = {}
    roundCoins     = 0
    failedUntil    = {}   -- в новом раунде старые цели уже неактуальны
    lastProgress   = os.clock()
    graceUntil     = math.max(graceUntil, os.clock() + CONFIG.ROUND_GRACE)
    fallSince      = nil
    wanderTarget   = nil
    wanderNextAt   = os.clock() + CONFIG.CROWD_WANDER_MIN
    currencyName   = nil  -- валюта на новой карте может называться иначе
    currencyMode   = nil
    loggedCurrency = nil
    targetLogged   = false
    farHoldSince   = nil   -- v6.1.4: новое ожидание «мы не на карте» с нуля
    farHoldWarned  = false -- v6.1.5
    lobbyHold      = false -- v6.1.5: в новом раунде снова трогаем персонажа смело
    farHoldLoggedAt = 0
    coinNextScan   = 0    -- сразу пересканируем карту
    missStreak     = 0
    moveMode       = "cframe"
    dbgText        = ""
    idleReason     = "новый раунд: ищу валюту"

    if flags.autoStart and unlocked then
        farmStart()      -- заодно синхронизирует текст кнопки Run/Stop
    end
    addLog("новый персонаж — раунд начинается")
    updateStatus()

    task.spawn(function()
        char:WaitForChild("HumanoidRootPart", 10)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end)
        end
        if char == LocalPlayer.Character then
            refreshParts()
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterSpawn)

--========================================================
-- v6.1: ДЕТЕКЦИИ INTERMISSION БОЛЬШЕ НЕТ (вместе со стопом в лобби).
-- Она искала в GUI надпись "intermission" и на 45 c останавливала фарм; при
-- постоянной надписи в лобби это выглядело как "бот стоит". Новый раунд
-- теперь определяется по респавну персонажа (onCharacterSpawn).
--========================================================

--========================================================
-- ВАЛЮТА: отметки посещений, конкуренты, кэш объектов
--========================================================
local function markVisited(coin)
    if coin then visited[coin] = os.clock() end
end

-- v5.8: цель, до которой не смогли добраться, не берём FAIL_BLACKLIST секунд.
-- Раньше такая цель возвращалась через VISIT_COOLDOWN = 0.6 c, и бот летал
-- к ней по кругу — со стороны это и было «летает по респе».
local function markFailed(coin)
    if coin and CONFIG.FAIL_BLACKLIST > 0 then
        failedUntil[coin] = os.clock() + CONFIG.FAIL_BLACKLIST
    end
end

local function isRecentlyVisited(coin)
    local f = failedUntil[coin]
    if f then
        if os.clock() < f then return true end
        failedUntil[coin] = nil
    end
    local t = visited[coin]
    if not t then return false end
    if os.clock() - t > CONFIG.VISIT_COOLDOWN then
        visited[coin] = nil
        return false
    end
    return true
end

local function otherPlayerPositions()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                list[#list + 1] = hrp.Position
            end
        end
    end
    return list
end

-- v6.1: сколько иных игроков "висит" у точки
local function crowdAt(pos, others)
    local n = 0
    for i = 1, #others do
        if (others[i] - pos).Magnitude < CONFIG.CONTEST_RADIUS then n += 1 end
    end
    return n
end

-- v6.1: ШТРАФ к дистанции, а НЕ запрет цели.
-- Раньше монета с игроком рядом ВЫБРАСЫВАЛАСЬ из выбора, и на полном сервере
-- ботов не оставалось ни одной цели: бот стоял на спавне с надписью "валюта
-- не найдена", хотя счётчик валюты на карте был не ноль. Теперь такая монета
-- просто "дороже": +CROWD_WEIGHT студов за каждого игрока рядом.
local function crowdPenalty(pos, others)
    if not flags.avoidCrowd then return 0 end
    local pen = 0
    for i = 1, #others do
        local d = (others[i] - pos).Magnitude
        if d < CONFIG.CONTEST_RADIUS then
            pen += (CONFIG.CONTEST_RADIUS - d) * CONFIG.CROWD_WEIGHT
        end
    end
    return pen
end

-- v6.1: другой игрок УЖЕ на монете и заметно ближе нас -> не летим "хвостом".
-- Порог жёсткий (4 студа и отрыв 10 студов), чтобы не бросать цель из-за
-- того, что кто-то просто летит рядом: раньше из-за этого бот вилял.
local function isTakenByOther(coinPos, myPos, others)
    if not flags.avoidCrowd then return false end
    local myDist = (myPos - coinPos).Magnitude
    for i = 1, #others do
        local d = (others[i] - coinPos).Magnitude
        if d < 4 and d + 10 < myDist then return true end
    end
    return false
end

--========================================================
-- v6.1: ВАЛЮТА — УНИВЕРСАЛЬНО, ПО СЛОВУ "coin" + ТОЧНЫЕ ПРИЗНАКИ
--========================================================
-- Почему так: в MM2 подбираемая часть называется Coin_Server (невидимая, с
-- TouchTransmitter), её видимый ребёнок — CoinVisual, на сервере она помечена
-- атрибутом CoinID. Раньше бот летал на декор, потому что валюта искалась по
-- КЛЮЧЕВЫМ СЛОВАМ ("candy" ловило CandyBucket) и авто-определением "много
-- одинаковых мелких частей" — оно и выбирало oct_handle (ручки дверей).
-- Теперь авто-определения НЕТ, а слова декора (CURRENCY_DENY) отсекаются явно.

local function isCharacterPart(obj)
    local char = LocalPlayer.Character
    return char ~= nil and obj:IsDescendantOf(char)
end

-- Атрибут валюты у части (nil, если атрибута нет)
local function coinAttrOf(p)
    if CONFIG.CURRENCY_ATTR == "" then return nil end
    local ok, v = pcall(p.GetAttribute, p, CONFIG.CURRENCY_ATTR)
    if not ok then return nil end
    return v
end

-- Точный признак валюты — атрибут CoinID. Значение можно ограничить через
-- CONFIG.CURRENCY_ID ("Candy"), по умолчанию принимается любое.
local function hasCoinAttr(p)
    local id = coinAttrOf(p)
    if id == nil then return false end
    if CONFIG.CURRENCY_ID ~= nil and id ~= CONFIG.CURRENCY_ID then return false end
    return true
end

-- Игра уже забрала эту валюту? (часть исчезла или помечена Collected)
local function coinGone(p)
    if not p or not p.Parent then return true end
    local ok, v = pcall(p.GetAttribute, p, "Collected")
    return ok and v == true
end

-- Подбираемая часть: TouchTransmitter / ClickDetector / ProximityPrompt
-- (у себя или у родителя-хитбокса).
local function isInteractivePart(p)
    if p:FindFirstChildWhichIsA("TouchTransmitter") then return true end
    if p:FindFirstChildWhichIsA("ClickDetector") then return true end
    if p:FindFirstChildWhichIsA("ProximityPrompt") then return true end

    local parent = p.Parent
    if parent and parent:IsA("BasePart")
        and parent:FindFirstChildWhichIsA("TouchTransmitter") then
        return true
    end
    return false
end

-- Имена в игре повторяются -> результат проверки кэшируем
local nameCache = {}
local denyCache = {}

-- v6.1: декор? (handle, door, bucket, lamp...). Проверяем ПОДСТРОКОЙ, потому
-- что имена склеены: "oct_handle", "CandyBucket_01", "DoorHandle".
local function nameIsDenied(name)
    if not name or name == "" then return false end
    local cached = denyCache[name]
    if cached ~= nil then return cached end

    local low = string.lower(name)
    local denied = false
    for i = 1, #CONFIG.CURRENCY_DENY do
        if string.find(low, CONFIG.CURRENCY_DENY[i], 1, true) then
            denied = true
            break
        end
    end
    denyCache[name] = denied
    return denied
end

-- v6.1: в имени есть слово валюты ("coin")? Подходит Coin, Coin_Server,
-- CoinVisual, ServerCoinPart, CandyCoin: слово может стоять где угодно.
local function nameHasCurrencyWord(name)
    if not name or name == "" or CONFIG.CURRENCY_WORD == "" then return false end
    local cached = nameCache[name]
    if cached ~= nil then return cached end
    local isIt = string.find(string.lower(name), CONFIG.CURRENCY_WORD, 1, true) ~= nil
    nameCache[name] = isIt
    return isIt
end
-- Тег CollectionService со словом coin (ServerCoinPart, CoinVisual, Coin...)
local function hasCurrencyTag(p)
    local ok, tags = pcall(p.GetTags, p)
    if ok and tags then
        for i = 1, #tags do
            if string.find(string.lower(tags[i]), "coin", 1, true) then return true end
        end
    end
    for i = 1, #CONFIG.CURRENCY_TAGS do
        local ok2, has = pcall(function()
            return CollectionService:HasTag(p, CONFIG.CURRENCY_TAGS[i])
        end)
        if ok2 and has then return true end
    end
    return false
end

-- Подбираемый предмет обычно мелкий и не мешает ходить
local function looksCollectible(p)
    local s = p.Size
    local maxSide = math.max(s.X, s.Y, s.Z)
    if maxSide > CONFIG.CURRENCY_MAX_SIZE then return false end
    if p.CanCollide and maxSide > CONFIG.CURRENCY_BIG_SIZE then return false end
    return true
end

-- В список берём и НЕВИДИМЫЕ части: Coin_Server невидима (Transparency = 1),
-- зато у неё TouchTransmitter и атрибут CoinID.
local function collectParts()
    local all = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent and not isCharacterPart(obj) then
            if obj.Transparency < 1 or coinAttrOf(obj) ~= nil
                or obj:FindFirstChildWhichIsA("TouchTransmitter") ~= nil then
                all[#all + 1] = obj
            end
        end
    end
    return all
end

-- Ручные имена: CONFIG.CURRENCY_NAME (точное) и CONFIG.CURRENCY_EXTRA (список).
-- Нужны, если в игре валюта называется без "coin" (например "Candy").
-- ВАЖНО: объявлена ДО currencyKind — иначе внутри неё это была бы глобальная
-- переменная (nil) и детект падал бы с "attempt to call a nil value".
local function nameIsExtraCurrency(name)
    if not name then return false end
    if CONFIG.CURRENCY_NAME ~= nil and name == CONFIG.CURRENCY_NAME then return true end
    for i = 1, #CONFIG.CURRENCY_EXTRA do
        if name == CONFIG.CURRENCY_EXTRA[i] then return true end
    end
    return false
end

-- v6.1: ЧЕМ эта часть является валютой. nil = не валюта.
-- Возвращает вид признака (для лога), приоритет сверху вниз.
local function currencyKind(p)
    if not p or not p.Parent or isCharacterPart(p) then return nil end
    if nameIsDenied(p.Name) then return nil end      -- ручки/двери/вёдра — мимо
    if not looksCollectible(p) then return nil end   -- слишком крупная — декор

    -- 1) атрибут CoinID — самый точный признак, имя не важно
    if hasCoinAttr(p) then return "CoinID" end

    -- 2) ручные имена (если в игре валюта зовётся иначе)
    if nameIsExtraCurrency(p.Name) then return "вручную" end

    -- 3) тег CollectionService со словом coin
    if hasCurrencyTag(p) then return "теги" end

    -- 4) имя содержит "coin" (Coin, Coin_Server, CoinVisual...) — только если
    --    часть реально подбираемая, иначе это может быть вывеска/иконка
    if nameHasCurrencyWord(p.Name) and isInteractivePart(p) then return "имя" end

    -- 5) часть внутри модели/папки с "coin" в имени — тоже для подбираемых
    local parent = p.Parent
    if parent and (parent:IsA("Model") or parent:IsA("Folder"))
        and nameHasCurrencyWord(parent.Name) and isInteractivePart(p) then
        return "имя модели"
    end
    return nil
end

-- Если валюта не нашлась — показываем в логе, что вообще есть рядом
-- (заменяет "[Cosmic] валюта не найдена. Кандидаты..." из консоли).
local function dumpCandidates(all)
    local stats = {}
    for i = 1, #all do
        local p = all[i]
        local s = p.Size
        if math.max(s.X, s.Y, s.Z) <= CONFIG.CURRENCY_MAX_SIZE then
            local e = stats[p.Name]
            if e then
                e.n += 1
                if isInteractivePart(p) then e.inter = true end
            else
                stats[p.Name] = { n = 1, inter = isInteractivePart(p) }
            end
        end
    end

    local arr = {}
    for name, e in pairs(stats) do
        arr[#arr + 1] = { name = name, n = e.n, inter = e.inter }
    end
    table.sort(arr, function(a, b) return a.n > b.n end)

    local msg = "валюта не найдена, кандидаты:"
    for i = 1, math.min(#arr, 5) do
        msg = msg .. (" %s x%d%s"):format(arr[i].name, arr[i].n,
            arr[i].inter and "*" or "")
    end
    return msg
end

-- Полный обход workspace дорогой -> кэшируем список валюты.
local function refreshCoinCache()
    local all      = collectParts()
    local list     = {}
    local listKind = {}
    local kinds    = {}
    local seen     = {}

    for i = 1, #all do
        local p    = all[i]
        local kind = currencyKind(p)
        if kind and not seen[p] then
            seen[p] = true
            list[#list + 1]         = p
            listKind[#listKind + 1] = kind
        end
    end

    -- CoinVisual — ребёнок Coin_Server (та же монета): чтобы не было двух целей
    -- на одну конфету, оставляем только родителя.
    if #list > 1 then
        local keep, keepKind = {}, {}
        for i = 1, #list do
            if not seen[list[i].Parent] then
                keep[#keep + 1]         = list[i]
                keepKind[#keepKind + 1] = listKind[i]
            end
        end
        list, listKind = keep, keepKind
    end

    -- Режим для статуса/лога считаем ПОСЛЕ отсева детей: иначе в логе было
    -- «валюта: 1 шт. (CoinID x1 + теги x1)» — ребёнок CoinVisual попадал в счёт.
    for i = 1, #listKind do
        local k = listKind[i]
        kinds[k] = (kinds[k] or 0) + 1
    end

    -- Режим для статуса/лога: CoinID > вручную > теги > имя
    local order = { "CoinID", "вручную", "теги", "имя", "имя модели" }
    local modeParts, sigParts = {}, {}
    for i = 1, #order do
        local k = order[i]
        if kinds[k] then
            modeParts[#modeParts + 1] = ("%s x%d"):format(k, kinds[k])
            sigParts[#sigParts + 1]  = k
        end
    end
    local mode = #modeParts > 0 and table.concat(modeParts, " + ") or nil
    -- v6.1.3: подпись БЕЗ количества — по ней решаем, писать ли строку в лог.
    local sig  = #sigParts > 0 and table.concat(sigParts, " + ") or nil

    coinCache     = list
    currencyCount = #list
    currencyMode  = mode
    currencyName  = list[1] and list[1].Name or nil

    if #list > 0 then
        -- v6.1.3: строка в лог — только когда меняется СПОСОБ распознавания
        -- (CoinID / теги / имя), а не на каждое изменение количества. Раньше
        -- «валюта: 36 шт.», «валюта: 35 шт.», «валюта: 33 шт.» шли раз в
        -- секунду и вытесняли из окна (6 строк) метку сборки и ошибки.
        -- Количество видно в строке статуса («вал:36»).
        if loggedCurrency ~= sig then
            loggedCurrency = sig
            addLog(("валюта: %d шт. (%s) — %s"):format(#list, mode or "?",
                currencyName or "?"))
        end
    elseif os.clock() - lastDump > 10 then
        -- v6.1.3: карта выгружена (лобби/конец раунда) — сбрасываем подпись,
        -- чтобы в следующем раунде строка «валюта: ...» снова попала в лог.
        loggedCurrency = nil
        lastDump = os.clock()
        addLog(dumpCandidates(all))
    end

    coinNextScan = os.clock() + (#list > 0 and CONFIG.COIN_SCAN_INTERVAL
        or CONFIG.COIN_RESCAN_EMPTY)
end

-- Выбор цели: ближайшая ПО СТОИМОСТИ = 3D-дистанция + штраф за толпу.
-- Толпа НЕ выкидывает цель (раньше именно из-за этого бот стоял на спавне с
-- надписью "валюта не найдена", когда все монеты были "заняты" другими).
-- v6.1.3: второе возвращаемое значение = "цель ДАЛЬШЕ радиуса" (дальний
-- перелёт). Без него в лобби не было выхода: в кэше 30+ монет, но ни одна не
-- ближе COIN_RANGE — функция возвращала nil, и фарм навсегда замирал.
local function findNearestCoin(origin, ignoreCrowd)
    if os.clock() >= coinNextScan then
        refreshCoinCache()
    end

    local others = ignoreCrowd and {} or otherPlayerPositions()
    local best, bestCost = nil, math.huge

    for i = 1, #coinCache do
        local coin = coinCache[i]
        if not coinGone(coin) and not isRecentlyVisited(coin) then
            local dist = (origin - coin.Position).Magnitude
            if dist < CONFIG.COIN_RANGE then
                local cost = dist + crowdPenalty(coin.Position, others)
                if cost < bestCost then
                    bestCost = cost
                    best     = coin
                end
            end
        end
    end

    if best then
        nearestCoinDist = (origin - best.Position).Magnitude
        return best, false
    end

    -- Радиус пуст: берём ближайшую монету ВООБЩЕ (без ограничения дистанции).
    -- Штраф за толпу здесь уже не важен — главное добраться до карты.
    for i = 1, #coinCache do
        local coin = coinCache[i]
        if not coinGone(coin) and not isRecentlyVisited(coin) then
            local dist = (origin - coin.Position).Magnitude
            if dist < bestCost then
                bestCost = dist
                best     = coin
            end
        end
    end

    nearestCoinDist = best and (origin - best.Position).Magnitude or 0
    return best, best ~= nil
end

-- v6.1: СЛУЧАЙНАЯ цель из самых свободных (раз в 30..45 c).
-- Нужна, чтобы куча ботов не липла к одной монете: даже если все летят к
-- ближайшей, каждый раз в 30..45 c бот уходит к другой.
local function randomCoin(origin)
    local others = otherPlayerPositions()

    -- Проход по кэшу с фильтром дистанции: пул монет с МИНИМАЛЬНОЙ толпой.
    local function gather(range)
        local bestCrowd, pool = nil, {}
        for i = 1, #coinCache do
            local coin = coinCache[i]
            if not coinGone(coin) and not isRecentlyVisited(coin) then
                local dist = (origin - coin.Position).Magnitude
                if dist < range then
                    local n = crowdAt(coin.Position, others)
                    if bestCrowd == nil or n < bestCrowd then
                        bestCrowd, pool = n, { coin }
                    elseif n == bestCrowd then
                        pool[#pool + 1] = coin
                    end
                end
            end
        end
        return pool
    end

    local pool = gather(CONFIG.COIN_RANGE)
    -- v6.1.3: в радиусе пусто (лобби / другой край карты) — берём из ВСЕХ монет:
    -- иначе уход от толпы возвращал nil и отменял единственную дальнюю цель,
    -- которую нашёл findNearestCoin, — и бот снова замирал.
    if #pool == 0 then pool = gather(math.huge) end

    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

--========================================================
-- v5.9: СЧЁТ ПО ФАКТУ (событие сервера + фактический подбор)
--========================================================
-- Игра присылает CoinCollected(id, count, capacity), где count — сколько
-- валюты уже собрано. Считаем РАЗНИЦУ, а не «долетел = +1».
local function findRemoteEvent(root, shortName)
    if not root then return nil end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("RemoteEvent") and string.find(string.lower(d.Name), shortName, 1, true) then
            return d
        end
    end
    return nil
end

local function bindCoinEvents()
    if coinEventBound then return end
    local holder = ReplicatedStorage:FindFirstChild("Remotes")
        or ReplicatedStorage:FindFirstChild("RemoteEvents")
        or ReplicatedStorage

    local ev = findRemoteEvent(holder, "coincollected")
    if ev then
        coinEventBound = true
        ev.OnClientEvent:Connect(function(id, count, capacity)
            if type(count) ~= "number" or count ~= count or count < 0 then return end
            -- Если валюта жёстко задана в конфиге — чужие события не считаем
            if type(id) == "string" and CONFIG.CURRENCY_ID ~= nil
                and id ~= CONFIG.CURRENCY_ID then
                return
            end

            if bagBaseline == nil then
                bagBaseline = count                    -- первый пакет: берём за базу
            elseif count > bagBaseline then
                roundCoins  += (count - bagBaseline)   -- ФАКТИЧЕСКИЙ прирост
                bagBaseline  = count
                lastProgress = os.clock()
                missStreak   = 0
            else
                -- v6.1: счётчик УМЕНЬШИЛСЯ = начался новый раунд (раньше это
                -- ловила надпись Intermission, теперь её детекта нет).
                if count < bagBaseline and bagBaseline > 0 then
                    roundCoins    = 0
                    currentTarget = nil
                    visited       = {}
                    failedUntil   = {}
                    coinNextScan  = 0
                    targetLogged  = false
                    addLog("новый раунд (счётчик валюты сброшен)")
                end
                bagBaseline = count
            end

            bagCount = count
            if type(capacity) == "number" and capacity > 0 then
                bagCapacity  = capacity
                bagCapSource = "event"   -- v6.1.4: сервер главнее GUI
            end
            if farmRunning then updateStatus() end
        end)
        print("[Cosmic] счёт валюты по событию сервера: " .. ev:GetFullName())
    end

    local started = findRemoteEvent(holder, "coinsstarted")
    if started then
        started.OnClientEvent:Connect(function()
            bagBaseline = 0
            bagCount    = 0
            bagCapacity = nil
            bagCapSource = nil   -- v6.1.4: в новом раунде вместимость узнаём заново
            roundCoins  = 0
            missStreak  = 0
            if farmRunning then updateStatus() end
        end)
        print("[Cosmic] новый раунд валюты: " .. started:GetFullName())
    end
end

--========================================================
-- v6.1.4: МЕШОК ИЗ GUI ИГРЫ («40/50»).
-- Сервер не во всех сезонах присылает вместимость мешка третьим аргументом
-- CoinCollected. Из-за этого ресет упирался в хардкод RESET_AT_COINS = 40,
-- хотя в сезоне 50 мест: бот перерождался, не набрав полный мешок.
-- Ищем в PlayerGui текст РОВНО вида «N/M» (наш статус — одна длинная строка
-- «running | +40 | вал:36 ...», под шаблон не подходит) и берём его как
-- текущий счёт и вместимость.
--========================================================
local function readBagGui()
    local ok, res = pcall(function()
        local found
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            local txt = (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text or nil
            if txt and #txt <= 12 then
                local a, b = txt:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
                if a and b then
                    local n, cap = tonumber(a), tonumber(b)
                    -- 5..200 мест: отсекаем таймеры «1/3» и прочие счётчики
                    if n and cap and cap >= 5 and cap <= 200 and n <= cap then
                        found = { count = n, cap = cap }
                    end
                end
            end
        end
        return found
    end)
    return ok and res or nil
end

-- Раз в секунду. Счёт из GUI берём только если события сервера нет (событие
-- точнее), а вместимость — если её не сообщил сервер и она подтвердилась два
-- чтения подряд (защита от чужого счётчика вида «3/12» в чужом GUI).
local function pollBagGui()
    if os.clock() < bagGuiNext then return end
    bagGuiNext = os.clock() + 1
    local info = readBagGui()
    if not info then return end

    if info.cap == bagGuiCapSeen then
        bagGuiCapHits += 1
    else
        bagGuiCapSeen, bagGuiCapHits = info.cap, 1
    end
    if bagCapSource ~= "event" and bagGuiCapHits >= 2 then
        bagCapacity, bagCapSource = info.cap, "gui"
    end

    if not coinEventBound and info.count ~= bagCount then
        bagCount = info.count
        if farmRunning then updateStatus() end
    end
end

-- v5.9: валюта реально ушла? (часть исчезла / Collected / CoinVisual.Collected)
local function coinTaken(coin)
    if coinGone(coin) then return true end
    local ok, vis = pcall(function() return coin:FindFirstChild("CoinVisual") end)
    if ok and vis then
        local ok2, coll = pcall(vis.GetAttribute, vis, "Collected")
        if ok2 and coll == true then return true end
    end
    return false
end

-- Касание валюты для исполнителей, которые умеют firetouchinterest.
-- Сервер сам выдаёт валюту, и мы видим факт, а не «долетел — засчитал».
local function touchAssist(root, coin)
    if type(firetouchinterest) ~= "function" then return false end
    pcall(firetouchinterest, root, coin, 0)
    task.wait()
    pcall(firetouchinterest, root, coin, 1)
    return true
end

-- v5.9: ПОДБОР ПРОВЕРЯЕТСЯ ПО ФАКТУ.
-- Держим персонажа над валютой тем же плавным CFrame-шагом (без телепортов)
-- и ждём, пока игра реально её заберёт. Ничего не забралось за timeout —
-- значит это декор, засчитывать нечего.
local function confirmPickup(coin, goalYArg)
    if not coin or not getRoot() then return false end

    -- v6.1: держим гуманоида в PlatformStand, иначе его "пол" подпирает корень
    -- и бот не может ни опуститься к валюте ниже пола, ни пройти сквозь него.
    local hum = getHumanoid()
    if hum and not hum.PlatformStand then hum.PlatformStand = true end

    local bagBefore   = bagCount
    local roundBefore = roundCoins
    local deadline    = os.clock() + CONFIG.TOUCH_TIMEOUT
    local assistAt    = os.clock() + CONFIG.TOUCH_ASSIST_DELAY
    local goalY       = goalYArg or (coin.Position.Y + CONFIG.PICKUP_LIFT)

    local taken     = false
    while farmRunning and coin.Parent and os.clock() < deadline do
        if coinTaken(coin) then
            taken = true
            break
        end
        if coinEventBound and (bagCount > bagBefore or roundCoins > roundBefore) then
            taken = true
            break
        end

        local r = getRoot()
        if not r then break end

        -- Сначала yield, потом читаем позиции: иначе шаг считается по устаревшей
        local dt    = math.clamp(task.wait(), 0, 0.05)
        local to    = coin.Position
        local dx    = to.X - r.Position.X
        local dz    = to.Z - r.Position.Z
        local dist  = math.sqrt(dx * dx + dz * dz)
        -- v6.1.6: getEffectiveSpeed уже не бывает ниже SPEED_LO (10 ст/с) —
        -- отдельная «нижняя граница» MIN_FARM_SPEED больше не нужна.
        local spd   = getEffectiveSpeed(dist)
        local step  = math.min(spd * dt, CONFIG.MAX_FRAME_MOVE)
        local alpha = dist > 1e-3 and math.clamp(step / dist, 0, 1) or 0

        local nx = r.Position.X + dx * alpha
        local nz = r.Position.Z + dz * alpha
        local dy = goalY - r.Position.Y
        local ny
        if math.abs(dy) <= step then
            ny = goalY
        else
            ny = r.Position.Y + (dy > 0 and step or -step)
        end

        pcall(function()
            r.CFrame = CFrame.new(nx, ny, nz) * r.CFrame.Rotation
            r.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
            r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)

        if CONFIG.TOUCH_ASSIST and os.clock() >= assistAt then
            assistAt = os.clock() + CONFIG.TOUCH_RETRY_AT
            touchAssist(r, coin)
        end
    end

    if not taken then taken = coinTaken(coin) end
    if taken and coin.Parent then
        -- Сервер уже выдал валюту, но часть ещё висит (репликация) —
        -- второй раз к ней не летим.
        markFailed(coin)
    end
    return taken
end

-- v6.0: короткая пауза с УДЕРЖАНИЕМ корня на месте.
-- Noclip выключает коллизии, поэтому без записи CFrame персонаж за паузу
-- (0.1..0.3 c) успевает просесть вниз — и следующий полёт начинается с того,
-- что бот сначала опускается, а потом поднимается. Держим позицию: просадки нет.
local function holdStill(seconds)
    seconds = seconds or 0.1
    local root = getRoot()
    local hum  = getHumanoid()
    if not root or not hum or hum.Health <= 0 then
        task.wait(seconds)
        return
    end
    -- v6.1: пауза тоже идёт "в noclip" — иначе Humanoid подопрёт корень полом
    -- и после паузы бот начнёт не оттуда, откуда остановился.
    if not hum.PlatformStand then hum.PlatformStand = true end
    local pos    = root.Position
    local untilT = os.clock() + seconds
    repeat
        task.wait()
        pcall(function()
            root.CFrame = CFrame.new(pos) * root.CFrame.Rotation
            root.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
    until os.clock() >= untilT
end

--========================================================
-- FARM CORE
-- Один цикл: ближайшая монета -> долететь -> отметить -> вернуться.
-- =======================================================
local function farmIteration()
    local root = getRoot()
    local hum  = getHumanoid()
    if not root or not hum then
        idleReason = "нет персонажа"
        dbgText    = ""
        task.wait(0.5)
        return
    end
    if hum.Health <= 0 then
        idleReason = "персонаж мёртв (ждём респавн)"
        dbgText    = ""
        task.wait(0.5)
        return
    end

    -- Ручной полёт конфликтует с фармом
    if flags.fly then
        idleReason = "включён ручной Fly"
        dbgText    = ""
        task.wait(0.2)
        return
    end

    -- Авто-ресет: провалились ниже карты (с подтверждением, чтобы не ловить
    -- ложное срабатывание на телепорте в начале раунда)
    if flags.autoReset and root.Position.Y < CONFIG.RESET_Y then
        if not fallSince then fallSince = os.clock() end
        if os.clock() - fallSince >= CONFIG.FALL_CONFIRM then
            respawnNow()
            return
        end
    else
        fallSince = nil
    end

    -- v6.1: раз в 30..45 c уходим к СЛУЧАЙНОЙ монете (из самых свободных),
    -- чтобы куча ботов не липла к одной. Таймер не сбрасывается при неудаче:
    -- иначе при пустой карте он бы дёргался каждый кадр.
    if flags.avoidCrowd and os.clock() >= wanderNextAt
        and not (roundCoins == 0 and nearestCoinDist > CONFIG.FAR_HOLD_DIST) then
        -- v6.1.5: в лобби «уход от толпы» не нужен — он только подставлял дальнюю
        -- монету и раньше сбивал ожидание («ухожу от толпы» прямо перед полётом).
        wanderNextAt = os.clock() + CONFIG.CROWD_WANDER_MIN
            + math.random() * (CONFIG.CROWD_WANDER_MAX - CONFIG.CROWD_WANDER_MIN)
        wanderTarget = randomCoin(root.Position)
        if wanderTarget then
            addLog("ухожу от толпы: случайная монета")
        end
    end

    if not (currentTarget and currentTarget.Parent) then
        -- v6.1: wanderTarget выбран заранее (раз в 30..45 c) и мог исчезнуть —
        -- забрал другой бот или сменился раунд. Иначе летим к пустоте.
        if wanderTarget and coinGone(wanderTarget) then
            wanderTarget = nil
        end
        -- v6.1.3: far = ни одной монеты в радиусе COIN_RANGE (лобби или другой
        -- край карты). Раньше это был тупик: currentTarget = nil, и бот стоял с
        -- «валюта не найдена», хотя в кэше 30+ монет.
        local nearest, far = findNearestCoin(root.Position)
        currentTarget = wanderTarget or nearest
        wanderTarget  = nil

        -- v6.1.4: СЛИШКОМ ДАЛЕКО = МЫ НЕ НА КАРТЕ. Пока в раунде не собрано ни
        -- одной монеты, а ближайшая дальше FAR_HOLD_DIST, лететь бессмысленно:
        -- игру устраивает только её собственный перенос на карту, а полёт из
        -- лобби его ломает (персонаж оставался в лобби и ехал за 8000 студов).
        -- v6.1.5: ТАЙМАУТА БОЛЬШЕ НЕТ. В 6.1.4 через FAR_HOLD_MAX секунд бот всё
        -- равно летел — ровно это видно в логе («лечу к ближайшей (Coin_Server,
        -- 8866 ст)»), и персонаж так и оставался в лобби. Ждём без ограничения:
        -- уедем из лобби — испортим весь раунд, постоим — просто потеряем время.
        farHoldDist = 0
        if currentTarget and CONFIG.FAR_HOLD_DIST > 0 and roundCoins == 0 then
            local d = (currentTarget.Position - root.Position).Magnitude
            if d > CONFIG.FAR_HOLD_DIST then
                if not farHoldSince then
                    farHoldSince  = os.clock()
                    farHoldWarned = false
                end
                farHoldDist   = d
                currentTarget = nil
                wanderTarget  = nil
                if os.clock() - farHoldLoggedAt > 15 then
                    farHoldLoggedAt = os.clock()
                    -- v6.1.5: в логе видно ВСЁ, что нужно для разбора: где стоим,
                    -- сколько монет в мире, заякорен ли персонаж игрой.
                    addLog(("жду карту: монета %.0f ст > %d | я (%.0f, %.0f, %.0f) | монет %d | заякорен: %s")
                        :format(d, CONFIG.FAR_HOLD_DIST, root.Position.X, root.Position.Y,
                            root.Position.Z, currencyCount, tostring(root.Anchored)))
                end
                if not farHoldWarned and os.clock() - farHoldSince > CONFIG.FAR_HOLD_MAX then
                    farHoldWarned = true
                    addLog(("не переносят на карту %.0f c — стою и не трогаю персонажа "
                        .. "(лечу, только когда монета ближе %d ст)")
                        :format(os.clock() - farHoldSince, CONFIG.FAR_HOLD_DIST))
                    addLog("если так весь раунд — Stop и Run farm (или FAR_HOLD_DIST = 0)")
                end
            else
                farHoldSince = nil
            end
        else
            farHoldSince = nil
        end
        -- v6.1.5: пока в раунде не собрано ни одной монеты и цели нет — стоим
        -- ПАССИВНО (без noclip, PlatformStand и записи CFrame), чтобы не мешать
        -- игре перенести персонажа на карту.
        lobbyHold = (roundCoins == 0 and currentTarget == nil)
        if currentTarget and far then
            -- Строка в лог — не чаще раза в 10 c: иначе она забьёт окно.
            if os.clock() - farLoggedAt > 10 then
                farLoggedAt = os.clock()
                addLog(("все монеты дальше %d ст — лечу к ближайшей (%s, %.0f ст)")
                    :format(CONFIG.COIN_RANGE, tostring(currentTarget.Name),
                        (currentTarget.Position - root.Position).Magnitude))
            end
        elseif currentTarget and not targetLogged then
            targetLogged = true
            addLog(("цель: %s (%.0f ст)"):format(
                currentTarget.Name, (currentTarget.Position - root.Position).Magnitude))
        end
    end

    -- Монет нет (начало раунда / все собраны): ждём и НЕ считаем это простоем
    if not currentTarget then
        -- v6.1.3: пишем, ЧЕГО не хватает. Пустой кэш = карта ещё не загружена
        -- (межраундье), это нормальное ожидание. Непустой кэш при пустом
        -- результате = все монеты в чёрном списке (их только что не забрали).
        if farHoldDist > 0 then
            -- v6.1.5: причина простоя — «мы не на карте» + сколько уже ждём
            idleReason = ("жду карту: %.0f ст, %.0f c"):format(
                farHoldDist, farHoldSince and (os.clock() - farHoldSince) or 0)
        elseif currencyCount > 0 then
            idleReason = ("валюта не найдена (в кэше %d, все в чёрном списке)")
                :format(currencyCount)
        else
            idleReason = "жду карту (в workspace нет монет — межраундье)"
        end
        dbgText      = ""
        lastProgress = os.clock()
        if lobbyHold then
            -- v6.1.5: ПАССИВНОЕ ожидание. Раньше здесь стоял holdStill(0.3),
            -- который каждый кадр возвращал корень на место — и перенос на карту,
            -- сделанный игрой, тут же отменялся: бот «замирал» в лобби.
            task.wait(0.3)
        else
            holdStill(0.3)   -- v6.0: ждём, не давая персонажу просесть вниз
        end
        return
    end

    -- Авто-ресет: есть цель, но давно ничего не собираем (монеты забирают / недостижимы)
    if flags.autoReset
        and os.clock() >= graceUntil
        and (os.clock() - lastProgress) > CONFIG.IDLE_RESET then
        lastProgress = os.clock()
        markFailed(currentTarget)   -- v5.8: эту цель больше не берём FAIL_BLACKLIST сек.
        respawnNow()
        return
    end

    -- v6.0: ОДНА точка полёта на всю цель (по пути не меняется)
    local hipOffset = computeHipOffset()
    local goal      = flightGoal(currentTarget, hipOffset)

    -- v6.1: пока ведём персонажа — PlatformStand, чтобы Humanoid не подпирал
    -- его полом (см. maintain). Без этого бот "не пробивал" пол.
    movingToCoin  = true
    hum.AutoRotate = false
    if not hum.PlatformStand then hum.PlatformStand = true end

    local lastPos      = root.Position
    local lastDist     = math.huge
    local stuck        = 0
    local reached      = false
    local retargetAt   = os.clock() + CONFIG.RETARGET_INTERVAL
    local approachBest = (goal - root.Position).Magnitude

    while farmRunning and currentTarget and currentTarget.Parent do
        local r = getRoot()
        if not r then break end

        local dt = math.clamp(task.wait(), 0, 0.05)

        -- v6.1.4: ЗА ПАУЗУ цель могла обнулиться. Обработчик CoinCollected при
        -- старте нового раунда пишет currentTarget = nil, а корень пропадает при
        -- респавне. Без проверки кадр падал с «:2026: attempt to index nil with
        -- 'Position'» и цикл обрывался посреди полёта (movingToCoin оставался
        -- true, Noclip не выключался).
        if not currentTarget or not currentTarget.Parent then break end
        local rNow = getRoot()
        if not rNow then break end
        r = rNow

        -- v6.1: пересмотр цели РЕДКО (1.5 c) и только при явном выигрыше
        -- (>= RETARGET_ADVANTAGE студов). Раньше 0.35 c + 25% заворачивали бота
        -- в сторону на каждом шаге — со стороны это было похоже на объезд.
        if os.clock() >= retargetAt then
            retargetAt = os.clock() + CONFIG.RETARGET_INTERVAL

            -- Другой игрок уже НА монете и заметно ближе — не летим хвостом
            if isTakenByOther(currentTarget.Position, r.Position, otherPlayerPositions()) then
                markVisited(currentTarget)
                currentTarget = nil
                break
            end

            local cand = findNearestCoin(r.Position)
            if cand and cand ~= currentTarget and cand.Parent then
                local dCur = (currentTarget.Position - r.Position).Magnitude
                local dNew = (cand.Position - r.Position).Magnitude
                if dNew < dCur - CONFIG.RETARGET_ADVANTAGE then
                    currentTarget = cand
                    goal          = flightGoal(cand, hipOffset)
                    approachBest  = (goal - r.Position).Magnitude
                end
            end
        end


        -- v6.0: ведём корень по ПРЯМОЙ 3D-линии к точке над валютой.
        -- Вертикаль распределена по всему пути так же, как горизонталь:
        -- бот поднимается/опускается РАВНОМЕРНО, а не "сначала по X, потом
        -- на высоту монеты по Y". Высота — из goal (считается один раз на
        -- цель), X/Z — живая позиция валюты (на случай, если она на
        -- движущейся платформе).
        local to     = currentTarget.Position
        local delta  = Vector3.new(to.X - r.Position.X,
            goal.Y - r.Position.Y,
            to.Z - r.Position.Z)
        local dx     = delta.X
        local dz     = delta.Z
        local dy     = delta.Y
        local distXZ = math.sqrt(dx * dx + dz * dz)
        local dist3  = delta.Magnitude
        lastDist     = distXZ

        -- Пока реально приближаемся (по 3D) — простой не засчитывается
        if dist3 < approachBest - 0.5 then
            approachBest = dist3
            lastProgress = os.clock()
        end

        -- Догнал = горизонталь в STOP_DIST И высота в STOP_DIST. Высота
        -- догоняется той же прямой, поэтому "под монетой -> вверх" не бывает.
        if distXZ <= CONFIG.STOP_DIST and math.abs(dy) <= CONFIG.STOP_DIST then
            -- v5.9: НЕ «долетел = засчитал». Держимся над валютой и ждём,
            -- пока игра реально её заберёт (исчезла / Collected / CoinCollected).
            -- v6.1.4: confirmPickup внутри делает паузы, поэтому за это время
            -- цель могла обнулиться обработчиком валюты (новый раунд). Держим её
            -- локально, иначе markFailed(nil) ронял кадр.
            local target = currentTarget
            reached = confirmPickup(target, goal.Y)
            if reached then
                missStreak  = 0
                lastProgress = os.clock()
            elseif target then
                missStreak += 1
                markFailed(target)   -- декор / сервер не выдал: не кружимся
                addLog((("не забрали %s за %.1f c — в чёрный список"):format(
                    tostring(target.Name), CONFIG.TOUCH_TIMEOUT))
                    .. (type(firetouchinterest) == "function" and ""
                        or " | нет firetouchinterest: подбор только касанием"))
                if missStreak >= 5 then
                    missStreak  = 0
                    failedUntil = {}
                    addLog("5 целей подряд не подобрались — чёрный список очищен")
                end
            end
            break
        end

        -- v6.1.4: SMART SPEED ПО ВЕКТОРУ. Множитель считается по длине 3D-пути
        -- (dist3), а не по горизонтальной проекции: при полёте наискосок/вверх
        -- скорость больше не зависит от того, что «по земле близко, а по высоте
        -- далеко». Шаг идёт по единичному 3D-вектору, значит скорость постоянна
        -- вдоль всей прямой (без «сначала вперёд, потом вверх»).
        local spd   = getEffectiveSpeed(dist3)
        -- v6.1.3: дальний перелёт (лобби -> карта). Обычная скорость фарма
        -- (SPEED_LO..SPEED_HI = 10..80 ст/с) превращала 2000 студов в минуту
        -- стояния на месте. FLY_SPEED уже проверен ручным полётом — берём его
        -- как МИНИМУМ, то есть слайдер выше 70 продолжает работать.
        if dist3 > CONFIG.FAR_DIST then
            spd = math.max(spd, CONFIG.FLY_SPEED)
        end
        local step  = math.min(spd * dt, CONFIG.MAX_FRAME_MOVE)
        local alpha = dist3 > 1e-3 and math.clamp(step / dist3, 0, 1) or 1

        local nx = r.Position.X + dx * alpha
        local ny = r.Position.Y + dy * alpha
        local nz = r.Position.Z + dz * alpha

        -- Пишем позицию. Основной способ — CFrame (как в v5.3). Если персонаж
        -- при этом не сдвигается вообще (физика/игра возвращают позицию),
        -- автоматически переключаемся на velocity-толчок.
        if moveMode == "cframe" then
            pcall(function()
                r.CFrame = CFrame.new(nx, ny, nz) * r.CFrame.Rotation
                r.AssemblyLinearVelocity  = Vector3.new(0, 0, 0)
                r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        else
            local dir = Vector3.new(dx, dy, dz)
            if dir.Magnitude > 1e-3 then dir = dir.Unit end
            pcall(function()
                r.AssemblyLinearVelocity  = dir * spd
                r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end

        if os.clock() >= dbgNextAt then
            dbgNextAt = os.clock() + 0.5
            dbgText = ("цель %.14s %.0fст | v=%.1f | %s"):format(
                currentTarget.Name, distXZ, spd, moveMode)
        end

        -- Застревание: просто бросаем цель (никаких авто-ресетов по "не двигается")
        if os.clock() < graceUntil then
            stuck   = 0
            lastPos = r.Position
        elseif (r.Position - lastPos).Magnitude < 0.05 then
            stuck += dt
            if stuck >= 0.5 and moveMode == "cframe" and distXZ > 4 then
                -- CFrame не сдвигает персонажа -> пробуем velocity
                moveMode   = "velocity"
                stuck      = 0
                lastPos    = r.Position
                print("[Cosmic] CFrame не двигает персонажа -> перешёл на velocity")
            elseif stuck >= CONFIG.STUCK_LIMIT then
                idleReason = (moveMode == "velocity" and "не двигается даже velocity")
                    or "не двигается (CFrame)"
                print("[Cosmic] цель недостижима: " .. idleReason)
                markVisited(currentTarget)
                markFailed(currentTarget)   -- v5.8: дольше не возвращаемся
                currentTarget = nil
                break
            end
        else
            idleReason = "лечу к цели"
            stuck      = 0
            lastPos    = r.Position
        end
    end

    movingToCoin = false
    idleReason   = "выбираю следующую цель"
    dbgText      = ""

    local endHum = getHumanoid()
    if endHum and not flags.fly then
        endHum.AutoRotate = true
    end

    -- Монета исчезла, когда мы были уже рядом (собрали касанием) — тоже успех
    if not reached and currentTarget and currentTarget.Parent == nil
        and lastDist <= CONFIG.STOP_DIST * 2 then
        reached = true
    end

    if currentTarget then
        markVisited(currentTarget)
        currentTarget = nil
    end

    if reached then
        lastProgress = os.clock()
        -- v5.9: при событии сервера счёт уже увеличен по фактическому приросту
        if not coinEventBound then roundCoins += 1 end
        updateStatus()
        holdStill(0.1)   -- v6.0: даём сработать сбору, не давая просесть
    end

    -- Авто-ресет по количеству собранных за раунд монет
    -- Авто-ресет по мешку (v6.1.4). Вместимость берём из события сервера или из
    -- GUI игры, поэтому ресет срабатывает ровно на «мешок полон» (50/50 в
    -- обычном сезоне, 40/40 в ивенте) — RESET_AT_COINS только страховка для игр,
    -- где вместимость нигде не сообщается.
    if reached and flags.autoReset then
        local haveCap = bagCapacity and bagCapacity > 0
        local full    = haveCap and bagCount >= bagCapacity
        if full or (not haveCap and CONFIG.RESET_AT_COINS > 0
            and roundCoins >= CONFIG.RESET_AT_COINS) then
            addLog(full
                and ("мешок полон %d/%d — ресет"):format(bagCount, bagCapacity)
                or ("%d монет за раунд — ресет"):format(roundCoins))
            respawnNow()
        end
    end
end

--========================================================
-- v6.1.2: САМОПРОВЕРКА СБОРКИ.
-- Скрипт — один большой файл, и он уже один раз "склеился" так, что
-- объявление функции оказалось внутри другой. Синтаксис при этом цел, а в
-- игре вызов падает с "attempt to call a nil value" и номером строки — по
-- такому сообщению невозможно понять, ЧТО именно nil.
-- Здесь перечислены функции, без которых фарм не работает: при старте и при
-- ошибке фарма печатается список отсутствующих. ВАЖНО: обращение к имени,
-- которого нет, тихо даёт nil (глобал), поэтому проверка не падает сама.
--========================================================
local function selfCheck()
    -- Таблица строится НА МОМЕНТ ВЫЗОВА, а не при загрузке файла: farmStart и
    -- farmStop — глобальные функции и объявлены НИЖЕ этого места, поэтому в
    -- момент загрузки они ещё nil. Здесь же они читаются уже готовыми.
    local probe = {
    { "addLog",             addLog             },
    { "updateStatus",       updateStatus       },
    { "getRoot",            getRoot            },
    { "getHumanoid",        getHumanoid        },
    { "refreshParts",       refreshParts       },
    { "noclipWanted",       noclipWanted       },
    { "holdStill",          holdStill          },
    { "coinFloorY",         coinFloorY         },
    { "flightGoal",         flightGoal         },
    { "getEffectiveSpeed",  getEffectiveSpeed  },
    { "baseSpeed",          baseSpeed          },
    { "respawnNow",         respawnNow         },
    { "onCharacterSpawn",   onCharacterSpawn   },
    { "markVisited",        markVisited        },
    { "markFailed",         markFailed         },
    { "isRecentlyVisited",  isRecentlyVisited  },
    { "otherPlayerPositions", otherPlayerPositions },
    { "crowdAt",            crowdAt            },
    { "crowdPenalty",       crowdPenalty       },
    { "isTakenByOther",     isTakenByOther     },
    { "coinGone",           coinGone           },
    { "isInteractivePart",  isInteractivePart  },
    { "nameIsDenied",       nameIsDenied       },
    { "nameHasCurrencyWord", nameHasCurrencyWord },
    { "hasCurrencyTag",     hasCurrencyTag     },
    { "looksCollectible",   looksCollectible   },
    { "collectParts",       collectParts       },
    { "nameIsExtraCurrency", nameIsExtraCurrency },
    { "currencyKind",       currencyKind       },
    { "dumpCandidates",     dumpCandidates     },
    { "refreshCoinCache",   refreshCoinCache   },
    { "findNearestCoin",    findNearestCoin    },
    { "randomCoin",         randomCoin         },
    { "bindCoinEvents",     bindCoinEvents     },
    { "coinTaken",          coinTaken          },
    { "touchAssist",        touchAssist        },
    { "confirmPickup",      confirmPickup      },
    { "farmIteration",      farmIteration      },
    { "farmStart",          farmStart          },
    { "farmStop",           farmStop           },
    }

    local missing = {}
    for i = 1, #probe do
        local name, fn = probe[i][1], probe[i][2]
        if type(fn) ~= "function" then
            missing[#missing + 1] = name
        end
    end
    if #missing > 0 then
        local msg = "СБОРКА СЛОМАНА — нет функций: "
            .. table.concat(missing, ", ")
            .. " (файл загружен не полностью: залейте его заново целиком)"
        warn("[Cosmic] " .. msg)
        return false, msg
    end
    return true, ("самопроверка: ок (%d функций)"):format(#probe)
end

--========================================================
-- v6.1: СУПЕРВИЗОР. Стоп-в-лобби (enterLobby / leaveLobby / pollRound)
-- удалён целиком: он не спасал (бот всё равно летал по лобби на декор),
-- занимал место в GUI и иногда ложно останавливал фарм из-за надписи
-- "intermission". Раунд определяется по респавну персонажа и по счётчику
-- валюты сервера.
--========================================================

function farmStart()
    -- v6.1.2: если файл собран не полностью, не начинаем фарм: иначе это
    -- поток одинаковых "attempt to call a nil value" в логе.
    local buildOk, why = selfCheck()
    if not buildOk then
        idleReason = "сборка сломана (смотри лог)"
        addLog(why)
        updateStatus()
        return
    end

    farmRunning   = true
    currentTarget = nil
    movingToCoin  = false
    wanderTarget  = nil
    wanderNextAt  = os.clock() + CONFIG.CROWD_WANDER_MIN
        + math.random() * (CONFIG.CROWD_WANDER_MAX - CONFIG.CROWD_WANDER_MIN)
    visited       = {}
    fallSince     = nil
    lastProgress  = os.clock()
    graceUntil    = os.clock() + CONFIG.SPAWN_GRACE
    moveMode      = "cframe"
    idleReason    = "старт: ищу валюту"
    dbgText       = ""
    coinNextScan  = 0
    failedUntil   = {}   -- чистый чёрный список недостижимых целей
    missStreak    = 0    -- счётчик «не подобралось подряд» сбрасываем
    farHoldSince  = nil  -- v6.1.4: ожидание «мы в лобби» начинается заново
    farHoldWarned = false
    farHoldLoggedAt = 0
    lobbyHold     = false -- v6.1.5: noclip/PlatformStand снова наши

    runBtn.Text = "Stop farm"
    runBtn.BackgroundColor3 = COLORS.accent2
    addLog("фарм запущен")
    updateStatus()
end

function farmStop()
    farmRunning   = false
    currentTarget = nil
    movingToCoin  = false
    wanderTarget  = nil
    moveMode      = "cframe"
    lobbyHold     = false   -- v6.1.5: вернуть персонажу обычное управление/noclip
    farHoldSince  = nil
    farHoldWarned = false
    idleReason    = "остановлен"
    dbgText       = ""
    runBtn.Text = "Run farm"
    runBtn.BackgroundColor3 = COLORS.accent
    addLog("фарм остановлен")
    updateStatus()
end

runBtn.MouseButton1Click:Connect(function()
    if farmRunning then farmStop() else farmStart() end
end)

task.spawn(function()
    while true do
        if not farmRunning then
            task.wait(0.2)
        else
            local ok, err = pcall(farmIteration)
            if not ok then
                warn("[Cosmic] farm error:", err)
                idleReason = "ошибка в farmIteration (смотри лог)"
                local msg = "ошибка фарма: " .. tostring(err)
                -- v6.1.2: "attempt to call a nil value" почти всегда означает
                -- потерянную при копировании функцию — сразу называем её.
                if tostring(err):find("nil value", 1, true) then
                    local buildOk, why = selfCheck()
                    if not buildOk then msg = msg .. " | " .. why end
                end
                addLog(msg)
                task.wait(0.5)
            end
        end
    end
end)

--========================================================
-- ДИАГНОСТИКА: строка состояния в окне + лог в консоль.
-- Позволяет точно увидеть, почему бот не двигается.
--========================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        pollBagGui()          -- v6.1.4: «мешок N/M» из GUI игры (раз в секунду)
        if farmRunning then updateStatus() end
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.DBG_INTERVAL)

        if not CONFIG.DEBUG or not farmRunning then
            lastDbgPos = nil
        else
            local r     = getRoot()
            local pos   = r and r.Position or Vector3.new()
            local moved = lastDbgPos and (pos - lastDbgPos).Magnitude or 0
            lastDbgPos  = pos

            print((("[Cosmic][dbg] run=%s fly=%s mode=%s | вал=%d (%s) | событие=%s"
                .. " | цель=%s | сдвиг=%.1f ст | поз=(%.0f, %.0f, %.0f) | %s")
                :format(
                    tostring(farmRunning), tostring(flags.fly),
                    moveMode, currencyCount, currencyMode or "не найдена",
                    coinEventBound and ("да, мешок " .. tostring(bagCount)) or "нет",
                    currentTarget and currentTarget.Name or "—",
                    moved, pos.X, pos.Y, pos.Z, idleReason)))
        end
    end
end)

--========================================================
-- LAUNCH
--========================================================
task.spawn(function()
    task.wait(2)

    updateSpeedVisuals()
    bindCoinEvents()  -- v5.9: подписка на CoinCollected (счёт по факту)
    local _, checkMsg = selfCheck()   -- v6.1.2: проверка целостности сборки
    addLog(("v%s загружен — управление через WindUI"):format(BUILD))
    addLog(checkMsg)
    -- v6.1.4: сразу видно, чем бот подбирает валюту и знает ли он размер мешка.
    addLog(("подбор: %s | мешок: %s"):format(
        type(firetouchinterest) == "function" and "firetouchinterest" or "касанием",
        bagCapacity and ("0/" .. tostring(bagCapacity)) or "размер неизвестен"))

    main.Visible = false -- legacy UI не показываем

    -- Если персонаж уже в игре — сразу готовим состояние (без авто-старта до пароля)
    if LocalPlayer.Character then
        onCharacterSpawn(LocalPlayer.Character)
    end
end)

print("[Cosmic UI v6.1 MM2] Module loaded. Build " .. BUILD .. " | unified WindUI enabled")


--========================================================
-- UNIFIED WINDUI HUB
--========================================================
-- Footagesus WindUI.
-- NOTE: main_example.lua launches the library's standalone demo and does not
-- return its WindUI/Window objects. Loading it here would create a separate
-- demo window, so this hub loads the same WindUI library and creates the hub
-- controls inside a single WindUI window using the example's modern styling.
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "MM2 HUB",
    Icon = "solar:wind-bold",
    Author = "Footagesus WindUI • MM2",
    Folder = "MM2CombinedHub",
    Size = UDim2.fromOffset(700, 560),
    MinSize = Vector2.new(560, 420),
    Theme = "Dark",
    Resizable = true,
    Transparent = true,
    NewElements = true,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    SideBarWidth = 200,
    ToggleKey = Enum.KeyCode.RightShift,
    OpenButton = {
        Title = "Open MM2 HUB",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
    },
})

local function uiNotify(title, content)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = 4 })
    end)
end

local function setESP(value)
    ESPEnabled = value
    if not value then
        for _, obj in pairs(espObjects) do
            if obj then
                if obj.box then obj.box.Visible = false end
                if obj.name then obj.name.Visible = false end
                if obj.roleText then obj.roleText.Visible = false end
            end
        end
    end
end

local function setGunESP(value)
    GunESPEnabled = value
    if not value and gunESPObject then
        pcall(function() if gunESPObject.box then gunESPObject.box:Remove() end end)
        pcall(function() if gunESPObject.label then gunESPObject.label:Remove() end end)
        gunESPObject = nil
    end
end

local function setAntiFling(value)
    AntiFlingEnabled = value
    flags.antiFling = value
    if value then
        StartAntiFling()
    else
        if antiFlingConnection then
            antiFlingConnection:Disconnect()
            antiFlingConnection = nil
        end
    end
end

local function setAutoKill(value)
    if AutoKillEnabled ~= value then
        ToggleAutoKill()
    end
end

local FarmTab = Window:Tab({ Title = "Farm", Icon = "coins" })
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local UtilityTab = Window:Tab({ Title = "Utilities", Icon = "shield-check" })
local ActionTab = Window:Tab({ Title = "Actions", Icon = "zap" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Farm
local farmSection = FarmTab:Section({ Title = "Autofarm" })
farmSection:Button({
    Title = "Start / Stop Farm",
    Desc = "Start or stop automatic coin collection",
    Callback = function()
        if farmRunning then
            farmStop()
            uiNotify("Autofarm", "Farm stopped")
        else
            farmStart()
            uiNotify("Autofarm", "Farm start command sent")
        end
    end,
})
farmSection:Toggle({
    Title = "Auto Start on Respawn",
    Desc = "Automatically start farming after your character respawns",
    Default = flags.autoStart,
    Callback = function(value) flags.autoStart = value end,
})
farmSection:Toggle({
    Title = "Auto Reset",
    Desc = "Allow automatic character reset when the farm conditions require it",
    Default = flags.autoReset,
    Callback = function(value) flags.autoReset = value end,
})
farmSection:Slider({
    Title = "Farm Speed",
    Desc = "Movement speed: 1–50",
    Step = 1,
    Value = { Min = CONFIG.SPEED_MIN, Max = CONFIG.SPEED_MAX, Default = speedValue },
    Callback = function(value)
        speedValue = math.clamp(tonumber(value) or speedValue, CONFIG.SPEED_MIN, CONFIG.SPEED_MAX)
        pcall(updateSpeedVisuals)
        pcall(updateStatus)
    end,
})
farmSection:Toggle({
    Title = "Smart Speed",
    Desc = "Increase speed when closer to the target",
    Default = flags.smartSpeed,
    Callback = function(value) flags.smartSpeed = value end,
})
farmSection:Toggle({
    Title = "Avoid Crowd",
    Desc = "Avoid crowded areas when selecting coins",
    Default = flags.avoidCrowd,
    Callback = function(value) flags.avoidCrowd = value end,
})
farmSection:Button({
    Title = "Copy Farm Log",
    Desc = "Copy the diagnostic log if the clipboard API is available",
    Callback = function()
        local logText = table.concat(logLines, "\n")
        local ok = pcall(function() setclipboard(logText) end)
        uiNotify("Farm Log", ok and "Log copied" or "Clipboard API is unavailable")
    end,
})

-- Visuals
local visualSection = VisualTab:Section({ Title = "ESP" })
visualSection:Toggle({
    Title = "Player ESP",
    Desc = "Highlight players and display role labels",
    Default = ESPEnabled,
    Callback = setESP,
})
visualSection:Toggle({
    Title = "Gun ESP",
    Desc = "Highlight the dropped gun when available",
    Default = GunESPEnabled,
    Callback = setGunESP,
})

-- Utilities
local protectionSection = UtilityTab:Section({ Title = "Protection" })
protectionSection:Toggle({
    Title = "Anti-Fling",
    Desc = "Toggle the protection handlers from the included modules",
    Default = AntiFlingEnabled and flags.antiFling,
    Callback = setAntiFling,
})
protectionSection:Toggle({
    Title = "Anti-AFK",
    Desc = "Enable the anti-idle handler",
    Default = flags.antiAFK,
    Callback = function(value) flags.antiAFK = value end,
})
protectionSection:Toggle({
    Title = "Manual Fly",
    Desc = "Manual flight with WASD + Space / Shift",
    Default = flags.fly,
    Callback = function(value) flags.fly = value end,
})
protectionSection:Button({
    Title = "Teleport to Gun",
    Desc = "Teleport to the dropped gun when available",
    Callback = function() TeleportToGun() end,
})

-- Actions
local actionSection = ActionTab:Section({ Title = "Actions" })
actionSection:Toggle({
    Title = "Auto Kill",
    Desc = "Enables the original Auto Kill loop from module1",
    Default = AutoKillEnabled,
    Callback = setAutoKill,
})
actionSection:Paragraph({
    Title = "Single WindUI Interface",
    Desc = "All hub controls use this WindUI window. The legacy standalone target-fling panel is disabled to prevent separate non-WindUI windows.",
})

-- Settings
local PulseHubController
local settingsSection = SettingsTab:Section({ Title = "Hub" })
settingsSection:Paragraph({
    Title = "WindUI Build",
    Desc = "Use this single WindUI window for hub controls. Legacy standalone interfaces remain hidden or disabled.",
})
settingsSection:Button({
    Title = "Stop Active Modules",
    Desc = "Stop farming and disable Auto Kill and manual flight",
    Callback = function()
        pcall(farmStop)
        pcall(function() setAutoKill(false) end)
        pcall(function() if PulseHubController then PulseHubController.Unload() end end)
        flags.fly = false
        uiNotify("MM2 HUB", "Active loops stopped")
    end,
})
settingsSection:Button({
    Title = "Unload WindUI Window",
    Desc = "Close the WindUI window only",
    Callback = function()
        pcall(function() if PulseHubController then PulseHubController.Unload() end end); pcall(function() Window:Destroy() end)
    end,
})


--========================================================
-- EXTRA MODULES (adapted from the additional uploaded scripts)
-- All labels in this hub are English.
--========================================================
local ExtraTab = Window:Tab({ Title = "Extra Modules", Icon = "layers" })

-- Candy collection module from module3.txt
local candySection = ExtraTab:Section({ Title = "Candy Farm" })
local candyFarmEnabled = false
local candyFarmSpeed = 23
local candyFarmThread = nil

local function stopCandyFarm()
    candyFarmEnabled = false
    candyFarmThread = nil
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.HipHeight = 0
    end
end

local function startCandyFarm()
    if candyFarmEnabled then return end
    candyFarmEnabled = true
    candyFarmThread = task.spawn(function()
        while candyFarmEnabled do
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                local target, bestDistance = nil, math.huge
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "Candies" then
                        local distance = (obj.Position - root.Position).Magnitude
                        if distance < bestDistance then
                            target, bestDistance = obj, distance
                        end
                    end
                end
                if target then
                    local delta = target.Position - root.Position
                    if delta.Magnitude > 1 then
                        root.AssemblyLinearVelocity = delta.Unit * candyFarmSpeed
                    else
                        root.AssemblyLinearVelocity = Vector3.zero
                    end
                    task.wait(0.12)
                else
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.4)
                end
            else
                task.wait(0.3)
            end
        end
    end)
end

candySection:Toggle({
    Title = "Fly Farm Candies",
    Desc = "Move toward the nearest candy pickup",
    Default = false,
    Callback = function(value)
        if value then startCandyFarm() else stopCandyFarm() end
    end,
})
candySection:Slider({
    Title = "Candy Farm Speed",
    Desc = "Movement speed used by the candy collector",
    Step = 1,
    Value = { Min = 5, Max = 60, Default = candyFarmSpeed },
    Callback = function(value)
        candyFarmSpeed = math.clamp(tonumber(value) or 23, 5, 60)
    end,
})

-- Movement helpers adapted from module3.txt
local movementSection = ExtraTab:Section({ Title = "Movement" })
local customWalkSpeedEnabled = false
local customWalkSpeed = 23
local customHipHeightEnabled = false

local function applyMovementSettings()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.WalkSpeed = customWalkSpeedEnabled and customWalkSpeed or 16
    humanoid.HipHeight = customHipHeightEnabled and -1.5 or 0
end

movementSection:Toggle({
    Title = "Custom Walk Speed",
    Desc = "Apply a custom character WalkSpeed",
    Default = false,
    Callback = function(value)
        customWalkSpeedEnabled = value
        applyMovementSettings()
    end,
})
movementSection:Slider({
    Title = "Walk Speed",
    Desc = "Custom WalkSpeed value",
    Step = 1,
    Value = { Min = 16, Max = 60, Default = customWalkSpeed },
    Callback = function(value)
        customWalkSpeed = math.clamp(tonumber(value) or 23, 16, 60)
        if customWalkSpeedEnabled then applyMovementSettings() end
    end,
})
movementSection:Toggle({
    Title = "Low Hip Height",
    Desc = "Set HipHeight to -1.5 while enabled",
    Default = false,
    Callback = function(value)
        customHipHeightEnabled = value
        applyMovementSettings()
    end,
})
movementSection:Button({
    Title = "Reset Character",
    Desc = "Reset your own character",
    Callback = function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
    end,
})

-- Simple fall recovery from module3.txt
local safetySection = ExtraTab:Section({ Title = "Safety Helpers" })
local fallRecoveryEnabled = false
local fallRecoveryConnection = nil
safetySection:Toggle({
    Title = "Fall Recovery",
    Desc = "Return your character above the map if it falls below Y = -100",
    Default = false,
    Callback = function(value)
        fallRecoveryEnabled = value
        if fallRecoveryConnection then
            fallRecoveryConnection:Disconnect()
            fallRecoveryConnection = nil
        end
        if value then
            fallRecoveryConnection = RunService.Heartbeat:Connect(function()
                if not fallRecoveryEnabled then return end
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and root.Position.Y < -100 then
                    root.CFrame = CFrame.new(root.Position.X, 50, root.Position.Z)
                end
            end)
        end
    end,
})

-- Keep movement values consistent after respawning.
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if customWalkSpeedEnabled or customHipHeightEnabled then
        applyMovementSettings()
    end
end)

safetySection:Button({
    Title = "Stop Extra Modules",
    Desc = "Stop candy farming, disable fall recovery, and restore movement defaults",
    Callback = function()
        stopCandyFarm()
        if fallRecoveryConnection then
            fallRecoveryConnection:Disconnect()
            fallRecoveryConnection = nil
        end
        fallRecoveryEnabled = false
        customWalkSpeedEnabled = false
        customHipHeightEnabled = false
        applyMovementSettings()
        uiNotify("Extra Modules", "Extra modules stopped")
    end,
})

uiNotify("MM2 HUB", "Unified interface loaded")

--========================================================
-- PULSEHUB FEATURE ENGINE RE-HOSTED IN THE SAME FOOTAGESUS WINDUI WINDOW
-- Features from the additional PulseHub/Delta/Best/Premium MM2 sources are
-- exposed as WindUI controls below. No module-owned gameplay window is created.
--========================================================
local function installPulseHubWindUI(WindUIRef, SharedWindow, VisualTabRef, UtilityTabRef, FarmTabRef, ExtraTabRef)
    local function tr(s) return tostring(s) end
    local function uiCorner(obj, radius)
        if not obj then return nil end
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = obj
        return corner
    end
    local fovGui
    local function getGuiParent()
        if type(gethui) == "function" then
            local ok, parent = pcall(gethui)
            if ok and parent then return parent end
        end
        return game:GetService("CoreGui")
    end
    local Env = (type(getgenv) == "function" and getgenv()) or _G

--[[
    PulseHub MM2 — standalone build
    UI: black / midnight, rectangular cards, compact controls, blue frost accents.
    Intended for executor environments; features degrade gracefully when optional
    executor APIs (Drawing, hookmetamethod, setfpscap, etc.) are unavailable.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local V3 = Vector3.new
local C3 = Color3.fromRGB
local U2 = UDim2.new
local K = Enum.KeyCode
local hasDrawing = type(Drawing) == "table" or type(Drawing) == "userdata"
local espGui
local canHook = type(hookmetamethod) == "function" and type(getnamecallmethod) == "function"
local canFPS = type(setfpscap) == "function"
local Env = (type(getgenv) == "function" and getgenv()) or _G

local Hub = {
    alive = true,
    startedAt = os.clock(),
    conns = {},
    cleanups = {},
    esp = {},
    backtrack = {},
    xray = {},
    state = {},
    tabs = {},
    controls = {},
    tabButtons = {},
    selectedTab = nil,
    drag = nil,
    rightDown = false,
    lastPing = 0,
    roleCache = {},
    playerRows = {},
    sliderMeta = {},
    antiFlingCollisionState = {},
    antiFlingTeleportGraceUntil = 0,
    antiFlingIgnoreUntil = 0,
    roundStateCache = false,
    roundStateCacheAt = 0,
    roundChangedAt = 0,
    flyBV = nil,
    flyBG = nil,
    flyOldPlatformStand = nil,
    spinAngle = 0,
    spinLast = 0,
    spinOldAutoRotate = nil,
    spinActiveCharacter = nil,
    flingTarget = nil,
    flingBusyUntil = 0,
    musicSound = nil,
    restoreAnimations = {},
    originalLighting = {},
    presetObjects = {},
    createdGui = nil,
    fovDrawing = nil,
    clickFlingConn = nil,
    touchFlingConn = nil,
    silentHookInstalled = false,
}

Hub.state = {
    -- Visuals
    esp = false, espBox = false, espSkel = false, espTracer = false,
    gunEsp = false, xray = false, lblRole = false, lblName = false, lblDist = false, lblWeapon = false,
    chams = false, chamsTrans = 55, backtrack = false, backMs = 150,
    trail = false, trailColor = "Blue", trailLife = 1,
    bloom = false, bloomInt = 0.8, bloomSize = 24, bloomThr = 0.9,
    atmo = false, atmoDensity = 30, atmoHaze = 1,
    rays = false, raysInt = 0.25, raysSpread = 0.8,
    blur = false, blurSize = 12,
    dof = false, dofFar = 50, dofFocus = 60, dofRadius = 30,
    fog = false, fogEnd = 800,
    -- Combat
    aimOn = false, aimVersion = "Silent", aimType = "Auto role", aimSpeed = 35,
    aimReturn = false, predict = 60, aimWall = false, fovShow = false, fovRadius = 160,
    killAura = false, killRadius = 18, killMode = "All",
    autoPickup = false, autoShoot = false, autoKill = false, autoFlingSheriff = false,
    autoWin = false, antiThrow = false,
    bringMurderer = false, bringSheriff = false, bringInnocent = false,
    staticMurderer = false, bringGunDrop = false, bringDistance = 3,
    fullbright = false,
    knifeAim = false, knifeWall = false, knifeLead = 80, knifeAuto = false,
    desync = false, desyncMode = "Jitter", desyncRadius = 6, desyncSpeed = 20,
    faceThreat = false, resolver = false,
    -- Player
    farm = false, farmVersion = "Tween", farmSpeed = 40, farmReset = false,
    farmAvoid = false, farmFling = false,
    noclip = false, infJump = false, antiFling = false, fly = false, spin = false,
    bhop = false, bhopSpeed = 28, bhopAccel = 0, bhopAutoJump = true, invis = false, bombPower = 90, flySpeed = 50, spinSpeed = 20,
    -- Animation / troll
    packSel = "Ninja", packSpeed = 1, emoteSel = "Wave", emoteSpeed = 1,
    emoteHold = false, animAuto = false, toy = "Halo", toyOn = false,
    korblox = false, headless = false, speedOn = false, walkSpeed = 40,
    jumpOn = false, jumpPower = 70, touchFling = false, clickFling = false,
    orbit = false, orbitTarget = "Murderer", orbitRadius = 8, orbitSpeed = 4,
    -- Music / misc
    music = false, musicDelay = 3, musicVol = 50, songs = {},
    fpsUnlock = false, fpsCap = 240, optTex = false, optPart = false,
    optShadow = false, optRefl = false, optLow = false, antiAfk = false,
    theme = "Midnight", uiScale = 100, stretch = false, font = "Gotham",
    textSize = 0, lang = "Русский", menuKey = K.RightShift, menuKeyName = "RightShift",
    lightingPreset = "None", selectedPlayer = "", flingPower = 295, flingUp = 125, flingSpin = 16000, flingDuration = 1.65, antiFlingVelocity = 105, antiFlingAngular = 38, antiFlingJump = 48,
    preset_night_brightness = 1.0, preset_night_clock = 0.5, preset_night_exposure = -0.2,
    preset_realism_brightness = 2.0, preset_realism_clock = 14, preset_realism_exposure = 0,
    preset_future_brightness = 3.0, preset_future_clock = 16, preset_future_exposure = 0.35,
    preset_studio_brightness = 2.5, preset_studio_clock = 12, preset_studio_exposure = 0.15,
    preset_desert_brightness = 2.4, preset_desert_clock = 15, preset_desert_exposure = 0.1,
    preset_clean_brightness = 2.2, preset_clean_clock = 13, preset_clean_exposure = 0,
}

-- Automatic config persistence. No manual config creation is required.
-- Uses the executor filesystem when available; otherwise falls back to a session-only env table.
Hub.config = {
    path = "PulseHub/MM2.json",
    fallbackPath = "PulseHub_MM2.json",
    loaded = false,
    dirty = false,
}

local function configFS()
    return type(readfile) == "function" and type(writefile) == "function"
end

local function ensureConfigFolder()
    if type(makefolder) ~= "function" then return end
    if type(isfolder) == "function" then
        local ok, yes = pcall(isfolder, "PulseHub")
        if ok and yes then return end
    end
    pcall(makefolder, "PulseHub")
end

local function configSnapshot()
    local out = {}
    for k,v in pairs(Hub.state) do
        local tv = type(v)
        if tv == "boolean" or tv == "number" or tv == "string" then
            out[k] = v
        elseif tv == "table" and k == "songs" then
            out[k] = {}
            for i,x in ipairs(v) do out[k][i] = tostring(x) end
        end
    end
    out._version = 2
    return out
end

local function applyLoadedConfig(data)
    if type(data) ~= "table" then return end
    for k,v in pairs(data) do
        if k ~= "_version" and Hub.state[k] ~= nil then
            if type(Hub.state[k]) == type(v) then Hub.state[k] = v end
        end
    end
    Hub.state.menuKey = ({RightShift=K.RightShift,Insert=K.Insert,Home=K.Home,End=K.End,Delete=K.Delete})[Hub.state.menuKeyName] or K.RightShift
end

local function loadConfig()
    if Env.PulseHubConfig and type(Env.PulseHubConfig) == "table" then
        applyLoadedConfig(Env.PulseHubConfig)
        Hub.config.loaded = true
        return
    end
    if configFS() then
        ensureConfigFolder()
        local paths = {Hub.config.path, Hub.config.fallbackPath}
        for _,path in ipairs(paths) do
            local exists = true
            if type(isfile) == "function" then
                local ok, val = pcall(isfile, path)
                exists = ok and val or false
            end
            if exists then
                local okRead, raw = pcall(readfile, path)
                if okRead and type(raw) == "string" and #raw > 2 then
                    local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
                    if okDecode and type(data) == "table" then
                        applyLoadedConfig(data)
                        Hub.config.loaded = true
                        return
                    end
                end
            end
        end
    end
end

local function saveConfig()
    local snap = configSnapshot()
    Env.PulseHubConfig = snap
    if not configFS() then return false end
    ensureConfigFolder()
    local okEncode, raw = pcall(function() return HttpService:JSONEncode(snap) end)
    if not okEncode or type(raw) ~= "string" then return false end
    local ok = pcall(writefile, Hub.config.path, raw)
    if not ok then ok = pcall(writefile, Hub.config.fallbackPath, raw) end
    Hub.config.dirty = false
    return ok
end

loadConfig()
-- Prevent legacy saved post-processing from making the screen blurry after injection.
Hub.state.blur=false; Hub.state.dof=false; Hub.state.bloom=false; Hub.state.atmo=false; Hub.state.rays=false; Hub.state.fog=false
Hub.uiBaseSize = {}

local function pushConn(c)
    if c then Hub.conns[#Hub.conns + 1] = c end
    return c
end

local function pushCleanup(f)
    if f then Hub.cleanups[#Hub.cleanups + 1] = f end
    return f
end

local function safe(f, ...)
    if type(f) ~= "function" then return nil end
    local a = table.pack(pcall(f, ...))
    if a[1] then return table.unpack(a, 2, a.n) end
    return nil
end

local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PulseHub MM2", Text = tostring(msg), Duration = 3
        })
    end)
end

local function aliveCharacter(p)
    local c = p and p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    return c, h, r
end

local function livingCharacter(p)
    local c, h, r = aliveCharacter(p)
    if not c or not h or not r or h.Health <= 0 or not c:IsDescendantOf(workspace) then return nil end
    return c, h, r
end

local function hasTool(p, name)
    local c = p and p.Character
    local b = p and p:FindFirstChildOfClass("Backpack")
    return (c and c:FindFirstChild(name)) or (b and b:FindFirstChild(name))
end

local function roleOf(p)
    if not p then return "Unknown" end
    local now=os.clock()
    if Hub.roleCache[p] and Hub.roleCache[p].t and now-Hub.roleCache[p].t<0.18 then return Hub.roleCache[p].r end
    local function normalize(v)
        if type(v)~="string" then return nil end
        local x=v:lower()
        if x:find("murder",1,true) then return "Murderer" end
        if x:find("sheriff",1,true) then return "Sheriff" end
        if x:find("hero",1,true) then return "Hero" end
        if x:find("innocent",1,true) then return "Innocent" end
        return nil
    end
    local role
    pcall(function() role=normalize(p.Team and p.Team.Name) end)
    if not role then
        for _,key in ipairs({"Role","RoleName","PlayerRole","CurrentRole"}) do
            local ok,v=pcall(function() return p:GetAttribute(key) end)
            if ok then role=normalize(v) end
            if not role and p.Character then
                ok,v=pcall(function() return p.Character:GetAttribute(key) end)
                if ok then role=normalize(v) end
            end
            if role then break end
        end
    end
    if not role and hasTool(p,"Knife") then role="Murderer" end
    if not role and hasTool(p,"Gun") then role="Sheriff" end
    role=role or "Innocent"
    Hub.roleCache[p]={r=role,t=now}
    return role
end

local function roleColor(role)
    if role == "Murderer" then return C3(247, 92, 108) end
    if role == "Sheriff" then return C3(100, 164, 255) end
    if role == "Hero" then return C3(255, 204, 95) end
    return C3(180, 212, 232)
end

local function nearestTarget(filter, fromPos)
    local origin = fromPos or (select(3, aliveCharacter(LocalPlayer)) and select(3, aliveCharacter(LocalPlayer)).Position)
    if not origin then return nil end
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (not filter or filter(p)) then
            local c, h, r = aliveCharacter(p)
            if c and h and h.Health > 0 and r then
                local d = (r.Position - origin).Magnitude
                if d < bestD then best, bestD = p, d end
            end
        end
    end
    return best, bestD
end

local function playersRoleTarget()
    local meRole = roleOf(LocalPlayer)
    if Hub.state.aimType == "Murderer" then
        return nearestTarget(function(p) return roleOf(p) == "Murderer" end)
    elseif Hub.state.aimType == "Sheriff" then
        return nearestTarget(function(p) return roleOf(p) == "Sheriff" end)
    elseif Hub.state.aimType == "Closest to me" then
        return nearestTarget()
    elseif Hub.state.aimType == "Closest to cursor" then
        local best, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c, h, r = aliveCharacter(p)
                if c and h and h.Health > 0 and r then
                    local vp, onScreen = Camera:WorldToViewportPoint(r.Position)
                    if onScreen then
                        local d = (Vector2.new(vp.X, vp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if d < dist then best, dist = p, d end
                    end
                end
            end
        end
        return best, dist
    else
        if meRole == "Sheriff" or hasTool(LocalPlayer, "Gun") then
            return nearestTarget(function(p) return roleOf(p) == "Murderer" end)
        elseif meRole == "Murderer" then
            return nearestTarget(function(p) return roleOf(p) == "Sheriff" end)
        end
        return nearestTarget(function(p) return roleOf(p) == "Murderer" end)
    end
end

local function predictedPosition(p, ms)
    local _, _, r = aliveCharacter(p)
    if not r then return nil end
    local lead = math.max(0, ms or 0) / 1000
    local v = r.AssemblyLinearVelocity or r.Velocity or V3(0, 0, 0)
    if Hub.state.resolver then
        local hist = Hub.backtrack[p]
        if hist and #hist >= 2 then
            local a, b = hist[#hist-1], hist[#hist]
            local dt = math.max(0.01, b.t - a.t)
            v = (b.cf.Position - a.cf.Position) / dt
        end
    end
    return r.Position + v * lead
end

local function visibleFrom(origin, targetPos, targetCharacter)
    local d = targetPos - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local hit = workspace:Raycast(origin, d, params)
    return not hit or (targetCharacter and hit.Instance:IsDescendantOf(targetCharacter))
end

local function targetByFov()
    local origin = Camera.CFrame.Position
    local best, bestPx = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c, h, r = aliveCharacter(p)
            if c and h and h.Health > 0 and r then
                local vp, on = Camera:WorldToViewportPoint(r.Position)
                if on then
                    local px = (Vector2.new(vp.X, vp.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if px <= Hub.state.fovRadius and px < bestPx then
                        if not Hub.state.aimWall or visibleFrom(origin, r.Position, c) then
                            best, bestPx = p, px
                        end
                    end
                end
            end
        end
    end
    return best
end

local function findRemoteLike(root, names, className)
    if not root then return nil end
    for _, n in ipairs(names) do
        local obj = root:FindFirstChild(n, true)
        if obj and (not className or obj:IsA(className)) then return obj end
    end
    for _, obj in ipairs(root:GetDescendants()) do
        if (not className or obj:IsA(className)) then
            local low = obj.Name:lower()
            for _, n in ipairs(names) do
                if low:find(n:lower(), 1, true) then return obj end
            end
        end
    end
    return nil
end

local function equippedGun()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("Gun")
end

local function equippedKnife()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("Knife")
end

local function shootAt(p)
    local gun = equippedGun()
    if not gun then
        local b = LocalPlayer:FindFirstChildOfClass("Backpack")
        local g = b and b:FindFirstChild("Gun")
        local _, h = aliveCharacter(LocalPlayer)
        if g and h then safe(function() h:EquipTool(g) end); task.wait() end
        gun = equippedGun()
    end
    if not gun then return false end
    local pos = predictedPosition(p, Hub.state.predict)
    if not pos then return false end
    local rf = findRemoteLike(gun, {"CreateBeam", "RemoteFunction", "Shoot", "Fire"}, "RemoteFunction")
    if rf and rf:IsA("RemoteFunction") then
        local ok = pcall(function() rf:InvokeServer(1, pos, "AH2") end)
        if ok then return true end
    end
    local re = findRemoteLike(gun, {"Shoot", "Fire", "CreateBeam"}, "RemoteEvent")
    if re and re:IsA("RemoteEvent") then
        local ok = pcall(function() re:FireServer(1, pos, "AH2") end)
        if ok then return true end
    end
    local click = gun:FindFirstChildOfClass("Tool")
    if click and click.Activate then
        safe(function() click:Activate() end)
        return true
    end
    return false
end

local function knifeThrowAt(p)
    local knife = equippedKnife()
    if not knife then
        local b = LocalPlayer:FindFirstChildOfClass("Backpack")
        local k = b and b:FindFirstChild("Knife")
        local _, h = aliveCharacter(LocalPlayer)
        if k and h then safe(function() h:EquipTool(k) end); task.wait() end
        knife = equippedKnife()
    end
    if not knife then return false end
    local pos = predictedPosition(p, Hub.state.knifeLead)
    if not pos then return false end
    local remote = findRemoteLike(knife, {"CreateBeam", "Throw", "RemoteFunction", "KnifeThrow"}, "RemoteFunction")
    if remote and remote:IsA("RemoteFunction") then
        local ok = pcall(function() remote:InvokeServer(1, pos, "AH2") end)
        if ok then return true end
    end
    local ev = findRemoteLike(knife, {"Throw", "KnifeThrow", "Remote"}, "RemoteEvent")
    if ev and ev:IsA("RemoteEvent") then
        local ok = pcall(function() ev:FireServer("Down", pos) end)
        if ok then return true end
    end
    local localScript = knife:FindFirstChild("KnifeLocal", true)
    local stab = localScript and findRemoteLike(localScript, {"Throw", "RemoteFunction"}, "RemoteFunction")
    if stab and stab:IsA("RemoteFunction") then
        return pcall(function() stab:InvokeServer(1, pos, "AH2") end)
    end
    return false
end

local function stab()
    local knife = equippedKnife()
    local remote = knife and knife:FindFirstChild("Stab")
    if remote and remote:IsA("RemoteEvent") then return pcall(function() remote:FireServer("Down") end) end
    remote = knife and findRemoteLike(knife, {"Stab", "Remote"}, "RemoteEvent")
    if remote then return pcall(function() remote:FireServer("Down") end) end
    return false
end

local function findGunDrop(force)
    local now=os.clock()
    if not force and Hub.gunDropCache and Hub.gunDropCache.Parent and now-(Hub.gunDropCacheAt or 0)<0.25 then
        return Hub.gunDropCache
    end
    local direct = workspace:FindFirstChild("GunDrop", true)
    if direct then
        if direct:IsA("BasePart") then
            Hub.gunDropCache=direct; Hub.gunDropCacheAt=now; return direct
        end
        if direct:IsA("Model") then
            local part=direct.PrimaryPart or direct:FindFirstChildWhichIsA("BasePart", true)
            if part then
                Hub.gunDropCache=direct; Hub.gunDropPart=part; Hub.gunDropCacheAt=now; return direct
            end
        end
    end
    for _,d in ipairs(workspace:GetDescendants()) do
        if d.Name:lower():find("gundrop",1,true) then
            if d:IsA("BasePart") then
                Hub.gunDropCache=d; Hub.gunDropPart=d; Hub.gunDropCacheAt=now; return d
            elseif d:IsA("Model") then
                local part=d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    Hub.gunDropCache=d; Hub.gunDropPart=part; Hub.gunDropCacheAt=now; return d
                end
            end
        end
    end
    Hub.gunDropCache=nil; Hub.gunDropPart=nil; Hub.gunDropCacheAt=now
    return nil
end

local function gunDropPart(drop)
    if not drop then return nil end
    if drop:IsA("BasePart") then return drop end
    if drop:IsA("Model") then
        return drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart", true)
    end
    return drop:FindFirstChildWhichIsA("BasePart", true)
end

local function pickupGun()
    local now=os.clock()
    if Hub._gunPickupNext and now<Hub._gunPickupNext then return false end
    Hub._gunPickupNext=now+0.20
    if not livingCharacter(LocalPlayer) or hasTool(LocalPlayer,"Gun") then return hasTool(LocalPlayer,"Gun") ~= nil end
    local drop=findGunDrop()
    local c,h,r=livingCharacter(LocalPlayer)
    local part=gunDropPart(drop)
    if not drop or not part or not c or not h or not r then return false end

    local oldCF=r.CFrame
    local restore=true
    Hub.antiFlingIgnoreUntil=math.max(Hub.antiFlingIgnoreUntil or 0,now+0.55)

    local function gotGun()
        return hasTool(LocalPlayer,"Gun") ~= nil
    end
    local function tryPrompts()
        for _,obj in ipairs(drop:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and type(fireproximityprompt)=="function" then
                pcall(fireproximityprompt,obj,1,true)
            elseif obj:IsA("ClickDetector") and type(fireclickdetector)=="function" then
                pcall(fireclickdetector,obj,0)
            end
        end
    end
    local function tryTouch()
        if type(firetouchinterest)~="function" then return end
        local parts={}
        if drop:IsA("BasePart") then parts[#parts+1]=drop end
        for _,obj in ipairs(drop:GetDescendants()) do
            if obj:IsA("BasePart") then parts[#parts+1]=obj end
        end
        for _,obj in ipairs(parts) do
            pcall(firetouchinterest,r,obj,0)
            pcall(firetouchinterest,r,obj,1)
        end
    end

    for _=1,3 do
        if gotGun() then restore=false; break end
        tryPrompts(); tryTouch()
        if gotGun() then restore=false; break end
        local cf
        if drop:IsA("Model") then pcall(function() cf=drop:GetPivot() end) else cf=part.CFrame end
        if cf and (r.Position-cf.Position).Magnitude>5 then
            pcall(function() r.CFrame=cf+V3(0,1.75,0) end)
            task.wait(0.07)
        end
        tryTouch(); tryPrompts()
        if gotGun() then restore=false; break end
        task.wait(0.05)
    end
    if restore and r.Parent and h.Health>0 then pcall(function() r.CFrame=oldCF end) end
    return gotGun()
end

local function antiFlingStep()
    local nowTick=os.clock()
    if Hub._antiNext and nowTick<Hub._antiNext then return end
    Hub._antiNext=nowTick+0.05
    if not Hub.state.antiFling then
        for d,old in pairs(Hub.antiFlingCollisionState or {}) do
            if d and d.Parent and d:IsA("BasePart") then pcall(function() d.CanCollide=old end) end
        end
        Hub.antiFlingSafeCF=nil; Hub.antiFlingLastPos=nil; Hub.antiFlingLastTime=nil
        Hub.antiFlingRecoverUntil=0; Hub.antiFlingShieldUntil=0; Hub.antiFlingTeleportGraceUntil=0
        Hub.antiFlingCollisionState={}
        return
    end
    local c,h,r=livingCharacter(LocalPlayer); if not c or not h or not r then return end
    local now=os.clock()
    if Hub.state.fly then
        Hub.antiFlingSafeCF=r.CFrame; Hub.antiFlingLastPos=r.Position; Hub.antiFlingLastTime=now
        return
    end
    if Hub.activeFlingConn or now<(Hub.antiFlingIgnoreUntil or 0) or now<(Hub.antiFlingTeleportGraceUntil or 0) then
        Hub.antiFlingSafeCF=r.CFrame
        Hub.antiFlingLastPos=r.Position
        Hub.antiFlingLastTime=now
        return
    end

    local pos=r.Position
    local vel=r.AssemblyLinearVelocity
    local ang=r.AssemblyAngularVelocity
    local vmag=vel.Magnitude
    local amag=ang.Magnitude
    local last=Hub.antiFlingLastPos
    local dt=Hub.antiFlingLastTime and math.max(0.008,now-Hub.antiFlingLastTime) or 0.016
    local moved=last and (pos-last).Magnitude or 0
    local movedSpeed=moved/dt
    local vThreshold=math.max(35,tonumber(Hub.state.antiFlingVelocity) or 105)
    local aThreshold=math.max(10,tonumber(Hub.state.antiFlingAngular) or 38)
    local jumpThreshold=math.max(10,tonumber(Hub.state.antiFlingJump) or 48)
    local normalWalkSpeed=Hub.state.speedOn and math.max(16,tonumber(Hub.state.walkSpeed) or 40) or 16
    local velocityLimit=math.max(vThreshold,normalWalkSpeed*1.45)

    -- Large CFrame jumps with ordinary physics are teleports/round transitions, not flings.
    local teleportDistance=math.max(60,jumpThreshold*2.2)
    local teleportLike=moved>teleportDistance and vmag<vThreshold*1.20 and amag<aThreshold*1.35
    if teleportLike then
        Hub.antiFlingSafeCF=r.CFrame
        Hub.antiFlingTeleportGraceUntil=now+0.40
        Hub.antiFlingLastPos=pos
        Hub.antiFlingLastTime=now
        return
    end

    -- Do not use displacement alone. Normal walking/jumping is allowed; a fling needs violent physics too.
    local violent = (vmag>velocityLimit and movedSpeed>velocityLimit*0.55)
        or (amag>aThreshold and movedSpeed>70)
        or (vmag>velocityLimit*1.25 and movedSpeed>105)
    local stable = vmag<vThreshold*0.55 and amag<aThreshold*0.85 and movedSpeed<math.max(85,jumpThreshold*2)
    if violent and now>=(Hub.antiFlingRecoverUntil or 0) then
        if Hub.antiFlingSafeCF then pcall(function() r.CFrame=Hub.antiFlingSafeCF end) end
        pcall(function()
            r.AssemblyLinearVelocity=V3(0,0,0)
            r.AssemblyAngularVelocity=V3(0,0,0)
            h.PlatformStand=false
            h.Sit=false
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
        Hub.antiFlingShieldUntil=now+0.20
        Hub.antiFlingRecoverUntil=now+0.13
    elseif stable then
        Hub.antiFlingSafeCF=r.CFrame
    end
    if (Hub.antiFlingShieldUntil or 0)>now then
        for _,d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                if Hub.antiFlingCollisionState[d]==nil then Hub.antiFlingCollisionState[d]=d.CanCollide end
                pcall(function() d.CanCollide=false end)
            end
        end
    elseif Hub.antiFlingShieldUntil and Hub.antiFlingShieldUntil>0 and now-Hub.antiFlingShieldUntil>0 then
        for d,old in pairs(Hub.antiFlingCollisionState) do
            if d and d.Parent and d:IsA("BasePart") then pcall(function() d.CanCollide=old end) end
        end
        Hub.antiFlingCollisionState={}
        Hub.antiFlingShieldUntil=0
    end
    Hub.antiFlingLastPos=pos; Hub.antiFlingLastTime=now
end

-- Fling remains a client-side physics attempt. The server may override ownership or movement.
local function fling(p, seconds)
    if not p or p==LocalPlayer then return false end
    local _,mh,myr=livingCharacter(LocalPlayer); local tc,th,tr=livingCharacter(p)
    if not mh or not myr or not tc or not th or not tr then return false end
    local now=os.clock()
    if Hub.activeFlingConn and Hub.flingTarget==p and now<(Hub.flingBusyUntil or 0) then return true end
    if Hub.activeFlingConn then pcall(function() Hub.activeFlingConn:Disconnect() end); Hub.activeFlingConn=nil end
    local startCF=myr.CFrame
    local oldAuto=mh.AutoRotate; local oldCollide=myr.CanCollide; local oldMass=myr.Massless; local oldState=mh:GetState()
    local proxy=Instance.new("Part")
    proxy.Name="PulseFlingProxy"; proxy.Size=V3(4.6,4.6,4.6); proxy.Transparency=1; proxy.CanCollide=true; proxy.CanTouch=true; proxy.CanQuery=false; proxy.Massless=false; proxy.CFrame=myr.CFrame; proxy.Parent=myr.Parent
    local weld=Instance.new("WeldConstraint"); weld.Part0=myr; weld.Part1=proxy; weld.Parent=proxy
    local bav
    pcall(function() bav=Instance.new("BodyAngularVelocity"); bav.Name="PulseFlingSpin"; bav.MaxTorque=V3(math.huge,math.huge,math.huge); bav.AngularVelocity=V3(0,Hub.state.flingSpin or 16000,0); bav.P=175000; bav.Parent=myr end)
    pcall(function() mh.AutoRotate=false; mh:ChangeState(Enum.HumanoidStateType.Physics); myr.CanCollide=true; myr.Massless=false end)
    local stopAt=now+(seconds or Hub.state.flingDuration or 1.35)
    local warmupAt=now+0.10
    Hub.flingTarget=p; Hub.flingBusyUntil=stopAt+0.12; Hub.antiFlingIgnoreUntil=stopAt+0.55
    local conn; local finished=false
    local function finish(restorePosition)
        if finished then return end; finished=true
        pcall(function() if conn then conn:Disconnect() end end)
        pcall(function() weld:Destroy(); proxy:Destroy(); if bav then bav:Destroy() end end)
        Hub.activeFlingConn=nil; Hub.flingTarget=nil; Hub.flingBusyUntil=0
        pcall(function()
            myr.CanCollide=oldCollide; myr.Massless=oldMass; mh.AutoRotate=oldAuto
            if restorePosition and mh.Health>0 and myr.Parent then
                myr.CFrame=startCF; myr.AssemblyLinearVelocity=V3(0,0,0); myr.AssemblyAngularVelocity=V3(0,0,0)
            end
            if mh.Health>0 and oldState~=Enum.HumanoidStateType.Dead then mh:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end)
    end
    conn=RunService.Heartbeat:Connect(function()
        local _,ah,me=livingCharacter(LocalPlayer); local _,at,target=livingCharacter(p)
        if not Hub.alive or os.clock()>stopAt or not ah or not me or not at or not target then finish(true); return end
        local delta=target.Position-me.Position; local dist=delta.Magnitude
        local dir=dist>0.1 and delta.Unit or V3(1,0,0)
        local tangent=V3(-dir.Z,0,dir.X)
        local desired=target.Position-dir*2.35+V3(0,1.20,0)
        pcall(function()
            me.CFrame=CFrame.lookAt(desired,target.Position)
            if os.clock()>=warmupAt then
                local spinT=os.clock()*math.max(26,(Hub.state.flingSpin or 16000)/300)
                local orbit=(tangent*math.cos(spinT)+dir*math.sin(spinT))*math.clamp((Hub.state.flingPower or 295)*0.50,115,205)
                local v=dir*(Hub.state.flingPower or 295)+orbit+V3(0,Hub.state.flingUp or 125,0)
                me.AssemblyLinearVelocity=v; me.AssemblyAngularVelocity=V3(0,Hub.state.flingSpin or 16000,0)
                me.Velocity=v
                target.AssemblyLinearVelocity=dir*-(Hub.state.flingPower or 295)+V3(0,Hub.state.flingUp or 125,0)
                target.AssemblyAngularVelocity=V3(0,Hub.state.flingSpin or 16000,0)
            end
        end)
    end)
    Hub.activeFlingConn=conn
    pushCleanup(function() finish(true) end)
    return true
end

local function selectedPlayer()
    local uid = tonumber(Hub.state.selectedPlayer)
    if not uid then return nil end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.UserId == uid then return p end
    end
    return nil
end

local function mapModel()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and (obj:FindFirstChild("CoinContainer", true) or obj:FindFirstChild("Coin_Server", true)) then
            return obj
        end
    end
    return nil
end

local function coinParts()
    local now=os.clock(); if Hub.coinCache and Hub.coinCacheAt and now-Hub.coinCacheAt<0.18 then return Hub.coinCache end
    local list = {}
    local map = mapModel()
    if map then
        local cc = map:FindFirstChild("CoinContainer", true)
        if cc then
            for _, d in ipairs(cc:GetDescendants()) do
                if d:IsA("BasePart") and d.Name == "Coin_Server" then list[#list + 1] = d end
            end
        end
    end
    if #list == 0 then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name == "Coin_Server" then list[#list + 1] = d end
        end
    end
    Hub.coinCache=list; Hub.coinCacheAt=now
    return list
end

local function bagCount()
    local c = LocalPlayer.Character
    local b = LocalPlayer:FindFirstChildOfClass("Backpack")
    local candidates = {LocalPlayer, c, b}
    for _, obj in ipairs(candidates) do
        if obj then
            for _, n in ipairs({"Coin", "Coins", "CoinAmount", "Bag", "BagValue"}) do
                local v = obj:GetAttribute(n)
                if type(v) == "number" then return v end
                local child = obj:FindFirstChild(n)
                if child and child:IsA("NumberValue") then return child.Value end
            end
        end
    end
    return nil
end

local function roundActive(force)
    local now=os.clock()
    if not force and now-(Hub.roundStateCacheAt or 0)<0.25 then return Hub.roundStateCache end
    local active=false
    local pg=LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _,d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") then
                local txt=d.Text:lower()
                if txt:find("in round",1,true) or txt:find("your murderer",1,true) or txt:find("innocent",1,true) then active=true; break end
            end
        end
    end
    if not active then
        for _,obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and (obj:FindFirstChild("CoinContainer",true) or obj:FindFirstChild("Coin_Server",true)) then
                active=true; break
            end
        end
        if not active then active=#coinParts()>0 end
    end
    Hub.roundStateCache=active; Hub.roundStateCacheAt=now
    return active
end

local function playerRoundState(p, globalRound)
    if not globalRound then return "Lobby" end
    local _,h,r=aliveCharacter(p)
    if not h or not r or h.Health<=0 then return "Spectator" end
    return "In round"
end

local function startFly()
    if Hub.flyConn then return end
    local c,h,r=aliveCharacter(LocalPlayer)
    if not c or not h or not r then return end
    Hub.flyOldPlatformStand=h.PlatformStand
    pcall(function() h.PlatformStand=true; h.AutoRotate=false end)
    Hub.flyBV=Instance.new("BodyVelocity")
    Hub.flyBV.Name="PulseFlyVelocity"; Hub.flyBV.MaxForce=V3(math.huge,math.huge,math.huge); Hub.flyBV.P=35000; Hub.flyBV.Velocity=V3(0,0,0); Hub.flyBV.Parent=r
    Hub.flyBG=Instance.new("BodyGyro")
    Hub.flyBG.Name="PulseFlyGyro"; Hub.flyBG.MaxTorque=V3(math.huge,math.huge,math.huge); Hub.flyBG.P=28000; Hub.flyBG.D=850; Hub.flyBG.CFrame=r.CFrame; Hub.flyBG.Parent=r
    Hub.flyConn=RunService.RenderStepped:Connect(function()
        if not Hub.alive or not Hub.state.fly then return end
        local _,hh,rr=aliveCharacter(LocalPlayer)
        if not hh or not rr then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        local dir=V3(0,0,0)
        if UIS:IsKeyDown(K.W) then dir=dir+cam.CFrame.LookVector end
        if UIS:IsKeyDown(K.S) then dir=dir-cam.CFrame.LookVector end
        if UIS:IsKeyDown(K.A) then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(K.D) then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(K.Space) then dir=dir+V3(0,1,0) end
        if UIS:IsKeyDown(K.LeftControl) then dir=dir-V3(0,1,0) end
        if dir.Magnitude>0 then
            local v=dir.Unit*(tonumber(Hub.state.flySpeed) or 50)
            if Hub.flyBV and Hub.flyBV.Parent then Hub.flyBV.Velocity=v end
        elseif Hub.flyBV and Hub.flyBV.Parent then
            Hub.flyBV.Velocity=V3(0,0,0)
        end
        if Hub.flyBG and Hub.flyBG.Parent then
            Hub.flyBG.CFrame=CFrame.lookAt(rr.Position,rr.Position+cam.CFrame.LookVector)
        end
    end)
    pushCleanup(function()
        pcall(function() if Hub.flyConn then Hub.flyConn:Disconnect() end end)
        pcall(function() if Hub.flyBV then Hub.flyBV:Destroy() end end)
        pcall(function() if Hub.flyBG then Hub.flyBG:Destroy() end end)
    end)
end

local function stopFly()
    if Hub.flyConn then pcall(function() Hub.flyConn:Disconnect() end); Hub.flyConn=nil end
    pcall(function() if Hub.flyBV then Hub.flyBV:Destroy() end end); Hub.flyBV=nil
    pcall(function() if Hub.flyBG then Hub.flyBG:Destroy() end end); Hub.flyBG=nil
    local _,h=aliveCharacter(LocalPlayer)
    if h then pcall(function() h.PlatformStand=Hub.flyOldPlatformStand or false; h.AutoRotate=not Hub.state.spin end) end
    Hub.flyOldPlatformStand=nil
end

local function applyNoclip()
    if Hub.noclipConn then return end
    Hub.noclipConn = RunService.Heartbeat:Connect(function()
        if not Hub.state.noclip then return end
        local now=os.clock(); if Hub._noclipNext and now<Hub._noclipNext then return end; Hub._noclipNext=now+0.08
        local c=LocalPlayer.Character
        if c then for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") and d.CanCollide then pcall(function() d.CanCollide=false end) end end end
    end)
    pushCleanup(function() pcall(function() Hub.noclipConn:Disconnect() end) end)
end

local function resetNoclip()
    local c = LocalPlayer.Character
    if c then for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide = true end end end
end

local function setXray(on)
    Hub.state.xray = on
    if Hub.xrayConn then pcall(function() Hub.xrayConn:Disconnect() end); Hub.xrayConn=nil end
    if on then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and not d:IsDescendantOf(LocalPlayer.Character) then
                if Hub.xray[d] == nil then Hub.xray[d] = d.LocalTransparencyModifier end
                d.LocalTransparencyModifier = math.max(d.LocalTransparencyModifier, 0.55)
            end
        end
        Hub.xrayConn = workspace.DescendantAdded:Connect(function(d)
            if Hub.alive and Hub.state.xray and d:IsA("BasePart") and not d:IsDescendantOf(LocalPlayer.Character) then
                Hub.xray[d] = d.LocalTransparencyModifier
                d.LocalTransparencyModifier = math.max(d.LocalTransparencyModifier, 0.55)
            end
        end)
        pushCleanup(function() if Hub.xrayConn then pcall(function() Hub.xrayConn:Disconnect() end); Hub.xrayConn=nil end end)
    else
        for d, old in pairs(Hub.xray) do
            if d and d.Parent then pcall(function() d.LocalTransparencyModifier = old end) end
        end
        Hub.xray = {}
    end
end

local function destroyName(parent, names)
    for _, n in ipairs(names) do
        local o = parent:FindFirstChild(n)
        if o then pcall(function() o:Destroy() end) end
    end
end

local function clearEspFor(p)
    local e=Hub.esp[p]; if not e then return end
    if e.gui then pcall(function() e.gui:Destroy() end) end
    if e.tracerBeam then pcall(function() e.tracerBeam:Destroy() end) end
    if e.skel then for _,x in ipairs(e.skel) do pcall(function() if x.beam then x.beam:Destroy() end end); pcall(function() if x.a then x.a:Destroy() end end); pcall(function() if x.b then x.b:Destroy() end end) end end
    Hub.esp[p]=nil
end
local ESP_BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"UpperTorso","Left Arm"},{"UpperTorso","Right Arm"},{"LowerTorso","Left Leg"},{"LowerTorso","Right Leg"}}
local function playerFromPart(part)
    if typeof(part)~="Instance" then return nil end
    local x=part
    while x and x~=workspace do
        if x:IsA("Model") then local p=Players:GetPlayerFromCharacter(x); if p then return p end end
        x=x.Parent
    end
    return nil
end
local function ensureGuiEsp(p)
    local e=Hub.esp[p]; if e and e.gui and e.gui.Parent then return e end
    e={skel={}}; if not espGui or not espGui.Parent then return e end
    local g=Instance.new("BillboardGui"); g.Name="PulseESP_"..tostring(p.UserId); g.ResetOnSpawn=false; g.AlwaysOnTop=true; g.LightInfluence=0; g.Size=UDim2.fromOffset(78,108); g.StudsOffset=Vector3.new(0,1.65,0); g.MaxDistance=10000; g.Parent=espGui; e.gui=g
    local box=Instance.new("Frame"); box.Name="Box"; box.BackgroundTransparency=1; box.Size=U2(1,-6,1,-6); box.Position=U2(0,3,0,3); box.Parent=g; uiCorner(box,5); e.box=box
    local st=Instance.new("UIStroke"); st.Thickness=1.4; st.Parent=box; e.boxStroke=st
    local tx=Instance.new("TextLabel"); tx.Name="Info"; tx.BackgroundTransparency=1; tx.Size=U2(1,32,0,38); tx.AnchorPoint=Vector2.new(0.5,1); tx.Position=U2(0.5,0,0,1); tx.Font=Enum.Font.GothamSemibold; tx.TextSize=10; tx.TextStrokeTransparency=0.45; tx.TextWrapped=true; tx.Parent=g; e.text=tx
    Hub.esp[p]=e; return e
end
local function ensureSkeleton(e,c)
    if not c then return end
    for _,pair in ipairs(ESP_BONES) do
        local aPart,bPart=c:FindFirstChild(pair[1]),c:FindFirstChild(pair[2])
        if aPart and bPart then
            local key=pair[1].."|"..pair[2]; local found
            for _,x in ipairs(e.skel) do if x.key==key then found=x break end end
            if not found then
                local a=Instance.new("Attachment"); a.Name="PulseSkelA"; a.Parent=aPart
                local b=Instance.new("Attachment"); b.Name="PulseSkelB"; b.Parent=bPart
                local beam=Instance.new("Beam"); beam.Name="PulseSkeleton"; beam.Attachment0=a; beam.Attachment1=b; beam.Width0=0.025; beam.Width1=0.025; beam.FaceCamera=true; beam.LightEmission=1; beam.Transparency=NumberSequence.new(0.05); beam.Parent=aPart
                e.skel[#e.skel+1]={key=key,a=a,b=b,beam=beam}
            end
        end
    end
end
local function espGuiStep()
    if not Hub.state.esp then
        for _,e in pairs(Hub.esp) do
            if e.gui then e.gui.Enabled=false end; if e.tracerBeam then e.tracerBeam.Enabled=false end
            for _,x in ipairs(e.skel or {}) do if x.beam then x.beam.Enabled=false end end
        end
        return
    end
    local localRoot=select(3,livingCharacter(LocalPlayer))
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local c,h,r=livingCharacter(p); local e=ensureGuiEsp(p)
            if e.gui then e.gui.Enabled=c~=nil; e.gui.Adornee=r end
            if c and h and r then
                local role=roleOf(p); local col=roleColor(role); e.box.Visible=Hub.state.espBox; e.boxStroke.Color=col; e.text.TextColor3=col
                local me=localRoot; local dist=me and math.floor((r.Position-me.Position).Magnitude) or 0; local bits={}
                if Hub.state.lblRole then bits[#bits+1]=tr(role) end
                if Hub.state.lblName then bits[#bits+1]=p.Name end
                if Hub.state.lblDist then bits[#bits+1]=tostring(dist).." st" end
                if Hub.state.lblWeapon then
                    local char = p.Character
                    local backpack = p:FindFirstChildOfClass("Backpack")
                    local weapon = char and (char:FindFirstChild("Knife") or char:FindFirstChild("Gun"))
                    if not weapon and backpack then weapon = backpack:FindFirstChild("Knife") or backpack:FindFirstChild("Gun") end
                    if weapon then bits[#bits+1]="["..weapon.Name.."]" end
                end
                e.text.Text=table.concat(bits,"  •  "); e.text.Visible=#bits>0
                if Hub.state.espTracer and localRoot then
                    local la=localRoot:FindFirstChild("PulseTracerOrigin") or Instance.new("Attachment")
                    la.Name="PulseTracerOrigin"; la.Position=Vector3.new(0,-1.5,0); la.Parent=localRoot; e.tracerLocalAtt=la
                    local ta=r:FindFirstChild("PulseTracerTarget") or Instance.new("Attachment")
                    ta.Name="PulseTracerTarget"; ta.Position=Vector3.new(0,-1.5,0); ta.Parent=r; e.tracerTargetAtt=ta
                    if not e.tracerBeam then
                        local beam=Instance.new("Beam"); beam.Name="PulseTracer"; beam.Attachment0=la; beam.Attachment1=ta; beam.Width0=0.018; beam.Width1=0.018; beam.FaceCamera=true; beam.LightEmission=1; beam.Transparency=NumberSequence.new(0.15); beam.Parent=r; e.tracerBeam=beam
                    end
                    e.tracerBeam.Enabled=true; e.tracerBeam.Color=ColorSequence.new(col)
                elseif e.tracerBeam then e.tracerBeam.Enabled=false end
                if Hub.state.espSkel then ensureSkeleton(e,c) end
                for _,x in ipairs(e.skel or {}) do if x.beam then x.beam.Enabled=Hub.state.espSkel; x.beam.Color=ColorSequence.new(col) end end
            else
                if e.tracerBeam then e.tracerBeam.Enabled=false end; for _,x in ipairs(e.skel or {}) do if x.beam then x.beam.Enabled=false end end
            end
        end
    end
end
local function espStep()
    local now=os.clock(); if Hub._espNext and now<Hub._espNext then return end; Hub._espNext=now+0.03; espGuiStep()
end

local function gunEspStep()
    local now=os.clock(); if Hub._gunNext and now<Hub._gunNext then return end; Hub._gunNext=now+0.15
    if not Hub.state.gunEsp then local old=workspace:FindFirstChild("PulseGun",true); if old then pcall(function() old:Destroy() end) end; return end
    local drop = findGunDrop()
    local h = workspace:FindFirstChild("PulseGun", true)
    if Hub.state.gunEsp and drop then
        if not h or not h:IsA("Highlight") then
            if h then h:Destroy() end
            h = Instance.new("Highlight")
            h.Name = "PulseGun"
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = drop
        end
        h.FillColor = C3(112, 177, 255)
        h.OutlineColor = C3(220, 241, 255)
        h.FillTransparency = 0.25
        h.OutlineTransparency = 0
    elseif h then
        h:Destroy()
    end
end

local function applyChams(p)
    local c = p.Character
    if not c then return end
    local h = c:FindFirstChild("PulseCham")
    if Hub.state.chams then
        if not h then h = Instance.new("Highlight"); h.Name = "PulseCham"; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = c end
        h.FillColor = roleColor(roleOf(p)); h.OutlineColor = roleColor(roleOf(p)); h.FillTransparency = Hub.state.chamsTrans / 100; h.OutlineTransparency = 0.1
    elseif h then h:Destroy() end
end

local function applyTrail()
    local c, _, root = aliveCharacter(LocalPlayer)
    if not c or not root then return end
    local a0 = root:FindFirstChild("PulseTrailA0")
    local a1 = root:FindFirstChild("PulseTrailA1")
    local tr = root:FindFirstChild("PulseTrail")
    if not Hub.state.trail then
        if tr then tr:Destroy() end
        if a0 then a0:Destroy() end
        if a1 then a1:Destroy() end
        return
    end
    if not a0 then a0 = Instance.new("Attachment"); a0.Name = "PulseTrailA0"; a0.Position = V3(0,1,0); a0.Parent = root end
    if not a1 then a1 = Instance.new("Attachment"); a1.Name = "PulseTrailA1"; a1.Position = V3(0,-1,0); a1.Parent = root end
    if not tr then tr = Instance.new("Trail"); tr.Name = "PulseTrail"; tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = Hub.state.trailLife; tr.LightEmission = 0.7; tr.Parent = root end
    tr.Lifetime = Hub.state.trailLife
    if Hub.state.trailColor == "Rainbow" then
        local h = (os.clock() * 0.2) % 1
        tr.Color = ColorSequence.new(Color3.fromHSV(h,0.55,1), Color3.fromHSV((h+0.2)%1,0.55,1))
    elseif Hub.state.trailColor == "Pink" then
        tr.Color = ColorSequence.new(C3(255,170,208), C3(244,202,255))
    elseif Hub.state.trailColor == "White" then
        tr.Color = ColorSequence.new(C3(255,255,255), C3(211,237,255))
    else
        tr.Color = ColorSequence.new(C3(126,191,255), C3(205,235,255))
    end
end

local function applyPostFX()
    local function fx(className, name)
        local o = Lighting:FindFirstChild(name)
        if o and not o:IsA(className) then
            pcall(function() o:Destroy() end)
            o = nil
        end
        if not o then o = Instance.new(className); o.Name = name; o.Parent = Lighting end
        return o
    end

    local bloom = fx("BloomEffect", "PulseBloom")
    bloom.Enabled = Hub.state.bloom
    bloom.Intensity = Hub.state.bloomInt
    bloom.Size = Hub.state.bloomSize
    bloom.Threshold = Hub.state.bloomThr

    -- Atmosphere does not have an Enabled property. Disable it by driving
    -- Density/Haze/Glare to zero while retaining the configured values.
    local atmo = fx("Atmosphere", "PulseAtmosphere")
    atmo.Density = Hub.state.atmo and (Hub.state.atmoDensity / 100) or 0
    atmo.Haze = Hub.state.atmo and Hub.state.atmoHaze or 0
    atmo.Glare = 0

    local rays = fx("SunRaysEffect", "PulseRays")
    rays.Enabled = Hub.state.rays
    rays.Intensity = Hub.state.raysInt
    rays.Spread = Hub.state.raysSpread

    local blur = fx("BlurEffect", "PulseBlur")
    blur.Enabled = Hub.state.blur
    blur.Size = Hub.state.blurSize

    local dof = fx("DepthOfFieldEffect", "PulseDof")
    dof.Enabled = Hub.state.dof
    dof.FarIntensity = Hub.state.dofFar / 100
    dof.FocusDistance = Hub.state.dofFocus
    dof.InFocusRadius = Hub.state.dofRadius

    -- Fog is a Lighting property, not an Atmosphere.Enabled flag.
    if Hub.state.fog then
        pcall(function()
            Lighting.FogStart = 0
            Lighting.FogEnd = math.max(50, Hub.state.fogEnd)
        end)
    elseif Hub.originalLighting.FogEnd then
        pcall(function()
            Lighting.FogEnd = Hub.originalLighting.FogEnd
        end)
        if Hub.originalLighting.FogStart then
            pcall(function()
                Lighting.FogStart = Hub.originalLighting.FogStart
            end)
        end
    end

    -- Keep a single atmosphere object for the main effect; remove the old
    -- duplicate PulseFog object left by earlier builds.
    local oldFog = Lighting:FindFirstChild("PulseFog")
    if oldFog then pcall(function() oldFog:Destroy() end) end
end

local function saveOriginalLighting()
    for _, n in ipairs({"Brightness","ClockTime","ExposureCompensation","FogStart","FogEnd","GlobalShadows","OutdoorAmbient","Ambient"}) do
        Hub.originalLighting[n] = Lighting[n]
    end
end

local function setPreset(id)
    for _, o in pairs(Hub.presetObjects) do pcall(function() o:Destroy() end) end
    Hub.presetObjects = {}
    if not id then
        for k,v in pairs(Hub.originalLighting) do pcall(function() Lighting[k] = v end) end
        return
    end
    local n = id
    local b = tonumber(Hub.state["preset_"..n.."_brightness"]) or 2
    local c = tonumber(Hub.state["preset_"..n.."_clock"]) or 13
    local e = tonumber(Hub.state["preset_"..n.."_exposure"]) or 0
    local ambient, outdoor
    if id == "night" then ambient, outdoor = C3(45,60,90), C3(55,75,105)
    elseif id == "realism" then ambient, outdoor = C3(150,170,190), C3(140,160,180)
    elseif id == "future" then ambient, outdoor = C3(175,225,255), C3(155,200,240)
    elseif id == "studio" then ambient, outdoor = C3(210,220,230), C3(190,205,220)
    elseif id == "desert" then ambient, outdoor = C3(235,215,180), C3(230,200,165)
    elseif id == "bright" then ambient, outdoor = C3(210,225,240), C3(200,220,235)
    else ambient, outdoor = C3(205,225,240), C3(195,218,235) end
    pcall(function()
        Lighting.ClockTime=c; Lighting.Brightness=b; Lighting.ExposureCompensation=e
        Lighting.Ambient=ambient; Lighting.OutdoorAmbient=outdoor
    end)
end

local function applyOptimizations()
    Hub.optStore = Hub.optStore or {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Texture") or d:IsA("Decal") then
            Hub.optStore[d] = Hub.optStore[d] or {transparency=d.Transparency}
            d.Transparency = Hub.state.optTex and 1 or Hub.optStore[d].transparency
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            Hub.optStore[d] = Hub.optStore[d] or {enabled=d.Enabled}
            d.Enabled = Hub.state.optPart and false or Hub.optStore[d].enabled
        elseif d:IsA("BasePart") then
            Hub.optStore[d] = Hub.optStore[d] or {shadow=d.CastShadow, material=d.Material, reflect=(d:IsA("MeshPart") and d.Reflectance or nil)}
            d.CastShadow = Hub.state.optShadow and false or Hub.optStore[d].shadow
            if d:IsA("MeshPart") then pcall(function() d.Reflectance = Hub.state.optRefl and 0 or Hub.optStore[d].reflect end) end
            d.Material = Hub.state.optLow and Enum.Material.Plastic or Hub.optStore[d].material
        end
    end
end

local function fpsApply()
    if canFPS and Hub.state.fpsUnlock then pcall(function() setfpscap(Hub.state.fpsCap) end) end
end

local function setAnimations(pack)
    local c = LocalPlayer.Character
    if not c then return end
    local animate = c:FindFirstChild("Animate")
    if not animate then return end
    local packs = {
        Bubbly = {run=910025107, walk=910034870, jump=910016857, idle=910004836},
        Cartoony = {run=742638842, walk=742640026, jump=742637942, idle=742637544},
        Ninja = {run=656118852, walk=656121766, jump=656117878, idle=656117400},
        Pirate = {run=750783738, walk=750785693, jump=750782230, idle=750781874},
        Robot = {run=616091570, walk=616095330, jump=616090535, idle=616088211},
        Mage = {run=707861613, walk=707897309, jump=707853694, idle=707742142},
        Astronaut = {run=891636393, walk=891636393, jump=891627522, idle=891621366},
        Knight = {run=657564596, walk=657552124, jump=658409194, idle=657595757},
    }
    local p = packs[pack]
    if not p then return end
    local function setId(path, id)
        local x = path and path:FindFirstChildOfClass("Animation")
        if x then x.AnimationId = "rbxassetid://" .. tostring(id) end
    end
    setId(animate:FindFirstChild("run"), p.run)
    setId(animate:FindFirstChild("walk"), p.walk)
    setId(animate:FindFirstChild("jump"), p.jump)
    setId(animate:FindFirstChild("idle"), p.idle)
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("AnimationTrack") then pcall(function() d:AdjustSpeed(Hub.state.packSpeed) end) end
    end
end

local function playEmote(name)
    local _, h = aliveCharacter(LocalPlayer)
    if not h then return end
    if type(h.PlayEmote) == "function" then pcall(function() h:PlayEmote(name) end); return end
    local emotes = {Wave="/e wave", Cheer="/e cheer", Laugh="/e laugh", Dance="/e dance", Dance2="/e dance2", Dance3="/e dance3", Point="/e point"}
    local command = emotes[name]
    if command then pcall(function() game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(command, "All") end) end
end

local function setKorblox(on)
    local c = LocalPlayer.Character
    if not c then return end
    local desc = c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid"):GetAppliedDescription()
    if not desc then return end
    if on then pcall(function() desc.RightLeg = 139607718; c:FindFirstChildOfClass("Humanoid"):ApplyDescription(desc) end)
    else
        pcall(function() c:FindFirstChildOfClass("Humanoid"):ApplyDescription(Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)) end)
    end
end

local function setHeadless(on)
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local head = c:FindFirstChild("Head")
    if on and head then head.Transparency = 1; destroyName(head, {"face"})
    elseif head then head.Transparency = 0 end
end

local function clearToy()
    local c=LocalPlayer.Character
    if c then destroyName(c,{"PulseToy","PulseToyRing","PulseToyOrb","PulseToyBalloon"}) end
end

local function makeToy(name)
    clearToy()
    local _,_,r=aliveCharacter(LocalPlayer); if not r then return end
    if name=="Halo" then
        local ring=Instance.new("Part"); ring.Name="PulseToyRing"; ring.Anchored=true; ring.CanCollide=false; ring.Shape=Enum.PartType.Cylinder; ring.Size=V3(3,0.18,3); ring.Material=Enum.Material.Neon; ring.Color=C3(206,236,255); ring.CFrame=r.CFrame*CFrame.new(0,3.1,0)*CFrame.Angles(0,0,math.rad(90)); ring.Parent=r;
        pushCleanup(function() if ring then ring:Destroy() end end)
    elseif name=="Balloon" then
        local ball=Instance.new("Part"); ball.Name="PulseToyBalloon"; ball.Shape=Enum.PartType.Ball; ball.Size=V3(1.5,1.5,1.5); ball.Material=Enum.Material.SmoothPlastic; ball.Color=C3(183,220,255); ball.Anchored=true; ball.CanCollide=false; ball.Parent=r
        local rope=Instance.new("Beam"); local a0=Instance.new("Attachment",r); local a1=Instance.new("Attachment",ball); a0.Position=V3(0,1,0); a1.Position=V3(0,-0.8,0); rope.Attachment0=a0; rope.Attachment1=a1; rope.Width0=0.02; rope.Width1=0.02; rope.Parent=r;
        pushCleanup(function() pcall(function() ball:Destroy(); rope:Destroy(); a0:Destroy(); a1:Destroy() end) end)
    else
        local orb=Instance.new("Part"); orb.Name="PulseToyOrb"; orb.Shape=Enum.PartType.Ball; orb.Size=V3(1,1,1); orb.Material=Enum.Material.Neon; orb.Color=C3(166,214,255); orb.Anchored=true; orb.CanCollide=false; orb.Parent=r
        pushCleanup(function() if orb then orb:Destroy() end end)
    end
end

local function setSpeed()
    local _, h = aliveCharacter(LocalPlayer)
    if h then
        local target=Hub.state.bhop and Hub.state.bhopSpeed or (Hub.state.speedOn and Hub.state.walkSpeed or 16)
        pcall(function() h.WalkSpeed=math.clamp(tonumber(target) or 16,8,200) end)
    end
end

local function setSpin(on)
    local _,h,r=aliveCharacter(LocalPlayer)
    if on then
        if h then
            Hub.spinOldAutoRotate=h.AutoRotate
            pcall(function() h.AutoRotate=false end)
            Hub.spinActiveCharacter=LocalPlayer.Character
        end
        Hub.spinAngle=0; Hub.spinLast=os.clock()
    else
        if h and Hub.spinActiveCharacter==LocalPlayer.Character then pcall(function() h.AutoRotate=(Hub.spinOldAutoRotate==nil) and true or Hub.spinOldAutoRotate end) end
        Hub.spinOldAutoRotate=nil; Hub.spinActiveCharacter=nil; Hub.spinAngle=0; Hub.spinLast=0
        if r then pcall(function() r.AssemblyAngularVelocity=V3(0,0,0) end) end
    end
end

local function setJump()
    local _, h = aliveCharacter(LocalPlayer)
    if h then pcall(function() h.JumpPower = Hub.state.jumpOn and Hub.state.jumpPower or 50 end) end
end

local function setLocalInvisible(on)
    local c = LocalPlayer.Character
    if not c then return end
    for _,d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = on and 1 or 0
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = on and 1 or 0
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") then
            d.Enabled = not on
        end
    end
end

local function bombJump()
    local _, _, r = aliveCharacter(LocalPlayer)
    if r then r.AssemblyLinearVelocity = V3(0, Hub.state.bombPower, 0) end
end

local function orbitTarget()
    if Hub.state.orbitTarget == "Murderer" then return nearestTarget(function(p) return roleOf(p) == "Murderer" end)
    elseif Hub.state.orbitTarget == "Sheriff" then return nearestTarget(function(p) return roleOf(p) == "Sheriff" end)
    else return nearestTarget() end
end

local function animationToSpeed()
    for _, d in ipairs(LocalPlayer.Character and LocalPlayer.Character:GetDescendants() or {}) do
        if d:IsA("AnimationTrack") then pcall(function() d:AdjustSpeed(Hub.state.emoteSpeed) end) end
    end
end

local function musicStop()
    if Hub.musicSound then pcall(function() Hub.musicSound:Stop(); Hub.musicSound:Destroy() end); Hub.musicSound=nil end
end

local function musicPlayRandom()
    if #Hub.state.songs == 0 then return end
    musicStop()
    local id = Hub.state.songs[math.random(1,#Hub.state.songs)]
    local s = Instance.new("Sound")
    s.Name = "PulseRoundMusic"; s.SoundId = "rbxassetid://" .. tostring(id); s.Volume = Hub.state.musicVol/100
    s.Looped = false; s.Parent = SoundService; Hub.musicSound = s
    task.delay(Hub.state.musicDelay, function() if Hub.alive and s.Parent and Hub.state.music then pcall(function() s:Play() end) end end)
end

local function serverHop(small)
    local servers = nil
    if type(request) == "function" then
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local ok, res = pcall(function() return request({Url=url, Method="GET"}) end)
        if ok and res and res.Body then servers = safe(function() return HttpService:JSONDecode(res.Body) end) end
    end
    local best
    if servers and servers.data then
        for _, sv in ipairs(servers.data) do
            if sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                if not small or sv.playing <= math.max(3, math.floor(sv.maxPlayers*0.35)) then best = sv.id; break end
            end
        end
    end
    if best then TeleportService:TeleportToPlaceInstance(game.PlaceId, best, LocalPlayer) else TeleportService:Teleport(game.PlaceId, LocalPlayer) end
end

local function setAntiAfk(on)
    Hub.state.antiAfk = on
    if Hub.afkConn then pcall(function() Hub.afkConn:Disconnect() end); Hub.afkConn=nil end
    if on then
        local vu = game:GetService("VirtualUser")
        Hub.afkConn = LocalPlayer.Idled:Connect(function()
            pcall(function() vu:Button2Down(Vector2.new(0,0), Camera.CFrame); task.wait(0.1); vu:Button2Up(Vector2.new(0,0), Camera.CFrame) end)
        end)
        pushCleanup(function() pcall(function() Hub.afkConn:Disconnect() end) end)
    end
end

local function setDesync()
    if not Hub.state.desync then return end
    local _, _, r = aliveCharacter(LocalPlayer)
    if not r then return end
    local t = os.clock() * Hub.state.desyncSpeed / 5
    local off
    if Hub.state.desyncMode == "Jitter" then off = V3(math.sin(t)*Hub.state.desyncRadius,0,math.cos(t)*Hub.state.desyncRadius)
    elseif Hub.state.desyncMode == "Orbit" then off = V3(math.cos(t),0,math.sin(t)) * Hub.state.desyncRadius
    elseif Hub.state.desyncMode == "Vertical" then off = V3(0,math.sin(t)*Hub.state.desyncRadius,0)
    elseif Hub.state.desyncMode == "Behind" then off = -r.CFrame.LookVector * Hub.state.desyncRadius
    else off = r.CFrame.RightVector * Hub.state.desyncRadius end
    r.CFrame = r.CFrame + off
end

local function faceThreat()
    if not Hub.state.faceThreat then return end
    local p = nearestTarget()
    local _, _, r = aliveCharacter(LocalPlayer)
    local _, _, tr = aliveCharacter(p)
    if r and tr then r.CFrame = CFrame.lookAt(r.Position, tr.Position) end
end

local function farmStep()
    if not Hub.state.farm or not roundActive() then return end
    local _, _, r = aliveCharacter(LocalPlayer)
    if not r then return end
    local count = bagCount()
    if Hub.state.farmReset and count and count >= 40 then
        local h = select(2, aliveCharacter(LocalPlayer)); if h then h.Health = 0 end
        return
    end
    local nearest, d = nil, math.huge
    for _, c in ipairs(coinParts()) do
        if c and c.Parent then
            local dd = (c.Position - r.Position).Magnitude
            if dd < d then nearest, d = c, dd end
        end
    end
    if not nearest then return end
    if Hub.state.farmAvoid then
        local m = nearestTarget(function(p) return roleOf(p)=="Murderer" end)
        local _,_,mr = aliveCharacter(m)
        if mr and (mr.Position-r.Position).Magnitude < 18 then return end
    end
    if Hub.state.farmVersion == "Teleport" then
        r.CFrame = nearest.CFrame + V3(0,2,0)
    else
        local distance = (nearest.Position - r.Position).Magnitude
        local duration = math.max(0.02, distance / math.max(Hub.state.farmSpeed, 1))
        safe(function() TweenService:Create(r, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame=nearest.CFrame+V3(0,2,0)}):Play() end)
    end
end

local function installSilentHook()
    if Hub.silentHookInstalled or not canHook then return end
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if Hub.alive and Hub.state.aimOn and Hub.state.aimVersion == "Silent" and (method == "InvokeServer" or method == "FireServer") then
            local gun = equippedGun()
            local target = targetByFov() or select(1, playersRoleTarget())
            if gun and target and (self:IsDescendantOf(gun) or self.Name:lower():find("beam",1,true)) then
                local pos = predictedPosition(target, Hub.state.predict)
                if pos then
                    for i, v in ipairs(args) do if typeof(v) == "Vector3" then args[i] = pos; break end end
                    return old(self, table.unpack(args))
                end
            end
        end
        return old(self, ...)
    end)
    Hub.silentHookInstalled = true
end

local function fovInit()
    if hasDrawing and not Hub.fovDrawing then
        local c = Drawing.new("Circle")
        c.Visible = false; c.Filled = false; c.Thickness = 1.3; c.NumSides = 64; c.Transparency = 0.9
        c.Color = C3(139,210,247)
        Hub.fovDrawing = c
        pushCleanup(function() pcall(function() c:Remove() end) end)
    end
end

local function fovStep()
    local now=os.clock(); if Hub._fovNext and now<Hub._fovNext then return end; Hub._fovNext=now+0.03
    local visible = Hub.state.aimOn and Hub.state.fovShow
    local vp = Camera.ViewportSize
    if Hub.fovDrawing then
        local c = Hub.fovDrawing
        c.Position = Vector2.new(vp.X/2,vp.Y/2)
        c.Radius = Hub.state.fovRadius
        c.Visible = visible
    end
    fovGui.Position = U2(0,vp.X/2,0,vp.Y/2)
    fovGui.Size = U2(0,Hub.state.fovRadius*2,0,Hub.state.fovRadius*2)
    fovGui.ZIndex = 120; fovGui.Visible = visible and not Hub.fovDrawing
end

local function cameraAimStep()
    local knifeMode = Hub.state.knifeAim and equippedKnife() and Hub.rightDown
    if knifeMode then
        local p = nearestTarget(function(x) return roleOf(x)=="Sheriff" or roleOf(x)=="Hero" end)
        local _,_,r = aliveCharacter(p)
        if r then
            local pos = predictedPosition(p, Hub.state.knifeLead) or r.Position
            local from = Camera.CFrame.Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(from,pos), math.clamp(Hub.state.aimSpeed/100,0.02,1))
        end
        return
    end
    if not Hub.state.aimOn or Hub.state.aimVersion ~= "Camera" or not Hub.rightDown then return end
    local p = targetByFov() or select(1, playersRoleTarget())
    local _, _, r = aliveCharacter(p)
    if not r then return end
    local pos = predictedPosition(p, Hub.state.predict) or r.Position
    local from = Camera.CFrame.Position
    local wanted = CFrame.lookAt(from, pos)
    local alpha = math.clamp(Hub.state.aimSpeed/100, 0.02, 1)
    local old = Camera.CFrame
    Camera.CFrame = old:Lerp(wanted, alpha)
end

local function aimReturn()
    if not Hub.state.aimReturn then return end
end

local function initBacktrack()
    if Hub.backtrackConn then return end
    Hub.backtrackConn = RunService.Heartbeat:Connect(function()
        if not Hub.state.backtrack then return end
        local now = os.clock()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local _, h, r = aliveCharacter(p)
                if h and h.Health > 0 and r then
                    Hub.backtrack[p] = Hub.backtrack[p] or {}
                    table.insert(Hub.backtrack[p], {t=now, cf=r.CFrame})
                    while #Hub.backtrack[p] > 20 or (Hub.backtrack[p][1] and now - Hub.backtrack[p][1].t > 0.75) do table.remove(Hub.backtrack[p], 1) end
                end
            end
        end
    end)
    pushCleanup(function() pcall(function() Hub.backtrackConn:Disconnect() end) end)
end

local function renderBacktrack()
    if not Hub.state.backtrack then
        for _,e in pairs(Hub.backtrack) do
            if e.ghost then pcall(function() e.ghost:Destroy() end); e.ghost=nil end
        end
        return
    end
    local targetT=os.clock()-Hub.state.backMs/1000
    for p,hist in pairs(Hub.backtrack) do
        if hist and #hist>0 then
            local sample=hist[1]
            for i=#hist,1,-1 do if hist[i].t<=targetT then sample=hist[i]; break end end
            local c=p.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
            if r then
                local entry=Hub.backtrack[p]
                local ghost=entry.ghost
                if not ghost then
                    ghost=Instance.new("Part"); ghost.Name="PulseBackGhost"; ghost.Anchored=true; ghost.CanCollide=false; ghost.CanQuery=false; ghost.CanTouch=false; ghost.Material=Enum.Material.ForceField; ghost.Transparency=0.72; ghost.Size=V3(3,5,2); ghost.Parent=workspace; entry.ghost=ghost
                end
                ghost.CFrame=sample.cf; ghost.Color=roleColor(roleOf(p)); ghost.Transparency=0.72
            end
        end
    end
end

local function roundLoops()
    task.spawn(function()
        while Hub.alive do
            pcall(function()
                if Hub.state.killAura and equippedKnife() then
                    local meRoot = select(3, aliveCharacter(LocalPlayer))
                    if meRoot then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer then
                                local _, h, r = aliveCharacter(p)
                                local okTarget = Hub.state.killMode == "All" or roleOf(p) == "Sheriff"
                                if okTarget and h and h.Health > 0 and r and (r.Position-meRoot.Position).Magnitude <= Hub.state.killRadius then stab() end
                            end
                        end
                    end
                end
                if Hub.state.autoPickup and livingCharacter(LocalPlayer) then pickupGun() end
                if Hub.state.autoKill then
                    local m = nearestTarget(function(p) return roleOf(p)=="Murderer" end)
                    if m then shootAt(m) end
                elseif Hub.state.autoShoot then
                    local t = targetByFov() or select(1, playersRoleTarget())
                    if t then shootAt(t) end
                end
                if Hub.state.knifeAuto then
                    local m = nearestTarget(function(p) return true end)
                    if m then
                        local _,_,r = aliveCharacter(m)
                        local _,_,me = aliveCharacter(LocalPlayer)
                        if r and me and (r.Position-me.Position).Magnitude <= 70 and (not Hub.state.knifeWall or visibleFrom(me.Position, r.Position, m.Character)) then knifeThrowAt(m) end
                    end
                end
                if Hub.state.autoWin and roleOf(LocalPlayer) == "Murderer" and equippedKnife() then
                    local target = nearestTarget(function(p) return roleOf(p) ~= "Murderer" end)
                    if target then
                        local _, _, targetRoot = aliveCharacter(target)
                        local _, _, myRoot = aliveCharacter(LocalPlayer)
                        if targetRoot and myRoot and (targetRoot.Position - myRoot.Position).Magnitude <= 18 then
                            stab()
                        elseif targetRoot then
                            knifeThrowAt(target)
                        end
                    end
                end
                if Hub.state.autoFlingSheriff then
                    local s = nearestTarget(function(p) return roleOf(p)=="Sheriff" end)
                    if s then fling(s, 0.8) end
                end
                if Hub.state.farm then farmStep() end
            end)
            task.wait(0.12)
        end
    end)
end

task.spawn(function()
    while Hub.alive do
        if Hub.state.emoteHold then
            playEmote(Hub.state.emoteSel)
            task.wait(2.2)
        else
            task.wait(0.4)
        end
    end
end)

local function playerWatch()
    local function watchRole(p)
        p:GetPropertyChangedSignal("Team"):Connect(function() Hub.roleCache[p]=nil end)
        for _,key in ipairs({"Role","RoleName","PlayerRole","CurrentRole"}) do pcall(function() p:GetAttributeChangedSignal(key):Connect(function() Hub.roleCache[p]=nil end) end) end
        pcall(function()
            if p.Character then
                p.Character.ChildAdded:Connect(function(ch) if ch:IsA("Tool") then Hub.roleCache[p]=nil end end)
                p.Character.ChildRemoved:Connect(function(ch) if ch:IsA("Tool") then Hub.roleCache[p]=nil end end)
            end
        end)
    end
    pushConn(Players.PlayerAdded:Connect(function(p)
        watchRole(p)
        Hub.roleCache[p] = nil
        pushConn(p.CharacterAdded:Connect(function(char)
            Hub.roleCache[p]=nil
            pcall(function() char.ChildAdded:Connect(function(ch) if ch:IsA("Tool") then Hub.roleCache[p]=nil end end); char.ChildRemoved:Connect(function(ch) if ch:IsA("Tool") then Hub.roleCache[p]=nil end end) end)
            task.wait(0.5); if Hub.state.trail and p==LocalPlayer then applyTrail() end
        end))
    end))
    pushConn(Players.PlayerRemoving:Connect(function(p) clearEspFor(p); Hub.roleCache[p]=nil; Hub.backtrack[p]=nil end))
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            watchRole(p)
            pushConn(p.CharacterAdded:Connect(function(char)
            Hub.roleCache[p]=nil
            pcall(function() char.ChildAdded:Connect(function(ch) if ch:IsA("Tool") then Hub.roleCache[p]=nil end end); char.ChildRemoved:Connect(function(ch) if ch:IsA("Tool") then Hub.roleCache[p]=nil end end) end)
            task.wait(0.2); applyChams(p)
        end))
        end
    end
end



    -- Legacy ESP artifacts are separate overlays, not a second control window.
    Hub.state.lang = "English"
    pcall(function()
        local old = getGuiParent():FindFirstChild("PulseHubESP")
        if old then old:Destroy() end
    end)
    espGui = Instance.new("ScreenGui")
    espGui.Name = "PulseHubESP"
    espGui.ResetOnSpawn = false
    espGui.IgnoreGuiInset = true
    espGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    espGui.DisplayOrder = 600
    espGui.Parent = getGuiParent()
    fovGui = Instance.new("Frame")
    fovGui.Name = "PulseHubFOV"
    fovGui.AnchorPoint = Vector2.new(0.5, 0.5)
    fovGui.BackgroundTransparency = 1
    fovGui.BorderSizePixel = 0
    fovGui.Size = UDim2.fromOffset(120, 120)
    fovGui.Visible = false
    fovGui.Parent = espGui
    uiCorner(fovGui, 1000)
    local fovStroke = Instance.new("UIStroke")
    fovStroke.Thickness = 1.5
    fovStroke.Color = Color3.fromRGB(139, 210, 247)
    fovStroke.Parent = fovGui

    local function pulseNotify(title, message)
        pcall(function() WindUIRef:Notify({Title=title, Content=message, Duration=3}) end)
    end
    local function pulseTab(title, icon)
        return SharedWindow:Tab({Title=title, Icon=icon})
    end
    local function pulseSection(tab, title, desc)
        return tab:Section({Title=title, Desc=desc, Opened=true})
    end
    local function invokeCallback(title, callback, value)
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback, value)
        if not ok then
            warn("[MM2 WindUI] " .. tostring(title) .. ": " .. tostring(err))
            pulseNotify("Module error", tostring(title) .. " failed; check the console")
        end
    end
    local function setState(key, value, callback, title, save)
        Hub.state[key] = value
        if callback then invokeCallback(title or key, callback, value) end
        if save ~= false then pcall(saveConfig) end
    end
    local function addToggle(section, title, key, desc, callback)
        local control = section:Toggle({
            Title=title, Desc=desc, Value=(Hub.state[key] == true), Flag="PulseHub_" .. key,
            Callback=function(value) setState(key, value, callback, title) end,
        })
        Hub.controls[key] = {
            set=function(value, silent) setState(key, value, silent and nil or callback, title, true) end,
        }
        return control
    end
    local function addSlider(section, title, key, minValue, maxValue, step, desc, suffix, callback)
        local value = tonumber(Hub.state[key]) or minValue
        local control = section:Slider({
            Title=title, Desc=desc, Step=step or 1,
            Value={Min=minValue, Max=maxValue, Default=math.clamp(value, minValue, maxValue)},
            Flag="PulseHub_" .. key,
            Callback=function(newValue)
                local n = tonumber(newValue) or minValue
                setState(key, math.clamp(n, minValue, maxValue), callback, title)
            end,
        })
        Hub.controls[key] = {
            set=function(newValue, silent)
                local n = math.clamp(tonumber(newValue) or minValue, minValue, maxValue)
                setState(key, n, silent and nil or callback, title, true)
                if control and control.Set then pcall(function() control:Set(n) end) end
            end,
        }
        return control
    end
    local function addDropdown(section, title, key, values, desc, callback)
        local initial = Hub.state[key]
        local allowed = false
        for _, value in ipairs(values) do if value == initial then allowed = true break end end
        if not allowed then initial = values[1]; Hub.state[key] = initial end
        local control = section:Dropdown({
            Title=title, Desc=desc, Values=values, Value=initial, AllowNone=false,
            Flag="PulseHub_" .. key,
            Callback=function(value) setState(key, value, callback, title) end,
        })
        Hub.controls[key] = {
            set=function(value, silent) setState(key, value, silent and nil or callback, title, true); if control and control.Select then pcall(function() control:Select(value) end) end end,
        }
        return control
    end
    local function addButton(section, title, desc, callback)
        return section:Button({Title=title, Desc=desc, Callback=function() invokeCallback(title, callback) end})
    end
    local function addInput(section, title, desc, placeholder, callback)
        return section:Input({Title=title, Desc=desc, Placeholder=placeholder or "Enter value...", Value="", Callback=function(value) invokeCallback(title, callback, value) end})
    end
    local function selectPlayerByName(name)
        local clean = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if clean == "" then return nil end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and (player.Name:lower() == clean or player.DisplayName:lower() == clean or tostring(player.UserId) == clean) then
                Hub.state.selectedPlayer = tostring(player.UserId)
                pcall(saveConfig)
                return player
            end
        end
        return nil
    end
    local function teleportToRole(role)
        local player = nearestTarget(function(p) return roleOf(p) == role end)
        local _, _, targetRoot = aliveCharacter(player)
        local _, _, myRoot = aliveCharacter(LocalPlayer)
        if player and targetRoot and myRoot then
            Hub.antiFlingIgnoreUntil = os.clock() + 0.65
            myRoot.CFrame = targetRoot.CFrame + V3(3, 0, 0)
            pulseNotify("Teleport", "Moved near " .. role)
        else
            pulseNotify("Teleport", "No active " .. role .. " target was found")
        end
    end
    local function bringSelectedLocal()
        local target = selectedPlayer()
        local _, _, targetRoot = aliveCharacter(target)
        local _, _, myRoot = aliveCharacter(LocalPlayer)
        if target and targetRoot and myRoot then
            -- Client-side placement attempt, matching the source module's behavior.
            targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
            pulseNotify("Player Tools", "Applied local bring attempt to " .. target.Name)
        else
            pulseNotify("Player Tools", "Select an active player first")
        end
    end
    local function bringRoleLocal(role)
        local target = nearestTarget(function(p) return roleOf(p) == role end)
        local _, _, targetRoot = aliveCharacter(target)
        local _, _, myRoot = aliveCharacter(LocalPlayer)
        if target and targetRoot and myRoot then
            targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
            pulseNotify("Player Tools", "Applied local bring attempt to " .. role)
        else
            pulseNotify("Player Tools", "No active " .. role .. " target was found")
        end
    end
    local staticMurdererCache = nil
    local function restoreStaticMurderer()
        local cached = staticMurdererCache
        staticMurdererCache = nil
        if cached and cached.player then
            local _, _, root = aliveCharacter(cached.player)
            if root and cached.cframe then pcall(function() root.CFrame = cached.cframe end) end
        end
    end
    local function sourceBringStep()
        local _, _, myRoot = aliveCharacter(LocalPlayer)
        if not myRoot then return end
        local distance = math.clamp(tonumber(Hub.state.bringDistance) or 3, 0, 5)
        local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -distance)

        -- These are local-client position attempts. Whether a change replicates is game/network dependent.
        if Hub.state.bringMurderer or Hub.state.bringSheriff or Hub.state.bringInnocent then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local role = roleOf(player)
                    local shouldBring = (role == "Murderer" and Hub.state.bringMurderer)
                        or ((role == "Sheriff" or role == "Hero") and Hub.state.bringSheriff)
                        or (role == "Innocent" and Hub.state.bringInnocent)
                    if shouldBring then
                        local _, humanoid, root = aliveCharacter(player)
                        if humanoid and humanoid.Health > 0 and root then
                            pcall(function()
                                root.CFrame = targetCFrame
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                            end)
                        end
                    end
                end
            end
        end

        if Hub.state.staticMurderer then
            local target = nearestTarget(function(player) return roleOf(player) == "Murderer" end)
            if target then
                local _, _, root = aliveCharacter(target)
                if root then
                    if not staticMurdererCache or staticMurdererCache.player ~= target then
                        restoreStaticMurderer()
                        staticMurdererCache = { player = target, cframe = root.CFrame }
                    end
                    pcall(function()
                        root.CFrame = targetCFrame
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end
        elseif staticMurdererCache then
            restoreStaticMurderer()
        end

        if Hub.state.bringGunDrop then
            local drop = findGunDrop(true)
            local part = drop and (drop:IsA("BasePart") and drop or Hub.gunDropPart)
            if part and part:IsA("BasePart") then
                pcall(function()
                    part.CFrame = myRoot.CFrame
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end)
                if type(firetouchinterest) == "function" then
                    pcall(function()
                        firetouchinterest(myRoot, part, 0)
                        task.wait(0.01)
                        firetouchinterest(myRoot, part, 1)
                    end)
                end
            end
        end

        if Hub.state.antiThrow and UIS:IsKeyDown(K.Q) then
            local character, humanoid = aliveCharacter(LocalPlayer)
            if character and humanoid and (character:FindFirstChild("Gun") or character:FindFirstChild("Revolver")) then
                pcall(function() humanoid:UnequipTools() end)
            end
        end
    end

    local function refreshFlingConnections()
        if Hub.clickFlingConn then pcall(function() Hub.clickFlingConn:Disconnect() end); Hub.clickFlingConn=nil end
        if Hub.touchFlingConn then pcall(function() Hub.touchFlingConn:Disconnect() end); Hub.touchFlingConn=nil end
        if Hub.state.clickFling then
            Hub.clickFlingConn = UIS.InputBegan:Connect(function(input, processed)
                if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                local target = playerFromPart(Mouse.Target)
                if target and target ~= LocalPlayer then fling(target, Hub.state.flingDuration or 1.35) end
            end)
            pushConn(Hub.clickFlingConn)
        end
        if Hub.state.touchFling then
            Hub.touchFlingConn = RunService.Heartbeat:Connect(function()
                if not Hub.alive or not Hub.state.touchFling then return end
                local _, _, myRoot = aliveCharacter(LocalPlayer)
                if not myRoot then return end
                local target = nearestTarget(function(p)
                    local _, _, root = aliveCharacter(p)
                    return root ~= nil and (root.Position - myRoot.Position).Magnitude <= 7
                end)
                if target then fling(target, 0.65) end
            end)
            pushConn(Hub.touchFlingConn)
        end
    end

    -- Reuse the base hub's tabs for overlapping categories; unique feature groups get their own tabs.
    local visualSection = pulseSection(VisualTabRef, "Advanced ESP & Role Markers", "PulseHub visual module")
    addToggle(visualSection, "Pulse Player ESP", "esp", "Show role-colored player overlays")
    addToggle(visualSection, "ESP Boxes", "espBox", "Show player boxes")
    addToggle(visualSection, "ESP Skeleton", "espSkel", "Draw R6 / R15 skeleton beams")
    addToggle(visualSection, "ESP Tracers", "espTracer", "Draw lines toward players")
    addToggle(visualSection, "Show Role Labels", "lblRole", "Include Murderer / Sheriff / Innocent")
    addToggle(visualSection, "Show Player Names", "lblName", "Include player names")
    addToggle(visualSection, "Show Distance", "lblDist", "Include distance in studs")
    addToggle(visualSection, "Show Equipped Weapon", "lblWeapon", "Include Knife / Gun when detectable")
    addToggle(visualSection, "Pulse Gun ESP", "gunEsp", "Highlight dropped gun")
    addToggle(visualSection, "X-Ray", "xray", "Adjust local wall transparency", function(value) setXray(value) end)
    addToggle(visualSection, "Role Chams", "chams", "Highlight characters by detected role", function() for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then applyChams(p) end end end)
    addSlider(visualSection, "Chams Transparency", "chamsTrans", 0, 100, 1, "Role highlight transparency", "%", function() for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then applyChams(p) end end end)
    addDropdown(visualSection, "Lighting Preset", "lightingPreset", {"None", "Night", "Bright", "Clean"}, "Apply a simple local lighting preset", function(value)
        Hub.state.fullbright = value == "Bright"
        if value == "None" then setPreset(nil) else setPreset(({Night="night", Bright="bright", Clean="clean"})[value]) end
    end)
    addToggle(visualSection, "Fullbright", "fullbright", "Bright local lighting from the Normal Hub module", function(value)
        if value then
            Hub.state.lightingPreset = "Bright"
            setPreset("bright")
        else
            setPreset(nil)
            Hub.state.lightingPreset = "None"
        end
    end)

    local combatTab = pulseTab("Combat", "target")
    local aimSection = pulseSection(combatTab, "Aim Assist", "Advanced target selection options")
    addToggle(aimSection, "Enable Aim Assist", "aimOn", "Master switch for supported aim features")
    addDropdown(aimSection, "Aim Version", "aimVersion", {"Silent", "Camera"}, "Silent modifies supported shot arguments; Camera guides view")
    addDropdown(aimSection, "Aim Target", "aimType", {"Auto role", "Murderer", "Sheriff", "Closest to cursor", "Closest to me"}, "Choose the target rule")
    addSlider(aimSection, "Aim Speed", "aimSpeed", 1, 100, 1, "Camera interpolation", "%")
    addToggle(aimSection, "Return Camera", "aimReturn", "Restore camera after a camera flick")
    addSlider(aimSection, "Prediction", "predict", 0, 300, 5, "Velocity lead", " ms")
    addToggle(aimSection, "Wall Check", "aimWall", "Require line of sight")
    addToggle(aimSection, "Show Aim FOV", "fovShow", "Show the target radius circle")
    addSlider(aimSection, "FOV Radius", "fovRadius", 20, 600, 5, "Target radius", " px")

    local weaponSection = pulseSection(combatTab, "Weapons & Combat Actions", "Gun and knife automation controls")
    addToggle(weaponSection, "Auto Pick Up Gun", "autoPickup", "Pick up a detected dropped gun")
    addToggle(weaponSection, "Auto Shoot Murderer", "autoShoot", "Automatically target a detected Murderer")
    addToggle(weaponSection, "Auto Kill (Sheriff Role)", "autoKill", "Use the original PulseHub sheriff-side routine")
    addToggle(weaponSection, "Auto-Win (Murderer Role)", "autoWin", "Try the included automatic knife routine when you are Murderer")
    addToggle(weaponSection, "Anti-Throw", "antiThrow", "Unequip the gun while Q is held, matching the Premium source behavior")
    addToggle(weaponSection, "Auto Fling Sheriff", "autoFlingSheriff", "Attempt a physics fling toward a Sheriff")
    addToggle(weaponSection, "Knife Kill Aura", "killAura", "Automatic knife attacks when supported")
    addSlider(weaponSection, "Kill Radius", "killRadius", 5, 60, 1, "Attack distance", " st")
    addDropdown(weaponSection, "Kill Targets", "killMode", {"All", "Sheriff only"}, "Choose knife-aura target types")
    addButton(weaponSection, "Pick Up Gun Now", "Try to collect the dropped gun", function() pickupGun() end)
    addButton(weaponSection, "Shoot Murderer Once", "Run one supported shot attempt", function() local target = nearestTarget(function(p) return roleOf(p) == "Murderer" end); if target then shootAt(target) else pulseNotify("Combat", "No Murderer target was found") end end)
    local knifeSection = pulseSection(combatTab, "Knife", "Knife targeting and throw options")
    addToggle(knifeSection, "Knife Aim Assist", "knifeAim", "Assist knife target selection")
    addToggle(knifeSection, "Knife Wall Check", "knifeWall", "Require line of sight for knife throws")
    addSlider(knifeSection, "Knife Lead", "knifeLead", 0, 300, 5, "Velocity lead", " ms")
    addToggle(knifeSection, "Auto Throw Knife", "knifeAuto", "Automatically throw toward selected targets")
    addButton(knifeSection, "Throw at Target", "Try a throw at the selected role target", function() local target = select(1, playersRoleTarget()); if target then knifeThrowAt(target) end end)
    local fakePosSection = pulseSection(combatTab, "Position & Resolver", "Motion helpers")
    addToggle(fakePosSection, "Fake Position", "desync", "Apply a local offset pattern")
    addDropdown(fakePosSection, "Offset Mode", "desyncMode", {"Jitter", "Orbit", "Vertical", "Behind", "Sideways"}, "Choose the offset pattern")
    addSlider(fakePosSection, "Offset Radius", "desyncRadius", 1, 30, 1, "Offset distance", " st")
    addSlider(fakePosSection, "Offset Speed", "desyncSpeed", 1, 100, 1, "Offset rate")
    addToggle(fakePosSection, "Face Nearest Threat", "faceThreat", "Turn toward the nearest player")
    addToggle(fakePosSection, "Resolver", "resolver", "Enable motion-sample resolver option")

    local movementSection = pulseSection(UtilityTabRef, "Advanced Movement", "Movement helpers from the added modules")
    addToggle(movementSection, "Noclip", "noclip", "Disable local character collisions", function(value) if value then applyNoclip() else resetNoclip() end end)
    addToggle(movementSection, "Infinite Jump", "infJump", "Allow jumping while airborne")
    addToggle(movementSection, "Pulse Anti-Fling", "antiFling", "Recover from abnormal incoming physics")
    addToggle(movementSection, "Fly", "fly", "WASD flight controls", function(value) if value then startFly() else stopFly() end end)
    addToggle(movementSection, "Spin", "spin", "Rotate the character", function(value) setSpin(value) end)
    addToggle(movementSection, "Bunny Hop", "bhop", "Controlled jump speed", function() setSpeed() end)
    addToggle(movementSection, "Bunny Hop Auto Jump", "bhopAutoJump", "Jump automatically when grounded")
    addToggle(movementSection, "Local Invisibility", "invis", "Local-only transparency effect", function(value) setLocalInvisible(value) end)
    addSlider(movementSection, "Fly Speed", "flySpeed", 10, 200, 1, "Flight speed")
    addSlider(movementSection, "Spin Speed", "spinSpeed", 1, 60, 1, "Rotation speed")
    addSlider(movementSection, "Bomb Jump Power", "bombPower", 20, 250, 5, "Vertical launch power")
    addSlider(movementSection, "Bunny Hop Speed", "bhopSpeed", 10, 80, 1, "Movement speed during bunny hop", " st", function() setSpeed() end)
    addSlider(movementSection, "Anti-Fling Velocity", "antiFlingVelocity", 60, 180, 5, "Linear speed threshold")
    addSlider(movementSection, "Anti-Fling Angular", "antiFlingAngular", 15, 80, 1, "Angular speed threshold")
    addSlider(movementSection, "Anti-Fling Jump", "antiFlingJump", 20, 100, 2, "Sudden position delta", " st")
    addButton(movementSection, "Bomb Jump", "Launch vertically", function() bombJump() end)

    local coinSection = pulseSection(FarmTabRef, "Alternate Coin Autofarm", "Additional autofarm engine from the advanced module")
    addToggle(coinSection, "Pulse Coin Farm", "farm", "Collect detected Coin_Server parts")
    addDropdown(coinSection, "Pulse Farm Mode", "farmVersion", {"Tween", "Teleport"}, "Movement mode")
    addSlider(coinSection, "Pulse Farm Speed", "farmSpeed", 10, 150, 1, "Movement rate")
    addToggle(coinSection, "Reset When Bag Is Full", "farmReset", "Reset after a detected bag threshold")
    addToggle(coinSection, "Avoid Murderer", "farmAvoid", "Pause collection when a Murderer is nearby")
    addToggle(coinSection, "Fling After Respawn", "farmFling", "Attempt to fling a nearby player after respawn")

    local playersTab = pulseTab("Player Tools", "users")
    local selectionSection = pulseSection(playersTab, "Target Player", "Select by player name, display name, or UserId")
    addInput(selectionSection, "Select Player", "Enter a player name or UserId", "Player name or UserId", function(value)
        local player = selectPlayerByName(value)
        if player then pulseNotify("Player Tools", "Selected " .. player.Name) else pulseNotify("Player Tools", "Player not found") end
    end)
    addButton(selectionSection, "Copy Selected Name", "Copy name if a target is selected", function() local target=selectedPlayer(); if target then if type(setclipboard)=="function" then pcall(setclipboard,target.Name) end; pulseNotify("Player Tools", target.Name) end end)
    addButton(selectionSection, "Teleport to Selected", "Move your character near the selected player", function() local target=selectedPlayer(); local _,_,myRoot=aliveCharacter(LocalPlayer); local _,_,targetRoot=aliveCharacter(target); if target and myRoot and targetRoot then Hub.antiFlingIgnoreUntil=os.clock()+0.65; myRoot.CFrame=targetRoot.CFrame+V3(3,0,0) else pulseNotify("Player Tools", "Select an active player first") end end)
    addButton(selectionSection, "Bring Selected (Local Attempt)", "Client-side position attempt; may not replicate to other clients", function() bringSelectedLocal() end)
    addButton(selectionSection, "Fling Selected", "Attempt a physics fling on the selected player", function() local target=selectedPlayer(); if target then fling(target, Hub.state.flingDuration or 1.35) else pulseNotify("Player Tools", "Select an active player first") end end)
    addButton(selectionSection, "Teleport to Murderer", "Move your character near the detected Murderer", function() teleportToRole("Murderer") end)
    addButton(selectionSection, "Teleport to Sheriff", "Move your character near the detected Sheriff", function() teleportToRole("Sheriff") end)
    addButton(selectionSection, "Teleport to Innocent", "Move your character near a detected Innocent", function() teleportToRole("Innocent") end)
    addButton(selectionSection, "Bring Murderer (Local Attempt)", "Try moving the detected Murderer on this client", function() bringRoleLocal("Murderer") end)
    addButton(selectionSection, "Bring Sheriff (Local Attempt)", "Try moving the detected Sheriff on this client", function() bringRoleLocal("Sheriff") end)
    addButton(selectionSection, "Bring Innocent (Local Attempt)", "Try moving the nearest detected Innocent on this client", function() bringRoleLocal("Innocent") end)
    local bringSection = pulseSection(playersTab, "Continuous Bring (Local Attempt)", "These position edits may not replicate to the server or other clients")
    addToggle(bringSection, "Bring Murderer", "bringMurderer", "Continuously try to move Murderer near you")
    addToggle(bringSection, "Bring Sheriff / Hero", "bringSheriff", "Continuously try to move Sheriff or Hero near you")
    addToggle(bringSection, "Bring Innocents", "bringInnocent", "Continuously try to move Innocent players near you")
    addToggle(bringSection, "Static Teleport Murderer", "staticMurderer", "Keep attempting local placement; restore the last position when disabled")
    addToggle(bringSection, "Bring Dropped Gun", "bringGunDrop", "Try to move the dropped gun to you and touch it")
    addSlider(bringSection, "Bring Distance", "bringDistance", 0, 5, 1, "Offset in studs")
    local flingTuneSection = pulseSection(playersTab, "Fling Tuning", "Adjust values for selected-player fling attempts")
    addSlider(flingTuneSection, "Fling Power", "flingPower", 180, 500, 5, "Forward impulse")
    addSlider(flingTuneSection, "Fling Lift", "flingUp", 40, 220, 5, "Vertical impulse")
    addSlider(flingTuneSection, "Fling Spin", "flingSpin", 5000, 24000, 500, "Angular speed")
    addSlider(flingTuneSection, "Fling Duration", "flingDuration", 0.7, 2.5, 0.05, "Contact window", " s")
    local socialTab = pulseTab("Animations", "smile")
    local animSection = pulseSection(socialTab, "Animation Packs", "Local avatar animation options")
    addDropdown(animSection, "Animation Pack", "packSel", {"Bubbly", "Cartoony", "Ninja", "Pirate", "Robot", "Mage", "Astronaut", "Knight"}, "R15 animation bundle", function(value) setAnimations(value) end)
    addSlider(animSection, "Animation Speed", "packSpeed", 0.2, 3, 0.1, "Playback rate", "x")
    addDropdown(animSection, "Emote", "emoteSel", {"Wave", "Cheer", "Laugh", "Dance", "Dance2", "Dance3", "Point"}, "Built-in emote")
    addSlider(animSection, "Emote Speed", "emoteSpeed", 0.2, 3, 0.1, "Playback rate", "x", function() animationToSpeed() end)
    addToggle(animSection, "Hold Emote", "emoteHold", "Repeat selected emote")
    addToggle(animSection, "Reapply After Respawn", "animAuto", "Reapply animation pack after respawn")
    addButton(animSection, "Play Selected Emote", "Play the selected emote", function() playEmote(Hub.state.emoteSel) end)
    addButton(animSection, "Stop Emotes", "Stop active animation tracks", function() local _, humanoid=aliveCharacter(LocalPlayer); if humanoid then for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do pcall(function() track:Stop() end) end end end)
    local localAvatarSection = pulseSection(socialTab, "Local Avatar & Movement", "Local-only visual / movement changes")
    addToggle(localAvatarSection, "Fake Korblox", "korblox", "Local avatar appearance effect", function(value) setKorblox(value) end)
    addToggle(localAvatarSection, "Fake Headless", "headless", "Local head transparency effect", function(value) setHeadless(value) end)
    addDropdown(localAvatarSection, "Visual Toy", "toy", {"Halo", "Balloon", "Orb pet"}, "Local visual toy", function(value) if Hub.state.toyOn then makeToy(value) end end)
    addToggle(localAvatarSection, "Equip Visual Toy", "toyOn", "Show or remove the local visual toy", function(value) if value then makeToy(Hub.state.toy) else clearToy() end end)
    addButton(localAvatarSection, "Random Emote", "Play a random emote", function() local options={"Wave","Cheer","Laugh","Dance","Dance2","Dance3","Point"}; playEmote(options[math.random(1,#options)]) end)
    addToggle(localAvatarSection, "Custom Walk Speed", "speedOn", "Apply custom local WalkSpeed", function() setSpeed() end)
    addSlider(localAvatarSection, "Walk Speed", "walkSpeed", 16, 200, 1, "Custom WalkSpeed", "", function() setSpeed() end)
    addToggle(localAvatarSection, "Custom Jump Power", "jumpOn", "Apply custom JumpPower", function() setJump() end)
    addSlider(localAvatarSection, "Jump Power", "jumpPower", 50, 300, 1, "Custom JumpPower", "", function() setJump() end)
    addToggle(localAvatarSection, "Touch Fling", "touchFling", "Attempt fling on nearby players", function() refreshFlingConnections() end)
    addToggle(localAvatarSection, "Click Fling", "clickFling", "Click a player to attempt a fling", function() refreshFlingConnections() end)
    addToggle(localAvatarSection, "Orbit Target", "orbit", "Circle the configured target role")
    addDropdown(localAvatarSection, "Orbit Target Role", "orbitTarget", {"Murderer", "Sheriff", "Nearest"}, "Select orbit target")
    addSlider(localAvatarSection, "Orbit Radius", "orbitRadius", 3, 30, 1, "Orbit radius", " st")
    addSlider(localAvatarSection, "Orbit Speed", "orbitSpeed", 1, 20, 1, "Orbit speed")

    local worldTab = pulseTab("World & System", "globe")
    local musicSection = pulseSection(worldTab, "Round Music", "Play audio when a round starts")
    addToggle(musicSection, "Auto-Play Music", "music", "Play a random saved audio when a round starts", function(value) if not value then musicStop() elseif roundActive() then musicPlayRandom() end end)
    addSlider(musicSection, "Music Start Delay", "musicDelay", 0, 30, 1, "Delay before playback", " s")
    addSlider(musicSection, "Music Volume", "musicVol", 0, 100, 1, "Volume", "%", function(value) if Hub.musicSound then Hub.musicSound.Volume=value/100 end end)
    addInput(musicSection, "Add Audio ID", "Add a numeric Roblox audio asset ID", "Numeric asset ID", function(value) local id=tostring(value or ""):match("%d+"); if id then Hub.state.songs[#Hub.state.songs+1]=id; saveConfig(); pulseNotify("Audio ID", "Added " .. id) end end)
    addButton(musicSection, "Play Random Audio", "Play one saved audio now", function() musicPlayRandom() end)
    addButton(musicSection, "Stop Audio", "Stop current music", function() musicStop() end)
    addButton(musicSection, "Clear Audio List", "Remove saved audio IDs", function() Hub.state.songs={}; saveConfig(); musicStop() end)
    local optimizationSection = pulseSection(worldTab, "Performance & Server", "Local performance helpers")
    addToggle(optimizationSection, "Remove Textures", "optTex", "Hide decals and textures", function() applyOptimizations() end)
    addToggle(optimizationSection, "Remove Particles", "optPart", "Disable particle effects", function() applyOptimizations() end)
    addToggle(optimizationSection, "Low Quality Mode", "optLow", "Use low-cost materials", function() applyOptimizations() end)
    addToggle(optimizationSection, "FPS Unlock", "fpsUnlock", "Use executor FPS cap API if available", function() fpsApply() end)
    addSlider(optimizationSection, "FPS Cap", "fpsCap", 30, 9999, 10, "Target cap", " FPS", function() fpsApply() end)
    addToggle(optimizationSection, "Pulse Anti-AFK", "antiAfk", "Prevent idle kick", function(value) setAntiAfk(value) end)
    addButton(optimizationSection, "Rejoin Server", "Rejoin this experience", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    addButton(optimizationSection, "Server Hop", "Try to join another public server", function() serverHop(false) end)
    addButton(optimizationSection, "Small Server Hop", "Try to join a less populated server", function() serverHop(true) end)
    addButton(optimizationSection, "Copy Job ID", "Copy the current server JobId", function() if type(setclipboard)=="function" then pcall(setclipboard, game.JobId) end; pulseNotify("Job ID", game.JobId) end)
    local configSection = pulseSection(worldTab, "Module Config & Cleanup", "Configuration is saved when supported by the executor")
    local themes = {"Dark", "Light", "Darker", "Aqua", "Amethyst", "Rose", "Midnight"}
    addDropdown(configSection, "WindUI Theme", "theme", themes, "Change the shared WindUI theme", function(value) pcall(function() WindUIRef:SetTheme(value) end) end)
    addButton(configSection, "Save Pulse Config", "Save PulseHub settings", function() local ok=saveConfig(); pulseNotify("Config", ok and "Config saved" or "Session config saved") end)
    addButton(configSection, "Stop PulseHub Features", "Stop PulseHub loops and remove PulseHub effects, leaving the shared WindUI open", function() Hub.Unload(); pulseNotify("PulseHub", "Feature engine unloaded; base tabs remain open") end)

    -- Apply persisted states that require an explicit setup function.
    pcall(setAntiAfk, Hub.state.antiAfk)
    pcall(fpsApply)
    if Hub.state.fly then pcall(startFly) end
    if Hub.state.invis then pcall(setLocalInvisible, true) end
    if Hub.state.xray then pcall(setXray, true) end
    if Hub.state.chams then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then pcall(applyChams, p) end end end
    if Hub.state.trail then pcall(applyTrail) end
    if Hub.state.speedOn then pcall(setSpeed) end
    if Hub.state.jumpOn then pcall(setJump) end
    if Hub.state.korblox then pcall(setKorblox, true) end
    if Hub.state.headless then pcall(setHeadless, true) end
    if Hub.state.toyOn then pcall(makeToy, Hub.state.toy) end
    if Hub.state.animAuto then pcall(setAnimations, Hub.state.packSel) end
    if Hub.state.fullbright then
        pcall(setPreset, "bright")
    elseif Hub.state.lightingPreset and Hub.state.lightingPreset ~= "None" then
        local presets = {Night="night", Bright="bright", Clean="clean"}
        pcall(setPreset, presets[Hub.state.lightingPreset])
    end

-- background loops -----------------------------------------------------------
saveOriginalLighting()
fovInit(); installSilentHook(); initBacktrack(); playerWatch(); roundLoops(); refreshFlingConnections(); applyNoclip(); setAntiAfk(Hub.state.antiAfk); fpsApply(); if Hub.state.trail then applyTrail() end; if Hub.state.xray then setXray(true) end; if Hub.state.chams then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then applyChams(p) end end end
-- Legacy scene post-FX are intentionally not auto-created; the visual tab stays lightweight.

pushConn(RunService.RenderStepped:Connect(function()
    if not Hub.alive then return end
    Camera = workspace.CurrentCamera
    local now=os.clock()
    if Hub.state.esp then pcall(espStep) end
    if Hub.state.gunEsp then pcall(gunEspStep) end
    if Hub.state.aimOn and Hub.state.fovShow then pcall(fovStep) end
    if Hub.state.aimOn or Hub.state.knifeAim then pcall(cameraAimStep) end
    if Hub.state.backtrack and (not Hub._backtrackNext or now>=Hub._backtrackNext) then Hub._backtrackNext=now+0.05; pcall(renderBacktrack) end
    if Hub.state.desync and (not Hub._desyncNext or now>=Hub._desyncNext) then Hub._desyncNext=now+0.035; pcall(setDesync) end
    if Hub.state.faceThreat and (not Hub._faceNext or now>=Hub._faceNext) then Hub._faceNext=now+0.05; pcall(faceThreat) end
    if Hub.state.spin then
        local _,h,r=livingCharacter(LocalPlayer)
        if h and r then
            local dt=math.clamp(now-(Hub.spinLast or now),0,0.05)
            Hub.spinLast=now; h.AutoRotate=false
            Hub.spinAngle=(Hub.spinAngle or 0)+math.rad((tonumber(Hub.state.spinSpeed) or 20)*6)*dt
            pcall(function() r.CFrame=CFrame.new(r.Position)*CFrame.Angles(0,Hub.spinAngle,0) end)
        end
    end
    if Hub.state.bhop then
        if not Hub._bhopSpeedNext or now>=Hub._bhopSpeedNext then
            Hub._bhopSpeedNext=now+0.08
            local _,h,r=livingCharacter(LocalPlayer)
            if h then
                pcall(function() h.WalkSpeed=math.clamp(tonumber(Hub.state.bhopSpeed) or 28,10,80) end)
                if Hub.state.bhopAutoJump and r and h.FloorMaterial~=Enum.Material.Air and (not Hub._bhopJumpNext or now>=Hub._bhopJumpNext) then
                    Hub._bhopJumpNext=now+0.08
                    h.Jump=true
                end
            end
        end
    elseif Hub.state.speedOn and not Hub.state.fly then
        if not Hub._walkSpeedNext or now>=Hub._walkSpeedNext then
            Hub._walkSpeedNext=now+0.12
            local _,h=livingCharacter(LocalPlayer)
            if h then pcall(function() h.WalkSpeed=math.clamp(tonumber(Hub.state.walkSpeed) or 40,16,200) end) end
        end
    end
    antiFlingStep()
    if Hub.state.bringMurderer or Hub.state.bringSheriff or Hub.state.bringInnocent or Hub.state.staticMurderer or Hub.state.bringGunDrop or Hub.state.antiThrow then
        pcall(sourceBringStep)
    elseif staticMurdererCache then
        pcall(restoreStaticMurderer)
    end
    if Hub.state.orbit then
        local p=orbitTarget(); local _,_,tr=aliveCharacter(p); local _,_,me=aliveCharacter(LocalPlayer)
        if tr and me then local tt=os.clock()*Hub.state.orbitSpeed; local off=V3(math.cos(tt),0,math.sin(tt))*Hub.state.orbitRadius; me.CFrame=CFrame.lookAt(tr.Position+off,tr.Position) end
    end
    if Hub.state.clickFling and not Hub.clickFlingConn then refreshFlingConnections() end
    if Hub.state.touchFling and not Hub.touchFlingConn then refreshFlingConnections() end
end))

pushConn(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)
    Hub.state.bhopSpeed = math.clamp(tonumber(Hub.state.bhopSpeed) or 28,10,80)
    setSpeed(); setJump(); if Hub.state.spin then setSpin(true) end setHeadless(Hub.state.headless); setLocalInvisible(Hub.state.invis); applyTrail();
    if Hub.state.animAuto then setAnimations(Hub.state.packSel) end
    if Hub.state.toyOn then makeToy(Hub.state.toy) end
    if Hub.state.chams then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then applyChams(p) end end end
    if Hub.state.xray then setXray(true) end
    refreshFlingConnections()
    if Hub.state.lightingPreset and Hub.state.lightingPreset~="None" then
        local mp={Night="night",Bright="bright",Clean="clean"}
        pcall(setPreset,mp[Hub.state.lightingPreset])
    end
    if Hub.state.farmFling then
        task.delay(0.7,function() local p=nearestTarget(); if p then fling(p,0.8) end end)
    end
end))

-- periodic status
 task.spawn(function()
    local wasRound=false
    while Hub.alive do
        local nowRound=roundActive()
        if nowRound ~= wasRound then
            Hub.roundChangedAt=os.clock()
            Hub.antiFlingTeleportGraceUntil=os.clock()+1.35
            Hub.antiFlingSafeCF=select(3,aliveCharacter(LocalPlayer)) and select(3,aliveCharacter(LocalPlayer)).CFrame or Hub.antiFlingSafeCF
            Hub.antiFlingLastPos=select(3,aliveCharacter(LocalPlayer)) and select(3,aliveCharacter(LocalPlayer)).Position or Hub.antiFlingLastPos
            Hub.antiFlingLastTime=os.clock()
        end
        if Hub.state.music and nowRound and not wasRound then musicPlayRandom() end
        wasRound=nowRound
        local ping=0
        safe(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        Hub.lastPing=ping
        if Hub.state.chams and (not Hub._chamsNext or os.clock()>=Hub._chamsNext) then
            Hub._chamsNext=os.clock()+0.80
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer then pcall(applyChams,p) end
            end
        end
        -- Status display is provided by the shared WindUI window.
        task.wait(0.25)
    end
end)

function Hub.Unload()
    if not Hub.alive then return end
    saveConfig()
    Hub.alive=false
    musicStop(); stopFly()
    pcall(function() if Hub.clickFlingConn then Hub.clickFlingConn:Disconnect(); Hub.clickFlingConn=nil end end)
    pcall(function() if Hub.touchFlingConn then Hub.touchFlingConn:Disconnect(); Hub.touchFlingConn=nil end end)
    pcall(function() if Hub.activeFlingConn then Hub.activeFlingConn:Disconnect(); Hub.activeFlingConn=nil end end)
    setXray(false)
    for _,e in pairs(Hub.backtrack) do if e.ghost then pcall(function() e.ghost:Destroy() end) end end
    for _,p in ipairs(Players:GetPlayers()) do
        clearEspFor(p)
        local c=p.Character
        if c then destroyName(c,{"PulseCham","PulseTag","PulseBacktrack","PulseTrailA0","PulseTrailA1","PulseTrail"}) end
    end
    for _,f in ipairs(Hub.cleanups) do pcall(f) end
    for _,c in ipairs(Hub.conns) do pcall(function() c:Disconnect() end) end
    for k,v in pairs(Hub.originalLighting) do pcall(function() Lighting[k]=v end) end
    for _,n in ipairs({"PulseBloom","PulseAtmosphere","PulseRays","PulseBlur","PulseDof","PulseFog"}) do local o=Lighting:FindFirstChild(n); if o then o:Destroy() end end
    resetNoclip()
    pcall(restoreStaticMurderer)
    setLocalInvisible(false)
    for d,old in pairs(Hub.optStore or {}) do if d and d.Parent then pcall(function() if old.transparency~=nil then d.Transparency=old.transparency end; if old.enabled~=nil then d.Enabled=old.enabled end; if old.shadow~=nil then d.CastShadow=old.shadow end; if old.material~=nil then d.Material=old.material end; if old.reflect~=nil and d:IsA("MeshPart") then d.Reflectance=old.reflect end end) end end
    pcall(function() if espGui then espGui:Destroy() end end)
    -- The shared WindUI window is owned by the outer hub.
    Env.PulseHub = nil
end

Env.PulseHub = Hub
notify("PulseHub feature modules loaded inside shared WindUI")


    pushConn(UIS.InputBegan:Connect(function(input, processed)
        if processed or not Hub.alive then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Hub.rightDown = true
            Hub.aimReturnCF = Camera.CFrame
        end
        if input.KeyCode == K.N and Hub.controls.noclip then Hub.controls.noclip.set(not Hub.state.noclip) end
        if input.KeyCode == K.J and Hub.controls.infJump then Hub.controls.infJump.set(not Hub.state.infJump) end
        if input.KeyCode == K.F and Hub.controls.fly then Hub.controls.fly.set(not Hub.state.fly) end
        if input.KeyCode == K.X and Hub.controls.spin then Hub.controls.spin.set(not Hub.state.spin) end
        if input.KeyCode == K.B and Hub.controls.bhop then Hub.controls.bhop.set(not Hub.state.bhop) end
        if input.KeyCode == K.V then bombJump() end
    end))
    pushConn(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Hub.rightDown = false
            if Hub.state.aimReturn and Hub.state.aimVersion == "Camera" and Hub.aimReturnCF then
                safe(function()
                    TweenService:Create(Camera, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame=Hub.aimReturnCF}):Play()
                end)
            end
        end
    end))
    pushConn(UIS.JumpRequest:Connect(function()
        if not Hub.alive then return end
        local _, humanoid, root = livingCharacter(LocalPlayer)
        if Hub.state.bhop and humanoid and root then
            pcall(function()
                humanoid.WalkSpeed = math.clamp(tonumber(Hub.state.bhopSpeed) or 28, 10, 80)
                if Hub.state.bhopAutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        elseif Hub.state.infJump and humanoid then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end))
    Env.PulseHub = Hub
    pulseNotify("WindUI Modules", "Advanced feature tabs added to the shared window")
    return Hub
end

PulseHubController = installPulseHubWindUI(WindUI, Window, VisualTab, UtilityTab, FarmTab, ExtraTab)

