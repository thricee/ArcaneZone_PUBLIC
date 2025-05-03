local CollectionService = game.GetService(game, "CollectionService")
local PhysicsService = game.GetService(game, "PhysicsService")
local Players = game.GetService(game, "Players")
local ContentProvider = game.GetService(game, "ContentProvider")
local RunService = game.GetService(game, "RunService")
local ReplicatedStorage = game.GetService(game, "ReplicatedStorage")
local StarterGui = game.GetService(game, "StarterGui")
local UserInputService = game.GetService(game, 'UserInputService')
local Helpers = ReplicatedStorage.Helpers
local HiddenRemote = require(Helpers.RoStrap.FindFirstChildOfClass(Helpers.RoStrap, 'ModuleScript'))
local Janitor = require(Helpers.Janitor.Main)
local Client: Player = Players.LocalPlayer

local Channels = {
    ['NO_FALSE_POSITIVE'] = HiddenRemote:Get('Roof'),
    ['POSSIBLE_FALSE_POSITIVE'] = HiddenRemote:Get('Wall1'),
    ['UI_OBJECT'] = HiddenRemote:Get('Wall2'),
    ['RESIZE'] = HiddenRemote:Get('Wall3'),
    ['HOOKING_TASK_LIBRARY'] = HiddenRemote:Get('Wall4'),
    ['VIRTUAL_INPUT_MANAGER'] = HiddenRemote:Get('Wall5'),
    ['HOOKING_ROBLOX_FUNCTIONS'] = HiddenRemote:Get('Wall6'),
    ['XEN_ZONE'] = HiddenRemote:Get('Wall7'),
    ['CHARACTER_CONNECTION_DISABLED'] = HiddenRemote:Get('Wall8'),
    ['ARCHIVABLE_ENABLED'] = HiddenRemote:Get('Wall9'),
    ['CBRING_V1'] = HiddenRemote:Get('Wall10'),
    ['WORKSPACE_TAMPERING'] = HiddenRemote:Get('Wall11'),
    ['HOOKING_GLOBAL_FUNCTIONS'] = HiddenRemote:Get('Wall12'),
    ['MANIPULATING_GCINFO'] = HiddenRemote:Get('Wall13'),
    ['ENVIRONMENT_TAMPERING'] = HiddenRemote:Get('Wall14'),
    ['TOUCH_DESYNC'] = HiddenRemote:Get('Wall15'),
    ['TOUCHING_PARTS'] = HiddenRemote:Get('Wall16'),
    ['CONNECTIONS'] = HiddenRemote:Get('Wall17'),
}

if not game.IsLoaded(game) then
    game.Loaded.Wait(game.Loaded)
end

local Once = game.Loaded.Once
local Connect = game.Loaded.Connect
local SignalWait = game.Loaded.Wait
local PropertyChanged = game.GetPropertyChangedSignal

local GetChildren = game.GetChildren
local WaitForChild = game.WaitForChild
local GetAttribute = game.GetAttribute
local FindFirstChildOfClass = game.FindFirstChildOfClass
local FindFirstChild = game.FindFirstChild
local IsA = game.IsA
local Clone = game.Clone
local Destroy = game.Destroy
local SetAttribute = game.SetAttribute

local CachedTick = tick
local CachedPCall = pcall
local CachedInfo = gcinfo
local CachedWait = task.wait
local CachedSpawn = task.spawn
local CachedDelay = task.delay
local CachedGetFenv = getfenv
local CachedTostring = tostring

local ScriptEnvironment = CachedGetFenv()
local CurrentScript = ScriptEnvironment.script
ScriptEnvironment.script = {}

local NewVector3 = Vector3.new
local Dot = NewVector3().Dot

local math = math
local acos = math.acos

local NewestEnv

local CreateInstance = Instance.new
local StringFind = ('').find

local taskWait = function(WaitTime: number)
    local OldTime = CachedTick()

    if typeof(WaitTime) ~= "number" then
        WaitTime = 0
    end

    repeat
        SignalWait(RunService.Heartbeat)
    until CachedTick() - OldTime >= WaitTime

    return CachedTick() - OldTime
end


local function SafeInstance(InstanceName: string, Parent: Instance)
    local Instance = CreateInstance(InstanceName, Parent)
    if not Instance or Instance.ClassName ~= InstanceName or not Instance.IsA(Instance, InstanceName) then
        -- // Hooking instance.new
        rawget(Channels, 'HOOKING_GLOBAL_FUNCTIONS'):Fire()
    end

    local InstanceClone = Clone(Instance)
    SetAttribute(InstanceClone, 'ValidObject', true)
    Destroy(InstanceClone)

    if InstanceClone.Parent then
        -- // Hooking Destroy
        rawget(Channels, 'HOOKING_GLOBAL_FUNCTIONS'):Fire()
    end

    SetAttribute(Instance, 'ValidObject', true)
    return Instance
end

local ConnectionsTable = {}

local function ProtectedConnect(Instance: Instance, Signal: RBXScriptSignal, Callback: () -> (), SignalName: string, GetSignal: () -> ())
    if tostring(nil) ~= 'nil' or tostring ~= CachedTostring then
        rawget(Channels, 'HOOKING_GLOBAL_FUNCTIONS'):Fire()
    end

    if SignalName and CachedTostring(Signal) ~= 'Signal ' .. SignalName then
        -- // Connection Tampering
        rawget(Channels, 'CONNECTIONS'):Fire()
    end

    local ConnectionInfo = {
        ['Instance'] = Instance,
        ['Connection'] = Connect(Signal, Callback),
        ['SignalName'] = SignalName,
        ['Callback'] = Callback,
        ['GetSignal'] = GetSignal
    }

    if not rawget(ConnectionsTable, Instance) then
        rawset(ConnectionsTable, Instance, ConnectionInfo)
    end
end

local SetPartCollisionGroup = PhysicsService.SetPartCollisionGroup
local GetTagged = CollectionService.GetTagged
local GetPlayerFromCharacter = Players.GetPlayerFromCharacter

local IsStudio = RunService.IsStudio(RunService)

local function EmptyFunction()
    
end

local function AngleBetween(Part1: BasePart, Part2: BasePart)
    return acos(Dot(Part1.CFrame.LookVector), (Part2.Position - Part1.Position).Unit)
end

local function TableAverage(Table: table)
    local Sum = 0
    for _, Num in pairs(Table) do
        Sum += Num
    end
    return Sum / #Table
end

local function FindPlayerFakeHandle(Player: Player)
    local Tagged = GetTagged(CollectionService, game.JobId)

    if IsStudio then
        Tagged = GetTagged(CollectionService, '0')
    end
    
    for _, Handle: BasePart in ipairs(Tagged) do
        local HandleAttachment: Attachment = Handle.Attachment
        local HandleWeld: WeldConstraint = FindFirstChildOfClass(HandleAttachment, 'WeldConstraint')
        local RealHandle = HandleWeld.Part1

        if not RealHandle.Parent or not RealHandle.Parent.Parent then
            continue
        end

        local Sword: Tool = RealHandle.Parent
        local Character: Model = Sword.Parent

        if GetPlayerFromCharacter(Players, Character) == Player then
            return Handle, RealHandle
        end
    end
end

--[[
    MY METHODS
]]
local OldConnection: RBXScriptConnection
local function PlayerAdded(Player: Player)

    --[[
        OTHER PLAYERS
    ]]

    local PlayerCharacter = Player.Character or SignalWait(Player.CharacterAdded)
    local PlayerAddedJanitor = Janitor.new()

    local function CharacterAdded(_)
        local Character = Player.Character
        PlayerAddedJanitor:Cleanup()

        local Torso = WaitForChild(Character, "Torso")
        Torso.Archivable = false

        local Signal = PropertyChanged(Torso, 'Archivable')
        ProtectedConnect(Torso, Signal, function()
            if Torso.Archivable then
                rawget(Channels, 'ARCHIVABLE_ENABLED'):Fire()
            end

            Torso.Archivable = false
        end, nil, function()
            -- // Get signal function
            return PropertyChanged(Torso, 'Archivable')
        end)

        for _, v in pairs(GetChildren(Character)) do
            if StringFind(v.Name, 'Arm') or StringFind(v.Name, 'Leg') then
                if IsA(v, 'BasePart') then
                    ProtectedConnect(v, PropertyChanged(v, 'CFrame'), function()
                        rawget(Channels, 'CBRING_V1'):Fire()
                    end, nil, function()
                        -- // Get signal function
                        return PropertyChanged(v, 'CFrame')
                    end)
                end
            end
        end
    end

    CharacterAdded(PlayerCharacter)
    ProtectedConnect(Player, Player.CharacterAdded, CharacterAdded, 'CharacterAdded')
end

local LastCharacterAdded = CachedTick()
local function CharacterAdded(Character)

    --[[
        OUR CHARACTER
    ]]

    local OldTick = CachedTick()
    LastCharacterAdded = OldTick
    local ClientCharacter = Client.Character or Character or SignalWait(Client.CharacterAdded)
    local Humanoid = WaitForChild(ClientCharacter, 'Humanoid')

    if OldConnection then
        OldConnection.Disconnect(OldConnection)
    end

    local DiedConnection = Humanoid.Died
    ProtectedConnect(Humanoid, DiedConnection, function()
        CachedDelay(Players.RespawnTime * 2, function()
            if LastCharacterAdded == OldTick then
                rawget(Channels, 'CHARACTER_CONNECTION_DISABLED'):Fire()
            end
        end)
    end, 'Died')

    ProtectedConnect(ClientCharacter, ClientCharacter.childAdded, function(Sword: Tool)
        if IsA(Sword, 'Tool') then
            local RealHandle: BasePart = Sword.Handle
            if RealHandle and GetAttribute(Sword, 'CheckSword') then
                do
                    local SizeSignal = PropertyChanged(RealHandle, 'Size')
                    ProtectedConnect(RealHandle, SizeSignal, function()
                        rawget(Channels, 'RESIZE'):Fire()
                    end, nil, function()
                        -- // Get signal.
                        return PropertyChanged(RealHandle, 'Size')
                    end)

                    if RealHandle.Size ~= Vector3.new(1, 0.8, 4) then
                        rawget(Channels, 'RESIZE'):Fire()
                    end
                end

                do
                    local CachedHits = {}
                    local LastEquipped = CachedTick()
                    local Warnings = 0

                    ProtectedConnect(Sword, Sword.Equipped, function()
                        LastEquipped = CachedTick()
                    end, 'Equipped')

                    local FakeHandle = FindPlayerFakeHandle(Client)
                    OldConnection = ProtectedConnect(FakeHandle, FakeHandle.LocalSimulationTouched, function(BasePart: BasePart)
                        local OldTick = CachedTick()
                        rawset(CachedHits, BasePart, OldTick)

                        CachedDelay(0.4, function()
                            if rawget(CachedHits, BasePart) == OldTick then
                                rawset(CachedHits, BasePart, nil)
                            end
                        end)
                    end, 'LocalSimulationTouched')

                    ProtectedConnect(RealHandle, RealHandle.LocalSimulationTouched, function(BasePart: BasePart)
                        if CachedTick() - LastEquipped > 0.1 then
                            local VictimCharacter = BasePart.Parent
                            local VictimPlayer = GetPlayerFromCharacter(Players, VictimCharacter)
                            if VictimPlayer and VictimPlayer ~= Client then
                                local Humanoid = FindFirstChildOfClass(VictimCharacter, 'Humanoid')
                                if Humanoid and Humanoid.Health > 0 then
                                    taskWait(0.1)

                                    if not rawget(CachedHits, BasePart) then
                                        Warnings += 1
                                        if Warnings > 5 then
                                            rawget(Channels, 'TOUCH_DESYNC'):Fire()
                                        end

                                        CachedDelay(1, function()
                                            Warnings = math.clamp(Warnings - 1, 0, 10)
                                        end)
                                    end

                                end
                            end
                        end
                    end, 'LocalSimulationTouched')
                end
            end
        end
    end, 'childAdded')
end

if Client.Character then
    CharacterAdded(Client.Character)
end

ProtectedConnect(Client, Client.CharacterAdded, CharacterAdded, 'CharacterAdded')
ProtectedConnect(Players, Players.PlayerAdded, PlayerAdded, 'PlayerAdded')

for _, v in pairs(Players.GetPlayers(Players)) do
    if v ~= Client then
        PlayerAdded(v)
        if v.Character and v.Character.Parent then
            for _, v2 in pairs(GetChildren(v.Character)) do
                if IsA(v2, 'BasePart') and v2.Name ~= 'Head' and FindFirstChildOfClass(v2, 'SpecialMesh') then
                    local FakeLimb = v2
                    for _, v3 in pairs(GetChildren(v.Character)) do
                        if IsA(v3, 'BasePart') and v3.Name == FakeLimb.Name and v3 ~= FakeLimb then
                            local RealLimb = v3
                            RealLimb.Parent = workspace
                            RealLimb.Parent = v.Character
                        end
                    end
                end
            end
        end
    end
end

-- // Loop.
local FakeHumanoid = SafeInstance('Humanoid')
local FakeHumanoidPart: BasePart = SafeInstance('Part')
FakeHumanoidPart.Name = 'Humanoid'

local PreloadLogged = false
local HealthIndex = false
local VirtualUser = false
local RobloxFunctionHook = false
local TaskHook = false
local GlobalHook = false
local EnvironmentTamper = false
local GCInfoTampering = false
local PCallCheck = false
local TouchingParts = false

local function LoopCheck()
    if not HealthIndex then
        FakeHumanoid.Health = 100
        if FakeHumanoid.Health ~= 100 then
            rawget(Channels, 'XEN_ZONE'):Fire()
            HealthIndex = true
        end
    
        if CachedPCall(function() return FakeHumanoidPart.Health end) then
            rawget(Channels, 'XEN_ZONE'):Fire()
            HealthIndex = true
        end
    end

    if not PreloadLogged then
        ContentProvider.PreloadAsync(ContentProvider, {game.CoreGui}, function(AssetId: string)
            if StringFind(AssetId, 'rbxassetid://') or StringFind(AssetId, 'rbxasset://DexStorage.rbxm') then
                if not RunService.IsStudio(RunService) and not PreloadLogged then
                    rawget(Channels, 'UI_OBJECT'):Fire()
                    PreloadLogged = true
                end
            end
        end)

        ContentProvider.preloadAsync(ContentProvider, {game.CoreGui}, function(AssetId: string)
            if StringFind(AssetId, 'rbxassetid://') or StringFind(AssetId, 'rbxasset://DexStorage.rbxm') then
                if not RunService.IsStudio(RunService) and not PreloadLogged then
                    rawget(Channels, 'UI_OBJECT'):Fire()
                    PreloadLogged = true
                end
            end
        end)
    end
    
    if not VirtualUser then
        if game.FindService(game, 'VirtualInputManager') then
            rawget(Channels, 'VIRTUAL_INPUT_MANAGER'):Fire()
            VirtualUser = true
        end
    end

    if not TaskHook then
        if CachedWait ~= task.wait or CachedSpawn ~= task.spawn or CachedDelay ~= task.delay then
            rawget(Channels, 'HOOKING_TASK_LIBRARY'):Fire()
            TaskHook = true
        end
    end

    if not RobloxFunctionHook then
        if GetChildren ~= game.GetChildren or GetAttribute ~= game.GetAttribute or FindFirstChildOfClass ~= game.FindFirstChildOfClass or WaitForChild ~= game.WaitForChild or IsA ~= game.IsA or SetPartCollisionGroup ~= PhysicsService.SetPartCollisionGroup or CreateInstance ~= Instance.new then
            rawget(Channels, 'HOOKING_ROBLOX_FUNCTIONS'):Fire()
            RobloxFunctionHook = true
        end
    end

    if not GlobalHook then
        if CachedTick ~= tick or CachedInfo ~= gcinfo or CachedPCall ~= pcall then
            rawget(Channels, 'HOOKING_GLOBAL_FUNCTIONS'):Fire()
            GlobalHook = true
        end
    end

    if not EnvironmentTamper and NewestEnv then
        if CachedGetFenv() ~= NewestEnv then
            rawget(Channels, 'ENVIRONMENT_TAMPERING'):Fire()
            EnvironmentTamper = true
        end
    end

    if not GCInfoTampering then
        if gcinfo() ~= collectgarbage('count') then
            rawget(Channels, 'MANIPULATING_GCINFO'):Fire()
            GCInfoTampering = true
        end
    end

    if not PCallCheck then
        local S, E = CachedPCall(function()
            return false
        end)

        if not S and not E then
            rawget(Channels, 'HOOKING_GLOBAL_FUNCTIONS'):Fire()
            PCallCheck = true
        end
    end

    if not TouchingParts then
        local Namecall = FakeHumanoidPart:GetTouchingParts()
        local Index = FakeHumanoidPart.GetTouchingParts(FakeHumanoidPart)
        if typeof(Namecall) ~= 'table' or typeof(Index) ~= "table" then
            rawget(Channels, 'TOUCHING_PARTS'):Fire()
            TouchingParts = true
        else
            for _, v in ipairs(Index) do
                if not table.find(Namecall, v) then
                    rawget(Channels, 'TOUCHING_PARTS'):Fire()
                    TouchingParts = true
                end
            end

            for _, v in ipairs(Namecall) do
                if not table.find(Index, v) then
                    rawget(Channels, 'TOUCHING_PARTS'):Fire()
                    TouchingParts = true
                end
            end
        end
    end
end

ProtectedConnect(workspace, workspace.DescendantAdded, function(Descendant: Instance)
    if IsA(Descendant, 'BasePart') and not GetAttribute(Descendant, 'PartOwner') then
        SetPartCollisionGroup(PhysicsService, Descendant, 'NonRemote')
    end

    CachedDelay(2, function()
        taskWait(5)
        if not GetAttribute(Descendant, 'ValidObject') and Descendant.Parent and not IsA(Descendant, 'ValueBase') and not IsA(Descendant, 'Animation') and not IsA(Descendant, 'Sound') then
            rawget(Channels, 'WORKSPACE_TAMPERING'):Fire()
        end
    end)
end, 'DescendantAdded')

local INFO_Tick = CachedTick()
local INFO_Table = {}
local CG_Table = {}

ProtectedConnect(RunService, RunService.Heartbeat, function()
    if CachedTick() - INFO_Tick >= 10 then
        local INFO_Average = TableAverage(INFO_Table)
        local CG_Average = TableAverage(CG_Table)
        INFO_Table = {}
        INFO_Tick = CachedTick()

        if INFO_Average < 400 or CG_Average < 400 then
            rawget(Channels, 'MANIPULATING_GCINFO'):Fire()
        end
    else
        table.insert(CG_Table, collectgarbage('count'))
        table.insert(INFO_Table, gcinfo())
    end
end, 'Heartbeat')

local LastHandshake = CachedTick()
CachedSpawn(function()
    while taskWait(0.1) do
        CachedSpawn(LoopCheck)
        CachedSpawn(function()
            for Instance: Instance, ConnectionInfo: {Instance: Instance, Connection: RBXScriptConnection, SignalName: string, Callback: () -> (), GetSignal: () -> ()} in pairs(ConnectionsTable) do
                if Instance.Parent then
                   -- // Instance is still in game.
                    ConnectionInfo.Connection:Disconnect() 
                    rawset(ConnectionsTable, Instance, nil)

                    local Signal: RBXScriptSignal

                    if typeof(ConnectionInfo.GetSignal) == "function" then
                        Signal = ConnectionInfo.GetSignal()
                        if typeof(Signal) ~= "RBXScriptSignal" then
                            rawget(Channels, 'CONNECTIONS'):Fire()
                            Signal = Instance[ConnectionInfo.SignalName]
                        end
                    else
                        Signal = Instance[ConnectionInfo.SignalName]
                    end

                    ProtectedConnect(Instance, Signal, ConnectionInfo.Callback, ConnectionInfo.SignalName, ConnectionInfo.GetSignal)
                end
            end
        end)
        CachedSpawn(function()
            if CachedTick() - LastHandshake >= 3 then
                HiddenRemote:Get(Client.Name .. '-Handshake'):Fire()
                LastHandshake = CachedTick()
            end
        end)
    end
end)

NewestEnv = CachedGetFenv()

return setmetatable({{}}, {__iter = function(Array: table)
    table.insert(Array, {})
    return next, Array
end})