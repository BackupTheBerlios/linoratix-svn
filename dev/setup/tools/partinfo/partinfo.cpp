#include <iostream>
#include <partedpp/partedpp.h>
#include <cstdlib>
#include <string>

using namespace std;

Ped::Device *device;

void get_model();
void get_size();

int main(int argc, char *argv[])
{
	string s1;
	
	device = new Ped::Device(argv[2]);

	s1 = argv[1];
	
	if(s1 == "model")
	{
		get_model();
	}
	else if(s1 == "size")
	{
		get_size();
	}
	else
	{
		cout << "Wrong parameter!" << endl;
	}
	
	delete device;
	return EXIT_SUCCESS;
}

void get_model()
{
	cout << device->get_model() << endl;
}

void get_size()
{
	cout << device->get_length() / 2 << endl;
}
