class_name ChaseCamera
extends Camera3D
## Weiche Verfolgerkamera (A-014): folgt Position/Rotation des Ziels
## unabhängig von dessen Roll/Physik-Taumeln, zieht bei Boost das FOV auf.

@export var target: Kart
@export var distance: float = 6.0
@export var height: float = 2.5
@export var look_height: float = 1.0
@export var follow_speed: float = 6.0
@export var rotation_speed: float = 4.0
@export var base_fov: float = 70.0
@export var boost_fov: float = 82.0
@export var fov_speed: float = 40.0

var _look_back: bool = false


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var target_forward: Vector3 = -target.global_transform.basis.z
	target_forward.y = 0.0
	if target_forward.length() < 0.01:
		target_forward = Vector3.FORWARD
	target_forward = target_forward.normalized()
	if _look_back:
		target_forward = -target_forward

	var desired_position: Vector3 = (
		target.global_position - target_forward * distance + Vector3.UP * height
	)
	global_position = global_position.lerp(desired_position, clampf(delta * follow_speed, 0.0, 1.0))

	var look_target: Vector3 = target.global_position + Vector3.UP * look_height
	var desired_transform: Transform3D = global_transform.looking_at(look_target, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(
		desired_transform.basis, clampf(delta * rotation_speed, 0.0, 1.0)
	)

	fov = move_toward(fov, boost_fov if target.is_boosting() else base_fov, fov_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("look_back"):
		_look_back = true
	elif event.is_action_released("look_back"):
		_look_back = false
