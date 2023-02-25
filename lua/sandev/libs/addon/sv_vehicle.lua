-- Break vehicles (By Zaurzo)

-- SCars
-- https://steamcommunity.com/sharedfiles/filedetails/?id=104483020
function SEv.Addon:BreakSCar(vehicle)
    if not vehicle or not IsValid(vehicle) or not vehicle:IsVehicle() then return end
    if not vehicle.IsScar then return end

    if vehicle.TurnOffCar then
        vehicle:TurnOffCar()
    end

    if vehicle.StartCar then 
        vehicle.StartCar = function() return end
    end

    if vehicle.TurnLeft or vehicle.TurnRight then
        vehicle.TurnLeft = function() return end
        vehicle.TurnRight = function() return end
    end
end

-- Simphys
-- https://steamcommunity.com/workshop/filedetails/?id=771487490
function SEv.Addon:BreakSimphys(vehicle)
    if not vehicle or not IsValid(vehicle) or not vehicle:IsVehicle() then return end
    if not vehicle.IsSimfphyscar then return end

    if vehicle.StopEngine then
        vehicle:StopEngine()
    end

    if vehicle.SetValues then
        vehicle:SetValues()
    end

    if vehicle.StartEngine then 
        vehicle.StartEngine = function() return end 
    end

    if vehicle.SetActive then
        vehicle.SetActive = function() return end
    end
end