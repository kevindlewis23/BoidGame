class_name LevelSelector
extends Node

@export var start_button : Button
@export var create_level_button : Button
@export var load_level_button : Button
@export var instructions_button : Button
@export var option_select : CustomOptions
@export var quit_button : Button
static var num_levels : int = 21

static var level_loader : PackedScene = preload("res://level_loader.tscn")

func _ready():
	# Load the passed levels so far
	var passed_levels = load_passed_levels()
	var passed_levels_cur_index = 0

	# Add all the options
	var first_unpassed_level = 1
	var found_unpassed = false
	for i in range(num_levels):
		var item_text = "Level %d" % (i + 1)
		var item_color = Color.WHITE
		# See if the level has been passed
		if passed_levels_cur_index < passed_levels.size() and passed_levels[passed_levels_cur_index] == i + 1:
			passed_levels_cur_index += 1
			# Change color to be darker
			item_color = Color(1, 1, 1, 0.3)
		else:
			if not found_unpassed:
				first_unpassed_level = i + 1
				found_unpassed = true

		# Add the item to the option select
		option_select.add_item_with_color(item_text, item_color)
	
	# Set the first unpassed level as the selected one
	if first_unpassed_level <= num_levels:
		option_select.select(first_unpassed_level - 1)
	# Select the first unpassed level
	start_button.pressed.connect(start_level)
	create_level_button.pressed.connect(func(): get_tree().change_scene_to_file("res://level_creator.tscn"))
	load_level_button.pressed.connect(load_level)
	instructions_button.pressed.connect(func(): OS.shell_open("https://github.com/kevindlewis23/BoidGame/blob/main/README.md"))
	quit_button.pressed.connect(func(): get_tree().quit())

func start_level():
	var level_number = option_select.get_selected_id() + 1
	start_level_from_number(level_number, get_tree())
	
static func start_level_from_number(level_number: int, tree : SceneTree) -> void:
	# Get the level
	var level_name = "res://levels/level_%d.json" % (level_number)
	LevelInstanceProps.level_number = level_number

	# Make sure it actually exists
	if FileAccess.file_exists(level_name):
		LevelInstanceProps.scene_to_return_to = "res://level_select.tscn"
		LevelInstanceProps.level_file_path = level_name
		# Start the level loader
		tree.change_scene_to_packed(level_loader)

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

func load_passed_levels() -> Array:
	if not FileAccess.file_exists(Constants.passed_levels_file_path):
		return []
	var file = FileAccess.open(Constants.passed_levels_file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_data)
		if error == OK:
			# Sort and return
			var passed_levels = json.data
			passed_levels.sort()
			return passed_levels
		else:
			push_error("Failed to parse passed levels file: %s" % json.get_error_message())
			return []
	else:
		push_error("Failed to open passed levels file: %s" % Constants.passed_levels_file_path)
		return []
