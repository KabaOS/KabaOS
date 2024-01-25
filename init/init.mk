build:
	@$(CC) $(CFLAGS) -static main.c -o init  -specs "../build/musl-gcc-init.specs"
