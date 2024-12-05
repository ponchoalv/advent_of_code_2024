package day_5

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 143
EXAMPLE_PART_2 :: 123

RESULT_PART_1 :: 6260
RESULT_PART_2 :: 5346

// pages are not higher than 99
N :: 100

PageRule :: struct {
	childs: [N]bool,
}

page_rules: [N]PageRule = {}

main :: proc() {
	fmt.println("Running day_5...")
	test_part_1("day_5_example_input", EXAMPLE_PART_1)
	test_part_2("day_5_example_input", EXAMPLE_PART_2)
	test_part_1("day_5_input", RESULT_PART_1)
	test_part_2("day_5_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	page_number_inputs := parse_input(input)
	for &page_numbers in page_number_inputs {
		if is_valid, middle := validate_print_order(&page_numbers); is_valid {
			result += u64(middle)
		}
	}
	elapsed := time.since(start)
	fmt.printf("time elapsed: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	fmt.println("Hello day 1 part 2", filename)
	start := time.now()
	input := read_file(filename)
	page_number_inputs := parse_input(input)
	for &page_numbers in page_number_inputs {
		if is_valid, middle := validate_print_order(&page_numbers); !is_valid {
			re_order_pages(&page_numbers)
			result += u64(page_numbers[len(page_numbers) / 2])
		}
	}

	elapsed := time.since(start)
	fmt.printf("time elapsed: %fms\n", time.duration_milliseconds(elapsed))
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

parse_input :: proc(input: string) -> [][]int #no_bounds_check {
	page_print_inputs := [dynamic][]int{}
	parsing_rule := true

	for v in strings.split_lines(input) {
		if v == "" {
			parsing_rule = false
			continue
		}

		if parsing_rule {
			start_end := strings.split(v, "|")
			page_rules[strconv.atoi(start_end[0])].childs[strconv.atoi(start_end[1])] = true
		} else {
			pages_str := strings.split(v, ",")
			pages_int := [dynamic]int{}

			for p in pages_str {
				append(&pages_int, strconv.atoi(p))
			}
			append(&page_print_inputs, pages_int[:])
		}
	}

	return page_print_inputs[:]
}

validate_print_order :: proc(page_numbers: ^[]int) -> (bool, int) #no_bounds_check {
	is_valid := false
	outer: for page, i in page_numbers {
		for child in page_numbers[i + 1:] {
			is_valid = page_rules[page].childs[child]
			if !is_valid {
				break outer
			}
		}
	}

	return is_valid, page_numbers[len(page_numbers) / 2]
}

re_order_pages :: proc(page_numbers: ^[]int) #no_bounds_check {
	page_greater_than :: proc(i, j: int) -> bool {
		return page_rules[i].childs[j]
	}

	slice.sort_by(page_numbers[:], page_greater_than)
}
