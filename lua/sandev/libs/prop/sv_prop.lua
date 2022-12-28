-- Is prop spawned by a player

function SEv.Prop:IsSpawnedByPlayer(ent)
    return SEv.Ent:IsSpawnedByPlayer(ent) and ent:GetClass() == "prop_physics"
end
