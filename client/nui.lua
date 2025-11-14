UI = {}

PokerPendingStartContext = PokerPendingStartContext or nil

function UI:OpenBlindsModal(opts)
    SendNUIMessage({
        type = "openBlindsModal",
        min = opts and opts.min or 1,
        max = opts and opts.max or 1000,
        defaultBlind = opts and opts.defaultBlind or 5,
    })
    SetNuiFocus(true, true)
end

function UI:StartGame(game)

    if Config.DebugPrintUnsafe then print("UI:StartGame - game", game) end
    
    math.randomseed(GetGameTimer())

    SendNUIMessage({
        type = "start",
        game = game,
        thisPlayer = findThisPlayerFromGameTable(game),
    })
	SetNuiFocus(false, false)
    isInGame = true
end

function UI:UpdateGame(game)

    if Config.DebugPrintUnsafe then print("UI:UpdateGame - game", game) end
    
    math.randomseed(GetGameTimer())

    SendNUIMessage({
        type = "update",
        game = game,
        thisPlayer = findThisPlayerFromGameTable(game),
    })
    
end

function UI:AlertWinScenario(winScenario)

    if Config.DebugPrint then print("UI:AlertWinScenario - winScenario", winScenario) end
    
    math.randomseed(GetGameTimer())

    if winScenario.isTrueTie then
        for k,v in pairs(winScenario.tiedHands) do
            if v.playerNetId == GetPlayerServerId(PlayerId()) then
                winScenario["thisPlayersWinningHand"] = v
                break
            end
        end
    else
        if winScenario.winningHand.playerNetId == GetPlayerServerId(PlayerId()) then
            winScenario["thisPlayersWinningHand"] = winScenario.winningHand
        end
    end

    -- Play audio for win or lose
    if winScenario["thisPlayersWinningHand"] then
        TriggerEvent('poker:playAudio', Config.Audio.Win)
    else
        TriggerEvent('poker:playAudio', Config.Audio.Lose)
    end

    SendNUIMessage({
        type = "win",
        winScenario = winScenario,
    })

    -- Play animations for win or lose
    if winScenario["thisPlayersWinningHand"] then
        PlayAnimation("Win")
        PlayAnimation("Roseanne")
    else
        PlayAnimation("Loss")
    end
    
end

function UI:CloseAll()
    SendNUIMessage({
        type = "close",
    })
    SetNuiFocus(false, false)
    isInGame = false
end

RegisterNUICallback("playCardFlip", function(args, cb)
	-- if Config.DebugPrint then print("closeAll") end
    local rand = math.random(1,3)
    local audioName = Config.Audio["CardFlip"..rand]
	TriggerEvent('poker:playAudio', audioName)
	cb("ok")
end)

RegisterNUICallback("closeAll", function(args, cb)
	if Config.DebugPrint then print("closeAll") end
	UI:CloseAll()
	cb("ok")
end)

RegisterNUICallback("blindsSelected", function(args, cb)
	local blind = args and args.blind or nil
	if Config.DebugPrint then print("blindsSelected", blind) end
	if blind and tonumber(blind) and tonumber(blind) >= 1 and PokerPendingStartContext then
		SetNuiFocus(false, false)
		TriggerServerEvent("rainbow_poker:Server:StartNewPendingGame", PokerPendingStartContext.name, tostring(math.floor(tonumber(blind))), PokerPendingStartContext.locationIndex)
		PokerPendingStartContext = nil
		cb("ok")
	else
		cb("fail")
	end
end)

RegisterNUICallback("cancelBlinds", function(args, cb)
	SetNuiFocus(false, false)
	PokerPendingStartContext = nil
	cb("ok")
end)
