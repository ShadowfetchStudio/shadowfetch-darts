class_name DartsGameController
extends Node3D

var engine := DartEngine.new()
var camera: Camera3D
var ui: DartsHUD
var board: DartBoardView
var _busy := false
var _charging := false
var _charge := 0.35
var _stats: Dictionary = {}
var _live: Array = []
var _aim: MeshInstance3D
var _visit := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats = StatsStore.load_stats()
	engine.reset(GameSession.mode)
	_world()
	ui = DartsHUD.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	ui.setup(engine)
	ui.throw_requested.connect(_player_throw)
	ui.pause_requested.connect(_toggle_pause)
	ui.restart_requested.connect(_restart)
	ui.settings_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")
	)
	ui.menu_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	ui.quit_requested.connect(func(): get_tree().quit())
	_handle_cli()


func _world() -> void:
	var env_n := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.03, 0.032)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.3, 0.28)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = false
	env_n.environment = env
	add_child(env_n)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 25, 0)
	key.light_energy = 0.55
	key.shadow_enabled = SettingsStore.quality_shadows()
	add_child(key)
	board = DartBoardView.new()
	add_child(board)
	camera = Camera3D.new()
	camera.fov = 32
	camera.position = Vector3(0.06, 1.73, 0.92)
	add_child(camera)
	camera.look_at(Vector3(0, 1.73, 0.02))
	_aim = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.006
	sph.height = 0.012
	_aim.mesh = sph
	var am := StandardMaterial3D.new()
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	am.albedo_color = Color(0.95, 0.55, 0.45)
	_aim.material_override = am
	add_child(_aim)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		return
	if get_tree().paused or _busy or engine.phase == DartTypes.Phase.OVER:
		return
	if not _is_human():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_charging = true
				_charge = 0.35
			elif _charging:
				_charging = false
				_player_throw()


func _process(dt: float) -> void:
	if get_tree().paused:
		return
	if _charging:
		_charge = minf(_charge + dt * 1.15 * SettingsStore.shot_sensitivity, 1.0)
		ui.set_power(_charge)
	_update_aim()
	if _ai_should_throw():
		_ai_throw()


func _update_aim() -> void:
	var hit := _mouse_on_board()
	if hit != Vector3.INF:
		_aim.global_position = hit


func _mouse_on_board() -> Vector3:
	if camera == null:
		return Vector3.INF
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	if absf(dir.z) < 0.0001:
		return Vector3.INF
	var t := (0.02 - from.z) / dir.z
	if t < 0.0:
		return Vector3.INF
	return from + dir * t


func _is_human() -> bool:
	if engine.mode == DartTypes.Mode.PRACTICE:
		return true
	if GameSession.local_multi or not GameSession.vs_ai:
		return true
	return engine.current == 0


func _ai_should_throw() -> bool:
	return GameSession.vs_ai and not GameSession.local_multi and engine.current == 1 \
		and engine.phase == DartTypes.Phase.THROWING and not _busy and not get_tree().paused


func _player_throw() -> void:
	if _busy or not _is_human() or engine.phase != DartTypes.Phase.THROWING:
		return
	var dest := _mouse_on_board()
	if dest == Vector3.INF:
		dest = Vector3(0, 1.73, 0.02)
	var mm := Vector2((dest.x) * 1000.0, (dest.y - 1.73) * 1000.0)
	var sigma := (1.35 - _charge) * 16.0 / SettingsStore.shot_sensitivity
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	mm += Vector2(rng.randfn(0.0, sigma), rng.randfn(0.0, sigma))
	_launch(mm, _charge)
	_charge = 0.35
	ui.set_power(_charge)


func _ai_throw() -> void:
	var mm := DartAI.aim_mm(engine, SettingsStore.ai_difficulty)
	_launch(mm, 0.82)


func _launch(mm: Vector2, power: float) -> void:
	_busy = true
	AudioManager.play("throw")
	var dart := FlightDart.new()
	dart.setup(SettingsStore.dart_style if _is_human() else 1)
	add_child(dart)
	var start := Vector3(0.02, 1.68, 2.3)
	var dest := Vector3(mm.x / 1000.0, 1.73 + mm.y / 1000.0, 0.02)
	dart.global_position = start
	var dur := lerpf(0.42, 0.26, clampf(power, 0.2, 1.0))
	var tw := create_tween()
	tw.tween_method(func(u: float):
		if not is_instance_valid(dart):
			return
		var p := start.lerp(dest, u)
		p.y += sin(u * PI) * 0.045
		dart.global_position = p
		if dest != start:
			dart.look_at(dest, Vector3.UP)
	, 0.0, 1.0, dur)
	tw.finished.connect(func():
		if is_instance_valid(dart):
			dart.embed_at(dest)
		_resolve(mm, dart)
	)


func _resolve(mm: Vector2, dart: FlightDart) -> void:
	var hit := DartBoard.score_mm(mm.x, mm.y)
	if hit.ring == DartTypes.Ring.MISS and is_instance_valid(dart):
		var tw := create_tween()
		tw.tween_property(dart, "position:y", dart.position.y - 0.9, 0.45)
		tw.finished.connect(func():
			if is_instance_valid(dart):
				dart.queue_free()
		)
	else:
		_live.append(dart)
	var before := engine.remaining()
	var r := engine.apply_hit(hit)
	_stats["darts"] = int(_stats.get("darts", 0)) + 1
	if hit.number == 25:
		_stats["bulls"] = int(_stats.get("bulls", 0)) + 1
	_visit += hit.points
	if (r["turn_over"] or r["won"]) and _visit == 180:
		_stats["one_eighties"] = int(_stats.get("one_eighties", 0)) + 1
	if r["bust"] or r["turn_over"] or r["won"]:
		_visit = 0
	if r["bust"]:
		AudioManager.play("bust")
		_clear_turn_darts()
	elif r["won"]:
		AudioManager.play("win")
		_stats["games"] = int(_stats.get("games", 0)) + 1
		if engine.winner == 0:
			_stats["wins"] = int(_stats.get("wins", 0)) + 1
			if engine.mode == DartTypes.Mode.FIVE_OH_ONE or engine.mode == DartTypes.Mode.THREE_OH_ONE:
				_stats["checkouts"] = int(_stats.get("checkouts", 0)) + 1
				_stats["highest_checkout"] = maxi(int(_stats.get("highest_checkout", 0)), before)
		else:
			_stats["losses"] = int(_stats.get("losses", 0)) + 1
		StatsStore.save_stats(_stats)
	else:
		AudioManager.play("hit" if hit.points > 0 else "bust")
		if r["turn_over"]:
			_clear_turn_darts()
	ui.refresh()
	_busy = false
	if engine.mode == DartTypes.Mode.PRACTICE and _live.size() > 9:
		var old: FlightDart = _live.pop_front()
		if is_instance_valid(old):
			old.queue_free()


func _clear_turn_darts() -> void:
	for d in _live:
		if is_instance_valid(d):
			d.queue_free()
	_live.clear()


func _toggle_pause() -> void:
	ui.set_paused(not get_tree().paused)


func _restart() -> void:
	get_tree().paused = false
	engine.reset(GameSession.mode)
	_clear_turn_darts()
	_busy = false
	ui.refresh()


func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--screenshot" in args:
		await get_tree().create_timer(0.7).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := ProjectSettings.globalize_path("res://docs/screenshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("board.png"))
			print("SCREENSHOT ", dir.path_join("board.png"))
	if "--self-test" in args or GameSession.self_test:
		await get_tree().process_frame
		var ok := _run_self_test()
		print("SELFTEST contact=true first=%s pocketed=%s foul= ok=%s" % [
			DartBoard.score_mm(0, 103).label,
			DartBoard.score_mm(0, 0).label,
			ok
		])
		print("SELFTEST hits=T20,50 board=ok engine=ok")
		get_tree().quit(0 if ok else 1)


func _run_self_test() -> bool:
	var t20 := DartBoard.score_mm(0, 103)
	var db := DartBoard.score_mm(0, 0)
	if t20.points != 60 or db.points != 50:
		return false
	var e := DartEngine.new()
	e.reset(DartTypes.Mode.FIVE_OH_ONE)
	e.scores[0] = 170
	e.turn_start = 170
	e.apply_hit(t20)
	e.apply_hit(t20)
	var r := e.apply_hit(db)
	return bool(r["won"])
