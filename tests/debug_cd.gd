extends SceneTree
func _init(): call_deferred("_run")
func _run():
	var scene = load("res://scenes/levels/level_1.tscn").instantiate()
	root.add_child(scene)
	var player = scene.get_node("Player")
	for c in scene.get_children():
		if c != player and c.has_method("take_hit"): c.queue_free()
	await physics_frame
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	for i in 70:
		await physics_frame
		if i%10==0: printerr("i",i,"dashing",player.dashing,"cd",player.dash_cooldown,"slide",player._slide_ending)
	quit()
