-- REDZ XITER v3
local env = (getgenv and getgenv()) or _G
if env.__REDZ_UNLOAD then pcall(env.__REDZ_UNLOAD) end

local Players, RunService, TweenService, UIS, Lighting, Stats =
    game:GetService("Players"), game:GetService("RunService"), game:GetService("TweenService"),
    game:GetService("UserInputService"), game:GetService("Lighting"), game:GetService("Stats")
local LocalPlayer, Camera = Players.LocalPlayer, workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local TixSettings = {
    -- Aimbot
    Sticky = false, AimMode = "Always", AimKey = "RMB", Priority = "Crosshair", TargetPart = "Head",
    WallCheck = true, TeamCheck = false, FriendCheck = false,
    FOV = 150, FOVOrigin = "Center", Smoothness = 1, Prediction = 0, CircleVis = false,
    Triggerbot = false, Auto360 = false, SpinSpeed = 15, Optimizer = false,
    -- ESP
    ESPBox = false, BoxStyle = "Box", ESPSkeleton = false, ESPHealth = false, ESPName = false,
    ESPDistance = false, ESPTracer = false, ESPDot = false, ESPArrows = false, UseDisplay = false,
    ESPTeamCheck = false, ESPTeamSelected = {},  -- {[teamName]=true}; empty = all enemies
    ColVisible = "Green", ColHidden = "Red", ColTeam = "Blue",
    -- Misc
    Watermark = false, Notify = true,
}
local S = TixSettings

-- THEME
local RedzPrimary = Color3.fromRGB(220, 0, 0)
local RedzDarkBg = Color3.fromRGB(12, 5, 5)
local RedzCardBg = Color3.fromRGB(22, 10, 10)
local OffText = Color3.fromRGB(170, 150, 150)
local Palette = {
    Red = RedzPrimary, Green = Color3.fromRGB(0, 255, 0), Blue = Color3.fromRGB(60, 120, 255),
    Yellow = Color3.fromRGB(255, 220, 0), Cyan = Color3.fromRGB(0, 230, 255),
    Pink = Color3.fromRGB(255, 90, 200), Orange = Color3.fromRGB(255, 140, 0), White = Color3.fromRGB(255, 255, 255),
}
local PaletteNames = {"Red", "Green", "Blue", "Yellow", "Cyan", "Pink", "Orange", "White"}
local BoneStructure = {
    R15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    },
    R6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}},
}
local KeyMap = {
    RMB = Enum.UserInputType.MouseButton2, LMB = Enum.UserInputType.MouseButton1,
    E = Enum.KeyCode.E, Q = Enum.KeyCode.Q, Shift = Enum.KeyCode.LeftShift,
}

-- STATE / CLEANUP (everything tracked here is released by Unload)
local alive, conns, drawSet = true, {}, {}
local Unload, spinCleanup, lockPlayer, aimToggled
local ESP = {}  -- [Player] = entry

local function track(c) conns[#conns + 1] = c; return c end

local function newDraw(kind, props, bucket)
    local d = Drawing.new(kind)
    for k, v in pairs(props) do d[k] = v end
    drawSet[d] = true
    if bucket then bucket[#bucket + 1] = d end
    return d
end

local function mk(class, parent, props)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    i.Parent = parent
    return i
end
local function corner(i, r) return mk("UICorner", i, {CornerRadius = UDim.new(0, r or 8)}) end
local function stroke(i, th, tr) return mk("UIStroke", i, {Thickness = th, Transparency = tr or 0, Color = RedzPrimary}) end
local function Lbl(p, text, size, pos, align, col, ts)
    return mk("TextLabel", p, {
        Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold,
        TextColor3 = col or RedzPrimary, TextSize = ts or 14, TextXAlignment = align or Enum.TextXAlignment.Left,
    })
end

local Circle = newDraw("Circle", {Thickness = 2, NumSides = 64, Filled = false, Color = RedzPrimary, Visible = false})

-- ── HELPERS ─────────────────────────────────────────────────
local friendCache = {}
local function isFriend(p)
    if friendCache[p.UserId] == nil then
        friendCache[p.UserId] = false
        task.spawn(function()
            local ok, r = pcall(function() return LocalPlayer:IsFriendsWith(p.UserId) end)
            if ok then friendCache[p.UserId] = r end
        end)
    end
    return friendCache[p.UserId]
end

-- nil teams are never "same team" (teamless games)
local function sameTeam(p) return p.Team ~= nil and p.Team == LocalPlayer.Team end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local function rayClear(part)
    rp.FilterDescendantsInstances = {Camera, LocalPlayer.Character}
    local o = Camera.CFrame.Position
    local r = workspace:Raycast(o, part.Position - o, rp)
    return r == nil or r.Instance:IsDescendantOf(part.Parent)
end

local function keyHeld(k)
    if k.EnumType == Enum.KeyCode then return UIS:IsKeyDown(k) end
    return UIS:IsMouseButtonPressed(k)
end

-- ── AIMBOT ──────────────────────────────────────────────────
local function getChosenPart(c)
    if S.TargetPart == "Torso" then
        return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart")
    end
    return c:FindFirstChild(S.TargetPart) or c:FindFirstChild("Head")
end

-- velocity lead in ms (uncalibrated: tune per game)
local function aimPos(part)
    local root = part.Parent:FindFirstChild("HumanoidRootPart")
    if S.Prediction > 0 and root then return part.Position + root.AssemblyLinearVelocity * (S.Prediction / 1000) end
    return part.Position
end

local function evalTarget(p, org, maxR)
    local c = p.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if (S.TeamCheck and sameTeam(p)) or (S.FriendCheck and isFriend(p)) then return end
    local part = getChosenPart(c)
    if not part then return end
    local v, on = Camera:WorldToViewportPoint(aimPos(part))
    if not on then return end
    local mag = (Vector2.new(v.X, v.Y) - org).Magnitude
    if mag > maxR or (S.WallCheck and not rayClear(part)) then return end
    local score = mag
    if S.Priority == "Distance" then score = (part.Position - Camera.CFrame.Position).Magnitude
    elseif S.Priority == "Health" then score = hum.Health end
    return part, score
end

-- keeps the current target while it stays valid (1.3x FOV hysteresis), so it doesn't flicker between players
local function getTarget(org)
    if lockPlayer then
        local part = evalTarget(lockPlayer, org, S.FOV * 1.3)
        if part then return part end
        lockPlayer = nil
    end
    local best, bestScore, bestP
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local part, score = evalTarget(p, org, S.FOV)
            if part and (not bestScore or score < bestScore) then best, bestScore, bestP = part, score, p end
        end
    end
    lockPlayer = bestP
    return best
end

local lastTrig = 0
local function triggerStep()
    if tick() - lastTrig < 0.05 then return end
    local t = Mouse.Target
    local obj = t and t.Parent
    if obj and obj:IsA("Accessory") then obj = obj.Parent end
    local p = obj and Players:GetPlayerFromCharacter(obj)
    local hum = obj and obj:FindFirstChildOfClass("Humanoid")
    if p and p ~= LocalPlayer and hum and hum.Health > 0 and not (S.TeamCheck and sameTeam(p)) and not (S.FriendCheck and isFriend(p)) then
        lastTrig = tick()
        if mouse1click then mouse1click()
        else
            task.spawn(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
                task.wait()
                vim:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
            end)
        end
    end
end

-- ── AUTO 360 ────────────────────────────────────────────────
local isSpinning = false
local function do360Spin()
    if isSpinning or not alive then return end
    local char = LocalPlayer.Character
    local hrp, hum = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end
    isSpinning = true
    -- AlignOrientation keeps WASD physics intact
    local att = mk("Attachment", hrp, {Name = "Redz360Attachment"})
    local align = mk("AlignOrientation", hrp, {
        Name = "Redz360Align", Attachment0 = att, Mode = Enum.OrientationAlignmentMode.OneAttachment,
        RigidityEnabled = false, MaxAngularVelocity = math.huge, MaxTorque = math.huge, Responsiveness = 200,
    })
    local startYaw, deg, conn = select(2, hrp.CFrame:ToOrientation()), 0, nil
    spinCleanup = function()
        if conn then conn:Disconnect() end
        align:Destroy(); att:Destroy()
        isSpinning, spinCleanup = false, nil
    end
    conn = track(RunService.Heartbeat:Connect(function(dt)
        if not (alive and S.Auto360 and hrp.Parent and hum.Parent and hum.Health > 0) then return spinCleanup() end
        local step = math.min(S.SpinSpeed * 60 * dt, 360 - deg)
        deg = deg + step
        align.CFrame = CFrame.Angles(0, startYaw + math.rad(deg), 0)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(step), 0)
        if deg >= 360 then spinCleanup() end
    end))
end

local function hookJump(char)
    local h = char:WaitForChild("Humanoid", 10)
    if h then h.Jumping:Connect(function(a) if a and alive and S.Auto360 then do360Spin() end end) end
end

-- ── FPS OPTIMIZER (runs once, restorable) ───────────────────
local optOrig, optConn, optLight = {}, nil, nil
local function optApply(v)
    if optOrig[v] then return end
    if v:IsA("BasePart") then
        optOrig[v] = {v.Material, v.Reflectance}; v.Material = Enum.Material.Plastic; v.Reflectance = 0
    elseif v:IsA("Decal") or v:IsA("Texture") then
        optOrig[v] = {v.Transparency}; v.Transparency = 1
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
        optOrig[v] = {v.Enabled}; v.Enabled = false
    end
end
local function setOptimizer(on)
    if optConn then optConn:Disconnect(); optConn = nil end
    if not on then
        for v, o in pairs(optOrig) do
            pcall(function()
                if v:IsA("BasePart") then v.Material, v.Reflectance = o[1], o[2]
                elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = o[1]
                else v.Enabled = o[1] end
            end)
        end
        table.clear(optOrig)
        if optLight ~= nil then Lighting.GlobalShadows = optLight; optLight = nil end
        return
    end
    if optLight == nil then optLight = Lighting.GlobalShadows end
    Lighting.GlobalShadows = false
    optConn = workspace.DescendantAdded:Connect(function(v) pcall(optApply, v) end)
    task.spawn(function()
        for i, v in ipairs(workspace:GetDescendants()) do
            if not S.Optimizer then return end
            pcall(optApply, v)
            if i % 400 == 0 then task.wait() end
        end
    end)
end

-- ── ESP ─────────────────────────────────────────────────────
local function espAllowed(p)
    if not S.ESPTeamCheck then return true end
    if sameTeam(p) then return false end
    if next(S.ESPTeamSelected) and not S.ESPTeamSelected[p.Team and p.Team.Name or "Sem Time"] then return false end
    return true
end

local function makeEntry(p)
    local e = {all = {}}
    local function T(sz) return newDraw("Text", {Size = sz, Font = 2, Center = true, Outline = true, Visible = false}, e.all) end
    e.box = newDraw("Square", {Thickness = 1.5, Filled = false, Visible = false}, e.all)
    e.hpBg = newDraw("Line", {Thickness = 4, Color = Color3.fromRGB(30, 30, 30), Visible = false}, e.all)
    e.hpFill = newDraw("Line", {Thickness = 2, Visible = false}, e.all)
    e.name, e.dist = T(13), T(12)
    e.tracer = newDraw("Line", {Thickness = 1, Visible = false}, e.all)
    e.dot = newDraw("Circle", {Thickness = 1, NumSides = 16, Filled = true, Visible = false}, e.all)
    e.arrow = newDraw("Triangle", {Thickness = 1, Filled = true, Visible = false}, e.all)
    ESP[p] = e
    return e
end

local function lines(e, key, n)  -- lazily created line sets (corner box, skeleton)
    if not e[key] then
        local t = {}
        for i = 1, n do t[i] = newDraw("Line", {Thickness = 1.5, Visible = false}, e.all) end
        e[key] = t
    end
    return e[key]
end
local function setVis(list, v) if list then for _, d in ipairs(list) do d.Visible = v end end end
local function hideEntry(e) for _, d in ipairs(e.all) do d.Visible = false end; e.state = nil end

local function drawPlayer(p, e, c, hum, root, head, now, vp)
    -- colors: team > visible > hidden (visibility raycast throttled to 10 Hz)
    local col
    if sameTeam(p) then col = Palette[S.ColTeam]
    else
        if now - (e.vt or 0) > 0.1 then e.vt, e.seen = now, rayClear(head) end
        col = Palette[e.seen and S.ColVisible or S.ColHidden]
    end

    -- 2D rect from head top to feet (works for scaled R15 and R6)
    local below = hum.RigType == Enum.HumanoidRigType.R15 and hum.HipHeight + root.Size.Y / 2 or 3
    local t = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0))
    local b = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, below, 0))
    local cx = (t.X + b.X) / 2
    local on = t.Z > 0 and b.Z > 0 and cx >= 0 and cx <= vp.X and b.Y >= 0 and t.Y <= vp.Y

    if not on then  -- off-screen arrow
        if e.state == "full" then hideEntry(e) end
        e.state = "arrow"
        e.arrow.Visible = S.ESPArrows
        if S.ESPArrows then
            local rel = Camera.CFrame:PointToObjectSpace(root.Position)
            local d = Vector2.new(rel.X, rel.Z)
            d = d.Magnitude > 1e-3 and d.Unit or Vector2.new(0, 1)
            local ctr = vp / 2
            local pt, n = ctr + d * (math.min(ctr.X, ctr.Y) * 0.7), Vector2.new(-d.Y, d.X)
            e.arrow.PointA, e.arrow.PointB, e.arrow.PointC = pt + d * 12, pt - d * 6 + n * 8, pt - d * 6 - n * 8
            e.arrow.Color = col
        end
        return
    end

    e.state = "full"
    e.arrow.Visible = false
    local h = b.Y - t.Y
    local w = h * 0.6
    local x, y = cx - w / 2, t.Y

    -- box / corner box
    local style = S.ESPBox and S.BoxStyle
    e.box.Visible = style == "Box"
    if style == "Box" then e.box.Position, e.box.Size, e.box.Color = Vector2.new(x, y), Vector2.new(w, h), col end
    if style == "Corner" then
        local cl, lw, lh = lines(e, "corn", 8), w * 0.3, h * 0.2
        local cs = {
            {x, y, lw, 0}, {x, y, 0, lh}, {x + w, y, -lw, 0}, {x + w, y, 0, lh},
            {x, y + h, lw, 0}, {x, y + h, 0, -lh}, {x + w, y + h, -lw, 0}, {x + w, y + h, 0, -lh},
        }
        for i, s in ipairs(cs) do
            local l = cl[i]
            l.From, l.To, l.Color, l.Visible = Vector2.new(s[1], s[2]), Vector2.new(s[1] + s[3], s[2] + s[4]), col, true
        end
    else setVis(e.corn, false) end

    -- health bar
    e.hpBg.Visible, e.hpFill.Visible = S.ESPHealth, S.ESPHealth
    if S.ESPHealth then
        local fr, bx = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), x - 5
        e.hpBg.From, e.hpBg.To = Vector2.new(bx, y + h), Vector2.new(bx, y)
        e.hpFill.From, e.hpFill.To = Vector2.new(bx, y + h), Vector2.new(bx, y + h - h * fr)
        e.hpFill.Color = Color3.fromRGB(255 * (1 - fr), 255 * fr, 0)
    end

    -- name / distance
    e.name.Visible = S.ESPName
    if S.ESPName then
        e.name.Text, e.name.Color, e.name.Position = S.UseDisplay and p.DisplayName or p.Name, col, Vector2.new(cx, y - 16)
    end
    e.dist.Visible = S.ESPDistance
    if S.ESPDistance then
        e.dist.Text = math.floor((root.Position - Camera.CFrame.Position).Magnitude) .. "m"
        e.dist.Color, e.dist.Position = OffText, Vector2.new(cx, y + h + 2)
    end

    -- tracer / head dot
    e.tracer.Visible = S.ESPTracer
    if S.ESPTracer then e.tracer.From, e.tracer.To, e.tracer.Color = Vector2.new(vp.X / 2, vp.Y), Vector2.new(cx, y + h), col end
    e.dot.Visible = S.ESPDot
    if S.ESPDot then
        local hv = Camera:WorldToViewportPoint(head.Position)
        e.dot.Position, e.dot.Radius, e.dot.Color = Vector2.new(hv.X, hv.Y), math.max(2, h * 0.05), col
    end

    -- skeleton
    if S.ESPSkeleton then
        local bs, bl = BoneStructure[hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"], lines(e, "bones", 14)
        for i = 1, 14 do
            local pr, l, ok = bs[i], bl[i], false
            if pr then
                local pa, pb = c:FindFirstChild(pr[1]), c:FindFirstChild(pr[2])
                if pa and pb then
                    local va, oa = Camera:WorldToViewportPoint(pa.Position)
                    local vb, ob = Camera:WorldToViewportPoint(pb.Position)
                    if oa and ob then l.From, l.To, l.Color, ok = Vector2.new(va.X, va.Y), Vector2.new(vb.X, vb.Y), col, true end
                end
            end
            l.Visible = ok
        end
    else setVis(e.bones, false) end
end

local function updateESP(now, vp)
    local any = S.ESPBox or S.ESPSkeleton or S.ESPHealth or S.ESPName or S.ESPDistance or S.ESPTracer or S.ESPDot or S.ESPArrows
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c = p.Character
            local hum, root, head = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChild("Head")
            local e = ESP[p]
            if any and hum and root and head and hum.Health > 0 and espAllowed(p) then
                drawPlayer(p, e or makeEntry(p), c, hum, root, head, now, vp)
            elseif e and e.state then hideEntry(e) end
        end
    end
end

-- ── UI ──────────────────────────────────────────────────────
local TixUI = mk("ScreenGui", gethui and gethui() or game:GetService("CoreGui"), {Name = "REDZ_XITER_V2", ResetOnSpawn = false})

local TogglePanel = mk("Frame", TixUI, {Size = UDim2.new(0, 55, 0, 45), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = RedzDarkBg, Active = true, Draggable = true})
corner(TogglePanel); stroke(TogglePanel, 2)
local ToggleBtn = mk("TextButton", TogglePanel, {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "REDZ", Font = Enum.Font.GothamBold, TextColor3 = RedzPrimary, TextSize = 14})

local VisiblePos, HiddenPos = UDim2.new(0.5, -180, 0.5, -150), UDim2.new(0.5, -180, 1.2, 0)
local Main = mk("Frame", TixUI, {Size = UDim2.new(0, 360, 0, 300), Position = HiddenPos, BackgroundColor3 = RedzDarkBg, Visible = false, Active = true, Draggable = true})
corner(Main, 10); stroke(Main, 2)
Lbl(Main, "REDZ XITER", UDim2.new(1, 0, 0, 50), nil, Enum.TextXAlignment.Center, nil, 22)
local CloseBtn = mk("TextButton", Main, {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -35, 0, 10), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold, TextColor3 = RedzPrimary, TextSize = 25})

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = true; TogglePanel.Visible = false
    Main:TweenPosition(VisiblePos, "Out", "Quart", 0.5, true)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main:TweenPosition(HiddenPos, "In", "Quart", 0.4, true, function() Main.Visible = false; TogglePanel.Visible = true end)
end)

-- toasts + watermark (created after Main so they render on top)
local Toasts = mk("Frame", TixUI, {Size = UDim2.new(0, 230, 1, -20), Position = UDim2.new(1, -240, 0, 10), BackgroundTransparency = 1})
mk("UIListLayout", Toasts, {Padding = UDim.new(0, 4)})
local function Notify(text)
    if not S.Notify then return end
    local t = Lbl(Toasts, text, UDim2.new(1, 0, 0, 26), nil, Enum.TextXAlignment.Center, nil, 13)
    t.BackgroundTransparency, t.BackgroundColor3 = 0, RedzCardBg
    corner(t, 6); stroke(t, 1)
    task.delay(2.5, function() if t.Parent then t:Destroy() end end)
end
local WM = Lbl(TixUI, "", UDim2.new(0, 220, 0, 22), UDim2.new(0.5, -110, 0, 6), Enum.TextXAlignment.Center, nil, 13)
WM.BackgroundTransparency, WM.BackgroundColor3, WM.Visible = 0, RedzCardBg, false
corner(WM, 6); stroke(WM, 1)

-- tabs
local TabBar = mk("Frame", Main, {Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 46), BackgroundTransparency = 1})
mk("UIListLayout", TabBar, {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)})
local tabs = {}
local function selectTab(sc)
    for _, t in ipairs(tabs) do
        local on = t.scroll == sc
        t.scroll.Visible, t.btn.TextColor3, t.stroke.Transparency = on, on and RedzPrimary or OffText, on and 0 or 0.7
        t.btn.BackgroundColor3 = on and Color3.fromRGB(50, 5, 5) or RedzCardBg
    end
end
local function MakeTab(label)
    local btn = mk("TextButton", TabBar, {Size = UDim2.new(1 / 3, -4, 1, 0), BackgroundColor3 = RedzCardBg, AutoButtonColor = false, Text = label, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = OffText})
    corner(btn, 6)
    local sc = mk("ScrollingFrame", Main, {
        Size = UDim2.new(1, -20, 1, -90), Position = UDim2.new(0, 10, 0, 82), BackgroundTransparency = 1, Visible = false,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 2, ScrollBarImageColor3 = RedzPrimary,
    })
    mk("UIListLayout", sc, {Padding = UDim.new(0, 6)})
    tabs[#tabs + 1] = {btn = btn, scroll = sc, stroke = stroke(btn, 1, 0.7)}
    btn.MouseButton1Click:Connect(function() selectTab(sc) end)
    return sc
end
local ScrollAimbot, ScrollVisual, ScrollMisc = MakeTab("Aimbot"), MakeTab("Visual & ESP"), MakeTab("Misc")
selectTab(ScrollAimbot)

-- widgets
local function Card(parent, h, class)
    local c = mk(class or "TextButton", parent, {Size = UDim2.new(1, -5, 0, h), BackgroundColor3 = RedzCardBg})
    if c:IsA("TextButton") then c.Text, c.AutoButtonColor = "", false end
    corner(c); stroke(c, 1, 0.8)
    return c
end

local function AddToggle(text, key, scroll, cb)
    local btn = Card(scroll, 42)
    Lbl(btn, text, UDim2.new(1, -60, 1, 0), UDim2.new(0, 15, 0, 0))
    local st = Lbl(btn, "OFF", UDim2.new(0, 40, 1, 0), UDim2.new(1, -55, 0, 0), Enum.TextXAlignment.Right, OffText, 13)
    local function paint()
        local on = S[key]
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = on and Color3.fromRGB(60, 5, 5) or RedzCardBg}):Play()
        st.Text, st.TextColor3 = on and "ON" or "OFF", on and RedzPrimary or OffText
    end
    btn.MouseButton1Click:Connect(function() S[key] = not S[key]; paint(); if cb then cb(S[key]) end end)
    paint()
end

local function AddSlider(text, key, min, max, scroll)
    local c = Card(scroll, 50, "Frame")
    local lbl = Lbl(c, text .. ": " .. S[key], UDim2.new(1, -20, 0, 20), UDim2.new(0, 15, 0, 5))
    local bar = mk("Frame", c, {Size = UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 15, 0, 32), BackgroundColor3 = Color3.fromRGB(50, 5, 5)})
    corner(bar)
    local knob = mk("TextButton", bar, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new((S[key] - min) / (max - min), -7, 0.5, -7), BackgroundColor3 = RedzPrimary, Text = ""})
    corner(knob)
    local drag = false
    local function isPtr(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
    knob.InputBegan:Connect(function(i) if isPtr(i) then drag = true end end)
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local r = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            S[key] = math.round(min + (max - min) * r)
            knob.Position, lbl.Text = UDim2.new(r, -7, 0.5, -7), text .. ": " .. S[key]
        end
    end))
    track(UIS.InputEnded:Connect(function(i) if isPtr(i) then drag = false end end))
end

local function AddSelector(text, key, options, scroll, colored)
    local btn = Card(scroll, 42)
    Lbl(btn, text, UDim2.new(1, -120, 1, 0), UDim2.new(0, 15, 0, 0))
    local st = Lbl(btn, "", UDim2.new(0, 100, 1, 0), UDim2.new(1, -115, 0, 0), Enum.TextXAlignment.Right, nil, 13)
    local idx = table.find(options, S[key]) or 1
    local function paint()
        S[key] = options[idx]
        st.Text = tostring(S[key]):upper()
        if colored then st.TextColor3 = Palette[S[key]] end
    end
    btn.MouseButton1Click:Connect(function() idx = idx % #options + 1; paint() end)
    paint()
end

local function AddButton(text, fn, scroll)
    local btn = Card(scroll, 42)
    Lbl(btn, text, UDim2.new(1, 0, 1, 0), nil, Enum.TextXAlignment.Center)
    btn.MouseButton1Click:Connect(fn)
end

-- AIMBOT TAB
AddToggle("Sticky Aim", "Sticky", ScrollAimbot, function(on)
    Notify("Sticky Aim " .. (on and "ON" or "OFF"))
    if not on then  -- remove residual camera roll
        lockPlayer = nil
        pcall(function() local p = Camera.CFrame.Position; Camera.CFrame = CFrame.new(p, p + Camera.CFrame.LookVector) end)
    end
end)
AddSelector("Aim Mode", "AimMode", {"Always", "Hold", "Toggle"}, ScrollAimbot)
AddSelector("Aim Key (Hold/Toggle)", "AimKey", {"RMB", "LMB", "E", "Q", "Shift"}, ScrollAimbot)
AddSelector("Target Priority", "Priority", {"Crosshair", "Distance", "Health"}, ScrollAimbot)
AddSelector("Puxar Em (Target)", "TargetPart", {"Head", "Torso", "HumanoidRootPart"}, ScrollAimbot)
AddToggle("Wall Check", "WallCheck", ScrollAimbot)
AddToggle("Team Check", "TeamCheck", ScrollAimbot)
AddToggle("Friend Check", "FriendCheck", ScrollAimbot)
AddToggle("Trigger Bot", "Triggerbot", ScrollAimbot)
AddToggle("Auto 360 On Jump", "Auto360", ScrollAimbot)
AddToggle("Show FOV Circle", "CircleVis", ScrollAimbot)
AddSelector("FOV Origin", "FOVOrigin", {"Center", "Mouse"}, ScrollAimbot)
AddSlider("Tamanho do FOV", "FOV", 10, 600, ScrollAimbot)
AddSlider("Suavidade (Smoothness)", "Smoothness", 1, 200, ScrollAimbot)
AddSlider("Prediction (ms)", "Prediction", 0, 300, ScrollAimbot)
AddSlider("Velocidade do 360", "SpinSpeed", 5, 30, ScrollAimbot)

-- VISUAL TAB
AddToggle("ESP Box", "ESPBox", ScrollVisual)
AddSelector("Box Style", "BoxStyle", {"Box", "Corner"}, ScrollVisual)
AddToggle("ESP Skeleton", "ESPSkeleton", ScrollVisual)
AddToggle("ESP Health Bar", "ESPHealth", ScrollVisual)
AddToggle("ESP Nome", "ESPName", ScrollVisual)
AddToggle("Use Display Name", "UseDisplay", ScrollVisual)
AddToggle("ESP Distância", "ESPDistance", ScrollVisual)
AddToggle("ESP Tracers", "ESPTracer", ScrollVisual)
AddToggle("ESP Head Dot", "ESPDot", ScrollVisual)
AddToggle("Off-screen Arrows", "ESPArrows", ScrollVisual)
AddToggle("ESP Team Check", "ESPTeamCheck", ScrollVisual)

do  -- team drawer
    local Teams, open = game:GetService("Teams"), false
    local box = Card(ScrollVisual, 42, "Frame")
    box.AutomaticSize = Enum.AutomaticSize.Y
    mk("UIListLayout", box, {Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    local head = mk("TextButton", box, {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = "", LayoutOrder = 1})
    Lbl(head, "Selecionar Times", UDim2.new(1, -60, 1, 0), UDim2.new(0, 15, 0, 0))
    local arrow = Lbl(head, "▾", UDim2.new(0, 30, 1, 0), UDim2.new(1, -38, 0, 0), Enum.TextXAlignment.Center, nil, 16)
    local drawer = mk("Frame", box, {Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 2})
    mk("UIListLayout", drawer, {Padding = UDim.new(0, 4)})

    local function rebuild()
        for _, ch in ipairs(drawer:GetChildren()) do if not ch:IsA("UIListLayout") then ch:Destroy() end end
        local list = Teams:GetTeams()
        if #list == 0 then
            Lbl(drawer, "Nenhum time encontrado neste jogo", UDim2.new(1, 0, 0, 28), nil, Enum.TextXAlignment.Center, OffText, 12)
            return
        end
        for _, team in ipairs(list) do
            if team ~= LocalPlayer.Team then
                local row = mk("TextButton", drawer, {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(30, 8, 8), AutoButtonColor = false, Text = ""})
                corner(row, 5)
                corner(mk("Frame", row, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0.5, -7), BackgroundColor3 = team.TeamColor.Color}), 3)
                Lbl(row, team.Name, UDim2.new(1, -70, 1, 0), UDim2.new(0, 32, 0, 0), nil, nil, 13)
                local cb = mk("Frame", row, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -28, 0.5, -9)})
                corner(cb, 4); stroke(cb, 1)
                local mark = Lbl(cb, "✓", UDim2.new(1, 0, 1, 0), nil, Enum.TextXAlignment.Center, nil, 13)
                local function paint()
                    local on = S.ESPTeamSelected[team.Name] == true
                    mark.Visible, cb.BackgroundColor3 = on, on and Color3.fromRGB(60, 5, 5) or Color3.fromRGB(40, 10, 10)
                end
                -- unchecked = nil (not false), so an empty selection means "all enemies" again
                row.MouseButton1Click:Connect(function() S.ESPTeamSelected[team.Name] = (not S.ESPTeamSelected[team.Name]) or nil; paint() end)
                paint()
            end
        end
    end
    head.MouseButton1Click:Connect(function()
        open = not open
        if open then rebuild() end
        drawer.Visible, arrow.Text = open, open and "▴" or "▾"
    end)
end

AddSelector("Visible Color", "ColVisible", PaletteNames, ScrollVisual, true)
AddSelector("Hidden Color", "ColHidden", PaletteNames, ScrollVisual, true)
AddSelector("Team Color", "ColTeam", PaletteNames, ScrollVisual, true)

-- MISC TAB
AddToggle("FPS Otimizador", "Optimizer", ScrollMisc, setOptimizer)
AddToggle("Watermark (FPS/Ping)", "Watermark", ScrollMisc)
AddToggle("Notifications", "Notify", ScrollMisc)
AddButton("Unload Script", function() Unload() end, ScrollMisc)

-- ── UNLOAD (single cleanup path) ────────────────────────────
Unload = function()
    alive = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for d in pairs(drawSet) do pcall(function() d:Remove() end) end
    S.Optimizer = false; setOptimizer(false)
    if spinCleanup then pcall(spinCleanup) end
    TixUI:Destroy()
    env.__REDZ_UNLOAD = nil
end
env.__REDZ_UNLOAD = Unload

-- ── WIRING ──────────────────────────────────────────────────
track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Camera = workspace.CurrentCamera end))
track(Players.PlayerRemoving:Connect(function(p)
    local e = ESP[p]
    if e then
        for _, d in ipairs(e.all) do drawSet[d] = nil; pcall(function() d:Remove() end) end
        ESP[p] = nil
    end
    if lockPlayer == p then lockPlayer = nil end
end))
track(LocalPlayer.CharacterAdded:Connect(function(c) isSpinning = false; hookJump(c) end))
if LocalPlayer.Character then task.spawn(hookJump, LocalPlayer.Character) end

track(UIS.InputBegan:Connect(function(i, gp)
    if gp or S.AimMode ~= "Toggle" then return end
    local k = KeyMap[S.AimKey]
    if i.KeyCode == k or i.UserInputType == k then
        aimToggled = not aimToggled
        Notify("Aim " .. (aimToggled and "LOCKED" or "OFF"))
    end
end))

local fps, wmT = 60, 0
track(RunService.RenderStepped:Connect(function(dt)
    if not alive then return end
    local now, vp = tick(), Camera.ViewportSize
    local org = S.FOVOrigin == "Mouse" and UIS:GetMouseLocation() or vp / 2
    Circle.Position, Circle.Radius, Circle.Visible = org, S.FOV, S.CircleVis

    WM.Visible = S.Watermark
    fps = fps * 0.9 + (1 / math.max(dt, 1e-4)) * 0.1
    if S.Watermark and now - wmT > 0.5 then
        wmT = now
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        WM.Text = "REDZ | " .. math.floor(fps) .. " FPS | " .. (ok and math.floor(ping) .. "ms" or "--")
    end

    local want = S.Sticky and (S.AimMode == "Always" or (S.AimMode == "Hold" and keyHeld(KeyMap[S.AimKey])) or (S.AimMode == "Toggle" and aimToggled))
    if want then
        local part = getTarget(org)
        if part then
            -- frame-rate independent lerp (same feel as the old per-frame factor at 60 FPS)
            local f60 = 1 / (1 + (S.Smoothness - 1) * 0.12)
            local f = f60 >= 1 and 1 or 1 - (1 - f60) ^ (dt * 60)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPos(part)), f)
        end
    else lockPlayer = nil end

    if S.Triggerbot then triggerStep() end
    updateESP(now, vp)
end))

Notify("REDZ XITER loaded")
