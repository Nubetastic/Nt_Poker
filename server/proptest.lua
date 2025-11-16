RegisterNetEvent('nt_poker:proptest:save', function(block)
    local res = GetCurrentResourceName()
    local path = 'tablePrep.md'
    local existing = LoadResourceFile(res, path) or ''
    local ok = SaveResourceFile(res, path, existing .. "\n" .. tostring(block) .. "\n", -1)
    TriggerClientEvent('nt_poker:proptest:saved', source, ok ~= nil)
end)
