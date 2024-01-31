extends Resource
class_name ItemResource

## Loose stats for equpiment items. Meqnt to work with EquipmentObjects and
## EquipmentSystems. When an EquipmentObject hits a target, these stats get
## passed to the the hit target by the EquipmentSystem. It's up to the hit object
## to decide what to do with this info (take damage, stunned, has weaknesses/etc).  
signal item_used

@export var name : String = "Consumable Item"
@export_enum("DRINK","THROWN","OTHER") var object_type : String= "DRINK"
@export var power : int = 1
@export var weight : int = 1
@export var value : int = 1
@export var texture : Texture2D
var count = 1

@export var physical_scene : PackedScene

func activate():
	print(name + " - was activated")
	item_used.emit(self)
