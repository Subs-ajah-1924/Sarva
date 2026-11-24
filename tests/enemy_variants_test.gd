extends SceneTree

# Headless behavior test for the goblin and skeleton enemies.
# Run: godot --headless --script tests/enemy_variants_test.gd

var failures: int = 0
var level: Node
var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var goblin: CharacterBody2D
var goblin_sprite: AnimatedSprite2D
var skeleton: CharacterBody2D
var skeleton_sprite: AnimatedSprite2D


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


func _wait_for_player_hurt(max_frames: int) -> bool:
	for i in max_frames:
		await physics_frame
		if player_sprite.animation == "hurt":
			return true
	return false


func _wait_player_recovered(max_frames: int) -> void:
	for i in max_frames:
		await physics_frame
		if player_sprite.animation != "hurt":
			await _physics_frames(5)
			return


func _run() -> void:
	level = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(level)
	await physics_frame

	player = level.get_node_or_null("Player") as CharacterBody2D
	goblin = level.get_node_or_null("Goblin") as CharacterBody2D
	skeleton = level.get_node_or_null("Skeleton") as CharacterBody2D
	_check(player != null, "level contains the player")
	_check(goblin != null, "level contains a goblin")
	_check(skeleton != null, "level contains a skeleton")
	if player == null or goblin == null or skeleton == null:
		quit(1)
		return

	player_sprite = player.get_node("AnimatedSprite2D")
	goblin_sprite = goblin.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	skeleton_sprite = skeleton.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(goblin_sprite != null, "goblin has an AnimatedSprite2D")
	_check(skeleton_sprite != null, "skeleton has an AnimatedSprite2D")
	if goblin_sprite == null or skeleton_sprite == null:
		quit(1)
		return

	var slime := level.get_node_or_null("Slime")
	if slime != null:
		slime.queue_free()

	player.global_position = Vector2(80, 200)
	goblin.global_position = Vector2(420, 200)
	skeleton.global_position = Vector2(520, 200)
	await _physics_frames(70)

	_check(player.is_on_floor() and goblin.is_on_floor() and skeleton.is_on_floor(),
			"player, goblin, and skeleton stand on the ground")

	for enemy_name in ["goblin", "skeleton"]:
		var frames: SpriteFrames = goblin_sprite.sprite_frames if enemy_name == "goblin" else skeleton_sprite.sprite_frames
		for animation in ["idle", "walk", "attack", "hurt"]:
			_check(frames.has_animation(animation) and frames.get_frame_count(animation) > 0,
					"%s has a %s animation" % [enemy_name, animation])

	_check(goblin_sprite.animation == "idle", "goblin idles while player is far")
	_check(skeleton_sprite.animation == "idle", "skeleton idles while player is far")

	# --- goblin chase ---
	goblin.global_position = Vector2(200, 200)
	await _physics_frames(40)
	_check(goblin.global_position.x < 198.0, "goblin walks toward the player")

	# --- player attack hurts goblin ---
	goblin.global_position = player.global_position + Vector2(28, 0)
	await _physics_frames(2)
	Input.action_press("move_right")
	await _physics_frames(2)
	Input.action_release("move_right")
	var goblin_x := goblin.global_position.x
	Input.action_press("attack")
	await _physics_frames(2)
	Input.action_release("attack")
	var goblin_hurt := false
	for i in 30:
		await physics_frame
		if goblin_sprite.animation == "hurt":
			goblin_hurt = true
			break
	_check(goblin_hurt, "goblin plays its hurt animation when hit")
	_check(goblin.global_position.x > goblin_x + 1.0, "goblin is knocked away by the player attack")

	await _physics_frames(120)
	_check(is_instance_valid(goblin) and goblin.get("health") == 2, "goblin survives one hit with two HP remaining")

	# --- goblin attacks the player ---
	goblin.global_position = Vector2(420, 200)
	player.global_position = Vector2(80, 200)
	await _physics_frames(60)
	await _wait_player_recovered(180)
	var player_hp_before_goblin: int = player.get("health")
	goblin.global_position = Vector2(108, 200)
	await _physics_frames(10)
	_check(await _wait_for_player_hurt(180), "goblin attacks and hurts the player")
	_check(player.get("health") == player_hp_before_goblin - 1, "goblin attack removes exactly one player HP")

	goblin.queue_free()
	await physics_frame

	# --- skeleton chase ---
	player.global_position = Vector2(80, 200)
	skeleton.global_position = Vector2(210, 200)
	await _physics_frames(80)
	_check(skeleton.global_position.x < 208.0, "skeleton walks toward the player")

	# --- player attack hurts skeleton ---
	skeleton.global_position = player.global_position + Vector2(30, 0)
	await _physics_frames(2)
	Input.action_press("move_right")
	await _physics_frames(2)
	Input.action_release("move_right")
	var skeleton_x := skeleton.global_position.x
	Input.action_press("attack")
	await _physics_frames(2)
	Input.action_release("attack")
	var skeleton_hurt := false
	for i in 45:
		await physics_frame
		if skeleton_sprite.animation == "hurt":
			skeleton_hurt = true
			break
	_check(skeleton_hurt, "skeleton plays its hurt animation when hit")
	_check(skeleton.global_position.x > skeleton_x + 1.0, "skeleton is knocked away by the player attack")

	await _physics_frames(120)
	_check(is_instance_valid(skeleton) and skeleton.get("health") == 3, "skeleton survives one hit with three HP remaining")
	printerr("DEBUG after survival p=%s v=%s s=%s" % [player.global_position, player.velocity, skeleton.global_position])

	# --- skeleton attacks the player ---
	skeleton.global_position = Vector2(520, 200)
	player.global_position = Vector2(80, 240)
	player.velocity = Vector2.ZERO
	for a in ["move_left", "move_right", "attack", "jump", "dash"]:
		Input.action_release(a)
	await _physics_frames(5)
	await _wait_player_recovered(180)
	skeleton.global_position = Vector2(110, 200)
	await _physics_frames(10)
	var skeleton_attack_seen := false
	var skeleton_hurt_player := false
	var player_hp_before_skeleton: int = player.get("health")
	for i in 180:
		await physics_frame
		if skeleton.attacking:
			skeleton_attack_seen = true
		if player_sprite.animation == "hurt":
			skeleton_hurt_player = true
			break
	_check(skeleton_attack_seen, "skeleton plays its attack animation")
	_check(skeleton_hurt_player, "skeleton attacks and hurts the player")
	_check(player.get("health") == player_hp_before_skeleton - 1, "skeleton attack removes exactly one player HP")

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		push_error("%d test(s) failed" % failures)
	quit(1 if failures > 0 else 0)
