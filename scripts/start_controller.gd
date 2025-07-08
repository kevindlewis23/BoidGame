class_name StartController
extends BaseButton

@export var moving_objects_parent : Node2D
static var Instance : StartController

func _ready():
	Instance = self
	pressed.connect(start)

func start():
	IngameBoid.num_main_boids = 0
	# Fist, find all movable object
	var movable_things = get_tree().get_nodes_in_group("movable_things")
	# Start them all
	
	for thing in movable_things:
		var g_transform = thing.object_to_replace_on_start.global_transform
		# Instantiate the new object in the right place
		var new_obj = thing.object_to_replace_with.instantiate()
		
		new_obj.global_transform = g_transform
		BoidsController.Instance.add_child(new_obj)
		if new_obj is IngameBoid and new_obj.is_main_boid:
			IngameBoid.num_main_boids += 1
	moving_objects_parent.hide()
	hide()
	BoidsController.Instance.start()

# Reset on pressing r
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_R:
			reset()
		elif event.pressed and event.keycode == KEY_ESCAPE:
			# get_tree().quit()
			leave_to_home()
		elif event.pressed and event.keycode == KEY_Q:
			leave_to_home()
		elif (event.pressed and 
			(event.keycode == KEY_SPACE or event.keycode == KEY_ENTER) 
			and not BoidsController.Instance.running):
			start()


func reset():
	BoidsController.Instance.running = false
	# Delete all boids
	for node in BoidsController.Instance.get_children():
		BoidsController.Instance.remove_child(node)
		node.queue_free()
	for star in get_tree().get_nodes_in_group("stars"):
		star.show()
	show()
	moving_objects_parent.show()

func leave_to_home():
	get_tree().change_scene_to_file(LevelInstanceProps.scene_to_return_to)
