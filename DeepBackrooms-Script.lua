if not game:IsLoaded() then
	game.Loaded:Wait()
end

getgenv().webhook = getgenv().webhook or "Your_Webhook_URL"
getgenv().discordId = getgenv().discordId or "Your_Discord_ID"

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local execName = "Unknown"
pcall(function()
	execName = identifyexecutor()
end)

if execName == "Xeno" or execName == "Solara" then
	Players.LocalPlayer:Kick("Unsupported Executor")
	return
end

repeat task.wait() until game.ReplicatedStorage:FindFirstChild("Library")

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local InstancingCmds = require(game.ReplicatedStorage.Library.Client.InstancingCmds)
local MiscItem = require(game.ReplicatedStorage.Library.Items.MiscItem)
local EggCmds = require(game.ReplicatedStorage.Library.Client.EggCmds)
local CustomEggsCmds = require(game.ReplicatedStorage.Library.Client.CustomEggsCmds)
local PlayerPet = require(game.ReplicatedStorage.Library.Client.PlayerPet)
local Signal = require(game.ReplicatedStorage.Library.Signal)
local Types = require(game.ReplicatedStorage.Library.Items.Types)
local NumberShorten = require(game.ReplicatedStorage.Library.Functions.NumberShorten)
local InventoryCmds = require(game.ReplicatedStorage.Library.Client.InventoryCmds)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

local localPlayer = Players.LocalPlayer
local enterPosition = nil
local doneCleaning = false
local httpRequest = request or http_request or (syn and syn.request)

local roomsToStore = {
	"DeepCoinRoom1", "DeepCoinRoom2", "DeepCoinRoom3",
	"DeepChestRoom1", "DeepChestRoom2", "DeepChestRoom3",
	"DeepFreeEggRoom1", "DeepFreeEggRoom2", "DeepLockedEggRoom",
	"GameMastersStage",
}

local seenPets = {}
task.spawn(function()
	while not Save.Get() do
		task.wait()
	end
	local container = InventoryCmds.Container(localPlayer)
	for itemUID, item in pairs(container:All()) do
		if item:IsA("Pet") then
			local exclusiveLevel = item:GetExclusiveLevel()
			if exclusiveLevel and exclusiveLevel > 3 then
				seenPets[itemUID] = true
			end
		end
	end
end)

local oldCalculate = PlayerPet.CalculateSpeedMultiplier
PlayerPet.CalculateSpeedMultiplier = function(self, ...)
	if _G.InfinitePetSpeed then
		return 100000
	end
	return oldCalculate(self, ...)
end

if _G.ExecutedScript then
	pcall(function()
		local pg = localPlayer:FindFirstChild("PlayerGui")
		if pg then
			for _, gui in ipairs(pg:GetChildren()) do
				if gui.Name == "Rayfield" then
					gui:Destroy()
				end
			end
		end
	end)
end
_G.ExecutedScript = true

_G.ScannedRooms = {}
_G.ScannedRoomsMap = {}
_G.VistedRooms = {}
_G.IsScanning = false
_G.Teleporting = false
_G.AutoHatch = false
_G.AutoTPBestEgg = false
_G.AutoMiniBoss = false
_G.AutoBossChest = false
_G.AutoMiniChest = false
_G.AutoCoinRoom = false
_G.AutoTPLockedEgg = false
_G.AutoTPAnomaly = false
_G.InfinitePetSpeed = false
_G.AutoTapper = false
_G.SelectedLockedEggMult = "Any"

local AutoBestEgg
local AutoLockedEgg
local AutoAnomaly
local AutoHatchToggle
local AutoFarmBoss
local AutoBossChestToggle
local AutoMiniChestToggle
local AutoCoinRoomToggle
local StatusLabel

local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local function tryEnterBackrooms()
	local things = workspace:FindFirstChild("__THINGS")
	if not things then return end
	local instances = things:FindFirstChild("Instances")
	if not instances then return end
	local backrooms = instances:FindFirstChild("Backrooms")
	if not backrooms then return end
	local teleports = backrooms:FindFirstChild("Teleports")
	if not teleports then return end
	local enter = teleports:FindFirstChild("Enter")
	if not enter then return end
	local character = getCharacter()
	if character then
		character:PivotTo(enter.CFrame)
	end
end

task.spawn(tryEnterBackrooms)

local function createMessage(msg)
	if workspace:FindFirstChildOfClass("Message") then
		return workspace:FindFirstChildOfClass("Message")
	end
	local message = Instance.new("Message", workspace)
	message.Text = msg
	return message
end

local function getGeneratedBackrooms()
	local things = workspace:FindFirstChild("__THINGS")
	if not things then return nil end
	local container = things:FindFirstChild("__INSTANCE_CONTAINER")
	if not container then return nil end
	local active = container:FindFirstChild("Active")
	if not active then return nil end
	local backrooms = active:WaitForChild("Backrooms", 3)
	if not backrooms then return nil end
	return backrooms:FindFirstChild("GeneratedBackrooms")
end

local function findRoomDataByUID(roomUID)
	return _G.ScannedRoomsMap[roomUID]
end

local function getNearestEgg()
	local character = getCharacter()
	if typeof(character) ~= "Model" then return end
	local closestEgg, minDist = nil, 40
	for _, egg in pairs(CustomEggsCmds.All()) do
		if egg._position then
			local dist = (egg._position - character:GetPivot().Position).Magnitude
			if dist < minDist then
				minDist = dist
				closestEgg = egg
			end
		end
	end
	return closestEgg
end

local function isPlayerInRoom(roomData)
	if not roomData then return false end
	local character = getCharacter()
	if not character then return false end
	local roomCFrame, roomSize = roomData.Model:GetBoundingBox()
	local localPoint = roomCFrame:PointToObjectSpace(character:GetPivot().Position)
	return math.abs(localPoint.X) <= roomSize.X / 2 + 20
		and math.abs(localPoint.Y) <= roomSize.Y / 2 + 35
		and math.abs(localPoint.Z) <= roomSize.Z / 2 + 20
end

local function getBestEggRoom()
	local bestRoom, maxMult = nil, -1
	for _, room in ipairs(_G.ScannedRooms) do
		if string.match(room.Id, "DeepFreeEggRoom") and room.EggMultiplier and room.EggMultiplier > maxMult then
			maxMult = room.EggMultiplier
			bestRoom = room
		end
	end
	return bestRoom
end

local function getBestLockedEggRoom()
	local bestRoom, maxMult = nil, -1
	local targetMult = (_G.SelectedLockedEggMult and _G.SelectedLockedEggMult ~= "Any")
		and tonumber(string.match(_G.SelectedLockedEggMult, "%d+"))
		or nil
	for _, room in ipairs(_G.ScannedRooms) do
		if room.Id == "DeepLockedEggRoom" and room.EggMultiplier then
			if (not room.ExpireTime) or room.ExpireTime - workspace:GetServerTimeNow() > 0 then
				if (not targetMult or room.EggMultiplier >= targetMult) and room.EggMultiplier > maxMult then
					maxMult = room.EggMultiplier
					bestRoom = room
				end
			end
		end
	end
	return bestRoom
end

local function findRoomByPattern(pattern)
	for _, room in ipairs(_G.ScannedRooms) do
		if string.match(room.Id, pattern) then
			return room
		end
	end
end

local function findBossRoom()
	for _, room in ipairs(_G.ScannedRooms) do
		if room.Id == "GameMastersStage" then
			return room
		end
	end
end

local function keyCheck()
	local keyItem = MiscItem("Deep Backrooms Crayon Key")
	return keyItem and keyItem:HasAny()
end

local function UnlockRoom(roomUID)
	if _G.IsScanning or not keyCheck() then return end
	local character = getCharacter()
	if not character then return end
	local activeInstance = InstancingCmds.Get()
	if not activeInstance then return end
	local roomData = findRoomDataByUID(roomUID)
	if not roomData then return end
	local lockedDoors = roomData.Model:FindFirstChild("LockedDoors")
	if not lockedDoors then return end
	local lockedPart
	for _, child in ipairs(lockedDoors:GetChildren()) do
		local lock = child:FindFirstChild("Lock")
		if lock and lock.Transparency < 1 then
			lockedPart = lock
			break
		end
	end
	if not lockedPart then return end
	character:PivotTo(CFrame.new(lockedPart.Position))
	activeInstance:FireCustom("AbstractRoom_FireServer", roomUID, "UnlockDoors")
end

local function TeleportToRoom(roomUID, isScanning)
	if _G.Teleporting then return end
	_G.Teleporting = true

	local character = getCharacter()
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local roomData = findRoomDataByUID(roomUID)
	if not rootPart or not roomData then
		_G.Teleporting = false
		return
	end

	local roomModel = roomData.Model
	local roomId = roomData.Id
	local pos = roomData.Position
	local centerCF = roomModel:GetBoundingBox()

	local forceField = Instance.new("ForceField")
	forceField.Visible = false
	forceField.Parent = character

	Network.Fire("RequestStreaming", pos)
	rootPart.Anchored = true
	character:PivotTo(centerCF + Vector3.new(0, 10, 0))

	task.delay(2.5, function()
		if forceField.Parent then forceField:Destroy() end
		if not isScanning then rootPart.Anchored = false end
	end)

	if not isScanning then
		task.wait(1.5)
		local targetObj = roomModel:FindFirstChild("Sign")
			or roomModel:FindFirstChild("Backrooms Egg")
			or roomModel:FindFirstChild("BillboardAdornee")
			or roomModel.PrimaryPart
			or roomModel:FindFirstChildWhichIsA("BasePart", true)
		character:PivotTo((targetObj and targetObj.CFrame or CFrame.new(pos)) + Vector3.new(0, 15, 0))

		if roomId == "DeepLockedEggRoom" then
			local activeInstance = InstancingCmds.Get()
			if activeInstance then
				local ok, playerDataList = pcall(function()
					return activeInstance:InvokeCustom("AbstractRoom_GetPlayerData")
				end)
				if ok then
					for _, roomInfo in ipairs(playerDataList) do
						if roomInfo.uid == roomUID and roomInfo.data then
							roomData.ExpireTime = roomInfo.data.UnlockExpireTimestamp
							break
						end
					end
				end
			end
		end

		if roomId == "DeepLockedEggRoom" or roomId == "GameMastersStage" then
			UnlockRoom(roomUID)
		end

		task.wait(0.3)
		character:PivotTo((targetObj and targetObj.CFrame or CFrame.new(pos)) + Vector3.new(0, 15, 0))
	end

	_G.Teleporting = false
end

local function CleanupWalls()
	local folder = getGeneratedBackrooms()
	if not folder then
		doneCleaning = true
		return
	end
	if doneCleaning then return end
	for _, room in ipairs(folder:GetChildren()) do
		if room.Name == "Walls" then
			local children = room:GetChildren()
			for i = 1, #children do
				children[i]:Destroy()
				if i % 15 == 0 then RunService.Heartbeat:Wait() end
			end
			room:Destroy()
		end
	end
	doneCleaning = true
end

local function TPtoSpawn()
	local character = getCharacter()
	if not character or typeof(enterPosition) ~= "Vector3" then return end
	Network.Fire("RequestStreaming", enterPosition)
	character:PivotTo(CFrame.new(enterPosition) + Vector3.new(0, 5, 0))
end

local function Scan()
	if _G.IsScanning then return end
	_G.IsScanning = true
	doneCleaning = false

	local character = getCharacter()
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		_G.IsScanning = false
		return
	end

	local total = 0
	local message = createMessage("Exploring the backrooms! Please wait...")
	StatusLabel:Set("Status: Exploring...")

	local folder = getGeneratedBackrooms()
	if not folder then
		repeat
			task.wait(0.5)
			folder = getGeneratedBackrooms()
			warn("WAITING...")
		until folder and #folder:GetChildren() > 0
	end

	local deepSpawnRoom = folder:WaitForChild("DeepSpawnRoom", 3)
	if deepSpawnRoom then
		local spawnLocation = deepSpawnRoom:FindFirstChild("DEEP_SPAWN_LOCATION")
		if spawnLocation then
			enterPosition = spawnLocation.Position
			Network.Fire("RequestStreaming", enterPosition)
			character:PivotTo(CFrame.new(enterPosition) + Vector3.new(0, 5, 0))
		end
	end

	task.spawn(CleanupWalls)
	repeat
		message.Text = "Changes to unnecessary stuff!"
		task.wait(0.10)
	until doneCleaning
	message.Text = "Exploring the backrooms! Please wait..."

	local function processRoom(room)
		if room:GetAttribute("DeepRoom") ~= true then return end
		local roomUID = room:GetAttribute("RoomUID")
		if not roomUID or _G.ScannedRoomsMap[roomUID] then return end

		local roomId = room:GetAttribute("RoomID")
		local roomCFrame = room:GetPivot()
		local mult = room:GetAttribute("EggMultiplier") or 0
		local roomData = {
			uid = roomUID,
			Id = roomId,
			Model = room,
			CFrame = roomCFrame,
			Position = roomCFrame.Position,
			EggMultiplier = mult > 0 and mult or nil,
		}

		_G.ScannedRoomsMap[roomUID] = roomData
		table.insert(_G.ScannedRooms, roomData)
		total += 1
		StatusLabel:Set("Status: Scanned " .. #_G.ScannedRooms .. " rooms")

		if roomId == "DeepLockedEggRoom" or string.match(roomId, "DeepFreeEggRoom") then
			warn(roomId .. " with " .. mult .. "x mult")
		elseif roomId == "GameMastersStage" then
			warn("Boss room", roomId)
		else
			print(roomId)
		end
	end

	local function runScanPass()
		local gen = getGeneratedBackrooms()
		if not gen then return end
		for _, room in ipairs(gen:GetChildren()) do
			processRoom(room)
		end
	end

	runScanPass()

	while #_G.ScannedRooms < 400 do
		character = getCharacter()
		if not character then
			task.wait(0.5)
			continue
		end
		if _G.Teleporting then
			task.wait(0.5)
			continue
		end

		local nearestRoom, nearestDist = nil, math.huge
		for _, room in ipairs(_G.ScannedRooms) do
			if not _G.VistedRooms[room.uid] then
				local dist = (room.Position - character:GetPivot().Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestRoom = room
				end
			end
		end

		if not nearestRoom then
			warn("No more unvisited rooms.")
			break
		end

		_G.VistedRooms[nearestRoom.uid] = true
		TeleportToRoom(nearestRoom.uid, true)
		task.wait(0.5)
		runScanPass()
	end

	table.clear(_G.VistedRooms)

	for i = #_G.ScannedRooms, 1, -1 do
		local room = _G.ScannedRooms[i]
		if not table.find(roomsToStore, room.Id) then
			_G.ScannedRoomsMap[room.uid] = nil
			table.remove(_G.ScannedRooms, i)
		end
	end

	TPtoSpawn()
	rootPart.Anchored = false
	StatusLabel:Set("Status: Scan Complete! " .. #_G.ScannedRooms .. " valid rooms (" .. total .. " total)")
	game.Debris:AddItem(message, 0)
	_G.IsScanning = false
	warn("Scan finished!")
end

local function canDoAction()
	return not _G.IsScanning and not _G.Teleporting
end

local function isAutoAnomlyActive()
	return _G.AutoTPAnomaly
		and workspace:GetAttribute("BackroomsAnomalyActive") == true
		and type(workspace:GetAttribute("BackroomsAnomalyEndsAt")) == "number"
		and workspace:GetAttribute("BackroomsAnomalyEndsAt") >= workspace:GetServerTimeNow()
end

local function getBreakablesFolder()
	local things = workspace:FindFirstChild("__THINGS")
	return things and things:FindFirstChild("Breakables")
end

local function findBreakableNear(pos, idList, range)
	range = range or 130
	local folder = getBreakablesFolder()
	if not folder then return end
	for _, breakable in ipairs(folder:GetChildren()) do
		local breakableId = breakable:GetAttribute("BreakableID")
		if breakableId then
			for _, id in ipairs(idList) do
				if breakableId == id or string.find(breakableId, id, 1, true) then
					if (breakable:GetPivot().Position - pos).Magnitude < range then
						return breakable
					end
				end
			end
		end
	end
end

local function attackBreakable(breakable)
	if not breakable then return end
	local breakableUID = breakable:GetAttribute("BreakableUID")
	if not breakableUID then return end
	local character = getCharacter()
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:MoveTo(breakable:GetPivot().Position)
	end
	Network.UnreliableFire("Breakables_PlayerDealDamage", breakableUID)
	for _, pet in pairs(PlayerPet.GetByPlayer(localPlayer)) do
		if pet.cpet then pet:SetTarget(breakable) end
	end
end

local function getRoomFarmPos(room)
	local breakZone = room.Model:FindFirstChild("BREAK_ZONE")
	return breakZone and breakZone:GetPivot().Position or room.Position
end

local function tpRoomWithZone(room)
	TeleportToRoom(room.uid)
	task.wait(0.3)
	local breakZone = room.Model:FindFirstChild("BREAK_ZONE")
	if breakZone then
		local character = getCharacter()
		if character then
			character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 5, 0))
		end
	end
end

local function getThumbnailUrl(iconId)
	if not iconId or not httpRequest then return nil end
	local default = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. iconId .. "&width=420&height=420&format=png"
	local ok, response = pcall(function()
		return httpRequest({
			Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. iconId .. "&size=420x420&format=Png&isCircular=false",
			Method = "GET",
		})
	end)
	if not ok or response.StatusCode ~= 200 then return default end
	local decoded = HttpService:JSONDecode(response.Body)
	return decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl or default
end

local function sendWebhook(data)
	if getgenv().webhook == "" or not httpRequest then return end
	pcall(function()
		httpRequest({
			Url = getgenv().webhook,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data),
		})
	end)
end

local function serverHop(reason)
	local message = createMessage(reason)
	pcall(function()
		local api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
		local servers = HttpService:JSONDecode(game:HttpGet(api))
		for _, server in ipairs(servers.data) do
			if server.playing < server.maxPlayers and server.id ~= game.JobId then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
				return
			end
		end
		TeleportService:Teleport(game.PlaceId, localPlayer)
	end)
	if message then game.Debris:AddItem(message, 10) end
end

local function turnOffOtherAutos(activeToggle)
	local toggles = {
		{ AutoBestEgg, "_G.AutoTPBestEgg" },
		{ AutoLockedEgg, "_G.AutoTPLockedEgg" },
		{ AutoFarmBoss, "_G.AutoMiniBoss" },
		{ AutoBossChestToggle, "_G.AutoBossChest" },
		{ AutoMiniChestToggle, "_G.AutoMiniChest" },
		{ AutoCoinRoomToggle, "_G.AutoCoinRoom" },
	}
	for _, entry in ipairs(toggles) do
		if entry[1] and entry[1] ~= activeToggle then
			entry[1]:Set(false)
		end
	end
end

local Rayfield
local rayfieldOk, rayfieldErr = pcall(function()
	Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
end)
if not rayfieldOk or not Rayfield then
	warn("[DeepBackrooms] Rayfield load failed:", rayfieldErr)
	pcall(function()
		Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true))()
	end)
end
if not Rayfield then
	local msg = Instance.new("Message", workspace)
	msg.Text = "Deep Backrooms: UI failed to load (HttpGet blocked?)"
	task.delay(5, function() msg:Destroy() end)
	return
end

local Window = Rayfield:CreateWindow({
	Name = "PS99 - Deep Backrooms Event",
	LoadingTitle = "PS99 - Deep Backrooms Event",
	LoadingSubtitle = "developed by mitzci0",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "DeepBackroomsPS99",
		FileName = "Config",
	},
})

local MainTab = Window:CreateTab("Main")
local EggTab = Window:CreateTab("Eggs")
local ChestTab = Window:CreateTab("Chests")
local WebhookTab = Window:CreateTab("Webhook")
local MiscTab = Window:CreateTab("Misc")

StatusLabel = MainTab:CreateLabel("Status: Idle")

MainTab:CreateSection("Map")
MainTab:CreateButton({
	Name = "Rescan Backrooms",
	Callback = function()
		if _G.IsScanning then return end
		table.clear(_G.ScannedRooms)
		table.clear(_G.ScannedRoomsMap)
		table.clear(_G.VistedRooms)
		doneCleaning = false
		task.spawn(Scan)
	end,
})
MainTab:CreateButton({
	Name = "Teleport to Spawn",
	Callback = function()
		TPtoSpawn()
	end,
})

MainTab:CreateSection("Quick Teleport")
MainTab:CreateButton({
	Name = "Best Free Egg Room",
	Callback = function()
		if not canDoAction() then return end
		local room = getBestEggRoom()
		if room then TeleportToRoom(room.uid) else Rayfield:Notify({ Title = "No Room", Content = "Scan first", Duration = 4 }) end
	end,
})
MainTab:CreateButton({
	Name = "Best Locked Egg Room",
	Callback = function()
		if not canDoAction() then return end
		local room = getBestLockedEggRoom()
		if room then TeleportToRoom(room.uid) else Rayfield:Notify({ Title = "No Room", Content = "No locked egg room", Duration = 4 }) end
	end,
})
MainTab:CreateButton({
	Name = "Active Anomaly (250x)",
	Callback = function()
		if not canDoAction() then return end
		if workspace:GetAttribute("BackroomsAnomalyActive") ~= true then
			Rayfield:Notify({ Title = "No Anomaly", Content = "Nothing active", Duration = 4 })
			return
		end
		local endsAt = workspace:GetAttribute("BackroomsAnomalyEndsAt")
		if type(endsAt) == "number" and workspace:GetServerTimeNow() > endsAt then
			Rayfield:Notify({ Title = "No Anomaly", Content = "Nothing active", Duration = 4 })
			return
		end
		local pos = workspace:GetAttribute("BackroomsAnomalyPos")
		if pos then
			Network.Fire("RequestStreaming", pos)
			getCharacter():PivotTo(CFrame.new(pos) + Vector3.new(0, 5, 0))
		end
	end,
})
MainTab:CreateButton({
	Name = "Boss Room",
	Callback = function()
		if not canDoAction() then return end
		local room = findBossRoom()
		if room then tpRoomWithZone(room) else Rayfield:Notify({ Title = "No Room", Content = "Boss room not scanned", Duration = 4 }) end
	end,
})

EggTab:CreateSection("Auto Teleport")
AutoBestEgg = EggTab:CreateToggle({
	Name = "Auto TP Best Free Egg",
	CurrentValue = false,
	Flag = "AutoTPBestEgg",
	Callback = function(value)
		if value then turnOffOtherAutos(AutoBestEgg) end
		_G.AutoTPBestEgg = value
	end,
})
AutoLockedEgg = EggTab:CreateToggle({
	Name = "Auto TP Locked Egg",
	CurrentValue = false,
	Flag = "AutoTPLockedEgg",
	Callback = function(value)
		if value then turnOffOtherAutos(AutoLockedEgg) end
		_G.AutoTPLockedEgg = value
	end,
})
AutoAnomaly = EggTab:CreateToggle({
	Name = "Auto TP Anomaly Egg",
	CurrentValue = false,
	Flag = "AutoTPAnomaly",
	Callback = function(value)
		_G.AutoTPAnomaly = value
	end,
})
EggTab:CreateDropdown({
	Name = "Locked Egg Mult Target",
	Options = { "Any", "50x", "75x", "100x" },
	CurrentOption = { "Any" },
	Flag = "EggTarget",
	Callback = function(options)
		_G.SelectedLockedEggMult = typeof(options) == "table" and options[1] or options
	end,
})

EggTab:CreateSection("Hatching")
AutoHatchToggle = EggTab:CreateToggle({
	Name = "Auto Hatch Eggs",
	CurrentValue = false,
	Flag = "AutoHatch",
	Callback = function(value)
		_G.AutoHatch = value
	end,
})
EggTab:CreateToggle({
	Name = "Disable Hatch Animation",
	CurrentValue = false,
	Flag = "DisableHatchAnimation",
	Callback = function(value)
		for _, descendant in ipairs(localPlayer:WaitForChild("PlayerScripts"):GetDescendants()) do
			if descendant.Name == "Egg Opening Frontend" then
				descendant.Enabled = not value
				break
			end
		end
	end,
})

ChestTab:CreateSection("Boss")
AutoBossChestToggle = ChestTab:CreateToggle({
	Name = "Auto Complete Boss Chest",
	CurrentValue = false,
	Flag = "AutoBossChest",
	Callback = function(value)
		if value then turnOffOtherAutos(AutoBossChestToggle) end
		_G.AutoBossChest = value
	end,
})
AutoFarmBoss = ChestTab:CreateToggle({
	Name = "Auto Farm Boss Room",
	CurrentValue = false,
	Flag = "AutoFarmBoss",
	Callback = function(value)
		if value then turnOffOtherAutos(AutoFarmBoss) end
		_G.AutoMiniBoss = value
	end,
})

ChestTab:CreateSection("Mini Rooms")
AutoMiniChestToggle = ChestTab:CreateToggle({
	Name = "Auto Farm Mini Chest Room",
	CurrentValue = false,
	Flag = "AutoMiniChest",
	Callback = function(value)
		if value then turnOffOtherAutos(AutoMiniChestToggle) end
		_G.AutoMiniChest = value
	end,
})
AutoCoinRoomToggle = ChestTab:CreateToggle({
	Name = "Auto Farm Coin Room",
	CurrentValue = false,
	Flag = "AutoCoinRoom",
	Callback = function(value)
		if value then turnOffOtherAutos(AutoCoinRoomToggle) end
		_G.AutoCoinRoom = value
	end,
})

ChestTab:CreateSection("Manual TP")
ChestTab:CreateButton({
	Name = "Mini Chest Room",
	Callback = function()
		if not canDoAction() then return end
		local room = findRoomByPattern("DeepChestRoom")
		if room then tpRoomWithZone(room) else Rayfield:Notify({ Title = "No Room", Content = "Scan first", Duration = 4 }) end
	end,
})
ChestTab:CreateButton({
	Name = "Coin / Breakable Room",
	Callback = function()
		if not canDoAction() then return end
		local room = findRoomByPattern("DeepCoinRoom")
		if room then tpRoomWithZone(room) else Rayfield:Notify({ Title = "No Room", Content = "Scan first", Duration = 4 }) end
	end,
})

WebhookTab:CreateSection("Discord")
WebhookTab:CreateInput({
	Name = "Webhook URL",
	PlaceholderText = "https://discord.com/api/webhooks/...",
	RemoveTextAfterFocusLost = false,
	Flag = "WebhookURL",
	Callback = function(text)
		getgenv().webhook = text
	end,
})
WebhookTab:CreateInput({
	Name = "Discord User ID",
	PlaceholderText = "optional ping id",
	RemoveTextAfterFocusLost = false,
	Flag = "DiscordID",
	Callback = function(text)
		getgenv().discordId = text
	end,
})
WebhookTab:CreateLabel("Pings on exclusive+ pets")

MiscTab:CreateSection("Boosts")
MiscTab:CreateToggle({
	Name = "Infinite Pet Speed",
	CurrentValue = false,
	Flag = "InfinitePetSpeed",
	Callback = function(value)
		_G.InfinitePetSpeed = value
	end,
})
MiscTab:CreateToggle({
	Name = "Auto Tapper",
	CurrentValue = false,
	Flag = "AutoTapper",
	Callback = function(value)
		_G.AutoTapper = value
	end,
})

MiscTab:CreateSection("Server")
MiscTab:CreateButton({
	Name = "Rejoin",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, localPlayer)
	end,
})
MiscTab:CreateButton({
	Name = "Server Hop",
	Callback = function()
		serverHop("Server Hopping...")
	end,
})

MiscTab:CreateLabel("developed by mitzci0")

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoTPBestEgg or isAutoAnomlyActive() or not canDoAction() then continue end
		local room = getBestEggRoom()
		if room then
			if not isPlayerInRoom(room) then
				TeleportToRoom(room.uid)
				task.wait(2)
			end
		else
			serverHop("No Best Egg in this server. hopping...")
			task.wait(5)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoTPLockedEgg or isAutoAnomlyActive() or not canDoAction() then continue end
		local room = getBestLockedEggRoom()
		if room then
			if not isPlayerInRoom(room) then
				TeleportToRoom(room.uid)
				task.wait(2)
			end
		else
			serverHop("No locked egg room. hopping...")
			task.wait(5)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoTPAnomaly or not canDoAction() then continue end
		local endsAt = workspace:GetAttribute("BackroomsAnomalyEndsAt")
		if workspace:GetAttribute("BackroomsAnomalyActive") ~= true
			or (type(endsAt) == "number" and workspace:GetServerTimeNow() > endsAt) then
			continue
		end
		local pos = workspace:GetAttribute("BackroomsAnomalyPos")
		if not pos then continue end
		local character = getCharacter()
		if not character then continue end
		if (character:GetPivot().Position - pos).Magnitude > 40 then
			Network.Fire("RequestStreaming", pos)
			character:PivotTo(CFrame.new(pos) + Vector3.new(0, 5, 0))
			task.wait(2)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		if not _G.AutoHatch or not canDoAction() then continue end
		local egg = getNearestEgg()
		if egg then
			pcall(function()
				Network.Invoke("CustomEggs_Hatch", egg._uid, EggCmds.GetMaxHatch(egg._dir))
			end)
		end
	end
end)

local chestIds = { "Daydream Mimic Chest2", "Daydream Mimic Chest" }
local bossIds = { "Daydream Mimic Boss2", "Daydream Mimic Boss" }

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoBossChest or isAutoAnomlyActive() or not canDoAction() then continue end
		local room = findBossRoom()
		if not room then
			serverHop("No Boss Room in this server. hopping...")
			task.wait(5)
			continue
		end
		if not isPlayerInRoom(room) then
			TeleportToRoom(room.uid)
			task.wait(2)
			continue
		end
		local chest = findBreakableNear(getRoomFarmPos(room), chestIds)
		if chest then attackBreakable(chest) end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoMiniBoss or isAutoAnomlyActive() or not canDoAction() then continue end
		local room = findBossRoom()
		if not room then
			serverHop("No Boss Room in this server. hopping...")
			task.wait(5)
			continue
		end
		if not isPlayerInRoom(room) then
			TeleportToRoom(room.uid)
			task.wait(2)
			continue
		end
		local pos = getRoomFarmPos(room)
		local target = findBreakableNear(pos, chestIds) or findBreakableNear(pos, bossIds)
		if target then attackBreakable(target) end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoMiniChest or isAutoAnomlyActive() or not canDoAction() then continue end
		local room = findRoomByPattern("DeepChestRoom")
		if not room then
			serverHop("No mini chest room. hopping...")
			task.wait(5)
			continue
		end
		if not isPlayerInRoom(room) then
			TeleportToRoom(room.uid)
			task.wait(2)
			continue
		end
		local target = findBreakableNear(getRoomFarmPos(room), chestIds)
		if target then attackBreakable(target) end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.AutoCoinRoom or isAutoAnomlyActive() or not canDoAction() then continue end
		local room = findRoomByPattern("DeepCoinRoom")
		if not room then
			serverHop("No coin room. hopping...")
			task.wait(5)
			continue
		end
		if not isPlayerInRoom(room) then
			TeleportToRoom(room.uid)
			task.wait(1.5)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if not _G.AutoTapper then continue end
		local character = getCharacter()
		if not character then continue end
		local folder = getBreakablesFolder()
		if not folder then continue end
		local nearestUID, nearestDist = nil, 150
		for _, breakable in ipairs(folder:GetChildren()) do
			local uid = breakable:GetAttribute("BreakableUID")
			if uid and not breakable:GetAttribute("ManualDamage") and not breakable:GetAttribute("DisableDamage") then
				local dist = (breakable:GetPivot().Position - character:GetPivot().Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestUID = uid
				end
			end
		end
		if nearestUID then
			Signal.Fire("AutoClicker_Nearby", nearestUID)
		end
	end
end)

Network.Fired("Items: Update"):Connect(function(player, packet)
	if not packet or not packet.set then return end
	for classKey, items in pairs(packet.set) do
		if classKey ~= "Pet" then continue end
		local classType = Types.TypeUnchecked(classKey)
		if not classType then continue end
		for itemUID, itemData in pairs(items) do
			if seenPets[itemUID] then continue end
			local item = classType:From(itemData)
			item:SetUID(itemUID)
			if item:GetExclusiveLevel() <= 3 then continue end
			seenPets[itemUID] = true
			local thumbnailUrl = getThumbnailUrl(string.match(item:GetIcon() or "", "%d+"))
			local embed = {
				title = "||" .. localPlayer.Name .. "|| just hatched a " .. item:GetName() .. "!",
				color = 16753920,
				fields = {
					{ name = "Exists", value = tostring(NumberShorten(item:GetExistCount())), inline = true },
					{ name = "RAP", value = tostring(NumberShorten(item:GetRAP())), inline = true },
				},
				footer = { text = "developed by mitzci0" },
				timestamp = DateTime.now():ToIsoDate(),
			}
			if thumbnailUrl then embed.thumbnail = { url = thumbnailUrl } end
			local content = (getgenv().discordId == "" or getgenv().discordId == nil)
				and "@everyone"
				or "<@" .. getgenv().discordId .. ">"
			sendWebhook({ username = "Unknown", content = content, embeds = { embed } })
		end
	end
end)

localPlayer.Idled:Connect(function()
	Signal.Fire("ResetIdleTimer")
	VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

task.spawn(function()
	task.wait(5)
	Scan()
end)
Rayfield:LoadConfiguration()
