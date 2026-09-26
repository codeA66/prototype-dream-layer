-- LevelCore — HỆ THỐNG TẦNG DÙNG CHUNG (Dream Layers)
-- Mọi tầng dùng chung: Tỉnh táo, phạt luật, prompt, đồ cầm tay, cửa (F), kỹ năng vai,
-- cổng thoát, hòa mộng, chuyển tầng.
-- THÊM TẦNG MỚI: tạo Script mới trong ServerScriptService rồi gọi
--   Core.register(3, {name = "...", start = fn, sleep = fn, active = fn, tools = {...},
--                     onDream = fn(p), skill = {roomAttr = "Room3", allowed = fn(p)}, loseRestart = true})
-- Thắng tầng n: Core.finishLevel(n, true) tự chuyển sang tầng n+1 (nếu có) hoặc về sảnh.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Remotes = RS:WaitForChild("Remotes")

local Core = {}
Core.Remotes = Remotes
Core.levels = {}
Core.current = nil
Core.promptFns = setmetatable({}, {__mode = "k"})

-- ===== VAI =====
Core.ROLE = {
	-- Thấu Thị: biết cái đang ẩn · Chữa Lành: dỗ dịu & gánh hộ · Người Neo: dừng thời gian · Bói Toán: biết điều sắp tới
	Seer = {enabled = true, max = 100, cost = 3, cd = 18, dur = 12, mark = 15},
	Healer = {enabled = true, max = 100, cost = 5, cd = 30, heal = 25, revive = 40, calm = 12, lull = 3},
	Anchor = {enabled = true, max = 110, cost = 8, cd = 40, dur = 5, door = 5},
	Diviner = {enabled = true, max = 100, cost = 5, cd = 30},
}
Core.ROLE_ORDER = {"Seer", "Healer", "Anchor", "Diviner"}
function Core.roleTaken(r, except)
	for _, o in ipairs(Players:GetPlayers()) do if o ~= except and o:GetAttribute("Role") == r then return o end end
	return nil
end
function Core.fillRoles()
	for _, p in ipairs(Players:GetPlayers()) do
		if not p:GetAttribute("Role") then
			for _, r in ipairs(Core.ROLE_ORDER) do if Core.ROLE[r].enabled and not Core.roleTaken(r, p) then p:SetAttribute("Role", r) break end end
		end
	end
end

-- ===== CƠ BẢN =====
function Core.now() return workspace:GetServerTimeNow() end
function Core.hrp(p) local c = p.Character return c and c:FindFirstChild("HumanoidRootPart") end
function Core.speed(p)
	local r = Core.hrp(p) if not r then return 0 end
	local v = r.AssemblyLinearVelocity return Vector3.new(v.X, 0, v.Z).Magnitude
end
function Core.level(p) return p:GetAttribute("Level") end
function Core.playersIn(n)
	local t = {} for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("Level") == n then table.insert(t, p) end end return t
end
function Core.alive(p) return p:GetAttribute("Sanity") ~= nil and not p:GetAttribute("Dreaming") and Core.hrp(p) ~= nil end
-- who: Player -> 1 người; bảng -> danh sách; nil -> tất cả
function Core.notify(msg, who)
	if typeof(who) == "Instance" then Remotes.Notify:FireClient(who, msg)
	elseif type(who) == "table" then for _, p in ipairs(who) do Remotes.Notify:FireClient(p, msg) end
	else Remotes.Notify:FireAllClients(msg) end
end
-- Trạng thái tầng (Attributes trên 1 Folder trong ReplicatedStorage)
function Core.state(name)
	local f = RS:FindFirstChild(name) or Instance.new("Folder")
	f.Name = name f.Parent = RS
	f:GetAttributeChangedSignal("Phase"):Connect(function() if Core.log then Core.log("phase", nil, name .. ":" .. tostring(f:GetAttribute("Phase"))) end end)
	return f, function(k, v) f:SetAttribute(k, v) end, function(k) return f:GetAttribute(k) end
end
function Core.inZone(pos, zone, padY)
	local rel = zone.CFrame:PointToObjectSpace(pos) local h = zone.Size / 2
	return math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + (padY or 0) and math.abs(rel.Z) <= h.Z
end
-- Phòng theo các Part vùng (Zones): trả về tên Part đầu tiên chứa vị trí
function Core.zoneRoom(zones, list, pos, default)
	for _, r in ipairs(list) do local z = zones:FindFirstChild(r) if z and Core.inZone(pos, z, 4) then return r end end
	return default or "Hall"
end

-- ===== TỈNH TÁO =====
function Core.maxSan(p) local r = Core.ROLE[p:GetAttribute("Role") or ""] return r and r.max or 100 end
function Core.addSanity(p, d, cap)
	if p:GetAttribute("Dreaming") or not p:GetAttribute("Sanity") then return end
	local s = p:GetAttribute("Sanity") local m = Core.maxSan(p)
	if d > 0 then local c = math.min(m, cap or m) if s >= c then return end s = math.min(c, s + d)
	else
		-- Bài Ru: trong lúc được ru, mọi sát thương chỉ còn một nửa
		if (p:GetAttribute("LullUntil") or 0) > workspace:GetServerTimeNow() then d = d * 0.5 end
		s = math.max(0, s + d)
	end
	p:SetAttribute("Sanity", s)
	if s <= 0 then p:SetAttribute("Dreaming", true) end
end
-- Tỉnh táo cơ bản mỗi tick: sáng hồi / tối rút, đứng gần đồng đội, hào quang Chữa Lành
-- C cần: DARK_DRAIN, LIGHT_HEAL, LIGHT_CAP, NEAR_HEAL, NEAR_CAP, NEAR_RANGE, HEALER_AURA, HEALER_RANGE
function Core.tickSanity(p, plist, lit, C, dt)
	local pos = Core.hrp(p).Position
	local near = false
	for _, o in ipairs(plist) do
		if o ~= p and Core.alive(o) then
			local d = (Core.hrp(o).Position - pos).Magnitude
			if d <= C.NEAR_RANGE then near = true end
			if o:GetAttribute("Role") == "Healer" and d <= C.HEALER_RANGE then Core.addSanity(p, C.HEALER_AURA * dt) end
		end
	end
	-- Không còn trừ Tỉnh táo theo thời gian: bóng tối không rút nữa, ánh sáng vẫn hồi
	if lit then Core.addSanity(p, C.LIGHT_HEAL * dt, C.LIGHT_CAP) end
	if near then Core.addSanity(p, C.NEAR_HEAL * dt, C.NEAR_CAP) end
end

-- ===== PHẠT LUẬT =====
-- o: prefix, penalty, blocked(p) -> true thì bỏ qua, notify(msg, p), after(p) sau khi phạt
Core.EXTRA_PENALTY = 5 -- cộng thêm vào MỌI lần phạm luật (chỉnh độ khó ở đây)
function Core.newRules(o)
	local cd = {}
	local say = o.notify or Core.notify
	return function(p, msg, pen)
		if (o.blocked and o.blocked(p)) or not Core.alive(p) then return end
		if os.clock() < (cd[p] or 0) then return end
		cd[p] = os.clock() + 1.5
		if (p:GetAttribute("CalmUntil") or 0) > Core.now() then
			p:SetAttribute("CalmUntil", 0)
			say("🛡 Bài Ru che chở bạn khỏi 1 lần phạt: " .. msg, p) return
		end
		pen = (pen or o.penalty or 8) + Core.EXTRA_PENALTY -- mọi lần phạm luật nặng thêm
		local h = Core.bondedHealer(p)
		if h then
			local half = math.floor(pen / 2 + 0.5)
			Core.addSanity(h, -half) pen = pen - half
			say("🧵 Bạn gánh hộ " .. p.Name .. " (−" .. half .. " Tỉnh táo)", h)
		end
		Core.addSanity(p, -pen)
		say((o.prefix or "⚠ ") .. msg .. " (−" .. pen .. " Tỉnh táo)", p)
		p:SetAttribute("Violations", (p:GetAttribute("Violations") or 0) + 1)
		if Core.log then Core.log("violate", p, msg, pen) end
		if o.after then o.after(p) end
	end
end

-- ===== PROMPT / HIỆN-ẨN =====
function Core.newPrompter(canUse)
	return function(part, action, obj, hold, fn, key)
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = action pp.ObjectText = obj or "" pp.HoldDuration = hold or 0
		pp.MaxActivationDistance = 10 pp.RequiresLineOfSight = false pp.ClickablePrompt = false pp.Parent = part
		if key then pp.KeyboardKeyCode = key end
		local run = function(p) if Core.alive(p) and canUse(p) then fn(p, pp) end end
		pp.Triggered:Connect(run)
		Core.promptFns[pp] = run
		return pp
	end
end
function Core.en(part, on) for _, pp in ipairs(part:GetChildren()) do if pp:IsA("ProximityPrompt") then pp.Enabled = on end end end
function Core.show(part, on, tr) part.Transparency = on and (tr or 0) or 1 Core.en(part, on) end
-- Bong bóng thoại: tìm BillboardGui "Speech" bất kỳ trong model
function Core.say(model, txt, dur)
	local gui = model:FindFirstChild("Speech", true) if not gui then return end
	local l = gui.Bubble.Text l.Text = txt gui.Enabled = true
	task.delay(dur or 3, function() if l.Text == txt then l.Text = "" gui.Enabled = false end end)
end
function Core.setGhost(p, on)
	local c = p.Character if not c then return end
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Transparency = on and 0.75 or 0 end end
	local hum = c:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = on and 22 or 16 end
end
function Core.freeze(p, sec)
	if p:GetAttribute("Role") == "Anchor" then return end -- nội tại Chân Neo
	local c = p.Character local hum = c and c:FindFirstChildOfClass("Humanoid") if not hum then return end
	hum.WalkSpeed = 0 hum.JumpPower = 0
	task.delay(sec, function() if hum.Parent then hum.WalkSpeed = p:GetAttribute("Dreaming") and 22 or 16 hum.JumpPower = 50 end end)
end

-- ===== NHẬT KÝ PLAYTEST =====
-- In ra Output (Studio) / Developer Console F9 → tab Server (game thật) với tiền tố [PLAYTEST]
local LOG = {}
local runStart = os.clock()
function Core.log(ev, p, a, b)
	local e = {t = os.clock(), ev = ev, p = p and p.Name or nil, a = a, b = b, lv = Core.current}
	table.insert(LOG, e)
	if #LOG > 3000 then table.remove(LOG, 1) end
	if ev == "start" then runStart = e.t end
	local line = string.format("[PLAYTEST] %6.1fs T%s %s %s %s %s", e.t - runStart, tostring(e.lv or "-"), ev, e.p or "", tostring(a or ""), tostring(b or ""))
	print(line)
end
function Core.summary(n)
	local from = 0
	for i = #LOG, 1, -1 do if LOG[i].ev == "start" and LOG[i].a == n then from = i break end end
	if from == 0 then return "(chưa có dữ liệu)" end
	local t0 = LOG[from].t
	local phases, viol, dreams, skills, lastPh, lastT = {}, {}, {}, {}, nil, t0
	local rules = {}
	for i = from, #LOG do
		local e = LOG[i]
		if e.ev == "phase" then
			if lastPh then phases[#phases + 1] = string.format("%s %ds", lastPh, math.floor(e.t - lastT)) end
			lastPh = tostring(e.a):match(":(.+)$") lastT = e.t
		elseif e.ev == "violate" then
			viol[e.p] = (viol[e.p] or 0) + 1
			local key = tostring(e.a):match("^(.-) —") or tostring(e.a):sub(1, 30)
			rules[key] = (rules[key] or 0) + 1
		elseif e.ev == "dream" then dreams[e.p] = (dreams[e.p] or 0) + 1
		elseif e.ev == "skill" then skills[e.p] = (skills[e.p] or 0) + 1 end
	end
	local function kv(t) local o = {} for k, v in pairs(t) do table.insert(o, tostring(k) .. "=" .. v) end return #o > 0 and table.concat(o, ", ") or "0" end
	return string.format("Tầng %d · tổng %ds\n  Giai đoạn: %s\n  Phạm luật: %s\n  Luật hay bị phạm: %s\n  Hòa mộng: %s\n  Dùng kỹ năng: %s",
		n, math.floor(os.clock() - t0), table.concat(phases, " → "), kv(viol), kv(rules), kv(dreams), kv(skills))
end
function Core.dumpLog() return Core.summary(Core.current or 1) end

-- ===== ĐỒ CẦM TAY =====
function Core.hasTool(p, name) return (p.Backpack and p.Backpack:FindFirstChild(name)) or (p.Character and p.Character:FindFirstChild(name)) end
function Core.giveTool(p, name, tip, size, color, onActivate)
	local have = Core.hasTool(p, name) if have then return have end
	local t = Instance.new("Tool") t.Name = name t.ToolTip = tip t.CanBeDropped = false
	local h = Instance.new("Part") h.Name = "Handle" h.Size = size h.Color = color h.CanCollide = false h.Massless = true h.Parent = t
	if onActivate then t.Activated:Connect(function() onActivate(p, t) end) end
	t.Parent = p.Backpack
	return t
end
function Core.removeTool(p, name) local t = Core.hasTool(p, name) if t then t:Destroy() end end
function Core.removeTools(p, names) for _, n in ipairs(names) do Core.removeTool(p, n) end end
-- Đồ xếp chồng (1 ô trên thanh đồ, tên "Tên ×N")
-- def: label, tip(n), size, color | handle(tool)->Part, init(tool), onUse(p)->false nếu không tiêu hao, alwaysCount
function Core.findStack(p, key)
	for _, c in ipairs({p.Backpack, p.Character}) do
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t:GetAttribute("StackKey") == key then return t end end end
	end
end
function Core.stackCount(p, key) local t = Core.findStack(p, key) return t and (t:GetAttribute("Count") or 0) or 0 end
function Core.setStack(p, key, n, def)
	local t = Core.findStack(p, key)
	if n <= 0 then if t then t:Destroy() end return end
	if not t then
		t = Instance.new("Tool") t.CanBeDropped = false t:SetAttribute("StackKey", key)
		if def.handle then def.handle(t) else
			local h = Instance.new("Part") h.Name = "Handle" h.Size = def.size or Vector3.new(1, 1, 1) h.Color = def.color or Color3.new(1, 1, 1)
			h.CanCollide = false h.Massless = true h.Parent = t
		end
		if def.init then def.init(t) end
		if def.onUse then
			t.Activated:Connect(function()
				if t.Parent ~= p.Character or not Core.alive(p) then return end
				if def.onUse(p) ~= false then Core.setStack(p, key, Core.stackCount(p, key) - 1, def) end
			end)
		end
		t.Parent = p.Backpack
	end
	t:SetAttribute("Count", n)
	t.Name = (n > 1 or def.alwaysCount) and (def.label .. " ×" .. n) or def.label
	t.ToolTip = def.tip and def.tip(n) or def.label
end

-- ===== CỬA (F) =====
-- o: canUse(p), check(p, door)->thông báo nếu cấm mở, onToggle(p, door), lockedMsg, dist
function Core.wireDoors(folder, o)
	o = o or {}
	local ctl = {locked = false, list = {}}
	for _, m in ipairs(folder:GetChildren()) do
		local hinge = m.Hinge.Value
		local rel = hinge:ToObjectSpace(m:GetPivot())
		local openH = hinge * CFrame.Angles(0, math.rad(-95), 0)
		local open, busy = false, false
		local pp = Instance.new("ProximityPrompt") pp.ActionText = "Mở cửa" pp.ObjectText = "Cửa" pp.KeyboardKeyCode = Enum.KeyCode.F
		pp.MaxActivationDistance = o.dist or 10 pp.RequiresLineOfSight = false pp.ClickablePrompt = false pp.Parent = m.Panel
		table.insert(ctl.list, function(v) open = v busy = false m:PivotTo((v and openH or hinge) * rel) pp.ActionText = v and "Đóng cửa" or "Mở cửa" end)
		pp.Triggered:Connect(function(p)
			if p:GetAttribute("Dreaming") or busy then return end
			if o.canUse and not o.canUse(p) then return end
			if ctl.locked then Core.notify(o.lockedMsg or "Cửa đã bị khóa chặt...", p) return end
			if o.check then local msg = o.check(p, m) if msg then Core.notify(msg, p) return end end
			busy = true open = not open
			pcall(function() m.Panel.Creak:Play() end)
			if o.onToggle then o.onToggle(p, m) end
			local from, to = open and hinge or openH, open and openH or hinge
			for i = 1, 10 do m:PivotTo(from:Lerp(to, i / 10) * rel) task.wait(0.02) end
			pp.ActionText = open and "Đóng cửa" or "Mở cửa" busy = false
		end)
	end
	function ctl.setAll(v) for _, f in ipairs(ctl.list) do f(v) end end
	return ctl
end

-- ===== CỔNG THOÁT =====
-- o: gate, S, G, doors, players(), alive(p), escapeTime, gateTime, safe(p), target()->CFrame,
--    openMsg, trappedMsg, closedMsg, onOpen(), blocked(), notify(msg, who)
function Core.newEscape(o)
	local E = {openAt = nil, closed = false}
	local say = o.notify or Core.notify
	local gate = o.gate
	function E.reset()
		E.openAt = nil E.closed = false
		gate.Material = Enum.Material.Glass gate.Color = Color3.fromRGB(30, 30, 40) gate.CanCollide = true gate.Transparency = 0.3
	end
	function E.open()
		o.S("Phase", "Gate") E.openAt = os.clock() E.closed = false
		o.S("EscapeDeadline", Core.now() + o.escapeTime)
		o.doors.locked = false o.doors.setAll(true)
		gate.Material = Enum.Material.Neon gate.Color = Color3.fromRGB(140, 255, 200) gate.CanCollide = false gate.Transparency = 0.2
		if o.onOpen then o.onOpen() end
		if Core.log then Core.log("gate") end
		say(o.openMsg)
	end
	gate.Touched:Connect(function(hit)
		if o.G("Phase") ~= "Gate" or (o.blocked and o.blocked()) then return end
		local p = Players:GetPlayerFromCharacter(hit.Parent)
		if p and o.alive(p) and not p:GetAttribute("Escaped") then
			p:SetAttribute("Escaped", true)
			local r = Core.hrp(p) local cf = o.target and o.target()
			if r and cf then r.CFrame = cf * CFrame.new(0, 5, 0) end
			say(p.Name .. " đã bước qua Cổng!")
		end
	end)
	function E.extend(sec) if E.openAt and not E.closed then E.openAt += sec o.S("EscapeDeadline", (o.G("EscapeDeadline") or Core.now()) + sec) return true end return false end
	-- gọi mỗi tick khi Phase == "Gate": trả về true (thắng), false (thua) hoặc nil
	function E.tick()
		if o.G("Phase") ~= "Gate" or not E.openAt then return nil end
		local el = os.clock() - E.openAt
		local plist = o.players()
		if not E.closed and el >= o.escapeTime then
			E.closed = true o.doors.setAll(false) o.doors.locked = true
			for _, p in ipairs(plist) do
				if o.alive(p) and not p:GetAttribute("Escaped") and not o.safe(p) then
					p:SetAttribute("Sanity", 0) p:SetAttribute("Dreaming", true)
					say(o.trappedMsg, p)
				end
			end
			if o.closedMsg then say(o.closedMsg) end
		end
		local esc, left = 0, 0
		for _, p in ipairs(plist) do if p:GetAttribute("Escaped") then esc += 1 elseif o.alive(p) then left += 1 end end
		if esc > 0 and left == 0 then return true end
		if el > o.gateTime then return esc > 0 end
		return nil
	end
	return E
end

-- ===== TRẠNG THÁI PHÒNG: Neo (dừng thời gian) & Ru (dỗ dịu) =====
-- Lưu trên Folder trạng thái của tầng: Freeze_<phòng>, Lull_<phòng> = thời điểm hết hiệu lực
function Core.isFrozen(G, room) return (G("Freeze_" .. room) or 0) > Core.now() end
function Core.isLulled(G, room) return (G("Lull_" .. room) or 0) > Core.now() end
-- chờ "sec" giây nhưng KHÔNG tính thời gian phòng đang bị Neo; dời các mốc giờ (attrs) theo
function Core.waitUnfrozen(S, G, room, sec, attrs)
	local t = 0
	while t < sec do
		local dt = task.wait(0.1)
		if Core.isFrozen(G, room) then
			if attrs then for _, a in ipairs(attrs) do local v = G(a) if type(v) == "number" and v > 0 then S(a, v + dt) end end end
		else t += dt end
	end
end
-- Nội tại Linh Cảm của Bói Toán: báo tên phòng vừa có dấu hiệu xuất hiện
function Core.sense(level, roomLabel)
	do return end -- Linh Cảm đã bỏ (làm mất giá trị của cuốn nhật ký); giữ hàm để không phải sửa chỗ gọi
	for _, p in ipairs(Core.playersIn(level)) do
		if p:GetAttribute("Role") == "Diviner" then Remotes.Notify:FireClient(p, "__LINHCAM__|" .. roomLabel) end
	end
end
-- Sợi Chỉ Đỏ
function Core.bondedHealer(p)
	for _, h in ipairs(Core.playersIn(Core.level(p))) do
		if h ~= p and h:GetAttribute("Role") == "Healer" and h:GetAttribute("BondWith") == p.Name and Core.alive(h) then return h end
	end
end
local bondNear = {}
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, h in ipairs(Players:GetPlayers()) do
			if h:GetAttribute("Role") == "Healer" and Core.level(h) and Core.alive(h) then
				local best
				for _, o in ipairs(Core.playersIn(Core.level(h))) do
					if o ~= h and Core.alive(o) and (Core.hrp(o).Position - Core.hrp(h).Position).Magnitude < 6 then best = o end
				end
				if best and h:GetAttribute("BondWith") ~= best.Name then
					bondNear[h] = (bondNear[h] == nil or bondNear[h].p ~= best) and {p = best, t = 0} or bondNear[h]
					bondNear[h].t += 0.5
					if bondNear[h].t >= 2 then
						h:SetAttribute("BondWith", best.Name) bondNear[h] = nil
						Core.notify("🧵 Sợi Chỉ Đỏ nối bạn với " .. best.Name .. ".", h)
						Core.notify("🧵 " .. h.Name .. " đã nối Sợi Chỉ Đỏ với bạn — bạn ấy sẽ gánh hộ một nửa mỗi lần bạn bị phạt.", best)
					end
				else bondNear[h] = nil end
			end
		end
	end
end)

-- ===== KỸ NĂNG 4 VAI (chỉ tác động lên PHÒNG đang đứng lúc dùng) =====
-- def.skill: roomAttr, allowed(p), safeRooms = {Hall=true}, onSeer(p, room), onLull(p, room), divine(p, room) -> văn bản quẻ
function Core.castSkill(p, def)
	local sk = def.skill if not sk then return end
	if not Core.alive(p) or (def.active and not def.active()) then return end
	local now = Core.now()
	if now < (p:GetAttribute("SkillReadyAt") or 0) then return end
	if sk.allowed then local e = sk.allowed(p) if e then if e ~= "" then Core.notify(e, p) end return end end
	local role = p:GetAttribute("Role") local R = Core.ROLE[role or ""]
	if not R or not R.enabled then return end
	local room = p:GetAttribute(sk.roomAttr) or "Hall"
	local safe = sk.safeRooms and sk.safeRooms[room]
	local mates = Core.playersIn(Core.level(p))
	local S, G = def.S, def.G
	local function spend() Core.addSanity(p, -R.cost) p:SetAttribute("SkillReadyAt", now + R.cd) end
	if role == "Seer" then
		spend()
		p:SetAttribute("TrueSightUntil", now + R.dur) p:SetAttribute("SightRoom", room)
		-- Đánh Dấu: cả nhóm cùng thấy những gì Thấu Thị soi được (thêm 15 giây)
		if S then S("SeerMarkRoom", room) S("SeerMarkUntil", now + R.dur + R.mark) end
		if sk.onSeer then sk.onSeer(p, room) end
		Core.notify("👁 " .. p.Name .. " Nhìn Xuyên (" .. (sk.roomName and sk.roomName[room] or room) .. ") — cả nhóm thấy những gì bạn ấy soi được.", mates)
	elseif role == "Healer" then
		spend()
		local healed, revived = {}, {}
		for _, o in ipairs(mates) do
			if o:GetAttribute(sk.roomAttr) == room and Core.hrp(o) then
				if o:GetAttribute("Dreaming") then
					o:SetAttribute("Dreaming", false) o:SetAttribute("Sanity", R.revive) table.insert(revived, o.Name)
				else Core.addSanity(o, R.heal) if o ~= p then table.insert(healed, o.Name) end end
				o:SetAttribute("CalmUntil", now + R.calm)
				o:SetAttribute("LullUntil", now + R.lull) -- sát thương giảm một nửa trong 3 giây
			end
		end
		local msg = p.Name .. " hát Bài Ru ♪ — +" .. R.heal .. " & Bình tâm " .. R.calm .. "s cho mọi người trong phòng"
		if #revived > 0 then msg = msg .. ", kéo " .. table.concat(revived, ", ") .. " trở lại" end
		msg = msg .. ". Sát thương giảm một nửa trong " .. R.lull .. " giây."
		Core.notify(msg, mates)
	elseif role == "Anchor" then
		-- lúc Cổng mở: CHỐNG CỬA (mỗi tầng 1 lần)
		if G and G("Phase") == "Gate" and def.escape then
			if p:GetAttribute("DoorHeld") then Core.notify("Bạn đã chống cửa một lần ở tầng này rồi.", p) return end
			if def.escape.extend(R.door) then
				spend() p:SetAttribute("DoorHeld", true)
				Core.notify("⚓ " .. p.Name .. " CHỐNG CỬA — cửa đóng chậm thêm " .. R.door .. " giây!", mates)
			end
			return
		end
		if safe then Core.notify("Nơi này không có gì để neo lại. Hãy cắm Neo trong một phòng có luật.", p) return end
		spend()
		if S then S("Freeze_" .. room, now + R.dur) end
		Core.notify("⚓ " .. p.Name .. " CẮM NEO — mọi thứ trong phòng đứng yên " .. R.dur .. " giây.", mates)
	elseif role == "Diviner" then
		local text = sk.divine and sk.divine(p, room)
		if not text then Core.notify("Nơi này không có quẻ nào để gieo.", p) return end
		spend()
		Remotes.Notify:FireClient(p, "__QUE__|" .. (sk.roomName and sk.roomName[room] or room) .. "|" .. text)
	end
	if Core.log then Core.log("skill", p, role, room) end
end
Remotes.UseSkill.OnServerEvent:Connect(function(p, action)
	if action ~= "Skill" then return end
	local def = Core.levels[Core.level(p) or 0]
	if def then Core.castSkill(p, def) end
end)

-- ===== HÒA MỘNG (dùng chung) =====
local function onDreamChanged(p)
	local lv = Core.level(p) local def = Core.levels[lv or 0]
	if not p:GetAttribute("Dreaming") then Core.setGhost(p, false) return end
	Core.setGhost(p, true)
	if not def or (def.active and not def.active()) then return end
	if Core.log then Core.log("dream", p) end
	if def.onDream then def.onDream(p) end
	local mates = Core.playersIn(lv)
	Core.notify(p.Name .. " đã HÒA MỘNG... Chữa Lành hãy đến gần và hát Bài Ru để kéo bạn ấy về!", mates)
	local r = Core.hrp(p)
	for _, o in ipairs(mates) do
		if r and o ~= p and Core.alive(o) and (Core.hrp(o).Position - r.Position).Magnitude <= 30 then Core.addSanity(o, -(def.witness or 10)) end
	end
end
local function hookPlayer(p)
	p:GetAttributeChangedSignal("Dreaming"):Connect(function() onDreamChanged(p) end)
	if Core.current then p:SetAttribute("Level", Core.current) end
	p.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		Core.setGhost(p, p:GetAttribute("Dreaming"))
		local hum = char:WaitForChild("Humanoid", 5) if not hum then return end
		hum.Died:Connect(function()
			local def = Core.levels[Core.level(p) or 0]
			if def and (not def.active or def.active()) and not p:GetAttribute("Dreaming") then
				p:SetAttribute("Sanity", 0) p:SetAttribute("Dreaming", true)
			end
		end)
	end)
end
Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end

-- ===== ĐĂNG KÝ TẦNG / CHUYỂN TẦNG =====
function Core.register(n, def) def.n = n Core.levels[n] = def end
Core.lobbyFn = function() end -- GameManager gán hàm vào sảnh
local function sleepAll(except)
	for k, d in pairs(Core.levels) do if k ~= except and d.sleep then d.sleep() end end
end
function Core.prepPlayer(p, n)
	p:SetAttribute("Level", n)
	p:SetAttribute("Dreaming", false) p:SetAttribute("Escaped", false) p:SetAttribute("Dancing", false)
	p:SetAttribute("Sanity", Core.maxSan(p)) p:SetAttribute("SkillReadyAt", 0)
	p:SetAttribute("CalmUntil", 0) p:SetAttribute("TrueSightUntil", 0) p:SetAttribute("SightRoom", nil) p:SetAttribute("DoorHeld", nil) p:SetAttribute("BondWith", nil)
	for _, d in pairs(Core.levels) do if d.tools then Core.removeTools(p, d.tools) end end
	Core.setGhost(p, false)
end
function Core.startLevel(n)
	local def = Core.levels[n]
	if not def then Core.toLobby() return end
	sleepAll(n)
	Core.current = n
	RS:SetAttribute("CurrentLevel", n)
	Core.fillRoles()
	for _, p in ipairs(Players:GetPlayers()) do Core.prepPlayer(p, n) end
	for _, h in ipairs(Players:GetPlayers()) do
		if h:GetAttribute("Role") == "Healer" then
			for _, o in ipairs(Players:GetPlayers()) do if o ~= h then h:SetAttribute("BondWith", o.Name) break end end
		end
	end
	-- xóa trạng thái Neo/Ru/Đánh dấu còn sót của lần chơi trước
	if def.state then for k in pairs(def.state:GetAttributes()) do if k:match("^Freeze_") or k:match("^Lull_") or k:match("^SeerMark") then def.state:SetAttribute(k, nil) end end end
	if Core.log then Core.log("start", nil, n) end
	def.start()
end
function Core.toLobby()
	sleepAll(nil)
	Core.current = nil
	RS:SetAttribute("CurrentLevel", 0)
	for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("Level", nil) end
	Core.lobbyFn()
end
-- gọi sau màn hình thắng/thua của tầng n
function Core.finishLevel(n, win)
	if Core.log then Core.log(win and "win" or "lose", nil, n) end
	print("[PLAYTEST] ===== KẾT QUẢ " .. (win and "THẮNG" or "THUA") .. " =====\n" .. Core.summary(n))
	local def = Core.levels[n]
	if win then
		if Core.levels[n + 1] then Core.startLevel(n + 1)
		elseif Core.testLevel() == n then Core.startLevel(n)
		else Core.toLobby() end
	else
		if def and def.loseRestart then Core.startLevel(n) else Core.toLobby() end
	end
end
-- Studio: thuộc tính Workspace "TestLevel" (số tầng) — hoặc TestLevel2 = true (cũ)
function Core.testLevel()
	if not RunService:IsStudio() then return nil end
	local n = workspace:GetAttribute("TestLevel")
	if type(n) == "number" and n > 0 then return n end
	if workspace:GetAttribute("TestLevel2") then return 2 end
	return nil
end

-- ===== DEBUG (chỉ trong Studio): ServerStorage.CoreDebug:Invoke(cmd, ...) =====
if RunService:IsStudio() then
	local SS = game:GetService("ServerStorage")
	local bf = SS:FindFirstChild("CoreDebug") or Instance.new("BindableFunction")
	bf.Name = "CoreDebug" bf.Parent = SS
	local function findPrompt(part, action)
		for _, pp in ipairs(part:GetDescendants()) do
			if pp:IsA("ProximityPrompt") and (not action or pp.ActionText:find(action, 1, true)) then return pp end
		end
	end
	bf.OnInvoke = function(cmd, a, b, c)
		if cmd == "prompt" then -- a = Part, b = tên người chơi, c = một phần ActionText
			local pp = findPrompt(a, c) if not pp then return "no prompt" end
			local fn = Core.promptFns[pp] if not fn then return "not core prompt" end
			fn(Players:FindFirstChild(b) or Players:GetPlayers()[1]) return "ok"
		elseif cmd == "start" then Core.startLevel(a) return "ok"
		elseif cmd == "lobby" then Core.toLobby() return "ok"
		elseif cmd == "current" then return Core.current
		elseif cmd == "lv" then -- a = tên lệnh debug của tầng hiện tại
			local d = Core.levels[Core.current or 0] local f = d and d.debug and d.debug[a]
			if not f then return "no cmd" end return f(b, c)
		elseif cmd == "log" then return Core.dumpLog and Core.dumpLog() or ""
		end
		return "unknown"
	end
end

return Core
