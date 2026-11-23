extends SceneTree

# Builds res://assets/sprites/player/player_frames.tres from the separated
# character frames. Run after changing the player sprite assets:
#   godot --headless --script tools/build_player_frames.gd

const FRAMES_PATH := "res://assets/sprites/player/player_frames.tres"
const BASE := "res://assets/sprites/player/Separated Images/"
const SHEET_BASE := "res://assets/sprites/player/Spritesheets/Transitions/"
const FRAME_SIZE := 160

const ANIMATIONS := {
	"idle": {"dir": "01.Idle", "fps": 8.0, "loop": true},
	"run": {"dir": "03.Run", "fps": 12.0, "loop": true},
	"run_start": {"sheet": "01.Run start.png", "frames": 1, "fps": 20.0, "loop": false},
	"run_stop": {"sheet": "02.Run stop.png", "frames": 6, "fps": 20.0, "loop": false},
	"jump": {"dir": "04.Jump", "fps": 12.0, "loop": false},
	"jump_apex": {"sheet": "05.Jump Apex.png", "frames": 5, "fps": 20.0, "loop": false},
	"fall": {"dir": "05.Fall", "fps": 12.0, "loop": false},
	"land": {"sheet": "06.Land.png", "frames": 4, "fps": 20.0, "loop": false},
	"land_hard": {"sheet": "07.Land from Distance.png", "frames": 8, "fps": 20.0, "loop": false},
	"slide_start": {"sheet": "03.Slide start.png", "frames": 4, "fps": 24.0, "loop": false},
	"slide_end": {"sheet": "04.Slide end.png", "frames": 5, "fps": 20.0, "loop": false},
	"wall_hold_start": {"sheet": "08.wall hold start.png", "frames": 6, "fps": 20.0, "loop": false},
	"ledge_climb": {"sheet": "09.(Ledge hold ) climb up.png", "frames": 5, "fps": 20.0, "loop": false},
	"knockback_recover": {"sheet": "10.Knockback recover.png", "frames": 7, "fps": 20.0, "loop": false},
	"attack": {"dir": "09.Attack 1", "fps": 18.0, "loop": false},
	"attack2": {"dir": "10.Attack 2", "fps": 18.0, "loop": false},
	"hurt": {"dir": "16.Knockback", "fps": 12.0, "loop": false},
	"dash": {"dir": "06.Slide", "fps": 16.0, "loop": false},
}


func _init() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for animation: String in ANIMATIONS:
		var config: Dictionary = ANIMATIONS[animation]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, config["fps"])
		frames.set_animation_loop(animation, config["loop"])
		if config.has("dir"):
			for frame_path in _frame_paths(BASE + config["dir"]):
				frames.add_frame(animation, load(frame_path))
		else:
			var texture: Texture2D = load(SHEET_BASE + config["sheet"])
			for i in int(config["frames"]):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(0, i * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
				frames.add_frame(animation, atlas)

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
