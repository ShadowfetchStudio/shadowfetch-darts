extends RefCounted

const Board = preload("res://scripts/darts/dart_board.gd")
const Rules = preload("res://scripts/darts/dart_engine.gd")
const Types = preload("res://scripts/darts/dart_types.gd")
const Book = preload("res://scripts/darts/checkout_book.gd")

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	_known_points()
	_sector_centers()
	_border_rings()
	_border_sectors()
	_bull_borders()
	_miss_and_nan()
	_x01_rules()
	_checkouts()
	_cricket()
	_clock()
	_practice()
	_random_coordinates(120000)
	print("Darts checks: %d  failures: %d" % [_checks, _failures.size()])
	for m in _failures:
		print("FAIL: ", m)
	return _failures.is_empty()


func _known_points() -> void:
	_eq_hit(0, 0, 50, 25, Types.Ring.DOUBLE_BULL)
	_eq_hit(0, 10, 25, 25, Types.Ring.BULL)
	_eq_hit(0, 50, 20, 20, Types.Ring.SINGLE)
	_eq_hit(0, 103, 60, 20, Types.Ring.TRIPLE)
	_eq_hit(0, 166, 40, 20, Types.Ring.DOUBLE)
	_eq_hit(0, 171, 0, 0, Types.Ring.MISS)
	_eq_hit(50, 0, 6, 6, Types.Ring.SINGLE)
	_eq_hit(103, 0, 18, 6, Types.Ring.TRIPLE)
	_eq_hit(166, 0, 12, 6, Types.Ring.DOUBLE)
	_eq_hit(-50, 0, 11, 11, Types.Ring.SINGLE)
	_eq_hit(0, -50, 3, 3, Types.Ring.SINGLE)
	_eq_hit(0, -103, 9, 3, Types.Ring.TRIPLE)
	_eq_hit(0, -166, 6, 3, Types.Ring.DOUBLE)


func _sector_centers() -> void:
	for n in Types.SECTORS:
		var s: Vector2 = Board.sector_center_mm(n, Types.Ring.SINGLE)
		var t: Vector2 = Board.sector_center_mm(n, Types.Ring.TRIPLE)
		var d: Vector2 = Board.sector_center_mm(n, Types.Ring.DOUBLE)
		_eq_hit(s.x, s.y, n, n, Types.Ring.SINGLE)
		_eq_hit(t.x, t.y, n * 3, n, Types.Ring.TRIPLE)
		_eq_hit(d.x, d.y, n * 2, n, Types.Ring.DOUBLE)


func _border_rings() -> void:
	for n in Types.SECTORS:
		var c: Vector2 = Board.sector_center_mm(n, Types.Ring.SINGLE)
		var dir := c.normalized()
		if dir.length() < 0.1:
			continue
		_ring_at(dir, 6.34, 50)
		_ring_at(dir, 6.36, 25)
		_ring_at(dir, 15.88, 25)
		_ring_at(dir, 15.92, n)
		_ring_at(dir, 98.9, n)
		_ring_at(dir, 99.1, n * 3)
		_ring_at(dir, 106.9, n * 3)
		_ring_at(dir, 107.1, n)
		_ring_at(dir, 161.9, n)
		_ring_at(dir, 162.1, n * 2)
		_ring_at(dir, 169.9, n * 2)
		_ring_at(dir, 170.1, 0)


func _border_sectors() -> void:
	for i in 20:
		var boundary := float(i) * 18.0 + 9.0
		var nxt: int = Types.SECTORS[(i + 1) % 20]
		var cur: int = Types.SECTORS[i]
		var just_before := deg_to_rad(boundary - 0.05)
		var just_after := deg_to_rad(boundary + 0.05)
		var exact := deg_to_rad(boundary)
		var r := 80.0
		_eq_hit(sin(just_before) * r, cos(just_before) * r, cur, cur, Types.Ring.SINGLE)
		_eq_hit(sin(just_after) * r, cos(just_after) * r, nxt, nxt, Types.Ring.SINGLE)
		_eq_hit(sin(exact) * r, cos(exact) * r, nxt, nxt, Types.Ring.SINGLE)
		for rad in [103.0, 166.0]:
			var hb := Board.score_mm(sin(just_before) * rad, cos(just_before) * rad)
			var ha := Board.score_mm(sin(just_after) * rad, cos(just_after) * rad)
			_ok(hb.number == cur, "pre-boundary %s r=%.0f" % [cur, rad])
			_ok(ha.number == nxt, "post-boundary %s r=%.0f" % [nxt, rad])


func _bull_borders() -> void:
	for ang in range(0, 360, 15):
		var a := deg_to_rad(float(ang))
		var db := Board.score_mm(sin(a) * 6.0, cos(a) * 6.0)
		var sb := Board.score_mm(sin(a) * 12.0, cos(a) * 12.0)
		_ok(db.points == 50, "inner bull %d" % ang)
		_ok(sb.points == 25, "outer bull %d" % ang)


func _miss_and_nan() -> void:
	_eq_hit(400, 0, 0, 0, Types.Ring.MISS)
	_eq_hit(0, 400, 0, 0, Types.Ring.MISS)
	var nan_hit := Board.score_mm(INF, NAN)
	_ok(nan_hit.points == 0, "non-finite miss")


func _x01_rules() -> void:
	var e := Rules.new()
	e.reset(Types.Mode.FIVE_OH_ONE)
	_ok(e.scores[0] == 501, "501 start")
	e.apply_hit(Board.score_mm(0, 103))
	e.apply_hit(Board.score_mm(0, 103))
	e.apply_hit(Board.score_mm(0, 103))
	_ok(e.scores[0] == 321, "three T20 from 501")
	_ok(e.current == 1, "turn passed")
	e.reset(Types.Mode.THREE_OH_ONE)
	_ok(e.scores[0] == 301, "301 start")
	var d16: Vector2 = Board.sector_center_mm(16, Types.Ring.DOUBLE)
	e.scores[0] = 32
	e.turn_start = 32
	var r := e.apply_hit(Board.score_mm(d16.x, d16.y))
	_ok(r["won"] == true and e.winner == 0, "D16 checkout 32")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 32
	e.turn_start = 32
	r = e.apply_hit(Board.score_mm(0, 50))
	_ok(r["bust"] == false and e.scores[0] == 12, "single 20 from 32 leaves 12")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 20
	e.turn_start = 20
	r = e.apply_hit(Board.score_mm(0, 50))
	_ok(r["bust"] == true, "leave 0 without double is bust")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 21
	e.turn_start = 21
	r = e.apply_hit(Board.score_mm(0, 50))
	_ok(r["bust"] == true and e.scores[0] == 21, "leave 1 is bust")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 40
	e.turn_start = 40
	e.apply_hit(Board.score_mm(400, 0))
	e.apply_hit(Board.score_mm(400, 0))
	e.apply_hit(Board.score_mm(400, 0))
	_ok(e.scores[0] == 40 and e.current == 1, "three misses keep score")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 50
	e.turn_start = 50
	r = e.apply_hit(Board.score_mm(0, 0))
	_ok(r["won"] == true, "50 finishes")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 25
	e.turn_start = 25
	r = e.apply_hit(Board.score_mm(0, 10))
	_ok(r["bust"] == true, "25 cannot checkout")
	e.reset(Types.Mode.FIVE_OH_ONE)
	e.scores[0] = 170
	e.turn_start = 170
	e.apply_hit(Board.score_mm(0, 103))
	e.apply_hit(Board.score_mm(0, 103))
	r = e.apply_hit(Board.score_mm(0, 0))
	_ok(r["won"] == true, "170 T20 T20 50")


func _checkouts() -> void:
	_ok(Book.suggest(32, 1) == PackedStringArray(["D16"]), "32 one dart")
	_ok(Book.suggest(2, 1) == PackedStringArray(["D1"]), "2 one dart")
	_ok(Book.suggest(50, 1) == PackedStringArray(["50"]), "50 one dart")
	_ok(Book.suggest(3, 1).is_empty(), "3 no one-dart")
	_ok(not Book.suggest(3, 2).is_empty(), "3 two-dart")
	_ok(not Book.suggest(170, 3).is_empty(), "170 three-dart")
	_ok(Book.suggest(169, 3).is_empty(), "169 impossible")
	_ok(Book.suggest(1, 3).is_empty(), "1 impossible")
	for s in range(2, 171):
		var path := Book.suggest(s, 3)
		if path.is_empty():
			_ok(s in [169, 168, 166, 165, 163, 162, 159], "impossible %d listed" % s)
			continue
		var total := 0
		for lab in path:
			total += _label_points(str(lab))
		_ok(total == s, "checkout %d sums %d via %s" % [s, total, ",".join(path)])
		_ok(_is_finish(str(path[path.size() - 1])), "checkout %d ends double" % s)


func _cricket() -> void:
	var e := Rules.new()
	e.reset(Types.Mode.CRICKET)
	e.apply_hit(Board.score_mm(0, 103))
	_ok(int(e.cricket_marks[0][20]) == 3, "T20 closes 20")
	_ok(e.cricket_points[0] == 0, "close does not score")
	e.apply_hit(Board.score_mm(0, 103))
	_ok(e.cricket_points[0] == 60, "T20 after close scores 20+20+20")
	e.reset(Types.Mode.CRICKET)
	for t in [20, 19, 18, 17, 16, 15]:
		e.cricket_marks[0][t] = 3
		e.cricket_marks[1][t] = 3
	e.cricket_marks[0][25] = 3
	e.cricket_marks[1][25] = 2
	e.cricket_points = [0, 0]
	var r := e.apply_hit(Board.score_mm(0, 10))
	_ok(r["won"] == true, "close last bull while leading")
	e.reset(Types.Mode.CRICKET)
	e.cricket_marks[0][20] = 3
	e.cricket_marks[1][20] = 3
	e.apply_hit(Board.score_mm(0, 50))
	_ok(e.cricket_points[0] == 0, "both closed 20 scores nothing")


func _clock() -> void:
	var e := Rules.new()
	e.reset(Types.Mode.AROUND_CLOCK)
	e.apply_hit(Board.score_mm(0, 50))
	_ok(e.clock_number[0] == 1, "20 does not count as 1")
	var one := Board.sector_center_mm(1, Types.Ring.SINGLE)
	e.apply_hit(Board.score_mm(one.x, one.y))
	_ok(e.clock_number[0] == 2, "hit 1 advances")
	var two := Board.sector_center_mm(2, Types.Ring.DOUBLE)
	e.apply_hit(Board.score_mm(two.x, two.y))
	_ok(e.clock_number[0] == 3, "double 2 counts")
	e.reset(Types.Mode.AROUND_CLOCK)
	e.clock_number[0] = 21
	e.darts_used = 0
	e.current = 0
	var r := e.apply_hit(Board.score_mm(0, 0))
	_ok(r["won"] == true, "bull finishes clock")


func _practice() -> void:
	var e := Rules.new()
	e.reset(Types.Mode.PRACTICE)
	e.apply_hit(Board.score_mm(0, 103))
	e.apply_hit(Board.score_mm(0, 103))
	e.apply_hit(Board.score_mm(0, 103))
	e.apply_hit(Board.score_mm(0, 103))
	_ok(e.phase != Types.Phase.OVER and e.current == 0, "practice never ends")


func _random_coordinates(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260920
	var seen := 0
	for i in n:
		var x := rng.randf_range(-190.0, 190.0)
		var y := rng.randf_range(-190.0, 190.0)
		var a := Board.score_mm(x, y)
		var b := Board.score_mm(x, y)
		_ok(a.points == b.points and a.number == b.number and a.ring == b.ring, "deterministic %d" % i)
		_ok(a.points == a.number * a.multiplier or a.number == 25, "points identity %d" % i)
		if a.number == 25:
			_ok(a.points == 25 or a.points == 50, "bull points %d" % i)
		if a.radius_mm >= Types.DOUBLE_OUTER:
			_ok(a.points == 0, "outside miss %d" % i)
		if a.radius_mm < Types.DOUBLE_BULL_R:
			_ok(a.points == 50, "center 50 %d" % i)
		if a.ring == Types.Ring.TRIPLE:
			_ok(a.points == a.number * 3, "triple %d" % i)
		if a.ring == Types.Ring.DOUBLE and a.number != 25:
			_ok(a.points == a.number * 2, "double %d" % i)
		seen += 1
	_ok(seen == n, "resolved %d coordinates" % n)


func _ring_at(dir: Vector2, radius: float, points: int) -> void:
	var h := Board.score_mm(dir.x * radius, dir.y * radius)
	_ok(h.points == points, "r=%.3f expect %d got %d" % [radius, points, h.points])


func _eq_hit(x: float, y: float, points: int, number: int, ring: Types.Ring) -> void:
	var h := Board.score_mm(x, y)
	_ok(h.points == points and h.number == number and h.ring == ring,
		"(%s,%s) expect %d/%d/%s got %d/%d/%s" % [x, y, points, number, ring, h.points, h.number, h.ring])


func _label_points(lab: String) -> int:
	if lab == "50":
		return 50
	if lab == "25":
		return 25
	if lab.begins_with("T"):
		return int(lab.substr(1)) * 3
	if lab.begins_with("D"):
		return int(lab.substr(1)) * 2
	if lab.begins_with("S"):
		return int(lab.substr(1))
	return 0


func _is_finish(lab: String) -> bool:
	return lab == "50" or lab.begins_with("D")


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
