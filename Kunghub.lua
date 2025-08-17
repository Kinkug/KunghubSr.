local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MOVE_SPEED = 150
local TOGGLE_KEY = Enum.KeyCode.V
local LOCK_MOUSE_KEY = Enum.KeyCode.L
local FLOAT_HEIGHT = 1
local RETURN_TIME = 0.3

local enabled = false
local mouseLocked = true
local inputList = {W=false, A=false, S=false, D=false, Q=false, E=false}
local cameraCF
local oldCameraType, oldCameraSubject, oldCameraCFrame
local oldPlatformStand
local connection

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FreecamToggleGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 230)
frame.Position = UDim2.new(0, 10, 1, -240) -- Left bottom corner
frame.BackgroundTransparency = 0.25
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 15)
frameCorner.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -10, 0, 40)
toggleButton.Position = UDim2.new(0, 5, 0, 5)
toggleButton.Text = " กล้องบิน! "
toggleButton.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local mouseLockButton = Instance.new("TextButton")
mouseLockButton.Size = UDim2.new(1, -10, 0, 40)
mouseLockButton.Position = UDim2.new(0, 5, 0, 50)
mouseLockButton.Text = " ล็อคเป้าใว้กลาง "
mouseLockButton.Parent = frame

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 12)
lockCorner.Parent = mouseLockButton

local directions = {
    {"W", "W", UDim2.new(0.5, -25, 0, 100)},
    {"S", "S", UDim2.new(0.5, -25, 0, 160)},
    {"A", "A", UDim2.new(0.1, 0, 0, 160)},
    {"D", "D", UDim2.new(0.7, 0, 0, 160)},
    {"Q", "Q", UDim2.new(0.1, 0, 0, 100)},
    {"E", "E", UDim2.new(0.7, 0, 0, 100)},
}

for _, dir in ipairs(directions) do
    local key, text, pos = unpack(dir)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.Parent = frame

    -- UICorner for button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    -- Button press effects
    btn.MouseButton1Down:Connect(function()
        inputList[key] = true
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)
    btn.MouseButton1Up:Connect(function()
        inputList[key] = false
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
end

local function getMoveVector(cf)
    local forward, right, up = cf.LookVector, cf.RightVector, cf.UpVector
    local vec = Vector3.new()
    if inputList.W then vec += forward end
    if inputList.S then vec -= forward end
    if inputList.D then vec += right end
    if inputList.A then vec -= right end
    if inputList.E then vec += up end
    if inputList.Q then vec -= up end
    return vec.Magnitude > 0 and vec.Unit or Vector3.new()
end

local function applyMouseLock()
    if not UserInputService.TouchEnabled and mouseLocked then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

local function enableFreecam()
    if enabled then return end
    enabled = true

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    oldCameraType = camera.CameraType
    oldCameraSubject = camera.CameraSubject
    oldCameraCFrame = camera.CFrame
    oldPlatformStand = humanoid.PlatformStand

    humanoid.PlatformStand = true
    root.Anchored = true
    root.CFrame = CFrame.new(root.Position.X, root.Position.Y + FLOAT_HEIGHT, root.Position.Z)

    camera.CameraType = Enum.CameraType.Scriptable
    cameraCF = CFrame.new(root.Position + Vector3.new(0, FLOAT_HEIGHT, 0))

    applyMouseLock()

    connection = RunService.RenderStepped:Connect(function(dt)
        if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
            local delta = UserInputService:GetMouseDelta()
            if delta.X ~= 0 or delta.Y ~= 0 then
                cameraCF = cameraCF * CFrame.Angles(-math.rad(delta.Y * 0.15), -math.rad(delta.X * 0.15), 0)
            end
        elseif UserInputService.TouchEnabled then
            local touches = UserInputService:GetTouches()
            for _, touch in ipairs(touches) do
                if touch.UserInputState == Enum.UserInputState.Change then
                    cameraCF = cameraCF * CFrame.Angles(-math.rad(touch.Delta.y * 0.15), -math.rad(touch.Delta.x * 0.15), 0)
                end
            end
        end

        local moveDir = getMoveVector(cameraCF)
        if moveDir.Magnitude > 0 then
            cameraCF = cameraCF + (moveDir * MOVE_SPEED * dt)
        end
        camera.CFrame = cameraCF

        root.CFrame = CFrame.new(root.Position.X, root.Position.Y, root.Position.Z) * CFrame.Angles(0, select(2, camera.CFrame:ToEulerAnglesYXZ()), 0)
    end)
end

local function disableFreecam()
    if not enabled then return end
    enabled = false

    if connection then connection:Disconnect() end
    applyMouseLock()

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if humanoid then humanoid.PlatformStand = oldPlatformStand or false end
        if root then
            root.Anchored = false
            local startCF = camera.CFrame
            local endCF = oldCameraCFrame or camera.CFrame
            local startTime = tick()

            local smoothConn
            smoothConn = RunService.RenderStepped:Connect(function()
                local alpha = math.min((tick() - startTime) / RETURN_TIME, 1)
                camera.CFrame = startCF:Lerp(endCF, alpha)
                if alpha >= 1 then
                    if smoothConn then smoothConn:Disconnect() end
                    camera.CameraType = oldCameraType or Enum.CameraType.Custom
                    if oldCameraSubject then
                        camera.CameraSubject = oldCameraSubject
                    end
                end
            end)
        end
    end
end

-- Toggle
local function toggleFreecam()
    if enabled then disableFreecam() else enableFreecam() end
end

toggleButton.MouseButton1Click:Connect(toggleFreecam)

mouseLockButton.MouseButton1Click:Connect(function()
    mouseLocked = not mouseLocked
    mouseLockButton.Text = "Mouse Lock: " .. (mouseLocked and "ON (L)" or "OFF (L)")
    applyMouseLock()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == TOGGLE_KEY then toggleFreecam() end
    if input.KeyCode == LOCK_MOUSE_KEY then
        mouseLocked = not mouseLocked
        mouseLockButton.Text = "Mouse Lock: " .. (mouseLocked and "ON (L)" or "OFF (L)")
        applyMouseLock()
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
    if enabled then disableFreecam() end
end)

RunService.Heartbeat:Connect(function()
    toggleButton.TextColor3 = enabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,255,255)
end)
