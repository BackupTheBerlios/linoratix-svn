#include <iostream>
#include <parted/parted.h>
#include <cstdlib>
#include <string>
#include <sstream>

using namespace std;

PedDevice* device;
string s2;

void get_model();
void get_size();
void get_fs(int);
void get_geometry(int);
void get_type(int);
void get_all_partitions();

bool string_to_int(const string&, int&);

int main(int argc, char *argv[])
{
	string s1,s3;
	int i;

	if(argc < 3) exit(1);
	
	s1 = argv[1];
	s2 = argv[2];
	if(argc >= 4)
	{
		s3 = argv[3];
	}
	
	if(s1 == "model")
	{
		get_model();
	}
	else if(s1 == "size")
	{
		get_size();
	}
	else if(s1 == "fstype")
	{
		string_to_int(s3, i);
		get_fs(i);
	}
	else if(s1 == "geometry")
	{
		string_to_int(s3, i);
		get_geometry(i);
	}
	else if(s1 == "type")
	{
		string_to_int(s3, i);
		get_type(i);
	}
	else if(s1 == "getall")
	{
		get_all_partitions();
	}
	else
	{
		cout << "Wrong parameter!" << endl;
	}
	
	return EXIT_SUCCESS;
}

void get_model()
{
	device = ped_device_get(s2.c_str());
	cout << device->model << endl;
}

void get_size()
{
	device = ped_device_get(s2.c_str());
	cout << device->length / 2 << endl;
}

void get_fs(int part_id)
{
	PedPartition* part;
	PedDisk* disk;
	PedFileSystemType* fs_type;
	
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	part = ped_disk_get_partition(disk, part_id);
	if(part)
	{
		cout << part->fs_type->name << endl;
	}
}

void get_all_partitions()
{
	PedPartition* part;
	PedDisk* disk;
	
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	
	for (part = ped_disk_next_partition (disk, NULL); part; part = ped_disk_next_partition (disk, part))
	{
		if(part->num != -1)
		{
			cout << part->num << ":" << part->geom.start << ":" << part->geom.end
			<< ":" << ped_partition_type_get_name (part->type)
			<< ":" << (part->fs_type ? part->fs_type->name : "")
			<< ":" << device->length / 2 << endl;
		}
	}
}

void get_geometry(int part_id)
{
	PedPartition* part;
	PedDisk* disk;
	PedFileSystemType* fs_type;
	
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	part = ped_disk_get_partition(disk, part_id);
	if(part)
	{
		cout << part->geom.start << ":" << part->geom.end << endl;
	}
}

void get_type(int part_id)
{
	PedPartition* part;
	PedDisk* disk;
	PedFileSystemType* fs_type;
	
	device = ped_device_get(s2.c_str());
	disk = ped_disk_new (device);
	part = ped_disk_get_partition(disk, part_id);
	if(part)
	{	
		cout << ped_partition_type_get_name (part->type) << endl;
	}
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
