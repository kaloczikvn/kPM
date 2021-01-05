class "kPMShared"

require("__shared/MapsConfig")
require("__shared/LevelNameHelper")
require("__shared/WeaponModifier")
require("__shared/Generators/MapMarkerEntityDataGenerator")
require("__shared/Generators/PropertyConnectionsGenerator")

function kPMShared:__init()
    print("shared initialization")

    self.m_ExtensionLoadedEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadedEvent = Events:Subscribe("Extension:Unloaded", self, self.OnExtensionUnloaded)

    self.m_LevelName = nil

    self.m_CustomMapMarkerEntityAGuid = Guid('261E43BF-259B-41D2-BF3B-42069ASITE')
    self.m_CustomMapMarkerEntityBGuid = Guid('271E43CF-269C-42D2-CF3C-69420BSITE')

    self.m_CustomMapMarkerEntityAGenerated = nil
    self.m_CustomMapMarkerEntityBGenerated = nil

    self.m_SoldierWeaponBlueprints = { }
    self.m_BulletEntityDatas = { }
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
    if SharedUtils:GetLevelName() ~= 'Levels/MP_012/MP_012' then
        ResourceManager:MountSuperBundle('Levels/MP_012/MP_012')
    end
end

function kPMShared:UnregisterEvents()
    print("unregistering events")
end

function kPMShared:OnLevelRegisterEntityResources()
    if self.m_LevelName == nil then
        self.m_LevelName = LevelNameHelper:GetLevelName()
    end

    local s_Registry = RegistryContainer()

    local s_CustomMapMarkerEntityAData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.m_CustomMapMarkerEntityAGuid))
    if s_CustomMapMarkerEntityAData == nil then
        error('s_CustomMapMarkerEntityAData not found')
        return
    end

    local s_CustomMapMarkerEntityBData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.m_CustomMapMarkerEntityBGuid))
    if s_CustomMapMarkerEntityBData == nil then
        error('s_CustomMapMarkerEntityBData not found')
        return
    end

    s_Registry.entityRegistry:add(s_CustomMapMarkerEntityAData)
    s_Registry.entityRegistry:add(s_CustomMapMarkerEntityBData)
    ResourceManager:AddRegistry(s_Registry, ResourceCompartment.ResourceCompartment_Game)
end

function kPMShared:OnLevelLoaded(p_LevelName, p_GameMode)
    self:SpawnPlants()
    
    for i, l_Instance in pairs(self.m_SoldierWeaponBlueprints) do
        WeaponModifier:ModifyWeaponInstance(l_Instance)
    end
    self.m_SoldierWeaponBlueprints = { }

    local s_MaterialGrid = MaterialGridData(ResourceManager:SearchForDataContainer(SharedUtils:GetLevelName() .. "/MaterialGrid_Win32/Grid"))        
    for i, l_Instance in pairs(self.m_BulletEntityDatas) do
        if l_Instance.materialPair ~= nil and l_Instance.materialPair.physicsPropertyIndex ~= nil and s_MaterialGrid.materialIndexMap[l_Instance.materialPair.physicsPropertyIndex+1] ~= nil then
            MaterialRelationDamageData(MaterialInteractionGridRow(s_MaterialGrid.interactionGrid[s_MaterialGrid.materialIndexMap[l_Instance.materialPair.physicsPropertyIndex+1]+1]).items[s_MaterialGrid.materialIndexMap[65+1]+1].physicsPropertyProperties[1]):MakeWritable()
            MaterialRelationDamageData(MaterialInteractionGridRow(s_MaterialGrid.interactionGrid[s_MaterialGrid.materialIndexMap[l_Instance.materialPair.physicsPropertyIndex+1]+1]).items[s_MaterialGrid.materialIndexMap[65+1]+1].physicsPropertyProperties[1]).damageProtectionMultiplier = 3.0 -- head
        end
    end
    self.m_BulletEntityDatas = { }
end

function kPMShared:OnPartitionLoaded(p_Partition)
    if self.m_LevelName == nil then
        self.m_LevelName = LevelNameHelper:GetLevelName()
    end

    if self.m_LevelName ~= nil then
        if MapsConfig[self.m_LevelName]["EFFECTS_WORLD_PART_DATA"] ~= nil then
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
            end
        end

        if MapsConfig[self.m_LevelName]["CAMERA_ENTITY_DATA"] ~= nil then
            if p_Partition.guid == MapsConfig[self.m_LevelName]["CAMERA_ENTITY_DATA"]["PARTITION"] then
                for _, l_Instance in pairs(p_Partition.instances) do
                    if l_Instance.instanceGuid == MapsConfig[self.m_LevelName]["CAMERA_ENTITY_DATA"]["INSTANCE"] then
                        local l_CameraEntityData = CameraEntityData(l_Instance)
                        l_CameraEntityData:MakeWritable()
                        l_CameraEntityData.enabled = false
                    end
                end
            end
        end
    end

    if p_Partition.guid == Guid("3E80FB04-9283-4A39-81A1-280936590079") then
        for _, l_Instance in pairs(p_Partition.instances) do
            if l_Instance.instanceGuid == Guid("678635B2-D620-4588-BB02-CA349C657376") then
                local l_ConeOutputNodeData = ConeOutputNodeData(l_Instance)
                l_ConeOutputNodeData:MakeWritable()
                l_ConeOutputNodeData.gain = 20.0
            end
        end
    end

    if p_Partition.guid == Guid("F256E142-C9D8-4BFE-985B-3960B9E9D189") then
        for _, l_Instance in pairs(p_Partition.instances) do
            if l_Instance.instanceGuid == Guid("A988B874-7307-49F8-8D18-30A68DDBC3F3") then
                local l_VeniceFPSCameraData = VeniceFPSCameraData(l_Instance)
                l_VeniceFPSCameraData:MakeWritable()
                l_VeniceFPSCameraData.suppressionBlurAmountMultiplier = 0.0
                l_VeniceFPSCameraData.suppressionBlurSizeMultiplier = 0.0
            end
        end
    end

    for _, l_Instance in pairs(p_Partition.instances) do
        if l_Instance:Is('EntityVoiceOverInfo') then
            local l_EntityVoiceOverInfo = EntityVoiceOverInfo(l_Instance)
            l_EntityVoiceOverInfo:MakeWritable()
            l_EntityVoiceOverInfo.voiceOverType = nil
        end

        if l_Instance:Is('SoldierWeaponBlueprint') then
            local s_SoldierWeaponBlueprint = SoldierWeaponBlueprint(l_Instance)
            table.insert(self.m_SoldierWeaponBlueprints, s_SoldierWeaponBlueprint)
        end

        if l_Instance:Is('BulletEntityData') then
            local s_BulletEntityData = BulletEntityData(l_Instance)
            table.insert(self.m_BulletEntityDatas, s_BulletEntityData)
        end

        if l_Instance.instanceGuid == Guid('5FA66B8C-BE0E-3758-7DE9-533EA42F5364') then
			-- Get rid of the PreRoundEntity. We don't need preround in this gamemode.
			local bp = LogicPrefabBlueprint(l_Instance)
			bp:MakeWritable()

			for i = #bp.objects, 1, -1 do
				if bp.objects[i]:Is('PreRoundEntityData') then
					bp.objects:erase(i)
				end
			end

			for i = #bp.eventConnections, 1, -1 do
				if bp.eventConnections[i].source:Is('PreRoundEntityData') or bp.eventConnections[i].target:Is('PreRoundEntityData') then
					bp.eventConnections:erase(i)
				end
			end
		end

        if l_Instance.instanceGuid == self.m_CustomMapMarkerEntityAGuid or l_Instance.instanceGuid == self.m_CustomMapMarkerEntityBGuid then
			return
		end
    end

    if self.m_CustomMapMarkerEntityAGenerated == nil then
        self.m_CustomMapMarkerEntityAGenerated = MapMarkerEntityDataGenerator:Create(self.m_CustomMapMarkerEntityAGuid, "A")
    end

    if self.m_CustomMapMarkerEntityBGenerated == nil then
        self.m_CustomMapMarkerEntityBGenerated = MapMarkerEntityDataGenerator:Create(self.m_CustomMapMarkerEntityBGuid, "B")
    end

    p_Partition:AddInstance(self.m_CustomMapMarkerEntityAGenerated)
    p_Partition:AddInstance(self.m_CustomMapMarkerEntityBGenerated)
end

-- ==========
-- Hooks
-- ==========
function kPMShared:RegisterHooks()
    print("registering hooks")

    Hooks:Install('ResourceManager:LoadBundles', 100, function(hook, bundles, compartment)
        if #bundles == 1 and bundles[1] == SharedUtils:GetLevelName() then
            if SharedUtils:GetLevelName() == 'Levels/MP_012/MP_012' then
                bundles = {
                    bundles[1],
                    'Levels/MP_012/TutorialMP',
                }
            else
                bundles = {
                    bundles[1],
                    'Levels/MP_012/MP_012',
                    'Levels/MP_012/TutorialMP',
                }
            end
            
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
end

function kPMShared:SpawnPlantObjects(p_Trans)
    local l_PlantBp = ResourceManager:SearchForDataContainer('Props/MilitaryProps/CapturePoint_01/CapturePointComputer_01')

	if l_PlantBp == nil then
		error('err: could not find the plant blueprint.')
		return
    end
    
	local l_Params = EntityCreationParams()
	l_Params.transform = p_Trans
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

    if kPMConfig.DebugMode then
        print("SpawnIconEntities: "..p_Id)
    end

    
    if p_Id == "A" then
        s_CustomMapMarkerEntityData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.m_CustomMapMarkerEntityAGuid))
    elseif p_Id == "B" then
        s_CustomMapMarkerEntityData = MapMarkerEntityData(ResourceManager:SearchForInstanceByGuid(self.m_CustomMapMarkerEntityBGuid))
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

    --[[
    local s_PropertyConnection = PropertyConnectionsGenerator:Create(
        ResourceManager:SearchForInstanceByGuid(Guid('60425693-6BA0-412D-A565-28ACAAA5E127')),
        s_CustomMapMarkerEntityData,
        -501687874,
        -2024647575
    )

    local s_FullTdm = DataBusData(ResourceManager:SearchForInstanceByGuid(Guid('5E64B049-3FE1-8A8B-4D16-99435672C9BC')))
    s_FullTdm:MakeWritable()
    s_FullTdm.propertyConnections:add(s_PropertyConnection)
    ]]
end

return kPMShared()
