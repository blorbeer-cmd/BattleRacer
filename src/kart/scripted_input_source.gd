class_name ScriptedInputSource
extends KartInputSource
## Synthetische Eingabequelle für automatisierte Physik-Regressionstests
## (Q-008). Werte werden direkt gesetzt statt vom Input-Singleton gelesen,
## damit Topspeed/Boost/Beschleunigung headless in GUT geprüft werden können.

var steering: float = 0.0
var accelerate: float = 0.0
var brake: float = 0.0
var drift_held: bool = false


func get_steering() -> float:
	return steering


func get_accelerate() -> float:
	return accelerate


func get_brake() -> float:
	return brake


func is_drift_held() -> bool:
	return drift_held
