#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// LPM
#include <lpm/lpm.h>

lpm_author **get_author_information(int a)
{
	int author_count = 0;
	int count = 0;
	char input[2000];
	
	lpm_author **authors=NULL;
	
	if(a == 1)
	{
		printf("How much maintainers for this package: ");
	} else
	{
		printf("How much authors for this package: ");
	}
	
	scanf("%i", &author_count);
	
	printf("Well, we have %i people(s)!\n\n", author_count);
	
	authors = (lpm_author **)realloc(authors, author_count * sizeof(lpm_author*));
	
	for(count = 1; count <= author_count; count++)
	{
		authors[(count-1)] = (lpm_author *)malloc(sizeof(lpm_author));
		
		if(a == 1)
		{
			printf("Please give type the information for maintainer %i ('none' for no information):\n", count);
		} else
		{
			printf("Please give type the information for author %i ('none' for no information):\n", count);
		}
		printf("Given name: ");
		scanf("%s", &input);
		authors[(count-1)]->given_name = malloc(strlen(input)+1);
		strcpy(authors[(count-1)]->given_name, input);
		
		printf("Surname: ");
		scanf("%s", &input);
		authors[(count-1)]->surname = malloc(strlen(input)+1);
		strcpy(authors[(count-1)]->surname, input);
		
		printf("E-Mail: ");
		scanf("%s", &input);
		authors[(count-1)]->email = malloc(strlen(input)+1);
		strcpy(authors[(count-1)]->email, input);
		
		printf("Homepage: ");
		scanf("%s", &input);
		authors[(count-1)]->homepage = malloc(strlen(input)+1);
		strcpy(authors[(count-1)]->homepage, input);
		
		printf("Nickname: ");
		scanf("%s", &input);
		authors[(count-1)]->nick = malloc(strlen(input)+1);
		strcpy(authors[(count-1)]->nick, input);
	}
	
	return authors;
}

lpm_maintainer get_maintainer_information(void)
{
	lpm_maintainer maintainer;
	int author_count;
	char input[2000];

	maintainer.persons = NULL;
	maintainer.persons = (lpm_author **)realloc(maintainer.persons, 100 * sizeof(lpm_author*));
	maintainer.persons = get_author_information(1);	
	
	printf("Bugreport E-Mail: ");
	scanf("%s", &input);
	maintainer.bugreport_email = malloc(strlen(input)+1);
	strcpy(maintainer.bugreport_email, input);
	
	return maintainer;
}

lpm_dependency **get_dependency_information(void)
{
	lpm_dependency **deps=NULL;
	int dep_count=0;
	int count=0;
	char input[2000];
	
	printf("How much dependencies does this package have: ");
	scanf("%i", &dep_count);
	
	deps = (lpm_dependency **)realloc(deps, dep_count * sizeof(lpm_dependency*));
	for(count = 1; count <= dep_count; count++)
	{
		deps[(count-1)] = (lpm_dependency *)malloc(sizeof(lpm_dependency));
		
		printf("Packetname (%i): ", count);
		scanf("%s", &input);
		deps[(count-1)]->package_name = malloc(strlen(input)+1);
		strcpy(deps[(count-1)]->package_name, input);
		
		printf("Modifier (%i): ", count);
		scanf("%s", &input);
		deps[(count-1)]->version_modifier = malloc(strlen(input)+1);
		strcpy(deps[(count-1)]->version_modifier, input);		

		printf("Packetversion (%i): ", count);
		scanf("%s", &input);
		deps[(count-1)]->package_version = malloc(strlen(input)+1);
		strcpy(deps[(count-1)]->package_version, input);		
	}
	
	return deps;
}

int main(void)
{
	lpm_package package;
	lpm_author **authors;
	lpm_resource res;

	char input[2000];
	char *package_filename;
	
	printf("Welcome to the LIP Creator Tool.\n\n");
	printf("This program will guide you through the steps of creating a ");
	printf("Linoratix Package.\n\n");
	
	package.authors = NULL;
	package.dependencies = NULL;
	
	printf("Packagenname: ");
	scanf("%s", &input);
	package.name = malloc(strlen(input)+1);
	strcpy(package.name, input);
	
	printf("Version: ");
	scanf("%s", &input);
	package.version = malloc(strlen(input)+1);
	strcpy(package.version, input);
	
	printf("License: ");
	scanf("%s", &input);
	package.license = malloc(strlen(input)+1);
	strcpy(package.license, input);
	
	printf("Homepage: ");
	scanf("%s", &input);
	package.homepage = malloc(strlen(input)+1);
	strcpy(package.homepage, input);

	package.authors = get_author_information(0);
	package.maintainer = get_maintainer_information();
	package.dependencies = get_dependency_information();
	
	package_filename = malloc(strlen(package.name) + strlen(package.version) + 6);
	strcpy(package_filename, package.name);
	strcat(package_filename, "-");
	strcat(package_filename, package.version);
	strcat(package_filename, ".lip");

	res = lpm_open(package_filename, RES_OPEN_W);
	lpm_write(&res, &package);
	lpm_close(&res);
	
	return(0);
}
