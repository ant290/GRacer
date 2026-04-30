extends VehicleBody3D

@export var MAX_STEER := 0.8
@export var ENGINE_POWER := 250
@export var BRAKE_POWER := 1.5

## Maximum speed in kilometres per hour
@export var MAX_SPEED := 220
## Maximum speed in kilometres per hour
@export var MAX_REVERSE_SPEED := 80

@export var GEAR_RATIOS := [0.0, 2.1, 1.4, 1.0, 0.7, 0.5] # 0 = neutral
var current_gear := 1
var max_rpm := 6000
var rpm := 0.0

var shift_up_rpm := 5000
var shift_down_rpm := 2500

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var reverse_camera: Camera3D = $CameraPivot/ReverseCamera
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var gear_choice: Label = %GearChoice
@onready var front_left: VehicleWheel3D = $Front_Left
@onready var front_right: VehicleWheel3D = $Front_Right
@onready var rear_left: VehicleWheel3D = $Rear_Left
@onready var rear_right: VehicleWheel3D = $Rear_Right


var init_position : Vector3
var init_transform : Transform3D
var look_ahead : Vector3

func _init() -> void:
	init_transform = transform
	print("init transform %s " % init_transform)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	look_ahead = global_position
	pass # Replace with function body.
	
func _input(event):
	if event.is_action_pressed("driving_reset"):
		
		# wtf is this, Godot???
		PhysicsServer3D.body_set_state(
			get_rid(),
			PhysicsServer3D.BODY_STATE_TRANSFORM,
			init_transform)
			
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func _process(delta: float) -> void:
	progress_bar.value = rpm

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_rpm()
	update_gears()
	var speed = linear_velocity.length()
	var speed_in_kph = speed * 3.6
	
	steering = move_toward(steering, Input.get_axis("driving_right", "driving_left") * MAX_STEER, delta * 2.5)
	var forward_input = Input.get_axis("driving_reverse", "driving_accelerate")
	var velocity_dot = linear_velocity.dot(transform.basis.z)
	
	var gear_ratio = GEAR_RATIOS[current_gear]
	
	if forward_input < 0:
		## Limit to max reverse speed
		if speed_in_kph >= MAX_REVERSE_SPEED and velocity_dot < 0:
			engine_force = 0
		else:
			if speed < 5.0 and not is_zero_approx(speed):
				engine_force = -clampf(ENGINE_POWER * BRAKE_POWER * 5.0 / speed, 0.0, 150)
			else:
				engine_force = -ENGINE_POWER * BRAKE_POWER
	else:
		if speed_in_kph >= MAX_SPEED and velocity_dot > 0:
			engine_force = 0
		else:
			engine_force = forward_input * ENGINE_POWER * gear_ratio

	#camera controls
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5.0)
	look_ahead = look_ahead.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(look_ahead)
	reverse_camera.look_at(look_ahead)
	_check_camera_switch()
	
func _check_camera_switch():
	if linear_velocity.length() < 5: return
	if linear_velocity.dot(transform.basis.z) > 0:
		camera_3d.current = true
	else:
		reverse_camera.current = true

func update_rpm():
	var wheel_speed = abs(get_wheel_speed()) # custom helper or use wheel angular velocity
	print(current_gear)
	print(wheel_speed)
	var rpm_calc = ((wheel_speed * 0.6) * GEAR_RATIOS[current_gear] * 10)# * 0.6
	rpm = clamp(rpm_calc, 800, max_rpm)
	print(rpm)

func get_wheel_speed() -> float:
	var avg_rpm = (front_left.get_rpm() + front_right.get_rpm() + rear_left.get_rpm() + rear_right.get_rpm()) / 4.0
	return avg_rpm

func update_gears():
	var format_string = "%sst Gear"
	if current_gear < GEAR_RATIOS.size() -1 and rpm > shift_up_rpm:
		current_gear += 1
		gear_choice.text = format_string % current_gear
	
	if current_gear > 1 and rpm < shift_down_rpm:
		current_gear -= 1
		gear_choice.text = format_string % current_gear
	
	
