
Config = {}

Config.Debug = false
Config.DebugPrint = false
Config.DebugPrintUnsafe = false
Config.DebugCommands = false
Config.DebugOptions = {
    SkipStartGameOptions = false,
}

Config.Framework = "RSG" -- Supported: RSG, Vorp

Config.TableDistance = 2.6
Config.TurnTimeoutInSeconds = 2 * 60
Config.TurnTimeoutWarningInSeconds = 20
Config.BetweenRoundWait = 15000 -- Time to wait between rounds in ms
Config.HouseCut = 0.05 -- 5% house cut

Config.Keys = {
    ActionCall = "INPUT_FRONTEND_RB", -- E
    ActionRaise = "INPUT_CONTEXT_X", -- R
    ActionCheck = "INPUT_FRONTEND_RS", -- X
    ActionFold = "INPUT_CONTEXT_B", -- F
    IncreaseRaise = "INPUT_FRONTEND_UP", -- UP
    DecreaseRaise = "INPUT_FRONTEND_DOWN", -- DOWN
    StartGame = "INPUT_CONTEXT_A", -- SPACE
    JoinGame = "INPUT_CONTEXT_X", -- R
    BeginGame = "INPUT_CREATOR_ACCEPT", -- ENTER
    CancelGame = "INPUT_FRONTEND_RS", -- X
    LeaveGame = "INPUT_CONTEXT_A", -- SPACE
    AddNpc = "INPUT_INTERACT_LOCKON_POS", -- G (default)
}

Config.Locations = {
    ["Smithfields"] = {
        Table = {
            Coords = vector3(-304.53515625, 801.1351928710938, 117.97854614257812)
        },
        MaxPlayers = 6,
        Chairs = {
            [1] = {
                Coords = vector4(-303.7159118652344, 801.9509887695312, 118.48006439209, 495.00006103516),
            },
            [2] = {
                Coords = vector4(-303.3963623046875, 800.8367919921875, 118.48006439209, 435.0),
            },
            [3] = {
                Coords = vector4(-304.22540283203, 799.99670410156, 118.48006439209, 374.99998474121),
            },
            [4] = {
                Coords = vector4(-305.36395263672, 800.29479980469, 118.48006439209, 315.00004577637),
            },
            [5] = {
                Coords = vector4(-305.68051147461, 801.43267822266, 118.48006439209, 254.99998474121),
            },
            [6] = {
                Coords = vector4(-304.85144042969, 802.27276611328, 118.48006439209, 193.3058052063),
            },
        }
    },
    ["Blackwater"] = {
        Table = {
            Coords = vector3(-813.2147827148438, -1316.54736328125, 42.67874908447265)
        },
        MaxPlayers = 6,
        Chairs = {
            [1] = {
                Coords = vector4(-813.21484375, -1315.3173828125, 43.178806304932, 180.0),
            },
            [2] = {
                Coords = vector4(-812.14965820312, -1315.9323730469, 43.178745269775, 479.99996948242),
            },
            [3] = {
                Coords = vector4(-812.14978027344, -1317.1624755859, 43.178791046143, 420.00004577637),
            },
            [4] = {
                Coords = vector4(-813.21478271484, -1317.77734375, 43.178730010986, 359.99998474121),
            },
            [5] = {
                Coords = vector4(-814.27996826172, -1317.1623535156, 43.178760528564, 299.99995422363),
            },
            [6] = {
                Coords = vector4(-814.28009033203, -1315.9324951172, 43.178672790527, 240.00002670288),
            },
        }
    },
    ["Bastille"] = {
        Table = {
            Coords = vector3(2630.739990234375, -1226.25048828125, 52.3793716430664)
        },
        MaxPlayers = 6,
        Chairs = {
            [1] = {
                Coords = vector4(2629.7143554688, -1226.8499755859, 52.879585266113, 299.99995422363),
            },
            [2] = {
                Coords = vector4(2629.7067871094, -1225.6606445312, 52.879585266113, 240.00002670288),
            },
            [3] = {
                Coords = vector4(2630.7260742188, -1225.0499267578, 52.879585266113, 539.76260375977),
            },
            [4] = {
                Coords = vector4(2631.767578125, -1225.6502685547, 52.879753112793, 479.99996948242),
            },
            [5] = {
                Coords = vector4(2631.7666015625, -1226.8171386719, 52.879753112793, 420.00004577637),
            },
            [6] = {
                Coords = vector4(2630.7465820312, -1227.4375, 52.879585266113, 359.99998474121),
            },
        }
    },
    ["Tumbleweed"] = {
        Table = {
            Coords = vector3(-5510.39453125, -2913.763671875, 0.63532996177673)
        },
        MaxPlayers = 6,
        Chairs = {
            [1] = {
                Coords = vector4(-5509.8168945312, -2912.76171875, 1.1376080513, 521.35214233398),
            },
            [2] = {
                Coords = vector4(-5509.076171875, -2913.7365722656, 1.1376080513, 462.59912109375),
            },
            [3] = {
                Coords = vector4(-5509.7485351562, -2914.8395996094, 1.1376080513, 397.97984313965),
            },
            [4] = {
                Coords = vector4(-5510.9624023438, -2914.7702636719, 1.1376080513, 342.36683654785),
            },
            [5] = {
                Coords = vector4(-5511.638671875, -2913.7788085938, 1.1376080513, 286.14791870117),
            },
            [6] = {
                Coords = vector4(-5511.0307617188, -2912.7585449219, 1.1376080513, 212.57964706421),
            },
        }
    },
    ["SaintDenis_Backroom"] = {
        Table = {
            Coords = vector3(2717.64355469, -1285.60559082, 59.35139084)
        },
        MaxPlayers = 6,
        Chairs = {
            [1] = {
                Coords = vector4(2718.37719727, -1284.56481934, 59.85137177, 144.81988525),
            },
            [2] = { 
                Coords = vector4(2717.11108398, -1284.44995117, 59.85134888, 204.73828125),
            },
            [3] = {
                Coords = vector4(2716.37255859, -1285.48706055, 59.85139465, 264.67211914),
            },
            [4] = {
                Coords = vector4(2716.91040039, -1286.64672852, 59.85135651, 324.84735107),
            },
            [5] = {
                Coords = vector4(2718.16870117, -1286.74353027, 59.85141754, 24.77279663),
            },
            [6] = {
                Coords = vector4(2718.89746094, -1285.71374512, 59.85138702, 85.07020569),
            },
        },
    },
}


Config.Animations = {
    HoldCards = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "hold_cards_idle_a",
            isIdle = true,
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "look_medium_board_02",
            isIdle = true,
        },
    },
    --------
    NoCards = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "no_cards_idle_a",
            isIdle = true,
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "no_cards_idle_e",
            isIdle = true,
        },
    },
    --------
    Bet = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "bet_stack_a",
            Length = 2300,
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "bet_stack_b",
            Length = 2000,
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "bet_stack_c",
            Length = 1900,
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "bet_stack_d",
            Length = 2000,
        },
    },
    Check = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "check_a",
            Length = 1700,
        },
    },
    Fold = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "fold",
            Length = 1200,
        },
    },
    AllIn = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "take_pot_a",
        },
    },
    --------
    DealFlop = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "flop",
        },
    },
    DealTurn = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "turn_hold_cards",
            Length = 7000,
        },
    },
    DealRiver = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "river_hold_cards",
            Length = 7000,
        },
    },
    --------
    Reveal = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "reveal",
            Length = 4000,
        },
    },
    Roseanne = { -- Win
        {
            Dict = "mini_games@poker_mg@base",
            Name = "take_pot_a",
            Length = 7000,
        },
    },
    Win = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "express_win_a",
        },
    },
    Loss = {
        {
            Dict = "mini_games@poker_mg@base",
            Name = "express_loss_a",
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "express_loss_b",
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "express_loss_c",
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "express_loss_d",
        },
        {
            Dict = "mini_games@poker_mg@base",
            Name = "express_loss_e",
        },
    },
}
