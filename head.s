LATCH equ 11930
;LATCH equ 59650 ; 11930*5
SCRN_SEL equ 0x18
TSS0_SEL equ 0x20
LDT0_SEL equ 0x28
TSS1_SEL equ 0x30
LDT1_SEL equ 0x38

bits 32
;mov ax, 0x4344

startup_32:
	mov eax, 0x10 ;指向系统段
	mov ds, ax

	lss esp, [init_stack] ;这里出错的话，就检查你的数据段是不是正常的完整的拷贝到了0x0000
	call setup_idt
	call setup_gdt

	mov eax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	lss esp, [init_stack]

	mov al, 0x36
	mov edx, 0x43
	out dx, al 

	mov eax, LATCH
	mov edx, 0x40
	out dx, al
	mov al, ah
	out dx, al

	mov eax,  0x00080000
	mov ax, timer_interrupt
	mov dx, 0x8E00
	mov ecx, 0x08
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx
	mov ax, system_interrupt
	mov dx, 0xef00
	mov ecx,  0x80
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	;中断0x81	
	mov ax, print_bin_interrupt
	mov dx, 0xef00
	mov ecx,  0x81
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx


	pushfd
	mov eax, 0xffffbfff
	and dword [esp], eax
	popfd
	mov eax, TSS0_SEL
	ltr ax
	mov eax, LDT0_SEL
	lldt ax
	mov dword [current], 0
	sti
	push 0x17
	push init_stack
	pushfd
	push 0x0f
	push task0
	iret

setup_gdt:
	lgdt [lgdt_opcode]
	ret

setup_idt:
	lea edx, [ignore_int]
	mov eax, 0x00080000
	mov ax, dx
	mov dx, 0x8E00
	lea edi, [idt]
	mov ecx, 256

rp_idt: mov [edi], eax
	mov [edi+4], edx
	add edi, 8
	dec ecx
	jne rp_idt
	lidt [lidt_opcode]
	ret

write_char:
	push gs
	push ebx
	mov ebx, SCRN_SEL
	mov gs, bx
	mov bx, [scr_loc]
	shl ebx, 1
	mov [gs:ebx],al

	; color
	mov al, ah;0x0002
	mov [gs:ebx+1],al

	shr ebx, 1
	add ebx, 4
	cmp ebx, 2000 ;2000个字符位置
	jb wc_o
	mov ebx, 0
wc_o:	mov [scr_loc], ebx
	pop ebx
	pop gs
	ret

;打印一个整数ax到bh行，bl列, 颜色信息存放在ch
print_binary:
	push gs
	push edx
	push si
	push di

	;备份
	mov di, ax	
	mov edx, SCRN_SEL
	mov gs, dx

	mov si, 0 ;共16位，从左向右打印
repeat_pos:
	mov ax, di ;还原ax

	mov dx, si
	mov cl, dl
	shl ax, cl
	shr ax, 15 ;移到最右侧1位
	;计算屏幕位置，bh*80+bl+si
	;mov edx, bh 
	;multi edx, 80
	push bx
	mov edx, 0
for_mult:
	cmp bh, 0
	je end_mult
	add edx, 80
	sub bh, 1
	jmp for_mult

end_mult:

	mov bh, 0	
	add dx, bx ; add bl
	add dx, si ; dx存放位置

	pop bx

	;print
	shl edx, 1
	add al, '0';加上asc偏移
	mov [gs:edx], al
	mov [gs:edx+1], ch


	inc si
	cmp si, 16
	jb repeat_pos

	pop di
	pop si
	pop edx
	pop gs
	ret

align 4
ignore_int:
	push ds
	push eax
	mov eax, 0x10
	mov ds,ax
	mov eax, 'I'
	mov ah, 0x0003
	call write_char
	pop eax
	pop ds
	iret


align 4
timer_interrupt:
	push ds
	push eax
	;for test
	;mov eax, 'T'
	;mov ah, 0x04;4
	;call write_char
	;end test
	
	mov eax, 0x10
	mov ds, ax
	mov al, 0x20
	out 0x20, al
	mov  eax, 1

	;pop eax
	;pop ds
	;iret


	cmp [current], eax
	je task0_cur
	mov dword [current], eax
	jmp TSS1_SEL:0
	jmp task1_cur
task0_cur:	
	mov dword [current], 0
	jmp TSS0_SEL:0
task1_cur:	
	pop eax
	pop ds
	iret


align 4
system_interrupt:
	push ds
	push edx
	push ecx
	push ebx
	push eax
	mov edx, 0x10
	mov ds, dx
	;mov ah, 0x0002
	call write_char
	pop eax
	pop ebx
	pop ecx
	pop edx
	pop ds
	iret
align 4
print_bin_interrupt:
	push ds
	push edx
	push ecx
	push ebx
	push eax
	;mov ch, 0x02; color
	call print_binary
	pop eax
	pop ebx
	pop ecx
	pop edx
	pop ds
	iret



current: 
	dd 0
scr_loc: 
	dd 0
task0_count:
	dd 0
task1_count:
	dd 0


align 4
	dw 0
lidt_opcode:
	dw 256*8-1
	dd idt
lgdt_opcode:
	dw (end_gdt-gdt)-1
	dw gdt, 0

align 8
idt:
	times 2048 db 0

gdt:	dw 0, 0, 0, 0
	dw 0x07ff, 0x0000, 0x9a00, 0x00c0 ;0x08
	dw 0x07ff, 0x0000, 0x9200, 0x00c0 ;0x10
	dw 0x0002, 0x8000, 0x920b, 0x00c0 ;0x18
	dw 0x68, tss0, 0xe900, 0x0 ;0x20
	dw 0x40, ldt0, 0xe200, 0x0 ;0x28
	dw 0x68, tss1, 0xe900, 0x0 ;0x30
	dw 0x40, ldt1, 0xe200, 0x0 ;0x38
	dw 0x0002, 0x8000, 0x920b, 0x00c0 ;0x40
end_gdt:
	times 128 dd 0 
init_stack:
	dd init_stack
	dw 0x10

align 8
ldt0:	dw 0, 0, 0, 0
	dw 0x03ff, 0x0000, 0xfa00, 0x00c0
	dw 0x03ff, 0x0000, 0xf200, 0x00c0

tss0:	dd 0
	dd krn_stk0, 0x10
	dd 0, 0, 0, 0, 0
	dd 0, 0, 0, 0, 0
	dd 0, 0, 0, 0, 0
	dd 0, 0, 0, 0, 0, 0
	dd LDT0_SEL, 0x80000000

	times 128 db 0
krn_stk0:

align 8
ldt1:	dw 0, 0, 0, 0
	dw 0x03ff, 0x0000, 0xfa00, 0x00c0
	dw 0x03ff, 0x0000, 0xf200, 0x00c0


tss1:	dd 0
	dd krn_stk1, 0x10
	dd 0, 0, 0, 0, 0
	dd task1, 0x200
	dd 0, 0, 0, 0
	dd usr_stk1, 0, 0, 0
	dd 0x17, 0x0f, 0x17, 0x17, 0x17, 0x17
	dd LDT1_SEL, 0x80000000

	times 128 dw 0
krn_stk1:

task0:
	mov eax, 0x17
	mov ds, ax
	mov ax, [task0_count]
	add ax, 2
	mov [task0_count], ax
	mov ch, 0x04 ;color
	mov bh, 2
	mov bl, 0
	int 0x81
	mov ecx, 0xfffff
t0:	loop t0
	jmp task0
task1:
	mov ax, [task1_count]
	inc ax
	mov [task1_count], ax
	mov ch, 0x02 ;color
	mov bh, 5
	mov bl, 0
	int 0x81
	mov ecx, 0xfffff
t1:	loop t1
	jmp task1

	times 128 dd 0
usr_stk1:


