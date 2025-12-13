print("Auto Mummy Return? Loaded")

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local player = Players.LocalPlayer

--================ CONFIG ================--
local LIVES_FOLDER_NAME = "Lives"
local MUMMY_NAME        = "Mummy Lv.40"

local APPROACH_DISTANCE = 5
local TWEEN_TIME        = 0.35

local ATTACK_DELAY      = 0.5
local MOUSE_CFRAME      = CFrame.new(-2678.40234375, 0.7871074, -674.6618652, 1,0,0, 0,1,0, 0,0,1)

--================ QUEST DIALOG ================--

local function fireDialogue(choiceText)
    local remote = ReplicatedStorage
        :WaitForChild("Remote")
        :WaitForChild("Event")
        :WaitForChild("Dialogue")

    local args = { { Choice = choiceText } }
    remote:FireServer(unpack(args))
end

local function clickWindTourist()
    local cd = Workspace.NPC.WindTourist.ClickDetector
    cd.MaxActivationDistance = 100000000000
    if fireclickdetector then
        fireclickdetector(cd)
    end
end

local function startMummyQuest()
    clickWindTourist()
    task.wait(1.5) -- waktu buka dialog
    fireDialogue("Start 'Mummy Return?'")
end

local function completeMummyQuestOnly()
    clickWindTourist()
    task.wait(1.5) -- buka dialog selesai quest
    fireDialogue("Yes, I've completed it.")
end

--================ COMBAT / TARGET ================--

local function getLivesFolder()
    return Workspace:FindFirstChild(LIVES_FOLDER_NAME)
end

local function getNearestMummy()
    local lives = getLivesFolder()
    if not lives then return nil end

    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = character.HumanoidRootPart

    local nearest, dist = nil, math.huge
    for _, child in ipairs(lives:GetChildren()) do
        if child.Name == MUMMY_NAME then
            local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
            if root then
                local d = (root.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = child
                end
            end
        end
    end

    return nearest
end

local function getHandlerEvent()
    local character = player.Character
    if not character or not character.Parent then return nil end

    local ok, result = pcall(function()
        local handler = character:WaitForChild("PlayerHandler", 3)
        if not handler then return nil end
        return handler:WaitForChild("HandlerEvent", 3)
    end)

    return ok and result or nil
end

local function fireHeavyAttack()
    local handlerEvent = getHandlerEvent()
    if not handlerEvent then return end

    local args = { {
        CombatAction = true,
        AttackType   = "Down",
        HeavyAttack  = true,
        MouseData    = MOUSE_CFRAME
    } }
    handlerEvent:FireServer(unpack(args))
end

local function fireSkill(key)
    local handlerEvent = getHandlerEvent()
    if not handlerEvent then return end

    local args = { {
        Skill      = true,
        AttackType = "Down",
        Key        = key,
        MouseData  = MOUSE_CFRAME
    } }
    handlerEvent:FireServer(unpack(args))
end

local function tweenPlayerToTarget(model)
    if not model then return end

    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = character.HumanoidRootPart
    local targetRoot = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
    if not targetRoot then return end

    local targetPos = targetRoot.Position
    local playerPos = hrp.Position
    local dir       = targetPos - playerPos
    if dir.Magnitude <= 0 then return end

    local finalPos
    if dir.Magnitude > APPROACH_DISTANCE then
        finalPos = targetPos - dir.Unit * APPROACH_DISTANCE
    else
        finalPos = playerPos
    end

    local info  = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, info, {CFrame = CFrame.new(finalPos, targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

local function killOneMummy()
    local mummy = getNearestMummy()
    if not mummy then return false end

    tweenPlayerToTarget(mummy)

    local lives = getLivesFolder()
    local timeout = tick() + 10 -- anti nyangkut 10 detik

    while mummy and mummy.Parent == lives and tick() < timeout do
        fireHeavyAttack()
        fireSkill("E")
        fireSkill("V")
        task.wait(ATTACK_DELAY)
    end

    return true
end

local function killSixMummy()
    for i = 1, 6 do
        if not killOneMummy() then
            -- kalau tidak ada mummy, tunggu respawn sebentar
            task.wait(1)
        end
        task.wait(0.2)
    end
end

--================ MAIN LOOP AUTO MUMMY QUEST ================--

local autoMummyLoopRunning = false

local function startAutoMummyLoop()
    if autoMummyLoopRunning then return end
    autoMummyLoopRunning = true

    StarterGui:SetCore("SendNotification", {
        Title = "Auto Mummy Return?",
        Text  = "ON (Quest + Kill 6 Mummy)",
        Duration = 3
    })

    task.spawn(function()
        while autoMummyLoopRunning do
            -- STEP 1: ambil quest
            startMummyQuest()

            -- delay setelah ambil quest sebelum kill
            task.wait(1.5)

            -- STEP 2: bunuh 6 mummy
            killSixMummy()

            -- delay setelah kill sebelum complete
            task.wait(1)

            -- STEP 3: complete quest
            completeMummyQuestOnly()

            -- delay kecil biar server update, lalu ulang dari STEP 1
            task.wait(1)
        end
    end)
end

local function stopAutoMummyLoop()
    autoMummyLoopRunning = false
    StarterGui:SetCore("SendNotification", {
        Title = "Auto Mummy Return?",
        Text  = "OFF",
        Duration = 3
    })
end

--================ SIMPLE TOGGLE GUI ================--

local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AutoMummyReturn"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 70)
frame.Position = UDim2.new(0, 20, 0.65, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 30)
button.Position = UDim2.fromOffset(10, 20)
button.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "AUTO MUMMY RETURN?: OFF"
button.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

button.MouseButton1Click:Connect(function()
    if autoMummyLoopRunning then
        stopAutoMummyLoop()
        button.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
        button.Text = "AUTO MUMMY RETURN?: OFF"
    else
        startAutoMummyLoop()
        button.BackgroundColor3 = Color3.fromRGB(255, 80, 120)
        button.Text = "AUTO MUMMY RETURN?: ON"
    end
end)
