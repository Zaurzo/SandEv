-- A way to see what's going on with the memories

-- Get a table with all the memory layers
function SEv.Event.Memory.Dependency:GeLayers()
    local providersCopy = table.Copy(self.providers)
    local dependentsCopy = table.Copy(self.dependents)
    local popedMemoryNames = {}
    local memoryLayers = {}

    self:WarnUnused(providersCopy, dependentsCopy)
    self:RemoveLoops(providersCopy, dependentsCopy)

    while(next(providersCopy)) do -- This table is emptied as we select the memories from each layer
        local layerProviders, layerDependents = self:PopTopLayer(providersCopy, dependentsCopy, popedMemoryNames)
        
        table.insert(memoryLayers, { providers = layerProviders, dependents = layerDependents })
    end

    self:WarnMissingProvider(dependentsCopy)

    return memoryLayers
end

-- Pop a memory layer, which consists of a number of providers and dependents which are
-- activated under the same number of dependencies
function SEv.Event.Memory.Dependency:PopTopLayer(providers, dependents, popedMemoryNames)
    popedMemoryNames = popedMemoryNames or {}
    local topProvidersLayer = {}
    local topDependentsLayer = {}

    -- Pop top providers ([memoryName] = eventName)
    for eventName, memoryTab in pairs(providers) do
        if not dependents[eventName] then
            for memoryName, _ in pairs(memoryTab) do
                topProvidersLayer[memoryName] = topProvidersLayer[memoryName] or {}
                table.insert(topProvidersLayer[memoryName], eventName)
                popedMemoryNames[memoryName] = true
            end

            providers[eventName] = nil
        end
    end

    -- Pop top dependents ([eventName] = memoryName)
    for eventName, memoryTab in pairs(dependents) do
        local add = {}

        for memoryName, _ in pairs(memoryTab) do
            table.insert(add, memoryName)

            if not popedMemoryNames[memoryName] then
                add = {}
                break
            end
        end

        for k, memoryName in ipairs(add) do
            topDependentsLayer[eventName] = topDependentsLayer[eventName] or {}
            table.insert(topDependentsLayer[eventName], memoryName)
        end

        if #add > 0 then
            dependents[eventName] = nil
        end
    end

    return topProvidersLayer, topDependentsLayer, popedMemoryNames
end

-- Completely remove loops from the dependencies
function SEv.Event.Memory.Dependency:RemoveLoops(providers, dependents)
    -- Use memoryName as index to easyly crosscheck providers and dependents
    local formatedProviders = {}
    for eventName, memoryTab in pairs(providers) do
        for memoryName, _ in pairs(memoryTab) do
            formatedProviders[memoryName] = formatedProviders[memoryName] or {}
            formatedProviders[memoryName][eventName] = true
        end
    end

    -- Remove a detected loop
    local function removeLoop(eventNameOut)
        providers[eventNameOut] = nil
        dependents[eventNameOut] = nil

        for memoryName, eventTab in pairs(formatedProviders) do
            for eventName,_ in pairs(eventTab) do
                if eventName == eventNameOut then
                    formatedProviders[memoryName][eventName] = nil
                end
            end
        end
    end

    -- Recursivelly check all paths to remove loops
    local function clearPath(curName, curTab, checkTab1, checkTab2, done, isEvent)
        if isEvent then
            if done[curName] then
                done[curName] = nil

                return curName
            end

            done[curName] = true
        end

        for curTabIndex, _ in pairs(curTab) do
            if checkTab2[curTabIndex] then
                local result = clearPath(curTabIndex, checkTab2[curTabIndex], checkTab2, checkTab1, done, not isEvent)

                if result then
                    if isEvent then
                        removeLoop(curName)
                        return curName .. " <-- " .. result
                    else
                        return result
                    end
                end
            end
        end

        if isEvent then
            done[curName] = nil
        end
    end

    -- Start
    local printedError = false
    for eventName, memoryTab in pairs(dependents) do
        local done = {}
        local result = clearPath(eventName, memoryTab, dependents, formatedProviders, done, true)

        if result then
            if not printedError then
                printedError = true
                ErrorNoHaltWithStack("[SEv] ERROR!! Loop(s) detected in the memory module! The following events will not be loaded:")
            end

            print("  Loop: " .. result .. "\n")
        end
    end
end

-- Warn about unused memories
function SEv.Event.Memory.Dependency:WarnUnused(providers, dependents)
    local function filterMemories(curMemoriesTab)
        local memories = {}

        for eventName, memoryTab in pairs(curMemoriesTab) do
            for memoryName, _ in pairs(memoryTab) do
                memories[memoryName] = true
            end
        end

        return memories
    end

    local providedMemories = filterMemories(providers)
    local requiredMemories = filterMemories(dependents)

    local unused = {}
    for memoryName,_ in pairs(providedMemories) do
        if not requiredMemories[memoryName] then
            table.insert(unused, memoryName)
        end
    end

    if next(unused) then
        print("\n[SEv] Warning! The following memories have been declared but have no dependents:")

        for _, memoryName in SortedPairsByValue(unused) do
            print(" - " .. memoryName)
        end
    end
end

-- Throw an error if there are events that require unprovided memories
function SEv.Event.Memory.Dependency:WarnMissingProvider(leftDependents)
    if next(leftDependents) then
        print("[SEv] WARNING! The following events require memories that are not provided:")

        for eventName, memoryTab in pairs(leftDependents) do 
            print("  \"" .. eventName .. "\" event requires:")

            for memoryName, _ in pairs(memoryTab) do
                print("    " .. memoryName)
            end
        end
    end
end

-- Print all memory layers
function SEv.Event.Memory.Dependency:PrintLogic()
    local memoryLayers = self:GeLayers()

    if next(memoryLayers) then
        print("\n###################################")
        print("SEv Memories")
        print("Lower layers depend on upper layers")
        print("###################################\n")

        local function printSection(memoriesTab, header, tableTitle)
            if next(memoriesTab) then
                print(header)
                print(tableTitle)

                for memoryName, eventTab in SortedPairs(memoriesTab) do
                    local events = ""

                    for k, eventName in ipairs(eventTab) do
                        events = events .. eventName .. ", "
                    end

                    print(string.format("      %-31s %s", memoryName, string.sub(events, 1, events:len() - 2)))
                end
            end
        end

        -- Incompatibilities
        local incompatibilitiesList = self.instance.Event.Memory.Incompatibility:GetList()

        if next(incompatibilitiesList) then
            local formattedIcompat = {}

            for eventName, memoryTab in pairs(incompatibilitiesList) do
                for memoryName, _ in pairs(memoryTab) do
                    formattedIcompat[eventName] = formattedIcompat[eventName] or {}
                    table.insert(formattedIcompat[eventName], memoryName)
                end
            end

            print("[General]")

            printSection(formattedIcompat, "\n  [Incompatibilities]\n", "    [Event Name]                 [Incompatible memories]")

            print()
        end

        -- Layers
        for memoryLayer, memoryType in ipairs(memoryLayers) do
            print("[Layer " .. memoryLayer .. "]")

            printSection(memoryType.providers, "\n  [Providers]\n", "    [Memory Name]                [Events that activate the memory]")
            printSection(memoryType.dependents, "\n  [Dependents]\n", "    [Event Name]                 [Memories required to load the event]")
            
            print()
        end
    end
end



--[[

-- ---------------------------------------------------

-- Debug only SEv.Event.Memory.Dependency:RemoveLoops()

local t1 = {
    ["aa"] = { ["1"] = true },
    ["bb"] = { ["2"] = true },
    ["cc"] = { ["3"] = true, ["4"] = true},
    ["ee"] = { ["5"] = true }
}

local t2 = {
    ["aa"] = { ["2"] = true, ["22"] = true },
    ["bb"] = { ["3"] = true },
    ["cc"] = { ["1"] = true }
}

PrintTable(t1)

SEv.Event.Memory.Dependency:RemoveLoops(t1, t2)

PrintTable(t1)

-- ---------------------------------------------------

-- Fully debug SEv.Event.Memory.Dependency:GeLayers()

local providers = { -- ["event name"] = { ["memory name"] = bool, ... }
    ["1"] = { ["_"] = true },
    ["2"] = { ["_"] = true },
    ["3"] = { ["_"] = true },
    ["4"] = { ["ba"] = true, ["_"] = true },
    ["5"] = { ["new"] = true },
    ["S1"] = { ["A"] = true, ["B"] = true },
    ["S2"] = { ["B"] = true },
    ["S3"] = { ["A"] = true, ["C"] = true },
    ["SX"] = { ["K"] = true },
    ["aa"] = { ["1"] = true },
    ["bb"] = { ["2"] = true },
    ["cc"] = { ["3"] = true },
    ["unu1"] = { ["nope1"] = true },
    ["unu2"] = { ["nope2"] = true }
}

local dependents = {
    ["5"] = { ["K"] = true, ["_"] = true },
    ["6"] = { ["K"] = true, ["_"] = true },
    ["7"] = { ["K"] = true, ["_"] = true },
    ["8"] = { ["K"] = true, ["_"] = true },
    ["S4"] = { ["A"] = true, ["B"] = true, ["C"] = true},
    ["SX"] = { ["C"] = true },
    ["S+"] = { ["K"] = true, ["C"] = true },
    ["S_"] = { ["A"] = true, ["B"] = true, ["K"] = true },
    ["aa"] = { ["2"] = true },
    ["bb"] = { ["3"] = true },
    ["cc"] = { ["1"] = true },
    ["help"] = { ["void"] = true }
}

local memoryLayers = SEv.Event.Memory.Dependency:GeLayers(providers, dependents)
SEv.Event.Memory.Dependency:PrintLogic(memoryLayers)


-- ---------------------------------------------------------------------------------------------


HOW IT WORKS?
(Sorry, Portuguese helps myself)

----

Memórias providenciadas e requeridas por cenas

provider
["S1"] = { "A", "B" }
["S2"] = { "B" }
["S3"] = { "A", "C" }
["SX"] = { "K" }

dependent
["S4"] = { "A", "B", "C"}
["SX"] = { "C" }
["S+"] = { "K", "C" }
["S_"] = { "A", "B", "K" }

Esquema

     _____ PRIMEIRAS COLUMAS PARA AS PRIMEIRAS MEMÓRIAS
S1   S1
     S2        QUEM LIBERA (CENAS)
S3        S3   
"A", "B", "C" ------------ O QUE É LIBERADO (MEMÓRIAS)
S4   S4   S4
          SX   QUEM DEPENDE (CENAS)

               _____  NOVA COLUMA PARA NOVAS MEMÓRIAS

               SX    QUEM LIBERA (CENAS)
               "K" ------------ O QUE É LIBERADO (MEMÓRIAS)
          S+   S+    QUEM DEPENDE (CENAS)
S_   S_        S_

1) Começa pegando quem não depende de ninguém e listo acima das memórias liberadas
2) Pego quem pode ser liberado com as memórias abertas e listo abaixo delas
3) Retiro das tabelas tudo o que foi listado
4) Repito o loop

EXEMPLO MAIS COMPLEXO:

provider
["S1"] = { "A", "B" }
["S2"] = { "B" }
["S3"] = { "A", "C" }
["SX"] = { "K" }
["1"] = { "_" }
["2"] = { "_" }
["3"] = { "_" }
["4"] = { "ba", "_" }
["5"] = { "new" }

dependent
["S4"] = { "A", "B", "C"}
["SX"] = { "C" }
["S+"] = { "K", "C" }
["S_"] = { "A", "B", "K" }
["5"] = { "k", "_" }
["6"] = { "k", "_" }
["7"] = { "k", "_" }
["8"] = { "k", "_" }

               1
               2
               3
               4    4
S1   S1
     S2 
S3        S3   
"A", "B", "C", "_", "ba" ------------
S4   S4   S4
          SX
_____ 
                          SX 
                          "K" ------------
          S+              S+
S_   S_                   S_
                5         5
                6         6
                7         7
                8         8
_____                    
                              5
                              "new" ------------


SOBRE LOOPS

ZZ --> C --> A --> B --> A --> B --> ...

Memórias que dependem de si mesmo, inclusive quando há múltiplas memórias na cadeia, geram loops!

Eu poderia deixar essa cadeia circular inclusa e quebrá-la com qualquer provider externo de uma memória dependent dela,
mas não quero isso, não há vantagens nisso! Não há nenhum comportamento especial positivo nesse ciclo que faça valer a
pena a enorme complexidade de lidar com ele.

ENTÃO DEVO DETECTAR E REMOVER:

a->b->a
a->b->c->d->a
a->b->c->b
...

Todas as memórias envolvidas serão desativadas, mesmo as fora do loop, para encorajar a total remoção deles.

OUTROS ERROS:

Cenas dependendo de memórias que não são fornecidas por ninguém

ALERTAS:

Cenas fornecendo memórias que não são usadas por ninguém
]]