all: checkdeps mysql db binary

mysql:
	g++ -shared mysql.cpp -o mysql.so -lmysqlclient

db:
	g++ -shared libldb.cpp -o libldb.so
	
binary:
	g++ -o main main.cpp -L. -ldl -lldb
	
clean:
	rm *.so
	rm main
	rm *~

run:
	./main

install:
	install libldb.so /usr/lib
#	ldconfig

checkdeps:
	./checkdeps.sh
