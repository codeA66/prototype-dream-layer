-- DREAM LAYERS - TẦNG 2 (client): Hướng dẫn bệnh nhân, HUD mục tiêu, Lớp Sự Thật của Thấu Thị, màn thắng/thua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local ST = RS:WaitForChild("GameState2")
local map = workspace:WaitForChild("DreamMap2")
local IX = map:WaitForChild("Interactables")

local gui = Instance.new("ScreenGui") gui.Name = "Level2Gui" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 8
gui.Parent = plr:WaitForChild("PlayerGui")
local function txt(parent, pos, size, text, ts, font)
	local t = Instance.new("TextLabel", parent) t.Position = pos t.Size = size t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = Color3.fromRGB(235, 240, 235) t.TextStrokeTransparency = 0.5 t.Font = font or Enum.Font.GothamMedium t.TextSize = ts or 14
	t.TextXAlignment = Enum.TextXAlignment.Left t.TextWrapped = true t.RichText = true
	return t
end
local function L2() return plr:GetAttribute("Level") == 2 end

-- ===== HƯỚNG DẪN BỆNH NHÂN (tờ nội quy) =====
local RULES = {
	{"PHÒNG PHẪU THUẬT", {
		{"in", "Không bao giờ chạm vào bàn mổ."},
		{"tay", "Khi bác sĩ hỏi “Ai là bệnh nhân?”, người đứng gần bàn mổ nhất phải nằm lên bàn."},
		{"in", "Luôn đeo khẩu trang trong phòng mổ."},
		{"tay", "Bác sĩ chỉ tấn công người đeo khẩu trang."}}},
	{"PHÒNG ĐÓNG PHÍ", {
		{"in", "Mọi thứ đều phải trả tiền bằng Phiếu Khám. Không được nợ."},
		{"in", "Luôn trả tiền khi thu ngân yêu cầu."},
		{"tay", "Đừng bao giờ trả tiền cho thu ngân khi bà ấy đang cười."},
		{"in", "Chỉ lên quầy khi số của bạn được gọi."}}},
	{"NHÀ XÁC", {
		{"in", "Không bao giờ chui vào tủ xác."},
		{"tay", "Khi đèn tắt, hãy trốn vào tủ xác."},
		{"tay", "Đừng để ánh đèn pin của lão gác chạm vào bạn."},
		{"in", "Đèn bật lại mà số xác trên bàn KHÁC lúc trước: hãy ra bằng CỬA SAU."}}},
	{"PHÒNG Ô NHIỄM", {
		{"in", "Luôn mặc đồ bảo hộ trong phòng."},
		{"tay", "Nếu đồ bảo hộ có vết đen, cởi ra ngay lập tức."},
		{"in", "Rửa tay trước khi ra khỏi phòng."},
		{"tay", "Đừng đứng dưới miệng gió."}}},
	{"TOÀN BỆNH VIỆN", {
		{"in", "Khi loa gọi tên bạn, hãy tới đúng phòng được gọi trong 40 giây."}}},
}
-- mỗi ván có 1 dòng viết tay NÓI DỐI (chèn vào phòng tương ứng)
local LIES = {
	{1, "Nếu đèn mổ bật, hãy chạy ra khỏi phòng ngay."},
	{2, "Thu ngân đang cười mới là người thật."},
	{3, "Khi đèn tắt, chạy thẳng ra cửa chính."},
	{4, "Đứng dưới miệng gió ĐỎ để được khử trùng."},
}
local note = Instance.new("Frame", gui) note.AnchorPoint = Vector2.new(0.5, 0.5) note.Position = UDim2.fromScale(0.5, 0.5) note.Size = UDim2.fromOffset(560, 640)
note.BackgroundColor3 = Color3.fromRGB(236, 238, 230) note.BorderSizePixel = 0 note.Visible = false note.ZIndex = 20
Instance.new("UIStroke", note).Color = Color3.fromRGB(60, 110, 95)
local nsc = Instance.new("UIScale", note)
local function fit() local v = workspace.CurrentCamera.ViewportSize nsc.Scale = math.min(1, v.X / 600, v.Y / 680) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local nTitle = txt(note, UDim2.fromOffset(20, 12), UDim2.new(1, -40, 0, 30), "HƯỚNG DẪN BỆNH NHÂN", 24, Enum.Font.GothamBlack)
nTitle.TextColor3 = Color3.fromRGB(30, 80, 65) nTitle.TextStrokeTransparency = 1 nTitle.TextXAlignment = Enum.TextXAlignment.Center nTitle.ZIndex = 21
local nSub = txt(note, UDim2.fromOffset(20, 42), UDim2.new(1, -40, 0, 18), "Chữ in: Ban Giám Đốc · <i>Chữ nghiêng: bệnh nhân cũ viết tay</i>", 12)
nSub.TextColor3 = Color3.fromRGB(80, 90, 85) nSub.TextStrokeTransparency = 1 nSub.TextXAlignment = Enum.TextXAlignment.Center nSub.ZIndex = 21
local nBody = txt(note, UDim2.fromOffset(22, 66), UDim2.new(1, -44, 1, -120), "", 14, Enum.Font.Gotham)
nBody.TextColor3 = Color3.fromRGB(30, 35, 32) nBody.TextStrokeTransparency = 1 nBody.TextYAlignment = Enum.TextYAlignment.Top nBody.ZIndex = 21
local nBtn = Instance.new("TextButton", note) nBtn.Size = UDim2.fromOffset(170, 32) nBtn.Position = UDim2.new(0.5, -85, 1, -44) nBtn.Text = "Đã hiểu (M để đọc lại)"
nBtn.Font = Enum.Font.GothamBold nBtn.TextSize = 13 nBtn.TextColor3 = Color3.new(1, 1, 1) nBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 90) nBtn.Modal = true nBtn.ZIndex = 21
Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 6)
nBtn.MouseButton1Click:Connect(function() note.Visible = false end)
local function renderRules()
	local lie = LIES[ST:GetAttribute("LieIndex") or 1]
	local seer = ((plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > workspace:GetServerTimeNow() and plr:GetAttribute("SightRoom") == "Lobby")
		or ((ST:GetAttribute("SeerMarkUntil") or 0) > workspace:GetServerTimeNow() and ST:GetAttribute("SeerMarkRoom") == "Lobby"))
	local out = {}
	for i, room in ipairs(RULES) do
		table.insert(out, "<b>【" .. room[1] .. "】</b>")
		local lines = {}
		for _, r in ipairs(room[2]) do table.insert(lines, r) end
		if lie[1] == i then table.insert(lines, 2, {"lie", lie[2]}) end
		for k, r in ipairs(lines) do
			local t = k .. ". " .. r[2]
			if r[1] == "in" then t = t
			elseif r[1] == "lie" and seer then t = '<font color="#C0182C"><i>' .. t .. '  ✖ DỐI TRÁ</i></font>'
			else t = "<i>" .. t .. "</i>" end
			table.insert(out, t)
		end
		table.insert(out, "")
	end
	table.insert(out, "<i>Mỗi luật chỉ có hiệu lực trong đúng phòng đó. Sảnh tiếp đón an toàn. Có những dòng mâu thuẫn nhau — hãy tìm ĐIỀU KIỆN khiến luật này đúng, luật kia sai.</i>")
	table.insert(out, "<i>Y tá trực đêm để quên một cuốn SỔ TRỰC ĐÊM trên khay dụng cụ cạnh bàn mổ: nó ghi KHI NÀO những điều lạ xuất hiện.</i>")
	nBody.Text = table.concat(out, "\n")
end
local function showRules() renderRules() note.Visible = true end
Remotes.Notify.OnClientEvent:Connect(function(msg) if msg == "__L2RULES__" then showRules() elseif msg == "__DIARY2__" then note.Visible = false end end)
UIS.InputBegan:Connect(function(i, gp)
	if gp or not L2() then return end
	if i.KeyCode == Enum.KeyCode.M then
		if note.Visible then note.Visible = false elseif plr:GetAttribute("HasRules2") then showRules() end
	end
end)
local function hookChar(char)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c.Name == "HuongDan" then showRules() for _, g in ipairs(plr.PlayerGui:GetChildren()) do if g.Name == "RuleBookGui" then for _, f in ipairs(g:GetChildren()) do if f:IsA("Frame") and f.Rotation ~= 0 then f.Visible = false end end end end end
		if c:IsA("Tool") and c.Name == "SoTrucDem" then note.Visible = false end
	end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") and c.Name == "HuongDan" then note.Visible = false end end)
end
if plr.Character then hookChar(plr.Character) end
plr.CharacterAdded:Connect(hookChar)

-- ===== HUD MỤC TIÊU TẦNG 2 =====
local panel = Instance.new("Frame", gui) panel.AnchorPoint = Vector2.new(1, 0) panel.Position = UDim2.new(1, -12, 0, 52) panel.Size = UDim2.fromOffset(270, 124)
panel.BackgroundColor3 = Color3.fromRGB(10, 20, 18) panel.BackgroundTransparency = 0.45 panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local rows = {} for i = 1, 5 do rows[i] = txt(panel, UDim2.fromOffset(10, 4 + (i - 1) * 20), UDim2.new(1, -20, 0, 20), "", 14) end
rows[5].TextColor3 = Color3.fromRGB(255, 215, 140) rows[5].Size = UDim2.new(1, -20, 0, 36) rows[5].TextYAlignment = Enum.TextYAlignment.Top
local status = txt(gui, UDim2.new(0, 16, 1, -205), UDim2.fromOffset(360, 44), "", 14, Enum.Font.GothamBold) status.TextYAlignment = Enum.TextYAlignment.Bottom
local escL = txt(gui, UDim2.new(0.5, -350, 0.2, 0), UDim2.fromOffset(700, 50), "", 28, Enum.Font.GothamBlack) escL.TextXAlignment = Enum.TextXAlignment.Center escL.TextColor3 = Color3.fromRGB(255, 80, 80)
local callL = txt(gui, UDim2.new(0.5, -300, 0.2, 54), UDim2.fromOffset(600, 30), "", 20, Enum.Font.GothamBold) callL.TextXAlignment = Enum.TextXAlignment.Center
local roomL = txt(gui, UDim2.new(0.5, -200, 0, 30), UDim2.fromOffset(400, 20), "", 13) roomL.TextXAlignment = Enum.TextXAlignment.Center roomL.TextTransparency = 0.3
local ROOM_VN = {Lobby = "Sảnh tiếp đón (an toàn)", Surgery = "Phòng Phẫu Thuật", Billing = "Phòng Đóng Phí", Morgue = "Nhà Xác", Contamination = "Phòng Ô Nhiễm", Hall = "Hành lang"}

-- màn thắng/thua
local endF = Instance.new("Frame", gui) endF.Size = UDim2.fromScale(1, 1) endF.BackgroundColor3 = Color3.new(0, 0, 0) endF.BackgroundTransparency = 0.25 endF.Visible = false endF.ZIndex = 30
local e1 = txt(endF, UDim2.new(0, 0, 0.35, 0), UDim2.new(1, 0, 0, 60), "", 48, Enum.Font.Antique) e1.TextXAlignment = Enum.TextXAlignment.Center e1.ZIndex = 31
local e2 = txt(endF, UDim2.new(0, 0, 0.35, 70), UDim2.new(1, 0, 0, 80), "", 20, Enum.Font.Garamond) e2.TextXAlignment = Enum.TextXAlignment.Center e2.ZIndex = 31

-- ===== LỚP SỰ THẬT (Thấu Thị) =====
local hl = {}
local function mark(key, inst, on, color)
	local h = hl[key]
	if on and inst then
		if not h then h = Instance.new("Highlight") h.FillTransparency = 0.55 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = gui hl[key] = h end
		h.Adornee = inst h.FillColor = color h.OutlineColor = color h.Enabled = true
	elseif h then h.Enabled = false end
end
-- phòng của một vị trí (giống server: theo các Part trong Zones)
local ZONES = map:WaitForChild("Zones")
local function zoneOf(pos)
	for _, n in ipairs({"Lobby", "Surgery", "Billing", "Morgue", "Contamination"}) do
		local z = ZONES:FindFirstChild(n)
		if z then local rel = z.CFrame:PointToObjectSpace(pos) local h = z.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + 4 and math.abs(rel.Z) <= h.Z then return n end end
	end
	return "Hall"
end
-- dấu hiệu ĐANG xuất hiện: viền sáng nhấp nháy (không xuyên tường) — dễ nhận ra cho người chơi 12+
local liveHL = {}
do
	local SIGNS = {ECG = IX:WaitForChild("HeartMonitor"), Mirror = IX:WaitForChild("Mirror"), Drawer13 = IX:WaitForChild("Drawers"):WaitForChild("Drawer_13")}
	for k, inst in pairs(SIGNS) do
		local h = Instance.new("Highlight") h.Adornee = inst h.FillColor = Color3.fromRGB(200, 170, 255) h.OutlineColor = Color3.fromRGB(235, 220, 255)
		h.DepthMode = Enum.HighlightDepthMode.Occluded h.Enabled = false h.Parent = gui liveHL[k] = h
	end
	RunService.RenderStepped:Connect(function()
		local k2 = (math.sin(os.clock() * 3) + 1) / 2
		for k, h in pairs(liveHL) do
			local live = L2() and ST:GetAttribute("SignLive_" .. k) == true and not ST:GetAttribute("Sign_" .. k)
			h.Enabled = live
			if live then h.FillTransparency = 0.75 + 0.15 * k2 h.OutlineTransparency = 0.1 + 0.5 * k2 end
		end
	end)
end
-- vết đen trên đồ bảo hộ của ĐỒNG ĐỘI (bản thân không thấy)
local dirtyHL = {}

RunService.RenderStepped:Connect(function()
	local on = L2()
	panel.Visible = on status.Visible = on roomL.Visible = on callL.Visible = on
	local ph = ST:GetAttribute("Phase") or ""
	endF.Visible = on and (ph == "Win" or ph == "Lose")
	if endF.Visible then
		local t = ST:GetAttribute("RoundTime") or 0
		local tstr = string.format("%d:%02d", t // 60, t % 60)
		if ph == "Win" then e1.Text = "QUA TẦNG 2" e1.TextColor3 = Color3.fromRGB(160, 255, 200) e2.Text = "Bệnh viện chìm vào bóng tối sau lưng các em...\nThời gian: " .. tstr
		else e1.Text = "BỊ NUỐT" e1.TextColor3 = Color3.fromRGB(255, 90, 110) e2.Text = "Bệnh viện giữ các em lại.\nThời gian trụ được: " .. tstr .. "\n\nChơi lại Tầng 2 sau vài giây..." end
	end
	if not on then note.Visible = false for _, h in pairs(hl) do h.Enabled = false end return end
	local signs, shards, tickets = ST:GetAttribute("Signs") or 0, ST:GetAttribute("Shards") or 0, ST:GetAttribute("Tickets") or 0
	rows[1].Text = (signs >= 3 and "☑ " or "☐ ") .. "Dấu hiệu bất thường  " .. signs .. "/3"
	rows[2].Text = (shards >= 3 and "☑ " or "☐ ") .. "Mảnh Neo Thức  " .. shards .. "/3"
	rows[3].Text = "🎫 Phiếu Khám của bạn: " .. (plr:GetAttribute("Tickets") or 0) .. "  (cả nhóm: " .. tickets .. ")"
	rows[4].Text = (ST:GetAttribute("Keycard") and "☑ " or "☐ ") .. "Thẻ Từ (mở Phòng Ô Nhiễm)"
	local obj
	if not plr:GetAttribute("HasRules2") then obj = "→ Nhặt Hướng dẫn bệnh nhân ở quầy tiếp đón"
	elseif ph == "TrinhSat" then obj = "→ Tìm dấu hiệu (Phẫu Thuật · Đóng Phí · Nhà Xác)"
	elseif ph == "TruyNguyen" then obj = ST:GetAttribute("Keycard") and "→ Chọn đúng hồ sơ bệnh án trong Phòng Ô Nhiễm" or "→ Mua Thẻ Từ ở Phòng Đóng Phí"
	elseif ph == "ThanhTay" then obj = "→ Đưa túi truyền dịch tới lò hủy Nhà Xác"
	elseif ph == "Neo" then obj = shards < 3 and "→ Tìm Mảnh Neo" or "→ Đặt Mảnh Neo vào Bệ Neo ở sảnh"
	elseif ph == "Gate" then obj = plr:GetAttribute("Escaped") and "→ Đã qua Cổng" or "→ VỀ SẢNH, bước vào Cổng!"
	else obj = "" end
	rows[5].Text = obj
	roomL.Text = ROOM_VN[plr:GetAttribute("Room2") or ""] or ""
	-- trạng thái cá nhân
	local st = {}
	if plr:GetAttribute("Mask") then table.insert(st, "😷 Đang đeo khẩu trang") end
	if plr:GetAttribute("Suit") then table.insert(st, "🦺 Đang mặc đồ bảo hộ") end
	if plr:GetAttribute("Infected") then table.insert(st, '<font color="#FF6060">☣ NHIỄM BỆNH</font>') end
	if plr:GetAttribute("Hiding") then table.insert(st, "🗄 Đang trốn trong tủ xác") end
	status.Text = table.concat(st, "\n")
	-- đếm ngược thoát
	if ph == "Gate" and not plr:GetAttribute("Escaped") then
		local left = math.ceil((ST:GetAttribute("EscapeDeadline") or 0) - workspace:GetServerTimeNow())
		escL.Text = left > 0 and ("⚠ CỬA SẮT HẠ SAU " .. left .. "s — CHẠY VỀ SẢNH! ⚠") or "Cửa đã đóng — bước vào CỔNG!"
	else escL.Text = "" end
	-- LOA BỆNH VIỆN
	local ct = ST:GetAttribute("CallTarget") or ""
	if ct ~= "" and ph ~= "Gate" then
		local left = math.max(0, math.ceil((ST:GetAttribute("CallDeadline") or 0) - workspace:GetServerTimeNow()))
		local mine = ct == plr.Name
		callL.Text = "📢 LOA: mời " .. (mine and "<b>BẠN</b>" or ct) .. " đến " .. (ROOM_VN[ST:GetAttribute("CallRoom") or ""] or "") .. " — " .. left .. "s"
		callL.TextColor3 = mine and Color3.fromRGB(255, 200, 90) or Color3.fromRGB(200, 210, 220)
	else callL.Text = "" end
	-- Thấu Thị: Nhìn Xuyên
	local mineSight = plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > workspace:GetServerTimeNow()
	local teamSight = (ST:GetAttribute("SeerMarkUntil") or 0) > workspace:GetServerTimeNow()
	local sight = mineSight or teamSight
	-- Nhìn Xuyên chỉ soi PHÒNG đang đứng
	local room = mineSight and (plr:GetAttribute("SightRoom") or plr:GetAttribute("Room2")) or ST:GetAttribute("SeerMarkRoom")
	local fw = ST:GetAttribute("FakeWindow")
	mark("fake", fw and IX:FindFirstChild(fw == 1 and "CashierA" or "CashierB"), sight and room == "Billing", Color3.fromRGB(255, 50, 80))
	local myDrawer = ST:GetAttribute(plr:GetAttribute("Role") == "Seer" and "SeerDrawer" or "HealerDrawer")
	mark("drawer", myDrawer and IX.Drawers:FindFirstChild(myDrawer), sight and room == "Morgue", Color3.fromRGB(120, 200, 255))
	mark("drawer2", IX.Drawers:FindFirstChild(ST:GetAttribute("HealerDrawer") or ""), sight and room == "Morgue", Color3.fromRGB(120, 255, 170))
	local cr = ST:GetAttribute("CorrectRecord")
	mark("record", cr and IX:FindFirstChild("Record" .. cr), sight and room == "Contamination" and ph == "TruyNguyen", Color3.fromRGB(255, 220, 90))
	mark("doctor", IX:FindFirstChild("Doctor"), sight and room == "Surgery", Color3.fromRGB(255, 120, 60))
	mark("pz", IX:FindFirstChild("PatientZero"), sight and room == "Contamination", Color3.fromRGB(255, 60, 60))
	mark("keeper", IX:FindFirstChild("Keeper"), sight and room == "Morgue", Color3.fromRGB(255, 160, 60))
	local tk = map:FindFirstChild("Tickets")
	if tk then for i, t in ipairs(tk:GetChildren()) do local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") mark("t" .. i, t, sight and r and zoneOf(t.Position) == room, Color3.fromRGB(255, 215, 120)) end end
	if note.Visible then renderRules() end
	-- vết đen: thấy trên người khác
	for _, o in ipairs(Players:GetPlayers()) do
		if o ~= plr and o.Character then
			local dirty = o:GetAttribute("SuitDirty") and o:GetAttribute("Suit")
			local h = dirtyHL[o]
			if dirty and not h then h = Instance.new("Highlight") h.FillColor = Color3.new(0, 0, 0) h.FillTransparency = 0.3 h.OutlineColor = Color3.fromRGB(60, 0, 0) h.Parent = gui dirtyHL[o] = h end
			if h then h.Adornee = o.Character h.Enabled = dirty == true end
		end
	end
end)

-- ===== ĐÈN NHẤP NHÁY & ĐÈN KHẨN CẤP =====
task.spawn(function()
	local flick, pulse = {}, {}
	for _, p in ipairs(map:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("Flicker") then table.insert(flick, p) end
		if p:IsA("BasePart") and p:GetAttribute("Pulse") then table.insert(pulse, p) end
	end
	local function setOn(p, on) for _, l in ipairs(p:GetChildren()) do if l:IsA("Light") then l.Enabled = on end end p.Transparency = on and 0 or 0.6 end
	task.spawn(function()
		while true do
			task.wait(math.random(2, 6) / 10)
			local p = flick[math.random(#flick)]
			if p and L2() then
				for i = 1, math.random(2, 5) do setOn(p, false) task.wait(math.random(3, 12) / 100) setOn(p, true) task.wait(math.random(3, 15) / 100) end
			end
		end
	end)
	local t = 0
	while true do
		t += task.wait(0.05)
		local k = (math.sin(t * 2.2) + 1) / 2
		for _, p in ipairs(pulse) do
			local l = p:FindFirstChildOfClass("PointLight") if l then l.Brightness = 0.2 + k * 0.9 end
			p.Color = Color3.fromRGB(80 + 150 * k, 15, 15)
		end
	end
end)

-- ===== ÂM THANH NỀN TẦNG 2 =====
task.spawn(function()
	local amb = RS:WaitForChild("L2Ambience"):Clone() amb.Parent = gui
	local l1amb
	while true do
		task.wait(0.5)
		local on = L2()
		if on and not amb.IsPlaying then amb:Play() elseif not on and amb.IsPlaying then amb:Stop() end
		l1amb = l1amb or plr.PlayerGui:FindFirstChild("Ambience", true)
		if l1amb and l1amb:IsA("Sound") then
			if not l1amb:GetAttribute("BaseVol") then l1amb:SetAttribute("BaseVol", l1amb.Volume) end
			l1amb.Volume = on and l1amb:GetAttribute("BaseVol") * 0.35 or l1amb:GetAttribute("BaseVol")
		end
	end
end)
