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

var running = false

func _ready():
	Instance = self
	if auto_start:
		start()

func start():
	boids = get_tree().get_nodes_in_group("boids")
	obstacles = get_tree().get_nodes_in_group("obstacles")
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
	for boid in boids:
		boid.calc_velocity(delta, boids, obstacles)
	for boid in boids:
		boid.calc_next_position_and_angle(delta)

func lerp_all_boids(lerp_number: int):
	for boid in boids:
		boid.lerp_to_new_position_and_angle(lerp_number)
