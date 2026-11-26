extends CharacterBody2D
class_name Enemy

# Shared melee enemy behavior. Tune per enemy through exported values.

signal health_changed(current: int, maximum: int)
signal died(enemy: Enemy)

@export var move_speed := 45.0
@export var detection_range := 140.0
@export var attack_range := 30.0
@export var cooldown := 1.4
@export var windup := 0.3
@export var active_time := 0.2
@export var hurt_duration := 0.35
@export var knockback_speed := 130.0
@export var max_health := 2
@export var attack_damage := 1
@export var invulnerability_duration := 0.5

var player: Node2D
var health: int
var facing := -1
var attacking := false
var dead := false
var attack_time := 0.0
var attack_cooldown := 0.0
var hurt_time := 0.0
var invulnerable := 0.0
var hit_done := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackHitbox
@onready var health_bar: Node2D = $WorldHealthBar


func _ready() -> void:
	health = max_health
	health_changed.connect(health_bar.set_health)
	health_changed.emit(health, max_health)
	player = get_tree().get_first_node_in_group("player")
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	invulnerable = maxf(invulnerable - delta, 0.0)

	if hurt_time > 0.0:
		hurt_time -= delta
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		_update_animation()
		return

	if attacking:
		_update_attack(delta)
		move_and_slide()
		_update_animation()
		return

	if player != null and is_instance_valid(player):
		var dx := player.global_position.x - global_position.x
		var distance := absf(dx)
		if distance <= attack_range and attack_cooldown <= 0.0 and is_on_floor():
			_start_attack(signf(dx))
		elif distance <= detection_range:
			facing = 1 if dx > 0.0 else -1
			velocity.x = move_toward(velocity.x, facing * move_speed, 600.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)

	move_and_slide()
	_update_animation()


func _start_attack(direction: float) -> void:
	attacking = true
	attack_time = 0.0
	attack_cooldown = cooldown
	hit_done = false
	facing = 1 if direction > 0.0 else -1
	attack_area.position.x = 15.0 * facing
	attack_area.monitoring = false
	sprite.play("attack")


func _update_attack(delta: float) -> void:
	attack_time += delta
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)

	var in_window := attack_time >= windup and attack_time <= windup + active_time
	attack_area.monitoring = in_window
	if in_window and not hit_done:
		for body in attack_area.get_overlapping_bodies():
			if body.has_method("take_hit"):
				if body.take_hit(facing, attack_damage):
					hit_done = true
					break


func take_hit(direction: int, damage: int = 1) -> bool:
	if dead or invulnerable > 0.0 or hurt_time > 0.0:
		return false
	health = maxi(health - maxi(damage, 0), 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()
		return true

	invulnerable = invulnerability_duration
	hurt_time = hurt_duration
	attacking = false
	hit_done = false
	attack_area.monitoring = false
	velocity = Vector2(direction * knockback_speed, -90.0)
	sprite.play("hurt")
	sprite.modulate = Color(2.0, 2.0, 2.0)
	var flash_timer := get_tree().create_timer(0.08, true, false, true)
	flash_timer.timeout.connect(func(): sprite.modulate = Color(1.0, 1.0, 1.0))
	return true


func _die() -> void:
	if dead:
		return
	dead = true
	attacking = false
	hit_done = false
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	attack_area.monitorable = false
	attack_area.collision_layer = 0
	attack_area.collision_mask = 0
	collision_layer = 0
	collision_mask = 0
	for collision_shape in find_children("CollisionShape2D", "CollisionShape2D", true, false):
		collision_shape.set_deferred("disabled", true)
	died.emit(self)
	sprite.play("death")


func _on_animation_finished() -> void:
	if dead and sprite.animation == "death":
		queue_free()
		return
	if sprite.animation == "attack":
		attacking = false
		attack_area.monitoring = false


func _update_animation() -> void:
	if dead:
		return
	sprite.flip_h = facing < 0

	if hurt_time > 0.0:
		sprite.play("hurt")
	elif attacking:
		sprite.play("attack")
	elif absf(velocity.x) > 2.0:
		sprite.play("walk")
	else:
		sprite.play("idle")
