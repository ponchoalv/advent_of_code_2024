package day_7

import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "aoc_math"

EXAMPLE_PART_1 :: 3749
EXAMPLE_PART_2 :: 11387

RESULT_PART_1 :: 5540634308362
RESULT_PART_2 :: 472290821152397

NumberToCalibrate :: struct {
	value:             u64,
	members:           []u64,
	can_be_calibrated: bool,
}

main :: proc() {
	fmt.println("Running day_7...")
	start := time.now()
	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))

	test_part_1("day_7_example_input", EXAMPLE_PART_1)
	test_part_2("day_7_example_input", EXAMPLE_PART_2)
	test_part_1("day_7_input", RESULT_PART_1)
	test_part_2("day_7_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	// result = parse_numbers_to_calibrate(input)
	result = parse_numbers_to_calibrate_recursive(input)
	elapsed := time.since(start)
	fmt.printf("time elapsed: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = parse_numbers_to_calibrate_recursive(input, true)
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

parse_input :: proc(input: string) -> []NumberToCalibrate {
	lines := strings.split_lines(input)
	numbers_to_calibrate := [dynamic]NumberToCalibrate{}
	x: sa.Small_Array(12, u64)

	for l in lines {
		if l == "" {
			continue
		}
		current_number := NumberToCalibrate{}

		l_splt := strings.split(l, ":")

		if val, ok := strconv.parse_u64(l_splt[0]); ok {
			current_number.value = val
		} else {
			fmt.panicf("cannot parse number '%v' as u64", l_splt[0])
		}

		nums_str := strings.split(l_splt[1], " ")

		for n in nums_str {
			if n == "" {
				continue
			}
			if num, ok := strconv.parse_u64(n); ok {
				sa.append(&x, num)
			} else {
				fmt.panicf("cannot parse number '%v' as u64", n)
			}
		}

		current_number.members = slice.clone(sa.slice(&x))
		sa.clear(&x)

		append(&numbers_to_calibrate, current_number)
	}
	return numbers_to_calibrate[:]
}

parse_numbers_to_calibrate_recursive :: proc(
	input: string,
	with_concat: bool = false,
) -> (
	result: u64,
) {
	numbers_to_calibrate := parse_input(input)

	for &num_to_cal in numbers_to_calibrate {
		if tune_number_calibration_recursive(
			num_to_cal.value,
			num_to_cal.members[0],
			num_to_cal.members[1:],
			with_concat,
		) {
			result += num_to_cal.value
		}
	}

	return
}

tune_number_calibration_recursive :: proc(
	target, accumulator: u64,
	next: []u64,
	with_concat: bool = false,
) -> bool {
	if len(next) == 0 {
		return accumulator == target
	}

	return(
		tune_number_calibration_recursive(target, accumulator + next[0], next[1:], with_concat) ||
		tune_number_calibration_recursive(target, accumulator * next[0], next[1:], with_concat) ||
		(with_concat &&
				tune_number_calibration_recursive(
					target,
					aoc_math.concat_number(accumulator, next[0]),
					next[1:],
					with_concat,
				)) \
	)
}