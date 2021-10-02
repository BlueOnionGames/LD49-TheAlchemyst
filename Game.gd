extends Spatial

onready var gauge := find_node("HeatGauge") as HeatGauge
onready var pot := find_node("Pot") as Pot
onready var progress_circle := find_node("ProgressCircle") as ProgressCircle
onready var anim_player := find_node("AnimationPlayer") as AnimationPlayer

var time_in_range := 0.0
var time_in_danger := 0.0
var in_range := false
var in_danger := false

var potion_duration := 4.0
var time_bubbles := 2.0
var buildup_speed := 0.5
var buildup_explosion := 2.0

func _ready():
	pot.emit_fire = true
	pot.emit_bubbles = false

func _process(delta):
	if self.in_range:
		time_in_range += delta
		if time_in_range >= time_bubbles:
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

	if self.in_danger:
		pot.set_buildup_strength(time_in_danger * buildup_speed)
		if pot.buildup_strength > buildup_explosion:
			self.anim_player.play("gameover")
	elif pot.buildup_strength > 0.0:
		pot.set_buildup_strength(lerp(pot.buildup_strength, 0, delta))


func _on_HeatGauge_stir_in_range():
	self.in_range = true


func _on_HeatGauge_stir_out_of_range():
	self.in_range = false
	time_in_range = 0
	pot.emit_bubbles = false


func _on_HeatGauge_stir_in_danger():
	self.in_danger = true


func _on_HeatGauge_stir_out_of_danger():
	self.in_danger = false
	time_in_danger = 0
