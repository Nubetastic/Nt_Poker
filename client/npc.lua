NPCVisuals = {}

local npcPeds = {}
local npcHandObjs = {}
local isHostClient = false
local currentLocationId = nil

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

local function deletePedSafe(ped)
    if ped and DoesEntityExist(ped) then
        DeletePed(ped)
    end
end

local function deleteObjSafe(obj)
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
    end
end

local function attachHandToPed(ped)
    local model = (ConfigProps and ConfigProps.HandCardModel) or "p_cs_holdemhand02x"
    local hash = loadModel(model)
    if not hash then return nil end
    local obj = CreateObjectNoOffset(hash, 0.0, 0.0, 0.0, true, true, false)
    if not obj then return nil end
    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, true, true)
    FreezeEntityPosition(obj, false)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_L_Finger13")
    AttachEntityToEntity(obj, ped, boneIndex, .033, -.016, 0, 90.0, 0.0, 50.0, true, true, false, true, 1, true)
    return obj
end

local function isHost(game)
    return game and game.propHostNetId and (game.propHostNetId == GetPlayerServerId(PlayerId())) or false
end

local function ensureNpcPedFor(game, loc, player)
    local seat = player.seatIndex or player.order
    if not seat or not loc or not loc.Chairs then return end
    local chair = loc.Chairs[seat]
    if not chair or not chair.Coords then return end
    if npcPeds[seat] and DoesEntityExist(npcPeds[seat]) then return end
    local model = (player.npcModel or (ConfigNPC and ConfigNPC.Models and ConfigNPC.Models.Common and ConfigNPC.Models.Common[1])) or "u_m_m_racforeman_01"
    local hash = loadModel(model)
    if not hash then return end
    local pos = vector3(chair.Coords.x, chair.Coords.y, chair.Coords.z)
    local ped = CreatePed(hash, pos.x, pos.y, pos.z, chair.Coords.w or 0.0, true, true, true, true)
    if not ped then return end
    SetEntityHeading(ped, chair.Coords.w or 0.0)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    local netId = NetworkGetNetworkIdFromEntity(ped)
    -- SetNetworkIdCanMigrate(netId, true) -- AI keeps adding this in, its not a real native.
    SetNetworkIdExistsOnAllMachines(netId, true)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, 0, 1, 1, 1, false)
    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(ped, GetHashKey("GENERIC_SEAT_CHAIR_TABLE_SCENARIO"), chair.Coords.x, chair.Coords.y, chair.Coords.z, chair.Coords.w or 0.0, -1, false, true)
    RequestAnimDict("mini_games@poker_mg@base")
    local t = GetGameTimer() + 5000
    while not HasAnimDictLoaded("mini_games@poker_mg@base") and GetGameTimer() < t do Wait(0) end
    TaskPlayAnim(ped, "mini_games@poker_mg@base", "hold_cards_idle_a", 1.0, 1.0, -1, 25, 1.0, true, 0, false, 0, false)
    npcPeds[seat] = ped
end

local function cleanupAll()
    for k,p in pairs(npcPeds) do
        deletePedSafe(p)
        npcPeds[k] = nil
    end
    for k,o in pairs(npcHandObjs) do
        deleteObjSafe(o)
        npcHandObjs[k] = nil
    end
    currentLocationId = nil
end

function NPCVisuals:Start(game, locationId)
    cleanupAll()
    currentLocationId = locationId
    isHostClient = isHost(game)
    if not isHostClient then return end
    local loc = Config.Locations[locationId]
    if not loc then return end
    for _,p in pairs(game.players or {}) do
        if p.isNpc then
            ensureNpcPedFor(game, loc, p)
            local seat = p.seatIndex or p.order
            if seat and npcPeds[seat] and DoesEntityExist(npcPeds[seat]) and game.step ~= ROUNDS.SHOWDOWN and not p.hasFolded then
                if not npcHandObjs[seat] or not DoesEntityExist(npcHandObjs[seat]) then
                    npcHandObjs[seat] = attachHandToPed(npcPeds[seat])
                end
            end
        end
    end
end

function NPCVisuals:Update(game)
    if not currentLocationId then return end
    local hostNow = isHost(game)
    if hostNow ~= isHostClient then
        cleanupAll()
        isHostClient = hostNow
    end
    if not isHostClient then return end
    local loc = Config.Locations[currentLocationId]
    if not loc then return end
    local present = {}
    for _,p in pairs(game.players or {}) do
        if p.isNpc then
            ensureNpcPedFor(game, loc, p)
            local seat = p.seatIndex or p.order
            if seat then
                present[seat] = true
                local ped = npcPeds[seat]
                if ped and DoesEntityExist(ped) then
                    local shouldHaveCards = (game.step ~= ROUNDS.SHOWDOWN) and (not p.hasFolded)
                    if shouldHaveCards then
                        if not npcHandObjs[seat] or not DoesEntityExist(npcHandObjs[seat]) then
                            npcHandObjs[seat] = attachHandToPed(ped)
                        end
                    else
                        if npcHandObjs[seat] then
                            deleteObjSafe(npcHandObjs[seat])
                            npcHandObjs[seat] = nil
                        end
                    end
                end
            end
        end
    end
    for seat, ped in pairs(npcPeds) do
        if not present[seat] then
            deletePedSafe(ped)
            npcPeds[seat] = nil
            if npcHandObjs[seat] then
                deleteObjSafe(npcHandObjs[seat])
                npcHandObjs[seat] = nil
            end
        end
    end
end

function NPCVisuals:CleanupAll()
    cleanupAll()
end
