---@class SandEv.MaterialLib : SandEv.Library
local MaterialLib = SandEv.Base:Library()
SandEv.Base.Material = MaterialLib

local TOOL_TEX_SIZE = 64
local toolMaterials = {}

surface.CreateFont('SEvToolTextureName', {
    font = 'Arial',
    size = 14,
    weight = 1000,
    blursize = 0,
    scanlines = 0,
    antialias = true
})

---@param rt ITexture
---@param name string
local function DrawToolTexture(rt, name)
    render.PushRenderTarget(rt)
        render.Clear(255, 255, 255, 255, true, true)

        cam.Start2D()
            surface.SetFont('SEvToolTextureName')

            local textW, textH = surface.GetTextSize(name)
            
            if textW > 60 then
                local words = name:Split(' ')

                if #words > 1 then
                    name = table.concat(words, '\n')
                else
                    name = name:sub(1, 8) .. '\n' .. name:sub(8)
                end

                textW, textH = surface.GetTextSize(name)
            end

            draw.DrawText(
                name, 
                'SEvToolTextureName', 
                TOOL_TEX_SIZE / 2, TOOL_TEX_SIZE / 2 - (textH / 2), 
                Color(0, 0, 0), 
                TEXT_ALIGN_CENTER
            )
        cam.End2D()
    render.PopRenderTarget()

    return rt
end

---Creates a material with a texture that mimics Hammer tool textures.
---@param text string The arial text to put into the center of the texture. This will always be uppercase.
---@return IMaterial
function MaterialLib:CreateToolMaterial(text)
    text = text:upper()

    local mat = toolMaterials[text]

    if mat then
        return mat
    end

    local rt = GetRenderTarget('sev_tool_' .. text, TOOL_TEX_SIZE, TOOL_TEX_SIZE)

    render.PushRenderTarget(rt)
    render.Clear(255, 255, 255, 255, true, true)
    render.PopRenderTarget()

    mat = CreateMaterial(rt:GetName(), 'UnlitGeneric', {
        ['$basetexture'] = rt:GetName(),
        ['$color2'] = '[1 1 1]',
        ['$translucent'] = 1,
        ['$nomip'] = 1,
        ['$alpha'] = 1
    })

    toolMaterials[text] = mat

    -- Draw to the tool texture outside of DrawTranslucent
    -- Sometimes the text won't be drawn if I don't do this
    timer.Simple(0.001, function()
        DrawToolTexture(rt, text)
    end)

    return mat
end