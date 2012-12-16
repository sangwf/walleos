gcc -o macho_parse ./tools/macho_parse.c
gcc -m32 -c pci.c
./macho_parse pci.o 1>/dev/null 
mv __text pci.bin
chmod 777 pci.bin
nasm -f bin boot.s -o boot.bin
nasm -f bin head.s -o head.bin
cat boot.bin head.bin pci.bin > merge.bin
dd conv=sync if=merge.bin of=boot.img bs=1440k count=1
rm -f boot.bin head.bin merge.bin pci.bin macho_parse
