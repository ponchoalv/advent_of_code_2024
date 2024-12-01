package day_2

import "core:fmt"
import "core:os"

EXAMPLE_PART_1 :: 0
EXAMPLE_PART_2 :: 0

RESULT_PART_1 :: 0
RESULT_PART_2 :: 0

main :: proc() {
	fmt.println("Running day_2...")
	test_part_1("day_2_example_input", EXAMPLE_PART_1)
	test_part_2("day_2_example_input", EXAMPLE_PART_2)
	test_part_1("day_2_input", RESULT_PART_1)
	test_part_2("day_2_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> u64 {
	fmt.println("Hello day 1 part 1", filename)
	return 0
}

part_2 :: proc(input: string)  -> u64 {
	fmt.println("Hello day 1 part 2", input)
	return 0
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
