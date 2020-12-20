class 'SoundEntityDataGenerator'

function SoundEntityDataGenerator:Create(p_EntityGuid, p_Site, p_Type)
    local s_EntityData = SoundEntityData(p_EntityGuid)

    local s_SoundAsset = nil

    s_SoundAsset = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_DICEAlarm_01")
    --[[if p_Type == "planting" then
        s_SoundAsset = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_DICEAlarm_01")
    elseif p_Type == "planted" then
        s_SoundAsset = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_BFSignatureExpl_01")
    elseif p_Type == "defusing" then
        s_SoundAsset = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_BombTimer_01")
    elseif p_Type == "defused" then
        s_SoundAsset = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_LowWarningTone_01")
    end]]

    if s_SoundAsset ~= nil then
        s_EntityData.sound = SoundAsset(s_SoundAsset)
        return s_EntityData
    end

    return nil
end

return SoundEntityDataGenerator()
