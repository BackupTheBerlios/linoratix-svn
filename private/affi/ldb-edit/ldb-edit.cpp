#include "ldb-edit.h"
#include "MainFrame.h"

class MyApp: public wxApp
{
   public:
      virtual bool OnInit();
};

bool MyApp::OnInit() {
   try {
      MainFrame *MainF = new MainFrame("Linoratix Database Editor", wxPoint(50, 50), wxSize(650, 350));
   
      SetTopWindow(MainF);
      MainF->Show(true);
   }
   catch(const char* e) {     cerr << e << endl;                       return -1; }
   catch(std::exception& e) { cerr << e.what() << endl;                return -1; }
   catch(...) {               cerr << "Fatal error... EXITING"<< endl; return -1; }
}

IMPLEMENT_APP(MyApp)

