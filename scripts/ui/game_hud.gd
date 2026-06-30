extends Control
class_name GameHUD

@onready var phase_label: Label = %PhaseLabel
@onready var fact_label: RichTextLabel = %FactLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var stats_label: Label = %StatsLabel
@onready var colonization_bar: ProgressBar = %ColonizationBar
@onready var env_label: Label = %EnvLabel
@onready var species_label: Label = %SpeciesLabel
@onready var land_button: Button = %LandButton
@onready var grow_button: Button = %GrowHyphaeButton
@onready var controls_hint: Label = %ControlsHint

var _mycelium: MyceliumColony


func _ready() -> void:
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.fact_updated.connect(_on_fact_updated)
	GameState.nutrients_changed.connect(_on_nutrients_changed)
	GameState.colonization_changed.connect(_on_colonization_changed)
	GameState.colonies_changed.connect(_on_colonies_changed)
	_update_species()
	land_button.visible = false
	land_button.pressed.connect(_on_land_pressed)
	grow_button.visible = false
	grow_button.toggled.connect(_on_grow_toggled)
	_refresh_colonization_display()


func refresh_colonization_display() -> void:
	_refresh_colonization_display()


func bind_spore(spore: SporePlayer) -> void:
	if spore.landing_ready_changed.is_connected(_on_landing_ready_changed):
		spore.landing_ready_changed.disconnect(_on_landing_ready_changed)
	spore.landing_ready_changed.connect(_on_landing_ready_changed)


func bind_mycelium(mycelium: MyceliumColony) -> void:
	_mycelium = mycelium
	if mycelium.grow_state_changed.is_connected(_on_mycelium_grow_changed):
		mycelium.grow_state_changed.disconnect(_on_mycelium_grow_changed)
	mycelium.grow_state_changed.connect(_on_mycelium_grow_changed)


func set_landing_ui_visible(show_landing: bool) -> void:
	land_button.visible = show_landing
	if not show_landing:
		land_button.disabled = true


func set_grow_ui_visible(show_grow: bool) -> void:
	grow_button.visible = show_grow
	if not show_grow:
		grow_button.button_pressed = false
		if _mycelium:
			_mycelium.set_grow_active(false)


func _on_landing_ready_changed(can_land: bool, over_compatible: bool) -> void:
	land_button.disabled = not can_land
	if can_land and over_compatible:
		land_button.text = "Land on substrate"
	elif can_land:
		land_button.text = "Land (wrong substrate)"
	else:
		land_button.text = "Land — drift over ring-marked patch"


func _on_land_pressed() -> void:
	var spore := get_tree().get_first_node_in_group("spore_player") as SporePlayer
	if spore:
		spore.request_land()


func _on_grow_toggled(pressed: bool) -> void:
	if _mycelium:
		_mycelium.set_grow_active(pressed)
	_update_grow_button_text(pressed)


func _on_mycelium_grow_changed(is_growing: bool) -> void:
	grow_button.set_pressed_no_signal(is_growing)
	_update_grow_button_text(is_growing)


func _update_grow_button_text(is_growing: bool) -> void:
	if is_growing:
		grow_button.text = "Growing — secreting enzymes & absorbing"
	else:
		grow_button.text = "Grow Hyphae & Intake Nutrients"


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


func set_explore_controls_visible(_show: bool) -> void:
	pass


func show_spectate_target(label: String, index: int, total: int) -> void:
	if label.is_empty():
		return
	stats_label.text = "Spectating (%d/%d): %s" % [index, total, label]


func _on_phase_changed(phase: LifeCycle.Phase) -> void:
	var info: Dictionary = LifeCycle.PHASE_FACTS[phase]
	phase_label.text = String(info.get("title", ""))
	_update_controls_hint(phase)
	if phase == LifeCycle.Phase.MYCELIUM_COLONIZATION:
		_refresh_colonization_display()
	elif phase != LifeCycle.Phase.ENVIRONMENTAL_TRIGGER:
		colonization_bar.visible = false


func _update_controls_hint(phase: LifeCycle.Phase) -> void:
	match phase:
		LifeCycle.Phase.SPORE_DISPERSAL:
			controls_hint.text = "WASD drift | Right-click orbit | Scroll zoom | L Land"
		LifeCycle.Phase.MYCELIUM_COLONIZATION:
			controls_hint.text = "Hold SPACE or toggle Grow button | Tips seek digestible nutrients | 80% to fruit"
		LifeCycle.Phase.ENVIRONMENTAL_TRIGGER:
			controls_hint.text = "H raise humidity | V ventilate CO₂ | Need >85% humidity, <40% CO₂"
		LifeCycle.Phase.FRUITING_BODY_GROWTH:
			controls_hint.text = "Tab/Q spectate wild mushrooms | Right-click orbit | Scroll zoom"
		LifeCycle.Phase.SPORE_PRODUCTION, LifeCycle.Phase.COMPLETE:
			controls_hint.text = "Tab/Q spectate | Right-drag pan | Shift+right orbit | Scroll zoom | F freecam | Esc exit freecam"
		_:
			controls_hint.text = "Right-click orbit camera | Scroll zoom"


func _on_fact_updated(_title: String, fact: String) -> void:
	fact_label.text = fact


func _on_nutrients_changed(amount: float, max_amount: float) -> void:
	_update_stats(amount, max_amount, GameState.colonization_percent)


func _on_colonization_changed(percent: float) -> void:
	_update_stats(GameState.nutrients, GameState.max_nutrients, percent)
	_update_colonization_bar(percent)


func _on_colonies_changed(_spawned: int, _mature: int) -> void:
	_update_stats(GameState.nutrients, GameState.max_nutrients, GameState.colonization_percent)


func _refresh_colonization_display() -> void:
	var show_bar := GameState.current_phase == LifeCycle.Phase.MYCELIUM_COLONIZATION
	colonization_bar.visible = show_bar
	_update_stats(GameState.nutrients, GameState.max_nutrients, GameState.colonization_percent)
	_update_colonization_bar(GameState.colonization_percent)


func _update_colonization_bar(percent: float) -> void:
	colonization_bar.value = percent
	if percent >= 80.0:
		colonization_bar.tooltip_text = "Colonization complete — environmental trigger next"
	elif percent >= 65.0:
		colonization_bar.tooltip_text = "Substrate colonization: %.1f%% — network maturing toward 80%%" % percent
	else:
		colonization_bar.tooltip_text = "Substrate colonization: %.1f%% (need 80%%)" % percent
	if GameState.current_phase == LifeCycle.Phase.MYCELIUM_COLONIZATION:
		if percent >= 65.0 and percent < 80.0:
			controls_hint.text = "Hyphal network spreading — hold SPACE near nutrients or wait for maturation"
		elif percent < 65.0:
			controls_hint.text = "Hold SPACE or toggle Grow button | Tips seek digestible nutrients | 80% to fruit"


func _update_stats(nutrients: float, max_nutrients: float, colonization: float) -> void:
	var phase := GameState.current_phase
	if phase == LifeCycle.Phase.SPORE_PRODUCTION or phase == LifeCycle.Phase.COMPLETE:
		stats_label.text = "Colonies: %d spawned | %d fruiting | Spores: %d" % [
			GameState.spawned_colonies,
			GameState.mature_colonies,
			GameState.spores_released,
		]
	else:
		stats_label.text = "Nutrients: %.0f/%.0f | Colonization: %.1f%%" % [
			nutrients, max_nutrients, colonization,
		]


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/species_select.tscn")
