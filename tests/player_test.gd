extends SceneTree

# Headless behavior test for the player vertical slice.
# Run: godot --headless --script tests/player_test.gd

var failures: int = 0
var level: Node
var player: CharacterBody2D
var sprite: AnimatedSprite2D


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
	_check(player != null, "level contains a Player CharacterBody2D")
	if player == null:
		quit(1)
		return

	sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(sprite != null, "player has an AnimatedSprite2D")

	for child in level.get_children():
		if child != player and child.has_method("take_hit"):
			child.queue_free()
	await physics_frame

	player.global_position = Vector2(80, 180)
	await _physics_frames(70)
	_check(player.is_on_floor(), "player falls and lands on the ground")
	_check(absf(player.global_position.y - 240.0) < 2.0, "player feet rest on top of the ground")

	if sprite == null:
		quit(1)
		return

	_check(sprite.animation == "idle" and sprite.is_playing(), "player plays idle animation when standing")

	var start_x := player.global_position.x
	Input.action_press("move_right")
	await _physics_frames(30)
	_check(player.global_position.x > start_x + 20.0, "move_right moves player right")
	_check(sprite.animation == "run", "player plays run animation while moving")
	_check(not sprite.flip_h, "sprite faces right when moving right")
	Input.action_release("move_right")

	await _physics_frames(40)
	_check(absf(player.velocity.x) < 1.0, "player stops when input released")
	_check(player.is_on_floor(), "player stays on the ground while running")
	_check(sprite.animation == "idle", "player returns to idle animation when stopped")

	Input.action_press("move_left")
	await _physics_frames(10)
	Input.action_release("move_left")
	_check(sprite.flip_h, "sprite faces left when moving left")
	await _physics_frames(40)

	Input.action_press("jump")
	await _physics_frames(6)
	Input.action_release("jump")
	_check(player.velocity.y < 0.0, "jump gives upward velocity")
	_check(player.global_position.y < 239.0, "player leaves the ground when jumping")
	_check(sprite.animation == "jump", "player plays jump animation while rising")

	await _physics_frames(30)
	_check(player.velocity.y > 0.0, "player starts falling after jump apex")
	_check(sprite.animation == "fall", "player plays fall animation while falling")

	await _physics_frames(90)
	_check(player.is_on_floor(), "player lands again after jumping")
	_check(sprite.animation == "idle", "player returns to idle after landing")

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		push_error("%d test(s) failed" % failures)
	quit(1 if failures > 0 else 0)
