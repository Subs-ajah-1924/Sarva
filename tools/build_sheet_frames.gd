extends SceneTree

# Builds goblin_frames.tres and skeleton_frames.tres from the horizontal
# spritesheets. Run after changing enemy sprite assets:
#   godot --headless --script tools/build_sheet_frames.gd

const BASE := "res://assets/sprites/enemies/"
const FRAME_SIZE := 150.0

const ENEMIES := {
	"goblin": {
		"sheet": "Goblin",
		"out": "res://assets/sprites/enemies/goblin_frames.tres",
		"animations": {
			"idle": {"file": "Idle.png", "frames": 4, "fps": 8.0, "loop": true},
			"walk": {"file": "Run.png", "frames": 8, "fps": 10.0, "loop": true},
			"attack": {"file": "Attack.png", "frames": 8, "fps": 12.0, "loop": false},
			"hurt": {"file": "Take Hit.png", "frames": 4, "fps": 12.0, "loop": false},
		},
	},
	"skeleton": {
		"sheet": "Skeleton",
		"out": "res://assets/sprites/enemies/skeleton_frames.tres",
		"animations": {
			"idle": {"file": "Idle.png", "frames": 4, "fps": 8.0, "loop": true},
			"walk": {"file": "Walk.png", "frames": 4, "fps": 8.0, "loop": true},
			"attack": {"file": "Attack.png", "frames": 8, "fps": 12.0, "loop": false},
			"hurt": {"file": "Take Hit.png", "frames": 4, "fps": 12.0, "loop": false},
		},
	},
}


func _init() -> void:
	var ok := true
	for enemy_name: String in ENEMIES:
		if not _build(ENEMIES[enemy_name]):
			ok = false
	quit(0 if ok else 1)


func _build(config: Dictionary) -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for animation: String in config["animations"]:
		var info: Dictionary = config["animations"][animation]
		var texture: Texture2D = load(BASE + config["sheet"] + "/" + info["file"])
		frames.add_animation(animation)
		frames.set_animation_speed(animation, info["fps"])
		frames.set_animation_loop(animation, info["loop"])
		for i in int(info["frames"]):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(i * FRAME_SIZE, 0.0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(animation, frame)

	var error := ResourceSaver.save(frames, config["out"])
	if error != OK:
		push_error("Failed to save %s: %s" % [config["out"], error_string(error)])
		return false
	print("Saved ", config["out"])
	return true
