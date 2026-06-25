extends Node3D

class_name SporePlayer

signal landed_on_substrate(position: Vector3, substrate_type: String)
signal germination_complete
signal landing_ready_changed(can_land: bool, over_compatible: bool)

@export var wind_strength: float = 2.2
@export var drift_control: float = 4.5
@export var float_altitude: float = 8.0
@export var landing_snap_speed: float = 14.0

var _active := false
var _landed := false
var _compatible_landing := false
var _germination_timer := 0.0
var _landing_in_progress := false
var _landing_target := Vector3.ZERO
var _pending_substrate_type := ""
var _can_land := false
var _over_compatible := false
const GERMINATION_TIME := 2.5
const LANDING_DETECT_RADIUS := 4.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _halo: MeshInstance3D = $Halo
@onready var _glow: OmniLight3D = $Glow
var _spore_camera: OrbitCamera = null


func _ready() -> void:
	add_to_group("spore_player")
	_spore_camera = get_parent().get_node_or_null("SporeCamera") as OrbitCamera
	_setup_visuals()


func _setup_visuals() -> void:
	_mesh.scale = Vector3.ONE
	if _halo:
		_halo.scale = Vector3.ONE * 1.35
	_glow.light_energy = 0.55
	_glow.omni_range = 1.2

	var mat := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat = mat.duplicate() as StandardMaterial3D
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.95, 0.55)
		mat.emission_energy_multiplier = 1.5
		_mesh.set_surface_override_material(0, mat)


func _get_camera_input_direction() -> Vector3:
	if _spore_camera == null:
		return Vector3.ZERO
	var forward: Vector3 = _spore_camera.get_flat_forward()
	var right: Vector3 = _spore_camera.get_flat_right()
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir += forward
	if Input.is_action_pressed("move_back"):
		input_dir -= forward
	if Input.is_action_pressed("move_right"):
		input_dir += right
	if Input.is_action_pressed("move_left"):
		input_dir -= right
	return input_dir


func activate() -> void:
	_active = true
	_landed = false
	_compatible_landing = false
	_germination_timer = 0.0
	_landing_in_progress = false
	position = Vector3(randf_range(-4.0, 4.0), float_altitude, randf_range(-4.0, 4.0))
	visible = true
	if _spore_camera:
		_spore_camera.set_target(self)
		_spore_camera.set_follow_enabled(true)
		_spore_camera.current = true
	_update_landing_state()


func deactivate() -> void:
	_active = false
	visible = false


func request_land() -> void:
	if not _active or _landed or _landing_in_progress:
		return
	var patch := _find_nearest_patch(LANDING_DETECT_RADIUS)
	if patch == null:
		return
	_landing_in_progress = true
	_landing_target = Vector3(
		position.x,
		patch.global_position.y + 0.12,
		position.z
	)
	_pending_substrate_type = patch.get_substrate_type()


func _physics_process(delta: float) -> void:
	if not _active:
		return

	if not _landed:
		if _landing_in_progress:
			position = position.move_toward(_landing_target, landing_snap_speed * delta)
			if position.distance_to(_landing_target) < 0.08:
				position = _landing_target
				_landing_in_progress = false
				_try_land(_pending_substrate_type)
		else:
			_drift_spore(delta)
			_update_landing_state()
		return

	if not _compatible_landing:
		return

	_germination_timer += delta
	if _germination_timer >= GERMINATION_TIME:
		germination_complete.emit()
		deactivate()


func _update_landing_state() -> void:
	var patch := _find_nearest_patch(LANDING_DETECT_RADIUS)
	var can_land: bool = patch != null
	var compatible: bool = false
	if patch:
		var substrates: Array = MushroomSpeciesData.get_substrates(GameState.selected_species)
		compatible = patch.get_substrate_type() in substrates
	if can_land != _can_land or compatible != _over_compatible:
		_can_land = can_land
		_over_compatible = compatible
		landing_ready_changed.emit(_can_land, _over_compatible)


func _drift_spore(delta: float) -> void:
	var wind := Vector3(
		sin(Time.get_ticks_msec() * 0.0012) * wind_strength,
		0.0,
		cos(Time.get_ticks_msec() * 0.0009) * wind_strength
	)
	var input_dir: Vector3 = _get_camera_input_direction()

	if input_dir.length_squared() > 0.0001:
		position += input_dir.normalized() * drift_control * delta
	position += wind * delta
	position.y = lerpf(position.y, float_altitude, delta * 0.35)

	if Input.is_action_just_pressed("land_spore"):
		request_land()


func _try_land(substrate_type: String) -> void:
	var species: Dictionary = GameState.selected_species
	var substrates: Array = MushroomSpeciesData.get_substrates(species)
	var compatible: bool = substrate_type in substrates
	_compatible_landing = compatible
	landed_on_substrate.emit(position, substrate_type)
	if compatible:
		_landed = true
		GameState.landing_position = position
		GameState.landing_substrate = substrate_type
		var germ_temp: Vector2 = MushroomSpeciesData.get_vector2(species, "germination_temp_c", Vector2(10.0, 24.0))
		GameState.temperature_c = randf_range(germ_temp.x, germ_temp.y)
		_reset_spore_material()
	else:
		_landing_in_progress = false
		position.y = float_altitude
		_mesh.set_surface_override_material(
			0,
			_create_material(Color(1.0, 0.2, 0.2))
		)


func _reset_spore_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.55)
	mat.emission_energy_multiplier = 1.5
	mat.roughness = 0.3
	_mesh.set_surface_override_material(0, mat)


func _find_nearest_patch(max_dist: float) -> SubstratePatch:
	var best_patch: SubstratePatch = null
	var best_dist := max_dist
	for node in get_tree().get_nodes_in_group("substrate"):
		var patch := node as SubstratePatch
		if patch == null:
			continue
		var horizontal := Vector2(patch.global_position.x, patch.global_position.z)
		var spore_pos := Vector2(position.x, position.z)
		var dist := horizontal.distance_to(spore_pos)
		if dist < best_dist:
			best_dist = dist
			best_patch = patch
	return best_patch


func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	return mat
