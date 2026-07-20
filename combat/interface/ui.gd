extends Control

signal flee(winner: Combatant, loser: Combatant)


@export var combatants_node: Node
@export var info_scene: PackedScene


func initialize() -> void:
	for combatant in combatants_node.get_children():
		var health := combatant.get_node(^"Health")
		var info := info_scene.instantiate()
		var health_info := info.get_node(^"VBoxContainer/HealthContainer/Health")
		health_info.value = health.life
		health_info.max_value = health.max_life
		info.get_node(^"VBoxContainer/NameContainer/Name").text = combatant.name
		health.health_changed.connect(health_info.set_value)
		$Combatants.add_child(info)

	$Buttons/GridContainer/Attack.grab_focus()


func _on_Attack_button_up() -> void:
	var player := get_tree().get_first_node_in_group("players") as Combatant
	if not player or not player.active:
		return

	var target := get_tree().get_first_node_in_group("enemies") as Combatant
	player.attack(target)


func _on_Defend_button_up() -> void:
	var player := get_tree().get_first_node_in_group("players") as Combatant
	if not player or not player.active:
		return

	player.defend()


func _on_Heal_button_up() -> void:
	var player := get_tree().get_first_node_in_group("players") as Combatant
	if not player or not player.active:
		return

	player.heal()


func _on_Flee_button_up() -> void:
	var player := get_tree().get_first_node_in_group("players") as Combatant
	if not player or not player.active:
		return

	player.flee()

	var winner: Combatant = get_tree().get_first_node_in_group("enemies")
	flee.emit(winner, player)
