extends SceneTree
func _init(): call_deferred("_run")
func _run():
	var scene = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Player")
	for c in scene.get_children():
		if c != player and c.has_method("take_hit"): c.queue_free()
	await physics_frame
	# mimic dash test left part
	Input.action_press("move_left")
	for i in 10: await physics_frame
	Input.action_release("move_left")
	for i in 40:
		await physics_frame
		if i%10==0: printerr("i",i,"facing",player.facing,"vx",player.velocity.x,"anim",player.get_node("AnimatedSprite2D").animation)
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	await physics_frame
	printerr("FINAL facing",player.facing,"vx",player.velocity.x)
	quit()
