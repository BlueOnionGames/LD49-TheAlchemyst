extends Spatial

const DEBUGGING := true

onready var gauge := find_node("HeatGauge") as HeatGauge
onready var pot := find_node("Pot") as Pot
onready var progress_circle := find_node("ProgressCircle") as ProgressCircle
onready var anim_player := find_node("MainAnimationPlayer") as AnimationPlayer
onready var upgrade_container := find_node("UpgradeContainer") as GridContainer
onready var tooltip := find_node("Tooltip")
onready var lbl_coins := find_node("LblCoins") as Label
onready var msg_pause := find_node("PauseMsg") as Container
onready var label_spawner := find_node("LabelSpawner") as LabelSpawner
onready var brew_timer := find_node("AutoBrewTimer") as Timer
onready var brew_checkbox := find_node("AutoBrewCheckBox") as CheckBox
onready var brew_interval_lbl := find_node("AutoBrewIntervalLabel") as Label
onready var brew_container := find_node("AutoBrewContainer") as Container
onready var stats_label := find_node("StatsLabel") as RichTextLabel

export(String, FILE) var upgrade_dir := "res://Upgrades"

var upgrades := []

var time_in_range := 0.0
var time_in_danger := 0.0
var in_range := false
var in_danger := false


func _ready():
	pot.emit_fire = true
	pot.emit_bubbles = false
	self.brew_container.visible = false
	self.load_upgrades()
	Stats.connect("coins_changed", self, "update_coins_label")
	yield(get_tree(), "idle_frame")
	Stats.load_stats()
	# Start paused
	self.pause()

	if not DEBUGGING:
		$CanvasLayer/btnSave.visible = false
		$CanvasLayer/btnReset.visible = false


func _process(delta):
	Stats.playtime += delta
	if self.stats_label != null:
		self.stats_label.text = ""
		for attribute in Stats._initial_attributes:
			self.stats_label.text = "%s %s: %s\n" % [self.stats_label.text, attribute, Stats.get(attribute)]
	if get_tree().paused: return

	if self.in_range:
		time_in_range += delta * Stats.time_speedup
		if time_in_range >= Stats.time_till_bubbles:
			pot.emit_bubbles = true

	progress_circle.progress = time_in_range / Stats.time_till_potion
	if time_in_range >= Stats.time_till_potion:
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
		pot.set_buildup_strength(pot.buildup_strength + delta * Stats.buildup_speed)
		if pot.buildup_strength > Stats.explosion_trigger:
			self.anim_player.play("gameover")
	elif pot.buildup_strength > 0.0:
		if pot.buildup_strength < 0.1:
			pot.set_buildup_strength(0)
		else:
			pot.set_buildup_strength(lerp(pot.buildup_strength, 0, delta))


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		self.pause(not get_tree().paused)
		get_tree().set_input_as_handled()


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
			if upgrade != null && (DEBUGGING || !upgrade.identifier.begins_with('dbg_')):
				self.upgrades.append(upgrade)
			else:
				print("Could not load upgrade %s, got null!" % file)
		file = dir.get_next()
	self.upgrades.sort_custom(self, "sort_upgrades")
	for child in self.upgrade_container.get_children():
		self.upgrade_container.remove_child(child)
	for upgrade in self.upgrades:
		var button := preload("res://Upgrades/UpgradeButton.tscn").instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
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


func update_coins_label(coins: int) -> void:
	if lbl_coins:
		lbl_coins.text = "%d" % coins


func brew_potion() -> void:
	self.gauge.new_flame()
	self.time_in_range = 0.0
	self.label_spawner.spawn_label("+%d x %d" % [Stats.potions_per_batch, Stats.coins_per_potion])
	Stats.coins += Stats.potions_per_batch * Stats.coins_per_potion
	Stats.potions_brewed += Stats.potions_per_batch


func apply_upgrade(upgrade: Upgrade):
	if upgrade.custom_effect:
		match upgrade.identifier:
			"dbg_spawn_label":
				self.label_spawner.spawn_label("Test")
			"auto_brewer":
				self.brew_container.visible = true
				Stats.connect("autobrew_interval_changed", self.brew_timer, "set_wait_time")
				Stats.connect("autobrew_interval_changed", self, "set_autobrew_interval_label")
				Stats.connect("autobrew_enabled_changed", self, "set_autobrew_timer")
				self.brew_timer.wait_time = Stats.autobrew_interval
			_:
				print("Unhandled upgrade identifier: %s" % upgrade.identifier)
	for effect in upgrade.effects:
		var seff := effect as StatEffect
		if seff == null:
			print("Invalid stat effect found in upgrade %s!" % upgrade.name)
			continue
		var stat = Stats.get(seff.name)
		Stats.set(seff.name, stat * seff.multiplier + seff.addition)


func _on_btnSave_pressed():
	Stats.save_stats()


func reset():
	self.pause(true, true)
	self.upgrades = []
	self.load_upgrades()
	self.anim_player.play("RESET")
	self.get_tree().call_group("Resetable", "reset")


func _on_BtnRestart_pressed():
	self.reset()


func _on_BtnReload_pressed():
	self.reset()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	Stats.load_stats()
	self.pause(true, true)


func _on_SaveTimer_timeout():
	Stats.save_stats()


func pause(pause: bool = true, show_message := true):
	get_tree().set_pause(pause)
	if show_message || not pause:
		msg_pause.visible = pause


func set_autobrew_timer(enabled: bool) -> void:
	self.brew_checkbox.pressed = enabled
	if enabled:
		self.brew_timer.start()
	else:
		self.brew_timer.stop()


func set_autobrew_interval_label(interval: float) -> void:
	self.brew_interval_lbl.text = "%.1f" % interval


func _on_AutobrewerLabel_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Stats.autobrew_enabled = !Stats.autobrew_enabled


func _on_AutobrewerCheckBox_toggled(button_pressed) -> void:
	Stats.autobrew_enabled = button_pressed


func _on_BtnAutoBrewIntervalMinus_pressed():
	Stats.autobrew_interval = max(0.1, Stats.autobrew_interval - 0.1)


func _on_BtnAutoBrewIntervalPlus_pressed():
	Stats.autobrew_interval = min(10, Stats.autobrew_interval + 0.1)
