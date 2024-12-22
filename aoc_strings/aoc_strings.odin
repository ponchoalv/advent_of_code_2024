package aoc_strings

import "core:strings"

generateCombinations :: proc(lists: [][]string) -> []string {
	// Si no hay listas, retornamos un slice vacío
	if len(lists) == 0 {
		return []string{}
	}

	// Si solo hay una lista, retornamos sus elementos
	if len(lists) == 1 {
		return lists[0]
	}

	// Obtenemos las combinaciones del resto de las listas
	restCombinations := generateCombinations(lists[1:])

	// Si no hay más combinaciones, retornamos la primera lista
	if len(restCombinations) == 0 {
		return lists[0]
	}

	result := make([dynamic]string, context.temp_allocator)

	// Para cada elemento en la primera lista
	for first in lists[0] {
		// Lo combinamos con cada combinación del resto
		for rest in restCombinations {
			conc, _ := strings.concatenate([]string{first, rest})
			append(&result, conc)
		}
	}

	return result[:]
}
