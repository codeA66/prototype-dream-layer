-- DREAM LAYERS - TẦNG 3: KHU RỪNG MÊ
-- 1 Lobby an toàn (Lửa trại) + 5 phòng có luật:
--   Room1 Rừng đom đóm · Room2 Đầm sương mù · Room3 Cây cổ thụ có mắt · Room4 Hang gỗ mục · Room5 Vườn nấm phát sáng
-- Nguồn Ô Nhiễm: LA BÀN GÃY của cậu bé Minh (dưới gốc Cây Mắt) → thả xuống giữa Đầm sương mù.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Remotes = RS:WaitForChild("Remotes")
local Core = require(game:GetService("ServerScriptService"):WaitForChild("LevelCore"))
local map = Core.mapTemplate("DreamMap3") -- cất bản gốc trước khi sửa map; mỗi lần vào màn sẽ clone lại
local IX = map.Interactables
local Z = map.Zones

local C = {
	DARK_DRAIN = 0.3, LIGHT_HEAL = 1, LIGHT_CAP = 80, NEAR_HEAL = 0.5, NEAR_CAP = 70, NEAR_RANGE = 12,
	HEALER_AURA = 1, HEALER_RANGE = 14, PENALTY = 8,
	ESCAPE_TIME = 12, GATE_TIME = 60, COMPASS_TIME = 90, SIGN_LIVE = 20, LULL_EXTRA = 8,
}

local ST, S, G = Core.state("GameState3")
S("Phase", "Idle")

-- Kênh riêng Tầng 3: client báo "nín thở" (Vườn nấm) và "nhìn xuống nước" (Đầm sương)
local L3Act = Remotes:FindFirstChild("L3Act") or Instance.new("RemoteEvent")
L3Act.Name = "L3Act" L3Act.Parent = Remotes

-- ===== TIỆN ÍCH =====
local function inL3(p) return p:GetAttribute("Level") == 3 end
local function l3Players() return Core.playersIn(3) end
local hrp, speed, addSanity = Core.hrp, Core.speed, Core.addSanity
local show, en = Core.show, Core.en
local giveTool, removeTool = Core.giveTool, Core.removeTool
local function now() return workspace:GetServerTimeNow() end
local function alive(p) return inL3(p) and Core.alive(p) end
local function notify(msg, who) Core.notify(msg, who or l3Players()) end
local ROOMS = {"Lobby", "Room1", "Room2", "Room3", "Room4", "Room5"}
local ROOM_NAME3 = {Lobby = "Lửa trại", Room1 = "Rừng đom đóm", Room2 = "Đầm sương mù", Room3 = "Cây cổ thụ có mắt",
	Room4 = "Hang gỗ mục", Room5 = "Vườn nấm phát sáng", Hall = "Lối mòn"}
local function roomOf(pos) return Core.zoneRoom(Z, ROOMS, pos, "Hall") end
local function inRoom(room) local t = {} for _, p in ipairs(l3Players()) do if alive(p) and p:GetAttribute("Room3") == room then table.insert(t, p) end end return t end
local function active() local ph = G("Phase") return ph ~= "Idle" and ph ~= "Win" and ph ~= "Lose" end
local function playing() local ph = G("Phase") return ph == "TrinhSat" or ph == "TruyNguyen" or ph == "ThanhTay" or ph == "Neo" end
local function awake(room) return playing() and G("Active_" .. room) end -- phòng chỉ "thức dậy" khi có người bước vào
local function calm(room) return Core.isLulled(G, room) end
local function stillEntity(room) return Core.isFrozen(G, room) or Core.isLulled(G, room) end -- thực thể bị Neo / được Ru thì không bắt ai
local violate = Core.newRules({prefix = "⚠ ", penalty = C.PENALTY, notify = notify,
	blocked = function(p) return G("Phase") == "Gate" or not inL3(p) end})
local prompt = Core.newPrompter(function(p) return inL3(p) and active() end)
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function inAny(model, pos, name, padY)
	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("BasePart") and (not name or c.Name == name) and Core.inZone(pos, c, padY or 4) then return c end
	end
end
local function inRing(model, pos) -- vòng nấm: Part hình trụ nằm ngang, bán kính = Size.Y / 2
	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("BasePart") and (flat(pos) - flat(c.Position)).Magnitude <= c.Size.Y / 2 then return c end
	end
end
-- Bài Ru giữ trạng thái an toàn: sự kiện xấu kế tiếp bị hoãn tới khi hết Ru
local function holdWhileLulled(room, attr)
	while Core.isLulled(G, room) do
		task.wait(0.2)
		if attr and type(G(attr)) == "number" then S(attr, math.max(G(attr), (G("Lull_" .. room) or 0))) end
	end
end
local function say(room, msg) local list = inRoom(room) if #list > 0 then notify(msg, list) end end
-- mỗi luật chỉ phạt 1 người tối đa 1 lần trong "sec" giây (không phạt dồn liên tục trong cùng một lần phòng đổi trạng thái)
local hitCd = {}
local function hitReady(p, key, sec)
	local k = p.UserId .. key
	if (hitCd[k] or 0) > os.clock() then return false end
	hitCd[k] = os.clock() + sec return true
end
local lastRoom = {}
local onChat -- gán ở phần Room3

-- ===== CỬA (F) =====
local doorCtl = Core.wireDoors(map.Doors, {dist = 11, lockedMsg = "Cây cối đã mọc kín lối đi...",
	canUse = function(p) return alive(p) end})

-- ===== DẤU HIỆU: mỗi ván chọn ngẫu nhiên 3 trong 5 phòng =====
local SIGN_KEYS = {"Arrow", "Reflection", "Carving", "Backpack", "Shoe"}
local SIGN_ROOM = {Arrow = "Room1", Reflection = "Room2", Carving = "Room3", Backpack = "Room4", Shoe = "Room5"}
local SIGN_NAMES = {Arrow = "Đom đóm xếp thành mũi tên chỉ ngược đường", Reflection = "Bóng đứa trẻ cầm la bàn dưới nước",
	Carving = "Tên khắc trên thân cây", Backpack = "Chiếc ba lô có tấm bản đồ bị xé", Shoe = "Chiếc giày nhỏ giữa vòng nấm"}
-- mỗi câu ký ức đều hướng về LA BÀN (hoặc loại trừ một lựa chọn sai) → 3 câu bất kỳ vẫn giải được câu đố
local SIGN_MEMORY = {
	Arrow = "“Đom đóm bay theo hướng mũi KIM nhỏ mình cầm… càng đi càng xa lều.”",
	Reflection = "“Dưới nước, mặt kim cứ quay mãi, không chịu dừng.”",
	Carving = "“Lần thứ ba mình khắc tên lên cây này rồi… mình vẫn đi đúng hướng KIM chỉ mà?”",
	Backpack = "“Mất bản đồ cũng không sao — mình còn cái ba tặng, nó luôn chỉ hướng Bắc.”",
	Shoe = "“Đèn pin vẫn sáng, giày vẫn còn một chiếc… chỉ có thứ trong túi áo là quay cuồng.”",
}
local function signOn(key) return (G("SignSet") or ""):find(key, 1, true) ~= nil end
local liveUntil = {}
local function makeLive(key)
	if G("Phase") ~= "TrinhSat" or not signOn(key) or G("Sign_" .. key) then return end
	liveUntil[key] = os.clock() + C.SIGN_LIVE S("SignLive_" .. key, true)
	Core.sense(3, ROOM_NAME3[SIGN_ROOM[key]])
end
local function registerSign(key, p)
	if G("Sign_" .. key) or not G("SignLive_" .. key) then return end
	S("Sign_" .. key, true) S("SignLive_" .. key, false)
	S("Signs", (G("Signs") or 0) + 1)
	for _, o in ipairs(l3Players()) do Remotes.Notify:FireClient(o, "__MEMORY__|" .. SIGN_NAMES[key] .. "|" .. SIGN_MEMORY[key]) end
	if G("Signs") >= 3 then
		S("Phase", "TruyNguyen")
		for i = 1, 4 do en(IX["Puzzle" .. i], true) end
		notify("Đủ 3 Dấu Hiệu! Về LỬA TRẠI, trả lời câu hỏi trên phiến đá: thứ gì khiến cậu bé cứ đi vòng quanh?")
	end
end
local SIGN_PART = {Arrow = IX.Clue_Arrow, Reflection = IX.Clue_Reflection, Carving = IX.Clue_Carving, Backpack = IX.Clue_Backpack, Shoe = IX.Clue_Shoe}
for key, part in pairs(SIGN_PART) do
	prompt(part, "Ghi nhận", "Điều kỳ lạ", 1, function(p)
		if G("SignLive_" .. key) then registerSign(key, p) else notify("Không có gì lạ ở đây... lúc này.", p) end
	end, Enum.KeyCode.R)
end
-- hiện / ẩn phần hình ảnh của từng dấu hiệu
local function setSignVisual(key, on)
	if key == "Arrow" then for _, f in ipairs(IX.ArrowFlies:GetChildren()) do f.Transparency = on and 0 or 1 end
	elseif key == "Reflection" then IX.Clue_Reflection.Transparency = on and 0.5 or 1 IX.Clue_Reflection.SurfaceGui.Text.TextTransparency = on and 0 or 1
	elseif key == "Carving" then IX.Clue_Carving.SurfaceGui.Text.TextTransparency = on and 0 or 1
	elseif key == "Backpack" then IX.Clue_Backpack.Transparency = on and 0 or 1 IX.Clue_Backpack.PointLight.Brightness = on and 0.8 or 0
	elseif key == "Shoe" then IX.Clue_Shoe.Transparency = on and 0 or 1 IX.Clue_Shoe.PointLight.Brightness = on and 0.8 or 0 end
end

-- ===== TỜ NỘI QUY + NHẬT KÝ KIỂM LÂM =====
prompt(IX.RulesPaper, "Nhặt", "Nội quy khu cắm trại", 0.5, function(p)
	p:SetAttribute("HasRules3", true)
	giveTool(p, "NoiQuyRung", "Nội quy khu cắm trại (cầm lên để đọc · M)", Vector3.new(1.4, 0.05, 1.9), Color3.fromRGB(236, 228, 205))
	Remotes.Notify:FireClient(p, "__L3RULES__")
end)
prompt(IX.RangerLog, "Đọc", "Nhật ký kiểm lâm", 1, function(p)
	p:SetAttribute("HasLog3", true)
	giveTool(p, "NhatKyKiemLam", "Nhật ký kiểm lâm (cầm lên để đọc)", Vector3.new(1.3, 0.3, 1.8), Color3.fromRGB(60, 80, 50))
	Remotes.Notify:FireClient(p, "__DIARY3__")
end)

-- ===================================================================
-- ROOM1 — RỪNG ĐOM ĐÓM: sáng 20s → nhấp nháy 2s → TẮT 6–8s
-- Luật: tắt thì ĐỨNG YÊN (12) · chỉ đi trên lối đá trắng (8, bị đưa về đầu phòng) · không bắt đom đóm (8)
-- Thưởng: đứng yên trọn một lần tắt → MẢNH NEO 1 hiện ra cuối lối đá
-- ===================================================================
local FLIES = IX.Fireflies:GetChildren()
local function setFlies(on)
	for _, f in ipairs(FLIES) do
		f.Transparency = on and 0 or 1
		local l = f:FindFirstChildOfClass("PointLight") if l then l.Enabled = on end
	end
end
local stillOK = {} -- người đứng yên suốt lần tắt đèn hiện tại
task.spawn(function()
	while true do
		setFlies(true) S("FireflyOn", true)
		S("FireflyOffAt", now() + 22) -- 20s sáng + 2s nhấp nháy báo trước
		Core.waitUnfrozen(S, G, "Room1", 20, {"FireflyOffAt"})
		if not awake("Room1") then continue end
		holdWhileLulled("Room1", "FireflyOffAt")
		say("Room1", "Đàn đom đóm nhấp nháy dồn dập...")
		for _ = 1, 5 do setFlies(false) task.wait(0.2) setFlies(true) task.wait(0.2) end
		for k in pairs(stillOK) do stillOK[k] = nil end
		for _, p in ipairs(inRoom("Room1")) do stillOK[p] = true end
		setFlies(false) S("FireflyOn", false)
		local d = math.random(6, 8) S("FireflyOnAt", now() + d)
		Core.waitUnfrozen(S, G, "Room1", d, {"FireflyOnAt"})
		setFlies(true) S("FireflyOn", true)
		for p, ok in pairs(stillOK) do
			if ok and alive(p) and p:GetAttribute("Room3") == "Room1" and not G("Shard1Given") then
				S("Shard1Given", true) show(IX.AnchorShard1, true) IX.AnchorShard1.PointLight.Enabled = true
				notify(p.Name .. " đứng yên trọn bóng tối... ánh đom đóm tụ lại cuối lối đá thành một MẢNH NEO!")
			end
		end
		for k in pairs(stillOK) do stillOK[k] = nil end
		makeLive("Arrow")
	end
end)
prompt(IX.FireflyJar, "Bắt đom đóm", "Lọ thủy tinh", 0.5, function(p)
	violate(p, "Rừng đom đóm — bạn đã BẮT ĐOM ĐÓM", 8)
end)

-- ===================================================================
-- ROOM2 — ĐẦM SƯƠNG MÙ: im 15–20s → leng keng 2s → CHUÔNG VANG 8s
-- Luật: chuông vang thì không rời lối đá (12) · không nhìn xuống nước quá 3s (10) · cầu gỗ chỉ 1 người (8)
-- ===================================================================
local BELL = IX.Chime.Bell
task.spawn(function()
	while true do
		S("ChimeRing", false) pcall(function() BELL.Ring:Stop() end) BELL.PointLight.Brightness = 0
		local w = math.random(15, 20) S("ChimeAt", now() + w + 2) -- +2s leng keng báo trước
		Core.waitUnfrozen(S, G, "Room2", w, {"ChimeAt"})
		if not awake("Room2") then continue end
		holdWhileLulled("Room2", "ChimeAt")
		pcall(function() BELL.Tinkle:Play() end)
		say("Room2", "*leng keng*... gió bắt đầu nổi trên đầm.")
		task.wait(2)
		S("ChimeRing", true) pcall(function() BELL.Ring:Play() end) BELL.PointLight.Brightness = 1.5
		S("ChimeEndAt", now() + 8)
		Core.waitUnfrozen(S, G, "Room2", 8, {"ChimeEndAt"})
		S("ChimeRing", false) pcall(function() BELL.Ring:Stop() end) BELL.PointLight.Brightness = 0
		say("Room2", "Tiếng chuông dứt. Mặt nước lặng như gương...")
		makeLive("Reflection")
	end
end)
local function onStone(pos) return inAny(IX.Stones, pos) or Core.inZone(pos, IX.Bridge, 4) end
local lookDownT = {}
local bridgeSince = {}
L3Act.OnServerEvent:Connect(function(p, what, v)
	if not alive(p) then return end
	if what == "Breath" then p:SetAttribute("HoldBreath", v == true)
	elseif what == "Chat" then onChat(p)
	elseif what == "LookDown" then
		if p:GetAttribute("Room3") ~= "Room2" or calm("Room2") then return end
		if (lookDownT[p] or 0) > os.clock() then return end
		lookDownT[p] = os.clock() + 4
		violate(p, "Đầm sương mù — bạn NHÌN XUỐNG NƯỚC quá lâu, có thứ gì đó nhìn lại", 10)
	end
end)

-- ===================================================================
-- ROOM3 — CÂY CỔ THỤ CÓ MẮT: nhắm 12–18s → lá xào xạc 2s → MỞ MẮT 6s
-- Luật: cây mở mắt thì quay lưng lại (15) · không chạm rễ phát sáng (8) · không chat khi cây mở mắt (8)
-- ===================================================================
local TREE = IX.EyeTree
local EYES = {} for _, e in ipairs(TREE:GetChildren()) do if e.Name == "Eye" then table.insert(EYES, e) end end
local TREE_POS = TREE.Trunk.Position
local function setEyes(open)
	for _, e in ipairs(EYES) do e.Color = open and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 20, 20) e.PointLight.Brightness = open and 2 or 0 end
end
task.spawn(function()
	while true do
		S("EyeOpen", false) setEyes(false)
		local w = math.random(12, 18) S("EyeOpenAt", now() + w + 2) -- +2s lá xào xạc báo trước
		Core.waitUnfrozen(S, G, "Room3", w, {"EyeOpenAt"})
		if not awake("Room3") then continue end
		holdWhileLulled("Room3", "EyeOpenAt")
		say("Room3", "Lá cây xào xạc... một vệt sáng đỏ bò lên thân cây.")
		for _, e in ipairs(EYES) do e.PointLight.Brightness = 0.6 end
		task.wait(2)
		S("EyeOpen", true) setEyes(true) S("EyeCloseAt", now() + 6)
		Core.waitUnfrozen(S, G, "Room3", 6, {"EyeCloseAt"})
		S("EyeOpen", false) setEyes(false)
		makeLive("Carving")
	end
end)
local function facingTree(p)
	local r = hrp(p) if not r then return false end
	local to = flat(TREE_POS - r.Position) if to.Magnitude < 0.1 then return true end
	local look = flat(r.CFrame.LookVector) if look.Magnitude < 0.1 then return false end
	return look.Unit:Dot(to.Unit) > 0.2
end
-- nói chuyện: Player.Chatted (chat cũ) + client báo "Chat" (TextChatService mới)
onChat = function(p)
	if alive(p) and p:GetAttribute("Room3") == "Room3" and G("EyeOpen") and not stillEntity("Room3") and hitReady(p, "chat", 2) then
		violate(p, "Cây cổ thụ — bạn NÓI CHUYỆN khi cây đang mở mắt", 8)
	end
end
local function hookChat(p) p.Chatted:Connect(function() onChat(p) end) end

-- ===================================================================
-- ROOM4 — HANG GỖ MỤC: gõ xa 12–18s → GÕ GẦN 10s → KẺ GÕ ĐI NGANG 6s
-- Luật: Kẻ Gõ đi ngang mà không nép trong hốc tường → bị chạm (18) · không nhảy trong hang (8)
--       đếm tiếng gõ lúc vào hang, trước khi ra gõ lại đúng số đó vào tảng đá cạnh cửa (10)
-- ===================================================================
local KN = IX.Knocker
local KN_HOME = KN:GetPivot()
local KPATH = {} for i = 1, 4 do KPATH[i] = IX.KnockPath["P" .. i].Position end
local ECHO = IX.CaveEcho
local passHit = {}
local function knockSound(n, gap)
	for _ = 1, n do pcall(function() ECHO.Knock:Play() end) task.wait(gap) end
end
task.spawn(function()
	while true do
		S("KnockState", "far") KN:PivotTo(KN_HOME)
		local w = math.random(12, 18) S("KnockPassAt", now() + w + 10)
		local t = 0
		while t < w do -- tiếng gõ xa, thưa
			local dt = math.random(3, 5)
			Core.waitUnfrozen(S, G, "Room4", dt, {"KnockPassAt"}) t += dt
			if awake("Room4") then task.spawn(knockSound, 1, 0) end
		end
		if not awake("Room4") then continue end
		holdWhileLulled("Room4", "KnockPassAt")
		S("KnockState", "near") S("KnockPassAt", now() + 10)
		say("Room4", "CỐC. CỐC. CỐC. Tiếng gõ dồn dập và TO dần... nó đang tới gần!")
		local nt = 0
		while nt < 10 do
			Core.waitUnfrozen(S, G, "Room4", 1, {"KnockPassAt"}) nt += 1
			pcall(function() ECHO.Knock.PlaybackSpeed = 0.4 + nt * 0.03 ECHO.Knock:Play() end)
		end
		S("KnockState", "pass")
		for k in pairs(passHit) do passHit[k] = nil end
		-- Kẻ Gõ đi dọc lối trong hang (6 giây); Neo thì đứng yên
		local el = 0
		while el < 6 do
			local dt = task.wait(0.1)
			if not Core.isFrozen(G, "Room4") then el += dt end
			local k = math.clamp(el / 6, 0, 1) * (#KPATH - 1)
			local i = math.min(#KPATH - 1, math.floor(k) + 1)
			local pos = KPATH[i]:Lerp(KPATH[i + 1], k - (i - 1))
			local nxt = KPATH[i + 1]
			if (flat(nxt) - flat(pos)).Magnitude > 0.1 then KN:PivotTo(CFrame.lookAt(pos, Vector3.new(nxt.X, pos.Y, nxt.Z))) end
		end
		S("KnockState", "far") KN:PivotTo(KN_HOME)
		say("Room4", "Tiếng bước chân xa dần... trong hang có thứ gì đó vừa rơi lại.")
		makeLive("Backpack")
	end
end)
local function inNiche(pos) return inAny(IX.Niches, pos, "Niche", 4) end
-- đếm tiếng gõ khi vào hang
local function knockWelcome(p)
	local n = math.random(2, 5)
	p:SetAttribute("KnockNeed", n) p:SetAttribute("KnockGiven", 0)
	task.spawn(function()
		task.wait(1)
		for i = 1, n do
			pcall(function() IX.KnockStone.Knock:Play() end)
			Remotes.Notify:FireClient(p, "*cốc*" .. string.rep("  ·", i))
			task.wait(0.9)
		end
	end)
end
prompt(IX.KnockStone, "Gõ 1 tiếng", "Tảng đá cạnh cửa", 0, function(p)
	p:SetAttribute("KnockGiven", (p:GetAttribute("KnockGiven") or 0) + 1)
	pcall(function() IX.KnockStone.Knock:Play() end)
	notify("Bạn gõ vào tảng đá: *cốc* (" .. p:GetAttribute("KnockGiven") .. ")", p)
end)
local function hookJump(p, char)
	local hum = char:WaitForChild("Humanoid", 5) if not hum then return end
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping and alive(p) and p:GetAttribute("Room3") == "Room4" and not calm("Room4") then
			violate(p, "Hang gỗ mục — bạn đã NHẢY, trần hang rung lên", 8)
		end
	end)
end

-- ===================================================================
-- ROOM5 — VƯỜN NẤM PHÁT SÁNG: tối 15s → phồng lên 2s → PHUN BÀO TỬ 5s
-- Luật: nấm sáng thì NÍN THỞ (giữ B) (12) · không hái nấm (10) · không bước vào vòng nấm đỏ (8)
-- ===================================================================
local CAPS = {} for _, m in ipairs(IX.Mushrooms:GetChildren()) do if m:FindFirstChild("Cap") then table.insert(CAPS, m.Cap) end end
local CLOUD = IX.SporeCloud
local glowSince = 0
local breathHit = {}
local function setGlow(k) -- 0 = tối, 1 = sáng rực
	for _, c in ipairs(CAPS) do
		c.Color = Color3.fromRGB(40, 70, 80):Lerp(Color3.fromRGB(110, 255, 230), k)
		local l = c:FindFirstChildOfClass("PointLight") if l then l.Brightness = 0.2 + k * 1.8 end
	end
	CLOUD.Transparency = 1 - k * 0.25
end
task.spawn(function()
	while true do
		S("SporeGlow", false) setGlow(0)
		S("SporeAt", now() + 17)
		Core.waitUnfrozen(S, G, "Room5", 15, {"SporeAt"})
		if not awake("Room5") then continue end
		holdWhileLulled("Room5", "SporeAt")
		say("Room5", "Những cây nấm PHỒNG lên, phát ra tiếng “phì”...")
		pcall(function() CLOUD.Hiss:Play() end)
		setGlow(0.4) task.wait(2)
		for k in pairs(breathHit) do breathHit[k] = nil end
		S("SporeGlow", true) setGlow(1) glowSince = os.clock() S("SporeEndAt", now() + 5)
		Core.waitUnfrozen(S, G, "Room5", 5, {"SporeEndAt"})
		S("SporeGlow", false) setGlow(0)
		say("Room5", "Bào tử lắng xuống. Bạn có thể thở lại.")
		makeLive("Shoe")
	end
end)
prompt(IX.PickMushroom.Cap, "Hái nấm", "Nấm lạ phát sáng", 1, function(p)
	violate(p, "Vườn nấm — bạn đã HÁI thứ mọc dưới đất", 10)
end)

-- ===== TRUY NGUYÊN: phiến đá ở Lửa trại =====
local CHOICES = {"LA BÀN GÃY", "BẢN ĐỒ BỊ XÉ", "ĐÈN PIN HẾT PIN", "CHIẾC GIÀY"} -- 1 = đáp án đúng
local order = {1, 2, 3, 4}
local function shufflePuzzle()
	order = {1, 2, 3, 4}
	for i = 4, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
	for slot = 1, 4 do
		IX["Puzzle" .. slot].SurfaceGui.Text.Text = CHOICES[order[slot]]
		if order[slot] == 1 then S("CorrectPuzzle", slot) end
	end
end
local COMPASS = IX.Compass
local COMPASS_HOME = COMPASS.CFrame
for slot = 1, 4 do
	prompt(IX["Puzzle" .. slot], "CHỌN", "Hòn đá " .. slot, 1, function(p)
		if G("Phase") ~= "TruyNguyen" then return end
		if slot == G("CorrectPuzzle") then
			S("Phase", "ThanhTay")
			for i = 1, 4 do en(IX["Puzzle" .. i], false) end
			show(COMPASS, true) COMPASS.PointLight.Brightness = 1
			notify("Đúng rồi — LA BÀN GÃY! Nó đang nằm dưới gốc CÂY CỔ THỤ. Mang nó thả xuống GIỮA ĐẦM SƯƠNG MÙ trong " .. C.COMPASS_TIME .. " giây!")
		else
			violate(p, "Sai rồi — khu rừng xoay một vòng quanh bạn", 8)
		end
	end)
end

-- ===== THANH TẨY: la bàn gãy → giữa đầm =====
local carrier, carryAt = nil, 0
local function setSlow(p, on)
	local c = p.Character local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = on and 11 or (p:GetAttribute("Dreaming") and 22 or 16) end
end
local function resetCompass(msg)
	if carrier then removeTool(carrier, "LaBanGay") setSlow(carrier, false) end
	carrier = nil S("CompassCarrier", "") S("CompassDeadline", 0)
	COMPASS.CFrame = COMPASS_HOME
	show(COMPASS, G("Phase") == "ThanhTay") COMPASS.PointLight.Brightness = G("Phase") == "ThanhTay" and 1 or 0
	if msg then notify(msg) end
end
prompt(COMPASS, "Nhặt la bàn gãy", "Nguồn Ô Nhiễm", 1, function(p)
	if G("Phase") ~= "ThanhTay" or carrier then return end
	carrier = p carryAt = os.clock()
	show(COMPASS, false) COMPASS.PointLight.Brightness = 0
	giveTool(p, "LaBanGay", "La bàn gãy — kim quay không ngừng. Thả xuống giữa Đầm sương mù", Vector3.new(1.2, 0.3, 1.2), Color3.fromRGB(190, 160, 90))
	setSlow(p, true)
	S("CompassCarrier", p.Name) S("CompassDeadline", now() + C.COMPASS_TIME)
	notify(p.Name .. " cầm LA BÀN GÃY — nó nặng trĩu, bạn ấy đi chậm lại. Đồng đội hãy canh chuông gió và mắt cây!")
end)
prompt(IX.DropPoint, "Thả la bàn xuống đầm", "Giữa đầm", 3, function(p)
	if G("Phase") ~= "ThanhTay" then return end
	if carrier ~= p then notify("Cần mang LA BÀN GÃY tới đây.", p) return end
	removeTool(p, "LaBanGay") setSlow(p, false) carrier = nil S("CompassCarrier", "") S("CompassDeadline", 0)
	S("Cleansed", true) S("Phase", "Neo")
	for _, o in ipairs(l3Players()) do addSanity(o, 20) end
	notify("THANH TẨY thành công! La bàn chìm xuống đáy đầm, sương tan dần. (+20 Tỉnh táo) — Gom đủ 3 Mảnh Neo, đặt vào Bệ Neo cạnh lửa trại.")
end)

-- ===== MẢNH NEO / BỆ NEO / CỔNG =====
for i = 1, 3 do
	local sh = IX["AnchorShard" .. i]
	prompt(sh, "Nhặt", "Mảnh Neo Thức", 0.5, function(p)
		if sh.Transparency >= 1 then return end
		show(sh, false) sh.PointLight.Enabled = false
		S("Shards", (G("Shards") or 0) + 1)
		notify(p.Name .. " nhặt Mảnh Neo (" .. G("Shards") .. "/3)")
	end)
end
local escape = Core.newEscape({gate = IX.Gate, S = S, G = G, doors = doorCtl, players = l3Players, alive = alive,
	escapeTime = C.ESCAPE_TIME, gateTime = C.GATE_TIME, notify = notify,
	safe = function(p) return roomOf(hrp(p).Position) == "Lobby" end,
	target = function() local esc = workspace:FindFirstChild("DreamMap") and workspace.DreamMap:FindFirstChild("EscapeRoom") return esc and esc:GetPivot() end,
	openMsg = "MỌI QUY LUẬT ĐÃ BIẾN MẤT. Cây cối đang khép lối — " .. C.ESCAPE_TIME .. " giây nữa rừng nuốt mọi con đường. CHẠY VỀ LỬA TRẠI, qua CỔNG GỖ!",
	trappedMsg = "Cành cây đan kín sau lưng bạn... Bạn bị lạc lại trong rừng.",
	onOpen = function() resetCompass() end})
prompt(IX.AnchorAltar, "Đặt Mảnh Neo", "Bệ Neo", 1, function(p)
	if G("Phase") == "Gate" then return end
	if (G("Shards") or 0) < 3 then notify("Cần đủ 3 Mảnh Neo (đang có " .. (G("Shards") or 0) .. ").", p) return end
	if not G("Cleansed") then notify("Bệ Neo không phản ứng... Khu rừng vẫn còn ô nhiễm. Hãy THANH TẨY trước.", p) return end
	escape.open()
end)

-- ===== KỸ NĂNG THEO PHÒNG (Tầng 3) =====
local function secs(attr) return math.max(0, math.floor((G(attr) or 0) - now())) end
local function nicheSteps(p)
	local r = hrp(p) if not r then return end
	local list = {} for _, n in ipairs(IX.Niches:GetChildren()) do if n.Name == "Niche" then table.insert(list, n) end end
	table.sort(list, function(a, b) return (a.Position - r.Position).Magnitude < (b.Position - r.Position).Magnitude end)
	local out = {} for i = 1, math.min(2, #list) do table.insert(out, string.format("%.1f,%.1f", list[i].Position.X, list[i].Position.Z)) end
	Remotes.Notify:FireClient(p, "__STEPS__|" .. table.concat(out, ";"))
end
local function divineL3(p, room)
	if room == "Lobby" then
		local ph = G("Phase")
		if ph == "TrinhSat" then
			local left = {} for _, k in ipairs(SIGN_KEYS) do if signOn(k) and not G("Sign_" .. k) then table.insert(left, ROOM_NAME3[SIGN_ROOM[k]]) end end
			return "Đêm nay, điều kỳ lạ còn đợi ở: " .. table.concat(left, " · ") .. ".\nNhật ký kiểm lâm ghi KHI NÀO chúng hiện ra."
		elseif ph == "TruyNguyen" then return "Ba ký ức đều nói về HƯỚNG ĐI. Thứ gì trong túi áo cậu bé chỉ đường sai?"
		elseif ph == "ThanhTay" then return carrier and ("La bàn đang ở trong tay " .. string.upper(carrier.DisplayName) .. " — còn " .. secs("CompassDeadline") .. " giây.") or "La bàn gãy nằm dưới gốc Cây cổ thụ. Thả nó giữa Đầm sương mù."
		elseif ph == "Neo" then return "Mảnh Neo: " .. (G("Shards") or 0) .. "/3. Một mảnh chỉ hiện ra cho người biết ĐỨNG YÊN trong bóng tối của rừng đom đóm." end
		return nil
	elseif room == "Room1" then
		return G("FireflyOn") and ("Đom đóm sẽ TẮT sau khoảng " .. secs("FireflyOffAt") .. " giây. Khi đó hãy đứng yên.")
			or ("Đom đóm sẽ sáng lại sau " .. secs("FireflyOnAt") .. " giây. Đừng nhúc nhích!")
	elseif room == "Room2" then
		return G("ChimeRing") and ("Chuông gió còn vang " .. secs("ChimeEndAt") .. " giây nữa — đứng trên đá!")
			or ("Chuông gió sẽ vang sau khoảng " .. secs("ChimeAt") .. " giây, kéo dài 8 giây.")
	elseif room == "Room3" then
		return G("EyeOpen") and ("Cây còn mở mắt " .. secs("EyeCloseAt") .. " giây — quay lưng lại!")
			or ("Cây sẽ mở mắt sau khoảng " .. secs("EyeOpenAt") .. " giây, trong 6 giây.")
	elseif room == "Room4" then
		nicheSteps(p)
		return "Kẻ Gõ đi ngang sau khoảng " .. secs("KnockPassAt") .. " giây. Hai vòng sáng dưới đất là hốc tường gần bạn nhất."
			.. (p:GetAttribute("KnockNeed") and ("\nTiếng gõ lúc bạn vào hang: " .. p:GetAttribute("KnockNeed") .. " lần.") or "")
	elseif room == "Room5" then
		local out = {} for _, c in ipairs(IX.WhiteRings:GetChildren()) do table.insert(out, string.format("%.1f,%.1f", c.Position.X, c.Position.Z)) end
		Remotes.Notify:FireClient(p, "__STEPS__|" .. table.concat(out, ";"))
		return G("SporeGlow") and ("Bào tử còn phun " .. secs("SporeEndAt") .. " giây — NÍN THỞ!")
			or ("Nấm sẽ phun bào tử sau khoảng " .. secs("SporeAt") .. " giây. Vòng sáng dưới đất là vòng nấm TRẮNG an toàn.")
	end
end
local LULL_ATTR = {Room1 = "FireflyOffAt", Room2 = "ChimeAt", Room3 = "EyeOpenAt", Room4 = "KnockPassAt", Room5 = "SporeAt"}
local LULL_MSG = {Room1 = "Đom đóm sáng dịu lại, lâu thêm một chút...", Room2 = "Gió lặng hẳn — chuông gió im thêm một lúc.",
	Room3 = "Cây cổ thụ lim dim... nhắm mắt thêm một lúc.", Room4 = "Tiếng bước chân trong hang chậm lại...", Room5 = "Những cây nấm xẹp xuống, ngủ thêm một lúc."}
local function lullL3(p, room)
	if not LULL_ATTR[room] then return end
	local untilT = now() + C.LULL_EXTRA
	S("Lull_" .. room, untilT)
	local a = LULL_ATTR[room] if type(G(a)) == "number" then S(a, math.max(G(a), untilT)) end
	say(room, "♪ " .. LULL_MSG[room])
end

-- ===== BẮT ĐẦU / KẾT THÚC TẦNG 3 =====
local LIE_POOL = 4
local function spawnAt(p)
	local r = hrp(p) if r then r.Anchored = false r.CFrame = IX.Spawn3.CFrame + Vector3.new(math.random(-6, 6), 4, math.random(-3, 3)) end
end
local function startLevel3()
	S("Phase", "TrinhSat") S("Signs", 0) S("Shards", 0) S("Cleansed", false) S("Shard1Given", false)
	-- chọn 3 trong 5 dấu hiệu
	local keys = table.clone(SIGN_KEYS)
	for i = #keys, 2, -1 do local j = math.random(i) keys[i], keys[j] = keys[j], keys[i] end
	S("SignSet", table.concat({keys[1], keys[2], keys[3]}, ","))
	for _, k in ipairs(SIGN_KEYS) do S("Sign_" .. k, false) S("SignLive_" .. k, false) setSignVisual(k, false) liveUntil[k] = nil end
	S("LieIndex", math.random(LIE_POOL)) S("StartedAt", now())
	for _, r in ipairs({"Room1", "Room2", "Room3", "Room4", "Room5"}) do S("Active_" .. r, false) end
	shufflePuzzle() for i = 1, 4 do en(IX["Puzzle" .. i], false) end
	show(IX.AnchorShard1, false) IX.AnchorShard1.PointLight.Enabled = false
	for k in pairs(lastRoom) do lastRoom[k] = nil end for k in pairs(hitCd) do hitCd[k] = nil end
	for i = 2, 3 do show(IX["AnchorShard" .. i], true) IX["AnchorShard" .. i].PointLight.Enabled = true end
	carrier = nil resetCompass()
	escape.reset()
	doorCtl.locked = false doorCtl.setAll(false)
	for _, p in ipairs(l3Players()) do
		for _, a in ipairs({"HasRules3", "HasLog3", "HoldBreath", "KnockNeed", "KnockGiven", "Room3"}) do p:SetAttribute(a, nil) end
		spawnAt(p)
	end
	notify("TẦNG 3 — KHU RỪNG MÊ. Nhặt NỘI QUY KHU CẮM TRẠI trên gốc cây cạnh lửa trại. Cẩn thận: không phải dòng viết tay nào cũng là thật. Bên kia lửa trại có một cuốn NHẬT KÝ KIỂM LÂM...")
end
local function endLevel3(win, msg)
	if G("Phase") == "Win" or G("Phase") == "Lose" then return end
	S("RoundTime", math.floor(now() - (G("StartedAt") or 0)))
	S("Phase", win and "Win" or "Lose")
	notify(msg)
	task.delay(8, function() Core.finishLevel(3, win) end)
end
local startEvent = SS:FindFirstChild("StartLevel3") or Instance.new("BindableEvent", SS) startEvent.Name = "StartLevel3"
startEvent.Event:Connect(function() Core.startLevel(3) end)

-- ===== ĐĂNG KÝ TẦNG 3 VỚI LEVELCORE =====
Core.register(3, {
	S = S, G = G, state = ST, escape = escape,
	name = "Khu Rừng Mê", start = function() Core.reloadLevel(script, "DreamMap3") end, loseRestart = true, -- mỗi lần vào màn: map mới + script mới
	sleep = function() S("Phase", "Idle") end,
	active = active,
	debug = { -- chỉ dùng khi test trong Studio: ServerStorage.CoreDebug:Invoke("lv", "<lệnh>")
		signs = function() for _, k in ipairs(SIGN_KEYS) do if signOn(k) then S("SignLive_" .. k, true) registerSign(k) end end end,
		neo = function() S("Phase", "Neo") S("Cleansed", true) S("Shards", 3) end,
	},
	tools = {"NoiQuyRung", "NhatKyKiemLam", "LaBanGay"},
	onDream = function(p)
		if carrier == p then resetCompass("Người cầm la bàn đã hòa mộng — la bàn quay về dưới gốc Cây cổ thụ!") end
		p:SetAttribute("HoldBreath", false)
	end,
	skill = {roomAttr = "Room3", safeRooms = {Hall = true, Lobby = true}, roomName = ROOM_NAME3, divine = divineL3, onLull = lullL3,
		allowed = function(p) if not active() then return "" end end,
		onSeer = function(p) p:SetAttribute("SightRoom", p:GetAttribute("Room3")) end, -- chỉ soi phòng lúc dùng
	},
})

-- ===== TICK CHÍNH =====
local TICK = 0.2
local function hookCharacter(p)
	p.CharacterAdded:Connect(function(char)
		task.wait(0.3)
		if inL3(p) then spawnAt(p) end
		hookJump(p, char)
	end)
	if p.Character then task.spawn(hookJump, p, p.Character) end
	hookChat(p)
end
Players.PlayerAdded:Connect(hookCharacter)
for _, p in ipairs(Players:GetPlayers()) do hookCharacter(p) end -- script được chạy lại khi làm mới map
Players.PlayerRemoving:Connect(function(p) if carrier == p then resetCompass("Người cầm la bàn đã rời đi — la bàn quay về gốc cây.") end end)
if script:GetAttribute("Boot") == "start" then task.defer(startLevel3) end

while true do
	task.wait(TICK)
	local ph = G("Phase")
	if ph == "Idle" or ph == "Win" or ph == "Lose" then continue end
	local plist = l3Players()
	local escaping = ph == "Gate"
	local onBridge = {}
	for _, p in ipairs(plist) do
		if alive(p) and not p:GetAttribute("Escaped") then
			local pos = hrp(p).Position
			local room = roomOf(pos)
			local prev = lastRoom[p]
			p:SetAttribute("Room3", room)
			if room ~= "Hall" and room ~= "Lobby" and not G("Active_" .. room) then S("Active_" .. room, true) end
			-- vào / ra hang
			if room == "Room4" and prev ~= "Room4" and not escaping then knockWelcome(p) end
			if prev == "Room4" and room ~= "Room4" and not escaping and p:GetAttribute("KnockNeed") then
				if (p:GetAttribute("KnockGiven") or 0) ~= p:GetAttribute("KnockNeed") and not calm("Room4") then
					violate(p, "Hang gỗ mục — bạn ra khỏi hang mà không gõ lại ĐÚNG " .. p:GetAttribute("KnockNeed") .. " tiếng", 10)
				else notify("Tiếng gõ đáp lại từ sâu trong hang... nó để bạn đi.", p) end
				p:SetAttribute("KnockNeed", nil) p:SetAttribute("KnockGiven", nil)
			end
			lastRoom[p] = room
			if not escaping then
				Core.tickSanity(p, plist, room == "Lobby", C, TICK) -- lửa trại hồi Tỉnh táo
				if room == "Room1" then
					if not G("FireflyOn") and not calm("Room1") and speed(p) > 1.5 then
						stillOK[p] = false
						if hitReady(p, "dark", 9) then violate(p, "Rừng đom đóm — bạn DI CHUYỂN khi đom đóm đã tắt", 12) end
					end
					if inAny(IX.Room1Grass, pos, nil, 3) and not inAny(IX.Room1Path, pos) then
						violate(p, "Rừng đom đóm — bạn bước vào CỎ CAO và bị lạc", 8)
						local r = hrp(p) if r then r.CFrame = IX.Room1Start.CFrame + Vector3.new(0, 3, 0) end
					end
				elseif room == "Room2" then
					if G("ChimeRing") and not calm("Room2") and not onStone(pos) and hitReady(p, "chime", 9) then
						violate(p, "Đầm sương mù — bạn RỜI LỐI ĐÁ khi chuông gió đang vang", 12)
					end
					if Core.inZone(pos, IX.Bridge, 4) then table.insert(onBridge, p) bridgeSince[p] = bridgeSince[p] or os.clock() else bridgeSince[p] = nil end
				elseif room == "Room3" then
					if G("EyeOpen") and not stillEntity("Room3") and facingTree(p) and hitReady(p, "eye", 7) then
						violate(p, "Cây cổ thụ — bạn NHÌN vào cây khi nó mở mắt", 15)
					end
					if inAny(IX.Roots, pos, nil, 3.5) and hitReady(p, "root", 4) then violate(p, "Cây cổ thụ — bạn GIẪM lên rễ cây phát sáng", 8) end
				elseif room == "Room4" then
					if G("KnockState") == "pass" and not stillEntity("Room4") and not passHit[p] and not inNiche(pos) then
						passHit[p] = true
						violate(p, "Hang gỗ mục — Kẻ Gõ đi ngang và CHẠM vào bạn (không nép vào hốc tường)", 18)
					end
				elseif room == "Room5" then
					if G("SporeGlow") and not calm("Room5") and os.clock() - glowSince > 1.2 and not p:GetAttribute("HoldBreath") and not breathHit[p] then
						breathHit[p] = true
						violate(p, "Vườn nấm — bạn HÍT PHẢI bào tử (không nín thở)", 12)
					end
					if inRing(IX.RedRings, pos) and hitReady(p, "ring", 4) then violate(p, "Vườn nấm — bạn bước vào VÒNG NẤM ĐỎ", 8) end
				end
			end
		end
	end
	-- cầu gỗ chỉ chịu 1 người: người lên sau bị phạt
	if #onBridge >= 2 and not calm("Room2") then
		table.sort(onBridge, function(a, b) return (bridgeSince[a] or 0) < (bridgeSince[b] or 0) end)
		for i = 2, #onBridge do
			if hitReady(onBridge[i], "bridge", 4) then violate(onBridge[i], "Đầm sương mù — cầu gỗ KÊU RĂNG RẮC, đã có người khác trên cầu", 8) end
		end
	end

	-- Thua khi cả nhóm hòa mộng (hiệu ứng hòa mộng do LevelCore lo)
	local anyAlive = false
	for _, p in ipairs(plist) do if alive(p) then anyAlive = true end end
	if #plist > 0 and not anyAlive then endLevel3(false, "CẢ NHÓM ĐÃ HÒA MỘNG. Khu rừng giữ tất cả lại... Chơi lại Tầng 3 sau 8 giây.") continue end

	-- dấu hiệu hết thời gian xuất hiện
	for _, k in ipairs(SIGN_KEYS) do
		local live = G("SignLive_" .. k) == true and liveUntil[k] ~= nil and os.clock() < liveUntil[k] and not G("Sign_" .. k)
		if G("SignLive_" .. k) and not live then S("SignLive_" .. k, false) end
		setSignVisual(k, live)
	end

	-- La bàn hết giờ
	if carrier and os.clock() - carryAt > C.COMPASS_TIME then resetCompass("La bàn gãy TÁI SINH dưới gốc Cây cổ thụ!") end

	-- Thoát
	if escaping then
		local r = escape.tick()
		if r == true then endLevel3(true, "QUA TẦNG 3! Ánh bình minh xuyên qua tán lá — cả nhóm tìm được đường ra khỏi khu rừng...") continue
		elseif r == false then endLevel3(false, "Cổng gỗ khép lại. Cả nhóm lạc trong rừng mãi mãi.") end
	end
end
