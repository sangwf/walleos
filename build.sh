nasm -f bin boot.s -o boot.bin
nasm -f bin head.s -o head.bin
cat boot.bin head.bin > merge.bin
dd conv=sync if=merge.bin of=boot.img bs=1440k count=1
rm -f boot.bin head.bin merge.bin
