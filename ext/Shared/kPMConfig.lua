require ("__shared/GameTypes")

kPMConfig =
{
    -- ==========
    -- Debug mode options
    -- ==========
    DebugMode = false,

    -- ==========
    -- Server configuration options
    -- ==========
    AdminName = "KVN",

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
    MatchDefaultRounds = 12,

    -- Minimum of 2 players in order to start a match
    MinPlayerCount = 2,

    -- Minimum clan tag length
    MinClanTagLength = 1,

    -- Maximum strat time (default: 5 seconds)
    MaxStratTime = 10.0,

    -- Maximum knife round time (default: 5 minutes)
    MaxKnifeRoundTime = 120.0,

    -- Maximum transitition time between gamestates (default: 2 seconds)
    MaxTransititionTime = 5.0,

    -- Round time (default: 10 minutes)
    MaxRoundTime = 240.0,

    -- Game end time (default: 20 sec)
    MaxEndgameTime = 20.0,

    -- Squad size
    SquadSize = 24,

    -- Default gametype is GameTypes.Public
    GameType = GameTypes.Public,

    -- Bomb related stuff
    BombRadius = 1.5,
    BombTime = 60.0,
    PlantTime = 5.0,
    DefuseTime = 5.0,
}
