#include "ldb-edit.h"

int main() {
   try {
      db* datenbank = new db("sqlite-backend.so");
   }
   catch(const char* e) {     cout << e << endl;         return -1; }
   catch(std::exception& e) { cout << e.what() << endl;  return -1; }

   return 0;
}

