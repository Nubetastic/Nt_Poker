Framework = {}

local function isRSG()
    return (Config and (Config.Framework == 'RSG' or Config.Framework == 'rsg')) or false
end

if isRSG() then
    local Core = exports['rsg-core'] and exports['rsg-core']:GetCoreObject() or nil
    function Framework.getPlayer(source)
        if not Core or not source then return nil end
        return Core.Functions.GetPlayer(source)
    end
    function Framework.getName(source)
        local Player = Framework.getPlayer(source)
        local firstname = Player and Player.PlayerData and Player.PlayerData.charinfo and Player.PlayerData.charinfo.firstname
        return firstname or GetPlayerName(source)
    end
    function Framework.getCash(source)
        local Player = Framework.getPlayer(source)
        if not Player then return 0 end
        local cash = Player.Functions.GetMoney('cash') or 0
        return cash
    end
    function Framework.hasMoney(source, amount)
        amount = tonumber(amount)
        return Framework.getCash(source) >= (amount or 0)
    end
    function Framework.removeMoney(source, amount, reason)
        local Player = Framework.getPlayer(source)
        if not Player then return false end
        local cash = Player.Functions.GetMoney('cash') or 0
        if cash < (tonumber(amount) or 0) then return false end
        Player.Functions.RemoveMoney('cash', tonumber(amount) or 0, reason or 'poker')
        return true
    end
    function Framework.addMoney(source, amount, reason)
        local Player = Framework.getPlayer(source)
        if not Player then return false end
        Player.Functions.AddMoney('cash', tonumber(amount) or 0, reason or 'poker')
        return true
    end
else
    local VorpCore = nil
    if exports and exports['vorp_core'] and exports['vorp_core'].getCore then
        VorpCore = exports['vorp_core']:getCore()
    else
        TriggerEvent('getCore', function(core) VorpCore = core end)
    end
    local function getVorpCharacter(source)
        if not VorpCore or not source then return nil end
        if VorpCore.getUser then
            local User = VorpCore.getUser(source)
            if User and User.getUsedCharacter then
                return User:getUsedCharacter()
            end
        end
        if VorpCore.getCharacter then
            return VorpCore.getCharacter(source)
        end
        return nil
    end
    function Framework.getPlayer(source)
        return getVorpCharacter(source)
    end
    function Framework.getName(source)
        local char = getVorpCharacter(source)
        local fname = char and (char.firstname or (char.getFirstName and char:getFirstName())) or nil
        local lname = char and (char.lastname or (char.getLastName and char:getLastName())) or nil
        if fname and lname then return (tostring(fname) .. ' ' .. tostring(lname)) end
        if fname then return tostring(fname) end
        return GetPlayerName(source)
    end
    function Framework.getCash(source)
        local char = getVorpCharacter(source)
        if not char then return 0 end
        if type(char.money) ~= 'nil' then return tonumber(char.money) or 0 end
        if char.getMoney then return tonumber(char:getMoney()) or 0 end
        if char.getCurrency then return tonumber(char:getCurrency(0)) or 0 end
        return 0
    end
    function Framework.hasMoney(source, amount)
        amount = tonumber(amount)
        return Framework.getCash(source) >= (amount or 0)
    end
    function Framework.removeMoney(source, amount, reason)
        local char = getVorpCharacter(source)
        if not char then return false end
        amount = tonumber(amount) or 0
        local bal = Framework.getCash(source)
        if bal < amount then return false end
        if char.removeMoney then
            char:removeMoney(amount)
            return true
        end
        if char.removeCurrency then
            char:removeCurrency(0, amount)
            return true
        end
        if char.subMoney then
            char:subMoney(amount)
            return true
        end
        return false
    end
    function Framework.addMoney(source, amount, reason)
        local char = getVorpCharacter(source)
        if not char then return false end
        amount = tonumber(amount) or 0
        if char.addMoney then
            char:addMoney(amount)
            return true
        end
        if char.addCurrency then
            char:addCurrency(0, amount)
            return true
        end
        if char.addMoney and type(char.addMoney) == 'function' then
            char:addMoney(amount)
            return true
        end
        return false
    end
end
