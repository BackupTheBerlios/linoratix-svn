#include <iostream>
#include <map>
#include <string>
#include <mysql/mysql.h>

using namespace std;


MYSQL con;
my_ulonglong row_index=0;
MYSQL_RES *result;

// hier wird nur ein true zurueckgegeben
// um zu ueberpruefen? ob das ein db treiber ist
extern "C" bool l_is_driver()
{
	return true;
}

extern "C" bool l_connect(map<string,string> con_data)
{
	mysql_init(&con);
	mysql_real_connect(&con, 
			con_data["server"].c_str(), 
			con_data["username"].c_str(), 
			con_data["password"].c_str(), 
			con_data["database"].c_str(), 
			NULL,
			NULL,
			NULL);
	return true;
}

extern "C" bool l_select(map<string,string>& query, string& sql_query)
{
	sql_query = "SELECT ";

	// kucken ob ein "fields" im array steckt
	if(query.find("fields") != query.end())
	{
		// wenn ja wird das mit hingehangen
		sql_query += query["fields"] + " ";
	}
	else
	{
		// ansonsten ist default der *
		sql_query += "* ";
	}

	// ist ein table mit drinne?
	if(query.find("table") != query.end())
	{
		// so ischd es un druff un dewedda
		sql_query += "from " + query["table"];
	}
	else
	{
		// falscher sql query, und ab dafuer
		// l_error(...)
		return false;
	}

	// wenn jemand noch nen join braucht...
	if(query.find("join") != query.end())
	{
		sql_query += " " + query["join"];
	}


	// ist ein where mit drinne
	if(query.find("where") != query.end())
	{
		// ok da fragt einer nach mehr einzelheiten...
		sql_query += " where " + query["where"];
	}


	// bei nem order
	if(query.find("order") != query.end())
	{
		sql_query += " order by " + query["order"];
	}

	
	// group auch noch beachten
	if(query.find("group") != query.end())
	{
		sql_query += " group by " + query["group"];
	}

	return true; // allen baletti
}

// hier werden die sql queries dann ausjefuehrt
extern "C" int l_query(string database, string sql_query)
{
	if(! mysql_select_db(&con, database.c_str()))
	{
		row_index = 0;
		return mysql_real_query(&con, sql_query.c_str(), strlen(sql_query.c_str()));
	}

	return -1;
}

// jibbd die anzahl der erjebnisse zurueck
extern "C" int l_num_rows()
{
	result = mysql_store_result(&con);
	if(result)
	{
		return mysql_num_rows(result);
	}
	else
	{
		return -1;
	}
}

extern "C" int l_next_record(map<string,string>& record)
{
	MYSQL_ROW row;
	MYSQL_FIELD *field;
	
	map<string,string> ret;
	int i;
	unsigned int num_fields;

	num_fields = mysql_num_fields(result);

	if(row = mysql_fetch_row(result))
	{
		for(i=0; i < num_fields; i++)
		{
			field = mysql_fetch_field_direct(result, i);
			record[field->name] = row[i];
		}
		return 0;
	}
	
	return -1;
}

