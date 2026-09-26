-- DREAM LAYERS - Sảnh chờ: chọn vai (không trùng nhau), sẵn sàng, đếm ngược vào ván
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local State = RS:WaitForChild("GameState")
local Remotes = RS:WaitForChild("Remotes")

local ROLES = {
	{id = "Seer", name = "THẤU THỊ", icon = "👁", color = Color3.fromRGB(160, 140, 255), enabled = true,
		desc = "Biết cái đang ẨN.\nNhìn Xuyên: soi bí mật của phòng đang đứng — cả nhóm cùng thấy.\nNội tại Mắt Đêm: thấy xuyên tường hiểm nguy & đồ vật ở gần.\nTỉnh táo 100."},
	{id = "Healer", name = "CHỮA LÀNH", icon = "♪", color = Color3.fromRGB(120, 230, 170), enabled = true,
		desc = "Dỗ dịu & GÁNH HỘ.\nBài Ru: +25 cả phòng, Bình tâm, kéo người hòa mộng dậy, sát thương giảm một nửa 3 giây.\nNội tại Sợi Chỉ Đỏ: gánh một nửa lần phạt của đồng đội.\nTỉnh táo 100."},
	{id = "Anchor", name = "NGƯỜI NEO", icon = "⚓", color = Color3.fromRGB(120, 180, 240), enabled = true,
		desc = "DỪNG THỜI GIAN.\nCắm Neo: mọi thứ trong phòng đứng yên 5 giây. Cổng mở: Chống cửa +5 giây.\nNội tại Chân Neo: không bao giờ bị đơ.\nTỉnh táo 110."},
	{id = "Diviner", name = "NHÀ BÓI TOÁN", icon = "🔮", color = Color3.fromRGB(235, 195, 110), enabled = true,
		desc = "Biết điều SẮP TỚI.\nGieo Quẻ: báo sự kiện kế tiếp của phòng đang đứng.\nNội tại Điềm Báo: rung màn hình ngay trước khi phòng đổi trạng thái.\nTỉnh táo 100."},
}

local gui = Instance.new("ScreenGui") gui.Name = "LobbyGui" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 30
gui.Parent = plr:WaitForChild("PlayerGui")
local bg = Instance.new("Frame", gui) bg.Size = UDim2.fromScale(1, 1) bg.BackgroundColor3 = Color3.fromRGB(8, 6, 14) bg.BackgroundTransparency = 0.25
local function txt(parent, pos, size, text, ts, font)
	local t = Instance.new("TextLabel", parent) t.Position = pos t.Size = size t.BackgroundTransparency = 1 t.Text = text or ""
	t.TextColor3 = Color3.fromRGB(235, 228, 245) t.Font = font or Enum.Font.GothamMedium t.TextSize = ts or 16 t.TextWrapped = true
	return t
end
txt(bg, UDim2.new(0, 0, 0.08, 0), UDim2.new(1, 0, 0, 50), "CHỌN VAI TRÒ", 40, Enum.Font.Antique)
local sub = txt(bg, UDim2.new(0, 0, 0.08, 52), UDim2.new(1, 0, 0, 24), "Mỗi người một vai, không trùng nhau. Tất cả bấm SẴN SÀNG để bắt đầu.", 16)

local row = Instance.new("Frame", bg) row.AnchorPoint = Vector2.new(0.5, 0.5) row.Position = UDim2.fromScale(0.5, 0.5) row.Size = UDim2.fromOffset(4 * 220 + 3 * 16, 300) row.BackgroundTransparency = 1
local sc = Instance.new("UIScale", row)
local function fit() local v = workspace.CurrentCamera.ViewportSize sc.Scale = math.min(1, (v.X - 40) / 928, (v.Y - 260) / 300) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local lay = Instance.new("UIListLayout", row) lay.FillDirection = Enum.FillDirection.Horizontal lay.Padding = UDim.new(0, 16) lay.HorizontalAlignment = Enum.HorizontalAlignment.Center

local cards = {}
for _, r in ipairs(ROLES) do
	local c = Instance.new("TextButton", row) c.Size = UDim2.fromOffset(220, 300) c.Text = "" c.AutoButtonColor = r.enabled
	c.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
	Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke", c) st.Thickness = 2 st.Color = r.color st.Transparency = 0.5
	txt(c, UDim2.fromOffset(0, 14), UDim2.new(1, 0, 0, 60), r.icon, 48, Enum.Font.GothamBold).TextColor3 = r.color
	txt(c, UDim2.fromOffset(0, 78), UDim2.new(1, 0, 0, 26), r.name, 20, Enum.Font.GothamBlack).TextColor3 = r.color
	local d = txt(c, UDim2.fromOffset(12, 110), UDim2.new(1, -24, 0, 130), r.desc, 13) d.TextYAlignment = Enum.TextYAlignment.Top
	local owner = txt(c, UDim2.new(0, 0, 1, -48), UDim2.new(1, 0, 0, 36), "", 15, Enum.Font.GothamBold)
	if not r.enabled then c.BackgroundTransparency = 0.5 owner.Text = "🔒 Chưa mở" owner.TextColor3 = Color3.fromRGB(150, 150, 150) end
	c.MouseButton1Click:Connect(function() if r.enabled then Remotes.UseSkill:FireServer("PickRole", r.id) end end)
	cards[r.id] = {btn = c, stroke = st, owner = owner, role = r}
end

local ready = Instance.new("TextButton", bg) ready.AnchorPoint = Vector2.new(0.5, 1) ready.Position = UDim2.new(0.5, 0, 0.9, 0) ready.Size = UDim2.fromOffset(260, 54)
ready.Font = Enum.Font.GothamBlack ready.TextSize = 22 ready.TextColor3 = Color3.new(1, 1, 1) ready.Modal = true -- giải phóng chuột ở góc nhìn thứ nhất
Instance.new("UICorner", ready).CornerRadius = UDim.new(0, 12)
ready.MouseButton1Click:Connect(function() Remotes.UseSkill:FireServer("Ready") end)
local status = txt(bg, UDim2.new(0, 0, 0.9, 8), UDim2.new(1, 0, 0, 24), "", 16, Enum.Font.GothamBold)

RunService.RenderStepped:Connect(function()
	local inLobby = State:GetAttribute("Phase") == "Lobby" and not workspace:GetAttribute("TestLevel2")
	bg.Visible = inLobby
	if not inLobby then return end
	local owners = {}
	local total, readyN = 0, 0
	for _, p in ipairs(Players:GetPlayers()) do
		total += 1
		if p:GetAttribute("Ready") then readyN += 1 end
		local r = p:GetAttribute("Role") if r then owners[r] = p end
	end
	for id, c in pairs(cards) do
		if c.role.enabled then
			local o = owners[id]
			if o == plr then
				c.owner.Text = "✔ BẠN" .. (plr:GetAttribute("Ready") and " (sẵn sàng)" or "") c.owner.TextColor3 = c.role.color
				c.stroke.Thickness = 4 c.stroke.Transparency = 0 c.btn.BackgroundColor3 = Color3.fromRGB(40, 34, 62)
			elseif o then
				c.owner.Text = o.DisplayName .. (o:GetAttribute("Ready") and " ✔" or "") c.owner.TextColor3 = Color3.fromRGB(200, 200, 200)
				c.stroke.Thickness = 2 c.stroke.Transparency = 0.7 c.btn.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
			else
				c.owner.Text = "Trống — bấm để chọn" c.owner.TextColor3 = Color3.fromRGB(170, 170, 190)
				c.stroke.Thickness = 2 c.stroke.Transparency = 0.5 c.btn.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
			end
		end
	end
	local me = plr:GetAttribute("Role")
	local isReady = plr:GetAttribute("Ready")
	ready.Text = not me and "CHỌN MỘT VAI" or (isReady and "HỦY SẴN SÀNG" or "SẴN SÀNG")
	ready.BackgroundColor3 = not me and Color3.fromRGB(60, 60, 70) or (isReady and Color3.fromRGB(140, 60, 70) or Color3.fromRGB(60, 150, 100))
	local startAt = State:GetAttribute("LobbyStartAt") or 0
	if startAt > 0 then
		status.Text = "Bắt đầu sau " .. math.max(0, math.ceil(startAt - workspace:GetServerTimeNow())) .. "..."
		status.TextColor3 = Color3.fromRGB(255, 220, 120)
	else
		status.Text = "Sẵn sàng: " .. readyN .. "/" .. total .. " người chơi"
		status.TextColor3 = Color3.fromRGB(200, 200, 220)
	end
end)
