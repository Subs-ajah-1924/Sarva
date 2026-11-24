extends SceneTree

# Headless behavior test for combat: player attack + slime enemy (no HP system).
# Run: godot --headless --script tests/combat_test.gd

var failures: int = 0
var level: Node
var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var slime: CharacterBody2D
var slime_sprite: AnimatedSprite2D


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1


func _physics_frames(count: int) -> void:
	for i in count:
		await physics_frame


func _run() -> void:
	level = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(level)
	await physics_frame

	player = level.get_node_or_null("Player") as CharacterBody2D
	slime = level.get_node_or_null("Slime") as CharacterBody2D
	_check(player != null, "level contains the player")
	_check(slime != null, "level contains a slime enemy")
	if player == null or slime == null:
		quit(1)
		return

	player_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	slime_sprite = slime.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(player_sprite != null, "player has an AnimatedSprite2D")
	_check(slime_sprite != null, "slime has an AnimatedSprite2D")
	if player_sprite == null or slime_sprite == null:
		quit(1)
		return

	player.global_position = Vector2(80, 200)
	slime.global_position = Vector2(260, 200)
	await _physics_frames(70)
	_check(player.is_on_floor() and slime.is_on_floor(), "both actors stand on the ground")
	_check(slime_sprite.animation == "idle", "slime idles while player is out of range")

	slime.global_position = Vector2(220, 200)
	await _physics_frames(2)
	var shim_x := slime.global_position.x
	await _physics_frames(40)
	_check(slime.global_position.x < shim_x - 2.0, "slime walks toward the player")

	# --- player normal attack ---
	slime.global_position = player.global_position + Vector2(28, 0)
	await _physics_frames(2)
	Input.action_press("move_right")
	await _physics_frames(2)
	Input.action_release("move_right")
	var slime_hit_x := slime.global_position.x

	Input.action_press("attack")
	await _physics_frames(2)
	Input.action_release("attack")
	var slime_hurt := false
	for i in 25:
		await physics_frame
		if slime_sprite.animation == "hurt":
			slime_hurt = true
			break
	_check(player_sprite.animation == "attack", "player plays the attack animation")
	_check(slime_hurt, "slime plays its hurt animation when hit")
	_check(slime.global_position.x > slime_hit_x + 1.0, "slime is knocked away by the player attack")

	await _physics_frames(120)
	_check(is_instance_valid(slime) and slime.get("health") == 1, "slime survives one hit with one HP remaining")

	# --- slime attack ---
	player.global_position = Vector2(80, 200)
	slime.global_position = Vector2(108, 200)
	await _physics_frames(10)
	var player_hp_before_slime: int = player.get("health")

	var player_hurt := false
	var slime_attacked := false
	for i in 240:
		await physics_frame
		if slime_sprite.animation == "attack":
			slime_attacked = true
		if player_sprite.animation == "hurt":
			player_hurt = true
			break

	_check(slime_attacked, "slime plays its attack animation")
	_check(player_hurt, "slime attack puts the player in hurt state")
	_check(player.get("health") == player_hp_before_slime - 1, "slime attack removes exactly one player HP")

	var knocked_x := player.global_position.x
	await _physics_frames(10)
	_check(player.global_position.x < knocked_x - 1.0, "player is knocked back by the slime attack")

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		push_error("%d test(s) failed" % failures)
	quit(1 if failures > 0 else 0)
