#include <iostream>
#include <partedpp/partedpp.h>
#include <cstdlib>
#include <string>
#include <cstdio>

using namespace std;

Ped::Device *device;
string s2;

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
	
	delete device;
	return EXIT_SUCCESS;
}

bool create_remain_disk()
{ // erzeugt eine extended partition mit swap, home und root
  // es darf keine extended partition schon vorhanden sein.
	device = new Ped::Device(s2);
	Ped::Disk *disk = new Ped::Disk(*device);
	
	long long len_start, len_end, dev_len, len_rest, len_swap, len_root, len_home;
	
	dev_len = device->get_length() / 2 / 1024;
	cout << "dev_len	" << dev_len << endl;
	
	len_swap = 512; // MB
	cout << "swap...	" << len_swap << endl;
	
	
	len_start = disk->get_partition(disk->get_primary_partition_count()).get_geometry().get_end() / 2 / 1024;
	
	len_rest = dev_len - len_start - len_swap;
	
	string create_part = "/sbin/parted " + s2 + " mkpart extended";
	char exec[create_part.length() + 500];
	
	sprintf(exec, "%s %i", create_part.c_str(), len_start);
	sprintf(exec, "%s %i", exec, dev_len);
	
	// cout << exec << endl;
	system(exec);   // extended
	
	len_root = len_rest * 70 / 100;
	cout << "root...	" << len_root << endl;
	
	if(len_root <= 4096)  // wenn root part kleiner ist wie 4GiB
	{
		exit(6);
	}
	
	len_rest = len_rest - len_root;
	len_home = len_rest;    // der rest ischd home
	
	cout << "home...	" << len_home << endl;
	
	if(len_home + len_root + len_swap  > dev_len)
	{
		exit(9);
	}
	
	create_part = "/sbin/parted " + s2 + " mkpart logical ext3";
	sprintf(exec, "%s %i", create_part.c_str(), len_start);
	sprintf(exec, "%s %i", exec, len_start + len_root);
	
	// cout << exec << endl;
	system(exec); // root
	
	
	create_part = "/sbin/parted " + s2 + " mkpart logical ext3";
	sprintf(exec, "%s %i", create_part.c_str(), len_start + len_root);
	sprintf(exec, "%s %i", exec, len_start + len_root + len_home);
	
	// cout << exec << endl;
	system(exec); // home
	
	create_part = "/sbin/parted " + s2 + " mkpart logical ext3";
	sprintf(exec, "%s %i", create_part.c_str(), len_start + len_root + len_home);
	sprintf(exec, "%s %i", exec, dev_len);
	
	// cout << exec << endl;
	system(exec); // swap
	
	return true;
}

bool create_one_disk()
{
	string s_label = "/sbin/parted " + s2 + " mklabel msdos";
	
	long long dev_len, len_boot, len_home, len_root, len_swap, len_rest;
	
	system(s_label.c_str());
	
	device = new Ped::Device(s2);
	cout << "Die ganze Platte verwenden" << endl;
	
	dev_len = device->get_length() / 2 / 1024; // / 2;  // das sind wenn ich das richtig kappiert hab KiB => MB
	
	cout << "dev_len	" << dev_len << endl;
	
	len_swap = 512; // MB

	cout << "swap...	" << len_swap << endl;
	
	len_boot = 50; // 50MB
	
	cout << "boot...	"  << len_boot << endl;

	if((len_swap + len_boot ) >= dev_len)
	{
		exit(5);
	}
	
	len_rest = dev_len - len_swap - len_boot;
	
	cout << "rest...	" << len_rest << endl;
	
	   // die 20 einfach so zur sicherheit ;)
	len_root = len_rest * 70 / 100;

	cout << "root...	" << len_root << endl;

		
	if(len_root <= 4096)  // wenn root part kleiner ist wie 4GiB
	{
		exit(6);
	}
	
	len_rest = len_rest - len_root;
	len_home = len_rest;    // der rest ischd home
	
	cout << "home...	" << len_home << endl;
	
	if(len_home <= 1024)   // kleiner wie nen gig soll /home auch net sein...
	{
		exit(7);
	}
	
	Ped::Disk *disk = new Ped::Disk(*device);
	
	cout << "alles loeschen..." << endl;
	
	if(len_home + len_root + len_swap + len_boot > dev_len)
	{
		exit(9);
	}
	
	disk->delete_all();
	
	string create_part = "/sbin/parted " + s2 + " mkpart primary ext3 0";
	char exec[create_part.length() + 500];
	
	sprintf(exec, "%s %i", create_part.c_str(), len_boot);
	
	//cout << exec << endl;
	system(exec);   // boot
	
	create_part = "/sbin/parted " + s2 + " mkpart primary ext3";
	sprintf(exec, "%s %i", create_part.c_str(), len_boot);
	sprintf(exec, "%s %i", exec, len_boot + len_root);
	
	//cout << exec << endl;
	system(exec); // root
		
	create_part = "/sbin/parted " + s2 + " mkpart primary ext3";
	sprintf(exec, "%s %i", create_part.c_str(), len_boot+len_root);
	sprintf(exec, "%s %i", exec, len_boot + len_root + len_home);
	
	//cout << exec << endl;
	system(exec); // root

	// cout << exec << endl;
	create_part = "/sbin/parted " + s2 + " mkpart primary linux-swap";
	sprintf(exec, "%s %i", create_part.c_str(), len_boot+len_root+len_home);
	sprintf(exec, "%s %i", exec, dev_len);
	
	//cout << exec << endl;
	system(exec); // root	
	
	delete disk;
	
	return true;
}
