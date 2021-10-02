extends Node
class_name StatsClass

signal coins_changed
signal load_start
signal load_done
signal save_start
signal save_done

var save_file := "user://game1.sav"

var coins := 0 setget set_coins
var stir_decay := 0.3  # per second
var potions_brewed := 0
var potions_per_batch := 1
var coins_per_potion := 1.0

var _initial_attributes: Dictionary

func _ready():
	self._initial_attributes = self.get_attributes()
	self.add_to_group("Resetable", true)
	self.set_coins(self.coins) # Trigger the signal


func reset() -> void:
	for key in self._initial_attributes:
		self.set(key, self._initial_attributes[key])


func set_coins(cns: int) -> void:
	if cns != coins:
		coins = cns
		self.emit_signal("coins_changed", coins)

func get_attributes() -> Dictionary:
	return {
		"coins": self.coins,
		"stir_decay": self.stir_decay,
		"potions_brewed": self.potions_brewed,
		"potions_per_batch": self.potions_per_batch,
		"coins_per_potion": self.coins_per_potion,
	}


func save_stats() -> void:
	self.emit_signal("save_start")
	var file = File.new()
	file.open(self.save_file, File.WRITE)
	file.store_line(to_json(self.get_attributes()))
	file.close()
	self.emit_signal("save_done")


func load_stats() -> void:
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
