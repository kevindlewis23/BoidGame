extends BaseButton

@export var moving_objects_parent : Node2D

func _ready():
	pressed.connect(start)

func start():
	# Fist, find all movable object
	var movable_things = get_tree().get_nodes_in_group("movable_things")
	# Start them all
	for thing in movable_things:
		var thing_to_replace = thing.object_to_replace_on_start
		var g_pos = thing_to_replace.global_position
		var g_rot = thing_to_replace.global_rotation
		# Instantiate the new object in the right place
		var new_obj = thing.object_to_relace_with.instantiate()
		new_obj.global_position = g_pos
		new_obj.global_rotation = g_rot
		# Add this object to the scene
		BoidsController.Instance.add_child(new_obj)
	moving_objects_parent.hide()
	hide()
	BoidsController.Instance.start()
