class_name IngameBoid
extends Boid

"""Boid that has collisions"""

# Is it the boid that needs to reach the star
@export var is_main_boid : bool = true
@export var collider : Area2D

# Distance 
@export var lose_margin : float = 200
var path : Path

# Static in case there are multiple boids that can collect stars
static var stars = []
var must_be_in_area : Rect2

static var star_collecting_boids = []
var is_dead : bool = false

static var objects_being_deleted : Array = []

static var win_screen : PackedScene = load("res://ui/win_screen.tscn")
static var win_screen_from_load : PackedScene = load("res://ui/win_screen_from_load.tscn")

static var has_won : bool = false


func _ready():
	super._ready()
	has_won = false
	collider.area_entered.connect(collide)
	
	stars = get_tree().get_nodes_in_group("stars")
	must_be_in_area = Rect2(SCENE_LEFT -lose_margin, SCENE_TOP-lose_margin,
							SCENE_RIGHT - SCENE_LEFT + 2 * lose_margin,
							SCENE_BOTTOM - SCENE_TOP + 2 * lose_margin)
	path = load("res://misc_objects/path.tscn").instantiate() as Path
	get_tree().current_scene.add_child(path)
	path.visible = LevelHudController.paths_visibility

func _exit_tree() -> void:
	# Ignore if the scene is changing
	if LevelHudController.Instance.scene_is_changing:
		return
	# Move path
	get_tree().current_scene.remove_child(path)
	LevelHudController.Instance.last_positions_parent.add_child(path)
	
func collide(other_collider : Area2D):
	var other_object = other_collider.get_parent()
	# If two boids that can collect stars hit a star on the same frame, I don't want it to be double counted
	# Same with boids that get eaten, I don't want a double free
	if self in objects_being_deleted or other_object in objects_being_deleted:
		return
	if other_object.is_in_group("stars"):
		collide_with_star(other_object)
	elif other_object.is_in_group("zappers"):
		collide_with_zapper(other_object)
	elif other_object.is_in_group("predator_boids") and is_in_group("boids"):
		collide_with_predator(other_object)		

func _physics_process(_delta : float):
	objects_being_deleted = []
	# Lose if you are too far out of the bounds
	if is_dead or has_won:
		return

func _draw() -> void:
	if is_main_boid:
		draw_circle(Vector2.ZERO, VISION_RADIUS, Color(1,1,1,.015))

func remove_this():
	BoidsController.Instance.remove_boid(self)
	queue_free()
	objects_being_deleted.append(self)
	

func is_out_of_bounds() -> bool:
	return not must_be_in_area.has_point(global_position)

# Overridden from Boid
func calc_next_position_and_angle(delta: float) -> void:
	super.calc_next_position_and_angle(delta)
	path.points.append(position)

func collide_with_star(star : Node2D):
	if is_main_boid:
		star.hide()
		objects_being_deleted.append(star)
		# I was keeping track of a count of the stars but there was a bug that I had once that I could never reproduce and couldn't explain so I'm doing this instead
		# It was in a level with only one boid that could collect stars, so I don't really understand how it could've happened, but I won without collecting all stars
		if stars.all(func (item): return not item.visible):
			win()

func collide_with_zapper(_zapper : Node2D):
	lose("You got zapped!")

func collide_with_predator(_predator : Node2D):
	is_dead = true
	remove_this()

func win():
	print("You win!!!!!!!")
	IngameBoid.star_collecting_boids = []
	has_won = true
	# BoidsController.Instance.running = false
	# Return to level creator if that is the scene to return to
	if LevelInstanceProps.scene_to_return_to == "res://level_creator.tscn":
		LevelHudController.Instance.leave_to_home.call_deferred()
	# Level loaded from the load button in the level selector
	elif LevelInstanceProps.level_number == 0:
		var win_screen_instance = win_screen_from_load.instantiate()
		get_tree().current_scene.add_child(win_screen_instance)
	else:
		# Create the win screen
		var win_screen_instance = win_screen.instantiate()
		get_tree().current_scene.add_child(win_screen_instance)
		# Add the level number to the list of passed levels
		if not FileAccess.file_exists(Constants.passed_levels_file_path):
			var file = FileAccess.open(Constants.passed_levels_file_path, FileAccess.WRITE)
			file.store_string(JSON.stringify([LevelInstanceProps.level_number]))
			file.close()
		else:
			var file = FileAccess.open(Constants.passed_levels_file_path, FileAccess.READ_WRITE)
			var json_data = file.get_as_text()
			var json = JSON.new()
			var error = json.parse(json_data)
			if error == OK:
				var passed_levels = json.data
				var level_has_been_passed = false
				for level in passed_levels:
					if level == LevelInstanceProps.level_number:
						level_has_been_passed = true
						break
				if not level_has_been_passed:
					passed_levels.append(LevelInstanceProps.level_number)
					file.seek(0)
					file.store_string(JSON.stringify(passed_levels))
			else:
				push_error("Failed to parse passed levels file: %s" % json.get_error_message())
			file.close()

static func lose(_reason : String):
	if has_won:
		return
	IngameBoid.star_collecting_boids = []
	print("You lose")
	# print(reason)
	BoidsController.Instance.running = false
	LevelHudController.Instance.reset.call_deferred()
