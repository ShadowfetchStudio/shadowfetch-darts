class_name DartBoard
extends RefCounted

const Types = preload("res://scripts/darts/dart_types.gd")
const Hit = preload("res://scripts/darts/dart_hit.gd")

## Deterministic WDF-sized scoring. Origin is the bull. +Y is 12 o'clock (20).
## +X is 3 o'clock (6). Angle increases clockwise. Exact clockwise sector
## rays belong to the next sector. Exact ring radii belong to the outer region
## of that threshold (r < next bound).


static func score_mm(x_mm: float, y_mm: float) -> Hit:
	var hit := Hit.new()
	hit.x_mm = x_mm
	hit.y_mm = y_mm
	hit.radius_mm = sqrt(x_mm * x_mm + y_mm * y_mm)
	hit.angle_deg = rad_to_deg(atan2(x_mm, y_mm))
	if not is_finite(hit.radius_mm) or not is_finite(hit.angle_deg):
		hit.label = "Miss"
		return hit
	var r := hit.radius_mm
	if r >= Types.DOUBLE_OUTER:
		hit.ring = Types.Ring.MISS
		hit.label = "Miss"
		return hit
	if r < Types.DOUBLE_BULL_R:
		hit.number = 25
		hit.ring = Types.Ring.DOUBLE_BULL
		hit.multiplier = 2
		hit.points = 50
		hit.label = "50"
		return hit
	if r < Types.SINGLE_BULL_R:
		hit.number = 25
		hit.ring = Types.Ring.BULL
		hit.multiplier = 1
		hit.points = 25
		hit.label = "25"
		return hit
	hit.number = Types.SECTORS[_sector_index(hit.angle_deg)]
	if r < Types.TRIPLE_INNER:
		hit.ring = Types.Ring.SINGLE
		hit.multiplier = 1
	elif r < Types.TRIPLE_OUTER:
		hit.ring = Types.Ring.TRIPLE
		hit.multiplier = 3
	elif r < Types.DOUBLE_INNER:
		hit.ring = Types.Ring.SINGLE
		hit.multiplier = 1
	else:
		hit.ring = Types.Ring.DOUBLE
		hit.multiplier = 2
	hit.points = hit.number * hit.multiplier
	hit.label = _label(hit)
	return hit


static func score_m(x_m: float, y_m: float) -> Hit:
	return score_mm(x_m * 1000.0, y_m * 1000.0)


static func _sector_index(angle_deg: float) -> int:
	var shifted := fposmod(angle_deg + 9.0, 360.0)
	var idx := int(floor((shifted + 1.0e-7) / 18.0)) % 20
	if idx < 0:
		idx += 20
	return idx


static func sector_index(number: int) -> int:
	for i in Types.SECTORS.size():
		if int(Types.SECTORS[i]) == number:
			return i
	return -1


static func sector_center_mm(number: int, ring: Types.Ring) -> Vector2:
	if number == 25:
		return Vector2.ZERO
	var idx := sector_index(number)
	if idx < 0:
		return Vector2.ZERO
	var ang := deg_to_rad(float(idx) * 18.0)
	var rad := 80.0
	match ring:
		Types.Ring.TRIPLE:
			rad = 103.0
		Types.Ring.DOUBLE:
			rad = 166.0
		_:
			rad = 80.0
	return Vector2(sin(ang) * rad, cos(ang) * rad)


static func _label(hit: Hit) -> String:
	match hit.ring:
		Types.Ring.TRIPLE:
			return "T%d" % hit.number
		Types.Ring.DOUBLE:
			return "D%d" % hit.number
		_:
			return "S%d" % hit.number
