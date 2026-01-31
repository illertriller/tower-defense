extends Node2D

## Grid Manager - Handles the tile grid system
## Each cell is 32x32 pixels
## Towers occupy 2x2 cells
## Grid size is now dynamic based on map size from Settings

const CELL_SIZE: int = 32

# Dynamic grid dimensions — set in _ready from Settings
var grid_width: int = 80   # default fallback
var grid_height: int = 45

# Grid states
enum CellState {
	EMPTY = 0,
	PATH = 1,
	TOWER = 2,
	BLOCKED = 3
}

# 2D grid array - stores CellState for each cell
var grid: Array = []

# Grid visibility — only show while placing towers
var grid_visible: bool = false

func _ready():
	_init_grid()

func setup_for_map(map_w: int, map_h: int):
	grid_width = map_w / CELL_SIZE
	grid_height = map_h / CELL_SIZE
	_init_grid()
	queue_redraw()

func _init_grid():
	grid.clear()
	for x in range(grid_width):
		var column: Array = []
		for y in range(grid_height):
			column.append(CellState.EMPTY)
		grid.append(column)

func set_grid_visible(is_visible: bool):
	grid_visible = is_visible
	queue_redraw()

func _draw():
	if not grid_visible:
		return
	
	# Draw grid lines across the full map
	var grid_color = Color(1, 1, 1, 0.08)
	var total_w = grid_width * CELL_SIZE
	var total_h = grid_height * CELL_SIZE
	
	# Vertical lines
	for x in range(grid_width + 1):
		var px = x * CELL_SIZE
		draw_line(Vector2(px, 0), Vector2(px, total_h), grid_color, 1.0)
	
	# Horizontal lines
	for y in range(grid_height + 1):
		var py = y * CELL_SIZE
		draw_line(Vector2(0, py), Vector2(total_w, py), grid_color, 1.0)

# Convert world position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var gx = int(world_pos.x / CELL_SIZE)
	var gy = int(world_pos.y / CELL_SIZE)
	return Vector2i(clampi(gx, 0, grid_width - 1), clampi(gy, 0, grid_height - 1))

# Convert grid coordinates to world position (top-left corner of cell)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)

# Get the snapped center position for a 2x2 tower placement
func get_tower_snap_position(world_pos: Vector2) -> Vector2:
	var grid_pos = world_to_grid(world_pos)
	# Clamp so 2x2 tower stays within grid
	grid_pos.x = clampi(grid_pos.x, 0, grid_width - 2)
	grid_pos.y = clampi(grid_pos.y, 0, grid_height - 2)
	# Return center of the 2x2 area
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE,
		grid_pos.y * CELL_SIZE + CELL_SIZE
	)

# Check if a 2x2 tower can be placed at grid position
func can_place_tower(world_pos: Vector2) -> bool:
	var grid_pos = world_to_grid(world_pos)
	grid_pos.x = clampi(grid_pos.x, 0, grid_width - 2)
	grid_pos.y = clampi(grid_pos.y, 0, grid_height - 2)
	
	# Check all 4 cells
	for dx in range(2):
		for dy in range(2):
			var cx = grid_pos.x + dx
			var cy = grid_pos.y + dy
			if cx >= grid_width or cy >= grid_height:
				return false
			if grid[cx][cy] != CellState.EMPTY:
				return false
	return true

# Mark 2x2 cells as occupied by tower
func place_tower(world_pos: Vector2):
	var grid_pos = world_to_grid(world_pos)
	grid_pos.x = clampi(grid_pos.x, 0, grid_width - 2)
	grid_pos.y = clampi(grid_pos.y, 0, grid_height - 2)
	
	for dx in range(2):
		for dy in range(2):
			grid[grid_pos.x + dx][grid_pos.y + dy] = CellState.TOWER

# Free 2x2 cells when a tower is demolished
func remove_tower(world_pos: Vector2):
	var grid_pos = world_to_grid(world_pos)
	grid_pos.x = clampi(grid_pos.x, 0, grid_width - 2)
	grid_pos.y = clampi(grid_pos.y, 0, grid_height - 2)
	
	for dx in range(2):
		for dy in range(2):
			var cx = grid_pos.x + dx
			var cy = grid_pos.y + dy
			if cx < grid_width and cy < grid_height:
				if grid[cx][cy] == CellState.TOWER:
					grid[cx][cy] = CellState.EMPTY

# Mark cells along the enemy path
func mark_path_cells(path_curve: Curve2D):
	if not path_curve:
		return
	var points = path_curve.get_baked_points()
	for point in points:
		var grid_pos = world_to_grid(point)
		if grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height:
			grid[grid_pos.x][grid_pos.y] = CellState.PATH
			# Also mark adjacent cells for wider path blocking
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var nx = grid_pos.x + dx
					var ny = grid_pos.y + dy
					if nx >= 0 and nx < grid_width and ny >= 0 and ny < grid_height:
						if grid[nx][ny] == CellState.EMPTY:
							grid[nx][ny] = CellState.PATH

# Get grid position for debug/display
func get_cell_state(grid_pos: Vector2i) -> int:
	if grid_pos.x < 0 or grid_pos.x >= grid_width or grid_pos.y < 0 or grid_pos.y >= grid_height:
		return CellState.BLOCKED
	return grid[grid_pos.x][grid_pos.y]
