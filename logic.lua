-- logic.lua
local CONFIG = CONFIG or loadstring("")() -- assume defined in ui.lua environment

-- Game state
gameState = {
    currencies = { Energy = CONFIG.Currencies.Energy.start, Coins = CONFIG.Currencies.Coins.start, Gems = CONFIG.Currencies.Gems.start },
    upgrades = {}, stats = { totalEnergy = 0, totalCoins = 0, totalTaps = 0, playTime = 0 },
    settings = { activeTab = "Main", darkMode = true, soundEnabled = true, uiPosition = UDim2.new(0.5,0,0.5,0) }
}

for _, u in ipairs(CONFIG.UpgradeData) do
    gameState.upgrades[u.id] = { level = 0 }
end

local function formatNumber(n)
    return tostring(math.floor(n))
end

function calculateCurrentRates()
    local r = { tapPower = CONFIG.BaseRates.TapEnergy, passiveCoin = CONFIG.BaseRates.PassiveCoin, autoClicker = 0, conversion = CONFIG.BaseRates.ConversionRate }
    for _, u in ipairs(CONFIG.UpgradeData) do
        local lvl = gameState.upgrades[u.id].level
        local eff = u.effect(lvl)
        if u.id == "tap_power" then r.tapPower = eff
        elseif u.id == "passive_income" then r.passiveCoin = eff
        elseif u.id == "auto_clicker" then r.autoClicker = eff
        elseif u.id == "conversion_rate" then r.conversion = eff end
    end
    return r
end

function earnEnergy(amount)
    gameState.currencies.Energy += amount
    gameState.stats.totalEnergy += amount
end

function checkMilestones()
    for _, m in ipairs(CONFIG.MilestoneData) do
        if not m.claimed then
            local prog = ({energy = gameState.stats.totalEnergy, coins = gameState.stats.totalCoins, taps = gameState.stats.totalTaps, upgrades = function() local sum=0; for _,u in pairs(gameState.upgrades) do sum+=u.level end return sum end, gems = gameState.currencies.Gems })[m.id:match("^(%a+)_")]
            if prog and prog >= m.goal then
                m.claimed = true
                gameState.currencies.Gems += (m.reward.gems or 0)
                -- You can apply m.effect() to adjust multipliers here
            end
        end
    end
end

function purchaseUpgrade(id)
    local udata, state = nil, gameState.upgrades[id]
    for _, u in ipairs(CONFIG.UpgradeData) do if u.id == id then udata = u end end
    if udata and state.level < udata.maxLevel then
        local cost = udata.baseCost * (udata.costIncrease ^ state.level)
        if gameState.currencies.Coins >= cost then
            gameState.currencies.Coins -= cost
            state.level += 1
            return true
        end
    end
    return false
end

function simulateOfflineProgress()
    -- left blank for you to implement
end

function exportSaveString()
    -- left blank for you to implement
end

-- Expose for UI to call
globals = { calculateCurrentRates = calculateCurrentRates, earnEnergy = earnEnergy, checkMilestones = checkMilestones, purchaseUpgrade = purchaseUpgrade, formatNumber = formatNumber, simulateOfflineProgress = simulateOfflineProgress, exportSaveString = exportSaveString }
