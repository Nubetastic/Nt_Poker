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
        Wait(math.random(3000, 5000))
        local outstanding = math.max(0, game:getRoundsHighestBet() - (current:getAmountBetInRound() or 0))
        local cash = current.getNpcCash and current:getNpcCash() or 0
        local ante = game:getAnte() or 1
        local action = 'CHECK'
        local raiseBy = 0
        if outstanding == 0 then
            if cash > ante and math.random() < 0.35 then
                raiseBy = math.min(ante, cash)
                action = 'RAISE'
            else
                action = 'CHECK'
            end
        else
            if cash <= 0 then
                action = 'FOLD'
            elseif outstanding >= cash then
                action = 'ALLIN'
            else
                if math.random() < 0.15 then
                    action = 'FOLD'
                elseif math.random() < 0.30 and cash - outstanding > ante then
                    raiseBy = math.min(ante, cash - outstanding)
                    action = 'RAISE'
                else
                    action = 'CALL'
                end
            end
        end
        if action == 'FOLD' then
            game:onPlayerDidActionFold(current:getNetId())
        elseif action == 'CHECK' then
            game:onPlayerDidActionCheck(current:getNetId())
        elseif action == 'CALL' then
            current:setNpcCash(cash - outstanding)
            game:onPlayerDidActionCall(current:getNetId())
        elseif action == 'RAISE' then
            local toPay = outstanding + raiseBy
            current:setNpcCash(cash - toPay)
            game:onPlayerDidActionRaise(current:getNetId(), raiseBy)
        elseif action == 'ALLIN' then
            local potBefore = game:getBettingPool()
            game:addSidePot(potBefore)
            game:onPlayerDidActionAllIn(current:getNetId(), cash)
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