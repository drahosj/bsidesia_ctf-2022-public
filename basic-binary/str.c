#include <stdio.h>
#include <stdlib.h>

int main()
{
	setbuf(stdout, NULL);

	FILE * flag = fopen("flag.txt", "r");
      size_t flaglen = 0;
      char * flagbuf = NULL;
      if (flag != NULL) {
            getline(&flagbuf, &flaglen, flag);
      }

	printf("What is your name?\n");
	size_t len = 0;
	char * buf = NULL;
	getline(&buf, &len, stdin);
      printf("Goodbye, ");
	printf(buf);

      if (flagbuf != NULL) {
            free(flagbuf);
      }
      free(buf);
	return 0;
}
