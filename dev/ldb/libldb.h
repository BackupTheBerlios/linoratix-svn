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
      bool Disconnect();
		
		int Select(map<string,string>&);
      int Create(map<string, string>&);
		int Insert(map<string,string>&, map<string,string>&);
      int Execute();
      
		bool NextRecord();
      int ColumnNames(map<string, string>& out);
		int NumRows();
	
		map<string,string> Record;

	private:
		char* m_driver;
		void* handle;
		
		string _database;
		
		typedef bool (*connect_t)(map<string,string>);
		connect_t _connect;

      typedef bool (*disconnect_t)();
      disconnect_t _disconnect;

		typedef int (*next_record_t)(map<string,string>&);
		next_record_t _next_record;

      typedef int (*column_names_t)(map<string, string>&);
      column_names_t _column_names;

		typedef bool (*select_t)(map<string,string>, string&);
		select_t _select;

      typedef bool (*create_t)(map<string, string>, string&);
      create_t _create;

		typedef bool (*insert_t)(map<string,string>, map<string,string>, string&);
		insert_t _insert;

      typedef int (*execute_t)();
      execute_t _execute;
		
		typedef int (*query_t)(string, string);
		query_t _query;

		typedef bool (*is_driver_t)();
		is_driver_t _is_driver;

		typedef int (*num_rows_t)();
		num_rows_t _num_rows;
		
		int query(string);

};

#endif
