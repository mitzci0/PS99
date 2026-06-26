--[[
═══════════════════════════════════════════════════════════════════════════════
  Pet Simulator 99 - Soccer Event Script
  Developed by mitzci0

  Current Version: v1.0.0

  Versioning System:
    • Patch Release  (Bug Fixes)         → 1.0.0 → 1.0.1
    • Minor Release  (New Features)      → 1.0.0 → 1.1.0
    • Major Release  (Breaking Changes)  → 1.0.0 → 2.0.0

  Last Updated: 2026-06-26
  
  If you find any bugs/errors, please report them to me via DM on Discord.
  Username: mitzci0
═══════════════════════════════════════════════════════════════════════════════
]]--





if not game:IsLoaded() then
	game.Loaded:Wait()
end

getgenv().webhook = getgenv().webhook or ""
getgenv().discordId = getgenv().discordId or ""

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
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
local Types = require(game.ReplicatedStorage.Library.Items.Types)
local NumberShorten = require(game.ReplicatedStorage.Library.Functions.NumberShorten)
local InventoryCmds = require(game.ReplicatedStorage.Library.Client.InventoryCmds)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

local localPlayer = Players.LocalPlayer
local httpRequest = request or http_request or (syn and syn.request)

local seenPets = {}
local webhookReady = false

local function tryPetMethod(item, methodName)
	local ok, result = pcall(function()
		return item[methodName](item)
	end)
	return ok and result
end

local function getPetTier(item)
	if tryPetMethod(item, "IsGargantuan") then
		return "Gargantuan"
	end
	if tryPetMethod(item, "IsTitanic") then
		return "Titanic"
	end
	if tryPetMethod(item, "IsHuge") then
		return "Huge"
	end

	local level = item:GetExclusiveLevel()
	if level == 6 then
		return "Gargantuan"
	elseif level == 5 then
		return "Titanic"
	elseif level == 4 then
		return "Huge"
	end

	return nil
end

local function isWebhookPet(item)
	return getPetTier(item) ~= nil
end

local function getTierColor(tier)
	if tier == "Gargantuan" then
		return 15158332
	elseif tier == "Titanic" then
		return 10181046
	end
	return 16753920
end

task.spawn(function()
	while not Save.Get() do
		task.wait()
	end
	local container = InventoryCmds.Container(localPlayer)
	for itemUID, item in pairs(container:All()) do
		if item:IsA("Pet") and isWebhookPet(item) then
			seenPets[itemUID] = true
		end
	end
	webhookReady = true
end)

local function getThumbnailUrl(iconId)
	local default = "https://www.roblox.com/asset-thumbnail/image?assetId=0&width=420&height=420&format=png"
	if not iconId then
		return default
	end
	if not httpRequest then
		return default
	end
	local ok, response = pcall(function()
		return httpRequest({
			Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. iconId .. "&size=420x420&format=Png&isCircular=false",
			Method = "GET",
		})
	end)
	if not ok or response.StatusCode ~= 200 then
		return default
	end
	local decoded = HttpService:JSONDecode(response.Body)
	return decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl or default
end

local function sendWebhook(data)
	if getgenv().webhook == "" or not httpRequest then
		return
	end
	pcall(function()
		httpRequest({
			Url = getgenv().webhook,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(data),
		})
	end)
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

local Rayfield
local rayfieldOk, rayfieldErr = pcall(function()
	Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield", true))()
end)
if not rayfieldOk or not Rayfield then
	warn("[PS99 Event Script] Rayfield load failed:", rayfieldErr)
	pcall(function()
		Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true))()
	end)
end
if not Rayfield then
	local msg = Instance.new("Message", workspace)
	msg.Text = "PS99 Event Script: UI failed to load (HttpGet blocked?)"
	task.delay(25, function() msg:Destroy() end)
	return
end

local Window = Rayfield:CreateWindow({
	Name = "Pet Simulator 99  |  Event Script",
	LoadingTitle = "Soccer Event Script",
	LoadingSubtitle = "developed by mitzci0",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "PS99",
		FileName = "Config",
	},
})

local Category1 = Window:CreateTab("")
local Category2 = Window:CreateTab("")
local Category3 = Window:CreateTab("")
local Category4 = Window:CreateTab("")
local Category5 = Window:CreateTab("")
local Category6 = Window:CreateTab("Webhook")

Category6:CreateSection("Discord Webhook")
Category6:CreateInput({
	Name = "Webhook URL",
	PlaceholderText = "https://discord.com/api/webhooks/...",
	RemoveTextAfterFocusLost = false,
	Flag = "WebhookURL",
	Callback = function(text)
		getgenv().webhook = text
	end,
})
Category6:CreateInput({
	Name = "Discord User ID",
	PlaceholderText = "User-ID",
	RemoveTextAfterFocusLost = false,
	Flag = "DiscordID",
	Callback = function(text)
		getgenv().discordId = text
	end,
})
Category6:CreateLabel("Notified at a hatch of a New Huge / Titanic / Gargantuan")
Category6:CreateLabel("Your changes will be saved automatically.")

local function findRayfieldInput(inputName)
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end
	local rayfieldGui = playerGui:FindFirstChild("Rayfield")
	if not rayfieldGui then
		return nil
	end
	for _, descendant in ipairs(rayfieldGui:GetDescendants()) do
		if descendant.Name == inputName and descendant:FindFirstChild("InputFrame") then
			return descendant
		end
	end
	return nil
end

local function clampWebhookInputWidth()
	local referenceInput = findRayfieldInput("Discord User ID")
	local webhookInput = findRayfieldInput("Webhook URL")
	if not referenceInput or not webhookInput then
		return false
	end

	local referenceWidth = referenceInput.InputFrame.AbsoluteSize.X
	if referenceWidth < 1 then
		return false
	end

	local inputFrame = webhookInput.InputFrame
	local inputBox = inputFrame.InputBox

	local function applyFixedSize()
		inputFrame.Size = UDim2.new(0, referenceWidth, 0, 30)
		inputBox.TextTruncate = Enum.TextTruncate.AtEnd
	end

	applyFixedSize()
	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		task.defer(applyFixedSize)
	end)
	inputBox.FocusLost:Connect(function()
		task.defer(applyFixedSize)
	end)

	return true
end

Network.Fired("Items: Update"):Connect(function(player, packet)
	if not webhookReady or not packet or not packet.set then
		return
	end
	if player and player ~= localPlayer then
		return
	end
	for classKey, items in pairs(packet.set) do
		if classKey ~= "Pet" then
			continue
		end
		local classType = Types.TypeUnchecked(classKey)
		if not classType then
			continue
		end
		for itemUID, itemData in pairs(items) do
			if seenPets[itemUID] then
				continue
			end
			local item = classType:From(itemData)
			item:SetUID(itemUID)
			if not isWebhookPet(item) then
				continue
			end
			seenPets[itemUID] = true

			local tier = getPetTier(item)
			local thumbnailUrl = getThumbnailUrl(string.match(item:GetIcon() or "", "%d+"))
			local embed = {
				title = "||" .. localPlayer.Name .. "|| hatched a " .. tier .. " " .. item:GetName() .. "!",
				color = getTierColor(tier),
				fields = {
					{ name = "Tier", value = tier, inline = true },
					{ name = "Exists", value = tostring(NumberShorten(item:GetExistCount())), inline = true },
					{ name = "RAP", value = tostring(NumberShorten(item:GetRAP())), inline = true },
				},
				footer = { text = "developed by mitzci0" },
				timestamp = DateTime.now():ToIsoDate(),
			}
			if thumbnailUrl then
				embed.thumbnail = { url = thumbnailUrl }
			end

			local content = (getgenv().discordId == "" or getgenv().discordId == nil)
				and "@everyone"
				or "<@" .. getgenv().discordId .. ">"

			sendWebhook({
				username = "Pet Simulator 99 | Soccer Event",
				content = content,
				embeds = { embed },
			})
		end
	end
end)

Rayfield:LoadConfiguration()

task.spawn(function()
	for _ = 1, 20 do
		if clampWebhookInputWidth() then
			break
		end
		task.wait(0.1)
	end
end)
