package day_10

import "core:container/bit_array"
import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 36
EXAMPLE_PART_2 :: 81

RESULT_PART_1 :: 698
RESULT_PART_2 :: 1436

Tile :: struct {
	is_head:  bool,
	position: [2]i16,
	step:     u8,
}

main :: proc() {
	fmt.println("Running day_10...")
	test_part_1("day_10_example_input", EXAMPLE_PART_1)
	test_part_2("day_10_example_input", EXAMPLE_PART_2)
	test_part_1("day_10_input", RESULT_PART_1)
	test_part_2("day_10_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)
	grid, headtrails := parse_to_grid(input)

	for headtrail in headtrails {
		result += u64(walk_trail(grid, headtrail))
	}

	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	fmt.println(input)
	grid, headtrails := parse_to_grid(input)

	for headtrail in headtrails {
		result += u64(walk_trail(grid, headtrail, true))
	}

	// fmt.println(walk_trail(grid, headtrails[2], true))

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

get_moves :: proc(grid: [][]Tile, current_position: Tile) -> [][2]i16 {
	grid_len := i16(len(grid))
	next_positions := [dynamic][2]i16{}

	directions := [][2]i16{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

	for coord in directions {
		posible_direction := current_position.position + coord

		if posible_direction.x >= 0 &&
		   posible_direction.y >= 0 &&
		   posible_direction.x < grid_len &&
		   posible_direction.y < grid_len {
			next_tile := grid[posible_direction.x][posible_direction.y]
			if next_tile.step == current_position.step + 1 {
				append(&next_positions, posible_direction)
			}
		}
	}

	return next_positions[:]
}

parse_to_grid :: proc(input: string) -> (grid: [][]Tile, trailheads: []Tile) {
	tiles_grid := [dynamic][]Tile{}
	heads := [dynamic]Tile{}

	for l, y in strings.split_lines(input) {
		if l == "" {
			continue
		}

		tiles := [dynamic]Tile{}

		for c, x in l {
			if c == 0 {
				continue
			}

			tile := Tile {
				is_head  = c == '0',
				position = [2]i16{i16(y), i16(x)},
				step     = u8(c - '0'),
			}

			if tile.is_head {
				append(&heads, tile)
			}
			append(&tiles, tile)
		}
		append(&tiles_grid, tiles[:])
	}

	return tiles_grid[:], heads[:]
}

walk_trail :: proc(grid: [][]Tile, headtrail: Tile, multiple_starts: bool = false) -> u32 {
	grid_len := u16(len(grid))
	tiles := [dynamic]Tile{}
	walked_steps_bits: bit_array.Bit_Array

	trails_count: u32
	q: sa.Small_Array(10, Tile)
	sa.push(&q, headtrail)

	for sa.len(q) > 0 {
		current_tile := sa.pop_back(&q)

		if multiple_starts {
			if current_tile.step == 9 {
				trails_count += 1
				continue
			}
		} else {
			coord_was_set := bit_array.get(&walked_steps_bits, (u16(current_tile.position.x)*grid_len+u16(current_tile.position.y)))

			if !coord_was_set {
				bit_array.set(&walked_steps_bits, (u16(current_tile.position.x)*grid_len+u16(current_tile.position.y)), true)
				if current_tile.step == 9 {
					trails_count += 1
					continue
				}
			}
		}

		for pos in get_moves(grid, current_tile) {
			if multiple_starts {
				sa.push(&q, grid[pos.x][pos.y])
			} else {
				coord_was_set := bit_array.get(&walked_steps_bits, (u16(pos.x)*grid_len+u16(pos.y)))
				if !coord_was_set {
					sa.push(&q, grid[pos.x][pos.y])
				}
			}
		}
	}

	return trails_count
}
