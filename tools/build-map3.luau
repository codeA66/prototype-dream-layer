-- Dựng map Tầng 3 — KHU RỪNG MÊ — ra map/DreamMap3.rbxm
-- Chạy: lune run tools/build-map3.luau
-- Đây là bản map khởi đầu (blockout). Builder có thể mở trong Studio để trang trí thêm,
-- nhưng KHÔNG đổi tên các thứ trong Interactables / Zones / Doors (code Level3Manager dùng những tên này).
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance, CFrame, Vector3, Color3, Enum = roblox.Instance, roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum
local UDim2 = roblox.UDim2

-- số ngẫu nhiên có hạt giống cố định (Lune không có Random) → mỗi lần chạy ra cùng một map
local seed = 3
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648 return seed / 2147483648 end
local rng = {
	NextNumber = function(_, a, b) if not a then return rnd() end return a + (b - a) * rnd() end,
	NextInteger = function(_, a, b) return a + math.floor(rnd() * (b - a + 1)) end,
}
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local map = Instance.new("Folder") map.Name = "DreamMap3"
local function folder(name, parent, class)
	local f = Instance.new(class or "Folder") f.Name = name f.Parent = parent or map return f
end
local GEO, PROPS, ZONES, DOORS, IX = folder("Geometry"), folder("Props"), folder("Zones"), folder("Doors"), folder("Interactables")
local LIGHTS = folder("Lights")

local function part(o)
	local p = Instance.new("Part")
	p.Name = o.name or "Part"
	p.Anchored = true
	p.Size = o.size or Vector3.new(4, 1, 4)
	p.CFrame = o.cf or CFrame.new(o.pos or Vector3.new())
	p.Material = o.mat or Enum.Material.SmoothPlastic
	p.Color = o.color or rgb(90, 90, 90)
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if o.shape then p.Shape = o.shape end
	if o.tr then p.Transparency = o.tr end
	if o.collide == false then p.CanCollide = false end
	if o.noShadow then p.CastShadow = false end
	if o.touch == false then p.CanTouch = false end
	if o.query == false then p.CanQuery = false end
	p.Parent = o.parent or GEO
	return p
end
local function light(p, range, bright, color, shadows)
	local l = Instance.new("PointLight") l.Range = range l.Brightness = bright l.Color = color l.Shadows = shadows == true l.Parent = p return l
end
local function sound(parent, name, id, vol, looped, speed)
	local s = Instance.new("Sound") s.Name = name s.SoundId = id s.Volume = vol or 0.7 s.Looped = looped == true
	s.PlaybackSpeed = speed or 1 s.RollOffMaxDistance = 90 s.Parent = parent return s
end
local function label(p, face, text, color, font)
	local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 40
	g.LightInfluence = 0 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true
	t.Text = text t.TextColor3 = color or rgb(240, 230, 210) t.FontFace = roblox.Font.fromEnum(font or Enum.Font.Antique) t.Parent = g
	return t
end

local WALL_H = 26
local HEDGE = rgb(24, 38, 24)
local ROCK = rgb(52, 48, 46)

-- ===== TƯỜNG QUANH MỘT KHU (chừa lối vào) =====
-- open = { N = {{a, b}}, S = ..., E = ..., W = ... } — đoạn trống theo tọa độ thế giới
-- N = cạnh z nhỏ, S = cạnh z lớn, W = cạnh x nhỏ, E = cạnh x lớn
local function walls(cx, cz, w, d, open, mat, color, h)
	h = h or WALL_H
	local x0, x1, z0, z1 = cx - w / 2, cx + w / 2, cz - d / 2, cz + d / 2
	local function side(key, from, to, fixed, alongX)
		local gaps = (open and open[key]) or {}
		table.sort(gaps, function(a, b) return a[1] < b[1] end)
		local segs, cur = {}, from
		for _, g in ipairs(gaps) do
			if g[1] > cur then table.insert(segs, {cur, g[1]}) end
			cur = math.max(cur, g[2])
		end
		if cur < to then table.insert(segs, {cur, to}) end
		for _, s in ipairs(segs) do
			local len = s[2] - s[1] + (alongX and 0 or 0)
			local mid = (s[1] + s[2]) / 2
			local pos = alongX and Vector3.new(mid, h / 2, fixed) or Vector3.new(fixed, h / 2, mid)
			local size = alongX and Vector3.new(len + 2, h, 2) or Vector3.new(2, h, len + 2)
			part({name = "Wall", size = size, pos = pos, mat = mat or Enum.Material.LeafyGrass, color = color or HEDGE})
		end
	end
	side("N", x0, x1, z0 - 1, true)
	side("S", x0, x1, z1 + 1, true)
	side("W", z0, z1, x0 - 1, false)
	side("E", z0, z1, x1 + 1, false)
end
local function ground(name, cx, cz, w, d, mat, color)
	return part({name = name, size = Vector3.new(w, 1, d), pos = Vector3.new(cx, -0.5, cz), mat = mat or Enum.Material.Grass, color = color or rgb(34, 46, 30)})
end
local function zone(name, cx, cz, w, d)
	part({name = name, size = Vector3.new(w, 22, d), pos = Vector3.new(cx, 11, cz), tr = 1, collide = false, touch = false, query = false, parent = ZONES})
end
local function fill(pos, range, bright, color)
	local p = part({name = "FillLight", size = Vector3.new(0.2, 0.2, 0.2), pos = pos, tr = 1, collide = false, touch = false, query = false, parent = LIGHTS})
	light(p, range or 45, bright or 0.4, color or rgb(150, 170, 220))
end
-- cây trang trí
local function tree(x, z, scale, parent)
	scale = scale or 1
	local m = Instance.new("Model") m.Name = "Tree" m.Parent = parent or PROPS
	local h = rng:NextNumber(16, 24) * scale
	part({name = "Trunk", shape = Enum.PartType.Cylinder, size = Vector3.new(h, 2.4 * scale, 2.4 * scale),
		cf = CFrame.new(x, h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), mat = Enum.Material.Wood, color = rgb(52, 38, 28), parent = m})
	for i = 1, 2 do
		local r = rng:NextNumber(9, 13) * scale
		part({name = "Leaves", shape = Enum.PartType.Ball, size = Vector3.new(r, r, r),
			pos = Vector3.new(x + rng:NextNumber(-2, 2), h - 1 + i * 2.5, z + rng:NextNumber(-2, 2)),
			mat = Enum.Material.LeafyGrass, color = rgb(22 + rng:NextInteger(0, 10), 40 + rng:NextInteger(0, 14), 24), collide = false, parent = m})
	end
	return m
end
-- hàng cây sát tường bên trong một khu, bỏ qua gần các lối vào
local function treeBorder(cx, cz, w, d, avoid, count)
	local placed = 0
	for _ = 1, count * 6 do
		if placed >= count then break end
		local sideN = rng:NextInteger(1, 4)
		local x, z
		if sideN == 1 then x, z = rng:NextNumber(cx - w / 2 + 3, cx + w / 2 - 3), cz - d / 2 + rng:NextNumber(2.5, 5)
		elseif sideN == 2 then x, z = rng:NextNumber(cx - w / 2 + 3, cx + w / 2 - 3), cz + d / 2 - rng:NextNumber(2.5, 5)
		elseif sideN == 3 then x, z = cx - w / 2 + rng:NextNumber(2.5, 5), rng:NextNumber(cz - d / 2 + 3, cz + d / 2 - 3)
		else x, z = cx + w / 2 - rng:NextNumber(2.5, 5), rng:NextNumber(cz - d / 2 + 3, cz + d / 2 - 3) end
		local ok = true
		for _, a in ipairs(avoid or {}) do if (Vector3.new(x, 0, z) - Vector3.new(a[1], 0, a[2])).Magnitude < (a[3] or 12) then ok = false end end
		if ok then tree(x, z, rng:NextNumber(0.8, 1.15)) placed += 1 end
	end
end
-- cửa gỗ: Model có Panel + Hinge (CFrameValue) — LevelCore.wireDoors dùng
local function door(name, cf, width)
	local m = Instance.new("Model") m.Name = name m.Parent = DOORS
	local panel = part({name = "Panel", size = Vector3.new(width, 12, 0.6), cf = cf, mat = Enum.Material.WoodPlanks, color = rgb(74, 54, 36), parent = m})
	sound(panel, "Creak", "rbxassetid://9120839174", 0.8)
	for i = -1, 1 do
		part({name = "Plank", size = Vector3.new(width - 0.4, 0.8, 0.8), cf = cf * CFrame.new(0, i * 4, 0.3), mat = Enum.Material.Wood, color = rgb(58, 42, 28), collide = false, parent = m})
	end
	local hv = Instance.new("CFrameValue") hv.Name = "Hinge" hv.Value = cf * CFrame.new(-width / 2, 0, 0) hv.Parent = m
	m.PrimaryPart = panel
	return m
end

-- ===================================================================
-- BỐ CỤC (nhìn từ trên xuống, Bắc = z nhỏ)
--            Room1 Rừng đom đóm (0, 1300)
--                     |
--  Room3 Cây Mắt ── LOBBY Lửa trại ── Room2 Đầm sương
--   (-110, 1400)      (0, 1400)        (110, 1400)
--                   /   [Cổng]   \
--        Room4 Hang gỗ          Room5 Vườn nấm
--         (-50, 1510)            (50, 1510)
-- ===================================================================
local LOBBY = {0, 1400, 70, 70}
local R1 = {0, 1300, 70, 80}
local R2 = {110, 1400, 80, 80}
local R3 = {-110, 1400, 80, 80}
local R4 = {-50, 1510, 70, 70}
local R5 = {50, 1510, 70, 70}

-- ===== MẶT ĐẤT + TƯỜNG =====
ground("Ground_Lobby", 0, 1400, 70, 70, Enum.Material.Grass, rgb(38, 50, 32))
walls(0, 1400, 70, 70, {N = {{-6, 6}}, E = {{1394, 1406}}, W = {{1394, 1406}}, S = {{-27, -15}, {15, 27}}})
ground("Ground_Room1", 0, 1300, 70, 80) walls(0, 1300, 70, 80, {S = {{-6, 6}}})
ground("Ground_Room2", 110, 1400, 80, 80, Enum.Material.Mud, rgb(36, 40, 32)) walls(110, 1400, 80, 80, {W = {{1394, 1406}}})
ground("Ground_Room3", -110, 1400, 80, 80) walls(-110, 1400, 80, 80, {E = {{1394, 1406}}})
ground("Ground_Room4", -50, 1510, 70, 70, Enum.Material.Slate, rgb(44, 40, 38))
walls(-50, 1510, 70, 70, {N = {{-27, -15}}}, Enum.Material.Slate, ROCK, 14)
part({name = "CaveRoof", size = Vector3.new(74, 2, 74), pos = Vector3.new(-50, 15, 1510), mat = Enum.Material.Slate, color = rgb(34, 31, 30)})
-- vách hang cao hơn mái để không trèo được lên
walls(-50, 1510, 70, 70, {N = {{-27, -15}}}, Enum.Material.Rock, rgb(40, 37, 35), WALL_H)
ground("Ground_Room5", 50, 1510, 70, 70, Enum.Material.Grass, rgb(30, 36, 34)) walls(50, 1510, 70, 70, {N = {{15, 27}}})
-- lối mòn (đất)
ground("Trail_N", 0, 1352.5, 12, 25, Enum.Material.Ground, rgb(58, 46, 34)) walls(0, 1352.5, 12, 25, {N = {{-6, 6}}, S = {{-6, 6}}})
ground("Trail_E", 52.5, 1400, 35, 12, Enum.Material.Ground, rgb(58, 46, 34)) walls(52.5, 1400, 35, 12, {W = {{1394, 1406}}, E = {{1394, 1406}}})
ground("Trail_W", -52.5, 1400, 35, 12, Enum.Material.Ground, rgb(58, 46, 34)) walls(-52.5, 1400, 35, 12, {W = {{1394, 1406}}, E = {{1394, 1406}}})
ground("Trail_SW", -21, 1455, 12, 40, Enum.Material.Ground, rgb(58, 46, 34)) walls(-21, 1455, 12, 40, {N = {{-27, -15}}, S = {{-27, -15}}})
ground("Trail_SE", 21, 1455, 12, 40, Enum.Material.Ground, rgb(58, 46, 34)) walls(21, 1455, 12, 40, {N = {{15, 27}}, S = {{15, 27}}})

-- ===== VÙNG PHÒNG (Zones) =====
zone("Lobby", 0, 1400, 70, 70)
zone("Room1", 0, 1300, 70, 80)
zone("Room2", 110, 1400, 80, 80)
zone("Room3", -110, 1400, 80, 80)
zone("Room4", -50, 1510, 70, 70)
zone("Room5", 50, 1510, 70, 70)

-- ===== CỬA =====
door("Door_Room1", CFrame.new(0, 6, 1346), 12)
door("Door_Room2", CFrame.new(64, 6, 1400) * CFrame.Angles(0, math.rad(90), 0), 12)
door("Door_Room3", CFrame.new(-64, 6, 1400) * CFrame.Angles(0, math.rad(-90), 0), 12)
door("Door_Room4", CFrame.new(-21, 6, 1468), 12)
door("Door_Room5", CFrame.new(21, 6, 1468), 12)

-- ===== ÁNH SÁNG NỀN (trăng) =====
-- mỗi khu có 1 đèn giữa + 4 đèn góc để không tối om, nhưng vẫn giữ không khí đêm
for _, a in ipairs({LOBBY, R1, R2, R3, R5}) do
	fill(Vector3.new(a[1], 18, a[2]), 60, 0.9)
	for _, c in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do fill(Vector3.new(a[1] + c[1] * a[3] / 4, 14, a[2] + c[2] * a[4] / 4), 34, 0.55) end
end
fill(Vector3.new(-50, 10, 1510), 45, 0.45, rgb(130, 120, 160))
for _, c in ipairs({{-1, -1}, {1, -1}, {-1, 1}, {1, 1}}) do fill(Vector3.new(-50 + c[1] * 17, 9, 1510 + c[2] * 17), 26, 0.3, rgb(130, 120, 160)) end
for _, t in ipairs({{0, 1352}, {52, 1400}, {-52, 1400}, {-21, 1455}, {21, 1455}}) do fill(Vector3.new(t[1], 12, t[2]), 30, 0.7) end

-- ===== ĐÈN LỒNG + BIỂN CHỈ ĐƯỜNG ở mỗi lối ra khỏi Lửa trại =====
local function lantern(x, z, text)
	local m = Instance.new("Model") m.Name = "Lantern" m.Parent = PROPS
	part({name = "Post", size = Vector3.new(0.6, 8, 0.6), pos = Vector3.new(x, 4, z), mat = Enum.Material.Wood, color = rgb(60, 44, 30), parent = m})
	local lamp = part({name = "Lamp", size = Vector3.new(1.2, 1.6, 1.2), pos = Vector3.new(x, 8.6, z), mat = Enum.Material.Neon, color = rgb(255, 190, 110), collide = false, parent = m})
	light(lamp, 26, 1.6, rgb(255, 180, 110), true)
	if text then
		local sign = part({name = "Sign", size = Vector3.new(6, 1.6, 0.3), pos = Vector3.new(x, 6.4, z), mat = Enum.Material.WoodPlanks, color = rgb(90, 66, 44), collide = false, parent = m})
		label(sign, Enum.NormalId.Front, text, rgb(255, 235, 200), Enum.Font.GothamBold)
		label(sign, Enum.NormalId.Back, text, rgb(255, 235, 200), Enum.Font.GothamBold)
		-- biển luôn quay mặt vào Lửa trại
		sign.CFrame = CFrame.lookAt(Vector3.new(x, 6.4, z), Vector3.new(0, 6.4, 1400))
	end
end
lantern(-8, 1368, "↑ RỪNG ĐOM ĐÓM") lantern(8, 1368, nil)
lantern(32, 1390, "→ ĐẦM SƯƠNG MÙ") lantern(32, 1410, nil)
lantern(-32, 1390, "← CÂY CỔ THỤ") lantern(-32, 1410, nil)
lantern(-29, 1432, "↓ HANG GỖ MỤC") lantern(29, 1432, "↓ VƯỜN NẤM")
-- đèn lồng dọc lối mòn, ngay trước mỗi cửa gỗ
for _, t in ipairs({{-5, 1358}, {40, 1395}, {-40, 1395}, {-26, 1446}, {26, 1446}}) do lantern(t[1], t[2], nil) end

-- ===================================================================
-- LOBBY — LỬA TRẠI (an toàn)
-- ===================================================================
treeBorder(0, 1400, 70, 70, {{0, 1365}, {35, 1400}, {-35, 1400}, {-21, 1435}, {21, 1435}, {0, 1435}}, 10)
local fire = part({name = "Campfire", size = Vector3.new(4, 1, 4), pos = Vector3.new(0, 0.5, 1400), mat = Enum.Material.Slate, color = rgb(40, 36, 34), parent = IX})
local fx = Instance.new("Fire") fx.Heat = 9 fx.Size = 6 fx.Color = rgb(255, 150, 60) fx.SecondaryColor = rgb(255, 60, 20) fx.Parent = fire
light(fire, 34, 2.2, rgb(255, 160, 90), true)
for i = 0, 5 do
	local a = i / 6 * math.pi * 2
	part({name = "Stone", size = Vector3.new(1.6, 1, 1.6), pos = Vector3.new(math.cos(a) * 3, 0.5, 1400 + math.sin(a) * 3), mat = Enum.Material.Slate, color = rgb(80, 76, 72), parent = PROPS})
end
for i = 0, 3 do -- khúc gỗ ngồi quanh lửa
	local a = i / 4 * math.pi * 2 + 0.4
	part({name = "LogSeat", shape = Enum.PartType.Cylinder, size = Vector3.new(6, 1.6, 1.6),
		cf = CFrame.new(math.cos(a) * 9, 0.8, 1400 + math.sin(a) * 9) * CFrame.Angles(0, -a + math.rad(90), 0),
		mat = Enum.Material.Wood, color = rgb(70, 50, 34), parent = PROPS})
end
-- lều bỏ hoang
part({name = "Tent", size = Vector3.new(10, 7, 8), cf = CFrame.new(20, 3.5, 1378) * CFrame.Angles(0, math.rad(20), 0), mat = Enum.Material.Fabric, color = rgb(120, 90, 50), parent = PROPS})
local function stump(name, pos, parent)
	return part({name = name, shape = Enum.PartType.Cylinder, size = Vector3.new(2.8, 3, 3), cf = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		mat = Enum.Material.Wood, color = rgb(80, 58, 40), parent = parent or PROPS})
end
stump("Stump", Vector3.new(8, 1.4, 1390))
part({name = "RulesPaper", size = Vector3.new(1.4, 0.05, 1.9), pos = Vector3.new(8, 2.85, 1390), color = rgb(236, 228, 205), parent = IX})
stump("Stump", Vector3.new(-8, 1.4, 1390))
part({name = "RangerLog", size = Vector3.new(1.3, 0.3, 1.8), pos = Vector3.new(-8, 3, 1390), mat = Enum.Material.Fabric, color = rgb(60, 80, 50), parent = IX})
-- Spawn
part({name = "Spawn3", size = Vector3.new(8, 1, 8), pos = Vector3.new(0, 0.2, 1386), tr = 1, collide = false, touch = false, parent = IX})
-- Bệ Neo
local altar = part({name = "AnchorAltar", size = Vector3.new(3.6, 3.6, 3.6), pos = Vector3.new(0, 1.8, 1420), mat = Enum.Material.Marble, color = rgb(170, 180, 190), parent = IX})
light(altar, 10, 0.6, rgb(160, 200, 255))
-- Cổng gỗ cũ (cuối lối mòn sau Lobby, trên tường phía nam)
part({name = "GateArchL", size = Vector3.new(1.5, 18, 1.5), pos = Vector3.new(-7, 9, 1433.5), mat = Enum.Material.Wood, color = rgb(60, 44, 30), parent = PROPS})
part({name = "GateArchR", size = Vector3.new(1.5, 18, 1.5), pos = Vector3.new(7, 9, 1433.5), mat = Enum.Material.Wood, color = rgb(60, 44, 30), parent = PROPS})
part({name = "GateArchTop", size = Vector3.new(16, 1.5, 1.5), pos = Vector3.new(0, 18, 1433.5), mat = Enum.Material.Wood, color = rgb(60, 44, 30), parent = PROPS})
part({name = "Gate", size = Vector3.new(12, 16, 1), pos = Vector3.new(0, 8, 1433.5), mat = Enum.Material.Glass, color = rgb(30, 30, 40), tr = 0.3, parent = IX})
-- Phiến đá Truy Nguyên + 4 hòn đá lựa chọn
local tablet = part({name = "PuzzleTablet", size = Vector3.new(1, 6, 8), pos = Vector3.new(-30, 3, 1405), mat = Enum.Material.Slate, color = rgb(70, 70, 76), parent = PROPS})
label(tablet, Enum.NormalId.Right, "THỨ GÌ KHIẾN CẬU BÉ CỨ ĐI VÒNG QUANH?", rgb(220, 210, 180))
for i = 1, 4 do
	local st = part({name = "Puzzle" .. i, size = Vector3.new(2.4, 1.6, 2.4), pos = Vector3.new(-25, 0.8, 1398 + (i - 1) * 4.5), mat = Enum.Material.Slate, color = rgb(90, 88, 84), parent = IX})
	label(st, Enum.NormalId.Top, "?", rgb(240, 225, 190), Enum.Font.GothamBold)
end

-- ===================================================================
-- ROOM1 — RỪNG ĐOM ĐÓM
-- ===================================================================
treeBorder(0, 1300, 70, 80, {{0, 1340}}, 16)
local path1 = folder("Room1Path", IX, "Model")
local PATH1 = {Vector3.new(0, 0, 1338), Vector3.new(-20, 0, 1312), Vector3.new(15, 0, 1290), Vector3.new(0, 0, 1266)}
for i = 1, #PATH1 - 1 do
	local a, b = PATH1[i], PATH1[i + 1]
	local len = (b - a).Magnitude
	local n = math.ceil(len / 4)
	for k = 0, n do
		local p = a:Lerp(b, k / n)
		part({name = "PathStone", size = Vector3.new(6, 0.5, 4.6), cf = CFrame.lookAt(p + Vector3.new(0, 0.25, 0), b + Vector3.new(0, 0.25, 0)),
			mat = Enum.Material.Slate, color = rgb(200, 204, 196), parent = path1})
	end
end
part({name = "PathStone", size = Vector3.new(12, 0.5, 8), pos = Vector3.new(0, 0.25, 1264), mat = Enum.Material.Slate, color = rgb(200, 204, 196), parent = path1})
local grass = folder("Room1Grass", IX, "Model")
for _, g in ipairs({{22, 1325, 22, 22}, {-25, 1285, 20, 24}, {28, 1270, 14, 18}, {-26, 1330, 16, 16}, {26, 1300, 14, 10}}) do
	part({name = "TallGrass", size = Vector3.new(g[3], 3.5, g[4]), pos = Vector3.new(g[1], 1.75, g[2]), mat = Enum.Material.Grass, color = rgb(46, 70, 36), tr = 0.15, collide = false, parent = grass})
end
part({name = "Room1Start", size = Vector3.new(4, 1, 4), pos = Vector3.new(0, 0.5, 1334), tr = 1, collide = false, touch = false, parent = IX})
local flies = folder("Fireflies", IX, "Model")
for i = 1, 28 do
	local p = part({name = "Firefly", shape = Enum.PartType.Ball, size = Vector3.new(0.45, 0.45, 0.45),
		pos = Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(2.5, 9), rng:NextNumber(1264, 1336)),
		mat = Enum.Material.Neon, color = rgb(210, 255, 120), collide = false, noShadow = true, touch = false, query = false, parent = flies})
	if i % 3 == 0 then light(p, 10, 0.9, rgb(200, 255, 120)) end
end
-- mũi tên đom đóm (dấu hiệu) — chỉ ngược về phía Lobby, ẩn lúc đầu
local arrow = folder("ArrowFlies", IX, "Model")
local ARROW = {{0, 0}, {0, 2}, {0, 4}, {0, 6}, {-1.6, 4.6}, {1.6, 4.6}, {-3, 3.2}, {3, 3.2}}
for _, a in ipairs(ARROW) do
	part({name = "ArrowFly", shape = Enum.PartType.Ball, size = Vector3.new(0.6, 0.6, 0.6), pos = Vector3.new(a[1], 5, 1272 + a[2]),
		mat = Enum.Material.Neon, color = rgb(255, 250, 160), tr = 1, collide = false, noShadow = true, parent = arrow})
end
part({name = "Clue_Arrow", size = Vector3.new(7, 8, 4), pos = Vector3.new(0, 4, 1275), tr = 1, collide = false, parent = IX})
-- lọ đom đóm (bẫy: "Không bắt đom đóm")
local jar = part({name = "FireflyJar", shape = Enum.PartType.Cylinder, size = Vector3.new(1.4, 1, 1), cf = CFrame.new(-10, 3.4, 1316) * CFrame.Angles(0, 0, math.rad(90)),
	mat = Enum.Material.Glass, color = rgb(200, 255, 150), tr = 0.4, parent = IX})
light(jar, 8, 1, rgb(200, 255, 130))
stump("Stump", Vector3.new(-10, 1.4, 1316))
local s1 = part({name = "AnchorShard1", size = Vector3.new(1, 1.6, 1), cf = CFrame.new(0, 2.4, 1262) * CFrame.Angles(0, math.rad(45), math.rad(20)), mat = Enum.Material.Neon, color = rgb(150, 220, 255), tr = 1, collide = false, parent = IX})
light(s1, 10, 1, rgb(150, 220, 255))

-- ===================================================================
-- ROOM2 — ĐẦM SƯƠNG MÙ
-- ===================================================================
treeBorder(110, 1400, 80, 80, {{70, 1400}}, 12)
part({name = "Water", size = Vector3.new(74, 0.3, 74), pos = Vector3.new(112, 0.05, 1400), mat = Enum.Material.Glass, color = rgb(30, 52, 56), tr = 0.15, collide = false, parent = IX})
local stones = folder("Stones", IX, "Model")
local STONES = {{76, 1400}, {82, 1396}, {88, 1402}, {94, 1398}, {100, 1403}, {105, 1398}, {120, 1407}, {125, 1413}, {130, 1419}, {116, 1392}}
for _, s in ipairs(STONES) do
	part({name = "Stone", size = Vector3.new(5, 0.7, 5), cf = CFrame.new(s[1], 0.35, s[2]) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0), mat = Enum.Material.Slate, color = rgb(120, 120, 112), parent = stones})
end
part({name = "Stone", size = Vector3.new(9, 0.8, 9), pos = Vector3.new(112, 0.4, 1401), mat = Enum.Material.Slate, color = rgb(130, 128, 118), parent = stones})
-- cầu gỗ ra đảo nhỏ phía bắc (chỉ 1 người)
part({name = "Bridge", size = Vector3.new(6, 0.8, 22), pos = Vector3.new(112, 0.6, 1383), mat = Enum.Material.WoodPlanks, color = rgb(90, 66, 44), parent = IX})
part({name = "Stone", size = Vector3.new(16, 0.8, 12), pos = Vector3.new(112, 0.4, 1366), mat = Enum.Material.Slate, color = rgb(110, 110, 100), parent = stones})
-- chuông gió trên cây chết ở đảo
local chime = folder("Chime", IX, "Model")
part({name = "DeadTree", shape = Enum.PartType.Cylinder, size = Vector3.new(14, 1.6, 1.6), cf = CFrame.new(112, 7, 1364) * CFrame.Angles(0, 0, math.rad(90)), mat = Enum.Material.Wood, color = rgb(70, 64, 58), parent = chime})
part({name = "Branch", size = Vector3.new(8, 0.6, 0.6), pos = Vector3.new(114, 12, 1364), mat = Enum.Material.Wood, color = rgb(70, 64, 58), parent = chime})
local bell = part({name = "Bell", size = Vector3.new(0.6, 2.4, 0.6), pos = Vector3.new(117, 10, 1364), mat = Enum.Material.Metal, color = rgb(190, 190, 170), collide = false, parent = chime})
for i = 1, 4 do part({name = "Rod", size = Vector3.new(0.2, 1.6 + i * 0.3, 0.2), pos = Vector3.new(116 + i * 0.4, 10 - i * 0.15, 1364), mat = Enum.Material.Metal, color = rgb(200, 200, 180), collide = false, parent = chime}) end
sound(bell, "Ring", "rbxassetid://9113583960", 0.9, true, 1.3)
sound(bell, "Tinkle", "rbxassetid://9113583960", 0.4, false, 1.8)
light(bell, 14, 0, rgb(200, 220, 255))
-- bóng phản chiếu (dấu hiệu)
local refl = part({name = "Clue_Reflection", size = Vector3.new(5, 0.2, 5), pos = Vector3.new(124, 0.25, 1404), mat = Enum.Material.Neon, color = rgb(170, 200, 255), tr = 1, collide = false, parent = IX})
label(refl, Enum.NormalId.Top, "🧒🧭", rgb(200, 220, 255), Enum.Font.GothamBold).TextTransparency = 1
-- điểm thả la bàn (giữa đầm)
local drop = part({name = "DropPoint", shape = Enum.PartType.Cylinder, size = Vector3.new(0.3, 4, 4), cf = CFrame.new(112, 0.9, 1401) * CFrame.Angles(0, 0, math.rad(90)), mat = Enum.Material.Neon, color = rgb(90, 140, 160), tr = 0.6, collide = false, parent = IX})
light(drop, 10, 0.5, rgb(120, 180, 200))
-- sương mù thấp
for i = 1, 6 do
	part({name = "Mist", size = Vector3.new(26, 3, 26), pos = Vector3.new(rng:NextNumber(84, 140), 1.5, rng:NextNumber(1372, 1428)), mat = Enum.Material.SmoothPlastic, color = rgb(190, 200, 205), tr = 0.9, collide = false, noShadow = true, touch = false, query = false, parent = PROPS})
end

-- ===================================================================
-- ROOM3 — CÂY CỔ THỤ CÓ MẮT
-- ===================================================================
treeBorder(-110, 1400, 80, 80, {{-70, 1400}}, 12)
local eyeTree = folder("EyeTree", IX, "Model")
part({name = "Trunk", shape = Enum.PartType.Cylinder, size = Vector3.new(34, 11, 11), cf = CFrame.new(-128, 17, 1400) * CFrame.Angles(0, 0, math.rad(90)), mat = Enum.Material.Wood, color = rgb(58, 44, 36), parent = eyeTree})
for i = 1, 4 do
	part({name = "Canopy", shape = Enum.PartType.Ball, size = Vector3.new(22, 22, 22), pos = Vector3.new(-128 + rng:NextNumber(-7, 7), 34 + rng:NextNumber(-2, 3), 1400 + rng:NextNumber(-7, 7)), mat = Enum.Material.LeafyGrass, color = rgb(24, 36, 24), collide = false, parent = eyeTree})
end
for _, dz in ipairs({-2, 2}) do
	local e = part({name = "Eye", size = Vector3.new(0.6, 1.2, 2.2), pos = Vector3.new(-122.4, 14, 1400 + dz), mat = Enum.Material.Neon, color = rgb(60, 20, 20), collide = false, parent = eyeTree})
	light(e, 18, 0, rgb(255, 40, 40))
end
local carving = part({name = "Clue_Carving", size = Vector3.new(0.3, 3, 5), pos = Vector3.new(-122.4, 7, 1400), color = rgb(58, 44, 36), tr = 1, collide = false, parent = IX})
label(carving, Enum.NormalId.Right, "MINH – 10 tuổi", rgb(230, 210, 170)).TextTransparency = 1
local roots = folder("Roots", IX, "Model")
for i = 0, 6 do
	local a = math.rad(-80 + i * 27)
	local len = rng:NextNumber(9, 14)
	local c = Vector3.new(-128 + math.cos(a) * (6 + len / 2), 0.3, 1400 + math.sin(a) * (6 + len / 2))
	part({name = "Root", size = Vector3.new(len, 0.6, 1.2), cf = CFrame.new(c) * CFrame.Angles(0, -a, 0), mat = Enum.Material.Neon, color = rgb(150, 70, 200), collide = false, parent = roots})
end
local compass = part({name = "Compass", shape = Enum.PartType.Cylinder, size = Vector3.new(0.3, 1.4, 1.4), cf = CFrame.new(-112, 0.3, 1414) * CFrame.Angles(0, 0, math.rad(90)), mat = Enum.Material.Metal, color = rgb(190, 160, 90), tr = 1, collide = false, parent = IX})
light(compass, 8, 0, rgb(255, 200, 120))

-- ===================================================================
-- ROOM4 — HANG GỖ MỤC
-- ===================================================================
for _ = 1, 8 do -- cột đá
	local x, z = rng:NextNumber(-78, -36), rng:NextNumber(1490, 1530)
	if (Vector3.new(x, 0, z) - Vector3.new(-50, 0, 1510)).Magnitude > 8 then
		part({name = "RockPillar", size = Vector3.new(rng:NextNumber(3, 5), 14, rng:NextNumber(3, 5)), pos = Vector3.new(x, 7, z), mat = Enum.Material.Slate, color = ROCK, parent = PROPS})
	end
end
local niches = folder("Niches", IX, "Model")
for i, n in ipairs({{-82, 1490}, {-82, 1530}, {-50, 1542}, {-18, 1530}, {-50, 1478.5}}) do
	part({name = "Niche", size = Vector3.new(5, 10, 5), pos = Vector3.new(n[1], 5, n[2]), tr = 1, collide = false, touch = false, query = false, parent = niches})
	local mk = part({name = "NicheMoss", size = Vector3.new(4, 0.2, 4), pos = Vector3.new(n[1], 0.1, n[2]), mat = Enum.Material.Neon, color = rgb(60, 90, 150), tr = 0.5, collide = false, parent = niches})
	light(mk, 8, 0.5, rgb(90, 130, 220))
end
local knock = folder("Knocker", IX, "Model")
knock.PrimaryPart = part({name = "Body", size = Vector3.new(3, 9, 2), pos = Vector3.new(-70, 4.5, 1485), mat = Enum.Material.SmoothPlastic, color = rgb(10, 8, 10), collide = false, parent = knock}) -- code dùng PivotTo để di chuyển Kẻ Gõ
part({name = "Head", shape = Enum.PartType.Ball, size = Vector3.new(2.6, 2.6, 2.6), pos = Vector3.new(-70, 10.2, 1485), mat = Enum.Material.SmoothPlastic, color = rgb(10, 8, 10), collide = false, parent = knock})
part({name = "Arm", size = Vector3.new(0.8, 7, 0.8), pos = Vector3.new(-68, 5, 1485), mat = Enum.Material.SmoothPlastic, color = rgb(14, 10, 12), collide = false, parent = knock})
for _, dx in ipairs({-0.6, 0.6}) do part({name = "EyeGlow", size = Vector3.new(0.4, 0.3, 0.2), pos = Vector3.new(-70 + dx, 10.4, 1483.8), mat = Enum.Material.Neon, color = rgb(255, 60, 40), collide = false, parent = knock}) end
local kpath = folder("KnockPath", IX)
for i, w in ipairs({{-70, 1485}, {-70, 1535}, {-30, 1535}, {-30, 1490}}) do
	part({name = "P" .. i, size = Vector3.new(1, 1, 1), pos = Vector3.new(w[1], 4.5, w[2]), tr = 1, collide = false, touch = false, query = false, parent = kpath})
end
local kstone = part({name = "KnockStone", size = Vector3.new(3, 3, 3), pos = Vector3.new(-28, 1.5, 1480), mat = Enum.Material.Slate, color = rgb(84, 78, 72), parent = IX})
sound(kstone, "Knock", "rbxassetid://9116809743", 0.9, false, 0.45)
local caveSound = part({name = "CaveEcho", size = Vector3.new(1, 1, 1), pos = Vector3.new(-50, 8, 1510), tr = 1, collide = false, touch = false, query = false, parent = IX})
sound(caveSound, "Knock", "rbxassetid://9116809743", 1, false, 0.4)
sound(caveSound, "Hum", "rbxassetid://4227579935", 0.3, true, 0.6)
local bag = part({name = "Clue_Backpack", size = Vector3.new(2, 2.4, 1.2), pos = Vector3.new(-62, 1.2, 1538), mat = Enum.Material.Fabric, color = rgb(160, 60, 50), tr = 1, collide = false, parent = IX})
light(bag, 6, 0, rgb(255, 200, 150))
local s2 = part({name = "AnchorShard2", size = Vector3.new(1, 1.6, 1), cf = CFrame.new(-50, 2, 1542) * CFrame.Angles(0, math.rad(30), math.rad(15)), mat = Enum.Material.Neon, color = rgb(150, 220, 255), collide = false, parent = IX})
light(s2, 10, 1, rgb(150, 220, 255))
for _ = 1, 10 do -- nấm/gỗ mục phát sáng mờ
	local p = part({name = "RotWood", size = Vector3.new(rng:NextNumber(3, 6), 0.8, 1.2), cf = CFrame.new(rng:NextNumber(-80, -24), 0.4, rng:NextNumber(1486, 1540)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
		mat = Enum.Material.Wood, color = rgb(60, 52, 40), parent = PROPS})
	if rng:NextNumber() < 0.4 then light(p, 7, 0.3, rgb(120, 170, 110)) end
end

-- ===================================================================
-- ROOM5 — VƯỜN NẤM PHÁT SÁNG
-- ===================================================================
treeBorder(50, 1510, 70, 70, {{21, 1475}}, 10)
local mush = folder("Mushrooms", IX, "Model")
local function mushroom(x, z, s, parent, color)
	local m = Instance.new("Model") m.Name = "Mushroom" m.Parent = parent or mush
	part({name = "Stem", shape = Enum.PartType.Cylinder, size = Vector3.new(2 * s, 0.6 * s, 0.6 * s), cf = CFrame.new(x, s, z) * CFrame.Angles(0, 0, math.rad(90)), mat = Enum.Material.SmoothPlastic, color = rgb(220, 215, 200), collide = false, parent = m})
	local cap = part({name = "Cap", shape = Enum.PartType.Ball, size = Vector3.new(2 * s, 1 * s, 2 * s), pos = Vector3.new(x, 2 * s, z), mat = Enum.Material.Neon, color = color or rgb(40, 70, 80), collide = false, parent = m})
	return m, cap
end
for i = 1, 22 do
	local x, z = rng:NextNumber(20, 82), rng:NextNumber(1482, 1542)
	local _, cap = mushroom(x, z, rng:NextNumber(0.8, 1.8))
	if i % 3 == 0 then light(cap, 12, 0.2, rgb(90, 255, 230)) end
end
local white, red = folder("WhiteRings", IX, "Model"), folder("RedRings", IX, "Model")
local function ring(parent, name, x, z, d, color)
	return part({name = name, shape = Enum.PartType.Cylinder, size = Vector3.new(0.15, d, d), cf = CFrame.new(x, 0.08, z) * CFrame.Angles(0, 0, math.rad(90)),
		mat = Enum.Material.Neon, color = color, tr = 0.55, collide = false, noShadow = true, parent = parent})
end
for _, r in ipairs({{60, 1525, 14}, {36, 1535, 10}, {30, 1492, 9}, {70, 1495, 9}}) do ring(white, "WhiteRing", r[1], r[2], r[3], rgb(235, 240, 235)) end
for _, r in ipairs({{45, 1505, 10}, {76, 1540, 9}, {28, 1515, 8}, {58, 1485, 7}}) do ring(red, "RedRing", r[1], r[2], r[3], rgb(200, 40, 40)) end
local _, bigCap = mushroom(32, 1497, 2.6, IX, rgb(255, 150, 220))
bigCap.Parent.Name = "PickMushroom"
light(bigCap, 12, 1.2, rgb(255, 150, 220))
local shoe = part({name = "Clue_Shoe", size = Vector3.new(1.2, 0.8, 2), pos = Vector3.new(36, 0.4, 1535), mat = Enum.Material.Fabric, color = rgb(200, 60, 60), tr = 1, collide = false, parent = IX})
light(shoe, 6, 0, rgb(255, 200, 200))
local s3 = part({name = "AnchorShard3", size = Vector3.new(1, 1.6, 1), cf = CFrame.new(60, 2, 1525) * CFrame.Angles(0, math.rad(60), math.rad(18)), mat = Enum.Material.Neon, color = rgb(150, 220, 255), collide = false, parent = IX})
light(s3, 10, 1, rgb(150, 220, 255))
local sporeSrc = part({name = "SporeCloud", size = Vector3.new(66, 6, 66), pos = Vector3.new(50, 3, 1510), mat = Enum.Material.SmoothPlastic, color = rgb(150, 255, 230), tr = 1, collide = false, noShadow = true, touch = false, query = false, parent = IX})
sound(sporeSrc, "Hiss", "rbxassetid://9120494643", 0.7, false, 0.6)

fs.writeFile("map/DreamMap3.rbxm", roblox.serializeModel({map}))
print("map/DreamMap3.rbxm", #map:GetDescendants())
