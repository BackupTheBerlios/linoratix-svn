#include <iostream>
#include <string>
#include <vector>
#include "../src/partedpp.h"

using namespace std;

int main(int argc, char **argv) {

    Ped::Device *device = new Ped::Device("/dev/hda");
    cout << "Model: " << device->get_model() << endl;
    cout << "Device path: " << device->get_path() << endl;
    cout << "Type: " << device->get_type() << endl;
    cout << "# sectors: " << device->get_length() << endl;
    Ped::Disk *disk = new Ped::Disk(*device);
    bool checked = disk->check();
    string str_checked;
    if (checked) {
      str_checked = "true";
    } else {
      str_checked = "false";
    }
    cout << "Disk doesn't contain any errors: " << str_checked << endl;
    cout << "Model (called via disk class): " << disk->get_device().get_model() << endl;
    cout << "Disk type: " << disk->get_disktype().get_name() << endl;
    delete disk;
    delete device;
    return 0;
}


