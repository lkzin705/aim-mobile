-- =====================================
-- SERVIÇO. Melhorar: Configs padrão
-- =====================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =====================================
-- CONFIGURAÇÕES
-- =====================================

local AIM_PART = "Head"
local WORLD_WEIGHT = 0.002
local DRAG_DISTANCE = 30 -- para mobile touch
local BUTTON_SCALE = 1.3 -- aumenta botão para toque
local PANEL_WIDTH = 260

local AimEnabled = false
local AimAlwaysOn = false
local HoldAim = false
local AimTime = 0.01

local ButtonFormat = "RECT"
local ESPEnabled = false
local ESP_COLOR = Color3.fromRGB(255,0,0)
local ESP_IGNORE_COLOR = Color3.fromRGB(150,200,255)
local ESPObjects = {}

local AimMode = "CENTER" -- CENTRO ou NEAR (PLAYER PRÓXIMO)

local IgnoredPlayers = {} -- Lista de players ignorados

-- =====================================
-- GUI BASE
-- =====================================

local gui = Instance.new("ScreenGui")
gui.Name = "AimAssist_Mobile"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = Player:WaitForChild("PlayerGui")

-- =====================================
-- FUNÇÃO DRAG (TOUCH FRIENDLY)
-- =====================================

local function makeDraggable(button)
	local dragging = false
	local moved = false
	local startPos, dragStart

	button.Active = true

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			startPos = button.Position
			dragStart = input.Position
		end
	end)

	button.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > DRAG_DISTANCE then
				moved = true
			end
			button.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
		end
	end)

	button.InputEnded:Connect(function()
		dragging = false
	end)

	return function() return moved end
end

-- =====================================
-- BOTÃO AIM
-- =====================================

local AimButton = Instance.new("TextButton", gui)
AimButton.Size = UDim2.fromOffset(130*BUTTON_SCALE,42*BUTTON_SCALE)
AimButton.Position = UDim2.new(1,-180,0.45,0)
AimButton.Text = "AIM: OFF"
AimButton.Font = Enum.Font.GothamBold
AimButton.TextSize = 20
AimButton.TextColor3 = Color3.new(1,1,1)
AimButton.BackgroundColor3 = Color3.fromRGB(180,60,60)
AimButton.BorderSizePixel = 0
AimButton.ZIndex = 20
AimButton.AutoButtonColor = false

local AimCorner = Instance.new("UICorner", AimButton)
AimCorner.CornerRadius = UDim.new(0,16)
local AimDragged = makeDraggable(AimButton)

-- =====================================
-- BOTÃO CONFIG
-- =====================================

local ConfigButton = Instance.new("TextButton", gui)
ConfigButton.Size = UDim2.fromOffset(130*BUTTON_SCALE,42*BUTTON_SCALE)
ConfigButton.Position = UDim2.new(1,-180,0.45,80)
ConfigButton.Text = "⚙ CONFIG"
ConfigButton.Font = Enum.Font.Gotham
ConfigButton.TextSize = 18
ConfigButton.TextColor3 = Color3.new(1,1,1)
ConfigButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
ConfigButton.BorderSizePixel = 0
ConfigButton.AutoButtonColor = false
ConfigButton.ZIndex = 20

Instance.new("UICorner", ConfigButton).CornerRadius = UDim.new(0,12)
local ConfigDragged = makeDraggable(ConfigButton)

-- =====================================
-- PAINEL CONFIG (SCROLLABLE)
-- =====================================

local Panel = Instance.new("Frame", gui)
Panel.Size = UDim2.fromOffset(PANEL_WIDTH,400)
Panel.Position = UDim2.new(0.5,-PANEL_WIDTH/2,0.5,-200)
Panel.BackgroundColor3 = Color3.fromRGB(24,24,24)
Panel.BorderSizePixel = 0
Panel.Visible = false
Panel.ZIndex = 30
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0,12)

local Scroll = Instance.new("ScrollingFrame", Panel)
Scroll.Size = UDim2.new(1,0,1,0)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.ScrollBarThickness = 8
Scroll.ZIndex = 31

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0,8)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder

local Padding = Instance.new("UIPadding", Scroll)
Padding.PaddingTop = UDim.new(0,12)
Padding.PaddingBottom = UDim.new(0,12)

local function createButton(text,color)
	local b = Instance.new("TextButton", Scroll)
	b.Size = UDim2.new(1,-24,0,42)
	b.Text = text
	b.Font = Enum.Font.Gotham
	b.TextSize = 18
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = color or Color3.fromRGB(50,50,50)
	b.BorderSizePixel = 0
	b.ZIndex = 32
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
	return b
end

local FormatBtn = createButton("FORMATO: RETÂNGULO")
local HoldBtn   = createButton("SEGURAR AIM: OFF")
local AlwaysBtn = createButton("AIM SEMPRE ON: OFF")
local ESPBtn    = createButton("ESP: OFF")
local ModeBtn   = createButton("MODO: CENTRO DA TELA") -- Botão de modo de mira
local IgnoreBtn = createButton("IGNORAR PLAYER") -- Botão para adicionar/remover ignorados

local TimeBox = Instance.new("TextBox", Scroll)
TimeBox.Size = UDim2.new(1,-24,0,42)
TimeBox.PlaceholderText = "Tempo do AIM (segundos)"
TimeBox.Text = tostring(AimTime)
TimeBox.Font = Enum.Font.Gotham
TimeBox.TextSize = 18
TimeBox.TextColor3 = Color3.new(1,1,1)
TimeBox.BackgroundColor3 = Color3.fromRGB(42,42,42)
TimeBox.BorderSizePixel = 0
TimeBox.ZIndex = 32
Instance.new("UICorner", TimeBox).CornerRadius = UDim.new(0,12)

local ExitBtn = createButton("SAIR DO SCRIPT", Color3.fromRGB(140,45,45))

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y + 12)
end)

-- =====================================
-- FUNÇÕES VISUAIS
-- =====================================

local function updateAimVisual()
	AimButton.Text = AimEnabled and "AIM: ON" or "AIM: OFF"
	AimButton.BackgroundColor3 = AimEnabled
		and Color3.fromRGB(60,180,90)
		or Color3.fromRGB(180,60,60)
end

local function applyFormat()
	if ButtonFormat == "RECT" then
		AimButton.Size = UDim2.fromOffset(130*BUTTON_SCALE,42*BUTTON_SCALE)
		AimCorner.CornerRadius = UDim.new(0,16)
		FormatBtn.Text = "FORMATO: RETÂNGULO"
	else
		AimButton.Size = UDim2.fromOffset(95*BUTTON_SCALE,95*BUTTON_SCALE)
		AimCorner.CornerRadius = UDim.new(1,0)
		FormatBtn.Text = "FORMATO: BOLA"
	end
end

-- =====================================
-- ESP AURA MOBILE COM PLAYER IGNORADO
-- =====================================

local function clearESP()
	for _,h in pairs(ESPObjects) do
		if h then h:Destroy() end
	end
	ESPObjects = {}
end

local function addAuraToCharacter(char, isIgnored)
	if not char or not ESPEnabled then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local h = Instance.new("Highlight")
	h.FillColor = isIgnored and ESP_IGNORE_COLOR or ESP_COLOR
	h.OutlineColor = isIgnored and ESP_IGNORE_COLOR or ESP_COLOR
	h.FillTransparency = 0.6
	h.OutlineTransparency = 0.4
	h.Parent = char
	table.insert(ESPObjects, h)
end

local function updateESP()
	clearESP()
	if not ESPEnabled then return end

	for _,p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character then
			local ignored = table.find(IgnoredPlayers, p.Name) ~= nil
			addAuraToCharacter(p.Character, ignored)
			p.CharacterAdded:Connect(function(char)
				local ignored2 = table.find(IgnoredPlayers, p.Name) ~= nil
				addAuraToCharacter(char, ignored2)
			end)
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	if ESPEnabled then
		p.CharacterAdded:Connect(function(char)
			local ignored = table.find(IgnoredPlayers, p.Name) ~= nil
			addAuraToCharacter(char, ignored)
		end)
	end
end)

-- =====================================
-- AIM SNAP (COM MODO CENTRO / PRÓXIMO E IGNORADOS)
-- =====================================

local function getTarget()
	local char = Player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local best, bestScore = nil, math.huge
	local center = Camera.ViewportSize / 2

	for _,p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and (table.find(IgnoredPlayers,p.Name) == nil) then
			local hum = p.Character:FindFirstChild("Humanoid")
			local head = p.Character:FindFirstChild(AIM_PART)
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and head and hrp then
				local score
				if AimMode == "CENTER" then
					local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
					if onScreen then
						score = (Vector2.new(pos.X,pos.Y)-center).Magnitude +
							(hrp.Position-root.Position).Magnitude * WORLD_WEIGHT
					else
						score = math.huge
					end
				else -- PLAYER PRÓXIMO
					score = (hrp.Position - root.Position).Magnitude
				end

				if score < bestScore then
					bestScore = score
					best = head
				end
			end
		end
	end
	return best
end

RunService.RenderStepped:Connect(function()
	if AimEnabled then
		local target = getTarget()
		if target then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
		end
	end
end)

-- =====================================
-- INPUT BOTÕES MOBILE
-- =====================================

AimButton.MouseButton1Down:Connect(function()
	if AimDragged() then return end
	if HoldAim then
		AimEnabled = true
		updateAimVisual()
	end
end)

AimButton.MouseButton1Up:Connect(function()
	if HoldAim then
		AimEnabled = false
		updateAimVisual()
	end
end)

AimButton.MouseButton1Click:Connect(function()
	if AimDragged() or HoldAim then return end
	if AimAlwaysOn then
		AimEnabled = not AimEnabled
	else
		AimEnabled = true
		task.delay(AimTime, function()
			if not HoldAim and not AimAlwaysOn then
				AimEnabled = false
				updateAimVisual()
			end
		end)
	end
	updateAimVisual()
end)

ConfigButton.MouseButton1Click:Connect(function()
	if ConfigDragged() then return end
	Panel.Visible = not Panel.Visible
end)

-- Formato
FormatBtn.MouseButton1Click:Connect(function()
	ButtonFormat = (ButtonFormat=="RECT") and "CIRCLE" or "RECT"
	applyFormat()
end)

-- SEGURAR AIM
HoldBtn.MouseButton1Click:Connect(function()
	HoldAim = not HoldAim
	if HoldAim then
		AimAlwaysOn = false
		AlwaysBtn.Text = "AIM SEMPRE ON: OFF"
		AlwaysBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
		HoldBtn.BackgroundColor3 = Color3.fromRGB(60,180,90)
	else
		HoldBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	end
	HoldBtn.Text = "SEGURAR AIM: "..(HoldAim and "ON" or "OFF")
end)

-- AIM SEMPRE ON
AlwaysBtn.MouseButton1Click:Connect(function()
	AimAlwaysOn = not AimAlwaysOn
	if AimAlwaysOn then
		HoldAim = false
		HoldBtn.Text = "SEGURAR AIM: OFF"
		HoldBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
		AlwaysBtn.BackgroundColor3 = Color3.fromRGB(60,180,90)
	else
		AlwaysBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	end
	AlwaysBtn.Text = "AIM SEMPRE ON: "..(AimAlwaysOn and "ON" or "OFF")
end)

-- ESP
ESPBtn.MouseButton1Click:Connect(function()
	ESPEnabled = not ESPEnabled
	ESPBtn.Text = "ESP: "..(ESPEnabled and "ON" or "OFF")
	updateESP()
end)

-- MODO AIM
ModeBtn.MouseButton1Click:Connect(function()
	AimMode = (AimMode=="CENTER") and "NEAR" or "CENTER"
	ModeBtn.Text = "MODO: "..(AimMode=="CENTER" and "CENTRO DA TELA" or "PLAYER PRÓXIMO")
end)

-- IGNORAR PLAYER
IgnoreBtn.MouseButton1Click:Connect(function()
	-- Simples input: ignora ou remove do ignore
	local plrName = Players.LocalPlayer.Name -- aqui você pode adaptar para UI input real
	local targetName = Player:GetMouse().Target and Player:GetMouse().Target.Parent.Name or ""
	if targetName ~= "" then
		if table.find(IgnoredPlayers,targetName) then
			table.remove(IgnoredPlayers, table.find(IgnoredPlayers,targetName))
		else
			table.insert(IgnoredPlayers,targetName)
		end
	end
	updateESP()
end)

-- AIM Time
TimeBox.FocusLost:Connect(function()
	local t = tonumber(TimeBox.Text)
	if t and t > 0 then
		AimTime = t
	end
end)

-- Exit
ExitBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

applyFormat()
updateAimVisual()
