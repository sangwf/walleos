if [ ! -f wlinker ]; then
    echo "Create a new wlinker ..."
    gcc -o wlinker ./tools/wlinker.c
fi
nasm -f bin boot.s -o boot.bin
gcc -m32 -o wsh wsh.c pci.c sysfunc.c
./wlinker head.s wsh 
cat boot.bin system.bin > merge.bin
dd conv=sync if=merge.bin of=boot.img bs=1440k count=1
rm -f boot.bin head.bin system.bin merge.bin wsh
