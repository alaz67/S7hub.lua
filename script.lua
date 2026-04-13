--[[
    S7 Hub - Ultimate merged script
    - Black & purple theme
    - Floating draggable title "S7 Hub"
    - Speed customization
    - Auto-switch to steal speed when holding pet (Brainrot)
    - Hit Circle for Bat Aimbot
    - Auto Steal (no progress bar UI)
    - Full scrolling on all sections
    - Waypoint offsets, countdown auto play, bat aimbot, galaxy, steal, etc.
    - PC keybinds + mobile touch buttons
    - Config saving
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ACCENT  = Color3.fromRGB(138, 43, 226)
local WHITE   = Color3.fromRGB(240,240,255)
local BG      = Color3.fromRGB(5,5,8)
local CARD    = Color3.fromRGB(12,12,18)
local OFF_CLR = Color3.fromRGB(30,25,45)
local MOB_ON  = Color3.fromRGB(100,20,180)
local MOB_OFF = Color3.fromRGB(12,8,20)

local S7Speed = {
    Enabled = false, SpeedUI = nil, SpeedValue = 58,
    StealValue = 31, HeartbeatConn = nil,
    character = nil, hrp = nil, hum = nil
}

local function isCarryingPet()
    local char = player.Character
    if not char then return false end
    if char:FindFirstChild("Brainrot") then return true end
    if player:GetAttribute("Stealing") == true then return true end
    return false
end

local function enableS7Speed()
    if S7Speed.Enabled then return end
    S7Speed.Enabled = true
    if S7Speed.SpeedUI and S7Speed.SpeedUI.ToggleBtn then
        S7Speed.SpeedUI.ToggleBtn.Text = "ON"
        S7Speed.SpeedUI.Header.BackgroundColor3 = ACCENT
    end
    if player.Character then
        S7Speed.character = player.Character
        S7Speed.hrp = player.Character:WaitForChild("HumanoidRootPart")
        S7Speed.hum = player.Character:WaitForChild("Humanoid")
    end
    player.CharacterAdded:Connect(function(char)
        S7Speed.character = char
        S7Speed.hrp = char:WaitForChild("HumanoidRootPart")
        S7Speed.hum = char:WaitForChild("Humanoid")
    end)
    S7Speed.HeartbeatConn = RunService.Heartbeat:Connect(function()
        if not S7Speed.Enabled or not S7Speed.character or not S7Speed.hrp or not S7Speed.hum then return end
        local moveDir = S7Speed.hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local carrying = isCarryingPet()
            local targetSpeed = carrying and S7Speed.StealValue or S7Speed.SpeedValue
            if targetSpeed and targetSpeed > 0 then
                S7Speed.hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * targetSpeed, S7Speed.hrp.AssemblyLinearVelocity.Y, moveDir.Z * targetSpeed)
            end
        end
    end)
end

local function disableS7Speed()
    if not S7Speed.Enabled then return end
    S7Speed.Enabled = false
    if S7Speed.SpeedUI and S7Speed.SpeedUI.ToggleBtn then
        S7Speed.SpeedUI.ToggleBtn.Text = "OFF"
        S7Speed.SpeedUI.Header.BackgroundColor3 = Color3.fromRGB(30,25,45)
    end
    if S7Speed.HeartbeatConn then S7Speed.HeartbeatConn:Disconnect(); S7Speed.HeartbeatConn = nil end
end

local function createS7SpeedUI()
    local sg = Instance.new("ScreenGui"); sg.Name = "S7_SpeedCustomizer"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = CoreGui
    local mf = Instance.new("Frame"); mf.Size = UDim2.new(0,260,0,200); mf.Position = UDim2.new(0.5,-130,0.4,-100); mf.BackgroundColor3 = BG; mf.BackgroundTransparency = 0.15; mf.BorderSizePixel = 0; mf.Active = true; mf.Draggable = true; mf.Parent = sg
    Instance.new("UICorner",mf).CornerRadius = UDim.new(0,14)
    local ms = Instance.new("UIStroke",mf); ms.Color = ACCENT; ms.Thickness = 2
    local tb = Instance.new("Frame",mf); tb.Size = UDim2.new(1,0,0,36); tb.BackgroundColor3 = Color3.fromRGB(8,5,15); tb.BorderSizePixel = 0; Instance.new("UICorner",tb).CornerRadius = UDim.new(0,14)
    local tf = Instance.new("Frame",tb); tf.Size = UDim2.new(1,0,0,16); tf.Position = UDim2.new(0,0,1,-16); tf.BackgroundColor3 = Color3.fromRGB(8,5,15); tf.BorderSizePixel = 0
    local tl = Instance.new("TextLabel",tb); tl.Size = UDim2.new(1,-50,1,0); tl.Position = UDim2.new(0,12,0,0); tl.BackgroundTransparency = 1; tl.Text = "S7 SPEED CUSTOMIZER"; tl.TextColor3 = ACCENT; tl.TextSize = 13; tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Font = Enum.Font.GothamBold
    local cb = Instance.new("TextButton",tb); cb.Size = UDim2.new(0,26,0,26); cb.Position = UDim2.new(1,-34,0.5,-13); cb.BackgroundColor3 = Color3.fromRGB(25,15,40); cb.Text = "X"; cb.TextColor3 = ACCENT; cb.TextSize = 14; cb.Font = Enum.Font.GothamBold; cb.BorderSizePixel = 0; Instance.new("UICorner",cb).CornerRadius = UDim.new(0,8)
    local hd = Instance.new("Frame",mf); hd.Size = UDim2.new(1,-20,0,48); hd.Position = UDim2.new(0,10,0,48); hd.BackgroundColor3 = Color3.fromRGB(30,25,45); hd.BorderSizePixel = 0; Instance.new("UICorner",hd).CornerRadius = UDim.new(0,10); Instance.new("UIStroke",hd).Color = ACCENT
    local tog = Instance.new("TextButton",hd); tog.Size = UDim2.new(1,0,1,0); tog.BackgroundTransparency = 1; tog.Text = "OFF"; tog.TextColor3 = WHITE; tog.TextSize = 20; tog.Font = Enum.Font.GothamBold
    local function mkRow(lbt,dv,yp)
        local lb = Instance.new("TextLabel",mf); lb.Size = UDim2.new(0.6,0,0,32); lb.Position = UDim2.new(0,12,0,yp); lb.BackgroundTransparency = 1; lb.Text = lbt; lb.TextColor3 = Color3.fromRGB(180,170,200); lb.TextSize = 13; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Font = Enum.Font.GothamBold
        local bx = Instance.new("TextBox",mf); bx.Size = UDim2.new(0,85,0,32); bx.Position = UDim2.new(1,-97,0,yp); bx.BackgroundColor3 = Color3.fromRGB(20,15,35); bx.Text = tostring(dv); bx.TextColor3 = ACCENT; bx.Font = Enum.Font.GothamBold; bx.TextSize = 14; bx.ClearTextOnFocus = false; Instance.new("UICorner",bx).CornerRadius = UDim.new(0,8); Instance.new("UIStroke",bx).Color = ACCENT
        return bx
    end
    local si = mkRow("NORMAL SPEED",S7Speed.SpeedValue,110)
    local sti = mkRow("CARRY SPEED",S7Speed.StealValue,155)
    tog.MouseButton1Click:Connect(function() if S7Speed.Enabled then disableS7Speed() else enableS7Speed() end end)
    si.FocusLost:Connect(function() local n=tonumber(si.Text); if n then S7Speed.SpeedValue=math.clamp(n,1,200); si.Text=tostring(S7Speed.SpeedValue) else si.Text=tostring(S7Speed.SpeedValue) end end)
    sti.FocusLost:Connect(function() local n=tonumber(sti.Text); if n then S7Speed.StealValue=math.clamp(n,1,200); sti.Text=tostring(S7Speed.StealValue) else sti.Text=tostring(S7Speed.StealValue) end end)
    cb.MouseButton1Click:Connect(function() if S7Speed.Enabled then disableS7Speed() end; sg:Destroy(); S7Speed.SpeedUI = nil end)
    S7Speed.SpeedUI = {ScreenGui=sg,ToggleBtn=tog,Header=hd}
end

local HitCircle = {Enabled=false,Conn=nil,Circle=nil,Align=nil,Attach=nil,FLY_SPEED=55}

local function getNearestPlayerForBat()
    local char = player.Character; if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local nearestPlayer,nearestDistance = nil,math.huge; local myPos = hrp.Position
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
            if d < nearestDistance then nearestDistance = d; nearestPlayer = p end
        end
    end
    return nearestPlayer,nearestDistance
end

local function findBatTool()
    local c = player.Character; if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then return ch end end
    if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then return ch end end end
    return nil
end

local function enableHitCircle()
    if HitCircle.Enabled then return end; HitCircle.Enabled = true
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
    HitCircle.Attach = Instance.new("Attachment",hrp)
    HitCircle.Align = Instance.new("AlignOrientation",hrp); HitCircle.Align.Attachment0 = HitCircle.Attach; HitCircle.Align.Mode = Enum.OrientationAlignmentMode.OneAttachment; HitCircle.Align.RigidityEnabled = true
    HitCircle.Circle = Instance.new("Part"); HitCircle.Circle.Shape = Enum.PartType.Cylinder; HitCircle.Circle.Material = Enum.Material.Neon; HitCircle.Circle.Size = Vector3.new(0.05,14.5,14.5); HitCircle.Circle.Color = ACCENT; HitCircle.Circle.CanCollide = false; HitCircle.Circle.Massless = true; HitCircle.Circle.Parent = Workspace
    local weld = Instance.new("Weld"); weld.Part0 = hrp; weld.Part1 = HitCircle.Circle; weld.C0 = CFrame.new(0,-1,0)*CFrame.Angles(0,0,math.rad(90)); weld.Parent = HitCircle.Circle
    local batCD = false
    local function hitBat() if batCD then return end; batCD = true; local bat = findBatTool(); if bat then pcall(function() bat:Activate() end) end; task.delay(0.08,function() batCD = false end) end
    HitCircle.Conn = RunService.RenderStepped:Connect(function()
        if not HitCircle.Enabled then return end
        local c2 = player.Character; if not c2 then return end
        local hrp2 = c2:FindFirstChild("HumanoidRootPart"); local hum2 = c2:FindFirstChildOfClass("Humanoid"); if not hrp2 or not hum2 then return end
        local target,distance = getNearestPlayerForBat()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local tp = target.Character.HumanoidRootPart.Position
            hum2.AutoRotate = false; HitCircle.Align.Enabled = true
            HitCircle.Align.CFrame = CFrame.lookAt(hrp2.Position,Vector3.new(tp.X,hrp2.Position.Y,tp.Z))
            hrp2.AssemblyLinearVelocity = (tp-hrp2.Position).Unit*HitCircle.FLY_SPEED
            if distance <= 7.25 then local bat = findBatTool(); if bat then if bat.Parent ~= c2 then hum2:EquipTool(bat); task.wait(0.05) end; hitBat() end end
        else HitCircle.Align.Enabled = false; hum2.AutoRotate = true end
    end)
end

local function disableHitCircle()
    if not HitCircle.Enabled then return end; HitCircle.Enabled = false
    if HitCircle.Conn then HitCircle.Conn:Disconnect(); HitCircle.Conn = nil end
    if HitCircle.Circle then HitCircle.Circle:Destroy(); HitCircle.Circle = nil end
    if HitCircle.Align then HitCircle.Align:Destroy(); HitCircle.Align = nil end
    if HitCircle.Attach then HitCircle.Attach:Destroy(); HitCircle.Attach = nil end
    local char = player.Character; if char and char:FindFirstChild("Humanoid") then char.Humanoid.AutoRotate = true end
end

-- AUTO STEAL (kein UI Fenster)
local AutoSteal = {Enabled=false,STEAL_RADIUS=8,STEAL_DURATION=0.2,isStealing=false,StealData={},heartbeatConn=nil}

local function getHRP() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end

local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots"); if not plots then return false end
    local plot = plots:FindFirstChild(pn); if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb = sign:FindFirstChild("YourBase"); return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function findNearestPrompt()
    local hrp = getHRP(); if not hrp then return nil end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local nearest,dist = nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do
            local base = pod:FindFirstChild("Base"); if not base then continue end
            local spawn = base:FindFirstChild("Spawn"); if not spawn then continue end
            local d = (spawn.Position-hrp.Position).Magnitude
            if d <= AutoSteal.STEAL_RADIUS and d < dist then
                local att = spawn:FindFirstChild("PromptAttachment")
                if att then for _,p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") and p.ActionText and p.ActionText:find("Steal") then nearest,dist = p,d end end end
            end
        end
    end
    return nearest
end

local function executeSteal(prompt)
    if AutoSteal.isStealing then return end
    if not AutoSteal.StealData[prompt] then
        AutoSteal.StealData[prompt] = {hold={},trigger={},ready=true}
        if getconnections then
            for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(AutoSteal.StealData[prompt].hold,c.Function) end end
            for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(AutoSteal.StealData[prompt].trigger,c.Function) end end
        end
    end
    local data = AutoSteal.StealData[prompt]; if not data.ready then return end
    data.ready = false; AutoSteal.isStealing = true
    task.spawn(function()
        for _,f in ipairs(data.hold) do pcall(function() f() end) end
        task.wait(AutoSteal.STEAL_DURATION)
        for _,f in ipairs(data.trigger) do pcall(function() f() end) end
        data.ready = true; AutoSteal.isStealing = false
    end)
end

local function enableAutoSteal()
    if AutoSteal.Enabled then return end; AutoSteal.Enabled = true
    AutoSteal.heartbeatConn = RunService.Heartbeat:Connect(function()
        if not AutoSteal.Enabled or AutoSteal.isStealing then return end
        local ok,prompt = pcall(findNearestPrompt); if ok and prompt then pcall(executeSteal,prompt) end
    end)
end

local function disableAutoSteal()
    if not AutoSteal.Enabled then return end; AutoSteal.Enabled = false
    if AutoSteal.heartbeatConn then AutoSteal.heartbeatConn:Disconnect(); AutoSteal.heartbeatConn = nil end
end

local WPRight = {
    {label="R1",pos=Vector3.new(-475.37,-7,26.63),color=Color3.new(0.313726,0.705882,1),offset=Vector3.new(0,0,0)},
    {label="R2",pos=Vector3.new(-486.76,-3.65,17.55),color=Color3.new(0.392157,1,0.470588),offset=Vector3.new(0,0,0)},
    {label="R3",pos=Vector3.new(-475.57,-5.62,31.04),color=Color3.new(1,0.862745,0.196078),offset=Vector3.new(0,0,0)},
    {label="R4",pos=Vector3.new(-476.09,-6.56,97.06),color=Color3.new(1,0.313726,0.627451),offset=Vector3.new(0,0,0)},
}
local WPLeft = {
    {label="L1",pos=Vector3.new(-476.48,-6.28,92.73),color=Color3.new(0.313726,0.705882,1),offset=Vector3.new(0,0,0)},
    {label="L2",pos=Vector3.new(-483.12,-4.95,94.80),color=Color3.new(0.392157,1,0.470588),offset=Vector3.new(0,0,0)},
    {label="L3",pos=Vector3.new(-473.38,-8.40,22.34),color=Color3.new(1,0.862745,0.196078),offset=Vector3.new(0,0,0)},
    {label="L4",pos=Vector3.new(-483.12,-4.95,94.80),color=Color3.new(1,0.313726,0.627451),offset=Vector3.new(0,0,0)},
}

local function wpPos(wp) return wp.pos+wp.offset end
local function getL1() return wpPos(WPLeft[1]) end
local function getLEND() return wpPos(WPLeft[2]) end
local function getLFINAL() return wpPos(WPLeft[3]) end
local function getR1() return wpPos(WPRight[1]) end
local function getREND() return wpPos(WPRight[2]) end
local function getRFINAL() return wpPos(WPRight[4]) end

local POS_L1=getL1(); local POS_L2=getLEND(); local LFINAL=getLFINAL()
local POS_R1=getR1(); local POS_R2=getREND(); local RFINAL=getRFINAL()
local TPA=Vector3.new(-472.60,-7.00,57.52)
local TPRB=Vector3.new(-471.76,-7.00,26.22)
local TPR1=Vector3.new(-483.51,-5.10,18.89)

NORMAL_SPEED=58; SLOW_SPEED=31; aplOn=false; aprOn=false; aplPhase=1; aprPhase=1; aplConn=nil; aprConn=nil
STEAL_RADIUS=20; STEAL_DURATION=0.35; antiRagdollEnabled=false; unwalkEnabled=false; unwalkConn=nil
batAimbotEnabled=false; BAT_ENGAGE_RANGE=5; AIMBOT_SPEED=60; MELEE_OFFSET=3; aimbotConnection=nil; lockedTarget=nil
galaxyEnabled=false; hopsEnabled=false; galaxyVF=nil; galaxyAtt=nil
DEFAULT_GRAVITY=196.2; GALAXY_GRAVITY=42; GALAXY_HOP=35; HOP_COOLDOWN=0.08; lastHop=0; spaceHeld=false
spinBotEnabled=false; spinBAV=nil; SPIN_SPEED=19; espEnabled=true; espConns={}
optimizerEnabled=false; xrayOrig={}; fovValue=70; fovConn=nil; slowDownEnabled=false
tauntActive=false; tauntLoop=nil; infJumpEnabled=true; INF_JUMP_FORCE=54; CLAMP_FALL=80
gChar=nil; gHum=nil; gHrp=nil; speedBB=nil
ProgressBarFill=nil; ProgressLabel=nil; ProgressPctLabel=nil; RadiusInput=nil
animalCache={}; promptCache={}; stealCache={}
toggleStates={}; mobileButtons={}; mobBtnRefs={}; AntiRagdollConns={}
CONFIG_KEY="S7_Hub_Config"; changingKeybind=nil; SavedToggleStates={}
RagdollTPEnabled=false; tpWasRagdolled=false; tpCooldown=false
tpStateConn=nil; tpChildConn=nil; tpChildRemConn=nil; tpMedusaActive=false
local TP_PRE_STEP=Vector3.new(-452.5,-6.6,57.7)
local TP_STEPS={Left={Vector3.new(-475.0,-6.6,94.7),Vector3.new(-482.6,-4.7,94.6)},Right={Vector3.new(-475.2,-6.6,23.5),Vector3.new(-482.2,-4.7,23.4)}}
local TP_OUTSIDE_STEPS={Left={Vector3.new(-466.0,-6.6,94.7),Vector3.new(-472.0,-6.6,94.7)},Right={Vector3.new(-466.0,-6.6,23.5),Vector3.new(-472.0,-6.6,23.5)}}
floatEnabled=false; floatConn=nil; autoPlayAfterTP=false; autoSwingEnabled=false
medusaCounterEnabled=false; noCamCollisionEnabled=false; shinyGraphicsEnabled=false; removeAccessoriesEnabled=false
autoPlayCDEnabled=false; cdWatching=false; cdLastNum=-1; cdConn=nil; lastAutoPlayMode="Left"; wpOffsetPanel=nil

Keybinds={AutoLeft=Enum.KeyCode.Q,AutoRight=Enum.KeyCode.E,AutoSteal=Enum.KeyCode.V,BatAimbot=Enum.KeyCode.Z,AntiRagdoll=Enum.KeyCode.X,Unwalk=Enum.KeyCode.N,SlowDown=Enum.KeyCode.F7,RagdollTP=Enum.KeyCode.F8,Drop=Enum.KeyCode.F3,Taunt=Enum.KeyCode.F4,TPDown=Enum.KeyCode.G}
KeybindButtons={}

local function saveConfig()
    pcall(function()
        if not writefile then return end
        local lo,ro={},{}
        for i,wp in ipairs(WPLeft) do lo[i]={wp.offset.X,wp.offset.Y,wp.offset.Z} end
        for i,wp in ipairs(WPRight) do ro[i]={wp.offset.X,wp.offset.Y,wp.offset.Z} end
        local d={NORMAL_SPEED=NORMAL_SPEED,SLOW_SPEED=SLOW_SPEED,STEAL_RADIUS=STEAL_RADIUS,STEAL_DURATION=STEAL_DURATION,GALAXY_GRAVITY=GALAXY_GRAVITY,GALAXY_HOP=GALAXY_HOP,SPIN_SPEED=SPIN_SPEED,fovValue=fovValue,AIMBOT_SPEED=AIMBOT_SPEED,BAT_ENGAGE_RANGE=BAT_ENGAGE_RANGE,leftOffsets=lo,rightOffsets=ro,autoPlayCDEnabled=autoPlayCDEnabled,autoPlayAfterTP=autoPlayAfterTP,autoSwingEnabled=autoSwingEnabled,floatEnabled=floatEnabled,medusaCounterEnabled=medusaCounterEnabled,noCamCollisionEnabled=noCamCollisionEnabled,shinyGraphicsEnabled=shinyGraphicsEnabled,removeAccessoriesEnabled=removeAccessoriesEnabled}
        for k,v in pairs(toggleStates) do d["TOGGLE_"..k]=v.state end
        for k,v in pairs(Keybinds) do d["KEY_"..k]=v.Name end
        writefile(CONFIG_KEY..".json",game:GetService("HttpService"):JSONEncode(d))
    end)
end

local function loadConfig()
    pcall(function()
        if not(readfile and isfile and isfile(CONFIG_KEY..".json")) then return end
        local ok,d=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_KEY..".json")) end)
        if not(ok and d) then return end
        if d.NORMAL_SPEED then NORMAL_SPEED=d.NORMAL_SPEED end; if d.SLOW_SPEED then SLOW_SPEED=d.SLOW_SPEED end
        if d.STEAL_RADIUS then STEAL_RADIUS=d.STEAL_RADIUS end; if d.STEAL_DURATION then STEAL_DURATION=d.STEAL_DURATION end
        if d.GALAXY_GRAVITY then GALAXY_GRAVITY=d.GALAXY_GRAVITY end; if d.GALAXY_HOP then GALAXY_HOP=d.GALAXY_HOP end
        if d.SPIN_SPEED then SPIN_SPEED=d.SPIN_SPEED end; if d.fovValue then fovValue=d.fovValue end
        if d.AIMBOT_SPEED then AIMBOT_SPEED=d.AIMBOT_SPEED end; if d.BAT_ENGAGE_RANGE then BAT_ENGAGE_RANGE=d.BAT_ENGAGE_RANGE end
        if d.leftOffsets then for i,off in ipairs(d.leftOffsets) do if WPLeft[i] then WPLeft[i].offset=Vector3.new(off[1],off[2],off[3]) end end end
        if d.rightOffsets then for i,off in ipairs(d.rightOffsets) do if WPRight[i] then WPRight[i].offset=Vector3.new(off[1],off[2],off[3]) end end end
        if d.autoPlayCDEnabled~=nil then autoPlayCDEnabled=d.autoPlayCDEnabled end
        if d.autoPlayAfterTP~=nil then autoPlayAfterTP=d.autoPlayAfterTP end
        if d.autoSwingEnabled~=nil then autoSwingEnabled=d.autoSwingEnabled end
        if d.floatEnabled~=nil then floatEnabled=d.floatEnabled end
        if d.medusaCounterEnabled~=nil then medusaCounterEnabled=d.medusaCounterEnabled end
        if d.noCamCollisionEnabled~=nil then noCamCollisionEnabled=d.noCamCollisionEnabled end
        if d.shinyGraphicsEnabled~=nil then shinyGraphicsEnabled=d.shinyGraphicsEnabled end
        if d.removeAccessoriesEnabled~=nil then removeAccessoriesEnabled=d.removeAccessoriesEnabled end
        for k in pairs(Keybinds) do if d["KEY_"..k] then pcall(function() Keybinds[k]=Enum.KeyCode[d["KEY_"..k]] end) end end
        SavedToggleStates={}; for k,v in pairs(d) do if k:sub(1,7)=="TOGGLE_" then SavedToggleStates[k:sub(8)]=v end end
        POS_L1=getL1(); POS_L2=getLEND(); LFINAL=getLFINAL(); POS_R1=getR1(); POS_R2=getREND(); RFINAL=getRFINAL()
    end)
end
loadConfig()

UserInputService.JumpRequest:Connect(function() if not infJumpEnabled then return end; local h=getHRP(); if h then h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,INF_JUMP_FORCE,h.AssemblyLinearVelocity.Z) end end)
RunService.Heartbeat:Connect(function() if not infJumpEnabled then return end; local h=getHRP(); if h and h.AssemblyLinearVelocity.Y<-CLAMP_FALL then h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,-CLAMP_FALL,h.AssemblyLinearVelocity.Z) end end)

local _wfConns={}; local _wfActive=false
local function startWalkFling()
    _wfActive=true
    table.insert(_wfConns,RunService.Stepped:Connect(function() if not _wfActive then return end; for _,p in ipairs(Players:GetPlayers()) do if p~=player and p.Character then for _,pt in ipairs(p.Character:GetChildren()) do if pt:IsA("BasePart") then pt.CanCollide=false end end end end end))
    local co=coroutine.create(function() while _wfActive do RunService.Heartbeat:Wait(); local c=player.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); if not root then RunService.Heartbeat:Wait() continue end; local vel=root.Velocity; root.Velocity=vel*10000+Vector3.new(0,10000,0); RunService.RenderStepped:Wait(); if root and root.Parent then root.Velocity=vel end; RunService.Stepped:Wait(); if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end end end)
    coroutine.resume(co); table.insert(_wfConns,co)
end
local function stopWalkFling() _wfActive=false; for _,c in ipairs(_wfConns) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() elseif typeof(c)=="thread" then pcall(task.cancel,c) end end; _wfConns={} end
local function doDrop() startWalkFling(); task.delay(0.4,stopWalkFling) end

local function sendTauntMessage() pcall(function() local TCS=game:GetService("TextChatService"); local ch=TCS.TextChannels:FindFirstChild("RBXGeneral"); if ch then ch:SendAsync("S7 Hub better") else game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents",1):WaitForChild("SayMessageRequest",1):FireServer("S7 Hub better","All") end end) end
local function startTauntSpam() if tauntLoop then return end; tauntActive=true; tauntLoop=task.spawn(function() while tauntActive do sendTauntMessage(); task.wait(0.5) end end) end
local function stopTauntSpam() tauntActive=false; if tauntLoop then task.cancel(tauntLoop); tauntLoop=nil end end

local function makeSpeedBB()
    local c=player.Character; if not c then return end; local head=c:FindFirstChild("Head"); if not head then return end
    if speedBB then pcall(function() speedBB:Destroy() end) end
    speedBB=Instance.new("BillboardGui"); speedBB.Name="S7SpeedBB"; speedBB.Adornee=head; speedBB.Size=UDim2.new(0,130,0,30); speedBB.StudsOffset=Vector3.new(0,3.2,0); speedBB.AlwaysOnTop=true; speedBB.Parent=head
    local lbl=Instance.new("TextLabel"); lbl.Name="SpeedLbl"; lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=WHITE; lbl.TextStrokeColor3=ACCENT; lbl.TextStrokeTransparency=0.3; lbl.Font=Enum.Font.GothamBold; lbl.TextScaled=true; lbl.Text="Speed: 0"; lbl.Parent=speedBB
end
RunService.RenderStepped:Connect(function() if not speedBB or not speedBB.Parent then return end; local h=getHRP(); if not h then return end; local lbl=speedBB:FindFirstChild("SpeedLbl"); if not lbl then return end; local v=h.AssemblyLinearVelocity; lbl.Text="Speed: "..math.floor(Vector3.new(v.X,0,v.Z).Magnitude) end)

local function startAntiRagdoll()
    if #AntiRagdollConns>0 then return end
    local c=player.Character or player.CharacterAdded:Wait(); local humanoid=c:WaitForChild("Humanoid"); local root=c:WaitForChild("HumanoidRootPart"); local animator=humanoid:WaitForChild("Animator")
    local maxVelocity=40; local clampVelocity=25; local maxClamp=15; local lastVelocity=Vector3.new(0,0,0)
    local function IsRagdollState() local s=humanoid:GetState(); return s==Enum.HumanoidStateType.Physics or s==Enum.HumanoidStateType.Ragdoll or s==Enum.HumanoidStateType.FallingDown or s==Enum.HumanoidStateType.GettingUp end
    local function CleanRagdollEffects() for _,obj in pairs(c:GetDescendants()) do if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") or (obj:IsA("Attachment") and (obj.Name=="A" or obj.Name=="B")) then obj:Destroy() elseif obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then obj:Destroy() elseif obj:IsA("Motor6D") then obj.Enabled=true end end; for _,track in pairs(animator:GetPlayingAnimationTracks()) do local an=track.Animation and track.Animation.Name:lower() or ""; if an:find("rag") or an:find("fall") or an:find("hurt") or an:find("down") then track:Stop(0) end end end
    local function ReEnableControls() pcall(function() require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Enable() end) end
    table.insert(AntiRagdollConns,humanoid.StateChanged:Connect(function() if IsRagdollState() then humanoid:ChangeState(Enum.HumanoidStateType.Running); CleanRagdollEffects(); workspace.CurrentCamera.CameraSubject=humanoid; ReEnableControls() end end))
    table.insert(AntiRagdollConns,RunService.Heartbeat:Connect(function() if not antiRagdollEnabled then return end; if IsRagdollState() then CleanRagdollEffects(); local vel=root.AssemblyLinearVelocity; if (vel-lastVelocity).Magnitude>maxVelocity and vel.Magnitude>clampVelocity then root.AssemblyLinearVelocity=vel.Unit*math.min(vel.Magnitude,maxClamp) end; lastVelocity=vel end end))
    table.insert(AntiRagdollConns,c.DescendantAdded:Connect(function() if IsRagdollState() then CleanRagdollEffects() end end))
    table.insert(AntiRagdollConns,player.CharacterAdded:Connect(function(nc) c=nc; humanoid=nc:WaitForChild("Humanoid"); root=nc:WaitForChild("HumanoidRootPart"); animator=humanoid:WaitForChild("Animator"); lastVelocity=Vector3.new(0,0,0); ReEnableControls(); CleanRagdollEffects() end))
    ReEnableControls(); CleanRagdollEffects()
end
local function stopAntiRagdoll() for _,conn in pairs(AntiRagdollConns) do conn:Disconnect() end; AntiRagdollConns={} end

local MEDUSA_TP_NAMES={["Petrified"]=true,["Petrify"]=true,["Stone"]=true,["MedusaStone"]=true,["MedusaEffect"]=true,["Stoned"]=true,["MedusaHead"]=true,["Frozen"]=true,["Statue"]=true,["PetrifyEffect"]=true}
local function isMedusaTPChild(name) if MEDUSA_TP_NAMES[name] then return true end; local l=name:lower(); return l:find("medusa") or l:find("petri") or l:find("stone") or l:find("statue") or l:find("frozen") end
local TP_RAGDOLL_STATES={[Enum.HumanoidStateType.Physics]=true,[Enum.HumanoidStateType.FallingDown]=true,[Enum.HumanoidStateType.Ragdoll]=true}
local function detectEnemySide() local plots=workspace:FindFirstChild("Plots"); if not plots then return "Left" end; for _,plot in ipairs(plots:GetChildren()) do local sign=plot:FindFirstChild("PlotSign"); if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") and yb.Enabled then local center=plot:FindFirstChildWhichIsA("BasePart"); local z=center and center.Position.Z or 0; return z>60 and "Right" or "Left" end end end; return "Left" end
local function tpMoveTo(pos) local r=getHRP(); if not r then return end; r.CFrame=CFrame.new(pos); r.AssemblyLinearVelocity=Vector3.zero end
local function doRagdollTP() if tpCooldown then return end; tpCooldown=true; local side=detectEnemySide(); local steps=TP_STEPS[side]; tpMoveTo(TP_PRE_STEP); task.delay(0.10,function() tpMoveTo(steps[1]); task.delay(0.10,function() tpMoveTo(steps[2]); task.delay(1.2,function() tpCooldown=false end) end) end end
local function doMedusaTP() if tpCooldown then return end; tpCooldown=true; local side=detectEnemySide(); local steps=TP_OUTSIDE_STEPS[side]; tpMoveTo(TP_PRE_STEP); task.delay(0.10,function() tpMoveTo(steps[1]); task.delay(0.10,function() tpMoveTo(steps[2]); task.delay(1.2,function() tpCooldown=false; tpMedusaActive=false end) end) end end
local function hookTPCharacter(char)
    if tpStateConn then tpStateConn:Disconnect(); tpStateConn=nil end; if tpChildConn then tpChildConn:Disconnect(); tpChildConn=nil end; if tpChildRemConn then tpChildRemConn:Disconnect(); tpChildRemConn=nil end
    local hum=char:WaitForChild("Humanoid"); local spawnTime=tick(); local function isSpawnGrace() return (tick()-spawnTime)<2 end
    tpStateConn=hum.StateChanged:Connect(function(_,ns) if not RagdollTPEnabled then return end; if isSpawnGrace() then tpWasRagdolled=false; return end; if TP_RAGDOLL_STATES[ns] then if not tpWasRagdolled then tpWasRagdolled=true; task.defer(doRagdollTP) end else tpWasRagdolled=false end end)
    tpChildConn=char.ChildAdded:Connect(function(child) if not RagdollTPEnabled then return end; if isSpawnGrace() then return end; if isMedusaTPChild(child.Name) then if not tpMedusaActive then tpMedusaActive=true; task.defer(doMedusaTP) end; return end; if child.Name=="Ragdoll" or child.Name=="IsRagdoll" then if not tpWasRagdolled then tpWasRagdolled=true; task.defer(doRagdollTP) end end end)
    tpChildRemConn=char.ChildRemoved:Connect(function(child) if child.Name=="Ragdoll" or child.Name=="IsRagdoll" then tpWasRagdolled=false end; if isMedusaTPChild(child.Name) then tpMedusaActive=false end end)
end
local function startRagdollTP() tpWasRagdolled=false; tpCooldown=false; local char=player.Character; if char then hookTPCharacter(char) end end
local function stopRagdollTP() if tpStateConn then tpStateConn:Disconnect(); tpStateConn=nil end; if tpChildConn then tpChildConn:Disconnect(); tpChildConn=nil end; if tpChildRemConn then tpChildRemConn:Disconnect(); tpChildRemConn=nil end; tpWasRagdolled=false; tpMedusaActive=false end

local function startUnwalk() if not gChar then return end; local h2=gChar:FindFirstChildOfClass("Humanoid"); if not h2 then return end; local anim=h2:FindFirstChildOfClass("Animator"); if not anim then return end; for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end; if unwalkConn then unwalkConn:Disconnect() end; unwalkConn=RunService.Heartbeat:Connect(function() if not unwalkEnabled then unwalkConn:Disconnect(); unwalkConn=nil; return end; local c=player.Character; if not c then return end; local hh=c:FindFirstChildOfClass("Humanoid"); if not hh then return end; local an=hh:FindFirstChildOfClass("Animator"); if not an then return end; for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end end) end
local function stopUnwalk() if unwalkConn then unwalkConn:Disconnect(); unwalkConn=nil end end

local function createESP(plr) if plr==player or not plr.Character then return end; local c=plr.Character; local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end; local head=c:FindFirstChild("Head"); if not head then return end; if c:FindFirstChild("S7ESP") then return end; local box=Instance.new("BoxHandleAdornment"); box.Name="S7ESP"; box.Adornee=root; box.Size=Vector3.new(4,6,2); box.Color3=ACCENT; box.Transparency=0.45; box.ZIndex=10; box.AlwaysOnTop=true; box.Parent=c; local bb=Instance.new("BillboardGui"); bb.Name="S7ESP_Name"; bb.Adornee=head; bb.Size=UDim2.new(0,200,0,45); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=c; local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=plr.DisplayName; lbl.TextColor3=WHITE; lbl.Font=Enum.Font.GothamBold; lbl.TextScaled=true; lbl.TextStrokeTransparency=0.5; lbl.TextStrokeColor3=ACCENT; lbl.Parent=bb end
local function removeESP(plr) if not plr.Character then return end; local b=plr.Character:FindFirstChild("S7ESP"); local n=plr.Character:FindFirstChild("S7ESP_Name"); if b then b:Destroy() end; if n then n:Destroy() end end
local function enableESP() for _,plr in ipairs(Players:GetPlayers()) do if plr~=player then if plr.Character then pcall(function() createESP(plr) end) end; table.insert(espConns,plr.CharacterAdded:Connect(function() task.wait(0.1); if espEnabled then pcall(function() createESP(plr) end) end end)) end end; table.insert(espConns,Players.PlayerAdded:Connect(function(plr) if plr==player then return end; table.insert(espConns,plr.CharacterAdded:Connect(function() task.wait(0.1); if espEnabled then pcall(function() createESP(plr) end) end end)) end)) end
local function disableESP() for _,plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end; for _,c in ipairs(espConns) do if c and c.Connected then c:Disconnect() end end; espConns={} end

local function enableOptimizer() pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; Lighting.GlobalShadows=false; Lighting.Brightness=2; Lighting.FogEnd=9e9; Lighting.FogStart=9e9; for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=false end end end); pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do pcall(function() if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false; obj:Destroy() elseif obj:IsA("SelectionBox") then obj:Destroy() elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic; for _,ch in ipairs(obj:GetChildren()) do if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then ch:Destroy() end end elseif obj:IsA("Sky") then obj:Destroy() end end) end end); pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then xrayOrig[obj]=obj.LocalTransparencyModifier; obj.LocalTransparencyModifier=0.88 end end end) end
local function disableOptimizer() pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic; Lighting.GlobalShadows=true; Lighting.FogEnd=100000; Lighting.FogStart=0 end); for part,val in pairs(xrayOrig) do if part and part.Parent then part.LocalTransparencyModifier=val end end; xrayOrig={} end
local function applyFOV() if fovConn then fovConn:Disconnect() end; fovConn=RunService.RenderStepped:Connect(function() camera.FieldOfView=fovValue end) end
local function setupGalaxyForce() local h=getHRP(); if not h then return end; if galaxyVF then galaxyVF:Destroy() end; if galaxyAtt then galaxyAtt:Destroy() end; galaxyAtt=Instance.new("Attachment"); galaxyAtt.Parent=h; galaxyVF=Instance.new("VectorForce"); galaxyVF.Attachment0=galaxyAtt; galaxyVF.ApplyAtCenterOfMass=true; galaxyVF.RelativeTo=Enum.ActuatorRelativeTo.World; galaxyVF.Force=Vector3.zero; galaxyVF.Parent=h end
local function updateGalaxyForce() if not galaxyEnabled or not galaxyVF or not gChar then return end; local mass=0; for _,p in ipairs(gChar:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end; local tg=DEFAULT_GRAVITY*(GALAXY_GRAVITY/100); galaxyVF.Force=Vector3.new(0,mass*(DEFAULT_GRAVITY-tg)*0.95,0) end
local function startGalaxy() galaxyEnabled=true; hopsEnabled=true; pcall(setupGalaxyForce) end
local function stopGalaxy() galaxyEnabled=false; hopsEnabled=false; if galaxyVF then galaxyVF:Destroy(); galaxyVF=nil end; if galaxyAtt then galaxyAtt:Destroy(); galaxyAtt=nil end end
local function doHop() local h=getHRP(); local hh=getHum(); if not h or not hh then return end; if tick()-lastHop<HOP_COOLDOWN then return end; lastHop=tick(); if hh.FloorMaterial==Enum.Material.Air then h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,GALAXY_HOP,h.AssemblyLinearVelocity.Z) end end
local function startSpin() local c=player.Character; if not c then return end; local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end; if spinBAV then spinBAV:Destroy() end; spinBAV=Instance.new("BodyAngularVelocity"); spinBAV.Name="S7SpinBAV"; spinBAV.MaxTorque=Vector3.new(0,math.huge,0); spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0); spinBAV.Parent=root end
local function stopSpin() if spinBAV then spinBAV:Destroy(); spinBAV=nil end end

local function stopAutoPlayLeft() aplOn=false; if aplConn then aplConn:Disconnect(); aplConn=nil end; aplPhase=1; local hh=getHum(); if hh then hh:Move(Vector3.zero,false) end end
local function stopAutoPlayRight() aprOn=false; if aprConn then aprConn:Disconnect(); aprConn=nil end; aprPhase=1; local hh=getHum(); if hh then hh:Move(Vector3.zero,false) end end

local function startAutoPlayLeft()
    if aplConn then aplConn:Disconnect() end; aplPhase=1
    aplConn=RunService.Heartbeat:Connect(function()
        if not aplOn or not gHrp or not gHum then return end
        if aplPhase==1 then local d=Vector3.new(POS_L1.X-gHrp.Position.X,0,POS_L1.Z-gHrp.Position.Z); if d.Magnitude<1 then aplPhase=2; return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*NORMAL_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*NORMAL_SPEED)
        elseif aplPhase==2 then local d=Vector3.new(POS_L2.X-gHrp.Position.X,0,POS_L2.Z-gHrp.Position.Z); if d.Magnitude<1 then aplPhase=0; gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; task.delay(0.1,function() if aplOn then aplPhase=3 end end); return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*NORMAL_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*NORMAL_SPEED)
        elseif aplPhase==0 then return
        elseif aplPhase==3 then local d=Vector3.new(POS_L1.X-gHrp.Position.X,0,POS_L1.Z-gHrp.Position.Z); if d.Magnitude<1 then aplPhase=4; return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*SLOW_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*SLOW_SPEED)
        elseif aplPhase==4 then local d=Vector3.new(LFINAL.X-gHrp.Position.X,0,LFINAL.Z-gHrp.Position.Z); if d.Magnitude<1 then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; stopAutoPlayLeft(); return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*SLOW_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*SLOW_SPEED) end
    end)
end

local function startAutoPlayRight()
    if aprConn then aprConn:Disconnect() end; aprPhase=1
    aprConn=RunService.Heartbeat:Connect(function()
        if not aprOn or not gHrp or not gHum then return end
        if aprPhase==1 then local d=Vector3.new(POS_R1.X-gHrp.Position.X,0,POS_R1.Z-gHrp.Position.Z); if d.Magnitude<1 then aprPhase=2; return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*NORMAL_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*NORMAL_SPEED)
        elseif aprPhase==2 then local d=Vector3.new(POS_R2.X-gHrp.Position.X,0,POS_R2.Z-gHrp.Position.Z); if d.Magnitude<1 then aprPhase=0; gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; task.delay(0.1,function() if aprOn then aprPhase=3 end end); return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*NORMAL_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*NORMAL_SPEED)
        elseif aprPhase==0 then return
        elseif aprPhase==3 then local d=Vector3.new(POS_R1.X-gHrp.Position.X,0,POS_R1.Z-gHrp.Position.Z); if d.Magnitude<1 then aprPhase=4; return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*SLOW_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*SLOW_SPEED)
        elseif aprPhase==4 then local d=Vector3.new(RFINAL.X-gHrp.Position.X,0,RFINAL.Z-gHrp.Position.Z); if d.Magnitude<1 then gHum:Move(Vector3.zero,false); gHrp.AssemblyLinearVelocity=Vector3.zero; stopAutoPlayRight(); return end; local md=d.Unit; gHum:Move(md,false); gHrp.AssemblyLinearVelocity=Vector3.new(md.X*SLOW_SPEED,gHrp.AssemblyLinearVelocity.Y,md.Z*SLOW_SPEED) end
    end)
end

local function isMyBase(plotName) local plots=workspace:FindFirstChild("Plots"); if not plots then return false end; local plot=plots:FindFirstChild(plotName); if not plot then return false end; local sign=plot:FindFirstChild("PlotSign"); if not sign then return false end; local yb=sign:FindFirstChild("YourBase"); return yb and yb:IsA("BillboardGui") and yb.Enabled==true end
local function scanPlot(plot) if not plot or not plot:IsA("Model") then return end; if isMyBase(plot.Name) then return end; local podiums=plot:FindFirstChild("AnimalPodiums"); if not podiums then return end; for _,pod in ipairs(podiums:GetChildren()) do if pod:IsA("Model") and pod:FindFirstChild("Base") then table.insert(animalCache,{plot=plot.Name,slot=pod.Name,worldPosition=pod:GetPivot().Position,uid=plot.Name.."_"..pod.Name}) end end end
task.spawn(function() task.wait(2); local plots=workspace:WaitForChild("Plots",10); if not plots then return end; for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end; plots.ChildAdded:Connect(function(plot) if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end end); task.spawn(function() while task.wait(5) do animalCache={}; for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end end end) end)

local function startFloat() if floatConn then floatConn:Disconnect() end; local h=getHRP(); if h then h.CFrame=CFrame.new(h.Position.X,h.Position.Y+8,h.Position.Z); h.AssemblyLinearVelocity=Vector3.new(h.AssemblyLinearVelocity.X,0,h.AssemblyLinearVelocity.Z) end; floatConn=RunService.Heartbeat:Connect(function() if not floatEnabled then floatConn:Disconnect(); floatConn=nil; return end; local h2=getHRP(); if not h2 then return end; h2.AssemblyLinearVelocity=Vector3.new(h2.AssemblyLinearVelocity.X,0,h2.AssemblyLinearVelocity.Z) end) end
local function stopFloat() if floatConn then floatConn:Disconnect(); floatConn=nil end end
local function tpTo(pos) local c=player.Character; if not c then return end; c:PivotTo(CFrame.new(pos)); local h=c:FindFirstChild("HumanoidRootPart"); if h then h.AssemblyLinearVelocity=Vector3.new(0,0,0) end end
local function updateToggle(name,state) local t=toggleStates[name]; if not t then return end; t.state=state; t.track.BackgroundColor3=state and ACCENT or OFF_CLR; t.dot.Position=state and UDim2.new(1,-t.dotSz-3,0.5,-t.dotSz/2) or UDim2.new(0,3,0.5,-t.dotSz/2); if mobBtnRefs[name] then TweenService:Create(mobBtnRefs[name],TweenInfo.new(0.15),{BackgroundColor3=state and MOB_ON or MOB_OFF}):Play() end end

local function doTPRight() tpTo(TPA); task.wait(0.1); tpTo(TPRB); task.wait(0.1); tpTo(TPR1); if autoPlayAfterTP then if lastAutoPlayMode=="Left" then aplOn=true; startAutoPlayLeft(); updateToggle("Auto Play Left",true) else aprOn=true; startAutoPlayRight(); updateToggle("Auto Play Right",true) end end end
local function doDropBrainrot() local h=getHRP(); if h then h.CFrame=h.CFrame*CFrame.new(0,-50,0) end end
local function doTPDown() local r=getHRP(); if not r then return end; r.CFrame=r.CFrame*CFrame.new(0,-20,0) end

RunService.Heartbeat:Connect(function() if not medusaCounterEnabled then return end; local c=player.Character; if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end; if hum:GetState()==Enum.HumanoidStateType.Physics then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end end)
local function applyNoCamCollision() camera.CameraType=noCamCollisionEnabled and Enum.CameraType.Scriptable or Enum.CameraType.Custom end
local function applyShiny() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic; v.Reflectance=0.25 end end end
local function removeAccessories() if not removeAccessoriesEnabled then return end; local c=player.Character; if c then for _,v in ipairs(c:GetDescendants()) do if v:IsA("Accessory") then v:Destroy() end end end end
player.CharacterAdded:Connect(function() task.wait(0.5); removeAccessories() end)

local function scanForCountdown() local best=-1; for _,gui in ipairs(player.PlayerGui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Name~="S7_GUI" and gui.Name~="S7_OpenClose" and gui.Name~="S7_TauntButton" and gui.Name~="S7_FloatingTitle" then for _,desc in ipairs(gui:GetDescendants()) do if desc:IsA("TextLabel") and desc.Visible then local n=tonumber(desc.Text); if n and n==math.floor(n) and n>=1 and n<=15 then local abs=desc.AbsoluteSize; if abs.X>40 and abs.Y>30 and n>best then best=n end end end end end end; return best end
local function beginCountdownWatch() if cdWatching then return end; cdWatching=true; cdLastNum=-1; if cdConn then cdConn:Disconnect() end; cdConn=RunService.Heartbeat:Connect(function() if not autoPlayCDEnabled then cdWatching=false; cdConn:Disconnect(); cdConn=nil; return end; local n=scanForCountdown(); if n>=1 then cdLastNum=n elseif cdLastNum>=1 then cdLastNum=-1; cdWatching=false; cdConn:Disconnect(); cdConn=nil; task.wait(0.05); if lastAutoPlayMode=="Left" and not aplOn then aplOn=true; startAutoPlayLeft(); updateToggle("Auto Play Left",true) elseif lastAutoPlayMode=="Right" and not aprOn then aprOn=true; startAutoPlayRight(); updateToggle("Auto Play Right",true) end end end) end
RunService.Heartbeat:Connect(function() if autoPlayCDEnabled and not cdWatching and scanForCountdown()>=1 then beginCountdownWatch() end end)
RunService.Heartbeat:Connect(function() if not gChar or not gHum or not gHrp then return end; if spinBotEnabled and spinBAV then spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0) end; if galaxyEnabled then updateGalaxyForce() end; if galaxyEnabled and hopsEnabled and spaceHeld then doHop() end; if not batAimbotEnabled and not aplOn and not aprOn then local md=gHum.MoveDirection; if md.Magnitude>0.1 then local spd=slowDownEnabled and SLOW_SPEED or NORMAL_SPEED; gHrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,gHrp.AssemblyLinearVelocity.Y,md.Z*spd) end end end)
UserInputService.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.Space then spaceHeld=true end end)
UserInputService.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.Space then spaceHeld=false end end)

local function setupChar(c) gChar=c; gHum=c:WaitForChild("Humanoid",5); gHrp=c:WaitForChild("HumanoidRootPart",5); if not gHum or not gHrp then return end; task.wait(0.5); makeSpeedBB(); if galaxyEnabled then stopGalaxy(); startGalaxy() end; if antiRagdollEnabled then stopAntiRagdoll(); startAntiRagdoll() end; if spinBotEnabled then stopSpin(); startSpin() end; if espEnabled then enableESP() end; if unwalkEnabled then startUnwalk() end; if RagdollTPEnabled then hookTPCharacter(c) end; if floatEnabled then startFloat() else stopFloat() end; if noCamCollisionEnabled then applyNoCamCollision() end; if shinyGraphicsEnabled then applyShiny() end; if removeAccessoriesEnabled then removeAccessories() end end
if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(function(c) task.wait(0.5); setupChar(c) end)

-- FLOATING TITLE
local TitleGui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui")); TitleGui.Name="S7_FloatingTitle"; TitleGui.ResetOnSpawn=false; TitleGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local TitleFrame=Instance.new("Frame",TitleGui); TitleFrame.Size=UDim2.new(0,140,0,40); TitleFrame.Position=UDim2.new(0.5,-70,0.1,0); TitleFrame.BackgroundColor3=Color3.fromRGB(8,5,15); TitleFrame.BackgroundTransparency=0.2; TitleFrame.BorderSizePixel=0; Instance.new("UICorner",TitleFrame).CornerRadius=UDim.new(0,12)
local titleStroke=Instance.new("UIStroke",TitleFrame); titleStroke.Color=ACCENT; titleStroke.Thickness=2
local TitleLabel=Instance.new("TextLabel",TitleFrame); TitleLabel.Size=UDim2.new(1,0,1,0); TitleLabel.BackgroundTransparency=1; TitleLabel.Text="S7 Hub"; TitleLabel.Font=Enum.Font.GothamBlack; TitleLabel.TextSize=20; TitleLabel.TextColor3=WHITE; TitleLabel.TextStrokeColor3=ACCENT; TitleLabel.TextStrokeTransparency=0.3
local dragTitle=false; local dragStartPos,startTitlePos
TitleFrame.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragTitle=true; dragStartPos=input.Position; startTitlePos=TitleFrame.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragTitle and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local delta=input.Position-dragStartPos; TitleFrame.Position=UDim2.new(startTitlePos.X.Scale,startTitlePos.X.Offset+delta.X,startTitlePos.Y.Scale,startTitlePos.Y.Offset+delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragTitle=false end end)
task.spawn(function() while TitleFrame and TitleFrame.Parent do for i=0,20 do titleStroke.Thickness=2+i*0.05; task.wait(0.04) end; for i=0,20 do titleStroke.Thickness=3-i*0.05; task.wait(0.04) end end end)

-- TAUNT BUTTON
local TauntGuiBtn=Instance.new("ScreenGui",player:WaitForChild("PlayerGui")); TauntGuiBtn.Name="S7_TauntButton"; TauntGuiBtn.ResetOnSpawn=false; TauntGuiBtn.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local Tbtn=Instance.new("TextButton",TauntGuiBtn); Tbtn.Size=UDim2.new(0,52,0,52); Tbtn.Position=UDim2.new(0.85,0,0.5,-26); Tbtn.BackgroundColor3=Color3.fromRGB(10,5,20); Tbtn.Text="T"; Tbtn.TextSize=20; Tbtn.Font=Enum.Font.GothamBold; Tbtn.TextColor3=WHITE; Tbtn.BorderSizePixel=0; Tbtn.Active=true; Instance.new("UICorner",Tbtn).CornerRadius=UDim.new(1,0)
local TStroke=Instance.new("UIStroke",Tbtn); TStroke.Thickness=2.5; TStroke.Color=ACCENT; TStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
local draggingTaunt,dragStartTaunt,startPosTaunt=false,nil,nil
Tbtn.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then draggingTaunt=true; dragStartTaunt=input.Position; startPosTaunt=Tbtn.Position; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then draggingTaunt=false end end) end end)
UserInputService.InputChanged:Connect(function(input) if draggingTaunt and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then local delta=input.Position-dragStartTaunt; Tbtn.Position=UDim2.new(startPosTaunt.X.Scale,startPosTaunt.X.Offset+delta.X,startPosTaunt.Y.Scale,startPosTaunt.Y.Offset+delta.Y) end end)
Tbtn.MouseButton1Click:Connect(function() sendTauntMessage() end)

-- MAIN GUI
local ScreenGui=Instance.new("ScreenGui"); ScreenGui.Name="S7_GUI"; ScreenGui.ResetOnSpawn=false; ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ScreenGui.IgnoreGuiInset=false; ScreenGui.Parent=player:WaitForChild("PlayerGui")
local MainFrame=Instance.new("Frame"); MainFrame.Name="MainFrame"; MainFrame.Size=UDim2.new(0,360,0,650); MainFrame.Position=UDim2.new(0.5,-180,0.5,-325); MainFrame.BackgroundColor3=BG; MainFrame.BorderSizePixel=0; MainFrame.Active=true; MainFrame.Visible=false; MainFrame.Parent=ScreenGui; Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,16)
local MainStroke=Instance.new("UIStroke",MainFrame); MainStroke.Thickness=2; MainStroke.Color=ACCENT; MainStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
task.spawn(function() while MainFrame and MainFrame.Parent do for i=0,20 do MainStroke.Thickness=2+i*0.05; task.wait(0.04) end; for i=0,20 do MainStroke.Thickness=3-i*0.05; task.wait(0.04) end end end)
local TitleBar=Instance.new("Frame",MainFrame); TitleBar.Size=UDim2.new(1,0,0,52); TitleBar.BackgroundColor3=Color3.fromRGB(8,5,15); TitleBar.BorderSizePixel=0; Instance.new("UICorner",TitleBar).CornerRadius=UDim.new(0,16)
local TitleFix=Instance.new("Frame",TitleBar); TitleFix.Size=UDim2.new(1,0,0,16); TitleFix.Position=UDim2.new(0,0,1,-16); TitleFix.BackgroundColor3=Color3.fromRGB(8,5,15); TitleFix.BorderSizePixel=0
local TitleLbl=Instance.new("TextLabel",TitleBar); TitleLbl.Size=UDim2.new(1,0,1,0); TitleLbl.BackgroundTransparency=1; TitleLbl.Text="S7 Hub"; TitleLbl.Font=Enum.Font.GothamBlack; TitleLbl.TextSize=22; TitleLbl.TextColor3=WHITE; TitleLbl.TextStrokeColor3=ACCENT; TitleLbl.TextStrokeTransparency=0.5
do
    local guiScale=1.0; local BASE_W,BASE_H=360,650
    local plusBtn=Instance.new("TextButton",TitleBar); plusBtn.Size=UDim2.new(0,26,0,26); plusBtn.Position=UDim2.new(1,-58,0.5,-13); plusBtn.BackgroundColor3=Color3.fromRGB(25,15,40); plusBtn.Text="+"; plusBtn.Font=Enum.Font.GothamBlack; plusBtn.TextSize=16; plusBtn.TextColor3=ACCENT; plusBtn.BorderSizePixel=0; Instance.new("UICorner",plusBtn).CornerRadius=UDim.new(0,6)
    local minusBtn=Instance.new("TextButton",TitleBar); minusBtn.Size=UDim2.new(0,26,0,26); minusBtn.Position=UDim2.new(1,-28,0.5,-13); minusBtn.BackgroundColor3=Color3.fromRGB(25,15,40); minusBtn.Text="-"; minusBtn.Font=Enum.Font.GothamBlack; minusBtn.TextSize=16; minusBtn.TextColor3=ACCENT; minusBtn.BorderSizePixel=0; Instance.new("UICorner",minusBtn).CornerRadius=UDim.new(0,6)
    plusBtn.MouseButton1Click:Connect(function() guiScale=math.min(guiScale+0.1,2.0); local w=math.floor(BASE_W*guiScale); local h=math.floor(BASE_H*guiScale); MainFrame.Size=UDim2.new(0,w,0,h); MainFrame.Position=UDim2.new(0.5,-w/2,0.5,-h/2) end)
    minusBtn.MouseButton1Click:Connect(function() guiScale=math.max(guiScale-0.1,0.4); local w=math.floor(BASE_W*guiScale); local h=math.floor(BASE_H*guiScale); MainFrame.Size=UDim2.new(0,w,0,h); MainFrame.Position=UDim2.new(0.5,-w/2,0.5,-h/2) end)
end
local DiscordLbl=Instance.new("TextLabel",MainFrame); DiscordLbl.Size=UDim2.new(1,0,0,18); DiscordLbl.Position=UDim2.new(0,0,1,-22); DiscordLbl.BackgroundTransparency=1; DiscordLbl.Text="https://discord.gg/5FaWfEvmJ"; DiscordLbl.Font=Enum.Font.GothamBold; DiscordLbl.TextSize=11; DiscordLbl.TextColor3=ACCENT
local TabContainer=Instance.new("Frame",MainFrame); TabContainer.Size=UDim2.new(1,-20,0,34); TabContainer.Position=UDim2.new(0,10,0,60); TabContainer.BackgroundTransparency=1
local function makeTab(text,xScale,xPos) local t=Instance.new("TextButton",TabContainer); t.Size=UDim2.new(xScale,-4,1,0); t.Position=UDim2.new(xPos,2,0,0); t.BackgroundColor3=OFF_CLR; t.Text=text; t.Font=Enum.Font.GothamBold; t.TextSize=11; t.TextColor3=Color3.fromRGB(160,150,180); t.BorderSizePixel=0; Instance.new("UICorner",t).CornerRadius=UDim.new(0,8); return t end
local FeatTab=makeTab("FEATURES",0.2,0); local MovTab=makeTab("MOVEMENT",0.2,0.2); local VisTab=makeTab("VISUALS",0.2,0.4); local SetTab=makeTab("SETTINGS",0.2,0.6); local BindTab=makeTab("BINDS",0.2,0.8)
local function makeScrollFrame() local sf=Instance.new("ScrollingFrame",MainFrame); sf.Size=UDim2.new(1,-20,1,-148); sf.Position=UDim2.new(0,10,0,103); sf.BackgroundTransparency=1; sf.BorderSizePixel=0; sf.ScrollBarThickness=4; sf.ScrollBarImageColor3=ACCENT; sf.CanvasSize=UDim2.new(0,0,0,0); sf.AutomaticCanvasSize=Enum.AutomaticSize.Y; sf.Visible=false; local ll=Instance.new("UIListLayout",sf); ll.Padding=UDim.new(0,6); ll.SortOrder=Enum.SortOrder.LayoutOrder; return sf end
local FeatFrame=makeScrollFrame(); local MovFrame=makeScrollFrame(); local VisFrame=makeScrollFrame(); local SetFrame=makeScrollFrame(); local BindFrame=makeScrollFrame(); FeatFrame.Visible=true
local frames={FeatFrame,MovFrame,VisFrame,SetFrame,BindFrame}; local tabs={FeatTab,MovTab,VisTab,SetTab,BindTab}
local function selectTab(idx) for i,sf in ipairs(frames) do sf.Visible=(i==idx) end; for i,tb in ipairs(tabs) do tb.BackgroundColor3=(i==idx) and ACCENT or OFF_CLR; tb.TextColor3=(i==idx) and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,150,180) end end
for i,tb in ipairs(tabs) do tb.MouseButton1Click:Connect(function() selectTab(i) end) end; selectTab(1)

local function makeToggle(parent,name,order,callback,defaultOn)
    local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=CARD; row.BorderSizePixel=0; row.LayoutOrder=order; Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-70,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=WHITE; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pW,pH,dSz=46,24,18; local track=Instance.new("Frame",row); track.Size=UDim2.new(0,pW,0,pH); track.Position=UDim2.new(1,-(pW+12),0.5,-pH/2)
    local initState=(SavedToggleStates[name]~=nil) and SavedToggleStates[name] or (defaultOn or false)
    track.BackgroundColor3=initState and ACCENT or OFF_CLR; track.BorderSizePixel=0; Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",track); dot.Size=UDim2.new(0,dSz,0,dSz); dot.Position=initState and UDim2.new(1,-dSz-3,0.5,-dSz/2) or UDim2.new(0,3,0.5,-dSz/2); dot.BackgroundColor3=Color3.fromRGB(255,255,255); dot.BorderSizePixel=0; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    toggleStates[name]={track=track,dot=dot,state=initState,dotSz=dSz}
    if initState and callback then task.defer(function() callback(true) end) end
    local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Click:Connect(function() local ns=not toggleStates[name].state; toggleStates[name].state=ns; track.BackgroundColor3=ns and ACCENT or OFF_CLR; dot.Position=ns and UDim2.new(1,-dSz-3,0.5,-dSz/2) or UDim2.new(0,3,0.5,-dSz/2); if callback then callback(ns) end; task.defer(saveConfig) end)
    return row
end

local function makeSection(parent,text,order) local lbl=Instance.new("TextLabel",parent); lbl.Size=UDim2.new(1,0,0,26); lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=ACCENT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.LayoutOrder=order end
local function makeNumInput(parent,labelText,defaultVal,order,onChanged) local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=CARD; row.BorderSizePixel=0; row.LayoutOrder=order; Instance.new("UICorner",row).CornerRadius=UDim.new(0,10); local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-90,1,0); lbl.Position=UDim2.new(0,14,0,0); lbl.BackgroundTransparency=1; lbl.Text=labelText; lbl.TextColor3=WHITE; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; local box=Instance.new("TextBox",row); box.Size=UDim2.new(0,68,0,28); box.Position=UDim2.new(1,-78,0.5,-14); box.BackgroundColor3=Color3.fromRGB(15,12,28); box.Text=tostring(defaultVal); box.TextColor3=ACCENT; box.Font=Enum.Font.GothamBold; box.TextSize=13; box.TextXAlignment=Enum.TextXAlignment.Center; box.BorderSizePixel=0; box.ClearTextOnFocus=false; Instance.new("UICorner",box).CornerRadius=UDim.new(0,6); box.FocusLost:Connect(function() local n=tonumber(box.Text); if n then if onChanged then onChanged(n) end; task.defer(saveConfig) else box.Text=tostring(defaultVal) end end); return row,box end
local function makeActionBtn(parent,text,order,fn) local b=Instance.new("TextButton",parent); b.Size=UDim2.new(1,0,0,40); b.BackgroundColor3=Color3.fromRGB(20,15,35); b.Text=text; b.Font=Enum.Font.GothamBlack; b.TextSize=13; b.TextColor3=ACCENT; b.BorderSizePixel=0; b.LayoutOrder=order; Instance.new("UICorner",b).CornerRadius=UDim.new(0,10); Instance.new("UIStroke",b).Color=ACCENT; b.MouseButton1Click:Connect(function() task.spawn(fn) end); return b end

-- FEATURES TAB
makeSection(FeatFrame,"  COMBAT",1)
makeToggle(FeatFrame,"Bat Aimbot + Hit Circle",2,function(v) batAimbotEnabled=v; if v then if aplOn then stopAutoPlayLeft(); updateToggle("Auto Play Left",false) end; if aprOn then stopAutoPlayRight(); updateToggle("Auto Play Right",false) end; enableHitCircle() else disableHitCircle() end end)
makeToggle(FeatFrame,"Auto Steal",3,function(v) if v then enableAutoSteal() else disableAutoSteal() end end)
makeToggle(FeatFrame,"Anti Ragdoll",4,function(v) antiRagdollEnabled=v; if v then startAntiRagdoll() else stopAntiRagdoll() end end)
makeToggle(FeatFrame,"Ragdoll TP",5,function(v) RagdollTPEnabled=v; if v then startRagdollTP() else stopRagdollTP() end end)
makeToggle(FeatFrame,"Medusa Counter",6,function(v) medusaCounterEnabled=v end)
makeToggle(FeatFrame,"Unwalk",7,function(v) unwalkEnabled=v; if v then startUnwalk() else stopUnwalk() end end)
makeSection(FeatFrame,"  SPEED",8)
makeToggle(FeatFrame,"Slow Down",9,function(v) slowDownEnabled=v end)
makeToggle(FeatFrame,"Float",10,function(v) floatEnabled=v; if v then startFloat() else stopFloat() end end)
makeSection(FeatFrame,"  DROP / TP",11)
makeActionBtn(FeatFrame,"DO DROP",12,doDrop)
makeActionBtn(FeatFrame,"TP DOWN",13,doTPDown)
makeActionBtn(FeatFrame,"TP RIGHT",14,doTPRight)
makeActionBtn(FeatFrame,"DROP BRAINROT",15,doDropBrainrot)
makeSection(FeatFrame,"  TAUNT SPAM",16)
makeToggle(FeatFrame,"Taunt Spam",17,function(v) if v then startTauntSpam() else stopTauntSpam() end end)

-- MOVEMENT TAB
makeSection(MovFrame,"  AUTO PLAY (LOOP)",1)
makeToggle(MovFrame,"Auto Play Left",2,function(v) if v then if batAimbotEnabled then disableHitCircle(); updateToggle("Bat Aimbot + Hit Circle",false) end; if aprOn then stopAutoPlayRight(); updateToggle("Auto Play Right",false) end; aplOn=true; startAutoPlayLeft(); lastAutoPlayMode="Left" else stopAutoPlayLeft() end end)
makeToggle(MovFrame,"Auto Play Right",3,function(v) if v then if batAimbotEnabled then disableHitCircle(); updateToggle("Bat Aimbot + Hit Circle",false) end; if aplOn then stopAutoPlayLeft(); updateToggle("Auto Play Left",false) end; aprOn=true; startAutoPlayRight(); lastAutoPlayMode="Right" else stopAutoPlayRight() end end)
makeToggle(MovFrame,"Auto Play After Countdown",4,function(v) autoPlayCDEnabled=v end)
makeToggle(MovFrame,"Auto Play After TP",5,function(v) autoPlayAfterTP=v end)
makeSection(MovFrame,"  GALAXY",6)
makeToggle(MovFrame,"Galaxy Mode",7,function(v) galaxyEnabled=v; if v then startGalaxy() else stopGalaxy() end end)
makeToggle(MovFrame,"Spin Bot",8,function(v) spinBotEnabled=v; if v then startSpin() else stopSpin() end end)
makeSection(MovFrame,"  OTHER",9)
makeToggle(MovFrame,"No Cam Collision",10,function(v) noCamCollisionEnabled=v; applyNoCamCollision() end)
makeToggle(MovFrame,"Infinite Jump",11,function(v) infJumpEnabled=v end)

-- VISUALS TAB
makeSection(VisFrame,"  PLAYER",1)
makeToggle(VisFrame,"Player ESP",2,function(v) espEnabled=v; if v then enableESP() else disableESP() end end,true)
makeSection(VisFrame,"  PERFORMANCE",3)
makeToggle(VisFrame,"Optimizer + XRay",4,function(v) optimizerEnabled=v; if v then enableOptimizer() else disableOptimizer() end end)
makeToggle(VisFrame,"Shiny Graphics",5,function(v) shinyGraphicsEnabled=v; if v then applyShiny() end end)
makeToggle(VisFrame,"Remove Accessories",6,function(v) removeAccessoriesEnabled=v; removeAccessories() end)

-- SETTINGS TAB
makeSection(SetFrame,"  SPEED CUSTOMIZER",1)
do
    local speedRow=Instance.new("Frame",SetFrame); speedRow.Size=UDim2.new(1,0,0,50); speedRow.BackgroundColor3=CARD; speedRow.BorderSizePixel=0; speedRow.LayoutOrder=2; Instance.new("UICorner",speedRow).CornerRadius=UDim.new(0,10)
    local speedBtn=Instance.new("TextButton",speedRow); speedBtn.Size=UDim2.new(0.85,-20,0,36); speedBtn.Position=UDim2.new(0.075,0,0.5,-18); speedBtn.BackgroundColor3=Color3.fromRGB(15,10,28); speedBtn.Text="Speed Customizer"; speedBtn.TextColor3=ACCENT; speedBtn.Font=Enum.Font.GothamBold; speedBtn.TextSize=13; speedBtn.BorderSizePixel=0; Instance.new("UICorner",speedBtn).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",speedBtn).Color=ACCENT
    local open=false; speedBtn.MouseButton1Click:Connect(function() if open then if S7Speed.SpeedUI and S7Speed.SpeedUI.ScreenGui then if S7Speed.Enabled then disableS7Speed() end; S7Speed.SpeedUI.ScreenGui:Destroy(); S7Speed.SpeedUI=nil end; open=false else createS7SpeedUI(); open=true end end)
end
makeSection(SetFrame,"  STEAL",3); makeNumInput(SetFrame,"Steal Radius",STEAL_RADIUS,4,function(v) STEAL_RADIUS=math.clamp(v,5,200) end); makeNumInput(SetFrame,"Steal Duration",STEAL_DURATION,5,function(v) STEAL_DURATION=math.max(0.05,v) end)
makeSection(SetFrame,"  GALAXY",6); makeNumInput(SetFrame,"Gravity %",GALAXY_GRAVITY,7,function(v) GALAXY_GRAVITY=v end); makeNumInput(SetFrame,"Hop Power",GALAXY_HOP,8,function(v) GALAXY_HOP=v end); makeNumInput(SetFrame,"Spin Speed",SPIN_SPEED,9,function(v) SPIN_SPEED=v; if spinBAV then spinBAV.AngularVelocity=Vector3.new(0,SPIN_SPEED,0) end end)
makeSection(SetFrame,"  CAMERA / BAT",10); makeNumInput(SetFrame,"FOV",fovValue,11,function(v) fovValue=v; applyFOV() end); makeNumInput(SetFrame,"Aimbot Speed",AIMBOT_SPEED,12,function(v) AIMBOT_SPEED=v end); makeNumInput(SetFrame,"Engage Range",BAT_ENGAGE_RANGE,13,function(v) BAT_ENGAGE_RANGE=v end)
makeSection(SetFrame,"  CONFIG",14)
do local sb=Instance.new("TextButton",SetFrame); sb.Size=UDim2.new(1,0,0,40); sb.BackgroundColor3=Color3.fromRGB(15,35,15); sb.Text="SAVE CONFIG"; sb.Font=Enum.Font.GothamBlack; sb.TextSize=13; sb.TextColor3=WHITE; sb.BorderSizePixel=0; sb.LayoutOrder=15; Instance.new("UICorner",sb).CornerRadius=UDim.new(0,10); sb.MouseButton1Click:Connect(function() saveConfig(); sb.Text="SAVED!"; task.delay(1.5,function() sb.Text="SAVE CONFIG" end) end) end

-- BINDS TAB
makeSection(BindFrame,"  KEYBINDS (click to rebind)",1)
do local bindHint=Instance.new("TextLabel",BindFrame); bindHint.Size=UDim2.new(1,0,0,36); bindHint.BackgroundColor3=Color3.fromRGB(15,8,28); bindHint.BackgroundTransparency=0; bindHint.BorderSizePixel=0; bindHint.Text="Click a key button then press\nany key to rebind. CTRL = clear."; bindHint.TextColor3=Color3.fromRGB(180,160,220); bindHint.Font=Enum.Font.Gotham; bindHint.TextSize=11; bindHint.TextWrapped=true; bindHint.LayoutOrder=2; Instance.new("UICorner",bindHint).CornerRadius=UDim.new(0,8) end
local bindList={{"Auto Left","AutoLeft"},{"Auto Right","AutoRight"},{"Auto Steal","AutoSteal"},{"Bat Aimbot","BatAimbot"},{"Anti Ragdoll","AntiRagdoll"},{"Unwalk","Unwalk"},{"Slow Down","SlowDown"},{"Ragdoll TP","RagdollTP"},{"Drop","Drop"},{"Taunt","Taunt"},{"TP Down","TPDown"}}
for idx,entry in ipairs(bindList) do
    local dn,kn=entry[1],entry[2]; local row=Instance.new("Frame",BindFrame); row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=CARD; row.BorderSizePixel=0; row.LayoutOrder=idx+2; Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    local nl=Instance.new("TextLabel",row); nl.Size=UDim2.new(1,-110,1,0); nl.Position=UDim2.new(0,14,0,0); nl.BackgroundTransparency=1; nl.Text=dn; nl.TextColor3=WHITE; nl.Font=Enum.Font.GothamBold; nl.TextSize=13; nl.TextXAlignment=Enum.TextXAlignment.Left
    local kb=Instance.new("TextButton",row); kb.Size=UDim2.new(0,90,0,30); kb.Position=UDim2.new(1,-98,0.5,-15); kb.BackgroundColor3=Color3.fromRGB(25,15,40); kb.Text=Keybinds[kn] and tostring(Keybinds[kn]):gsub("Enum.KeyCode.","") or "NONE"; kb.Font=Enum.Font.GothamBold; kb.TextSize=11; kb.TextColor3=ACCENT; kb.BorderSizePixel=0; Instance.new("UICorner",kb).CornerRadius=UDim.new(0,8); KeybindButtons[kn]=kb
    kb.MouseButton1Click:Connect(function() if changingKeybind then return end; changingKeybind=kn; kb.Text="Press key..."; kb.TextColor3=Color3.fromRGB(255,200,50); local conn; conn=UserInputService.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Keyboard then if input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.RightControl then Keybinds[kn]=nil; kb.Text="NONE" else Keybinds[kn]=input.KeyCode; kb.Text=tostring(input.KeyCode):gsub("Enum.KeyCode.","") end; kb.TextColor3=ACCENT; changingKeybind=nil; conn:Disconnect(); task.defer(saveConfig) end end) end)
end

-- PROGRESS BAR (versteckt aber funktioniert noch intern)
do
    local PBC=Instance.new("Frame",ScreenGui); PBC.Size=UDim2.new(0,380,0,58); PBC.Position=UDim2.new(0.5,-190,1,-130); PBC.BackgroundColor3=Color3.fromRGB(8,5,15); PBC.BackgroundTransparency=0.08; PBC.BorderSizePixel=0; PBC.Visible=false
    Instance.new("UICorner",PBC).CornerRadius=UDim.new(0,14)
    ProgressLabel=Instance.new("TextLabel",PBC); ProgressLabel.Size=UDim2.new(0.45,0,0.5,0); ProgressLabel.Position=UDim2.new(0,12,0,4); ProgressLabel.BackgroundTransparency=1; ProgressLabel.Text="READY"; ProgressLabel.TextColor3=WHITE; ProgressLabel.Font=Enum.Font.GothamBold; ProgressLabel.TextSize=13; ProgressLabel.TextXAlignment=Enum.TextXAlignment.Left; ProgressLabel.ZIndex=3
    ProgressPctLabel=Instance.new("TextLabel",PBC); ProgressPctLabel.Size=UDim2.new(0.3,0,0.5,0); ProgressPctLabel.Position=UDim2.new(0.45,0,0,4); ProgressPctLabel.BackgroundTransparency=1; ProgressPctLabel.Text=""; ProgressPctLabel.TextColor3=ACCENT; ProgressPctLabel.Font=Enum.Font.GothamBlack; ProgressPctLabel.TextSize=15; ProgressPctLabel.TextXAlignment=Enum.TextXAlignment.Center; ProgressPctLabel.ZIndex=3
    local pt=Instance.new("Frame",PBC); pt.Size=UDim2.new(0.92,0,0,14); pt.Position=UDim2.new(0.04,0,1,-22); pt.BackgroundColor3=Color3.fromRGB(20,15,35); pt.BorderSizePixel=0; pt.ZIndex=2; Instance.new("UICorner",pt).CornerRadius=UDim.new(1,0)
    ProgressBarFill=Instance.new("Frame",pt); ProgressBarFill.Size=UDim2.new(0,0,1,0); ProgressBarFill.BackgroundColor3=ACCENT; ProgressBarFill.BorderSizePixel=0; ProgressBarFill.ZIndex=3; Instance.new("UICorner",ProgressBarFill).CornerRadius=UDim.new(1,0)
end

-- MOBILE BUTTONS: Links: AUTO L, PLAY L, DROP, LOCK | Rechts: AUTO R, PLAY R, TP DOWN, CARRY SPD
do
    local gap=68; local startY=-170; local col1=-120; local col2=-56
    local function makeMob(label,xOffset,yOffset,toggleName,onAct) local btn=Instance.new("TextButton",ScreenGui); btn.Size=UDim2.new(0,58,0,58); btn.Position=UDim2.new(1,xOffset,0.5,yOffset); btn.BackgroundColor3=MOB_OFF; btn.BackgroundTransparency=0.1; btn.Text=label; btn.TextColor3=WHITE; btn.Font=Enum.Font.GothamBold; btn.TextSize=9; btn.TextWrapped=true; btn.BorderSizePixel=0; btn.ZIndex=20; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10); local s=Instance.new("UIStroke",btn); s.Color=ACCENT; s.Thickness=1.5; s.Transparency=0.3; table.insert(mobileButtons,btn); if toggleName then mobBtnRefs[toggleName]=btn end; btn.MouseButton1Click:Connect(onAct); return btn end

    -- Links
    makeMob("AUTO\nL",col1,startY+gap*0,"Auto Play Left",function() local ns=not aplOn; if ns then if batAimbotEnabled then disableHitCircle(); updateToggle("Bat Aimbot + Hit Circle",false) end; if aprOn then stopAutoPlayRight(); updateToggle("Auto Play Right",false) end; aplOn=true; startAutoPlayLeft() else stopAutoPlayLeft() end; updateToggle("Auto Play Left",ns) end)
    makeMob("PLAY\nL",col1,startY+gap*1,nil,function() if not aplOn then aplOn=true; startAutoPlayLeft(); updateToggle("Auto Play Left",true) end end)
    makeMob("DROP",col1,startY+gap*2,nil,function() task.spawn(doDrop) end)
    makeMob("LOCK",col1,startY+gap*3,"Anti Ragdoll",function() local ns=not(toggleStates["Anti Ragdoll"] and toggleStates["Anti Ragdoll"].state); antiRagdollEnabled=ns; if ns then startAntiRagdoll() else stopAntiRagdoll() end; updateToggle("Anti Ragdoll",ns) end)

    -- Rechts
    makeMob("AUTO\nR",col2,startY+gap*0,"Auto Play Right",function() local ns=not aprOn; if ns then if batAimbotEnabled then disableHitCircle(); updateToggle("Bat Aimbot + Hit Circle",false) end; if aplOn then stopAutoPlayLeft(); updateToggle("Auto Play Left",false) end; aprOn=true; startAutoPlayRight() else stopAutoPlayRight() end; updateToggle("Auto Play Right",ns) end)
    makeMob("PLAY\nR",col2,startY+gap*1,nil,function() if not aprOn then aprOn=true; startAutoPlayRight(); updateToggle("Auto Play Right",true) end end)
    makeMob("TP\nDOWN",col2,startY+gap*2,nil,function() task.spawn(doTPDown) end)
    makeMob("CARRY\nSPD",col2,startY+gap*3,"Slow Down",function() local ns=not(toggleStates["Slow Down"] and toggleStates["Slow Down"].state); slowDownEnabled=ns; updateToggle("Slow Down",ns) end)
end

-- OPEN/CLOSE BUTTON
do
    local OCGui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui")); OCGui.Name="S7_OpenClose"; OCGui.ResetOnSpawn=false; OCGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    local OBtn=Instance.new("TextButton",OCGui); OBtn.Size=UDim2.new(0,52,0,52); OBtn.Position=UDim2.new(0,10,0.5,-26); OBtn.BackgroundColor3=Color3.fromRGB(8,5,15); OBtn.Text="S7"; OBtn.TextSize=16; OBtn.Font=Enum.Font.GothamBlack; OBtn.TextColor3=WHITE; OBtn.BorderSizePixel=0; OBtn.Active=true; Instance.new("UICorner",OBtn).CornerRadius=UDim.new(0,14)
    local OS=Instance.new("UIStroke",OBtn); OS.Thickness=2; OS.Color=ACCENT; OS.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    task.spawn(function() while OBtn and OBtn.Parent do for i=0,20 do OS.Thickness=2+i*0.05; task.wait(0.04) end; for i=0,20 do OS.Thickness=3-i*0.05; task.wait(0.04) end end end)
    local dragging,dragStart,startPos=false,nil,nil
    OBtn.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=input.Position; startPos=OBtn.Position; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then local d=input.Position-dragStart; OBtn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
    OBtn.MouseButton1Click:Connect(function() MainFrame.Visible=not MainFrame.Visible; TweenService:Create(OS,TweenInfo.new(0.15),{Color=MainFrame.Visible and WHITE or ACCENT}):Play() end)
end

do local dragging,dragStart,startPos=false,nil,nil; TitleBar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=input.Position; startPos=MainFrame.Position end end); UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then local d=input.Position-dragStart; MainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end); UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end) end

do local FPSLbl=Instance.new("TextLabel",TitleBar); FPSLbl.Size=UDim2.new(0,70,0,16); FPSLbl.Position=UDim2.new(0,10,0,5); FPSLbl.BackgroundTransparency=1; FPSLbl.Text="0 FPS"; FPSLbl.Font=Enum.Font.GothamBold; FPSLbl.TextSize=11; FPSLbl.TextColor3=ACCENT; FPSLbl.TextXAlignment=Enum.TextXAlignment.Left; local PingLbl=Instance.new("TextLabel",TitleBar); PingLbl.Size=UDim2.new(0,70,0,16); PingLbl.Position=UDim2.new(1,-80,0,5); PingLbl.BackgroundTransparency=1; PingLbl.Text="0ms"; PingLbl.Font=Enum.Font.GothamBold; PingLbl.TextSize=11; PingLbl.TextColor3=ACCENT; PingLbl.TextXAlignment=Enum.TextXAlignment.Right; local fc,lft=0,tick(); RunService.RenderStepped:Connect(function() fc=fc+1; local ct=tick(); if ct-lft>=1 then FPSLbl.Text=fc.." FPS"; fc=0; lft=ct end; pcall(function() PingLbl.Text=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()).."ms" end) end) end

-- WAYPOINT OFFSET PANEL
function openWPPanel(side)
    if wpOffsetPanel then wpOffsetPanel:Destroy(); wpOffsetPanel=nil end
    local wps=(side=="Right") and WPRight or WPLeft
    wpOffsetPanel=Instance.new("Frame"); wpOffsetPanel.Size=UDim2.new(0,218,0,108); wpOffsetPanel.Position=UDim2.new(0,270,0,200); wpOffsetPanel.BackgroundColor3=BG; wpOffsetPanel.BorderSizePixel=0; wpOffsetPanel.ZIndex=50; wpOffsetPanel.Active=true; wpOffsetPanel.Parent=ScreenGui
    Instance.new("UICorner",wpOffsetPanel).CornerRadius=UDim.new(0,8)
    local s=Instance.new("UIStroke",wpOffsetPanel); s.Color=ACCENT; s.Thickness=1.5; s.Transparency=0.35
    local _pd,_pds,_psp=false,nil,nil
    wpOffsetPanel.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _pd=true; _pds=i.Position; _psp=wpOffsetPanel.Position end end)
    wpOffsetPanel.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _pd=false end end)
    UserInputService.InputChanged:Connect(function(i) if _pd and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-_pds; wpOffsetPanel.Position=UDim2.new(_psp.X.Scale,_psp.X.Offset+d.X,_psp.Y.Scale,_psp.Y.Offset+d.Y) end end)
    local hdr=Instance.new("Frame"); hdr.Size=UDim2.new(1,0,0,26); hdr.BackgroundColor3=BG; hdr.BorderSizePixel=0; hdr.ZIndex=51; hdr.Parent=wpOffsetPanel
    local ttl=Instance.new("TextLabel"); ttl.Size=UDim2.new(1,-80,1,0); ttl.Position=UDim2.new(0,10,0,0); ttl.BackgroundTransparency=1; ttl.Text="OFFSET "..side; ttl.TextColor3=ACCENT; ttl.TextSize=11; ttl.Font=Enum.Font.GothamBold; ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.ZIndex=52; ttl.Parent=hdr
    local rst=Instance.new("TextButton"); rst.Size=UDim2.new(0,32,0,18); rst.Position=UDim2.new(1,-58,0.5,-9); rst.BackgroundColor3=Color3.fromRGB(25,15,40); rst.BorderSizePixel=0; rst.Text="RST"; rst.TextColor3=ACCENT; rst.TextSize=9; rst.Font=Enum.Font.Gotham; rst.ZIndex=53; rst.Parent=hdr; Instance.new("UICorner",rst).CornerRadius=UDim.new(0,3); Instance.new("UIStroke",rst).Color=ACCENT
    rst.MouseButton1Click:Connect(function() for _,wp in ipairs(wps) do wp.offset=Vector3.new(0,0,0) end; wpOffsetPanel:Destroy(); wpOffsetPanel=nil; openWPPanel(side); POS_L1=getL1(); POS_L2=getLEND(); LFINAL=getLFINAL(); POS_R1=getR1(); POS_R2=getREND(); RFINAL=getRFINAL(); saveConfig() end)
    local cls=Instance.new("TextButton"); cls.Size=UDim2.new(0,20,0,18); cls.Position=UDim2.new(1,-24,0.5,-9); cls.BackgroundColor3=Color3.fromRGB(25,15,40); cls.BorderSizePixel=0; cls.Text="X"; cls.TextColor3=ACCENT; cls.TextSize=10; cls.Font=Enum.Font.GothamBold; cls.ZIndex=53; cls.Parent=hdr
    cls.MouseButton1Click:Connect(function() wpOffsetPanel:Destroy(); wpOffsetPanel=nil end)
    local colXs={8,60,112,164}
    for i,wp in ipairs(wps) do
        local cx=colXs[i]
        if i>1 then local div=Instance.new("Frame"); div.Size=UDim2.new(0,1,0,74); div.Position=UDim2.new(0,cx-4,0,30); div.BackgroundColor3=Color3.fromRGB(40,30,60); div.BorderSizePixel=0; div.ZIndex=51; div.Parent=wpOffsetPanel end
        local wlbl=Instance.new("TextLabel"); wlbl.Size=UDim2.new(0,46,0,14); wlbl.Position=UDim2.new(0,cx,0,30); wlbl.BackgroundTransparency=1; wlbl.Text=wp.label; wlbl.TextColor3=Color3.fromRGB(150,140,180); wlbl.TextSize=10; wlbl.Font=Enum.Font.GothamBold; wlbl.TextXAlignment=Enum.TextXAlignment.Center; wlbl.ZIndex=51; wlbl.Parent=wpOffsetPanel
        local cbar=Instance.new("Frame"); cbar.Size=UDim2.new(0,42,0,2); cbar.Position=UDim2.new(0,cx,0,44); cbar.BackgroundColor3=wp.color; cbar.BorderSizePixel=0; cbar.ZIndex=51; cbar.Parent=wpOffsetPanel; Instance.new("UICorner",cbar).CornerRadius=UDim.new(0,1)
        local function makeSpinner(axis,rowY)
            local axCol=(axis=="X") and Color3.new(1,0.431373,0.431373) or Color3.new(0.6,0.4,1)
            local xl=Instance.new("TextLabel"); xl.Size=UDim2.new(0,46,0,10); xl.Position=UDim2.new(0,cx,0,rowY-10); xl.BackgroundTransparency=1; xl.Text=axis; xl.TextColor3=axCol; xl.TextSize=9; xl.TextXAlignment=Enum.TextXAlignment.Center; xl.ZIndex=51; xl.Parent=wpOffsetPanel
            local minus=Instance.new("TextButton"); minus.Size=UDim2.new(0,14,0,16); minus.Position=UDim2.new(0,cx,0,rowY); minus.BackgroundColor3=Color3.fromRGB(20,15,35); minus.BorderSizePixel=0; minus.Text="-"; minus.TextColor3=axCol; minus.TextSize=10; minus.Font=Enum.Font.GothamBold; minus.ZIndex=52; minus.Parent=wpOffsetPanel
            local box=Instance.new("TextBox"); box.Size=UDim2.new(0,18,0,16); box.Position=UDim2.new(0,cx+14,0,rowY); box.BackgroundColor3=Color3.fromRGB(10,8,20); box.BorderSizePixel=0; box.Text="0"; box.TextColor3=WHITE; box.Font=Enum.Font.GothamBold; box.TextSize=8; box.ClearTextOnFocus=false; box.ZIndex=52; box.Parent=wpOffsetPanel; Instance.new("UIStroke",box).Color=axCol
            local plus=Instance.new("TextButton"); plus.Size=UDim2.new(0,14,0,16); plus.Position=UDim2.new(0,cx+32,0,rowY); plus.BackgroundColor3=Color3.fromRGB(20,15,35); plus.BorderSizePixel=0; plus.Text="+"; plus.TextColor3=axCol; plus.TextSize=10; plus.Font=Enum.Font.GothamBold; plus.ZIndex=52; plus.Parent=wpOffsetPanel
            local function applyVal(val) local cur=wp.offset; if axis=="X" then wp.offset=Vector3.new(val,cur.Y,cur.Z) else wp.offset=Vector3.new(cur.X,cur.Y,val) end; POS_L1=getL1(); POS_L2=getLEND(); LFINAL=getLFINAL(); POS_R1=getR1(); POS_R2=getREND(); RFINAL=getRFINAL(); saveConfig() end
            local function step(d) local next=(tonumber(box.Text) or 0)+d; box.Text=tostring(next); applyVal(next) end
            minus.MouseButton1Click:Connect(function() step(-1) end); plus.MouseButton1Click:Connect(function() step(1) end)
            box.FocusLost:Connect(function() local raw=box.Text:match("^%-?%d+") or "0"; local val=tonumber(raw) or 0; box.Text=tostring(val); applyVal(val) end)
            local initVal=(axis=="X") and wp.offset.X or wp.offset.Y; box.Text=tostring(initVal)
        end
        makeSpinner("X",58); makeSpinner("Y",86)
    end
end

task.wait(1)
for _,frame in ipairs(MovFrame:GetChildren()) do
    if frame:IsA("Frame") and frame.LayoutOrder==2 then
        local gearBtn=Instance.new("TextButton",frame); gearBtn.Size=UDim2.new(0,24,0,24); gearBtn.Position=UDim2.new(1,-32,0.5,-12); gearBtn.BackgroundColor3=Color3.fromRGB(25,15,40); gearBtn.Text="G"; gearBtn.TextColor3=ACCENT; gearBtn.TextSize=14; gearBtn.Font=Enum.Font.Gotham; gearBtn.BorderSizePixel=0; gearBtn.ZIndex=205; Instance.new("UICorner",gearBtn).CornerRadius=UDim.new(0,6); gearBtn.MouseButton1Click:Connect(function() openWPPanel("Left") end)
    elseif frame:IsA("Frame") and frame.LayoutOrder==3 then
        local gearBtn=Instance.new("TextButton",frame); gearBtn.Size=UDim2.new(0,24,0,24); gearBtn.Position=UDim2.new(1,-32,0.5,-12); gearBtn.BackgroundColor3=Color3.fromRGB(25,15,40); gearBtn.Text="G"; gearBtn.TextColor3=ACCENT; gearBtn.TextSize=14; gearBtn.Font=Enum.Font.Gotham; gearBtn.BorderSizePixel=0; gearBtn.ZIndex=205; Instance.new("UICorner",gearBtn).CornerRadius=UDim.new(0,6); gearBtn.MouseButton1Click:Connect(function() openWPPanel("Right") end)
    end
end

-- PC KEYBIND HANDLER
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end; if changingKeybind then return end; if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    if Keybinds.AutoLeft and input.KeyCode==Keybinds.AutoLeft then local ns=not aplOn; if ns then if batAimbotEnabled then disableHitCircle(); updateToggle("Bat Aimbot + Hit Circle",false) end; if aprOn then stopAutoPlayRight(); updateToggle("Auto Play Right",false) end; aplOn=true; startAutoPlayLeft() else stopAutoPlayLeft() end; updateToggle("Auto Play Left",ns)
    elseif Keybinds.AutoRight and input.KeyCode==Keybinds.AutoRight then local ns=not aprOn; if ns then if batAimbotEnabled then disableHitCircle(); updateToggle("Bat Aimbot + Hit Circle",false) end; if aplOn then stopAutoPlayLeft(); updateToggle("Auto Play Left",false) end; aprOn=true; startAutoPlayRight() else stopAutoPlayRight() end; updateToggle("Auto Play Right",ns)
    elseif Keybinds.AutoSteal and input.KeyCode==Keybinds.AutoSteal then local ns=not(toggleStates["Auto Steal"] and toggleStates["Auto Steal"].state); if ns then enableAutoSteal() else disableAutoSteal() end; updateToggle("Auto Steal",ns)
    elseif Keybinds.BatAimbot and input.KeyCode==Keybinds.BatAimbot then local ns=not(toggleStates["Bat Aimbot + Hit Circle"] and toggleStates["Bat Aimbot + Hit Circle"].state); if ns then if aplOn then stopAutoPlayLeft(); updateToggle("Auto Play Left",false) end; if aprOn then stopAutoPlayRight(); updateToggle("Auto Play Right",false) end; enableHitCircle() else disableHitCircle() end; updateToggle("Bat Aimbot + Hit Circle",ns)
    elseif Keybinds.AntiRagdoll and input.KeyCode==Keybinds.AntiRagdoll then local ns=not(toggleStates["Anti Ragdoll"] and toggleStates["Anti Ragdoll"].state); antiRagdollEnabled=ns; if ns then startAntiRagdoll() else stopAntiRagdoll() end; updateToggle("Anti Ragdoll",ns)
    elseif Keybinds.Unwalk and input.KeyCode==Keybinds.Unwalk then local ns=not(toggleStates["Unwalk"] and toggleStates["Unwalk"].state); unwalkEnabled=ns; if ns then startUnwalk() else stopUnwalk() end; updateToggle("Unwalk",ns)
    elseif Keybinds.SlowDown and input.KeyCode==Keybinds.SlowDown then local ns=not(toggleStates["Slow Down"] and toggleStates["Slow Down"].state); slowDownEnabled=ns; updateToggle("Slow Down",ns)
    elseif Keybinds.RagdollTP and input.KeyCode==Keybinds.RagdollTP then local ns=not(toggleStates["Ragdoll TP"] and toggleStates["Ragdoll TP"].state); RagdollTPEnabled=ns; if ns then startRagdollTP() else stopRagdollTP() end; updateToggle("Ragdoll TP",ns)
    elseif Keybinds.Drop and input.KeyCode==Keybinds.Drop then task.spawn(doDrop)
    elseif Keybinds.Taunt and input.KeyCode==Keybinds.Taunt then sendTauntMessage()
    elseif Keybinds.TPDown and input.KeyCode==Keybinds.TPDown then task.spawn(doTPDown)
    end
end)

if espEnabled then enableESP() end
applyFOV()
print("S7 Hub loaded - Black & Purple - discord.gg/5FaWfEvmJ")
