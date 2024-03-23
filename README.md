# 1️⃣🐝🏎️ The One Billion Row Challenge

- Challenge blog post: https://www.morling.dev/blog/one-billion-row-challenge/
- Challenge repository: https://github.com/gunnarmorling/1brc

The challenge: **compute simple floating-point math over 1 billion rows. As
fast as possible, without dependencies.**

Implemented in Odin.

I have seen this challenge in multiple places and decided I wanted to test the
speed of Odin and maybe try some of the `soa` features in the language. I knew
going in that the biggest bottleneck would be reading in the file so I decided
to tackle that first.


### Note

Computer specs:<br>
Intel(R) Core(TM) i9-10900K CPU @ 3.70GHz<br>
2x16gb DDR4 2400 MT/s<br>
OS Pop!_OS Version: 22.04 LTS<br>

All test were run with odin compiler optimization `-o:speed`

### Reading The File

I started doing what is recommended in the docs and jsut do a simple call to
`os.read_entire_file()`.

Code looked something like this:11
```odin
package main

import "core:fmt"
import "core:os"

main :: proc() {
    file_name := os.args[1]
	data, err := os.read_entire_file(file_name)
	if !err {
		fmt.println("Error reading entire file")

	}
	defer delete(data, context.allocator)


}
```

This was surpisingly fast for a builtin function that just loads the entire
file. With a cold run averaging `~8 seconds` and subsequent runs ran around
`~5 seconds`.
```bash
time ./1brow_odin ./measurements.txt > /dev/null
./1brow_odin ./measurements.txt >
user 4.67s
system 93%
cpu 4.987 total
```

Next Approach was the buffered approach using the built in `bufio` package but
this was much slower than the approach above event with playing with buffer
sizes consistenly got times longer than `~2 mins` even with optimizations on.

```odin
main :: proc() {
	file_name := os.args[1]
	f_handler, err := os.open(file_name)
	if err != 0 {
		fmt.printf("Error opening file %s\n", file_name)
	}
	defer os.close(f_handler)

	reader: bufio.Reader
	buffer: [2048]byte
	bufio.reader_init_with_buf(&reader, os.stream_from_handle(f_handler), buffer[:])
    defer bufio.reader_destroy(&reader)
    for {
        line, err := bufio.reader_read_string(&reader, '\n', context.allocator)
        if err != nil {
		    fmt.printf("Error reading file to string\n")
            break
        }
    }

}

```

Another interesting approach was ths `#load` implementation, it is a compiler
builtin which loads the file at compile time which as you would guess the
compile time was pretty nuts and kept getting segfaults. I did not spend time
to figure out why, maybe another day. I did want to make sure I read a file
during runtime which seemed more in the spirit of the challenge also have a
huge binary like this doesn't make too much sense. On to the next attempt!


The next implementation took around `~4.4 seconds` on average.
```bash
./1brow_odin ./measurements.txt >
user 3.67s
system 93%
cpu 4.434 total
```

```odin
package main

import "core:fmt"
import "core:os"

CHUNK_SIZE :: 2048 * 2048 * 64

main :: proc() {
	file_name := os.args[1]
	f_handler, op_err := os.open(file_name)
	if op_err != 0 {
		fmt.printf("Errord opening file: %s code: \n", file_name, op_err)
		return
	}

	count := 0
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
		count += 1
	}

}
```
