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
#  define DEBUG(text) cout << "DEBUG: " << text << endl;
#else
#  define DEBUG(text)
#endif




using namespace std;

static bool m_isconnected = false;
static sqlite3 *db;


extern "C" bool l_is_driver() // for extern test that this is a linoratix db backend driver
{ 
   DEBUG("this is the sqlite3-backend")
   return true; 
} 


extern "C" bool l_connect(map <string, string> con_data) // this does make the db connection
{
   if(m_isconnected) return true; // its allready ready :-)

   if(con_data.find("database") == con_data.end()) { 
      DEBUG("no database selected, try l_connect(string[\"database\"])") 
      throw "no database selected"; 
   }

   int rc = sqlite3_open(con_data["database"].c_str(), &db);
   if (rc) { // sqlite3 has done a failure :-(
      throw sqlite3_errmsg(db);
   } else {
      m_isconnected = true;
      #ifdef _DO_DEBUG_ // show me where I am connected to
         string *database = &con_data["database"];
         DEBUG("connected to database " + *database)
      #endif
      return true;
   }
}

// builds the sql_query content to pass them into the l_query function
extern "C" bool l_select(map<string, string>& query, string& sql_query)
{
   sql_query = "SELECT ";
   
   // selected fields
   if(query.find("fields") != query.end()) {
      sql_query += query["fields"] + " ";
   } else {
      sql_query += "* ";
   }
   
   // selected table
   if(query.find("table") != query.end()) {
      sql_query += "FROM " + query["table"] + " ";
   } else {
      DEBUG("no table selected...")
      return false;
   }
   
   // table joins
   if(query.find("join") != query.end()) {
      sql_query += query["join"] + " ";
   }
   
   // where condition
   if(query.find("where") != query.end()) {
      sql_query += "WHERE " + query["where"] + " ";
   }

   // order
   if(query.find("order") != query.end()) {
      sql_query += "ORDER BY " + query["order"] + " ";
   }

   // group
   if(query.find("group") != query.end()) {
      sql_query += "GROUP BY " + query["group"] + " ";
   }

   sql_query += ";"; // end of query!
   DEBUG(sql_query)
   return true;
}


