tool
extends Sprite
class_name ProgressCircle

export(Color) var background_color := Color(0.29, 0.29, 0.29) setget set_bg
export(Color) var foreground_color := Color(0.14, 0.36, 0.25) setget set_fg
export(float, 0.0, 1.0) var progress := 0.0 setget set_progress


func set_bg(color: Color) -> void:
	background_color = color
	self.material.set_shader_param("background_color", background_color)


func set_fg(color: Color) -> void:
	foreground_color = color
	self.material.set_shader_param("foreground_color", foreground_color)


func set_progress(prog: float) -> void:
	progress = prog
	self.material.set_shader_param("progress", progress)
