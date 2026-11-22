---@class SandEv.MaterialLib : SandEv.Library
local MaterialLib = SandEv.Base:Library()
SandEv.Base.Material = MaterialLib

local TOOL_TEX_SIZE = 64
local RENDER_HOOK_NAME = 'sandev_draw_tool_textures'

local toolMaterials = {}
local toolTextureQueue = {}

surface.CreateFont('SEvToolText', {
    font = 'Arial',
    size = 14,
    weight = 1000,
    blursize = 0,
    scanlines = 0,
    antialias = true
})

---@param rt ITexture
---@param text string
local function DrawToolTexture(rt, text)
    render.PushRenderTarget(rt)
        render.Clear(255, 255, 255, 255, true, true)

        cam.Start2D()
            local mkup = markup.Parse(
                '<font=SEvToolText><colour=0,0,0>' .. text .. '</font></colour>',
                60
            )

            mkup:Draw(
                TOOL_TEX_SIZE / 2, TOOL_TEX_SIZE / 2,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                255, 
                TEXT_ALIGN_CENTER
            )
        cam.End2D()
    render.PopRenderTarget()

    return rt
end

local function DrawToolTextureQueue()
    for text, rt in pairs(toolTextureQueue) do
        DrawToolTexture(rt, text)

        toolTextureQueue[text] = nil
    end

    hook.Remove('PostRender', RENDER_HOOK_NAME)
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

    DrawToolTexture(rt, text)

    mat = CreateMaterial(rt:GetName(), 'UnlitGeneric', {
        ['$basetexture'] = rt:GetName(),
        ['$color2'] = '[1 1 1]',
        ['$translucent'] = 1,
        ['$nomip'] = 1,
        ['$alpha'] = 1
    })

    toolMaterials[text] = mat
    toolTextureQueue[text] = rt

    -- I queue the render texture to be drawn again in PostRender just to make sure everything draws properly
    -- If it's drawn in an ENT:Draw hook, for example, the text may not be properly drawn onto the texture
    hook.Add('PostRender', RENDER_HOOK_NAME, DrawToolTextureQueue)

    return mat
end