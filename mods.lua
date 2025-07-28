-- mods.lua
local user, repo, branch = "Somepeoplees", "Incrementalui", "main"
local base = ("https://raw.githubusercontent.com/%s/%s/%s/mods/"):format(user, repo, branch)

-- List of mod filenames (hardcoded or dynamically defined)
local modList = { "ExampleMod.lua" }  -- add more filenames as mods grow

for _, filename in ipairs(modList) do
    local url = base .. filename
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if ok and src then
        local fn, err = loadstring(src)
        if fn then
            local success, result = pcall(fn, gameState, globals)
            if not success then warn("[Mod] Failed on " .. filename .. ": " .. tostring(result)) end
        else
            warn("[Mod] Compile error in " .. filename .. ": " .. tostring(err))
        end
    else
        warn("[Mod] Could not download " .. filename)
    end
end

-- Info Button popup using clipboard
setclipboard([[
MOD CREATION TEMPLATE:
return function(gameState, globals)
  -- Use {
  --   globals.calculateCurrentRates(),
  --   globals.earnEnergy(amount),
  --   globals.purchaseUpgrade(id),
  --   gameState.currencies, gameState.upgrades
  -- } to interact.
end
]])
