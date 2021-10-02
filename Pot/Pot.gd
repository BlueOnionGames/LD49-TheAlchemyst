extends StaticBody
class_name Pot

var is_hovered := false
var buildup_strength: float setget set_buildup_strength

export(Color) var bubble_color := Color(0.3, 0.5, 0.75, 0.35) setget set_bubble_color
export(Color) var liquid_color := Color(0.3, 0.5, 0.75, 0.5) setget set_liquid_color
export(Color) var overheat_color := Color(0.54, 0, 0)

export(bool) var emit_bubbles := false setget set_bubbles
export(bool) var emit_fire := false setget set_fire
export(bool) var liquid_light := false setget set_liquid_light

onready var msh_pot := find_node("Pot") as MeshInstance
onready var msh_border := find_node("Border") as MeshInstance
onready var anim_spoon := find_node("AnimSpoon") as AnimationPlayer
onready var anim_pot := find_node("AnimPot") as AnimationPlayer
onready var pot_light := find_node("PotLight") as OmniLight
onready var liquid := find_node("Liquid") as CSGMesh
onready var liquid_particles := find_node("LiquidParticles") as CPUParticles
onready var fire_particles := find_node("FireParticles") as CPUParticles

var _pot_default: Color
var _border_default: Color

signal stirred


func _ready() -> void:
	self.connect("mouse_entered", Input, "set_default_cursor_shape", [Input.CURSOR_POINTING_HAND])
	self.connect("mouse_exited", Input, "set_default_cursor_shape", [Input.CURSOR_ARROW])
	self.connect("mouse_entered", self, "set_hovered", [true])
	self.connect("mouse_exited", self, "set_hovered", [false])
	self.set_bubbles(self.emit_bubbles)
	self._pot_default = msh_pot.get_surface_material(0).albedo_color
	self._border_default = msh_border.get_surface_material(0).albedo_color


func set_hovered(hovered: bool) -> void:
	self.is_hovered = hovered


func _unhandled_input(event) -> void:
	if event.is_action_pressed("game_stir") and self.is_hovered:
		anim_spoon.play("Stir")
		anim_pot.play("hiteffect")
		self.emit_signal("stirred")


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

