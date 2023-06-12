-- Break vehicles (By Zaurzo)

-- SCars
-- https://steamcommunity.com/sharedfiles/filedetails/?id=104483020
function SEv.Addon:BreakSCar(vehicle)
    if not IsValid(vehicle) or not vehicle:IsVehicle() or not vehicle.IsScar then return end

    if vehicle.TurnOffCar then
        vehicle:TurnOffCar()
    end

    if vehicle.StartCar then 
        vehicle.StartCar = function() end
    end

    if vehicle.TurnLeft or vehicle.TurnRight then
        vehicle.TurnLeft = function() end
        vehicle.TurnRight = function() end
    end
end

-- Simphys
-- https://steamcommunity.com/workshop/filedetails/?id=771487490
function SEv.Addon:BreakSimphys(vehicle)
    if not IsValid(vehicle) or not vehicle:IsVehicle() or not vehicle.IsSimfphyscar then return end

    if vehicle.StopEngine then
        vehicle:StopEngine()
    end

    if vehicle.SetValues then
        vehicle:SetValues()
    end

    if vehicle.StartEngine then 
        vehicle.StartEngine = function() end 
    end

    if vehicle.SetActive then
        vehicle.SetActive = function() end
    end
end
