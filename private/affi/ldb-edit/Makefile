all: binary

	wxlibs=`wx-config --libs`
	wxcxx=`wx-config --cxxflags`

binary:
	cp ../ldb/libldb.so ../ldb/sqlite-backend.so ../ldb/libldb.h .
	g++ -o ldb-edit ldb-edit.cpp -L. -Wl,-R. -ldl -lldb ${wxlibs} ${wxcxx}
	
clean:
	rm libldb.so
	rm sqlite-backend.so
	rm libldb.h
	rm *.so
	rm ldb-edit
	rm *~

run:
	./ldb-edit

