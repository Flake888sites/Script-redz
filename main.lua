local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local TixSettings = {
    Sticky = false,
    WallCheck = true,
    TeamCheck = false,
    FriendCheck = false,
    ESP = false,
    FOV = 150,
    Smoothness = 1,
    CircleVis = false,
    Optimizer = false,
    Triggerbot = false,
    Auto360 = false,
    SpinSpeed = 15,
    TargetPart = "Head",
    Humanized = false,
}

-- REDZ THEME COLORS
local RedzPrimary = Color3.fromRGB(220, 0, 0)
local RedzDarkBg  = Color3.fromRGB(12, 5, 5)
local RedzCardBg  = Color3.fromRGB(22, 10, 10)
local OffText     = Color3.fromRGB(170, 150, 150)

-- Cache de Amigos
local friendCache = {}
local function isFriend(player)
    if friendCache[player.UserId] ~= nil then return friendCache[player.UserId] end
    friendCache[player.UserId] = false
    task.spawn(function()
        local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        if ok then friendCache[player.UserId] = res end
    end)
    return friendCache[player.UserId]
end

-- Drawings
local Circle = Drawing.new("Circle")
Circle.Visible   = false
Circle.Thickness = 2
Circle.NumSides  = 64
Circle.Radius    = TixSettings.FOV
Circle.Filled    = false

local visualCache  = {}
local BoneStructure = {
    R15 = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    },
    R6 = {
        {"Head","Torso"},
        {"Torso","Left Arm"},{"Torso","Right Arm"},
        {"Torso","Left Leg"},{"Torso","Right Leg"},
    },
}

-- ============================================================
-- UI
-- ============================================================
local TixUI = Instance.new("ScreenGui")
TixUI.Name         = "REDZ_XITER_V2"
TixUI.Parent       = gethui and gethui() or game:GetService("CoreGui")
TixUI.ResetOnSpawn = false

local TogglePanel = Instance.new("Frame", TixUI)
TogglePanel.Size             = UDim2.new(0, 55, 0, 45)
TogglePanel.Position         = UDim2.new(0, 20, 0, 20)
TogglePanel.BackgroundColor3 = RedzDarkBg
TogglePanel.Active           = true
TogglePanel.Draggable        = true
Instance.new("UICorner", TogglePanel)
local ToggleStroke = Instance.new("UIStroke", TogglePanel)
ToggleStroke.Thickness = 2
ToggleStroke.Color     = RedzPrimary

local ToggleBtn = Instance.new("TextButton", TogglePanel)
ToggleBtn.Size               = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text               = "REDZ"
ToggleBtn.Font               = Enum.Font.GothamBold
ToggleBtn.TextColor3         = RedzPrimary
ToggleBtn.TextSize           = 14

local Main       = Instance.new("Frame", TixUI)
local VisiblePos = UDim2.new(0.5, -180, 0.5, -145)
local HiddenPos  = UDim2.new(0.5, -180, 1.2, 0)
Main.Size             = UDim2.new(0, 360, 0, 290)
Main.Position         = HiddenPos
Main.BackgroundColor3 = RedzDarkBg
Main.Visible          = false
Main.Active           = true
Main.Draggable        = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 2
MainStroke.Color     = RedzPrimary

local Title = Instance.new("TextLabel", Main)
Title.Size               = UDim2.new(1, 0, 0, 50)
Title.Text               = "REDZ XITER"
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 22
Title.BackgroundTransparency = 1
Title.TextColor3         = RedzPrimary

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size               = UDim2.new(0, 30, 0, 30)
CloseBtn.Position           = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text               = "x"
CloseBtn.Font               = Enum.Font.GothamBold
CloseBtn.TextColor3         = RedzPrimary
CloseBtn.TextSize           = 25

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = true; TogglePanel.Visible = false
    Main:TweenPosition(VisiblePos, "Out", "Quart", 0.5, true)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main:TweenPosition(HiddenPos, "In", "Quart", 0.4, true, function()
        Main.Visible = false; TogglePanel.Visible = true
    end)
end)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size                = UDim2.new(1, -20, 1, -70)
Scroll.Position            = UDim2.new(0, 10, 0, 60)
Scroll.BackgroundTransparency = 1
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness  = 2
Scroll.ScrollBarImageColor3 = RedzPrimary
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 6)

-- ============================================================
-- Componentes UI
-- ============================================================
local function AddToggle(text, settingKey)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size             = UDim2.new(1, -5, 0, 42)
    btn.BackgroundColor3 = RedzCardBg
    btn.Text             = ""
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn)
    local BStroke = Instance.new("UIStroke", btn)
    BStroke.Thickness = 1; BStroke.Color = RedzPrimary; BStroke.Transparency = 0.8

    local Label = Instance.new("TextLabel", btn)
    Label.Size               = UDim2.new(1, -60, 1, 0)
    Label.Position           = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text               = text
    Label.Font               = Enum.Font.GothamBold
    Label.TextColor3         = RedzPrimary
    Label.TextSize           = 14
    Label.TextXAlignment     = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", btn)
    Status.Size              = UDim2.new(0, 40, 1, 0)
    Status.Position          = UDim2.new(1, -55, 0, 0)
    Status.BackgroundTransparency = 1
    Status.Text              = "OFF"
    Status.Font              = Enum.Font.GothamBold
    Status.TextColor3        = OffText
    Status.TextSize          = 13
    Status.TextXAlignment    = Enum.TextXAlignment.Right

    btn.MouseButton1Click:Connect(function()
        TixSettings[settingKey] = not TixSettings[settingKey]
        local s = TixSettings[settingKey]
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = s and Color3.fromRGB(60,5,5) or RedzCardBg}):Play()
        Status.Text      = s and "ON" or "OFF"
        Status.TextColor3 = s and RedzPrimary or OffText
        if settingKey == "CircleVis" then Circle.Visible = s end
    end)
    return {Label = Label, Status = Status}
end

local function AddSlider(text, settingKey, min, max, default)
    TixSettings[settingKey] = default
    local container = Instance.new("Frame", Scroll)
    container.Size             = UDim2.new(1, -5, 0, 50)
    container.BackgroundColor3 = RedzCardBg
    Instance.new("UICorner", container)
    local BStroke = Instance.new("UIStroke", container)
    BStroke.Thickness = 1; BStroke.Color = RedzPrimary; BStroke.Transparency = 0.8

    local Label = Instance.new("TextLabel", container)
    Label.Size               = UDim2.new(1, -20, 0, 20)
    Label.Position           = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text               = text .. ": " .. tostring(default)
    Label.Font               = Enum.Font.GothamBold
    Label.TextColor3         = RedzPrimary
    Label.TextSize           = 14
    Label.TextXAlignment     = Enum.TextXAlignment.Left

    local SliderBar = Instance.new("Frame", container)
    SliderBar.Size             = UDim2.new(1, -30, 0, 6)
    SliderBar.Position         = UDim2.new(0, 15, 0, 32)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 5, 5)
    Instance.new("UICorner", SliderBar)

    local SliderBtn = Instance.new("TextButton", SliderBar)
    SliderBtn.Size             = UDim2.new(0, 14, 0, 14)
    SliderBtn.Position         = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    SliderBtn.BackgroundColor3 = RedzPrimary
    SliderBtn.Text             = ""
    Instance.new("UICorner", SliderBtn)

    local dragging = false
    local function update(input)
        local rx = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local val = math.round(min + (max - min) * rx)
        SliderBtn.Position      = UDim2.new(rx, -7, 0.5, -7)
        TixSettings[settingKey] = val
        Label.Text              = text .. ": " .. tostring(val)
    end
    SliderBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function AddSelector(text, settingKey, options)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size             = UDim2.new(1, -5, 0, 42)
    btn.BackgroundColor3 = RedzCardBg
    btn.Text             = ""
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn)
    local BStroke = Instance.new("UIStroke", btn)
    BStroke.Thickness = 1; BStroke.Color = RedzPrimary; BStroke.Transparency = 0.8

    local Label = Instance.new("TextLabel", btn)
    Label.Size           = UDim2.new(1, -120, 1, 0)
    Label.Position       = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text           = text
    Label.Font           = Enum.Font.GothamBold
    Label.TextColor3     = RedzPrimary
    Label.TextSize       = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", btn)
    Status.Size          = UDim2.new(0, 100, 1, 0)
    Status.Position      = UDim2.new(1, -115, 0, 0)
    Status.BackgroundTransparency = 1
    Status.Text          = tostring(TixSettings[settingKey]):upper()
    Status.Font          = Enum.Font.GothamBold
    Status.TextColor3    = RedzPrimary
    Status.TextSize      = 13
    Status.TextXAlignment = Enum.TextXAlignment.Right

    local idx = 1
    for i, v in ipairs(options) do if v == TixSettings[settingKey] then idx = i break end end

    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        TixSettings[settingKey] = options[idx]
        Status.Text = tostring(options[idx]):upper()
        btn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
        task.wait(0.1)
        btn.BackgroundColor3 = RedzCardBg
    end)
end

-- Monta os toggles
AddToggle("Sticky Aim",          "Sticky")
AddToggle("Simulacao Humana",    "Humanized")
AddToggle("Wall Check",          "WallCheck")
AddToggle("Team Check",          "TeamCheck")
AddToggle("Friend Check",        "FriendCheck")
AddToggle("Visual ESP + Skeleton","ESP")
AddToggle("Auto 360 On Jump",    "Auto360")
AddToggle("Trigger Bot",         "Triggerbot")
AddToggle("FPS Otimizador",      "Optimizer")
AddToggle("Show FOV",            "CircleVis")
AddSelector("Puxar Em (Target)", "TargetPart", {"Head", "Torso", "HumanoidRootPart"})
AddSlider("Tamanho do FOV",      "FOV",         10,  600, 150)
AddSlider("Suavidade",           "Smoothness",   1,   50,   1)
AddSlider("Velocidade do 360",   "SpinSpeed",    5,   30,  15)

-- ============================================================
-- Estado de humanizacao (spring de noise)
-- ============================================================
local hNoise = { x=0, y=0, vx=0, vy=0 }

local function stepHumanize(dt)
    local strength = 0.5
    local stiffness = 9
    local damping   = 0.72
    local tx = math.sin(tick()*7.3)*strength + math.sin(tick()*2.9)*strength*0.4
    local ty = math.cos(tick()*6.1)*strength + math.cos(tick()*2.4)*strength*0.4
    hNoise.vx = (hNoise.vx + (tx - hNoise.x) * stiffness * dt) * damping
    hNoise.vy = (hNoise.vy + (ty - hNoise.y) * stiffness * dt) * damping
    hNoise.x  = hNoise.x + hNoise.vx
    hNoise.y  = hNoise.y + hNoise.vy
end

-- ============================================================
-- Background threads
-- ============================================================
task.spawn(function()
    while task.wait(2) do
        if TixSettings.Optimizer then
            pcall(function()
                game:GetService("Lighting").GlobalShadows = false
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                        v.Material = Enum.Material.Plastic; v.Reflectance = 0
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                        v.Enabled = false
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(10) do
        for _, visual in pairs(visualCache) do
            pcall(function()
                if visual.High then visual.High:Destroy() end
                if visual.Bones then for _, l in pairs(visual.Bones) do l:Remove() end end
            end)
        end
        table.clear(visualCache)
    end
end)

-- ============================================================
-- Auto 360
-- ============================================================
local isSpinning = false
local function do360Spin()
    if isSpinning then return end
    isSpinning = true
    local deg = 0
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if TixSettings.Auto360 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp   = LocalPlayer.Character.HumanoidRootPart
            local speed = TixSettings.SpinSpeed
            hrp.CFrame    = hrp.CFrame * CFrame.Angles(0, math.rad(speed), 0)
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(speed), 0)
            deg = deg + speed
            if deg >= 360 then conn:Disconnect(); isSpinning = false end
        else conn:Disconnect(); isSpinning = false end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").Jumping:Connect(function(active)
        if active and TixSettings.Auto360 then do360Spin() end
    end)
end)
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    LocalPlayer.Character.Humanoid.Jumping:Connect(function(active)
        if active and TixSettings.Auto360 then do360Spin() end
    end)
end

-- ============================================================
-- Helpers de aimbot
-- ============================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(targetPart)
    if not TixSettings.WallCheck then return true end
    local char = LocalPlayer.Character
    rayParams.FilterDescendantsInstances = char and {char} or {}
    local origin = Camera.CFrame.Position
    local dir    = targetPart.Position - origin
    local result = workspace:Raycast(origin, dir, rayParams)
    return result ~= nil and result.Instance ~= nil and result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getChosenPart(character)
    local p = TixSettings.TargetPart
    if p == "Torso" then
        return character:FindFirstChild("Torso")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild(p) or character:FindFirstChild("Head")
end

local function getClosest()
    local target, best = nil, TixSettings.FOV
    local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    for _, v in pairs(Players:GetPlayers()) do
        if v == LocalPlayer then continue end
        if not (v.Character and v.Character:FindFirstChild("Humanoid")) then continue end
        if v.Character.Humanoid.Health <= 0 then continue end
        if TixSettings.TeamCheck and v.Team == LocalPlayer.Team then continue end
        if TixSettings.FriendCheck and isFriend(v) then continue end
        local part = getChosenPart(v.Character)
        if not part then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen and isVisible(part) then
            local dist = (Vector2.new(sp.X, sp.Y) - Vector2.new(cx, cy)).Magnitude
            if dist < best then target = part; best = dist end
        end
    end
    return target
end

local function clearSkeleton(visual)
    if visual.Bones then
        for _, line in pairs(visual.Bones) do line.Visible = false end
    end
end

-- ============================================================
-- Loop principal
-- ============================================================
local lastTrigger = 0

RunService.RenderStepped:Connect(function(dt)
    -- FOV circle
    Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    Circle.Radius   = TixSettings.FOV
    Circle.Color    = RedzPrimary
    Circle.Visible  = TixSettings.CircleVis
    MainStroke.Color   = RedzPrimary
    ToggleStroke.Color = RedzPrimary
    Title.TextColor3   = RedzPrimary

    -- ============================================================
    -- AIMBOT
    -- Calcula o delta em pixels entre o centro da tela e o alvo,
    -- aplica suavidade e usa mousemoverel para mover a camera
    -- de forma identica ao movimento fisico do mouse.
    -- ============================================================
    if TixSettings.Sticky then
        local lock = getClosest()
        if lock then
            local cx, cy = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
            local sp, onScreen = Camera:WorldToViewportPoint(lock.Position)

            if onScreen then
                local dx = sp.X - cx
                local dy = sp.Y - cy

                -- Smoothness=1 move tudo de vez; valores maiores suavizam
                local s = math.max(TixSettings.Smoothness, 1)
                local moveX = dx / s
                local moveY = dy / s

                -- Humanizacao: micro-drift sobre o movimento
                if TixSettings.Humanized then
                    stepHumanize(dt)
                    local mag = math.sqrt(dx*dx + dy*dy)
                    local shakeMult = math.clamp(mag / 100, 0, 1)
                    moveX = moveX + hNoise.x * shakeMult
                    moveY = moveY + hNoise.y * shakeMult
                end

                if mousemoverel then
                    -- Metodo principal: simula mouse fisico
                    mousemoverel(moveX, moveY)
                else
                    -- Fallback para executores sem mousemoverel
                    local camPos    = Camera.CFrame.Position
                    local targetCF  = CFrame.new(camPos, lock.Position)
                    local lerpAlpha = math.clamp(1 / s, 0.01, 1)
                    Camera.CFrame   = Camera.CFrame:Lerp(targetCF, lerpAlpha)
                end
            end
        end
    end

    -- Triggerbot
    if TixSettings.Triggerbot and (tick() - lastTrigger) > 0.05 then
        local mt = LocalPlayer:GetMouse().Target
        if mt and mt.Parent then
            local obj = mt.Parent
            if obj:IsA("Accessory") then obj = obj.Parent end
            local hum  = obj:FindFirstChildOfClass("Humanoid")
            local pTgt = Players:GetPlayerFromCharacter(obj)
            if pTgt and pTgt ~= LocalPlayer
                and (not TixSettings.TeamCheck  or pTgt.Team ~= LocalPlayer.Team)
                and (not TixSettings.FriendCheck or not isFriend(pTgt))
                and hum and hum.Health > 0
            then
                lastTrigger = tick()
                if mouse1click then
                    mouse1click()
                else
                    local vim = game:GetService("VirtualInputManager")
                    if vim then
                        local mx, my = LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y
                        vim:SendMouseButtonEvent(mx, my, 0, true,  game, 1)
                        task.wait()
                        vim:SendMouseButtonEvent(mx, my, 0, false, game, 1)
                    end
                end
            end
        end
    end

    -- ESP (Chams + Skeleton)
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            table.insert(targets, p.Character)
        end
    end

    for _, char in pairs(targets) do
        if not visualCache[char] then
            visualCache[char] = { High = Instance.new("Highlight", TixUI), Bones = {} }
            for _ = 1, 14 do
                local l = Drawing.new("Line")
                l.Thickness   = 1.5
                l.Transparency = 1
                table.insert(visualCache[char].Bones, l)
            end
        end

        local visual  = visualCache[char]
        local head    = char:FindFirstChild("Head")
        local hum     = char:FindFirstChild("Humanoid")
        local isAlive = head and hum and hum.Health > 0
        local espColor = RedzPrimary

        if TixSettings.ESP and isAlive and head then
            local char2 = LocalPlayer.Character
            rayParams.FilterDescendantsInstances = char2 and {char2} or {}
            local origin = Camera.CFrame.Position
            local result = workspace:Raycast(origin, head.Position - origin, rayParams)
            if result and result.Instance and result.Instance:IsDescendantOf(char) then
                espColor = Color3.fromRGB(0, 255, 0)
            end
        end

        visual.High.Enabled      = TixSettings.ESP and isAlive
        visual.High.Adornee      = char
        visual.High.FillColor    = espColor
        visual.High.OutlineColor = Color3.new(1, 1, 1)
        clearSkeleton(visual)

        if TixSettings.ESP and isAlive then
            local rigType  = (hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
            local boneList = BoneStructure[rigType]
            for i, pair in ipairs(boneList) do
                local pA = char:FindFirstChild(pair[1])
                local pB = char:FindFirstChild(pair[2])
                if pA and pB then
                    local sA, vA = Camera:WorldToViewportPoint(pA.Position)
                    local sB, vB = Camera:WorldToViewportPoint(pB.Position)
                    if vA and vB then
                        local line = visual.Bones[i]
                        if line then
                            line.Visible = true
                            line.From    = Vector2.new(sA.X, sA.Y)
                            line.To      = Vector2.new(sB.X, sB.Y)
                            line.Color   = espColor
                        end
                    end
                end
            end
        end
    end
end)
