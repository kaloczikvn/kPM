class "kPMClient"

require("ClientCommands")
require("Freecam")
require("UICleanup")
require("StratVision")
require("__shared/GameStates")
require("__shared/kPMConfig")
require("__shared/MapsConfig")
require("__shared/LevelNameHelper")

function kPMClient:__init()
    -- Start the client initialization
    print("client initialization")

    --  Console commands
    self.m_PositionCommand = nil

    -- Extension events
    self.m_ExtensionLoadedEvent = nil
    self.m_ExtensionUnloadedEvent = nil

    self.m_PartitionLoadedEvent = nil
    self.m_PlayerChatEvent = nil

    -- These are the specific events that are required to kick everything else off
    self.m_ExtensionLoadedEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadedEvent = Events:Subscribe("Extension:Unloaded", self, self.OnExtensionUnloaded)

    -- Ready-Up Inputs
    self.m_RupHeldTime = 0.0

    -- Plant Inputs
    self.m_PlantHeldTime = 0.0

    -- Tab / Scoreboard Inputs
    self.m_TabHeldTime = 0.0
    self.m_ScoreboardActive = false
    
    -- The current gamestate, this is read-only and should only be changed by the SERVER
    self.m_GameState = GameStates.None

    -- The current gametype
    self.m_GameType = GameTypes.Public

    self.m_AttackersTeamId = TeamId.Team2
    self.m_DefendersTeamId = TeamId.Team1

    -- Freecamera
    self.m_FreeCam = FreeCam()

    self.m_StatVision = StratVision()
end

-- ==========
-- Extensions
-- ==========

function kPMClient:OnExtensionLoaded()
    -- Register all of the console variable commands
    self:RegisterCommands()

    -- Register all of the events
    self:RegisterEvents()

    -- Initialize the WebUI
    WebUI:Init()

    -- Show the WebUI
    WebUI:Show()
end

function kPMClient:OnExtensionUnloaded()
    self:UnregisterCommands()
    self:UnregisterEvents()
end

-- ==========
-- Events
-- ==========
function kPMClient:RegisterEvents()
    print("registering events")

    -- Install input hooks
    self.m_InputPreUpdateHook = Hooks:Install("Input:PreUpdate", 1, self, self.OnInputPreUpdate)

    -- Engine tick
    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)

    -- Game State events
    self.m_GameStateChangedEvent = NetEvents:Subscribe("kPM:GameStateChanged", self, self.OnGameStateChanged)

    -- Game Type events
    self.m_GameTypeChangedEvent = NetEvents:Subscribe("kPM:GameTypeChanged", self, self.OnGameTypeChanged)

    -- Ready Up State Update
    self.m_RupStateEvent = NetEvents:Subscribe("kPM:RupStateChanged", self, self.OnRupStateChanged)

    -- Update ping table
    self.m_PlayerPing = NetEvents:Subscribe("Player:Ping", self, self.OnPlayerPing)
    self.m_PingTable = {}

    self.m_PlayerReadyUpPlayers = NetEvents:Subscribe("Player:ReadyUpPlayers", self, self.OnReadyUpPlayers)
    self.m_PlayerReadyUpPlayersTable = {}

    self.m_UIPushScreen = Hooks:Install('UI:PushScreen', 1, self, self.OnUIPushScreen)

    -- Player Events
    self.m_PlayerRespawnEvent = Events:Subscribe("Player:Respawn", self, self.OnPlayerRespawn)
    self.m_PlayerKilledEvent = Events:Subscribe("Player:Killed", self, self.OnPlayerKilled)
    self.m_PlayerDeletedEvent = Events:Subscribe("Player:Deleted", self, self.OnPlayerDeleted)

    -- Level events
    self.m_LevelDestroyEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)

    -- Client events
    self.m_ClientUpdateInputEvent = Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)

    -- WebUI
    self.m_SetSelectedTeamEvent = Events:Subscribe("WebUISetSelectedTeam", self, self.OnSetSelectedTeam)
    self.m_SetSelectedLoadoutEvent = Events:Subscribe("WebUISetSelectedLoadout", self, self.OnSetSelectedLoadout)
    
    self.m_StartWebUITimerEvent = NetEvents:Subscribe("kPM:StartWebUITimer", self, self.OnStartWebUITimer)
    self.m_UpdateHeaderEvent = NetEvents:Subscribe("kPM:UpdateHeader", self, self.OnUpdateHeader)
    self.m_SetRoundEndInfoBoxEvent = NetEvents:Subscribe("kPM:SetRoundEndInfoBox", self, self.OnSetRoundEndInfoBox)
    self.m_SetGameEndEvent = NetEvents:Subscribe("kPM:SetGameEnd", self, self.OnSetGameEnd)

    self.m_UpdateTeamsEvent = NetEvents:Subscribe("kPM:UpdateTeams", self, self.OnUpdateTeams)

    self.m_FirstSpawn = false

    -- Cleanup Events
    self.m_CleanupEvent = NetEvents:Subscribe("kPM:Cleanup", self, self.OnCleanup)
end

function kPMClient:UnregisterEvents()
    print("unregistering events")
end

function kPMClient:OnSetSelectedTeam(p_Team)
    if p_Team == nil then
        return
    end

    if p_Team == 2 then
        NetEvents:Send("kPM:PlayerSetSelectedTeam", self.m_AttackersTeamId)
    else
        NetEvents:Send("kPM:PlayerSetSelectedTeam", self.m_DefendersTeamId)
    end
end

function kPMClient:OnSetSelectedLoadout(p_Data)
    if p_Data == nil then
        return
    end

    -- If the player never spawned we should force him to pick a team and a loadout first
    if self.m_FirstSpawn == false then
        self.m_FirstSpawn = true
    end

    NetEvents:Send("kPM:PlayerSetSelectedKit", p_Data)
end

-- ==========
-- Console Commands
-- ==========
function kPMClient:RegisterCommands()
    print("registering commands")
    
    -- Register console commands for users to leverage
    self.m_PositionCommand = Console:Register("kpm_player_pos", "Displays the current player position", ClientCommands.PlayerPosition)
    self.m_ReadyUpCommand = Console:Register("kpm_ready_up", "Toggles the ready up state", ClientCommands.ReadyUp)
    self.m_ForceReadyUpCommand = Console:Register("kpm_force_ready_up", "Toggles all players to ready up state", ClientCommands.ForceReadyUp)
    
end

function kPMClient:UnregisterCommands()
    print("unregistering commands")
end

function kPMClient:OnLevelDestroyed()
    -- Handle cleanup when level is destroyed
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnLevelDestroy()
    end
end

function kPMClient:OnLevelLoaded()
    NetEvents:Send("kPM:PlayerConnected")
    WebUI:ExecuteJS("OpenCloseTeamMenu(true);")
end

function kPMClient:OnUpdateInput(p_DeltaTime)
    -- Update the freecam
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnUpdateInput(p_DeltaTime)
    end

    -- Open Team menu
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F9) then
        -- If the player never spawned we should force him to pick a team and a loadout first
        if self.m_FirstSpawn then
            WebUI:ExecuteJS("OpenCloseTeamMenu();")
        end
    end

    -- Open Loadout menu
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F10) then
        -- If the player never spawned we should force him to pick a team and a loadout first
        if self.m_FirstSpawn then
            WebUI:ExecuteJS("OpenCloseLoadoutMenu();")
        end
    end

    -- Manually check for toggles
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F4) then
        print("enabling freecam movement")
        self.m_FreeCam:OnEnableFreeCamMovement()
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F5) then
        print("control start")
        self.m_FreeCam:OnControlStart()
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F6) then
        print("control end")
        self.m_FreeCam:OnControlEnd()
    end
end

function kPMClient:OnInputPreUpdate(p_Hook, p_Cache, p_DeltaTime)
    -- Validate our cache
    if p_Cache == nil then
        print("err: invalid input cache.")
        return
    end

    -- Tab held or not
    self:IsTabHeld(p_Hook, p_Cache, p_DeltaTime)

    -- Check to see if we are in the warmup state to get rup status
    if self.m_GameState == GameStates.Warmup then
        -- Get the interact level
        local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptInteract)
        
        -- If the player is holding the interact key then update our variables and clear it for the next frame
        if s_InteractLevel > 0.0 then
            self.m_RupHeldTime = self.m_RupHeldTime + p_DeltaTime
            p_Cache:SetLevel(InputConceptIdentifiers.ConceptInteract, 0.0)
        else
            -- If the client isn't holding interact reset our time
            self.m_RupHeldTime = 0.0
        end

        WebUI:ExecuteJS("RupInteractProgress(" .. tostring(self.m_RupHeldTime) ..", " .. tostring(kPMConfig.MaxReadyUpTime) .. ");")

        -- Toggle the rup state
        if self.m_RupHeldTime >= kPMConfig.MaxReadyUpTime then
            -- Get the local player id
            local s_Player = PlayerManager:GetLocalPlayer()
            if s_Player == nil then
                print("err: could not get local player.")
                return
            end

            -- Get the local player id
            local s_PlayerId = s_Player.id

            -- Send the toggle event to the server
            NetEvents:Send("kPM:ToggleRup")

            print("rup status changed")

            -- Reset our rup timer
            self.m_RupHeldTime = 0.0
        end
    elseif self:IsPlayerInsideThePlantZone() and (self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf) then
        -- Get the interact level
        local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptInteract)

        -- If the player is holding the interact key then update our variables and clear it for the next frame
        if s_InteractLevel > 0.0 then
            self.m_PlantHeldTime = self.m_PlantHeldTime + p_DeltaTime
            p_Cache:SetLevel(InputConceptIdentifiers.ConceptInteract, 0.0)
        else
            -- If the client isn't holding interact reset our time
            self.m_PlantHeldTime = 0.0
        end

        WebUI:ExecuteJS("PlantInteractProgress(" .. tostring(self.m_PlantHeldTime) ..", " .. tostring(kPMConfig.PlantTime) .. ");")

        -- Toggle the rup state
        if self.m_PlantHeldTime >= kPMConfig.PlantTime then
            -- Get the local player id
            local s_Player = PlayerManager:GetLocalPlayer()
            if s_Player == nil then
                print("err: could not get local player.")
                return
            end

            -- Get the local player id
            local s_PlayerId = s_Player.id

            -- Send the toggle event to the server
            --NetEvents:Send("kPM:ToggleRup")

            print("client planted")

            -- Reset our rup timer
            self.m_PlantHeldTime = 0.0
        end
    end

    -- Update the freecam
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnUpdateInputHook(p_Hook, p_Cache, p_DeltaTime)
    end
end

function kPMClient:IsTabHeld(p_Hook, p_Cache, p_DeltaTime)
    -- Get the interact level
    local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptScoreboard)

    local l_ScoreboardActive = self.m_ScoreboardActive

    local l_Player = PlayerManager:GetLocalPlayer()
    
    if l_Player == nil then
        return
    end

    -- If the player is holding the interact key then update our variables and clear it for the next frame
    if s_InteractLevel > 0.0 then
        l_ScoreboardActive = true
        self.m_TabHeldTime = self.m_TabHeldTime + p_DeltaTime
        p_Cache:SetLevel(InputConceptIdentifiers.ConceptScoreboard, 0.0)
    else
        self.m_TabHeldTime = 0.0
        l_ScoreboardActive = false
    end

    if self.m_TabHeldTime >= 2.0 then
        self:OnUpdateScoreboard(l_Player)

        -- Reset our timer
        self.m_TabHeldTime = 0.0
    end


    if self.m_ScoreboardActive ~= l_ScoreboardActive then
        self.m_ScoreboardActive = l_ScoreboardActive

        if l_ScoreboardActive == true then
            self:OnUpdateScoreboard(l_Player)
        end

        if l_Player.alive == true then
            WebUI:ExecuteJS("OpenCloseScoreboard(" .. string.format('%s', l_ScoreboardActive) .. ");")
        end
    end
end

function kPMClient:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    -- TODO: Implement time related functionaity
    
end

function kPMClient:OnRupStateChanged(p_WaitingOnPlayers, p_LocalRupStatus)
    if p_WaitingOnPlayers == nil then
        print("err: invalid waiting on player count.")
        return
    end

    if p_LocalRupStatus == nil then
        print("err: invalid local rup status.")
        return
    end

    local l_Player = PlayerManager:GetLocalPlayer()
    self:OnUpdateScoreboard(l_Player)
end

function kPMClient:OnUIPushScreen(hook, screen, graphPriority, parentGraph)
    local screen = UIGraphAsset(screen)
    if screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsScreen' or
        screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsHUD32Screen'
    then
        hook:Return(nil)
        return
    end
end

function kPMClient:OnPlayerPing(p_PingTable)
    self.m_PingTable = p_PingTable
end

function kPMClient:OnReadyUpPlayers(p_ReadyUpPlayers)
    self.m_PlayerReadyUpPlayersTable = p_ReadyUpPlayers
end

function kPMClient:OnGameStateChanged(p_OldGameState, p_GameState)
    -- Validate our gamestates
    if p_OldGameState == nil or p_GameState == nil then
        print("err: invalid gamestate from server")
        return
    end

    if p_OldGameState == p_GameState then
        -- Removed the warning, on first connect it tries to update the local GameState to GameState.None, 
        -- later on when the player reconnects the local GameState going to change for him
        return
    end

    print("info: gamestate " .. p_OldGameState .. " -> " .. p_GameState)
    self.m_GameState = p_GameState

    if p_GameState == GameStates.Strat then
        self.m_StatVision:SetStratVision()
    else
        self.m_StatVision:RemoveStratVision()
    end

    -- Update the WebUI
    WebUI:ExecuteJS("ChangeState(" .. self.m_GameState .. ");")
end

function kPMClient:OnGameTypeChanged(p_GameType)
    -- Validate our gametype
    if p_GameType == nil then
        print("err: invalid gametype")
        return
    end

    print("info: gametype " .. p_GameType)
    self.m_GameType = p_GameType

    -- Update the WebUI
    WebUI:ExecuteJS("ChangeType(" .. self.m_GameType .. ");")
end

function kPMClient:OnUpdateHeader(p_AttackerPoints, p_DefenderPoints, p_Rounds)
    WebUI:ExecuteJS("UpdateHeader(" .. p_AttackerPoints .. ", " .. p_DefenderPoints .. ", " .. (p_Rounds + 1) .. ");")
end

function kPMClient:OnUpdateTeams(p_AttackersTeamId, p_DefendersTeamId)
    if self.m_AttackersTeamId ~= p_AttackersTeamId then
        self.m_AttackersTeamId = p_AttackersTeamId
    end

    if self.m_DefendersTeamId ~= p_DefendersTeamId then
        self.m_DefendersTeamId = p_DefendersTeamId
    end
end

function kPMClient:OnUpdateScoreboard(p_Player)
    if p_Player == nil then
        return
    end
    
    print("OnUpdateScoreboard")

    local l_PlayerListDefenders = PlayerManager:GetPlayersByTeam(self.m_DefendersTeamId)
    local l_PlayerListAttackers = PlayerManager:GetPlayersByTeam(self.m_AttackersTeamId)

    table.sort(l_PlayerListDefenders, function(a, b) 
		return a.score > b.score
    end)
    
    table.sort(l_PlayerListAttackers, function(a, b) 
		return a.score > b.score
    end)

    local l_PlayersObject = {}
    l_PlayersObject["defenders"] = {}
    l_PlayersObject["attackers"] = {}
    
    for index, l_Player in pairs(l_PlayerListDefenders) do
		local l_Ping = "0"
		if self.m_PingTable[l_Player.id] ~= nil and self.m_PingTable[l_Player.id] >= 0 and self.m_PingTable[l_Player.id] < 999 then
			l_Ping = self.m_PingTable[l_Player.id]
        end

        local l_Ready = false
        if self.m_PlayerReadyUpPlayersTable[l_Player.id] ~= nil then
            l_Ready = self.m_PlayerReadyUpPlayersTable[l_Player.id]
        end
        
		table.insert(l_PlayersObject["defenders"], {
            ["id"] = l_Player.id,
            ["name"] = l_Player.name,
            ["ping"] = l_Ping,
            ["kill"] = l_Player.kills,
            ["death"] = l_Player.deaths,
            ["isDead"] = not l_Player.alive,
            ["isReady"] = l_Ready,
            ["team"] = l_Player.teamId,
        })
    end

    for index, l_Player in pairs(l_PlayerListAttackers) do
		local l_Ping = "0"
		if self.m_PingTable[l_Player.id] ~= nil and self.m_PingTable[l_Player.id] >= 0 and self.m_PingTable[l_Player.id] < 999 then
			l_Ping = self.m_PingTable[l_Player.id]
        end

        local l_Ready = false
        if self.m_PlayerReadyUpPlayersTable[l_Player.id] ~= nil then
            l_Ready = self.m_PlayerReadyUpPlayersTable[l_Player.id]
        end

		table.insert(l_PlayersObject["attackers"], {
            ["id"] = l_Player.id,
            ["name"] = l_Player.name,
            ["ping"] = l_Ping,
            ["kill"] = l_Player.kills,
            ["death"] = l_Player.deaths,
            ["isDead"] = not l_Player.alive,
            ["isReady"] = l_Ready,
            ["team"] = l_Player.teamId,
        })
    end

    local l_Ping = "0"
    if self.m_PingTable[p_Player.id] ~= nil and self.m_PingTable[p_Player.id] >= 0 and self.m_PingTable[p_Player.id] < 999 then
        l_Ping = self.m_PingTable[p_Player.id]
    end

    local l_Ready = false
    if self.m_PlayerReadyUpPlayersTable[p_Player.id] ~= nil then
        l_Ready = self.m_PlayerReadyUpPlayersTable[p_Player.id]
    end

    local l_PlayerClient = {
        ["id"] = p_Player.id,
        ["name"] = p_Player.name,
        ["ping"] = l_Ping,
        ["kill"] = p_Player.kills,
        ["death"] = p_Player.deaths,
        ["isDead"] = not p_Player.alive,
        ["isReady"] = l_Ready,
        ["team"] = p_Player.teamId,
    }

    WebUI:ExecuteJS(string.format("UpdatePlayers(%s, %s);", json.encode(l_PlayersObject), json.encode(l_PlayerClient)))
end

function kPMClient:OnStartWebUITimer(p_Time)
    WebUI:ExecuteJS(string.format("SetTimer(%s);", p_Time))
end

function kPMClient:OnSetRoundEndInfoBox(p_WinnerTeamId)
    local isPlayerWinner = false

    local l_Player = PlayerManager:GetLocalPlayer()
    if l_Player.teamId == p_WinnerTeamId then
        isPlayerWinner = true
    end
    
    if p_WinnerTeamId == self.m_AttackersTeamId then
        WebUI:ExecuteJS('UpdateRoundEndInfoBox('.. tostring(isPlayerWinner) .. ', "attackers");')
    else
        WebUI:ExecuteJS('UpdateRoundEndInfoBox('.. tostring(isPlayerWinner) .. ', "defenders");')
    end
    
    WebUI:ExecuteJS("ShowHideRoundEndInfoBox(true)")
end

function kPMClient:OnSetGameEnd(p_WinnerTeamId)
    local isPlayerWinner = false

    if p_WinnerTeamId == nil then
        WebUI:ExecuteJS('SetGameEnd('.. tostring(isPlayerWinner) .. ', "draw");')
    end

    local l_Player = PlayerManager:GetLocalPlayer()
    if l_Player.teamId == p_WinnerTeamId then
        isPlayerWinner = true
    end
    
    if p_WinnerTeamId == self.m_AttackersTeamId then
        WebUI:ExecuteJS('SetGameEnd('.. tostring(isPlayerWinner) .. ', "attackers");')
    else
        WebUI:ExecuteJS('SetGameEnd('.. tostring(isPlayerWinner) .. ', "defenders");')
    end
end

function kPMClient:OnCleanup(p_EntityType)
    if p_EntityType == nil then
        return
    end
    local l_Entities = {}

    local l_Iterator = EntityManager:GetIterator(p_EntityType)
    local l_Entity = l_Iterator:Next()
    while l_Entity do
        l_Entities[#l_Entities+1] = Entity(l_Entity)
        l_Entity = l_Iterator:Next()
    end

    for _, l_Entity in pairs(l_Entities) do
        if l_Entity ~= nil then
            l_Entity:Destroy()
        end
    end
end

function kPMClient:OnPlayerRespawn(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end

end

function kPMClient:OnPlayerKilled(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end
    
    print('OnPlayerKilled')
end

function kPMClient:OnPlayerDeleted(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end

    print('OnPlayerDeleted')
end

function kPMClient:IsPlayerInsideThePlantZone()
    local l_LevelName = LevelNameHelper:GetLevelName()
    if l_LevelName == nil then
        return false
    end

    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        return false
    end

    -- Check to see if the player is alive
    if localPlayer.alive == false then
        return false
    end

    -- Get the local soldier instance
    local localSoldier = localPlayer.soldier
    if localSoldier == nil then
        return false
    end

    -- Get the soldier LinearTransform
    local soldierLinearTransform = localSoldier.worldTransform

    -- Get the position vector
    local position = soldierLinearTransform.trans

    -- print("A: " .. position:Distance(MapsConfig[l_LevelName]["PLANT_A"]["POS"].trans))
    -- print("B: " .. position:Distance(MapsConfig[l_LevelName]["PLANT_B"]["POS"].trans))

    if position:Distance(MapsConfig[l_LevelName]["PLANT_A"]["POS"].trans) <= MapsConfig[l_LevelName]["PLANT_A"]["RADIUS"] or
    position:Distance(MapsConfig[l_LevelName]["PLANT_B"]["POS"].trans) <= MapsConfig[l_LevelName]["PLANT_A"]["RADIUS"] then
        return true
    end
end

return kPMClient()
