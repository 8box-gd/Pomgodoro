extends Node2D

enum {WORK, BREAK, LONGBREAK}

@onready var timer_container = %TimerContainer
@onready var time_label = %TimeLabel
@onready var work_timer = $WorkTimer
@onready var break_timer = $BreakTimer
@onready var long_break_timer = $LongBreakTimer
@onready var start_pause_button = %StartPauseButton
@onready var cycle_label = %CycleLabel
@onready var background_rect = %BackgroundRect
@onready var alarm_sound = $Alarm
@onready var click_sound = $Click
@onready var work_button = %WorkButton
@onready var break_button = %BreakButton
@onready var long_break_button = %LongBreakButton
@onready var idle_timer: Timer = $IdleTimer
@onready var flash_rect: ColorRect = %FlashRect

@onready var settings_container = %SettingsContainer
@onready var work_slider = %WorkSlider
@onready var work_setting_label = %WorkSettingLabel
@onready var break_slider = %BreakSlider
@onready var break_setting_label = %BreakSettingLabel
@onready var long_break_slider = %LongBreakSlider
@onready var long_break_setting_label = %LongBreakSettingLabel
@onready var cycle_slider = %CycleSlider
@onready var cycle_setting_label = %CycleSettingLabel
@onready var autostart_button = %AutostartButton
@onready var dark_button = %DarkButton
@onready var volume_slider = $CanvasLayer/SettingsContainer/Volume/VolumeSlider
@onready var click_options = %ClickOptions
@onready var alarm_options = %AlarmOptions

var time_running = false
var show_default_text = true
@onready var current_timer = work_timer
var current_cycle: int = 0
var showing_timer = true
var idle_flashing_active := false

var light_theme_colors = [Color.TOMATO, Color.DARK_TURQUOISE, Color.ROYAL_BLUE]
var dark_theme_colors = [Color.WEB_MAROON, Color.DARK_SLATE_GRAY, Color.MIDNIGHT_BLUE]
var current_theme = dark_theme_colors

var work_timer_mins: int = 25
var break_timer_mins: int = 5
var long_break_timer_mins: int = 15
var cycles_to_long_break: int = 4
var app_window: Window

func _ready():
	app_window = get_window()#get_tree().root
	load_in_save()
	work_timer.wait_time = work_timer_mins * 60
	break_timer.wait_time = break_timer_mins * 60
	long_break_timer.wait_time = long_break_timer_mins * 60
	background_rect.color = current_theme[0]
	
	break_slider.value = break_timer_mins
	cycle_slider.value = cycles_to_long_break
	long_break_slider.value = long_break_timer_mins
	work_slider.value = work_timer_mins
	change_click(click_options.selected)
	change_alarm(alarm_options.selected)
	#NOTE: Volume slider is updated in load_in_save()

func load_in_save():
	var save_data = SaveManager.read_save()
	work_timer_mins = save_data.work_time
	break_timer_mins = save_data.break_time
	long_break_timer_mins = save_data.long_break_time
	cycles_to_long_break = save_data.cycles_to_long_break
	autostart_button.button_pressed = save_data.autostart
	dark_button.button_pressed = save_data.dark_theme
	volume_slider.value = save_data.volume
	click_options.selected = save_data.selected_click
	alarm_options.selected = save_data.selected_alarm
	AudioServer.set_bus_volume_db(1, linear_to_db(save_data.volume))
	print(save_data)

func _on_start_pause_button_pressed():
	push_startpause()

func push_startpause():
	click_sound.play()
	stop_idletime()
	if not time_running:
		start_time()
	else:
		stop_time()

func start_time():
	if current_timer.is_stopped():
		current_timer.start()
		if current_timer == work_timer:
			current_cycle += 1
			cycle_label.text = "#"+str(current_cycle)
	time_running = true
	if show_default_text: show_default_text = false
	current_timer.paused = false
	start_pause_button.text = "PAUSE"

func stop_time():
	time_running = false
	current_timer.paused = true
	start_pause_button.text = "START"

func to_min_sec():
	var time_left = current_timer.time_left
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	return [minute, second]

func _process(delta):
	if Input.is_action_just_pressed("startstop"):
		push_startpause()
	
	if not show_default_text:
		time_label.text = "%02d:%02d" % to_min_sec()
	else:
		match current_timer:
			work_timer:
				time_label.text = str(work_timer_mins)+":00"
				if work_timer_mins < 10: time_label.text = "0"+time_label.text
			break_timer:
				time_label.text = str(break_timer_mins)+":00"
				if break_timer_mins < 10: time_label.text = "0"+time_label.text
			long_break_timer:
				time_label.text = str(long_break_timer_mins)+":00"
				if long_break_timer_mins < 10: time_label.text = "0"+time_label.text

func _on_work_timer_timeout():
	alarm_sound.play()
	start_idletime()
	prints(current_cycle, cycles_to_long_break, current_cycle % cycles_to_long_break)
	if (current_cycle % cycles_to_long_break) == 0 and cycles_to_long_break != 1:
		switch_to_long_break()
	else:
		switch_to_break()
	if autostart_button.button_pressed:
		await get_tree().create_timer(1.0).timeout
		start_time()

func _on_break_timer_timeout():
	alarm_sound.play()
	start_idletime()
	switch_to_work()
	if autostart_button.button_pressed:
		await get_tree().create_timer(1.0).timeout
		start_time()

func _on_long_break_timer_timeout():
	alarm_sound.play()
	start_idletime()
	switch_to_work()
	if autostart_button.button_pressed:
		await get_tree().create_timer(1.0).timeout
		start_time()

func switch_to_work():
	stop_time()
	current_timer = work_timer
	show_default_text = true
	background_rect.color = current_theme[0]
	work_button.disabled = true
	break_button.disabled = false
	long_break_button.disabled = false
func switch_to_break():
	stop_time()
	current_timer = break_timer
	show_default_text = true
	background_rect.color = current_theme[1]
	work_button.disabled = false
	break_button.disabled = true
	long_break_button.disabled = false
func switch_to_long_break():
	stop_time()
	current_timer = long_break_timer
	show_default_text = true
	background_rect.color = current_theme[2]
	work_button.disabled = false
	break_button.disabled = false
	long_break_button.disabled = true

func _on_work_button_pressed():
	work_timer.stop()
	break_timer.stop()
	long_break_timer.stop()
	switch_to_work()
func _on_break_button_pressed():
	work_timer.stop()
	break_timer.stop()
	long_break_timer.stop()
	switch_to_break()
func _on_long_break_button_pressed():
	work_timer.stop()
	break_timer.stop()
	long_break_timer.stop()
	switch_to_long_break()

func _on_settings_button_pressed():
	if showing_timer:
		timer_container.visible = false
		settings_container.visible = true
		showing_timer = false
		work_timer.stop()
		break_timer.stop()
		long_break_timer.stop()
		background_rect.color = current_theme[0]

## SETTINGS BEGIN HERE

func _on_work_slider_value_changed(value):
	work_setting_label.text = "Work time: "+str(work_slider.value)+" minutes"

func _on_break_slider_value_changed(value):
	break_setting_label.text = "Break time: "+str(break_slider.value)+" minutes"

func _on_long_break_slider_value_changed(value):
	long_break_setting_label.text = "Long break time: "+str(long_break_slider.value)+" minutes"

func _on_cycle_slider_value_changed(value):
	cycle_setting_label.text = "Have a long break every "+str(cycle_slider.value)+" cycles"
	if cycle_slider.value == 1: cycle_setting_label.text = "Long breaks disabled"

func _on_dark_button_toggled(toggled_on):
	if toggled_on:
		current_theme = dark_theme_colors
	else:
		current_theme = light_theme_colors
	background_rect.color = current_theme[0]

func _on_reset_button_pressed():
	work_slider.value = 25
	break_slider.value = 5
	long_break_slider.value = 15
	cycle_slider.value = 4
	volume_slider.value = 1.0
	autostart_button.button_pressed = false
	dark_button.button_pressed = true
	alarm_options.selected = 0
	click_options.selected = 0
	change_click(click_options.selected)
	change_alarm(alarm_options.selected)

func _on_apply_button_pressed():
	save_options()
	work_timer_mins = work_slider.value
	break_timer_mins = break_slider.value
	long_break_timer_mins = long_break_slider.value
	update_timer()
	
	timer_container.visible = true
	settings_container.visible = false
	showing_timer = true
	switch_to_work()

func update_timer():
	work_timer.wait_time = work_timer_mins * 60
	break_timer.wait_time = break_timer_mins * 60
	long_break_timer.wait_time = long_break_timer_mins * 60
	if current_cycle > 0:
		current_cycle -= 1
		cycle_label.text = "#"+str(current_cycle)
	background_rect.color = current_theme[0]

func _on_save_button_pressed():
	save_options()

func save_options():
	var write_me = { "autostart": autostart_button.button_pressed,
		"break_time": break_slider.value,
		"cycles_to_long_break": cycle_slider.value,
		"dark_theme": dark_button.button_pressed,
		"long_break_time": long_break_slider.value,
		"selected_alarm": alarm_options.selected, #TODO: Unfuck this when you add new alarms
		"selected_click": click_options.selected,
		"volume": volume_slider.value,
		"work_time": work_slider.value }
	SaveManager.write_save(write_me)

func _on_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(1, linear_to_db(value))

func change_click(sound):
	var new_sound = ""
	match sound:
		0:
			new_sound = "res://Clicks/DefaultClick.mp3"
		1:
			new_sound = "res://Clicks/yuh.wav"
		2:
			pass
	click_sound.stream = load(new_sound)

func change_alarm(sound):
	var new_sound = ""
	match sound:
		0:
			new_sound = "res://Alarms/DefaultAlarm.wav"
		1:
			new_sound = "res://Alarms/owowowow.wav"
		2:
			pass
	alarm_sound.stream = load(new_sound)

func _on_click_options_item_selected(index):
	change_click(index)

func _on_alarm_options_item_selected(index):
	change_alarm(index)


func start_idletime() -> void:
	idle_flashing_active = true
	idle_timer.start()
	flash_rect.modulate = Color(1,1,1,1)

func stop_idletime() -> void:
	idle_flashing_active = false
	idle_timer.stop()
	flash_rect.modulate = Color(1,1,1,0)

func _on_idle_timer_timeout() -> void:
	idle_flash()

func idle_flash() -> void:
	match current_timer:
		work_timer:
			flash_rect.color = light_theme_colors[0]
		break_timer:
			flash_rect.color = light_theme_colors[1]
		long_break_timer:
			flash_rect.color = light_theme_colors[2]
	if current_theme == light_theme_colors:
		flash_rect.color = Color(0.9, 0.9, 0.9, 1)
	
	# Don't want to use an AnimationPlayer here because it might be expensive
	#Window.request_attention()
	app_window.request_attention()
	flash_rect.visible = true
	await get_tree().create_timer(0.6).timeout
	flash_rect.visible = false
	await get_tree().create_timer(0.6).timeout
	flash_rect.visible = true
	await get_tree().create_timer(0.6).timeout
	flash_rect.visible = false
	await get_tree().create_timer(0.6).timeout
	flash_rect.visible = true
	await get_tree().create_timer(0.6).timeout
	flash_rect.visible = false
