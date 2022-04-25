#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

void give_flag()
{
        size_t len = 0;
        char * buf = NULL;
        FILE * flag = fopen("flag.txt", "r");
        
        if (flag == NULL) {
              puts("Tried to give flag, but flag.txt doesn't exist.");
              return;
        }

        getline(&buf, &len, flag);
        fclose(flag);
        printf(buf);
}

char * pass = "password";

int main()
{
      setbuf(stdout, NULL);
      srand(time(NULL));

      int x = rand() % 10;
      int y = rand() % 10;
      printf("If you are human, solve %d + %d: ", x, y);

      size_t len = 0;
      char * buf = NULL;
      getline(&buf, &len, stdin);

      if (atoi(buf) != x + y) {
            puts("Begone bot!");
            return 0;
      }


      printf("Enter the password for the flag: ");
      getline(&buf, &len, stdin);

      if (!strcmp(buf, pass)) {
            give_flag();
      } else {
            puts("Wrong password!");
      }

      return 0;
}
