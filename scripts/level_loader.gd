extends Node2D


@export var moving_objects_parent : Node2D
@export var where_to_place_stars : Node2D

const ObjectType = LevelCreatorThing.ObjectType

const OBJECT_SCENES = {
	ObjectType.BOID: preload("res://movable_assets/movable_boid.tscn"),
	ObjectType.REPELLER: preload("res://movable_assets/movable_repeller.tscn"),
	ObjectType.STAR: preload("res://game_objects/star.tscn")
}

const player_boid_scene = preload("res://game_objects/player_boid.tscn") as PackedScene
const predator_boid_scene = preload("res://game_objects/evil_boid.tscn") as PackedScene
const predator_player_boid_scene = preload("res://game_objects/evil_player_boid.tscn") as PackedScene

func _ready() -> void:
	var level_file_path = LevelInstanceProps.level_file_path

	if FileAccess.file_exists(level_file_path):
		var file = FileAccess.open(level_file_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_data)
			if error == OK:
				load_level_from_array(json.data)
			else:
				push_error("Failed to parse level: %s" % json.get_error_message())
		else:
			push_error("Failed to open level file: %s" % level_file_path)
	else:
		push_error("Failed to open level file: %s" % level_file_path)

func load_level_from_array(level_data: Array) -> void:
	for item in level_data:
		var obj_type = int(item["object_type"])
		if obj_type == ObjectType.STAR:
			var star = OBJECT_SCENES[ObjectType.STAR].instantiate()
			star.global_position = Vector2(item["object"]["x"], item["object"]["y"])
			where_to_place_stars.add_child(star)
		else:
			var movable_object = OBJECT_SCENES[obj_type].instantiate() as MovableThing
			# Set the bounding box
			var bb_left = item["bounding_box"]["left"]
			var bb_right = item["bounding_box"]["right"]
			var bb_top = item["bounding_box"]["top"]
			var bb_bottom = item["bounding_box"]["bottom"]

			movable_object.bounding_box.position = Vector2()
			movable_object.bounding_box.polygon = PackedVector2Array([
				Vector2(bb_left, bb_top),
				Vector2(bb_right, bb_top),
				Vector2(bb_right, bb_bottom),
				Vector2(bb_left, bb_bottom)
			])

			

			# Set location and rotation.  Make sure position gets set even if it seems impossible
			var huge_box = Rect2(-Constants.WIDTH, -Constants.HEIGHT, 2 * Constants.WIDTH, 2 * Constants.HEIGHT)
			movable_object.moving_object_bounding_box.move_to(Vector2(item["object"]["x"], item["object"]["y"]), huge_box)
			movable_object.moving_object_bounding_box.rotate_to(
				-item["object"]["rotation"] * PI / 180.0, huge_box)


			movable_object.can_move = item["object"].get("can_move", false)
			movable_object.can_rotate = item["object"].get("can_rotate", false)
			if obj_type == ObjectType.BOID:
				var can_collect_stars = item["object"].get("can_collect_stars", false)
				var is_predator = item["object"].get("is_predator", false)
				var color = Color.WHITE
				if can_collect_stars:
					if is_predator:
						movable_object.object_to_replace_with = predator_player_boid_scene
						color = Constants.predator_player_boid_color
					else:
						movable_object.object_to_replace_with = player_boid_scene
						color = Constants.player_boid_color
				else:
					if is_predator:
						movable_object.object_to_replace_with = predator_boid_scene
						color = Constants.predator_boid_color
				# Set the color, this will probably be temporary until the sprites are different
				movable_object.moving_object_bounding_box.get_child(0).get_child(0).get_child(0).color = color

			moving_objects_parent.add_child(movable_object)
			
