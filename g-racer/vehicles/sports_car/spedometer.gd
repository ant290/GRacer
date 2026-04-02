extends Label

enum SpeedUnit {
	METERS_PER_SECOND,
	KILOMETERS_PER_HOUR,
	MILES_PER_HOUR,
}

@export var speed_unit: SpeedUnit = SpeedUnit.KILOMETERS_PER_HOUR

@onready var player: VehicleBody3D = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var speed := player.linear_velocity.length()
	
	if speed_unit == SpeedUnit.METERS_PER_SECOND:
		text = ("%.1f" % speed) + " m/s"
	elif speed_unit == SpeedUnit.KILOMETERS_PER_HOUR:
		speed *= 3.6
		text = ("%.0f" % speed) + " km/h"
	else: # speed_unit == SpeedUnit.MILES_PER_HOUR:
		speed *= 2.23694
		text = ("%.0f" % speed) + " mph"
