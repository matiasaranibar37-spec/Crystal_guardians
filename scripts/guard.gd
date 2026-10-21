extends CharacterBody2D

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN
}


@export var patrol_speed: float = 70.0
@export var chase_speed: float = 115.0
@export var arrival_distance: float = 12.0

@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0

@export var idle_duration: float = 1.0
@export var repath_distance: float = 8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@onready var patrol_a: Marker2D = $PositionPatrolA
@onready var patrol_b: Marker2D = $PositionPatrolB

var state: State = State.IDLE
var player: CharacterBody2D = null

var home_position: Vector2
var patrol_positions: Array[Vector2] = []
var patrol_index: int = 0

var idle_timer: float = 0.0
var attack_timer: float = 0.0

var facing_direction: String = "down"
var navigation_ready: bool = false
@export var health: int = 50


func _ready() -> void:
	add_to_group("guards")
	home_position = global_position

	# Guardamos las posiciones globales de patrullaje.
	# Así no se mueven junto con el guardia.
	patrol_positions = [
		patrol_a.global_position,
		patrol_b.global_position
	]

	# Configuración de navegación.
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.avoidance_enabled = false

	detection_area.body_entered.connect(
		_on_detection_body_entered
	)

	detection_area.body_exited.connect(
		_on_detection_body_exited
	)

	# Estado inicial.
	state = State.IDLE
	idle_timer = idle_duration

	# Esperar a que el mapa de navegación se sincronice.
	call_deferred("_initialize_navigation")


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	if health <= 0:
		queue_free()

func _initialize_navigation() -> void:
	await get_tree().physics_frame

	if not is_inside_tree():
		return

	navigation_ready = true

	navigation_agent.target_position = home_position


func _physics_process(delta: float) -> void:
	if not navigation_ready:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)

	match state:
		State.IDLE:
			process_idle(delta)

		State.PATROL:
			process_patrol()

		State.CHASE:
			process_chase()

		State.ATTACK:
			process_attack()

		State.RETURN:
			process_return()

	move_and_slide()
	update_animation()


func process_idle(delta: float) -> void:
	velocity = Vector2.ZERO

	idle_timer -= delta

	if idle_timer <= 0.0:
		change_state(State.PATROL)


func process_patrol() -> void:
	if patrol_positions.is_empty():
		velocity = Vector2.ZERO
		return

	var target: Vector2 = patrol_positions[patrol_index]

	navigate_to(target, patrol_speed)

	if global_position.distance_to(target) <= arrival_distance:
		velocity = Vector2.ZERO

		patrol_index = (
			patrol_index + 1
		) % patrol_positions.size()

		change_state(State.IDLE)


func process_chase() -> void:
	if not is_instance_valid(player):
		player = null
		change_state(State.RETURN)
		return

	if is_player_in_attack_range():
		velocity = Vector2.ZERO
		change_state(State.ATTACK)
		return

	navigate_to(
		player.global_position,
		chase_speed
	)


func process_attack() -> void:
	velocity = Vector2.ZERO

	if not is_instance_valid(player):
		player = null
		change_state(State.RETURN)
		return

	if not is_player_in_attack_range():
		change_state(State.CHASE)
		return

	# Orientarse hacia el jugador.
	var direction: Vector2 = (
		player.global_position - global_position
	)

	update_facing_direction(direction)

	if attack_timer <= 0.0:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

		attack_timer = attack_cooldown

		print("Guardia atacó al jugador")


func process_return() -> void:
	navigate_to(
		home_position,
		patrol_speed
	)

	if global_position.distance_to(home_position) <= arrival_distance:
		velocity = Vector2.ZERO
		change_state(State.IDLE)


func navigate_to(
	target: Vector2,
	movement_speed: float
) -> void:

	if not navigation_ready:
		velocity = Vector2.ZERO
		return

	# Solo actualizar destino si ha cambiado.
	if navigation_agent.target_position.distance_to(target) > repath_distance:
		navigation_agent.target_position = target

	# Comprobar si terminó el recorrido.
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	# Obtener el siguiente punto de la ruta.
	var next_position: Vector2 = (
		navigation_agent.get_next_path_position()
	)

	# Calcular dirección hacia ese punto.
	var direction: Vector2 = (
		global_position.direction_to(next_position)
	)

	velocity = direction * movement_speed


func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body is CharacterBody2D:
			player = body as CharacterBody2D
			change_state(State.CHASE)


func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		change_state(State.RETURN)


func is_player_in_attack_range() -> bool:
	if not is_instance_valid(player):
		return false

	return attack_area.overlaps_body(player)


func change_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		State.IDLE:
			idle_timer = idle_duration
			velocity = Vector2.ZERO

		State.PATROL:
			pass

		State.CHASE:
			pass

		State.ATTACK:
			velocity = Vector2.ZERO

		State.RETURN:
			pass

	print("Estado del guardia: ", State.keys()[state])


func update_animation() -> void:
	if velocity.length() > 5.0:
		update_facing_direction(velocity)

	var prefix: String = "idle"

	if velocity.length() > 5.0:
		prefix = "walk"

	var animation_name: String = (
		prefix + "_" + facing_direction
	)

	if sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)


func update_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.001:
		return

	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			facing_direction = "right"
		else:
			facing_direction = "left"
	else:
		if direction.y > 0.0:
			facing_direction = "down"
		else:
			facing_direction = "up"
