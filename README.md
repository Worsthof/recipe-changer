# Palworld Recipe Changer Mod
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 💡 What is it About?

This mod is designed for simple **quality-of-life** changes or balance adjustments. It's written in Lua using the [UE4SS scripting library](https://docs.ue4ss.com/). It modifies the core item crafting data table (`DT_ItemRecipeDataTable`) at runtime. Instead of replacing game files, it intercepts the data and overwrites specific recipe parameters defined by the user in a configuration file (`config.lua`).

This allows you to globally adjust four key recipe properties:

* **`OutputAmount`**: The number of items produced per single craft.
* **`WorkAmount`**: The base time (in seconds) required for the craft.
* **`Materials`**: Which materials are required and the amount of each one.
* **`ExpRate`**: The multiplier for the experience granted upon completing the craft.

---

## ⚙️ How to Use

All modifications are managed within the **`config.lua`** file.

### 1. Identify the Recipe Name

The key for every modification must be the **exact internal name** of the recipe as found in the game files. These names are **case-sensitive**.

| Item Category | Example Key |
| :--- | :--- |
| **Pal Spheres** | `"PalSphere"`, `"PalSphere_Mega"`, `"PalSphere_Legend"` |
| **Weapons** | `"AssaultRifle_Default1"`, `"Musket"`, `"Spear"` |
| **Ammunition** | `"RifleBullet"`, `"ShotgunBullet"`, `"Arrow"` |
| **Materials** | `"IronIngot"`, `"CarbonFiber"`, `"Cloth"` |
| **Food** | `"Cake"`, `"BakedMeat_ChickenPal"`, `"Pizza"` |

A small exported list **`RecipeNames.csv`** is available for easier access.
I have not tested every name on this list, but no issues have been encountered so far.
It is AI generated so take it with a grain of salt.

### 2. Configure a Recipe

In the **`config.lua`** file locate the "Recipes" collection and simply add you desired modifications based on the provided example.

#### Modifying Materials

Materials are indexed from [1] to [5].
- To change a material: Provide a new Name (e.g., "IronIngot") and a new Amount.
- To remove a material: Set the Name to "None" and the Amount to 0.

Example config:
```lua

local config = {
    Recipes = {
        ["PalSphere"] = {
            OutputAmount = 10,
            WorkAmount = 10,
            ExpRate = 1,
            Materials = {
                [1] = { Name = "Wood", Amount = 5 },
                [2] = { Name = "Stone", Amount = 10 },
                [3] = { Name = "None", Amount = 0 }, 
            },
        },
    },
    Verbose = false
}

```

#### JSON Recipes

You can define your recipe modifications in JSON too. For this create a new or edit an existing json file in the project **`Recipes`** directory.
```
RecipeChanger/
└── Scripts/
    └── Recipes/
        ├── sphere.json
        └── ammo.json
            
```
The filename can be almost anything, but it must not contain special characters and must have a **`.json`** extension.
There can be multiple JSON files, the mod will use all of them. The JSON objects should be constructed with the same structure as the Lua tables.

Example JSON:
```json

{
    "PalSphere": {
        "OutputAmount": 10,
        "WorkAmount": 10,
        "ExpRate": 1,
        "Materials": {
            "1": { "Name": "Wood", "Amount": 5 },
            "2": { "Name": "Stone", "Amount": 10 },
            "3": { "Name": "None", "Amount": 0 }
        }
    }
}

```

---

## ⬇️ Prerequisites
This mod requires a working installation of UE4SS (Unreal Engine 4/5 Scripting System) and currently will only work with latest "experimental" version. Visit the [UE4SS repository](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) for more details.

---

## 🛠️ Installation

### 1. Locate the Mod Directory
Navigate to the UE4SS Mods folder.
Usually looking like this:
```...\Palworld\Pal\Binaries\Win64\ue4ss\Mods```

### 2. Download the Mod
Locate and download the [newest release](https://github.com/Worsthof/recipe-changer/releases).
The Mod will be in a ```.zip``` file, named ```RecipeChanger.zip```.

### 3. Install the mod
Extract the mod contents to your ```...\Mods``` folder.
After this the folder structure should look something like this:
```
ue4ss/
└── Mods/
    └── RecipeChanger/
        ├── LICENSE
        ├── README.md
        ├── RecipeNames.csv
        └── Scripts/
            ├── config.lua
            ├── main.lua
            ├── utils.lua
            ├── file_handler.lua
            ├── Recipes/
            │   ├── sphere.json
            │   └── ammo.json
            └── Libs/
                └── dkjson.lua
```
### 4. Apply Engine Compatibility Config
Due to updates in the game engine, a special configuration file is required for UE4SS to function correctly with Palworld's memory layout.

To obtain this required configuration:

- Download the corresponding [UE4SS release optimized for Palworld](https://github.com/Okaetsu/RE-UE4SS/releases/tag/experimental-palworld).
- Look for the ```MemberVariableLayout.ini``` file within the downloaded ```ue4ss``` folder.
- Copy this file and paste it into your main Palworld UE4SS installation folder ```...\Palworld\Pal\Binaries\Win64\ue4ss```.

The final placement should look like this:

```
ue4ss/
└── MemberVariableLayout.ini
```

### 5. Enable the Mod in UE4SS
Go back to the main UE4SS Mods folder ```...ue4ss\Mods``` and open the ```mods.txt``` file.
Add the following line to the end of the file:
```
RecipeChanger : 1
```

Save and close ```mods.txt```. The mod is now active and will load the next time you launch Palworld!

---

## 📄 License
This project is licensed under the MIT License.
