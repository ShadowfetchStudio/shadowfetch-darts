extends Node

var _players: Dictionary = {}


func _ready() -> void:
	for key in ["ui", "throw", "hit", "bust", "mark", "win", "lose"]:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players[key] = p
	_players["ui"].stream = _tone(780, 0.04, 0.14)
	_players["throw"].stream = _tone(240, 0.08, 0.18)
	_players["hit"].stream = _tone(190, 0.09, 0.26)
	_players["bust"].stream = _tone(110, 0.22, 0.2)
	_players["mark"].stream = _tone(440, 0.08, 0.18)
	_players["win"].stream = _chord([523, 659, 784], 0.5)
	_players["lose"].stream = _tone(140, 0.32, 0.2)
	var music := AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = _pad()
	add_child(music)
	var amb := AudioStreamPlayer.new()
	amb.bus = "Ambient"
	amb.stream = _room()
	add_child(amb)
	SettingsStore.settings_changed.connect(func(): SettingsStore.apply_audio())
	SettingsStore.apply_audio()
	if SettingsStore.music_volume > 0.02:
		music.play()
	if SettingsStore.ambient_volume > 0.02:
		amb.play()


func play(kind: String) -> void:
	if SettingsStore.sfx_volume <= 0.001:
		return
	if _players.has(kind):
		_players[kind].play()


func _tone(freq: float, seconds: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-t * 8.0) * (1.0 - t / seconds)
		var s := clampi(int(sin(t * TAU * freq) * 32767.0 * vol * env), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _chord(freqs: Array, seconds: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.0
		for f in freqs:
			sample += sin(t * TAU * float(f))
		sample /= float(freqs.size())
		var env := exp(-t * 3.2)
		var s := clampi(int(sample * 20000.0 * env), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _pad() -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 8
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.07 * sin(t * TAU * 49.0) + 0.04 * sin(t * TAU * 73.5)
		var s := clampi(int(sample * 32767.0), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


func _room() -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 6
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.03 * sin(t * TAU * 62.0) + 0.015 * sin(t * TAU * 93.0)
		var s := clampi(int(sample * 32767.0), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	return s
