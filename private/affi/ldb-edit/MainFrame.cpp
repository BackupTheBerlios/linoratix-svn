#include "MainFrame.h"

// registering events
BEGIN_EVENT_TABLE(MainFrame, wxFrame)
   EVT_MENU(ID_quit, MainFrame::doQuit)
END_EVENT_TABLE()





MainFrame::MainFrame(const wxString& title, const wxPoint& pos, const wxSize& size) 
   : wxFrame((wxFrame *)NULL, -1, title, pos, size) {


}



void MainFrame::doQuit(wxCommandEvent& WXUNUSED(event)) {
   Close(true);
}

