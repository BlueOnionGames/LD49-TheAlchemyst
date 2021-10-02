extends Panel
class_name Tooltip

const MOUSE_OFFSET := Vector2(15, 0)

onready var lbl_name := find_node("LblName") as Label
onready var lbl_price := find_node("LblPrice") as Label
onready var lbl_description := find_node("LblDescription") as Label
onready var tex_coin := find_node("TexCoin") as TextureRect

const TEX_BOUGHT := preload("res://check.png")
const TEX_COIN := preload("res://coin.png")

export(Color) var col_too_expensive := Color(0.56, 0.13, 0.13)
var _default_color: Color


func _ready() -> void:
	self._default_color = lbl_price.get_color("font_color")
	self.visible = false
	self.set_process(false)


func _process(_delta: float) -> void:
	self.rect_global_position = self.get_global_mouse_position() + MOUSE_OFFSET


func show_tooltip(upgrade: Upgrade) -> void:
	if upgrade == null:
		self.hide_tooltip(upgrade)
	else:
		lbl_name.text = upgrade.name
		if upgrade.purchased:
			tex_coin.texture = TEX_BOUGHT
			lbl_price.text = "Bought"
			lbl_price.add_color_override("font_color", self._default_color)
		else:
			tex_coin.texture = TEX_COIN
			lbl_price.text = "%d" % upgrade.cost
			if upgrade.cost > Stats.coins:
				lbl_price.add_color_override("font_color", self.col_too_expensive)
			else:
				lbl_price.add_color_override("font_color", self._default_color)
		lbl_description.text = upgrade.description
		self.visible = true
		self.set_process(true)


func hide_tooltip(_upgrade: Upgrade) -> void:
	self.visible = false
	self.set_process(false)
