"""
This is square control so we can use hover stuff
However, it acts like a circle, since it has a child that freely instead of rotating itself
"""
extends BoundingArea

@export var child_rotator : Node2D

func move_to(target_position : Vector2, outer_bounding_box: Rect2) -> void:
	# First, get an aabb of this
	var test_aabb = get_global_rect()
	test_aabb.position = target_position - size / 2
	position = target_position - size / 2 + get_box_delta(outer_bounding_box, test_aabb)

func rotate_to(target_rotation: float, outer_bounding_box: Rect2) -> bool:
	child_rotator.rotation = target_rotation
	return true

func get_center() -> Vector2:
	return position + size/2
