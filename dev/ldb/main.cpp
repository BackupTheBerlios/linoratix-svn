#include <iostream>
#include <map>

#include "libldb.h"

using namespace std;

int main()
{
	map <string, string> my_con, my_insert, my_set;
	map <string, string> my_query;
	
	my_con["server"] = "localhost";
	my_con["username"] = "root";
	my_con["password"] = "";
	my_con["database"] = "perlnuke";
/*	my_con["port"] = NULL;
	my_con["unix_socket"] = NULL;
	my_con["client_flag"] = NULL; */
	
	db *datenbank = new db("./mysql.so");
	

	
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

	return 0;
}
