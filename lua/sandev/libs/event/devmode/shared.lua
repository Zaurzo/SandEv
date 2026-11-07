local EventLib = SandEv.Base.Event

---@param cmdName string
---@return SandEv.Instance
local function GetInstance(cmdName)
    local instanceID = cmdName:match('^(%w+)_')

    return SandEv:GetInstance(instanceID)
end

---@param ply Player
---@param cmdName string
---@param args string[]
local function ListEvents(ply, cmdName, args)
    local instance = GetInstance(cmdName)
    local tier = args[1]

    if not tier then
        instance:Print('Usage: ' .. cmdName .. ' <tier>')
        return
    end

    local tierValue = tonumber(tier)
    local maxTier = instance.Event:GetMaxTier()

    if not tierValue or (tierValue < 1 or tierValue > maxTier) then
        instance:Print('Invalid tier. Must be between 1 - ' .. maxTier)

        return
    end

    local events = {}

    for _, event in ipairs(instance.Event:GetList()) do
        if event.Tier == tierValue then
            events[event.Category] = events[event.Category] or {}

            table.insert(events[event.Category], event)
        end
    end

    if table.IsEmpty(events) then
        instance:Print('There are no currently loaded events from that tier.')

        return
    end

    print('- Loaded Tier ' .. tier .. ' Events -\n')

    for category, list in pairs(events) do
        print(category .. ':')

        for _, event in ipairs(list) do
            local tag = event:IsEnabled() and ' [Enabled]' or ' [Disabled]'

            print('\t' .. event.ID .. tag)
        end
    end
end

---@param ply Player
---@param cmdName string
---@param args string[]
local function ToggleEvent(ply, cmdName, args)
    local instance = GetInstance(cmdName)
    local eventName = args[1]

    if not eventName then return end

    local event = instance.Event:Get(eventName)

    if not event then
        instance:Print('There is no event loaded with that name.')
        return
    end

    local state

    if event:IsEnabled() then
        state = 'off'

        event:Disable()
    else
        state = 'on'

        event:Enable()
    end

    instance:Print('Toggled ' .. state .. ' event "' .. eventName .. '"')
end

function EventLib:InstallDevCommands()
    if self._dev_commands_setup then return end

    local id = self.Instance.ID
    local listCommandName = id .. '_event_list'
    local toggleCommandName = id .. '_event_toggle'

    if CLIENT then
        local gizmosCvarName = id .. '_event_draw_gizmos'

        listCommandName = listCommandName .. '_cl'
        toggleCommandName = toggleCommandName .. '_cl'

        self._gizmos_convar = CreateClientConVar(
            gizmosCvarName,
            '0',
            false,
            true,
            '',
            0,
            1
        )

        cvars.AddChangeCallback(gizmosCvarName, self.OnDrawGizmosChanged)
    end

    concommand.Add(listCommandName, ListEvents)
    concommand.Add(toggleCommandName, ToggleEvent)

    self._dev_commands_setup = true
end

---@param convarName string
---@param old string
---@param new string
function EventLib.OnDevModeChanged(convarName, old, new)
    if new ~= '1' then return end

    local instanceID = convarName:match('devmode_(%w+)_')
    local instance = SandEv:GetInstance(instanceID)
    
    if not instance then return end

    if SERVER then
        net.cheap.Start('sandev_devmode_enabled')
        net.WriteString(instanceID)
        net.Broadcast()

        cvars.RemoveChangeCallback(convarName, instanceID)
    end

    instance.Event:InstallDevCommands()
end