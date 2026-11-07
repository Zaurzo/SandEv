AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

---@generic T
---@param className `T`
---@return T[]
local function FindEntsBasedOn(className)
    local entities = {}

    for _, ent in ents.Iterator() do
        local class = ent:GetClass()

        if class == className or scripted_ents.IsBasedOn(class, className) then
            table.insert(entities, ent)
        end
    end

    return entities
end

net.cheap.Receive('sandev_prepare_marker_data', function(len, ply)
    local instanceID = net.ReadString()
    local instance = SandEv:GetInstance(instanceID)

    if not instance then return end

    net.cheap.Start('sandev_marker_data')

    for _, marker in ipairs(FindEntsBasedOn('sev_marker')) do
        net.WriteEntity(marker)

        marker:WriteData()
    end

    net.Broadcast()
end)