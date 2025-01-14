package bit_utils

Direction :: enum {
	FORWARD,
	DOWN,
	BACKWARD,
	UP,
}

Side :: enum {
	RIGHT,
	BOTTOM,
	LEFT,
	TOP,
}

Direction_Vector :: [Direction][2]int{
	.FORWARD = {0, 1},
	.DOWN = {1, 0},
	.BACKWARD = {0, -1},
	.UP = {-1, 0},
}

Side_Vector :: [Side][2]i16{
	.RIGHT = {0, 1},
	.BOTTOM = {1, 0},
	.LEFT = {0, -1},
	.TOP = {-1, 0},
}

Dir_Vec := Direction_Vector
Side_Vec := Side_Vector

get_direction_left_right :: proc(dir: Direction) -> []Direction {
	dirs := [dynamic]Direction{}
	append(&dirs, Direction((u8(dir) + u8(1)) % u8(4)))
	append(&dirs, Direction((u8(dir) + u8(3)) % u8(4)))
	return dirs[:]
}

// might move this to a library in the future
encode :: proc(x, y:u16, d: u8) -> (combined:u32) {
	// n_x :u32= 10 // Bits for x
    n_y :u32= 10 // Bits for y
    n_d :u32= 8  // Bits for direction

    combined = (u32(x) << (n_y + n_d)) | (u32(y) << n_d) | u32(d)

    return
}

encode_x_y_z_k :: proc(x, y, z, k:i16) -> (combined:u32) {
	// n_x :u32= 8 // Bits for x
    n_y :u32= 8 // Bits for y
    n_z :u32= 8 // Bits for y
    n_k :u32= 8 // Bits for y

    combined = (u32(x) << (n_y + n_z + n_k)) | (u32(y) << (n_z + n_k)) | (u32(z) <<  n_k) | u32(z)

    return
}

decode :: proc (combined: u32) -> (x: u16, y: u16, d: u8) {
    // n_x :u32= 10 // Bits for x
    n_y :u32= 10 // Bits for y
    n_d :u32= 8 // Bits for direction

    d = u8(combined & 0b11111111) // Extract direction (last 2 bits)
    y = u16((combined >> n_d) & 0x3FF) // Extract y (next 10 bits 11 1111 1111)
    x = u16(combined >> (n_y + n_d)) // Extract x (remaining bits)
    return
}

direction_to_u8 :: proc(dir: [2]int) -> u8 {
	switch dir {
		case [2]int{0, 1}:
			return u8(Direction.FORWARD)
		case [2]int{1, 0}:
			return u8(Direction.DOWN)
		case [2]int{0, -1}:
			return u8(Direction.BACKWARD)
		case [2]int{-1, 0}:
			return u8(Direction.UP)
	}
	return 4
}

direction_from_u8 :: proc(dir: Direction) -> [2]int {
	return Dir_Vec[dir]
}

direction_to_side :: proc(dir: [2]i16) -> Side {
	switch dir {
		case [2]i16{0, 1}:
			return .RIGHT
		case [2]i16{1, 0}:
			return .BOTTOM
		case [2]i16{0, -1}:
			return .LEFT
		case [2]i16{-1, 0}:
			return .TOP
	}
	return .TOP
}



// might move this to a library in the future
encode_u32 :: proc(x, y:u32) -> (combined:u64) {
    n_y :u64= 32 // Bits for y
    

    combined = (u64(x) << (n_y) | (u64(y)))

    return
}

decode_u32 :: proc (combined: u64) -> (x: u32, y: u32) {
    n_y :u64= 32 // Bits for y

    y = u32((combined) & 0xFFFFFFFF) // Extract y (next 32 bits 11 1111 1111)
    x = u32(combined >> (n_y)) // Extract x (remaining bits)
    return
}