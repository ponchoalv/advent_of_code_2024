package day_18

import bu "bit_utils"
import qu "core:container/priority_queue"
import "aoc_search"
import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 22
EXAMPLE_PART_2 :: [2]int{1,6}

RESULT_PART_1 :: 454
RESULT_PART_2 :: [2]int{51,8}

EXAMPLE_GRID :: 7
REAL_GRID :: 71

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
		memory_grid = parse_grid(input, EXAMPLE_GRID, 12)
		target = memory_grid[EXAMPLE_GRID-1][EXAMPLE_GRID-1]
	} else {
		memory_grid = parse_grid(input, REAL_GRID, 1024)
		target = memory_grid[REAL_GRID-1][REAL_GRID-1]
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
	corrupted_base :=0

	if is_example {
		corrupted_base=12
		memory_grid = parse_grid(input, EXAMPLE_GRID, corrupted_base)
		target = memory_grid[EXAMPLE_GRID-1][EXAMPLE_GRID-1]
	} else {
		corrupted_base=1024
		memory_grid = parse_grid(input, REAL_GRID, corrupted_base)
		target = memory_grid[REAL_GRID-1][REAL_GRID-1]
	}

	start_tile := memory_grid[0][0]

	corruped_bytes := parse_corrup_bytes(input)
	walked_tiles := map[[2]int][dynamic][2]int{}

	// track all possible paths to the target
	start_2 := time.now()
	find_paths(memory_grid,start_tile,target,&walked_tiles, true)
	elapsed_2 := time.since(start)

	fmt.printf("time spent searching all paths: %fms\n", time.duration_milliseconds(elapsed_2))


	// remove from all possible trails to target the corruped bytes one by one in order
	start_3 := time.now()
	track := map[[2]int]bool{}
	q: queue.Queue([2]int)

	for i in corrupted_base..<len(corruped_bytes) {
		if _, found := walked_tiles[corruped_bytes[i]]; found {
			delete_key(&walked_tiles, corruped_bytes[i])
		} else {
			continue
		}

		queue.clear(&q)
		clear(&track)
		queue.push(&q, target.position)
		
		for queue.len(q) > 0 {
			cur := queue.pop_front(&q)
			if n, ok := walked_tiles[cur]; ok {
				for next in n {
					if _, found := track[next]; !found {
						track[next]=true
						queue.push(&q, next)
					}
				}
			}
		}

		if _, found := track[start_tile.position]; !found {
			result = corruped_bytes[i]
			break
		}
	}
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
		if new_coord.x >= 0 && new_coord.x < len(grid) && new_coord.y >= 0 && new_coord.y < len(grid) {
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

find_paths :: proc(grid: [][]Tile, start: Tile, target: Tile, walked_tiles: ^map[[2]int][dynamic][2]int, search_paths:bool = false) -> int {
	costs := map[[3]int]int{}
	q: qu.Priority_Queue(Tile)
	qu.init(&q, less, qu.default_swap_proc(Tile))
	qu.push(&q, start)

	for qu.len(q) > 0 {
		current := qu.pop(&q)

		if current.position == target.position {
			if search_paths {
				continue
			} else {
				return current.cost
			}
		} else {
			for move in get_neighbours(grid, current) {
				move_recorded_cost, ok := costs[[3]int{move.position.x, move.position.y, int(move.direction)}]
				if !ok {
					move_recorded_cost = max(int)
				}

				if current.cost + move.cost < move_recorded_cost {
					costs[[3]int{move.position.x, move.position.y, int(move.direction)}] = current.cost + move.cost
					move_n := Tile{}
					move_n = move
					move_n.cost = current.cost + move.cost
					qu.push(&q, move_n)
				}

				if search_paths {
					if v, found := walked_tiles[move.position]; found {
						append(&walked_tiles[move.position], current.position)
					} else {
						position := [dynamic][2]int{}
						append(&position, current.position)
						walked_tiles[move.position] = position
					}	
				}
			}
		}
	}
	return -1
}

parse_corrup_bytes :: proc(input:string) ->[][2]int {
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