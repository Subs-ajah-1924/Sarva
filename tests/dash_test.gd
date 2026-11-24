extends SceneTree

# Headless behavior test for faster movement + dash.
# Run: godot --headless --script tests/dash_test.gd

const DASH_MIN_SPEED := 300.0

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


func _release_all() -> void:
	for action in ["move_left", "move_right", "attack", "jump", "dash"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _run() -> void:
	level = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(level)
	await physics_frame

	player = level.get_node_or_null("Player") as CharacterBody2D
	_check(player != null, "level contains the player")
	if player == null:
		quit(1)
		return
	sprite = player.get_node("AnimatedSprite2D")
	_check(InputMap.has_action("dash"), "input map has a dash action")

	for child in level.get_children():
		if child != player and child.has_method("take_hit"):
			child.queue_free()
	await physics_frame

	player.global_position = Vector2(120, 180)
	await _physics_frames(70)
	_check(player.is_on_floor(), "player stands on the ground")

	# Faster run speed.
	var run_start := player.global_position.x
	Input.action_press("move_right")
	await _physics_frames(30)
	Input.action_release("move_right")
	var run_distance := player.global_position.x - run_start
	_check(run_distance > 70.0, "player runs faster than before (%.1f px in 30 frames)" % run_distance)

	await _physics_frames(30)
	_check(sprite.animation == "idle", "player is idle before dash")

	# Ground dash to the right.
	Input.action_press("dash")
	await _physics_frames(2)
	Input.action_release("dash")
	_check(player.dashing, "pressing dash starts a dash")
	_check(absf(player.velocity.x) > DASH_MIN_SPEED, "dash speed is faster than running")
	_check(sprite.animation in ["slide_start", "dash"], "player plays the dash animation")

	var dash_start := player.global_position.x
	await _physics_frames(10)
	_check(player.global_position.x > dash_start + 25.0, "dash moves the player forward")

	await _physics_frames(15)
	_check(not player.dashing, "dash ends after its duration")

	# Cooldown blocks an immediate second dash.
	Input.action_press("dash")
	await _physics_frames(2)
	Input.action_release("dash")
	_check(not player.dashing, "dash cannot be spammed during cooldown")

	await _physics_frames(45)
	Input.action_press("dash")
	await _physics_frames(2)
	Input.action_release("dash")
	_check(player.dashing, "dash is available again after cooldown")

	# Dash follows facing direction.
	player.global_position = Vector2(250, 180)
	await _physics_frames(70)
	await _physics_frames(40)
	Input.action_press("move_left")
	await _physics_frames(10)
	Input.action_release("move_left")
	await _physics_frames(40)
	Input.action_press("dash")
	await _physics_frames(2)
	Input.action_release("dash")
	_check(player.dashing and player.velocity.x < -DASH_MIN_SPEED, "dash goes left when facing left")

	_release_all()

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		push_error("%d test(s) failed" % failures)
	quit(1 if failures > 0 else 0)
