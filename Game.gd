extends Spatial

onready var gauge := find_node("HeatGauge") as HeatGauge
onready var pot := find_node("Pot") as Pot
onready var progress_circle := find_node("ProgressCircle") as ProgressCircle

var time_in_range := 0.0
var time_in_danger := 0.0
var in_range := false
var in_danger := false

var potion_duration := 1.0

func _process(delta):
	if self.in_range:
		time_in_range += delta
		if time_in_range > 2:
			pot.emit_bubbles = true

	progress_circle.progress = time_in_range / potion_duration
	if time_in_range >= potion_duration:
		gauge.new_flame()
		self.time_in_range = 0.0

	if self.in_danger:
		time_in_danger += delta

	if self.in_range:
		gauge.range_color = Color.green
	elif self.in_danger:
		gauge.range_color = Color.red
	else:
		gauge.range_color = Color.white


func _on_HeatGauge_stir_in_range():
	self.in_range = true
	pot.emit_fire = true


func _on_HeatGauge_stir_out_of_range():
	self.in_range = false
	time_in_range = 0
	pot.emit_fire = false
	pot.emit_bubbles = false


func _on_HeatGauge_stir_in_danger():
	self.in_danger = true


func _on_HeatGauge_stir_out_of_danger():
	self.in_danger = false
	time_in_danger = 0
