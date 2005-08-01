#include "lpm.h"
#include <stdlib.h>

int main()
{
	lpm_package pkg, pkg2;
	lpm_resource res, res2;
	
	int max_n=0;

	printf("Hello LPM!\n");

	pkg.name = malloc(4);
	strcpy(pkg.name, "test");

	pkg.maintainer = malloc(sizeof(lpm_maintainer));
	pkg.maintainer->bugreport_email = malloc(21);
	strcpy(pkg.maintainer->bugreport_email, "jfried@linoratix.com");
	
	pkg.maintainer->persons = NULL;
	
	// dynamisches "array" wenn 100 eintraege erreicht sind muss es erhoeht werden.
	pkg.maintainer->persons = (lpm_author **)realloc(pkg.maintainer->persons, 100 * sizeof(lpm_author*));
	pkg.maintainer->persons[0] = (lpm_author *)malloc(sizeof(lpm_author));
	pkg.maintainer->persons[0]->given_name = malloc(4);
	strcpy(pkg.maintainer->persons[0]->given_name, "jan");

	// 2. maintainer
	pkg.maintainer->persons[1] = (lpm_author *)malloc(sizeof(lpm_author));
	pkg.maintainer->persons[1]->given_name = malloc(10);
	strcpy(pkg.maintainer->persons[1]->given_name, "friedrich");


	printf("Name: %s\n", pkg.name);
	printf("Email: %s\n", pkg.maintainer->bugreport_email);
	printf("Maint_given_name: %s\n", pkg.maintainer->persons[0]->given_name);
	printf("Maint_given_name2: %s\n", pkg.maintainer->persons[1]->given_name);
	printf("--------------------\n");


	res = lpm_open("./test.lip", RES_OPEN_W);
	lpm_write(&res, &pkg);
	lpm_close(&res);
	


	res2 = lpm_open("./test.lip", RES_OPEN_R);
	lpm_read(&res2, &pkg2);
	lpm_close(&res2);
	
	printf("Name2: %s\n", pkg2.name);
	printf("Email: %s\n", pkg2.maintainer->bugreport_email);
	printf("Maint_given_name: %s\n", pkg2.maintainer->persons[0]->given_name);
	printf("Maint_given_name2: %s\n", pkg2.maintainer->persons[1]->given_name);

	
	//package_info(&pkg);
	
	//printf("name: %s\n", pkg.name);
	//printf("given_name: %s\n", (*pkg.author).given_name);	 */
}

