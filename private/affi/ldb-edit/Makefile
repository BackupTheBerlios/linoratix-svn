all: binary

binary:
	cp ../../../dev/ldb/libldb.so ../../../dev/ldb/sqlite-backend.so ../../../dev/ldb/libldb.h .
	g++ -o MainFrame.o -c MainFrame.cpp `wxgtk-2.4-config --cxxflags`
	g++ -o ldb-edit.o -c ldb-edit.cpp `wxgtk-2.4-config --cxxflags`
	g++ -o ldb-edit ldb-edit.o MainFrame.o -L. -Wl,-R. -ldl -lldb `wxgtk-2.4-config --libs` `wxgtk-2.4-config --cxxflags`
	
clean:
	rm libldb.h
	rm *.so
	rm *.o
	rm ldb-edit
	rm *~

run:
	./ldb-edit

