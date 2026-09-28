-- Xuất map (tên trùng nhau nên syncback không tách được) từ DreamLayers.rbxl ra file .rbxm
-- Chạy: lune run tools/export-maps.luau
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local game = roblox.deserializePlace(fs.readFile("DreamLayers.rbxl"))
local function save(inst, path)
	fs.writeFile(path, roblox.serializeModel({ inst }))
	print(path, #inst:GetDescendants())
end
save(game.Workspace.DreamMap, "map/DreamMap.rbxm")
save(game.Workspace.DreamMap2, "map/DreamMap2.rbxm")
save(game.Workspace.DreamMap3, "map/DreamMap3.rbxm")
save(game.ReplicatedStorage.L2Ambience, "shared/L2Ambience.rbxm")
