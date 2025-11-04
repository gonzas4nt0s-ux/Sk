-- ⚙️ Adaptado para KRNL Android - Melee Admin (by ChatGPT)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local MeleeEvent = ReplicatedStorage:WaitForChild("MeleeEvent")

-- 🖥️ UI
local gui = Instance.new("ScreenGui")
gui.Name = "MeleeAdminAndroid"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 240, 0, 260)
frame.Position = UDim2.new(0.03, 0, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true -- 📱 se puede mover con el dedo

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "⚔️ MELEE ADMIN (Android)"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

-- Variables configurables
local range, repeats, damage, spoof = 12, 80, 50, 6
local loopActive = false

-- Funciones helpers
local function spoofOrigin(dist)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return Vector3.new(0,0,0) end
	return root.Position + root.CFrame.LookVector * dist
end

local function sendMeleeOnce(mode)
	local origin = spoofOrigin(spoof)
	local params = {
		origin = origin,
		range = range,
		repeats = repeats,
		damage = damage,
		mode = mode or "single",
	}
	MeleeEvent:FireServer(params)
end

-- Crear botón genérico
local function makeButton(y, text, func)
	local btn = Instance.new("TextButton")
	btn.Parent = frame
	btn.Size = UDim2.new(1, -12, 0, 28)
	btn.Position = UDim2.new(0, 6, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 14
	btn.Text = text
	btn.BorderSizePixel = 0
	btn.MouseButton1Click:Connect(func)
	return btn
end

-- 📏 Controles táctiles simples
local rangeBtn = makeButton(36, "Range: 12", function()
	range = (range >= 100) and 12 or range + 12
	rangeBtn.Text = "Range: " .. range
end)

local repBtn = makeButton(72, "Repeats: 80", function()
	repeats = (repeats >= 500) and 80 or repeats + 80
	repBtn.Text = "Repeats: " .. repeats
end)

local dmgBtn = makeButton(108, "Damage: 50", function()
	damage = (damage >= 1000) and 50 or damage + 50
	dmgBtn.Text = "Damage: " .. damage
end)

local spoofBtn = makeButton(144, "Spoof Forward: 6", function()
	spoof = (spoof >= 80) and 6 or spoof + 6
	spoofBtn.Text = "Spoof Forward: " .. spoof
end)

local killBtn = makeButton(180, "⚡ KILL ALL (una vez)", function()
	sendMeleeOnce("kill")
end)

local loopBtn = makeButton(216, "🔁 TOGGLE LOOPKILL: OFF", function()
	loopActive = not loopActive
	loopBtn.Text = "🔁 TOGGLE LOOPKILL: " .. (loopActive and "ON" or "OFF")
	if loopActive then
		task.spawn(function()
			while loopActive do
				sendMeleeOnce("kill")
				task.wait(0.12)
			end
		end)
	end
end)