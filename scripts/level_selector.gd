extends Node

@export var start_button : Button
@export var create_level_button : Button
@export var load_level_button : Button
@export var instructions_button : Button
@export var option_select : OptionButton
@export var quit_button : Button
@export var num_levels : int = 9

var level_loader : PackedScene = load("res://level_loader.tscn")

func _ready():
	# Add all the options
	for i in range(num_levels):
		option_select.add_item("Level %d" % (i + 1))
	start_button.pressed.connect(start_level)
	create_level_button.pressed.connect(func(): get_tree().change_scene_to_file("res://level_creator.tscn"))
	load_level_button.pressed.connect(load_level)
	instructions_button.pressed.connect(func(): OS.shell_open("https://github.com/kevindlewis23/BoidGame/blob/main/README.md"))
	quit_button.pressed.connect(func(): get_tree().quit())

func start_level():
	# Get the level
	var level_name = "res://Levels/level_%d.tscn" % (option_select.get_selected_id() + 1)
	# Make sure the file exists
	if ResourceLoader.exists(level_name):
		get_tree().change_scene_to_file(level_name)
	else:
		# Check if it exists as a .json file
		var json_name = "res://Levels/level_%d.json" % (option_select.get_selected_id() + 1)
		if FileAccess.file_exists(json_name):
			LevelInstanceProps.scene_to_return_to = "res://level_select.tscn"
			LevelInstanceProps.level_file_path = json_name
			# Start the level loader
			get_tree().change_scene_to_packed(level_loader)

		else:
			push_error("Level file does not exist: %s" % level_name)
			return
	
func load_level():
	var file_dialog = FileDialog.new()
	
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.json"]
	add_child(file_dialog)
	file_dialog.popup_centered()
	file_dialog.file_selected.connect(load_file_from_path)

func load_file_from_path(path: String) -> void:
	# Check if the file exists
	if not FileAccess.file_exists(path):
		push_error("File does not exist: %s" % path)
		return
	
	# Set the level file path and scene to return to
	LevelInstanceProps.level_file_path = path
	LevelInstanceProps.scene_to_return_to = "res://level_select.tscn"
	
	# Start the level loader
	get_tree().change_scene_to_packed(level_loader)
