class_name LevelCreator
extends Node2D

signal state_changed

var pause_state_changed : bool = true

@export var add_options : Panel
@export var created_objects : Node
@export var hud : LevelCreatorHudController

# Used for ctrl z and ctrl y functionality
var state_list : UndoRedoThing = UndoRedoThing.new()


static var right_click_captured : bool = false
static var Instance : LevelCreator = null
var viewport : Viewport

var create_position = Vector2()

var level_loader : PackedScene = load("res://level_loader.tscn")

func _ready():
	viewport = get_viewport()
	pause_state_changed = false
	right_click_captured = false
	
	state_changed.connect(_on_state_changed)
	Instance = self

	# Load the default level
	var lvl
	if FileAccess.file_exists(Constants.level_creator_tmp_file_path):
		lvl = load_level(Constants.level_creator_tmp_file_path)
	else:
		lvl = load_level("res://level_creator_assets/default_level.json")

	state_list.add_state(lvl)
	
	
# Load a level into the game and return the state
func load_level(level_path: String, first_load : bool = true) -> Dictionary:
	if not first_load:
		hud.hud_bar_force_shown -= 1
		hud.force_show_hud_bar_for_a_bit()
	if FileAccess.file_exists(level_path):
		var file = FileAccess.open(level_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_data)
			if error == OK:
				# Check if this is an array or dictionary
				if not json.data is Dictionary:
					push_error("Level file should be a dictionary.")
					return {}
				load_state(json.data)
				return json.data
			else:
				push_error("Failed to parse level: %s" % json.get_error_message())
		else:
			push_error("Failed to open level file: %s" % level_path)
	else:
		push_error("Failed to open level file: %s" % level_path)
	return {}

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
	# For consistency I should probably move this all to level_creator_hud_controller, but it's fine here for now
	elif event is InputEventKey and event.is_pressed() and not hud.focused_on_textbox:
		if event.keycode == KEY_Z and event.is_command_or_control_pressed():
			undo()
		elif event.keycode == KEY_Y and event.is_command_or_control_pressed():
			redo()
		elif event.keycode == KEY_T:
			test_level()
		elif event.keycode == KEY_S and event.is_command_or_control_pressed():
			save_state_to_file()
		elif event.keycode == KEY_N and event.is_command_or_control_pressed():
			trash()
		elif event.keycode == KEY_L and event.is_command_or_control_pressed():
			load_from_file()
			
			
func save_and_quit():
	# Save the state to the temp file
	save_state_to_file_path(Constants.level_creator_tmp_file_path, false)
	# Go to the level select scene
	get_tree().change_scene_to_file("res://level_select.tscn")

func undo():
	var new_state = state_list.undo()
	if new_state:
		change_state_to_new(new_state)
		

func redo():
	var new_state = state_list.redo()
	if new_state:
		change_state_to_new(new_state)

func change_state_to_new(state):
	var cur_level_name = hud.level_name.text
	var cur_info_text = hud.info_text.text
	load_state(state)
	# If something changed, show it
	if cur_info_text != hud.info_text.text:
		if not hud.info_overlay.visible:
			hud.toggle_info()
	elif cur_level_name != hud.level_name.text:
		hud.force_show_hud_bar_for_a_bit()

func trash():
	# Send a confirmation dialogue to make sure
	hud.hud_bar_force_shown += 1
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Are you sure you want to delete your progress? This cannot be undone"
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()
	confirmation_dialog.confirmed.connect(func():
		# Delete the temp file and restart the scene
		if FileAccess.file_exists(Constants.level_creator_tmp_file_path):
			DirAccess.remove_absolute(Constants.level_creator_tmp_file_path)
		get_tree().reload_current_scene()
	)
	confirmation_dialog.canceled.connect(func():
		hud.hud_bar_force_shown -= 1
	)


func load_from_file():
	hud.hud_bar_force_shown += 1
	# Load a level from a file
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.json"]
	file_dialog.current_dir = Helpers.get_storage_directory("load_creator")
	file_dialog.current_file = "level.json"
	add_child(file_dialog)
	file_dialog.popup_centered()
	file_dialog.file_selected.connect(
		func(level_path) : 
			Helpers.add_storage_directory("load_creator", level_path.get_base_dir())
			load_level(level_path, false)
	)
	file_dialog.canceled.connect(func():
		hud.hud_bar_force_shown -= 1
	)



func test_level():
	save_state_to_file_path(Constants.level_creator_tmp_file_path)
	LevelInstanceProps.level_file_path = Constants.level_creator_tmp_file_path
	LevelInstanceProps.scene_to_return_to = "res://level_creator.tscn"
	LevelInstanceProps.level_number = 0
	get_tree().change_scene_to_packed(level_loader)

func save_state() -> Dictionary:
	var game_objects = []
	for child in created_objects.get_children():
		game_objects.append(child.save_state())
	var level_name = hud.level_name.text
	var level_info = hud.info_text.text
	return {"game_objects": game_objects, "level_name": level_name, "level_info": level_info}

func load_state(state: Dictionary) -> void:
	# Clear the current created objects
	pause_state_changed = true
	for child in created_objects.get_children():
		child.queue_free()
	# Load the new state
	for child_state in state.get("game_objects", []):
		var new_object = LevelCreatorThing.load_state(child_state)
		created_objects.add_child(new_object)
	
	hud.level_name.text = state.get("level_name", "")
	hud.info_text.text = state.get("level_info", "")
	set_deferred("pause_state_changed", false)

func _on_state_changed():
	if not pause_state_changed:
		state_list.add_state(save_state())


func save_state_to_file() -> void:
	hud.hud_bar_force_shown += 1
	# Prompt user for a file path
	var file_dialog = FileDialog.new()
	
	file_dialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.json"]
	file_dialog.current_dir = Helpers.get_storage_directory("save")
	file_dialog.current_file = "level.json"
	add_child(file_dialog)
	file_dialog.popup_centered()
	file_dialog.file_selected.connect(save_state_to_file_path)
	file_dialog.canceled.connect(func():
		hud.hud_bar_force_shown -= 1
	)

func save_state_to_file_path(path: String, save_directory : bool = true) -> void:
	hud.hud_bar_force_shown -= 1
	# Open the new file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_state()))
		file.close()

		# Store the folder this was saved to in storage_directories
		if save_directory:
			Helpers.add_storage_directory("save", path.get_base_dir())
	else:
		push_error("Failed to open file for writing: %s" % path)
