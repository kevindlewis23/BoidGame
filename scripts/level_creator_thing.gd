class_name LevelCreatorThing
extends MovableThing

signal remove_control_box
signal add_control_box

# Positions of the corners
const mask_x = [-1, 1, 1, -1]
const mask_y = [-1, -1, 1, 1]
@export var corner_size = 20
@export var corner_color = Color(1, 1, 1, .5)
@export var control_box : ControlBox
var hovered_corner : ColorRect = null
var hovered_corner_index : int = -1

const DEFAULT_BOUNDARY = 30

func _ready() -> void:
	bounding_box_base_color = bounding_box_hover_color
	var mobb_pos = moving_object_bounding_box.global_position
	bounding_box.global_position.x = 0
	bounding_box.global_position.y = 0
	
	for i in range(4):
		var new_corner = ColorRect.new()
		new_corner.color = corner_color
		new_corner.size.x = corner_size
		new_corner.size.y = corner_size
		if mask_x[i] == mask_y[i]:
			new_corner.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		else:
			new_corner.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		bounding_box.add_child(new_corner)
		new_corner.mouse_entered.connect(func () -> void:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				hovered_corner = new_corner;
				hovered_corner_index = i
		)
		new_corner.mouse_exited.connect(func () -> void:
			if hovered_corner == new_corner and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				hovered_corner = null
				hovered_corner_index = -1
		)
	resize_box(DEFAULT_BOUNDARY, DEFAULT_BOUNDARY,
			Constants.WIDTH - DEFAULT_BOUNDARY, Constants.HEIGHT - DEFAULT_BOUNDARY)
	super._ready()
	moving_object_bounding_box.move_to(mobb_pos + moving_object_bounding_box.size / 2, bounding_box_aabb)
	reposition_corners()

	moved.connect(control_box.set_values_to_current)

func reposition_corners():
	var corners = bounding_box.get_children()
	for i in range(4):
		corners[i].position.x = bounding_box.polygon[i].x - corner_size / 2.0
		corners[i].position.y = bounding_box.polygon[i].y - corner_size / 2.0
	var mobb_pos = moving_object_bounding_box.global_position
	bounding_box_aabb = get_rect_bounds(bounding_box)
	moving_object_bounding_box.move_to(mobb_pos + moving_object_bounding_box.size / 2, bounding_box_aabb)

func resize_box(left : float, top: float, right : float, bottom: float, from_right : bool = true, from_bottom : bool = true) -> void:
	# First, make sure the box is within the boundaries of the level
	left = max(left, DEFAULT_BOUNDARY)
	top = max(top, DEFAULT_BOUNDARY)
	right = min(right, Constants.WIDTH - DEFAULT_BOUNDARY)
	bottom = min(bottom, Constants.HEIGHT - DEFAULT_BOUNDARY)
	# First, make sure the bounding box is big enough
	if from_right:
		right = max(right, left + moving_object_bounding_box.size.x)
	else:
		left = min(left, right - moving_object_bounding_box.size.x)
	if from_bottom:
		bottom = max(bottom, top + moving_object_bounding_box.size.y)
	else:
		top = min(top, bottom - moving_object_bounding_box.size.y)
	var x_pos = [left, right]
	var y_pos = [top, bottom]
	# I'm probably overcomplicating this, seems unnecessary lol
	for i in range(4):
		bounding_box.polygon[i].x = x_pos[max(0,mask_x[i])]
		bounding_box.polygon[i].y = y_pos[max(0,mask_y[i])]
	reposition_corners()
	control_box.set_values_to_current()
	
func _process(delta: float) -> void:
	super._process(delta	)
	if hovered_corner_index >= 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var l = bounding_box.polygon[0].x
		var t = bounding_box.polygon[0].y
		var r = bounding_box.polygon[2].x
		var b = bounding_box.polygon[2].y

		var from_right = true
		var from_bottom = true
		var mouse_pos = viewport.get_mouse_position()

		if hovered_corner_index == 0 or hovered_corner_index == 3:
			l = mouse_pos.x + corner_size / 2.0
			from_right = false
		if hovered_corner_index == 1 or hovered_corner_index == 2:
			r = mouse_pos.x + corner_size / 2.0
		if hovered_corner_index == 0 or hovered_corner_index == 1:
			t = mouse_pos.y + corner_size / 2.0
			from_bottom = false
		if hovered_corner_index == 2 or hovered_corner_index == 3:
			b = mouse_pos.y + corner_size / 2.0
		resize_box(l, t, r, b, from_right, from_bottom)
	
func _input( event ):
	if event is InputEventMouseButton:
		if not event.is_pressed():
			# If the left mouse button is released, we stop resizing
			hovered_corner = null
			hovered_corner_index = -1
			if not is_hovered and not is_dragging and not is_rotating:
				remove_control_box.emit()
			else:
				add_control_box.emit()
	super._input(event)
