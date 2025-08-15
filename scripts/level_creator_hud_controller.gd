class_name LevelCreatorHudController
extends BaseHudController

# This code is probably too paired with the LevelCreator but it was the easy thing to do

@export var test_button : Button
@export var undo_button : Button
@export var redo_button : Button
@export var trash_button : Button
@export var load_button : Button
@export var save_button : Button
@export var level_creator : LevelCreator


@onready var text_boxes = [level_name, info_text]

# For both textboxes
var text_when_entered = ["", ""]
var focused_on_textbox = false

func _ready() -> void:
	super._ready()

	for i in range(text_boxes.size()):
		var text_box = text_boxes[i]

		text_box.focus_entered.connect(func():
			hud_bar_force_shown += 1
			text_when_entered[i] = text_box.text
			focused_on_textbox = true
		)
		text_box.focus_exited.connect(func():
			hud_bar_force_shown -= 1
			if text_box.text != text_when_entered[i]:
				level_creator.state_changed.emit()
			focused_on_textbox = false
		)

	test_button.pressed.connect(level_creator.test_level)
	undo_button.pressed.connect(level_creator.undo)
	redo_button.pressed.connect(level_creator.redo)
	trash_button.pressed.connect(level_creator.trash)
	load_button.pressed.connect(level_creator.load_from_file)
	save_button.pressed.connect(level_creator.save_state_to_file)


func _input(event: InputEvent) -> void:
	super._input(event)
	# Focus in Godot is not suited for GUI all that well, I want to remove focus when you click off of the level name
	for text_box in text_boxes:
		if text_box.has_focus() and event is InputEventMouseButton and event.pressed and not text_box.get_rect().has_point(event.position):
			text_box.release_focus()


# Overriding so that we save first
func leave_to_home():
	level_creator.save_and_quit()
