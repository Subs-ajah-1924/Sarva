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
	var player_scene := load("res://scenes/characters/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	root.add_child(player)
	await physics_frame
	var healing_sprite := player.get_node_or_null("HealingSprite") as AnimatedSprite2D
	_check(healing_sprite != null, "player scene has healing overlay")
	if healing_sprite:
		_check(healing_sprite.sprite_frames == player.get_node("AnimatedSprite2D").sprite_frames, "healing overlay reuses player frames")
		_check(healing_sprite.sprite_frames.has_animation("healing"), "healing overlay uses existing healing animation")
		_check(not healing_sprite.visible, "healing overlay starts hidden")
	_check(InputMap.has_action("heal"), "heal input action exists")
	var heal_key_bound := false
	for event in InputMap.action_get_events("heal"):
		if event is InputEventKey and event.physical_keycode == KEY_E:
			heal_key_bound = true
	_check(heal_key_bound, "heal input is bound to E")

	player.health = player.max_health - 2
	player.energy = 2
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_E
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await physics_frame
	key_event = InputEventKey.new()
	key_event.physical_keycode = KEY_E
	Input.parse_input_event(key_event)
	await physics_frame
	_check(player.health == player.max_health - 1, "heal input restores one HP")
	_check(player.energy == 1, "heal input consumes one energy")
	if healing_sprite:
		_check(healing_sprite.visible, "successful heal shows healing overlay")
		for frame in 55:
			await physics_frame
		_check(not healing_sprite.visible, "healing overlay hides when animation finishes")

	player.health = 1
	player.energy = 0
	player._try_heal()
	_check(player.health == 1 and player.energy == 0, "heal with no energy changes nothing")

	player.health = player.max_health
	player.energy = 1
	player._try_heal()
	_check(player.health == player.max_health and player.energy == 1, "heal at full health consumes no energy")

	if failures == 0:
		print("ALL TESTS PASSED")
	quit(1 if failures > 0 else 0)
