# Combat Defense Model — Armor System 0.1A

## Overview

The Armor System provides a simple, scalable defensive layer driven entirely by equipped parts. There are **no hard classes** — armor and penetration come from what you equip.

## Core Formula

All physical/general damage uses one centralized calculation path via `BotStatCalculator.calculate_armored_damage()`:

```
effective_armor = max(0.0, target_armor - attacker_flat_penetration)
effective_armor = effective_armor * (1.0 - attacker_percent_penetration)
final_damage = raw_damage * 100.0 / (100.0 + effective_armor)
```

- Negative armor is **never** produced (clamped at 0.0).
- `percent_armor_penetration` is clamped to `[0.0, 1.0]`.

## Damage Pipeline Order

For **Player receiving damage** (`Player3D.take_damage`):

```
1. RAW DAMAGE (from projectile, melee hit, or Charger contact)
2. ARMOR / PENETRATION (centralized formula above)
3. REACTIVE PLATING (if active and source is hostile_projectile: ×0.40 multiplier, consumes a plate)
4. INCOMING DAMAGE MULTIPLIER (temporary modifiers like Fortify)
5. SYNC MITIGATION EVENT (damage_mitigated calculated as raw - final_applied)
6. HP REDUCTION
```

For **enemies receiving damage** (Shooter, Charger, Dummy):

```
1. RAW DAMAGE (from Player projectile or melee source)
2. ARMOR / PENETRATION (same centralized formula; enemies currently have 0 armor)
3. HP REDUCTION
```

## Interaction with Existing Abilities

| Ability | Interaction with Armor |
|---|---|
| **Bastion Protocol** | Intercepts projectile *before* damage. Blocked projectile = 0 damage, no armor calc. |
| **Reactive Plating** | Applied *after* armor reduction. Multiplies post-armor damage by 0.40. |
| **Fortify (Heavy Core)** | Applied *after* armor and Reactive Plating via `incoming_damage_multiplier`. |
| **Ghost Buffer** | Absorbs projectile *before* damage. No armor calc needed. |
| **Reflex Overclock** | Evasion flag checked *before* damage. No armor calc needed. |
| **Directional Barrier** | Intercepts projectile *before* damage. No armor calc needed. |
| **Execution Protocol** | Melee damage flows through target's armor. Assassin penetration applies. |
| **Rail Salvo** | Projectile damage flows through target's armor. Shooter penetration applies. |
| **Charger Contact** | Calls `take_damage(contact_damage)` with no source, so Player's full armor applies (0 penetration). |

## Equipment Values (Lab 0.1A)

### Tank Parts
| Part | Armor | Flat Pen | % Pen |
|---|---|---|---|
| Tank Core | 18 | 0 | 0% |
| Tank Arms | 4 | 0 | 0% |
| Tank Legs | 10 | 0 | 0% |
| **Full Tank** | **32** | **0** | **0%** |

### Assassin Parts
| Part | Armor | Flat Pen | % Pen |
|---|---|---|---|
| Assassin Core | 2 | 0 | 0% |
| Assassin Arms | 0 | 4 | 20% |
| Assassin Legs | 0 | 0 | 0% |
| **Full Assassin** | **2** | **4** | **20%** |

### Shooter Parts
| Part | Armor | Flat Pen | % Pen |
|---|---|---|---|
| Shooter Core | 3 | 0 | 0% |
| Shooter Arms | 0 | 2 | 0% |
| Shooter Legs | 2 | 0 | 0% |
| **Full Shooter** | **5** | **2** | **0%** |

### Generic Parts
| Part | Armor | Flat Pen | % Pen |
|---|---|---|---|
| Standard Core | 5 | 0 | 0% |
| Standard Arms | 0 | 0 | 0% |
| Standard Legs | 3 | 0 | 0% |
| **Full Standard** | **8** | **0** | **0%** |
| Light Core | 0 | 0 | 0% |
| Rapid Arms | 0 | 0 | 0% |
| Light Legs | 0 | 0 | 0% |
| **Full Light** | **0** | **0** | **0%** |
| Heavy Core | 15 | 0 | 0% |
| Heavy Arms | 5 | 0 | 0% |
| Heavy Legs | 10 | 0 | 0% |
| **Full Heavy** | **30** | **0** | **0%** |

## Example Damage Calculations

### Normal shot vs Full Tank (32 Armor)
```
RAW: 20
effective_armor = max(0, 32 - 0) = 32
effective_armor = 32 * (1.0 - 0.0) = 32
final = 20 * 100 / 132 ≈ 15.15
```

### Assassin vs Full Tank (32 Armor, 4 flat pen, 20% pen)
```
RAW: 40 (melee)
effective_armor = max(0, 32 - 4) = 28
effective_armor = 28 * (1.0 - 0.20) = 22.4
final = 40 * 100 / 122.4 ≈ 32.68
```

### Normal shot vs Zero Armor target (Dummy)
```
RAW: 20
effective_armor = 0
final = 20 * 100 / 100 = 20 (unchanged)
```

## Design Philosophy

- Armor is **equipment-driven** — "You Are What You Equip."
- Role Profile remains **descriptive only**. No hidden bonuses from role percentage.
- Heavy parts provide armor but are **not Tank affinity**. Heavy ≠ Tank.
- CHAOS stress testing is a diagnostic tool, not the sole balance target.
- Armor provides **structural durability** that persists outside ability windows.
