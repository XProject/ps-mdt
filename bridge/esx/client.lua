if Framework.initials ~= "esx" then return end

local function CapitalStartLetter(str)
    return _(str):gsub("^%l", string.upper)
end

Framework.TriggerServerCallback = Framework.object.TriggerServerCallback  --[[@as function]]

Framework.GetPlayerData = Framework.object.GetPlayerData --[[@as function]]

Framework.AllVehicles = setmetatable({}, {
    __index = function(self, key)
        local vehicleData = rawget(self, key)
        if vehicleData ~= nil then return vehicleData end

        local hash = joaat(key)
        vehicleData = {
            name = GetDisplayNameFromVehicleModel(hash),
            brand = GetMakeNameFromVehicleModel(hash),
            model = key,
            hash = hash
        }

        rawset(self, key, vehicleData)

        return vehicleData
    end
})


function Framework.IsPlayerLoaded()
    return Framework.object.IsPlayerLoaded()
end

function Framework.GetPlayerCitizenId()
    return Framework.PlayerData?.metadata?.citizenId
end

function Framework.GetPlayerFirstName()
    return Framework.PlayerData?.firstName
end

function Framework.GetPlayerLastName()
    return Framework.PlayerData?.lastName
end

function Framework.GetPlayerBirthDate()
    return Framework.PlayerData?.dateofbirth
end

function Framework.GetPlayerJobName()
    return Framework.PlayerData?.job?.name
end

function Framework.GetPlayerJobDuty()
    return Framework.PlayerData?.job?.jobDuty -- to be released: https://github.com/esx-framework/esx_core/pull/947
end

function Framework.GetPlayerJobGradeName()
    return Framework.PlayerData?.job?.grade_label
end

function Framework.GetPlayerJobType()
    return nil
end

function Framework.IsPlayerLEO()
    return Framework.GetPlayerJobType() == "leo"
end

function Framework.GetPlayerCallsign()
    return Framework.PlayerData?.metadata?.callsign
end

function Framework.CanPlayerOpenMDT()
    return not Framework.PlayerData?.dead
end

function Framework.Notification(message, type)
    return Framework.object.ShowNotification(message, type)
end

-- If you use a different fine system, you will need to change this
function Framework.BillPlayer(targetSourceId, fineAmount)
    local job = Framework.GetPlayerJobName()
    local jobName = CapitalStartLetter(job)
    local jobGradeLabel = CapitalStartLetter(Framework.GetPlayerJobGradeName())
    local firstName = CapitalStartLetter(Framework.GetPlayerFirstName())
    local lastName = CapitalStartLetter(Framework.GetPlayerLastName())
    TriggerServerEvent("esx_billing:sendBill", targetSourceId, ("society_%s"):format(job), ("%s Fine from %s %s %s: $%s"):format(jobName, jobGradeLabel, firstName, lastName, fineAmount), fineAmount)
end

-- If you use a different community service system, you will need to change this
function Framework.SendPlayerToCommunityService(targetSourceId, sentence)
    print("~r~NO COMMUNITY SERVICE FUNCTION IS DEFINED FOR ESX!~s~")
end

-- If you use a different jail system, you will need to change this
function Framework.JailPlayer(targetSourceId, sentence)
    print("~r~NO JAIL FUNCTION IS DEFINED FOR ESX!~s~")
end

function Framework.ToggleDuty()
     -- to be released: https://github.com/esx-framework/esx_core/pull/947
end

function Framework.SpawnVehicle(vehicleModel, cb, coords, networked)
    return Framework.object.Game.SpawnVehicle(vehicleModel, vector3(coords.x, coords.y, coords.z), coords.w or 0.0, cb, networked)
end

function Framework.SetVehicleProperties(vehicle, props)
    return Framework.object.Game.SetVehicleProperties(vehicle, props)
end

function Framework.GetPlate(vehicle)
    return vehicle ~= 0 and Framework.object.Math.Trim(GetVehicleNumberPlateText(vehicle))
end

-- Events from esx
RegisterNetEvent("esx:playerLoaded", function(xPlayer)
    Framework.PlayerData = xPlayer
end)

RegisterNetEvent("esx:onPlayerLogout", function()
    TriggerServerEvent("ps-mdt:server:OnPlayerUnload")
    Framework.PlayerData = {}
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    Framework.PlayerData = val
end)

AddEventHandler("esx:setPlayerData", function(key, val, _)
    if GetInvokingResource() == Framework.resourceName then
        Framework.PlayerData[key] = val
    end
end)

-- TODO: setup event handler on change in job duty state once https://github.com/esx-framework/esx_core/pull/947 is merged