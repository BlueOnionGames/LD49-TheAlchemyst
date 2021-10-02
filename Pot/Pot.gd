extends StaticBody
class_name Pot

var is_hovered := false

export(Color) var bubble_color := Color(0.3, 0.5, 0.75, 0.35) setget set_bubble_color
export(Color) var liquid_color := Color(0.3, 0.5, 0.75, 0.5) setget set_liquid_color

export(bool) var emit_bubbles := false setget set_bubbles
export(bool) var emit_fire := false setget set_fire
export(bool) var liquid_light := false setget set_liquid_light

onready var anim_spoon := find_node("AnimSpoon") as AnimationPlayer
onready var anim_pot := find_node("AnimPot") as AnimationPlayer
onready var pot_light := find_node("PotLight") as OmniLight
onready var liquid := find_node("Liquid") as CSGMesh
onready var liquid_particles := find_node("LiquidParticles") as CPUParticles
onready var fire_particles := find_node("FireParticles") as CPUParticles

signal stirred


func _ready() -> void:
	self.connect("mouse_entered", Input, "set_default_cursor_shape", [Input.CURSOR_POINTING_HAND])
	self.connect("mouse_exited", Input, "set_default_cursor_shape", [Input.CURSOR_ARROW])
	self.connect("mouse_entered", self, "set_hovered", [true])
	self.connect("mouse_exited", self, "set_hovered", [false])
	self.set_bubbles(self.emit_bubbles)


func set_hovered(hovered: bool) -> void:
	self.is_hovered = hovered


func _unhandled_input(event) -> void:
	if event.is_action_pressed("game_stir") and self.is_hovered:
		anim_spoon.play("Stir")
		anim_pot.play("hiteffect")
		self.emit_signal("stirred")


func set_bubbles(bubbles: bool) -> void:
	emit_bubbles = bubbles
	liquid_particles.emitting = emit_bubbles


func set_fire(fire: bool) -> void:
	if fire_particles == null: return
	emit_fire = fire
	fire_particles.emitting = emit_fire


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
	pot_light.visible = liquid_light

