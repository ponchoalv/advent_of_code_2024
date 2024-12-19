package day_19

import "core:container/queue"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 6
EXAMPLE_PART_2 :: 16

RESULT_PART_1 :: 213
RESULT_PART_2 :: 1016700771200474

// Helper struct to store pattern and its count
Pattern_Count :: struct {
	pattern: string,
}

main :: proc() {
	fmt.println("Running day_19...")
	test_part_1("day_19_example_input", EXAMPLE_PART_1)
	test_part_2("day_19_example_input", EXAMPLE_PART_2)
	test_part_1("day_19_input", RESULT_PART_1)
	test_part_2("day_19_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	towels, patterns := parse_towels_patterns(input)

	memo := map[string]u64{}
	for pt in patterns {
		result += 1 if count_all_towels_patterns(towels[:], pt, &memo) > 0 else 0
	}

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	towels, patterns := parse_towels_patterns(input)

	memo := map[string]u64{}
	for pt in patterns {
		result += count_all_towels_patterns(towels[:], pt, &memo)
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
	data, ok := os.read_entire_file(filename, context.temp_allocator)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}

parse_towels_patterns :: proc(input:string) -> (towels_slice, patterns_slice: []string) {
	towel_patterns := strings.split(input, "\n\n")

	towels := [dynamic]string{}

	for tw in strings.split(towel_patterns[0], ", ") {
		append(&towels, tw)
	}

	patterns := [dynamic]string{}

	for pt in strings.split_lines(towel_patterns[1]) {
		if pt == "" {
			continue
		}
		append(&patterns, pt)
	}

	towels_slice = towels[:]
	patterns_slice = patterns[:]
	
	return
}

count_all_towels_patterns :: proc(
	towels: []string,
	pattern: string,
	memo: ^map[string]u64,
) -> u64 {
	if !(pattern in memo) {
		if len(pattern) == 0 {
			return 1
		} else {
			result: u64 = 0
			for tow in towels {
				if strings.has_prefix(pattern, tow) {
					result += count_all_towels_patterns(towels, pattern[len(tow):], memo)
				}
			}
			memo[pattern] = result
		}
	}
	return memo[pattern]
}
