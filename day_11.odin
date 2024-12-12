package day_11

import "aoc_math"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"


EXAMPLE_PART_1 :: 55312
EXAMPLE_PART_2 :: 65601038650482

RESULT_PART_1 :: 191690
RESULT_PART_2 :: 228651922369703

main :: proc() {
	fmt.println("Running day_11...")
	test_part_1("day_11_example_input", EXAMPLE_PART_1)
	test_part_2("day_11_example_input", EXAMPLE_PART_2)
	test_part_1("day_11_input", RESULT_PART_1)
	test_part_2("day_11_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)
	result = count_after_blink(input, 25)
	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = count_after_blink(input, 75)
	fmt.println(input)
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

// counting blinks, used a list first, but program crashed after reaching 4gb of ram on part 2
// after that decided to go with a map to count frequencies of ocurrence of the numbers after blink.
count_after_blink :: proc(input: string, blink_times: u64) -> (result: u64) {
	stones := map[u64]u64{}
	memo := map[[2]u64]u64{}

	for n in strings.split(input, " ") {
		num, _ := strconv.parse_u64(strings.trim(n, "\n "))
		stones[num] += 1
	}

	for i in 0 ..< blink_times {
		stones = blink_at_stones(stones)
	}

	for _, count in stones {
		result += count
	}

	return
}

blink_at_stone :: proc(stone: u64) -> []u64 {
	result := [dynamic]u64{}
	if stone == 0 {
		append(&result, 1)
	} else {
		d := aoc_math.get_digits(stone)
		if d % 2 == 0 {
			first, second := aoc_math.split_number(stone, d)
			append(&result, first, second)
		} else {
			append(&result, stone * 2024)
		}
	}

	return result[:]
}

blink_at_stones :: proc(stones: map[u64]u64) -> (result: map[u64]u64) {
	for stone, count in stones {
		for next_stone in blink_at_stone(stone) {
			// need to sum the count of the stone, so we now how many times we produce the next_stone at blinking on the stone
			result[next_stone] += count
		}
	}
	return
}

/*
Could be used to solve both parts with the memo, just call it like this:
	for stone in stones {
		result += blink_recursive(stone, blink_times, &memo)
	}

It have similar performance as the one without recursion. I found more readable the other one.
*/
blink_recursive :: proc(stone: u64, step: u64, memo: ^map[[2]u64]u64) -> u64 {
	if step == 0 {
		return 1
	}
	
	if value, found := memo[{stone, step}]; found {
		return value
	}

	if stone == 0 {
		return blink_recursive(1, step - 1, memo)
	}


	result: u64
	d := aoc_math.get_digits(stone)
	if d % 2 == 0 {
		first, second := aoc_math.split_number(stone, d)
		result = blink_recursive(first, step - 1, memo) + blink_recursive(second, step - 1, memo)
	} else {
		result = blink_recursive(stone * 2024, step - 1, memo)
	}

	memo[{stone, step}] = result
	return result
}
