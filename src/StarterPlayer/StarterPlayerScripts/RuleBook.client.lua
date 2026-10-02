-- So Tay Giac Mong: tu mo khi moi vao, mo lai bang phim N hoac cam cuon so (Tool SoTay)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local function pushHint() end

local ROLE_PAGE = {
	Seer = {"Vai của bạn: THẤU THỊ", "Bạn biết cái đang ẨN.\n\n• [Q] NHÌN XUYÊN (−3, 12 giây, hồi 18 giây): soi bí mật của PHÒNG đang đứng. Mọi thứ bạn thấy hiện cho CẢ NHÓM thêm 15 giây.\n• Nơi không có luật: thấy mọi đồng đội và hiểm nguy trên tầng, lộ ra dòng nội quy NÓI DỐI.\n\n• Nội tại MẮT ĐÊM: trong 25 bước luôn thấy xuyên tường hiểm nguy và đồ vật. Tỉnh táo tối đa 100.\n\nBấm V để xem lại."},
	Healer = {"Vai của bạn: CHỮA LÀNH", "Bạn dỗ dịu và GÁNH HỘ.\n\n• [Q] BÀI RU (−5, hồi 30 giây): mọi người trong phòng +25, Bình tâm 12 giây, kéo người hòa mộng dậy. 3 giây sau đó sát thương chỉ còn một nửa.\n\n• Nội tại SỢI CHỈ ĐỎ: gánh một nửa mỗi lần phạt của đồng đội được nối, dù khác phòng. Đứng cạnh ai 2 giây để nối.\n• Đứng gần bạn là hồi Tỉnh táo. Tỉnh táo tối đa 100.\n\nBấm V để xem lại."},
	Anchor = {"Vai của bạn: NGƯỜI NEO", "Bạn DỪNG THỜI GIAN.\n\n• [Q] CẮM NEO (−8, 5 giây, hồi 40 giây): mọi thứ trong PHÒNG đứng yên như lúc bấm. Neo cả trạng thái xấu, nên chọn đúng lúc!\n• Khi Cổng mở: CHỐNG CỬA, cửa đóng chậm thêm 5 giây (1 lần mỗi tầng).\n\n• Nội tại CHÂN NEO: không bao giờ bị đơ. Tỉnh táo tối đa 110.\n\nBấm V để xem lại."},
	Diviner = {"Vai của bạn: NHÀ BÓI TOÁN", "Bạn biết điều SẮP TỚI.\n\n• [Q] GIEO QUẺ (−5, hồi 30 giây): lá quẻ báo sự kiện KẾ TIẾP của phòng đang đứng.\n\n• Nội tại ĐIỀM BÁO: khoảng 3 giây trước khi phòng bạn đang đứng sắp đổi trạng thái, màn hình rung nhẹ (tối đa 1 lần mỗi 60 giây). Tỉnh táo tối đa 100.\n\nBấm V để xem lại."},
}

local PAGES = {
	{"SỔ TAY GIẤC MỘNG", "Bạn đã bị kéo vào giấc mộng của một thực thể đang ngủ.\n\nTầng mộng này đã bị ô nhiễm. Muốn thoát ra, cả nhóm phải:\n\n1. TRINH SÁT: tìm 3 Dấu Hiệu Bất Thường (giữ E để ghi nhận).\n2. TRUY NGUYÊN: ghép các dấu hiệu trên Bảng Ghi Nhớ để tìm ra Nguồn Ô Nhiễm.\n3. THANH TẨY: phá hủy Nguồn Ô Nhiễm.\n4. Gom đủ 3 MẢNH NEO THỨC (mảnh 1: làm xong yêu cầu của cô giáo · mảnh 2–3: tìm trong Thư viện và Phòng nhạc), đặt vào Bệ Neo ở hành lang để mở Cổng Tầng.\n\nCổng chỉ mở 60 giây. Ai không kịp vào sẽ bị bỏ lại."},
	{"TỈNH TÁO", "Mỗi người có một thanh Tỉnh táo. Bạn sẽ không thấy con số, chỉ thấy viền màn hình tối dần.\n\nMẤT tỉnh táo khi:\n• Bị thứ gì đó trong mơ chạm vào\n• Thấy đồng đội gục ngã\n• Dùng kỹ năng\n• Phá vỡ luật của tầng\n\nHỒI tỉnh táo khi:\n• Đứng trong ánh đèn\n• Đứng cạnh đồng đội\n• Thanh Tẩy thành công\n\nCàng mất trí, bạn càng nghe và thấy những thứ không có thật."},
	{"HÒA MỘNG", "Khi Tỉnh táo về 0, bạn HÒA MỘNG: thành bóng hồn mờ nhạt, bay được nhưng không chạm được gì.\n\nBạn chưa thua. Bay theo đồng đội và chờ Chữa Lành đến gần hát Bài Ru để kéo bạn trở lại.\n\nNếu CẢ NHÓM cùng hòa mộng, giấc mơ nuốt chửng tất cả — ván chơi RESET TOÀN BỘ, làm lại từ đầu (kể cả nhặt lại tờ nội quy)."},
	{"MỖI TẦNG CÓ LUẬT RIÊNG", "Tầng mộng không nói luật của nó ra. Hãy quan sát:\nnhững thứ trong phòng đang làm gì, đang NHÌN về đâu, chữ viết để lại nói gì.\n\nPhá luật sẽ bị phạt. Phá luật khi có thứ gì đó đang săn bạn... còn tệ hơn.\n\n— Trang giấy bị xé, chữ nguệch ngoạc —\n\"...trong lớp phải LUÔN NGHE LỜI cô giáo. Cô nhờ gì thì phải làm cho bằng được...\"\n\n\"...khi cô quay xuống nhìn, đừng ai nhúc nhích...\"\n\n\"...mình đã để lại cuốn NHẬT KÝ trên bàn đọc trong thư viện. Nó ghi lại KHI NÀO những thứ lạ xuất hiện...\""},
	"ROLE",
	{"ĐIỀU KHIỂN", "WASD + chuột: di chuyển / nhìn\nE (giữ): tương tác, ghi nhận dấu hiệu, nhặt đồ\nF: mở / đóng cửa\nQ hoặc nút tròn dưới màn hình: kỹ năng (tác dụng lên phòng đang đứng)\n1–9: chọn đồ trên thanh đồ, CLICK chuột để dùng (Bình Hồi +25 Tỉnh táo)\nM: đọc lại nội quy phòng\nH: bảng luật tóm tắt\nZ / X / C: Ping \"Ở đây\" / \"Nguy hiểm\" / \"Dấu hiệu\" tại chỗ con trỏ\nN: mở / đóng Sổ Tay này\n\nGiấc mơ này không thể vượt qua một mình.\nHãy nói cho nhau biết mình thấy gì."},
}

local gui = Instance.new("ScreenGui") gui.Name = "RuleBookGui" gui.ResetOnSpawn = false gui.DisplayOrder = 10 gui.Parent = plr:WaitForChild("PlayerGui")
local dim = Instance.new("Frame", gui) dim.Size = UDim2.fromScale(1, 1) dim.BackgroundColor3 = Color3.new(0, 0, 0) dim.BackgroundTransparency = 0.45 dim.BorderSizePixel = 0
local book = Instance.new("Frame", dim) book.AnchorPoint = Vector2.new(0.5, 0.5) book.Position = UDim2.fromScale(0.5, 0.5) book.Size = UDim2.fromOffset(560, 460)
book.BackgroundColor3 = Color3.fromRGB(226, 212, 180) book.BorderSizePixel = 0
Instance.new("UICorner", book).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", book) stroke.Thickness = 6 stroke.Color = Color3.fromRGB(90, 40, 40)
local cons = Instance.new("UISizeConstraint", book) cons.MaxSize = Vector2.new(560, 460)
local sc = Instance.new("UIScale", book)
local function fit() local v = workspace.CurrentCamera.ViewportSize sc.Scale = math.min(1, v.X / 600, v.Y / 500) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

local title = Instance.new("TextLabel", book) title.BackgroundTransparency = 1 title.Position = UDim2.fromOffset(24, 16) title.Size = UDim2.new(1, -48, 0, 40)
title.Font = Enum.Font.Antique title.TextSize = 30 title.TextColor3 = Color3.fromRGB(70, 25, 25)
local body = Instance.new("TextLabel", book) body.BackgroundTransparency = 1 body.Position = UDim2.fromOffset(28, 64) body.Size = UDim2.new(1, -56, 1, -130)
body.Font = Enum.Font.Garamond body.TextSize = 21 body.TextColor3 = Color3.fromRGB(40, 30, 25) body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top
local pageL = Instance.new("TextLabel", book) pageL.BackgroundTransparency = 1 pageL.Position = UDim2.new(0.5, -60, 1, -50) pageL.Size = UDim2.fromOffset(120, 34)
pageL.Font = Enum.Font.Garamond pageL.TextSize = 18 pageL.TextColor3 = Color3.fromRGB(90, 70, 60)

local function btn(text, pos)
	local b = Instance.new("TextButton", book) b.Position = pos b.Size = UDim2.fromOffset(120, 34) b.Text = text
	b.Font = Enum.Font.GothamBold b.TextSize = 16 b.TextColor3 = Color3.fromRGB(240, 225, 200) b.BackgroundColor3 = Color3.fromRGB(90, 40, 40) b.AutoButtonColor = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end
local prev = btn("◀ Trước", UDim2.new(0, 24, 1, -50))
local nextB = btn("Tiếp ▶", UDim2.new(1, -144, 1, -50))
local close = Instance.new("TextButton", book) close.Size = UDim2.fromOffset(34, 34) close.Position = UDim2.new(1, -44, 0, 12) close.Text = "✕"
close.Font = Enum.Font.GothamBold close.TextSize = 20 close.BackgroundTransparency = 1 close.TextColor3 = Color3.fromRGB(90, 40, 40)

local page = 1
local function render()
	local p = PAGES[page]
	if p == "ROLE" then p = ROLE_PAGE[plr:GetAttribute("Role")] or {"VAI TRÒ", "Đang chờ nhận vai..."} end
	title.Text = p[1] body.Text = p[2]
	pageL.Text = page .. " / " .. #PAGES
	prev.Visible = page > 1
	nextB.Text = page < #PAGES and "Tiếp ▶" or "Đóng sổ"
end
nextB.Modal = true -- giai phong chuot khi dang mo so (camera goc nhin thu nhat)
local function setOpen(on) dim.Visible = on if on then render() end end
prev.MouseButton1Click:Connect(function() page = math.max(1, page - 1) render() end)
nextB.MouseButton1Click:Connect(function() if page < #PAGES then page += 1 render() else setOpen(false) end end)
close.MouseButton1Click:Connect(function() setOpen(false) end)
plr:GetAttributeChangedSignal("Role"):Connect(function() if dim.Visible then render() end end)

UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.N then setOpen(not dim.Visible) end
end)

-- Cam cuon so (Tool) -> mo so
local showAllRulesRef
local showDiaryRef
local note
local function hookChar(char)
	char.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") and (c.Name == "ToNoiQuy" or c.Name == "NhatKy" or c.Name == "SoTrucDem") then note.Visible = false end
		if c:IsA("Tool") and c.Name == "SoTay" then setOpen(false) end
	end)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c.Name == "SoTay" then page = 1 setOpen(true) end
		if c:IsA("Tool") and c.Name == "ToNoiQuy" and showAllRulesRef then showAllRulesRef() end
		if c:IsA("Tool") and c.Name == "NhatKy" and showDiaryRef then showDiaryRef() end
		if c:IsA("Tool") and c.Name == "SoTrucDem" and showDiaryRef then showDiaryRef(2) end
	end)
end
if plr.Character then hookChar(plr.Character) end
plr.CharacterAdded:Connect(hookChar)

-- ===== TO GIAY LUAT PHONG: nhan khi vao phong lan dau, M de doc lai =====
local ROOM_NOTES = {
	Class = {"PHÒNG 1 — LỚP HỌC", "NỘI QUY LỚP HỌC\n\n1. Khi cô quay xuống nhìn lớp, KHÔNG ĐƯỢC DI CHUYỂN.\n\n2. Cô nhờ việc gì phải làm xong trước khi hết giờ (được phép ra khỏi lớp để làm).\n\n3. Khi cô ĐIỂM DANH, người được gọi phải về một chiếc BÀN và trả lời “Có ạ” (E) trong 8 giây. Người được gọi được phép đi lại lúc đó.\n\n✎ \"...đừng bao giờ trả lời cho một cái tên mà cả nhóm không ai nhận...\"\n\n(Chỉ có hiệu lực trong lớp học.)"},
	West = {"PHÒNG 2 — THƯ VIỆN", "NỘI QUY THƯ VIỆN\n\n1. Không được NHẢY.\n\n2. Không Ping (tiếng động).\n\n3. Không đứng SÁT NHAU thì thầm quá 3 giây.\n\n✎ \"...bà thủ thư không nhìn thấy gì, nhưng bà NGHE được tất cả. Khi bà đến gần — đứng yên...\"\n\n(Chỉ có hiệu lực trong thư viện.)"},
	East = {"PHÒNG 3 — PHÒNG NHẠC", "NỘI QUY PHÒNG NHẠC\n\n1. Khi nhạc còn vang, KHÔNG ĐỨNG YÊN quá 4 giây.\n\n2. Khi nhạc TẮT (đàn chuyển đỏ), phải ĐỨNG YÊN cho tới khi nhạc vang lại.\n\n3. Không được CHẠM VÀO ĐÀN piano.\n\n✎ \"...con rối chỉ nhảy khi nhạc còn vang. Đừng để nó mời bạn nhảy cùng...\"\n\n(Chỉ có hiệu lực trong phòng nhạc.)"},
}
-- Mỗi ván có 1 dòng viết tay NÓI DỐI (server chọn LieIndex1). Thấu Thị dùng Nhìn Xuyên sẽ thấy nó đỏ lên.
local LIES1 = {
	{"Class", "\"...cô không để ý người đứng sát bàn — đứng cạnh bàn thì cứ đi lại thoải mái...\""},
	{"West", "\"...bà thủ thư nghễnh ngãng một bên tai — thì thầm sát nhau thì bà không nghe thấy...\""},
	{"East", "\"...nhạc vừa tắt thì CHẠY ngay ra cửa — con rối chỉ bắt người đứng yên...\""},
	{"Class", "\"...trả lời thay cho bạn thì cô không bao giờ nhận ra giọng đâu...\""},
}
local State1 = game:GetService("ReplicatedStorage"):WaitForChild("GameState")
local seen = {}
note = Instance.new("Frame", gui) note.AnchorPoint = Vector2.new(0.5, 0.5) note.Position = UDim2.fromScale(0.5, 0.5) note.Size = UDim2.fromOffset(520, 620)
note.BackgroundColor3 = Color3.fromRGB(238, 230, 205) note.BorderSizePixel = 0 note.Rotation = -2 note.Visible = false
local ns = Instance.new("UIStroke", note) ns.Thickness = 2 ns.Color = Color3.fromRGB(150, 130, 100)
local nsc = Instance.new("UIScale", note)
local function fitN() local v = workspace.CurrentCamera.ViewportSize nsc.Scale = math.min(1, v.X / 560, v.Y / 660) end fitN()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitN)
local nTitle = Instance.new("TextLabel", note) nTitle.BackgroundTransparency = 1 nTitle.Position = UDim2.fromOffset(20, 14) nTitle.Size = UDim2.new(1, -40, 0, 36)
nTitle.Font = Enum.Font.Antique nTitle.TextSize = 26 nTitle.TextColor3 = Color3.fromRGB(110, 20, 20)
local nBody = Instance.new("TextLabel", note) nBody.BackgroundTransparency = 1 nBody.Position = UDim2.fromOffset(24, 56) nBody.Size = UDim2.new(1, -48, 1, -110)
nBody.Font = Enum.Font.Garamond nBody.TextSize = 17 nBody.TextColor3 = Color3.fromRGB(40, 30, 25) nBody.TextWrapped = true
nBody.TextXAlignment = Enum.TextXAlignment.Left nBody.TextYAlignment = Enum.TextYAlignment.Top
local nBtn = Instance.new("TextButton", note) nBtn.Size = UDim2.fromOffset(160, 34) nBtn.Position = UDim2.new(0.5, -80, 1, -48) nBtn.Text = "Đã hiểu (M để đọc lại)"
nBtn.Font = Enum.Font.GothamBold nBtn.TextSize = 13 nBtn.TextColor3 = Color3.fromRGB(240, 225, 200) nBtn.BackgroundColor3 = Color3.fromRGB(110, 20, 20) nBtn.Modal = true
Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 6)
nBtn.MouseButton1Click:Connect(function() note.Visible = false end)
local function showNote(room)
	local n = ROOM_NOTES[room] if not n then return end
	nBody.TextSize = 17 nTitle.Text = n[1] nBody.Text = n[2] note.Visible = true
end
local rulesOpen = false
local function esc(t) return (t:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function showAllRules()
	local lie = LIES1[State1:GetAttribute("LieIndex1") or 0]
	local now = workspace:GetServerTimeNow()
	local sight = (plr:GetAttribute("Role") == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > now and plr:GetAttribute("SightRoom") == "Hall")
		or ((State1:GetAttribute("SeerMarkUntil") or 0) > now and State1:GetAttribute("SeerMarkRoom") == "Hall")
	local parts = {}
	for _, k in ipairs({"Class", "West", "East"}) do
		local n = ROOM_NOTES[k]
		local body = n[2]:gsub("\n%(Chỉ có hiệu lực[^%)]*%)", ""):gsub("NỘI QUY [^\n]*\n\n", "")
		body = esc(body):gsub("\n\n+", "\n"):gsub("^\n+", "")
		if lie and lie[1] == k then
			local line = "✎ " .. esc(lie[2])
			body = body:gsub("\n$", "") .. "\n" .. (sight and ('<font color="#C01818"><b>' .. line .. '</b></font>') or line) .. "\n"
		end
		table.insert(parts, "<b>【" .. n[1] .. "】</b>\n" .. body)
	end
	nBody.RichText = true nBody.TextSize = 17
	nTitle.Text = "NỘI QUY TẦNG — LỚP HỌC VỠ"
	nBody.Text = table.concat(parts, "\n") .. "\nMỗi luật CHỈ có hiệu lực khi bạn ở trong phòng đó. Hành lang không có luật.\n<i>Chữ ✎ là học sinh cũ viết tay — có một dòng NÓI DỐI.</i>\n<i>Người viết để lại cuốn NHẬT KÝ trên bàn đọc trong Thư viện: nó ghi KHI NÀO những điều lạ xuất hiện.</i>"
	note.Visible = true rulesOpen = true
end
task.spawn(function() -- cập nhật màu dòng nói dối khi đang mở
	while true do task.wait(0.5) if note.Visible and rulesOpen then showAllRules() end end
end)
note:GetPropertyChangedSignal("Visible"):Connect(function() if not note.Visible then rulesOpen = false end end)
showAllRulesRef = showAllRules
-- ===== NHẬT KÝ HỌC SINH CŨ (nhặt ở bàn đọc Thư viện) =====
local DIARY = "<i>Mấy trang cuối, nét chữ run run...</i>\n\n"
	.. "<b>Thứ Hai.</b> Chữ trên bảng tự đổi. Nhưng chỉ lúc cô QUAY XUỐNG nhìn bọn mình — lúc ai cũng phải đứng im. Lần sau mình sẽ đứng sẵn cạnh bảng, chờ cô quay lại.\n\n"
	.. "<b>Thứ Ba.</b> Ở phòng nhạc, lúc đàn IM BẶT, mình nghe có người đọc bài ở góc phòng. Tiếng đọc còn văng vẳng một lúc sau khi nhạc vang lại.\n\n"
	.. "<b>Thứ Tư.</b> Tiết đầu tiên, cô lại điểm danh một cái tên không ai trong lớp có. Lần nào cũng vào giữa tiết. Hôm nay cả lớp IM LẶNG... và bạn ấy ngồi ở bàn cuối góc lớp.\nĐừng trả lời thay bạn ấy.\n\n"
	.. "<b>Thứ Năm.</b> Mình không nhớ tên bạn ấy nữa.\nMình không nhớ tên mình nữa."
local DIARY2 = "<i>Sổ giao ca — Y tá trực đêm, khoa Hồi Sức. Mấy trang cuối nhòe mực...</i>\n\n"
	.. "<b>02:10.</b> Đèn mổ vừa TẮT sau ca mổ. Máy đo nhịp tim đường PHẲNG, vậy mà vẫn kêu bíp bíp. Chỉ một lúc thôi. Tôi đứng ngay cạnh máy mới nghe rõ.\n\n"
	.. "<b>02:40.</b> Bảng số ở Phòng Đóng Phí gọi “SỐ 00”. Tấm GƯƠNG cạnh quầy thì thầm, trong gương tờ hóa đơn in tên TÔI. Bảng đổi số là gương lại bình thường.\n\n"
	.. "<b>03:15.</b> Lão gác nhà xác tắt đèn đếm xác. Đèn bật lại thì TỦ SỐ 13 nóng hổi, như có người vừa nằm trong đó.\n\n"
	.. "<b>03:33.</b> Giường 13 không có ai. Nhưng hồ sơ ghi bệnh nhân vẫn còn sống."
local function showDiary(which)
	nBody.RichText = true rulesOpen = false nBody.TextSize = 21
	nTitle.Text = which == 2 and "SỔ TRỰC ĐÊM" or "NHẬT KÝ — KHÔNG RÕ TÊN"
	nBody.Text = which == 2 and DIARY2 or DIARY
	note.Visible = true
end
showDiaryRef = showDiary
Remotes.Notify.OnClientEvent:Connect(function(msg) if msg == "__DIARY__" then showDiary() elseif msg == "__DIARY2__" then showDiary(2) end end)
Remotes.Notify.OnClientEvent:Connect(function(msg) if msg == "__SHOW_RULES__" then showAllRules() elseif msg == "__L2RULES__" or msg == "__L3RULES__" or msg == "__DIARY3__" then note.Visible = false end end)
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	-- Tầng 2, 3 có tờ nội quy riêng (Level2Client, Level3Client): M ở đây chỉ để đóng tờ đang mở
	if i.KeyCode == Enum.KeyCode.M and (plr:GetAttribute("Level") or 1) > 1 then note.Visible = false return end
	if i.KeyCode == Enum.KeyCode.M then
		if note.Visible then note.Visible = false
		elseif plr:GetAttribute("HasRules") then showAllRules()
		else pushHint() end
	end
end)

-- Sổ tay không tự mở nữa (bấm N). Tờ nội quy nhặt ở sảnh.
setOpen(false)
