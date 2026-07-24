local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("X6G1_Hub")
if oldGui then oldGui:Destroy() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService('VirtualUser')

local Settings = {
    Aimbot = {
        Enabled = false,
        Draw = false,
        DrawSize = 50,
        TargetParts = {"Head"},
        CheckDowned = false,
        CheckWall = false,
        CheckTeam = false,
        Velocity = false,
        Smooth = false,
        SmoothSize = 0.5,
    },
    KeyBinds = {
        aimbot = nil,
        melee = nil,
        noRecoil = nil,
        fly = nil,
        noclip = nil,
        infiniteStamina = nil,
        nofalldamage = nil,
        nobarriers = nil,
        esp = nil,
        invis = nil,
        safeESP = nil,
        fullbright = nil,
        fov = nil,
        autodoors = nil,
        unlockdoors = nil,
        autopickupmoney = nil,
        autopickupscraps = nil,
        autopickuptools = nil,
        fastpickup = nil,
        nofaillockpick = nil,
        fakedown = nil,
        stopneckmove = nil,
        unbreaklimbs = nil,
        instantreload = nil,
        admincheck = nil,
    }
}

local RageSettings = {
    Enabled = false,
    FireRate = 5,
    Prediction = false,
    PredictionAmount = 0.1,
    VisibilityCheck = false,
    HitNotifyEnabled = false,
    HitNotifyDuration = 3,
    HitSoundType = "Default",
    CustomHitSoundId = "rbxassetid://6534948092",
    FovEnabled = false,
    FovRadius = 100,
    NoFovLimit = false,
    DownedCheck = false,
    NoFireRateLimit = false,
    LastShot = 0,
}

local NewFeatures = {
    AutoLockpick = false,
    HitNotifyColor = Color3.fromRGB(0,255,0),
}

local AimbotRunning = false
local AimbotCoroutine = nil
local AimbotCircle = nil

local function StartAimbot()
    if AimbotRunning then return end
    AimbotRunning = true
    AimbotCoroutine = task.spawn(function()
        local pressed = false
        local aimtarget = nil
        local canusing = false
        local FirstPerson = true
        local predict = 15
        local part = nil
        local randpart = nil
        local lastRandomTick = tick()

        local function getClosestTarget()
            local closest, closestDist = nil, Settings.Aimbot.DrawSize
            local mousePos = UserInputService:GetMouseLocation()
            for _, player in pairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char = player.Character
                if not char then continue end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if not onScreen then continue end
                if Settings.Aimbot.CheckTeam and player.Team == LocalPlayer.Team then continue end
                if Settings.Aimbot.CheckWall then
                    local ignore = {Camera, LocalPlayer.Character, char}
                    if player.Parent ~= workspace then table.insert(ignore, player.Parent) end
                    local checkpart = char:FindFirstChild("HumanoidRootPart")
                    if not checkpart then continue end
                    local parts = Camera:GetPartsObscuringTarget({checkpart.Position}, ignore)
                    if #parts > 0 then continue end
                end
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
            return closest
        end

        local inputBegan = UserInputService.InputBegan:Connect(function(key, gpe)
            if gpe then return end
            if not UserInputService:GetFocusedTextBox() and key.UserInputType == Enum.UserInputType.MouseButton2 then
                pressed = true
                aimtarget = getClosestTarget()
            end
        end)
        local inputEnded = UserInputService.InputEnded:Connect(function(key, gpe)
            if gpe then return end
            if not UserInputService:GetFocusedTextBox() and key.UserInputType == Enum.UserInputType.MouseButton2 then
                pressed = false
                aimtarget = nil
            end
        end)

        while AimbotRunning do
            if Settings.Aimbot.Draw then
                if not AimbotCircle then
                    AimbotCircle = Drawing.new("Circle")
                    AimbotCircle.Color = Color3.new(1,0,0)
                    AimbotCircle.Thickness = 2
                    AimbotCircle.Filled = false
                    AimbotCircle.Radius = Settings.Aimbot.DrawSize
                    AimbotCircle.Visible = true
                end
                local mousePos = UserInputService:GetMouseLocation()
                AimbotCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
                AimbotCircle.Radius = Settings.Aimbot.DrawSize
                AimbotCircle.Visible = true
            else
                if AimbotCircle then AimbotCircle.Visible = false end
            end

            if FirstPerson then
                local magnitude = (Camera.Focus.p - Camera.CFrame.p).Magnitude
                canusing = magnitude <= 1.5
            end

            if pressed and aimtarget and aimtarget.Character then
                local humanoid = aimtarget.Character:FindFirstChild("Humanoid")
                local targetParts = Settings.Aimbot.TargetParts
                if #targetParts == 0 then part = "Head"
                elseif #targetParts == 1 then part = targetParts[1]
                else
                    if tick() - lastRandomTick >= 0.5 then
                        randpart = targetParts[math.random(1, #targetParts)]
                        lastRandomTick = tick()
                    end
                    part = randpart or targetParts[1]
                end
                if part and humanoid and humanoid.Health > 0 and canusing then
                    local targetPart = aimtarget.Character[part]
                    if targetPart then
                        local targetPos = targetPart.Position
                        if Settings.Aimbot.Velocity then
                            targetPos = targetPos + targetPart.Velocity / predict
                        end
                        if Settings.Aimbot.Smooth then
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.p, targetPos), Settings.Aimbot.SmoothSize)
                        else
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                        end
                    end
                end
            end

            RunService.RenderStepped:Wait()
        end

        inputBegan:Disconnect()
        inputEnded:Disconnect()
        if AimbotCircle then AimbotCircle:Remove(); AimbotCircle = nil end
        AimbotRunning = false
        AimbotCoroutine = nil
    end)
end

local function StopAimbot()
    if AimbotRunning then
        AimbotRunning = false
        if AimbotCoroutine then AimbotCoroutine = nil end
    else
        if AimbotCircle then AimbotCircle:Remove(); AimbotCircle = nil end
    end
end

local bodySelector = nil
local function CreateBodySelector()
    if bodySelector then bodySelector:Destroy(); bodySelector = nil return end
    local screenGui = playerGui:FindFirstChild("X6G1_Hub")
    if not screenGui then return end
    local selector = Instance.new("Frame")
    selector.Name = "BodySelector"
    selector.Size = UDim2.new(0, 200, 0, 250)
    selector.Position = UDim2.new(0.5, -100, 0.5, -125)
    selector.AnchorPoint = Vector2.new(0.5,0.5)
    selector.BackgroundColor3 = Color3.fromRGB(20,20,25)
    selector.BorderSizePixel = 0
    selector.Parent = screenGui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,12); corner.Parent = selector
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(60,60,75); stroke.Thickness = 1; stroke.Parent = selector

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1
    title.Text = "选择目标部位"
    title.TextColor3 = Color3.fromRGB(220,220,220)
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 16
    title.Parent = selector

    local parts = {"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}
    local displayNames = {"头部","躯干","左臂","右臂","左腿","右腿"}
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0,4)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = selector

    for i, partName in ipairs(parts) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9,0,0,30)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btn.Text = displayNames[i]
        btn.TextColor3 = Color3.fromRGB(210,210,210)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = selector
        local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(0,6); corner2.Parent = btn
        local stroke2 = Instance.new("UIStroke"); stroke2.Color = Color3.fromRGB(80,80,90); stroke2.Thickness = 1; stroke2.Parent = btn
        local function updateHighlight()
            local found = false
            for _, v in pairs(Settings.Aimbot.TargetParts) do
                if v == displayNames[i] then found = true; break end
            end
            btn.BackgroundColor3 = found and Color3.fromRGB(70,180,100) or Color3.fromRGB(40,40,50)
        end
        updateHighlight()
        btn.MouseButton1Click:Connect(function()
            local idx = table.find(Settings.Aimbot.TargetParts, displayNames[i])
            if idx then
                table.remove(Settings.Aimbot.TargetParts, idx)
            else
                table.insert(Settings.Aimbot.TargetParts, displayNames[i])
            end
            updateHighlight()
        end)
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.4,0,0,30)
    closeBtn.Position = UDim2.new(0.3,0,1,-40)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,70)
    closeBtn.Text = "关闭"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = selector
    local corner3 = Instance.new("UICorner"); corner3.CornerRadius = UDim.new(0,6); corner3.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function() selector:Destroy(); bodySelector = nil end)

    bodySelector = selector
end

if LocalPlayer then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local MeleeAura_Enabled = false
local MeleeAura_Connection = nil
local function MeleeAttack(target)
    if not (target and target:FindFirstChild("Head")) then return end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local remote1 = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("XMHH.2")
    local remote2 = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("XMHH2.2")
    if not remote1 or not remote2 then return end
    local arg1 = {"🍞", tick(), tool, "43TRFWX", "Normal", tick(), true}
    local success1, result = pcall(function() return remote1:InvokeServer(unpack(arg1)) end)
    if not success1 then return end
    task.wait(0.1)
    local Handle = tool and (tool:FindFirstChild("WeaponHandle") or tool:FindFirstChild("Handle")) or (char and char:FindFirstChild("Right Arm"))
    local head = target:FindFirstChild("Head")
    if Handle and head and hrp then
        local arg2 = {"🍞", tick(), tool, "2389ZFX34", result, false, Handle, head, target, hrp.Position, head.Position}
        pcall(function() remote2:FireServer(unpack(arg2)) end)
    end
end
function MeleeAura_Enable()
    if MeleeAura_Enabled then return end
    MeleeAura_Enabled = true
    MeleeAura_Connection = RunService.RenderStepped:Connect(function()
        if not MeleeAura_Enabled then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local c = plr.Character
                    local hrp2 = c and c:FindFirstChild("HumanoidRootPart")
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    if hrp2 and hum and (hrp.Position - hrp2.Position).Magnitude < 5 and hum.Health > 15 and not c:FindFirstChildOfClass("ForceField") then
                        MeleeAttack(c)
                    end
                end
            end
        end
    end)
end
function MeleeAura_Disable()
    if not MeleeAura_Enabled then return end
    MeleeAura_Enabled = false
    if MeleeAura_Connection then MeleeAura_Connection:Disconnect(); MeleeAura_Connection = nil end
end

local NoRecoil_Enabled = false
local NoRecoil_Connections = {}
local GlobalOriginalValues = {}
local WeaponCache = {}
local GunSettings = {NoRecoil=true, Spread=true, SpreadAmount=0}
function cacheWeapons()
    WeaponCache = {}
    for _, v in pairs(getgc(true)) do
        if type(v)=='table' and rawget(v,'EquipTime') then
            table.insert(WeaponCache, v)
            if not GlobalOriginalValues[v] then
                GlobalOriginalValues[v]={Recoil=v.Recoil, CameraRecoilingEnabled=v.CameraRecoilingEnabled, AngleX_Min=v.AngleX_Min, AngleX_Max=v.AngleX_Max, AngleY_Min=v.AngleY_Min, AngleY_Max=v.AngleY_Max, AngleZ_Min=v.AngleZ_Min, AngleZ_Max=v.AngleZ_Max, Spread=v.Spread}
            end
        end
    end
end
function applyGunMods()
    for _, weapon in ipairs(WeaponCache) do
        if GunSettings.NoRecoil then
            weapon.Recoil=0; weapon.CameraRecoilingEnabled=false; weapon.AngleX_Min=0; weapon.AngleX_Max=0; weapon.AngleY_Min=0; weapon.AngleY_Max=0; weapon.AngleZ_Min=0; weapon.AngleZ_Max=0
        end
        if GunSettings.Spread then weapon.Spread=GunSettings.SpreadAmount end
    end
end
function resetGunMods()
    for weapon, values in pairs(GlobalOriginalValues) do
        weapon.Recoil=values.Recoil; weapon.CameraRecoilingEnabled=values.CameraRecoilingEnabled; weapon.AngleX_Min=values.AngleX_Min; weapon.AngleX_Max=values.AngleX_Max; weapon.AngleY_Min=values.AngleY_Min; weapon.AngleY_Max=values.AngleY_Max; weapon.AngleZ_Min=values.AngleZ_Min; weapon.AngleZ_Max=values.AngleZ_Max; weapon.Spread=values.Spread
    end
end
function handleWeapon(weapon)
    if NoRecoil_Enabled then task.wait(0.1); cacheWeapons(); applyGunMods() end
end
function onCharacterAdded_nr(character)
    for _, child in ipairs(character:GetChildren()) do if child:IsA("Tool") then handleWeapon(child) end end
    table.insert(NoRecoil_Connections, character.ChildAdded:Connect(function(child) if child:IsA("Tool") then handleWeapon(child) end end))
    local humanoid=character:WaitForChild("Humanoid",2)
    if humanoid then
        table.insert(NoRecoil_Connections, humanoid.Died:Connect(function() if NoRecoil_Enabled then task.wait(1.5); cacheWeapons(); applyGunMods() end end))
    end
end
function NoRecoil_Enable()
    if NoRecoil_Enabled then return end
    NoRecoil_Enabled=true
    cacheWeapons(); applyGunMods()
    table.insert(NoRecoil_Connections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded_nr))
    if LocalPlayer.Character then onCharacterAdded_nr(LocalPlayer.Character) end
end
function NoRecoil_Disable()
    if not NoRecoil_Enabled then return end
    NoRecoil_Enabled=false
    resetGunMods()
    for _, conn in ipairs(NoRecoil_Connections) do conn:Disconnect() end
    NoRecoil_Connections={}
end

local Fly_Enabled = false
local Fly_Connection = nil
local Fly_Speed = 50
function Fly_Enable()
    if Fly_Enabled then return end
    Fly_Enabled = true
    Fly_Connection = RunService.RenderStepped:Connect(function(dt)
        if not Fly_Enabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local cam = Workspace.CurrentCamera
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
            if moveDir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (moveDir.Unit * Fly_Speed * dt)
            end
        end
    end)
end
function Fly_Disable()
    if not Fly_Enabled then return end
    Fly_Enabled = false
    if Fly_Connection then Fly_Connection:Disconnect(); Fly_Connection = nil end
end

local Noclip_Enabled = false
local Noclip_Connection = nil
local originalCollisions = {}
function Noclip_Enable()
    if Noclip_Enabled then return end
    Noclip_Enabled = true
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                originalCollisions[part] = true
                part.CanCollide = false
            end
        end
    end
    if not Noclip_Connection then
        Noclip_Connection = RunService.RenderStepped:Connect(function()
            if not Noclip_Enabled then return end
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end
function Noclip_Disable()
    if not Noclip_Enabled then return end
    Noclip_Enabled = false
    if Noclip_Connection then Noclip_Connection:Disconnect(); Noclip_Connection = nil end
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and originalCollisions[part] then
                part.CanCollide = true
            end
        end
    end
    originalCollisions = {}
end

local isInfiniteStaminaEnabled = false
local oldStaminaFunction = nil
local targetFunction = nil
do
    local success_hook = pcall(function()
        local env = getrenv and getrenv() or getfenv()
        if env and env._G and env._G.S_Take then
            local upval = getupvalue(env._G.S_Take, 2)
            if type(upval) == 'function' then targetFunction = upval end
        end
        if targetFunction then
            oldStaminaFunction = hookfunction(targetFunction, function(v1, ...)
                if isInfiniteStaminaEnabled then
                    return oldStaminaFunction(0, ...)
                else
                    return oldStaminaFunction(v1, ...)
                end
            end)
        end
    end)
end
function InfiniteStamina_Enable()
    if not oldStaminaFunction then return end
    isInfiniteStaminaEnabled = true
end
function InfiniteStamina_Disable()
    isInfiniteStaminaEnabled = false
end

local Nofalldamage_Enabled = false
function Nofalldamage_Enable()
    if Nofalldamage_Enabled then return end
    Nofalldamage_Enabled = true
    if LocalPlayer.Character then
        local ff = Instance.new("ForceField"); ff.Visible=false; ff.Parent=LocalPlayer.Character
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        if Nofalldamage_Enabled and char then
            local ff = Instance.new("ForceField"); ff.Visible=false; ff.Parent=char
        end
    end)
end
function Nofalldamage_Disable()
    if not Nofalldamage_Enabled then return end
    Nofalldamage_Enabled = false
    if LocalPlayer.Character then
        for _, a in pairs(LocalPlayer.Character:GetChildren()) do
            if a:IsA("ForceField") and a.Visible==false then a:Destroy() end
        end
    end
end

local NoBarriers_Enabled = false
function NoBarriers_Enable()
    if NoBarriers_Enabled then return end
    NoBarriers_Enabled = true
    local partsFolder = Workspace.Filter and Workspace.Filter.Parts and Workspace.Filter.Parts["F_Parts"]
    if partsFolder then
        for _, a in pairs(partsFolder:GetDescendants()) do
            if a:IsA("Part") or a:IsA("MeshPart") then a.CanTouch = false end
        end
    end
end
function NoBarriers_Disable()
    if not NoBarriers_Enabled then return end
    NoBarriers_Enabled = false
    local partsFolder = Workspace.Filter and Workspace.Filter.Parts and Workspace.Filter.Parts["F_Parts"]
    if partsFolder then
        for _, a in pairs(partsFolder:GetDescendants()) do
            if a:IsA("Part") or a:IsA("MeshPart") then a.CanTouch = true end
        end
    end
end

local FullBright_Enabled = false
local FullBright_Connection = nil
local OriginalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation,
}
local function SaveOriginalLighting()
    OriginalLighting.ClockTime = Lighting.ClockTime
    OriginalLighting.Brightness = Lighting.Brightness
    OriginalLighting.Ambient = Lighting.Ambient
    OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    OriginalLighting.ColorShift_Top = Lighting.ColorShift_Top
    OriginalLighting.FogStart = Lighting.FogStart
    OriginalLighting.FogEnd = Lighting.FogEnd
    OriginalLighting.ExposureCompensation = Lighting.ExposureCompensation
end

function FullBright_Enable()
    if FullBright_Enabled then return end
    FullBright_Enabled = true
    SaveOriginalLighting()
    Lighting.ClockTime = 14
    Lighting.Brightness = 4
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.ColorShift_Top = Color3.new(0,0,0)
    Lighting.FogStart = 100000
    Lighting.FogEnd = 100000
    Lighting.ExposureCompensation = 0.7

    FullBright_Connection = RunService.RenderStepped:Connect(function()
        if not FullBright_Enabled then
            FullBright_Connection:Disconnect()
            FullBright_Connection = nil
            return
        end
        if Lighting.ClockTime ~= 14 then Lighting.ClockTime = 14 end
        if Lighting.Brightness ~= 4 then Lighting.Brightness = 4 end
        if Lighting.Ambient ~= Color3.new(1,1,1) then Lighting.Ambient = Color3.new(1,1,1) end
        if Lighting.OutdoorAmbient ~= Color3.new(1,1,1) then Lighting.OutdoorAmbient = Color3.new(1,1,1) end
        if Lighting.ColorShift_Top ~= Color3.new(0,0,0) then Lighting.ColorShift_Top = Color3.new(0,0,0) end
        if Lighting.FogStart ~= 100000 then Lighting.FogStart = 100000 end
        if Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
        if Lighting.ExposureCompensation ~= 0.7 then Lighting.ExposureCompensation = 0.7 end
    end)

    local function onPropertyChanged(prop, targetVal)
        if FullBright_Enabled then
            local current = Lighting[prop]
            if current ~= targetVal then
                Lighting[prop] = targetVal
            end
        end
    end
    local connections = {}
    connections[1] = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
        onPropertyChanged("ClockTime", 14)
    end)
    connections[2] = Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
        onPropertyChanged("Brightness", 4)
    end)
    connections[3] = Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
        onPropertyChanged("Ambient", Color3.new(1,1,1))
    end)
    connections[4] = Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
        onPropertyChanged("OutdoorAmbient", Color3.new(1,1,1))
    end)
    connections[5] = Lighting:GetPropertyChangedSignal("ColorShift_Top"):Connect(function()
        onPropertyChanged("ColorShift_Top", Color3.new(0,0,0))
    end)
    connections[6] = Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
        onPropertyChanged("FogStart", 100000)
    end)
    connections[7] = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
        onPropertyChanged("FogEnd", 100000)
    end)
    connections[8] = Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
        onPropertyChanged("ExposureCompensation", 0.7)
    end)
    FullBright_Connection._extraConnections = connections
end

function FullBright_Disable()
    if not FullBright_Enabled then return end
    FullBright_Enabled = false
    if FullBright_Connection then
        if FullBright_Connection._extraConnections then
            for _, conn in ipairs(FullBright_Connection._extraConnections) do
                conn:Disconnect()
            end
        end
        FullBright_Connection:Disconnect()
        FullBright_Connection = nil
    end
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
end

local Fov_Enabled = false
local Fov_Value = 80
local Original_Fov = Camera.FieldOfView
function Fov_Enable()
    Fov_Enabled = true
end
function Fov_Disable()
    Fov_Enabled = false
    Camera.FieldOfView = Original_Fov
end
RunService.RenderStepped:Connect(function()
    if Fov_Enabled then
        Camera.FieldOfView = Fov_Value
    end
end)

local ESP_Enabled = false
local ESP_Data = {}
local ESP_Connections = {}
local ESP_CONFIG = { OutlineColor = Color3.new(1,0,0), TextColor = Color3.new(1,1,1), FontSize = 12, ShowSelf = false }
local function createESPForPlayer(player)
    if player == LocalPlayer and not ESP_CONFIG.ShowSelf then return nil end
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    if not humanoid or not head then return nil end
    if ESP_Data[player] then destroyESPForPlayer(player) end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = ESP_CONFIG.OutlineColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0,120,0,40)
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0,2.5,0)
    billboard.MaxDistance = 0
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,0.5,0)
    nameLabel.Position = UDim2.new(0,0,0,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = ESP_CONFIG.TextColor
    nameLabel.TextSize = ESP_CONFIG.FontSize
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = billboard
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1,0,0.5,0)
    healthLabel.Position = UDim2.new(0,0,0.5,0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth
    healthLabel.TextColor3 = ESP_CONFIG.TextColor
    healthLabel.TextSize = ESP_CONFIG.FontSize
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.Parent = billboard
    local healthConn = humanoid.HealthChanged:Connect(function(newHealth)
        if healthLabel and humanoid then
            healthLabel.Text = math.floor(newHealth) .. "/" .. humanoid.MaxHealth
        end
    end)
    ESP_Data[player] = { Highlight = highlight, Billboard = billboard, NameLabel = nameLabel, HealthLabel = healthLabel, Humanoid = humanoid, HealthChanged = healthConn }
end
local function destroyESPForPlayer(player)
    local data = ESP_Data[player]
    if not data then return end
    if data.HealthChanged then data.HealthChanged:Disconnect() end
    if data.Highlight then data.Highlight:Destroy() end
    if data.Billboard then data.Billboard:Destroy() end
    ESP_Data[player] = nil
end
local function onPlayerAddedForESP(player)
    if player == LocalPlayer and not ESP_CONFIG.ShowSelf then return end
    local charAddedConn = player.CharacterAdded:Connect(function(character)
        if not ESP_Enabled then charAddedConn:Disconnect() return end
        local humanoid = character:WaitForChild("Humanoid",5)
        local head = character:WaitForChild("Head",5)
        if humanoid and head then
            if ESP_Data[player] then destroyESPForPlayer(player) end
            createESPForPlayer(player)
        end
    end)
    ESP_Connections[player] = { CharacterAdded = charAddedConn }
    if player.Character then createESPForPlayer(player) end
end
local function onPlayerRemovingForESP(player)
    if ESP_Connections[player] and ESP_Connections[player].CharacterAdded then
        ESP_Connections[player].CharacterAdded:Disconnect()
    end
    ESP_Connections[player] = nil
    destroyESPForPlayer(player)
end
function ESP_Enable()
    if ESP_Enabled then return end
    ESP_Enabled = true
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer or ESP_CONFIG.ShowSelf then
            onPlayerAddedForESP(player)
        end
    end
    ESP_Connections.PlayerAdded = Players.PlayerAdded:Connect(onPlayerAddedForESP)
    ESP_Connections.PlayerRemoving = Players.PlayerRemoving:Connect(onPlayerRemovingForESP)
    if ESP_CONFIG.ShowSelf then
        ESP_Connections.SelfAdded = LocalPlayer.CharacterAdded:Connect(function(character)
            if not ESP_Enabled then ESP_Connections.SelfAdded:Disconnect() return end
            local humanoid = character:WaitForChild("Humanoid",5)
            local head = character:WaitForChild("Head",5)
            if humanoid and head then
                if ESP_Data[LocalPlayer] then destroyESPForPlayer(LocalPlayer) end
                createESPForPlayer(LocalPlayer)
            end
        end)
        if LocalPlayer.Character then createESPForPlayer(LocalPlayer) end
    end
end
function ESP_Disable()
    if not ESP_Enabled then return end
    ESP_Enabled = false
    if ESP_Connections.PlayerAdded then ESP_Connections.PlayerAdded:Disconnect() end
    if ESP_Connections.PlayerRemoving then ESP_Connections.PlayerRemoving:Disconnect() end
    if ESP_Connections.SelfAdded then ESP_Connections.SelfAdded:Disconnect() end
    for _, conns in pairs(ESP_Connections) do
        if type(conns) == "table" and conns.CharacterAdded then conns.CharacterAdded:Disconnect() end
    end
    ESP_Connections = {}
    for player, _ in pairs(ESP_Data) do destroyESPForPlayer(player) end
    ESP_Data = {}
end

local Invis_Enabled = false
local Invis_Track = nil
local Invis_Animation = Instance.new("Animation")
Invis_Animation.AnimationId = "rbxassetid://215384594"
local Invis_Humanoid = nil
local Invis_HumanoidRootPart = nil
local Invis_Fixed = true
local function Invis_UpdateRefs()
    local char = LocalPlayer.Character
    if char then
        Invis_HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
        Invis_Humanoid = char:FindFirstChildOfClass("Humanoid")
    else
        Invis_HumanoidRootPart = nil
        Invis_Humanoid = nil
    end
end
local function Invis_LoadTrack()
    if Invis_Track then pcall(function() Invis_Track:Stop() end); Invis_Track = nil end
    if Invis_Humanoid then
        local success, track = pcall(function() return Invis_Humanoid:LoadAnimation(Invis_Animation) end)
        if success then Invis_Track = track; Invis_Track.Priority = Enum.AnimationPriority.Action4 end
    end
end
local function Invis_Enable()
    if Invis_Enabled or not Invis_Fixed then return end
    Invis_UpdateRefs()
    if not Invis_Humanoid or not Invis_HumanoidRootPart then return end
    if not LocalPlayer.Character:FindFirstChild("Torso") then
        pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="隐身失败", Text="需要R6角色", Duration=5}) end)
        return
    end
    Invis_Enabled = true
    Workspace.CurrentCamera.CameraSubject = Invis_HumanoidRootPart
    Invis_LoadTrack()
end
local function Invis_Disable()
    if not Invis_Enabled then return end
    Invis_Enabled = false
    if Invis_Track then pcall(function() Invis_Track:Stop() end) end
    if Invis_Humanoid then Workspace.CurrentCamera.CameraSubject = Invis_Humanoid end
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency == 0.5 then part.Transparency = 0 end
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function(char)
    if Invis_Track then pcall(function() Invis_Track:Stop() end); Invis_Track=nil end
    task.wait()
    Invis_UpdateRefs()
    if not Invis_Humanoid then task.wait(0.5); Invis_UpdateRefs() end
    if Invis_Humanoid and Invis_Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        Invis_Fixed = false
        if Invis_Enabled then Invis_Disable() end
        pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="隐身警告", Text="非R6角色，已禁用", Duration=5}) end)
        return
    else
        Invis_Fixed = true
    end
    if Invis_Enabled and Invis_HumanoidRootPart then
        Workspace.CurrentCamera.CameraSubject = Invis_HumanoidRootPart
        Invis_LoadTrack()
    end
end)
LocalPlayer.CharacterRemoving:Connect(function()
    if Invis_Track then pcall(function() Invis_Track:Stop() end); Invis_Track=nil end
end)
RunService.Heartbeat:Connect(function(dt)
    if not Invis_Enabled or not Invis_Fixed then
        if not Invis_Enabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency == 0.5 then part.Transparency = 0 end
            end
        end
        return
    end
    if not LocalPlayer.Character or not Invis_Humanoid or not Invis_HumanoidRootPart or not Invis_Humanoid:IsDescendantOf(Workspace) or Invis_Humanoid.Health <= 0 then return end
    local speed = 12
    if Invis_Humanoid.MoveDirection.Magnitude > 0 then
        local offset = Invis_Humanoid.MoveDirection * speed * dt
        Invis_HumanoidRootPart.CFrame = Invis_HumanoidRootPart.CFrame + offset
    end
    local oldCFrame = Invis_HumanoidRootPart.CFrame
    local oldCamOffset = Invis_Humanoid.CameraOffset
    local _, y = Workspace.CurrentCamera.CFrame:ToOrientation()
    Invis_HumanoidRootPart.CFrame = CFrame.new(Invis_HumanoidRootPart.CFrame.Position) * CFrame.fromOrientation(0, y, 0)
    Invis_HumanoidRootPart.CFrame = Invis_HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
    Invis_Humanoid.CameraOffset = Vector3.new(0, 1.44, 0)
    if Invis_Track then
        local ok = pcall(function()
            if not Invis_Track.IsPlaying then Invis_Track:Play() end
            Invis_Track:AdjustSpeed(0)
            Invis_Track.TimePosition = 0.3
        end)
        if not ok then Invis_LoadTrack() end
    elseif Invis_Humanoid and Invis_Humanoid.Health > 0 then Invis_LoadTrack() end
    RunService.RenderStepped:Wait()
    if Invis_Humanoid and Invis_Humanoid:IsDescendantOf(Workspace) then Invis_Humanoid.CameraOffset = oldCamOffset end
    if Invis_HumanoidRootPart and Invis_HumanoidRootPart:IsDescendantOf(Workspace) then Invis_HumanoidRootPart.CFrame = oldCFrame end
    if Invis_Track then pcall(function() Invis_Track:Stop() end) end
    if Invis_HumanoidRootPart and Invis_HumanoidRootPart:IsDescendantOf(Workspace) then
        local look = Workspace.CurrentCamera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z).Unit
        if flat.Magnitude > 0.1 then
            Invis_HumanoidRootPart.CFrame = CFrame.new(Invis_HumanoidRootPart.Position, Invis_HumanoidRootPart.Position + flat)
        end
    end
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency ~= 1 then part.Transparency = 0.5 end
        end
    end
end)
function Invis_EnableCall() Invis_Enable() end
function Invis_DisableCall() Invis_Disable() end

local BredMakurz_Enabled = false
local bredMakurzConnection = nil
local function formatName(name)
    name = string.gsub(name, "([a-z])([A-Z])", "%1 %2")
    local underscoreIndex = string.find(name, "_")
    if underscoreIndex then name = string.sub(name, 1, underscoreIndex - 1) end
    return name
end
local function ApplyBredMakurzModification()
    local bredMakurzFolder = Workspace.Map:FindFirstChild("BredMakurz")
    if not bredMakurzFolder then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local playerPosition = character.HumanoidRootPart.Position
    for _, v in pairs(bredMakurzFolder:GetChildren()) do
        local objectPosition
        if v.PrimaryPart and v.PrimaryPart:IsA("BasePart") then
            objectPosition = v.PrimaryPart.Position
        else
            local part = v:FindFirstChildOfClass("BasePart")
            if part then objectPosition = part.Position else continue end
        end
        local distance = (objectPosition - playerPosition).magnitude
        local existingGui = v:FindFirstChild("Ahh")
        if distance <= 200 then
            if not existingGui then
                local x = Instance.new('BillboardGui', v)
                x.Name = "Ahh"
                x.AlwaysOnTop = true
                x.Size = UDim2.new(8,0,4,0)
                x.MaxDistance = 200
                local textLabel = Instance.new('TextLabel', x)
                textLabel.Size = UDim2.new(1,0,1,0)
                textLabel.BackgroundTransparency = 1
                textLabel.Font = Enum.Font.SourceSansBold
                textLabel.TextScaled = false
                textLabel.TextSize = 15
                textLabel.Text = formatName(v.Name)
                x.Adornee = v
                local values = v:FindFirstChild("Values")
                local brokenValue = values and values:FindFirstChild("Broken")
                if brokenValue then
                    if brokenValue.Value ~= false then textLabel.TextColor3 = Color3.new(255,0,0) else textLabel.TextColor3 = Color3.new(0,255,0) end
                    brokenValue:GetPropertyChangedSignal("Value"):Connect(function()
                        textLabel.TextColor3 = brokenValue.Value ~= false and Color3.new(255,0,0) or Color3.new(0,255,0)
                    end)
                else
                    textLabel.TextColor3 = Color3.new(0,255,0)
                end
            end
        elseif existingGui then existingGui:Destroy() end
    end
end
function BredMakurz_Enable()
    if BredMakurz_Enabled then return end
    BredMakurz_Enabled = true
    bredMakurzConnection = RunService.Heartbeat:Connect(function() ApplyBredMakurzModification() end)
end
function BredMakurz_Disable()
    if not BredMakurz_Enabled then return end
    BredMakurz_Enabled = false
    if bredMakurzConnection then bredMakurzConnection:Disconnect(); bredMakurzConnection = nil end
    local bredMakurzFolder = Workspace.Map:FindFirstChild("BredMakurz")
    if bredMakurzFolder then
        for _, v in pairs(bredMakurzFolder:GetChildren()) do
            pcall(function() if v:FindFirstChild("Ahh") then v.Ahh:Destroy() end end)
        end
    end
end

local OpenNearbyDoors_Enabled = false
local UnlockNearbyDoors_Enabled = false
local NearbyDoorInteraction_Coroutine = nil
local function NearbyDoorInteraction_Loop()
    while (OpenNearbyDoors_Enabled or UnlockNearbyDoors_Enabled) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then task.wait(0.5) continue end
        local doorsFolder = Workspace.Map:FindFirstChild("Doors")
        if not doorsFolder then
            if OpenNearbyDoors_Enabled then OpenNearbyDoors_Disable() end
            if UnlockNearbyDoors_Enabled then UnlockNearbyDoors_Disable() end
            break
        end
        local playerPos = hrp.Position
        for _, doorInstance in ipairs(doorsFolder:GetChildren()) do
            local doorBase = doorInstance:FindFirstChild("DoorBase")
            local valuesFolder = doorInstance:FindFirstChild("Values")
            local eventsFolder = doorInstance:FindFirstChild("Events")
            if doorBase and valuesFolder and eventsFolder and (playerPos - doorBase.Position).Magnitude <= 6 then
                local toggleEvent = eventsFolder:FindFirstChild("Toggle")
                if not toggleEvent then continue end
                if UnlockNearbyDoors_Enabled then
                    local lockedValue = valuesFolder:FindFirstChild("Locked")
                    local lockArgument = doorInstance:FindFirstChild("Lock")
                    if lockedValue and lockArgument and lockedValue.Value == true then
                        pcall(function() toggleEvent:FireServer("Unlock", lockArgument) end)
                    end
                end
                if OpenNearbyDoors_Enabled then
                    local openValue = valuesFolder:FindFirstChild("Open")
                    local knobArgument = doorInstance:FindFirstChild("Knob2") or doorInstance:FindFirstChild("Knob")
                    if openValue and knobArgument and openValue.Value == false then
                        local isLocked = valuesFolder:FindFirstChild("Locked")
                        if not isLocked or isLocked.Value == false or not UnlockNearbyDoors_Enabled then
                            pcall(function() toggleEvent:FireServer("Open", knobArgument) end)
                        end
                    end
                end
            end
        end
        task.wait(0.25)
    end
    NearbyDoorInteraction_Coroutine = nil
end
local function StartStopDoorInteractionLoop()
    local shouldRun = OpenNearbyDoors_Enabled or UnlockNearbyDoors_Enabled
    if shouldRun and not NearbyDoorInteraction_Coroutine then
        NearbyDoorInteraction_Coroutine = task.spawn(NearbyDoorInteraction_Loop)
    end
end
function OpenNearbyDoors_Enable() if OpenNearbyDoors_Enabled then return end OpenNearbyDoors_Enabled = true StartStopDoorInteractionLoop() end
function OpenNearbyDoors_Disable() if not OpenNearbyDoors_Enabled then return end OpenNearbyDoors_Enabled = false StartStopDoorInteractionLoop() end
function UnlockNearbyDoors_Enable() if UnlockNearbyDoors_Enabled then return end UnlockNearbyDoors_Enabled = true StartStopDoorInteractionLoop() end
function UnlockNearbyDoors_Disable() if not UnlockNearbyDoors_Enabled then return end UnlockNearbyDoors_Enabled = false StartStopDoorInteractionLoop() end

local AutoPickupMoney_Enabled = false
local AutoPickupMoney_Connection = nil
local MoneyCooldown = false
function AutoPickupMoney_Enable()
    if AutoPickupMoney_Enabled then return end
    AutoPickupMoney_Enabled = true
    local cashFolder = Workspace.Filter:FindFirstChild("SpawnedBread")
    local remoteEvent = ReplicatedStorage.Events:FindFirstChild("CZDPZUS")
    if not cashFolder or not remoteEvent then return end
    AutoPickupMoney_Connection = RunService.RenderStepped:Connect(function()
        if not AutoPickupMoney_Enabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or MoneyCooldown then return end
        local rootPosition = hrp.Position
        for _, v in ipairs(cashFolder:GetChildren()) do
            if (rootPosition - v.Position).Magnitude < 5 and not MoneyCooldown then
                MoneyCooldown = true
                pcall(function() remoteEvent:FireServer(v) end)
                task.wait(1)
                MoneyCooldown = false
                break
            end
        end
    end)
end
function AutoPickupMoney_Disable()
    if not AutoPickupMoney_Enabled then return end
    AutoPickupMoney_Enabled = false
    if AutoPickupMoney_Connection then AutoPickupMoney_Connection:Disconnect(); AutoPickupMoney_Connection = nil end
    MoneyCooldown = false
end

local AutoPickupScraps_Enabled = false
local AutoPickupScraps_Run = nil
function AutoPickupScraps_Enable()
    if AutoPickupScraps_Enabled then return end
    AutoPickupScraps_Enabled = true
    local remote = ReplicatedStorage.Events.PIC_PU
    local scrapsfolder = Workspace.Filter.SpawnedPiles
    local canPickup = true; local startTick = tick()
    AutoPickupScraps_Run = RunService.RenderStepped:Connect(function()
        if not AutoPickupScraps_Enabled then return end
        local function GetClosestScrap()
            local maxdist = 15; local closest = nil
            for _, a in pairs(scrapsfolder:GetChildren()) do
                if a and (a.Name=="S1" or a.Name=="S2") and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - a.MeshPart.Position).Magnitude
                    if dist < maxdist then maxdist=dist; closest=a end
                end
            end
            return closest
        end
        local scrap = GetClosestScrap()
        if scrap and canPickup then
            remote:FireServer(string.reverse(scrap:GetAttribute("jzu")))
            canPickup = false
        end
        if not canPickup and tick()-startTick >= 4.5 then canPickup=true; startTick=tick() end
    end)
end
function AutoPickupScraps_Disable()
    if not AutoPickupScraps_Enabled then return end
    AutoPickupScraps_Enabled = false
    if AutoPickupScraps_Run then AutoPickupScraps_Run:Disconnect(); AutoPickupScraps_Run=nil end
end

local AutoPickupTools_Enabled = false
local AutoPickupTools_Run = nil
function AutoPickupTools_Enable()
    if AutoPickupTools_Enabled then return end
    AutoPickupTools_Enabled = true
    local remote = ReplicatedStorage.Events.PIC_TLO
    local toolsfolder = Workspace.Filter.SpawnedTools
    local canPickup = true; local startTick = tick()
    AutoPickupTools_Run = RunService.RenderStepped:Connect(function()
        if not AutoPickupTools_Enabled then return end
        local function GetClosestTool()
            local maxdist = 15; local closest = nil
            for _, a in pairs(toolsfolder:GetChildren()) do
                if a then
                    local handle = a:FindFirstChild("Handle") or a:FindFirstChild("WeaponHandle")
                    if handle and (handle:IsA("Part") or handle:IsA("MeshPart")) and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - handle.Position).Magnitude
                        if dist < maxdist then maxdist=dist; closest=a end
                    end
                end
            end
            return closest
        end
        local tool = GetClosestTool()
        if tool and canPickup then
            local Handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("WeaponHandle")
            if Handle then remote:FireServer(Handle); canPickup=false end
        end
        if not canPickup and tick()-startTick >= 1.5 then canPickup=true; startTick=tick() end
    end)
end
function AutoPickupTools_Disable()
    if not AutoPickupTools_Enabled then return end
    AutoPickupTools_Enabled = false
    if AutoPickupTools_Run then AutoPickupTools_Run:Disconnect(); AutoPickupTools_Run=nil end
end

local FastPickup_Enabled = false
function FastPickup_Enable()
    if FastPickup_Enabled then return end
    FastPickup_Enabled = true
    game.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then
            obj.HoldDuration = 0
            obj:GetPropertyChangedSignal("HoldDuration"):Connect(function()
                if FastPickup_Enabled then obj.HoldDuration = 0 end
            end)
        end
    end)
end
function FastPickup_Disable()
    FastPickup_Enabled = false
end

local NoFailLockpick_Enabled = false
local lockpickAddedConnection = nil
function NoFailLockpick_Enable()
    if NoFailLockpick_Enabled then return end
    NoFailLockpick_Enabled = true
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    lockpickAddedConnection = PlayerGui.ChildAdded:Connect(function(Item)
        if Item.Name == "LockpickGUI" then
            local mf = Item:WaitForChild("MF", 10)
            if not mf then return end
            local lpFrame = mf:WaitForChild("LP_Frame", 10)
            if not lpFrame then return end
            local frames = lpFrame:WaitForChild("Frames", 10)
            if not frames then return end
            local b1 = frames:WaitForChild("B1", 10)
            local b2 = frames:WaitForChild("B2", 10)
            local b3 = frames:WaitForChild("B3", 10)
            if b1 and b1.Bar and b1.Bar:FindFirstChild("UIScale") then b1.Bar.UIScale.Scale = 10 end
            if b2 and b2.Bar and b2.Bar:FindFirstChild("UIScale") then b2.Bar.UIScale.Scale = 10 end
            if b3 and b3.Bar and b3.Bar:FindFirstChild("UIScale") then b3.Bar.UIScale.Scale = 10 end
        end
    end)
end
function NoFailLockpick_Disable()
    if not NoFailLockpick_Enabled then return end
    NoFailLockpick_Enabled = false
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    if lockpickAddedConnection then lockpickAddedConnection:Disconnect(); lockpickAddedConnection = nil end
    local lockpickGui = PlayerGui:FindFirstChild("LockpickGUI")
    if lockpickGui then
        local frames = lockpickGui:FindFirstChild("MF")
        if frames then
            local lpFrame = frames:FindFirstChild("LP_Frame")
            if lpFrame then
                local bars = lpFrame:FindFirstChild("Frames")
                if bars then
                    if bars.B1 and bars.B1.Bar and bars.B1.Bar:FindFirstChild("UIScale") then bars.B1.Bar.UIScale.Scale = 1 end
                    if bars.B2 and bars.B2.Bar and bars.B2.Bar:FindFirstChild("UIScale") then bars.B2.Bar.UIScale.Scale = 1 end
                    if bars.B3 and bars.B3.Bar and bars.B3.Bar:FindFirstChild("UIScale") then bars.B3.Bar.UIScale.Scale = 1 end
                end
            end
        end
    end
end

local FakeDown_Enabled = false
function FakeDown_Enable()
    if FakeDown_Enabled then return end
    FakeDown_Enabled = true
    local function setDown()
        local stats = ReplicatedStorage:FindFirstChild("CharStats")
        if stats and stats[LocalPlayer.Name] and stats[LocalPlayer.Name]:FindFirstChild("Downed") then
            local down = stats[LocalPlayer.Name].Downed
            down.Value = true
            down:GetPropertyChangedSignal("Value"):Connect(function()
                if FakeDown_Enabled then down.Value = true end
            end)
        end
    end
    setDown()
    LocalPlayer.CharacterAdded:Connect(setDown)
end
function FakeDown_Disable()
    if not FakeDown_Enabled then return end
    FakeDown_Enabled = false
    local stats = ReplicatedStorage:FindFirstChild("CharStats")
    if stats and stats[LocalPlayer.Name] and stats[LocalPlayer.Name]:FindFirstChild("Downed") then
        stats[LocalPlayer.Name].Downed.Value = false
    end
end

local Stopneckmove_Enabled = false
function Stopneckmove_Enable()
    if Stopneckmove_Enabled then return end
    Stopneckmove_Enabled = true
    if LocalPlayer.Character then LocalPlayer.Character:SetAttribute("NoNeckMovement", true) end
    LocalPlayer.CharacterAdded:Connect(function(char)
        if Stopneckmove_Enabled and char then char:SetAttribute("NoNeckMovement", true) end
    end)
end
function Stopneckmove_Disable()
    if not Stopneckmove_Enabled then return end
    Stopneckmove_Enabled = false
    if LocalPlayer.Character then
        local attr = LocalPlayer.Character:GetAttribute("NoNeckMovement")
        if attr then LocalPlayer.Character:SetAttribute("NoNeckMovement", nil) end
    end
end

local Unbreaklimbs_Enabled = false
function Unbreaklimbs_Enable()
    if Unbreaklimbs_Enabled then return end
    Unbreaklimbs_Enabled = true
    local function fixLimbs()
        local stats = ReplicatedStorage:FindFirstChild("CharStats")
        if not stats or not stats[LocalPlayer.Name] then return end
        local limbs = stats[LocalPlayer.Name]:FindFirstChild("HealthValues")
        if not limbs then return end
        for _, part in pairs(limbs:GetChildren()) do
            for _, child in pairs(part:GetChildren()) do
                if child.Name == "Broken" then
                    child.Value = false
                    child:GetPropertyChangedSignal("Value"):Connect(function()
                        if Unbreaklimbs_Enabled then child.Value = false end
                    end)
                end
            end
        end
        limbs.ChildAdded:Connect(function(newPart)
            if Unbreaklimbs_Enabled then
                for _, child in pairs(newPart:GetChildren()) do
                    if child.Name == "Broken" then
                        child.Value = false
                        child:GetPropertyChangedSignal("Value"):Connect(function()
                            if Unbreaklimbs_Enabled then child.Value = false end
                        end)
                    end
                end
            end
        end)
    end
    fixLimbs()
    LocalPlayer.CharacterAdded:Connect(fixLimbs)
end
function Unbreaklimbs_Disable()
    Unbreaklimbs_Enabled = false
end

local Instantreload_Enabled = false
function Instantreload_Enable()
    if Instantreload_Enabled then return end
    Instantreload_Enabled = true
    local gunR_remote = ReplicatedStorage.Events.GNX_R
    local function handleTool(tool)
        if tool and tool:FindFirstChild("IsGun") then
            local values = tool:FindFirstChild("Values")
            if values then
                local ammo = values:FindFirstChild("SERVER_Ammo")
                local stored = values:FindFirstChild("SERVER_StoredAmmo")
                if ammo and stored then
                    stored:GetPropertyChangedSignal("Value"):Connect(function()
                        if Instantreload_Enabled then gunR_remote:FireServer(tick(), "KLWE89U0", tool) end
                    end)
                    ammo:GetPropertyChangedSignal("Value"):Connect(function()
                        if Instantreload_Enabled and stored.Value ~= 0 then gunR_remote:FireServer(tick(), "KLWE89U0", tool) end
                    end)
                    if stored.Value ~= 0 then gunR_remote:FireServer(tick(), "KLWE89U0", tool) end
                end
            end
        end
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        if Instantreload_Enabled and char then
            char.ChildAdded:Connect(function(obj)
                if obj:IsA("Tool") then handleTool(obj) end
            end)
            for _, child in pairs(char:GetChildren()) do if child:IsA("Tool") then handleTool(child) end end
        end
    end)
    if LocalPlayer.Character then
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do if child:IsA("Tool") then handleTool(child) end end
    end
end
function Instantreload_Disable()
    Instantreload_Enabled = false
end

local AdminCheck_Enabled = false
local AdminCheck_Connection = nil
local staffPlayers = {
    groups = {
        [4165692] = {Tester=true, Contributor=true, ["Tester+"]=true, Developer=true, ["Developer+"]=true, ["Community Manager"]=true, Manager=true, Owner=true},
        [32406137] = {Junior=true, Moderator=true, Senior=true, Administrator=true, Manager=true, Holder=true},
        [8024440] = {zzzz=true, ["reshape enjoyer"]=true, ["i heart reshape"]=true, ["reshape superfan"]=true},
        [14927228] = {["♞"]=true}
    },
    users = {3294804378,93676120,54087314,81275825,140837601,1229486091,46567801,418086275,29706395,3717066084,1424338327,5046662686,5046661126,5046659439,418199326,1024216621,1810535041,63238912,111250044,63315426,730176906,141193516,194512073,193945439,412741116,195538733,102045519,955294,957835150,25689921,366613818,281593651,455275714,208929505,96783330,156152502,93281166,959606619,142821118,632886139,175931803,122209625,278097946,142989311,1517131734,446849296,87189764,67180844,9212846,47352513,48058122,155413858,10497435,513615792,55893752,55476024,151691292,136584758,16983447,3111449,94693025,271400893,5005262660,295331237,64489098,244844600,114332275,25048901,69262878,50801509,92504899,42066711,50585425,31365111,166406495,2457253857,29761878,21831137,948293345,439942262,38578487,1163048,7713309208,3659305297,15598614,34616594,626833004,198610386,153835477,3923114296,3937697838,102146039,119861460,371665775,1206543842,93428604,1863173316,90814576,374665997,423005063,140172831,42662179,9066859,438805620,14855669,727189337,1871290386,608073286}
}
local function hasTracker(player)
    if not player then return false end
    for _, child in pairs(player:GetChildren()) do
        if typeof(child.Name)=="string" and string.sub(child.Name,-8)=="Tracker$" then
            local tracked = string.sub(child.Name,1,-9)
            if Players:FindFirstChild(tracked) then return true, tracked end
        end
    end
    return false
end
local function isStaff(player)
    if not player then return false end
    for groupID, roles in pairs(staffPlayers.groups) do
        local rank = pcall(player.GetRankInGroup, player, groupID)
        if rank and rank > 0 then
            local role = pcall(player.GetRoleInGroup, player, groupID)
            if role and roles[role] then return true, role, groupID end
        end
    end
    for _, id in pairs(staffPlayers.users) do
        if player.UserId == id then return true, "UserID", id end
    end
    return false
end
local function kickformat(staffInfo)
    local msg = "检测到管理员：\n"
    for i, staff in ipairs(staffInfo.Staff) do
        local idType = staff.Role == "UserID" and "用户ID" or "身份"
        local idValue = staff.Role == "UserID" and staff.GroupId or staff.Role or "未知"
        msg = msg .. string.format("- %s (%s: %s)%s", staff.Name or "未知", idType, idValue, staff.TrackedPlayer and " - 追踪: "..staff.TrackedPlayer or "")
        if i < #staffInfo.Staff then msg = msg .. "\n" end
    end
    return msg
end
local function kickWithStaffInfo(info) if LocalPlayer then LocalPlayer:Kick("管理员加入\n\n"..kickformat(info)) end end
local function checkCurrentStaff()
    local found = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local is, role, gid = isStaff(p)
            local has, tracked = hasTracker(p)
            if is or has then
                table.insert(found, {Name=p.Name, Role=has and "Tracker User" or role, GroupId=gid, TrackedPlayer=tracked})
            end
        end
    end
    if #found > 0 then kickWithStaffInfo({Staff=found}) return true end
    return false
end
local function onPlayerJoining(player)
    if not AdminCheck_Enabled then return end
    local is, role, gid = isStaff(player)
    local has, tracked = hasTracker(player)
    if is or has then
        kickWithStaffInfo({Staff={{Name=player.Name, Role=has and "Tracker User" or role, GroupId=gid, TrackedPlayer=tracked}}})
    end
end
function AdminCheck_Enable()
    if AdminCheck_Enabled then return end
    AdminCheck_Enabled = true
    if AdminCheck_Connection then AdminCheck_Connection:Disconnect() end
    AdminCheck_Connection = Players.PlayerAdded:Connect(onPlayerJoining)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="管理员检测", Text="监控已激活", Duration=5}) end)
    task.spawn(function()
        local found = checkCurrentStaff()
        if found then AdminCheck_Enabled = false; if AdminCheck_Connection then AdminCheck_Connection:Disconnect(); AdminCheck_Connection=nil end end
    end)
end
function AdminCheck_Disable()
    if not AdminCheck_Enabled then return end
    AdminCheck_Enabled = false
    if AdminCheck_Connection then AdminCheck_Connection:Disconnect(); AdminCheck_Connection = nil end
end

local RageLogGui = Instance.new("ScreenGui")
RageLogGui.Name = "RageHitLogs"
RageLogGui.ResetOnSpawn = false
RageLogGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local activeLogs = {}

local function showHitNotify(targetName, damage, hitPart, targetHumanoid, hitPosition, tool)
    if not RageSettings.HitNotifyEnabled then return end
    local distance = math.floor((Camera.CFrame.Position - hitPosition).Magnitude)
    local hp = targetHumanoid and tostring(math.floor(targetHumanoid.Health)) or "?"
    local weapon = tool and tool.Name or "Unknown"
    local box = Instance.new("Frame")
    box.Parent = RageLogGui
    box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    box.BackgroundTransparency = 0.3
    box.BorderSizePixel = 0

    local parts = {
        {"Hit target: ", Color3.fromRGB(255,255,255)},
        {targetName.." ", NewFeatures.HitNotifyColor},
        {"["..weapon.."] ", Color3.fromRGB(255,255,255)},
        {"HP:", Color3.fromRGB(255,255,255)},
        {hp.." ", NewFeatures.HitNotifyColor},
        {"Dist:"..distance, Color3.fromRGB(255,255,255)}
    }
    local offsetX = 6
    local totalW, maxH = 0, 0
    for _, seg in ipairs(parts) do
        local txt, col = seg[1], seg[2]
        local label = Instance.new("TextLabel")
        label.Parent = box
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.TextColor3 = col
        label.FontFace = Font.new("rbxassetid://12187371840")
        label.TextSize = 20
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = txt
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.Position = UDim2.new(0, offsetX, 0, 0)
        offsetX = offsetX + label.TextBounds.X
        totalW = offsetX
        maxH = math.max(maxH, label.TextBounds.Y)
    end
    box.Size = UDim2.new(0, totalW + 12, 0, maxH + 8)
    table.insert(activeLogs, box)
    for i, l in ipairs(activeLogs) do
        l.Position = UDim2.new(0, 10, 0, 40 + (i - 1) * (l.AbsoluteSize.Y + 5))
    end
    task.delay(RageSettings.HitNotifyDuration or 3, function()
        for i, l in ipairs(activeLogs) do
            if l == box then table.remove(activeLogs, i); break end
        end
        if box then box:Destroy() end
        for i, l in ipairs(activeLogs) do
            l.Position = UDim2.new(0, 10, 0, 40 + (i - 1) * (l.AbsoluteSize.Y + 5))
        end
    end)
end

local function RandomString(length)
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = ""
    for i = 1, length do
        result = result .. charset:sub(math.random(1, #charset), math.random(1, #charset))
    end
    return result
end

local function canSeeTarget(targetPart)
    if not RageSettings.VisibilityCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local startPos = Camera.CFrame.Position
    local endPos = targetPart.Position
    local direction = (endPos - startPos)
    local distance = direction.Magnitude
    local raycastResult = workspace:Raycast(startPos, direction.Unit * distance, raycastParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart.CanCollide then
            local model = hitPart:FindFirstAncestorOfClass("Model")
            if model then
                local humanoid = model:FindFirstChild("Humanoid")
                if humanoid then return true end
            end
            return false
        end
    end
    return true
end

local function isPlayerDowned(player)
    if not RageSettings.DownedCheck then return false end
    if not player.Character then return true end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return true end
    return humanoid.Health <= 0
end

local function getClosestRage()
    local closest = nil
    local shortest = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and not isPlayerDowned(p) then
            local h = p.Character:FindFirstChild("Humanoid")
            local head = p.Character:FindFirstChild("Head")
            if h and h.Health > 0 and head and canSeeTarget(head) then
                if not RageSettings.NoFovLimit and RageSettings.FovEnabled then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                        if dist > RageSettings.FovRadius then continue end
                    else continue end
                end
                local dist = (head.Position - Camera.CFrame.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

local function playHitSound()
    if RageSettings.HitSoundType == "Weapon" then
        if LocalPlayer.Character then
            for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, child in ipairs(tool:GetDescendants()) do
                        if child:IsA("Sound") and child.Name == "FireSound1" then
                            local soundClone = child:Clone()
                            soundClone.Parent = Camera
                            soundClone:Play()
                            game:GetService("Debris"):AddItem(soundClone, soundClone.TimeLength)
                            return
                        end
                    end
                end
            end
        end
    elseif RageSettings.HitSoundType == "Custom" then
        local sound = Instance.new("Sound")
        sound.SoundId = RageSettings.CustomHitSoundId
        sound.Volume = 1
        sound.PlayOnRemove = true
        sound.Parent = Camera
        sound:Destroy()
    else
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://6534948092"
        sound.Volume = 1
        sound.PlayOnRemove = true
        sound.Parent = Camera
        sound:Destroy()
    end
end

local function getCurrentTool()
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then return tool end
        end
    end
    return nil
end

local GNX_S = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("GNX_S")
local ZFKLF__H = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ZFKLF__H")

local function shootRage(head)
    local tool = getCurrentTool()
    if not tool then return end
    local values = tool:FindFirstChild("Values")
    local hitMarker = tool:FindFirstChild("Hitmarker")
    if not values or not hitMarker then return end
    local ammo = values:FindFirstChild("SERVER_Ammo")
    local storedAmmo = values:FindFirstChild("SERVER_StoredAmmo")
    if not ammo or not storedAmmo then return end
    if ammo.Value <= 0 then return end

    local hitPosition = head.Position
    if RageSettings.Prediction then
        local velocity = head.Velocity or Vector3.zero
        hitPosition = hitPosition + velocity * RageSettings.PredictionAmount
    end
    local shootPosition = Camera.CFrame.Position
    local hitDirection = (hitPosition - shootPosition).Unit
    local randomKey = RandomString(30) .. "0"
    if GNX_S and ZFKLF__H then
        local args1 = {tick(), randomKey, tool, "FDS9I83", shootPosition, {hitDirection}, false}
        local args2 = {"🧈", tool, randomKey, 1, head, hitPosition, hitDirection}
        GNX_S:FireServer(unpack(args1))
        ZFKLF__H:FireServer(unpack(args2))
    end
    ammo.Value = math.max(ammo.Value - 1, 0)
    hitMarker:Fire(head)
    playHitSound()
    local player = Players:GetPlayerFromCharacter(head.Parent)
    if player then
        local humanoid = head.Parent:FindFirstChildOfClass("Humanoid")
        showHitNotify(player.Name, 1, head, humanoid, hitPosition, tool)
    end
end

task.spawn(function()
    while true do
        local waitTime = RageSettings.NoFireRateLimit and 0 or (1 / RageSettings.FireRate)
        task.wait(waitTime)
        if RageSettings.Enabled and tick() - RageSettings.LastShot >= waitTime then
            local target = getClosestRage()
            if target then
                shootRage(target)
                RageSettings.LastShot = tick()
            end
        end
    end
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Thickness = 1
fovCircle.Transparency = 1
fovCircle.Filled = false
local function updateFovCircle()
    if RageSettings.FovEnabled then
        fovCircle.Radius = RageSettings.FovRadius
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end
updateFovCircle()
RunService.RenderStepped:Connect(function()
    if RageSettings.FovEnabled then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = RageSettings.FovRadius
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

local function FindLockpickObject()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "LockpickObject" or obj:FindFirstChild("LockpickGUI") then
            return obj
        end
    end
    return nil
end

local function IsNearLockpick()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    local obj = FindLockpickObject()
    if not obj then return false end
    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude
    return dist <= 10
end

local function GetLockpickCompleteFunc()
    for i, v in getgc() do
        if type(v) == "function" and debug.info(v, "n") == "Complete" then
            return v
        end
    end
    return nil
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if NewFeatures.AutoLockpick then
            if IsNearLockpick() and not LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI") then
                local obj = FindLockpickObject()
                if obj and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                    task.wait(0.1)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                    task.wait(0.2)
                    local timeout = tick() + 3
                    while tick() < timeout do
                        if LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI") then
                            task.wait(0.15)
                            local complete = GetLockpickCompleteFunc()
                            if complete then complete() end
                            break
                        end
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "LockpickGUI" and NewFeatures.AutoLockpick then
        task.wait(0.15)
        local complete = GetLockpickCompleteFunc()
        if complete then complete() end
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "X6G1_Hub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 400)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5,0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,20)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = true
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Parent = screenGui
local cornerMain = Instance.new("UICorner"); cornerMain.CornerRadius = UDim.new(0,12); cornerMain.Parent = mainFrame
local strokeMain = Instance.new("UIStroke"); strokeMain.Color = Color3.fromRGB(60,60,75); strokeMain.Thickness = 1; strokeMain.Transparency = 0.5; strokeMain.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 20, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "X6G1 Hub 2.0"
titleLabel.Font = Enum.Font.GothamSemibold
titleLabel.TextColor3 = Color3.fromRGB(220,220,220)
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local line = Instance.new("Frame")
line.Size = UDim2.new(1, -40, 0, 1)
line.Position = UDim2.new(0, 20, 0, 40)
line.BackgroundColor3 = Color3.fromRGB(60,60,75)
line.BorderSizePixel = 0
line.Parent = mainFrame

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -20, 0, 20)
footer.Position = UDim2.new(0, 10, 1, -25)
footer.BackgroundTransparency = 1
footer.Text = "按 Ins 切换 | X6G1"
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextColor3 = Color3.fromRGB(100,100,120)
footer.TextXAlignment = Enum.TextXAlignment.Right
footer.Parent = mainFrame

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, -70)
sidebar.Position = UDim2.new(0, 10, 0, 50)
sidebar.BackgroundColor3 = Color3.fromRGB(20,20,25)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
local sideCorner = Instance.new("UICorner"); sideCorner.CornerRadius = UDim.new(0,8); sideCorner.Parent = sidebar
local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 5)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidebar

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -150, 1, -70)
content.Position = UDim2.new(0, 140, 0, 50)
content.BackgroundColor3 = Color3.fromRGB(20,20,25)
content.BorderSizePixel = 0
content.ScrollingDirection = Enum.ScrollingDirection.Y
content.ScrollBarThickness = 6
content.ScrollBarImageColor3 = Color3.fromRGB(60,60,75)
content.CanvasSize = UDim2.new(0,0,0,0)
content.Parent = mainFrame
local contentCorner = Instance.new("UICorner"); contentCorner.CornerRadius = UDim.new(0,8); contentCorner.Parent = content
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.Parent = content
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
end)

do
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local absPos = mainFrame.AbsolutePosition
            if input.Position.Y < absPos.Y + 45 and input.Position.Y > absPos.Y and input.Position.X > absPos.X and input.Position.X < absPos.X + mainFrame.AbsoluteSize.X then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

local activeBinds = {}
local currentRowWaitingForKey = nil
local bindButtonRefs = {}
local keyGetters = {}
local keySetters = {}
local toggleData = {}

local function createToggleRow(text, canToggle, isEnabledFn, onEnable, onDisable, getKeyFn, setKeyFn)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,5)
    layout.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = " " .. text
    label.TextColor3 = Color3.fromRGB(210,210,210)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.25,0,0.8,0)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(25,25,30)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.AutoButtonColor = false
    toggleBtn.LayoutOrder = 2
    toggleBtn.Parent = frame
    local cornerBtn = Instance.new("UICorner"); cornerBtn.CornerRadius = UDim.new(0,6); cornerBtn.Parent = toggleBtn
    local strokeBtn = Instance.new("UIStroke"); strokeBtn.Color = Color3.fromRGB(60,60,75); strokeBtn.Thickness = 1; strokeBtn.Parent = toggleBtn

    local function updateToggleVisuals()
        local enabled = false
        if type(isEnabledFn) == "function" then
            local s, r = pcall(isEnabledFn)
            if s then enabled = r end
        end
        if not canToggle then
            toggleBtn.Text = "运行"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80,120,220)
        elseif enabled then
            toggleBtn.Text = "开"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,180,100)
        else
            toggleBtn.Text = "关"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200,80,80)
        end
    end

    toggleData[frame] = {
        isEnabledFn = isEnabledFn,
        onEnable = onEnable,
        onDisable = onDisable,
        canToggle = canToggle,
        updateFn = updateToggleVisuals,
        toggleBtn = toggleBtn
    }

    local bindBtn = nil
    if getKeyFn and setKeyFn then
        bindBtn = Instance.new("TextButton")
        bindBtn.Size = UDim2.new(0.25,0,0.8,0)
        bindBtn.Font = Enum.Font.GothamMedium
        bindBtn.TextSize = 12
        bindBtn.TextColor3 = Color3.fromRGB(210,210,210)
        bindBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
        bindBtn.BorderSizePixel = 0
        bindBtn.AutoButtonColor = false
        bindBtn.LayoutOrder = 3
        bindBtn.Parent = frame
        local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(0,6); corner2.Parent = bindBtn
        local stroke2 = Instance.new("UIStroke"); stroke2.Color = Color3.fromRGB(60,60,75); stroke2.Thickness = 1; stroke2.Parent = bindBtn

        bindButtonRefs[frame] = bindBtn
        keyGetters[frame] = getKeyFn
        keySetters[frame] = setKeyFn

        local function updateBindText()
            local kb = nil
            if type(getKeyFn) == "function" then
                local s, r = pcall(getKeyFn)
                if s then kb = r end
            end
            bindBtn.Text = kb and typeof(kb)=="EnumItem" and "["..kb.Name.."]" or "绑定"
        end
        updateBindText()

        local capturing = false
        bindBtn.MouseButton1Click:Connect(function()
            if currentRowWaitingForKey and currentRowWaitingForKey ~= frame then
                local prevBtn = bindButtonRefs[currentRowWaitingForKey]
                if prevBtn then
                    local getter = keyGetters[currentRowWaitingForKey]
                    local txt = "绑定"
                    if getter then
                        local s,r = pcall(getter)
                        if s and r and typeof(r)=="EnumItem" then txt = "["..r.Name.."]" end
                    end
                    prevBtn.Text = txt
                end
            end
            if capturing then
                capturing = false
                updateBindText()
                currentRowWaitingForKey = nil
            else
                capturing = true
                bindBtn.Text = "..."
                currentRowWaitingForKey = frame
                task.delay(5, function()
                    if capturing and currentRowWaitingForKey == frame then
                        capturing = false
                        updateBindText()
                        currentRowWaitingForKey = nil
                    end
                end)
            end
        end)

        bindBtn.MouseEnter:Connect(function()
            TweenService:Create(bindBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,60,75)}):Play()
        end)
        bindBtn.MouseLeave:Connect(function()
            TweenService:Create(bindBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45,45,55)}):Play()
        end)
    else
        toggleBtn.Size = UDim2.new(0.5,0,0.8,0)
        layout.Padding = UDim.new(0,10)
    end

    toggleBtn.MouseEnter:Connect(function()
        local color = toggleBtn.BackgroundColor3
        TweenService:Create(toggleBtn, TweenInfo.new(0.1), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1),0.2)}):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        updateToggleVisuals()
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local enabled = false
            if type(isEnabledFn) == "function" then
                local s, r = pcall(isEnabledFn)
                if s then enabled = r end
            end
            if not canToggle then
                if type(onEnable) == "function" then pcall(onEnable) end
                toggleBtn.Text = "完成"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(80,120,220)
                toggleBtn.Active = false
                if bindBtn then bindBtn.Active = false end
                return
            end
            if enabled then
                if type(onDisable) == "function" then pcall(onDisable) end
            else
                if type(onEnable) == "function" then pcall(onEnable) end
            end
            updateToggleVisuals()
        end)
    end)

    updateToggleVisuals()
    return frame
end

local function createSliderRow(text, min, max, defaultValue, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,5)
    layout.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = " " .. text
    label.TextColor3 = Color3.fromRGB(210,210,210)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1
    label.Parent = frame

    local sliderContainer = Instance.new("Frame")
    sliderContainer.Size = UDim2.new(0.4,0,0.8,0)
    sliderContainer.BackgroundColor3 = Color3.fromRGB(40,40,50)
    sliderContainer.BorderSizePixel = 0
    sliderContainer.LayoutOrder = 2
    sliderContainer.Parent = frame
    local cornerS = Instance.new("UICorner"); cornerS.CornerRadius = UDim.new(8,8); cornerS.Parent = sliderContainer
    local strokeS = Instance.new("UIStroke"); strokeS.Color = Color3.fromRGB(60,60,75); strokeS.Thickness = 1; strokeS.Parent = sliderContainer

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0.5,0,1,0)
    slider.BackgroundColor3 = Color3.fromRGB(70,180,100)
    slider.BorderSizePixel = 0
    slider.Text = ""
    slider.Parent = sliderContainer
    local cornerSlider = Instance.new("UICorner"); cornerSlider.CornerRadius = UDim.new(8,8); cornerSlider.Parent = slider

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.15,0,1,0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(210,210,210)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextSize = 12
    valueLabel.LayoutOrder = 3
    valueLabel.Parent = frame

    local function updateSlider(val)
        pcall(function()
            local clamped = math.clamp(val, min, max)
            local scale = (clamped - min) / (max - min)
            slider.Size = UDim2.new(math.clamp(scale, 0.1, 1), 0, 1, 0)
            if clamped < 10 then
                valueLabel.Text = string.format("%.2f", clamped)
            else
                valueLabel.Text = math.floor(clamped)
            end
            if type(setter) == "function" then
                setter(clamped)
            end
        end)
    end
    updateSlider(defaultValue)

    local slide = false
    slider.MouseButton1Down:Connect(function() slide = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then slide = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and slide then
            pcall(function()
                local mouseX = input.Position.X
                local absX = sliderContainer.AbsolutePosition.X
                local width = sliderContainer.AbsoluteSize.X
                if width > 0 then
                    local scale = (mouseX - absX) / width
                    local val = min + math.clamp(scale, 0, 1) * (max - min)
                    updateSlider(val)
                end
            end)
        end
    end)
    return frame
end

local function createCheckboxRow(text, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,5)
    layout.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = " " .. text
    label.TextColor3 = Color3.fromRGB(200,200,200)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1
    label.Parent = frame

    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0,25,0,25)
    checkBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    checkBtn.BorderSizePixel = 0
    checkBtn.Text = ""
    checkBtn.TextColor3 = Color3.fromRGB(255,255,255)
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.TextSize = 18
    checkBtn.LayoutOrder = 2
    checkBtn.Parent = frame
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,4); corner.Parent = checkBtn
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(80,80,90); stroke.Thickness = 1; stroke.Parent = checkBtn

    local function updateCheck()
        pcall(function()
            local val = false
            if type(getter) == "function" then
                local s, r = pcall(getter)
                if s then val = r end
            end
            if val then
                checkBtn.Text = "✔"
                checkBtn.BackgroundColor3 = Color3.fromRGB(70,180,100)
            else
                checkBtn.Text = ""
                checkBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
            end
        end)
    end
    updateCheck()
    checkBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local val = false
            if type(getter) == "function" then
                local s, r = pcall(getter)
                if s then val = r end
            end
            if type(setter) == "function" then
                pcall(setter, not val)
            end
            updateCheck()
        end)
    end)
    return frame
end

local function createBodySelectorButton(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,5)
    layout.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = " " .. text
    label.TextColor3 = Color3.fromRGB(200,200,200)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = 1
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,30,0,25)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,70)
    btn.Text = "⚙"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.BorderSizePixel = 0
    btn.LayoutOrder = 2
    btn.Parent = frame
    local cornerB = Instance.new("UICorner"); cornerB.CornerRadius = UDim.new(0,6); cornerB.Parent = btn
    btn.MouseButton1Click:Connect(CreateBodySelector)
    return frame
end

local Categories = {"子追", "自瞄", "战斗", "移动", "视觉", "自动", "杂项"}
local categoryButtons = {}
local categoryFrames = {}
for _, cat in ipairs(Categories) do categoryFrames[cat] = {} end

local zhuiCat = categoryFrames["子追"]
table.insert(zhuiCat, createToggleRow("启用子追", true,
    function() return RageSettings.Enabled end,
    function() RageSettings.Enabled = true end,
    function() RageSettings.Enabled = false end,
    function() return Settings.KeyBinds.aimbot end,
    function(v) Settings.KeyBinds.aimbot = v end
))
table.insert(zhuiCat, createSliderRow("射速", 1, 1000, 5,
    function() return RageSettings.FireRate end,
    function(v) RageSettings.FireRate = math.floor(v) end
))
table.insert(zhuiCat, createToggleRow("预测", true,
    function() return RageSettings.Prediction end,
    function() RageSettings.Prediction = true end,
    function() RageSettings.Prediction = false end
))
table.insert(zhuiCat, createSliderRow("预测量", 0.05, 0.3, 0.1,
    function() return RageSettings.PredictionAmount end,
    function(v) RageSettings.PredictionAmount = v end
))
table.insert(zhuiCat, createToggleRow("可见性检查", true,
    function() return RageSettings.VisibilityCheck end,
    function() RageSettings.VisibilityCheck = true end,
    function() RageSettings.VisibilityCheck = false end
))
table.insert(zhuiCat, createToggleRow("命中通知", true,
    function() return RageSettings.HitNotifyEnabled end,
    function() RageSettings.HitNotifyEnabled = true end,
    function() RageSettings.HitNotifyEnabled = false end
))
table.insert(zhuiCat, createSliderRow("通知持续时间", 1, 10, 3,
    function() return RageSettings.HitNotifyDuration end,
    function(v) RageSettings.HitNotifyDuration = math.floor(v) end
))
table.insert(zhuiCat, createSliderRow("声音类型 (1-默认,2-武器,3-自定义)", 1, 3, 1,
    function()
        if RageSettings.HitSoundType == "Default" then return 1
        elseif RageSettings.HitSoundType == "Weapon" then return 2
        else return 3 end
    end,
    function(v)
        if v == 1 then RageSettings.HitSoundType = "Default"
        elseif v == 2 then RageSettings.HitSoundType = "Weapon"
        else RageSettings.HitSoundType = "Custom" end
    end
))
table.insert(zhuiCat, createToggleRow("FOV 圆圈", true,
    function() return RageSettings.FovEnabled end,
    function() RageSettings.FovEnabled = true; updateFovCircle() end,
    function() RageSettings.FovEnabled = false; updateFovCircle() end
))
table.insert(zhuiCat, createSliderRow("FOV 半径", 10, 1500, 100,
    function() return RageSettings.FovRadius end,
    function(v) RageSettings.FovRadius = math.floor(v); updateFovCircle() end
))
table.insert(zhuiCat, createToggleRow("无 FOV 限制", true,
    function() return RageSettings.NoFovLimit end,
    function() RageSettings.NoFovLimit = true end,
    function() RageSettings.NoFovLimit = false end
))
table.insert(zhuiCat, createToggleRow("倒地检查", true,
    function() return RageSettings.DownedCheck end,
    function() RageSettings.DownedCheck = true end,
    function() RageSettings.DownedCheck = false end
))
table.insert(zhuiCat, createToggleRow("无射速限制", true,
    function() return RageSettings.NoFireRateLimit end,
    function() RageSettings.NoFireRateLimit = true end,
    function() RageSettings.NoFireRateLimit = false end
))

local aimCat = categoryFrames["自瞄"]
table.insert(aimCat, createToggleRow("自瞄辅助", true,
    function() return Settings.Aimbot.Enabled end,
    function() Settings.Aimbot.Enabled = true; StartAimbot() end,
    function() Settings.Aimbot.Enabled = false; StopAimbot() end,
    function() return Settings.KeyBinds.aimbot end,
    function(v) Settings.KeyBinds.aimbot = v end
))
table.insert(aimCat, createCheckboxRow("绘制圆圈",
    function() return Settings.Aimbot.Draw end,
    function(v) Settings.Aimbot.Draw = v end
))
table.insert(aimCat, createSliderRow("大小", 20, 500, Settings.Aimbot.DrawSize,
    function() return Settings.Aimbot.DrawSize end,
    function(v) Settings.Aimbot.DrawSize = math.floor(v); if AimbotCircle then AimbotCircle.Radius = v end end
))
table.insert(aimCat, createBodySelectorButton("目标部位"))
table.insert(aimCat, createCheckboxRow("检查倒地",
    function() return Settings.Aimbot.CheckDowned end,
    function(v) Settings.Aimbot.CheckDowned = v end
))
table.insert(aimCat, createCheckboxRow("检查墙体",
    function() return Settings.Aimbot.CheckWall end,
    function(v) Settings.Aimbot.CheckWall = v end
))
table.insert(aimCat, createCheckboxRow("检查队友",
    function() return Settings.Aimbot.CheckTeam end,
    function(v) Settings.Aimbot.CheckTeam = v end
))
table.insert(aimCat, createCheckboxRow("提前量",
    function() return Settings.Aimbot.Velocity end,
    function(v) Settings.Aimbot.Velocity = v end
))
table.insert(aimCat, createCheckboxRow("平滑",
    function() return Settings.Aimbot.Smooth end,
    function(v) Settings.Aimbot.Smooth = v end
))
table.insert(aimCat, createSliderRow("平滑度", 0.1, 1, Settings.Aimbot.SmoothSize,
    function() return Settings.Aimbot.SmoothSize end,
    function(v) Settings.Aimbot.SmoothSize = v end
))

local fightCat = categoryFrames["战斗"]
table.insert(fightCat, createToggleRow("近战光环", true,
    function() return MeleeAura_Enabled end,
    MeleeAura_Enable, MeleeAura_Disable,
    function() return Settings.KeyBinds.melee end,
    function(v) Settings.KeyBinds.melee = v end
))
table.insert(fightCat, createToggleRow("无后坐力", true,
    function() return NoRecoil_Enabled end,
    NoRecoil_Enable, NoRecoil_Disable,
    function() return Settings.KeyBinds.noRecoil end,
    function(v) Settings.KeyBinds.noRecoil = v end
))

local moveCat = categoryFrames["移动"]
table.insert(moveCat, createToggleRow("飞行", true,
    function() return Fly_Enabled end,
    Fly_Enable, Fly_Disable,
    function() return Settings.KeyBinds.fly end,
    function(v) Settings.KeyBinds.fly = v end
))
table.insert(moveCat, createToggleRow("穿墙", true,
    function() return Noclip_Enabled end,
    Noclip_Enable, Noclip_Disable,
    function() return Settings.KeyBinds.noclip end,
    function(v) Settings.KeyBinds.noclip = v end
))
table.insert(moveCat, createToggleRow("无限耐力", true,
    function() return isInfiniteStaminaEnabled end,
    InfiniteStamina_Enable, InfiniteStamina_Disable,
    function() return Settings.KeyBinds.infiniteStamina end,
    function(v) Settings.KeyBinds.infiniteStamina = v end
))
table.insert(moveCat, createToggleRow("无摔落伤害", true,
    function() return Nofalldamage_Enabled end,
    Nofalldamage_Enable, Nofalldamage_Disable,
    function() return Settings.KeyBinds.nofalldamage end,
    function(v) Settings.KeyBinds.nofalldamage = v end
))
table.insert(moveCat, createToggleRow("无屏障", true,
    function() return NoBarriers_Enabled end,
    NoBarriers_Enable, NoBarriers_Disable,
    function() return Settings.KeyBinds.nobarriers end,
    function(v) Settings.KeyBinds.nobarriers = v end
))

local visCat = categoryFrames["视觉"]
table.insert(visCat, createToggleRow("ESP", true,
    function() return ESP_Enabled end,
    ESP_Enable, ESP_Disable,
    function() return Settings.KeyBinds.esp end,
    function(v) Settings.KeyBinds.esp = v end
))
table.insert(visCat, createToggleRow("隐身", true,
    function() return Invis_Enabled end,
    Invis_EnableCall, Invis_DisableCall,
    function() return Settings.KeyBinds.invis end,
    function(v) Settings.KeyBinds.invis = v end
))
table.insert(visCat, createToggleRow("保险箱透视", true,
    function() return BredMakurz_Enabled end,
    BredMakurz_Enable, BredMakurz_Disable,
    function() return Settings.KeyBinds.safeESP end,
    function(v) Settings.KeyBinds.safeESP = v end
))
table.insert(visCat, createToggleRow("全亮", true,
    function() return FullBright_Enabled end,
    FullBright_Enable, FullBright_Disable,
    function() return Settings.KeyBinds.fullbright end,
    function(v) Settings.KeyBinds.fullbright = v end
))
table.insert(visCat, createToggleRow("视野", true,
    function() return Fov_Enabled end,
    Fov_Enable, Fov_Disable,
    function() return Settings.KeyBinds.fov end,
    function(v) Settings.KeyBinds.fov = v end
))
table.insert(visCat, createSliderRow("视野角度", 70, 120, Fov_Value,
    function() return Fov_Value end,
    function(v) Fov_Value = math.floor(v) end
))
table.insert(visCat, createSliderRow("相机距离", 10, 500, LocalPlayer.CameraMaxZoomDistance,
    function() return LocalPlayer.CameraMaxZoomDistance end,
    function(v) LocalPlayer.CameraMaxZoomDistance = v end
))

local autoCat = categoryFrames["自动"]
table.insert(autoCat, createToggleRow("自动开门", true,
    function() return OpenNearbyDoors_Enabled end,
    OpenNearbyDoors_Enable, OpenNearbyDoors_Disable,
    function() return Settings.KeyBinds.autodoors end,
    function(v) Settings.KeyBinds.autodoors = v end
))
table.insert(autoCat, createToggleRow("自动解锁门", true,
    function() return UnlockNearbyDoors_Enabled end,
    UnlockNearbyDoors_Enable, UnlockNearbyDoors_Disable,
    function() return Settings.KeyBinds.unlockdoors end,
    function(v) Settings.KeyBinds.unlockdoors = v end
))
table.insert(autoCat, createToggleRow("自动拾取金钱", true,
    function() return AutoPickupMoney_Enabled end,
    AutoPickupMoney_Enable, AutoPickupMoney_Disable,
    function() return Settings.KeyBinds.autopickupmoney end,
    function(v) Settings.KeyBinds.autopickupmoney = v end
))
table.insert(autoCat, createToggleRow("自动拾取废料", true,
    function() return AutoPickupScraps_Enabled end,
    AutoPickupScraps_Enable, AutoPickupScraps_Disable,
    function() return Settings.KeyBinds.autopickupscraps end,
    function(v) Settings.KeyBinds.autopickupscraps = v end
))
table.insert(autoCat, createToggleRow("自动拾取工具", true,
    function() return AutoPickupTools_Enabled end,
    AutoPickupTools_Enable, AutoPickupTools_Disable,
    function() return Settings.KeyBinds.autopickuptools end,
    function(v) Settings.KeyBinds.autopickuptools = v end
))
table.insert(autoCat, createToggleRow("自动开锁", true,
    function() return NewFeatures.AutoLockpick end,
    function() NewFeatures.AutoLockpick = true end,
    function() NewFeatures.AutoLockpick = false end,
    function() return Settings.KeyBinds.autolockpick end,
    function(v) Settings.KeyBinds.autolockpick = v end
))

local miscCat = categoryFrames["杂项"]
table.insert(miscCat, createToggleRow("快速拾取", true,
    function() return FastPickup_Enabled end,
    FastPickup_Enable, FastPickup_Disable,
    function() return Settings.KeyBinds.fastpickup end,
    function(v) Settings.KeyBinds.fastpickup = v end
))
table.insert(miscCat, createToggleRow("开锁必过", true,
    function() return NoFailLockpick_Enabled end,
    NoFailLockpick_Enable, NoFailLockpick_Disable,
    function() return Settings.KeyBinds.nofaillockpick end,
    function(v) Settings.KeyBinds.nofaillockpick = v end
))
table.insert(miscCat, createToggleRow("假倒地", true,
    function() return FakeDown_Enabled end,
    FakeDown_Enable, FakeDown_Disable,
    function() return Settings.KeyBinds.fakedown end,
    function(v) Settings.KeyBinds.fakedown = v end
))
table.insert(miscCat, createToggleRow("禁止头部转动", true,
    function() return Stopneckmove_Enabled end,
    Stopneckmove_Enable, Stopneckmove_Disable,
    function() return Settings.KeyBinds.stopneckmove end,
    function(v) Settings.KeyBinds.stopneckmove = v end
))
table.insert(miscCat, createToggleRow("肢体不骨折", true,
    function() return Unbreaklimbs_Enabled end,
    Unbreaklimbs_Enable, Unbreaklimbs_Disable,
    function() return Settings.KeyBinds.unbreaklimbs end,
    function(v) Settings.KeyBinds.unbreaklimbs = v end
))
table.insert(miscCat, createToggleRow("瞬间换弹", true,
    function() return Instantreload_Enabled end,
    Instantreload_Enable, Instantreload_Disable,
    function() return Settings.KeyBinds.instantreload end,
    function(v) Settings.KeyBinds.instantreload = v end
))
table.insert(miscCat, createToggleRow("管理员检测", true,
    function() return AdminCheck_Enabled end,
    AdminCheck_Enable, AdminCheck_Disable,
    function() return Settings.KeyBinds.admincheck end,
    function(v) Settings.KeyBinds.admincheck = v end
))

for catName, frames in pairs(categoryFrames) do
    for _, frame in ipairs(frames) do
        frame.Parent = content
        frame.Visible = false
    end
end
local defaultCategory = "自瞄"
for _, frame in ipairs(categoryFrames[defaultCategory]) do
    frame.Visible = true
end

local activeCategoryButton = nil
for _, catName in ipairs(Categories) do
    local btn = Instance.new("TextButton")
    btn.Name = catName .. "Button"
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(20,20,25)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = #categoryButtons + 1
    btn.Parent = sidebar
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,6); corner.Parent = btn
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = catName
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(180,180,190)
    label.Parent = btn

    btn.MouseEnter:Connect(function()
        if btn ~= activeCategoryButton then
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30,30,35)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn ~= activeCategoryButton then
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20,20,25)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if btn == activeCategoryButton then return end
        if activeCategoryButton then
            TweenService:Create(activeCategoryButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20,20,25)}):Play()
            activeCategoryButton.TextLabel.TextColor3 = Color3.fromRGB(180,180,190)
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,50)}):Play()
        btn.TextLabel.TextColor3 = Color3.fromRGB(230,230,230)
        activeCategoryButton = btn

        for _, frames in pairs(categoryFrames) do
            for _, frame in ipairs(frames) do
                frame.Visible = false
            end
        end
        for _, frame in ipairs(categoryFrames[catName]) do
            frame.Visible = true
        end
    end)
    categoryButtons[catName] = btn
end

local defaultBtn = categoryButtons[defaultCategory]
if defaultBtn then
    defaultBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    defaultBtn.TextLabel.TextColor3 = Color3.fromRGB(230,230,230)
    activeCategoryButton = defaultBtn
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.Unknown then return end
    if currentRowWaitingForKey then
        local frame = currentRowWaitingForKey
        local bindBtn = bindButtonRefs[frame]
        local getter = keyGetters[frame]
        local setter = keySetters[frame]
        local data = toggleData[frame]
        if bindBtn and getter and setter and data then
            pcall(function()
                local oldKey = nil
                local s,r = pcall(getter)
                if s then oldKey = r end
                if oldKey and activeBinds[oldKey] and activeBinds[oldKey].frame == frame then
                    activeBinds[oldKey] = nil
                end
                if activeBinds[key] and activeBinds[key].frame ~= frame then
                    local otherFrame = activeBinds[key].frame
                    local otherSet = keySetters[otherFrame]
                    if otherSet then pcall(otherSet, nil) end
                    local otherBtn = bindButtonRefs[otherFrame]
                    if otherBtn then otherBtn.Text = "绑定" end
                    activeBinds[key] = nil
                end
                pcall(setter, key)
                local toggleBtn = data.toggleBtn
                if toggleBtn then
                    activeBinds[key] = {
                        frame = frame,
                        toggleBtn = toggleBtn,
                        isEnabledFn = data.isEnabledFn,
                        onEnable = data.onEnable,
                        onDisable = data.onDisable,
                        canToggle = data.canToggle,
                        updateFn = data.updateFn
                    }
                end
                bindBtn.Text = "["..key.Name.."]"
                currentRowWaitingForKey = nil
            end)
        else
            if bindBtn then bindBtn.Text = "绑定" end
            currentRowWaitingForKey = nil
        end
    elseif activeBinds[key] then
        pcall(function()
            local info = activeBinds[key]
            if info and info.canToggle then
                local enabled = false
                if type(info.isEnabledFn) == "function" then
                    local s,r = pcall(info.isEnabledFn)
                    if s then enabled = r end
                end
                if enabled then
                    if type(info.onDisable) == "function" then pcall(info.onDisable) end
                else
                    if type(info.onEnable) == "function" then pcall(info.onEnable) end
                end
                if type(info.updateFn) == "function" then pcall(info.updateFn) end
            end
        end)
    end
end)

mainFrame.Size = UDim2.new(0,0,0,0)
local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,450,0,400)})
task.wait(0.1)
openTween:Play()

print("X6G1 Hub 2.0 加载完成。按 Ins 切换。")