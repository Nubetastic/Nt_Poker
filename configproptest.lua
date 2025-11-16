ConfigPropsTest = {}


ConfigPropsTest.CardProps = {
    [1] = "p_cs_pokercard01x",
    [2] = "p_cs_pokercard02x",
    [3] = "p_pokercard01x",
    [4] = "p_card01x",
    [5] = "p_card02x",
    [6] = "p_playingcard01x",
    [7] = "p_gen_card01x", -- works but just a red card, not useful.
    [8] = "p_cs_holdemhand02x", -- works texas holden hand
    [9] = "p_pokerchips01x",
    [10] = "p_chips01x",
    [11] = "p_chip01x", -- works, single chip
    [12] = "p_gen_card01x",
    [13] = "p_gen_cards01x",
    [14] = "topcardpokerhand02x",
    [15] = "proc_card01x", -- blue single card, not suyre
    [16] = "s_playingcardpack01x",
    [17] = "p_cards01x", -- blue deck of cards
    [18] = "p_cards02x", -- blue deck of cards
    [19] = "p_pokercaddy01x", -- poker caddy
    [20] = "p_pokercaddy02x", -- poker caddy flat
    [21] = "p_pokerchipavarage01x", -- pile of chips, good for center of table bet pile.
    [22] = "p_pokerchipavarage02x",  -- neat pile of chips.
    [23] = "des_mg_pokertable", 
    [24] = "p_pokerchipante04x", 
    [25] = "p_pokerchipante05x", 
    [26] = "p_gen_tablepoker02x",
}



ConfigPropsTest.Props = {
    Deck = {
        model = "p_cards01x",
        offset = { x = 0.3, y = 0.2, z = 0.86 },
    },
    Pot = {
        model = "p_pokerchipante01x",
        offset = { x = -0.1, y = 0.0, z = 0.853 },
    },
    Plane = {
        model = "p_pokercaddy02x",
        offset = { x = 0.2, y = -0.1, z = 0.852, h = 25 },
    },
    PlayerChips = { 
        model = "p_pokerchiplosingstack01x",
        offset = { r = .7, deg = 25, z = 0.853 }, -- done by distance between table center and player
    },
}


