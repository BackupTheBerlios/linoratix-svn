#include "MainFrame.h"

// registering events
BEGIN_EVENT_TABLE(MainFrame, wxFrame)
   EVT_MENU(ID_quit, MainFrame::doQuit)
   EVT_MENU(ID_about, MainFrame::doAbout)
END_EVENT_TABLE()





MainFrame::MainFrame(const wxString& title, const wxPoint& pos, const wxSize& size) 
   : wxFrame((wxFrame *)NULL, -1, title, pos, size) {
   try {
      wxMenu *menuFile = new wxMenu;
      wxMenu *menuHelp = new wxMenu;
      wxMenuBar *menuBar = new wxMenuBar;
      
      menuFile->Append(ID_quit, "E&xit");
      menuHelp->Append(ID_about, "&About");
      
      menuBar->Append(menuFile, "&File");
      menuBar->Append(menuHelp, "&Help");

      SetMenuBar(menuBar);
   }
   catch (std::exception& e) { wxMessageBox(e.what(), "Error :-(", wxOK | wxICON_ERROR, this); }
   catch (const char* e) { wxMessageBox(e, "Error :-(", wxOK | wxICON_ERROR, this); }
   catch (...) { wxMessageBox("Unknown Error", "Error :-(", wxOK | wxICON_ERROR, this); }
}



void MainFrame::doQuit(wxCommandEvent& WXUNUSED(event)) {
   Close(true);
}

void MainFrame::doAbout(wxCommandEvent& WXUNUSED(event)) {
   wxMessageBox(wxString("Author: Marco Wagner\nE-mail: affi@linoratix.com\n\nVisit www.linoratix.com\n\nThis programm was built with wxWidgets and stands under the GPL\n\nVersion: ") + VERSIONNR, wxString("About Linoratix Database Editor v. ") + VERSIONNR, wxOK | wxICON_INFORMATION, this);
}

