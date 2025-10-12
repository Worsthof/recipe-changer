# Tweaksmith
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 💡 What is it About?

This mod is designed for simple **quality-of-life** changes or balance adjustments. It's written in Lua using the [UE4SS scripting library](https://docs.ue4ss.com/). It modifies the core item crafting data table (`DT_ItemRecipeDataTable`) at runtime. Instead of replacing game files, it intercepts the data and overwrites specific recipe parameters defined by the user in JSON configuration files.

This allows you to globally adjust the following key recipe properties:

* **`OutputItem`**: The name of item to be produced.
* **`OutputAmount`**: The number of items produced per single craft.
* **`WorkAmount`**: The base time (in seconds) required for the craft.
* **`Materials`**: Which materials are required and the amount of each one.
* **`ExpRate`**: The multiplier for the experience granted upon completing the craft.

---

## ⚙️ How to Use

All modifications are managed from explicitly structured JSON files.

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

You can define your recipe modifications in JSON files. For this create a new or edit an existing json file in the project **`Recipes`** directory.
```
Tweaksmith/
├── Scripts/
└── Recipes/
    ├── global.json
    ├── sphere.json
    └── ammo.json
            
```
The filename can be almost anything, but it must not contain special characters and must have a **`.json`** extension.
There can be multiple JSON files, the mod will use all of them. The recipe objects inside the JSON should be constructed as shown below.
All property modification is **OPTIONAL** , this example just show the possibilities.

Example JSON:
```json
{
    "PalSphere": {
        "OutputItem": "Arrow",
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

#### Modifying Materials

Materials are indexed from [1] to [5].
- To change a material: Provide a new Name (e.g., "IronIngot") and a new Amount.
- To remove a material: Set the Name to "None" and the Amount to 0.

#### Global modifiers

If you want recipe changes which would apply to all recipe, you can define your recipe with a key of an asterisk (*). All global modification will be applied before any of the explicit one.

Example:
```json
{
    "*": {
        "WorkAmount": 30
    },
}
```

This would set the `WorkAmount` to 30 seconds for all recipe.

If you want to apply multiple global modification in different JSON files, then you should explicitly tell the priority level of that modification. This is because under the hood all modficiation is merged to one before applying changes. If you doesn't provide this, then the merge order of the global modifications will be unpredictable which could lead to unexpected results.

To apply priority to a global config, simply add a number after the asterisk. The higher the number, the latter it will be merged. By default all priority level is zero.

Example:
```json
{
    "*": {
        "WorkAmount": 30,
        "OutputAmount": 20
    },

    "*3": {
        "WorkAmount": 20
    },

}
```

This would set `WorkAmount` to 20 sec and `OutputAmount` to 20 for every recipe.

##### Grouping

If you don't want to apply modification on every recipe but just a group of recipes you can leverage the `ItemType` propeties.
Each item has two type **`ItemTypeA`** and **`ItemTypeB`**. You can tell the global modifier to check for these `ItemTypes` before applying changes, this way it's possible to exclude items from global modification.

You can do this by specifying the `ItemType` on the key of the config, each of them concatenated by colon (:).

The pattern looks like this: `*:<ItemTypeA>:<ItemTypeB>`.

Both `ItemType` specification is **OPTIONAL** but **`ItemTypeB`** cannot exists without **`ItemTypeA`**. The more specified the group, the latter will be merged, unaffected by priority.

Example:
```json
{
    "*": {
        "WorkAmount": 30
    },

    "*:Ammo": {
        "WorkAmount": 20
    },

    "*:Material:MaterialIngot": {
        "WorkAmount": 10
    }
}
```

This example would set every item recipe `WorkAmount` to 30 sec, but every **`Ammo`** type recipe to 20 sec, but every **`MaterialIngot`** type recipe to 10 sec.

You can find the available `ItemTypes` in `ItemTypeA.csv` and `ItemTypeB.csv`.

#### Dynamic modifiers

If you want to apply changes relatively to the original recipe values, you can do that by supplying a specific string which correctly matches the `Dynamic modifier pattern` to the value of a property.

The pattern looks like this: `::<modifier>::<operand>`.

The available modifiers are:
* **`ADD`**: Adds the operand to the correspondig property.
* **`SUBSTRACT`**: Substracts the operand from the correspondig property.
* **`MULTIPLY`**: Multiplies the corresponding property by the operand.

These `Dynamic modifers` can be applied to every number based recipe property.

Example:
```json
{
    "*": {
        "WorkAmount": "::MULTIPLY::0.5"
    },
}
```

This example would half the `WorkAmount` for every recipe.

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
Locate and download the [newest release](https://github.com/Worsthof/tweaksmith/releases).
The Mod will be in a ```.zip``` file, named ```RecipeChanger.zip```.

### 3. Install the mod
Extract the mod contents to your ```...\Mods``` folder.
After this the folder structure should look something like this:
```
ue4ss/
└── Mods/
    └── Tweaksmith/
        ├── Scripts/
        │   └── main.lua
        │   ...
        └── Recipes/
            └── your_recipes.json
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
Tweaksmith : 1
```

Save and close ```mods.txt```. The mod is now active and will load the next time you launch Palworld!

---

## 📄 License
This project is licensed under the MIT License.
