#ifndef __pm_h
#define __pm_h

#include <iostream>
#include <string>
#include "sqlite3/sqlite3.h"

using namespace std;

class pm {
public:
	pm(const char* dbname, const char* dbpath);
	~pm();

	bool packetExists() {}
	bool install() {}
	bool remove() {}

	char* listPaket() {}
	char* searchFile() {}
	
private:
	string m_dbname;
	string m_dbpath;
	
	sqlite3* m_db;
	char* m_err;

	bool m_ready;
};
#endif
