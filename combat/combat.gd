extends Node

signal combat_finished(winner: Combatant, loser: Combatant)


@onready var ui := $CombatCanvas/UI


func _ready() -> void:
	ui.flee.connect(_on_flee)


func _on_flee(winner: Combatant, loser: Combatant) -> void:
	finish_combat(winner, loser)


func initialize(combat_combatants: Array[PackedScene]) -> void:
	for combatant_scene in combat_combatants:
		var combatant := combatant_scene.instantiate()
		if combatant is Combatant:
			$Combatants.add_combatant(combatant)
			if combatant.is_player:
				combatant.add_to_group("players")
			else:
				combatant.add_to_group("enemies")
			combatant.get_node(^"Health").dead.connect(_on_combatant_death.bind(combatant))
		else:
			combatant.queue_free()
	ui.initialize()
	$TurnQueue.initialize()


func clear_combat() -> void:
	$TurnQueue.stop()
	for n in $Combatants.get_children():
		n.queue_free()
	for n in ui.get_node(^"Combatants").get_children():
		n.queue_free()


func finish_combat(winner: Combatant, loser: Combatant) -> void:
	combat_finished.emit(winner, loser)


func _on_combatant_death(combatant: Combatant) -> void:
	var winner: Combatant
	if combatant.is_in_group("players"):
		winner = get_tree().get_first_node_in_group("enemies")
	else:
		winner = get_tree().get_first_node_in_group("players")

	finish_combat(winner, combatant)
