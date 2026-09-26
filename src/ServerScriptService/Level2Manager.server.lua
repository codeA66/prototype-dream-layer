-- DREAM LAYERS - TẦNG 2: BỆNH VIỆN NGỦ QUÊN
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Remotes = RS:WaitForChild("Remotes")
local Core = require(game:GetService("ServerScriptService"):WaitForChild("LevelCore"))
local map = workspace:WaitForChild("DreamMap2")
local IX = map.Interactables
local Z = map.Zones

local C = {
	DARK_DRAIN = 0.3, LIGHT_HEAL = 1, LIGHT_CAP = 80, NEAR_HEAL = 0.5, NEAR_CAP = 70, NEAR_RANGE = 12,
	HEALER_AURA = 1, HEALER_RANGE = 14, PENALTY = 8,
	ESCAPE_TIME = 12, GATE_TIME = 60, TICKETS = 8,
	PRICE = {Key = 3, Shard = 5, Potion = 1},
}

local ST, S, G = Core.state("GameState2")
S("Phase", "Idle")

-- ===== TIỆN ÍCH =====
-- ===== TIỆN ÍCH (dùng chung từ LevelCore) =====
local function inL2(p) return p:GetAttribute("Level") == 2 end
local function l2Players() return Core.playersIn(2) end
local hrp, speed, maxSan, addSanity = Core.hrp, Core.speed, Core.maxSan, Core.addSanity
local setGhost, freeze, show, en, say = Core.setGhost, Core.freeze, Core.show, Core.en, Core.say
local hasTool, giveTool, removeTool = Core.hasTool, Core.giveTool, Core.removeTool
local function alive(p) return inL2(p) and Core.alive(p) end
local function notify(msg, who) Core.notify(msg, who or l2Players()) end
local ROOMS = {"Lobby", "Surgery", "Billing", "Morgue", "Contamination"}
local function roomOf(pos) return Core.zoneRoom(Z, ROOMS, pos, "Hall") end
local function active() local ph = G("Phase") return ph ~= "Idle" and ph ~= "Win" and ph ~= "Lose" end
local violate = Core.newRules({prefix = "⚠ ", penalty = C.PENALTY, notify = notify,
	blocked = function(p) return G("Phase") == "Gate" or not inL2(p) end})
local prompt = Core.newPrompter(function(p) return inL2(p) and active() end)
-- Phiếu Khám: mỗi người tự giữ; 1 ô trên thanh đồ "Phiếu Khám ×N"
local TICKET = {label = "Phiếu Khám", alwaysCount = true, size = Vector3.new(1.4, 0.1, 1), color = Color3.fromRGB(230, 200, 120),
	init = function(t) t:SetAttribute("IsTicket", true) end,
	tip = function(n) return "Bạn có " .. n .. " Phiếu Khám — trả tiền ở Phòng Đóng Phí" end}
local function setTickets(p, n) p:SetAttribute("Tickets", n) Core.setStack(p, "Ticket", n, TICKET) end
local function tickets(p) return p:GetAttribute("Tickets") or 0 end
local function updateTeamTickets() local s = 0 for _, o in ipairs(l2Players()) do s += tickets(o) end S("Tickets", s) end

-- ===== CỬA (F) =====
local doorCtl = Core.wireDoors(map.Doors, {dist = 11, lockedMsg = "Cửa sắt đã hạ xuống...",
	canUse = function(p) return alive(p) end,
	check = function(p, m) if m.Name == "Door_Contam" and not G("Keycard") then return "Cửa khóa từ. Cần THẺ TỪ (mua ở Phòng Đóng Phí, 3 Phiếu Khám)." end end})
local function allDoors(o) doorCtl.setAll(o) end

-- ===== TỜ NỘI QUY (Hướng dẫn bệnh nhân) =====
prompt(IX.RulesPaper, "Nhặt", "Hướng dẫn bệnh nhân", 0.5, function(p)
	p:SetAttribute("HasRules2", true)
	giveTool(p, "HuongDan", "Hướng dẫn bệnh nhân (cầm lên để đọc · M)", Vector3.new(1.4, 0.05, 1.9), Color3.fromRGB(240, 235, 215))
	Remotes.Notify:FireClient(p, "__L2RULES__")
end)

-- ===== SỔ TRỰC ĐÊM (trên khay dụng cụ cạnh bàn mổ): ghi KHI NÀO dấu hiệu xuất hiện =====
prompt(IX.NightLog, "Đọc sổ trực đêm", "Khay dụng cụ", 1, function(p)
	p:SetAttribute("HasLog2", true)
	giveTool(p, "SoTrucDem", "Sổ trực đêm của y tá (cầm lên để đọc)", Vector3.new(1.2, 0.25, 1.7), Color3.fromRGB(40, 70, 90))
	Remotes.Notify:FireClient(p, "__DIARY2__")
end)

-- ===== PHIẾU KHÁM (tiền) =====
local ticketFolder = Instance.new("Folder") ticketFolder.Name = "Tickets" ticketFolder.Parent = map
local function spawnTickets()
	ticketFolder:ClearAllChildren()
	local spots = IX.TicketSpawns:GetChildren()
	for i = #spots, 2, -1 do local j = math.random(i) spots[i], spots[j] = spots[j], spots[i] end
	for i = 1, math.min(C.TICKETS, #spots) do
		local t = Instance.new("Part") t.Name = "Ticket" t.Anchored = true t.CanCollide = false t.Size = Vector3.new(1.4, 0.1, 1) t.Color = Color3.fromRGB(240, 220, 150)
		t.Position = spots[i].Position t.Parent = ticketFolder		t.Material = Enum.Material.Neon t.Color = Color3.fromRGB(230, 200, 120)
		local gl = Instance.new("PointLight", t) gl.Range = 6 gl.Brightness = 0.9 gl.Color = Color3.fromRGB(255, 210, 130)
		prompt(t, "Nhặt", "Phiếu Khám", 0.3, function(p)
			t:Destroy() setTickets(p, tickets(p) + 1) updateTeamTickets()
			notify("Nhặt 1 Phiếu Khám — bạn có " .. tickets(p) .. " phiếu.", p)
		end)
	end
end

-- ===== PHÒNG PHẪU THUẬT: đèn mổ + Bác Sĩ Không Mặt + khẩu trang =====
local DOC = IX.Doctor
local TABLE = IX.OpTable
local docHome = DOC:GetPivot()
local docY = docHome.Y
local volunteer = nil
local docCd = 0
local function toggleMask(p, t)
	local on = not p:GetAttribute("Mask") p:SetAttribute("Mask", on)
	notify(on and "Bạn đeo khẩu trang." or "Bạn tháo khẩu trang.", p)
end
prompt(IX.MaskCabinet, "Lấy khẩu trang", "Tủ dụng cụ", 0.5, function(p)
	giveTool(p, "KhauTrang", "Khẩu trang — cầm lên rồi CLICK để đeo/tháo", Vector3.new(1, 0.6, 0.3), Color3.fromRGB(120, 180, 170), toggleMask)
	notify("Đã lấy khẩu trang. Cầm lên và click để đeo/tháo.", p)
end)
prompt(TABLE, "Nằm lên bàn mổ", "Bàn mổ", 2, function(p)
	if G("OpLight") then
		if volunteer then return end
		volunteer = p
		local r = hrp(p) if r then r.CFrame = CFrame.new(TABLE.Position + Vector3.new(0, 4, 0)) end
		freeze(p, 5) addSanity(p, -5)
		say(DOC, "Bệnh nhân đây rồi... *tiếng dao kéo*", 5)
		pcall(function() TABLE.Tools:Play() task.delay(1.6, function() TABLE.Tools:Play() end) end)
		if not G("ShardDoctorGiven") then
			S("ShardDoctorGiven", true) show(IX.ShardDoctor, true)
			notify("Bác sĩ hài lòng. Một MẢNH NEO rơi ra từ túi áo ông ấy!")
		end
	else
		violate(p, "Phẫu thuật — chạm vào bàn mổ khi đèn TẮT")
	end
end)
local ecgActive = false
local ecgTxt = IX.HeartMonitor:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
function ecgBeep() -- (khai báo toàn cục để gọi được từ vòng đèn mổ)
	if ecgActive then return end
	ecgActive = true S("SignLive_ECG", true) Core.sense(2, "Phòng Phẫu Thuật")
	ecgTxt.Text = "—————— BÍP! BÍP!" ecgTxt.TextColor3 = Color3.fromRGB(255, 80, 80)
	for _, p in ipairs(l2Players()) do if hrp(p) and roomOf(hrp(p).Position) == "Surgery" then notify("Ca mổ vừa xong... máy đo nhịp tim đường PHẲNG mà vẫn kêu BÍP BÍP!", p) end end
	task.spawn(function() while ecgActive do pcall(function() IX.HeartMonitor.ECGBeep:Play() end) task.wait(0.9) end end)
	task.wait(12)
	ecgActive = false S("SignLive_ECG", false)
	ecgTxt.Text = "—————— 0" ecgTxt.TextColor3 = Color3.fromRGB(80, 255, 120)
	pcall(function() IX.HeartMonitor.ECGLong:Play() task.delay(2.5, function() IX.HeartMonitor.ECGLong:Stop() end) end)
end
task.spawn(function() -- chu kỳ đèn mổ
	while true do
		S("OpLight", false) IX.SurgeryBulb.OpLight.Enabled = false IX.SurgeryBulb.Color = Color3.fromRGB(90, 90, 85)
		local w = math.random(30, 45) S("OpLightAt", workspace:GetServerTimeNow() + w)
		Core.waitUnfrozen(S, G, "Surgery", w, {"OpLightAt"})
		local ph = G("Phase")
		if ph ~= "Idle" and ph ~= "Gate" and ph ~= "Win" and ph ~= "Lose" and G("Active_Surgery") then
			volunteer = nil
			S("OpLight", true) IX.SurgeryBulb.OpLight.Enabled = true IX.SurgeryBulb.Color = Color3.fromRGB(255, 255, 240)
			say(DOC, "Ai là bệnh nhân?", 6)
			Core.waitUnfrozen(S, G, "Surgery", 6)
			if not volunteer then
				local best, bd
				for _, p in ipairs(l2Players()) do
					if alive(p) and roomOf(hrp(p).Position) == "Surgery" then
						local d = (hrp(p).Position - TABLE.Position).Magnitude if not bd or d < bd then best, bd = p, d end
					end
				end
				if best then violate(best, "Không ai nằm lên bàn — Bác sĩ mổ nhầm người!", 25) say(DOC, "Vậy thì... EM.", 3) pcall(function() TABLE.Tools:Play() end) end
			end
			task.wait(2)
			if G("Phase") == "TrinhSat" and not G("Sign_ECG") then task.spawn(ecgBeep) end
		end
	end
end)
task.spawn(function() -- chu kỳ khẩu trang của bác sĩ
	while true do
		S("DoctorMasked", true) DOC.Mask.Transparency = 0
		Core.waitUnfrozen(S, G, "Surgery", 30)
		S("DoctorMasked", false) DOC.Mask.Transparency = 1
		if G("Phase") ~= "Idle" then say(DOC, "Khuôn mặt của ta đâu...?", 3) end
		Core.waitUnfrozen(S, G, "Surgery", 10)
	end
end)

-- ===== PHÒNG ĐÓNG PHÍ: thu ngân thật / bản sao + số 00 =====
local CASH = {IX.CashierA, IX.CashierB}
local function setFake(i)
	S("FakeWindow", i)
	for k = 1, 2 do
		local fake = k == i
		CASH[k].Smile.Transparency = fake and 0 or 1
		local plate = IX["NamePlate" .. k]:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
		plate.Text = fake and string.reverse("1 NAGN UHT"):gsub("1", tostring(k)) or ("THU NGÂN " .. k)
		if fake then plate.Text = (k == 1 and "1 NÂGN UHT" or "2 NÂGN UHT") end
	end
end
task.spawn(function()
	while true do
		setFake(math.random(2)) S("SwapAt", workspace:GetServerTimeNow() + 25)
		Core.waitUnfrozen(S, G, "Billing", 25, {"SwapAt"})
		for _, p in ipairs(l2Players()) do if hrp(p) and roomOf(hrp(p).Position) == "Billing" then notify("Đèn quầy nháy lên... hai thu ngân vừa đổi chỗ?", p) end end
	end
end)
task.spawn(function()
	while true do
		local n = IX.QueueBoard:FindFirstChildOfClass("SurfaceGui").Number
		S("QueueZero", false) S("SignLive_Mirror", false) n.Text = string.format("MỜI SỐ %02d", math.random(1, 40)) pcall(function() IX.Mirror.Whisper:Stop() end)
		local qw = math.random(30, 45) S("QueueZeroAt", workspace:GetServerTimeNow() + qw)
		Core.waitUnfrozen(S, G, "Billing", qw, {"QueueZeroAt"})
		if G("Active_Billing") then
			S("QueueZero", true) n.Text = "MỜI SỐ 00"
			if G("Phase") == "TrinhSat" and not G("Sign_Mirror") then
				S("SignLive_Mirror", true) Core.sense(2, "Phòng Đóng Phí") pcall(function() IX.Mirror.Whisper:Play() end)
				for _, p in ipairs(l2Players()) do if p:GetAttribute("Room2") == "Billing" then notify("Bảng gọi “SỐ 00”... tấm GƯƠNG cạnh quầy thì thầm tên ai đó.", p) end end
			end
			Core.waitUnfrozen(S, G, "Billing", 10)
		end
	end
end)
local function buy(p, win, item)
	local price = C.PRICE[item]
	if tickets(p) < price then notify("Bạn không đủ Phiếu Khám (cần " .. price .. ", bạn có " .. tickets(p) .. ").", p) return end
	if G("QueueZero") and not Core.isLulled(G, "Billing") then
		for _, o in ipairs(l2Players()) do violate(o, "Đóng phí — lên quầy khi bảng gọi SỐ 00. Thu ngân tính nợ CẢ NHÓM", 10) end
		return
	end
	setTickets(p, tickets(p) - price) updateTeamTickets()
	if G("FakeWindow") == win and not Core.isLulled(G, "Billing") then
		violate(p, "Đóng phí — bạn đã trả tiền cho BẢN SAO đang cười", 10)
		say(CASH[win], "Hihi... cảm ơn nhé.", 3)
		return
	end
	say(CASH[win], "Đã thanh toán.", 2)
	if item == "Key" then S("Keycard", true) notify(p.Name .. " mua THẺ TỪ — cửa Phòng Ô Nhiễm đã mở khóa.")
	elseif item == "Shard" then
		if G("ShardBought") then setTickets(p, tickets(p) + price) updateTeamTickets() notify("Mảnh Neo này đã được mua rồi.", p) return end
		S("ShardBought", true) show(IX.ShardBuy, true) notify("Đã mua MẢNH NEO — nó nằm trên quầy.")
	elseif item == "Potion" then addSanity(p, 25) notify("Bạn uống thuốc (+25 Tỉnh táo).", p) end
end
for w = 1, 2 do
	local base = IX["Window" .. w]
	local function sub(name, key, item, label, dz)
		local part = base:Clone() part.Name = name part:ClearAllChildren() part.CFrame = base.CFrame * CFrame.new(0, 0, dz) part.Size = Vector3.new(0.5, 1, 1) part.Parent = IX
		prompt(part, label .. " (" .. C.PRICE[item] .. " phiếu)", "Thu ngân " .. w, 0.5, function(p) buy(p, w, item) end, key)
	end
	sub("BuyKey" .. w, Enum.KeyCode.E, "Key", "Mua Thẻ Từ", -1.5)
	sub("BuyShard" .. w, Enum.KeyCode.R, "Shard", "Mua Mảnh Neo", 0)
	sub("BuyPotion" .. w, Enum.KeyCode.T, "Potion", "Mua thuốc", 1.5)
end

-- ===== NHÀ XÁC: đèn tắt + Người Gác + tủ xác có tên =====
local KEEP = IX.Keeper
local keepHome = KEEP:GetPivot()
local DRAWERS = IX.Drawers:GetChildren()
local ROLE_TAG = {Seer = "THẤU THỊ", Healer = "CHỮA LÀNH", Anchor = "NGƯỜI NEO", Diviner = "NHÀ BÓI TOÁN"}
local FAKE_NAMES = {"Nguyễn V. A", "Trần T. B", "Lê V. C", "Phạm T. D", "Không rõ", "Vô danh", "Minh 5A", "???"}
local drawerTag = {}
local morgueLights = {}
for _, d in ipairs(map.Props.Morgue:GetDescendants()) do if d:IsA("Light") then table.insert(morgueLights, d) end end
for _, d in ipairs(map.Props:GetChildren()) do if d.Name == "Fluoro" or d.Name == "LightNode" then end end
local hidingIn = {}
local function tagDrawers()
	local list = {} for _, d in ipairs(DRAWERS) do if d.Name ~= "Drawer_13" then table.insert(list, d) end end
	for i = #list, 2, -1 do local j = math.random(i) list[i], list[j] = list[j], list[i] end
	local idx = 1
	for _, r in ipairs({"Seer", "Healer"}) do drawerTag[list[idx]] = r idx += 1 end
	for _, d in ipairs(DRAWERS) do
		local tag = d:FindFirstChildOfClass("SurfaceGui").Tag
		local num = d.Name:sub(-2)
		if drawerTag[d] then tag.Text = "#" .. num .. " " .. ROLE_TAG[drawerTag[d]]
		elseif d.Name == "Drawer_13" then tag.Text = "#13 ???"
		else tag.Text = "#" .. num .. " " .. FAKE_NAMES[math.random(#FAKE_NAMES)] end
		local bb = d:FindFirstChild("NameTag") or Instance.new("BillboardGui")
		bb.Name = "NameTag" bb.Size = UDim2.fromOffset(150, 30) bb.StudsOffset = Vector3.new(0, 0, 1.2) bb.MaxDistance = 16 bb.LightInfluence = 0 bb.Parent = d
		local l = bb:FindFirstChild("T") or Instance.new("TextLabel", bb)
		l.Name = "T" l.Size = UDim2.fromScale(1, 1) l.BackgroundColor3 = Color3.fromRGB(225, 218, 190) l.BackgroundTransparency = 0.1
		l.TextColor3 = Color3.fromRGB(30, 25, 20) l.Font = Enum.Font.Code l.TextScaled = true l.Text = tag.Text
	end
	S("SeerDrawer", list[1].Name) S("HealerDrawer", list[2].Name)
end
local function unhide(p)
	local d = hidingIn[p] if not d then return end
	hidingIn[p] = nil p:SetAttribute("Hiding", nil)
	local r = hrp(p) if r then r.Anchored = false r.CFrame = CFrame.new(d.Position + Vector3.new(0, 0, 5)) end
end
for _, d in ipairs(DRAWERS) do
	prompt(d, "Chui vào tủ", "Tủ xác", 0.6, function(p)
		if hidingIn[p] then unhide(p) return end
		local r = hrp(p) if not r then return end
		if drawerTag[d] == p:GetAttribute("Role") then
			hidingIn[p] = d p:SetAttribute("Hiding", d.Name)
			r.CFrame = CFrame.new(d.Position + Vector3.new(0, 0, 1.2)) r.Anchored = true
			notify("Bạn nằm vào ngăn tủ có tên mình. Lạnh... nhưng an toàn. (bấm E lần nữa để ra)", p)
			if not G("ShardDrawerGiven") then
				S("ShardDrawerGiven", true) S("Shards", (G("Shards") or 0) + 1)
				notify(p.Name .. " sờ thấy một MẢNH NEO trong ngăn tủ! (" .. G("Shards") .. "/3)")
			end
		else
			violate(p, "Nhà xác — chui vào tủ xác KHÔNG phải của mình", 20)
			freeze(p, 4)
		end
	end)
end
-- Đếm số xác: lão gác tự thêm/bớt xác khi đèn tắt
local bodies = {} for i = 1, 5 do bodies[i] = IX["Body" .. i] end
local function bodyCount() local n = 0 for _, b in ipairs(bodies) do if b.Transparency < 1 then n += 1 end end return n end
local countMismatch, mismatchUntil = false, 0
local nextMismatch = nil -- Bói Toán biết trước
local drawer13Until = 0
local keeperChase = nil -- {p, untilT}: lão gác đuổi theo người ra nhầm cửa
local lastRoom = {}
local DOOR_BACK_POS = map.Doors.Door_MorgueBack.Panel.Position
local DOOR_MAIN_POS = map.Doors.Door_Morgue.Panel.Position
task.spawn(function()
	while true do
		if not G("Active_Morgue") then task.wait(1) continue end -- nhà xác chưa có ai vào
		S("MorgueDark", false) for _, l in ipairs(morgueLights) do l.Enabled = true end KEEP.Flashlight.Beam.Enabled = false
		pcall(function() map.Zones.Morgue.ColdHum:Resume() if not map.Zones.Morgue.ColdHum.IsPlaying then map.Zones.Morgue.ColdHum:Play() end end)
		local w = math.random(30, 40) S("MorgueDarkAt", workspace:GetServerTimeNow() + w)
		Core.waitUnfrozen(S, G, "Morgue", w, {"MorgueDarkAt"})
		local ph = G("Phase")
		if ph ~= "Idle" and ph ~= "Gate" and ph ~= "Win" and ph ~= "Lose" then
			S("MorgueDark", true) for _, l in ipairs(morgueLights) do l.Enabled = false end KEEP.Flashlight.Beam.Enabled = true
			pcall(function() map.Zones.Morgue.ColdHum:Pause() end)
			say(KEEP, "Một... hai... ba...", 6)
			local caught = {}
			local t0 = os.clock()
			local el = 0
			while el < 7 do
				local dt0 = os.clock()
				local yaw = el / 7 * math.pi * 2
				local pos = keepHome.Position
				KEEP:PivotTo(CFrame.new(pos) * CFrame.Angles(0, yaw, 0))
				local look = KEEP:GetPivot().LookVector
				local calm = Core.isFrozen(G, "Morgue") or Core.isLulled(G, "Morgue")
				KEEP.Flashlight.Beam.Enabled = not Core.isLulled(G, "Morgue")
				for _, p in ipairs(l2Players()) do
					if not calm and alive(p) and not caught[p] and not hidingIn[p] and roomOf(hrp(p).Position) == "Morgue" then
						local to = hrp(p).Position - pos
						local flat = Vector3.new(to.X, 0, to.Z)
						if flat.Magnitude < 34 and flat.Unit:Dot(Vector3.new(look.X, 0, look.Z).Unit) > 0.8 then
							caught[p] = true
							violate(p, "Nhà xác — Người Gác soi thấy bạn và đếm bạn vào số xác", 25)
							local slab = bodies[math.random(#bodies)] local r = hrp(p) if r then r.CFrame = CFrame.new(slab.Position + Vector3.new(0, 3, 0)) end
						end
					end
				end
				task.wait(0.1)
				if not Core.isFrozen(G, "Morgue") then el += os.clock() - dt0 end
			end
			KEEP:PivotTo(keepHome)
			-- lén thêm/bớt 1 xác
			local mm = nextMismatch if mm == nil then mm = math.random() < 0.5 end nextMismatch = nil
			if mm then
				local b = bodies[math.random(#bodies)] b.Transparency = b.Transparency < 1 and 1 or 0
				countMismatch = true mismatchUntil = os.clock() + 25
			else countMismatch = false end
			S("BodyCount", bodyCount()) S("BodyMismatch", countMismatch)
			if G("Phase") == "TrinhSat" and not G("Sign_Drawer13") then
				drawer13Until = os.clock() + 25 S("SignLive_Drawer13", true) Core.sense(2, "Nhà Xác")
				pcall(function() local b = IX.Drawers.Drawer_13.Breath b.TimePosition = 0 b:Play() task.delay(4, function() b:Stop() end) end)
				for _, p in ipairs(l2Players()) do if p:GetAttribute("Room2") == "Morgue" then notify("Lão gác đếm xong... TỦ SỐ 13 bốc hơi nóng, như có người vừa nằm trong đó.", p) end end
			end
			for _, p in ipairs(l2Players()) do if hrp(p) and roomOf(hrp(p).Position) == "Morgue" then notify("Đèn bật lại... Hãy ĐẾM LẠI số xác trên bàn.", p) end end
			for p in pairs(hidingIn) do unhide(p) end
		end
	end
end)

-- ===== PHÒNG Ô NHIỄM: đồ bảo hộ + miệng gió + Bệnh Nhân Số 0 =====
local PZ = IX.PatientZero
local VENTS = {} for i = 1, 5 do VENTS[i] = {grate = IX.Vents["Vent" .. i], led = IX.Vents["VentLight" .. i]} end
local activeVent = 2
local nextVent = nil -- Bói Toán biết trước
local function pickVent() local v repeat v = math.random(#VENTS) until v ~= activeVent or #VENTS < 2 return v end -- luôn chuyển sang miệng gió KHÁC
local underTimer, spreadTimer, dirtyAt = {}, {}, {}
local feverT, maskT, suitT = {}, {}, {}
local function toggleSuit(p)
	local on = not p:GetAttribute("Suit") p:SetAttribute("Suit", on)
	if not on then p:SetAttribute("SuitDirty", false) end
	notify(on and "Bạn mặc đồ bảo hộ." or "Bạn cởi đồ bảo hộ ra.", p)
end
prompt(IX.SuitLocker, "Lấy đồ bảo hộ", "Tủ đồ", 0.5, function(p)
	p:SetAttribute("SuitDirty", false)
	giveTool(p, "DoBaoHo", "Đồ bảo hộ — cầm lên rồi CLICK để mặc/cởi", Vector3.new(1.2, 1.2, 0.4), Color3.fromRGB(230, 200, 60), toggleSuit)
	notify("Đã lấy đồ bảo hộ mới. Cầm lên và click để mặc/cởi.", p)
end)
prompt(IX.WashStation, "Rửa tay", "Trạm rửa tay", 3, function(p)
	if activeVent == 1 then violate(p, "Ô nhiễm — rửa tay dưới miệng gió ĐỎ", 10) p:SetAttribute("Infected", true) return end
	p:SetAttribute("Infected", false) p:SetAttribute("Washed", true)
	notify("Bạn đã rửa tay sạch sẽ. Hết nhiễm bệnh.", p)
end)
task.spawn(function()
	while true do
		activeVent = nextVent or pickVent() nextVent = nil
		S("ActiveVent", activeVent)
		for i, v in ipairs(VENTS) do v.led.Color = i == activeVent and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 255, 120) end
		pcall(function() local sc = VENTS[activeVent].grate.Scratch sc.PlaybackSpeed = 0.7 + math.random() * 0.3 sc:Play() end)
		local gp = VENTS[activeVent].grate.Position
		PZ:PivotTo(CFrame.new(gp.X, gp.Y - 3.5, gp.Z))
		Core.waitUnfrozen(S, G, "Contamination", math.random(4, 7))
	end
end)

-- ===== DẤU HIỆU / TRUY NGUYÊN / THANH TẨY =====
local SIGN_NAMES = {ECG = "Máy đo nhịp tim phẳng mà vẫn kêu bíp", Mirror = "Hóa đơn in tên chính bạn", Drawer13 = "Tủ xác số 13 ấm áp"}
local SIGN_MEMORY = {
	ECG = "“Ca mổ đêm đó không có chữ ký của bác sĩ nào.”",
	Mirror = "“Ai đó đã trả viện phí bằng TÊN NGƯỜI KHÁC.”",
	Drawer13 = "“Bệnh nhân GIƯỜNG 13 chưa bao giờ chết.”",
}
local function registerSign(key, p)
	if G("Sign_" .. key) then return end
	S("Sign_" .. key, true) S("SignLive_" .. key, false)
	if key == "Mirror" then pcall(function() IX.Mirror.Whisper:Stop() end) end S("Signs", (G("Signs") or 0) + 1)
	for _, o in ipairs(l2Players()) do Remotes.Notify:FireClient(o, "__MEMORY__|" .. SIGN_NAMES[key] .. "|" .. SIGN_MEMORY[key]) end
	if G("Signs") >= 3 then
		S("Phase", "TruyNguyen")
		notify("Đủ 3 Dấu Hiệu! Vào PHÒNG Ô NHIỄM, tìm trong tủ hồ sơ bệnh án khớp với cả 3 ký ức.")
		for i = 1, 5 do en(IX["Record" .. i], true) end
	end
end
prompt(IX.HeartMonitor, "Ghi nhận", "Dấu hiệu", 1, function(p) if ecgActive then registerSign("ECG", p) else notify("Máy đo nhịp tim im lặng, đường phẳng.", p) end end)
prompt(IX.Mirror, "Soi gương", "Gương", 1, function(p)
	if not G("QueueZero") then notify("Trong gương chỉ có bóng của bạn... không có gì lạ.", p) return end
	notify("Bảng đang gọi SỐ 00... trong gương, tờ hóa đơn trên quầy in tên: " .. string.upper(p.DisplayName) .. "!", p)
	registerSign("Mirror", p)
end)
local d13sign = Instance.new("Part") d13sign.Name = "Sign_Drawer13" d13sign.Anchored = true d13sign.CanCollide = false d13sign.Transparency = 1
d13sign.Size = Vector3.new(8, 3.8, 0.5) d13sign.CFrame = IX.Drawers.Drawer_13.CFrame + Vector3.new(0, 0, 1) d13sign.Parent = IX
prompt(d13sign, "Sờ vào cửa tủ", "Tủ #13", 1, function(p) registerSign("Drawer13", p) end, Enum.KeyCode.R)
-- Hồ sơ bệnh án
local RECORD_TEXT = {
	"Giường 07 · Bác sĩ ký: có · Người trả phí: chính bệnh nhân",
	"Giường 13 · Bác sĩ ký: có · Người trả phí: người khác tên",
	"Giường 13 · Bác sĩ ký: KHÔNG · Người trả phí: người khác tên",
	"Giường 13 · Bác sĩ ký: KHÔNG · Người trả phí: chính bệnh nhân",
	"Giường 31 · Bác sĩ ký: KHÔNG · Người trả phí: người khác tên",
}
local recordOrder = {}
local function shuffleRecords()
	recordOrder = {1, 2, 3, 4, 5}
	for i = 5, 2, -1 do local j = math.random(i) recordOrder[i], recordOrder[j] = recordOrder[j], recordOrder[i] end
	for slot = 1, 5 do if recordOrder[slot] == 3 then S("CorrectRecord", slot) end end
end
for slot = 1, 5 do
	local part = IX["Record" .. slot]
	prompt(part, "Đọc hồ sơ", "Hồ sơ " .. slot, 0.3, function(p) notify("Hồ sơ " .. slot .. ": " .. RECORD_TEXT[recordOrder[slot]], p) end)
	prompt(part, "CHỌN hồ sơ này", "Hồ sơ " .. slot, 1, function(p)
		if G("Phase") ~= "TruyNguyen" then return end
		if slot == G("CorrectRecord") then
			S("Phase", "ThanhTay") en(IX.IVBag, true)
			notify("Đúng hồ sơ! Nguồn Ô Nhiễm: TÚI TRUYỀN DỊCH ĐEN ở giường 13. Mang nó tới LÒ HỦY trong Nhà Xác!")
		else
			violate(p, "Sai hồ sơ — Bệnh Nhân Số 0 cào mạnh trên trần", 8)
		end
	end, Enum.KeyCode.R)
end
local bagCarrier, bagAt = nil, 0
local BAG_HOME = IX.IVBag.CFrame
local function resetBag(msg)
	if bagCarrier then removeTool(bagCarrier, "TuiTruyenDich") end
	bagCarrier = nil IX.IVBag.CFrame = BAG_HOME IX.IVBag.Transparency = 0
	en(IX.IVBag, G("Phase") == "ThanhTay")
	if msg then notify(msg) end
end
prompt(IX.IVBag, "Gỡ túi truyền dịch", "Nguồn Ô Nhiễm", 1, function(p)
	if G("Phase") ~= "ThanhTay" or bagCarrier then return end
	bagCarrier = p bagAt = os.clock() IX.IVBag.Transparency = 1 en(IX.IVBag, false)
	giveTool(p, "TuiTruyenDich", "Túi truyền dịch đen — đưa tới lò hủy Nhà Xác", Vector3.new(1.2, 1.8, 0.5), Color3.fromRGB(20, 15, 20))
	notify(p.Name .. " đang cầm túi truyền dịch. 90 giây trước khi nó tái sinh!")
end)
prompt(IX.FurnaceMouth, "Đốt túi truyền dịch", "Lò hủy", 8, function(p)
	if bagCarrier ~= p then notify("Cần mang túi truyền dịch đen tới đây.", p) return end
	removeTool(p, "TuiTruyenDich") bagCarrier = nil
	S("Cleansed", true) S("Phase", "Neo")
	for _, o in ipairs(l2Players()) do addSanity(o, 20) end
	notify("THANH TẨY thành công! Lửa xanh bùng lên trong lò. (+20 Tỉnh táo) — Gom đủ 3 Mảnh Neo, đặt vào Bệ Neo ở sảnh.")
end)

-- ===== LOA BỆNH VIỆN: gọi tên bệnh nhân tới một phòng =====
local CALL_ROOMS = {"Surgery", "Billing", "Morgue", "Contamination", "Lobby"}
local ROOM_UP = {Lobby = "SẢNH TIẾP ĐÓN", Surgery = "PHÒNG PHẪU THUẬT", Billing = "PHÒNG ĐÓNG PHÍ", Morgue = "NHÀ XÁC", Contamination = "PHÒNG Ô NHIỄM"}
local CALL_TIME = 40
local nextCall, nextCallAt = nil, 0 -- Bói Toán biết trước
local call = nil
local function clearCall() call = nil S("CallTarget", "") S("CallRoom", "") S("CallDeadline", 0) end
local function makeCall(p, room)
	call = {p = p, room = room, deadline = os.clock() + CALL_TIME}
	S("CallTarget", p.Name) S("CallRoom", room) S("CallDeadline", workspace:GetServerTimeNow() + CALL_TIME)
	pcall(function() map.HospitalChime:Play() end)
	notify("📢 LOA: “Mời bệnh nhân " .. string.upper(p.DisplayName) .. " đến " .. ROOM_UP[room] .. ". Xin nhắc lại...” (" .. CALL_TIME .. " giây)")
end
task.spawn(function()
	while true do
		local cw = math.random(55, 85) nextCallAt = os.clock() + cw
		task.wait(cw)
		local ph = G("Phase")
		if call or not (ph == "TrinhSat" or ph == "TruyNguyen" or ph == "ThanhTay" or ph == "Neo") then continue end
		local cands = {} for _, p in ipairs(l2Players()) do if alive(p) and not p:GetAttribute("Hiding") then table.insert(cands, p) end end
		if #cands == 0 then continue end
		local p, room
		if nextCall and nextCall.p.Parent and table.find(cands, nextCall.p) and nextCall.p:GetAttribute("Room2") ~= nextCall.room then p, room = nextCall.p, nextCall.room end
		nextCall = nil
		if not p then
			p = cands[math.random(#cands)]
			local rooms = {} for _, r in ipairs(CALL_ROOMS) do if r ~= p:GetAttribute("Room2") and (r ~= "Contamination" or G("Keycard")) then table.insert(rooms, r) end end
			room = rooms[math.random(#rooms)]
		end
		makeCall(p, room)
	end
end)

-- ===== MẢNH NEO / BỆ NEO / CỔNG =====
for _, n in ipairs({"ShardDoctor", "ShardBuy"}) do
	prompt(IX[n], "Nhặt", "Mảnh Neo Thức", 0.5, function(p)
		show(IX[n], false) S("Shards", (G("Shards") or 0) + 1)
		notify(p.Name .. " nhặt Mảnh Neo (" .. G("Shards") .. "/3)")
	end)
end
local escape = Core.newEscape({gate = IX.Gate, S = S, G = G, doors = doorCtl, players = l2Players, alive = alive,
	escapeTime = C.ESCAPE_TIME, gateTime = C.GATE_TIME, notify = notify,
	safe = function(p) return roomOf(hrp(p).Position) == "Lobby" end,
	target = function() local esc = workspace:FindFirstChild("DreamMap") and workspace.DreamMap:FindFirstChild("EscapeRoom") return esc and esc:GetPivot() end,
	openMsg = "MỌI QUY LUẬT ĐÃ BIẾN MẤT. Điện bệnh viện đang cắt — " .. C.ESCAPE_TIME .. " giây nữa cửa sắt hạ xuống. CHẠY VỀ SẢNH!",
	trappedMsg = "Cửa sắt hạ xuống sau lưng bạn... Bạn bị nhốt lại bệnh viện.",
	onOpen = function() clearCall() end})
prompt(IX.Pedestal, "Đặt Mảnh Neo", "Bệ Neo", 1, function(p)
	if G("Phase") == "Gate" then return end
	if (G("Shards") or 0) < 3 then notify("Cần đủ 3 Mảnh Neo (đang có " .. (G("Shards") or 0) .. ").", p) return end
	if not G("Cleansed") then notify("Bệ Neo không phản ứng... Tầng vẫn còn ô nhiễm. Hãy THANH TẨY trước.", p) return end
	escape.open()
end)

-- ===== BẮT ĐẦU / KẾT THÚC TẦNG 2 =====
local LIE_POOL = 4
local backEvent = SS:FindFirstChild("BackToLobby") or Instance.new("BindableEvent", SS) backEvent.Name = "BackToLobby"
local startEvent = SS:FindFirstChild("StartLevel2") or Instance.new("BindableEvent", SS) startEvent.Name = "StartLevel2"
local function spawnAt(p)
	local r = hrp(p) if r then r.Anchored = false r.CFrame = IX.Spawn2.CFrame + Vector3.new(math.random(-6, 6), 4, math.random(-3, 3)) end
end
local function startLevel2()
	S("Phase", "TrinhSat") S("Signs", 0) S("Shards", 0) S("Tickets", 0) S("Keycard", false) S("Cleansed", false)
	S("ShardDoctorGiven", false) S("ShardBought", false) S("ShardDrawerGiven", false)
	for _, k in ipairs({"ECG", "Mirror", "Drawer13"}) do S("Sign_" .. k, false) end
	S("LieIndex", math.random(LIE_POOL)) S("StartedAt", workspace:GetServerTimeNow())
	for i = 1, 5 do en(IX["Record" .. i], false) end
	show(IX.ShardDoctor, false) show(IX.ShardBuy, false)
	en(IX.IVBag, false) IX.IVBag.CFrame = BAG_HOME IX.IVBag.Transparency = 0 bagCarrier = nil
	for _, b in ipairs(bodies) do b.Transparency = 0 end S("BodyCount", bodyCount())
	escape.reset()
	doorCtl.locked = false allDoors(false)
	tagDrawers() shuffleRecords() spawnTickets()
	for k in pairs(hidingIn) do hidingIn[k] = nil end
	for _, r in ipairs({"Surgery", "Billing", "Morgue", "Contamination"}) do S("Active_" .. r, false) end
	for _, k in ipairs({"ECG", "Mirror", "Drawer13"}) do S("SignLive_" .. k, false) end drawer13Until = 0
	clearCall() countMismatch = false keeperChase = nil S("BodyMismatch", false) KEEP:PivotTo(keepHome)
	for _, p in ipairs(l2Players()) do
		for _, a in ipairs({"Mask", "Suit", "SuitDirty", "Infected", "Washed", "HasRules2", "HasLog2", "Hiding"}) do p:SetAttribute(a, nil) end
		setTickets(p, 0)
		spawnAt(p)
	end
	notify("TẦNG 2 — BỆNH VIỆN NGỦ QUÊN. Nhặt HƯỚNG DẪN BỆNH NHÂN ở quầy tiếp đón. Cẩn thận: không phải dòng nào cũng là thật. Nghe nói y tá trực đêm để quên một cuốn SỔ trong phòng mổ...")
end
local function endLevel2(win, msg)
	if G("Phase") == "Win" or G("Phase") == "Lose" then return end
	S("RoundTime", math.floor(workspace:GetServerTimeNow() - (G("StartedAt") or 0)))
	S("Phase", win and "Win" or "Lose")
	notify(msg)
	task.delay(8, function() Core.finishLevel(2, win) end)
end
startEvent.Event:Connect(function() Core.startLevel(2) end)
-- ===== KỸ NĂNG THEO PHÒNG (Tầng 2) =====
local ROOM_NAME2 = {Lobby = "Sảnh tiếp đón", Surgery = "Phòng Phẫu Thuật", Billing = "Phòng Đóng Phí", Morgue = "Nhà Xác", Contamination = "Phòng Ô Nhiễm", Hall = "Hành lang"}
local function secs(attr) return math.max(0, math.floor((G(attr) or 0) - workspace:GetServerTimeNow())) end
local function divineL2(p, room)
	if room == "Lobby" then
		if call then return "Loa đang gọi " .. string.upper(call.p.DisplayName) .. " tới " .. ROOM_UP[call.room] .. "." end
		if not nextCall or not nextCall.p.Parent then
			local cands = {} for _, o in ipairs(l2Players()) do if alive(o) then table.insert(cands, o) end end
			if #cands == 0 then return nil end
			local o = cands[math.random(#cands)]
			local rooms = {} for _, r in ipairs(CALL_ROOMS) do if r ~= o:GetAttribute("Room2") and (r ~= "Contamination" or G("Keycard")) then table.insert(rooms, r) end end
			nextCall = {p = o, room = rooms[math.random(#rooms)]}
		end
		return string.format("Loa lần tới (khoảng %d giây nữa) sẽ gọi %s tới %s.", math.max(0, math.floor(nextCallAt - os.clock())), string.upper(nextCall.p.DisplayName), ROOM_UP[nextCall.room])
	elseif room == "Surgery" then
		local best, bd
		for _, o in ipairs(l2Players()) do if alive(o) and o:GetAttribute("Room2") == "Surgery" then local d = (hrp(o).Position - TABLE.Position).Magnitude if not bd or d < bd then best, bd = o, d end end end
		return (G("OpLight") and "Đèn mổ ĐANG bật!" or ("Đèn mổ bật sau khoảng " .. secs("OpLightAt") .. " giây.")) .. "\nNếu không ai tự nằm lên bàn, bác sĩ sẽ chọn người đứng gần bàn nhất — hiện là " .. (best and string.upper(best.DisplayName) or "không ai") .. "."
	elseif room == "Billing" then
		return "Bảng sẽ gọi SỐ 00 sau khoảng " .. secs("QueueZeroAt") .. " giây — đừng lên quầy lúc đó.\nHai thu ngân đổi chỗ sau khoảng " .. secs("SwapAt") .. " giây."
	elseif room == "Morgue" then
		if nextMismatch == nil then nextMismatch = math.random() < 0.5 end
		return "Đèn nhà xác tắt sau khoảng " .. secs("MorgueDarkAt") .. " giây.\nLần này số xác " .. (nextMismatch and "SẼ THAY ĐỔI — hãy ra bằng CỬA SAU." or "sẽ KHÔNG đổi — ra cửa chính cũng được.")
	elseif room == "Contamination" then
		nextVent = nextVent or pickVent()
		local vp = VENTS[nextVent].grate.Position
		Remotes.Notify:FireClient(p, "__STEPS__|" .. string.format("%.1f,%.1f", vp.X, vp.Z))
		return "Miệng gió có vòng sáng dưới sàn sẽ là miệng gió chuyển ĐỎ tiếp theo. Đừng đứng dưới nó."
	end
end
local function lullL2(p, room)
	if room == "Contamination" then
		for _, o in ipairs(l2Players()) do if o:GetAttribute("Room2") == "Contamination" then o:SetAttribute("Infected", false) o:SetAttribute("SuitDirty", false) end end
	elseif room == "Morgue" then keeperChase = nil KEEP:PivotTo(keepHome)
	elseif room == "Surgery" then say(DOC, "...*ngáp*... đeo lại khẩu trang thôi.", 3) end
end
-- ===== ĐĂNG KÝ TẦNG 2 VỚI LEVELCORE =====
Core.register(2, {
	S = S, G = G, state = ST, escape = escape,
	name = "Bệnh Viện Ngủ Quên", start = startLevel2, loseRestart = true,
	sleep = function() S("Phase", "Idle") end,
	active = active,
	debug = { -- chỉ dùng khi test trong Studio
		call = function(p, room) makeCall(p, room) end,
		mismatch = function() countMismatch = true mismatchUntil = os.clock() + 25 S("BodyMismatch", true) end,
	},
	tools = {"HuongDan", "KhauTrang", "DoBaoHo", "TuiTruyenDich", "SoTrucDem"},
	onDream = function(p)
		if bagCarrier == p then resetBag("Người cầm túi truyền dịch đã hòa mộng — túi quay về giường 13!") end
		unhide(p)
	end,
	skill = {roomAttr = "Room2", safeRooms = {Hall = true, Lobby = true}, roomName = ROOM_NAME2, divine = divineL2, onLull = lullL2,
		allowed = function(p) if not active() then return "" end end,
		onSeer = function(p) p:SetAttribute("SightRoom", p:GetAttribute("Room2")) end, -- chỉ soi phòng lúc dùng
	},
})



-- ===== TICK CHÍNH =====
local TICK = 0.25
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.3)
		if inL2(p) then spawnAt(p) end
	end)
end)

while true do
	task.wait(TICK)
	local ph = G("Phase")
	if ph == "Idle" or ph == "Win" or ph == "Lose" then continue end
	local plist = l2Players()
	local escaping = ph == "Gate"
	for _, p in ipairs(plist) do
		if alive(p) and not p:GetAttribute("Escaped") then
			local pos = hrp(p).Position
			local room = roomOf(pos)
			p:SetAttribute("Room2", room)
			if room ~= "Hall" and room ~= "Lobby" and not G("Active_" .. room) then
				S("Active_" .. room, true)
				if room == "Surgery" then notify("Cạnh bàn mổ, trên khay dụng cụ, có ngọn nến và một cuốn SỔ TRỰC ĐÊM ai đó để quên.", p) end
			end
			if not escaping then
				-- Tỉnh táo cơ bản (LevelCore) + lây nhiễm bệnh
				Core.tickSanity(p, plist, room == "Lobby" and not p:GetAttribute("Infected"), C, TICK) -- đang nhiễm bệnh thì ánh sáng không hồi
				for _, o in ipairs(plist) do
					if o ~= p and alive(o) and p:GetAttribute("Infected") and not o:GetAttribute("Infected") and (hrp(o).Position - pos).Magnitude < 6 then
						spreadTimer[o] = (spreadTimer[o] or 0) + TICK
						if spreadTimer[o] >= 3 then spreadTimer[o] = 0 o:SetAttribute("Infected", true) notify("Bạn bị lây NHIỄM BỆNH từ " .. p.Name .. "!", o) end
					end
				end
				-- Nhiễm bệnh: −1 Tỉnh táo mỗi giây cho tới khi rửa tay
				if p:GetAttribute("Infected") then addSanity(p, -1 * TICK) end

				-- PHẪU THUẬT: khẩu trang
				if room == "Surgery" and G("DoctorMasked") and not p:GetAttribute("Mask") and not Core.isLulled(G, "Surgery") then addSanity(p, -1 * TICK) end -- −1/giây
				-- Ô NHIỄM: đồ bảo hộ + miệng gió
				if room == "Contamination" then
					if not p:GetAttribute("Suit") then addSanity(p, -1 * TICK) end -- −1/giây
					local vp = VENTS[activeVent].grate.Position
					if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(vp.X, 0, vp.Z)).Magnitude < 4.5 then
						underTimer[p] = (underTimer[p] or 0) + TICK
						if underTimer[p] >= 1.5 and not p:GetAttribute("Infected") and not Core.isLulled(G, "Contamination") then
							underTimer[p] = 0
							if (p:GetAttribute("CalmUntil") or 0) > workspace:GetServerTimeNow() then p:SetAttribute("CalmUntil", 0) notify("🛡 Bài Ru che chở bạn khỏi Bệnh Nhân Số 0!", p)
							else
								p:SetAttribute("Infected", true)
								if p:GetAttribute("Suit") then p:SetAttribute("SuitDirty", true) dirtyAt[p] = os.clock() end
								notify("Bệnh Nhân Số 0 thò xuống chạm vào bạn — NHIỄM BỆNH! (rửa tay khi đèn miệng gió xanh, hoặc Bài Ru)", p)
							end
						end
					else underTimer[p] = 0 end
					if p:GetAttribute("SuitDirty") and p:GetAttribute("Suit") and dirtyAt[p] and os.clock() - dirtyAt[p] > 5 then
						dirtyAt[p] = os.clock() violate(p, "Ô nhiễm — đồ bảo hộ có vết đen mà bạn không cởi ra", 10)
					end
				else underTimer[p] = 0 end
				if room ~= "Contamination" and room ~= "Hall" and p:GetAttribute("Washed") == false then end
			end
		end
	end

	-- Thua khi cả nhóm hòa mộng (hiệu ứng hòa mộng do LevelCore lo)
	local anyAlive = false
	for _, p in ipairs(plist) do if alive(p) then anyAlive = true end end
	if #plist > 0 and not anyAlive then endLevel2(false, "CẢ NHÓM ĐÃ HÒA MỘNG. Bệnh viện nuốt chửng tất cả... Chơi lại Tầng 2 sau 8 giây.") continue end

	-- Tủ #13 ấm (trục Trạng thái nhóm)
	if ph == "TrinhSat" and not G("Sign_Drawer13") then
		local warm = os.clock() < drawer13Until
		if not warm and G("SignLive_Drawer13") then S("SignLive_Drawer13", false) end
		IX.Drawers.Drawer_13.Color = warm and Color3.fromRGB(230, 150, 110) or Color3.fromRGB(170, 180, 190)
		en(d13sign, warm)
	end

	-- Bác sĩ: săn người đeo khẩu trang khi ông tháo khẩu trang (Neo: đứng im · Ru: đeo lại khẩu trang, ngừng săn)
	DOC.Mask.Transparency = (G("DoctorMasked") or Core.isLulled(G, "Surgery")) and 0 or 1
	if not escaping and not Core.isFrozen(G, "Surgery") then
		local target, td
		if not G("DoctorMasked") and not G("OpLight") and not Core.isLulled(G, "Surgery") then
			for _, p in ipairs(plist) do
				if alive(p) and p:GetAttribute("Mask") and roomOf(hrp(p).Position) == "Surgery" then
					local d = (hrp(p).Position - DOC:GetPivot().Position).Magnitude if not td or d < td then target, td = p, d end
				end
			end
		end
		local cur = DOC:GetPivot().Position
		local goal
		if G("OpLight") then goal = TABLE.Position + Vector3.new(0, 0, -7)
		elseif target then goal = hrp(target).Position
		else local a = os.clock() * 0.3 goal = TABLE.Position + Vector3.new(math.cos(a) * 12, 0, math.sin(a) * 12) end
		local flat = Vector3.new(goal.X, docY, goal.Z)
		local dir = flat - Vector3.new(cur.X, docY, cur.Z)
		if dir.Magnitude > 0.2 then
			local step = (target and 12 or 6) * TICK
			local nxt = Vector3.new(cur.X, docY, cur.Z) + dir.Unit * math.min(step, dir.Magnitude)
			DOC:PivotTo(CFrame.lookAt(nxt, nxt + dir.Unit))
		end
		if target and td < 4 and os.clock() > docCd then
			docCd = os.clock() + 3
			violate(target, "Bác Sĩ Không Mặt giật khẩu trang của bạn", 20)
			target:SetAttribute("Mask", false)
		end
	end

	-- LOA: người được gọi phải tới đúng phòng
	if call and not escaping then
		local p = call.p
		if not p.Parent or not alive(p) then clearCall()
		elseif p:GetAttribute("Room2") == call.room then
			addSanity(p, 10) notify("📢 LOA: “Cảm ơn bệnh nhân " .. p.DisplayName .. ".” (+10 Tỉnh táo)") clearCall()
		elseif os.clock() > call.deadline then
			violate(p, "Loa gọi tên bạn mà bạn không tới " .. ROOM_UP[call.room], 10) clearCall()
		end
	end
	-- NHÀ XÁC: số xác thay đổi -> phải ra bằng CỬA SAU
	if not escaping then
		if countMismatch and os.clock() > mismatchUntil then countMismatch = false S("BodyMismatch", false) end
		for _, p in ipairs(plist) do
			if alive(p) then
				local now = p:GetAttribute("Room2")
				if lastRoom[p] == "Morgue" and now ~= "Morgue" and countMismatch then
					local pos = hrp(p).Position
					if (pos - DOOR_BACK_POS).Magnitude < (pos - DOOR_MAIN_POS).Magnitude then
						notify("Bạn lách ra bằng cửa sau. Lão gác không để ý.", p)
					else
						violate(p, "Nhà xác — số xác đã thay đổi mà bạn ra bằng CỬA CHÍNH", 15)
						keeperChase = {p = p, untilT = os.clock() + 6}
						say(KEEP, "Ngươi... chưa được đếm.", 3)
					end
				end
				lastRoom[p] = now
			end
		end
		if keeperChase and not G("MorgueDark") and not Core.isFrozen(G, "Morgue") and not Core.isLulled(G, "Morgue") then
			local t = keeperChase.p
			if os.clock() > keeperChase.untilT or not alive(t) then keeperChase = nil KEEP:PivotTo(keepHome)
			else
				local cur = KEEP:GetPivot().Position local tp = hrp(t).Position
				local from = Vector3.new(cur.X, keepHome.Y, cur.Z)
				local dir = Vector3.new(tp.X, keepHome.Y, tp.Z) - from
				if dir.Magnitude > 0.3 then local nxt = from + dir.Unit * math.min(11 * TICK, dir.Magnitude) KEEP:PivotTo(CFrame.lookAt(nxt, nxt + dir.Unit)) end
				if dir.Magnitude < 4 then
					addSanity(t, -10) notify("Lão gác túm lấy vai bạn... (−10 Tỉnh táo)", t)
					keeperChase = nil KEEP:PivotTo(keepHome)
				end
			end
		end
	end

	-- Túi truyền dịch hết giờ
	if bagCarrier and os.clock() - bagAt > 90 then resetBag("Túi truyền dịch TÁI SINH về giường 13!") end

	-- Thoát
	if escaping then
		local r = escape.tick()
		if r == true then endLevel2(true, "QUA TẦNG 2! Cổng đưa cả nhóm xuống tầng mộng sâu hơn...") continue
		elseif r == false then endLevel2(false, "Cổng đóng lại. Cả nhóm bị nhốt trong bệnh viện.") end
	end
end
