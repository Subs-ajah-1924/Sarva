extends CharacterBody2D
class_name Player

const SPEED := 180.0
const ACCELERATION := 1400.0
const FRICTION := 1500.0
const JUMP_VELOCITY := -300.0
const SPRITE_OFFSET_X := 8.0
const ATTACK_WINDUP := 0.07
const ATTACK_ACTIVE := 0.10
const ATTACK_RECOVERY := 0.25
const HURT_TIME := 0.35
const DASH_SPEED := 420.0
const DASH_TIME := 0.18
const DASH_INVULNERABILITY_TIME := DASH_TIME
const DASH_COOLDOWN := 0.6
const COMBO_WINDOW := 0.35

signal health_changed(current: int, maximum: int)
signal died(player: Player)

@export var max_health := 10
@export var post_hit_invulnerability := 0.5

var facing := 1
var hurt_time := 0.0
var health: int
var is_invulnerable := false
var invulnerability_time := 0.0
var dead := false
var spawn_position := Vector2.ZERO
var attacking := false
var attack_type := 1
var attack_time := 0.0
var hit_targets: Array[Node] = []
var dashing := false
var dash_time := 0.0
var dash_cooldown := 0.0
var _hit_this_attack := false
var _hitstop_done := false
var _attack_done := false
var _was_in_air := false
var _fall_speed := 0.0
var _landing := false
var _recovering := false
var _apex_played := false
var _air_frames := 0
var _slide_ending := false

var shake_time := 0.0
var shake_amp := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackHitbox
@onready var camera: Camera2D = $Camera2D
@onready var hit_sfx: AudioStreamPlayer = $HitSfx
@onready var miss_sfx: AudioStreamPlayer = $MissSfx
@onready var healing_sprite: AnimatedSprite2D = $HealingSprite


func _ready() -> void:
	spawn_position = global_position
	health = max_health
	health_changed.emit(health, max_health)
	sprite.animation_finished.connect(_on_animation_finished)
	hit_sfx.stream = load("res://assets/audio/sfx/char/keno damage.mp3")
	miss_sfx.stream = load("res://assets/audio/sfx/sword/basic attack rk keno.wav")
	healing_sprite.hide()


func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta / maxf(Engine.time_scale, 0.001)
		if shake_time <= 0.0:
			shake_time = 0.0
			camera.offset = Vector2.ZERO
		else:
			camera.offset = Vector2(randf_range(-shake_amp, shake_amp), randf_range(-shake_amp, shake_amp))


func _physics_process(delta: float) -> void:
	if dead:
		return
	if hurt_time > 0.0:
		hurt_time = maxf(hurt_time - delta, 0.0)
		if hurt_time <= 0.0:
			_recovering = true
	if invulnerability_time > 0.0:
		invulnerability_time = maxf(invulnerability_time - delta, 0.0)
		if invulnerability_time <= 0.0:
			is_invulnerable = false

	dash_cooldown = maxf(dash_cooldown - delta, 0.0)

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		_start_dash()
		move_and_slide()
		_update_animation()
		return

	if dashing:
		dash_time -= delta
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		if dash_time <= 0.0:
			dashing = false
			if invulnerability_time <= 0.0:
				is_invulnerable = false
		move_and_slide()
		_update_animation()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if hurt_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		_update_animation()
		return
	if _recovering:
		if sprite.animation != "knockback_recover":
			sprite.play("knockback_recover")
		move_and_slide()
		_update_animation()
		return

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		_start_dash()
		move_and_slide()
		_update_animation()
		return

	if attacking:
		_process_attack(delta)
		move_and_slide()
		_update_animation()
		return

	if Input.is_action_just_pressed("attack") and is_on_floor():
		_start_attack()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if not is_on_floor():
		_was_in_air = true
		_air_frames += 1
		_fall_speed = velocity.y
	elif _was_in_air and _air_frames > 4 and _fall_speed > 100.0 and absf(velocity.x) < 50.0:
		_landing = true
		_was_in_air = false
		_air_frames = 0
		_apex_played = false
	elif is_on_floor():
		_air_frames = 0

	move_and_slide()
	_update_animation()


func _start_dash() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
	dashing = true
	dash_time = DASH_TIME
	invulnerability_time = DASH_INVULNERABILITY_TIME
	is_invulnerable = true
	dash_cooldown = DASH_COOLDOWN
	attacking = false
	_slide_ending = false
	attack_area.monitoring = false
	velocity = Vector2(facing * DASH_SPEED, 0.0)
	sprite.play("dash")


func _start_attack() -> void:
	attacking = true
	attack_time = 0.0
	hit_targets.clear()
	_hit_this_attack = false
	_hitstop_done = false
	_attack_done = false
	sprite.play("attack")
	attack_area.position.x = 20.0 * facing
	attack_area.monitoring = false

	hit_sfx.stream = load("res://assets/audio/sfx/char/keno damage.mp3")
	miss_sfx.stream = load("res://assets/audio/sfx/sword/basic attack rk keno.wav")
	miss_sfx.stop()
	miss_sfx.play()


func _process_attack(delta: float) -> void:
	attack_time += delta
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	var in_window := attack_time >= ATTACK_WINDUP and attack_time <= ATTACK_WINDUP + ATTACK_ACTIVE
	attack_area.monitoring = in_window
	if in_window:
		for body in attack_area.get_overlapping_bodies():
			if body in hit_targets or not body.has_method("take_hit"):
				continue
			hit_targets.append(body)
			if body.take_hit(facing, 1):
				_on_hit(body)

	if attack_time >= ATTACK_WINDUP + ATTACK_ACTIVE + ATTACK_RECOVERY:
		_attack_done = true
		attacking = false
		attack_area.monitoring = false


func _on_hit(enemy: Node) -> void:
	if _hit_this_attack:
		return
	_hit_this_attack = true
	miss_sfx.stop()
	hit_sfx.play()

	shake_time = 0.10
	shake_amp = 6.0

	_spawn_hitspark(enemy.global_position + Vector2(0, -12), facing)

	if not _hitstop_done:
		_hitstop_done = true
		_do_hitstop()


func _do_hitstop() -> void:
	Engine.time_scale = 0.06
	var timer := get_tree().create_timer(0.05, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0


func take_hit(direction: int, damage: int = 1) -> bool:
	if dead or is_invulnerable or dashing:
		return false
	health = maxi(health - maxi(damage, 0), 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		die()
		return true
	is_invulnerable = true
	invulnerability_time = post_hit_invulnerability
	hurt_time = HURT_TIME
	attacking = false
	_recovering = false
	attack_area.monitoring = false
	velocity = Vector2(direction * 150.0, -120.0)
	sprite.play("hurt")
	return true

func heal(amount: int) -> int:
	var restored := mini(maxi(amount, 0), max_health - health)
	if restored <= 0:
		return 0
	health += restored
	health_changed.emit(health, max_health)
	return restored


func die() -> void:
	if dead:
		return
	dead = true
	dashing = false
	attacking = false
	hurt_time = 0.0
	_recovering = false
	attack_time = 0.0
	dash_time = 0.0
	velocity = Vector2.ZERO
	is_invulnerable = false
	invulnerability_time = 0.0
	attack_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitorable", false)
	set_deferred("collision_layer", 1)
	set_deferred("collision_mask", 0)
	for collision_shape in find_children("CollisionShape2D", "CollisionShape2D", true, false):
		collision_shape.set_deferred("disabled", true)
	died.emit(self)
	sprite.play("death")


func respawn(at: Vector2) -> void:
	global_position = at
	dead = false
	health = max_health
	health_changed.emit(health, max_health)
	velocity = Vector2.ZERO
	attacking = false
	dashing = false
	hurt_time = 0.0
	attack_time = 0.0
	dash_time = 0.0
	dash_cooldown = 0.0
	is_invulnerable = false
	invulnerability_time = 0.0
	facing = 1
	hit_targets.clear()
	_hit_this_attack = false
	_hitstop_done = false
	_attack_done = false
	_was_in_air = false
	_fall_speed = 0.0
	_landing = false
	_recovering = false
	_apex_played = false
	_air_frames = 0
	_slide_ending = false
	attack_area.set_deferred("monitoring", false)
	attack_area.set_deferred("monitorable", false)
	collision_layer = 1
	collision_mask = 3
	for collision_shape in find_children("CollisionShape2D", "CollisionShape2D", true, false):
		collision_shape.set_deferred("disabled", false)
	sprite.modulate = Color.WHITE
	sprite.play("idle")


func _on_animation_finished() -> void:
	if dead and sprite.animation == "death":
		respawn(spawn_position)
		return
	if sprite.animation == "knockback_recover":
		_recovering = false
		return
	if sprite.animation == "attack":
		attacking = false
		attack_area.monitoring = false


func _update_animation() -> void:
	if dead:
		return
	sprite.flip_h = facing < 0
	sprite.offset.x = SPRITE_OFFSET_X if facing > 0 else -SPRITE_OFFSET_X

	if hurt_time > 0.0:
		if sprite.animation != "hurt": sprite.play("hurt")
		return
	if _recovering:
		if sprite.animation != "knockback_recover":
			sprite.play("knockback_recover")
		return
	if dashing:
		if sprite.animation == "slide_start" and not sprite.is_playing():
			sprite.play("dash")
		elif sprite.animation not in ["slide_start", "dash", "slide_end"]:
			sprite.play("slide_start")
		return
	if attacking:
		if sprite.animation != "attack":
			sprite.play("attack")
		return
	if not is_on_floor():
		_apex_played = _apex_played or sprite.animation == "jump_apex"
		if velocity.y < -20.0:
			if sprite.animation != "jump":
				sprite.play("jump")
		elif velocity.y > 20.0:
			if sprite.animation != "fall":
				sprite.play("fall")
		elif not _apex_played:
			_apex_played = true
			if sprite.animation != "jump_apex":
				sprite.play("jump_apex")
		return
	if _landing:
		if sprite.animation not in ["land", "land_hard"]:
			if absf(_fall_speed) > 260.0:
				sprite.play("land_hard")
			else:
				sprite.play("land")
		if not sprite.is_playing():
			_landing = false
		else:
			return
	if absf(velocity.x) > 1.0:
		if sprite.animation == "run_stop":
			if sprite.is_playing():
				return
		if sprite.animation not in ["run", "run_start"]:
			if sprite.animation == "idle":
				sprite.play("run_start")
			else:
				sprite.play("run")
		elif sprite.animation == "run_start" and not sprite.is_playing():
			sprite.play("run")
	else:
		if sprite.animation == "run":
			sprite.play("run_stop")
		elif sprite.animation == "run_stop" and sprite.is_playing():
			return
		else:
			sprite.play("idle")


func _spawn_hitspark(pos: Vector2, dir: int) -> void:
	var spark := CPUParticles2D.new()
	spark.one_shot = true
	spark.explosiveness = 1.0
	spark.amount = 16
	spark.lifetime = 0.28
	spark.direction = Vector2(dir, -0.35).normalized()
	spark.spread = 45.0
	spark.initial_velocity_min = 90.0
	spark.initial_velocity_max = 190.0
	spark.gravity = Vector2(0.0, 280.0)
	spark.scale_amount_min = 1.0
	spark.scale_amount_max = 2.5
	spark.color = Color(1.0, 0.85, 0.3)
	spark.z_index = 20
	spark.position = pos
	get_parent().add_child(spark)
	var timer := get_tree().create_timer(0.4, true, false, true)
	timer.timeout.connect(spark.queue_free)
