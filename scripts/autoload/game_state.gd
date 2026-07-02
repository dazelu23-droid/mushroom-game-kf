extends Node

signal phase_changed(phase: LifeCycle.Phase)
signal nutrients_changed(amount: float, max_amount: float)
signal colonization_changed(percent: float)
signal fact_updated(title: String, fact: String)
signal colonies_changed(spawned: int, mature: int)

var selected_species: Dictionary = {}
var current_phase: LifeCycle.Phase = LifeCycle.Phase.SPORE_DISPERSAL

var landing_position: Vector3 = Vector3.ZERO
var landing_substrate: String = ""
var landing_patch: SubstratePatch

var nutrients: float = 0.0
var max_nutrients: float = 100.0
var colonization_percent: float = 0.0

var humidity: float = 50.0
var co2_level: float = 80.0
var temperature_c: float = 18.0

var growth_progress: float = 0.0
var spores_released: int = 0
var spawned_colonies: int = 0
var mature_colonies: int = 0


func select_species(species: Dictionary) -> void:
	selected_species = species
	reset_run()


func reset_run() -> void:
	current_phase = LifeCycle.Phase.SPORE_DISPERSAL
	landing_position = Vector3.ZERO
	landing_substrate = ""
	landing_patch = null
	nutrients = 0.0
	max_nutrients = 100.0
	colonization_percent = 0.0
	humidity = 50.0
	co2_level = 80.0
	temperature_c = 18.0
	growth_progress = 0.0
	spores_released = 0
	spawned_colonies = 0
	mature_colonies = 0
	_emit_phase()


func set_phase(phase: LifeCycle.Phase) -> void:
	current_phase = phase
	_emit_phase()


func add_nutrients(amount: float) -> void:
	nutrients = clampf(nutrients + amount, 0.0, max_nutrients)
	nutrients_changed.emit(nutrients, max_nutrients)


func add_colonization(amount: float) -> void:
	set_colonization(colonization_percent + amount)


func set_colonization(percent: float) -> void:
	colonization_percent = clampf(percent, 0.0, 100.0)
	colonization_changed.emit(colonization_percent)


func set_colony_counts(spawned: int, mature: int) -> void:
	spawned_colonies = maxi(spawned, 0)
	mature_colonies = maxi(mature, 0)
	colonies_changed.emit(spawned_colonies, mature_colonies)


func _emit_phase() -> void:
	phase_changed.emit(current_phase)
	var info: Dictionary = LifeCycle.PHASE_FACTS[current_phase]
	fact_updated.emit(String(info.get("title", "")), String(info.get("fact", "")))
