package bit_utils

// might move this to a library in the future
encode :: proc(x, y:u16, d: u8) -> u32 {
	n_x :u32= 10 // Bits for x
    n_y :u32= 10 // Bits for y
    n_d :u32= 2  // Bits for direction

    combined: u32 = (u32(x) << (n_y + n_d)) | (u32(y) << n_d) | u32(d)

    return combined
}

decode :: proc (combined: u32) -> (x: u16, y: u16, d: u8) {
    n_x :u32= 10 // Bits for x
    n_y :u32= 10 // Bits for y
    n_d :u32= 2  // Bits for direction

    d = u8(combined & 0b11) // Extract direction (last 2 bits)
    y = u16((combined >> n_d) & 0x3FF) // Extract y (next 10 bits)
    x = u16(combined >> (n_y + n_d)) // Extract x (remaining bits)
    return
}

direction_to_u8 :: proc(dir: [2]int) -> u8 {
	switch dir {
		case [2]int{0, 1}:
			return 0
		case [2]int{1, 0}:
			return 1
		case [2]int{0, -1}:
			return 2
		case [2]int{-1, 0}:
			return 3
	}
	return 4
}