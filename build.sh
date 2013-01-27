gcc -o wlinker ./tools/wlinker.c
nasm -f bin boot.s -o boot.bin
gcc -m32 -o main main.c pci.c sysfunc.c
./wlinker head.s main 
cat boot.bin system.bin > merge.bin
dd conv=sync if=merge.bin of=boot.img bs=1440k count=1
rm -f boot.bin head.bin system.bin merge.bin main wlinker
