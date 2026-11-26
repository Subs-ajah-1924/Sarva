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
	for _frame in count:
		await physics_frame

func _move_player(player: CharacterBody2D, action: String, frames: int) -> void:
	Input.action_press(action)
	await _physics_frames(frames)
	Input.action_release(action)
	await physics_frame

func _run() -> void:
	var level := (load("res://scenes/levels/level_1.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await physics_frame
	var player := level.get_node("Player") as CharacterBody2D
	for child in level.get_children():
		if child != player and child.has_method("take_hit"):
			child.queue_free()

	player.global_position = Vector2(570.0, 223.5)
	await _physics_frames(20)
	await _move_player(player, "move_right", 120)
	var top_position := player.global_position
	_check(top_position.x > 705.0, "player ascends stairs onto upper platform; end=%s" % top_position)
	_check(player.is_on_floor(), "player remains grounded at top of stairs")

	await _move_player(player, "move_left", 120)
	var bottom_position := player.global_position
	_check(bottom_position.x < 570.0, "player descends stairs to lower ground; end=%s" % bottom_position)
	_check(player.is_on_floor(), "player remains grounded after descending stairs")
	_check(absf(bottom_position.y - 239.0) < 3.0, "player returns to lower ground height without floating; end=%s" % bottom_position)

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
