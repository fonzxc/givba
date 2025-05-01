local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Aiming = false
local maxDistance = 100 -- Maximum distance to consider targets
local fovAngle = 15 -- Initial FOV angle in degrees
local aimPartName = "Head" -- Part to aim at
local currentKey = Enum.KeyCode.E -- Default aim lock key
local fovVisible = true -- FOV circle visibility state
local currentTarget = nil -- Track the current target
local smoothingFactor = 1 -- Smoothing factor (0 to 1, lower = smoother)
local buttonsVisible = true -- Track button visibility state
local randomAimPart = nil -- Store random aim part when aim lock is activated
local boxEspEnabled = true -- Box ESP toggle state
local distanceEspEnabled = true -- Distance ESP toggle state
local nameEspEnabled = true -- Name ESP toggle state

-- Wait for PlayerGui
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

-- Create settings frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Parent = screenGui
settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
settingsFrame.BorderSizePixel = 0
settingsFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
settingsFrame.Size = UDim2.new(0.15, 0, 0.6, 0)
settingsFrame.ZIndex = 100
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = settingsFrame

-- Add UIListLayout
local listLayout = Instance.new("UIListLayout")
listLayout.Parent = settingsFrame
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Create title label
local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = settingsFrame
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aim Lock Settings"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.ZIndex = 100

-- Create TextBox for aim lock key
local keyInput = Instance.new("TextBox")
keyInput.Parent = settingsFrame
keyInput.Size = UDim2.new(1, 0, 0, 30)
keyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.Text = "E"
keyInput.TextScaled = true
keyInput.PlaceholderText = "Key"
keyInput.ZIndex = 100
local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyInput
local keyStroke = Instance.new("UIStroke")
keyStroke.Parent = keyInput
keyStroke.Color = Color3.fromRGB(255, 255, 255)
keyStroke.Thickness = 1
keyStroke.Transparency = 0.5

-- Create Toggle FOV Button
local fovToggleButton = Instance.new("TextButton")
fovToggleButton.Parent = settingsFrame
fovToggleButton.Size = UDim2.new(1, 0, 0, 30)
fovToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
fovToggleButton.Text = "Hide FOV"
fovToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fovToggleButton.TextScaled = true
fovToggleButton.ZIndex = 100
fovToggleButton.BorderSizePixel = 0
local fovButtonCorner = Instance.new("UICorner")
fovButtonCorner.CornerRadius = UDim.new(0, 8)
fovButtonCorner.Parent = fovToggleButton
local fovButtonStroke = Instance.new("UIStroke")
fovButtonStroke.Parent = fovToggleButton
fovButtonStroke.Color = Color3.fromRGB(255, 255, 255)
fovButtonStroke.Thickness = 1
fovButtonStroke.Transparency = 0.5

-- Create TextBox for FOV input
local fovInput = Instance.new("TextBox")
fovInput.Parent = settingsFrame
fovInput.Size = UDim2.new(1, 0, 0, 30)
fovInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
fovInput.TextColor3 = Color3.fromRGB(255, 255, 255)
fovInput.Text = tostring(fovAngle)
fovInput.TextScaled = true
fovInput.PlaceholderText = "FOV (1-50)"
fovInput.ZIndex = 100
local fovInputCorner = Instance.new("UICorner")
fovInputCorner.CornerRadius = UDim.new(0, 8)
fovInputCorner.Parent = fovInput
local fovInputStroke = Instance.new("UIStroke")
fovInputStroke.Parent = fovInput
fovInputStroke.Color = Color3.fromRGB(255, 255, 255)
fovInputStroke.Thickness = 1
fovInputStroke.Transparency = 0.5

-- Create Aim Part Button
local aimPartButton = Instance.new("TextButton")
aimPartButton.Parent = settingsFrame
aimPartButton.Size = UDim2.new(1, 0, 0, 30)
aimPartButton.BackgroundColor3 = Color3.fromRGB(150, 50, 150)
aimPartButton.Text = "Aim Part: " .. aimPartName
aimPartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimPartButton.TextScaled = true
aimPartButton.ZIndex = 100
aimPartButton.BorderSizePixel = 0
local aimPartButtonCorner = Instance.new("UICorner")
aimPartButtonCorner.CornerRadius = UDim.new(0, 8)
aimPartButtonCorner.Parent = aimPartButton
local aimPartButtonStroke = Instance.new("UIStroke")
aimPartButtonStroke.Parent = aimPartButton
aimPartButtonStroke.Color = Color3.fromRGB(255, 255, 255)
aimPartButtonStroke.Thickness = 1
aimPartButtonStroke.Transparency = 0.5

-- Create TextBox for smoothing factor
local smoothingInput = Instance.new("TextBox")
smoothingInput.Parent = settingsFrame
smoothingInput.Size = UDim2.new(1, 0, 0, 30)
smoothingInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
smoothingInput.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothingInput.Text = tostring(smoothingFactor)
smoothingInput.TextScaled = true
smoothingInput.PlaceholderText = "Smoothing (0-1)"
smoothingInput.ZIndex = 100
local smoothingCorner = Instance.new("UICorner")
smoothingCorner.CornerRadius = UDim.new(0, 8)
smoothingCorner.Parent = smoothingInput
local smoothingStroke = Instance.new("UIStroke")
smoothingStroke.Parent = smoothingInput
smoothingStroke.Color = Color3.fromRGB(255, 255, 255)
smoothingStroke.Thickness = 1
smoothingStroke.Transparency = 0.5

-- Create Toggle Box ESP Button
local boxEspToggleButton = Instance.new("TextButton")
boxEspToggleButton.Parent = settingsFrame
boxEspToggleButton.Size = UDim2.new(1, 0, 0, 30)
boxEspToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
boxEspToggleButton.Text = "Disable Box ESP"
boxEspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
boxEspToggleButton.TextScaled = true
boxEspToggleButton.ZIndex = 100
boxEspToggleButton.BorderSizePixel = 0
local boxEspButtonCorner = Instance.new("UICorner")
boxEspButtonCorner.CornerRadius = UDim.new(0, 8)
boxEspButtonCorner.Parent = boxEspToggleButton
local boxEspButtonStroke = Instance.new("UIStroke")
boxEspButtonStroke.Parent = boxEspToggleButton
boxEspButtonStroke.Color = Color3.fromRGB(255, 255, 255)
boxEspButtonStroke.Thickness = 1
boxEspButtonStroke.Transparency = 0.5

-- Create Toggle Distance ESP Button
local distanceEspToggleButton = Instance.new("TextButton")
distanceEspToggleButton.Parent = settingsFrame
distanceEspToggleButton.Size = UDim2.new(1, 0, 0, 30)
distanceEspToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
distanceEspToggleButton.Text = "Disable Distance ESP"
distanceEspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceEspToggleButton.TextScaled = true
distanceEspToggleButton.ZIndex = 100
distanceEspToggleButton.BorderSizePixel = 0
local distanceEspButtonCorner = Instance.new("UICorner")
distanceEspButtonCorner.CornerRadius = UDim.new(0, 8)
distanceEspButtonCorner.Parent = distanceEspToggleButton
local distanceEspButtonStroke = Instance.new("UIStroke")
distanceEspButtonStroke.Parent = distanceEspToggleButton
distanceEspButtonStroke.Color = Color3.fromRGB(255, 255, 255)
distanceEspButtonStroke.Thickness = 1
distanceEspButtonStroke.Transparency = 0.5

-- Create Toggle Name ESP Button
local nameEspToggleButton = Instance.new("TextButton")
nameEspToggleButton.Parent = settingsFrame
nameEspToggleButton.Size = UDim2.new(1, 0, 0, 30)
nameEspToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
nameEspToggleButton.Text = "Disable Name ESP"
nameEspToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nameEspToggleButton.TextScaled = true
nameEspToggleButton.ZIndex = 100
nameEspToggleButton.BorderSizePixel = 0
local nameEspButtonCorner = Instance.new("UICorner")
nameEspButtonCorner.CornerRadius = UDim.new(0, 8)
nameEspButtonCorner.Parent = nameEspToggleButton
local nameEspButtonStroke = Instance.new("UIStroke")
nameEspButtonStroke.Parent = nameEspToggleButton
nameEspButtonStroke.Color = Color3.fromRGB(255, 255, 255)
nameEspButtonStroke.Thickness = 1
nameEspButtonStroke.Transparency = 0.5

-- Create Unload Button
local unloadButton = Instance.new("TextButton")
unloadButton.Parent = settingsFrame
unloadButton.Size = UDim2.new(1, 0, 0, 30)
unloadButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
unloadButton.Text = "Unload Script"
unloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadButton.TextScaled = true
unloadButton.ZIndex = 100
unloadButton.BorderSizePixel = 0
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = unloadButton
local unloadButtonStroke = Instance.new("UIStroke")
unloadButtonStroke.Parent = unloadButton
unloadButtonStroke.Color = Color3.fromRGB(255, 255, 231)
unloadButtonStroke.Thickness = 1
unloadButtonStroke.Transparency = 0.5

-- Create circular Frame for FOV
local fovFrame = Instance.new("Frame")
fovFrame.Parent = screenGui
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel = 0
fovFrame.Visible = true
fovFrame.ZIndex = 100
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = fovFrame
local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = fovFrame
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Thickness = 4
uiStroke.Transparency = 0.2

-- Create TextLabel for aimlocked player (styled consistently with buttons)
local targetLabel = Instance.new("TextLabel")
targetLabel.Parent = screenGui
targetLabel.Size = UDim2.new(0.15, 0, 0, 30) -- Same height as buttons
targetLabel.Position = UDim2.new(0.5, -targetLabel.Size.X.Offset / 2, 0.02, 0)
targetLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Match button background
targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
targetLabel.Text = "Target: None"
targetLabel.TextScaled = true
targetLabel.ZIndex = 100
local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 8) -- Match button corner radius
targetCorner.Parent = targetLabel
local targetStroke = Instance.new("UIStroke")
targetStroke.Parent = targetLabel
targetStroke.Color = Color3.fromRGB(255, 255, 255)
targetStroke.Thickness = 1
targetStroke.Transparency = 0.5

-- Store event connections
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
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
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
            if p.Character then
                local character = p.Character
                local bboxCFrame, bboxSize = character:GetBoundingBox()
                local corners = {}
                for x = -1, 1, 2 do
                    for y = -1, 1, 2 do
                        for z = -1, 1, 2 do
                            local corner = bboxCFrame * Vector3.new(x * bboxSize.X / 2, y * bboxSize.Y / 2, z * bboxSize.Z / 2)
                            table.insert(corners, corner)
                        end
                    end
                end
                local visiblePoints = {}
                for _, corner in ipairs(corners) do
                    local screenPos, _ = workspace.CurrentCamera:WorldToViewportPoint(corner)
                    if screenPos.Z > 0 then
                        table.insert(visiblePoints, screenPos)
                    end
                end
                if #visiblePoints > 0 then
                    local minX, minY, maxX, maxY = visiblePoints[1].X, visiblePoints[1].Y, visiblePoints[1].X, visiblePoints[1].Y
                    for i = 2, #visiblePoints do
                        local sp = visiblePoints[i]
                        if sp.X < minX then minX = sp.X end
                        if sp.X > maxX then maxX = sp.X end
                        if sp.Y < minY then minY = sp.Y end
                        if sp.Y > maxY then maxY = sp.Y end
                    end
                    local screenMinX = math.max(minX, 0)
                    local screenMaxX = math.min(maxX, workspace.CurrentCamera.ViewportSize.X)
                    local screenMinY = math.max(minY, 0)
                    local screenMaxY = math.min(maxY, workspace.CurrentCamera.ViewportSize.Y)
                    if screenMinX < screenMaxX and screenMinY < screenMaxY then
                        box.Size = UDim2.new(0, screenMaxX - screenMinX, 0, screenMaxY - screenMinY)
                        box.Position = UDim2.new(0, screenMinX, 0, screenMinY)
                        box.Visible = boxEspEnabled
                    else
                        box.Visible = false
                    end
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end

            -- Update ESP colors for current target
            local stroke = box:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = (p == currentTarget) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
            end
            distanceLabel.TextColor3 = (p == currentTarget) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
            nameLabel.TextColor3 = (p == currentTarget) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)

            -- Update Distance
            local distance = (player.Character and player.Character.HumanoidRootPart and rootPart) and (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude or 0
            distanceLabel.Text = string.format("%.1f studs", distance)
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
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

-- Handle player leaving
game.Players.PlayerRemoving:Connect(function(p)
    if espElements[p] then
        espElements[p].box.Parent:Destroy()
        espElements[p].distance.Parent:Destroy()
        espElements[p].name.Parent:Destroy()
        espElements[p] = nil
    end
end)

local function isWithinFOV(targetPos, camCFrame)
    local vectorToTarget = (targetPos - camCFrame.Position).Unit
    local cameraForward = camCFrame.LookVector
    local angle = math.deg(math.acos(vectorToTarget:Dot(cameraForward)))
    return angle <= fovAngle / 2
end

local function getClosestPlayer()
    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(aimPartName == "Random" and randomAimPart or aimPartName) then
        return currentTarget
    end

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
        uiStroke.Color = Color3.fromRGB(255, 0, 0)
        targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    else
        targetLabel.Text = "Target: None"
        currentTarget = nil
        uiStroke.Color = Color3.fromRGB(255, 255, 255)
        targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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

local function adjustFOV()
    local value = tonumber(fovInput.Text)
    if value and value >= 1 and value <= 50 then
        fovAngle = value
    else
        fovInput.Text = tostring(fovAngle)
    end
end

local function adjustAimPart()
    local aimParts = {"Head", "HumanoidRootPart", "Random"}
    local currentIndex = table.find(aimParts, aimPartName) or 1
    aimPartName = aimParts[(currentIndex % #aimParts) + 1]
    aimPartButton.Text = "Aim Part: " .. aimPartName
end

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

local function toggleButtons()
    buttonsVisible = not buttonsVisible
    settingsFrame.Visible = buttonsVisible
    targetLabel.Visible = buttonsVisible
end

local function toggleBoxESP()
    boxEspEnabled = not boxEspEnabled
    boxEspToggleButton.Text = boxEspEnabled and "Disable Box ESP" or "Enable Box ESP"
    boxEspToggleButton.BackgroundColor3 = boxEspEnabled and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 50, 50)
    for _, elements in pairs(espElements) do
        elements.box.Parent.Enabled = boxEspEnabled
    end
end

local function toggleDistanceESP()
    distanceEspEnabled = not distanceEspEnabled
    distanceEspToggleButton.Text = distanceEspEnabled and "Disable Distance ESP" or "Enable Distance ESP"
    distanceEspToggleButton.BackgroundColor3 = distanceEspEnabled and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 50, 50)
    for _, elements in pairs(espElements) do
        elements.distance.Parent.Enabled = distanceEspEnabled
    end
end

local function toggleNameESP()
    nameEspEnabled = not nameEspEnabled
    nameEspToggleButton.Text = nameEspEnabled and "Disable Name ESP" or "Enable Name ESP"
    nameEspToggleButton.BackgroundColor3 = nameEspEnabled and Color3.fromRGB(50, 150, 150) or Color3.fromRGB(150, 50, 50)
    for _, elements in pairs(espElements) do
        elements.name.Parent.Enabled = nameEspEnabled
    end
end

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

local function toggleFOV()
    fovVisible = not fovVisible
    fovFrame.Visible = fovVisible
    fovToggleButton.Text = fovVisible and "Hide FOV" or "Show FOV"
    fovToggleButton.BackgroundColor3 = fovVisible and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
end

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

-- Connect TextBox inputs
table.insert(connections, keyInput.FocusLost:Connect(function()
    onKeyInput()
end))

table.insert(connections, smoothingInput.FocusLost:Connect(function()
    local value = tonumber(smoothingInput.Text)
    if value and value >= 0 and value <= 1 then
        smoothingFactor = value
    else
        smoothingInput.Text = tostring(smoothingFactor)
    end
end))

table.insert(connections, fovInput.FocusLost:Connect(adjustFOV))

-- Connect buttons
table.insert(connections, fovToggleButton.Activated:Connect(toggleFOV))
table.insert(connections, aimPartButton.Activated:Connect(adjustAimPart))
table.insert(connections, boxEspToggleButton.Activated:Connect(toggleBoxESP))
table.insert(connections, distanceEspToggleButton.Activated:Connect(toggleDistanceESP))
table.insert(connections, nameEspToggleButton.Activated:Connect(toggleNameESP))
table.insert(connections, unloadButton.Activated:Connect(unloadScript))

-- Connect Right-Alt key for toggling GUI
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or input.KeyCode ~= Enum.KeyCode.RightAlt then return end
    toggleButtons()
end))

-- Update aim lock, FOV circle, and ESP
table.insert(connections, RunService.RenderStepped:Connect(function()
    if Aiming then
        AimLock()
    else
        -- Reset FOV color and target label when not aiming
        uiStroke.Color = Color3.fromRGB(255, 255, 255)
        targetLabel.Text = "Target: None"
        targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentTarget = nil
    end
    if fovVisible then
        updateFOVCircle()
    end
    updateESP()
end))

-- Cleanup when ScreenGui is destroyed
table.insert(connections, screenGui.AncestryChanged:Connect(function()
    if not screenGui:IsDescendantOf(game) then
        unloadScript()
    end
end))
