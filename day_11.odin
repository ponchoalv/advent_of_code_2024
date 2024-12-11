package day_11

import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:time"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:math"
import "core:math/big"
import "core:container/bit_array"


EXAMPLE_PART_1 :: 55312
EXAMPLE_PART_2 :: 65601038650482

RESULT_PART_1 :: 191690
RESULT_PART_2 :: 228651922369703

BIG_NUM :: 18_446_744_073_709_551_614

// remember_nums: map[u64][]u64

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

part_2 :: proc(filename: string)  -> (result: u64) {
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

count_after_blink :: proc(input:string, times: int) -> (result: u64) {
	x := map[u64]u64{}
	remember_blinks := map[u64][2]u64{}

	for n in strings.split(input, " ") {
		num,_ := strconv.parse_u64(strings.trim(n, "\n "))
		x[num] += 1
	}

    for i in 0..<times {
    	temp := map[u64]u64{}
    	stones_count := map[u64]u64{}

    	for stone, count in x {
    		if _,found := remember_blinks[stone]; !found {
    			remember_blinks[stone] = blink_at_stone(stone)
    		}

    		stones_count[stone] += count

    		for next_stone in remember_blinks[stone] {
    			if next_stone != BIG_NUM {	
    				temp[next_stone] += stones_count[stone]
    			}
    		}
    	}
     	x = temp
    }
    
    for _, count in x {
    	result += count
    }

	return
}

get_digits :: proc(num: u64) -> (count: u64) {
	num := num
	for num > 0 {
		num = num/10
		count += 1
	}

	return
}

split_number :: proc(num :u64, digits: u64) -> (front, back: u64) {
	divider := u64(math.pow(f64(10), f64(digits/2)))

	front = num / divider
	back = num - (front * divider)
	return
}

blink_once :: proc(stones: ^[dynamic]u64) {
	stones_count := len(stones)

	for i in 0..<stones_count {
		if stones[i] == 0 {
			stones[i] = 1
		} else {
			d := get_digits(stones[i])
			if d % 2 == 0 {
				first, second := split_number(stones[i], d)
				stones[i] = first
				append(stones, second)
			} else {
				stones[i] *= 2024
			}
		}
	}
}


blink_at_stone :: proc(stone: u64) -> ([2]u64) {
	if stone == 0 {
		return [2]u64{1 , BIG_NUM}
	} else {
		d := get_digits(stone)
		if d % 2 == 0 {
			first, second := split_number(stone, d)
			return [2]u64{first, second}
		} else {
			return [2]u64{stone * 2024, BIG_NUM}
		}
	}
}


// blink_once_bit :: proc(stones: ^bit_array.Bit_Array) {
// 	st_it := bit_array.make_iterator(stones)

// 	for num in bit_array.iterate_by_set(&st_it) {
// 		bit_array.unset(stones, u64(num))
// 		if num == 0 {
// 			bit_array.set(stones, 1)
// 		} else {
// 			d := get_digits(u64(num))
// 			if d % 2 == 0 {
// 				first, second := split_number(u64(num), d)
// 				bit_array.set(stones, first)
// 				bit_array.set(stones, second)

// 				// append(stones, second)
// 			} else {
// 				bit_array.set(stones, u64(num * 2024))
// 			}
// 		}
// 	}
// }

blink_stone :: proc(num:u64) -> (a,b:u64, split:bool) {
	if num == 0 {
		a = 1
		split = false
	} else {
		d := get_digits(num)
		if d % 2 == 0 {
			a, b = split_number(num, d)
			split = true
		} else {
			a = num * 2024
			split = false
		}
	}

	return
}