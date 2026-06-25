extends Node3D

class_name SporeRelease

signal cycle_complete

@export var release_duration: float = 8.0

var _timer := 0.0
var _active := false
var _spore_rate := 100.0

@onready var _particles: GPUParticles3D = $SporeParticles
@onready var _growth: MushroomGrowthVisual = %MushroomGrowth


func activate() -> void:
	_active = true
	_timer = 0.0
	var species: Dictionary = GameState.selected_species
	_spore_rate = float(species.get("spores_per_day", 12000)) / 60.0
	_particles.emitting = true
	_particles.amount = int(clampf(_spore_rate * 0.5, 200.0, 2000.0))
	if _growth:
		_particles.global_position = _growth.get_cap_position()


func _process(delta: float) -> void:
	if not _active:
		return

	_timer += delta
	GameState.spores_released += int(_spore_rate * delta)
	if _growth:
		_particles.global_position = _growth.get_cap_position()

	if _timer >= release_duration:
		_active = false
		_particles.emitting = false
		cycle_complete.emit()
