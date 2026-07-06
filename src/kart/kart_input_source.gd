class_name KartInputSource
extends RefCounted
## Abstrahiert Eingabequellen für den Kart-Controller (Q-008): echte
## Spieler-Eingabe und synthetische Test-Eingabe implementieren dasselbe
## Interface, damit Physik-Verhalten ohne Gamepad testbar ist.


func get_steering() -> float:
	return 0.0


func get_accelerate() -> float:
	return 0.0


func get_brake() -> float:
	return 0.0


func is_drift_held() -> bool:
	return false
