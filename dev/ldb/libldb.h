#ifndef __ldb_h
#define __ldb_h

#include <map>
#include <string>

using namespace std;

class db
{
	public:
		// treibername
		db(char*);
		~db();
		bool Connect(map<string,string>);
		
		int Select(map<string,string>&);

		bool NextRecord();
		int NumRows();
	
		map<string,string> Record;

	private:
		char* m_driver;
		void* handle;
		
		string _database;
		
		typedef bool (*connect_t)(map<string,string>);
		connect_t _connect;

		typedef int (*next_record_t)(map<string,string>&);
		next_record_t _next_record;

		typedef bool (*select_t)(map<string,string>, string&);
		select_t _select;

		typedef int (*query_t)(string, string);
		query_t _query;

		typedef bool (*is_driver_t)();
		is_driver_t _is_driver;

		typedef int (*num_rows_t)();
		num_rows_t _num_rows;
		
		int query(string);

};

#endif
