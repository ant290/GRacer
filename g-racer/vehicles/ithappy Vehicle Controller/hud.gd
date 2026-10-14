class_name HUD
extends CanvasLayer

@onready var gear_choice: Label = %GearChoice
@onready var rpm_bar: ProgressBar = %RPMBar

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
