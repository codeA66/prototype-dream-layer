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
