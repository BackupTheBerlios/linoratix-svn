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

#include "sqlite.h"

// DEBUG macro
#ifdef _DO_DEBUG_
#  define DEBUG(text) cerr << "DEBUG: " << text << endl;
#else
#  define DEBUG(text)
#endif




using namespace std;

bool m_isconnected = false;
sqlite3 *db;
sqlite3_stmt *stmt;


extern "C" bool l_is_driver() { // for extern test that this is a linoratix db backend driver
   DEBUG("this is the sqlite3-backend")
   return true; 
} 


extern "C" bool l_connect(map <string, string> con_data) { // this does make the db connection
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


extern "C" bool l_disconnect() {
   if(!m_isconnected) return true; // not connected so disconnect is good =)

   // TODO error checking
   sqlite3_close(db);
   DEBUG("disconnected from database")
   return true;
}


// deletes the precompiled statement 
bool clearstmt() {
   if(stmt != NULL) { 
      if(sqlite3_finalize(stmt) != SQLITE_OK) {
         DEBUG("cant delete precompiled statement [" + string(sqlite3_errmsg(db)) + "]")
         return false;
      } else {
         DEBUG("precompiled statement deleted")
         return true;
      }
   } else 
      return true; // no statement in there so its ready to take a statement :P
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


// this does execute the statement 1 for rows left, 0 for no rows left and <0 if an error appears
extern "C" int l_execute() {
      switch (sqlite3_step(stmt)) {
         case SQLITE_ROW:
            DEBUG("query successfully executed")
            return 1;
            break;
         case SQLITE_DONE:
            DEBUG("query successfully executed and at end of rows")
            return 0;
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
   if(stmtok(sql_query)) {
         int x = l_query("", sql_query);
         if(x)
            return l_execute();
         else
            return x;
   }
   return 0;
}


// this function does prepare the statement... call this function for all results
extern "C" int l_query(string database, string sql_query) { // database var is not used here
   if(sqlite3_prepare(db, sql_query.c_str(), sizeof(sql_query.c_str()), &stmt, NULL) != SQLITE_OK) {
      DEBUG("precompiling of statement failed [" + string(sqlite3_errmsg(db)) + "]")
      return -1;
   } else {
      DEBUG("statement is precompiled")
      return 1;
   }
}


extern "C" int l_num_rows() {
   if(stmt != NULL) {
      DEBUG("sqlite cant get the numbers of rows :-(")
      return 0;
   } else {
      DEBUG("no statement precompiled");
      return -1;
   }
}


int strlen(const unsigned char* srcstr) {
   int length = 0;
   
   while(srcstr[length] != '\0')
      length++;
   
   return length;
}


string toString(const unsigned char* srcstr) {
   int length = strlen(srcstr);
   string deststr;
   
   for(int x = 0; x <= length; x++) {
      deststr += srcstr[x];
   }
   return deststr;
}


string toString(int& srcint) {
   string deststr;
   deststr += srcint;
   return deststr;
}


extern "C" int l_next_record(map<string, string>& record) {
   if(stmt == NULL) {
      DEBUG("no statement precompiled")
      return -1;
   }
   
   int rc = l_execute();
   if(rc <= 0) return rc;

   int spaltenanz = sqlite3_column_count(stmt);
      
   for(int x = 0; x < spaltenanz; x++) {
      record[sqlite3_column_name(stmt, x)] = toString(sqlite3_column_text(stmt, x));
      DEBUG(string("OUT: ") + sqlite3_column_name(stmt, x) + " => " + toString(sqlite3_column_text(stmt, x)))
   }
   return true;
}


extern "C" int l_column_names(map<string, string>& out) {
   if(stmt == NULL) {
      DEBUG("no statement precompiled")
      return -1;
   }
   
  int count = sqlite3_column_count(stmt);
   
   for(int x = 0; x < count; x++) {
      out[toString(x)] = sqlite3_column_name(stmt, x);
   }
   #ifdef _DO_DEBUG
      for(int x = 0; x < count; x++) {
         cerr << "Spalte: " << x << " Wert: " << out[toString(x)] << endl;
      }
   #endif
   return count;
}


extern "C" int l_insert(string& table, map<string, string>& insert, string& sql_query) {
   sql_query = "INSERT INTO " + table + " (";
   string tmp = " values (";
  
   map<string, string>::iterator iter = insert.begin(), end = insert.end();
   
   while(iter != end) { // foreach like
      sql_query += iter->first;
      tmp += string("'") + sqlite3_mprintf("%q", iter->second.c_str()) + "'";
      iter++;
      if(iter != end) {
         sql_query += ", ";
         tmp += ", ";
      }
   } 

   sql_query += ")";
   tmp += ")";

   sql_query += tmp + ";"; // complete statement 
   DEBUG(sql_query)
   return true;
}


