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
static sqlite3_stmt *stmt;


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
         DEBUG("connected to database [" + *database + "]")
      #endif
      return true;
   }
}

// deletes the precompiled statement 
bool clearstmt() {
   if(stmt != NULL) { 
      if(sqlite3_finalize(stmt) != SQLITE_OK) {
         DEBUG("cant delet precompiled statement [" + string(sqlite3_errmsg(db)) + "]")
         return false;
      } else {
         DEBUG("precompiled statement deleted")
         return true;
      }
   } 
}


bool stmtok(string& sql_query) {
   if(!sqlite3_complete(sql_query.c_str())) {
      DEBUG("the statement did not pass the sqlite SQL-Check")
      return false;
   } else {
      DEBUG("the statement did pass the sqlite SQL-Check")
      return true;
   }
}


// builds the sql_query content to pass them into the l_query function
extern "C" bool l_select(map<string, string>& query, string& sql_query)
{
   clearstmt();
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

   sql_query += ";"; // end of statement!
   DEBUG("statement [" + sql_query + "]")

   return stmtok(sql_query);
}


extern "C" bool l_create(map<string, string>& con_data, string& sql_query) {
   clearstmt();
   sql_query = "CREATE ";

   // what shoud be created?
   if(con_data.find("table") != con_data.end()) {
      sql_query += "TABLE " + con_data["table"] + " ";
   } else if(con_data.find("view") != con_data.end()) {
      sql_query += "VIEW " +  con_data["view"] + " ";
   } else {
      DEBUG("what do you want to create? [view, table]")
      return false;
   }

   // fields
   if(con_data.find("fields") != con_data.end()) {
      sql_query += "( " + con_data["fields"] + ") ";
   } else {
      DEBUG("whoops.. forgotten the fields?")
      return false;
   }
   
   sql_query += ";"; // end of statement!
   DEBUG("statement [" + sql_query + "]")

   return stmtok(sql_query);
}


// this function does execute the statement... call this function for all results
extern "C" int l_query(string database, string sql_query) { // database var is not used here
   if(sqlite3_prepare(db, sql_query.c_str(), sizeof(sql_query.c_str()), &stmt, NULL) != SQLITE_OK) {
      DEBUG("preparing of statement failed [" + string(sqlite3_errmsg(db)) + "]")
      return -1;
   } else {
      DEBUG("statement is prepared")
      switch (sqlite3_step(stmt)) {
         case SQLITE_ROW:
            DEBUG("query successfully executed")
            return 2;
            break;
         case SQLITE_DONE:
            DEBUG("query successfully executed and at end of rows")
            return 1;
            break;
         case SQLITE_ERROR:
            DEBUG("error while executing query: [" + string(sqlite3_errmsg(db)) + "]")
            return -1;
            break;
         case SQLITE_BUSY:
            DEBUG("the database is busy")
            return -1;
            break;
         case SQLITE_MISUSE:
            DEBUG("no query found to execute [" + string(sqlite3_errmsg(db)) + "]")
            return -1;
            break;
         default:
            DEBUG("unknown query return [" + string(sqlite3_errmsg(db)) + "]")
            return -1;
            break;
      }
   }
}


