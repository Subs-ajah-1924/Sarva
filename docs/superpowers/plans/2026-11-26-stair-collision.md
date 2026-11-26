# Stair Collision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let player traverse `level_1.tscn` stairs up and down smoothly without snagging or floating.

**Architecture:** Correct collision only on stair-route tiles and join stair surfaces to existing ramp/platform without vertical blocking faces. Keep player movement behavior and art unchanged. A Godot headless test exercises both travel directions in actual level geometry.

**Tech Stack:** Godot 4.7.2, GDScript, TileSet collision polygons, headless SceneTree tests.

**Spec:** `docs/superpowers/specs/2026-11-26-stair-collision-design.md`

## Global Constraints

- Do not alter sprite or frame assets.
- Preserve existing local edits; modify only collision relevant to stair route and test files.
- Do not change movement speed, jump behavior, or broad player physics settings.

## Review Focus

- Ascending from lower ground must cross tile edge and ramp without snagging; test upward traversal in `tests/player_ramp_test.gd`.
- Descending must remain grounded on stair contour without visible gaps; test reverse traversal and grounded state in `tests/player_ramp_test.gd`.
- Adjacent upper platform must connect cleanly without a side-wall stop; test endpoint position on both directions.
- Existing non-stair ground/platform collision must remain intact; run existing project tests.
- Collision edits must not remove art; inspect diff and open/load scene with Godot editor.

---

### Task 1: Verify bidirectional traversal

**Files:**
- Modify: `tests/player_ramp_test.gd`
- Modify: `scenes/levels/level_1.tscn`

**Interfaces:**
- Consumes: Actual level's `Player`, `TileMapLayer`, `Ground`, and stair collision surfaces.
- Produces: Test coverage for successful upward and downward traversal, grounded state, and bounded vertical deviation.

- [ ] **Step 1: Remove diagnostic-only modifications from test setup**

Do not force `floor_max_angle`; test default player physics. Keep meaningful collision position diagnostics only if assertions fail.

- [ ] **Step 2: Add downward traversal test and explicit ascent assertions**

Test starts at lower stair approach, moves right over stairs to upper platform, then turns and moves left back down. Assert x crosses both route endpoints, player remains grounded, and vertical position follows expected stair height rather than floating.

- [ ] **Step 3: Run test to verify failing behavior**

Run: `godot --headless --path . --script tests/player_ramp_test.gd`
Expected: FAIL at ascent before collision correction; preserve actual stopping location and collider as diagnostic evidence.

- [ ] **Step 4: Inspect stair tile positions and collision polygons in `scenes/levels/level_1.tscn`**

Map the tile coordinates on the route and identify full-square polygons whose vertical sides intersect player approach. Limit edit to those route tiles and ramp/platform joins.

- [ ] **Step 5: Replace blocking side collision with contour-following stair collision**

Set polygons per route tile so collision top follows visible stair surface, adjacent polygons share edges, no upward-facing gaps remain, and side faces do not block traversal. Preserve unrelated tile collisions and existing unmodified local work.

- [ ] **Step 6: Run traversal test to verify both directions pass**

Run: `godot --headless --path . --script tests/player_ramp_test.gd`
Expected: `ALL TESTS PASSED`, with player grounded and within asserted stair contour during ascent and descent.

- [ ] **Step 7: Run full project verification**

Run all `tests/*_test.gd` with Godot headless and `godot --headless --path . --editor --quit`.
Expected: all tests pass; editor exits without scene/resource errors.

- [ ] **Step 8: Review diff for scope and whitespace errors**

Run: `git diff --check` and inspect `git diff -- scenes/levels/level_1.tscn tests/player_ramp_test.gd`.
Expected: only stair collision and traversal test changes; no unrelated scene/art edits.
