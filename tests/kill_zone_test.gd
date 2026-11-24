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

func _physics_frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	var packed := load("res://scenes/levels/level_1.tscn") as PackedScene
	var level := packed.instantiate()
	root.add_child(level)
	await physics_frame
	var zone := level.get_node_or_null("KillZone") as Area2D
	var player := level.get_node_or_null("Player") as CharacterBody2D
	_check(zone != null, "level has a kill zone")
	_check(player != null, "level has a player")
	if zone == null or player == null:
		quit(1)
		return
	_check(zone.has_method("_on_body_entered"), "kill zone handles body entry")
	_check(zone.collision_mask == 1, "kill zone monitors player collision layer only")
	var collision_shape := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(collision_shape != null and collision_shape.shape is RectangleShape2D, "kill zone uses broad rectangle collision")
	var ground := level.get_node("Ground")
	var lowest_ground_bottom := -INF
	for child in ground.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			lowest_ground_bottom = maxf(lowest_ground_bottom, child.global_position.y + child.shape.size.y * 0.5)
	_check(zone.global_position.y - collision_shape.shape.size.y * 0.5 > lowest_ground_bottom + 32.0, "kill zone sits clear below lowest ground collider")
	var saved_spawn: Vector2 = player.get("spawn_position")
	var saved_collision_layer: int = player.collision_layer
	var saved_collision_mask: int = player.collision_mask
	_check(saved_spawn == player.global_position, "saved spawn matches placed level start")
	var died_count := [0]
	player.died.connect(func(_actor): died_count[0] += 1)

	# Non-player bodies use enemy collision layer 2 and must not trigger zone.
	var dummy := StaticBody2D.new()
	dummy.collision_layer = 2
	dummy.collision_mask = 0
	var dummy_shape := CollisionShape2D.new()
	var dummy_rect := RectangleShape2D.new()
	dummy_rect.size = Vector2(8, 8)
	dummy_shape.shape = dummy_rect
	dummy.add_child(dummy_shape)
	dummy.global_position = zone.global_position + Vector2(0, -10)
	level.add_child(dummy)
	await _physics_frames(3)
	_check(not player.get("dead") and died_count[0] == 0, "non-player body does not trigger player death")
	dummy.queue_free()

	# Player entering zone follows shared death/automatic respawn flow.
	player.global_position = zone.global_position + Vector2(0, -10)
	player.velocity = Vector2.ZERO
	player.set("hurt_time", 0.2)
	player.set("_recovering", true)
	await _physics_frames(3)
	_check(player.get("dead"), "falling into kill zone starts player death")
	_check(died_count[0] == 1, "kill zone emits one player death")
	_check(player.collision_layer == saved_collision_layer, "dying player remains on collision layer detected by kill zone")
	_check(player.collision_mask == 0, "dying player stops colliding with world and enemies")
	_check(player.get_node("AnimatedSprite2D").animation == "death", "hurt state does not overwrite death animation")
	for i in 200:
		await physics_frame
		if not player.get("dead"):
			break
	_check(not player.get("dead"), "kill-zone death automatically respawns player")
	_check(player.get("spawn_position") == saved_spawn, "kill-zone respawn uses original position")
	_check(player.global_position.distance_to(saved_spawn) < 1.0, "player returns to original position")
	_check(player.get("health") == player.get("max_health"), "kill-zone respawn restores full HP")
	_check(player.collision_layer == saved_collision_layer and player.collision_mask == saved_collision_mask, "respawn restores original player collision settings")
	_check(died_count[0] == 1, "kill zone does not retrigger after respawn at safe spawn")

	# Duplicate zone entry during death cannot schedule another death/respawn.
	player.take_hit(1, 99)
	_check(player.get("dead"), "lethal damage begins death before duplicate zone entry")
	var deaths_before_duplicate: int = died_count[0]
	zone._on_body_entered(player)
	_check(died_count[0] == deaths_before_duplicate, "zone entry during death does not emit another death")
	for i in 200:
		await physics_frame
		if not player.get("dead"):
			break
	_check(not player.get("dead") and player.get("health") == player.get("max_health"), "duplicate zone entry keeps single respawn flow")
	_check(died_count[0] == deaths_before_duplicate, "duplicate zone entry does not schedule another death")

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
