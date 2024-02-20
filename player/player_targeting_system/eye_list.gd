extends Area3D

@export var target_group_name : String = "Targets"
@onready var target_list : Array = []

signal target_list_updated

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_make_list)
	body_exited.connect(_clean_list)

func _make_list(_body):
	if _body.is_in_group(target_group_name):
		target_list = get_overlapping_bodies()
		target_list = target_list.filter(_filter_body)
		target_list_updated.emit()

func _clean_list(_new_body):
	var cleaned_list = []
	for old_body in target_list:
		if old_body != _new_body:
			cleaned_list.append(old_body)
	target_list = cleaned_list
	target_list_updated.emit()

func _filter_body(body):
	# returns true of the bodies are in the target group.
	if body.is_in_group(target_group_name):
		return true
