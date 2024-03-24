package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

CHUNK_SIZE :: 1048 * 1048

Temp_Info :: struct {
	count: f32,
	min:   int,
	max:   int,
	sum:   f32,
}


print_results :: proc(info: map[string]^Temp_Info, names: [dynamic]string) {
    slice.sort(names[:])
	for name in names {
		t := info[name]
		fmt.printf("%s=%d/%f/%d\n", name, t.min, t.sum / t.count, t.max)
	}
}


main :: proc() {
	file_name := os.args[1]
	f_handler, op_err := os.open(file_name)
	if op_err != 0 {
		fmt.printf("Errord opening file: %s code: \n", file_name, op_err)
		return
	}

	count := 0
	info := make(map[string]^Temp_Info)
	names: [dynamic]string

	loop: for {
		byte_buffer := make([]byte, CHUNK_SIZE)
		read_total, read_err := os.read(f_handler, byte_buffer)
		if read_err != 0 {
			fmt.printf("Error reading file: %s code: %v\n", file_name, read_err)
			return
		}
		if read_total <= 0 {
			fmt.printf("Got to end of file count: %v \n", count)
			break
		}
		s := string(byte_buffer)

		for line in strings.split_iterator(&s, "\n") {
			if strings.trim_space(line) == "" {
				break loop
			}
			parts := strings.split(line, ";")
			if len(parts) < 2 {
				break loop
			}
			name, temp_num := string(parts[0]), parts[1]
			val, conv_ok := strconv.parse_f32(temp_num)
			if !conv_ok {
				fmt.println("error parsing f32")
			}
			append(&names, name)
			if temp, ok := info[name]; ok {
				temp.count += 1
				temp.min = math.min(temp.min, int(val))
				temp.max = math.max(temp.min, int(val))
				temp.sum += val
			} else {
				temp_info := new(Temp_Info)
				temp_info.count = 1
				temp_info.min = int(val)
				temp_info.max = int(val)
				temp_info.sum = val

				info[parts[0]] = temp_info
			}
		}
		count += 1
	}
	print_results(info, names)
}
