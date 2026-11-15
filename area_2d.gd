extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		call_deferred("_restart")

func _restart() -> void:
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.reload_current_scene()
