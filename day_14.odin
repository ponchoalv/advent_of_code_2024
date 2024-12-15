package day_14

import "bit_utils"
import "core:container/bit_array"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 12
EXAMPLE_PART_2 :: 1

RESULT_PART_1 :: 232589280
RESULT_PART_2 :: 7569

Robot :: struct {
	p:  [2]int,
	s:  [2]int,
	id: int,
}

Quadrant :: struct {
	tl: [2]int,
	tr: [2]int,
	bl: [2]int,
	br: [2]int,
}

main :: proc() {
	fmt.println("Running day_14...")

	is_example := true
	context.user_ptr = &is_example
	test_part_1("day_14_example_input", EXAMPLE_PART_1)
	test_part_2("day_14_example_input", EXAMPLE_PART_2)
	is_example = false
	context.user_ptr = &is_example

	test_part_1("day_14_input", RESULT_PART_1)
	test_part_2("day_14_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()

	grid: [2]int
	is_example := cast(^bool)context.user_ptr

	if is_example^ {
		grid = {11, 7}
	} else {
		grid = {101, 103}
	}

	input := read_file(filename)
	// fmt.println(input)
	robots := parse_robots_input(input)
	robots = get_robots_position_after_seconds(robots, grid, 100)
	quadrants := get_quadrants(grid)
	result = get_safety_factor(robots, quadrants)
	elapsed := time.since(start)
	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))

	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	grid: [2]int
	is_example := cast(^bool)context.user_ptr

	if is_example^ {
		grid = {11, 7}
	} else {
		grid = {101, 103}
	}

	robots := parse_robots_input(input)

	result = 1
	for true {
		updated_robots := get_robots_position_after_seconds_map(robots, grid, int(result))
		if len(updated_robots) == len(robots) {
			fmt.println(result)

			for y in 0 ..< grid.y {
				for x in 0 ..< grid.x {
					if _, found := updated_robots[{x, y}]; found {
						fmt.print("*")
					} else {
						fmt.print(".")
					}
				}
				fmt.println("")
			}

			fmt.println("")
			break
		}

		result += 1
	}

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

parse_robots_input :: proc(input: string) -> []Robot {
	robots := [dynamic]Robot{}
	for l, i in strings.split_lines(input) {
		if l == "" {
			continue
		}

		robot := Robot{}

		parts := strings.split_multi(l, []string{"p", "=", ",", "v", " "})
		px := strconv.atoi(parts[2])
		py := strconv.atoi(parts[3])
		robot.p.x, robot.p.y = px, py

		vx := strconv.atoi(parts[6])
		vy := strconv.atoi(parts[7])
		robot.s.x, robot.s.y = vx, vy
		robot.id = i

		append(&robots, robot)

	}

	return robots[:]
}

get_robots_position_after_seconds :: proc(
	robots: []Robot,
	grid_size: [2]int,
	seconds: int,
) -> []Robot {
	robots_new_positions := [dynamic]Robot{}
	for robot in robots {
		append(&robots_new_positions, update_position(robot, grid_size, seconds))
	}

	return robots_new_positions[:]
}

get_robots_position_after_seconds_map :: proc(
	robots: []Robot,
	grid_size: [2]int,
	seconds: int,
) -> map[[2]int]Robot {
	new_robots := map[[2]int]Robot{}
	for robot in robots {
		new_robot := update_position(robot, grid_size, seconds)
		new_robots[new_robot.p] = new_robot
	}

	return new_robots
}

update_position :: proc(robot: Robot, grid_size: [2]int, seconds: int) -> Robot {
	new_position_robot := robot
	nx := (seconds * robot.s.x) + robot.p.x
	ny := (seconds * robot.s.y) + robot.p.y

	new_position_robot.p.x =
		nx % grid_size.x if nx >= 0 || nx % grid_size.x == 0 else grid_size.x + nx % grid_size.x
	new_position_robot.p.y =
		ny % grid_size.y if ny >= 0 || ny % grid_size.y == 0 else grid_size.y + ny % grid_size.y

	return new_position_robot
}


get_safety_factor :: proc(robots: []Robot, quadrants: [4]Quadrant) -> (result: u64) {
	quadrant_count := [4]int{}
	track_robots := map[int]Robot{}
	for robot in robots {
		for quadrant, i in quadrants {
			if _, robot_was_counted := track_robots[robot.id]; robot_was_counted {
				continue
			}

			if is_robot_in_quadrant(robot, quadrant) {
				track_robots[robot.id] = robot
				quadrant_count[i] += 1
			}
		}
	}

	result = u64(quadrant_count[0] * quadrant_count[1] * quadrant_count[2] * quadrant_count[3])

	return
}

is_robot_in_quadrant :: proc(robot: Robot, quadrant: Quadrant) -> bool {
	is_bellow_tl := robot.p.x >= quadrant.tl.x && robot.p.y >= quadrant.tl.y
	is_bellow_tr := robot.p.x <= quadrant.tr.x && robot.p.y >= quadrant.tr.y
	is_above_bl := robot.p.x >= quadrant.bl.x && robot.p.y <= quadrant.bl.y
	is_above_br := robot.p.x <= quadrant.br.x && robot.p.y <= quadrant.br.y

	return is_bellow_tl && is_bellow_tr && is_above_bl && is_above_br

}

get_quadrants :: proc(grid: [2]int) -> [4]Quadrant {
	return [4]Quadrant {
		{
			tl = {0, 0},
			tr = {grid.x / 2 - 1, 0},
			bl = {0, grid.y / 2 - 1},
			br = {grid.x / 2 - 1, grid.y / 2 - 1},
		},
		{
			tl = {0, (grid.y / 2) + 1},
			tr = {grid.x / 2 - 1, (grid.y / 2) + 1},
			bl = {0, grid.y - 1},
			br = {grid.x / 2 - 1, grid.y - 1},
		},
		{
			tl = {(grid.x / 2) + 1, 0},
			tr = {grid.x - 1, 0},
			bl = {(grid.x / 2) + 1, grid.y / 2 - 1},
			br = {grid.x - 1, grid.y / 2 - 1},
		},
		{
			tl = {(grid.x / 2) + 1, (grid.y / 2) + 1},
			tr = {grid.x - 1, (grid.y / 2) + 1},
			bl = {(grid.x / 2) + 1, grid.y},
			br = {grid.x - 1, grid.y - 1},
		},
	}
}
