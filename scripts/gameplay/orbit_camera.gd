extends Camera3D
class_name OrbitCamera

@export var target_path: NodePath
@export var follow_distance: float = 14.0
@export var min_distance: float = 6.0
@export var max_distance: float = 30.0
@export var min_pitch: float = -85.0
@export var max_pitch: float = -10.0
@export var mouse_sensitivity: float = 0.22
@export var wheel_zoom_speed: float = 1.5
@export var focus_height_offset: float = 0.35
@export var follow_enabled_on_start: bool = true

var _yaw_deg: float = 0.0
var _pitch_deg: float = -28.0
var _dragging := false
var _target: Node3D = null
var _follow_enabled := true

var _focus_point: Vector3 = Vector3.ZERO
var _use_focus_point := false


func _ready() -> void:
	_follow_enabled = follow_enabled_on_start
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node3D
	_update_transform()


func set_target(node: Node3D) -> void:
	_target = node
	_use_focus_point = false


func set_focus_point(point: Vector3) -> void:
	_focus_point = point
	_use_focus_point = true


func set_follow_enabled(enabled: bool) -> void:
	_follow_enabled = enabled


func get_flat_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3(0, 0, -1)
	return forward.normalized()


func get_flat_right() -> Vector3:
	var right := global_transform.basis.x
	right.y = 0.0
	if right.length_squared() < 0.0001:
		right = Vector3(1, 0, 0)
	return right.normalized()


func _unhandled_input(event: InputEvent) -> void:
	if not _follow_enabled or not current:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			follow_distance = clampf(follow_distance - wheel_zoom_speed, min_distance, max_distance)
			_update_transform()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			follow_distance = clampf(follow_distance + wheel_zoom_speed, min_distance, max_distance)
			_update_transform()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_yaw_deg -= motion.relative.x * mouse_sensitivity
		_pitch_deg = clampf(_pitch_deg - motion.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		_update_transform()


func _process(_delta: float) -> void:
	if not _follow_enabled or not current:
		return
	_update_transform()


func _get_focus() -> Vector3:
	if _use_focus_point:
		return _focus_point + Vector3(0, focus_height_offset, 0)
	if _target:
		return _target.global_position + Vector3(0, focus_height_offset, 0)
	return global_position - global_transform.basis.z * follow_distance


func _update_transform() -> void:
	var focus := _get_focus()
	var yaw_rad := deg_to_rad(_yaw_deg)
	var pitch_rad := deg_to_rad(_pitch_deg)
	var horizontal := cos(pitch_rad) * follow_distance
	var offset := Vector3(
		sin(yaw_rad) * horizontal,
		-sin(pitch_rad) * follow_distance,
		cos(yaw_rad) * horizontal
	)
	global_position = focus + offset
	look_at(focus, Vector3.UP)
