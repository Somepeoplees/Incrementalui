-- ui.lua (creates UI and tool)
local player = game.Players.LocalPlayer
local coins = 0
local multiplier = 1

-- Tool
local tool = Instance.new("Tool")
tool.Name = "IncrementalTool"
tool.RequiresHandle = false
tool.CanBeDropped = false
tool.Parent = player:WaitForChild("Backpack")

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "IncrementalUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0.8, 0, 0.65, 0)
frame.Position = UDim2.new(0.1, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0
frame.Visible = false

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0.1, 0)
title.Text = "INCREMENTAL GAME"
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold

-- Currency
local currencyLabel = Instance.new("TextLabel", frame)
currencyLabel.Size = UDim2.new(1, 0, 0.1, 0)
currencyLabel.Position = UDim2.new(0, 0, 0.1, 0)
currencyLabel.Text = "Coins: 0"
currencyLabel.TextScaled = true
currencyLabel.TextColor3 = Color3.fromRGB(255,255,100)
currencyLabel.BackgroundTransparency = 1
currencyLabel.Font = Enum.Font.GothamBold

-- Clicker Button
local clicker = Instance.new("TextButton", frame)
clicker.Size = UDim2.new(0.8, 0, 0.2, 0)
clicker.Position = UDim2.new(0.1, 0, 0.22, 0)
clicker.Text = "Click +1"
clicker.TextScaled = true
clicker.BackgroundColor3 = Color3.fromRGB(60,60,60)
clicker.Font = Enum.Font.Gotham
clicker.TextColor3 = Color3.new(1, 1, 1)

clicker.MouseButton1Click:Connect(function()
    coins += multiplier
    currencyLabel.Text = "Coins: " .. coins
end)

-- Upgrade
local upgrade = Instance.new("TextButton", frame)
upgrade.Size = UDim2.new(0.8, 0, 0.15, 0)
upgrade.Position = UDim2.new(0.1, 0, 0.45, 0)
upgrade.Text = "Upgrade (+1 per click, Cost: 10)"
upgrade.TextScaled = true
upgrade.BackgroundColor3 = Color3.fromRGB(40,80,40)
upgrade.Font = Enum.Font.Gotham
upgrade.TextColor3 = Color3.new(1, 1, 1)

upgrade.MouseButton1Click:Connect(function()
    local cost = multiplier * 10
    if coins >= cost then
        coins -= cost
        multiplier += 1
        currencyLabel.Text = "Coins: " .. coins
        upgrade.Text = "Upgrade (+1, Cost: " .. (multiplier * 10) .. ")"
        clicker.Text = "Click +" .. multiplier
    end
end)

-- Mods Tab
local modsButton = Instance.new("TextButton", frame)
modsButton.Size = UDim2.new(0.8, 0, 0.1, 0)
modsButton.Position = UDim2.new(0.1, 0, 0.65, 0)
modsButton.Text = "Mods / Add-ons"
modsButton.TextScaled = true
modsButton.Font = Enum.Font.Gotham
modsButton.BackgroundColor3 = Color3.fromRGB(45,45,75)
modsButton.TextColor3 = Color3.new(1, 1, 1)

modsButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Somepeoplees/Incrementalui/main/mods.lua"))()
end)

-- Tool toggles UI
tool.Equipped:Connect(function() frame.Visible = true end)
tool.Unequipped:Connect(function() frame.Visible = false end)
