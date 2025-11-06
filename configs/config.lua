Config = {

    -- Set language
    defaultlang = 'en_lang',
    -----------------------------------------------------

    devMode = {
        active = false, -- Set to true to enable debug logs
    },
    -----------------------------------------------------

    keys = {
        start = 0x760A9C6F, -- [G]
        reward = 0x760A9C6F, -- [G]
    },
    -----------------------------------------------------

    -- Discord Webhook Configuration
    Webhook = {
        URL = 'https://discord.com/api/webhooks/1435887550840701003/KY7ueV2LgNmv_qp9X610LROGfA8OE4AYcCXyBpfoGkAkgQpJJjw_UYVw4Z9Zp4Qc8HeT',
        Title = 'BCC-Waves',
        Avatar = ''
    },
    -----------------------------------------------------

    waveCooldown = 15, -- Time in minutes before the location can be used again (per player)
    -----------------------------------------------------

    FirstWaveDelay = 5, -- Time in seconds before the first enemy wave appears
    EnemyWaveDelay = 10, -- Time in seconds between enemy waves
    -----------------------------------------------------

    -- Remote blip: Shows radius blip to nearby players (not just the mission starter)
    RemoteBlip = {
        hintRadius = 50,         -- extra units added to areaBlip's radius to show active waves area
        color = 'LIGHT_YELLOW'   -- key from BlipColors to use for remote hint blips
    },
    -----------------------------------------------------

    -- Ped updater tuning
    -- WARNING: these values affect how often NPCs are updated and therefore
    -- can change CPU usage and NPC responsiveness. Only tweak if you know
    -- what you're doing or are following a measured tuning session.
    -- Defaults are conservative and work well for most servers.
    PedUpdater = {
        -- Target time budget (ms) to spend updating NPCs per slice.
        -- Larger means more NPCs processed per frame (more responsive),
        -- smaller means lower CPU but NPCs react slower.
        frameBudgetMs = 10, -- Default: 10

        -- Estimated cost per ped in milliseconds. This is an approximation
        -- used to compute how many peds we can update within the budget.
        -- You can lower this if you measure that updates are faster on your server.
        costPerPedMs = 2, -- Default: 2

        -- Minimum and maximum number of slices to split the active ped set into.
        -- Increasing maxSlices lets the updater spread work across more ticks.
        minSlices = 1,  -- Default: 1
        maxSlices = 16, -- Default: 16

        -- How long to wait (ms) between processing each slice.
        -- Lower values increase responsiveness but use more CPU.
        sliceWaitMs = 200, -- Default: 200

        -- How often (ms) the updater will reassign combat/movement tasks to
        -- the same NPC. Frequent reassignments can interrupt animations and
        -- movement (causing jitter). Increase this value to reduce jitter at
        -- the cost of slower reactions to target changes.
        taskReassignMs = 1000,  -- Default: 1000
    },
    -----------------------------------------------------

    BlipColors = {
        LIGHT_BLUE    = 'BLIP_MODIFIER_MP_COLOR_1',
        DARK_RED      = 'BLIP_MODIFIER_MP_COLOR_2',
        PURPLE        = 'BLIP_MODIFIER_MP_COLOR_3',
        ORANGE        = 'BLIP_MODIFIER_MP_COLOR_4',
        TEAL          = 'BLIP_MODIFIER_MP_COLOR_5',
        LIGHT_YELLOW  = 'BLIP_MODIFIER_MP_COLOR_6',
        PINK          = 'BLIP_MODIFIER_MP_COLOR_7',
        GREEN         = 'BLIP_MODIFIER_MP_COLOR_8',
        DARK_TEAL     = 'BLIP_MODIFIER_MP_COLOR_9',
        RED           = 'BLIP_MODIFIER_MP_COLOR_10',
        LIGHT_GREEN   = 'BLIP_MODIFIER_MP_COLOR_11',
        TEAL2         = 'BLIP_MODIFIER_MP_COLOR_12',
        BLUE          = 'BLIP_MODIFIER_MP_COLOR_13',
        DARK_PUPLE    = 'BLIP_MODIFIER_MP_COLOR_14',
        DARK_PINK     = 'BLIP_MODIFIER_MP_COLOR_15',
        DARK_DARK_RED = 'BLIP_MODIFIER_MP_COLOR_16',
        GRAY          = 'BLIP_MODIFIER_MP_COLOR_17',
        PINKISH       = 'BLIP_MODIFIER_MP_COLOR_18',
        YELLOW_GREEN  = 'BLIP_MODIFIER_MP_COLOR_19',
        DARK_GREEN    = 'BLIP_MODIFIER_MP_COLOR_20',
        BRIGHT_BLUE   = 'BLIP_MODIFIER_MP_COLOR_21',
        BRIGHT_PURPLE = 'BLIP_MODIFIER_MP_COLOR_22',
        YELLOW_ORANGE = 'BLIP_MODIFIER_MP_COLOR_23',
        BLUE2         = 'BLIP_MODIFIER_MP_COLOR_24',
        TEAL3         = 'BLIP_MODIFIER_MP_COLOR_25',
        TAN           = 'BLIP_MODIFIER_MP_COLOR_26',
        OFF_WHITE     = 'BLIP_MODIFIER_MP_COLOR_27',
        LIGHT_YELLOW2 = 'BLIP_MODIFIER_MP_COLOR_28',
        LIGHT_PINK    = 'BLIP_MODIFIER_MP_COLOR_29',
        LIGHT_RED     = 'BLIP_MODIFIER_MP_COLOR_30',
        LIGHT_YELLOW3 = 'BLIP_MODIFIER_MP_COLOR_31',
        WHITE         = 'BLIP_MODIFIER_MP_COLOR_32'
    },
    -----------------------------------------------------
}
