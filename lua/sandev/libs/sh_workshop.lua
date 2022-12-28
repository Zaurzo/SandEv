-- Deal with workshop addons

function SEv.Workshop:InitializeList()
    local addons = engine.GetAddons()

    for i = 1, #addons do
        local addon = addons[i]
        self.list[tonumber(addon.wsid)] = addon
    end
end

function SEv.Workshop:IsInstalled(wsid)
    return self.list[wsid] and true or false
end

function SEv.Workshop:IsMounted(wsid)
    return SEv.Workshop:IsInstalled(wsid) and self.list[wsid].mounted or false
end

function SEv.Workshop:Download(wsid)
    local path = "cache/workshop/" .. wsid .. ".gma"

    if not file.Exists(path, "GAME") then
        steamworks.DownloadUGC(wsid, function() return end)
    end
end

function SEv.Workshop:GetMountedByTag(tag)
    local list = {}

    for k, addonTab in ipairs(engine.GetAddons()) do
        if addonTab.mounted and string.find(addonTab.tags, "NPC") then
            table.insert(list, addonTab)
        end
    end

    return list
end

function SEv.Workshop:ReadGmaHeader(path)
    -- TO-DO https://github.com/Facepunch/gmad/blob/master/include/AddonReader.h
    local gma = file.Open(path, "rb", "MOD")

    if not gma then return end

    local gmaInfo = {}
    local gmaHeader = gma:Read(65536)

    -- Get data here

    gma:Close()

    return gmaInfo
end
