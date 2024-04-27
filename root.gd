extends Node2D

enum {WORK, BREAK, LONGBREAK}

@onready var time_label = $CanvasLayer/TimeLabel
@onready var work_timer = $WorkTimer
@onready var break_timer = $BreakTimer
@onready var long_break_timer = $LongBreakTimer
@onready var start_pause_button = $CanvasLayer/StartPauseButton
@onready var cycle_label = $CanvasLayer/CycleLabel
@onready var background_rect = $CanvasLayer/BackgroundRect

var time_running = false
var show_default_text = true
@onready var current_timer = work_timer
var current_cycle: int = 0

@export var work_timer_mins = 5/60
@export var break_timer_mins = 1/60
@export var long_break_timer_mins = 3/60
@export var cycles_to_long_break = 3

func _ready():
	work_timer.wait_time = work_timer_mins * 60
	break_timer.wait_time = break_timer_mins * 60
	long_break_timer.wait_time = long_break_timer_mins * 60

func _on_start_pause_button_pressed():
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
	if (current_cycle % cycles_to_long_break) == 0:
		current_timer = long_break_timer
		show_default_text = true
		stop_time()
		background_rect.color = Color.ROYAL_BLUE
	else:
		current_timer = break_timer
		show_default_text = true
		stop_time()
		background_rect.color = Color.DARK_TURQUOISE

func _on_break_timer_timeout():
	current_timer = work_timer
	show_default_text = true
	stop_time()
	background_rect.color = Color.TOMATO

func _on_long_break_timer_timeout():
	current_timer = work_timer
	show_default_text = true
	stop_time()
	background_rect.color = Color.TOMATO
