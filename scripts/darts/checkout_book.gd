class_name CheckoutBook
extends RefCounted

## Exhaustive double-out search. Last dart must be a double or 50.


static func all_throws() -> Array:
	var out: Array = []
	for n in range(1, 21):
		out.append({"l": "S%d" % n, "p": n, "fin": false})
		out.append({"l": "D%d" % n, "p": n * 2, "fin": true})
		out.append({"l": "T%d" % n, "p": n * 3, "fin": false})
	out.append({"l": "25", "p": 25, "fin": false})
	out.append({"l": "50", "p": 50, "fin": true})
	return out


static var _cache: Dictionary = {}


static func suggest(score: int, darts_left: int = 3) -> PackedStringArray:
	if score <= 1 or darts_left <= 0 or score > 180:
		return PackedStringArray()
	var key := "%d:%d" % [score, darts_left]
	if _cache.has(key):
		return _cache[key]
	var path := _search(score, darts_left)
	var labels := PackedStringArray()
	for step in path:
		labels.append(str(step))
	_cache[key] = labels
	return labels


static func is_possible(score: int, darts_left: int = 3) -> bool:
	if score <= 0:
		return score == 0
	return not suggest(score, darts_left).is_empty()


static func _search(score: int, left: int) -> Array:
	if score == 0:
		return []
	if left <= 0 or score < 0 or score == 1:
		return []
	if score > 60 * left:
		return []
	var throws: Array = all_throws()
	if left == 1:
		for t in throws:
			if bool(t["fin"]) and int(t["p"]) == score:
				return [str(t["l"])]
		return []
	var preferred: Array = throws.duplicate()
	preferred.sort_custom(func(a, b): return int(a["p"]) > int(b["p"]))
	for t in preferred:
		var p: int = int(t["p"])
		if p > score:
			continue
		var nxt: int = score - p
		if nxt == 1:
			continue
		if nxt == 0:
			if bool(t["fin"]):
				return [str(t["l"])]
			continue
		var rest := _search(nxt, left - 1)
		if not rest.is_empty():
			var out: Array = [str(t["l"])]
			out.append_array(rest)
			return out
	return []
