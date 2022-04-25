#include <stdio.h>

void give_flag()
{
	size_t len = 0;
	char * buf = NULL;
	FILE * flag = fopen("flag.txt", "r");

	getline(&buf, &len, flag);
	printf(buf);
}

int main()
{
	setbuf(stdout, NULL);

	printf("What is your name?\n");
	char buf[64];
	fread(buf, 1, 4096, stdin);
	if (0) { /* NEVER GIVE THE FLAG!!! */
		give_flag();
	} else {
		printf("%s, you do not get the flag!\n", buf);
	}

	return 0;
}
