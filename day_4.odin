package day_4

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 18
EXAMPLE_PART_2 :: 9

RESULT_PART_1 :: 2483
RESULT_PART_2 :: 1925

main :: proc() {
	fmt.println("Running day_4...")
	test_part_1("day_4_example_input", EXAMPLE_PART_1)
	test_part_2("day_4_example_input", EXAMPLE_PART_2)
	test_part_1("day_4_input", RESULT_PART_1)
	test_part_2("day_4_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()

	result = count_words_with_xmas(read_file(filename))
	
	elapsed := time.since(start)

	fmt.printf("time elapsed: %fms\n",time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string)  -> (result: u64) {
	start := time.now()

	result = count_words_with_x_mas(read_file(filename))
	
	elapsed := time.since(start)

	fmt.printf("time elapsed: %fms\n",time.duration_milliseconds(elapsed))
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

/*
   - Need to find XMAS in all possible directions including diagonals
       - forward
       - backward
       - down
       - up
       - down forward diagonal
       - up forward diagonal
       - down backward diagonal
       - up backward diagonal
*/
count_words_with_xmas :: proc(input: string) -> u64 {
	lines := strings.split_lines(input)
	len_lines := len(lines)
	len_line := len(lines[0])

	total_len := len_lines*len_line
	
	buffer: [4]byte

	i := 0
	line_num := 0
	result: u64 = 0
	match_word := "XMAS"

	for i < total_len {
		if input[i] ==  'X' {
			// forward line
			if (i % (len_line + 1)) + 3 < len_line {
				result += 1 if input[i:i+4] == match_word else 0
			}

			// backward line
			if (i % (len_line + 1)) - 3 >= 0 {
				result += 1 if input[i-3:i+1] == "SAMX" else 0
			}

			// down direction
			if  line_num + 4 < len_lines {
				buffer[0] = input[i]
				buffer[1] = input[i + len_line + 1]
				buffer[2] = input[i + ((len_line + 1) * 2)]
				buffer[3] = input[i + ((len_line + 1) * 3)]
				
				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// up direction
			if  line_num - 3 >= 0 {
				buffer[0] = input[i]
				buffer[1] = input[i - (len_line + 1)]
				buffer[2] = input[i - ((len_line + 1) * 2)]
				buffer[3] = input[i - ((len_line + 1) * 3)]

				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// down forward diagonal
			if  line_num + 4 < len_lines && (i % (len_line + 1)) + 3 < len_line {
				buffer[0] = input[i]
				buffer[1] = input[i + len_line + 1 + 1]
				buffer[2] = input[i + ((len_line + 1) * 2) + 2]
				buffer[3] = input[i + ((len_line + 1) * 3) + 3]
				
				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// up forward diagonal
			if  line_num - 3 >= 0 && (i % (len_line + 1)) + 3 < len_line {
				buffer[0] = input[i]
				buffer[1] = input[i - (len_line + 1) + 1]
				buffer[2] = input[i - ((len_line + 1) * 2) + 2]
				buffer[3] = input[i - ((len_line + 1) * 3) + 3]
				
				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// down backward diagonal
			if  line_num + 4 < len_lines && (i % (len_line + 1)) - 3 >= 0 {
				buffer[0] = input[i]
				buffer[1] = input[i + len_line]
				buffer[2] = input[i + ((len_line + 1) * 2) - 2]
				buffer[3] = input[i + ((len_line + 1) * 3) - 3]
				
				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// up backward diagonal
			if  line_num - 3 >= 0 && (i % (len_line + 1)) - 3 >= 0 {
				buffer[0] = input[i]
				buffer[1] = input[i - (len_line + 1) - 1]
				buffer[2] = input[i - ((len_line + 1) * 2) - 2]
				buffer[3] = input[i - ((len_line + 1) * 3) - 3]
				
				result += 1 if transmute(string)buffer[:] == match_word else 0
			}
		} else if input[i] == '\n' {
			line_num += 1
		}
		i += 1
	}

	return result
}

/*
   - Need to find MAS in all diagonals and match the A (intersection point), and only then increase result by 1
       - down forward diagonal, record A position and if it was twice increase result
       - up forward diagonal, record A position and if it was twice increase result
       - down backward diagonal, record A position and if it was twice increase result
       - up backward diagonal, record A position and if it was twice increase result
*/
count_words_with_x_mas :: proc(input: string) -> u64 {
	lines := strings.split_lines(input)
	len_lines := len(lines)
	len_line := len(lines[0])
	total_len := len_lines*len_line
	
	buffer: [3]byte

	// will count how many times the A got intercepted by storing the position everytime I found an MAS
	intersections := make([]int, total_len)

	i := 0
	line_num := 0
	result: u64 = 0
	match_word := "MAS"

	for i < total_len {
		if input[i] ==  'M' {
			// down forward diagonal
			if  line_num + 3 < len_lines && (i % (len_line + 1)) + 2 < len_line {
				buffer[0] = input[i]
				buffer[1] = input[i + len_line + 1 + 1]
				buffer[2] = input[i + ((len_line + 1) * 2) + 2]
				
				if transmute(string)buffer[:] == match_word {
					intersections[i + len_line + 1 + 1] = intersections[i + len_line + 1 + 1] + 1
					result += 1 if intersections[i + len_line + 1 + 1] == 2 else 0
				}
			}

			// up forward diagonal
			if  line_num - 2 >= 0 && (i % (len_line + 1)) + 2 < len_line {
				buffer[0] = input[i]
				buffer[1] = input[i - (len_line + 1) + 1]
				buffer[2] = input[i - ((len_line + 1) * 2) + 2]
				
				if transmute(string)buffer[:] == match_word {
					intersections[i - (len_line + 1) + 1] = intersections[i - (len_line + 1) + 1] + 1
					result += 1 if intersections[i - (len_line + 1) + 1] == 2 else 0
				}
			}

			// down backward diagonal
			if  line_num + 3 < len_lines && (i % (len_line + 1)) - 2 >= 0 {
				buffer[0] = input[i]
				buffer[1] = input[i + len_line]
				buffer[2] = input[i + ((len_line + 1) * 2) - 2]
				
				if transmute(string)buffer[:] == match_word {
					intersections[i + len_line] = intersections[i + len_line] + 1
					result += 1 if intersections[i + len_line] == 2 else 0
				}
			}

			// up backward diagonal
			if  line_num - 2 >= 0 && (i % (len_line + 1)) - 2 >= 0 {
				buffer[0] = input[i]
				buffer[1] = input[i - (len_line + 1) - 1]
				buffer[2] = input[i - ((len_line + 1) * 2) - 2]
				
				if transmute(string)buffer[:] == match_word {
					intersections[i - (len_line + 1) - 1] = intersections[i - (len_line + 1) - 1] + 1
					result += 1 if intersections[i - (len_line + 1) - 1] == 2 else 0
				}
			}
		} else if input[i] == '\n' {
			line_num += 1
		}
		i += 1
	}

	return result
}

/*
generic way (could be use with other words and in both parts)
Part 1 (checking for XMAS and with check_for_x=false):
	- Need to find XMAS in all possible directions including diagonals
       - forward
       - backward
       - down
       - up
       - down forward diagonal
       - up forward diagonal
       - down backward diagonal
       - up backward diagonal
Part 2 (checking for MAS and with check_for_x=true):
	- Need to find MAS in all diagonals and match the A (intersection point), and only then increase result by 1
       - down forward diagonal, record A position and if it was twice increase result
       - up forward diagonal, record A position and if it was twice increase result
       - down backward diagonal, record A position and if it was twice increase result
       - up backward diagonal, record A position and if it was twice increase result
*/
count_match_word :: proc(input, match_word: string, check_for_x: bool = false) -> u64 {
	lines := strings.split_lines(input)
	len_lines := len(lines)
	len_line := len(lines[0])
	total_len := len_lines*len_line
	
	len_match_word := len(match_word)
	buffer: []byte = make([]byte, len_match_word)
	match_word_reverse := strings.reverse(match_word)
	
	i := 0
	line_num := 0
	result: u64 = 0
	intersections := make([]int, total_len)
	x_pos := 0
	match_forward:= false

	for i < total_len {
		if input[i] ==  match_word[0] {
			// forward line
			if (i % (len_line + 1)) + (len_match_word - 1) < len_line && !check_for_x {
				if input[i:i+len_match_word] == match_word {
					result += 1
					match_forward = true
				}
			}

			// backward line
			if (i % (len_line + 1)) - (len_match_word - 1) >= 0  && !check_for_x {
				result += 1 if input[i-(len_match_word - 1):i+1] == match_word_reverse else 0
			}

			// down direction
			if  line_num + len_match_word < len_lines  && !check_for_x {
				for j in 0..<len_match_word {
	 				buffer[j] = input[i + (len_line + 1) * j]
				}

				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// up direction
			if  line_num - (len_match_word - 1) >= 0  && !check_for_x {
				for j in 0..<len_match_word {
	 				buffer[j] = input[i - (len_line + 1) * j]
				}

				result += 1 if transmute(string)buffer[:] == match_word else 0
			}

			// down forward diagonal
			if  line_num + len_match_word < len_lines && (i % (len_line + 1)) + (len_match_word - 1) < len_line {
				for j in 0..<len_match_word {
	 				buffer[j] = input[i + ((len_line + 1) * j) + (1 * j)]
	 				if check_for_x && j == len_match_word / 2 {
	 					x_pos = i + ((len_line + 1) * j) + (1 * j)
	 				}
				}

				if transmute(string)buffer[:] == match_word {
					if check_for_x {
						intersections[x_pos] = intersections[x_pos] + 1
						result += 1 if intersections[x_pos] == 2 else 0
					} else {
						result += 1
					}
				}
			}

			// up forward diagonal
			if  line_num - (len_match_word - 1) >= 0 && (i % (len_line + 1)) + (len_match_word - 1) < len_line {
				for j in 0..<len_match_word {
	 				buffer[j] = input[i - ((len_line + 1) * j) + (1 * j)]
	 				if check_for_x && j == len_match_word / 2 {
	 					x_pos = i - ((len_line + 1) * j) + (1 * j)
	 				}
				}

				if transmute(string)buffer[:] == match_word {
					if check_for_x {
						intersections[x_pos] = intersections[x_pos] + 1
						result += 1 if intersections[x_pos] == 2 else 0
					} else {
						result += 1
					}
				}
			}

			// down backward diagonal
			if  line_num + len_match_word < len_lines && (i % (len_line + 1)) - (len_match_word - 1) >= 0 {
				for j in 0..<len_match_word {
	 				buffer[j] = input[i + ((len_line + 1) * j) - (1 * j)]
	 				if check_for_x && j == len_match_word / 2 {
	 					x_pos = i + ((len_line + 1) * j) - (1 * j)
	 				}
				}

				if transmute(string)buffer[:] == match_word {
					if check_for_x {
						intersections[x_pos] = intersections[x_pos] + 1
						result += 1 if intersections[x_pos] == 2 else 0
					} else {
						result += 1
					}
				}
			}

			// up backward diagonal
			if  line_num - (len_match_word - 1) >= 0 && (i % (len_line + 1)) - (len_match_word - 1) >= 0 {
				for j in 0..<len_match_word {
	 				buffer[j] = input[i - ((len_line + 1) * j) - (1 * j)]
	 				if check_for_x && j == len_match_word / 2 {
	 					x_pos = i - ((len_line + 1) * j) - (1 * j)
	 				}
				}
				
				if transmute(string)buffer[:] == match_word {
					if check_for_x {
						intersections[x_pos] = intersections[x_pos] + 1
						result += 1 if intersections[x_pos] == 2 else 0
					} else {
						result += 1
					}
				}
			}

		} else if input[i] == '\n' {
			line_num += 1
		}

		if match_forward {
			i += len_match_word
			match_forward = false
		} else {
			i += 1
		}
	}

	return result
}