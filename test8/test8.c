/* test8.c:
 *
 * allocate a huge ammount of memory and random access for the time allowed
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define KB ((size_t)1024)
#define MB (KB * (size_t)1024)
#define GB (MB * (size_t)1024)

int main(int argc, char *argv[])
{
	time_t started;
	unsigned char *memblock;
	size_t blocksize;
	time_t runtime;
	long int arg1, arg2;
	char sizestr[80];
	unsigned long granularity, pos, skip;

	if (argc != 3) {
		printf("Failed: wrong number of arguments "
				"(expected 3, got %d)\n", argc);
		return EXIT_FAILURE;
	}
	if (sscanf(argv[1], "%ld", &arg1) != 1 || arg1 < 0 ||
			sscanf(argv[2], "%ld", &arg2) != 1 || arg2 < 0) {
		printf("Failed: usage %s <BYTES> <SECONDS>\n", argv[0]);
		return EXIT_FAILURE;
	}
	blocksize = arg1;
	runtime = arg2;

	if (blocksize > GB) {
		sprintf(sizestr, "%.2f GB", (double)blocksize / (double)GB);
	}
	else if (blocksize > MB) {
		sprintf(sizestr, "%.2f MB", (double)blocksize / (double)MB);
	}
	else if (blocksize > KB) {
		sprintf(sizestr, "%.2f KB", (double)blocksize / (double)KB);
	}
	else {
		sprintf(sizestr, "%lu bytes", (unsigned long)blocksize);
	}
	printf("Trying to allocate %s\n", sizestr);

	if (!(memblock = malloc(blocksize))) {
		printf("Failed: could not allocate %s\n", sizestr);
		return EXIT_FAILURE;
	}

	/* Try to access as many data pages as possible in the given time, so
	 * that the OS will give us as much resident memory as we can get.
	 * Start by accessing the first and the last possitions of the memory
	 * block, then access the middle, the quartiles, and so on
	 */
	printf("Accessing data pages...\n");
	
	memblock[0] = rand() % 256;
	memblock[blocksize - 1] = rand() % 256;

	started = time(NULL);
	srand(started);
	granularity = 1;
	while (time(NULL) - started < runtime) {
		granularity++;

		skip = (unsigned long)blocksize / granularity;
		skip = skip > 1 ? skip : 1;
		pos = skip;
		while (time(NULL) - started < runtime && (size_t)pos < blocksize) {
			memblock[pos] = rand() % 256;
			pos += skip;
		}
	}
	free(memblock);

	return EXIT_SUCCESS;
}
