class_name ForestBuilder
extends Node3D

const TREE_SCENE := preload("res://scenes/forest_tree.tscn")
const TREE_SPORE_FADE_SCRIPT := preload("res://scripts/world/tree_spore_fade.gd")

@export var forest_radius: float = 30.0
@export var tree_count: int = 95
@export var ground_size: float = 72.0

var _rng := RandomNumberGenerator.new()
var _height_noise := FastNoiseLite.new()


func build() -> void:
	_rng.randomize()
	_setup_height_noise()
	_build_ground()
	_scatter_trees()
	_build_fallen_logs()
	_build_rocks()
	_build_understory()
	_build_ferns()
	_build_atmosphere_particles()
	_setup_tree_spore_fade()


func _setup_tree_spore_fade() -> void:
	if get_node_or_null("TreeSporeFade"):
		return
	var fader := Node.new()
	fader.name = "TreeSporeFade"
	fader.set_script(TREE_SPORE_FADE_SCRIPT)
	add_child(fader)


func _setup_height_noise() -> void:
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = 0.035
	_height_noise.fractal_octaves = 5
	_height_noise.fractal_lacunarity = 2.1


func get_terrain_height(x: float, z: float) -> float:
	return _terrain_height(x, z)


func clear_vegetation_near_points(points: Array[Vector3], radius: float) -> void:
	for group_name in ["Understory", "Ferns"]:
		var group := get_node_or_null(group_name) as Node3D
		if group == null:
			continue
		for child in group.get_children():
			if not child is Node3D:
				continue
			var node := child as Node3D
			var node_pos := Vector2(node.global_position.x, node.global_position.z)
			for point in points:
				var patch_pos := Vector2(point.x, point.z)
				if node_pos.distance_to(patch_pos) < radius:
					node.queue_free()
					break


func _terrain_height(x: float, z: float) -> float:
	return _height_noise.get_noise_2d(x, z) * 1.4


func _make_noise_texture(freq: float, octaves: int) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = freq
	noise.fractal_octaves = octaves
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.width = 1024
	tex.height = 1024
	return tex


func _make_ground_material() -> StandardMaterial3D:
	var color_noise := _make_noise_texture(0.05, 4)
	var detail_noise := _make_noise_texture(0.18, 3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.26, 0.11)
	mat.albedo_texture = color_noise
	mat.uv1_scale = Vector3(8, 8, 8)
	mat.roughness = 0.97
	mat.roughness_texture = detail_noise
	mat.normal_enabled = true
	mat.normal_texture = detail_noise
	mat.normal_scale = 0.35
	return mat


func _make_bark_material() -> StandardMaterial3D:
	var bark_noise := _make_noise_texture(0.12, 4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.26, 0.18, 0.12)
	mat.albedo_texture = bark_noise
	mat.uv1_scale = Vector3(2.5, 2.5, 2.5)
	mat.roughness = 0.94
	mat.roughness_texture = bark_noise
	return mat


func _make_moss_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.38, 0.14)
	mat.roughness = 1.0
	mat.emission_enabled = true
	mat.emission = Color(0.04, 0.1, 0.03)
	return mat


func _make_rock_material() -> StandardMaterial3D:
	var rock_noise := _make_noise_texture(0.08, 3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.3, 0.28)
	mat.albedo_texture = rock_noise
	mat.roughness = 0.88
	return mat


func _build_ground() -> void:
	var subdiv := 64
	var plane := PlaneMesh.new()
	plane.size = Vector2(ground_size, ground_size)
	plane.subdivide_width = subdiv
	plane.subdivide_depth = subdiv

	var arrays := plane.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var v := vertices[i]
		v.y = _terrain_height(v.x, v.z)
		vertices[i] = v
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var surface_tool := SurfaceTool.new()
	surface_tool.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.generate_normals(true)
	var mesh := surface_tool.commit()

	var ground := MeshInstance3D.new()
	ground.name = "ForestFloor"
	ground.mesh = mesh
	ground.material_override = _make_ground_material()
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(ground)

	var body := StaticBody3D.new()
	ground.add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ground_size, 0.5, ground_size)
	col.shape = shape
	col.position = Vector3(0, -0.25, 0)
	body.add_child(col)


func _scatter_trees() -> void:
	var trees_root := Node3D.new()
	trees_root.name = "Trees"
	add_child(trees_root)

	var placed := 0
	var attempts := 0
	while placed < tree_count and attempts < tree_count * 6:
		attempts += 1
		var angle := _rng.randf_range(0, TAU)
		var dist := _rng.randf_range(6.0, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _terrain_height(pos.x, pos.z)
		if pos.length() < 5.0:
			continue
		var tree: Node3D = TREE_SCENE.instantiate()
		tree.position = pos
		tree.rotation.y = _rng.randf_range(0, TAU)
		var tree_scale: float = _rng.randf_range(0.75, 1.55)
		tree.scale = Vector3.ONE * tree_scale
		_apply_tree_materials(tree)
		trees_root.add_child(tree)
		placed += 1


func _build_fallen_logs() -> void:
	var logs := Node3D.new()
	logs.name = "FallenLogs"
	add_child(logs)

	for i in 16:
		var angle := _rng.randf_range(0, TAU)
		var dist := _rng.randf_range(4.0, forest_radius - 2.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _terrain_height(pos.x, pos.z) + 0.12
		var rot := Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0, TAU), _rng.randf_range(-0.1, 0.1))
		logs.add_child(_make_log(pos, rot, _rng.randf_range(1.8, 4.2)))


func _make_log(pos: Vector3, rot: Vector3, length: float) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation = rot

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.24
	cyl.height = length
	cyl.radial_segments = 14
	mesh_inst.mesh = cyl
	mesh_inst.rotation.z = PI * 0.5
	mesh_inst.material_override = _make_bark_material()
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mesh_inst)

	if _rng.randf() > 0.35:
		var moss := MeshInstance3D.new()
		var moss_mesh := BoxMesh.new()
		moss_mesh.size = Vector3(length * 0.5, 0.05, 0.4)
		moss.mesh = moss_mesh
		moss.position = Vector3(0, 0.16, 0)
		moss.material_override = _make_moss_material()
		root.add_child(moss)

	return root


func _build_rocks() -> void:
	var rocks := Node3D.new()
	rocks.name = "Rocks"
	add_child(rocks)

	for i in 22:
		var angle := _rng.randf_range(0, TAU)
		var dist := _rng.randf_range(3.0, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _terrain_height(pos.x, pos.z) + 0.08
		var rock := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = _rng.randf_range(0.2, 0.65)
		sph.radial_segments = 10
		sph.rings = 8
		rock.mesh = sph
		rock.position = pos
		rock.scale = Vector3(
			_rng.randf_range(0.8, 1.4),
			_rng.randf_range(0.5, 0.9),
			_rng.randf_range(0.8, 1.3)
		)
		rock.material_override = _make_rock_material()
		rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		rocks.add_child(rock)


func _build_understory() -> void:
	var understory := Node3D.new()
	understory.name = "Understory"
	add_child(understory)

	for i in 42:
		var angle := _rng.randf_range(0, TAU)
		var dist := _rng.randf_range(2.0, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _terrain_height(pos.x, pos.z)
		var bush := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = _rng.randf_range(0.2, 0.7)
		sph.radial_segments = 8
		bush.mesh = sph
		bush.position = Vector3(pos.x, pos.y + sph.radius * 0.35, pos.z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			_rng.randf_range(0.06, 0.14),
			_rng.randf_range(0.26, 0.42),
			_rng.randf_range(0.08, 0.18)
		)
		mat.roughness = 0.92
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.08
		bush.material_override = mat
		bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		understory.add_child(bush)

	for i in 14:
		var angle := _rng.randf_range(0, TAU)
		var dist := _rng.randf_range(4.0, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _terrain_height(pos.x, pos.z)
		var stump := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.3
		cyl.bottom_radius = 0.38
		cyl.height = 0.4
		cyl.radial_segments = 12
		stump.mesh = cyl
		stump.position = Vector3(pos.x, pos.y + 0.2, pos.z)
		stump.material_override = _make_bark_material()
		stump.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		understory.add_child(stump)


func _build_ferns() -> void:
	var ferns := Node3D.new()
	ferns.name = "Ferns"
	add_child(ferns)

	for i in 55:
		var angle := _rng.randf_range(0, TAU)
		var dist := _rng.randf_range(2.5, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _terrain_height(pos.x, pos.z)
		var fern := Node3D.new()
		fern.position = pos
		fern.rotation.y = _rng.randf_range(0, TAU)
		for j in 5:
			var frond := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.04, 0.55, 0.12)
			frond.mesh = box
			frond.rotation.y = j * TAU / 5.0
			frond.position = Vector3(0, 0.28, 0)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.1, 0.38, 0.14)
			mat.roughness = 0.85
			frond.material_override = mat
			fern.add_child(frond)
		ferns.add_child(fern)


func _build_atmosphere_particles() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "ForestMist"
	particles.amount = 120
	particles.lifetime = 8.0
	particles.visibility_aabb = AABB(Vector3(-40, 0, -40), Vector3(80, 12, 80))
	particles.position = Vector3(0, 2.5, 0)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(forest_radius * 0.85, 3.0, forest_radius * 0.85)
	mat.direction = Vector3(0.1, 0.2, 0.05)
	mat.spread = 25.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.45
	mat.gravity = Vector3(0, -0.02, 0)
	mat.scale_min = 0.08
	mat.scale_max = 0.2
	mat.color = Color(0.82, 0.9, 0.78, 0.25)
	particles.process_material = mat

	var quad := QuadMesh.new()
	quad.size = Vector2(0.15, 0.15)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.9, 0.95, 0.88, 0.2)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = draw_mat
	particles.draw_pass_1 = quad
	add_child(particles)


func _apply_tree_materials(tree: Node3D) -> void:
	var bark := _make_bark_material()
	var leaf_noise := _make_noise_texture(0.22, 3)
	for child in tree.get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			if "Foliage" in child.name:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(
					_rng.randf_range(0.06, 0.12),
					_rng.randf_range(0.28, 0.38),
					_rng.randf_range(0.08, 0.16)
				)
				mat.albedo_texture = leaf_noise
				mat.roughness = 0.84
				mat.emission_enabled = true
				mat.emission = mat.albedo_color * 0.12
				mesh_inst.material_override = mat
			else:
				var bark_copy := bark.duplicate() as StandardMaterial3D
				mesh_inst.material_override = bark_copy
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

