class_name LevelCreator
extends Node2D

signal state_changed

var pause_state_changed : bool = true

@export var add_options : Panel
@export var created_objects : Node

# Used for ctrl z and ctrl y functionality
var state_list : Array = []
var current_state_index : int = 0


static var right_click_captured : bool = false
static var instance : LevelCreator = null
var viewport : Viewport

var create_position = Vector2()

var level_loader : PackedScene = load("res://level_loader.tscn")

func _ready():
	viewport = get_viewport()
	pause_state_changed = false
	
	state_changed.connect(_on_state_changed)
	instance = self

	# Load the default level
	var lvl
	if FileAccess.file_exists(Constants.level_creator_tmp_file_path):
		lvl = load_level(Constants.level_creator_tmp_file_path)
	else:
		lvl = load_level("res://level_creator_assets/default_level.json")

	state_list.append(lvl)
	
	
# Load a level into the game and return the state
func load_level(level_path: String) -> Array:
	if FileAccess.file_exists(level_path):
		var file = FileAccess.open(level_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_data)
			if error == OK:
				load_state(json.data)
				return json.data
			else:
				push_error("Failed to parse level: %s" % json.get_error_message())
		else:
			push_error("Failed to open level file: %s" % level_path)
	else:
		push_error("Failed to open level file: %s" % level_path)
	return []

func _input( event ):
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.is_released():
			if right_click_captured:
				right_click_captured = false
			else:
				create_position = viewport.get_mouse_position()
				add_options.show()
				
				add_options.position = create_position
				# Ensure the box is actually in the scene
				add_options.position += BoundingArea.get_box_delta(
					Constants.global_aabb, add_options.get_rect())
		elif event.button_index == 1 and event.is_released():
			add_options.hide()
	elif event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_Z and event.is_command_or_control_pressed():
			if current_state_index > 0:
				current_state_index -= 1
				load_state(state_list[current_state_index])
		elif event.is_pressed() and event.keycode == KEY_Y and event.is_command_or_control_pressed():
			if current_state_index < state_list.size() - 1:
				current_state_index += 1
				load_state(state_list[current_state_index])
		elif event.is_pressed() and event.keycode == KEY_S and event.is_command_or_control_pressed():
			save_state_to_file()
		elif event.is_pressed() and event.keycode == KEY_T:
			save_state_to_file_path(Constants.level_creator_tmp_file_path)
			LevelInstanceProps.level_file_path = Constants.level_creator_tmp_file_path
			LevelInstanceProps.scene_to_return_to = "res://level_creator.tscn"
			get_tree().change_scene_to_packed(level_loader)
		elif event.is_pressed() and event.keycode == KEY_N and event.is_command_or_control_pressed() and event.shift_pressed:
			# Delete the temp file and restart the scene
			if FileAccess.file_exists(Constants.level_creator_tmp_file_path):
				DirAccess.remove_absolute(Constants.level_creator_tmp_file_path)
			get_tree().reload_current_scene()
		elif event.is_pressed() and event.keycode == KEY_ESCAPE:
			# Save the state to the temp file
			save_state_to_file_path(Constants.level_creator_tmp_file_path)
			# Go to the level select scene
			get_tree().change_scene_to_file("res://level_select.tscn")
		elif event.is_pressed() and event.keycode == KEY_L and event.is_command_or_control_pressed():
			# Load a level from a file
			var file_dialog = FileDialog.new()
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.filters = ["*.json"]
			file_dialog.current_file = "level.json"
			add_child(file_dialog)
			file_dialog.popup_centered()
			file_dialog.file_selected.connect(load_level)
			

func save_state() -> Array:
	var state = []
	for child in created_objects.get_children():
		state.append(child.save_state())
	return state

func load_state(state: Array) -> void:
	# Clear the current created objects
	pause_state_changed = true
	for child in created_objects.get_children():
		child.queue_free()
	# Load the new state
	for child_state in state:
		var new_object = LevelCreatorThing.load_state(child_state)
		created_objects.add_child(new_object)
	set_deferred("pause_state_changed", false)

func _on_state_changed():
	if pause_state_changed:
		return
	if current_state_index < state_list.size() - 1:
		state_list = state_list.slice(0, current_state_index + 1)
	current_state_index += 1
	state_list.append(save_state())


func save_state_to_file() -> void:
	# Prompt user for a file path
	var file_dialog = FileDialog.new()
	
	file_dialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.json"]
	file_dialog.current_file = "level.json"
	add_child(file_dialog)
	file_dialog.popup_centered()
	file_dialog.file_selected.connect(save_state_to_file_path)


func save_state_to_file_path(path: String) -> void:
	# Open the new file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_state()))
		file.close()
	else:
		push_error("Failed to open file for writing: %s" % path)
