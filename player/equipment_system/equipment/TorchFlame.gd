extends GPUParticles3D

@onready var torch_light : OmniLight3D = $TorchLight
@onready var fire_sfx = $"../FireSFX"

@onready var parent_torch: EquipmentObject = get_parent()

func _ready():
	parent_torch.equipped_changed.connect(toggle_torch)

func toggle_torch(toggle):
	emitting = toggle
	torch_light.visible = toggle
	fire_sfx.playing = toggle
