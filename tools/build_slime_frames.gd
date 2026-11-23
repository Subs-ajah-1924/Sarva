extends SceneTree

# Builds res://assets/sprites/enemies/slime_frames.tres from the green slime
# frames. Run after changing the slime sprite assets:
#   godot --headless --script tools/build_slime_frames.gd

const FRAMES_PATH := "res://assets/sprites/enemies/slime_frames.tres"
const BASE := "res://assets/sprites/enemies/Slime_Enemy_Pixel_Monsters_Vol_1/Slime/frames/green/"

const ANIMATIONS := {
	"idle": {"dir": "idle", "fps": 8.0, "loop": true},
	"walk": {"dir": "walk", "fps": 10.0, "loop": true},
	"attack": {"dir": "attack", "fps": 12.0, "loop": false},
	"hurt": {"dir": "hurt1", "fps": 12.0, "loop": false},
}


func _init() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for animation: String in ANIMATIONS:
		var config: Dictionary = ANIMATIONS[animation]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, config["fps"])
		frames.set_animation_loop(animation, config["loop"])
		for frame_path in _frame_paths(BASE + config["dir"]):
			frames.add_frame(animation, load(frame_path))

	var error := ResourceSaver.save(frames, FRAMES_PATH)
	if error != OK:
		push_error("Failed to save %s: %s" % [FRAMES_PATH, error_string(error)])
		quit(1)
		return
	print("Saved ", FRAMES_PATH)
	quit()


func _frame_paths(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() == "png":
			paths.append(dir_path.path_join(file_name))
	paths.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return paths
