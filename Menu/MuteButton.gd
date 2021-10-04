extends Container

signal muted
signal unmuted
signal mute_toggled


export var button_size := Vector2(48, 48) setget set_button_size
export(int, 0) var audio_bus := 0


func _ready():
	self.update_interface()


func set_button_size(new_size: Vector2) -> void:
	button_size = new_size
	rect_min_size = button_size
	$TextureButton.rect_min_size = button_size
	$TextureRect.rect_min_size = button_size
	$TextureRect2.rect_min_size = button_size


func update_interface() -> void:
	var is_mute := AudioServer.is_bus_mute(self.audio_bus)
	$TextureButton.pressed = is_mute
	$TextureRect2.visible = is_mute
	$TextureRect.self_modulate.a = 0.5 if is_mute else 1.0

func _on_Button_toggled(button_pressed) -> void:
	AudioServer.set_bus_mute(audio_bus, button_pressed)
	self.update_interface()
	if button_pressed:
		self.emit_signal("muted")
	else:
		self.emit_signal("unmuted")
	self.emit_signal("mute_toggled", button_pressed)
