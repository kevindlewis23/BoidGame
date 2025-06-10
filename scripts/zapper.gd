extends Node

@export var electiricy : Area2D
@export var collision_shape : CollisionShape2D

@export var on_time : float = 1
@export var off_time : float = 1
@export var phase_shift : float = 0

var period
var current_phase = 0
var running = false

func _ready():
	period = on_time + off_time
	start()

func start():
	current_phase = phase_shift
	running = true

func _physics_process(delta: float) -> void:
	if running:
		current_phase = fmod(current_phase + delta, period)
		if current_phase < on_time:
			electiricy.show.call_deferred()
			collision_shape.set_deferred("disabled", false)
		else:
			electiricy.hide.call_deferred()
			collision_shape.set_deferred("disabled", true)
