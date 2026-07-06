class_name KartHandling
extends Resource
## Datengetriebene Tuning-Parameter pro Kart/Charakter (README Abschnitt 4,
## CLAUDE.md „Handling ist datengetrieben"). Balancing-Änderungen passieren
## ausschließlich hier, nie im Kart-Controller-Code.

enum WeightClass { LIGHT, MEDIUM, HEAVY }

@export var weight_class: WeightClass = WeightClass.MEDIUM

@export_group("Antrieb")
@export var max_speed: float = 22.0
@export var reverse_speed: float = 10.0
@export var acceleration: float = 14.0
@export var braking_force: float = 30.0
@export var natural_deceleration: float = 6.0

@export_group("Lenkung")
@export var max_steering_angle_deg: float = 32.0
@export var steering_speed: float = 6.0

@export_group("Grip & Drift")
@export var grip: float = 10.0
@export var drift_grip: float = 4.0
@export var drift_steering_multiplier: float = 1.5
@export var drift_min_speed: float = 6.0

@export_group("Mini-Turbo")
@export var mini_turbo_stage1_time: float = 0.8
@export var mini_turbo_stage2_time: float = 1.6
@export var mini_turbo_boost_stage1: float = 6.0
@export var mini_turbo_boost_stage2: float = 10.0
@export var mini_turbo_boost_duration: float = 1.0

@export_group("Fahrzeug")
@export var mass_kg: float = 150.0
@export var suspension_stiffness: float = 60.0
@export var suspension_damping: float = 4.0

@export_group("Untergrund")
@export var offroad_speed_multiplier: float = 0.5
