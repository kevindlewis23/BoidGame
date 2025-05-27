class_name StartController
extends BaseButton

@export var moving_objects_parent : Node2D
static var Instance : StartController

func _ready():
	Instance = self
	pressed.connect(start)

func start():
	# Fist, find all movable object
	var movable_things = get_tree().get_nodes_in_group("movable_things")
	# Start them all
	for thing in movable_things:
		var thing_to_replace = thing.object_to_replace_on_start
		var g_transform = thing.object_to_replace_on_start.global_transform
		# Instantiate the new object in the right place
		var new_obj = thing.object_to_relace_with.instantiate()
		
		new_obj.global_transform = g_transform
		BoidsController.Instance.add_child(new_obj)
	moving_objects_parent.hide()
	hide()
	BoidsController.Instance.start()

func reset():
	# Delete everything in moving_objects parent
	for node in BoidsController.Instance.get_children():
		moving_objects_parent.remove_child(node)
		node.queue_free()
	for star in get_tree().get_nodes_in_group("stars"):
		star.show()
	show()
	moving_objects_parent.show()
