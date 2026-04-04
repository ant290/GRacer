# Optional, add to execute in the editor.
@tool

# Icons are optional.
# Alternatively, you may use the UID of the icon or the absolute path.
@icon("icon.svg")

# Automatically register the node in the Create New Node dialog
# and make it available for use with other scripts.
class_name MyButton
extends Button


func _enter_tree():
	pressed.connect(clicked)


func clicked():
	print("You clicked me!")
