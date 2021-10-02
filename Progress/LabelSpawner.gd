extends Control
class_name LabelSpawner

func spawn_label(text: String) -> void:
	var label := preload("res://Progress/FloatingLabel.tscn").instance() as Label
	label.text = text
	self.add_child(label)
