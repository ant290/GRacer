class_name Vehicle
extends VehicleBody3D

#this is taken from the tutorial by ithappy: https://www.youtube.com/watch?v=hUVTQh797sY

@export_group("Engine")
@export var torque: int = 2000
@export var max_engine_RPM: int = 8000
@export var shift_up_engine_RPM: int = 6000
@export var shift_down_engine_RPM: int = 1300
@export var idle_engine_RPM: int = 800
@export var gear_ratios: Array[float] = [0.0, 2.1, 1.4, 1.0, 0.7, 0.5] # 0 = neutral
@export var engine_braking: float = 10
var current_gear : int = 1
var wheel_RPM: float = 0.0
var engine_RPM: float = 0.0

@export_group("Drivetrain")
@export var turn_speed: float = 3.0
@export var turn_amount: float = 0.4
@export var wheel_traction_left: VehicleWheel3D
@export var wheel_traction_right: VehicleWheel3D
@export var max_brake_force: float = 50

@export_group("Audio")
@export var engine_sound: AudioStreamPlayer3D
@export var idle_engine_pitch: float = 0.35
@export var max_engine_pitch: float = 1.5

@onready var hud: HUD = %HUD

var throttle: float = 0.0
var reverse: float = 0.0
var handbrake: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hud.update_rpm(engine_RPM)
	hud.update_throttle(throttle)
	hud.update_reverse(reverse)
	hud.update_handbrake(handbrake)

func _physics_process(delta: float) -> void:
	throttle = Input.get_action_strength("driving_accelerate")
	reverse = Input.get_action_strength("driving_reverse")
	handbrake = Input.is_action_pressed("driving_handbrake")
	var steering_dir = Input.get_action_strength("driving_left") - Input.get_action_strength("driving_right")
	
	handle_gears()
	
	var RPM_left = wheel_traction_left.get_rpm()
	var RPM_right = wheel_traction_right.get_rpm()
	wheel_RPM = (RPM_left + RPM_right) / 2.0 # divided by 2 because 2 wheel drive, div by 4 if 4 wheel drive
	engine_RPM = (absf(wheel_RPM) * gear_ratios[current_gear]) * 10 # could do with a much better way to do this in the future as engine rpm is currently tied to wheels that must be on the ground
	engine_RPM = clampf(engine_RPM, idle_engine_RPM, max_engine_RPM)
	#print_debug("wheel RPM: %s" % wheel_RPM) #gets to about max 300
	#print_debug("engine RPM: %s" % engine_RPM)
	
	var is_braking = handle_braking(throttle, reverse, handbrake) #setup handbrake later
	
	#if not is_zero_approx(reverse):
		##apply reverse engine force
		#engine_force = -reverse * torque * gear_ratios[current_gear]
	#else:
		#engine_force = throttle * torque * gear_ratios[current_gear]
	engine_force = (throttle - reverse) * torque * gear_ratios[current_gear]
	
	steering = lerp(steering, steering_dir * turn_amount, turn_speed * delta)
	
	handle_engine_rev_sound(delta)

## applies the braking force and returns if braking is applied or not
func handle_braking(throttle: float, reverse: float, handbrake: bool) -> bool:
	if handbrake:
		brake = max_brake_force
		return true

	var z_velocity_dot = linear_velocity.dot(transform.basis.z)
	#print_debug("throttle: %s" % throttle)
	#print_debug("reverse: %s" % reverse)
	#print_debug("z_velocity_dot: %s" % z_velocity_dot)
	
	if not is_zero_approx(reverse):
		if z_velocity_dot > 0:
			#apply braking
			brake = max_brake_force * reverse
			return true
	elif not is_zero_approx(throttle) and z_velocity_dot < 0:
		brake = max_brake_force * throttle
		return true
	elif is_zero_approx(throttle) and is_zero_approx(reverse):
		brake = engine_braking
		return true
	
	brake = 0
	return false



func handle_gears() -> void:
	#needs a fix for reverse
	if current_gear < gear_ratios.size() -1 and engine_RPM > shift_up_engine_RPM:
		current_gear += 1
	else:
		if current_gear > 1 and engine_RPM < shift_down_engine_RPM:
			current_gear -= 1
	hud.update_gear(current_gear)
	

func handle_engine_rev_sound(delta) -> void:
	if !engine_sound.playing:
		engine_sound.play()
	
	#get current RPM as a pct of max rpm
	#set that as how far between idle and max
	var min_max_difference = max_engine_pitch - idle_engine_pitch
	var percent_of_max_RPM = (abs(engine_RPM) / max_engine_RPM)# * 100.0
	var rev_adjustment = idle_engine_pitch + (min_max_difference * percent_of_max_RPM)
	
	engine_sound.pitch_scale = clampf(rev_adjustment, idle_engine_pitch, max_engine_pitch)
