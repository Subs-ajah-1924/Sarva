extends Control

const HEALTH_FRAME = preload("res://assets/sprites/ui/healthbar_frame.png")
const ENERGY_TEXTURE = preload("res://assets/sprites/ui/hands_frame.png")
const HEALTH_TRACK_WIDTH := 84.0
const HEALTH_TRACK_HEIGHT := 14.0
const HEALTH_FILL_WIDTH := 84.0
const HEALTH_FILL_HEIGHT := 14.0
const ENERGY_FILL_WIDTH := 64.0
const ENERGY_FILL_HEIGHT := 51.0
const ENERGY_FILL_BOTTOM := 121.0
const ENERGY_TEXTURE_HEIGHT := 64.0

var health := 10
var max_health := 10
var energy := 0
var max_energy := 5

@onready var health_track: Sprite2D = get_node_or_null("HealthbarTrack")
@onready var health_frame: Sprite2D = get_node_or_null("HealthbarTrack/HealthbarFrame")
@onready var health_fill: Sprite2D = get_node_or_null("HealthbarTrack/HealthbarFill")
@onready var energy_frame: Sprite2D = get_node_or_null("HandsFill/HandsFrame")
@onready var energy_fill: Sprite2D = get_node_or_null("HandsFill")

func _ready() -> void:
	if health_frame:
		health_frame.texture = HEALTH_FRAME
	if energy_frame:
		energy_frame.texture = ENERGY_TEXTURE
	if health_fill:
		health_fill.region_enabled = true
	if health_track:
		health_track.region_enabled = true
	if energy_fill:
		energy_fill.region_enabled = true
	_update_health()
	_update_energy()

func set_health(current: int, maximum: int) -> void:
	max_health = maxi(maximum, 1)
	health = clampi(current, 0, max_health)
	_update_health()

func set_energy(current: int, maximum: int) -> void:
	max_energy = maxi(maximum, 0)
	energy = clampi(current, 0, max_energy)
	_update_energy()

func _update_health() -> void:
	if not is_node_ready():
		return
	var ratio := float(health) / float(max_health)
	if health_track:
		var track_width := HEALTH_TRACK_WIDTH * ratio
		health_track.region_rect = Rect2(0.0, 0.0, track_width, HEALTH_TRACK_HEIGHT)
		health_track.offset.x = (track_width - HEALTH_TRACK_WIDTH) * 0.5
	if health_fill:
		var width := HEALTH_FILL_WIDTH * ratio
		health_fill.region_rect = Rect2(0.0, 0.0, width, HEALTH_FILL_HEIGHT)
		health_fill.offset.x = (width - HEALTH_FILL_WIDTH) * 0.5

func _update_energy() -> void:
	if not is_node_ready() or energy_fill == null:
		return
	var ratio := 0.0
	if max_energy > 0:
		ratio = float(energy) / float(max_energy)
	var height := ENERGY_FILL_HEIGHT * ratio
	energy_fill.region_rect = Rect2(0.0, ENERGY_FILL_BOTTOM - height, ENERGY_FILL_WIDTH, height)
	energy_fill.offset.y = (ENERGY_FILL_BOTTOM - ENERGY_TEXTURE_HEIGHT) - height * 0.5
	energy_fill.self_modulate.a = 1.0 if height > 0.0 else 0.0
