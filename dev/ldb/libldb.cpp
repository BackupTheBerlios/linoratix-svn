#include <iostream>
#include <dlfcn.h>
//#include <exception>

#include "libldb.h"

using namespace std;

db::db(char* driver)
{
	this->m_driver = driver;
	
	cout << "driver: " << this->m_driver << "\n";
	
	this->handle = dlopen(driver, RTLD_LAZY);
	if(!this->handle)
      throw "kein Handle";
//      throw std::exception("kein Handle");
	
	this->_connect = (connect_t) dlsym(handle, "l_connect");	
	this->_select = (select_t) dlsym(handle, "l_select");
   this->_create = (create_t) dlsym(handle, "l_create");
	this->_insert = (insert_t) dlsym(handle, "l_insert");
	this->_is_driver = (is_driver_t) dlsym(handle, "l_is_driver");
	this->_query = (query_t) dlsym(handle, "l_query");
	this->_num_rows = (num_rows_t) dlsym(handle, "l_num_rows");
	this->_next_record = (next_record_t) dlsym(handle, "l_next_record");
	
	if(! this->_is_driver()) // Seg Fault wenn es kein Treiber ist!
      throw "Dies ist kein Treiber";
//      throw std::exception("Dies ist kein Treiber");
}

db::~db()
{
}

bool db::Connect(map<string,string> con_data)
{
	this->_database = con_data["database"];
	this->_connect(con_data);
}

int db::Select(map<string, string>& query)
{
	string sql_query;
	
	if(!this->_select(query, sql_query))
      return false;
	
	return this->query(sql_query);
}

int db::Create(map<string, string>& query)
{
   string sql_query;

   if(!this->_create(query, sql_query))
      return false;

   return this->query(sql_query);
}

int db::NumRows()
{
	return this->_num_rows();
}

int db::query(string query)
{
	return this->_query(this->_database, query);
}

bool db::NextRecord()
{
	if(! this->_next_record(this->Record))
	{
		return true;
	}
	else
	{
		return false;
	}
}

int db::Insert(map<string,string>& query, map<string,string>& set)
{
	string sql_query;
	
	this->_insert(query, set, sql_query);
	
	return this->query(sql_query);
}

