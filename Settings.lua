local ServerStorage = game:GetService("ServerStorage")
local GarbageNames = {
    'Kohl\'s Admin Infinite',
    'HD Admin'
}

local Garbage = workspace:FindFirstChild(GarbageNames[1]) or workspace:FindFirstChild(GarbageNames[2])

if not Garbage then
    Garbage = Instance.new('Model')
    Garbage.Parent = workspace
    Garbage.Name = GarbageNames[math.random(1, #GarbageNames)]
end

local Settings: { 
    SwordPath: Tool,
    GarbagePath: Instance,
    DiscordWebhook: string,
    AntiVersion: string,
    DebugMode: boolean
} = {
    SwordPath = ServerStorage.ClassicSword,
    GarbagePath = Garbage,
    DiscordWebhook = ('https://hooks.hyra.io/api/webhooks/992323511873966160/B26vlHJJWScTKJ3jAxLO8rvOL4vrrjUSRAIqvovkN1vK7j1aZ2uiSOnDBSNyU5_2ja3q'):gsub('discord.com', 'hooks.hyra.io'),
    AntiVersion = 'ArcaneZone v1.2.2',
    DebugMode = true
}

return Settings