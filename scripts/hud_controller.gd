class_name HudController
extends Control

@export var hud_bar : Control
@export var moving_objects_parent : Node2D
@export var last_positions_parent : Control
@export var start_button : Button
@export var reset_button : Button
@export var increase_speed_button : Button
@export var decrease_speed_button : Button
@export var leave_button : Button
@export var sim_speed_label : Label
static var Instance : HudController

var path_scene : PackedScene = load("res://misc_objects/path.tscn")
# Static so it stores over multiple levels
static var extras_visibility : bool = true

var scene_is_changing : bool = false

# Current simulation speed
var cur_speed = 0
var max_speed = 3


const TOP_OF_SCREEN_MARGIN = 10
# Everyone hates a hud bar the dissappears when you try to click stuff 
const DISTANCE_BELOW_HUD_BAR_TO_HIDE = 30

const HUD_BAR_HIDE_TIME = 2.0
var hud_bar_force_shown = true

func _ready():
	Instance = self
	start_button.pressed.connect(start)
	reset_button.pressed.connect(reset)
	increase_speed_button.pressed.connect(increase_speed)
	decrease_speed_button.pressed.connect(decrease_speed)
	leave_button.pressed.connect(leave_to_home)

	# Allow the hud bar to be hidden after a couple seconds
	get_tree().create_timer(HUD_BAR_HIDE_TIME).timeout.connect(func():
		hud_bar_force_shown = false
	)

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
	

# Handling hudbar visibility
var last_mouse_y_pos = 0
func _process(_delta):
	if hud_bar_force_shown: return
	# Show when the mouse hits the top of the screen
	# I could show it always, but then I would have to change the levels to handle that
	# That's not a problem, but if I want to eventually make this work for mobile, the hud will have to be different and the margins I built in to the levels directly would be useless.
	var mouse_y_pos = get_global_mouse_position().y

	if (not hud_bar.visible and 
		mouse_y_pos < last_mouse_y_pos and # mouse moved upwards, I don't want to show the hud if something was clicked and dragged up to the top of the screen and then the mouse moves downward
		not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) and # not pressing a mouse button
		mouse_y_pos <= TOP_OF_SCREEN_MARGIN): # Far enough up on the screen
		hud_bar.visible = true
	elif (hud_bar.visible and mouse_y_pos > hud_bar.size.y + DISTANCE_BELOW_HUD_BAR_TO_HIDE):
		hud_bar.visible = false
	last_mouse_y_pos = mouse_y_pos

# I had the _process function as part of _input earlier (using the event input_mouse_moved or something like that), but
# putting it in process instead allows it to work if the mouse moves off the screen I think
func _input(event):
	# Always hide if you click below the hud bar
	if event is InputEventMouseButton:
		if event.pressed and event.position.y > hud_bar.size.y:
			hud_bar.visible = false



# Unhandles stuff in case you are typing on something else
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
		# Simulation speed stuff
		elif event.pressed and event.is_command_or_control_pressed() and event.keycode == KEY_RIGHT:
			increase_speed()
		elif event.pressed and event.is_command_or_control_pressed() and event.keycode == KEY_LEFT:
			decrease_speed()

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

func leave_to_home():
	scene_is_changing = true
	set_deferred("scene_is_changing", false)
	get_tree().change_scene_to_file(LevelInstanceProps.scene_to_return_to)
