class_name PlayerInputSource
extends KartInputSource
## Liest echte Spieler-Eingaben über die Input-Map-Aktionen
## (siehe CLAUDE.md „Eingabe"). Gamepad ist primär, Tastatur vollwertiger
## Fallback — beides läuft über dieselben Aktionsnamen.


func get_steering() -> float:
	return Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")


func get_accelerate() -> float:
	return Input.get_action_strength("accelerate")


func get_brake() -> float:
	return Input.get_action_strength("brake")


func is_drift_held() -> bool:
	return Input.is_action_pressed("drift")
