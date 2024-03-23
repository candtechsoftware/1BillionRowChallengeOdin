package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math"

CHUNK_SIZE :: 2048 * 2048 * 64

Temp_Info :: struct {
    count: int,
    min: int,
    max: int,
    sum: f32,
}


main :: proc() {
	file_name := os.args[1]
	f_handler, op_err := os.open(file_name)
	if op_err != 0 {
		fmt.printf("Errord opening file: %s code: \n", file_name, op_err)
		return
	}

	count := 0
    info := make(map[string]Temp_Info)

	for {
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
            parts := strings.split(line, ";")
            if temp, ok := info[parts[0]]; ok {
                temp.count += 1
                if val, conv_ok := strconv.parse_f32(parts[1]); conv_ok {
                    temp.min = math.min(temp.min, int(val))
                    temp.max = math.max(temp.min, int(val))
                    temp.sum += val
                }
            }
        }
		count += 1
	}

    fmt.println(info)
}
