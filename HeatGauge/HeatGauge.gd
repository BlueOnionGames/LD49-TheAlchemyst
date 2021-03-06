extends Node2D
class_name HeatGauge

onready var spr_bar  := find_node("Bar") as Sprite
onready var ar_flame := find_node("Flame") as Area2D
onready var ar_range := find_node("Range") as Area2D
onready var ar_danger := find_node("Danger") as Area2D
onready var rect_danger := find_node("DangerRect") as ColorRect

var spr_range: Sprite
var shape_range: CollisionShape2D
var shape_danger: CollisionShape2D

var bar_height := 0

export(float, 0.0, 1.0) var flame_strength := 0.7 setget set_flame
export(float, 0.0, 1.0) var stir_level := 1.0 setget set_stir_level

export(Color) var bar_color := Color.white setget set_bar
export(Color) var range_color := Color.white setget set_range

var was_in_range := false
var was_in_danger := false

signal stir_in_range
signal stir_out_of_range

signal stir_in_danger
signal stir_out_of_danger


func _ready() -> void:
	self.bar_height = spr_bar.texture.get_height()
	self.reset()
	Stats.connect("stir_range_changed", self, "set_stir_range")
	Stats.connect("danger_range_changed", self, "set_danger_range")


func _process(delta: float) -> void:
	self.stir_level -= Stats.stir_decay * delta

	var in_range := self.in_range()
	if in_range != self.was_in_range:
		if self.was_in_range: # Was in range -> now not anymore
			self.emit_signal("stir_out_of_range")
		else: # Was out of range -> now in range
			self.emit_signal("stir_in_range")
		self.was_in_range = in_range

	var in_danger := self.in_danger()
	if in_danger != self.was_in_danger:
		if self.was_in_danger: # Was in danger -> now not anymore
			self.emit_signal("stir_out_of_danger")
		else: # Was out of danger -> now in danger
			self.emit_signal("stir_in_danger")
		self.was_in_danger = in_danger


func reset() -> void:
	self.set_stir_level(1.0)

	spr_range = ar_range.find_node("Sprite")
	shape_range = ar_range.find_node("CollisionShape2D")
	shape_danger = ar_danger.find_node("CollisionShape2D")

	self.bar_color = Color.white
	self.range_color = Color.white

	self.new_flame()

	self.was_in_range = self.in_range()
	self.was_in_danger = self.in_danger()


func new_flame() -> void:
	var prev_flame := self.flame_strength
	var min_rand = -1.0
	var max_rand = 1.0
	# Prevent the flame from getting stuck near the edges
	if prev_flame > 0.9:
		max_rand = 0.1
	elif prev_flame < Stats.danger_range * 3.0:
		min_rand = 0.1
	var randomness := rand_range(min_rand, max_rand) * Stats.flame_randomness
	var new_flame := prev_flame + randomness
	self.set_flame(max(new_flame, Stats.danger_range + Stats.stir_strength))


func set_flame(flame: float) -> void:
	flame_strength = clamp(flame, 0.0, 1.0)
	ar_flame.position.y = -bar_height * flame_strength


func set_stir_level(level: float) -> void:
	stir_level = clamp(level, 0.0, 1.0)
	ar_range.position.y = -bar_height * stir_level


func set_danger_range(danger_range: float) -> void:
	var shape := shape_danger.shape as RectangleShape2D
	shape.extents.y = bar_height * danger_range / 2.0
	shape_danger.position.y = -shape.extents.y
	rect_danger.margin_top = -shape.extents.y * 2.0


func set_stir_range(stir_range: float) -> void:
	var shape := shape_range.shape as RectangleShape2D
	shape.extents.y = bar_height * stir_range / 2.0
	spr_range.scale.y = stir_range / (spr_range.texture.get_height() / (bar_height*1.0))


func stir() -> void:
	self.stir_level += Stats.stir_strength


func in_range() -> bool:
	return ar_flame.overlaps_area(ar_range)


func in_danger() -> bool:
	return ar_danger.overlaps_area(ar_range)


func set_bar(color: Color) -> void:
	bar_color = color
	spr_bar.self_modulate = bar_color


func set_range(color: Color) -> void:
	range_color = color
	spr_range.self_modulate = range_color
