# Chassis System Integration

## Overview

The BotArena physical equipment system uses four slots:
1. Core
2. **Chassis** (Added in 0.1A)
3. Arms
4. Legs

Chassis is a purely **structural/passive** equipment slot. It does not provide any active abilities and does not introduce a new hotkey. The controls remain:
- **LMB** = Primary Attack
- **Q** = Core
- **E** = Arms
- **R** = Legs
- **Space** = Dash
- **F** = Protocol Special

## Phase 0.1A — Structural Migration

Phase 0.1A introduces the structural slot without rebalancing the game. 
- A neutral `Standard Chassis` was introduced to serve as a baseline.
- **Zero Combat Stats**: The Standard Chassis has 0 for all modifiers (HP, Armor, Movement, etc.).
- **Zero Resource Cost**: Power, Weight, and Thermal load are all 0 to avoid breaking existing builds.
- **Role Affinity**: The neutral chassis provides 0 Tank, Assassin, and Shooter affinity.

### Coverage & Role Profile Migration

The `BotRoleCalculator` detects the number of physical parts equipped to determine Protocol eligibility coverage. Since Chassis currently provides no affinity, naive counting would artificially reduce coverage (e.g. 3 affinity parts / 4 equipped parts = 75% coverage), invalidating existing Protocol builds.

To preserve compatibility, a temporary migration rule is implemented: **Neutral Lab Chassis do not penalize the equipped part count.** The 0.1A `BotRoleCalculator` detects if a part is a Chassis with 0 affinity across all roles and safely ignores it for coverage math. This preserves 100% coverage for existing Full Tank, Full Assassin, and Full Shooter builds.

## Phase 0.1B — Role Chassis & Stat Redistribution

In Phase 0.1B, role-specific Chassis are introduced to naturally establish the Chassis as the primary structural component of a build.

### Chassis Structural Identity
The Chassis slot acts as the core of a Bot's structural identity. It carries a heavy percentage of the build's base Hit Points (HP) and Armor, while simultaneously demanding a significant Weight and Power cost. 

### Stat Redistribution Principle
To ensure existing combat balance was not destroyed, the structural statistics of role chassis were obtained by **redistributing** existing stats from the Core and Legs, rather than simply adding new stats on top. This is treated as a strict **Resource Conservation** problem:

*   **Old Total Power = New Total Power**
*   **Old Total Weight = New Total Weight**
*   **Old Total Thermal = New Total Thermal**

### Final Four-Piece Coverage Math
The coverage percentage is now calculated by dividing the number of physical pieces carrying ANY role affinity by exactly `4` (the total number of physical slots).
Generic lab components with `0` affinity (such as the Standard Chassis, Standard Core, etc.) do **not** contribute to the affinity count, naturally reducing the coverage percentage.

### Multiple Compatible Protocols
With the introduction of the 4th role-bearing slot, a hybrid build can now be eligible for multiple protocols simultaneously.
For example, the classic **T-T-A-T** (Tank Core, Tank Chassis, Assassin Arms, Tank Legs) yields:
*   Tank Affinity: 75%
*   Assassin Affinity: 25%
*   Coverage: 100%

Because Tank is >= 50%, Assassin is >= 25%, and Coverage is >= 67%, this build is eligible for the **Fighter Protocol**, while simultaneously being eligible for the **Tank Protocol** (Tank >= 75%). This emergent flexibility allows players to consciously choose their Special Ability.
