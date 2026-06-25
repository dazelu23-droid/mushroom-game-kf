extends Node3D

const ROTATE_SPEED := 0.003
const ZOOM_SPEED := 0.4
const MIN_DISTANCE := 3.0
const MAX_DISTANCE := 18.0

var _dragging := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust_zoom(-ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust_zoom(ZOOM_SPEED)
	elif event is InputEventMouseMotion and _dragging:
		rotation.y -= event.relative.x * ROTATE_SPEED
		rotation.x = clampf(rotation.x - event.relative.y * ROTATE_SPEED, -0.6, 0.35)


func _adjust_zoom(delta: float) -> void:
	var camera := $Camera3D as Camera3D
	var local := camera.position
	local.z = clampf(local.z + delta, MIN_DISTANCE, MAX_DISTANCE)
	camera.position = local
