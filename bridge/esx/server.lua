if Framework.initials ~= "esx" then return end

Framework.CreateServerCallback = Framework.object.RegisterServerCallback  --[[@as function]]

function Framework.GetPlayerByCitizenId(citizenId)
    local xPlayers = Framework.object.GetExtendedPlayers()
    for i = 1, #xPlayers do
        local xPlayer = xPlayers[i]
        if xPlayer.getMeta()?.citizenId == citizenId then
            return xPlayer
        end
    end
    return nil
end

Framework.GetPlayerByServerId = Framework.object.GetPlayerFromId --[[@as function]]

function Framework.GetPlayerIdentifierByServerId(source, _)
    return Framework.GetPlayerByServerId(source)?.getIdentifier()
end

function Framework.GetPlayerCitizenIdByServerId(source)
    local player = Framework.GetPlayerByServerId(source)
    return player?.getMeta()?.citizenId
end

function Framework.GetPlayerCitizenIdByPlayer(player)
    return player?.getMeta()?.citizenId
end

function Framework.GetPlayerServerIdByPlayer(player)
    return player?.source
end

function Framework.GetPlayerFirstNameByPlayer(player)
    return CapitalFirstLetter(player?.get("firstName"))
end

function Framework.GetPlayerLastNameByPlayer(player)
    return CapitalFirstLetter(player?.get("lastName"))
end

function Framework.GetPlayerFullNameByPlayer(player)
    local firstName = Framework.GetPlayerFirstNameByPlayer(player)
    local lastName = Framework.GetPlayerLastNameByPlayer(player)
    return ("%s %s"):format(firstName, lastName)
end

function Framework.GetPlayerLicensesByPlayer(player) -- TODO: maybe I should get all available licenses and loop through them to check whether player have them or not
    local _licenses, licenses = {}, {}
    local source = Framework.GetPlayerServerIdByPlayer(player)
    TriggerEvent("esx_license:getLicenses", source, function(returnedLicenses)
        _licenses = returnedLicenses
    end)
    if _licenses then
        for i = 1, #_licenses do
            local licenseName = _licenses[i].type -- or _licenses[i].name ?   we'll see
            licenses[licenseName] = true
        end
    end
    return licenses
end

function Framework.GetPlayerGenderByPlayer(player)
    return player?.get("sex")
end

-- if you use another phone other than NPWD, change this function"s return data
function Framework.GetPlayerPhoneNumberByPlayer(player)
    local identifier = player?.getIdentifier()
    if not identifier then return end
    local success, playerData = pcall(exports.npwd.getPlayerData, { identifier = identifier })
    return success and playerData?.phoneNumber
end

function Framework.GetPlayerJobNameByPlayer(player)
    return player?.getjob()?.name
end

function Framework.GetPlayerJobGradeNameByPlayer(player)
    return player?.getjob()?.grade_label
end

function Framework.GetPlayerJobGradeLevelByPlayer(player)
    return player?.getjob()?.grade
end

function Framework.GetPlayerJobDutyByPlayer(player)
    return player?.getjob()?.jobDuty -- to be released: https://github.com/esx-framework/esx_core/pull/947
end

function Framework.GetPlayerJobObjectAsQbByPlayer(player) -- QB Style
    local job = player?.getJob()
    if not job then return end
    local jobObject = {
        name = job.name,
        label = job.label,
        payment = job.grade_salary,
        onduty = job?.jobDuty, -- to be released: https://github.com/esx-framework/esx_core/pull/947
        isboss = job.grade_name == "boss",
        grade = {
            name = job.grade_label,
            level = job.grade
        }
    }
    return jobObject
end

function Framework.GetPlayerCallSignByPlayer(player)
    return player?.getMeta()?.callsign
end

function Framework.SetPlayerCallSignByPlayer(player, newCallSign)
    return player?.setMeta("callsign", newCallSign)
end

function Framework.GetPlayerHasItemByPlayer(player, item)
    return player?.getInventoryItem(item) and true or false
end

function Framework.RemoveMoneyFromPlayer(player, money, account, reason)
    return player?.removeAccountMoney(account or "bank", money, reason)
end

function Framework.Notification(source, message, type, duration)
    return TriggerClientEvent("esx:showNotification", source, message, type, duration)
end

function Framework.UnpackJobData(data) -- QB Style
    local job = {
        name = data?.name,
        label = data?.label
    }
    local grade = {
        name = data?.grade_label,
    }

    return job, grade
end

AddEventHandler("esx:playerLoaded", GenerateCitizenId)