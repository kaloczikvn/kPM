WeaponsConfig = 
{
    ["Weapons/AK74M/AK74"] = {
        -- WeaponFiringData
        deployTime = 0.95,
        
        -- FireLogicData
        rateOfFire = 700.0,
        reloadTimeBulletsLeft = 2.5,
        reloadTime = 3.25,

        -- BulletEntityData
        startDamage = 40.0,
        endDamage = 30.0,
        damageFalloffStartDistance = 15.0,
        damageFalloffEndDistance = 50.0,

        -- GunSwayData
        firstShotRecoilMultiplier = 1.0,
        deviationScaleFactorZoom = 0.5,

        -- -- GunSwayStandData
        stand = {
            noZoom = {
                baseValue = {
                    minAngle = 0.1,
                    maxAngle = 5.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 3.5,
                    maxAngle = 7.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                jumping = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
                sprinting = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
                vaultingSmallObject = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                }
            },
            zoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 5.0,
                    increasePerShot = 0.5,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.5,
                    maxAngle = 5.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                jumping = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
            }
        },

        -- -- GunSwayCrouchProneData
        crouch = {
            noZoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 5.0,
                    increasePerShot = 0.5,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.5,
                    maxAngle = 5.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
            },
            zoom = {
                baseValue = {
                    minAngle = 0.0005,
                    maxAngle = 3.5,
                    increasePerShot = 0.5,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.5,
                    maxAngle = 5.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
            },
        },
    },

    ["Weapons/M16A4/M16A4"] = {
        -- WeaponFiringData
        deployTime = 0.75,
        
        -- FireLogicData
        rateOfFire = 775.0,
        reloadTimeBulletsLeft = 2.03,
        reloadTime = 2.36,

        -- BulletEntityData
        startDamage = 25.0,
        endDamage = 18.4,
        damageFalloffStartDistance = 6.0,
        damageFalloffEndDistance = 35.0,

        -- GunSwayData
        firstShotRecoilMultiplier = 1.0,
        deviationScaleFactorZoom = 0.75,

        -- -- GunSwayStandData
        stand = {
            noZoom = {
                baseValue = {
                    minAngle = 0.25,
                    maxAngle = 4.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 1.5,
                    maxAngle = 4.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
                jumping = {
                    minAngle = 2.5,
                    maxAngle = 10.0,
                    increasePerShot = 2.0,
                    decreasePerSecond = 7.5,
                },
                sprinting = {
                    minAngle = 2.5,
                    maxAngle = 10.0,
                    increasePerShot = 2.0,
                    decreasePerSecond = 7.5,
                },
                vaultingSmallObject = {
                    minAngle = 2.5,
                    maxAngle = 10.0,
                    increasePerShot = 2.0,
                    decreasePerSecond = 7.5,
                }
            },
            zoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 2.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 0.25,
                    maxAngle = 4.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
                jumping = {
                    minAngle = 2.5,
                    maxAngle = 10.0,
                    increasePerShot = 2.0,
                    decreasePerSecond = 7.5,
                },
            }
        },

        -- -- GunSwayCrouchProneData
        crouch = {
            noZoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 2.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 0.25,
                    maxAngle = 4.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
            },
            zoom = {
                baseValue = {
                    minAngle = 0.005,
                    maxAngle = 2.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 0.25,
                    maxAngle = 4.0,
                    increasePerShot = 0.85,
                    decreasePerSecond = 15.0,
                },
            }
        },
    },


    ["Weapons/AKS74u/AKS74u"] = {
        -- WeaponFiringData
        deployTime = 0.95,
        
        -- FireLogicData
        rateOfFire = 850.0,
        reloadTimeBulletsLeft = 2.5,
        reloadTime = 3.25,

        -- BulletEntityData
        startDamage = 31.5,
        endDamage = 15.5,
        damageFalloffStartDistance = 8.5,
        damageFalloffEndDistance = 45.0,

        -- GunSwayData
        firstShotRecoilMultiplier = 1.0,
        deviationScaleFactorZoom = 0.75,

        -- -- GunSwayStandData
        stand = {
            noZoom = {
                baseValue = {
                    minAngle = 0.15,
                    maxAngle = 2.5,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.0,
                    maxAngle = 3.0,
                    increasePerShot = 2.0,
                    decreasePerSecond = 10.0,
                },
                jumping = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
                sprinting = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
                vaultingSmallObject = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                }
            },
            zoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 2.0,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.0,
                    maxAngle = 3.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                jumping = {
                    minAngle = 3.5,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 10.0,
                },
            }
        },

        -- -- GunSwayCrouchProneData
        crouch = {
            noZoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 2.5,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.0,
                    maxAngle = 3.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
            },
            zoom = {
                baseValue = {
                    minAngle = 0.025,
                    maxAngle = 2.5,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
                moving = {
                    minAngle = 1.0,
                    maxAngle = 3.0,
                    increasePerShot = 1.0,
                    decreasePerSecond = 10.0,
                },
            },
        },
    },

    ["Weapons/XP1_L96/L96"] = {
        -- WeaponFiringData
        deployTime = 0.95,
        
        -- FireLogicData
        rateOfFire = 360.0,
        reloadTimeBulletsLeft = 2.6,
        reloadTime = 4.8,

        -- BulletEntityData
        startDamage = 100.0,
        endDamage = 55.0,
        damageFalloffStartDistance = 150.0,
        damageFalloffEndDistance = 250.0,

        -- GunSwayData
        firstShotRecoilMultiplier = 1.0,
        deviationScaleFactorZoom = 0.75,

        -- -- GunSwayStandData
        stand = {
            noZoom = {
                baseValue = {
                    minAngle = 5.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 6.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
                jumping = {
                    minAngle = 7.0,
                    maxAngle = 12.5,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
                sprinting = {
                    minAngle = 7.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
                vaultingSmallObject = {
                    minAngle = 5.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                }
            },
            zoom = {
                baseValue = {
                    minAngle = 0.0,
                    maxAngle = 1.5,
                    increasePerShot = 1.0,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 6.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
                jumping = {
                    minAngle = 7.0,
                    maxAngle = 12.5,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
            }
        },

        -- -- GunSwayCrouchProneData
        crouch = {
            noZoom = {
                baseValue = {
                    minAngle = 1.5,
                    maxAngle = 4.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 6.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
            },
            zoom = {
                baseValue = {
                    minAngle = 0.0,
                    maxAngle = 1.5,
                    increasePerShot = 1.0,
                    decreasePerSecond = 15.0,
                },
                moving = {
                    minAngle = 6.0,
                    maxAngle = 7.0,
                    increasePerShot = 1.2,
                    decreasePerSecond = 15.0,
                },
            }
        },
    },

    ["Weapons/Taurus44/Taurus44"] = {
        -- WeaponFiringData
        deployTime = 0.55,
        
        -- FireLogicData
        rateOfFire = 175.0,
        reloadTimeBulletsLeft = 1.96,
        reloadTime = 2.1,

        -- BulletEntityData
        startDamage = 50.0,
        endDamage = 30.0,
        damageFalloffStartDistance = 30.0,
        damageFalloffEndDistance = 50.0,

        -- GunSwayData
        firstShotRecoilMultiplier = 1.0,
        deviationScaleFactorZoom = 0.5,

        -- -- GunSwayStandData
        stand = {
            noZoom = {
                baseValue = {
                    minAngle = 0.0,
                    maxAngle = 6.0,
                    increasePerShot = 1.5,
                    decreasePerSecond = 25.0,
                },
                moving = {
                    minAngle = 2.0,
                    maxAngle = 6.0,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
                jumping = {
                    minAngle = 7.0,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
                sprinting = {
                    minAngle = 7.0,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
                vaultingSmallObject = {
                    minAngle = 7.0,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                }
            },
            zoom = {
                baseValue = {
                    minAngle = 0.0,
                    maxAngle = 4.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 25.0,
                },
                moving = {
                    minAngle = 2.0,
                    maxAngle = 6.0,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
                jumping = {
                    minAngle = 7.0,
                    maxAngle = 12.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
            }
        },

        -- -- GunSwayCrouchProneData
        crouch = {
            noZoom = {
                baseValue = {
                    minAngle = 0.0,
                    maxAngle = 4.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 25.0,
                },
                moving = {
                    minAngle = 1.0,
                    maxAngle = 4.0,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
            },
            zoom = {
                baseValue = {
                    minAngle = 0.0,
                    maxAngle = 4.5,
                    increasePerShot = 1.5,
                    decreasePerSecond = 25.0,
                },
                moving = {
                    minAngle = 1.0,
                    maxAngle = 4.0,
                    increasePerShot = 1.5,
                    decreasePerSecond = 15.0,
                },
            },
        },
    },
}
