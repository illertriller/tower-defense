extends Node2D

## Grid Manager - Handles the tile grid system
## Each cell is 32x32 pixels
## Towers occupy 2x2 cells

const CELL_SIZE: int = 32
const GRID_WIDTH: int = 40   # 1280 / 32
const GRID_HEIGHT: int = 22  # 704 / 32 (bottom 16px for UI)

# Grid states
enum CellState {
	EMPTY = 0,
	PATH = 1,
	TOWER = 2,
	BLOCKED = 3
}

# 2D grid array - stores CellState for each cell
var grid: Array = []

func _ready():
	_init_grid()

func _init_grid():
	grid.clear()
	for x in range(GRID_WIDTH):
		var column: Array = []
		for y in range(GRID_HEIGHT):
			column.append(CellState.EMPTY)
		grid.append(column)

func _draw():
	# Draw subtle grid lines
	var grid_color = Color(1, 1, 1, 0.08)
	
	# Vertical lines
	for x in range(GRID_WIDTH + 1):
		var start = Vector2(x * CELL_SIZE, 0)
		var end = Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
		draw_line(start, end, grid_color, 1.0)
	
	# Horizontal lines
	for y in range(GRID_HEIGHT + 1):
		var start = Vector2(0, y * CELL_SIZE)
		var end = Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE)
		draw_line(start, end, grid_color, 1.0)

# Convert world position to grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var gx = int(world_pos.x / CELL_SIZE)
	var gy = int(world_pos.y / CELL_SIZE)
	return Vector2i(clampi(gx, 0, GRID_WIDTH - 1), clampi(gy, 0, GRID_HEIGHT - 1))

# Convert grid coordinates to world position (top-left corner of cell)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)

# Get the snapped center position for a 2x2 tower placement
func get_tower_snap_position(world_pos: Vector2) -> Vector2:
	var grid_pos = world_to_grid(world_pos)
	# Clamp so 2x2 tower stays within grid
	grid_pos.x = clampi(grid_pos.x, 0, GRID_WIDTH - 2)
	grid_pos.y = clampi(grid_pos.y, 0, GRID_HEIGHT - 2)
	# Return center of the 2x2 area
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE,
		grid_pos.y * CELL_SIZE + CELL_SIZE
	)

# Check if a 2x2 tower can be placed at grid position
func can_place_tower(world_pos: Vector2) -> bool:
	var grid_pos = world_to_grid(world_pos)
	grid_pos.x = clampi(grid_pos.x, 0, GRID_WIDTH - 2)
	grid_pos.y = clampi(grid_pos.y, 0, GRID_HEIGHT - 2)
	
	# Check all 4 cells
	for dx in range(2):
		for dy in range(2):
			var cx = grid_pos.x + dx
			var cy = grid_pos.y + dy
			if cx >= GRID_WIDTH or cy >= GRID_HEIGHT:
				return false
			if grid[cx][cy] != CellState.EMPTY:
				return false
	return true

# Mark 2x2 cells as occupied by tower
func place_tower(world_pos: Vector2):
	var grid_pos = world_to_grid(world_pos)
	grid_pos.x = clampi(grid_pos.x, 0, GRID_WIDTH - 2)
	grid_pos.y = clampi(grid_pos.y, 0, GRID_HEIGHT - 2)
	
	for dx in range(2):
		for dy in range(2):
			grid[grid_pos.x + dx][grid_pos.y + dy] = CellState.TOWER

# Mark cells along the enemy path
func mark_path_cells(path_curve: Curve2D):
	if not path_curve:
		return
	var points = path_curve.get_baked_points()
	for point in points:
		var grid_pos = world_to_grid(point)
		if grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT:
			grid[grid_pos.x][grid_pos.y] = CellState.PATH
			# Also mark adjacent cells for wider path blocking
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var nx = grid_pos.x + dx
					var ny = grid_pos.y + dy
					if nx >= 0 and nx < GRID_WIDTH and ny >= 0 and ny < GRID_HEIGHT:
						if grid[nx][ny] == CellState.EMPTY:
							grid[nx][ny] = CellState.PATH

# Get grid position for debug/display
func get_cell_state(grid_pos: Vector2i) -> int:
	if grid_pos.x < 0 or grid_pos.x >= GRID_WIDTH or grid_pos.y < 0 or grid_pos.y >= GRID_HEIGHT:
		return CellState.BLOCKED
	return grid[grid_pos.x][grid_pos.y]
