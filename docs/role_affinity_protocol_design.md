# Role Affinity & Protocol Design Document

## 1. Core Principles
* **Descriptive Build Profile**: Bot builds do not enforce hard classes or place equipment locks based on parts selected. Instead, every piece of equipped modular gear generates **Role Affinity** scores (Tank, Assassin, Shooter), which aggregate into a descriptive **Build Profile**.
* **You Are What You Equip**: The Bot Build Profile is calculated dynamically at runtime. It represents a descriptive readout, never restricting build freedom or imposing invisible stat penalties.

## 2. Role Affinity Mapping
* Current explict Role Lab equipment pieces contribute **+2.0** to their specific roles:
  * **Tank Test Core, Arms, and Legs** -> Tank Affinity
  * **Assassin Test Core, Arms, and Legs** -> Assassin Affinity
  * **Shooter Test Core, Arms, and Legs** -> Shooter Affinity
* Generic benchmark parts (Standard, Light, Heavy) represent control baselines and contribute **0.0** to all role affinities.

## 3. Future Protocol Modules
* **Eligibility & Requirements**: In future updates, players can equip **Protocol Modules** in a dedicated slot. These Modules will require specific Build Profile thresholds (e.g. "Requires >= 66% Shooter Affinity" or "Requires >= 33% Tank & >= 33% Assassin").
* **Special Abilities**: Equipping a Protocol Module unlocks a unique Special/Ultimate ability, associated with small stat tradeoffs and Power/Weight/Thermal loads.
* **Special Resource (Sync)**: Protocol Special abilities are powered by a dedicated dynamic resource called **Sync** (or Protocol Charge).

## 4. Sync Generation Gameplay Loop
Players generate Sync during battle by executing role-consistent playstyles:
* **Tank**: Rewarded for damage mitigation, staggering targets, and executing interrupts against high-threat attacks.
* **Assassin**: Rewarded for mobile engagements (ingress), high-burst combos, and confirming rapid kills.
* **Shooter**: Rewarded for landing hits at Optimal Range (>= 6.0 units) and neutralizing hostile projectiles via marksman range interception.
* **Hybrids**: Rewarded for mixed combat loops combining elements of their composite role profiles.

## 5. Progression & Specialization
* Progression trees will unlock various Protocol Modules for selection, but active combat eligibility is always determined by the current equipped part configuration.
* **Full Specialization** (e.g. 100% single role) unlocks advanced, highly focused Protocols.
* **Hybrid Specialization** (e.g. 67% / 33% mixed roles) unlocks specialized hybrid Protocols that support versatile multi-role combat loops.
