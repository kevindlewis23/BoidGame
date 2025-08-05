extends Node


@export var return_button : Button
@export var next_level_button : Button

func _ready() -> void:
    return_button.pressed.connect(func () -> void:
        get_tree().change_scene_to_file(LevelInstanceProps.scene_to_return_to)
    )
    
    if LevelInstanceProps.level_number >= LevelSelector.num_levels:
        next_level_button.disabled = true
    else:
        next_level_button.pressed.connect(func () -> void:
            LevelSelector.start_level_from_number(LevelInstanceProps.level_number + 1, get_tree())
        )

