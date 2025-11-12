package day_25

import "core:fmt"
import "core:os"
import "core:time"
import "core:strings"

EXAMPLE_PART_1 :: 3
RESULT_PART_1 :: 3155

main :: proc() {
	fmt.println("Running day_25...")
	test_part_1("day_25_example_input", EXAMPLE_PART_1)
	test_part_1("day_25_input", RESULT_PART_1)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	lines := strings.split_lines(input)

	parsing_lock := false

	locks := [dynamic][5]int{}
	keys := [dynamic][5]int{}

	i := 0
	temp_key_lock := [5]int{}
	for l in lines {
		if l == "" {
			i = 0
			if parsing_lock {
				append(&locks, temp_key_lock)
			} else {
				append(&keys, temp_key_lock)
			}

			temp_key_lock[0] = 0
			temp_key_lock[1] = 0
			temp_key_lock[2] = 0
			temp_key_lock[3] = 0
			temp_key_lock[4] = 0

			continue
		}

		if i == 0 && l == "#####" {
			parsing_lock=true
		} else if i == 0 {
			parsing_lock=false
		}

		temp_key_lock[0] += 1 if (parsing_lock && l[0] == '#') || (!parsing_lock && l[0] == '.') else 0
		temp_key_lock[1] += 1 if (parsing_lock && l[1] == '#') || (!parsing_lock && l[1] == '.') else 0
		temp_key_lock[2] += 1 if (parsing_lock && l[2] == '#') || (!parsing_lock && l[2] == '.') else 0
		temp_key_lock[3] += 1 if (parsing_lock && l[3] == '#') || (!parsing_lock && l[3] == '.') else 0
		temp_key_lock[4] += 1 if (parsing_lock && l[4] == '#') || (!parsing_lock && l[4] == '.') else 0

		i += 1
	}

	key_locks_matched := map[[2][5]int]bool{}

	for lock in locks {
		for key in keys {
			dif := key - lock
			fit := true

			fit &= dif[0] >= 0
			fit &= dif[1] >= 0
			fit &= dif[2] >= 0
			fit &= dif[3] >= 0
			fit &= dif[4] >= 0

			if fit {
				key_locks_matched[{lock,key}] = true
			}
		}
	}

	result = u64(len(key_locks_matched))

	elapsed := time.since(start)

	fmt.printf("time elapsed in part 1: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	// fmt.println(input)
	elapsed := time.since(start)

	fmt.printf("time elapsed in part 2: %fms\n", time.duration_milliseconds(elapsed))
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

read_file :: proc(filename: string) -> string {
	data, ok := os.read_entire_file(filename, context.temp_allocator)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}
