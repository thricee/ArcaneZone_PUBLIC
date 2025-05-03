local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local AntiSettings = require(script.Parent.Parent.Settings)
local Sword = AntiSettings.SwordPath

local SwordModule = {}
local SpecialMeshSizes = {
    Vector3.new(0, math.random(1, 18e8), math.random(1, 18e8)),
    Vector3.new(math.random(1, 18e8), math.random(1, 18e8), 0)
}

function SwordModule:AddSword(Player: Player)
    local PlayerSword = Sword:Clone()
    PlayerSword:SetAttribute('CheckSword', true)
    PlayerSword.Parent = Player.Backpack

    return PlayerSword
end

function SwordModule:CreateFakeHandle(SwordTool: Tool, Offset: CFrame, SwordSize: Vector3)
    local SwordHandle: BasePart = SwordTool.Handle

    if typeof(Offset) ~= "CFrame" then
        Offset = CFrame.new(0, 0, 0)
    end

    local FakeHandle = Instance.new('Part')
    local SpecialMesh = Instance.new('SpecialMesh')
    local WeldConstraint = Instance.new('WeldConstraint')
    local FakeHandleAttachment = Instance.new('Attachment')
    FakeHandleAttachment.Parent = FakeHandle
    SpecialMesh.Parent = FakeHandle
    SpecialMesh.Scale = SpecialMeshSizes[math.random(1, #SpecialMeshSizes)]
    WeldConstraint.Parent = FakeHandleAttachment
    WeldConstraint.Enabled = false
    WeldConstraint.Part0 = FakeHandle
    WeldConstraint.Part1 = SwordHandle

    repeat 
        task.wait()
        FakeHandle.Parent = AntiSettings.GarbagePath
    until FakeHandle.Parent
    FakeHandle:SetNetworkOwner()

    if Offset == CFrame.new(0, 0, 0) then
        if RunService:IsStudio() then
            CollectionService:AddTag(FakeHandle, '0')
        else
            CollectionService:AddTag(FakeHandle, game.JobId)
        end
    end
    
    task.wait()

    FakeHandle.Size = SwordSize or SwordHandle.Size
    FakeHandle.CFrame = SwordHandle.CFrame * Offset
    FakeHandle.Massless = true
    FakeHandle.CanCollide = false
    FakeHandle.Anchored = true

    local SwordAttachment = Instance.new('Attachment')
    SwordAttachment.Parent = SwordHandle

    local EquippedConnection: RBXScriptConnection
    EquippedConnection = SwordTool.Equipped:Connect(function()
        FakeHandle.CFrame = SwordHandle.CFrame * Offset
        FakeHandle.Anchored = false
        WeldConstraint.Enabled = true
    end)

    local UnequippedConnection: RBXScriptConnection
    UnequippedConnection = SwordTool.Unequipped:Connect(function()
        WeldConstraint.Enabled = false
        FakeHandle.Anchored = true
    end)

    SwordTool.Destroying:Connect(function()
        EquippedConnection:Disconnect()
        UnequippedConnection:Disconnect()
        SwordAttachment:Destroy()
        FakeHandle:Destroy()
    end)

    return FakeHandle
end

function SwordModule:GetLungeStatus(Sword: Tool)
    return Sword.GripUp == Vector3.new(1, 0, 0) or Sword.GripUp == Vector3.new(-1, 0, 0)
end

return SwordModule