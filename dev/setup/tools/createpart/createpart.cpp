#include <iostream>
#include <parted/parted.h>
#include <cstdlib>
#include <string>
#include <cstdio>

using namespace std;

//Ped::Device *device;
string s2;
PedDevice* device;

bool create_one_disk();
bool create_remain_disk();

int main(int argc, char *argv[])
{
	string s1 = argv[1];
	s2 = argv[2];
	
	if(s1 == "onedisk")
	{
		create_one_disk();
	}
	if(s1 == "remaindisk")
	{
		create_remain_disk();
	}
	
	return EXIT_SUCCESS;
}

bool create_remain_disk()
{ // erzeugt eine extended partition mit swap, home und root
  // es darf keine extended partition schon vorhanden sein.
	PedPartition* part;
	PedDisk* disk;
	PedConstraint* constraint;
	PedPartitionType part_type;
	PedSector start,end;
	const PedDiskType* type;
	long long len_start, len_end, dev_len, len_rest, len_swap, len_root, len_home;
	
	const PedFileSystemType* fs_type = ped_file_system_type_get ("ext3");
	
	// das ist die gewaehlte platte
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	
	// die geometrydaten der platte
	constraint = ped_constraint_any(device);

	// wie lang ist denn die platte?
	dev_len = device->length;
	
	len_swap = 512 * 1024 * 2; // swap sollte 512mb sein
	
	int last_part = ped_disk_get_primary_partition_count(disk);
	part = ped_disk_get_partition(disk, last_part);
	
	len_start = part->geom.end;
	
	len_rest = dev_len - len_swap - len_start;
	len_root = len_rest * 70 / 100;
	
	if(len_root <= 4096)  // wenn root part kleiner ist wie 4GiB
	{
		exit(6);
	}
	
	len_rest = len_rest - len_root;   // was bleibt uns jetzt noch?
	len_home = len_rest;    // de reschd ischd home
	
	if(len_home <= 1024)   // kleiner wie nen gig soll /home auch net sein...
	{
		exit(7);
	}
	
	if(len_home + len_root + len_swap > dev_len) // mal kucken ob wir jetzt nicht zuviel hamm...
	{
		exit(9);
	}
	
	// Was fuer nen partitionstyp solls denn sein
	part_type = PED_PARTITION_EXTENDED;
	
	part = ped_partition_new (disk, part_type, fs_type, len_start, dev_len-1);
	ped_disk_add_partition (disk, part, constraint);
	ped_partition_set_system (part, fs_type);
	
	// Was fuer nen partitionstyp solls denn sein
	part_type = PED_PARTITION_LOGICAL;

	// root	
	part = ped_partition_new (disk, part_type, fs_type, len_start, len_start + len_root);
	ped_disk_add_partition (disk, part, constraint);
	ped_partition_set_system (part, fs_type);
	cout << "root:" << s2 << "5" << endl;
	
	// home
	part = ped_partition_new (disk, part_type, fs_type, len_start + len_root, len_start + len_root + len_home);
	ped_disk_add_partition (disk, part, constraint);
	ped_partition_set_system (part, fs_type);
	cout << "home:" << s2 << "6" << endl;

	// swap
	part = ped_partition_new (disk, part_type, fs_type, len_start + len_root + len_home, dev_len-1);
	ped_disk_add_partition (disk, part, constraint);
	fs_type = ped_file_system_type_get ("linux-swap");
	ped_partition_set_system (part, fs_type);
	cout << "swap:" << s2 << "7" << endl;

	
	ped_disk_commit (disk);
	
	return true;
}

bool create_one_disk()
{
	PedPartition* part;
	PedDisk* disk;
	PedConstraint* constraint;
	PedPartitionType part_type;
	PedSector start,end;
	const PedDiskType* type;
	
	const PedFileSystemType* fs_type = ped_file_system_type_get ("ext3");
	long long dev_len, len_boot, len_home, len_root, len_swap, len_rest;
	
	// das ist die gewaehlte platte
	device = ped_device_get(s2.c_str());

	// gleich ein msdos label machen
	type = ped_disk_type_get("msdos");
	disk = ped_disk_new_fresh (device, type);
		
	// die geometrydaten der platte
	constraint = ped_constraint_any(device);
	
	// Was fuer nen partitionstyp solls denn sein
	part_type = PED_PARTITION_NORMAL;
	
	// wie lang ist denn die platte?
	dev_len = device->length;
	
	len_swap = 512 * 1024 * 2; // swap sollte 512mb sein
	len_boot = 50 * 1024 * 2; // boot partition ist 50 mb
	
	if((len_swap + len_boot ) >= dev_len) // kucken ob es zu gross wird
	{
		exit(5);
	}
	
	len_rest = dev_len - len_swap - len_boot;  // was haben wir noch uebrig
	len_root = len_rest * 70 / 100;   // 70% von dem was wir noch haben ist fuer / (root)
		
	if(len_root <= 4096)  // wenn root part kleiner ist wie 4GiB
	{
		exit(6);
	}
	
	len_rest = len_rest - len_root;   // was bleibt uns jetzt noch?
	len_home = len_rest;    // de reschd ischd home
	
	if(len_home <= 1024)   // kleiner wie nen gig soll /home auch net sein...
	{
		exit(7);
	}
	
	if(len_home + len_root + len_swap + len_boot > dev_len) // mal kucken ob wir jetzt nicht zuviel hamm...
	{
		exit(9);
	}
	
	// jetzt wird erstmal alles geplaett
	ped_disk_delete_all(disk);
	
	// die boot partition erzeugen
	part = ped_partition_new (disk, part_type, fs_type, 0, len_boot);
	ped_disk_add_partition (disk, part, constraint);
	ped_partition_set_system (part, fs_type);
	cout << "boot:" << s2 << "1" << endl;
	
	// nun die root partitions
	part = ped_partition_new (disk, part_type, fs_type, len_boot, len_boot + len_root);
	ped_disk_add_partition (disk, part, constraint);
	ped_partition_set_system (part, fs_type);
	cout << "root:" << s2 << "2" << endl;
	
	// und die home
	part = ped_partition_new (disk, part_type, fs_type, len_boot + len_root, len_boot + len_root + len_home);
	ped_disk_add_partition (disk, part, constraint);
	ped_partition_set_system (part, fs_type);
	cout << "home:" << s2 << "3" << endl;

	// und die swap
	part = ped_partition_new (disk, part_type, fs_type, len_boot + len_root + len_home, dev_len-1);
	ped_disk_add_partition (disk, part, constraint);
	fs_type = ped_file_system_type_get ("linux-swap");
	ped_partition_set_system (part, fs_type);
	cout << "swap:" << s2 << "4" << endl;

	// und den ganzen kram auf die platte schreiben
	ped_disk_commit (disk);
		
	return true;
}
