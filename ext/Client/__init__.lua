class "kPMClient"

require("ClientCommands")
require("SpecCam")
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
    self.m_RupHeldReady = false

    -- Plant Inputs
    self.m_PlantOrDefuseHeldTime = 0.0
    self.m_StartedPlantingOrDefusing = false
    self.m_BombSite = nil
    self.m_BombLocation = nil
    self.m_LaptopEntity = nil

    self.m_PlayerInputs = true

    -- Tab / Scoreboard Inputs
    self.m_TabHeldTime = 0.0
    self.m_ScoreboardActive = false
    
    -- The current gamestate, this is read-only and should only be changed by the SERVER
    self.m_GameState = GameStates.None

    -- The current gametype
    self.m_GameType = GameTypes.Public

    self.m_AttackersTeamId = TeamId.Team2
    self.m_DefendersTeamId = TeamId.Team1

    self.m_FirstSpawn = false

    self.m_ExplosionEntityData = nil

    self.m_PlantSoundEntityData = nil
    self.m_PlantSent = false

    -- Freecamera
    self.m_SpecCam = SpecCam()

    -- Start vision (black and white)
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

    self.m_PartitionLoadedEvent = Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoaded)

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

    -- Player Events
    self.m_PlayerRespawnEvent = Events:Subscribe("Player:Respawn", self, self.OnPlayerRespawn)
    self.m_PlayerKilledEvent = Events:Subscribe("Player:Killed", self, self.OnPlayerKilled)
    self.m_PlayerDeletedEvent = Events:Subscribe("Player:Deleted", self, self.OnPlayerDeleted)

    -- Level events
    self.m_LevelDestroyEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)
    self.m_LevelLoadResourcesEvent = Events:Subscribe("Level:LoadResources", self, self.OnLevelLoadResources)

    -- Client events
    self.m_ClientUpdateInputEvent = Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)

    -- WebUI
    self.m_SetSelectedTeamEvent = Events:Subscribe("WebUISetSelectedTeam", self, self.OnSetSelectedTeam)
    self.m_SetSelectedLoadoutEvent = Events:Subscribe("WebUISetSelectedLoadout", self, self.OnSetSelectedLoadout)
    
    self.m_StartWebUITimerEvent = NetEvents:Subscribe("kPM:StartWebUITimer", self, self.OnStartWebUITimer)
    self.m_UpdateHeaderEvent = NetEvents:Subscribe("kPM:UpdateHeader", self, self.OnUpdateHeader)
    self.m_SetRoundEndInfoBoxEvent = NetEvents:Subscribe("kPM:SetRoundEndInfoBox", self, self.OnSetRoundEndInfoBox)
    self.m_SetGameEndEvent = NetEvents:Subscribe("kPM:SetGameEnd", self, self.OnSetGameEnd)
    self.m_ResetUIEvent = NetEvents:Subscribe("kPM:ResetUI", self, self.OnResetUI)

    self.m_BombPlantedEvent = NetEvents:Subscribe("kPM:BombPlanted", self, self.OnBombPlanted)
    self.m_BombDefusedEvent = NetEvents:Subscribe("kPM:BombDefused", self, self.OnBombDefused)
    self.m_BombKaboomEvent = NetEvents:Subscribe("kPM:BombKaboom", self, self.OnBombKaboom)

    self.m_PlaySoundPlantingEvent = NetEvents:Subscribe("kPM:PlaySoundPlanting", self, self.OnPlaySoundPlanting)

    self.m_UpdateTeamsEvent = NetEvents:Subscribe("kPM:UpdateTeams", self, self.OnUpdateTeams)

    self.m_DisablePlayerInputsEvent = NetEvents:Subscribe("kPM:DisablePlayerInputs", self, self.OnDisablePlayerInputs)
    self.m_EnablePlayerInputsEvent = NetEvents:Subscribe("kPM:EnablePlayerInputs", self, self.OnEnablePlayerInputs)

    -- Cleanup Events
    self.m_CleanupEvent = NetEvents:Subscribe("kPM:Cleanup", self, self.OnCleanup)
end

function kPMClient:OnPartitionLoaded(p_Partition)
end

function kPMClient:UnregisterEvents()
    print("unregistering events")
end

function kPMClient:OnSetSelectedTeam(p_Team)
    if p_Team == nil then
        return
    end

    local s_LocalPlayer = PlayerManager:GetLocalPlayer()
    if s_LocalPlayer == nil then
        return
    end

    if not s_LocalPlayer.alive and (self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf) then
        self.m_SpecCam:Enable()
    end

    if p_Team == 3 then -- auto-join
        local s_Attackers = PlayerManager:GetPlayersByTeam(self.m_AttackersTeamId)
        local s_Defenders = PlayerManager:GetPlayersByTeam(self.m_DefendersTeamId)

        local s_AttackersCount = 0
        for index, l_Player in pairs(s_Attackers) do
            s_AttackersCount = s_AttackersCount + 1
        end

        local s_DefendersCount = 0
        for index, l_Player in pairs(s_Defenders) do
            s_DefendersCount = s_DefendersCount + 1
        end

        if s_AttackersCount > s_DefendersCount then
            NetEvents:Send("kPM:PlayerSetSelectedTeam", self.m_DefendersTeamId)
        elseif s_AttackersCount < s_DefendersCount then
            NetEvents:Send("kPM:PlayerSetSelectedTeam", self.m_AttackersTeamId)
        else
            NetEvents:Send("kPM:PlayerSetSelectedTeam", self.m_AttackersTeamId)
        end
    elseif p_Team == 2 then -- attackers
        NetEvents:Send("kPM:PlayerSetSelectedTeam", self.m_AttackersTeamId)
    else -- defenders
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
    --self.m_PositionCommand = Console:Register("kpm_player_pos", "Displays the current player position", ClientCommands.PlayerPosition)
    --self.m_ReadyUpCommand = Console:Register("kpm_ready_up", "Toggles the ready up state", ClientCommands.ReadyUp)
    self.m_ForceReadyUpCommand = Console:Register("kpm_force_ready_up", "Toggles all players to ready up state", ClientCommands.ForceReadyUp)
end

function kPMClient:UnregisterCommands()
    print("unregistering commands")
end

function kPMClient:OnLevelDestroyed()
    -- Handle cleanup when level is destroyed
    if self.m_SpecCam ~= nil then
        self.m_SpecCam:OnLevelDestroy()
    end
end

function kPMClient:OnLevelLoaded()
    NetEvents:Send("kPM:PlayerConnected")
    WebUI:ExecuteJS("OpenCloseTeamMenu(true);")
    WebUI:ExecuteJS("RoundCount(" .. kPMConfig.MatchDefaultRounds .. ");")
end

function kPMClient:OnLevelLoadResources()
    print('OnLevelLoadResources')
    self.m_ExplosionEntityData = nil

    self.m_PlantSoundEntityData = nil
end

function kPMClient:OnUpdateInput(p_DeltaTime)
    -- Update the freecam
    if self.m_SpecCam ~= nil then
        self.m_SpecCam:OnUpdateInput(p_DeltaTime)
    end

    -- TODO: Remove me
    --[[if InputManager:WentKeyDown(InputDeviceKeys.IDK_F8) then
        NetEvents:Send("kPM:TogglePlant", "plant", "A", Vec3(-341.6533203125, 71.388473510742, 297.3525390625), true)
    end]]

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
end

function kPMClient:OnInputPreUpdate(p_Hook, p_Cache, p_DeltaTime)
    -- Validate our cache
    if p_Cache == nil then
        print("err: invalid input cache.")
        return
    end

    -- Get the local player id
    local s_Player = PlayerManager:GetLocalPlayer()

    -- Tab held or not
    self:IsTabHeld(p_Hook, p_Cache, p_DeltaTime)
    self:IsPlantingOrDefuseing(p_Hook, p_Cache, p_DeltaTime)

    -- Check to see if we are in the warmup state to get rup status
    if self.m_GameState == GameStates.Warmup then
        -- Get the interact level
        local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptInteract)
        
        -- If the player is holding the interact key then update our variables and clear it for the next frame
        if s_InteractLevel > 0.0 then
            self.m_RupHeldTime = self.m_RupHeldTime + p_DeltaTime
            p_Cache:SetLevel(InputConceptIdentifiers.ConceptInteract, 0.0)
        else
            if self.m_RupHeldReady then
                self.m_RupHeldReady = false
            end
            -- If the client isn't holding interact reset our time
            self.m_RupHeldTime = 0.0
        end

        -- Toggle the rup state
        if self.m_RupHeldTime >= kPMConfig.MaxReadyUpTime then
            if not self.m_RupHeldReady then
                NetEvents:Send("kPM:ToggleRup")
                WebUI:ExecuteJS("RupInteractProgress(" .. tostring(0) ..", " .. tostring(kPMConfig.MaxReadyUpTime) .. ");")
                self.m_RupHeldReady = true
            end
        else
            WebUI:ExecuteJS("RupInteractProgress(" .. tostring(self.m_RupHeldTime) ..", " .. tostring(kPMConfig.MaxReadyUpTime) .. ");")
        end
    end

    -- Update the freecam
    if self.m_SpecCam ~= nil then
        self.m_SpecCam:OnUpdateInputHook(p_Hook, p_Cache, p_DeltaTime)
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

    if self.m_TabHeldTime >= 3.0 then
        if l_ScoreboardActive == true then
            self:OnUpdateScoreboard(l_Player)
        end

        -- Reset our timer
        self.m_TabHeldTime = 0.0
    end

    if self.m_ScoreboardActive ~= l_ScoreboardActive then
        self.m_ScoreboardActive = l_ScoreboardActive

        if l_ScoreboardActive == true then
            self:OnUpdateScoreboard(l_Player)
        end

        WebUI:ExecuteJS("OpenCloseScoreboard(" .. string.format('%s', l_ScoreboardActive) .. ");")
    end
end

function kPMClient:IsPlantingOrDefuseing(p_Hook, p_Cache, p_DeltaTime)
    local s_SelectedPlant = self:IsPlayerInsideThePlantZone()

    local s_Player = PlayerManager:GetLocalPlayer()

    local s_PlantSent = self.m_PlantSent

    if s_SelectedPlant ~= nil and (self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf) then
        -- Get the interact level
        local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptInteract)

        -- If the player is holding the interact key then update our variables and clear it for the next frame
        if s_InteractLevel > 0.0 then
            self.m_PlantOrDefuseHeldTime = self.m_PlantOrDefuseHeldTime + p_DeltaTime
            p_Cache:SetLevel(InputConceptIdentifiers.ConceptInteract, 0.0)
            s_PlantSent = true
            self:DisablePlayerInputs()
        else
            s_PlantSent = false
            self:EnablePlayerInputs()

            -- If the client isn't holding interact reset our timer
            self.m_PlantOrDefuseHeldTime = 0.0
        end

        if s_Player == nil then
            print("err: could not get local player.")
            return
        end

        if s_PlantSent ~= self.m_PlantSent then
            self.m_PlantSent = s_PlantSent

            if s_PlantSent == true then
                NetEvents:Send("kPM:PlaySoundPlanting", s_Player.soldier.worldTransform.trans)
            end
        end

        if s_Player.teamId == self.m_AttackersTeamId then
            -- If player is attacker
            WebUI:ExecuteJS("PlantInteractProgress(" .. tostring(self.m_PlantOrDefuseHeldTime) ..", " .. tostring(kPMConfig.PlantTime) .. ", '" .. tostring("plant") .. "');")

            -- Toggle the plant state
            if self.m_PlantOrDefuseHeldTime >= kPMConfig.PlantTime then
                -- Send the plant event
                NetEvents:Send("kPM:TogglePlant", "plant", s_SelectedPlant, s_Player.soldier.worldTransform.trans)
                print("client planted")

                -- Reset our plant or defuse timer
                self.m_PlantOrDefuseHeldTime = 0.0
            end
        elseif s_Player.teamId == self.m_DefendersTeamId then
            -- If player is defender
            WebUI:ExecuteJS("PlantInteractProgress(" .. tostring(self.m_PlantOrDefuseHeldTime) ..", " .. tostring(kPMConfig.PlantTime) .. ", '" .. tostring("defuse") .. "');")

            -- Toggle the defuse state
            if self.m_PlantOrDefuseHeldTime >= kPMConfig.DefuseTime then
                -- Send the defuse event
                NetEvents:Send("kPM:TogglePlant", "defuse", s_SelectedPlant)
                print("client defused")

                -- Reset our plant or defuse timer
                self.m_PlantOrDefuseHeldTime = 0.0
            end
        end
    else 
        if self.m_PlantOrDefuseHeldTime > 0.0 and (self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf) then
            -- Re-enable inputs after planting
            WebUI:ExecuteJS("PlantInteractProgress(" .. tostring(0) ..", " .. tostring(kPMConfig.PlantTime) .. ", '" .. tostring("defuse") .. "');")
            self:EnablePlayerInputs()
            self.m_PlantOrDefuseHeldTime = 0
        end
    end
end


function kPMClient:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    -- TODO: Implement time related functionaity
end

function kPMClient:OnRupStateChanged(p_WaitingOnPlayers, p_LocalRupStatus)
    --[[if p_WaitingOnPlayers == nil then
        print("err: invalid waiting on player count.")
        return
    end

    if p_LocalRupStatus == nil then
        print("err: invalid local rup status.")
        return
    end]]

    local l_Player = PlayerManager:GetLocalPlayer()
    if l_Player ~= nil then
        self:OnUpdateScoreboard(l_Player)
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

    -- Reset the bomb plant status
    self.m_BombSite = nil
    self.m_BombLocation = nil
    self:DestroyLaptop()

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

function kPMClient:OnUpdateHeader(p_AttackerPoints, p_DefenderPoints, p_Rounds, p_BombSite)
    if p_BombSite ~= nil then
        WebUI:ExecuteJS('UpdateHeader(' .. p_AttackerPoints .. ', ' .. p_DefenderPoints .. ', ' .. (p_Rounds + 1) .. ', "' .. tostring(p_BombSite) .. '");')
    else
        WebUI:ExecuteJS('UpdateHeader(' .. p_AttackerPoints .. ', ' .. p_DefenderPoints .. ', ' .. (p_Rounds + 1) .. ');')
    end
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
    else
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
end


function kPMClient:OnResetUI()
    WebUI:ExecuteJS('ResetUI();')
end

function kPMClient:OnBombPlanted(p_BombSite, p_BombLocation)
    if p_BombSite == nil or p_BombLocation == nil then
        return
    end

    print('info: bomb has been planted on ' .. p_BombSite)

    self.m_BombSite = p_BombSite
    self.m_BombLocation = p_BombLocation
    self:PlaceLaptop()

    print('info: bomb location:')
    print(self.m_BombLocation)

    WebUI:ExecuteJS('BombPlanted("' .. p_BombSite .. '");')
end

function kPMClient:OnBombDefused()
    print('info: bomb defused')

    -- I dont think this is necessary because on gamestate change we clear out the bombsites
    self.m_BombSite = nil
    self.m_BombLocation = nil
    self:DestroyLaptop()
    --WebUI:ExecuteJS('BombDefused();')
end

function kPMClient:OnBombKaboom()
    local s_Data = self:GetExplosionEntityData()

	if s_Data == nil then
		print('Could not get explosion data')
		return
    end
    
	local s_Transform = LinearTransform()
	s_Transform.trans = self.m_BombLocation

	local s_Entity = EntityManager:CreateEntity(s_Data, s_Transform)

	if s_Entity == nil then
		print('Could not create kaboom entity.')
		return
    end 
    
	s_Entity = ExplosionEntity(s_Entity)
	s_Entity:Detonate(s_Transform, Vec3(0, 1, 0), 1.0, nil)
end

function kPMClient:GetExplosionEntityData()
   	-- Stole this from NoFaTe's battlefieldv mod
	if self.m_ExplosionEntityData ~= nil then
		return self.m_ExplosionEntityData
    end
    
	local s_Original = ResourceManager:SearchForInstanceByGuid(Guid('F2D79077-51D0-455C-8707-FDD38E9EE3D7'))

	if s_Original == nil then
		print('Could not find explosion template')
		return nil
    end
    
	self.m_ExplosionEntityData = VeniceExplosionEntityData(s_Original:Clone())
	self.m_ExplosionEntityData.innerBlastRadius = 10
	self.m_ExplosionEntityData.blastRadius = 30
	self.m_ExplosionEntityData.blastDamage = 1000
	self.m_ExplosionEntityData.blastImpulse = 1000
	self.m_ExplosionEntityData.hasStunEffect = true
	self.m_ExplosionEntityData.shockwaveRadius = 55
	self.m_ExplosionEntityData.shockwaveTime = 0.75
	self.m_ExplosionEntityData.shockwaveDamage = 10
	self.m_ExplosionEntityData.shockwaveImpulse = 200
	self.m_ExplosionEntityData.cameraShockwaveRadius = 10

	return self.m_ExplosionEntityData
end

function kPMClient:OnPlaySoundPlanting(p_Trans)
    if p_Trans == nil then
		print('No plant location')
		return
    end

    local s_Data = self:GetPlantSoundEntityData()

	if s_Data == nil then
		print('Could not get sound data')
		return
    end
    
	local s_Transform = LinearTransform()
	s_Transform.trans = p_Trans

	local s_Entity = EntityManager:CreateEntity(s_Data, s_Transform)

	if s_Entity == nil then
		print('Could not create kaboom entity.')
		return
    end

    s_Entity:FireEvent('Start')
end

function kPMClient:GetPlantSoundEntityData()
       if self.m_PlantSoundEntityData ~= nil then
		return self.m_PlantSoundEntityData
    end
    
	local s_Original = ResourceManager:SearchForInstanceByGuid(Guid('9A715038-A22A-409A-AB33-E12B4338AA6A'))

	if s_Original == nil then
		print('Could not find sound template')
		return nil
    end
    
    self.m_PlantSoundEntityData = SoundEffectEntityData(s_Original:Clone())
    
	return self.m_PlantSoundEntityData
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

    self.m_SpecCam:Disable()
end

function kPMClient:OnPlayerKilled(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end

    self:EnablePlayerInputs()

    if self.m_GameState == GameStates.FirstHalf or
        self.m_GameState == GameStates.SecondHalf
    then
        self.m_SpecCam:Enable()
    end
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
        return nil
    end

    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        return nil
    end

    -- Check to see if the player is alive
    if localPlayer.alive == false then
        return nil
    end

    -- Get the local soldier instance
    local localSoldier = localPlayer.soldier
    if localSoldier == nil then
        return nil
    end

    -- Get the soldier LinearTransform
    local soldierLinearTransform = localSoldier.worldTransform

    -- Get the position vector
    local position = soldierLinearTransform.trans

    if localPlayer.teamId == self.m_AttackersTeamId and self.m_BombSite == nil and self.m_BombLocation == nil then
        -- If the player is attacker and the bomb is not planted

        if position:Distance(MapsConfig[l_LevelName]["PLANT_A"]["POS"].trans) <= MapsConfig[l_LevelName]["PLANT_A"]["RADIUS"] then
            return "A"
        end

        if position:Distance(MapsConfig[l_LevelName]["PLANT_B"]["POS"].trans) <= MapsConfig[l_LevelName]["PLANT_B"]["RADIUS"] then
            return "B"
        end
    end

    if localPlayer.teamId == self.m_DefendersTeamId and self.m_BombSite ~= nil and self.m_BombLocation ~= nil then
        local dist = position:Distance(self.m_BombLocation)
        if dist ~= nil then
            -- If the player is defender and the bomb is planted
            if dist <= kPMConfig.BombRadius then
                -- If the a defender player is inside the defuse radius
                return self.m_BombSite
            end
        end
    end

    return nil
end

function kPMClient:OnDisablePlayerInputs()
    self:DisablePlayerInputs()
end

function kPMClient:DisablePlayerInputs()
    if self.m_PlayerInputs then
        local s_Player = PlayerManager:GetLocalPlayer()
        if s_Player ~= nil then
            s_Player:EnableInput(EntryInputActionEnum.EIAFire, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAJump, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAThrottle, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAStrafe, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAChangePose, false)
            s_Player:EnableInput(EntryInputActionEnum.EIAProne, false)
            s_Player:EnableInput(EntryInputActionEnum.EIASprint, false)
            self.m_PlayerInputs = false
        end
    end
end

function kPMClient:OnEnablePlayerInputs()
    self:EnablePlayerInputs()
end

function kPMClient:EnablePlayerInputs()
    if not self.m_PlayerInputs then
        local s_Player = PlayerManager:GetLocalPlayer()
        if s_Player ~= nil then
            s_Player:EnableInput(EntryInputActionEnum.EIAFire, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAJump, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAThrottle, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAStrafe, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAChangePose, true)
            s_Player:EnableInput(EntryInputActionEnum.EIAProne, true)
            s_Player:EnableInput(EntryInputActionEnum.EIASprint, true)
            self.m_PlayerInputs = true
        end
    end
end

function kPMClient:PlaceLaptop()
    local s_PlantBp = ResourceManager:SearchForDataContainer('Objects/Laptop_01/Laptop_01')

	if s_PlantBp == nil then
		error('err: could not find the plant blueprint.')
		return
    end
    
	local s_Params = EntityCreationParams()
	s_Params.transform.trans = self.m_BombLocation
	s_Params.networked = false

    local s_Bus = EntityManager:CreateEntitiesFromBlueprint(s_PlantBp, s_Params)

    if s_Bus ~= nil then
        for _, entity in pairs(s_Bus.entities) do
            entity:Init(Realm.Realm_Client, true)
        end

        self.m_LaptopEntity = s_Bus
    else
		error('err: could not spawn laptop.')
		return
	end
end

function kPMClient:DestroyLaptop()
    if self.m_LaptopEntity == nil then
        return
    end

    for _, entity in pairs(self.m_LaptopEntity.entities) do
        if entity ~= nil then
            entity:Destroy()
        end 
    end

    self.m_LaptopEntity = nil
end

return kPMClient()
