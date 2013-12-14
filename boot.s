BOOTSEG equ 0x07c0

jmp BOOTSEG: go

go:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x400

ready_to_load:
    mov bp, BootMessage    ;es:bp = 串地址
    mov cx, 18    ;cs = 串长度
    mov ax, 01301h
    mov bx, 000ch
    mov dl, 0
;   int 10h


load_system:
    mov dx, 0x0000
    mov cx, 0x0002
    mov ax, 0x1000 ;SYSSEG
    mov es, ax
    xor bx, bx
    mov ax, 0x200 + 54 ;SYSLEN
    int 0x13
    jnc ok_load
die:
    jmp die

ok_load:
    cli
    mov ax, 0x1000 ;SYSSEG
    mov ds, ax
    xor ax, ax
    mov es, ax
    mov cx, 8192 ; 移动8192个double word(4 bytes)，这里拷贝少了会导致加载的head.s代码不完整
    sub si, si
    sub di, di
    rep movsd

    mov ax, cs
    mov ds, ax
    lidt [idt_48]
    lgdt [gdt_48]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp dword 0x0008: 0x00000000

gdt:
    dw 0
    dw 0
    dw 0
    dw 0      ;0x00

    dw 0x07FF ;0x08
    dw 0x0000
    dw 0x9A00
    dw 0x00C0

    dw 0x07FF ;0x10
    dw 0x0000
    dw 0x9200
    dw 0x00C0

    dw 0x0002 ;0x18
    dw 0x8000
    dw 0x920b
    dw 0x00c0

    dw 0x07FF ;0x20
    dw 0x7c00
    dw 0x9A00
    dw 0x00c0
end_gdt:

idt_48:
    dw 0
    dw 0, 0
gdt_48:
    dw (end_gdt - gdt) - 1
    dw BOOTSEG * 16 + gdt, 0

BootMessage:
    db "Loading System ..."

times 510 - ($ - $$) db 0
dw 0xAA55
