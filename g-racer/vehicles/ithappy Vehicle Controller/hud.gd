class_name HUD
extends CanvasLayer

@onready var gear_choice: Label = %GearChoice
@onready var rpm_bar: ProgressBar = %RPMBar
@onready var throttle_bar: ProgressBar = %ThrottleBar
@onready var reverse_bar: ProgressBar = %ReverseBar
@onready var handbrake_rect: ColorRect = %HandbrakeRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_gear(gear: int) -> void:
	var format_string = "%sst Gear"
	gear_choice.text = format_string % gear

func update_rpm(rpm: float) -> void:
	rpm_bar.value = rpm

func update_throttle(throttle: float) -> void:
	throttle_bar.value = throttle

func update_reverse(reverse: float) -> void:
	reverse_bar.value = reverse

func update_handbrake(handbrake: bool) -> void:
	handbrake_rect.visible = handbrake
