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

## Future Plans (Phase 0.1B)

In Phase 0.1B, the neutral chassis will be complemented by role-specific chassis:
- Tank Chassis
- Assassin Chassis
- Shooter Chassis

At this point, role builds will transition to natural 4-part distributions (25%, 50%, 75%, 100%), and HP/Armor/Weight will be redistributed into the Chassis slot to provide true structural differentiation between builds.
