#!/bin/bash
# jaaaa ich sollte mir mal anschaun wie makefiles gehen :P

g++ -shared libtest.cpp -o libtest.so			# die ".so" muss mit lib beginnen weilse sonst der linker net findet
g++ test.cpp -o test -L. -Wl,-R. -ltest	 		# -R pfad der libs; -l name der lib; -Wl komma liste an den linker 
							# geben; -L keine ahnung; -o resultat datei
if [ "$?" == "0" ]; then
	./test
fi
