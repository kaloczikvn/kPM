class "kPMShared"

require("__shared/MapsConfig")
require ("__shared/LevelNameHelper")

function kPMShared:__init()
    print("shared initialization")

    self.m_ExtensionLoadedEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadedEvent = Events:Subscribe("Extension:Unloaded", self, self.OnExtensionUnloaded)

    self.m_LevelName = nil
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
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)
    self.m_PartitionLoaded = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)

    Events:Subscribe('Level:LoadResources', function()
        ResourceManager:MountSuperBundle('Levels/COOP_010/COOP_010')
    end)
end

function kPMShared:UnregisterEvents()
    print("unregistering events")
end

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
    --self:SpawnIconEntities(p_Trans)
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

function kPMShared:SpawnIconEntities(p_Trans)
    local s_EntityPos = LinearTransform()
    s_EntityPos.trans = p_Trans.trans
    
    local s_EntityData = MapMarkerEntityData()
    s_EntityData.baseTransform = Vec3(0, 0, 0)
    s_EntityData.progressMinTime = 15.0
    s_EntityData.sid = ""
    s_EntityData.nrOfPassengers = 0
    s_EntityData.nrOfEntries = 0
    s_EntityData.progressTime1Player = 0.0
    s_EntityData.showRadius = 0.0
    s_EntityData.hideRadius = 0.0
    s_EntityData.blinkTime = 5.0
    s_EntityData.markerType = MapMarkerType.MMTMissionObjective
    s_EntityData.visibleForTeam = TeamId.TeamNeutral
    s_EntityData.ownerTeam = TeamId.TeamNeutral
    s_EntityData.hudIcon = UIHudIcon.UIHudIcon_ObjectiveGeneral
    s_EntityData.verticalOffset = 0.0
    s_EntityData.focusPointRadius = 80.0
    s_EntityData.instantFlagReturnRadius = 0.0
    s_EntityData.progress = 0.0
    s_EntityData.progressPlayerSpeedUpPercentage = 10.0
    s_EntityData.trackedPlayersInRange = 0
    s_EntityData.trackingPlayerRange = 10.0
    s_EntityData.progressTime = 80.0
    s_EntityData.onlyShowSnapped = false
    s_EntityData.flagControlMarker = false
    s_EntityData.showProgress = false
    s_EntityData.useMarkerTransform = false
    s_EntityData.isVisible = true
    s_EntityData.snap = true
    s_EntityData.showAirTargetBox = true
    s_EntityData.isFocusPoint = true
    s_EntityData.enabled = true
    s_EntityData.transform = LinearTransform(
        Vec3(1, 0, 0),
        Vec3(0, 1, 0),
        Vec3(0, 0, 1),
        Vec3(0, 6.4, 0)
    )
    
    local s_CreatedEntity = EntityManager:CreateEntity(s_EntityData, s_EntityPos)
    
    if s_CreatedEntity ~= nil then
        s_CreatedEntity:Init(Realm.Realm_Server, true)
    else
        error('err: could not spawn icon.')
		return
    end
end

return kPMShared()
