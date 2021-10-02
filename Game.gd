extends Spatial

const DEBUGGING := true

onready var gauge := find_node("HeatGauge") as HeatGauge
onready var pot := find_node("Pot") as Pot
onready var progress_circle := find_node("ProgressCircle") as ProgressCircle
onready var anim_player := find_node("MainAnimationPlayer") as AnimationPlayer
onready var upgrade_container := find_node("UpgradeContainer") as GridContainer
onready var tooltip := find_node("Tooltip") as Tooltip
onready var lbl_coins := find_node("LblCoins") as Label
onready var msg_pause := find_node("PauseMsg") as Container
onready var label_spawner := find_node("LabelSpawner") as LabelSpawner

export(String, FILE) var upgrade_dir := "res://Upgrades"

var upgrades := []

var time_in_range := 0.0
var time_in_danger := 0.0
var in_range := false
var in_danger := false

var potion_duration := 4.0
var time_bubbles := 2.0
var buildup_speed := 0.5
var buildup_explosion := 2.0


func _ready():
	pot.emit_fire = true
	pot.emit_bubbles = false
	self.load_upgrades()
	Stats.connect("coins_changed", self, "update_coins_label")
	yield(get_tree(), "idle_frame")
	Stats.load_stats()
	# Start paused
	self._on_btnPause_toggled(true)


func _process(delta):
	if self.in_range:
		time_in_range += delta * Stats.time_speedup
		if time_in_range >= time_bubbles:
			pot.emit_bubbles = true

	progress_circle.progress = time_in_range / potion_duration
	if time_in_range >= potion_duration:
		self.brew_potion()

	if self.in_danger:
		time_in_danger += delta

	if self.in_range:
		gauge.range_color = Color.green
	elif self.in_danger:
		gauge.range_color = Color.red
	else:
		gauge.range_color = Color.white

	if self.in_danger:
		pot.set_buildup_strength(pot.buildup_strength + delta * buildup_speed)
		if pot.buildup_strength > buildup_explosion:
			self.anim_player.play("gameover")
	elif pot.buildup_strength > 0.0:
		if pot.buildup_strength < 0.1:
			pot.set_buildup_strength(0)
		else:
			pot.set_buildup_strength(lerp(pot.buildup_strength, 0, delta))


func load_upgrades() -> void:
	var dir := Directory.new()
	var err := dir.open(self.upgrade_dir)
	if err:
		print("Could not open upgrades folder! Error number: %d" % err)
		return
	err = dir.list_dir_begin(true, true)
	if err:
		print("Could not list upgrades! Error number: %d" % err)
		return

	print("Loading upgrades...")

	var file = dir.get_next()
	while file != "":
		if file.begins_with("u_"):
			print("Found upgrade %s" % file)
			var upgrade = load("%s/%s" % [self.upgrade_dir, file]) as Upgrade
			if upgrade != null && (DEBUGGING || !upgrade.identifier.starts_with('dbg_')):
				self.upgrades.append(upgrade)
			else:
				print("Could not load upgrade %s, got null!" % file)
		file = dir.get_next()
	self.upgrades.sort_custom(self, "sort_upgrades")
	for child in self.upgrade_container.get_children():
		self.upgrade_container.remove_child(child)
	for upgrade in self.upgrades:
		var button := preload("res://Upgrades/UpgradeButton.tscn").instance(PackedScene.GEN_EDIT_STATE_INSTANCE) as UpgradeButton
		button.upgrade = upgrade
		upgrade.purchased = false
		button.connect("upgrade_bought", self, "apply_upgrade")
		button.connect("upgrade_hover", self.tooltip, "show_tooltip")
		button.connect("upgrade_hover_exited", self.tooltip, "hide_tooltip")
		self.upgrade_container.add_child(button)


func sort_upgrades(upgrade1: Upgrade, upgrade2: Upgrade) -> bool:
	if upgrade2 == null:
		return true
	return upgrade1.order < upgrade2.order || (upgrade1.order == upgrade2.order && upgrade1.cost < upgrade2.cost)


func _on_HeatGauge_stir_in_range():
	self.in_range = true


func _on_HeatGauge_stir_out_of_range():
	self.in_range = false
	time_in_range = 0
	pot.emit_bubbles = false


func _on_HeatGauge_stir_in_danger():
	self.in_danger = true


func _on_HeatGauge_stir_out_of_danger():
	self.in_danger = false
	time_in_danger = 0


func _on_btnPause_toggled(button_pressed):
	get_tree().paused = button_pressed
	msg_pause.visible = button_pressed


func update_coins_label(coins: int) -> void:
	if lbl_coins:
		lbl_coins.text = "%d" % coins


func brew_potion() -> void:
	self.gauge.new_flame()
	self.time_in_range = 0.0
	self.label_spawner.spawn_label("+%d" % Stats.potions_per_batch)
	Stats.coins += Stats.potions_per_batch * Stats.coins_per_potion
	Stats.potions_brewed += Stats.potions_per_batch


func apply_upgrade(upgrade: Upgrade):
	if upgrade.custom_effect:
		match upgrade.identifier:
			"stabiliser_1":
				self.gauge.stir_decay *= 0.8
			"stabiliser_2":
				self.gauge.stir_decay *= 0.8
			_:
				print("Unhandled upgrade identifier: %s" % upgrade.identifier)
	else:
		var stat = Stats.get(upgrade.stat)
		Stats.set(upgrade.stat, stat * upgrade.stat_multiplier + upgrade.stat_addition)


func _on_btnSave_pressed():
	Stats.save_stats()


func reset():
	self.upgrades = []
	self.load_upgrades()
	self.anim_player.play("RESET")
	self.get_tree().call_group("Resetable", "reset")


func _on_BtnRestart_pressed():
	self.reset()


func _on_BtnReload_pressed():
	self.reset()
	yield(get_tree(), "idle_frame")
	Stats.load_stats()


func _on_SaveTimer_timeout():
	Stats.save_stats()


func pause(pause: bool = true):
	get_tree().set_pause(pause)
