#include <iostream>
#include <string>
#include <vector>
#include "../src/partedpp.h"

using namespace std;

int main(int argc, char **argv) {

    Ped::Device *device = new Ped::Device("/dev/hda");
    Ped::Disk *disk = new Ped::Disk(*device);
    int i;
    cout << "# of primary partitions: " << disk->get_primary_partition_count() << endl;
    cout << "Max nr. of primary part: " << disk->get_max_primary_partition_count() << endl;
    cout << "Last partition number:   " << disk->get_last_partition_num() << endl;
    cout << "Partition table doesn't contain any errors: " << disk->check() << endl;
    cout << "Name of disk type:       " << disk->get_disktype().get_name() << endl;
    cout << "Enter partition number:  ";
    cin >> i;
    try {
      disk->get_partition(i);
    }
    catch (std::runtime_error &e) {
      e.what();
    }
    //cout << "Partition name:  " << disk->get_partition(i).get_name() << endl;
    cout << "Partition path:  " << disk->get_partition(i).get_path() << endl;
    cout << "Partition nr:    " << disk->get_partition(i).get_num() << endl;
    cout << "Filesystem type: " << disk->get_partition(i).get_file_system_type().get_name() << endl;
    cout << "Part type:       " << disk->get_partition(i).get_partition_type() << endl;
    cout << "Part type name:  " << disk->get_partition(i).get_type_name(disk->get_partition(i).get_partition_type()) << endl;
    cout << "Geometry start:  " << disk->get_partition(i).get_geometry().get_start() << endl;
    cout << "Geometry end:    " << disk->get_partition(i).get_geometry().get_end() << endl;
    cout << "Geometry length: " << disk->get_partition(i).get_geometry().get_length() << endl;
    delete disk;
    delete device;
    return 0;
}

