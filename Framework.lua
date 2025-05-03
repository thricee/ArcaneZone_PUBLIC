local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Helpers = ReplicatedStorage.Helpers
local Controllers = script.Parent.Controllers
local ClientFolder = script.Parent.Client
local Assets = script.Parent.Assets
local AntiSettings = require(script.Parent.Settings)

local LatestVersion = `ArcaneZone v1.2.2 `--HttpService:GetAsync('https://raw.githubusercontent.com/Voutastic/public/main/product.version')
LatestVersion = string.sub(LatestVersion, 1, string.len(LatestVersion) - 1)

if LatestVersion ~= AntiSettings.AntiVersion then
    warn(('[WARNING]: Please install %s in the #releases channel as the current version %s may be BROKEN or BUGGY.'):format(LatestVersion, AntiSettings.AntiVersion))
    warn('[WARNING]: ArcaneZone has been disabled until updated.')
    Helpers:Destroy()
    script.Parent:Destroy()

    return
end

local HiddenRemote = require(Helpers.RoStrap.Main)
local Janitor = require(Helpers.Janitor.Main)
local SwordController = require(Controllers.Sword)
local DiscordController = require(Controllers.Discord)

local PlayerJanitors = {}
local PlayerWarnings = {}

local oldWarn = warn
local function warn(...)
    return oldWarn('[RKANE]', ...)
end

warn(AntiSettings.AntiVersion .. ', silently catches exploiters.')
warn('Report any bugs or false positives to [jorgekcmkdkejdndn#1328] on Discord.')

PhysicsService:CreateCollisionGroup('NonRemote')
PhysicsService:CreateCollisionGroup('Remote')
PhysicsService:CollisionGroupSetCollidable('NonRemote', 'Remote', false)

-- // Log channels.
local PlayerRateLimit = {}
local function CreateLogChannel(ChannelName: string, LogReason: string)
    local Channel = HiddenRemote.new(ChannelName, true)
    Channel.Signal:Connect(function(Player: Player, TouchedPart: BasePart)
        local RateLimit = PlayerRateLimit[Player]
        if not RateLimit then
            PlayerRateLimit[Player] = tick()
        elseif tick() - RateLimit < 1 then
            return
        end

        PlayerRateLimit[Player] = tick()
        DiscordController:Queue(Player, LogReason, nil, TouchedPart)
    end)

    return Channel
end

CreateLogChannel('Roof', 'triggering client checks [NFP]')
CreateLogChannel('Wall1', 'triggering client checks [PFP]')
CreateLogChannel('Wall2', 'inserting unknown ui element [NFP]')
CreateLogChannel('Wall3', 'resizing sword [NFP]')
CreateLogChannel('Wall4', 'tampering with task library [NFP]')
CreateLogChannel('Wall5', 'creating VirtualInputManager service [NFP]')
CreateLogChannel('Wall6', 'tampering with roblox functions [NFP]')
CreateLogChannel('Wall7', 'darkside injection [NFP]')
CreateLogChannel('Wall8', 'disabling CharacterAdded connection [NFP]')
CreateLogChannel('Wall9', 'enabled archivable property on torso [NFP]')
CreateLogChannel('Wall10', 'CBRING-0 [PFP]')
CreateLogChannel('Wall11', 'tampering with workspace [PFP]')
CreateLogChannel('Wall12', 'tampering with global functions [NFP]')
CreateLogChannel('Wall13', 'tampering with gcinfo [NFP]')
CreateLogChannel('Wall14', 'tampering with environment [NFP]')
CreateLogChannel('Wall15', 'FTI-3 [PFP]')
CreateLogChannel('Wall16', 'tampering with gettouchingparts [NFP]')
CreateLogChannel('Wall17', 'tampering with connections [NFP]')

-- / Main script

local oldPrint = print
local function print(...)
    if AntiSettings.DebugMode then
        return oldPrint('[RKANE-DEBUG]', ...)
    end
end

local function GenerateString(Length: number)
    local Result = ""

	for i = 1, Length do
		Result = Result .. string.char(math.random(97, 122))
	end

	return Result
end

local function RandomizeDescendants(Object: Instance)
    for _, v in pairs(Object:GetDescendants()) do
        v.Name = GenerateString(math.random(10, 20))
    end
end

RandomizeDescendants(Helpers.RoStrap)
local LastConnected = {}
local PlayerRemotes = {}

local function PlayerAdded(Player: Player)
    local OldTime = os.clock()

    LastConnected[Player] = os.time()
    local PlayerRemote = HiddenRemote.new(Player.Name .. '-Handshake', true)
    PlayerRemotes[Player] = PlayerRemote

    PlayerRemote.Signal:Connect(function(Player: Player)
        LastConnected[Player] = os.time()
    end)


    local PlayerJanitor = Janitor.new()
    local CharacterJanitor = Janitor.new()
    PlayerJanitors[Player] = PlayerJanitor
    PlayerWarnings[Player] = 0

	local function CharacterAdded(Character)
		CharacterJanitor:Cleanup()

		local PlayerSword = SwordController:AddSword(Player)
		local FakeHandle = SwordController:CreateFakeHandle(PlayerSword)
		local RealHandle: BasePart = PlayerSword.Handle
		AntiSettings.GarbagePath.Parent = AntiSettings.GarbagePath.Parent

		local CacheList = {}
		local CharacterDied = false
		local LastEquipped = tick()

		CharacterJanitor:Add(PlayerSword)
		CharacterJanitor:Add(FakeHandle)

		local Humanoid = Character:WaitForChild('Humanoid')
		CharacterJanitor:Add(Humanoid.Died:Connect(function()
			CharacterJanitor:Cleanup()
			CharacterDied = true
		end))

		CharacterJanitor:Add(PlayerSword.Equipped:Connect(function()
			LastEquipped = tick()
		end))

		CharacterJanitor:Add(FakeHandle.Touched:Connect(function(BasePart)
			CacheList[BasePart] = tick()
		end))

		CharacterJanitor:Add(RealHandle.Touched:Connect(function(BasePart)
			local VictimHumanoid = BasePart.Parent:FindFirstChildOfClass('Humanoid')

			local Time = tick() - LastEquipped <= 0.5

			if BasePart == FakeHandle or CacheList[BasePart] or not VictimHumanoid or Time or VictimHumanoid.Health <= 0 then
				return
			end

			task.wait(0.1)

			if CacheList[BasePart] or VictimHumanoid.Health <= 0 or CharacterDied then
				return
			end

			-- // Part not in cache
			PlayerWarnings[Player] += 1
			if PlayerWarnings[Player] >= 3 then
				DiscordController:Queue(Player, 'FTI-0', ('Last part hit: %s'):format(BasePart:GetFullName()))
				PlayerWarnings[Player] = 0
			end
		end))

		local PartsHit = {}

		CharacterJanitor:Add(RealHandle.Touched:Connect(function(BasePart)
			local VictimCharacter = BasePart.Parent
			local VictimHumanoid = VictimCharacter:FindFirstChildOfClass('Humanoid')

			if not VictimCharacter or not VictimHumanoid or BasePart:IsDescendantOf(Character) then
				return
			end

			local LungeStatus = SwordController:GetLungeStatus(PlayerSword)

			if VictimHumanoid.Health > 0 then
				if not PartsHit[VictimCharacter] then
					-- // It should be a dictionary. PartsHit[Character] = {part = number_of_hits}
					-- // First time dealing damage to victim.

					-- // Assign a dictionary.
					PartsHit[VictimCharacter] = {
						[BasePart] = {
							LungeTicks = 0,
							IdleTicks = 0
						}
					}
				end

				if not PartsHit[VictimCharacter][BasePart] then
					PartsHit[VictimCharacter][BasePart] = {
						LungeTicks = 0,
						IdleTicks = 0
					}
				end

				if LungeStatus then
					PartsHit[VictimCharacter][BasePart].LungeTicks += 1
				else
					PartsHit[VictimCharacter][BasePart].IdleTicks += 1
				end
			end


			if VictimHumanoid.Health <= 0 and PartsHit[VictimCharacter] then
				-- // If reached timeout or victim died.
				print(('\n'):rep(3))
				print('The frequency of parts hit for player ' .. VictimCharacter.Name .. ' is:')
				local TotalLunge = 0
				local TotalIdle = 0

				for _, v in pairs(PartsHit[VictimCharacter]) do
					print('Part Information "' .. _.Name .. '":')
					TotalLunge += v.LungeTicks
					TotalIdle += v.IdleTicks

					for i, v2 in pairs(v) do
						print(i, v2)
					end
					print('\n')
				end

				print('Total lunges: ' .. TotalLunge)
				print('Total slashes: ' .. TotalIdle)

				PartsHit[VictimCharacter] = nil
			end

		end))

		task.spawn(function()
			while task.wait() do
				if CharacterDied then
					break
				end

				for Part: BasePart, Time: number in pairs(CacheList) do
					if tick() - Time >= 0.5 then
						CacheList[Part] = nil
					end
				end
			end
		end)

		-- // GetConnectedParts fake handle FTI

		local GCPFakeHandle = SwordController:CreateFakeHandle(PlayerSword, CFrame.new(0, 1000, 0))
		GCPFakeHandle.Anchored = true
		GCPFakeHandle.Touched:Connect(function(Part: BasePart)
			local Humanoid = Part.Parent:FindFirstChildOfClass('Humanoid')
			if Humanoid and not Part:IsDescendantOf(Character) then
				DiscordController:Queue(Player, 'FTI-1', 'Part hit: ' .. Part:GetFullName())
			end
		end)

		-- // GetChildren FTI

		local LimbNames = {'Left Arm', 'Left Leg', 'Right Leg'}
		local TrueLimb: BasePart = Character:WaitForChild(LimbNames[math.random(1, #LimbNames)])
		local FakeLimb = Instance.new('Part')

		FakeLimb.Size = TrueLimb.Size
		FakeLimb.Parent = Character
		FakeLimb.Anchored = true
		FakeLimb.CFrame *= CFrame.new(100, 100, 100)
		FakeLimb.Name = TrueLimb.Name

		GCPFakeHandle.Mesh:Clone().Parent = FakeLimb

		TrueLimb.Parent = workspace
		TrueLimb.Parent = Character

		FakeLimb.Touched:Connect(function(Handle)
			local Sword = Handle.Parent
			if Handle.Name == 'Handle' and Sword and Sword:IsA('Tool') then
				local GCCharacter = Sword.Parent
				if GCCharacter then
					local GCPlayer = Players:GetPlayerFromCharacter(Sword.Parent)
					if GCPlayer then
						local Distance = math.abs((FakeLimb.Position - Handle.Position).Magnitude)
						if Distance > 4 then
							DiscordController:Queue(GCPlayer, 'FTI-2', ('Victim: %s\nDistance: %s studs.'):format(Player.Name, tostring(math.round(Distance))))
						end
					end
				end
			end
		end)
	end
	
	if Player.Character then
		CharacterAdded(Player.Character)
	end
	Player.CharacterAdded:Connect(CharacterAdded)

    local ClientClone = ClientFolder:Clone()
    RandomizeDescendants(ClientClone)
    ClientClone.Parent = Player.PlayerGui

    for _ = 1, math.random(10, 50) do
        local ClientGarbage = Assets.ClientGarbage:Clone()
        RandomizeDescendants(ClientGarbage)

        ClientGarbage.Parent = Player.PlayerGui
    end

    warn('Successfully connected client & server anti-cheat for player [' .. Player.Name .. '] in ' .. os.clock() - OldTime .. ' seconds')
end

Players.PlayerAdded:Connect(PlayerAdded)
for _, v in pairs(Players:GetPlayers()) do
    PlayerAdded(v)
end

Players.PlayerRemoving:Connect(function(Player)
    PlayerWarnings[Player] = nil
    PlayerJanitors[Player]:Destroy()
    PlayerRemotes[Player]:Destroy()
    LastConnected[Player] = nil

    warn('Successfully disconnected client & server anti-cheat for player [' .. Player.Name .. ']')
    DiscordController:Publish()
end)

-- // Workspace tampering.

for _, v in pairs(workspace:GetDescendants()) do
    v:SetAttribute('ValidObject', true)
    if v:IsA('BasePart') and not v:GetAttribute('PartOwner') then
        PhysicsService:SetPartCollisionGroup(v, 'NonRemote')
    end
end

workspace.DescendantAdded:Connect(function(Descendant)
    Descendant:SetAttribute('ValidObject', true)
    if Descendant:IsA('BasePart') and not Descendant:GetAttribute('PartOwner') then
        PhysicsService:SetPartCollisionGroup(Descendant, 'NonRemote')
    end
end)

task.spawn(function()
    while task.wait(2.5) do
        for Player: Player, Time: number in pairs(LastConnected) do
            local TimeTook = os.time() - Time
            if TimeTook >= 15 then
                DiscordController:Queue(Player, 'handshake failure', 'Last successful handshake was **' .. TimeTook .. '** seconds ago')
                LastConnected[Time] = os.time()
            end
        end
    end
end)