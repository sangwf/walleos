gcc -o macho_parse ./tools/macho_parse.c
gcc -m32 -c main.c
./macho_parse main.o 
mv __text main.bin
chmod 777 main.bin
nasm -f bin boot.s -o boot.bin
nasm -f bin head.s -o head.bin
cat boot.bin head.bin main.bin > merge.bin
dd conv=sync if=merge.bin of=boot.img bs=1440k count=1
rm -f boot.bin head.bin merge.bin main.o main.bin macho_parse
