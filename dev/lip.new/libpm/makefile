all: build

build:
	g++ -shared libpm.cpp -o libpm.so -L. -lsqlite

clean:
	rm *.so
	rm *.o
