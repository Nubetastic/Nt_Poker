-- Natives-only bootstrap (replacing VORP and rainbow-core on client)

-- Simple notify bridge -> chat
RegisterNetEvent('poker:notify', function(dataOrText)
    --local msg = type(dataOrText) == 'table' and (dataOrText.description or dataOrText.text or dataOrText.message) or tostring(dataOrText)
    --TriggerEvent('chat:addMessage', { args = { 'Poker', msg } })
end)

-- Unified notify wrapper: prefers ox_lib, falls back to chat
local function NotifyRightTip(message, nType, duration)
    if lib and lib.notify then
        lib.notify({
            title = 'Poker',
            description = tostring(message),
            type = nType or 'inform',
            duration = duration
        })
    else
        TriggerEvent('poker:notify', message)
    end
end

-- Native checks for interaction readiness
local function CanPedStartInteractionNative(ped)
    if not ped or ped == 0 then return false end
    if IsEntityDead(ped) or IsPedRagdoll(ped) then return false end
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then return false end
    if IsPedActiveInScenario(ped) then return false end
    return true
end

-- On-screen keyboard helper (letters or numbers only)
local function TextInput(prompt, default, numeric)
    AddTextEntry('POKER_OSK', prompt)
    DisplayOnscreenKeyboard(1, 'POKER_OSK', '', default or '', '', '', '', 30)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if GetOnscreenKeyboardResult() then
        local res = GetOnscreenKeyboardResult()
        if numeric then
            res = res:gsub("[^0-9]", "")
        else
            res = res:gsub("[^A-Za-z]", "")
        end
        return res
    end
    return nil
end

-- Native Prompt shim with minimal VORP-like API
local function CreateNativePrompt(label, control, mode)
    local str = CreateVarString(10, "LITERAL_STRING", label)
    local p = PromptRegisterBegin()
    PromptSetControlAction(p, control)
    PromptSetText(p, str)
    PromptSetEnabled(p, false)
    PromptSetVisible(p, false)
    if mode == 'hold' then
        PromptSetHoldMode(p, true)
    else
        PromptSetStandardMode(p, true)
    end
    PromptRegisterEnd(p)
    return p
end

local function NewPromptGroup()
    local groupId = math.random(0, 0xFFFFFF)
    return {
        RegisterPrompt = function(self, label, controlHash, _a, _b, _enabled, mode, _extra)
            local pr = CreateNativePrompt(label, controlHash, mode)
            PromptSetGroup(pr, groupId, 0)
            local obj = { Prompt = pr, _mode = mode or 'click' }
            function obj:TogglePrompt(state)
                PromptSetEnabled(self.Prompt, state)
                PromptSetVisible(self.Prompt, state)
            end
            function obj:HasCompleted()
                if self._mode == 'hold' then
                    return PromptHasHoldModeCompleted(self.Prompt)
                else
                    return PromptHasStandardModeCompleted(self.Prompt)
                end
            end
            return obj
        end,
        ShowGroup = function(self, label)
            PromptSetActiveGroupThisFrame(groupId, CreateVarString(10, 'LITERAL_STRING', label))
        end
    }
end

NativeUtils = { Prompts = { SetupPromptGroup = function() return NewPromptGroup() end } }

-- Expose for later use
CanPedStartInteraction = CanPedStartInteractionNative
TextInputForPoker = TextInput
RainbowCore = { CanPedStartInteraction = CanPedStartInteractionNative }

local PromptGroupInGame
local PromptGroupInGameLeave
local PromptGroupTable
local PromptGroupFinalize
local PromptCall
local PromptRaise
local PromptCheck
local PromptFold
local PromptIncreaseAmount
local PromptDecreaseAmount
local PromptStart
local PromptJoin
local PromptBegin
local PromptCancel
local PromptAddNpc
local PromptLeave

local characterName = false

isInGame = false
game = nil

local locations = {}
local isNearTable = false
local nearTableLocationIndex

local turnRaiseAmount = 1
local turnBaseRaiseAmount = 1
local isPlayerOccupied = false
local hasLeft = false
playingPoker = false
local lastStep = nil
local revealHoldUntil = 0


if Config.DebugCommands then
    -- Run through winning cases without actually playing the game yourself.
    -- Example:
    -- /pokerv KcKdQs8d2h AhJc As8h
    -- (Showdown only)
    RegisterCommand("pokerv", function(source, args, rawCommand)

        TriggerServerEvent("rainbow_poker:Server:Command:pokerv", args)
        
    end, false)

    -- Test creating of decks
    RegisterCommand("debug:pokerDeck", function(source, args, rawCommand)

        TriggerServerEvent("rainbow_poker:Server:Command:Debug:PokerDeck", args)
        
    end, false)
end


-------- THREADS

-- Performance
Citizen.CreateThread(function()

	Citizen.Wait(1000)

	while true do

		local playerPedId = PlayerPedId()
		if playerPedId then
			isPlayerOccupied = not RainbowCore.CanPedStartInteraction(playerPedId)
		end

		Wait(200)
	end
end)

-- Check if near table
CreateThread(function()

    TriggerServerEvent("rainbow_poker:Server:RequestUpdatePokerTables")

    while true do
        local sleep = 1000

        if not isInGame and not isPlayerOccupied then
            local playerPedId = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPedId)

            local isCurrentlyNearTable = false
            for k,location in pairs(locations) do
                if #(playerCoords - location.tableCoords) < Config.TableDistance then
                    sleep = 250
                    isCurrentlyNearTable = true
                    nearTableLocationIndex = k
                end
            end
            isNearTable = isCurrentlyNearTable
        end

        Wait(sleep)
    end

end)



-- Join game prompts
CreateThread(function()

    PromptGroupTable = NativeUtils.Prompts:SetupPromptGroup()
    PromptStart = PromptGroupTable:RegisterPrompt("Start Game", GetHashKey(Config.Keys.StartGame), 1, 1, true, "hold", {timedeventhash = "MEDIUM_TIMED_EVENT"})
    PromptJoin = PromptGroupTable:RegisterPrompt("Join Game", GetHashKey(Config.Keys.JoinGame), 1, 1, true, "hold", {timedeventhash = "MEDIUM_TIMED_EVENT"})

    while true do

        local sleep = 1000

        PromptJoin:TogglePrompt(false)
        PromptStart:TogglePrompt(false)

        if not isInGame and isNearTable and nearTableLocationIndex and not isPlayerOccupied then

            if characterName == false then
                characterName = ""
                TriggerServerEvent("rainbow_poker:Server:RequestCharacterName")
            end

            local location = locations[nearTableLocationIndex]

            sleep = 1

            -- Join during pending game (standard)
            if location.state == LOCATION_STATES.PENDING_GAME and location.pendingGame.initiatorNetId ~= GetPlayerServerId(PlayerId()) then
                local hasPlayerAlreadyJoined = false
                for k,v in pairs(location.pendingGame.players) do
                    if v.netId == GetPlayerServerId(PlayerId()) then
                        hasPlayerAlreadyJoined = true
                    end
                end

                if not hasPlayerAlreadyJoined then
                    PromptJoin:TogglePrompt(true)
                    if location.pendingGame and location.pendingGame.ante then
                        PromptSetText(PromptJoin.Prompt, CreateVarString(10, "LITERAL_STRING", "Join Game  |  Ante Bet: ~o~$"..location.pendingGame.ante.." ", "Title"))
                    end
                end

            -- Join during active game (wait for next hand)
            elseif location.state == LOCATION_STATES.GAME_IN_PROGRESS then
                PromptJoin:TogglePrompt(true)
                PromptSetText(PromptJoin.Prompt, CreateVarString(10, "LITERAL_STRING", "Join Next Hand", "Title"))

            -- Start new game
            elseif location.state == LOCATION_STATES.EMPTY then
                PromptStart:TogglePrompt(true)
            end

            PromptGroupTable:ShowGroup("Poker Table")

                -- START
                if PromptStart:HasCompleted() then
                
                    local playersChosenName
                    if Config.DebugOptions.SkipStartGameOptions then
                        playersChosenName = "foo"
                    else
                        local playersChosenNameInput = {
                            type = "enableinput", -- don't touch
                            inputType = "input", -- input type
                            button = "Confirm", -- button name
                            placeholder = "", -- placeholder name
                            style = "block", -- don't touch
                            attributes = {
                                inputHeader = "YOUR NAME", -- header
                                type = "text", -- inputype text, number,date,textarea ETC
                                pattern = "[A-Za-z]+", --  only numbers "[0-9]" | for letters only "[A-Za-z]+" 
                                title = "Letters only (no spaces or quotes)", -- if input doesnt match show this message
                                style = "border-radius: 10px; background-color: ; border:none;", -- style 
                                value = characterName,
                            }
                        }
                        playersChosenName = characterName
                    end

                    if not playersChosenName or playersChosenName=="" then
                        NotifyRightTip("You must enter a name.", 'error', 6 * 1000)
                    elseif string.len(playersChosenName) < 3 then
                        NotifyRightTip("Your name must be at least 3 letters long.", 'error', 6 * 1000)
                    else
                        Wait(100)

                        PokerPendingStartContext = { name = playersChosenName, locationIndex = nearTableLocationIndex }
                        UI:OpenBlindsModal({ min = 1, max = 1000, defaultBlind = 5 })
                    end

                    Wait(3 * 1000)

                end

                -- JOIN
                if PromptJoin:HasCompleted() then
                    local playersChosenNameInput = {
                        type = "enableinput", -- don't touch
                        inputType = "input", -- input type
                        button = "Confirm", -- button name
                        placeholder = "", -- placeholder name
                        style = "block", -- don't touch
                        attributes = {
                            inputHeader = "YOUR NAME", -- header
                            type = "text", -- inputype text, number,date,textarea ETC
                            pattern = "[A-Za-z]+", --  only numbers "[0-9]" | for letters only "[A-Za-z]+" 
                            title = "Letters only", -- if input doesnt match show this message
                            style = "border-radius: 10px; background-color: ; border:none;",-- style 
                            value = characterName,
                        }
                    }
                    local playersChosenName = characterName

                    TriggerServerEvent("rainbow_poker:Server:JoinGame", playersChosenName, nearTableLocationIndex)

                    Wait(3 * 1000)
                end
            
        end

        Wait(sleep)
    end

end)


-- Begin game prompt
CreateThread(function()

    PromptGroupFinalize = NativeUtils.Prompts:SetupPromptGroup()
    PromptBegin = PromptGroupFinalize:RegisterPrompt("Begin Game", GetHashKey(Config.Keys.BeginGame), 1, 1, true, "hold", {timedeventhash = "MEDIUM_TIMED_EVENT"})
    PromptCancel = PromptGroupFinalize:RegisterPrompt("Cancel Game", GetHashKey(Config.Keys.CancelGame), 1, 1, true, "hold", {timedeventhash = "MEDIUM_TIMED_EVENT"})
    PromptAddNpc = PromptGroupFinalize:RegisterPrompt("Add NPC", GetHashKey(Config.Keys.AddNpc), 1, 1, true, "click", {})

    while true do

        local sleep = 1000

        PromptBegin:TogglePrompt(false)
        PromptCancel:TogglePrompt(false)
        PromptAddNpc:TogglePrompt(false)

        if not isInGame and nearTableLocationIndex and locations[nearTableLocationIndex] and playingPoker then
            sleep = 1
            local location = locations[nearTableLocationIndex]

            if location.state == LOCATION_STATES.PENDING_GAME and location.pendingGame.initiatorNetId == GetPlayerServerId(PlayerId()) then

                PromptBegin:TogglePrompt(true)
                PromptCancel:TogglePrompt(true)
                if ConfigNPC and ConfigNPC.NPCEnable then PromptAddNpc:TogglePrompt(true) end

                PromptSetText(PromptBegin.Prompt, CreateVarString(10, "LITERAL_STRING", "Begin Game  |  Players: ~o~" .. #location.pendingGame.players .. " ", "Title"))

                PromptSetPriority(PromptBegin.Prompt, 3)

                PromptGroupFinalize:ShowGroup("Poker Table")

                if PromptBegin:HasCompleted() then
                    TriggerServerEvent("rainbow_poker:Server:FinalizePendingGameAndBegin", nearTableLocationIndex)
                end

                if PromptCancel:HasCompleted() then
                    TriggerServerEvent("rainbow_poker:Server:CancelPendingGame", nearTableLocationIndex)
                end

                if (ConfigNPC and ConfigNPC.NPCEnable) and PromptAddNpc:HasCompleted() then
                    TriggerServerEvent("rainbow_poker:Server:AddNpcToPendingGame", nearTableLocationIndex)
                end

            end
        end

        Wait(sleep)

    end

end)

-- In-game prompts
CreateThread(function()

    PromptGroupInGame = NativeUtils.Prompts:SetupPromptGroup()
    PromptCall = PromptGroupInGame:RegisterPrompt("Call (Match)", GetHashKey(Config.Keys.ActionCall), 1, 1, true, "click", {})
    PromptRaise = PromptGroupInGame:RegisterPrompt("Raise $1", GetHashKey(Config.Keys.ActionRaise), 1, 1, true, "click", {})
    PromptCheck = PromptGroupInGame:RegisterPrompt("Check", GetHashKey(Config.Keys.ActionCheck), 1, 1, true, "click", {})
    PromptFold = PromptGroupInGame:RegisterPrompt("Fold", GetHashKey(Config.Keys.ActionFold), 1, 1, true, "hold", {timedeventhash = "MEDIUM_TIMED_EVENT"})
    PromptIncreaseAmount = PromptGroupInGame:RegisterPrompt("Increase", GetHashKey(Config.Keys.IncreaseRaise), 1, 1, true, "click", {})
    PromptDecreaseAmount = PromptGroupInGame:RegisterPrompt("Decrease", GetHashKey(Config.Keys.DecreaseRaise), 1, 1, true, "click", {})
    
    PromptLeave = PromptGroupInGame:RegisterPrompt("Leave", GetHashKey(Config.Keys.LeaveGame), 1, 1, true, "hold", {timedeventhash = "MEDIUM_TIMED_EVENT"})

    local wasMyTurn = false

    while true do

        local sleep = 2000

        if isInGame and game and game.step ~= ROUNDS.PENDING and game.step ~= ROUNDS.SHOWDOWN then
            sleep = 0

            PromptCall:TogglePrompt(false)
            PromptSetEnabled(PromptCall.Prompt, false)
            PromptRaise:TogglePrompt(false)
            PromptSetEnabled(PromptRaise.Prompt, false)
            PromptCheck:TogglePrompt(false)
            PromptSetEnabled(PromptCheck.Prompt, false)
            PromptFold:TogglePrompt(false)
            PromptSetEnabled(PromptFold.Prompt, false)
            PromptIncreaseAmount:TogglePrompt(false)
            PromptSetEnabled(PromptIncreaseAmount.Prompt, false)
            PromptDecreaseAmount:TogglePrompt(false)
            PromptSetEnabled(PromptDecreaseAmount.Prompt, false)


            -- Block inputs
            DisableAllControlActions(0)
            EnableControlAction(0, GetHashKey(Config.Keys.ActionCall))
            EnableControlAction(0, GetHashKey(Config.Keys.ActionRaise))
            EnableControlAction(0, GetHashKey(Config.Keys.ActionCheck))
            EnableControlAction(0, GetHashKey(Config.Keys.ActionFold))
            EnableControlAction(0, GetHashKey(Config.Keys.IncreaseRaise))
            EnableControlAction(0, GetHashKey(Config.Keys.DecreaseRaise))
            EnableControlAction(0, GetHashKey(Config.Keys.LeaveGame))
            EnableControlAction(0, 0x4BC9DABB, true) -- Enable push-to-talk
			EnableControlAction(0, 0xF3830D8E, true) -- Enable J for jugular
            -- Re-enable mouse
            EnableControlAction(0, `INPUT_LOOK_UD`, true) -- INPUT_LOOK_UD
            EnableControlAction(0, `INPUT_LOOK_LR`, true) -- INPUT_LOOK_LR
            -- For Admin Menu:
            EnableControlAction(0, `INPUT_CREATOR_RT`, true) -- PAGE DOWN


            -- Always show Leave prompt
            PromptSetEnabled(PromptLeave.Prompt, true)
            PromptLeave:TogglePrompt(true)
            PromptGroupInGame:ShowGroup("Poker Game")

            if PromptLeave:HasCompleted() then
                if Config.DebugPrint then print("PromptLeave") end
                TriggerServerEvent("rainbow_poker:Server:PlayerLeave")
                Wait(1000)
            end

            -- Check if it's their turn
            local thisPlayer = findThisPlayerFromGameTable(game)

            -- print('thisPlayer', thisPlayer)
            -- print('game', game)
            -- print('game.currentTurn == thisPlayer.order', game["currentTurn"], thisPlayer["order"])

            local myTurn = (game.currentTurn == thisPlayer.order) and (not thisPlayer.hasFolded)

            if myTurn and not wasMyTurn then Wait(2000) end

            if myTurn then
                local canEnable = GetGameTimer() >= revealHoldUntil
                if not canEnable and promptsActive then
                    PromptCall:TogglePrompt(false)
                    PromptSetEnabled(PromptCall.Prompt, false)
                    PromptRaise:TogglePrompt(false)
                    PromptSetEnabled(PromptRaise.Prompt, false)
                    PromptCheck:TogglePrompt(false)
                    PromptSetEnabled(PromptCheck.Prompt, false)
                    PromptFold:TogglePrompt(false)
                    PromptSetEnabled(PromptFold.Prompt, false)
                    PromptIncreaseAmount:TogglePrompt(false)
                    PromptSetEnabled(PromptIncreaseAmount.Prompt, false)
                    promptsActive = false
                end


                if not thisPlayer.hasFolded then

                    PromptSetText(PromptRaise.Prompt, CreateVarString(10, "LITERAL_STRING", string.format("Raise by $%d | (~o~$%d~s~)", turnRaiseAmount, game.currentGoingBet + turnRaiseAmount), "Title"))
                    PromptSetText(PromptCall.Prompt, CreateVarString(10, "LITERAL_STRING", string.format("Call | (~o~$%d~s~)", (game.roundsHighestBet - thisPlayer.amountBetInRound)), "Title"))

                    if canEnable then
                        -- Conditionally show Call or Check depending on this round's betting circumstances
                        if game.roundsHighestBet and game.roundsHighestBet > 0 then
                            PromptCheck:TogglePrompt(false)
                            PromptSetEnabled(PromptCheck.Prompt, false)
                            PromptCall:TogglePrompt(true)
                            PromptSetEnabled(PromptCall.Prompt, true)
                        else
                            PromptCheck:TogglePrompt(true)
                            PromptSetEnabled(PromptCheck.Prompt, true)
                            PromptCall:TogglePrompt(false)
                            PromptSetEnabled(PromptCall.Prompt, false)
                        end

                        PromptRaise:TogglePrompt(true)
                        PromptSetEnabled(PromptRaise.Prompt, true)
                        PromptFold:TogglePrompt(true)
                        PromptSetEnabled(PromptFold.Prompt, true)
                        PromptIncreaseAmount:TogglePrompt(true)
                        PromptSetEnabled(PromptIncreaseAmount.Prompt, true)
                        PromptDecreaseAmount:TogglePrompt(true)
                        PromptSetEnabled(PromptDecreaseAmount.Prompt, true)

                        PromptGroupInGame:ShowGroup("Poker Game")
                    end


                    if PromptCall:HasCompleted() then
                        if Config.DebugPrint then print("PromptCall") end

                        TriggerServerEvent("rainbow_poker:Server:PlayerActionCall")

                        PlayAnimation("Bet")
                    end

                    if PromptRaise:HasCompleted() then
                        if Config.DebugPrint then print("PromptRaise") end

                        TriggerServerEvent("rainbow_poker:Server:PlayerActionRaise", turnRaiseAmount)

                        PlayAnimation("Bet")
                    end

                    if PromptCheck:HasCompleted() then
                        if Config.DebugPrint then print("PromptCheck") end

                        TriggerServerEvent("rainbow_poker:Server:PlayerActionCheck")

                        PlayAnimation("Check")
                    end

                    if PromptFold:HasCompleted() then
                        if Config.DebugPrint then print("PromptFold") end

                        TriggerServerEvent("rainbow_poker:Server:PlayerActionFold")

                        if Props then Props:OnLocalFold() end

                        PlayAnimation("Fold")
                        PlayAnimation("NoCards")
                    end

                    if PromptIncreaseAmount:HasCompleted() then
                        if Config.DebugPrint then print("IncreaseRaise") end
                        local outstanding = math.max(0, (game.roundsHighestBet or 0) - (thisPlayer.amountBetInRound or 0))
                        local cash = (thisPlayer.playerCash or 0)
                        local maxRaise = math.max(0, cash - outstanding)
                        if maxRaise >= turnBaseRaiseAmount then
                            local maxStep = maxRaise - (maxRaise % turnBaseRaiseAmount)
                            if turnRaiseAmount < maxStep then
                                turnRaiseAmount = math.min(maxStep, turnRaiseAmount + turnBaseRaiseAmount)
                            end
                        end
                    end

                    if PromptDecreaseAmount:HasCompleted() then
                        if Config.DebugPrint then print("DecreaseRaise") end
                        if turnRaiseAmount > turnBaseRaiseAmount then
                            turnRaiseAmount = math.max(turnBaseRaiseAmount, turnRaiseAmount - turnBaseRaiseAmount)
                        end
                    end
                
                end
            
            else
                -- It's not their turn

                if thisPlayer.hasFolded then

                    -- Player has folded

                    -- Enable the "Leave" prompt
                    PromptSetEnabled(PromptLeave.Prompt, true)
                    PromptLeave:TogglePrompt(true)

                    PromptGroupInGame:ShowGroup("Poker Game")

                    if PromptLeave:HasCompleted() then
                        if Config.DebugPrint then print("PromptLeave") end

                        TriggerServerEvent("rainbow_poker:Server:PlayerLeave")

                        Wait(2000)
                    end
                end

            end

            wasMyTurn = myTurn

        elseif isInGame and game and game.step == ROUNDS.SHOWDOWN then

            sleep = 0
            PromptCall:TogglePrompt(false)
            PromptSetEnabled(PromptCall.Prompt, false)
            PromptRaise:TogglePrompt(false)
            PromptSetEnabled(PromptRaise.Prompt, false)
            PromptCheck:TogglePrompt(false)
            PromptSetEnabled(PromptCheck.Prompt, false)
            PromptFold:TogglePrompt(false)
            PromptSetEnabled(PromptFold.Prompt, false)
            PromptIncreaseAmount:TogglePrompt(false)
            PromptSetEnabled(PromptIncreaseAmount.Prompt, false)
            PromptDecreaseAmount:TogglePrompt(false)
            PromptSetEnabled(PromptDecreaseAmount.Prompt, false)
            -- Enable the "Leave" prompt
            PromptSetEnabled(PromptLeave.Prompt, true)
            PromptLeave:TogglePrompt(true)

            PromptGroupInGame:ShowGroup("Poker Game")

            if PromptLeave:HasCompleted() then
                if Config.DebugPrint then print("PromptLeave") end

                TriggerServerEvent("rainbow_poker:Server:PlayerLeave")

                Wait(2000)
            end

        end

        Wait(sleep)
        
    end
end)




-- Check for deaths (or other hard-occupying things)
CreateThread(function()

    while true do

        local sleep = 1000

        if isInGame and game then
            local ped = PlayerPedId()
            local hardOccupied = IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false)
            if hardOccupied then
                if Config.DebugPrint then print("became hard-occupied mid-game") end

                TriggerServerEvent("rainbow_poker:Server:PlayerActionFold")
                turnRaiseAmount = turnBaseRaiseAmount

                Wait(200)

                TriggerServerEvent("rainbow_poker:Server:PlayerLeave")

                sleep = 10 * 1000
            end
        end

        Wait(sleep)
    end

end)


-------- EVENTS


RegisterNetEvent("rainbow_poker:Client:ReturnRequestCharacterName")
AddEventHandler("rainbow_poker:Client:ReturnRequestCharacterName", function(_name)

	if Config.DebugPrint then print("rainbow_poker:Client:ReturnRequestCharacterName", _name) end

    characterName = _name
end)

RegisterNetEvent("rainbow_poker:Client:ReturnJoinGame")
AddEventHandler("rainbow_poker:Client:ReturnJoinGame", function(locationIndex, player, seatIndex)
    
    if Config.DebugPrint then print("rainbow_poker:Client:ReturnJoinGame", locationIndex, player, seatIndex) end

    local locationId = locations[locationIndex].id

    playingPoker = true
    startChairScenario(locationId, seatIndex or player.order)
end)

RegisterNetEvent("rainbow_poker:Client:ReturnStartNewPendingGame")
AddEventHandler("rainbow_poker:Client:ReturnStartNewPendingGame", function(locationIndex, player, seatIndex)
    
    if Config.DebugPrint then print("rainbow_poker:Client:ReturnStartNewPendingGame", locationIndex, player, seatIndex) end

    local locationId = locations[locationIndex].id

    playingPoker = true
    startChairScenario(locationId, seatIndex or player.order)

end)

RegisterNetEvent("rainbow_poker:Client:CancelPendingGame")
AddEventHandler("rainbow_poker:Client:CancelPendingGame", function(locationIndex)

	if Config.DebugPrint then print("rainbow_poker:Client:CancelPendingGame", locationIndex) end
	
    playingPoker = false
    clearPedTaskAndUnfreeze(true)
   
end)

RegisterNetEvent("rainbow_poker:Client:StartGame")
AddEventHandler("rainbow_poker:Client:StartGame", function(_game, playerSeatOrder)

	if Config.DebugPrint then print("rainbow_poker:Client:StartGame", _game, playerSeatOrder) end
	
    UI:StartGame(_game)

    game = _game
    isInGame = true

    turnBaseRaiseAmount = (game and tonumber(game.ante) and tonumber(game.ante) > 0) and tonumber(game.ante) or 1
    turnRaiseAmount = turnBaseRaiseAmount

    local locationId = locations[nearTableLocationIndex].id
    startChairScenario(locationId, playerSeatOrder)

   
    PlayAnimation("HoldCards")

    if Props and locations and nearTableLocationIndex and locations[nearTableLocationIndex] then
        local locationId = locations[nearTableLocationIndex].id
        Props:Start(game, locationId, playerSeatOrder)
        if NPCVisuals then NPCVisuals:Start(game, locationId) end
    end
end)

RegisterNetEvent("rainbow_poker:Client:UpdatePokerTables")
AddEventHandler("rainbow_poker:Client:UpdatePokerTables", function(_locations)

	if Config.DebugPrint then print("rainbow_poker:Client:UpdatePokerTables", _locations) end
	
    locations = _locations
   
end)

RegisterNetEvent("rainbow_poker:Client:TriggerUpdate")
AddEventHandler("rainbow_poker:Client:TriggerUpdate", function(_game)

	if Config.DebugPrintUnsafe then print("rainbow_poker:Client:TriggerUpdate", _game) end
	
    UI:UpdateGame(_game)

    game = _game

    if Props then
        Props:Update(game)
    end
    if NPCVisuals then
        NPCVisuals:Update(game)
    end

    local prevStep = lastStep
    if game then
        lastStep = game.step
        if prevStep ~= nil and prevStep ~= game.step and game.step ~= ROUNDS.PENDING and game.step ~= ROUNDS.SHOWDOWN then
            revealHoldUntil = GetGameTimer() + 4000
        end
    end

    turnBaseRaiseAmount = (game and tonumber(game.ante) and tonumber(game.ante) > 0) and tonumber(game.ante) or 1
    turnRaiseAmount = turnBaseRaiseAmount
   
end)

RegisterNetEvent("rainbow_poker:Client:ReturnPlayerLeave")
AddEventHandler("rainbow_poker:Client:ReturnPlayerLeave", function(locationIndex, player)
    
    if Config.DebugPrint then print("rainbow_poker:Client:ReturnPlayerLeave") end

    hasLeft = true
    playingPoker = false
    UI:CloseAll()
    clearPedTaskAndUnfreeze(true)

    if Props then
        Props:CleanupAll()
    end
    if NPCVisuals then
        NPCVisuals:CleanupAll()
    end

end)

RegisterNetEvent("rainbow_poker:Client:WarnTurnTimer")
AddEventHandler("rainbow_poker:Client:WarnTurnTimer", function(locationIndex, player)
    
    if Config.DebugPrint then print("rainbow_poker:Client:WarnTurnTimer") end

    local timeRemaining = Config.TurnTimeoutWarningInSeconds

    NotifyRightTip(string.format("WARNING: Take action now. Less than %d seconds remaining.", timeRemaining), 'warning', 6 * 1000)

end)

RegisterNetEvent("rainbow_poker:Client:AlertWin")
AddEventHandler("rainbow_poker:Client:AlertWin", function(_winScenario)
    
    if Config.DebugPrint then print("rainbow_poker:Client:AlertWin") end

    -- Don't alert if they left the poker game
    if hasLeft == false then
        UI:AlertWinScenario(_winScenario)
    end

end)

RegisterNetEvent("rainbow_poker:Client:CleanupFinishedGame")
AddEventHandler("rainbow_poker:Client:CleanupFinishedGame", function()
    
    if Config.DebugPrint then print("rainbow_poker:Client:CleanupFinishedGame") end

    UI:CloseAll()

    if hasLeft == false then
        clearPedTaskAndUnfreeze(true)
    end

    if Props then
        Props:CleanupAll()
    end
    if NPCVisuals then
        NPCVisuals:CleanupAll()
    end

    game = nil
    isInGame = false
    hasLeft = false
    playingPoker = false
    
end)

if Config.DebugCommands then
    RegisterCommand("poker:spawnprops", function()
        if Props then Props:DebugSpawnCandidates() end
    end, false)
end



-------- FUNCTIONS

function PlayAnimation(animationId)

    if hasLeft then
        return
    end

    math.randomseed(GetGameTimer())

    local animationArray = Config.Animations[animationId]
    local randomAnimationIndex = math.random(1, #animationArray)
    local animation = animationArray[randomAnimationIndex]

    if Config.DebugPrint then print("PlayAnimation - animation", animation) end

    RequestAnimDict(animation.Dict)
    while not HasAnimDictLoaded(animation.Dict) do
        Wait(100)
    end

    local playerPedId = PlayerPedId()

    local length = 0
    if animation.isIdle then
        length = -1
    elseif animation.Length then
        length = animation.Length
    else
        length = 4000
    end

    local blendIn = 8.0
    local blendOut = 1.0
    if animation.isIdle then
        blendIn = 1.0
        blendOut = 1.0
    end

    -- if Config.DebugPrint then print("PlayAnimation - length", length) end

    FreezeEntityPosition(playerPedId, true)

    -- if Config.DebugPrint then print("PlayAnimation - TaskPlayAnim") end
    TaskPlayAnim(playerPedId, animation.Dict, animation.Name, blendIn, blendOut, length, 25, 1.0, true, 0, false, 0, false)

    if length and length > 0 then
        -- if Config.DebugPrint then print("PlayAnimation - waiting") end
        Wait(length)
        PlayBestIdleAnimation()
    end
end

function PlayBestIdleAnimation()
    if Config.DebugPrint then print("PlayBestIdleAnimation") end

    -- Check if game exists before accessing it
    if not game then
        if Config.DebugPrint then print("PlayBestIdleAnimation - game is nil, skipping") end
        return
    end

    -- Check if players table exists
    if not game.players then
        if Config.DebugPrint then print("PlayBestIdleAnimation - game.players is nil, skipping") end
        return
    end

    local player
    for k,v in pairs(game.players) do
        if v.netId == GetPlayerServerId(PlayerId()) then
            player = v
            break
        end
    end

    if game.step == ROUNDS.SHOWDOWN or (player and player.hasFolded) then
        PlayAnimation("NoCards")
    else
        PlayAnimation("HoldCards")
    end
end

function startChairScenario(locationId, chairNumber)

    if Config.DebugPrint then print("startChairScenario", locationId, chairNumber) end


    -- Get the location's config
    local configTable = Config.Locations[locationId]

    local chairVector = configTable.Chairs[chairNumber].Coords

    if Config.DebugPrint then print("startChairScenario - chairVector", chairVector) end

    ClearPedTasksImmediately(PlayerPedId())

	FreezeEntityPosition(PlayerPedId(), true)

    TaskStartScenarioAtPosition(PlayerPedId(), GetHashKey("GENERIC_SEAT_CHAIR_TABLE_SCENARIO"), chairVector.x, chairVector.y, chairVector.z, chairVector.w, -1, false, true)
    
end

function findThisPlayerFromGameTable(_game)
    for k,playerTable in pairs(_game.players) do
        if playerTable.netId == GetPlayerServerId(PlayerId()) then
            return playerTable
        end
    end
end

function clearPedTaskAndUnfreeze(isSmooth)
    local playerPedId = PlayerPedId()
    FreezeEntityPosition(playerPedId, false)
    -- if isSmooth then
    --     ClearPedTasks(playerPedId)
    -- else
        ClearPedTasksImmediately(playerPedId)
    -- end
end

--------

AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() == resourceName then

        isInGame = false
        game = nil
        isNearTable = false
        nearTableLocationIndex = nil
        locations = {}
        hasLeft = false

        clearPedTaskAndUnfreeze(false)
        
        if Props then
            Props:CleanupAll()
        end
        if NPCVisuals then
            NPCVisuals:CleanupAll()
        end
    end

end)


AddEventHandler('playerDropped', function (reason)
    if Config.DebugPrint then print("Player dropped, cleaning up poker game") end
    
    -- Clean up all game state
    isInGame = false
    game = nil
    isNearTable = false
    nearTableLocationIndex = nil
    hasLeft = true
    playingPoker = false
    
    -- Clean up UI
    if UI then
        UI:CloseAll()
    end
    
    -- Clean up props
    if Props then
        Props:CleanupAll()
    end
    if NPCVisuals then
        NPCVisuals:CleanupAll()
    end
    
    -- Clear any active prompts
    local prompts = {PromptCall, PromptRaise, PromptCheck, PromptFold, PromptIncreaseAmount, PromptStart, PromptJoin, PromptBegin, PromptCancel, PromptLeave}
    for _, prompt in pairs(prompts) do
        if prompt and prompt.TogglePrompt then
            prompt:TogglePrompt(false)
        end
    end
    
    -- Clear ped tasks
    clearPedTaskAndUnfreeze(false)
end)