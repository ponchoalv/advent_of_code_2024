package slice_helpers

/*
Will need to get elements sorted first
*/
group_by :: proc(slice: $T/[]$E, group_by_proc: proc(a, b: E) -> bool) -> [][]E {
    groups :=[dynamic][]E{}

    if len(slice) == 0 {
        return groups[:] // Return empty groups if input slice is empty
    }

    current_group := [dynamic]E{}
    append(&current_group, slice[0])

    for i := 1; i < len(slice); i += 1 {
        if group_by_proc(slice[i-1], slice[i]) {
            append(&current_group, slice[i]);
        } else {
             append(&groups, current_group[:]);
            current_group = [dynamic]E{}
            append(&current_group, slice[i]);
        }
    }

    // Add the last group
    append(&groups, current_group[:]);

    return groups[:];
}

group_by_distance :: proc(a, b: [2]int) -> bool {
	return abs(a.x-b.x) + abs(a.y-b.y) == 1
}

/*
main :: proc() {
    slice := [][2]int{ {1, 2}, {1, 3},  {1, 4}, {423, 3}, {4, 5} }

    group_by_proc :: proc(a, b: [2]int) -> bool {
        return abs(a.x-b.x) + abs(a.y-b.y) == 1
    }

    grouped := group_by(slice, group_by_proc)

    for group in grouped {
        fmt.println(group);
    }
}

