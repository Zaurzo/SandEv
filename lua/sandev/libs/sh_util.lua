-- Some poorly made addons are overwriting the global function type() with numbers and
-- strings, so I created this ugly workaround. Better than nothing, I guess. - Xala
-- Note: It's possible that some type may have been accidentally left out, specifically
--       if it is an Entity.
local types = { -- https://wiki.facepunch.com/gmod/Enums/TYPE
    [TYPE_NONE] = "Invalid type",
    [TYPE_INVALID] = "Invalid type",
    [TYPE_NIL] = "nil",
    [TYPE_BOOL] = "boolean",
    [TYPE_LIGHTUSERDATA] = "light userdata",
    [TYPE_NUMBER] = "number",
    [TYPE_STRING] = "string",
    [TYPE_TABLE] = "table",
    [TYPE_FUNCTION] = "function",
    [TYPE_USERDATA] = "userdata",
    [TYPE_THREAD] = "thread",
    [TYPE_ENTITY] = "Entity", -- and entity sub-classes including Player, Weapon, NPC, Vehicle, CSEnt, and NextBot
    [TYPE_VECTOR] = "Vector",
    [TYPE_ANGLE] = "Angle",
    [TYPE_PHYSOBJ] = "PhysObj",
    [TYPE_SAVE] = "ISave",
    [TYPE_RESTORE] = "IRestore",
    [TYPE_DAMAGEINFO] = "CTakeDamageInfo",
    [TYPE_EFFECTDATA] = "CEffectData",
    [TYPE_MOVEDATA] = "CMoveData",
    [TYPE_RECIPIENTFILTER] = "CRecipientFilter",
    [TYPE_USERCMD] = "CUserCmd",
    [TYPE_SCRIPTEDVEHICLE] = "",
    [TYPE_MATERIAL] = "IMaterial",
    [TYPE_PANEL] = "Panel",
    [TYPE_PARTICLE] = "CLuaParticle",
    [TYPE_PARTICLEEMITTER] = "CLuaEmitter",
    [TYPE_TEXTURE] = "ITexture",
    [TYPE_USERMSG] = "bf_read",
    [TYPE_CONVAR] = "ConVar",
    [TYPE_IMESH] = "IMesh",
    [TYPE_MATRIX] = "VMatrix",
    [TYPE_SOUND] = "CSoundPatch",
    [TYPE_PIXELVISHANDLE] = "pixelvis_handle_t",
    [TYPE_DLIGHT] = "dlight_t",
    [TYPE_VIDEO] = "IVideoWriter",
    [TYPE_FILE] = "File",
    [TYPE_LOCOMOTION] = "CLuaLocomotion",
    [TYPE_PATH] = "PathFollower",
    [TYPE_NAVAREA] = "CNavArea",
    [TYPE_SOUNDHANDLE] = "IGModAudioChannel",
    [TYPE_NAVLADDER] = "CNavLadder",
    [TYPE_PARTICLESYSTEM] = "CNewParticleEffect",
    [TYPE_PROJECTEDTEXTURE] = "ProjectedTexture",
    [TYPE_PHYSCOLLIDE] = "PhysCollide",
    [TYPE_SURFACEINFO] = "SurfaceInfo",
    [TYPE_COUNT] = "48" -- "Amount of T YPE_* enums",
    --[TYPE_COLOR] = "Metatable of a Color.", -- Hack, not a valid type
}

local CSEntMetaTable

if CLIENT then
    CSEntMetaTable = FindMetaTable("CSEnt")
end

function SEv.Util:Type(any)
    local typeID = TypeID(any)

    if types[typeID] == "Entity" then
        if any:IsPlayer() then
            return "Player"
        elseif any:IsVehicle() then
            return "Vehicle"
        elseif any:IsNPC() then
            return "NPC"
        elseif any:IsWeapon() then
            return "Weapon"
        elseif any:IsNextBot() then
            return "NextBot"
        elseif CLIENT and CSEntMetaTable == debug.getmetatable(any) then
            return "CSEnt"
        end
    end

    return types[typeID]
end

-- Some libs are not meant to be called directly, devs must create their ours instances of them.
function SEv.Util:BlockDirectLibCalls(lib)
    lib = setmetatable({}, {
        __newindex = function(self, key, value)
            if not self[key] then
                if isfunction(value) then
                    rawset(self, key, function(self, ...)
                        if self == lib then
                            print("This lib is not meant to be used directly! Use table.Copy() to clone it into a new table.")
                            return
                        end
    
                        value(self, ...)
                    end)
                else
                    rawset(self, key, value)
                end
            end
        end
    })
end