extends GutTest
## Physik-Korrektheitstests für den Kart-Controller (Q-008). Prüft Zahlen
## (Topspeed-Obergrenze, Abbremsverhalten) über eine synthetische
## Eingabequelle — nicht das subjektive Fahrgefühl, das bleibt manuelles
## Gegenspielen mit Gamepad (siehe CLAUDE.md).

const KartScene := preload("res://src/kart/kart.tscn")

var _kart: Kart
var _input: ScriptedInputSource


func before_each() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)

	_kart = KartScene.instantiate()
	add_child_autofree(_kart)
	_kart.handling = _make_handling()
	_kart.mass = _kart.handling.mass_kg
	_input = ScriptedInputSource.new()
	_kart.input_source = _input
	_kart.global_position = Vector3(0.0, 0.5, 0.0)

	await wait_physics_frames(60)


func _make_handling() -> KartHandling:
	var handling := KartHandling.new()
	handling.max_speed = 20.0
	handling.acceleration = 16.0
	handling.natural_deceleration = 8.0
	handling.mass_kg = 150.0
	return handling


func test_accelerating_approaches_but_does_not_exceed_max_speed() -> void:
	_input.accelerate = 1.0
	await wait_physics_frames(int(3.0 * Engine.physics_ticks_per_second))
	var speed: float = _kart.linear_velocity.length()
	assert_almost_eq(speed, _kart.handling.max_speed, 2.0)
	assert_lt(speed, _kart.handling.max_speed + 1.0)


func test_no_input_decelerates_kart() -> void:
	var forward: Vector3 = -_kart.global_transform.basis.z
	_kart.linear_velocity = forward * 10.0
	await wait_physics_frames(int(3.0 * Engine.physics_ticks_per_second))
	assert_lt(_kart.linear_velocity.length(), 2.0)


func test_mini_turbo_charges_stage_after_hold_time() -> void:
	_input.accelerate = 1.0
	await wait_physics_frames(int(1.0 * Engine.physics_ticks_per_second))
	_input.steering = 1.0
	_input.drift_held = true
	await wait_physics_frames(
		int((_kart.handling.mini_turbo_stage1_time + 0.2) * Engine.physics_ticks_per_second)
	)
	_input.drift_held = false
	await wait_physics_frames(2)
	assert_true(_kart.is_boosting())
