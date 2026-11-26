extends SceneTree

const SOURCE := "res://assets/sprites/ui/Horror Healthbar.png"
const FRAME_PATH := "res://assets/sprites/ui/healthbar_frame.png"
const FILL_PATH := "res://assets/sprites/ui/healthbar_fill.png"
const TRACK_PATH := "res://assets/sprites/ui/healthbar_track.png"
const BAR_RECT := Rect2i(32, 48, 84, 14)
const TRACK_COLOR := Color8(109, 133, 165)


func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null:
		push_error("Failed to load " + SOURCE)
		quit(1)
		return
	var frame := source.duplicate() as Image
	for y in BAR_RECT.size.y:
		for x in BAR_RECT.size.x:
			frame.set_pixel(BAR_RECT.position.x + x, BAR_RECT.position.y + y, Color(0, 0, 0, 0))
	var fill := source.get_region(BAR_RECT)
	var track := source.get_region(BAR_RECT)
	for y in fill.get_height():
		for x in fill.get_width():
			if _is_fill(fill.get_pixel(x, y)):
				track.set_pixel(x, y, TRACK_COLOR)
			else:
				fill.set_pixel(x, y, Color(0, 0, 0, 0))
	var frame_error := frame.save_png(ProjectSettings.globalize_path(FRAME_PATH))
	var fill_error := fill.save_png(ProjectSettings.globalize_path(FILL_PATH))
	var track_error := track.save_png(ProjectSettings.globalize_path(TRACK_PATH))
	if frame_error != OK or fill_error != OK or track_error != OK:
		push_error("Failed to save healthbar textures")
		quit(1)
		return
	print("Saved ", FRAME_PATH, ", ", FILL_PATH, " and ", TRACK_PATH)
	quit()


func _is_fill(color: Color) -> bool:
	var r := color.r * 255.0
	var g := color.g * 255.0
	var b := color.b * 255.0
	return color.a > 0.15 and g > 120.0 and b > 120.0 and r < 150.0 and (g - r) > 30.0
