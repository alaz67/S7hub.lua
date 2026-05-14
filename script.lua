local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer

--------------------------------------------------------------
-- CONFIG (5 pages, Home in the middle)
--------------------------------------------------------------
local PAGES = {
	{id = "Admin Panel", icon = "rbxassetid://128675791008004"},
	{id = "Booster",     icon = "rbxassetid://97968612312448"},
	{id = "Home",        icon = "rbxassetid://7733960981"},
	{id = "TP",          icon = ""},
	{id = "Settings",    icon = "rbxassetid://6031280882"},
}

local BTN_SIZE_NORMAL = UDim2.new(0, 36, 0, 36)
local BTN_SIZE_ACTIVE = UDim2.new(0, 46, 0, 46)
local ICON_SIZE_NORMAL = UDim2.new(0, 16, 0, 16)
local ICON_SIZE_ACTIVE = UDim2.new(0, 20, 0, 20)
local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local SESSION_START = tick()

--------------------------------------------------------------
-- PERSISTENCE SYSTEM
--------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local DASHBOARD_SAVE_FILE = "DashboardGui_SaveData.json"
local SaveData = {}
local ToggleRegistry = {}       -- name -> function(bool) to set toggle
local GuiPositionRegistry = {}  -- key -> frame reference
local TOGGLE_NO_SAVE = {["Rejoin"] = true}  -- toggles that should never auto-restore

local function loadSaveData()
	local ok, content = pcall(function() return readfile(DASHBOARD_SAVE_FILE) end)
	if not ok or not content then return {} end
	local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
	if not ok2 or type(data) ~= "table" then return {} end
	return data
end

local function writeSaveData()
	-- Capture all GUI positions before writing
	for key, frame in pairs(GuiPositionRegistry) do
		if frame and frame.Parent then
			local pos = frame.Position
			SaveData.guiPositions[key] = {xs = pos.X.Scale, xo = pos.X.Offset, ys = pos.Y.Scale, yo = pos.Y.Offset}
		end
	end
	pcall(function() writefile(DASHBOARD_SAVE_FILE, HttpService:JSONEncode(SaveData)) end)
end

local function restoreGuiPosition(key, frame)
	local saved = SaveData.guiPositions and SaveData.guiPositions[key]
	if saved then
		frame.Position = UDim2.new(saved.xs or 0, saved.xo or 0, saved.ys or 0, saved.yo or 0)
	end
	GuiPositionRegistry[key] = frame
end

local function unregisterGuiPosition(key)
	GuiPositionRegistry[key] = nil
end

SaveData = loadSaveData()
if not SaveData.toggles then SaveData.toggles = {} end
if not SaveData.keybinds then SaveData.keybinds = {} end
if not SaveData.guiPositions then SaveData.guiPositions = {} end
if not SaveData.selections then SaveData.selections = {} end

--------------------------------------------------------------
-- HELPER
--------------------------------------------------------------
local function create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function addAnimatedStroke(parent, thickness)
	local stroke = Instance.new("UIStroke", parent)
	stroke.Thickness = thickness or 1.5
	stroke.Color = Color3.fromRGB(255, 255, 255)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
	})
	gradient.Parent = stroke
	local offset = math.random(0, 360)
	task.spawn(function()
		while stroke and stroke.Parent do
			for i = 0, 360, 2 do
				gradient.Rotation = (i + offset) % 360
				task.wait(0.01)
			end
		end
	end)
	return stroke, gradient
end


--------------------------------------------------------------
-- SCREEN GUI
--------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DashboardGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

--------------------------------------------------------------
-- MAIN FRAME
--------------------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 400, 0, 250)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
addAnimatedStroke(mainFrame, 2)
restoreGuiPosition("MainDashboard", mainFrame)

--------------------------------------------------------------
-- FLOATING PARTICLES
--------------------------------------------------------------
for i = 1, 40 do
	local ball = Instance.new("Frame")
	ball.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
	ball.Position = UDim2.new(math.random(2, 98) / 100, 0, math.random(2, 98) / 100, 0)
	ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ball.BackgroundTransparency = math.random(20, 50) / 100
	ball.BorderSizePixel = 0
	ball.ZIndex = 0
	ball.Parent = mainFrame
	Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
	task.spawn(function()
		local startX = ball.Position.X.Scale
		local startY = ball.Position.Y.Scale
		local phase = math.random() * math.pi * 2
		local speedMult = 1.2 + math.random() * 1.6
		while ball and ball.Parent do
			local t = tick() + phase
			local newX = startX + math.sin(t * speedMult) * 0.06
			local newY = startY + math.cos(t * speedMult * 0.8) * 0.045
			ball.Position = UDim2.new(math.clamp(newX, 0.01, 0.99), 0, math.clamp(newY, 0.01, 0.99), 0)
			ball.BackgroundTransparency = 0.2 + math.sin(t * 3 + phase) * 0.2
			task.wait(0.02)
		end
	end)
end

--------------------------------------------------------------
-- DRAGGING
--------------------------------------------------------------
do
	local dragging, dragStart, startPos
	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

--------------------------------------------------------------
-- TOP BAR
--------------------------------------------------------------
local topBar = create("Frame", {
	Name = "TopBar", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1, ZIndex = 10, Parent = mainFrame,
})

do
	local avatarFrame = create("Frame", {
		Name = "AvatarFrame", Position = UDim2.new(0, 16, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 22, 0, 22), BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0, ZIndex = 11, Parent = topBar,
	}, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	avatarImage.ZIndex = 12
	avatarImage.Parent = avatarFrame
	Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(0, 4)

	create("TextLabel", {
		Name = "Greeting", Position = UDim2.new(0, 44, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 180, 0, 16), BackgroundTransparency = 1,
		Text = "Hello " .. player.DisplayName, TextColor3 = Color3.fromRGB(210, 210, 205),
		TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11, Parent = topBar,
	})
end

local clockLabel = create("TextLabel", {
	Name = "Clock", Position = UDim2.new(1, -56, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
	Size = UDim2.new(0, 56, 0, 16), BackgroundTransparency = 1, Text = "12:24:00",
	TextColor3 = Color3.fromRGB(150, 150, 145), TextSize = 11, Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 11, Parent = topBar,
})

--------------------------------------------------------------
-- CLOSE BUTTON
--------------------------------------------------------------
do
	local closeBtn = create("TextButton", {
		Name = "CloseButton", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.3, BorderSizePixel = 0, Text = "X",
		TextColor3 = Color3.fromRGB(100, 100, 100), TextSize = 12, Font = Enum.Font.GothamBold,
		AutoButtonColor = false, ZIndex = 15, Parent = mainFrame,
	}, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })

	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		closeBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		for i = 0, 1, 0.1 do
			mainFrame.BackgroundTransparency = 0.15 + (i * 0.85)
			for _, desc in ipairs(mainFrame:GetDescendants()) do
				if desc:IsA("TextLabel") or desc:IsA("TextButton") then desc.TextTransparency = i end
				if desc:IsA("ImageLabel") then desc.ImageTransparency = i end
				if desc:IsA("Frame") and desc.BackgroundTransparency < 1 then desc.BackgroundTransparency = math.min(desc.BackgroundTransparency + 0.12, 1) end
				if desc:IsA("UIStroke") then desc.Transparency = i end
			end
			task.wait(0.02)
		end
		screenGui:Destroy()
	end)
end

--------------------------------------------------------------
-- SEPARATOR
--------------------------------------------------------------
create("Frame", {
	Name = "Separator", Position = UDim2.new(0.05, 0, 0, 36), Size = UDim2.new(0.9, 0, 0, 1),
	BackgroundColor3 = Color3.fromRGB(40, 40, 40), BackgroundTransparency = 0.5,
	BorderSizePixel = 0, ZIndex = 10, Parent = mainFrame,
})

--------------------------------------------------------------
-- CONTENT AREA
--------------------------------------------------------------
local contentArea = create("Frame", {
	Name = "ContentArea", Position = UDim2.new(0, 12, 0, 40), Size = UDim2.new(1, -24, 1, -100),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = mainFrame,
})

local pageFrames = {}

for _, pageInfo in ipairs(PAGES) do
	if pageInfo.id ~= "Admin Panel" and pageInfo.id ~= "Home" and pageInfo.id ~= "Booster" and pageInfo.id ~= "Settings" and pageInfo.id ~= "TP" then
		local page = create("Frame", {
			Name = "Page_" .. pageInfo.id, Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1, Visible = false, Parent = contentArea,
		})
		create("ImageLabel", {
			Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.3, 0),
			Size = UDim2.new(0, 26, 0, 26), BackgroundTransparency = 1, Image = pageInfo.icon,
			ImageColor3 = Color3.fromRGB(255, 255, 255), ImageTransparency = 0.4,
			ScaleType = Enum.ScaleType.Fit, Parent = page,
		})
		create("TextLabel", {
			Name = "Title", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 200, 0, 18), BackgroundTransparency = 1, Text = pageInfo.id,
			TextSize = 13, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(220, 220, 220),
			Parent = page,
		})
		create("TextLabel", {
			Name = "Description", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.66, 0),
			Size = UDim2.new(0, 260, 0, 14), BackgroundTransparency = 1,
			Text = "This is the " .. pageInfo.id .. " page.", TextSize = 11, Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(90, 90, 90), Parent = page,
		})
		pageFrames[pageInfo.id] = page
	end
end

--------------------------------------------------------------
-- HOME PAGE (Widget Dashboard)
--------------------------------------------------------------
local homePage = create("Frame", {
	Name = "Page_Home", Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1, Visible = true, Parent = contentArea,
})
pageFrames["Home"] = homePage

local sessionTimeLabel, sessionBarFill, fpsValueLabel, fpsBars, serverPlayersLabel
local chartBars, chartValueLabels
local FPS_BAR_COUNT = 16

do
	local function createWidget(props)
		local card = create("Frame", {
			Name = props.name or "Widget", Position = props.position, Size = props.size,
			BackgroundColor3 = Color3.fromRGB(10, 10, 10), BackgroundTransparency = 0.25,
			BorderSizePixel = 0, Parent = homePage,
		}, {
			create("UICorner", {CornerRadius = UDim.new(0, 6)}),
			create("UIStroke", {Color = Color3.fromRGB(35, 35, 35), Thickness = 1}),
		})
		return card
	end

	-- Session Timer
	local sessionWidget = createWidget({name = "SessionTimer", position = UDim2.new(0, 0, 0, 0), size = UDim2.new(0.48, 0, 0, 44)})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 12), BackgroundTransparency = 1, Text = "SESSION TIME", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(100, 100, 100), TextXAlignment = Enum.TextXAlignment.Left, Parent = sessionWidget})
	sessionTimeLabel = create("TextLabel", {Name = "Value", Position = UDim2.new(0, 8, 0, 16), Size = UDim2.new(1, -16, 0, 14), BackgroundTransparency = 1, Text = "00:00:00", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = sessionWidget})
	local sessionBarBg = create("Frame", {Name = "BarBg", Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Parent = sessionWidget}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
	sessionBarFill = create("Frame", {Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = sessionBarBg}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})

	-- FPS Counter
	local fpsWidget = createWidget({name = "FPSCounter", position = UDim2.new(0.52, 0, 0, 0), size = UDim2.new(0.48, 0, 0, 44)})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 12), BackgroundTransparency = 1, Text = "FPS", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(100, 100, 100), TextXAlignment = Enum.TextXAlignment.Left, Parent = fpsWidget})
	fpsValueLabel = create("TextLabel", {Name = "Value", Position = UDim2.new(0, 8, 0, 16), Size = UDim2.new(0, 40, 0, 14), BackgroundTransparency = 1, Text = "60", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = fpsWidget})
	local fpsBarContainer = create("Frame", {Name = "FPSBars", Position = UDim2.new(0, 50, 0, 14), Size = UDim2.new(1, -60, 0, 22), BackgroundTransparency = 1, ClipsDescendants = true, Parent = fpsWidget})
	fpsBars = {}
	for i = 1, FPS_BAR_COUNT do
		fpsBars[i] = create("Frame", {Name = "Bar" .. i, Position = UDim2.new((i - 1) / FPS_BAR_COUNT, 1, 1, 0), AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(1 / FPS_BAR_COUNT, -2, 0.1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = fpsBarContainer}, {create("UICorner", {CornerRadius = UDim.new(0, 1)})})
	end

	-- Server Info
	local serverWidget = createWidget({name = "ServerInfo", position = UDim2.new(0, 0, 0, 48), size = UDim2.new(0.48, 0, 0, 44)})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 12), BackgroundTransparency = 1, Text = "SERVER", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(100, 100, 100), TextXAlignment = Enum.TextXAlignment.Left, Parent = serverWidget})
	serverPlayersLabel = create("TextLabel", {Name = "Players", Position = UDim2.new(0, 8, 0, 16), Size = UDim2.new(1, -16, 0, 12), BackgroundTransparency = 1, Text = #Players:GetPlayers() .. " players", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = serverWidget})
	create("TextLabel", {Name = "ServerId", Position = UDim2.new(0, 8, 0, 30), Size = UDim2.new(1, -16, 0, 10), BackgroundTransparency = 1, Text = "ID: " .. tostring(game.JobId):sub(1, 8) .. "...", TextSize = 8, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(70, 70, 70), TextXAlignment = Enum.TextXAlignment.Left, Parent = serverWidget})

	-- Account Age
	local accountWidget = createWidget({name = "AccountAge", position = UDim2.new(0.52, 0, 0, 48), size = UDim2.new(0.48, 0, 0, 44)})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 12), BackgroundTransparency = 1, Text = "ACCOUNT AGE", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(100, 100, 100), TextXAlignment = Enum.TextXAlignment.Left, Parent = accountWidget})
	local accountDays = player.AccountAge
	local accountYears = math.floor(accountDays / 365)
	local accountRemDays = accountDays % 365
	local ageText = accountYears > 0 and (accountYears .. "y " .. accountRemDays .. "d") or (accountDays .. " days")
	create("TextLabel", {Name = "Value", Position = UDim2.new(0, 8, 0, 16), Size = UDim2.new(1, -16, 0, 14), BackgroundTransparency = 1, Text = ageText, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = accountWidget})
	local acctBarBg = create("Frame", {Name = "BarBg", Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Parent = accountWidget}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
	create("Frame", {Name = "Fill", Size = UDim2.new(math.clamp(accountDays / (365 * 10), 0, 1), 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = acctBarBg}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})

	-- Session Chart
	local chartWidget = createWidget({name = "SessionChart", position = UDim2.new(0, 0, 0, 96), size = UDim2.new(1, 0, 1, -96)})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 3), Size = UDim2.new(0.5, 0, 0, 12), BackgroundTransparency = 1, Text = "SESSION BREAKDOWN", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(100, 100, 100), TextXAlignment = Enum.TextXAlignment.Left, Parent = chartWidget})
	local chartArea = create("Frame", {Name = "ChartArea", Position = UDim2.new(0, 8, 0, 16), Size = UDim2.new(1, -16, 1, -20), BackgroundTransparency = 1, ClipsDescendants = true, Parent = chartWidget})

	local barLabels = {"HRS", "MIN", "SEC"}
	local barColors = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180), Color3.fromRGB(110, 110, 110)}
	chartBars = {}
	chartValueLabels = {}
	for i = 1, 3 do
		local barX = (i - 1) / 3
		local barBg = create("Frame", {Name = "BarBg" .. i, Position = UDim2.new(barX, 6, 0, 0), Size = UDim2.new(1/3, -12, 1, -12), BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0, Parent = chartArea}, {create("UICorner", {CornerRadius = UDim.new(0, 3)})})
		chartBars[i] = create("Frame", {Name = "Fill", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = barColors[i], BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = barBg}, {create("UICorner", {CornerRadius = UDim.new(0, 3)})})
		chartValueLabels[i] = create("TextLabel", {Name = "Val", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -2), Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, Text = "0", TextSize = 9, Font = Enum.Font.GothamBold, TextColor3 = barColors[i], Parent = chartBars[i]})
		create("TextLabel", {Name = "BarLabel", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(barX + 1/6, 0, 1, -11), Size = UDim2.new(1/3, 0, 0, 10), BackgroundTransparency = 1, Text = barLabels[i], TextSize = 7, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(70, 70, 70), Parent = chartArea})
	end
end

--------------------------------------------------------------
-- HOME PAGE UPDATE LOOP
--------------------------------------------------------------
do
	local fpsHistory = {}
	local lastFpsTime = tick()
	local frameCount = 0
	RunService.Heartbeat:Connect(function() frameCount = frameCount + 1 end)
	task.spawn(function()
		while homePage and homePage.Parent do
			local elapsed = tick() - SESSION_START
			local hrs = math.floor(elapsed / 3600)
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = math.floor(elapsed % 60)
			sessionTimeLabel.Text = string.format("%02d:%02d:%02d", hrs, mins, secs)
			local fillRatio = math.clamp(elapsed / 3600, 0, 1)
			TweenService:Create(sessionBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(fillRatio, 0, 1, 0)}):Play()
			local now = tick()
			local dt = now - lastFpsTime
			local fps = math.floor(frameCount / dt)
			frameCount = 0
			lastFpsTime = now
			fpsValueLabel.Text = tostring(fps)
			if fps >= 50 then fpsValueLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
			elseif fps >= 30 then fpsValueLabel.TextColor3 = Color3.fromRGB(255, 255, 180)
			else fpsValueLabel.TextColor3 = Color3.fromRGB(255, 160, 160) end
			table.insert(fpsHistory, fps)
			if #fpsHistory > FPS_BAR_COUNT then table.remove(fpsHistory, 1) end
			for i = 1, FPS_BAR_COUNT do
				local val = fpsHistory[i] or 0
				local ratio = math.clamp(val / 120, 0.05, 1)
				fpsBars[i].Size = UDim2.new(1 / FPS_BAR_COUNT, -2, ratio, 0)
				if val >= 50 then fpsBars[i].BackgroundColor3 = Color3.fromRGB(200, 255, 200)
				elseif val >= 30 then fpsBars[i].BackgroundColor3 = Color3.fromRGB(255, 255, 180)
				else fpsBars[i].BackgroundColor3 = Color3.fromRGB(255, 160, 160) end
				fpsBars[i].BackgroundTransparency = 0.35
			end
			serverPlayersLabel.Text = #Players:GetPlayers() .. " players"
			local maxVal = math.max(hrs, mins, secs, 1)
			local vals = {hrs, mins, secs}
			for i = 1, 3 do
				local ratio = math.clamp(vals[i] / math.max(maxVal, 1), 0, 1)
				if vals[i] == 0 then ratio = 0.04 end
				TweenService:Create(chartBars[i], TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, ratio, 0)}):Play()
				chartValueLabels[i].Text = tostring(vals[i])
			end
			task.wait(0.5)
		end
	end)
end

--------------------------------------------------------------
-- ADMIN PANEL PAGE
--------------------------------------------------------------
local adminPage = create("Frame", {Name = "Page_Admin Panel", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = contentArea})
pageFrames["Admin Panel"] = adminPage

local adminScroll = create("ScrollingFrame", {Name = "AdminScroll", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = adminPage})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = adminScroll})

local function createToggleRow(name, layoutOrder, callback)
	local row = create("Frame", {Name = "Row_" .. name, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = layoutOrder, Parent = adminScroll}, {create("UICorner", {CornerRadius = UDim.new(0, 5)})})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Text = name, TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 200, 200), TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
	local tBg = create("Frame", {Name = "ToggleBg", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 30, 0, 14), BackgroundColor3 = Color3.fromRGB(40, 40, 40), BorderSizePixel = 0, Parent = row}, {create("UICorner", {CornerRadius = UDim.new(1, 0)}), create("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1})})
	local tCircle = create("Frame", {Name = "Circle", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.fromRGB(100, 100, 100), BorderSizePixel = 0, Parent = tBg}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
	local tBtn = create("TextButton", {Name = "Btn", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = tBg})
	local enabled = false
	local function setToggle(newState)
		if newState == enabled then return end
		enabled = newState
		if enabled then
			TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			TweenService:Create(tCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		else
			TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
			TweenService:Create(tCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
		end
		if not TOGGLE_NO_SAVE[name] then SaveData.toggles[name] = enabled; writeSaveData() end
		callback(enabled)
	end
	tBtn.MouseButton1Click:Connect(function() setToggle(not enabled) end)
	ToggleRegistry[name] = setToggle
	return row
end

--------------------------------------------------------------
-- ADMIN SPAMMER (wrapped in do...end)
--------------------------------------------------------------
do
	local adminSpammerGui = nil

	local function destroyAdminSpammer()
		if CoreGui:FindFirstChild("CatHubSpammer") then CoreGui["CatHubSpammer"]:Destroy() end
		unregisterGuiPosition("AdminSpammer")
		adminSpammerGui = nil
	end

	local function createAdminSpammer()
		destroyAdminSpammer()
		local spamScreenGui = Instance.new("ScreenGui")
		spamScreenGui.Name = "CatHubSpammer"; spamScreenGui.ResetOnSpawn = false; spamScreenGui.Parent = CoreGui
		adminSpammerGui = spamScreenGui

		local spamMainFrame = Instance.new("Frame")
		spamMainFrame.Name = "MainFrame"; spamMainFrame.Size = UDim2.new(0, 220, 0, 320)
		spamMainFrame.Position = UDim2.new(1, -235, 0.5, -160); spamMainFrame.AnchorPoint = Vector2.new(0, 0.5)
		spamMainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0); spamMainFrame.BackgroundTransparency = 0.15
		spamMainFrame.BorderSizePixel = 0; spamMainFrame.Active = true; spamMainFrame.ClipsDescendants = true
		spamMainFrame.Parent = spamScreenGui
		Instance.new("UICorner", spamMainFrame).CornerRadius = UDim.new(0, 8)
		addAnimatedStroke(spamMainFrame, 2)
		restoreGuiPosition("AdminSpammer", spamMainFrame)

		local spamHeader = Instance.new("Frame"); spamHeader.Name = "Header"; spamHeader.Size = UDim2.new(1, 0, 0, 35)
		spamHeader.BackgroundColor3 = Color3.fromRGB(10, 10, 10); spamHeader.BackgroundTransparency = 0.1; spamHeader.BorderSizePixel = 0; spamHeader.Parent = spamMainFrame
		Instance.new("UICorner", spamHeader).CornerRadius = UDim.new(0, 8)

		local spamTitle = Instance.new("TextLabel"); spamTitle.Size = UDim2.new(1, -30, 1, 0); spamTitle.Position = UDim2.new(0, 10, 0, 0)
		spamTitle.BackgroundTransparency = 1; spamTitle.Text = "Admin Spammer"; spamTitle.Font = Enum.Font.GothamBold; spamTitle.TextSize = 14
		spamTitle.TextColor3 = Color3.fromRGB(255, 255, 255); spamTitle.TextXAlignment = Enum.TextXAlignment.Left; spamTitle.Parent = spamHeader

		local spamMinBtn = Instance.new("TextButton"); spamMinBtn.Size = UDim2.new(0, 24, 0, 24); spamMinBtn.Position = UDim2.new(1, -30, 0, 5.5)
		spamMinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); spamMinBtn.Text = "─"; spamMinBtn.Font = Enum.Font.GothamBold
		spamMinBtn.TextSize = 14; spamMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); spamMinBtn.Parent = spamHeader
		Instance.new("UICorner", spamMinBtn).CornerRadius = UDim.new(0, 6)

		local spamBody = Instance.new("Frame"); spamBody.Name = "Body"; spamBody.Size = UDim2.new(1, 0, 1, -35); spamBody.Position = UDim2.new(0, 0, 0, 35)
		spamBody.BackgroundColor3 = Color3.fromRGB(0, 0, 0); spamBody.BackgroundTransparency = 0.15; spamBody.BorderSizePixel = 0; spamBody.Parent = spamMainFrame
		Instance.new("UICorner", spamBody).CornerRadius = UDim.new(0, 8)

		local spamContent = Instance.new("ScrollingFrame"); spamContent.Name = "ContentFrame"; spamContent.Size = UDim2.new(1, -10, 1, -50); spamContent.Position = UDim2.new(0, 5, 0, 5)
		spamContent.BackgroundTransparency = 1; spamContent.BorderSizePixel = 0; spamContent.ScrollBarThickness = 3; spamContent.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
		spamContent.CanvasSize = UDim2.new(0, 0, 0, 0); spamContent.Parent = spamBody

		local spamLayout = Instance.new("UIListLayout"); spamLayout.SortOrder = Enum.SortOrder.LayoutOrder; spamLayout.Padding = UDim.new(0, 4); spamLayout.Parent = spamContent

		local spamNearestBtn = Instance.new("TextButton"); spamNearestBtn.Name = "SpamNearestBtn"; spamNearestBtn.Size = UDim2.new(1, -10, 0, 34)
		spamNearestBtn.Position = UDim2.new(0, 5, 1, -39); spamNearestBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); spamNearestBtn.BorderSizePixel = 0
		spamNearestBtn.AutoButtonColor = false; spamNearestBtn.Text = "Spam closest humanoid"; spamNearestBtn.Font = Enum.Font.GothamBold
		spamNearestBtn.TextSize = 12; spamNearestBtn.TextColor3 = Color3.fromRGB(200, 200, 200); spamNearestBtn.Parent = spamBody
		Instance.new("UICorner", spamNearestBtn).CornerRadius = UDim.new(0, 6)
		local spamNearStroke = Instance.new("UIStroke"); spamNearStroke.Thickness = 1; spamNearStroke.Color = Color3.fromRGB(60, 60, 60); spamNearStroke.Parent = spamNearestBtn

		local spamming = {}
		local nearestSpamBusy = false
		local spamNearestKeybind = nil
		local isSettingKeybind = false

		-- Restore saved keybind
		local _savedSpamKb = SaveData.keybinds and SaveData.keybinds["AdminSpamNearest"]
		if _savedSpamKb then pcall(function() spamNearestKeybind = Enum.KeyCode[_savedSpamKb] end) end
		if spamNearestKeybind then spamNearestBtn.Text = "SPAM NEAREST [" .. spamNearestKeybind.Name .. "]" end

		local notifFrame = Instance.new("Frame"); notifFrame.Name = "Notification"; notifFrame.Size = UDim2.new(0, 200, 0, 35)
		notifFrame.Position = UDim2.new(0.5, -100, 0, -45); notifFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10); notifFrame.BackgroundTransparency = 0.1
		notifFrame.BorderSizePixel = 0; notifFrame.Visible = false; notifFrame.Parent = spamScreenGui
		Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", notifFrame).Color = Color3.fromRGB(50, 50, 50)
		local notifTextLabel = Instance.new("TextLabel"); notifTextLabel.Size = UDim2.new(1, -10, 1, 0); notifTextLabel.Position = UDim2.new(0, 5, 0, 0)
		notifTextLabel.BackgroundTransparency = 1; notifTextLabel.Font = Enum.Font.Gotham; notifTextLabel.TextSize = 12; notifTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255); notifTextLabel.Parent = notifFrame

		local notifActive = false
		local function showNotif(msg)
			if notifActive then return end; notifActive = true; notifTextLabel.Text = msg; notifFrame.Visible = true
			notifFrame:TweenPosition(UDim2.new(0.5, -100, 0, 10), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true)
			task.wait(1.2)
			notifFrame:TweenPosition(UDim2.new(0.5, -100, 0, -45), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.4, true, function() notifFrame.Visible = false; notifActive = false end)
		end

		local function findAdminPanel() return player:WaitForChild("PlayerGui"):FindFirstChild("AdminPanel") end
		local function clickButton(button) pcall(function() for _, c in pairs(getconnections(button.MouseButton1Click)) do c:Fire() end; for _, c in pairs(getconnections(button.Activated)) do c:Fire() end end) end
		local function findPlayerButton(targetPlayer)
			local ap = findAdminPanel(); if not ap then return nil end
			for _, d in pairs(ap:GetDescendants()) do
				if d:IsA("TextButton") or d:IsA("ImageButton") then
					local t = d:IsA("TextButton") and d.Text or ""
					if t == "" and d:IsA("ImageButton") then for _, c in pairs(d:GetDescendants()) do if c:IsA("TextLabel") then t = c.Text; break end end end
					if t == targetPlayer.DisplayName or t:find(targetPlayer.DisplayName) or t == targetPlayer.Name or t:find(targetPlayer.Name) then return d end
				end
			end
			return nil
		end
		local function getCommandButtons()
			local buttons = {}; local ap = findAdminPanel(); if not ap then return buttons end
			for _, d in pairs(ap:GetDescendants()) do
				if d:IsA("TextButton") or d:IsA("ImageButton") then
					local t = d:IsA("TextButton") and d.Text or ""
					if t == "" and d:IsA("ImageButton") then for _, c in pairs(d:GetDescendants()) do if c:IsA("TextLabel") and c.Text ~= "" then t = c.Text; break end end end
					if t ~= "" and (t:match("^:") or t:match("^;")) then table.insert(buttons, {button = d, name = t}) end
				end
			end
			return buttons
		end
		local function getNearestPlayer()
			local char = player.Character; if not char then return nil end
			local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
			local nearest, nearestDist = nil, math.huge
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local o = p.Character:FindFirstChild("HumanoidRootPart")
					if o then local d = (hrp.Position - o.Position).Magnitude; if d < nearestDist then nearestDist = d; nearest = p end end
				end
			end
			return nearest
		end

		local function spamNearestOnce()
			if nearestSpamBusy then return end
			local nearest = getNearestPlayer(); if not nearest then showNotif("No players nearby"); return end
			nearestSpamBusy = true; spamNearestBtn.Text = "Spamming... (" .. nearest.DisplayName .. ")"
			spamNearestBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0); spamNearestBtn.TextColor3 = Color3.fromRGB(255, 100, 100); spamNearStroke.Color = Color3.fromRGB(120, 30, 30)
			task.spawn(function()
				local cmds = {}; for _, cd in pairs(getCommandButtons()) do if not cd.name:lower():find("control") then table.insert(cmds, cd) end end
				for _, cd in ipairs(cmds) do local pb = findPlayerButton(nearest); if pb then clickButton(pb) end; clickButton(cd.button); task.wait(0.05) end
				nearestSpamBusy = false
				spamNearestBtn.Text = spamNearestKeybind and ("SPAM NEAREST [" .. spamNearestKeybind.Name .. "]") or "Spam closest humanoid"
				spamNearestBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); spamNearestBtn.TextColor3 = Color3.fromRGB(200, 200, 200); spamNearStroke.Color = Color3.fromRGB(60, 60, 60)
				showNotif("Spam Complete")
			end)
		end

		spamNearestBtn.MouseButton1Click:Connect(function() if not isSettingKeybind then spamNearestOnce() end end)
		spamNearestBtn.MouseEnter:Connect(function() if not nearestSpamBusy then spamNearestBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); spamNearestBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end end)
		spamNearestBtn.MouseLeave:Connect(function() if not nearestSpamBusy then spamNearestBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); spamNearestBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end end)

		-- Keybind popup
		local kbPopup = Instance.new("Frame"); kbPopup.Size = UDim2.new(0, 180, 0, 70); kbPopup.Position = UDim2.new(0.5, -90, 0.5, -35)
		kbPopup.BackgroundColor3 = Color3.fromRGB(15, 15, 15); kbPopup.BackgroundTransparency = 0.05; kbPopup.BorderSizePixel = 0; kbPopup.Visible = false; kbPopup.ZIndex = 10; kbPopup.Parent = spamScreenGui
		Instance.new("UICorner", kbPopup).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", kbPopup).Color = Color3.fromRGB(80, 80, 80)
		local kbTitle = Instance.new("TextLabel"); kbTitle.Size = UDim2.new(1, 0, 0, 25); kbTitle.Position = UDim2.new(0, 0, 0, 5); kbTitle.BackgroundTransparency = 1; kbTitle.Text = "Set Keybind"; kbTitle.Font = Enum.Font.GothamBold; kbTitle.TextSize = 13; kbTitle.TextColor3 = Color3.fromRGB(255, 255, 255); kbTitle.ZIndex = 11; kbTitle.Parent = kbPopup
		local kbHint = Instance.new("TextLabel"); kbHint.Size = UDim2.new(1, 0, 0, 20); kbHint.Position = UDim2.new(0, 0, 0, 28); kbHint.BackgroundTransparency = 1; kbHint.Text = "Press any key..."; kbHint.Font = Enum.Font.Gotham; kbHint.TextSize = 11; kbHint.TextColor3 = Color3.fromRGB(160, 160, 160); kbHint.ZIndex = 11; kbHint.Parent = kbPopup
		local clearKbBtn = Instance.new("TextButton"); clearKbBtn.Size = UDim2.new(0.5, -10, 0, 18); clearKbBtn.Position = UDim2.new(0.25, 0, 1, -23); clearKbBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); clearKbBtn.Text = "Clear Bind"; clearKbBtn.Font = Enum.Font.Gotham; clearKbBtn.TextSize = 10; clearKbBtn.TextColor3 = Color3.fromRGB(180, 180, 180); clearKbBtn.ZIndex = 11; clearKbBtn.Parent = kbPopup
		Instance.new("UICorner", clearKbBtn).CornerRadius = UDim.new(0, 4)

		spamNearestBtn.MouseButton2Click:Connect(function() if nearestSpamBusy then return end; isSettingKeybind = true; kbPopup.Visible = true; kbHint.Text = spamNearestKeybind and ("Current: " .. spamNearestKeybind.Name .. " | Press new key...") or "Press any key..." end)
		UserInputService.InputBegan:Connect(function(input) if not isSettingKeybind then return end; if input.UserInputType == Enum.UserInputType.Keyboard then spamNearestKeybind = input.KeyCode; isSettingKeybind = false; kbPopup.Visible = false; spamNearestBtn.Text = "SPAM NEAREST [" .. input.KeyCode.Name .. "]"; showNotif("Bound to " .. input.KeyCode.Name); SaveData.keybinds["AdminSpamNearest"] = input.KeyCode.Name; writeSaveData() end end)
		UserInputService.InputBegan:Connect(function(input, gp) if gp or isSettingKeybind then return end; if spamNearestKeybind and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == spamNearestKeybind then spamNearestOnce() end end)
		clearKbBtn.MouseButton1Click:Connect(function() spamNearestKeybind = nil; isSettingKeybind = false; kbPopup.Visible = false; spamNearestBtn.Text = "Spam closest humanoid"; showNotif("Keybind Cleared"); SaveData.keybinds["AdminSpamNearest"] = nil; writeSaveData() end)

		-- Player cards
		local function createPlayerCard(targetPlayer)
			local card = Instance.new("TextButton"); card.Name = targetPlayer.Name; card.Size = UDim2.new(1, 0, 0, 28); card.BackgroundColor3 = Color3.fromRGB(15, 15, 15); card.BackgroundTransparency = 0.1; card.BorderSizePixel = 0; card.AutoButtonColor = false; card.Text = ""; card.Parent = spamContent
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
			local nameLabel = Instance.new("TextLabel"); nameLabel.Size = UDim2.new(1, -25, 1, 0); nameLabel.Position = UDim2.new(0, 8, 0, 0); nameLabel.BackgroundTransparency = 1; nameLabel.Text = targetPlayer.DisplayName; nameLabel.Font = Enum.Font.Gotham; nameLabel.TextSize = 13; nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220); nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = card
			local statusDot = Instance.new("Frame"); statusDot.Size = UDim2.new(0, 6, 0, 6); statusDot.Position = UDim2.new(1, -12, 0.5, -3); statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100); statusDot.BorderSizePixel = 0; statusDot.Parent = card; Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
			card.MouseEnter:Connect(function() if not spamming[targetPlayer.Name] then card.BackgroundColor3 = Color3.fromRGB(25, 25, 25); nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) end end)
			card.MouseLeave:Connect(function() if not spamming[targetPlayer.Name] then card.BackgroundColor3 = Color3.fromRGB(15, 15, 15); nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220) end end)
			card.MouseButton1Click:Connect(function()
				local pk = targetPlayer.Name
				if spamming[pk] then spamming[pk] = false; statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100); card.BackgroundColor3 = Color3.fromRGB(15, 15, 15); nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
				else
					spamming[pk] = true; statusDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); card.BackgroundColor3 = Color3.fromRGB(0, 0, 0); nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					task.spawn(function()
						local cmds = {}; for _, cd in pairs(getCommandButtons()) do if not cd.name:lower():find("control") then table.insert(cmds, cd) end end
						for _, cd in ipairs(cmds) do if not spamming[pk] then break end; local pb = findPlayerButton(targetPlayer); if pb then clickButton(pb) end; clickButton(cd.button) end
						spamming[pk] = false; statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 100); card.BackgroundColor3 = Color3.fromRGB(15, 15, 15); showNotif("Spam Complete")
					end)
				end
			end)
		end

		local function refreshPlayers()
			local existing = {}; for _, c in pairs(spamContent:GetChildren()) do if c:IsA("TextButton") then existing[c.Name] = c end end
			for _, p in pairs(Players:GetPlayers()) do if p ~= player then if not existing[p.Name] then createPlayerCard(p) end elseif existing[p.Name] then existing[p.Name]:Destroy(); spamming[p.Name] = false end end
			spamContent.CanvasSize = UDim2.new(0, 0, 0, spamLayout.AbsoluteContentSize.Y + 5)
		end
		refreshPlayers()
		task.spawn(function() while spamScreenGui and spamScreenGui.Parent do refreshPlayers(); task.wait(1) end end)
		Players.PlayerRemoving:Connect(function(p) spamming[p.Name] = false end)
		spamLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() spamContent.CanvasSize = UDim2.new(0, 0, 0, spamLayout.AbsoluteContentSize.Y + 5) end)

		-- Minimize + Drag
		local isMin = false
		spamMinBtn.MouseButton1Click:Connect(function() isMin = not isMin; spamBody.Visible = not isMin; spamMainFrame.Size = isMin and UDim2.new(0, 220, 0, 35) or UDim2.new(0, 220, 0, 320); spamMinBtn.Text = isMin and "+" or "─" end)

		local sDragging, sDragStart, sStartPos, sDragInput
		spamHeader.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sDragging = true; sDragStart = input.Position; sStartPos = spamMainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then sDragging = false end end) end end)
		spamHeader.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then sDragInput = input end end)
		UserInputService.InputChanged:Connect(function(input) if input == sDragInput and sDragging then local delta = input.Position - sDragStart; spamMainFrame.Position = UDim2.new(sStartPos.X.Scale, sStartPos.X.Offset + delta.X, sStartPos.Y.Scale, sStartPos.Y.Offset + delta.Y) end end)
	end

	createToggleRow("Admin Spammer", 1, function(enabled) if enabled then createAdminSpammer() else destroyAdminSpammer() end end)
end

--------------------------------------------------------------
-- BASE PROTECTOR (wrapped in do...end)
--------------------------------------------------------------
do
	local bpGui = nil
	local bpHeartbeat = nil
	local bpPlayerConns = {}

	local function destroyBP()
		if bpGui then bpGui:Destroy(); bpGui = nil end
		if bpHeartbeat then bpHeartbeat:Disconnect(); bpHeartbeat = nil end
		for _, c in ipairs(bpPlayerConns) do if c and c.Connected then c:Disconnect() end end
		bpPlayerConns = {}
		unregisterGuiPosition("BaseProtector")
		if _G.dumpedandremakedbysaturday then
			_G.dumpedandremakedbysaturday.Mode = "None"
			_G.dumpedandremakedbysaturday.BorderKick = false
			_G.dumpedandremakedbysaturday.TpProtector = false
		end
	end

	local function createBP()
		destroyBP()

		local rs = game:GetService("ReplicatedStorage")
		local plrs = game:GetService("Players")
		local run = game:GetService("RunService")
		local TweenService = game:GetService("TweenService")

		local lp         = plrs.LocalPlayer
		local ws         = game:GetService("Workspace")
		local repsto     = game:GetService("ReplicatedStorage")
		local stats      = game:GetService("Stats")
		local uis        = game:GetService("UserInputService")
		local plrgui     = lp:WaitForChild("PlayerGui")

		_G.dumpedandremakedbysaturday = {
			Mode                 = "None",
			BorderKick           = false,
			MyPlot               = nil,
			StealHitbox          = nil,
			CarpetSpammedPlayers = {},
			AdminRemote          = nil,
			LastPunishTime       = {},
			TpProtector          = false,
			PlayerPositions      = {},
			TpProtectorCooldowns = {},
		}

		local core = _G.dumpedandremakedbysaturday

		local function fireAdmin(...)
			if not core.AdminRemote then return end
			local a = {...}
			task.spawn(function()
				core.AdminRemote:InvokeServer(unpack(a))
			end)
		end

		local CARPET_ITEMS = {["Flying Carpet"] = true, ["Witch's Broom"] = true, ["Santa's Sleigh"] = true}

		function punishPlayer(p)
			if not core.AdminRemote then return end
			if not p or p == lp then return end
			local char = p.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local uid = p.UserId
			if core.LastPunishTime[uid] and tick() - core.LastPunishTime[uid] < 2 then return end
			core.LastPunishTime[uid] = tick()
			hrp.CFrame = CFrame.new(0, 10000, 0)

			if core.Mode == "Kick" then
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "balloon")
				task.delay(0.3, function() lp:Kick("Zero caught u UwU") end)
			elseif core.Mode == "NoKick" then
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "balloon")
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "ragdoll")
			end
		end

		local function findPlayerInHitbox()
			local hitbox = core.StealHitbox
			if not hitbox then return end
			local cf   = hitbox.CFrame
			local size = hitbox.Size
			local hx, hz = size.X * 0.5, size.Z * 0.5
			for _, p in ipairs(plrs:GetPlayers()) do
				if p ~= lp then
					local char = p.Character
					if char then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							local rel = cf:PointToObjectSpace(hrp.Position)
							if math.abs(rel.X) <= hx and math.abs(rel.Z) <= hz then
								for _, item in ipairs(char:GetChildren()) do
									if CARPET_ITEMS[item.Name] then
										punishPlayer(p)
										break
									end
								end
							end
						end
					end
				end
			end
		end

		task.spawn(function()
			if not lp.Character then lp.CharacterAdded:Wait() end
			task.wait(1)

			local net      = repsto:WaitForChild("Packages"):WaitForChild("Net")
			local children = net:GetChildren()
			local byIdx    = {}
			local byName   = {}
			for i, obj in ipairs(children) do
				byIdx[i]          = obj
				byName[obj.Name]  = i
			end

			local anchorIdx = byName["RF/a0e78691-cb9b-4efc-ac08-9c06fea70059"]
			if anchorIdx then
				local actual = byIdx[anchorIdx + 1]
				if actual then
					core.AdminRemote = actual
				end
			end

			for _, obj in ipairs(repsto:GetDescendants()) do
				if obj:IsA("RemoteEvent") then
					obj.OnClientEvent:Connect(function(...)
						if core.Mode == "None" or not core.AdminRemote or not core.MyPlot then return end
						for _, a in ipairs({...}) do
							if type(a) == "string" and a:lower():find("stealing") then
								local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
								if not myHRP then return end
								local best, bestDist = nil, math.huge
								for _, p in ipairs(plrs:GetPlayers()) do
									if p ~= lp then
										local char = p.Character
										if char then
											local hrp = char:FindFirstChild("HumanoidRootPart")
											if hrp then
												local dist = (hrp.Position - myHRP.Position).Magnitude
												if dist < bestDist then bestDist = dist best = p end
											end
										end
									end
								end
								if best then punishPlayer(best) end
								return
							end
						end
					end)
				end
			end
		end)

		task.spawn(function()
			if hookfunction and fireproximityprompt then
				local old = fireproximityprompt
				hookfunction(fireproximityprompt, newcclosure(function(prompt, ...)
					if core.Mode ~= "None" then
						local at = (prompt.ActionText or ""):lower()
						local ot = (prompt.ObjectText  or ""):lower()
						if at:find("steal") or ot:find("steal") then
							local part = prompt.Parent
							if part and part:IsA("BasePart") then
								local pos = part.Position
								local best, bestD = nil, math.huge
								for _, p in ipairs(plrs:GetPlayers()) do
									if p ~= lp then
										local char = p.Character
										if char then
											local hrp = char:FindFirstChild("HumanoidRootPart")
											if hrp then
												local d = (hrp.Position - pos).Magnitude
												if d < bestD then bestD = d best = p end
											end
										end
									end
								end
								if best and bestD < 20 then punishPlayer(best) end
							end
							findPlayerInHitbox()
						end
					end
					return old(prompt, ...)
				end))
			end
			if hookfunction and newcclosure then
				local oldFS = Instance.FireServer
				hookfunction(Instance.FireServer, newcclosure(function(self, ...)
					if core.Mode ~= "None" and core.StealHitbox then
						findPlayerInHitbox()
					end
					return oldFS(self, ...)
				end))
			end
		end)

		local pingLbl = nil

		task.spawn(function()
			while bpGui and bpGui.Parent and task.wait(0.5) do
				local plots = ws:FindFirstChild("Plots")
				if plots and not core.MyPlot then
					for _, p in ipairs(plots:GetChildren()) do
						local sign = p:FindFirstChild("PlotSign")
						if sign then
							local lbl = sign:FindFirstChild("TextLabel", true)
							if lbl then
								local t = lbl.Text:lower()
								if t:find(lp.Name:lower()) or t:find(lp.DisplayName:lower()) then
									core.MyPlot      = p
									core.StealHitbox = p:FindFirstChild("StealHitbox", true)
									break
								end
							end
						end
					end
				end

				if pingLbl then
					local ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
					local safe = ping <= 150
					pingLbl.Text       = "PING: " .. (safe and "SAFE" or "HIGH") .. " (" .. ping .. " ms)"
					pingLbl.TextColor3 = safe and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(180, 180, 180)
				end
			end
		end)

		bpHeartbeat = run.Heartbeat:Connect(function()
			if core.BorderKick and core.StealHitbox and core.AdminRemote then
				local cf, size = core.StealHitbox.CFrame, core.StealHitbox.Size
				local hx, hz = size.X * 0.5, size.Z * 0.5
				for _, p in ipairs(plrs:GetPlayers()) do
					if p ~= lp then
						local char = p.Character
						if char then
							local hrp = char:FindFirstChild("HumanoidRootPart")
							if hrp then
								local rel = cf:PointToObjectSpace(hrp.Position)
								if math.abs(rel.X) <= hx and math.abs(rel.Z) <= hz then
									for _, item in ipairs(char:GetChildren()) do
										if CARPET_ITEMS[item.Name] then
											local uid = p.UserId
											if not core.CarpetSpammedPlayers[uid] then
												core.CarpetSpammedPlayers[uid] = true
												fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "balloon")
												fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "jumpscare")
												fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "rocket")
												fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "jail")
												task.delay(5, function() core.CarpetSpammedPlayers[uid] = nil end)
											end
											break
										end
									end
								end
							end
						end
					end
				end
			end

			if core.TpProtector and core.AdminRemote then
				for _, p in ipairs(plrs:GetPlayers()) do
					if p ~= lp then
						local char = p.Character
						if char then
							local hrp = char:FindFirstChild("HumanoidRootPart")
							if hrp then
								local cur = hrp.Position
								local uid = p.UserId
								local last = core.PlayerPositions[uid]
								if last and (cur - last).Magnitude > 7 then
									for _, item in ipairs(char:GetChildren()) do
										if CARPET_ITEMS[item.Name] then
											if not core.TpProtectorCooldowns[uid] or tick() - core.TpProtectorCooldowns[uid] > 3 then
												core.TpProtectorCooldowns[uid] = tick()
												fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "balloon")
												fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "jail")
											end
											break
										end
									end
								end
								core.PlayerPositions[uid] = cur
							end
						end
					end
				end
			end
		end)

		-- ============================================================
		-- GUI — BLACK & WHITE THEME
		-- ============================================================

		local sg = Instance.new("ScreenGui")
		sg.Name = "KdmlExecutorMobile"
		sg.Enabled = true
		sg.Parent = plrgui
		bpGui = sg

		local frame = Instance.new("Frame")
		frame.Name = "ExecutorFrame"
		frame.Visible = true
		frame.ZIndex = 1
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.Size = UDim2.new(0, 280, 0, 300)
		frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		frame.BackgroundTransparency = 0.05
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = true
		frame.Active = true
		frame.Parent = sg
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		restoreGuiPosition("BaseProtector", frame)

		-- Animated black and white stroke
		local frameStroke = Instance.new("UIStroke", frame)
		frameStroke.Thickness = 2
		frameStroke.Color = Color3.fromRGB(255, 255, 255)

		local frameGradient = Instance.new("UIGradient")
		frameGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
		})
		frameGradient.Parent = frameStroke

		task.spawn(function()
			while frameGradient and frameGradient.Parent do
				for i = 0, 360, 2 do
					if not frameGradient or not frameGradient.Parent then break end
					frameGradient.Rotation = i
					task.wait(0.01)
				end
			end
		end)

		-- Title bar
		local titlebar = Instance.new("Frame")
		titlebar.Name = "TitleBar"
		titlebar.ZIndex = 2
		titlebar.Size = UDim2.new(1, 0, 0, 36)
		titlebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		titlebar.BorderSizePixel = 0
		titlebar.Parent = frame
		Instance.new("UICorner", titlebar).CornerRadius = UDim.new(0, 8)

		local bfill = Instance.new("Frame")
		bfill.Size = UDim2.new(1, 0, 0, 12)
		bfill.Position = UDim2.new(0, 0, 1, -12)
		bfill.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		bfill.BorderSizePixel = 0
		bfill.ZIndex = 1
		bfill.Parent = titlebar

		-- Title label
		local titlelbl = Instance.new("TextLabel")
		titlelbl.ZIndex = 3
		titlelbl.Position = UDim2.new(0, 10, 0, 0)
		titlelbl.Size = UDim2.new(1, -80, 0.6, 0)
		titlelbl.BackgroundTransparency = 1
		titlelbl.Text = "Zero base protecter"
		titlelbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titlelbl.TextSize = 14
		titlelbl.Font = Enum.Font.GothamBold
		titlelbl.TextXAlignment = Enum.TextXAlignment.Left
		titlelbl.Parent = titlebar

		-- Ping label
		local pinglbl = Instance.new("TextLabel")
		pinglbl.ZIndex = 3
		pinglbl.Position = UDim2.new(0, 10, 0.6, 0)
		pinglbl.Size = UDim2.new(1, -80, 0.4, 0)
		pinglbl.BackgroundTransparency = 1
		pinglbl.Text = "PING: SAFE (25 ms)"
		pinglbl.TextColor3 = Color3.fromRGB(120, 120, 120)
		pinglbl.TextSize = 8
		pinglbl.Font = Enum.Font.GothamBold
		pinglbl.TextXAlignment = Enum.TextXAlignment.Left
		pinglbl.Parent = titlebar
		pingLbl = pinglbl

		-- Close button
		local closebtn = Instance.new("TextButton")
		closebtn.ZIndex = 3
		closebtn.Position = UDim2.new(1, -32, 0.5, -14)
		closebtn.Size = UDim2.new(0, 28, 0, 28)
		closebtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		closebtn.Text = "X"
		closebtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closebtn.TextSize = 14
		closebtn.Font = Enum.Font.GothamBold
		closebtn.Parent = titlebar
		Instance.new("UICorner", closebtn).CornerRadius = UDim.new(0, 5)

		closebtn.MouseEnter:Connect(function()
			TweenService:Create(closebtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}):Play()
		end)
		closebtn.MouseLeave:Connect(function()
			TweenService:Create(closebtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
		end)

		-- Minimize button
		local minbtn = Instance.new("TextButton")
		minbtn.ZIndex = 3
		minbtn.Position = UDim2.new(1, -64, 0.5, -14)
		minbtn.Size = UDim2.new(0, 28, 0, 28)
		minbtn.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
		minbtn.Text = "_"
		minbtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		minbtn.TextSize = 16
		minbtn.Font = Enum.Font.GothamBold
		minbtn.Parent = titlebar
		Instance.new("UICorner", minbtn).CornerRadius = UDim.new(0, 5)

		minbtn.MouseEnter:Connect(function()
			TweenService:Create(minbtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		minbtn.MouseLeave:Connect(function()
			TweenService:Create(minbtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(160, 160, 160)}):Play()
		end)

		-- Scroll area
		local scroll = Instance.new("ScrollingFrame")
		scroll.Position = UDim2.new(0, 8, 0, 44)
		scroll.Size = UDim2.new(1, -16, 1, -52)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ClipsDescendants = true
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.Parent = frame

		local listlay = Instance.new("UIListLayout")
		listlay.Padding = UDim.new(0, 6)
		listlay.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listlay.SortOrder = Enum.SortOrder.LayoutOrder
		listlay.Parent = scroll

		Instance.new("UIPadding", scroll).PaddingTop = UDim.new(0, 4)

		-- ============================================================
		-- TOGGLE ROWS — BLACK & WHITE THEME
		-- ============================================================
		local tstates = { Kick = false, NoKick = false, Protector = false, TpProtector = false }
		local tdots   = {}

		local function setVisual(key, state)
			local d = tdots[key]
			if d then
				d.Position         = state and UDim2.new(1, -19, 0, 1) or UDim2.new(0, 1, 0, 1)
				d.BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
			end
		end

		local function makeToggleRow(labelText, order, toggleKey)
			local row = Instance.new("Frame")
			row.LayoutOrder = order
			row.Size = UDim2.new(1, -4, 0, 40)
			row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			row.BorderSizePixel = 0
			row.Parent = scroll
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(50, 50, 50)
			stroke.Thickness = 1
			stroke.Transparency = 0.3
			stroke.Parent = row

			local lbl = Instance.new("TextLabel")
			lbl.Position = UDim2.new(0, 10, 0, 0)
			lbl.Size = UDim2.new(0.65, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = labelText
			lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
			lbl.TextSize = 12
			lbl.Font = Enum.Font.GothamBold
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = row

			local track = Instance.new("TextButton")
			track.Position = UDim2.new(0.8, 0, 0.5, -10)
			track.Size = UDim2.new(0, 40, 0, 20)
			track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			track.BorderSizePixel = 0
			track.Text = ""
			track.AutoButtonColor = false
			track.Parent = row
			Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

			local dot = Instance.new("Frame")
			dot.Position = UDim2.new(0, 1, 0, 1)
			dot.Size = UDim2.new(0, 18, 0, 18)
			dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			dot.BorderSizePixel = 0
			dot.Parent = track
			Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

			tdots[toggleKey] = dot

			local db = false
			track.MouseButton1Click:Connect(function()
				if db then return end
				db = true

				local on = not tstates[toggleKey]
				tstates[toggleKey] = on

				if toggleKey == "Kick" then
					if on then core.Mode = "Kick" tstates["NoKick"] = false setVisual("NoKick", false)
					else core.Mode = "None" end
				elseif toggleKey == "NoKick" then
					if on then core.Mode = "NoKick" tstates["Kick"] = false setVisual("Kick", false)
					else core.Mode = "None" end
				elseif toggleKey == "Protector" then
					core.BorderKick = on
				elseif toggleKey == "TpProtector" then
					core.TpProtector = on
				end

				setVisual(toggleKey, on)
				task.delay(0.2, function() db = false end)
			end)
		end

		makeToggleRow("SPAM IF STEALING (KICK)",    0, "Kick")
		makeToggleRow("SPAM IF STEALING (NO KICK)", 1, "NoKick")
		makeToggleRow("ANTI-TP SCAM (RECOMMENDED)", 2, "Protector")
		makeToggleRow("TP PROTECTOR",               3, "TpProtector")

		-- ============================================================
		-- CLOSE / MINIMIZE
		-- ============================================================
		closebtn.MouseButton1Click:Connect(function() sg.Enabled = false end)

		local minimized = false
		minbtn.MouseButton1Click:Connect(function()
			minimized = not minimized
			scroll.Visible = not minimized
			frame.Size = minimized and UDim2.new(0, 280, 0, 36) or UDim2.new(0, 280, 0, 300)
		end)

		-- ============================================================
		-- DRAGGABLE
		-- ============================================================
		do
			local dragging, dragStart, frameStart = false, nil, nil
			titlebar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = true dragStart = i.Position frameStart = frame.Position
				end
			end)
			titlebar.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
			end)
			uis.InputChanged:Connect(function(i)
				if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					local delta = i.Position - dragStart
					frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
				end
			end)
		end

		-- ============================================================
		-- PLAYER ROWS
		-- ============================================================
		local playerRows = {}

		local function addPlayerRow(p)
			if p == lp or playerRows[p.UserId] then return end

			local prow = Instance.new("Frame")
			prow.LayoutOrder = 1000000 + p.UserId % 100000
			prow.Size = UDim2.new(1, -4, 0, 60)
			prow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			prow.BorderSizePixel = 0
			prow.Parent = scroll
			Instance.new("UICorner", prow).CornerRadius = UDim.new(0, 8)

			local avatar = Instance.new("ImageLabel")
			avatar.Position = UDim2.new(0, 8, 0, 10)
			avatar.Size = UDim2.new(0, 40, 0, 40)
			avatar.BackgroundTransparency = 1
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150"
			avatar.Parent = prow
			Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

			local namelbl = Instance.new("TextLabel")
			namelbl.Position = UDim2.new(0, 55, 0, 8)
			namelbl.Size = UDim2.new(1, -130, 0, 20)
			namelbl.BackgroundTransparency = 1
			namelbl.Text = p.Name
			namelbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			namelbl.TextSize = 12
			namelbl.Font = Enum.Font.GothamBold
			namelbl.TextXAlignment = Enum.TextXAlignment.Left
			namelbl.Parent = prow

			local rolelbl = Instance.new("TextLabel")
			rolelbl.Position = UDim2.new(0, 55, 0, 28)
			rolelbl.Size = UDim2.new(1, -130, 0, 16)
			rolelbl.BackgroundTransparency = 1
			rolelbl.Text = "Player"
			rolelbl.TextColor3 = Color3.fromRGB(120, 120, 120)
			rolelbl.TextSize = 10
			rolelbl.Font = Enum.Font.Gotham
			rolelbl.TextXAlignment = Enum.TextXAlignment.Left
			rolelbl.Parent = prow

			local spambtn = Instance.new("TextButton")
			spambtn.Position = UDim2.new(1, -70, 0.5, -11)
			spambtn.Size = UDim2.new(0, 60, 0, 22)
			spambtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
			spambtn.Text = "SPAM"
			spambtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			spambtn.TextSize = 12
			spambtn.Font = Enum.Font.GothamBold
			spambtn.Parent = prow
			Instance.new("UICorner", spambtn).CornerRadius = UDim.new(0, 5)

			spambtn.MouseEnter:Connect(function()
				TweenService:Create(spambtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end)
			spambtn.MouseLeave:Connect(function()
				TweenService:Create(spambtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
			end)

			spambtn.MouseButton1Click:Connect(function()
				if not core.AdminRemote then return end
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "balloon")
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "ragdoll")
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "jumpscare")
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "rocket")
				fireAdmin("f888ee6e-c86d-46e1-93d7-0639d6635d42", p, "jail")
				punishPlayer(p)
			end)

			playerRows[p.UserId] = prow
		end

		local function removePlayerRow(p)
			if playerRows[p.UserId] then
				playerRows[p.UserId]:Destroy()
				playerRows[p.UserId] = nil
			end
		end

		for _, p in ipairs(plrs:GetPlayers()) do addPlayerRow(p) end
		table.insert(bpPlayerConns, plrs.PlayerAdded:Connect(addPlayerRow))
		table.insert(bpPlayerConns, plrs.PlayerRemoving:Connect(removePlayerRow))
	end

	createToggleRow("Base Protector", 2, function(enabled) if enabled then createBP() else destroyBP() end end)
end



--------------------------------------------------------------
-- AP ON STEAL (wrapped)
--------------------------------------------------------------
do
	local active = false
	local conn = nil
	local ANIM_ID = "rbxassetid://71186871415348"

	local function findAP() return player:WaitForChild("PlayerGui"):FindFirstChild("AdminPanel") end
	local function clk(b) pcall(function() for _, c in pairs(getconnections(b.MouseButton1Click)) do c:Fire() end; for _, c in pairs(getconnections(b.Activated)) do c:Fire() end end) end
	local function findPB(tp) local ap = findAP(); if not ap then return nil end; for _, d in pairs(ap:GetDescendants()) do if d:IsA("TextButton") or d:IsA("ImageButton") then local t = d:IsA("TextButton") and d.Text or ""; if t == "" and d:IsA("ImageButton") then for _, c in pairs(d:GetDescendants()) do if c:IsA("TextLabel") then t = c.Text; break end end end; if t == tp.DisplayName or t:find(tp.DisplayName) or t == tp.Name or t:find(tp.Name) then return d end end end; return nil end
	local function getCmds() local bs = {}; local ap = findAP(); if not ap then return bs end; for _, d in pairs(ap:GetDescendants()) do if d:IsA("TextButton") or d:IsA("ImageButton") then local t = d:IsA("TextButton") and d.Text or ""; if t == "" and d:IsA("ImageButton") then for _, c in pairs(d:GetDescendants()) do if c:IsA("TextLabel") and c.Text ~= "" then t = c.Text; break end end end; if t ~= "" and (t:match("^:") or t:match("^;")) then table.insert(bs, {button = d, name = t}) end end end; return bs end
	local function getNearest() local char = player.Character; if not char then return nil end; local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end; local n, nd = nil, math.huge; for _, p in pairs(Players:GetPlayers()) do if p ~= player and p.Character then local o = p.Character:FindFirstChild("HumanoidRootPart"); if o then local d = (hrp.Position - o.Position).Magnitude; if d < nd then nd = d; n = p end end end end; return n end
	local function spamNearest() local n = getNearest(); if not n then return end; local cmds = {}; for _, cd in pairs(getCmds()) do if not cd.name:lower():find("control") then table.insert(cmds, cd) end end; for _, cd in ipairs(cmds) do local pb = findPB(n); if pb then clk(pb) end; clk(cd.button); task.wait(0.05) end end
	local function isStealAnim() local char = player.Character; if not char then return false end; local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end; local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return false end; for _, track in ipairs(anim:GetPlayingAnimationTracks()) do if track.Animation and track.Animation.AnimationId == ANIM_ID then return true end end; return false end

	local fired = false
	createToggleRow("AP On Steal", 3, function(enabled)
		if enabled then
			if active then return end; active = true; fired = false
			conn = RunService.Heartbeat:Connect(function() if not active then return end; if isStealAnim() then if not fired then fired = true; task.spawn(spamNearest) end else fired = false end end)
		else
			active = false; if conn then conn:Disconnect(); conn = nil end
		end
	end)
end

--------------------------------------------------------------
-- RAGDOLL SELF (wrapped)
--------------------------------------------------------------
do
	local remote, found = nil, false
	local keybind, settingKb = nil, false

	-- Restore saved keybind
	local _savedRagKb = SaveData.keybinds and SaveData.keybinds["RagdollSelf"]
	if _savedRagKb then pcall(function() keybind = Enum.KeyCode[_savedRagKb] end) end

	local function ensureRemote()
		if found then return remote end
		pcall(function()
			if not player.Character then player.CharacterAdded:Wait() end
			local net = ReplicatedStorage:WaitForChild("Packages", 5):WaitForChild("Net", 5); if not net then return end
			local children = net:GetChildren(); local byName = {}; for i, obj in ipairs(children) do byName[obj.Name] = i end
			local idx = byName["RF/a0e78691-cb9b-4efc-ac08-9c06fea70059"]; if idx and children[idx + 1] then remote = children[idx + 1]; found = true end
		end)
		return remote
	end
	task.spawn(ensureRemote)

	local function fire() local r = ensureRemote(); if not r then return end; pcall(function() r:InvokeServer("f888ee6e-c86d-46e1-93d7-0639d6635d42", player, "ragdoll") end) end

	local popup = create("Frame", {Name = "RagdollKeybindPopup", Size = UDim2.new(0, 180, 0, 70), Position = UDim2.new(0.5, -90, 0.5, -35), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(15, 15, 15), BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = screenGui}, {create("UICorner", {CornerRadius = UDim.new(0, 8)}), create("UIStroke", {Color = Color3.fromRGB(80, 80, 80), Thickness = 1})})
	create("TextLabel", {Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 5), BackgroundTransparency = 1, Text = "Set Keybind", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 21, Parent = popup})
	local hint = create("TextLabel", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 28), BackgroundTransparency = 1, Text = "Press any key...", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(160, 160, 160), ZIndex = 21, Parent = popup})
	local clearBtn = create("TextButton", {Size = UDim2.new(0.5, -10, 0, 18), Position = UDim2.new(0.25, 0, 1, -23), BackgroundColor3 = Color3.fromRGB(40, 40, 40), Text = "Clear Bind", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(180, 180, 180), ZIndex = 21, Parent = popup}, {create("UICorner", {CornerRadius = UDim.new(0, 4)})})

	UserInputService.InputBegan:Connect(function(input) if not settingKb then return end; if input.UserInputType == Enum.UserInputType.Keyboard then keybind = input.KeyCode; settingKb = false; popup.Visible = false; SaveData.keybinds["RagdollSelf"] = input.KeyCode.Name; writeSaveData() end end)
	UserInputService.InputBegan:Connect(function(input, gp) if gp or settingKb then return end; if keybind and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keybind then task.spawn(fire) end end)
	clearBtn.MouseButton1Click:Connect(function() keybind = nil; settingKb = false; popup.Visible = false; SaveData.keybinds["RagdollSelf"] = nil; writeSaveData() end)

	local row = createToggleRow("Ragdoll Self", 4, function(enabled) if enabled then task.spawn(fire) end end)
	local rcBtn = create("TextButton", {Name = "RightClickZone", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = row})
	rcBtn.MouseButton2Click:Connect(function() settingKb = true; popup.Visible = true; hint.Text = keybind and ("Current: " .. keybind.Name .. " | Press new key...") or "Press any key..." end)
end

--------------------------------------------------------------
-- BOOSTER PAGE
--------------------------------------------------------------
local boosterPage = create("Frame", {Name = "Page_Booster", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = contentArea})
pageFrames["Booster"] = boosterPage

local boosterScroll = create("ScrollingFrame", {Name = "BoosterScroll", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = boosterPage})
create("UIGridLayout", {CellSize = UDim2.new(0.5, -3, 0, 26), CellPadding = UDim2.new(0, 6, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, Parent = boosterScroll})

local function createBoosterToggleRow(name, layoutOrder, callback)
	local row = create("Frame", {Name = "Row_" .. name, Size = UDim2.new(0.5, -3, 0, 26), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = layoutOrder, Parent = boosterScroll}, {create("UICorner", {CornerRadius = UDim.new(0, 5)})})
	create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Text = name, TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 200, 200), TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
	local tBg = create("Frame", {Name = "ToggleBg", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 30, 0, 14), BackgroundColor3 = Color3.fromRGB(40, 40, 40), BorderSizePixel = 0, Parent = row}, {create("UICorner", {CornerRadius = UDim.new(1, 0)}), create("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1})})
	local tCircle = create("Frame", {Name = "Circle", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.fromRGB(100, 100, 100), BorderSizePixel = 0, Parent = tBg}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
	local tBtn = create("TextButton", {Name = "Btn", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = tBg})
	local enabled = false
	local function setToggle(newState)
		if newState == enabled then return end
		enabled = newState
		if enabled then TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play(); TweenService:Create(tCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
		else TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play(); TweenService:Create(tCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play() end
		if not TOGGLE_NO_SAVE[name] then SaveData.toggles[name] = enabled; writeSaveData() end
		callback(enabled)
	end
	tBtn.MouseButton1Click:Connect(function() setToggle(not enabled) end)
	ToggleRegistry[name] = setToggle
	return row
end

--------------------------------------------------------------
-- AUTO STEAL (wrapped)
--------------------------------------------------------------
do
	local loaded = false
	local cleanup = {}
	local function destroyAS() if CoreGui:FindFirstChild("KZRAutoGrabUI") then CoreGui["KZRAutoGrabUI"]:Destroy() end; unregisterGuiPosition("AutoSteal"); for _, c in ipairs(cleanup) do if c and typeof(c) == "RBXScriptConnection" and c.Connected then c:Disconnect() end end; cleanup = {}; loaded = false end
	local function createAS()
		destroyAS(); loaded = true
		-- Full auto steal code runs in its own scope via loadstring-like pattern
		-- For brevity this is the same logic but all locals are scoped here
		local Datas = ReplicatedStorage:WaitForChild("Datas"); local Shared = ReplicatedStorage:WaitForChild("Shared"); local Utils = ReplicatedStorage:WaitForChild("Utils")
		local AD, ASh, NU
		task.spawn(function() for i=1,10 do local s1,d=pcall(require,Datas:WaitForChild("Animals")); local s2,sh=pcall(require,Shared:WaitForChild("Animals")); local s3,nu=pcall(require,Utils:WaitForChild("NumberUtils")); if s1 and d then AD=d end; if s2 and sh then ASh=sh end; if s3 and nu then NU=nu end; if AD and ASh and NU then break end; task.wait(0.5) end end)

		local function _getIT()
			local Pk = ReplicatedStorage:FindFirstChild("Packages"); if not Pk then return nil end; local SM = Pk:FindFirstChild("Synchronizer"); if not SM then return nil end
			local ok, syn = pcall(require, SM); if not ok or not syn then return nil end; local Get = syn.Get; if type(Get)~="function" then return nil end
			for i=1,5 do local s,u=pcall(getupvalue,Get,i); if s and type(u)=="table" then if u.___private or u.___channels or u.___data then return u end; for k,v in pairs(u) do if type(k)=="string" and k:match("^Plot_") or type(v)=="table" then return u end end end end
			local s,e=pcall(getfenv,Get); if s and e and e.self then return e.self end; return nil
		end
		local SI={_cache={},_data=nil}; task.spawn(function() for i=1,10 do SI._data=_getIT(); if SI._data then break end; task.wait(1) end end)
		local function sGet(n) if not n or type(n)~="string" then return nil end; if SI._cache[n]==false then return nil end; if SI._data then for _,k in ipairs({n,"Plot_"..n,"Plot"..n,n.."_Channel","Channel_"..n}) do if SI._data[k] then SI._cache[n]=SI._data[k]; return SI._data[k] end end; for k,v in pairs(SI._data) do if type(k)=="string" and (k==n or k:find(n,1,true)) and type(v)=="table" then SI._cache[n]=v; return v end end end; SI._cache[n]=false; return nil end
		local function sP(ch,p) if not ch or type(ch)~="table" then return nil end; if ch[p] then return ch[p] end; if type(ch.Get)=="function" then local ok,r=pcall(ch.Get,ch,p); if ok then return r end end; local alts={Owner={"owner","Owner","plotOwner","PlotOwner"},AnimalList={"animalList","AnimalList","animals","Animals","pets"}}; if alts[p] then for _,a in ipairs(alts[p]) do if ch[a] then return ch[a] end end end; return nil end

		local allAn,plotCh,lastH,PC,SC = {},{},{},{},{}
		local autoMode,selIdx,asEn,rClock,espObj = true,1,false,0,{}
		local TDIST,CSPD,DAMT,DSPD,RSPD,SCOOL = 10,70,8,100,420,0.4
		local sPct,sTgt,sPhase,dTgt,lsTime,sFiring = 0,nil,"idle",0,0,false
		local G={}

		local function isMyB(ad) if not ad or not ad.plot then return false end; local plots=Workspace:FindFirstChild("Plots"); if not plots then return false end; local plot=plots:FindFirstChild(ad.plot); if not plot then return false end; local ch=sGet(plot.Name); if ch then local o=sP(ch,"Owner"); if o then if typeof(o)=="Instance" and o:IsA("Player") then return o.UserId==player.UserId end; if type(o)=="table" and o.UserId then return o.UserId==player.UserId end; if typeof(o)=="Instance" then return o==player end end end; local sign=plot:FindFirstChild("PlotSign"); if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled end end; return false end
		local function hsv(h,s,v) local i=math.floor(h*6);local f=h*6-i; local p,q,t=v*(1-s),v*(1-f*s),v*(1-(1-f)*s); i=i%6; if i==0 then return Color3.new(v,t,p) elseif i==1 then return Color3.new(q,v,p) elseif i==2 then return Color3.new(p,v,t) elseif i==3 then return Color3.new(p,q,v) elseif i==4 then return Color3.new(t,p,v) else return Color3.new(v,p,q) end end
		local function rbw() return hsv((rClock%4)/4,1,1) end

		local function findPM(ad) if not ad then return nil end; local plots=Workspace:FindFirstChild("Plots"); if not plots then return nil end; local plot=plots:FindFirstChild(ad.plot); if not plot then return nil end; local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end; local pod=pods:FindFirstChild(ad.slot); if not pod then return nil end; local base=pod:FindFirstChild("Base"); if base then local spwn=base:FindFirstChild("Spawn"); if spwn then for _,c in ipairs(spwn:GetChildren()) do if c:IsA("Model") or c:IsA("BasePart") then return c end end end end; local function df(parent) for _,c in ipairs(parent:GetChildren()) do if c:IsA("Model") or (c:IsA("BasePart") and c.Name~="Base") then return c end; local r=df(c); if r then return r end end; return nil end; return df(pod) end
		local function getPP(ad) local m=findPM(ad); if not m then return nil end; if m:IsA("Model") then if m.PrimaryPart then return m.PrimaryPart.Position end; local ok,cf=pcall(function() return m:GetBoundingBox() end); if ok and cf then return cf.Position end; local p=m:FindFirstChildWhichIsA("BasePart"); if p then return p.Position end elseif m:IsA("BasePart") then return m.Position end; return nil end
		local function getPlrP() local char=player.Character; if not char then return nil end; local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end; return hrp.Position end
		local function distT(ad) local pp=getPP(ad); if not pp then return math.huge end; local plr=getPlrP(); if not plr then return math.huge end; return (pp-plr).Magnitude end

		local function clrESP(uid) if espObj[uid] then local e=espObj[uid]; if e.hl and e.hl.Parent then e.hl:Destroy() end; if e.bb and e.bb.Parent then e.bb:Destroy() end; espObj[uid]=nil end end
		local function clrAllESP() for uid in pairs(espObj) do clrESP(uid) end end
		local function apESP(ad) if not ad then return end; clrESP(ad.uid); local model=findPM(ad); if not model then return end; local hl=Instance.new("Highlight"); hl.FillTransparency=0.3; hl.OutlineTransparency=0; hl.FillColor=rbw(); hl.OutlineColor=rbw(); hl.Adornee=model; hl.Parent=Workspace; local anchor=model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) or model; local bb=Instance.new("BillboardGui"); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,180,0,38); bb.StudsOffset=Vector3.new(0,4,0); bb.Adornee=anchor; bb.Parent=Workspace; local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextColor3=Color3.new(1,1,1); lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.Text=(ad.name or "?").."\n"..(ad.genText or ""); lbl.Parent=bb; espObj[ad.uid]={hl=hl,bb=bb,lbl=lbl} end
		table.insert(cleanup, RunService.Heartbeat:Connect(function(dt) rClock=rClock+dt; local col=rbw(); for uid,e in pairs(espObj) do if e.hl and e.hl.Parent then e.hl.FillColor=col; e.hl.OutlineColor=col else espObj[uid]=nil end; if e.lbl then e.lbl.TextColor3=col end end end))
		local function refESP() clrAllESP(); if not asEn then return end; if autoMode then for _,pet in ipairs(allAn) do if not isMyB(pet) then apESP(pet) end end else local pet=allAn[selIdx]; if pet and not isMyB(pet) then apESP(pet) end end end

		local function findPr(ad) if not ad then return nil end; local c=PC[ad.uid]; if c and c.Parent then return c end; local plots=Workspace:FindFirstChild("Plots"); if not plots then return nil end; local plot=plots:FindFirstChild(ad.plot); if not plot then return nil end; local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end; local pod=pods:FindFirstChild(ad.slot); if not pod then return nil end; local base=pod:FindFirstChild("Base"); if not base then return nil end; local spwn=base:FindFirstChild("Spawn"); if not spwn then return nil end; local att=spwn:FindFirstChild("PromptAttachment"); if not att then return nil end; for _,p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") then PC[ad.uid]=p; return p end end; return nil end
		local function buildCB(pr) if SC[pr] then return end; local data={hold={},trig={},ready=true}; local ok1,c1=pcall(getconnections,pr.PromptButtonHoldBegan); if ok1 and type(c1)=="table" then for _,c in ipairs(c1) do if type(c.Function)=="function" then table.insert(data.hold,c.Function) end end end; local ok2,c2=pcall(getconnections,pr.Triggered); if ok2 and type(c2)=="table" then for _,c in ipairs(c2) do if type(c.Function)=="function" then table.insert(data.trig,c.Function) end end end; if #data.hold>0 or #data.trig>0 then SC[pr]=data end end
		local function runL(l) for _,fn in ipairs(l) do task.spawn(fn) end end
		local function fireSt(pr) local d=SC[pr]; if not d then return end; if #d.hold>0 then runL(d.hold) end; task.wait(0.05); if #d.trig>0 then runL(d.trig) end end

		local function getH(al) if not al then return "" end; local h=""; for s,d in pairs(al) do if type(d)=="table" then h=h..tostring(s)..tostring(d.Index)..tostring(d.Mutation) end end; return h end
		local function scanPl(plot) pcall(function() local uid=plot.Name; local ch=sGet(uid); if not ch then return end; local al=sP(ch,"AnimalList"); local hash=getH(al); if lastH[uid]==hash then return end; lastH[uid]=hash; for i=#allAn,1,-1 do if allAn[i].plot==uid then table.remove(allAn,i) end end; local owner=sP(ch,"Owner"); if not owner or not Players:FindFirstChild(owner.Name) then return end; if owner.UserId == player.UserId then return end; if not al then return end; for slot,ad in pairs(al) do if type(ad)=="table" then local nm=ad.Index; local info=AD and AD[nm]; if not info then continue end; local gen=ASh and ASh:GetGeneration(nm,ad.Mutation,ad.Traits,nil) or 0; local genT="$"..(NU and NU:ToString(gen) or tostring(gen)).."/s"; table.insert(allAn,{name=info.DisplayName or nm,genText=genT,genValue=gen,mutation=ad.Mutation or "None",owner=owner.Name or "?",plot=uid,slot=tostring(slot),uid=uid.."_"..tostring(slot)}) end end; table.sort(allAn,function(a,b) return a.genValue>b.genValue end) end) end
		local function setupPl(plot) if plotCh[plot.Name] then return end; local ch; for i=1,3 do ch=sGet(plot.Name); if ch then break end; task.wait(0.3) end; if not ch then return end; plotCh[plot.Name]=true; scanPl(plot); table.insert(cleanup, plot.DescendantAdded:Connect(function() task.wait(0.05); scanPl(plot) end)); table.insert(cleanup, plot.DescendantRemoving:Connect(function() task.wait(0.05); scanPl(plot) end)); task.spawn(function() while plot.Parent and plotCh[plot.Name] and loaded do task.wait(1); scanPl(plot) end end) end
		local function initScan() local plots=Workspace:FindFirstChild("Plots"); if not plots then for i=1,30 do plots=Workspace:FindFirstChild("Plots"); if plots then break end; task.wait(0.5) end; if not plots then return end end; for _,p in ipairs(plots:GetChildren()) do task.spawn(setupPl,p) end; table.insert(cleanup, plots.ChildAdded:Connect(function(p) task.wait(0.2); task.spawn(setupPl,p) end)); table.insert(cleanup, plots.ChildRemoved:Connect(function(p) plotCh[p.Name]=nil; lastH[p.Name]=nil; for i=#allAn,1,-1 do if allAn[i].plot==p.Name then table.remove(allAn,i) end end end)) end

		local W,EH,CH = 300,112,42; local isExp = true
		local function getPN() if autoMode then return "AUTO" end; local p = allAn[selIdx]; return p and string.upper(p.name) or "NONE" end
		local function updateUI() if G.pct then G.pct.Text = string.format("%.0f%%", sPct) end; if G.bar then G.bar.Size = UDim2.new(sPct/100, 0, 1, 0) end; if G.badge then if asEn then G.badge.Text = "ON"; G.badge.BackgroundColor3 = Color3.fromRGB(34, 170, 34) else G.badge.Text = "OFF"; G.badge.BackgroundColor3 = Color3.fromRGB(195, 22, 22) end end; if G.petLbl then G.petLbl.Text = getPN() end end

		local function createGUI()
			if CoreGui:FindFirstChild("KZRAutoGrabUI") then CoreGui.KZRAutoGrabUI:Destroy() end
			local sg = Instance.new("ScreenGui"); sg.Name = "KZRAutoGrabUI"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.DisplayOrder = 200; sg.IgnoreGuiInset = true; sg.Parent = CoreGui
			local mf = Instance.new("Frame"); mf.Name = "MainFrame"; mf.Size = UDim2.new(0, W, 0, EH); mf.Position = UDim2.new(0.5, -W/2, 0.75, 0); mf.BackgroundColor3 = Color3.fromRGB(0, 0, 0); mf.BackgroundTransparency = 0.15; mf.BorderSizePixel = 0; mf.Active = true; mf.ClipsDescendants = true; mf.Parent = sg
			Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 8); addAnimatedStroke(mf, 2)
			restoreGuiPosition("AutoSteal", mf)
			local header = Instance.new("Frame"); header.Name = "Header"; header.Size = UDim2.new(1, 0, 0, 38); header.BackgroundTransparency = 1; header.Parent = mf
			local title = Instance.new("TextLabel"); title.Size = UDim2.new(0, 120, 1, 0); title.Position = UDim2.new(0, 10, 0, 0); title.BackgroundTransparency = 1; title.Text = "[+] Calcium steal"; title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextColor3 = Color3.fromRGB(220, 220, 220); title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = header
			G.pct = Instance.new("TextLabel"); G.pct.Size = UDim2.new(0, 40, 1, 0); G.pct.Position = UDim2.new(0, 130, 0, 0); G.pct.BackgroundTransparency = 1; G.pct.Text = "0%"; G.pct.Font = Enum.Font.GothamBold; G.pct.TextSize = 14; G.pct.TextColor3 = Color3.fromRGB(178, 1, 255); G.pct.TextXAlignment = Enum.TextXAlignment.Left; G.pct.Parent = header
			G.badge = Instance.new("TextButton"); G.badge.Size = UDim2.new(0, 48, 0, 24); G.badge.Position = UDim2.new(0, 176, 0.5, -12); G.badge.BackgroundColor3 = Color3.fromRGB(195, 22, 22); G.badge.BorderSizePixel = 0; G.badge.Text = "OFF"; G.badge.Font = Enum.Font.GothamBold; G.badge.TextSize = 11; G.badge.TextColor3 = Color3.fromRGB(255, 255, 255); G.badge.AutoButtonColor = false; G.badge.Parent = header; Instance.new("UICorner", G.badge).CornerRadius = UDim.new(0, 6)
			local collapser = Instance.new("TextButton"); collapser.Size = UDim2.new(0, 24, 0, 24); collapser.Position = UDim2.new(1, -30, 0.5, -12); collapser.BackgroundTransparency = 1; collapser.Text = "–"; collapser.Font = Enum.Font.GothamBold; collapser.TextSize = 18; collapser.TextColor3 = Color3.fromRGB(160, 150, 140); collapser.AutoButtonColor = false; collapser.Parent = header
			local barBg = Instance.new("Frame"); barBg.Size = UDim2.new(1, 0, 0, 4); barBg.Position = UDim2.new(0, 0, 0, 38); barBg.BackgroundColor3 = Color3.fromRGB(30, 20, 18); barBg.BorderSizePixel = 0; barBg.Parent = mf
			G.bar = Instance.new("Frame"); G.bar.Size = UDim2.new(0, 0, 1, 0); G.bar.BackgroundColor3 = Color3.fromRGB(210, 30, 10); G.bar.BorderSizePixel = 0; G.bar.Parent = barBg; local barGrad = Instance.new("UIGradient"); barGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 20, 5)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))}; barGrad.Parent = G.bar
			local sep1 = Instance.new("Frame"); sep1.Size = UDim2.new(1, 0, 0, 1); sep1.Position = UDim2.new(0, 0, 0, 42); sep1.BackgroundColor3 = Color3.fromRGB(50, 40, 35); sep1.BorderSizePixel = 0; sep1.Parent = mf
			local selRow = Instance.new("Frame"); selRow.Name = "SelectionRow"; selRow.Size = UDim2.new(1, 0, 0, 56); selRow.Position = UDim2.new(0, 0, 0, 43); selRow.BackgroundTransparency = 1; selRow.Visible = isExp; selRow.Parent = mf
			local selBg = Instance.new("Frame"); selBg.Size = UDim2.new(1, -20, 1, -12); selBg.Position = UDim2.new(0, 10, 0, 6); selBg.BackgroundColor3 = Color3.fromRGB(22, 16, 14); selBg.BorderSizePixel = 0; selBg.Parent = selRow; Instance.new("UICorner", selBg).CornerRadius = UDim.new(0, 8)
			local lBtn = Instance.new("TextButton"); lBtn.Size = UDim2.new(0, 34, 1, 0); lBtn.BackgroundTransparency = 1; lBtn.Text = "<"; lBtn.Font = Enum.Font.GothamBold; lBtn.TextSize = 18; lBtn.TextColor3 = Color3.fromRGB(175, 165, 150); lBtn.AutoButtonColor = false; lBtn.Parent = selBg
			local rBtn = Instance.new("TextButton"); rBtn.Size = UDim2.new(0, 34, 1, 0); rBtn.Position = UDim2.new(1, -34, 0, 0); rBtn.BackgroundTransparency = 1; rBtn.Text = ">"; rBtn.Font = Enum.Font.GothamBold; rBtn.TextSize = 18; rBtn.TextColor3 = Color3.fromRGB(175, 165, 150); rBtn.AutoButtonColor = false; rBtn.Parent = selBg
			G.petLbl = Instance.new("TextLabel"); G.petLbl.Size = UDim2.new(1, -68, 1, 0); G.petLbl.Position = UDim2.new(0, 34, 0, 0); G.petLbl.BackgroundTransparency = 1; G.petLbl.Text = "AUTO"; G.petLbl.Font = Enum.Font.GothamBold; G.petLbl.TextSize = 14; G.petLbl.TextColor3 = Color3.fromRGB(228, 218, 205); G.petLbl.TextTruncate = Enum.TextTruncate.AtEnd; G.petLbl.Parent = selBg
			-- Drag
			local dr,ds,sp = false,nil,nil
			header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dr=true; ds=input.Position; sp=mf.Position end end)
			table.insert(cleanup, UserInputService.InputChanged:Connect(function(input) if dr and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d=input.Position-ds; mf.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end))
			table.insert(cleanup, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dr=false end end))
			collapser.MouseButton1Click:Connect(function() isExp=not isExp; collapser.Text=isExp and "–" or "+"; TweenService:Create(mf,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.new(0,W,0,isExp and EH or CH)}):Play(); selRow.Visible=isExp end)
			G.badge.MouseButton1Click:Connect(function() asEn=not asEn; if not asEn then clrAllESP(); sPct=0; sTgt=nil; sPhase="idle"; dTgt=0; sFiring=false else sPhase="charging"; refESP() end; updateUI() end)
			lBtn.MouseButton1Click:Connect(function() if autoMode then autoMode=false; selIdx=math.max(1,#allAn) else selIdx=selIdx-1; if selIdx<1 then autoMode=true; selIdx=1 end end; sPct=0; sTgt=nil; sPhase=asEn and "charging" or "idle"; dTgt=0; sFiring=false; updateUI(); refESP() end)
			rBtn.MouseButton1Click:Connect(function() if autoMode then autoMode=false; selIdx=1 else selIdx=selIdx+1; if selIdx>#allAn then autoMode=true; selIdx=1 end end; sPct=0; sTgt=nil; sPhase=asEn and "charging" or "idle"; dTgt=0; sFiring=false; updateUI(); refESP() end)
			return true
		end

		local function getTgt() if not asEn then return nil end; if autoMode then if #allAn==0 then return nil end; local best,bd=nil,math.huge; for _,pet in ipairs(allAn) do if not isMyB(pet) then local d=distT(pet); if d<bd then bd=d; best=pet end end end; return best else local pet=allAn[selIdx]; if pet and not isMyB(pet) then return pet end; return nil end end

		table.insert(cleanup, RunService.Heartbeat:Connect(function(dt)
			if not loaded or not asEn then if sPhase~="idle" then sPct=0; sTgt=nil; sPhase="idle"; dTgt=0; sFiring=false; updateUI() end; return end; if sFiring then return end
			local target=getTgt(); if target~=sTgt then sTgt=target; if not target then if sPhase=="dipping" or sPhase=="rushing" then sPct=90; sPhase="holding" elseif sPhase=="idle" then sPhase="charging" end else if sPhase=="idle" then sPhase="charging" elseif sPhase=="holding" or sPhase=="dipping" or sPhase=="rushing" then sPct=90; sPhase="holding"; dTgt=0 end end end
			if not sTgt then updateUI(); return end; local dist=distT(sTgt)
			if sPhase=="charging" then sPct=sPct+CSPD*dt; if sPct>=95 then sPct=95; sPhase="holding" end
			elseif sPhase=="holding" then sPct=95; if dist<=TDIST then dTgt=95-DAMT-math.random(0,3); sPhase="dipping" end
			elseif sPhase=="dipping" then sPct=sPct-DSPD*dt; if sPct<=dTgt then sPct=dTgt; sPhase="rushing" end
			elseif sPhase=="rushing" then sPct=sPct+RSPD*dt; if sPct>=100 then sPct=100; updateUI(); local now=tick(); if now-lsTime>=SCOOL then lsTime=now; sFiring=true; task.spawn(function() local pr=PC[sTgt and sTgt.uid or ""] or findPr(sTgt); if pr then buildCB(pr); if SC[pr] and SC[pr].ready then fireSt(pr) end end; task.wait(0.25); sPct=95; sPhase="holding"; dTgt=0; sFiring=false; refESP(); updateUI() end) else sPct=95; sPhase="holding"; dTgt=0 end; return end end
			updateUI()
		end))
		task.spawn(function() while loaded do task.wait(3); if asEn then refESP() end end end)
		task.spawn(function() while not AD or not ASh or not NU do task.wait(0.5) end; task.wait(1.5); if not createGUI() then return end; initScan(); task.wait(1); updateUI() end)
	end
	createBoosterToggleRow("Auto Steal", 1, function(en) if en then createAS() else destroyAS() end end)
end

--------------------------------------------------------------
-- OPTIMIZER (wrapped)
--------------------------------------------------------------
do
	local Opt = {Enabled = false, Mats = {}, Decals = {}, WWS = nil, GS = nil}
	local function enOpt()
		if Opt.Enabled then return end; Opt.Enabled = true
		Opt.WWS = Workspace.Terrain.WaterWaveSize; Opt.GS = game:GetService("Lighting").GlobalShadows
		Workspace.Terrain.WaterWaveSize = 0; game:GetService("Lighting").GlobalShadows = false
		for _, obj in pairs(game:GetDescendants()) do if obj:IsA("BasePart") and not Opt.Mats[obj] then Opt.Mats[obj] = obj.Material; obj.Material = Enum.Material.Plastic elseif obj:IsA("Decal") and not Opt.Decals[obj] then Opt.Decals[obj] = obj.Transparency; obj.Transparency = 1 end end
	end
	local function disOpt()
		if not Opt.Enabled then return end; Opt.Enabled = false
		if Opt.WWS then Workspace.Terrain.WaterWaveSize = Opt.WWS end; if Opt.GS ~= nil then game:GetService("Lighting").GlobalShadows = Opt.GS end
		for obj, mat in pairs(Opt.Mats) do if obj and obj.Parent then obj.Material = mat end end; for obj, trans in pairs(Opt.Decals) do if obj and obj.Parent then obj.Transparency = trans end end; Opt.Mats = {}; Opt.Decals = {}
	end
	createBoosterToggleRow("Optimizer", 2, function(en) if en then enOpt() else disOpt() end end)
end

--------------------------------------------------------------
-- NO ANIM (wrapped)
--------------------------------------------------------------
do
	local active = false; local conns = {}
	local function disAnims(char) local hum = char:WaitForChild("Humanoid", 5); if not hum then return end; for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end; table.insert(conns, hum.AnimationPlayed:Connect(function(t) if active then t:Stop() end end)) end
	createBoosterToggleRow("No Anim", 3, function(en) if en then active = true; if player.Character then disAnims(player.Character) end; table.insert(conns, player.CharacterAdded:Connect(function(c) if active then disAnims(c) end end)) else active = false; for _, c in ipairs(conns) do if c and c.Connected then c:Disconnect() end end; conns = {} end end)
end

--------------------------------------------------------------
-- PLAYER ESP (wrapped)
--------------------------------------------------------------
do
	local hls, bbs, conns, act = {}, {}, {}, false
	local COL = Color3.fromRGB(255, 0, 0)
	local function mkHL(char) local h = Instance.new("Highlight"); h.Name = "DashESP_Highlight"; h.Adornee = char; h.FillColor = COL; h.FillTransparency = 0.25; h.OutlineColor = COL; h.OutlineTransparency = 0; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = CoreGui; return h end
	local function mkBB(char, tp) local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5); if not hrp then return nil end; local bb = Instance.new("BillboardGui"); bb.Name = "DashESP_Name"; bb.Adornee = hrp; bb.AlwaysOnTop = true; bb.Size = UDim2.new(0, 100, 0, 20); bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0); bb.MaxDistance = 600; bb.Parent = CoreGui; local bg = Instance.new("Frame", bb); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0); bg.BackgroundTransparency = 0.4; Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6); local txt = Instance.new("TextLabel", bg); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamSemibold; txt.TextSize = 13; txt.TextColor3 = COL; txt.TextStrokeTransparency = 0.2; txt.Text = tp.DisplayName; return bb end
	local function attach(tp) if tp == player then return end; local function apply(char) if not char or not char.Parent or not act then return end; if hls[tp] then pcall(function() hls[tp]:Destroy() end) end; if bbs[tp] then pcall(function() bbs[tp]:Destroy() end) end; hls[tp] = mkHL(char); bbs[tp] = mkBB(char, tp) end; if tp.Character then apply(tp.Character) end; table.insert(conns, tp.CharacterAdded:Connect(apply)) end
	local function remove(tp) if hls[tp] then pcall(function() hls[tp]:Destroy() end); hls[tp] = nil end; if bbs[tp] then pcall(function() bbs[tp]:Destroy() end); bbs[tp] = nil end end
	createBoosterToggleRow("ESP", 4, function(en)
		if en then act = true; for _, p in ipairs(Players:GetPlayers()) do attach(p) end; table.insert(conns, Players.PlayerAdded:Connect(function(p) if act then attach(p) end end)); table.insert(conns, Players.PlayerRemoving:Connect(function(p) remove(p) end))
		else act = false; for _, c in ipairs(conns) do if c and c.Connected then c:Disconnect() end end; conns = {}; for p in pairs(hls) do remove(p) end end
	end)
end

--------------------------------------------------------------
-- ANTI-RAGDOLL (wrapped)
--------------------------------------------------------------
do
	local conn = nil
	createBoosterToggleRow("Anti-Ragdoll", 5, function(en)
		if en then
			if conn then return end
			conn = RunService.Heartbeat:Connect(function()
				local char = player.Character; if not char then return end; local root = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
				if hum and hum.Parent then local st = hum:GetState(); if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.Running); if Workspace.CurrentCamera then Workspace.CurrentCamera.CameraSubject = hum end; pcall(function() local PS = player:FindFirstChild("PlayerScripts"); if PS then local PM = PS:FindFirstChild("PlayerModule"); if PM then local C = require(PM:FindFirstChild("ControlModule")); if C and C.Enable then C:Enable() end end end end); if root then root.Velocity = Vector3.new(0,0,0); root.RotVelocity = Vector3.new(0,0,0) end end end
				for _, obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end end
			end)
		else if conn then conn:Disconnect(); conn = nil end end
	end)
end

--------------------------------------------------------------
-- KICK ON STEAL (wrapped)
--------------------------------------------------------------
do
	local conns, act = {}, false
	local KW, KM = "you stole", "Auto kicked!"
	local function hasKW(t) return typeof(t) == "string" and string.find(string.lower(t), KW) ~= nil end
	local function doKick() pcall(function() player:Kick(KM) end) end
	local function watchObj(obj) if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end; if hasKW(obj.Text) then doKick(); return end; table.insert(conns, obj:GetPropertyChangedSignal("Text"):Connect(function() if act and hasKW(obj.Text) then doKick() end end)) end
	local function watchGui(gui) for _, obj in ipairs(gui:GetDescendants()) do watchObj(obj) end; table.insert(conns, gui.DescendantAdded:Connect(function(d) if act then watchObj(d) end end)) end
	createBoosterToggleRow("Kick on Steal", 6, function(en)
		if en then act = true; local pg = player:WaitForChild("PlayerGui"); for _, gui in ipairs(pg:GetChildren()) do watchGui(gui) end; table.insert(conns, pg.ChildAdded:Connect(function(gui) if act then watchGui(gui) end end))
		else act = false; for _, c in ipairs(conns) do if c and c.Connected then c:Disconnect() end end; conns = {} end
	end)
end

--------------------------------------------------------------
-- SPEED BOOST (wrapped)
--------------------------------------------------------------
do
	local conns, act = {}, false
	local SPD = 28
	local function remAcc(char) if not char then return end; for _, a in ipairs(char:GetDescendants()) do if a:IsA("Accessory") then a:Destroy() end end; table.insert(conns, char.DescendantAdded:Connect(function(c) if act and c:IsA("Accessory") then c:Destroy() end end)) end
	createBoosterToggleRow("Speed Boost", 7, function(en)
		if en then act = true; if player.Character then remAcc(player.Character) end; table.insert(conns, player.CharacterAdded:Connect(function(c) if act then remAcc(c) end end))
			table.insert(conns, RunService.Heartbeat:Connect(function() if not act then return end; local char = player.Character; if not char then return end; local hum = char:FindFirstChildOfClass("Humanoid"); local rp = char:FindFirstChild("HumanoidRootPart"); if not hum or not rp then return end; if hum.MoveDirection.Magnitude > 0 then rp.Velocity = Vector3.new(hum.MoveDirection.X * SPD, rp.Velocity.Y, hum.MoveDirection.Z * SPD) end end))
		else act = false; for _, c in ipairs(conns) do if c and c.Connected then c:Disconnect() end end; conns = {} end
	end)
end

--------------------------------------------------------------
-- BALLOON RESET (wrapped)
--------------------------------------------------------------
do
	local conns, act = {}, false
	local DC = CFrame.new(1000003.56, 999999.69, 8.17)
	local function eqCarpet() local char = player.Character; if not char then return end; local bp = player:FindFirstChild("Backpack"); if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("carpet") then char.Humanoid:EquipTool(t); return end end end end
	local function lockCam(saved) local cam = Workspace.CurrentCamera; cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = saved; local hc; hc = RunService.RenderStepped:Connect(function() cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = saved end); local nc = player.CharacterAdded:Wait(); hc:Disconnect(); cam.CameraType = Enum.CameraType.Custom; local hrp = nc:WaitForChild("HumanoidRootPart", 5); if hrp then cam.CameraSubject = nc:WaitForChild("Humanoid", 5) end end
	local function tpDie() local char = player.Character; if not char then return end; local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid"); if not hrp or not hum then return end; local saved = Workspace.CurrentCamera.CFrame; eqCarpet(); task.wait(); hrp.CFrame = DC; task.spawn(lockCam, saved); local cn; cn = RunService.Heartbeat:Connect(function() if not char or not char.Parent then cn:Disconnect(); return end; local h = char:FindFirstChild("Humanoid"); local r = char:FindFirstChild("HumanoidRootPart"); if not h or not r then cn:Disconnect(); return end; if h.Health <= 0 then cn:Disconnect(); return end; r.CFrame = DC end) end
	local function hasBal(t) return typeof(t) == "string" and string.lower(t):find('ran "balloon" on you!') ~= nil end
	local function chk(t) if act and hasBal(t) then tpDie() end end
	local function watchObj(obj) if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end; chk(obj.Text); table.insert(conns, obj:GetPropertyChangedSignal("Text"):Connect(function() chk(obj.Text) end)) end
	local function watchGui(gui) for _, obj in ipairs(gui:GetDescendants()) do watchObj(obj) end; table.insert(conns, gui.DescendantAdded:Connect(function(d) if act then watchObj(d) end end)) end
	createBoosterToggleRow("Ballon Reset", 8, function(en)
		if en then act = true; local pg = player:WaitForChild("PlayerGui"); for _, gui in ipairs(pg:GetChildren()) do watchGui(gui) end; table.insert(conns, pg.ChildAdded:Connect(function(gui) if act then watchGui(gui) end end))
		else act = false; for _, c in ipairs(conns) do if c and c.Connected then c:Disconnect() end end; conns = {} end
	end)
end

--------------------------------------------------------------
-- REJOIN (wrapped)
--------------------------------------------------------------
do
	local TS = game:GetService("TeleportService")
	createBoosterToggleRow("Rejoin", 9, function(en) if en then TS:Teleport(game.PlaceId, player) end end)
end

--------------------------------------------------------------
-- TIMER ESP (wrapped)
--------------------------------------------------------------
do
	local instances, conn, act = {}, nil, false
	local function mkBB(plot, mp) if instances[plot.Name] then instances[plot.Name]:Destroy() end; local bb = Instance.new("BillboardGui"); bb.Name = "TimerESP_" .. plot.Name; bb.Size = UDim2.new(0, 50, 0, 25); bb.StudsOffset = Vector3.new(0, 5, 0); bb.AlwaysOnTop = true; bb.Adornee = mp; bb.MaxDistance = 1000; bb.Parent = plot; local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSans; lbl.TextColor3 = Color3.fromRGB(255, 255, 255); lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.new(0, 0, 0); lbl.Parent = bb; instances[plot.Name] = bb; return bb end
	local function upd() local pf = Workspace:FindFirstChild("Plots"); if not pf then return end; for _, plot in ipairs(pf:GetChildren()) do local pu = plot:FindFirstChild("Purchases"); local pb = pu and pu:FindFirstChild("PlotBlock"); local mp = pb and pb:FindFirstChild("Main"); local bb = instances[plot.Name]; local tl = mp and mp:FindFirstChild("BillboardGui") and mp.BillboardGui:FindFirstChild("RemainingTime"); if tl and mp then bb = bb or mkBB(plot, mp); local lbl = bb:FindFirstChildWhichIsA("TextLabel"); if lbl then lbl.Text = tl.Text end elseif bb then bb:Destroy(); instances[plot.Name] = nil end end end
	createBoosterToggleRow("Timer ESP", 10, function(en)
		if en then act = true; conn = RunService.RenderStepped:Connect(upd)
		else act = false; if conn then conn:Disconnect(); conn = nil end; for n, bb in pairs(instances) do if bb and bb.Parent then bb:Destroy() end end; instances = {} end
	end)
end

--------------------------------------------------------------
-- TP PAGE (Full Semi-TP)
--------------------------------------------------------------
do
	local tpPage = create("Frame", {Name = "Page_TP", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = contentArea})
	pageFrames["TP"] = tpPage

	local tpScroll = create("ScrollingFrame", {Name = "TPScroll", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = tpPage})
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = tpScroll})

	local function createTPToggle(name, order, callback)
		local row = create("Frame", {Name = "Row_" .. name, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = order, Parent = tpScroll}, {create("UICorner", {CornerRadius = UDim.new(0, 5)})})
		create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Text = name, TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 200, 200), TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
		local tBg = create("Frame", {Name = "ToggleBg", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 30, 0, 14), BackgroundColor3 = Color3.fromRGB(40, 40, 40), BorderSizePixel = 0, Parent = row}, {create("UICorner", {CornerRadius = UDim.new(1, 0)}), create("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1})})
		local tC = create("Frame", {Name = "Circle", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.fromRGB(100, 100, 100), BorderSizePixel = 0, Parent = tBg}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
		local tBtn = create("TextButton", {Name = "Btn", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = tBg})
		local enabled = false
		local function setToggle(newState)
			if newState == enabled then return end
			enabled = newState
			if enabled then TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play(); TweenService:Create(tC, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
			else TweenService:Create(tBg, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play(); TweenService:Create(tC, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play() end
			if not TOGGLE_NO_SAVE[name] then SaveData.toggles[name] = enabled; writeSaveData() end
			callback(enabled)
		end
		tBtn.MouseButton1Click:Connect(function() setToggle(not enabled) end)
		ToggleRegistry[name] = setToggle
	end

	-- Full Semi-TP embedded (with auto-grab/auto-steal)
	local stpActive = false
	local stpGui = nil
	local stpCleanup = {}

	local function destroySTP()
		if CoreGui:FindFirstChild("FullSemiTPGui") then
			CoreGui["FullSemiTPGui"]:Destroy()
		end
		unregisterGuiPosition("FullSemiTP")
		for _, c in ipairs(stpCleanup) do
			if c and typeof(c) == "RBXScriptConnection" and c.Connected then
				c:Disconnect()
			end
		end
		stpCleanup = {}
		stpGui = nil
		stpActive = false
	end

	local function createSTP()
		destroySTP()
		stpActive = true

		local AnimalsData_STP = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

		local FFlags = {
			GameNetPVHeaderRotationalVelocityZeroCutoffExponent = -5000,
			LargeReplicatorWrite5 = true, LargeReplicatorEnabled9 = true,
			AngularVelociryLimit = 360,
			TimestepArbiterVelocityCriteriaThresholdTwoDt = 2147483646,
			S2PhysicsSenderRate = 15000, DisableDPIScale = true,
			MaxDataPacketPerSend = 2147483647, PhysicsSenderMaxBandwidthBps = 20000,
			TimestepArbiterHumanoidLinearVelThreshold = 21,
			MaxMissedWorldStepsRemembered = -2147483648,
			PlayerHumanoidPropertyUpdateRestrict = true,
			SimDefaultHumanoidTimestepMultiplier = 0,
			StreamJobNOUVolumeLengthCap = 2147483647,
			DebugSendDistInSteps = -2147483648,
			GameNetDontSendRedundantNumTimes = 1,
			CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent = 1,
			CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth = 1,
			LargeReplicatorSerializeRead3 = true,
			ReplicationFocusNouExtentsSizeCutoffForPauseStuds = 2147483647,
			CheckPVCachedVelThresholdPercent = 10,
			CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth = 1,
			GameNetDontSendRedundantDeltaPositionMillionth = 1,
			InterpolationFrameVelocityThresholdMillionth = 5,
			StreamJobNOUVolumeCap = 2147483647,
			InterpolationFrameRotVelocityThresholdMillionth = 5,
			CheckPVCachedRotVelThresholdPercent = 10,
			WorldStepMax = 30,
			InterpolationFramePositionThresholdMillionth = 5,
			TimestepArbiterHumanoidTurningVelThreshold = 1,
			SimOwnedNOUCountThresholdMillionth = 2147483647,
			GameNetPVHeaderLinearVelocityZeroCutoffExponent = -5000,
			NextGenReplicatorEnabledWrite4 = true,
			TimestepArbiterOmegaThou = 1073741823,
			MaxAcceptableUpdateDelay = 1,
			LargeReplicatorSerializeWrite4 = true,
		}

		local defaultFFlags = {
			GameNetPVHeaderRotationalVelocityZeroCutoffExponent = 8,
			LargeReplicatorWrite5 = false, LargeReplicatorEnabled9 = false,
			AngularVelociryLimit = 180,
			TimestepArbiterVelocityCriteriaThresholdTwoDt = 100,
			S2PhysicsSenderRate = 60, DisableDPIScale = false,
			MaxDataPacketPerSend = 1024, PhysicsSenderMaxBandwidthBps = 10000,
			TimestepArbiterHumanoidLinearVelThreshold = 10,
			MaxMissedWorldStepsRemembered = 10,
			PlayerHumanoidPropertyUpdateRestrict = false,
			SimDefaultHumanoidTimestepMultiplier = 1,
			StreamJobNOUVolumeLengthCap = 1000,
			DebugSendDistInSteps = 10,
			GameNetDontSendRedundantNumTimes = 10,
			CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent = 50,
			CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth = 100,
			LargeReplicatorSerializeRead3 = false,
			ReplicationFocusNouExtentsSizeCutoffForPauseStuds = 100,
			CheckPVCachedVelThresholdPercent = 50,
			CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth = 100,
			GameNetDontSendRedundantDeltaPositionMillionth = 100,
			InterpolationFrameVelocityThresholdMillionth = 100,
			StreamJobNOUVolumeCap = 1000,
			InterpolationFrameRotVelocityThresholdMillionth = 100,
			CheckPVCachedRotVelThresholdPercent = 50,
			WorldStepMax = 60,
			InterpolationFramePositionThresholdMillionth = 100,
			TimestepArbiterHumanoidTurningVelThreshold = 10,
			SimOwnedNOUCountThresholdMillionth = 1000,
			GameNetPVHeaderLinearVelocityZeroCutoffExponent = 8,
			NextGenReplicatorEnabledWrite4 = false,
			TimestepArbiterOmegaThou = 1000,
			MaxAcceptableUpdateDelay = 10,
			LargeReplicatorSerializeWrite4 = false,
		}

		local desyncActive = false
		local firstActivation = true

		local function applyFFlags(flags)
			for name, value in pairs(flags) do
				pcall(function() setfflag(tostring(name), tostring(value)) end)
			end
		end

		local function respawn(plr)
			local char = plr.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
				char:ClearAllChildren()
				local newChar = Instance.new("Model")
				newChar.Parent = workspace
				plr.Character = newChar
				task.wait()
				plr.Character = char
				newChar:Destroy()
			end
		end

		local CONFIG = { AUTO_STEAL_NEAREST = false }

		local allAnimalsCache = {}
		local PromptMemoryCache = {}
		local LastTargetUID = nil
		local LastPlayerPosition = nil
		local PlayerVelocity = Vector3.zero

		local AUTO_STEAL_PROX_RADIUS = 100
		local IsStealing = false
		local StealProgress = 0
		local CurrentStealTarget = nil
		local StealStartTime = 0

		local stealConnection = nil
		local velocityConnection = nil

		local stealCooldown = 0.2
		local HOLD_DURATION = 0.5

		local selectedBase = SaveData.selections and SaveData.selections["FullSemiTP_Base"] or "Base 2"

		local BASE_WAYPOINTS = {
			["Base 1"] = {
				{pos = Vector3.new(-359.3, -6.8, 5.6),   delay = 0.1},
				{pos = Vector3.new(-360.2, -6.8, 115.1),  delay = 0.1},
				{pos = Vector3.new(-337.2, -4.9, 100.4),  delay = 0.3},
				{pos = Vector3.new(-350.3, -6.8, 76.7),   delay = 0.1},
			},
			["Base 2"] = {
				{pos = Vector3.new(-359.7, -6.8, 113.3),  delay = 0.1},
				{pos = Vector3.new(-363.5, -6.8, 6.9),    delay = 0.1},
				{pos = Vector3.new(-337.6, -4.8, 19.9),   delay = 0.3},
				{pos = Vector3.new(-348.0, -6.8, 48.0),   delay = 0.1},
			},
		}

		local function getHRP()
			local char = player.Character
			if not char then return nil end
			return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
		end

		local function isMyBase(plotName)
			local plot = workspace.Plots:FindFirstChild(plotName)
			if not plot then return false end
			local sign = plot:FindFirstChild("PlotSign")
			if sign then
				local yourBase = sign:FindFirstChild("YourBase")
				if yourBase and yourBase:IsA("BillboardGui") then
					return yourBase.Enabled == true
				end
			end
			return false
		end

		local function scanSinglePlot(plot)
			if not plot or not plot:IsA("Model") then return end
			if isMyBase(plot.Name) then return end

			local podiums = plot:FindFirstChild("AnimalPodiums")
			if not podiums then return end

			for _, podium in ipairs(podiums:GetChildren()) do
				if podium:IsA("Model") and podium:FindFirstChild("Base") then
					local animalName = "Unknown"
					local spawn = podium.Base:FindFirstChild("Spawn")
					if spawn then
						for _, child in ipairs(spawn:GetChildren()) do
							if child:IsA("Model") and child.Name ~= "PromptAttachment" then
								animalName = child.Name
								local animalInfo = AnimalsData_STP[animalName]
								if animalInfo and animalInfo.DisplayName then
									animalName = animalInfo.DisplayName
								end
								break
							end
						end
					end

					table.insert(allAnimalsCache, {
						name = animalName,
						plot = plot.Name,
						slot = podium.Name,
						worldPosition = podium:GetPivot().Position,
						uid = plot.Name .. "_" .. podium.Name,
					})
				end
			end
		end

		local function initializeScanner()
			task.wait(2)
			local plots = workspace:WaitForChild("Plots", 10)
			if not plots then return end

			for _, plot in ipairs(plots:GetChildren()) do
				if plot:IsA("Model") then
					scanSinglePlot(plot)
				end
			end

			table.insert(stpCleanup, plots.ChildAdded:Connect(function(plot)
				if plot:IsA("Model") then
					task.wait(0.5)
					scanSinglePlot(plot)
				end
			end))

			task.spawn(function()
				while stpActive do
					task.wait(5)
					allAnimalsCache = {}
					for _, plot in ipairs(plots:GetChildren()) do
						if plot:IsA("Model") then
							scanSinglePlot(plot)
						end
					end
				end
			end)
		end

		local function findProximityPromptForAnimal(animalData)
			if not animalData then return nil end

			local cachedPrompt = PromptMemoryCache[animalData.uid]
			if cachedPrompt and cachedPrompt.Parent then
				return cachedPrompt
			end

			local plot = workspace.Plots:FindFirstChild(animalData.plot)
			if not plot then return nil end

			local podiums = plot:FindFirstChild("AnimalPodiums")
			if not podiums then return nil end

			local podium = podiums:FindFirstChild(animalData.slot)
			if not podium then return nil end

			local base = podium:FindFirstChild("Base")
			if not base then return nil end

			local spawn = base:FindFirstChild("Spawn")
			if not spawn then return nil end

			local attach = spawn:FindFirstChild("PromptAttachment")
			if not attach then return nil end

			for _, p in ipairs(attach:GetChildren()) do
				if p:IsA("ProximityPrompt") then
					PromptMemoryCache[animalData.uid] = p
					return p
				end
			end

			return nil
		end

		local function updatePlayerVelocity()
			local hrp = getHRP()
			if not hrp then return end

			local currentPos = hrp.Position

			if LastPlayerPosition then
				PlayerVelocity = (currentPos - LastPlayerPosition) / task.wait()
			end

			LastPlayerPosition = currentPos
		end

		local function shouldSteal(animalData)
			if not animalData or not animalData.worldPosition then return false end

			local hrp = getHRP()
			if not hrp then return false end

			return (hrp.Position - animalData.worldPosition).Magnitude <= AUTO_STEAL_PROX_RADIUS
		end

		local function triggerPrompt(prompt)
			if not prompt or not prompt:IsDescendantOf(workspace) then return end

			prompt.MaxActivationDistance = 9e9
			prompt.RequiresLineOfSight = false
			prompt.ClickablePrompt = true

			local usedFire = pcall(function()
				fireproximityprompt(prompt, 9e9, HOLD_DURATION)
			end)

			if not usedFire then
				pcall(function()
					prompt:InputHoldBegin()
					task.wait(HOLD_DURATION)
					prompt:InputHoldEnd()
				end)
			end

			IsStealing = true
			StealProgress = 0
			StealStartTime = tick()

			task.spawn(function()
				local startTime = tick()
				while tick() - startTime < HOLD_DURATION do
					StealProgress = (tick() - startTime) / HOLD_DURATION
					task.wait(0.05)
				end
				StealProgress = 1
				task.wait(0.4)
				IsStealing = false
				StealProgress = 0
				CurrentStealTarget = nil
			end)
		end

		local function attemptSteal(prompt, animalData)
			if not prompt or not prompt.Parent then return false end
			triggerPrompt(prompt)
			return true
		end

		local function getNearestAnimal()
			local hrp = getHRP()
			if not hrp then return nil end

			local nearest = nil
			local minDist = math.huge

			for _, animalData in ipairs(allAnimalsCache) do
				if isMyBase(animalData.plot) then continue end

				if animalData.worldPosition then
					local dist = (hrp.Position - animalData.worldPosition).Magnitude
					if dist < minDist then
						minDist = dist
						nearest = animalData
					end
				end
			end

			return nearest
		end

		local function autoStealLoop()
			if stealConnection then stealConnection:Disconnect() end
			if velocityConnection then velocityConnection:Disconnect() end

			velocityConnection = RunService.Heartbeat:Connect(updatePlayerVelocity)
			table.insert(stpCleanup, velocityConnection)

			stealConnection = RunService.Heartbeat:Connect(function()
				if not CONFIG.AUTO_STEAL_NEAREST then return end
				if IsStealing then return end

				local targetAnimal = getNearestAnimal()
				if not targetAnimal then return end
				if not shouldSteal(targetAnimal) then return end

				if LastTargetUID ~= targetAnimal.uid then
					LastTargetUID = targetAnimal.uid
				end

				local prompt = PromptMemoryCache[targetAnimal.uid]
				if not prompt or not prompt.Parent then
					prompt = findProximityPromptForAnimal(targetAnimal)
				end

				if prompt then
					attemptSteal(prompt, targetAnimal)
					task.wait(stealCooldown)
				end
			end)
			table.insert(stpCleanup, stealConnection)
		end

		-- ═══════ BUILD THE GUI ═══════
		local sg = Instance.new("ScreenGui")
		sg.Name = "FullSemiTPGui"
		sg.ResetOnSpawn = false
		sg.Parent = CoreGui
		stpGui = sg

		local mf = Instance.new("Frame")
		mf.Name = "MainFrame"
		mf.Size = UDim2.new(0, 155, 0, 155)
		mf.Position = UDim2.new(1, -170, 0.5, -78)
		mf.AnchorPoint = Vector2.new(0, 0.5)
		mf.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		mf.BackgroundTransparency = 0.15
		mf.BorderSizePixel = 0
		mf.Active = true
		mf.ClipsDescendants = false
		mf.Parent = sg
		Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 8)
		addAnimatedStroke(mf, 2)
		restoreGuiPosition("FullSemiTP", mf)

		local padding = Instance.new("UIPadding", mf)
		padding.PaddingTop = UDim.new(0, 7)
		padding.PaddingBottom = UDim.new(0, 7)
		padding.PaddingLeft = UDim.new(0, 8)
		padding.PaddingRight = UDim.new(0, 8)
		local listLayout = Instance.new("UIListLayout", mf)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 5)
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0, 16)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "Full Semi-TP"
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 13
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.LayoutOrder = 0
		titleLabel.Parent = mf

		-- Base Dropdown
		local dropdownOpen = false
		local dropdownBtn = Instance.new("TextButton")
		dropdownBtn.Size = UDim2.new(1, 0, 0, 24)
		dropdownBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		dropdownBtn.BorderSizePixel = 0
		dropdownBtn.Text = "Base: " .. selectedBase .. "  ▼"
		dropdownBtn.Font = Enum.Font.GothamMedium
		dropdownBtn.TextSize = 11
		dropdownBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		dropdownBtn.LayoutOrder = 1
		dropdownBtn.AutoButtonColor = false
		dropdownBtn.Parent = mf
		Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)

		local dropdownFrame = Instance.new("Frame")
		dropdownFrame.Size = UDim2.new(0, 139, 0, 48)
		dropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		dropdownFrame.BorderSizePixel = 0
		dropdownFrame.Visible = false
		dropdownFrame.ZIndex = 10
		dropdownFrame.Parent = sg
		Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 8)
		Instance.new("UIListLayout", dropdownFrame).SortOrder = Enum.SortOrder.LayoutOrder

		for i, baseName in ipairs({"Base 1", "Base 2"}) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, 0, 0, 24)
			optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			optBtn.BorderSizePixel = 0
			optBtn.Text = baseName
			optBtn.Font = Enum.Font.GothamMedium
			optBtn.TextSize = 11
			optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
			optBtn.LayoutOrder = i
			optBtn.AutoButtonColor = false
			optBtn.ZIndex = 10
			optBtn.Parent = dropdownFrame
			Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 8)
			optBtn.MouseEnter:Connect(function() optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end)
			optBtn.MouseLeave:Connect(function() optBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20) end)
			optBtn.MouseButton1Click:Connect(function()
				selectedBase = baseName
				dropdownBtn.Text = "Base: " .. baseName .. "  ▼"
				dropdownFrame.Visible = false
				dropdownOpen = false
				SaveData.selections["FullSemiTP_Base"] = baseName; writeSaveData()
			end)
		end

		dropdownBtn.MouseEnter:Connect(function() dropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25) end)
		dropdownBtn.MouseLeave:Connect(function() dropdownBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15) end)
		dropdownBtn.MouseButton1Click:Connect(function()
			dropdownOpen = not dropdownOpen
			dropdownFrame.Visible = dropdownOpen
			if dropdownOpen then
				local absPos = dropdownBtn.AbsolutePosition
				local absSize = dropdownBtn.AbsoluteSize
				dropdownFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2)
			end
		end)

		-- Desync + Teleport buttons
		local selectedButton = nil
		local function createButton(name, text, order, highlighted)
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = UDim2.new(1, 0, 0, 28)
			btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			btn.BorderSizePixel = 0
			btn.Text = text
			btn.Font = Enum.Font.GothamMedium
			btn.TextSize = 12
			btn.TextColor3 = Color3.fromRGB(220, 220, 220)
			btn.LayoutOrder = order
			btn.AutoButtonColor = false
			btn.Parent = mf
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			if highlighted then
				local stroke = Instance.new("UIStroke", btn)
				stroke.Color = Color3.fromRGB(255, 255, 255)
				stroke.Thickness = 2
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				selectedButton = btn
			end
			btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25) end)
			btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15) end)
			return btn
		end

		local function selectButton(btn)
			if selectedButton then
				local old = selectedButton:FindFirstChildOfClass("UIStroke")
				if old then old:Destroy() end
			end
			local stroke = Instance.new("UIStroke", btn)
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Thickness = 2
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			selectedButton = btn
		end

		local desyncBtn = createButton("DesyncButton", "Desync: OFF", 2, false)
		local teleportBtn = createButton("TeleportButton", "Teleport", 3, true)

		desyncBtn.MouseButton1Click:Connect(function()
			selectButton(desyncBtn)
			desyncActive = not desyncActive
			if desyncActive then
				applyFFlags(FFlags)
				if firstActivation then
					respawn(player)
					firstActivation = false
				end
				desyncBtn.Text = "Desync: ON"
			else
				applyFFlags(defaultFFlags)
				desyncBtn.Text = "Desync: OFF"
			end
		end)

		local teleportRunning = false
		teleportBtn.MouseButton1Click:Connect(function()
			selectButton(teleportBtn)
			if teleportRunning then return end
			teleportRunning = true
			task.delay(0.5, function()
				CONFIG.AUTO_STEAL_NEAREST = true
				task.delay(3, function()
					CONFIG.AUTO_STEAL_NEAREST = false
					teleportBtn.Text = "Teleport"
				end)
			end)
			teleportBtn.Text = "Teleporting..."
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			local backpack = player:WaitForChild("Backpack")

			local carpet = backpack:FindFirstChild("Flying Carpet")
			if not carpet then
				carpet = character:FindFirstChild("Flying Carpet")
			end
			if carpet and carpet.Parent == backpack then
				character:WaitForChild("Humanoid"):EquipTool(carpet)
			end

			local waypoints = BASE_WAYPOINTS[selectedBase]
			for _, wp in ipairs(waypoints) do
				humanoidRootPart.CFrame = CFrame.new(wp.pos)
				task.wait(wp.delay)
			end
			teleportBtn.Text = "Stealing..."
			teleportRunning = false
		end)

		-- Dragging
		local sDragging, sDragStart, sStartPos
		mf.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sDragging = true
				sDragStart = input.Position
				sStartPos = mf.Position
			end
		end)
		table.insert(stpCleanup, UserInputService.InputChanged:Connect(function(input)
			if sDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - sDragStart
				mf.Position = UDim2.new(sStartPos.X.Scale, sStartPos.X.Offset + delta.X, sStartPos.Y.Scale, sStartPos.Y.Offset + delta.Y)
			end
		end))
		table.insert(stpCleanup, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sDragging = false
			end
		end))

		-- Start the scanner and auto-steal loop
		task.spawn(initializeScanner)
		autoStealLoop()
	end

	createTPToggle("Full Semi-TP", 1, function(en) if en then createSTP() else destroySTP() end end)

	--------------------------------------------------------------
	-- FULL TP (wrapped)
	--------------------------------------------------------------
	do
		local ftpGui = nil
		local ftpCleanup = {}
		local ftpFlagsApplied = false

		local function destroyFullTP()
			if CoreGui:FindFirstChild("InstantStealGui") then
				CoreGui["InstantStealGui"]:Destroy()
			end
			unregisterGuiPosition("FullTP")
			for _, c in ipairs(ftpCleanup) do
				if c and typeof(c) == "RBXScriptConnection" and c.Connected then
					c:Disconnect()
				end
			end
			ftpCleanup = {}
			ftpGui = nil
		end

		local function createFullTP()
			destroyFullTP()

			-- ========== REMOTE MAPPER ==========
			local HOLD_LABEL = "f40f7d9e-2f0d-4167-b250-899273f46874"
			local DELIVER_LABEL = "3ba148c9-7ed6-4675-93f8-9f7c356a2c54"

			local RemoteIndex, RemoteObjects = {}, {}
			local netChildren = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):GetChildren()

			for i, obj in ipairs(netChildren) do
				if obj:IsA("RemoteEvent") then
					local nextObj = netChildren[i + 1]
					if nextObj then
						RemoteIndex[obj.Name] = i + 1
						RemoteObjects[i + 1] = nextObj
					end
				end
			end

			local holdIndex = RemoteIndex["RE/" .. HOLD_LABEL]
			local deliverIndex = RemoteIndex["RE/" .. DELIVER_LABEL]
			local AutoStealHoldRemote = holdIndex and RemoteObjects[holdIndex] or nil
			local AutoStealDeliverRemote = deliverIndex and RemoteObjects[deliverIndex] or nil

			-- ========== HELPERS ==========
			local function findMyPlot()
				local plots = Workspace:FindFirstChild("Plots")
				if not plots then return nil, nil end
				for _, plot in pairs(plots:GetChildren()) do
					if plot:IsA("Model") then
						local sign = plot:FindFirstChild("PlotSign")
						if sign then
							local yourBase = sign:FindFirstChild("YourBase")
							if yourBase and yourBase:IsA("BillboardGui") and yourBase.Enabled then
								return plot.Name, plot
							end
						end
					end
				end
				return nil, nil
			end

			local function getPodiumFromPrompt(prompt)
				local current = prompt.Parent
				while current and current ~= Workspace do
					if current:IsA("Model") and current:FindFirstChild("Base") then
						return current
					end
					current = current.Parent
				end
				return nil
			end

			-- ========== INSTANT STEAL ==========
			local function executeSteal(targetPodium)
				local char = player.Character
				if not char then return end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then return end

				local myPlotName, myPlot = findMyPlot()
				if not myPlot then return end

				local structureBase = myPlot:FindFirstChild("DeliveryHitbox")
				if not structureBase then return end

				local holdPosition
				if targetPodium == "10" then
					holdPosition = structureBase.Position + Vector3.new(7.688, -6.029, -94.500)
				elseif targetPodium == "1" then
					holdPosition = structureBase.Position + Vector3.new(8.126, -5.213, 92.923)
				else
					return
				end

				local closestPrompt, closestDistance, closestPodium = nil, math.huge, nil

				for _, prompt in pairs(Workspace:GetDescendants()) do
					if prompt:IsA("ProximityPrompt") then
						local podiumModel = getPodiumFromPrompt(prompt)
						if podiumModel and podiumModel.Name == targetPodium then
							local base = podiumModel:FindFirstChild("Base")
							if base and base:FindFirstChild("Spawn") then
								local distance = (holdPosition - base.Spawn.Position).Magnitude
								if distance < closestDistance then
									closestDistance = distance
									closestPrompt = prompt
									closestPodium = podiumModel
								end
							end
						end
					end
				end

				if not closestPrompt or not closestPodium then return end

				local carpet = char:FindFirstChild("Flying Carpet") or player.Backpack:FindFirstChild("Flying Carpet")
				if carpet then carpet.Parent = char end

				root.CFrame = CFrame.new(holdPosition)
				task.wait(0.15)

				local orig = {
					los = closestPrompt.RequiresLineOfSight,
					dist = closestPrompt.MaxActivationDistance,
					enabled = closestPrompt.Enabled,
					hold = closestPrompt.HoldDuration
				}

				closestPrompt.RequiresLineOfSight = false
				closestPrompt.MaxActivationDistance = math.huge
				closestPrompt.Enabled = true
				closestPrompt.HoldDuration = 0

				pcall(function()
					for _, conn in pairs(getconnections(closestPrompt.Triggered)) do
						conn:Fire()
					end
				end)

				if targetPodium == "10" then
					root.CFrame = CFrame.new(structureBase.Position + Vector3.new(-28.303, -5.756, -41.164))
					task.wait(0.1)
					root.CFrame = CFrame.new(structureBase.Position + Vector3.new(8.211, -3.037, -83.243))
				elseif targetPodium == "1" then
					root.CFrame = CFrame.new(structureBase.Position + Vector3.new(-25.251, -6.129, -24.699))
					task.wait(0.1)
					root.CFrame = CFrame.new(structureBase.Position + Vector3.new(8.136, -4.389, -131.669))
				end

				closestPrompt.RequiresLineOfSight = orig.los
				closestPrompt.MaxActivationDistance = orig.dist
				closestPrompt.Enabled = orig.enabled
				closestPrompt.HoldDuration = orig.hold
			end

			-- ========== APPLY FFLAGS ==========
			if not ftpFlagsApplied then
				local ftpFlags = {
					{"GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000"},
					{"LargeReplicatorWrite5", "true"},
					{"LargeReplicatorEnabled9", "true"},
					{"AngularVelociryLimit", "360"},
					{"TimestepArbiterVelocityCriteriaThresholdTwoDt", "2147483646"},
					{"S2PhysicsSenderRate", "15000"},
					{"DisableDPIScale", "true"},
					{"MaxDataPacketPerSend", "2147483647"},
					{"ServerMaxBandwith", "52"},
					{"PhysicsSenderMaxBandwidthBps", "20000"},
					{"MaxTimestepMultiplierBuoyancy", "2147483647"},
					{"SimOwnedNOUCountThresholdMillionth", "2147483647"},
					{"MaxMissedWorldStepsRemembered", "-2147483648"},
					{"CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth", "1"},
					{"StreamJobNOUVolumeLengthCap", "2147483647"},
					{"DebugSendDistInSteps", "-2147483648"},
					{"MaxTimestepMultiplierAcceleration", "2147483647"},
					{"LargeReplicatorRead5", "true"},
					{"SimExplicitlyCappedTimestepMultiplier", "2147483646"},
					{"GameNetDontSendRedundantNumTimes", "1"},
					{"CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent", "1"},
					{"CheckPVCachedRotVelThresholdPercent", "10"},
					{"LargeReplicatorSerializeRead3", "true"},
					{"ReplicationFocusNouExtentsSizeCutoffForPauseStuds", "2147483647"},
					{"NextGenReplicatorEnabledWrite4", "true"},
					{"CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth", "1"},
					{"GameNetDontSendRedundantDeltaPositionMillionth", "1"},
					{"InterpolationFrameVelocityThresholdMillionth", "5"},
					{"StreamJobNOUVolumeCap", "2147483647"},
					{"InterpolationFrameRotVelocityThresholdMillionth", "5"},
					{"WorldStepMax", "30"},
					{"TimestepArbiterHumanoidLinearVelThreshold", "1"},
					{"InterpolationFramePositionThresholdMillionth", "5"},
					{"TimestepArbiterHumanoidTurningVelThreshold", "1"},
					{"MaxTimestepMultiplierContstraint", "2147483647"},
					{"GameNetPVHeaderLinearVelocityZeroCutoffExponent", "-5000"},
					{"CheckPVCachedVelThresholdPercent", "10"},
					{"TimestepArbiterOmegaThou", "1073741823"},
					{"MaxAcceptableUpdateDelay", "1"},
					{"LargeReplicatorSerializeWrite4", "true"},
				}

				for _, data in ipairs(ftpFlags) do
					pcall(function()
						if setfflag then
							setfflag(data[1], data[2])
						end
					end)
				end

				-- Respawn character for desync effect
				local char = player.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then hum:ChangeState(Enum.HumanoidStateType.Dead) end
					char:ClearAllChildren()
					local f = Instance.new("Model", Workspace)
					player.Character = f
					task.wait()
					player.Character = char
					f:Destroy()
				end

				ftpFlagsApplied = true
			end

			-- ========== GUI ==========
			local gui = Instance.new("ScreenGui")
			gui.Name = "InstantStealGui"
			gui.ResetOnSpawn = false
			gui.Parent = CoreGui
			ftpGui = gui

			local main = Instance.new("Frame")
			main.Size = UDim2.new(0, 150, 0, 105)
			main.Position = UDim2.new(1, -165, 0.5, -52)
			main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			main.BackgroundTransparency = 0.05
			main.BorderSizePixel = 0
			main.ClipsDescendants = false
			main.Active = true
			main.Parent = gui
			Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
			addAnimatedStroke(main, 2)
			restoreGuiPosition("FullTP", main)

			-- Title
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, 0, 0, 28)
			title.BackgroundTransparency = 1
			title.Text = "Full TP"
			title.TextColor3 = Color3.fromRGB(255, 255, 255)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 13
			title.Parent = main

			-- Dropdown
			local selectedPodium = SaveData.selections and SaveData.selections["FullTP_Podium"] or nil
			local ddOpen = false

			local ddBtn = Instance.new("TextButton")
			ddBtn.Size = UDim2.new(0, 130, 0, 26)
			ddBtn.Position = UDim2.new(0.5, -65, 0, 30)
			ddBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			ddBtn.BorderSizePixel = 0
			ddBtn.Text = ""
			ddBtn.AutoButtonColor = false
			ddBtn.Parent = main
			Instance.new("UICorner", ddBtn).CornerRadius = UDim.new(0, 5)

			local ddLabel = Instance.new("TextLabel")
			ddLabel.Size = UDim2.new(1, -24, 1, 0)
			ddLabel.Position = UDim2.new(0, 8, 0, 0)
			ddLabel.BackgroundTransparency = 1
			ddLabel.Text = selectedPodium == "1" and "Base 1" or (selectedPodium == "10" and "Base 2" or "Select Podium")
			ddLabel.TextColor3 = selectedPodium and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
			ddLabel.Font = Enum.Font.GothamMedium
			ddLabel.TextSize = 11
			ddLabel.TextXAlignment = Enum.TextXAlignment.Left
			ddLabel.Parent = ddBtn

			local ddArrow = Instance.new("TextLabel")
			ddArrow.Size = UDim2.new(0, 20, 1, 0)
			ddArrow.Position = UDim2.new(1, -22, 0, 0)
			ddArrow.BackgroundTransparency = 1
			ddArrow.Text = "▼"
			ddArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
			ddArrow.Font = Enum.Font.GothamBold
			ddArrow.TextSize = 9
			ddArrow.Parent = ddBtn

			-- Dropdown list
			local ddList = Instance.new("Frame")
			ddList.Size = UDim2.new(0, 130, 0, 0)
			ddList.Position = UDim2.new(0.5, -65, 0, 58)
			ddList.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			ddList.BorderSizePixel = 0
			ddList.ClipsDescendants = true
			ddList.ZIndex = 10
			ddList.Parent = main
			Instance.new("UICorner", ddList).CornerRadius = UDim.new(0, 5)

			local options = {
				{text = "Base 1", value = "1"},
				{text = "Base 2", value = "10"}
			}

			for i, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, -6, 0, 24)
				optBtn.Position = UDim2.new(0, 3, 0, 3 + (i-1) * 26)
				optBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				optBtn.BorderSizePixel = 0
				optBtn.Text = opt.text
				optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
				optBtn.Font = Enum.Font.GothamMedium
				optBtn.TextSize = 11
				optBtn.ZIndex = 11
				optBtn.AutoButtonColor = false
				optBtn.Parent = ddList
				Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

				optBtn.MouseEnter:Connect(function()
					TweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}):Play()
				end)
				optBtn.MouseLeave:Connect(function()
					TweenService:Create(optBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
				end)
				optBtn.MouseButton1Click:Connect(function()
					selectedPodium = opt.value
					ddLabel.Text = opt.text
					ddLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					ddOpen = false
					TweenService:Create(ddList, TweenInfo.new(0.15), {Size = UDim2.new(0, 130, 0, 0)}):Play()
					TweenService:Create(ddArrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
					SaveData.selections["FullTP_Podium"] = opt.value; writeSaveData()
				end)
			end

			ddBtn.MouseButton1Click:Connect(function()
				ddOpen = not ddOpen
				local targetSize = ddOpen and UDim2.new(0, 130, 0, 56) or UDim2.new(0, 130, 0, 0)
				local targetRot = ddOpen and 180 or 0
				TweenService:Create(ddList, TweenInfo.new(0.15), {Size = targetSize}):Play()
				TweenService:Create(ddArrow, TweenInfo.new(0.15), {Rotation = targetRot}):Play()
			end)

			-- Execute button
			local execBtn = Instance.new("TextButton")
			execBtn.Size = UDim2.new(0, 130, 0, 28)
			execBtn.Position = UDim2.new(0.5, -65, 0, 64)
			execBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
			execBtn.BorderSizePixel = 0
			execBtn.Text = "STEAL"
			execBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			execBtn.Font = Enum.Font.GothamBold
			execBtn.TextSize = 12
			execBtn.AutoButtonColor = false
			execBtn.Parent = main
			Instance.new("UICorner", execBtn).CornerRadius = UDim.new(0, 5)

			execBtn.MouseEnter:Connect(function()
				TweenService:Create(execBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end)
			execBtn.MouseLeave:Connect(function()
				TweenService:Create(execBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)}):Play()
			end)

			execBtn.MouseButton1Click:Connect(function()
				if not selectedPodium then
					ddBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
					task.wait(0.15)
					ddBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					return
				end
				execBtn.Text = "..."
				task.spawn(function() executeSteal(selectedPodium) end)
				task.wait(0.3)
				execBtn.Text = "STEAL"
			end)

			-- Dragging
			local ftpDragging, ftpDragStart, ftpStartPos
			main.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					ftpDragging = true
					ftpDragStart = input.Position
					ftpStartPos = main.Position
				end
			end)
			table.insert(ftpCleanup, UserInputService.InputChanged:Connect(function(input)
				if ftpDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local delta = input.Position - ftpDragStart
					main.Position = UDim2.new(ftpStartPos.X.Scale, ftpStartPos.X.Offset + delta.X, ftpStartPos.Y.Scale, ftpStartPos.Y.Offset + delta.Y)
				end
			end))
			table.insert(ftpCleanup, UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					ftpDragging = false
				end
			end))
		end

		createTPToggle("Full TP", 2, function(en) if en then createFullTP() else destroyFullTP() end end)
	end

	--------------------------------------------------------------
	-- TP SCAM (wrapped)
	--------------------------------------------------------------
	do
		local tpScamGui = nil
		local tpScamCleanup = {}
		local tpScamStealConn = nil
		local tpScamVelConn = nil

		local function destroyTPScam()
			if CoreGui:FindFirstChild("SukiTP_Dashboard") then
				CoreGui["SukiTP_Dashboard"]:Destroy()
			end
			unregisterGuiPosition("TPScam")
			if tpScamStealConn then tpScamStealConn:Disconnect(); tpScamStealConn = nil end
			if tpScamVelConn then tpScamVelConn:Disconnect(); tpScamVelConn = nil end
			for _, c in ipairs(tpScamCleanup) do
				if c and typeof(c) == "RBXScriptConnection" and c.Connected then
					c:Disconnect()
				end
			end
			tpScamCleanup = {}
			tpScamGui = nil
		end

		local function createTPScam()
			destroyTPScam()

			local HttpService = game:GetService("HttpService")

			-- ========== AUTO-STEAL CONFIG & STATE ==========
			local TS_CONFIG = { AUTO_STEAL_NEAREST = false }
			local TS_AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))

			local tsAllAnimals = {}
			local tsPromptCache = {}
			local tsLastTargetUID = nil
			local tsLastPlayerPos = nil
			local tsPlayerVelocity = Vector3.zero

			local TS_PROX_RADIUS = 100
			local tsIsStealing = false
			local tsStealProgress = 0
			local tsStealStartTime = 0

			local tsStealCooldown = 0.1
			local TS_HOLD_DURATION = 0.25

			local SAVE_FILE = "SukiTP_Waypoints.json"

			-- ========== WAYPOINT SAVE / LOAD ==========
			local function saveWaypointsToFile(waypointsList)
				local data = {}
				for _, wp in ipairs(waypointsList) do
					table.insert(data, { name = wp.name, x = wp.cframe.X, y = wp.cframe.Y, z = wp.cframe.Z })
				end
				pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(data)) end)
			end

			local function loadWaypointsFromFile()
				local success, content = pcall(function() return readfile(SAVE_FILE) end)
				if not success or not content then return {} end
				local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
				if not ok or type(data) ~= "table" then return {} end
				return data
			end

			-- ========== AUTO-STEAL CORE ==========
			local function tsGetHRP()
				local char = player.Character
				if not char then return nil end
				return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
			end

			local function tsIsMyBase(plotName)
				local plot = Workspace.Plots:FindFirstChild(plotName)
				if not plot then return false end
				local sign = plot:FindFirstChild("PlotSign")
				if sign then
					local yb = sign:FindFirstChild("YourBase")
					if yb and yb:IsA("BillboardGui") then return yb.Enabled == true end
				end
				return false
			end

			local function tsScanPlot(plot)
				if not plot or not plot:IsA("Model") then return end
				if tsIsMyBase(plot.Name) then return end
				local podiums = plot:FindFirstChild("AnimalPodiums")
				if not podiums then return end
				for _, podium in ipairs(podiums:GetChildren()) do
					if podium:IsA("Model") and podium:FindFirstChild("Base") then
						local animalName = "Unknown"
						local spawn = podium.Base:FindFirstChild("Spawn")
						if spawn then
							for _, child in ipairs(spawn:GetChildren()) do
								if child:IsA("Model") and child.Name ~= "PromptAttachment" then
									animalName = child.Name
									local info = TS_AnimalsData[animalName]
									if info and info.DisplayName then animalName = info.DisplayName end
									break
								end
							end
						end
						table.insert(tsAllAnimals, {
							name = animalName, plot = plot.Name, slot = podium.Name,
							worldPosition = podium:GetPivot().Position, uid = plot.Name .. "_" .. podium.Name,
						})
					end
				end
			end

			local function tsInitScanner()
				task.wait(2)
				local plots = Workspace:WaitForChild("Plots", 10)
				if not plots then return end
				for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then tsScanPlot(plot) end end
				table.insert(tpScamCleanup, plots.ChildAdded:Connect(function(plot) if plot:IsA("Model") then task.wait(0.5); tsScanPlot(plot) end end))
				task.spawn(function() while tpScamGui and tpScamGui.Parent do task.wait(5); tsAllAnimals = {}; for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then tsScanPlot(plot) end end end end)
			end

			local function tsFindPrompt(ad)
				if not ad then return nil end
				local cached = tsPromptCache[ad.uid]; if cached and cached.Parent then return cached end
				local plot = Workspace.Plots:FindFirstChild(ad.plot); if not plot then return nil end
				local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end
				local pod = pods:FindFirstChild(ad.slot); if not pod then return nil end
				local base = pod:FindFirstChild("Base"); if not base then return nil end
				local spawn = base:FindFirstChild("Spawn"); if not spawn then return nil end
				local att = spawn:FindFirstChild("PromptAttachment"); if not att then return nil end
				for _, p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") then tsPromptCache[ad.uid] = p; return p end end
				return nil
			end

			local function tsTriggerPrompt(prompt)
				if not prompt or not prompt:IsDescendantOf(Workspace) then return end
				prompt.MaxActivationDistance = 9e9; prompt.RequiresLineOfSight = false; prompt.ClickablePrompt = true
				local used = pcall(function() fireproximityprompt(prompt, 9e9, TS_HOLD_DURATION) end)
				if not used then pcall(function() prompt:InputHoldBegin(); task.wait(TS_HOLD_DURATION); prompt:InputHoldEnd() end) end
				tsIsStealing = true; tsStealProgress = 0; tsStealStartTime = tick()
				task.spawn(function()
					local st = tick(); while tick() - st < TS_HOLD_DURATION do tsStealProgress = (tick() - st) / TS_HOLD_DURATION; task.wait(0.05) end
					tsStealProgress = 1; task.wait(0.4); tsIsStealing = false; tsStealProgress = 0
				end)
			end

			local function tsGetNearest()
				local hrp = tsGetHRP(); if not hrp then return nil end
				local nearest, minD = nil, math.huge
				for _, ad in ipairs(tsAllAnimals) do
					if not tsIsMyBase(ad.plot) and ad.worldPosition then
						local d = (hrp.Position - ad.worldPosition).Magnitude
						if d < minD then minD = d; nearest = ad end
					end
				end
				return nearest
			end

			local function tsAutoStealLoop()
				if tpScamStealConn then tpScamStealConn:Disconnect() end
				if tpScamVelConn then tpScamVelConn:Disconnect() end
				tpScamVelConn = RunService.Heartbeat:Connect(function()
					local hrp = tsGetHRP(); if not hrp then return end
					local cur = hrp.Position
					if tsLastPlayerPos then tsPlayerVelocity = (cur - tsLastPlayerPos) / task.wait() end
					tsLastPlayerPos = cur
				end)
				table.insert(tpScamCleanup, tpScamVelConn)
				tpScamStealConn = RunService.Heartbeat:Connect(function()
					if not TS_CONFIG.AUTO_STEAL_NEAREST or tsIsStealing then return end
					local target = tsGetNearest(); if not target then return end
					local hrp = tsGetHRP(); if not hrp then return end
					if (hrp.Position - target.worldPosition).Magnitude > TS_PROX_RADIUS then return end
					if tsLastTargetUID ~= target.uid then tsLastTargetUID = target.uid end
					local prompt = tsPromptCache[target.uid]; if not prompt or not prompt.Parent then prompt = tsFindPrompt(target) end
					if prompt then tsTriggerPrompt(prompt); task.wait(tsStealCooldown) end
				end)
				table.insert(tpScamCleanup, tpScamStealConn)
			end

			-- ========== COLORS ==========
			local COL = {
				panelBg = Color3.fromRGB(10, 10, 10), topBar = Color3.fromRGB(20, 20, 20),
				listBg = Color3.fromRGB(15, 15, 15), btnLight = Color3.fromRGB(220, 220, 220),
				btnMid = Color3.fromRGB(160, 160, 160), btnDark = Color3.fromRGB(80, 80, 80),
				white = Color3.fromRGB(255, 255, 255), dimText = Color3.fromRGB(120, 120, 120),
			}

			-- ========== GUI ==========
			local sg = Instance.new("ScreenGui")
			sg.Name = "SukiTP_Dashboard"; sg.ResetOnSpawn = false
			sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = CoreGui
			tpScamGui = sg

			local mf = Instance.new("Frame")
			mf.Name = "MainFrame"; mf.Size = UDim2.new(0, 240, 0, 228)
			mf.Position = UDim2.new(0.5, -120, 0.5, -114)
			mf.BackgroundColor3 = COL.panelBg; mf.BackgroundTransparency = 0.05
			mf.BorderSizePixel = 0; mf.Active = true; mf.Parent = sg
			Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 8)
			addAnimatedStroke(mf, 2)
			restoreGuiPosition("TPScam", mf)

			-- Top bar
			local tb = Instance.new("Frame")
			tb.Name = "TopBar"; tb.Size = UDim2.new(1, 0, 0, 38)
			tb.BackgroundColor3 = COL.topBar; tb.BorderSizePixel = 0; tb.Parent = mf
			Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
			local tbMask = Instance.new("Frame"); tbMask.Size = UDim2.new(1, 0, 0, 14)
			tbMask.Position = UDim2.new(0, 0, 1, -14); tbMask.BackgroundColor3 = COL.topBar
			tbMask.BorderSizePixel = 0; tbMask.Parent = tb

			local BTN_W, BTN_H, BTN_R, BTN_Y = 32, 26, 5, 6

			-- "+" save waypoint button
			local btnPlus = Instance.new("TextButton")
			btnPlus.Size = UDim2.new(0, BTN_W, 0, BTN_H); btnPlus.Position = UDim2.new(0, 7, 0, BTN_Y)
			btnPlus.BackgroundColor3 = COL.btnLight; btnPlus.BorderSizePixel = 0
			btnPlus.Text = "+"; btnPlus.TextColor3 = Color3.fromRGB(0, 0, 0)
			btnPlus.Font = Enum.Font.GothamBold; btnPlus.TextSize = 20; btnPlus.AutoButtonColor = false; btnPlus.Parent = tb
			Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, BTN_R)

			-- "TP" teleport button
			local btnTPScam = Instance.new("TextButton")
			btnTPScam.Size = UDim2.new(0, BTN_W, 0, BTN_H); btnTPScam.Position = UDim2.new(0, 44, 0, BTN_Y)
			btnTPScam.BackgroundColor3 = COL.btnMid; btnTPScam.BorderSizePixel = 0
			btnTPScam.Text = "TP"; btnTPScam.TextColor3 = Color3.fromRGB(0, 0, 0)
			btnTPScam.Font = Enum.Font.GothamBold; btnTPScam.TextSize = 12; btnTPScam.AutoButtonColor = false; btnTPScam.Parent = tb
			Instance.new("UICorner", btnTPScam).CornerRadius = UDim.new(0, BTN_R)

			-- Title
			local titleLbl = Instance.new("TextLabel")
			titleLbl.Size = UDim2.new(0, 80, 1, 0); titleLbl.Position = UDim2.new(0, 80, 0, 0)
			titleLbl.BackgroundTransparency = 1; titleLbl.Text = "TP SCAM"
			titleLbl.TextColor3 = COL.white; titleLbl.Font = Enum.Font.GothamBold
			titleLbl.TextSize = 15; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = tb

			-- "AS" auto-steal toggle button
			local btnASToggle = Instance.new("TextButton")
			btnASToggle.Size = UDim2.new(0, BTN_W, 0, BTN_H); btnASToggle.Position = UDim2.new(1, -74, 0, BTN_Y)
			btnASToggle.BackgroundColor3 = COL.btnLight; btnASToggle.BorderSizePixel = 0
			btnASToggle.Text = "AS"; btnASToggle.TextColor3 = Color3.fromRGB(0, 0, 0)
			btnASToggle.Font = Enum.Font.GothamBold; btnASToggle.TextSize = 12; btnASToggle.AutoButtonColor = false; btnASToggle.Parent = tb
			Instance.new("UICorner", btnASToggle).CornerRadius = UDim.new(0, BTN_R)

			-- "X" minimize button
			local btnMin = Instance.new("TextButton")
			btnMin.Size = UDim2.new(0, BTN_W, 0, BTN_H); btnMin.Position = UDim2.new(1, -38, 0, BTN_Y)
			btnMin.BackgroundColor3 = COL.btnDark; btnMin.BorderSizePixel = 0
			btnMin.Text = "─"; btnMin.TextColor3 = COL.white
			btnMin.Font = Enum.Font.GothamBold; btnMin.TextSize = 14; btnMin.AutoButtonColor = false; btnMin.Parent = tb
			Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, BTN_R)

			-- Hover effects
			for _, btn in ipairs({btnPlus, btnTPScam, btnASToggle}) do
				local orig = btn.BackgroundColor3
				btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
				btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = orig}):Play() end)
			end
			btnMin.MouseEnter:Connect(function() TweenService:Create(btnMin, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}):Play() end)
			btnMin.MouseLeave:Connect(function() TweenService:Create(btnMin, TweenInfo.new(0.1), {BackgroundColor3 = COL.btnDark}):Play() end)

			-- Info label
			local infoLbl = Instance.new("TextLabel")
			infoLbl.Size = UDim2.new(1, -16, 0, 20); infoLbl.Position = UDim2.new(0, 8, 0, 42)
			infoLbl.BackgroundTransparency = 1; infoLbl.Text = "P or + to Add | F or TP to Teleport | AS to Steal"
			infoLbl.TextColor3 = COL.dimText; infoLbl.Font = Enum.Font.GothamBold; infoLbl.TextSize = 9
			infoLbl.TextXAlignment = Enum.TextXAlignment.Center; infoLbl.Parent = mf

			-- Scroll list area
			local listArea = Instance.new("Frame")
			listArea.Size = UDim2.new(1, -20, 1, -74); listArea.Position = UDim2.new(0, 10, 0, 66)
			listArea.BackgroundColor3 = COL.listBg; listArea.BorderSizePixel = 0
			listArea.ClipsDescendants = true; listArea.Parent = mf
			Instance.new("UICorner", listArea).CornerRadius = UDim.new(0, 8)

			local scrollFrame = Instance.new("ScrollingFrame")
			scrollFrame.Size = UDim2.new(1, 0, 1, 0); scrollFrame.BackgroundTransparency = 1
			scrollFrame.BorderSizePixel = 0; scrollFrame.ScrollBarThickness = 4
			scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; scrollFrame.Parent = listArea
			Instance.new("UIListLayout", scrollFrame).Padding = UDim.new(0, 4)
			scrollFrame:FindFirstChildOfClass("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder
			local sfPad = Instance.new("UIPadding", scrollFrame)
			sfPad.PaddingTop = UDim.new(0, 4); sfPad.PaddingBottom = UDim.new(0, 4)
			sfPad.PaddingLeft = UDim.new(0, 4); sfPad.PaddingRight = UDim.new(0, 4)

			-- Dragging
			local tsDrag, tsDragStart, tsStartPos
			tb.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					tsDrag = true; tsDragStart = input.Position; tsStartPos = mf.Position
				end
			end)
			tb.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then tsDrag = false end
			end)
			table.insert(tpScamCleanup, UserInputService.InputChanged:Connect(function(input)
				if tsDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local delta = input.Position - tsDragStart
					mf.Position = UDim2.new(tsStartPos.X.Scale, tsStartPos.X.Offset + delta.X, tsStartPos.Y.Scale, tsStartPos.Y.Offset + delta.Y)
				end
			end))

			-- Minimize
			local tsMinimized = false
			btnMin.MouseButton1Click:Connect(function()
				tsMinimized = not tsMinimized
				if tsMinimized then
					mf.Size = UDim2.new(0, 240, 0, 38); btnMin.Text = "+"
				else
					mf.Size = UDim2.new(0, 240, 0, 228); btnMin.Text = "─"
				end
			end)

			-- ========== WAYPOINT SYSTEM ==========
			local tsWaypoints = {}

			local function tsCreateEntry(name, pos)
				local coordText = string.format("%.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z)
				local entry = Instance.new("Frame")
				entry.Size = UDim2.new(1, 0, 0, 30); entry.BackgroundColor3 = COL.topBar
				entry.BorderSizePixel = 0; entry.Parent = scrollFrame
				Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)
				local nameLbl = Instance.new("TextLabel")
				nameLbl.Size = UDim2.new(0, 70, 1, 0); nameLbl.Position = UDim2.new(0, 8, 0, 0)
				nameLbl.BackgroundTransparency = 1; nameLbl.Text = name; nameLbl.TextColor3 = COL.white
				nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
				nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Parent = entry
				local coordLbl = Instance.new("TextLabel")
				coordLbl.Size = UDim2.new(1, -110, 1, 0); coordLbl.Position = UDim2.new(0, 70, 0, 0)
				coordLbl.BackgroundTransparency = 1; coordLbl.Text = coordText; coordLbl.TextColor3 = COL.dimText
				coordLbl.Font = Enum.Font.Gotham; coordLbl.TextSize = 10
				coordLbl.TextXAlignment = Enum.TextXAlignment.Left; coordLbl.TextTruncate = Enum.TextTruncate.AtEnd; coordLbl.Parent = entry
				local delBtn = Instance.new("TextButton")
				delBtn.Size = UDim2.new(0, 22, 0, 20); delBtn.Position = UDim2.new(1, -28, 0.5, -10)
				delBtn.BackgroundColor3 = COL.btnDark; delBtn.BorderSizePixel = 0
				delBtn.Text = "X"; delBtn.TextColor3 = COL.white; delBtn.Font = Enum.Font.GothamBold
				delBtn.TextSize = 11; delBtn.AutoButtonColor = false; delBtn.Parent = entry
				Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
				delBtn.MouseEnter:Connect(function() TweenService:Create(delBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}):Play() end)
				delBtn.MouseLeave:Connect(function() TweenService:Create(delBtn, TweenInfo.new(0.1), {BackgroundColor3 = COL.btnDark}):Play() end)
				return entry, delBtn
			end

			local function tsRemoveWaypoint(index)
				if tsWaypoints[index] then tsWaypoints[index].entry:Destroy(); table.remove(tsWaypoints, index); saveWaypointsToFile(tsWaypoints) end
			end

			local function tsAddWaypoint(name, cframe)
				local entry, delBtn = tsCreateEntry(name, cframe.Position)
				local wp = { name = name, cframe = cframe, entry = entry }
				table.insert(tsWaypoints, wp)
				delBtn.MouseButton1Click:Connect(function() for i, w in ipairs(tsWaypoints) do if w == wp then tsRemoveWaypoint(i); break end end end)
				return wp
			end

			local function tsSavePosition()
				if #tsWaypoints >= 2 then return end
				local char = player.Character; if not char then return end
				local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
				tsAddWaypoint("WP " .. (#tsWaypoints + 1), root.CFrame)
				saveWaypointsToFile(tsWaypoints)
			end

			local function tsEquipCarpet()
				local char = player.Character; if not char then return false end
				local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
				for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.Name == "Flying Carpet" then return true end end
				local bp = player:FindFirstChild("Backpack"); if not bp then return false end
				for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name == "Flying Carpet" then hum:EquipTool(t); return true end end
				return false
			end

			local function tsTeleportNext()
				if #tsWaypoints == 0 then return end
				local char = player.Character; if not char then return end
				local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
				tsEquipCarpet(); task.wait(0.2)
				root.CFrame = tsWaypoints[1].cframe
				if #tsWaypoints >= 2 then
					task.delay(0.1, function()
						local c = player.Character; if not c then return end
						local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
						r.CFrame = tsWaypoints[2].cframe
					end)
				end
			end

			-- Load saved waypoints
			local saved = loadWaypointsFromFile()
			for _, wpData in ipairs(saved) do
				if #tsWaypoints >= 2 then break end
				tsAddWaypoint(wpData.name or ("WP " .. (#tsWaypoints + 1)), CFrame.new(wpData.x, wpData.y, wpData.z))
			end

			-- Button connections
			btnPlus.MouseButton1Click:Connect(tsSavePosition)
			btnTPScam.MouseButton1Click:Connect(tsTeleportNext)
			btnASToggle.MouseButton1Click:Connect(function()
				TS_CONFIG.AUTO_STEAL_NEAREST = not TS_CONFIG.AUTO_STEAL_NEAREST
				if TS_CONFIG.AUTO_STEAL_NEAREST then
					btnASToggle.BackgroundColor3 = COL.white; btnASToggle.Text = "ON"
				else
					btnASToggle.BackgroundColor3 = COL.btnLight; btnASToggle.Text = "AS"
				end
			end)

			-- Keyboard shortcuts
			table.insert(tpScamCleanup, UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.KeyCode == Enum.KeyCode.P then tsSavePosition()
				elseif input.KeyCode == Enum.KeyCode.F then tsTeleportNext() end
			end))

			-- Start auto-steal systems
			task.spawn(tsInitScanner)
			tsAutoStealLoop()
		end

		createTPToggle("TP Scam", 3, function(en) if en then createTPScam() else destroyTPScam() end end)
	end
end

--------------------------------------------------------------
-- SETTINGS PAGE (wrapped)
--------------------------------------------------------------
do
	local settingsPage = create("Frame", {Name = "Page_Settings", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = contentArea})
	pageFrames["Settings"] = settingsPage

	local SONGS = {{name = "Charlie kirk remix", id = "rbxassetid://77582495618566"},{name = "Brazilian Phonk", id = "rbxassetid://95197852052116"},{name = "Low Cortisol", id = "rbxassetid://110919391228823"},{name = "Russian LARP", id = "rbxassetid://70482066067268"},{name = "Larp", id = "rbxassetid://96086520089708"},{name = "Cool Rave", id = "rbxassetid://115343112094045"},{name = "Epste1n", id = "rbxassetid://101813524933119"}}
	local currentSound, ddOpen = nil, false

	local songSection = create("Frame", {Name = "SongSection", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = settingsPage})
	create("TextLabel", {Name = "SongLabel", Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(0, 50, 1, 0), BackgroundTransparency = 1, Text = "Song", TextSize = 10, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(160, 160, 160), TextXAlignment = Enum.TextXAlignment.Left, Parent = songSection})
	local ddBtn = create("TextButton", {Name = "DropdownBtn", Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -54, 1, 0), BackgroundColor3 = Color3.fromRGB(10, 10, 10), BackgroundTransparency = 0.25, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = songSection}, {create("UICorner", {CornerRadius = UDim.new(0, 5)}), create("UIStroke", {Color = Color3.fromRGB(40, 40, 40), Thickness = 1})})
	local ddText = create("TextLabel", {Name = "SelectedText", Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1, Text = "None", TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(200, 200, 200), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11, Parent = ddBtn})
	local ddArrow = create("TextLabel", {Name = "Arrow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Text = "▼", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(120, 120, 120), ZIndex = 11, Parent = ddBtn})
	local ddList = create("ScrollingFrame", {Name = "DropdownList", Position = UDim2.new(0, 50, 0, 27), Size = UDim2.new(1, -54, 0, 90), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80), BackgroundColor3 = Color3.fromRGB(8, 8, 8), BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, ZIndex = 20, ClipsDescendants = true, Parent = settingsPage}, {create("UICorner", {CornerRadius = UDim.new(0, 5)}), create("UIStroke", {Color = Color3.fromRGB(40, 40, 40), Thickness = 1})})
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), Parent = ddList})
	create("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), Parent = ddList})

	local function playSong(sd) if currentSound then currentSound:Destroy(); currentSound = nil end; if sd then local s = Instance.new("Sound"); s.SoundId = sd.id; s.Volume = 0.5; s.Looped = true; s.Parent = SoundService; s:Play(); currentSound = s; ddText.Text = sd.name else ddText.Text = "None" end end

	local function mkOpt(name, order, songData)
		local ob = create("TextButton", {Name = "Option_" .. name, Size = UDim2.new(1, 0, 0, 21), BackgroundColor3 = Color3.fromRGB(15, 15, 15), BackgroundTransparency = 0.3, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = order, ZIndex = 21, Parent = ddList}, {create("UICorner", {CornerRadius = UDim.new(0, 4)})})
		create("TextLabel", {Name = "Label", Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0), BackgroundTransparency = 1, Text = name, TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = songData and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(150, 150, 150), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = ob})
		ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0; ob.BackgroundColor3 = Color3.fromRGB(25, 25, 25) end)
		ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 0.3; ob.BackgroundColor3 = Color3.fromRGB(15, 15, 15) end)
		ob.MouseButton1Click:Connect(function() playSong(songData); ddOpen = false; ddList.Visible = false; ddArrow.Text = "▼" end)
	end
	mkOpt("None", 0, nil)
	for i, s in ipairs(SONGS) do mkOpt(s.name, i, s) end

	ddBtn.MouseButton1Click:Connect(function() ddOpen = not ddOpen; ddList.Visible = ddOpen; ddArrow.Text = ddOpen and "▲" or "▼" end)
	ddBtn.MouseEnter:Connect(function() ddBtn.BackgroundTransparency = 0.1 end)
	ddBtn.MouseLeave:Connect(function() ddBtn.BackgroundTransparency = 0.25 end)
end

--------------------------------------------------------------
-- BOTTOM NAV BAR (wrapped)
--------------------------------------------------------------
do
	local navBar = create("Frame", {Name = "NavBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -30, 0, 50), BackgroundTransparency = 1, Parent = mainFrame}, {create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder})})

	local activePage = "Home"
	local navButtons = {}

	local function switchPage(pageId)
		if pageId == activePage then return end
		if pageFrames[activePage] then pageFrames[activePage].Visible = false end
		if pageFrames[pageId] then pageFrames[pageId].Visible = true end
		for id, data in pairs(navButtons) do
			if id == pageId then
				TweenService:Create(data.btn, TWEEN_INFO, {Size = BTN_SIZE_ACTIVE, BackgroundTransparency = 0.1}):Play()
				if data.useText then TweenService:Create(data.textLabel, TWEEN_INFO, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				else TweenService:Create(data.icon, TWEEN_INFO, {Size = ICON_SIZE_ACTIVE, ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play() end
			else
				TweenService:Create(data.btn, TWEEN_INFO, {Size = BTN_SIZE_NORMAL, BackgroundTransparency = 0.35}):Play()
				if data.useText then TweenService:Create(data.textLabel, TWEEN_INFO, {TextColor3 = Color3.fromRGB(160, 160, 160)}):Play()
				else TweenService:Create(data.icon, TWEEN_INFO, {Size = ICON_SIZE_NORMAL, ImageColor3 = Color3.fromRGB(160, 160, 160)}):Play() end
			end
		end
		activePage = pageId
	end

	for i, pageInfo in ipairs(PAGES) do
		local isHome = (pageInfo.id == "Home")
		local btn = create("TextButton", {Name = "NavBtn_" .. pageInfo.id, AnchorPoint = Vector2.new(0.5, 0.5), Size = isHome and BTN_SIZE_ACTIVE or BTN_SIZE_NORMAL, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = isHome and 0.1 or 0.35, BorderSizePixel = 0, Text = "", LayoutOrder = i, AutoButtonColor = false, Parent = navBar}, {create("UICorner", {CornerRadius = UDim.new(0, 6)})})
		addAnimatedStroke(btn, 1.5)
		local btnIcon, btnTextLabel
		local useText = (pageInfo.icon == "")
		if useText then
			btnTextLabel = create("TextLabel", {Name = "BtnText", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = pageInfo.id, TextColor3 = Color3.fromRGB(160, 160, 160), TextSize = 13, Font = Enum.Font.GothamBold, Parent = btn})
		else
			btnIcon = create("ImageLabel", {Name = "BtnIcon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = isHome and ICON_SIZE_ACTIVE or ICON_SIZE_NORMAL, BackgroundTransparency = 1, Image = pageInfo.icon, ImageColor3 = isHome and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160), ScaleType = Enum.ScaleType.Fit, Parent = btn})
		end
		navButtons[pageInfo.id] = {btn = btn, icon = btnIcon, textLabel = btnTextLabel, useText = useText}
		btn.MouseEnter:Connect(function() if pageInfo.id ~= activePage then TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.2}):Play(); if useText then TweenService:Create(btnTextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextColor3 = Color3.fromRGB(220, 220, 220)}):Play() else TweenService:Create(btnIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(220, 220, 220)}):Play() end end end)
		btn.MouseLeave:Connect(function() if pageInfo.id ~= activePage then TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.35}):Play(); if useText then TweenService:Create(btnTextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextColor3 = Color3.fromRGB(160, 160, 160)}):Play() else TweenService:Create(btnIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageColor3 = Color3.fromRGB(160, 160, 160)}):Play() end end end)
		btn.MouseButton1Click:Connect(function() switchPage(pageInfo.id) end)
	end
end

--------------------------------------------------------------
-- LIVE CLOCK
--------------------------------------------------------------
task.spawn(function()
	while clockLabel and clockLabel.Parent do
		local now = os.date("*t")
		clockLabel.Text = string.format("%02d:%02d:%02d", now.hour, now.min, now.sec)
		task.wait(1)
	end
end)

--------------------------------------------------------------
-- PERIODIC POSITION SAVER
--------------------------------------------------------------
task.spawn(function()
	while screenGui and screenGui.Parent do
		for key, frame in pairs(GuiPositionRegistry) do
			if frame and frame.Parent then
				local pos = frame.Position
				SaveData.guiPositions[key] = {xs = pos.X.Scale, xo = pos.X.Offset, ys = pos.Y.Scale, yo = pos.Y.Offset}
			end
		end
		pcall(function() writefile(DASHBOARD_SAVE_FILE, HttpService:JSONEncode(SaveData)) end)
		task.wait(3)
	end
end)

--------------------------------------------------------------
-- RESTORE SAVED TOGGLES
--------------------------------------------------------------
task.defer(function()
	task.wait(1.5) -- wait for all UI and systems to initialize
	if SaveData.toggles then
		for name, wasEnabled in pairs(SaveData.toggles) do
			if wasEnabled and ToggleRegistry[name] and not TOGGLE_NO_SAVE[name] then
				task.spawn(function()
					ToggleRegistry[name](true)
				end)
				task.wait(0.3) -- stagger each toggle activation
			end
		end
	end
end)

--------------------------------------------------------------
-- INIT
--------------------------------------------------------------
print("DashboardGui loaded for " .. player.DisplayName .. "!")
