ConfigProps = {}


ConfigProps.HandCardModel = "p_cs_holdemhand02x" -- cards players hold.

ConfigProps.Props = {
    Deck = {
        model = "p_cards01x",
        offset = { x = 0.3, y = 0.2, z = 0.86 },
    },
    Pot = {
        model = "p_pokerchipwinningstack01x",
        offset = { x = -0.1, y = 0.0, z = 0.853 },
    },
    Plane = { -- chip holder.
        model = "p_pokercaddy02x",
        offset = { x = 0.2, y = -0.1, z = 0.852, h = 25 }, -- h rotates on xy plane.
    },
    PlayerChips = { 
        model = {
            "p_pokerchipavarage01x",
            "p_pokerchipavarage02x",
            "p_pokerchipavarage03x",
        },
        offset = { r = .5, z = 0.853 }, -- r is radius from center of table to player.
    },
}
