class_name NutrientSource
extends Area3D

@export var nutrient_type: String = "cellulose"
@export var nutrient_amount: float = 25.0
@export var label_text: String = "Decaying hardwood log"

var _depleted := false


func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


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


func _set_depleted_visual() -> void:
	var mesh := get_parent().get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.25, 0.22, 0.2)


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
