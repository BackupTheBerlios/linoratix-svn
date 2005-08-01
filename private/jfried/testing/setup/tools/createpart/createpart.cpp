#include <iostream>
#include <parted/parted.h>
#include <cstdlib>
#include <string>
#include <cstdio>
#include <sstream>

using namespace std;

string s2;
PedDevice* device;

bool create_one_disk();
bool create_remain_disk();
bool remove_partition(int);
bool add_partition(PedSector, PedSector, string);
bool add_extended_partition(PedSector, PedSector, string);
bool add_logical_partition(PedSector, PedSector, string);

bool string_to_int(const string&, int&);
bool string_to_longlong(const string &s, long long &i);
bool __add_partition(PedSector, PedSector, string, PedPartitionType);


int main(int argc, char *argv[])
{
	string s1,s3,s4,s5;
	int i;
	long long l,l2;
	
	if(argc < 3) goto print_help;
	
	s1 = argv[1];
	s2 = argv[2];
	
	if(argc >= 4)
	{
		s3 = argv[3];
	}
	if(argc >= 5)
	{
		s4 = argv[4];
	}
	if(argc >= 6)
	{
		s5 = argv[5];
	}
	
	if(s1 == "onedisk")
	{
		create_one_disk();
	}
	else if(s1 == "remaindisk")
	{
		create_remain_disk();
	}
	else if(s1 == "remove_partition")
	{
		string_to_int(s3, i);
		remove_partition(i);
	}
	else if(s1 == "add_partition")
	{
		string_to_longlong(s3, l);
		string_to_longlong(s4, l2);
		add_partition(l, l2, s5);
	}
	else if(s1 == "add_extended_partition")
	{
		string_to_longlong(s3, l);
		string_to_longlong(s4, l2);
		add_extended_partition(l, l2, s5);
	}
	else if(s1 == "add_logical_partition")
	{
		string_to_longlong(s3, l);
		string_to_longlong(s4, l2);
		add_logical_partition(l, l2, s5);
	}
	else
	{
		goto print_help;
	}

	
	return EXIT_SUCCESS;
print_help:
		cout << "Wrong parameter" << endl;
		cout << "=================" << endl;
		cout << endl;
		cout << "onedisk <device> ... remove all partitions and create linux partitions" << endl;
		cout << "remaindisk <device> ... create an extendes partition and in that linux partitions" << endl;
		cout << "remove_partition <device> <partid> ... remove partition [partid] on [device]" << endl;
		cout << "add_partition <device> <startsector> <endsector> <filesystem> ... add a primary partition" << endl;
		cout << "add_extended_partition <device> <startsector> <endsector> <filesystem> ... add an extended partition" << endl;
		cout << "add_logical_partition <device> <startsector> <endsector> <filesystem> ... add an extended partition" << endl;
		cout << "remove_partition <device> <partid> ... removes partition" << endl;
		cout << endl;
		exit(1);
}

bool remove_partition(int part_id)
{
	PedPartition* part;
	PedDisk* disk;
	
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	part = ped_disk_get_partition(disk, part_id);
	
	if(part) 
	{
		ped_disk_delete_partition (disk, part);
		ped_disk_commit (disk);
	}
	ped_disk_destroy (disk);
}

bool add_partition(PedSector start, PedSector end, string str_fs_type)
{
	PedPartitionType part_type;
	part_type = PED_PARTITION_NORMAL;
	
	return __add_partition(start, end, str_fs_type, part_type);
}

bool add_extended_partition(PedSector start, PedSector end, string str_fs_type)
{
	PedPartitionType part_type;
	part_type = PED_PARTITION_EXTENDED;
	
	return __add_partition(start, end, str_fs_type, part_type);
}

bool add_logical_partition(PedSector start, PedSector end, string str_fs_type)
{
	PedPartitionType part_type;
	part_type = PED_PARTITION_LOGICAL;
	
	return __add_partition(start, end, str_fs_type, part_type);
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
	
	add_extended_partition(len_start, dev_len-1, "ext3");
	
	// Was fuer nen partitionstyp solls denn sein
	part_type = PED_PARTITION_LOGICAL;

	// root	
	add_logical_partition(len_start, len_start + len_root, "ext3");
	cout << "/:" << s2 << "5" << endl;
	
	// home
	add_logical_partition(len_start + len_root, len_start + len_root + len_home, "ext3");
	cout << "/home:" << s2 << "6" << endl;

	// swap
	add_logical_partition(len_start + len_root + len_home, dev_len-1, "linux-swap");
	cout << "swap:" << s2 << "7" << endl;
	
	ped_disk_destroy (disk);
	
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
	// und den ganzen kram auf die platte schreiben
	ped_disk_commit (disk);
	
	// die boot partition erzeugen
	add_partition(0, len_boot, "ext3");
	cout << "/boot:" << s2 << "1" << endl;
	
	// nun die root partitions
	add_partition(len_boot, len_boot + len_root, "ext3");
	cout << "/:" << s2 << "2" << endl;
	
	// und die home
	add_partition(len_boot + len_root, len_boot + len_root + len_home, "ext3");
	cout << "/home:" << s2 << "3" << endl;

	// und die swap
	add_partition(len_boot + len_root + len_home, dev_len-1, "linux-swap");
	cout << "swap:" << s2 << "4" << endl;

	ped_disk_destroy (disk);
	
	return true;
}

bool __add_partition(PedSector start, PedSector end, string str_fs_type, PedPartitionType part_type)
{
	PedPartition* part;
	PedDisk* disk;
	PedConstraint* constraint;
	const PedFileSystemType* fs_type = ped_file_system_type_get (str_fs_type.c_str());
			
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	
	constraint = ped_constraint_any(device);
	
	part = ped_partition_new (disk, part_type, fs_type, start, end);
	if(part)
	{
		ped_disk_add_partition (disk, part, constraint);
		ped_partition_set_system (part, fs_type);
		ped_disk_commit (disk);
	}
	else
	{
		return false;
	}
	ped_disk_destroy (disk);
	
	return true;
}

bool string_to_int(const string &s, int &i)
{
	istringstream myStream(s);
  
	if (myStream>>i)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool string_to_longlong(const string &s, long long &i)
{
	istringstream myStream(s);
  
	if (myStream>>i)
	{
		return true;
	}
	else
	{
		return false;
	}
}
