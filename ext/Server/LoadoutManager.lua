class "LoadoutManager"

require ("__shared/kPMConfig")

function LoadoutManager:__init()
    -- Player loadouts
    self.m_PlayerLoadouts = { }
end

function LoadoutManager:OnPartitionLoaded(p_Partition)
    if p_Partition == nil then
        return
    end
end

function LoadoutManager:OnLevelDestroyed()
end

function LoadoutManager:IsKitAllowed(p_Player, p_Kit)
    -- Enable all kits with debug mode
    if kPMConfig.DebugMode then
        return true
    end

    -- Validate player
    if p_Player == nil then
        return false
    end

    local s_TeamId = p_Player.teamId
    local s_SquadId = p_Player.squadId

    -- You must be assigned a player team
    -- Spectators will be TeamNeutral I think
    if s_TeamId == TeamId.TeamNeutral then
        return false
    end

    -- TODO: Check the Kit limit
    return true
    
end

function LoadoutManager:SetPlayerLoadout(p_Player, p_Data)
    if p_Player == nil or p_Data == nil then
        return
    end

    if p_Player.teamId == TeamId.TeamNeutral then
        return
    end

    if self:IsKitAllowed(p_Data['class']) == false then
        return
    end

    -- TODO: Should fix this for performance reasons, maybe not idk... ¯\_(ツ)_/¯
    self.m_PlayerLoadouts[p_Player.id] = {
        Class = p_Data["class"],
        Weapons = {
            ResourceManager:SearchForDataContainer(p_Data["primary"]["Vext"]),
            ResourceManager:SearchForDataContainer(p_Data["secondary"]["Vext"]),
            ResourceManager:SearchForDataContainer(p_Data["tactical"]["Vext"]),
            ResourceManager:SearchForDataContainer(p_Data["lethal"]["Vext"]),
            ResourceManager:SearchForDataContainer("Weapons/Knife/U_Knife")
        },
        Attachments = {
            ResourceManager:SearchForDataContainer(p_Data["primaryAttachments"]["Sights"]["Vext"]),
            ResourceManager:SearchForDataContainer(p_Data["primaryAttachments"]["Primary"]["Vext"]),
            ResourceManager:SearchForDataContainer(p_Data["primaryAttachments"]["Secondary"]["Vext"])
        }
    }

    print("info: loadout saved for player: " .. p_Player.name)
end

function LoadoutManager:GetPlayerLoadout(p_Player)
    if p_Player == nil then
        return nil
    end

    if p_Player.teamId == TeamId.TeamNeutral then
        return nil
    end

    if self.m_PlayerLoadouts[p_Player.id] == nil then
        self:SetDefaultLoadout(p_Player)
    end

    return self.m_PlayerLoadouts[p_Player.id]
end

function LoadoutManager:SetDefaultLoadout(p_Player)
    if p_Player == nil then
        return
    end

    if p_Player.teamId == TeamId.TeamNeutral then
        return
    end

    if self:IsKitAllowed("Assault") == false then
        return
    end

    -- TODO: Should fix this for performance reasons, maybe not idk... ¯\_(ツ)_/¯
    self.m_PlayerLoadouts[p_Player.id] = {
        Class = "Assault",
        Weapons = {
            ResourceManager:SearchForDataContainer("Weapons/AK74M/U_AK74M"),
            ResourceManager:SearchForDataContainer("Weapons/Taurus44/U_Taurus44"),
            ResourceManager:SearchForDataContainer("Weapons/Gadgets/Ammobag/U_Ammobag"),
            ResourceManager:SearchForDataContainer("Weapons/M67/U_M67"),
            ResourceManager:SearchForDataContainer("Weapons/Knife/U_Knife")
        },
        Attachments = {
            ResourceManager:SearchForDataContainer("Weapons/AK74M/U_AK74M_RX_01"),
            ResourceManager:SearchForDataContainer("Weapons/AK74M/U_AK74M_Foregrip"),
            ResourceManager:SearchForDataContainer("Weapons/AK74M/U_AK74M_Flashsuppressor")
        }
    }

    print("info: loadout saved for player: " .. p_Player.name)
end

return LoadoutManager()
