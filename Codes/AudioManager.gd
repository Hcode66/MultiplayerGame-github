extends AudioStreamPlayer


enum SOUND_IDS{
	RUN = 0,
	JUMP = 1,
	SLASH1 = 2,
	SLASH2 = 3,
	DAMAGE,
	DASH,
	JUMP_AREA,
}

const sounds = {
	SOUND_IDS.RUN: preload("res://Audio/run.mp3"),
	SOUND_IDS.JUMP: preload("res://Audio/jump.mp3"),
	SOUND_IDS.SLASH1: preload("res://Audio/slash1.mp3"),
	SOUND_IDS.SLASH2: preload("res://Audio/slash2.mp3"),
	SOUND_IDS.DAMAGE: preload("res://Audio/damage.mp3"),
	SOUND_IDS.DASH: preload("res://Audio/dash.mp3"),
	SOUND_IDS.JUMP_AREA: preload("res://Audio/jumpArea.mp3"),
	
}

func get_audio(s_id) -> AudioStream:
	return sounds[s_id]

func create_sound(s_id: SOUND_IDS, pitch_range: Vector2 = Vector2.ZERO) -> AudioStreamPlayer2D:
	var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audio_player.stream = get_audio(s_id)
	if pitch_range != Vector2.ZERO:
		audio_player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	return audio_player


@rpc("any_peer", "call_local")
func play_sound(s_id: SOUND_IDS, pos: Vector2i, vol: float = 1., pitch_range: Vector2 = Vector2.ZERO):
	var audio_player: AudioStreamPlayer2D = create_sound(s_id,pitch_range)
	gonet.get_world().add_child(audio_player)
	audio_player.volume_linear = vol
	audio_player.play()
	audio_player.global_position = pos
	await audio_player.finished
	audio_player.queue_free()
