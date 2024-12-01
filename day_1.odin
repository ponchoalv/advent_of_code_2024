package day_1

import "core:fmt"
import "core:os"
import "core:sort"
import "core:strings"
import "core:strconv"

EXAMPLE_PART_1 :: 11
EXAMPLE_PART_2 :: 31

RESULT_PART_1 :: 1941353
RESULT_PART_2 :: 22539317

main :: proc() {
	fmt.println("Running day_1...")
	test_part_1("day_1_example_input", EXAMPLE_PART_1)
	test_part_2("day_1_example_input", EXAMPLE_PART_2)
	test_part_1("day_1_input", RESULT_PART_1)
	test_part_2("day_1_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> u64 {
	left_list, right_list := parse_input(read_file(filename))

	sort.quick_sort(left_list[:])
	sort.quick_sort(right_list[:])

	distance := sum(..distances(left_list[:], right_list[:]))

	return distance
}

part_2 :: proc(filename: string)  -> u64 {
	left_list, right_list := parse_input(read_file(filename))

	sort.quick_sort(left_list[:])
	sort.quick_sort(right_list[:])

	left_freqs := sum(..freqs(left_list[:], right_list[:]))

	return left_freqs
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

sum :: proc(nums: ..u64, init_value:u64 = 0) -> (result: u64) {
	result = init_value
	for n in nums {
		result += n
	}
	return
}

distances :: proc(left, right: []u64) -> []u64 {
	distances := [dynamic]u64{}
	s := soa_zip(l=left, r=right)

	for v,i in s {
		append(&distances, u64(abs(int(s.l[i] - s.r[i]))))
	}

	return distances[:]
}

freqs :: proc(left, right: []u64) -> []u64 {
	freqs := [dynamic]u64{}
	freq := map[u64]u64{}

	for v in right {
		el, ok := freq[v]
		if ok {
			freq[v] = el + 1
		} else {
			freq[v] = 1
		}
	}

	for v in left {
		el, ok := freq[v]
		if ok {
			append(&freqs, v*el)
		}
	}

	return freqs[:]
}


parse_input :: proc(input: string) -> (left_location_list, right_location_list: [dynamic]u64) {
	// Split input into workflows and parts
	lines := strings.split(input, "\n")

	// Parse workflows
	for line in lines[:len(lines) - 1] {
		if line == "\n" {
			continue
		}

		both_lists := strings.split(line, "   ")
		left, ok_left := strconv.parse_u64(both_lists[0])
		if !ok_left {
			fmt.panicf("failed parsing number %s", both_lists[0])
		}


		right, ok_right := strconv.parse_u64(both_lists[1])
		if !ok_right {
			fmt.panicf("failed parsing number %s", both_lists[1])
		}

		append(&left_location_list, left)
		append(&right_location_list, right)
	}

	return
}