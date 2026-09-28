-- DREAM LAYERS - TẦNG 3 (client): Nội quy khu cắm trại, Nhật ký kiểm lâm, HUD mục tiêu, nín thở (Vườn nấm),
-- nhìn xuống nước (Đầm sương), Lớp Sự Thật của Thấu Thị, viền sáng dấu hiệu, màn thắng/thua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local plr = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local L3Act = Remotes:WaitForChild("L3Act")
local ST = RS:WaitForChild("GameState3")
local map = workspace:WaitForChild("DreamMap3")
local IX = map:WaitForChild("Interactables")

do local o = plr:WaitForChild("PlayerGui"):FindFirstChild("Level3Gui") if o then o:Destroy() end end -- bản cũ của script
local gui = Instance.new("ScreenGui") gui.Name = "Level3Gui" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 8
gui.Parent = plr:WaitForChild("PlayerGui")
local function txt(parent, pos, size, text, ts, font)
	local t = Instance.new("TextLabel", parent) t.Position = pos t.Size = size t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = Color3.fromRGB(235, 240, 230) t.TextStrokeTransparency = 0.5 t.Font = font or Enum.Font.GothamMedium t.TextSize = ts or 14
	t.TextXAlignment = Enum.TextXAlignment.Left t.TextWrapped = true t.RichText = true
	return t
end
local function L3() return plr:GetAttribute("Level") == 3 end
local function now() return workspace:GetServerTimeNow() end
local function myRoom() return plr:GetAttribute("Room3") or "" end

-- ===== NỘI QUY KHU CẮM TRẠI =====
local RULES = {
	{"RỪNG ĐOM ĐÓM", {
		{"in", "Chỉ đi trên lối đá trắng. Bước vào cỏ cao, bạn sẽ bị lạc."},
		{"tay", "Khi đom đóm tắt, đứng yên cho tới khi chúng sáng lại."},
		{"in", "Không bắt đom đóm."}}},
	{"ĐẦM SƯƠNG MÙ", {
		{"tay", "Khi chuông gió vang, không rời khỏi lối đá."},
		{"in", "Đừng nhìn xuống mặt nước quá lâu."},
		{"in", "Cầu gỗ chỉ chịu được một người."}}},
	{"CÂY CỔ THỤ", {
		{"in", "Không nói chuyện trước những thứ đang nhìn bạn."},
		{"tay", "Khi cây mở mắt, quay lưng lại với nó."},
		{"in", "Không giẫm lên rễ cây phát sáng."}}},
	{"HANG GỖ MỤC", {
		{"tay", "Khi tiếng gõ đến gần, nép vào hốc tường."},
		{"in", "Không nhảy trong hang."},
		{"tay", "Đếm tiếng gõ khi vào hang. Trước khi ra, gõ lại đúng chừng ấy lần vào tảng đá cạnh cửa."}}},
	{"VƯỜN NẤM", {
		{"tay", "Khi nấm phát sáng, nín thở (giữ phím B) cho tới khi nấm tắt."},
		{"in", "Đừng hái bất cứ thứ gì mọc dưới đất."},
		{"in", "Chỉ bước vào vòng nấm trắng, tránh vòng nấm đỏ."}}},
	{"TOÀN KHU RỪNG", {
		{"in", "Thấy mệt, hãy quay lại lửa trại."}}},
}
-- mỗi ván có 1 dòng viết tay NÓI DỐI (chèn vào phòng tương ứng) — mâu thuẫn với một luật khác
local LIES = {
	{1, "Khi đom đóm tắt, chạy thật nhanh qua — đừng đứng lại."},
	{3, "Khi cây mở mắt, nhìn thẳng vào nó, nó sẽ sợ."},
	{4, "Khi tiếng gõ đến gần, chạy thật nhanh ra khỏi hang."},
	{5, "Khi nấm phát sáng, hái một cây mà ăn — nó sẽ giúp bạn thở."},
}
local LOG_TEXT = {
	"<b>NHẬT KÝ KIỂM LÂM</b> — <i>trang cuối, chữ run run</i>",
	"",
	"• Ngay khi đàn đom đóm <b>sáng trở lại</b>, chúng xếp thành một hình gì đó… rồi tan đi.",
	"• Tiếng chuông gió <b>vừa dứt</b> là mặt nước lặng như gương. Tôi thấy một bóng người không phải mình.",
	"• Lúc cái cây <b>nhắm mắt lại</b>, vỏ cây lộ ra những nét chữ.",
	"• <b>Sau khi</b> tiếng gõ đi qua, trong hang có thứ gì đó rơi lại.",
	"• Khi bào tử <b>lắng xuống</b>, giữa vòng nấm lộ ra một thứ nhỏ xíu.",
	"",
	"<i>Không phải đêm nào cũng đủ cả năm điều. Mỗi đêm chỉ ba. Và chúng chỉ ở lại chừng hai mươi hơi thở.</i>",
	"<i>Đứa bé ấy vẫn đi vòng quanh ngoài kia. Tôi nghe tiếng nó gọi mỗi đêm.</i>",
}
local note = Instance.new("Frame", gui) note.AnchorPoint = Vector2.new(0.5, 0.5) note.Position = UDim2.fromScale(0.5, 0.5) note.Size = UDim2.fromOffset(560, 660)
note.BackgroundColor3 = Color3.fromRGB(232, 226, 204) note.BorderSizePixel = 0 note.Visible = false note.ZIndex = 20
Instance.new("UIStroke", note).Color = Color3.fromRGB(70, 90, 50)
local nsc = Instance.new("UIScale", note)
local function fit() local v = workspace.CurrentCamera.ViewportSize nsc.Scale = math.min(1, v.X / 600, v.Y / 700) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local nTitle = txt(note, UDim2.fromOffset(20, 12), UDim2.new(1, -40, 0, 30), "", 24, Enum.Font.GothamBlack)
nTitle.TextColor3 = Color3.fromRGB(50, 70, 35) nTitle.TextStrokeTransparency = 1 nTitle.TextXAlignment = Enum.TextXAlignment.Center nTitle.ZIndex = 21
local nSub = txt(note, UDim2.fromOffset(20, 42), UDim2.new(1, -40, 0, 18), "", 12)
nSub.TextColor3 = Color3.fromRGB(90, 90, 75) nSub.TextStrokeTransparency = 1 nSub.TextXAlignment = Enum.TextXAlignment.Center nSub.ZIndex = 21
local nBody = txt(note, UDim2.fromOffset(22, 66), UDim2.new(1, -44, 1, -120), "", 14, Enum.Font.Gotham)
nBody.TextColor3 = Color3.fromRGB(35, 35, 28) nBody.TextStrokeTransparency = 1 nBody.TextYAlignment = Enum.TextYAlignment.Top nBody.ZIndex = 21
local nBtn = Instance.new("TextButton", note) nBtn.Size = UDim2.fromOffset(170, 32) nBtn.Position = UDim2.new(0.5, -85, 1, -44) nBtn.Text = "Đã hiểu (M để đọc lại)"
nBtn.Font = Enum.Font.GothamBold nBtn.TextSize = 13 nBtn.TextColor3 = Color3.new(1, 1, 1) nBtn.BackgroundColor3 = Color3.fromRGB(70, 95, 50) nBtn.Modal = true nBtn.ZIndex = 21
Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 6)
nBtn.MouseButton1Click:Connect(function() note.Visible = false end)
local noteMode = "rules"
local function seerAt(room)
	return (plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > now() and plr:GetAttribute("SightRoom") == room)
		or ((ST:GetAttribute("SeerMarkUntil") or 0) > now() and ST:GetAttribute("SeerMarkRoom") == room)
end
local function renderNote()
	if noteMode == "log" then
		nTitle.Text = "NHẬT KÝ KIỂM LÂM" nSub.Text = "Ghi KHI NÀO những điều lạ xuất hiện — không ghi Ở ĐÂU"
		nBody.Text = table.concat(LOG_TEXT, "\n") return
	end
	nTitle.Text = "NỘI QUY KHU CẮM TRẠI" nSub.Text = "Chữ in: Ban Quản Lý Khu Cắm Trại · <i>Chữ nghiêng: người lạc trước đây viết tay ✎</i>"
	local lie = LIES[ST:GetAttribute("LieIndex") or 1]
	local seer = seerAt("Lobby")
	local out = {}
	for i, room in ipairs(RULES) do
		table.insert(out, "<b>【" .. room[1] .. "】</b>")
		local lines = {}
		for _, r in ipairs(room[2]) do table.insert(lines, r) end
		if lie[1] == i then table.insert(lines, 2, {"lie", lie[2]}) end
		for k, r in ipairs(lines) do
			local t = k .. ". " .. r[2]
			if r[1] == "in" then t = t
			elseif r[1] == "lie" and seer then t = '<font color="#C0182C"><i>✎ ' .. t .. '  ✖ DỐI TRÁ</i></font>'
			else t = "<i>✎ " .. t .. "</i>" end
			table.insert(out, t)
		end
		table.insert(out, "")
	end
	table.insert(out, "<i>Mỗi luật chỉ có hiệu lực trong đúng khu đó. Lửa trại an toàn. Một dòng viết tay là LỜI NÓI DỐI — nó mâu thuẫn với một luật khác.</i>")
	nBody.Text = table.concat(out, "\n")
end
local function showNote(mode) noteMode = mode renderNote() note.Visible = true end
Remotes.Notify.OnClientEvent:Connect(function(msg)
	if msg == "__L3RULES__" then showNote("rules") elseif msg == "__DIARY3__" then showNote("log") end
end)
UIS.InputBegan:Connect(function(i, gp)
	if gp or not L3() then return end
	if i.KeyCode == Enum.KeyCode.M then
		if note.Visible then note.Visible = false elseif plr:GetAttribute("HasRules3") then showNote("rules") end
	end
end)
local function hookChar(char)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c.Name == "NoiQuyRung" then showNote("rules") end
		if c:IsA("Tool") and c.Name == "NhatKyKiemLam" then showNote("log") end
	end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") and (c.Name == "NoiQuyRung" or c.Name == "NhatKyKiemLam") then note.Visible = false end end)
end
if plr.Character then hookChar(plr.Character) end
plr.CharacterAdded:Connect(hookChar)

-- ===== NÍN THỞ (Vườn nấm): giữ B, hoặc giữ nút trên màn hình (điện thoại) =====
local holding = false
local function setBreath(on)
	if on == holding then return end
	holding = on L3Act:FireServer("Breath", on)
end
UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.B and L3() then setBreath(true) end end)
UIS.InputEnded:Connect(function(i) if i.KeyCode == Enum.KeyCode.B then setBreath(false) end end)
local breathBtn = Instance.new("TextButton", gui) breathBtn.AnchorPoint = Vector2.new(1, 1) breathBtn.Position = UDim2.new(1, -110, 1, -130)
breathBtn.Size = UDim2.fromOffset(110, 110) breathBtn.Text = "🫁\nNÍN THỞ" breathBtn.Font = Enum.Font.GothamBlack breathBtn.TextSize = 16
breathBtn.TextColor3 = Color3.new(1, 1, 1) breathBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 75) breathBtn.BackgroundTransparency = 0.2 breathBtn.Visible = false
Instance.new("UICorner", breathBtn).CornerRadius = UDim.new(1, 0)
breathBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then setBreath(true) end end)
breathBtn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then setBreath(false) end end)

-- ===== NÓI CHUYỆN (TextChatService) → báo server (luật Cây cổ thụ) =====
pcall(function()
	TextChatService.SendingMessage:Connect(function() if L3() and myRoom() == "Room3" then L3Act:FireServer("Chat") end end)
end)

-- ===== HUD MỤC TIÊU TẦNG 3 =====
local panel = Instance.new("Frame", gui) panel.AnchorPoint = Vector2.new(1, 0) panel.Position = UDim2.new(1, -12, 0, 52) panel.Size = UDim2.fromOffset(280, 108)
panel.BackgroundColor3 = Color3.fromRGB(12, 20, 12) panel.BackgroundTransparency = 0.45 panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local rows = {} for i = 1, 4 do rows[i] = txt(panel, UDim2.fromOffset(10, 4 + (i - 1) * 20), UDim2.new(1, -20, 0, 20), "", 14) end
rows[4].TextColor3 = Color3.fromRGB(255, 215, 140) rows[4].Size = UDim2.new(1, -20, 0, 40) rows[4].TextYAlignment = Enum.TextYAlignment.Top
local status = txt(gui, UDim2.new(0, 16, 1, -230), UDim2.fromOffset(380, 60), "", 14, Enum.Font.GothamBold) status.TextYAlignment = Enum.TextYAlignment.Bottom
local escL = txt(gui, UDim2.new(0.5, -350, 0.2, 0), UDim2.fromOffset(700, 50), "", 28, Enum.Font.GothamBlack) escL.TextXAlignment = Enum.TextXAlignment.Center escL.TextColor3 = Color3.fromRGB(255, 80, 80)
local roomState = txt(gui, UDim2.new(0.5, -300, 0.2, 54), UDim2.fromOffset(600, 30), "", 20, Enum.Font.GothamBold) roomState.TextXAlignment = Enum.TextXAlignment.Center
local roomL = txt(gui, UDim2.new(0.5, -200, 0, 30), UDim2.fromOffset(400, 20), "", 13) roomL.TextXAlignment = Enum.TextXAlignment.Center roomL.TextTransparency = 0.3
local ROOM_VN = {Lobby = "Lửa trại (an toàn)", Room1 = "Rừng đom đóm", Room2 = "Đầm sương mù", Room3 = "Cây cổ thụ có mắt",
	Room4 = "Hang gỗ mục", Room5 = "Vườn nấm phát sáng", Hall = "Lối mòn"}

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
-- dấu hiệu ĐANG xuất hiện: viền sáng nhấp nháy (không xuyên tường) — dễ nhận ra cho người chơi 12+
local liveHL = {}
do
	local SIGNS = {Arrow = IX:WaitForChild("ArrowFlies"), Reflection = IX:WaitForChild("Clue_Reflection"), Carving = IX:WaitForChild("EyeTree"),
		Backpack = IX:WaitForChild("Clue_Backpack"), Shoe = IX:WaitForChild("Clue_Shoe")}
	for k, inst in pairs(SIGNS) do
		local h = Instance.new("Highlight") h.Adornee = inst h.FillColor = Color3.fromRGB(200, 170, 255) h.OutlineColor = Color3.fromRGB(235, 220, 255)
		h.DepthMode = Enum.HighlightDepthMode.Occluded h.Enabled = false h.Parent = gui liveHL[k] = h
	end
	RunService.RenderStepped:Connect(function()
		local k2 = (math.sin(os.clock() * 3) + 1) / 2
		for k, h in pairs(liveHL) do
			local live = L3() and ST:GetAttribute("SignLive_" .. k) == true and not ST:GetAttribute("Sign_" .. k)
			h.Enabled = live
			if live then h.FillTransparency = 0.75 + 0.15 * k2 h.OutlineTransparency = 0.1 + 0.5 * k2 end
		end
	end)
end

-- ===== NHÌN XUỐNG NƯỚC (Đầm sương): camera chúc xuống quá 3 giây =====
local downT = 0
local lastSent = 0
RunService.Heartbeat:Connect(function(dt)
	if not L3() or myRoom() ~= "Room2" or plr:GetAttribute("Dreaming") then downT = 0 return end
	local lv = workspace.CurrentCamera.CFrame.LookVector
	if lv.Y < -0.75 then downT += dt else downT = math.max(0, downT - dt * 2) end
	if downT >= 3 and os.clock() - lastSent > 4 then lastSent = os.clock() downT = 0 L3Act:FireServer("LookDown") end
end)

local function secsTo(attr) return math.max(0, math.ceil((ST:GetAttribute(attr) or 0) - now())) end
RunService.RenderStepped:Connect(function()
	local on = L3()
	panel.Visible = on status.Visible = on roomL.Visible = on roomState.Visible = on
	local ph = ST:GetAttribute("Phase") or ""
	endF.Visible = on and (ph == "Win" or ph == "Lose")
	if endF.Visible then
		local t = ST:GetAttribute("RoundTime") or 0
		local tstr = string.format("%d:%02d", t // 60, t % 60)
		if ph == "Win" then e1.Text = "QUA TẦNG 3" e1.TextColor3 = Color3.fromRGB(190, 255, 170) e2.Text = "Cậu bé Minh cuối cùng cũng tìm được đường về lều...\nThời gian: " .. tstr
		else e1.Text = "LẠC MÃI TRONG RỪNG" e1.TextColor3 = Color3.fromRGB(255, 90, 110) e2.Text = "Khu rừng giữ các em lại.\nThời gian trụ được: " .. tstr .. "\n\nChơi lại Tầng 3 sau vài giây..." end
	end
	local room = myRoom()
	breathBtn.Visible = on and room == "Room5" and UIS.TouchEnabled
	if not on then note.Visible = false for _, h in pairs(hl) do h.Enabled = false end if holding then setBreath(false) end return end
	local signs, shards = ST:GetAttribute("Signs") or 0, ST:GetAttribute("Shards") or 0
	rows[1].Text = (signs >= 3 and "☑ " or "☐ ") .. "Điều kỳ lạ trong rừng  " .. signs .. "/3"
	rows[2].Text = (ST:GetAttribute("Cleansed") and "☑ " or "☐ ") .. "Thả la bàn gãy xuống đầm"
	rows[3].Text = (shards >= 3 and "☑ " or "☐ ") .. "Mảnh Neo Thức  " .. shards .. "/3"
	local obj
	if not plr:GetAttribute("HasRules3") then obj = "→ Nhặt Nội quy trên gốc cây cạnh lửa trại"
	elseif ph == "TrinhSat" then obj = "→ Tìm 3 điều kỳ lạ (đọc Nhật ký kiểm lâm để biết KHI NÀO)"
	elseif ph == "TruyNguyen" then obj = "→ Về lửa trại, chọn đáp án trên phiến đá"
	elseif ph == "ThanhTay" then
		local c = ST:GetAttribute("CompassCarrier") or ""
		obj = c == "" and "→ Lấy la bàn gãy dưới gốc Cây cổ thụ" or ("→ Mang la bàn tới giữa Đầm sương mù · " .. secsTo("CompassDeadline") .. "s")
	elseif ph == "Neo" then obj = shards < 3 and "→ Tìm Mảnh Neo (Hang · Vườn nấm · Rừng đom đóm)" or "→ Đặt Mảnh Neo vào Bệ Neo cạnh lửa trại"
	elseif ph == "Gate" then obj = plr:GetAttribute("Escaped") and "→ Đã qua Cổng" or "→ VỀ LỬA TRẠI, bước qua CỔNG GỖ!"
	else obj = "" end
	rows[4].Text = obj
	roomL.Text = ROOM_VN[room] or ""
	-- trạng thái phòng đang đứng (nhắc luật đang có hiệu lực)
	local rs, rc = "", Color3.fromRGB(220, 230, 210)
	if ph ~= "Gate" then
		if room == "Room1" and ST:GetAttribute("FireflyOn") == false then rs, rc = "🌑 ĐOM ĐÓM ĐÃ TẮT — ĐỨNG YÊN!", Color3.fromRGB(255, 220, 120)
		elseif room == "Room2" and ST:GetAttribute("ChimeRing") then rs, rc = "🔔 CHUÔNG GIÓ ĐANG VANG — ĐỨNG TRÊN ĐÁ!", Color3.fromRGB(170, 210, 255)
		elseif room == "Room3" and ST:GetAttribute("EyeOpen") then rs, rc = "👁 CÂY ĐANG MỞ MẮT — QUAY LƯNG LẠI!", Color3.fromRGB(255, 90, 90)
		elseif room == "Room4" and ST:GetAttribute("KnockState") == "near" then rs, rc = "✊ TIẾNG GÕ ĐANG TỚI GẦN...", Color3.fromRGB(255, 170, 110)
		elseif room == "Room4" and ST:GetAttribute("KnockState") == "pass" then rs, rc = "✊ KẺ GÕ ĐANG ĐI NGANG!", Color3.fromRGB(255, 90, 90)
		elseif room == "Room5" and ST:GetAttribute("SporeGlow") then rs, rc = "🍄 BÀO TỬ! NÍN THỞ (giữ B)", Color3.fromRGB(120, 255, 220) end
	end
	roomState.Text = rs roomState.TextColor3 = rc
	-- trạng thái cá nhân
	local st = {}
	if holding then table.insert(st, "🫁 Đang nín thở") end
	if (ST:GetAttribute("CompassCarrier") or "") == plr.Name then table.insert(st, "🧭 Đang cầm LA BÀN GÃY (đi chậm)") end
	if room == "Room4" and plr:GetAttribute("KnockNeed") then table.insert(st, "✊ Bạn đã gõ vào tảng đá: " .. (plr:GetAttribute("KnockGiven") or 0) .. " lần") end
	status.Text = table.concat(st, "\n")
	-- đếm ngược thoát
	if ph == "Gate" and not plr:GetAttribute("Escaped") then
		local left = math.ceil((ST:GetAttribute("EscapeDeadline") or 0) - now())
		escL.Text = left > 0 and ("⚠ RỪNG KHÉP LỐI SAU " .. left .. "s — CHẠY VỀ LỬA TRẠI! ⚠") or "Lối đã khép — bước qua CỔNG GỖ!"
	else escL.Text = "" end
	-- Thấu Thị: Nhìn Xuyên (chỉ soi PHÒNG đang đứng lúc dùng; cả nhóm thấy nhờ Đánh Dấu)
	local mineSight = plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > now()
	local teamSight = (ST:GetAttribute("SeerMarkUntil") or 0) > now()
	local sight = mineSight or teamSight
	local sRoom = mineSight and (plr:GetAttribute("SightRoom") or room) or ST:GetAttribute("SeerMarkRoom")
	local SAFE, BAD, GOLD = Color3.fromRGB(120, 230, 255), Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 215, 110)
	mark("path1", IX:FindFirstChild("Room1Path"), sight and sRoom == "Room1", SAFE)
	mark("grass1", IX:FindFirstChild("Room1Grass"), sight and sRoom == "Room1", BAD)
	mark("shard1", IX:FindFirstChild("AnchorShard1"), sight and sRoom == "Room1", GOLD)
	mark("stones2", IX:FindFirstChild("Stones"), sight and sRoom == "Room2", SAFE)
	mark("bridge2", IX:FindFirstChild("Bridge"), sight and sRoom == "Room2", SAFE)
	mark("drop2", IX:FindFirstChild("DropPoint"), sight and sRoom == "Room2" and ph == "ThanhTay", GOLD)
	mark("tree3", IX:FindFirstChild("EyeTree"), sight and sRoom == "Room3", BAD)
	mark("roots3", IX:FindFirstChild("Roots"), sight and sRoom == "Room3", BAD)
	mark("compass3", IX:FindFirstChild("Compass"), sight and sRoom == "Room3" and ph == "ThanhTay", GOLD)
	mark("knock4", IX:FindFirstChild("Knocker"), sight and sRoom == "Room4", BAD)
	mark("niche4", IX:FindFirstChild("Niches"), sight and sRoom == "Room4", SAFE)
	mark("white5", IX:FindFirstChild("WhiteRings"), sight and sRoom == "Room5", SAFE)
	mark("red5", IX:FindFirstChild("RedRings"), sight and sRoom == "Room5", BAD)
	local cp = ST:GetAttribute("CorrectPuzzle")
	mark("puzzle", cp and IX:FindFirstChild("Puzzle" .. cp), sight and sRoom == "Lobby" and ph == "TruyNguyen", GOLD)
	-- Thấu Thị ở hang: biết số tiếng gõ đúng
	if sight and sRoom == "Room4" and room == "Room4" and plr:GetAttribute("KnockNeed") then
		status.Text = status.Text .. (status.Text ~= "" and "\n" or "") .. "👁 Số tiếng gõ đúng: " .. plr:GetAttribute("KnockNeed")
	end
	if note.Visible and noteMode == "rules" then renderNote() end
end)

-- ===== ĐOM ĐÓM LƠ LỬNG (chỉ hiệu ứng phía client) =====
task.spawn(function()
	local flies = IX:WaitForChild("Fireflies"):GetChildren()
	local base = {} for i, f in ipairs(flies) do base[i] = f.Position end
	local t = 0
	while true do
		t += task.wait(0.05)
		if L3() and myRoom() == "Room1" then
			for i, f in ipairs(flies) do
				if f.Parent then f.CFrame = CFrame.new(base[i] + Vector3.new(math.sin(t * 0.7 + i) * 1.2, math.sin(t * 1.3 + i * 2) * 0.6, math.cos(t * 0.6 + i) * 1.2)) end
			end
		end
	end
end)

-- ===== MAP ĐƯỢC LÀM MỚI =====
-- Mỗi lần vào màn, server xóa map cũ và clone map mới: chạy lại script này để gắn với map mới.
local myMap = map
local reloading = false
workspace.ChildAdded:Connect(function(c)
	if reloading or c.Name ~= "DreamMap3" or c == myMap then return end
	reloading = true
	task.spawn(function()
		while myMap and myMap.Parent == workspace and myMap.Name == "DreamMap3" do task.wait() end
		if holding then setBreath(false) end
		local s = script:Clone() s.Parent = script.Parent script:Destroy()
	end)
end)
