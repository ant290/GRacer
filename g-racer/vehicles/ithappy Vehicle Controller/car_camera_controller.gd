extends SpringArm3D

@export_group("camera")
@export var mouse_sensitivity: float = 0.1
@export var min_limit_x : float = -0.7
@export var max_limit_x: float = 0.45
@export var min_limit_x_degrees : float = -90.0
@export var max_limit_x_degrees: float = 10.0
@export var horizontal_acceleration: float = 2
@export var vertical_acceleration: float = 1
@export var original_view_rotation: Vector3 = Vector3(-20, -180, 0)
@export var spring_length_choices: Array[float] = [15.0, 10.0, 6.0]

@onready var camera_settings_debug: CanvasLayer = $CameraSettingsDebug
@onready var rotation_label: Label = %Rotation
@onready var position_label: Label = %Position
@onready var camera_control: Label = %CameraControl

var chosen_length: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_degrees = original_view_rotation
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# probably should reset when not using the stick anymore
	var joy_dir = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	rotate_to_stick_position(joy_dir)
	var joy_dir_accelerated = joy_dir * delta * Vector2(horizontal_acceleration, vertical_acceleration)
	#todo: use mouse as override maybe? keep code for now
	#rotate_from_vector(joy_dir_accelerated)
	update_debug_labels(joy_dir)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("camera_next"):
		if chosen_length < spring_length_choices.size() - 1:
			chosen_length += 1
		else:
			chosen_length = 0
		spring_length = spring_length_choices[chosen_length]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -90, -15)
		
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360)

func rotate_from_vector(v: Vector2):
	if v.length() == 0 : return
	rotation.y -= v.x
	rotation.x -= v.y
	rotation.x = clamp(rotation.x, min_limit_x, max_limit_x)
	
func rotate_to_stick_position(v: Vector2) -> void:
	#convert x y stick imputs to rotation around the centre
	######
	#IMPORTANT!! x on the stick is Y on the camera and vice versa IMPORTANT!!
	######
	
	#convert -1 to 1 into -180 to 180 for y position
	#think we can just times 180 by the value
	rotation_degrees.y = 180 + (v.x * 180)
	
	#convert -1 to 1 into min_limit_x, max_limit_x for x position
	#add the offset from the original position
	var vertical_rotation = (-v.y * 180) + original_view_rotation.x
	rotation_degrees.x = clampf(vertical_rotation, min_limit_x_degrees, max_limit_x_degrees)

func update_debug_labels(camera_input: Vector2) -> void:
	if not camera_settings_debug.visible:
		return
		
	var format_rotation = "Rotation - X: %s Y: %s Z: %s"
	var format_position = "Position - X: %s Y: %s Z: %s"
	var format_camera = "Camera - X: %s Y: %s"
	rotation_label.text = format_rotation % [rotation_degrees.x, rotation_degrees.y, rotation_degrees.z]
	position_label.text = format_position % [position.x, position.y, position.z]
	camera_control.text = format_camera % [camera_input.x, camera_input.y]
