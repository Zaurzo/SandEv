function SEv:AddDevModeToBase(base)
    function base:EnableDevMode()
        base.devMode = true

        concommand.Add(base.id .. "_events_toggle", function(ply, cmd, args) base.Event:Toggle(ply, cmd, args) end)
        concommand.Add(base.id .. "_events_list", function() base.Event:List() end)
        concommand.Add(base.id .. "_memories_toggle", function(ply, cmd, args) base.Event.Memory:Toggle(ply, cmd, args) end)
        concommand.Add(base.id .. "_memories_toggle_per_player", function(ply, cmd, args) base.Event.Memory:TogglePerPlayer(ply, cmd, args) end)
        concommand.Add(base.id .. "_memories_list", function() base.Event.Memory:List() end)
        concommand.Add(base.id .. "_memories_print_logic", function() base.Event.Memory.Dependency:PrintLogic() end)

        if CLIENT then
            net.Start(base.id .. "_event_request_all_render_sv")
            net.SendToServer()

            CreateClientConVar(base.id .. "_events_show_names", "0", true, false)
            CreateClientConVar(base.id .. "_events_render_auto", "0", true, false)
            SEv.Portals.VarDrawDistance = CreateClientConVar(base.id .. "_portal_drawdistance", "3500", true, false, "Sets the size of the portal along the Y axis", 0)

            concommand.Add(base.id .. "_events_render", function(ply, cmd, args) base.Event:ToggleRender(ply, cmd, args) end)
            concommand.Add(base.id .. "_events_render_list", function() base.Event:ListRender() end)
        end

        hook.Run(base.id .. "_devmode", true)
        
        if SERVER then
            RunConsoleCommand("state_devmode_" .. base.id, "1")
        end
    end

    function base:DisableDevMode()
        base.devMode = false

        concommand.Remove(base.id .. "_events_toggle")
        concommand.Remove(base.id .. "_events_list")
        concommand.Remove(base.id .. "_memories_toggle")
        concommand.Remove(base.id .. "_memories_list")
        concommand.Remove(base.id .. "_memories_print_logic")

        if CLIENT then
            concommand.Remove(base.id .. "_events_render")
            concommand.Remove(base.id .. "_events_render_list")

            -- Apparently we can't remove cvars.
        end

        hook.Run(base.id .. "_devmode", false)

        if SERVER then
            RunConsoleCommand("state_devmode_" .. base.id , "0")
        end
    end

    local devModeState = CreateConVar("state_devmode_" .. base.id , "0", { FCVAR_ARCHIVE, FCVAR_REPLICATED }) -- Just to store the state between games

    if SERVER then
        function base:ToggleDevMode()
            local toggleFuncName = base.devMode and "DisableDevMode" or "EnableDevMode"

            base[toggleFuncName]()

            net.Start(base.id .. "_toggle_devmode")
            net.WriteString(toggleFuncName)
            net.Broadcast()

            print("[SandEv] " .. base.id .. " devmode is " .. (base.devMode and "On" or "Off"))
        end

        concommand.Add("devmode_" .. base.id .. "_toggle", function() base:ToggleDevMode() end)    

        if devModeState:GetBool() then
            base:ToggleDevMode()
        end
    else
        hook.Add(base.id .. "_memories_received", base.id .. "_auto_dev_mode_cl", function()
            if GetConVar("state_devmode_" .. base.id):GetBool() then
                base:EnableDevMode()
            end
        end)

        net.Receive(base.id .. "_toggle_devmode", function()
            local toggleFuncName = net.ReadString()
            base[toggleFuncName]()
        end)
    end
end