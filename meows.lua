local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local LOCK_KEY = Enum.KeyCode.Q


local MAX_DISTANCE = 1000
local MAX_SCREEN_DISTANCE = 250
local AIM_SMOOTHNESS = 1

local lockedTarget = nil
local enabled = false


local function findClosestTarget()
	local closestPlayer = nil
	local closestScreenDistance = MAX_SCREEN_DISTANCE

	local screenCenter = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player then

			local character = targetPlayer.Character
			if character then

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local rootPart =
					character:FindFirstChild("UpperTorso")
					or character:FindFirstChild("Torso")
					or character:FindFirstChild("HumanoidRootPart")

				if humanoid and rootPart and humanoid.Health > 0 then

					local distance =
						(player.Character
						and player.Character:FindFirstChild("HumanoidRootPart")
						and (rootPart.Position -
						player.Character.HumanoidRootPart.Position).Magnitude)
						or math.huge

					if distance <= MAX_DISTANCE then

						local screenPosition, visible =
							camera:WorldToViewportPoint(rootPart.Position)

						if visible and screenPosition.Z > 0 then

							local targetPosition = Vector2.new(
								screenPosition.X,
								screenPosition.Y
							)

							local screenDistance =
								(targetPosition - screenCenter).Magnitude

							if screenDistance < closestScreenDistance then
								closestScreenDistance = screenDistance
								closestPlayer = targetPlayer
							end
						end
					end
				end
			end
		end
	end

	return closestPlayer
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == LOCK_KEY then
		enabled = not enabled

		if enabled then
			lockedTarget = findClosestTarget()
		else
			lockedTarget = nil
		end
	end
end)


RunService.RenderStepped:Connect(function()
	if not enabled then return end
	if not lockedTarget then return end

	local character = lockedTarget.Character
	if not character then
		lockedTarget = findClosestTarget()
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	local torso =
		character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 or not torso then
		lockedTarget = findClosestTarget()
		return
	end


	local cameraPosition = camera.CFrame.Position

	local targetCFrame = CFrame.lookAt(
		cameraPosition,
		torso.Position
	)

	camera.CFrame = camera.CFrame:Lerp(
		targetCFrame,
		AIM_SMOOTHNESS
	)
end)