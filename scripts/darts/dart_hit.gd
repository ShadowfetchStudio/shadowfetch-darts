class_name DartHit
extends RefCounted

const Types = preload("res://scripts/darts/dart_types.gd")

var x_mm: float = 0.0
var y_mm: float = 0.0
var radius_mm: float = 0.0
var angle_deg: float = 0.0
var number: int = 0
var ring: Types.Ring = Types.Ring.MISS
var points: int = 0
var multiplier: int = 0
var label: String = "Miss"


func can_checkout() -> bool:
	return ring == Types.Ring.DOUBLE or ring == Types.Ring.DOUBLE_BULL


func cricket_target() -> int:
	if number == 25:
		return 25
	if number in Types.CRICKET_TARGETS:
		return number
	return 0


func cricket_marks() -> int:
	if ring == Types.Ring.MISS:
		return 0
	if number == 25:
		return 2 if ring == Types.Ring.DOUBLE_BULL else 1
	return multiplier


func duplicate_hit():
	var h = get_script().new()
	h.x_mm = x_mm
	h.y_mm = y_mm
	h.radius_mm = radius_mm
	h.angle_deg = angle_deg
	h.number = number
	h.ring = ring
	h.points = points
	h.multiplier = multiplier
	h.label = label
	return h
