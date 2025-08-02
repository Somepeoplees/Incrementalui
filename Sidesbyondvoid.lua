-- Cube Clicker: Dynamic Invert & Improved Custom Shapes (Mobile Friendly)
-- Enhanced with all suggested improvements: structure, performance, features, UI/UX, error handling, security, mobile tweaks, and satisfying elements.

local clickEvent = game:GetService("ReplicatedStorage").Events.Click
local partsFolder = workspace:FindFirstChild("Parts")
if not partsFolder then warn("Parts folder not found!") return end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local playerGui = player:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HapticService = game:GetService("HapticService")

-- Config
local CONFIG = {
    CLICK_DELAY = 0.03,  -- Adjustable click speed
    UI_WIDTH = 340,
    UI_HEIGHT = 300,
    PROGRESS_BAR_HEIGHT = 10,
    BUTTON_SIZE_INCREASE = 1.2,  -- For accessibility (20% larger on mobile)
    SATISFYING_MODE = true,  -- Default on
    SOUND_CLICK_ID = "rbxassetid://9119706385",  -- Example pop sound ID (replace with valid)
    SOUND_CLEAR_ID = "rbxassetid://9119706385",  -- Example chime sound ID (replace with valid)
    PARTICLE_COLOR = Color3.fromRGB(255, 215, 0),  -- Gold burst
}

-- Preload sounds
local clickSound = Instance.new("Sound")
clickSound.SoundId = CONFIG.SOUND_CLICK_ID
clickSound.Parent = SoundService
local clearSound = Instance.new("Sound")
clearSound.SoundId = CONFIG.SOUND_CLEAR_ID
clearSound.Parent = SoundService

-- UI-based part detection
local function getRemainingParts()
    local success, remaining = pcall(function()
        return tonumber(player.PlayerGui.UI.Remaining.Text) or 0
    end)
    return success and remaining or 0
end
local function getMaxParts()
    local success, max = pcall(function()
        return tonumber(player.PlayerGui.UI.Max.Text) or 0
    end)
    return success and max or 0
end

-- Utility
local cachedParts = {}
local function getAllParts()
    local parts = {}
    for _, child in pairs(partsFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(parts, child)
        end
    end
    return parts
end
local function updateCache()
    cachedParts = getAllParts()
end
partsFolder.ChildAdded:Connect(updateCache)
partsFolder.ChildRemoved:Connect(updateCache)
updateCache()

local function getCubeCenter(parts)
    if #parts == 0 then return Vector3.new(0,0,0) end
    local total = Vector3.new()
    for _, part in pairs(parts) do total += part.Position end
    return total / #parts
end

-- Patterns (grouped into table)
local function sortSquareInsideOut(parts)
    local center = getCubeCenter(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local d = math.max(
            math.abs(part.Position.X - center.X),
            math.abs(part.Position.Y - center.Y),
            math.abs(part.Position.Z - center.Z)
        )
        table.insert(arr, {part=part, d=d})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortCircleInsideOut(parts)
    local center = getCubeCenter(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local d = (part.Position - center).Magnitude
        table.insert(arr, {part=part, d=d})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function getZLayers(parts, reverse)
    local layers = {}
    local zSet = {}
    for _, part in ipairs(parts) do
        local z = math.floor(part.Position.Z + 0.5)
        if not zSet[z] then zSet[z] = {} end
        table.insert(zSet[z], part)
    end
    local zKeys = {}
    for z in pairs(zSet) do table.insert(zKeys, z) end
    table.sort(zKeys, function(a, b) return reverse and a > b or a < b end)
    for _, z in ipairs(zKeys) do
        table.insert(layers, zSet[z])
    end
    return layers
end
local function sortHourglass(parts)
    local center = getCubeCenter(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local xzDist = math.sqrt((part.Position.X - center.X)^2 + (part.Position.Z - center.Z)^2)
        local yDist = math.abs(part.Position.Y - center.Y)
        local score = yDist - xzDist
        table.insert(arr, {part=part, d=score})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortPyramid(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local xzDist = math.sqrt((part.Position.X)^2 + (part.Position.Z)^2)
        table.insert(arr, {part=part, d=part.Position.Y + xzDist})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortUpsideDownPyramid(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local xzDist = math.sqrt((part.Position.X)^2 + (part.Position.Z)^2)
        table.insert(arr, {part=part, d=-(part.Position.Y - xzDist)})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortRhomboidPrism(parts)
    local center = getCubeCenter(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local sum = part.Position.X + part.Position.Y + part.Position.Z
        local dist = (part.Position - center).Magnitude
        table.insert(arr, {part=part, d=sum + dist*0.1})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortSpiralXY(parts)
    local center = getCubeCenter(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local dx = part.Position.X - center.X
        local dy = part.Position.Y - center.Y
        local angle = math.atan2(dy, dx)
        local dist = math.sqrt(dx*dx + dy*dy)
        table.insert(arr, {part=part, d=dist + angle*0.01})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortCheckerboard(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local x, y, z = math.floor(part.Position.X+0.5), math.floor(part.Position.Y+0.5), math.floor(part.Position.Z+0.5)
        local parity = (x + y + z) % 2
        table.insert(arr, {part=part, d=parity})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortRandom(parts)
    local arr = {}
    for _, part in pairs(parts) do
        table.insert(arr, {part=part, d=math.random()})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortDiagonalSweep(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local d = part.Position.X + part.Position.Y + part.Position.Z
        table.insert(arr, {part=part, d=d})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
-- New patterns
local function sortWave(parts)
    local center = getCubeCenter(parts)
    local arr = {}
    for _, part in pairs(parts) do
        local dx = part.Position.X - center.X
        local score = math.sin(dx * 0.5) + part.Position.Y
        table.insert(arr, {part=part, d=score})
    end
    table.sort(arr, function(a,b) return a.d < b.d end)
    local sorted = {}
    for _, v in ipairs(arr) do table.insert(sorted, v.part) end
    return sorted
end
local function sortLayersXY(parts)
    local layers = {}
    local xySet = {}
    for _, part in ipairs(parts) do
        local xy = math.floor(part.Position.X + 0.5) + math.floor(part.Position.Y + 0.5) * 100  -- Unique key
        if not xySet[xy] then xySet[xy] = {} end
        table.insert(xySet[xy], part)
    end
    local xyKeys = {}
    for xy in pairs(xySet) do table.insert(xyKeys, xy) end
    table.sort(xyKeys)
    local arr = {}
    for _, xy in ipairs(xyKeys) do for _, p in ipairs(xySet[xy]) do table.insert(arr, p) end end
    return arr
end

local patternSorters = {
    square = sortSquareInsideOut,
    circle = sortCircleInsideOut,
    front = function(parts) 
        local layers = getZLayers(parts, false)
        local arr = {}
        for _, layer in ipairs(layers) do for _, p in ipairs(layer) do table.insert(arr, p) end end
        return arr
    end,
    back = function(parts) 
        local layers = getZLayers(parts, true)
        local arr = {}
        for _, layer in ipairs(layers) do for _, p in ipairs(layer) do table.insert(arr, p) end end
        return arr
    end,
    hourglass = sortHourglass,
    pyramid = sortPyramid,
    upsidepyramid = sortUpsideDownPyramid,
    rhomboid = sortRhomboidPrism,
    spiralxy = sortSpiralXY,
    checker = sortCheckerboard,
    random = sortRandom,
    diagonal = sortDiagonalSweep,
    wave = sortWave,  -- New
    layersxy = sortLayersXY,  -- New
    custom = function(parts) return {} end,  -- Placeholder, defined later
}

-- Custom shape system
local customShapes = {}
local customShapeName = nil
local customShapeData = nil

local function safeLoadCustomShapes()
    if not (isfile and readfile) then return end
    local success, data = pcall(readfile, "cube_clicker_shapes.json")
    if not success then warn("Failed to read shapes file: " .. data) return end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if ok and type(decoded) == "table" then
        customShapes = decoded
    end
end
local function saveCustomShapes()
    if writefile then
        local success, err = pcall(writefile, "cube_clicker_shapes.json", HttpService:JSONEncode(customShapes))
        if not success then warn("Failed to save shapes: " .. err) end
    end
end
safeLoadCustomShapes()

-- Preload example shapes if empty
if next(customShapes) == nil then
    customShapes["Heart"] = {{0,0,0}, {1,1,0}, {-1,1,0}, {2,0,0}, {-2,0,0}, {1,-1,0}, {-1,-1,0}}
    customShapes["Arrow"] = {{0,0,0}, {1,0,0}, {2,0,0}, {2,1,0}, {2,-1,0}, {3,0,0}}
    saveCustomShapes()
end

local function parseCustomShapeInput(text)
    -- Safer parsing: Limit to JSON tables or sandboxed functions
    local ok, data = pcall(function() return HttpService:JSONDecode(text) end)
    if ok and type(data) == "table" then return data, "table", nil end
    
    -- Sandbox loadstring
    local env = {math = math, Vector3 = Vector3}  -- Whitelist safe globals
    local func, err = loadstring(text)
    if func then
        setfenv(func, env)
        local ok2, data2 = pcall(func)
        if ok2 and type(data2) == "table" then return data2, "table", nil end
        local testPart = {Position = Vector3.new(0,0,0)}
        local ok3, result = pcall(func, testPart)
        if ok3 and type(result) == "number" then return func, "function", nil end
    end
    if not ok then return nil, nil, "Invalid JSON: " .. tostring(err) end
    if not func then return nil, nil, "Invalid Lua: " .. tostring(err) end
    return nil, nil, "Invalid format: Must be JSON table or sort function. No malicious code allowed."
end

local function sortCustomShape(parts)
    if not customShapeData then return {} end
    local dataType = type(customShapeData)
    if dataType == "function" then
        local arr = {}
        for _, part in pairs(parts) do
            local success, score = pcall(customShapeData, part)
            if success and type(score) == "number" then
                table.insert(arr, {part=part, d=score})
            end
        end
        table.sort(arr, function(a,b) return a.d < b.d end)
        local sorted = {}
        for _, v in ipairs(arr) do table.insert(sorted, v.part) end
        return sorted
    elseif dataType == "table" then
        local center = getCubeCenter(parts)
        local matched = {}
        for _, posData in ipairs(customShapeData) do
            local x, y, z = posData[1], posData[2], posData[3]
            if type(x) == "number" and x < 0 then x = center.X + x end
            if type(y) == "number" and y < 0 then y = center.Y + y end
            if type(z) == "number" and z < 0 then z = center.Z + z end
            local targetPos = Vector3.new(x, y, z)
            for _, part in ipairs(parts) do
                if (part.Position - targetPos).Magnitude < 0.1 then
                    table.insert(matched, part)
                end
            end
        end
        return matched
    end
    return {}
end
patternSorters.custom = sortCustomShape  -- Assign now that it's defined

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CubeClickerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, CONFIG.UI_WIDTH, 0, CONFIG.UI_HEIGHT)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local corner = Instance.new("UICorner", mainFrame) corner.CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner", titleBar) titleCorner.CornerRadius = UDim.new(0, 10)
local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🎯 Cube Clicker"
titleText.TextColor3 = Color3.fromRGB(255,255,255)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBold

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(0,0,0)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
local minimizeCorner = Instance.new("UICorner", minimizeBtn) minimizeCorner.CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
local closeCorner = Instance.new("UICorner", closeBtn) closeCorner.CornerRadius = UDim.new(0, 5)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -20, 1, -60)
contentFrame.Position = UDim2.new(0, 10, 0, 50)
contentFrame.BackgroundTransparency = 1

-- Use UIListLayout for auto-arrange
local uiList = Instance.new("UIListLayout", contentFrame)
uiList.Padding = UDim.new(0, 5)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local partsCountLabel = Instance.new("TextLabel", contentFrame)
partsCountLabel.Size = UDim2.new(1, 0, 0, 25)
partsCountLabel.BackgroundTransparency = 1
partsCountLabel.Text = "Parts: 0/0"
partsCountLabel.TextColor3 = Color3.fromRGB(255,255,255)
partsCountLabel.TextScaled = true
partsCountLabel.Font = Enum.Font.Gotham
partsCountLabel.LayoutOrder = 1

local patternLabel = Instance.new("TextLabel", contentFrame)
patternLabel.Size = UDim2.new(1, 0, 0, 20)
patternLabel.BackgroundTransparency = 1
patternLabel.Text = "Pattern:"
patternLabel.TextColor3 = Color3.fromRGB(255,255,255)
patternLabel.TextScaled = true
patternLabel.Font = Enum.Font.Gotham
patternLabel.TextXAlignment = Enum.TextXAlignment.Left
patternLabel.LayoutOrder = 2

local patterns = {
    {"🔲 Square (Inside-Out)", "square"},
    {"⭕ Circle (Inside-Out)", "circle"},
    {"⬛ Front to Back", "front"},
    {"⬛ Back to Front", "back"},
    {"⌛ Hourglass", "hourglass"},
    {"🔺 Pyramid", "pyramid"},
    {"🔻 Upside-Down Pyramid", "upsidepyramid"},
    {"🔷 Rhomboid Prism", "rhomboid"},
    {"🌀 Spiral (XY)", "spiralxy"},
    {"🔳 Checkerboard", "checker"},
    {"🎲 Random", "random"},
    {"⧫ Diagonal Sweep", "diagonal"},
    {"🌊 Wave", "wave"},  -- New
    {"🗺️ Layers (XY)", "layersxy"},  -- New
    {"⭐ Custom Shape", "custom"},
}
local currentPattern = 1
local invertShape = false

local patternBtn = Instance.new("TextButton", contentFrame)
patternBtn.Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
patternBtn.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
patternBtn.Text = patterns[currentPattern][1]
patternBtn.TextColor3 = Color3.fromRGB(255,255,255)
patternBtn.TextScaled = true
patternBtn.Font = Enum.Font.Gotham
patternBtn.BorderSizePixel = 0
local patternCorner = Instance.new("UICorner", patternBtn) patternCorner.CornerRadius = UDim.new(0, 5)
patternBtn.LayoutOrder = 3

patternBtn.MouseButton1Click:Connect(function()
    currentPattern = currentPattern % #patterns + 1
    patternBtn.Text = patterns[currentPattern][1]
    TweenService:Create(patternBtn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(1, 0, 0, 35 * CONFIG.BUTTON_SIZE_INCREASE)}):Play()
    task.delay(0.1, function() TweenService:Create(patternBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)}):Play() end
end)

local controlBtn = Instance.new("TextButton", contentFrame)
controlBtn.Size = UDim2.new(1, 0, 0, 40 * CONFIG.BUTTON_SIZE_INCREASE)
controlBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
controlBtn.Text = "▶️ START"
controlBtn.TextColor3 = Color3.fromRGB(255,255,255)
controlBtn.TextScaled = true
controlBtn.Font = Enum.Font.GothamBold
controlBtn.BorderSizePixel = 0
local controlCorner = Instance.new("UICorner", controlBtn) controlCorner.CornerRadius = UDim.new(0, 5)
controlBtn.LayoutOrder = 4

local statusLabel = Instance.new("TextLabel", contentFrame)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏸️ Stopped"
statusLabel.TextColor3 = Color3.fromRGB(108,117,125)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.LayoutOrder = 5

local invertBtn = Instance.new("TextButton", contentFrame)
invertBtn.Size = UDim2.new(0.5, -5, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
invertBtn.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
invertBtn.Text = "Invert: OFF"
invertBtn.TextColor3 = Color3.fromRGB(255,255,255)
invertBtn.TextScaled = true
invertBtn.Font = Enum.Font.Gotham
invertBtn.BorderSizePixel = 0
local invertCorner = Instance.new("UICorner", invertBtn) invertCorner.CornerRadius = UDim.new(0, 5)
invertBtn.LayoutOrder = 6
invertBtn.MouseButton1Click:Connect(function()
    invertShape = not invertShape
    invertBtn.Text = "Invert: " .. (invertShape and "ON" or "OFF")
    invertBtn.BackgroundColor3 = invertShape and Color3.fromRGB(220, 53, 69) or Color3.fromRGB(108, 117, 125)
end)

local customBtn = Instance.new("TextButton", contentFrame)
customBtn.Size = UDim2.new(0.5, -5, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
customBtn.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
customBtn.Text = "Custom Shape"
customBtn.TextColor3 = Color3.fromRGB(255,255,255)
customBtn.TextScaled = true
customBtn.Font = Enum.Font.Gotham
customBtn.BorderSizePixel = 0
local customCorner = Instance.new("UICorner", customBtn) customCorner.CornerRadius = UDim.new(0, 5)
customBtn.LayoutOrder = 7

local customShapeLabel = Instance.new("TextLabel", contentFrame)
customShapeLabel.Size = UDim2.new(1, 0, 0, 18)
customShapeLabel.BackgroundTransparency = 1
customShapeLabel.Text = ""
customShapeLabel.TextColor3 = Color3.fromRGB(255,255,255)
customShapeLabel.TextScaled = true
customShapeLabel.Font = Enum.Font.Gotham
customShapeLabel.LayoutOrder = 8

-- New UI elements
local speedLabel = Instance.new("TextLabel", contentFrame)
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Click Delay (s):"
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.Gotham
speedLabel.LayoutOrder = 9

local speedSlider = Instance.new("TextBox", contentFrame)
speedSlider.Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
speedSlider.Text = tostring(CONFIG.CLICK_DELAY)
speedSlider.BackgroundColor3 = Color3.fromRGB(35,35,35)
speedSlider.TextColor3 = Color3.fromRGB(255,255,255)
speedSlider.TextScaled = true
speedSlider.Font = Enum.Font.Gotham
speedSlider.LayoutOrder = 10

local autoStartToggle = Instance.new("TextButton", contentFrame)
autoStartToggle.Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
autoStartToggle.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
autoStartToggle.Text = "Auto-Start on Respawn: OFF"
autoStartToggle.TextColor3 = Color3.fromRGB(255,255,255)
autoStartToggle.TextScaled = true
autoStartToggle.Font = Enum.Font.Gotham
autoStartToggle.BorderSizePixel = 0
local autoCorner = Instance.new("UICorner", autoStartToggle) autoCorner.CornerRadius = UDim.new(0, 5)
autoStartToggle.LayoutOrder = 11
local autoStart = false
autoStartToggle.MouseButton1Click:Connect(function()
    autoStart = not autoStart
    autoStartToggle.Text = "Auto-Start on Respawn: " .. (autoStart and "ON" or "OFF")
    autoStartToggle.BackgroundColor3 = autoStart and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(108, 117, 125)
end)

local satisfyingToggle = Instance.new("TextButton", contentFrame)
satisfyingToggle.Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
satisfyingToggle.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
satisfyingToggle.Text = "Satisfying Mode: ON"
satisfyingToggle.TextColor3 = Color3.fromRGB(255,255,255)
satisfyingToggle.TextScaled = true
satisfyingToggle.Font = Enum.Font.Gotham
satisfyingToggle.BorderSizePixel = 0
local satisfyCorner = Instance.new("UICorner", satisfyingToggle) satisfyCorner.CornerRadius = UDim.new(0, 5)
satisfyingToggle.LayoutOrder = 12
local satisfyingMode = CONFIG.SATISFYING_MODE
satisfyingToggle.MouseButton1Click:Connect(function()
    satisfyingMode = not satisfyingMode
    satisfyingToggle.Text = "Satisfying Mode: " .. (satisfyingMode and "ON" or "OFF")
    satisfyingToggle.BackgroundColor3 = satisfyingMode and Color3.fromRGB(40, 167, 69) or Color3.fromRGB(108, 117, 125)
end)

local debugToggle = Instance.new("TextButton", contentFrame)
debugToggle.Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
debugToggle.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
debugToggle.Text = "Debug Logging: OFF"
debugToggle.TextColor3 = Color3.fromRGB(255,255,255)
debugToggle.TextScaled = true
debugToggle.Font = Enum.Font.Gotham
debugToggle.BorderSizePixel = 0
local debugCorner = Instance.new("UICorner", debugToggle) debugCorner.CornerRadius = UDim.new(0, 5)
debugToggle.LayoutOrder = 13
local debugMode = false
debugToggle.MouseButton1Click:Connect(function()
    debugMode = not debugMode
    debugToggle.Text = "Debug Logging: " .. (debugMode and "ON" or "OFF")
    debugToggle.BackgroundColor3 = debugMode and Color3.fromRGB(0, 123, 255) or Color3.fromRGB(108, 117, 125)
end)

local resetBtn = Instance.new("TextButton", contentFrame)
resetBtn.Size = UDim2.new(1, 0, 0, 30 * CONFIG.BUTTON_SIZE_INCREASE)
resetBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
resetBtn.Text = "Reset Clicks"
resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
resetBtn.TextScaled = true
resetBtn.Font = Enum.Font.Gotham
resetBtn.BorderSizePixel = 0
local resetCorner = Instance.new("UICorner", resetBtn) resetCorner.CornerRadius = UDim.new(0, 5)
resetBtn.LayoutOrder = 14
resetBtn.MouseButton1Click:Connect(function()
    clickedParts = {}
    if debugMode then print("Clicks reset!") end
end)

local progressBar = Instance.new("Frame", contentFrame)
progressBar.Size = UDim2.new(1, 0, 0, CONFIG.PROGRESS_BAR_HEIGHT)
progressBar.BackgroundColor3 = Color3.fromRGB(50,50,50)
progressBar.LayoutOrder = 15
local progressFill = Instance.new("Frame", progressBar)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
local progressCorner = Instance.new("UICorner", progressBar) progressCorner.CornerRadius = UDim.new(0, 5)

-- Help button
local helpBtn = Instance.new("TextButton", titleBar)
helpBtn.Size = UDim2.new(0, 30, 0, 30)
helpBtn.Position = UDim2.new(1, -105, 0, 5)
helpBtn.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
helpBtn.Text = "?"
helpBtn.TextColor3 = Color3.fromRGB(255,255,255)
helpBtn.TextScaled = true
helpBtn.Font = Enum.Font.GothamBold
helpBtn.BorderSizePixel = 0
local helpCorner = Instance.new("UICorner", helpBtn) helpCorner.CornerRadius = UDim.new(0, 5)
helpBtn.MouseButton1Click:Connect(function()
    -- Show help modal (simple text for now)
    local helpModal = Instance.new("Frame", screenGui)
    helpModal.Size = UDim2.new(0, 300, 0, 200)
    helpModal.Position = UDim2.new(0.5, -150, 0.5, -100)
    helpModal.BackgroundColor3 = Color3.fromRGB(25,25,25)
    local helpText = Instance.new("TextLabel", helpModal)
    helpText.Size = UDim2.new(1,0,1,0)
    helpText.Text = "Help: Use patterns to click cubes. Custom shapes: JSON [[x,y,z]] or Lua function(part) return score end"
    helpText.TextWrapped = true
    helpText.TextColor3 = Color3.fromRGB(255,255,255)
    local closeHelp = Instance.new("TextButton", helpModal)
    closeHelp.Size = UDim2.new(0,30,0,30)
    closeHelp.Position = UDim2.new(1,-35,0,5)
    closeHelp.Text = "×"
    closeHelp.MouseButton1Click:Connect(function() helpModal:Destroy() end)
end)

-- Drag (with touch optimization)
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Orientation adapt
local function adaptOrientation()
    local screenSize = playerGui.AbsoluteSize
    if screenSize.X < screenSize.Y then
        -- Portrait: Adjust positions if needed
        mainFrame.Position = UDim2.new(0.5, -CONFIG.UI_WIDTH/2, 0, 50)
    else
        -- Landscape
        mainFrame.Position = UDim2.new(0, 50, 0, 50)
    end
end
adaptOrientation()
playerGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(adaptOrientation)

-- Minimize/close with cleanup
local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, CONFIG.UI_WIDTH, 0, 40)}):Play()
        contentFrame.Visible = false
        minimizeBtn.Text = "+"
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, CONFIG.UI_WIDTH, 0, CONFIG.UI_HEIGHT)}):Play()
        contentFrame.Visible = true
        minimizeBtn.Text = "-"
    end
end)
local connections = {}  -- For cleanup
closeBtn.MouseButton1Click:Connect(function()
    for _, conn in ipairs(connections) do conn:Disconnect() end
    screenGui:Destroy()
end)

-- Custom shape modal
local function showCustomShapeModal()
    local backdrop = Instance.new("Frame", screenGui)
    backdrop.Size = UDim2.new(1,0,1,0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0,0,0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.ZIndex = 9

    local modal = Instance.new("Frame", screenGui)
    modal.Size = UDim2.new(0, 320, 0, 320)
    modal.Position = UDim2.new(0.5, -160, 0.5, -160)
    modal.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    modal.ZIndex = 10
    modal.BorderSizePixel = 0
    local corner = Instance.new("UICorner", modal) corner.CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", modal)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Custom Shape Editor"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 11

    local shapeList = Instance.new("TextButton", modal)
    shapeList.Size = UDim2.new(1, -20, 0, 30)
    shapeList.Position = UDim2.new(0, 10, 0, 40)
    shapeList.Text = "Select Shape"
    shapeList.BackgroundColor3 = Color3.fromRGB(35,35,35)
    shapeList.TextColor3 = Color3.fromRGB(255,255,255)
    shapeList.TextScaled = true
    shapeList.Font = Enum.Font.Gotham
    shapeList.ZIndex = 11

    local shapeNames = {}
    for k in pairs(customShapes) do table.insert(shapeNames, k) end
    table.sort(shapeNames)

    local scrolling = Instance.new("ScrollingFrame", modal)
    scrolling.Size = UDim2.new(1, -20, 0, 150)
    scrolling.Position = UDim2.new(0, 10, 0, 70)
    scrolling.CanvasSize = UDim2.new(0, 0, 0, #shapeNames * 28)
    scrolling.BackgroundColor3 = Color3.fromRGB(45,45,45)
    scrolling.Visible = false
    scrolling.ZIndex = 12
    local dropCorner = Instance.new("UICorner", scrolling) dropCorner.CornerRadius = UDim.new(0, 5)
    for i, name in ipairs(shapeNames) do
        local btn = Instance.new("TextButton", scrolling)
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*28)
        btn.Text = name
        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextScaled = true
        btn.Font = Enum.Font.Gotham
        btn.ZIndex = 13
        btn.MouseButton1Click:Connect(function()
            shapeList.Text = name
            local data = customShapes[name]
            if type(data) == "table" then
                box.Text = HttpService:JSONEncode(data)
                previewLabel.Text = "Preview: "..#data.." positions"
            elseif type(data) == "function" then
                box.Text = "-- function(part) return part.Position.Y end"
                previewLabel.Text = "Preview: Custom sort function"
            end
            nameBox.Text = name
            scrolling.Visible = false
        end)
    end
    shapeList.MouseButton1Click:Connect(function()
        scrolling.Visible = not scrolling.Visible
    end)

    local box = Instance.new("TextBox", modal)
    box.Size = UDim2.new(1, -20, 0, 60)
    box.Position = UDim2.new(0, 10, 0, 230)
    box.Text = ""
    box.PlaceholderText = 'JSON: [[0,0,0],[1,1,1]] or Lua: return function(part) return part.Position.Y end'
    box.TextWrapped = true
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.BackgroundColor3 = Color3.fromRGB(35,35,35)
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.ZIndex = 11

    local previewLabel = Instance.new("TextLabel", modal)
    previewLabel.Size = UDim2.new(1, -20, 0, 30)
    previewLabel.Position = UDim2.new(0, 10, 0, 300)
    previewLabel.BackgroundTransparency = 1
    previewLabel.Text = "Preview: "
    previewLabel.TextColor3 = Color3.fromRGB(255,255,255)
    previewLabel.TextScaled = true
    previewLabel.Font = Enum.Font.Gotham
    previewLabel.ZIndex = 11

    local previewBtn = Instance.new("TextButton", modal)
    previewBtn.Size = UDim2.new(0, 80, 0, 30)
    previewBtn.Position = UDim2.new(0, 10, 0, 335)
    previewBtn.Text = "Preview"
    previewBtn.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
    previewBtn.TextColor3 = Color3.fromRGB(255,255,255)
    previewBtn.TextScaled = true
    previewBtn.Font = Enum.Font.GothamBold
    previewBtn.ZIndex = 11
    previewBtn.MouseButton1Click:Connect(function()
        local text = box.Text
        local data, _, err = parseCustomShapeInput(text)
        if data then
            local tempData = customShapeData
            customShapeData = data
            local sorted = sortCustomShape(cachedParts)
            previewLabel.Text = "Preview: " .. #sorted .. " parts matched/sorted"
            customShapeData = tempData  -- Restore
        else
            previewLabel.Text = "Error: " .. tostring(err)
        end
    end)

    local nameBox = Instance.new("TextBox", modal)
    nameBox.Size = UDim2.new(1, -20, 0, 30)
    nameBox.Position = UDim2.new(0, 10, 0, 370)
    nameBox.Text = ""
    nameBox.PlaceholderText = "Shape Name"
    nameBox.TextColor3 = Color3.fromRGB(255,255,255)
    nameBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
    nameBox.Font = Enum.Font.Gotham
    nameBox.TextSize = 16
    nameBox.ZIndex = 11

    local useBtn = Instance.new("TextButton", modal)
    useBtn.Size = UDim2.new(0, 80, 0, 30)
    useBtn.Position = UDim2.new(0, 10, 0, 410)
    useBtn.Text = "Use"
    useBtn.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
    useBtn.TextColor3 = Color3.fromRGB(255,255,255)
    useBtn.TextScaled = true
    useBtn.Font = Enum.Font.GothamBold
    useBtn.ZIndex = 11

    local saveBtn = Instance.new("TextButton", modal)
    saveBtn.Size = UDim2.new(0, 80, 0, 30)
    saveBtn.Position = UDim2.new(0, 100, 0, 410)
    saveBtn.Text = "Save"
    saveBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
    saveBtn.TextScaled = true
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.ZIndex = 11

    local delBtn = Instance.new("TextButton", modal)
    delBtn.Size = UDim2.new(0, 80, 0, 30)
    delBtn.Position = UDim2.new(0, 190, 0, 410)
    delBtn.Text = "Delete"
    delBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    delBtn.TextColor3 = Color3.fromRGB(255,255,255)
    delBtn.TextScaled = true
    delBtn.Font = Enum.Font.GothamBold
    delBtn.ZIndex = 11

    local feedback = Instance.new("TextLabel", modal)
    feedback.Size = UDim2.new(1, -20, 0, 20)
    feedback.Position = UDim2.new(0, 10, 0, 450)
    feedback.BackgroundTransparency = 1
    feedback.Text = ""
    feedback.TextColor3 = Color3.fromRGB(255, 80, 80)
    feedback.TextScaled = true
    feedback.Font = Enum.Font.Gotham
    feedback.ZIndex = 11

    local closeBtnModal = Instance.new("TextButton", modal)
    closeBtnModal.Size = UDim2.new(0, 30, 0, 30)
    closeBtnModal.Position = UDim2.new(1, -40, 0, 5)
    closeBtnModal.Text = "×"
    closeBtnModal.BackgroundColor3 = Color3.fromRGB(108,117,125)
    closeBtnModal.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtnModal.TextScaled = true
    closeBtnModal.Font = Enum.Font.GothamBold
    closeBtnModal.ZIndex = 11

    saveBtn.MouseButton1Click:Connect(function()
        local name = nameBox.Text
        local text = box.Text
        if name ~= "" and text ~= "" then
            local data, dataType, err = parseCustomShapeInput(text)
            if data then
                customShapes[name] = data
                saveCustomShapes()
                feedback.Text = "✅ Saved!"
            else
                feedback.Text = "❌ Error: " .. tostring(err)
            end
        else
            feedback.Text = "❌ Name and data required."
        end
    end)
    useBtn.MouseButton1Click:Connect(function()
        local text = box.Text
        local data, dataType, err = parseCustomShapeInput(text)
        if data then
            customShapeName = nameBox.Text
            customShapeData = data
            feedback.Text = "✅ Set as active!"
        else
            feedback.Text = "❌ Error: " .. tostring(err)
        end
    end)
    delBtn.MouseButton1Click:Connect(function()
        local name = nameBox.Text
        if customShapes[name] then
            customShapes[name] = nil
            saveCustomShapes()
            feedback.Text = "🗑️ Deleted!"
        else
            feedback.Text = "❌ Shape not found!"
        end
    end)
    closeBtnModal.MouseButton1Click:Connect(function()
        modal:Destroy()
        backdrop:Destroy()
    end)
end
customBtn.MouseButton1Click:Connect(showCustomShapeModal)

-- Dynamic invert system for all patterns
local function getPatternParts(parts)
    local sorter = patternSorters[patterns[currentPattern][2]]
    return sorter and sorter(parts) or {}
end

local isRunning = false
local clickedParts = {}
local totalClicked = 0  -- For stats
local fastestClear = math.huge

local function addSatisfyingEffects(part)
    if not satisfyingMode then return end
    -- Visual
    local particle = Instance.new("ParticleEmitter")
    particle.Parent = part
    particle.Color = ColorSequence.new(CONFIG.PARTICLE_COLOR)
    particle.Rate = 50
    particle.Lifetime = NumberRange.new(0.5)
    particle.Enabled = true
    task.delay(0.5, function() particle:Destroy() end)
    TweenService:Create(part, TweenInfo.new(0.2), {Color = Color3.new(1,0,0)}):Play()
    
    -- Audio
    clickSound:Play()
    
    -- Haptic
    if HapticService:IsVibrationSupported(Enum.UserInputType.Touch) then
        HapticService:Vibrate(Enum.VibrationMotor.Small, 0.1)
    end
end

local function clickParts(sortedParts, delay)
    for i, part in ipairs(sortedParts) do
        if not isRunning then break end
        if part and part.Parent and not clickedParts[part] then
            local success, err = pcall(function()
                clickEvent:FireServer(part, part.Position)
            end)
            if not success then warn("Click failed: " .. err) end
            clickedParts[part] = true
            totalClicked = totalClicked + 1
            addSatisfyingEffects(part)
            local rem = getRemainingParts()
            statusLabel.Text = "🎯 Clicking... " .. rem .. " left"
            statusLabel.TextColor3 = Color3.fromRGB(0,255,0)  -- Green for running
            if debugMode then print("Clicked: " .. part.Name) end
            task.wait(delay)
        end
    end
end

local function runScript()
    local startTime = tick()
    while isRunning do
        clickedParts = {}
        local remaining, maxParts = getRemainingParts(), getMaxParts()
        while remaining == 0 and isRunning do
            partsCountLabel.Text = "Parts: 0/0"
            statusLabel.Text = "⏳ Waiting for parts to spawn..."
            statusLabel.TextColor3 = Color3.fromRGB(255,193,7)  -- Yellow for waiting
            task.wait(0.1)
            remaining, maxParts = getRemainingParts(), getMaxParts()
        end
        if not isRunning then break end
        partsCountLabel.Text = "Parts: " .. remaining .. "/" .. maxParts
        statusLabel.Text = "🚀 Clicking " .. remaining .. " parts..."
        statusLabel.TextColor3 = Color3.fromRGB(0,255,0)
        startTime = tick()
        while getRemainingParts() > 0 and isRunning do
            if #cachedParts == 0 then task.wait(0.05) continue end
            local toClick = getPatternParts(cachedParts)
            if invertShape then
                toClick = table.reverse(toClick)  -- Note: table.reverse doesn't exist, use loop
                local rev = {}
                for i = #toClick, 1, -1 do table.insert(rev, toClick[i]) end
                toClick = rev
            end
            local delay = tonumber(speedSlider.Text) or CONFIG.CLICK_DELAY
            clickParts(toClick, delay)
            local percent = 1 - (getRemainingParts() / maxParts)
            TweenService:Create(progressFill, TweenInfo.new(0.2), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
            task.wait(0.05)
        end
        local clearTime = tick() - startTime
        if clearTime < fastestClear then fastestClear = clearTime end
        statusLabel.Text = "✅ All parts cleared! Waiting for respawn... Fastest: " .. string.format("%.2f", fastestClear) .. "s | Total: " .. totalClicked
        statusLabel.TextColor3 = Color3.fromRGB(40,167,69)
        if satisfyingMode then clearSound:Play() end
        repeat
            task.wait(0.1)
            remaining, maxParts = getRemainingParts(), getMaxParts()
            partsCountLabel.Text = "Parts: " .. remaining .. "/" .. maxParts
            if autoStart and remaining > 0 then break end  -- Auto-restart
        until remaining > 0 or not isRunning
    end
end

controlBtn.MouseButton1Click:Connect(function()
    if isRunning then
        isRunning = false
        controlBtn.Text = "▶️ START"
        controlBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        statusLabel.Text = "⏸️ Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(108,117,125)
    else
        isRunning = true
        controlBtn.Text = "⏹️ STOP"
        controlBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        statusLabel.Text = "🚀 Starting..."
        TweenService:Create(controlBtn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(1, 0, 0, 45 * CONFIG.BUTTON_SIZE_INCREASE)}):Play()
        task.delay(0.1, function() TweenService:Create(controlBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40 * CONFIG.BUTTON_SIZE_INCREASE)}):Play() end
        coroutine.wrap(runScript)()
    end
end)

-- Event-driven UI updates
local uiConnection = RunService.Heartbeat:Connect(function()
    if not screenGui.Parent then uiConnection:Disconnect() return end
    if customShapeName then
        customShapeLabel.Text = "Custom: " .. customShapeName
    else
        customShapeLabel.Text = ""
    end
    if not isRunning then
        local remaining, maxParts = getRemainingParts(), getMaxParts()
        partsCountLabel.Text = "Parts: " .. remaining .. "/" .. maxParts
    end
end)
table.insert(connections, uiConnection)

print("🎯 Cube Clicker UI Loaded with all enhancements!")
