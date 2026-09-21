class_name DartsHUD
extends CanvasLayer

signal throw_requested
signal pause_requested
signal restart_requested
signal settings_requested
signal menu_requested
signal quit_requested

var engine: DartEngine
var _status: Label
var _score: Label
var _hint: Label
var _power: ProgressBar
var _pause: PanelContainer
var _aim: Control


func setup(p_engine: DartEngine) -> void:
	engine = p_engine
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ThemeFactory.make()
	add_child(root)
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 14
	top.offset_bottom = 56
	root.add_child(top)
	_score = Label.new()
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_score)
	var pause_btn := Button.new()
	pause_btn.text = "PAUSE"
	pause_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_btn.pressed.connect(func(): pause_requested.emit())
	top.add_child(pause_btn)
	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 20
	_status.offset_right = -20
	_status.offset_top = 56
	_status.offset_bottom = 92
	root.add_child(_status)
	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_left = 20
	_hint.offset_right = -20
	_hint.offset_top = 92
	_hint.offset_bottom = 122
	_hint.add_theme_color_override("font_color", ThemeFactory.accent())
	root.add_child(_hint)
	_power = ProgressBar.new()
	_power.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_power.offset_left = 24
	_power.offset_right = -24
	_power.offset_top = -36
	_power.offset_bottom = -16
	_power.min_value = 0
	_power.max_value = 1
	_power.show_percentage = false
	_power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_power)
	var throw_btn := Button.new()
	throw_btn.text = "THROW"
	throw_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	throw_btn.offset_left = -170
	throw_btn.offset_top = -86
	throw_btn.offset_right = -24
	throw_btn.offset_bottom = -42
	throw_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	throw_btn.pressed.connect(func(): throw_requested.emit())
	root.add_child(throw_btn)
	_aim = Control.new()
	_aim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_aim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_aim)
	_pause = PanelContainer.new()
	_pause.visible = false
	_pause.set_anchors_preset(Control.PRESET_CENTER)
	_pause.custom_minimum_size = Vector2(340, 340)
	_pause.offset_left = -170
	_pause.offset_right = 170
	_pause.offset_top = -170
	_pause.offset_bottom = 170
	_pause.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(_pause)
	var pv := VBoxContainer.new()
	_pause.add_child(pv)
	var t := Label.new()
	t.text = "Paused"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(t)
	pv.add_child(_p("RESUME", func(): set_paused(false)))
	pv.add_child(_p("RESTART", func(): restart_requested.emit()))
	pv.add_child(_p("SETTINGS", func(): settings_requested.emit()))
	pv.add_child(_p("MAIN MENU", func(): menu_requested.emit()))
	pv.add_child(_p("QUIT", func(): quit_requested.emit()))
	refresh()


func _p(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func set_paused(v: bool) -> void:
	_pause.visible = v
	get_tree().paused = v


func set_status(t: String) -> void:
	if _status:
		_status.text = t


func set_power(p: float) -> void:
	if _power:
		_power.value = clampf(p, 0.0, 1.0)


func refresh() -> void:
	if engine == null:
		return
	var who := "You" if engine.current == 0 else "Opponent"
	if GameSession.local_multi:
		who = "Player %d" % (engine.current + 1)
	if engine.mode == DartTypes.Mode.CRICKET:
		_score.text = "%s   ·   %s   ·   You %d  Opp %d" % [
			GameSession.mode_name(), who, engine.cricket_points[0], engine.cricket_points[1]
		]
	elif engine.mode == DartTypes.Mode.AROUND_CLOCK:
		_score.text = "%s   ·   %s   ·   Need %s" % [
			GameSession.mode_name(), who, _clock(engine.clock_number[engine.current])
		]
	elif engine.mode == DartTypes.Mode.PRACTICE:
		_score.text = "Practice   ·   last %s" % engine.last_message
	else:
		_score.text = "%s   ·   %s   ·   You %d   Opp %d   ·   Darts %d" % [
			GameSession.mode_name(), who, engine.scores[0], engine.scores[1], engine.darts_left()
		]
	if engine.phase == DartTypes.Phase.OVER:
		var who_won := "You" if engine.winner == 0 else "Opponent"
		_status.text = "Game over — %s" % who_won
	else:
		_status.text = engine.last_message
	if SettingsStore.checkout_assist:
		var hint := engine.checkout_hint()
		_hint.text = "Checkout  %s" % "  ·  ".join(hint) if hint.size() > 0 else ""
	else:
		_hint.text = ""


func _clock(n: int) -> String:
	if n <= 20:
		return str(n)
	return "Bull"
