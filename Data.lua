local addonName, addon = ...

-- Constants
addon.C_HETT_LIST_ITEM = 235053
addon.WEEKLY_QUEST_ID = 87296
addon.COMPLETION_THRESHOLD = 4
addon.FONT = "Fonts\\FRIZQT__.TTF"
addon.DEFAULT_FONT_SIZE = 24
addon.DEFAULT_WIDTH = 250

-- Valid zones for the addon to show
addon.VALID_ZONES = {
    [2346] = true, [2214] = true, [862] = true, [2396] = true,
}

-- Side gig quest IDs (special handling)
addon.SIDE_GIG_QUESTS = {
    [85962] = true, [86178] = true, [85553] = true, [86180] = true,
    [85554] = true, [85945] = true, [85960] = true, [86177] = true,
    [85913] = true, [85944] = true, [85914] = true, [86179] = true,
}

-- Main quest list
addon.QUESTS = {
    {id = 86923, name = "50 Fishing Pools",          key = "fish",      default = false},
    {id = 86920, name = "5 Player Kills",            key = "war",       default = false},
    {id = 86924, name = "5 Battle Pets",             key = "pets",      default = false},
    {id = 87304, name = "Excavation Delve",          key = "vacate",    default = false},
    {id = 87303, name = "Sidestreet Delve",          key = "sidestreet",default = true},
    {id = 86917, name = "10 Jobs",                   key = "jobs",      default = true},
    {id = 87302, name = "3 Rares",                   key = "rare",      default = true},
    {id = 86918, name = "100 Scrap Cans",            key = "scrap",     default = true},
    {id = 86919, name = "Side Gig",                  key = "gig",       default = true, special = "gig"},
    {id = 87305, name = "2 Races",                   key = "drive",     default = true},
    {id = 87306, name = "50 Turbo Cans",             key = "turbo",     default = true},
    {id = 87307, name = "25 Dumpsters",              key = "garbage",   default = true},
    {id = 86915, name = "Side with Cartel",          key = "cartel",    default = false},
}

-- Gossip automation data
addon.GOSSIP_RARE_NPCS = {[234834] = true, [234819] = true, [234751] = true, [236035] = true, [231221] = true}
addon.GOSSIP_RARE_OPTION = 124544
addon.GOSSIP_LIST_OPTION = 131991
addon.GOSSIP_DRILL_OPTIONS = {[125429] = true, [125409] = true, [125433] = true, [125434] = true}