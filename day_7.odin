package day_7

import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:math"

EXAMPLE_PART_1 :: 3749
EXAMPLE_PART_2 :: 11387

RESULT_PART_1 :: 5540634308362
RESULT_PART_2 :: 472290821152397

MAX_OPERANDS :: 12

Operator :: enum {
	PLUS,
	MULTIPLY,
	CONCAT,
}

Operators :: []Operator

NumberToCalibrate :: struct {
	value:             u64,
	members:           []u64,
	operators:         []Operators,
	can_be_calibrated: bool,
}

ComputedOperators: [MAX_OPERANDS][]Operators
ComputedOperatorsWithConcatenation: [MAX_OPERANDS][]Operators

main :: proc() {
	fmt.println("Running day_7...")
	start := time.now()
	compute_operators(&ComputedOperators, &ComputedOperatorsWithConcatenation)
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
	result = parse_numbers_to_calibrate(input)

	elapsed := time.since(start)
	fmt.printf("time elapsed: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = parse_numbers_to_calibrate_with_concat(input)

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


parse_input :: proc(input: string) -> []NumberToCalibrate{
	lines := strings.split_lines(input)
	numbers_to_calibrate := [dynamic]NumberToCalibrate{}
	x: sa.Small_Array(MAX_OPERANDS, u64)

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

// Read the input and get the NumbersToCalibrate
parse_numbers_to_calibrate :: proc(input: string) -> (result: u64) {
	numbers_to_calibrate := parse_input(input)

	for &num_to_cal in numbers_to_calibrate {
		tune_number_calibration(&num_to_cal)
		if num_to_cal.can_be_calibrated {
			result += num_to_cal.value
		}
	}

	return
}

// Read the input and get the NumbersToCalibrate
parse_numbers_to_calibrate_with_concat :: proc(input: string) -> (result: u64) {
	numbers_to_calibrate := parse_input(input)

	for &num_to_cal in numbers_to_calibrate {
		tune_number_calibration(&num_to_cal, true)
		if num_to_cal.can_be_calibrated {
			result += num_to_cal.value
		}
	}

	return
}

// mark if the number can be calibrated and add the operands in that would apply
// probably the strings / buffer stuff is too slow and need to improve
// 
tune_number_calibration :: proc(number_to_calibrate: ^NumberToCalibrate, with_concat: bool = false) {
	operators:[]Operators
	
	if with_concat {
		operators = ComputedOperatorsWithConcatenation[len(number_to_calibrate.members) - 2]
	} else {
		operators = ComputedOperators[len(number_to_calibrate.members) - 2]
	}

	for comb_operations in operators {
		current_sum: u64 = 0
		current_sum += number_to_calibrate.members[0]
		for operation, i in comb_operations {
			if current_sum > number_to_calibrate.value {
				break
			}
			switch operation {
			case .PLUS:
				current_sum += number_to_calibrate.members[i + 1]
			case .MULTIPLY:
				current_sum *= number_to_calibrate.members[i + 1]
			case .CONCAT:
				r := number_to_calibrate.members[i + 1] 
				// get the digits dividing by 10 and then use it to 'concatenate' both numbers
				num_digits := 0
				temp := r
				for temp > 0 {
				    num_digits += 1
				    temp /= 10
				}

				// Concatenate `current_sum` and `r` using arithmetic
				factor := u64(math.pow(10, f64(num_digits))); // 10^num_digits
				current_sum = current_sum * factor + r;
			}
		}
		if number_to_calibrate.value == current_sum {
			number_to_calibrate.can_be_calibrated = true
			break
		}
	}
}

// Function to generate all combinations of Operator for a given length
generate_combinations :: proc(length: int, with_concat:bool = false) -> [][]Operator {
	combinations: [dynamic][]Operator = [dynamic][]Operator{}
	// Generate all combinations using a binary-like counting method
	total_combinations: u64
	if with_concat {
		total_combinations = u64(math.pow(3, f64(length))) // 3^length
	} else {
		total_combinations = 1 << u64(length) // 2^length
	}

	for i in 0 ..< total_combinations {
		combination: [dynamic]Operator = [dynamic]Operator{} // Dynamic array for each combination
		value := i
		for j in 0 ..< length {
			if with_concat {
				op: Operator
				switch (value % 3) {
					case 0:
						op = .MULTIPLY
					case 1:
						op = .PLUS
					case 2:
						op = .CONCAT
				}
				append(&combination, op)
				value /= 3
			} else {
				append(&combination, Operator.MULTIPLY if (i & (1 << u64(j))) != 0 else Operator.PLUS)
			}
		}
		append(&combinations, combination[:]) // Append the combination
	}

	return combinations[:]
}

// used for pre-calculate the posible operands per operation
compute_operators :: proc(ops: ^[MAX_OPERANDS][]Operators, ops_with_concat: ^[MAX_OPERANDS][]Operators) {
	for i in 0 ..< MAX_OPERANDS {
		ops[i] = generate_combinations(i + 1)
		ops_with_concat[i] = generate_combinations(i + 1, true)
	}
}
