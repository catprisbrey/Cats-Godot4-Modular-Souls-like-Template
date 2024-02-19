extends Control

@onready var nine_patch_rect = $NinePatchRect
@onready var control_card_label = $MarginContainer

# Called when the node enters the scene tree for the first time.

func _input(event):
	if event.is_action_pressed("ui_text_newline"):
		visible = !visible
		
func _ready():
	hide()
	nine_patch_rect.size = control_card_label.size
	nine_patch_rect.position = control_card_label.position
	#nine_patch_rect.set_anchors_preset(Control.PRESET_CENTER)


