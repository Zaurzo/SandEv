include('shared.lua')

local EffectLib = SandEv.Base.Effect

-- Laser beam

local beamMaterials = {
    Material('sprites/physbeam'),
    Material('sprites/physbeama'),
    Material('sprites/physgbeamb')
}

-- Requires: 3D rendering context
-- Beam types from 1 (thinner) to 3 (larger)
-- Code adapted from https://maurits.tv/data/garrysmod/wiki/wiki.garrysmod.com/indexffa5.html
function EffectLib:CreateBeam(startPos, endPos, beamType, color)
    local beam = beamMaterials[beamType]

    -- setup our variables
    local start_pos = startPos
    local end_pos = endPos
    local dir = (end_pos - start_pos)
    local increment = dir:Length() / 12

    dir:Normalize()
     
    -- set material
    render.SetMaterial(beam)
     
    -- start the beam with 14 points
    render.StartBeam(14)
     
    -- add start
    render.AddBeam(
        start_pos, -- Start position
        32, -- Width
        CurTime(), -- Texture coordinate
        color -- Color
    )
     
    for i = 1, 12 do
        -- get point
        local point = (start_pos + dir * (i * increment)) + VectorRand() * math.random(1, 16)
     
        -- texture coords
        local tcoord = CurTime() + (1 / 12) * i
     
        -- add point
        render.AddBeam(
            point,
            32,
            tcoord,
            color
        )
    end
     
    -- add the last point
    render.AddBeam(
        end_pos,
        32,
        CurTime() + 1,
        color
    )
     
    -- finish up the beam
    render.EndBeam()
end