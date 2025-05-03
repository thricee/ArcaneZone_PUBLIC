local ReplicatedStorage = game.GetService(game, "ReplicatedStorage")
local StarterPlayer = game.GetService(game, "StarterPlayer")

require(script.Parent.FindFirstChildOfClass(script.Parent, 'ModuleScript'))
task.wait()
ReplicatedStorage.Helpers.RoStrap.Destroy(ReplicatedStorage.Helpers.RoStrap)
script.Parent.Destroy(script.Parent)