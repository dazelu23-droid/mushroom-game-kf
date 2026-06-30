class_name MyceliumColony
extends Node3D

## Dikaryotic mycelium with apical tip growth, chemotaxis, and enzyme-gated nutrient uptake.

signal colonization_ready
signal grow_state_changed(is_growing: bool)

class HyphaTip:
	var position: Vector3 = Vector3.ZERO
	var direction: Vector3 = Vector3(0.0, -0.05, 1.0).normalized()
	var depth: int = 0
	var energy: float = 1.0
	var age: float = 0.0
	var radius: float = 0.018


@export var growth_speed: float = 6.2
@export var max_branches: int = 180
@export var colonization_target: float = 80.0
@export var tip_search_range: float = 16.0
@export var absorb_range: float = 4.5
@export var branch_chance: float = 0.09
@export var chemotaxis_strength: float = 0.78
@export var tortuosity: float = 0.22

var _tips: Array[HyphaTip] = []
var _nutrient_sources: Array[NutrientSource] = []
var _active := false
var _grow_requested := false
var _rng := RandomNumberGenerator.new()
var _colonization_signaled := false
var _hypha_material: StandardMaterial3D
var _tip_glow_material: StandardMaterial3D
var _hypha_root: Node3D
var _tip_glows: Node3D
var _branch_count := 0
var _species: Dictionary = {}
var _tip_glow_pool: Array[MeshInstance3D] = []
var _network_nodes: Array[Vector3] = []
var _junction_mesh: SphereMesh


func _ready() -> void:
	_hypha_root = Node3D.new()
	_hypha_root.name = "Hyphae"
	add_child(_hypha_root)
	_tip_glows = Node3D.new()
	_tip_glows.name = "TipGlows"
	add_child(_tip_glows)
	_build_materials()


func setup(origin: Vector3, nutrients: Array[NutrientSource]) -> void:
	for child in _hypha_root.get_children():
		child.queue_free()
	for child in _tip_glows.get_children():
		child.queue_free()
	_tip_glow_pool.clear()
	_tips.clear()
	_branch_count = 0
	_network_nodes.clear()
	_tip_glow_pool.clear()
	position = origin
	_nutrient_sources = nutrients
	_species = GameState.selected_species
	_rng.randomize()
	_create_initial_hypha()


func activate() -> void:
	_active = true
	_colonization_signaled = false
	visible = true


func deactivate() -> void:
	_active = false
	_grow_requested = false
	_clear_tip_glows()
	grow_state_changed.emit(false)


func set_grow_active(active: bool) -> void:
	_grow_requested = active
	grow_state_changed.emit(_is_growing())


func is_grow_active() -> bool:
	return _grow_requested


func _build_materials() -> void:
	_hypha_material = StandardMaterial3D.new()
	_hypha_material.albedo_color = Color(0.94, 0.91, 0.84, 0.92)
	_hypha_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hypha_material.roughness = 0.28
	_hypha_material.metallic = 0.0
	_hypha_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_hypha_material.subsurf_scatter_enabled = true
	_hypha_material.subsurf_scatter_strength = 0.55
	_hypha_material.subsurf_scatter_transmittance_enabled = true
	_hypha_material.subsurf_scatter_transmittance_color = Color(0.98, 0.9, 0.78)
	_hypha_material.subsurf_scatter_transmittance_depth = 0.08
	_hypha_material.clearcoat_enabled = true
	_hypha_material.clearcoat = 0.22
	_hypha_material.clearcoat_roughness = 0.18

	_tip_glow_material = StandardMaterial3D.new()
	_tip_glow_material.albedo_color = Color(0.98, 0.95, 0.82, 0.75)
	_tip_glow_material.emission_enabled = true
	_tip_glow_material.emission = Color(0.85, 0.95, 0.7)
	_tip_glow_material.emission_energy_multiplier = 1.8
	_tip_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tip_glow_material.roughness = 0.15

	_junction_mesh = SphereMesh.new()
	_junction_mesh.radial_segments = 8
	_junction_mesh.rings = 4


func _create_initial_hypha() -> void:
	var tip := HyphaTip.new()
	tip.position = Vector3.ZERO
	tip.direction = Vector3(0.0, -0.08, 1.0).normalized()
	tip.depth = 0
	_tips.append(tip)
	tip.radius = _add_hypha_segment(
		Vector3.ZERO, Vector3(0.0, -0.008, 0.1), 0, tip.direction, tip.radius, false
	)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var growing := _is_growing()
	var network_full := _branch_count >= max_branches

	if growing and not network_full:
		_grow_step(delta)
	elif GameState.colonization_percent < colonization_target:
		_absorb_from_tips(delta)

	if network_full:
		_mature_colonization(delta)

	_update_tip_glows(growing or network_full)

	if GameState.colonization_percent >= colonization_target and not _colonization_signaled:
		_signal_colonization_ready()


func _signal_colonization_ready() -> void:
	if _colonization_signaled:
		return
	_colonization_signaled = true
	colonization_ready.emit()


func _is_growing() -> bool:
	return Input.is_action_pressed("grow_mycelium") or _grow_requested


func _grow_step(delta: float) -> void:
	var new_tips: Array[HyphaTip] = []
	var temp_c: float = GameState.temperature_c
	var colon_temp: Vector2 = MushroomSpeciesData.get_vector2(
		_species, "colonization_temp_c", Vector2(12.0, 24.0)
	)
	var temp_factor := _temperature_growth_factor(temp_c, colon_temp)

	for tip in _tips:
		tip.age += delta
		var nutrient := _find_nearest_nutrient_for_tip(tip)
		if nutrient == null:
			_explore_step(tip, delta, temp_factor, new_tips)
			continue

		var target := to_local(nutrient.global_position)
		var to_target := target - tip.position
		var dist := to_target.length()

		var efficiency := MushroomSpeciesData.digest_efficiency(
			_species, nutrient.get_nutrient_type()
		)
		var speed_boost := 1.0 + efficiency * 0.4
		if dist < absorb_range:
			speed_boost += 0.55
			_intake_from_nutrient(nutrient, delta, efficiency, speed_boost)

		if dist < 0.08:
			new_tips.append(tip)
			continue

		var desired_dir := _substrate_direction(to_target.normalized())
		tip.direction = tip.direction.lerp(desired_dir, chemotaxis_strength * delta * 5.0).normalized()
		tip.direction = tip.direction.rotated(
			Vector3.UP,
			_rng.randf_range(-tortuosity, tortuosity) * delta * 4.0
		)
		tip.direction = _substrate_direction(tip.direction)

		var length := growth_speed * temp_factor * speed_boost * delta * _rng.randf_range(0.7, 1.0)
		var start := tip.position
		var end := start + tip.direction * length
		tip.direction = (end - start).normalized()
		tip.radius = _add_hypha_segment(start, end, tip.depth, tip.direction, tip.radius)
		tip.position = end
		tip.depth += 1
		new_tips.append(tip)

		var near_food := dist <= absorb_range * 1.4
		if tip.depth > 3 and near_food and _rng.randf() < branch_chance and _branch_count < max_branches - 1:
			_add_hypha_junction(tip.position, tip.radius)
			var branch := HyphaTip.new()
			branch.position = tip.position
			branch.radius = tip.radius
			branch.direction = _substrate_direction(
				tip.direction.rotated(Vector3.UP, _rng.randf_range(0.35, 0.75) * (1.0 if _rng.randf() > 0.5 else -1.0))
			)
			branch.depth = tip.depth
			branch.energy = tip.energy * 0.65
			var branch_start := branch.position
			var branch_end := branch_start + branch.direction * length * 0.55
			branch.direction = (branch_end - branch_start).normalized()
			branch.radius = _add_hypha_segment(
				branch_start, branch_end, branch.depth, branch.direction, branch.radius
			)
			branch.position = branch_end
			branch.depth += 1
			new_tips.append(branch)

	_tips = new_tips
	if _tips.is_empty():
		_create_initial_hypha()


func _absorb_from_tips(delta: float) -> void:
	for tip in _tips:
		var nutrient := _find_nearest_nutrient_for_tip(tip)
		if nutrient == null:
			continue
		var target := to_local(nutrient.global_position)
		if target.distance_to(tip.position) > absorb_range:
			continue
		var efficiency := MushroomSpeciesData.digest_efficiency(
			_species, nutrient.get_nutrient_type()
		)
		_intake_from_nutrient(nutrient, delta, efficiency, 1.0 + efficiency * 0.4)


func _explore_step(tip: HyphaTip, delta: float, temp_factor: float, new_tips: Array[HyphaTip]) -> void:
	tip.direction = tip.direction.rotated(
		Vector3.UP,
		_rng.randf_range(-0.45, 0.45) * delta * 3.0
	)
	tip.direction = _substrate_direction(tip.direction)
	var length := growth_speed * temp_factor * 0.5 * delta
	var start := tip.position
	var end := start + tip.direction * length
	tip.direction = (end - start).normalized()
	tip.radius = _add_hypha_segment(start, end, tip.depth, tip.direction, tip.radius)
	tip.position = end
	tip.depth += 1
	new_tips.append(tip)


func _intake_from_nutrient(
	nutrient: NutrientSource,
	delta: float,
	efficiency: float,
	speed_boost: float
) -> void:
	var absorb_rate := 4.8 * efficiency * delta * speed_boost
	var absorbed: float = nutrient.absorb(absorb_rate)
	if absorbed > 0.0:
		GameState.add_nutrients(absorbed)
		GameState.add_colonization(absorbed * 0.4 * efficiency)
		nutrient.pulse_absorption(absorbed)


func _substrate_direction(dir: Vector3) -> Vector3:
	if dir.length_squared() < 0.0001:
		return Vector3(0.0, -0.05, 1.0)
	dir = dir.normalized()
	dir.y = clampf(dir.y, -0.1, 0.03)
	var horizontal := Vector3(dir.x, 0.0, dir.z)
	if horizontal.length_squared() < 0.0001:
		horizontal = Vector3(0.0, 0.0, 1.0)
	horizontal = horizontal.normalized()
	return (horizontal * 0.94 + Vector3(0.0, dir.y, 0.0)).normalized()


func _temperature_growth_factor(temp_c: float, optimal: Vector2) -> float:
	var mid := (optimal.x + optimal.y) * 0.5
	var half_span := maxf((optimal.y - optimal.x) * 0.5, 1.0)
	var deviation := absf(temp_c - mid) / half_span
	return clampf(1.15 - deviation * 0.55, 0.35, 1.15)


func _find_nearest_nutrient_for_tip(tip: HyphaTip) -> NutrientSource:
	var best: NutrientSource = null
	var best_score := INF
	var tip_world := global_position + tip.position
	for source in _nutrient_sources:
		if source.is_depleted():
			continue
		var dist := tip_world.distance_to(source.global_position)
		if dist > tip_search_range:
			continue
		var efficiency := MushroomSpeciesData.digest_efficiency(
			_species, source.get_nutrient_type()
		)
		var score := dist / maxf(efficiency, 0.15)
		if score < best_score:
			best_score = score
			best = source
	return best


func _add_hypha_segment(
	start: Vector3,
	end: Vector3,
	depth: int,
	growth_dir: Vector3,
	start_radius: float,
	overlap_start: bool = true
) -> float:
	var dir := growth_dir
	if dir.length_squared() < 0.0001:
		dir = (end - start).normalized()
	if overlap_start and start_radius > 0.0 and dir.length_squared() > 0.0001:
		start = start - dir * start_radius * 0.65
		_add_hypha_junction(start + dir * start_radius * 0.65, start_radius)

	var segment_length := start.distance_to(end)
	if segment_length < 0.006:
		return start_radius

	var depth_t := clampf(1.0 - float(depth) / 32.0, 0.28, 1.0)
	var bottom_r := start_radius if start_radius > 0.0 else lerpf(0.004, 0.022, depth_t)
	var top_r := bottom_r * lerpf(0.92, 0.96, depth_t)
	var mid_r := (bottom_r + top_r) * 0.5

	_add_hypha_cylinder(start, end, bottom_r, top_r, dir)
	if segment_length > 0.04 and _rng.randf() > 0.35:
		var axis := Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-0.35, 0.35),
			_rng.randf_range(-1.0, 1.0)
		).normalized()
		if axis.length_squared() > 0.0001:
			var bend := dir.rotated(axis, _rng.randf_range(-0.12, 0.12))
			var mid := start + dir * segment_length * 0.5
			var mid_end := mid + bend * segment_length * 0.52
			_add_hypha_cylinder(mid, mid_end, mid_r, top_r, (mid_end - mid).normalized())

	_register_network_point(end, top_r)
	_try_anastomosis(end, top_r)

	_branch_count += 1
	GameState.add_colonization(_colonization_for_segment(segment_length))
	return top_r


func _colonization_for_segment(segment_length: float) -> float:
	var per_branch := colonization_target / float(max_branches)
	return per_branch * clampf(segment_length / 0.09, 0.7, 1.15)


func _mature_colonization(delta: float) -> void:
	if GameState.colonization_percent >= colonization_target:
		return
	var remaining := colonization_target - GameState.colonization_percent
	GameState.add_colonization(remaining * minf(delta * 0.45, 0.12))


func _add_hypha_cylinder(
	start: Vector3,
	end: Vector3,
	bottom_r: float,
	top_r: float,
	dir: Vector3
) -> void:
	var segment_length := start.distance_to(end)
	if segment_length < 0.004:
		return

	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = segment_length
	mesh.radial_segments = 10
	mesh.rings = 2
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _hypha_material

	var mid := (start + end) * 0.5
	mesh_instance.position = mid
	_hypha_root.add_child(mesh_instance)
	if dir.length_squared() > 0.0001:
		var y_axis := dir.normalized()
		var up := Vector3.UP
		if absf(y_axis.dot(up)) > 0.98:
			up = Vector3.RIGHT
		var x_axis := up.cross(y_axis).normalized()
		var z_axis := x_axis.cross(y_axis).normalized()
		mesh_instance.basis = Basis(x_axis, y_axis, z_axis)


func _register_network_point(at: Vector3, radius: float) -> void:
	_network_nodes.append(at)
	if _network_nodes.size() > 320:
		_network_nodes.pop_front()
	_add_hypha_junction(at, radius * 0.92)


func _try_anastomosis(at: Vector3, radius: float) -> void:
	var connect_range := radius * 8.0
	for node in _network_nodes:
		if node.is_equal_approx(at):
			continue
		var dist := node.distance_to(at)
		if dist > connect_range or dist < radius * 1.2:
			continue
		_add_hypha_bridge(node, at, radius * 0.72)
		return


func _add_hypha_bridge(from: Vector3, to: Vector3, bridge_radius: float) -> void:
	var dir := to - from
	var length := dir.length()
	if length < 0.015:
		return
	dir = dir.normalized()
	_add_hypha_cylinder(from, to, bridge_radius, bridge_radius * 0.94, dir)
	_add_hypha_junction(from, bridge_radius)
	_add_hypha_junction(to, bridge_radius * 0.94)


func _add_hypha_junction(at: Vector3, radius: float) -> void:
	if radius <= 0.0:
		return
	var mesh_instance := MeshInstance3D.new()
	var sphere := _junction_mesh.duplicate() as SphereMesh
	sphere.radius = radius * 1.05
	sphere.height = radius * 2.1
	mesh_instance.mesh = sphere
	mesh_instance.material_override = _hypha_material
	mesh_instance.position = at
	_hypha_root.add_child(mesh_instance)


func _update_tip_glows(show: bool) -> void:
	if not show:
		for glow in _tip_glow_pool:
			glow.visible = false
		return

	while _tip_glow_pool.size() < _tips.size():
		var glow := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.016
		sphere.height = 0.032
		sphere.radial_segments = 6
		sphere.rings = 3
		glow.mesh = sphere
		glow.material_override = _tip_glow_material
		_tip_glows.add_child(glow)
		_tip_glow_pool.append(glow)

	for i in _tips.size():
		var tip := _tips[i]
		var glow := _tip_glow_pool[i]
		glow.visible = true
		var glow_r := maxf(tip.radius, 0.012) * 1.15
		glow.scale = Vector3.ONE * (glow_r / 0.016)
		glow.position = tip.position

	for i in range(_tips.size(), _tip_glow_pool.size()):
		_tip_glow_pool[i].visible = false


func _clear_tip_glows() -> void:
	for glow in _tip_glow_pool:
		glow.visible = false
