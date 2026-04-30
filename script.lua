-- S7 SHUB - Black & Purple Edition
-- With Lock (Bat Aimbot), Auto Steal & Lagger Mode (12 Speed)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==================== COLORS ====================
local ACCENT = Color3.fromRGB(156, 50, 255)  -- Purple
local WHITE = Color3.fromRGB(240, 240, 255)
local BG = Color3.fromRGB(0, 0, 0)
local CARD = Color3.fromRGB(10, 10, 15)
local OFF_CLR = Color3.fromRGB(20, 20, 30)

-- ==================== LAGGER VARIABLES ====================
local laggerActive = false
local laggerNormalSpeed = 12  -- Normal speed when Lagger ON (changed from 35 to 12)
local laggerSlowSpeed = 10.5   -- Speed when holding Brainrot
local laggerSpeedValue = laggerNormalSpeed
local laggerMonitorConns = {}

-- Lagger speed setter function
local function setLaggerSpeed(speed)
    laggerNormalSpeed = speed
    if laggerActive then
        laggerSpeedValue = speed
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
                local isStealing = player:GetAttribute("Stealing") == true
                if hasBrainrot or isStealing then
                    hum.WalkSpeed = laggerSlowSpeed
                else
                    hum.WalkSpeed = laggerNormalSpeed
                end
            end
        end
    end
end

local function updateLaggerSpeed()
    if not laggerActive then return end
    local char = player.Character
    if not char then return end
    local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
    local isStealing = player:GetAttribute("Stealing") == true
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hasBrainrot or isStealing then
        hum.WalkSpeed = laggerSlowSpeed
    else
        if hum.WalkSpeed ~= laggerNormalSpeed then
            hum.WalkSpeed = laggerNormalSpeed
        end
    end
end

local function setupLaggerMonitor()
    local char = player.Character
    if not char then return end
    local function checkAndApply()
        if not laggerActive then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
        local isStealing = player:GetAttribute("Stealing") == true
        if hum then
            if hasBrainrot or isStealing then
                hum.WalkSpeed = laggerSlowSpeed
            else
                hum.WalkSpeed = laggerNormalSpeed
            end
        end
    end
    local addedConn = char.ChildAdded:Connect(function(child)
        if child.Name == "Brainrot" then checkAndApply() end
    end)
    local removedConn = char.ChildRemoved:Connect(function(child)
        if child.Name == "Brainrot" then checkAndApply() end
    end)
    table.insert(laggerMonitorConns, addedConn)
    table.insert(laggerMonitorConns, removedConn)
    checkAndApply()
end

local function cleanupLaggerMonitor()
    for _, conn in ipairs(laggerMonitorConns) do
        pcall(function() conn:Disconnect() end)
    end
    laggerMonitorConns = {}
end

-- ==================== BAT AIMBOT ====================
local batAimbotEnabled = false
local aimbotConnection = nil
local lockedTarget = nil
local AIMBOT_SPEED = 60
local BOT_ENGAGE_RANGE = 5
local purpleHighlight = nil

-- Create purple highlight for target
purpleHighlight = Instance.new("Highlight")
purpleHighlight.Name = "S7AimbotHighlight"
purpleHighlight.FillColor = ACCENT
purpleHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
purpleHighlight.FillTransparency = 0.5
purpleHighlight.OutlineTransparency = 0
pcall(function() purpleHighlight.Parent = player:WaitForChild("PlayerGui") end)

local SlapList = {"Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap", "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap", "Nuclear Slap", "Galaxy Slap", "Glitched Slap"}

local function findBatTool()
    local c = player.Character if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then
                return ch
            end
        end
    end
    for _, name in ipairs(SlapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    return nil
end

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist = math.huge
    local newTargetChar, newTargetHRP = nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isTargetValid(p.Character) then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local d = (tHRP.Position - myHRP.Position).Magnitude
                if d < shortestDist then
                    shortestDist = d
                    newTargetHRP = tHRP
                    newTargetChar = p.Character
                end
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

local function startBatAimbot()
    if aimbotConnection then return end
    batAimbotEnabled = true
    aimbotConnection = RunService.Heartbeat:Connect(function()
        if not batAimbotEnabled then return end
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local bat = findBatTool()
        if bat and bat.Parent ~= c then hum:EquipTool(bat) end
        local targetHRP, targetChar = getBestTarget(h)
        if purpleHighlight then
            purpleHighlight.Adornee = targetChar
        end
        if targetHRP and targetChar then
            local targetVel = targetHRP.AssemblyLinearVelocity
            local speed = targetVel.Magnitude
            local predictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + (targetVel * predictTime)
            local moveDir = predictedPos - h.Position
            local distToStand = moveDir.Magnitude
            if distToStand > 1.5 then
                h.AssemblyLinearVelocity = moveDir.Unit * AIMBOT_SPEED
            else
                h.AssemblyLinearVelocity = targetVel
            end
            hum.AutoRotate = false
            h.CFrame = CFrame.lookAt(h.Position, Vector3.new(predictedPos.X, h.Position.Y, predictedPos.Z))
            if distToStand <= BOT_ENGAGE_RANGE and bat then
                pcall(function() bat:Activate() end)
            end
        else
            lockedTarget = nil
            if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
            hum.AutoRotate = true
            if purpleHighlight then purpleHighlight.Adornee = nil end
        end
    end)
end

local function stopBatAimbot()
    batAimbotEnabled = false
    if aimbotConnection then aimbotConnection:Disconnect() aimbotConnection = nil end
    lockedTarget = nil
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end
    if purpleHighlight then purpleHighlight.Adornee = nil end
end

-- ==================== AUTO STEAL ====================
local autoStealEnabled = false
local autoStealConn = nil
local isStealing = false
local stealProgress = 0
local STEAL_RADIUS = 20
local STEAL_DURATION = 0.35
local allAnimalsCache = {}
local promptCache = {}
local stealCache = {}
local progressFill = nil
local progressLabel = nil
local progressPctLabel = nil

local function isMyBase(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    for _, pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            table.insert(allAnimalsCache, {
                plot = plot.Name,
                slot = pod.Name,
                worldPosition = pod:GetPivot().Position,
                uid = plot.Name .. "_" .. pod.Name
            })
        end
    end
end

local function findPromptForAnimal(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(ad.plot)
    if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums")
    if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot)
    if not pod then return nil end
    local base = pod:FindFirstChild("Base")
    if not base then return nil end
    local sp = base:FindFirstChild("Spawn")
    if not sp then return nil end
    local att = sp:FindFirstChild("PromptAttachment")
    if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            promptCache[ad.uid] = p
            return p
        end
    end
end

local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = { hold = {}, trigger = {}, ready = true }
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                if type(c.Function) == "function" then table.insert(data.hold, c.Function) end
            end
            for _, c in ipairs(getconnections(prompt.Triggered)) do
                if type(c.Function) == "function" then table.insert(data.trigger, c.Function) end
            end
        end
    end)
    if #data.hold > 0 or #data.trigger > 0 then
        stealCache[prompt] = data
    end
end

local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    isStealing = true
    local startTime = tick()
    if progressLabel then progressLabel.Text = "STEALING..." end
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if progressLabel then progressLabel.Text = "READY" end
        if progressPctLabel then progressPctLabel.Text = "" end
        if progressFill then progressFill.Size = UDim2.new(0, 0, 1, 0) end
        data.ready = true
        isStealing = false
    end)
    -- Progress update loop
    task.spawn(function()
        while isStealing do
            local prog = math.clamp((tick() - startTime) / STEAL_DURATION, 0, 1)
            if progressFill then progressFill.Size = UDim2.new(prog, 0, 1, 0) end
            if progressPctLabel then progressPctLabel.Text = math.floor(prog * 100) .. "%" end
            task.wait(0.03)
        end
    end)
    return true
end

local function nearestAnimal()
    local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(allAnimalsCache) do
        if not isMyBase(ad.plot) and ad.worldPosition then
            local d = (h.Position - ad.worldPosition).Magnitude
            if d < bestD then
                bestD = d
                best = ad
            end
        end
    end
    return best
end

local function startAutoStealLoop()
    if autoStealConn then return end
    autoStealConn = RunService.Heartbeat:Connect(function()
        if not autoStealEnabled or isStealing then return end
        local target = nearestAnimal()
        if not target then return end
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if (h.Position - target.worldPosition).Magnitude > STEAL_RADIUS then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then
            prompt = findPromptForAnimal(target)
        end
        if prompt then
            buildCallbacks(prompt)
            execSteal(prompt)
        end
    end)
end

local function stopAutoStealLoop()
    if autoStealConn then
        autoStealConn:Disconnect()
        autoStealConn = nil
    end
    isStealing = false
end

-- Cache animals periodically
task.spawn(function()
    task.wait(2)
    while task.wait(5) do
        allAnimalsCache = {}
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then
                    scanPlot(plot)
                end
            end
        end
    end
end)

-- ==================== INFINITE JUMP ====================
local infJumpEnabled = true
local jumpForce = 54
local clampFall = 80

UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, jumpForce, hrp.AssemblyLinearVelocity.Z)
    end
end)

RunService.Heartbeat:Connect(function()
    if not infJumpEnabled then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity.Y < -clampFall then
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -clampFall, hrp.AssemblyLinearVelocity.Z)
    end
end)

-- ==================== TAUNT ====================
local tauntActive = false
local tauntLoop = nil

local function startTaunt()
    if tauntLoop then return end
    tauntActive = true
    tauntLoop = task.spawn(function()
        while tauntActive do
            pcall(function()
                local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                if chatEvent then
                    local sayMsg = chatEvent:FindFirstChild("SayMessageRequest")
                    if sayMsg then
                        sayMsg:FireServer("/lol S7 Shub😂😂", "All")
                        task.wait(0.3)
                        sayMsg:FireServer("/lol S7 Shub😂😂", "All")
                    end
                end
            end)
            task.wait(2)
        end
    end)
end

local function stopTaunt()
    tauntActive = false
    if tauntLoop then
        task.cancel(tauntLoop)
        tauntLoop = nil
    end
end

-- ==================== ANTI RAGDOLL ====================
local antiRagdollEnabled = false
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                if root then
                    root.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then
                obj.Enabled = true
            end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "S7ShubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 520)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -260)
MainFrame.BackgroundColor3 = BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2
MainStroke.Color = ACCENT

-- Title
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 16)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "S7 SHUB"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.TextColor3 = ACCENT

local Discord = Instance.new("TextLabel", TitleBar)
Discord.Size = UDim2.new(1, 0, 0, 16)
Discord.Position = UDim2.new(0, 0, 1, -20)
Discord.BackgroundTransparency = 1
Discord.Text = "discord.gg/qMtvNQg68s"
Discord.Font = Enum.Font.GothamBold
Discord.TextSize = 10
Discord.TextColor3 = Color3.fromRGB(150, 150, 160)

-- Close button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = ACCENT
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    stopBatAimbot()
    stopAutoStealLoop()
    if laggerActive then
        laggerActive = false
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        cleanupLaggerMonitor()
    end
end)

-- Scrollable content
local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -140)
ScrollFrame.Position = UDim2.new(0, 10, 0, 100)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = ACCENT
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeSection(text)
    local lbl = Instance.new("TextLabel", ScrollFrame)
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = ACCENT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeToggle(text, defaultState, callback)
    local row = Instance.new("Frame", ScrollFrame)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0, 44, 0, 22)
    track.Position = UDim2.new(1, -54, 0.5, -11)
    track.BackgroundColor3 = defaultState and ACCENT or OFF_CLR
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    local isOn = defaultState
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        track.BackgroundColor3 = isOn and ACCENT or OFF_CLR
        dot.Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if callback then callback(isOn) end
    end)
    
    return { set = function(state)
        isOn = state
        track.BackgroundColor3 = state and ACCENT or OFF_CLR
        dot.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    end }
end

local function makeNumberInput(text, defaultValue, minVal, maxVal, callback)
    local row = Instance.new("Frame", ScrollFrame)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0, 70, 0, 28)
    box.Position = UDim2.new(1, -80, 0.5, -14)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    box.Text = tostring(defaultValue)
    box.TextColor3 = ACCENT
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            local clamped = math.clamp(n, minVal, maxVal)
            box.Text = tostring(clamped)
            if callback then callback(clamped) end
        else
            box.Text = tostring(defaultValue)
        end
    end)
    
    return box
end

-- Build GUI
makeSection(" ⚔️ COMBAT")
local lockToggle = makeToggle("LOCK (Bat Aimbot)", false, function(on)
    if on then
        startBatAimbot()
    else
        stopBatAimbot()
    end
end)

makeSection(" 🦴 MECHANICS")
local antiRagdollToggle = makeToggle("Anti Ragdoll", false, function(on)
    antiRagdollEnabled = on
    if on then startAntiRagdoll() else stopAntiRagdoll() end
end)
local infJumpToggle = makeToggle("Infinite Jump", true, function(on)
    infJumpEnabled = on
end)

makeSection(" 🏃 MOVEMENT")
local slowDownToggle = makeToggle("Slow Down", false, function(on)
    -- Slow down function
end)

makeSection(" 🐾 AUTO STEAL")
local stealToggle = makeToggle("Auto Steal", false, function(on)
    autoStealEnabled = on
    if on then
        startAutoStealLoop()
    else
        stopAutoStealLoop()
    end
end)
local stealRadiusInput = makeNumberInput("Steal Radius", STEAL_RADIUS, 5, 200, function(val)
    STEAL_RADIUS = val
end)

makeSection(" 🎭 LAGGER MODE")
local laggerToggle = makeToggle("Lagger Mode", false, function(on)
    laggerActive = on
    if on then
        laggerSpeedValue = laggerNormalSpeed
        setupLaggerMonitor()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = laggerNormalSpeed end
        end
    else
        cleanupLaggerMonitor()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
end)
local laggerSpeedInput = makeNumberInput("Lagger Speed", laggerNormalSpeed, 1, 50, function(val)
    laggerNormalSpeed = val
    if laggerActive then
        laggerSpeedValue = val
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end
end)

makeSection(" 📢 ACTIONS")
local tauntBtn = Instance.new("TextButton", ScrollFrame)
tauntBtn.Size = UDim2.new(1, 0, 0, 40)
tauntBtn.BackgroundColor3 = CARD
tauntBtn.Text = "TAUNT"
tauntBtn.Font = Enum.Font.GothamBlack
tauntBtn.TextSize = 14
tauntBtn.TextColor3 = ACCENT
tauntBtn.BorderSizePixel = 0
Instance.new("UICorner", tauntBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tauntBtn).Color = ACCENT

local tauntSpam = false
tauntBtn.MouseButton1Click:Connect(function()
    if tauntSpam then
        stopTaunt()
        tauntSpam = false
        tauntBtn.Text = "TAUNT"
        tauntBtn.BackgroundColor3 = CARD
    else
        startTaunt()
        tauntSpam = true
        tauntBtn.Text = "TAUNT ON"
        tauntBtn.BackgroundColor3 = ACCENT
        tauntBtn.TextColor3 = BG
    end
end)

makeSection(" 🎮 MOBILE")
local showMobileBtns = makeToggle("Show Mobile Buttons", false, function(on)
    -- Mobile buttons would appear here
end)

-- ==================== PROGRESS BAR (AUTO STEAL) ====================
local ProgressGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ProgressGui.Name = "S7ProgressBar"
ProgressGui.ResetOnSpawn = false
ProgressGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ProgressFrame = Instance.new("Frame", ProgressGui)
ProgressFrame.Size = UDim2.new(0, 220, 0, 38)
ProgressFrame.Position = UDim2.new(0.5, -110, 1, -55)
ProgressFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
ProgressFrame.BackgroundTransparency = 0.1
ProgressFrame.BorderSizePixel = 0
Instance.new("UICorner", ProgressFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", ProgressFrame).Color = ACCENT

progressLabel = Instance.new("TextLabel", ProgressFrame)
progressLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
progressLabel.Position = UDim2.new(0, 8, 0, 4)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "READY"
progressLabel.TextColor3 = WHITE
progressLabel.Font = Enum.Font.GothamBold
progressLabel.TextSize = 11
progressLabel.TextXAlignment = Enum.TextXAlignment.Left

progressPctLabel = Instance.new("TextLabel", ProgressFrame)
progressPctLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
progressPctLabel.Position = UDim2.new(0.5, 0, 0, 4)
progressPctLabel.BackgroundTransparency = 1
progressPctLabel.Text = ""
progressPctLabel.TextColor3 = ACCENT
progressPctLabel.Font = Enum.Font.GothamBlack
progressPctLabel.TextSize = 13
progressPctLabel.TextXAlignment = Enum.TextXAlignment.Center

local radLabel = Instance.new("TextLabel", ProgressFrame)
radLabel.Size = UDim2.new(0, 50, 0, 16)
radLabel.Position = UDim2.new(1, -60, 0, 4)
radLabel.BackgroundTransparency = 1
radLabel.Text = "R:" .. STEAL_RADIUS
radLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
radLabel.Font = Enum.Font.GothamBold
radLabel.TextSize = 10

local progressBg = Instance.new("Frame", ProgressFrame)
progressBg.Size = UDim2.new(0.92, 0, 0, 8)
progressBg.Position = UDim2.new(0.04, 0, 1, -14)
progressBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
progressBg.BorderSizePixel = 0
Instance.new("UICorner", progressBg).CornerRadius = UDim.new(1, 0)

progressFill = Instance.new("Frame", progressBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = ACCENT
progressFill.BorderSizePixel = 0
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

-- Update radius display when changed
local oldSetText = stealRadiusInput.Text
stealRadiusInput:GetPropertyChangedSignal("Text"):Connect(function()
    radLabel.Text = "R:" .. stealRadiusInput.Text
end)

-- ==================== OPEN/CLOSE BUTTON ====================
local OpenCloseGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
OpenCloseGui.Name = "S7OpenClose"
OpenCloseGui.ResetOnSpawn = false

local OpenBtn = Instance.new("TextButton", OpenCloseGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -25)
OpenBtn.BackgroundColor3 = BG
OpenBtn.Text = "S7"
OpenBtn.TextSize = 14
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextColor3 = ACCENT
OpenBtn.BorderSizePixel = 0
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", OpenBtn).Color = ACCENT

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    ProgressFrame.Visible = not ProgressFrame.Visible
end)

-- Make OpenBtn draggable
local dragging = false
local dragStart, startPos
OpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = OpenBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        OpenBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("S7 SHUB Loaded! discord.gg/qMtvNQg68s")
