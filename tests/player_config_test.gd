extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

func _run() -> void:
	var player_scene := load("res://scenes/characters/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	root.add_child(player)
	await process_frame

	var impact_sfx := player.get_node("HitSfx") as AudioStreamPlayer
	var swing_sfx := player.get_node("MissSfx") as AudioStreamPlayer
	_check(is_equal_approx(impact_sfx.volume_db, -2.0), "sword impact SFX volume is -2 dB")
	_check(is_equal_approx(swing_sfx.volume_db, -8.0), "sword swing SFX volume is -8 dB")

	var attack_has_x := false
	var attack_has_j := false
	for event in InputMap.action_get_events("attack"):
		if event is InputEventKey:
			attack_has_x = attack_has_x or event.physical_keycode == KEY_X
			attack_has_j = attack_has_j or event.physical_keycode == KEY_J
	_check(attack_has_x, "attack action is bound to X")
	_check(not attack_has_j, "attack action is no longer bound to J")

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
