class_name SoundManager
extends Node

var enabled: bool = true

var _sfx_place: AudioStreamWAV
var _sfx_flip: AudioStreamWAV
var _sfx_pass: AudioStreamWAV
var _sfx_invalid: AudioStreamWAV
var _sfx_win: AudioStreamWAV
var _sfx_lose: AudioStreamWAV
var _sfx_click: AudioStreamWAV

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS: int = 8

func _ready() -> void:
	_generate_all_sounds()
	for i in range(MAX_PLAYERS):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func play_sound(stream: AudioStreamWAV, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not enabled or stream == null:
		return
	var player := _get_free_player()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()

func play_place() -> void:
	# Subtle random pitch variation for tactile organic feel
	var pitch: float = randf_range(0.95, 1.05)
	play_sound(_sfx_place, pitch, 0.0)

func play_flip(index_offset: int = 0) -> void:
	# Slightly increasing pitch per cascaded flip
	var pitch: float = 1.0 + float(index_offset) * 0.06 + randf_range(-0.02, 0.02)
	play_sound(_sfx_flip, pitch, -2.0)

func play_pass() -> void:
	play_sound(_sfx_pass, 1.0, 0.0)

func play_invalid() -> void:
	play_sound(_sfx_invalid, 1.0, -2.0)

func play_win() -> void:
	play_sound(_sfx_win, 1.0, 0.0)

func play_lose() -> void:
	play_sound(_sfx_lose, 1.0, 0.0)

func play_click() -> void:
	play_sound(_sfx_click, 1.0, -4.0)

# --- Procedural Audio Synthesizer ---

func _generate_all_sounds() -> void:
	_sfx_place = _synthesize_place()
	_sfx_flip = _synthesize_flip()
	_sfx_pass = _synthesize_pass()
	_sfx_invalid = _synthesize_invalid()
	_sfx_win = _synthesize_win()
	_sfx_lose = _synthesize_lose()
	_sfx_click = _synthesize_click()

func _create_wav(sample_rate: int, data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _synthesize_place() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.12
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 35.0)
		# Crisp snap (800Hz decaying quickly) + resonance body (320Hz) + tiny noise
		var freq1: float = 800.0 * exp(-t * 40.0) + 300.0
		var tone: float = sin(2.0 * PI * freq1 * t) * 0.7
		var body: float = sin(2.0 * PI * 220.0 * t) * 0.3
		var noise: float = (randf() * 2.0 - 1.0) * exp(-t * 80.0) * 0.4
		var sample_val: float = (tone + body + noise) * env * 0.8
		var ival: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)

func _synthesize_flip() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.10
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 45.0)
		var freq: float = 520.0 * exp(-t * 20.0)
		var tone: float = sin(2.0 * PI * freq * t) * 0.6
		var noise: float = (randf() * 2.0 - 1.0) * exp(-t * 50.0) * 0.3
		var sample_val: float = (tone + noise) * env * 0.7
		var ival: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)

func _synthesize_pass() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.35
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t: float = float(i) / rate
		var env1: float = maxf(0.0, 1.0 - t / 0.2) * exp(-t * 8.0)
		var env2: float = 0.0
		if t >= 0.12:
			var t2: float = t - 0.12
			env2 = maxf(0.0, 1.0 - t2 / 0.22) * exp(-t2 * 8.0)
		
		var tone1: float = sin(2.0 * PI * 440.0 * t) * env1 * 0.5
		var tone2: float = sin(2.0 * PI * 330.0 * t) * env2 * 0.5
		var sample_val: float = (tone1 + tone2) * 0.8
		var ival: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)

func _synthesize_invalid() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.16
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 25.0)
		var tone: float = (1.0 if sin(2.0 * PI * 130.0 * t) > 0.0 else -1.0) * 0.4 # Square buzz
		var sample_val: float = tone * env * 0.6
		var ival: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)

func _synthesize_win() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.65
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	var freqs := [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var starts := [0.0, 0.12, 0.24, 0.36]
	
	for i in range(samples):
		var t: float = float(i) / rate
		var val: float = 0.0
		for k in range(freqs.size()):
			var st: float = starts[k]
			if t >= st:
				var dt: float = t - st
				var env: float = exp(-dt * 6.0)
				val += sin(2.0 * PI * freqs[k] * dt) * env * 0.25
		var ival: int = clampi(int(val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)

func _synthesize_lose() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.55
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	var freqs := [440.0, 415.3, 392.0, 349.23] # A4, G#4, G4, F4
	var starts := [0.0, 0.12, 0.24, 0.36]
	
	for i in range(samples):
		var t: float = float(i) / rate
		var val: float = 0.0
		for k in range(freqs.size()):
			var st: float = starts[k]
			if t >= st:
				var dt: float = t - st
				var env: float = exp(-dt * 7.0)
				val += sin(2.0 * PI * freqs[k] * dt) * env * 0.25
		var ival: int = clampi(int(val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)

func _synthesize_click() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.04
	var samples: int = int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 80.0)
		var tone: float = sin(2.0 * PI * 1200.0 * t) * 0.5
		var noise: float = (randf() * 2.0 - 1.0) * 0.3
		var val: float = (tone + noise) * env * 0.5
		var ival: int = clampi(int(val * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, ival)
	
	return _create_wav(rate, data)
