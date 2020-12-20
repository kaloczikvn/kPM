require ("__shared/GameTypes")

kPMConfig =
{
    -- ==========
    -- Debug mode options
    -- ==========
    DebugMode = true,

    -- ==========
    -- Client configuration options
    -- ==========

    -- Maximum Ready up time
    MaxReadyUpTime = 1.5,

    -- When up tick rup game logic
    MaxRupTick = 1.0,

    -- When to tick name update logic
    MaxNameTick = 5.0,

    -- ==========
    -- Shared configuration options
    -- ==========

    -- Maximums
    MaxTeamNameLength = 32,
    MaxClanTagLength = 4,

    -- ==========
    -- Server configuration options
    -- ==========
    MatchDefaultRounds = 6,

    -- Minimum of 2 players in order to start a match
    MinPlayerCount = 1,

    -- Minimum clan tag length
    MinClanTagLength = 1,

    -- Maximum strat time (default: 5 seconds)
    MaxStratTime = 10.0,

    -- Maximum knife round time (default: 5 minutes)
    MaxKnifeRoundTime = 300.0,

    -- Maximum transitition time between gamestates (default: 2 seconds)
    MaxTransititionTime = 5.0,

    -- Round time (default: 10 minutes)
    MaxRoundTime = 300.0,

    -- Game end time (default: 20 sec)
    MaxEndgameTime = 20.0,

    -- Squad size
    SquadSize = 24,

    -- Default gametype is GameTypes.Public
    GameType = GameTypes.Public,

    -- Bomb related stuff
    BombRadius = 1.5,
    BombTime = 45.0,
    PlantTime = 5.0,
    DefuseTime = 5.0,

    A_SoundPlantingGuid = Guid('271E43CF-269A-10D2-PLAI-ASITEPLANT'),
    A_SoundPlantedGuid = Guid('271E43CF-269A-20D2-PLAN-ASITEPLANT'),
    A_SoundDefusingGuid = Guid('271E43CF-269A-30D2-DEFI-ASITEPLANT'),
    A_SoundDefusedgGuid = Guid('271E43CF-269A-40D2-DEFU-ASITEPLANT'),

    B_SoundPlantingGuid = Guid('271E43CF-269B-15D2-PLAI-BSITEPLANT'),
    B_SoundPlantedGuid = Guid('271E43CF-269B-25D2-PLAN-BSITEPLANT'),
    B_SoundDefusingGuid = Guid('271E43CF-269B-35D2-DEFI-BSITEPLANT'),
    B_SoundDefusedgGuid = Guid('271E43CF-269B-45D2-DEFU-BSITEPLANT'),
}
