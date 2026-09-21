class_name DartEngine
extends RefCounted

const Types = preload("res://scripts/darts/dart_types.gd")
const Hit = preload("res://scripts/darts/dart_hit.gd")
const Book = preload("res://scripts/darts/checkout_book.gd")

var mode: Types.Mode = Types.Mode.FIVE_OH_ONE
var phase: Types.Phase = Types.Phase.THROWING
var current: int = 0
var scores: Array[int] = [501, 501]
var turn_start: int = 501
var darts_used: int = 0
var clock_number: Array[int] = [1, 1]
var cricket_marks: Array = []
var cricket_points: Array[int] = [0, 0]
var winner: int = -1
var last_message: String = ""
var last_bust: bool = false
var turn_hits: Array = []
var history: Array = []


func reset(p_mode: Types.Mode) -> void:
	mode = p_mode
	phase = Types.Phase.THROWING
	current = 0
	var start := Types.start_score(mode)
	scores = [start, start]
	turn_start = start
	darts_used = 0
	clock_number = [1, 1]
	cricket_points = [0, 0]
	cricket_marks = [_empty_marks(), _empty_marks()]
	winner = -1
	last_message = "Throw."
	last_bust = false
	turn_hits.clear()
	history.clear()


func apply_hit(hit: Hit) -> Dictionary:
	last_bust = false
	if phase == Types.Phase.OVER:
		return _pack(false, false)
	turn_hits.append(hit.duplicate_hit())
	history.append({"player": current, "label": hit.label, "points": hit.points})
	match mode:
		Types.Mode.PRACTICE:
			last_message = hit.label
			darts_used += 1
			return _pack(false, false)
		Types.Mode.AROUND_CLOCK:
			return _clock(hit)
		Types.Mode.CRICKET:
			return _cricket(hit)
		_:
			return _x01(hit)


func remaining(player: int = -1) -> int:
	var p := current if player < 0 else player
	return scores[p]


func darts_left() -> int:
	return 3 - darts_used


func checkout_hint() -> PackedStringArray:
	if mode != Types.Mode.FIVE_OH_ONE and mode != Types.Mode.THREE_OH_ONE:
		return PackedStringArray()
	return Book.suggest(scores[current], darts_left())


func cricket_closed(player: int, target: int) -> bool:
	return int(cricket_marks[player][target]) >= 3


func all_cricket_closed(player: int) -> bool:
	for t in Types.CRICKET_TARGETS:
		if not cricket_closed(player, t):
			return false
	return true


func _x01(hit: Hit) -> Dictionary:
	var next := scores[current] - hit.points
	if next < 0 or next == 1 or (next == 0 and not hit.can_checkout()):
		last_bust = true
		scores[current] = turn_start
		last_message = "Bust — %s" % hit.label
		_end_turn()
		return _pack(true, false)
	scores[current] = next
	last_message = hit.label
	if next == 0:
		winner = current
		phase = Types.Phase.OVER
		last_message = "Checkout %s" % hit.label
		return _pack(false, true)
	darts_used += 1
	if darts_used >= 3:
		_end_turn()
		return _pack(false, false)
	return _pack(false, false)


func _clock(hit: Hit) -> Dictionary:
	var need: int = clock_number[current]
	var ok := false
	if need <= 20:
		ok = hit.number == need
	else:
		ok = hit.number == 25
	if ok:
		clock_number[current] = need + 1
		last_message = "Hit %s" % hit.label
		if clock_number[current] > 21:
			winner = current
			phase = Types.Phase.OVER
			last_message = "Clock complete"
			return _pack(false, true)
	else:
		last_message = "Need %s  ·  %s" % [_clock_label(need), hit.label]
	darts_used += 1
	if darts_used >= 3:
		_end_turn()
	return _pack(false, false)


func _cricket(hit: Hit) -> Dictionary:
	var target := hit.cricket_target()
	var marks := hit.cricket_marks()
	if target == 0 or marks <= 0:
		last_message = hit.label
	else:
		_apply_cricket_marks(current, target, marks)
		last_message = hit.label
	if all_cricket_closed(current) and cricket_points[current] >= cricket_points[1 - current]:
		winner = current
		phase = Types.Phase.OVER
		last_message = "Cricket closed"
		return _pack(false, true)
	darts_used += 1
	if darts_used >= 3:
		_end_turn()
	return _pack(false, false)


func _apply_cricket_marks(player: int, target: int, marks: int) -> void:
	var opp := 1 - player
	var left := marks
	while left > 0:
		var have: int = int(cricket_marks[player][target])
		if have < 3:
			cricket_marks[player][target] = have + 1
		elif int(cricket_marks[opp][target]) < 3:
			cricket_points[player] += target
		left -= 1


func _end_turn() -> void:
	darts_used = 0
	turn_hits.clear()
	current = 1 - current
	turn_start = scores[current]
	if phase != Types.Phase.OVER:
		phase = Types.Phase.THROWING


func _empty_marks() -> Dictionary:
	var d := {}
	for t in Types.CRICKET_TARGETS:
		d[t] = 0
	return d


func _clock_label(n: int) -> String:
	if n <= 20:
		return str(n)
	return "Bull"


func _pack(bust: bool, won: bool) -> Dictionary:
	return {
		"bust": bust,
		"won": won,
		"turn_over": darts_used == 0 and phase != Types.Phase.OVER,
		"message": last_message,
		"player": current,
	}
