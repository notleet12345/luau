-- [ RIVALS 올인원 스크립트 - 모바일/PC 완벽 호환 ]
-- Delta Executor 등에서 loadstring으로 바로 사용 가능

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- 설정값
local FIGHT_RANGE = 5
local FIGHT_SPEED = 0.15
local DODGE_UP = 120
local DODGE_WAIT = 0.35

local isFight = false
local isAimbot = false
local isSpeed = false
local isAirJump = false
local isDodging = false
local lastAtk = 0

-- GUI 생성
local Gui = Instance.new("ScreenGui")
Gui.Name = "RivalsAllInOne"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 300)
Main.Position = UDim2.new(1, -240, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BackgroundTransparency = 0.15
Main.BorderSizePixel = 0
Main.Parent = Gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🔥 RIVALS 올인원"
Title.TextColor3 = Color3.fromRGB(255, 100, 100)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Main

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 8)
List.HorizontalAlignment = Enum.HorizontalAlignment.Center
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Main

local function mkBtn(txt, color, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 200, 0, 50)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Text = txt
    b.LayoutOrder = order
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = b
    
    b.Parent = Main
    return b
end

-- 버튼들 생성 (정돈된 레이아웃 순서 부여)
local b1 = mkBtn("⚔️ AUTO FIGHT: OFF", Color3.fromRGB(255, 60, 60), 1)
local b2 = mkBtn("🎯 AIMBOT: OFF", Color3.fromRGB(255, 60, 60), 2)
local b3 = mkBtn("🏃 SPEED: OFF", Color3.fromRGB(255, 60, 60), 3)
local b4 = mkBtn("🦅 AIR JUMP: OFF", Color3.fromRGB(255, 60, 60), 4)

-- 토글 로직
b1.MouseButton1Click:Connect(function()
    isFight = not isFight
    b1.Text = isFight and "⚔️ AUTO FIGHT: ON" or "⚔️ AUTO FIGHT: OFF"
    b1.BackgroundColor3 = isFight and Color3.fromRGB(60, 255, 60) or Color3.fromRGB(255, 60, 60)
end)

b2.MouseButton1Click:Connect(function()
    isAimbot = not isAimbot
    b2.Text = isAimbot and "🎯 AIMBOT: ON" or "🎯 AIMBOT: OFF"
    b2.BackgroundColor3 = isAimbot and Color3.fromRGB(60, 150, 255) or Color3.fromRGB(255, 60, 60)
end)

b3.MouseButton1Click:Connect(function()
    isSpeed = not isSpeed
    b3.Text = isSpeed and "🏃 SPEED: ON" or "🏃 SPEED: OFF"
    b3.BackgroundColor3 = isSpeed and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 60, 60)
end)

b4.MouseButton1Click:Connect(function()
    isAirJump = not isAirJump
    b4.Text = isAirJump and "🦅 AIR JUMP: ON" or "🦅 AIR JUMP: OFF"
    b4.BackgroundColor3 = isAirJump and Color3.fromRGB(200, 50, 255) or Color3.fromRGB(255, 60, 60)
end)

-- 공중 점프 기능
UserInputService.JumpRequest:Connect(function()
    if isAirJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- 가장 가까운 적 찾기 함수
local function getTarget()
    local target, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            if p.Character.Humanoid.Health > 0 then
                local d = (HRP.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    target = p.Character
                end
            end
        end
    end
    return target
end

-- 피격 시 회피 로직 함수화 (리스폰 대응용)
local function connectHealthChanged(targetHumanoid)
    targetHumanoid.HealthChanged:Connect(function(hp)
        if isFight and not isDodging and hp < targetHumanoid.MaxHealth * 0.9 then
            isDodging = true
            local orig = HRP.CFrame
            HRP.CFrame = CFrame.new(orig.X, orig.Y + DODGE_UP, orig.Z)
            
            task.delay(DODGE_WAIT, function()
                if HRP and HRP.Parent then
                    HRP.CFrame = orig
                end
                isDodging = false
            end)
        end
    end)
end

-- 초기 실행 시 이벤트 연결
connectHealthChanged(Humanoid)

-- 리스폰(재소환) 처리 반영
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Humanoid = c:WaitForChild("Humanoid")
    if isSpeed then Humanoid.WalkSpeed = 28 end
    connectHealthChanged(Humanoid) -- 새 Humanoid에도 회피 로직 재연결
end)

-- 메인 루프 (연산 최적화 적용)
RunService.RenderStepped:Connect(function()
    if not Character or not HRP or not Humanoid or Humanoid.Health <= 0 then return end
    
    local target = getTarget()
    
    -- 에임봇 기능
    if isAimbot and target and target:FindFirstChild("Head") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Head.Position)
    end
    
    -- 스피드 핵 기능
    if isSpeed and Humanoid then
        Humanoid.WalkSpeed = 28
    else
        if Humanoid then Humanoid.WalkSpeed = 16 end
    end
    
    -- 오토 파이트 기능
    if isFight and not isDodging and target and target:FindFirstChild("HumanoidRootPart") then
        local tHRP = target.HumanoidRootPart
        
        -- 부드럽게 적 배후/정면으로 접근
        local goal = tHRP.CFrame * CFrame.new(0, 0, FIGHT_RANGE)
        HRP.CFrame = HRP.CFrame:Lerp(goal, 0.6)
        HRP.Velocity = Vector3.new(0, HRP.Velocity.Y, 0)
        
        -- 쿨타임 무시 및 자동 공격
        if tick() - lastAtk >= FIGHT_SPEED then
            lastAtk = tick()
            for _, tool in pairs(Character:GetChildren()) do
                if tool:IsA("Tool") then
                    if tool:FindFirstChild("Cooldown") then
                        tool.Cooldown.Value = 0
                    end
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
    end
end)

print("✅ Rivals 올인원 스크립트 로드 완료!")
