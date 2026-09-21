class_name DartAI
extends RefCounted


static func aim_mm(engine: DartEngine, difficulty: String) -> Vector2:
	var target := _target(engine)
	var sigma := 28.0
	match difficulty:
		"easy":
			sigma = 42.0
		"hard":
			sigma = 11.0
		_:
			sigma = 22.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return target + Vector2(rng.randfn(0.0, sigma), rng.randfn(0.0, sigma))


static func _target(engine: DartEngine) -> Vector2:
	match engine.mode:
		DartTypes.Mode.CRICKET:
			return _cricket_target(engine)
		DartTypes.Mode.AROUND_CLOCK:
			var n: int = engine.clock_number[engine.current]
			if n >= 21:
				return Vector2.ZERO
			return DartBoard.sector_center_mm(n, DartTypes.Ring.SINGLE)
		DartTypes.Mode.PRACTICE:
			return DartBoard.sector_center_mm(20, DartTypes.Ring.TRIPLE)
		_:
			return _x01_target(engine)


static func _x01_target(engine: DartEngine) -> Vector2:
	var left := engine.remaining()
	if left <= 40 and left % 2 == 0:
		return DartBoard.sector_center_mm(left / 2, DartTypes.Ring.DOUBLE)
	if left == 50:
		return Vector2.ZERO
	var hint := engine.checkout_hint()
	if hint.size() > 0:
		return _label_aim(str(hint[0]))
	return DartBoard.sector_center_mm(20, DartTypes.Ring.TRIPLE)


static func _cricket_target(engine: DartEngine) -> Vector2:
	for t in DartTypes.CRICKET_TARGETS:
		if not engine.cricket_closed(engine.current, t):
			if t == 25:
				return Vector2.ZERO
			return DartBoard.sector_center_mm(t, DartTypes.Ring.TRIPLE)
	return DartBoard.sector_center_mm(20, DartTypes.Ring.TRIPLE)


static func _label_aim(lab: String) -> Vector2:
	if lab == "50" or lab == "25":
		return Vector2.ZERO
	var n := int(lab.substr(1))
	if lab.begins_with("T"):
		return DartBoard.sector_center_mm(n, DartTypes.Ring.TRIPLE)
	if lab.begins_with("D"):
		return DartBoard.sector_center_mm(n, DartTypes.Ring.DOUBLE)
	return DartBoard.sector_center_mm(n, DartTypes.Ring.SINGLE)
