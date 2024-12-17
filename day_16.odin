package day_16

import bu "bit_utils"
import qu "core:container/priority_queue"
import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 7036
EXAMPLE_PART_2 :: 45

RESULT_PART_1 :: 93436
RESULT_PART_2 :: 486


TileType :: enum {
	REINDEER,
	WALL,
	TARGET,
	EMPTY,
}

Tile :: struct {
	position:  [2]int,
	type:      TileType,
	direction: bu.Direction,
	cost:      int,
}

main :: proc() {
	fmt.println("Running day_16...")
	test_part_1("day_16_example_input", EXAMPLE_PART_1)
	test_part_2("day_16_example_input", EXAMPLE_PART_2)
	test_part_1("day_16_input", RESULT_PART_1)
	test_part_2("day_16_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	reindeer, target, maze := parse_maze(input)

	score, count, _, found := find_paths(maze, reindeer, target)
	result = u64(score)
	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	reindeer, target, maze := parse_maze(input)

	score, walked_trails, best_targets, found := find_paths(maze, reindeer, target, true)

	result = u64(get_best_spots(maze, best_targets, walked_trails))

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

parse_maze :: proc(input: string) -> (reindeer: Tile, target: Tile, maze_result: [][]Tile) {
	lines := strings.split_lines(input)

	maze := [dynamic][]Tile{}

	for l, y in lines {
		if l == "" {
			continue
		}

		maze_tiles := [dynamic]Tile{}

		for c, x in l {
			tile := Tile{}
			switch c {
			case '#':
				tile.type = .WALL
				tile.position = [2]int{y, x}
				append(&maze_tiles, tile)
			case 'E':
				tile.type = .TARGET
				tile.position = [2]int{y, x}
				target = tile
				append(&maze_tiles, tile)
			case 'S':
				tile.type = .REINDEER
				tile.position = [2]int{y, x}
				tile.direction = .FORWARD
				reindeer = tile
				append(&maze_tiles, tile)
			case:
				tile.type = .EMPTY
				tile.position = [2]int{y, x}
				append(&maze_tiles, tile)
			}

		}
		append(&maze, maze_tiles[:])
	}
	maze_result = maze[:]
	return
}

get_neighbours :: proc(maze: [][]Tile, current: Tile) -> []Tile {
	neighbours := [dynamic]Tile{}

	// look for the sides
	for dir in bu.get_direction_left_right(current.direction) {
		dc := current.position + bu.Dir_Vec[dir]
		cur_tile := maze[dc.x][dc.y]
		cur_tile.direction = dir
		cur_tile.cost = 1001
		if cur_tile.type == .EMPTY || cur_tile.type == .TARGET {
			append(&neighbours, cur_tile)
		}
	}

	// look forward
	fwrd := current.position + bu.Dir_Vec[current.direction]
	cur_tile := maze[fwrd.x][fwrd.y]
	cur_tile.direction = current.direction
	cur_tile.cost = 1
	if cur_tile.type == .EMPTY || cur_tile.type == .TARGET {
		append(&neighbours, cur_tile)
	}

	return neighbours[:]
}

less :: proc(a, b: Tile) -> bool {
	return a.cost <= b.cost
}

find_paths :: proc(
	maze: [][]Tile,
	start: Tile,
	target: Tile,
	count_tiles: bool = false,
) -> (
	int,
	map[[3]int][dynamic][3]int,
	[][3]int,
	bool,
) {
	costs := map[[3]int]int{}
	q: qu.Priority_Queue(Tile)
	qu.init(&q, less, qu.default_swap_proc(Tile))
	qu.push(&q, start)
	visited := map[[3]int][dynamic][3]int{}
	best_targets := [dynamic][3]int{}
	best_score := -1

	for qu.len(q) > 0 {
		current := qu.pop(&q)

		if current.position == target.position {
			if count_tiles {
				if best_score == -1 || current.cost <= best_score {
					best_score = current.cost
					append(
						&best_targets,
						[3]int{current.position.x, current.position.y, int(current.direction)},
					)
				}
				continue
			} else {
				return current.cost, visited, best_targets[:], true
			}
		} else {
			for move in get_neighbours(maze, current) {
				move_recorded_cost, ok :=
					costs[[3]int{move.position.x, move.position.y, int(move.direction)}]
				if !ok {
					move_recorded_cost = 999999999
				}
				if current.cost + move.cost < move_recorded_cost {
					costs[[3]int{move.position.x, move.position.y, int(move.direction)}] =
						current.cost + move.cost
					move_n := Tile{}
					move_n = move
					move_n.cost = current.cost + move.cost
					qu.push(&q, move_n)
					if v, ok :=
						   visited[[3]int{move.position.x, move.position.y, int(move.direction)}];
					   ok {
						new_list := [dynamic][3]int{}
						append(
							&new_list,
							[3]int{current.position.x, current.position.y, int(current.direction)},
						)
						append(&new_list, v[0])
						visited[[3]int{move.position.x, move.position.y, int(move.direction)}] =
							new_list
					} else {
						new_list := [dynamic][3]int{}
						append(
							&new_list,
							[3]int{current.position.x, current.position.y, int(current.direction)},
						)
						visited[[3]int{move.position.x, move.position.y, int(move.direction)}] =
							new_list
					}
				} else if current.cost + move.cost <= move_recorded_cost {
					if v, ok :=
						   visited[[3]int{move.position.x, move.position.y, int(move.direction)}];
					   ok {
						new_list := [dynamic][3]int{}
						append(
							&new_list,
							[3]int{current.position.x, current.position.y, int(current.direction)},
						)
						append(&new_list, v[0])
						visited[[3]int{move.position.x, move.position.y, int(move.direction)}] =
							new_list
					} else {
						new_list := [dynamic][3]int{}
						append(
							&new_list,
							[3]int{current.position.x, current.position.y, int(current.direction)},
						)
						visited[[3]int{move.position.x, move.position.y, int(move.direction)}] =
							new_list
					}
				}
			}
		}
	}
	return -1, visited, best_targets[:], false
}

print_walked_grid :: proc(maze: [][]Tile, nodes: map[[2]int]bool) {
	for y in 0 ..< len(maze) {
		for x in 0 ..< len(maze[0]) {

			switch maze[y][x].type {
			case .REINDEER:
				fmt.print("S")
			case .TARGET:
				fmt.print("E")
			case .WALL:
				fmt.print("#")
			case .EMPTY:
				if _, ok := nodes[[2]int{y, x}]; ok {
					fmt.print("O")
				} else {
					fmt.print(".")
				}
			}
		}
		fmt.println("")
	}
}

get_best_spots :: proc(
	maze: [][]Tile,
	best_targets: [][3]int,
	walked_trails: map[[3]int][dynamic][3]int,
) -> int {
	q: queue.Queue([3]int)
	nodes := map[[2]int]bool{}

	for tg in best_targets {
		queue.push(&q, tg)
		nodes[[2]int{tg.x, tg.y}] = true
	}

	for queue.len(q) > 0 {
		cur := queue.pop_back(&q)
		if n, ok := walked_trails[cur]; ok {
			for next in n {
				nodes[[2]int{next.x, next.y}] = true
				queue.push(&q, next)
			}
		}
	}

	print_walked_grid(maze, nodes)
	return len(nodes)
}
