local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local AntiSettings = require(script.Parent.Parent.Settings)
local DiscordModule = {}
local PlaceName = MarketplaceService:GetProductInfo(game.PlaceId).Name

local LoggedList = {}
local OldWarn = warn
local function warn(...)
    return OldWarn('[RKANE LOG]', ...)
end

function DiscordModule:LogSilent(Player: Player, Reason: string, AdditionalInformation: string, TouchedPart: BasePart)

    if LoggedList[Player] and tick() - LoggedList[Player] <= 0.5 then
        return
    end

    LoggedList[Player] = tick()
    local Handler = 'Server'

    if TouchedPart then
        Handler = 'Client'
    end

    local Description = "A player [%s](https://www.roblox.com/users/%s/profile) has been silently detected for **%s** at [%s](https://www.roblox.com/games/%s/)"
    Description = Description:format(Player.Name, Player.UserId, Reason, PlaceName, game.PlaceId)

    local DataTemplate = {
        ["embeds"] = {{
            ["title"] = 'Arcane Zone',
            ["description"] = Description,
            ["color"] = tonumber(0x58B9FF),
            ['fields'] = {
                {
                    ['name'] = 'Mode',
                    ['value'] = 'Silent',
                    ['inline'] = true
                },
                {
                    ['name'] = 'Handler',
                    ['value'] = Handler,
                    ['inline'] = true
                },
                {
                    ['name'] = 'Time',
                    ['value'] = ('<t:%s:F>'):format(tostring(math.floor(os.time()))),
                    ['inline'] = true
                },
                {
                    ['name'] = 'Additional Information',
                }
            },
            ['footer'] = {
                ["text"] = AntiSettings.AntiVersion
            }
        }}
    }

    local InfoField = DataTemplate.embeds[1].fields[4]
    if AdditionalInformation then
        InfoField.value = AdditionalInformation
    elseif Handler == 'Client' then
        InfoField.value = 'Middleman: ' .. TouchedPart:GetFullName()
    end

    local DiscordWebhook = ('https://discord.com/api/webhooks/1005414400640958554/7vNmhKjZFyQ_rR6FccCkKU8H0qgRf67kvXENDtwzXEJ8AT8MflUcoqaPG6C_0Dch_5dl'):gsub('discord.com', 'hooks.hyra.io') 

    local S, E = pcall(function()
        warn(('%s has been logged for %s'):format(Player.Name, Reason))
        HttpService:PostAsync(DiscordWebhook, HttpService:JSONEncode(DataTemplate))
    end)

    if not S then
        warn(E)
    end
    
end

local PublishQueue = {}
local WaitingForPublish = false

function DiscordModule:Queue(Player: Player, Reason: string, AdditionalInformation: string, TouchedPart: BasePart)

    -- // Create new list.
    if not PublishQueue[Player] then
        PublishQueue[Player] = {}
    end

    if not PublishQueue[Player][Reason] then
        local InformationTable = {
            REPETITIONS = 0,
            ADDITIONAL_INFORMATION = AdditionalInformation,
            TOUCHED_PART = TouchedPart
        }

        PublishQueue[Player][Reason] = InformationTable
    end

    PublishQueue[Player][Reason].REPETITIONS += 1
    if not WaitingForPublish then
        WaitingForPublish = true
        task.delay(30, function()
            self:Publish()
        end)
    end
end

function DiscordModule:Publish()
    WaitingForPublish = false
    for Player: Player, PlayerLogs in pairs(PublishQueue) do
        for Reason: string, InformationTable: {REPETITIONS: number, ADDITIONAL_INFORMATION: string, TOUCHED_PART: BasePart} in pairs(PlayerLogs) do
            local Handler = 'Server'

            if InformationTable.TOUCHED_PART then
                Handler = 'Client'
            end

            local Description = "A player [%s](https://www.roblox.com/users/%s/profile) has been silently detected for **%s** at ||[%s](https://www.roblox.com/games/%s/)||"
            Description = Description:format(Player.Name, Player.UserId, Reason, PlaceName, game.PlaceId)

            local DataTemplate = {
                ["embeds"] = {{
                    ["title"] = 'Arcane Zone',
                    ["description"] = Description,
                    ["color"] = tonumber(0x58B9FF),
                    ['fields'] = {
                        {
                            ['name'] = 'Mode',
                            ['value'] = 'Silent',
                            ['inline'] = true
                        },
                        {
                            ['name'] = 'Handler',
                            ['value'] = Handler,
                            ['inline'] = true
                        },
                        {
                            ['name'] = 'Time',
                            ['value'] = ('<t:%s:F>'):format(tostring(math.floor(os.time()))),
                            ['inline'] = true
                        },
                        {
                            ['name'] = 'Repetitions',
                            ['value'] = tostring(InformationTable.REPETITIONS),
                            ['inline'] = true
                        },
                        {
                            ['name'] = 'Additional Information',
                            ['inline'] = true
                        }
                    },
                    ['footer'] = {
                        ["text"] = AntiSettings.AntiVersion
                    }
                }}
            }

            local InfoField = DataTemplate.embeds[1].fields[5]
            if InformationTable.ADDITIONAL_INFORMATION then
                InfoField.value = InformationTable.ADDITIONAL_INFORMATION
            elseif Handler == 'Client' then
                InfoField.value = 'Middleman: ' .. InformationTable.TOUCHED_PART:GetFullName()
            end

            local S, E = pcall(function()
                warn(('%s has been logged for %s'):format(Player.Name, Reason))
                HttpService:PostAsync(AntiSettings.DiscordWebhook, HttpService:JSONEncode(DataTemplate))
                PublishQueue[Player][Reason] = nil
            end)

            if not S then
                warn(E)
            end
        end
    end
end

return DiscordModule