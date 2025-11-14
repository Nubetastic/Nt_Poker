-- Poker audio bridge (natives-only)
-- Maps poker sound keys to RDR2 frontend sounds. Tune names/sets to your liking.
-- Usage from client code:
--   TriggerEvent('poker:playAudio', 'ChipDrop')
--   TriggerEvent('poker:playAudio', 'CardFlip1')
-- For backward-compat with previous file-based calls, common .ogg names are aliased below.

local NativeSounds = {
    ChipDrop   = { name = 'NAV_LEFT',      set = 'HUD_SHOP_SOUNDSET' },
    ChipTap    = { name = 'NAV_UP',        set = 'HUD_SHOP_SOUNDSET' },
    CardsDeal  = { name = 'NAV_DOWN',      set = 'HUD_SHOP_SOUNDSET' },
    TurnWarn   = { name = 'NAV_LEFT_RIGHT',set = 'HUD_SHOP_SOUNDSET' },
    Win        = { name = 'CONFIRM_BEEP',  set = 'HUD_SHOP_SOUNDSET' },
    Lose       = { name = 'ERROR',         set = 'HUD_SHOP_SOUNDSET' },
    CardFlip1  = { name = 'NAV_UP',        set = 'HUD_SHOP_SOUNDSET' },
    CardFlip2  = { name = 'NAV_DOWN',      set = 'HUD_SHOP_SOUNDSET' },
    CardFlip3  = { name = 'NAV_LEFT',      set = 'HUD_SHOP_SOUNDSET' },
}

-- Optional aliases for older file-based names used by shamey/rainbow-core
local Aliases = {
    ['poker_chip_drop_1.ogg'] = 'ChipDrop',
    ['poker_chip_tap_1.ogg']  = 'ChipTap',
    ['poker_cards_deal5.ogg'] = 'CardsDeal',
    ['tick_tock.ogg']         = 'TurnWarn',
    ['treasure.ogg']          = 'Win',
    ['brass_fail.ogg']        = 'Lose',
    ['card_flip1.ogg']        = 'CardFlip1',
    ['card_flip2.ogg']        = 'CardFlip2',
    ['card_flip3.ogg']        = 'CardFlip3',
}

local function normalizeKey(key)
    if not key then return nil end
    key = tostring(key)
    if NativeSounds[key] then return key end
    return Aliases[key]
end

-- Main event to play poker sounds via natives only
RegisterNetEvent('poker:playAudio', function(key)
    local k = normalizeKey(key)
    if not k then return end
    local s = NativeSounds[k]
    if s then
        -- RDR2 native: AUDIO::PLAY_SOUND_FRONTEND(soundId, soundName, soundSet, p4)
        PlaySoundFrontend(-1, s.name, s.set, true)
    end
end)

-- Optional export for direct use: exports['Nt_shamey-poker']:PokerPlayAudio('ChipDrop')
exports('PokerPlayAudio', function(key)
    local k = normalizeKey(key)
    if not k then return end
    local s = NativeSounds[k]
    if s then
        PlaySoundFrontend(-1, s.name, s.set, true)
    end
end)