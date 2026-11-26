extends SceneTree

const SOURCE := "res://assets/sprites/ui/hands.png"
const FRAME_PATH := "res://assets/sprites/ui/hands_frame.png"
const FILL_PATH := "res://assets/sprites/ui/hands_fill.png"
const BAR_RECT := Rect2i(50, 70, 11, 51)


func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null:
		push_error("Failed to load " + SOURCE)
		quit(1)
		return
	var frame := source.duplicate() as Image
	var fill := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in BAR_RECT.size.y:
		for x in BAR_RECT.size.x:
			var source_x := BAR_RECT.position.x + x
			var source_y := BAR_RECT.position.y + y
			fill.set_pixel(source_x, source_y, source.get_pixel(source_x, source_y))
			frame.set_pixel(source_x, source_y, Color(0, 0, 0, 0))
	var frame_error := frame.save_png(ProjectSettings.globalize_path(FRAME_PATH))
	var fill_error := fill.save_png(ProjectSettings.globalize_path(FILL_PATH))
	if frame_error != OK or fill_error != OK:
		push_error("Failed to save hands textures")
		quit(1)
		return
	print("Saved ", FRAME_PATH, " and ", FILL_PATH)
	quit()
