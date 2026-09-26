# Dream Layers (Tầng Mộng) — prototype

Game kinh dị co-op trên Roblox. Cả nhóm bị kéo vào giấc mộng, phải tuân theo luật của từng phòng để thoát qua từng tầng.

- **Tầng 1 — Lớp Học Vỡ:** Lớp học, Thư viện, Phòng nhạc
- **Tầng 2 — Bệnh Viện Ngủ Quên:** Phẫu thuật, Đóng phí, Nhà xác, Phòng ô nhiễm
- **4 vai:** Thấu Thị, Chữa Lành, Người Neo, Nhà Bói Toán

## Cấu trúc code

```
src/
  ServerScriptService/
    LevelCore.lua              ModuleScript: hệ thống chung (Tỉnh táo, luật, kỹ năng, cổng, chuyển tầng)
    GameManager.server.lua     Sảnh + Tầng 1
    Level2Manager.server.lua   Tầng 2
  StarterPlayer/StarterPlayerScripts/
    DreamClient.client.lua     HUD, thanh Tỉnh táo, Nhìn Xuyên
    DreamPolish.client.lua     Nút kỹ năng, điểm danh, tiết học, màn thắng/thua
    RoleFX.client.lua          Giới thiệu vai, lá quẻ, Neo/Ru, Sợi Chỉ Đỏ, Mắt Đêm
    RuleBook.client.lua        Sổ tay, nội quy Tầng 1, nhật ký
    Level2Client.client.lua    Giao diện Tầng 2
    Lobby.client.lua           Chọn vai
docs/
  Luat_va_Gameplay_Tang1_Dream_Layers.docx
```

Tên file theo quy ước Rojo (`.server.lua` = Script, `.client.lua` = LocalScript, `.lua` = ModuleScript).
Map, âm thanh, Remotes nằm trong file place của Roblox Studio, không có trong repo.

## Làm việc với Rojo

1. Cài VS Code + extension **Rojo** (extension sẽ cài plugin Rojo cho Studio).
2. Mở thư mục repo trong VS Code → `Ctrl+Shift+P` → **Rojo: Start server**.
3. Mở place trong Studio → tab **Plugins → Rojo → Connect**.
4. Sửa code trong `src/` bằng VS Code, Studio tự cập nhật. **Không sửa script trong Studio** (sẽ bị Rojo ghi đè).
5. Commit + push bằng GitHub Desktop hoặc `git`.

Map, quái, âm thanh, Remotes vẫn nằm trong file place (`.rbxl`).

## Map và đối tượng trong game (Rojo syncback)

Repo chứa cả map và đối tượng, `rojo build -o DreamLayers.rbxl` dựng lại được cả game.

| Thư mục | Nội dung |
|---|---|
| `map/DreamMap.rbxm`, `map/DreamMap2.rbxm` | Map Tầng 1, Tầng 2 |
| `shared/Remotes`, `shared/DreamSounds`, `shared/L2Ambience.rbxm` | ReplicatedStorage |
| `shared/Lighting` | Hiệu ứng ánh sáng (thuộc tính Lighting nằm trong `default.project.json`) |

**Sau khi sửa map trong Studio:**

1. Ngắt Rojo (Disconnect + Stop server).
2. Studio: **File → Download a Copy** → lưu đè `DreamLayers.rbxl` trong repo.
3. Terminal: `aftman install` (lần đầu), rồi
   ```
   rojo syncback --input DreamLayers.rbxl --non-interactive
   lune run tools/export-maps.luau
   ```
4. Commit + push.

Map có nhiều đối tượng trùng tên (Desk, Wall…) nên `syncback` không tách được map; `tools/export-maps.luau` xuất map ra `.rbxm`.
**Luôn syncback trước khi Connect Rojo**, nếu không Rojo sẽ ghi đè map trong Studio bằng bản cũ trong repo.
