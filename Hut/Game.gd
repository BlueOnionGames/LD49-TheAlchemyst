extends Spatial

const DEBUGGING := false

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
onready var pause_button := find_node("PauseButton") as Button

onready var light1 := find_node("MainSceneLight1") as OmniLight
onready var light2 := find_node("MainSceneLight2") as OmniLight

export(String, FILE) var upgrade_dir := "res://Upgrades"

var upgrades := []

var time_in_range := 0.0
var time_in_danger := 0.0
var in_range := false
var in_danger := false

var _liquid_default: Color
var _light_default: Color

export(Color) var color_default := Color(0.66, 0.66, 0.66)
export(Color) var color_danger := Color(0.44, 0.15, 0.15)
export(Color) var color_range := Color(0.14, 0.36, 0.25)
export(Color) var liquid_hell_color := Color(0.44, 0, 0, 0.3)
export(Color) var light_2_hell_color := Color(0.14, 0.36, 0.25)


signal any_upgrade_bought
signal potion_brewed


func _ready():
	pot.emit_fire = true
	pot.emit_bubbles = false
	self.brew_container.visible = false
	self._liquid_default = pot.liquid_color
	self._light_default = light1.light_color
	self.load_upgrades()
	Stats.connect("coins_changed", self, "update_coins_label")
	Stats.connect("stability_changed", self, "update_stability")
	Stats.reset(true)

	if Stats.is_in_tutorial:
		self.pause(true, false)
		anim_player.play("tutorial1")
	else:
		# Start paused
		self.pause()

	# 1: SFX
	AudioServer.set_bus_volume_db(1, 0)

	if not DEBUGGING:
		$CanvasLayer/btnSave.visible = false
		$CanvasLayer/btnReset.visible = false


func _process(delta):
	Stats.playtime += delta
	if self.stats_label != null:
		self.stats_label.text = ""
		for attribute in Stats._initial_attributes:
			if attribute in ['autobrew_enabled', 'autobrew_interval', 'buildup_speed', 'time_till_bubbles', 'time_speedup']: continue
			elif attribute in ['playtime']:
				self.stats_label.text = "%s %s: %.1f\n" % [self.stats_label.text, attribute, Stats.get(attribute)]
			else:
				self.stats_label.text = "%s %s: %s\n" % [self.stats_label.text, attribute.replace('_', ' '), Stats.get(attribute)]
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
		gauge.range_color = color_range
	elif self.in_danger:
		gauge.range_color = color_danger
	else:
		gauge.range_color = color_default

	if self.in_danger:
		pot.set_buildup_strength(pot.buildup_strength + delta * Stats.buildup_speed)
		if pot.buildup_strength > Stats.explosion_trigger:
			self.anim_player.play("gameover")
	elif pot.buildup_strength > 0.0:
		if pot.buildup_strength < 0.1:
			pot.set_buildup_strength(0)
		else:
			pot.set_buildup_strength(lerp(pot.buildup_strength, 0, delta))


func _unhandled_input(event) -> void:
	if Stats.is_in_tutorial: return
	if event.is_action_pressed("pause"):
		self.pause(not get_tree().paused)
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("back"):
		self.return_to_menu()
		get_tree().set_input_as_handled()


func update_stability(stability: float) -> void:
	if stability < 0.9:
		pot.liquid_color = lerp(self._liquid_default, self.liquid_hell_color, min(1.0, 0.9 - stability + 0.6))
		pot.bubble_color = pot.liquid_color
		light1.light_color = lerp(light1.light_color, pot.liquid_color, min(1.0, 0.9 - stability + 0.6))
		light2.light_color = lerp(light2.light_color, self.light_2_hell_color, min(1.0, 0.9 - stability + 0.6))
	pot.liquid_light = stability < 0.5


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
	var already_bought = Stats.bought_upgrades
	for upgrade in self.upgrades:
		var button := preload("res://Upgrades/UpgradeButton.tscn").instance()
		button.upgrade = upgrade
		upgrade.purchased = already_bought.has(upgrade.name)
		if upgrade.purchased:
			self.apply_upgrade(upgrade, false)
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
	emit_signal("potion_brewed")


func apply_upgrade(upgrade: Upgrade, apply_stats := true):
	if upgrade.custom_effect:
		match upgrade.identifier:
			"dbg_spawn_label":
				self.label_spawner.spawn_label("Test")
			"black_hole":
				$WorldDecomposeTimer.start()
			"auto_brewer":
				self.brew_container.visible = true
				Stats.connect("autobrew_interval_changed", self.brew_timer, "set_wait_time")
				Stats.connect("autobrew_interval_changed", self, "set_autobrew_interval_label")
				Stats.connect("autobrew_enabled_changed", self, "set_autobrew_timer")
				self.brew_timer.wait_time = Stats.autobrew_interval
				self.set_autobrew_timer(Stats.autobrew_enabled)
				self.set_autobrew_interval_label(Stats.autobrew_interval)
				Stats.autobrew_enabled = true
			_:
				print("Unhandled upgrade identifier: %s" % upgrade.identifier)
	if apply_stats:
		self.emit_signal("any_upgrade_bought")
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
	self.anim_player.pause_mode = Node.PAUSE_MODE_PROCESS
	self.anim_player.play("RESET")
	self.pot.liquid_color = self._liquid_default
	self.pot.bubble_color = self._liquid_default
	self.light1.light_color = self._light_default
	self.light2.light_color = self._light_default
	self.get_tree().call_group("Resetable", "reset")
	self.brew_timer.stop()
	$WorldDecomposeTimer.stop()
	yield(get_tree(), "idle_frame")
	self.upgrades = []
	self.load_upgrades()


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
	pause_button.visible = not pause


func set_autobrew_timer(enabled: bool) -> void:
	self.brew_checkbox.pressed = enabled
	if enabled:
		self.brew_timer.start()
	else:
		self.brew_timer.stop()


func set_autobrew_interval_label(interval: float) -> void:
	self.brew_interval_lbl.text = "%.1f sec" % interval


func _on_AutobrewerLabel_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Stats.autobrew_enabled = !Stats.autobrew_enabled


func _on_AutobrewerCheckBox_toggled(button_pressed) -> void:
	Stats.autobrew_enabled = button_pressed


func _on_BtnAutoBrewIntervalMinus_pressed():
	Stats.autobrew_interval = max(0.1, Stats.autobrew_interval - 0.1)


func _on_BtnAutoBrewIntervalPlus_pressed():
	Stats.autobrew_interval = min(10, Stats.autobrew_interval + 0.1)


func return_to_menu():
	Stats.save_stats()
	if get_tree().paused:
		get_tree().set_pause(false)
	get_tree().change_scene("res://Menu/MainMenu.tscn")


func _on_WorldDecomposeTimer_timeout():
	if Stats.stability < 0:
		anim_player.play("portal_opening")
	elif Stats.stability > 0.1:
		Stats.stability *= 0.9
	else:
		Stats.stability -= 0.02


func _on_BtnQuitTutorial_pressed():
	anim_player.play("tutorial2")
	self.pause(false)
	Stats.is_in_tutorial = false
