-- S7 SHUB - Black & Blue Edition (KRIX HUB Style)
-- Features: Lock (Bat Aimbot), Auto Steal, Lagger, Taunt (/lol S7 Shub😂😂), Auto Grab
-- All buttons draggable, minimizable windows, start animation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ==================== COLORS (Black & Blue) ====================
local ACCENT = Color3.fromRGB(0, 150, 255)      -- Geiles Blau
local DARK_BLUE = Color3.fromRGB(0, 80, 150)
local BG_DARK = Color3.fromRGB(6, 6, 10)
local BG_CARD = Color3.fromRGB(12, 12, 18)
local TEXT_BRIGHT = Color3.fromRGB(235, 235, 245)
local TEXT_DIM = Color3.fromRGB(150, 150, 170)

-- ==================== START ANIMATION ====================
local startGui = Instance.new("ScreenGui")
startGui.Name = "S7StartAnimation"
startGui.ResetOnSpawn = false
startGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
startGui.Parent = player:WaitForChild("PlayerGui")

local startFrame = Instance.new("Frame")
startFrame.Size = UDim2.new(1, 0, 1, 0)
startFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
startFrame.BackgroundTransparency = 0
startFrame.BorderSizePixel = 0
startFrame.Parent = startGui

local startText = Instance.new("TextLabel")
startText.Size = UDim2.new(1, 0, 1, 0)
startText.BackgroundTransparency = 1
startText.Text = "🤫 S7 SHUB ⚡"
startText.TextColor3 = ACCENT
startText.Font = Enum.Font.GothamBlack
startText.TextSize = 45
startText.TextScaled = true
startText.Parent = startFrame

startText.TextStrokeTransparency = 0
startText.TextStrokeColor3 = Color3.fromRGB(0, 100, 200)

-- Animation
startFrame.BackgroundTransparency = 0
startText.TextTransparency = 0
startText.TextScaled = true

task.spawn(function()
    for i = 1, 20 do
        local scale = 0.8 + (i / 20) * 0.6
        startText.TextScaled = false
        startText.TextSize = 30 + i * 2
        task.wait(0.03)
    end
    task.wait(1)
    for i = 1, 10 do
        startFrame.BackgroundTransparency = i / 10
        startText.TextTransparency = i / 10
        task.wait(0.05)
    end
    startGui:Destroy()
end)

-- ==================== LAGGER VARIABLES ====================
local laggerActive = false
local laggerSlowSpeed = 10.5
local laggerNormalSpeed = 12
local laggerMonitorConns = {}

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

local function setLaggerSpeed(speed)
    laggerNormalSpeed = speed
    if laggerActive then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = speed end
        end
    end
end

-- ==================== BAT AIMBOT (LOCK) ====================
local autoBatEnabled = false
local autoSwingEnabled = true
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12
local aimbotConnection = nil
local lockedTarget = nil
local BAT_ENGAGE_RANGE = 5
local AIMBOT_SPEED = 60
local MELEE_OFFSET = 3
local HarderHitAnim = false
local MedusaCounter = false
local DesyncActive = false
local BrainrotReturnL = false
local BrainrotReturnR = false

local SlapList = {"Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap", "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap", "Nuclear Slap", "Galaxy Slap", "Glitched Slap"}

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

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local ff = targetChar:FindFirstChildOfClass("ForceField")
    return hum and hrp and hum.Health > 0 and not ff
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist = math.huge
    local newTargetChar = nil
    local newTargetHRP = nil
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and isTargetValid(targetPlayer.Character) then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local distance = (targetHRP.Position - myHRP.Position).Magnitude
            if distance < shortestDist then
                shortestDist = distance
                newTargetHRP = targetHRP
                newTargetChar = targetPlayer.Character
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

local function startBatAimbot()
    if aimbotConnection then return end
    local c = player.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not h or not hum then return end
    hum.AutoRotate = false
    
    local attachment = h:FindFirstChild("AimbotAttachment") or Instance.new("Attachment", h)
    attachment.Name = "AimbotAttachment"
    local align = h:FindFirstChild("AimbotAlign") or Instance.new("AlignOrientation", h)
    align.Name = "AimbotAlign"
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = attachment
    align.MaxTorque = math.huge
    align.Responsiveness = 200
    
    autoBatEnabled = true
    aimbotConnection = RunService.Heartbeat:Connect(function()
        if not autoBatEnabled then return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local currentHRP = player.Character.HumanoidRootPart
        local currentHum = player.Character:FindFirstChildOfClass("Humanoid")
        local bat = findBat()
        if bat and bat.Parent ~= player.Character then
            pcall(function() currentHum:EquipTool(bat) end)
        end
        local targetHRP, targetChar = getBestTarget(currentHRP)
        if targetHRP and targetChar then
            local targetVelocity = targetHRP.AssemblyLinearVelocity
            local speed = targetVelocity.Magnitude
            local dynamicPredictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + (targetVelocity * dynamicPredictTime)
            local dirToTarget = (predictedPos - currentHRP.Position)
            local distance3D = dirToTarget.Magnitude
            local targetStandPos = predictedPos
            if distance3D > 0 then
                targetStandPos = predictedPos - (dirToTarget.Unit * MELEE_OFFSET)
            end
            align.CFrame = CFrame.lookAt(currentHRP.Position, predictedPos)
            local moveDir = (targetStandPos - currentHRP.Position)
            local distToStandPos = moveDir.Magnitude
            if distToStandPos > 1 then
                currentHRP.AssemblyLinearVelocity = moveDir.Unit * AIMBOT_SPEED
            else
                currentHRP.AssemblyLinearVelocity = targetVelocity
            end
            if distToStandPos <= BAT_ENGAGE_RANGE then
                if bat and bat.Parent == player.Character then
                    pcall(function() bat:Activate() end)
                end
            end
        else
            lockedTarget = nil
            currentHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function stopBatAimbot()
    autoBatEnabled = false
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    local c = player.Character
    local h = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        local att = h:FindFirstChild("AimbotAttachment")
        if att then att:Destroy() end
        local al = h:FindFirstChild("AimbotAlign")
        if al then al:Destroy() end
        h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    if hum then hum.AutoRotate = true end
    lockedTarget = nil
end

-- ==================== AUTO GRAB (vom zweiten Script) ====================
local autoGrabEnabled = false
local autoGrabConn = nil
local GRAB_RADIUS = 20

local function findGrabbableItems()
    local items = {}
    local char = player.Character
    if not char then return items end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return items end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("BasePart") and obj.Name:lower():find("grab")) then
            if obj.Parent ~= char then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist <= GRAB_RADIUS then
                    table.insert(items, obj)
                end
            end
        end
    end
    return items
end

local function startAutoGrab()
    if autoGrabConn then return end
    autoGrabConn = RunService.Heartbeat:Connect(function()
        if not autoGrabEnabled then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        local items = findGrabbableItems()
        for _, item in ipairs(items) do
            if item and item.Parent and item.Parent ~= char then
                local dist = (hrp.Position - item.Position).Magnitude
                if dist <= GRAB_RADIUS then
                    local tool = item
                    if tool:IsA("Tool") then
                        local bp = player:FindFirstChildOfClass("Backpack")
                        if tool.Parent ~= char and tool.Parent ~= bp then
                            local grabDistance = (hrp.Position - tool.Position).Magnitude
                            if grabDistance <= 10 then
                                pcall(function()
                                    fireproximityprompt(tool:FindFirstChildWhichIsA("ProximityPrompt"))
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopAutoGrab()
    if autoGrabConn then
        autoGrabConn:Disconnect()
        autoGrabConn = nil
    end
end

-- ==================== TAUNT (vom zweiten Script) ====================
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
                    end
                else
                    local TCS = game:GetService("TextChatService")
                    local ch = TCS.TextChannels:FindFirstChild("RBXGeneral")
                    if ch then
                        ch:SendAsync("/lol S7 Shub😂😂")
                    end
                end
            end)
            task.wait(0.5)
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

-- ==================== AUTO STEAL (Progress Bar) ====================
local autoStealEnabled = false
local isStealing = false
local stealStartTime = nil
local autoStealConn = nil
local progressConn = nil
local STEAL_RADIUS = 20
local STEAL_DURATION = 0.35
local animalCache = {}
local promptCache = {}
local stealCache = {}
local ProgressBarFill = nil
local ProgressLabel = nil
local ProgressPctLabel = nil

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
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = "STEALING..." end
    if progressConn then progressConn:Disconnect() end
    progressConn = RunService.Heartbeat:Connect(function()
        if not isStealing then
            if progressConn then progressConn:Disconnect(); progressConn = nil end
            return
        end
        local prog = math.clamp((tick() - stealStartTime) / STEAL_DURATION, 0, 1)
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end
        if ProgressPctLabel then ProgressPctLabel.Text = math.floor(prog * 100) .. "%" end
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if progressConn then progressConn:Disconnect(); progressConn = nil end
        if ProgressLabel then ProgressLabel.Text = "READY" end
        if ProgressPctLabel then ProgressPctLabel.Text = "" end
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
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
        if not autoStealEnabled or isStealing then return end
        local target = nearestAnimal()
        if not target then return end
        local h = getHRP()
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

local function stopAutoSteal()
    if autoStealConn then autoStealConn:Disconnect(); autoStealConn = nil end
    isStealing = false
    if progressConn then progressConn:Disconnect(); progressConn = nil end
    if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
    if ProgressLabel then ProgressLabel.Text = "READY" end
    if ProgressPctLabel then ProgressPctLabel.Text = "" end
end

-- Cache animals periodically
task.spawn(function()
    task.wait(2)
    while task.wait(5) do
        animalCache = {}
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

-- ==================== MOVEMENT VARIABLES ====================
NORMAL_SPEED = 60
SLOW_SPEED = 29
AIMBOT_SPEED = 60

POS_L1 = Vector3.new(-476.48, -6.28, 92.73)
POS_L2 = Vector3.new(-483.12, -4.95, 94.80)
POS_R1 = Vector3.new(-476.16, -6.52, 25.62)
POS_R2 = Vector3.new(-483.04, -5.09, 23.14)
LFINAL = Vector3.new(-473.38, -8.40, 22.34)
RFINAL = Vector3.new(-476.17, -7.91, 97.91)

aplOn = false
aprOn = false
aplPhase = 1
aprPhase = 1
aplConn = nil
aprConn = nil
autoLOn = false
autoROn = false
autoLConn = nil
autoRConn = nil
autoLPhase = 1
autoRPhase = 1
antiRagdollEnabled = false
unwalkEnabled = false
unwalkConn = nil
galaxyEnabled = false
hopsEnabled = false
galaxyVF = nil
galaxyAtt = nil
DEFAULT_GRAVITY = 196.2
GALAXY_GRAVITY = 42
GALAXY_HOP = 35
HOP_COOLDOWN = 0.08
lastHop = 0
spaceHeld = false
spinBotEnabled = false
spinBAV = nil
SPIN_SPEED = 19
espEnabled = true
espConns = {}
optimizerEnabled = false
xrayOrig = {}
fovValue = 70
fovConn = nil
slowDownEnabled = true
infJumpEnabled = true
INF_JUMP_FORCE = 54
CLAMP_FALL = 80
FloatEnabled = false
FloatHeight = 9.5
DropBrainrotEnabled = false
TPMode = false
StretchRez = false
NoCamCollision = false
AntiLag = false
UltraMode = false
RemoveAccessories = false
DesyncPanelActive = false
LaggerPanelActive = false
SpeedBypass = false
gChar = nil
gHum = nil
gHrp = nil
toggleSetters = {}
mobBtnRefs = {}
AntiRagdollConns = {}
CONFIG_KEY = "S7_Shub_Config"
autoSaveEnabled = false

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ==================== MOVEMENT FUNCTIONS ====================
local function doTPDown()
    task.spawn(function()
        pcall(function()
            local c = player.Character
            if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {c}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -600, 0), rp)
            if hit then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                local hh = hum.HipHeight or 2
                local hy = hrp.Size.Y / 2
                hrp.CFrame = CFrame.new(hit.Position.X, hit.Position.Y + hh + hy + 0.1, hit.Position.Z)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end)
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local h = getHRP()
    if not h then return end
    h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, INF_JUMP_FORCE, h.AssemblyLinearVelocity.Z)
end)

RunService.Heartbeat:Connect(function()
    if not infJumpEnabled then return end
    local h = getHRP()
    if not h then return end
    if h.AssemblyLinearVelocity.Y < -CLAMP_FALL then
        h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, -CLAMP_FALL, h.AssemblyLinearVelocity.Z)
    end
end)

-- Float
local floatConn = nil
local function startFloat()
    if floatConn then return end
    floatConn = RunService.Heartbeat:Connect(function()
        if not FloatEnabled then
            if floatConn then floatConn:Disconnect(); floatConn = nil end
            return
        end
        local h = getHRP()
        if not h then return end
        if h.AssemblyLinearVelocity.Y < 0 and h.AssemblyLinearVelocity.Y > -FloatHeight then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, -FloatHeight, h.AssemblyLinearVelocity.Z)
        end
    end)
end

local function stopFloat()
    if floatConn then floatConn:Disconnect(); floatConn = nil end
end

-- Drop/Fling
local _wfConns = {}
local _wfActive = false

local function startWalkFling()
    _wfActive = true
    table.insert(_wfConns, RunService.Stepped:Connect(function()
        if not _wfActive then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end))
    local co = coroutine.create(function()
        while _wfActive do
            RunService.Heartbeat:Wait()
            local c = player.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            if not root then RunService.Heartbeat:Wait(); continue end
            local vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if root and root.Parent then root.Velocity = vel end
            RunService.Stepped:Wait()
            if root and root.Parent then root.Velocity = vel + Vector3.new(0, 0.1, 0) end
        end
    end)
    coroutine.resume(co)
    table.insert(_wfConns, co)
end

local function stopWalkFling()
    _wfActive = false
    for _, c in ipairs(_wfConns) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        elseif typeof(c) == "thread" then
            pcall(task.cancel, c)
        end
    end
    _wfConns = {}
end

local function doDrop()
    startWalkFling()
    task.delay(0.4, stopWalkFling)
end

local function doDropBrainrot()
    local char = player.Character
    if not char then return end
    local brainrot = char:FindFirstChild("Brainrot")
    if brainrot then
        brainrot:Destroy()
    end
end

-- Anti Ragdoll
local function startAntiRagdoll()
    if #AntiRagdollConns > 0 then return end
    local c = player.Character or player.CharacterAdded:Wait()
    local humanoid = c:WaitForChild("Humanoid")
    local root = c:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")
    local maxVelocity = 40
    local clampVelocity = 25
    local maxClamp = 15
    local lastVelocity = Vector3.new(0, 0, 0)

    local function IsRagdollState()
        local state = humanoid:GetState()
        return state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.GettingUp
    end

    local function CleanRagdollEffects()
        for _, obj in pairs(c:GetDescendants()) do
            if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") or (obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B")) then
                obj:Destroy()
            elseif obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                obj:Destroy()
            elseif obj:IsA("Motor6D") then
                obj.Enabled = true
            end
        end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local animName = track.Animation and track.Animation.Name:lower() or ""
            if animName:find("rag") or animName:find("fall") or animName:find("hurt") or animName:find("down") then
                track:Stop(0)
            end
        end
    end

    local function ReEnableControls()
        pcall(function()
            require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Enable()
        end)
    end

    table.insert(AntiRagdollConns, humanoid.StateChanged:Connect(function()
        if IsRagdollState() then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            CleanRagdollEffects()
            workspace.CurrentCamera.CameraSubject = humanoid
            ReEnableControls()
        end
    end))

    table.insert(AntiRagdollConns, RunService.Heartbeat:Connect(function()
        if not antiRagdollEnabled then return end
        if IsRagdollState() then
            CleanRagdollEffects()
            local vel = root.AssemblyLinearVelocity
            if (vel - lastVelocity).Magnitude > maxVelocity and vel.Magnitude > clampVelocity then
                root.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude, maxClamp)
            end
            lastVelocity = vel
        end
    end))

    table.insert(AntiRagdollConns, c.DescendantAdded:Connect(function()
        if IsRagdollState() then CleanRagdollEffects() end
    end))

    table.insert(AntiRagdollConns, player.CharacterAdded:Connect(function(newChar)
        c = newChar
        humanoid = newChar:WaitForChild("Humanoid")
        root = newChar:WaitForChild("HumanoidRootPart")
        animator = humanoid:WaitForChild("Animator")
        lastVelocity = Vector3.new(0, 0, 0)
        ReEnableControls()
        CleanRagdollEffects()
    end))

    ReEnableControls()
    CleanRagdollEffects()
end

local function stopAntiRagdoll()
    for _, conn in pairs(AntiRagdollConns) do
        conn:Disconnect()
    end
    AntiRagdollConns = {}
end

-- Unwalk
local function startUnwalk()
    if not gChar then return end
    local h2 = gChar:FindFirstChildOfClass("Humanoid")
    if not h2 then return end
    local anim = h2:FindFirstChildOfClass("Animator")
    if not anim then return end
    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
        t:Stop(0)
    end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not unwalkEnabled then
            if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end
            return
        end
        local c = player.Character
        if not c then return end
        local hh = c:FindFirstChildOfClass("Humanoid")
        if not hh then return end
        local an = hh:FindFirstChildOfClass("Animator")
        if not an then return end
        for _, t in ipairs(an:GetPlayingAnimationTracks()) do
            t:Stop(0)
        end
    end)
end

local function stopUnwalk()
    if unwalkConn then
        unwalkConn:Disconnect()
        unwalkConn = nil
    end
end

-- Auto Left/Right Movement
local function stopAutoL()
    autoLOn = false
    if autoLConn then autoLConn:Disconnect(); autoLConn = nil end
    autoLPhase = 1
    local hh = getHum()
    if hh then hh:Move(Vector3.zero, false) end
    local h = getHRP()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
end

local function stopAutoR()
    autoROn = false
    if autoRConn then autoRConn:Disconnect(); autoRConn = nil end
    autoRPhase = 1
    local hh = getHum()
    if hh then hh:Move(Vector3.zero, false) end
    local h = getHRP()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
end

local function startAutoL()
    if autoLConn then autoLConn:Disconnect() end
    autoLPhase = 1
    local pts = {POS_L1, POS_L2, LFINAL}
    autoLConn = RunService.Heartbeat:Connect(function()
        if not autoLOn or not gHrp or not gHum then return end
        local ph = autoLPhase
        local tgt = pts[ph]
        local spd = ph >= 2 and SLOW_SPEED or NORMAL_SPEED
        local flat = Vector3.new(tgt.X - gHrp.Position.X, 0, tgt.Z - gHrp.Position.Z)
        if flat.Magnitude < 1 then
            if ph == #pts then
                gHum:Move(Vector3.zero, false)
                gHrp.AssemblyLinearVelocity = Vector3.zero
                autoLOn = false
                stopAutoL()
                local info = mobBtnRefs["Auto Left"]
                if info and info.btn then
                    info.btn.BackgroundColor3 = BG_DARK
                    info.state = false
                end
                if toggleSetters["Auto Left"] then toggleSetters["Auto Left"](false) end
                return
            end
            autoLPhase = ph + 1
        else
            local md = flat.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * spd, gHrp.AssemblyLinearVelocity.Y, md.Z * spd)
        end
    end)
end

local function startAutoR()
    if autoRConn then autoRConn:Disconnect() end
    autoRPhase = 1
    local pts = {POS_R1, POS_R2, RFINAL}
    autoRConn = RunService.Heartbeat:Connect(function()
        if not autoROn or not gHrp or not gHum then return end
        local ph = autoRPhase
        local tgt = pts[ph]
        local spd = ph >= 2 and SLOW_SPEED or NORMAL_SPEED
        local flat = Vector3.new(tgt.X - gHrp.Position.X, 0, tgt.Z - gHrp.Position.Z)
        if flat.Magnitude < 1 then
            if ph == #pts then
                gHum:Move(Vector3.zero, false)
                gHrp.AssemblyLinearVelocity = Vector3.zero
                autoROn = false
                stopAutoR()
                local info = mobBtnRefs["Auto Right"]
                if info and info.btn then
                    info.btn.BackgroundColor3 = BG_DARK
                    info.state = false
                end
                if toggleSetters["Auto Right"] then toggleSetters["Auto Right"](false) end
                return
            end
            autoRPhase = ph + 1
        else
            local md = flat.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * spd, gHrp.AssemblyLinearVelocity.Y, md.Z * spd)
        end
    end)
end

-- Auto Play Left/Right
local function stopAutoPlayLeft()
    aplOn = false
    if aplConn then aplConn:Disconnect(); aplConn = nil end
    aplPhase = 1
    local hh = getHum()
    if hh then hh:Move(Vector3.zero, false) end
    local h = getHRP()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
end

local function stopAutoPlayRight()
    aprOn = false
    if aprConn then aprConn:Disconnect(); aprConn = nil end
    aprPhase = 1
    local hh = getHum()
    if hh then hh:Move(Vector3.zero, false) end
    local h = getHRP()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
end

local function startAutoPlayLeft()
    if aplConn then aplConn:Disconnect() end
    aplPhase = 1
    aplConn = RunService.Heartbeat:Connect(function()
        if not aplOn or not gHrp or not gHum then return end
        if aplPhase == 1 then
            local d = Vector3.new(POS_L1.X - gHrp.Position.X, 0, POS_L1.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then aplPhase = 2 return end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * NORMAL_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * NORMAL_SPEED)
        elseif aplPhase == 2 then
            local d = Vector3.new(POS_L2.X - gHrp.Position.X, 0, POS_L2.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then
                aplPhase = 0
                gHum:Move(Vector3.zero, false)
                gHrp.AssemblyLinearVelocity = Vector3.zero
                task.delay(0.1, function() if aplOn then aplPhase = 3 end end)
                return
            end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * NORMAL_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * NORMAL_SPEED)
        elseif aplPhase == 0 then
            return
        elseif aplPhase == 3 then
            local d = Vector3.new(POS_L1.X - gHrp.Position.X, 0, POS_L1.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then aplPhase = 4 return end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * SLOW_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * SLOW_SPEED)
        elseif aplPhase == 4 then
            local d = Vector3.new(LFINAL.X - gHrp.Position.X, 0, LFINAL.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then
                gHum:Move(Vector3.zero, false)
                gHrp.AssemblyLinearVelocity = Vector3.zero
                stopAutoPlayLeft()
                return
            end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * SLOW_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * SLOW_SPEED)
        end
    end)
end

local function startAutoPlayRight()
    if aprConn then aprConn:Disconnect() end
    aprPhase = 1
    aprConn = RunService.Heartbeat:Connect(function()
        if not aprOn or not gHrp or not gHum then return end
        if aprPhase == 1 then
            local d = Vector3.new(POS_R1.X - gHrp.Position.X, 0, POS_R1.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then aprPhase = 2 return end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * NORMAL_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * NORMAL_SPEED)
        elseif aprPhase == 2 then
            local d = Vector3.new(POS_R2.X - gHrp.Position.X, 0, POS_R2.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then
                aprPhase = 0
                gHum:Move(Vector3.zero, false)
                gHrp.AssemblyLinearVelocity = Vector3.zero
                task.delay(0.1, function() if aprOn then aprPhase = 3 end end)
                return
            end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * NORMAL_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * NORMAL_SPEED)
        elseif aprPhase == 0 then
            return
        elseif aprPhase == 3 then
            local d = Vector3.new(POS_R1.X - gHrp.Position.X, 0, POS_R1.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then aprPhase = 4 return end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * SLOW_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * SLOW_SPEED)
        elseif aprPhase == 4 then
            local d = Vector3.new(RFINAL.X - gHrp.Position.X, 0, RFINAL.Z - gHrp.Position.Z)
            if d.Magnitude < 1 then
                gHum:Move(Vector3.zero, false)
                gHrp.AssemblyLinearVelocity = Vector3.zero
                stopAutoPlayRight()
                return
            end
            local md = d.Unit
            gHum:Move(md, false)
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * SLOW_SPEED, gHrp.AssemblyLinearVelocity.Y, md.Z * SLOW_SPEED)
        end
    end)
end

-- ESP
local function createESP(plr)
    if plr == player or not plr.Character then return end
    local c = plr.Character
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local head = c:FindFirstChild("Head")
    if not head then return end
    if c:FindFirstChild("S7HubESP") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "S7HubESP"
    box.Adornee = root
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = ACCENT
    box.Transparency = 0.45
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Parent = c
    local bb = Instance.new("BillboardGui")
    bb.Name = "S7HubESP_Name"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 45)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = c
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = plr.DisplayName
    lbl.TextColor3 = TEXT_BRIGHT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextStrokeTransparency = 0.5
    lbl.TextStrokeColor3 = DARK_BLUE
    lbl.Parent = bb
end

local function removeESP(plr)
    if not plr.Character then return end
    local b = plr.Character:FindFirstChild("S7HubESP")
    local n = plr.Character:FindFirstChild("S7HubESP_Name")
    if b then b:Destroy() end
    if n then n:Destroy() end
end

local function enableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if plr.Character then
                pcall(function() createESP(plr) end)
            end
            table.insert(espConns, plr.CharacterAdded:Connect(function()
                task.wait(0.1)
                if espEnabled then
                    pcall(function() createESP(plr) end)
                end
            end))
        end
    end
    table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
        if plr == player then return end
        table.insert(espConns, plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            if espEnabled then
                pcall(function() createESP(plr) end)
            end
        end))
    end))
end

local function disableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        pcall(function() removeESP(plr) end)
    end
    for _, c in ipairs(espConns) do
        if c and c.Connected then
            c:Disconnect()
        end
    end
    espConns = {}
end

-- Optimizer
local function enableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness = 2
        Lighting.FogEnd = 9e9
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") then
                fx.Enabled = false
            end
        end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                    obj:Destroy()
                elseif obj:IsA("SelectionBox") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                    for _, ch in ipairs(obj:GetChildren()) do
                        if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then
                            ch:Destroy()
                        end
                    end
                elseif obj:IsA("Sky") then
                    obj:Destroy()
                end
            end)
        end
    end)
end

local function disableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        Lighting.GlobalShadows = true
    end)
end

-- FOV
local function applyFOV()
    if fovConn then fovConn:Disconnect() end
    fovConn = RunService.RenderStepped:Connect(function()
        workspace.CurrentCamera.FieldOfView = fovValue
    end)
end

-- Galaxy Mode
local function setupGalaxyForce()
    local h = getHRP()
    if not h then return end
    if galaxyVF then galaxyVF:Destroy() end
    if galaxyAtt then galaxyAtt:Destroy() end
    galaxyAtt = Instance.new("Attachment")
    galaxyAtt.Parent = h
    galaxyVF = Instance.new("VectorForce")
    galaxyVF.Attachment0 = galaxyAtt
    galaxyVF.ApplyAtCenterOfMass = true
    galaxyVF.RelativeTo = Enum.ActuatorRelativeTo.World
    galaxyVF.Force = Vector3.zero
    galaxyVF.Parent = h
end

local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVF or not gChar then return end
    local mass = 0
    for _, p in ipairs(gChar:GetDescendants()) do
        if p:IsA("BasePart") then
            mass = mass + p:GetMass()
        end
    end
    local tg = DEFAULT_GRAVITY * (GALAXY_GRAVITY / 100)
    galaxyVF.Force = Vector3.new(0, mass * (DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function startGalaxy()
    galaxyEnabled = true
    hopsEnabled = true
    pcall(setupGalaxyForce)
end

local function stopGalaxy()
    galaxyEnabled = false
    hopsEnabled = false
    if galaxyVF then galaxyVF:Destroy(); galaxyVF = nil end
    if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt = nil end
end

local function doHop()
    local h = getHRP()
    local hh = getHum()
    if not h or not hh then return end
    if tick() - lastHop < HOP_COOLDOWN then return end
    lastHop = tick()
    if hh.FloorMaterial == Enum.Material.Air then
        h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, GALAXY_HOP, h.AssemblyLinearVelocity.Z)
    end
end

-- Spin Bot
local function startSpin()
    local c = player.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if spinBAV then spinBAV:Destroy() end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "S7HubSpinBAV"
    spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0)
    spinBAV.Parent = root
end

local function stopSpin()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
end

-- Stretch Rez
local function setStretchRez(enabled)
    if enabled then
        workspace.CurrentCamera.ViewportSize = Vector2.new(1920, 1080)
    else
        workspace.CurrentCamera.ViewportSize = workspace.CurrentCamera.ViewportSize
    end
end

-- No Cam Collision
local function setNoCamCollision(enabled)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    if enabled then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Attach
    end
end

-- Remove Accessories
local function removeAllAccessories()
    local char = player.Character
    if not char then return end
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            acc:Destroy()
        end
    end
end

-- Character setup
RunService.Heartbeat:Connect(function()
    if not gChar or not gHum or not gHrp then return end
    if spinBotEnabled and spinBAV then
        spinBAV.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0)
    end
    if galaxyEnabled then
        updateGalaxyForce()
    end
    if galaxyEnabled and hopsEnabled and spaceHeld then
        doHop()
    end
    if not autoBatEnabled and not aplOn and not aprOn and not autoLOn and not autoROn then
        local md = gHum.MoveDirection
        if md.Magnitude > 0.1 then
            local spd = slowDownEnabled and SLOW_SPEED or NORMAL_SPEED
            gHrp.AssemblyLinearVelocity = Vector3.new(md.X * spd, gHrp.AssemblyLinearVelocity.Y, md.Z * spd)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
end)

local function setupChar(c)
    if not c then return end
    gChar = c
    gHum = c:FindFirstChildOfClass("Humanoid")
    gHrp = c:FindFirstChild("HumanoidRootPart")
    if not gHum or not gHrp then
        task.wait(0.5)
        gHum = c:FindFirstChildOfClass("Humanoid")
        gHrp = c:FindFirstChild("HumanoidRootPart")
        if not gHum or not gHrp then return end
    end

    task.wait(0.3)

    if galaxyEnabled then
        pcall(stopGalaxy)
        task.wait(0.1)
        pcall(startGalaxy)
    end
    if antiRagdollEnabled then
        pcall(stopAntiRagdoll)
        task.wait(0.1)
        pcall(startAntiRagdoll)
    end
    if spinBotEnabled then
        pcall(stopSpin)
        task.wait(0.1)
        pcall(startSpin)
    end
    if espEnabled then
        pcall(enableESP)
    end
    if autoBatEnabled then
        pcall(stopBatAimbot)
        task.wait(0.1)
        pcall(startBatAimbot)
    end
    if unwalkEnabled then
        pcall(startUnwalk)
    end
    if FloatEnabled then
        pcall(startFloat)
    end
    if autoGrabEnabled then
        pcall(startAutoGrab)
    end
    if laggerActive then
        cleanupLaggerMonitor()
        setupLaggerMonitor()
    end
end

if player.Character then
    task.wait(1)
    setupChar(player.Character)
end

player.CharacterAdded:Connect(function(c)
    task.wait(1.5)
    setupChar(c)
end)

-- ==================== DRAGGABLE SYSTEM ====================
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local handle = dragHandle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ==================== LAGGER PANEL ====================
local laggerPanel = nil
local laggerMinimized = false

local function createLaggerPanel()
    if laggerPanel then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "S7LaggerPanel"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 120)
    mainFrame.Position = UDim2.new(0.5, -100, 0.4, 0)
    mainFrame.BackgroundColor3 = BG_DARK
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = ACCENT
    mainStroke.Thickness = 1.5
    
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
    
    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "LAGGER PANEL"
    titleText.TextColor3 = ACCENT
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 12
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "−"
    closeBtn.TextColor3 = TEXT_BRIGHT
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    
    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -16, 1, -40)
    contentFrame.Position = UDim2.new(0, 8, 0, 34)
    contentFrame.BackgroundTransparency = 1
    
    local laggerToggle = Instance.new("TextButton", contentFrame)
    laggerToggle.Size = UDim2.new(1, 0, 0, 32)
    laggerToggle.Position = UDim2.new(0, 0, 0, 0)
    laggerToggle.BackgroundColor3 = BG_CARD
    laggerToggle.Text = "LAGGER: OFF"
    laggerToggle.TextColor3 = TEXT_BRIGHT
    laggerToggle.Font = Enum.Font.GothamBold
    laggerToggle.TextSize = 11
    Instance.new("UICorner", laggerToggle).CornerRadius = UDim.new(0, 6)
    
    local speedBox = Instance.new("TextBox", contentFrame)
    speedBox.Size = UDim2.new(1, 0, 0, 28)
    speedBox.Position = UDim2.new(0, 0, 0, 40)
    speedBox.BackgroundColor3 = BG_CARD
    speedBox.Text = tostring(laggerNormalSpeed)
    speedBox.TextColor3 = ACCENT
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 11
    speedBox.PlaceholderText = "Speed"
    Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)
    
    local function updateLaggerUI()
        if laggerActive then
            laggerToggle.Text = "LAGGER: ACTIVE ✓"
            laggerToggle.BackgroundColor3 = DARK_BLUE
        else
            laggerToggle.Text = "LAGGER: OFF"
            laggerToggle.BackgroundColor3 = BG_CARD
        end
    end
    
    laggerToggle.MouseButton1Click:Connect(function()
        laggerActive = not laggerActive
        updateLaggerUI()
        if laggerActive then
            setLaggerSpeed(tonumber(speedBox.Text) or 12)
            setupLaggerMonitor()
        else
            cleanupLaggerMonitor()
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end)
    
    speedBox.FocusLost:Connect(function()
        local n = tonumber(speedBox.Text)
        if n then setLaggerSpeed(n) end
    end)
    
    local minimized = false
    closeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            closeBtn.Text = "+"
            contentFrame.Visible = false
            mainFrame:TweenSize(UDim2.new(0, 200, 0, 34), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        else
            closeBtn.Text = "−"
            contentFrame.Visible = true
            mainFrame:TweenSize(UDim2.new(0, 200, 0, 120), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        end
    end)
    
    updateLaggerUI()
    makeDraggable(mainFrame, titleBar)
    laggerPanel = screenGui
end

local function destroyLaggerPanel()
    if laggerPanel then laggerPanel:Destroy() laggerPanel = nil end
end

-- ==================== DESYNC PANEL ====================
local desyncPanel = nil
local desyncMinimized = false
local desyncActive = false
local noAnimActive = false
local noAnimConnection = nil

local function toggleNoAnim(state)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if state then
        if noAnimConnection then return end
        noAnimConnection = RunService.RenderStepped:Connect(function()
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                track:Stop()
                track:AdjustSpeed(0)
            end
        end)
    else
        if noAnimConnection then
            noAnimConnection:Disconnect()
            noAnimConnection = nil
        end
    end
end

local function createDesyncPanel()
    if desyncPanel then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "S7DesyncPanel"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 110)
    mainFrame.Position = UDim2.new(0.5, -100, 0.3, 0)
    mainFrame.BackgroundColor3 = BG_DARK
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = ACCENT
    mainStroke.Thickness = 1.5
    
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
    
    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "DESYNC PANEL"
    titleText.TextColor3 = ACCENT
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 12
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "−"
    closeBtn.TextColor3 = TEXT_BRIGHT
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    
    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -16, 1, -40)
    contentFrame.Position = UDim2.new(0, 8, 0, 34)
    contentFrame.BackgroundTransparency = 1
    
    local desyncToggle = Instance.new("TextButton", contentFrame)
    desyncToggle.Size = UDim2.new(1, 0, 0, 32)
    desyncToggle.Position = UDim2.new(0, 0, 0, 0)
    desyncToggle.BackgroundColor3 = BG_CARD
    desyncToggle.Text = "DESYNC: OFF"
    desyncToggle.TextColor3 = TEXT_BRIGHT
    desyncToggle.Font = Enum.Font.GothamBold
    desyncToggle.TextSize = 11
    Instance.new("UICorner", desyncToggle).CornerRadius = UDim.new(0, 6)
    
    local noAnimToggle = Instance.new("TextButton", contentFrame)
    noAnimToggle.Size = UDim2.new(1, 0, 0, 32)
    noAnimToggle.Position = UDim2.new(0, 0, 0, 40)
    noAnimToggle.BackgroundColor3 = BG_CARD
    noAnimToggle.Text = "NO ANIM: OFF"
    noAnimToggle.TextColor3 = TEXT_BRIGHT
    noAnimToggle.Font = Enum.Font.GothamBold
    noAnimToggle.TextSize = 11
    Instance.new("UICorner", noAnimToggle).CornerRadius = UDim.new(0, 6)
    
    local function updateDesyncUI()
        if desyncActive then
            desyncToggle.Text = "DESYNC: ACTIVE ✓"
            desyncToggle.BackgroundColor3 = DARK_BLUE
        else
            desyncToggle.Text = "DESYNC: OFF"
            desyncToggle.BackgroundColor3 = BG_CARD
        end
    end
    
    local function updateNoAnimUI()
        if noAnimActive then
            noAnimToggle.Text = "NO ANIM: ON ✓"
            noAnimToggle.BackgroundColor3 = DARK_BLUE
        else
            noAnimToggle.Text = "NO ANIM: OFF"
            noAnimToggle.BackgroundColor3 = BG_CARD
        end
    end
    
    desyncToggle.MouseButton1Click:Connect(function()
        desyncActive = not desyncActive
        updateDesyncUI()
    end)
    
    noAnimToggle.MouseButton1Click:Connect(function()
        noAnimActive = not noAnimActive
        updateNoAnimUI()
        toggleNoAnim(noAnimActive)
    end)
    
    local minimized = false
    closeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            closeBtn.Text = "+"
            contentFrame.Visible = false
            mainFrame:TweenSize(UDim2.new(0, 200, 0, 34), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        else
            closeBtn.Text = "−"
            contentFrame.Visible = true
            mainFrame:TweenSize(UDim2.new(0, 200, 0, 110), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        end
    end)
    
    updateDesyncUI()
    updateNoAnimUI()
    makeDraggable(mainFrame, titleBar)
    desyncPanel = screenGui
end

local function destroyDesyncPanel()
    if desyncPanel then desyncPanel:Destroy() desyncPanel = nil end
end

-- ==================== MAIN MENU (KRIX HUB STYLE) ====================
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "S7Hub_Main"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 380, 0, 520)
mainFrame.Position = UDim2.new(0.5, -190, 0.4, 0)
mainFrame.BackgroundColor3 = BG_DARK
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = ACCENT
mainStroke.Thickness = 2

-- Title Bar / Header
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -100, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "S7 SHUB"
titleText.TextColor3 = ACCENT
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 20
titleText.TextXAlignment = Enum.TextXAlignment.Left

-- Close/Minimize Button (für das ganze Menu)
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -42, 0.5, -16)
minBtn.BackgroundColor3 = BG_CARD
minBtn.Text = "−"
minBtn.TextColor3 = TEXT_BRIGHT
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 20
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

-- Tabs (Speed, Combat, Steal, Movement, Visual, Auto, Settings)
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, -20, 0, 36)
tabContainer.Position = UDim2.new(0, 10, 0, 52)
tabContainer.BackgroundTransparency = 1

local tabs = {}
local tabFrames = {}
local tabNames = {"SPEED", "COMBAT", "STEAL", "MOVEMENT", "VISUAL", "AUTO", "SETTINGS"}

for i, name in ipairs(tabNames) do
    local tabBtn = Instance.new("TextButton", tabContainer)
    tabBtn.Size = UDim2.new(0.14, -2, 1, 0)
    tabBtn.Position = UDim2.new((i-1) * 0.142, 2, 0, 0)
    tabBtn.BackgroundColor3 = BG_CARD
    tabBtn.Text = name
    tabBtn.TextColor3 = TEXT_DIM
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 11
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
    tabs[i] = tabBtn
    
    local tabFrame = Instance.new("ScrollingFrame", mainFrame)
    tabFrame.Size = UDim2.new(1, -20, 1, -110)
    tabFrame.Position = UDim2.new(0, 10, 0, 96)
    tabFrame.BackgroundTransparency = 1
    tabFrame.BorderSizePixel = 0
    tabFrame.ScrollBarThickness = 3
    tabFrame.ScrollBarImageColor3 = ACCENT
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabFrame.Visible = (i == 1)
    tabFrames[i] = tabFrame
    
    local listLayout = Instance.new("UIListLayout", tabFrame)
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
end

local function selectTab(index)
    for i, frame in ipairs(tabFrames) do
        frame.Visible = (i == index)
    end
    for i, btn in ipairs(tabs) do
        if i == index then
            btn.BackgroundColor3 = ACCENT
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = BG_CARD
            btn.TextColor3 = TEXT_DIM
        end
    end
end

for i, btn in ipairs(tabs) do
    btn.MouseButton1Click:Connect(function()
        selectTab(i)
    end)
end

-- Helper function to create toggle rows
local function createToggleRow(parent, label, defaultState, order, onToggle)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = BG_CARD
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TEXT_BRIGHT
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggleBg = Instance.new("Frame", row)
    toggleBg.Size = UDim2.new(0, 46, 0, 22)
    toggleBg.Position = UDim2.new(1, -56, 0.5, -11)
    toggleBg.BackgroundColor3 = defaultState and ACCENT or BG_DARK
    toggleBg.BorderSizePixel = 0
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local toggleDot = Instance.new("Frame", toggleBg)
    toggleDot.Size = UDim2.new(0, 18, 0, 18)
    toggleDot.Position = defaultState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    toggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleDot.BorderSizePixel = 0
    Instance.new("UICorner", toggleDot).CornerRadius = UDim.new(1, 0)
    
    local state = defaultState
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        toggleBg.BackgroundColor3 = state and ACCENT or BG_DARK
        toggleDot.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        if onToggle then onToggle(state) end
    end)
    
    return row, function(s)
        state = s
        toggleBg.BackgroundColor3 = state and ACCENT or BG_DARK
        toggleDot.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    end
end

-- Helper function for value input
local function createValueRow(parent, label, defaultValue, order, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = BG_CARD
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, -12, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TEXT_BRIGHT
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.35, -12, 0, 28)
    box.Position = UDim2.new(0.65, 0, 0.5, -14)
    box.BackgroundColor3 = BG_DARK
    box.Text = tostring(defaultValue)
    box.TextColor3 = ACCENT
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            if onChange then onChange(n) end
        else
            box.Text = tostring(defaultValue)
        end
    end)
    
    return row, box
end

-- Helper for action button
local function createActionBtn(parent, text, order, onPress)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = BG_CARD
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, -16, 0, 30)
    btn.Position = UDim2.new(0, 8, 0.5, -15)
    btn.BackgroundColor3 = BG_DARK
    btn.Text = text
    btn.TextColor3 = TEXT_BRIGHT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(onPress)
    return row
end

-- ==================== POPULATE TABS ====================

-- SPEED TAB (Index 1)
createValueRow(tabFrames[1], "Normal Speed", NORMAL_SPEED, 1, function(v)
    NORMAL_SPEED = math.clamp(v, 1, 300)
end)
createValueRow(tabFrames[1], "Carry Speed", SLOW_SPEED, 2, function(v)
    SLOW_SPEED = math.clamp(v, 1, 300)
end)
createValueRow(tabFrames[1], "Lagger Speed", laggerNormalSpeed, 3, function(v)
    setLaggerSpeed(math.clamp(v, 1, 100))
end)

-- COMBAT TAB (Index 2)
local combatFrame = tabFrames[2]
local autoBatSetter
createToggleRow(combatFrame, "Auto Bat", autoBatEnabled, 1, function(v)
    autoBatEnabled = v
    if v then
        if aplOn then
            aplOn = false
            stopAutoPlayLeft()
        end
        if aprOn then
            aprOn = false
            stopAutoPlayRight()
        end
        if autoLOn then
            autoLOn = false
            stopAutoL()
        end
        if autoROn then
            autoROn = false
            stopAutoR()
        end
        startBatAimbot()
    else
        stopBatAimbot()
    end
end)
createToggleRow(combatFrame, "Auto Swing", true, 2, function(v)
    autoSwingEnabled = v
end)
createToggleRow(combatFrame, "Harder Hit Anim", HarderHitAnim, 3, function(v)
    HarderHitAnim = v
    -- Implement harder hit animation logic here if needed
end)
createToggleRow(combatFrame, "Medusa Counter", MedusaCounter, 4, function(v)
    MedusaCounter = v
    -- Medusa counter logic
end)
createToggleRow(combatFrame, "Desync", DesyncActive, 5, function(v)
    DesyncActive = v
    if DesyncPanelActive then createDesyncPanel() end
end)
createValueRow(combatFrame, "Engage Range", BAT_ENGAGE_RANGE, 6, function(v)
    BAT_ENGAGE_RANGE = math.clamp(v, 1, 50)
end)
createValueRow(combatFrame, "Aimbot Speed", AIMBOT_SPEED, 7, function(v)
    AIMBOT_SPEED = math.clamp(v, 10, 200)
end)

-- STEAL TAB (Index 3)
local stealFrame = tabFrames[3]
createToggleRow(stealFrame, "Auto Steal", autoStealEnabled, 1, function(v)
    autoStealEnabled = v
    if v then startAutoSteal() else stopAutoSteal() end
end)
createToggleRow(stealFrame, "Fastest Steal", false, 2, function(v)
    if v then STEAL_DURATION = 0.1 else STEAL_DURATION = 0.35 end
end)
createValueRow(stealFrame, "Radius", STEAL_RADIUS, 3, function(v)
    STEAL_RADIUS = math.clamp(v, 5, 200)
end)
createValueRow(stealFrame, "Duration", STEAL_DURATION, 4, function(v)
    STEAL_DURATION = math.max(0.05, v)
end)

-- MOVEMENT TAB (Index 4)
local moveFrame = tabFrames[4]
createToggleRow(moveFrame, "Infinite Jump", infJumpEnabled, 1, function(v)
    infJumpEnabled = v
end)
createToggleRow(moveFrame, "Anti Ragdoll", antiRagdollEnabled, 2, function(v)
    antiRagdollEnabled = v
    if v then startAntiRagdoll() else stopAntiRagdoll() end
end)
createToggleRow(moveFrame, "Unwalk", unwalkEnabled, 3, function(v)
    unwalkEnabled = v
    if v then startUnwalk() else stopUnwalk() end
end)
createToggleRow(moveFrame, "Float", FloatEnabled, 4, function(v)
    FloatEnabled = v
    if v then startFloat() else stopFloat() end
end)
createValueRow(moveFrame, "Float Height", FloatHeight, 5, function(v)
    FloatHeight = math.clamp(v, 1, 50)
end)
createActionBtn(moveFrame, "Drop Brainrot", 6, function()
    doDropBrainrot()
end)
createActionBtn(moveFrame, "TP Down", 7, function()
    doTPDown()
end)
createToggleRow(moveFrame, "TP Mode", TPMode, 8, function(v)
    TPMode = v
end)

-- VISUAL TAB (Index 5)
local visFrame = tabFrames[5]
createToggleRow(visFrame, "Stretch Rez", StretchRez, 1, function(v)
    StretchRez = v
    setStretchRez(v)
end)
createToggleRow(visFrame, "No Cam Collision", NoCamCollision, 2, function(v)
    NoCamCollision = v
    setNoCamCollision(v)
end)
createToggleRow(visFrame, "Anti Lag", AntiLag, 3, function(v)
    AntiLag = v
    if v then enableOptimizer() else disableOptimizer() end
end)
createToggleRow(visFrame, "Ultra Mode", UltraMode, 4, function(v)
    UltraMode = v
    if v then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end)
createToggleRow(visFrame, "Remove Accessories", RemoveAccessories, 5, function(v)
    RemoveAccessories = v
    if v then removeAllAccessories() end
end)
createToggleRow(visFrame, "Player ESP", espEnabled, 6, function(v)
    espEnabled = v
    if v then enableESP() else disableESP() end
end)
createValueRow(visFrame, "FOV", fovValue, 7, function(v)
    fovValue = math.clamp(v, 10, 120)
    applyFOV()
end)

-- AUTO TAB (Index 6)
local autoFrame = tabFrames[6]
createToggleRow(autoFrame, "Auto Left", autoLOn, 1, function(v)
    if v then
        if autoBatEnabled then
            autoBatEnabled = false
            stopBatAimbot()
        end
        if aprOn then
            aprOn = false
            stopAutoPlayRight()
        end
        if autoROn then
            autoROn = false
            stopAutoR()
        end
        if aplOn then
            aplOn = false
            stopAutoPlayLeft()
        end
        autoLOn = true
        startAutoL()
    else
        autoLOn = false
        stopAutoL()
    end
end)
createToggleRow(autoFrame, "Auto Right", autoROn, 2, function(v)
    if v then
        if autoBatEnabled then
            autoBatEnabled = false
            stopBatAimbot()
        end
        if aplOn then
            aplOn = false
            stopAutoPlayLeft()
        end
        if autoLOn then
            autoLOn = false
            stopAutoL()
        end
        if aprOn then
            aprOn = false
            stopAutoPlayRight()
        end
        autoROn = true
        startAutoR()
    else
        autoROn = false
        stopAutoR()
    end
end)
createToggleRow(autoFrame, "Full Auto Left", aplOn, 3, function(v)
    if v then
        if autoBatEnabled then
            autoBatEnabled = false
            stopBatAimbot()
        end
        if aprOn then
            aprOn = false
            stopAutoPlayRight()
        end
        if autoLOn then
            autoLOn = false
            stopAutoL()
        end
        if autoROn then
            autoROn = false
            stopAutoR()
        end
        aplOn = true
        startAutoPlayLeft()
    else
        aplOn = false
        stopAutoPlayLeft()
    end
end)
createToggleRow(autoFrame, "Full Auto Right", aprOn, 4, function(v)
    if v then
        if autoBatEnabled then
            autoBatEnabled = false
            stopBatAimbot()
        end
        if aplOn then
            aplOn = false
            stopAutoPlayLeft()
        end
        if autoLOn then
            autoLOn = false
            stopAutoL()
        end
        if autoROn then
            autoROn = false
            stopAutoR()
        end
        aprOn = true
        startAutoPlayRight()
    else
        aprOn = false
        stopAutoPlayRight()
    end
end)
createToggleRow(autoFrame, "Auto Grab", autoGrabEnabled, 5, function(v)
    autoGrabEnabled = v
    if v then startAutoGrab() else stopAutoGrab() end
end)
createValueRow(autoFrame, "Grab Radius", GRAB_RADIUS, 6, function(v)
    GRAB_RADIUS = math.clamp(v, 5, 50)
end)

-- SETTINGS TAB (Index 7)
local settingsFrame = tabFrames[7]
createToggleRow(settingsFrame, "Desync Panel", DesyncPanelActive, 1, function(v)
    DesyncPanelActive = v
    if v then createDesyncPanel() else destroyDesyncPanel() end
end)
createToggleRow(settingsFrame, "Lagger Panel", LaggerPanelActive, 2, function(v)
    LaggerPanelActive = v
    if v then createLaggerPanel() else destroyLaggerPanel() end
end)
createToggleRow(settingsFrame, "Speed Bypass", SpeedBypass, 3, function(v)
    SpeedBypass = v
end)
createToggleRow(settingsFrame, "Auto Save", autoSaveEnabled, 4, function(v)
    autoSaveEnabled = v
end)
createActionBtn(settingsFrame, "Taunt Spam", 5, function()
    if not tauntActive then
        startTaunt()
    else
        stopTaunt()
    end
end)

-- ==================== MOBILE BOTTOM BUTTONS (wie auf Bild 8) ====================
local bottomBar = Instance.new("Frame", screenGui)
bottomBar.Size = UDim2.new(1, 0, 0, 58)
bottomBar.Position = UDim2.new(0, 0, 1, -58)
bottomBar.BackgroundColor3 = BG_DARK
bottomBar.BackgroundTransparency = 0.1
bottomBar.BorderSizePixel = 0
Instance.new("UICorner", bottomBar).CornerRadius = UDim.new(0, 0)

local btnContainer = Instance.new("Frame", bottomBar)
btnContainer.Size = UDim2.new(1, -20, 1, -10)
btnContainer.Position = UDim2.new(0, 10, 0, 5)
btnContainer.BackgroundTransparency = 1

local btnLayout = Instance.new("UIListLayout", btnContainer)
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.Padding = UDim.new(0, 8)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local bottomButtons = {
    {text = "DROP BRAINROT", action = function() doDropBrainrot() end},
    {text = "AUTO L", action = function() 
        local newState = not autoLOn
        if newState then
            if autoBatEnabled then stopBatAimbot() end
            if aprOn then stopAutoPlayRight() end
            if autoROn then stopAutoR() end
            if aplOn then stopAutoPlayLeft() end
            autoLOn = true
            startAutoL()
        else
            autoLOn = false
            stopAutoL()
        end
    end},
    {text = "AUTO BAT", action = function()
        local newState = not autoBatEnabled
        if newState then
            if aplOn then stopAutoPlayLeft() end
            if aprOn then stopAutoPlayRight() end
            if autoLOn then stopAutoL() end
            if autoROn then stopAutoR() end
            autoBatEnabled = true
            startBatAimbot()
        else
            autoBatEnabled = false
            stopBatAimbot()
        end
    end},
    {text = "AUTO R", action = function()
        local newState = not autoROn
        if newState then
            if autoBatEnabled then stopBatAimbot() end
            if aplOn then stopAutoPlayLeft() end
            if autoLOn then stopAutoL() end
            if aprOn then stopAutoPlayRight() end
            autoROn = true
            startAutoR()
        else
            autoROn = false
            stopAutoR()
        end
    end},
    {text = "TP DOWN", action = function() doTPDown() end},
    {text = "CARRY", action = function()
        slowDownEnabled = not slowDownEnabled
    end},
    {text = "LAGGER", action = function()
        createLaggerPanel()
    end},
}

for _, btnData in ipairs(bottomButtons) do
    local btn = Instance.new("TextButton", btnContainer)
    btn.Size = UDim2.new(0, 85, 1, 0)
    btn.BackgroundColor3 = BG_CARD
    btn.Text = btnData.text
    btn.TextColor3 = TEXT_BRIGHT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(btnData.action)
end

-- ==================== Progress Bar für Auto Steal ====================
local progressGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
progressGui.Name = "S7ProgressBar"
progressGui.ResetOnSpawn = false

local progressFrame = Instance.new("Frame", progressGui)
progressFrame.Size = UDim2.new(0, 280, 0, 44)
progressFrame.Position = UDim2.new(0.5, -140, 1, -100)
progressFrame.BackgroundColor3 = BG_DARK
progressFrame.BackgroundTransparency = 0.1
progressFrame.BorderSizePixel = 0
Instance.new("UICorner", progressFrame).CornerRadius = UDim.new(0, 12)

local progressStroke = Instance.new("UIStroke", progressFrame)
progressStroke.Color = ACCENT
progressStroke.Thickness = 1.5

ProgressLabel = Instance.new("TextLabel", progressFrame)
ProgressLabel.Size = UDim2.new(0.5, -10, 0.5, 0)
ProgressLabel.Position = UDim2.new(0, 12, 0, 4)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "READY"
ProgressLabel.TextColor3 = TEXT_BRIGHT
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 12
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left

ProgressPctLabel = Instance.new("TextLabel", progressFrame)
ProgressPctLabel.Size = UDim2.new(0.4, -10, 0.5, 0)
ProgressPctLabel.Position = UDim2.new(0.6, 0, 0, 4)
ProgressPctLabel.BackgroundTransparency = 1
ProgressPctLabel.Text = ""
ProgressPctLabel.TextColor3 = ACCENT
ProgressPctLabel.Font = Enum.Font.GothamBlack
ProgressPctLabel.TextSize = 14
ProgressPctLabel.TextXAlignment = Enum.TextXAlignment.Right

local barBg = Instance.new("Frame", progressFrame)
barBg.Size = UDim2.new(0.92, 0, 0, 10)
barBg.Position = UDim2.new(0.04, 0, 1, -16)
barBg.BackgroundColor3 = BG_CARD
barBg.BorderSizePixel = 0
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

ProgressBarFill = Instance.new("Frame", barBg)
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = ACCENT
ProgressBarFill.BorderSizePixel = 0
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

-- ==================== START FEATURES ====================
if espEnabled then enableESP() end
applyFOV()
if spinBotEnabled then startSpin() end
if antiRagdollEnabled then startAntiRagdoll() end
if unwalkEnabled then startUnwalk() end
if autoBatEnabled then startBatAimbot() end
if autoStealEnabled then startAutoSteal() end
if galaxyEnabled then startGalaxy() end
if optimizerEnabled then enableOptimizer() end
if FloatEnabled then startFloat() end
if autoGrabEnabled then startAutoGrab() end

-- ==================== MENU MINIMIZE SYSTEM ====================
local menuVisible = true
local minimizedMenuBtn = nil

minBtn.MouseButton1Click:Connect(function()
    menuVisible = not menuVisible
    if not menuVisible then
        -- Menu verstecken, nur kleiner Button bleibt
        mainFrame.Visible = false
        bottomBar.Visible = false
        progressFrame.Visible = false
        if not minimizedMenuBtn then
            minimizedMenuBtn = Instance.new("TextButton", screenGui)
            minimizedMenuBtn.Size = UDim2.new(0, 50, 0, 50)
            minimizedMenuBtn.Position = UDim2.new(1, -60, 0.5, -25)
            minimizedMenuBtn.BackgroundColor3 = BG_DARK
            minimizedMenuBtn.Text = "S7S"
            minimizedMenuBtn.TextColor3 = ACCENT
            minimizedMenuBtn.Font = Enum.Font.GothamBlack
            minimizedMenuBtn.TextSize = 14
            Instance.new("UICorner", minimizedMenuBtn).CornerRadius = UDim.new(0, 12)
            Instance.new("UIStroke", minimizedMenuBtn).Color = ACCENT
            
            minimizedMenuBtn.MouseButton1Click:Connect(function()
                menuVisible = true
                mainFrame.Visible = true
                bottomBar.Visible = true
                progressFrame.Visible = true
                if minimizedMenuBtn then minimizedMenuBtn:Destroy() minimizedMenuBtn = nil end
            end)
            
            makeDraggable(minimizedMenuBtn, minimizedMenuBtn)
        end
    else
        if minimizedMenuBtn then
            minimizedMenuBtn:Destroy()
            minimizedMenuBtn = nil
        end
        mainFrame.Visible = true
        bottomBar.Visible = true
        progressFrame.Visible = true
    end
end)

-- ==================== DRAGGABLE MAIN MENU ====================
makeDraggable(mainFrame, titleBar)
makeDraggable(progressFrame, progressFrame)
makeDraggable(bottomBar, bottomBar)

print("S7 SHUB loaded - Black & Blue Edition | discord.gg/S7S")
