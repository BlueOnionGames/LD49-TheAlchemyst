extends Panel

var menu := preload("res://Menu/MainMenu.tscn")


func _ready():
	$AnimationPlayer.play("appear")


func gotoMenu():
	get_tree().change_scene_to(self.menu)
