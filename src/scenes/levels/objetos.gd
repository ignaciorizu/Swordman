extends TileMapLayer

const DESTRUCTIBLE_PHYSICS_INDEX: int = 1
const EMPTY_TILE_SOURCE: int = -1

func process_impact(impact_global_position: Vector2) -> void:
	var local_position: Vector2 = to_local(impact_global_position)
	var map_coordinates: Vector2i = local_to_map(local_position)
	var tile_data: TileData = get_cell_tile_data(map_coordinates)

	validate_and_destroy_tile(map_coordinates, tile_data)

func validate_and_destroy_tile(map_coordinates: Vector2i, tile_data: TileData) -> void:
	if tile_data == null:
		return

	set_cell(map_coordinates, EMPTY_TILE_SOURCE)
