extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.032)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(560, 620)
	box.offset_left = -280
	box.offset_right = 280
	box.offset_top = -310
	box.offset_bottom = 310
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var t := Label.new()
	t.text = "Game Modes"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	box.add_child(t)
	box.add_child(_m("501 vs AI", "Double-out. Three darts a turn.", DartTypes.Mode.FIVE_OH_ONE, true, false))
	box.add_child(_m("301 vs AI", "Shorter race. Same checkout law.", DartTypes.Mode.THREE_OH_ONE, true, false))
	box.add_child(_m("CRICKET vs AI", "Close 20–15 and bull. Score the open ones.", DartTypes.Mode.CRICKET, true, false))
	box.add_child(_m("AROUND THE CLOCK", "1 through 20, then bull.", DartTypes.Mode.AROUND_CLOCK, true, false))
	box.add_child(_m("501 LOCAL", "Two players, one machine.", DartTypes.Mode.FIVE_OH_ONE, false, true))
	box.add_child(_m("PRACTICE", "Throw forever. Read the wires.", DartTypes.Mode.PRACTICE, false, false))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	box.add_child(back)


func _m(title: String, blurb: String, mode: DartTypes.Mode, ai: bool, local: bool) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" % [title, blurb]
	b.custom_minimum_size.y = 68
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		GameSession.reset_defaults()
		GameSession.mode = mode
		GameSession.vs_ai = ai
		GameSession.local_multi = local
		get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	)
	return b
