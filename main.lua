--[[
    main.lua - Roblox Executor Script Loader
    Loads and executes multiple Lua files from:
    https://github.com/Somepeoplees/Incrementalui

    ❗ This script is designed for Roblox executors only.
    ✅ Fully client-side
    ✅ Supports mobile executors (Arceus X, Delta, Hydrogen)
--]]

local user = "Somepeoplees"
local repo = "Incrementalui"
local branch = "main"

-- ✅ List of script files to load
local scriptList = {
    "ui.lua",
    "logic.lua",
    "upgrades.lua",
    "mods.lua"
}

-- 🧠 Optional safety check: detect suspicious nested loaders
local function isSuspicious(source)
    return source:find("loadstring") or source:find("game:HttpGet") or source:find("HttpPost")
end

-- 🚀 Load and execute each script
for _, file in ipairs(scriptList) do
    local url = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(user, repo, branch, file)

    -- Fetch script from GitHub
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success and response then
        -- Scan for risky code (optional)
        if isSuspicious(response) then
            warn("[⚠️] Suspicious code detected in '" .. file .. "' — skipping execution.")
        else
            local func, loadErr = loadstring(response)
            if func then
                local ran, execErr = pcall(func)
                if ran then
                    print("[✅] Loaded: " .. file)
                else
                    warn("[❌] Runtime error in '" .. file .. "': " .. tostring(execErr))
                end
            else
                warn("[❌] Compile error in '" .. file .. "': " .. tostring(loadErr))
            end
        end
    else
        warn("[🚫] Failed to fetch '" .. file .. "' from GitHub.")
    end
end
