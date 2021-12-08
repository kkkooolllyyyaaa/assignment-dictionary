all: main

main: main.o lib.o dict.o
	ld main.o lib.o dict.o -o main

main.o: colon.inc main.asm
	nasm -f elf64 -o main.o main.asm

lib.o: lib.asm
	nasm -f elf64 -o lib.o  lib.asm

dict.o: dict.asm
	nasm -f elf64 -o dict.o  dict.asm

clean:
	rm -rf *.o
