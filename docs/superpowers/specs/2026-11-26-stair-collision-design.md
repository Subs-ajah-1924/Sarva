# Stair Collision Design

- Intent: Make the staircase in `scenes/levels/level_1.tscn` traversable in both directions without snagging or visibly floating.
- Goal: Replace blocking full-tile side collision around the stair path with collision surfaces that follow stair tops and join existing ramp/platform surfaces continuously.
- Non-goals: Change art, movement speed, jump behavior, unrelated tile collision, or broad player physics settings.
- Approaches: Considered raising `floor_max_angle`, using a single invisible ramp, or fitting collision to the stair tile contours. Raising the angle does not fix the observed tile-wall collision; a single ramp conflicts with tile sides and can create a gap. Use tile contour collision and preserve the existing ramp where it connects cleanly.
- Constraints: Keep existing local changes in `level_1.tscn`, `player.tscn`, and `player.gd`; adjust only collision necessary for the stairs and test both travel directions on the real level.
- Builder calls: Prefer continuous low-profile top surfaces and remove blocking side faces only for tiles along the stair route. Do not alter sprite/frame assets.
