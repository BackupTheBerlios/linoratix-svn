#include <iostream>
#include <string>
#include <vector>
#include "../src/device.h"
#include "../src/disk.h"

using namespace std;

int main(int argc, char **argv) {

    string s;
    cout << "Enter device path: ";
    cin >> s;
    try {
      Ped::Device test(s);
      Ped::Disk disk(test);
      cout << "Disk type is: " << disk.get_disktype().get_name() << endl;
    }
    catch (runtime_error &e) {
      cout << e.what() << endl;
    }
    return 0;
}

