#include <iostream>
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
//         throw std::exception("usage: <binaey> <driver.so>");

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

	   my_query["table"] = "blocks";
	   my_query["fields"]= "*";

	   if(! datenbank->Select(my_query))
	   {
	   	cout << "Anzahl: " << datenbank->NumRows() << endl;
	   	while(datenbank->NextRecord())
	   	{
	   		cout << datenbank->Record["direction"] << endl;
	   	}
	   }
	
   	my_insert["table"] = "blocks";
   	my_set["direction"] = "t'op";
   	my_set["text"] = "joah mann";
	
   	datenbank->Insert(my_insert, my_set);

   } catch (std::exception& e) {
      cout << "Exception: " << e.what() << endl;
      return -1;
    } catch (const char* e) {
      cout << "Exception: " << e << endl;
      return -1;
   } catch (...) {
      cout << "Exception: undefined" << endl;
      return -2;
   }

	return 0;
}
