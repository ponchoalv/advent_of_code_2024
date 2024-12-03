package day_3

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

EXAMPLE_PART_1 :: 161
EXAMPLE_PART_2 :: 48

RESULT_PART_1 :: 187833789
RESULT_PART_2 :: 94455185

main :: proc() {
	fmt.println("Running day_3...")
	test_part_1("day_3_example_input", EXAMPLE_PART_1)
	test_part_2("day_3_example_input", EXAMPLE_PART_2)
	test_part_1("day_3_input", RESULT_PART_1)
	test_part_2("day_3_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	input := read_file(filename)
	matches := parse_input(input)

	for m in matches {
		result += u64(m.x * m.y)
	}

	return result
}

part_2 :: proc(filename: string)  -> (result: u64) {
	input := read_file(filename)
	matches := parse_input(input, true)

	for m in matches {
		result += u64(m.x * m.y)
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

/*
	- part 1: read only tokens with the format mul(N,M) where N and M are numbers from 1 to 3 digits.
	- part 2: include conditionals for do() and don't() to know if the mul(N,M) is enable or not
				by default is enable.
*/
parse_input :: proc(input: string, with_conditionals: bool = false) -> [][2]int {
	matches := [dynamic][2]int{}
	i := 0
	len_input := len(input)
	enable := true

	for i < len_input {
		if i + 4 <= len_input && input[i:i+4] == "mul("  && (enable || !with_conditionals) {
			i += 4

			x_start := i
			for i < len_input && '0' <= input[i] && input[i] <= '9' {
				i += 1
			}
			x := input[x_start:i]

			if len(x) < 1 || len(x) > 3 {
				continue
			}

			if i < len_input && input[i] == ',' {
				i += 1
			} else {
				continue
			}

			y_start := i
			for i < len_input && '0' <= input[i] && input[i] <= '9' {
				i += 1
			}
			y := input[y_start:i]

			if len(y) < 1 || len(y) > 3 {
				continue
			}

			if i < len_input && input[i] == ')' {
				i += 1
				append(&matches, [2]int{strconv.atoi(x), strconv.atoi(y)})
			}
		} else if i + 7 <= len_input && input[i:i+7] == "don't()" {
			enable = false
			i += 7
		} else if i + 4 <= len_input && input[i:i+4] == "do()" {
			enable = true
			i += 4
		} else {
			i += 1
		}
	}

	return matches[:]
}
