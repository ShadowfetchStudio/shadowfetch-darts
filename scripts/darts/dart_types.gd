class_name DartTypes
extends RefCounted

enum Mode { FIVE_OH_ONE, THREE_OH_ONE, CRICKET, AROUND_CLOCK, PRACTICE }
enum Ring { MISS, SINGLE, DOUBLE, TRIPLE, BULL, DOUBLE_BULL }
enum Phase { THROWING, TURN_OVER, OVER }

const SECTORS: Array[int] = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
const CRICKET_TARGETS: Array[int] = [20, 19, 18, 17, 16, 15, 25]

const DOUBLE_BULL_R := 6.35
const SINGLE_BULL_R := 15.9
const TRIPLE_INNER := 99.0
const TRIPLE_OUTER := 107.0
const DOUBLE_INNER := 162.0
const DOUBLE_OUTER := 170.0


static func mode_name(mode: Mode) -> String:
	match mode:
		Mode.THREE_OH_ONE:
			return "301"
		Mode.CRICKET:
			return "Cricket"
		Mode.AROUND_CLOCK:
			return "Around the Clock"
		Mode.PRACTICE:
			return "Practice"
		_:
			return "501"


static func start_score(mode: Mode) -> int:
	match mode:
		Mode.THREE_OH_ONE:
			return 301
		Mode.FIVE_OH_ONE:
			return 501
		_:
			return 0


static func ring_name(ring: Ring) -> String:
	match ring:
		Ring.DOUBLE:
			return "Double"
		Ring.TRIPLE:
			return "Triple"
		Ring.BULL:
			return "Bull"
		Ring.DOUBLE_BULL:
			return "Double bull"
		Ring.MISS:
			return "Miss"
		_:
			return "Single"
