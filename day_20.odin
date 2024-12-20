package day_20

import "aoc_search"
import bu "bit_utils"
import qu "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 0
EXAMPLE_PART_2 :: 0

RESULT_PART_1 :: 1263
// RESULT_PART_1 :: 0
RESULT_PART_2 :: 957831


TileType :: enum {
	WALL,
	EMPTY,
	START,
	TARGET,
}

Tile :: struct {
	type:      TileType,
	direction: bu.Direction,
	cost:      int,
	position:  [2]int,
}

main :: proc() {
	fmt.println("Running day_20...")
	test_part_1("day_20_example_input", EXAMPLE_PART_1)
	test_part_2("day_20_example_input", EXAMPLE_PART_2)
	test_part_1("day_20_input", RESULT_PART_1)
	test_part_2("day_20_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	grid, start_tile, target := parse_grid(input)

	no_cheating_picoseconds, tiles_from_start := find_paths(grid, start_tile, target, false)
	_, tiles_from_end := find_paths(grid, target, start_tile, false)

	fmt.println("tiles_from_start", tiles_from_start[start_tile.position])
	fmt.println("tiles_from_end", tiles_from_end[start_tile.position])
	fmt.println("no_cheating_picoseconds", no_cheating_picoseconds)

	result = u64(
		get_cheating_2_picoseconds_fast(
			grid,
			100,
			no_cheating_picoseconds,
			tiles_from_start,
			tiles_from_end,
		),
	)

	fmt.println("count", result)

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	grid, start_tile, target := parse_grid(input)
	no_cheating_picoseconds, tiles_from_start := find_paths(grid, start_tile, target, true)
	_, tiles_from_end := find_paths(grid, target, start_tile, true)


	fmt.println("p2 tiles_from_start", tiles_from_start[start_tile.position])
	fmt.println("p2 tiles_from_end", tiles_from_end[start_tile.position])
	fmt.println("p2 no_cheating_picoseconds", no_cheating_picoseconds)


	result = u64(
		get_cheating_with_20_picosenconds(
			100,
			no_cheating_picoseconds,
			20,
			tiles_from_start,
			tiles_from_end,
		),
	)

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

parse_grid :: proc(input: string) -> (grid: [][]Tile, start: Tile, target: Tile) {
	result := [dynamic][]Tile{}
	lines := strings.split_lines(input)

	for line, y in lines {
		if line == "" {
			continue
		}
		row := [dynamic]Tile{}
		for x in 0 ..< len(line) {
			tile := Tile{}
			// first tile shouldn't have any cost
			tile.cost = 1
			tile.position = [2]int{y, x}
			if line[x] == '#' {
				tile.type = .WALL
			} else if line[x] == '.' {
				tile.type = .EMPTY
			} else if line[x] == 'S' {
				tile.type = .START
				tile.cost = 0
				start = tile
			} else if line[x] == 'E' {
				tile.type = .TARGET
				target = tile
			}
			append(&row, tile)
		}
		append(&result, row[:])

	}

	grid = result[:]
	return
}

print_grid :: proc(grid: [][]Tile) {
	for y in 0 ..< len(grid) {
		for x in 0 ..< len(grid[0]) {
			tile := grid[y][x]
			switch tile.type {
			case .WALL:
				fmt.print("#")
			case .EMPTY:
				fmt.print(".")
			case .START:
				fmt.print("S")
			case .TARGET:
				fmt.print("E")
			}
		}
		fmt.println("")
	}
}

find_paths :: proc(grid: [][]Tile, start: Tile, target: Tile, walls:bool) -> (int, map[[2]int]int) {
	costs := map[[2]int]int{}
	tracked_with_walls := map[[2]int]int{}

	q: qu.Queue(Tile)
	qu.push(&q, start)

	for qu.len(q) > 0 {
		current := qu.pop_front(&q)

		if current.position == target.position {
			if walls {
				return current.cost, costs
			} else {
				return current.cost, tracked_with_walls
			}
		} else {
			for move in get_neighbours(grid, current, walls) {
				move_recorded_cost, ok := costs[[2]int{move.position.x, move.position.y}]
				if !ok {
					move_recorded_cost = max(int)
				}

				if current.cost + move.cost < move_recorded_cost {
					costs[[2]int{move.position.x, move.position.y}] = current.cost + move.cost
					move_n := Tile{}
					move_n = move
					move_n.cost = current.cost + move.cost

					if move_n.type != .WALL {
						qu.push(&q, move_n)
					}

					if !walls {
						tracked_with_walls[move_n.position] = current.cost + move.cost
					}
				}
			}
		}
	}
	return -1, costs
}

get_neighbours :: proc(grid: [][]Tile, current: Tile, walls: bool) -> []Tile {
	result := [dynamic]Tile{}

	for dir in bu.Direction {
		coord_dir := bu.Dir_Vec[dir]
		new_coord := current.position + coord_dir
		if new_coord.x >= 0 &&
		   new_coord.x < len(grid) &&
		   new_coord.y >= 0 &&
		   new_coord.y < len(grid) {
			tile := grid[new_coord.x][new_coord.y]
			if !walls || (walls && tile.type != .WALL) {
				append(&result, tile)
			}
		}
	}

	return result[:]
}

// We can do it this way because the "cheated" Tiles are always next to the current tile in the path
// this way we can get the distance from the adyacent wall to the target and then addit to the cost/tiles so far
// sadly this approach wasn't usefull for part two where I have to find all the tiles whithin 20 tiles of distance and then get the sum of both.
get_cheating_2_picoseconds_fast :: proc(
	grid: [][]Tile,
	threshold: int,
	picoseconds: int,
	tiles_from_start: map[[2]int]int,
	tiles_from_end: map[[2]int]int,
) -> int {
	count := 0
	for y in 1 ..< len(grid) {
		for x in 1 ..< len(grid[0]) {
			if grid[y][x].type == .WALL {	
				current_pos := [2]int{y, x}
				if current_pos in tiles_from_start && current_pos in tiles_from_end {
					if (tiles_from_start[current_pos] -1 + tiles_from_end[current_pos] - 1) <= picoseconds - threshold {
						count += 1
					}
				}
			}
		}
	}
	return count
}

// Sadly, the approach used for part one was not working in part two because of the distance, so I wrote this version which can be used for part 1 and 2, but it will be significantly slower.
get_cheating_with_20_picosenconds :: proc(
	threshold: int,
	no_cheating_picoseconds: int,
	picoseconds_cheat: int,
	tiles_from_start: map[[2]int]int,
	tiles_from_end: map[[2]int]int,
) -> int {
	count := 0
	for from_start in tiles_from_start {
		for from_end in tiles_from_end {
			dist := manhatan_distance(from_start, from_end)
			if dist <= picoseconds_cheat {
				if tiles_from_start[from_start] - 1 + dist + tiles_from_end[from_end] - 1 <= no_cheating_picoseconds - threshold {
					count += 1
				}
			}
		}
	}
	return count
}

manhatan_distance :: proc(a, b: [2]int) -> int {
	return abs(a.x - b.x) + abs(a.y - b.y)
}
