#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <map>
//#include <exception>

#include "libldb.h"

using namespace std;

int main(int argc, char **argv)
{
   try {
      if (argc != 2) 
         throw "usage: <binary> <driver.so>"; 
//         throw std::exception("usage: <binary> <driver.so>");

   	map <string, string> my_con, my_insert, my_set;
   	map <string, string> my_query;
	
   	my_con["server"] = "localhost";
   	my_con["username"] = "root";
   	my_con["password"] = "";
   	my_con["database"] = "perlnuke";
/*	   my_con["port"] = NULL;
	   my_con["unix_socket"] = NULL;
	   my_con["client_flag"] = NULL; */
	
//	   db *datenbank = new db("./mysql-backend.so");
      db *datenbank = new db(argv[1]);
	
	
	   datenbank->Connect(my_con);

      // create test
      my_query["table"] = "test";
      my_query["fields"] = "zahl int, text varchar(128)";
      if(! datenbank->Create(my_query))
         cout << "The create test has returned: '" << datenbank->Execute() << "'" << endl;
      
//	   my_query["table"] = "blocks";
	   my_query["table"] = "test";
	   my_query["fields"]= "*";
      my_query["order"]= "zahl";

	   if(datenbank->Select(my_query))
	   {
	   	cout << "Reihenanzahl: " << datenbank->NumRows() << endl;
         
         map<string, string> titles;
         int columns = datenbank->ColumnNames(titles);
         cout << "Spaltenanzahl: " << columns << endl;
         string tmp;
         
         if(columns > 0) {
            // Feldnamen
            for(int x = 0; x < columns; x++) {
               tmp = x;
               cout << "| " << setw(11) << titles[tmp] << " | ";
            } cout << endl;
            // Feldinhalte
            while(datenbank->NextRecord()) {
               for(int x = 0; x < columns; x++) {
                  tmp = x;
                  cout << "| " << setw(12) << datenbank->Record[titles[tmp]] << " | ";
               } cout << endl;
      	   }
         }
      } // ich bin K�nig der Treppen :P


/*
   	my_insert["table"] = "blocks";
   	my_set["direction"] = "t'op";
   	my_set["text"] = "joah mann";
	
   	datenbank->Insert(my_insert, my_set);
*/

      
   } catch (std::exception& e) {
      cout << "Exception: " << e.what() << endl;
      return -1;
    } catch (const char* e) {
      cout << "Exception: " << e << endl;
      return -1;
   } catch (...) {
      cout << "Exception: undefined error" << endl;
      return -2;
   }

	return 0;
}
