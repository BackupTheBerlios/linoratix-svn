/*
 * LIP Pakagemanager...
 * ... zumindest wird er es irgendwann mal
 */

#include "libpm.h"
using namespace std;

pm::pm()
{
	
	if(sqlite3_open((m_dbname + "/" + m_dbpath).c_str(), &m_db)) {
		sqlite3_close(m_db);
		m_ready = false;
	} else {
		m_ready = true;
		//TODO: DB ueberpruefen? Tabellen anlegen?
	}
}

pm::~pm() { if(m_ready) { sqlite3_close(m_db); } }


