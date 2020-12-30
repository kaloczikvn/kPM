require("__shared/WeaponsConfig")

local WeaponModifier = class("WeaponModifier")

function WeaponModifier:ModifyWeaponInstance(p_Instance)
    if p_Instance == nil then
        return
    end
    
    local s_SoldierWeaponBlueprint = SoldierWeaponBlueprint(p_Instance)
    local s_Name = s_SoldierWeaponBlueprint.name

    if WeaponsConfig[s_Name] == nil then
        return
    end

    local s_SoldierWeaponData = SoldierWeaponData(s_SoldierWeaponBlueprint.object)
    local s_WeaponFiringData = WeaponFiringData(s_SoldierWeaponData.weaponFiring)
    s_WeaponFiringData:MakeWritable()
    s_WeaponFiringData.deployTime = WeaponsConfig[s_Name].deployTime

    local s_FiringFunctionData = FiringFunctionData(s_WeaponFiringData.primaryFire)
    s_FiringFunctionData:MakeWritable()
    local s_FireLogicData = FireLogicData(s_FiringFunctionData.fireLogic)
    
    s_FireLogicData.rateOfFire = WeaponsConfig[s_Name].rateOfFire
    s_FireLogicData.reloadTime = WeaponsConfig[s_Name].reloadTime
    s_FireLogicData.reloadTimeBulletsLeft = WeaponsConfig[s_Name].reloadTimeBulletsLeft
    
    local s_ShotConfigData = ShotConfigData(s_FiringFunctionData.shot)
    s_ShotConfigData.initialSpeed = Vec3(0, 0, 650)

    local s_BulletEntityData = BulletEntityData(s_ShotConfigData.projectileData)
    s_BulletEntityData:MakeWritable()
    s_BulletEntityData.startDamage = WeaponsConfig[s_Name].startDamage
    s_BulletEntityData.endDamage = WeaponsConfig[s_Name].endDamage
    s_BulletEntityData.damageFalloffStartDistance = WeaponsConfig[s_Name].damageFalloffStartDistance
    s_BulletEntityData.damageFalloffEndDistance = WeaponsConfig[s_Name].damageFalloffEndDistance
    s_BulletEntityData.instantHit = true


    local s_GunSwayData = GunSwayData(s_WeaponFiringData.weaponSway)
    s_GunSwayData:MakeWritable()
    s_GunSwayData.firstShotRecoilMultiplier = WeaponsConfig[s_Name].firstShotRecoilMultiplier
    s_GunSwayData.deviationScaleFactorZoom = WeaponsConfig[s_Name].deviationScaleFactorZoom

    -- Standing
    local s_GunSwayStandData = GunSwayStandData(s_GunSwayData.stand)
    local s_NoZoom = GunSwayBaseMoveJumpData(s_GunSwayStandData.noZoom)
    GunSwayDispersionData(s_NoZoom.baseValue).minAngle = WeaponsConfig[s_Name].stand.noZoom.baseValue.minAngle
    GunSwayDispersionData(s_NoZoom.baseValue).maxAngle = WeaponsConfig[s_Name].stand.noZoom.baseValue.maxAngle
    GunSwayDispersionData(s_NoZoom.baseValue).increasePerShot = WeaponsConfig[s_Name].stand.noZoom.baseValue.increasePerShot
    GunSwayDispersionData(s_NoZoom.baseValue).decreasePerSecond = WeaponsConfig[s_Name].stand.noZoom.baseValue.decreasePerSecond

    GunSwayDispersionData(s_NoZoom.moving).minAngle = WeaponsConfig[s_Name].stand.noZoom.moving.minAngle
    GunSwayDispersionData(s_NoZoom.moving).maxAngle = WeaponsConfig[s_Name].stand.noZoom.moving.maxAngle
    GunSwayDispersionData(s_NoZoom.moving).increasePerShot = WeaponsConfig[s_Name].stand.noZoom.moving.increasePerShot
    GunSwayDispersionData(s_NoZoom.moving).decreasePerSecond = WeaponsConfig[s_Name].stand.noZoom.moving.decreasePerSecond

    GunSwayDispersionData(s_NoZoom.jumping).minAngle = WeaponsConfig[s_Name].stand.noZoom.jumping.minAngle
    GunSwayDispersionData(s_NoZoom.jumping).maxAngle = WeaponsConfig[s_Name].stand.noZoom.jumping.maxAngle
    GunSwayDispersionData(s_NoZoom.jumping).increasePerShot = WeaponsConfig[s_Name].stand.noZoom.jumping.increasePerShot
    GunSwayDispersionData(s_NoZoom.jumping).decreasePerSecond = WeaponsConfig[s_Name].stand.noZoom.jumping.decreasePerSecond

    GunSwayDispersionData(s_NoZoom.sprinting).minAngle = WeaponsConfig[s_Name].stand.noZoom.sprinting.minAngle
    GunSwayDispersionData(s_NoZoom.sprinting).maxAngle = WeaponsConfig[s_Name].stand.noZoom.sprinting.maxAngle
    GunSwayDispersionData(s_NoZoom.sprinting).increasePerShot = WeaponsConfig[s_Name].stand.noZoom.sprinting.increasePerShot
    GunSwayDispersionData(s_NoZoom.sprinting).decreasePerSecond = WeaponsConfig[s_Name].stand.noZoom.sprinting.decreasePerSecond

    GunSwayDispersionData(s_NoZoom.vaultingSmallObject).minAngle = WeaponsConfig[s_Name].stand.noZoom.vaultingSmallObject.minAngle
    GunSwayDispersionData(s_NoZoom.vaultingSmallObject).maxAngle = WeaponsConfig[s_Name].stand.noZoom.vaultingSmallObject.maxAngle
    GunSwayDispersionData(s_NoZoom.vaultingSmallObject).increasePerShot = WeaponsConfig[s_Name].stand.noZoom.vaultingSmallObject.increasePerShot
    GunSwayDispersionData(s_NoZoom.vaultingSmallObject).decreasePerSecond = WeaponsConfig[s_Name].stand.noZoom.vaultingSmallObject.decreasePerSecond

    -- Standing -- Zoom
    local s_Zoom = GunSwayBaseMoveJumpData(s_GunSwayStandData.zoom)
    GunSwayDispersionData(s_Zoom.baseValue).minAngle = WeaponsConfig[s_Name].stand.zoom.baseValue.minAngle
    GunSwayDispersionData(s_Zoom.baseValue).maxAngle = WeaponsConfig[s_Name].stand.zoom.baseValue.maxAngle
    GunSwayDispersionData(s_Zoom.baseValue).increasePerShot = WeaponsConfig[s_Name].stand.zoom.baseValue.increasePerShot
    GunSwayDispersionData(s_Zoom.baseValue).decreasePerSecond = WeaponsConfig[s_Name].stand.zoom.baseValue.decreasePerSecond

    GunSwayDispersionData(s_Zoom.moving).minAngle = WeaponsConfig[s_Name].stand.zoom.moving.minAngle
    GunSwayDispersionData(s_Zoom.moving).maxAngle = WeaponsConfig[s_Name].stand.zoom.moving.maxAngle
    GunSwayDispersionData(s_Zoom.moving).increasePerShot = WeaponsConfig[s_Name].stand.zoom.moving.increasePerShot
    GunSwayDispersionData(s_Zoom.moving).decreasePerSecond = WeaponsConfig[s_Name].stand.zoom.moving.decreasePerSecond

    GunSwayDispersionData(s_Zoom.jumping).minAngle = WeaponsConfig[s_Name].stand.zoom.jumping.minAngle
    GunSwayDispersionData(s_Zoom.jumping).maxAngle = WeaponsConfig[s_Name].stand.zoom.jumping.maxAngle
    GunSwayDispersionData(s_Zoom.jumping).increasePerShot = WeaponsConfig[s_Name].stand.zoom.jumping.increasePerShot
    GunSwayDispersionData(s_Zoom.jumping).decreasePerSecond = WeaponsConfig[s_Name].stand.zoom.jumping.decreasePerSecond

    -- Crouching
    local s_GunSwayCrouchProneData = GunSwayCrouchProneData(s_GunSwayData.crouch)
    local s_NoZoom = GunSwayBaseMoveData(s_GunSwayCrouchProneData.noZoom)
    GunSwayDispersionData(s_NoZoom.baseValue).minAngle = WeaponsConfig[s_Name].crouch.noZoom.baseValue.minAngle
    GunSwayDispersionData(s_NoZoom.baseValue).maxAngle = WeaponsConfig[s_Name].crouch.noZoom.baseValue.maxAngle
    GunSwayDispersionData(s_NoZoom.baseValue).increasePerShot = WeaponsConfig[s_Name].crouch.noZoom.baseValue.increasePerShot
    GunSwayDispersionData(s_NoZoom.baseValue).decreasePerSecond = WeaponsConfig[s_Name].crouch.noZoom.baseValue.decreasePerSecond

    GunSwayDispersionData(s_NoZoom.moving).minAngle = WeaponsConfig[s_Name].crouch.noZoom.moving.minAngle
    GunSwayDispersionData(s_NoZoom.moving).maxAngle = WeaponsConfig[s_Name].crouch.noZoom.moving.maxAngle
    GunSwayDispersionData(s_NoZoom.moving).increasePerShot = WeaponsConfig[s_Name].crouch.noZoom.moving.increasePerShot
    GunSwayDispersionData(s_NoZoom.moving).decreasePerSecond = WeaponsConfig[s_Name].crouch.noZoom.moving.decreasePerSecond

    -- Crouching -- Zoom
    local s_Zoom = GunSwayBaseMoveData(s_GunSwayCrouchProneData.zoom)
    GunSwayDispersionData(s_Zoom.baseValue).minAngle = WeaponsConfig[s_Name].crouch.zoom.baseValue.minAngle
    GunSwayDispersionData(s_Zoom.baseValue).maxAngle = WeaponsConfig[s_Name].crouch.zoom.baseValue.maxAngle
    GunSwayDispersionData(s_Zoom.baseValue).increasePerShot = WeaponsConfig[s_Name].crouch.zoom.baseValue.increasePerShot
    GunSwayDispersionData(s_Zoom.baseValue).decreasePerSecond = WeaponsConfig[s_Name].crouch.zoom.baseValue.decreasePerSecond

    GunSwayDispersionData(s_Zoom.moving).minAngle = WeaponsConfig[s_Name].crouch.zoom.moving.minAngle
    GunSwayDispersionData(s_Zoom.moving).maxAngle = WeaponsConfig[s_Name].crouch.zoom.moving.maxAngle
    GunSwayDispersionData(s_Zoom.moving).increasePerShot = WeaponsConfig[s_Name].crouch.zoom.moving.increasePerShot
    GunSwayDispersionData(s_Zoom.moving).decreasePerSecond = WeaponsConfig[s_Name].crouch.zoom.moving.decreasePerSecond
end

return WeaponModifier
