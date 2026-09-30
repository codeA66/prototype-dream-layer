-- DREAM LAYERS - TẦNG 4 (BOSS): CĂN NHÀ CỦA NGƯỜI NGỦ
-- Kẻ Gieo Mộng = "Người Kể Chuyện Trước Giờ Ngủ". Người đang ngủ = Minh (giường 13).
-- 1 nơi an toàn (Lobby = Phòng ngủ của Minh) + 4 phòng có luật:
--   Room1 Lớp học trong tủ sách · Room2 Phòng chờ dưới gầm giường · Room3 Khu rừng trong bức tranh · Room4 Phòng khách (Ghế bành)
-- LƯU Ý TÊN: thuộc tính người chơi "Room4" (quy ước RoomN của tầng N) chứa tên phòng đang đứng: "Lobby", "Room1".."Room4", "Hall".
-- Cơ chế boss: LẬT TRANG (mỗi ~40s một phòng thành "chương đang kể", nhịp nhanh hơn) · ĐỘ SÂU GIẤC MỘNG 3 khúc
--              · MỰC ĐỎ (viết lại luật khi vỡ khúc) · RƯỢT ĐUỔI lúc Thanh Tẩy · 3 KẾT CỤC.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Remotes = RS:WaitForChild("Remotes")
local Core = require(game:GetService("ServerScriptService"):WaitForChild("LevelCore"))
local map = Core.mapTemplate("DreamMap4") -- cất bản gốc trước khi sửa map; mỗi lần vào màn sẽ clone lại
local IX = map.Interactables
local Z = map.Zones

local LV = 4 -- đổi thành 6 nếu nhóm giữ đúng GDD (boss sau Tầng 5) — xem HUONG_DAN_TANG_BOSS.md
local C = {
	LIGHT_HEAL = 1, LIGHT_CAP = 80, NEAR_HEAL = 0.5, NEAR_CAP = 70, NEAR_RANGE = 12,
	HEALER_AURA = 1, HEALER_RANGE = 14, PENALTY = 8,
	ESCAPE_TIME = 12, GATE_TIME = 60, BOOK_TIME = 90, SIGN_LIVE = 20, LULL_EXTRA = 8,
	PAGE_EVERY = 40, CHAPTER_LEN = 20, CHAPTER_SPEED = 0.6, -- chương đang kể: mọi mốc chờ ×0,6
	SEEDER_SPEED = 10, CARRY_SPEED = 12, FIRE_HOLD = 8, PAGE_READ_HOLD = 6,
	NIGHT_RADIUS = {[3] = 30, [2] = 22, [1] = 15, [0] = 15}, -- vùng sáng của đèn ngủ co lại theo Độ Sâu
}

local ST, S, G = Core.state("GameState4")
S("Phase", "Idle")

-- ===== TIỆN ÍCH =====
local function inL(p) return p:GetAttribute("Level") == LV end
local function lPlayers() return Core.playersIn(LV) end
local hrp, speed, addSanity = Core.hrp, Core.speed, Core.addSanity
local show, en = Core.show, Core.en
local giveTool, removeTool = Core.giveTool, Core.removeTool
local function now() return workspace:GetServerTimeNow() end
local function alive(p) return inL(p) and Core.alive(p) end
local function notify(msg, who) Core.notify(msg, who or lPlayers()) end
local ROOMS = {"Lobby", "Room1", "Room2", "Room3", "Room4"}
local RULE_ROOMS = {"Room1", "Room2", "Room3", "Room4"}
local ROOM_NAME = {Lobby = "Phòng ngủ của Minh", Room1 = "Lớp học trong tủ sách", Room2 = "Phòng chờ dưới gầm giường",
	Room3 = "Khu rừng trong bức tranh", Room4 = "Phòng khách", Hall = "Hành lang"}
local function roomOf(pos) return Core.zoneRoom(Z, ROOMS, pos, "Hall") end
local function inRoom(room) local t = {} for _, p in ipairs(lPlayers()) do if alive(p) and p:GetAttribute("Room4") == room then table.insert(t, p) end end return t end
local function active() local ph = G("Phase") return ph ~= "Idle" and ph ~= "Win" and ph ~= "Lose" end
local function playing() local ph = G("Phase") return ph == "TrinhSat" or ph == "TruyNguyen" or ph == "ThanhTay" or ph == "Neo" end
local function awake(room) return playing() and G("Active_" .. room) end
local function calm(room) return Core.isLulled(G, room) end
local function stillEntity(room) return Core.isFrozen(G, room) or Core.isLulled(G, room) end
local violate = Core.newRules({prefix = "⚠ ", penalty = C.PENALTY, notify = notify,
	blocked = function(p) return G("Phase") == "Gate" or not inL(p) end})
local prompt = Core.newPrompter(function(p) return inL(p) and active() end)
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function inAny(model, pos, name, padY)
	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("BasePart") and (not name or c.Name == name) and Core.inZone(pos, c, padY or 4) then return c end
	end
end
local function facing(p, target, dot)
	local r = hrp(p) if not r then return false end
	local to = flat(target - r.Position) if to.Magnitude < 0.1 then return true end
	local look = flat(r.CFrame.LookVector) if look.Magnitude < 0.1 then return false end
	return look.Unit:Dot(to.Unit) > (dot or 0.5)
end
local function holdWhileLulled(room, attr)
	while Core.isLulled(G, room) do
		task.wait(0.2)
		if attr and type(G(attr)) == "number" then S(attr, math.max(G(attr), (G("Lull_" .. room) or 0))) end
	end
end
local function say(room, msg) local list = inRoom(room) if #list > 0 then notify(msg, list) end end
local hitCd = {}
local function hitReady(p, key, sec)
	local k = p.UserId .. key
	if (hitCd[k] or 0) > os.clock() then return false end
	hitCd[k] = os.clock() + sec return true
end
local function play(inst, name) pcall(function() inst[name]:Play() end) end
local function stop(inst, name) pcall(function() inst[name]:Stop() end) end
local lastRoom = {}
local enterAt = {} -- vừa bước vào phòng: 1,5 giây ân hạn trước khi luật "trạng thái" bắt lỗi
local function settled(p) return os.clock() - (enterAt[p] or 0) > 1.5 end
local shufflePuzzle -- gán ở phần Truy Nguyên (Lật Trang dùng để đổi bìa sách)
local ROLE_VN = {Seer = "THẤU THỊ", Healer = "CHỮA LÀNH", Anchor = "NGƯỜI NEO", Diviner = "NHÀ BÓI TOÁN"}

-- ===== LẬT TRANG: mỗi ~40s, 1 trong 3 phòng thành "chương đang được kể" (nhịp nhanh hơn) =====
-- Chương kế tiếp được chọn TRƯỚC (NextChapter) để Bói Toán báo đúng.
local function chapterMul(room)
	if G("Chapter") == room and (G("ChapterUntil") or 0) > now() then return C.CHAPTER_SPEED end
	return 1
end
local function pickNext() local r = {"Room1", "Room2", "Room3"} S("NextChapter", r[math.random(3)]) end
task.spawn(function()
	while true do
		S("PageFlipAt", now() + C.PAGE_EVERY)
		-- Neo trong Phòng khách làm trang sách đứng yên
		Core.waitUnfrozen(S, G, "Room4", C.PAGE_EVERY - 3, {"PageFlipAt"})
		if not playing() then continue end
		notify("📖 Từ phòng khách vọng lại tiếng LẬT TRANG... đèn ngủ chập chờn.")
		play(IX.NightLight, "PageFlip")
		for _ = 1, 6 do IX.NightLight.PointLight.Enabled = false task.wait(0.25) IX.NightLight.PointLight.Enabled = true task.wait(0.25) end
		local ch = G("NextChapter") or "Room1"
		S("Chapter", ch) S("ChapterUntil", now() + C.CHAPTER_LEN)
		pickNext()
		notify("📖 Kẻ Gieo Mộng bắt đầu kể chương: " .. string.upper(ROOM_NAME[ch]) .. " — ở đó mọi thứ nhanh hơn!")
		if G("Phase") == "TruyNguyen" then
			-- nó viết lại bìa sách mỗi lần lật trang
			task.defer(function() if G("Phase") == "TruyNguyen" and shufflePuzzle then shufflePuzzle() notify("Các cuốn truyện trên kệ tự đổi chỗ cho nhau...") end end)
		end
	end
end)

-- ===== ĐỘ SÂU GIẤC MỘNG + MỰC ĐỎ =====
-- Depth 3 → 2 (giải Truy Nguyên) → 1 (Thanh Tẩy) → 0 (Cổng mở). Vỡ khúc 1 và 2 kèm 1 dòng MỰC ĐỎ (báo trước 5 giây).
local RED_MSG = {
	"✒ MỰC ĐỎ — Lớp học: khi cô quay xuống, phải NHÌN THẲNG vào cô.",
	"✒ MỰC ĐỎ — Khu rừng trong tranh: khi đom đóm tắt, KHÔNG được đứng yên quá 2 giây.",
}
local function dropDepth()
	local d = math.max(0, (G("Depth") or 3) - 1)
	S("Depth", d)
	local seeder = IX.Seeder
	pcall(function() seeder.Mask.Color = Color3.fromRGB(170, 80, 255):Lerp(Color3.fromRGB(255, 40, 60), (3 - d) / 3) end)
	pcall(function() seeder.Head.Whisper.Volume = 0.8 + (3 - d) * 0.4 end)
	IX.NightLight.PointLight.Range = C.NIGHT_RADIUS[d] or 15
	local red = 3 - d -- d = 2 → mực đỏ 1, d = 1 → mực đỏ 2
	if RED_MSG[red] then
		notify("Tiếng bút sột soạt... TỜ NỘI QUY đang phát sáng. Có ai đó đang VIẾT LẠI một dòng!")
		S("RedInkPending", red)
		task.delay(5, function()
			if not active() then return end
			S("RedInk", red) S("RedInkPending", 0)
			notify(RED_MSG[red] .. " (bấm M để đọc lại)")
		end)
	end
end

-- ===== CỬA (F) =====
local doorCtl = Core.wireDoors(map.Doors, {dist = 11, lockedMsg = "Cánh cửa đã bị khâu kín bằng chỉ đen...",
	canUse = function(p) return alive(p) end})

-- ===== DẤU HIỆU (cố định 3) =====
local SIGN_KEYS = {"Name", "Number13", "Boy"}
local SIGN_NAMES = {Name = "Cái tên MINH trên bảng đen", Number13 = "Loa gọi SỐ 13", Boy = "Cậu bé đứng trong bức tranh"}
local SIGN_MEMORY = {
	Name = "“Mẹ gọi tên con mỗi sáng… nhưng con không trả lời được.”",
	Number13 = "“Số 13 được gọi mãi… mà không ai đến đón.”",
	Boy = "“Con đi lạc vì chiếc la bàn chỉ về phía CUỐN TRUYỆN chú kể.”",
}
local SIGN_PART = {Name = IX.Clue_Name, Number13 = IX.Clue_Number, Boy = IX.Clue_Boy}
local liveUntil = {}
local function setSignVisual(key, on)
	local part = SIGN_PART[key]
	part.Transparency = on and (key == "Boy" and 0.2 or 0.3) or 1
end
local function makeLive(key)
	if G("Phase") ~= "TrinhSat" or G("Sign_" .. key) then return end
	liveUntil[key] = os.clock() + C.SIGN_LIVE S("SignLive_" .. key, true)
end
local function registerSign(key)
	if G("Sign_" .. key) or not G("SignLive_" .. key) then return end
	S("Sign_" .. key, true) S("SignLive_" .. key, false)
	S("Signs", (G("Signs") or 0) + 1)
	for _, o in ipairs(lPlayers()) do Remotes.Notify:FireClient(o, "__MEMORY__|" .. SIGN_NAMES[key] .. "|" .. SIGN_MEMORY[key]) end
	if G("Signs") >= 3 then
		S("Phase", "TruyNguyen")
		for i = 1, 5 do en(IX["Puzzle" .. i], true) end
		notify("Đủ 3 Dấu Hiệu! Về PHÒNG NGỦ, tìm trên kệ đúng cuốn truyện khớp cả 3 ký ức.")
	end
end
for key, part in pairs(SIGN_PART) do
	prompt(part, "Ghi nhận", "Điều kỳ lạ", 1, function(p)
		if G("SignLive_" .. key) then registerSign(key) else notify("Không có gì lạ ở đây... lúc này.", p) end
	end, Enum.KeyCode.R)
end

-- ===== TỜ NỘI QUY + SỔ TRỰC CỦA MẸ =====
prompt(IX.RulesPaper, "Nhặt", "Truyện trước giờ ngủ (nội quy)", 0.5, function(p)
	p:SetAttribute("HasRules4", true)
	giveTool(p, "NoiQuyNha", "Nội quy của căn nhà (cầm lên để đọc · M)", Vector3.new(1.4, 0.05, 1.9), Color3.fromRGB(236, 228, 205))
	Remotes.Notify:FireClient(p, "__L4RULES__")
end)
prompt(IX.MomDiary, "Đọc", "Sổ trực của mẹ", 1, function(p)
	p:SetAttribute("HasLog4", true)
	giveTool(p, "SoTrucCuaMe", "Sổ trực của mẹ (cầm lên để đọc)", Vector3.new(1.3, 0.3, 1.8), Color3.fromRGB(160, 90, 110))
	Remotes.Notify:FireClient(p, "__DIARY4__")
end)

-- ===================================================================
-- ROOM1 — LỚP HỌC TRONG TỦ SÁCH (mặt nạ Cô Giáo): viết bảng 10–14s → "E hèm" 2s → QUAY XUỐNG 5s
-- Luật: cô quay xuống thì không di chuyển (10) · tên ai trên bảng người đó lên bục trước khi cô quay xuống (15)
--       bục giảng chỉ dành cho người có tên trên bảng (8) · [Mực đỏ 1] cô quay xuống phải nhìn thẳng vào cô (8)
-- Thưởng: lần đầu lên bục đúng lúc → MẢNH NEO 1 (viên phấn)
-- Dấu hiệu: lúc cô quay xuống, bảng hiện tên MINH
-- ===================================================================
local BOARD = IX.Blackboard
local TEACHER = IX.Teacher
local TEACHER_HOME = TEACHER:GetPivot()
local function boardText(t, red)
	pcall(function() BOARD.SurfaceGui.Text.Text = t BOARD.SurfaceGui.Text.TextColor3 = red and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(240, 240, 230) end)
end
local function teacherFace(toBoard)
	local pos = TEACHER_HOME.Position
	local look = toBoard and Vector3.new(pos.X, pos.Y, BOARD.Position.Z) or Vector3.new(pos.X, pos.Y, pos.Z + 10)
	TEACHER:PivotTo(CFrame.lookAt(pos, look))
end
task.spawn(function()
	while true do
		S("TeacherLooking", false) teacherFace(true) play(BOARD, "Chalk")
		-- chọn 1 người trong lớp để viết tên vai lên bảng
		local here = inRoom("Room1")
		local target = (#here > 0 and math.random() < 0.7) and here[math.random(#here)] or nil
		S("BoardTarget", target and target.Name or "") S("PodiumDone", false)
		boardText(target and ("Lên bục: " .. (ROLE_VN[target:GetAttribute("Role") or ""] or target.DisplayName)) or "Bài hôm nay: CHUYỆN TRƯỚC GIỜ NGỦ")
		local w = math.random(10, 14) * chapterMul("Room1")
		S("TeacherTurnAt", now() + w + 2)
		Core.waitUnfrozen(S, G, "Room1", w, {"TeacherTurnAt"})
		if not awake("Room1") then stop(BOARD, "Chalk") continue end
		holdWhileLulled("Room1", "TeacherTurnAt")
		stop(BOARD, "Chalk") play(TEACHER.Head, "Ahem")
		Core.say(TEACHER, "E hèm...", 2) say("Room1", "“E hèm…” — cô sắp quay xuống!")
		task.wait(2)
		-- người có tên trên bảng mà chưa lên bục
		local tn = G("BoardTarget")
		if tn ~= "" and not G("PodiumDone") then
			local tp = Players:FindFirstChild(tn)
			if tp and alive(tp) and tp:GetAttribute("Room4") == "Room1" and not calm("Room1") then
				violate(tp, "Lớp học — tên bạn trên bảng mà bạn KHÔNG LÊN BỤC", 15)
			end
		end
		S("BoardTarget", "")
		teacherFace(false) S("TeacherLooking", true) S("TeacherLookSince", os.clock())
		makeLive("Name")
		if G("SignLive_Name") then boardText("MINH", true) else boardText("") end
		local d = 5 * chapterMul("Room1") S("TeacherBackAt", now() + d)
		Core.waitUnfrozen(S, G, "Room1", d, {"TeacherBackAt"})
		S("TeacherLooking", false)
	end
end)
prompt(IX.Podium, "Lên bục", "Bục giảng", 2, function(p)
	if not playing() then return end
	if G("BoardTarget") == p.Name and not G("TeacherLooking") then
		S("PodiumDone", true)
		notify("Bạn đứng lên bục đúng lúc. Cô gật đầu...", p)
		if not G("Shard1Given") then
			S("Shard1Given", true) show(IX.AnchorShard1, true) IX.AnchorShard1.PointLight.Brightness = 1
			notify("Trên bàn cô hiện ra một VIÊN PHẤN phát sáng — MẢNH NEO!", inRoom("Room1"))
		end
	elseif G("BoardTarget") == p.Name then
		notify("Muộn rồi — cô đã quay xuống!", p)
	elseif not calm("Room1") then
		violate(p, "Lớp học — bục giảng chỉ dành cho người có TÊN TRÊN BẢNG", 8)
	end
end)

-- ===================================================================
-- ROOM2 — PHÒNG CHỜ DƯỚI GẦM GIƯỜNG (mặt nạ Thu Ngân): im 12–16s → chuông 2s → LOA GỌI SỐ 6s
-- Luật: chỉ lên quầy khi số của bạn được gọi (8) · loa gọi SỐ 00 thì ngồi vào hàng ghế (10)
--       đèn quầy đỏ thì không lại gần quầy (8)
-- Thưởng: trình số đúng lượt → MẢNH NEO 2 (vòng tay bệnh viện) · Dấu hiệu: cứ 3 lượt loa gọi SỐ 13 (không ai cầm)
-- ===================================================================
local QB = IX.QueueBoard
local function qbText(t) pcall(function() QB.SurfaceGui.Text.Text = t end) end
local function counterRed(on)
	IX.CounterLight.Color = on and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 220, 120)
	IX.CounterLight.PointLight.Color = IX.CounterLight.Color
	S("CounterRed", on)
end
local callCount, callStart = 0, 0
local callHit = {}
local function giveTicket(p)
	if p:GetAttribute("QueueNo") then return end
	local used = {} for _, o in ipairs(lPlayers()) do if o:GetAttribute("QueueNo") then used[o:GetAttribute("QueueNo")] = true end end
	local n repeat n = math.random(1, 9) until not used[n]
	p:SetAttribute("QueueNo", n)
	notify("Một bàn tay đưa bạn tờ phiếu: SỐ " .. string.format("%02d", n) .. ". Chờ tới lượt.", p)
end
task.spawn(function()
	while true do
		S("CallNo", -1) counterRed(false) qbText("--")
		local w = math.random(12, 16) * chapterMul("Room2") S("CallAt", now() + w + 2)
		Core.waitUnfrozen(S, G, "Room2", w, {"CallAt"})
		if not awake("Room2") then continue end
		holdWhileLulled("Room2", "CallAt")
		play(QB, "Chime") say("Room2", "*ding-dong*... loa phòng chờ rè rè.")
		task.wait(2)
		callCount += 1
		local n
		if callCount % 3 == 0 then n = 13
		elseif math.random() < 0.25 then n = 0
		else
			local here = inRoom("Room2") local nums = {}
			for _, p in ipairs(here) do if p:GetAttribute("QueueNo") then table.insert(nums, p:GetAttribute("QueueNo")) end end
			n = (#nums > 0 and math.random() < 0.6) and nums[math.random(#nums)] or math.random(1, 9)
		end
		S("CallNo", n) qbText(string.format("%02d", n)) callStart = os.clock()
		for k in pairs(callHit) do callHit[k] = nil end
		if n == 0 then counterRed(true) say("Room2", "📢 “MỜI SỐ 00…” — đèn quầy chuyển ĐỎ!")
		else say("Room2", "📢 “Mời số " .. string.format("%02d", n) .. " lên quầy.”") end
		if n == 13 then makeLive("Number13") end
		local d = 6 * chapterMul("Room2") S("CallEndAt", now() + d)
		Core.waitUnfrozen(S, G, "Room2", d, {"CallEndAt"})
	end
end)
prompt(IX.Counter, "Trình số", "Quầy thu ngân", 1, function(p)
	if not playing() then return end
	local mine = p:GetAttribute("QueueNo")
	if mine and G("CallNo") == mine then
		S("CallNo", -1) qbText("--")
		Core.say(IX.Cashier, "Mời em... đeo cái này vào.", 3)
		if not G("Shard2Given") then
			S("Shard2Given", true) show(IX.AnchorShard2, true) IX.AnchorShard2.PointLight.Brightness = 1
			notify("Thu ngân đặt lên quầy một VÒNG TAY BỆNH VIỆN ghi tên “MINH” — MẢNH NEO!", inRoom("Room2"))
		else notify("Thu ngân đóng dấu vào phiếu của bạn.", p) end
		p:SetAttribute("QueueNo", nil) giveTicket(p)
	elseif not calm("Room2") then
		violate(p, "Phòng chờ — bạn lên quầy khi CHƯA TỚI SỐ của mình", 8)
	end
end)

-- ===================================================================
-- ROOM3 — KHU RỪNG TRONG BỨC TRANH: đom đóm sáng 16s → nháy 2s → TẮT 6s
-- Luật: đom đóm tắt thì đứng yên (8) [Mực đỏ 2: tắt thì KHÔNG đứng yên quá 2s] · không bước ra khỏi khung tranh (10)
--       không Ping (8)
-- Thưởng: tuân luật trọn một lần tắt → MẢNH NEO 3 (kim la bàn) · Dấu hiệu: khi đom đóm sáng lại, nếu Ngưỡng Thức < 70 hoặc đã quá 3 phút
-- ===================================================================
local FLIES = IX.Fireflies:GetChildren()
local function setFlies(on)
	for _, f in ipairs(FLIES) do
		f.Transparency = on and 0 or 1
		local l = f:FindFirstChildOfClass("PointLight") if l then l.Enabled = on end
	end
end
local obeyOK = {}
local stillSince = {}
local function threshold()
	local sum, n, dreaming = 0, 0, 0
	for _, p in ipairs(lPlayers()) do
		if p:GetAttribute("Dreaming") then dreaming += 1 elseif Core.alive(p) then sum += p:GetAttribute("Sanity") or 0 n += 1 end
	end
	return (n > 0 and sum / n or 0) - 5 * dreaming
end
task.spawn(function()
	while true do
		setFlies(true) S("FireflyOn", true)
		local w = 16 * chapterMul("Room3") S("FireflyOffAt", now() + w + 2)
		Core.waitUnfrozen(S, G, "Room3", w, {"FireflyOffAt"})
		if not awake("Room3") then continue end
		holdWhileLulled("Room3", "FireflyOffAt")
		say("Room3", "Đàn đom đóm nhấp nháy dồn dập...")
		for _ = 1, 5 do setFlies(false) task.wait(0.2) setFlies(true) task.wait(0.2) end
		for k in pairs(obeyOK) do obeyOK[k] = nil end
		for k in pairs(stillSince) do stillSince[k] = nil end
		for _, p in ipairs(inRoom("Room3")) do obeyOK[p] = true end
		setFlies(false) S("FireflyOn", false)
		local d = 6 * chapterMul("Room3") S("FireflyOnAt", now() + d)
		Core.waitUnfrozen(S, G, "Room3", d, {"FireflyOnAt"})
		setFlies(true) S("FireflyOn", true)
		for p, ok in pairs(obeyOK) do
			if ok and alive(p) and p:GetAttribute("Room4") == "Room3" and not G("Shard3Given") then
				S("Shard3Given", true) show(IX.AnchorShard3, true) IX.AnchorShard3.PointLight.Brightness = 1
				notify(p.Name .. " làm đúng luật trọn bóng tối... một KIM LA BÀN đỏ cắm xuống cỏ — MẢNH NEO!")
			end
		end
		for k in pairs(obeyOK) do obeyOK[k] = nil end
		if threshold() < 70 or now() - (G("StartedAt") or now()) > 180 then makeLive("Boy") end
	end
end)
Remotes.Ping.OnServerEvent:Connect(function(p)
	if alive(p) and p:GetAttribute("Room4") == "Room3" and playing() and not calm("Room3") then
		violate(p, "Khu rừng trong tranh — bạn đã PING, tiếng vọng làm bức tranh rung lên", 8)
	end
end)

-- ===================================================================
-- ROOM4 — PHÒNG KHÁCH: KẺ GIEO MỘNG đọc truyện 15–20s → gập sách 2s → NGẨNG LÊN 5s
-- Luật: không bước vào bóng ghế bành (15) · khi nó ngẩng lên, nhìn thẳng vào nó (8) · không nhảy khi nó đang đọc (8)
-- Lúc THANH TẨY: nó rời ghế, RƯỢT người cầm cuốn truyện (chạm −20). Neo / Bài Ru làm nó đứng yên.
-- ===================================================================
local SEEDER = IX.Seeder
local SEED_HOME = SEEDER:GetPivot()
local function seederHead() return SEEDER.Head.Position end
local function chasing() return G("Phase") == "ThanhTay" end
task.spawn(function()
	while true do
		if chasing() then task.wait(0.5) continue end
		S("SeederState", "read")
		local w = math.random(15, 20) S("SeederLookAt", now() + w + 2)
		Core.waitUnfrozen(S, G, "Room4", w, {"SeederLookAt"})
		if not awake("Room4") or chasing() then continue end
		holdWhileLulled("Room4", "SeederLookAt")
		say("Room4", "*PẠCH* — cuốn sách gập lại. Nó sắp ngẩng lên...")
		task.wait(2)
		if chasing() then continue end
		S("SeederState", "look") S("SeederLookSince", os.clock())
		Core.say(SEEDER, "Ai đang nghe chuyện của ta?", 3)
		local d = 5 S("SeederReadAt", now() + d)
		Core.waitUnfrozen(S, G, "Room4", d, {"SeederReadAt"})
	end
end)
local function inBossDomain(pos) -- Phòng khách + hành lang phía Nam (nối về phòng ngủ)
	return Core.inZone(pos, Z.Room4, 4) or (math.abs(pos.X) <= 7 and pos.Z >= 2036 and pos.Z <= 2066)
end
local lostUntil = 0
local function hookJump(p, char)
	local hum = char:WaitForChild("Humanoid", 5) if not hum then return end
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping and alive(p) and p:GetAttribute("Room4") == "Room4"
			and G("SeederState") == "read" and not chasing() and playing() and not calm("Room4") then
			violate(p, "Phòng khách — bạn NHẢY khi nó đang đọc truyện", 8)
		end
	end)
end

-- ===== TRUY NGUYÊN: 5 cuốn truyện trên kệ phòng ngủ =====
local BOOKS = { -- 1 = đáp án đúng (khớp cả 3 ký ức: tên MINH · số 13 · hình la bàn)
	"Chuyện của MINH\nsố 13\n(hình la bàn)",
	"Chuyện của MINH\nsố 13\n(hình ngôi sao)",
	"Chuyện của MINH\nsố 31\n(hình la bàn)",
	"Chuyện của LINH\nsố 13\n(hình la bàn)",
	"Chuyện của MINH\nsố 18\n(hình mặt trăng)",
}
shufflePuzzle = function()
	local order = {1, 2, 3, 4, 5}
	for i = 5, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
	for slot = 1, 5 do
		pcall(function() IX["Puzzle" .. slot].SurfaceGui.Text.Text = BOOKS[order[slot]] end)
		if order[slot] == 1 then S("CorrectPuzzle", slot) end
	end
end
local TALE = IX.TaleBook
local TALE_HOME = TALE.CFrame
for slot = 1, 5 do
	prompt(IX["Puzzle" .. slot], "CHỌN", "Cuốn truyện " .. slot, 1, function(p)
		if G("Phase") ~= "TruyNguyen" then return end
		if slot == G("CorrectPuzzle") then
			S("Phase", "ThanhTay")
			for i = 1, 5 do en(IX["Puzzle" .. i], false) end
			show(TALE, true) TALE.PointLight.Brightness = 1.5
			dropDepth()
			notify("ĐÚNG — CUỐN TRUYỆN KHÔNG CÓ TRANG CUỐI! Nó vừa hiện trên BÀN CÔ GIÁO (Lớp học). Mang nó tới LÒ SƯỞI PHÒNG KHÁCH, giữ E " .. C.FIRE_HOLD .. " giây. Kẻ Gieo Mộng sẽ ĐỨNG DẬY!")
		else
			violate(p, "Sai rồi — cuốn truyện cười khúc khích trong tay bạn", 8)
		end
	end)
end

-- ===== THANH TẨY: cuốn truyện → lò sưởi (có rượt đuổi + truyền tay) =====
local carrier = nil
local function setSlow(p, on)
	local c = p.Character local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = on and C.CARRY_SPEED or (p:GetAttribute("Dreaming") and 22 or 16) end
end
local function resetBook(msg)
	if carrier then removeTool(carrier, "CuonTruyen") setSlow(carrier, false) end
	carrier = nil S("BookCarrier", "")
	TALE.CFrame = TALE_HOME
	local on = G("Phase") == "ThanhTay"
	show(TALE, on) TALE.PointLight.Brightness = on and 1.5 or 0
	if msg then notify(msg) end
end
local function dropBook(p) -- truyền tay: thả sách xuống chân, Kẻ Gieo Mộng mất dấu 3 giây
	if carrier ~= p then return end
	local r = hrp(p)
	removeTool(p, "CuonTruyen") setSlow(p, false) carrier = nil S("BookCarrier", "")
	if r then TALE.CFrame = CFrame.new(r.Position - Vector3.new(0, 2.6, 0)) end
	show(TALE, true) TALE.PointLight.Brightness = 1.5
	lostUntil = os.clock() + 3
	notify(p.Name .. " thả CUỐN TRUYỆN xuống — Kẻ Gieo Mộng mất dấu trong chốc lát. Ai đó nhặt lên đi!")
end
prompt(TALE, "Nhặt cuốn truyện", "Nguồn Ô Nhiễm", 1, function(p)
	if G("Phase") ~= "ThanhTay" or carrier then return end
	if (G("BookDeadline") or 0) == 0 then S("BookDeadline", now() + C.BOOK_TIME) end -- 90s tính từ lần nhặt ĐẦU
	carrier = p
	show(TALE, false) TALE.PointLight.Brightness = 0
	giveTool(p, "CuonTruyen", "Cuốn truyện không có trang cuối — CLICK để thả cho đồng đội. Mang tới lò sưởi phòng khách.",
		Vector3.new(1.6, 0.4, 2.2), Color3.fromRGB(40, 20, 30), function(pl) dropBook(pl) end)
	setSlow(p, true)
	S("BookCarrier", p.Name)
	notify(p.Name .. " cầm CUỐN TRUYỆN — nó nặng trĩu. Trong phòng khách, có thứ gì đó vừa rời khỏi ghế bành...")
end)
prompt(IX.Fireplace, "Ném truyện vào lửa", "Lò sưởi", C.FIRE_HOLD, function(p)
	if G("Phase") ~= "ThanhTay" then return end
	if carrier ~= p then notify("Cần mang CUỐN TRUYỆN tới đây.", p) return end
	removeTool(p, "CuonTruyen") setSlow(p, false) carrier = nil S("BookCarrier", "") S("BookDeadline", 0)
	S("Cleansed", true) S("Phase", "Neo")
	SEEDER:PivotTo(SEED_HOME)
	for _, o in ipairs(lPlayers()) do addSanity(o, 20) end
	dropDepth()
	notify("THANH TẨY thành công! Cuốn truyện cháy thành tro, Kẻ Gieo Mộng gào lên rồi lùi về ghế. (+20 Tỉnh táo) — Gom 3 Mảnh Neo, đặt vào Bệ Neo trong phòng ngủ.")
end)

-- ===== TRANG CUỐI (kết cục Bình Minh): nằm ở nơi DÒNG NÓI DỐI muốn bạn tránh xa =====
local function pageOn(i) return G("LieIndex") == i and not G("PageTaken") end
for i = 1, 4 do
	local pg = IX["LastPage" .. i]
	prompt(pg, "Nhặt", "Một trang giấy xé", 1, function(p)
		if not pageOn(i) then return end
		S("PageTaken", true) show(pg, false) pg.PointLight.Brightness = 0
		giveTool(p, "TrangCuoi", "Trang cuối của cuốn truyện — khi Cổng mở, đọc nó bên giường Minh", Vector3.new(1.4, 0.05, 1.9), Color3.fromRGB(255, 245, 200))
		notify(p.Name .. " tìm thấy TRANG CUỐI của câu chuyện. Chữ viết tay của một đứa trẻ: “…và rồi cậu bé THỨC DẬY.”")
	end)
end
prompt(IX.Bed, "Đọc trang cuối", "Giường của Minh", C.PAGE_READ_HOLD, function(p)
	if G("Phase") ~= "Gate" or G("PageRead") then return end
	if not Core.hasTool(p, "TrangCuoi") then notify("Minh đang ngủ rất say...", p) return end
	removeTool(p, "TrangCuoi") S("PageRead", true)
	notify("📖 " .. p.Name .. " đọc to trang cuối: “…và rồi cậu bé THỨC DẬY.” — Mi mắt của Minh khẽ động!")
end)

-- ===== MẢNH NEO / BỆ NEO / CỔNG =====
for i = 1, 3 do
	local sh = IX["AnchorShard" .. i]
	prompt(sh, "Nhặt", "Mảnh Neo Thức", 0.5, function(p)
		if sh.Transparency >= 1 then return end
		show(sh, false) sh.PointLight.Brightness = 0
		S("Shards", (G("Shards") or 0) + 1)
		notify(p.Name .. " nhặt Mảnh Neo (" .. G("Shards") .. "/3)")
	end)
end
local escape = Core.newEscape({gate = IX.Gate, S = S, G = G, doors = doorCtl, players = lPlayers, alive = alive,
	escapeTime = C.ESCAPE_TIME, gateTime = C.GATE_TIME, notify = notify,
	safe = function(p) return roomOf(hrp(p).Position) == "Lobby" end,
	target = function() local esc = workspace:FindFirstChild("DreamMap") and workspace.DreamMap:FindFirstChild("EscapeRoom") return esc and esc:GetPivot() end,
	openMsg = "MỌI QUY LUẬT ĐÃ BIẾN MẤT. Căn nhà đang sập — " .. C.ESCAPE_TIME .. " giây nữa mọi cánh cửa khâu kín. CHẠY VỀ PHÒNG NGỦ, bước qua CỬA SỔ BÌNH MINH! (Ai có Trang Cuối: đọc nó bên giường Minh)",
	trappedMsg = "Cánh cửa khâu kín sau lưng bạn... Kẻ Gieo Mộng mỉm cười: “Người ngủ mới.”",
	onOpen = function() resetBook() dropDepth() end})
prompt(IX.AnchorAltar, "Đặt Mảnh Neo", "Bệ Neo", 1, function(p)
	if G("Phase") == "Gate" then return end
	if (G("Shards") or 0) < 3 then notify("Cần đủ 3 Mảnh Neo (đang có " .. (G("Shards") or 0) .. ").", p) return end
	if not G("Cleansed") then notify("Bệ Neo không phản ứng... Cuốn truyện vẫn còn đó. Hãy THANH TẨY trước.", p) return end
	escape.open()
end)

-- ===== KỸ NĂNG THEO PHÒNG =====
local function secs(attr) return math.max(0, math.floor((G(attr) or 0) - now())) end
local function divineL4(p, room)
	if room == "Lobby" or room == "Hall" then
		local ph = G("Phase")
		local nx = "\nTrang kế tiếp (sau " .. secs("PageFlipAt") .. " giây) sẽ kể: " .. string.upper(ROOM_NAME[G("NextChapter") or "Room1"]) .. "."
		if ph == "TrinhSat" then
			local left = {} for _, k in ipairs(SIGN_KEYS) do if not G("Sign_" .. k) then table.insert(left, SIGN_NAMES[k]) end end
			return "Còn thiếu: " .. table.concat(left, " · ") .. ".\nSổ trực của mẹ ghi KHI NÀO chúng hiện ra." .. nx
		elseif ph == "TruyNguyen" then return "Một cái tên, một con số, một hình vẽ. Lần lật trang tới, các cuốn truyện sẽ đổi chỗ." .. nx
		elseif ph == "ThanhTay" then
			return (carrier and ("Cuốn truyện trong tay " .. string.upper(carrier.DisplayName) .. " — còn " .. secs("BookDeadline") .. " giây.") or "Cuốn truyện chờ trên bàn cô giáo.")
				.. "\nTrong phòng khách, nó sẽ lao theo người cầm sách. Thả sách (click) để nó mất dấu." .. nx
		elseif ph == "Neo" then return "Mảnh Neo: " .. (G("Shards") or 0) .. "/3. Có một trang giấy ở nơi lời nói dối muốn các con tránh xa..." .. nx end
		return nil
	elseif room == "Room1" then
		return G("TeacherLooking") and ("Cô còn nhìn xuống " .. secs("TeacherBackAt") .. " giây nữa — đứng yên!")
			or ("Cô sẽ quay xuống sau khoảng " .. secs("TeacherTurnAt") .. " giây." .. ((G("BoardTarget") or "") ~= "" and ("\nTên trên bảng: " .. G("BoardTarget") .. " — lên bục ngay!") or ""))
	elseif room == "Room2" then
		local mine = p:GetAttribute("QueueNo")
		return "Loa sẽ gọi số sau khoảng " .. secs("CallAt") .. " giây." .. (mine and ("\nSố của bạn: " .. string.format("%02d", mine) .. ".") or "")
			.. ((callCount + 1) % 3 == 0 and "\nLượt tới: số không ai cầm." or "")
	elseif room == "Room3" then
		return G("FireflyOn") and ("Đom đóm sẽ TẮT sau khoảng " .. secs("FireflyOffAt") .. " giây.")
			or ("Đom đóm sáng lại sau " .. secs("FireflyOnAt") .. " giây.")
	elseif room == "Room4" then
		if chasing() then return "Nó đang săn cuốn truyện. Neo nó lại khi người cầm sách giữ E ở lò sưởi!" end
		return G("SeederState") == "look" and ("Nó còn ngẩng lên " .. secs("SeederReadAt") .. " giây — nhìn thẳng vào nó!")
			or ("Nó sẽ gập sách, ngẩng lên sau khoảng " .. secs("SeederLookAt") .. " giây.")
	end
end
local LULL_ATTR = {Room1 = "TeacherTurnAt", Room2 = "CallAt", Room3 = "FireflyOffAt", Room4 = "SeederLookAt"}
local LULL_MSG = {Room1 = "Cô giáo viết chậm lại, ngáp một cái...", Room2 = "Loa phòng chờ im bặt thêm một lúc.",
	Room3 = "Đom đóm sáng dịu, lâu thêm một chút...", Room4 = "Kẻ Gieo Mộng lim dim... đọc chậm lại."}
local function lullL4(p, room)
	if not LULL_ATTR[room] then return end
	local untilT = now() + C.LULL_EXTRA
	S("Lull_" .. room, untilT)
	local a = LULL_ATTR[room] if type(G(a)) == "number" then S(a, math.max(G(a), untilT)) end
	say(room, "♪ " .. LULL_MSG[room])
end

-- ===== BẮT ĐẦU / KẾT THÚC =====
local function spawnAt(p)
	local r = hrp(p) if r then r.Anchored = false r.CFrame = IX.Spawn4.CFrame + Vector3.new(math.random(-6, 6), 4, math.random(-3, 3)) end
end
local function startLevel4()
	S("Phase", "TrinhSat") S("Signs", 0) S("Shards", 0) S("Cleansed", false) S("Depth", 3) S("RedInk", 0) S("RedInkPending", 0)
	S("Shard1Given", false) S("Shard2Given", false) S("Shard3Given", false)
	S("PageTaken", false) S("PageRead", false) S("Ending", "") S("BookDeadline", 0) S("BookCarrier", "")
	S("Chapter", "") S("ChapterUntil", 0) pickNext()
	for _, k in ipairs(SIGN_KEYS) do S("Sign_" .. k, false) S("SignLive_" .. k, false) setSignVisual(k, false) liveUntil[k] = nil end
	S("LieIndex", math.random(4)) S("StartedAt", now())
	for _, r in ipairs(RULE_ROOMS) do S("Active_" .. r, false) end
	shufflePuzzle() for i = 1, 5 do en(IX["Puzzle" .. i], false) end
	for i = 1, 3 do show(IX["AnchorShard" .. i], false) IX["AnchorShard" .. i].PointLight.Brightness = 0 end
	for i = 1, 4 do local pg = IX["LastPage" .. i] local on = G("LieIndex") == i show(pg, on, 0.35) pg.PointLight.Brightness = on and 0.6 or 0 end
	IX.NightLight.PointLight.Range = C.NIGHT_RADIUS[3]
	for k in pairs(lastRoom) do lastRoom[k] = nil end for k in pairs(enterAt) do enterAt[k] = nil end for k in pairs(hitCd) do hitCd[k] = nil end
	callCount = 0
	carrier = nil resetBook() SEEDER:PivotTo(SEED_HOME)
	escape.reset()
	doorCtl.locked = false doorCtl.setAll(false)
	for _, p in ipairs(lPlayers()) do
		for _, a in ipairs({"HasRules4", "HasLog4", "QueueNo", "Room4"}) do p:SetAttribute(a, nil) end
		spawnAt(p)
	end
	notify("TẦNG CUỐI — CĂN NHÀ CỦA NGƯỜI NGỦ. Có ai đó đang ngủ trên chiếc giường kia... Nhặt TỜ NỘI QUY trên bàn học. Trên giường có SỔ TRỰC CỦA MẸ.")
end
local ENDING_MSG = {
	dawn = "BÌNH MINH — Minh đã thức dậy. Ở giường 13, máy đo tim kêu đều trở lại.",
	loop = "GIẤC MỘNG TIẾP DIỄN — Các em thoát ra... nhưng Kẻ Gieo Mộng lại mở một cuốn truyện mới.",
	left = "NGƯỜI KỂ CHUYỆN MỚI — Có người đã bị bỏ lại. Căn nhà có một người ngủ mới.",
}
local function endLevel4(win, msg)
	if G("Phase") == "Win" or G("Phase") == "Lose" then return end
	S("RoundTime", math.floor(now() - (G("StartedAt") or 0)))
	if win then
		local left = false
		for _, p in ipairs(lPlayers()) do if p:GetAttribute("Sanity") ~= nil and not p:GetAttribute("Escaped") then left = true end end
		local ending = left and "left" or (G("PageRead") and "dawn" or "loop")
		S("Ending", ending) msg = ENDING_MSG[ending]
		if Core.log then Core.log("ending", nil, ending) end
	end
	S("Phase", win and "Win" or "Lose")
	notify(msg)
	task.delay(win and 12 or 8, function() Core.finishLevel(LV, win) end)
end
local startEvent = SS:FindFirstChild("StartLevel4") or Instance.new("BindableEvent", SS) startEvent.Name = "StartLevel4"
startEvent.Event:Connect(function() Core.startLevel(LV) end)

Core.register(LV, {
	S = S, G = G, state = ST, escape = escape,
	name = "Căn Nhà Của Người Ngủ", start = function() Core.reloadLevel(script, "DreamMap4") end, loseRestart = true,
	sleep = function() S("Phase", "Idle") end,
	active = active,
	debug = { -- Studio: game.ServerStorage.CoreDebug:Invoke("lv", "<lệnh>")
		signs = function() for _, k in ipairs(SIGN_KEYS) do S("SignLive_" .. k, true) registerSign(k) end return "ok" end,
		thanh = function() S("Phase", "TruyNguyen") return "chọn cuốn " .. tostring(G("CorrectPuzzle")) end,
		neo = function() S("Phase", "Neo") S("Cleansed", true) S("Shards", 3) S("Depth", 1) return "ok" end,
		page = function() S("PageTaken", true) for _, p in ipairs(lPlayers()) do giveTool(p, "TrangCuoi", "Trang cuối", Vector3.new(1.4, 0.05, 1.9), Color3.fromRGB(255, 245, 200)) break end return "ok" end,
	},
	tools = {"NoiQuyNha", "SoTrucCuaMe", "CuonTruyen", "TrangCuoi"},
	onDream = function(p)
		if carrier == p then resetBook("Người cầm cuốn truyện đã hòa mộng — cuốn truyện quay về bàn cô giáo!") end
		if Core.hasTool(p, "TrangCuoi") then
			removeTool(p, "TrangCuoi") S("PageTaken", false)
			local pg = IX["LastPage" .. (G("LieIndex") or 1)] show(pg, true, 0.35) pg.PointLight.Brightness = 0.6
			notify("Trang cuối bay khỏi tay " .. p.Name .. ", trở về chỗ cũ...")
		end
	end,
	skill = {roomAttr = "Room4", safeRooms = {Hall = true, Lobby = true}, roomName = ROOM_NAME, divine = divineL4, onLull = lullL4,
		allowed = function(p) if not active() then return "" end end,
		onSeer = function(p) p:SetAttribute("SightRoom", p:GetAttribute("Room4")) end,
	},
})

-- ===== TICK CHÍNH =====
local TICK = 0.2
local function hookCharacter(p)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.3)
		if inL(p) then spawnAt(p) end
		hookJump(p, char)
	end)
	if p.Character then task.spawn(hookJump, p, p.Character) end
end
Players.PlayerAdded:Connect(hookCharacter)
for _, p in ipairs(Players:GetPlayers()) do hookCharacter(p) end
Players.PlayerRemoving:Connect(function(p) if carrier == p then resetBook("Người cầm cuốn truyện đã rời đi — cuốn truyện quay về bàn cô giáo.") end end)
if script:GetAttribute("Boot") == "start" then task.defer(startLevel4) end

while true do
	task.wait(TICK)
	local ph = G("Phase")
	if ph == "Idle" or ph == "Win" or ph == "Lose" then continue end
	local plist = lPlayers()
	local escaping = ph == "Gate"
	local nlPos, nlR = IX.NightLight.Position, IX.NightLight.PointLight.Range
	for _, p in ipairs(plist) do
		if alive(p) and not p:GetAttribute("Escaped") then
			local pos = hrp(p).Position
			local room = roomOf(pos)
			p:SetAttribute("Room4", room)
			if room ~= "Hall" and room ~= "Lobby" and not G("Active_" .. room) then S("Active_" .. room, true) end
			if lastRoom[p] ~= room then enterAt[p] = os.clock() end
			if room == "Room2" and lastRoom[p] ~= "Room2" and not escaping then giveTicket(p) end
			lastRoom[p] = room
			if not escaping then
				-- đèn ngủ hồi Tỉnh táo, vùng sáng co lại theo Độ Sâu Giấc Mộng
				Core.tickSanity(p, plist, room == "Lobby" and (pos - nlPos).Magnitude <= nlR, C, TICK)
				if room == "Room1" then
					if G("TeacherLooking") and not stillEntity("Room1") and settled(p) then
						if speed(p) > 1.5 and hitReady(p, "look1", 5) then violate(p, "Lớp học — bạn DI CHUYỂN khi cô đang nhìn xuống", 10) end
						if G("RedInk") >= 1 and os.clock() - (G("TeacherLookSince") or 0) > 1 and not facing(p, TEACHER.Head.Position)
							and hitReady(p, "red1", 5) then
							violate(p, "Lớp học (MỰC ĐỎ) — bạn KHÔNG NHÌN vào cô khi cô quay xuống", 8)
						end
					end
				elseif room == "Room2" then
					local cn = G("CallNo")
					if cn == 0 and not calm("Room2") and settled(p) and os.clock() - callStart > 1.5 and not callHit[p] and not inAny(IX.Seats, pos, nil, 12) then
						callHit[p] = true
						violate(p, "Phòng chờ — loa gọi SỐ 00 mà bạn KHÔNG NGỒI vào hàng ghế", 10)
					end
					if G("CounterRed") and not calm("Room2") and os.clock() - callStart > 1.5 and (flat(pos) - flat(IX.Counter.Position)).Magnitude < 9 and hitReady(p, "red2", 4) then
						violate(p, "Phòng chờ — bạn lại gần quầy khi ĐÈN ĐỎ", 8)
					end
				elseif room == "Room3" then
					if not G("FireflyOn") and not calm("Room3") and settled(p) then
						if G("RedInk") >= 2 then
							if speed(p) < 1 then
								stillSince[p] = stillSince[p] or os.clock()
								if os.clock() - stillSince[p] > 2 and hitReady(p, "still3", 3) then
									obeyOK[p] = false
									violate(p, "Khu rừng trong tranh (MỰC ĐỎ) — bạn ĐỨNG YÊN khi đom đóm tắt", 8)
								end
							else stillSince[p] = nil end
						elseif speed(p) > 1.5 then
							obeyOK[p] = false
							if hitReady(p, "dark3", 6) then violate(p, "Khu rừng trong tranh — bạn DI CHUYỂN khi đom đóm đã tắt", 8) end
						end
					end
					if not Core.inZone(pos, IX.FrameInside, 30) and hitReady(p, "frame3", 3) then -- padY lớn: nhảy không tính là ra khỏi tranh
						violate(p, "Khu rừng trong tranh — bạn BƯỚC RA KHỎI KHUNG TRANH", 10)
						local r = hrp(p) if r then r.CFrame = IX.Room3Start.CFrame + Vector3.new(0, 3, 0) end
					end
				elseif room == "Room4" then
					if inAny(IX.ChairShadow, pos, nil, 3) and not calm("Room4") and hitReady(p, "shadow4", 4) then
						violate(p, "Phòng khách — bạn BƯỚC VÀO BÓNG ghế bành", 15)
					end
					if not chasing() and G("SeederState") == "look" and not stillEntity("Room4") and settled(p) and os.clock() - (G("SeederLookSince") or 0) > 1
						and not facing(p, seederHead()) and hitReady(p, "look4", 6) then
						violate(p, "Phòng khách — bạn KHÔNG NHÌN vào nó khi nó ngẩng lên", 8)
					end
				end
			end
		end
	end

	-- RƯỢT ĐUỔI (Thanh Tẩy)
	if chasing() then
		local cur = SEEDER:GetPivot().Position
		local tgt = carrier and alive(carrier) and hrp(carrier) and os.clock() > lostUntil and inBossDomain(hrp(carrier).Position) and hrp(carrier).Position
		local goal = tgt or SEED_HOME.Position
		if not stillEntity("Room4") then
			local dir = flat(goal - cur)
			if dir.Magnitude > 0.5 then
				local np = cur + dir.Unit * math.min(dir.Magnitude, C.SEEDER_SPEED * TICK)
				SEEDER:PivotTo(CFrame.lookAt(np, np + dir.Unit))
			end
		end
		S("SeederHunting", tgt ~= nil and tgt ~= false)
		if tgt and (flat(tgt) - flat(cur)).Magnitude < 4 and not stillEntity("Room4") and hitReady(carrier, "seed", 4) then
			violate(carrier, "KẺ GIEO MỘNG CHẠM VÀO BẠN", 20)
			SEEDER:PivotTo(SEED_HOME) lostUntil = os.clock() + 3
		end
		if (G("BookDeadline") or 0) > 0 and now() > G("BookDeadline") then
			S("BookDeadline", 0) resetBook("Cuốn truyện TÁI SINH trên bàn cô giáo! (hết " .. C.BOOK_TIME .. " giây)")
			SEEDER:PivotTo(SEED_HOME)
		end
	end

	-- thua khi cả nhóm hòa mộng
	local anyAlive = false
	for _, p in ipairs(plist) do if alive(p) then anyAlive = true end end
	if #plist > 0 and not anyAlive then endLevel4(false, "CẢ NHÓM ĐÃ HÒA MỘNG. Kẻ Gieo Mộng khép sách lại... Chơi lại tầng cuối sau 8 giây.") continue end

	-- dấu hiệu hết thời gian xuất hiện
	for _, k in ipairs(SIGN_KEYS) do
		local live = G("SignLive_" .. k) == true and liveUntil[k] ~= nil and os.clock() < liveUntil[k] and not G("Sign_" .. k)
		if G("SignLive_" .. k) and not live then S("SignLive_" .. k, false) end
		setSignVisual(k, live)
	end

	if escaping then
		local r = escape.tick()
		if r == true then endLevel4(true) continue
		elseif r == false then endLevel4(false, "Cửa sổ khép lại. Căn nhà giữ tất cả các em trong giấc ngủ.") end
	end
end
