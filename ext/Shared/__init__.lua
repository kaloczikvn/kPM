class "kPMShared"

require("__shared/MapsConfig")
require("__shared/LevelNameHelper")
require("__shared/Generators/MapMarkerEntityDataGenerator")
require("__shared/Generators/SoundEntityDataGenerator")

function kPMShared:__init()
    print("shared initialization")

    self.m_ExtensionLoadedEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadedEvent = Events:Subscribe("Extension:Unloaded", self, self.OnExtensionUnloaded)

    self.m_LevelName = nil

    self.s_CustomMapMarkerEntityAGuid = Guid('261E43BF-259B-41D2-BF3B-42069ASITE')
    self.s_CustomMapMarkerEntityBGuid = Guid('271E43CF-269C-42D2-CF3C-69420BSITE')

    self.SoundPlantingGuid = Guid('271E43CF-269C-42D2-CF3C-69420BSITE')
end

function kPMShared:OnExtensionLoaded()
    -- Register all of the events
    self:RegisterEvents()

    -- Register all of the hooks
    self:RegisterHooks()
end

function kPMShared:OnExtensionUnloaded()
    self:UnregisterEvents()
    self:UnregisterHooks()
end

-- ==========
-- Events
-- ==========
function kPMShared:RegisterEvents()
    print("registering events")

    -- Level events
    self.m_LevelRegisterEntityResourcesEvent = Events:Subscribe('Level:RegisterEntityResources', self, self.OnLevelRegisterEntityResources)
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)
    self.m_PartitionLoadedEvent = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)
    self.m_LevelLoadResourcesEvent = Events:Subscribe("Level:LoadResources", self, self.OnLevelLoadResources)
end

function kPMShared:OnLevelLoadResources()
    ResourceManager:MountSuperBundle('Levels/COOP_010/COOP_010')
end

function kPMShared:UnregisterEvents()
    print("unregistering events")
end

function kPMShared:OnLevelRegisterEntityResources()
    if self.m_LevelName == nil then
        self.m_LevelName = LevelNameHelper:GetLevelName()
    end

    local s_Registry = RegistryContainer(ResourceManager:SearchForInstanceByGuid(MapsConfig[self.m_LevelName]["REGISTRY_CONTAINER"]["INSTANCE"]))

    self:AddMarkersToRegistry(s_Registry)
    -- self:AddSoundsToRegistry(s_Registry)
end

function kPMShared:AddMarkersToRegistry(p_Registry)    
    if p_Registry == nil then
        error('p_Registry not found')
        return
    end

    local s_CustomMapMarkerEntityAData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.s_CustomMapMarkerEntityAGuid))
    if s_CustomMapMarkerEntityAData == nil then
        error('s_CustomMapMarkerEntityAData not found')
        return
    end

    local s_CustomMapMarkerEntityBData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.s_CustomMapMarkerEntityBGuid))
    if s_CustomMapMarkerEntityBData == nil then
        error('s_CustomMapMarkerEntityBData not found')
        return
    end

    p_Registry:MakeWritable()
    p_Registry.entityRegistry:add(s_CustomMapMarkerEntityAData)
    p_Registry.entityRegistry:add(s_CustomMapMarkerEntityBData)
    ResourceManager:AddRegistry(p_Registry, ResourceCompartment.ResourceCompartment_Game)
end

--[[function kPMShared:AddSoundsToRegistry(p_Registry)    
    if p_Registry == nil then
        error('p_Registry not found')
        return
    end

    p_Registry:MakeWritable()

    local s_A_SoundPlantingGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.A_SoundPlantingGuid))
    local s_A_SoundPlantedGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.A_SoundPlantedGuid))
    local s_A_SoundDefusingGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.A_SoundDefusingGuid))
    local s_A_SoundDefusedgGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.A_SoundDefusedgGuid))
    p_Registry.entityRegistry:add(s_A_SoundPlantingGuid)
    p_Registry.entityRegistry:add(s_A_SoundPlantedGuid)
    p_Registry.entityRegistry:add(s_A_SoundDefusingGuid)
    p_Registry.entityRegistry:add(s_A_SoundDefusedgGuid)

    local s_B_SoundPlantingGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.B_SoundPlantingGuid))
    local s_B_SoundPlantedGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.B_SoundPlantedGuid))
    local s_B_SoundDefusingGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.B_SoundDefusingGuid))
    local s_B_SoundDefusedgGuid = SoundEntityData(ResourceManager:SearchForInstanceByGuid(kPMConfig.B_SoundDefusedgGuid))
    p_Registry.entityRegistry:add(s_B_SoundPlantingGuid)
    p_Registry.entityRegistry:add(s_B_SoundPlantedGuid)
    p_Registry.entityRegistry:add(s_B_SoundDefusingGuid)
    p_Registry.entityRegistry:add(s_B_SoundDefusedgGuid)

    ResourceManager:AddRegistry(p_Registry, ResourceCompartment.ResourceCompartment_Game)
end]]

function kPMShared:OnLevelLoaded(p_LevelName, p_GameMode)
    self:SpawnPlants()
end

function kPMShared:OnPartitionLoaded(p_Partition)
    if self.m_LevelName == nil then
        self.m_LevelName = LevelNameHelper:GetLevelName()
    end

    if self.m_LevelName ~= nil then
        if p_Partition.guid == MapsConfig[self.m_LevelName]["EFFECTS_WORLD_PART_DATA"]["PARTITION"] then
            for _, l_Instance in pairs(p_Partition.instances) do
                if l_Instance.instanceGuid == MapsConfig[self.m_LevelName]["EFFECTS_WORLD_PART_DATA"]["INSTANCE"] then
                    local l_EffectsWorldData = WorldPartData(l_Instance)
                    for _, l_Object in pairs(l_EffectsWorldData.objects) do
                        if l_Object:Is("EffectReferenceObjectData") then
                            local l_EffectReferenceObjectData = EffectReferenceObjectData(l_Object)
                            l_EffectReferenceObjectData:MakeWritable()
                            l_EffectReferenceObjectData.excluded = true
                        end
                    end
                end
            end
        elseif p_Partition.guid == MapsConfig[self.m_LevelName]["CAMERA_ENTITY_DATA"]["PARTITION"] then
            for _, l_Instance in pairs(p_Partition.instances) do
                if l_Instance.instanceGuid == MapsConfig[self.m_LevelName]["CAMERA_ENTITY_DATA"]["INSTANCE"] then
                    local l_CameraEntityData = CameraEntityData(l_Instance)
                    l_CameraEntityData:MakeWritable()
                    l_CameraEntityData.enabled = false
                end
            end
        end
    end

    for _, l_Instance in pairs(p_Partition.instances) do
        if  l_Instance.instanceGuid == self.s_CustomMapMarkerEntityAGuid or 
            l_Instance.instanceGuid == self.s_CustomMapMarkerEntityBGuid
            --[[l_Instance.instanceGuid == kPMConfig.A_SoundPlantingGuid or
            l_Instance.instanceGuid == kPMConfig.A_SoundPlantedGuid or
            l_Instance.instanceGuid == kPMConfig.A_SoundDefusingGuid or
            l_Instance.instanceGuid == kPMConfig.A_SoundDefusedgGuid or
            l_Instance.instanceGuid == kPMConfig.B_SoundPlantingGuid or
            l_Instance.instanceGuid == kPMConfig.B_SoundPlantedGuid or
            l_Instance.instanceGuid == kPMConfig.B_SoundDefusingGuid or
            l_Instance.instanceGuid == kPMConfig.B_SoundDefusedgGuid]]
        then
			return
		end
    end

    -- Markers
    local s_EntityDataA = MapMarkerEntityDataGenerator:Create(self.s_CustomMapMarkerEntityAGuid, "A")
    p_Partition:AddInstance(s_EntityDataA)
    local s_EntityDataB = MapMarkerEntityDataGenerator:Create(self.s_CustomMapMarkerEntityBGuid, "B")
    p_Partition:AddInstance(s_EntityDataB)


    --[[local s_AlarmSound = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_DICEAlarm_01")
    if s_AlarmSound ~= nil then
        -- A plant sounds
        local s_A_SoundPlanting = SoundEntityDataGenerator:Create(kPMConfig.A_SoundPlantingGuid, "A", "planting")
        p_Partition:AddInstance(s_A_SoundPlanting)

        local s_A_SoundPlanted = SoundEntityDataGenerator:Create(kPMConfig.A_SoundPlantedGuid, "A", "planted")
        p_Partition:AddInstance(s_A_SoundPlanted)

        local s_A_SoundDefusing = SoundEntityDataGenerator:Create(kPMConfig.A_SoundDefusingGuid, "A", "defusing")
        p_Partition:AddInstance(s_A_SoundDefusing)

        local s_A_SoundDefused = SoundEntityDataGenerator:Create(kPMConfig.A_SoundDefusedgGuid, "A", "defused")
        p_Partition:AddInstance(s_A_SoundDefused)

        -- B plant sounds
        local s_B_SoundPlanting = SoundEntityDataGenerator:Create(kPMConfig.B_SoundPlantingGuid, "B", "planting")
        p_Partition:AddInstance(s_B_SoundPlanting)

        local s_B_SoundPlanted = SoundEntityDataGenerator:Create(kPMConfig.B_SoundPlantedGuid, "B", "planted")
        p_Partition:AddInstance(s_B_SoundPlanted)

        local s_B_SoundDefusing = SoundEntityDataGenerator:Create(kPMConfig.B_SoundDefusingGuid, "B", "defusing")
        p_Partition:AddInstance(s_B_SoundDefusing)

        local s_B_SoundDefused = SoundEntityDataGenerator:Create(kPMConfig.B_SoundDefusedgGuid, "B", "defused")
        p_Partition:AddInstance(s_B_SoundDefused)
    end]]
end

-- ==========
-- Hooks
-- ==========
function kPMShared:RegisterHooks()
    print("registering hooks")

    Hooks:Install('ResourceManager:LoadBundles', 100, function(hook, bundles, compartment)
        if #bundles == 1 and bundles[1] == SharedUtils:GetLevelName() then
            bundles = {
                bundles[1],
                'Levels/COOP_010/COOP_010',
                'Levels/COOP_010/AB06_Parent',
            }
            
            hook:Pass(bundles, compartment)
        end
    end)
end

function kPMShared:UnregisterHooks()
    print("unregistering hooks")
end

-- ==========
-- kPM Specific functions
-- ==========
function kPMShared:SpawnPlants()
    if self.m_LevelName == nil then
        self.m_LevelName = LevelNameHelper:GetLevelName()
    end
    
    self:SpawnPlant(MapsConfig[self.m_LevelName]["PLANT_A"]["POS"], "A")
    self:SpawnPlant(MapsConfig[self.m_LevelName]["PLANT_B"]["POS"], "B")
end

function kPMShared:SpawnPlant(p_Trans, p_Id)
    self:SpawnPlantObjects(p_Trans)
    self:SpawnIconEntities(p_Trans, p_Id)
    -- self:SpawnSoundEtities(p_Trans, p_Id)
end

function kPMShared:SpawnPlantObjects(p_Trans)
    local l_PlantBp = ResourceManager:SearchForDataContainer('Props/StreetProps/SupplyAirdrop_02/SupplyAirdrop_02')

	if l_PlantBp == nil then
		error('err: could not find the plant blueprint.')
		return
    end
    
	local l_Params = EntityCreationParams()
	l_Params.transform.trans = p_Trans.trans
	l_Params.networked = false

    local l_Bus = EntityManager:CreateEntitiesFromBlueprint(l_PlantBp, l_Params)


    if l_Bus ~= nil then
        for _, entity in pairs(l_Bus.entities) do
            entity:Init(Realm.Realm_ClientAndServer, true)
        end
    else
		error('err: could not spawn plant.')
		return
	end
end

function kPMShared:SpawnIconEntities(p_Trans, p_Id)
    local s_CustomMapMarkerEntityData = nil
    if p_Id == "A" then
        s_CustomMapMarkerEntityData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.s_CustomMapMarkerEntityAGuid))
    elseif p_Id == "B" then
        s_CustomMapMarkerEntityData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.s_CustomMapMarkerEntityBGuid))
    end

    if s_CustomMapMarkerEntityData ~= nil then
        local s_EntityPos = LinearTransform()
        s_EntityPos.trans = p_Trans.trans

        local s_CreatedEntity = EntityManager:CreateEntity(s_CustomMapMarkerEntityData, s_EntityPos)

        if s_CreatedEntity ~= nil then
            s_CreatedEntity:Init(Realm.Realm_ClientAndServer, true)
        end
    else
        print('err: s_CustomMapMarkerEntityData - could not spawn icon.')
    end
end

--[[function kPMShared:SpawnSoundEtities(p_Trans, p_Id)
    local s_SoundAsset = ResourceManager:SearchForDataContainer("Sound/Levels/COOP_10_Subway/SFX/COOP_10_Subway_SFX_DICEAlarm_01")

    if s_SoundAsset ~= nil then
        local s_SoundEntityData = SoundEntityData()
        s_SoundEntityData.sound = SoundAsset(s_SoundAsset)
    
        if s_SoundEntityData ~= nil then
            local s_EntityPos = LinearTransform()
            s_EntityPos.trans = p_Trans.trans
    
            local s_CreatedEntity = EntityManager:CreateEntity(s_SoundEntityData, s_EntityPos)
    
            if s_CreatedEntity ~= nil then
                s_CreatedEntity:Init(Realm.Realm_ClientAndServer, true)
            end
        else
            print('err: s_SoundEntityData - could not spawn sound.')
        end
    else
        print('err: s_SoundAsset - could not spawn sound.')
    end
end]]

return kPMShared()
