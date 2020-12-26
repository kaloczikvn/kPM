class "kPMServer"

require ("__shared/kPMConfig")
require ("__shared/GameStates")
require ("__shared/Utils")
require ("__shared/GameTypes")

require ("Team")
require ("LoadoutManager")
require ("LoadoutDefinitions")
require ("Match")

function kPMServer:__init()
    print("server initialization")

    -- Register all of our needed events
    self:RegisterEvents()

    -- Hold gamestate information
    self.m_GameState = GameStates.None

    -- Create our team information
    self.m_Attackers = Team(TeamId.Team2, "Attackers", "") -- RUS
    self.m_Defenders = Team(TeamId.Team1, "Defenders", "") -- US

    -- Loadout manager
    self.m_LoadoutManager = LoadoutManager()

    -- Create a new match
    self.m_Match = Match(self, self.m_Attackers, self.m_Defenders, kPMConfig.MatchDefaultRounds, self.m_LoadoutManager, kPMConfig.GameType)

    -- Ready up tick
    self.m_RupTick = 0.0

    -- Name update
    self.m_NameTick = 0.0

    -- Match management
    self.m_AllowedGuids = { }

    -- Callbacks
    self.m_MatchStateCallbacks = { }

    ServerUtils:SetCustomGameModeName("Promod")
end

function kPMServer:RegisterEvents()
    -- Engine tick
    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)

    -- Player join/leave
    self.m_PlayerRequestJoinHook = Hooks:Install("Player:RequestJoin", 1, self, self.OnPlayerRequestJoin)

    self.m_PlayerJoiningEvent = Events:Subscribe("Player:Joining", self, self.OnPlayerJoining)
    self.m_PlayerLeaveEvent = Events:Subscribe("Player:Left", self, self.OnPlayerLeft)
    self.m_PlayerKilledEvent = Events:Subscribe("Player:Killed", self, self.OnPlayerKilled)

    -- Team management
    self.m_PlayerFindBestSquadHook = Hooks:Install("Player:FindBestSquad", 1, self, self.OnPlayerFindBestSquad)
    self.m_PlayerSelectTeamHook = Hooks:Install("Player:SelectTeam", 1, self, self.OnPlayerSelectTeam)

    -- Round management
    
    -- Damage hooks
    self.m_SoldierDamageHook = Hooks:Install("Soldier:Damage", 1, self, self.OnSoldierDamage)

    -- Events from the client
    self.m_ToggleRupEvent = NetEvents:Subscribe("kPM:ToggleRup", self, self.OnToggleRup)
    self.m_TogglePlantEvent = NetEvents:Subscribe("kPM:TogglePlant", self, self.OnTogglePlant)

    self.m_PlaySoundPlantingEvent = NetEvents:Subscribe("kPM:PlaySoundPlanting", self, self.OnPlaySoundPlanting)

    -- TODO: This is a debug only function
    self.m_ForceToggleRupEvent = NetEvents:Subscribe("kPM:ForceToggleRup", self, self.OnForceToggleRup)
    self.m_PlayerConnectedEvent = NetEvents:Subscribe("kPM:PlayerConnected", self, self.OnPlayerConnected)
    self.m_PlayerSetSelectedTeamEvent = NetEvents:Subscribe("kPM:PlayerSetSelectedTeam", self, self.OnPlayerSetSelectedTeam)
    self.m_PlayerSetSelectedKitEvent = NetEvents:Subscribe("kPM:PlayerSetSelectedKit", self, self.OnPlayerSetSelectedKit)

    -- Chat events
    self.m_PlayerChatEvent = Events:Subscribe("Player:Chat", self, self.OnPlayerChat)

    -- Partition events
    self.m_PartitionLoadedEvent = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)

    -- Level events
    self.m_LevelDestroyedEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)

    -- This starts the round manually, skipping any preround logic.
    -- It also requires the PreRoundEntity to be removed for it to work properly.
    self.m_EntityFactoryCreateFromBlueprintHook = Hooks:Install("EntityFactory:CreateFromBlueprint", 100, self, self.OnEntityFactoryCreateFromBlueprint)
end

function kPMServer:OnEntityFactoryCreateFromBlueprint(p_Hook, p_Blueprint, p_Transform, p_Variation, p_ParentRepresentative)
    if Blueprint(p_Blueprint).name == 'Gameplay/Level_Setups/Complete_setup/Full_TeamDeathmatch' then
        local tdmBus = p_Hook:Call()

        for _, l_Entity in pairs(tdmBus.entities) do
            if l_Entity:Is('ServerInputRestrictionEntity') then
                l_Entity:FireEvent('Deactivate')
            elseif l_Entity:Is('ServerRoundOverEntity') then
                l_Entity:FireEvent('RoundStarted')
            elseif l_Entity:Is('EventGateEntity') and l_Entity.data.instanceGuid == Guid('B7F13498-C61B-47E6-895E-0ED2048E7AF4') then
                l_Entity:FireEvent('Close')
            end
        end
    end
end

function kPMServer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)

    -- Update the match
    self.m_Match:OnEngineUpdate(self.m_GameState, p_DeltaTime)

    -- Check if the name
    if self.m_NameTick >= kPMConfig.MaxNameTick then
        -- Reset the name tick
        self.m_NameTick = 0.0

        local l_PingTable = {}

        -- Iterate all players
        local s_Players = PlayerManager:GetPlayers()
        for l_Index, l_Player in ipairs(s_Players) do
            -- Get the player team and name
            local l_Team = l_Player.teamId
            local l_Name = l_Player.name

            local l_ClanTag = ""
            if l_Team == self.m_Attackers:GetTeamId() then
                l_ClanTag = self.m_Attackers:GetClanTag()
            elseif l_Team == self.m_Defenders:GetTeamId() then
                l_ClanTag = self.m_Defenders:GetClanTag()
            end

            -- Check to make sure the clan tag min length is > 1
            if #l_ClanTag > kPMConfig.MinClanTagLength then
                -- Check if the player name already starts with the clan tag
                local l_Tag = "[" .. l_ClanTag .. "]"

                -- Check if the name starts with the class time
                if Utils.starts_with(l_Name, l_Tag) == false then
                    -- New name
                    local l_NewName = l_Tag .. " " .. l_Name

                    -- Update the player name
                    l_Player.name = l_NewName
                    print("updating " .. l_Name .. " to " .. l_NewName)
                end
            end

            l_PingTable[l_Player.id] = l_Player.ping
            NetEvents:Broadcast('Player:Ping', l_PingTable)
        end
    end
    self.m_NameTick = self.m_NameTick + p_DeltaTime
end

function kPMServer:OnPlayerRequestJoin(p_Hook, p_JoinMode, p_AccountGuid, p_PlayerGuid, p_PlayerName)
    -- Ensure that spectators can join the server at will
    if p_JoinMode ~= "player" then
        p_Hook:Return(true)
        return
    end

    -- Handle player joining

    -- If we are in the warmup gamestate or the endgame gamestate then allow players that aren't on the whitelist to join
    -- On public gametype everyone can join at any time
    if kPMConfig.GameType == GameTypes.Public or self.m_GameState == GameStates.Warmup or self.m_GameState == GameStates.None then
        p_Hook:Return(true)
        return
    end

    for l_Index, l_Guid in ipairs(self.m_AllowedGuids) do
        -- Check if the guid is on the allow list
        if l_Guid == p_AccountGuid then
            -- Allow for reconnects if a player disconnects
            p_Hook:Return(true)
            return
        end
    end

    -- This means that we were not in warmup, endgame, or no gamestate
    -- And a player tried to join a match in progress that wasn't there at the beginning

    p_Hook:Return(false)
end

-- This function takes a snapshot of all players in the server and adds them to the allow list
function kPMServer:UpdateAllowedGuids()
    if kPMConfig.GameType == GameTypes.Public then
        return
    end

    -- Clear our the previous guids
    self.m_AllowedGuids = { }

    -- Iterate through all players
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate the player
        if l_Player == nil then
            if kPMConfig.DebugMode then
                print("err: invalid player at index: " .. l_Index)
            end
            goto update_allowed_guids_continue
        end

        -- Add the account guid to the allowed guid
        table.insert(self.m_AllowedGuids, l_Player.accountGuid)

        -- Debug logging
        if kPMConfig.DebugMode then
            print("added player: " .. tostring(l_Player.name) .. " guid: " .. tostring(l_Player.accountGuid) .. " to the allow list.")
        end

        -- Lua does not have continue statement, so this hack is a workaround
        ::update_allowed_guids_continue::
    end
end

function kPMServer:OnPlayerJoining(p_Name, p_Guid, p_IpAddress, p_AccountGuid)
    -- Here we can send the event to whichever state we are running in
    print("info: player " .. p_Name .. " is joining the server")
end

function kPMServer:OnPlayerConnected(p_Player)
    if p_Player == nil then
        print("err: invalid player tried to connect.")
        return
    end

    self.m_Match:ForceUpdateHeader(p_Player)

    -- Send out gamestate information if he connects or reconnects
    NetEvents:SendTo("kPM:GameStateChanged", p_Player, GameStates.None, self.m_GameState)

    -- Send out the gametype if he connects or reconnects
    NetEvents:SendTo("kPM:GameTypeChanged", p_Player, kPMConfig.GameType)

    -- Send out the teams if he connects or reconnects
    NetEvents:SendTo("kPM:UpdateTeams", p_Player, self.m_Attackers:GetTeamId(), self.m_Defenders:GetTeamId())

    -- Send out the timer if its mid round
    if self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf then
        self:SetClientTimer(kPMConfig.MaxRoundTime - self.m_Match.m_UpdateTicks[self.m_GameState], p_Player)
    end
end

function kPMServer:OnPlayerLeft(p_Player)
    print("info: player " .. p_Player.name .. " has left the server")
end

function kPMServer:OnPlayerKilled(p_Player)
    if self.m_GameState == GameStates.Warmup or self.m_GameState == GameStates.None then
        self.m_Match:AddPlayerToSpawnQueue(
            p_Player, 
            self.m_Match:GetRandomSpawnpoint(p_Player), 
            CharacterPoseType.CharacterPoseType_Stand, 
            self:GetSoldierBlueprint(), 
            false,
            self.m_LoadoutManager:GetPlayerLoadout(p_Player)
        )
    end
end

function kPMServer:OnPlayerSetSelectedTeam(p_Player, p_Team)
    if p_Player == nil or p_Team == nil then
        return
    end

    if kPMConfig.GameType == GameTypes.Public then
        if self.m_GameState == GameStates.Strat or
            self.m_GameState == GameStates.None or 
            self.m_GameState == GameStates.Warmup
        then
            print("info: player " .. p_Player.name .. " has selected " .. p_Team .." team")
            p_Player.teamId = p_Team;

            if p_Player.soldier ~= nil then
                self.m_Match:KillPlayer(p_Player, false)

                self.m_Match:AddPlayerToSpawnQueue(
                    p_Player, 
                    self.m_Match:GetRandomSpawnpoint(p_Player), 
                    CharacterPoseType.CharacterPoseType_Stand, 
                    self:GetSoldierBlueprint(), 
                    false,
                    self.m_LoadoutManager:GetPlayerLoadout(p_Player)
                )
            end
        else
            if p_Player.soldier == nil or not p_Player.alive then
                print("info: player " .. p_Player.name .. " has selected " .. p_Team .." team")
                p_Player.teamId = p_Team;
            end
        end
    elseif kPMConfig.GameType == GameTypes.Comp then
        if self.m_GameState == GameStates.None or 
            self.m_GameState == GameStates.Warmup
        then
            print("info: player " .. p_Player.name .. " has selected " .. p_Team .." team")
            p_Player.teamId = p_Team;

            if p_Player.soldier ~= nil then
                self.m_Match:KillPlayer(p_Player, false)

                self.m_Match:AddPlayerToSpawnQueue(
                    p_Player, 
                    self.m_Match:GetRandomSpawnpoint(p_Player), 
                    CharacterPoseType.CharacterPoseType_Stand, 
                    s_SoldierBlueprint, 
                    false,
                    self.m_LoadoutManager:GetPlayerLoadout(p_Player)
                )
            end
        end
    end
end

function kPMServer:OnPlayerSetSelectedKit(p_Player, p_Data)
    if p_Player == nil or p_Data == nil then
        return
    end

    local l_Data = json.decode(p_Data)

    if Kits[l_Data["class"]] == nil then
        print("err: invalid kit.")
        return
    end
    
    self.m_LoadoutManager:SetPlayerLoadout(p_Player, l_Data)

    if self.m_GameState == GameStates.Warmup or self.m_GameState == GameStates.None or self.m_GameState == GameStates.Strat then
        -- If the current gamestate is Warmup or None we can switch kit instantly
        if p_Player.soldier ~= nil then
            self.m_Match:KillPlayer(p_Player, false)
        end

        self.m_Match:AddPlayerToSpawnQueue(
            p_Player, 
            self.m_Match:GetRandomSpawnpoint(p_Player), 
            CharacterPoseType.CharacterPoseType_Stand, 
            self:GetSoldierBlueprint(),
            false,
            self.m_LoadoutManager:GetPlayerLoadout(p_Player)
        )
    end
end

function kPMServer:GetSoldierBlueprint()
    return ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')
end

function kPMServer:OnPlayerFindBestSquad(p_Hook, p_Player)
    -- TODO: Force squad
end

function kPMServer:OnPlayerSelectTeam(p_Hook, p_Player, p_Team)
    -- p_Team is R/W
    -- p_Player is RO
end

function kPMServer:OnPartitionLoaded(p_Partition)
    -- Validate our partition
    if p_Partition == nil then
        return
    end

    -- Send event to the loadout manager
    self.m_LoadoutManager:OnPartitionLoaded(p_Partition)
end

function kPMServer:OnSoldierDamage(p_Hook, p_Soldier, p_Info, p_GiverInfo)
    if p_Soldier == nil then
        return
    end

    if p_Info == nil then
        return
    end

    -- TODO: Fixme
    -- If we are in warmup, then disable damage of all kind
    if self.m_GameState == GameStates.None or self.m_GameState == GameStates.Warmup then
        if p_GiverInfo.giver == nil or p_GiverInfo.damageType == DamageType.Suicide then
            return
        end

        p_Info.damage = 0.0
        p_Hook:Pass(p_Soldier, p_Info, p_GiverInfo)
    end
end

function kPMServer:OnToggleRup(p_Player)
    -- Check to see if we have a valid player
    if p_Player == nil then
        print("err: invalid player tried to rup.")
        return
    end

    -- Get the player information
    local s_PlayerName = p_Player.name
    local s_PlayerId = p_Player.id

    -- We only care if we are in warmup state, otherwise rups mean nothing
    if self.m_GameState ~= GameStates.Warmup then
        print("err: player " .. s_PlayerName .. " tried to rup in non-warmup?")
        return
    end

    -- Update the match information
    self.m_Match:OnPlayerRup(p_Player)
end

-- TODO: This is a debug only function
function kPMServer:OnForceToggleRup(p_Player)
    if p_Player == nil then
        print("err: invalid player.")
        return
    end

    local s_PlayerName = p_Player.name
    local s_PlayerId = p_Player.id

    if self.m_GameState ~= GameStates.Warmup then
        return
    end

    self.m_Match:ForceAllPlayerRup()
end

function kPMServer:OnTogglePlant(p_Player, p_PlantOrDefuse, p_BombSite, p_BombLocation, p_Force)
    -- Check to see if we have a valid player
    if p_Player == nil then
        print("err: invalid player tried to " .. p_PlantOrDefuse)
        return
    end

    if p_BombSite == nil then
        print("err: invalid bombsite")
        return
    end

    if self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf then
        self.m_Match:OnTogglePlant(p_Player, p_PlantOrDefuse, p_BombSite, p_BombLocation, p_Force)
    else
        print("err: player " .. p_Player.name .. " tried to " .. p_PlantOrDefuse .. " in non-round?")
    end
end

function kPMServer:OnPlaySoundPlanting(p_Player, p_Trans)
    print('Someone planting on:')
    print(p_Trans)
    
    if p_Trans == nil then
        return
    end

    NetEvents:Broadcast("kPM:PlaySoundPlanting", p_Trans)
end

function kPMServer:OnPlayerChat(p_Player, p_RecipientMask, p_Message)
    -- Check the player
    if p_Player == nil then
        return
    end

    -- Check the message
    if p_Message == nil then
        return
    end

    -- Check the length of the message
    if #p_Message <= 0 then
        return
    end

    -- Check for ready up state
    if Utils.starts_with(p_Message, "!warmup") then
        self:ChangeGameState(GameStates.Warmup)
    end

    if Utils.starts_with(p_Message, "!warmuptoknife") then

    end
end

function kPMServer:OnLevelDestroyed()
    -- Forward event to loadout mananager
    self.m_LoadoutManager:OnLevelDestroyed()
end

function kPMServer:OnLevelLoaded(p_LevelName, p_GameMode, p_Round, p_RoundsPerMap)
    self:SetupVariables()

    if self.m_GameState ~= GameStates.None then
        self.m_Match:RestartMatch()
    end
end

-- Helper functions
function kPMServer:ChangeGameState(p_GameState)
    if p_GameState < GameStates.None or p_GameState > GameStates.EndGame then
        print("err: attempted to switch to an invalid gamestate.")
        return
    end

    local s_OldGameState = self.m_GameState
    self.m_GameState = p_GameState

    -- Call UpdateAllowedGuids when Warmup ends
    if p_GameState ~= GameStates.Warmup and s_OldGameState == GameStates.Warmup then
        self:UpdateAllowedGuids()
    end

    NetEvents:Broadcast("kPM:GameStateChanged", s_OldGameState, p_GameState)
end

function kPMServer:SetClientTimer(p_Time, p_Player)
    if p_Time == nil then
        print("err: no time to send to the clients")
        return
    end

    if p_Player ~= nil then
        NetEvents:SendTo("kPM:StartWebUITimer", p_Player, p_Time)
    else
        NetEvents:Broadcast("kPM:StartWebUITimer", p_Time)
    end
end

function kPMServer:SetRoundEndInfoBox(p_WinnerTeamId)
    if p_WinnerTeamId == nil then
        print("err: no winner to send to the clients")
        return
    end

    NetEvents:Broadcast("kPM:SetRoundEndInfoBox", p_WinnerTeamId)
end

function kPMServer:SetGameEnd(p_WinnerTeamId)
    -- Watch out, this can be nil if the game is draw
    NetEvents:Broadcast("kPM:SetGameEnd", p_WinnerTeamId)
end

function kPMServer:SetupVariables()
    -- Hold a dictionary of all of the variables we want to change
    local s_VariablePair = {
        ["vars.friendlyFire"] = "true",
        ["vars.soldierHealth"] = "100",
        ["vars.regenerateHealth"] = "false",
        ["vars.onlySquadLeaderSpawn"] = "false",
        ["vars.3dSpotting"] = "false",
        ["vars.miniMap"] = "true",
        ["vars.autoBalance"] = "false",
        ["vars.teamKillCountForKick"] = "20",
        ["vars.teamKillValueForKick"] = "10",
        ["vars.teamKillValueIncrease"] = "1",
        ["vars.teamKillValueDecreasePerSecond"] = "1",
        ["vars.idleTimeout"] = "300",
        ["vars.3pCam"] = "false",
        ["vars.killCam"] = "false",
        ["vars.roundStartPlayerCount"] = "0",
        ["vars.roundRestartPlayerCount"] = "0",
        ["vars.hud"] = "true",
        ["vu.SquadSize"] = tostring(kPMConfig.SquadSize),
        ["vu.ColorCorrectionEnabled"] = "false",
        ["vu.SunFlareEnabled"] = "false",
        ["vu.SuppressionMultiplier"] = "0",
        ["vu.DestructionEnabled"] = "false",
    }

    -- Iterate through all of the commands and set their values via rcon
    for l_Command, l_Value in pairs(s_VariablePair) do
        local s_Result = RCON:SendCommand(l_Command, { l_Value })

        if #s_Result >= 1 then
            if s_Result[1] ~= "OK" then
                print("command: " .. l_Command .. " returned: " .. s_Result[1])
            end
        end
    end

    print("RCON Variables Setup")
end

return kPMServer()
