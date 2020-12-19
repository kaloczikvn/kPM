import { Weapons } from './Weapons';

export var Kits: any = [
    {
        Name: "Assault",
        Weapons: {
            Primary: {
                U_M16A4: Weapons.U_M16A4,
                U_AK74M: Weapons.U_AK74M,
                U_G36C: Weapons.U_G36C,
            },
            Secondary: {
                U_M9: Weapons.U_M9,
                U_Taurus44: Weapons.U_Taurus44,
            },
            Tactical: {
                U_M320_SMK: Weapons.U_M320_SMK,
                U_Ammobag: Weapons.U_Ammobag,
            },
            Lethal: {
                U_M67: Weapons.U_M67,
            },
            defaultPrimary: Weapons.U_M16A4.Key,
            defaultSecondary: Weapons.U_Taurus44.Key,
            defaultTactical: Weapons.U_M320_SMK.Key,
            defaultLethal: Weapons.U_M67.Key,
        },
    },
    {
        Name: "SpecOps",
        Weapons: {
            Primary: {
                U_AKS74u: Weapons.U_AKS74u,
                U_F2000: Weapons.U_F2000,
            },
            Secondary: {
                U_M9: Weapons.U_M9,
                U_Taurus44: Weapons.U_Taurus44,
            },
            Tactical: {
                U_Medkit: Weapons.U_Medkit,
                U_UGS: Weapons.U_UGS,
            },
            Lethal: {
                U_M67: Weapons.U_M67,
            },
            defaultPrimary: Weapons.U_AKS74u.Key,
            defaultSecondary: Weapons.U_Taurus44.Key,
            defaultTactical: Weapons.U_Medkit.Key,
            defaultLethal: Weapons.U_M67.Key,
        },
    },
    {
        Name: "Demolition",
        Weapons: {
            Primary: {
                U_SPAS12: Weapons.U_SPAS12,
                U_M249: Weapons.U_M249,
            },
            Secondary: {
                U_M9: Weapons.U_M9,
                U_Taurus44: Weapons.U_Taurus44,
            },
            Tactical: {
                U_C4: Weapons.U_C4,
                U_Claymore: Weapons.U_Claymore,
            },
            Lethal: {
                U_M67: Weapons.U_M67,
            },
            defaultPrimary: Weapons.U_SPAS12.Key,
            defaultSecondary: Weapons.U_Taurus44.Key,
            defaultTactical: Weapons.U_C4.Key,
            defaultLethal: Weapons.U_M67.Key,
        },
    },
    {
        Name: "Sniper",
        Weapons: {
            Primary: {
                U_L96: Weapons.U_L96,
                U_M98B: Weapons.U_M98B,
            },
            Secondary: {
                U_M9: Weapons.U_M9,
                U_Taurus44: Weapons.U_Taurus44,
            },
            Tactical: {
                U_MAV: Weapons.U_MAV,
                U_Ammobag: Weapons.U_Ammobag,
            },
            Lethal: {
                U_M67: Weapons.U_M67,
            },
            defaultPrimary: Weapons.U_L96.Key,
            defaultSecondary: Weapons.U_Taurus44.Key,
            defaultTactical: Weapons.U_MAV.Key,
            defaultLethal: Weapons.U_M67.Key,
        },
    },
];
