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
    ESPBox = false,
    ESPSkeleton = false,
    ESPHealth = false,
    ESPName = false,
    ESPDistance = false,
    FOV = 150,
    Smoothness = 1,
    CircleVis = false,
    Optimizer = false,
    Triggerbot = false,
    Auto360 = false,
    SpinSpeed = 15,
    TargetPart = "Head",
}

-- REDZ THEME COLORS
local RedzPrimary = Color3.fromRGB(220, 0, 0)
local RedzDarkBg = Color3.fromRGB(12, 5, 5)
local RedzCardBg = Color3.fromRGB(22, 10, 10)
local OffText = Color3.fromRGB(170, 150, 150)

-- Cache de Amigos
local friendCache = {}
local function isFriend(player)
    if friendCache[player.UserId] ~= nil then return friendCache[player.UserId] end
    friendCache[player.UserId] = false
    task.spawn(function()
        local success, result = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        if success then friendCache[player.UserId] = result end
    end)
    return friendCache[player.UserId]
end

-- Drawings
local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = 2
Circle.NumSides = 64
Circle.Radius = TixSettings.FOV
Circle.Filled = false

local visualCache = {}
-- visualCache[char] = {
--   High    = Highlight (box/chams),
--   Bones   = {Line, ...} (skeleton),
--   HpBar   = {bg=Line, fill=Line} (health bar),
--   NameTag = Drawing Text (name),
--   DistTag = Drawing Text (distance),
-- }
local BoneStructure = {
    R15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    },
    R6 = {
        {"Head", "Torso"},
        {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
}

local TixUI = Instance.new("ScreenGui")
TixUI.Name = "REDZ_XITER_V2"
TixUI.Parent = gethui and gethui() or game:GetService("CoreGui")
TixUI.ResetOnSpawn = false

local TogglePanel = Instance.new("Frame", TixUI)
TogglePanel.Size = UDim2.new(0, 55, 0, 45)
TogglePanel.Position = UDim2.new(0, 20, 0, 20)
TogglePanel.BackgroundColor3 = RedzDarkBg
TogglePanel.Active = true
TogglePanel.Draggable = true
Instance.new("UICorner", TogglePanel)
local ToggleStroke = Instance.new("UIStroke", TogglePanel)
ToggleStroke.Thickness = 2
ToggleStroke.Color = RedzPrimary

local ToggleBtn = Instance.new("TextButton", TogglePanel)
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = "REDZ"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = RedzPrimary
ToggleBtn.TextSize = 14

local Main = Instance.new("Frame", TixUI)
local VisiblePos = UDim2.new(0.5, -180, 0.5, -140)
local HiddenPos = UDim2.new(0.5, -180, 1.2, 0)
Main.Size = UDim2.new(0, 360, 0, 280) 
Main.Position = HiddenPos
Main.BackgroundColor3 = RedzDarkBg
Main.Visible = false
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 2
MainStroke.Color = RedzPrimary

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Text = "REDZ XITER"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.BackgroundTransparency = 1
Title.TextColor3 = RedzPrimary

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = RedzPrimary
CloseBtn.TextSize = 25

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = true; TogglePanel.Visible = false
    Main:TweenPosition(VisiblePos, "Out", "Quart", 0.5, true)
end)

CloseBtn.MouseButton1Click:Connect(function()
    Main:TweenPosition(HiddenPos, "In", "Quart", 0.4, true, function()
        Main.Visible = false; TogglePanel.Visible = true
    end)
end)

-- ── TAB BAR ────────────────────────────────────────────────
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, -20, 0, 28)
TabBar.Position = UDim2.new(0, 10, 0, 46)
TabBar.BackgroundTransparency = 1

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 6)

local function MakeTab(label)
    local tb = Instance.new("TextButton", TabBar)
    tb.Size = UDim2.new(0, 148, 1, 0)
    tb.BackgroundColor3 = RedzCardBg
    tb.AutoButtonColor = false
    tb.Text = label
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 13
    tb.TextColor3 = OffText
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", tb)
    s.Thickness = 1; s.Color = RedzPrimary; s.Transparency = 0.7
    return tb, s
end

local TabAimbot, TabAimbotStroke = MakeTab("Aimbot")
local TabVisual, TabVisualStroke = MakeTab("Visual & ESP")

-- shared scroll factory
local function MakeScroll(parent)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size = UDim2.new(1, -20, 1, -90)
    s.Position = UDim2.new(0, 10, 0, 82)
    s.BackgroundTransparency = 1
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.ScrollBarThickness = 2
    s.ScrollBarImageColor3 = RedzPrimary
    s.Visible = false
    local l = Instance.new("UIListLayout", s); l.Padding = UDim.new(0, 6)
    return s
end

local ScrollAimbot = MakeScroll(Main)
local ScrollVisual = MakeScroll(Main)

-- Tab switch logic
local function activateTab(scroll, tabBtn, tabStroke, otherScroll, otherBtn, otherStroke)
    scroll.Visible = true
    otherScroll.Visible = false
    tabBtn.TextColor3 = RedzPrimary
    tabBtn.BackgroundColor3 = Color3.fromRGB(50, 5, 5)
    tabStroke.Transparency = 0
    otherBtn.TextColor3 = OffText
    otherBtn.BackgroundColor3 = RedzCardBg
    otherStroke.Transparency = 0.7
end

TabAimbot.MouseButton1Click:Connect(function()
    activateTab(ScrollAimbot, TabAimbot, TabAimbotStroke, ScrollVisual, TabVisual, TabVisualStroke)
end)
TabVisual.MouseButton1Click:Connect(function()
    activateTab(ScrollVisual, TabVisual, TabVisualStroke, ScrollAimbot, TabAimbot, TabAimbotStroke)
end)

-- Start on Aimbot tab
activateTab(ScrollAimbot, TabAimbot, TabAimbotStroke, ScrollVisual, TabVisual, TabVisualStroke)

-- Scroll is now an alias so existing AddToggle/AddSlider/AddSelector functions work
-- We override Scroll per section below using a wrapper approach
local Scroll = ScrollAimbot  -- default target for helper functions

local function AddToggle(text, settingKey, targetScroll)
    targetScroll = targetScroll or Scroll
    local btn = Instance.new("TextButton", targetScroll)
    btn.Size = UDim2.new(1, -5, 0, 42)
    btn.BackgroundColor3 = RedzCardBg
    btn.Text = ""; btn.AutoButtonColor = false
    Instance.new("UICorner", btn)
    local BStroke = Instance.new("UIStroke", btn)
    BStroke.Thickness = 1; BStroke.Color = RedzPrimary; BStroke.Transparency = 0.8

    local Label = Instance.new("TextLabel", btn)
    Label.Size = UDim2.new(1, -60, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = text; Label.Font = Enum.Font.GothamBold
    Label.TextColor3 = RedzPrimary; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", btn)
    Status.Size = UDim2.new(0, 40, 1, 0); Status.Position = UDim2.new(1, -55, 0, 0)
    Status.BackgroundTransparency = 1; Status.Text = "OFF"; Status.Font = Enum.Font.GothamBold
    Status.TextColor3 = OffText; Status.TextSize = 13; Status.TextXAlignment = Enum.TextXAlignment.Right

    btn.MouseButton1Click:Connect(function()
        TixSettings[settingKey] = not TixSettings[settingKey]
        local s = TixSettings[settingKey]
        local targetColor = s and Color3.fromRGB(60, 5, 5) or RedzCardBg
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
        Status.Text = s and "ON" or "OFF"
        Status.TextColor3 = s and RedzPrimary or OffText
        if settingKey == "CircleVis" then Circle.Visible = s end
    end)
    return {Label = Label, Status = Status, Active = function() return TixSettings[settingKey] end}
end

local function AddSlider(text, settingKey, min, max, default, targetScroll)
    targetScroll = targetScroll or Scroll
    TixSettings[settingKey] = default
    local container = Instance.new("Frame", targetScroll)
    container.Size = UDim2.new(1, -5, 0, 50); container.BackgroundColor3 = RedzCardBg
    Instance.new("UICorner", container)
    local BStroke = Instance.new("UIStroke", container)
    BStroke.Thickness = 1; BStroke.Color = RedzPrimary; BStroke.Transparency = 0.8

    local Label = Instance.new("TextLabel", container)
    Label.Size = UDim2.new(1, -20, 0, 20); Label.Position = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1; Label.Text = text .. ": " .. tostring(default)
    Label.Font = Enum.Font.GothamBold; Label.TextColor3 = RedzPrimary; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left

    local SliderBar = Instance.new("Frame", container)
    SliderBar.Size = UDim2.new(1, -30, 0, 6); SliderBar.Position = UDim2.new(0, 15, 0, 32)
    SliderBar.BackgroundColor3 = Color3.fromRGB(50, 5, 5); Instance.new("UICorner", SliderBar)

    local SliderBtn = Instance.new("TextButton", SliderBar)
    SliderBtn.Size = UDim2.new(0, 14, 0, 14); SliderBtn.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    SliderBtn.BackgroundColor3 = RedzPrimary; SliderBtn.Text = ""; Instance.new("UICorner", SliderBtn)

    local dragging = false
    local function update(input)
        local relativeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local value = math.round(min + (max - min) * relativeX)
        SliderBtn.Position = UDim2.new(relativeX, -7, 0.5, -7)
        TixSettings[settingKey] = value
        Label.Text = text .. ": " .. tostring(value)
    end

    SliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function AddSelector(text, settingKey, options, targetScroll)
    targetScroll = targetScroll or Scroll
    local btn = Instance.new("TextButton", targetScroll)
    btn.Size = UDim2.new(1, -5, 0, 42); btn.BackgroundColor3 = RedzCardBg; btn.Text = ""; btn.AutoButtonColor = false
    Instance.new("UICorner", btn)
    local BStroke = Instance.new("UIStroke", btn)
    BStroke.Thickness = 1; BStroke.Color = RedzPrimary; BStroke.Transparency = 0.8

    local Label = Instance.new("TextLabel", btn)
    Label.Size = UDim2.new(1, -120, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = text; Label.Font = Enum.Font.GothamBold
    Label.TextColor3 = RedzPrimary; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", btn)
    Status.Size = UDim2.new(0, 100, 1, 0); Status.Position = UDim2.new(1, -115, 0, 0)
    Status.BackgroundTransparency = 1; Status.Text = tostring(TixSettings[settingKey]):upper()
    Status.Font = Enum.Font.GothamBold; Status.TextColor3 = RedzPrimary; Status.TextSize = 13; Status.TextXAlignment = Enum.TextXAlignment.Right

    local currentIndex = 1
    for i, v in ipairs(options) do if v == TixSettings[settingKey] then currentIndex = i break end end

    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        TixSettings[settingKey] = options[currentIndex]
        Status.Text = tostring(options[currentIndex]):upper()
        btn.BackgroundColor3 = Color3.fromRGB(40, 10, 10); task.wait(0.1); btn.BackgroundColor3 = RedzCardBg
    end)
end

-- ── AIMBOT TAB ──────────────────────────────────────────────
local indicators = {
    Sticky   = AddToggle("Sticky Aim",        "Sticky",      ScrollAimbot),
    Walls    = AddToggle("Wall Check",         "WallCheck",   ScrollAimbot),
    Teams    = AddToggle("Team Check",         "TeamCheck",   ScrollAimbot),
    Friends  = AddToggle("Friend Check",       "FriendCheck", ScrollAimbot),
    Trickshot= AddToggle("Auto 360 On Jump",   "Auto360",     ScrollAimbot),
    Trigger  = AddToggle("Trigger Bot",        "Triggerbot",  ScrollAimbot),
    Optimizer= AddToggle("FPS Otimizador",     "Optimizer",   ScrollAimbot),
    FOVCircle= AddToggle("Show FOV Circle",    "CircleVis",   ScrollAimbot),
}

AddSelector("Puxar Em (Target)", "TargetPart", {"Head", "Torso", "HumanoidRootPart"}, ScrollAimbot)
AddSlider("Tamanho do FOV",       "FOV",        10,  600, 150, ScrollAimbot)
AddSlider("Suavidade (Smoothness)","Smoothness",  1,  200,   1, ScrollAimbot)
AddSlider("Velocidade do 360",    "SpinSpeed",    5,   30,  15, ScrollAimbot)

AddSelector("Puxar Em (Target)", "TargetPart", {"Head", "Torso", "HumanoidRootPart"}, ScrollAimbot)
AddSlider("Tamanho do FOV",       "FOV",        10,  600, 150, ScrollAimbot)
AddSlider("Suavidade (Smoothness)","Smoothness",  1,  200,   1, ScrollAimbot)
AddSlider("Velocidade do 360",    "SpinSpeed",    5,   30,  15, ScrollAimbot)

-- ── VISUAL & ESP TAB ────────────────────────────────────────
AddToggle("ESP Box (Highlight)",    "ESPBox",       ScrollVisual)
AddToggle("ESP Skeleton",           "ESPSkeleton",  ScrollVisual)
AddToggle("ESP Health Bar",         "ESPHealth",    ScrollVisual)
AddToggle("ESP Nome",               "ESPName",      ScrollVisual)
AddToggle("ESP Distância",          "ESPDistance",  ScrollVisual)

-- Background Threads
task.spawn(function()
    while task.wait(2) do
        if TixSettings.Optimizer then
            pcall(function()
                game:GetService("Lighting").GlobalShadows = false
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                        v.Material = Enum.Material.Plastic; v.Reflectance = 0
                    elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled = false
                    end
                end
            end)
        end
    end
end)

local function cleanVisual(visual)
    pcall(function()
        if visual.High then visual.High:Destroy() end
        if visual.Bones then for _, l in pairs(visual.Bones) do l:Remove() end end
        if visual.HpBar then visual.HpBar.bg:Remove(); visual.HpBar.fill:Remove() end
        if visual.NameTag then visual.NameTag:Remove() end
        if visual.DistTag then visual.DistTag:Remove() end
    end)
end

task.spawn(function()
    while task.wait(10) do
        for char, visual in pairs(visualCache) do
            cleanVisual(visual)
        end
        table.clear(visualCache)
    end
end)

-- Limpa o cache do char antigo quando jogador renasce
for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(newChar)
        for char, visual in pairs(visualCache) do
            if char ~= newChar and Players:GetPlayerFromCharacter(char) == p then
                cleanVisual(visual)
                visualCache[char] = nil
            end
        end
    end)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(newChar)
        for char, visual in pairs(visualCache) do
            if char ~= newChar and Players:GetPlayerFromCharacter(char) == p then
                cleanVisual(visual)
                visualCache[char] = nil
            end
        end
    end)
end)

-- Limpa quando jogador sai
Players.PlayerRemoving:Connect(function(p)
    for char, visual in pairs(visualCache) do
        if Players:GetPlayerFromCharacter(char) == p then
            cleanVisual(visual)
            visualCache[char] = nil
        end
    end
end)

local isSpinning = false
local function do360Spin()
    if isSpinning then return end
    isSpinning = true
    local degreesRotated = 0
    local spinConnection
    spinConnection = RunService.RenderStepped:Connect(function()
        if TixSettings.Auto360 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local speed = TixSettings.SpinSpeed
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed), 0)
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(speed), 0)
            degreesRotated = degreesRotated + speed
            if degreesRotated >= 360 then spinConnection:Disconnect(); isSpinning = false end
        else spinConnection:Disconnect(); isSpinning = false end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Jumping:Connect(function(active) if active and TixSettings.Auto360 then do360Spin() end end)
end)

if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
    LocalPlayer.Character.Humanoid.Jumping:Connect(function(active) if active and TixSettings.Auto360 then do360Spin() end end)
end

local function isVisible(targetPart)
    if not TixSettings.WallCheck then return true end
    local ignoreList = {LocalPlayer.Character, Camera}
    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    if hit and hit:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

local function getChosenPart(character)
    local partName = TixSettings.TargetPart
    if partName == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild(partName) or character:FindFirstChild("Head")
end

local function getClosest()
    local target, shortestFOV = nil, TixSettings.FOV
    local potentials = {}
    for _,v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            if TixSettings.TeamCheck and v.Team == LocalPlayer.Team then continue end
            if TixSettings.FriendCheck and isFriend(v) then continue end
            local selectedPart = getChosenPart(v.Character)
            if selectedPart then table.insert(potentials, selectedPart) end
        end
    end

    for _, part in pairs(potentials) do
        local pos, vis = Camera:WorldToViewportPoint(part.Position)
        if vis and isVisible(part) then
            local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
            if mag < shortestFOV then target = part; shortestFOV = mag end
        end
    end
    return target
end

local function clearSkeleton(visual)
    if visual.Bones then for _, line in pairs(visual.Bones) do line.Visible = false end end
end

local lastTriggerClick = 0

RunService.RenderStepped:Connect(function()
    local accent = RedzPrimary

    -- CONFIGURAÇÃO DO CÍRCULO FOV
    Circle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    Circle.Radius = TixSettings.FOV
    Circle.Color = accent
    MainStroke.Color = accent
    ToggleStroke.Color = accent
    Title.TextColor3 = accent

    Circle.Visible = TixSettings.CircleVis

    -- LÓGICA DO AIMBOT STICKY
    if TixSettings.Sticky then
        local lock = getClosest()
        if lock then 
            local targetCFrame = CFrame.new(Camera.CFrame.Position, lock.Position)
            local lerpFactor = 1 / (1 + (TixSettings.Smoothness - 1) * 0.12)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(lerpFactor, 0, 1))
        end
    end

    -- LOGICA DO TRIGGER BOT
    if TixSettings.Triggerbot and tick() - lastTriggerClick > 0.05 then
        local mouseTarget = LocalPlayer:GetMouse().Target
        if mouseTarget and mouseTarget.Parent then
            local obj = mouseTarget.Parent
            if obj:IsA("Accessory") then obj = obj.Parent end
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local pTarget = Players:GetPlayerFromCharacter(obj)
            local isTriggerValid = false
            if pTarget and pTarget ~= LocalPlayer then
                if (not TixSettings.TeamCheck or pTarget.Team ~= LocalPlayer.Team) and (not TixSettings.FriendCheck or not isFriend(pTarget)) then
                    isTriggerValid = true
                end
            end
            if isTriggerValid and hum and hum.Health > 0 then
                lastTriggerClick = tick()
                if mouse1click then mouse1click()
                elseif game:GetService("VirtualInputManager") then
                    local mx, my = LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(mx, my, 0, true, game, 1)
                    task.wait()
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(mx, my, 0, false, game, 1)
                end
            end
        end
    end

    -- SISTEMA DE ESP
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            table.insert(targets, p)
        end
    end

    local anyESP = TixSettings.ESPBox or TixSettings.ESPSkeleton or TixSettings.ESPHealth or TixSettings.ESPName or TixSettings.ESPDistance

    for _, p in pairs(targets) do
        local char = p.Character
        -- Init visual cache entry
        if not visualCache[char] then
            local entry = { Bones = {} }

            -- Box (Highlight)
            local h = Instance.new("Highlight", TixUI)
            h.Enabled = false; entry.High = h

            -- Skeleton lines (14 for R15)
            for i = 1, 14 do
                local l = Drawing.new("Line")
                l.Thickness = 1.5; l.Transparency = 1; l.Visible = false
                table.insert(entry.Bones, l)
            end

            -- Health bar (background + fill)
            local hpBg = Drawing.new("Line"); hpBg.Thickness = 4; hpBg.Visible = false; hpBg.Color = Color3.fromRGB(30, 30, 30)
            local hpFill = Drawing.new("Line"); hpFill.Thickness = 3; hpFill.Visible = false
            entry.HpBar = {bg = hpBg, fill = hpFill}

            -- Name tag
            local nt = Drawing.new("Text"); nt.Size = 13; nt.Font = 2; nt.Center = true; nt.Outline = true; nt.Visible = false
            entry.NameTag = nt

            -- Distance tag
            local dt = Drawing.new("Text"); dt.Size = 12; dt.Font = 2; dt.Center = true; dt.Outline = true; dt.Visible = false
            entry.DistTag = dt

            visualCache[char] = entry
        end

        local visual = visualCache[char]
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChild("Humanoid")
        local isAlive = head and hum and hum.Health > 0

        -- Cor base: vermelho (accent), fica verde quando visível
        local espColor = accent

        if anyESP and isAlive and head then
            local ignoreList = {LocalPlayer.Character, Camera}
            local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
            if hit and hit:IsDescendantOf(char) then espColor = Color3.fromRGB(0, 255, 0) end
        end

        -- ── ESP BOX ──────────────────────────────────────────
        visual.High.Enabled = TixSettings.ESPBox and isAlive
        if TixSettings.ESPBox and isAlive then
            visual.High.Adornee = char
            visual.High.FillColor = espColor
            visual.High.OutlineColor = Color3.new(1, 1, 1)
        end

        -- ── ESP SKELETON ─────────────────────────────────────
        clearSkeleton(visual)
        if TixSettings.ESPSkeleton and isAlive then
            local rigType = (hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
            for index, bonePair in ipairs(BoneStructure[rigType]) do
                local partA = char:FindFirstChild(bonePair[1])
                local partB = char:FindFirstChild(bonePair[2])
                if partA and partB then
                    local posA, visA = Camera:WorldToViewportPoint(partA.Position)
                    local posB, visB = Camera:WorldToViewportPoint(partB.Position)
                    if visA and visB then
                        local line = visual.Bones[index]
                        if line then
                            line.Visible = true
                            line.From = Vector2.new(posA.X, posA.Y)
                            line.To = Vector2.new(posB.X, posB.Y)
                            line.Color = espColor
                        end
                    end
                end
            end
        end

        -- ── ESP HEALTH BAR ───────────────────────────────────
        local hpBg = visual.HpBar.bg
        local hpFill = visual.HpBar.fill
        if TixSettings.ESPHealth and isAlive and head then
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position)
            local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            if headVis and rootPart then
                local rootPos, _ = Camera:WorldToViewportPoint(rootPart.Position)
                local barHeight = math.abs(headPos.Y - rootPos.Y) * 1.4
                local barX = headPos.X - 18
                local barTopY = headPos.Y - barHeight * 0.1
                local barBotY = barTopY + barHeight

                hpBg.Visible = true
                hpBg.From = Vector2.new(barX, barTopY)
                hpBg.To = Vector2.new(barX, barBotY)

                local hpFrac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local fillBotY = barBotY
                local fillTopY = barBotY - barHeight * hpFrac
                local hpColor = Color3.fromRGB(
                    math.round(255 * (1 - hpFrac)),
                    math.round(255 * hpFrac),
                    0
                )
                hpFill.Visible = true
                hpFill.From = Vector2.new(barX, fillTopY)
                hpFill.To = Vector2.new(barX, fillBotY)
                hpFill.Color = hpColor
            end
        else
            hpBg.Visible = false; hpFill.Visible = false
        end

        -- ── ESP NAME ─────────────────────────────────────────
        local nt = visual.NameTag
        if TixSettings.ESPName and isAlive and head then
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position)
            if headVis then
                local player = Players:GetPlayerFromCharacter(char)
                nt.Visible = true
                nt.Text = player and player.Name or "?"
                nt.Color = espColor
                nt.Position = Vector2.new(headPos.X, headPos.Y - 22)
            else
                nt.Visible = false
            end
        else
            nt.Visible = false
        end

        -- ── ESP DISTANCE ─────────────────────────────────────
        local dt = visual.DistTag
        if TixSettings.ESPDistance and isAlive and head then
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position)
            if headVis then
                local dist = math.floor((head.Position - Camera.CFrame.Position).Magnitude)
                dt.Visible = true
                dt.Text = dist .. "m"
                dt.Color = OffText
                -- Show below name if both active, else below head
                local yOffset = TixSettings.ESPName and 34 or 22
                dt.Position = Vector2.new(headPos.X, headPos.Y - yOffset + 14)
            else
                dt.Visible = false
            end
        else
            dt.Visible = false
        end
    end
end)
