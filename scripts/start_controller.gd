class_name StartController
extends BaseButton

@export var moving_objects_parent : Node2D
@export var last_positions_parent : Control
static var Instance : StartController

var path_scene : PackedScene = load("res://misc_objects/path.tscn")
# Static so it stores over multiple levels
static var extras_visibility : bool = true

func _ready():
	Instance = self
	pressed.connect(start)

func start():
	IngameBoid.num_main_boids = 0
	# Fist, find all movable object
	var movable_things = get_tree().get_nodes_in_group("movable_things")
	# Start them all
	if last_positions_parent:
		# Remove all children from the last positions parent
		for child in last_positions_parent.get_children():
			child.queue_free()
	for thing in movable_things:
		var g_transform = thing.object_to_replace_on_start.global_transform
		if last_positions_parent:
			# Copy the sprite into the last positions parent
			var old_sprite_obj = thing.moving_object_bounding_box.get_child(0).get_child(0)
			var sprite_obj = old_sprite_obj.duplicate()
			sprite_obj.global_transform = old_sprite_obj.global_transform
			last_positions_parent.add_child(sprite_obj)

		# Instantiate the new object in the right place
		var new_obj = thing.object_to_replace_with.instantiate()
		
		new_obj.global_transform = g_transform
		BoidsController.Instance.add_child(new_obj)
		if new_obj is IngameBoid and new_obj.is_main_boid:
			IngameBoid.num_main_boids += 1
	moving_objects_parent.hide()
	hide()
	last_positions_parent.hide()
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
		elif event.pressed and event.keycode == KEY_E:
			# Toggle the visibility of the paths
			extras_visibility = not extras_visibility
			for path in get_tree().get_nodes_in_group("paths"):
				path.visible = extras_visibility
			# Maybe show/hide the last positions parent (assuming we are not currently running the simulation)
			if moving_objects_parent.visible:
				last_positions_parent.visible = extras_visibility


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
	last_positions_parent.visible = extras_visibility

func leave_to_home():
	get_tree().change_scene_to_file(LevelInstanceProps.scene_to_return_to)
