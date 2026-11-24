# Sarva

Platformer hack & slash 2D, pixel art, target Android landscape.

- Godot: 4.7
- Renderer: Compatibility (GL)
- Resolusi dasar: 480x270, stretch canvas_items / expand
- Orientasi: sensor landscape
- Texture filter: Nearest

## Struktur

```
assets/
  audio/
    music/            BGM
    sfx/
      char/           suara pemain (jump, dash, damage, dll)
      sword/          suara serangan
      ui/             klik, teks
      enemy/          suara musuh/boss
  fonts/              font game
  sprites/
    player/           karakter utama + ikon
    enemies/
      knight/         sprite knight (musuh)
      slime/          sprite slime
    environment/
      castle/         tileset kastil
      torch/          obor
    ui/               joystick, tombol
    items/            item/ikon
scenes/
  levels/             level & stage
  characters/         scene pemain
  enemies/            scene musuh
  ui/                 HUD, menu, joystick
  effects/            partikel, hit effect
scripts/
  player/             movement, combat, health
  enemies/            AI, state machine musuh
  systems/            game manager, save, audio, scene loader
  ui/                 logika HUD/menu
shaders/              shader custom
themes/               Theme resource UI
docs/                 desain & catatan
```

## Action input

`move_left`, `move_right`, `jump`, `attack`, `pause`.

Kontrol keyboard: `A`/`←` kiri, `D`/`→` kanan, `Space`/`W` lompat, `X` serang, `Shift`/`K` dash.

## Movement

- Kecepatan lari: 180 px/s (akselerasi 1400, friksi 1500).
- Dash: 420 px/s selama 0.18 dtk, cooldown 0.6 dtk, arah ikut hadap/input, gravitasi ditahan saat dash.
- Dash membatalkan serangan; tidak bisa dash saat hurt.

## Combat (tanpa HP)

- Player: serangan normal (`attack`) → windup 0.07 dtk, active 0.10 dtk, recovery 0.25 dtk. Tiap musuh kena sekali per ayunan.
  - Tekan `J` dua kali cepat → combo Attack 2 (animasi 8 frame @18 fps, SFX hit `sword/attack combo keno musuh.mp3`, miss `sword/basic attack rk keno.wav`).
  - Hit: hitstop 0.05 dtk (time scale 0.06), screen shake 0.10 dtk, hitspark, SFX `char/keno damage.mp3`, flash putih pada musuh.
  - Miss: SFX `sword/basic attack rk keno.wav`.
- Animasi serangan dipercepat: Attack 1/2 @18 fps.
- Slime: mengejar player dalam radius 140 px, menyerang dalam radius 30 px (windup 0.3 dtk, cooldown 1.4 dtk). Kena serangan: animasi `hurt` + knockback, kebal 0.5 dtk.
- Goblin: lebih cepat (80 px/s, deteksi 160 px, serang radius 34 px, windup 0.2 dtk, cooldown 1.0 dtk). Kena serangan: `hurt` + knockback 140, kebal 0.5 dtk.
- Skeleton: lebih lambat dan tangguh (55 px/s, deteksi 150 px, serang radius 38 px, windup 0.35 dtk, cooldown 1.5 dtk). Kena serangan: `hurt` + knockback 110, kebal 0.5 dtk.
- Tidak ada HP, damage, atau kematian. Musuh tidak bisa mati.

## Tes

```
godot --headless --script tests/player_test.gd
godot --headless --script tests/combat_test.gd
godot --headless --script tests/dash_test.gd
godot --headless --script tests/enemy_variants_test.gd
```

## Jalankan

```
godot --path . -e     # buka editor
godot --path .        # jalankan game
```
