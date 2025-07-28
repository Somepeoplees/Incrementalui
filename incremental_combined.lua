-- Combined Executor Script for Incremental Game


--[[ core.lua ]]
-- Core Variables and Upgrades

local currencies = {
    Energy = 0,
    Coins = 0,
    Gems = 0,
}

local upgrades = {
    tapPower = {level = 1, baseCost = 10},
    coinRate = {level = 1, baseCost = 20},
    autoClick = {level = 0, baseCost = 50},
    convertRate = {level = 1, baseCost = 100},
}

return {
    currencies = currencies,
    upgrades = upgrades
}


--[[ upgrades.lua ]]
-- Upgrade Manager

local core = loadstring(readfile("Incremental/core.lua"))()
local currencies = core.currencies
local upgrades = core.upgrades

local function canAfford(cost)
    return currencies.Coins >= cost
end

local function buyUpgrade(name)
    local upgrade = upgrades[name]
    if upgrade and canAfford(upgrade.baseCost * upgrade.level) then
        currencies.Coins -= upgrade.baseCost * upgrade.level
        upgrade.level += 1
        return true
    end
    return false
end

return {
    buyUpgrade = buyUpgrade,
    getUpgrades = function() return upgrades end
}


--[[ milestones.lua ]]
-- Milestone Tracker

local core = loadstring(readfile("Incremental/core.lua"))()
local currencies = core.currencies

local milestones = {
    {type="Energy", amount=1000, reward=function() core.upgrades.tapPower.level += 1 end, claimed=false},
    {type="Coins", amount=5000, reward=function() core.upgrades.coinRate.level += 1 end, claimed=false},
}

local function checkMilestones()
    for _, m in ipairs(milestones) do
        if not m.claimed and currencies[m.type] >= m.amount then
            m.reward()
            m.claimed = true
            print("Milestone achieved: " .. m.type .. " >= " .. m.amount)
        end
    end
end

spawn(function()
    while wait(5) do
        checkMilestones()
    end
end)

return {
    milestones = milestones
}


--[[ mods.lua ]]
-- Mod Loader

local mods = {}

local function runMod(scriptStr)
    local success, mod = pcall(loadstring(scriptStr))
    if success then
        table.insert(mods, mod)
        local ok, err = pcall(mod)
        if not ok then warn("Mod error:", err) end
    else
        warn("Invalid mod script")
    end
end

return {
    runMod = runMod,
    listMods = function() return mods end
}


--[[ automation.lua ]]
-- Automation Logic (auto tap, auto convert)

local core = loadstring(readfile("Incremental/core.lua"))()
local currencies = core.currencies
local upgrades = core.upgrades

spawn(function()
    while wait(1) do
        if upgrades.autoClick.level > 0 then
            currencies.Energy += upgrades.tapPower.level * upgrades.autoClick.level
        end
    end
end)

return {}


--[[ ui.lua ]]
-- UI Construction (Stub)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IncrementalUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "MainPanel"
frame.Size = UDim2.new(0.8, 0, 0.8, 0)
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Visible = true
frame.Parent = ScreenGui

return {}


--[[ tool.lua ]]
-- Tool Creation & Toggle UI

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function giveTool()
    local tool = Instance.new("Tool")
    tool.Name = "Incremental Device"
    tool.RequiresHandle = false
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
    
    local gui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("IncrementalUI")
    tool.Equipped:Connect(function()
        gui.Enabled = true
    end)
    
    tool.Unequipped:Connect(function()
        gui.Enabled = false
    end)
end

giveTool()

return {}


--[[ tick.lua ]]
-- Passive Tick Loop

local core = loadstring(readfile("Incremental/core.lua"))()
local currencies = core.currencies
local upgrades = core.upgrades

spawn(function()
    while wait(1) do
        currencies.Coins += upgrades.coinRate.level
    end
end)

return {}


--[[ init.lua logic (combined) ]]
if _G.IncrementalGame then return end
_G.IncrementalGame = true

print("Incremental Game Initialized")
