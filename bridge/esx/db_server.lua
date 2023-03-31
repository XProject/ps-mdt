if Framework.initials ~= "esx" then return end

-- TODO: complete setting up esx db

DB = {}

function DB.GetCitizenIDByLicense(license)
    return MySQL.query.await("SELECT JSON_VALUE(users.metadata, \"$.citizenId\") FROM users WHERE identifier = ?", {license})
end

function DB.GetNameFromCitizenId(citizenId)
    local name
    local result = MySQL.query.await("SELECT firstname, lastname FROM users WHERE JSON_VALUE(users.metadata, \"$.citizenId\") = ?", {citizenId})
    if result ~= nil then
        name = ("%s %s"):format(CapitalFirstLetter(result["firstname"]), CapitalFirstLetter(result["lastname"]))
    end
    return name
end

function DB.GetPlayerVehicles(citizenId) -- TODO: alter owned_vehicles add auto-increment id column - CHECK: query syntax as I'm not too knowledgeable on SQL joins...
    return MySQL.query.await("SELECT owned_vehicles.id, owned_vehicles.plate, JSON_VALUE(owned_vehicles.vehicle, \"$.model\") FROM owned_vehicles JOIN users on owned_vehicles.owner = users.identifier WHERE JSON_VALUE(users.metadata, \"$.citizenId\") = ?", {citizenId})
end

function DB.GetPlayerPropertiesByCitizenId(citizenId) -- TODO: go through esx_property and its exports to obtain data
    return
end

function DB.GetPlayerDataByCitizenId(citizenId)
    local playerData
    local player = Framework.GetPlayerByCitizenId(citizenId)
    if player ~= nil then
        playerData = {
            citizenid = citizenId,
            charinfo = {
                firstname = Framework.GetPlayerFirstNameByPlayer(player),
                lastname = Framework.GetPlayerLastNameByPlayer(player),
                birthdate = player.get("dateofbirth"),
                gender = Framework.GetPlayerGenderByPlayer(player),
                -- nationality = player.get("nationality"),
                phone = Framework.GetPlayerPhoneNumberByPlayer(player)
            },
            metadata = player.getMeta(),
            job = Framework.GetPlayerJobObjectAsQbByPlayer(player)
        }
    else
        playerData = MySQL.single.await("SELECT firstname, lastname, job, job_grade, metadata, dateofbirth, sex, phone_number FROM users WHERE JSON_VALUE(users.metadata, \"$.citizenId\") = ? LIMIT 1", { citizenId })
        if playerData then
            local ESXJobs = Framework.object.GetJobs()
            playerData.citizenId = citizenId
            charinfo = {
                firstname = CapitalFirstLetter(playerData.firstname),
                lastname = CapitalFirstLetter(playerData.lastname),
                birthdate = playerData.dateofbirth,
                gender = playerData.sex,
                -- nationality = playerData.nationality,
                phone = playerData.phone_number
            }
            playerData.metadata = playerData.metadata
            playerData.job = {
                name = playerData.job,
                label = ESXJobs?[playerData.job]?.label,
                payment = ESXJobs?[playerData.job]?.grades?[tostring(playerData.job_grade)]?.salary,
                --onduty = playerData?.jobDuty, -- to be released: https://github.com/esx-framework/esx_core/pull/947
                isboss = ESXJobs?[playerData.job]?.grades?[tostring(playerData.job_grade)]?.name == "boss",
                grade = {
                    name = ESXJobs?[playerData.job]?.grades?[tostring(playerData.job_grade)]?.label,
                    level = playerData.job_grade
                }
            }
        end
    end
    return playerData
end

--[[ -- should be removed since it's not used in the resource
function DB.GetOwnerName(cid)
    return MySQL.scalar.await("SELECT charinfo FROM `players` WHERE LOWER(`citizenid`) = ? LIMIT 1", {cid})
end
]]

-- Won't be implemented since there is no apartment system for default ESX
function DB.GetPlayerApartmentByCitizenId(citizenId)
end

function DB.GetPlayerLicenses(citizenId) -- CHECK: query syntax as I'm not too knowledgeable on SQL joins...
    local licenses = {}
    local player = Framework.GetPlayerByCitizenId(citizenId)
    if player ~= nil then
        licenses = Framework.GetPlayerLicensesByPlayer(player)
    else -- TODO: maybe I should get all available licenses and loop through them to check whether player have them or not
        local result = MySQL.query.await("SELECT user_licenses.type, licenses.label FROM user_licenses LEFT JOIN licenses ON user_licenses.type = licenses.type LEFT JOIN users ON user_licenses.owner = users.identifier WHERE JSON_VALUE(users.metadata, \"$.citizenId\") = ? ", {citizenId})
        if result then
            for i = 1, #result do
                local licenseName = result[i].type -- or _licenses[i].name ?   we'll see
                licenses[licenseName] = true
            end
        else
            licenses = {
                ["driver"] = false,
                ["business"] = false,
                ["weapon"] = false,
                ["pilot"] = false
            }
        end
    end
    return licenses
end