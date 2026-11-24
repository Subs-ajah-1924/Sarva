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
	var expected := {"Slime": 2, "Goblin": 3, "Skeleton": 4}
	for enemy_name in expected:
		var packed := load("res://scenes/enemies/%s.tscn" % enemy_name.to_lower()) as PackedScene
		var enemy := packed.instantiate() as CharacterBody2D
		root.add_child(enemy)
		await physics_frame
		var max_health_ok: bool = enemy.get("max_health") == expected[enemy_name]
		var attack_damage_ok: bool = enemy.get("attack_damage") == 1
		var health_ok: bool = enemy.get("health") == expected[enemy_name]
		var take_hit_callable := Callable(enemy, "take_hit")
		var take_hit_ok := enemy.has_method("take_hit") and take_hit_callable.get_argument_count() == 2
		var signals_ok := enemy.has_signal("health_changed") and enemy.has_signal("died")
		_check(max_health_ok, "%s max HP is configured" % enemy_name)
		_check(attack_damage_ok, "%s attack damage is 1" % enemy_name)
		_check(health_ok, "%s starts at max HP" % enemy_name)
		_check(take_hit_ok, "%s accepts damage with direction and amount" % enemy_name)
		_check(signals_ok, "%s exposes health and death signals" % enemy_name)
		var animations_ok: bool = enemy.get_node("AnimatedSprite2D").sprite_frames.has_animation("death")
		_check(animations_ok, "%s has death animation frames" % enemy_name)
		if not (max_health_ok and attack_damage_ok and health_ok and take_hit_ok and signals_ok):
			enemy.queue_free()
			continue

		var accepted: bool = enemy.take_hit(1, 1)
		_check(accepted, "%s accepts first hit" % enemy_name)
		_check(enemy.get("health") == expected[enemy_name] - 1, "%s loses one HP" % enemy_name)
		_check(not enemy.take_hit(1, 1), "%s rejects hit during i-frames" % enemy_name)
		_check(not enemy.take_hit(1, 99), "%s rejects repeated hit during i-frames" % enemy_name)
		await _physics_frames(35)
		var lethal_damage: int = int(enemy.get("health")) + 99
		var died_count := [0]
		enemy.died.connect(func(_actor): died_count[0] += 1)
		var lethal: bool = enemy.take_hit(1, lethal_damage)
		var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		_check(lethal, "%s accepts lethal hit" % enemy_name)
		_check(died_count[0] == 1, "%s emits death once" % enemy_name)
		_check(not enemy.take_hit(1, lethal_damage), "%s rejects repeat lethal hit while dying" % enemy_name)
		_check(died_count[0] == 1 and sprite.animation == "death", "%s does not restart death animation" % enemy_name)
		_check(enemy.get("collision_layer") == 0, "%s disables body collision on death" % enemy_name)
		var attack_area := enemy.get_node_or_null("AttackHitbox") as Area2D
		_check(attack_area == null or not attack_area.monitoring, "%s disables attack hitbox on death" % enemy_name)
		_check(sprite != null and sprite.animation == "death", "%s plays death animation" % enemy_name)
		if enemy.is_inside_tree():
			await _physics_frames(100)
		_check(not is_instance_valid(enemy), "%s frees after death animation" % enemy_name)

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
