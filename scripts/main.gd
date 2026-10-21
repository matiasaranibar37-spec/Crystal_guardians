extends Node2D

var crystals_collected: int = 0
var total_crystals: int = 0

@onready var crystal_label: Label = $UI/HUD/CrystalLabel
@onready var health_label: Label = $UI/HUD/HealthLabel
@onready var player: CharacterBody2D = $player

func _ready() -> void:
	var crystals := $crystals.get_children()
	total_crystals = crystals.size()
	for crystal in crystals:
		if crystal.has_signal("collected"):
			crystal.collected.connect(_on_crystal_collected)
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.health, player.max_health)
	update_crystal_label()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		var npc = get_node_or_null("NPC")
		if npc and is_instance_valid(player) and player.global_position.distance_to(npc.global_position) <= 95.0:
			print("Interacción con el NPC")

func _on_crystal_collected() -> void:
	crystals_collected += 1
	update_crystal_label()
	if crystals_collected >= total_crystals:
		print("¡Todos los cristales recolectados!")

func update_crystal_label() -> void:
	crystal_label.text = "💎 Cristales: %d / %d" % [crystals_collected, total_crystals]

func _on_player_health_changed(current: int, maximum: int) -> void:
	var hearts := int(ceil(float(current) / 20.0))
	health_label.text = "♥".repeat(hearts) + "♡".repeat(5 - hearts) + "  " + str(current) + "/" + str(maximum)
