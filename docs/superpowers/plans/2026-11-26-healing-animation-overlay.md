# Healing Animation Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show existing healing animation as player overlay on successful heal.

**Architecture:** Restore `HealingSprite` in player scene using existing `player_frames.tres` resource. Player script already optionally triggers the `healing` animation after successful `heal()`; preserve the current energy cost and input behavior.

**Tech Stack:** Godot 4.7, GDScript, TSCN.

**Spec:** `docs/superpowers/specs/2026-11-26-healing-animation-overlay-design.md`

## Global Constraints

- Keep existing healing sprite sheet and animation frames unchanged.
- `E` remains heal input; cost remains 1 energy for 1 HP.
- Show healing animation only after successful heal.
- Preserve unrelated edits in `scenes/characters/player.tscn`.

## Review Focus

- Missing or wrongly named `HealingSprite` node: scene test verifies node and `healing` animation.
- Full HP or zero energy must not play effect or consume energy: heal input test already covers behavior.
- No sprite frame changes: inspect TSCN/resource diff and confirm only node restored.

---

### Task 1: Restore healing overlay node

**Files:**
- Modify: `scenes/characters/player.tscn`
- Verify: `tests/player_heal_input_test.gd`

**Interfaces:**
- Consumes: `res://assets/sprites/player/player_frames.tres`, animation `healing`.
- Produces: child `HealingSprite` (`AnimatedSprite2D`) at player sprite offset `(8, -16)`, z-index `1`, hidden by default.

- [ ] **Step 1: Add scene assertions** for `HealingSprite` existence, shared existing SpriteFrames resource, `healing` animation, and hidden initial state.
- [ ] **Step 2: Run** `godot --headless --path . --script tests/player_heal_input_test.gd`; confirm new scene assertions fail because node is absent.
- [ ] **Step 3: Restore only the `HealingSprite` node** to `scenes/characters/player.tscn`; do not edit texture or SpriteFrames assets.
- [ ] **Step 4: Run** `godot --headless --path . --script tests/player_heal_input_test.gd` and `godot --headless --path . --editor --quit`; expect all assertions and editor import/parse to pass.
