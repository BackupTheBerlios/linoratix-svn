#ifndef __MAINFRAME_H
#define __MAINFRAME_H

#include "ldb-edit.h"

class MainFrame : public wxFrame
{
   public:
      MainFrame(const wxString&, const wxPoint&, const wxSize&);
      void doQuit(wxCommandEvent&);

      enum {ID_quit = 1};
      DECLARE_EVENT_TABLE()
};

#endif

