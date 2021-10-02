extends Control
class_name LabelSpawner

func spawn_label(text: String) -> void:
	var label := preload("res://Progress/FloatingLabel.tscn").instance() as Label
	label.text = text
	var x := rand_range(-2.0, 2.0)
	var y := rand_range(-2.0, 2.0)
	label.rect_global_position += Vector2(x, y)
	self.add_child(label)
