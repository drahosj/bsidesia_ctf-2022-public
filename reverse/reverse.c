#include <stdio.h>
#include <string.h>

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

char * pass = "TheSecretPassword\n";

int main()
{
      setbuf(stdout, NULL);

      printf("Enter the password for the flag:\n");
      
      size_t len = 0;
      char * buf = NULL;
      getline(&buf, &len, stdin);

      if (!strcmp(buf, pass+3)) {
            give_flag();
      } else {
            puts("Wrong password!");
      }

      return 0;
}
