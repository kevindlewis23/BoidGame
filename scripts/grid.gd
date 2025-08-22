extends Control

@export var grid_size: int = 30
@export var line_color : Color = Color(1, 1, 1, .03)
@export var every_nth_line_color : Color = Color(1,1,1,.1)
@export var every_nth_line_n : int = 4


func _draw() -> void:
	for i in range(1, ceil(Constants.WIDTH * 1.0 / grid_size)):
		var color = line_color
		if every_nth_line_n > 0 and i % every_nth_line_n == 0:
			color = every_nth_line_color
		draw_line(Vector2(i * grid_size, 0), Vector2(i * grid_size, Constants.HEIGHT), color)
		draw_line(Vector2(0, i * grid_size), Vector2(Constants.WIDTH, i * grid_size), color)
