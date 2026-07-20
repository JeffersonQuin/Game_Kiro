extends Pawn

@export var speed_boost := 1.5

@onready var dialogue_player: Node = $DialoguePlayer


func _ready() -> void:
	dialogue_player.dialogue_finished.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	var grid_node := get_parent() as Grid
	for child in grid_node.get_children():
		if child is Walker:
			child.speed_multiplier = speed_boost
			break
	grid_node.clear_cell(grid_node.local_to_map(position))
	queue_free()
