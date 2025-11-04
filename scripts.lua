-- MeleeClient (LocalScript en StarterGui)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local MeleeEvent = ReplicatedStorage:WaitForChild("MeleeEvent")

-- UI simple
local screen = Instance.new("ScreenGui")
screen.Name = "MeleeAdminGUI"
screen.ResetOnSpawn = false
screen.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 260, 0, 260)
frame.Position = UDim2.new(0.02,0,0.35,0)
frame.BackgroundTransparency = 0.15
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "MELEE ADMIN - ROTO"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

local function makeLabel(y,text)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1,-12,0,20)
    l.Position = UDim2.new(0,6,0,y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = Enum.Font.SourceSans
    l.TextSize = 14
    return l
end

local function makeSlider(y, minv, maxv, default)
    local lbl = makeLabel(y, "")
    local sliderBack = Instance.new("Frame", frame)
    sliderBack.Size = UDim2.new(1,-16,0,18)
    sliderBack.Position = UDim2.new(0,8,0,y+20)
    sliderBack.BackgroundColor3 = Color3.fromRGB(60,60,60)
    sliderBack.BorderSizePixel = 0

    local knob = Instance.new("Frame", sliderBack)
    knob.Size = UDim2.new(0.2,0,1,0)
    knob.Position = UDim2.new(0,0,0,0)
    knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(200,200,200)

    local value = default
    local function updateLabel()
        lbl.Text = string.format("%s: %d", lbl.Name or "Valor", math.floor(value))
    end

    -- simple dragging
    local dragging = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    local function onMove(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local x = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
            knob.Size = UDim2.new(0,x,1,0)
            value = minv + (maxv - minv) * x
            updateLabel()
        end
    end
    local function stopDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end
    UserInputService.InputChanged:Connect(onMove)
    UserInputService.InputEnded:Connect(stopDrag)

    -- init
    local initX = (default - minv) / (maxv - minv)
    knob.Size = UDim2.new(initX,0,1,0)
    value = default
    lbl.Name = "Slider"
    updateLabel()

    return function() return value end, lbl
end

-- Crear controles con límites potentes (usar con responsabilidad en tu juego)
local getRange, rlbl = makeSlider(36, 1, 100, 12)
rlbl.Text = "Range: 12"

local getRepeats, repLbl = makeSlider(76, 1, 500, 80)
repLbl.Text = "Repeats: 80"

local getDamage, dmgLbl = makeSlider(116, 0, 1000, 50)
dmgLbl.Text = "Damage: 50"

local getSpoof, spfLbl = makeSlider(156, 0, 80, 6)
spfLbl.Text = "Spoof forward: 6"

-- botones
local function makeButton(y, text)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1,-12,0,28)
    b.Position = UDim2.new(0,6,0,y)
    b.Text = text
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 14
    b.BackgroundColor3 = Color3.fromRGB(80,80,80)
    b.TextColor3 = Color3.new(1,1,1)
    b.BorderSizePixel = 0
    return b
end

local killBtn = makeButton(196, "KILL ALL (una vez)")
local loopBtn = makeButton(232, "TOGGLE LOOPKILL: OFF")
local loopActive = false
local loopId = tostring(math.random(100000,999999))

-- función que arma origin spoofed
local function getSpoofedOrigin(forwardDist)
    local char = player.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not root then return root and root.Position or Vector3.new(0,0,0) end
    return root.Position + root.CFrame.LookVector * forwardDist
end

local sendingLoop = nil
local function sendMeleeOnce(mode)
    local origin = getSpoofedOrigin(getSpoof())
    local params = {
        origin = origin,
        range = getRange(),
        repeats = math.floor(getRepeats()),
        damage = math.floor(getDamage()),
        mode = mode or "single",
    }
    -- Enviar
    MeleeEvent:FireServer(params)
end

killBtn.MouseButton1Click:Connect(function()
    sendMeleeOnce("kill") -- "kill" hace health = 0 en server si el server lo permite
end)

loopBtn.MouseButton1Click:Connect(function()
    loopActive = not loopActive
    loopBtn.Text = "TOGGLE LOOPKILL: " .. (loopActive and "ON" or "OFF")
    if loopActive and not sendingLoop then
        sendingLoop = true
        spawn(function()
            while loopActive do
                sendMeleeOnce("kill")
                wait(0.12) -- client-side pacing (ajustable)
            end
            sendingLoop = false
        end)
    else
        loopActive = false
    end
end)

-- hotkey K para enviar una vez
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        sendMeleeOnce("kill")
    end
end)

-- Helpers: actualizar labels periódicamente (muestra valores actuales)
spawn(function()
    while true do
        rlbl.Text = "Range: " .. tostring(math.floor(getRange()))
        repLbl.Text = "Repeats: " .. tostring(math.floor(getRepeats()))
        dmgLbl.Text = "Damage: " .. tostring(math.floor(getDamage()))
        spfLbl.Text = "Spoof forward: " .. tostring(math.floor(getSpoof()))
        wait(0.15)
    end
end)