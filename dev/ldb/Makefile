all: checkdeps mysql sqlite-lib sqlite db binary
all-sqlite: sqlite-lib sqlite db binary

sqlite-lib:   
		cd sqlite3 && ./configure && make && cd ..
		ar rc sqlite3/libsqlite-linoratix.a sqlite3/*.o

sqlite: #sqlite-lib
	g++ -shared sqlite.cpp -o sqlite-backend.so -Lsqlite3 -lsqlite-linoratix -D_DO_DEBUG_
#	g++ -shared sqlite.cpp -o sqlite-backend.so -Lsqlite3 -lsqlite-linoratix

mysql:
	g++ -shared mysql.cpp -o mysql-backend.so -lmysqlclient

db:
	g++ -shared libldb.cpp -o libldb.so

binary:
	g++ -o main main.cpp -L. -Wl,-R. -ldl -lldb
#	g++ -o main main.cpp -L. -ldl -lldb
	
clean:
	rm *.so
	rm main
	rm *~
	cd sqlite3 && make clean && cd ..

run:
	./main

install:
	install libldb.so /usr/lib
#	ldconfig -l /usr/lib

checkdeps:
	./checkdeps.sh
