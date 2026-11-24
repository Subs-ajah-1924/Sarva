extends Node2D

const BAR_SIZE := Vector2(20.0, 3.0)
const BORDER_COLOR := Color(0.08, 0.07, 0.09, 1.0)
const BACKGROUND_COLOR := Color(0.36, 0.12, 0.14, 1.0)
const FILL_COLOR := Color(0.28, 0.86, 0.34, 1.0)

var health_ratio: float = 1.0


func set_health(current: int, maximum: int) -> void:
	if maximum <= 0:
		health_ratio = 0.0
	else:
		health_ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var outer := Rect2(-BAR_SIZE * 0.5, BAR_SIZE)
	draw_rect(outer, BORDER_COLOR)
	var inner := outer.grow(-1.0)
	draw_rect(inner, BACKGROUND_COLOR)
	if health_ratio > 0.0:
		var fill := Rect2(inner.position, Vector2(inner.size.x * health_ratio, inner.size.y))
		draw_rect(fill, FILL_COLOR)
