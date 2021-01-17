class 'MapMarkerEntityDataGenerator'

function MapMarkerEntityDataGenerator:Create(p_EntityGuid, p_Site)
    local s_EntityData = MapMarkerEntityData(p_EntityGuid)
    s_EntityData.baseTransform = Vec3(0, 0, 0)
    s_EntityData.progressMinTime = 15.0
    s_EntityData.sid = p_Site .. " Site"
    s_EntityData.nrOfPassengers = 0
    s_EntityData.nrOfEntries = 0
    s_EntityData.progressTime1Player = 0.0
    s_EntityData.showRadius = 0.0
    s_EntityData.hideRadius = 0.0
    s_EntityData.blinkTime = 5.0
    s_EntityData.visibleForTeam = TeamId.TeamNeutral
    s_EntityData.ownerTeam = TeamId.TeamNeutral

    if p_Site == "A" then
        s_EntityData.markerType = MapMarkerType.MMTSoldier
        s_EntityData.hudIcon = UIHudIcon.UIHudIcon_FriendlyPlayer
    else
        s_EntityData.markerType = MapMarkerType.MMTSoldier
        s_EntityData.hudIcon = UIHudIcon.UIHudIcon_FriendlyPlayer
    end

    s_EntityData.verticalOffset = 0.0
    s_EntityData.focusPointRadius = 200.0
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
    s_EntityData.snap = false
    s_EntityData.showAirTargetBox = true
    s_EntityData.isFocusPoint = false
    s_EntityData.enabled = true
    s_EntityData.transform = LinearTransform(
        Vec3(1, 0, 0),
        Vec3(0, 1, 0),
        Vec3(0, 0, 1),
        Vec3(0, 3.4, 0)
    )

    return s_EntityData
end

return MapMarkerEntityDataGenerator()
