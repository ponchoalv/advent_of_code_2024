SESSION?=123
DAY?=1
CURRENT_FILE?=day_${DAY}.odin

download_input:
ifeq (,$(wildcard ./day_${DAY}_input))
	curl -b "session=${SESSION}" "https://adventofcode.com/2024/day/${DAY}/input" > day_${DAY}_input
endif

run_day: download_input ${CURRENT_FILE}
	odin run ${CURRENT_FILE} -file -o:speed

run_day_no_bounds_check: ${CURRENT_FILE}
	odin run ${CURRENT_FILE} -file --no-bounds-check
