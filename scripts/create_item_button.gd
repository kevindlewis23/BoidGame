extends Button

@export var object_to_create : PackedScene
@export var where_to_create : Node

func _ready():
	pressed.connect(create_sprite)

func create_sprite():
	var new_object = object_to_create.instantiate()
	new_object.position = get_parent().get_parent().create_position
	where_to_create.add_child(new_object)
	new_object.ready.connect(LevelCreator.instance.state_changed.emit)
