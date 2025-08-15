# Hud controller for actually playing a level
class_name LevelHudController
extends BaseHudController

static var Instance : LevelHudController


@export var moving_objects_parent : Node2D
@export var last_positions_parent : Control
@export var start_button : Button
@export var reset_button : Button

@export var increase_speed_button : Button
@export var decrease_speed_button : Button
@export var sim_speed_label : Label

var path_scene : PackedScene = load("res://misc_objects/path.tscn")

func _ready():
	super._ready()
	Instance = self
	start_button.pressed.connect(start)
	reset_button.pressed.connect(reset)
	increase_speed_button.pressed.connect(increase_speed)
	decrease_speed_button.pressed.connect(decrease_speed)


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventKey and event.pressed:
		if ((event.keycode == KEY_SPACE or event.keycode == KEY_ENTER) 
				and not BoidsController.Instance.running):
				start()
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_E:
			# Toggle the visibility of the paths
			extras_visibility = not extras_visibility
			for path in get_tree().get_nodes_in_group("paths"):
				path.visible = extras_visibility
			# Maybe show/hide the last positions parent (assuming we are not currently running the simulation)
			if moving_objects_parent.visible:
				last_positions_parent.visible = extras_visibility
		# Simulation speed stuff
		elif event.is_command_or_control_pressed() and event.keycode == KEY_RIGHT:
			increase_speed()
		elif event.is_command_or_control_pressed() and event.keycode == KEY_LEFT:
			decrease_speed()

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
	last_positions_parent.hide()
	start_button.hide()
	reset_button.show()
	
	BoidsController.Instance.start()


# Simulation speed
func increase_speed():
	if cur_speed < max_speed:
		cur_speed += 1
		sim_speed_label.text = BoidsController.Instance.set_speed(cur_speed)

func decrease_speed():
	if cur_speed > -max_speed:
		cur_speed -= 1
		sim_speed_label.text = BoidsController.Instance.set_speed(cur_speed)


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
	reset_button.hide()
	start_button.show()