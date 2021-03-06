extends Control

const game_scene := preload("res://Hut/Game.tscn")

onready var btn_continue := find_node("Continue") as Button


func _ready() -> void:
	btn_continue.disabled = not Stats.has_save_file()
	Stats.is_in_tutorial = btn_continue.disabled
	btn_continue.mouse_filter = Control.MOUSE_FILTER_IGNORE if not Stats.has_save_file() else Control.MOUSE_FILTER_STOP

	# 1: SFX
	AudioServer.set_bus_volume_db(1, -15)


func openUrl(url: String) -> void:
	OS.shell_open(url)


func _on_Itch_pressed():
	self.openUrl("https://zedutch.itch.io/")


func _on_Twitter_pressed():
	self.openUrl("https://twitter.com/zedutch_")


func _on_Twitch_pressed():
	self.openUrl("https://www.twitch.tv/zedutch_")


func _on_Quit_pressed():
	get_tree().quit(0)


func _on_New_Game_pressed():
	Stats.reset()
	get_tree().change_scene_to(game_scene)


func _on_Continue_pressed():
	Stats.load_stats()
	yield(get_tree(), "idle_frame")
	get_tree().change_scene_to(game_scene)

