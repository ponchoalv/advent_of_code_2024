package day_15

import bu "bit_utils"
import ba "core:container/bit_array"
import qu "core:container/queue"
import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 10092
EXAMPLE_PART_2 :: 9021

RESULT_PART_1 :: 1442192
RESULT_PART_2 :: 1448458

TileType :: enum {
	WALL,
	BOX,
	LEFT_BOX,
	RIGHT_BOX,
	EMPTY,
	ROBOT,
}

WarehouseTile :: struct {
	type:     TileType,
	position: [2]int,
}

main :: proc() {
	fmt.println("Running day_15...")
	test_part_1("day_15_example_input", EXAMPLE_PART_1)
	test_part_2("day_15_example_input", EXAMPLE_PART_2)
	test_part_1("day_15_input", RESULT_PART_1)
	test_part_2("day_15_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	robot_pos, warehouse_map, moves := parse_warehouse_robot(input)
	robot := warehouse_map[robot_pos.x][robot_pos.y]

	print_warehouse(warehouse_map)

	for direction in moves {
		robot = move(&warehouse_map, robot, direction)
	}

	print_warehouse(warehouse_map)

	result = sum_coordinates(warehouse_map)

	elapsed := time.since(start)
	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	robot_pos, warehouse_map, moves := parse_warehouse_robot(input, true)
	print_warehouse(warehouse_map)

	robot := warehouse_map[robot_pos.x][robot_pos.y]

	for dir in moves {
		robot = move(&warehouse_map, robot, dir)
	}

	print_warehouse(warehouse_map)

	result = sum_coordinates(warehouse_map)

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

test_part_1 :: proc(input: string, expected_result: u64) {
	part_1_result := part_1(input)
	fmt.assertf(
		part_1_result == expected_result,
		"(%s): part 1 result was %d and expected was %d",
		input,
		part_1_result,
		expected_result,
	)
	fmt.printf("(%s) part 1 result: %d\n", input, part_1_result)
}

test_part_2 :: proc(input: string, expected_result: u64) {
	part_2_result := part_2(input)
	fmt.assertf(
		part_2_result == expected_result,
		"(%s): part 2 result was %d and expected was %d",
		input,
		part_2_result,
		expected_result,
	)
	fmt.printf("(%s) part 2 result: %d\n", input, part_2_result)
}

read_file :: proc(filename: string) -> string {
	data, ok := os.read_entire_file(filename, context.temp_allocator)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}

parse_warehouse_robot :: proc(
	input: string,
	extended: bool = false,
) -> (
	robot_poss: [2]int,
	warehousemap: [][]WarehouseTile,
	moves: []bu.Direction,
) {
	lines := strings.split_lines(input)
	parsing_grid := true

	warehouse_map := [dynamic][]WarehouseTile{}
	moves_dyn := [dynamic]bu.Direction{}

	for l, y in lines {
		if l == "" {
			parsing_grid = false
		}

		if parsing_grid {
			warehouse_tiles := [dynamic]WarehouseTile{}
			x_correction := 0
			for c, x in l {
				tile := WarehouseTile{}
				switch c {
				case '#':
					tile.type = .WALL
					tile.position = [2]int{y, x + x_correction}
					append(&warehouse_tiles, tile)
					if extended {
						second_tile := tile
						second_tile.position = tile.position + {0, 1}
						append(&warehouse_tiles, second_tile)
					}
				case 'O':
					if extended {
						tile.type = .LEFT_BOX
						tile.position = [2]int{y, x + x_correction}
						append(&warehouse_tiles, tile)

						right_tile := tile
						right_tile.type = .RIGHT_BOX
						right_tile.position = [2]int{y, x + x_correction + 1}
						append(&warehouse_tiles, right_tile)
					} else {
						tile.type = .BOX
						tile.position = [2]int{y, x + x_correction}
						append(&warehouse_tiles, tile)
					}
				case '@':
					tile.type = .ROBOT
					robot_poss = [2]int{y, x + x_correction}
					tile.position = robot_poss
					append(&warehouse_tiles, tile)

					if extended {
						tile.type = .EMPTY
						tile.position = robot_poss + {0, 1}
						append(&warehouse_tiles, tile)
					}
				case:
					tile.type = .EMPTY
					tile.position = [2]int{y, x + x_correction}
					append(&warehouse_tiles, tile)

					if extended {
						tile.position = tile.position + {0, 1}
						append(&warehouse_tiles, tile)
					}
				}

				if extended {
					x_correction += 1
				}
			}
			append(&warehouse_map, warehouse_tiles[:])
		} else {
			for c, x in l {
				switch c {
				case '^':
					append(&moves_dyn, bu.Direction.UP)
				case 'v':
					append(&moves_dyn, bu.Direction.DOWN)
				case '<':
					append(&moves_dyn, bu.Direction.BACKWARD)
				case '>':
					append(&moves_dyn, bu.Direction.FORWARD)
				}
			}
		}
	}

	warehousemap = warehouse_map[:]
	moves = moves_dyn[:]

	return
}

print_warehouse :: proc(warehouse_map: [][]WarehouseTile, extended: bool = false) {
	for y in 0 ..< len(warehouse_map) {
		for x in 0 ..< len(warehouse_map[0]) {

			switch warehouse_map[y][x].type {
			case .BOX:
				fmt.print("O")
			case .LEFT_BOX:
				fmt.print("[")
			case .RIGHT_BOX:
				fmt.print("]")
			case .WALL:
				fmt.print("#")
			case .EMPTY:
				fmt.print(".")
			case .ROBOT:
				fmt.print("@")
			}
		}
		fmt.println("")
	}
}

sum_coordinates :: proc(warehouse_map: [][]WarehouseTile) -> (result: u64) {
	for y in 0 ..< len(warehouse_map) {
		for x in 0 ..< len(warehouse_map[0]) {
			if warehouse_map[y][x].type == .LEFT_BOX || warehouse_map[y][x].type == .BOX {
				result += u64(x + (100 * y))
			}
		}
	}

	return
}

move :: proc(
	warehouse_map: ^[][]WarehouseTile,
	robot: WarehouseTile,
	direction: bu.Direction,
) -> WarehouseTile {
	// q: qu.Queue(WarehouseTile)
	q: sa.Small_Array(10, WarehouseTile)

	sa.push(&q, robot)
	tracked_tiles := [dynamic]WarehouseTile{}
	track_tiles_set := map[[2]int]bool{}
	append(&tracked_tiles, robot)

	for sa.len(q) > 0 {
		current := sa.pop_front(&q)
		// fmt.println(current)

		if current.type == .WALL {
			return robot
		} else if current.type == .LEFT_BOX {
			right := current.position + bu.Dir_Vec[.FORWARD]

			if _, found := track_tiles_set[right]; !found {
				right_tile := warehouse_map[right.x][right.y]
				append(&tracked_tiles, right_tile)
				sa.push(&q, right_tile)
				track_tiles_set[right] = true
			}
		} else if current.type == .RIGHT_BOX {
			left := current.position + bu.Dir_Vec[.BACKWARD]
			if _, found := track_tiles_set[left]; !found {
				left_tile := warehouse_map[left.x][left.y]
				append(&tracked_tiles, left_tile)
				sa.push(&q, left_tile)
				track_tiles_set[left] = true
			}
		} else if current.type == .EMPTY {
			continue
		}

		next := current.position + bu.Dir_Vec[direction]
		next_tile := warehouse_map[next.x][next.y]
		append(&tracked_tiles, next_tile)
		sa.push(&q, next_tile)
		track_tiles_set[next] = true
	}

	// update tiles positions
	empty_tile := WarehouseTile {
		type = .EMPTY,
	}

	for i in 0 ..< len(tracked_tiles) {
		tile := tracked_tiles[i]
		// clean all to change tiles
		empty_tile.position = tile.position
		warehouse_map[empty_tile.position.x][empty_tile.position.y] = empty_tile

		if tile.type == .EMPTY {
			continue
		} else {
			tile.position = tile.position + bu.Dir_Vec[direction]
		}

		tracked_tiles[i] = tile
	}

	// move all non-empty tiles
	for tile in tracked_tiles {
		if tile.type != .EMPTY {
			warehouse_map[tile.position.x][tile.position.y] = tile
		}
	}

	return tracked_tiles[0]
}
