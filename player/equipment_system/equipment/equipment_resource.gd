extends Resource
class_name EquipmentResource

## Loose stats for equpiment items. Meqnt to work with EquipmentObjects and
## EquipmentSystems. When an EquipmentObject hits a target, these stats get
## passed to the the hit target by the EquipmentSystem. It's up to the hit object
## to decide what to do with this info (take damage, stunned, has weaknesses/etc).  

@export var name : String = "Equipable Item"
@export_enum("SLASH","HEAVY","SHIELD","OTHER") var object_type : String= "SLASH"
@export var power : int = 1
@export var weight : int = 1
@export var value : int = 1
