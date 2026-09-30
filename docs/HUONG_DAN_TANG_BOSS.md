# Tầng Boss — "Căn Nhà Của Người Ngủ"

Hướng dẫn cho nhóm: ý tưởng màn boss + cách dựng nó trong VS Code (Rojo) từ bộ code khởi đầu đi kèm.

---

## 1. Ý tưởng (bản 1 trang để nhóm duyệt)

**Cốt truyện chốt.** Ba tầng trước là giấc mơ của **Minh**, một cậu bé đang hôn mê ở **giường 13**:
tên cậu trong sổ của cô (T1), "bệnh nhân giường 13 chưa bao giờ chết" (T2), chiếc la bàn gãy làm cậu lạc (T3).
**Kẻ Gieo Mộng** là *"Người Kể Chuyện Trước Giờ Ngủ"*: nó hứa kể chuyện cho Minh hết sợ, rồi giữ cậu trong mơ mãi.
Các kẻ địch ở tầng trước chỉ là **mặt nạ** của nó. Minh sắp tỉnh, nên nó cần **một người ngủ mới**: chính nhóm người chơi.

**Map:** 1 nơi an toàn + 4 phòng có luật.

| Khu | Thực thể | Chu kỳ | Luật (phạt, chưa tính +5) |
|---|---|---|---|
| **Phòng ngủ của Minh** (Lobby, an toàn) | — | Đèn ngủ hồi Tỉnh táo, vùng sáng co lại theo Độ Sâu | Không có luật |
| **Lớp học trong tủ sách** (Room1) | Mặt nạ Cô Giáo | Viết bảng 10–14s → "E hèm" 2s → quay xuống 5s | Cô quay xuống thì không di chuyển (10) · Tên ai trên bảng, người đó lên bục trước khi cô quay xuống (15) · Bục chỉ dành cho người có tên (8) · **Mực đỏ 1:** cô quay xuống thì phải nhìn thẳng vào cô (8) |
| **Phòng chờ dưới gầm giường** (Room2) | Mặt nạ Thu Ngân | Im 12–16s → chuông 2s → loa gọi số 6s | Chỉ lên quầy khi số của mình được gọi (8) · Loa gọi SỐ 00 thì ngồi vào hàng ghế (10) · Đèn quầy đỏ thì không lại gần quầy (8) |
| **Khu rừng trong bức tranh** (Room3) | Đom đóm | Sáng 16s → nháy 2s → tắt 6s | Đom đóm tắt thì đứng yên (8), **Mực đỏ 2** đổi thành: không đứng yên quá 2 giây · Không bước ra khỏi khung tranh (10) · Không Ping (8) |
| **Phòng khách** (Room4) | **Kẻ Gieo Mộng** trên ghế bành | Đọc 15–20s → gập sách 2s → ngẩng lên 5s | Không bước vào bóng ghế bành (15) · Nó ngẩng lên thì nhìn thẳng vào nó (8) · Không nhảy khi nó đang đọc (8) |

**Cơ chế riêng của boss**

- **Lật Trang (khoảng mỗi 40 giây).** Có tiếng lật sách và đèn ngủ nháy 3 giây để báo trước. Sau đó 1 trong 3 phòng thành *"chương đang kể"* trong 20 giây, và mọi nhịp của phòng đó nhanh hơn khoảng 1,7 lần.
  - Bói Toán thấy trước chương kế tiếp.
  - Người Neo cắm Neo trong phòng khách thì trang sách bị hoãn.
  - Trong lúc Truy Nguyên, mỗi lần lật trang các cuốn truyện trên kệ đổi chỗ.
- **Độ Sâu Giấc Mộng.** Thanh 3 khúc ở giữa màn hình. Mất 1 khúc mỗi khi giải câu đố, thanh tẩy xong, và khi Cổng mở. Mỗi lần mất khúc, đèn ngủ co lại, mặt nạ đổi màu đỏ dần, tiếng thì thầm to lên.
- **Mực Đỏ.** Khi mất khúc 1 và khúc 2, Kẻ Gieo Mộng viết lại một luật. Trước 5 giây có báo hiệu: tiếng bút và tờ nội quy phát sáng. Dòng mực đỏ luôn đúng. *Chỗ này cố ý phá lệ "chữ in luôn đúng".*

**5 giai đoạn**

1. **Trinh Sát.** Tìm 3 dấu hiệu, tài liệu đi kèm là *Sổ trực của mẹ* (chỉ ghi KHI NÀO):
   - Bảng đen hiện tên **MINH** lúc cô quay xuống (Giác quan).
   - Loa gọi **số 13**, cứ 3 lượt một lần (Nhịp thời gian).
   - **Cậu bé trong tranh** hiện khi Ngưỡng Thức < 70 hoặc sau 3 phút, đúng lúc đom đóm sáng lại (Trạng thái nhóm).
2. **Truy Nguyên.** Có 5 cuốn truyện trên kệ phòng ngủ. Chỉ 1 cuốn khớp cả 3 ký ức: *tên MINH · số 13 · hình la bàn*. Chọn sai −8.
3. **Thanh Tẩy (đỉnh của tầng).** Cuốn truyện hiện trên bàn cô giáo. Mang nó qua phòng ngủ tới **lò sưởi phòng khách** và giữ E 8 giây. Quá 90 giây thì sách tái sinh.
   - Người cầm sách đi chậm (12). **Kẻ Gieo Mộng rời ghế và rượt theo** (tốc độ 10, chạm vào −20).
   - Click để **thả sách** cho đồng đội nhặt, nó sẽ mất dấu 3 giây.
   - Neo hoặc Bài Ru làm nó đứng yên. Nó không vào được phòng ngủ.
4. **Neo.** 3 kỷ vật, cả 3 đều là phần thưởng cho việc tuân luật:
   - **Viên phấn:** lên bục đúng lúc.
   - **Vòng tay bệnh viện:** trình số đúng lượt.
   - **Kim la bàn:** làm đúng luật trọn một lần đom đóm tắt.
5. **Cổng.** Cửa sổ bình minh, 12 giây, Người Neo chống cửa được thêm +5 giây.

**Dòng nói dối (1 trong 4, ngẫu nhiên)** và **Trang Cuối**. Trang Cuối nằm ở đúng phòng mà dòng nói dối nhắc tới. Sổ của mẹ có gợi ý: *"nó ở nơi mà lời nói dối muốn con tránh xa"*. Thấu Thị đứng ở phòng ngủ sẽ thấy dòng nói dối đỏ lên.

**3 kết cục** (thua vì cả nhóm Hòa Mộng thì chỉ chơi lại, không tính là kết cục):

| Kết cục | Điều kiện |
|---|---|
| **Bình Minh** | Khi Cổng mở, người giữ Trang Cuối đứng ở giường Minh giữ E 6 giây, rồi **cả nhóm** qua cửa sổ |
| **Giấc Mộng Tiếp Diễn** | Cả nhóm thoát nhưng không đọc Trang Cuối |
| **Người Kể Chuyện Mới** | Có ít nhất 1 người qua cửa sổ nhưng có người bị bỏ lại (bị nhốt khi cửa đóng, hoặc đang Hòa Mộng mà không ai kéo về) |

---

## 2. Bộ code khởi đầu có gì

Giải nén gói `DreamLayers_TangBoss.zip` **đè lên thư mục gốc của repo**:

| File | Mới / sửa | Làm gì |
|---|---|---|
| `tools/build-map4.luau` | mới | Script Lune dựng map khối thô → `map/DreamMap4.rbxm` |
| `map/DreamMap4.rbxm` | mới | Map đã dựng sẵn (chạy lại script ở trên nếu sửa bố cục) |
| `src/ServerScriptService/Level4Manager.server.lua` | mới | Toàn bộ logic tầng boss (luật, thực thể, lật trang, rượt đuổi, 3 kết cục) |
| `src/StarterPlayer/StarterPlayerScripts/Level4Client.client.lua` | mới | Nội quy + mực đỏ, sổ của mẹ, HUD, thanh Độ Sâu, Lớp Sự Thật, màn kết cục |
| `src/StarterPlayer/StarterPlayerScripts/RoleFX.client.lua` | sửa | Thêm Tầng 4 cho giới thiệu vai, Điềm Báo, Mắt Đêm, bản đồ nhanh |
| `default.project.json` | sửa | Thêm `Workspace.DreamMap4` |
| `tools/export-maps.luau` | sửa | Xuất thêm DreamMap4 khi syncback |

Map đặt ở khoảng z = 1860–2160 nên không chồng lên Tầng 3 (z 1259–1546). Tên trong `Interactables` là "hợp đồng" với code. Đã kiểm tra tự động: đủ 39 vật, không thiếu tên nào.

---

## 3. Làm từng bước trong VS Code

### Bước 0 — Chuẩn bị (một lần)
1. Cài **VS Code**, extension **Rojo** và **Luau Language Server**.
2. Mở terminal trong thư mục repo và chạy `aftman install`. Lệnh này cài `rojo` và `lune` theo `aftman.toml`.
3. Tạo nhánh riêng: `git checkout -b tang-boss`.

### Bước 1 — Chép bộ code vào repo
1. Giải nén `DreamLayers_TangBoss.zip` vào thư mục gốc repo, chọn *Replace* khi được hỏi.
2. Chạy `git status`. Sẽ thấy đúng 8 file: 7 file trong bảng mục 2 và file hướng dẫn này.

### Bước 2 — Dựng map
```
lune run tools/build-map4.luau
```
Kết quả in ra `map/DreamMap4.rbxm  246`. Chỉ cần chạy lại khi sửa bố cục trong script. Nếu Builder trang trí trong Studio thì làm theo Bước 6.

### Bước 3 — Chạy trong Studio
1. VS Code: `Ctrl+Shift+P` → **Rojo: Start server**.
2. Mở place trong Studio → **Plugins → Rojo → Connect**. Workspace sẽ có `DreamMap4`, ServerScriptService có `Level4Manager`.
3. Test nhanh tầng boss: chọn **Workspace**, thêm thuộc tính số `TestLevel = 4`.
4. **Test → Clients and Servers → 2 Players** (hoặc 4). Chọn vai, bấm Sẵn sàng, game vào thẳng tầng boss.

### Bước 4 — Lệnh debug (tab Server, Command Bar)
```lua
local D = game.ServerStorage.CoreDebug
D:Invoke("lv", "signs")  -- ghi nhận đủ 3 dấu hiệu → Truy Nguyên
D:Invoke("lv", "thanh")  -- nhảy tới Truy Nguyên, in ra số thứ tự cuốn truyện đúng
D:Invoke("lv", "neo")    -- coi như đã thanh tẩy + có 3 Mảnh Neo → đặt vào Bệ Neo để mở Cổng
D:Invoke("lv", "page")   -- đưa Trang Cuối cho người chơi đầu tiên (test kết cục Bình Minh)
D:Invoke("log")          -- tóm tắt playtest: thời gian từng giai đoạn, luật hay bị phạm
```
Output in dòng `[PLAYTEST] ... ending dawn|loop|left` khi thắng.

### Bước 5 — Chỉnh độ khó
Mọi con số nằm trong bảng `C` ở đầu `Level4Manager.server.lua`:

| Khóa | Mặc định | Ý nghĩa |
|---|---|---|
| `PAGE_EVERY` / `CHAPTER_LEN` / `CHAPTER_SPEED` | 40 / 20 / 0.6 | Nhịp lật trang và độ gắt của "chương đang kể" |
| `SEEDER_SPEED` / `CARRY_SPEED` | 10 / 12 | Boss chậm hơn người cầm sách **2 stud/giây**. Hạ khoảng cách này xuống thì màn khó hơn |
| `FIRE_HOLD` | 8 | Số giây giữ E ở lò sưởi (khoảnh khắc cả đội phải bảo vệ) |
| `BOOK_TIME` | 90 | Giới hạn Thanh Tẩy, theo chuẩn |
| `NIGHT_RADIUS` | 30/22/15 | Vùng sáng của đèn ngủ theo Độ Sâu |
| `ESCAPE_TIME` | 12 | Thời gian chạy về cửa sổ |

Mức phạt ghi ngay trong từng lệnh `violate(...)`. Hệ thống tự cộng thêm 5 (`Core.EXTRA_PENALTY`).

### Bước 6 — Trang trí map (Builder)
1. Trong Studio, trang trí `Workspace.DreamMap4`: thay khối Teacher, Cashier, Seeder bằng model đẹp nhưng **giữ tên Model và Part `Head`**, thêm đồ nội thất vào `Props/`.
2. **Gắn âm thanh**: các Sound đang để `SoundId` trống: `NightLight.PageFlip`, `Blackboard.Chalk`, `Teacher.Head.Ahem`, `QueueBoard.Chime`, `Seeder.Head.Whisper`. Thiếu âm thanh thì game vẫn chạy.
3. Lưu lại: ngắt Rojo → **File → Download a Copy** → `DreamLayers.rbxl` → `rojo syncback --input DreamLayers.rbxl --non-interactive` → `lune run tools/export-maps.luau`.
4. **Không đổi tên** gì trong `Interactables`, `Zones`, `Doors` khi chưa báo người viết code.

### Bước 7 — Kiểm tra trước khi gộp (theo "Nguyên tắc xây tầng", mục 8)
- [ ] Chơi hết 5 giai đoạn, và ra được **cả 3 kết cục**:
  - Bình Minh: dùng `page` rồi đọc ở giường.
  - Tiếp Diễn: không đọc.
  - Người Kể Chuyện Mới: để 1 người đứng ngoài phòng ngủ khi cửa đóng.
- [ ] Mỗi luật: tuân thì không bị phạt, phạm thì bị phạt đúng mức, và luật không lan sang phòng khác. Đặc biệt kiểm tra 2 dòng mực đỏ sau khi chúng hiện.
- [ ] Phòng chỉ "thức dậy" khi có người vào. Chơi lại sau khi cả nhóm Hòa Mộng thì mọi thứ reset sạch: Độ Sâu về 3, không còn mực đỏ, trang cuối đổi chỗ.
- [ ] 4 vai đều dùng được ở mọi phòng. Neo làm Kẻ Gieo Mộng đứng yên lúc rượt, và làm trang sách bị hoãn.
- [ ] Thả sách (click) thì boss mất dấu. Người cầm sách Hòa Mộng thì sách về bàn cô.
- [ ] Không có lỗi đỏ trong Output. Nội dung hợp lứa tuổi 12+.

### Bước 8 — Đẩy lên
`git add -A` → `git commit -m "Tầng boss: Căn Nhà Của Người Ngủ"` → push nhánh → mở Pull Request cho nhóm duyệt.

---

## 4. Nếu nhóm giữ đúng GDD (boss là Tầng 6)
Đổi hết số 4 thành 6 như sau:

1. Đổi tên file thành `Level6Manager.server.lua`, `Level6Client.client.lua`, `build-map6.luau`.
2. Trong 3 file đó, thay `DreamMap4` → `DreamMap6`, `GameState4` → `GameState6`, thuộc tính `Room4` → `Room6`, và `local LV = 4` → `6`.
3. Trong `RoleFX.client.lua`, đổi các chỗ `[4]` và `l == 4` thành 6.
4. Trong `default.project.json` và `export-maps.luau`, đổi `DreamMap4` → `DreamMap6`.

Khi Tầng 4 và 5 xong, `Core.finishLevel` sẽ tự nối 5 → 6.

## 5. Ý tưởng mở rộng (chưa làm)
- Kết cục *Người Kể Chuyện Mới*: lưu tên vai bị bỏ lại vào `ReplicatedStorage`, rồi cho bảng đen Tầng 1 viết tên đó ở lượt chơi sau. Cần sửa `GameManager`.
- Khi mất khúc Độ Sâu, cho mặt nạ của thực thể trong phòng rơi xuống thật (hiệu ứng rơi và âm thanh).
