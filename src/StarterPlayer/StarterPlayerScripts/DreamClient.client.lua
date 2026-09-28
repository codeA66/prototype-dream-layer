-- DREAM LAYERS - Client (HUD, Lop Su That, ky nang, ping)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local plr = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local State = RS:WaitForChild("GameState")
local IX = workspace:WaitForChild("DreamMap"):WaitForChild("Interactables")
local cam = workspace.CurrentCamera

local ROLE_NAME = {Seer = "THAU THI", Healer = "CHUA LANH", Anchor = "NGUOI NEO", Diviner = "NHA BOI TOAN"}
local SKILL_NAME = {Seer = "[Q] Nhìn Xuyên (−5 · 8s): soi bí mật của PHÒNG đang đứng", Healer = "[Q] Bài Ru (−5): +20 cả nhóm, Bình tâm 10s, kéo người Hòa Mộng"}
local PHASE_TEXT = {
	TrinhSat = "TRINH SAT - Tim 3 Dau Hieu Bat Thuong",
	TruyNguyen = "TRUY NGUYEN - Xep dau hieu theo gio tren Bang Ghi Nho",
	ThanhTay = "THANH TAY - Mang cuon so den den ban giao vien",
	Neo = "NEO - Gom 3 Manh Neo, dat vao Be Neo o hanh lang",
	Gate = "CONG DA MO - Chay vao cong!",
	Win = "QUA TANG!", Lose = "BI NUOT...",
}

-- ===== GUI =====
do local o = plr:WaitForChild("PlayerGui"):FindFirstChild("DreamHUD") if o then o:Destroy() end local c = Lighting:FindFirstChild("DreamHUD_CC") if c then c:Destroy() end end -- bản cũ của script (trước khi làm mới map)
local gui = Instance.new("ScreenGui") gui.Name = "DreamHUD" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.Parent = plr:WaitForChild("PlayerGui")
local function label(parent, pos, size, text, sizeT)
	local t = Instance.new("TextLabel") t.Parent = parent t.Position = pos t.Size = size t.BackgroundTransparency = 1
	t.TextColor3 = Color3.fromRGB(230, 225, 240) t.TextStrokeTransparency = 0.4 t.Font = Enum.Font.GothamMedium
	t.TextSize = sizeT or 18 t.TextXAlignment = Enum.TextXAlignment.Left t.Text = text or "" t.TextWrapped = true
	return t
end

-- vignette (Sanity khong dung so)
local vig = {}
for i, cfg in ipairs({{UDim2.new(0,0,0,0), UDim2.new(1,0,0.25,0), 90}, {UDim2.new(0,0,0.75,0), UDim2.new(1,0,0.25,0), -90}, {UDim2.new(0,0,0,0), UDim2.new(0.2,0,1,0), 0}, {UDim2.new(0.8,0,0,0), UDim2.new(0.2,0,1,0), 180}}) do
	local f = Instance.new("Frame", gui) f.Position = cfg[1] f.Size = cfg[2] f.BorderSizePixel = 0 f.BackgroundColor3 = Color3.fromRGB(20, 0, 10) f.ZIndex = 0
	local g = Instance.new("UIGradient", f) g.Rotation = cfg[3]
	vig[i] = f
end
local noise = Instance.new("Frame", gui) noise.Size = UDim2.fromScale(1, 1) noise.BackgroundColor3 = Color3.new(1, 1, 1) noise.BackgroundTransparency = 1 noise.BorderSizePixel = 0 noise.ZIndex = 1

local roleL = label(gui, UDim2.fromOffset(16, 50), UDim2.fromOffset(420, 26), "", 22) roleL.Font = Enum.Font.GothamBold
local skillL = label(gui, UDim2.fromOffset(16, 78), UDim2.fromOffset(420, 22), "", 16)
local infoL = label(gui, UDim2.fromOffset(16, 102), UDim2.fromOffset(420, 22), "", 16)
local healL = label(gui, UDim2.fromOffset(16, 128), UDim2.fromOffset(420, 80), "", 16) healL.TextYAlignment = Enum.TextYAlignment.Top healL.TextColor3 = Color3.fromRGB(150, 255, 170)
local helpL = label(gui, UDim2.new(0, 16, 1, -70), UDim2.fromOffset(560, 60), "Chuột: nhìn | Q: kỹ năng | 1–9: chọn đồ, Click: dùng | E: tương tác | F: mở cửa | Z/X/C: Ping | N: sổ tay | M: luật phòng | R: đổi vai (test 1 mình)", 14)
helpL.TextTransparency = 0.3 helpL.TextYAlignment = Enum.TextYAlignment.Bottom
local phaseL = label(gui, UDim2.new(0.5, -300, 0, 50), UDim2.fromOffset(600, 30), "", 22) phaseL.TextXAlignment = Enum.TextXAlignment.Center phaseL.Font = Enum.Font.GothamBold
local cleanseBar = Instance.new("Frame", gui) cleanseBar.Position = UDim2.new(0.5, -150, 0, 86) cleanseBar.Size = UDim2.fromOffset(300, 10) cleanseBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40) cleanseBar.Visible = false
local cleanseFill = Instance.new("Frame", cleanseBar) cleanseFill.BackgroundColor3 = Color3.fromRGB(255, 200, 120) cleanseFill.Size = UDim2.fromScale(0, 1) cleanseFill.BorderSizePixel = 0
local taskL = label(gui, UDim2.new(0.5, -300, 0, 100), UDim2.fromOffset(600, 26), "", 19) taskL.TextXAlignment = Enum.TextXAlignment.Center taskL.TextColor3 = Color3.fromRGB(255, 190, 120) taskL.Font = Enum.Font.GothamBold
-- THANH TỈNH TÁO
local sanFrame = Instance.new("Frame", gui) sanFrame.Position = UDim2.new(0, 16, 1, -120) sanFrame.Size = UDim2.fromOffset(300, 22)
sanFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 30) sanFrame.BorderSizePixel = 0
Instance.new("UICorner", sanFrame).CornerRadius = UDim.new(0, 6)
local sanStroke = Instance.new("UIStroke", sanFrame) sanStroke.Color = Color3.fromRGB(200, 190, 220) sanStroke.Transparency = 0.5
local sanFill = Instance.new("Frame", sanFrame) sanFill.BorderSizePixel = 0 sanFill.Size = UDim2.fromScale(1, 1)
Instance.new("UICorner", sanFill).CornerRadius = UDim.new(0, 6)
local sanText = label(sanFrame, UDim2.fromOffset(8, 0), UDim2.new(1, -16, 1, 0), "", 15) sanText.Font = Enum.Font.GothamBold sanText.ZIndex = 3
local itemL = label(gui, UDim2.new(0, 16, 1, -150), UDim2.fromOffset(420, 24), "", 16) itemL.TextColor3 = Color3.fromRGB(255, 220, 140)
local musicL = label(gui, UDim2.new(0.5, -300, 0, 128), UDim2.fromOffset(600, 26), "", 20) musicL.TextXAlignment = Enum.TextXAlignment.Center musicL.Font = Enum.Font.GothamBold
local ITEM_NAME = {BinhHoi = "Bình Hồi (+25)", ChuongTinh = "Chuông Tỉnh (đuổi quái, −15)", DenNhu = "Đèn Nhử (vùng sáng, −15)"}
local function sanState(s)
	if s >= 80 then return "Tỉnh táo", Color3.fromRGB(110, 200, 255)
	elseif s >= 50 then return "Mơ Hồ", Color3.fromRGB(170, 150, 255)
	elseif s >= 25 then return "Loạn Trí", Color3.fromRGB(230, 120, 200)
	else return "Hoảng Loạn", Color3.fromRGB(255, 60, 60) end
end
-- Nhìn Xuyên: bảng thông tin + highlight xuyên tường
local sightL = label(gui, UDim2.new(1, -330, 0, 140), UDim2.fromOffset(310, 110), "", 17)
sightL.TextColor3 = Color3.fromRGB(255, 240, 160) sightL.TextYAlignment = Enum.TextYAlignment.Top sightL.Font = Enum.Font.GothamBold
local calmL = label(gui, UDim2.new(0, 16, 1, -178), UDim2.fromOffset(300, 24), "", 16) calmL.TextColor3 = Color3.fromRGB(150, 255, 190)
local xray = {}
local function setXray(inst, on, color)
	local h = xray[inst]
	if on and not h then
		h = Instance.new("Highlight") h.Adornee = inst h.FillTransparency = 0.6 h.OutlineColor = color h.FillColor = color
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = gui xray[inst] = h
	elseif not on and h then h:Destroy() xray[inst] = nil end
end
local dreamL = label(gui, UDim2.new(0.5, -300, 0.4, 0), UDim2.fromOffset(600, 60), "BAN DA HOA MONG\nBay theo dong doi, cho Bai Ru...", 28)
dreamL.TextXAlignment = Enum.TextXAlignment.Center dreamL.Visible = false dreamL.TextColor3 = Color3.fromRGB(180, 160, 255)

local feed = Instance.new("Frame", gui) feed.BackgroundTransparency = 1 feed.Position = UDim2.new(0.5, -260, 0, 84) feed.Size = UDim2.fromOffset(520, 70)
local lay = Instance.new("UIListLayout", feed) lay.VerticalAlignment = Enum.VerticalAlignment.Top lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Padding = UDim.new(0, 2)
local order = 0
local function pushMsg(msg, color)
	order += 1
	local kids = {} for _, c in ipairs(feed:GetChildren()) do if c:IsA("TextLabel") then table.insert(kids, c) end end
	if #kids >= 3 then table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end) kids[1]:Destroy() end
	local t = label(feed, UDim2.new(), UDim2.new(1, 0, 0, 18), msg, 14) t.TextXAlignment = Enum.TextXAlignment.Center t.LayoutOrder = order
	t.AutomaticSize = Enum.AutomaticSize.Y t.TextStrokeTransparency = 0.6 if color then t.TextColor3 = color end
	task.delay(5, function() t:Destroy() end)
end
Remotes.Notify.OnClientEvent:Connect(function(msg) if typeof(msg) == "string" and msg:sub(1, 2) ~= "__" then pushMsg(msg) end end) -- "__...__" là lệnh cho giao diện, không hiện ra bảng tin

local cc = Instance.new("ColorCorrectionEffect") cc.Name = "DreamHUD_CC" cc.Parent = Lighting

for _, l in ipairs({roleL, skillL, infoL, helpL, phaseL, taskL, itemL, musicL}) do l.Visible = false end
musicL.Visible = false musicL.TextSize = 14 musicL.Position = UDim2.new(0.5, -300, 1, -118)
healL.TextSize = 14 healL.Position = UDim2.new(0, 16, 1, -250)
-- ===== LOP SU THAT: Thau Thi =====
local shadowBox = Instance.new("SelectionBox") shadowBox.Adornee = IX:WaitForChild("Sign_Shadow") shadowBox.Color3 = Color3.fromRGB(170, 170, 255)
shadowBox.LineThickness = 0.03 shadowBox.SurfaceTransparency = 1 shadowBox.Transparency = 0.75 shadowBox.Parent = gui
local stalkerHL = Instance.new("Highlight") stalkerHL.Adornee = IX:WaitForChild("Stalker") stalkerHL.FillColor = Color3.fromRGB(255, 0, 60) stalkerHL.FillTransparency = 0.5 stalkerHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop stalkerHL.Enabled = false stalkerHL.Parent = gui
local function mkHL(inst, color) local h = Instance.new("Highlight") h.Adornee = inst h.FillColor = color h.OutlineColor = color h.FillTransparency = 0.55 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Enabled = false h.Parent = gui return h end
local libHL = mkHL(IX:WaitForChild("Librarian"), Color3.fromRGB(255, 150, 60))
local pupHL = mkHL(IX:WaitForChild("Puppet"), Color3.fromRGB(255, 80, 160))

local clockGui = Instance.new("BillboardGui") clockGui.Adornee = IX:WaitForChild("Clock") clockGui.Size = UDim2.fromOffset(300, 110) clockGui.StudsOffset = Vector3.new(0, 4, 0) clockGui.AlwaysOnTop = true clockGui.Enabled = false clockGui.Parent = gui
local clockText = label(clockGui, UDim2.new(), UDim2.fromScale(1, 1), "", 20) clockText.TextXAlignment = Enum.TextXAlignment.Center clockText.TextColor3 = Color3.fromRGB(255, 240, 160) clockText.BackgroundTransparency = 0.3 clockText.BackgroundColor3 = Color3.new(0, 0, 0)
local seerHours
Remotes.SeerVision.OnClientEvent:Connect(function(hours, labels)
	local lines = {"KIM GIO THAT:"}
	for i = 1, 3 do table.insert(lines, labels[i] .. " -> " .. hours[i] .. " gio") end
	seerHours = table.concat(lines, "\n")
	clockText.Text = seerHours
end)

-- ===== INPUT =====
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.Q and not plr:GetAttribute("Dancing") then Remotes.UseSkill:FireServer("Skill")
	elseif k == Enum.KeyCode.R then Remotes.UseSkill:FireServer("SwapRole")

	elseif k == Enum.KeyCode.Z or k == Enum.KeyCode.X or k == Enum.KeyCode.C then
		local kind = k == Enum.KeyCode.Z and 1 or (k == Enum.KeyCode.X and 2 or 3)
		local m = UIS:GetMouseLocation()
		local ray = cam:ViewportPointToRay(m.X, m.Y)
		local params = RaycastParams.new() params.FilterDescendantsInstances = {plr.Character} params.FilterType = Enum.RaycastFilterType.Exclude
		local r = workspace:Raycast(ray.Origin, ray.Direction * 120, params)
		Remotes.Ping:FireServer(r and r.Position or (ray.Origin + ray.Direction * 30), kind)
	end
end)

-- ===== VIEW REPORT (luat bang den + Ke Dung Sau Cua) =====
local board = IX:WaitForChild("Blackboard")
local stalker = IX.Stalker
task.spawn(function()
	while true do
		task.wait(0.2)
		local look = cam.CFrame.LookVector
		local toBoard = (board.Position - cam.CFrame.Position)
		local back = Vector3.new(look.X, 0, look.Z).Unit:Dot(Vector3.new(toBoard.X, 0, toBoard.Z).Unit) < -0.2
		local sees = false
		local sp, onScreen = cam:WorldToViewportPoint(stalker.Position)
		if onScreen and sp.Z > 0 then
			local dir = stalker.Position - cam.CFrame.Position
			if look:Dot(dir.Unit) > 0.6 then
				local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
				local ex = {stalker} for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ex, p.Character) end end
				params.FilterDescendantsInstances = ex
				local hit = workspace:Raycast(cam.CFrame.Position, dir, params)
				sees = hit == nil or hit.Instance.CanCollide == false
			end
		end
		Remotes.ViewReport:FireServer(back, sees)
	end
end)

-- ===== ao anh thi tham (Loan Tri) =====
local whispers = {"...quay lai di...", "...no o sau ban...", "...ban co chac do la ban cua ban?...", "...hom qua...hom nay...", "...dung ngu..."}
task.spawn(function()
	while true do
		task.wait(math.random(8, 15))
		local s = plr:GetAttribute("Sanity") or 100
		if not plr:GetAttribute("Dreaming") and s < 50 then pushMsg(whispers[math.random(#whispers)], Color3.fromRGB(200, 120, 160)) end
	end
end)

-- ===== RENDER =====
RunService.RenderStepped:Connect(function()
	local role = plr:GetAttribute("Role")
	local s = plr:GetAttribute("Sanity") or 100
	local dreaming = plr:GetAttribute("Dreaming")
	local now = workspace:GetServerTimeNow()
	local phase = State:GetAttribute("Phase") or ""

	roleL.Text = "Vai tro: " .. (ROLE_NAME[role] or "...")
	local ready = plr:GetAttribute("SkillReadyAt") or 0
	local cd = ready - now
	skillL.Text = (SKILL_NAME[role] or "") .. (cd > 0 and string.format("  - hoi chieu %ds", math.ceil(cd)) or "  - SAN SANG")
	local ROOMS = {Class = "Phong 1 - Lop hoc", West = "Phong 2 - Thu vien", East = "Phong 3 - Phong nhac", Hall = "Hanh lang (an toan)"}
	infoL.Text = string.format("%s   |   Dau hieu: %d/3   |   Manh Neo: %d/3", ROOMS[plr:GetAttribute("Room")] or "...", State:GetAttribute("Signs") or 0, State:GetAttribute("Shards") or 0)
	phaseL.Text = PHASE_TEXT[phase] or ""
	do
		local m = ({Seer = 100, Healer = 100, Anchor = 110, Diviner = 100})[role] or 100 -- mức tối đa theo vai
		s = math.min(s, m)
		local st, col = sanState(s)
		sanFill.Size = UDim2.fromScale(math.clamp(s / m, 0, 1), 1)
		sanFill.BackgroundColor3 = dreaming and Color3.fromRGB(90, 80, 120) or col
		sanText.Text = dreaming and "HÒA MỘNG" or string.format("TỈNH TÁO  %d / %d  ·  %s", math.floor(s), m, st)
		itemL.Text = ""
		if plr:GetAttribute("Room") == "East" then
			local on = State:GetAttribute("MusicOn")
			musicL.Text = on and "♪ Nhạc đang vang — đừng đứng yên ♪" or "✖ NHẠC TẮT — ĐỨNG YÊN! ✖"
			musicL.TextColor3 = on and Color3.fromRGB(180, 200, 255) or Color3.fromRGB(255, 80, 80)
		else musicL.Text = "" end
	end
	local tt = State:GetAttribute("TaskText") or ""
	if tt ~= "" then
		local left = math.max(0, math.ceil((State:GetAttribute("TaskDeadline") or 0) - now))
		local carry = plr:GetAttribute("Carrying")
		taskL.Text = "LOI GIAO VIEN: " .. tt .. " (" .. left .. "s)" .. (carry and "  [dang cam do]" or "")
	else taskL.Text = "" end
	cleanseBar.Visible = phase == "ThanhTay" and (State:GetAttribute("Cleanse") or 0) > 0
	cleanseFill.Size = UDim2.fromScale(math.clamp(State:GetAttribute("Cleanse") or 0, 0, 1), 1)

	-- Chua Lanh: thay Sanity chinh xac + Nguong Thuc
	if role == "Healer" then
		local lines = {"Nguong Thuc: " .. tostring(State:GetAttribute("Threshold") or "?")}
		for _, p in ipairs(Players:GetPlayers()) do
			table.insert(lines, p.Name .. ": " .. (p:GetAttribute("Dreaming") and "HOA MONG" or math.floor(p:GetAttribute("Sanity") or 0)))
		end
		healL.Text = table.concat(lines, "\n")
	else healL.Text = "" end

	-- vignette theo Sanity
	local k = dreaming and 0.2 or math.clamp(1 - s / 100, 0, 1)
	for _, f in ipairs(vig) do f.BackgroundTransparency = 1 - k * 0.85 end
	cc.Saturation = dreaming and -1 or -(k * 0.6)
	cc.TintColor = dreaming and Color3.fromRGB(190, 180, 255) or Color3.new(1, 1, 1)
	dreamL.Visible = dreaming == true

	-- Hoang Loan: rung man hinh
	if not dreaming and s < 25 then
		cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(math.random(-10, 10) / 20), math.rad(math.random(-10, 10) / 20), 0)
	end

	-- Thau Thi
	local mineSight = role == "Seer" and (plr:GetAttribute("TrueSightUntil") or 0) > now
	local teamSight = (State:GetAttribute("SeerMarkUntil") or 0) > now -- Đánh Dấu: cả nhóm thấy những gì Thấu Thị soi
	local sight = (mineSight or teamSight) and (plr:GetAttribute("Level") or 1) == 1
	local myRoom = plr:GetAttribute("Room")
	-- Nhìn Xuyên chỉ soi PHÒNG lúc dùng kỹ năng
	local sRoom = mineSight and (plr:GetAttribute("SightRoom") or myRoom) or State:GetAttribute("SeerMarkRoom")
	local function roomOfPos(pos) local x, z = pos.X / 1.2, pos.Z / 1.2
		if x < -50.5 and math.abs(z) < 30.5 then return "West" elseif x > 50.5 and math.abs(z) < 30.5 then return "East"
		elseif math.abs(x) < 50.5 and z > -35.5 and z < 35.5 then return "Class" elseif z >= 35.5 then return "Hall" end return "None" end
	local function here(inst) local p = inst:IsA("Model") and inst:GetPivot().Position or inst.Position return roomOfPos(p) == sRoom end
	shadowBox.Visible = role == "Seer" and (plr:GetAttribute("Level") or 1) == 1 and myRoom == "Class" and not State:GetAttribute("Sign_Shadow") and phase == "TrinhSat"
	shadowBox.Transparency = (sight and sRoom == "Class") and 0.1 or 0.75
	stalkerHL.Enabled = sight and State:GetAttribute("StalkerActive") == true
	clockGui.Enabled = sight and mineSight and sRoom == "Class" and phase == "TruyNguyen" and seerHours ~= nil
	libHL.Enabled = sight and sRoom == "West"
	pupHL.Enabled = sight and sRoom == "East"
	noise.BackgroundTransparency = (sight and mineSight) and (0.85 + math.random() * 0.1) or 1
	-- Thấy trước
	if sight and mineSight then
		local lines = {"👁 NHÌN XUYÊN (" .. math.ceil((plr:GetAttribute("TrueSightUntil") or 0) - now) .. "s)"}
		if sRoom == "Class" then
			if State:GetAttribute("TeacherWatching") then
				table.insert(lines, "Cô ĐANG NHÌN · quay lại bảng sau " .. math.max(0, math.ceil((State:GetAttribute("TeacherTurnBackAt") or now) - now)) .. "s")
			else
				table.insert(lines, "Cô quay xuống sau " .. math.max(0, math.ceil((State:GetAttribute("TeacherTurnAt") or now) - now)) .. "s")
			end
			local rn = State:GetAttribute("RollName") or ""
			if rn ~= "" then table.insert(lines, State:GetAttribute("RollGhost") and ("Điểm danh: KHÔNG có ai tên " .. rn .. "!") or ("Điểm danh: " .. rn .. " là người thật")) end
		elseif sRoom == "East" then
			local mc = math.max(0, math.ceil((State:GetAttribute("MusicChangeAt") or now) - now))
			table.insert(lines, State:GetAttribute("MusicOn") and ("Nhạc TẮT sau " .. mc .. "s") or ("Nhạc vang lại sau " .. mc .. "s"))
			table.insert(lines, "Con Rối hiện xuyên tường")
		elseif sRoom == "West" then
			table.insert(lines, "Thủ Thư hiện xuyên tường")
			table.insert(lines, "Bà nghe bước chân trong ~12 bước")
		else
			table.insert(lines, "Hành lang: không có gì bất thường")
		end
		sightL.Text = table.concat(lines, "\n")
	else sightL.Text = "" end
	-- mắt cô sáng rực khi sắp quay (chỉ Thấu Thị thấy)
	local eyes = IX.Teacher:FindFirstChild("Eyes")
	if eyes then
		local soon = (State:GetAttribute("TeacherTurnAt") or 0) - now
		eyes.Size = (sight and sRoom == "Class" and soon > 0 and soon < 2.5) and Vector3.new(2, 0.6, 0.1) or Vector3.new(1.2, 0.3, 0.1)
	end
	local gold = Color3.fromRGB(255, 220, 90)
	setXray(IX.Chalk, sight and IX.Chalk.Transparency < 1 and here(IX.Chalk), gold)
	setXray(IX.TaskBook, sight and IX.TaskBook.Transparency < 1 and here(IX.TaskBook), gold)
	setXray(IX.Notebook, sight and IX.Notebook.Transparency < 1 and here(IX.Notebook), Color3.fromRGB(255, 120, 80))
	for _, n in ipairs({"Shard1", "Shard2", "Shard3"}) do setXray(IX[n], sight and IX[n].Transparency < 1 and here(IX[n]), Color3.fromRGB(120, 200, 255)) end
	local itemsF = IX.Parent and IX.Parent:FindFirstChild("Items")
	if itemsF then for _, it in ipairs(itemsF:GetChildren()) do setXray(it, sight and here(it), Color3.fromRGB(140, 255, 160)) end end
	for inst in pairs(xray) do if not inst.Parent then setXray(inst, false) end end
	-- Bình tâm
	local calm = (plr:GetAttribute("CalmUntil") or 0) - now
	calmL.Text = calm > 0 and ("🛡 Bình tâm " .. math.ceil(calm) .. "s — miễn 1 lần phạt luật") or ""
end)

-- ===== MAP ĐƯỢC LÀM MỚI =====
-- Mỗi lần vào màn, server xóa map cũ và clone map mới: chạy lại script này để gắn với map mới.
local myMap = IX.Parent
local reloading = false
workspace.ChildAdded:Connect(function(c)
	if reloading or c.Name ~= "DreamMap" or c == myMap then return end
	reloading = true
	task.spawn(function()
		-- chờ map cũ bị đổi tên / xóa hẳn, để bản chạy lại chắc chắn tìm thấy map MỚI
		while myMap and myMap.Parent == workspace and myMap.Name == "DreamMap" do task.wait() end
		local s = script:Clone() s.Parent = script.Parent script:Destroy()
	end)
end)
