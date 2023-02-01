-- Bases devmode

function SEv:AddDevModeToBase(base)
    function base:EnableDevMode()
        base.devMode = true

        concommand.Add(base.id .. "_events_toggle", function(ply, cmd, args) base.Event:Toggle(ply, cmd, args) end)
        concommand.Add(base.id .. "_events_list", function() base.Event:List() end)
        concommand.Add(base.id .. "_memories_toggle", function(ply, cmd, args) base.Event.Memory:Toggle(ply, cmd, args) end)
        concommand.Add(base.id .. "_memories_toggle_per_player", function(ply, cmd, args) base.Event.Memory:TogglePerPlayer(ply, cmd, args) end)
        concommand.Add(base.id .. "_memories_list", function() base.Event.Memory:List() end)
        concommand.Add(base.id .. "_memories_print_logic", function() base.Event.Memory.Dependency:PrintLogic() end)
        concommand.Add(base.id .. "_memories_set", function(ply, cmd, args) --TODO: Move this to something else.
            print(ply)
            print(cmd)
            if string.find(args[2], "^[%s]-[{]") then
                PrintTable(thing)
            else
                print(thing)
            end

            local function StringToTable(tblstr)
                return CompileString('return ' .. tblstr)()
            end

            if isnumber(args[2]) then
                -- We know it is a int.
                args[2] = tonumber(args[2])
            elseif args[2] == ("true" or "false") then
                -- We know it is a Bool.
                args[2] = tobool(args[2])
            elseif string.find(args[2], "^[%s]-[{]") then
                -- We know it is a table.

                local ConvertedStr = StringToTable(args[2])--CompileString("return " .. args[2] .. "", "SrtToTable")()
                --PrintTable(CompileString("function SrtToTable() return " .. args[2] .. " end SrtToTable()", "SrtToTable")())
                if string.find(args[2], "^[%s]-[{]") then
                    PrintTable(ConvertedStr)
                else
                    print(ConvertedStr)
                end
                --PrintTable(CompileString('return ' .. tostring("function() return " .. args[2] .. " end")))--args[3]), "SrtToTable"))
            else
                args[2] = tostring(args[2]) -- for extra mesure.
                -- We know it is a string.
            end

            --base.Event.Memory.SetCommand(args[1], args[2])
        end)

        if CLIENT then
            net.Start(base.id .. "_event_request_all_render_sv")
            net.SendToServer()

            CreateClientConVar(base.id .. "_events_show_names", "0", true, false)
            CreateClientConVar(base.id .. "_events_render_auto", "0", true, false)
            SEvPortals.VarDrawDistance = CreateClientConVar(base.id .. "_portal_drawdistance", "3500", true, false, "Sets the size of the portal along the Y axis", 0)

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
        concommand.Remove(base.id .. "_memories_set")

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

-- SandEv devmode

function SEv:EnableDevMode()
    SEv.devMode = true

    hook.Run(SEv.id .. "_devmode", true)
    
    if SERVER then
        RunConsoleCommand("state_devmode_" .. SEv.id, "1")
    end
end

function SEv:DisableDevMode()
    SEv.devMode = false

    hook.Run(SEv.id .. "_devmode", false)

    if SERVER then
        RunConsoleCommand("state_devmode_" .. SEv.id , "0")
    end
end

local SEvDevModeState = CreateConVar("state_devmode_" .. SEv.id , "0", { FCVAR_ARCHIVE, FCVAR_REPLICATED }) -- Just to store the state between games

if SERVER then
    function SEv:ToggleDevMode()
        local toggleFuncName = SEv.devMode and "DisableDevMode" or "EnableDevMode"

        SEv[toggleFuncName]()

        net.Start(SEv.id .. "_toggle_devmode")
        net.WriteString(toggleFuncName)
        net.Broadcast()

        print("[SandEv] " .. SEv.id .. " devmode is " .. (SEv.devMode and "On" or "Off"))
    end

    concommand.Add("devmode_" .. SEv.id .. "_toggle", function() SEv:ToggleDevMode() end)    

    if SEvDevModeState:GetBool() then
        SEv:ToggleDevMode()
    end
else
    hook.Add(SEv.id .. "_memories_received", SEv.id .. "_auto_dev_mode_cl", function()
        if GetConVar("state_devmode_" .. SEv.id):GetBool() then
            SEv:EnableDevMode()
        end
    end)

    net.Receive(SEv.id .. "_toggle_devmode", function()
        local toggleFuncName = net.ReadString()
        SEv[toggleFuncName]()
    end)
end