function SEv.Material:FixVertexLitMaterial(materialName)
    local material = Material(materialName)

    if not material then return material end
 
    local strImage = material:GetName() .. "_fixed"

    if string.find(material:GetShader(), "VertexLitGeneric") or string.find(material:GetShader(), "Cable") then
        local materialFixed = Material(strImage)

        if not materialFixed:IsError() then return materialFixed end

        local texture = material:GetString("$basetexture")

        if texture then
            local translucent = bit.band(material:GetInt("$flags"), 2097152)

            local params = {}
            params[ "$basetexture" ] = texture

            if translucent == 2097152 then
                params[ "$translucent" ] = 1
            end

            material = CreateMaterial(strImage, "VertexLitGeneric", params)
        end
    end

    return material
end