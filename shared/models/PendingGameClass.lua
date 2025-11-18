---@class PendingGame
PendingGame = {}

PendingGame.initiatorNetId = 0
PendingGame.players = {}
PendingGame.ante = 0
PendingGame.handLimitMultiplier = 0

-- function PendingGame:getLocation()
-- 	return self.location
-- end

-- function PendingGame:setLocation(location)
-- 	self.location = location
-- end

function PendingGame:getInitiatorNetId()
	return self.initiatorNetId
end

function PendingGame:setInitiatorNetId(initiatorNetId)
	self.initiatorNetId = initiatorNetId
end

function PendingGame:getPlayers()
	return self.players
end

function PendingGame:setPlayers(players)
	self.players = players
end

function PendingGame:getAnte()
	return self.ante
end

function PendingGame:setAnte(ante)
	self.ante = tonumber(ante) or 0
end

function PendingGame:getHandLimitMultiplier()
	return self.handLimitMultiplier or 0
end

function PendingGame:setHandLimitMultiplier(mult)
	self.handLimitMultiplier = tonumber(mult) or 0
end

--------

function PendingGame:addPlayer(pendingPlayer)

	table.insert(self.players, pendingPlayer)
end

function PendingGame:hasPlayerNetId(playerNetId)
	for k,v in pairs(self.players) do
		if v:getNetId() == playerNetId then
			return true
		end
	end
	return false
end


---@return PendingGame
function PendingGame:New(obj)
	local instance = setmetatable({}, {
        __index = self
    })
    instance.initiatorNetId = obj.initiatorNetId
	instance.players = obj.players
	instance.ante = tonumber(obj.ante) or 0
	instance.handLimitMultiplier = tonumber(obj.handLimitMultiplier) or 0
    return instance
end