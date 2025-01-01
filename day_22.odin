package day_22

import "bit_utils"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 37327623
EXAMPLE_PART_2 :: 23

RESULT_PART_1 :: 17577894908
RESULT_PART_2 :: 1931

// 1476 to low

PRICE_CHANGE_PATTERN :: [4]int{-2, 1, -1, 3}

main :: proc() {
	fmt.println("Running day_22...")
	test_part_1("day_22_example_input", EXAMPLE_PART_1)
	test_part_2("day_22_2_example_input", EXAMPLE_PART_2)
	test_part_1("day_22_input", RESULT_PART_1)
	test_part_2("day_22_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	// fmt.println(input)

	lines := strings.split_lines(input)

	for l in lines {
		if l == "" {continue}
		secret, _ := strconv.parse_u64(l)

		for _ in 0 ..< 2000 {
			secret = step(secret)
		}

		result += secret
	}

	elapsed := time.since(start)

	fmt.printf("time elapsed part 1: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	pre_calculated_prices := make_map_cap(map[u64][dynamic]int, 3000)
	defer delete_map(pre_calculated_prices)

	price_changes_sequences := make_map_cap(map[[4]int]int, 45000)
	defer delete_map(price_changes_sequences)

	lines := strings.split_lines(input)

	best := 0
	#no_bounds_check for l in lines {
		if l == "" {continue}
		secret, _ := strconv.parse_u64(l)
		initial := secret
		visited := make_map_cap(map[[4]int]bool, 2000)
		defer delete_map(visited)

		#no_bounds_check for i in 0 ..< 2000 {
			secret = step(secret)
			if i == 0 {
				prices := make([dynamic]int)
				reserve_dynamic_array(&prices, 2001)
				append(&prices, int(secret % 10))
				pre_calculated_prices[initial] = prices 
			} else {
				append(&pre_calculated_prices[initial], int(secret % 10))
			}

			if i > 3 {
				#no_bounds_check zipped := soa_zip(
					a = pre_calculated_prices[initial][:],
					b = pre_calculated_prices[initial][1:],
				)

				seq := [4]int {
					zipped[i - 4].b - zipped[i - 4].a,
					zipped[i - 3].b - zipped[i - 3].a,
					zipped[i - 2].b - zipped[i - 2].a,
					zipped[i - 1].b - zipped[i - 1].a,
				}

				if !(seq in visited) {
					visited[seq] = true
					price_changes_sequences[seq] += pre_calculated_prices[initial][i]
					best = max(best, price_changes_sequences[seq])
				}
			}
		}
		// fmt.println(len(visited))
	}

	fmt.println(len(pre_calculated_prices))
	fmt.println(len(price_changes_sequences))

	result = u64(best)

	elapsed := time.since(start)

	fmt.printf("time elapsed part 2: %fms\n", time.duration_milliseconds(elapsed))
	
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

step :: proc(secret: u64) -> (result: u64) {
	result = ((secret * 64) ~ secret) % 16777216
	result = ((result / 32) ~ result) % 16777216
	result = ((result * 2048) ~ result) % 16777216

	return
}
