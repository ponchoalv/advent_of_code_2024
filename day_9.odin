package day_9

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:time"

EXAMPLE_PART_1 :: 1928
EXAMPLE_PART_2 :: 2858

RESULT_PART_1 :: 6211348208140
RESULT_PART_2 :: 6239783302560

BLANK_ID :: 4_294_967_295

main :: proc() {
	fmt.println("Running day_9...")
	test_part_1("day_9_example_input", EXAMPLE_PART_1)
	test_part_2("day_9_example_input", EXAMPLE_PART_2)
	test_part_1("day_9_input", RESULT_PART_1)
	test_part_2("day_9_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = defrag_single(input)
	elapsed := time.since(start)

	fmt.printf("time elapsed part 1: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	result = defrag_block(input)
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

checksum :: proc(disk_image: []u32) -> (checksum: u64) {
	for v, i in disk_image {
		if v != BLANK_ID {
			checksum += u64(v * u32(i))
		}
	}
	return
}

swap_blanks_for_numbers :: proc(numbers, free_spaces: []u32, disk_image: ^[dynamic]u32) #no_bounds_check {
	// swap values from number block to blank space block
	#no_bounds_check for nb in soa_zip(num = numbers, blank = free_spaces) {
		if nb.num < nb.blank {
			break
		}

		disk_image[nb.num], disk_image[nb.blank] = disk_image[nb.blank], disk_image[nb.num]
	}
}

// get expanded disk image, then compless by single number movements
// we track blank spaces and number spaces to then swap them quickly
defrag_single :: proc(input: string) -> u64 #no_bounds_check {
	disk_image := [dynamic]u32{}
	track_blank := [dynamic]u32{}
	track_numbers := [dynamic]u32{}
	current_id: u32

	for c, i in input {
		if c == 0 || c == '\n' {
			continue
		}
		if i % 2 == 0 {
			for j in 0 ..< int(c - '0') {
				append(&track_numbers, u32(len(disk_image)))
				append(&disk_image, current_id)
			}
			current_id += 1
		} else {
			for j in 0 ..< int(c - '0') {
				append(&track_blank, u32(len(disk_image)))
				append(&disk_image, BLANK_ID)
			}
		}
	}

	slice.reverse(track_numbers[:])

	swap_blanks_for_numbers(track_numbers[:], track_blank[:], &disk_image)

	return checksum(disk_image[:])
}

// try to move blocks of number from right to left into the block of spaces they fit
defrag_block :: proc(input: string) -> u64 #no_bounds_check {
	disk_image := [dynamic]u32{}
	track_blank := map[u32][]u32{}
	track_numbers := map[u32][]u32{}
	track_numbers_group_index_position := [dynamic]u32{}
	track_brank_group_index_position := [dynamic]u32{}
	current_id: u32

	#no_bounds_check for c, i in input {
		if c == 0 || c == '\n' {
			continue
		}

		if i % 2 == 0 {
			number_block := [dynamic]u32{}
			for j in 0 ..< int(c - '0') {
				append(&number_block, u32(len(disk_image)))
				append(&disk_image, current_id)
			}
			track_numbers[u32(len(disk_image))] = number_block[:]
			append(&track_numbers_group_index_position, u32(len(disk_image)))
			current_id += 1
		} else {
			blank_block := [dynamic]u32{}
			for j in 0 ..< int(c - '0') {
				append(&blank_block, u32(len(disk_image)))
				append(&disk_image, BLANK_ID)
			}

			track_blank[u32(len(disk_image))] = blank_block[:]
			append(&track_brank_group_index_position, u32(len(disk_image)))
		}
	}

	slice.reverse(track_numbers_group_index_position[:])

	// n will be the last position for that block of numbert
	#no_bounds_check numbers_loop: for n in track_numbers_group_index_position {
		nums_pos := track_numbers[n]
		nums_block := u32(len(nums_pos))

		// look for free space blocks for block of size nums_block with which ocuppied positions nums_pos to n-1.
		// b will be the last position of that block of free space. 
		#no_bounds_check for b, i in track_brank_group_index_position {
			blanks_pos := track_blank[b]
			blanks_block := u32(len(blanks_pos))


			// not enough space in this block for the number
			if blanks_block < nums_block {
				continue
			}

			// the numbers block must be only moved to the left
			// n and b are references to where in the image disk they are
			if n < b {
				continue numbers_loop
			}

			// swap values from number block to blank space block
			swap_blanks_for_numbers(nums_pos[:], blanks_pos[:], &disk_image)

			// remove the free space block from the array of blank spaces
			// also remove it from the dictionary with the pointers to the index that those arrays use.
			if nums_block == blanks_block {
				ordered_remove(&track_brank_group_index_position, i)
				delete_key(&track_blank, b)
			} else if nums_block < blanks_block {
				// reduce the ammount of free blocks available
				track_blank[b] = blanks_pos[nums_block:]
			}

			continue numbers_loop
		}
	}

	return checksum(disk_image[:])
}
