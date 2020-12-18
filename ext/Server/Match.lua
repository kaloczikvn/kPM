local Match = class("Match")
require ("__shared/MapsConfig")
require ("__shared/GameStates")
require ("__shared/kPMConfig")
require ("__shared/LevelNameHelper")
require ("__shared/GameTypes")
require ("__shared/Util/TableHelper")

require ("LoadoutManager")
require ("LoadoutDefinitions")

function Match:__init(p_Server, p_TeamAttackers, p_TeamDefenders, p_RoundCount, p_LoadoutManager, p_GameType)
    if p_GameType ~= GameTypes.Public then
        print("Only public gametype is supported as of now.")
        return
    end

    -- Save server reference
    self.m_Server = p_Server

    self.m_Attackers = p_TeamAttackers
    self.m_Defenders = p_TeamDefenders

    -- Number of rounds to play in total (divide by 2 for rounds per half)
    self.m_RoundCount = p_RoundCount

    -- The current round being played, starts at 1, value of 0 means invalid
    self.m_CurrentRound = 0

    -- Keep track of ready up status
    -- This uses the (PlayerId, bool) to prevent memory references
    self.m_ReadyUpPlayers = { }

    -- Last game state (so if we are going to timeout->gameplay we know which half we are in)
    self.m_CurrentState = GameStates.None
    self.m_LastState = GameStates.None

    -- State callbacks
    self.m_UpdateStates = { }
    self.m_UpdateStates[GameStates.Warmup] = self.OnWarmup
    self.m_UpdateStates[GameStates.WarmupToKnife] = self.OnWarmupToKnife
    self.m_UpdateStates[GameStates.KnifeRound] = self.OnKnifeRound
    self.m_UpdateStates[GameStates.KnifeToFirst] = self.OnKnifeToFirst
    self.m_UpdateStates[GameStates.FirstHalf] = self.OnFirstHalf
    self.m_UpdateStates[GameStates.FirstToHalf] = self.OnFirstToHalf
    self.m_UpdateStates[GameStates.HalfTime] = self.OnHalfTime
    self.m_UpdateStates[GameStates.HalfToSecond] = self.OnHalfToSecond
    self.m_UpdateStates[GameStates.SecondHalf] = self.OnSecondHalf
    self.m_UpdateStates[GameStates.Timeout] = self.OnTimeout -- TODO: FIXME
    self.m_UpdateStates[GameStates.Strat] = self.OnStrat
    --self.m_UpdateStates[GameStates.NadeTraining] = self.OnNadeTraining -- TODO: FIXME
    self.m_UpdateStates[GameStates.EndGame] = self.OnEndGame

    -- State ticks
    self.m_UpdateTicks = { }
    self.m_UpdateTicks[GameStates.None] = 0.0
    self.m_UpdateTicks[GameStates.Warmup] = 0.0
    self.m_UpdateTicks[GameStates.WarmupToKnife] = 0.0
    self.m_UpdateTicks[GameStates.KnifeRound] = 0.0
    self.m_UpdateTicks[GameStates.KnifeToFirst] = 0.0
    self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
    self.m_UpdateTicks[GameStates.FirstToHalf] = 0.0
    self.m_UpdateTicks[GameStates.HalfTime] = 0.0
    self.m_UpdateTicks[GameStates.HalfToSecond] = 0.0
    self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
    self.m_UpdateTicks[GameStates.Timeout] = 0.0
    self.m_UpdateTicks[GameStates.Strat] = 0.0
    self.m_UpdateTicks[GameStates.NadeTraining] = 0.0
    self.m_UpdateTicks[GameStates.EndGame] = 0.0

    self.m_LoadoutManager = p_LoadoutManager

    self.m_KillQueue = { }
    self.m_SpawnQueue = { }
    self.m_UpdateManagerUpdateEvent = Events:Subscribe("UpdateManager:Update", self, self.OnUpdateManagerUpdate)

    self.m_RestartQueue = false

    self.m_GameType = p_GameType

    self.m_BombSite = nil
    self.m_BombLocation = nil
    self.m_BombTime = nil

    print("init: " .. self.m_UpdateTicks[GameStates.EndGame])
end

function Match:OnUpdateManagerUpdate(p_DeltaTime, p_UpdatePass)
    if p_UpdatePass == UpdatePass.UpdatePass_PreSim then
        if not TableHelper:empty(self.m_KillQueue) then
            self:KillQueuedPlayers()
        end
        
        if not TableHelper:empty(self.m_SpawnQueue) then
            self:SpawnQueuedPlayers()
        end

        if self.m_RestartQueue then
            -- TODO: Dont show the endscreen, just restart the map or something like that!
            RCON:SendCommand('mapList.endround', {"1"})
        end
    end
end

-- ==========
-- Logic Update Callbacks
-- ==========

function Match:OnEngineUpdate(p_GameState, p_DeltaTime)
    local s_Callback = self.m_UpdateStates[p_GameState]
    if s_Callback == nil then
        return
    end

    if self.m_CurrentState ~= p_GameState then
        if kPMConfig.DebugMode then
            print("transitioning from " .. self.m_LastState .. " to " .. p_GameState)
        end
        self.m_LastState = self.m_CurrentState
    end

    self.m_CurrentState = p_GameState

    s_Callback(self, p_DeltaTime)
end

function Match:OnWarmup(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.Warmup] == 0.0 then
        self.m_Server:SetClientTimer(0)
    end

    -- Check to see if the current time is greater or equal than our max
    if self.m_UpdateTicks[GameStates.Warmup] >= kPMConfig.MaxRupTick then
        self.m_UpdateTicks[GameStates.Warmup] = 0.0

        -- Check if all players are readied up
        if self:IsAllPlayersRup() then
            -- First change the game state so we have no logic running
            self.m_Server:ChangeGameState(GameStates.None)
            --ChatManager:Yell("All players have readied up, starting knife round...", 2.0)

            -- Handle resetting all players or spawning them
            self.m_Server:ChangeGameState(GameStates.WarmupToKnife)
        end

        -- Update status to all players
        local s_Players = PlayerManager:GetPlayers()
        for l_Index, l_Player in ipairs(s_Players) do
            -- Check if this specific player is readied up
            local l_PlayerRup = self:IsPlayerRup(l_Player.id)
            
            -- Send to client to update WebUI
            NetEvents:SendTo("kPM:RupStateChanged", l_Player, self:GetPlayerNotRupCount(), l_PlayerRup)
        end
    end

    -- Add the delta time to our rup timer
    self.m_UpdateTicks[GameStates.Warmup] = self.m_UpdateTicks[GameStates.Warmup] + p_DeltaTime
end

function Match:OnWarmupToKnife(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.WarmupToKnife] == 0.0 then
        self.m_Server:SetClientTimer(kPMConfig.MaxTransititionTime)

        -- Kill all players disabling their ability to spawn
        self:KillAllPlayers(false)
    end

    -- TODO: Disable knife canned animations

    -- If we have reached the maximum time here
    if self.m_UpdateTicks[GameStates.WarmupToKnife] >= kPMConfig.MaxTransititionTime then
        self.m_UpdateTicks[GameStates.WarmupToKnife] = 0.0

        -- Tried this to remove the animated melee attack, not really working
        -- self:FireEventForSpecificEntity("ServerMeleeEntity", "DisableMeleeTarget")

        if self.m_GameType == GameTypes.Public then
            self.m_Server:ChangeGameState(GameStates.FirstHalf)
        end

        if self.m_GameType == GameTypes.Comp then
            self.m_Server:ChangeGameState(GameStates.KnifeRound)
        end
    end

    -- Update the tick
    self.m_UpdateTicks[GameStates.WarmupToKnife] = self.m_UpdateTicks[GameStates.WarmupToKnife] + p_DeltaTime
end

function Match:GetPlayerCounts()
    local s_AttackerAliveCount = 0
    local s_DefenderAliveCount = 0

    local s_AttackerTotalCount = 0
    local s_DefenderTotalCount = 0

    local s_AttackerDeadCount = 0
    local s_DefenderDeadCount = 0

    -- Get the attacker and defender team ids
    local s_AttackerId = self.m_Attackers:GetTeamId()
    local s_DefenderId = self.m_Defenders:GetTeamId()

    -- Iterate and check alive status
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate player
        if l_Player == nil then
            goto _on_knife_round_continue_
        end

        local s_Team = l_Player.teamId

        if not l_Player.alive then
            if s_Team == s_AttackerId then
                s_AttackerDeadCount = s_AttackerDeadCount + 1
            elseif s_Team == s_DefenderId then
                s_DefenderDeadCount = s_DefenderDeadCount + 1
            end
        else
            if s_Team == s_AttackerId then
                s_AttackerAliveCount = s_AttackerAliveCount + 1
            elseif s_Team == s_DefenderId then
                s_DefenderAliveCount = s_DefenderAliveCount + 1
            end
        end

        if s_Team == s_AttackerId then
            s_AttackerTotalCount = s_AttackerTotalCount + 1
        elseif s_Team == s_DefenderId then
            s_DefenderTotalCount = s_DefenderTotalCount + 1
        end
        ::_on_knife_round_continue_::
    end

    return s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount
end

function Match:OnKnifeRound(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.KnifeRound] == 0.0 then
        self:SpawnAllPlayers(true)
        self.m_Server:SetClientTimer(kPMConfig.MaxKnifeRoundTime)
    end

    if TableHelper:empty(self.m_SpawnQueue) then
        if self.m_Attackers == nil then
            print("could not find attackers")
            return
        end

        if self.m_Defenders == nil then
            print("could not find defenders")
            return
        end

        local s_AttackerId = self.m_Attackers:GetTeamId()
        local s_DefenderId = self.m_Defenders:GetTeamId()

        local s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount = self:GetPlayerCounts()

        -- Check the round state
        local s_Winner = TeamId.TeamNeutral
        if s_AttackerTotalCount > 0 and s_AttackerAliveCount == 0 then
            -- If all attackers have been eliminated
            s_Winner = s_DefenderId
        elseif s_DefenderTotalCount > 0 and s_DefenderAliveCount == 0 then
            -- All defenders have been eliminated
            s_Winner = s_AttackerId
        end

        if s_Winner ~= TeamId.TeamNeutral then
            self.m_Server:ChangeGameState(GameStates.KnifeToFirst)
            self.m_Server:SetRoundEndInfoBox(s_Winner)
            return
        end

        -- Check to see if we have triggered a round end
        if self.m_UpdateTicks[GameStates.KnifeRound] >= kPMConfig.MaxKnifeRoundTime then
            self.m_UpdateTicks[GameStates.KnifeRound] = 0.0

            -- Trigger
            if s_Winner == TeamId.TeamNeutral then
                print("no team won? this is probably an error")
                return
            end

            -- Change the game state to the first half
            self.m_Server:ChangeGameState(GameStates.KnifeToFirst)
            return
        end
    end

    self.m_UpdateTicks[GameStates.KnifeRound] = self.m_UpdateTicks[GameStates.KnifeRound] + p_DeltaTime
end

function Match:OnKnifeToFirst(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.KnifeToFirst] == 0.0 then
        self.m_Server:SetClientTimer(kPMConfig.MaxTransititionTime)

        -- Kill all players before the first round
        self:KillAllPlayers(false)
    end

    if self.m_UpdateTicks[GameStates.KnifeToFirst] > kPMConfig.MaxTransititionTime then
        self.m_UpdateTicks[GameStates.KnifeToFirst] = 0.0

        -- Tried this to remove the animated melee attack
        -- self:FireEventForSpecificEntity("ServerMeleeEntity", "EnableMeleeTarget")

        self.m_Server:ChangeGameState(GameStates.FirstHalf)
        return
    end

    self.m_UpdateTicks[GameStates.KnifeToFirst] = self.m_UpdateTicks[GameStates.KnifeToFirst] + p_DeltaTime
end

-- Shamelessly stolen and modified from https://github.com/BF3RM

function Match:SwitchTeams()
    -- Save and swap the attackers and defenders
    local s_OldAttackers = self.m_Attackers
    local s_OldDefenders = self.m_Defenders

    self.m_Attackers = s_OldDefenders
    self.m_Defenders = s_OldAttackers

    NetEvents:Broadcast("kPM:UpdateTeams", self.m_Attackers:GetTeamId(), self.m_Defenders:GetTeamId())

    print("switched teams")
end

function Match:OnFirstHalf(p_DeltaTime)
    -- Handle the case of when a round first starts, otherwise it will run "normal" code
    if self.m_UpdateTicks[GameStates.FirstHalf] == 0.0 then
        -- Switch to strat time for 5 seconds

        -- Kill all players
        self:KillAllPlayers(false)

        -- Respawn all players
        self:SpawnAllPlayers(false)

        self.m_BombSite = nil
        self.m_BombLocation = nil
        self.m_BombTime = nil
        
        NetEvents:Broadcast("kPM:UpdateHeader", self.m_Attackers:CountRoundWon(), self.m_Defenders:CountRoundWon(), self.m_CurrentRound)

        -- Manually update the ticks
        self.m_UpdateTicks[GameStates.FirstHalf] = self.m_UpdateTicks[GameStates.FirstHalf] + p_DeltaTime

        -- Switch to strat time, do not touch the FirstHalf timer, this ensures that we pick up "normal" round
        self.m_Server:ChangeGameState(GameStates.Strat)
    end

    -- TODO: FIXME
    -- When start ends we need to update the UI's timer. Its kinda hacky now, needs a better solution
    if self.m_UpdateTicks[GameStates.FirstHalf] >= 0.5 and self.m_UpdateTicks[GameStates.FirstHalf] <= 2.0 then
        self.m_Server:SetClientTimer(kPMConfig.MaxRoundTime)
    end

    if TableHelper:empty(self.m_SpawnQueue) then
        -- Get the player counts
        local s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount = self:GetPlayerCounts()

        -- The round is running as expected, check the ending conditions

        -- Which are if all attackers are dead
        if s_AttackerAliveCount == 0 and self.m_BombSite == nil and self.m_BombLocation == nil and self.m_BombTime == nil then
            print("all attackers are dead and the bomb is not planted, round is over")
            -- Give a round to the defenders
            self.m_Defenders:RoundWon(self.m_CurrentRound)

            -- Give a loss to the attackers
            self.m_Attackers:RoundLoss(self.m_CurrentRound)

            -- Update the round count
            self.m_CurrentRound = self.m_CurrentRound + 1

            self.m_Server:SetRoundEndInfoBox(self.m_Defenders:GetTeamId())

            self:IsRoundHalfTime()

            -- Set this round to be over
            self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
            return
        end
        
        -- TODO: If the objectives have been completed

        -- If all defenders are dead
        if s_DefenderAliveCount == 0 then
            print("all defenders are dead, round is over")

            -- Give a loss to the defenders
            self.m_Defenders:RoundLoss(self.m_CurrentRound)

            -- Give a win to the attackers
            self.m_Attackers:RoundWon(self.m_CurrentRound)

            -- Update the round count
            self.m_CurrentRound = self.m_CurrentRound + 1

            self.m_Server:SetRoundEndInfoBox(self.m_Attackers:GetTeamId())

            self:IsRoundHalfTime()

            -- Set this round to be over
            self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
            return
        end

        -- If the round is over
        if self.m_BombSite == nil and self.m_BombLocation == nil and self.m_BombTime == nil then
            if self.m_UpdateTicks[GameStates.FirstHalf] >= kPMConfig.MaxRoundTime then
                -- If the defenders have any players alive, they win, simple
                if s_DefenderAliveCount > 0 then
                    self.m_Defenders:RoundWon(self.m_CurrentRound)
                    self.m_Attackers:RoundLoss(self.m_CurrentRound)

                    self.m_Server:SetRoundEndInfoBox(self.m_Defenders:GetTeamId())
                else
                    self.m_Attackers:RoundWon(self.m_CurrentRound)
                    self.m_Defenders:RoundLoss(self.m_CurrentRound)

                    self.m_Server:SetRoundEndInfoBox(self.m_Attackers:GetTeamId())
                end

                -- Update the round count
                self.m_CurrentRound = self.m_CurrentRound + 1

                self:IsRoundHalfTime()

                -- Leave the timer at 0.0 in the same state, it will catch at the top
                -- of this function and enable strat mode
                self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
                return
            end
        else
            if self.m_UpdateTicks[GameStates.FirstHalf] >= self.m_BombTime then
                self.m_Attackers:RoundWon(self.m_CurrentRound)
                self.m_Defenders:RoundLoss(self.m_CurrentRound)
                self.m_Server:SetRoundEndInfoBox(self.m_Attackers:GetTeamId())
    
                -- Update the round count
                self.m_CurrentRound = self.m_CurrentRound + 1
    
                self:IsRoundHalfTime()
    
                -- Leave the timer at 0.0 in the same state, it will catch at the top
                -- of this function and enable strat mode
                self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
                return
            end
        end
    end

    -- Update the tick
    self.m_UpdateTicks[GameStates.FirstHalf] = self.m_UpdateTicks[GameStates.FirstHalf] + p_DeltaTime
end

function Match:IsRoundHalfTime()
    if self.m_CurrentRound >= (self.m_RoundCount / 2) then
        self.m_Server:ChangeGameState(GameStates.FirstToHalf)
    end
end

function Match:OnFirstToHalf(p_DeltaTime)
    self:KillAllPlayers(false)
    self.m_Server:ChangeGameState(GameStates.HalfTime)
end

function Match:OnHalfTime(p_DeltaTime)
    self:SwitchTeams()
    self.m_Server:ChangeGameState(GameStates.HalfToSecond)
end

function Match:OnHalfToSecond(p_DeltaTime)
    self.m_Server:ChangeGameState(GameStates.SecondHalf)
end

function Match:OnSecondHalf(p_DeltaTime)
    -- Handle the case of when a round first starts, otherwise it will run "normal" code
    if self.m_UpdateTicks[GameStates.SecondHalf] == 0.0 then
        -- Switch to strat time for 5 seconds

        -- Kill all players
        self:KillAllPlayers(false)

        -- Respawn all players
        self:SpawnAllPlayers(false)

        self.m_BombSite = nil
        self.m_BombLocation = nil
        self.m_BombTime = nil
        
        NetEvents:Broadcast("kPM:UpdateHeader", self.m_Attackers:CountRoundWon(), self.m_Defenders:CountRoundWon(), self.m_CurrentRound, "nil")

        -- Manually update the ticks
        self.m_UpdateTicks[GameStates.SecondHalf] = self.m_UpdateTicks[GameStates.SecondHalf] + p_DeltaTime

        -- Switch to strat time, do not touch the SecondHalf timer, this ensures that we pick up "normal" round
        self.m_Server:ChangeGameState(GameStates.Strat)
    end

    -- TODO: FIXME
    -- When start ends we need to update the UI's timer. Its kinda hacky now, needs a better solution
    if self.m_UpdateTicks[GameStates.SecondHalf] >= 0.5 and self.m_UpdateTicks[GameStates.SecondHalf] <= 2.0 then
        self.m_Server:SetClientTimer(kPMConfig.MaxRoundTime)
    end

    if TableHelper:empty(self.m_SpawnQueue) then
        -- Get the player counts
        local s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount = self:GetPlayerCounts()

        -- The round is running as expected, check the ending conditions

        -- Which are if all attackers are dead
        if s_AttackerAliveCount == 0 and self.m_BombSite == nil and self.m_BombLocation == nil and self.m_BombTime == nil then
            print("all attackers are dead and the bomb is not planted, round is over")

            -- Give a round to the defenders
            self.m_Defenders:RoundWon(self.m_CurrentRound)

            -- Give a loss to the attackers
            self.m_Attackers:RoundLoss(self.m_CurrentRound)

            -- Update the round count
            self.m_CurrentRound = self.m_CurrentRound + 1

            self.m_Server:SetRoundEndInfoBox(self.m_Defenders:GetTeamId())

            self:IsAnyTeamWon()

            -- Set this round to be over
            self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
            return
        end
        
        -- TODO: If the objectives have been completed

        -- If all defenders are dead
        if s_DefenderAliveCount == 0 then
            print("all defenders are dead, round is over")

            -- Give a loss to the defenders
            self.m_Defenders:RoundLoss(self.m_CurrentRound)

            -- Give a win to the attackers
            self.m_Attackers:RoundWon(self.m_CurrentRound)

            -- Update the round count
            self.m_CurrentRound = self.m_CurrentRound + 1

            self.m_Server:SetRoundEndInfoBox(self.m_Attackers:GetTeamId())

            self:IsAnyTeamWon()

            -- Set this round to be over
            self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
            return
        end

        -- If the round is over
        if self.m_BombSite == nil and self.m_BombLocation == nil and self.m_BombTime == nil then
            if self.m_UpdateTicks[GameStates.SecondHalf] >= kPMConfig.MaxRoundTime then
                -- If the defenders have any players alive, they win, simple
                if s_DefenderAliveCount > 0 then
                    self.m_Defenders:RoundWon(self.m_CurrentRound)
                    self.m_Attackers:RoundLoss(self.m_CurrentRound)
    
                    self.m_Server:SetRoundEndInfoBox(self.m_Defenders:GetTeamId())
                else
                    self.m_Attackers:RoundWon(self.m_CurrentRound)
                    self.m_Defenders:RoundLoss(self.m_CurrentRound)
    
                    self.m_Server:SetRoundEndInfoBox(self.m_Attackers:GetTeamId())
                end
    
                -- Update the round count
                self.m_CurrentRound = self.m_CurrentRound + 1
    
                self:IsAnyTeamWon()
    
                -- Leave the timer at 0.0 in the same state, it will catch at the top
                -- of this function and enable strat mode
                self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
                return
            end
        else
            if self.m_UpdateTicks[GameStates.SecondHalf] >= self.m_BombTime then
                self.m_Attackers:RoundWon(self.m_CurrentRound)
                self.m_Defenders:RoundLoss(self.m_CurrentRound)
                self.m_Server:SetRoundEndInfoBox(self.m_Attackers:GetTeamId())
    
                -- Update the round count
                self.m_CurrentRound = self.m_CurrentRound + 1
    
                self:IsAnyTeamWon()
    
                -- Leave the timer at 0.0 in the same state, it will catch at the top
                -- of this function and enable strat mode
                self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
                return
            end
        end
    end

    -- Update the tick
    self.m_UpdateTicks[GameStates.SecondHalf] = self.m_UpdateTicks[GameStates.SecondHalf] + p_DeltaTime
end

function Match:IsAnyTeamWon()
    if self.m_Attackers:CountRoundWon() >= (self.m_RoundCount / 2 + 1) or 
        self.m_Defenders:CountRoundWon() >= (self.m_RoundCount / 2 + 1) then
        NetEvents:Broadcast("kPM:UpdateHeader", self.m_Attackers:CountRoundWon(), self.m_Defenders:CountRoundWon(), self.m_CurrentRound, "nil")
        self.m_Server:ChangeGameState(GameStates.EndGame)
        return
    end

    if self.m_CurrentRound >= self.m_RoundCount then
        NetEvents:Broadcast("kPM:UpdateHeader", self.m_Attackers:CountRoundWon(), self.m_Defenders:CountRoundWon(), self.m_CurrentRound, "nil")
        self.m_Server:ChangeGameState(GameStates.EndGame)
        return
    end
end

function Match:OnEndGame(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.EndGame] == 0.0 then
        if self.m_Attackers:CountRoundWon() == self.m_Defenders:CountRoundWon() then
            print('Game end: Draw')
            self.m_Server:SetGameEnd(nil)
        else
            if self.m_Attackers:CountRoundWon() > self.m_Defenders:CountRoundWon() then
                print('Game end: Attackers win')
                self.m_Server:SetGameEnd(self.m_Attackers:GetTeamId())
            else
                print('Game end: Defenders win')
                self.m_Server:SetGameEnd(self.m_Defenders:GetTeamId())
            end
        end

        self.m_Server:SetClientTimer(kPMConfig.MaxEndgameTime)
    end

    if self.m_UpdateTicks[GameStates.EndGame] >= kPMConfig.MaxEndgameTime then
        -- Set the restart queue so we can trigger an rcon restart or something like that
        self.m_RestartQueue = true
    end

    self.m_UpdateTicks[GameStates.EndGame] = self.m_UpdateTicks[GameStates.EndGame] + p_DeltaTime
end

function Match:OnTimeout(p_DeltaTime)
end

function Match:OnStrat(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.Strat] == 0.0 then
        self.m_Server:SetClientTimer(kPMConfig.MaxStratTime)
    end

    if self.m_UpdateTicks[GameStates.Strat] >= kPMConfig.MaxStratTime then
        self.m_UpdateTicks[GameStates.Strat] = 0.0

        -- One more cleanup, they can respawn and change / drop kits... dont leave those kits on the floor
        self:Cleanup();

        -- Check the previous state
        local s_LastState = self.m_LastState
        if s_LastState ~= GameStates.KnifeToFirst and s_LastState ~= GameStates.HalfToSecond and s_LastState ~= GameStates.FirstHalf and s_LastState ~= GameStates.SecondHalf then
            print("ERROR coming from invalid state: " .. s_LastState)
            return
        end

        self:EnablePlayerInputs()
        self.m_Server:ChangeGameState(s_LastState)
        return
    else
        -- Maybe overkill to set it every tick, but remember, players can respawn or rejoin when Start
        self:DisablePlayerInputs()
    end

    -- Update the strat tick counter
    self.m_UpdateTicks[GameStates.Strat] = self.m_UpdateTicks[GameStates.Strat] + p_DeltaTime
end

function Match:DisablePlayerInputs()
    --[[local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        l_Player:EnableInput(EntryInputActionEnum.EIAFire, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAJump, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAThrottle, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAStrafe, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAChangePose, false)
        l_Player:EnableInput(EntryInputActionEnum.EIAProne, false)
    end]]
    NetEvents:Broadcast("kPM:DisablePlayerInputs")
end

function Match:EnablePlayerInputs()
    --[[local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        l_Player:EnableInput(EntryInputActionEnum.EIAFire, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAJump, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAThrowGrenade, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAThrottle, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAStrafe, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAMeleeAttack, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAChangePose, true)
        l_Player:EnableInput(EntryInputActionEnum.EIAProne, true)
    end]]
    NetEvents:Broadcast("kPM:EnablePlayerInputs")
end

function Match:ClearReadyUpState()
    -- Clear out all ready up state entries
    self.m_ReadyUpPlayers = { }
end

function Match:OnTogglePlant(p_Player, p_PlantOrDefuse, p_BombSite, p_BombLocation, p_Force)
    if p_PlantOrDefuse == "plant" then
        if p_Player.teamId ~= self.m_Attackers:GetTeamId() then
            if p_Force == nil then
                return
            end
        end

        if p_BombSite == nil or p_BombLocation == nil then
            return
        end 

        if self.m_BombSite ~= nil or self.m_BombLocation ~= nil then
            -- If the bomb already planted return
            return
        end

        self.m_BombSite = p_BombSite
        self.m_BombLocation = p_BombLocation
        if self.m_CurrentState == GameStates.FirstHalf then
            self.m_BombTime = self.m_UpdateTicks[GameStates.FirstHalf] + kPMConfig.BombTime
        elseif self.m_CurrentState == GameStates.SecondHalf then
            self.m_BombTime = self.m_UpdateTicks[GameStates.SecondHalf] + kPMConfig.BombTime
        end

        print('info: bomb has been planted on ' .. p_BombSite)

        NetEvents:Broadcast("kPM:UpdateHeader", self.m_Attackers:CountRoundWon(), self.m_Defenders:CountRoundWon(), self.m_CurrentRound, p_BombSite)

        -- Notify players that the bomb has been planted and start the timer
        self.m_Server:SetClientTimer(kPMConfig.BombTime)
        NetEvents:Broadcast('kPM:BombPlanted', p_BombSite, p_BombLocation)
    elseif p_PlantOrDefuse == "defuse" then
        if p_Player.teamId ~= self.m_Defenders:GetTeamId() then
            return
        end

        if self.m_BombSite == nil or self.m_BombLocation == nil then
            return
        end

        print('info: bomb has been defused')

        -- Notify players that the bomb has been defused and end the round
        NetEvents:Broadcast('kPM:BombDefused')

        self.m_Defenders:RoundWon(self.m_CurrentRound)
        self.m_Attackers:RoundLoss(self.m_CurrentRound)
        self.m_CurrentRound = self.m_CurrentRound + 1
        self.m_Server:SetRoundEndInfoBox(self.m_Defenders:GetTeamId())

        if self.m_CurrentState == GameStates.FirstHalf then
            self:IsRoundHalfTime()
            self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
        elseif self.m_CurrentState == GameStates.SecondHalf then
            self:IsAnyTeamWon()
            self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
        end
    end
end

function Match:OnPlayerRup(p_Player)
    if p_Player == nil then
        print("err: invalid player tried to rup.")
        return
    end

    -- Get the player id
    local s_PlayerId = p_Player.id

    -- Player does not exist in our ready up state yet
    if self.m_ReadyUpPlayers[s_PlayerId] == nil then
        self.m_ReadyUpPlayers[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        NetEvents:Broadcast('Player:ReadyUpPlayers', self.m_ReadyUpPlayers)
        return
    end

    -- Player has already been added, but has not readied up yet
    if self.m_ReadyUpPlayers[s_PlayerId] == false then
        self.m_ReadyUpPlayers[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        NetEvents:Broadcast('Player:ReadyUpPlayers', self.m_ReadyUpPlayers)
        return
    end

    -- If the player was previously readied and now is unready
    if self.m_ReadyUpPlayers[s_PlayerId] == true then
        self.m_ReadyUpPlayers[s_PlayerId] = false
        print("info: player " .. p_Player.name .. " unready up :(")
        NetEvents:Broadcast('Player:ReadyUpPlayers', self.m_ReadyUpPlayers)
        return
    end
end

function Match:ForceAllPlayerRup()
    for index, l_Player in pairs(PlayerManager:GetPlayers()) do
		self.m_ReadyUpPlayers[l_Player.id] = true
    end
end

function Match:IsAllPlayersRup()
    -- Get the player count
    local s_TotalPlayerCount = PlayerManager:GetPlayerCount()

    -- Check to make sure that we have enough players to start
    if s_TotalPlayerCount < kPMConfig.MinPlayerCount then
        return false
    end

    -- Get all players in the server
    local s_Players = PlayerManager:GetPlayers()

    -- Iterate over all players and check the rup state
    for l_Index, l_Player in ipairs(s_Players) do
        -- Check that the player is valid
        if l_Player == nil then
            print("err: invalid player in player manager.")
            return false
        end

        -- Get the player id
        local l_PlayerId = l_Player.id

        -- Check to see if this player has *any* rup state
        if self.m_ReadyUpPlayers[l_PlayerId] == nil then
            return false
        end

        -- Is this player not readied up
        if self.m_ReadyUpPlayers[l_PlayerId] == false then
            return false
        end
    end

    -- All conditions passed, all players are readied up
    return true
end

function Match:IsPlayerRup(p_PlayerId)
    local s_PlayerId = p_PlayerId

     -- Player does not exist in our ready up state yet
    if self.m_ReadyUpPlayers[s_PlayerId] == nil then
        return false
    end

    -- Player has already been added, but has not readied up yet
    return self.m_ReadyUpPlayers[s_PlayerId] == true
end

function Match:GetPlayerNotRupCount()
    local l_Count = 0;
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Check that the player is valid
        if l_Player == nil then
            print("err: invalid player in player manager.")
            return 0
        end

        local l_PlayerId = l_Player.id

        if self.m_ReadyUpPlayers[l_PlayerId] == nil or self.m_ReadyUpPlayers[l_PlayerId] == false then
            l_Count = l_Count + 1
        end
    end

    return l_Count
end

function Match:KillAllPlayers(p_IsAllowedToSpawn)
    -- Kill all alive players
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate our player
        if l_Player == nil then
            goto _knife_continue_
        end

        -- Kill the player
        self:KillPlayer(l_Player, p_IsAllowedToSpawn)

        ::_knife_continue_::
    end
end

function Match:KillPlayer(p_Player, p_IsAllowedToSpawn)
    if p_Player == nil then
        return
    end

    -- Disable players ability to spawn
    p_Player.isAllowedToSpawn = p_IsAllowedToSpawn

    -- If the player is not alive skip on
    if not p_Player.alive then
        return
    end

    if TableHelper:contains(self.m_KillQueue, p_Player.name) then
        -- Player is already in the kill queue
        return
    end

    self:AddPlayerToKillQueue(p_Player.name)
end

function Match:KillQueuedPlayers()
    for l_Index, l_PlayerName in ipairs(self.m_KillQueue) do
        print('KillQueuedPlayer: ' .. l_PlayerName)
        RCON:SendCommand('admin.killPlayer', {l_PlayerName})
        table.remove(self.m_KillQueue, l_Index)
    end
end

function Match:SpawnQueuedPlayers()
    for l_Index, l_Spawn in ipairs(self.m_SpawnQueue) do
        if not TableHelper:contains(self.m_KillQueue, l_Spawn["p_Player"].name) then
            print('SpawnQueuedPlayer: ' .. l_Spawn["p_Player"].name)
            self:SpawnPlayer(
                l_Spawn["p_Player"],
                l_Spawn["p_Transform"],
                l_Spawn["p_Pose"],
                l_Spawn["p_SoldierBp"],
                l_Spawn["p_KnifeOnly"],
                l_Spawn["p_SelectedKit"]
            )
            table.remove(self.m_SpawnQueue, l_Index)
        end
    end
end

function Match:SpawnAllPlayers(p_KnifeOnly)
    if p_KnifeOnly == nil then
        p_KnifeOnly = false
    end

    self:Cleanup();

    local s_SoldierBlueprint = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate our player
        if l_Player == nil then
            goto _knife_continue_
        end

        self:AddPlayerToSpawnQueue(
            l_Player, 
            self:GetRandomSpawnpoint(l_Player), 
            CharacterPoseType.CharacterPoseType_Stand, 
            s_SoldierBlueprint, 
            p_KnifeOnly,
            self.m_LoadoutManager:GetPlayerLoadout(l_Player)
        )

        ::_knife_continue_::
    end
end

function Match:AddPlayerToSpawnQueue(p_Player, p_Transform, p_Pose, p_SoldierBp, p_KnifeOnly, p_SelectedKit)
    print('AddPlayerToSpawnQueue: ' .. p_Player.name)
    table.insert(self.m_SpawnQueue, {
        ["p_Player"] = p_Player,
        ["p_Transform"] = p_Transform,
        ["p_Pose"] = p_Pose,
        ["p_SoldierBp"] = p_SoldierBp,
        ["p_KnifeOnly"] = p_KnifeOnly,
        ["p_SelectedKit"] = p_SelectedKit,
    })
end

function Match:AddPlayerToKillQueue(p_PlayerName)
    print('AddPlayerToKillQueue: ' .. p_PlayerName)
    table.insert(self.m_KillQueue, p_PlayerName)
end

function Match:SpawnPlayer(p_Player, p_Transform, p_Pose, p_SoldierBp, p_KnifeOnly, p_SelectedKit)
    if p_Player == nil then
        return
    end

    if p_Player.alive then
        return
    end

    if p_SelectedKit == nil then
        return
    end

    local l_SoldierAsset = nil
    local l_Appearance = nil
    if p_Player.teamId == self.m_Defenders:GetTeamId() then
        -- US
        l_SoldierAsset = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["DEFENDER"]["KIT"])
        l_Appearance = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["DEFENDER"]["APPEARANCE"])
    else
        -- RUS
        l_SoldierAsset = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["ATTACKER"]["KIT"])
        l_Appearance = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["ATTACKER"]["APPEARANCE"])
    end

    if l_SoldierAsset == nil or l_Appearance == nil then
        return
    end

    if p_KnifeOnly then
        local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')
        p_Player:SelectWeapon(WeaponSlot.WeaponSlot_0, knife, {})
    else
        local l_Loadout = p_SelectedKit.Weapons
        if l_Loadout == nil then
            print("err: something is really wrong here, spawn with a knife then...")
            local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')
            p_Player:SelectWeapon(WeaponSlot.WeaponSlot_0, knife, {})
        end

        local l_WeaponIndex = 0;
        for l_Index, l_LoadoutItem in ipairs(l_Loadout) do
            if l_LoadoutItem == nil then
                goto _weapon_continue_
            end

            local l_Attachments = {}
            if l_WeaponIndex == 0 then
                l_Attachments = p_SelectedKit.Attachments
            end

            p_Player:SelectWeapon(l_WeaponIndex, l_LoadoutItem, l_Attachments)
    
            l_WeaponIndex = l_WeaponIndex + 1;

            ::_weapon_continue_::
        end
    end
    
    p_Player:SelectUnlockAssets(l_SoldierAsset, { l_Appearance })

    local l_SpawnedSoldier = p_Player:CreateSoldier(p_SoldierBp, p_Transform)
    
	p_Player:SpawnSoldierAt(l_SpawnedSoldier, p_Transform, p_Pose)
	p_Player:AttachSoldier(l_SpawnedSoldier)

    return l_SpawnedSoldier
end

function Match:GetRandomSpawnpoint(p_Player)
    if p_Player == nil then
        print("err: no player?")
        return
    end

    local l_LevelName = LevelNameHelper:GetLevelName()
    if l_LevelName == nil then
        print("err: no level??")
        return
    end

    -- TODO: Don't spawn on an already taken spawnpoint
    
    local l_SpawnTrans = nil;

    if p_Player.teamId == self.m_Defenders:GetTeamId() then
        l_SpawnTrans = MapsConfig[l_LevelName]["DEF_SPAWNS"][ math.random( #MapsConfig[l_LevelName]["DEF_SPAWNS"] ) ]
    else
        l_SpawnTrans = MapsConfig[l_LevelName]["ATK_SPAWNS"][  math.random( #MapsConfig[l_LevelName]["ATK_SPAWNS"] ) ]
    end

    if l_SpawnTrans == nil then
        return
    end

    return l_SpawnTrans
end

function Match:Cleanup()
    self:CleanupSpecificEntity("ServerPickupEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientPickupEntity")

    self:CleanupSpecificEntity("ServerMedicBagEntity")
    self:CleanupSpecificEntity("ServerMedicBagHealingSphereEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientMedicBagEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientMedicBagHealingSphereEntity")

    self:CleanupSpecificEntity("ServerSupplySphereEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientSupplySphereEntity")

    self:CleanupSpecificEntity("ServerExplosionEntity")
    self:CleanupSpecificEntity("ServerExplosionPackEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientExplosionEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientExplosionPackEntity")

    self:CleanupSpecificEntity("ServerGrenadeEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientGrenadeEntity")
end

function Match:CleanupSpecificEntity(p_EntityType)
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

function Match:FireEventForSpecificEntity(p_EntityType, p_EventString)
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
            l_Entity:FireEvent(p_EventString)
        end
    end
end

return Match
