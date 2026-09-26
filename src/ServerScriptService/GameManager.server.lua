-- DREAM LAYERS - Prototype 2 người (Tầng: Lớp Học Vỡ, 3 phòng)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Remotes = RS:WaitForChild("Remotes")
local Core = require(game:GetService("ServerScriptService"):WaitForChild("LevelCore"))
local map = workspace:WaitForChild("DreamMap")
local IX = map.Interactables
local Z = map.Zones

-- ===== CẤU HÌNH =====
local C = {
	DARK_DRAIN = 0.4, NEAR_HEAL = 0.5, NEAR_CAP = 70, LIGHT_HEAL = 1, LIGHT_CAP = 80,
	HEALER_AURA = 1, HEALER_RANGE = 12, NEAR_RANGE = 10,
	RULE_PENALTY = 8, STALKER_TOUCH = 20, STALKER_SPEED = 10, STALKER_START = 45,
	WITNESS = 10, CLEANSE_BONUS = 20, CLEANSE_TIME = 10, NOTEBOOK_TIMEOUT = 90,
	SEER = {max = 80, cost = 5, cd = 25, dur = 8},
	HEALER = {max = 100, cost = 5, cd = 35, heal = 20, range = 20, revive = 40, calm = 10},
	SHADOW_THRESHOLD = 79, ANTI_STUCK = 180, GATE_TIME = 60,
	TEACHER_PENALTY = 10, TASK_TIME = 150, TASK_FAIL = 15, TASK_REWARD = 20,
	STALKER_ENABLED = false, -- tạm tắt Kẻ Đứng Sau Cửa
	BOARD_LIMIT = 5, STILL_LIMIT = 4, WHISPER_LIMIT = 3, WHISPER_RANGE = 5,
}
local K = 1.2 -- tỉ lệ map (đã phóng to 1.2 lần)
local NOTEBOOK_HOME = Vector3.new(-14, 3.2, -27) * K
local CHALK_HOME = Vector3.new(104, 1, 24) * K
local BOOK_HOME = Vector3.new(-104, 1, 24) * K
local STALKER_HOME = Vector3.new(-100, 4.5, 0) * K
-- kẻ địch (gán thật ở mục KẺ ĐỊCH bên dưới)
local libraryNoise = function(pos, loud, who) end
local lastNoise = {} -- [player] = os.clock() lần cuối gây tiếng động lớn
local resetEnemies = function() end

local State, S, G = Core.state("GameState")

local function notify(msg, who) Core.notify(msg, who) end
local hrp, speed, maxSan, addSanity, alive = Core.hrp, Core.speed, Core.maxSan, Core.addSanity, Core.alive
local function inZone(pos, zone) return Core.inZone(pos, zone, 0) end
local tempLights = {} -- {pos, untilT}
local function inLight(pos)
	if inZone(pos, Z.LampZone) or inZone(pos, Z.HallZone) then return true end
	for _, l in ipairs(tempLights) do if os.clock() < l.t and (l.pos - pos).Magnitude < 12 then return true end end
	return false
end
local function roomOf(pos)
	local x, z = pos.X / K, pos.Z / K
	if x < -50.5 and math.abs(z) < 30.5 then return "West" end
	if x > 50.5 and math.abs(z) < 30.5 then return "East" end
	if math.abs(x) < 50.5 and z > -35.5 and z < 35.5 then return "Class" end
	if z >= 35.5 then return "Hall" end
	return "None"
end


local stalkerPauseUntil = 0
local function moveStalkerNear(pos, dist)
	if not C.STALKER_ENABLED then return end
	local a = math.random() * math.pi * 2
	local x = math.clamp(pos.X + math.cos(a) * dist, -108 * K, 108 * K)
	local z = math.clamp(pos.Z + math.sin(a) * dist, -33 * K, 63 * K)
	IX.Stalker.Position = Vector3.new(x, 4.5 * K, z)
	S("StalkerActive", true)
end

local violate = Core.newRules({prefix = "⚠ PHẠM LUẬT: ", penalty = C.RULE_PENALTY, notify = notify,
	blocked = function() return G("Phase") == "Gate" end, -- đã đặt Mảnh Neo: mọi quy luật biến mất
	after = function(p) if math.random() < 0.25 and hrp(p) then moveStalkerNear(hrp(p).Position, 22) end end})

-- ===== VAI TRÒ (dùng chung LevelCore) =====
ROLES = Core.ROLE
ROLE_ORDER = Core.ROLE_ORDER
roleTaken = Core.roleTaken
local setGhost = Core.setGhost

-- ===== PROMPT =====
local prompt = Core.newPrompter(function() return not G("RoundOver") end)
local show, en = Core.show, Core.en

-- ===== GIÁO VIÊN & NHIỆM VỤ =====
local teacher = IX.Teacher
local teacherBase = teacher:GetPivot()
local function teacherSay(txt, dur) Core.say(teacher, txt, dur or 4) end
local currentTask, taskDeadline, taskProgress = nil, 0, 0
local taskSteps, stepIndex = nil, 0
local STEPS = {
	Wipe = {id = "Wipe", say = "Lên LAU BẢNG cho cô!", hint = "Lau bảng: giữ E ở bảng đen"},
	Chalk = {id = "Chalk", say = "Sang PHÒNG NHẠC lấy HỘP PHẤN cho cô.", hint = "Lấy hộp phấn ở Phòng nhạc → nộp ở bàn giáo viên"},
	Book = {id = "Book", say = "Vào THƯ VIỆN lấy SỔ ĐIỂM cho cô.", hint = "Lấy sổ điểm ở Thư viện → nộp ở bàn giáo viên"},
	Sit = {id = "Sit", say = "CẢ LỚP VỀ CHỖ! Đứng yên cạnh bàn.", hint = "Tất cả đứng yên cạnh một cái bàn trong lớp 8 giây"},
}
-- Mỗi yêu cầu gồm nhiều bước, phải làm lần lượt
local TASKS = {{"Wipe"}, {"Chalk"}, {"Book"}, {"Sit"}}
-- Thời gian = quãng đường ước tính / tốc độ đi bộ + thời gian thao tác + ~10 giây dư
local WALK = 16
local function taskTime(id)
	local alivePs = {}
	for _, p in ipairs(Players:GetPlayers()) do if alive(p) then table.insert(alivePs, p) end end
	if #alivePs == 0 then return 20 end
	local desk = IX.TeacherDesk.Position
	local function best(fn) local b = math.huge for _, p in ipairs(alivePs) do b = math.min(b, fn(hrp(p).Position)) end return b end
	local function worst(fn) local w = 0 for _, p in ipairs(alivePs) do w = math.max(w, fn(hrp(p).Position)) end return w end
	local travel, action = 0, 1
	if id == "Wipe" then travel = best(function(pos) return (pos - IX.Blackboard.Position).Magnitude end) action = 3
	elseif id == "Chalk" then travel = best(function(pos) return (pos - CHALK_HOME).Magnitude end) + (CHALK_HOME - desk).Magnitude action = 2
	elseif id == "Book" then travel = best(function(pos) return (pos - BOOK_HOME).Magnitude end) + (BOOK_HOME - desk).Magnitude action = 2
	elseif id == "Sit" then travel = worst(function(pos) return (pos - Vector3.new(0, pos.Y, 4 * K)).Magnitude end) action = 8 end
	return math.max(15, math.ceil(travel / WALK * 1.4 + action + 14))
end
-- ===== ĐỒ CẦM TAY (Tool) =====
local TOOL_DEF = {
	Chalk = {name = "HopPhan", tip = "Hộp phấn (nộp ở bàn giáo viên)", size = Vector3.new(1.4, 0.6, 0.8), color = Color3.fromRGB(240, 240, 230)},
	Book = {name = "SoDiem", tip = "Sổ điểm (nộp ở bàn giáo viên)", size = Vector3.new(1.6, 0.4, 2), color = Color3.fromRGB(40, 60, 120)},
	Diary = {name = "NhatKy", tip = "Nhật ký học sinh cũ (cầm lên để đọc)", size = Vector3.new(1.2, 0.3, 1.6), color = Color3.fromRGB(95, 30, 30)},
	Rules = {name = "ToNoiQuy", tip = "Tờ nội quy tầng (cầm lên để đọc · M)", size = Vector3.new(1.4, 0.05, 1.9), color = Color3.fromRGB(240, 232, 205)},
}
local hasTool = Core.hasTool
local function giveTool(p, key) local d = TOOL_DEF[key] return Core.giveTool(p, d.name, d.tip, d.size, d.color) end
local function removeTool(p, key) Core.removeTool(p, TOOL_DEF[key].name) end
local function clearTaskItems()
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("Carrying", nil) removeTool(p, "Chalk") removeTool(p, "Book")
	end
	IX.Chalk.Position = CHALK_HOME IX.TaskBook.Position = BOOK_HOME
	IX.Chalk.Transparency = 0 IX.TaskBook.Transparency = 0
end

local function setStep(t)
	currentTask = t taskProgress = 0
	en(IX.Blackboard, t ~= nil and t.id == "Wipe")
	en(IX.Chalk, t ~= nil and t.id == "Chalk")
	en(IX.TaskBook, t ~= nil and t.id == "Book")
	en(IX.TeacherDesk, t ~= nil and (t.id == "Chalk" or t.id == "Book"))
	if t then
		S("TaskText", t.hint)
	else S("TaskText", "") end
end
local function setTask(list)
	if not list then taskSteps = nil stepIndex = 0 setStep(nil) return end
	taskSteps = list stepIndex = 1
	local T = taskTime(list[1])
	taskDeadline = os.clock() + T
	S("TaskDeadline", workspace:GetServerTimeNow() + T)
	setStep(STEPS[list[1]])
end
local function finishTask(ok)
	if not currentTask then return end
	clearTaskItems()
	if ok and stepIndex < #taskSteps then
		stepIndex += 1
		local nxt = STEPS[taskSteps[stepIndex]]
		teacherSay("Được. Giờ thì... " .. nxt.say)
		notify("Xong bước " .. (stepIndex - 1) .. "! Cô giáo nói tiếp: " .. nxt.say)
		setStep(nxt)
		return
	end
	if ok then
		for _, p in ipairs(Players:GetPlayers()) do addSanity(p, C.TASK_REWARD) end
		if not G("TeacherShardGiven") then
			S("TeacherShardGiven", true)
			show(IX.Shard1, true)
			teacherSay("Ngoan lắm. Cô để phần thưởng trên bàn cho các em.", 6)
		else
			teacherSay("Tốt lắm. Ngoan.")
		end
	else
		teacherSay("CÁC EM KHÔNG NGHE LỜI!", 5)
		for _, p in ipairs(Players:GetPlayers()) do
			addSanity(p, -C.TASK_FAIL)
			if alive(p) then moveStalkerNear(hrp(p).Position, 20) end
		end
	end
	setTask(nil)
end

-- ===== DẤU HIỆU / TRUY NGUYÊN / THANH TẨY =====
local roundStart = 0
local hours, pressSeq = {}, {}
local carrier, notebookPickedAt, cleanseProgress, wasInLamp = nil, 0, 0, false
local boardAltered, voiceActive, shadowRevealed = false, false, false
local classStart = nil -- lúc có người bước vào Lớp học lần đầu (tiết học + lịch điểm danh tính từ đây)
local gateOpenAt = nil
local escapePhase = 0
local signNames = {Sign_Board = "Chữ trên bảng tự đổi", Sign_Voice = "Tiếng đọc bài vọng lại", Sign_Shadow = "Học sinh-bóng ở góc lớp"}
local btnLabel = {"Chữ trên bảng", "Tiếng đọc bài", "Học sinh-bóng"}
-- Mỗi Dấu Hiệu mở ra một mảnh ký ức của Người Mơ, gợi dần tới Nguồn Ô Nhiễm (cuốn sổ trên bàn cô)
local SIGN_MEMORY = {
	Sign_Board = "“Hôm ấy cô viết tên một bạn lên bảng… rồi xóa đi. Cô ghi lại điều gì đó vào CUỐN SỔ trên bàn.”",
	Sign_Voice = "“Có ai đó bị phạt đọc bài một mình trong phòng nhạc, đọc mãi… đến khi đồng hồ ngừng chạy.”",
	Sign_Shadow = "“Bạn ấy ngồi ở góc lớp. Không ai còn nhớ tên. Tên bạn ấy nằm trong CUỐN SỔ CỦA CÔ.”",
}

local function startTruyNguyen()
	S("Phase", "TruyNguyen")
	local pool = {1,2,3,4,5,6,7,8,9,10,11,12}
	for i = 1, 3 do hours[i] = table.remove(pool, math.random(#pool)) end
	pressSeq = {}
	show(IX.MemoryBoard, true) for i = 1, 3 do show(IX["MemoryBtn" .. i], true) end
	for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("Role") == "Seer" then Remotes.SeerVision:FireClient(p, hours, btnLabel) end end
	notify("Đủ 3 Dấu Hiệu! TRUY NGUYÊN: xếp 3 dấu hiệu trên Bảng Ghi Nhớ (góc trái bảng đen) theo giờ từ sớm đến muộn. Chỉ Thấu Thị đọc được giờ thật bằng Nhìn Xuyên ở đồng hồ.")
end
local function registerSign(name, p)
	if G(name) then return end
	S(name, true) S("Signs", (G("Signs") or 0) + 1)
	S("SignLive_" .. name:gsub("Sign_", ""), false)
	if name == "Sign_Voice" then pcall(function() IX.Sign_Voice.Ghostly:Stop() end) end
	show(IX[name], false)
	Remotes.Notify:FireAllClients("__MEMORY__|" .. signNames[name] .. "|" .. (SIGN_MEMORY[name] or ""))
	if G("Signs") >= 3 then startTruyNguyen() end
end
local function pressBtn(i, p)
	if G("Phase") ~= "TruyNguyen" then return end
	table.insert(pressSeq, i)
	IX["MemoryBtn" .. i].Color = Color3.fromRGB(200, 180, 90)
	if #pressSeq < 3 then notify(p.Name .. " chọn: " .. btnLabel[i] .. " (" .. #pressSeq .. "/3)") return end
	local ok = hours[pressSeq[1]] < hours[pressSeq[2]] and hours[pressSeq[2]] < hours[pressSeq[3]]
	for k = 1, 3 do IX["MemoryBtn" .. k].Color = Color3.fromRGB(120, 100, 70) end
	if ok then
		show(IX.MemoryBoard, false) for k = 1, 3 do show(IX["MemoryBtn" .. k], false) end
		S("Phase", "ThanhTay") show(IX.Notebook, true)
		notify("Đúng rồi! Nguồn Ô Nhiễm: CUỐN SỔ CHÁY DỞ trên bàn giáo viên. Mang đến đèn bàn và đứng yên " .. C.CLEANSE_TIME .. " giây.")
	else
		pressSeq = {} addSanity(p, -8)
		moveStalkerNear(IX.MemoryBoard.Position, 18)
		notify("Sai thứ tự! " .. p.Name .. " −8 Tỉnh táo. Có thứ gì đó xuất hiện gần bảng...")
	end
end
local function dropNotebook(reason)
	carrier = nil cleanseProgress = 0 wasInLamp = false
	IX.Notebook.Position = NOTEBOOK_HOME show(IX.Notebook, true) S("Cleanse", 0)
	if reason then notify(reason) end
end
local escape -- tạo ở mục CỬA
local function openGate() escape.open() end

-- ===== VẬT PHẨM =====
local ITEMS = {
	BinhHoi = {name = "Bình Hồi", color = Color3.fromRGB(120, 255, 160), desc = "+25 Tỉnh táo"},
	ChuongTinh = {name = "Chuông Tỉnh", color = Color3.fromRGB(255, 220, 90), desc = "Đuổi Kẻ Đứng Sau Cửa ra xa 15 giây (−15)"},
	DenNhu = {name = "Đèn Nhử", color = Color3.fromRGB(255, 170, 80), desc = "Đặt vùng sáng an toàn 20 giây (−15)"},
}
local ITEM_KEYS = {"BinhHoi"}
local function makeItemVisual(key, parent, pos)
	-- đồ vật thật, không phát sáng
	local main = Instance.new("Part") main.Anchored = pos ~= nil main.CanCollide = false main.Massless = true
	local deco = Instance.new("Part") deco.Anchored = false deco.CanCollide = false deco.Massless = true
	if key == "BinhHoi" then
		main.Size = Vector3.new(0.7, 1.1, 0.7) main.Color = Color3.fromRGB(90, 170, 110) main.Material = Enum.Material.Glass main.Transparency = 0.15
		deco.Size = Vector3.new(0.35, 0.35, 0.35) deco.Color = Color3.fromRGB(120, 80, 50) deco.Material = Enum.Material.Wood
	else
		main.Size = Vector3.new(0.9, 1.3, 0.9) main.Color = Color3.fromRGB(70, 60, 45) main.Material = Enum.Material.Metal
		deco.Size = Vector3.new(0.95, 0.7, 0.95) deco.Color = Color3.fromRGB(230, 200, 130) deco.Material = Enum.Material.Glass deco.Transparency = 0.3
	end
	main.CFrame = CFrame.new(pos or Vector3.zero)
	deco.CFrame = main.CFrame * (key == "BinhHoi" and CFrame.new(0, 0.7, 0) or CFrame.new(0, 0, 0))
	main.Parent = parent deco.Parent = parent
	local w = Instance.new("WeldConstraint") w.Part0 = main w.Part1 = deco w.Parent = main
	return main
end
local useItem
local ITEM_STACK = {}
for key, def in pairs(ITEMS) do
	ITEM_STACK[key] = {label = def.name,
		handle = function(t) local h = makeItemVisual(key, t, nil) h.Name = "Handle" return h end,
		init = function(t) t:SetAttribute("ItemKey", key) end,
		tip = function(n) return def.desc .. " — click để dùng (còn " .. n .. ")" end,
		onUse = function(p) useItem(p, key) end}
end
local function spawnItems()
	map.Items:ClearAllChildren()
	for _, spot in ipairs(map.ItemSpawns:GetChildren()) do
		if math.random() < 0.8 then
			local key = ITEM_KEYS[math.random(#ITEM_KEYS)] local def = ITEMS[key]
			local m = Instance.new("Model") m.Name = key m.Parent = map.Items
			local part = makeItemVisual(key, m, spot.Position + Vector3.new(0, 0.1, 0))
			m.PrimaryPart = part
			prompt(part, "Nhặt", def.name, 0.3, function(p)
				m:Destroy()
				Core.setStack(p, key, Core.stackCount(p, key) + 1, ITEM_STACK[key])
				notify("Nhặt " .. def.name .. ": " .. def.desc .. ". Chọn ô trên thanh đồ rồi CLICK để dùng.", p)
			end)
		end
	end
end
useItem = function(p, key)
	if not key or not hrp(p) then return end
	local pos = hrp(p).Position
	if key == "BinhHoi" then
		addSanity(p, 25) notify("Bạn uống Bình Hồi (+25 Tỉnh táo)", p)
	elseif key == "ChuongTinh" then
		addSanity(p, -15)
		if p:GetAttribute("Room") == "West" then violate(p, "Tiếng chuông vang khắp thư viện") end
		moveStalkerNear(pos, 70) stalkerPauseUntil = os.clock() + 15
		notify(p.Name .. " rung Chuông Tỉnh! Kẻ Đứng Sau Cửa bị đẩy lùi 15 giây.")
	elseif key == "DenNhu" then
		addSanity(p, -15)
		local lamp = Instance.new("Part") lamp.Anchored = true lamp.CanCollide = false lamp.Size = Vector3.new(1, 1.5, 1) lamp.Material = Enum.Material.Neon
		lamp.Color = ITEMS.DenNhu.color lamp.Position = pos - Vector3.new(0, 2, 0) lamp.Parent = map.Items
		local l = Instance.new("PointLight", lamp) l.Range = 14 l.Brightness = 2 l.Color = ITEMS.DenNhu.color
		table.insert(tempLights, {pos = pos, t = os.clock() + 20})
		Debris:AddItem(lamp, 20)
		notify(p.Name .. " đặt Đèn Nhử: vùng sáng an toàn 20 giây.")
	end
end

-- ===== KẾT THÚC / RESET =====
local resetRound
local function endRound(win, msg)
	if G("RoundOver") then return end
	S("RoundOver", true) S("RoundTime", math.floor(os.clock() - roundStart)) S("Phase", win and "Win" or "Lose")
	notify(msg)
	task.delay(8, function() Core.finishLevel(1, win) end)
end

-- ===== CỬA (F) =====
local doorCtl = Core.wireDoors(map.Doors, {lockedMsg = "Cửa đã bị khóa chặt...",
	onToggle = function(p, m) if m.Name == "Door_West" then libraryNoise(m.Panel.Position, true, p) end end})
local function closeAllDoors() doorCtl.setAll(false) end
local function openAllDoors() doorCtl.setAll(true) end
local function wireDoors() end -- cửa đã được LevelCore gắn ở trên
escape = Core.newEscape({gate = IX.Gate, S = S, G = G, doors = doorCtl, alive = alive, notify = notify,
	players = function() return Players:GetPlayers() end,
	escapeTime = 10, gateTime = C.GATE_TIME,
	blocked = function() return G("RoundOver") end,
	safe = function(p) return roomOf(hrp(p).Position) == "Hall" end,
	target = function() return map.EscapeRoom:GetPivot() end,
	openMsg = "MỌI QUY LUẬT ĐÃ BIẾN MẤT. 10 giây nữa mọi cánh cửa sẽ đóng — CHẠY VỀ SẢNH!",
	trappedMsg = "Cánh cửa đóng sầm lại sau lưng bạn... Bạn bị nhốt trong giấc mơ.",
	closedMsg = "MỌI CÁNH CỬA ĐÃ ĐÓNG. Ai ở sảnh hãy bước vào Cổng!",
	onOpen = function()
		S("TeacherWatching", false)
		if currentTask then setTask(nil) end
		teacherSay("...Tan học rồi. VỀ ĐI.", 6)
	end})

local function wire()
	wireDoors()
	prompt(IX.Diary, "Đọc nhật ký", "Cuốn sổ cũ trên bàn đọc", 1, function(p)
		p:SetAttribute("HasDiary", true)
		giveTool(p, "Diary")
		Remotes.Notify:FireClient(p, "__DIARY__")
	end)
	prompt(IX.RulesPaper, "Nhặt tờ giấy", "Nội quy tầng", 0.5, function(p)
		if not p:GetAttribute("HasRules") then p:SetAttribute("HasRules", true) end
		giveTool(p, "Rules")
		Remotes.Notify:FireClient(p, "__SHOW_RULES__")
	end)
	prompt(IX.Sign_Board, "Ghi nhận", "Dấu hiệu", 1, function(p) if boardAltered then registerSign("Sign_Board", p) end end)
	prompt(IX.Sign_Voice, "Ghi nhận", "Dấu hiệu", 1, function(p) if voiceActive then registerSign("Sign_Voice", p) end end)
	prompt(IX.Sign_Shadow, "Ghi nhận", "Dấu hiệu", 1, function(p) registerSign("Sign_Shadow", p) end)
	for i = 1, 3 do prompt(IX["MemoryBtn" .. i], btnLabel[i], "Bảng Ghi Nhớ", 0, function(p) pressBtn(i, p) end) end
	prompt(IX.Notebook, "Nhặt sổ", "Nguồn Ô Nhiễm", 0.5, function(p)
		if G("Phase") ~= "ThanhTay" or carrier then return end
		carrier = p notebookPickedAt = os.clock() cleanseProgress = 0 en(IX.Notebook, false)
		notify(p.Name .. " đang cầm sổ. Còn " .. C.NOTEBOOK_TIMEOUT .. " giây trước khi nó tái sinh!")
	end)
	for _, name in ipairs({"Shard1", "Shard2", "Shard3"}) do
		prompt(IX[name], "Nhặt", "Mảnh Neo Thức", 0.5, function(p)
			show(IX[name], false) S("Shards", (G("Shards") or 0) + 1)
			notify(p.Name .. " nhặt Mảnh Neo (" .. G("Shards") .. "/3)")
		end)
	end
	prompt(IX.Pedestal, "Đặt Mảnh Neo", "Bệ Neo", 1, function(p)
		if G("Phase") == "Gate" then return end
		if (G("Shards") or 0) < 3 then notify("Cần đủ 3 Mảnh Neo (đang có " .. (G("Shards") or 0) .. "). Mảnh 1: hoàn thành yêu cầu của cô. Mảnh 2–3: Thư viện, Phòng nhạc.", p) return end
		if not G("Cleansed") then notify("Bệ Neo không phản ứng... Tầng vẫn còn ô nhiễm. Hãy THANH TẨY Nguồn Ô Nhiễm trước.", p) return end
		openGate()
	end)

	prompt(IX.Blackboard, "Lau bảng", "Bảng đen", 3, function() if currentTask and currentTask.id == "Wipe" then finishTask(true) end end)
	prompt(IX.Chalk, "Nhặt hộp phấn", "Việc cô nhờ", 0.5, function(p)
		if currentTask and currentTask.id == "Chalk" and not p:GetAttribute("Carrying") then
			p:SetAttribute("Carrying", "Chalk") giveTool(p, "Chalk")
			IX.Chalk.Transparency = 1 en(IX.Chalk, false)
			notify("Đã nhặt Hộp phấn (có trong túi đồ). Mang về bàn giáo viên!", p)
		end
	end)
	prompt(IX.TaskBook, "Nhặt sổ điểm", "Việc cô nhờ", 0.5, function(p)
		if currentTask and currentTask.id == "Book" and not p:GetAttribute("Carrying") then
			p:SetAttribute("Carrying", "Book") giveTool(p, "Book")
			IX.TaskBook.Transparency = 1 en(IX.TaskBook, false)
			notify("Đã nhặt Sổ điểm (có trong túi đồ). Mang về bàn giáo viên!", p)
		end
	end)
	prompt(IX.TeacherDesk, "Nộp cho cô", "Bàn giáo viên", 0.5, function(p)
		local c = p:GetAttribute("Carrying") if currentTask and c and c == currentTask.id then finishTask(true) end
	end)
end

resetRound = function()
	shadowRevealed = false boardAltered = false voiceActive = false classStart = nil
	for _, k in ipairs({"Board", "Voice", "Shadow"}) do S("SignLive_" .. k, false) end pcall(function() IX.Sign_Voice.Ghostly:Stop() end)
	for _, r in ipairs({"Class", "West", "East"}) do S("Active_" .. r, false) end
	S("TeacherWatching", false) S("ClassStartAt", 0)
	S("Period", 0) S("LieIndex1", math.random(4)) S("RollName", "") S("RollDeadline", 0)
	for _, k in ipairs({"Sign_Board", "Sign_Voice", "Sign_Shadow"}) do S(k, false) end
	S("Signs", 0) S("Shards", 0) S("Cleanse", 0) S("TeacherShardGiven", false) S("Cleansed", false) S("Phase", "TrinhSat") S("StalkerActive", false)
	carrier = nil cleanseProgress = 0 pressSeq = {} tempLights = {}
	show(IX.Sign_Board, true, 1) show(IX.Sign_Voice, false) show(IX.Sign_Shadow, false)
	show(IX.MemoryBoard, false) for i = 1, 3 do show(IX["MemoryBtn" .. i], false) end
	show(IX.Notebook, false) IX.Notebook.Position = NOTEBOOK_HOME
	show(IX.Shard1, false) show(IX.Shard2, true) show(IX.Shard3, true)
	escape.reset()
	IX.Stalker.Position = STALKER_HOME
	IX.Stalker.Transparency = C.STALKER_ENABLED and 0 or 1 IX.Stalker.Decal.Transparency = C.STALKER_ENABLED and 0 or 1
	setTask(nil)
	clearTaskItems() setStep(nil)
	spawnItems()
	roundStart = os.clock()
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("Dreaming", false) p:SetAttribute("Sanity", maxSan(p))
		p:SetAttribute("SkillReadyAt", 0) p:SetAttribute("Carrying", nil) p:SetAttribute("Item", nil)
		p:SetAttribute("HasRules", false) p:SetAttribute("HasDiary", false) p:SetAttribute("CalmUntil", 0) p:SetAttribute("Escaped", false) p:SetAttribute("Dancing", false)
		p:LoadCharacter()
	end
	closeAllDoors() doorCtl.locked = false
	resetEnemies()
	S("RoundOver", false)
	notify("TRINH SÁT: tìm 3 Dấu Hiệu Bất Thường. Nhặt TỜ NỘI QUY trên bàn ở sảnh trước khi vào phòng (M để đọc lại).")
end

-- ===== NGƯỜI CHƠI =====
local view, backTimer, stillTimer, whisperTimer, caughtCd = {}, {}, {}, {}, {}
-- Riêng Tầng 1 khi có người hòa mộng (hiệu ứng chung do LevelCore lo)
local function onDream(p)
	if G("RoundOver") then return end
	local c = p:GetAttribute("Carrying")
	if c then
		p:SetAttribute("Carrying", nil) removeTool(p, c)
		local part = c == "Chalk" and IX.Chalk or IX.TaskBook
		part.Position = c == "Chalk" and CHALK_HOME or BOOK_HOME part.Transparency = 0 en(part, true)
		notify("Đồ cô nhờ rơi về chỗ cũ!")
	end
	if carrier == p then dropNotebook("Người cầm sổ đã hòa mộng — sổ quay về chỗ cũ!") end
end
Players.PlayerAdded:Connect(function(p)
	p:SetAttribute("Role", nil) p:SetAttribute("Ready", false)
	-- vào giữa ván: tự nhận vai còn trống để chơi cùng luôn
	if G("Phase") ~= "Lobby" then
		for _, r in ipairs(ROLE_ORDER) do if ROLES[r].enabled and not roleTaken(r, p) then p:SetAttribute("Role", r) break end end
	end
	p:SetAttribute("Sanity", maxSan(p)) p:SetAttribute("Dreaming", false) p:SetAttribute("SkillReadyAt", 0)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.2)		-- CHẾ ĐỘ TEST TẦNG 2 (chỉ trong Studio): bật thuộc tính TestLevel2 của Workspace
		if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("TestLevel2") then
			local m2 = workspace:FindFirstChild("DreamMap2")
			local sp = m2 and m2.Interactables:FindFirstChild("Spawn2")
			local root = char:FindFirstChild("HumanoidRootPart")
			if sp and root then root.CFrame = sp.CFrame + Vector3.new(0, 4, 0) end
		end
		if p:GetAttribute("HasRules") then giveTool(p, "Rules") end
		if p:GetAttribute("HasDiary") then giveTool(p, "Diary") end
		local hum = char:WaitForChild("Humanoid")
		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Jumping and alive(p) and p:GetAttribute("Room") == "West" then
				violate(p, "Thư viện — bạn đã NHẢY, tiếng động vang khắp phòng")
				if hrp(p) then libraryNoise(hrp(p).Position, true, p) end
			end
		end)
	end)
end)
Players.PlayerRemoving:Connect(function(p)
	if carrier == p then dropNotebook() end
	view[p] = nil p:SetAttribute("Role", nil)
end)
Remotes.ViewReport.OnServerEvent:Connect(function(p, back, sees) view[p] = {back = back == true, sees = sees == true, t = os.clock()} end)

Remotes.UseSkill.OnServerEvent:Connect(function(p, action, extra)
	if action == "DanceResult" then finishDance(p, extra) return end
	if action == "PickRole" then
		if G("Phase") ~= "Lobby" or type(extra) ~= "string" or not ROLES[extra] or not ROLES[extra].enabled then return end
		if roleTaken(extra, p) then notify("Vai này đã có người chọn.", p) return end
		p:SetAttribute("Role", extra) p:SetAttribute("Ready", false)
		p:SetAttribute("Sanity", maxSan(p))
		return
	end
	if action == "Ready" then
		if G("Phase") ~= "Lobby" or not p:GetAttribute("Role") then return end
		p:SetAttribute("Ready", not p:GetAttribute("Ready"))
		return
	end
	if action == "SwapRole" then
		if false then
			p:SetAttribute("Role", p:GetAttribute("Role") == "Seer" and "Healer" or "Seer")
			p:SetAttribute("Sanity", math.min(p:GetAttribute("Sanity"), maxSan(p)))
			if p:GetAttribute("Role") == "Seer" and G("Phase") == "TruyNguyen" then Remotes.SeerVision:FireClient(p, hours, btnLabel) end
		end
		return
	end
end)

Remotes.Ping.OnServerEvent:Connect(function(p, pos, kind)
	if typeof(pos) ~= "Vector3" or not hrp(p) or (pos - hrp(p).Position).Magnitude > 150 then return end
	if alive(p) and p:GetAttribute("Room") == "West" then violate(p, "Thư viện — bạn đã Ping") libraryNoise(hrp(p).Position, true, p) end
	local labels = {"Ở ĐÂY", "NGUY HIỂM", "DẤU HIỆU"}
	local colors = {Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 220, 90)}
	kind = math.clamp(tonumber(kind) or 1, 1, 3)
	local m = Instance.new("Part") m.Anchored = true m.CanCollide = false m.CanQuery = false m.Size = Vector3.new(0.6, 0.6, 0.6)
	m.Shape = Enum.PartType.Ball m.Material = Enum.Material.Neon m.Color = colors[kind] m.Position = pos + Vector3.new(0, 0.5, 0) m.Parent = workspace
	local bb = Instance.new("BillboardGui", m) bb.Size = UDim2.fromOffset(170, 40) bb.AlwaysOnTop = true bb.StudsOffset = Vector3.new(0, 2, 0)
	local t = Instance.new("TextLabel", bb) t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true t.Font = Enum.Font.GothamBold
	t.TextColor3 = colors[kind] t.TextStrokeTransparency = 0 t.Text = labels[kind] .. " (" .. p.Name .. ")"
	Debris:AddItem(m, 5)
end)

-- ===== VÒNG LẶP SỰ KIỆN =====
-- ===== TIẾT HỌC: lớp học tệ dần, mỗi tiết 4 phút =====
local PERIOD_LEN = 240
local PERIOD = {
	{write = {8, 14}, watch = {4, 6}, on = {10, 16}, off = {4, 6}, drain = 1, lib = 1},
	{write = {6, 10}, watch = {5, 7}, on = {8, 12}, off = {3, 5}, drain = 1.25, lib = 1.15},
	{write = {4, 8}, watch = {6, 8}, on = {6, 9}, off = {3, 4}, drain = 1.5, lib = 1.3},
}
local BASE_DRAIN = C.DARK_DRAIN
local function per() return PERIOD[G("Period") or 1] or PERIOD[1] end
local function rnd(r) return math.random(r[1], r[2]) end
local PERIOD_MSG = {
	[2] = "🔔 Chuông reo — TIẾT 2. Lớp học lạnh hơn... cô quay xuống thường xuyên hơn.",
	[3] = "🔔 Chuông reo — TIẾT CUỐI. Những chiếc bàn trống... đã có người ngồi.",
}
local function setPeriod(n)
	S("Period", n) S("PeriodEndsAt", n < 3 and (workspace:GetServerTimeNow() + PERIOD_LEN) or 0)
	C.DARK_DRAIN = BASE_DRAIN * PERIOD[n].drain
	if n > 1 then
		pcall(function() local b = teacher.Head.Bell b.TimePosition = 0 b:Play() task.delay(3, function() b:Stop() end) end)
		notify(PERIOD_MSG[n])
		teacherSay(n == 3 and "Tiết cuối rồi. Cả lớp... NGỒI NGAY NGẮN." or "Vào tiết mới. Trật tự!", 5)
	end
end

-- ===== DẤU HIỆU CÓ NGUYÊN NHÂN =====
-- (1) Chữ trên bảng chỉ đổi SAU LƯNG cô — lúc cô quay xuống nhìn lớp (không ai được di chuyển).
local boardTexts = {"Nội quy: LUÔN NGHE LỜI CÔ", "CÓ AI ĐÓ ĐANG ĐỨNG SAU EM", "Hôm qua ... hôm nay ... hôm qua", "CÁC EM ĐÃ NGOAN CHƯA?", "BẠN ẤY VẪN NGỒI Ở GÓC LỚP"}
local boardMiss = 0
local function boardOn()
	if G("Phase") ~= "TrinhSat" or G("Sign_Board") then return end
	boardMiss += 1
	if math.random() < 0.5 and boardMiss < 3 then return end
	boardMiss = 0
	local l = IX.Blackboard.BoardGui.Text
	boardAltered = true l.Text = boardTexts[math.random(2, #boardTexts)] l.TextColor3 = Color3.fromRGB(255, 70, 70)
	S("SignLive_Board", true) Core.sense(1, "Lớp học")
	pcall(function() IX.Blackboard.BoardScreech:Play() end)
	for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("Room") == "Class" then notify("*Tiếng phấn rít lên* — chữ trên bảng sau lưng cô vừa tự đổi!", p) end end
end
local function boardOff()
	if not boardAltered then return end
	local l = IX.Blackboard.BoardGui.Text
	boardAltered = false l.Text = boardTexts[1] l.TextColor3 = Color3.fromRGB(230, 230, 220)
	S("SignLive_Board", false)
end
-- (2) Tiếng đọc bài vang lên trong KHOẢNG LẶNG khi nhạc tắt, rồi văng vẳng dưới tiếng nhạc thêm ~12 giây.
local voiceMiss = 0
local function stopVoice() voiceActive = false S("SignLive_Voice", false) pcall(function() IX.Sign_Voice.Ghostly:Stop() end) if not G("Sign_Voice") then show(IX.Sign_Voice, false) end end
-- (3) Học sinh-bóng: cô điểm danh một cái tên KHÔNG AI trong nhóm — nếu cả lớp im lặng, bạn ấy hiện ra ở góc lớp.

local nextTask, nextRollTarget, nextOff = nil, nil, nil -- Bói Toán nhìn thấy trước những lựa chọn này
-- ===== ĐIỂM DANH =====
local ROLL_TIME = 8
local GHOST_TIMES = {90, 200, 270, 510, 750} -- giây kể từ đầu ván: 2 lần trong tiết 1, dự phòng 30s sau đầu tiết 2 và 3
local ghostTried = {}
local function ghostDueAt()
	if not classStart or G("Phase") ~= "TrinhSat" or G("Sign_Shadow") or shadowRevealed then return nil end
	for i, t in ipairs(GHOST_TIMES) do if not ghostTried[i] then return t, i end end
end
local GHOST_NAMES = {"Vũ Thị Hạnh", "Trần Minh Khôi", "Lê Ngọc Ánh", "Phạm Gia Bảo", "Đỗ Thu Trang"}
local roll = nil
local rollCount, lastRollAt, rollRound = 0, os.clock(), -1
local deskPrompts = {}
local function setDeskPrompts(on, label) for _, pp in ipairs(deskPrompts) do pp.Enabled = on if label then pp.ObjectText = label end end end
local function endRoll()
	if roll and roll.target then roll.target:SetAttribute("RollGrace", nil) end
	roll = nil S("RollName", "") S("RollDeadline", 0) S("RollGhost", false) setDeskPrompts(false)
end
local function revealShadow()
	shadowRevealed = true
	show(IX.Sign_Shadow, true, 0.15) S("SignLive_Shadow", true) Core.sense(1, "Lớp học")
	pcall(function() local b = IX.Sign_Shadow.Breath b.TimePosition = 0 b:Play() task.delay(4, function() b:Stop() end) end)
	teacherSay("...Không ai nhớ bạn ấy à?", 4)
	for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("Room") == "Class" then notify("Không ai trả lời... Ở BÀN CUỐI GÓC LỚP, có ai đó vừa ngồi xuống.", p) end end
end
local function answerRoll(p)
	if not roll or p:GetAttribute("Room") ~= "Class" then return end
	local r = roll
	endRoll()
	if r.ghost then
		violate(p, "Điểm danh — bạn trả lời cho một người KHÔNG có trong lớp", 10)
		teacherSay("Em nói dối. Bạn ấy... không còn ở đây nữa.", 4)
	elseif p == r.target then
		teacherSay("Được. Ngồi yên đấy.", 3)
	elseif math.random() < 0.3 then
		violate(p, "Điểm danh — cô nhận ra bạn trả lời thay cho " .. r.name, 15)
		teacherSay("Đó không phải giọng của " .. r.name .. "!", 4)
	else
		teacherSay("Được.", 2)
		notify("Bạn trả lời thay cho " .. r.name .. "... cô không nhận ra.", p)
	end
end
for _, d in ipairs(map.Props:GetChildren()) do
	if d.Name == "Desk" and d:FindFirstChild("Top") then
		local pp = prompt(d.Top, "Có ạ!", "Điểm danh", 0, function(p) answerRoll(p) end)
		pp.Enabled = false table.insert(deskPrompts, pp)
	end
end
local function startRoll(force)
	local alivePs = {} for _, o in ipairs(Players:GetPlayers()) do if alive(o) then table.insert(alivePs, o) end end
	if #alivePs == 0 then return false end
	rollCount += 1 lastRollAt = os.clock()
	local ghost = force == true -- tên bí ẩn chỉ gọi theo lịch cố định (GHOST_TIMES)
	local target, name = nil, nil
	if ghost then name = GHOST_NAMES[math.random(#GHOST_NAMES)]
	else target = (nextRollTarget and table.find(alivePs, nextRollTarget)) and nextRollTarget or alivePs[math.random(#alivePs)] nextRollTarget = nil name = target.DisplayName target:SetAttribute("RollGrace", true) end
	roll = {name = name, target = target, ghost = ghost, deadline = os.clock() + ROLL_TIME, round = roundStart}
	S("RollName", name) S("RollDeadline", workspace:GetServerTimeNow() + ROLL_TIME) S("RollGhost", ghost)
	setDeskPrompts(true, "Điểm danh: " .. name)
	teacherSay("Điểm danh... " .. name .. "!", ROLL_TIME)
	notify("📋 Cô điểm danh: " .. string.upper(name) .. " — về một chiếc BÀN trong lớp và trả lời “Có ạ” (E) trong " .. ROLL_TIME .. " giây.")
	return true
end
local function tickRoll()
	if not roll then return end
	if roll.round ~= roundStart or G("Phase") == "Gate" or G("RoundOver") then endRoll() return end
	if os.clock() < roll.deadline then return end
	local r = roll endRoll()
	if r.ghost then revealShadow()
	elseif r.target then violate(r.target, "Điểm danh — cô gọi tên mà bạn không trả lời", 12) teacherSay(r.name .. " VẮNG MẶT.", 3) end
end

-- Giáo viên: viết bảng <-> quay xuống nhìn lớp (điểm danh / nhờ việc)
local lastTaskAt = os.clock()
task.spawn(function()
	while true do
		-- Lớp học chưa có ai bước vào: cô chỉ viết bảng, chưa có luật nào
		local ph1 = G("Phase")
		local l1On = (ph1 == "TrinhSat" or ph1 == "TruyNguyen" or ph1 == "ThanhTay" or ph1 == "Neo") and not G("RoundOver")
		if roll and not l1On then endRoll() end
		if not G("Active_Class") or not l1On then S("TeacherWatching", false) teacher:PivotTo(teacherBase) boardOff() task.wait(1) continue end
		S("TeacherWatching", false) teacher:PivotTo(teacherBase) boardOff()
		pcall(function() teacher.Body.Chalk:Play() end)
		local iterRound = roundStart
		if rollRound ~= roundStart then rollRound = roundStart rollCount = 0 lastRollAt = os.clock() - 20 ghostTried = {} end
		local w = rnd(per().write)
		-- đến giờ gọi tên bí ẩn: rút ngắn lúc viết bảng để cô quay xuống đúng giờ
		local ghostIdx = nil
		do
			local gAt, gi = ghostDueAt()
			local el = os.clock() - (classStart or os.clock())
			if gAt and gAt - el < w + 1.5 then w = math.max(0.5, gAt - el - 1.5) ghostIdx = gi end
		end
		S("TeacherTurnAt", workspace:GetServerTimeNow() + w + 1.5)
		Core.waitUnfrozen(S, G, "Class", w, {"TeacherTurnAt"})
		while Core.isLulled(G, "Class") do task.wait(0.2) end -- đang bị ru: cô chưa quay xuống
		-- ván mới đã bắt đầu trong lúc cô viết bảng -> bỏ lượt cũ, chờ lớp được "đánh thức" lại
		if iterRound ~= roundStart or not G("Active_Class") then continue end
		if not G("RoundOver") then
			if G("Phase") == "Gate" then task.wait(1) continue end
			teacherSay("E hèm...") task.wait(1.5)
			pcall(function() teacher.Body.Chalk:Stop() end)
			teacher:PivotTo(teacherBase * CFrame.Angles(0, math.pi, 0)) S("TeacherWatching", true)
			boardOn()
			local w2 = rnd(per().watch)
			local sinceRoll = os.clock() - lastRollAt
			if ghostIdx and not roll and ghostDueAt() then
				ghostTried[ghostIdx] = true
				if startRoll(true) then w2 = ROLL_TIME + 1 end
			elseif not currentTask and not roll and sinceRoll > 45 and (math.random() < 0.5 or sinceRoll > 80) and not (function() local gAt = ghostDueAt() return gAt and classStart and gAt - (os.clock() - classStart) < 20 end)() then
				if startRoll() then w2 = ROLL_TIME + 1 end
			elseif not currentTask and not roll and os.clock() - lastTaskAt > 35 and G("Phase") ~= "Gate" then
				lastTaskAt = os.clock()
				local list = nextTask or TASKS[math.random(#TASKS)] nextTask = nil setTask(list)
				pcall(function() local b = teacher.Head.Bell b.TimePosition = 0 b:Play() task.delay(2.5, function() b:Stop() end) end) teacherSay(STEPS[list[1]].say, 8)
			end
			S("TeacherTurnBackAt", workspace:GetServerTimeNow() + w2)
			Core.waitUnfrozen(S, G, "Class", w2, {"TeacherTurnBackAt"})
		end
	end
end)
-- Phòng nhạc: nhạc vang <-> tắt
local musicChangedAt = 0
task.spawn(function()
	while true do
		-- Phòng nhạc chưa có ai vào: nhạc cứ vang, chưa tắt/bật
		if not G("Active_East") then
			if not G("MusicOn") then S("MusicOn", true) IX.Piano.Color = Color3.fromRGB(15, 15, 18) pcall(function() IX.Piano.MusicBox:Resume() end) end
			S("MusicChangeAt", 0) task.wait(1) continue
		end
		S("MusicOn", true) musicChangedAt = os.clock() IX.Piano.Color = Color3.fromRGB(15, 15, 18)
		pcall(function() IX.Piano.MusicBox:Resume() if not IX.Piano.MusicBox.IsPlaying then IX.Piano.MusicBox:Play() end end)
		local d1 = rnd(per().on) S("MusicChangeAt", workspace:GetServerTimeNow() + d1)
		Core.waitUnfrozen(S, G, "East", d1, {"MusicChangeAt"})
		S("MusicOn", false) musicChangedAt = os.clock() IX.Piano.Color = Color3.fromRGB(90, 0, 0)
		pcall(function() IX.Piano.MusicBox:Pause() end)
		local d2 = nextOff or rnd(per().off) nextOff = nil S("MusicChangeAt", workspace:GetServerTimeNow() + d2)
		if G("Phase") == "TrinhSat" and not G("Sign_Voice") and not voiceActive and not G("RoundOver") then
			voiceMiss += 1
			if math.random() < 0.5 or voiceMiss >= 3 then
				voiceMiss = 0 voiceActive = true show(IX.Sign_Voice, true, 0.4) S("SignLive_Voice", true) Core.sense(1, "Phòng nhạc") pcall(function() IX.Sign_Voice.Ghostly:Play() end)
				for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("Room") == "East" then notify("Nhạc vừa tắt... có tiếng ai đó ĐỌC BÀI ở góc phòng nhạc!", p) end end
				task.delay(d2 + 12, stopVoice)
			end
		end
		Core.waitUnfrozen(S, G, "East", d2, {"MusicChangeAt"})
	end
end)
IX.Piano.Touched:Connect(function(hit)
	local p = Players:GetPlayerFromCharacter(hit.Parent)
	if p and alive(p) then violate(p, "Phòng nhạc — bạn đã CHẠM VÀO ĐÀN") end
end)

-- ===== KẺ ĐỊCH =====
C.ENEMIES_ENABLED = true
local function enemySay(model, txt, dur)
	local gui = model.Root:FindFirstChild("Speech") if not gui then return end
	gui.Bubble.Text.Text = txt gui.Enabled = true
	task.delay(dur or 2.5, function() if gui.Bubble.Text.Text == txt then gui.Enabled = false end end)
end
local function faceMove(model, from, to, step)
	local dir = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if dir.Magnitude < 0.05 then return from end
	local nxt = from + dir.Unit * math.min(step, dir.Magnitude)
	model:PivotTo(CFrame.lookAt(nxt, nxt + dir.Unit))
	return nxt
end

-- (1) THỦ THƯ MÙ — Thư viện. Không nhìn thấy, chỉ SĂN THEO TIẾNG ĐỘNG.
--   • Người đi lại trong vòng 12 bước quanh bà bị "nghe thấy" (đứng yên thì an toàn).
--   • Nhảy, Ping, mở cửa thư viện = tiếng động lớn: bà lao tới chỗ phát ra tiếng.
--   • Bị chạm: −20 Tỉnh táo.
local LIB = IX.Librarian
local LIB_HOME = Vector3.new(-80, 0, 0) * K
local LIB_Y = 4.25 * K
local libNodes = {}
for _, x in ipairs({-104, -80, -58}) do for _, z in ipairs({-24, -12, 0, 12, 24}) do table.insert(libNodes, Vector3.new(x * K, 0, z * K)) end end
local function libNeighbors(n)
	local out = {}
	local nx, nz = math.floor(n.X / K + 0.5), math.floor(n.Z / K + 0.5)
	for _, m in ipairs(libNodes) do
		local mx, mz = math.floor(m.X / K + 0.5), math.floor(m.Z / K + 0.5)
		local dx, dz = math.abs(mx - nx), math.abs(mz - nz)
		if (dz == 0 and (dx == 24 or dx == 22)) or (dx == 0 and dz == 12 and nx == -80) then table.insert(out, m) end
	end
	return out
end
local function nearestNode(pos) local b, bd for _, n in ipairs(libNodes) do local d = (Vector3.new(pos.X, 0, pos.Z) - n).Magnitude if not bd or d < bd then b, bd = n, d end end return b end
local function libPath(from, to) -- BFS trên lưới lối đi giữa các kệ sách
	local start, goal = nearestNode(from), nearestNode(to)
	local key = function(v) return v.X .. "," .. v.Z end
	local prev, q, seen = {}, {start}, {[key(start)] = true}
	while #q > 0 do
		local cur = table.remove(q, 1)
		if key(cur) == key(goal) then break end
		for _, nb in ipairs(libNeighbors(cur)) do if not seen[key(nb)] then seen[key(nb)] = true prev[key(nb)] = cur table.insert(q, nb) end end
	end
	local path, c = {}, goal
	while c and key(c) ~= key(start) do table.insert(path, 1, c) c = prev[key(c)] end
	return path
end
local lib = {pos = LIB_HOME, path = {}, mode = "Patrol", cd = 0, huntUntil = 0}
libraryNoise = function(pos, loud, who)
	if who then lastNoise[who] = os.clock() end
	if not C.ENEMIES_ENABLED or G("Phase") == "Gate" then return end
	lib.path = libPath(lib.pos, pos) table.insert(lib.path, Vector3.new(pos.X, 0, pos.Z))
	lib.mode = "Hunt" lib.huntUntil = os.clock() + 8
	if loud then enemySay(LIB, "Ai... đó...?", 2) end
end

-- (2) CON RỐI NHẢY MÚA — Phòng nhạc. Chỉ nhảy múa (di chuyển) KHI NHẠC VANG.
--   • Nhạc vang: lướt về phía người gần nhất trong phòng. Bạn buộc phải di chuyển (luật phòng) và né nó.
--   • Nhạc tắt: con rối đứng im — đừng đứng gần nó khi nhạc sắp vang lại!
--   • Bị chạm: −15 Tỉnh táo, con rối quay về sân khấu.
local PUP = IX.Puppet
local PUP_HOME = Vector3.new(80, 1.5, -14) * K
-- Minigame điệu nhảy: con rối chộp được → người chơi bấm đúng Q/E theo nhịp.
-- Đúng ít nhất 4/5 nhịp: không mất gì. Sai: −15 Tỉnh táo.
local dancePending = {}
function startDance(p)
	if p:GetAttribute("Role") == "Anchor" then notify("⚓ Con Rối giật dây nhưng bạn đứng vững như neo.", p) return end
	local seq = {} for i = 1, 5 do seq[i] = math.random() < 0.5 and "Q" or "E" end
	local seqStr = table.concat(seq)
	dancePending[p] = seqStr
	p:SetAttribute("Dancing", true)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 0 hum.JumpPower = 0 end
	Remotes.Notify:FireClient(p, "__DANCE__|" .. seqStr)
	task.delay(9, function() if dancePending[p] == seqStr then finishDance(p, 0) end end)
end
function finishDance(p, hits)
	if not dancePending[p] then return end
	dancePending[p] = nil
	p:SetAttribute("Dancing", false)
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = p:GetAttribute("Dreaming") and 22 or 16 hum.JumpPower = 50 end
	if (tonumber(hits) or 0) >= 4 then
		notify("Bạn theo kịp điệu nhảy! Con rối buông bạn ra.", p)
	else
		addSanity(p, -15)
		notify("Lạc nhịp! Con rối giật dây bạn (−15 Tỉnh táo).", p)
	end
end
local pup = {pos = PUP_HOME, cd = 0, t = 0}

resetEnemies = function()
	lib.pos = LIB_HOME lib.path = {} lib.mode = "Patrol" lib.cd = 0
	LIB:PivotTo(CFrame.new(LIB_HOME) * CFrame.new(0, LIB_Y, 0))
	pup.pos = PUP_HOME pup.cd = 0
	PUP:PivotTo(CFrame.new(PUP_HOME) * CFrame.new(0, 3 * K, 0))
end
resetEnemies()

task.spawn(function()
	local DT = 0.1
	while true do
		task.wait(DT)
		if not C.ENEMIES_ENABLED or G("RoundOver") or G("Phase") == "Gate" then continue end
		local plist = Players:GetPlayers()
		-- ===== Thủ Thư ===== (Neo: đứng im · Ru: không nghe thấy bước chân)
		local libLull = Core.isLulled(G, "West")
		if not Core.isFrozen(G, "West") then
			-- nghe tiếng bước chân
			local heard, hd
			for _, p in ipairs(plist) do
				if alive(p) and p:GetAttribute("Room") == "West" then
					local pos = hrp(p).Position
					local d = (Vector3.new(pos.X, 0, pos.Z) - lib.pos).Magnitude
					if not libLull and d < 12 * per().lib and speed(p) > 2 and (not hd or d < hd) then heard, hd = p, d end
				end
			end
			if heard then
				local pos = hrp(heard).Position
				lib.mode = "Hunt" lib.huntUntil = os.clock() + 4
				lib.path = {Vector3.new(pos.X, 0, pos.Z)} -- trong tầm nghe: lao thẳng tới
			end
			if lib.mode == "Hunt" and os.clock() > lib.huntUntil and #lib.path == 0 then lib.mode = "Patrol" end
			if #lib.path == 0 then
				local nbs = libNeighbors(nearestNode(lib.pos))
				lib.path = {nbs[math.random(#nbs)]}
			end
			local target = lib.path[1]
			local spd = (lib.mode == "Hunt" and 11 or 5) * per().lib
			lib.pos = faceMove(LIB, lib.pos, target, spd * DT)
			LIB:PivotTo(LIB:GetPivot() + Vector3.new(0, LIB_Y - LIB:GetPivot().Y, 0))
			if (lib.pos - target).Magnitude < 0.3 then table.remove(lib.path, 1) end
			if os.clock() > lib.cd then
				for _, p in ipairs(plist) do
					if alive(p) and p:GetAttribute("Room") == "West" then
						local pos = hrp(p).Position
						local near = (Vector3.new(pos.X, 0, pos.Z) - lib.pos).Magnitude < 7
						local noisy = speed(p) > 2 or os.clock() - (lastNoise[p] or 0) < 1
						if near and noisy and not libLull then
							lib.cd = os.clock() + 4
							addSanity(p, -20)
							enemySay(LIB, "SUỴT!!!", 2)
							notify("Thủ Thư Mù nghe thấy bạn ngay bên cạnh! (−20 Tỉnh táo)", p)
							lib.mode = "Patrol" lib.path = {}
						end
					end
				end
			end
		end
		-- ===== Con Rối ===== (Neo: đứng im · Ru: ngồi xuống)
		do
			if G("MusicOn") and not Core.isFrozen(G, "East") and not Core.isLulled(G, "East") then
				local target, td
				for _, p in ipairs(plist) do
					if alive(p) and p:GetAttribute("Room") == "East" then
						local pos = hrp(p).Position
						local d = (Vector3.new(pos.X, pup.pos.Y, pos.Z) - pup.pos).Magnitude
						if not td or d < td then target, td = p, d end
					end
				end
				local goal = target and Vector3.new(hrp(target).Position.X, PUP_HOME.Y, hrp(target).Position.Z) or PUP_HOME
				pup.t += DT
				local spd = target and 7.5 or 4
				local dir = Vector3.new(goal.X - pup.pos.X, 0, goal.Z - pup.pos.Z)
				if dir.Magnitude > 0.05 then
					pup.look = dir.Unit
					pup.pos = pup.pos + dir.Unit * math.min(spd * DT, dir.Magnitude)
				end
				local look = pup.look or Vector3.new(0, 0, 1)
				-- lắc lư như đang nhảy
				local p0 = pup.pos + Vector3.new(0, 3 * K + math.abs(math.sin(pup.t * 6)) * 0.6, 0)
				PUP:PivotTo(CFrame.lookAt(p0, p0 + look) * CFrame.Angles(0, 0, math.sin(pup.t * 6) * 0.15))
				if target and td < 4 and os.clock() > pup.cd and not target:GetAttribute("Dancing") then
					pup.cd = os.clock() + 12
					startDance(target)
					pup.pos = PUP_HOME
				end
			end
		end
	end
end)

-- ===== PROMPT KHÔNG BẮT CHUỘT =====
-- Ở góc nhìn thứ nhất, prompt "E" dạng nút bấm được sẽ chiếm chuột và làm camera không xoay được.
local function unclick(pp) if pp:IsA("ProximityPrompt") then pp.ClickablePrompt = false end end
for _, d in ipairs(workspace:GetDescendants()) do unclick(d) end
workspace.DescendantAdded:Connect(unclick)

-- ===== DEBUG (dùng để test tự động trong Studio) =====
if game:GetService("RunService"):IsStudio() then
	local api = {
		sign = function(name, p) registerSign(name, p) end,
		hours = function() return hours end,
		press = function(i, p) pressBtn(i, p) end,
		pickNotebook = function(p) carrier = p notebookPickedAt = os.clock() cleanseProgress = 0 end,
		task = function(list) setTask(list) end,
		step = function() return currentTask and currentTask.id end,
		finishStep = function() finishTask(true) end,
	}
	local bf = Instance.new("BindableFunction") bf.Name = "DreamDebug" bf.Parent = game:GetService("ServerStorage")
	bf.OnInvoke = function(cmd, ...) return api[cmd](...) end
end

-- ===== TICK CHÍNH =====
-- ===== SẢNH CHỜ: chọn vai → sẵn sàng → bắt đầu =====
function enterLobby()
	S("RoundOver", true) S("Phase", "Lobby") S("LobbyStartAt", 0)
	setTask(nil) clearTaskItems() closeAllDoors() doorCtl.locked = false resetEnemies() escape.reset()
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("Ready", false) p:SetAttribute("Dreaming", false) p:SetAttribute("Escaped", false) p:SetAttribute("Dancing", false)
		p:SetAttribute("Sanity", maxSan(p))
		p:LoadCharacter()
	end
end
task.spawn(function()
	while true do
		task.wait(0.5)
		if G("Phase") == "Lobby" then
			local plist = Players:GetPlayers()
			local allReady = #plist > 0
			for _, p in ipairs(plist) do if not (p:GetAttribute("Role") and p:GetAttribute("Ready")) then allReady = false end end
			if allReady then
				if (G("LobbyStartAt") or 0) == 0 then S("LobbyStartAt", workspace:GetServerTimeNow() + 4) end
				if workspace:GetServerTimeNow() >= G("LobbyStartAt") then S("LobbyStartAt", 0) Core.startLevel(1) end
			elseif (G("LobbyStartAt") or 0) ~= 0 then S("LobbyStartAt", 0) end
		end
	end
end)

local TICK = 0.25
-- ===== KỸ NĂNG THEO PHÒNG (Tầng 1) =====
local ROOM_NAME1 = {Class = "Lớp học", West = "Thư viện", East = "Phòng nhạc", Hall = "Hành lang"}
-- Bói Toán: quẻ báo sự kiện KẾ TIẾP của phòng đang đứng
local function divineL1(p, room)
	if room == "Class" then
		local lines = {}
		local gAt = ghostDueAt()
		local el = classStart and (os.clock() - classStart) or 0
		if gAt and gAt - el < 75 then
			table.insert(lines, string.format("Lần điểm danh tới (khoảng %d giây nữa): cô sẽ gọi một cái tên KHÔNG CÓ trong lớp. Cả nhóm hãy IM LẶNG.", math.max(0, math.floor(gAt - el))))
		else
			local alivePs = {} for _, o in ipairs(Players:GetPlayers()) do if alive(o) then table.insert(alivePs, o) end end
			if (not nextRollTarget or not nextRollTarget.Parent) and #alivePs > 0 then nextRollTarget = alivePs[math.random(#alivePs)] end
			if nextRollTarget then table.insert(lines, "Lần điểm danh tới cô sẽ gọi: " .. string.upper(nextRollTarget.DisplayName) .. ". Người đó nên đứng sẵn gần một chiếc bàn.") end
		end
		nextTask = nextTask or TASKS[math.random(#TASKS)]
		table.insert(lines, "Việc tiếp theo cô sẽ nhờ: " .. STEPS[nextTask[1]].hint .. ".")
		return table.concat(lines, "\n")
	elseif room == "West" then
		while #lib.path < 3 do
			local last = lib.path[#lib.path] or lib.pos
			local nbs = libNeighbors(nearestNode(last))
			table.insert(lib.path, nbs[math.random(#nbs)])
		end
		local pts = {} for i = 1, 3 do local v = lib.path[i] table.insert(pts, string.format("%.1f,%.1f", v.X, v.Z)) end
		Remotes.Notify:FireClient(p, "__STEPS__|" .. table.concat(pts, ";"))
		return "Những dấu chân phát sáng trên sàn là đường Thủ Thư sắp đi. Tránh xa chúng."
	elseif room == "East" then
		local best, bd
		for _, o in ipairs(Players:GetPlayers()) do
			if alive(o) and o:GetAttribute("Room") == "East" then local d = (hrp(o).Position - pup.pos).Magnitude if not bd or d < bd then best, bd = o, d end end
		end
		nextOff = nextOff or rnd(per().off)
		return (best and ("Khi nhạc vang, Con Rối sẽ đuổi theo " .. string.upper(best.DisplayName) .. " (người đứng gần nó nhất).") or "Con Rối chưa nhắm ai.") .. "\nLần nhạc tắt tới sẽ kéo dài " .. nextOff .. " giây — chuẩn bị đứng yên."
	elseif room == "Hall" then
		local lines = {"Mảnh Neo đã có: " .. (G("Shards") or 0) .. "/3."}
		if not G("TeacherShardGiven") then table.insert(lines, "• Một mảnh là phần thưởng khi làm xong việc cô nhờ.")
		elseif IX.Shard1.Transparency < 1 then table.insert(lines, "• Một mảnh đang nằm trên bàn giáo viên.") end
		for _, n in ipairs({"Shard2", "Shard3"}) do if IX[n].Transparency < 1 then table.insert(lines, "• Một mảnh đang nằm ở " .. (ROOM_NAME1[roomOf(IX[n].Position)] or "đâu đó")) end end
		return table.concat(lines, "\n")
	end
end
-- Chữa Lành: tác dụng tức thì khi ru (ngoài trạng thái Lull_<phòng>)
local function lullL1(p, room)
	if room == "East" then
		for _, o in ipairs(Players:GetPlayers()) do if o:GetAttribute("Dancing") and o:GetAttribute("Room") == "East" then finishDance(o, 5) notify("♪ Bài Ru thay tiếng nhạc — Con Rối buông bạn ra.", o) end end
	end
end
-- ===== ĐĂNG KÝ TẦNG 1 VỚI LEVELCORE =====
Core.register(1, {
	S = S, G = G, state = State, escape = escape,
	name = "Lớp Học Vỡ", start = resetRound, loseRestart = false,
	tools = {"ToNoiQuy", "HopPhan", "SoDiem", "NhatKy"},
	active = function() return not G("RoundOver") end,
	sleep = function() S("RoundOver", true) S("Phase", "Away") setTask(nil) clearTaskItems() end,
	onDream = onDream,
	debug = { -- chỉ dùng khi test trong Studio
		roll = function(ghost) return startRoll(ghost == true) end,
		period = function(n) classStart = os.clock() - PERIOD_LEN * (n - 1) - 1 end,
		board = function() boardMiss = 5 boardOn() return boardAltered end,
		state = function() return {shadow = shadowRevealed, voice = voiceActive, board = boardAltered, roll = roll and roll.name, desks = #deskPrompts} end,
	},
	skill = {roomAttr = "Room", safeRooms = {Hall = true}, roomName = ROOM_NAME1, divine = divineL1, onLull = lullL1,
		-- dùng ở phòng nào cũng được; hiệu ứng chỉ tác động lên phòng đang đứng lúc dùng
		allowed = function(p) if (p:GetAttribute("Room") or "None") == "None" then return "" end end,
		onSeer = function(p)
			local room = p:GetAttribute("Room")
			p:SetAttribute("SightRoom", room)
			if room == "Class" and G("Phase") == "TruyNguyen" then Remotes.SeerVision:FireClient(p, hours, btnLabel) end
		end},
})
Core.lobbyFn = enterLobby
wire()
enterLobby()
do
	local SSv = game:GetService("ServerStorage")
	local back = SSv:FindFirstChild("BackToLobby") or Instance.new("BindableEvent", SSv) back.Name = "BackToLobby"
	back.Event:Connect(function() Core.toLobby() end)
	local tl = Core.testLevel()
	if tl and tl ~= 1 then S("RoundOver", true) S("Phase", "Away") task.delay(3, function() Core.startLevel(tl) end) end
end
while true do
	task.wait(TICK)
	if G("RoundOver") then continue end
	local plist = Players:GetPlayers()
	local sum, n, ghosts = 0, 0, 0
	for _, p in ipairs(plist) do
		if p:GetAttribute("Dreaming") then ghosts += 1 elseif p:GetAttribute("Sanity") then sum += p:GetAttribute("Sanity") n += 1 end
	end
	local threshold = n > 0 and (sum / n - 5 * ghosts) or 0
	S("Threshold", math.floor(threshold))
	local musicGrace = os.clock() - musicChangedAt < 0.8
	local escaping = G("Phase") == "Gate"
	if escaping then
		local r = escape.tick()
		if r == true then endRound(true, "QUA TẦNG! Cổng dịch chuyển đưa cả nhóm tới tầng mộng tiếp theo...") continue
		elseif r == false then endRound(false, "Cổng đã đóng. Cả nhóm bị nuốt vào mộng...") continue end
	end

	for _, p in ipairs(plist) do
		if alive(p) and not escaping then
			local pos = hrp(p).Position
			local room = roomOf(pos)
			p:SetAttribute("Room", room)
			-- phòng "thức dậy" khi có người bước vào lần đầu
			if os.clock() - roundStart > 3 and (room == "Class" or room == "West" or room == "East") and not G("Active_" .. room) then
				S("Active_" .. room, true)
				if room == "Class" then
					classStart = os.clock() lastTaskAt = os.clock() lastRollAt = os.clock() - 20 S("ClassStartAt", workspace:GetServerTimeNow())
					teacherSay("...Vào lớp rồi thì NGỒI NGAY NGẮN.", 4)
				elseif room == "East" then musicChangedAt = os.clock()
				elseif room == "West" then notify("Thư viện tối om... chỉ có một ngọn NẾN đang cháy trên bàn đọc, cạnh một cuốn nhật ký đang mở.", p) end
			end
			local whisperMate = false
			for _, o in ipairs(plist) do
				if o ~= p and alive(o) and (hrp(o).Position - pos).Magnitude <= C.WHISPER_RANGE then whisperMate = true end
			end
			Core.tickSanity(p, plist, inLight(pos), C, TICK)
			local spd = speed(p)

			-- PHÒNG 1: LỚP HỌC
			local v = view[p]
			if room == "Class" then
				-- Luật 1: cô quay xuống nhìn -> cấm di chuyển
				if G("TeacherWatching") and spd > 2 and not p:GetAttribute("RollGrace") and os.clock() > (caughtCd[p] or 0) then
					caughtCd[p] = os.clock() + 2
					teacherSay("EM KIA! AI CHO EM ĐI LẠI?")
					violate(p, "Lớp học — cô đang nhìn mà bạn DI CHUYỂN", C.TEACHER_PENALTY)
				end
			end

			-- PHÒNG 2: THƯ VIỆN — không đứng sát nhau thì thầm
			if room == "West" and whisperMate and not Core.isLulled(G, "West") then
				whisperTimer[p] = (whisperTimer[p] or 0) + TICK
				if whisperTimer[p] >= C.WHISPER_LIMIT then whisperTimer[p] = 0 violate(p, "Thư viện — đứng sát nhau THÌ THẦM quá lâu") end
			else whisperTimer[p] = 0 end

			-- PHÒNG 3: PHÒNG NHẠC
			if room == "East" and not musicGrace and not p:GetAttribute("Dancing") and not Core.isLulled(G, "East") then
				if G("MusicOn") then
					if spd < 1 then stillTimer[p] = (stillTimer[p] or 0) + TICK else stillTimer[p] = 0 end
					if stillTimer[p] >= C.STILL_LIMIT then stillTimer[p] = 0 violate(p, "Phòng nhạc — nhạc đang vang mà bạn ĐỨNG YÊN") end
				else
					stillTimer[p] = 0
					if spd > 2 then violate(p, "Phòng nhạc — nhạc tắt mà bạn còn DI CHUYỂN") end
				end
			else stillTimer[p] = 0 end
		end
	end


	-- Chỉ khi CẢ NHÓM cùng gục mới thua và reset toàn bộ
	local anyAlive = false
	for _, p in ipairs(plist) do if alive(p) and not p:GetAttribute("Dreaming") then anyAlive = true end end
	if #plist > 0 and not anyAlive then endRound(false, "CẢ NHÓM ĐÃ HÒA MỘNG. Giấc mơ nuốt chửng tất cả... Reset sau 8 giây.") continue end

	-- Học sinh-bóng: chỉ hiện sau lần cô điểm danh một cái tên không ai nhận (xem ĐIỂM DANH)
	if G("Phase") == "TrinhSat" and not G("Sign_Shadow") then show(IX.Sign_Shadow, shadowRevealed, 0.15) end
	-- Bài Ru ở Lớp học: cô ngáp, quay ngay lên bảng
	if Core.isLulled(G, "Class") and G("TeacherWatching") then teacher:PivotTo(teacherBase) S("TeacherWatching", false) end
	-- Neo ở Lớp học: điểm danh cũng ngừng đếm giờ
	if roll and Core.isFrozen(G, "Class") then roll.deadline += TICK S("RollDeadline", (G("RollDeadline") or 0) + TICK) end
	tickRoll()
	-- Tiết học
	if not escaping then
		local want = classStart and math.min(3, 1 + math.floor((os.clock() - classStart) / PERIOD_LEN)) or 0
		if want > 0 and want ~= (G("Period") or 0) then setPeriod(want) end
		if want == 0 and C.DARK_DRAIN ~= BASE_DRAIN then C.DARK_DRAIN = BASE_DRAIN end
	end

	-- Nhiệm vụ cô giáo
	if currentTask then
		if currentTask.id == "Sit" then
			local allOk = true
			for _, p in ipairs(plist) do
				if alive(p) then
					local pos = hrp(p).Position local near = false
					for _, d in ipairs(map.Props:GetChildren()) do
						if d.Name == "Desk" and (d.Top.Position - pos).Magnitude < 6 then near = true end
					end
					if not near or speed(p) > 1 then allOk = false end
				end
			end
			taskProgress = allOk and taskProgress + TICK or 0
			if taskProgress >= 8 then finishTask(true) end
		end
		if currentTask and os.clock() > taskDeadline then finishTask(false) end
	end

	-- Thanh Tẩy
	if carrier then
		if not alive(carrier) then dropNotebook("Sổ rơi mất!")
		else
			IX.Notebook.CFrame = hrp(carrier).CFrame * CFrame.new(0, 0, -1.5)
			if inZone(hrp(carrier).Position, Z.LampZone) then cleanseProgress += TICK wasInLamp = true
			elseif wasInLamp then cleanseProgress *= 0.5 wasInLamp = false end
			S("Cleanse", cleanseProgress / C.CLEANSE_TIME)
			if cleanseProgress >= C.CLEANSE_TIME then
				carrier = nil show(IX.Notebook, false) S("Phase", "Neo") S("Cleanse", 1) S("Cleansed", true)
				for _, p in ipairs(plist) do addSanity(p, C.CLEANSE_BONUS) end
				notify("THANH TẨY thành công! +" .. C.CLEANSE_BONUS .. " Tỉnh táo cả nhóm. Tầng đã ổn định — giờ đặt đủ 3 Mảnh Neo vào Bệ Neo ở hành lang.")
			elseif os.clock() - notebookPickedAt > C.NOTEBOOK_TIMEOUT then
				dropNotebook("Cuốn sổ TÁI SINH về bàn giáo viên!")
			end
		end
	end



	-- Kẻ Đứng Sau Cửa
	if C.STALKER_ENABLED and not G("StalkerActive") and os.clock() - roundStart > C.STALKER_START then
		S("StalkerActive", true) notify("Một cánh cửa ở đâu đó vừa kẹt mở... KẺ ĐỨNG SAU CỬA đã thức dậy. Nó chỉ tiến lại khi không ai nhìn nó.")
	end
	if G("StalkerActive") and os.clock() > stalkerPauseUntil then
		local seen = false
		for _, p in ipairs(plist) do local vv = view[p] if alive(p) and vv and vv.sees and os.clock() - vv.t < 0.6 then seen = true end end
		local st = IX.Stalker local target, td
		for _, p in ipairs(plist) do
			if alive(p) then
				local d = (hrp(p).Position - st.Position).Magnitude - ((p:GetAttribute("Sanity") or 100) < 25 and 30 or 0)
				if not td or d < td then target, td = p, d end
			end
		end
		if target and not seen then
			local tp = hrp(target).Position local flat = Vector3.new(tp.X, 4.5 * K, tp.Z)
			local dir = flat - st.Position
			if dir.Magnitude > 0.1 then
				local nextPos = st.Position + dir.Unit * math.min(dir.Magnitude, C.STALKER_SPEED * TICK)
				if not inLight(nextPos) then st.CFrame = CFrame.lookAt(nextPos, flat) end
			end
		end
		for _, p in ipairs(plist) do
			if alive(p) and (hrp(p).Position - st.Position).Magnitude < 4 then
				addSanity(p, -C.STALKER_TOUCH)
				notify("☠ KẺ ĐỨNG SAU CỬA đã chạm vào bạn! (−" .. C.STALKER_TOUCH .. " Tỉnh táo). Hãy luôn có người nhìn về phía nó.", p)
				moveStalkerNear(hrp(p).Position, 45)
			end
		end
	end
end
