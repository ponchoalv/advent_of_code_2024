package day_24

import "core:fmt"
import "core:math/bits"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 2024
EXAMPLE_PART_2 :: ""

RESULT_PART_1 :: 61886126253040
RESULT_PART_2 :: "fgt,fpq,nqk,pcp,srn,z07,z24,z32"

Operation :: enum {
	AND,
	XOR,
	OR,
}

GateType :: enum {
	INPUT,
	INTERMEDIATE,
	EDGE,
}

Gate :: struct {
	inputs:    [2]string,
	operation: Operation,
	type:      GateType,
	value:     bool,
	id:        string,
}


main :: proc() {
	fmt.println("Running day_24...")
	test_part_1("day_24_example_input", EXAMPLE_PART_1)
	// test_part_2("day_24_example_input", EXAMPLE_PART_2)
	test_part_1("day_24_input", RESULT_PART_1)
	test_part_2("day_24_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)

	inputs := map[string]Gate{}
	gates := map[string]Gate{}
	parse_gates_inputs(input, &gates, &inputs)

	keys, _ := slice.map_keys(gates)
	slice.sort(keys)

	num := [dynamic]bool{}
	memo := map[string]bool{}
	for k in keys {
		if gates[k].type == .EDGE {
			append(&num, calculate_gate_value(gates, inputs, gates[k].id, &memo))
		} else {
			continue
		}
	}

	result = calculate_num(num[:])
	elapsed := time.since(start)

	fmt.printf("time elapsed in part 1: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: string) {
	start := time.now()
	input := read_file(filename)
	inputs := map[string]Gate{}
	gates := map[string]Gate{}
	parse_gates_inputs(input, &gates, &inputs)


	gates_str, _ := slice.map_keys(gates)
	slice.sort(gates_str)

	result = find_and_swap_faulty_gates(&gates, gates_str)
	fmt.println(result)

	elapsed := time.since(start)

	fmt.printf("time elapsed in part 2: %fms\n", time.duration_milliseconds(elapsed))
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

test_part_2 :: proc(input: string, expected_result: string) {
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

calculate_gate_value :: proc(gates, inputs: map[string]Gate, gate_input: string, memo: ^map[string]bool) -> bool {
	if gate_input in inputs {
		return inputs[gate_input].value
	}

	if gate_input in memo {
		return memo[gate_input]
	}

	result: bool
	if g, ok := gates[gate_input]; ok {
		switch g.operation {
		case .AND:
			result = bool(
				u8(calculate_gate_value(gates, inputs, g.inputs[0], memo)) &
				u8(calculate_gate_value(gates, inputs, g.inputs[1], memo)),
			)
		case .OR:
			result = bool(
				u8(calculate_gate_value(gates, inputs, g.inputs[0], memo)) |
				u8(calculate_gate_value(gates, inputs, g.inputs[1], memo)),
			)
		case .XOR:
			result = bool(
				u8(calculate_gate_value(gates, inputs, g.inputs[0], memo)) ~
				u8(calculate_gate_value(gates, inputs, g.inputs[1], memo)),
			)
		}
	}

	memo[gate_input]=result
	
	return memo[gate_input]
}

calculate_num :: proc(bit_num: []bool) -> u64 {
	result: u64 = 0
	for b, i in bit_num {
		result += 1 << u64(i) if b else 0
	}

	return result
}

parse_gates_inputs :: proc(input: string, gates, inputs: ^map[string]Gate) {
	lines := strings.split_lines(input)

	parsing_inputs := true

	for l in lines {
		if l == "" {
			parsing_inputs = false
			continue
		}

		if parsing_inputs {
			xs := strings.split_multi(l, []string{":", " "})
			value, _ := strconv.parse_bool(xs[2])
			input := Gate {
				id    = xs[0],
				type  = .INPUT,
				value = value,
			}
			inputs[input.id] = input
		} else {
			xs := strings.split_multi(l, []string{" ", "->"})
			gate := Gate{}
			switch xs[1] {
			case "XOR":
				gate.operation = .XOR
			case "OR":
				gate.operation = .OR
			case "AND":
				gate.operation = .AND
			}

			gate.inputs = [2]string{xs[0], xs[2]}
			gate.id = xs[5]

			if strings.has_prefix(gate.id, "z") {
				gate.type = .EDGE
			} else {
				gate.type = .INTERMEDIATE
			}

			gates[gate.id] = gate
		}
	}
}

/* we need to run verification on diferent type of gates, it could be an edge (like the Z's one)
		or intermediate, like all the others, some of them are going to be the carry of the operations, and the others
		will represents the A and B in the sum operations.

		Step-by-Step

    	Bitwise Sum: Si=Ai⊕Bi⊕Ci−1

        	- Where Ci−1 is the carry from the previous bit position.
        	- For the least significant bit, C−1=0. (z00)

    	Carry Generation: Ci=(Ai∧Bi)∨(Ci−1∧(Ai⊕Bi))

    	Repeat this for all 45 bits.
	*/
edge :: proc(gates: map[string]Gate, wire: string, depth: int, memo: ^map[[2]string]bool) -> bool {
	// fmt.printf("%*[0]s%s%s\n", depth, " ","edge ", wire)
	if !(wire in gates) {
		return false
	}

	gate := gates[wire]

	if gate.inputs in memo {
		return memo[gate.inputs]
	}

	if gate.operation != .XOR {
		return false
	}

	// z00
	if depth == 0 {
		return gate.inputs == [2]string{"x00", "y00"} || gate.inputs == [2]string{"y00", "x00"}
	}

	memo[gate.inputs] =
		intermediate_xor(gates, gate.inputs.x, depth) &&
			carry_bit(gates, gate.inputs.y, depth, memo) ||
		intermediate_xor(gates, gate.inputs.y, depth) &&
			carry_bit(gates, gate.inputs.x, depth, memo)

	return memo[gate.inputs]
}

intermediate_xor :: proc(gates: map[string]Gate, wire: string, depth: int) -> bool {
	// fmt.printf("%*[0]s%s%s\n", depth, " ","inter ", wire)
	return check_gate_type(gates, wire, depth, .XOR)
}

carry_bit :: proc(
	gates: map[string]Gate,
	wire: string,
	depth: int,
	memo: ^map[[2]string]bool,
) -> bool {
	// fmt.printf("%*[0]s%s%s\n", depth, " ","carry ", wire)
	if !(wire in gates) {
		return false
	}

	gate := gates[wire]

	if gate.inputs in memo {
		return memo[gate.inputs]
	}

	if depth == 1 {
		if gate.operation != .AND {
			return false
		}

		return gate.inputs == [2]string{"x00", "y00"} || gate.inputs == [2]string{"y00", "x00"}
	}

	if gate.operation != .OR {
		return false
	}

	memo[gate.inputs] =
		d_carry_bit(gates, gate.inputs.x, depth - 1) &&
			re_carry_bit(gates, gate.inputs.y, depth - 1, memo) ||
		d_carry_bit(gates, gate.inputs.y, depth - 1) &&
			re_carry_bit(gates, gate.inputs.x, depth - 1, memo)

	return memo[gate.inputs]
}

d_carry_bit :: proc(gates: map[string]Gate, wire: string, depth: int) -> bool {
	// fmt.printf("%*[0]s%s%s\n", depth, " ","inter ", wire)
	return check_gate_type(gates, wire, depth, .AND)
}

re_carry_bit :: proc(
	gates: map[string]Gate,
	wire: string,
	depth: int,
	memo: ^map[[2]string]bool,
) -> bool {
	// fmt.printf("%*[0]s%s%s\n", depth, " ", "d_carry ", wire)
	if !(wire in gates) {
		return false
	}

	gate := gates[wire]
	if gate.inputs in memo {
		return memo[gate.inputs]
	}

	if gate.operation != .AND {
		return false
	}

	memo[gate.inputs] =
		intermediate_xor(gates, gate.inputs.x, depth) && carry_bit(gates, gate.inputs.y, depth, memo) ||
		intermediate_xor(gates, gate.inputs.y, depth) && carry_bit(gates, gate.inputs.x, depth, memo)

	return memo[gate.inputs]
}

format_wire :: proc(wire_prefix: string, wire_num: int) -> string {
	buff: strings.Builder
	return fmt.sbprintf(&buff, "%s%2d", wire_prefix, wire_num)
}

check_gate_type :: proc(gates: map[string]Gate, wire: string, depth: int, ops: Operation) -> bool {
	if !(wire in gates) {
		return false
	}

	gate := gates[wire]

	if gate.operation != ops {
		return false
	}

	x, y := format_wire("x", depth), format_wire("y", depth)

	return gate.inputs == [2]string{x, y} || gate.inputs == [2]string{y, x}
}

check_gate :: proc(gates: map[string]Gate, gate_num: int, memo: ^map[[2]string]bool) -> bool {
	return edge(gates, format_wire("z", gate_num), gate_num, memo)
}


check_progress :: proc(gates: map[string]Gate) -> int {
	memo := make(map[[2]string]bool)
	defer delete_map(memo)

	progress := 0
	for true {
		if !check_gate(gates, progress, &memo) {
			break
		}

		progress += 1
	}

	return progress
}

// with the checking functions in place, lets brute force this thing :D
// will loop and try swapes in faulty wires/gates once it fix all of them
// will return the swaped gates joined and sorted in a string
find_and_swap_faulty_gates :: proc(gates: ^map[string]Gate, gates_srt: []string) -> string {
	swaps := [dynamic]string{}

	// look for 4 swaps
	for _ in 0 ..< 4 {
		// track how far we made it before/after swaps
		base_progress := check_progress(gates^)
		seen := map[[2]string]bool{}
		x_loop: for x in gates_srt {
			for y in gates_srt {
				if x == y || {x, y} in seen || {y, x} in seen {
					continue
				}

				// swap the gates
				gates[x], gates[y] = gates[y], gates[x]

				seen[{x, y}] = true
				seen[{y, x}] = true

				if check_progress(gates^) > base_progress {
					append(&swaps, x, y)
					break x_loop
				}
				// restore swaped gates, there was no improvement
				gates[x], gates[y] = gates[y], gates[x]
			}
		}

		fmt.println("swaps so far:", swaps)
	}

	slice.sort(swaps[:])
	joined, _ := strings.join(swaps[:], ",")

	return joined
}

from_decimal_to_bool_array :: proc(value: u64, bits_length: uint) -> []bool {
	result := make([]bool, bits_length)
	i := 0
	num := value
	for num > 0 {
		result[i] = bool(num % 2)
		num /= 2
		i += 1
	}
	return result[:]
}
