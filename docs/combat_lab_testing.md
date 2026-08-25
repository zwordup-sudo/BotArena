# Combat Lab Testing

## Overview
The Combat Lab Setup system provides a configurable testing environment where players and developers can customize the Arena dimensions and enemy compositions before entering combat. This tool makes it easy to isolate specific builds, test balance profiles, and reproduce combat scenarios reliably.

## Flow
1. **Loadout**: Set up your bot build and Protocol modules.
2. **Combat Lab Setup**: Access the configurations page by clicking the **ENTER ARENA** button.
3. **Arena**: Start the simulation using the customized parameters.

## Configurations Page Options
* **Arena Size**:
  * **SMALL**: 0.75x standard width and depth.
  * **STANDARD**: 1.00x standard width/depth (34.0 x 21.0 units).
  * **LARGE**: 1.35x standard width and depth.
  * **XL**: 1.75x standard width and depth.
* **Target Dummies**: Range from `0` to `8` stationary target dummies.
* **Enemy Shooters**: Range from `0` to `12` ranged shooters. Spawns include staggered initial fire delays to prevent simultaneous volley pressure.
* **Enemy Chargers**: Range from `0` to `6` charging melee enemies.
* **Presets**:
  * **BASELINE**: Standard setup used for control testing (1 Dummy, 3 Shooters, 1 Charger, STANDARD Arena).
  * **CUSTOM**: Allows arbitrary values within safe limits.
  * **RANGED PRESSURE**: 6 Shooters, 0 Chargers, 1 Dummy on a LARGE Arena.
  * **MELEE PRESSURE**: 1 Shooter, 4 Chargers, 1 Dummy on a LARGE Arena.
  * **CHAOS**: 6 Shooters, 3 Chargers, 1 Dummy on an XL Arena.

## Deterministic Spawns
To ensure balance testing is reproducible, enemy spawn positions are calculated deterministically along concentric rings surrounding the player's central spawn point. 
The placement algorithm sorts points by radius and angle, guaranteeing that selecting the same configurations always positions the entities in the exact same starting points, avoiding any reliance on random spawn layouts.
