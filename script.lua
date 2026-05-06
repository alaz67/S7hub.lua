local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local LP = Players.LocalPlayer

local State = {
	normalSpeed = 60, carrySpeed = 30,
	speedToggled = false, autoBatToggled = false,
	hittingCooldown = false, infJumpEnabled = false,
	antiRagdollEnabled = false, fpsBoostEnabled = false,
	guiVisible = true,
	isStealing = false, stealStartTime = nil, lastStealTick = 0,
	brainrotReturnLeftEnabled = false, brainrotReturnRightEnabled = false,
	brainrotReturnCooldown = false, lastKnownHealth = 100,
	autoLeftEnabled = false, autoRightEnabled = false,
	autoLeftPhase = 1, autoRightPhase = 1,
	medusaLastUsed = 0, medusaDebounce = false, medusaCounterEnabled = false,
	dropBrainrotActive = false, floatEnabled = false, floatHeight = 9.5,
	autoPlayEnabled = false, autoPlayWaypoint = 1,
	autoPlayWaiting = false, autoPlayWaitingCountdown = false,
	_tpInProgress = false, detectedBaseSide = nil,
	lastMoveDir = Vector3.new(0,0,0),
	animEnabled = false, unwalkEnabled = false,
}

local Keys = {
	autoBat = Enum.KeyCode.E, speed = Enum.KeyCode.Q,
	guiHide = Enum.KeyCode.LeftControl,
	brainrotReturnLeft = Enum.KeyCode.F, brainrotReturnRight = Enum.KeyCode.G,
	autoLeft = Enum.KeyCode.L, autoRight = Enum.KeyCode.R,
	dropBrainrot = Enum.KeyCode.H, float = Enum.KeyCode.J,
	autoPlay = Enum.KeyCode.P,
}

local Steal = {
	AutoStealEnabled = false, StealRadius = 20, StealDuration = 0.25,
	Data = {}, plotCache = {}, plotCacheTime = {},
	cachedPrompts = {}, promptCacheTime = 0,
}

local MOVE_KEYS = {
	[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,
	[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
	[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,
	[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true,
}

local PLOT_CACHE_DURATION = 2
local PROMPT_CACHE_REFRESH = 0.15
local STEAL_COOLDOWN = 0.1
local AUTO_START_DELAY = 0.7
local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED = 150
local MEDUSA_COOLDOWN = 25

local POS = {
	L1 = Vector3.new(-476.48,-6.28,92.73), L2 = Vector3.new(-483.12,-4.95,94.80),
	R1 = Vector3.new(-476.16,-6.52,25.62), R2 = Vector3.new(-483.04,-5.09,23.14),
}

local RIGHT_STEP_1 = Vector3.new(-474.9, -7.0, 24.1)
local RIGHT_STEP_2 = Vector3.new(-482.64, -5.20, 21.06)
local RIGHT_STEP_3 = Vector3.new(-466.78, -7.10, 40.83)
local LEFT_STEP_1  = Vector3.new(-474.9, -7.0, 94.9)
local LEFT_STEP_2  = Vector3.new(-481.7, -5.1, 97.7)
local LEFT_STEP_3  = Vector3.new(-465.7, -7.0, 83.2)

local AP_RIGHT_WP = {
	Vector3.new(-473.04,-6.99,29.71), Vector3.new(-483.57,-5.10,18.74),
	Vector3.new(-475.00,-6.99,26.43), Vector3.new(-474.67,-6.94,105.48),
}
local AP_LEFT_WP = {
	Vector3.new(-472.49,-7.00,90.62), Vector3.new(-484.62,-5.10,100.37),
	Vector3.new(-475.08,-7.00,93.29), Vector3.new(-474.22,-6.96,16.18),
}

local Conns = {
	autoSteal = nil, antiRag = nil, autoPlay = nil,
	autoLeft = nil, autoRight = nil, float = nil,
	anchor = {}, progress = nil,
}

local h, hrp, speedLbl
local setAutoPlay, setAutoLeft, setAutoRight, setFloat
local setInstaGrab, setAutoBat, setInfJump, setAntiRag, setFps, setMedusaCounter
local setBrainrotReturnLeft, setBrainrotReturnRight, setAnimToggle, setUnwalkToggle
local setupMedusaCounter, stopMedusaCounter, startAntiRagdoll, stopAntiRagdoll
local applyFPSBoost, startAutoSteal, stopAutoSteal
local startAutoLeft, stopAutoLeft, startAutoRight, stopAutoRight
local startFloat, stopFloat, stopAutoPlay, saveConfig
local brainrotReturnLeftKeyBtn, brainrotReturnRightKeyBtn

local C_BG      = Color3.fromRGB(8,8,12)
local C_PANEL   = Color3.fromRGB(14,16,22)
local C_ROW     = Color3.fromRGB(20,22,28)
local C_ROW_HOV = Color3.fromRGB(28,30,38)
local C_BORDER  = Color3.fromRGB(35,45,65)
local C_BORDER2 = Color3.fromRGB(50,60,85)
local C_HEADER  = Color3.fromRGB(10,12,18)
local C_ACCENT  = Color3.fromRGB(100,150,255)
local C_ACCENT2 = Color3.fromRGB(80,120,220)
local C_DIM     = Color3.fromRGB(70,75,90)
local C_WHITE   = Color3.fromRGB(255,255,255)
local C_ON_BG   = Color3.fromRGB(60,90,180)
local C_OFF_BG  = Color3.fromRGB(30,34,44)
local C_KEY_BG  = Color3.fromRGB(22,26,34)

local LOGO_ID = "rbxassetid://120042443836261"
task.spawn(function() pcall(function() ContentProvider:PreloadAsync({LOGO_ID}) end) end)

local Anims = {
	idle1    = "rbxassetid://133806214992291",
	idle2    = "rbxassetid://94970088341563",
	walk     = "rbxassetid://707897309",
	run      = "rbxassetid://707861613",
	jump     = "rbxassetid://116936326516985",
	fall     = "rbxassetid://116936326516985",
	climb    = "rbxassetid://116936326516985",
	swim     = "rbxassetid://116936326516985",
	swimidle = "rbxassetid://116936326516985",
}
task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync({
			Anims.idle1, Anims.idle2, Anims.walk, Anims.run,
			Anims.jump, Anims.fall, Anims.climb, Anims.swim, Anims.swimidle,
		})
	end)
end)

local animHeartbeatConn = nil
local savedAnimate = nil
local originalAnims = nil

local function isPackAnim(id)
	if not id then return false end
	for _, v in pairs(Anims) do
		if v == id then return true end
	end
	return false
end

local function saveOriginalAnims(char)
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	local function g(obj) return obj and obj.AnimationId or nil end
	local ids = {
		idle1    = g(animate.idle     and animate.idle.Animation1),
		idle2    = g(animate.idle     and animate.idle.Animation2),
		walk     = g(animate.walk     and animate.walk.WalkAnim),
		run      = g(animate.run      and animate.run.RunAnim),
		jump     = g(animate.jump     and animate.jump.JumpAnim),
		fall     = g(animate.fall     and animate.fall.FallAnim),
		climb    = g(animate.climb    and animate.climb.ClimbAnim),
		swim     = g(animate.swim     and animate.swim.Swim),
		swimidle = g(animate.swimidle and animate.swimidle.SwimIdle),
	}
	if not isPackAnim(ids.walk) then
		originalAnims = ids
	end
end

local function applyAnimPack(char)
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	local function s(obj, id) if obj then obj.AnimationId = id end end
	s(animate.idle     and animate.idle.Animation1,     Anims.idle1)
	s(animate.idle     and animate.idle.Animation2,     Anims.idle2)
	s(animate.walk     and animate.walk.WalkAnim,       Anims.walk)
	s(animate.run      and animate.run.RunAnim,         Anims.run)
	s(animate.jump     and animate.jump.JumpAnim,       Anims.jump)
	s(animate.fall     and animate.fall.FallAnim,       Anims.fall)
	s(animate.climb    and animate.climb.ClimbAnim,     Anims.climb)
	s(animate.swim     and animate.swim.Swim,           Anims.swim)
	s(animate.swimidle and animate.swimidle.SwimIdle,   Anims.swimidle)
end

local function restoreOriginalAnims(char)
	if not originalAnims then return end
	local animate = char:FindFirstChild("Animate")
	if not animate then return end
	local function s(obj, id) if obj and id then obj.AnimationId = id end end
	s(animate.idle     and animate.idle.Animation1,     originalAnims.idle1)
	s(animate.idle     and animate.idle.Animation2,     originalAnims.idle2)
	s(animate.walk     and animate.walk.WalkAnim,       originalAnims.walk)
	s(animate.run      and animate.run.RunAnim,         originalAnims.run)
	s(animate.jump     and animate.jump.JumpAnim,       originalAnims.jump)
	s(animate.fall     and animate.fall.FallAnim,       originalAnims.fall)
	s(animate.climb    and animate.climb.ClimbAnim,     originalAnims.climb)
	s(animate.swim     and animate.swim.Swim,           originalAnims.swim)
	s(animate.swimidle and animate.swimidle.SwimIdle,   originalAnims.swimidle)
	local hum2 = char:FindFirstChildOfClass("Humanoid")
	if hum2 then
		for _, track in ipairs(hum2:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
		hum2:ChangeState(Enum.HumanoidStateType.Running)
	end
end

local function startAnimToggle()
	if animHeartbeatConn then animHeartbeatConn:Disconnect(); animHeartbeatConn = nil end
	local char = LP.Character
	if char then
		saveOriginalAnims(char)
		applyAnimPack(char)
		local hum2 = char:FindFirstChildOfClass("Humanoid")
		if hum2 then
			for _, track in ipairs(hum2:GetPlayingAnimationTracks()) do
				track:Stop(0)
			end
			hum2:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
	animHeartbeatConn = RunService.Heartbeat:Connect(function()
		if not State.animEnabled then return end
		local c = LP.Character
		if c then applyAnimPack(c) end
	end)
end

local function stopAnimToggle()
	if animHeartbeatConn then animHeartbeatConn:Disconnect(); animHeartbeatConn = nil end
	local char = LP.Character
	if char then restoreOriginalAnims(char) end
end

local function startUnwalk()
	if State.unwalkEnabled then return end
	State.unwalkEnabled = true
	local c = LP.Character
	if not c then return end
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum then
		for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
			t:Stop()
		end
	end
	local anim = c:FindFirstChild("Animate")
	if anim then
		savedAnimate = anim:Clone()
		anim:Destroy()
	end
end

local function stopUnwalk()
	if not State.unwalkEnabled then return end
	State.unwalkEnabled = false
	local c = LP.Character
	if c and savedAnimate then
		savedAnimate.Parent = c
		savedAnimate.Disabled = false
		savedAnimate = nil
	end
	task.spawn(function()
		task.wait(0.15)
		local char = LP.Character
		if not char then return end
		if State.animEnabled then
			saveOriginalAnims(char)
			applyAnimPack(char)
		else
			restoreOriginalAnims(char)
		end
	end)
end

local Camera = workspace.CurrentCamera

for _, name in pairs({"S7_GUI"}) do
	local old = game:GetService("CoreGui"):FindFirstChild(name)
	if old then old:Destroy() end
end

local closeBtnRef = nil
local gui = Instance.new("ScreenGui")
gui.Name="S7_GUI"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
gui.IgnoreGuiInset=true; gui.Parent=LP:WaitForChild("PlayerGui")

local shadow = Instance.new("Frame",gui)
shadow.Size=UDim2.new(0,320,0,560); shadow.Position=UDim2.new(0,10,0,10)
shadow.BackgroundColor3=Color3.fromRGB(0,0,0); shadow.BackgroundTransparency=0.5; shadow.BorderSizePixel=0
Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,12)

local main = Instance.new("Frame",gui)
main.Name="Main"; main.Size=UDim2.new(0,320,0,560); main.Position=UDim2.new(0,10,0,10)
main.BackgroundColor3=C_BG; main.BorderSizePixel=0; main.Active=true; main.ClipsDescendants=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
local mainStroke = Instance.new("UIStroke",main); mainStroke.Color=C_BORDER2; mainStroke.Thickness=1

local header = Instance.new("Frame",main)
header.Size=UDim2.new(1,0,0,50); header.BackgroundColor3=C_HEADER; header.BorderSizePixel=0; header.ZIndex=5
local headerDiv = Instance.new("Frame",header)
headerDiv.Size=UDim2.new(1,0,0,1); headerDiv.Position=UDim2.new(0,0,1,-1)
headerDiv.BackgroundColor3=C_BORDER; headerDiv.BorderSizePixel=0; headerDiv.ZIndex=6

local titleLbl = Instance.new("TextLabel",header)
titleLbl.Size=UDim2.new(1,0,1,0); titleLbl.BackgroundTransparency=1; titleLbl.Text="S7"
titleLbl.TextColor3=C_ACCENT; titleLbl.Font=Enum.Font.GothamBlack; titleLbl.TextSize=22
titleLbl.TextXAlignment=Enum.TextXAlignment.Center; titleLbl.ZIndex=6

local subLbl = Instance.new("TextLabel",header)
subLbl.Size=UDim2.new(1,0,0,14); subLbl.Position=UDim2.new(0,0,1,-18)
subLbl.BackgroundTransparency=1; subLbl.Text="vyse.cc"
subLbl.TextColor3=C_DIM; subLbl.Font=Enum.Font.Gotham; subLbl.TextSize=10
subLbl.TextXAlignment=Enum.TextXAlignment.Center; subLbl.ZIndex=6

local closeBtn = Instance.new("TextButton",gui)
closeBtn.Size=UDim2.new(0,28,0,28)
closeBtn.Position=UDim2.new(0,10+320-36,0,10+12)
closeBtn.BackgroundColor3=Color3.fromRGB(30,35,45); closeBtn.BorderSizePixel=0
closeBtn.Text="-"; closeBtn.TextColor3=C_ACCENT
closeBtn.Font=Enum.Font.GothamBlack; closeBtn.TextSize=20; closeBtn.ZIndex=50
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
local closeBtnStroke = Instance.new("UIStroke",closeBtn)
closeBtnStroke.Color=C_BORDER2; closeBtnStroke.Thickness=1
closeBtnRef = closeBtn

local miniBtn = Instance.new("TextButton",gui)
miniBtn.Name="S7_Mini"; miniBtn.Size=UDim2.new(0,70,0,32); miniBtn.Position=UDim2.new(0,10,0,10)
miniBtn.BackgroundColor3=C_PANEL; miniBtn.BorderSizePixel=0; miniBtn.Text="S7"; miniBtn.TextColor3=C_ACCENT
miniBtn.Font=Enum.Font.GothamBlack; miniBtn.TextSize=16; miniBtn.ZIndex=20; miniBtn.Visible=false
Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",miniBtn).Color=C_BORDER2

local scroll = Instance.new("ScrollingFrame",main)
scroll.Size=UDim2.new(1,0,1,-50); scroll.Position=UDim2.new(0,0,0,50)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=3
scroll.ScrollBarImageColor3=C_BORDER2; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.ZIndex=2
local listLayout = Instance.new("UIListLayout",scroll)
listLayout.SortOrder=Enum.SortOrder.LayoutOrder; listLayout.Padding=UDim.new(0,2)
local pad = Instance.new("UIPadding",scroll)
pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,10)

local lo = 0
local function LO() lo+=1; return lo end

local function makeGap(px) local f=Instance.new("Frame",scroll); f.Size=UDim2.new(1,0,0,px or 4); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=LO() end
local function makeDivider() local f=Instance.new("Frame",scroll); f.Size=UDim2.new(1,0,0,1); f.BackgroundColor3=C_BORDER; f.BorderSizePixel=0; f.LayoutOrder=LO() end
local function makeSectionLabel(text) local row=Instance.new("Frame",scroll); row.Size=UDim2.new(1,0,0,24); row.BackgroundTransparency=1; row.BorderSizePixel=0; row.LayoutOrder=LO(); local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=text:upper(); lbl.TextColor3=C_ACCENT2; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left end

local function makeInputRow(label, default, onChange)
	local row=Instance.new("Frame",scroll); row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=C_ROW; row.BorderSizePixel=0; row.LayoutOrder=LO()
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",row).Color=C_BORDER
	local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C_ACCENT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
	local box=Instance.new("TextBox",row); box.Size=UDim2.new(0,80,0,26); box.Position=UDim2.new(1,-86,0.5,-13); box.BackgroundColor3=C_KEY_BG; box.BorderSizePixel=0; box.Text=tostring(default); box.TextColor3=C_ACCENT; box.Font=Enum.Font.GothamBold; box.TextSize=12; box.ClearTextOnFocus=false
	Instance.new("UICorner",box).CornerRadius=UDim.new(0,5); local bs=Instance.new("UIStroke",box); bs.Color=C_BORDER2; bs.Thickness=1
	box.FocusLost:Connect(function() if onChange then local n=tonumber(box.Text); if n then onChange(box.Text) else box.Text=tostring(default) end end end)
	return box
end

local function makeStatusRow(label, valTxt)
	local row=Instance.new("Frame",scroll); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C_ROW; row.BorderSizePixel=0; row.LayoutOrder=LO()
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",row).Color=C_BORDER
	local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C_ACCENT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
	local val=Instance.new("TextLabel",row); val.Size=UDim2.new(0.45,-10,1,0); val.Position=UDim2.new(0.52,0,0,0); val.BackgroundTransparency=1; val.Text=valTxt; val.TextColor3=C_ACCENT2; val.Font=Enum.Font.GothamBlack; val.TextSize=12; val.TextXAlignment=Enum.TextXAlignment.Right
	return val
end

local function makeActionBtn(label, onClick)
	local btn=Instance.new("TextButton",scroll); btn.Size=UDim2.new(1,0,0,34); btn.BackgroundColor3=C_PANEL; btn.BorderSizePixel=0; btn.LayoutOrder=LO(); btn.Text=label; btn.TextColor3=C_WHITE; btn.Font=Enum.Font.GothamBold; btn.TextSize=13
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",btn).Color=C_BORDER2
	btn.MouseButton1Click:Connect(function() if onClick then pcall(onClick) end end)
	return btn
end

local function makeKeybindRow(label, currentKey, onChanged)
	local row=Instance.new("Frame",scroll); row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=C_ROW; row.BorderSizePixel=0; row.LayoutOrder=LO()
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",row).Color=C_BORDER
	local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C_ACCENT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
	local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(0,80,0,26); btn.Position=UDim2.new(1,-86,0.5,-13); btn.BackgroundColor3=C_KEY_BG; btn.BorderSizePixel=0; btn.Text=currentKey.Name; btn.TextColor3=C_ACCENT; btn.Font=Enum.Font.GothamBold; btn.TextSize=11
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5); local bs=Instance.new("UIStroke",btn); bs.Color=C_BORDER2; bs.Thickness=1
	local listening=false; local listenConn
	local function stopListen(key) listening=false; if listenConn then listenConn:Disconnect(); listenConn=nil end; if key then btn.Text=key.Name; if onChanged then onChanged(key) end end end
	btn.MouseButton1Click:Connect(function()
		if listening then stopListen(nil); return end; listening=true; btn.Text="..."
		listenConn=UIS.InputBegan:Connect(function(inp)
			if not listening then return end; if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
			if inp.KeyCode==Enum.KeyCode.Escape then stopListen(nil); return end; stopListen(inp.KeyCode)
		end)
	end)
	return btn
end

local function makeToggleRow(label, defaultKey, defaultOn, onToggle, onKeyChanged)
	local row=Instance.new("Frame",scroll); row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=C_ROW; row.BorderSizePixel=0; row.LayoutOrder=LO()
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",row).Color=C_BORDER
	local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(0,130,1,0); lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C_ACCENT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
	local keyBtn=nil
	if defaultKey then
		keyBtn=Instance.new("TextButton",row); keyBtn.Size=UDim2.new(0,65,0,24); keyBtn.Position=UDim2.new(1,-130,0.5,-12); keyBtn.BackgroundColor3=C_KEY_BG; keyBtn.BorderSizePixel=0; keyBtn.Text=defaultKey.Name; keyBtn.TextColor3=C_ACCENT2; keyBtn.Font=Enum.Font.GothamBold; keyBtn.TextSize=10; keyBtn.ZIndex=5
		Instance.new("UICorner",keyBtn).CornerRadius=UDim.new(0,4); local ks=Instance.new("UIStroke",keyBtn); ks.Color=C_BORDER2; ks.Thickness=1
		local kListening=false; local kConn
		local function kStop(key) kListening=false; if kConn then kConn:Disconnect(); kConn=nil end; if key then keyBtn.Text=key.Name; if onKeyChanged then onKeyChanged(key) end end end
		keyBtn.MouseButton1Click:Connect(function()
			if kListening then kStop(nil); return end; kListening=true; keyBtn.Text="..."
			kConn=UIS.InputBegan:Connect(function(inp)
				if not kListening then return end; if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
				if inp.KeyCode==Enum.KeyCode.Escape then kStop(nil); return end; kStop(inp.KeyCode)
			end)
		end)
	end
	local pillBg=Instance.new("Frame",row); pillBg.Size=UDim2.new(0,42,0,20); pillBg.Position=UDim2.new(1,-48,0.5,-10); pillBg.BackgroundColor3=defaultOn and C_ON_BG or C_OFF_BG; pillBg.BorderSizePixel=0; pillBg.ZIndex=5
	Instance.new("UICorner",pillBg).CornerRadius=UDim.new(1,0); local dot=Instance.new("Frame",pillBg); dot.Size=UDim2.new(0,14,0,14); dot.Position=defaultOn and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7); dot.BackgroundColor3=defaultOn and C_WHITE or C_DIM; dot.BorderSizePixel=0; dot.ZIndex=6; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
	local isOn=defaultOn or false
	local function setV(on) isOn=on; pillBg.BackgroundColor3=on and C_ON_BG or C_OFF_BG; dot.Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7); dot.BackgroundColor3=on and C_WHITE or C_DIM end
	local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=3
	clk.MouseButton1Click:Connect(function() isOn=not isOn; setV(isOn); if onToggle then pcall(onToggle,isOn) end end)
	return setV, keyBtn
end

local modeValLbl, normalBox, carryBox, saveBtn
local autoBatKeyBtn, speedKeyBtn
local autoLeftKeyBtn, autoRightKeyBtn
local guiHideKeyBtn, floatHeightBox
local dropBrainrotKeyBtn

makeSectionLabel("Speed")
normalBox = makeInputRow("Normal Speed", State.normalSpeed, function(v) local n=tonumber(v); if n and n>0 and n<=500 then State.normalSpeed=n end end)
carryBox  = makeInputRow("Carry Speed",  State.carrySpeed,  function(v) local n=tonumber(v); if n and n>0 and n<=500 then State.carrySpeed=n  end end)
speedKeyBtn = makeKeybindRow("Speed Toggle", Keys.speed, function(k) Keys.speed=k end)
modeValLbl = makeStatusRow("Mode","Normal")
makeGap(4); makeDivider(); makeGap(4)

makeSectionLabel("Combat")
setAutoBat, autoBatKeyBtn = makeToggleRow("Auto Bat", Keys.autoBat, false, function(on) State.autoBatToggled=on end, function(k) Keys.autoBat=k end)
makeGap(4); makeDivider(); makeGap(4)

makeSectionLabel("Mechanics")
setInstaGrab = makeToggleRow("Insta Grab", nil, false, function(on) Steal.AutoStealEnabled=on; if on then startAutoSteal() else stopAutoSteal() end end)
setInfJump = makeToggleRow("Infinite Jump", nil, false, function(on) State.infJumpEnabled=on end)
setAntiRag = makeToggleRow("Anti Ragdoll", nil, false, function(on) State.antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
setFps = makeToggleRow("FPS Boost", nil, false, function(on) State.fpsBoostEnabled=on; if on then pcall(applyFPSBoost) end end)
setMedusaCounter = makeToggleRow("Medusa Counter", nil, false, function(on) State.medusaCounterEnabled=on; if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end)
setAnimToggle = makeToggleRow("Tryhard Anim", nil, false, function(on) State.animEnabled=on; if on then startAnimToggle() else stopAnimToggle() end end)
setUnwalkToggle = makeToggleRow("Unwalk", nil, false, function(on) if on then startUnwalk() else stopUnwalk() end end)
makeGap(4); makeDivider(); makeGap(4)

makeSectionLabel("Teleport / Movement")
dropBrainrotKeyBtn = makeKeybindRow("Drop Brainrot", Keys.dropBrainrot, function(k) Keys.dropBrainrot=k end)

setBrainrotReturnLeft, brainrotReturnLeftKeyBtn = makeToggleRow("Brainrot Return L", Keys.brainrotReturnLeft, false,
	function(on)
		State.brainrotReturnLeftEnabled = on
		if on and setBrainrotReturnRight then setBrainrotReturnRight(false) end
	end, function(k) Keys.brainrotReturnLeft = k end)

setBrainrotReturnRight, brainrotReturnRightKeyBtn = makeToggleRow("Brainrot Return R", Keys.brainrotReturnRight, false,
	function(on)
		State.brainrotReturnRightEnabled = on
		if on and setBrainrotReturnLeft then setBrainrotReturnLeft(false) end
	end, function(k) Keys.brainrotReturnRight = k end)

setAutoPlay, _ = makeToggleRow("Auto Play", Keys.autoPlay, false, function(on) State.autoPlayEnabled=on; if on then startAutoPlay() else stopAutoPlay() end end, function(k) Keys.autoPlay=k end)
setAutoLeft, autoLeftKeyBtn = makeToggleRow("Auto Left", Keys.autoLeft, false, function(on) State.autoLeftEnabled=on; if on then startAutoLeft() else stopAutoLeft() end end, function(k) Keys.autoLeft=k end)
setAutoRight, autoRightKeyBtn = makeToggleRow("Auto Right", Keys.autoRight, false, function(on) State.autoRightEnabled=on; if on then startAutoRight() else stopAutoRight() end end, function(k) Keys.autoRight=k end)
makeGap(4); makeDivider(); makeGap(4)

makeSectionLabel("Float")
floatHeightBox = makeInputRow("Float Height", State.floatHeight, function(v) local n=tonumber(v); if n and n>=1 and n<=100 then State.floatHeight=n end end)
setFloat, _ = makeToggleRow("Float", Keys.float, false, function(on) State.floatEnabled=on; if on then startFloat() else stopFloat() end end, function(k) Keys.float=k end)
makeGap(4); makeDivider(); makeGap(4)

makeSectionLabel("Interface")
guiHideKeyBtn = makeKeybindRow("Hide / Show GUI", Keys.guiHide, function(k) Keys.guiHide=k end)
makeGap(6)
saveBtn = makeActionBtn("Save Config", function() saveConfig() end)
makeGap(8)

local footerLbl = Instance.new("TextLabel",scroll)
footerLbl.Size=UDim2.new(1,0,0,18); footerLbl.BackgroundTransparency=1; footerLbl.LayoutOrder=LO()
footerLbl.Text="S7  |  vyse.cc"; footerLbl.TextColor3=Color3.fromRGB(50,50,50)
footerLbl.Font=Enum.Font.Gotham; footerLbl.TextSize=10; footerLbl.TextXAlignment=Enum.TextXAlignment.Center

local progressPct = Instance.new("TextLabel",gui)
progressPct.Size=UDim2.new(0,0,0,0); progressPct.Visible=false
local progressFill = Instance.new("Frame",gui)
progressFill.Size=UDim2.new(0,0,0,0); progressFill.Visible=false

local function resetProgressBar() end

local function toggleGuiVis()
	State.guiVisible = not State.guiVisible
	main.Visible = State.guiVisible
	shadow.Visible = State.guiVisible
	closeBtn.Visible = State.guiVisible
	miniBtn.Visible = not State.guiVisible
end

closeBtn.MouseButton1Click:Connect(function() toggleGuiVis() end)
miniBtn.MouseButton1Click:Connect(function() toggleGuiVis() end)

local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	frame.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true; dragStart=inp.Position; startPos=frame.Position
			inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
		end
	end)
	frame.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement then dragInput=inp end end)
	UIS.InputChanged:Connect(function(inp)
		if inp==dragInput and dragging then
			local dx = inp.Position.X - dragStart.X; local dy = inp.Position.Y - dragStart.Y
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+dx, startPos.Y.Scale, startPos.Y.Offset+dy)
		end
	end)
end
makeDraggable(main); makeDraggable(miniBtn)

-- === CORE FUNCTIONS ===
local detectedBaseSideConfirmed = false

local function getPlotPosition(plot)
	if not plot then return nil end
	if plot.PrimaryPart then return plot.PrimaryPart.Position end
	local sign = plot:FindFirstChild("PlotSign")
	if sign then local p=sign:IsA("BasePart") and sign or sign:FindFirstChildWhichIsA("BasePart"); if p then return p.Position end end
	local sum,count = Vector3.zero,0
	for _,obj in plot:GetDescendants() do if obj:IsA("BasePart") then sum+=obj.Position; count+=1 end end
	return count>0 and (sum/count) or nil
end

local function findMyPlot()
	local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
	local name = LP.DisplayName or LP.Name; local nameLower = name:lower()
	for _,plot in plots:GetChildren() do
		local sign=plot:FindFirstChild("PlotSign"); if not sign then continue end
		local yb=sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") and yb.Enabled then return plot end
		local sg=sign:FindFirstChild("SurfaceGui"); if not sg then continue end
		local fr=sg:FindFirstChild("Frame"); if not fr then continue end
		local lbl2=fr:FindFirstChild("TextLabel")
		if lbl2 and typeof(lbl2.Text)=="string" and lbl2.Text~="" then
			local t=lbl2.Text:lower()
			if t:find(nameLower,1,true) and t:find("'s base",1,true) then return plot end
		end
	end
	return nil
end

local function getSideByPlayerPos()
	local char=LP.Character; if not char then return nil end
	local root=char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
	local pos=root.Position
	local dR=(pos-RIGHT_STEP_3).Magnitude; local dL=(pos-LEFT_STEP_3).Magnitude
	if math.abs(dR-dL) > 10 then return dR < dL and "right" or "left" end
	return nil
end

local function getBaseSide()
	if State.detectedBaseSide and detectedBaseSideConfirmed then return State.detectedBaseSide end
	local myPlot
	for _=1,30 do myPlot=findMyPlot(); if myPlot then break end; task.wait(1) end
	if myPlot then
		local bp=getPlotPosition(myPlot)
		if bp then
			local side = (bp-RIGHT_STEP_3).Magnitude < (bp-LEFT_STEP_3).Magnitude and "right" or "left"
			State.detectedBaseSide = side; detectedBaseSideConfirmed = true
			return side
		end
	end
	local posSide = getSideByPlayerPos()
	if posSide then State.detectedBaseSide = posSide; return posSide end
	return State.detectedBaseSide or "left"
end

local function resetBaseSide() State.detectedBaseSide = nil; detectedBaseSideConfirmed = false end

local function isRagdolledCheck()
	local c = LP.Character; if not c then return false end
	local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return false end
	local state = hum:GetState()
	return state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown
end

local function doReturnTeleport(step1, step2, step3)
	if State.brainrotReturnCooldown then return end
	State.brainrotReturnCooldown = true
	if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft = nil end
	if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight = nil end
	State.autoLeftEnabled = false; State.autoRightEnabled = false; State.autoLeftPhase = 1; State.autoRightPhase = 1
	if setAutoLeft then setAutoLeft(false) end; if setAutoRight then setAutoRight(false) end
	if Conns.autoPlay then Conns.autoPlay:Disconnect(); Conns.autoPlay = nil end
	State.autoPlayEnabled = false; State.autoPlayWaypoint = 1; if setAutoPlay then setAutoPlay(false) end
	task.spawn(function()
		pcall(function()
			local c = LP.Character; if not c then return end
			local root = c:FindFirstChild("HumanoidRootPart"); local hum = c:FindFirstChildOfClass("Humanoid")
			if not root then return end
			for _, obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") then obj.Enabled = true end end
			if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
			task.wait(0.20)
			root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = CFrame.new(step1 + Vector3.new(0, 3, 0)); task.wait(0.20)
			root.AssemblyLinearVelocity = Vector3.zero; root.CFrame = CFrame.new(step2 + Vector3.new(0, 3, 0)); task.wait(0.20)
			root.AssemblyLinearVelocity = Vector3.zero; root.CFrame = CFrame.new(step3 + Vector3.new(0, 3, 0))
			if hum then hum:ChangeState(Enum.HumanoidStateType.Running); hum:Move(Vector3.zero, false) end
			for _, obj in ipairs(c:GetDescendants()) do if obj:IsA("Motor6D") then obj.Enabled = true end end
		end)
		task.wait(0.6); State.brainrotReturnCooldown = false
	end)
end

local function isCountdownNum(text) local n=tonumber(text); return n and n>=1 and n<=5 end
local function getTimerLabel()
	local ok,lbl2=pcall(function() return LP.PlayerGui:FindFirstChild("DuelsMachineTopFrame") and LP.PlayerGui.DuelsMachineTopFrame:FindFirstChild("DuelsMachineTopFrame") and LP.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame:FindFirstChild("Timer") and LP.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer:FindFirstChild("Label") end)
	return ok and lbl2 or nil
end
local function isInCountdown() local lbl2=getTimerLabel(); return lbl2 and isCountdownNum(lbl2.Text) end

stopAutoPlay = function()
	State.autoPlayEnabled=false; State.autoPlayWaypoint=1; State.autoPlayWaiting=false; State.autoPlayWaitingCountdown=false
	if Conns.autoPlay then Conns.autoPlay:Disconnect(); Conns.autoPlay=nil end
	local char=LP.Character; if char then
		local root=char:FindFirstChild("HumanoidRootPart"); local hum2=char:FindFirstChildOfClass("Humanoid")
		if root then root.AssemblyLinearVelocity=Vector3.new(0,root.AssemblyLinearVelocity.Y,0) end
		if hum2 then hum2:Move(Vector3.zero,false) end
	end
	if setAutoPlay then setAutoPlay(false) end
end

local function startAutoPlayMovement()
	if Conns.autoPlay then Conns.autoPlay:Disconnect() end
	State.autoPlayWaypoint=1; State.autoPlayWaiting=false
	Conns.autoPlay = RunService.Heartbeat:Connect(function()
		if not State.autoPlayEnabled then return end
		local char=LP.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart"); local hum2=char:FindFirstChildOfClass("Humanoid")
		if not root or not hum2 then return end
		local wps = State.autoPlaySide=="right" and AP_RIGHT_WP or AP_LEFT_WP
		if State.autoPlayWaypoint>#wps then stopAutoPlay(); return end
		if State.autoPlayWaiting then root.AssemblyLinearVelocity=Vector3.new(0,root.AssemblyLinearVelocity.Y,0); return end
		local tp=wps[State.autoPlayWaypoint]
		local txz=Vector3.new(tp.X,0,tp.Z); local cxz=Vector3.new(root.Position.X,0,root.Position.Z)
		local dist=(txz-cxz).Magnitude
		local spd = State.autoPlayWaypoint>2 and State.carrySpeed or State.normalSpeed
		if dist>3 then
			local md=(txz-cxz).Unit
			root.AssemblyLinearVelocity=Vector3.new(md.X*spd,root.AssemblyLinearVelocity.Y,md.Z*spd)
		else
			if State.autoPlayWaypoint==2 then
				root.AssemblyLinearVelocity=Vector3.new(0,root.AssemblyLinearVelocity.Y,0); State.autoPlayWaiting=true
				task.spawn(function() task.wait(0.25); if State.autoPlayEnabled then State.autoPlayWaiting=false; State.autoPlayWaypoint=3 end end)
			elseif State.autoPlayWaypoint==#wps then
				root.AssemblyLinearVelocity=Vector3.new(0,root.AssemblyLinearVelocity.Y,0); stopAutoPlay()
			else
				State.autoPlayWaypoint=State.autoPlayWaypoint+1
			end
		end
	end)
end

function startAutoPlay()
	if not State.autoPlayEnabled then return end
	task.spawn(function()
		local side=getBaseSide(); State.autoPlaySide=(side=="right") and "left" or "right"
		if not State.autoPlayEnabled then return end
		if isInCountdown() then
			local lbl2=getTimerLabel()
			if lbl2 then
				local conn2; conn2=lbl2:GetPropertyChangedSignal("Text"):Connect(function()
					if isCountdownNum(lbl2.Text) and tonumber(lbl2.Text)==1 then
						conn2:Disconnect(); task.wait(AUTO_START_DELAY)
						if State.autoPlayEnabled then startAutoPlayMovement() end
					end
				end)
			else
				startAutoPlayMovement()
			end
		else
			startAutoPlayMovement()
		end
	end)
end

local function findMedusa()
	local char=LP.Character; if not char then return nil end
	for _,tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") then local tn=tool.Name:lower()
		if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end end
	local bp2=LP:FindFirstChild("Backpack")
	if bp2 then for _,tool in ipairs(bp2:GetChildren()) do if tool:IsA("Tool") then local tn=tool.Name:lower()
		if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end end end
	return nil
end

local function useMedusaCounter()
	if State.medusaDebounce then return end
	if tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
	local char=LP.Character; if not char then return end
	State.medusaDebounce=true
	local med=findMedusa(); if not med then State.medusaDebounce=false; return end
	if med.Parent~=char then local hum2=char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
	pcall(function() med:Activate() end)
	State.medusaLastUsed=tick(); State.medusaDebounce=false
end

local function onAnchorChanged(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if part.Anchored and part.Transparency==1 then useMedusaCounter() end end) end
setupMedusaCounter = function(char)
	stopMedusaCounter(); if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
	table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end))
end
stopMedusaCounter = function() for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end; Conns.anchor={} end

local function runDropBrainrot()
	if State.dropBrainrotActive then return end
	local char=LP.Character; if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
	State.dropBrainrotActive=true; local t0=tick(); local dc
	dc=RunService.Heartbeat:Connect(function()
		local r=char and char:FindFirstChild("HumanoidRootPart")
		if not r then dc:Disconnect(); State.dropBrainrotActive=false; return end
		if tick()-t0>=DROP_ASCEND_DURATION then
			dc:Disconnect()
			local rp=RaycastParams.new(); rp.FilterDescendantsInstances={char}; rp.FilterType=Enum.RaycastFilterType.Exclude
			local rr=workspace:Raycast(r.Position,Vector3.new(0,-2000,0),rp)
			if rr then
				local hum2=char:FindFirstChildOfClass("Humanoid")
				local off=(hum2 and hum2.HipHeight or 2)+(r.Size.Y/2)
				r.CFrame=CFrame.new(r.Position.X,rr.Position.Y+off,r.Position.Z); r.AssemblyLinearVelocity=Vector3.new(0,0,0)
			end
			State.dropBrainrotActive=false; return
		end
		r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,DROP_ASCEND_SPEED,r.AssemblyLinearVelocity.Z)
	end)
end

startAutoLeft = function()
	if Conns.autoLeft then Conns.autoLeft:Disconnect() end; State.autoLeftPhase=1
	Conns.autoLeft=RunService.Heartbeat:Connect(function()
		if not State.autoLeftEnabled then return end
		local char=LP.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart"); local hum2=char:FindFirstChildOfClass("Humanoid")
		if not root or not hum2 then return end
		local spd=State.normalSpeed
		if State.autoLeftPhase==1 then
			local tgt=Vector3.new(POS.L1.X,root.Position.Y,POS.L1.Z)
			if (tgt-root.Position).Magnitude<1 then State.autoLeftPhase=2; return end
			local d=(POS.L1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
			hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif State.autoLeftPhase==2 then
			local tgt=Vector3.new(POS.L2.X,root.Position.Y,POS.L2.Z)
			if (tgt-root.Position).Magnitude<1 then
				hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.new(0,0,0)
				State.autoLeftEnabled=false; if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end
				State.autoLeftPhase=1; if setAutoLeft then setAutoLeft(false) end; return
			end
			local d=(POS.L2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
			hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
stopAutoLeft = function()
	if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end; State.autoLeftPhase=1
	local char=LP.Character; if char then local hum2=char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero,false) end end
end

startAutoRight = function()
	if Conns.autoRight then Conns.autoRight:Disconnect() end; State.autoRightPhase=1
	Conns.autoRight=RunService.Heartbeat:Connect(function()
		if not State.autoRightEnabled then return end
		local char=LP.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart"); local hum2=char:FindFirstChildOfClass("Humanoid")
		if not root or not hum2 then return end
		local spd=State.normalSpeed
		if State.autoRightPhase==1 then
			local tgt=Vector3.new(POS.R1.X,root.Position.Y,POS.R1.Z)
			if (tgt-root.Position).Magnitude<1 then State.autoRightPhase=2; return end
			local d=(POS.R1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
			hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif State.autoRightPhase==2 then
			local tgt=Vector3.new(POS.R2.X,root.Position.Y,POS.R2.Z)
			if (tgt-root.Position).Magnitude<1 then
				hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.new(0,0,0)
				State.autoRightEnabled=false; if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end
				State.autoRightPhase=1; if setAutoRight then setAutoRight(false) end; return
			end
			local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
			hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
stopAutoRight = function()
	if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end; State.autoRightPhase=1
	local char=LP.Character; if char then local hum2=char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero,false) end end
end

startFloat = function()
	if Conns.float then Conns.float:Disconnect() end
	Conns.float=RunService.Heartbeat:Connect(function()
		if not State.floatEnabled then return end
		local char=LP.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
		local rp=RaycastParams.new(); rp.FilterDescendantsInstances={char}; rp.FilterType=Enum.RaycastFilterType.Exclude
		local rr=workspace:Raycast(root.Position,Vector3.new(0,-200,0),rp)
		if rr then
			local diff=(rr.Position.Y+State.floatHeight)-root.Position.Y
			if math.abs(diff)>0.3 then root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,diff*15,root.AssemblyLinearVelocity.Z)
			else root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z) end
		end
	end)
end
stopFloat = function()
	if Conns.float then Conns.float:Disconnect(); Conns.float=nil end
	local char=LP.Character; if char then local root=char:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z) end
	end
end

startAntiRagdoll = function()
	if Conns.antiRag then return end
	Conns.antiRag=RunService.Heartbeat:Connect(function()
		local char=LP.Character; if not char then return end
		local hum2=char:FindFirstChildOfClass("Humanoid"); local root=char:FindFirstChild("HumanoidRootPart")
		if hum2 then
			local st=hum2:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum2:ChangeState(Enum.HumanoidStateType.Running); workspace.CurrentCamera.CameraSubject=hum2
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule"); if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.new(0,0,0); root.RotVelocity=Vector3.new(0,0,0) end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end
stopAntiRagdoll = function() if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end end

applyFPSBoost = function()
	pcall(function() setfpscap(999999999) end)
	local function processObj(v)
		pcall(function()
			if v:IsA("Model") then v.LevelOfDetail=Enum.ModelLevelOfDetail.Disabled; v.ModelStreamingMode=Enum.ModelStreamingMode.Nonatomic
			elseif v:IsA("MeshPart") then v.CastShadow=false; v.DoubleSided=false; v.RenderFidelity=Enum.RenderFidelity.Performance
			elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
			elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
			elseif v:IsA("SpecialMesh") then v.TextureId=""
			elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
			elseif v:IsA("Explosion") then v.BlastPressure=1; v.BlastRadius=1
			elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then v:Destroy()
			elseif v:IsA("Attachment") then v.Visible=false end
		end)
	end
	for _,v in pairs(workspace:GetDescendants()) do processObj(v) end
	pcall(function()
		local lighting=game:GetService("Lighting")
		for _,v in pairs(lighting:GetDescendants()) do pcall(function()
			if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end
		end) end
		pcall(function() sethiddenproperty(lighting,"Technology",Enum.Technology.Legacy) end)
		lighting.GlobalShadows=false; lighting.FogEnd=9e9; lighting.Brightness=0
		local terrain=workspace:FindFirstChildOfClass("Terrain")
		if terrain then pcall(function() sethiddenproperty(terrain,"Decoration",false) end)
			terrain.WaterReflectance=0; terrain.WaterTransparency=0.7; terrain.WaterWaveSize=0; terrain.WaterWaveSpeed=0 end
	end)
	workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(processObj,v) end end)
end

local function isMyPlotByName(plotName)
	local ct=tick()
	if Steal.plotCache[plotName] and (ct-(Steal.plotCacheTime[plotName] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[plotName] end
	local plots=workspace:FindFirstChild("Plots"); if not plots then Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false end
	local plot=plots:FindFirstChild(plotName); if not plot then Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false end
	local sign=plot:FindFirstChild("PlotSign")
	if sign then
		local yb=sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then local r=yb.Enabled==true; Steal.plotCache[plotName]=r; Steal.plotCacheTime[plotName]=ct; return r end
	end
	Steal.plotCache[plotName]=false; Steal.plotCacheTime[plotName]=ct; return false
end

local function findNearestPrompt()
	local char=LP.Character; if not char then return nil end
	local root=char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
	local ct=tick()
	if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then
		local np,nd,nn=nil,math.huge,nil
		for _,data in ipairs(Steal.cachedPrompts) do if data.spawn then local dist=(data.spawn.Position-root.Position).Magnitude
			if dist<=Steal.StealRadius and dist<nd then np=data.prompt; nd=dist; nn=data.name end end end
		if np then return np,nd,nn end
	end
	Steal.cachedPrompts={}; Steal.promptCacheTime=ct
	local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end
	local np,nd,nn=nil,math.huge,nil
	for _,plot in ipairs(plots:GetChildren()) do
		if isMyPlotByName(plot.Name) then continue end
		local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
		for _,pod in ipairs(pods:GetChildren()) do pcall(function()
			local base=pod:FindFirstChild("Base"); local sp=base and base:FindFirstChild("Spawn")
			if sp then
				local att=sp:FindFirstChild("PromptAttachment")
				if att then for _,child in ipairs(att:GetChildren()) do if child:IsA("ProximityPrompt") then
					local dist=(sp.Position-root.Position).Magnitude
					table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp,name=pod.Name})
					if dist<=Steal.StealRadius and dist<nd then np=child; nd=dist; nn=pod.Name end; break end end end
			end end)
		end
	end
	return np,nd,nn
end

local function executeSteal(prompt)
	local ct=tick()
	if ct-State.lastStealTick<STEAL_COOLDOWN then return end
	if State.isStealing then return end
	if not Steal.Data[prompt] then
		Steal.Data[prompt]={hold={},trigger={},ready=true}
		pcall(function()
			if getconnections then
				for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
				for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
			else Steal.Data[prompt].useFallback=true end
		end)
	end
	local data=Steal.Data[prompt]; if not data.ready then return end
	data.ready=false; State.isStealing=true; State.stealStartTime=ct; State.lastStealTick=ct
	task.spawn(function()
		local ok=false
		pcall(function()
			if not data.useFallback then
				for _,fn in ipairs(data.hold) do task.spawn(fn) end
				task.wait(Steal.StealDuration)
				for _,fn in ipairs(data.trigger) do task.spawn(fn) end
				ok=true
			end
		end)
		if not ok and fireproximityprompt then pcall(function() fireproximityprompt(prompt); ok=true end) end
		if not ok then pcall(function() prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd() end) end
		task.wait(Steal.StealDuration*0.3)
		data.ready=true; State.isStealing=false
	end)
end

startAutoSteal = function()
	if Conns.autoSteal then return end
	Conns.autoSteal=RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or State.isStealing then return end
		local p=findNearestPrompt(); if p then executeSteal(p) end
	end)
end
stopAutoSteal = function()
	if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal=nil end
	State.isStealing=false; State.lastStealTick=0
	Steal.plotCache={}; Steal.plotCacheTime={}; Steal.cachedPrompts={}; resetProgressBar()
end

local function getBat()
	local char=LP.Character; if not char then return nil end
	local tool=char:FindFirstChild("Bat"); if tool then return tool end
	local bp2=LP:FindFirstChild("Backpack"); if bp2 then tool=bp2:FindFirstChild("Bat"); if tool then tool.Parent=char; return tool end end
	return nil
end
local function tryHitBat()
	if State.hittingCooldown then return end; State.hittingCooldown=true
	pcall(function() local bat=getBat(); if bat then bat:Activate(); local ev=bat:FindFirstChildWhichIsA("RemoteEvent"); if ev then ev:FireServer() end end end)
	task.delay(0.08, function() State.hittingCooldown=false end)
end

saveConfig = function()
	local cfg = { normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed,
		autoBatKey=Keys.autoBat.Name, speedKey=Keys.speed.Name,
		autoStealEnabled=Steal.AutoStealEnabled, grabRadius=Steal.StealRadius,
		infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled, fpsBoost=State.fpsBoostEnabled,
		brainrotReturnLeftKey=Keys.brainrotReturnLeft.Name, brainrotReturnRightKey=Keys.brainrotReturnRight.Name,
		brainrotReturnLeft=State.brainrotReturnLeftEnabled, brainrotReturnRight=State.brainrotReturnRightEnabled,
		medusaCounter=State.medusaCounterEnabled, dropBrainrotKey=Keys.dropBrainrot.Name,
		autoPlayKey=Keys.autoPlay.Name, autoLeftKey=Keys.autoLeft.Name, autoRightKey=Keys.autoRight.Name,
		guiHideKey=Keys.guiHide.Name, floatKey=Keys.float.Name, floatHeight=State.floatHeight,
		animEnabled=State.animEnabled, unwalkEnabled=State.unwalkEnabled,
	}
	local ok=pcall(function() writefile("S7_Config.json",HttpService:JSONEncode(cfg)) end)
	local prev=saveBtn.Text; saveBtn.Text=ok and "Saved!" or "Failed!"; task.wait(1.5); saveBtn.Text=prev
end

local function loadConfig()
	local hasFile=false; pcall(function() hasFile=isfile("S7_Config.json") end); if not hasFile then return end
	local ok,cfg=pcall(function() return HttpService:JSONDecode(readfile("S7_Config.json")) end); if not ok or not cfg then return end
	if cfg.normalSpeed then State.normalSpeed=cfg.normalSpeed; normalBox.Text=tostring(cfg.normalSpeed) end
	if cfg.carrySpeed then State.carrySpeed=cfg.carrySpeed; carryBox.Text=tostring(cfg.carrySpeed) end
	if cfg.autoBatKey and Enum.KeyCode[cfg.autoBatKey] then Keys.autoBat=Enum.KeyCode[cfg.autoBatKey]; if autoBatKeyBtn then autoBatKeyBtn.Text=cfg.autoBatKey end end
	if cfg.speedKey and Enum.KeyCode[cfg.speedKey] then Keys.speed=Enum.KeyCode[cfg.speedKey]; if speedKeyBtn then speedKeyBtn.Text=cfg.speedKey end end
	if cfg.autoLeftKey and Enum.KeyCode[cfg.autoLeftKey] then Keys.autoLeft=Enum.KeyCode[cfg.autoLeftKey]; if autoLeftKeyBtn then autoLeftKeyBtn.Text=cfg.autoLeftKey end end
	if cfg.autoRightKey and Enum.KeyCode[cfg.autoRightKey] then Keys.autoRight=Enum.KeyCode[cfg.autoRightKey]; if autoRightKeyBtn then autoRightKeyBtn.Text=cfg.autoRightKey end end
	if cfg.autoPlayKey and Enum.KeyCode[cfg.autoPlayKey] then Keys.autoPlay=Enum.KeyCode[cfg.autoPlayKey] end
	if cfg.grabRadius then Steal.StealRadius=cfg.grabRadius end
	if cfg.autoStealEnabled then Steal.AutoStealEnabled=true; setInstaGrab(true); startAutoSteal() end
	if cfg.infJump then State.infJumpEnabled=true; setInfJump(true) end
	if cfg.antiRagdoll then State.antiRagdollEnabled=true; setAntiRag(true); startAntiRagdoll() end
	if cfg.fpsBoost then State.fpsBoostEnabled=true; setFps(true); applyFPSBoost() end
	if cfg.brainrotReturnLeftKey and Enum.KeyCode[cfg.brainrotReturnLeftKey] then Keys.brainrotReturnLeft=Enum.KeyCode[cfg.brainrotReturnLeftKey]; if brainrotReturnLeftKeyBtn then brainrotReturnLeftKeyBtn.Text=cfg.brainrotReturnLeftKey end end
	if cfg.brainrotReturnRightKey and Enum.KeyCode[cfg.brainrotReturnRightKey] then Keys.brainrotReturnRight=Enum.KeyCode[cfg.brainrotReturnRightKey]; if brainrotReturnRightKeyBtn then brainrotReturnRightKeyBtn.Text=cfg.brainrotReturnRightKey end end
	if cfg.brainrotReturnLeft then State.brainrotReturnLeftEnabled=true; setBrainrotReturnLeft(true) end
	if cfg.brainrotReturnRight then State.brainrotReturnRightEnabled=true; setBrainrotReturnRight(true) end
	if cfg.medusaCounter then State.medusaCounterEnabled=true; setMedusaCounter(true); setupMedusaCounter(LP.Character) end
	if cfg.dropBrainrotKey and Enum.KeyCode[cfg.dropBrainrotKey] then Keys.dropBrainrot=Enum.KeyCode[cfg.dropBrainrotKey]; if dropBrainrotKeyBtn then dropBrainrotKeyBtn.Text=cfg.dropBrainrotKey end end
	if cfg.guiHideKey and Enum.KeyCode[cfg.guiHideKey] then Keys.guiHide=Enum.KeyCode[cfg.guiHideKey]; if guiHideKeyBtn then guiHideKeyBtn.Text=cfg.guiHideKey end end
	if cfg.floatKey and Enum.KeyCode[cfg.floatKey] then Keys.float=Enum.KeyCode[cfg.floatKey] end
	if cfg.floatHeight then State.floatHeight=cfg.floatHeight; if floatHeightBox then floatHeightBox.Text=tostring(cfg.floatHeight) end end
	if cfg.animEnabled then State.animEnabled=true; setAnimToggle(true); task.spawn(function() task.wait(0.5); if animHeartbeatConn then animHeartbeatConn:Disconnect(); animHeartbeatConn=nil end; local c=LP.Character; if c then saveOriginalAnims(c) end; startAnimToggle(); if c then applyAnimPack(c) end end) end
	if cfg.unwalkEnabled then setUnwalkToggle(true); task.spawn(function() task.wait(0.5); State.unwalkEnabled=false; startUnwalk() end) end
end

local function setupChar(char)
	task.wait(0.1); resetBaseSide(); originalAnims=nil
	h=char:WaitForChild("Humanoid",5); hrp=char:WaitForChild("HumanoidRootPart",5)
	if not h or not hrp then return end
	State.lastKnownHealth=h.Health
	if State.antiRagdollEnabled and not Conns.antiRag then task.wait(0.5); startAntiRagdoll() end
	if State.medusaCounterEnabled then setupMedusaCounter(char) end
	if State.autoPlayEnabled then stopAutoPlay() end
	if State.animEnabled then task.wait(0.3); saveOriginalAnims(char); applyAnimPack(char) end
	if State.unwalkEnabled then State.unwalkEnabled=false; task.wait(0.3); startUnwalk() end
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then
		for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end
	end end
end)

UIS.JumpRequest:Connect(function()
	if not State.infJumpEnabled then return end
	local char=LP.Character; if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
end)
RunService.Heartbeat:Connect(function()
	if not State.infJumpEnabled then return end
	local char=LP.Character; if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if root and root.Velocity.Y<-120 then root.Velocity=Vector3.new(root.Velocity.X,-120,root.Velocity.Z) end
end)

RunService.RenderStepped:Connect(function()
	if not (h and hrp) then return end
	if State._tpInProgress then return end
	if not State.autoPlayEnabled then
		local md=h.MoveDirection; local spd=State.speedToggled and State.carrySpeed or State.normalSpeed
		if md.Magnitude>0 then State.lastMoveDir=md; hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
		elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
			local anyHeld=false; for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
			if anyHeld then hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd) end
		end
	end
end)

local function getClosestPlayer()
	if not hrp then return nil,math.huge end
	local cp,cd=nil,math.huge
	for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.Character then
		local tr=p.Character:FindFirstChild("HumanoidRootPart")
		if tr then local d=(hrp.Position-tr.Position).Magnitude; if d<cd then cd=d; cp=p end end
	end
	return cp,cd
end

RunService.Heartbeat:Connect(function()
	if not (State.autoBatToggled and h and hrp) then return end
	local target,dist=getClosestPlayer()
	if target and target.Character then
		local tr=target.Character:FindFirstChild("HumanoidRootPart")
		if tr then
			local fp=tr.Position+tr.CFrame.LookVector*1.5
			local dir=(fp-hrp.Position).Unit
			hrp.Velocity=Vector3.new(dir.X*56.5,dir.Y*56.5,dir.Z*56.5)
			if dist<=5 then tryHitBat() end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	local isLeftActive = State.brainrotReturnLeftEnabled
	local isRightActive = State.brainrotReturnRightEnabled
	if not (isLeftActive or isRightActive) then return end
	if State.brainrotReturnCooldown then return end
	local char = LP.Character; if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
	local currentHealth = hum.Health
	local wasHit = currentHealth < State.lastKnownHealth - 1
	local isRagdolled = isRagdolledCheck()
	State.lastKnownHealth = currentHealth
	if not (wasHit or isRagdolled) then return end
	if isLeftActive then doReturnTeleport(LEFT_STEP_1, LEFT_STEP_2, LEFT_STEP_3)
	elseif isRightActive then doReturnTeleport(RIGHT_STEP_1, RIGHT_STEP_2, RIGHT_STEP_3) end
end)

UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
	local kc=inp.KeyCode
	if kc==Keys.speed then State.speedToggled=not State.speedToggled; modeValLbl.Text=State.speedToggled and "Carry" or "Normal"
	elseif kc==Keys.autoBat then State.autoBatToggled=not State.autoBatToggled; setAutoBat(State.autoBatToggled)
	elseif kc==Keys.brainrotReturnLeft then State.brainrotReturnLeftEnabled=not State.brainrotReturnLeftEnabled; setBrainrotReturnLeft(State.brainrotReturnLeftEnabled)
		if State.brainrotReturnLeftEnabled then State.brainrotReturnRightEnabled=false; if setBrainrotReturnRight then setBrainrotReturnRight(false) end end
	elseif kc==Keys.brainrotReturnRight then State.brainrotReturnRightEnabled=not State.brainrotReturnRightEnabled; setBrainrotReturnRight(State.brainrotReturnRightEnabled)
		if State.brainrotReturnRightEnabled then State.brainrotReturnLeftEnabled=false; if setBrainrotReturnLeft then setBrainrotReturnLeft(false) end end
	elseif kc==Keys.autoPlay then State.autoPlayEnabled=not State.autoPlayEnabled; setAutoPlay(State.autoPlayEnabled); if State.autoPlayEnabled then startAutoPlay() else stopAutoPlay() end
	elseif kc==Keys.autoLeft then State.autoLeftEnabled=not State.autoLeftEnabled; if setAutoLeft then setAutoLeft(State.autoLeftEnabled) end; if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
	elseif kc==Keys.autoRight then State.autoRightEnabled=not State.autoRightEnabled; if setAutoRight then setAutoRight(State.autoRightEnabled) end; if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
	elseif kc==Keys.dropBrainrot then task.spawn(runDropBrainrot)
	elseif kc==Keys.float then State.floatEnabled=not State.floatEnabled; if setFloat then setFloat(State.floatEnabled) end; if State.floatEnabled then startFloat() else stopFloat() end
	elseif kc==Keys.guiHide then toggleGuiVis() end
end)

loadConfig()
print("[S7] Loaded!")
