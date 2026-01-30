-- GlassBoxGray オーラ MOD + クリスマスツリー + Wing + 魔法陣 + テレポート + サイレントエイム
-- 高さ5の位置にリング状に配置・回転 (形状選択機能付き)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- ★ OrionUIライブラリをロード ★
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

local Window = OrionLib:MakeWindow({ Name = "GlassBoxGray オーラ", HidePremium = true, SaveConfig = false })
local Tab = Window:MakeTab({ Name = "AURA", Icon = "rbxassetid://448336338" })
local ChristmasTab = Window:MakeTab({ Name = "🎄 Christmas Tree", Icon = "rbxassetid://448336338" })
local WingTab = Window:MakeTab({ Name = "👼 Wing", Icon = "rbxassetid://448336338" })
local CombinedTab = Window:MakeTab({ Name = "🌟 Combined", Icon = "rbxassetid://448336338" })
local TeleportTab = Window:MakeTab({ Name = "🌀 テレポート", Icon = "rbxassetid://448336338" })
local SilentAimTab = Window:MakeTab({ Name = "🎯 サイレントエイム", Icon = "rbxassetid://448336338" })

-- 設定変数 (通常オーラ)
local Enabled = false
local FollowPlayerEnabled = false
local TargetPlayerName = ""
local RingHeight = 5.0
local RingSize = 5.0
local ObjectCount = 30
local RotationSpeed = 20.0
local ShapeType = "Circle"

-- 設定変数 (クリスマスツリー)
local TreeEnabled = false
local TreeFollowPlayerEnabled = false
local TreeTargetPlayerName = ""
local TreeHeight = 15.0
local TreeLayers = 5
local TreeRotationSpeed = 20.0
local TreeObjectCount = 25
local TreeRingSize = 8.0

-- 設定変数 (Wing)
local WingEnabled = false
local WingFollowPlayerEnabled = false
local WingTargetPlayerName = ""
local WingVerticalOffset = 2.0
local WingSpread = 5.0
local WingObjectCount = 10
local WingFlapShape = 2.0
local WingFlapSpeed = 1.0
local WingFlapAmount = 3.0
local WingObjectType = "GlassBoxGray"

-- ★ コンビネーションモード設定 - 固定値に設定 ★
local CombinedEnabled = false
local CombinedFollowPlayerEnabled = false
local CombinedTargetPlayerName = ""
-- ★ リング設定 (固定値) ★
local CombinedRingHeight = 50.0  -- 高さ50に固定
local CombinedRingSize = 100.0   -- サイズ100に固定
local CombinedRingObjectCount = 30  -- オブジェクト量30に固定
local CombinedRotationSpeed = 120.0  -- 回転速度120に固定
local CombinedShapeType = "Circle"  -- 形状Circleに固定
-- ★ 翼設定 (固定値) ★
local CombinedWingVerticalOffset = 0.0  -- 高さ0に固定
local CombinedWingSpread = 57.0  -- 長さ57に固定
local CombinedWingObjectCount = 41  -- オブジェクト量41に固定
local CombinedWingFlapShape = 3.5  -- 波の細かさ3.5に固定
local CombinedWingFlapSpeed = 1.5  -- 速さ1.5に固定
local CombinedWingFlapAmount = 71.0  -- 折りたたみ71に固定
-- ★ 装飾設定 ★
local CombinedDecorationEnabled = false
local CombinedDecorationCount = 10
local CombinedDecorationHeight = 8.0
local CombinedDecorationSize = 12.0
local CombinedDecorationRotationSpeed = 15.0
local CombinedDecorationPattern = "Circle"

-- Combinedモードで使用するオブジェクトタイプの選択
local CombinedObjectType = "GlassBoxGray"  -- GlassBoxGrayに固定

-- ★ 追加: テレポート設定 ★
local TeleportEnabled = false
local TeleportHeight = 0.0  -- 高さ調整可能 (0〜20)
local TeleportKey = Enum.KeyCode.T  -- テレポートキー
local TeleportSpeed = 100  -- テレポート速度

-- ★ 追加: サイレントエイム設定 ★
local SilentAimEnabled = false
local SilentAimKey = Enum.KeyCode.Q  -- サイレントエイムキー
local SilentAimFOV = 50  -- 吸い付く範囲 (1〜50)
local SilentAimHitPart = "HumanoidRootPart"  -- 狙う部位
local SilentAimWallCheck = true  -- 壁貫通チェック
local SilentAimPrediction = 0.165  -- 予測値

local list = {}
local loopConn = nil
local tAccum = 0
local wingTimeAccum = 0
local decorationTimeAccum = 0

-- ★ 追加: サイレントエイム変数 ★
local silentAimConnection = nil
local mouse = LP:GetMouse()

-- HRP取得
local function HRP()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c:FindFirstChild("HumanoidRootPart")
end

-- ターゲットプレイヤーのHRP取得
local function getTargetHRP(playerName)
    if playerName == "" then return nil end
    
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then return nil end
    
    local char = targetPlayer.Character
    if not char then return nil end
    
    return char:FindFirstChild("HumanoidRootPart")
end

-- モデルからパーツ取得
local function getPartFromModel(m)
    if m.PrimaryPart then return m.PrimaryPart end
    for _, child in ipairs(m:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

-- 物理演算アタッチ
local function attachPhysics(rec)
    local model = rec.model
    local part = rec.part
    if not model or not part or not part.Parent then return end
    
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p:SetNetworkOwner(LP) end)
            p.CanCollide = false
            p.CanTouch = false
        end
    end
    
    if not part:FindFirstChild("BodyVelocity") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "BodyVelocity"
        bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
        bv.Velocity = Vector3.new()
        bv.P = 1e6
        bv.Parent = part
    end
    
    if not part:FindFirstChild("BodyGyro") then
        local bg = Instance.new("BodyGyro")
        bg.Name = "BodyGyro"
        bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
        bg.CFrame = part.CFrame
        bg.P = 1e6
        bg.Parent = part
    end
end

-- 物理演算デタッチ
local function detachPhysics(rec)
    local model = rec.model
    local part = rec.part
    if not model or not part then return end
    
    local bv = part:FindFirstChild("BodyVelocity")
    if bv then bv:Destroy() end
    
    local bg = part:FindFirstChild("BodyGyro")
    if bg then bg:Destroy() end
    
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = true
            p.CanTouch = true
            pcall(function() p:SetNetworkOwner(nil) end)
        end
    end
end

-- GlassBoxGrayをスキャン
local function rescan()
    for _, r in ipairs(list) do
        detachPhysics(r)
    end
    list = {}
    
    local maxObjects = 0
    local foundCount = 0
    
    -- 各モードに必要なオブジェクト数を計算
    if CombinedEnabled then
        maxObjects = CombinedRingObjectCount + (CombinedWingObjectCount * 2)
        if CombinedDecorationEnabled then
            maxObjects = maxObjects + CombinedDecorationCount
        end
    elseif WingEnabled then
        maxObjects = WingObjectCount * 2
    elseif TreeEnabled then
        maxObjects = TreeObjectCount
    else
        maxObjects = ObjectCount
    end
    
    for _, d in ipairs(Workspace:GetDescendants()) do
        if foundCount >= maxObjects then break end
        
        -- 対象のオブジェクトを検索
        if d:IsA("Model") and d.Name == "GlassBoxGray" then
            local part = getPartFromModel(d)
            if part and not part.Anchored then
                local rec = { 
                    model = d, 
                    part = part,
                    globalIndex = foundCount + 1,
                    type = "unknown",
                    objectName = "GlassBoxGray"
                }
                
                if CombinedEnabled then
                    if foundCount < CombinedRingObjectCount then
                        rec.type = "ring"
                        rec.ringIndex = foundCount + 1
                        rec.totalRings = CombinedRingObjectCount
                    elseif foundCount < (CombinedRingObjectCount + (CombinedWingObjectCount * 2)) then
                        rec.type = "wing"
                        rec.wingIndex = foundCount - CombinedRingObjectCount + 1
                        rec.totalWings = CombinedWingObjectCount * 2
                    else
                        rec.type = "decoration"
                        rec.decorationIndex = foundCount - (CombinedRingObjectCount + (CombinedWingObjectCount * 2)) + 1
                        rec.totalDecorations = CombinedDecorationCount
                    end
                elseif WingEnabled then
                    rec.type = "wing"
                    rec.wingIndex = foundCount + 1
                    rec.totalWings = WingObjectCount * 2
                elseif TreeEnabled then
                    rec.type = "tree"
                else
                    rec.type = "ring"
                    rec.ringIndex = foundCount + 1
                    rec.totalRings = ObjectCount
                end
                
                table.insert(list, rec)
                foundCount = foundCount + 1
            end
        end
    end
    
    for i = 1, #list do
        attachPhysics(list[i])
    end
end

-- 形状計算関数
local function getShapePosition(index, total, size, rotation, shapeType)
    local t = (index - 1) / total
    
    if shapeType == "Circle" then
        local angle = t * math.pi * 2 + rotation
        local radius = size / 2
        return Vector3.new(
            radius * math.cos(angle),
            0,
            radius * math.sin(angle)
        )
        
    elseif shapeType == "Heart" then
        local angle = (t * 2 * math.pi) + rotation
        local x = 16 * (math.sin(angle))^3
        local y = 13 * math.cos(angle) - 5 * math.cos(2*angle) - 2 * math.cos(3*angle) - math.cos(4*angle)
        local scale = size / 30
        
        return Vector3.new(
            -y * scale,
            0,
            x * scale
        )
    end
    
    return Vector3.new()
end

-- クリスマスツリー形状計算
local function getTreePosition(index, total, rotation)
    local objectsPerLayer = math.ceil(total / TreeLayers)
    local layerIndex = math.floor((index - 1) / objectsPerLayer)
    local indexInLayer = (index - 1) % objectsPerLayer
    
    local layerHeight = (layerIndex / TreeLayers) * TreeHeight
    local radiusAtLayer = (1 - layerIndex / TreeLayers) * TreeRingSize
    
    local t = indexInLayer / objectsPerLayer
    local angle = t * math.pi * 2 + rotation + (layerIndex * 0.5)
    
    return Vector3.new(
        radiusAtLayer * math.cos(angle),
        layerHeight,
        radiusAtLayer * math.sin(angle)
    )
end

-- Wing形状計算
local function getWingPosition(index, total, time, verticalOffset, spread, flapShape, flapSpeed, flapAmount)
    local halfTotal = total / 2
    local isLeftWing = index <= halfTotal
    local wingIndex = isLeftWing and index or (index - halfTotal)
    
    local t = (wingIndex - 1) / (halfTotal - 1)
    local phase = (time * flapSpeed - wingIndex * 0.05) * flapShape
    local sinValue = math.sin(phase)
    
    local actualFlapAmount
    if sinValue > 0 then
        actualFlapAmount = flapAmount * 0.6
    else
        actualFlapAmount = flapAmount
    end
    
    local flapAngle = sinValue * math.rad(actualFlapAmount)
    local baseX = t * spread
    local rotatedY = baseX * math.sin(flapAngle)
    local rotatedX = baseX * math.cos(flapAngle)
    
    local sideOffset = isLeftWing and -(5 + rotatedX) or (5 + rotatedX)
    
    return Vector3.new(
        sideOffset,
        verticalOffset + rotatedY,
        0
    ), isLeftWing
end

-- 装飾パターン計算関数
local function getDecorationPosition(index, total, time, height, size, patternType)
    local t = (index - 1) / total
    
    if patternType == "Circle" then
        local angle = t * math.pi * 2 + time * 0.5
        local radius = size / 2
        local verticalOffset = math.sin(angle * 3 + time) * 2.0
        
        return Vector3.new(
            radius * math.cos(angle),
            height + verticalOffset,
            radius * math.sin(angle)
        )
        
    elseif patternType == "Spiral" then
        local angle = t * math.pi * 6 + time
        local spiralProgress = t
        local radius = (size / 2) * (0.5 + spiralProgress * 0.5)
        local spiralHeight = spiralProgress * height * 1.5
        
        return Vector3.new(
            radius * math.cos(angle),
            spiralHeight,
            radius * math.sin(angle)
        )
        
    elseif patternType == "Crown" then
        local angle = t * math.pi * 2
        local radius = (size / 2) * (0.7 + math.sin(angle * 5 + time) * 0.3)
        local crownHeight = height + math.cos(angle * 8 + time * 2) * 3.0
        
        return Vector3.new(
            radius * math.cos(angle),
            crownHeight,
            radius * math.sin(angle)
        )
    end
    
    return Vector3.new(0, height, 0)
end

-- メインループ
local function startLoop()
    if loopConn then
        loopConn:Disconnect()
        loopConn = nil
    end
    tAccum = 0
    wingTimeAccum = 0
    decorationTimeAccum = 0
    
    loopConn = RunService.Heartbeat:Connect(function(dt)
        local root = HRP()
        if not root or #list == 0 then return end
        
        local targetRoot = root
        
        if CombinedEnabled then
            if CombinedFollowPlayerEnabled then
                local targetHRP = getTargetHRP(CombinedTargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        elseif WingEnabled then
            if WingFollowPlayerEnabled then
                local targetHRP = getTargetHRP(WingTargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        elseif TreeEnabled then
            if TreeFollowPlayerEnabled then
                local targetHRP = getTargetHRP(TreeTargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        else
            if FollowPlayerEnabled then
                local targetHRP = getTargetHRP(TargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        end
        
        local rootVelocity = targetRoot.AssemblyLinearVelocity or targetRoot.Velocity or Vector3.new()
        
        if CombinedEnabled then
            tAccum = tAccum + dt * (CombinedRotationSpeed / 10)
            wingTimeAccum = wingTimeAccum + dt
            decorationTimeAccum = decorationTimeAccum + dt * (CombinedDecorationRotationSpeed / 10)
            
            for i, rec in ipairs(list) do
                local part = rec.part
                if not part or not part.Parent then continue end
                
                local localPos, isLeftWing
                
                if rec.type == "ring" then
                    local ringIndex = rec.ringIndex or 1
                    local ringTotal = rec.totalRings or CombinedRingObjectCount
                    
                    localPos = getShapePosition(ringIndex, ringTotal, CombinedRingSize, tAccum * 0.5, CombinedShapeType)
                    localPos = localPos + Vector3.new(0, CombinedRingHeight, 0)
                elseif rec.type == "wing" then
                    local wingIndex = rec.wingIndex or 1
                    local wingTotal = rec.totalWings or (CombinedWingObjectCount * 2)
                    
                    localPos, isLeftWing = getWingPosition(
                        wingIndex, 
                        wingTotal, 
                        wingTimeAccum,
                        CombinedWingVerticalOffset,
                        CombinedWingSpread,
                        CombinedWingFlapShape,
                        CombinedWingFlapSpeed,
                        CombinedWingFlapAmount
                    )
                elseif rec.type == "decoration" then
                    local decorationIndex = rec.decorationIndex or 1
                    local decorationTotal = rec.totalDecorations or CombinedDecorationCount
                    
                    localPos = getDecorationPosition(
                        decorationIndex,
                        decorationTotal,
                        decorationTimeAccum,
                        CombinedDecorationHeight,
                        CombinedDecorationSize,
                        CombinedDecorationPattern
                    )
                else
                    continue
                end
                
                local targetCF
                if rec.type == "wing" then
                    local _, yRot, _ = targetRoot.CFrame:ToEulerAnglesYXZ()
                    targetCF = CFrame.new(targetRoot.Position) * CFrame.Angles(0, yRot, 0)
                else
                    targetCF = targetRoot.CFrame
                end
                
                local targetPos = targetCF.Position + (targetCF - targetCF.Position):VectorToWorldSpace(localPos)
                
                local dir = targetPos - part.Position
                local distance = dir.Magnitude
                local bv = part:FindFirstChild("BodyVelocity")
                
                if bv then
                    if distance > 0.1 then
                        local moveVelocity = dir.Unit * math.min(3000, distance * 50)
                        bv.Velocity = moveVelocity + rootVelocity
                    else
                        bv.Velocity = rootVelocity
                    end
                    bv.P = 1e6
                end
                
                local bg = part:FindFirstChild("BodyGyro")
                if bg then
                    if rec.type == "wing" and isLeftWing then
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position)
                        bg.CFrame = lookAtCFrame
                    elseif rec.type == "decoration" then
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 1, 0))
                        bg.CFrame = lookAtCFrame
                    else
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position) * CFrame.Angles(0, math.pi, 0)
                        bg.CFrame = lookAtCFrame
                    end
                    bg.P = 1e6
                end
            end
        else
            if WingEnabled then
                wingTimeAccum = wingTimeAccum + dt
            else
                local currentRotationSpeed = TreeEnabled and TreeRotationSpeed or RotationSpeed
                tAccum = tAccum + dt * (currentRotationSpeed / 10)
            end
            
            for i, rec in ipairs(list) do
                local part = rec.part
                if not part or not part.Parent then continue end
                
                local localPos, isLeftWing
                if WingEnabled then
                    localPos, isLeftWing = getWingPosition(
                        rec.wingIndex or i, 
                        rec.totalWings or (WingObjectCount * 2), 
                        wingTimeAccum,
                        WingVerticalOffset, WingSpread, 
                        WingFlapShape, WingFlapSpeed, WingFlapAmount
                    )
                elseif TreeEnabled then
                    localPos = getTreePosition(i, #list, tAccum * 0.5)
                else
                    localPos = getShapePosition(rec.ringIndex or i, rec.totalRings or ObjectCount, RingSize, tAccum * 0.5, ShapeType)
                    localPos = localPos + Vector3.new(0, RingHeight, 0)
                end
                
                local targetCF
                if WingEnabled then
                    local _, yRot, _ = targetRoot.CFrame:ToEulerAnglesYXZ()
                    targetCF = CFrame.new(targetRoot.Position) * CFrame.Angles(0, yRot, 0)
                else
                    targetCF = targetRoot.CFrame
                end
                
                local targetPos = targetCF.Position + (targetCF - targetCF.Position):VectorToWorldSpace(localPos)
                
                local dir = targetPos - part.Position
                local distance = dir.Magnitude
                local bv = part:FindFirstChild("BodyVelocity")
                
                if bv then
                    if distance > 0.1 then
                        local moveVelocity = dir.Unit * math.min(3000, distance * 50)
                        bv.Velocity = moveVelocity + rootVelocity
                    else
                        bv.Velocity = rootVelocity
                    end
                    bv.P = 1e6
                end
                
                local bg = part:FindFirstChild("BodyGyro")
                if bg then
                    if WingEnabled and isLeftWing then
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position)
                        bg.CFrame = lookAtCFrame
                    else
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position) * CFrame.Angles(0, math.pi, 0)
                        bg.CFrame = lookAtCFrame
                    end
                    bg.P = 1e6
                end
            end
        end
    end)
end

-- ループ停止
local function stopLoop()
    if loopConn then
        loopConn:Disconnect()
        loopConn = nil
    end
    for _, rec in ipairs(list) do
        detachPhysics(rec)
    end
    list = {}
end

-- プレイヤー名リスト取得
local function getPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(names, player.Name)
        end
    end
    return names
end

-- ★ 追加: テレポート関数 ★
local function teleportToMouse()
    if not TeleportEnabled then return end
    
    local character = LP.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local targetPosition = mouse.Hit.Position + Vector3.new(0, TeleportHeight, 0)
    local direction = (targetPosition - humanoidRootPart.Position)
    local distance = direction.Magnitude
    
    if distance > 0 then
        -- スムーズなテレポート
        local steps = math.ceil(distance / TeleportSpeed)
        local stepSize = distance / steps
        
        for i = 1, steps do
            if not TeleportEnabled then break end
            
            local stepPos = humanoidRootPart.Position + (direction.Unit * stepSize * i)
            humanoidRootPart.CFrame = CFrame.new(stepPos)
            RunService.Heartbeat:Wait()
        end
    end
end

-- ★ 追加: 壁貫通チェック関数 ★
local function isVisible(targetPart, origin)
    if not SilentAimWallCheck then return true end
    
    local character = LP.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local rayOrigin = origin or humanoidRootPart.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * 1000
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LP.Character}
    
    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        local model = hitPart:FindFirstAncestorWhichIsA("Model")
        
        if model then
            local targetModel = targetPart:FindFirstAncestorWhichIsA("Model")
            if model == targetModel then
                return true
            end
        end
        return false
    end
    
    return true
end

-- ★ 追加: 最適なターゲット取得関数 ★
local function getBestTarget()
    if not SilentAimEnabled then return nil end
    
    local character = LP.Character
    if not character then return nil end
    
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local bestTarget = nil
    local bestDistance = SilentAimFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        
        local targetChar = player.Character
        if not targetChar then continue end
        
        local targetPart = targetChar:FindFirstChild(SilentAimHitPart)
        if not targetPart then continue end
        
        -- 壁貫通チェック
        if not isVisible(targetPart) then continue end
        
        -- スクリーン上の位置を計算
        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
        
        if onScreen then
            local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
            local distance = (screenPoint - mousePos).Magnitude
            
            if distance < bestDistance then
                bestDistance = distance
                bestTarget = {
                    Player = player,
                    Character = targetChar,
                    Part = targetPart,
                    Position = targetPart.Position,
                    Distance = distance
                }
            end
        end
    end
    
    return bestTarget
end

-- ★ 追加: サイレントエイムループ開始 ★
local function startSilentAimLoop()
    if silentAimConnection then
        silentAimConnection:Disconnect()
        silentAimConnection = nil
    end
    
    silentAimConnection = RunService.RenderStepped:Connect(function()
        if not SilentAimEnabled then return end
        
        local target = getBestTarget()
        if target then
            local camera = Workspace.CurrentCamera
            if camera then
                -- マウス位置をターゲットに向ける
                local screenPos = camera:WorldToViewportPoint(target.Position)
                if screenPos then
                    -- マウス位置を更新（実際のマウス移動はしない）
                    -- ここではFOV内にターゲットがあることだけを検知
                end
            end
        end
    end)
end

-- ★ 追加: サイレントエイムループ停止 ★
local function stopSilentAimLoop()
    if silentAimConnection then
        silentAimConnection:Disconnect()
        silentAimConnection = nil
    end
end

-- ★ 追加: テレポートキー入力監視 ★
local teleportConnection = nil
local function startTeleportListener()
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
    
    teleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == TeleportKey and TeleportEnabled then
            teleportToMouse()
        end
        
        if input.KeyCode == SilentAimKey and SilentAimEnabled then
            -- サイレントエイムキーが押されたときの処理
            local target = getBestTarget()
            if target then
                -- ここで射撃などの処理を追加できます
                print("サイレントエイムターゲット: " .. target.Player.Name)
            end
        end
    end)
end

-- ====================================================================
-- UI要素 (通常オーラ)
-- ====================================================================

Tab:AddSection({ Name = "起動/停止" })

Tab:AddToggle({
    Name = "GlassBoxGray オーラ ON/OFF",
    Default = false,
    Callback = function(v)
        Enabled = v
        if v then
            TreeEnabled = false
            WingEnabled = false
            CombinedEnabled = false
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

Tab:AddSection({ Name = "Follow Player" })

Tab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        TargetPlayerName = v
    end
})

Tab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        FollowPlayerEnabled = v
    end
})

Tab:AddSection({ Name = "形状選択" })

Tab:AddDropdown({
    Name = "オーラの形状",
    Default = ShapeType,
    Options = {"Circle", "Heart"},
    Callback = function(v)
        ShapeType = v
    end
})

Tab:AddSection({ Name = "GlassBoxGray 設定" })

Tab:AddSlider({
    Name = "形状の高さ",
    Min = 1.0,
    Max = 50.0,
    Default = RingHeight,
    Increment = 0.5,
    Callback = function(v)
        RingHeight = v
    end
})

Tab:AddSlider({
    Name = "形状のサイズ",
    Min = 3.0,
    Max = 100.0,
    Default = RingSize,
    Increment = 1.0,
    Callback = function(v)
        RingSize = v
    end
})

Tab:AddSlider({
    Name = "オブジェクト数",
    Min = 3,
    Max = 30,
    Default = ObjectCount,
    Increment = 1,
    Callback = function(v)
        ObjectCount = v
        if Enabled then
            rescan()
        end
    end
})

Tab:AddSlider({
    Name = "回転速度",
    Min = 0.0,
    Max = 1000.0,
    Default = RotationSpeed,
    Increment = 10.0,
    Callback = function(v)
        RotationSpeed = v
    end
})

-- ====================================================================
-- UI要素 (クリスマスツリー)
-- ====================================================================

ChristmasTab:AddSection({ Name = "🎄 Christmas Tree 起動" })

ChristmasTab:AddToggle({
    Name = "🎄 Christmas Tree ON/OFF",
    Default = false,
    Callback = function(v)
        TreeEnabled = v
        if v then
            Enabled = false
            WingEnabled = false
            CombinedEnabled = false
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

ChristmasTab:AddSection({ Name = "Follow Player (ツリー)" })

ChristmasTab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        TreeTargetPlayerName = v
    end
})

ChristmasTab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        TreeFollowPlayerEnabled = v
    end
})

ChristmasTab:AddSection({ Name = "ツリー設定" })

ChristmasTab:AddSlider({
    Name = "ツリーの高さ",
    Min = 5.0,
    Max = 200.0,
    Default = TreeHeight,
    Increment = 5.0,
    Callback = function(v)
        TreeHeight = v
    end
})

ChristmasTab:AddSlider({
    Name = "ツリーの幅 (リング最大半径)",
    Min = 3.0,
    Max = 100.0,
    Default = TreeRingSize,
    Increment = 1.0,
    Callback = function(v)
        TreeRingSize = v
    end
})

ChristmasTab:AddSlider({
    Name = "ツリーの層数",
    Min = 1,
    Max = 30,
    Default = TreeLayers,
    Increment = 1,
    Callback = function(v)
        TreeLayers = v
    end
})

ChristmasTab:AddSlider({
    Name = "オブジェクト数",
    Min = 10,
    Max = 30,
    Default = TreeObjectCount,
    Increment = 1,
    Callback = function(v)
        TreeObjectCount = v
        if TreeEnabled then
            rescan()
        end
    end
})

ChristmasTab:AddSlider({
    Name = "回転速度",
    Min = 0.0,
    Max = 1000.0,
    Default = TreeRotationSpeed,
    Increment = 10.0,
    Callback = function(v)
        TreeRotationSpeed = v
    end
})

-- ====================================================================
-- UI要素 (Wing)
-- ====================================================================

WingTab:AddSection({ Name = "👼 Wing 起動" })

WingTab:AddToggle({
    Name = "👼 Wing ON/OFF",
    Default = false,
    Callback = function(v)
        WingEnabled = v
        if v then
            Enabled = false
            TreeEnabled = false
            CombinedEnabled = false
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

WingTab:AddSection({ Name = "Follow Player (Wing)" })

WingTab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        WingTargetPlayerName = v
    end
})

WingTab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        WingFollowPlayerEnabled = v
    end
})

WingTab:AddSection({ Name = "Wing 設定" })

WingTab:AddSlider({
    Name = "翼の高さ位置",
    Min = -10.0,
    Max = 20.0,
    Default = WingVerticalOffset,
    Increment = 0.5,
    Callback = function(v)
        WingVerticalOffset = v
    end
})

WingTab:AddSlider({
    Name = "翼の広がり (横の長さ)",
    Min = 3.0,
    Max = 100.0,
    Default = WingSpread,
    Increment = 1.0,
    Callback = function(v)
        WingSpread =
