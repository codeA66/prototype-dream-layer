-- DREAM LAYERS - TẦNG 4 BOSS (client): Nội quy căn nhà (có MỰC ĐỎ), Sổ trực của mẹ, HUD mục tiêu,
-- thanh ĐỘ SÂU GIẤC MỘNG, chương đang kể, Lớp Sự Thật của Thấu Thị, viền sáng dấu hiệu, màn 3 kết cục
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local LV = 4 -- khớp với LV trong Level4Manager
local ST = RS:WaitForChild("GameState4")
local map = workspace:WaitForChild("DreamMap4")
local IX = map:WaitForChild("Interactables")

do local o = plr:WaitForChild("PlayerGui"):FindFirstChild("Level4Gui") if o then o:Destroy() end end
local gui = Instance.new("ScreenGui") gui.Name = "Level4Gui" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 8
gui.Parent = plr:WaitForChild("PlayerGui")
local function txt(parent, pos, size, text, ts, font)
	local t = Instance.new("TextLabel", parent) t.Position = pos t.Size = size t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = Color3.fromRGB(238, 232, 248) t.TextStrokeTransparency = 0.5 t.Font = font or Enum.Font.GothamMedium t.TextSize = ts or 14
	t.TextXAlignment = Enum.TextXAlignment.Left t.TextWrapped = true t.RichText = true
	return t
end
local function onL() return plr:GetAttribute("Level") == LV end
local function now() return workspace:GetServerTimeNow() end
local function myRoom() return plr:GetAttribute("Room4") or "" end

-- ===== NỘI QUY CĂN NHÀ =====
-- "in" = Ban Quản Lý Giấc Ngủ (luôn đúng) · "tay" = Minh viết tay ✎ · "red" = MỰC ĐỎ của Kẻ Gieo Mộng (luôn đúng, hiện khi RedInk >= n)
local RULES = {
	{"LỚP HỌC TRONG TỦ SÁCH", {
		{"in", "Khi cô quay xuống nhìn lớp, không được di chuyển."},
		{"tay", "Tên ai hiện trên bảng, người đó phải lên BỤC GIẢNG trước khi cô quay xuống."},
		{"in", "Bục giảng chỉ dành cho người có tên trên bảng."},
		{"red", "Khi cô quay xuống, phải NHÌN THẲNG vào cô.", 1}}},
	{"PHÒNG CHỜ DƯỚI GẦM GIƯỜNG", {
		{"in", "Chỉ lên quầy khi SỐ CỦA BẠN được gọi."},
		{"tay", "Khi loa gọi SỐ 00, tất cả ngồi vào hàng ghế chờ."},
		{"in", "Đèn quầy đỏ thì không lại gần quầy."}}},
	{"KHU RỪNG TRONG BỨC TRANH", {
		{"tay", "Khi đom đóm tắt, đứng yên cho tới khi chúng sáng lại.", nil, 2}, -- bị MỰC ĐỎ 2 gạch bỏ
		{"red", "Khi đom đóm tắt, KHÔNG được đứng yên quá 2 giây.", 2},
		{"in", "Không bước ra khỏi khung tranh (viền vàng)."},
		{"in", "Không Ping trong tranh."}}},
	{"PHÒNG KHÁCH", {
		{"in", "Không bước vào bóng của ghế bành."},
		{"tay", "Khi chú ấy ngẩng lên, nhìn thẳng vào chú."},
		{"in", "Không nhảy khi chú đang đọc."}}},
	{"CẢ CĂN NHÀ", {
		{"in", "Mệt thì về đứng gần đèn ngủ trong phòng ngủ."}}},
}
-- 1 dòng viết tay NÓI DỐI mỗi ván (LieIndex) — Trang Cuối nằm ở phòng mà dòng này nhắc tới
local LIES = {
	{1, "Thấy tên mình trên bảng thì trốn xuống gầm bàn, cô không thấy đâu."},
	{2, "Loa gọi SỐ 00 thì chạy lên quầy — đó là lượt của bạn."},
	{3, "Ra khỏi khung tranh là thoát được khu rừng."},
	{4, "Khi chú ấy ngẩng lên, nhắm mắt lại và quay đi."},
}
local DIARY = {
	"<b>SỔ TRỰC CỦA MẸ</b> — <i>bên giường 13</i>",
	"",
	"• Con nói trong mơ: <b>lúc cô giáo quay xuống</b>, trên bảng hiện một cái tên không phải của ai trong lớp.",
	"• Con kể loa phòng chờ <b>cứ vài lượt</b> lại gọi một số không ai cầm.",
	"• Khi các bạn của con <b>mệt lả</b> (hoặc ở lại quá lâu), trong bức tranh có một cậu bé đứng nhìn ra — đúng lúc <b>đom đóm sáng lại</b>.",
	"",
	"<i>Chú kể chuyện đến mỗi tối. Chú bảo cuốn truyện ấy không bao giờ có trang cuối.</i>",
	"<i>Mẹ đã giấu trang cuối đi. Nó ở nơi mà lời nói dối muốn con tránh xa.</i>",
}
local note = Instance.new("Frame", gui) note.AnchorPoint = Vector2.new(0.5, 0.5) note.Position = UDim2.fromScale(0.5, 0.5) note.Size = UDim2.fromOffset(580, 680)
note.BackgroundColor3 = Color3.fromRGB(228, 222, 236) note.BorderSizePixel = 0 note.Visible = false note.ZIndex = 20
local nStroke = Instance.new("UIStroke", note) nStroke.Color = Color3.fromRGB(70, 60, 110) nStroke.Thickness = 2
local nsc = Instance.new("UIScale", note)
local function fit() local v = workspace.CurrentCamera.ViewportSize nsc.Scale = math.min(1, v.X / 620, v.Y / 720) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local nTitle = txt(note, UDim2.fromOffset(20, 12), UDim2.new(1, -40, 0, 30), "", 24, Enum.Font.GothamBlack)
nTitle.TextColor3 = Color3.fromRGB(60, 50, 100) nTitle.TextStrokeTransparency = 1 nTitle.TextXAlignment = Enum.TextXAlignment.Center nTitle.ZIndex = 21
local nSub = txt(note, UDim2.fromOffset(20, 42), UDim2.new(1, -40, 0, 18), "", 12)
nSub.TextColor3 = Color3.fromRGB(90, 85, 100) nSub.TextStrokeTransparency = 1 nSub.TextXAlignment = Enum.TextXAlignment.Center nSub.ZIndex = 21
local nBody = txt(note, UDim2.fromOffset(22, 66), UDim2.new(1, -44, 1, -120), "", 14, Enum.Font.Gotham)
nBody.TextColor3 = Color3.fromRGB(35, 30, 45) nBody.TextStrokeTransparency = 1 nBody.TextYAlignment = Enum.TextYAlignment.Top nBody.ZIndex = 21
local nBtn = Instance.new("TextButton", note) nBtn.Size = UDim2.fromOffset(170, 32) nBtn.Position = UDim2.new(0.5, -85, 1, -44) nBtn.Text = "Đã hiểu (M để đọc lại)"
nBtn.Font = Enum.Font.GothamBold nBtn.TextSize = 13 nBtn.TextColor3 = Color3.new(1, 1, 1) nBtn.BackgroundColor3 = Color3.fromRGB(80, 70, 130) nBtn.Modal = true nBtn.ZIndex = 21
Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 6)
nBtn.MouseButton1Click:Connect(function() note.Visible = false end)
local noteMode = "rules"
local function seerAt(room)
	return (plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > now() and plr:GetAttribute("SightRoom") == room)
		or ((ST:GetAttribute("SeerMarkUntil") or 0) > now() and ST:GetAttribute("SeerMarkRoom") == room)
end
local function renderNote()
	if noteMode == "log" then
		nTitle.Text = "SỔ TRỰC CỦA MẸ" nSub.Text = "Ghi KHI NÀO những điều lạ xuất hiện — không ghi Ở ĐÂU"
		nBody.Text = table.concat(DIARY, "\n") return
	end
	nTitle.Text = "TRUYỆN TRƯỚC GIỜ NGỦ — NỘI QUY CỦA CĂN NHÀ"
	nSub.Text = "Chữ in: Ban Quản Lý Giấc Ngủ · <i>✎ Chữ nghiêng: Minh viết tay</i> · <font color=\"#B0102A\">✒ Mực đỏ: vừa được viết thêm</font>"
	local red = ST:GetAttribute("RedInk") or 0
	local lie = LIES[ST:GetAttribute("LieIndex") or 1]
	local seer = seerAt("Lobby")
	local out = {}
	for i, room in ipairs(RULES) do
		table.insert(out, "<b>【" .. room[1] .. "】</b>")
		local lines = {}
		for _, r in ipairs(room[2]) do
			if r[1] ~= "red" or red >= r[3] then table.insert(lines, r) end
		end
		if lie[1] == i then table.insert(lines, 2, {"lie", lie[2]}) end
		for k, r in ipairs(lines) do
			local t = k .. ". " .. r[2]
			if r[1] == "red" then t = '<font color="#B0102A"><b>✒ ' .. t .. '</b></font>'
			elseif r[1] == "tay" and r[4] and red >= r[4] then t = '<font color="#8A8090"><s><i>✎ ' .. t .. '</i></s></font>'
			elseif r[1] == "lie" and seer then t = '<font color="#C0182C"><i>✎ ' .. t .. '  ✖ DỐI TRÁ</i></font>'
			elseif r[1] ~= "in" then t = "<i>✎ " .. t .. "</i>" end
			table.insert(out, t)
		end
		table.insert(out, "")
	end
	table.insert(out, "<i>Mỗi luật chỉ có hiệu lực trong đúng phòng đó. Phòng ngủ an toàn. Một dòng viết tay là LỜI NÓI DỐI. Dòng MỰC ĐỎ luôn là thật.</i>")
	nBody.Text = table.concat(out, "\n")
end
local function showNote(mode) noteMode = mode renderNote() note.Visible = true end
Remotes.Notify.OnClientEvent:Connect(function(msg)
	if msg == "__L4RULES__" then showNote("rules") elseif msg == "__DIARY4__" then showNote("log") end
end)
UIS.InputBegan:Connect(function(i, gp)
	if gp or not onL() then return end
	if i.KeyCode == Enum.KeyCode.M then
		if note.Visible then note.Visible = false elseif plr:GetAttribute("HasRules4") then showNote("rules") end
	end
end)
local function hookChar(char)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c.Name == "NoiQuyNha" then showNote("rules") end
		if c:IsA("Tool") and c.Name == "SoTrucCuaMe" then showNote("log") end
	end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") and (c.Name == "NoiQuyNha" or c.Name == "SoTrucCuaMe") then note.Visible = false end end)
end
if plr.Character then hookChar(plr.Character) end
plr.CharacterAdded:Connect(hookChar)

-- ===== HUD =====
local panel = Instance.new("Frame", gui) panel.AnchorPoint = Vector2.new(1, 0) panel.Position = UDim2.new(1, -12, 0, 52) panel.Size = UDim2.fromOffset(290, 108)
panel.BackgroundColor3 = Color3.fromRGB(16, 12, 26) panel.BackgroundTransparency = 0.45 panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local rows = {} for i = 1, 4 do rows[i] = txt(panel, UDim2.fromOffset(10, 4 + (i - 1) * 20), UDim2.new(1, -20, 0, 20), "", 14) end
rows[4].TextColor3 = Color3.fromRGB(255, 215, 140) rows[4].Size = UDim2.new(1, -20, 0, 40) rows[4].TextYAlignment = Enum.TextYAlignment.Top
-- thanh ĐỘ SÂU GIẤC MỘNG (3 khúc) ở giữa phía trên
local depthF = Instance.new("Frame", gui) depthF.AnchorPoint = Vector2.new(0.5, 0) depthF.Position = UDim2.new(0.5, 0, 0, 52) depthF.Size = UDim2.fromOffset(300, 34)
depthF.BackgroundTransparency = 1
local depthL = txt(depthF, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 14), "ĐỘ SÂU GIẤC MỘNG", 12, Enum.Font.GothamBold) depthL.TextXAlignment = Enum.TextXAlignment.Center
local seg = {}
for i = 1, 3 do
	local s = Instance.new("Frame", depthF) s.Position = UDim2.new((i - 1) / 3, 3, 0, 16) s.Size = UDim2.new(1 / 3, -6, 0, 12)
	s.BackgroundColor3 = Color3.fromRGB(150, 70, 230) s.BorderSizePixel = 0
	Instance.new("UICorner", s).CornerRadius = UDim.new(0, 4) seg[i] = s
end
local chapterL = txt(gui, UDim2.new(0.5, -250, 0, 90), UDim2.fromOffset(500, 20), "", 14, Enum.Font.GothamBold) chapterL.TextXAlignment = Enum.TextXAlignment.Center
chapterL.TextColor3 = Color3.fromRGB(230, 170, 255)
local status = txt(gui, UDim2.new(0, 16, 1, -230), UDim2.fromOffset(380, 60), "", 14, Enum.Font.GothamBold) status.TextYAlignment = Enum.TextYAlignment.Bottom
local escL = txt(gui, UDim2.new(0.5, -350, 0.2, 0), UDim2.fromOffset(700, 50), "", 28, Enum.Font.GothamBlack) escL.TextXAlignment = Enum.TextXAlignment.Center escL.TextColor3 = Color3.fromRGB(255, 80, 80)
local roomState = txt(gui, UDim2.new(0.5, -300, 0.2, 54), UDim2.fromOffset(600, 30), "", 20, Enum.Font.GothamBold) roomState.TextXAlignment = Enum.TextXAlignment.Center
local roomL = txt(gui, UDim2.new(0.5, -200, 0, 30), UDim2.fromOffset(400, 20), "", 13) roomL.TextXAlignment = Enum.TextXAlignment.Center roomL.TextTransparency = 0.3
local ROOM_VN = {Lobby = "Phòng ngủ của Minh (an toàn)", Room1 = "Lớp học trong tủ sách", Room2 = "Phòng chờ dưới gầm giường",
	Room3 = "Khu rừng trong bức tranh", Room4 = "Phòng khách", Hall = "Hành lang"}

-- màn kết thúc: 3 kết cục + thua
local endF = Instance.new("Frame", gui) endF.Size = UDim2.fromScale(1, 1) endF.BackgroundColor3 = Color3.new(0, 0, 0) endF.BackgroundTransparency = 0.2 endF.Visible = false endF.ZIndex = 30
local e1 = txt(endF, UDim2.new(0, 0, 0.33, 0), UDim2.new(1, 0, 0, 60), "", 46, Enum.Font.Antique) e1.TextXAlignment = Enum.TextXAlignment.Center e1.ZIndex = 31
local e2 = txt(endF, UDim2.new(0.1, 0, 0.33, 70), UDim2.new(0.8, 0, 0, 120), "", 20, Enum.Font.Garamond) e2.TextXAlignment = Enum.TextXAlignment.Center e2.ZIndex = 31
local ENDINGS = {
	dawn = {"BÌNH MINH", Color3.fromRGB(255, 225, 150), "Ánh nắng tràn qua cửa sổ. Ở giường 13, máy đo tim kêu đều trở lại.\nMinh mở mắt. Cuốn truyện cuối cùng cũng có trang cuối."},
	loop = {"GIẤC MỘNG TIẾP DIỄN", Color3.fromRGB(190, 170, 255), "Các em đã thoát ra... nhưng Minh vẫn ngủ.\nTrong phòng khách, Kẻ Gieo Mộng mở một cuốn truyện mới: “LỚP HỌC VỠ”."},
	left = {"NGƯỜI KỂ CHUYỆN MỚI", Color3.fromRGB(255, 110, 120), "Có người đã bị bỏ lại phía sau.\nCăn nhà vừa có một người ngủ mới... và Kẻ Gieo Mộng đã có câu chuyện tiếp theo."},
}

-- ===== LỚP SỰ THẬT (Thấu Thị) + VIỀN DẤU HIỆU =====
local hl = {}
local function mark(key, inst, on, color)
	local h = hl[key]
	if on and inst then
		if not h then h = Instance.new("Highlight") h.FillTransparency = 0.55 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = gui hl[key] = h end
		h.Adornee = inst h.FillColor = color h.OutlineColor = color h.Enabled = true
	elseif h then h.Enabled = false end
end
local liveHL = {}
do
	local SIGNS = {Name = IX:WaitForChild("Blackboard"), Number13 = IX:WaitForChild("QueueBoard"), Boy = IX:WaitForChild("Clue_Boy")}
	for k, inst in pairs(SIGNS) do
		local h = Instance.new("Highlight") h.Adornee = inst h.FillColor = Color3.fromRGB(200, 170, 255) h.OutlineColor = Color3.fromRGB(235, 220, 255)
		h.DepthMode = Enum.HighlightDepthMode.Occluded h.Enabled = false h.Parent = gui liveHL[k] = h
	end
	RunService.RenderStepped:Connect(function()
		local k2 = (math.sin(os.clock() * 3) + 1) / 2
		for k, h in pairs(liveHL) do
			local live = onL() and ST:GetAttribute("SignLive_" .. k) == true and not ST:GetAttribute("Sign_" .. k)
			h.Enabled = live
			if live then h.FillTransparency = 0.75 + 0.15 * k2 h.OutlineTransparency = 0.1 + 0.5 * k2 end
		end
	end)
end
-- tờ nội quy phát sáng khi MỰC ĐỎ sắp được viết
local paperHL = Instance.new("Highlight") paperHL.FillColor = Color3.fromRGB(255, 40, 60) paperHL.OutlineColor = Color3.fromRGB(255, 80, 90)
paperHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop paperHL.Enabled = false paperHL.Parent = gui

local function secsTo(attr) return math.max(0, math.ceil((ST:GetAttribute(attr) or 0) - now())) end
RunService.RenderStepped:Connect(function()
	local on = onL()
	panel.Visible = on status.Visible = on roomL.Visible = on roomState.Visible = on depthF.Visible = on chapterL.Visible = on
	local ph = ST:GetAttribute("Phase") or ""
	endF.Visible = on and (ph == "Win" or ph == "Lose")
	if endF.Visible then
		local t = ST:GetAttribute("RoundTime") or 0
		local tstr = string.format("%d:%02d", t // 60, t % 60)
		local e = ENDINGS[ST:GetAttribute("Ending") or ""]
		if ph == "Win" and e then e1.Text = e[1] e1.TextColor3 = e[2] e2.Text = e[3] .. "\n\nThời gian: " .. tstr
		else e1.Text = "BỊ KỂ VÀO TRUYỆN" e1.TextColor3 = Color3.fromRGB(255, 90, 110) e2.Text = "Kẻ Gieo Mộng khép sách lại.\nThời gian trụ được: " .. tstr .. "\n\nChơi lại tầng cuối sau vài giây..." end
	end
	if not on then note.Visible = false paperHL.Enabled = false for _, h in pairs(hl) do h.Enabled = false end return end
	local room = myRoom()
	-- Độ sâu
	local depth = ST:GetAttribute("Depth") or 3
	for i = 1, 3 do seg[i].BackgroundTransparency = i <= depth and 0 or 0.85 end
	-- chương đang kể
	local ch = ST:GetAttribute("Chapter") or ""
	if ch ~= "" and (ST:GetAttribute("ChapterUntil") or 0) > now() then chapterL.Text = "📖 Chương đang kể: " .. (ROOM_VN[ch] or ch) .. " · " .. secsTo("ChapterUntil") .. "s"
	else chapterL.Text = "" end
	-- tờ nội quy phát sáng khi mực đỏ sắp tới
	local pending = (ST:GetAttribute("RedInkPending") or 0) > 0
	local paper = plr.Character and plr.Character:FindFirstChild("NoiQuyNha")
	paperHL.Adornee = paper paperHL.Enabled = pending and paper ~= nil
	paperHL.FillTransparency = 0.3 + 0.4 * ((math.sin(os.clock() * 8) + 1) / 2)
	-- mục tiêu
	local signs, shards = ST:GetAttribute("Signs") or 0, ST:GetAttribute("Shards") or 0
	rows[1].Text = (signs >= 3 and "☑ " or "☐ ") .. "Dấu hiệu bất thường  " .. signs .. "/3"
	rows[2].Text = (ST:GetAttribute("Cleansed") and "☑ " or "☐ ") .. "Đốt cuốn truyện ở lò sưởi"
	rows[3].Text = (shards >= 3 and "☑ " or "☐ ") .. "Mảnh Neo Thức  " .. shards .. "/3"
	local obj
	if not plr:GetAttribute("HasRules4") then obj = "→ Nhặt tờ nội quy trên bàn học trong phòng ngủ"
	elseif ph == "TrinhSat" then obj = "→ Tìm 3 dấu hiệu (Sổ trực của mẹ ghi KHI NÀO)"
	elseif ph == "TruyNguyen" then obj = "→ Về phòng ngủ, chọn đúng cuốn truyện trên kệ"
	elseif ph == "ThanhTay" then
		local c = ST:GetAttribute("BookCarrier") or ""
		obj = c == "" and "→ Lấy cuốn truyện (bàn cô giáo / chỗ vừa bị thả)" or ("→ Mang cuốn truyện tới LÒ SƯỞI phòng khách" .. ((ST:GetAttribute("BookDeadline") or 0) > 0 and (" · " .. secsTo("BookDeadline") .. "s") or ""))
	elseif ph == "Neo" then obj = shards < 3 and "→ Tìm Mảnh Neo (Lớp học · Phòng chờ · Khu rừng)" or "→ Đặt Mảnh Neo vào Bệ Neo trong phòng ngủ"
	elseif ph == "Gate" then obj = plr:GetAttribute("Escaped") and "→ Đã qua cửa sổ" or "→ VỀ PHÒNG NGỦ, bước qua CỬA SỔ BÌNH MINH!"
	else obj = "" end
	rows[4].Text = obj
	roomL.Text = ROOM_VN[room] or ""
	-- trạng thái phòng
	local rs, rc = "", Color3.fromRGB(230, 225, 240)
	if ph ~= "Gate" then
		if room == "Room1" and ST:GetAttribute("TeacherLooking") then rs, rc = "👀 CÔ ĐANG NHÌN XUỐNG — ĐỨNG YÊN!", Color3.fromRGB(255, 220, 120)
		elseif room == "Room1" and (ST:GetAttribute("BoardTarget") or "") == plr.Name then rs, rc = "✏ TÊN BẠN TRÊN BẢNG — LÊN BỤC GIẢNG!", Color3.fromRGB(255, 150, 120)
		elseif room == "Room2" and ST:GetAttribute("CallNo") == 0 then rs, rc = "📢 SỐ 00 — NGỒI VÀO HÀNG GHẾ!", Color3.fromRGB(255, 90, 90)
		elseif room == "Room2" and (ST:GetAttribute("CallNo") or -1) > 0 then rs, rc = "📢 Đang gọi số " .. string.format("%02d", ST:GetAttribute("CallNo")), Color3.fromRGB(170, 230, 255)
		elseif room == "Room3" and ST:GetAttribute("FireflyOn") == false then
			rs = (ST:GetAttribute("RedInk") or 0) >= 2 and "🌑 ĐOM ĐÓM TẮT — ĐỪNG ĐỨNG YÊN! (mực đỏ)" or "🌑 ĐOM ĐÓM TẮT — ĐỨNG YÊN!" rc = Color3.fromRGB(255, 220, 120)
		elseif room == "Room4" and ph == "ThanhTay" and ST:GetAttribute("SeederHunting") then rs, rc = "🩸 KẺ GIEO MỘNG ĐANG ĐUỔI THEO CUỐN TRUYỆN!", Color3.fromRGB(255, 60, 80)
		elseif room == "Room4" and ST:GetAttribute("SeederState") == "look" and ph ~= "ThanhTay" then rs, rc = "👁 NÓ ĐANG NGẨNG LÊN — NHÌN THẲNG VÀO NÓ!", Color3.fromRGB(255, 90, 90) end
	end
	roomState.Text = rs roomState.TextColor3 = rc
	local st = {}
	if plr:GetAttribute("QueueNo") then table.insert(st, "🎫 Phiếu chờ của bạn: SỐ " .. string.format("%02d", plr:GetAttribute("QueueNo"))) end
	if (ST:GetAttribute("BookCarrier") or "") == plr.Name then table.insert(st, "📕 Đang cầm CUỐN TRUYỆN (đi chậm) — click để thả cho đồng đội") end
	if plr.Character and (plr.Character:FindFirstChild("TrangCuoi") or plr.Backpack:FindFirstChild("TrangCuoi")) then table.insert(st, "📄 Bạn giữ TRANG CUỐI — khi Cổng mở, đọc nó bên giường Minh") end
	status.Text = table.concat(st, "\n")
	if ph == "Gate" and not plr:GetAttribute("Escaped") then
		local left = math.ceil((ST:GetAttribute("EscapeDeadline") or 0) - now())
		escL.Text = left > 0 and ("⚠ CĂN NHÀ SẬP SAU " .. left .. "s — VỀ PHÒNG NGỦ! ⚠") or "Mọi cánh cửa đã khâu kín — bước qua CỬA SỔ!"
	else escL.Text = "" end
	-- Thấu Thị
	local mineSight = plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > now()
	local teamSight = (ST:GetAttribute("SeerMarkUntil") or 0) > now()
	local sight = mineSight or teamSight
	local sRoom = mineSight and (plr:GetAttribute("SightRoom") or room) or ST:GetAttribute("SeerMarkRoom")
	local SAFE, BAD, GOLD = Color3.fromRGB(120, 230, 255), Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 215, 110)
	local lie = ST:GetAttribute("LieIndex") or 1
	local page = not ST:GetAttribute("PageTaken") and IX:FindFirstChild("LastPage" .. lie)
	local pageRoom = ({"Room1", "Room2", "Room3", "Room4"})[lie]
	mark("teacher1", IX:FindFirstChild("Teacher"), sight and sRoom == "Room1", BAD)
	mark("podium1", IX:FindFirstChild("Podium"), sight and sRoom == "Room1", SAFE)
	mark("seats2", IX:FindFirstChild("Seats"), sight and sRoom == "Room2", SAFE)
	mark("counter2", IX:FindFirstChild("Counter"), sight and sRoom == "Room2", BAD)
	mark("frame3", IX:FindFirstChild("FrameInside"), sight and sRoom == "Room3", SAFE)
	mark("shadow4", IX:FindFirstChild("ChairShadow"), sight and sRoom == "Room4", BAD)
	mark("seeder4", IX:FindFirstChild("Seeder"), sight and sRoom == "Room4", BAD)
	mark("fire4", IX:FindFirstChild("Fireplace"), sight and sRoom == "Room4" and ph == "ThanhTay", GOLD)
	mark("book", IX:FindFirstChild("TaleBook"), sight and ph == "ThanhTay" and (ST:GetAttribute("BookCarrier") or "") == "", GOLD)
	mark("page", page, sight and sRoom == pageRoom, GOLD)
	local cp = ST:GetAttribute("CorrectPuzzle")
	mark("puzzle", cp and IX:FindFirstChild("Puzzle" .. cp), sight and sRoom == "Lobby" and ph == "TruyNguyen", GOLD)
	if note.Visible and noteMode == "rules" then renderNote() end
end)

-- ===== MAP ĐƯỢC LÀM MỚI: chạy lại script này để gắn với map mới =====
local myMap = map
local reloading = false
workspace.ChildAdded:Connect(function(c)
	if reloading or c.Name ~= "DreamMap4" or c == myMap then return end
	reloading = true
	task.spawn(function()
		while myMap and myMap.Parent == workspace and myMap.Name == "DreamMap4" do task.wait() end
		local s = script:Clone() s.Parent = script.Parent script:Destroy()
	end)
end)
