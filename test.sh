nasm -l jmptest.lst head.s -o test.bin
cat jmptest.lst
rm -f jmptest.lst test.bin
