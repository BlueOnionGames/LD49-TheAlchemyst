extends StaticBody
class_name Pot

var is_hovered := false
var buildup_strength: float setget set_buildup_strength

export(Color) var bubble_color := Color(0.3, 0.5, 0.75, 0.35) setget set_bubble_color
export(Color) var liquid_color := Color(0.3, 0.5, 0.75, 0.5) setget set_liquid_color
export(Color) var overheat_color := Color(0.54, 0, 0)

export(bool) var emit_bubbles := false setget set_bubbles
export(bool) var emit_fire := true setget set_fire
export(bool) var liquid_light := false setget set_liquid_light

onready var msh_pot := find_node("Pot") as MeshInstance
onready var msh_border := find_node("Border") as MeshInstance
onready var anim_spoon := find_node("AnimSpoon") as AnimationPlayer
onready var anim_pot := find_node("AnimPot") as AnimationPlayer
onready var pot_light := find_node("PotLight") as OmniLight
onready var fire_light := find_node("FireLight") as OmniLight
onready var liquid := find_node("Liquid") as CSGMesh
onready var liquid_particles := find_node("LiquidParticles") as CPUParticles
onready var fire_particles := find_node("FireParticles") as CPUParticles

onready var liquid_audio1 := find_node("LiquidAudio1") as AudioStreamPlayer3D
onready var liquid_audio2 := find_node("LiquidAudio2") as AudioStreamPlayer3D
onready var bubbles_timer := find_node("BubblesTimer") as Timer

var bubble_sounds := [
	preload("res://Pot/bubble1.mp3"),
	preload("res://Pot/bubble2.mp3"),
	preload("res://Pot/bubble3.mp3"),
	preload("res://Pot/bubble4.mp3"),
	preload("res://Pot/bubble5.mp3"),
]

var _pot_default: Color
var _border_default: Color
var _bubble_audio_index := 0

signal stirred


func _ready() -> void:
	self.connect("mouse_entered", Input, "set_default_cursor_shape", [Input.CURSOR_POINTING_HAND])
	self.connect("mouse_exited", Input, "set_default_cursor_shape", [Input.CURSOR_ARROW])
	self.connect("mouse_entered", self, "set_hovered", [true])
	self.connect("mouse_exited", self, "set_hovered", [false])
	self.set_bubbles(self.emit_bubbles)
	self._pot_default = msh_pot.get_surface_material(0).albedo_color
	self._border_default = msh_border.get_surface_material(0).albedo_color


func _unhandled_input(event) -> void:
	if ((event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("game_stir")) and self.is_hovered:
		Stats.manual_stirs += 1
		self.stir()
		get_tree().set_input_as_handled()


func stir(only_spoon := false) -> void:
	anim_spoon.play("stir", -1, Stats.stir_speed)
	if not only_spoon:
		anim_pot.play("hiteffect")
	self.emit_signal("stirred")


func reset() -> void:
	self.is_hovered = false
	self.buildup_strength = 0
	self.emit_bubbles = false
	self.emit_fire = true
	self.liquid_light = false
	self.anim_pot.play("RESET")
	self.anim_spoon.play("RESET")


func set_hovered(hovered: bool) -> void:
	self.is_hovered = hovered


func set_buildup_strength(strength: float) -> void:
	buildup_strength = strength
	if buildup_strength > 0.001:
		anim_pot.play("buildup", -1, buildup_strength)
		var pot_color = self._pot_default.linear_interpolate(overheat_color, buildup_strength)
		msh_pot.get_surface_material(0).albedo_color = pot_color
		var border_color = self._border_default.linear_interpolate(overheat_color, buildup_strength)
		msh_border.get_surface_material(0).albedo_color = border_color
	else:
		buildup_strength = 0.0
		msh_pot.get_surface_material(0).albedo_color = self._pot_default
		msh_border.get_surface_material(0).albedo_color = self._border_default


func stop_buildup() -> void:
	anim_pot.stop()


func set_bubbles(bubbles: bool) -> void:
	emit_bubbles = bubbles
	if liquid_audio1 && liquid_audio2 && liquid_audio1.playing != bubbles:
		liquid_audio1.playing = bubbles
		liquid_audio2.playing = bubbles
#	self.set_random_bubble_sound()
	if bubbles_timer:
		if bubbles && bubbles_timer.is_stopped():
			bubbles_timer.start()
		else:
			bubbles_timer.stop()
	if liquid_particles:
		liquid_particles.emitting = emit_bubbles


func set_fire(fire: bool) -> void:
	if fire_particles == null: return
	emit_fire = fire
	fire_particles.emitting = emit_fire
	fire_light.visible = emit_fire


func set_bubble_color(color: Color) -> void:
	var mat := liquid_particles.mesh.surface_get_material(0) as SpatialMaterial
	bubble_color = color
	mat.albedo_color = bubble_color


func set_liquid_color(color: Color) -> void:
	if liquid == null: return
	var mat := liquid.mesh.surface_get_material(0) as SpatialMaterial
	liquid_color = color
	mat.albedo_color = liquid_color
	pot_light.light_color = liquid_color


func set_liquid_light(light: bool) -> void:
	liquid_light = light
	if pot_light:
		pot_light.visible = liquid_light


func set_random_bubble_sound():
	if liquid_audio1 != null && liquid_audio2:
		var was_playing := liquid_audio1.playing
		var size := bubble_sounds.size()
		_bubble_audio_index = (_bubble_audio_index + 1) % 2
		match _bubble_audio_index:
			0:
				liquid_audio1.stream = bubble_sounds[floor(size * randf())]
				liquid_audio1.playing = was_playing
			1:
				liquid_audio2.stream = bubble_sounds[floor(size * randf())]
				liquid_audio2.playing = was_playing
