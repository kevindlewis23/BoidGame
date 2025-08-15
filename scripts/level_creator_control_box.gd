class_name ControlBox
extends Control

@export var has_rotation : bool = true
@export var has_bounding_box : bool = true

@export var can_move_checkbox : CheckBox
@export var can_rotate_checkbox : CheckBox
@export var can_collect_stars_box_container : Container
@export var can_move_and_rotate_container : Container
@export var x_position : SpinBox
@export var y_position : SpinBox
@export var rotation_box : SpinBox
@export var rotation_container : Container
@export var box_left : SpinBox
@export var box_right : SpinBox
@export var box_bottom : SpinBox
@export var box_top : SpinBox
@export var bounding_box_tab : Container
@export var bounding_box : Polygon2D
@export var object : BoundingArea
@export var connected_thing : LevelCreatorThing
@export var tab_container : TabContainer
@export var delete_button : Button
@export var is_boid : bool = false


var can_collect_stars_box : CheckBox
var is_predator_box : CheckBox
const dist_from_object : float = 40.0

var some_child_has_focus : bool = false


# Used for Level Creator state saving
var ignore_value_changes : bool = false


var clicked_here : bool = false

func _ready() -> void:
	# Connect some signals so that the delete key doesn't delete the box if you're typing in a textbox
	for textbox in [
		x_position, y_position, rotation_box, box_left, box_top, box_right, box_bottom
	]:
		textbox.get_line_edit().focus_entered.connect(func () -> void:
			some_child_has_focus = true
		)
		textbox.get_line_edit().focus_exited.connect(func () -> void:
			some_child_has_focus = false
		)

	if not has_rotation:
		can_rotate_checkbox.hide()
		rotation_container.hide()

	if not has_bounding_box:
		bounding_box_tab.queue_free()
		can_move_and_rotate_container.queue_free()
	
	if not is_boid:
		can_collect_stars_box_container.queue_free()
		# Set can_move to false by default
		can_move_checkbox.button_pressed = false
	else:
		can_collect_stars_box = can_collect_stars_box_container.get_child(0)
		can_collect_stars_box.toggled.connect(func (pressed):
			set_boid_color(pressed, is_predator_box.button_pressed)
			# var color = Constants.player_boid_color if pressed else Color.WHITE
			# object.get_child(0).get_child(0).get_child(0).color = color
		)

		is_predator_box = can_collect_stars_box_container.get_child(1)
		is_predator_box.toggled.connect(func (pressed):
			set_boid_color(can_collect_stars_box.button_pressed, pressed)
			# var color = Constants.predator_boid_color if pressed else Color.WHITE
			# object.get_child(0).get_child(0).get_child(0).color = color
		)

		is_predator_box.toggled.emit(is_predator_box.button_pressed)
	# Set bounds
	x_position.min_value = 0
	y_position.min_value = 0
	box_left.min_value = 0
	box_top.min_value = 0
	box_right.min_value = 0
	box_bottom.min_value = 0
	x_position.max_value = Constants.WIDTH
	y_position.max_value = Constants.HEIGHT
	box_left.max_value = Constants.WIDTH
	box_top.max_value = Constants.HEIGHT
	box_right.max_value = Constants.WIDTH
	box_bottom.max_value = Constants.HEIGHT
	rotation_box.min_value = -1000000
	rotation_box.max_value = 1000000
	set_values_to_current.call_deferred()

	x_position.value_changed.connect(set_pos_from_box)
	y_position.value_changed.connect(set_pos_from_box)
	rotation_box.value_changed.connect(set_rotation_from_box)

	box_left.value_changed.connect(func (_new_val) -> void:
		resize_box_from_val(false, false)
	)
	box_top.value_changed.connect(func (_new_val) -> void:
		resize_box_from_val(false, false)
	)
	box_right.value_changed.connect(func (_new_val) -> void:
		resize_box_from_val(true, false)
	)
	box_bottom.value_changed.connect(func (_new_val) -> void:
		resize_box_from_val(false, true)
	)

	connected_thing.add_control_box.connect(func(): 
		show()
		get_parent().get_parent().move_child(get_parent(), -1)
	)
	connected_thing.remove_control_box.connect(hide_if_not_focused)
	tab_container.tab_changed.connect(func (_new_index) -> void:
		var gc = object.get_global_center()
		# move box after a small delay to ensure the new tab is focused
		await get_tree().create_timer(0).timeout
		move_box(gc.x, gc.y)
	)

	delete_button.pressed.connect(remove_this)


func set_boid_color(can_collect_stars : bool, is_predator : bool) -> void:
	var color
	if can_collect_stars:
		if is_predator:
			color = Constants.predator_player_boid_color
		else:
			color = Constants.player_boid_color
	else:
		if is_predator:
			color = Constants.predator_boid_color
		else:
			color = Color.WHITE
	object.get_child(0).get_child(0).get_child(0).color = color


func resize_box_from_val(from_right : bool, from_bottom : bool) -> void:
	if not ignore_value_changes:
		LevelCreator.Instance.state_changed.emit.call_deferred()
	connected_thing.resize_box(
		box_left.value,
		box_top.value,
		box_right.value,
		box_bottom.value,
		from_right,
		from_bottom
	)

func hide_if_not_focused() -> void:
	if not clicked_here:
		hide()

func set_pos_from_box(_new_val) -> void:
	var pos = Vector2(x_position.value, y_position.value)
	object.move_to(pos, connected_thing.bounding_box_aabb)
	if not ignore_value_changes:
		LevelCreator.Instance.state_changed.emit.call_deferred()
	set_values_to_current()

func set_rotation_from_box(new_val) -> void:
	var rot = -new_val * PI / 180
	object.rotate_to(rot, connected_thing.bounding_box_aabb)
	if not ignore_value_changes:
		LevelCreator.Instance.state_changed.emit.call_deferred()
	set_values_to_current()

func set_values_to_current() -> void:
	var bbox_left = bounding_box.polygon[0].x
	var bbox_top = bounding_box.polygon[0].y
	var bbox_right = bounding_box.polygon[2].x
	var bbox_bottom = bounding_box.polygon[2].y
	var rot = -wrapf(object.get_object_rotation(),-PI,PI) * 180 / PI
	var pos = object.get_global_center()
	set_values(
		pos.x,
		pos.y,
		rot,
		bbox_left,
		bbox_top,
		bbox_right,
		bbox_bottom
	)

func set_values(x : float, y : float, rot : float, box_left_value : float, box_top_value : float,
		box_right_value : float, box_bottom_value : float) -> void:
	ignore_value_changes = true
	x_position.value = x
	y_position.value = y
	rotation_box.value = rot
	if has_bounding_box:
		box_left.value = box_left_value
		box_top.value = box_top_value
		box_right.value = box_right_value
		box_bottom.value = box_bottom_value
	move_box(x, y)
	set_deferred("ignore_value_changes", false)
	
	
func move_box(x : float, y: float):
	# Move control box
	var sz = get_child(0).size
	global_position = Vector2(x + dist_from_object, y + dist_from_object)
	# Move to top left if this is not in the viewport
	if global_position.x + sz.x > Constants.WIDTH:
		global_position.x = x - sz.x - dist_from_object
	if global_position.y + sz.y > Constants.HEIGHT:
		global_position.y = y - sz.y - dist_from_object


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var mouse_pos = get_viewport().get_mouse_position()
			# Get the control box rectangle
			var ctrl_rect = get_child(0).get_global_rect()
			if ctrl_rect.has_point(mouse_pos):
				clicked_here = true
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			set_deferred("clicked_here", false)
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide_if_not_focused()
		elif event.pressed and event.keycode == KEY_DELETE:
			if visible and not some_child_has_focus:
				remove_this()

func remove_this():
	connected_thing.tree_exited.connect(LevelCreator.Instance.state_changed.emit)
	connected_thing.queue_free()
