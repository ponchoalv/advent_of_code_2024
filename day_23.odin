package day_23

import "core:container/queue"
import "core:container/topological_sort"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

EXAMPLE_PART_1 :: 7
EXAMPLE_PART_2 :: "co,de,ka,ta"

RESULT_PART_1 :: 1200
RESULT_PART_2 :: "ag,gh,hh,iv,jx,nq,oc,qm,rb,sm,vm,wu,zr"

main :: proc() {
	fmt.println("Running day_23...")
	test_part_1("day_23_example_input", EXAMPLE_PART_1)
	test_part_2("day_23_example_input", EXAMPLE_PART_2)
	test_part_1("day_23_input", RESULT_PART_1)
	test_part_2("day_23_input", RESULT_PART_2)
}

part_1 :: proc(filename: string) -> (result: u64) {
	start := time.now()
	input := read_file(filename)
	// fmt.println(input)

	list := strings.split_lines(input)
	grouped_computers := map[string]map[string]string{}


	for l in list {
		if l == "" {
			continue
		}

		splitted := strings.split(l, "-")

		for s, i in splitted {
			if s in grouped_computers {
				st := splitted[i - 1] if i > 0 else splitted[i + 1]
				maped := grouped_computers[s]
				maped[st] = st
				grouped_computers[s] = maped
			} else {
				new_map := map[string]string{}
				new_map[splitted[i - 1] if i > 0 else splitted[i + 1]] =
					splitted[i - 1] if i > 0 else splitted[i + 1]
				grouped_computers[s] = new_map
			}
		}
	}

	net_3 := map[string]bool{}
	for pc, m in grouped_computers {
		pc2s, _ := slice.map_keys(m)
		for pc2 in pc2s {
			pc3s, _ := slice.map_keys(grouped_computers[pc2])
			for pc3 in pc3s {
				if pc in grouped_computers[pc3] {
					val := slice.clone([]string{pc, pc2, pc3})
					slice.sort(val)
					key := strings.join(val, ",")
					if !(key in net_3) {
						net_3[key] = true
					}
				}
			}
		}
	}

	for k in net_3 {
		if strings.has_prefix(k, "t") || strings.contains(k, ",t") {
			result += 1
		}
	}

	elapsed := time.since(start)

	fmt.printf("time elapsed in part 1: %fms\n", time.duration_milliseconds(elapsed))
	return
}

part_2 :: proc(filename: string) -> (result: string) {
	start := time.now()
	input := read_file(filename)
	list := strings.split_lines(input)
	grouped_computers := map[string]map[string]string{}


	for l in list {
		if l == "" {
			continue
		}

		splitted := strings.split(l, "-")

		for s, i in splitted {
			if s in grouped_computers {
				st := splitted[i - 1] if i > 0 else splitted[i + 1]
				maped := grouped_computers[s]
				maped[st] = st
				grouped_computers[s] = maped
			} else {
				new_map := map[string]string{}
				new_map[splitted[i - 1] if i > 0 else splitted[i + 1]] =
					splitted[i - 1] if i > 0 else splitted[i + 1]
				grouped_computers[s] = new_map
			}
		}
	}

	biggest_network := min(int)
	response := string{}
	for pc in grouped_computers {
		network := get_biggest_network_for_computer(grouped_computers, pc)
		biggest_network = max(biggest_network, len(network))
		if len(network) == biggest_network {
			response = network
		}
	}

	result = response

	elapsed := time.since(start)

	fmt.printf("time elapsed in part 2: %fms\n", time.duration_milliseconds(elapsed))
	return
}

get_biggest_network_for_computer :: proc(
	grouped_computers: map[string]map[string]string,
	key: string,
) -> string {
	result := make([][dynamic]string, len(grouped_computers[key]))
	defer delete(result)
	nets := grouped_computers[key]
	nets_slice, _ := slice.map_keys(nets)

	for &l in result {
		append(&l, key)
	}

	for pc in nets_slice {
		matched_count := 0
		for pc2 in nets_slice {
			if pc == pc2 {continue}
			if pc in grouped_computers[pc2] {
				matched_count += 1
			}
		}

		append(&result[matched_count], pc)
	}

	network := string{}
	best := min(int)

	/* the first that have >1 means that is the biggest cluster of networks
		This also works for my input:
			slice.sort((result[len(result)-2])[:])
			network := strings.join((result[len(result)-2])[:], ",")
		if the first group matched means that all the connections of that pc are part of cluster,
		if the next one match, means that all the pcs connected to the current pc but 1 are part of the same network
	*/
	#reverse for &res, i in result {
		if len(res) > 1 && len(res) >= len(result) {
			slice.sort(res[:])
			network = strings.join(res[:i + 2], ",")
			break
		}
	}

	return network
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
		"(%s): part 2 result was %s and expected was %s",
		input,
		part_2_result,
		expected_result,
	)
	fmt.printf("(%s) part 2 result: %s\n", input, part_2_result)
}

read_file :: proc(filename: string) -> string {
	data, ok := os.read_entire_file(filename)
	if !ok {
		panic("failed reading file")
	}

	return string(data)
}
