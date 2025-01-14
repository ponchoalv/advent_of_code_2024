package aoc_math

import "core:math"

// I'm sure there must be a library in odin for this
get_digits :: proc(num: u64) -> (count: u64) {
	num := num
	for num > 0 {
		num = num / 10
		count += 1
	}

	return
}

split_number :: proc(num: u64, digits: u64) -> (front, back: u64) {
	divider := u64(math.pow(f64(10), f64(digits / 2)))

	front = num / divider
	back = num - (front * divider)
	return
}