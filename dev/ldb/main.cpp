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
      db *datenbank = new db(argv[1]); // hier wird ein zeiger auf ein objekt gelegt das neu im speicher erstellt wird
                                       // der adressbereich auf den dieses objekt zeigt darf nicht verloren gehen sonst --> speicher verloren
	
	
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
            // column name 
            for(int x = 0; x < columns; x++) {
               tmp = x;
               cout << "| " << setw(11) << titles[tmp] << " | ";
            } cout << endl;
            // column value
            while(datenbank->NextRecord()) {
               for(int x = 0; x < columns; x++) {
                  tmp = x;
                  cout << "| " << setw(12) << datenbank->Record[titles[tmp]] << " | ";
               } cout << endl;
      	   }
         }
      } // iam the stairs king :-P 

      string table = "test";
      my_set["zahl"] = "123";
      my_set["text"] = "blah^asd'das";

      datenbank->Insert(table, my_set);


      delete datenbank; // der speicher den das Objekt benutzt muss allerdings auch wieder frei gegeben werden
                        // sonst ist irgendwann der speicher voll mit objekten die nichtmehr benutzt werden --> das ist schlecht

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
