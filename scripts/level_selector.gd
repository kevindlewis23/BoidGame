extends Node

@export var start_button : Button
@export var option_select : OptionButton
@export var num_levels : int = 9

func _ready():
	# Add all the options
	for i in range(num_levels):
		option_select.add_item("Level %d" % (i + 1))
	start_button.pressed.connect(start_level)

func start_level():
	# Get the level
	var level_name = "res://Levels/level_%d.tscn" % (option_select.get_selected_id() + 1)
	get_tree().change_scene_to_file(level_name)
