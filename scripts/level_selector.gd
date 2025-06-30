extends Node

@export var start_button : Button
@export var option_select : OptionButton
@export var num_levels : int = 9

var level_loader : PackedScene = load("res://level_loader.tscn")

func _ready():
	# Add all the options
	for i in range(num_levels):
		option_select.add_item("Level %d" % (i + 1))
	start_button.pressed.connect(start_level)

func start_level():
	# Get the level
	var level_name = "res://Levels/level_%d.tscn" % (option_select.get_selected_id() + 1)
	# Make sure the file exists
	if FileAccess.file_exists(level_name):
		get_tree().change_scene_to_file(level_name)
	else:
		# Check if it exists as a .json file
		var json_name = "res://Levels/level_%d.json" % (option_select.get_selected_id() + 1)
		if FileAccess.file_exists(json_name):
			LevelInstanceProps.scene_to_return_to = "res://level_select.tscn"
			LevelInstanceProps.scene_file_path = json_name
			# Start the level loader
			get_tree().change_scene_to_packed(level_loader)

		else:
			push_error("Level file does not exist: %s" % level_name)
			return
	
