class_name LevelCreator
extends Node2D

@export var add_options : Panel

static var right_click_captued : bool = false
var viewport : Viewport

var create_position = Vector2()

func _ready():
	viewport = get_viewport()

func _input( event ):
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.is_released():
			if right_click_captued:
				right_click_captued = false
			else:
				create_position = viewport.get_mouse_position()
				add_options.show()
				
				add_options.position = create_position
				# Ensure the box is actually in the scene
				add_options.position += BoundingArea.get_box_delta(
					Constants.global_aabb, add_options.get_rect())
		elif event.button_index == 1 and event.is_released():
			add_options.hide()
