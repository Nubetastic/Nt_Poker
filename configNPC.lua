ConfigNPC = {}

ConfigNPC.NPCEnable = true -- Enable npc players at tables.
ConfigNPC.NPCEnableOnlyOnHandLimit = true -- If true npc players will only be added to hand limit tables.
ConfigNPC.NPCHandLimitMax = 100 -- Max hand limit for npc players to be added to table.

ConfigNPC.Settings = {
    MaxPerTable = 3, -- max number of npc players at any table.
    NPCLeaveSeatFree = true, -- If there is an npc playing and less then 2 free seats then one npc at the table will leave between hands.
    MaxFreeSeats = 1, -- If there are less then this number of free seats at a table an npc will leave between hands.
    DecisionTime = math.random(30,120), -- time in seconds npc will take to make a decision.
}

ConfigNPC.NpcCash = {
    Min = 50,
    Max = 500,
    Poor = 150,
    Common = 300,
}


ConfigNPC.Models = {
    Rich = {
        "msp_saintdenis1_males_01",
        "u_m_m_bht_saintdenissaloon",
        "u_m_m_mud3pimp_01",
        "mp_u_m_m_animalpoacher_02",
        "mp_u_m_m_animalpoacher_06",
        "MP_U_M_M_SALOONBRAWLER_06",
        "u_f_m_bht_wife",
        "u_f_m_nbxresident_01",
        "mp_u_f_m_buyer_special_01",
    },
    Common = {
        "u_m_m_racforeman_01",
        "u_m_m_unibountyhunter_01",
        "u_m_m_unibountyhunter_02",
        "u_m_m_unidusterhenchman_01",
        "u_m_m_unidusterhenchman_02",
        "u_m_m_unidusterhenchman_03",
        "u_m_m_wtccowboy_04",
        "mp_u_m_m_animalpoacher_09",
        "MP_U_M_M_SALOONBRAWLER_02",
        "MP_U_M_M_SALOONBRAWLER_07",
        "MP_U_M_M_SALOONBRAWLER_11",
        "u_m_m_bht_strawberryduel",
        "mp_de_u_f_m_DOVERHILL_01",
        "mp_de_u_f_m_HEARTLANDS_01",
        "u_f_m_story_nightfolk_01",
        "mp_u_f_m_buyer_improved_01",
        "mp_u_f_m_nat_traveler_01",
    },
    Poor = {
        "u_m_m_emrfarmhand_03",
        "mp_u_m_m_animalpoacher_03",
        "mp_u_m_m_buyer_improved_01",
        "mp_u_m_m_nat_farmer_01",
        "MP_U_M_M_SALOONBRAWLER_03",
        "MP_U_M_M_SALOONBRAWLER_04",
        "MP_U_M_M_SALOONBRAWLER_01",
        "MP_U_M_M_SALOONBRAWLER_08",
        "MP_U_M_M_SALOONBRAWLER_09",
        "MP_U_M_M_SALOONBRAWLER_12",
        "u_m_m_armytrn4_01",
        "mp_de_u_f_m_BRAITHWAITE_01",
        "u_f_m_valtownfolk_01",
    },
}