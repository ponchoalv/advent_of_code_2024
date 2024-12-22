package day_21

import "aoc_search"
import "aoc_strings"
import "base:builtin"
import bu "bit_utils"
import "core:container/queue"
import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

EXAMPLE_PART_1 :: 126384
EXAMPLE_PART_2 :: 2536798

RESULT_PART_1 :: 174124
RESULT_PART_2 :: 3197436
// 3197436
// 2025830

NUM_PAD := [][]rune {
	[]rune{'7', '8', '9'},
	[]rune{'4', '5', '6'},
	[]rune{'1', '2', '3'},
	[]rune{'#', '0', 'A'},
}

DIR_PAD := [][]rune{
	[]rune{'#', '^', 'A'}, 
	[]rune{'<', 'v', '>'}}

Move :: struct {
	position: [2]int,
	move:     rune,
	buff:     []rune,
}

Direction_Move_Vector :: [bu.Direction]rune {
	.FORWARD  = '>',
	.DOWN     = 'v',
	.BACKWARD = '<',
	.UP       = '^',
}

Dir_Move := Direction_Move_Vector

main :: proc() {
	fmt.println("Running day_21...")
	test_part_1("day_21_example_input", EXAMPLE_PART_1)
	test_part_2("day_21_example_input", EXAMPLE_PART_2)
	test_part_1("day_21_input", RESULT_PART_1)
	test_part_2("day_21_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)

	num_pad_moves := pre_calculate_pad_moves(NUM_PAD)
	fmt.println(num_pad_moves)

	dir_pad_moves := pre_calculate_pad_moves(DIR_PAD)
	fmt.println(dir_pad_moves)

	dir_pad_length := pre_calculate_pad_moves_length(dir_pad_moves)
	fmt.println(dir_pad_length)

	lines := strings.split_lines(input)

	for code in lines {
		if code == "" {continue}

		numeric_code, _ := strconv.parse_u64(code[:len(code) - 1])


		first_robot_movements := get_movements_for_first_robot(code, num_pad_moves)

		best: u64 = max(u64)

		for moves in first_robot_movements {
			code_with_a, _ := slice.concatenate([][]rune{[]rune{'A'}, utf8.string_to_runes(moves)})
			zipped_combs := soa_zip(x = code_with_a, y = code_with_a[1:])

			length: u64= 0
			
			for pair in zipped_combs {
				memo := map[[2]rune]u64{}
				length += r_r_movements_length({pair.x, pair.y}, dir_pad_moves, dir_pad_length, 2, &memo)
			}
			best = min(best,length)
		}

		fmt.println(best)


		// tengo que hacer esto de forma recursiva y con memoization
		// first_robot := get_movements_second_robot(first_robot_movements, dir_pad_moves)
		// second_robot := get_movements_second_robot(first_robot, dir_pad_moves)

		result += best * numeric_code
		fmt.println(result)

		// free_all(context.temp_allocator)
	}


	// context.allocator = allocator
	// fmt.println(num_pad_moves)
	// fmt.println(dir_pad_moves)

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)

	lines := strings.split_lines(input)
	num_pad_moves := pre_calculate_pad_moves(NUM_PAD)
	dir_pad_moves := pre_calculate_pad_moves(DIR_PAD)
	dir_pad_length := pre_calculate_pad_moves_length(dir_pad_moves)

	for code in lines {
		if code == "" {continue}

		numeric_code, _ := strconv.parse_u64(code[:len(code) - 1])

		first_robot_movements := get_movements_for_first_robot(code, num_pad_moves)

		best: u64 = max(u64)

		for moves in first_robot_movements {
			code_with_a, _ := slice.concatenate([][]rune{[]rune{'A'}, utf8.string_to_runes(moves)})
			zipped_combs := soa_zip(x = code_with_a, y = code_with_a[1:])

			length: u64= 0
			for pair in zipped_combs {
				memo := map[[2]rune]u64{}
				length += r_r_movements_length({pair.x, pair.y}, dir_pad_moves,dir_pad_length, 25, &memo)
			}
			best = min(best,length)
		}

		fmt.println(best, numeric_code, result)

		result += (best * numeric_code)
	}

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
	data, ok := os.read_entire_file(filename)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}

get_neighbours :: proc(grid: [][]rune, current: [2]int) -> []Move {
	result := make([dynamic]Move, context.temp_allocator)

	for dir in bu.Direction {
		coord_dir := bu.Dir_Vec[dir]
		new_coord := current + coord_dir
		if new_coord.x >= 0 &&
		   new_coord.x < len(grid) &&
		   new_coord.y >= 0 &&
		   new_coord.y < len(grid[0]) {
			key := grid[new_coord.x][new_coord.y]
			if key != '#' {
				move := Move {
					position = new_coord,
					move     = Dir_Move[dir],
				}
				append(&result, move)
			}
		}
	}

	// fmt.println("moves", current, result)

	return result[:]
}

find_paths :: proc(pad: [][]rune, from, to: [2]int) -> []string {
	costs := make(map[[2]int]int, context.temp_allocator)

	q: queue.Queue(Move)
	result := make([dynamic]string)
	optimal_len := max(int)

	queue.push_back(&q, Move{position = from})

	outer: for queue.len(q) > 0 {
		cur := queue.pop_front(&q)

		if cur.position == to {
			new_buf, _ := slice.concatenate([][]rune{cur.buff, []rune{'A'}})
			append(&result, utf8.runes_to_string(new_buf))
		}

		for move in get_neighbours(pad, cur.position) {
			move_recored_cost, ok := costs[[2]int{move.position.x, move.position.y}]
			if !ok {
				move_recored_cost = max(int)
			}
			if len(cur.buff) < move_recored_cost {
				costs[[2]int{move.position.x, move.position.y}] = len(cur.buff) + 1

				new_buff, _ := slice.concatenate([][]rune{cur.buff, []rune{move.move}})
				queue.push_back(&q, Move{position = move.position, buff = new_buff})
			}
		}
	}
	return result[:]
}

pre_calculate_pad_moves :: proc(pad: [][]rune) -> (result: map[[2]rune][]string) {
	for r in 0 ..< len(pad) {
		for c in 0 ..< len(pad[0]) {
			for r1 in 0 ..< len(pad) {
				for c1 in 0 ..< len(pad[0]) {
					if pad[r][c] != '#' && pad[r1][c1] != '#' {
						result[{pad[r][c], pad[r1][c1]}] = find_paths(pad, {r, c}, {r1, c1})
					}
				}
			}
		}
	}
	return
}


pre_calculate_pad_moves_length :: proc(pre_calc_moves: map[[2]rune][]string) -> (result: map[[2]rune]u64) {
	for k, v in pre_calc_moves {
		result[k]=u64(len(v[0]))
	}

	return
}

get_movements_for_first_robot :: proc(
	code: string,
	num_pad_moves: map[[2]rune][]string,
) -> []string {
	movements_per_pair := make([dynamic][]string, context.temp_allocator)
	code_with_a, _ := slice.concatenate(
		[][]rune{[]rune{'A'}, utf8.string_to_runes(code)},
		context.temp_allocator,
	)
	zipped_combs := soa_zip(x = code_with_a, y = code_with_a[1:])

	for pair in zipped_combs {
		append(&movements_per_pair, num_pad_moves[{pair.x, pair.y}])
	}

	return aoc_strings.generateCombinations(movements_per_pair[:])
}

get_movements_second_robot :: proc(
	moves: []string,
	dir_pad_moves: map[[2]rune][]string,
) -> []string {
	result := make([dynamic]string, context.temp_allocator)

	for move in moves {
		append(&result, ..get_movements_for_first_robot(move, dir_pad_moves))
	}


	// fmt.println(len(result))
	// fmt.println(min_size)/
	min_size := get_shortest_string_size(result[:])
	filtered := aoc_search.filter_by_with_param(
		result[:],
		min_size,
		proc(s: string, min_size: int) -> bool {return min_size == len(s)},
		context.temp_allocator,
	)
	// fmt.println(len(filtered))

	return filtered
}

r_r_movements_length :: proc(
	pair: [2]rune,
	dir_pad_moves: map[[2]rune][]string,
	dir_pad_length: map[[2]rune]u64,
	depth: int,
	memo: ^map[[2]rune]u64,
) -> u64 {
	if pair in memo {
		return memo[pair]
	}

	if depth == 1 {
		return dir_pad_length[pair]
	}

	best: u64 = max(u64)

	for xs in dir_pad_moves[pair] {
		result: u64 = 0
		code_with_a, err := slice.concatenate([][]rune{[]rune{'A'}, utf8.string_to_runes(xs)})
		if err != nil {
			panic("something happened")
		}

		zipped_combs := soa_zip(x = code_with_a, y = code_with_a[1:])

		for pair in zipped_combs {
			result += r_r_movements_length({pair.x, pair.y}, dir_pad_moves, dir_pad_length, depth - 1, memo)
		}

		best = min(best, result)
	}

	memo[pair] = best

	return memo[pair]
}


get_shortest_string_size :: proc(list: []string) -> int {
	min := max(int)
	for l in list {
		min = builtin.min(min, len(l))
	}

	return min
}
