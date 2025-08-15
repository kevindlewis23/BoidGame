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
static var star_count = 0
var must_be_in_area : Rect2

static var num_main_boids = 1
var is_dead : bool = false

static var objects_being_deleted : Array = []

static var win_screen : PackedScene = load("res://ui/win_screen.tscn")

static var has_won : bool = false


func _ready():
	super._ready()
	has_won = false
	collider.area_entered.connect(collide)
	
	star_count = get_tree().get_nodes_in_group("stars").size()
	must_be_in_area = Rect2(SCENE_LEFT -lose_margin, SCENE_TOP-lose_margin,
							SCENE_RIGHT - SCENE_LEFT + 2 * lose_margin,
							SCENE_BOTTOM - SCENE_TOP + 2 * lose_margin)
	path = load("res://misc_objects/path.tscn").instantiate() as Path
	get_tree().current_scene.add_child(path)
	path.visible = LevelHudController.Instance.extras_visibility

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
	if is_main_boid and not must_be_in_area.has_point(global_position):
		is_dead = true
		num_main_boids -= 1
		if num_main_boids <= 0:
			lose("You swam out of the map!!")
		else:
			remove_this()

func _draw() -> void:
	if is_main_boid:
		draw_circle(Vector2.ZERO, VISION_RADIUS, Color(1,1,1,.015))

func remove_this():
	BoidsController.Instance.remove_boid(self)
	queue_free()
	objects_being_deleted.append(self)
	

# Overridden from Boid
func calc_next_position_and_angle(delta: float) -> void:
	super.calc_next_position_and_angle(delta)
	path.points.append(position)

func collide_with_star(star : Node2D):
	if is_main_boid:
		star_count-=1
		star.hide()
		objects_being_deleted.append(star)
		if star_count <= 0:
			win()

func collide_with_zapper(_zapper : Node2D):
	lose("You got zapped!")

func collide_with_predator(_predator : Node2D):
	is_dead = true
	remove_this()
	if is_main_boid:
		num_main_boids -= 1
		if num_main_boids <= 0:
			lose("You got eaten!")

func win():
	print("You win!!!!!!!")
	has_won = true
	# BoidsController.Instance.running = false
	# Return to level creator if that is the scene to return to
	if LevelInstanceProps.level_number == 0:
		LevelHudController.Instance.leave_to_home.call_deferred()
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

func lose(reason : String):
	if has_won:
		return
	print("You lose")
	print(reason)
	BoidsController.Instance.running = false
	LevelHudController.Instance.reset.call_deferred()
