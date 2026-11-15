extends Node

@export var target_node: Node2D
var max_frames: int = 300
var history: Array = []

func _ready() -> void:
	if not target_node:
		target_node = get_parent()

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("rewind"):
		rewind()
	else:
		record()

func record() -> void:
	var state: Dictionary = {
		"pos": target_node.global_position,
		"rot": target_node.global_rotation
	}
	history.append(state)
	
	if history.size() > max_frames:
		history.pop_front()

func rewind() -> void:
	if history.size() > 0:
		var state: Dictionary = history.pop_back()
		target_node.global_position = state["pos"]
		target_node.global_rotation = state["rot"]
