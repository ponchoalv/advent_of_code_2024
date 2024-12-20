package day_8

import "core:container/bit_array"
import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"


EXAMPLE_PART_1 :: 14
EXAMPLE_PART_2 :: 34

RESULT_PART_1 :: 357
RESULT_PART_2 :: 1266

main :: proc() {
	fmt.println("Running day_8...")
	test_part_1("day_8_example_input", EXAMPLE_PART_1)
	test_part_2("day_8_example_input", EXAMPLE_PART_2)
	test_part_1("day_8_input", RESULT_PART_1)
	test_part_2("day_8_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	result = get_antinodes(input)

	elapsed := time.since(start)

	fmt.printf("time elapsed part 1: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = get_antinodes_with_resonant_harmonics(input)

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
	data, ok := os.read_entire_file(filename)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}


// group all coords under the same freq
get_anthenas_coords_by_freq :: proc(lines: []string) -> map[u8][dynamic][2]int {
	grid_len := len(lines) - 1
	anthenas_coords_by_freq := map[u8][dynamic][2]int{}
	for y in 0 ..< grid_len {
		for x in 0 ..< grid_len {
			if lines[y] == "" || lines[y][x] == '.' {
				continue
			}

			if ac, ok := anthenas_coords_by_freq[lines[y][x]]; ok {
				append(&ac, [2]int{y, x})
				anthenas_coords_by_freq[lines[y][x]] = ac
			} else {
				v := [dynamic][2]int{}
				append(&v, [2]int{y, x})
				anthenas_coords_by_freq[lines[y][x]] = v
			}
		}
	}

	return anthenas_coords_by_freq
}

/*
	to get the antinodes we need to do something like this for every token looking downwards:
    in this case (1,8) matched with (2,5) and the two antinodes are (0,11) and (3,2)
	- (1, 8) + (-1, 3) -> (0, 11)
	- (2, 5) -> antinode (1-2), (8-5) -> (-1, 3) or -> (2-1, 5-8) -> (1, -3) -> (2,5) + (1, -3) -> (3, 2)
*/
get_antinodes :: proc(input: string) -> u64 {
	lines := strings.split_lines(input)
	grid_len := u16(len(lines) - 1)
	anthenas_coords_by_freq := get_anthenas_coords_by_freq(lines)
	// track antinodes
	antinodes_set: bit_array.Bit_Array
	antinode_count: u64

	for k, anthenas in anthenas_coords_by_freq {
		for first in anthenas {
			for second in anthenas {
				if first == second {
					continue
				}
				antinode := first + (first - second)
				if antinode.x >= 0 &&
				   antinode.y >= 0 &&
				   u16(antinode.x) < grid_len &&
				   u16(antinode.y) < grid_len {
					antinode_was_set := bit_array.get(&antinodes_set, (u16(antinode.x)*grid_len+u16(antinode.y)))
						if !antinode_was_set {
							antinode_count += 1
							bit_array.set(&antinodes_set, (u16(antinode.x)*grid_len+u16(antinode.y)), true)
						}
				}
			}
		}
	}

	return antinode_count
}

get_antinodes_using_array :: proc(input: string) -> u64 #no_bounds_check {
	lines := strings.split_lines(input)
	grid_len := len(lines) - 1
	antinodes := [50][50]bool{}
	result:u64 = 0
	
	for y in 0..<grid_len {
		for x in 0..<grid_len {
			if lines[y] == "" || lines[y][x] == '.' {
				continue
			}

			current_token := lines[y][x]
			first := [2]int{y, x}

			for yt in 0..<grid_len {
				for xt in 0..<grid_len {
					if lines[y] == "" || (yt == y && xt == x) || lines[y][x] == '.' {
						continue
					}

					if current_token == lines[yt][xt] {
						second := [2]int{yt, xt}

						antinode := first + (first - second)

						if antinode.x >= 0 &&
					 	  antinode.y >= 0 &&
						  antinode.x < grid_len &&
						  antinode.y < grid_len {
							if !antinodes[antinode[0]][antinode[1]]  {
								antinodes[antinode[0]][antinode[1]] = true
								result += 1
							}
						}
					}
				}
			}
		}
	}

	return result
}

/*
	to get the antinodes we need to do something like this for every token looking downwards:
    in this case (1,8) matched with (2,5) and the two antinodes are (0,11) and (3,2)
	- (1, 8) + (-1, 3) -> (0, 11)
	- (2, 5) -> antinode (1-2), (8-5) -> (-1, 3) or -> (2-1, 5-8) -> (1, -3) -> (2,5) + (1, -3) -> (3, 2)
	- include the harmonics in the directions of the antinode also include all the stations that are within harmonics
*/
get_antinodes_with_resonant_harmonics :: proc(input: string) -> u64 {
	lines := strings.split_lines(input)
	grid_len := u16(len(lines) - 1)
	anthenas_coords_by_freq := get_anthenas_coords_by_freq(lines)
	
	// keep track what antinodes have been visited using bit array instead of map
	antinodes_set: bit_array.Bit_Array
	antinode_count:u64

	for k, anthenas in anthenas_coords_by_freq {
		for first in anthenas {
			for second in anthenas {
				if first == second {
					continue
				}
				antinode_diretion := first - second
				antinode := first + antinode_diretion
				antinode_was_set := bit_array.get(&antinodes_set, (u16(first.x)*grid_len+u16(first.y)))
				if !antinode_was_set {
					antinode_count += 1
					bit_array.set(&antinodes_set, (u16(first.x)*grid_len+u16(first.y)), true)
				}
				// move in antinode direction while is whithin the boundaries and add it to the antinodes set
				for antinode.x >= 0 &&
				    antinode.y >= 0 &&
				    u16(antinode.x) < grid_len &&
				    u16(antinode.y) < grid_len {
				    	antinode_was_set := bit_array.get(&antinodes_set, (u16(antinode.x)*grid_len+u16(antinode.y)))
						if !antinode_was_set {
							antinode_count += 1
							bit_array.set(&antinodes_set, (u16(antinode.x)*grid_len+u16(antinode.y)), true)
						}
						antinode += antinode_diretion
				}
			}

		}
	}

	return antinode_count
}
