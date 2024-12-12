package table_slot

import "core:mem"

Table_Slot :: struct($Key, $Value: typeid) {
	occupied: bool,
	hash:     u32,
	key:      Key,
	value:    Value,
}

TABLE_SIZE_MIN :: 32
Table :: struct($Key, $Value: typeid) {
	count:     int,
	allocator: mem.Allocator,
	slots:     []Table_Slot(Key, Value),
}

// Only allow types that are specializations of a (polymorphic) slice
make_slice :: proc($T: typeid/[]$E, len: int) -> T {
	return make(T, len)
}

// Only allow types that are specializations of `Table`
allocate :: proc(table: ^$T/Table, capacity: int) {
	c := context
	if table.allocator.procedure != nil {
		c.allocator = table.allocator
	}
	context = c

	table.slots = make_slice(type_of(table.slots), max(capacity, TABLE_SIZE_MIN))
}

expand :: proc(table: ^$T/Table) {
	c := context
	if table.allocator.procedure != nil {
		c.allocator = table.allocator
	}
	context = c

	old_slots := table.slots
	defer delete(old_slots)

	cap := max(2 * len(table.slots), TABLE_SIZE_MIN)
	allocate(table, cap)

	for s in old_slots {
		if s.occupied {
			put(table, s.key, s.value)
		}
	}
}

// Polymorphic determination of a polymorphic struct
// put :: proc(table: ^$T/Table, key: T.Key, value: T.Value) {
put :: proc(table: ^Table($Key, $Value), key: Key, value: Value) {
	hash := get_hash(key) // Ad-hoc method which would fail in a different scope
	index := find_index(table, key, hash)
	if index < 0 {
		if f64(table.count) >= 0.75 * f64(len(table.slots)) {
			expand(table)
		}
		assert(table.count <= len(table.slots))

		index = int(hash % u32(len(table.slots)))

		for table.slots[index].occupied {
			if index += 1; index >= len(table.slots) {
				index = 0
			}
		}

		table.count += 1
	}

	slot := &table.slots[index]
	slot.occupied = true
	slot.hash = hash
	slot.key = key
	slot.value = value
}


// find :: proc(table: ^$T/Table, key: T.Key) -> (T.Value, bool) {
find :: proc(table: ^Table($Key, $Value), key: Key) -> (Value, bool) {
	hash := get_hash(key)
	index := find_index(table, key, hash)
	if index < 0 {
		return Value{}, false
	}
	return table.slots[index].value, true
}

find_index :: proc(table: ^Table($Key, $Value), key: Key, hash: u32) -> int {
	if len(table.slots) <= 0 {
		return -1
	}

	index := int(hash % u32(len(table.slots)))
	for table.slots[index].occupied {
		if table.slots[index].hash == hash {
			if table.slots[index].key == key {
				return index
			}
		}

		if index += 1; index >= len(table.slots) {
			index = 0
		}
	}

	return -1
}

get_hash :: proc(s: string) -> u32 { 	// fnv32a
	h: u32 = 0x811c9dc5
	for i in 0 ..< len(s) {
		h = (h ~ u32(s[i])) * 0x01000193
	}
	return h
}
