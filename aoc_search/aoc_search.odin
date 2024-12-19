package aoc_search

import "core:container/priority_queue"
import "core:fmt"

dijkstra :: proc(grid: $T/[][]$E, start: E, target: E, less: proc(a,b: E)->bool, get_neighbours: proc(grid: T, current: E) -> []E) -> int {
	costs := map[[3]int]int{}
	
	q: priority_queue.Priority_Queue(E)
	priority_queue.init(&q, less, priority_queue.default_swap_proc(E))
	priority_queue.push(&q, start)

	for priority_queue.len(q) > 0 {
		current := priority_queue.pop(&q)

		if current.position == target.position {
				return current.cost
		} else {
			for move in get_neighbours(grid, current) {
				move_recorded_cost, ok := costs[[3]int{move.position.x, move.position.y, int(move.direction)}]
				if !ok {
					move_recorded_cost = max(int)
				}

				if current.cost + move.cost < move_recorded_cost {
					costs[[3]int{move.position.x, move.position.y, int(move.direction)}] = current.cost + move.cost
					move_n := E{}
					move_n = move
					move_n.cost = current.cost + move.cost
					priority_queue.push(&q, move_n)
				}
			}
		}
	}
	return -1
}