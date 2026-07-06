class_name BoostPad
extends Area3D
## Boost-Pad-Baustein (A-017, README Abschnitt „Strecken & Rennlogik").
## Wiederverwendbar in beliebigen Streckenszenen unter tracks/.

@export var boost_speed: float = 12.0
@export var boost_duration: float = 1.2


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_external_boost"):
		body.apply_external_boost(boost_speed, boost_duration)
