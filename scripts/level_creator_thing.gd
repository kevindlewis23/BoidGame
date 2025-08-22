class_name LevelCreatorThing
extends MovableThing

enum ObjectType {
	BOID, REPELLER, STAR
}


signal remove_control_box
signal add_control_box

# Positions of the corners
const mask_x = [-1, 1, 1, -1]
const mask_y = [-1, -1, 1, 1]
@export var corner_size = 20
@export var corner_color = Color(1, 1, 1, .5)
@export var control_box : ControlBox
@export var object_type : ObjectType = ObjectType.BOID
var starting_boid_bb_width : float = 200.0
var hovered_corner : ColorRect = null
var hovered_corner_index : int = -1



const OBJECT_SCENES = {
	ObjectType.BOID: preload("res://level_creator_assets/level_creator_boid.tscn"),
	ObjectType.REPELLER: preload("res://level_creator_assets/level_creator_repeller.tscn"),
	ObjectType.STAR: preload("res://level_creator_assets/level_creator_star.tscn")
}

const DEFAULT_BOUNDARY = 30

func _ready() -> void:
	is_level_creator_thing = true
	bounding_box_base_color = bounding_box_hover_color
	var mobb_pos = moving_object_bounding_box.global_position
	bounding_box.global_position.x = 0
	bounding_box.global_position.y = 0
	if control_box.has_bounding_box:
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

	LevelCreator.Instance.state_changed.emit.call_deferred()

	moved.connect(control_box.set_values_to_current)

func reposition_corners():
	if not control_box.has_bounding_box:
		return
	var corners = bounding_box.get_children()
	for i in range(4):
		corners[i].position.x = bounding_box.polygon[i].x - corner_size / 2.0
		corners[i].position.y = bounding_box.polygon[i].y - corner_size / 2.0
	var mobb_pos = moving_object_bounding_box.global_position
	bounding_box_aabb = get_rect_bounds(bounding_box)
	moving_object_bounding_box.move_to(mobb_pos + moving_object_bounding_box.size / 2, bounding_box_aabb)

func resize_box(left : float, top: float, right : float, bottom: float, from_right : bool = true, from_bottom : bool = true) -> void:
	if not control_box.has_bounding_box:
		return
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
	super._process(delta)
	if not control_box.has_bounding_box:
		return
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
			if hovered_corner:
				LevelCreator.Instance.state_changed.emit()
			hovered_corner = null
			hovered_corner_index = -1
			if not is_hovered and not is_dragging and not is_rotating:
				remove_control_box.emit()
			else:
				add_control_box.emit()
			# If we were dragging or rotating, we emit the state changed signal
			if (is_dragging_has_actually_started and event.button_index == MOUSE_BUTTON_LEFT) or (is_rotating and event.button_index == MOUSE_BUTTON_RIGHT):
				LevelCreator.Instance.state_changed.emit()
	super._input(event)


func save_state() -> Dictionary:
	"""Save the state of this object"""
	var state =  {
		"object_type": object_type,
		"object": {
			"x": control_box.x_position.value,
			"y": control_box.y_position.value,
			"rotation": control_box.rotation_box.value
		}
	}
	if not object_type == ObjectType.STAR:
		state["bounding_box"] = {
			"left": control_box.box_left.value,
			"top": control_box.box_top.value,
			"right": control_box.box_right.value,
			"bottom": control_box.box_bottom.value
		}
		state["object"]["can_move"] = control_box.can_move_checkbox.button_pressed
	if object_type == ObjectType.BOID:
		state["object"]["can_rotate"] = control_box.can_rotate_checkbox.button_pressed
		state["object"]["can_collect_stars"] = control_box.can_collect_stars_box.button_pressed
		state["object"]["is_predator"] = control_box.is_predator_box.button_pressed

	return state

static func load_state(state: Dictionary) -> LevelCreatorThing:
	"""Load the state of this object"""
	# Cast object type to an integer, since jsonifying will turn it into a float
	var new_object = OBJECT_SCENES[int(state["object_type"])].instantiate() as LevelCreatorThing
	# Once the object is ready, do the rest as a callback
	new_object.ready.connect(func() -> void:

		# Move the bounding box to the correct position first
		if not new_object.object_type == ObjectType.STAR:
			new_object.resize_box(state["bounding_box"]["left"], state["bounding_box"]["top"],
				state["bounding_box"]["right"], state["bounding_box"]["bottom"])
			new_object.control_box.can_move_checkbox.button_pressed = state["object"]["can_move"]

			
		# Set location and rotation.  Make sure position gets set even if it seems impossible
		new_object.moving_object_bounding_box.move_to(Vector2(state["object"]["x"], state["object"]["y"]), Constants.huge_box)
		if new_object.object_type == ObjectType.BOID:
			var target_rotation = -state["object"]["rotation"] * PI / 180.0
			new_object.moving_object_bounding_box.rotate_to(target_rotation, Constants.huge_box)
			new_object.control_box.can_rotate_checkbox.button_pressed = state["object"]["can_rotate"]
			new_object.control_box.can_collect_stars_box.button_pressed = state["object"]["can_collect_stars"]
			# Supporting levels from before the predator boids were added
			new_object.control_box.is_predator_box.button_pressed = state["object"].get("is_predator", false)
		new_object.remove_control_box.emit()
	)

	
	return new_object
