package day_12

import "bit_utils"
import "core:container/bit_array"
import sa "core:container/small_array"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"
import "slice_helpers"

EXAMPLE_PART_1 :: 1930
EXAMPLE_PART_2 :: 1206

RESULT_PART_1 :: 1483212
RESULT_PART_2 :: 897062

Plot :: struct {
	position:   [2]i16,
	plot_type:  u8,
	neighbours: u8,
	edges:      []bit_utils.Side,
}

PlotArea :: struct {
	plot_type: u8,
	plots:     []Plot,
}

SideAligne :: struct {
	side: bit_utils.Side,
	pos:  i16,
}

main :: proc() {
	fmt.println("Running day_12...")
	test_part_1("day_12_example_input", EXAMPLE_PART_1)
	test_part_2("day_12_example_input", EXAMPLE_PART_2)
	test_part_1("day_12_input", RESULT_PART_1)
	test_part_2("day_12_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = get_plot_map_price(input)
	elapsed := time.since(start)

	fmt.printf("time elapsed computing operators: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	result = get_plot_map_price(input, true)
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

get_plot_map_price :: proc(input: string, with_bulk_discount: bool = false) -> (result: u64) {
	plot_map := [dynamic][]Plot{}

	lines := strings.split_lines(input)
	len_matrix := len(lines) - 1 //because of empty new line
	grouped_plots: bit_array.Bit_Array

	for y in 0 ..< len_matrix {
		tiles := [dynamic]Plot{}
		for x in 0 ..< len_matrix {
			tile := Plot {
				position  = {i16(y), i16(x)},
				plot_type = u8(lines[y][x]),
			}
			append(&tiles, tile)
		}
		append(&plot_map, tiles[:])
	}

	for y in 0 ..< len_matrix {
		for x in 0 ..< len_matrix {
			current_plot := plot_map[y][x]
			if !bit_array.get(
				&grouped_plots,
				bit_utils.encode(
					u16(current_plot.position.x),
					u16(current_plot.position.y),
					current_plot.plot_type,
				),
			) {
				result += get_price(
					get_plot_area(plot_map[:], current_plot, &grouped_plots),
					with_bulk_discount,
				)
			}
		}
	}
	return
}

distance :: proc(a,b:[2]i16) -> i16 {
	return abs(a.x-b.x) + abs(a.y-b.y)
}

by_x :: proc(i, j: [2]i16) -> bool {
	return i.x < j.x || (i.x == j.x && i.y < i.y)
}

by_y :: proc(i, j: [2]i16) -> bool {
	return i.y < j.y || (i.y == j.y && i.x < j.x)
}

count_edges :: proc(coords: [][2]i16) -> (perimiter: i16) {
	// Initialize variables
	track_coords: bit_array.Bit_Array
	groups := [dynamic][][2]i16{}

	// Helper function to check adjacency (Manhattan distance = 1)
	is_adjacent :: proc(a: [2]i16, b: [2]i16) -> bool {
		return (abs(a.x - b.x) + abs(a.y - b.y)) == 1
	}

	// Iterate over all coordinates
	for i in 0 ..< len(coords) {
		coord := coords[i]

		// Skip if already visited
		exists := bit_array.get(
			&track_coords,
			bit_utils.encode(u16(coord.x), u16(coord.y), 0),
		)
		if exists {
			continue
		}

		// Start a new group
		group := [dynamic][2]i16{}
		queue : sa.Small_Array(2, [2]i16)

		bit_array.set(&track_coords, bit_utils.encode(u16(coord.x), u16(coord.y), 0))


		sa.push(&queue, coord)
		// BFS to find all connected coordinates
		for sa.len(queue) > 0 {
			current := sa.pop_back(&queue)

			append(&group, current)

			// Find all adjacent, unvisited neighbors
			for j in 0 ..< len(coords) {
				neighbor := coords[j]
				if is_adjacent(current, neighbor) {
					neighbor_exists := bit_array.get(
						&track_coords,
						bit_utils.encode(u16(neighbor.x), u16(neighbor.y), 0),
					)
					if !neighbor_exists {
						bit_array.set(&track_coords, bit_utils.encode(u16(neighbor.x), u16(neighbor.y), 0))
						sa.push(&queue, neighbor)
					}
				}
			}
		}

		// Store the completed group
		append(&groups, group[:])
	}
	// fmt.println(groups)
	return i16(len(groups))
}

group_by_distance :: proc(a, b: [2]i16) -> bool {
	return abs(a.x-b.x) + abs(a.y-b.y) == 1
}

count_edges_failed :: proc(coords: [][2]i16) -> (perimiter: i16) {
	groups := slice_helpers.group_by(coords, group_by_distance)

	perimiter = i16(len(groups))
	return
}

// count intersections between edge plots to get an idea of the amount of sides we got in the area
get_perimiter :: proc(plot_area: PlotArea) -> (perimiter: u64) {
	track_top := [dynamic][2]i16{}
	track_bottom := [dynamic][2]i16{}
	track_left := [dynamic][2]i16{}
	track_right := [dynamic][2]i16{}

	// group coordinates by edge type
	for plot in plot_area.plots {
		for edge in plot.edges {
			switch edge {
			case .TOP:
				append(&track_top, plot.position)
			case .BOTTOM:
				append(&track_bottom, plot.position)
			case .LEFT:
				append(&track_left, plot.position)
			case .RIGHT:
				append(&track_right, plot.position)
			}
		}
	}

	// fmt.println(rune(plot_area.plot_type), "TOP")
	// fmt.println(track_top)
	// slice.stable_sort_by(track_top[:], by_x)
	top := count_edges(track_top[:])
	// fmt.println(top)

	// fmt.println(rune(plot_area.plot_type), "BOTTOM")
	// fmt.println(track_bottom)
	// slice.stable_sort_by(track_bottom[:], by_x)
	bottom := count_edges(track_bottom[:])
	// fmt.println(bottom)

	// fmt.println(rune(plot_area.plot_type), "LEFT")
	// fmt.println(track_left)
	// slice.stable_sort_by(track_left[:], by_y)
	left := count_edges(track_left[:])
	// fmt.println(left)

	// fmt.println(rune(plot_area.plot_type), "RIGHT")
	// fmt.println(track_right)
	slice.stable_sort_by(track_right[:], by_y)
	right := count_edges(track_right[:])
	// fmt.println(right)

	return u64(top + bottom + left + right)
}

get_price :: proc(plot_area: PlotArea, with_bulk_discount: bool = false) -> u64 {
	area := u64(len(plot_area.plots))
	perimiter: u64

	if with_bulk_discount {
		perimiter = get_perimiter(plot_area)
	} else {
		for plot, i in plot_area.plots {
			perimiter += (4 - u64(plot.neighbours))
		}
	}

	return area * perimiter
}

get_neighbours :: proc(
	plot_map: [][]Plot,
	current_plot: Plot,
) -> (
	neighbours: [][2]i16,
	edges: []bit_utils.Side,
) {
	grid_len := i16(len(plot_map))
	next_positions := [dynamic][2]i16{}
	sides := [dynamic]bit_utils.Side{}
	directions := [][2]i16{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

	for coord in directions {
		posible_direction := current_plot.position + coord

		if posible_direction.x >= 0 &&
		   posible_direction.y >= 0 &&
		   posible_direction.x < grid_len &&
		   posible_direction.y < grid_len {
			next_plot := plot_map[posible_direction.x][posible_direction.y]
			if next_plot.plot_type == current_plot.plot_type {
				append(&next_positions, posible_direction)
			} else {
				append(&sides, bit_utils.direction_to_side(coord))
			}
		} else {
			append(&sides, bit_utils.direction_to_side(coord))
		}
	}

	neighbours = next_positions[:]
	edges = sides[:]

	return
}

get_plot_area :: proc(
	plot_map: [][]Plot,
	plot: Plot,
	clustered_plots: ^bit_array.Bit_Array,
) -> (
	result: PlotArea,
) {
	plots := [dynamic]Plot{}
	q: sa.Small_Array(200, Plot)
	sa.push(&q, plot)

	for sa.len(q) > 0 {
		current_plot := sa.pop_back(&q)
		current_plot_neighbours, edges := get_neighbours(plot_map, current_plot)
		current_plot.neighbours = u8(len(current_plot_neighbours))
		current_plot.edges = edges

		coord_was_set := bit_array.get(
			clustered_plots,
			bit_utils.encode(
				u16(current_plot.position.x),
				u16(current_plot.position.y),
				current_plot.plot_type,
			),
		)

		if coord_was_set {
			continue
		}

		bit_array.set(
			clustered_plots,
			bit_utils.encode(
				u16(current_plot.position.x),
				u16(current_plot.position.y),
				current_plot.plot_type,
			),
			true,
		)

		append(&plots, current_plot)


		for pos in current_plot_neighbours {
			plot_at_pos := plot_map[pos.x][pos.y]
			coord_was_set := bit_array.get(
				clustered_plots,
				bit_utils.encode(u16(pos.x), u16(pos.y), plot_at_pos.plot_type),
			)
			if !coord_was_set {
				sa.push(&q, plot_at_pos)
			}
		}
	}

	result.plot_type = plot.plot_type
	// slice.stable_sort_by(plots[:], plots_sort_y)
	// fmt.println(plots[:])
	result.plots = plots[:]
	// fmt.println(result, get_price(result))
	return
}
