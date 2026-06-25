extends Control
class_name GameHUD

@onready var phase_label: Label = %PhaseLabel
@onready var fact_label: RichTextLabel = %FactLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var stats_label: Label = %StatsLabel
@onready var env_label: Label = %EnvLabel
@onready var species_label: Label = %SpeciesLabel
@onready var land_button: Button = %LandButton


func _ready() -> void:
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.fact_updated.connect(_on_fact_updated)
	GameState.nutrients_changed.connect(_on_nutrients_changed)
	GameState.colonization_changed.connect(_on_colonization_changed)
	_update_species()
	land_button.visible = false
	land_button.pressed.connect(_on_land_pressed)


func bind_spore(spore: SporePlayer) -> void:
	if spore.landing_ready_changed.is_connected(_on_landing_ready_changed):
		spore.landing_ready_changed.disconnect(_on_landing_ready_changed)
	spore.landing_ready_changed.connect(_on_landing_ready_changed)


func set_landing_ui_visible(show_landing: bool) -> void:
	land_button.visible = show_landing
	if not show_landing:
		land_button.disabled = true


func _on_landing_ready_changed(can_land: bool, over_compatible: bool) -> void:
	land_button.disabled = not can_land
	if can_land and over_compatible:
		land_button.text = "Land on substrate"
	elif can_land:
		land_button.text = "Land (wrong substrate)"
	else:
		land_button.text = "Land — drift over green patch"


func _on_land_pressed() -> void:
	var spore := get_tree().get_first_node_in_group("spore_player") as SporePlayer
	if spore:
		spore.request_land()


func _update_species() -> void:
	if GameState.selected_species.is_empty():
		return
	species_label.text = "%s — %s" % [
		GameState.selected_species.get("common_name", ""),
		GameState.selected_species.get("scientific_name", ""),
	]


func show_objective(text: String) -> void:
	objective_label.text = text


func update_environment(humidity: float, co2: float) -> void:
	env_label.text = "Humidity: %.0f%% | CO₂: %.0f%%" % [humidity, co2]


func _on_phase_changed(phase: LifeCycle.Phase) -> void:
	var info: Dictionary = LifeCycle.PHASE_FACTS[phase]
	phase_label.text = String(info.get("title", ""))


func _on_fact_updated(_title: String, fact: String) -> void:
	fact_label.text = fact


func _on_nutrients_changed(amount: float, max_amount: float) -> void:
	_update_stats(amount, max_amount, GameState.colonization_percent)


func _on_colonization_changed(percent: float) -> void:
	_update_stats(GameState.nutrients, GameState.max_nutrients, percent)


func _update_stats(nutrients: float, max_nutrients: float, colonization: float) -> void:
	stats_label.text = "Nutrients: %.0f/%.0f | Colonization: %.0f%%" % [
		nutrients, max_nutrients, colonization,
	]


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/species_select.tscn")
