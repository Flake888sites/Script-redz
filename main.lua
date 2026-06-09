local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

return function(Modulos)
    local TixSettings = Modulos.Config.Settings
    local Circle = Modulos.AimbotCircle

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

    -- Loop de Alinhamento da Mira com Humanização Corrigida
    RunService.RenderStepped:Connect(function()
        if not TixSettings.Sticky then return end
        
        local maisProximo = nil
        local menorDistanciaMouse = TixSettings.FOV
        local mousePos = game:GetService("UserInputService"):GetMouseLocation()

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(TixSettings.TargetPart) and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                
                if TixSettings.TeamCheck and p.Team == LocalPlayer.Team then continue end
                if TixSettings.FriendCheck and isFriend(p) then continue end
                
                local part = p.Character[TixSettings.TargetPart]
                local telaPos, visivel = Camera:WorldToViewportPoint(part.Position)
                
                if visivel then
                    if TixSettings.WallCheck then
                        local raio = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
                        local ig = {LocalPlayer.Character, p.Character}
                        local hit = workspace:FindPartOnRayWithIgnoreList(raio, ig)
                        if hit then continue end
                    end
                    
                    local dist2D = (Vector2.new(telaPos.X, telaPos.Y) - mousePos).Magnitude
                    if dist2D < menorDistanciaMouse then
                        menorDistanciaMouse = dist2D
                        maisProximo = part
                    end
                end
            end
        end

        if maisProximo then
            local pAlvo, _ = Camera:WorldToViewportPoint(maisProximo.Position)
            local alvo2D = Vector2.new(pAlvo.X, pAlvo.Y)
            local suavidadeFinal = TixSettings.Smoothness

            -- RESOLUÇÃO DA HUMANIZAÇÃO: 
            -- Quanto mais longe o alvo está no espaço 3D, mais trêmula/lenta a mira age simular o erro humano.
            if TixSettings.Humanized then
                local dist3D = (maisProximo.Position - Camera.CFrame.Position).Magnitude
                local fatorDistancia = math.clamp(dist3D / 50, 1, 5)
                suavidadeFinal = suavidadeFinal * fatorDistancia
            end

            -- Aplica a movimentação suave na câmera
            local diff = (alvo2D - mousePos) / suavidadeFinal
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(-diff.X * 0.1), 0) * CFrame.Angles(math.rad(-diff.Y * 0.1), 0, 0)
        end
    end)

    -- Threads do Otimizador e Limpeza Básica
    task.spawn(function()
        while task.wait(2) do
            if TixSettings.Optimizer then
                pcall(function()
                    game:GetService("Lighting").GlobalShadows = false
                    for _, v in pairs(workspace:GetDescendants()) do
                        if v:IsA("Part") or v:IsA("MeshPart") then
                            v.Material = Enum.Material.Plastic; v.Reflectance = 0
                        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
                        end
                    end
                end)
            end
        end
    end)
end

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
    Humanized = false
}

-- Cores Temáticas REDZ
local Cores = {
    Primary = Color3.fromRGB(220, 0, 0),
    DarkBg = Color3.fromRGB(12, 5, 5),
    CardBg = Color3.fromRGB(22, 10, 10),
    OffText = Color3.fromRGB(170, 150, 150)
}

return {Settings = TixSettings, Cores = Cores}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

return function(Modulos)
    local TixSettings = Modulos.Config.Settings
    local Cores = Modulos.Config.Cores

    local TixUI = Instance.new("ScreenGui")
    TixUI.Name = "REDZ_XITER_V2"
    TixUI.Parent = gethui and gethui() or game:GetService("CoreGui")
    TixUI.ResetOnSpawn = false

    local TogglePanel = Instance.new("Frame", TixUI)
    TogglePanel.Size = UDim2.new(0, 55, 0, 45)
    TogglePanel.Position = UDim2.new(0, 20, 0, 20)
    TogglePanel.BackgroundColor3 = Cores.DarkBg
    TogglePanel.Active = true
    TogglePanel.Draggable = true
    Instance.new("UICorner", TogglePanel)
    local ToggleStroke = Instance.new("UIStroke", TogglePanel)
    ToggleStroke.Thickness = 2
    ToggleStroke.Color = Cores.Primary

    local ToggleBtn = Instance.new("TextButton", TogglePanel)
    ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Text = "REDZ"
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextColor3 = Cores.Primary
    ToggleBtn.TextSize = 14

    local Main = Instance.new("Frame", TixUI)
    local VisiblePos = UDim2.new(0.5, -180, 0.5, -140)
    local HiddenPos = UDim2.new(0.5, -180, 1.2, 0)
    Main.Size = UDim2.new(0, 360, 0, 280) 
    Main.Position = HiddenPos
    Main.BackgroundColor3 = Cores.DarkBg
    Main.Visible = false
    Main.Active = true
    Main.Draggable = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Thickness = 2
    MainStroke.Color = Cores.Primary

    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Text = "REDZ XITER"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Cores.Primary

    local CloseBtn = Instance.new("TextButton", Main)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 10)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextColor3 = Cores.Primary
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

    local Scroll = Instance.new("ScrollingFrame", Main)
    Scroll.Size = UDim2.new(1, -20, 1, -70)
    Scroll.Position = UDim2.new(0, 10, 0, 60)
    Scroll.BackgroundTransparency = 1
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollBarImageColor3 = Cores.Primary

    local UIList = Instance.new("UIListLayout", Scroll)
    UIList.Padding = UDim.new(0, 6)

    local function AddToggle(text, settingKey)
        local btn = Instance.new("TextButton", Scroll)
        btn.Size = UDim2.new(1, -5, 0, 42)
        btn.BackgroundColor3 = Cores.CardBg
        btn.Text = ""; btn.AutoButtonColor = false
        Instance.new("UICorner", btn)
        local BStroke = Instance.new("UIStroke", btn)
        BStroke.Thickness = 1; BStroke.Color = Cores.Primary; BStroke.Transparency = 0.8

        local Label = Instance.new("TextLabel", btn)
        Label.Size = UDim2.new(1, -60, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1; Label.Text = text; Label.Font = Enum.Font.GothamBold
        Label.TextColor3 = Cores.Primary; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left

        local Status = Instance.new("TextLabel", btn)
        Status.Size = UDim2.new(0, 40, 1, 0); Status.Position = UDim2.new(1, -55, 0, 0)
        Status.BackgroundTransparency = 1; Status.Text = "OFF"; Status.Font = Enum.Font.GothamBold
        Status.TextColor3 = Cores.OffText; Status.TextSize = 13; Status.TextXAlignment = Enum.TextXAlignment.Right

        btn.MouseButton1Click:Connect(function()
            TixSettings[settingKey] = not TixSettings[settingKey]
            local s = TixSettings[settingKey]
            local targetColor = s and Color3.fromRGB(60, 5, 5) or Cores.CardBg
            TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
            Status.Text = s and "ON" or "OFF"
            Status.TextColor3 = s and Cores.Primary or Cores.OffText
            if settingKey == "CircleVis" and Modulos.AimbotCircle then 
                Modulos.AimbotCircle.Visible = s 
            end
        end)
    end

    local function AddSlider(text, settingKey, min, max, default)
        TixSettings[settingKey] = default
        local container = Instance.new("Frame", Scroll)
        container.Size = UDim2.new(1, -5, 0, 50); container.BackgroundColor3 = Cores.CardBg
        Instance.new("UICorner", container)
        local BStroke = Instance.new("UIStroke", container)
        BStroke.Thickness = 1; BStroke.Color = Cores.Primary; BStroke.Transparency = 0.8

        local Label = Instance.new("TextLabel", container)
        Label.Size = UDim2.new(1, -20, 0, 20); Label.Position = UDim2.new(0, 15, 0, 5)
        Label.BackgroundTransparency = 1; Label.Text = text .. ": " .. tostring(default)
        Label.Font = Enum.Font.GothamBold; Label.TextColor3 = Cores.Primary; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left

        local SliderBar = Instance.new("Frame", container)
        SliderBar.Size = UDim2.new(1, -30, 0, 6); SliderBar.Position = UDim2.new(0, 15, 0, 32)
        SliderBar.BackgroundColor3 = Color3.fromRGB(50, 5, 5); Instance.new("UICorner", SliderBar)

        local SliderBtn = Instance.new("TextButton", SliderBar)
        SliderBtn.Size = UDim2.new(0, 14, 0, 14); SliderBtn.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        SliderBtn.BackgroundColor3 = Cores.Primary; SliderBtn.Text = ""; Instance.new("UICorner", SliderBtn)

        local dragging = false
        local function update(input)
            local relativeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local value = math.round(min + (max - min) * relativeX)
            SliderBtn.Position = UDim2.new(relativeX, -7, 0.5, -7)
            TixSettings[settingKey] = value
            Label.Text = text .. ": " .. tostring(value)
            if settingKey == "FOV" and Modulos.AimbotCircle then
                Modulos.AimbotCircle.Radius = value
            end
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

    local function AddSelector(text, settingKey, options)
        local btn = Instance.new("TextButton", Scroll)
        btn.Size = UDim2.new(1, -5, 0, 42); btn.BackgroundColor3 = Cores.CardBg; btn.Text = ""; btn.AutoButtonColor = false
        Instance.new("UICorner", btn)
        local BStroke = Instance.new("UIStroke", btn)
        BStroke.Thickness = 1; BStroke.Color = Cores.Primary; BStroke.Transparency = 0.8

        local Label = Instance.new("TextLabel", btn)
        Label.Size = UDim2.new(1, -120, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1; Label.Text = text; Label.Font = Enum.Font.GothamBold
        Label.TextColor3 = Cores.Primary; Label.TextSize = 14; Label.TextXAlignment = Enum.TextXAlignment.Left

        local Status = Instance.new("TextLabel", btn)
        Status.Size = UDim2.new(0, 100, 1, 0); Status.Position = UDim2.new(1, -115, 0, 0)
        Status.BackgroundTransparency = 1; Status.Text = tostring(TixSettings[settingKey]):upper()
        Status.Font = Enum.Font.GothamBold; Status.TextColor3 = Cores.Primary; Status.TextSize = 13; Status.TextXAlignment = Enum.TextXAlignment.Right

        local currentIndex = 1
        for i, v in ipairs(options) do if v == TixSettings[settingKey] then currentIndex = i break end end

        btn.MouseButton1Click:Connect(function()
            currentIndex = currentIndex + 1
            if currentIndex > #options then currentIndex = 1 end
            TixSettings[settingKey] = options[currentIndex]
            Status.Text = tostring(options[currentIndex]):upper()
            btn.BackgroundColor3 = Color3.fromRGB(40, 10, 10); task.wait(0.1); btn.BackgroundColor3 = Cores.CardBg
        end)
    end

    -- Criação dos Elementos Visuais na Ordem Correta
    AddToggle("Sticky Aim", "Sticky")
    AddToggle("Simulacao Humana", "Humanized")
    AddToggle("Wall Check", "WallCheck")
    AddToggle("Team Check", "TeamCheck")
    AddToggle("Friend Check", "FriendCheck")
    AddToggle("Visual ESP + Skeleton", "ESP")
    AddToggle("Auto 360 On Jump", "Auto360")
    AddToggle("Trigger Bot", "Triggerbot")
    AddToggle("FPS Otimizador", "Optimizer")
    AddToggle("Show FOV", "CircleVis")

    AddSelector("Puxar Em (Target)", "TargetPart", {"Head", "Torso", "HumanoidRootPart"})
    AddSlider("Tamanho do FOV", "FOV", 10, 600, 150)
    AddSlider("Suavidade (Smoothness)", "Smoothness", 1, 50, 1)
    AddSlider("Velocidade do 360", "SpinSpeed", 5, 30, 15)
end
