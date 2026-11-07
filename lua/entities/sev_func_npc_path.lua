AddCSLuaFile()

ENT.Base = 'sev_func_path'

if CLIENT then return end

---@param npc NPC
---@param running? boolean
function ENT:Follow(npc, running)
    self._npc_running = self._npc_running or {}
    self._npc_running[npc] = running or nil

    self.BaseClass.Follow(self, npc)
end

local function GetSchedule(path, npc)
    local running = path._npc_running and path._npc_running[npc]

    return running and SCHED_FORCED_GO_RUN or SCHED_FORCED_GO
end

function ENT:ForceGo(npc, point)
    npc:SetLastPosition(point.pos)
    npc:SetSchedule(GetSchedule(self, npc))
end

---@param npc NPC
function ENT:OnPathThink(npc, point)
    if npc:GetCurrentSchedule() ~= GetSchedule(self, npc) then
        self:ForceGo(npc, point)
    end
end

ENT.OnPathAdvance = ENT.ForceGo