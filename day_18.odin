package day_18

import "aoc_search"
import bu "bit_utils"
import ba "core:container/bit_array"
import qu "core:container/priority_queue"
import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 22
EXAMPLE_PART_2 :: [2]int{1, 6}

RESULT_PART_1 :: 454
RESULT_PART_2 :: [2]int{51, 8}

EXAMPLE_GRID_SIZE :: 7
REAL_GRID_SIZE :: 71

TileType :: enum {
	CORRUPTED,
	EMPTY,
}

Tile :: struct {
	type:      TileType,
	direction: bu.Direction,
	cost:      int,
	position:  [2]int,
}

main :: proc() {
	fmt.println("Running day_18...")
	is_example := true
	context.user_ptr = &is_example
	test_part_1("day_18_example_input", EXAMPLE_PART_1)
	test_part_2("day_18_example_input", EXAMPLE_PART_2)
	is_example = false
	test_part_1("day_18_input", RESULT_PART_1)
	test_part_2("day_18_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	is_example := (cast(^bool)context.user_ptr)^

	memory_grid := [][]Tile{}
	target := Tile{}
	walked_tiles := map[[2]int][dynamic][2]int{}

	if is_example {
		memory_grid = parse_grid(input, EXAMPLE_GRID_SIZE, 12)
		target = memory_grid[EXAMPLE_GRID_SIZE - 1][EXAMPLE_GRID_SIZE - 1]
	} else {
		memory_grid = parse_grid(input, REAL_GRID_SIZE, 1024)
		target = memory_grid[REAL_GRID_SIZE - 1][REAL_GRID_SIZE - 1]
	}

	start_tile := memory_grid[0][0]
	result = u64(aoc_search.dijkstra(memory_grid, start_tile, target, less, get_neighbours))

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: [2]int) {
	start := time.now()
	input := read_file(filename)

	is_example := (cast(^bool)context.user_ptr)^

	memory_grid := [][]Tile{}
	target := Tile{}
	corrupted_base := 0

	if is_example {
		corrupted_base = 12
		memory_grid = parse_grid(input, EXAMPLE_GRID_SIZE, corrupted_base)
		target = memory_grid[EXAMPLE_GRID_SIZE - 1][EXAMPLE_GRID_SIZE - 1]
	} else {
		corrupted_base = 1024
		memory_grid = parse_grid(input, REAL_GRID_SIZE, corrupted_base)
		target = memory_grid[REAL_GRID_SIZE - 1][REAL_GRID_SIZE - 1]
	}

	start_tile := memory_grid[0][0]

	corruped_bytes := parse_corrup_bytes(input)
	walked_tiles := map[[2]int][dynamic][2]int{}

	// track all possible paths to the target
	start_2 := time.now()
	find_paths(memory_grid, start_tile, target, &walked_tiles)
	elapsed_2 := time.since(start)

	fmt.printf("time spent searching all paths: %fms\n", time.duration_milliseconds(elapsed_2))


	// remove from all possible trails to target the corruped bytes one by one in order
	start_3 := time.now()
	result = find_blocking_corruped_byte(
		&walked_tiles,
		corruped_bytes,
		corrupted_base,
		start_tile,
		target,
	)

	elapsed_3 := time.since(start)
	fmt.printf("time spent searching all paths: %fms\n", time.duration_milliseconds(elapsed_3))

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

test_part_2 :: proc(input: string, expected_result: [2]int) {
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

parse_grid :: proc(input: string, grid_size: int, corruped_byes: int) -> [][]Tile {
	result := [dynamic][]Tile{}

	for y in 0 ..< grid_size {
		row := [dynamic]Tile{}
		for x in 0 ..< grid_size {
			tile := Tile{}
			tile.type = .EMPTY
			// first tile shouldn't have any cost
			tile.cost = 0 if x == 0 && y == 0 else 1
			tile.position = [2]int{y, x}
			append(&row, tile)
		}
		append(&result, row[:])
	}

	i := 0
	for line in strings.split_lines(input) {
		if line == "" {
			continue
		}

		if i == corruped_byes {
			break
		}

		coords := strings.split(line, ",")
		x := strconv.atoi(coords[0])
		y := strconv.atoi(coords[1])

		tile := result[y][x]
		tile.type = .CORRUPTED
		result[y][x] = tile

		i += 1
	}

	return result[:]
}

print_grid :: proc(grid: [][]Tile) {
	for y in 0 ..< len(grid) {
		for x in 0 ..< len(grid) {
			tile := grid[y][x]
			switch tile.type {
			case .CORRUPTED:
				fmt.print("#")
			case .EMPTY:
				fmt.print(".")
			}
		}
		fmt.println("")
	}

}

get_neighbours :: proc(grid: [][]Tile, current: Tile) -> []Tile {
	result := [dynamic]Tile{}

	for dir in bu.Direction {
		coord_dir := bu.Dir_Vec[dir]
		new_coord := current.position + coord_dir
		if new_coord.x >= 0 &&
		   new_coord.x < len(grid) &&
		   new_coord.y >= 0 &&
		   new_coord.y < len(grid) {
			tile := grid[new_coord.x][new_coord.y]
			if tile.type != .CORRUPTED {
				append(&result, tile)
			}
		}
	}

	return result[:]
}

less :: proc(a, b: Tile) -> bool {
	return a.cost < b.cost
}

find_paths :: proc(
	grid: [][]Tile,
	start: Tile,
	target: Tile,
	walked_tiles: ^map[[2]int][dynamic][2]int,
) -> int #no_bounds_check {
	costs := map[[3]int]int{}
	q: queue.Queue(Tile)
	queue.push(&q, start)

	for queue.len(q) > 0 {
		current := queue.pop_front(&q)

		if current.position == target.position {
			continue
		} else {
			for move in get_neighbours(grid, current) {
				if !(move.position in walked_tiles) {
					queue.push(&q, move)
					position := [dynamic][2]int{}
					append(&position, current.position)
					walked_tiles[move.position] = position
				} else {
					append(&walked_tiles[move.position], current.position)
				}
			}
		}
	}
	return -1
}

parse_corrup_bytes :: proc(input: string) -> [][2]int {
	result := [dynamic][2]int{}

	for line in strings.split_lines(input) {
		if line == "" {
			continue
		}

		parts := strings.split(line, ",")

		x := strconv.atoi(parts[1])
		y := strconv.atoi(parts[0])
		coord := [2]int{x, y}
		append(&result, coord)
	}

	return result[:]
}

find_blocking_corruped_byte :: proc(
	walked_tiles: ^map[[2]int][dynamic][2]int,
	corruped_bytes: [][2]int,
	starting_byte: int,
	start, target: Tile,
) -> [2]int {
	track: ba.Bit_Array
	q: queue.Queue([2]int)
	queue.reserve(&q, 1000)

	#no_bounds_check for i in starting_byte ..< len(corruped_bytes) {
		if found := corruped_bytes[i] in walked_tiles; found {
			delete_key(walked_tiles, corruped_bytes[i])
		} else {
			continue
		}

		queue.clear(&q)
		ba.clear(&track)
		queue.push(&q, target.position)

		for queue.len(q) > 0 {
			cur := queue.pop_front(&q)
			if n, ok := walked_tiles[cur]; ok {
				for next in n {
					found := ba.get(&track, bu.encode(u16(next.x), u16(next.y), 0))
					if !found {
						ba.set(&track, bu.encode(u16(next.x), u16(next.y), 0))
						queue.push(&q, next)
					}
				}
			}
		}

		found := ba.get(&track, bu.encode(u16(start.position.x), u16(start.position.y), 0))

		if !found {
			return corruped_bytes[i]
		}
	}
	return 0
}
