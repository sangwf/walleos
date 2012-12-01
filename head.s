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

	;init keyboard interrupt	
	mov ax, keyboard_int
	mov dx, 0xef00
	mov ecx,  0x09
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	;clock interrupt: 显示时间
	mov ax, clock_int
	mov dx, 0xef00
	mov ecx,  0x79
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

	;DEBUG:
	mov ch, 0x02
	mov bh, 24

	mov al, 'W'
	mov bl, 0
	call write_char_by_pos

	mov al, 'A'
	mov bl, 1
	call write_char_by_pos
	mov al, 'L'
	mov bl, 2
	call write_char_by_pos
	mov al, 'L'
	mov bl, 3
	call write_char_by_pos
	mov al, 'E'
	mov bl, 4
	call write_char_by_pos
	mov al, 'O'
	mov bl, 5
	call write_char_by_pos
	mov al, 'S'
	mov bl, 6
	call write_char_by_pos
	mov al, ' '
	mov bl, 7
	call write_char_by_pos
	mov al, 'V'
	mov bl, 8
	call write_char_by_pos
	mov al, '1'
	mov bl, 9
	call write_char_by_pos
	mov al, '.'
	mov bl, 10
	call write_char_by_pos
	mov al, '3'
	mov bl, 11
	call write_char_by_pos
	mov al, ':'
	mov bl, 12
	call write_char_by_pos

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
	push edx
	mov ebx, SCRN_SEL
	mov gs, bx
	mov bx, [scr_loc]	

	mov dl, 0 ;作为特殊按键的标记
	;处理回车按键0x1c
	cmp al, 0x1c
	jne left_ctrl_key
return_key:
	push eax

	mov ax, bx
	mov cl, 80
	div cl ;al商，ah余数
	sub cl, ah
	mov dl, cl
	mov dh, 0
	add bx, dx
	sub bx, 1

	pop eax	
	mov al, ' ' ;对于return key，直接输出一个空格
left_ctrl_key:
	cmp al, 0x1d
	jne delete_key

	mov al, ' '
	mov dl, 1
delete_key: ;处理delete按键
	cmp al, 0x0e
	jne normal_char

	cmp bx, 0 
	je not_delete
	sub bx, 1 ;减1
not_delete:
	mov al, ' '
	mov dl, 1

normal_char:	


	shl ebx, 1
	mov [gs:ebx],al
	; color
	mov [gs:ebx+1],ch

	shr ebx, 1

;正常的char才需要+1
	cmp dl, 1
	je not_add_loc
	add ebx, 1
not_add_loc:
	cmp ebx, 1920 ;1920个字符位置
	jb wc_o
	mov ebx, 0
wc_o:	mov [scr_loc], ebx
	
	call mov_cur
	shl ebx, 1
	mov [gs:ebx+1],ch
write_char_ret:
	pop edx
	pop ebx
	pop gs
	ret

mov_cur: ;移动光标，ebx保存有cur要设置的位置
	push eax
	push edx        

	;--------------------------------------;
        ;   VGA寄存器 低字节;
        ;--------------------------------------;

        mov     al, 0x0f               ; 光标位置低字节索引
        mov     dx, 0x03D4             ; 写到CRT索引寄存器
        out     dx, al

        mov     al, bl                 ; 当前位置在EBX中，BL包含低字节，BH高字节
        mov     dx, 0x03D5             ; 写到数据寄存器
        out     dx, al                 ; 低字节

        ;---------------------------------------;
        ;   VGA 寄存器 高字节;
        ;---------------------------------------;

        xor     eax, eax
        mov     al, 0x0e               ; 光标位置高字节索引
        mov     dx, 0x03D4             ; 写到CRT索引寄存器
        out     dx, al
 
        mov     al, bh                 ; 当前位置在EBX中，BL包含低字节，BH高字节
        mov     dx, 0x03D5             ; 写到数据寄存器
        out     dx, al                 ; 高字节
mov_cur_ret:
	pop edx
	pop eax
        ret


;输入一个字符al到bh行，bl列，ch为color
write_char_by_pos:
	push gs
	push ebx
	push edx

	mov edx, SCRN_SEL
	mov gs, dx

	push bx
	;计算屏幕位置，bh*80+bl+si
	;mov edx, bh 
	;multi edx, 80
	mov edx, 0
for_mult1:
	cmp bh, 0
	je end_mult1
	add edx, 80
	sub bh, 1
	jmp for_mult1

end_mult1:

	mov bh, 0	
	add dx, bx ; add bl

	pop bx

;	mov ax, dx
;	call print_binary

	
	;print
	shl edx, 1
	mov [gs:edx], al
	mov [gs:edx+1], ch


	pop edx
	pop ebx
	pop gs
	ret

;打印一个整数ax到bh行，bl列, 颜色信息存放在ch
print_binary:
	push gs
	push edx
	push si
	push di
	push eax

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

	pop eax
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
clock_int: ;显示时钟
	push ds
	push eax
	;get time
	;second
	mov al, 0x00
	out 0x70, al
	in al, 0x71
	mov [tm_sec], al

	;miniute
	mov al, 0x02
	out 0x70, al
	in al, 0x71
	mov [tm_min], al

	;hour
	mov al, 0x04
	out 0x70, al
	in al, 0x71
	mov [tm_hour], al


	mov ch, 0x02 ;color
	mov bh, 24 ;行

	mov al, [tm_sec]
	xor edx, edx
	mov dl, al
	shl dl, 4
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 79
	call write_char_by_pos

	mov al, [tm_sec]
	xor edx, edx
	mov dl, al
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 78
	call write_char_by_pos

	mov al, ':'
	mov bl, 77
	call write_char_by_pos

	mov al, [tm_min]
	xor edx, edx
	mov dl, al
	shl dl, 4
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 76
	call write_char_by_pos

	mov al, [tm_min]
	xor edx, edx
	mov dl, al
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 75
	call write_char_by_pos

	mov al, ':'
	mov bl, 74
	call write_char_by_pos

	mov al, [tm_hour]
	xor edx, edx
	mov dl, al
	shl dl, 4
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 73
	call write_char_by_pos

	mov al, [tm_hour]
	xor edx, edx
	mov dl, al
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 72
	call write_char_by_pos


	pop eax
	pop ds
	iret



mode:	db 0
leds:	db 0
e0:	db 0

align 4
keyboard_int:
	push eax
	push ebx
	push ecx
	push edx
	push ds
	push es

	mov eax, 0x10  ; 系统数据段
	mov ds, ax
	mov es, ax

	in al, 0x60


	cmp al, 0xe0
	je set_e0
	cmp al, 0xe1
	je set_e1
	;call [key_table+eax*4]
	call do_self
	mov cl, 0
	mov [e0], cl

e0_e1:
	in al, 0x61
	or al, 0x80 ; al 位7置位，禁止键盘工作
	out 0x61, al ;使PPI PB7位置位
	add al, 0x7F ; al位7复位	
	out 0x61, al ; 使PPI PB7位复位，允许键盘工作
	mov al, 0x20 ;向8259中断芯片发送EOI中断结束信号
	out 0x20, al

kb_ret:
	pop es
	pop ds
	pop edx
	pop ecx
	pop ebx
	pop eax
	iret

set_e0:
	mov cl, 1
	mov [e0],cl
	jmp e0_e1
set_e1:	
	mov cl, 2
	mov [e0],cl
	jmp e0_e1

do_self:
	;剔除按键弹起的消息，第8位为1
	mov bl, al
	and bl, 0x80
	cmp bl, 0
	jne none

	;word_count++
	push edx
	mov dx, [word_count]
	inc dx
	mov [word_count], dx
	pop edx

	push eax
	call func_main
	pop eax

	mov ch, 0x07 ;screen color
	mov bh, 24
	mov bl, 15
	call print_binary	
	and ax, 0x007f


	mov al, [key_map+eax]

	call write_char

;	mov ch, 0x02
;	mov bh, 0
;	mov bl, 0
;	call write_char_by_pos	

none:
	ret

;for macbook pro keyboard
key_map:
	db 0
	db "01234567890-="
	db 0x0e ;delete key
	db " qwertyuiop[]"
	db 0x1c ;return key
	db 0x1d ;ctrl key(left)
	db "asdfghjkl;'"
	db "  \zxcvbnm,./"
	
	times 128 db 0



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
word_count:
	dd 0
tm_sec:
	db 0
tm_min:
	db 0
tm_hour:
	db 0


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

task0: ;显示字母数量
	mov eax, 0x17
	mov ds, ax
	mov ax, [word_count]
	mov ch, 0x04 ;color
	mov bh, 24 ;行
	mov bl, 44 ;列
	int 0x81
	jmp task0
task1: ;显示时间
	int 0x79
	jmp task1

	times 128 dd 0
usr_stk1:
func_main:

