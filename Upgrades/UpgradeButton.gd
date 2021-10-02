extends Control
class_name UpgradeButton

export var upgrade_res: Resource setget set_upgrade
var upgrade: Upgrade

onready var icon := find_node("TextureRect") as TextureRect
onready var button := find_node("TextureButton") as TextureButton
onready var bought_check := find_node("TexBought") as TextureRect
onready var button_container := find_node("ButtonContainer") as Container

signal upgrade_hover
signal upgrade_hover_exited
signal upgrade_bought

func _ready() -> void:
	Stats.connect("coins_changed", self, "check_purchasable")
	self.visible = false
	self.bought_check.visible = false

func set_upgrade(upgr: Resource) -> void:
	if upgr is Upgrade:
		upgrade_res = upgr
		upgrade = upgrade_res as Upgrade
		if upgrade.texture != null:
			self.icon.texture = upgrade.texture
		if upgrade.purchased:
			self.disable()
			self.bought_check.visible = true
		else:
			self.check_purchasable(Stats.coins)

	else:
		print("ONLY UPGRADES ALLOWED! >:(")


func disable() -> void:
	button.disabled = true
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	self.button_container.modulate.a = 0.4


func enable() -> void:
	button.disabled = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	self.button_container.modulate.a = 1.0


func check_purchasable(coins: int) -> void:
	if self.upgrade == null: return
	elif self.upgrade.purchased: return

	if coins + 3 >= self.upgrade.cost / 2.0: # +3 so the first upgrade is always visible
		self.visible = true

	if coins >= self.upgrade.cost:
		self.enable()
	else:
		self.disable()
		self.button_container.modulate.a = 0.6


func _on_Button_pressed() -> void:
	Stats.coins -= upgrade.cost
	upgrade.purchased = true
	if upgrade.single_purchase:
		self.disable()
		self.bought_check.visible = true
	else:
		self.check_purchasable(Stats.coins)
	self.emit_signal("upgrade_bought", self.upgrade)


func _on_Button_mouse_entered() -> void:
	self.emit_signal("upgrade_hover", self.upgrade)


func _on_Button_mouse_exited() -> void:
	self.emit_signal("upgrade_hover_exited", self.upgrade)
