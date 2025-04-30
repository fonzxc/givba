local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Aiming = false
local maxDistance = 100 -- Maximum distance to consider targets
local fovAngle = 10 -- Initial FOV angle in degrees
local aimPartName = "Head" -- Part to aim at
local currentKey = Enum.KeyCode.E -- Default aim lock key
local fovVisible = true -- FOV circle visibility state
local currentTarget = nil -- Track the current target to prevent jitter
local smoothingFactor = 1 -- Smoothing factor for camera interpolation (0 to 1, lower = smoother)
local buttonsVisible = true -- Track button visibility state
local randomAimPart = nil -- Store the randomly selected aim part when aim lock is activated

-- Preset FOV sizes to cycle through
local fovSizes = {10, 15, 20, 25}
local currentFovIndex = 2 -- Start at 60 (index 2 in fovSizes)

-- Preset aim parts to cycle through
local aimParts = {"Head", "HumanoidRootPart", "Random"}
local currentAimPartIndex = 1 -- Start at Head (index 1 in aimParts)

-- Wait for PlayerGui to be available
if not player:WaitForChild("PlayerGui", 5) then
    error("PlayerGui not found")
end

-- Create ScreenGui for GUI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true -- Explicitly enable
print("ScreenGui created and parented to PlayerGui")

-- Create circular Frame for FOV (outline only)
local fovFrame = Instance.new("Frame")
fovFrame.Parent = screenGui
fovFrame.BackgroundTransparency = 1 -- Invisible background
fovFrame.BorderSizePixel = 0
fovFrame.Visible = true -- Initially visible
fovFrame.ZIndex = 100 -- High ZIndex to avoid overlap
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Center the frame on its position
print("FOV Frame created")

-- Make the Frame circular
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0) -- Fully circular
uiCorner.Parent = fovFrame

-- Add UIStroke for outline
local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = fovFrame
uiStroke.Color = Color3.fromRGB(255, 255, 255) -- White outline
uiStroke.Thickness = 4 -- Thicker outline for visibility
uiStroke.Transparency = 0.2 -- Slightly transparent outline

-- Create TextLabel for aimlocked player
local targetLabel = Instance.new("TextLabel")
targetLabel.Parent = screenGui
targetLabel.Size = UDim2.new(0.2, 0, 0.05, 0) -- Scale-based size
targetLabel.Position = UDim2.new(0.5, 0, 0.02, 0) -- Top-center
targetLabel.BackgroundTransparency = 0.5
targetLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
targetLabel.Text = "Target: None"
targetLabel.TextScaled = true
targetLabel.ZIndex = 100
targetLabel.Visible = true
-- Add a border for clarity
local labelStroke = Instance.new("UIStroke")
labelStroke.Parent = targetLabel
labelStroke.Color = Color3.fromRGB(255, 255, 255)
labelStroke.Thickness = 1
labelStroke.Transparency = 0.5
print("Target Label created")

-- Create TextBox for setting aim lock key
local keyInput = Instance.new("TextBox")
keyInput.Parent = screenGui
keyInput.Size = UDim2.new(0.05, 0, 0.05, 0) -- Scale-based size
keyInput.Position = UDim2.new(0.5, -120, 0.1, 0) -- Below-left of target label with offset
keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Dark gray background
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.Text = "E" -- Default key
keyInput.TextScaled = true
keyInput.ZIndex = 100
keyInput.PlaceholderText = "Key"
keyInput.Visible = true
local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyInput
-- Add a border
local keyStroke = Instance.new("UIStroke")
keyStroke.Parent = keyInput
keyStroke.Color = Color3.fromRGB(255, 255, 255)
keyStroke.Thickness = 1
keyStroke.Transparency = 0.5
print("Key Input TextBox created")

-- Create Toggle FOV Button
local fovToggleButton = Instance.new("TextButton")
fovToggleButton.Parent = screenGui
fovToggleButton.Size = UDim2.new(0.1, 0, 0.05, 0) -- Scale-based size
fovToggleButton.Position = UDim2.new(0.5, 20, 0.1, 0) -- Below-right of target label with offset
fovToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50) -- Green when FOV on
fovToggleButton.Text = "Hide FOV"
fovToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fovToggleButton.TextScaled = true
fovToggleButton.ZIndex = 100
fovToggleButton.BorderSizePixel = 0
fovToggleButton.Visible = true
local fovButtonCorner = Instance.new("UICorner")
fovButtonCorner.CornerRadius = UDim.new(0, 8)
fovButtonCorner.Parent = fovToggleButton
-- Add a border
local fovButtonStroke = Instance.new("UIStroke")
fovButtonStroke.Parent = fovToggleButton
fovButtonStroke.Color = Color3.fromRGB(255, 255, 255)
fovButtonStroke.Thickness = 1
fovButtonStroke.Transparency = 0.5
print("FOV Toggle Button created")

-- Create Adjust FOV Button
local fovAdjustButton = Instance.new("TextButton")
fovAdjustButton.Parent = screenGui
fovAdjustButton.Size = UDim2.new(0.1, 0, 0.05, 0) -- Scale-based size
fovAdjustButton.Position = UDim2.new(0.5, 20, 0.18, 0) -- Below the FOV toggle button
fovAdjustButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150) -- Blue background
fovAdjustButton.Text = "FOV: " .. fovAngle -- Initial text
fovAdjustButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fovAdjustButton.TextScaled = true
fovAdjustButton.ZIndex = 100
fovAdjustButton.BorderSizePixel = 0
fovAdjustButton.Visible = true
local adjustButtonCorner = Instance.new("UICorner")
adjustButtonCorner.CornerRadius = UDim.new(0, 8)
adjustButtonCorner.Parent = fovAdjustButton
-- Add a border
local adjustButtonStroke = Instance.new("UIStroke")
adjustButtonStroke.Parent = fovAdjustButton
adjustButtonStroke.Color = Color3.fromRGB(255, 255, 255)
adjustButtonStroke.Thickness = 1
adjustButtonStroke.Transparency = 0.5
print("FOV Adjust Button created")

-- Create Aim Part Button
local aimPartButton = Instance.new("TextButton")
aimPartButton.Parent = screenGui
aimPartButton.Size = UDim2.new(0.1, 0, 0.05, 0) -- Scale-based size
aimPartButton.Position = UDim2.new(0.5, 20, 0.26, 0) -- Below the FOV adjust button
aimPartButton.BackgroundColor3 = Color3.fromRGB(150, 50, 150) -- Purple background
aimPartButton.Text = "Aim Part: " .. aimPartName -- Initial text
aimPartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimPartButton.TextScaled = true
aimPartButton.ZIndex = 100
aimPartButton.BorderSizePixel = 0
aimPartButton.Visible = true
local aimPartButtonCorner = Instance.new("UICorner")
aimPartButtonCorner.CornerRadius = UDim.new(0, 8)
aimPartButtonCorner.Parent = aimPartButton
-- Add a border
local aimPartButtonStroke = Instance.new("UIStroke")
aimPartButtonStroke.Parent = aimPartButton
aimPartButtonStroke.Color = Color3.fromRGB(255, 255, 255)
aimPartButtonStroke.Thickness = 1
aimPartButtonStroke.Transparency = 0.5
print("Aim Part Button created")

-- Create Unload Button
local unloadButton = Instance.new("TextButton")
unloadButton.Parent = screenGui
unloadButton.Size = UDim2.new(0.1, 0, 0.05, 0) -- Scale-based size
unloadButton.Position = UDim2.new(0.9, 0, 0.02, 0) -- Top-right
unloadButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red background
unloadButton.Text = "Unload Script"
unloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadButton.TextScaled = true
unloadButton.ZIndex = 100
unloadButton.BorderSizePixel = 0
unloadButton.Visible = true
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = unloadButton
-- Add a border
local unloadButtonStroke = Instance.new("UIStroke")
unloadButtonStroke.Parent = unloadButton
unloadButtonStroke.Color = Color3.fromRGB(255, 255, 231)
unloadButtonStroke.Thickness = 1
unloadButtonStroke.Transparency = 0.5
print("Unload Button created")

-- Store event connections for cleanup
local connections = {}

local function isWithinFOV(targetPos, camCFrame)
    local vectorToTarget = (targetPos - camCFrame.Position).Unit
    local cameraForward = camCFrame.LookVector
    local angle = math.deg(math.acos(vectorToTarget:Dot(cameraForward)))
    return angle <= fovAngle / 2
end

local function getClosestPlayer()
    -- Determine the part to aim at
    local effectiveAimPart = aimPartName == "Random" and randomAimPart or aimPartName

    -- If we have a current target, check if it's still valid
    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(effectiveAimPart) then
        local aimPart = currentTarget.Character[effectiveAimPart]
        local charPos = aimPart.Position
        local mousePos = mouse.Hit.Position
        local cam = workspace.CurrentCamera
        local magnitude = (charPos - mousePos).Magnitude
        if magnitude <= maxDistance and isWithinFOV(charPos, cam.CFrame) then
            return currentTarget -- Keep the current target
        else
            currentTarget = nil -- Clear the target if out of range or FOV
        end
    end

    -- Find a new target if none exists or the current one is invalid
    local closestPlayer = nil
    local lastMagnitude = maxDistance
    local mousePos = mouse.Hit.Position
    local cam = workspace.CurrentCamera

    for _, v in ipairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild(effectiveAimPart) then
            local aimPart = v.Character[effectiveAimPart]
            local charPos = aimPart.Position
            local magnitude = (charPos - mousePos).Magnitude
            if magnitude < lastMagnitude and isWithinFOV(charPos, cam.CFrame) then
                lastMagnitude = magnitude
                closestPlayer = v
            end
        end
    end

    currentTarget = closestPlayer -- Update the current target
    return closestPlayer
end

local function AimLock()
    -- Determine the part to aim at
    local effectiveAimPart = aimPartName == "Random" and randomAimPart or aimPartName

    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild(effectiveAimPart) then
        local aimPartPos = target.Character[effectiveAimPart].Position
        local cam = workspace.CurrentCamera
        local pos = cam.CFrame.Position
        local targetCFrame = CFrame.new(pos, aimPartPos)
        -- Smoothly interpolate the camera's CFrame
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, smoothingFactor)
        targetLabel.Text = "Target: " .. target.Name
    else
        targetLabel.Text = "Target: None"
    end
end

local function updateFOVCircle()
    local cam = workspace.CurrentCamera
    local screenSize = cam.ViewportSize
    local center = UserInputService:GetMouseLocation() -- More reliable mouse position

    -- Debug: Print mouse position
    print("Mouse Position: ", center.X, center.Y)

    -- Calculate FOV radius in pixels
    local camFOV = cam.FieldOfView
    local fovRadius = math.tan(math.rad(fovAngle / 2)) / math.tan(math.rad(camFOV / 2)) * screenSize.Y / 2

    -- Update FOV circle, centering on mouse
    fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovFrame.Position = UDim2.fromOffset(center.X, center.Y) -- Explicit pixel offset
end

-- Function to cycle FOV sizes
local function adjustFOV()
    -- Increment the index, looping back to 1 if exceeding the table length
    currentFovIndex = (currentFovIndex % #fovSizes) + 1
    fovAngle = fovSizes[currentFovIndex]
    fovAdjustButton.Text = "FOV: " .. fovAngle
    print("FOV adjusted to: ", fovAngle)
end

-- Function to cycle aim parts
local function adjustAimPart()
    -- Increment the index, looping back to 1 if exceeding the table length
    currentAimPartIndex = (currentAimPartIndex % #aimParts) + 1
    aimPartName = aimParts[currentAimPartIndex]
    aimPartButton.Text = "Aim Part: " .. aimPartName
    print("Aim part adjusted to: ", aimPartName)
end

-- Function to update key binding
local function updateKeyBinding()
    -- Disconnect existing input connections
    for i = #connections, 1, -1 do
        local connection = connections[i]
        if connection == inputBeganConnection or connection == inputEndedConnection then
            connection:Disconnect()
            table.remove(connections, i)
        end
    end

    -- Connect new input events
    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= currentKey then return end
        Aiming = true
        -- Set random aim part when aim lock is activated if Random is selected
        if aimPartName == "Random" then
            randomAimPart = math.random() > 0.5 and "Head" or "HumanoidRootPart"
            print("Random aim part selected: ", randomAimPart)
        end
        print("Aim lock activated with key: ", currentKey.Name)
    end)
    table.insert(connections, inputBeganConnection)

    inputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= currentKey then return end
        Aiming = false
        currentTarget = nil -- Clear the target when aiming stops
        randomAimPart = nil -- Clear random aim part when aim lock stops
        print("Aim lock deactivated")
    end)
    table.insert(connections, inputEndedConnection)
end

-- Function to toggle all buttons visibility
local function toggleButtons()
    buttonsVisible = not buttonsVisible
    keyInput.Visible = buttonsVisible
    fovToggleButton.Visible = buttonsVisible
    fovAdjustButton.Visible = buttonsVisible
    aimPartButton.Visible = buttonsVisible
    unloadButton.Visible = buttonsVisible
    targetLabel.Visible = buttonsVisible
    print("Buttons Visible: ", buttonsVisible)
end

-- Handle key input from TextBox
local function onKeyInput()
    local input = keyInput.Text:upper():sub(1, 1) -- Get first character, uppercase
    local keyCode = Enum.KeyCode[input]
    if keyCode then
        currentKey = keyCode
        keyInput.Text = input -- Update TextBox to show valid key
        updateKeyBinding()
        print("Aim lock key set to: ", input)
    else
        keyInput.Text = currentKey.Name -- Revert to current key if invalid
        print("Invalid key entered: ", input)
    end
end

-- Function to toggle FOV visibility
local function toggleFOV()
    fovVisible = not fovVisible
    fovFrame.Visible = fovVisible
    fovToggleButton.Text = fovVisible and "Hide FOV" or "Show FOV"
    fovToggleButton.BackgroundColor3 = fovVisible and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    print("FOV Visible: ", fovVisible)
end

-- Function to unload the script
local function unloadScript()
    -- Disconnect all stored connections
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    
    -- Destroy the ScreenGui
    print("Destroying ScreenGui")
    screenGui:Destroy()
    
    -- Print confirmation
    print("Script unloaded successfully")
end

-- Initialize input connections
local inputBeganConnection, inputEndedConnection
updateKeyBinding()

-- Connect TextBox input
table.insert(connections, keyInput.FocusLost:Connect(function()
    print("Key TextBox input received")
    onKeyInput()
end))

-- Connect FOV toggle button
table.insert(connections, fovToggleButton.Activated:Connect(function()
    print("FOV Toggle Button clicked")
    toggleFOV()
end))

-- Connect FOV adjust button
table.insert(connections, fovAdjustButton.Activated:Connect(function()
    print("FOV Adjust Button clicked")
    adjustFOV()
end))

-- Connect Aim Part button
table.insert(connections, aimPartButton.Activated:Connect(function()
    print("Aim Part Button clicked")
    adjustAimPart()
end))

-- Connect unload button
table.insert(connections, unloadButton.Activated:Connect(function()
    print("Unload Button clicked")
    unloadScript()
end))

-- Connect Right-Alt key for toggling buttons
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.RightAlt then return end
    toggleButtons()
end))

-- Update aim lock and FOV circle
table.insert(connections, RunService.RenderStepped:Connect(function()
    if Aiming then
        AimLock()
    end
    if fovVisible then
        updateFOVCircle()
    end
end))

-- Cleanup when ScreenGui is destroyed
table.insert(connections, screenGui.AncestryChanged:Connect(function()
    if not screenGui:IsDescendantOf(game) then
        screenGui:Destroy()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        connections = {}
        print("ScreenGui destroyed due to ancestry change")
    end
end))
