extends Boid

"""Boid that has collisions"""

# Is it the boid that needs to reach the star
@export var is_main_boid : bool = true
@export var collider : Area2D

# Distance 
@export var lose_margin : float = 200

var star_count = 0
var must_be_in_area : Rect2

func _ready():
	collider.area_entered.connect(collide)
	star_count = get_tree().get_nodes_in_group("stars").size()
	must_be_in_area = Rect2(SCENE_LEFT -lose_margin, SCENE_TOP-lose_margin,
							SCENE_RIGHT - SCENE_LEFT + 2 * lose_margin,
							SCENE_BOTTOM - SCENE_TOP + 2 * lose_margin)
	
func collide(other_collider : Area2D):
	var other_object = other_collider.get_parent()
	if other_object.is_in_group("Star"):
		collide_with_star(other_object)
		

func _physics_process(_delta : float):
	# Lose if you are too far out of the bounds
	if is_main_boid and not must_be_in_area.has_point(global_position):
		lose("You swam out of the map!!")
	
	

func collide_with_star(star : Node2D):
	if is_main_boid:
		star_count-=1
		star.hide()
		if star_count <= 0:
			win()


func win():
	print("you win!!!!!!!")
	BoidsController.Instance.running = false

func lose(reason : String):
	print("You lose")
	print(reason)
	BoidsController.Instance.running = false
