
-- XENO NIGHTMARE DEERGOD MODEL LOADER (.rbxm / .rbxmx)

local G = getgenv()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- GitHub model loader
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        warn("Xeno: Required file functions are unavailable")
        return nil
    end

    local function generateFileName(input)
        local hash = 0
        for i = 1, #input do
            hash = (hash * 31 + string.byte(input, i)) % 2^32
        end
        return "deer_god_" .. tostring(hash) .. ".rbxm"
    end

    local fileName = generateFileName(url)

    -- Try cached model first
    local exists = false
    if isfile then
        local ok, result = pcall(function()
            return isfile(fileName)
        end)
        exists = ok and result
    end

    if exists then
        local ok, result = pcall(function()
            local assetId = getcustomasset(fileName)
            return game:GetObjects(assetId)[1]
        end)

        if ok and result then
            return result
        end
    end

    -- Download model from GitHub
    local ok, response = pcall(function()
        return request({
            Url = url,
            Method = "GET"
        })
    end)

    if not ok or not response or response.StatusCode ~= 200 then
        warn("Xeno: Failed to download NIGHTMARE DEERGOD")
        return nil
    end

    local saved = pcall(function()
        writefile(fileName, response.Body)
    end)

    if not saved then
        warn("Xeno: Failed to save model file")
        return nil
    end

    local loaded, result = pcall(function()
        local assetId = getcustomasset(fileName)
        return game:GetObjects(assetId)[1]
    end)

    if loaded and result then
        return result
    end

    warn("Xeno: Failed to load downloaded model")
    return nil
end


local function DeerGod()
    -- SETTINGS
    local SPEED = 100
    local ambruhspeed = SPEED
    local storer = SPEED
    local ambruhheight = Vector3.new(0, 3.4, 0)

    local gameData = ReplicatedStorage:WaitForChild("GameData")
    local latestRoom = gameData:WaitForChild("LatestRoom")
    local currentRooms = workspace:WaitForChild("CurrentRooms")

    local killed = false

    -- Load NIGHTMARE DEERGOD from GitHub
    local modelUrl =
        "https://raw.githubusercontent.com/Ilikerobloxdoors/NIGHTMARE-DEERGOD/main/NIGHTMARE%20DEERGOD.rbxm"

    local entity = G.LoadGithubModel(modelUrl)

    if not entity then
        warn("Xeno: NIGHTMARE DEERGOD model failed to load")
        return
    end

    entity.Parent = workspace

    local entityPart = entity:FindFirstChildWhichIsA("BasePart", true)

    if not entityPart then
        warn("Xeno: Model has no BasePart")
        entity:Destroy()
        return
    end

    -- Camera shake setup
    local cameraShaker = require(ReplicatedStorage:WaitForChild("CameraShaker"))
    local camera = workspace.CurrentCamera

    local camShake = cameraShaker.new(
        Enum.RenderPriority.Camera.Value,
        function(cf)
            camera.CFrame = camera.CFrame * cf
        end
    )

    camShake:Start()

    -- Detect whether a boss encounter is active
    local function isBossActive()
        local room = latestRoom.Value

        if room == 50 or room == 100 then
            return true
        end

        for _, sound in ipairs(ReplicatedStorage:GetDescendants()) do
            if sound:IsA("Sound")
                and sound.IsPlaying
                and (sound.Name:find("Music") or sound.Name == "Shade") then
                return true
            end
        end

        return false
    end

    -- Line-of-sight detection
    local function canSeeTarget(target, size)
        if killed or isBossActive() then
            return false
        end

        local root = target:FindFirstChild("HumanoidRootPart")
        if not root then
            return false
        end

        local origin = entityPart.Position
        local direction = (root.Position - origin).Unit * size
        local ray = Ray.new(origin, direction)

        local hit = workspace:FindPartOnRay(ray, entity)

        if hit and hit:IsDescendantOf(target) then
            killed = true
            return true
        end

        return false
    end

    local function GetTime(dist, speed)
        return dist / speed
    end

    task.wait(1)

    -- Player detection
    task.spawn(function()
        while entity.Parent and entityPart.Parent do
            task.wait(0.01)

            local player = game.Players.LocalPlayer
            local character = player and player.Character

            if character
                and character:FindFirstChild("HumanoidRootPart")
                and character:FindFirstChildOfClass("Humanoid") then

                if canSeeTarget(character, 50)
                    and not character:GetAttribute("Hiding") then

                    character.Humanoid:TakeDamage(100)

                    pcall(function()
                        ReplicatedStorage.GameStats[
                            "Player_" .. character.Name
                        ].Total.DeathCause.Value = "Deer God"
                    end)

                    local hints = {
                        "You died to Dear god...",
                        "Hide wont work, so try running",
                        "Avoid eye contact!"
                    }

                    local remotesFolder =
                        ReplicatedStorage:FindFirstChild("RemotesFolder")
                        or ReplicatedStorage:FindFirstChild("Bricks")

                    if remotesFolder
                        and remotesFolder:FindFirstChild("DeathHint") then

                        firesignal(
                            remotesFolder.DeathHint.OnClientEvent,
                            hints,
                            "Blue"
                        )
                    end
                end
            end
        end
    end)

    -- Stronger camera shake every 1.6 seconds
    task.spawn(function()
        while entity.Parent and entityPart.Parent do
            task.wait(1.6)

            if entity.Parent and entityPart.Parent then
                camShake:ShakeOnce(4, 6, 0.1, 1.2)
            end
        end
    end)

    -- Move through room nodes at 100 studs per second
    ambruhspeed = SPEED

    for i = 1, latestRoom.Value + 1 do
        if not entity.Parent then
            break
        end

        local room = currentRooms:FindFirstChild(tostring(i))

        if room then
            local nodes = room:FindFirstChild("Nodes")

            if nodes then
                for _, node in ipairs(nodes:GetChildren()) do
                    if not entity.Parent then
                        break
                    end

                    if node:IsA("BasePart") then
                        local dist =
                            (entityPart.Position - node.Position).Magnitude

                        local duration = GetTime(dist, ambruhspeed)

                        local tween = game:GetService("TweenService"):Create(
                            entityPart,
                            TweenInfo.new(
                                duration,
                                Enum.EasingStyle.Linear,
                                Enum.EasingDirection.Out
                            ),
                            {
                                CFrame = node.CFrame + ambruhheight
                            }
                        )

                        tween:Play()
                        tween.Completed:Wait()

                        ambruhspeed = storer
                    end
                end
            end
        end
    end

    -- Remove entity after its run
    if entity.Parent then
        local tween = game:GetService("TweenService"):Create(
            entityPart,
            TweenInfo.new(1.5),
            {
                CFrame = entityPart.CFrame * CFrame.new(0, -80, 0)
            }
        )

        tween:Play()
        game:GetService("Debris"):AddItem(entity, 1.5)
        task.wait(1.5)
    end

    camShake:Stop()

    -- Custom NIGHTMARE DEERGOD Achievement
    task.wait(2)

    local success, result = pcall(function()
        local CustomAchievements = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/RegularVynixu/DOORS-Custom-Achievements/main/init.luau"
        ))()

        if CustomAchievements:CheckOwned("TestAchievement") then
            CustomAchievements:Revoke("TestAchievement")
        end

        CustomAchievements:Grant({
            Identifier = "TestAchievement",
            Title = "Faster And Faster And Faster",
            Desc = "Hes running way faster than before",
            Reason = "Survive And Encounter Nightmare DearGod",
            Image = "rbxassetid://139658033332422"
        }, {
            CheckOwned = true,
            Remember = true
        })
    end)

    if not success then
        warn("Xeno: Custom achievement failed: " .. tostring(result))
    end
end

local success, err = pcall(DeerGod)

if not success then
    warn("Xeno DeerGod error: " .. tostring(err))
end
