extends Node

## Build Manager - Handles tower placement

signal tower_selected(tower_type: String)
signal tower_placed(tower_type: String, position: Vector2)
signal build_cancelled()

var selected_tower: String = ""
var is_building: bool = false
var ghost_tower: Node2D = null

func select_tower(type: String):
	if GameManager.can_afford(type):
		selected_tower = type
		is_building = true
		tower_selected.emit(type)
	else:
		# TODO: Play "can't afford" sound
		pass

func cancel_build():
	selected_tower = ""
	is_building = false
	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null
	build_cancelled.emit()

func try_place_tower(pos: Vector2, tower_scene: PackedScene) -> bool:
	if not is_building or selected_tower.is_empty():
		return false
	
	if not GameManager.buy_tower(selected_tower):
		return false
	
	var tower = tower_scene.instantiate()
	tower.global_position = pos
	tower.setup(selected_tower)
	
	# Add to the towers container in the main scene
	var towers_container = get_tree().get_first_node_in_group("towers_container")
	if towers_container:
		towers_container.add_child(tower)
	else:
		get_tree().current_scene.add_child(tower)
	
	tower_placed.emit(selected_tower, pos)
	
	# Reset build state
	cancel_build()
	return true
