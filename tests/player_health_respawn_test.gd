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

func _release_all() -> void:
	for action in ["move_left", "move_right", "attack", "jump", "dash"]:
		Input.action_release(action)

func _run() -> void:
	var level: Node = (load("res://scenes/levels/level_1.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await physics_frame
	var player: Node = level.get_node_or_null("Player")
	var enemy: Node = level.get_node_or_null("Slime")
	_check(player != null, "level instantiates player")
	if player == null:
		quit(1)
		return
	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var attack_area := player.get_node("AttackHitbox") as Area2D
	var spawn: Vector2 = player.global_position
	_check(player.get("max_health") == 5, "player has five max HP")
	_check(player.get("health") == 5, "player starts at full HP")
	_check(player.get("spawn_position") == spawn, "spawn position captures level instance placement")
	_check(player.get_node_or_null("WorldHealthBar") != null, "player has reusable health bar child")
	_check(sprite.sprite_frames.has_animation("death"), "player has death animation frames")

	# Enemy hit and post-hit invulnerability are separate from hurt stun.
	var hit_accepted: bool = player.take_hit(1, 1)
	_check(hit_accepted and player.get("health") == 4, "enemy hit removes one HP")
	_check(player.get("is_invulnerable"), "player gains post-hit invulnerability")
	_check(not player.take_hit(1, 1), "repeated hit during post-hit i-frames is rejected")
	_check(player.get("health") == 4, "rejected hit preserves HP")
	_check(is_equal_approx(player.get("hurt_time"), 0.35), "hurt stun remains distinct from invulnerability")
	await _physics_frames(50)
	_check(not player.get("is_invulnerable"), "post-hit invulnerability ends after 0.5 seconds")

	# Dash grants its existing 0.18-second invulnerability window.
	_release_all()
	await _physics_frames(30)
	Input.action_press("dash")
	await _physics_frames(2)
	Input.action_release("dash")
	_check(player.get("dashing"), "dash starts")
	_check(player.get("is_invulnerable"), "dash grants i-frames")
	_check(not player.take_hit(1, 1), "damage during dash i-frames is rejected")
	_check(player.get("health") == 4, "dash i-frames preserve HP")
	await _physics_frames(12)
	_check(not player.get("dashing"), "dash ends after 0.18 seconds")
	_check(not player.get("is_invulnerable"), "dash i-frames end with dash")
	if enemy != null:
		enemy.global_position = Vector2(420, 200)

	# Lethal damage emits one death event and disables player controls.
	var deaths := [0]
	player.died.connect(func(_actor): deaths[0] += 1)
	player.set("hurt_time", 0.2)
	player.set("_recovering", true)
	var lethal_hit: bool = player.take_hit(1, 99)
	_check(lethal_hit and player.get("dead"), "lethal damage enters dead state")
	_check(deaths[0] == 1, "death emits once")
	_check(not player.take_hit(1, 99), "dead player rejects further damage")
	player.die()
	_check(deaths[0] == 1, "repeated die call does not emit again")
	_check(sprite.animation == "death", "player plays death animation")
	await physics_frame
	_check(not attack_area.monitoring, "death disables attack monitoring")
	_check(player.get("collision_layer") == 1, "death keeps player collision layer for kill-zone detection")
	_check(player.get("collision_mask") == 0, "death disables player collision mask")
	_check(sprite.animation == "death", "hurt state does not replace death animation")
	_check(not player.get("_recovering") and player.get("hurt_time") == 0.0, "death clears hurt and recovery state")
	_check(not player.get("attacking") and not player.get("dashing"), "death clears attack and dash")

	# Respawn resets all combat state and restores full health at captured spawn.
	player.velocity = Vector2(80, -120)
	player.set("attacking", true)
	player.set("dashing", true)
	player.set("hurt_time", 0.2)
	player.set("dash_cooldown", 2.0)
	player.set("attack_time", 0.2)
	player.respawn(spawn)
	_check(not player.get("dead"), "respawn clears dead state")
	_check(player.global_position == spawn, "respawn returns to saved start")
	_check(player.get("health") == 5, "respawn restores full HP")
	_check(player.velocity == Vector2.ZERO, "respawn clears velocity")
	_check(not player.get("attacking") and not player.get("dashing"), "respawn clears attack and dash")
	_check(is_zero_approx(player.get("hurt_time")), "respawn clears hurt stun")
	_check(not player.get("is_invulnerable"), "respawn clears i-frames")
	_check(not attack_area.monitoring, "respawn leaves attack hitbox inactive")
	_check(player.get("dash_cooldown") == 0.0, "respawn clears dash cooldown")
	_check(sprite.animation != "death", "respawn exits death animation")
	_check(not attack_area.monitorable, "respawn preserves original attack-hitbox monitorable state")
	_check(player.get("collision_layer") == 1 and player.get("collision_mask") == 3, "respawn restores original player collision settings")
	_check(is_instance_valid(enemy), "surviving enemy remains in level")
	player.die()
	for i in 200:
		await physics_frame
		if not player.get("dead"):
			break
	_check(not player.get("dead"), "player automatically respawns after death animation")
	_check(player.get("spawn_position") == spawn and player.get("health") == 5, "automatic respawn restores saved start and full HP")

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
