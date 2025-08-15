# Abstractions for both in game hud and level creator hud
class_name BaseHudController
extends Control

@export var hud_bar : Control
@export var info_button : Button

@export var leave_button : Button

@export var level_name : Control
@export var info_text : Control
@export var info_close_button : Button
@export var info_overlay : Control



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
# Number of different reasons the hud bar should be force shown at any given time
var hud_bar_force_shown = 0

func _ready():
	
	leave_button.pressed.connect(leave_to_home)
	info_close_button.pressed.connect(close_this)
	info_button.pressed.connect(toggle_info)
	# Allow the hud bar to be hidden after a couple seconds
	force_show_hud_bar_for_a_bit()
	
	
func force_show_hud_bar_for_a_bit():
	hud_bar_force_shown += 1
	get_tree().create_timer(HUD_BAR_HIDE_TIME).timeout.connect(func():
		hud_bar_force_shown -= 1
	)


func toggle_info():
	info_overlay.visible = not info_overlay.visible
	if info_overlay.visible:
		hud_bar_force_shown += 1
	else:
		hud_bar_force_shown -= 1

# Close info if it is shown, otherwise leave
func close_this():
	if info_overlay.visible:
		toggle_info()
	else:
		leave_to_home()
		
# Handling hudbar visibility
var last_mouse_y_pos = 0
func _process(_delta):
	# Should never be less than 0, but if it gets reset and decreased due to a timer, I want to reset this
	if hud_bar_force_shown < 0: hud_bar_force_shown = 0
	elif hud_bar_force_shown > 0: 
		hud_bar.visible = true
		return
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
		if event.pressed and event.position.y > hud_bar.size.y and not info_overlay.visible:
			hud_bar.visible = false
			hud_bar_force_shown = 0



# Unhandles stuff in case you are typing on something else
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_Q:
			close_this()
		elif event.keycode == KEY_I:
			toggle_info()


func leave_to_home():
	scene_is_changing = true
	set_deferred("scene_is_changing", false)
	get_tree().change_scene_to_file(LevelInstanceProps.scene_to_return_to)
