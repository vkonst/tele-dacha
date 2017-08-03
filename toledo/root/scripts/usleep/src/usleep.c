#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char **argv) {
        if (argc != 3) printf("Usage : sleep unit duration\n");
        if (strcmp("ms", argv[1]) == 0) sleep(atoi(argv[2]));
        else if (strcmp("us", argv[1]) == 0) usleep(atoi(argv[2]));
        exit(0);
}

