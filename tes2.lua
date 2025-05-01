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
local boxEspEnabled = true -- Box ESP toggle state
local distanceEspEnabled = true -- Distance ESP toggle state
local nameEspEnabled = true -- Name ESP toggle state

-- Preset FOV sizes to cycle through
local fovSizes = {10, 15, 20, 25}
local currentFovIndex = 2 -- Start at 15 (index 2 in fovSizes)

-- Preset aim parts to cycle through
local aimParts = {"Head", "HumanoidRootPart", "Random"}
local currentAimPartIndex = 1 -- Start at Head (index 1 in aimParts)

-- Wait for PlayerGui to be available
local success, playerGui = pcall(function()
    return player:WaitForChild("PlayerGui", 5)
end)
if not success or not playerGui then
    error("Failed to find PlayerGui: " .. (playerGui or "timeout"))
end

-- Create ScreenGui for GUI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true

-- Create circular Frame for FOV (outline only)
local fovFrame = Instance.new("Frame")
fovFrame.Parent = screenGui
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel = 0
fovFrame.Visible = true
fovFrame.ZIndex = 100
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)

-- Make the Frame circular
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = fovFrame

-- Add UIStroke for outline
local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = fovFrame
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Thickness = 4
uiStroke.Transparency = 0.2

-- Create TextLabel for aimlocked player
local targetLabel = Instance.new("TextLabel")
targetLabel.Parent = screenGui
targetLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
targetLabel.Position = UDim2.new(0.5, 0, 0.02, 0)
targetLabel.BackgroundTransparency = 0.5
targetLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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

-- Create TextBox for setting aim lock key
local keyInput = Instance.new("TextBox")
keyInput.Parent = screenGui
keyInput.Size = UDim2.new(0.05, 0, 0.05, 0)
keyInput.Position = UDim2.new(0.5, -120, 0.1, 0)
keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.Text = "E"
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

-- Create Toggle FOV Button
local fovToggleButton = Instance.new("TextButton")
fovToggleButton.Parent = screenGui
fovToggleButton.Size = UDim2.new(0.1, 0, 0.05, 0)
fovToggleButton.Position = UDim2.new(0.5, 20, 0.1, 0)
fovToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
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

-- Create Adjust FOV Button
local fovAdjustButton = Instance.new("TextButton")
fovAdjustButton.Parent = screenGui
fovAdjustButton.Size = UDim2.new(0.1, 0, 0.05, 0)
fovAdjustButton.Position = UDim2.new(0.5, 20, 0.18, 0)
fovAdjustButton.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
fovAdjustButton.Text = "FOV: " .. fovAngle
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

-- Create Aim Part Button
local aimPartButton = Instance.new("TextButton")
aimPartButton.Parent = screenGui
aimPartButton.Size = UDim2.new(0.1, 0, 0.05, 0)
aimPartButton.Position = UDim2.new(0.5, 20, 0.26, 0)
aimPartButton.BackgroundColor3 = Color3.fromRGB(150, 50, 150)
aimPartButton.Text = "Aim Part: " .. aimPartName
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

-- Create Toggle Box ESP Button
local boxEspToggleButton = Instance.new("TextButton")
boxEspToggleButton.Parent = screenGui
boxEspToggleButton.Size = UDim2.new(0.1, 0, 0.05, 0)
boxEspToggleButton.Position = UDim2.new(0.5, 20, 0.34, 0)
boxEspToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
boxEspToggleButton.Text = "Disable Box ESP"
boxEspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
boxEspToggleButton.TextScaled = true
boxEspToggleButton.ZIndex = 100
boxEspToggleButton.BorderSizePixel = 0
boxEspToggleButton.Visible = true
local boxEspButtonCorner = Instance.new("UICorner")
boxEspButtonCorner.CornerRadius = UDim.new(0, 8)
boxEspButtonCorner.Parent = boxEspToggleButton
-- Add a border
local boxEspButtonStroke = Instance.new("UIStroke")
boxEspButtonStroke.Parent = boxEspToggleButton
boxEspButtonStroke.Color = Color3.fromRGB(255, 255, 255)
boxEspButtonStroke.Thickness = 1
boxEspButtonStroke.Transparency = 0.5

-- Create Toggle Distance ESP Button
local distanceEspToggleButton = Instance.new("TextButton")
distanceEspToggleButton.Parent = screenGui
distanceEspToggleButton.Size = UDim2.new(0.1, 0, 0.05, 0)
distanceEspToggleButton.Position = UDim2.new(0.5, 20, 0.42, 0)
distanceEspToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
distanceEspToggleButton.Text = "Disable Distance ESP"
distanceEspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceEspToggleButton.TextScaled = true
distanceEspToggleButton.ZIndex = 100
distanceEspToggleButton.BorderSizePixel = 0
distanceEspToggleButton.Visible = true
local distanceEspButtonCorner = Instance.new("UICorner")
distanceEspButtonCorner.CornerRadius = UDim.new(0, 8)
distanceEspButtonCorner.Parent = distanceEspToggleButton
-- Add a border
local distanceEspButtonStroke = Instance.new("UIStroke")
distanceEspButtonStroke.Parent = distanceEspToggleButton
distanceEspButtonStroke.Color = Color3.fromRGB(255, 255, 255)
distanceEspButtonStroke.Thickness = 1
distanceEspButtonStroke.Transparency = 0.5

-- Create Toggle Name ESP Button
local nameEspToggleButton = Instance.new("TextButton")
nameEspToggleButton.Parent = screenGui
nameEspToggleButton.Size = UDim2.new(0.1, 0, 0.05, 0)
nameEspToggleButton.Position = UDim2.new(0.5, 20, 0.50, 0)
nameEspToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
nameEspToggleButton.Text = "Disable Name ESP"
nameEspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nameEspToggleButton.TextScaled = true
nameEspToggleButton.ZIndex = 100
nameEspToggleButton.BorderSizePixel = 0
nameEspToggleButton.Visible = true
local nameEspButtonCorner = Instance.new("UICorner")
nameEspButtonCorner.CornerRadius = UDim.new(0, 8)
nameEspButtonCorner.Parent = nameEspToggleButton
-- Add a border
local nameEspButtonStroke = Instance.new("UIStroke")
nameEspButtonStroke.Parent = nameEspToggleButton
nameEspButtonStroke.Color = Color3.fromRGB(255, 255, 255)
nameEspButtonStroke.Thickness = 1
nameEspButtonStroke.Transparency = 0.5

-- Create Unload Button
local unloadButton = Instance.new("TextButton")
unloadButton.Parent = screenGui
unloadButton.Size = UDim2.new(0.1, 0, 0.05, 0)
unloadButton.Position = UDim2.new(0.9, 0, 0.02, 0)
unloadButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
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

-- Store event connections for cleanup
local connections = {}

-- ESP storage
local espElements = {}

local function createBox(player)
    local boxGui = Instance.new("ScreenGui")
    boxGui.Parent = screenGui
    boxGui.IgnoreGuiInset = true
    boxGui.ResetOnSpawn = false
    boxGui.Enabled = boxEspEnabled

    local boxFrame = Instance.new("Frame")
    boxFrame.Parent = boxGui
    boxFrame.BackgroundTransparency = 1
    boxFrame.BorderSizePixel = 0
    boxFrame.ZIndex = 99

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = boxFrame
    uiStroke.Color = Color3.fromRGB(255, 0, 0)
    uiStroke.Thickness = 2
    uiStroke.Transparency = 0.3

    return boxFrame
end

local function createDistanceLabel(player)
    local distanceGui = Instance.new("ScreenGui")
    distanceGui.Parent = screenGui
    distanceGui.IgnoreGuiInset = true
    distanceGui.ResetOnSpawn = false
    distanceGui.Enabled = distanceEspEnabled

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Parent = distanceGui
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Size = UDim2.new(0, 100, 0, 20)
    distanceLabel.ZIndex = 99

    return distanceLabel
end

local function createNameLabel(player)
    local nameGui = Instance.new("ScreenGui")
    nameGui.Parent = screenGui
    nameGui.IgnoreGuiInset = true
    nameGui.ResetOnSpawn = false
    nameGui.Enabled = nameEspEnabled

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = nameGui
    nameLabel.BackgroundTransparency = 0.5
    nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Size = UDim2.new(0, 100, 0, 20)
    nameLabel.ZIndex = 99

    local nameStroke = Instance.new("UIStroke")
    nameStroke.Parent = nameLabel
    nameStroke.Color = Color3.fromRGB(255, 255, 255)
    nameStroke.Thickness = 1
    nameStroke.Transparency = 0.5

    return nameLabel
end

local function updateESP()
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = p.Character.HumanoidRootPart
            local head = p.Character:FindFirstChild("Head")
            if not espElements[p] then
                espElements[p] = {
                    box = createBox(p),
                    distance = createDistanceLabel(p),
                    name = createNameLabel(p)
                }
            end

            local box = espElements[p].box
            local distanceLabel = espElements[p].distance
            local nameLabel = espElements[p].name

            -- Update Box
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
            if onScreen and head then
                local headPos = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                local feetPos = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 4, 0))
                local boxSize = Vector2.new(math.abs(headPos.X - feetPos.X) * 2, math.abs(headPos.Y - feetPos.Y) * 1.5)
                box.Size = UDim2.new(0, boxSize.X, 0, boxSize.Y)
                box.Position = UDim2.new(0, headPos.X - boxSize.X / 2, 0, headPos.Y - boxSize.Y / 2)
                box.Visible = boxEspEnabled
            else
                box.Visible = false
            end

            -- Update Distance
            local distance = (player.Character and player.Character.HumanoidRootPart and rootPart) and (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude or 0
            distanceLabel.Text = string.format("%.1f studs", distance)
            if onScreen then
                distanceLabel.Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y + 20)
                distanceLabel.Visible = distanceEspEnabled
            else
                distanceLabel.Visible = false
            end

            -- Update Name
            if onScreen and head then
                local headScreenPos = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                nameLabel.Position = UDim2.new(0, headScreenPos.X - 50, 0, headScreenPos.Y - 20)
                nameLabel.Visible = nameEspEnabled
            else
                nameLabel.Visible = false
            end
        else
            if espElements[p] then
                espElements[p].box.Parent:Destroy()
                espElements[p].distance.Parent:Destroy()
                espElements[p].name.Parent:Destroy()
                espElements[p] = nil
            end
        end
    end
end

local function isWithinFOV(targetPos, camCFrame)
    local vectorToTarget = (targetPos - camCFrame.Position).Unit
    local cameraForward = camCFrame.LookVector
    local angle = math.deg(math.acos(vectorToTarget:Dot(cameraForward)))
    return angle <= fovAngle / 2
end

local function getClosestPlayer()
    -- If we already have a locked target, keep it
    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(aimPartName == "Random" and randomAimPart or aimPartName) then
        return currentTarget
    end

    -- Find a new target only if we don't have one
    local closestPlayer = nil
    local lastMagnitude = maxDistance
    local mousePos = mouse.Hit.Position
    local cam = workspace.CurrentCamera
    local effectiveAimPart = aimPartName == "Random" and randomAimPart or aimPartName

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

    currentTarget = closestPlayer
    return closestPlayer
end

local function AimLock()
    local effectiveAimPart = aimPartName == "Random" and randomAimPart or aimPartName
    local target = getClosestPlayer()

    if target and target.Character and target.Character:FindFirstChild(effectiveAimPart) then
        local aimPartPos = target.Character[effectiveAimPart].Position
        local cam = workspace.CurrentCamera
        local pos = cam.CFrame.Position
        local targetCFrame = CFrame.new(pos, aimPartPos)
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, smoothingFactor)
        targetLabel.Text = "Target: " .. target.Name
    else
        targetLabel.Text = "Target: None"
        currentTarget = nil -- Clear target if it's no longer valid
    end
end

local function updateFOVCircle()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local screenSize = cam.ViewportSize
    local center = UserInputService:GetMouseLocation()

    local camFOV = cam.FieldOfView
    local fovRadius = math.tan(math.rad(fovAngle / 2)) / math.tan(math.rad(camFOV / 2)) * screenSize.Y / 2

    fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
    fovFrame.Position = UDim2.fromOffset(center.X, center.Y)
end

-- Function to cycle FOV sizes
local function adjustFOV()
    currentFovIndex = (currentFovIndex % #fovSizes) + 1
    fovAngle = fovSizes[currentFovIndex]
    fovAdjustButton.Text = "FOV: " .. fovAngle
end

-- Function to cycle aim parts
local function adjustAimPart()
    currentAimPartIndex = (currentAimPartIndex % #aimParts) + 1
    aimPartName = aimParts[currentAimPartIndex]
    aimPartButton.Text = "Aim Part: " .. aimPartName
end

-- Function to update key binding
local function updateKeyBinding()
    for i = #connections, 1, -1 do
        local connection = connections[i]
        if connection == inputBeganConnection or connection == inputEndedConnection then
            connection:Disconnect()
            table.remove(connections, i)
        end
    end

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= currentKey then return end
        Aiming = true
        if aimPartName == "Random" then
            randomAimPart = math.random() > 0.5 and "Head" or "HumanoidRootPart"
        end
    end)
    table.insert(connections, inputBeganConnection)

    inputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed or input.KeyCode ~= currentKey then return end
        Aiming = false
        currentTarget = nil
        randomAimPart = nil
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
    boxEspToggleButton.Visible = buttonsVisible
    distanceEspToggleButton.Visible = buttonsVisible
    nameEspToggleButton.Visible = buttonsVisible
    unloadButton.Visible = buttonsVisible
    targetLabel.Visible = buttonsVisible
end

-- Function to toggle Box ESP
local function toggleBoxESP()
    boxEspEnabled = not boxEspEnabled
    boxEspToggleButton.Text = boxEspEnabled and "Disable Box ESP" or "Enable Box ESP"
    boxEspToggleButton.BackgroundColor3 = boxEspEnabled and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 50, 50)
    for _, elements in pairs(espElements) do
        elements.box.Parent.Enabled = boxEspEnabled
    end
end

-- Function to toggle Distance ESP
local function toggleDistanceESP()
    distanceEspEnabled = not distanceEspEnabled
    distanceEspToggleButton.Text = distanceEspEnabled and "Disable Distance ESP" or "Enable Distance ESP"
    distanceEspToggleButton.BackgroundColor3 = distanceEspEnabled and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 50, 50)
    for _, elements in pairs(espElements) do
        elements.distance.Parent.Enabled = distanceEspEnabled
    end
end

-- Function to toggle Name ESP
local function toggleNameESP()
    nameEspEnabled = not nameEspEnabled
    nameEspToggleButton.Text = nameEspEnabled and "Disable Name ESP" or "Enable Name ESP"
    nameEspToggleButton.BackgroundColor3 = nameEspEnabled and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 50, 50)
    for _, elements in pairs(espElements) do
        elements.name.Parent.Enabled = nameEspEnabled
    end
end

-- Handle key input from TextBox
local function onKeyInput()
    local input = keyInput.Text:upper():sub(1, 1)
    local keyCode = Enum.KeyCode[input]
    if keyCode then
        currentKey = keyCode
        keyInput.Text = input
        updateKeyBinding()
    else
        keyInput.Text = currentKey.Name
    end
end

-- Function to toggle FOV visibility
local function toggleFOV()
    fovVisible = not fovVisible
    fovFrame.Visible = fovVisible
    fovToggleButton.Text = fovVisible and "Hide FOV" or "Show FOV"
    fovToggleButton.BackgroundColor3 = fovVisible and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
end

-- Function to unload the script
local function unloadScript()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    for _, elements in pairs(espElements) do
        elements.box.Parent:Destroy()
        elements.distance.Parent:Destroy()
        elements.name.Parent:Destroy()
    end
    espElements = {}
    screenGui:Destroy()
end

-- Initialize input connections
local inputBeganConnection, inputEndedConnection
updateKeyBinding()

-- Connect TextBox input
table.insert(connections, keyInput.FocusLost:Connect(function()
    onKeyInput()
end))

-- Connect FOV toggle button
table.insert(connections, fovToggleButton.Activated:Connect(function()
    toggleFOV()
end))

-- Connect FOV adjust button
table.insert(connections, fovAdjustButton.Activated:Connect(function()
    adjustFOV()
end))

-- Connect Aim Part button
table.insert(connections, aimPartButton.Activated:Connect(function()
    adjustAimPart()
end))

-- Connect Box ESP toggle button
table.insert(connections, boxEspToggleButton.Activated:Connect(function()
    toggleBoxESP()
end))

-- Connect Distance ESP toggle button
table.insert(connections, distanceEspToggleButton.Activated:Connect(function()
    toggleDistanceESP()
end))

-- Connect Name ESP toggle button
table.insert(connections, nameEspToggleButton.Activated:Connect(function()
    toggleNameESP()
end))

-- Connect unload button
table.insert(connections, unloadButton.Activated:Connect(function()
    unloadScript()
end))

-- Connect Right-Alt key for toggling buttons
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.RightAlt then return end
    toggleButtons()
end))

-- Update aim lock, FOV circle, and ESP
table.insert(connections, RunService.RenderStepped:Connect(function()
    if Aiming then
        AimLock()
    end
    if fovVisible then
        updateFOVCircle()
    end
    updateESP()
end))

-- Cleanup when ScreenGui is destroyed
table.insert(connections, screenGui.AncestryChanged:Connect(function()
    if not screenGui:IsDescendantOf(game) then
        screenGui:Destroy()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        connections = {}
        for _, elements in pairs(espElements) do
            elements.box.Parent:Destroy()
            elements.distance.Parent:Destroy()
            elements.name.Parent:Destroy()
        end
        espElements = {}
    end
end))
