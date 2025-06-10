"""Abstract class for a bounding box or bounding circle"""
class_name BoundingArea

extends Control


func move_to(target_position : Vector2, outer_bounding_box: Rect2) -> void:
	"""Move as close to the target position as possible"""

func rotate_to(target_rotation: float, outer_bounding_box: Rect2) -> bool:
	"""Try to rotate to the target position, if it fails, return false"""
	return false

func get_object_rotation() -> float:
	"""Get the current rotation of this node"""
	return 0.0

func get_center() -> Vector2:
	"""Get the center of this node"""
	return Vector2()

func get_global_center() -> Vector2:
	"""Get the global center of this node"""
	return get_center() + global_position - position

# Helper function that will be useful in subclasses
static func get_box_delta(aabb1:Rect2, aabb2: Rect2):
	""" Figure out how far we need to move aabb2 so it fits in aabb1 """
	var delta = Vector2()
	# right
	if aabb2.end.x > aabb1.end.x:
		delta.x += aabb1.end.x - aabb2.end.x
	# left
	elif aabb2.position.x < aabb1.position.x:
		delta.x += aabb1.position.x - aabb2.position.x
	# top
	if aabb2.position.y < aabb1.position.y:
		delta.y += aabb1.position.y - aabb2.position.y
	# bottom
	elif aabb2.end.y > aabb1.end.y:
		delta.y += aabb1.end.y - aabb2.end.y
	return delta
