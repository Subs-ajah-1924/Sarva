extends SceneTree
func _init(): call_deferred("_run")
func _run():
	var scene = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Player")
	for c in scene.get_children():
		if c != player and c.has_method("take_hit"): c.queue_free()
	await physics_frame
	player.global_position = Vector2(80,239)
	for i in 30: await physics_frame
	printerr("before press just_pressed=", Input.is_action_just_pressed("attack"), " pressed=", Input.is_action_pressed("attack"))
	Input.action_press("attack")
	await physics_frame
	printerr("after press just_pressed=", Input.is_action_just_pressed("attack"), " pressed=", Input.is_action_pressed("attack"))
	Input.action_release("attack")
	quit()
