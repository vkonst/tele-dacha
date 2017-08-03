# build usleep executable when user executes "make"
usleep: usleep.o
	$(CC) $(LDFLAGS) usleep.o -o usleep
usleep.o: usleep.c
	$(CC) $(CFLAGS) -c usleep.c

# remove object files and executable when user executes "make clean"
clean:
	rm *.o usleep
