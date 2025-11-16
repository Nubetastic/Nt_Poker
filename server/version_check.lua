local remoteManifestUrl = 'https://raw.githubusercontent.com/Nubetastic/Nt_Poker/main/fxmanifest.lua'

local function extractVersionFromManifest(text)
    for line in string.gmatch(text or '', "[^\r\n]+") do
        local v = line:match('^%s*version%s*[%s=]*%s*"([^"]+)"')
            or line:match("^%s*version%s*[%s=]*%s*'([^']+)'")
            or line:match('^%s*version%s+([%w%.%-_]+)')
        if v and #v > 0 then return v end
    end
    return nil
end

local function compareVersions(a, b)
    local function splitNums(v)
        local t = {}
        for num in tostring(v):gmatch('(%d+)') do
            t[#t+1] = tonumber(num) or 0
        end
        return t
    end
    local ap, bp = splitNums(a), splitNums(b)
    local len = math.max(#ap, #bp)
    for i = 1, len do
        local ai = ap[i] or 0
        local bi = bp[i] or 0
        if ai < bi then return -1 end
        if ai > bi then return 1 end
    end
    return 0
end

CreateThread(function()
    local res = GetCurrentResourceName()
    local localVersion = GetResourceMetadata(res, 'version', 0) or '0.0.0'
    print(('[%s] local version: %s'):format(res, tostring(localVersion)))
    PerformHttpRequest(remoteManifestUrl, function(status, body)
        if status ~= 200 or not body or #body == 0 then
            print(('[%s] version check failed (%s)'):format(res, tostring(status)))
            return
        end
        local remoteVersion = extractVersionFromManifest(body)
        if not remoteVersion then
            print(('[%s] could not parse remote version'):format(res))
            return
        end
        print(('[%s] remote version: %s'):format(res, tostring(remoteVersion)))
        local cmp = compareVersions(localVersion, remoteVersion)
        if cmp < 0 then
            print(('^1[%s] update available: %s -> %s^7'):format(res, localVersion, remoteVersion))
        else
            print(('[%s] up to date (%s)'):format(res, localVersion))
        end
    end, 'GET', '', { ['User-Agent'] = 'Nt_PokerVersionChecker' })
end)
