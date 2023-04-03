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
        playerData = MySQL.query.await("SELECT firstname, lastname, job, job_grade, metadata, dateofbirth, sex, phone_number FROM users WHERE JSON_VALUE(users.metadata, \"$.citizenId\") = ? LIMIT 1", { citizenId })
        if playerData then -- compatibility with QB return data
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

function DB.ManageLicense(citizenid, type, status) -- TODO: implement if it's properly working in OG repo
end

function DB.UpdateAllLicenses(citizenid, incomingLicenses) -- TODO: implement if it's properly working in OG repo
end

function DB.SearchAllPlayersByData(data, jobType) -- CHECK: query syntax as I'm not too knowledgeable on SQL joins...
    local result = MySQL.query.await("SELECT JSON_VALUE(u.metadata, \"$.citizenId\"), u.firstname, u.lastname, u.dateofbirth, u.sex, u.phone_number, md.pfp FROM users u LEFT JOIN mdt_data md on JSON_VALUE(u.metadata, \"$.citizenId\") = md.cid WHERE LOWER(CONCAT(u.firstname, \" \", u.lastname)) LIKE :query OR LOWER(JSON_VALUE(u.metadata, \"$.citizenId\")) LIKE :query AND jobtype = :jobtype LIMIT 20", { query = string.lower("%"..data.."%"), jobtype = jobType })
    if result and next(result) then
        for i = 1, #result do -- compatibility with QB return data
            result[i].charinfo = {
                firstname = CapitalFirstLetter(result[i].firstname),
                lastname = CapitalFirstLetter(result[i].lastname),
                birthdate = result[i].dateofbirth,
                gender = result[i].sex,
                -- nationality = result[i].nationality,
                phone = result[i].phone_number
            }
        end
    end
    return result
end

function DB.SearchPlayerIncidentByData(data, jobType) -- CHECK: query syntax as I'm not too knowledgeable on SQL joins... TODO: (maybe it should be merged with DB.SearchAllPlayersByData as they both select same data, except this one selects metadata extra!)
    local result MySQL.query.await("SELECT JSON_VALUE(u.metadata, \"$.citizenId\"), u.firstname, u.lastname, u.dateofbirth, u.sex, u.phone_number, u.metadata, md.pfp from users u LEFT JOIN mdt_data md on JSON_VALUE(u.metadata, \"$.citizenId\") = md.cid WHERE LOWER(`citizenid`) LIKE :query AND `jobtype` = :jobtype LIMIT 30", {
        query = string.lower("%"..data.."%"), -- % wildcard, needed to search for all alike results
        jobtype = jobType
    })
    if result and next(result) then
        for i = 1, #result do -- compatibility with QB return data
            result[i].charinfo = {
                firstname = CapitalFirstLetter(result[i].firstname),
                lastname = CapitalFirstLetter(result[i].lastname),
                birthdate = result[i].dateofbirth,
                gender = result[i].sex,
                -- nationality = result[i].nationality,
                phone = result[i].phone_number
            }
        end
    end
    return result
end

function DB.SearchAllVehiclesByData(data) -- TODO: alter owned_vehicles add auto-increment id column - CHECK: query syntax as I'm not too knowledgeable on SQL joins...
    local result =  MySQL.query.await("SELECT ov.id, JSON_VALUE(u.metadata, \"$.citizenId\"), ov.plate, JSON_VALUE(ov.vehicle, \"$.model\"), ov.vehicle, ov.stored, u.firstname, u.lastname, u.dateofbirth, u.sex, u.phone_number FROM `owned_vehicles` ov LEFT JOIN users u ON ov.owner = u.identifier WHERE LOWER(`plate`) LIKE :query LIMIT 25", {
        query = string.lower("%"..data.."%")
    })
    if result and next(result) then
        for i = 1, #result do -- compatibility with QB return data
            result[i].charinfo = {
                firstname = CapitalFirstLetter(result[i].firstname),
                lastname = CapitalFirstLetter(result[i].lastname),
                birthdate = result[i].dateofbirth,
                gender = result[i].sex,
                -- nationality = result[i].nationality,
                phone = result[i].phone_number
            }
            result[i].state = result[i].stored
        end
    end
    return result
end

function DB.SearchVehicleDataByPlate(plate)
    local result = MySQL.query.await("select ov.*, u.firstname, u.lastname, u.dateofbirth, u.sex, u.phone_number from owned_vehicles ox LEFT JOIN users u ON ov.owner = u.identifier where ov.plate = :plate LIMIT 1", { plate = TrimString(plate)})
    if result and next(result) then
        for i = 1, #result do -- compatibility with QB return data
            result[i].charinfo = {
                firstname = CapitalFirstLetter(result[i].firstname),
                lastname = CapitalFirstLetter(result[i].lastname),
                birthdate = result[i].dateofbirth,
                gender = result[i].sex,
                -- nationality = result[i].nationality,
                phone = result[i].phone_number
            }
            result[i].state = result[i].stored
        end
    end
    return result
end