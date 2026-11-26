# Healing Animation Overlay Design

- **Intent:** Show existing healing effect when player spends one energy to restore one HP.
- **Approach:** Restore `HealingSprite` as an `AnimatedSprite2D` overlay using existing `player_frames.tres` and its `healing` animation. Playing animation on main player sprite would replace locomotion/combat animation, so overlay is preferred.
- **Constraints:** Keep existing sprite sheet and animation frames unchanged. Healing effect only appears after successful heal; no effect when energy is empty or HP is full. Preserve existing `E` binding and one-energy/one-HP behavior.
- **Scope:** Update `scenes/characters/player.tscn` and verify heal visual behavior. Do not modify texture assets.
