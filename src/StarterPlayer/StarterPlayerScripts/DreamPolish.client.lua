-- DREAM LAYERS - Màn mở đầu, mục tiêu gọn, nút kỹ năng, việc cô nhờ, ký ức Dấu Hiệu, màn thắng/thua, âm thanh
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer
local State = RS:WaitForChild("GameState")
local Remotes = RS:WaitForChild("Remotes")
local Sounds = RS:WaitForChild("DreamSounds")
local map = workspace:WaitForChild("DreamMap")

local gui = Instance.new("ScreenGui") gui.Name = "DreamPolish" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 5
gui.Parent = plr:WaitForChild("PlayerGui")

local function txt(parent, pos, size, text, ts, font)
	local t = Instance.new("TextLabel", parent) t.Position = pos t.Size = size t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = Color3.fromRGB(235, 228, 245) t.TextStrokeTransparency = 0.5 t.Font = font or Enum.Font.GothamMedium t.TextSize = ts or 16
	t.TextXAlignment = Enum.TextXAlignment.Left t.TextWrapped = true
	return t
end

-- ===== ÂM THANH =====
local amb = Sounds.Ambience:Clone() amb.Parent = gui amb:Play()
local hb = Sounds.Heartbeat:Clone() hb.Parent = gui hb:Play()

-- ===== MỤC TIÊU GỌN (góc phải) =====
local panel = Instance.new("Frame", gui) panel.AnchorPoint = Vector2.new(1, 0) panel.Position = UDim2.new(1, -12, 0, 52) panel.Size = UDim2.fromOffset(250, 78)
panel.BackgroundColor3 = Color3.fromRGB(12, 10, 18) panel.BackgroundTransparency = 0.5 panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local rSigns = txt(panel, UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 18), "", 14)
local rShards = txt(panel, UDim2.fromOffset(10, 26), UDim2.new(1, -20, 0, 18), "", 14)
local rNow = txt(panel, UDim2.fromOffset(10, 48), UDim2.new(1, -20, 0, 26), "", 13) rNow.TextColor3 = Color3.fromRGB(255, 215, 140) rNow.TextYAlignment = Enum.TextYAlignment.Top

-- ===== VIỆC CÔ NHỜ (1 dòng gọn) =====
local taskL = txt(gui, UDim2.new(0.5, -220, 0, 56), UDim2.fromOffset(440, 22), "", 15, Enum.Font.GothamBold) taskL.TextXAlignment = Enum.TextXAlignment.Center

-- ===== KÝ ỨC (khi ghi nhận Dấu Hiệu) =====
local memT = txt(gui, UDim2.new(0.5, -300, 0.62, 0), UDim2.fromOffset(600, 70), "", 18, Enum.Font.Garamond)
memT.TextXAlignment = Enum.TextXAlignment.Center memT.TextColor3 = Color3.fromRGB(220, 200, 255) memT.TextTransparency = 1 memT.TextStrokeTransparency = 1
local function flicker()
	local lights = {}
	for _, l in ipairs(map:GetDescendants()) do if l:IsA("PointLight") then table.insert(lights, {l, l.Brightness}) end end
	for i = 1, 6 do
		for _, e in ipairs(lights) do e[1].Brightness = (i % 2 == 1) and e[2] * 0.1 or e[2] end
		task.wait(0.12)
	end
	for _, e in ipairs(lights) do e[1].Brightness = e[2] end
end
Remotes.Notify.OnClientEvent:Connect(function(msg)
	if msg:sub(1, 10) ~= "__MEMORY__" then return end
	local _, name, mem = table.unpack(string.split(msg, "|"))
	task.spawn(flicker)
	memT.Text = "✧ " .. (name or "") .. " ✧\n" .. (mem or "")
	memT.TextTransparency = 0 memT.TextStrokeTransparency = 0.6
	task.delay(6, function()
		TweenService:Create(memT, TweenInfo.new(1.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)
end)

-- ===== NÚT KỸ NĂNG (dưới cùng, di chuột để xem mô tả) =====
local SKILL_CD = {Seer = 18, Healer = 30, Anchor = 40, Diviner = 30}
local SKILL = {
	Seer = {icon = "👁", name = "NHÌN XUYÊN", desc = "Thấu Thị · [Q] hoặc click\nTốn 3 Tỉnh táo · 12 giây · hồi 18s\n\nSoi bí mật của PHÒNG đang đứng. Mọi thứ bạn soi được hiện cho CẢ NHÓM thêm 15 giây.\nNơi không có luật: thấy mọi đồng đội và hiểm nguy trên tầng, lộ dòng nội quy NÓI DỐI.\n\nNội tại Mắt Đêm: trong 25 bước thấy xuyên tường hiểm nguy và đồ vật.\nV: xem lại chi tiết"},
	Healer = {icon = "♪", name = "BÀI RU", desc = "Chữa Lành · [Q] hoặc click\nTốn 5 Tỉnh táo · hồi 30s\n\nMọi người trong PHÒNG +25, Bình tâm 12s, kéo tất cả người hòa mộng dậy. 3 giây sau đó sát thương chỉ còn một nửa.\n\nNội tại Sợi Chỉ Đỏ: gánh một nửa lần phạt của đồng đội được nối.\nV: xem lại chi tiết"},
	Anchor = {icon = "⚓", name = "CẮM NEO", desc = "Người Neo · [Q] hoặc click\nTốn 8 Tỉnh táo · 5 giây · hồi 40s\n\nMọi thứ trong PHÒNG đang đứng đứng yên như lúc bấm. Neo khóa cả trạng thái xấu — chọn đúng lúc!\nCổng mở: CHỐNG CỬA +5 giây (1 lần/tầng).\n\nNội tại Chân Neo: không bao giờ bị đơ.\nV: xem lại chi tiết"},
	Diviner = {icon = "🔮", name = "GIEO QUẺ", desc = "Nhà Bói Toán · [Q] hoặc click\nTốn 5 Tỉnh táo · hồi 30s\n\nRút lá quẻ báo SỰ KIỆN KẾ TIẾP của phòng đang đứng.\n\nNội tại Điềm Báo: viền màn hình rung ~3 giây trước khi phòng đang đứng đổi trạng thái (tối đa 1 lần/60 giây).\nV: xem lại chi tiết"},
}
local btn = Instance.new("TextButton", gui) btn.AnchorPoint = Vector2.new(0.5, 1) btn.Position = UDim2.new(0.5, -300, 1, -14) btn.Size = UDim2.fromOffset(64, 64)
btn.BackgroundColor3 = Color3.fromRGB(35, 28, 55) btn.Text = "" btn.AutoButtonColor = true
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
local bs = Instance.new("UIStroke", btn) bs.Thickness = 2 bs.Color = Color3.fromRGB(180, 150, 255)
local icon = txt(btn, UDim2.new(), UDim2.fromScale(1, 1), "", 30, Enum.Font.GothamBold) icon.TextXAlignment = Enum.TextXAlignment.Center
local keyL = txt(btn, UDim2.new(0, 4, 0, 2), UDim2.fromOffset(20, 14), "Q", 12, Enum.Font.GothamBold)
local cdOverlay = Instance.new("Frame", btn) cdOverlay.BackgroundColor3 = Color3.new(0, 0, 0) cdOverlay.BackgroundTransparency = 0.35 cdOverlay.BorderSizePixel = 0 cdOverlay.AnchorPoint = Vector2.new(0, 1) cdOverlay.Position = UDim2.fromScale(0, 1) cdOverlay.ZIndex = 2
Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(0, 12)
local cdL = txt(btn, UDim2.new(), UDim2.fromScale(1, 1), "", 20, Enum.Font.GothamBold) cdL.TextXAlignment = Enum.TextXAlignment.Center cdL.ZIndex = 3
local nameL = txt(btn, UDim2.new(0, -20, 1, 2), UDim2.new(1, 40, 0, 14), "", 11, Enum.Font.GothamBold) nameL.TextXAlignment = Enum.TextXAlignment.Center
local tip = Instance.new("Frame", gui) tip.AnchorPoint = Vector2.new(0.5, 1) tip.Position = UDim2.new(0.5, -300, 1, -92) tip.Size = UDim2.fromOffset(320, 235)
tip.BackgroundColor3 = Color3.fromRGB(15, 12, 24) tip.BackgroundTransparency = 0.1 tip.Visible = false
Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 8)
local ts = Instance.new("UIStroke", tip) ts.Color = Color3.fromRGB(180, 150, 255) ts.Transparency = 0.4
local tipT = txt(tip, UDim2.fromOffset(10, 8), UDim2.new(1, -20, 1, -16), "", 13) tipT.TextYAlignment = Enum.TextYAlignment.Top tipT.RichText = true
btn.MouseEnter:Connect(function() tip.Visible = true end)
btn.MouseLeave:Connect(function() tip.Visible = false end)
local btnScale = Instance.new("UIScale", btn)
local readyL = txt(gui, UDim2.new(0.5, -360, 1, -110), UDim2.fromOffset(120, 20), "", 14, Enum.Font.GothamBlack) readyL.TextXAlignment = Enum.TextXAlignment.Center readyL.TextColor3 = Color3.fromRGB(200, 180, 255)
local wasReady = true
local function pulse(color)
	btnScale.Scale = 1.25
	TweenService:Create(btnScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	bs.Thickness = 5 bs.Color = color
	TweenService:Create(bs, TweenInfo.new(0.6), {Thickness = 2}):Play()
end
plr:GetAttributeChangedSignal("SkillReadyAt"):Connect(function()
	-- vừa dùng kỹ năng: nút chớp sáng + vòng sóng
	if (plr:GetAttribute("SkillReadyAt") or 0) <= workspace:GetServerTimeNow() then return end
	pulse(Color3.fromRGB(255, 255, 255))
	local ring = Instance.new("Frame", gui) ring.AnchorPoint = Vector2.new(0.5, 0.5) ring.Position = UDim2.new(0.5, -300, 1, -46) ring.Size = UDim2.fromOffset(64, 64) ring.BackgroundTransparency = 1
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
	local rs = Instance.new("UIStroke", ring) rs.Thickness = 4 rs.Color = Color3.fromRGB(200, 170, 255)
	TweenService:Create(ring, TweenInfo.new(0.5), {Size = UDim2.fromOffset(150, 150)}):Play()
	TweenService:Create(rs, TweenInfo.new(0.5), {Transparency = 1}):Play()
	task.delay(0.55, function() ring:Destroy() end)
	wasReady = false
end)
RunService.Heartbeat:Connect(function()
	local ready = (plr:GetAttribute("SkillReadyAt") or 0) <= workspace:GetServerTimeNow()
	if ready and not wasReady then
		wasReady = true
		pulse(Color3.fromRGB(255, 230, 120))
		readyL.Text = "SẴN SÀNG!" readyL.TextTransparency = 0
		TweenService:Create(readyL, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -360, 1, -122)}):Play()
		task.delay(1.2, function()
			TweenService:Create(readyL, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			task.wait(0.5) readyL.Position = UDim2.new(0.5, -360, 1, -110)
		end)
	end
end)
btn.MouseButton1Click:Connect(function() Remotes.UseSkill:FireServer("Skill") end)

-- ===== HIỆU ỨNG MẤT / HỒI TỈNH TÁO =====
local flash = Instance.new("Frame", gui) flash.Size = UDim2.fromScale(1, 1) flash.BorderSizePixel = 0 flash.BackgroundTransparency = 1 flash.ZIndex = 1
local fg = Instance.new("UIGradient", flash) -- viền đậm, giữa trong
fg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 0.85), NumberSequenceKeypoint.new(0.75, 0.85), NumberSequenceKeypoint.new(1, 0)})
local flash2 = flash:Clone() flash2.Parent = gui flash2.UIGradient.Rotation = 90
local cam = workspace.CurrentCamera
local function popNumber(delta)
	local pos = UDim2.new(0, 170 + math.random(-30, 30), 1, -150)
	local t = txt(gui, pos, UDim2.fromOffset(120, 34), (delta > 0 and "+" or "−") .. math.floor(math.abs(delta) + 0.5), 28, Enum.Font.GothamBlack)
	t.TextXAlignment = Enum.TextXAlignment.Center t.TextStrokeTransparency = 0.2
	t.TextColor3 = delta > 0 and Color3.fromRGB(120, 255, 170) or Color3.fromRGB(255, 70, 90)
	local sc = Instance.new("UIScale", t) sc.Scale = 1.6
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	TweenService:Create(t, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = pos - UDim2.fromOffset(0, 70), TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	task.delay(1.3, function() t:Destroy() end)
end
local function screenFlash(color, strength)
	for _, f in ipairs({flash, flash2}) do
		f.BackgroundColor3 = color f.BackgroundTransparency = 1 - strength
		TweenService:Create(f, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
	end
end
local function shake(power)
	task.spawn(function()
		for i = 1, 8 do
			local k = power * (1 - i / 8)
			cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(math.random(-10, 10) / 10 * k), math.rad(math.random(-10, 10) / 10 * k), 0)
			RunService.RenderStepped:Wait()
		end
	end)
end
local lastSan = plr:GetAttribute("Sanity")
plr:GetAttributeChangedSignal("Sanity"):Connect(function()
	local s = plr:GetAttribute("Sanity")
	if lastSan and s then
		local delta = s - lastSan
		if delta <= -3 then
			popNumber(delta) screenFlash(Color3.fromRGB(200, 0, 30), math.clamp(-delta / 25, 0.25, 0.7)) shake(math.clamp(-delta / 6, 1, 4))
		elseif delta >= 3 then
			popNumber(delta) screenFlash(Color3.fromRGB(40, 255, 140), 0.3)
		end
	end
	lastSan = s
end)
plr:GetAttributeChangedSignal("Dreaming"):Connect(function() lastSan = plr:GetAttribute("Sanity") end)

-- ===== MINIGAME ĐIỆU NHẢY CON RỐI =====
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local dance = Instance.new("Frame", gui) dance.AnchorPoint = Vector2.new(0.5, 0.5) dance.Position = UDim2.fromScale(0.5, 0.55) dance.Size = UDim2.fromOffset(420, 190)
dance.BackgroundColor3 = Color3.fromRGB(40, 8, 18) dance.BackgroundTransparency = 0.15 dance.Visible = false dance.ZIndex = 10
Instance.new("UICorner", dance).CornerRadius = UDim.new(0, 14)
local dst = Instance.new("UIStroke", dance) dst.Color = Color3.fromRGB(255, 120, 150) dst.Thickness = 2
local dTitle = txt(dance, UDim2.fromOffset(0, 8), UDim2.new(1, 0, 0, 26), "♪ CON RỐI KÉO BẠN VÀO ĐIỆU NHẢY ♪", 18, Enum.Font.GothamBlack) dTitle.TextXAlignment = Enum.TextXAlignment.Center dTitle.ZIndex = 11
local dHint = txt(dance, UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 18), "Bấm đúng phím Q hoặc E theo nhịp (cần 4/5)", 13) dHint.TextXAlignment = Enum.TextXAlignment.Center dHint.ZIndex = 11
local beats = {}
for i = 1, 5 do
	local b = Instance.new("Frame", dance) b.Size = UDim2.fromOffset(62, 62) b.Position = UDim2.new(0, 22 + (i - 1) * 78, 0, 70) b.BackgroundColor3 = Color3.fromRGB(70, 30, 45) b.ZIndex = 11
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke", b) st.Color = Color3.fromRGB(150, 90, 110) st.Thickness = 2
	local l = txt(b, UDim2.new(), UDim2.fromScale(1, 1), "", 30, Enum.Font.GothamBlack) l.TextXAlignment = Enum.TextXAlignment.Center l.ZIndex = 12
	beats[i] = {f = b, l = l, st = st}
end
local timer = Instance.new("Frame", dance) timer.Position = UDim2.new(0, 22, 0, 146) timer.Size = UDim2.fromOffset(376, 8) timer.BackgroundColor3 = Color3.fromRGB(255, 200, 120) timer.BorderSizePixel = 0 timer.ZIndex = 11
local dResult = txt(dance, UDim2.fromOffset(0, 160), UDim2.new(1, 0, 0, 22), "", 16, Enum.Font.GothamBold) dResult.TextXAlignment = Enum.TextXAlignment.Center dResult.ZIndex = 11

local function runDance(seq)
	dance.Visible = true dResult.Text = "" PPS.Enabled = false
	for i = 1, 5 do beats[i].l.Text = seq:sub(i, i) beats[i].f.BackgroundColor3 = Color3.fromRGB(70, 30, 45) beats[i].st.Color = Color3.fromRGB(150, 90, 110) beats[i].l.TextTransparency = 0.6 end
	task.wait(0.8)
	local hits = 0
	for i = 1, 5 do
		local want = seq:sub(i, i) == "Q" and Enum.KeyCode.Q or Enum.KeyCode.E
		local b = beats[i]
		b.l.TextTransparency = 0 b.st.Color = Color3.fromRGB(255, 220, 120) b.st.Thickness = 4
		local window = 1.1 - i * 0.08 -- nhịp nhanh dần
		timer.Size = UDim2.fromOffset(376, 8)
		local tw = TweenService:Create(timer, TweenInfo.new(window, Enum.EasingStyle.Linear), {Size = UDim2.fromOffset(0, 8)}) tw:Play()
		local got, correct = false, false
		local conn = UIS.InputBegan:Connect(function(input, gp)
			if got then return end
			if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then got = true correct = input.KeyCode == want end
		end)
		local t0 = os.clock()
		while not got and os.clock() - t0 < window do RunService.RenderStepped:Wait() end
		conn:Disconnect() tw:Cancel()
		b.st.Thickness = 2
		if correct then hits += 1 b.f.BackgroundColor3 = Color3.fromRGB(40, 150, 90) b.st.Color = Color3.fromRGB(150, 255, 190)
		else b.f.BackgroundColor3 = Color3.fromRGB(170, 30, 50) b.st.Color = Color3.fromRGB(255, 120, 120) end
		task.wait(0.15)
	end
	dResult.Text = hits >= 4 and ("Theo kịp điệu nhảy! (" .. hits .. "/5)") or ("Lạc nhịp... (" .. hits .. "/5)")
	dResult.TextColor3 = hits >= 4 and Color3.fromRGB(150, 255, 190) or Color3.fromRGB(255, 120, 120)
	Remotes.UseSkill:FireServer("DanceResult", hits)
	task.wait(1.2)
	dance.Visible = false PPS.Enabled = true
end
Remotes.Notify.OnClientEvent:Connect(function(msg)
	if msg:sub(1, 9) == "__DANCE__" then task.spawn(runDance, msg:sub(11)) end
end)

-- ===== MÀN MỞ ĐẦU =====
local intro = Instance.new("Frame", gui) intro.Size = UDim2.fromScale(1, 1) intro.BackgroundColor3 = Color3.new(0, 0, 0) intro.ZIndex = 20
local t1 = txt(intro, UDim2.new(0, 0, 0.36, 0), UDim2.new(1, 0, 0, 60), "DREAM LAYERS", 54, Enum.Font.Antique) t1.TextXAlignment = Enum.TextXAlignment.Center t1.ZIndex = 21
local t2 = txt(intro, UDim2.new(0, 0, 0.36, 70), UDim2.new(1, 0, 0, 34), "Tầng 1 — Lớp Học Vỡ", 28, Enum.Font.Antique) t2.TextXAlignment = Enum.TextXAlignment.Center t2.ZIndex = 21 t2.TextColor3 = Color3.fromRGB(200, 170, 255)
local t3 = txt(intro, UDim2.new(0, 0, 0.36, 120), UDim2.new(1, 0, 0, 30), "\"Trước khi vào lớp, hãy đọc nội quy trên bàn ở sảnh...\"", 18, Enum.Font.Garamond) t3.TextXAlignment = Enum.TextXAlignment.Center t3.ZIndex = 21
task.delay(3.5, function()
	local ti = TweenInfo.new(2)
	TweenService:Create(intro, ti, {BackgroundTransparency = 1}):Play()
	for _, l in ipairs({t1, t2, t3}) do TweenService:Create(l, ti, {TextTransparency = 1, TextStrokeTransparency = 1}):Play() end
	task.wait(2.1) intro.Visible = false
end)

-- ===== MÀN THẮNG / THUA =====
local endF = Instance.new("Frame", gui) endF.Size = UDim2.fromScale(1, 1) endF.BackgroundColor3 = Color3.new(0, 0, 0) endF.BackgroundTransparency = 0.25 endF.Visible = false endF.ZIndex = 15
local e1 = txt(endF, UDim2.new(0, 0, 0.35, 0), UDim2.new(1, 0, 0, 60), "", 50, Enum.Font.Antique) e1.TextXAlignment = Enum.TextXAlignment.Center e1.ZIndex = 16
local e2 = txt(endF, UDim2.new(0, 0, 0.35, 70), UDim2.new(1, 0, 0, 80), "", 20, Enum.Font.Garamond) e2.TextXAlignment = Enum.TextXAlignment.Center e2.ZIndex = 16
local function onPhase()
	local ph = State:GetAttribute("Phase")
	if ph == "Win" or ph == "Lose" then
		local t = State:GetAttribute("RoundTime") or 0
		local tstr = string.format("%d:%02d", t // 60, t % 60)
		if ph == "Win" then
			e1.Text = "QUA TẦNG" e1.TextColor3 = Color3.fromRGB(160, 255, 200)
			e2.Text = "Cổng dịch chuyển đưa các em xuống tầng mộng sâu hơn...\nThời gian: " .. tstr .. "\n\n(Tầng 2 đang được xây dựng — ván mới sau vài giây)"
		else
			e1.Text = "BỊ NUỐT" e1.TextColor3 = Color3.fromRGB(255, 90, 110)
			e2.Text = "Các em đã không nghe lời cô.\nThời gian trụ được: " .. tstr .. "\n\nThử lại sau vài giây..."
		end
		endF.Visible = true
	else endF.Visible = false end
end
State:GetAttributeChangedSignal("Phase"):Connect(onPhase) onPhase()

-- ===== ĐẾM NGƯỢC THOÁT =====
local escL = txt(gui, UDim2.new(0.5, -350, 0.2, 0), UDim2.fromOffset(700, 50), "", 30, Enum.Font.GothamBlack)
escL.TextXAlignment = Enum.TextXAlignment.Center escL.TextColor3 = Color3.fromRGB(255, 80, 80) escL.TextStrokeTransparency = 0.2
local escScale = Instance.new("UIScale", escL)
local lastSec = -1
-- ===== CẬP NHẬT =====
RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	local ph = State:GetAttribute("Phase") or ""
	local signs = State:GetAttribute("Signs") or 0
	local shards = State:GetAttribute("Shards") or 0
	rSigns.Text = (signs >= 3 and "☑ " or "☐ ") .. "Dấu hiệu bất thường  " .. signs .. "/3"
	rShards.Text = (shards >= 3 and "☑ " or "☐ ") .. "Mảnh Neo Thức  " .. shards .. "/3"
	local now_obj
	if not plr:GetAttribute("HasRules") then now_obj = "→ Nhặt tờ nội quy ở sảnh"
	elseif ph == "TrinhSat" then now_obj = "→ Tìm dấu hiệu bất thường"
	elseif ph == "TruyNguyen" then now_obj = "→ Xếp Bảng Ghi Nhớ theo giờ"
	elseif ph == "ThanhTay" then now_obj = "→ Đưa cuốn sổ đến đèn bàn cô"
	elseif ph == "Neo" then now_obj = shards < 3 and "→ Tìm Mảnh Neo" or "→ Đặt Mảnh Neo vào Bệ Neo"
	elseif ph == "Gate" then now_obj = plr:GetAttribute("Escaped") and "→ Đã qua Cổng, chờ đồng đội" or "→ Về SẢNH, bước vào Cổng!"
	else now_obj = "" end
	rNow.Text = now_obj
	local L2 = plr:GetAttribute("Level") == 2
	panel.Visible = not L2
	if ph == "Gate" and not plr:GetAttribute("Escaped") and plr:GetAttribute("Level") ~= 2 then
		local left = math.ceil((State:GetAttribute("EscapeDeadline") or 0) - now)
		if left > 0 then
			escL.Text = "⚠ CỬA ĐÓNG SAU " .. left .. "s — CHẠY VỀ SẢNH! ⚠"
			escL.TextColor3 = Color3.fromRGB(255, 80, 80)
			if left ~= lastSec then lastSec = left escScale.Scale = 1.3 TweenService:Create(escScale, TweenInfo.new(0.3), {Scale = 1}):Play() end
		else
			escL.Text = "Mọi cánh cửa đã đóng — bước vào CỔNG!" escL.TextColor3 = Color3.fromRGB(160, 255, 210) escScale.Scale = 0.8
		end
	else escL.Text = "" end
	-- việc cô nhờ
	local tt = State:GetAttribute("TaskText") or ""
	if tt ~= "" and plr:GetAttribute("Level") ~= 2 then
		local left = math.max(0, math.ceil((State:GetAttribute("TaskDeadline") or 0) - now))
		taskL.Text = "📝 " .. tt .. "  ·  " .. left .. "s"
		taskL.TextColor3 = left <= 10 and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 200, 130)
	else taskL.Text = "" end
	-- nút kỹ năng
	local role = plr:GetAttribute("Role")
	local sk = SKILL[role]
	btn.Visible = sk ~= nil
	if sk then
		icon.Text = sk.icon nameL.Text = sk.name tipT.Text = "<b>" .. sk.name .. "</b>\n" .. sk.desc
		local cd = (plr:GetAttribute("SkillReadyAt") or 0) - now
		local cdMax = SKILL_CD[role] or 30
		local inClass = true -- dùng được ở mọi phòng
		if cd > 0 then
			cdOverlay.Visible = true cdOverlay.Size = UDim2.fromScale(1, math.clamp(cd / cdMax, 0, 1)) cdL.Text = tostring(math.ceil(cd))
		else cdOverlay.Visible = false cdL.Text = "" end
		btn.BackgroundColor3 = inClass and Color3.fromRGB(35, 28, 55) or Color3.fromRGB(30, 30, 30)
		bs.Color = inClass and Color3.fromRGB(180, 150, 255) or Color3.fromRGB(90, 90, 90)
		icon.TextTransparency = inClass and 0 or 0.6
	end
	-- nhịp tim
	local s = plr:GetAttribute("Sanity") or 100
	local k = plr:GetAttribute("Dreaming") and 0 or math.clamp((50 - s) / 50, 0, 1)
	hb.Volume = k * 1.2 hb.PlaybackSpeed = 1 + k * 0.5
	amb.Volume = plr:GetAttribute("Dreaming") and 0.15 or 0.35
end)

-- ===== DẤU HIỆU DỄ NHẬN RA (12+): viền sáng nhấp nháy khi dấu hiệu đang xuất hiện, không xuyên tường =====
do
	local IX1 = map:WaitForChild("Interactables")
	local SIGNS = {Board = IX1:WaitForChild("Blackboard"), Voice = IX1:WaitForChild("Sign_Voice"), Shadow = IX1:WaitForChild("Sign_Shadow")}
	local hl = {}
	for k, inst in pairs(SIGNS) do
		local h = Instance.new("Highlight") h.Adornee = inst h.FillColor = Color3.fromRGB(200, 170, 255) h.OutlineColor = Color3.fromRGB(235, 220, 255)
		h.DepthMode = Enum.HighlightDepthMode.Occluded h.Enabled = false h.Parent = gui hl[k] = h
	end
	RunService.RenderStepped:Connect(function()
		local k2 = (math.sin(os.clock() * 3) + 1) / 2
		for k, h in pairs(hl) do
			local live = plr:GetAttribute("Level") ~= 2 and State:GetAttribute("SignLive_" .. k) == true and not State:GetAttribute("Sign_" .. k)
			h.Enabled = live
			if live then h.FillTransparency = 0.75 + 0.15 * k2 h.OutlineTransparency = 0.1 + 0.5 * k2 end
		end
	end)
end

-- ===== TIẾT HỌC + ĐIỂM DANH (HUD) =====
local periodL = txt(gui, UDim2.new(1, -262, 0, 134), UDim2.fromOffset(250, 18), "", 13, Enum.Font.GothamBold)
periodL.TextXAlignment = Enum.TextXAlignment.Right periodL.TextColor3 = Color3.fromRGB(210, 200, 230)
local rollL = txt(gui, UDim2.new(0.5, -300, 0, 82), UDim2.fromOffset(600, 30), "", 20, Enum.Font.GothamBlack)
rollL.TextXAlignment = Enum.TextXAlignment.Center rollL.TextStrokeTransparency = 0.2
-- ĐIỂM DANH: loa trường + băng rôn lớn cho CẢ NHÓM, dù đang ở phòng nào
local rollBig = txt(gui, UDim2.new(0.5, -360, 0.3, 0), UDim2.fromOffset(720, 70), "", 34, Enum.Font.GothamBlack)
rollBig.TextXAlignment = Enum.TextXAlignment.Center rollBig.TextColor3 = Color3.fromRGB(255, 215, 150) rollBig.TextTransparency = 1 rollBig.TextStrokeTransparency = 1
local pa = Instance.new("Sound") pa.SoundId = "rbxassetid://134681576227406" pa.Volume = 0.7 pa.Parent = gui
local lastRoll = ""
State:GetAttributeChangedSignal("RollName"):Connect(function()
	local rn = State:GetAttribute("RollName") or ""
	local ph0 = State:GetAttribute("Phase") or ""
	if rn == "" or rn == lastRoll or plr:GetAttribute("Level") == 2 or not (ph0 == "TrinhSat" or ph0 == "TruyNguyen" or ph0 == "ThanhTay" or ph0 == "Neo") then lastRoll = rn return end
	lastRoll = rn
	pcall(function() pa.TimePosition = 0 pa:Play() end)
	rollBig.Text = rn == plr.DisplayName and "📢 CÔ GỌI TÊN BẠN!" or ("📢 CÔ ĐIỂM DANH: " .. string.upper(rn))
	rollBig.TextTransparency = 0 rollBig.TextStrokeTransparency = 0.2
	local sc = rollBig:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", rollBig) sc.Scale = 1.4
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()
	task.delay(3, function() if lastRoll == rn then TweenService:Create(rollBig, TweenInfo.new(0.8), {TextTransparency = 1, TextStrokeTransparency = 1}):Play() end end)
end)
local PLAYING = {TrinhSat = true, TruyNguyen = true, ThanhTay = true, Neo = true}
RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	local ph = State:GetAttribute("Phase") or ""
	local on = plr:GetAttribute("Level") ~= 2 and PLAYING[ph] == true
	local pn = State:GetAttribute("Period") or 0
	if on and pn > 0 then
		local ends = State:GetAttribute("PeriodEndsAt") or 0
		if pn >= 3 then periodL.Text = "TIẾT CUỐI" periodL.TextColor3 = Color3.fromRGB(255, 110, 110)
		else
			local left = math.max(0, math.floor(ends - now))
			periodL.Text = string.format("TIẾT %d/3 · chuông sau %d:%02d", pn, left // 60, left % 60)
			periodL.TextColor3 = pn == 2 and Color3.fromRGB(255, 190, 140) or Color3.fromRGB(210, 200, 230)
		end
	else periodL.Text = "" end
	local rn = State:GetAttribute("RollName") or ""
	if on and rn ~= "" then
		local left = math.max(0, math.ceil((State:GetAttribute("RollDeadline") or 0) - now))
		if rn == plr.DisplayName then
			rollL.Text = "📋 CÔ GỌI TÊN BẠN — về một chiếc bàn, bấm E “Có ạ” · " .. left .. "s"
			rollL.TextColor3 = Color3.fromRGB(255, 120, 90)
		else
			rollL.Text = "📋 Điểm danh: " .. rn .. " · " .. left .. "s"
			rollL.TextColor3 = Color3.fromRGB(255, 215, 150)
		end
	else rollL.Text = "" end
end)
-- Tiết cuối: học sinh-bóng ngồi kín các bàn trống, quay đầu nhìn theo bạn (chỉ phía client)
task.spawn(function()
	local ghosts = {}
	local function clear() for _, g in ipairs(ghosts) do g.m:Destroy() end ghosts = {} end
	local function spawnGhosts()
		local desks = {}
		for _, d in ipairs(map.Props:GetChildren()) do if d.Name == "Desk" and d:FindFirstChild("Top") then table.insert(desks, d.Top) end end
		for i = #desks, 2, -1 do local j = math.random(i) desks[i], desks[j] = desks[j], desks[i] end
		for i = 1, math.min(6, #desks) do
			local top = desks[i]
			local m = Instance.new("Model") m.Name = "ShadowStudent"
			local function part(size, shape)
				local p = Instance.new("Part") p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
				p.Size = size p.Color = Color3.fromRGB(8, 6, 12) p.Material = Enum.Material.SmoothPlastic p.Transparency = 1
				if shape then p.Shape = shape end p.Parent = m return p
			end
			local body = part(Vector3.new(1.5, 1.7, 1))
			local head = part(Vector3.new(1.3, 1.3, 1.3), Enum.PartType.Ball)
			local base = top.Position + Vector3.new(0, 0.4, 0) + (top.CFrame.LookVector * -2.2)
			m.Parent = workspace
			table.insert(ghosts, {m = m, body = body, head = head, base = base})
		end
	end
	while true do
		task.wait(0.05)
		local ph = State:GetAttribute("Phase") or ""
		local want = plr:GetAttribute("Level") ~= 2 and (State:GetAttribute("Period") or 0) >= 3 and PLAYING[ph] == true
		if want and #ghosts == 0 then spawnGhosts() elseif not want and #ghosts > 0 then clear() end
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		for _, g in ipairs(ghosts) do
			local look = root and Vector3.new(root.Position.X, g.base.Y, root.Position.Z) or (g.base + Vector3.new(0, 0, 1))
			local cf = CFrame.lookAt(g.base, look)
			g.body.CFrame = cf
			g.head.CFrame = cf * CFrame.new(0, 1.45, 0)
			local tr = 0.2 + 0.12 * math.sin(os.clock() * 2 + g.base.X)
			g.body.Transparency = tr g.head.Transparency = tr
		end
	end
end)

-- ===== ĐÈN NHẤP NHÁY TẦNG 1 & ĐÈN KHẨN CẤP =====
task.spawn(function()
	local flick, pulse = {}, {}
	for _, p in ipairs(map:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("Flicker") then table.insert(flick, p) end
		if p:IsA("BasePart") and p:GetAttribute("Pulse") then table.insert(pulse, p) end
	end
	local function setOn(p, on) for _, l in ipairs(p:GetChildren()) do if l:IsA("Light") then l.Enabled = on end end p.Transparency = on and 0 or 0.6 end
	task.spawn(function()
		while true do
			task.wait(math.random(3, 8) / (((State:GetAttribute("Period") or 1) >= 3) and 25 or 10)) -- tiết cuối: đèn chập chờn dữ hơn
			local p = #flick > 0 and flick[math.random(#flick)]
			if p and plr:GetAttribute("Level") ~= 2 then
				for i = 1, math.random(2, 5) do setOn(p, false) task.wait(math.random(3, 12) / 100) setOn(p, true) task.wait(math.random(3, 15) / 100) end
			end
		end
	end)
	local t = 0
	while true do
		t += task.wait(0.05)
		local k = (math.sin(t * 2.2) + 1) / 2
		for _, p in ipairs(pulse) do
			local l = p:FindFirstChildOfClass("PointLight") if l then l.Brightness = 0.15 + k * 0.8 end
			p.Color = Color3.fromRGB(80 + 150 * k, 15, 15)
		end
	end
end)

-- ===== HỒN MA DẤU HIỆU: chỉ hiện mặt/ánh sáng khi dấu hiệu đang lộ =====
task.spawn(function()
	local ghosts = {}
	for _, p in ipairs(map:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("Ghost") then table.insert(ghosts, p) end end
	local hls = {}
	for i, g in ipairs(ghosts) do
		local h = Instance.new("Highlight") h.Adornee = g h.FillColor = Color3.fromRGB(200, 220, 255) h.FillTransparency = 0.55
		h.OutlineColor = Color3.fromRGB(230, 240, 255) h.OutlineTransparency = 0.2 h.DepthMode = Enum.HighlightDepthMode.Occluded h.Parent = gui hls[i] = h
	end
	local t = 0
	while true do
		t += task.wait(0.05)
		for i, g in ipairs(ghosts) do
			local vis = g.Transparency < 0.99
			local fg = g:FindFirstChild("FaceGui") if fg then fg.Enabled = vis end
			local gl = g:FindFirstChild("GhostGlow") if gl then gl.Enabled = vis gl.Brightness = 1 + math.sin(t * 3 + i) * 0.4 end
			hls[i].Enabled = vis
			if vis then g.Transparency = 0.15 + (math.sin(t * 2.5 + i) + 1) * 0.12 end
		end
	end
end)
