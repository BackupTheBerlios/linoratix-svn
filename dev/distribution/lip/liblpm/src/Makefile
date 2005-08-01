all: clean build

build:
	gcc -shared -o liblpm.so resource.c lpm.c

clean:
	-rm *.so
	-rm *~

testapp:
	gcc -o test.bin -L. -llpm test.c

install:
	cp liblpm.so /usr/lib
	mkdir -p /usr/include/lpm
	cp lpm.h resource.h /usr/include/lpm

uninstall:
	rm /usr/lib/liblpm.so
	rm -rf /usr/include/lpm
