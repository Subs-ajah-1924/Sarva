extends SceneTree
func _init(): call_deferred("_run")
func _run():
	var scene = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Player")
	var sprite = player.get_node("AnimatedSprite2D")
	for c in scene.get_children():
		if c != player and c.has_method("take_hit"): c.queue_free()
	await physics_frame
	Input.action_press("move_right")
	for i in 30: await physics_frame
	Input.action_release("move_right")
	for i in 30: await physics_frame
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	await physics_frame
	printerr("after dash dashing=",player.dashing,"cd=",player.dash_cooldown)
	for i in 2: await physics_frame
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	await physics_frame
	printerr("second dash dashing=",player.dashing,"cd=",player.dash_cooldown,"anim=",sprite.animation)
	quit()
