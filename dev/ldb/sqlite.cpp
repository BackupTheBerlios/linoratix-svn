/*
 * Linoratix sqlite3 Database-backend
 * Author: Marco Wagner affi@linoratix.com
 *
 * THIS FILE IS FREE (as in freedom) AND STANDS UNDER THE GPL
 */

#include <iostream>
#include <map>
#include <string>
//#include <exception>
#include "sqlite3/sqlite3.h"

// DEBUG macro
#ifdef _DO_DEBUG_
#  define DEBUG(asd) cout << asd << endl;
#else
#  define DEBUG(asd)
#endif




using namespace std;

static bool m_isconnected = false;
static sqlite3 *db;


extern "C" bool l_is_driver() // for extern test that this is a linoratix db backend driver
{ 
   DEBUG("This is the sqlite3-backend")
   return true; 
} 


extern "C" bool l_connect(map <string, string> con_data) // this does make the db connection
{
   if(m_isconnected) return true; // its allready ready :-)
   
   int rc = sqlite3_open(con_data["database"].c_str(), &db);
   if (rc) { // sqlite3 has done a failure :-(
      throw sqlite3_errmsg(db);
   } else {
      m_isconnected = true;
      DEBUG("connected to con_data[\"database\"]")
      return true;
   }
}



