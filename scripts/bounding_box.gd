extends BoundingArea


func _ready() -> void:
	pivot_offset = size / 2

func move_to(target_position : Vector2, outer_bounding_box: Rect2) -> void:
	# Get the AABB of the potentially rotated bounding box
	var aabb = aabb_of_rotated_rect()
	aabb.position = target_position - aabb.size / 2
	# Make the object as close as possible while within the bounding box
	position = target_position - size / 2 + get_box_delta(outer_bounding_box, aabb)

func rotate_to(target_rotation: float, outer_bounding_box: Rect2) -> bool:
	# If the rotated box is enclosed in the bounding box, then update the rotation
	var old_rotation = rotation
	rotation = target_rotation
	var rotated_aabb = aabb_of_rotated_rect()
	if outer_bounding_box.encloses(rotated_aabb):
		return true
	else:
		rotation = old_rotation
		return false

func get_object_rotation() -> float:
	""" Get the current rotation of this node """
	return rotation

func get_center() -> Vector2:
	var obj_box = aabb_of_rotated_rect()
	return obj_box.position + obj_box.size / 2

# Helper functions

func aabb_of_rotated_rect():
	""" Get the AABB of a rotated rectangle """
	# Box rect position is wrong by default, we need to fix it
	var box_rect = get_global_rect()
	box_rect.position = find_actual_position(box_rect.position, box_rect.size, rotation)
	var corners = [
		box_rect.position,
		box_rect.end,
		Vector2(box_rect.position.x, box_rect.end.y),
		Vector2(box_rect.end.x, box_rect.position.y)
	]
	var center = box_rect.position + box_rect.size / 2
	
	# Create a size 0 aabb at the center, and we will merge all the rotated points
	var aabb = Rect2(center, Vector2.ZERO)
	for point in corners:
		# Rotate to the correct position
		point = rotate_point(point, center, rotation)
		# Make the aabb contain this point
		aabb = aabb.merge(Rect2(point, Vector2.ZERO))
	# The position is wrong because of rotation, here's a correction factor
	return aabb
	
func rotate_point(point: Vector2, center:Vector2, theta: float):
	return Vector2(
		center.x+(point.x-center.x)*cos(theta)+(point.y-center.y)*sin(theta),
		center.y-(point.x-center.x)*sin(theta)+(point.y-center.y)*cos(theta)
	)

func find_actual_position(fake_position : Vector2, size: Vector2, theta: float):
	return fake_position + Vector2(
		.5 * (size.x * cos(theta) - size.x - size.y * sin(theta)),
		.5 * (size.x * sin(theta) - size.y + size.y * cos(theta))
	)
