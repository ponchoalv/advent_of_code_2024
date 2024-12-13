package day_13

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 480
EXAMPLE_PART_2 :: 875318608908

RESULT_PART_1 :: 35082
RESULT_PART_2 :: 82570698600470

ClawMachine :: struct {
	a:      [2]i64,
	b:      [2]i64,
	prize: [2]i64,
}

main :: proc() {
	fmt.println("Running day_13...")
	test_part_1("day_13_example_input", EXAMPLE_PART_1)
	test_part_2("day_13_example_input", EXAMPLE_PART_2)
	test_part_1("day_13_input", RESULT_PART_1)
	test_part_2("day_13_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	// fmt.println(input)
	result = get_minimun_tokens_for_prize(parse_claw_machine(input))
	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	// fmt.println(input)
	result = get_minimun_tokens_for_prize(parse_claw_machine(input), true)
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

parse_claw_machine :: proc(input: string)  -> []ClawMachine{
	lines := strings.split_lines(input)

	machines := [dynamic]ClawMachine{}

	machine := ClawMachine{}
	for line in lines {

		if strings.contains(line, "Button A:") {
			splits := strings.split_multi(line, []string{"+", ","})
			machine.a.x, _ = strconv.parse_i64(splits[1])
			machine.a.y, _ = strconv.parse_i64(splits[3])
		}

		if strings.contains(line, "Button B:") {
			splits := strings.split_multi(line, []string{"+", ","})
			machine.b.x, _ = strconv.parse_i64(splits[1])
			machine.b.y, _ = strconv.parse_i64(splits[3])
		}

		if strings.contains(line, "Prize:") {
			splits := strings.split_multi(line, []string{"=", ","})
			machine.prize.x, _ = strconv.parse_i64(splits[1])
			machine.prize.y, _ = strconv.parse_i64(splits[3])
		}

		if line == "" {
			append(&machines, machine)
		}
	}

	return machines[:]
}

// get the minimum tokens needed to get the prize (part one wihtout calibrating and part two with calibration)
get_minimun_tokens_for_prize :: proc(machines: []ClawMachine, calibrated:bool = false) -> (tokens:u64) {
	for &machine in machines {
		if calibrated {
			machine.prize.x += 10_000_000_000_000
			machine.prize.y += 10_000_000_000_000
		}

		a, b := calculate_a_and_b(machine)
		if was_prize_reached(machine, a, b) {
			tokens += u64(3 * a + b)
		}
	}

	return
}

/*
After using Cramer’s Rule to Solve a 2×2 System
	https://math.libretexts.org/Bookshelves/Precalculus/Precalculus_1e_(OpenStax)/09%3A_Systems_of_Equations_and_Inequalities/9.08%3A_Solving_Systems_with_Cramer%27s_Rule
	we can express the system like this for the given example:
		94a + 22b = 8400
		34a + 67b = 5400

	which translate to a matrix / matrix, where we apply Cramer's rules and we can get the value for a
		8400 22
		5400 67
		-------  = ((8400 * 67) - (22 * 5400))/ (94 * 67 - 22 * 34) = a
		94  22
		34  67 

	And b is simply relpacing a in the previous system, this is how we can express any a / b:

		a = ((8400 * 67) - (22 * 5400))/ (94 * 67 - 22 * 34)
		b = (5400 - 34 * a )/ 67
	 	
 			or
	
		b = (94 * 5400 - 34 * 8400) / (94 * 67 - 34 * 22) -> 40
		a = (8400 - 22 * b) / 94 -> 80.0
*/
calculate_a_and_b :: proc(machine: ClawMachine) -> (a, b: i64) {
	a =
		((machine.b.y * machine.prize.x) -
		(machine.b.x * machine.prize.y)) / (machine.a.x * machine.b.y -
				machine.a.y * machine.b.x)
	b = (machine.prize.y - machine.a.y * a) / machine.b.y
	return
}

// check if with the calculated a and b we can reach the prize
was_prize_reached :: proc(machine: ClawMachine, a,b:i64) -> bool {
	return machine.a.x * a + machine.b.x * b == machine.prize.x &&
			machine.a.y * a + machine.b.y * b == machine.prize.y
}