class_name DartBoardView
extends Node3D

const Types = preload("res://scripts/darts/dart_types.gd")
const FACE_Z := 0.012


func _ready() -> void:
	_room()
	_board()
	_numbers()
	_oche()


func _room() -> void:
	var wall := MeshInstance3D.new()
	var wb := BoxMesh.new()
	wb.size = Vector3(3.2, 3.0, 0.08)
	wall.mesh = wb
	wall.position = Vector3(0, 1.35, -0.06)
	wall.material_override = _mat(Color(0.08, 0.055, 0.058), 0.7, 0.18)
	add_child(wall)
	var floor := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(4.0, 0.06, 4.2)
	floor.mesh = fb
	floor.position = Vector3(0, -0.03, 1.6)
	floor.material_override = _mat(Color(0.07, 0.05, 0.045), 0.35, 0.55)
	add_child(floor)
	var rail := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(2.4, 0.04, 0.08)
	rail.mesh = rb
	rail.position = Vector3(0, 0.02, 2.37)
	rail.material_override = _mat(Color(0.72, 0.42, 0.32), 0.2, 0.85)
	add_child(rail)
	var lamp := SpotLight3D.new()
	lamp.light_energy = 1.15
	lamp.spot_range = 5.0
	lamp.spot_angle = 36.0
	lamp.shadow_enabled = true
	add_child(lamp)
	lamp.position = Vector3(0.12, 2.15, 0.85)
	lamp.look_at(Vector3(0, 1.73, 0.02), Vector3.UP)
	var fill := OmniLight3D.new()
	fill.light_energy = 0.22
	fill.omni_range = 2.8
	fill.light_color = Color(1.0, 0.82, 0.76)
	add_child(fill)
	fill.position = Vector3(0.0, 1.73, 0.55)


func _board() -> void:
	var back := MeshInstance3D.new()
	var back_m := CylinderMesh.new()
	back_m.top_radius = 0.226
	back_m.bottom_radius = 0.226
	back_m.height = 0.018
	back_m.radial_segments = 48
	back.mesh = back_m
	back.rotation_degrees = Vector3(90, 0, 0)
	back.position = Vector3(0, 1.73, -0.02)
	back.material_override = _mat(Color(0.1, 0.06, 0.055), 0.85, 0.12)
	add_child(back)
	var surround := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.168
	ring.outer_radius = 0.226
	ring.ring_segments = 48
	ring.rings = 16
	surround.mesh = ring
	surround.rotation_degrees = Vector3(90, 0, 0)
	surround.position = Vector3(0, 1.73, 0.004)
	surround.material_override = _mat(Color(0.16, 0.08, 0.07), 0.75, 0.18)
	add_child(surround)
	var face := Node3D.new()
	face.position = Vector3(0, 1.73, FACE_Z)
	add_child(face)
	for i in 20:
		var a0 := deg_to_rad(float(i) * 18.0 - 9.0)
		var a1 := deg_to_rad(float(i) * 18.0 + 9.0)
		var cream := i % 2 == 0
		var single_c := Color(0.7, 0.6, 0.46) if cream else Color(0.08, 0.07, 0.075)
		var multi_c := Color(0.7, 0.12, 0.14) if cream else Color(0.08, 0.38, 0.26)
		face.add_child(_wedge(0.0159, 0.099, a0, a1, single_c, 0.002))
		face.add_child(_wedge(0.099, 0.107, a0, a1, multi_c, 0.003))
		face.add_child(_wedge(0.107, 0.162, a0, a1, single_c, 0.002))
		face.add_child(_wedge(0.162, 0.170, a0, a1, multi_c, 0.0035))
	face.add_child(_disc(0.0159, Color(0.12, 0.38, 0.28), 0.004))
	face.add_child(_disc(0.00635, Color(0.72, 0.16, 0.18), 0.005))
	var wire := MeshInstance3D.new()
	var wire_m := TorusMesh.new()
	wire_m.inner_radius = 0.168
	wire_m.outer_radius = 0.172
	wire.mesh = wire_m
	wire.rotation_degrees = Vector3(90, 0, 0)
	wire.material_override = _mat(Color(0.85, 0.78, 0.62), 0.15, 0.9)
	face.add_child(wire)


func _numbers() -> void:
	for i in 20:
		var n: int = Types.SECTORS[i]
		var ang := deg_to_rad(float(i) * 18.0)
		var lab := Label3D.new()
		lab.text = str(n)
		lab.font_size = 42
		lab.pixel_size = 0.00115
		lab.modulate = Color(0.95, 0.82, 0.74)
		lab.position = Vector3(sin(ang) * 0.248, 1.73 + cos(ang) * 0.248, FACE_Z + 0.014)
		lab.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		add_child(lab)


func _oche() -> void:
	var mark := Label3D.new()
	mark.text = "OCHE  2.37 m"
	mark.font_size = 18
	mark.pixel_size = 0.002
	mark.modulate = Color(0.7, 0.45, 0.4)
	mark.position = Vector3(0.55, 0.08, 2.37)
	mark.rotation_degrees = Vector3(-90, 0, 0)
	add_child(mark)


func _wedge(r0: float, r1: float, a0: float, a1: float, color: Color, z: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 10
	for s in steps:
		var t0 := float(s) / float(steps)
		var t1 := float(s + 1) / float(steps)
		var a := lerpf(a0, a1, t0)
		var b := lerpf(a0, a1, t1)
		var p0 := Vector3(sin(a) * r0, cos(a) * r0, z)
		var p1 := Vector3(sin(b) * r0, cos(b) * r0, z)
		var p2 := Vector3(sin(b) * r1, cos(b) * r1, z)
		var p3 := Vector3(sin(a) * r1, cos(a) * r1, z)
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(p0)
		st.add_vertex(p2)
		st.add_vertex(p1)
		st.add_vertex(p0)
		st.add_vertex(p3)
		st.add_vertex(p2)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat(color, 0.55, 0.25)
	return mi


func _disc(radius: float, color: Color, z: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 24
	for s in steps:
		var a := TAU * float(s) / float(steps)
		var b := TAU * float(s + 1) / float(steps)
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(0, 0, z))
		st.add_vertex(Vector3(sin(b) * radius, cos(b) * radius, z))
		st.add_vertex(Vector3(sin(a) * radius, cos(a) * radius, z))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat(color, 0.5, 0.3)
	return mi


func _mat(albedo: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = maxf(roughness, 0.45)
	m.metallic = minf(metallic, 0.35)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = false
	return m
