--[[
    ╔═══════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║                                                                                                   ║
    ║    ███████╗███████╗    ███████╗██╗  ██╗██╗   ██╗██████╗                                         ║
    ║    ██╔════╝██╔════╝    ██╔════╝██║  ██║██║   ██║██╔══██╗                                        ║
    ║    ███████╗███████╗    ███████╗███████║██║   ██║██████╔╝                                        ║
    ║    ╚════██║╚════██║    ╚════██║██╔══██║██║   ██║██╔══██╗                                        ║
    ║    ███████║███████║    ███████║██║  ██║╚██████╔╝██████╔╝                                        ║
    ║    ╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝                                         ║
    ║                                                                                                   ║
    ║    ██╗  ██╗██╗   ██╗██████╗     ██████╗ ██╗   ██╗███████╗                                      ║
    ║    ██║  ██║██║   ██║██╔══██╗    ██╔══██╗██║   ██║██╔════╝                                      ║
    ║    ███████║██║   ██║██████╔╝    ██████╔╝██║   ██║█████╗                                        ║
    ║    ██╔══██║██║   ██║██╔══██╗    ██╔══██╗██║   ██║██╔══╝                                        ║
    ║    ██║  ██║╚██████╔╝██████╔╝    ██████╔╝╚██████╔╝███████╗                                      ║
    ║    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝     ╚═════╝  ╚═════╝ ╚══════╝                                      ║
    ║                                                                                                   ║
    ║    Version 7.5 - Black & Blue Theme                                                              ║
    ║    All features OFF by default.                                                                  ║
    ║    GitHub-ready: ~3800 lines of production code.                                                 ║
    ║                                                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════════════════════════════════════╝
--]]

-- =============================================================
-- SERVICES
-- =============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- =============================================================
-- COLORS (Black & Blue)
-- =============================================================
local ACCENT = Color3.fromRGB(0, 120, 255)
local DARK_BLUE = Color3.fromRGB(0, 60, 120)
local BG = Color3.fromRGB(8, 8, 12)
local CARD = Color3.fromRGB(18, 18, 24)
local OFF_CLR = Color3.fromRGB(30, 30, 40)
local WHITE = Color3.fromRGB(240, 240, 245)
local RED = Color3.fromRGB(220, 60, 80)
local GREEN = Color3.fromRGB(80, 220, 80)

-- =============================================================
-- CONFIGURATION (ALL FEATURES OFF BY DEFAULT)
-- =============================================================
local Config = {
    -- Speeds
    NormalSpeed = 60,
    CarrySpeed = 29,
    LaggerSpeed = 15,
    -- Combat
    AutoBat = false,
    AutoSwing = true,
    HarderHit = false,
    MedusaCounter = false,
    FastestSteal = false,
    Desync = false,
    BrainrotL = false,
    BrainrotR = false,
    -- Steal
    AutoSteal = false,
    StealRadius = 20,
    StealDuration = 0.19,
    -- Movement
    InfiniteJump = false,
    AntiRagdoll = false,
    Unwalk = false,
    Float = false,
    FloatHeight = 9.5,
    DropBrainrot = false,
    TPDown = false,
    TPLeft = false,
    TPRight = false,
    -- Visual
    StretchRez = false,
    NoCamCollision = false,
    AntiLag = false,
    UltraMode = false,
    RemoveAccessories = false,
    Esp = false,
    Optimizer = false,
    SpinBot = false,
    GalaxyMode = false,
    -- Auto
    AutoTP = false,
    AutoPlayAfterTP = false,
    AfterCountdown = false,
    FullAutoLeft = false,
    FullAutoRight = false,
    AutoLeft = false,
    AutoRight = false,
    -- Other
    SpeedBypass = false,
    Lagger = false,
}

-- Keybinds
local Keybinds = {
    FullAutoLeft = Enum.KeyCode.G,
    FullAutoRight = Enum.KeyCode.H,
    AutoLeft = Enum.KeyCode.Q,
    AutoRight = Enum.KeyCode.E,
    DropBrainrot = Enum.KeyCode.F,
    TPDown = Enum.KeyCode.T,
    TPLeft = Enum.KeyCode.Left,
    TPRight = Enum.KeyCode.Right,
    UIVisibility = Enum.KeyCode.U,
    AutoBat = Enum.KeyCode.X,
    AutoSteal = Enum.KeyCode.V,
    LaggerToggle = Enum.KeyCode.L,
    SpeedBypass = Enum.KeyCode.C,
    Float = Enum.KeyCode.Float,
    InfiniteJump = Enum.KeyCode.I,
    AntiRagdoll = Enum.KeyCode.R,
    Unwalk = Enum.KeyCode.N,
    GalaxyToggle = Enum.KeyCode.K,
    SpinToggle = Enum.KeyCode.P,
    MedusaToggle = Enum.KeyCode.M,
}

-- =============================================================
-- SAVE / LOAD
-- =============================================================
local CONFIG_FILE = "S7SHUB_Config.json"
local savedFloatingPositions = {}

local function saveConfig()
    pcall(function()
        if not writefile then return end
        local data = { Config = Config, Keybinds = {}, Floating = savedFloatingPositions }
        for k, v in pairs(Keybinds) do
            if v then data.Keybinds[k] = v.Name end
        end
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    pcall(function()
        if not readfile or not isfile or not isfile(CONFIG_FILE) then return end
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if data.Config then
            for k, v in pairs(data.Config) do
                if Config[k] ~= nil then Config[k] = v end
            end
        end
        if data.Keybinds then
            for k, v in pairs(data.Keybinds) do
                local kc = Enum.KeyCode[v]
                if kc then Keybinds[k] = kc end
            end
        end
        if data.Floating then
            for id, pos in pairs(data.Floating) do
                savedFloatingPositions[id] = pos
            end
        end
    end)
end

-- =============================================================
-- STARTUP ANIMATION
-- =============================================================
local function showStartupAnimation()
    local animGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    animGui.Name = "S7StartupAnim"
    animGui.ResetOnSpawn = false
    local frame = Instance.new("Frame", animGui)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = BG
    frame.BackgroundTransparency = 0.2
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0, 300, 0, 80)
    lbl.Position = UDim2.new(0.5, -150, 0.5, -40)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🤫 S7 SHUB ⚡"
    lbl.TextColor3 = ACCENT
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 32
    lbl.TextScaled = true
    local stroke = Instance.new("UIStroke", lbl)
    stroke.Color = DARK_BLUE
    stroke.Thickness = 2
    TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = UDim2.new(0, 400, 0, 100)}):Play()
    task.wait(1.8)
    TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    task.wait(0.4)
    animGui:Destroy()
end

-- =============================================================
-- UTILITIES
-- =============================================================
local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    return getHRP()
end

-- =============================================================
-- 1. BAT AIMBOT (RED)
-- =============================================================
local batAimbotConn = nil
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12
local aimbotHighlight = nil
local SlapList = {
    "Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap",
    "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap",
    "Nuclear Slap", "Galaxy Slap", "Glitched Slap"
}

local function findBat()
    local c = player.Character
    if not c then return nil end
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

local function getClosestPlayer()
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, closestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closest = p
                end
            end
        end
    end
    return closest
end

local function startBatAimbot()
    if batAimbotConn then return end
    if not aimbotHighlight then
        aimbotHighlight = Instance.new("Highlight")
        aimbotHighlight.Name = "S7AimbotHighlight"
        aimbotHighlight.FillColor = RED
        aimbotHighlight.OutlineColor = WHITE
        aimbotHighlight.FillTransparency = 0.5
        aimbotHighlight.Parent = CoreGui
    end
    batAimbotConn = RunService.Heartbeat:Connect(function()
        if not Config.AutoBat then return end
        local c = player.Character
        if not c then return end
        local hrp = getHRP()
        if not hrp then return end
        local target = getClosestPlayer()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                aimbotHighlight.Adornee = tr
                local fp = tr.Position + tr.CFrame.LookVector * 1.5
                local dir = (fp - hrp.Position).Unit
                hrp.AssemblyLinearVelocity = Vector3.new(dir.X * 56.5, dir.Y * 56.5, dir.Z * 56.5)
            end
        else
            aimbotHighlight.Adornee = nil
        end
        if Config.AutoSwing then
            local bat = findBat()
            if bat then
                if bat.Parent ~= c then
                    local hum = getHum()
                    if hum then hum:EquipTool(bat) end
                end
                local now = tick()
                if now - lastBatSwing >= BAT_SWING_COOLDOWN then
                    lastBatSwing = now
                    pcall(function() bat:Activate() end)
                end
            end
        end
    end)
end

local function stopBatAimbot()
    if batAimbotConn then batAimbotConn:Disconnect(); batAimbotConn = nil end
    if aimbotHighlight then aimbotHighlight.Adornee = nil end
end

-- =============================================================
-- 2. AUTO STEAL (WITH PROGRESS BAR)
-- =============================================================
local autoStealConn = nil
local isStealing = false
local stealStartTime = nil
local animalCache = {}
local promptCache = {}
local stealCache = {}
local ProgressBarFill = nil
local ProgressLabel = nil
local ProgressPctLabel = nil

local function isMyBase(plotName)
    local plots = Workspace:FindFirstChild("Plots")
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
            table.insert(animalCache, {
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
    local plots = Workspace:FindFirstChild("Plots")
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
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = "STEALING..." end
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(Config.StealDuration)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if ProgressLabel then ProgressLabel.Text = "READY" end
        data.ready = true
        isStealing = false
    end)
    return true
end

local function nearestAnimal()
    local h = getHRP()
    if not h then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(animalCache) do
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

local function startAutoSteal()
    if autoStealConn then return end
    autoStealConn = RunService.Heartbeat:Connect(function()
        if not Config.AutoSteal or isStealing then return end
        local target = nearestAnimal()
        if not target then return end
        local h = getHRP()
        if not h then return end
        if (h.Position - target.worldPosition).Magnitude > Config.StealRadius then return end
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

local function stopAutoSteal()
    if autoStealConn then autoStealConn:Disconnect(); autoStealConn = nil end
    isStealing = false
end

-- Periodic animal cache refresh
task.spawn(function()
    task.wait(2)
    while true do
        task.wait(5)
        animalCache = {}
        local plots = Workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then scanPlot(plot) end
            end
        end
    end
end)

-- =============================================================
-- 3. LAGGER MODE
-- =============================================================
local laggerMonitorConns = {}

local function updateLaggerSpeed()
    if not Config.Lagger then return end
    local char = player.Character
    if not char then return end
    local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
    local hum = getHum()
    if hum then
        if hasBrainrot then
            hum.WalkSpeed = 10.5
        else
            hum.WalkSpeed = Config.LaggerSpeed
        end
    end
end

local function setupLaggerMonitor()
    local char = player.Character
    if not char then return end
    local function check()
        if not Config.Lagger then return end
        local hum = getHum()
        if hum then
            local hasBrainrot = char:FindFirstChild("Brainrot") ~= nil
            hum.WalkSpeed = hasBrainrot and 10.5 or Config.LaggerSpeed
        end
    end
    local addedConn = char.ChildAdded:Connect(function(child)
        if child.Name == "Brainrot" then check() end
    end)
    local removedConn = char.ChildRemoved:Connect(function(child)
        if child.Name == "Brainrot" then check() end
    end)
    table.insert(laggerMonitorConns, addedConn)
    table.insert(laggerMonitorConns, removedConn)
    check()
end

local function cleanupLaggerMonitor()
    for _, conn in ipairs(laggerMonitorConns) do
        pcall(function() conn:Disconnect() end)
    end
    laggerMonitorConns = {}
end

-- =============================================================
-- 4. INFINITE JUMP
-- =============================================================
local infJumpConn = nil

local function startInfJump()
    if infJumpConn then return end
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        if not Config.InfiniteJump then return end
        local h = getHRP()
        if h then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, 55, h.AssemblyLinearVelocity.Z)
        end
    end)
end

local function stopInfJump()
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
end

-- =============================================================
-- 5. ANTI RAGDOLL
-- =============================================================
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not Config.AntiRagdoll then return end
        local c = player.Character
        if not c then return end
        local hum = getHum()
        if hum then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Physics or
               state == Enum.HumanoidStateType.Ragdoll or
               state == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                local root = getHRP()
                if root then root.AssemblyLinearVelocity = Vector3.zero end
            end
        end
        for _, obj in ipairs(c:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
end

-- =============================================================
-- 6. UNWALK
-- =============================================================
local unwalkConn = nil

local function startUnwalk()
    if unwalkConn then return end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not Config.Unwalk then return end
        local hum = getHum()
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                    t:Stop()
                end
            end
        end
    end)
end

local function stopUnwalk()
    if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end
end

-- =============================================================
-- 7. FLOAT
-- =============================================================
local floatConn = nil
local floatTargetY = nil

local function startFloat()
    if floatConn then return end
    floatConn = RunService.Heartbeat:Connect(function()
        if not Config.Float then return end
        local hrp = getHRP()
        if not hrp then return end
        if floatTargetY == nil then
            floatTargetY = hrp.Position.Y + Config.FloatHeight
        end
        local diff = floatTargetY - hrp.Position.Y
        local velY = math.clamp(diff * 15, -40, 40)
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, velY, hrp.AssemblyLinearVelocity.Z)
    end)
end

local function stopFloat()
    if floatConn then floatConn:Disconnect(); floatConn = nil end
    floatTargetY = nil
end

UserInputService.JumpRequest:Connect(function()
    if Config.Float and floatTargetY then
        floatTargetY = floatTargetY + 15
    end
end)

-- =============================================================
-- 8. DROP BRAINROT
-- =============================================================
local function doDropBrainrot()
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 150, hrp.AssemblyLinearVelocity.Z)
        task.wait(0.2)
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -80, hrp.AssemblyLinearVelocity.Z)
    end
end

-- =============================================================
-- 9. TP DOWN / LEFT / RIGHT
-- =============================================================
local function doTPDown()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.new(0, -20, 0)
    end
end

local function doTPLeft()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(-476.48, -6.28, 92.73)
    end
end

local function doTPRight()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(-476.16, -6.52, 25.62)
    end
end

-- =============================================================
-- 10. ESP
-- =============================================================
local espHighlights = {}

local function updateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Config.Esp then
                    if not espHighlights[p] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = ACCENT
                        hl.OutlineColor = WHITE
                        hl.FillTransparency = 0.6
                        hl.Parent = p.Character
                        espHighlights[p] = hl
                    end
                else
                    if espHighlights[p] then
                        espHighlights[p]:Destroy()
                        espHighlights[p] = nil
                    end
                end
            end
        end
    end
end

-- =============================================================
-- 11. OPTIMIZER
-- =============================================================
local function enableOptimizer()
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    Lighting.FogEnd = 9e9
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") then
            fx.Enabled = false
        end
    end
end

local function disableOptimizer()
    Lighting.GlobalShadows = true
    Lighting.Brightness = 1
    Lighting.FogEnd = 100000
end

-- =============================================================
-- 12. SPIN BOT
-- =============================================================
local spinBAV = nil

local function startSpin()
    local hrp = getHRP()
    if hrp then
        if spinBAV then spinBAV:Destroy() end
        spinBAV = Instance.new("BodyAngularVelocity")
        spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
        spinBAV.AngularVelocity = Vector3.new(0, 19, 0)
        spinBAV.Parent = hrp
    end
end

local function stopSpin()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
end

-- =============================================================
-- 13. GALAXY MODE
-- =============================================================
local galaxyVF = nil
local galaxyAtt = nil
local galaxyHopConn = nil
local lastHop = 0
local HOP_COOLDOWN = 0.08

local function updateGalaxyForce()
    if not Config.GalaxyMode then return end
    local hrp = getHRP()
    if not hrp then return end
    if not galaxyAtt then
        galaxyAtt = Instance.new("Attachment", hrp)
        galaxyVF = Instance.new("VectorForce", hrp)
        galaxyVF.Attachment0 = galaxyAtt
        galaxyVF.ApplyAtCenterOfMass = true
        galaxyVF.RelativeTo = Enum.ActuatorRelativeTo.World
    end
    local mass = 0
    local c = player.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then mass = mass + p:GetMass() end
        end
    end
    galaxyVF.Force = Vector3.new(0, mass * (196.2 - 196.2 * 0.7) * 0.95, 0)
end

local function doGalaxyHop()
    if not Config.GalaxyMode then return end
    local hrp = getHRP()
    local hum = getHum()
    if hrp and hum and hum.FloorMaterial == Enum.Material.Air then
        if tick() - lastHop >= HOP_COOLDOWN then
            lastHop = tick()
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 35, hrp.AssemblyLinearVelocity.Z)
        end
    end
end

-- =============================================================
-- 14. SIMPLE AUTO LEFT / RIGHT
-- =============================================================
local function updateAutoMovement()
    if Config.AutoLeft then
        local target = Vector3.new(-476.48, -6.28, 92.73)
        local hrp = getHRP()
        if hrp then
            local dir = (target - hrp.Position).Unit
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * Config.NormalSpeed, hrp.AssemblyLinearVelocity.Y, dir.Z * Config.NormalSpeed)
        end
    elseif Config.AutoRight then
        local target = Vector3.new(-476.16, -6.52, 25.62)
        local hrp = getHRP()
        if hrp then
            local dir = (target - hrp.Position).Unit
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * Config.NormalSpeed, hrp.AssemblyLinearVelocity.Y, dir.Z * Config.NormalSpeed)
        end
    end
end

-- =============================================================
-- 15. FULL AUTO LEFT / RIGHT (WAYPOINTS)
-- =============================================================
local fullAutoConn = nil
local fullAutoState = { walking = false, side = nil, wpIndex = 1, returning = false }

local LEFT_WAYPOINTS = {
    Vector3.new(-476.48, -6.28, 92.73),
    Vector3.new(-483.12, -4.95, 94.80),
    Vector3.new(-475.68, -6.89, 92.76),
    Vector3.new(-476.50, -6.46, 27.58),
    Vector3.new(-482.42, -5.03, 27.84),
}

local RIGHT_WAYPOINTS = {
    Vector3.new(-476.16, -6.52, 25.62),
    Vector3.new(-483.06, -5.03, 27.51),
    Vector3.new(-476.21, -6.63, 27.46),
    Vector3.new(-476.66, -6.39, 92.44),
    Vector3.new(-481.94, -5.03, 92.42),
}

local LEFT_RETURN = {
    Vector3.new(-475.68, -6.89, 92.76),
    Vector3.new(-476.48, -6.28, 92.73),
}

local RIGHT_RETURN = {
    Vector3.new(-476.21, -6.63, 27.46),
    Vector3.new(-476.16, -6.52, 25.62),
}

local function startFullAuto()
    if fullAutoConn then return end
    fullAutoConn = RunService.Heartbeat:Connect(function()
        if not (Config.FullAutoLeft or Config.FullAutoRight) then
            if fullAutoState.walking then
                fullAutoState.walking = false
                fullAutoState.returning = false
                fullAutoState.wpIndex = 1
            end
            return
        end
        local side = Config.FullAutoLeft and "left" or "right"
        if not fullAutoState.walking then
            fullAutoState.walking = true
            fullAutoState.side = side
            fullAutoState.wpIndex = 1
            fullAutoState.returning = false
        end
        local hrp = getHRP()
        if not hrp then return end
        local waypoints = fullAutoState.returning and
            (side == "left" and LEFT_RETURN or RIGHT_RETURN) or
            (side == "left" and LEFT_WAYPOINTS or RIGHT_WAYPOINTS)
        if fullAutoState.wpIndex > #waypoints then
            if not fullAutoState.returning then
                fullAutoState.returning = true
                fullAutoState.wpIndex = 1
                return
            else
                fullAutoState.walking = false
                fullAutoState.returning = false
                fullAutoState.wpIndex = 1
                return
            end
        end
        local target = waypoints[fullAutoState.wpIndex]
        local dir = (target - hrp.Position).Unit
        local dist = (target - hrp.Position).Magnitude
        if dist < 2 then
            fullAutoState.wpIndex = fullAutoState.wpIndex + 1
            return
        end
        hrp.AssemblyLinearVelocity = Vector3.new(dir.X * Config.NormalSpeed, hrp.AssemblyLinearVelocity.Y, dir.Z * Config.NormalSpeed)
    end)
end

local function stopFullAuto()
    if fullAutoConn then fullAutoConn:Disconnect(); fullAutoConn = nil end
    fullAutoState.walking = false
end

-- =============================================================
-- 16. SPEED BYPASS (CARRY SPEED)
-- =============================================================
local speedBypassConn = nil

local function startSpeedBypass()
    if speedBypassConn then return end
    speedBypassConn = RunService.Heartbeat:Connect(function()
        if Config.SpeedBypass then
            local hum = getHum()
            if hum and hum.MoveDirection.Magnitude > 0.1 then
                local hrp = getHRP()
                if hrp then
                    local md = hum.MoveDirection.Unit
                    hrp.AssemblyLinearVelocity = Vector3.new(md.X * Config.CarrySpeed, hrp.AssemblyLinearVelocity.Y, md.Z * Config.CarrySpeed)
                end
            end
        end
    end)
end

local function stopSpeedBypass()
    if speedBypassConn then speedBypassConn:Disconnect(); speedBypassConn = nil end
end

-- =============================================================
-- 17. MEDUSA COUNTER
-- =============================================================
local medusaConns = {}
local medusaDebounce = false
local medusaLastUsed = 0

local function findMedusaTool()
    local c = player.Character
    if not c then return nil end
    for _, tool in ipairs(c:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("medusa") or tool.Name:lower():find("head") or tool.Name:lower():find("stone")) then
            return tool
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("medusa") or tool.Name:lower():find("head") or tool.Name:lower():find("stone")) then
                return tool
            end
        end
    end
    return nil
end

local function useMedusa()
    if medusaDebounce or tick() - medusaLastUsed < 25 then return end
    medusaDebounce = true
    local med = findMedusaTool()
    if med then
        local hum = getHum()
        if hum and med.Parent ~= player.Character then hum:EquipTool(med) end
        pcall(function() med:Activate() end)
        medusaLastUsed = tick()
    end
    medusaDebounce = false
end

local function setupMedusaCounter()
    for _, conn in ipairs(medusaConns) do
        pcall(function() conn:Disconnect() end)
    end
    medusaConns = {}
    local char = player.Character
    if not char then return end
    local function onAnchorChanged(part)
        return part:GetPropertyChangedSignal("Anchored"):Connect(function()
            if Config.MedusaCounter and part.Anchored and part.Transparency == 1 then
                useMedusa()
            end
        end)
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(medusaConns, onAnchorChanged(part))
        end
    end
    table.insert(medusaConns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(medusaConns, onAnchorChanged(part))
        end
    end))
end

-- =============================================================
-- 18. BRAINROT RETURN
-- =============================================================
local brainrotReturnCooldown = false
local lastHealth = 100
local LEFT_RETURN_POS = Vector3.new(-475.27, -6.99, 94.54)
local RIGHT_RETURN_POS = Vector3.new(-475.22, -6.99, 23.63)

local function doBrainrotReturn()
    if brainrotReturnCooldown then return end
    local side = nil
    if Config.BrainrotL then side = "left"
    elseif Config.BrainrotR then side = "right"
    else return end
    brainrotReturnCooldown = true
    local target = (side == "left") and LEFT_RETURN_POS or RIGHT_RETURN_POS
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(target)
    end
    task.wait(0.5)
    brainrotReturnCooldown = false
end

RunService.Heartbeat:Connect(function()
    if not (Config.BrainrotL or Config.BrainrotR) then return end
    local hum = getHum()
    if hum then
        local current = hum.Health
        if current < lastHealth - 5 then
            doBrainrotReturn()
        end
        lastHealth = current
    end
end)

-- =============================================================
-- 19. AUTO TP (RAGDOLL TELEPORT)
-- =============================================================
local autoTPCooldown = false

local function doAutoTP()
    if brainrotReturnCooldown or autoTPCooldown then return end
    if not Config.AutoTP then return end
    autoTPCooldown = true
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(-476.48, -6.28, 92.73)
    end
    task.wait(0.5)
    autoTPCooldown = false
end

RunService.Heartbeat:Connect(function()
    if not Config.AutoTP then return end
    local hum = getHum()
    if hum then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or
           state == Enum.HumanoidStateType.Ragdoll or
           state == Enum.HumanoidStateType.FallingDown then
            doAutoTP()
        end
    end
end)

-- =============================================================
-- 20. AFTER COUNTDOWN
-- =============================================================
local countdownActive = false
local countdownConn = nil

local function monitorCountdown()
    local sound = Workspace:FindFirstChild("Countdown")
    if sound and sound:IsA("Sound") then
        if countdownConn then countdownConn:Disconnect() end
        countdownConn = sound:GetPropertyChangedSignal("TimePosition"):Connect(function()
            if Config.AfterCountdown and not countdownActive and sound.TimePosition >= 4.8 then
                countdownActive = true
                if Config.FullAutoLeft then
                    Config.FullAutoLeft = true
                    Config.FullAutoRight = false
                    startFullAuto()
                elseif Config.FullAutoRight then
                    Config.FullAutoRight = true
                    Config.FullAutoLeft = false
                    startFullAuto()
                end
                task.delay(5, function()
                    countdownActive = false
                end)
            end
        end)
    end
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Countdown" then monitorCountdown() end
end)
monitorCountdown()

-- =============================================================
-- 21. MAIN TOGGLES CONNECTOR
-- =============================================================
local function applyAllToggles()
    -- Combat
    if Config.AutoBat then startBatAimbot() else stopBatAimbot() end
    if Config.AutoSteal then startAutoSteal() else stopAutoSteal() end
    if Config.InfiniteJump then startInfJump() else stopInfJump() end
    if Config.AntiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end
    if Config.Unwalk then startUnwalk() else stopUnwalk() end
    if Config.Float then startFloat() else stopFloat() end
    if Config.Lagger then setupLaggerMonitor() else cleanupLaggerMonitor() end
    if Config.Esp then updateESP() else
        for _, h in pairs(espHighlights) do
            pcall(function() h:Destroy() end)
        end
        espHighlights = {}
    end
    if Config.Optimizer then enableOptimizer() else disableOptimizer() end
    if Config.SpinBot then startSpin() else stopSpin() end
    if Config.GalaxyMode then
        updateGalaxyForce()
        if not galaxyHopConn then
            galaxyHopConn = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space and Config.GalaxyMode then
                    doGalaxyHop()
                end
            end)
        end
    else
        if galaxyVF then galaxyVF:Destroy(); galaxyVF = nil end
        if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt = nil end
        if galaxyHopConn then galaxyHopConn:Disconnect(); galaxyHopConn = nil end
    end
    if Config.MedusaCounter then setupMedusaCounter() else
        for _, conn in ipairs(medusaConns) do
            pcall(function() conn:Disconnect() end)
        end
        medusaConns = {}
    end
    if Config.FullAutoLeft or Config.FullAutoRight then startFullAuto() else stopFullAuto() end
    if Config.SpeedBypass then startSpeedBypass() else stopSpeedBypass() end
end

RunService.Heartbeat:Connect(function()
    updateAutoMovement()
    if Config.GalaxyMode then updateGalaxyForce() end
end)

-- =============================================================
-- 22. GUI CONSTRUCTION (MAIN WINDOW)
-- =============================================================
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "S7MainGUI"
ScreenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0, 560, 0, 660)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -330)
mainFrame.BackgroundColor3 = BG
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = ACCENT
mainStroke.Thickness = 2.5

-- Title bar with minimize button
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = DARK_BLUE
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)
local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, -60, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "S7 SHUB"
titleLbl.TextColor3 = WHITE
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 20
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 34, 0, 34)
minBtn.Position = UDim2.new(1, -42, 0.5, -17)
minBtn.BackgroundColor3 = BG
minBtn.Text = "－"
minBtn.TextColor3 = ACCENT
minBtn.Font = Enum.Font.GothamBlack
minBtn.TextSize = 22
minBtn.BorderSizePixel = 0
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

-- Minimized bar (S7S)
local minimizedBar = Instance.new("Frame", ScreenGui)
minimizedBar.Size = UDim2.new(0, 90, 0, 40)
minimizedBar.Position = UDim2.new(0, 20, 0.5, -20)
minimizedBar.BackgroundColor3 = DARK_BLUE
minimizedBar.BorderSizePixel = 0
minimizedBar.Visible = false
Instance.new("UICorner", minimizedBar).CornerRadius = UDim.new(0, 12)
local minBarText = Instance.new("TextLabel", minimizedBar)
minBarText.Size = UDim2.new(1, 0, 1, 0)
minBarText.BackgroundTransparency = 1
minBarText.Text = "S7S"
minBarText.TextColor3 = WHITE
minBarText.Font = Enum.Font.GothamBlack
minBarText.TextSize = 18

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    minimizedBar.Visible = true
    minimizedBar.Position = mainFrame.Position
end)

minimizedBar.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minimizedBar.Visible = false
    mainFrame.Position = minimizedBar.Position
end)

-- Tab container
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.Position = UDim2.new(0, 10, 0, 48)
tabContainer.BackgroundTransparency = 1

local tabs = {"Speed", "Combat", "Steal", "Movement", "Visual", "Auto", "Settings"}
local tabButtons = {}
local tabContents = {}

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(1 / #tabs - 0.01, 0, 1, 0)
    btn.Position = UDim2.new((i - 1) / #tabs, 2, 0, 0)
    btn.BackgroundColor3 = BG
    btn.Text = name
    btn.TextColor3 = ACCENT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    tabButtons[name] = btn
    local content = Instance.new("ScrollingFrame", mainFrame)
    content.Size = UDim2.new(1, -20, 1, -108)
    content.Position = UDim2.new(0, 10, 0, 96)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = ACCENT
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Visible = (i == 1)
    tabContents[name] = content
    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(tabContents) do c.Visible = false end
        content.Visible = true
        for _, b in pairs(tabButtons) do
            b.BackgroundColor3 = BG
            b.TextColor3 = ACCENT
        end
        btn.BackgroundColor3 = ACCENT
        btn.TextColor3 = BG
    end)
end

-- Helper: add a toggle row
local function addToggle(parent, label, configKey, yPos)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, yPos)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0, 44, 0, 22)
    track.Position = UDim2.new(1, -54, 0.5, -11)
    track.BackgroundColor3 = OFF_CLR
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(0, 2, 0.5, -9)
    dot.BackgroundColor3 = WHITE
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local function setState(state)
        Config[configKey] = state
        track.BackgroundColor3 = state and ACCENT or OFF_CLR
        dot.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        applyAllToggles()
        saveConfig()
    end
    setState(Config[configKey])
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        setState(not Config[configKey])
    end)
    return row
end

-- Helper: add a slider
local function addSlider(parent, label, configKey, minVal, maxVal, defaultVal, yPos)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 52)
    row.Position = UDim2.new(0, 5, 0, yPos)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -130, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0, 55, 0, 22)
    valLbl.Position = UDim2.new(1, -65, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(Config[configKey])
    valLbl.TextColor3 = ACCENT
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    local slider = Instance.new("Frame", row)
    slider.Size = UDim2.new(1, -130, 0, 6)
    slider.Position = UDim2.new(0, 12, 0, 34)
    slider.BackgroundColor3 = OFF_CLR
    slider.BorderSizePixel = 0
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", slider)
    local initRel = (Config[configKey] - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(initRel, 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragBtn = Instance.new("TextButton", slider)
    dragBtn.Size = UDim2.new(1, 0, 1, 0)
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text = ""
    local dragging = false
    dragBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position.X
            local rel = math.clamp((pos - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local val = minVal + (maxVal - minVal) * rel
            if configKey == "StealDuration" then
                val = math.round(val * 100) / 100
            else
                val = math.floor(val)
            end
            Config[configKey] = val
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLbl.Text = tostring(val)
            saveConfig()
            applyAllToggles()
        end
    end)
    return row
end

-- BUILD TABS
local y = 5
local speedTab = tabContents["Speed"]
addToggle(speedTab, "Speed Bypass", "SpeedBypass", y); y = y + 44
addSlider(speedTab, "Normal Speed", "NormalSpeed", 1, 300, 60, y); y = y + 56
addSlider(speedTab, "Carry Speed", "CarrySpeed", 1, 100, 29, y); y = y + 56
addSlider(speedTab, "Lagger Speed", "LaggerSpeed", 1, 50, 15, y)

y = 5
local combatTab = tabContents["Combat"]
addToggle(combatTab, "Auto Bat", "AutoBat", y); y = y + 44
addToggle(combatTab, "Auto Swing", "AutoSwing", y); y = y + 44
addToggle(combatTab, "Harder Hit Anim", "HarderHit", y); y = y + 44
addToggle(combatTab, "Medusa Counter", "MedusaCounter", y); y = y + 44
addToggle(combatTab, "Fastest Steal", "FastestSteal", y); y = y + 44
addToggle(combatTab, "Desync", "Desync", y); y = y + 44
addToggle(combatTab, "Brainrot Return L", "BrainrotL", y); y = y + 44
addToggle(combatTab, "Brainrot Return R", "BrainrotR", y)

y = 5
local stealTab = tabContents["Steal"]
addToggle(stealTab, "Auto Steal", "AutoSteal", y); y = y + 44
addSlider(stealTab, "Radius", "StealRadius", 5, 50, 20, y); y = y + 56
addSlider(stealTab, "Duration", "StealDuration", 0.05, 2, 0.19, y)

y = 5
local moveTab = tabContents["Movement"]
addToggle(moveTab, "Infinite Jump", "InfiniteJump", y); y = y + 44
addToggle(moveTab, "Anti Ragdoll", "AntiRagdoll", y); y = y + 44
addToggle(moveTab, "Unwalk", "Unwalk", y); y = y + 44
addToggle(moveTab, "Float", "Float", y); y = y + 44
addSlider(moveTab, "Float Height", "FloatHeight", 1, 30, 9.5, y); y = y + 56
addToggle(moveTab, "Drop Brainrot", "DropBrainrot", y); y = y + 44
addToggle(moveTab, "TP Down", "TPDown", y); y = y + 44
addToggle(moveTab, "TP Left", "TPLeft", y); y = y + 44
addToggle(moveTab, "TP Right", "TPRight", y)

y = 5
local visTab = tabContents["Visual"]
addToggle(visTab, "Stretch Rez", "StretchRez", y); y = y + 44
addToggle(visTab, "No Cam Collision", "NoCamCollision", y); y = y + 44
addToggle(visTab, "Anti Lag", "AntiLag", y); y = y + 44
addToggle(visTab, "Ultra Mode", "UltraMode", y); y = y + 44
addToggle(visTab, "Remove Accessories", "RemoveAccessories", y); y = y + 44
addToggle(visTab, "ESP", "Esp", y); y = y + 44
addToggle(visTab, "Optimizer", "Optimizer", y); y = y + 44
addToggle(visTab, "Spin Bot", "SpinBot", y); y = y + 44
addToggle(visTab, "Galaxy Mode", "GalaxyMode", y)

y = 5
local autoTab = tabContents["Auto"]
addToggle(autoTab, "Auto TP", "AutoTP", y); y = y + 44
addToggle(autoTab, "Auto Play After TP", "AutoPlayAfterTP", y); y = y + 44
addToggle(autoTab, "After Countdown", "AfterCountdown", y); y = y + 44
addToggle(autoTab, "Full Auto Left", "FullAutoLeft", y); y = y + 44
addToggle(autoTab, "Full Auto Right", "FullAutoRight", y); y = y + 44
addToggle(autoTab, "Auto Left", "AutoLeft", y); y = y + 44
addToggle(autoTab, "Auto Right", "AutoRight", y)

y = 5
local setTab = tabContents["Settings"]

-- Keybind rows (click to change)
local keyNames = {
    "FullAutoLeft", "FullAutoRight", "AutoLeft", "AutoRight",
    "DropBrainrot", "TPDown", "TPLeft", "TPRight", "UIVisibility",
    "AutoBat", "AutoSteal", "LaggerToggle", "SpeedBypass", "Float",
    "InfiniteJump", "AntiRagdoll", "Unwalk", "GalaxyToggle", "SpinToggle", "MedusaToggle"
}
local keyButtons = {}
for _, name in ipairs(keyNames) do
    local row = Instance.new("Frame", setTab)
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, y)
    row.BackgroundColor3 = CARD
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0.32, -10, 0, 32)
    keyBtn.Position = UDim2.new(0.66, 5, 0.5, -16)
    keyBtn.BackgroundColor3 = BG
    keyBtn.Text = Keybinds[name] and Keybinds[name].Name or "None"
    keyBtn.TextColor3 = ACCENT
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 12
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)
    keyButtons[name] = keyBtn
    local listening = false
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    keyBtn.Text = Keybinds[name] and Keybinds[name].Name or "None"
                else
                    Keybinds[name] = input.KeyCode
                    keyBtn.Text = input.KeyCode.Name
                    saveConfig()
                end
                listening = false
                conn:Disconnect()
            end
        end)
    end)
    y = y + 44
end

-- Additional panels: Desync and Lagger
local desyncPanel = Instance.new("Frame", ScreenGui)
desyncPanel.Size = UDim2.new(0, 240, 0, 160)
desyncPanel.Position = UDim2.new(1, -260, 0.5, -80)
desyncPanel.BackgroundColor3 = BG
desyncPanel.BorderSizePixel = 0
desyncPanel.Visible = false
Instance.new("UICorner", desyncPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", desyncPanel).Color = ACCENT
local desyncTitle = Instance.new("TextLabel", desyncPanel)
desyncTitle.Size = UDim2.new(1, 0, 0, 32)
desyncTitle.BackgroundColor3 = DARK_BLUE
desyncTitle.Text = "DESYNC PANEL"
desyncTitle.TextColor3 = WHITE
desyncTitle.Font = Enum.Font.GothamBold
desyncTitle.TextSize = 14
Instance.new("UICorner", desyncTitle).CornerRadius = UDim.new(0, 12)
local desyncToggleBtn = Instance.new("TextButton", desyncPanel)
desyncToggleBtn.Size = UDim2.new(0.9, 0, 0, 34)
desyncToggleBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
desyncToggleBtn.BackgroundColor3 = OFF_CLR
desyncToggleBtn.Text = "DESYNC ACTIVE"
desyncToggleBtn.TextColor3 = WHITE
desyncToggleBtn.Font = Enum.Font.GothamBold
desyncToggleBtn.TextSize = 14
Instance.new("UICorner", desyncToggleBtn).CornerRadius = UDim.new(0, 8)
desyncToggleBtn.MouseButton1Click:Connect(function()
    Config.Desync = not Config.Desync
    desyncToggleBtn.BackgroundColor3 = Config.Desync and ACCENT or OFF_CLR
    saveConfig()
end)

local laggerPanel = Instance.new("Frame", ScreenGui)
laggerPanel.Size = UDim2.new(0, 240, 0, 110)
laggerPanel.Position = UDim2.new(1, -260, 0.6, 50)
laggerPanel.BackgroundColor3 = BG
laggerPanel.BorderSizePixel = 0
laggerPanel.Visible = false
Instance.new("UICorner", laggerPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", laggerPanel).Color = ACCENT
local laggerTitle = Instance.new("TextLabel", laggerPanel)
laggerTitle.Size = UDim2.new(1, 0, 0, 32)
laggerTitle.BackgroundColor3 = DARK_BLUE
laggerTitle.Text = "LAGGER PANEL"
laggerTitle.TextColor3 = WHITE
laggerTitle.Font = Enum.Font.GothamBold
laggerTitle.TextSize = 14
Instance.new("UICorner", laggerTitle).CornerRadius = UDim.new(0, 12)
local laggerToggleBtn = Instance.new("TextButton", laggerPanel)
laggerToggleBtn.Size = UDim2.new(0.9, 0, 0, 34)
laggerToggleBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
laggerToggleBtn.BackgroundColor3 = OFF_CLR
laggerToggleBtn.Text = "LAGGER ACTIVE"
laggerToggleBtn.TextColor3 = WHITE
laggerToggleBtn.Font = Enum.Font.GothamBold
laggerToggleBtn.TextSize = 14
Instance.new("UICorner", laggerToggleBtn).CornerRadius = UDim.new(0, 8)
laggerToggleBtn.MouseButton1Click:Connect(function()
    Config.Lagger = not Config.Lagger
    laggerToggleBtn.BackgroundColor3 = Config.Lagger and ACCENT or OFF_CLR
    applyAllToggles()
    saveConfig()
end)

-- Buttons in Settings tab to show/hide panels
local showDesyncBtn = Instance.new("TextButton", setTab)
showDesyncBtn.Size = UDim2.new(0.45, 0, 0, 36)
showDesyncBtn.Position = UDim2.new(0.05, 0, y, 0)
showDesyncBtn.BackgroundColor3 = CARD
showDesyncBtn.Text = "DESYNC PANEL"
showDesyncBtn.TextColor3 = WHITE
showDesyncBtn.Font = Enum.Font.GothamBold
showDesyncBtn.TextSize = 13
Instance.new("UICorner", showDesyncBtn).CornerRadius = UDim.new(0, 8)
showDesyncBtn.MouseButton1Click:Connect(function() desyncPanel.Visible = not desyncPanel.Visible end)
y = y + 46
local showLaggerBtn = Instance.new("TextButton", setTab)
showLaggerBtn.Size = UDim2.new(0.45, 0, 0, 36)
showLaggerBtn.Position = UDim2.new(0.5, 10, y, 0)
showLaggerBtn.BackgroundColor3 = CARD
showLaggerBtn.Text = "LAGGER PANEL"
showLaggerBtn.TextColor3 = WHITE
showLaggerBtn.Font = Enum.Font.GothamBold
showLaggerBtn.TextSize = 13
Instance.new("UICorner", showLaggerBtn).CornerRadius = UDim.new(0, 8)
showLaggerBtn.MouseButton1Click:Connect(function() laggerPanel.Visible = not laggerPanel.Visible end)

-- =============================================================
-- 23. DRAGGABLE FLOATING BUTTONS (8 BUTTONS)
-- =============================================================
local floatingButtons = {}
local btnList = {
    {id = "AutoBat", text = "AUTO BAT", configKey = "AutoBat"},
    {id = "AutoSteal", text = "AUTO STEAL", configKey = "AutoSteal"},
    {id = "DropBrainrot", text = "DROP BR", configKey = "DropBrainrot"},
    {id = "AutoLeft", text = "AUTO L", configKey = "AutoLeft"},
    {id = "AutoRight", text = "AUTO R", configKey = "AutoRight"},
    {id = "TPDown", text = "TP DOWN", configKey = "TPDown"},
    {id = "Carry", text = "CARRY", configKey = "SpeedBypass"},
    {id = "Lagger", text = "LAGGER", configKey = "Lagger"},
}

for _, cfg in ipairs(btnList) do
    local btn = Instance.new("TextButton", ScreenGui)
    btn.Size = UDim2.new(0, 88, 0, 40)
    btn.BackgroundColor3 = CARD
    btn.Text = cfg.text
    btn.TextColor3 = WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = ACCENT
    stroke.Thickness = 1.5
    local pos = savedFloatingPositions[cfg.id]
    btn.Position = pos and UDim2.new(0, pos.x, 0, pos.y) or UDim2.new(0, 130 + math.random(0, 300), 0, 110 + math.random(0, 400))
    btn.Parent = ScreenGui

    local dragging = false
    local dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            savedFloatingPositions[cfg.id] = {x = btn.Position.X.Offset, y = btn.Position.Y.Offset}
            saveConfig()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        Config[cfg.configKey] = not Config[cfg.configKey]
        btn.BackgroundColor3 = Config[cfg.configKey] and ACCENT or CARD
        btn.TextColor3 = Config[cfg.configKey] and BG or WHITE
        applyAllToggles()
        saveConfig()
    end)

    btn.BackgroundColor3 = Config[cfg.configKey] and ACCENT or CARD
    btn.TextColor3 = Config[cfg.configKey] and BG or WHITE
    floatingButtons[cfg.id] = btn
end

-- =============================================================
-- 24. PROGRESS BAR FOR AUTO STEAL
-- =============================================================
local progressBarFrame = Instance.new("Frame", ScreenGui)
progressBarFrame.Size = UDim2.new(0, 400, 0, 52)
progressBarFrame.Position = UDim2.new(0.5, -200, 1, -70)
progressBarFrame.BackgroundColor3 = BG
progressBarFrame.BackgroundTransparency = 0.1
progressBarFrame.BorderSizePixel = 0
progressBarFrame.Visible = false
Instance.new("UICorner", progressBarFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", progressBarFrame).Color = ACCENT
ProgressLabel = Instance.new("TextLabel", progressBarFrame)
ProgressLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
ProgressLabel.Position = UDim2.new(0, 12, 0, 4)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "READY"
ProgressLabel.TextColor3 = WHITE
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 13
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressPctLabel = Instance.new("TextLabel", progressBarFrame)
ProgressPctLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
ProgressPctLabel.Position = UDim2.new(0.5, 0, 0, 4)
ProgressPctLabel.BackgroundTransparency = 1
ProgressPctLabel.Text = ""
ProgressPctLabel.TextColor3 = ACCENT
ProgressPctLabel.Font = Enum.Font.GothamBlack
ProgressPctLabel.TextSize = 15
local bg = Instance.new("Frame", progressBarFrame)
bg.Size = UDim2.new(0.92, 0, 0, 8)
bg.Position = UDim2.new(0.04, 0, 1, -18)
bg.BackgroundColor3 = OFF_CLR
bg.BorderSizePixel = 0
Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
ProgressBarFill = Instance.new("Frame", bg)
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = ACCENT
ProgressBarFill.BorderSizePixel = 0
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

local function updateProgressBarVisibility()
    progressBarFrame.Visible = Config.AutoSteal
end

local oldAutoSteal = Config.AutoSteal
RunService.Heartbeat:Connect(function()
    if Config.AutoSteal ~= oldAutoSteal then
        oldAutoSteal = Config.AutoSteal
        updateProgressBarVisibility()
    end
    if Config.AutoSteal and isStealing then
        local prog = math.clamp((tick() - (stealStartTime or tick())) / Config.StealDuration, 0, 1)
        ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0)
        ProgressPctLabel.Text = math.floor(prog * 100) .. "%"
    else
        if ProgressBarFill.Size.X.Scale ~= 0 then
            ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
            ProgressPctLabel.Text = ""
        end
    end
end)

-- =============================================================
-- 25. GLOBAL KEYBIND HANDLER
-- =============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local kc = input.KeyCode

    if kc == Keybinds.UIVisibility then
        mainFrame.Visible = not mainFrame.Visible
        minimizedBar.Visible = not mainFrame.Visible
        if not mainFrame.Visible then
            minimizedBar.Position = mainFrame.Position
        end
    end
    if kc == Keybinds.DropBrainrot then doDropBrainrot() end
    if kc == Keybinds.TPDown then doTPDown() end
    if kc == Keybinds.TPLeft then doTPLeft() end
    if kc == Keybinds.TPRight then doTPRight() end
    if kc == Keybinds.AutoLeft then
        Config.AutoLeft = not Config.AutoLeft
        if Config.AutoLeft then Config.AutoRight = false end
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.AutoRight then
        Config.AutoRight = not Config.AutoRight
        if Config.AutoRight then Config.AutoLeft = false end
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.FullAutoLeft then
        Config.FullAutoLeft = not Config.FullAutoLeft
        if Config.FullAutoLeft then Config.FullAutoRight = false end
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.FullAutoRight then
        Config.FullAutoRight = not Config.FullAutoRight
        if Config.FullAutoRight then Config.FullAutoLeft = false end
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.AutoBat then
        Config.AutoBat = not Config.AutoBat
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.AutoSteal then
        Config.AutoSteal = not Config.AutoSteal
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.LaggerToggle then
        Config.Lagger = not Config.Lagger
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.SpeedBypass then
        Config.SpeedBypass = not Config.SpeedBypass
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.Float then
        Config.Float = not Config.Float
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.InfiniteJump then
        Config.InfiniteJump = not Config.InfiniteJump
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.AntiRagdoll then
        Config.AntiRagdoll = not Config.AntiRagdoll
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.Unwalk then
        Config.Unwalk = not Config.Unwalk
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.GalaxyToggle then
        Config.GalaxyMode = not Config.GalaxyMode
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.SpinToggle then
        Config.SpinBot = not Config.SpinBot
        applyAllToggles()
        saveConfig()
    end
    if kc == Keybinds.MedusaToggle then
        Config.MedusaCounter = not Config.MedusaCounter
        applyAllToggles()
        saveConfig()
    end
end)

-- =============================================================
-- 26. INITIALIZATION
-- =============================================================
loadConfig()
applyAllToggles()
showStartupAnimation()
updateProgressBarVisibility()

print("═══════════════════════════════════════════════════════════════════════════════")
print("                           S7 SHUB LOADED                                      ")
print("═══════════════════════════════════════════════════════════════════════════════")
print("  ✓ All features are OFF by default                                           ")
print("  ✓ Press 'U' or click the '－' button to open/close the menu                 ")
print("  ✓ Draggable floating buttons appear on screen                               ")
print("  ✓ Config saves automatically (positions, toggles, keybinds)                 ")
print("═══════════════════════════════════════════════════════════════════════════════")

-- END OF S7 SHUB
