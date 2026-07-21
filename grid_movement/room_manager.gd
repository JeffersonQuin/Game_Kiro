class_name RoomManager
extends Node2D

const ROOM_WIDTH := 20
const ROOM_HEIGHT := 10
const ROOM_COUNT := 5
const OBSTACLE_SOURCES := [1, 3, 4, 5, 6, 7, 8, 9, 10]

@onready var ground: TileMapLayer = $Ground
@onready var pathways: TileMapLayer = $Pathways
@onready var grid: Grid = $Grid
@onready var player: Node2D = $Grid/Player
@onready var opponent: Node2D = $Grid/Opponent
@onready var key_item: Node2D = $Grid/Object
@onready var minimap: DungeonMinimap = $DungeonMinimap

var generator := MazeGenerator.new()
var rooms: Dictionary = {}
var room_connections := {
	0: {"east": 1, "south": 2},
	1: {"west": 0, "south": 3},
	2: {"north": 0, "south": 4},
	3: {"north": 1, "east": 4},
	4: {"north": 2, "west": 3},
}
var current_room_id := 0
var rng := RandomNumberGenerator.new()
var changing_room := false


func _ready() -> void:
	rng.randomize()
	$Decoration.hide()
	$"Decoration upper level".hide()
	for room_id in ROOM_COUNT:
		rooms[room_id] = generator.generate(ROOM_WIDTH, ROOM_HEIGHT, room_connections[room_id])
	minimap.configure(room_connections)
	_render_room(0, Vector2i(1, 1))


func _process(_delta: float) -> void:
	if changing_room:
		return
	var cell := grid.local_to_map(player.position)
	for direction: String in rooms[current_room_id].doors:
		if cell == rooms[current_room_id].doors[direction]:
			_change_room(room_connections[current_room_id][direction], _opposite(direction))
			return


func _change_room(next_room_id: int, entered_from: String) -> void:
	changing_room = true
	player.set_process(false)
	await _fade(Color(0.02, 0.03, 0.06, 1.0), 0.18)
	var entry: Vector2i = rooms[next_room_id].doors[entered_from]
	entry = _interior_cell(entry)
	_render_room(next_room_id, entry)
	await _fade(Color(0.02, 0.03, 0.06, 0.0), 0.18)
	player.set_process(true)
	changing_room = false


func _render_room(room_id: int, player_cell: Vector2i) -> void:
	current_room_id = room_id
	ground.clear()
	pathways.clear()
	grid.clear()
	var cells: Array = rooms[room_id].cells
	for y in ROOM_HEIGHT:
		for x in ROOM_WIDTH:
			var cell := Vector2i(x, y)
			ground.set_cell(cell, 0, Vector2i.ZERO, rng.randi_range(0, 7))
			if cells[y][x] == 0:
				pathways.set_cell(cell, _path_source(cell, cells), Vector2i.ZERO, rng.randi_range(0, 7))
			else:
				grid.set_cell(cell, OBSTACLE_SOURCES[rng.randi_range(0, OBSTACLE_SOURCES.size() - 1)], Vector2i.ZERO, rng.randi_range(0, 7))
	player.position = grid.map_to_local(player_cell)
	grid.set_cell(player_cell, CellType.Type.ACTOR, Vector2i.ZERO)
	_place_room_entities(room_id)
	minimap.set_current_room(room_id)


func _place_room_entities(room_id: int) -> void:
	if is_instance_valid(key_item):
		key_item.visible = room_id == 2
		if key_item.visible:
			var item_cell := _first_open_cell(room_id, Vector2i(ROOM_WIDTH >> 1, ROOM_HEIGHT >> 1))
			key_item.position = grid.map_to_local(item_cell)
			grid.set_cell(item_cell, CellType.Type.OBJECT, Vector2i.ZERO)
	opponent.visible = room_id == 4
	opponent.set_process(room_id == 4)
	if room_id == 4:
		var enemy_cell := _first_open_cell(room_id, Vector2i(ROOM_WIDTH - 3, ROOM_HEIGHT - 3))
		opponent.position = grid.map_to_local(enemy_cell)
		grid.set_cell(enemy_cell, CellType.Type.ACTOR, Vector2i.ZERO)


func _first_open_cell(room_id: int, preferred: Vector2i) -> Vector2i:
	var cells: Array = rooms[room_id].cells
	for radius in range(0, max(ROOM_WIDTH, ROOM_HEIGHT)):
		for y in range(maxi(1, preferred.y - radius), mini(ROOM_HEIGHT - 1, preferred.y + radius + 1)):
			for x in range(maxi(1, preferred.x - radius), mini(ROOM_WIDTH - 1, preferred.x + radius + 1)):
				if cells[y][x] == 0:
					return Vector2i(x, y)
	return Vector2i(1, 1)


func _path_source(cell: Vector2i, cells: Array) -> int:
	var neighbors := 0
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var check: Vector2i = cell + direction
		if check.x >= 0 and check.x < ROOM_WIDTH and check.y >= 0 and check.y < ROOM_HEIGHT and cells[check.y][check.x] == 0:
			neighbors += 1
	if neighbors <= 1:
		return 3
	return 2 if rng.randf() < 0.7 else rng.randi_range(0, 1)


func _interior_cell(door: Vector2i) -> Vector2i:
	if door.x == 0:
		return door + Vector2i.RIGHT
	if door.x == ROOM_WIDTH - 1:
		return door + Vector2i.LEFT
	if door.y == 0:
		return door + Vector2i.DOWN
	return door + Vector2i.UP


func _opposite(direction: String) -> String:
	return {"north": "south", "south": "north", "east": "west", "west": "east"}[direction]


func _fade(color: Color, duration: float) -> void:
	var overlay: ColorRect = $RoomTransition
	var tween := create_tween()
	tween.tween_property(overlay, "color", color, duration)
	await tween.finished
