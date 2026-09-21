extends Node

const Types = preload("res://scripts/darts/dart_types.gd")

var mode: Types.Mode = Types.Mode.FIVE_OH_ONE
var vs_ai: bool = true
var local_multi: bool = false
var self_test: bool = false


func reset_defaults() -> void:
	mode = Types.Mode.FIVE_OH_ONE
	vs_ai = true
	local_multi = false
	self_test = false


func mode_name() -> String:
	return Types.mode_name(mode)
