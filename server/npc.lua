function npcPlayTurns(game)
    local acted = false
    while game and game.getPlayers and game:getPlayers() and game:getStep() ~= ROUNDS.SHOWDOWN do
        local current = game:findPlayerOfCurrentTurn()
        if not current or not (current.getIsNpc and current:getIsNpc()) or current:getHasFolded() or current:getIsAllIn() then
            break
        end
        local anyHuman = false
        for _,p in pairs(game:getPlayers()) do
            if not (p.getIsNpc and p:getIsNpc()) and not p.hasLeftSession then
                anyHuman = true
                break
            end
        end
        if not anyHuman then
            endAndCleanupGame(game)
            break
        end
        Wait(100)

        local outstanding = math.max(0, game:getRoundsHighestBet() - (current:getAmountBetInRound() or 0))
        local cash = current.getNpcCash and current:getNpcCash() or 0
        local ante = game:getAnte() or 1
        local action = 'CHECK'
        local raiseBy = 0

        local s = (ConfigNPC and ConfigNPC.Settings) or {}
        local lowMult = tonumber(s.LowBetting or 3)
        local highMult = tonumber(s.HighBetting or 8)
        local bluffChance = tonumber(s.BluffChance or 0)
        local disableBluffAmt = tonumber(s.DisableBluffAmount or 0)
        local raiseChance = tonumber(s.RaiseChance or 0)
        local callChance = tonumber(s.CallChance or 0)
        local foldChance = tonumber(s.FoldChance or 0)

        local function isStrong()
            local round = game:getStep()
            local board = game:getBoard()
            local bestHand = nil

            
            if round == ROUNDS.INITIAL then
                local a = current:getCardA()
                local b = current:getCardB()
                if a and b then
                    if a:getRoyalty() == b:getRoyalty() then
                        local r = a:getRoyalty()
                        return r == 'A' or r == 'K' or r == 'Q' or r == 'J' or r == 'T' or r == '9' or r == '8'
                    end
                    local high = { A=true, K=true, Q=true, J=true, T=true }
                    return (high[a:getRoyalty()] and high[b:getRoyalty()])
                end
                return false
            end

            
            local function consider(hand)
                if not bestHand then
                    bestHand = hand
                else
                    local better = decideBetterHandOverall(bestHand, hand)
                    if better == hand then bestHand = hand end
                end
            end

            
            for _,v in pairs(board:retrieveAllFourCardCombos(false)) do
                consider(Hand:New({ cards = { current:getCardA(), v[1], v[2], v[3], v[4] }, playerNetId = current:getNetId() }))
            end
            
            for _,v in pairs(board:retrieveAllFourCardCombos(false)) do
                consider(Hand:New({ cards = { current:getCardB(), v[1], v[2], v[3], v[4] }, playerNetId = current:getNetId() }))
            end
            
            for _,v in pairs(board:retrieveAllThreeCardCombos(false)) do
                consider(Hand:New({ cards = { current:getCardA(), current:getCardB(), v[1], v[2], v[3] }, playerNetId = current:getNetId() }))
            end
            
            if round == ROUNDS.RIVER or round == ROUNDS.SHOWDOWN then
                consider(Hand:New({ cards = board:retrieveAllFiveCards(), playerNetId = current:getNetId() }))
            end

            if not bestHand then return false end

            
            if determineIfHandIsRoyalFlush(bestHand) then return true end
            if determineIfHandIsStraightFlush(bestHand) then return true end
            if determineIfHandIsFourOfAKind(bestHand) then return true end
            if determineIfHandIsFullHouse(bestHand) then return true end
            if determineIfHandIsFlush(bestHand) then return true end
            if determineIfHandIsStraight(bestHand) then return true end
            if determineIfHandIsThreeOfAKind(bestHand) then return true end
            if determineIfHandIsTwoPairs(bestHand) then return true end
            if determineIfHandIsOnePair(bestHand) then return false end
            return false
        end

        local strong = isStrong()
        local betMult = ante > 0 and (outstanding / ante) or 0

        if outstanding == 0 then
            if strong then
                if cash > ante and math.random() < raiseChance then
                    raiseBy = math.min(ante, cash)
                    action = 'RAISE'
                else
                    action = 'CHECK'
                end
            else
                if cash > ante and bluffChance > 0 and math.random() < bluffChance then
                    local maxBluff = (disableBluffAmt > 0) and (ante * disableBluffAmt) or ante
                    raiseBy = math.min(ante, maxBluff, cash)
                    action = raiseBy > 0 and 'RAISE' or 'CHECK'
                else
                    action = 'CHECK'
                end
            end
        else
            if cash <= 0 then
                action = 'FOLD'
            elseif outstanding >= cash then
                action = 'ALLIN'
            else
                if betMult <= lowMult then
                    if strong then
                        if math.random() < raiseChance and (cash - outstanding) > ante then
                            raiseBy = math.min(ante, cash - outstanding)
                            action = 'RAISE'
                        elseif math.random() < callChance then
                            action = 'CALL'
                        else
                            action = 'CALL'
                        end
                    else
                        if bluffChance > 0 and betMult <= disableBluffAmt and math.random() < bluffChance and (cash - outstanding) > ante then
                            raiseBy = math.min(ante, cash - outstanding)
                            action = 'RAISE'
                        elseif math.random() < foldChance then
                            action = 'FOLD'
                        else
                            action = 'CALL'
                        end
                    end
                elseif betMult <= highMult then
                    if strong then
                        if math.random() < callChance then
                            action = 'CALL'
                        elseif (cash - outstanding) > ante and math.random() < raiseChance then
                            raiseBy = math.min(ante, cash - outstanding)
                            action = 'RAISE'
                        else
                            action = 'CALL'
                        end
                    else
                        if math.random() < (foldChance + 0.2) then
                            action = 'FOLD'
                        else
                            action = 'CALL'
                        end
                    end
                else
                    if strong then
                        action = 'CALL'
                    else
                        action = 'FOLD'
                    end
                end
            end
        end

        if game.getHandLimitMultiplier and (game:getHandLimitMultiplier() or 0) > 0 then
            local limit = (game:getAnte() or 0) * game:getHandLimitMultiplier()
            local remaining = limit - (current:getTotalAmountBetInGame() or 0)
            local toPay = outstanding + (action == 'RAISE' and raiseBy or 0)
            if remaining <= 0 then
                action = (outstanding == 0) and 'CHECK' or 'FOLD'
                raiseBy = 0
            elseif action ~= 'CHECK' and toPay > remaining then
                action = (outstanding == 0) and 'CHECK' or 'FOLD'
                raiseBy = 0
            end
        end

        local limit = (game:getAnte() or 0) * game:getHandLimitMultiplier()
        local remaining = limit - (current:getTotalAmountBetInGame() or 0)
        local cashNow = current.getNpcCash and current:getNpcCash() or 0
        if game.getHandLimitMultiplier and remaining == 0 then
            print("Hand Limit: " .. tostring(cashNow))
            action = 'CHECK'
        else
            Wait(math.random(3000, 5000))
        end

        if action == 'FOLD' then
            game:onPlayerDidActionFold(current:getNetId())
        elseif action == 'CHECK' then
            game:onPlayerDidActionCheck(current:getNetId())
        elseif action == 'CALL' then
            current:setNpcCash(cashNow - outstanding)
            game:onPlayerDidActionCall(current:getNetId())
        elseif action == 'RAISE' then
            local toPay = outstanding + raiseBy
            current:setNpcCash(cashNow - toPay)
            game:onPlayerDidActionRaise(current:getNetId(), raiseBy)
        elseif action == 'ALLIN' then
            local potBefore = game:getBettingPool()
            game:addSidePot(potBefore)
            game:onPlayerDidActionAllIn(current:getNetId(), cashNow)
            current:setNpcCash(0)
        end

        acted = true
        if not game:advanceTurn() then
            checkForWinCondition(game)
        end
        TriggerUpdate(game)
        if Turns_BroadcastTurnState and game and game.getStep and game:getStep() ~= ROUNDS.SHOWDOWN then
            Turns_BroadcastTurnState(game)
        end
    end
    if acted then
        TriggerUpdate(game)
    end
end