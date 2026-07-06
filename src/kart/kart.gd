class_name Kart
extends RigidBody3D
## Raycast-Kart-Controller (README Abschnitt 4 / CLAUDE.md „Fahrphysik").
## Simuliert einen unsichtbaren Fahrzeugkörper über vier
## Raycast-Federungen; das sichtbare Kart-Mesh wird rein optisch
## nachgeführt (Neigung, Drift-Winkel).

signal drift_started
signal drift_ended(boost_applied: bool)
signal mini_turbo_charged(stage: int)
signal respawned

## Verstärkt den Radeinschlagswinkel zur tatsächlichen Gier-Drehrate
## (Radiant/Sekunde) — ohne diesen Faktor ist die Wendigkeit bei
## niedriger/mittlerer Geschwindigkeit kaum spürbar.
const TURN_RATE_GAIN: float = 4.0

@export var handling: KartHandling
@export var visual_root_path: NodePath
@export var wheel_ray_fl: NodePath
@export var wheel_ray_fr: NodePath
@export var wheel_ray_rl: NodePath
@export var wheel_ray_rr: NodePath
@export var void_y_threshold: float = -10.0

var input_source: KartInputSource = PlayerInputSource.new()

var _visual_root: Node3D
var _wheel_ray_nodes: Array[RayCast3D] = []
var _steering_angle: float = 0.0
var _grounded: bool = false
var _on_offroad: bool = false
var _is_drifting: bool = false
var _drift_direction: float = 0.0
var _drift_charge_time: float = 0.0
var _drift_stage: int = 0
var _boost_time_left: float = 0.0
var _boost_speed: float = 0.0
var _upside_down_time: float = 0.0
var _last_safe_transform: Transform3D


func _ready() -> void:
	_visual_root = get_node_or_null(visual_root_path)
	_wheel_ray_nodes = [
		get_node(wheel_ray_fl) as RayCast3D,
		get_node(wheel_ray_fr) as RayCast3D,
		get_node(wheel_ray_rl) as RayCast3D,
		get_node(wheel_ray_rr) as RayCast3D,
	]
	if handling != null:
		mass = handling.mass_kg
	_last_safe_transform = global_transform


func _physics_process(delta: float) -> void:
	if handling == null:
		return
	_update_ground_state()
	_apply_suspension()
	_apply_drive(delta)
	_apply_steering(delta)
	_apply_lateral_grip(delta)
	_stabilize_rotation(delta)
	_update_drift(delta)
	_update_auto_right(delta)
	_update_visual(delta)
	_check_fell_off()
	if _grounded and _is_upright():
		_last_safe_transform = global_transform


func is_boosting() -> bool:
	return _boost_time_left > 0.0


func apply_external_boost(speed: float, duration: float) -> void:
	_boost_speed = maxf(_boost_speed, speed)
	_boost_time_left = maxf(_boost_time_left, duration)


func respawn() -> void:
	global_transform = _last_safe_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_is_drifting = false
	_boost_time_left = 0.0
	respawned.emit()


func _update_ground_state() -> void:
	_grounded = false
	_on_offroad = false
	for ray in _wheel_ray_nodes:
		if not ray.is_colliding():
			continue
		_grounded = true
		var collider: Object = ray.get_collider()
		if collider is Node and (collider as Node).is_in_group("offroad"):
			_on_offroad = true


func _apply_suspension() -> void:
	for ray in _wheel_ray_nodes:
		if not ray.is_colliding():
			continue
		var contact: Vector3 = ray.get_collision_point()
		var normal: Vector3 = ray.get_collision_normal()
		var ray_length: float = ray.target_position.length()
		var distance: float = ray.global_position.distance_to(contact)
		var compression: float = clampf(ray_length - distance, 0.0, ray_length)
		var compression_ratio: float = compression / ray_length
		var spring_velocity: float = linear_velocity.dot(normal)
		var force_magnitude: float = (
			compression_ratio * handling.suspension_stiffness
			- spring_velocity * handling.suspension_damping
		)
		apply_force(normal * maxf(force_magnitude, 0.0), contact - global_position)


func _apply_drive(delta: float) -> void:
	if not _grounded:
		return

	var forward: Vector3 = -global_transform.basis.z
	var forward_speed: float = linear_velocity.dot(forward)
	var offroad_factor: float = handling.offroad_speed_multiplier if _on_offroad else 1.0

	if _boost_time_left > 0.0:
		_boost_time_left = maxf(_boost_time_left - delta, 0.0)
		apply_central_force(forward * _boost_speed * mass)

	var boost_bonus: float = _boost_speed if _boost_time_left > 0.0 else 0.0
	var max_forward_speed: float = (handling.max_speed + boost_bonus) * offroad_factor

	var accelerate_input: float = input_source.get_accelerate()
	var brake_input: float = input_source.get_brake()

	if accelerate_input > 0.0 and forward_speed < max_forward_speed:
		apply_central_force(
			forward * accelerate_input * handling.acceleration * offroad_factor * mass
		)
	elif brake_input > 0.0:
		if forward_speed > 0.0:
			apply_central_force(forward * -brake_input * handling.braking_force * mass)
		elif forward_speed > -handling.reverse_speed:
			apply_central_force(forward * -brake_input * handling.acceleration * mass)
	else:
		apply_central_force(forward * -signf(forward_speed) * handling.natural_deceleration * mass)

	if _on_offroad and forward_speed > max_forward_speed:
		apply_central_force(forward * -handling.natural_deceleration * 2.0 * mass)


func _apply_steering(delta: float) -> void:
	if not _grounded:
		return

	var steering_input: float = input_source.get_steering()
	var max_angle: float = deg_to_rad(handling.max_steering_angle_deg)
	var target_angle: float = -steering_input * max_angle

	if _is_drifting:
		var drift_bias: float = -_drift_direction * max_angle * 0.6
		target_angle = clampf(
			target_angle + drift_bias,
			-max_angle * handling.drift_steering_multiplier,
			max_angle * handling.drift_steering_multiplier
		)

	_steering_angle = move_toward(_steering_angle, target_angle, handling.steering_speed * delta)

	var forward_speed: float = linear_velocity.dot(-global_transform.basis.z)
	var speed_ratio: float = clampf(absf(forward_speed) / handling.max_speed, 0.3, 1.0)
	var turn_rate: float = _steering_angle * TURN_RATE_GAIN * speed_ratio
	var active_grip: float = handling.drift_grip if _is_drifting else handling.grip
	angular_velocity.y = move_toward(angular_velocity.y, turn_rate, active_grip * 3.0 * delta)


func _apply_lateral_grip(delta: float) -> void:
	if not _grounded:
		return
	var right: Vector3 = global_transform.basis.x
	var lateral_speed: float = linear_velocity.dot(right)
	var active_grip: float = handling.drift_grip if _is_drifting else handling.grip
	var max_correction: float = active_grip * delta * 10.0
	var correction: float = clampf(lateral_speed, -max_correction, max_correction)
	linear_velocity -= right * correction


func _stabilize_rotation(delta: float) -> void:
	var righting_speed: float = handling.grip * 2.0 * delta
	angular_velocity.x = move_toward(angular_velocity.x, 0.0, righting_speed)
	angular_velocity.z = move_toward(angular_velocity.z, 0.0, righting_speed)


func _update_drift(delta: float) -> void:
	var steering_input: float = input_source.get_steering()
	var forward_speed: float = linear_velocity.dot(-global_transform.basis.z)
	var drift_held: bool = input_source.is_drift_held()

	if not _is_drifting:
		if (
			_grounded
			and drift_held
			and absf(steering_input) > 0.1
			and forward_speed > handling.drift_min_speed
		):
			_start_drift(signf(steering_input))
		return

	if not drift_held:
		_end_drift()
		return

	_drift_charge_time += delta
	var new_stage: int = 0
	if _drift_charge_time >= handling.mini_turbo_stage2_time:
		new_stage = 2
	elif _drift_charge_time >= handling.mini_turbo_stage1_time:
		new_stage = 1
	if new_stage != _drift_stage:
		_drift_stage = new_stage
		mini_turbo_charged.emit(_drift_stage)


func _start_drift(direction: float) -> void:
	_is_drifting = true
	_drift_direction = direction
	_drift_charge_time = 0.0
	_drift_stage = 0
	drift_started.emit()


func _end_drift() -> void:
	_is_drifting = false
	var boosted: bool = _drift_stage > 0
	if _drift_stage == 1:
		apply_external_boost(handling.mini_turbo_boost_stage1, handling.mini_turbo_boost_duration)
	elif _drift_stage == 2:
		apply_external_boost(handling.mini_turbo_boost_stage2, handling.mini_turbo_boost_duration)
	_drift_stage = 0
	drift_ended.emit(boosted)


func _is_upright() -> bool:
	return global_transform.basis.y.dot(Vector3.UP) > 0.0


func _update_auto_right(delta: float) -> void:
	if _is_upright():
		_upside_down_time = 0.0
		return
	_upside_down_time += delta
	if _upside_down_time > 1.5:
		_snap_upright()


func _snap_upright() -> void:
	var origin: Vector3 = global_position + Vector3.UP * 1.0
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	global_transform = Transform3D(Basis.looking_at(forward.normalized(), Vector3.UP), origin)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_upside_down_time = 0.0


func _update_visual(delta: float) -> void:
	if _visual_root == null:
		return
	var target_basis: Basis = Basis()
	if _is_drifting:
		target_basis = target_basis.rotated(Vector3.UP, _drift_direction * deg_to_rad(20.0))
	_visual_root.transform.basis = _visual_root.transform.basis.slerp(
		target_basis, clampf(delta * 8.0, 0.0, 1.0)
	)


func _check_fell_off() -> void:
	if global_position.y < void_y_threshold:
		respawn()
