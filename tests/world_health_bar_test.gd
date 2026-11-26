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
	var packed := load("res://scenes/ui/world_health_bar.tscn") as PackedScene
	_check(packed != null, "world health bar scene loads")
	if packed != null:
		var bar := packed.instantiate()
		root.add_child(bar)
		_check(bar.has_method("set_health"), "health bar exposes set_health")
		if bar.has_method("set_health"):
			bar.set_health(2, 4)
			_check(is_equal_approx(bar.health_ratio, 0.5), "half health renders at half ratio")
			bar.set_health(-1, 4)
			_check(is_equal_approx(bar.health_ratio, 0.0), "negative current health clamps to empty")
			bar.set_health(8, 4)
			_check(is_equal_approx(bar.health_ratio, 1.0), "current health above maximum clamps to full")
			bar.set_health(1, 0)
			_check(is_equal_approx(bar.health_ratio, 0.0), "zero maximum health renders empty")
		bar.queue_free()
		for enemy_path in ["slime", "goblin", "skeleton"]:
			var enemy_scene := load("res://scenes/enemies/%s.tscn" % enemy_path) as PackedScene
			var enemy := enemy_scene.instantiate()
			_check(enemy.get_node_or_null("WorldHealthBar") != null, "%s owns reusable health bar child" % enemy_path)
			enemy.queue_free()

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
