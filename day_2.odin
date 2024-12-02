package day_2

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

EXAMPLE_PART_1 :: 2
EXAMPLE_PART_2 :: 5

RESULT_PART_1 :: 314
RESULT_PART_2 :: 373


Direction :: enum {
	INCREASE,
	DECREASE,
	UNKNOWN,
}

main :: proc() {
	fmt.println("Running day_2...")
	test_part_1("day_2_example_input", EXAMPLE_PART_1)
	test_part_2("day_2_example_input", EXAMPLE_PART_2)
	test_part_1("day_2_input", RESULT_PART_1)
	test_part_2("day_2_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> u64 {
	input := read_file(filename)
	parsed_input := parse_input(input)
	result :u64 = 0
	for l in parsed_input {
		if is_safe_report(l) {
			result += 1
		}
	}
	return result
}

part_2 :: proc(filename: string)  -> u64 {
	input := read_file(filename)
	parsed_input := parse_input(input)
	result :u64 = 0

	for l in parsed_input {
		if is_safe_report_second_part(l) {
			result += 1
		}
	}
	return result
}

test_part_1 :: proc(input: string, expected_result: u64) {
	part_1_result := part_1(input)
	fmt.assertf(part_1_result == expected_result, "(%s): part 1 result was %d and expected was %d",  input, part_1_result, expected_result)
	fmt.printf("(%s) part 1 result: %d\n", input, part_1_result)
}

test_part_2 :: proc(input: string, expected_result: u64) {
	part_2_result := part_2(input)
	fmt.assertf(part_2_result == expected_result, "(%s): part 2 result was %d and expected was %d",  input, part_2_result, expected_result)
	fmt.printf("(%s) part 2 result: %d\n", input, part_2_result)
}

read_file :: proc(filename: string) -> string {
	data, ok := os.read_entire_file(filename)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}

parse_input :: proc(input: string) -> [][]int {
	lines := strings.split(input, "\n")
	result := [dynamic][]int{}

	for line in lines {
		if line == "\n"  || line == "" {
			continue
		}

		numbers_str := strings.split(line, " ")
		// fmt.println(numbers_str)

		numbers_int := [dynamic]int{}
		for n,i in numbers_str {
			append(&numbers_int, strconv.atoi(n))
		}

		append(&result, numbers_int[:])
	}

	return result[:]
}


/*
    - The levels are either all increasing or all decreasing.
    - Any two adjacent levels differ by at least one and at most three.
*/
is_safe_report :: proc(report: []int) -> (result: bool) {
	dir := Direction.UNKNOWN
	d: Direction
	prev := -1

	for v, i in report {
		d = Direction.INCREASE if v > prev else Direction.DECREASE
		dif :=  abs(v-prev)
		check_dif := dif > 0 && dif < 4
		if i == 1 && check_dif {
			dir = d
			result = true
		} else if i > 1 && d == dir && check_dif {
			result = true
		} else if i > 0 {
			result = false
			return
		}

		prev = v
	}
	return
}


/*
    - The levels are either all increasing or all decreasing.
    - Any two adjacent levels differ by at least one and at most three.
	- Tolerate a single bad level.
*/
is_safe_report_second_part :: proc(report: []int, depth:int = 0) -> (result: bool) {
	dir := Direction.UNKNOWN
	d: Direction
	prev := -1

	for v, i in report {
		d = Direction.INCREASE if v > prev else Direction.DECREASE
		dif :=  abs(v-prev)
		check_dif := dif > 0 && dif < 4
		if i == 1 && check_dif {
			dir = d
			result = true
		} else if i > 1 && d == dir && check_dif {
			result = true
		} else if i > 0 {
			if depth > 0 {
				result = false
				return
			}

			// removing current value and check if it is safe
			wihtout_current := [dynamic]int{}
			append(&wihtout_current, ..report[:i])
			append(&wihtout_current, ..report[i+1:])
			is_valid_without_current := is_safe_report_second_part(wihtout_current[:], 1)
	

			// removing previous value and check if it is safe
			wihtout_previous := [dynamic]int{}
			append(&wihtout_previous, ..report[:i-1])
			append(&wihtout_previous, ..report[i:])
			is_valid_without_previous := is_safe_report_second_part(wihtout_previous[:], 1)

			// Edge case when removing the index 1 and 2 failed but if we would remove index 0 would succeed.
			// For example having [20, 21, 20, 18, 17] it would failed if we only check current and previous
			is_valid_without_two_previous := false
			if i > 1 {
				wihtout_two_previous := [dynamic]int{}
				append(&wihtout_two_previous, ..report[:i-2])
				append(&wihtout_two_previous, ..report[i-1:])
				is_valid_without_two_previous = is_safe_report_second_part(wihtout_two_previous[:], 1)		
			}
			
			result = is_valid_without_current || is_valid_without_previous || is_valid_without_two_previous
			return
		}

		prev = v
	}
	return
}