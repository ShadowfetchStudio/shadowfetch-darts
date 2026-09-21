class_name FlightDart
extends Node3D

var style: int = 0


func setup(p_style: int) -> void:
	style = p_style
	var barrel_c := Color(0.22, 0.2, 0.2)
	var shaft_c := Color(0.75, 0.55, 0.45)
	match style:
		1:
			barrel_c = Color(0.72, 0.52, 0.22)
			shaft_c = Color(0.9, 0.78, 0.4)
		2:
			barrel_c = Color(0.62, 0.16, 0.18)
			shaft_c = Color(0.85, 0.7, 0.68)
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.0024
	cone.height = 0.028
	tip.mesh = cone
	tip.rotation_degrees = Vector3(90, 0, 0)
	tip.position = Vector3(0, 0, 0.014)
	tip.material_override = _mat(Color(0.85, 0.85, 0.88), 0.25, 0.9)
	add_child(tip)
	var barrel := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0042
	cyl.bottom_radius = 0.0036
	cyl.height = 0.038
	barrel.mesh = cyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0, -0.018)
	barrel.material_override = _mat(barrel_c, 0.35, 0.7)
	add_child(barrel)
	var shaft := MeshInstance3D.new()
	var sh := CylinderMesh.new()
	sh.top_radius = 0.0018
	sh.bottom_radius = 0.0018
	sh.height = 0.045
	shaft.mesh = sh
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.position = Vector3(0, 0, -0.058)
	shaft.material_override = _mat(shaft_c, 0.4, 0.3)
	add_child(shaft)
	for i in 3:
		var flight := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.018, 0.001, 0.022)
		flight.mesh = box
		flight.position = Vector3(0, 0, -0.086)
		flight.rotation_degrees = Vector3(0, 0, float(i) * 120.0)
		flight.material_override = _mat(barrel_c.lightened(0.15), 0.55, 0.05)
		add_child(flight)


func embed_at(world: Vector3) -> void:
	global_position = world
	look_at(world + Vector3(0, 0, -0.2), Vector3.UP)


func _mat(albedo: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	return m
