#include <iostream>
#include <string>
#include <vector>
#include "../src/partedpp.h"

using namespace std;

int main(int argc, char **argv) {

    Ped::Device *test = new Ped::Device("/dev/hda");
    Ped::Disk disk(*test);
    cout << "Disk type is: " << disk.get_disktype().get_name() << endl;
    delete test;
    return 0;
}

