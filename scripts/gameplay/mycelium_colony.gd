class_name MyceliumColony
extends Node3D

## Visualizes dikaryotic mycelium spreading through substrate.
## Hyphae grow ~1–10 µm diameter; here scaled for visibility.

signal colonization_ready

@export var growth_speed: float = 8.0
@export var max_branches: int = 48

var _branches: Array[Node3D] = []
var _nutrient_sources: Array[NutrientSource] = []
var _active := false
var _tip_positions: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()
var _colonization_signaled := false


func setup(origin: Vector3, nutrients: Array[NutrientSource]) -> void:
	for branch in _branches:
		if is_instance_valid(branch):
			branch.queue_free()
	_branches.clear()
	position = origin
	_nutrient_sources = nutrients
	_rng.randomize()
	_create_initial_hypha()


func activate() -> void:
	_active = true
	_colonization_signaled = false
	visible = true


func deactivate() -> void:
	_active = false


func _create_initial_hypha() -> void:
	_tip_positions.clear()
	_tip_positions.append(Vector3.ZERO)
	_add_hypha_segment(Vector3.ZERO, Vector3(0.0, -0.02, 0.15))


func _physics_process(delta: float) -> void:
	if not _active:
		return

	if Input.is_action_pressed("grow_mycelium") and _branches.size() < max_branches:
		_grow_step(delta)

	if GameState.colonization_percent >= 80.0 and not _colonization_signaled:
		_colonization_signaled = true
		colonization_ready.emit()


func _grow_step(delta: float) -> void:
	var nutrient: NutrientSource = _find_nearest_nutrient(18.0)
	if nutrient == null:
		return

	var target: Vector3 = to_local(nutrient.global_position)
	var new_tips: Array[Vector3] = []

	for tip in _tip_positions:
		var offset: Vector3 = target - tip
		if offset.length_squared() < 0.01:
			continue
		var direction: Vector3 = offset.normalized()
		direction.y = clampf(direction.y, -0.3, 0.1)
		direction = direction.rotated(Vector3.UP, _rng.randf_range(-0.6, 0.6)).normalized()
		var length: float = growth_speed * delta * _rng.randf_range(0.4, 1.0)
		var end := tip + direction * length
		_add_hypha_segment(tip, end)
		new_tips.append(end)

		if _rng.randf() < 0.35:
			var branch_dir := direction.rotated(Vector3.UP, _rng.randf_range(-1.2, 1.2))
			var branch_end := tip + branch_dir * length * 0.7
			_add_hypha_segment(tip, branch_end)
			new_tips.append(branch_end)

		var absorbed: float = nutrient.absorb(2.5 * delta)
		if absorbed > 0.0:
			GameState.add_nutrients(absorbed)
			GameState.set_colonization(
				GameState.colonization_percent + absorbed * 0.15
			)

	_tip_positions = new_tips


func _find_nearest_nutrient(max_range: float) -> NutrientSource:
	var best: NutrientSource = null
	var best_dist := INF
	for source in _nutrient_sources:
		if source.is_depleted():
			continue
		var dist := global_position.distance_to(source.global_position)
		if dist <= max_range and dist < best_dist:
			best_dist = dist
			best = source
	return best


func _add_hypha_segment(start: Vector3, end: Vector3) -> void:
	var segment_length := start.distance_to(end)
	if segment_length < 0.01:
		return

	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.015
	mesh.bottom_radius = 0.02
	mesh.height = segment_length
	mesh.radial_segments = 4

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.9, 0.85, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat

	var mid := (start + end) * 0.5
	mesh_instance.position = mid
	if segment_length > 0.01:
		mesh_instance.look_at(end, Vector3.UP)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI * 0.5)

	add_child(mesh_instance)
	_branches.append(mesh_instance)
