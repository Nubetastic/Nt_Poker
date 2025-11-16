Framework = {}


if (Config and (Config.Framework == 'RSG' or Config.Framework == 'rsg')) then
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
elseif (Config and (Config.Framework == 'VORP' or Config.Framework == 'vorp' or Config.Framework == 'Vorp')) then
    local VORPcore = exports.vorp_core and exports.vorp_core.GetCore and exports.vorp_core:GetCore() or nil
    local function getChar(source)
        if not VORPcore or not source then return nil end
        local user = VORPcore.getUser and VORPcore.getUser(source) or nil
        return user and user.getUsedCharacter or nil
    end
    function Framework.getPlayer(source)
        return getChar(source)
    end
    function Framework.getName(source)
        local char = getChar(source)
        local fname = char and (char.firstname or char.firstName) or nil
        local lname = char and (char.lastname or char.lastName) or nil
        if fname and lname then return (tostring(fname) .. ' ' .. tostring(lname)) end
        if fname then return tostring(fname) end
        return GetPlayerName(source)
    end
    function Framework.getCash(source)
        local char = getChar(source)
        if not char then return 0 end
        return tonumber(char.money) or 0
    end
    function Framework.hasMoney(source, amount)
        amount = tonumber(amount)
        return Framework.getCash(source) >= (amount or 0)
    end
    function Framework.removeMoney(source, amount, reason)
        local char = getChar(source)
        if not char then return false end
        amount = tonumber(amount) or 0
        if Framework.getCash(source) < amount then return false end
        if char.removeCurrency then char.removeCurrency(0, amount) return true end
        if char.subMoney then char.subMoney(amount) return true end
        if char.removeMoney then char.removeMoney(amount) return true end
        return false
    end
    function Framework.addMoney(source, amount, reason)
        local char = getChar(source)
        if not char then return false end
        amount = tonumber(amount) or 0
        if char.addCurrency then char.addCurrency(0, amount) return true end
        if char.addMoney then char.addMoney(amount) return true end
        return false
    end
end
