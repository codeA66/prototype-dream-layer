-- Dựng map Tầng 4 (BOSS) — CĂN NHÀ CỦA NGƯỜI NGỦ — ra map/DreamMap4.rbxm
-- Chạy: lune run tools/build-map4.luau
-- Bản blockout (khối thô). Builder mở trong Studio để trang trí thêm,
-- nhưng KHÔNG đổi tên các thứ trong Interactables / Zones / Doors (Level4Manager dùng đúng những tên này).
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance, CFrame, Vector3, Color3, Enum = roblox.Instance, roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum
local UDim2 = roblox.UDim2

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local map = Instance.new("Folder") map.Name = "DreamMap4"
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
	if o.touch == false then p.CanTouch = false end
	if o.query == false then p.CanQuery = false end
	p.Parent = o.parent or GEO
	return p
end
local function light(p, range, bright, color)
	local l = Instance.new("PointLight") l.Range = range l.Brightness = bright l.Color = color l.Parent = p return l
end
-- SoundId để trống: Builder gắn ID âm thanh trong Studio (code gọi Play() trong pcall nên thiếu âm vẫn chạy)
local function sound(parent, name, id, vol, looped)
	local s = Instance.new("Sound") s.Name = name s.SoundId = id or "" s.Volume = vol or 0.7 s.Looped = looped == true
	s.RollOffMaxDistance = 90 s.Parent = parent return s
end
local function label(p, face, text, color, font)
	local g = Instance.new("SurfaceGui") g.Face = face g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 40
	g.LightInfluence = 0 g.Parent = p
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true
	t.Text = text t.TextColor3 = color or rgb(240, 230, 210) t.FontFace = roblox.Font.fromEnum(font or Enum.Font.Antique) t.Parent = g
	return t
end
local function speech(model, adornee)
	local g = Instance.new("BillboardGui") g.Name = "Speech" g.Size = UDim2.fromOffset(260, 60) g.StudsOffset = Vector3.new(0, 3, 0)
	g.Adornee = adornee g.AlwaysOnTop = true g.Enabled = false g.Parent = model
	local f = Instance.new("Frame") f.Name = "Bubble" f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = rgb(20, 16, 28) f.BackgroundTransparency = 0.3 f.Parent = g
	local t = Instance.new("TextLabel") t.Name = "Text" t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true
	t.TextColor3 = rgb(240, 230, 250) t.Text = "" t.Parent = f
end

local WALL_H = 22
local WALLPAPER = rgb(70, 58, 78)

-- ===== TƯỜNG QUANH MỘT KHU (chừa lối vào) — giống build-map3 =====
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
			local len = s[2] - s[1]
			local mid = (s[1] + s[2]) / 2
			local pos = alongX and Vector3.new(mid, h / 2, fixed) or Vector3.new(fixed, h / 2, mid)
			local size = alongX and Vector3.new(len + 2, h, 2) or Vector3.new(2, h, len + 2)
			part({name = "Wall", size = size, pos = pos, mat = mat or Enum.Material.Fabric, color = color or WALLPAPER})
		end
	end
	side("N", x0, x1, z0 - 1, true)
	side("S", x0, x1, z1 + 1, true)
	side("W", z0, z1, x0 - 1, false)
	side("E", z0, z1, x1 + 1, false)
	-- trần nhà
	part({name = "Ceiling", size = Vector3.new(w + 4, 1, d + 4), pos = Vector3.new(cx, h + 0.5, cz), mat = Enum.Material.Wood, color = rgb(40, 32, 40)})
end
local function floor(name, cx, cz, w, d, mat, color)
	return part({name = name, size = Vector3.new(w, 1, d), pos = Vector3.new(cx, -0.5, cz), mat = mat or Enum.Material.WoodPlanks, color = color or rgb(70, 52, 44)})
end
local function zone(name, cx, cz, w, d)
	part({name = name, size = Vector3.new(w, 22, d), pos = Vector3.new(cx, 11, cz), tr = 1, collide = false, touch = false, query = false, parent = ZONES})
end
local function fill(pos, range, bright, color)
	local p = part({name = "FillLight", size = Vector3.new(0.2, 0.2, 0.2), pos = pos, tr = 1, collide = false, touch = false, query = false, parent = LIGHTS})
	light(p, range or 45, bright or 0.4, color or rgb(170, 150, 220))
end
local function door(name, cf, width)
	local m = Instance.new("Model") m.Name = name m.Parent = DOORS
	local panel = part({name = "Panel", size = Vector3.new(width, 12, 0.6), cf = cf, mat = Enum.Material.WoodPlanks, color = rgb(92, 70, 60), parent = m})
	sound(panel, "Creak", "rbxassetid://9120839174", 0.8)
	local hv = Instance.new("CFrameValue") hv.Name = "Hinge" hv.Value = cf * CFrame.new(-width / 2, 0, 0) hv.Parent = m
	m.PrimaryPart = panel
	return m
end
-- người/thực thể dạng khối: Body + Head (+ Mask) — Builder thay bằng model đẹp nhưng giữ tên Model + Part "Head"
local function figure(name, pos, bodyColor, maskColor, parent)
	local m = Instance.new("Model") m.Name = name m.Parent = parent or IX
	local body = part({name = "Body", size = Vector3.new(3, 6, 2), pos = pos + Vector3.new(0, 3, 0), color = bodyColor, parent = m})
	local head = part({name = "Head", size = Vector3.new(2, 2, 2), pos = pos + Vector3.new(0, 7, 0), color = rgb(225, 215, 200), parent = m})
	if maskColor then part({name = "Mask", size = Vector3.new(1.8, 1.8, 0.3), pos = pos + Vector3.new(0, 7, -1.1), mat = Enum.Material.Neon, color = maskColor, collide = false, parent = m}) end
	m.PrimaryPart = body
	speech(m, head)
	return m
end

-- ===================================================================
-- BỐ CỤC (nhìn từ trên xuống, Bắc = z nhỏ) — đặt xa Tầng 3 (z 1259–1546)
--                 Room1 Lớp học trong tủ sách (0, 1900)
--                              |
--  Room3 Khu rừng trong tranh ── LOBBY Phòng ngủ của Minh ── Room2 Phòng chờ dưới gầm giường
--        (-110, 2000)               (0, 2000)                   (110, 2000)
--                              |
--                 Room4 Phòng khách — Ghế bành (0, 2110)
-- ===================================================================
floor("Floor_Lobby", 0, 2000, 70, 70, Enum.Material.Carpet, rgb(46, 52, 86))
walls(0, 2000, 70, 70, {N = {{-6, 6}}, S = {{-6, 6}}, E = {{1994, 2006}}, W = {{1994, 2006}}}, Enum.Material.Fabric, rgb(60, 70, 110))
floor("Floor_Room1", 0, 1900, 80, 70, Enum.Material.WoodPlanks, rgb(80, 60, 44))
walls(0, 1900, 80, 70, {S = {{-6, 6}}}, Enum.Material.Wood, rgb(74, 58, 44))
floor("Floor_Room2", 110, 2000, 80, 80, Enum.Material.Marble, rgb(170, 175, 170))
walls(110, 2000, 80, 80, {W = {{1994, 2006}}}, Enum.Material.SmoothPlastic, rgb(150, 170, 160))
floor("Floor_Room3", -110, 2000, 80, 80, Enum.Material.Grass, rgb(34, 46, 30))
walls(-110, 2000, 80, 80, {E = {{1994, 2006}}}, Enum.Material.LeafyGrass, rgb(24, 38, 24))
floor("Floor_Room4", 0, 2110, 90, 90, Enum.Material.WoodPlanks, rgb(60, 40, 36))
walls(0, 2110, 90, 90, {N = {{-6, 6}}}, Enum.Material.Fabric, rgb(80, 40, 48))
-- hành lang
floor("Hall_N", 0, 1950, 12, 30) walls(0, 1950, 12, 30, {N = {{-6, 6}}, S = {{-6, 6}}})
floor("Hall_E", 52.5, 2000, 35, 12) walls(52.5, 2000, 35, 12, {W = {{1994, 2006}}, E = {{1994, 2006}}})
floor("Hall_W", -52.5, 2000, 35, 12) walls(-52.5, 2000, 35, 12, {W = {{1994, 2006}}, E = {{1994, 2006}}})
floor("Hall_S", 0, 2050, 12, 30) walls(0, 2050, 12, 30, {N = {{-6, 6}}, S = {{-6, 6}}})

-- ===== VÙNG PHÒNG =====
zone("Lobby", 0, 2000, 70, 70)
zone("Room1", 0, 1900, 80, 70)
zone("Room2", 110, 2000, 80, 80)
zone("Room3", -110, 2000, 80, 80)
zone("Room4", 0, 2110, 90, 90)

-- ===== CỬA =====
door("Door_Room1", CFrame.new(0, 6, 1936), 12)
door("Door_Room2", CFrame.new(69, 6, 2000) * CFrame.Angles(0, math.rad(90), 0), 12)
door("Door_Room3", CFrame.new(-69, 6, 2000) * CFrame.Angles(0, math.rad(-90), 0), 12)
door("Door_Room4", CFrame.new(0, 6, 2064), 12)

-- ánh sáng nền (mờ, tím lạnh)
fill(Vector3.new(0, 18, 1900), 60, 0.7) fill(Vector3.new(110, 18, 2000), 60, 0.7)
fill(Vector3.new(-110, 18, 2000), 60, 0.5, rgb(120, 170, 130)) fill(Vector3.new(0, 18, 2110), 70, 0.35, rgb(200, 120, 120))
fill(Vector3.new(0, 18, 1950), 25, 0.3) fill(Vector3.new(0, 18, 2050), 25, 0.3)
fill(Vector3.new(52, 18, 2000), 25, 0.3) fill(Vector3.new(-52, 18, 2000), 25, 0.3)

-- ===================================================================
-- LOBBY — PHÒNG NGỦ CỦA MINH (nơi an toàn: không có luật)
-- ===================================================================
part({name = "Spawn4", size = Vector3.new(8, 1, 8), pos = Vector3.new(0, 0.2, 2010), tr = 1, collide = false, touch = false, parent = IX})
local bed = part({name = "Bed", size = Vector3.new(8, 2.5, 12), pos = Vector3.new(22, 1.25, 1985), mat = Enum.Material.Fabric, color = rgb(210, 205, 230), parent = IX})
part({name = "Pillow", size = Vector3.new(6, 1, 2.5), pos = Vector3.new(22, 3, 1980.5), mat = Enum.Material.Fabric, color = rgb(240, 240, 250), parent = PROPS})
local nl = part({name = "NightLight", shape = Enum.PartType.Ball, size = Vector3.new(2, 2, 2), pos = Vector3.new(28, 4, 1978), mat = Enum.Material.Neon, color = rgb(255, 235, 170), parent = IX})
light(nl, 30, 1.6, rgb(255, 230, 170))
sound(nl, "PageFlip", "", 1)
part({name = "Nightstand", size = Vector3.new(3, 3, 3), pos = Vector3.new(28, 1.5, 1978), mat = Enum.Material.Wood, color = rgb(90, 70, 55), parent = PROPS})
part({name = "RulesPaper", size = Vector3.new(1.4, 0.05, 1.9), pos = Vector3.new(-6, 3.05, 2012), color = rgb(236, 228, 205), parent = IX})
part({name = "Desk", size = Vector3.new(6, 3, 3), pos = Vector3.new(-6, 1.5, 2012), mat = Enum.Material.Wood, color = rgb(100, 76, 60), parent = PROPS})
part({name = "MomDiary", size = Vector3.new(1.3, 0.3, 1.8), pos = Vector3.new(18, 2.7, 1993), mat = Enum.Material.Fabric, color = rgb(160, 90, 110), parent = IX})
-- Bệ Neo + Cổng (khung cửa sổ lúc bình minh)
local altar = part({name = "AnchorAltar", size = Vector3.new(3.6, 3.6, 3.6), pos = Vector3.new(0, 1.8, 2022), mat = Enum.Material.Marble, color = rgb(170, 180, 190), parent = IX})
light(altar, 10, 0.6, rgb(150, 220, 255))
part({name = "WindowFrame", size = Vector3.new(16, 18, 1), pos = Vector3.new(-22, 9, 1966.2), mat = Enum.Material.Wood, color = rgb(60, 44, 36), parent = PROPS})
part({name = "Gate", size = Vector3.new(12, 14, 1), pos = Vector3.new(-22, 9, 1967), mat = Enum.Material.Glass, color = rgb(30, 30, 40), tr = 0.3, parent = IX})
-- Kệ truyện: 5 cuốn truyện = câu đố Truy Nguyên
part({name = "Bookshelf", size = Vector3.new(24, 10, 3), pos = Vector3.new(-18, 5, 2033), mat = Enum.Material.Wood, color = rgb(80, 58, 44), parent = PROPS})
for i = 1, 5 do
	local b = part({name = "Puzzle" .. i, size = Vector3.new(3, 4, 1), pos = Vector3.new(-28 + (i - 1) * 5, 6, 2031), mat = Enum.Material.Fabric,
		color = rgb(120 + i * 15, 80, 100), parent = IX})
	label(b, Enum.NormalId.Front, "?", rgb(250, 240, 220))
end

-- ===================================================================
-- ROOM1 — LỚP HỌC TRONG TỦ SÁCH (mặt nạ Cô Giáo)
-- ===================================================================
local board = part({name = "Blackboard", size = Vector3.new(30, 10, 0.5), pos = Vector3.new(0, 8, 1866.5), mat = Enum.Material.Slate, color = rgb(28, 44, 36), parent = IX})
label(board, Enum.NormalId.Back, "", rgb(240, 240, 230), Enum.Font.Cartoon)
sound(board, "Chalk", "", 0.6, true)
local teacher = figure("Teacher", Vector3.new(8, 0, 1872), rgb(80, 60, 90), rgb(240, 240, 240))
sound(teacher.Head, "Ahem", "", 1)
part({name = "Clue_Name", size = Vector3.new(8, 3, 0.4), pos = Vector3.new(-9, 8, 1867), mat = Enum.Material.Neon, color = rgb(200, 40, 40), tr = 1, collide = false, parent = IX})
part({name = "TeacherDesk", size = Vector3.new(8, 3, 4), pos = Vector3.new(0, 1.5, 1876), mat = Enum.Material.Wood, color = rgb(110, 80, 56), parent = PROPS})
part({name = "Podium", size = Vector3.new(5, 1, 5), pos = Vector3.new(-12, 0.5, 1876), mat = Enum.Material.Wood, color = rgb(140, 100, 70), parent = IX})
local s1 = part({name = "AnchorShard1", size = Vector3.new(0.6, 2, 0.6), pos = Vector3.new(-2, 4, 1876), mat = Enum.Material.Neon, color = rgb(240, 240, 240), tr = 1, collide = false, parent = IX})
light(s1, 8, 0, rgb(200, 230, 255))
local tale = part({name = "TaleBook", size = Vector3.new(1.6, 0.4, 2.2), pos = Vector3.new(2, 3.2, 1876), mat = Enum.Material.Fabric, color = rgb(40, 20, 30), tr = 1, collide = false, parent = IX})
light(tale, 10, 0, rgb(255, 60, 90))
for r = 0, 2 do for c = -2, 2 do
	part({name = "StudentDesk", size = Vector3.new(5, 3, 3), pos = Vector3.new(c * 12, 1.5, 1895 + r * 10), mat = Enum.Material.Wood, color = rgb(120, 90, 64), parent = PROPS})
end end

-- ===================================================================
-- ROOM2 — PHÒNG CHỜ DƯỚI GẦM GIƯỜNG (mặt nạ Thu Ngân)
-- ===================================================================
local qb = part({name = "QueueBoard", size = Vector3.new(12, 5, 0.5), pos = Vector3.new(110, 12, 1961.5), mat = Enum.Material.SmoothPlastic, color = rgb(20, 20, 24), parent = IX})
label(qb, Enum.NormalId.Back, "--", rgb(255, 90, 60), Enum.Font.Code)
sound(qb, "Chime", "", 1)
local counter = part({name = "Counter", size = Vector3.new(20, 4, 3), pos = Vector3.new(110, 2, 1972), mat = Enum.Material.Wood, color = rgb(120, 100, 90), parent = IX})
local cl = part({name = "CounterLight", size = Vector3.new(2, 1, 2), pos = Vector3.new(110, 10, 1972), mat = Enum.Material.Neon, color = rgb(80, 220, 120), parent = IX})
light(cl, 18, 1, rgb(80, 220, 120))
figure("Cashier", Vector3.new(110, 0, 1966), rgb(90, 110, 100), rgb(255, 210, 210))
part({name = "Clue_Number", size = Vector3.new(6, 3, 0.4), pos = Vector3.new(124, 12, 1962), mat = Enum.Material.Neon, color = rgb(255, 60, 60), tr = 1, collide = false, parent = IX})
local seats = folder("Seats", IX, "Model")
for r = 0, 2 do
	part({name = "Seat", size = Vector3.new(30, 2, 5), pos = Vector3.new(110, 1, 1995 + r * 12), mat = Enum.Material.Fabric, color = rgb(60, 90, 110), parent = seats})
end
local s2 = part({name = "AnchorShard2", size = Vector3.new(1.4, 0.4, 1.4), pos = Vector3.new(104, 4.4, 1972), mat = Enum.Material.Neon, color = rgb(150, 220, 255), tr = 1, collide = false, parent = IX})
light(s2, 8, 0, rgb(150, 220, 255))

-- ===================================================================
-- ROOM3 — KHU RỪNG TRONG BỨC TRANH (đom đóm)
-- Sàn trong khung tranh (FrameInside) là vùng được đứng; ngoài viền vàng (dải phía Tây, Bắc, Nam) là "ngoài tranh"
-- ===================================================================
part({name = "FrameInside", size = Vector3.new(70, 0.2, 56), pos = Vector3.new(-103, 0.1, 2000), mat = Enum.Material.Grass, color = rgb(44, 62, 36), collide = false, parent = IX})
for _, e in ipairs({{-103, 1971, 72, 1}, {-103, 2029, 72, 1}, {-139, 2000, 1, 58}}) do -- cạnh Đông để trống: lối vào từ cửa
	part({name = "FrameEdge", size = Vector3.new(e[3], 0.4, e[4]), pos = Vector3.new(e[1], 0.2, e[2]), mat = Enum.Material.Neon, color = rgb(230, 190, 80), collide = false, parent = PROPS})
end
part({name = "Room3Start", size = Vector3.new(4, 1, 4), pos = Vector3.new(-84, 0.5, 2000), tr = 1, collide = false, touch = false, parent = IX})
local flies = folder("Fireflies", IX, "Model")
for i = 1, 24 do
	local a = i * 0.9
	local f = part({name = "Fly", shape = Enum.PartType.Ball, size = Vector3.new(0.5, 0.5, 0.5),
		pos = Vector3.new(-110 + math.cos(a) * (8 + i), 4 + (i % 4), 2000 + math.sin(a) * (8 + i % 18)), mat = Enum.Material.Neon, color = rgb(210, 255, 140), collide = false, parent = flies})
	if i % 3 == 0 then light(f, 12, 0.8, rgb(210, 255, 140)) end
end
local boy = part({name = "Clue_Boy", size = Vector3.new(2, 5, 1), pos = Vector3.new(-128, 2.5, 1982), mat = Enum.Material.Neon, color = rgb(20, 20, 30), tr = 1, collide = false, parent = IX})
local s3 = part({name = "AnchorShard3", size = Vector3.new(0.3, 2.4, 0.3), pos = Vector3.new(-110, 2.4, 2020), mat = Enum.Material.Neon, color = rgb(255, 80, 80), tr = 1, collide = false, parent = IX})
light(s3, 8, 0, rgb(255, 120, 120))

-- ===================================================================
-- ROOM4 — PHÒNG KHÁCH: KẺ GIEO MỘNG ngồi ghế bành đọc truyện
-- ===================================================================
part({name = "Armchair", size = Vector3.new(8, 6, 7), pos = Vector3.new(0, 3, 2140), mat = Enum.Material.Fabric, color = rgb(110, 30, 40), parent = IX})
local shadow = folder("ChairShadow", IX, "Model")
part({name = "Shadow", size = Vector3.new(22, 0.2, 14), pos = Vector3.new(0, 0.1, 2128), mat = Enum.Material.SmoothPlastic, color = rgb(10, 6, 10), collide = false, parent = shadow})
local seeder = figure("Seeder", Vector3.new(0, 0, 2136), rgb(30, 24, 40), rgb(170, 80, 255))
seeder.Head.Size = Vector3.new(2.4, 2.4, 2.4)
part({name = "Book", size = Vector3.new(2, 0.3, 1.5), pos = Vector3.new(0, 5, 2134), mat = Enum.Material.Fabric, color = rgb(200, 180, 140), collide = false, parent = seeder})
sound(seeder.Head, "Whisper", "", 0.8, true)
part({name = "SeederHome", size = Vector3.new(2, 1, 2), pos = Vector3.new(0, 0.5, 2136), tr = 1, collide = false, touch = false, parent = IX})
local fire = part({name = "Fireplace", size = Vector3.new(12, 8, 3), pos = Vector3.new(-38, 4, 2150), mat = Enum.Material.Brick, color = rgb(90, 50, 40), parent = IX})
light(fire, 20, 1.2, rgb(255, 140, 60))

-- ===================================================================
-- TRANG CUỐI (kết cục Bình Minh): 4 chỗ, mỗi ván chỉ bật chỗ ứng với dòng nói dối
-- ===================================================================
local pages = {Vector3.new(-30, 1, 1870), Vector3.new(140, 1, 1966), Vector3.new(-128, 1, 2026), Vector3.new(40, 1, 2150)}
for i, pos in ipairs(pages) do
	local p = part({name = "LastPage" .. i, size = Vector3.new(1.4, 0.05, 1.9), pos = pos, mat = Enum.Material.Neon, color = rgb(255, 245, 200), tr = 1, collide = false, parent = IX})
	light(p, 6, 0, rgb(255, 245, 200))
end

fs.writeFile("map/DreamMap4.rbxm", roblox.serializeModel({ map }))
print("map/DreamMap4.rbxm", #map:GetDescendants())
