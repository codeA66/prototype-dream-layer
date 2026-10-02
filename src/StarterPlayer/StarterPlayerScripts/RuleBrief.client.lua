-- BẢNG LUẬT TÓM TẮT (cả 3 tầng): hiện ngay khi vào tầng, mỗi luật vài chữ. H để mở lại.
-- Tờ nội quy chi tiết vẫn giữ nguyên, ai muốn đọc kỹ thì nhặt giấy.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer

local BRIEF = {
	[1] = {
		title = "TẦNG 1 — TRƯỜNG HỌC", state = "GameState", lieAttr = "LieIndex1", safe = "Hành lang",
		rooms = {
			{"LỚP HỌC", {"Cô nhìn → đứng yên", "Làm việc cô nhờ", "Bị gọi tên → về bàn, giữ E", "✎ Không nhận tên lạ"}},
			{"THƯ VIỆN", {"Không nhảy", "Không Ping", "Không đứng sát nhau"}},
			{"PHÒNG NHẠC", {"Nhạc vang → đi lại", "Nhạc tắt → đứng yên", "Không chạm đàn"}},
		},
		lies = {{1, "Đứng cạnh bàn → đi thoải mái"}, {2, "Thì thầm sát nhau không sao"}, {3, "Nhạc tắt → chạy ra cửa"}, {1, "Trả lời thay bạn được"}},
	},
	[2] = {
		title = "TẦNG 2 — BỆNH VIỆN", state = "GameState2", lieAttr = "LieIndex", safe = "Sảnh tiếp đón",
		rooms = {
			{"PHẪU THUẬT", {"Không chạm bàn mổ", "Bị hỏi → người gần bàn nằm lên", "Đeo khẩu trang"}},
			{"ĐÓNG PHÍ", {"Trả bằng Phiếu Khám", "Thu ngân cười → không trả", "Chờ gọi số"}},
			{"NHÀ XÁC", {"Đèn tắt → trốn tủ xác", "Tránh đèn pin", "Số xác đổi → ra cửa sau"}},
			{"Ô NHIỄM", {"Mặc đồ bảo hộ", "Đồ có vết đen → cởi", "Rửa tay trước khi ra", "Tránh miệng gió"}},
			{"LOA GỌI TÊN", {"Tới đúng phòng trong 40s"}},
		},
		lies = {{1, "Đèn mổ bật → chạy ra"}, {2, "Thu ngân cười là người thật"}, {3, "Đèn tắt → chạy ra cửa chính"}, {4, "Đứng dưới gió ĐỎ"}},
	},
	[3] = {
		title = "TẦNG 3 — KHU RỪNG", state = "GameState3", lieAttr = "LieIndex", safe = "Lửa trại",
		rooms = {
			{"ĐOM ĐÓM", {"Đi lối đá trắng", "Đom đóm tắt → đứng yên", "Không bắt đom đóm"}},
			{"ĐẦM SƯƠNG", {"Chuông gió → ở trên đá", "Không nhìn nước lâu", "Cầu: 1 người"}},
			{"CÂY CỔ THỤ", {"Không chat", "Cây mở mắt → quay lưng", "Không giẫm rễ sáng"}},
			{"HANG GỖ", {"Tiếng gõ → nép vào hốc", "Không nhảy", "Đếm tiếng gõ, ra gõ lại đủ"}},
			{"VƯỜN NẤM", {"Nấm sáng → nín thở (B)", "Không hái gì", "Chỉ vào vòng trắng"}},
		},
		lies = {{1, "Đom đóm tắt → chạy"}, {3, "Cây mở mắt → nhìn thẳng"}, {4, "Tiếng gõ → chạy ra"}, {5, "Nấm sáng → ăn nấm"}},
	},
}

local gui = Instance.new("ScreenGui") gui.Name = "RuleBriefGui" gui.ResetOnSpawn = false gui.DisplayOrder = 12
gui.Parent = plr:WaitForChild("PlayerGui")
local board = Instance.new("Frame", gui) board.AnchorPoint = Vector2.new(0.5, 0.5) board.Position = UDim2.fromScale(0.5, 0.5)
board.Size = UDim2.fromOffset(600, 420) board.BackgroundColor3 = Color3.fromRGB(28, 34, 30) board.BorderSizePixel = 0 board.Visible = false
Instance.new("UICorner", board).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", board) st.Thickness = 6 st.Color = Color3.fromRGB(95, 70, 45)
local sc = Instance.new("UIScale", board)
local function fit() local v = workspace.CurrentCamera.ViewportSize sc.Scale = math.min(1, v.X / 640, v.Y / 460) end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local body = Instance.new("TextLabel", board) body.BackgroundTransparency = 1 body.Position = UDim2.fromOffset(26, 18) body.Size = UDim2.new(1, -52, 1, -76)
body.Font = Enum.Font.GothamMedium body.TextSize = 17 body.TextColor3 = Color3.fromRGB(240, 236, 220) body.RichText = true body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top
local ok = Instance.new("TextButton", board) ok.Size = UDim2.fromOffset(200, 36) ok.Position = UDim2.new(0.5, -100, 1, -50)
ok.Text = "Đã hiểu (H để xem lại)" ok.Font = Enum.Font.GothamBold ok.TextSize = 15 ok.TextColor3 = Color3.new(1, 1, 1)
ok.BackgroundColor3 = Color3.fromRGB(95, 70, 45) ok.Modal = true
Instance.new("UICorner", ok).CornerRadius = UDim.new(0, 6)
ok.MouseButton1Click:Connect(function() board.Visible = false end)

local function render(lv)
	local b = BRIEF[lv] if not b then return false end
	local stObj = RS:FindFirstChild(b.state)
	local lie = b.lies[(stObj and stObj:GetAttribute(b.lieAttr)) or 0]
	local out = {'<font size="26"><b>' .. b.title .. '</b></font>',
		'<font size="14" color="#B8C8A0">An toàn: ' .. b.safe .. ' · ✎ = viết tay, 1 dòng là NÓI DỐI</font>', ""}
	for i, room in ipairs(b.rooms) do
		local lines = {}
		for _, r in ipairs(room[2]) do table.insert(lines, r) end
		if lie and lie[1] == i then table.insert(lines, 2, "✎ " .. lie[2]) end
		table.insert(out, '<font color="#FFD98A"><b>' .. room[1] .. ":</b></font>  " .. table.concat(lines, "  ·  "))
	end
	body.Text = table.concat(out, "\n")
	return true
end
local function show() if render(plr:GetAttribute("Level")) then board.Visible = true end end

plr:GetAttributeChangedSignal("Level"):Connect(function()
	board.Visible = false
	task.wait(0.5)
	show()
end)
if plr:GetAttribute("Level") then task.defer(show) end
for lv, b in pairs(BRIEF) do -- dòng nói dối chọn khi bắt đầu ván → cập nhật nếu đang mở
	task.spawn(function()
		local stObj = RS:WaitForChild(b.state)
		stObj:GetAttributeChangedSignal(b.lieAttr):Connect(function() if board.Visible and plr:GetAttribute("Level") == lv then render(lv) end end)
	end)
end
UIS.InputBegan:Connect(function(i, gp)
	if gp or i.KeyCode ~= Enum.KeyCode.H then return end
	if board.Visible then board.Visible = false else show() end
end)
