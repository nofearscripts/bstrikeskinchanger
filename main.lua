--[[
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║    NoFear Multi-Executor Compatibility v3.0 - STEALTH EDITION        ║
    ║                                                                       ║
    ║  Supports: Xeno, Solara, Seliware, Potassium, Wave, Bunni,          ║
    ║           ByteBreaker, Valcano                                        ║
    ║                                                                       ║
    ║  MINIMAL FOOTPRINT - Only adds executor compatibility                ║
    ╚═══════════════════════════════════════════════════════════════════════╝
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ========================================
-- MULTI-EXECUTOR COMPATIBILITY LAYER ONLY
-- NO AGGRESSIVE SCANNING OR HOOKING
-- ========================================

-- Create global compatibility layer
getgenv = getgenv or function() return _G end
gethui = gethui or function() return game:GetService("CoreGui") end

-- Function compatibility (fallbacks only)
hookfunction = hookfunction or replaceclosure or function(old, new) return new end
newcclosure = newcclosure or function(f) return f end
getconnections = getconnections or get_signal_cons or function() return {} end
getgc = getgc or get_gc_objects or function() return {} end
hookmetamethod = hookmetamethod or function(obj, method, hook) return hook end
getnamecallmethod = getnamecallmethod or get_namecall_method or function() return "" end
checkcaller = checkcaller or is_protosmasher_caller or function() return false end

-- Debug info compatibility
if not (debug and debug.info) then
    if debug and debug.getinfo then
        local old_getinfo = debug.getinfo
        debug.info = function(f, w)
            local info = old_getinfo(f)
            if w == "s" then return info.source end
            if w == "n" then return info.name end
            return info
        end
    else
        debug = debug or {}
        debug.info = function() return "" end
    end
end


-- Simple kick protection (minimal)
task.spawn(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    for _, kickName in ipairs({"Kick", "kick"}) do
        pcall(function()
            local kickFunc = LocalPlayer[kickName]
            if type(kickFunc) == "function" then
                local oldKick
                oldKick = hookfunction(kickFunc, newcclosure(function(self, ...)
                    if self == LocalPlayer then
                        return
                    end
                    return oldKick(self, ...)
                end))
            end
        end)
    end
end)

task.wait(1)

-- Skin changer loading

--// ============================================================
--// SKIN CHANGER (Protected by bypass)
--// Full Model + Animation Replacement
--// ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Paths
local weaponsAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Weapons")
local weaponsDB = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Custom"):WaitForChild("Weapons")
local audioDB = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Audio"):WaitForChild("Weapons")

-- Config
local currentConfig = {
    SelectedKnife = nil,
    SelectedKnifeSkin = nil,
    SelectedWeapon = nil,
    SelectedWeaponSkin = nil,
    SelectedGlove = nil,
    SelectedGloveSkin = nil,
    WearLevel = "Factory New",
    EnableSkinchanger = true
}

-- Knife database with available skins per knife
local knifeDatabase = {
    ["Butterfly Knife"] = {"Vanilla", "Fade", "Woodland", "Naval", "Whiteout", "Safari", "Violet", "Midnight", "Blackwidow", "Scarlet", "Lebron James"},
    ["Karambit"] = {"Vanilla", "Fade", "Woodland", "Naval", "Whiteout", "Safari", "Violet", "Midnight", "Blackwidow", "Scarlet", "Aurora", "Frostbite", "Noir"},
    ["Flip Knife"] = {"Vanilla", "Fade", "Woodland", "Naval", "Whiteout", "Safari", "Violet", "Midnight", "Blackwidow", "Scarlet", "Frostbite", "Aurora", "Noir"},
    ["M9 Bayonet"] = {"Vanilla", "Fade", "Woodland", "Naval", "Whiteout", "Safari", "Violet", "Midnight", "Blackwidow", "Scarlet"},
    ["Gut Knife"] = {"Vanilla", "Fade", "Woodland", "Naval", "Whiteout", "Violet", "Midnight", "Blackwidow", "Scarlet", "Safari", "Frostbite", "Aurora", "Noir"}
}

-- Weapon database with available skins per weapon
local weaponDatabase = {
    ["AK-47"] = {"Stock", "Sakura"},
    ["M4A4"] = {"Stock", "The Ambassador", "Wrapped", "B-Hop"},
    ["M4A1-S"] = {"Stock", "Retro", "Anodized Red", "Orchids"},
    ["AWP"] = {"Stock", "Typhon", "Beta", "Metamorphosis", "High Octane"},
    ["Desert Eagle"] = {"Stock", "Mercy", "Permafrost", "High Octane"},
    ["Glock-18"] = {"Stock", "Fade", "Aurora", "Fuji"},
    ["USP-S"] = {"Stock", "Wintergreen"},
    ["P90"] = {"Stock", "Big Cat"},
    ["AUG"] = {"Stock", "Hot Rod", "Overgrowth", "Anodized Red"},
    ["FAMAS"] = {"Stock", "Arctic Camo", "Heirloom"},
    ["Galil AR"] = {"Stock", "Irradiated", "Monochrome"},
    ["SSG 08"] = {"Stock", "Desert Strike", "Labyrinth"},
    ["Nova"] = {"Stock", "Arctic Stripe", "Heat", "Flutter"},
    ["XM1014"] = {"Stock", "Abstract", "Lilies"},
    ["P250"] = {"Stock", "Glacial", "Pulse", "B-250"},
    ["Five-SeveN"] = {"Stock", "Icecap"},
    ["Tec-9"] = {"Stock", "Striker", "Monarch", "Medal.tv"},
    ["Dual Berettas"] = {"Stock", "Choking Hazard", "Vernal"},
    ["MP9"] = {"Stock", "X-Ray", "Anodized Red", "High Octane"},
    ["MAC-10"] = {"Stock", "Air Mail", "Daisies"},
    ["Negev"] = {"Stock", "Frostbloom", "Noctiflora"},
    ["SG 553"] = {"Stock", "Frostline", "Dynasty"}
}

-- Glove database with available skins per glove type
local gloveDatabase = {
    ["Driver Gloves"] = {"Cardinal Weave", "Cobra", "Gator", "Leopard", "Midnight Weave", "Nomad", "Snow Leopard", "Tartan", "Tuxedo", "Cardinal"},
    ["Sports Gloves"] = {"Bumblebee", "Freshmint", "Hunter", "Dune", "Blackout", "Imperial", "Labyrinth", "Malibu", "Racer", "Tidal"},
    ["Operator Gloves"] = {"Emerald Widow", "Black Widow", "Reinforced", "Bumblebee", "Fade", "Smoke", "Amber Fade", "Agent", "Hunter", "Hellwire"},
    ["Hand Wraps"] = {"Crime Scene", "Checkers", "Carpet", "Camouflage", "Meander", "Bandage", "Hunter", "Taped"}
}

-- Store original assets for restoration
local originalAssets = {}
local originalDB = {}
local originalAudio = {}

-- Apply replacement function
local function applyKnifeReplacement(originalName, replacementName, skinName)
    if not replacementName then return end
    
    skinName = skinName or "Fade"
    
    -- Applying knife replacement
    
    -- Replace assets
    local originalAsset = weaponsAssets:FindFirstChild(originalName)
    local replacementAsset = weaponsAssets:FindFirstChild(replacementName)
    
    if originalAsset and replacementAsset then
        if not originalAssets[originalName] then
            originalAssets[originalName] = {}
            for _, child in ipairs(originalAsset:GetChildren()) do
                table.insert(originalAssets[originalName], child:Clone())
            end
        end
        
        for _, child in ipairs(originalAsset:GetChildren()) do
            child:Destroy()
        end
        
        for _, child in ipairs(replacementAsset:GetChildren()) do
            child:Clone().Parent = originalAsset
        end
        
        -- Apply skin texture to Camera model
        local cameraModel = originalAsset:FindFirstChild("Camera")
                if cameraModel then
            local weaponModel = cameraModel:FindFirstChild("Weapon")
                        if weaponModel then
                local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
                local skinFolder = SKINS_PATH:FindFirstChild(replacementName)
                                if skinFolder then
                    local specificSkin = skinFolder:FindFirstChild(skinName)
                                        if specificSkin then
                        local skinCameraFolder = specificSkin:FindFirstChild("Camera")
                                                if skinCameraFolder then
                            local wearFolder = skinCameraFolder:FindFirstChild(currentConfig.WearLevel) or skinCameraFolder:FindFirstChild("Factory New")
                                                        if wearFolder then
                                -- Apply to handle
                                local weaponHandle = weaponModel:FindFirstChild("Handle")
                                if weaponHandle then
                                    for _, child in ipairs(weaponHandle:GetChildren()) do
                                        if child:IsA("SurfaceAppearance") then
                                            child:Destroy()
                                        end
                                    end
                                    local skinSurface = wearFolder:FindFirstChild("Handle")
                                    if skinSurface then
                                        skinSurface:Clone().Parent = weaponHandle
                                    end
                                end
                                
                                -- Apply to other parts (for butterfly knife, etc.)
                                for _, part in ipairs(weaponModel:GetChildren()) do
                                    if part:IsA("BasePart") and part.Name ~= "Handle" then
                                        local skinPart = wearFolder:FindFirstChild(part.Name)
                                        if skinPart then
                                            for _, child in ipairs(part:GetChildren()) do
                                                if child:IsA("SurfaceAppearance") then
                                                    child:Destroy()
                                                end
                                            end
                                            skinPart:Clone().Parent = part
                                        end
                                    end
                                end
                                
                                -- Texture applied silently
                            end
                        end
                    end
                end
            end
        end
        
            end
    
    -- Replace database module
    local originalDBMod = weaponsDB:FindFirstChild(originalName)
    local replacementDBMod = weaponsDB:FindFirstChild(replacementName)
    
    if originalDBMod and replacementDBMod then
        if not originalDB[originalName] then
            originalDB[originalName] = originalDBMod:Clone()
        end
        
        local replacementClone = replacementDBMod:Clone()
        replacementClone.Name = originalName
        replacementDBMod.Parent = nil
        originalDBMod:Destroy()
        replacementClone.Parent = weaponsDB
        replacementDBMod.Parent = weaponsDB
        
            end
    
    -- Replace audio
    local originalAudioMod = audioDB:FindFirstChild(originalName)
    local replacementAudioMod = audioDB:FindFirstChild(replacementName)
    
    if originalAudioMod and replacementAudioMod then
        if not originalAudio[originalName] then
            originalAudio[originalName] = {}
            for _, child in ipairs(originalAudioMod:GetChildren()) do
                table.insert(originalAudio[originalName], child:Clone())
            end
        end
        
        for _, child in ipairs(originalAudioMod:GetChildren()) do
            child:Destroy()
        end
        
        for _, child in ipairs(replacementAudioMod:GetChildren()) do
            child:Clone().Parent = originalAudioMod
        end
        
            end
    
        
    -- Also apply to currently equipped knife if it exists
    local camera = workspace.CurrentCamera
    local equippedKnife = camera:FindFirstChild(originalName)
    if equippedKnife then
                local weaponModel = equippedKnife:FindFirstChild("Weapon")
        if weaponModel then
            local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
            local skinFolder = SKINS_PATH:FindFirstChild(replacementName)
            if skinFolder then
                local specificSkin = skinFolder:FindFirstChild(skinName)
                if specificSkin then
                    local skinCameraFolder = specificSkin:FindFirstChild("Camera")
                    if skinCameraFolder then
                        local wearFolder = skinCameraFolder:FindFirstChild(currentConfig.WearLevel) or skinCameraFolder:FindFirstChild("Factory New")
                        if wearFolder then
                            -- Apply to handle
                            local weaponHandle = weaponModel:FindFirstChild("Handle")
                            if weaponHandle then
                                for _, child in ipairs(weaponHandle:GetChildren()) do
                                    if child:IsA("SurfaceAppearance") then
                                        child:Destroy()
                                    end
                                end
                                local skinSurface = wearFolder:FindFirstChild("Handle")
                                if skinSurface then
                                    skinSurface:Clone().Parent = weaponHandle
                                    -- Texture applied silently
                                end
                            end
                            
                            -- Apply to other parts
                            for _, part in ipairs(weaponModel:GetChildren()) do
                                if part:IsA("BasePart") and part.Name ~= "Handle" then
                                    local skinPart = wearFolder:FindFirstChild(part.Name)
                                    if skinPart then
                                        for _, child in ipairs(part:GetChildren()) do
                                            if child:IsA("SurfaceAppearance") then
                                                child:Destroy()
                                            end
                                        end
                                        skinPart:Clone().Parent = part
                                        -- Texture applied silently
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Apply glove replacement function
local function applyGloveReplacement(originalName, replacementName, skinName)
    if not replacementName or not skinName then return end
    
    -- Applying glove replacement
    
    -- Check if glove type or CT/T default
    local isDefaultGlove = (originalName == "T Glove" or originalName == "CT Glove")
    
    if isDefaultGlove then
        -- Replace default gloves with fancy gloves
        local originalAsset = weaponsAssets:FindFirstChild(originalName)
        local replacementAsset = weaponsAssets:FindFirstChild(replacementName)
        
        if originalAsset and replacementAsset then
            -- Store original
            if not originalAssets[originalName] then
                originalAssets[originalName] = {}
                for _, child in ipairs(originalAsset:GetChildren()) do
                    table.insert(originalAssets[originalName], child:Clone())
                end
            end
            
            -- Clear and replace
            for _, child in ipairs(originalAsset:GetChildren()) do
                child:Destroy()
            end
            
            for _, child in ipairs(replacementAsset:GetChildren()) do
                child:Clone().Parent = originalAsset
            end
            
                    end
        
        -- Replace database
        local originalDBMod = weaponsDB:FindFirstChild(originalName)
        local replacementDBMod = weaponsDB:FindFirstChild(replacementName)
        
        if originalDBMod and replacementDBMod then
            if not originalDB[originalName] then
                originalDB[originalName] = originalDBMod:Clone()
            end
            
            local replacementClone = replacementDBMod:Clone()
            replacementClone.Name = originalName
            replacementDBMod.Parent = nil
            originalDBMod:Destroy()
            replacementClone.Parent = weaponsDB
            replacementDBMod.Parent = weaponsDB
            
                    end
    end
    
    -- Apply glove skin texture (works for both default→fancy and fancy→fancy)
    local targetGlove = isDefaultGlove and originalName or replacementName
    local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
    local skinFolder = SKINS_PATH:FindFirstChild(replacementName)
    
    if skinFolder then
        local specificSkin = skinFolder:FindFirstChild(skinName)
        if specificSkin then
            -- Apply to character gloves (visible to others)
            local characterSkin = specificSkin:FindFirstChild("Character")
            if characterSkin then
                local wearFolder = characterSkin:FindFirstChild(currentConfig.WearLevel) or characterSkin:FindFirstChild("Factory New")
                if wearFolder then
                    local leftArm = wearFolder:FindFirstChild("Left Arm")
                    local rightArm = wearFolder:FindFirstChild("Right Arm")
                    
                    if leftArm or rightArm then
                                            end
                end
            end
            
            -- Apply to camera gloves (first person view)
            local cameraSkin = specificSkin:FindFirstChild("Camera")
            if cameraSkin then
                local wearFolder = cameraSkin:FindFirstChild(currentConfig.WearLevel) or cameraSkin:FindFirstChild("Factory New")
                if wearFolder then
                                    end
            end
        end
    end
    
    end

-- Notifications handled by Window:Notify() from DrawingUILib

local function startTextureMonitor()
    local camera = workspace.CurrentCamera
    
    camera.ChildAdded:Connect(function(child)
        if not child:IsA("Model") then return end
        
        -- Handle knives
        if child.Name == "T Knife" or child.Name == "CT Knife" then
            -- Wait for the knife to fully load
            task.wait(0.3)
            
            -- Check if we have a configured knife/skin
            if currentConfig.SelectedKnife and currentConfig.SelectedKnifeSkin then
                local weaponModel = child:FindFirstChild("Weapon")
                if weaponModel then
                    local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
                    local skinFolder = SKINS_PATH:FindFirstChild(currentConfig.SelectedKnife)
                    if skinFolder then
                        local specificSkin = skinFolder:FindFirstChild(currentConfig.SelectedKnifeSkin)
                        if specificSkin then
                            local skinCameraFolder = specificSkin:FindFirstChild("Camera")
                            if skinCameraFolder then
                                local wearFolder = skinCameraFolder:FindFirstChild(currentConfig.WearLevel) or skinCameraFolder:FindFirstChild("Factory New")
                                if wearFolder then
                                    -- Apply to handle
                                    local weaponHandle = weaponModel:FindFirstChild("Handle")
                                    if weaponHandle then
                                        for _, oldChild in ipairs(weaponHandle:GetChildren()) do
                                            if oldChild:IsA("SurfaceAppearance") then
                                                oldChild:Destroy()
                                            end
                                        end
                                        local skinSurface = wearFolder:FindFirstChild("Handle")
                                        if skinSurface then
                                            skinSurface:Clone().Parent = weaponHandle
                                                                                    end
                                    end
                                    
                                    -- Apply to other parts (butterfly, etc.)
                                    for _, part in ipairs(weaponModel:GetChildren()) do
                                        if part:IsA("BasePart") and part.Name ~= "Handle" then
                                            local skinPart = wearFolder:FindFirstChild(part.Name)
                                            if skinPart then
                                                for _, oldChild in ipairs(part:GetChildren()) do
                                                    if oldChild:IsA("SurfaceAppearance") then
                                                        oldChild:Destroy()
                                                    end
                                                end
                                                skinPart:Clone().Parent = part
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Handle weapons
        if weaponDatabase[child.Name] and currentConfig.SelectedWeapon == child.Name and currentConfig.SelectedWeaponSkin then
            task.wait(0.3)
            
            local weaponModel = child:FindFirstChild("Weapon")
            if weaponModel then
                local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
                local skinFolder = SKINS_PATH:FindFirstChild(child.Name)
                if skinFolder then
                    local specificSkin = skinFolder:FindFirstChild(currentConfig.SelectedWeaponSkin)
                    if specificSkin then
                        local skinCameraFolder = specificSkin:FindFirstChild("Camera")
                        if skinCameraFolder then
                            local wearFolder = skinCameraFolder:FindFirstChild(currentConfig.WearLevel) or skinCameraFolder:FindFirstChild("Factory New")
                            if wearFolder then
                                -- Apply to weapon handle
                                local weaponHandle = weaponModel:FindFirstChild("Handle")
                                if weaponHandle then
                                    for _, oldChild in ipairs(weaponHandle:GetChildren()) do
                                        if oldChild:IsA("SurfaceAppearance") then
                                            oldChild:Destroy()
                                        end
                                    end
                                    local skinSurface = wearFolder:FindFirstChild("Handle")
                                    if skinSurface then
                                        skinSurface:Clone().Parent = weaponHandle
                                                                            end
                                end
                                
                                -- Apply to other parts if they exist
                                for _, part in ipairs(weaponModel:GetChildren()) do
                                    if part:IsA("BasePart") and part.Name ~= "Handle" then
                                        local skinPart = wearFolder:FindFirstChild(part.Name)
                                        if skinPart then
                                            for _, oldChild in ipairs(part:GetChildren()) do
                                                if oldChild:IsA("SurfaceAppearance") then
                                                    oldChild:Destroy()
                                                end
                                            end
                                            skinPart:Clone().Parent = part
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Handle gloves (T Glove or CT Glove)
        if (child.Name == "T Glove" or child.Name == "CT Glove") and currentConfig.SelectedGlove and currentConfig.SelectedGloveSkin then
            task.wait(0.3)
            
            local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
            local skinFolder = SKINS_PATH:FindFirstChild(currentConfig.SelectedGlove)
            if skinFolder then
                local specificSkin = skinFolder:FindFirstChild(currentConfig.SelectedGloveSkin)
                if specificSkin then
                    local skinCameraFolder = specificSkin:FindFirstChild("Camera")
                    if skinCameraFolder then
                        local wearFolder = skinCameraFolder:FindFirstChild(currentConfig.WearLevel) or skinCameraFolder:FindFirstChild("Factory New")
                        if wearFolder then
                            -- Find Left Arm and Right Arm in camera view
                            local leftArm = child:FindFirstChild("Left Arm", true)
                            local rightArm = child:FindFirstChild("Right Arm", true)
                            
                            -- Apply to Left Arm
                            if leftArm then
                                for _, oldChild in ipairs(leftArm:GetChildren()) do
                                    if oldChild:IsA("SurfaceAppearance") then
                                        oldChild:Destroy()
                                    end
                                end
                                local skinLeftArm = wearFolder:FindFirstChild("Left Arm")
                                if skinLeftArm then
                                    skinLeftArm:Clone().Parent = leftArm
                                end
                            end
                            
                            -- Apply to Right Arm
                            if rightArm then
                                for _, oldChild in ipairs(rightArm:GetChildren()) do
                                    if oldChild:IsA("SurfaceAppearance") then
                                        oldChild:Destroy()
                                    end
                                end
                                local skinRightArm = wearFolder:FindFirstChild("Right Arm")
                                if skinRightArm then
                                    skinRightArm:Clone().Parent = rightArm
                                end
                            end
                            
                                                    end
                    end
                end
            end
        end
    end)
    
    end

-- Initialize
-- NoFear BloxStrike SkinChanger

-- Load loader in module mode
local _loaderEnv = getfenv and getfenv() or _ENV
_loaderEnv.ScriptURL = ""
_loaderEnv.ScriptName = "BloxStrike SkinChanger"
local loaderSrc = game:HttpGet("https://raw.githubusercontent.com/nofearscripts/nofearUI/refs/heads/main/nofearld")
local runWithKeyCheck = loadstring(loaderSrc)()
if not runWithKeyCheck then return end

runWithKeyCheck(function()

local uiSrc = game:HttpGet("https://raw.githubusercontent.com/nofearscripts/nofearUI/refs/heads/main/bstrikeUI")
local uiChunk, uiErr = loadstring(uiSrc)
if not uiChunk then error("[NoFear] UI compile error: " .. tostring(uiErr)) end
local ok, result = pcall(uiChunk)
local Library = (ok and result) or getgenv().DrawLib or _G.DrawLib
if not Library then error("[NoFear] Failed to load UI Library - Executor may not be supported") end
local vp = workspace.CurrentCamera.ViewportSize
local Window = Library:CreateWindow({ Title = "NoFear", Game = "BloxStrike SkinChanger", Version = "v1.0", Discord = "discord.gg/G9QSXsB9wY", ToggleKey = Enum.KeyCode.K, StartX = vp.X - 740, StartY = 100 })

-- Build sorted name lists
local knifeNames = {}
for k in pairs(knifeDatabase) do table.insert(knifeNames, k) end
table.sort(knifeNames)

local weaponNames = {}
for k in pairs(weaponDatabase) do table.insert(weaponNames, k) end
table.sort(weaponNames)

local gloveNames = {}
for k in pairs(gloveDatabase) do table.insert(gloveNames, k) end
table.sort(gloveNames)

-- Knives Tab: one section per knife, scrollable
local KnivesTab = Window:AddTab({ Name = "Knives" })
local side = false
for _, knifeName in ipairs(knifeNames) do
    local sec = KnivesTab:AddSection(knifeName, side)
    local skins = knifeDatabase[knifeName]
    sec:AddDropdown({ Name = "Skin", Options = skins, Default = skins[1], Callback = function(v)
        currentConfig.SelectedKnife = knifeName
        currentConfig.SelectedKnifeSkin = v
        applyKnifeReplacement("T Knife", knifeName, v)
        applyKnifeReplacement("CT Knife", knifeName, v)
        Window:Notify(knifeName .. " | " .. v .. " applied")
    end })
    side = not side
end

local function applyWeaponSkinNow(weaponName, skinName)
    -- Apply skin to currently equipped weapon in camera if it matches
    local camera = workspace.CurrentCamera
    local equippedWeapon = camera:FindFirstChild(weaponName)
    if equippedWeapon then
        local weaponModel = equippedWeapon:FindFirstChild("Weapon")
        if weaponModel then
            local SKINS_PATH = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")
            local skinFolder = SKINS_PATH:FindFirstChild(weaponName)
            if skinFolder then
                local specificSkin = skinFolder:FindFirstChild(skinName)
                if specificSkin then
                    local skinCameraFolder = specificSkin:FindFirstChild("Camera")
                    if skinCameraFolder then
                        local wearFolder = skinCameraFolder:FindFirstChild(currentConfig.WearLevel) or skinCameraFolder:FindFirstChild("Factory New")
                        if wearFolder then
                            local weaponHandle = weaponModel:FindFirstChild("Handle")
                            if weaponHandle then
                                for _, c in ipairs(weaponHandle:GetChildren()) do
                                    if c:IsA("SurfaceAppearance") then c:Destroy() end
                                end
                                local skinSurface = wearFolder:FindFirstChild("Handle")
                                if skinSurface then skinSurface:Clone().Parent = weaponHandle end
                            end
                            for _, part in ipairs(weaponModel:GetChildren()) do
                                if part:IsA("BasePart") and part.Name ~= "Handle" then
                                    local skinPart = wearFolder:FindFirstChild(part.Name)
                                    if skinPart then
                                        for _, c in ipairs(part:GetChildren()) do
                                            if c:IsA("SurfaceAppearance") then c:Destroy() end
                                        end
                                        skinPart:Clone().Parent = part
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Weapons Tab: one section per weapon, scrollable
local WeaponsTab = Window:AddTab({ Name = "Weapons" })
side = false
for _, weaponName in ipairs(weaponNames) do
    local sec = WeaponsTab:AddSection(weaponName, side)
    local skins = weaponDatabase[weaponName]
    sec:AddDropdown({ Name = "Skin", Options = skins, Default = skins[1], Callback = function(v)
        currentConfig.SelectedWeapon = weaponName
        currentConfig.SelectedWeaponSkin = v
        applyWeaponSkinNow(weaponName, v)
        Window:Notify(weaponName .. " | " .. v .. " applied")
    end })
    side = not side
end

local SettingsTab = Window:AddTab({ Name = "Settings" })
local GenSec = SettingsTab:AddSection("General")
GenSec:AddToggle({ Name = "Enable Skinchanger", Default = true, Callback = function(v) currentConfig.EnableSkinchanger = v end })
GenSec:AddDropdown({ Name = "Wear Level", Options = {"Factory New","Minimal Wear","Field-Tested","Well-Worn","Battle-Scarred"}, Default = "Factory New", Callback = function(v) currentConfig.WearLevel = v end })
local InfoSec = SettingsTab:AddSection("Info", "right")
InfoSec:AddLabel({ Text = "NoFear BloxStrike SkinChanger v1.0" })
InfoSec:AddLabel({ Text = "Skins apply at start of next round" })
InfoSec:AddLabel({ Text = "Press K to toggle UI" })

Window:Finalize()
startTextureMonitor()

end) -- runWithKeyCheck
