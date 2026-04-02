extends VehicleBody3D

@export var MAX_STEER := 0.8
@export var ENGINE_POWER := 300
@export var BRAKE_POWER := 1.5

## Maximum speed in kilometres per hour
@export var MAX_SPEED := 220
## Maximum speed in kilometres per hour
@export var MAX_REVERSE_SPEED := 80

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var reverse_camera: Camera3D = $CameraPivot/ReverseCamera

var init_position : Vector3
var init_transform : Transform3D
var look_at : Vector3

func _init() -> void:
	init_transform = transform
	print("init transform %s " % init_transform)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	look_at = global_position
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var speed = linear_velocity.length()
	var speed_in_kph = speed * 3.6
	
	steering = move_toward(steering, Input.get_axis("driving_right", "driving_left") * MAX_STEER, delta * 2.5)
	var forward_input = Input.get_axis("driving_reverse", "driving_accelerate")
	var velocity_dot = linear_velocity.dot(transform.basis.z)
	
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
			engine_force = forward_input * ENGINE_POWER

	#camera controls
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 20)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * 5.0)
	look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(look_at)
	reverse_camera.look_at(look_at)
	_check_camera_switch()
	
func _check_camera_switch():
	if linear_velocity.length() < 5: return
	if linear_velocity.dot(transform.basis.z) > 0:
		camera_3d.current = true
	else:
		reverse_camera.current = true
