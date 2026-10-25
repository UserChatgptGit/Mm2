--[[
    MM2 COMBINED HUB — WindUI
    Объединяет ESP / Gun ESP / Anti-Fling / TP to Gun / Auto Kill / Fling panel
    и Cosmic Autofarm v6.1.x в одном основном окне WindUI.

    Примечание: WindUI загружается из официального репозитория ниже.
    Оба исходных окна скрыты; функции исходных модулей сохранены внутри этого файла.
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

FlingButton.MouseButton1Click:Connect(ToggleFlingGUI)

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
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "MM2 HUB",
    Icon = "zap",
    Author = "Combined Modules",
    Folder = "MM2CombinedHub",
    Size = UDim2.fromOffset(650, 520),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 180,
    ScrollBarEnabled = true,
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
actionSection:Button({
    Title = "Open Target Fling Panel",
    Desc = "Open the original player-selection panel",
    Callback = function()
        local ok, err = pcall(ToggleFlingGUI)
        if not ok then
            warn("[MM2 HUB] Fling panel error: " .. tostring(err))
            uiNotify("Fling Panel", "Could not open the panel; see the console for details")
        end
    end,
})
actionSection:Paragraph({
    Title = "Note",
    Desc = "The target-selection panel remains a separate window because its original logic uses its own player list.",
})

-- Settings
local settingsSection = SettingsTab:Section({ Title = "Hub" })
settingsSection:Paragraph({
    Title = "Combined build",
    Desc = "The original modules are included in this file. Use this window for primary controls; legacy windows are hidden.",
})
settingsSection:Button({
    Title = "Stop Active Modules",
    Desc = "Stop farming and disable Auto Kill and manual flight",
    Callback = function()
        pcall(farmStop)
        pcall(function() setAutoKill(false) end)
        flags.fly = false
        uiNotify("MM2 HUB", "Active loops stopped")
    end,
})
settingsSection:Button({
    Title = "Unload WindUI Window",
    Desc = "Close the WindUI window only",
    Callback = function()
        pcall(function() Window:Destroy() end)
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
