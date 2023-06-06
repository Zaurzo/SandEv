-- Break vehicles (By Zaurzo)

-- Break any supported vehicle
function SEv.Vehicle:Break(vehicle)
    if not IsValid(vehicle) or not vehicle:IsVehicle() or self:IsBroken(vehicle) then return end

    local vehSoundList = vehicle.sev_veh_sound_list

    if vehSoundList then
        for soundName in pairs(vehSoundList) do
            vehicle:StopSound(soundName)
        end

        -- Cleanup. This function does a permanent effect on the vehicle and we don't need to use this variable anymore
        vehicle.sev_veh_sound_list = nil
    end

    if vehicle.IsSimfphyscar then
        SEv.Addon:BreakSimphys(vehicle)
    elseif vehicle.IsScar then
        SEv.Addon:BreakSCar(vehicle)    
    else
        SEv.Vehicle:BreakHL2Vehicle(vehicle)
    end

    vehicle.sev_broken_engine = true

    SEv.Ent:SetMute(vehicle, true)
end

-- Default HL2 based vehicles
function SEv.Vehicle:BreakHL2Vehicle(vehicle)
    if not IsValid(vehicle) or not vehicle:IsVehicle() then return end

    if vehicle.StartEngine then
        vehicle:StartEngine(false)
        vehicle:SetSequence('idle')

        vehicle.StartEngine = function() end
    end

    if vehicle.TurnOn then
        vehicle:TurnOn(false)

        vehicle.TurnOn = function() end
    end

    if vehicle.Think then
        vehicle.Think = function() end
    end
end

function SEv.Vehicle:IsBroken(vehicle)
    return vehicle.sev_broken_engine
end

-- Some vehicle engine sounds don't stop upon engine break
-- So we add it to a table and stop the sound when necessary
hook.Add('EntityEmitSound', 'sev_vehicle_sound_control', function(soundData)
    local ent = soundData.Entity

    if IsValid(ent) and ent:IsVehicle() then
        local vehSoundList = ent.sev_veh_sound_list

        if not vehSoundList then
            vehSoundList = {}
            ent.sev_veh_sound_list = vehSoundList
        end

        vehSoundList[soundData.SoundName] = true
    end
end)

-- Keep vehicles broken
hook.Add('VehicleMove', 'sev_vehicle_control', function(ply, vehicle)
    if not IsValid(vehicle) then return end

    if SEv.Vehicle:IsBroken(vehicle) then
        if vehicle.IsSimfphyscar then
            SEv.Addon:BreakSimphys(vehicle)
        elseif vehicle.IsScar then
            SEv.Addon:BreakSCar(vehicle)    
        else
            SEv.Vehicle:BreakHL2Vehicle(vehicle)
        end
    end
end)
