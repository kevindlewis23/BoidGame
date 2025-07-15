class_name Boid

extends Node2D

# px/s
@export var MAX_SPEED : float = 500
@export var MIN_SPEED : float = 300
# px/s/s
@export var MAX_ACCELERATION : float = 1000
# from 0 to 1, purely visual, doesn't affect the actual motion
@export var VISUAL_ANGULAR_MOMENTUM = 0.6

# Boid rule stuff
# px
@export var VISION_RADIUS : float = 200
@export var SEPARATION_DISTANCE: float = 100
@export var OBSTACLE_AVOID_DISTANCE : float = 200
@export var WALL_AVOID_DISTANCE : float = 300
# Around 0 to 1
@export var SEPARATION : float = 0.5
@export var WALL_AVOIDANCE : float = 20
@export var OBSTACLE_AVOIDANCE : float = 4
@export var ALIGNMENT : float = 0.8
@export var COHESION : float = 0.3

# How close (in radians) the acceleration has to be from being in the exact opposite direction as velocity to add a slight turn
@export var SHOULD_TURN_EPSILON : float = .04
@export var SHOULD_TURN_MIN_ACCELERATION : float = MAX_ACCELERATION/2
@export var SHOULD_TURN_ROTATION : float = -PI/4

# Whether or not to teleport when you swim off the map (like pacman)
@export var MAP_IS_TORUS : bool = false

# Cohesion factor when COHESION is set to 1
const COHESION_BASE_FACTOR = .04
const SEPARATION_BASE_FACTOR = 80
const ALIGNMENT_BASE_FACTOR = .3


const SCENE_LEFT = 0
var SCENE_RIGHT = Constants.WIDTH
const SCENE_TOP = 0
var SCENE_BOTTOM = Constants.HEIGHT


var next_velocity : Vector2 = Vector2()
var last_velocity : Vector2 = Vector2()

# For lerping between frames
var next_position
var next_rotation


func _ready():
	next_velocity = Vector2((MIN_SPEED + MAX_SPEED) / 2, 0).rotated(rotation)
	last_velocity = next_velocity

# Separating movement and calculation to ensure determinism,
# First calculate all the velocities for each boid based on current positions
func calc_next_position_and_angle(delta: float) -> void:
	last_velocity = next_velocity
	next_position = position + next_velocity * delta
	var target_angle = next_velocity.angle()
	
	next_rotation = lerp_angle(rotation, target_angle, 1-VISUAL_ANGULAR_MOMENTUM)

# Keeping this separate from get_next_position_angle_angle so that I can 
# lerp between frames for smooth slow motion
func lerp_to_new_position_and_angle(frames_left : int):
	# Frames left should always be a positive number, but in case something is wrong, make sure we don't divide by 0
	frames_left = max(frames_left, 1)
	position = lerp(position, next_position, 1.0/frames_left)
	rotation = lerp_angle(rotation, next_rotation, 1.0/frames_left)
	if frames_left == 1 and MAP_IS_TORUS:
		# If you are actually in the final location, make sure to wrap your position
		position.x = wrapf(position.x, SCENE_LEFT, SCENE_RIGHT)
		position.y = wrapf(position.y, SCENE_TOP, SCENE_BOTTOM)
		

func calc_velocity(delta : float, all_boids : Array, obstacles : Array) -> void:
	# Get the boids near you
	var close_boids = get_close_elements(all_boids, VISION_RADIUS)

	var close_obstacles = get_close_elements(obstacles, OBSTACLE_AVOID_DISTANCE)
	var velocity_change = (cohere(close_boids) * COHESION +
						  separate(close_boids, SEPARATION_DISTANCE) * SEPARATION + 
						  separate(close_obstacles, OBSTACLE_AVOID_DISTANCE) * OBSTACLE_AVOIDANCE +
						  avoid_walls() * WALL_AVOIDANCE +
						  align(close_boids) * ALIGNMENT)
	
	# If velocity_change is in the exact opposite direction as velocity, add a slight right turn so you don't run straight into things
	if (PI - absf(next_velocity.angle_to(velocity_change)) < SHOULD_TURN_EPSILON and
		velocity_change.length_squared() > (SHOULD_TURN_MIN_ACCELERATION * delta)**2):
		velocity_change = velocity_change.rotated(SHOULD_TURN_ROTATION)
	
	next_velocity += velocity_change.limit_length(delta * MAX_ACCELERATION)
	next_velocity = clamp_vector(next_velocity, MIN_SPEED, MAX_SPEED) 

# Get the elements of a list that are within a radius of you
func get_close_elements(elements : Array, radius : float) -> Array:
	var sqr_radius = radius * radius
	var elements_in_radius = []
	for element in elements:
		if element == self:
			continue
		var distance_sqr = position.distance_squared_to(element.global_position)
		if distance_sqr < sqr_radius:
			elements_in_radius.append(element)
	return elements_in_radius

func cohere(other_boids) -> Vector2:
	var center = get_center(other_boids)
	return (center - position) * COHESION_BASE_FACTOR

func separate(other_boids : Array, separation_distance: float) -> Vector2:
	var target = Vector2()
	for boid in other_boids:
		# Steering force is higher when you are closer to something
		var dist = maxf(position.distance_to(boid.global_position), .0001)
		if dist < separation_distance:
			target += (position - boid.global_position) / dist
	return target * SEPARATION_BASE_FACTOR
	

func avoid_walls() -> Vector2:
	var target_velocity = Vector2()
	var eps = .00001
	var dist_from_left = maxf(position.x - SCENE_LEFT, eps)
	var dist_from_right = maxf(SCENE_RIGHT - position.x, eps)
	var dist_from_top = maxf(position.y - SCENE_TOP, eps)
	var dist_from_bottom = maxf(SCENE_BOTTOM - position.y , eps)
	if dist_from_left < WALL_AVOID_DISTANCE:
		# Steer towards the middle
		target_velocity += Vector2.RIGHT / dist_from_left
	elif dist_from_right < WALL_AVOID_DISTANCE:
		target_velocity += Vector2.LEFT / dist_from_right
	
	if dist_from_top < WALL_AVOID_DISTANCE:
		# Steer towards the middle
		target_velocity += Vector2.DOWN / dist_from_top
	elif dist_from_bottom < WALL_AVOID_DISTANCE:
		target_velocity += Vector2.UP / dist_from_bottom
	
	return target_velocity * SEPARATION_BASE_FACTOR
		
		
	

func align(other_boids: Array) -> Vector2:
	var avg_velocity = get_avg_velocity(other_boids)
	return (avg_velocity - last_velocity) * ALIGNMENT_BASE_FACTOR


func get_center(boids) -> Vector2:
	if boids.size() == 0:
		return position
	var center = Vector2()
	for boid in boids:
		center += boid.global_position
	center /= boids.size()
	return center

func get_avg_velocity(boids) -> Vector2:
	if boids.size() == 0:
		return last_velocity
	var avg_velocity = Vector2()
	for boid in boids:
		avg_velocity += boid.last_velocity
	avg_velocity /= boids.size()
	return avg_velocity
	
# Utility function to clamp vector by length
func clamp_vector(vec : Vector2, min_length: float, max_length : float) -> Vector2:
	var vec_length = vec.length()
	if vec_length == 0:
		return Vector2(min_length, 0)
	if vec_length > max_length:
		return vec * max_length/vec_length
	if vec_length < min_length:
		return vec * min_length/vec_length
	return vec

# func clear_position_history():
	# position_history.clear()
