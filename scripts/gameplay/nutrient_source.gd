class_name NutrientSource
extends Area3D

@export var nutrient_type: String = "cellulose"
@export var nutrient_amount: float = 25.0
@export var label_text: String = "Decaying hardwood log"

var _depleted := false
var _base_albedo := Color(0.32, 0.24, 0.16)
var _mesh: MeshInstance3D
var _pulse_tween: Tween


func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_mesh = get_parent().get_node_or_null("Mesh") as MeshInstance3D
	if _mesh:
		var mat := _mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			_base_albedo = mat.albedo_color


func is_depleted() -> bool:
	return _depleted


func absorb(amount: float) -> float:
	if _depleted:
		return 0.0
	var taken: float = minf(amount, nutrient_amount)
	nutrient_amount -= taken
	if nutrient_amount <= 0.0:
		_depleted = true
		_set_depleted_visual()
	return taken


func get_nutrient_type() -> String:
	return nutrient_type


func get_remaining_fraction() -> float:
	var max_amount := 40.0
	return clampf(nutrient_amount / max_amount, 0.0, 1.0)


func pulse_absorption(amount: float) -> void:
	if _mesh == null:
		return
	var mat := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	var intensity := clampf(amount * 0.15, 0.05, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.32, 0.12) * intensity
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(mat, "emission_energy_multiplier", 2.2, 0.08)
	_pulse_tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.35)
	_pulse_tween.tween_callback(func() -> void:
		if not _depleted:
			mat.emission_enabled = false
	)


func _set_depleted_visual() -> void:
	if _mesh == null:
		return
	var mat := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.22, 0.2, 0.18)
		mat.roughness = 0.98
		mat.emission_enabled = false


func _on_mouse_entered() -> void:
	if not _depleted:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	pass
