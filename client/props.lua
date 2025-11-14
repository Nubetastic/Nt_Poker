Props = {}

local tableObjs = {}
local playerChips = {}
local tablePos = nil
local tableHeading = 0.0
local tableLower = 0.05
local currentLocationId = nil
local localHandObj = nil

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
    local obj = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, true, true, false)
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

local function clearLocalHandObj()
    if localHandObj and DoesEntityExist(localHandObj) then
        DeleteObject(localHandObj)
    end
    localHandObj = nil
end

local function giveLocalHandProp()
    clearLocalHandObj()
    local model = (ConfigProps and ConfigProps.HandCardModel) or "p_cs_holdemhand02x"
    local hash = loadModel(model)
    if not hash then return end
    local ped = PlayerPedId()
    local obj = CreateObjectNoOffset(hash, 0.0, 0.0, 0.0, true, true, false)
    if not obj then return end
    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, true, true)
    FreezeEntityPosition(obj, false)
    local bone = "SKEL_L_Finger13"
    local boneIndex = GetEntityBoneIndexByName(ped, bone)

    AttachEntityToEntity(obj, ped, boneIndex, .033, -.016, 0, 90.0, 0.0, 50.0, true, true, false, true, 1, true)
    localHandObj = obj
end

local function worldFrom(base, heading, forward, right, up)
    local h = math.rad(heading or 0.0)
    local sinH = math.sin(h)
    local cosH = math.cos(h)
    local dx = (right or 0.0) * cosH - (forward or 0.0) * sinH
    local dy = (right or 0.0) * sinH + (forward or 0.0) * cosH
    return vector3(base.x + dx, base.y + dy, base.z + (up or 0.0))
end

local function clearTableObjs()
    for _,o in ipairs(tableObjs) do
        deleteObjectSafe(o)
    end
    tableObjs = {}
end

local function clearPlayerChips()
    for k,o in pairs(playerChips) do
        deleteObjectSafe(o)
        playerChips[k] = nil
    end
end

local function spawnAndStore(model, coords, heading)
    local obj = createLocalObject(model, coords, heading)
    if obj then table.insert(tableObjs, obj) end
    return obj
end

function Props:Start(game, locationId, playerSeatOrder)
    currentLocationId = locationId
    local loc = Config.Locations[locationId]
    if not loc or not loc.Table or not loc.Table.Coords then return end
    tablePos = loc.Table.Coords
    tableHeading = loc.Table.Heading or (tablePos.w or 0.0) or 0.0
    clearTableObjs()
    clearPlayerChips()
    local cfg = ConfigProps and ConfigProps.Props or {}
    local isHost = false
    for _,p in pairs(game.players or {}) do
        if (p.order == 1) and p.netId == GetPlayerServerId(PlayerId()) then
            isHost = true
            break
        end
    end
    if isHost then
        local planeCfg = cfg.Plane or {}
        local planeModel = planeCfg.model or "p_pokercaddy02x"
        local planeOff = planeCfg.offset or {}
        local planePos = worldFrom(tablePos, tableHeading, planeOff.x or 0.5, planeOff.y or -0.15, (planeOff.z or 0.88) - tableLower)
        local planeHeading = tableHeading + (planeOff.h or 0.0)
        spawnAndStore(planeModel, planePos, planeHeading)
        local deckCfg = cfg.Deck or {}
        local deckModel = deckCfg.model or "p_cards01x"
        local deckOff = deckCfg.offset or {}
        local deckPos = worldFrom(tablePos, tableHeading, deckOff.x or 0.18, deckOff.y or -0.18, (deckOff.z or 0.93) - tableLower)
        spawnAndStore(deckModel, deckPos, tableHeading)
        local potCfg = cfg.Pot or {}
        local potModel = potCfg.model or "p_pokerchipavarage01x"
        local potOff = potCfg.offset or {}
        local potPos = worldFrom(tablePos, tableHeading, potOff.x or 0.0, potOff.y or 0.0, (potOff.z or 0.93) - tableLower)
        spawnAndStore(potModel, potPos, tableHeading)
    end
    giveLocalHandProp()
    self:Update(game)
end

function Props:Update(game)
    if not game or not tablePos or not currentLocationId then return end
    local loc = Config.Locations[currentLocationId]
    if not loc or not loc.Chairs then return end
    local cfg = ConfigProps and ConfigProps.Props or {}
    local chipsCfg = cfg.PlayerChips or {}
    local chipsModelCfg = chipsCfg.model or "p_pokerchipavarage02x"
    local chipsOff = chipsCfg.offset or {}
    local r = chipsOff.r or 1.0
    local zOff = chipsOff.z or 0.93
    local present = {}
    for _,p in pairs(game.players or {}) do
        if p.netId == GetPlayerServerId(PlayerId()) then
            local order = p.seatIndex or p.order
            local chair = loc.Chairs and loc.Chairs[order]
            if chair and chair.Coords then
                local chairPos = vector3(chair.Coords.x, chair.Coords.y, chair.Coords.z)
                local dirX = chairPos.x - tablePos.x
                local dirY = chairPos.y - tablePos.y
                local len = math.sqrt(dirX*dirX + dirY*dirY)
                if len < 0.001 then len = 1.0 end
                dirX = dirX / len
                dirY = dirY / len
                local chipsX = tablePos.x + dirX * r
                local chipsY = tablePos.y + dirY * r
                local pos = vector3(chipsX, chipsY, tablePos.z + (zOff - tableLower))
                if not playerChips[order] or not DoesEntityExist(playerChips[order]) then
                    local chipsModel = chipsModelCfg
                    if type(chipsModelCfg) == 'table' and #chipsModelCfg > 0 then
                        chipsModel = chipsModelCfg[math.random(1, #chipsModelCfg)]
                    end
                    local heading = math.random() * 360.0
                    playerChips[order] = createLocalObject(chipsModel, pos, heading)
                else
                    FreezeEntityPosition(playerChips[order], false)
                    SetEntityCoords(playerChips[order], pos.x, pos.y, pos.z, false, false, false, true)
                    FreezeEntityPosition(playerChips[order], true)
                end
                present[order] = true
            end
            break
        end
    end
    for order,obj in pairs(playerChips) do
        if not present[order] then
            deleteObjectSafe(obj)
            playerChips[order] = nil
        end
    end

    if localHandObj then
        if game.step == ROUNDS.SHOWDOWN then
            clearLocalHandObj()
        else
            for _,p in pairs(game.players or {}) do
                if p.netId == GetPlayerServerId(PlayerId()) and p.hasFolded then
                    clearLocalHandObj()
                    break
                end
            end
        end
    else
        if game.step ~= ROUNDS.SHOWDOWN then
            for _,p in pairs(game.players or {}) do
                if p.netId == GetPlayerServerId(PlayerId()) and not p.hasFolded then
                    giveLocalHandProp()
                    break
                end
            end
        end
    end
end

function Props:OnLocalFold()
    clearLocalHandObj()
end

function Props:CleanupAll()
    clearTableObjs()
    clearPlayerChips()
    clearLocalHandObj()
    tablePos = nil
    currentLocationId = nil
end

function Props:DebugSpawnCandidates()
end
