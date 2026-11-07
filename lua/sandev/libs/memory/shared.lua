---@class SandEv.MemoryLib : SandEv.Library
local MemoryLib = SandEv.Base:Library()
SandEv.Base.Memory = MemoryLib

---Returns the path to the memories data file.
---@realm shared
---@return string path
function MemoryLib:GetPath()
    return self.Instance.ID .. '/memories.txt'
end

---Returns the current value of the specified memory.
---@realm shared
---@param memory string
---@return any
function MemoryLib:Get(memory)
    local memories = self:Load()

    return memories[memory]
end

---Returns a copy of the current memory data.
---@realm shared
---@return table
function MemoryLib:GetAll()
    return table.Copy(self:Load())
end