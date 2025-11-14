local RSGCore = exports['rsg-core']:GetCoreObject()

local locations = {}

local pendingGames = {}
local activeGames = {}

local function sortAndAssignOrders(players, startingSeat)
    table.sort(players, function(a,b)
        local sa = a.seatIndex or a:getSeatIndex() or 999
        local sb = b.seatIndex or b:getSeatIndex() or 999
        if sa == sb then return (a:getNetId() or 0) < (b:getNetId() or 0) end
        return sa < sb
    end)
    local startIdx = 1
    for i,p in ipairs(players) do
        if (p.seatIndex or p:getSeatIndex()) == startingSeat then
            startIdx = i
            break
        end
    end
    for i=1, startIdx-1 do
        local x = table.remove(players, 1)
        table.insert(players, x)
    end
    for i,p in ipairs(players) do
        p:setOrder(i)
    end
end

local function nextStartingSeat(currentSeat, maxSeats, players)
    if not currentSeat then return nil end
    local occupied = {}
    for _,p in ipairs(players) do
        if p.seatIndex or p:getSeatIndex() then
            occupied[p.seatIndex or p:getSeatIndex()] = true
        end
    end
    if not maxSeats or maxSeats < 1 then maxSeats = 6 end
    local tries = 0
    local s = currentSeat
    while tries < maxSeats do
        s = s + 1
        if s > maxSeats then s = 1 end
        if occupied[s] then return s end
        tries = tries + 1
    end
    return currentSeat
end








-- Initial set up of locations
Citizen.CreateThread(function()
    for k,v in pairs(Config.Locations) do
        local location = Location:New({
            id = k,
            state = LOCATION_STATES.EMPTY,
            tableCoords = v.Table.Coords,
            maxPlayers = v.MaxPlayers,
        })
        location.waitingPlayers = {}
        table.insert(locations, location)
    end
end)








--------

RegisterServerEvent("rainbow_poker:Server:RequestCharacterName", function()
	local _source = source

    local Player = RSGCore.Functions.GetPlayer(_source)
    local firstname = (Player and Player.PlayerData and Player.PlayerData.charinfo and Player.PlayerData.charinfo.firstname) or GetPlayerName(_source)
    TriggerClientEvent("rainbow_poker:Client:ReturnRequestCharacterName", _source, firstname)
end)



RegisterServerEvent("rainbow_poker:Server:RequestUpdatePokerTables", function()
	local _source = source

    TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", _source, locations)

end)



RegisterServerEvent("rainbow_poker:Server:StartNewPendingGame", function(player1sChosenName, anteAmount, tableLocationIndex)
	local _source = source

    if Config.DebugPrint then print("StartNewPendingGame", player1sChosenName, anteAmount, tableLocationIndex) end

    -- Validate location index and state
    local loc = locations[tableLocationIndex]
    if not loc then
        if Config.DebugPrint then print("StartNewPendingGame: invalid location index", tableLocationIndex) end
        return
    end
    -- Make sure this location is still in state EMPTY (i.e. no one else has started a game at the same time)
    if loc:getState() ~= LOCATION_STATES.EMPTY then
        return
    end

    -- Make sure this player isn't already in a pending poker game
    if findPendingGameByPlayerNetId(_source) ~= false then
        TriggerClientEvent('poker:notify', _source, { description = 'You are still in a pending poker game.', type = 'error', duration = 6000 })
        return
    end

    -- Make sure this player isn't already in an active poker game
    if findActiveGameByPlayerNetId(_source) ~= false then
        TriggerClientEvent('poker:notify', _source, { description = 'You are still in an active poker game.', type = 'error', duration = 6000 })
        return
    end

    player1sChosenName = truncateString(player1sChosenName, 10)

    if not hasMoney(_source, anteAmount) then
        TriggerClientEvent('poker:notify', _source, { description = "You don't have enough for the ante.", type = 'error', duration = 6000 })
        return
    end

    math.randomseed(os.time())

    local player1NetId = _source

    local pendingPlayer1 = Player:New({
        netId = player1NetId,
        name = player1sChosenName,
        order = 1,
    })
    pendingPlayer1.seatIndex = math.random(1, loc:getMaxPlayers())
    
    -- Create the PendingGame
    local newPendingGame = PendingGame:New({
        initiatorNetId = _source,
        players = {
            pendingPlayer1,
        },
        ante = anteAmount,
    })

    locations[tableLocationIndex]:setPendingGame(newPendingGame)
    locations[tableLocationIndex]:setState(LOCATION_STATES.PENDING_GAME)

    if Config.DebugPrint then print("StartNewGame - newPendingGame", newPendingGame) end

    -- Make the player sit at the chair of their order
    TriggerClientEvent("rainbow_poker:Client:ReturnStartNewPendingGame", _source, tableLocationIndex, pendingPlayer1, pendingPlayer1.seatIndex)

    TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)

    -- Discord logging removed
end)

RegisterServerEvent("rainbow_poker:Server:JoinGame", function(playersChosenName, tableLocationIndex)
	local _source = source

    if Config.DebugPrint then print("JoinGame", playersChosenName, tableLocationIndex) end

    local loc = locations[tableLocationIndex]
    if not loc then
        if Config.DebugPrint then print("JoinGame: invalid location index", tableLocationIndex) end
        return
    end
    local pendingGame = loc:getPendingGame()
    if not pendingGame then
        if loc:getState() == LOCATION_STATES.GAME_IN_PROGRESS then
            local game = activeGames[tableLocationIndex]
            if not game then return end
            if loc.waitingPlayers then
                for _,wp in ipairs(loc.waitingPlayers) do
                    if wp.netId == _source then
                        TriggerClientEvent('poker:notify', _source, { description = 'You are already waiting for the next hand.', type = 'inform', duration = 6000 })
                        return
                    end
                end
            else
                loc.waitingPlayers = {}
            end
            local taken = {}
            for _,p in pairs(game:getPlayers()) do
                local s = p.seatIndex or p:getOrder()
                taken[s] = true
            end
            for _,wp in ipairs(loc.waitingPlayers) do
                taken[wp.seatIndex] = true
            end
            local available = {}
            for i=1, loc:getMaxPlayers() do
                if not taken[i] then table.insert(available, i) end
            end
            if #available == 0 then
                TriggerClientEvent('poker:notify', _source, { description = 'No seats available.', type = 'error', duration = 6000 })
                return
            end
            if not hasMoney(_source, game:getAnte()) then
                TriggerClientEvent('poker:notify', _source, { description = "You don't have enough for the ante.", type = 'error', duration = 6000 })
                return
            end
            local seatIndex = available[math.random(1, #available)]
            table.insert(loc.waitingPlayers, { netId = _source, name = truncateString(playersChosenName, 12), seatIndex = seatIndex })
            TriggerClientEvent("rainbow_poker:Client:ReturnJoinGame", _source, tableLocationIndex, { order = seatIndex }, seatIndex)
            TriggerClientEvent('poker:notify', _source, { description = 'You will join next hand.', type = 'inform', duration = 6000 })
            TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)
            return
        else
            if Config.DebugPrint then print("JoinGame: no pending game at location", tableLocationIndex) end
            return
        end
    end


    -- Check if the game is already maxed out
    if #pendingGame:getPlayers() >= loc:getMaxPlayers() then
        TriggerClientEvent('poker:notify', _source, { description = 'This poker game is full.', type = 'error', duration = 6000 })
        return
    end

    -- Make sure this player isn't already in a pending poker game
    if findPendingGameByPlayerNetId(_source) ~= false then
        TriggerClientEvent('poker:notify', _source, { description = 'You are still in a pending poker game.', type = 'error', duration = 6000 })
        return
    end

    -- Make sure this player isn't already in an active poker game
    if findActiveGameByPlayerNetId(_source) ~= false then
        TriggerClientEvent('poker:notify', _source, { description = 'You are still in an active poker game.', type = 'error', duration = 6000 })
        return
    end


    playersChosenName = truncateString(playersChosenName, 12)

    local playerNetId = _source

    local taken = {}
    for k,v in pairs(pendingGame:getPlayers()) do
        if v.seatIndex then
            taken[v.seatIndex] = true
        end
    end
    local available = {}
    for i=1, loc:getMaxPlayers() do
        if not taken[i] then
            table.insert(available, i)
        end
    end
    if not hasMoney(_source, pendingGame:getAnte()) then
        TriggerClientEvent('poker:notify', _source, { description = "You don't have enough for the ante.", type = 'error', duration = 6000 })
        return
    end
    local seatIndex = available[math.random(1, #available)]
    local pendingPlayer = Player:New({
        netId = playerNetId,
        name = playersChosenName,
        order = #pendingGame:getPlayers()+1,
    })
    pendingPlayer.seatIndex = seatIndex

    -- Add player & init their hole cards
    pendingGame:addPlayer(pendingPlayer)

    -- Make the player sit at the chair of their order
    TriggerClientEvent("rainbow_poker:Client:ReturnJoinGame", _source, tableLocationIndex, pendingPlayer, pendingPlayer.seatIndex)

    TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)

    -- Discord logging removed
end)


RegisterServerEvent("rainbow_poker:Server:FinalizePendingGameAndBegin", function(tableLocationIndex)
	local _source = source

    if Config.DebugPrint then print("FinalizePendingGameAndBegin", tableLocationIndex) end

    local loc = locations[tableLocationIndex]
    if not loc then
        if Config.DebugPrint then print("FinalizePendingGameAndBegin: invalid location index", tableLocationIndex) end
        return
    end
    local pendingGame = loc:getPendingGame()
    if not pendingGame then
        if Config.DebugPrint then print("FinalizePendingGameAndBegin: no pending game at location", tableLocationIndex) end
        return
    end

    -- Check there's 1+ players, and not >12
    if #pendingGame:getPlayers() < 2 then
        TriggerClientEvent('poker:notify', _source, { description = 'You need at least 1 other player to join your poker game.', type = 'error', duration = 6000 })
        return
    elseif #pendingGame:getPlayers() > 12 then
        TriggerClientEvent('poker:notify', _source, { description = 'You cannot have more than 12 players in your poker game.', type = 'error', duration = 6000 })
        return
    end

    -- Make sure all the pending players have enough money
    for k,v in pairs(pendingGame:getPlayers()) do
        if not hasMoney(v:getNetId(), pendingGame:getAnte()) then
            TriggerEvent("rainbow_poker:Server:CancelPendingGame", tableLocationIndex)
            TriggerClientEvent('poker:notify', v:getNetId(), { description = "You don't have the ante money.", type = 'error', duration = 6000 })
            return
        end
    end

    -- Add players to active game
    local activeGamePlayers = {}
    for k,v in pairs(pendingGame:getPlayers()) do
        if takeMoney(v:getNetId(), pendingGame:getAnte()) then
            table.insert(activeGamePlayers, Player:New({
                netId = v:getNetId(),
                name = v:getName(),
                order = v:getOrder(),
                seatIndex = v.seatIndex,
                totalAmountBetInGame = pendingGame:getAnte(),
            }))
        else
            TriggerEvent("rainbow_poker:Server:CancelPendingGame", tableLocationIndex)
            return
        end
    end

    local hostNetId = pendingGame:getInitiatorNetId()
    local hostSeat = nil
    for _,p in pairs(pendingGame:getPlayers()) do
        if p:getNetId() == hostNetId then
            hostSeat = p.seatIndex or p:getSeatIndex()
            break
        end
    end
    if not hostSeat and #activeGamePlayers > 0 then
        hostSeat = activeGamePlayers[1].seatIndex or activeGamePlayers[1]:getSeatIndex()
    end
    if hostSeat then
        sortAndAssignOrders(activeGamePlayers, hostSeat)
    end

    local newActiveGame = Game:New({
        locationIndex = tableLocationIndex,
        players = activeGamePlayers,
        ante = pendingGame:getAnte(),
        bettingPool = pendingGame:getAnte() * #pendingGame:getPlayers(),
    })

    newActiveGame:init()
    newActiveGame:moveToNextRound()

    activeGames[tableLocationIndex] = newActiveGame

    locations[tableLocationIndex]:setPendingGame(nil)
    locations[tableLocationIndex]:setState(LOCATION_STATES.GAME_IN_PROGRESS)

    TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)

    -- To all of the game's players
    for k,player in pairs(newActiveGame:getPlayers()) do
        local seatIndexToSend = player:getOrder()
        for _,p in pairs(pendingGame:getPlayers()) do
            if p:getNetId() == player:getNetId() and p.seatIndex then
                seatIndexToSend = p.seatIndex
                break
            end
        end
        TriggerClientEvent("rainbow_poker:Client:StartGame", player:getNetId(), newActiveGame, player.seatIndex or seatIndexToSend)
    end

    Wait(1000)
    -- newActiveGame:startTurnTimer(newActiveGame:findPlayerByNetId(_source))

end)

RegisterServerEvent("rainbow_poker:Server:CancelPendingGame", function(tableLocationIndex)
	local _source = source

    if Config.DebugPrint then print("CancelPendingGame", tableLocationIndex) end

    local loc = locations[tableLocationIndex]
    if not loc then
        if Config.DebugPrint then print("CancelPendingGame: invalid location index", tableLocationIndex) end
        return
    end

    if not loc:getPendingGame() then
        if Config.DebugPrint then print("CancelPendingGame: no pending game at location", tableLocationIndex) end
        return
    end

    for k,v in pairs(loc:getPendingGame():getPlayers()) do
        TriggerClientEvent("rainbow_poker:Client:CancelPendingGame", v:getNetId(), tableLocationIndex)
        TriggerClientEvent('poker:notify', v:getNetId(), { description = 'The pending poker game has been canceled.', type = 'inform', duration = 6000 })
    end

    locations[tableLocationIndex]:setPendingGame(nil)
    locations[tableLocationIndex]:setState(LOCATION_STATES.EMPTY)

    TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)

    -- Discord logging removed

end)


RegisterServerEvent("rainbow_poker:Server:PlayerActionCheck", function(tableLocationIndex)
	local _source = source

    if Config.DebugPrint then print("rainbow_poker:Server:PlayerActionCheck", _source, tableLocationIndex) end

    local game = findActiveGameByPlayerNetId(_source)

    game:stopTurnTimer()

    game:onPlayerDidActionCheck(_source)

    if not game:advanceTurn() then
        checkForWinCondition(game)
    end

    TriggerUpdate(game)
end)

RegisterServerEvent("rainbow_poker:Server:PlayerActionRaise", function(amountToRaise)
	local _source = source

    if Config.DebugPrint then print("rainbow_poker:Server:PlayerActionRaise - _source, amountToRaise:", _source, amountToRaise) end

    local game = findActiveGameByPlayerNetId(_source)
    local player = game and game:findPlayerByNetId(_source) or nil
    if not game or not player or game:getCurrentTurn() ~= player:getOrder() or player:getIsAllIn() then
        return
    end

    game:stopTurnTimer()

    amountToRaise = tonumber(amountToRaise)
    if takeMoney(_source, amountToRaise) then
        game:onPlayerDidActionRaise(_source, amountToRaise)
    else
        local cash = getCash(_source)
        if cash <= 0 then
            fold(_source)
            return
        end
        local potBefore = game:getBettingPool()
        local PlayerObj = RSGCore.Functions.GetPlayer(_source)
        if PlayerObj then PlayerObj.Functions.RemoveMoney('cash', cash, 'poker-allin') end
        game:addSidePot(potBefore)
        game:onPlayerDidActionAllIn(_source, cash)
    end

    if not game:advanceTurn() then
        checkForWinCondition(game)
    end

    TriggerUpdate(game)
end)

RegisterServerEvent("rainbow_poker:Server:PlayerActionCall", function()
	local _source = source

    if Config.DebugPrint then print("rainbow_poker:Server:PlayerActionCall", _source) end

    local game = findActiveGameByPlayerNetId(_source)

    if not game then return end
    local player = game:findPlayerByNetId(_source)
    if not player or game:getCurrentTurn() ~= player:getOrder() then
        TriggerClientEvent('poker:notify', _source, { description = 'Not your turn.', type = 'error', duration = 4000 })
        return
    end
    if player:getIsAllIn() then
        return
    end

    game:stopTurnTimer()

    local player = game:findPlayerByNetId(_source)
    local amount = game:getRoundsHighestBet() - player:getAmountBetInRound()

    if takeMoney(_source, amount) then
        game:onPlayerDidActionCall(_source)
    else
        local cash = getCash(_source)
        if cash <= 0 then
            fold(_source)
            return
        end
        local potBefore = game:getBettingPool()
        local PlayerObj = RSGCore.Functions.GetPlayer(_source)
        if PlayerObj then PlayerObj.Functions.RemoveMoney('cash', cash, 'poker-allin') end
        game:addSidePot(potBefore)
        game:onPlayerDidActionAllIn(_source, cash)
    end

    if not game:advanceTurn() then
        checkForWinCondition(game)
    end

    TriggerUpdate(game)
end)

RegisterServerEvent("rainbow_poker:Server:PlayerActionFold", function()
	local _source = source

    if Config.DebugPrint then print("rainbow_poker:Server:PlayerActionFold", _source) end

    fold(_source)
end)

RegisterServerEvent("rainbow_poker:Server:PlayerLeave", function()
	local _source = source

    if Config.DebugPrint then print("rainbow_poker:Server:PlayerLeave", _source) end

    -- Double-check that the player has already folded
    local game = findActiveGameByPlayerNetId(_source)
    local player = game:findPlayerByNetId(_source)
    if Config.DebugPrint then print("rainbow_poker:Server:PlayerLeave - player", player) end
    if game:getStep() ~= ROUNDS.SHOWDOWN and player:getHasFolded() == false then
        print("WARNING: Player trying to leave game pre-showdown when they haven't folded yet.", _source)
        return
    end

    TriggerClientEvent("rainbow_poker:Client:ReturnPlayerLeave", _source)

    if game and player then
        player.hasLeftSession = true
    end

end)


function checkForWinCondition(game)
    
    if Config.DebugPrint then print("checkForWinCondition()") end

    local isWinCondition = false

    -- See if we're entering the Showdown round
    if game:getStep() == ROUNDS.RIVER then
        if Config.DebugPrint then print("checkForWinCondition() - true - due to River") end
        isWinCondition = true
        game:moveToNextRound()
    end

    -- See if everyone has folded except for 1
    local numPlayersFolded = 0
    for k,player in pairs(game:getPlayers()) do
        if player:getHasFolded() then
            numPlayersFolded = numPlayersFolded + 1
        end
    end
    if numPlayersFolded >= #game:getPlayers()-1 then
        if Config.DebugPrint then print("checkForWinCondition() - true - due to folds") end
        isWinCondition = true
    end


    if isWinCondition then

        game:stopTurnTimer()

        local winScenario = getWinScenarioFromSetOfPlayers(game:getPlayers(), game:getBoard(), game:getStep())
        if Config.DebugPrint then print("checkForWinCondition() - WIN - winScenario:", winScenario) end
        -- if Config.Debug then writeDebugWinScenario(winScenario) end

        -- Give the pot money
        if not winScenario:getIsTrueTie() then
            local winnerNetId
            if winScenario:getWinningHand() then
                winnerNetId = winScenario:getWinningHand():getPlayerNetId()
            else
                for k,player in pairs(game:getPlayers()) do
                    if not player:getHasFolded() then
                        winnerNetId = player:getNetId()
                        break
                    end
                end
            end
            if winnerNetId then
                giveMoney(winnerNetId, game:getBettingPool())
            end
        else
            local splitAmount = game:getBettingPool() / #winScenario:getTiedHands()
            for k,tiedHand in pairs(winScenario:getTiedHands()) do
                local pid = tiedHand:getPlayerNetId()
                giveMoney(pid, splitAmount)
            end
        end

        -- Alert the win to all players of this poker game
        for k,player in pairs(game:getPlayers()) do
            TriggerClientEvent("rainbow_poker:Client:AlertWin", player:getNetId(), winScenario)
        end

        for k,player in pairs(game:getPlayers()) do
            TriggerClientEvent('poker:notify', player:getNetId(), { description = 'Next hand in 10 seconds. Press DOWN to leave.', type = 'inform', duration = 10000 })
        end

        Citizen.SetTimeout(10 * 1000, function()
            local continuingPlayers = {}
            for k,player in pairs(game:getPlayers()) do
                if not player.hasLeftSession then
                    table.insert(continuingPlayers, player)
                end
            end

            if #continuingPlayers < 2 then
                endAndCleanupGame(game)
                return
            end

            local activeGamePlayers = {}
            for k,player in ipairs(continuingPlayers) do
                if takeMoney(player:getNetId(), game:getAnte()) then
                    table.insert(activeGamePlayers, Player:New({
                        netId = player:getNetId(),
                        name = player:getName(),
                        order = #activeGamePlayers + 1,
                        seatIndex = player.seatIndex,
                        totalAmountBetInGame = game:getAnte(),
                    }))
                else
                    TriggerClientEvent('poker:notify', player:getNetId(), { description = 'Insufficient funds for ante. Leaving table.', type = 'error', duration = 10000 })
                end
            end

            local locationIndex = game:getLocationIndex()
            local ante = game:getAnte()
            local loc = locations[locationIndex]
            local hasWaiting = (loc and loc.waitingPlayers and #loc.waitingPlayers > 0)

            if hasWaiting then
                endAndCleanupGame(game)
            end

            if loc and loc.waitingPlayers then
                for _,wp in ipairs(loc.waitingPlayers) do
                    if takeMoney(wp.netId, ante) then
                        table.insert(activeGamePlayers, Player:New({
                            netId = wp.netId,
                            name = wp.name,
                            order = #activeGamePlayers + 1,
                            seatIndex = wp.seatIndex,
                            totalAmountBetInGame = ante,
                        }))
                    else
                        TriggerClientEvent('poker:notify', wp.netId, { description = 'Insufficient funds for ante. Leaving queue.', type = 'error', duration = 10000 })
                    end
                end
                loc.waitingPlayers = {}
            end

            if #activeGamePlayers < 2 then
                if not hasWaiting then
                    endAndCleanupGame(game)
                end
                return
            end

            local prevFirst = game:findPlayerByOrder(1)
            local prevSeat = nil
            if prevFirst then prevSeat = prevFirst.seatIndex or prevFirst:getSeatIndex() end
            local maxSeats = 6
            if loc and loc.getMaxPlayers then maxSeats = loc:getMaxPlayers() end
            local startSeat = prevSeat and nextStartingSeat(prevSeat, maxSeats, activeGamePlayers) or ((activeGamePlayers[1] and (activeGamePlayers[1].seatIndex or activeGamePlayers[1]:getSeatIndex())) or 1)
            sortAndAssignOrders(activeGamePlayers, startSeat)

            local newActiveGame = Game:New({
                locationIndex = locationIndex,
                players = activeGamePlayers,
                ante = ante,
                bettingPool = ante * #activeGamePlayers,
            })

            newActiveGame:init()
            newActiveGame:moveToNextRound()

            activeGames[locationIndex] = newActiveGame

            if hasWaiting and locations[locationIndex] then
                locations[locationIndex]:setState(LOCATION_STATES.GAME_IN_PROGRESS)
            end

            for k,player in pairs(newActiveGame:getPlayers()) do
                TriggerClientEvent("rainbow_poker:Client:StartGame", player:getNetId(), newActiveGame, player.seatIndex or player:getOrder())
            end

            TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)
        end)

        

    else
        -- No win condition yet; move on to next round
        game:moveToNextRound()
    end

end

function endAndCleanupGame(game)
    local locationIndex = game:getLocationIndex()

    if Config.DebugPrint then print("endAndCleanupGame - locationIndex:", locationIndex) end

    for k,player in pairs(game:getPlayers()) do
        TriggerClientEvent("rainbow_poker:Client:CleanupFinishedGame", player:getNetId())
    end

    -- Reset the location
    locations[locationIndex]:setState(LOCATION_STATES.EMPTY)

    if Config.DebugPrint then print("endAndCleanupGame - about to remove game - activeGames:", activeGames) end
    -- table.remove(activeGames, locationIndex)
    activeGames[locationIndex] = nil
    if Config.DebugPrint then print("endAndCleanupGame - removed game - activeGames:", activeGames) end

    game = nil

    TriggerClientEvent("rainbow_poker:Client:UpdatePokerTables", -1, locations)
end

function fold(targetNetId)
    local game = findActiveGameByPlayerNetId(targetNetId)

    game:stopTurnTimer()

    game:onPlayerDidActionFold(targetNetId)

    -- Check if there's only 1 non-folded player left
    local numNotFolded = 0
    for k,player in pairs(game:getPlayers()) do
        if not player:getHasFolded() then
            numNotFolded = numNotFolded + 1
        end
    end

    if numNotFolded > 1 then

        if not game:advanceTurn() then
            checkForWinCondition(game)
        end

        TriggerUpdate(game)
    else
        -- Last person standing!
        game:setStep(ROUNDS.SHOWDOWN)
        checkForWinCondition(game)
        TriggerUpdate(game)
    end
end

function getCash(targetNetId)
    local Player = RSGCore.Functions.GetPlayer(targetNetId)
    if not Player then return 0 end
    local cash = Player.Functions.GetMoney('cash') or 0
    return cash
end

function hasMoney(targetNetId, amount)
    amount = tonumber(amount)
    local cash = getCash(targetNetId)
    return cash >= amount
end

function takeMoney(targetNetId, amount)
    amount = tonumber(amount)
    local Player = RSGCore.Functions.GetPlayer(targetNetId)
    if not Player then return false end
    local cash = Player.Functions.GetMoney('cash') or 0
    if cash < amount then
        TriggerClientEvent('poker:notify', targetNetId, { description = string.format("You don't have $%.2f!", amount), type = 'error', duration = 20000 })
        return false
    end
    Player.Functions.RemoveMoney('cash', amount, 'poker-ante')
    TriggerClientEvent('poker:notify', targetNetId, { description = string.format("You have bet $%.2f.", amount), type = 'inform', duration = 6000 })
    return true
end

function giveMoney(targetNetId, amount)
    amount = tonumber(amount)
    local Player = RSGCore.Functions.GetPlayer(targetNetId)
    if not Player then return false end
    Player.Functions.AddMoney('cash', amount, 'poker-win')
    TriggerClientEvent('poker:notify', targetNetId, { description = string.format("You have won $%.2f.", amount), type = 'success', duration = 6000 })
    return true
end

function truncateString(str, max)
    if string.len(str) > max then
        return string.sub(str, 1, max) .. "…"
    else
        return str
    end
end



--------

-- Trigger updates to all the clients of the players of this game of poker.
function TriggerUpdate(game)

    -- Loop thru all this game's players
    for k,player in pairs(game:getPlayers()) do
        TriggerClientEvent("rainbow_poker:Client:TriggerUpdate", player:getNetId(), game)
    end
end


--------

-- Discord webhooks removed



--------

function findActiveGameByPlayerNetId(playerNetId)
    for k,v in pairs(activeGames) do
        for k2,v2 in pairs(v:getPlayers()) do
            if v2:getNetId() == playerNetId then
                return v
            end
        end
    end
    return false
end

function findPendingGameByPlayerNetId(playerNetId)
    for k,v in pairs(pendingGames) do
        for k2,v2 in pairs(v:getPlayers()) do
            if v2:getNetId() == playerNetId then
                return v
            end
        end
    end
    return false
end

--------

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() == resourceName then

        locations = {}
        pendingGames = {}
        activeGames = {}

    end

end)