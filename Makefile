build:
	odin build . -o:speed ./build/app

run-test:
	./build/app ./data/test.csv

clean:
	rm -rf build
