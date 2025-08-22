class_name BoidsController

extends Node

# Simulation speed must be an integer
# If fast forward is set to true, then this is the number of physics ticks that run per frame
# If it is set to false, this is the number of frames it takes for a physics tick to happen
@export var SIMULATION_SPEED : int = 1
@export var FAST_FORWARD : bool = true
@export var auto_start : bool = false

static var Instance : BoidsController

var frame_number = 0
var obstacles : Array = []
var boids: Array = []
var predators: Array = []
var obstacles_and_predators: Array = []
var boids_and_predators: Array = []

var running = false

func _ready():
	Instance = self
	if auto_start:
		start()

func start():
	boids = get_tree().get_nodes_in_group("boids")
	obstacles = get_tree().get_nodes_in_group("obstacles")
	predators = get_tree().get_nodes_in_group("predator_boids")

	obstacles_and_predators = obstacles + predators
	boids_and_predators = boids + predators
	frame_number = 0
	running = true

# On fixed update
func _physics_process(delta: float) -> void:
	if running:
		if FAST_FORWARD:
			for __ in range(SIMULATION_SPEED):
				physics_tick(delta)
				lerp_all_boids(1)
		else:
			if frame_number == 0:
				physics_tick(delta)
			lerp_all_boids(SIMULATION_SPEED - frame_number)
			frame_number += 1
			if frame_number >= SIMULATION_SPEED:
				frame_number = 0


func physics_tick(delta : float) -> void:
	# Calculate all the velocities first before moving the boids, for determinism
	for boid in boids_and_predators:
		boid.calc_velocity(delta, boids, obstacles_and_predators)
	for boid in boids_and_predators:
		boid.calc_next_position_and_angle(delta)
	if (LevelHudController.Instance and # There is currently a HUD, meaning we're in the right scene
		IngameBoid.star_collecting_boids.size() > 0 and # There are star collecting boids
		IngameBoid.star_collecting_boids.all(func(boid): return not boid or boid.is_dead or boid.is_out_of_bounds())): # They're all dead or out of bounds
			IngameBoid.lose("All star collecting boids are dead or out of bounds")

func lerp_all_boids(lerp_number: int):
	for boid in boids_and_predators:
		boid.lerp_to_new_position_and_angle(lerp_number)

func remove_boid(boid: Node):
	if boid in boids:
		boids.erase(boid)
		boids_and_predators.erase(boid)
	elif boid in predators:
		predators.erase(boid)
		obstacles_and_predators.erase(boid)
		boids_and_predators.erase(boid)

func set_speed(speed: int) -> String:
	# Setting the simulation speed but from a different way of representing speed
	# 0 is normal, -1 is half, 1 is double, etc
	# Return a string to display sim speed
	if speed == 0:
		SIMULATION_SPEED = 1
		FAST_FORWARD = true
		return "1x"
	elif speed < 0:
		SIMULATION_SPEED = -speed + 1
		FAST_FORWARD = false
		return "%.2fx" % (1.0 / SIMULATION_SPEED)
	else:
		SIMULATION_SPEED = speed + 1
		FAST_FORWARD = true
		return "%.2fx" % SIMULATION_SPEED
