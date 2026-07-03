--[[
    AccountAgeHUD.lua
    HUD que busca um usuário do Roblox por nome (parcial ou completo),
    mostra a idade da conta (dias e anos), pode ser encolhido para um
    círculo pequeno e arrastável, e tem botão de fechar que destrói o HUD.

    Como usar:
    - Cole este script em um LocalScript (ex: StarterPlayerScripts).
    - Digite parte do nome de usuário no campo de texto e aperte "Buscar".
    - Se houver mais de um resultado, o HUD mostra uma lista para escolher.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-------------------------------------------------
-- ScreenGui base
-------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AccountAgeHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-------------------------------------------------
-- Frame principal
-------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 220)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-------------------------------------------------
-- Barra de título (arrastável) + botões
-------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Corrige o canto inferior da titlebar pra não ficar arredondado
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = titleBar.BackgroundColor3
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Idade da Conta"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Botão de encolher
local collapseButton = Instance.new("TextButton")
collapseButton.Name = "CollapseButton"
collapseButton.Size = UDim2.new(0, 26, 0, 26)
collapseButton.Position = UDim2.new(1, -60, 0, 3)
collapseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
collapseButton.Text = "—"
collapseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
collapseButton.Font = Enum.Font.GothamBold
collapseButton.TextSize = 16
collapseButton.Parent = titleBar

local collapseCorner = Instance.new("UICorner")
collapseCorner.CornerRadius = UDim.new(0, 8)
collapseCorner.Parent = collapseButton

-- Botão de fechar (exclui tudo)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.Position = UDim2.new(1, -30, 0, 3)
closeButton.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-------------------------------------------------
-- Campo de busca (aceita nome parcial)
-------------------------------------------------
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -20, 0, 32)
searchBox.Position = UDim2.new(0, 10, 0, 42)
searchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderText = "Digite parte do nome..."
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local searchButton = Instance.new("TextButton")
searchButton.Name = "SearchButton"
searchButton.Size = UDim2.new(1, -20, 0, 30)
searchButton.Position = UDim2.new(0, 10, 0, 80)
searchButton.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
searchButton.Text = "Buscar"
searchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
searchButton.Font = Enum.Font.GothamBold
searchButton.TextSize = 14
searchButton.Parent = mainFrame

local searchButtonCorner = Instance.new("UICorner")
searchButtonCorner.CornerRadius = UDim.new(0, 8)
searchButtonCorner.Parent = searchButton

-------------------------------------------------
-- Área de resultados / lista de escolha
-------------------------------------------------
local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Name = "ResultsFrame"
resultsFrame.Size = UDim2.new(1, -20, 0, 100)
resultsFrame.Position = UDim2.new(0, 10, 0, 116)
resultsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
resultsFrame.BorderSizePixel = 0
resultsFrame.ScrollBarThickness = 4
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.Visible = false
resultsFrame.Parent = mainFrame

local resultsCorner = Instance.new("UICorner")
resultsCorner.CornerRadius = UDim.new(0, 8)
resultsCorner.Parent = resultsFrame

local resultsList = Instance.new("UIListLayout")
resultsList.Padding = UDim.new(0, 4)
resultsList.Parent = resultsFrame

-- Label de resultado (mostra idade da conta)
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -20, 0, 90)
infoLabel.Position = UDim2.new(0, 10, 0, 116)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = ""
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 14
infoLabel.TextWrapped = true
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Visible = false
infoLabel.Parent = mainFrame

-------------------------------------------------
-- Círculo de "encolhido"
-------------------------------------------------
local bubble = Instance.new("TextButton")
bubble.Name = "Bubble"
bubble.Size = UDim2.new(0, 50, 0, 50)
bubble.Position = mainFrame.Position
bubble.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
bubble.Text = "IDD"
bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 12
bubble.Visible = false
bubble.Active = true
bubble.Parent = screenGui

local bubbleCorner = Instance.new("UICorner")
bubbleCorner.CornerRadius = UDim.new(1, 0)
bubbleCorner.Parent = bubble

-------------------------------------------------
-- Função: arrastar qualquer frame com o mouse/touch
-------------------------------------------------
local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(mainFrame, titleBar)
makeDraggable(bubble, bubble)

-------------------------------------------------
-- Função: buscar usuários por nome parcial
-- Usa a API pública de busca de usuários do Roblox
-------------------------------------------------
local function searchUsersByPartialName(partialName)
	local url = "https://users.roblox.com/v1/users/search?keyword="
		.. HttpService:UrlEncode(partialName) .. "&limit=10"

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if not success then
		return nil, "Erro ao conectar na API do Roblox."
	end

	local success2, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not success2 or not data or not data.data then
		return nil, "Resposta inválida da API."
	end

	return data.data, nil
end

-------------------------------------------------
-- Função: pegar data de criação da conta e calcular idade
-------------------------------------------------
local function getAccountAge(userId)
	local url = "https://users.roblox.com/v1/users/" .. tostring(userId)

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if not success then
		return nil, "Erro ao buscar dados do usuário."
	end

	local success2, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)

	if not success2 or not data or not data.created then
		return nil, "Não foi possível ler a data de criação."
	end

	-- data.created vem em formato ISO 8601, ex: "2014-05-21T12:34:56.789Z"
	local year, month, day = data.created:match("(%d+)-(%d+)-(%d+)")
	if not year then
		return nil, "Formato de data inesperado."
	end

	local createdTime = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = 0, min = 0, sec = 0,
	})

	local now = os.time()
	local diffSeconds = now - createdTime
	local diffDays = math.floor(diffSeconds / 86400)
	local diffYears = diffDays / 365.25

	return {
		name = data.name,
		displayName = data.displayName,
		created = data.created,
		days = diffDays,
		years = diffYears,
	}, nil
end

-------------------------------------------------
-- Mostrar resultado final na tela
-------------------------------------------------
local function showAccountInfo(userId, username)
	infoLabel.Visible = true
	resultsFrame.Visible = false
	infoLabel.Text = "Buscando dados de @" .. username .. "..."

	local info, err = getAccountAge(userId)

	if not info then
		infoLabel.Text = "Erro: " .. tostring(err)
		return
	end

	infoLabel.Text = string.format(
		"Usuário: %s (@%s)\nConta criada em: %s\nIdade da conta: %d dias\n(~%.1f anos)",
		info.displayName, info.name, info.created:sub(1, 10), info.days, info.years
	)
end

-------------------------------------------------
-- Limpar lista de resultados
-------------------------------------------------
local function clearResults()
	for _, child in ipairs(resultsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

-------------------------------------------------
-- Botão de busca
-------------------------------------------------
searchButton.MouseButton1Click:Connect(function()
	local query = searchBox.Text
	if not query or query:gsub("%s", "") == "" then
		infoLabel.Visible = true
		resultsFrame.Visible = false
		infoLabel.Text = "Digite um nome (ou parte dele) para buscar."
		return
	end

	infoLabel.Visible = true
	resultsFrame.Visible = false
	infoLabel.Text = "Buscando usuários..."

	local users, err = searchUsersByPartialName(query)

	if not users then
		infoLabel.Text = "Erro: " .. tostring(err)
		return
	end

	if #users == 0 then
		infoLabel.Text = "Nenhum usuário encontrado com esse nome."
		return
	end

	if #users == 1 then
		-- Resultado único: já mostra a idade da conta direto
		showAccountInfo(users[1].id, users[1].name)
		return
	end

	-- Múltiplos resultados: mostra lista pra escolher
	infoLabel.Visible = false
	resultsFrame.Visible = true
	clearResults()

	for i, user in ipairs(users) do
		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option_" .. user.name
		optionButton.Size = UDim2.new(1, -8, 0, 26)
		optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
		optionButton.Text = user.displayName .. " (@" .. user.name .. ")"
		optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		optionButton.Font = Enum.Font.Gotham
		optionButton.TextSize = 13
		optionButton.LayoutOrder = i
		optionButton.Parent = resultsFrame

		local optCorner = Instance.new("UICorner")
		optCorner.CornerRadius = UDim.new(0, 6)
		optCorner.Parent = optionButton

		optionButton.MouseButton1Click:Connect(function()
			showAccountInfo(user.id, user.name)
		end)
	end

	resultsFrame.CanvasSize = UDim2.new(0, 0, 0, resultsList.AbsoluteContentSize.Y + 8)
end)

-- Também permite apertar Enter no TextBox pra buscar
searchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		searchButton.MouseButton1Click:Fire()
	end
end)

-------------------------------------------------
-- Botão de encolher (vira círculo pequeno móvel)
-------------------------------------------------
collapseButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	bubble.Position = UDim2.new(
		mainFrame.Position.X.Scale, mainFrame.Position.X.Offset,
		mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset
	)
	bubble.Visible = true
end)

bubble.MouseButton1Click:Connect(function()
	bubble.Visible = false
	mainFrame.Position = bubble.Position
	mainFrame.Visible = true
end)

-------------------------------------------------
-- Botão de fechar (destrói o HUD inteiro)
-------------------------------------------------
closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)
