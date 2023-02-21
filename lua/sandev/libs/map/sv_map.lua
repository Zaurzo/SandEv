--[[
    Protect map entities or entities that are considered from the map from undesirable behavior 

    The idea here is to mask these entities just enough, by no means are they perfectly hidden!

    In general they should act like walls ("Entity [0][worldspawn]"), so the tool relationships
    are limited and they return false when checked by IsValid. This has proven to be good enough
    so far (HUDs and Inspectors are being blocked successfully).

    Another thing is that these entities cannot be triggered by external addons, so ENT:Fire() is
    detoured! E.G. FNAF NPCs were removing the dark room floor because it's a func_door and they
    want to be spooky openning it.
--]]

function SEv.Map:SetProtectedEntity(ent)
    local toolsBlacklist = {
        "remover",
        "duplicator",
        "motor",
        "pulley",
        "nocollide",
        "physprop",
        "material",
        "colour",
        "trails"
    }

    SEv.Ent:BlockTools(ent, unpack(toolsBlacklist))
    SEv.Ent:BlockContextMenu(ent, true)
    SEv.Ent:HideInfo(ent, true)
    SEv.Ent:SetFakeInvalid(ent, true)
    SEv.Ent:HideFire(ent, true)
    SEv.Ent:BlockEntRemoveCvars(ent, true)
end

-- Read nodes

-- Original code by Silverlan, Nodegraph Editor
-- https://steamcommunity.com/sharedfiles/filedetails/?id=104487190&searchtext=nodegraph

NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5

local AINET_VERSION_NUMBER = 37
local NUM_HULLS = 10
local MAX_NODES = 1500

local _R = debug.getregistry()
local meta = {}
_R.SEvNodes = meta
local methods = {}
meta.__index = methods
function meta:__tostring()
    local str = "SEvNodes [" .. table.Count(self:GetNodes()) .. " Nodes] [" .. table.Count(self:GetLinks()) .. " Links] [AINET " .. self:GetAINetVersion() .. "] [MAP " .. self:GetMapVersion() .. "]"
    return str
end
methods.MetaName = "SEvNodes"
function _R.SEvNodes.Create(f)
    local t = {}
    setmetatable(t,meta)
    if(f) then if(!t:ParseFile(f)) then t:Clear() end
    else t:Clear() end
    return t
end

function _R.SEvNodes.Read(f)
    if(!f) then f = "maps/graphs/" .. game.GetMap() .. ".ain" end
    return _R.SEvNodes.Create(f)
end

function methods:Clear()
    self.m_nodegraph = {
        ainet_version = AINET_VERSION_NUMBER,
        map_version = 1196,
        nodes = {},
        links = {},
        lookup = {}
    }
end

function methods:GetAINetVersion() return self:GetData().ainet_version end

function methods:GetMapVersion() return self:GetData().map_version end

function methods:ParseFile(f)
    f = file.Open(f,"rb","GAME")
        if(!f) then return end
        local ainet_ver = f:ReadULong()
        local map_ver = f:ReadULong()
        local nodegraph = {
            ainet_version = ainet_ver,
            map_version = map_ver
        }
        if(ainet_ver != AINET_VERSION_NUMBER) then
            MsgN("Unknown graph file")
            return
        end
        local numNodes = f:ReadULong()
        if(numNodes > MAX_NODES || numNodes < 0) then
            MsgN("Graph file has an unexpected amount of nodes")
            return
        end
        local nodes = {}
        for i = 1,numNodes do
            local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
            local yaw = f:ReadFloat()
            local flOffsets = {}
            for i = 1,NUM_HULLS do
                flOffsets[i] = f:ReadFloat()
            end
            local nodetype = f:ReadByte()
            local nodeinfo = f:ReadUShort()
            local zone = f:ReadShort()
            
            local node = {
                pos = v,
                yaw = yaw,
                offset = flOffsets,
                type = nodetype,
                info = nodeinfo,
                zone = zone,
                neighbor = {},
                numneighbors = 0,
                link = {},
                numlinks = 0
            }
            table.insert(nodes,node)
        end
        local numLinks = f:ReadULong()
        local links = {}
        for i = 1,numLinks do
            local link = {}
            local srcID = f:ReadShort()
            local destID = f:ReadShort()
            local nodesrc = nodes[srcID +1]
            local nodedest = nodes[destID +1]
            if(nodesrc && nodedest) then
                table.insert(nodesrc.neighbor,nodedest)
                nodesrc.numneighbors = nodesrc.numneighbors +1
                
                table.insert(nodesrc.link,link)
                nodesrc.numlinks = nodesrc.numlinks +1
                link.src = nodesrc
                link.srcID = srcID +1
                
                table.insert(nodedest.neighbor,nodesrc)
                nodedest.numneighbors = nodedest.numneighbors +1
                
                table.insert(nodedest.link,link)
                nodedest.numlinks = nodedest.numlinks +1
                link.dest = nodedest
                link.destID = destID +1
            else MsgN("Unknown link source or destination " .. srcID .. " " .. destID) end
            local moves = {}
            for i = 1,NUM_HULLS do
                moves[i] = f:ReadByte()
            end
            link.move = moves
            table.insert(links,link)
        end
        local lookup = {}
        for i = 1,numNodes do
            table.insert(lookup,f:ReadULong())
        end
    f:Close()
    nodegraph.nodes = nodes
    nodegraph.links = links
    nodegraph.lookup = lookup
    self.m_nodegraph = nodegraph
    return nodegraph
end

function methods:GetData() return self.m_nodegraph end

function methods:GetNodes() return self:GetData().nodes end
function methods:GetLinks() return self:GetData().links end
function methods:GetLookupTable() return self:GetData().lookup end

function methods:GetNode(nodeID) return self:GetNodes()[nodeID] end

-- Load cached nodes
function SEv.Map:LoadGroundNodes()
    local nodesCache = file.Read(self.path, "Data")

    if nodesCache then
        self.nodesList = util.JSONToTable(nodesCache)
    end
end

-- Save the read nodes
function SEv.Map:SaveGroundNodes()
    file.Write(self.path, util.TableToJSON(self.nodesList, false))
end

-- Get map node positions
function SEv.Map:GetGroundNodesPosTab()
    if self.nodesList then return self.nodesList end

    local _R = debug.getregistry()
    local posTab = {}
    local nodesCtrl = _R.SEvNodes.Read()

    if nodesCtrl then
        local nodesTab = nodesCtrl:GetNodes()

        for k,node in pairs(nodesTab) do
            if node.type == NODE_TYPE_GROUND then
                table.insert(posTab, node.pos)
            end
        end
    end

    self.nodesList = posTab

    SEv.Map:SaveGroundNodes()

    return self.nodesList
end