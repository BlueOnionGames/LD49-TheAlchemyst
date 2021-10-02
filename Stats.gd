extends Node
class_name StatsClass

signal coins_changed
signal stir_range_changed
signal danger_range_changed
signal autobrew_interval_changed
signal autobrew_enabled_changed
signal load_start
signal load_done
signal save_start
signal save_done

var save_file := "user://game1.sav"

var coins := 0 setget set_coins
var stir_decay := 0.3  # per second
var stir_strength := 0.2
var stir_range := 0.20 setget set_stir_range
var stir_speed := 1.0
var danger_range := 0.1 setget set_danger_range
var potions_brewed := 0
var potions_per_batch := 1
var coins_per_potion := 1
var time_speedup := 1.0
var time_till_potion := 4.0
var time_till_bubbles := 2.0
var explosion_trigger := 2.0
var flame_randomness := 1.0
var buildup_speed := 0.5
var stability := 1.0
var autobrew_interval := 1.0 setget set_autobrew_interval
var autobrew_enabled := true setget set_autobrew_enabled

var _initial_attributes: Dictionary

func _ready():
	self._initial_attributes = self.get_attributes()
	self.add_to_group("Resetable", true)
	self.reset(true)


func reset(skip_attributes := false) -> void:
	if not skip_attributes:
		for key in self._initial_attributes:
			self.set(key, self._initial_attributes[key])

	# Trigger the signals
	yield(get_tree(), "idle_frame")
	self.emit_signal("coins_changed", self.coins)
	self.emit_signal("stir_range_changed", self.stir_range)
	self.emit_signal("danger_range_changed", self.danger_range)


func set_coins(cns: int) -> void:
	if cns != coins:
		coins = cns
		self.emit_signal("coins_changed", coins)


func set_stir_range(new_range: float) -> void:
	if !is_equal_approx(stir_range, new_range):
		stir_range = new_range
		self.emit_signal("stir_range_changed", stir_range)


func set_danger_range(new_range: float) -> void:
	if !is_equal_approx(danger_range, new_range):
		danger_range = new_range
		self.emit_signal("danger_range_changed", danger_range)


func set_autobrew_interval(interval: float) -> void:
	if !is_equal_approx(autobrew_interval, interval):
		autobrew_interval = interval
		self.emit_signal("autobrew_interval_changed", autobrew_interval)


func set_autobrew_enabled(enabled: bool) -> void:
	if autobrew_enabled != enabled:
		autobrew_enabled = enabled
		self.emit_signal("autobrew_enabled_changed", autobrew_enabled)


func get_attributes() -> Dictionary:
	return {
		"coins": self.coins,
		"stir_decay": self.stir_decay,
		"stir_strength": self.stir_strength,
		"stir_range": self.stir_range,
		"stir_speed": self.stir_speed,
		"danger_range": self.danger_range,
		"potions_brewed": self.potions_brewed,
		"potions_per_batch": self.potions_per_batch,
		"coins_per_potion": self.coins_per_potion,
		"time_speedup": self.time_speedup,
		"time_till_potion": self.time_till_potion,
		"time_till_bubbles": self.time_till_bubbles,
		"explosion_trigger": self.explosion_trigger,
		"flame_randomness": self.flame_randomness,
		"buildup_speed": self.buildup_speed,
		"stability": self.stability,
		"autobrew_interval": self.autobrew_interval,
		"autobrew_enabled": self.autobrew_enabled,
	}


func save_stats() -> void:
	print("Saving stats...")
	self.emit_signal("save_start")
	var file = File.new()
	file.open(self.save_file, File.WRITE)
	file.store_line(to_json(self.get_attributes()))
	file.close()
	self.emit_signal("save_done")


func load_stats() -> void:
	print("Loading stats...")
	self.emit_signal("load_start")
	get_tree().paused = true
	var file = File.new()
	if not file.file_exists(self.save_file):
		print("No save file found!")
		return
	file.open(self.save_file, File.READ)
	var data := parse_json(file.get_line()) as Dictionary
	for key in data:
		self.set(key, data[key])
	file.close()
	get_tree().paused = false
	self.emit_signal("load_done")
