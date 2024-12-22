package aoc_search

import "core:container/priority_queue"
import "core:fmt"
import "base:runtime"

dijkstra :: proc(grid: $T/[][]$E, start: E, target: E, less: proc(a,b: E)->bool, get_neighbours: proc(grid: T, current: E) -> []E) -> int {
	costs := make(map[[3]int]int, context.temp_allocator)
	
	q: priority_queue.Priority_Queue(E)
	priority_queue.init(&q, less, priority_queue.default_swap_proc(E), 100, context.temp_allocator)
	priority_queue.push(&q, start)

	for priority_queue.len(q) > 0 {
		current := priority_queue.pop(&q)

		if current.position == target.position {
				return current.cost
		} else {
			for &move in get_neighbours(grid, current) {
				move_recorded_cost, ok := costs[[3]int{move.position.x, move.position.y, int(move.direction)}]
				if !ok {
					move_recorded_cost = max(int)
				}

				if current.cost + move.cost < move_recorded_cost {
					costs[[3]int{move.position.x, move.position.y, int(move.direction)}] = current.cost + move.cost
					move.cost = current.cost + move.cost
					priority_queue.push(&q, move)
				}
			}
		}
	}
	return -1
}

@(require_results)
filter_by_with_param :: proc(s: $S/[]$U, size:int, f: proc(g:U, m:int) -> bool, allocator := context.allocator) -> (res: S, err: runtime.Allocator_Error) #optional_allocator_error {
	r := make([dynamic]U, 0, 0, allocator) or_return
	for v in s {
		if f(v,size) {
			append(&r, v)
		}
	}
	return r[:], nil
}