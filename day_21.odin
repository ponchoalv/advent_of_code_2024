package day_21

import bu "bit_utils"
import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

EXAMPLE_PART_1 :: 126384
EXAMPLE_PART_2 :: 154115708116294

RESULT_PART_1 :: 174124
RESULT_PART_2 :: 216668579770346

NUM_PAD := [][]rune {
	[]rune{'7', '8', '9'},
	[]rune{'4', '5', '6'},
	[]rune{'1', '2', '3'},
	[]rune{'#', '0', 'A'},
}

DIR_PAD := [][]rune{
	[]rune{'#', '^', 'A'}, 
	[]rune{'<', 'v', '>'},
}

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

// used for memo in recursive function
MemoData :: struct {
	seq:   string,
	depth: int,
}
// cache / memo for recursive function
memo := map[MemoData]u64{}

pre_calculated_moves := map[[2]rune][]string{}
pre_calculate_length := map[[2]rune]u64{}

main :: proc() {
	fmt.println("Running day_21...")
	
	start := time.now()
	
	// pre-calculate best movements from one digit to another in the pads
	// this implementation was a simple BFS with a cost tracking map so we only got all the best paths
	pre_calculate_pad_moves(NUM_PAD, &pre_calculated_moves)
	pre_calculate_pad_moves(DIR_PAD, &pre_calculated_moves)
	pre_calculate_pad_moves_length(pre_calculated_moves, &pre_calculate_length)
	
	elapsed := time.since(start)
	fmt.printf("time elapsed pre-calculating moves: %fms\n", time.duration_milliseconds(elapsed))	
	
	test_part_1("day_21_example_input", EXAMPLE_PART_1)
	test_part_2("day_21_example_input", EXAMPLE_PART_2)
	test_part_1("day_21_input", RESULT_PART_1)
	test_part_2("day_21_input", RESULT_PART_2)
}


/* The problem initially was solved by brute force (part 1)
	After part 2 some bits from part one stayed others were removed.
	pre_calculated moves was kept, improved, merged into one dictionary 
	so we could use them in a recursive function later on.
*/
part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)

	lines := strings.split_lines(input)
	for code in lines {
		if code == "" {continue}
		numeric_code, _ := strconv.parse_u64(code[:len(code) - 1])
		result +=
			count_movements_per_sequence(
				code,
				pre_calculated_moves,
				pre_calculate_length,
				1 + 2,
				&memo,
			) *
			numeric_code
	}

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}


part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)

	lines := strings.split_lines(input)
	for code in lines {
		if code == "" {continue}
		numeric_code, _ := strconv.parse_u64(code[:len(code) - 1])
		result +=
			count_movements_per_sequence(
				code,
				pre_calculated_moves,
				pre_calculate_length,
				1 + 25,
				&memo,
			) *
			numeric_code
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

	return result[:]
}

find_paths :: proc(pad: [][]rune, from, to: [2]int) -> []string {
	costs := make(map[[2]int]int, context.temp_allocator)

	q: sa.Small_Array(12, Move)
	result := make([dynamic]string)

	sa.push_back(&q, Move{position = from})

	outer: for sa.len(q) > 0 {
		cur := sa.pop_front(&q)

		if cur.position == to {
			new_buf, _ := slice.concatenate([][]rune{cur.buff, []rune{'A'}})
			append(&result, utf8.runes_to_string(new_buf))
			continue
		}

		for move in get_neighbours(pad, cur.position) {
			move_recored_cost, ok := costs[[2]int{move.position.x, move.position.y}]
			if !ok {
				move_recored_cost = max(int)
			}
			if len(cur.buff) < move_recored_cost {
				costs[[2]int{move.position.x, move.position.y}] = len(cur.buff) + 1

				new_buff, _ := slice.concatenate([][]rune{cur.buff, []rune{move.move}})
				sa.push_back(&q, Move{position = move.position, buff = new_buff})
			}
		}
	}
	return result[:]
}

pre_calculate_pad_moves :: proc(pad: [][]rune, result: ^map[[2]rune][]string) {
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


pre_calculate_pad_moves_length :: proc(
	pre_calc_moves: map[[2]rune][]string,
	result: ^map[[2]rune]u64,
) {
	for k, v in pre_calc_moves {
		if len(v) > 0 {
			result[k] = u64(len(v[0]))
		}
	}

	return
}

count_movements_per_sequence :: proc(
	code_seq: string,
	pre_calculated_moves: map[[2]rune][]string,
	pre_calculate_length: map[[2]rune]u64,
	depth: int,
	memo: ^map[MemoData]u64,
) -> u64 {
	if (MemoData{code_seq, depth}) in memo {
		return memo[MemoData{code_seq, depth}]
	}

	if depth == 1 {
		code_with_a, _ := slice.concatenate([][]rune{[]rune{'A'}, utf8.string_to_runes(code_seq)})

		zipped_combs := soa_zip(x = code_with_a, y = code_with_a[1:])
		result: u64 = 0

		for pp in zipped_combs {
			result += pre_calculate_length[{pp.x, pp.y}]
		}

		return result
	}

	code_with_a, err := slice.concatenate([][]rune{[]rune{'A'}, utf8.string_to_runes(code_seq)})

	zipped_combs := soa_zip(x = code_with_a, y = code_with_a[1:])
	result: u64 = 0
	for pp in zipped_combs {
		best: u64 = max(u64)
		for sub_seq in pre_calculated_moves[{pp.x, pp.y}] {
			sub_length := count_movements_per_sequence(
				sub_seq,
				pre_calculated_moves,
				pre_calculate_length,
				depth - 1,
				memo,
			)
			best = min(best, sub_length)
		}
		result += best
	}

	memo[MemoData{code_seq, depth}] = result

	return memo[MemoData{code_seq, depth}]
}
