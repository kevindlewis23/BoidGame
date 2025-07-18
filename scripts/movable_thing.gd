class_name MovableThing
extends Node2D

signal moved


@export var can_rotate : bool = true
@export var can_move : bool = true
@export var bounding_box : Polygon2D
@export var moving_object_bounding_box : BoundingArea
@export var bounding_box_hover_color : Color = Color(1, 1, 1, .02)
@export var bounding_box_base_color : Color = Color.TRANSPARENT

@export var object_to_replace_on_start : Node2D
@export var object_to_replace_with : PackedScene

# how long after clicking the mouse button before you can actually move the object
const tap_time = .1

# Boundaries
var bounding_box_aabb : Rect2
var is_hovered : bool = false

var is_level_creator_thing : bool = false



var click_down_position : Vector2
var clicked: bool = false

var viewport : Viewport
var is_dragging : bool = false
var is_dragging_has_actually_started : bool = false
var is_rotating : bool = false
var look_at_segment : Line2D = null

func _ready() -> void:
	viewport = get_viewport()
	bounding_box_aabb = get_rect_bounds(bounding_box)
	moving_object_bounding_box.mouse_entered.connect(set_hovered)
	moving_object_bounding_box.mouse_exited.connect(set_unhovered)
	set_unhovered()
	# Add a tooltip unless this is a level_creator thing
	if not is_level_creator_thing:
		var help_text = "✅ move" if can_move else "❌ move" 
		# Add rotation if it is enabled, if it is not something like a repeller (can't be rotated anyway)
		if not self.is_in_group("movable_things_that_definitely_dont_rotate"):
			help_text += ", ✅ rotate" if can_rotate else ", ❌ rotate"
		moving_object_bounding_box.tooltip_text = help_text

func get_rect_bounds(box : Polygon2D):
	var aabb = Rect2(box.polygon[0], Vector2.ZERO)
	for point in box.polygon:
		aabb = aabb.merge(Rect2(point, Vector2.ZERO))
	aabb.position += box.global_position
	return aabb

func set_hovered():
	if can_move or can_rotate:
		is_hovered = true
		bounding_box.color = bounding_box_hover_color

func set_unhovered():
	is_hovered = false
	if not is_dragging and not is_rotating:
		bounding_box.color = bounding_box_base_color

func _input( event ):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.is_pressed() and is_hovered and can_move:
			start_dragging()
		elif event.button_index == 1 and not event.is_pressed() and can_move:
			stop_dragging()
			if not is_hovered and not is_rotating:
				bounding_box.color = bounding_box_base_color
		elif event.button_index == 2 and event.is_pressed() and is_hovered and can_rotate:
			is_rotating = true
			LevelCreator.right_click_captured = true
		elif event.button_index == 2 and not event.is_pressed() and can_rotate:
			is_rotating = false
			if look_at_segment:
				remove_child(look_at_segment)
				look_at_segment = null
			if not is_hovered and not is_dragging:
				bounding_box.color = bounding_box_base_color


func start_dragging():
	if not is_dragging:
		is_dragging = true
		is_dragging_has_actually_started = false
		# Set a timeout to start dragging
		get_tree().create_timer(tap_time).timeout.connect(func():
			if is_dragging:
				is_dragging_has_actually_started = true
		)

func stop_dragging():
	is_dragging = false
	is_dragging_has_actually_started = false

func _process(_delta):
	if is_dragging and is_dragging_has_actually_started:
		var target_position = viewport.get_mouse_position()
		moving_object_bounding_box.move_to(target_position, bounding_box_aabb)
		moved.emit()
	elif is_rotating:
		var obj_center = moving_object_bounding_box.get_center()
		
		var local_mouse_position =  viewport.get_mouse_position() - global_position
		var look_angle = obj_center.angle_to_point(local_mouse_position)
		
		# Aesthetic purposes, draw the look_vector
		if look_at_segment:
			look_at_segment.clear_points()
			look_at_segment.add_point(obj_center)
			look_at_segment.add_point(local_mouse_position)
		else:
			look_at_segment = Line2D.new()
			look_at_segment.width = 3
			look_at_segment.add_point(obj_center)
			look_at_segment.add_point(local_mouse_position)
			look_at_segment.antialiased = true
			look_at_segment.z_index = -1
			add_child(look_at_segment)

		# Try to rotate
		if moving_object_bounding_box.rotate_to(look_angle, bounding_box_aabb):
			look_at_segment.default_color = Color(1, 1, 1, .3)
			moved.emit()
		else:
			look_at_segment.default_color = Color(1, 0, 0)
