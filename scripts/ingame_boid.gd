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


func _ready():
	super._ready()
	collider.area_entered.connect(collide)
	
	star_count = get_tree().get_nodes_in_group("stars").size()
	must_be_in_area = Rect2(SCENE_LEFT -lose_margin, SCENE_TOP-lose_margin,
							SCENE_RIGHT - SCENE_LEFT + 2 * lose_margin,
							SCENE_BOTTOM - SCENE_TOP + 2 * lose_margin)
	path = load("res://misc_objects/path.tscn").instantiate() as Path
	get_tree().root.get_child(0).add_child(path)
	path.visible = StartController.Instance.extras_visibility

func _exit_tree() -> void:
	# Move path
	get_tree().root.get_child(0).remove_child(path)
	StartController.Instance.last_positions_parent.add_child(path)
	
func collide(other_collider : Area2D):
	var other_object = other_collider.get_parent()
	if other_object.is_in_group("stars"):
		collide_with_star(other_object)
	elif other_object.is_in_group("zappers"):
		collide_with_zapper(other_object)
	elif other_object.is_in_group("predator_boids") and is_in_group("boids"):
		collide_with_predator(other_object)		

func _physics_process(_delta : float):
	# Lose if you are too far out of the bounds
	if is_dead:
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
	

# Overridden from Boid
func calc_next_position_and_angle(delta: float) -> void:
	super.calc_next_position_and_angle(delta)
	path.points.append(position)

func collide_with_star(star : Node2D):
	if is_main_boid:
		star_count-=1
		star.hide()
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
	BoidsController.Instance.running = false
	StartController.Instance.leave_to_home.call_deferred()

func lose(reason : String):
	print("You lose")
	print(reason)
	BoidsController.Instance.running = false
	StartController.Instance.reset.call_deferred()
