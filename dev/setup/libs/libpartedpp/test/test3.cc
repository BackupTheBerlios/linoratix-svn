#include <iostream>
#include <string>
#include <vector>
#include "../src/device.h"
#include "../src/disk.h"

using namespace std;

int main(int argc, char **argv) {

    Ped::Device *device = new Ped::Device();
    Ped::Disk *disk1    = new Ped::Disk(*device);
    disk1->print();
    try {
        Ped::Disk *disk2 = new Ped::Disk(device->get_next());
        disk2->print();
        delete disk2;
    }
    catch (std::runtime_error &e) {
        cout << e.what() << endl;
        Ped::Device *dev = new Ped::Device("/dev/hda");
        Ped::Disk disk(*dev);
        cout << "Disk type is: " << disk.get_disktype().get_name() << endl;
    }
    delete disk1;
    delete device;
    return 0;
}

