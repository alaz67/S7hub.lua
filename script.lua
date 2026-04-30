-- S7 SHUB - Black & Blue Edition with Lock (Bat Aimbot) & Taunt Feature
-- With Discord Tag Above Head & Auto Steal Circle
-- Lock/Bat Aimbot: NO auto swing, smooth movement

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Black & Blue Color Scheme
local ACCENT = Color3.fromRGB(66, 135, 245)     -- Blue accent
local BG_DARK = Color3.fromRGB(8, 8, 12)        -- Near black
local BG_MID = Color3.fromRGB(15, 15, 20)       -- Dark grey/blue
local BG_CARD = Color3.fromRGB(22, 22, 30)      -- Card color
local TEXT_DIM = Color3.fromRGB(140, 140, 160)  -- Dim text
local TEXT_BRIGHT = Color3.fromRGB(220, 220, 240)

local Config = {
    StealSpeed = 30,
    FOV = 70,
    InfJumpPower = 60,
    WalkSpeed = 59,
    GrabRadius = 20,
    Gravity = 120,
    GalaxyGravityPercent = 70,
    HopPower = 35,
    HopCooldown = 0.08,
    AimbotRadius = 100,
    BatAimbotSpeed = 55,
    SpeedBoost = 29,
}

local Keybinds = {
    AutoLeft = Enum.KeyCode.Q,
    AutoRight = Enum.KeyCode.E,
    SpeedBoost = Enum.KeyCode.R,
    AutoSteal = Enum.KeyCode.V,
    BatAimbot = Enum.KeyCode.X,
    AntiRagdoll = Enum.KeyCode.Z,
    NoAnimations = Enum.KeyCode.N,
}

local function saveConfig()
    local data = { Config = Config, Keybinds = {}, Features = {} }
    for k, v in pairs(Keybinds) do
        if v then data.Keybinds[k] = v.Name end
    end
    pcall(function()
        data.Features.SpeedBoost   = SpeedBoostBtn   and SpeedBoostBtn.BackgroundColor3   == ACCENT or false
        data.Features.AutoSteal    = AutoStealBtn    and AutoStealBtn.BackgroundColor3    == ACCENT or false
        data.Features.BatAimbot    = BatAimbotBtn    and BatAimbotBtn.BackgroundColor3    == ACCENT or false
        data.Features.Galaxy       = GalaxyBtn       and GalaxyBtn.BackgroundColor3       == ACCENT or false
        data.Features.Optimizer    = OptimizerBtn    and OptimizerBtn.BackgroundColor3    == ACCENT or false
        data.Features.AntiRagdoll  = AntiRagdollBtn  and AntiRagdollBtn.BackgroundColor3  == ACCENT or false
        data.Features.NoAnimations = NoAnimBtn       and NoAnimBtn.BackgroundColor3       == ACCENT or false
        data.Features.Spinbot      = SpinbotBtn      and SpinbotBtn.BackgroundColor3      == ACCENT or false
        data.Features.InfJump      = InfJumpBtn      and InfJumpBtn.BackgroundColor3      == ACCENT or false
        data.Features.Noclip       = NoclipBtn       and NoclipBtn.BackgroundColor3       == ACCENT or false
        data.Features.Fullbright   = FullbrightBtn   and FullbrightBtn.BackgroundColor3   == ACCENT or false
    end)
    pcall(function() writefile("S7Shub_Config.json", HttpService:JSONEncode(data)) end)
end

local function loadConfig()
    pcall(function()
        if isfile("S7Shub_Config.json") then
            local data = HttpService:JSONDecode(readfile("S7Shub_Config.json"))
            if data.Config then for k, v in pairs(data.Config) do Config[k] = v end end
            if data.Keybinds then for k, v in pairs(data.Keybinds) do Keybinds[k] = Enum.KeyCode[v] end end
            return data.Features
        end
    end)
    return nil
end

local savedFeatures = loadConfig()

-- ==================== DISCORD TAG ====================
local function createDiscordTag()
    local function addTag()
        local char = player.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local existing = char:FindFirstChild("S7DiscordTag")
        if existing then existing:Destroy() end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "S7DiscordTag"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 160, 0, 28)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = char
        
        local frame = Instance.new("Frame", billboard)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = BG_DARK
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = ACCENT
        stroke.Thickness = 1
        
        local text = Instance.new("TextLabel", frame)
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "discord.gg/qMtvNQg68s"
        text.TextColor3 = TEXT_BRIGHT
        text.Font = Enum.Font.GothamBold
        text.TextSize = 11
        text.TextScaled = true
    end
    
    if player.Character then addTag() end
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        addTag()
    end)
end

-- ==================== TAUNT BUTTON ====================
local tauntGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
tauntGui.Name = "S7TauntButton"
tauntGui.ResetOnSpawn = false
tauntGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local tauntBtn = Instance.new("TextButton", tauntGui)
tauntBtn.Size = UDim2.new(0, 80, 0, 38)
tauntBtn.Position = UDim2.new(1, -90, 0.5, -50)
tauntBtn.BackgroundColor3 = BG_CARD
tauntBtn.Text = "TAUNT"
tauntBtn.TextColor3 = TEXT_BRIGHT
tauntBtn.Font = Enum.Font.GothamBlack
tauntBtn.TextSize = 12
tauntBtn.ZIndex = 20
Instance.new("UICorner", tauntBtn).CornerRadius = UDim.new(0, 10)

local tauntStroke = Instance.new("UIStroke", tauntBtn)
tauntStroke.Color = ACCENT
tauntStroke.Thickness = 1.5

-- Make taunt button draggable
local tauntDragging = false
local tauntDragStart = nil
local tauntStartPos = nil

tauntBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tauntDragging = true
        tauntDragStart = input.Position
        tauntStartPos = tauntBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if tauntDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - tauntDragStart
        tauntBtn.Position = UDim2.new(tauntStartPos.X.Scale, tauntStartPos.X.Offset + delta.X, tauntStartPos.Y.Scale, tauntStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tauntDragging = false
    end
end)

local tauntCooldown = false

local function sendTaunt()
    if tauntCooldown then return end
    tauntCooldown = true
    
    local chatEvent = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
    chatEvent:FireServer("/lol S7 Shub😂😂", "All")
    task.wait(0.2)
    chatEvent:FireServer("/lol S7 Shub😂😂", "All")
    
    tauntBtn.BackgroundColor3 = ACCENT
    tauntBtn.TextColor3 = BG_DARK
    task.wait(3)
    tauntBtn.BackgroundColor3 = BG_CARD
    tauntBtn.TextColor3 = TEXT_BRIGHT
    tauntCooldown = false
end

tauntBtn.MouseButton1Click:Connect(sendTaunt)

tauntBtn.MouseEnter:Connect(function()
    TweenService:Create(tauntBtn, TweenInfo.new(0.15), {BackgroundColor3 = BG_MID}):Play()
end)
tauntBtn.MouseLeave:Connect(function()
    TweenService:Create(tauntBtn, TweenInfo.new(0.15), {BackgroundColor3 = BG_CARD}):Play()
end)

-- ==================== UTILITY FUNCTIONS ====================
local function getHRP()
    local c = player.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
end

local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ==================== INFINITE JUMP ====================
local infJumpEnabled = true
local jumpForce = 54
local clampFallSpeed = 80
local infJumpConn = nil

local function startInfJump()
    if infJumpConn then return end
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        if not infJumpEnabled then return end
        local c = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, jumpForce, hrp.AssemblyLinearVelocity.Z)
    end)
end

RunService.Heartbeat:Connect(function()
    if not infJumpEnabled then return end
    local c = player.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp.AssemblyLinearVelocity.Y < -clampFallSpeed then
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -clampFallSpeed, hrp.AssemblyLinearVelocity.Z)
    end
end)

startInfJump()

-- ==================== ANTI RAGDOLL ====================
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics
            or humState == Enum.HumanoidStateType.Ragdoll
            or humState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                if root then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end
            hum.AutoRotate = true
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then
                obj.Enabled = true
            end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
end

-- ==================== NO ANIMATIONS ====================
local noAnimConn = nil

local function toggleNoAnimations(state)
    if noAnimConn then noAnimConn:Disconnect(); noAnimConn = nil end
    if state then
        local char = player.Character; if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid"); if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator"); if not animator then return end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop(); track:AdjustSpeed(0) end
        noAnimConn = humanoid.AnimationPlayed:Connect(function(track) track:Stop(); track:AdjustSpeed(0) end)
    end
end

-- ==================== SPINBOT ====================
local spinBAV = nil
local function startSpinbot()
    local hrp = getHRP(); if not hrp then return end
    if spinBAV then spinBAV:Destroy() end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, 50, 0)
    spinBAV.Parent = hrp
end
local function stopSpinbot()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
end

-- ==================== NOCLIP ====================
local noclipConn = nil
local function startNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = player.Character; if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = player.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end

-- ==================== FULLBRIGHT ====================
local origBrightness = nil
local function enableFullbright()
    local L = Lighting
    origBrightness = {L.Brightness, L.Ambient, L.OutdoorAmbient}
    L.Brightness = 10
    L.Ambient = Color3.fromRGB(255,255,255)
    L.OutdoorAmbient = Color3.fromRGB(255,255,255)
end
local function disableFullbright()
    if origBrightness then
        local L = Lighting
        L.Brightness = origBrightness[1]
        L.Ambient = origBrightness[2]
        L.OutdoorAmbient = origBrightness[3]
    end
end

-- ==================== OPTIMIZER ====================
local function enableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
    end)
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow = false; obj.Material = Enum.Material.Plastic end
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

-- ==================== SPEED BOOST ====================
local speedBoostConn = nil
local function startSpeedBoost()
    if speedBoostConn then return end
    speedBoostConn = RunService.Heartbeat:Connect(function()
        local char = player.Character; if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not humanoid or not hrp then return end
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * Config.SpeedBoost, hrp.AssemblyLinearVelocity.Y, moveDir.Z * Config.SpeedBoost)
        end
    end)
end
local function stopSpeedBoost()
    if speedBoostConn then speedBoostConn:Disconnect(); speedBoostConn = nil end
end

-- ==================== GALAXY MODE ====================
local galaxyVectorForce = nil
local galaxyAttachment = nil
local galaxyEnabled = false
local hopsEnabled = false
local lastHopTime = 0
local spaceHeld = false
local originalJumpPower = 50
local DEFAULT_GRAVITY = 196.2

local function captureJumpPower()
    local c = player.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.JumpPower > 0 then originalJumpPower = hum.JumpPower end
end

local function setupGalaxyForce()
    pcall(function()
        local c = player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment then galaxyAttachment:Destroy() end
        galaxyAttachment = Instance.new("Attachment"); galaxyAttachment.Parent = h
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0 = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force = Vector3.new(0, 0, 0)
        galaxyVectorForce.Parent = h
    end)
end

local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = player.Character; if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then mass = mass + p:GetMass() end
    end
    local tg = DEFAULT_GRAVITY * (Config.GalaxyGravityPercent / 100)
    galaxyVectorForce.Force = Vector3.new(0, mass * (DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function adjustGalaxyJump()
    pcall(function()
        local c = player.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if not galaxyEnabled then hum.JumpPower = originalJumpPower; return end
        local ratio = math.sqrt((DEFAULT_GRAVITY * (Config.GalaxyGravityPercent / 100)) / DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower * ratio
    end)
end

local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c = player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid"); if not h or not hum then return end
        if tick() - lastHopTime < Config.HopCooldown then return end
        lastHopTime = tick()
        if hum.FloorMaterial == Enum.Material.Air then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, Config.HopPower, h.AssemblyLinearVelocity.Z)
        end
    end)
end

local function startGalaxy()
    galaxyEnabled = true; hopsEnabled = true; setupGalaxyForce(); adjustGalaxyJump()
end

local function stopGalaxy()
    galaxyEnabled = false; hopsEnabled = false
    if galaxyVectorForce then galaxyVectorForce:Destroy(); galaxyVectorForce = nil end
    if galaxyAttachment then galaxyAttachment:Destroy(); galaxyAttachment = nil end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then doMiniHop() end
    if galaxyEnabled then updateGalaxyForce() end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
end)

-- ==================== BAT AIMBOT (LOCK) ====================
local batAimbotConn = nil
local aimbotTarget = nil
local AIMBOT_SPEED = Config.BatAimbotSpeed
local MELEE_OFFSET = 3
local lockedTarget = nil

local SlapList = {
    "Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap",
    "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap",
    "Nuclear Slap", "Galaxy Slap", "Glitched Slap"
}

local function findBat()
    local c = player.Character; if not c then return nil end
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
                if d < shortestDist and d <= Config.AimbotRadius then
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
    if batAimbotConn then return end
    batAimbotConn = RunService.Heartbeat:Connect(function()
        local c = player.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid"); if not h or not hum then return end
        local bat = findBat()
        if bat and bat.Parent ~= c then hum:EquipTool(bat) end
        local targetHRP, targetChar = getBestTarget(h)
        if targetHRP and targetChar then
            local targetVel = targetHRP.AssemblyLinearVelocity
            local speed = targetVel.Magnitude
            local predictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + (targetVel * predictTime)
            local dirToTarget = predictedPos - h.Position
            local dist3D = dirToTarget.Magnitude
            local targetStandPos = dist3D > 0 and (predictedPos - dirToTarget.Unit * MELEE_OFFSET) or predictedPos
            local moveDir = targetStandPos - h.Position
            local distToStand = moveDir.Magnitude
            if distToStand > 1.5 then
                h.AssemblyLinearVelocity = moveDir.Unit * Config.BatAimbotSpeed
            else
                h.AssemblyLinearVelocity = targetVel
            end
            hum.AutoRotate = false
            h.CFrame = CFrame.lookAt(h.Position, Vector3.new(predictedPos.X, h.Position.Y, predictedPos.Z))
        else
            lockedTarget = nil
            if h then
                h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
            end
            hum.AutoRotate = true
        end
    end)
end

local function stopBatAimbot()
    if batAimbotConn then batAimbotConn:Disconnect(); batAimbotConn = nil end
    lockedTarget = nil
    local hum = getHum()
    if hum then hum.AutoRotate = true end
end

-- ==================== AUTO LEFT / RIGHT ====================
local leftActive = false
local rightActive = false
local speed = Config.WalkSpeed or 59

local leftTargets = {
    Vector3.new(-474.92510986328125, -6.398684978485107, 95.64352416992188),
    Vector3.new(-482.6980285644531, -4.433956623077393, 98.34976196289062)
}
local rightTargets = {
    Vector3.new(-473.9881286621094, -6.398684024810791, 25.45433807373047),
    Vector3.new(-482.8011474609375, -4.433956623077393, 24.77419090270996)
}

local function moveToTargets(targetList)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    for i, target in ipairs(targetList) do
        while true do
            hrp = getHRP(); if not hrp then break end
            if not leftActive and not rightActive then
                if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
                if hum then hum:Move(Vector3.zero, false) end
                return
            end
            local diff = target - hrp.Position
            local flat = Vector3.new(diff.X, 0, diff.Z)
            if flat.Magnitude <= 1.5 then
                hrp.AssemblyLinearVelocity = Vector3.zero
                break
            end
            local dir = flat.Unit
            hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum:Move(dir, false) end
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * speed, hrp.AssemblyLinearVelocity.Y, dir.Z * speed)
            RunService.RenderStepped:Wait()
        end
    end
    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
    local hum2 = (player.Character or player.CharacterAdded:Wait()):FindFirstChildOfClass("Humanoid")
    if hum2 then hum2:Move(Vector3.zero, false) end
end

-- ==================== AUTO STEAL ====================
local AUTO_STEAL_PROX_RADIUS = Config.GrabRadius
local allAnimalsCache = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local IsStealing = false
local StealProgress = 0
local PartsCount = 64
local circleParts = {}
local CIRCLE_COLOR = ACCENT
local autoStealGui = nil
local progressFill = nil
local progressText = nil

local function createCircle()
    for _, p in ipairs(circleParts) do if p then pcall(function() p:Destroy() end) end end
    table.clear(circleParts)
    for i = 1, PartsCount do
        local part = Instance.new("Part")
        part.Anchored = true; part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = CIRCLE_COLOR; part.Transparency = 0.35
        part.Size = Vector3.new(0.5, 0.1, 0.2)
        part.Parent = workspace
        table.insert(circleParts, part)
    end
end

local function initAutoStealGUI()
    if autoStealGui then pcall(function() autoStealGui:Destroy() end); autoStealGui = nil end
    autoStealGui = Instance.new("ScreenGui")
    autoStealGui.Name = "S7AutoSteal"; autoStealGui.ResetOnSpawn = false
    autoStealGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    autoStealGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 24); frame.Position = UDim2.new(0.5, -100, 1, -80)
    frame.BackgroundColor3 = BG_DARK; frame.BackgroundTransparency = 0.2; frame.BorderSizePixel = 0
    frame.Parent = autoStealGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local fStroke = Instance.new("UIStroke"); fStroke.Thickness = 1; fStroke.Color = ACCENT; fStroke.Parent = frame

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0.7, 0, 0, 6); bg.Position = UDim2.new(0.05, 0, 0.5, -3)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); bg.BorderSizePixel = 0; bg.Parent = frame
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0); progressFill.BackgroundColor3 = ACCENT; progressFill.BorderSizePixel = 0; progressFill.Parent = bg
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

    progressText = Instance.new("TextLabel")
    progressText.Size = UDim2.new(0, 40, 1, 0); progressText.Position = UDim2.new(0.78, 0, 0, 0)
    progressText.BackgroundTransparency = 1; progressText.Text = "0%"
    progressText.Font = Enum.Font.GothamBold; progressText.TextSize = 11; progressText.TextColor3 = ACCENT
    progressText.Parent = frame

    local radiusText = Instance.new("TextLabel")
    radiusText.Size = UDim2.new(0, 40, 1, 0); radiusText.Position = UDim2.new(0, 5, 0, 0)
    radiusText.BackgroundTransparency = 1; radiusText.Text = tostring(Config.GrabRadius)
    radiusText.Font = Enum.Font.GothamBold; radiusText.TextSize = 11; radiusText.TextColor3 = TEXT_DIM
    radiusText.Parent = frame
end

task.spawn(function()
    task.wait(2)
    while task.wait(5) do
        table.clear(allAnimalsCache)
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then
                    local sign = plot:FindFirstChild("PlotSign")
                    local yourBase = sign and sign:FindFirstChild("YourBase")
                    if not (yourBase and yourBase.Enabled) then
                        local podiums = plot:FindFirstChild("AnimalPodiums")
                        if podiums then
                            for _, podium in ipairs(podiums:GetChildren()) do
                                if podium:IsA("Model") and podium:FindFirstChild("Base") then
                                    table.insert(allAnimalsCache, {
                                        plot = plot.Name, slot = podium.Name,
                                        worldPosition = podium:GetPivot().Position,
                                        uid = plot.Name.."_"..podium.Name
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function findPrompt(a)
    local c = PromptMemoryCache[a.uid]
    if c and c.Parent then return c end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    local plot = plots:FindFirstChild(a.plot)
    if not plot then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    local podium = podiums:FindFirstChild(a.slot); if not podium then return end
    local base = podium:FindFirstChild("Base"); if not base then return end
    local spawn = base:FindFirstChild("Spawn"); if not spawn then return end
    local attach = spawn:FindFirstChild("PromptAttachment"); if not attach then return end
    for _, p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then PromptMemoryCache[a.uid] = p; return p end
    end
end

local function build(prompt)
    if InternalStealCache[prompt] then return end
    local d = {h = {}, t = {}, r = true}
    local s1, c1 = pcall(function() return getconnections(prompt.PromptButtonHoldBegan) end)
    if s1 and c1 then for _, c in ipairs(c1) do if c and type(c.Function) == "function" then table.insert(d.h, c.Function) end end end
    local s2, c2 = pcall(function() return getconnections(prompt.Triggered) end)
    if s2 and c2 then for _, c in ipairs(c2) do if c and type(c.Function) == "function" then table.insert(d.t, c.Function) end end end
    InternalStealCache[prompt] = d
end

local function steal(prompt)
    local d = InternalStealCache[prompt]
    if not d or not d.r then return end
    d.r = false; IsStealing = true; StealProgress = 0
    task.spawn(function()
        if #d.h > 0 or #d.t > 0 then
            for _, f in ipairs(d.h) do task.spawn(function() pcall(f) end) end
            local s = tick()
            while tick() - s < Config.StealSpeed / 100 do StealProgress = (tick()-s)/(Config.StealSpeed/100); task.wait() end
            StealProgress = 1
            for _, f in ipairs(d.t) do task.spawn(function() pcall(f) end) end
        else
            if fireproximityprompt then fireproximityprompt(prompt) end
            local s = tick()
            while tick() - s < Config.StealSpeed / 100 do StealProgress = (tick()-s)/(Config.StealSpeed/100); task.wait() end
            StealProgress = 1
        end
        task.wait(0.2); IsStealing = false; StealProgress = 0; d.r = true
    end)
end

RunService.Heartbeat:Connect(function()
    if autoStealGui and autoStealGui.Parent then
        if progressFill then progressFill.Size = UDim2.new(math.max(0, StealProgress), 0, 1, 0) end
        if progressText then progressText.Text = math.floor(StealProgress * 100).."%" end
    end
end)

RunService.RenderStepped:Connect(function()
    if autoStealGui and autoStealGui.Parent then
        local hrp = getHRP(); if not hrp then return end
        if #circleParts == 0 then createCircle() end
        AUTO_STEAL_PROX_RADIUS = Config.GrabRadius
        for i, p in ipairs(circleParts) do
            local a1 = math.rad((i-1)/PartsCount*360); local a2 = math.rad(i/PartsCount*360)
            local p1 = Vector3.new(math.cos(a1),0,math.sin(a1))*AUTO_STEAL_PROX_RADIUS
            local p2 = Vector3.new(math.cos(a2),0,math.sin(a2))*AUTO_STEAL_PROX_RADIUS
            local c = (p1+p2)/2+hrp.Position
            p.Size = Vector3.new((p2-p1).Magnitude,0.1,0.2)
            p.CFrame = CFrame.new(c,c+Vector3.new(p2.X-p1.X,0,p2.Z-p1.Z))*CFrame.Angles(0,math.pi/2,0)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if autoStealGui and autoStealGui.Parent and not IsStealing then
        local hrp = getHRP(); if not hrp then return end
        local best, dist = nil, math.huge
        for _, a in ipairs(allAnimalsCache) do
            local d = (hrp.Position - a.worldPosition).Magnitude
            if d < dist then dist = d; best = a end
        end
        if best and dist <= AUTO_STEAL_PROX_RADIUS then
            local p = findPrompt(best); if p then build(p); steal(p) end
        end
    end
end)

-- ==================== GUI CONSTRUCTION ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "S7ShubGUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 480)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -240)
MainFrame.BackgroundColor3 = BG_DARK
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2.5
MainStroke.Color = ACCENT
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

task.spawn(function()
    while MainStroke and MainStroke.Parent do
        for i = 0, 30 do if not MainStroke.Parent then break end MainStroke.Thickness = 2.5 + (i * 0.04); task.wait(0.03) end
        for i = 0, 30 do if not MainStroke.Parent then break end MainStroke.Thickness = 3.7 - (i * 0.04); task.wait(0.03) end
    end
end)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "S7 SHUB"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.TextColor3 = ACCENT
Title.Parent = TitleBar

local DiscordLabel = Instance.new("TextLabel")
DiscordLabel.Name = "Discord"
DiscordLabel.Size = UDim2.new(1, 0, 0, 20)
DiscordLabel.Position = UDim2.new(0, 0, 1, -25)
DiscordLabel.BackgroundTransparency = 1
DiscordLabel.Text = "discord.gg/qMtvNQg68s"
DiscordLabel.Font = Enum.Font.GothamBold
DiscordLabel.TextSize = 11
DiscordLabel.TextColor3 = TEXT_DIM
DiscordLabel.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -20, 0, 35)
TabContainer.Position = UDim2.new(0, 10, 0, 60)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local function makeTab(name, text, xPos, active)
    local tab = Instance.new("TextButton")
    tab.Name = name
    tab.Size = UDim2.new(0.22, 0, 1, 0)
    tab.Position = UDim2.new(xPos, 0, 0, 0)
    tab.BackgroundColor3 = active and ACCENT or BG_CARD
    tab.Text = text
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 11
    tab.TextColor3 = active and BG_DARK or TEXT_DIM
    tab.BorderSizePixel = 0
    tab.Parent = TabContainer
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = tab
    return tab
end

local FeaturesTab = makeTab("FeaturesTab", "FEATURES", 0, true)
local KeybindsTab = makeTab("KeybindsTab", "KEYBINDS", 0.26, false)
local SettingsTab  = makeTab("SettingsTab",  "SETTINGS",  0.52, false)
local MobileTab    = makeTab("MobileTab",    "MOBILE",    0.78, false)

local function makeScrollFrame(visible)
    local f = Instance.new("ScrollingFrame")
    f.Size = UDim2.new(1, -20, 1, -145)
    f.Position = UDim2.new(0, 10, 0, 105)
    f.BackgroundTransparency = 1
    f.ScrollBarThickness = 4
    f.ScrollBarImageColor3 = ACCENT
    f.CanvasSize = UDim2.new(0, 0, 0, 450)
    f.Visible = visible
    f.Parent = MainFrame
    return f
end

local FeaturesFrame = makeScrollFrame(true)
local KeybindsFrame = makeScrollFrame(false)
local SettingsFrame = makeScrollFrame(false)
local MobileFrame   = makeScrollFrame(false)

local function switchTabs(active)
    local tabs = {FeaturesTab, KeybindsTab, SettingsTab, MobileTab}
    local frames = {FeaturesFrame, KeybindsFrame, SettingsFrame, MobileFrame}
    for i, t in ipairs(tabs) do
        local on = (t == active)
        t.BackgroundColor3 = on and ACCENT or BG_CARD
        t.TextColor3 = on and BG_DARK or TEXT_DIM
        frames[i].Visible = on
    end
end

FeaturesTab.MouseButton1Click:Connect(function() switchTabs(FeaturesTab) end)
KeybindsTab.MouseButton1Click:Connect(function() switchTabs(KeybindsTab) end)
SettingsTab.MouseButton1Click:Connect(function()  switchTabs(SettingsTab)  end)
MobileTab.MouseButton1Click:Connect(function()    switchTabs(MobileTab)    end)

local function createToggle(parent, name, text, yPos)
    local button = Instance.new("TextButton")
    button.Name = name.."Toggle"
    button.Size = UDim2.new(1, -10, 0, 40)
    button.Position = UDim2.new(0, 5, 0, yPos)
    button.BackgroundColor3 = BG_CARD
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.TextColor3 = TEXT_BRIGHT
    button.BorderSizePixel = 0
    button.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = button
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60,60,70); s.Thickness = 1; s.Parent = button
    return button
end

local function updateToggle(button, active)
    local targetColor = active and ACCENT or BG_CARD
    local textColor = active and BG_DARK or TEXT_BRIGHT
    TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    button.TextColor3 = textColor
end

local function createKeybindButton(parent, name, text, currentKey, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 50)
    container.Position = UDim2.new(0, 5, 0, yPos)
    container.BackgroundColor3 = BG_CARD
    container.BorderSizePixel = 0
    container.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = container
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60,60,70); s.Thickness = 1; s.Parent = container

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(0, 35, 0, 35)
    keyButton.Position = UDim2.new(0, 8, 0.5, -17.5)
    keyButton.BackgroundColor3 = ACCENT
    keyButton.Text = currentKey and currentKey.Name:sub(1,1) or "?"
    keyButton.Font = Enum.Font.GothamBlack
    keyButton.TextSize = currentKey and 16 or 12
    keyButton.TextColor3 = BG_DARK
    keyButton.BorderSizePixel = 0
    keyButton.Parent = container
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0,8); kc.Parent = keyButton

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 50, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = TEXT_BRIGHT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    return keyButton
end

local function createNumberInput(parent, name, text, currentValue, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 45)
    container.Position = UDim2.new(0, 5, 0, yPos)
    container.BackgroundColor3 = BG_CARD
    container.BorderSizePixel = 0
    container.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = container
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(60,60,70); s.Thickness = 1; s.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = TEXT_BRIGHT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local numButton = Instance.new("TextButton")
    numButton.Size = UDim2.new(0, 80, 0, 30)
    numButton.Position = UDim2.new(1, -85, 0.5, -15)
    numButton.BackgroundColor3 = ACCENT
    numButton.Text = tostring(currentValue)
    numButton.Font = Enum.Font.GothamBold
    numButton.TextSize = 12
    numButton.TextColor3 = BG_DARK
    numButton.BorderSizePixel = 0
    numButton.Parent = container
    local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0,8); nc.Parent = numButton
    return numButton
end

-- Features Tab
local AutoLeftBtn    = createToggle(FeaturesFrame, "AutoLeft",     "Auto Left",      0)
local AutoRightBtn   = createToggle(FeaturesFrame, "AutoRight",    "Auto Right",     45)
local SpeedBoostBtn  = createToggle(FeaturesFrame, "SpeedBoost",   "Steal Speed",    90)
local AutoStealBtn   = createToggle(FeaturesFrame, "AutoSteal",    "Auto Steal",     135)
local BatAimbotBtn   = createToggle(FeaturesFrame, "BatAimbot",    "LOCK (Aimbot)",  180)
local GalaxyBtn      = createToggle(FeaturesFrame, "Galaxy",       "Jump Power",     225)
local OptimizerBtn   = createToggle(FeaturesFrame, "Optimizer",    "Performance",    270)
local AntiRagdollBtn = createToggle(FeaturesFrame, "AntiRagdoll",  "Anti Ragdoll",   315)
local NoAnimBtn      = createToggle(FeaturesFrame, "NoAnimations", "No Animations",  360)
local SpinbotBtn     = createToggle(FeaturesFrame, "Spinbot",      "Spinbot",        405)
local InfJumpBtn     = createToggle(FeaturesFrame, "InfJump",      "Inf Jump",       450)
local NoclipBtn      = createToggle(FeaturesFrame, "Noclip",       "Noclip",         495)
local FullbrightBtn  = createToggle(FeaturesFrame, "Fullbright",   "Fullbright",     540)

-- Keybinds Tab
local AutoLeftKey    = createKeybindButton(KeybindsFrame, "AutoLeft",     "Auto Left Keybind",     Keybinds.AutoLeft,     0)
local AutoRightKey   = createKeybindButton(KeybindsFrame, "AutoRight",    "Auto Right Keybind",    Keybinds.AutoRight,    55)
local SpeedBoostKey  = createKeybindButton(KeybindsFrame, "SpeedBoost",   "Speed Boost Keybind",   Keybinds.SpeedBoost,   110)
local AutoStealKey   = createKeybindButton(KeybindsFrame, "AutoSteal",    "Auto Steal Keybind",    Keybinds.AutoSteal,    165)
local BatAimbotKey   = createKeybindButton(KeybindsFrame, "BatAimbot",    "Lock Keybind",          Keybinds.BatAimbot,    220)
local AntiRagdollKey = createKeybindButton(KeybindsFrame, "AntiRagdoll",  "Anti Ragdoll Keybind",  Keybinds.AntiRagdoll,  275)
local NoAnimKey      = createKeybindButton(KeybindsFrame, "NoAnimations", "No Anim Keybind",       Keybinds.NoAnimations, 330)

-- Settings Tab
local SpeedBoostInput    = createNumberInput(SettingsFrame, "SpeedBoost",     "Steal Speed",          Config.StealSpeed,       0)
local GrabRadiusInput    = createNumberInput(SettingsFrame, "GrabRadius",     "Grab Radius",          Config.GrabRadius,       50)
local GalaxyGravityInput = createNumberInput(SettingsFrame, "GalaxyGravity",  "Gravity %",            Config.GalaxyGravityPercent, 100)
local HopPowerInput      = createNumberInput(SettingsFrame, "HopPower",       "Hop Power",            Config.HopPower,         150)
local AimbotRadiusInput  = createNumberInput(SettingsFrame, "AimbotRadius",   "Aimbot Radius",        Config.AimbotRadius,     200)
local AimbotSpeedInput   = createNumberInput(SettingsFrame, "AimbotSpeed",    "Aimbot Speed",         Config.BatAimbotSpeed,   250)
local WalkSpeedInput     = createNumberInput(SettingsFrame, "WalkSpeed",      "Walk Speed",           Config.WalkSpeed,        300)
local FOVInput           = createNumberInput(SettingsFrame, "FOV",            "Field of View",        Config.FOV,              350)

local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(1, -10, 0, 40)
SaveButton.Position = UDim2.new(0, 5, 0, 310)
SaveButton.BackgroundColor3 = ACCENT
SaveButton.Text = "SAVE CONFIG"
SaveButton.Font = Enum.Font.GothamBlack
SaveButton.TextSize = 14
SaveButton.TextColor3 = BG_DARK
SaveButton.BorderSizePixel = 0
SaveButton.Parent = SettingsFrame
local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,10); sc.Parent = SaveButton

SaveButton.MouseButton1Click:Connect(function()
    saveConfig()
    SaveButton.Text = "SAVED!"
    task.wait(1)
    SaveButton.Text = "SAVE CONFIG"
end)

-- Mobile Tab
local _ml = Instance.new("TextLabel")
_ml.Size = UDim2.new(1,-10,0,30); _ml.Position = UDim2.new(0,5,0,0)
_ml.BackgroundTransparency = 1; _ml.Text = "MOBILE BUTTONS"
_ml.Font = Enum.Font.GothamBlack; _ml.TextSize = 13
_ml.TextColor3 = ACCENT; _ml.TextXAlignment = Enum.TextXAlignment.Left
_ml.Parent = MobileFrame

local MobileSupportBtn = createToggle(MobileFrame, "MobileSupport", "Show Mobile Buttons", 35)

local _mi = Instance.new("TextLabel")
_mi.Size = UDim2.new(1,-10,0,60); _mi.Position = UDim2.new(0,5,0,82)
_mi.BackgroundTransparency = 1
_mi.Text = "4 buttons: AUTO STEAL | LOCK (AIMBOT) | AUTO LEFT | AUTO RIGHT"
_mi.Font = Enum.Font.Gotham; _mi.TextSize = 11
_mi.TextColor3 = TEXT_DIM; _mi.TextWrapped = true
_mi.TextXAlignment = Enum.TextXAlignment.Left; _mi.Parent = MobileFrame

-- Mobile Buttons GUI
local MobileButtonsGui = Instance.new("ScreenGui")
MobileButtonsGui.Name = "S7MobileButtons"; MobileButtonsGui.ResetOnSpawn = false
MobileButtonsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MobileButtonsGui.Enabled = false; MobileButtonsGui.Parent = player:WaitForChild("PlayerGui")

local function createMobileButton(text, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 0, 65); btn.Position = position
    btn.BackgroundColor3 = BG_CARD; btn.Text = text
    btn.TextColor3 = TEXT_BRIGHT; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10; btn.TextWrapped = true; btn.BorderSizePixel = 0
    btn.Parent = MobileButtonsGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
    local s = Instance.new("UIStroke"); s.Color = ACCENT; s.Thickness = 2; s.Transparency = 0.3; s.Parent = btn
    return btn
end

local MobileUngrabBtn = createMobileButton("UNGRAB",     UDim2.new(1,-80,0.10,0))
local MobileBatBtn    = createMobileButton("LOCK",       UDim2.new(1,-80,0.24,0))
local MobileTauntBtn  = createMobileButton("TAUNT",      UDim2.new(1,-80,0.38,0))
local MobileSpinBtn   = createMobileButton("SPIN",       UDim2.new(1,-80,0.52,0))
local MobileLeftMobBtn  = createMobileButton("AUTO LEFT",  UDim2.new(0,10,0.3,-27))
local MobileRightMobBtn = createMobileButton("AUTO RIGHT", UDim2.new(0,10,0.3,46))

MobileSupportBtn.MouseButton1Click:Connect(function()
    local newState = MobileSupportBtn.BackgroundColor3 ~= ACCENT
    updateToggle(MobileSupportBtn, newState)
    MobileButtonsGui.Enabled = newState
end)

-- Mobile Left Button
MobileLeftMobBtn.MouseButton1Click:Connect(function()
    if leftActive then
        leftActive = false
        MobileLeftMobBtn.BackgroundColor3 = BG_CARD
        MobileLeftMobBtn.TextColor3 = TEXT_BRIGHT
        local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.zero end
        local hum = getHum(); if hum then hum:Move(Vector3.zero, false) end
        return
    end
    leftActive = true; rightActive = false
    MobileLeftMobBtn.BackgroundColor3 = ACCENT
    MobileLeftMobBtn.TextColor3 = BG_DARK
    MobileRightMobBtn.BackgroundColor3 = BG_CARD
    MobileRightMobBtn.TextColor3 = TEXT_BRIGHT
    task.spawn(function()
        while leftActive do
            moveToTargets(leftTargets)
            if not leftActive then break end
            task.wait(0.25)
            if not leftActive then break end
            local oldSpeed = speed
            speed = Config.StealSpeed
            moveToTargets(rightTargets)
            speed = oldSpeed
            if not leftActive then break end
            task.wait(0.3)
        end
        leftActive = false
        local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.zero end
        local hum = getHum(); if hum then hum:Move(Vector3.zero, false) end
        MobileLeftMobBtn.BackgroundColor3 = BG_CARD
        MobileLeftMobBtn.TextColor3 = TEXT_BRIGHT
    end)
end)

-- Mobile Right Button
MobileRightMobBtn.MouseButton1Click:Connect(function()
    if rightActive then
        rightActive = false
        MobileRightMobBtn.BackgroundColor3 = BG_CARD
        MobileRightMobBtn.TextColor3 = TEXT_BRIGHT
        local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.zero end
        local hum = getHum(); if hum then hum:Move(Vector3.zero, false) end
        return
    end
    rightActive = true; leftActive = false
    MobileRightMobBtn.BackgroundColor3 = ACCENT
    MobileRightMobBtn.TextColor3 = BG_DARK
    MobileLeftMobBtn.BackgroundColor3 = BG_CARD
    MobileLeftMobBtn.TextColor3 = TEXT_BRIGHT
    task.spawn(function()
        while rightActive do
            moveToTargets(rightTargets)
            if not rightActive then break end
            task.wait(0.25)
            if not rightActive then break end
            local oldSpeed = speed
            speed = Config.StealSpeed
            moveToTargets(leftTargets)
            speed = oldSpeed
            if not rightActive then break end
            task.wait(0.3)
        end
        rightActive = false
        local h = getHRP(); if h then h.AssemblyLinearVelocity = Vector3.zero end
        local hum = getHum(); if hum then hum:Move(Vector3.zero, false) end
        MobileRightMobBtn.BackgroundColor3 = BG_CARD
        MobileRightMobBtn.TextColor3 = TEXT_BRIGHT
    end)
end)

-- Mobile Ungrab Button
MobileUngrabBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local char = player.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        hum:UnequipTools()
        local rs = game:GetService("ReplicatedStorage")
        for _, v in ipairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local name = v.Name:lower()
                if name:find("drop") or name:find("release") or name:find("ungrab") then
                    pcall(function() v:FireServer() end)
                end
            end
        end
    end)
    TweenService:Create(MobileUngrabBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT}):Play()
    MobileUngrabBtn.TextColor3 = BG_DARK
    task.delay(0.35, function()
        TweenService:Create(MobileUngrabBtn, TweenInfo.new(0.15), {BackgroundColor3 = BG_CARD}):Play()
        MobileUngrabBtn.TextColor3 = TEXT_BRIGHT
    end)
end)

-- Mobile Lock (Bat Aimbot) Button
MobileBatBtn.MouseButton1Click:Connect(function()
    local newState = BatAimbotBtn.BackgroundColor3 ~= ACCENT
    updateToggle(BatAimbotBtn, newState)
    MobileBatBtn.BackgroundColor3 = newState and ACCENT or BG_CARD
    MobileBatBtn.TextColor3 = newState and BG_DARK or TEXT_BRIGHT
    if newState then startBatAimbot() else stopBatAimbot() end
end)

-- Mobile Spin Button
local spinMobileOn = false
MobileSpinBtn.MouseButton1Click:Connect(function()
    spinMobileOn = not spinMobileOn
    MobileSpinBtn.BackgroundColor3 = spinMobileOn and ACCENT or BG_CARD
    MobileSpinBtn.TextColor3 = spinMobileOn and BG_DARK or TEXT_BRIGHT
    if spinMobileOn then startSpinbot() else stopSpinbot() end
end)

-- Mobile Taunt Button
MobileTauntBtn.MouseButton1Click:Connect(function()
    sendTaunt()
    TweenService:Create(MobileTauntBtn, TweenInfo.new(0.15), {BackgroundColor3 = ACCENT}):Play()
    MobileTauntBtn.TextColor3 = BG_DARK
    task.delay(0.6, function()
        TweenService:Create(MobileTauntBtn, TweenInfo.new(0.15), {BackgroundColor3 = BG_CARD}):Play()
        MobileTauntBtn.TextColor3 = TEXT_BRIGHT
    end)
end)

-- Toggle Actions
AutoLeftBtn.MouseButton1Click:Connect(function()
    local newState = AutoLeftBtn.BackgroundColor3 ~= ACCENT
    updateToggle(AutoLeftBtn, newState)
    if newState then
        updateToggle(AutoRightBtn, false); leftActive = true
        task.spawn(function() moveToTargets(leftTargets); leftActive = false; updateToggle(AutoLeftBtn, false) end)
    else leftActive = false end
end)

AutoRightBtn.MouseButton1Click:Connect(function()
    local newState = AutoRightBtn.BackgroundColor3 ~= ACCENT
    updateToggle(AutoRightBtn, newState)
    if newState then
        updateToggle(AutoLeftBtn, false); rightActive = true
        task.spawn(function() moveToTargets(rightTargets); rightActive = false; updateToggle(AutoRightBtn, false) end)
    else rightActive = false end
end)

SpeedBoostBtn.MouseButton1Click:Connect(function()
    local newState = SpeedBoostBtn.BackgroundColor3 ~= ACCENT
    updateToggle(SpeedBoostBtn, newState)
    if newState then startSpeedBoost() else stopSpeedBoost() end
end)

AutoStealBtn.MouseButton1Click:Connect(function()
    local newState = AutoStealBtn.BackgroundColor3 ~= ACCENT
    updateToggle(AutoStealBtn, newState)
    if newState then
        task.spawn(function() initAutoStealGUI(); createCircle() end)
    else
        if autoStealGui then pcall(function() autoStealGui:Destroy() end); autoStealGui = nil end
        for _, p in ipairs(circleParts) do if p then pcall(function() p:Destroy() end) end end
        table.clear(circleParts)
    end
end)

BatAimbotBtn.MouseButton1Click:Connect(function()
    local newState = BatAimbotBtn.BackgroundColor3 ~= ACCENT
    updateToggle(BatAimbotBtn, newState)
    if newState then startBatAimbot() else stopBatAimbot() end
end)

GalaxyBtn.MouseButton1Click:Connect(function()
    local newState = GalaxyBtn.BackgroundColor3 ~= ACCENT
    updateToggle(GalaxyBtn, newState)
    if newState then startGalaxy() else stopGalaxy() end
end)

OptimizerBtn.MouseButton1Click:Connect(function()
    local newState = OptimizerBtn.BackgroundColor3 ~= ACCENT
    updateToggle(OptimizerBtn, newState)
    if newState then enableOptimizer() else disableOptimizer() end
end)

AntiRagdollBtn.MouseButton1Click:Connect(function()
    local newState = AntiRagdollBtn.BackgroundColor3 ~= ACCENT
    updateToggle(AntiRagdollBtn, newState)
    if newState then startAntiRagdoll() else stopAntiRagdoll() end
end)

NoAnimBtn.MouseButton1Click:Connect(function()
    local newState = NoAnimBtn.BackgroundColor3 ~= ACCENT
    updateToggle(NoAnimBtn, newState)
    toggleNoAnimations(newState)
end)

SpinbotBtn.MouseButton1Click:Connect(function()
    local newState = SpinbotBtn.BackgroundColor3 ~= ACCENT
    updateToggle(SpinbotBtn, newState)
    if newState then startSpinbot() else stopSpinbot() end
end)

InfJumpBtn.MouseButton1Click:Connect(function()
    local newState = InfJumpBtn.BackgroundColor3 ~= ACCENT
    updateToggle(InfJumpBtn, newState)
    infJumpEnabled = newState
end)

NoclipBtn.MouseButton1Click:Connect(function()
    local newState = NoclipBtn.BackgroundColor3 ~= ACCENT
    updateToggle(NoclipBtn, newState)
    if newState then startNoclip() else stopNoclip() end
end)

FullbrightBtn.MouseButton1Click:Connect(function()
    local newState = FullbrightBtn.BackgroundColor3 ~= ACCENT
    updateToggle(FullbrightBtn, newState)
    if newState then enableFullbright() else disableFullbright() end
end)

-- Number Input Handlers
local numberInputs = {
    {button=SpeedBoostInput,    name="SpeedBoost",           min=1, max=100, cfg="StealSpeed"},
    {button=GrabRadiusInput,    name="GrabRadius",           min=1, max=300, cfg="GrabRadius"},
    {button=GalaxyGravityInput, name="GalaxyGravityPercent", min=1, max=130, cfg="GalaxyGravityPercent"},
    {button=HopPowerInput,      name="HopPower",             min=1, max=80,  cfg="HopPower"},
    {button=AimbotRadiusInput,  name="AimbotRadius",         min=1, max=999, cfg="AimbotRadius"},
    {button=AimbotSpeedInput,   name="BatAimbotSpeed",       min=1, max=200, cfg="BatAimbotSpeed"},
    {button=WalkSpeedInput,     name="WalkSpeed",            min=1, max=200, cfg="WalkSpeed"},
    {button=FOVInput,           name="FOV",                  min=10, max=120, cfg="FOV"},
}

for _, data in ipairs(numberInputs) do
    data.button.MouseButton1Click:Connect(function()
        local typing = false
        if typing then return end
        typing = true
        local textBox = Instance.new("TextBox")
        textBox.Size = data.button.Size; textBox.Position = data.button.Position
        textBox.BackgroundColor3 = data.button.BackgroundColor3
        textBox.Text = tostring(Config[data.cfg])
        textBox.Font = data.button.Font; textBox.TextSize = data.button.TextSize
        textBox.TextColor3 = BG_DARK; textBox.ClearTextOnFocus = false; textBox.BorderSizePixel = 0
        textBox.Parent = data.button.Parent
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,8); tc.Parent = textBox
        textBox:CaptureFocus()
        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local num = tonumber(textBox.Text)
                if num and num >= data.min and num <= data.max then
                    Config[data.cfg] = num
                    data.button.Text = tostring(Config[data.cfg])
                    if data.cfg == "FOV" then
                        pcall(function() workspace.CurrentCamera.FieldOfView = Config.FOV end)
                    end
                end
            end
            textBox:Destroy(); typing = false
        end)
    end)
end

-- Keybind Handlers
local changingKeybind = nil
local keybindButtons = {
    {button=AutoLeftKey,    name="AutoLeft"},
    {button=AutoRightKey,   name="AutoRight"},
    {button=SpeedBoostKey,  name="SpeedBoost"},
    {button=AutoStealKey,   name="AutoSteal"},
    {button=BatAimbotKey,   name="BatAimbot"},
    {button=AntiRagdollKey, name="AntiRagdoll"},
    {button=NoAnimKey,      name="NoAnimations"},
}

for _, data in ipairs(keybindButtons) do
    data.button.MouseButton1Click:Connect(function()
        if changingKeybind then return end
        changingKeybind = data.name
        data.button.Text = "..."
        data.button.TextSize = 9
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
                    Keybinds[data.name] = nil
                    data.button.Text = "?"; data.button.TextSize = 12
                else
                    Keybinds[data.name] = input.KeyCode
                    data.button.Text = input.KeyCode.Name:sub(1,1); data.button.TextSize = 16
                end
                saveConfig(); changingKeybind = nil; conn:Disconnect()
            end
        end)
    end)
end

-- Keyboard Input Handler
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if changingKeybind then return end
    if input.KeyCode == Enum.KeyCode.Space then spaceHeld = true; return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local function tog(btn, onFn, offFn)
        local newState = btn.BackgroundColor3 ~= ACCENT
        updateToggle(btn, newState)
        if newState then if onFn then onFn() end else if offFn then offFn() end end
    end

    if Keybinds.AutoLeft     and input.KeyCode == Keybinds.AutoLeft     then
        local newState = AutoLeftBtn.BackgroundColor3 ~= ACCENT
        updateToggle(AutoLeftBtn, newState)
        if newState then
            updateToggle(AutoRightBtn, false); leftActive = true
            task.spawn(function() moveToTargets(leftTargets); leftActive = false; updateToggle(AutoLeftBtn, false) end)
        else leftActive = false end
    elseif Keybinds.AutoRight  and input.KeyCode == Keybinds.AutoRight  then
        local newState = AutoRightBtn.BackgroundColor3 ~= ACCENT
        updateToggle(AutoRightBtn, newState)
        if newState then
            updateToggle(AutoLeftBtn, false); rightActive = true
            task.spawn(function() moveToTargets(rightTargets); rightActive = false; updateToggle(AutoRightBtn, false) end)
        else rightActive = false end
    elseif Keybinds.SpeedBoost and input.KeyCode == Keybinds.SpeedBoost then tog(SpeedBoostBtn,  startSpeedBoost, stopSpeedBoost)
    elseif Keybinds.AutoSteal  and input.KeyCode == Keybinds.AutoSteal  then
        local newState = AutoStealBtn.BackgroundColor3 ~= ACCENT
        updateToggle(AutoStealBtn, newState)
        if newState then
            task.spawn(function() initAutoStealGUI(); createCircle() end)
        else
            if autoStealGui then pcall(function() autoStealGui:Destroy() end); autoStealGui = nil end
            for _, p in ipairs(circleParts) do if p then pcall(function() p:Destroy() end) end end
            table.clear(circleParts)
        end
    elseif Keybinds.BatAimbot  and input.KeyCode == Keybinds.BatAimbot  then tog(BatAimbotBtn,   startBatAimbot,  stopBatAimbot)
    elseif Keybinds.AntiRagdoll and input.KeyCode == Keybinds.AntiRagdoll then tog(AntiRagdollBtn, startAntiRagdoll, stopAntiRagdoll)
    elseif Keybinds.NoAnimations and input.KeyCode == Keybinds.NoAnimations then
        local newState = NoAnimBtn.BackgroundColor3 ~= ACCENT
        updateToggle(NoAnimBtn, newState); toggleNoAnimations(newState)
    end
end)

-- Open/Close Button
local OpenCloseBtnGui = Instance.new("ScreenGui")
OpenCloseBtnGui.Name = "S7OpenClose"; OpenCloseBtnGui.ResetOnSpawn = false
OpenCloseBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OpenCloseBtnGui.Parent = player:WaitForChild("PlayerGui")

local OpenCloseBtn = Instance.new("TextButton")
OpenCloseBtn.Size = UDim2.new(0, 52, 0, 52); OpenCloseBtn.Position = UDim2.new(0, 10, 0.5, -26)
OpenCloseBtn.BackgroundColor3 = BG_DARK; OpenCloseBtn.Text = "S7"
OpenCloseBtn.TextSize = 14; OpenCloseBtn.Font = Enum.Font.GothamBlack
OpenCloseBtn.TextColor3 = ACCENT; OpenCloseBtn.BorderSizePixel = 0; OpenCloseBtn.Active = true
OpenCloseBtn.Parent = OpenCloseBtnGui
Instance.new("UICorner", OpenCloseBtn).CornerRadius = UDim.new(0, 14)
local OCStroke = Instance.new("UIStroke"); OCStroke.Thickness = 2.5; OCStroke.Color = ACCENT; OCStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; OCStroke.Parent = OpenCloseBtn

task.spawn(function()
    while OpenCloseBtn and OpenCloseBtn.Parent do
        for i=0,20 do if not OpenCloseBtn.Parent then break end OCStroke.Thickness=2.5+(i*0.05); task.wait(0.04) end
        for i=0,20 do if not OpenCloseBtn.Parent then break end OCStroke.Thickness=3.5-(i*0.05); task.wait(0.04) end
    end
end)

do
    local dragging, dragStart, startPos = false, nil, nil
    OpenCloseBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = OpenCloseBtn.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - dragStart
            OpenCloseBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

OpenCloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    TweenService:Create(OCStroke, TweenInfo.new(0.15), {Color = MainFrame.Visible and ACCENT or ACCENT}):Play()
end)

ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Apply saved feature states
if savedFeatures then
    if savedFeatures.SpeedBoost   then updateToggle(SpeedBoostBtn, true);    startSpeedBoost() end
    if savedFeatures.AutoSteal    then updateToggle(AutoStealBtn, true);     task.spawn(function() initAutoStealGUI(); createCircle() end) end
    if savedFeatures.BatAimbot    then updateToggle(BatAimbotBtn, true);     startBatAimbot() end
    if savedFeatures.Galaxy       then updateToggle(GalaxyBtn, true);        startGalaxy() end
    if savedFeatures.Optimizer    then updateToggle(OptimizerBtn, true);     enableOptimizer() end
    if savedFeatures.AntiRagdoll  then updateToggle(AntiRagdollBtn, true);   startAntiRagdoll() end
    if savedFeatures.NoAnimations then updateToggle(NoAnimBtn, true);        toggleNoAnimations(true) end
    if savedFeatures.Spinbot      then updateToggle(SpinbotBtn, true);       startSpinbot() end
    if savedFeatures.InfJump      then updateToggle(InfJumpBtn, true);       infJumpEnabled = true end
    if savedFeatures.Noclip       then updateToggle(NoclipBtn, true);        startNoclip() end
    if savedFeatures.Fullbright   then updateToggle(FullbrightBtn, true);    enableFullbright() end
end

task.spawn(function()
    for i = 0, 1, 0.05 do MainFrame.BackgroundTransparency = 1 - i; task.wait(0.01) end
end)

pcall(function() workspace.CurrentCamera.FieldOfView = Config.FOV end)
createDiscordTag()

print("S7 SHUB Loaded! discord.gg/qMtvNQg68s")
