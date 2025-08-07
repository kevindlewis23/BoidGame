extends Node

var scene_to_return_to : String = "res://level_select.tscn"

var level_file_path: String = Constants.level_creator_tmp_file_path

# 0 refers to no level (or at least not one of actual game levels)
var level_number: int = 0


# func _ready() -> void:
# 	# Create a music player
# 	var audio_stream = AudioStreamWAV.load_from_file("res://assets/theme.wav")
	
# 	audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
# 	audio_stream.loop_end = audio_stream.get_length() * audio_stream.mix_rate  # Set the loop end to the end of the audio stream
	
# 	var music_player = AudioStreamPlayer.new()
# 	music_player.stream = audio_stream
# 	add_child(music_player)
# 	# Loop the music
# 	music_player.play()
