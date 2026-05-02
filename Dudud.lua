-- ==========================================
-- [[ ตัวแปรและฟังก์ชันระบบหลัก ]]
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 
local localPlayer = Players.LocalPlayer

-- ตรวจจับว่าผู้เล่นใช้มือถือหรือไม่ (มีระบบสัมผัสและไม่มีคีย์บอร์ด)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local SelectedPlayer = nil
local NoclipLoop = nil

-- [ตัวแปรของ ESP]
local ESP_Enabled = false
local SpeedEnabled = false
local SpeedValue = 16
local BrightEnabled = false
local BrightValue = 2

local DefaultBrightness = Lighting.Brightness
local DefaultClockTime = Lighting.ClockTime
local DefaultGlobalShadows = Lighting.GlobalShadows

-- ==========================================
-- [[ ฟังก์ชันระบบ ESP ใหม่ (ไร้บัค 100%) ]]
-- ==========================================
local function AddESP(player)
    if player == localPlayer or not ESP_Enabled then return end 
    
    local character = player.Character
    if not character then return end

    -- ลบอันเก่าออกก่อนเพื่อป้องกันการซ้อนทับ
    for _, v in pairs(character:GetChildren()) do
        if v.Name == "PlayerESP" or v.Name == "ESP_Label" then v:Destroy() end
    end

    -- วาดขอบ
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.Adornee = character
    highlight.FillTransparency = 1 
    highlight.OutlineColor = Color3.new(1, 1, 1) 
    highlight.OutlineTransparency = 0 
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
    highlight.Parent = character

    -- ป้ายชื่อบนหัว
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Label"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 500, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0) 
        billboard.AlwaysOnTop = true
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "InfoText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = ""
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextStrokeTransparency = 0 
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 13
        textLabel.Parent = billboard
        
        billboard.Parent = character
    end
end

local function RemoveESP(player)
    if player.Character then
        for _, v in pairs(player.Character:GetChildren()) do
            if v.Name == "PlayerESP" or v.Name == "ESP_Label" then
                v:Destroy()
            end
        end
    end
end

-- อัปเดตข้อความและสี ESP แบบเรียลไทม์
RunService.RenderStepped:Connect(function()
    if not ESP_Enabled then return end
    
    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char then
                local label = char:FindFirstChild("ESP_Label")
                local highlight = char:FindFirstChild("PlayerESP")
                local humanoid = char:FindFirstChild("Humanoid")
                local targetHrp = char:FindFirstChild("HumanoidRootPart")
                
                if label and label:FindFirstChild("InfoText") and highlight and humanoid and targetHrp and myHrp then
                    local distance = math.floor((myHrp.Position - targetHrp.Position).Magnitude)
                    local hp = math.floor(humanoid.Health)
                    local maxHp = math.floor(humanoid.MaxHealth)
                    
                    local tool = char:FindFirstChildOfClass("Tool")
                    local heldItem = tool and tool.Name or "None"
                    
                    local nameDisplay = ""
                    if player.DisplayName == player.Name then
                        nameDisplay = player.Name
                    else
                        nameDisplay = player.DisplayName .. " (@" .. player.Name .. ")"
                    end
                    
                    -- ตั้งค่าเป็นสีขาวล้วนสำหรับทุกคน
                    local targetColor = Color3.fromRGB(255, 255, 255)
                    
                    highlight.OutlineColor = targetColor
                    label.InfoText.TextColor3 = targetColor
                    label.InfoText.Text = string.format("%s | HP: %d/%d | %d Studs | Item: %s", nameDisplay, hp, maxHp, distance, heldItem)
                end
            end
        end
    end
end)

-- จัดการการเกิดใหม่ (สร้าง Event ครั้งเดียวเพื่อกันบัค)
local function SetupESPConnection(player)
    player.CharacterAdded:Connect(function()
        if ESP_Enabled then
            task.wait(0.5) -- รอให้ตัวละครโหลดเสร็จก่อนสร้าง ESP
            AddESP(player)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    SetupESPConnection(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    SetupESPConnection(player)
end

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)


-- ==========================================
-- [[ ฟังก์ชันตกแต่งขั้นสูง (Premium Aesthetics) ]]
-- ==========================================
local function ApplyGradient(parent, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation or 45
    gradient.Parent = parent
    return gradient
end

-- โทนสีหลัก (Neon Cyberpunk)
local Theme = {
    BG = Color3.fromRGB(12, 12, 17),
    PanelBG = Color3.fromRGB(18, 18, 24),
    ElementBG = Color3.fromRGB(26, 26, 34),
    TextWhite = Color3.fromRGB(240, 240, 240),
    TextGray = Color3.fromRGB(170, 170, 180),
    Grad1 = Color3.fromRGB(0, 255, 200), -- Cyan
    Grad2 = Color3.fromRGB(150, 50, 255), -- Purple
    Stroke = Color3.fromRGB(40, 40, 50)
}

local function GetPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return list
end

local function LoadUltraFlyGUI()
    if game.CoreGui:FindFirstChild("UltraFlyCustomDrag") then
        game.CoreGui.UltraFlyCustomDrag.Enabled = true
        return
    end
    local lp = Players.LocalPlayer
    local flying = false
    local flySpeed = 100
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UltraFlyCustomDrag"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    screenGui.DisplayOrder = 2147483647

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = isMobile and UDim2.new(0, 70, 0, 30) or UDim2.new(0, 80, 0, 35)
    mainFrame.Position = isMobile and UDim2.new(1, -130, 0.4, 0) or UDim2.new(1, -150, 0.4, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local function applyStyle(obj, radius, strokeColor)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = obj
        if strokeColor then
            local stroke = Instance.new("UIStroke")
            stroke.Color = strokeColor
            stroke.Thickness = 1.5
            stroke.Transparency = 0.2
            stroke.Parent = obj
        end
    end

    local flyBtn = Instance.new("TextButton")
    flyBtn.Size = UDim2.new(1, 0, 1, 0)
    flyBtn.BackgroundColor3 = Theme.PanelBG
    flyBtn.BorderSizePixel = 0
    flyBtn.Text = "FLY (F)" 
    flyBtn.TextColor3 = Theme.Grad1
    flyBtn.Font = Enum.Font.GothamBold
    flyBtn.TextSize = 14
    flyBtn.Parent = mainFrame
    applyStyle(flyBtn, 8, Theme.Grad1)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 18, 0, 18)
    toggleBtn.Position = UDim2.new(1, 5, 0, 0)
    toggleBtn.BackgroundColor3 = Theme.ElementBG
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "+"
    toggleBtn.TextColor3 = Theme.TextWhite
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = mainFrame
    applyStyle(toggleBtn, 5, Theme.Stroke)

    local speedInput = Instance.new("TextBox")
    speedInput.Size = UDim2.new(1, 0, 0, 25)
    speedInput.Position = UDim2.new(0, 0, 1, 8)
    speedInput.BackgroundColor3 = Theme.BG
    speedInput.BorderSizePixel = 0
    speedInput.Text = "100"
    speedInput.PlaceholderText = "SPEED"
    speedInput.TextColor3 = Theme.TextWhite
    speedInput.Font = Enum.Font.GothamSemibold
    speedInput.Visible = false
    speedInput.ClearTextOnFocus = false
    speedInput.Parent = mainFrame
    applyStyle(speedInput, 6, Theme.Stroke)

    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local frameSize = mainFrame.AbsoluteSize
        local newX = math.clamp(startPos.X + delta.X, 0, viewportSize.X - frameSize.X)
        local newY = math.clamp(startPos.Y + delta.Y, 0, viewportSize.Y - frameSize.Y)
        mainFrame.Position = UDim2.new(0, newX, 0, newY)
    end
    flyBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.AbsolutePosition
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    flyBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)

    local function startFly()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        local camera = workspace.CurrentCamera
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 15000
        bg.Parent = hrp
        hum.PlatformStand = true
        task.spawn(function()
            while flying and char.Parent and hrp.Parent do
                local md = hum.MoveDirection
                bg.CFrame = camera.CFrame
                if md.Magnitude > 0 then
                    local direction = (camera.CFrame.LookVector * (camera.CFrame:VectorToObjectSpace(md).Z * -1)) + (camera.CFrame.RightVector * camera.CFrame:VectorToObjectSpace(md).X)
                    bv.Velocity = direction.Unit * flySpeed
                else
                    bv.Velocity = Vector3.new(0, 0, 0)
                end
                RunService.RenderStepped:Wait()
            end
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
            if hum then hum.PlatformStand = false end
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F then
            flying = not flying
            if flying then
                flyBtn.TextColor3 = Theme.Grad1
                flyBtn.UIStroke.Color = Theme.Grad1
                startFly()
            else
                flyBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
                flyBtn.UIStroke.Color = Color3.fromRGB(255, 80, 80)
            end
        end
    end)
    flyBtn.MouseButton1Click:Connect(function()
        flying = not flying
        if flying then
            flyBtn.TextColor3 = Theme.Grad1
            flyBtn.UIStroke.Color = Theme.Grad1
            startFly()
        else
            flyBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            flyBtn.UIStroke.Color = Color3.fromRGB(255, 80, 80)
        end
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        speedInput.Visible = not speedInput.Visible
        toggleBtn.Text = speedInput.Visible and "-" or "+"
        toggleBtn.TextColor3 = speedInput.Visible and Color3.fromRGB(255, 100, 100) or Theme.TextWhite
    end)
    speedInput.FocusLost:Connect(function()
        local val = tonumber(speedInput.Text)
        if val then flySpeed = val else speedInput.Text = tostring(flySpeed) end
    end)
end

-- ==========================================
-- ฟังก์ชันช่วยสำหรับกันหลุดจอ (Clamping)
-- ==========================================
local function MakeDraggableAndClamped(Frame)
    local dragging, dragInput, dragStart, startPos
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.AbsolutePosition
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local frameSize = Frame.AbsoluteSize
            local newX = math.clamp(startPos.X + delta.X, 0, viewportSize.X - frameSize.X)
            local newY = math.clamp(startPos.Y + delta.Y, 0, viewportSize.Y - frameSize.Y)
            Frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end


-- ==========================================
-- [[ 1. ระบบตามติดชีวิตวาน (Follow System) ]]
-- ==========================================
local FollowScreenGui = Instance.new("ScreenGui")
FollowScreenGui.Name = "FollowSystemGui"
FollowScreenGui.ResetOnSpawn = false
FollowScreenGui.Enabled = false
FollowScreenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = isMobile and UDim2.new(0, 260, 0, 180) or UDim2.new(0, 320, 0, 200)
frame.Position = isMobile and UDim2.new(0.5, -130, 0.5, -90) or UDim2.new(0.5, -160, 0.5, -100)
frame.BackgroundColor3 = Theme.BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = FollowScreenGui
MakeDraggableAndClamped(frame)

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local fStroke = Instance.new("UIStroke", frame)
fStroke.Thickness = 1.5
ApplyGradient(fStroke, Theme.Grad1, Theme.Grad2, 45)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 30, 0, 30)
toggleBtn.Position = UDim2.new(1, -35, 0, 5)
toggleBtn.Text = "🖕"
toggleBtn.BackgroundColor3 = Theme.ElementBG
toggleBtn.TextColor3 = Theme.TextWhite
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 20
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 5)
padding.PaddingRight = UDim.new(0, 5)
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 5)
padding.Parent = contentFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Parent = contentFrame

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(0.95, 0, 0, 35)
dropdownBtn.Text = "  เลือกผัวลิต   ▼"
dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
dropdownBtn.BackgroundColor3 = Theme.ElementBG
dropdownBtn.TextColor3 = Theme.TextWhite
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextSize = 14
dropdownBtn.Parent = contentFrame
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 6)

local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0.95, 0, 0, 120)
playerListFrame.BackgroundColor3 = Theme.PanelBG
playerListFrame.Visible = false
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.ScrollBarThickness = 4
playerListFrame.ScrollBarImageColor3 = Theme.Grad1
playerListFrame.Parent = contentFrame
Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 6)

local posMode = "behind"

local modeDropdown = Instance.new("TextButton")
modeDropdown.Size = UDim2.new(0.95, 0, 0, 35)
modeDropdown.Text = "  ตอนนี้ ข้างหลังเอาวาน👉👌   ▼"
modeDropdown.TextXAlignment = Enum.TextXAlignment.Left
modeDropdown.BackgroundColor3 = Theme.ElementBG
modeDropdown.TextColor3 = Theme.TextWhite
modeDropdown.Font = Enum.Font.GothamBold
modeDropdown.TextSize = 14
modeDropdown.Parent = contentFrame
Instance.new("UICorner", modeDropdown).CornerRadius = UDim.new(0, 6)

local modeListFrame = Instance.new("Frame")
modeListFrame.Size = UDim2.new(0.95, 0, 0, 100)
modeListFrame.BackgroundColor3 = Theme.PanelBG
modeListFrame.Visible = false
modeListFrame.Parent = contentFrame
Instance.new("UICorner", modeListFrame).CornerRadius = UDim.new(0, 6)

local listLayout2 = Instance.new("UIListLayout")
listLayout2.Parent = modeListFrame
listLayout2.SortOrder = Enum.SortOrder.LayoutOrder

local function createModeButton(name, label)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Theme.PanelBG
    btn.TextColor3 = Theme.TextWhite
    btn.Text = "  " .. label
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = modeListFrame
    btn.MouseButton1Click:Connect(function()
        posMode = name
        modeDropdown.Text = "  เลือกส่วนของวานลิต: " .. label .. "   ▼"
        modeListFrame.Visible = false
    end)
end

createModeButton("behind", "ข้างหลังเอาวาน👉👌")
createModeButton("top", "บนหัว👉👌")
createModeButton("front", "ข้างหน้า👉👌")

modeDropdown.MouseButton1Click:Connect(function()
    modeListFrame.Visible = not modeListFrame.Visible
end)

local uiList = Instance.new("UIListLayout")
uiList.Parent = playerListFrame
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local quickPanelBtn = Instance.new("TextButton")
quickPanelBtn.Size = UDim2.new(0.95, 0, 0, 35)
quickPanelBtn.Text = "เปิดทางลัดของวานลิต"
quickPanelBtn.BackgroundColor3 = Theme.ElementBG
quickPanelBtn.TextColor3 = Theme.TextWhite
quickPanelBtn.Font = Enum.Font.GothamBlack
quickPanelBtn.TextSize = 14
quickPanelBtn.Parent = contentFrame
Instance.new("UICorner", quickPanelBtn).CornerRadius = UDim.new(0, 6)
local qpStroke = Instance.new("UIStroke", quickPanelBtn)
qpStroke.Thickness = 1.5
ApplyGradient(qpStroke, Theme.Grad1, Theme.Grad2)

local following = false
local followTarget = nil
local heartbeatConn
local selectedPlayer = nil
local isCollapsed = false

local function startFollow(player)
    followTarget = player
    following = true
    if heartbeatConn then heartbeatConn:Disconnect() end
    heartbeatConn = RunService.Heartbeat:Connect(function()
        if following and followTarget and followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = followTarget.Character.HumanoidRootPart
            local myChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                if posMode == "behind" then
                    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1)
                elseif posMode == "top" then
                    myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
                elseif posMode == "front" then
                    myHRP.CFrame = (targetHRP.CFrame * CFrame.new(0, 3, -1)) * CFrame.Angles(0, math.rad(180), 0)
                    local humanoid = myChar:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = "rbxassetid://148840371"
                        local track = humanoid:LoadAnimation(anim)
                        track:Play()
                    end
                end
            end
        end
    end)
end

local function stopFollow()
    following = false
    followTarget = nil
    if heartbeatConn then heartbeatConn:Disconnect() end
    local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
    end
end

local function updatePlayerList()
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Theme.PanelBG
            btn.TextColor3 = Theme.TextGray
            btn.TextWrapped = true
            btn.Text = "  " .. player.DisplayName .. " (@" .. player.Name .. ")"
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Gotham
            btn.Parent = playerListFrame
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                dropdownBtn.Text = "  เลือกไอควายนี้: " .. player.DisplayName .. "   ▼"
                playerListFrame.Visible = false
            end)
        end
    end
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 32)
end

dropdownBtn.MouseButton1Click:Connect(function()
    playerListFrame.Visible = not playerListFrame.Visible
    if playerListFrame.Visible then updatePlayerList() end
end)

toggleBtn.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    if isCollapsed then
        contentFrame.Visible = false
        frame.Size = isMobile and UDim2.new(0, 260, 0, 40) or UDim2.new(0, 320, 0, 40)
        toggleBtn.Text = "👉"
    else
        contentFrame.Visible = true
        frame.Size = isMobile and UDim2.new(0, 260, 0, 180) or UDim2.new(0, 320, 0, 200)
        toggleBtn.Text = "👌"
    end
end)

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

local quickFrame = Instance.new("Frame")
quickFrame.Size = UDim2.new(0, 110, 0, 40) 
quickFrame.Position = UDim2.new(1, -120, 0.5, -30)
quickFrame.BackgroundColor3 = Theme.BG
quickFrame.Visible = false
quickFrame.Active = true
quickFrame.Parent = FollowScreenGui
MakeDraggableAndClamped(quickFrame)

Instance.new("UICorner", quickFrame).CornerRadius = UDim.new(0, 8)
local qfStroke = Instance.new("UIStroke", quickFrame)
qfStroke.Thickness = 1.5
ApplyGradient(qfStroke, Theme.Grad2, Theme.Grad1, 90)

local qFollow = Instance.new("TextButton")
qFollow.Size = UDim2.new(1, -10, 0, 25)
qFollow.Position = UDim2.new(0, 5, 0, 7)
qFollow.Text = "ติดวานมัน🖕"
qFollow.BackgroundColor3 = Theme.ElementBG
qFollow.TextColor3 = Theme.TextWhite
qFollow.Font = Enum.Font.GothamBlack
qFollow.TextSize = 12
qFollow.Parent = quickFrame
Instance.new("UICorner", qFollow).CornerRadius = UDim.new(0, 6)
local qFollowStroke = Instance.new("UIStroke", qFollow)
qFollowStroke.Thickness = 1.5
ApplyGradient(qFollowStroke, Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 150, 50))

quickPanelBtn.MouseButton1Click:Connect(function() quickFrame.Visible = not quickFrame.Visible end)

qFollow.MouseButton1Click:Connect(function() 
    if following then
        stopFollow()
        qFollow.Text = "ติดวานมัน🖕"
        qFollow.TextColor3 = Theme.TextWhite
    else
        if selectedPlayer then 
            startFollow(selectedPlayer)
            qFollow.Text = "ยกเลิกติดวาน🖕"
            qFollow.TextColor3 = Color3.fromRGB(255, 50, 50) 
        end 
    end 
end)

-- ==========================================
-- [[ 2. ระบบบันทึกพิกัด (TP Manager) ]]
-- ==========================================
local TeleportScreenGui = Instance.new("ScreenGui")
TeleportScreenGui.Name = "TeleportSystem"
TeleportScreenGui.ResetOnSpawn = false
TeleportScreenGui.Enabled = false 
TeleportScreenGui.Parent = CoreGui

local TPMainFrame = Instance.new("Frame")
TPMainFrame.Name = "MainFrame"
TPMainFrame.Parent = TeleportScreenGui
TPMainFrame.BackgroundColor3 = Theme.BG
TPMainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
TPMainFrame.Size = isMobile and UDim2.new(0, 160, 0, 130) or UDim2.new(0, 200, 0, 150)
TPMainFrame.Active = true
TPMainFrame.ClipsDescendants = true 
MakeDraggableAndClamped(TPMainFrame)
Instance.new("UICorner", TPMainFrame).CornerRadius = UDim.new(0, 10)
local tpMainStroke = Instance.new("UIStroke", TPMainFrame)
tpMainStroke.Thickness = 1.5
ApplyGradient(tpMainStroke, Theme.Grad1, Theme.Grad2)

local TPTitleLabel = Instance.new("TextLabel")
TPTitleLabel.Name = "Title"
TPTitleLabel.Parent = TPMainFrame
TPTitleLabel.Size = UDim2.new(1, 0, 0, 35)
TPTitleLabel.Text = "TP MANAGER"
TPTitleLabel.Font = Enum.Font.GothamBlack
TPTitleLabel.TextColor3 = Theme.TextWhite
TPTitleLabel.BackgroundTransparency = 1
Instance.new("UICorner", TPTitleLabel).CornerRadius = UDim.new(0, 10)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = TPMainFrame
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -30, 0, 5)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBlack
MinimizeBtn.TextSize = 20
MinimizeBtn.TextColor3 = Theme.TextWhite
MinimizeBtn.BackgroundColor3 = Theme.ElementBG
MinimizeBtn.ZIndex = 2
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 5)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Name = "SaveBtn"
SaveBtn.Parent = TPMainFrame
SaveBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
SaveBtn.Size = UDim2.new(0.8, 0, 0, 35)
SaveBtn.Text = "SAVE POSITION"
SaveBtn.Font = Enum.Font.GothamBlack
SaveBtn.TextColor3 = Theme.TextWhite
SaveBtn.BackgroundColor3 = Theme.ElementBG
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)
local svStroke = Instance.new("UIStroke", SaveBtn)
svStroke.Thickness = 1.5
ApplyGradient(svStroke, Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 150, 50))

local ListBtn = Instance.new("TextButton")
ListBtn.Name = "ListBtn"
ListBtn.Parent = TPMainFrame
ListBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
ListBtn.Size = UDim2.new(0.8, 0, 0, 35)
ListBtn.Text = "OPEN LIST"
ListBtn.Font = Enum.Font.GothamBlack
ListBtn.TextColor3 = Theme.TextWhite
ListBtn.BackgroundColor3 = Theme.ElementBG
Instance.new("UICorner", ListBtn).CornerRadius = UDim.new(0, 6)
local lbStroke = Instance.new("UIStroke", ListBtn)
lbStroke.Thickness = 1.5
ApplyGradient(lbStroke, Theme.Grad1, Theme.Grad2)

local ListFrame = Instance.new("Frame")
ListFrame.Name = "ListFrame"
ListFrame.Parent = TeleportScreenGui
ListFrame.BackgroundColor3 = Theme.BG
ListFrame.Position = UDim2.new(0.3, 0, 0.1, 0)
ListFrame.Size = isMobile and UDim2.new(0, 240, 0, 300) or UDim2.new(0, 300, 0, 400)
ListFrame.Visible = false
ListFrame.Active = true
MakeDraggableAndClamped(ListFrame)
Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 10)
local lfStroke = Instance.new("UIStroke", ListFrame)
lfStroke.Thickness = 1.5
ApplyGradient(lfStroke, Theme.Grad2, Theme.Grad1)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Parent = ListFrame
ScrollFrame.Size = UDim2.new(1, -15, 1, -50)
ScrollFrame.Position = UDim2.new(0, 7, 0, 40)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Theme.Grad1

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.Padding = UDim.new(0, 8)

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TPMainFrame:TweenSize(isMobile and UDim2.new(0, 160, 0, 35) or UDim2.new(0, 200, 0, 35), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "+"
        SaveBtn.Visible = false
        ListBtn.Visible = false
    else
        TPMainFrame:TweenSize(isMobile and UDim2.new(0, 160, 0, 130) or UDim2.new(0, 200, 0, 150), "Out", "Quad", 0.3, true)
        MinimizeBtn.Text = "-"
        SaveBtn.Visible = true
        ListBtn.Visible = true
    end
end)

local savedLocations = {}
local MAX_LOCS = 20000

local function createEntry(pos, index)
    local EntryFrame = Instance.new("Frame")
    EntryFrame.Size = UDim2.new(1, -10, 0, 50)
    EntryFrame.BackgroundColor3 = Theme.ElementBG
    EntryFrame.Parent = ScrollFrame
    Instance.new("UICorner", EntryFrame).CornerRadius = UDim.new(0, 6)

    local PosLabel = Instance.new("TextLabel")
    PosLabel.Size = UDim2.new(0.6, 0, 1, 0)
    PosLabel.Position = UDim2.new(0.02, 0, 0, 0)
    PosLabel.Text = string.format("ID: %d\n%.1f, %.1f, %.1f", index, pos.X, pos.Y, pos.Z)
    PosLabel.TextColor3 = Theme.TextGray
    PosLabel.Font = Enum.Font.Code
    PosLabel.TextXAlignment = Enum.TextXAlignment.Left
    PosLabel.BackgroundTransparency = 1
    PosLabel.Parent = EntryFrame

    local GoBtn = Instance.new("TextButton")
    GoBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
    GoBtn.Position = UDim2.new(0.65, 0, 0.15, 0)
    GoBtn.Text = "TP"
    GoBtn.Font = Enum.Font.GothamBlack
    GoBtn.TextColor3 = Theme.TextWhite
    GoBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    GoBtn.Parent = EntryFrame
    Instance.new("UICorner", GoBtn).CornerRadius = UDim.new(0, 4)

    local DelBtn = Instance.new("TextButton")
    DelBtn.Size = UDim2.new(0.15, 0, 0.7, 0)
    DelBtn.Position = UDim2.new(0.82, 0, 0.15, 0)
    DelBtn.Text = "X"
    DelBtn.Font = Enum.Font.GothamBlack
    DelBtn.TextColor3 = Theme.TextWhite
    DelBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 50)
    DelBtn.Parent = EntryFrame
    Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 4)

    GoBtn.MouseButton1Click:Connect(function() game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos) end)
    DelBtn.MouseButton1Click:Connect(function() table.remove(savedLocations, index) refreshList() end)
end

function refreshList()
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for i, pos in ipairs(savedLocations) do createEntry(pos, i) end
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #savedLocations * 58)
end

SaveBtn.MouseButton1Click:Connect(function()
    if #savedLocations < MAX_LOCS then
        local currentPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        table.insert(savedLocations, currentPos)
        refreshList()
    end
end)

ListBtn.MouseButton1Click:Connect(function() ListFrame.Visible = not ListFrame.Visible end)


-- ==========================================
-- [[ Custom UI Library (Premium Upgrade) ]]
-- ==========================================
local CustomUI = {}
CustomUI.__index = CustomUI

if CoreGui:FindFirstChild("BOSS69_CustomUI") then
    CoreGui:FindFirstChild("BOSS69_CustomUI"):Destroy()
end
local MasterScreenGui = Instance.new("ScreenGui")
MasterScreenGui.Name = "BOSS69_CustomUI"
MasterScreenGui.ResetOnSpawn = false
MasterScreenGui.DisplayOrder = 2147483647
MasterScreenGui.Parent = CoreGui

local function AddPressAnimation(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.PanelBG}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBG}):Play()
        TweenService:Create(btn.UIScale or Instance.new("UIScale", btn), TweenInfo.new(0.1), {Scale = 1}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        local scale = btn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", btn)
        TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 0.95}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        local scale = btn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", btn)
        TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1}):Play()
    end)
end

function CustomUI:Window(options)
    local title = options.Title or "UI"
    local size = options.Size or (isMobile and UDim2.new(0, 380, 0, 280) or UDim2.new(0, 560, 0, 440))
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = size
    MainFrame.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    MainFrame.BackgroundColor3 = Theme.BG
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true 
    MainFrame.Parent = MasterScreenGui
    
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 2
    MainStroke.Transparency = 0.1
    MainStroke.Parent = MainFrame
    ApplyGradient(MainStroke, Theme.Grad1, Theme.Grad2)

    MakeDraggableAndClamped(MainFrame)

    local FloatingBtn = Instance.new("TextButton")
    FloatingBtn.Size = isMobile and UDim2.new(0, 45, 0, 45) or UDim2.new(0, 55, 0, 55)
    FloatingBtn.Position = isMobile and UDim2.new(1, -60, 0, 15) or UDim2.new(1, -75, 0, 20)
    FloatingBtn.BackgroundColor3 = Theme.BG
    FloatingBtn.Text = "B" 
    FloatingBtn.TextColor3 = Theme.TextWhite
    FloatingBtn.Font = Enum.Font.GothamBlack
    FloatingBtn.TextSize = isMobile and 22 or 28
    FloatingBtn.Parent = MasterScreenGui

    Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
    local FloatStroke = Instance.new("UIStroke")
    FloatStroke.Thickness = 3
    FloatStroke.Parent = FloatingBtn
    ApplyGradient(FloatStroke, Theme.Grad1, Theme.Grad2)
    ApplyGradient(FloatingBtn, Theme.Grad2, Theme.Grad1) 

    MakeDraggableAndClamped(FloatingBtn)

    local isPanelOpen = true
    local function TogglePanel()
        isPanelOpen = not isPanelOpen
        if isPanelOpen then
            MainFrame.Visible = true
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = size}):Play()
        else
            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function() if not isPanelOpen then MainFrame.Visible = false end end)
        end
    end
    FloatingBtn.MouseButton1Click:Connect(TogglePanel)

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame
    
    local TopBarLine = Instance.new("Frame")
    TopBarLine.Size = UDim2.new(1, 0, 0, 2)
    TopBarLine.Position = UDim2.new(0, 0, 1, -2)
    TopBarLine.BorderSizePixel = 0
    TopBarLine.Parent = TopBar
    ApplyGradient(TopBarLine, Theme.Grad1, Theme.Grad2)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -50, 1, 0)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Theme.TextWhite
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -40, 0, 7)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Theme.TextGray
    MinimizeBtn.Font = Enum.Font.GothamBlack
    MinimizeBtn.TextSize = 26
    MinimizeBtn.Parent = TopBar

    MinimizeBtn.MouseButton1Click:Connect(function() if isPanelOpen then TogglePanel() end end)
    MinimizeBtn.MouseEnter:Connect(function() TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Grad1}):Play() end)
    MinimizeBtn.MouseLeave:Connect(function() TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextGray}):Play() end)

    if options.Config and options.Config.Keybind then
        UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == options.Config.Keybind then
                MasterScreenGui.Enabled = not MasterScreenGui.Enabled
            end
        end)
    end

    local tabWidth = isMobile and 100 or 140
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, tabWidth, 1, -45)
    TabContainer.Position = UDim2.new(0, 0, 0, 45)
    TabContainer.BackgroundColor3 = Theme.PanelBG
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 8)
    TabListLayout.Parent = TabContainer

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 15)
    TabPadding.PaddingLeft = UDim.new(0, 10)
    TabPadding.PaddingRight = UDim.new(0, 10)
    TabPadding.Parent = TabContainer

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -tabWidth, 1, -45)
    ContentContainer.Position = UDim2.new(0, tabWidth, 0, 45)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local windowObj = {
        MainFrame = MainFrame,
        TabContainer = TabContainer,
        ContentContainer = ContentContainer,
        Tabs = {},
        FirstTab = true
    }
    
    function windowObj:Tab(tabOptions)
        local tabTitle = tabOptions.Title or "Tab"
        
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = self.FirstTab and Color3.fromRGB(255,255,255) or Theme.ElementBG
        TabBtn.Text = tabTitle
        TabBtn.TextColor3 = self.FirstTab and Theme.BG or Theme.TextGray
        TabBtn.Font = Enum.Font.GothamBlack
        TabBtn.TextSize = 13
        TabBtn.Parent = self.TabContainer
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        if self.FirstTab then
            ApplyGradient(TabBtn, Theme.Grad1, Theme.Grad2)
        end

        local ScrollContent = Instance.new("ScrollingFrame")
        ScrollContent.Size = UDim2.new(1, 0, 1, 0)
        ScrollContent.BackgroundTransparency = 1
        ScrollContent.ScrollBarThickness = 2
        ScrollContent.ScrollBarImageColor3 = Theme.Grad1
        ScrollContent.Visible = self.FirstTab
        ScrollContent.Parent = self.ContentContainer
        
        local ScrollLayout = Instance.new("UIListLayout")
        ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ScrollLayout.Padding = UDim.new(0, 12)
        ScrollLayout.Parent = ScrollContent
        
        local ScrollPadding = Instance.new("UIPadding")
        ScrollPadding.PaddingTop = UDim.new(0, 15)
        ScrollPadding.PaddingLeft = UDim.new(0, 15)
        ScrollPadding.PaddingRight = UDim.new(0, 15)
        ScrollPadding.PaddingBottom = UDim.new(0, 15)
        ScrollPadding.Parent = ScrollContent

        table.insert(self.Tabs, {Btn = TabBtn, Content = ScrollContent})

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(self.Tabs) do
                TweenService:Create(t.Btn, TweenInfo.new(0.3), {TextColor3 = Theme.TextGray}):Play()
                t.Btn.BackgroundColor3 = Theme.ElementBG
                if t.Btn:FindFirstChildOfClass("UIGradient") then t.Btn:FindFirstChildOfClass("UIGradient"):Destroy() end
                t.Content.Visible = false
            end
            ApplyGradient(TabBtn, Theme.Grad1, Theme.Grad2)
            TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Theme.BG}):Play()
            ScrollContent.Visible = true
        end)

        ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ScrollContent.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 30)
        end)

        self.FirstTab = false
        local tabElements = {}

        function tabElements:Section(secOptions)
            local secLabel = Instance.new("TextLabel")
            secLabel.Size = UDim2.new(1, 0, 0, 26)
            secLabel.BackgroundTransparency = 1
            secLabel.Text = secOptions.Title or "Section"
            secLabel.TextColor3 = Theme.Grad1
            secLabel.Font = Enum.Font.GothamBlack
            secLabel.TextSize = 15
            secLabel.TextXAlignment = Enum.TextXAlignment.Left
            secLabel.Parent = ScrollContent
        end

        function tabElements:Toggle(togOptions)
            local state = togOptions.Value or false
            local cb = togOptions.Callback or function() end

            local TogFrame = Instance.new("Frame")
            TogFrame.Size = UDim2.new(1, 0, 0, 45)
            TogFrame.BackgroundColor3 = Theme.ElementBG
            TogFrame.Parent = ScrollContent
            Instance.new("UICorner", TogFrame).CornerRadius = UDim.new(0, 8)
            local TogStroke = Instance.new("UIStroke", TogFrame)
            TogStroke.Color = Theme.Stroke
            TogStroke.Thickness = 1.5

            local TogLabel = Instance.new("TextLabel")
            TogLabel.Size = UDim2.new(1, -70, 1, 0)
            TogLabel.Position = UDim2.new(0, 15, 0, 0)
            TogLabel.BackgroundTransparency = 1
            TogLabel.Text = togOptions.Title or "Toggle"
            TogLabel.TextColor3 = Theme.TextWhite
            TogLabel.Font = Enum.Font.GothamBold
            TogLabel.TextSize = 13
            TogLabel.TextXAlignment = Enum.TextXAlignment.Left
            TogLabel.Parent = TogFrame

            local SwitchBg = Instance.new("Frame")
            SwitchBg.Size = UDim2.new(0, 48, 0, 24)
            SwitchBg.Position = UDim2.new(1, -60, 0.5, -12)
            SwitchBg.BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Theme.PanelBG
            SwitchBg.Parent = TogFrame
            Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
            local swGrad = nil
            if state then swGrad = ApplyGradient(SwitchBg, Theme.Grad1, Theme.Grad2) end

            local SwitchKnob = Instance.new("Frame")
            SwitchKnob.Size = UDim2.new(0, 20, 0, 20)
            SwitchKnob.Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SwitchKnob.Parent = SwitchBg
            Instance.new("UICorner", SwitchKnob).CornerRadius = UDim.new(1, 0)

            local clickOverlay = Instance.new("TextButton")
            clickOverlay.Size = UDim2.new(1, 0, 1, 0)
            clickOverlay.BackgroundTransparency = 1
            clickOverlay.Text = ""
            clickOverlay.Parent = TogFrame

            local function fire()
                state = not state
                cb(state)
                local goalKnobPos = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                local goalStroke = state and Theme.Grad1 or Theme.Stroke
                
                if state then
                    SwitchBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    if not SwitchBg:FindFirstChildOfClass("UIGradient") then ApplyGradient(SwitchBg, Theme.Grad1, Theme.Grad2) end
                else
                    SwitchBg.BackgroundColor3 = Theme.PanelBG
                    if SwitchBg:FindFirstChildOfClass("UIGradient") then SwitchBg:FindFirstChildOfClass("UIGradient"):Destroy() end
                end
                
                TweenService:Create(SwitchKnob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = goalKnobPos}):Play()
                TweenService:Create(TogStroke, TweenInfo.new(0.3), {Color = goalStroke}):Play()
            end
            
            clickOverlay.MouseButton1Click:Connect(fire)
            return { Set = function(newState) if state ~= newState then fire() end end }
        end

        function tabElements:Button(btnOptions)
            local cb = btnOptions.Callback or function() end

            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(1, 0, 0, 40)
            BtnFrame.BackgroundColor3 = Theme.ElementBG
            BtnFrame.Text = btnOptions.Title or "Button"
            BtnFrame.TextColor3 = Theme.TextWhite
            BtnFrame.Font = Enum.Font.GothamBlack
            BtnFrame.TextSize = 13
            BtnFrame.Parent = ScrollContent
            Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 8)
            
            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Theme.Stroke
            BtnStroke.Thickness = 1.5
            BtnStroke.Parent = BtnFrame

            AddPressAnimation(BtnFrame)
            BtnFrame.MouseButton1Click:Connect(cb)
        end

        function tabElements:Slider(sldOptions)
            local min = sldOptions.Min or 0
            local max = sldOptions.Max or 100
            local val = sldOptions.Value or min
            local cb = sldOptions.Callback or function() end

            local SldFrame = Instance.new("Frame")
            SldFrame.Size = UDim2.new(1, 0, 0, 55)
            SldFrame.BackgroundColor3 = Theme.ElementBG
            SldFrame.Parent = ScrollContent
            Instance.new("UICorner", SldFrame).CornerRadius = UDim.new(0, 8)
            Instance.new("UIStroke", SldFrame).Color = Theme.Stroke

            local SldLabel = Instance.new("TextLabel")
            SldLabel.Size = UDim2.new(1, -30, 0, 20)
            SldLabel.Position = UDim2.new(0, 15, 0, 8)
            SldLabel.BackgroundTransparency = 1
            SldLabel.Text = sldOptions.Title .. " : " .. tostring(val)
            SldLabel.TextColor3 = Theme.TextWhite
            SldLabel.Font = Enum.Font.GothamBold
            SldLabel.TextSize = 13
            SldLabel.TextXAlignment = Enum.TextXAlignment.Left
            SldLabel.Parent = SldFrame

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -30, 0, 6)
            Track.Position = UDim2.new(0, 15, 0, 38)
            Track.BackgroundColor3 = Theme.PanelBG
            Track.Parent = SldFrame
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame")
            local percent = (val - min) / (max - min)
            Fill.Size = UDim2.new(percent, 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(255,255,255)
            Fill.Parent = Track
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
            ApplyGradient(Fill, Theme.Grad1, Theme.Grad2, 0)

            local sldBtn = Instance.new("TextButton")
            sldBtn.Size = UDim2.new(1, 0, 1, 20)
            sldBtn.Position = UDim2.new(0, 0, 0, -10)
            sldBtn.BackgroundTransparency = 1
            sldBtn.Text = ""
            sldBtn.Parent = Track

            local sldDrag = false
            sldBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sldDrag = true end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sldDrag = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sldDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mathClamp = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local finalVal = math.floor(min + ((max - min) * mathClamp))
                    Fill.Size = UDim2.new(mathClamp, 0, 1, 0)
                    SldLabel.Text = sldOptions.Title .. " : " .. tostring(finalVal)
                    cb(finalVal)
                end
            end)
        end

        function tabElements:Textbox(txtOptions)
            local cb = txtOptions.Callback or function() end

            local TxtFrame = Instance.new("Frame")
            TxtFrame.Size = UDim2.new(1, 0, 0, 45)
            TxtFrame.BackgroundColor3 = Theme.ElementBG
            TxtFrame.Parent = ScrollContent
            Instance.new("UICorner", TxtFrame).CornerRadius = UDim.new(0, 8)
            Instance.new("UIStroke", TxtFrame).Color = Theme.Stroke

            local TxtLabel = Instance.new("TextLabel")
            TxtLabel.Size = UDim2.new(0.5, 0, 1, 0)
            TxtLabel.Position = UDim2.new(0, 15, 0, 0)
            TxtLabel.BackgroundTransparency = 1
            TxtLabel.Text = txtOptions.Title or "Textbox"
            TxtLabel.TextColor3 = Theme.TextWhite
            TxtLabel.Font = Enum.Font.GothamBold
            TxtLabel.TextSize = 13
            TxtLabel.TextXAlignment = Enum.TextXAlignment.Left
            TxtLabel.Parent = TxtFrame

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(0.4, 0, 0, 30)
            Box.Position = UDim2.new(0.6, -15, 0.5, -15)
            Box.BackgroundColor3 = Theme.BG
            Box.Text = txtOptions.Value or ""
            Box.PlaceholderText = txtOptions.Placeholder or ""
            Box.TextColor3 = Theme.Grad1
            Box.Font = Enum.Font.GothamBlack
            Box.TextSize = 12
            Box.ClearTextOnFocus = txtOptions.ClearTextOnFocus or false
            Box.Parent = TxtFrame
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
            Instance.new("UIStroke", Box).Color = Theme.Stroke

            Box.FocusLost:Connect(function() cb(Box.Text) end)
        end

        return tabElements
    end

    function windowObj:Notify(notifOptions)
        print("[BOSS69 NOTIFY]:", notifOptions.Title, "-", notifOptions.Desc)
    end

    return windowObj
end


-- ==========================================
-- [[ การสร้าง UI แผงหลักด้วย Library ]]
-- ==========================================
local Window = CustomUI:Window({
    Title = " BOSS69  ",
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = isMobile and UDim2.new(0, 380, 0, 280) or UDim2.new(0, 540, 0, 460)
    }
})

-- ===================================
-- [[ TAB 1: ฟังก์ชันหลัก ]]
-- ===================================
local Tab1 = Window:Tab({Title = "ฟังก์ชันหลัก"})

Tab1:Section({Title = "เปิด/ปิด แผง UI ภายนอก"})

Tab1:Toggle({
    Title = "เปิดแผง ตามติดชีวิตวาน (Follow UI)",
    Value = false,
    Callback = function(v)
        if CoreGui:FindFirstChild("FollowSystemGui") then CoreGui.FollowSystemGui.Enabled = v end
    end
})

Tab1:Toggle({
    Title = "เปิดแผง ระบบบันทึกพิกัด (TP Manager)",
    Value = false,
    Callback = function(v)
        if CoreGui:FindFirstChild("TeleportSystem") then CoreGui.TeleportSystem.Enabled = v end
    end
})

Tab1:Section({Title = "ระบบทั่วไป"})

local InstantTakeConnection = nil
Tab1:Toggle({
    Title = "Instant Take (เก็บของทันที)",
    Value = false,
    Callback = function(v)
        if v then
            local function modifyPrompt(obj) if obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 end end
            for _, obj in pairs(workspace:GetDescendants()) do modifyPrompt(obj) end
            InstantTakeConnection = workspace.DescendantAdded:Connect(modifyPrompt)
        else
            if InstantTakeConnection then InstantTakeConnection:Disconnect() InstantTakeConnection = nil end
            for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("ProximityPrompt") then obj.HoldDuration = 1 end end
        end
    end
})

local flyToggle = Tab1:Toggle({
    Title = "เปิดใช้งานเมนูบิน (Fly GUI)",
    Value = false,
    Callback = function(v)
        if v then LoadUltraFlyGUI() else
            if CoreGui:FindFirstChild("UltraFlyCustomDrag") then CoreGui.UltraFlyCustomDrag.Enabled = false end
        end
    end
})

Tab1:Toggle({
    Title = "เดินทะลุกำแพง (Noclip)",
    Value = false,
    Callback = function(v)
        if v then
            NoclipLoop = RunService.Stepped:Connect(function()
                if localPlayer.Character then
                    for _, part in pairs(localPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                end
            end)
        else
            if NoclipLoop then NoclipLoop:Disconnect() NoclipLoop = nil end
            if localPlayer.Character then
                for _, part in pairs(localPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
            end
        end
    end
})

-- ฟังก์ชันปุ่มกดสำหรับเปิดปิด ESP โดยเชื่อมกับระบบใหม่ของเรา
Tab1:Toggle({
    Title = "มองผู้เล่น (ESP)",
    Value = false,
    Callback = function(v)
        ESP_Enabled = v
        if v then
            -- เมื่อเปิดให้แสกนหาผู้เล่นทั้งหมดในขณะนั้นแล้วสร้าง ESP
            for _, plr in pairs(Players:GetPlayers()) do 
                if plr ~= localPlayer then AddESP(plr) end 
            end
        else
            -- เมื่อปิดให้ลบ ESP ทิ้งให้หมด
            for _, plr in pairs(Players:GetPlayers()) do 
                RemoveESP(plr)
            end
        end
    end
})

Tab1:Section({Title = "ความเร็วและการมองเห็น"})

Tab1:Toggle({
    Title = "เปิดใช้งาน วิ่งไว",
    Value = false,
    Callback = function(v)
        SpeedEnabled = v
        if not v and localPlayer.Character then localPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end
    end
})
Tab1:Slider({
    Title = "ปรับความเร็ว", 
    Min = 16, 
    Max = 500, 
    Value = 16, 
    Callback = function(v) SpeedValue = v end
})
Tab1:Textbox({
    Title = "พิมพ์ตัวเลขความเร็ว",
    Placeholder = "ใส่เลข...",
    Value = "16",
    ClearTextOnFocus = false,
    Callback = function(v)
        local num = tonumber(v)
        if num then SpeedValue = num end
    end
})

Tab1:Toggle({
    Title = "เปิดใช้งาน แมพสว่าง",
    Value = false,
    Callback = function(v)
        BrightEnabled = v
        if not v then
            Lighting.Brightness = DefaultBrightness
            Lighting.ClockTime = DefaultClockTime
            Lighting.GlobalShadows = DefaultGlobalShadows
        else Lighting.GlobalShadows = false end
    end
})
Tab1:Slider({
    Title = "แถบปรับความสว่าง",
    Min = 0, 
    Max = 50, 
    Value = 2,
    Callback = function(v) BrightValue = v end
})
Tab1:Textbox({
    Title = "พิมพ์ตัวเลขความสว่าง",
    Placeholder = "ใส่เลข...",
    Value = "2",
    ClearTextOnFocus = false,
    Callback = function(v)
        local num = tonumber(v)
        if num then BrightValue = num end
    end
})

-- ===================================
-- [[ TAB 2: สคริปต์ภายนอก & แก้บัค ]]
-- ===================================
local Tab2 = Window:Tab({Title = "ควย"})

Tab2:Section({Title = "โหลดสคริปต์เสริม"})
Tab2:Button({Title = "รันสคริปต์บิน (Nameless Admin)", Callback = function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-nameless-admin-15646"))() end})
Tab2:Button({
    Title = "ปลดล็อกมุมกล้อง",
    Callback = function()
        local lp = game.Players.LocalPlayer
        lp.CameraMaxZoomDistance = 100000
        lp.CameraMinZoomDistance = 0.5
        lp.CameraMode = Enum.CameraMode.Classic
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
})
Tab2:Button({Title = "โหลดสคริปต์เสริม 1", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/oopplprt041-crypto/Sjejjwueuruurrururururruru/refs/heads/main/Yyyyyyyyyyyyyy.lua"))() end})

Tab2:Section({Title = "แก้บัคตัวละคร"})
Tab2:Button({
    Title = "💀 รีเซ็ตตัวละคร (ตาย)",
    Callback = function()
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.Health = 0
        end
    end
})

-- ===================================
-- [[ TAB 3: ออโต้ฟาร์ม ]]
-- ===================================
local Tab3 = Window:Tab({Title = "ออโต้ฟาร์ม"})
Tab3:Section({Title = "Auto Kick & Train"})

-- แก้ไขให้โหลด Net แบบปลอดภัย ไม่ค้างในแมพอื่น
local function GetNet()
    local rs = game:GetService("ReplicatedStorage")
    if rs:FindFirstChild("Shared") and rs.Shared:FindFirstChild("Packages") and rs.Shared.Packages:FindFirstChild("Network") then
        return rs.Shared.Packages.Network
    end
    return nil
end

local PlayerGui = localPlayer:WaitForChild("PlayerGui")
local kickValues = { ["Perfect"] = 1 }
local currentKickMode = "Perfect"

-- [ 1. ฟังก์ชัน Auto Kick ] --
local autoKick = false
local kickTick = 0
Tab3:Toggle({
    Title = " Auto Kick! 💫 (Perfect)",
    Value = false,
    Callback = function(v)
        autoKick = v
        kickTick = kickTick + 1
        local currentTick = kickTick
        
        if autoKick then
            task.spawn(function()
                while autoKick and currentTick == kickTick do
                    pcall(function()
                        local char = localPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local hum = char and char:FindFirstChild("Humanoid")
                        local Net = GetNet()
                        
                        if hrp and hum and Net then
                            hrp.Velocity = Vector3.new(0,0,0)
                            hrp.CFrame = workspace.Areas.KickReady.CFrame + Vector3.new(0, 5, 0)
                            task.wait(0.5)
                            
                            local guiBtn = PlayerGui.HUD.KickButton
                            if getconnections then
                                for _, c in pairs(getconnections(guiBtn.MouseButton1Click)) do c:Fire() end
                            end
                            
                            if currentKickMode == "Perfect" then
                                pcall(function()
                                    local vfx = game:GetService("ReplicatedStorage").Objects.VFX:FindFirstChild("PerfectKick")
                                    if vfx then
                                        local vfxClone = vfx:Clone()
                                        vfxClone.Parent = hrp
                                        if vfxClone:IsA("ParticleEmitter") then vfxClone:Emit(30) end
                                        for _, d in pairs(vfxClone:GetDescendants()) do 
                                            if d:IsA("ParticleEmitter") then d:Emit(30) end 
                                        end
                                        game:GetService("Debris"):AddItem(vfxClone, 2)
                                    end
                                end)
                            end
                            
                            local kickMultiplier = kickValues[currentKickMode] or 1
                            Net.rev_KickEvent:FireServer(kickMultiplier)
                            task.wait(0.2)
                            
                            Net.rev_Transformed:FireServer()
                            Net.rev_KickZman:FireServer()
                            task.wait(0.5)
                            
                            local safeZone = workspace.Lobby:FindFirstChild("Safe")
                            if safeZone then 
                                hrp.Velocity = Vector3.new(0,0,0)
                                hrp.CFrame = safeZone.CFrame + Vector3.new(0, 5, 0) 
                            end
                        end
                    end)
                    task.wait(2.9) 
                end
            end)
        end
    end
})

-- [ 2. ฟังก์ชัน Turbo Auto Click ] --
local autoClickEnabled = false
local targetImageID = "77461897800522" 

local turboToggle = Tab3:Toggle({
    Title = "🚀 เปิด Turbo Auto Click (เร็วสูงสุด)",
    Value = false,
    Callback = function(v)
        autoClickEnabled = v
        if autoClickEnabled then
            task.spawn(function()
                while autoClickEnabled do
                    task.wait() 
                    pcall(function()
                        for _, element in pairs(localPlayer.PlayerGui:GetDescendants()) do
                            if (element:IsA("ImageButton") or element:IsA("ImageLabel")) and element.Visible then
                                if element.Image and string.find(tostring(element.Image), targetImageID) then
                                    local btn = element
                                    if not btn:IsA("GuiButton") and btn.Parent and btn.Parent:IsA("GuiButton") then btn = btn.Parent end
                                    if btn:IsA("GuiButton") then
                                        if firesignal then firesignal(btn.MouseButton1Click) firesignal(btn.Activated) firesignal(btn.MouseButton1Down)
                                        elseif getconnections then for _, conn in pairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end for _, conn in pairs(getconnections(btn.Activated)) do conn:Fire() end end
                                        task.wait(0.1) 
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end
})

-- [ 3. ฟังก์ชัน Auto Loop Fly (ระบบใหม่แท็บ 3 ลำดับ 3) ] --
local pos1 = Vector3.new(698.13, 3.00 + 5, 204.66) 
local pos2 = Vector3.new(724.48, 3.00 + 5, 207.85)
local isAutoFlyEnabled = false
local isFlying = false
local flyNoclipConn = nil

local function flyMoveTo(targetPos, speed)
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local startPos = hrp.Position
    local distance = (startPos - targetPos).Magnitude
    local timeToReach = distance / speed
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isFlying then connection:Disconnect() return end
        local alpha = math.clamp((tick() - startTime) / timeToReach, 0, 1)
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
        if alpha >= 1 then connection:Disconnect() end
    end)
    while isFlying and (tick() - startTime) < timeToReach do task.wait() end
end

local function stopFlyingRoutine()
    isFlying = false
    if flyNoclipConn then flyNoclipConn:Disconnect() flyNoclipConn = nil end
    local char = localPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local bv = char.HumanoidRootPart:FindFirstChild("AntiGravity")
        if bv then bv:Destroy() end
    end
end

local function startFlyingRoutine()
    if isFlying then return end
    isFlying = true
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then isFlying = false return end
    local hrp = char.HumanoidRootPart
    local bv = Instance.new("BodyVelocity")
    bv.Name = "AntiGravity"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    flyNoclipConn = RunService.Stepped:Connect(function()
        for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
    end)
    task.spawn(function()
        for i = 1, 3 do
            if not isFlying then break end
            flyMoveTo(pos1, 110)
            if not isFlying then break end
            task.wait(1.5)
            flyMoveTo(pos2, 110)
            if not isFlying then break end
            task.wait(1)
            if i == 3 then flyMoveTo(pos1, 110) end
        end
        while isFlying do
            if char and char:FindFirstChild("HumanoidRootPart") then hrp.CFrame = CFrame.new(pos1) end
            task.wait(0.1)
        end
    end)
end

-- ระบบ Hook สำหรับ Auto Fly
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and method == "FireServer" and isAutoFlyEnabled then
        local remoteName = tostring(self)
        if remoteName == "rev_Transformed" then
            task.spawn(function()
                task.wait(2)
                if isAutoFlyEnabled and not isFlying then startFlyingRoutine() end
            end)
        elseif remoteName == "rev_KickCollect" then
            task.spawn(stopFlyingRoutine)
        end
    end
    return oldNamecall(self, ...)
end)

local autoFlyToggle = Tab3:Toggle({
    Title = "✈️ เปิด Auto Loop Fly (3 Rounds)",
    Value = false,
    Callback = function(v)
        isAutoFlyEnabled = v
        if not v then stopFlyingRoutine() end
    end
})


-- ==========================================
-- [[ ลูปทำงานเบื้องหลังภาพรวม ]]
-- ==========================================
RunService.Heartbeat:Connect(function()
    if SpeedEnabled and localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
        localPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = SpeedValue
    end
    if BrightEnabled then 
        Lighting.Brightness = BrightValue 
        Lighting.ClockTime = 14 
    end
end)

Window:Notify({
    Title = "BOSS69",
    Desc = "ระบบ UI Premium และ ESP ใหม่รันเสร็จสิ้น!"
})

-- [ บังคับเปิดใช้งานตั้งแต่รันสคริปต์ ] --
flyToggle.Set(true)
turboToggle.Set(true)
autoFlyToggle.Set(true)
