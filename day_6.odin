package day_6

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 41
EXAMPLE_PART_2 :: 6

RESULT_PART_1 :: 5101
RESULT_PART_2 :: 1951

Direction :: [2]int

DIRECTION_FORWARD       :: Direction{0, 1}
DIRECTION_BACKWARD      :: Direction{0, -1}
DIRECTION_DOWN          :: Direction{1, 0}
DIRECTION_UP            :: Direction{-1, 0}
DIRECTION_DOWN_FORWARD  :: Direction{1, 1}
DIRECTION_UP_FORWARD    :: Direction{-1, 1}
DIRECTION_DOWN_BACKWARD :: Direction{1, -1}
DIRECTION_UP_BACKWARD   :: Direction{-1, -1}


main :: proc() {
	fmt.println("Running day_6...")
	test_part_1("day_6_example_input", EXAMPLE_PART_1)
	test_part_2("day_6_example_input", EXAMPLE_PART_2)
	test_part_1("day_6_input", RESULT_PART_1)
	test_part_2("day_6_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()

	input := read_file(filename)
	result = count_guard_steps(input)
	elapsed := time.since(start)

	fmt.printf("time elapsed: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string)  -> (result: u64) {
	start := time.now()

	input := read_file(filename)
	result = count_guard_looping_obstacles(input)
	elapsed := time.since(start)

	fmt.printf("time elapsed: %fms\n", time.duration_milliseconds(elapsed))
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
	walk through a source of type []string in the direction and as long as it reached the specified token.
	Record what was read as a result, return true when read is out of bounds and false if it needs to rotate
		starting_point: (y,x)
		Directions:
			- ( 0,  1)	-> forward
			- ( 0, -1)	-> backward
			- ( 1,  0)	-> down
			- (-1,  0)	-> up
			- ( 1,  1)	-> down forward diagonal
			- (-1,  1)	-> up forward diagonal
			- ( 1, -1)	-> down backward diagonal
			- (-1, -1)	-> up backward diagonal
*/
walk_until_in_direction :: proc(
	src: []string,
	starting_point: [2]int,
	direction: Direction,
	walked_steps: ^map[[2]int]bool,
	token: byte,
) -> (
	[2]int,
	bool,
) #no_bounds_check {
	current_poss:= starting_point

	for src[current_poss[0]][current_poss[1]] != token {
		// fmt.printf("%r", src[current_poss[0]][current_poss[1]])
		current_poss += direction
		// fmt.println(current_poss)
		if current_poss[0] < 0 ||
	   		current_poss[0] >= len(src[0]) ||
	   		current_poss[1] < 0 ||
	   		current_poss[1] >= len(src) - 1 {
	   		
	   		walked_steps[current_poss-direction]=true

			return (current_poss-direction), true
		}

		walked_steps[current_poss-direction]=true

	}

	return (current_poss - direction), false
}

/*
	Rotate a direction 90 degrees:
		(0, 1) (forward) -> (1, 0) -> down
		(1, 0) (down) -> (0, -1) -> backward
		(0, -1) (backward) -> (-1, 0) -> up
		(-1, 0) (up) -> (0, -1) -> forward
*/
turn_right :: proc(direction: Direction) -> Direction {
	switch direction {
		case DIRECTION_FORWARD:
			return DIRECTION_DOWN
		case DIRECTION_DOWN:
			return DIRECTION_BACKWARD
		case DIRECTION_BACKWARD:
			return DIRECTION_UP
		case DIRECTION_UP:
			return DIRECTION_FORWARD
	}

	return direction
}

/*
	find starting point by token, and return a boolean if it was found or not
*/
find_starting_point :: proc(src: []string, token: byte) -> ([2]int, bool) #no_bounds_check {
	for y in 0..<len(src) {
		for x in 0..<len(src[0]) {
			if src[y] == "" {
				continue
			}

			if src[y][x] == token {
				return [2]int{y,x}, true
			}
		}
	}

	return [2]int{}, false
}

/*
	- find starting point (we will assume direction is up)
	- walk map until we reach the token '#'
	- turn right when found a token
	- we assume that the starting direction is UP
*/
count_guard_steps :: proc(input: string) -> u64 #no_bounds_check {
	lines := strings.split_lines(input)
	current_poss, starting_point_ok := find_starting_point(lines, '^')
	direction := DIRECTION_UP
	walked_steps := map[[2]int]bool{}
	guard_finished_walk := false

	if !starting_point_ok {
		fmt.panicf("starting point not found with token: '%v'", '^')
	}

	for !guard_finished_walk {
		current_poss, guard_finished_walk = walk_until_in_direction(lines, current_poss, direction, &walked_steps,'#')
		if !guard_finished_walk {
			direction = turn_right(direction)
		}
	}

	// fmt.println(walked_steps)

	return u64(len(walked_steps))
}

/*
	- find starting point (we will consider direction is up)
	- walk map until we reach the token '#'
	- rotate right degrees when found a token
	- we assume that the starting direction is UP
	- record the path the guard follows
	- add obstructions to that path and check if guard is looping
*/
count_guard_looping_obstacles :: proc(input: string) -> u64 #no_bounds_check {
	lines := strings.split_lines(input)
	starting_poss, starting_point_ok := find_starting_point(lines, '^')
	current_poss := starting_poss
	direction := DIRECTION_UP

	walked_steps := map[[2]int]bool{}
	walked_steps_loop := map[[2]int]bool{}
	turned_steps_loop := map[[2]int][2]Direction{}
	
	guard_finished_walk := false
	result: u64
	loop_found := false
	line: []u8

	if !starting_point_ok {
		fmt.panicf("starting point not found with token: '%v'", '^')
	}

	// record guard path
	for !guard_finished_walk {
		current_poss, guard_finished_walk = walk_until_in_direction(lines, current_poss, direction, &walked_steps,'#')
		if !guard_finished_walk {
			direction = turn_right(direction)
		}
	}

	// add obstructions in the walked steps
	for coord in walked_steps {
		// cannot add obstacle in starting point
		if coord == starting_poss {
			continue
		}

		clear(&walked_steps_loop)
		clear(&turned_steps_loop)

		current_poss = starting_poss
		direction = DIRECTION_UP
		previous_line := strings.clone(lines[coord[0]])
		line = transmute([]u8)lines[coord[0]]
		line[coord[1]] = '#'
		lines[coord[0]] = transmute(string)line
		guard_finished_walk = false
		loop_found = false

		for !loop_found && !guard_finished_walk {
			current_poss, guard_finished_walk = walk_until_in_direction(lines, current_poss, direction, &walked_steps_loop,'#')
			if !guard_finished_walk {
				// loop would be if we are in a tile facing the same direction as before
				direction = turn_right(direction)
				if v, ok := turned_steps_loop[current_poss]; ok && (v[0]==direction || v[1]==direction) {
					result += 1
					loop_found = true
				}
				if v, ok := turned_steps_loop[current_poss]; ok {
					v[1] = direction
					turned_steps_loop[current_poss]=v
				} else {
					turned_steps_loop[current_poss] = [2]Direction{direction, direction}
				}
				
			}
		}

		lines[coord[0]] = previous_line
	}

	return result
}