extends Node


@export var return_button : Button
@export var next_level_button : Button

func _ready() -> void:
    return_button.pressed.connect(func () -> void:
        StartController.Instance.leave_to_home()
    )
    
    if LevelInstanceProps.level_number >= LevelSelector.num_levels:
        next_level_button.disabled = true
    else:
        next_level_button.pressed.connect(func () -> void:
            StartController.Instance.scene_is_changing = true
            StartController.Instance.set_deferred("scene_is_changing", false)
            LevelSelector.start_level_from_number(LevelInstanceProps.level_number + 1, get_tree())
        )

