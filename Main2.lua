--[[
    REDZ XITER V2 - Interface Principal
    Otimizado para dispositivos móveis
    - Cores reversas automáticas para ESP
    - Texto dinâmico mostrando cores atuais
--]]

local RedzLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/REDzHUB/RedzLib/main/RedzLib.lua"))()

-- Função para calcular cor reversa (complementar)
local function getReverseColor(color)
    return Color3.fromRGB(255 - color.R * 255, 255 - color.G * 255, 255 - color.B * 255)
end

-- Função para converter Color3 para string legível
local function colorToName(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("RGB(%d, %d, %d)", r, g, b)
end

-- Criar a janela principal
local Window = RedzLib:CreateWindow({
    Name = "REDZ XITER V2",
    Subtitle = "Mobile Optimized",
    SaveFolder = "REDZ_XITER_V2",
    ConfigFolder = "REDZ_XITER_V2"
})

-- Variáveis para armazenar as cores e labels dinâmicas
local currentColor = Color3.fromRGB(255, 0, 0) -- Cor padrão inicial
local reverseColor = getReverseColor(currentColor)
local colorLabel = nil

-- Aba Combat
local CombatTab = Window:CreateTab("⚔️ Combat", "rbxassetid://6031060927")

local CombatSection = CombatTab:CreateSection("🎯 Aimbot Settings")

-- Toggle Aimbot
CombatSection:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "aimbot_enabled",
    Callback = function(value) end
})

-- Smoothness Slider (1-100) - NO TOPO
CombatSection:CreateSlider({
    Name = "Smoothness",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "aimbot_smoothness",
    Callback = function(value) end
})

-- Wall Check
CombatSection:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Flag = "wall_check",
    Callback = function(value) end
})

-- Team Check
CombatSection:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "team_check",
    Callback = function(value) end
})

-- Hit Part Selection
local HitPartSection = CombatTab:CreateSection("🎯 Hit Part")

HitPartSection:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = "Head",
    Flag = "hit_part",
    Callback = function(value) end
})

-- Aba Visuals
local VisualsTab = Window:CreateTab("👁️ Visuals", "rbxassetid://6031060925")

-- ESP BOX Toggle - NO TOPO
local ESPSection = VisualsTab:CreateSection("📦 ESP Settings")

ESPSection:CreateToggle({
    Name = "ESP Box",
    CurrentValue = true,
    Flag = "esp_box",
    Callback = function(value) end
})

-- ESP Skeleton Toggle
ESPSection:CreateToggle({
    Name = "ESP Skeleton",
    CurrentValue = true,
    Flag = "esp_skeleton",
    Callback = function(value) end
})

-- ESP Color Picker (Sua cor escolhida)
ESPSection:CreateColorpicker({
    Name = "ESP Color",
    Color = currentColor,
    Flag = "esp_main_color",
    Callback = function(color)
        currentColor = color
        reverseColor = getReverseColor(color)
        
        -- Atualiza o texto dinâmico
        if colorLabel then
            colorLabel:SetText(string.format(
                "👁️ Visível: %s | 🧱 Parede: %s",
                colorToName(currentColor),
                colorToName(reverseColor)
            ))
        end
        
        -- Notificação rápida mostrando a cor reversa
        Window:CreateNotification({
            Title = "🔄 Cor Reversa Calculada",
            Text = string.format("Visível: %s → Parede: %s", 
                colorToName(currentColor), 
                colorToName(reverseColor)),
            Duration = 2,
        })
    end
})

-- Label dinâmica que mostra as cores atuais
colorLabel = ESPSection:CreateLabel({
    Text = string.format(
        "👁️ Visível: %s | 🧱 Parede: %s",
        colorToName(currentColor),
        colorToName(reverseColor)
    )
})

-- FOV Section
local FOVSection = VisualsTab:CreateSection("🔘 FOV Settings")

-- FOV Toggle - NO TOPO
FOVSection:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Flag = "fov_visible",
    Callback = function(value) end
})

-- FOV Radius Slider (1-600) - NO TOPO
FOVSection:CreateSlider({
    Name = "FOV Radius",
    Range = {1, 600},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "fov_radius",
    Callback = function(value) end
})

-- FOV Color Picker
FOVSection:CreateColorpicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "fov_color",
    Callback = function(color) end
})

-- Performance Settings
local InfoSection = VisualsTab:CreateSection("ℹ️ Performance")

InfoSection:CreateToggle({
    Name = "Show Visible Only",
    CurrentValue = true,
    Flag = "optimize_visible",
    Callback = function(value) end
})

-- Nota de rodapé
Window:CreateNotification({
    Title = "REDZ XITER V2",
    Text = "Cores reversas automáticas ativadas!",
    Duration = 3,
    Image = "rbxassetid://6031060927"
})

--[[
    FUNÇÕES ATUALIZADAS COM CORES REVERSAS AUTOMÁTICAS:
]]
local function drawBoxESP(character, isBoxActive, mainColor, isVisibleOnScreen)
    if not visualCache[character] then visualCache[character] = {} end
    local cache = visualCache[character]
    
    if not cache.Box then
        local b = Drawing.new("Square")
        b.Thickness = 1.5; b.Filled = false; b.Transparency = 1
        cache.Box = b
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if isBoxActive and hrp then
        local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        
        if onScreen then
            -- COR REVERSA AUTOMÁTICA:
            -- Visível = mainColor (cor escolhida)
            -- Atrás da parede = getReverseColor(mainColor) (cor complementar)
            local boxColor = isVisibleOnScreen and mainColor or getReverseColor(mainColor)
            
            local scaleFactor = 1 / (hrpPos.Z * math.tan(math.rad(Camera.FieldOfView / 2))) * 1000
            local width = 4 * scaleFactor
            local height = 5.5 * scaleFactor
            
            cache.Box.Visible = true
            cache.Box.Size = Vector2.new(width, height)
            cache.Box.Position = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)
            cache.Box.Color = boxColor
        else 
            cache.Box.Visible = false 
        end
    else
        if cache.Box then cache.Box.Visible = false end
    end
end

local function drawSkeletonESP(character, isSkeletonActive, mainColor, boneStructureList, isVisibleOnScreen)
    if not visualCache[character] then visualCache[character] = { Bones = {} } end
    local cache = visualCache[character]
    
    if #cache.Bones == 0 then
        for i = 1, #boneStructureList do
            local line = Drawing.new("Line")
            line.Thickness = 1.5; line.Transparency = 1
            table.insert(cache.Bones, line)
        end
    end
    
    local hum = character:FindFirstChild("Humanoid")
    if isSkeletonActive and hum and hum.Health > 0 then
        -- COR REVERSA AUTOMÁTICA:
        -- Visível = mainColor, Atrás da parede = getReverseColor(mainColor)
        local skeletonColor = isVisibleOnScreen and mainColor or getReverseColor(mainColor)
        
        for index, bonePair in ipairs(boneStructureList) do
            local partA = character:FindFirstChild(bonePair[1])
            local partB = character:FindFirstChild(bonePair[2])
            
            if partA and partB then
                local posA, visA = Camera:WorldToViewportPoint(partA.Position)
                local posB, visB = Camera:WorldToViewportPoint(partB.Position)
                local line = cache.Bones[index]
                
                if line and visA and visB then
                    line.Visible = true
                    line.From = Vector2.new(posA.X, posA.Y)
                    line.To = Vector2.new(posB.X, posB.Y)
                    line.Color = skeletonColor
                elseif line then 
                    line.Visible = false 
                end
            end
        end
    else
        if cache.Bones then 
            for _, line in pairs(cache.Bones) do 
                line.Visible = false 
            end 
        end
    end
end

--[[
    EXEMPLO DE INTEGRAÇÃO NO LOOP PRINCIPAL:
    
    local Flags = RedzLib.Flags
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild("HumanoidRootPart")
            local isVisible = checkWallVisibility(targetPart, Flags.wall_check)
            local mainColor = Flags.esp_main_color -- Sua cor escolhida
            
            if Flags.esp_box then
                drawBoxESP(player.Character, true, mainColor, isVisible)
            end
            
            if Flags.esp_skeleton then
                drawSkeletonESP(player.Character, true, mainColor, boneStructureList, isVisible)
            end
        end
    end
]]
