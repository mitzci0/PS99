if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local name, version = identifyexecutor()

if name == "Xeno" or name == "Solara" then
	Players.LocalPlayer:Kick("Unsupported Executor")
	return
end

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local InstancingCmds = require(game.ReplicatedStorage.Library.Client.InstancingCmds)
local MiscItem = require(game.ReplicatedStorage.Library.Items.MiscItem)
local EggCmds = require(game.ReplicatedStorage.Library.Client.EggCmds)
local CustomEggsCmds = require(game.ReplicatedStorage.Library.Client.CustomEggsCmds)
local PlayerPet = require(game.ReplicatedStorage.Library.Client.PlayerPet)
local Signal = require(game.ReplicatedStorage.Library.Signal)
local Types = require(game.ReplicatedStorage.Library.Items.Types)
local AbstractItem = require(game.ReplicatedStorage.Library.Items.AbstractItem)
local NumberShorten = require(game.ReplicatedStorage.Library.Functions.NumberShorten)
local InventoryCmds = require(game.ReplicatedStorage.Library.Client.InventoryCmds)
local Save = require(game.ReplicatedStorage.Library.Client.Save)

local seenPets = {}
task.spawn(function()
	while (not Save.Get()) do
		task.wait()
	end
	
	local container = InventoryCmds.Container(Players.LocalPlayer)
	local petsInventory = container:All()
	
	for itemUID, item in pairs(petsInventory) do
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

local localPlayer = Players.LocalPlayer
local enterPosition = nil
local roomsToStore = {
	"DeepCoinRoom1", "DeepCoinRoom2", "DeepCoinRoom3",
	"DeepChestRoom1", "DeepChestRoom2", "DeepChestRoom3",
	"DeepFreeEggRoom1", "DeepFreeEggRoom2", "DeepLockedEggRoom",
	"GameMastersStage"
}
local doneCleaning = false
local httpRequest = request or http_request or (syn and syn.request)

local Rayfield = (function()
-- Reaper-style UI library (Rayfield-compatible API)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Reaper = {}
Reaper.Flags = {}
Reaper.ConfigFolder = "DeepBackroomsPS99"
Reaper.ConfigFile = "Config"

local Theme = {
	Bg          = Color3.fromRGB(22, 22, 26),
	Sidebar     = Color3.fromRGB(18, 18, 22),
	TitleBar    = Color3.fromRGB(15, 15, 18),
	Row         = Color3.fromRGB(30, 30, 36),
	RowHover    = Color3.fromRGB(38, 38, 46),
	Accent      = Color3.fromRGB(168, 85, 247),
	AccentDark  = Color3.fromRGB(124, 58, 237),
	AccentGlow  = Color3.fromRGB(147, 51, 234),
	TabActive   = Color3.fromRGB(45, 32, 68),
	Text        = Color3.fromRGB(255, 255, 255),
	TextDim     = Color3.fromRGB(160, 160, 175),
	TextSection = Color3.fromRGB(200, 200, 210),
	Divider     = Color3.fromRGB(50, 50, 58),
	ToggleOff   = Color3.fromRGB(55, 55, 65),
	TitleMuted  = Color3.fromRGB(130, 130, 145),
}

local function getTabIcon(name)
	return string.upper(string.sub(name, 1, 1))
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
	return c
end

local function tween(o, info, props)
	local t = TweenService:Create(o, info, props)
	t:Play()
	return t
end

function Reaper:Notify(data)
	local gui = Player:WaitForChild("PlayerGui"):FindFirstChild("ReaperBackrooms")
	if not gui then return end
	local holder = gui:FindFirstChild("Notifications")
	if not holder then
		holder = Instance.new("Frame")
		holder.Name = "Notifications"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(0, 300, 1, -40)
		holder.Position = UDim2.new(1, -320, 0, 36)
		holder.Parent = gui
		Instance.new("UIListLayout", holder).Padding = UDim.new(0, 6)
		holder:FindFirstChildOfClass("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder
	end
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 64)
	card.BackgroundColor3 = Theme.Row
	card.BorderSizePixel = 0
	card.Parent = holder
	corner(card, 8)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 1, -10)
	bar.Position = UDim2.new(0, 6, 0, 5)
	bar.BackgroundColor3 = Theme.Accent
	bar.BorderSizePixel = 0
	bar.Parent = card
	corner(bar, 2)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.new(0, 16, 0, 8)
	t.Size = UDim2.new(1, -22, 0, 18)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Theme.Text
	t.Text = data.Title or "Notice"
	t.Parent = card
	local b = Instance.new("TextLabel")
	b.BackgroundTransparency = 1
	b.Position = UDim2.new(0, 16, 0, 28)
	b.Size = UDim2.new(1, -22, 0, 28)
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextYAlignment = Enum.TextYAlignment.Top
	b.TextColor3 = Theme.TextDim
	b.Text = data.Content or ""
	b.Parent = card
	card.Position = UDim2.new(1, 30, 0, 0)
	tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
	task.delay(data.Duration or 4, function()
		if card.Parent then
			tween(card, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
			task.wait(0.25)
			card:Destroy()
		end
	end)
end

function Reaper:LoadConfiguration()
	local HttpService = game:GetService("HttpService")
	if not (isfile and readfile and isfile(Reaper.ConfigFolder .. "/" .. Reaper.ConfigFile .. ".json")) then return end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(Reaper.ConfigFolder .. "/" .. Reaper.ConfigFile .. ".json"))
	end)
	if not ok or not decoded then return end
	for flag, value in pairs(decoded) do
		local entry = Reaper.Flags[flag]
		if entry and entry.Set then entry.Set(value) end
	end
end

function Reaper:SaveConfiguration()
	if not writefile then return end
	local HttpService = game:GetService("HttpService")
	local data = {}
	for flag, entry in pairs(Reaper.Flags) do
		if entry.Get then data[flag] = entry.Get() end
	end
	if isfolder and not isfolder(Reaper.ConfigFolder) then makefolder(Reaper.ConfigFolder) end
	writefile(Reaper.ConfigFolder .. "/" .. Reaper.ConfigFile .. ".json", HttpService:JSONEncode(data))
end

function Reaper:CreateWindow(options)
	local gui = Instance.new("ScreenGui")
	gui.Name = "ReaperBackrooms"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Player:WaitForChild("PlayerGui")

	local openBtn = Instance.new("TextButton")
	openBtn.Name = "OpenButton"
	openBtn.Size = UDim2.new(0, 120, 0, 40)
	openBtn.Position = UDim2.new(0, 16, 1, -56)
	openBtn.BackgroundColor3 = Theme.AccentDark
	openBtn.Text = "HUB"
	openBtn.Font = Enum.Font.GothamBold
	openBtn.TextSize = 14
	openBtn.TextColor3 = Theme.Text
	openBtn.AutoButtonColor = false
	openBtn.Visible = false
	openBtn.Parent = gui
	corner(openBtn, 10)

	local main = Instance.new("Frame")
	main.Name = "MainWindow"
	main.Size = UDim2.new(0, 780, 0, 480)
	main.Position = UDim2.new(0.5, -390, 0.5, -240)
	main.BackgroundColor3 = Theme.Bg
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = gui
	corner(main, 10)

	-- title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 34)
	titleBar.BackgroundColor3 = Theme.TitleBar
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main

	local titleText = Instance.new("TextLabel")
	titleText.BackgroundTransparency = 1
	titleText.Position = UDim2.new(0, 14, 0, 0)
	titleText.Size = UDim2.new(1, -120, 1, 0)
	titleText.Font = Enum.Font.Gotham
	titleText.TextSize = 13
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.TextColor3 = Theme.TitleMuted
	titleText.Text = "Pet Simulator 99  |  " .. ("Deep Backrooms") .. "       |  Made with Love by mitzci0 <3"
	titleText.Parent = titleBar

	local function makeWinBtn(text, xOff)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 34, 0, 34)
		b.Position = UDim2.new(1, xOff, 0, 0)
		b.BackgroundTransparency = 1
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.TextColor3 = Theme.TextDim
		b.AutoButtonColor = false
		b.Parent = titleBar
		b.MouseEnter:Connect(function() b.TextColor3 = Theme.Text end)
		b.MouseLeave:Connect(function() b.TextColor3 = Theme.TextDim end)
		return b
	end

	local minBtn = makeWinBtn("-", -68)
	local closeBtn = makeWinBtn("x", -34)

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, 0, 1, -34)
	body.Position = UDim2.new(0, 0, 0, 34)
	body.BackgroundTransparency = 1
	body.Parent = main

	-- sidebar
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 200, 1, 0)
	sidebar.BackgroundColor3 = Theme.Sidebar
	sidebar.BorderSizePixel = 0
	sidebar.Parent = body

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.Padding = UDim.new(0, 2)
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent = sidebar

	local sidebarPad = Instance.new("UIPadding")
	sidebarPad.PaddingTop = UDim.new(0, 10)
	sidebarPad.PaddingLeft = UDim.new(0, 0)
	sidebarPad.PaddingRight = UDim.new(0, 0)
	sidebarPad.Parent = sidebar

	-- content panel
	local contentPanel = Instance.new("Frame")
	contentPanel.Size = UDim2.new(1, -200, 1, 0)
	contentPanel.Position = UDim2.new(0, 200, 0, 0)
	contentPanel.BackgroundTransparency = 1
	contentPanel.ClipsDescendants = true
	contentPanel.Parent = body

	local windowOpen = true
	local function setVisible(v)
		windowOpen = v
		main.Visible = v
		openBtn.Visible = not v
	end

	minBtn.MouseButton1Click:Connect(function() setVisible(false) end)
	closeBtn.MouseButton1Click:Connect(function() setVisible(false) end)
	openBtn.MouseButton1Click:Connect(function() setVisible(true) end)

	local dragging, dragStart, startPos = false, nil, nil
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)

	local Window = {}
	local tabEntries = {}
	local activeTabName = nil

	function Window:CreateTab(name, _)
		local icon = getTabIcon(name)

		-- tab button
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, 0, 0, 44)
		tabBtn.BackgroundTransparency = 1
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.Parent = sidebar

		local activeBar = Instance.new("Frame")
		activeBar.Size = UDim2.new(0, 4, 1, -8)
		activeBar.Position = UDim2.new(0, 0, 0, 4)
		activeBar.BackgroundColor3 = Theme.Accent
		activeBar.BorderSizePixel = 0
		activeBar.Visible = false
		activeBar.Parent = tabBtn
		corner(activeBar, 2)

		local activeBg = Instance.new("Frame")
		activeBg.Size = UDim2.new(1, -8, 1, -4)
		activeBg.Position = UDim2.new(0, 4, 0, 2)
		activeBg.BackgroundColor3 = Theme.TabActive
		activeBg.BackgroundTransparency = 1
		activeBg.BorderSizePixel = 0
		activeBg.ZIndex = 0
		activeBg.Parent = tabBtn
		corner(activeBg, 6)

		local iconBadge = Instance.new("Frame")
		iconBadge.Size = UDim2.new(0, 22, 0, 22)
		iconBadge.Position = UDim2.new(0, 14, 0.5, -11)
		iconBadge.BackgroundColor3 = Theme.Row
		iconBadge.BorderSizePixel = 0
		iconBadge.ZIndex = 2
		iconBadge.Parent = tabBtn
		corner(iconBadge, 6)

		local iconLbl = Instance.new("TextLabel")
		iconLbl.BackgroundTransparency = 1
		iconLbl.Size = UDim2.new(1, 0, 1, 0)
		iconLbl.Font = Enum.Font.GothamBlack
		iconLbl.TextSize = 12
		iconLbl.Text = icon
		iconLbl.TextColor3 = Theme.TextDim
		iconLbl.ZIndex = 2
		iconLbl.Parent = iconBadge

		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(0, 1, 0, 18)
		sep.Position = UDim2.new(0, 44, 0.5, -9)
		sep.BackgroundColor3 = Theme.Divider
		sep.BorderSizePixel = 0
		sep.ZIndex = 2
		sep.Parent = tabBtn

		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 54, 0, 0)
		nameLbl.Size = UDim2.new(1, -60, 1, 0)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Text = name
		nameLbl.TextColor3 = Theme.TextDim
		nameLbl.ZIndex = 2
		nameLbl.Parent = tabBtn

		-- tab page container
		local container = Instance.new("Frame")
		container.Name = name
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		container.Visible = false
		container.Parent = contentPanel

		-- page header (Reaper style)
		local pageHeader = Instance.new("Frame")
		pageHeader.Size = UDim2.new(1, -32, 0, 56)
		pageHeader.Position = UDim2.new(0, 16, 0, 8)
		pageHeader.BackgroundTransparency = 1
		pageHeader.Parent = container

		local headerBar = Instance.new("Frame")
		headerBar.Size = UDim2.new(0, 5, 0, 32)
		headerBar.Position = UDim2.new(0, 0, 0, 6)
		headerBar.BackgroundColor3 = Theme.Accent
		headerBar.BorderSizePixel = 0
		headerBar.Parent = pageHeader
		corner(headerBar, 3)

		local headerTitle = Instance.new("TextLabel")
		headerTitle.BackgroundTransparency = 1
		headerTitle.Position = UDim2.new(0, 16, 0, 0)
		headerTitle.Size = UDim2.new(1, -16, 1, 0)
		headerTitle.Font = Enum.Font.GothamBlack
		headerTitle.TextSize = 28
		headerTitle.TextXAlignment = Enum.TextXAlignment.Left
		headerTitle.TextColor3 = Theme.Text
		headerTitle.Text = name
		headerTitle.Parent = pageHeader

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, -16, 1, -72)
		scroll.Position = UDim2.new(0, 8, 0, 64)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 3
		scroll.ScrollBarImageColor3 = Theme.Accent
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = container

		local page = scroll
		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding = UDim.new(0, 6)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent = page

		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingLeft = UDim.new(0, 8)
		pagePad.PaddingRight = UDim.new(0, 8)
		pagePad.PaddingBottom = UDim.new(0, 16)
		pagePad.Parent = page

		pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
		end)

		local function selectTab()
			for _, entry in ipairs(tabEntries) do
				entry.bar.Visible = false
				tween(entry.bg, TweenInfo.new(0.15), {BackgroundTransparency = 1})
				entry.icon.TextColor3 = Theme.TextDim
				entry.badge.BackgroundColor3 = Theme.Row
				entry.name.TextColor3 = Theme.TextDim
				entry.container.Visible = false
			end
			activeBar.Visible = true
			tween(activeBg, TweenInfo.new(0.15), {BackgroundTransparency = 0.35})
			iconLbl.TextColor3 = Theme.Text
			iconBadge.BackgroundColor3 = Theme.AccentDark
			nameLbl.TextColor3 = Theme.Text
			container.Visible = true
			activeTabName = name
		end

		tabBtn.MouseButton1Click:Connect(selectTab)
		tabBtn.MouseEnter:Connect(function()
			if activeTabName ~= name then
				tween(activeBg, TweenInfo.new(0.12), {BackgroundTransparency = 0.7})
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if activeTabName ~= name then
				tween(activeBg, TweenInfo.new(0.12), {BackgroundTransparency = 1})
			end
		end)

		table.insert(tabEntries, {
			bar = activeBar, bg = activeBg, icon = iconLbl, badge = iconBadge,
			name = nameLbl, container = container, select = selectTab,
		})
		if not activeTabName then selectTab() end

		local Tab = {}

		function Tab:CreateSection(title)
			local sec = Instance.new("TextLabel")
			sec.Size = UDim2.new(1, 0, 0, 28)
			sec.BackgroundTransparency = 1
			sec.Font = Enum.Font.GothamBold
			sec.TextSize = 13
			sec.TextXAlignment = Enum.TextXAlignment.Left
			sec.TextColor3 = Theme.TextSection
			sec.Text = title
			sec.Parent = page
			return sec
		end

		function Tab:CreateLabel(text)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 48)
			frame.BackgroundColor3 = Theme.Row
			frame.BorderSizePixel = 0
			frame.Parent = page
			corner(frame, 8)

			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, 3, 1, -14)
			bar.Position = UDim2.new(0, 10, 0, 7)
			bar.BackgroundColor3 = Theme.Accent
			bar.BorderSizePixel = 0
			bar.Parent = frame
			corner(bar, 2)

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.new(0, 22, 0, 0)
			label.Size = UDim2.new(1, -30, 1, 0)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = Theme.Text
			label.Text = text
			label.Parent = frame

			return { Set = function(_, t) label.Text = t end }
		end

		function Tab:CreateButton(opts)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 48)
			btn.BackgroundColor3 = Theme.Row
			btn.Text = ""
			btn.AutoButtonColor = false
			btn.Parent = page
			corner(btn, 8)

			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.Size = UDim2.new(1, -32, 1, 0)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextSize = 14
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextColor3 = Theme.Text
			lbl.Text = opts.Name or "Button"
			lbl.Parent = btn

			local arrow = Instance.new("TextLabel")
			arrow.BackgroundTransparency = 1
			arrow.Size = UDim2.new(0, 20, 1, 0)
			arrow.Position = UDim2.new(1, -28, 0, 0)
			arrow.Font = Enum.Font.GothamBold
			arrow.TextSize = 16
			arrow.TextColor3 = Theme.Accent
			arrow.Text = ">"
			arrow.Parent = btn

			btn.MouseEnter:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.RowHover}) end)
			btn.MouseLeave:Connect(function() tween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Row}) end)
			btn.MouseButton1Click:Connect(function() if opts.Callback then opts.Callback() end end)
			return btn
		end

		function Tab:CreateToggle(opts)
			local current = opts.CurrentValue or false
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 48)
			frame.BackgroundColor3 = Theme.Row
			frame.BorderSizePixel = 0
			frame.Parent = page
			corner(frame, 8)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.new(0, 16, 0, 0)
			nameLabel.Size = UDim2.new(1, -90, 1, 0)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 14
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextColor3 = Theme.Text
			nameLabel.Text = opts.Name or "Toggle"
			nameLabel.Parent = frame

			local switchBg = Instance.new("TextButton")
			switchBg.Size = UDim2.new(0, 52, 0, 28)
			switchBg.Position = UDim2.new(1, -68, 0.5, -14)
			switchBg.BackgroundColor3 = Theme.ToggleOff
			switchBg.Text = ""
			switchBg.AutoButtonColor = false
			switchBg.Parent = frame
			corner(switchBg, 14)

			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 22, 0, 22)
			knob.Position = UDim2.new(0, 3, 0.5, -11)
			knob.BackgroundColor3 = Theme.Text
			knob.BorderSizePixel = 0
			knob.Parent = switchBg
			corner(knob, 11)

			local function applyVisual(on)
				if on then
					tween(switchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundColor3 = Theme.Accent})
					tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -25, 0.5, -11)})
				else
					tween(switchBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundColor3 = Theme.ToggleOff})
					tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(0, 3, 0.5, -11)})
				end
			end

			local function setValue(on, fire)
				current = on
				applyVisual(on)
				if fire ~= false and opts.Callback then opts.Callback(on) end
				if opts.Flag then Reaper:SaveConfiguration() end
			end

			applyVisual(current)
			switchBg.MouseButton1Click:Connect(function() setValue(not current, true) end)
			frame.MouseEnter:Connect(function() tween(frame, TweenInfo.new(0.12), {BackgroundColor3 = Theme.RowHover}) end)
			frame.MouseLeave:Connect(function() tween(frame, TweenInfo.new(0.12), {BackgroundColor3 = Theme.Row}) end)

			local toggleObj = { Set = function(_, v) setValue(v, true) end }
			if opts.Flag then
				Reaper.Flags[opts.Flag] = {
					Set = function(v) toggleObj:Set(v) end,
					Get = function() return current end,
				}
			end
			return toggleObj
		end

		function Tab:CreateDropdown(opts)
			local current = (typeof(opts.CurrentOption) == "table" and opts.CurrentOption[1]) or opts.CurrentOption or (opts.Options and opts.Options[1]) or "Any"
			local open = false

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 48)
			frame.BackgroundColor3 = Theme.Row
			frame.BorderSizePixel = 0
			frame.ClipsDescendants = false
			frame.Parent = page
			corner(frame, 8)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.new(0, 16, 0, 0)
			nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 14
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextColor3 = Theme.Text
			nameLabel.Text = opts.Name or "Dropdown"
			nameLabel.Parent = frame

			local valueBtn = Instance.new("TextButton")
			valueBtn.Size = UDim2.new(0, 100, 0, 32)
			valueBtn.Position = UDim2.new(1, -116, 0.5, -16)
			valueBtn.BackgroundColor3 = Theme.ToggleOff
			valueBtn.Font = Enum.Font.GothamBold
			valueBtn.TextSize = 13
			valueBtn.TextColor3 = Theme.Accent
			valueBtn.Text = tostring(current)
			valueBtn.AutoButtonColor = false
			valueBtn.Parent = frame
			corner(valueBtn, 8)

			local dropPanel = Instance.new("Frame")
			dropPanel.Size = UDim2.new(1, -16, 0, 0)
			dropPanel.Position = UDim2.new(0, 8, 0, 50)
			dropPanel.BackgroundColor3 = Theme.Sidebar
			dropPanel.BorderSizePixel = 0
			dropPanel.Visible = false
			dropPanel.ZIndex = 5
			dropPanel.Parent = frame
			corner(dropPanel, 8)

			local dropLayout = Instance.new("UIListLayout")
			dropLayout.Padding = UDim.new(0, 2)
			dropLayout.Parent = dropPanel

			local dropPad = Instance.new("UIPadding")
			dropPad.PaddingTop = UDim.new(0, 4)
			dropPad.PaddingBottom = UDim.new(0, 4)
			dropPad.PaddingLeft = UDim.new(0, 4)
			dropPad.PaddingRight = UDim.new(0, 4)
			dropPad.Parent = dropPanel

			for _, option in ipairs(opts.Options or {}) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 34)
				optBtn.BackgroundColor3 = Theme.Row
				optBtn.Text = option
				optBtn.Font = Enum.Font.GothamBold
				optBtn.TextSize = 13
				optBtn.TextColor3 = Theme.Text
				optBtn.AutoButtonColor = false
				optBtn.Parent = dropPanel
				corner(optBtn, 6)
				optBtn.MouseEnter:Connect(function() optBtn.BackgroundColor3 = Theme.RowHover end)
				optBtn.MouseLeave:Connect(function() optBtn.BackgroundColor3 = Theme.Row end)
				optBtn.MouseButton1Click:Connect(function()
					current = option
					valueBtn.Text = tostring(current)
					open = false
					dropPanel.Visible = false
					frame.Size = UDim2.new(1, 0, 0, 48)
					if opts.Callback then opts.Callback({option}) end
					if opts.Flag then Reaper:SaveConfiguration() end
				end)
			end

			valueBtn.MouseButton1Click:Connect(function()
				open = not open
				dropPanel.Visible = open
				local h = open and (#(opts.Options or {}) * 36 + 12) or 0
				frame.Size = UDim2.new(1, 0, 0, 48 + h)
				dropPanel.Size = UDim2.new(1, -16, 0, h)
			end)

			if opts.Flag then
				Reaper.Flags[opts.Flag] = {
					Set = function(v)
						current = v
						valueBtn.Text = tostring(v)
						if opts.Callback then opts.Callback({v}) end
					end,
					Get = function() return current end,
				}
			end
			return frame
		end

		return Tab
	end

	return Window
end

return Reaper
end)()

local Window = Rayfield:CreateWindow({
	Name = "Deep Backrooms Script (BETA)",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Developed by mitzci0",
})

local Tab = Window:CreateTab("Eggs")
local MiniBossTab = Window:CreateTab("Chests")
local MiscTab = Window:CreateTab("Misc")
local StatusLabel = Tab:CreateLabel("Status: Idle")

_G.ScannedRooms = {}
_G.ScannedRoomsMap = {}
_G.VistedRooms = {}
_G.IsScanning = false
_G.Teleporting = false
_G.AutoHatch = false
_G.AutoTPBestEgg = false
_G.AutoMiniBoss = false
_G.AutoTPLockedEgg = false
_G.AutoTPAnomaly = false
_G.InfinitePetSpeed = false
_G.AutoTapper = false

_G.SelectedLockedEggMult = "Any"

local EggDropdown
local FreeEggTPButton
local AutoBestEgg
local LockedEggTarget
local LockedEggTPButton
local AutoLockedEgg
local AnomalyTPButton
local AutoAnomaly
local AutoHatch
local DisableHatchAnimation
local BreakablesRoomTPButton
local DeepChestRoomTPButton
local BossTPButton
local AutoFarmBoss
local RejoinButton
local ServerHopButton
local InfPetSpeedButton
local AutoTapperToggle

local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local character = getCharacter()
if character then
	local enterPart = workspace:WaitForChild("__THINGS")
		:WaitForChild("Instances")
		:WaitForChild("Backrooms")
		:WaitForChild("Teleports")
		:WaitForChild("Enter")
	character:PivotTo(enterPart.CFrame)
end

local function createMessage(msg)
	if workspace:FindFirstChildOfClass("Message") then
		return
	end
	local message = Instance.new("Message", workspace)
	message.Text = msg
	return message
end

local function getThumbnailUrl(iconId)
	if not iconId or not httpRequest then
		warn("no http/icon")
		return nil
	end

	local default = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. iconId .. "&width=420&height=420&format=png"

	local success, response = pcall(function()
		return httpRequest({
			Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. iconId .. "&size=420x420&format=Png&isCircular=false",
			Method = "GET"
		})
	end)

	if not success or response.StatusCode ~= 200  then
		warn("NO DATA FOR IMAGE 1")
		return default
	end

	local decoded = HttpService:JSONDecode(response.Body)
	if not decoded or not decoded.data then
		warn("NO DATA FOR IMAGE 2")
		return default
	end

	local imageUrl = decoded.data[1].imageUrl
	if not imageUrl then
		warn("NO DATA FOR IMAGE 3")
		return default
	end

	return imageUrl
end

local function sendWebhook(data)
	if getgenv().webhook == "" or getgenv().webhook == nil then
		warn("NO WEBHOOK!")
		return
	end

	if not httpRequest then
		warn("Error 1")
		return
	end

	local body = HttpService:JSONEncode(data)
	if not body then
		warn("Error 2")
		return
	end

	local success, response = pcall(function()
		return httpRequest({
			Url = getgenv().webhook,
			Method = "POST",
			Headers = {	["Content-Type"] = "application/json" },
			Body = body
		})
	end)

	if not success then
		warn("Error 3", tostring(response))
	end
end

local function serverHop(reason)
	local message = createMessage(reason)

	local success = pcall(function()
		local api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

		local function list(cursor)
			local raw = game:HttpGet(api .. ((cursor and "&cursor=" .. cursor) or ""))
			return HttpService:JSONDecode(raw)
		end

		local servers = list()
		for _, server in ipairs(servers.data) do
			if server.playing < server.maxPlayers and server.id ~= game.JobId then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
				return true
			end
		end
	end)

	if not success then
		TeleportService:Teleport(game.PlaceId, localPlayer)
	else
		game.Debris:AddItem(message, 10)
	end
end

if _G.ExecutedScript ~= nil then
	createMessage("Script was re-executed rejoining the game...")
	task.delay(2, function()
		TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
	end)
	return
end

_G.ExecutedScript = true

local function getGeneratedBackrooms()
	local container = workspace:FindFirstChild("__THINGS"):FindFirstChild("__INSTANCE_CONTAINER")
	if not container then
		return nil
	end

	local active = container:FindFirstChild("Active")
	if not active then
		return nil
	end

	local backrooms = active:WaitForChild("Backrooms", 3)
	if not backrooms then
		return nil
	end

	return backrooms:FindFirstChild("GeneratedBackrooms")
end

local function findRoomDataByUID(roomUID)
	local roomData = _G.ScannedRoomsMap[roomUID]
	if roomData then
		return roomData
	end
	return nil
end

local function findRoomModelByUID(roomUID)
	local folder = getGeneratedBackrooms()
	if not folder then 
		return nil 
	end

	for _, roomModel in ipairs(folder:GetChildren()) do
		if roomModel:GetAttribute("RoomUID") == roomUID then
			return roomModel
		end
	end

	return nil
end

local function getNearestEgg(character)
	if typeof(character) ~= "Model" then
		return
	end

	local closestEgg = nil
	local minDist = 40

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
	if roomData == nil then 
		return false 
	end

	local character = getCharacter()
	if not character then 
		return false 
	end

	local roomCFrame, roomSize = roomData.Model:GetBoundingBox()
	if not roomCFrame or not roomSize then
		return false
	end

	local localPoint = roomCFrame:PointToObjectSpace(character:GetPivot().Position)
	local limitX = (roomSize.X / 2) + 20
	local limitY = (roomSize.Y / 2) + 35
	local limitZ = (roomSize.Z / 2) + 20

	return math.abs(localPoint.X) <= limitX
		and math.abs(localPoint.Y) <= limitY
		and math.abs(localPoint.Z) <= limitZ
end

local function getBestEggRoom()
	local bestRoom = nil
	local maxMult = -1

	for _, room in ipairs(_G.ScannedRooms) do
		if string.match(room.Id, "DeepFreeEggRoom") ~= nil and room.EggMultiplier ~= nil then
			if room.EggMultiplier > maxMult then
				maxMult = room.EggMultiplier
				bestRoom = room
			end
		end
	end

	return bestRoom
end

local function getBestLockedEggRoom()
	local bestRoom = nil
	local maxMult = -1
	local targetMult = (_G.SelectedLockedEggMult and _G.SelectedLockedEggMult ~= "Any")
		and tonumber(string.match(_G.SelectedLockedEggMult, "%d+"))
		or nil

	for _, room in ipairs(_G.ScannedRooms) do
		if room.Id == "DeepLockedEggRoom" and room.EggMultiplier ~= nil then
			if (not room.ExpireTime) or (room.ExpireTime - workspace:GetServerTimeNow() > 0) then
				local isMatch = (not targetMult) or room.EggMultiplier >= targetMult

				if isMatch and room.EggMultiplier > maxMult then
					maxMult = room.EggMultiplier
					bestRoom = room
				end
			end
		end
	end

	return bestRoom
end

local function keyCheck()
	local keyItem = MiscItem("Deep Backrooms Crayon Key")
	if keyItem and keyItem:HasAny() then
		return true
	end
	return false
end

local function UnlockRoom(roomUID)
	if _G.IsScanning == true then
		return
	end

	local character = getCharacter()
	if not character then
		return
	end

	local ownsKey = keyCheck()
	if not ownsKey then
		return
	end

	local activeInstance = InstancingCmds.Get()
	if not activeInstance then
		return
	end

	local roomData = findRoomDataByUID(roomUID)
	if not roomData then 
		warn("NO ROOM DATA 2")
		return 
	end

	local roomModel = roomData.Model
	local lockedDoors = roomModel:FindFirstChild("LockedDoors")
	if not lockedDoors then 
		warn("IS NOT A LOCKED ROOM")
		return 
	end

	local lockedPart = nil
	for _, child in ipairs(lockedDoors:GetChildren()) do
		local lock = child:FindFirstChild("Lock")
		if lock and lock.Transparency < 1 then
			lockedPart = lock
			break
		end
	end

	if not lockedPart then
		warn("doesnt exist lock part")
		return 
	end

	character:PivotTo(CFrame.new(lockedPart.Position))
	activeInstance:FireCustom("AbstractRoom_FireServer", roomUID, "UnlockDoors")
end

local function TeleportToRoom(roomUID, isScanning)
	if _G.Teleporting then
		return
	end

	_G.Teleporting = true

	local character = getCharacter()
	if not character then
		_G.Teleporting = false
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		_G.Teleporting = false
		return
	end

	local roomData = findRoomDataByUID(roomUID)
	if not roomData then
		warn("NO ROOM DATA")
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
		if forceField and forceField.Parent then 
			forceField:Destroy() 
		end

		if (not isScanning) then
			rootPart.Anchored = false
		end
	end)

	if (not isScanning) then
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

				if not ok then
					warn("FAILED TO GET PLR DATA", playerDataList)
					return
				end

				for _, roomInfo in ipairs(playerDataList) do
					if roomInfo.uid == roomUID then
						local expireTime = roomInfo.data and roomInfo.data.UnlockExpireTimestamp or nil
						if expireTime then
							roomData.ExpireTime = expireTime
						end
						break
					end
				end
			else
				warn("not in instance??")
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

	if doneCleaning then
		return
	end

	for _, room in ipairs(folder:GetChildren()) do
		if room.Name == "Walls" then
			local children = room:GetChildren()

			for i = 1, #children do
				children[i]:Destroy()

				if i % 15 == 0 then
					RunService.Heartbeat:Wait()
				end
			end

			room:Destroy()
		end
	end

	doneCleaning = true
end

local function TPtoSpawn()
	local character = getCharacter()
	if not character then
		return
	end

	if typeof(enterPosition) ~= "Vector3" then
		return
	end

	Network.Fire("RequestStreaming", enterPosition)
	character:PivotTo(CFrame.new(enterPosition) + Vector3.new(0, 5, 0))
end

local function Scan()
	if _G.IsScanning then
		return
	end

	_G.IsScanning = true

	local character = getCharacter()
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
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
			warn("SAVED", enterPosition)
			Network.Fire("RequestStreaming", enterPosition)
			character:PivotTo(CFrame.new(enterPosition) + Vector3.new(0, 5, 0))
		end
	end

	task.spawn(CleanupWalls)

	repeat
		message.Text = "Changes to unnecessary stuff!"
		task.wait(0.10)
	until doneCleaning == true

	message.Text = "Exploring the backrooms! Please wait..."

	local function processRoom(room)
		if room:GetAttribute("DeepRoom") ~= true then
			return
		end

		local roomUID = room:GetAttribute("RoomUID")
		if not roomUID then
			return
		end

		local exists = _G.ScannedRoomsMap[roomUID]
		if not exists then
			local roomId = room:GetAttribute("RoomID")
			local roomCFrame = room:GetPivot()
			local mult = room:GetAttribute("EggMultiplier") or 0

			local roomData = {
				uid = roomUID,
				Id = roomId,
				Model = room,
				CFrame = roomCFrame,
				Position = roomCFrame.Position,
				EggMultiplier = mult > 0 and mult or nil
			}

			_G.ScannedRoomsMap[roomUID] = roomData
			table.insert(_G.ScannedRooms, roomData)
			total+=1

			StatusLabel:Set("Status: Scanned " .. #_G.ScannedRooms .. " rooms")

			if roomId == "DeepLockedEggRoom" or string.match(roomId, "DeepFreeEggRoom") ~= nil then
				warn(roomId .. " with " .. mult .. "x mult")
			elseif roomId == "GameMastersStage" then
				warn("Boss room", roomId)
			else
				print(roomId)
			end
		end
	end

	local function run()
		local folder = getGeneratedBackrooms()
		if not folder then
			return
		end

		local rooms = folder:GetChildren()
		for i = 1, #rooms do
			processRoom(rooms[i])
		end
	end

	run()

	while true do
		if #_G.ScannedRooms >= 400 then
			break
		end

		local character = getCharacter()
		if not character then
			continue
		end

		if _G.Teleporting == true then
			continue
		end

		local nearestRoom = nil
		local nearestDist = math.huge

		for i = 1, #_G.ScannedRooms do
			local room = _G.ScannedRooms[i]

			if _G.VistedRooms[room.uid] == nil then
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
		run()
	end

	table.clear(_G.VistedRooms)

	for i = 1, #_G.ScannedRooms do
		local room = _G.ScannedRooms[i]
		if room then
			local keep = table.find(roomsToStore, room.Id) ~= nil
			if not keep then
				table.remove(_G.ScannedRooms, i)
				_G.ScannedRoomsMap[room.uid] = nil
			end
		end
	end

	TPtoSpawn()
	rootPart.Anchored = false
	StatusLabel:Set("Status: Scan Complete! Scanned " .. total .. " rooms! with " .. #_G.ScannedRooms .. " valid rooms!")
	game.Debris:AddItem(message, 0)
	_G.IsScanning = false

	warn("Scan finished!")
end

local function canDoAction()
	return (not _G.IsScanning) and (not _G.Teleporting)
end

local function isAutoAnomlyActive()
	local anomalyActive = workspace:GetAttribute("BackroomsAnomalyActive")
	local endsAt = workspace:GetAttribute("BackroomsAnomalyEndsAt")

	return _G.AutoTPAnomaly and anomalyActive == true and type(endsAt) == "number" and endsAt >= workspace:GetServerTimeNow()
end

Tab:CreateSection("Egg Teleport")

FreeEggTPButton = Tab:CreateButton({
	Name = "Teleport to Best Free Egg Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local room = getBestEggRoom()
		if room then
			TeleportToRoom(room.uid)
		else
			Rayfield:Notify({
				Title = "No Room Found",
				Content = "Could not find any BEST FREE EGG ROOM!",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

Tab:CreateSection("Auto Farm")

AutoBestEgg = Tab:CreateToggle({
	Name = "Auto TP To Best Egg",
	CurrentValue = false,
	Flag = "AutoTPBestEgg",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end

		if value then
			if AutoFarmBoss ~= nil and _G.AutoMiniBoss == true then
				AutoFarmBoss:Set(false)
			end
			if AutoLockedEgg ~= nil and _G.AutoTPLockedEgg == true then
				AutoLockedEgg:Set(false)
			end
		end

		_G.AutoTPBestEgg = value
	end,
})

LockedEggTarget = Tab:CreateDropdown({
	Name = "Locked Egg Mult Target!",
	Options = {"Any", "50x", "75x", "100x"},
	CurrentOption = {"Any"},
	MultipleOptions = false,
	Flag = "EggTarget",
	Callback = function(options)
		if (not canDoAction()) then
			return
		end

		_G.SelectedLockedEggMult = (typeof(options) == "table" and options[1] or options)
	end,
})

LockedEggTPButton = Tab:CreateButton({
	Name = "Teleport to Locked Egg Egg Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local room = getBestLockedEggRoom()
		if room then
			TeleportToRoom(room.uid)
		else
			Rayfield:Notify({
				Title = "No Room Found",
				Content = "Could not find LOCKED EGG ROOM!",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

AutoLockedEgg = Tab:CreateToggle({
	Name = "Auto TP To Locked Egg",
	CurrentValue = false,
	Flag = "AutoTPLockedEgg",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end

		if value then
			if AutoFarmBoss ~= nil and _G.AutoMiniBoss == true then
				AutoFarmBoss:Set(false)
			end
			if AutoBestEgg ~= nil and _G.AutoTPBestEgg == true then
				AutoBestEgg:Set(false)
			end
		end

		_G.AutoTPLockedEgg = value
	end,
})

AnomalyTPButton = Tab:CreateButton({
	Name = "Teleport to Active Anomaly! (250x Egg)",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local character = getCharacter()
		if not character then
			return
		end

		local isActive = workspace:GetAttribute("BackroomsAnomalyActive")
		local endsAt = workspace:GetAttribute("BackroomsAnomalyEndsAt")

		if not isActive or (type(endsAt) == "number" and workspace:GetServerTimeNow() > endsAt) then
			Rayfield:Notify({
				Title = "No Anomly",
				Content = "No Active Anomaly in this server!",
				Duration = 4,
				Image = 4483362458
			})
			return
		end

		local pos = workspace:GetAttribute("BackroomsAnomalyPos")
		if not pos then
			return
		end

		Network.Fire("RequestStreaming", pos)
		character:PivotTo(CFrame.new(pos) + Vector3.new(0, 5, 0))
	end,
})

AutoAnomaly = Tab:CreateToggle({
	Name = "Auto TP To Active Anomly (250x Egg)",
	CurrentValue = false,
	Flag = "AutoTPAnomaly",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end

		_G.AutoTPAnomaly = value
	end,
})

Tab:CreateSection("Hatching")

AutoHatch = Tab:CreateToggle({
	Name = "Auto Hatch Eggs",
	CurrentValue = false,
	Flag = "AutoHatch",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end
		_G.AutoHatch = value
	end,
})

DisableHatchAnimation = Tab:CreateToggle({
	Name = "Disable Hatch Animation",
	CurrentValue = false,
	Flag = "DisableHatchAnimation",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end

		if workspace.CurrentCamera:FindFirstChild("Eggs") or workspace.CurrentCamera:FindFirstChild("Pets") then
			return
		end

		local scripts = localPlayer:WaitForChild("PlayerScripts")
		local scriptInstance = nil
		for _, descendant in ipairs(scripts:GetDescendants()) do
			if descendant.Name == "Egg Opening Frontend" then
				scriptInstance = descendant
				break
			end
		end

		if not scriptInstance then
			return
		end

		scriptInstance.Enabled = (not value)
	end,
})

MiniBossTab:CreateSection("Room Teleport")

BreakablesRoomTPButton = MiniBossTab:CreateButton({
	Name = "Teleport to nearest Breakable Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local found = false
		for _, r in ipairs(_G.ScannedRooms) do
			if string.match(r.Id, "DeepCoinRoom") ~= nil then
				found = true
				TeleportToRoom(r.uid)
				task.wait(0.3)
				local roomModel = r.Model
				local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
				if breakZone then
					local character = getCharacter()
					if character then
						character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 5, 0))
					end
				end
				break
			end
		end

		if not found then
			Rayfield:Notify({
				Title = "No Breakable Room",
				Content = "Could not find any scanned Breakable Room",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

DeepChestRoomTPButton = MiniBossTab:CreateButton({
	Name = "Teleport to nearest MINI Chest Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local found = false
		for _, r in ipairs(_G.ScannedRooms) do
			if string.match(r.Id, "DeepChestRoom") ~= nil then
				found = true
				TeleportToRoom(r.uid)
				task.wait(0.3)
				local roomModel = r.Model
				local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
				if breakZone then
					local character = getCharacter()
					if character then
						character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 5, 0))
					end
				end
				break
			end
		end

		if not found then
			Rayfield:Notify({
				Title = "No Breakable Room",
				Content = "Could not find any scanned MINI Chest Room",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

BossTPButton = MiniBossTab:CreateButton({
	Name = "Teleport to Boss Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local found = false
		for _, r in ipairs(_G.ScannedRooms) do
			if r.Id == "GameMastersStage" then
				found = true
				TeleportToRoom(r.uid)
				task.wait(0.3)
				local roomModel = r.Model
				local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
				if breakZone then
					local character = getCharacter()
					if character then
						character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 5, 0))
					end
				end
				break
			end
		end

		if not found then
			Rayfield:Notify({
				Title = "No Boss Room",
				Content = "Could not find any scanned Boss Room",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

MiniBossTab:CreateSection("Auto Farm")

AutoFarmBoss = MiniBossTab:CreateToggle({
	Name = "Auto Farm Boss Room",
	CurrentValue = false,
	Flag = "AutoFarmBoss",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end

		if value then
			if AutoHatch ~= nil and _G.AutoHatch == true then
				AutoHatch:Set(false)
			end
			if AutoBestEgg ~= nil and _G.AutoTPBestEgg == true then
				AutoBestEgg:Set(false)
			end
		end

		_G.AutoMiniBoss = value
	end,
})

MiscTab:CreateSection("Enhancements")

InfPetSpeedButton = MiscTab:CreateToggle({
	Name = "Infinite Pet Speed",
	CurrentValue = false,
	Flag = "InfinitePetSpeed",
	Callback = function(value)
		_G.InfinitePetSpeed = value
	end,
})

AutoTapperToggle = MiscTab:CreateToggle({
	Name = "Auto Tapper",
	CurrentValue = false,
	Flag = "AutoTapper",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end

		_G.AutoTapper = value
	end,
})

MiscTab:CreateSection("Server")

RejoinButton = MiscTab:CreateButton({
	Name = "Rejoin",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
	end,
})

ServerHopButton = MiscTab:CreateButton({
	Name = "ServerHop",
	Callback = function()
		serverHop("Server Hopping...")
	end,
})

InfiniteYieldButton = MiscTab:CreateButton({
	Name = "Infinite Yield",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
	end,
})

task.spawn(function()
	while true do
		task.wait(1)

		if not _G.AutoTPBestEgg then
			continue
		end

		if isAutoAnomlyActive() then
			continue
		end

		if not canDoAction() then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local room = getBestEggRoom()
		if room then
			local isInRoom = isPlayerInRoom(room)
			if (not isInRoom) then
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

		if not _G.AutoTPLockedEgg then
			continue
		end

		if isAutoAnomlyActive() then
			continue
		end

		if not canDoAction() then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local room = getBestLockedEggRoom()
		if room then
			local isInRoom = isPlayerInRoom(room)
			if (not isInRoom) then
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

		if not _G.AutoTPAnomaly then
			continue
		end

		if not canDoAction() then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local isActive = workspace:GetAttribute("BackroomsAnomalyActive")
		local endsAt = workspace:GetAttribute("BackroomsAnomalyEndsAt")

		if not isActive or (type(endsAt) == "number" and workspace:GetServerTimeNow() > endsAt) then
			continue
		end

		local pos = workspace:GetAttribute("BackroomsAnomalyPos")
		if not pos then
			continue
		end

		local distance = (character:GetPivot().Position - pos).Magnitude
		if distance > 40 then
			Network.Fire("RequestStreaming", pos)
			character:PivotTo(CFrame.new(pos) + Vector3.new(0, 5, 0))
			task.wait(2)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)

		if not _G.AutoHatch then
			continue
		end

		if not canDoAction() then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		local egg = getNearestEgg(rootPart)
		if egg then
			pcall(function()
				Network.Invoke("CustomEggs_Hatch", egg._uid, EggCmds.GetMaxHatch(egg._dir))
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)

		if not _G.AutoMiniBoss then
			continue
		end

		if isAutoAnomlyActive() then
			continue
		end

		if not canDoAction() then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local targetRoom = nil
		for _, r in ipairs(_G.ScannedRooms) do
			if r.Id == "GameMastersStage" then
				targetRoom = r
				break
			end
		end

		if targetRoom then
			local uid = targetRoom.uid
			local roomModel = targetRoom.Model
			local pos = targetRoom.Position

			local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
			if breakZone then
				pos = breakZone:GetPivot().Position
			end

			local isInRoom = isPlayerInRoom(targetRoom)
			if (not isInRoom) then
				TeleportToRoom(uid)
				task.wait(2)
			else
				local targetBreakable = nil
				local breakables = workspace:FindFirstChild("__THINGS"):FindFirstChild("Breakables"):GetChildren()

				for _, breakable in ipairs(breakables) do
					local breakableId = breakable:GetAttribute("BreakableID")
					if breakableId == "Daydream Mimic Chest2" then
						local breakablePos = breakable:GetPivot().Position
						if (breakablePos - pos).Magnitude < 130 then
							targetBreakable = breakable
							break
						end
					end
				end

				if not targetBreakable then
					for _, breakable in ipairs(breakables) do
						local breakableId = breakable:GetAttribute("BreakableID")
						if breakableId == "Daydream Mimic Boss2" then
							local breakablePos = breakable:GetPivot().Position
							if (breakablePos - pos).Magnitude < 130 then
								targetBreakable = breakable
								break
							end
						end
					end
				end

				if targetBreakable then
					local breakableUID = targetBreakable:GetAttribute("BreakableUID")
					local breakablePos = targetBreakable:GetPivot().Position

					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:MoveTo(breakablePos)
					end

					Network.UnreliableFire("Breakables_PlayerDealDamage", breakableUID)

					local activePets = PlayerPet.GetByPlayer(localPlayer)
					for _, pet in pairs(activePets) do
						if pet.cpet then
							pet:SetTarget(targetBreakable)
						end
					end
				end
			end
		else
			serverHop("No Boss Room in this server. hopping...")
			task.wait(5)
		end 
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)

		if not _G.AutoTapper then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local breakables = workspace:FindFirstChild("__THINGS"):FindFirstChild("Breakables"):GetChildren()
		local tapRange = 150
		local nearestDistance = math.huge
		local nearestBreakableUID = nil

		for _, breakable in ipairs(breakables) do
			local uid = breakable:GetAttribute("BreakableUID")
			if uid and (not breakable:GetAttribute("ManualDamage")) and (not breakable:GetAttribute("DisableDamage")) then
				local breakablePos = breakable:GetPivot().Position
				local distance = (breakablePos - character:GetPivot().Position).Magnitude

				if tapRange > distance and distance < nearestDistance then
					nearestDistance = distance
					nearestBreakableUID = uid
				end
			end
		end

		if nearestBreakableUID then
			Signal.Fire("AutoClicker_Nearby", nearestBreakableUID)
		end
	end
end)

Network.Fired("Items: Update"):Connect(function(player, packet, currencyPacket)
	if not packet or not packet.set then
		return
	end

	for classKey, items in pairs(packet.set) do
		if classKey ~= "Pet" then
			continue
		end
		
		local classType = Types.TypeUnchecked(classKey)
		if classType then
			for itemUID, itemData in pairs(items) do
				if seenPets[itemUID] == true then
					continue
				end
				
				local item = classType:From(itemData)
				item:SetUID(itemUID)

				local exclusiveLevel = item:GetExclusiveLevel()
				if exclusiveLevel > 3 then
					seenPets[itemUID] = true

					local itemName = item:GetName()
					local itemIcon = item:GetIcon()
					local exists = item:GetExistCount()
					local rap = item:GetRAP()
					local thumbnailUrl = getThumbnailUrl(string.match(itemIcon, "%d+"))

					local embed = {
						title = "||" .. localPlayer.Name .. "|| just hatched a " .. itemName .. "!",
						color = 16753920,
						fields = {
							{
								name = "Exists",
								value = tostring(NumberShorten(exists)),
								inline = true
							},
							{
								name = "RAP",
								value = tostring(NumberShorten(rap)),
								inline = true
							}
						},
						footer = { text = "developed by mitzci0 <3" },
						timestamp = DateTime.now():ToIsoDate()
					}

					if thumbnailUrl then
						embed.thumbnail = { url = thumbnailUrl }
					end

					local content = (getgenv().discordId == "" or getgenv().discordId == nil)
						and "@everyone"
						or 	"@>" .. getgenv().discordId .. ">"		

					sendWebhook({
						username = "Unknown",
						avatar_url = "",
						content = content,
						embeds = { embed }
					})
				end
			end
		end
	end
end)

localPlayer.Idled:Connect(function()
	-- ANTI AFK
	Signal.Fire("ResetIdleTimer")
	VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

task.wait(5) -- DO NOT REMOVE
Scan()
Rayfield:LoadConfiguration()
