local lastObj = nil
local tableObjs = {}

local function loadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) and not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function createLocalObject(model, coords, heading)
    local hash = type(model) == 'number' and model or loadModel(model)
    if not hash then return nil end
    local obj = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, true, false, true)
    if heading then SetEntityHeading(obj, heading) end
    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, true, true)
    FreezeEntityPosition(obj, true)
    return obj
end

local function deleteObjectSafe(obj)
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
    end
end

local function clearTableObjs()
    for _,o in ipairs(tableObjs) do
        deleteObjectSafe(o)
    end
    tableObjs = {}
end

local function spawnAndStore(model, coords, heading)
    local obj = createLocalObject(model, coords, heading)
    if obj then table.insert(tableObjs, obj) end
    return obj
end

local function worldFrom(base, heading, forward, right, up)
    local h = math.rad(heading or 0.0)
    local sinH = math.sin(h)
    local cosH = math.cos(h)
    local dx = right * cosH - forward * sinH
    local dy = right * sinH + forward * cosH
    return vector3(base.x + dx, base.y + dy, base.z + up)
end

local function placeOnGround(obj)
    if not obj or not DoesEntityExist(obj) then return end
    FreezeEntityPosition(obj, false)
    PlaceEntityOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
end

RegisterCommand("proptest", function(source, args)
    local idx = tonumber(args[1] or "") or 1
    local model = ConfigPropsTest and ConfigPropsTest.CardProps and ConfigPropsTest.CardProps[idx]
    if not model then
        TriggerEvent('chat:addMessage', { args = { 'Poker', 'Invalid index' } })
        return
    end
    if lastObj then
        deleteObjectSafe(lastObj)
        lastObj = nil
    end
    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 1.0, 0.0, 0)
    local heading = GetEntityHeading(ped)
    lastObj = createLocalObject(model, pos, heading)
    local outfit = tonumber(args[2] or "")
    if lastObj and outfit then
        if outfit == 0 then outfit = math.random(0, 31) end
        Citizen.InvokeNative(0x4111BA46, lastObj, outfit)
    end
end, false)

RegisterCommand("loadtabletest", function()
    clearTableObjs()
    local ped = PlayerPedId()
    local pedPos = GetEntityCoords(ped)

    local nearestKey, nearestLoc, nearestDist = nil, nil, 999999.0
    for k,v in pairs(Config.Locations) do
        local d = #(pedPos - v.Table.Coords)
        if d < nearestDist then
            nearestDist = d
            nearestLoc = v
            nearestKey = k
        end
    end
    if not nearestLoc or nearestDist > 20.0 then
        TriggerEvent('chat:addMessage', { args = { 'Poker', 'No poker table nearby' } })
        return
    end

    local tablePos = nearestLoc.Table.Coords
    local heading = nearestLoc.Table.Heading or (tablePos.w or 0.0)

    local lower = 0.05

    local cfg = ConfigPropsTest and ConfigPropsTest.Props or {}

    local planeCfg = cfg.Plane or {}
    local planeModel = planeCfg.model or "p_pokercaddy02x"
    local planeOff = planeCfg.offset or {}
    local planePos = worldFrom(tablePos, heading, planeOff.x or 0.5, planeOff.y or -0.15, (planeOff.z or 0.88) - lower)
    local planeHeading = heading + (planeOff.h or 0.0)
    spawnAndStore(planeModel, planePos, planeHeading)

    local deckCfg = cfg.Deck or {}
    local deckModel = deckCfg.model or "p_cards01x"
    local deckOff = deckCfg.offset or {}
    local deckPos = worldFrom(tablePos, heading, deckOff.x or 0.18, deckOff.y or -0.18, (deckOff.z or 0.93) - lower)
    spawnAndStore(deckModel, deckPos, heading)

    local potCfg = cfg.Pot or {}
    local potModel = potCfg.model or "p_pokerchipavarage01x"
    local potOff = potCfg.offset or {}
    local potPos = worldFrom(tablePos, heading, potOff.x or 0.0, potOff.y or 0.0, (potOff.z or 0.93) - lower)
    spawnAndStore(potModel, potPos, heading)

    local chipsCfg = cfg.PlayerChips or {}
    local chipsModel = chipsCfg.model or "p_pokerchipavarage02x"
    local chipsOff = chipsCfg.offset or {}
    local r = chipsOff.r or 1.0
    local zOff = chipsOff.z or 0.93
    local degOff = chipsOff.deg or 0.0
    local dirX = pedPos.x - tablePos.x
    local dirY = pedPos.y - tablePos.y
    local len = math.sqrt(dirX*dirX + dirY*dirY)
    if len < 0.001 then len = 1.0 end
    dirX = dirX / len
    dirY = dirY / len
    local rad = math.rad(degOff)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)
    local rotX = dirX * cosA - dirY * sinA
    local rotY = dirX * sinA + dirY * cosA
    local chipsX = tablePos.x + rotX * r
    local chipsY = tablePos.y + rotY * r
    local playerChipsPos = vector3(chipsX, chipsY, tablePos.z + (zOff - lower))
    spawnAndStore(chipsModel, playerChipsPos, heading)
end, false)

RegisterCommand("cleartabletest", function()
    clearTableObjs()
    if lastObj then deleteObjectSafe(lastObj) lastObj = nil end
end, false)

local prepState = { tablePos = nil, tableHeading = nil }

local function fmtf(n)
    return string.format("%.8f", n)
end

local function buildConfigBlock(name, tpos, chairs)
    local lines = {}
    table.insert(lines, "")
    table.insert(lines, "[\""..name.."\"] = {")
    table.insert(lines, "    Table = {")
    table.insert(lines, "        Coords = vector3("..fmtf(tpos.x)..", "..fmtf(tpos.y)..", "..fmtf(tpos.z)..")")
    table.insert(lines, "    },")
    table.insert(lines, "    MaxPlayers = 6,")
    table.insert(lines, "    Chairs = {")
    for i,seat in ipairs(chairs) do
        table.insert(lines, "        ["..i.."] = {")
        table.insert(lines, "            Coords = vector4("..fmtf(seat.x)..", "..fmtf(seat.y)..", "..fmtf(seat.z + 0.5)..", "..fmtf(seat.h).."),")
        table.insert(lines, "        },")
    end
    table.insert(lines, "    },")
    table.insert(lines, "},")
    return table.concat(lines, "\n")
end

local function computeAndSaveFromChair(entity)
    if not entity or not DoesEntityExist(entity) then return end
    if not prepState.tablePos then return end
    local tpos = prepState.tablePos
    local cpos = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    local dx = cpos.x - tpos.x
    local dy = cpos.y - tpos.y
    local r = math.sqrt(dx*dx + dy*dy)
    local seats = {}
    local function headingToCenter(px, py)
        return GetHeadingFromVector_2d(tpos.x - px, tpos.y - py)
    end
    table.insert(seats, { x = cpos.x, y = cpos.y, z = cpos.z, h = headingToCenter(cpos.x, cpos.y) })
    local pool = GetGamePool('CObject') or {}
    for _,e in ipairs(pool) do
        if e ~= entity and DoesEntityExist(e) and GetEntityModel(e) == model then
            local p = GetEntityCoords(e)
            local dToTable = #(p - tpos)
            if dToTable > 0.1 and math.abs(dToTable - r) < 1.0 then
                table.insert(seats, { x = p.x, y = p.y, z = p.z, h = headingToCenter(p.x, p.y) })
            end
        end
        if #seats >= 6 then break end
    end
    local function seatAngle(s)
        local vx = s.x - tpos.x
        local vy = s.y - tpos.y
        local a = math.deg(math.atan(vy, vx))
        if a < 0 then a = a + 360.0 end
        return a
    end
    table.sort(seats, function(a,b) return seatAngle(a) < seatAngle(b) end)
    if #seats < 6 then
        local baseA = seatAngle(seats[1])
        for i=#seats+1,6 do
            local ang = math.rad(baseA + (i-1)*60.0)
            local px = tpos.x + math.cos(ang)*r
            local py = tpos.y + math.sin(ang)*r
            local pz = cpos.z
            table.insert(seats, { x = px, y = py, z = pz, h = headingToCenter(px, py) })
        end
    end
    local name = string.format("Generated_%d_%d_%d", math.floor(tpos.x), math.floor(tpos.y), GetGameTimer())
    local block = buildConfigBlock(name, tpos, seats)
    TriggerServerEvent('nt_poker:proptest:save', block)
end

RegisterNetEvent('nt_poker:proptest:saved', function(ok)
    if ok then
        TriggerEvent('chat:addMessage', { args = { 'Poker', 'Saved to tablePrep.md' } })
    else
        TriggerEvent('chat:addMessage', { args = { 'Poker', 'Save failed' } })
    end
end)

CreateThread(function()
    if GetResourceState and GetResourceState('ox_target') == 'started' and exports and exports.ox_target then
        local function isTableEntity(ent)
            if not ent or not DoesEntityExist(ent) then return false end
            if IsEntityAPed(ent) or IsEntityAVehicle(ent) then return false end
            local model = GetEntityModel(ent)
            local min, max = GetModelDimensions(model)
            local dx = (max.x - min.x)
            local dy = (max.y - min.y)
            local dz = (max.z - min.z)
            return dx >= 0.8 and dy >= 0.8 and dz >= 0.5
        end
        exports.ox_target:addGlobalObject({
            {
                name = 'nt_poker_preptable',
                label = 'PrepTable',
                canInteract = function(entity)
                    return isTableEntity(entity)
                end,
                onSelect = function(data)
                    local ent = data and data.entity
                    if not ent then return end
                    prepState.tablePos = GetEntityCoords(ent)
                    prepState.tableHeading = GetEntityHeading(ent)
                    TriggerEvent('chat:addMessage', { args = { 'Poker', 'Table set' } })
                end
            }
        })
        exports.ox_target:addGlobalObject({
            {
                name = 'nt_poker_prepchair',
                label = 'PrepChair',
                canInteract = function(entity)
                    return prepState.tablePos ~= nil
                end,
                onSelect = function(data)
                    local ent = data and data.entity
                    if not ent then return end
                    computeAndSaveFromChair(ent)
                end
            }
        })
    end
end)
