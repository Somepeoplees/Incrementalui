-- Base raw URL of your GitHub repo
local baseURL = "https://raw.githubusercontent.com/Somepeoplees/Incrementalui/main/"

-- List of all script files in your repository (case-sensitive)
local scriptList = {
    "config.lua",
    "ui.lua",
    "upgrades.lua",
    "milestones.lua",
    "currencies.lua",
    "modloader.lua",
    "autosave.lua",
    "mainlogic.lua",
    -- Add more scripts here if you upload them
}

-- Function to safely load a remote script
local function importScript(name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(baseURL .. name))()
    end)

    if not success then
        warn("[INCREMENTALUI] Failed to load: " .. name .. " -> " .. tostring(result))
    else
        print("[INCREMENTALUI] Loaded: " .. name)
    end
end

-- Load all scripts in order
for _, scriptName in ipairs(scriptList) do
    importScript(scriptName)
end

-- Optional: load main game loop or UI initializer last
-- importScript("game.lua")
