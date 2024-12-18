package day_17

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: []u64{4, 6, 3, 5, 6, 3, 5, 2, 1, 0}
EXAMPLE_PART_2 :: 117440

RESULT_PART_1 :: []u64{1, 7, 2, 1, 4, 1, 5, 4, 0}
RESULT_PART_2 :: 37221261688308

CPU :: struct {
	memory:              map[string]u64,
	instruction_pointer: u64,
	instructions:        [8]proc(cpu: ^CPU, operand: u64),
	output:              [dynamic]u64,
}

main :: proc() {
	fmt.println("Running day_17...")
	test_part_1("day_17_example_input", EXAMPLE_PART_1)
	// test_part_2("day_17_example_input", EXAMPLE_PART_2)
	test_part_1("day_17_input", RESULT_PART_1)
	test_part_2("day_17_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: []u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)

	// 0 regs - 1 program
	registers, program := parse_initial_memory_program(input)
	cpu := init_cpu(registers)
	result = run_program(&cpu, program)

	print_output(cpu)

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)

	// 0 regs - 1 program
	registers, program := parse_initial_memory_program(input)

	cpu := CPU{}
	output := []u64{9999999}
	
	i: u64 = 0
	
	// the program is an output of 16 digits
	for j in 0..<16 {
		for !are_equal(output, program[len(program) - (1+j):]) {
			registers["A"] = i
			registers["B"] = 0
			registers["C"] = 0
			cpu = init_cpu(registers)
			output = run_program(&cpu, program)

			if are_equal(output, program[len(program) - (1+j):]) {
				i = i << 3
				break
			} else {
				i += 1
			}
		}
	}

	result = i >> 3

	print_output(cpu)
	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

test_part_1 :: proc(input: string, expected_result: []u64) {
	part_1_result := part_1(input)

	paired := soa_zip(l = part_1_result, r = expected_result)

	for pair in paired {
		fmt.assertf(
			pair.l == pair.r,
			"(%s): part 1 result was %d and expected was %d",
			input,
			part_1_result,
			expected_result,
		)
	}

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

run_program :: proc(cpu: ^CPU, program: []u64) -> []u64 {
	for cpu.instruction_pointer < u64(len(program)) {
		instruction := program[cpu.instruction_pointer]
		operand := program[cpu.instruction_pointer + 1]
		run_instruction(cpu, instruction, operand)
	}

	return cpu.output[:]
}

print_output :: proc(cpu: CPU) {
	for i in 0 ..< len(cpu.output) {
		fmt.print(cpu.output[i])
		if i != len(cpu.output) - 1 {
			fmt.print(",")
		}
	}
	fmt.println("")
}

run_instruction :: proc(cpu: ^CPU, instruction, operand: u64) {
	cpu.instructions[instruction](cpu, operand)
}

init_cpu :: proc(mem: map[string]u64) -> CPU {
	cpu := CPU{}
	cpu.memory = mem
	cpu.instruction_pointer = 0

	combo :: proc(op: u64, reg: map[string]u64) -> u64 {
		if op <= 3 {
			return u64(op)
		} else if op == 4 {
			return reg["A"]
		} else if op == 5 {
			return reg["B"]
		} else if op == 6 {
			return reg["C"]
		} else {
			panic("unreachable")
		}
	}

	cpu.instructions[0] = proc(cpu: ^CPU, operand: u64) {
		num := cpu.memory["A"]
		deno := u64(1) << combo(operand, cpu.memory)
		cpu.memory["A"] = (num) / deno
		cpu.instruction_pointer += 2
	}

	cpu.instructions[1] = proc(cpu: ^CPU, operand: u64) {
		cpu.memory["B"] = cpu.memory["B"] ~ operand
		cpu.instruction_pointer += 2
	}

	cpu.instructions[2] = proc(cpu: ^CPU, operand: u64) {
		cpu.memory["B"] = combo(operand, cpu.memory) % u64(8)
		cpu.instruction_pointer += 2
	}

	cpu.instructions[3] = proc(cpu: ^CPU, operand: u64) {
		if cpu.memory["A"] == 0 {
			cpu.instruction_pointer += 2
		} else {
			cpu.instruction_pointer = operand
		}
	}

	cpu.instructions[4] = proc(cpu: ^CPU, operand: u64) {
		cpu.memory["B"] = cpu.memory["B"] ~ cpu.memory["C"]
		cpu.instruction_pointer += 2
	}

	cpu.instructions[5] = proc(cpu: ^CPU, operand: u64) {
		append(&cpu.output, combo(operand, cpu.memory) % 8)
		cpu.instruction_pointer += 2
	}

	cpu.instructions[6] = proc(cpu: ^CPU, operand: u64) {
		num := cpu.memory["A"]
		deno := u64(1) << combo(operand, cpu.memory)
		cpu.memory["B"] = num / deno
		cpu.instruction_pointer += 2
	}

	cpu.instructions[7] = proc(cpu: ^CPU, operand: u64) {
		num := cpu.memory["A"]
		deno := u64(1) << combo(operand, cpu.memory)
		cpu.memory["C"] = num / deno
		cpu.instruction_pointer += 2
	}

	return cpu
}

parse_initial_memory_program :: proc(
	input: string,
) -> (
	initial_memory: map[string]u64,
	prog: []u64,
) {
	parts := strings.split(input, "\n\n")

	registers := map[string]u64{}

	for regs in strings.split_lines(parts[0]) {
		reg_parts := strings.split_multi(regs, {" ", ":"})
		num, _ := strconv.parse_u64(reg_parts[3])
		initial_memory[reg_parts[1]] = num
	}

	program := [dynamic]u64{}

	for ins_op, i in strings.split_multi(parts[1], {",", " "}) {
		if i == 0 || i == len(strings.split_multi(parts[1], {",", " "})) {
			continue
		}
		num, _ := strconv.parse_u64(ins_op)
		append(&program, num)
	}

	prog = program[:]
	return
}

are_equal :: proc(left, right: []u64) -> (are_equal: bool) {
	paired := soa_zip(l = left, r = right)
	are_equal = true
	for pair in paired {
		if pair.l != pair.r {
			are_equal = false
			return
		}
	}

	return
}
