-- Prop breaking

function SEv.Prop:CallOnBreak(ent, id, callback, ...)
    if callback then
        ent.sev_on_break_callback = ent.sev_on_break_callback or {}
        ent.sev_on_break_callback[id] = { func = callback, args = { ... } }
    end
end

function SEv.Prop:RemoveOnBreakCallback(ent, id)
    if ent.sev_on_break_callback then
        ent.sev_on_break_callback[id] = nil
    end
end

function SEv.Prop:GetOnBreakCallbacks(ent)
    return ent.sev_on_break_callback
end

hook.Add("PropBreak", "sev_prop_breaking_control", function(client, prop)
    local callbacks = SEv.Prop:GetOnBreakCallbacks(prop)

    if callbacks then
        for id, callback in pairs(callbacks) do
            if isfunction(callback.func) then
                callback.func(unpack(callback.args))
            end
        end
    end
end)