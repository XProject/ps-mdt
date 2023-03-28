if Framework.initials ~= "qb" then return end

Framework.CreateServerCallback = Framework.object.Functions.CreateCallback --[[@as function]]

Framework.GetPlayerByCitizenId = Framework.object.Functions.GetPlayerByCitizenId --[[@as function]]

Framework.GetPlayerByServerId = Framework.object.Functions.GetPlayer --[[@as function]]

Framework.GetPlayerIdentifierByServerId = Framework.object.Functions.GetIdentifier --[[@as function]]

function Framework.GetPlayerCitizenIdByServerId(source)
    local player = Framework.GetPlayerByServerId(source)
    return player?.PlayerData?.citizenid
end

function Framework.GetPlayerCitizenIdByPlayer(player)
    return player?.PlayerData?.citizenid
end

function Framework.GetPlayerCitizenIdByPlayerData(playerData)
    return playerData?.citizenid
end

function Framework.GetPlayerServerIdByPlayer(player)
    return player?.PlayerData?.source
end

function Framework.GetPlayerFirstNameByPlayer(player)
    local firstName = player?.PlayerData?.charinfo?.firstname
    return firstName:sub(1,1):upper()..firstName:sub(2)
end

function Framework.GetPlayerLastNameByPlayer(player)
    local lastName = player?.PlayerData?.charinfo?.lastname
    return lastName:sub(1,1):upper()..lastName:sub(2)
end

function Framework.GetPlayerFullNameByPlayer(player)
    local firstName = Framework.GetPlayerFirstNameByPlayer(player)
    local lastName = Framework.GetPlayerLastNameByPlayer(player)
    return ("%s %s"):format(firstName, lastName)
end

function Framework.GetPlayerMetadataByPlayerData(playerData)
    return playerData?.metadata
end

function Framework.GetPlayerLicensesByPlayer(player)
    return Framework.GetPlayerMetadataByPlayerData(player?.PlayerData)?.licenses
end

function Framework.GetPlayerLicensesByPlayerData(playerData)
    return Framework.GetPlayerMetadataByPlayerData(playerData)?.licenses
end

function Framework.GetPlayerGenderByPlayer(player)
    return player?.PlayerData?.charinfo?.gender
end

function Framework.GetPlayerPhoneNumberByPlayer(player)
    return player?.PlayerData?.charinfo?.phone
end

function Framework.GetPlayerJobNameByPlayer(player)
    return player?.PlayerData?.job?.name
end

function Framework.GetPlayerJobGradeLevelByPlayer(player)
    return player?.PlayerData?.job?.grade?.level
end

function Framework.GetPlayerJobDutyByPlayer(player)
    return player?.PlayerData?.job?.onduty
end

function Framework.GetPlayerJobObjectAsQbByPlayer(player) -- QB Style
    return player?.PlayerData?.job
end

function Framework.GetPlayerCallSignByPlayer(player)
    return player?.PlayerData?.metadata?.callsign
end

function Framework.SetPlayerCallSignByPlayer(player, newCallSign)
    return player?.Functions?.SetMetaData("callsign", newCallSign)
end

function Framework.GetPlayerHasItemByPlayer(player, item)
    return player?.Functions?.GetItemByName(item) and true or false
end

function Framework.RemoveMoneyFromPlayer(player, money, account, reason)
    return player?.Functions?.RemoveMoney(account or 'bank', money, reason)
end

function Framework.Notification(source, message, type, duration)
    return TriggerClientEvent('QBCore:Notify', source, message, type, duration)
end

function Framework.UnpackJobData(data) -- QB Style
    local job = {
        name = data.name,
        label = data.label
    }
    local grade = {
        name = data.grade.name,
    }

    return job, grade
end