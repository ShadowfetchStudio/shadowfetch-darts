extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.032)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 40
	panel.offset_bottom = -40
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Label.new()
	t.text = "How to Play"
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(s)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = """THROW
Aim with the mouse. Hold the left button to charge, release to throw. Strength and a little timing variance decide where the dart lands. The dart embeds in the sisal. Scoring is read from that coordinate — never from a later bounce.

BOARD
European / WDF geometry. 20 is at the top. Double bull is 50, outer bull is 25. Triples sit in the inner ring, doubles on the outer. Outside the double wire is a miss.

501 AND 301
Subtract each dart. Finish exactly on a double or the double bull. Going below zero, leaving 1, or hitting zero without a double is a bust — the turn score is wiped and it is the other side.

CRICKET
Close 20, 19, 18, 17, 16, 15, and bull (three marks). Extra marks score that number while the opponent is still open. Win by closing everything and leading or tying on points.

AROUND THE CLOCK
Hit 1 through 20 in order, then the bull. Doubles and triples of the needed number count.

PRACTICE
No match ending. Learn the wires.

CHECKOUT ASSIST
Optional. Suggests a legal double-out when one exists. It does not throw for you.

AI
Aims at legal targets with the same scorer. Difficulty only changes aim noise.
"""
	s.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	v.add_child(back)
