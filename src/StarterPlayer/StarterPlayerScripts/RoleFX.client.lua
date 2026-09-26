-- DREAM LAYERS — Hiệu ứng & giới thiệu 4 vai (dùng chung 2 tầng)
-- • Màn giới thiệu vai lúc mở màn mỗi tầng (phím V để xem lại)
-- • Lá quẻ (Bói Toán), dấu chân sáng, Linh Cảm
-- • Băng trạng thái phòng: đang bị Neo / đang được Ru
-- • Sợi Chỉ Đỏ (Chữa Lành), bản đồ nhanh của Thấu Thị (Hành lang / Sảnh)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local ST1 = RS:WaitForChild("GameState")
local ST2 = RS:WaitForChild("GameState2")
local function lvl() return plr:GetAttribute("Level") end
local function ST() return lvl() == 2 and ST2 or ST1 end
local function myRoom() return plr:GetAttribute(lvl() == 2 and "Room2" or "Room") end
local function now() return workspace:GetServerTimeNow() end

local gui = Instance.new("ScreenGui") gui.Name = "RoleFX" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 12
gui.Parent = plr:WaitForChild("PlayerGui")
local function txt(parent, pos, size, text, ts, font)
	local t = Instance.new("TextLabel", parent) t.Position = pos t.Size = size t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = Color3.fromRGB(238, 232, 248) t.TextStrokeTransparency = 0.5 t.Font = font or Enum.Font.GothamMedium t.TextSize = ts or 15
	t.TextWrapped = true t.RichText = true t.TextXAlignment = Enum.TextXAlignment.Left
	return t
end

-- ===== NỘI DUNG GIỚI THIỆU VAI =====
local ROLE = {
	Seer = {icon = "👁", name = "THẤU THỊ", color = Color3.fromRGB(160, 140, 255),
		stats = "Tỉnh táo tối đa 100 · Nhìn Xuyên: tốn 3, kéo dài 12 giây, hồi 18 giây",
		skill = "<b>NHÌN XUYÊN (Q)</b> — soi bí mật của <b>PHÒNG bạn đang đứng</b>: thấy trước khi nào điều trong phòng sắp thay đổi, thấy xuyên tường những thứ đang ẩn. Mọi thứ bạn soi được hiện cho <b>CẢ NHÓM</b> thêm 15 giây (Đánh Dấu).",
		passive = "<b>MẮT ĐÊM</b> — trong vòng 25 bước, bạn luôn thấy xuyên tường: hiểm nguy (viền tím) và đồ vật, Mảnh Neo, Phiếu Khám (viền vàng).",
		rooms = {
			{{"Trong mỗi phòng có luật", "Những bí mật và mốc giờ của riêng phòng đó — hãy tự khám phá"},
			 {"Nơi không có luật (hành lang)", "Thấy vị trí mọi đồng đội và mọi hiểm nguy trên cả tầng · lộ ra dòng NÓI DỐI trong tờ nội quy"}},
			{{"Trong mỗi phòng có luật", "Những bí mật và mốc giờ của riêng phòng đó — hãy tự khám phá"},
			 {"Nơi không có luật (sảnh)", "Thấy vị trí mọi đồng đội và mọi hiểm nguy trên cả tầng · lộ ra dòng NÓI DỐI trong tờ hướng dẫn"}}}},
	Healer = {icon = "♪", name = "CHỮA LÀNH", color = Color3.fromRGB(120, 230, 170),
		stats = "Tỉnh táo tối đa 100 · Bài Ru: tốn 5, hồi 30 giây",
		skill = "<b>BÀI RU (Q)</b> — mọi người trong phòng (cả bạn) <b>+25 Tỉnh táo</b>, <b>Bình tâm 12 giây</b> (miễn 1 lần phạt), kéo <b>TẤT CẢ</b> người Hòa Mộng trong phòng dậy. Trong <b>3 giây</b> sau đó, mọi sát thương lên họ <b>chỉ còn một nửa</b>.",
		passive = "<b>SỢI CHỈ ĐỎ</b> — bạn gánh <b>MỘT NỬA</b> mỗi lần phạt luật của đồng đội được nối, dù ở khác phòng. Đứng cạnh một đồng đội 2 giây để nối sang người đó.\nNgoài ra: đứng gần bạn là hồi Tỉnh táo; bạn thấy Tỉnh táo của cả nhóm.",
		rooms = {
			{{"Mọi nơi", "Tác dụng lên mọi người đang ở CÙNG PHÒNG với bạn lúc hát"}},
			{{"Mọi nơi", "Tác dụng lên mọi người đang ở CÙNG PHÒNG với bạn lúc hát"}}}},
	Anchor = {icon = "⚓", name = "NGƯỜI NEO", color = Color3.fromRGB(120, 180, 240),
		stats = "Tỉnh táo tối đa 110 · Cắm Neo: tốn 8, kéo dài 5 giây, hồi 40 giây",
		skill = "<b>CẮM NEO (Q)</b> — mọi thứ đang chuyển động trong <b>PHÒNG</b> đứng yên đúng như lúc bấm, đồng hồ sự kiện của phòng dừng lại. Neo khóa cả trạng thái XẤU — hãy chọn đúng lúc!\nKhi <b>CỔNG mở</b>: <b>CHỐNG CỬA</b> — cửa đóng chậm thêm 5 giây (1 lần mỗi tầng).",
		passive = "<b>CHÂN NEO</b> — bạn không bao giờ bị đơ.",
		rooms = {
			{{"Trong mỗi phòng có luật", "Mọi thứ đứng yên 5 giây"},
			 {"Nơi không có luật", "Không có gì để neo — trừ lúc Cổng mở: Chống cửa"}},
			{{"Trong mỗi phòng có luật", "Mọi thứ đứng yên 5 giây"},
			 {"Nơi không có luật", "Không có gì để neo — trừ lúc Cổng mở: Chống cửa"}}}},
	Diviner = {icon = "🔮", name = "NHÀ BÓI TOÁN", color = Color3.fromRGB(235, 195, 110),
		stats = "Tỉnh táo tối đa 100 · Gieo Quẻ: tốn 5, hồi 30 giây",
		skill = "<b>GIEO QUẺ (Q)</b> — rút một lá quẻ báo <b>SỰ KIỆN KẾ TIẾP</b> của phòng đang đứng: điều gì sắp xảy ra, với ai, khi nào. Chỉ bạn thấy lá quẻ — hãy báo cho đồng đội!",
		passive = "<b>ĐIỀM BÁO</b> — khoảng 3 giây trước khi phòng bạn đang đứng sắp đổi trạng thái, viền màn hình rung nhẹ (tối đa 1 lần mỗi 60 giây).",
		rooms = {
			{{"Trong mỗi phòng có luật", "Báo trước sự kiện kế tiếp của phòng đó"},
			 {"Nơi không có luật", "Báo tiến độ của cả nhóm và những gì còn thiếu"}},
			{{"Trong mỗi phòng có luật", "Báo trước sự kiện kế tiếp của phòng đó"},
			 {"Nơi không có luật", "Báo trước điều sắp xảy ra với cả nhóm"}}}},
}
ROLE_INFO = ROLE -- để script khác (Lớp/Sổ tay) có thể dùng chung nếu cần

-- ===== MÀN GIỚI THIỆU VAI =====
local intro = Instance.new("Frame", gui) intro.AnchorPoint = Vector2.new(0.5, 0.5) intro.Position = UDim2.fromScale(0.5, 0.5) intro.Size = UDim2.fromOffset(660, 580)
intro.BackgroundColor3 = Color3.fromRGB(16, 12, 26) intro.BackgroundTransparency = 0.05 intro.Visible = false intro.ZIndex = 40
Instance.new("UICorner", intro).CornerRadius = UDim.new(0, 14)
local iStroke = Instance.new("UIStroke", intro) iStroke.Thickness = 2
local iScale = Instance.new("UIScale", intro)
local function fit() local v = workspace.CurrentCamera.ViewportSize iScale.Scale = math.min(1, (v.X - 20) / 680, (v.Y - 20) / 600) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local iTitle = txt(intro, UDim2.fromOffset(24, 14), UDim2.new(1, -48, 0, 40), "", 28, Enum.Font.GothamBlack) iTitle.ZIndex = 41
local iStats = txt(intro, UDim2.fromOffset(24, 54), UDim2.new(1, -48, 0, 20), "", 14, Enum.Font.GothamBold) iStats.ZIndex = 41 iStats.TextColor3 = Color3.fromRGB(200, 195, 220)
local iScroll = Instance.new("ScrollingFrame", intro) iScroll.Position = UDim2.fromOffset(20, 82) iScroll.Size = UDim2.new(1, -40, 1, -146)
iScroll.BackgroundTransparency = 1 iScroll.BorderSizePixel = 0 iScroll.ScrollBarThickness = 6 iScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y iScroll.CanvasSize = UDim2.new() iScroll.ZIndex = 41
local iBody = txt(iScroll, UDim2.fromOffset(4, 0), UDim2.new(1, -16, 0, 0), "", 15) iBody.AutomaticSize = Enum.AutomaticSize.Y iBody.TextYAlignment = Enum.TextYAlignment.Top iBody.ZIndex = 42 iBody.TextStrokeTransparency = 1
local iBtn = Instance.new("TextButton", intro) iBtn.AnchorPoint = Vector2.new(0.5, 1) iBtn.Position = UDim2.new(0.5, 0, 1, -14) iBtn.Size = UDim2.fromOffset(240, 42)
iBtn.Font = Enum.Font.GothamBlack iBtn.TextSize = 17 iBtn.TextColor3 = Color3.new(1, 1, 1) iBtn.Text = "ĐÃ HIỂU (V để xem lại)" iBtn.Modal = true iBtn.ZIndex = 41
Instance.new("UICorner", iBtn).CornerRadius = UDim.new(0, 10)
iBtn.MouseButton1Click:Connect(function() intro.Visible = false end)
local LEVEL_NAME = {"TẦNG 1 — LỚP HỌC VỠ", "TẦNG 2 — BỆNH VIỆN NGỦ QUÊN"}
local function hex(c) return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255) end
local function showIntro()
	local r = ROLE[plr:GetAttribute("Role") or ""] local l = lvl()
	if not r or not l or not r.rooms[l] then return end
	iTitle.Text = r.icon .. "  VAI CỦA BẠN: " .. r.name iTitle.TextColor3 = r.color iStroke.Color = r.color iBtn.BackgroundColor3 = r.color:Lerp(Color3.new(0, 0, 0), 0.45)
	iStats.Text = r.stats
	local c = hex(r.color)
	local lines = {"<font color=\"" .. c .. "\"><b>KỸ NĂNG</b></font>", r.skill, "",
		"<font color=\"" .. c .. "\"><b>DÙNG Ở ĐÂU — LÀM GÌ (" .. LEVEL_NAME[l] .. ")</b></font>", "<i>Kỹ năng CHỈ tác động lên phòng bạn đang đứng lúc bấm, không lan sang phòng khác.</i>"}
	for _, row in ipairs(r.rooms[l]) do table.insert(lines, "• <b>" .. row[1] .. ":</b> " .. row[2]) end
	table.insert(lines, "")
	table.insert(lines, "<font color=\"" .. c .. "\"><b>NỘI TẠI</b></font>")
	table.insert(lines, r.passive)
	iBody.Text = table.concat(lines, "\n")
	iScroll.CanvasPosition = Vector2.zero
	intro.Visible = true
end
local lastShown = nil
local function maybeIntro()
	local l = lvl()
	if l and l ~= lastShown and plr:GetAttribute("Role") then lastShown = l task.delay(1.2, showIntro) end
	if not l then lastShown = nil intro.Visible = false end
end
plr:GetAttributeChangedSignal("Level"):Connect(maybeIntro)
plr:GetAttributeChangedSignal("Role"):Connect(function() if intro.Visible then showIntro() end end)
maybeIntro()
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.V then if intro.Visible then intro.Visible = false else showIntro() end end
end)

-- ===== LÁ QUẺ (Bói Toán) =====
local card = Instance.new("Frame", gui) card.AnchorPoint = Vector2.new(1, 0.5) card.Position = UDim2.new(1, -16, 0.5, 0) card.Size = UDim2.fromOffset(330, 170)
card.BackgroundColor3 = Color3.fromRGB(34, 24, 12) card.BackgroundTransparency = 0.1 card.Visible = false
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
local cs = Instance.new("UIStroke", card) cs.Color = Color3.fromRGB(235, 195, 110) cs.Thickness = 2
local cTitle = txt(card, UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 24), "", 17, Enum.Font.GothamBlack) cTitle.TextColor3 = Color3.fromRGB(245, 210, 130)
local cBody = txt(card, UDim2.fromOffset(14, 36), UDim2.new(1, -28, 1, -44), "", 15) cBody.TextYAlignment = Enum.TextYAlignment.Top
local cardToken = 0
-- dấu chân / vòng sáng trên sàn (chỉ người gieo quẻ thấy)
local marks = Instance.new("Folder") marks.Name = "QueMarks" marks.Parent = workspace
local function floorAt(x, z)
	local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {marks} for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ex, p.Character) end end params.FilterDescendantsInstances = ex
	local r = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -80, 0), params)
	return r and r.Position.Y or 0
end
Remotes.Notify.OnClientEvent:Connect(function(msg)
	if typeof(msg) ~= "string" then return end
	if msg:sub(1, 7) == "__QUE__" then
		local _, room, text = table.unpack(string.split(msg, "|"))
		cTitle.Text = "🔮 QUẺ · " .. (room or "") cBody.Text = text or ""
		card.Visible = true cardToken += 1 local tk = cardToken
		card.Position = UDim2.new(1, 360, 0.5, 0)
		TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Position = UDim2.new(1, -16, 0.5, 0)}):Play()
		task.delay(12, function() if tk == cardToken then card.Visible = false end end)
	elseif msg:sub(1, 9) == "__STEPS__" then
		marks:ClearAllChildren()
		local data = string.split(msg, "|")[2] or ""
		for i, pair in ipairs(string.split(data, ";")) do
			local x, z = pair:match("([%-%d%.]+),([%-%d%.]+)")
			x, z = tonumber(x), tonumber(z)
			if x and z then
				local y = floorAt(x, z)
				local m = Instance.new("Part") m.Anchored = true m.CanCollide = false m.CanQuery = false m.CastShadow = false
				m.Shape = Enum.PartType.Cylinder m.Size = Vector3.new(0.15, 3.2, 3.2) m.Material = Enum.Material.Neon
				m.Color = Color3.fromRGB(245, 200, 110) m.Transparency = 0.25 + (i - 1) * 0.15
				m.CFrame = CFrame.new(x, y + 0.08, z) * CFrame.Angles(0, 0, math.rad(90)) m.Parent = marks
				local gl = Instance.new("PointLight", m) gl.Range = 7 gl.Brightness = 1.2 gl.Color = m.Color
			end
		end
		task.delay(12, function() marks:ClearAllChildren() end)
	elseif msg:sub(1, 11) == "__LINHCAM__" then
		local room = string.split(msg, "|")[2] or ""
		senseMsg(room)
	end
end)

-- ===== LINH CẢM =====
local edge = Instance.new("Frame", gui) edge.Size = UDim2.fromScale(1, 1) edge.BackgroundTransparency = 1 edge.ZIndex = 2
local es = Instance.new("UIStroke", edge) es.Thickness = 18 es.Color = Color3.fromRGB(235, 195, 110) es.Transparency = 1
local senseL = txt(gui, UDim2.new(0.5, -300, 0.3, 0), UDim2.fromOffset(600, 30), "", 20, Enum.Font.GothamBlack)
senseL.TextXAlignment = Enum.TextXAlignment.Center senseL.TextColor3 = Color3.fromRGB(245, 210, 130) senseL.TextTransparency = 1
function senseMsg(room)
	senseL.Text = "🔮 Linh cảm: có gì đó vừa thay đổi ở " .. string.upper(room) senseL.TextTransparency = 0
	for i = 1, 3 do
		es.Transparency = 0.2 TweenService:Create(es, TweenInfo.new(0.45), {Transparency = 1}):Play() task.wait(0.5)
	end
	task.delay(3, function() TweenService:Create(senseL, TweenInfo.new(1), {TextTransparency = 1}):Play() end)
end

-- ===== ĐIỀM BÁO (nội tại Bói Toán): rung viền ~3 giây trước khi phòng đang đứng đổi trạng thái =====
local OMEN = {
	[1] = {Class = {"TeacherTurnAt"}, East = {"MusicChangeAt"}},
	[2] = {Surgery = {"OpLightAt"}, Morgue = {"MorgueDarkAt"}, Billing = {"QueueZeroAt"}},
}
local omenDone = {}
local lastOmen = -999 -- Điềm Báo: tối đa 1 lần mỗi 60 giây
task.spawn(function()
	while true do
		task.wait(0.2)
		local l = lvl()
		if l and plr:GetAttribute("Role") == "Diviner" and not plr:GetAttribute("Dreaming") and OMEN[l] then
			local attrs = OMEN[l][myRoom() or ""]
			if attrs then
				for _, a in ipairs(attrs) do
					local at = ST():GetAttribute(a)
					if type(at) == "number" and at > 0 then
						local left = at - now()
						local key = a .. math.floor(at)
						if left > 0 and left <= 3 and not omenDone[key] and os.clock() - lastOmen >= 60 then
							omenDone[key] = true lastOmen = os.clock()
							senseL.Text = "🔮 Điềm báo: có gì đó sắp thay đổi trong phòng..." senseL.TextTransparency = 0
							task.spawn(function()
								for i = 1, 2 do es.Transparency = 0.25 TweenService:Create(es, TweenInfo.new(0.4), {Transparency = 1}):Play() task.wait(0.45) end
								task.wait(1.5) TweenService:Create(senseL, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
							end)
						end
					end
				end
			end
		end
	end
end)

-- ===== BĂNG TRẠNG THÁI PHÒNG: NEO / RU =====
local roomBanner = txt(gui, UDim2.new(0.5, -300, 0, 116), UDim2.fromOffset(600, 26), "", 18, Enum.Font.GothamBlack) roomBanner.TextXAlignment = Enum.TextXAlignment.Center
local tint = Instance.new("ColorCorrectionEffect") tint.Name = "RoleTint" tint.Enabled = false tint.Parent = game:GetService("Lighting")
-- ===== SỢI CHỈ ĐỎ =====
local bondL = txt(gui, UDim2.new(0, 16, 1, -206), UDim2.fromOffset(360, 20), "", 14, Enum.Font.GothamBold) bondL.TextColor3 = Color3.fromRGB(255, 120, 120)
local beam, a0, a1
local function clearBeam() if beam then beam:Destroy() a0:Destroy() a1:Destroy() beam = nil end end
-- ===== BẢN ĐỒ NHANH CỦA THẤU THỊ (Hành lang T1 / Sảnh T2) =====
local floorHL = {}
local function setHL(key, inst, on, color)
	local h = floorHL[key]
	if on and inst then
		if not h then h = Instance.new("Highlight") h.FillTransparency = 0.6 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = gui floorHL[key] = h end
		h.Adornee = inst h.FillColor = color h.OutlineColor = color h.Enabled = true
	elseif h then h.Enabled = false end
end
local ENEMIES = {
	[1] = function() local IX = workspace.DreamMap.Interactables return {IX:FindFirstChild("Teacher"), IX:FindFirstChild("Librarian"), IX:FindFirstChild("Puppet")} end,
	[2] = function() local IX = workspace.DreamMap2.Interactables return {IX:FindFirstChild("Doctor"), IX:FindFirstChild("Keeper"), IX:FindFirstChild("PatientZero")} end,
}

RunService.RenderStepped:Connect(function()
	local l = lvl() local st = ST() local t = now()
	-- Neo / Ru của phòng mình đang đứng
	local room = myRoom()
	local fz = l and room and (st:GetAttribute("Freeze_" .. room) or 0) - t or 0
	local lu = l and (plr:GetAttribute("LullUntil") or 0) - t or 0
	if fz > 0 then
		roomBanner.Text = "⚓ Phòng đang bị NEO — mọi thứ đứng yên " .. math.ceil(fz) .. "s" roomBanner.TextColor3 = Color3.fromRGB(150, 200, 255)
		tint.Enabled = true tint.TintColor = Color3.fromRGB(200, 220, 255) tint.Saturation = -0.35
	elseif lu > 0 then
		roomBanner.Text = "♪ Bài Ru — sát thương giảm một nửa " .. math.ceil(lu) .. "s" roomBanner.TextColor3 = Color3.fromRGB(150, 255, 190)
		tint.Enabled = true tint.TintColor = Color3.fromRGB(215, 255, 225) tint.Saturation = -0.1
	else roomBanner.Text = "" tint.Enabled = false end
	-- Sợi Chỉ Đỏ
	local role = plr:GetAttribute("Role")
	local partner, iAmHealer = nil, false
	if l and role == "Healer" and plr:GetAttribute("BondWith") then partner = Players:FindFirstChild(plr:GetAttribute("BondWith")) iAmHealer = true
	elseif l then for _, o in ipairs(Players:GetPlayers()) do if o ~= plr and o:GetAttribute("Role") == "Healer" and o:GetAttribute("BondWith") == plr.Name and o:GetAttribute("Level") == l then partner = o end end end
	if partner then
		bondL.Text = iAmHealer and ("🧵 Sợi Chỉ Đỏ: bạn gánh hộ " .. partner.DisplayName) or ("🧵 " .. partner.DisplayName .. " đang gánh hộ bạn một nửa mỗi lần phạt")
		local r1 = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") local r2 = partner.Character and partner.Character:FindFirstChild("HumanoidRootPart")
		if r1 and r2 then
			if not beam or a0.Parent ~= r1 or a1.Parent ~= r2 then
				clearBeam()
				a0 = Instance.new("Attachment", r1) a1 = Instance.new("Attachment", r2)
				beam = Instance.new("Beam") beam.Attachment0 = a0 beam.Attachment1 = a1 beam.Width0 = 0.12 beam.Width1 = 0.12 beam.FaceCamera = true
				beam.Color = ColorSequence.new(Color3.fromRGB(255, 60, 70)) beam.LightEmission = 1 beam.Transparency = NumberSequence.new(0.35) beam.Parent = r1
			end
		else clearBeam() end
	else bondL.Text = "" clearBeam() end
	-- bản đồ nhanh của Thấu Thị (cả nhóm thấy nhờ Đánh Dấu)
	local mine = role == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > t
	local team = l and (st:GetAttribute("SeerMarkUntil") or 0) > t
	local sRoom = mine and plr:GetAttribute("SightRoom") or (team and st:GetAttribute("SeerMarkRoom"))
	local floorView = l and (mine or team) and ((l == 1 and sRoom == "Hall") or (l == 2 and sRoom == "Lobby"))
	for _, o in ipairs(Players:GetPlayers()) do if o ~= plr then setHL("p" .. o.UserId, o.Character, floorView, Color3.fromRGB(120, 255, 170)) end end
	local ens = l and ENEMIES[l] and ENEMIES[l]() or {}
	for i = 1, 3 do setHL("e" .. i, ens[i], floorView and ens[i] ~= nil, Color3.fromRGB(255, 90, 90)) end
	-- MẮT ĐÊM (nội tại Thấu Thị): trong 25 bước thấy xuyên tường hiểm nguy + đồ vật
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local seerEye = role == "Seer" and root and not plr:GetAttribute("Dreaming") and l
	local loot = {}
	if seerEye then
		if l == 1 then
			local IX = workspace.DreamMap.Interactables
			for _, n in ipairs({"Shard1", "Shard2", "Shard3", "Chalk", "TaskBook", "Notebook", "Diary"}) do local x = IX:FindFirstChild(n) if x and x.Transparency < 1 then table.insert(loot, x) end end
			for _, it in ipairs(workspace.DreamMap.Items:GetChildren()) do table.insert(loot, it) end
		else
			local IX = workspace.DreamMap2.Interactables
			for _, n in ipairs({"ShardDoctor", "ShardBuy", "IVBag", "NightLog"}) do local x = IX:FindFirstChild(n) if x and x.Transparency < 1 then table.insert(loot, x) end end
			local tk = workspace.DreamMap2:FindFirstChild("Tickets") if tk then for _, t in ipairs(tk:GetChildren()) do table.insert(loot, t) end end
		end
	end
	for k, h in pairs(floorHL) do if k:sub(1, 2) == "l_" then h.Enabled = false end end
	for i, it in ipairs(loot) do
		local pos = it:IsA("Model") and it:GetPivot().Position or it.Position
		if (pos - root.Position).Magnitude < 25 then
			local h = floorHL["l_" .. i]
			if not h then h = Instance.new("Highlight") h.FillTransparency = 0.8 h.OutlineTransparency = 0.35 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.FillColor = Color3.fromRGB(255, 215, 110) h.OutlineColor = Color3.fromRGB(255, 215, 110) h.Parent = gui floorHL["l_" .. i] = h end
			h.Adornee = it h.Enabled = true
		end
	end
	for i = 1, 3 do
		local e = ens[i]
		local near = seerEye and e and ((e:IsA("Model") and e:GetPivot().Position or e.Position) - root.Position).Magnitude < 25
		local h = floorHL["n" .. i]
		if near and not h then h = Instance.new("Highlight") h.FillTransparency = 1 h.OutlineTransparency = 0.45 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.OutlineColor = Color3.fromRGB(190, 170, 255) h.Parent = gui floorHL["n" .. i] = h end
		if h then h.Adornee = e h.Enabled = near == true and not floorView end
	end
end)
