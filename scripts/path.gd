extends Node2D
class_name Path

var points : Array = []

func _ready() -> void:
	# Set z index to -1
	z_index = -2

func _process(_delta: float) -> void:
	# Update the path every frame
	queue_redraw()

func _draw() -> void:
	if points.size() >= 2:
		draw_polyline(points, Color(1, 1, 1, 0.5), 10, true)
