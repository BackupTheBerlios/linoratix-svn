all: sqlite libpm

sqlite:
	cd sqlite3 && ./configure && make && cd ..
	ar rc sqlite3/libsqlite-linoratix.a sqlite3/*.o

libpm:
	g++ -shared libpm.cpp -o libpm.so -Lsqlite3 -lsqlite-linoratix
	mkdir result >/dev/null 2>&1; mv -vf libpm.so result/

clean:
	cd sqlite3 && make clean && cd ..
	rm -rf result && rm -f *cpp~ && rm -f sqlite3/libsqlite-linoratix.a
