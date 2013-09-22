LATCH equ 11930
KERNEL_SEL equ 0x08
DATA_SEL equ 0x10
SCRN_SEL equ 0x18
TSS0_SEL equ 0x20
LDT0_SEL equ 0x28
TSS1_SEL equ 0x30
LDT1_SEL equ 0x38

INPUT_BUFFER_SIZE equ 1024 ; 输入缓冲区大小
RETURN_KEY  equ 0x1c ; return key
LAST_ROW equ 24 ; 最后一行

bits 32
start:
	mov eax, DATA_SEL ;指向系统段
	mov ds, ax

    ; 这里出错的话，就检查你的数据段是不是正常的完整的拷贝到了0x0000
	lss esp, [init_stack]
	
    call setup_idt
	call setup_gdt

	mov eax, DATA_SEL
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

	mov ax, int_timer
	mov dx, 0x8E00
	mov ecx, 0x08
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	;init keyboard interrupt	
	mov ax, int_keyboard
	mov dx, 0xef00
	mov ecx,  0x09
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	; netcard interrupt	
	mov ax, int_netcard
	mov dx, 0xef00
	mov ecx,  0x0B
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx


	; clock interrupt: 显示时间
	mov ax, int_clock_display
	mov dx, 0xef00
	mov ecx,  0x79
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

    ; 系统调用的统一入口
	mov ax, int_system
	mov dx, 0xef00
	mov ecx,  0x80
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	; 中断0x81	
	mov ax, int_print_bin
	mov dx, 0xef00
	mov ecx,  0x81
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	; 中断0x82
	mov ax, int_print_hex
	mov dx, 0xef00
	mov ecx,  0x82
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	; 中断0x83
	mov ax, int_print_return
	mov dx, 0xef00
	mov ecx,  0x83
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx

	; 中断0x84
	mov ax, int_print_string
	mov dx, 0xef00
	mov ecx,  0x84
	lea esi, [idt+ecx*8]
	mov [esi], eax
	mov [4+esi], edx


	; 中断0x85
	mov ax, int_print_hex_32
	mov dx, 0xef00
	mov ecx,  0x85
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

	mov ch, 0x02
	mov bh, LAST_ROW
	mov bl, 0
	lea edx, [STR_VERSION]
	call func_write_string_by_pos

	sti
	push 0x17  ; ldt0中的第三项，表示局部数据段
	push init_stack
	pushfd     ; EFLAGS
	push 0x0f  ; CS, ldt0中的第二项，表示局部代码段
	push task0 ; IP
	iret

setup_gdt:
	lgdt [lgdt_opcode]
	ret

setup_idt:
	lea edx, [int_ignore]
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
	push eax
	push ebx
	push ecx
	push edx
	push gs
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
	call func_update_location
	shl ebx, 1
	mov [gs:ebx+1],ch
write_char_ret:
	pop gs
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret

;回车换行
func_write_return:
	push eax
	push ebx
	push ecx
	push edx
	push gs
	mov ebx, SCRN_SEL
	mov gs, bx
	mov bx, [scr_loc] ;bx = location	

	mov ax, bx
	mov cl, 80
	div cl ;al商，ah余数
	sub cl, ah
	mov dl, cl
	mov dh, 0
	add bx, dx
;	sub bx, 1

	call func_update_location
	pop gs
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret


;打印dx为16进制数，" 0x**** "，共占8个位置
func_write_hex:
	push eax
	push ebx
	push ds
	mov eax, 0x10  ; 系统数据段
	mov ds, ax

	mov al, ' '
	call func_write_normal_char
	mov al, '0'
	call func_write_normal_char
	mov al, 'x'
	call func_write_normal_char

	xor eax, 0
	mov al, dh
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dh
	shl al, 4
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dl
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dl
	shl al, 4
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char

	mov al, ' '
	call func_write_normal_char
	pop ds
	pop ebx
	pop eax
	ret

;打印edx为16进制数，" 0x******** "，共占12个位置
func_write_hex_32:
	push eax
	push ebx
	push ds
	mov eax, 0x10  ; 系统数据段
	mov ds, ax

	mov al, ' '
	call func_write_normal_char
	mov al, '0'
	call func_write_normal_char
	mov al, 'x'
	call func_write_normal_char

	;print edx's high word
	push edx
	shr edx, 16

	xor eax, 0
	mov al, dh
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dh
	shl al, 4
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dl
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dl
	shl al, 4
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char

	pop edx

	xor eax, 0
	mov al, dh
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dh
	shl al, 4
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dl
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char
	xor eax, 0
	mov al, dl
	shl al, 4
	shr al, 4
	mov al, [hex_map+eax]
	call func_write_normal_char

	mov al, ' '
	call func_write_normal_char
	pop ds
	pop ebx
	pop eax
	ret

;打印一个常规字符al到屏幕
func_write_normal_char:
	push eax
	push gs
	mov ebx, SCRN_SEL
	mov gs, bx
	mov bx, [scr_loc]	

	shl ebx, 1
	mov [gs:ebx],al
	; color
	mov [gs:ebx+1],ch
	shr ebx, 1
	add ebx, 1
	call func_update_location
	pop gs
	pop eax
	ret


;更新位置偏移
;ebx为新位置请求
func_update_location:
	cmp ebx, 1920 ;1920个字符位置
	jb  mark_not_overflow
	mov ebx, 0
mark_not_overflow:
    mov [scr_loc], ebx
	call func_mov_cur
	ret


func_mov_cur: ;移动光标，ebx保存有cur要设置的位置
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

;输入edx所存以'\0'结尾的字符串到屏幕，ch为color
func_write_string:
	push eax
	push ebx
	push edx

	mov ax, [scr_loc]	
	mov bl, 80
	div bl ;al商，ah余数

	mov bh, al
	mov bl, ah
	call func_write_string_by_pos

	pop edx
	pop ebx
	pop eax
	ret

;输入edx所存以'\0'结尾的字符串到bh行，bl列，ch为color
func_write_string_by_pos:
	push eax
	push ebx
	
mark_wsbp_while:
	cmp byte [edx], 0
	je mark_wsbp_ret
	mov al, [edx]
	call func_write_char_by_pos
	inc bl
	;处理换行问题
	cmp bl, 80
	jne mark_wsbp_next
	mov bl, 0
	inc bh
	cmp bh, LAST_ROW
	jne mark_wsbp_next
	mov bh, 0
mark_wsbp_next:
	inc edx
	jmp mark_wsbp_while
	
mark_wsbp_ret:
	pop ebx
	pop eax
	ret


;输入一个字符al到bh行，bl列，ch为color
func_write_char_by_pos:
	push gs
	push ebx
	push edx

	mov edx, SCRN_SEL
	mov gs, dx

	push ax
	push bx
	;计算屏幕位置，bh*80+bl
	mov al, 80
	mul bh
	mov dx, ax

	mov bh, 0	
	add dx, bx ; add bl

	pop bx
	pop ax
	
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
	push ax
	push bx

	mov al, 80
	mul bh
	mov dx, ax

	mov bh, 0	
	add dx, bx ; add bl
	add dx, si ; dx存放位置

	pop bx
	pop ax

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

;打印一个整数ax到bh行，bl列, 颜色信息存放在ch
;16进制
print_hex:
	push eax
	push ebx
	push ecx
	push edx
	push si
	push di
	push gs
	;备份
	mov di, ax	

	;set gs = SCRN_SEL
	mov edx, SCRN_SEL
	mov gs, dx

	mov si, 0 ;共4位，从左向右打印
repeat_pos2:
	mov ax, di ;还原ax

	push ax
	mov al, 4
	mul si
	mov cl, al
	pop ax

	shl ax, cl
	shr ax, 12 ;移到最右侧1位

	;计算屏幕位置，bh*80+bl+si
	push ax
	push bx

	mov al, 80
	mul bh
	mov dx, ax

	mov bh, 0	
	add dx, bx ; add bl
	add dx, si ; si存放偏移

	pop bx
	pop ax

	;print
	shl edx, 1
	push ebx
	mov ebx, 0
	mov bl, al
	mov al, [hex_map+ebx]
	mov [gs:edx], al
	mov [gs:edx+1], ch
	pop ebx	

	inc si
	cmp si, 4
	jb repeat_pos2

	pop gs
	pop di
	pop si
	pop edx
	pop ecx
	pop ebx
	pop eax	
	ret
hex_map:
	db "0123456789ABCDEF"

align 4
int_ignore:
	push ds
	push eax
	mov eax, 0x10
	mov ds, ax
	mov eax, 'I'
	mov ah, 0x03
    mov bh, LAST_ROW
    mov bl, 60
	call func_write_char_by_pos
	pop eax
	pop ds
	iret


align 4
int_clock_display: ;显示时钟
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
	mov bh, LAST_ROW ;行

	mov al, [tm_sec]
	xor edx, edx
	mov dl, al
	shl dl, 4
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 79
	call func_write_char_by_pos

	mov al, [tm_sec]
	xor edx, edx
	mov dl, al
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 78
	call func_write_char_by_pos

	mov al, ':'
	mov bl, 77
	call func_write_char_by_pos

	mov al, [tm_min]
	xor edx, edx
	mov dl, al
	shl dl, 4
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 76
	call func_write_char_by_pos

	mov al, [tm_min]
	xor edx, edx
	mov dl, al
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 75
	call func_write_char_by_pos

	mov al, ':'
	mov bl, 74
	call func_write_char_by_pos

	mov al, [tm_hour]
	xor edx, edx
	mov dl, al
	shl dl, 4
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 73
	call func_write_char_by_pos

	mov al, [tm_hour]
	xor edx, edx
	mov dl, al
	shr dl, 4	

	mov al, [key_map+1+edx]
	mov bl, 72
	call func_write_char_by_pos


	pop eax
	pop ds
	iret



mode:	db 0
leds:	db 0
e0:	db 0

align 4
int_keyboard:
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

    ; 在屏幕最下方输出按键的二进制码，用于调试
	mov ch, 0x07 ; screen color
	mov bh, LAST_ROW
	mov bl, 30
	call print_binary	

	and ax, 0x007f
	mov al, [key_map + eax]

    ; 记录到buffer中
	push edx
    mov edx, [input_position]
    mov [input_buffer + edx], al
     
    ; update input position
    inc edx
    cmp edx, INPUT_BUFFER_SIZE
    jb .mark_not_update_input_position
    mov edx, 0
.mark_not_update_input_position:
    mov [input_position], edx

    ; 在屏幕上输出字符
	call write_char

	pop edx
none:
	ret

; for macbook pro keyboard
key_map:
	db 0
	db "01234567890-="
	db 0x0e ; delete key
	db " qwertyuiop[]"
	db RETURN_KEY ; return key
	db 0x1d ; ctrl key(left)
	db "asdfghjkl;'"
	db "  \zxcvbnm,./"
	
	times 128 db 0

; 用于按键输入的buffer，循环队列，1024个字节
input_buffer:
    times INPUT_BUFFER_SIZE db 0
; 表示当前buffer的下一个可输入字符
input_position:
    dd 0
; 表示Shell当前处理到的字符位置
deal_position:
    dd 0


align 4
int_timer:
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
int_netcard:
	push ds
	push edx
	push ecx
	push ebx
	push eax
	mov ch, 0x02
	mov bh, LAST_ROW
	mov bl, 0
	lea edx, [STR_VERSION]
	call func_write_string_by_pos
	pop eax
	pop ebx
	pop ecx
	pop edx
	pop ds
	iret

align 4
int_system:
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
int_print_bin:
	push ds
	push edx
	push ecx
	push ebx
	push eax
	mov ch, 0x02; color
	call print_binary
	pop eax
	pop ebx
	pop ecx
	pop edx
	pop ds
	iret

align 4
int_print_hex:
	push ds
	push edx
	push ecx
	push ebx
	push eax
	;print dx
	call func_write_hex
	pop eax
	pop ebx
	pop ecx
	pop edx
	pop ds
	iret

align 4
int_print_hex_32:
	push ds
	push edx
	push ecx
	push ebx
	push eax
	;print dx
	call func_write_hex_32
	pop eax
	pop ebx
	pop ecx
	pop edx
	pop ds
	iret


align 4
int_print_return:
	call func_write_return
	iret

align 4
int_print_string:
	mov ch, 0x02 ;color
	call func_write_string
	iret



STR_PCI_INFO:
	db " BUS     SLOT    FUNC    DEVICE  VENDOR  SUB|CLASS REV|PROGIF PIN|LINE"
	db 0

STR_VERSION:
	db "WALLEOS V1.9(2013/9/19): "
	db 0
ERROR_COMMAND_INFO:
    db "Command not valid. "
    db 0

current: 
	dd 0
scr_loc: 
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

gdt:	
    dw 0, 0, 0, 0
	dw 0x07ff, 0x0000, 0x9a00, 0x00c0 ; 0x08
	dw 0x07ff, 0x0000, 0x9200, 0x00c0 ; 0x10
	dw 0x0002, 0x8000, 0x920b, 0x00c0 ; 0x18
	dw 0x68, tss0, 0xe900, 0x0 ; 0x20
	dw 0x40, ldt0, 0xe200, 0x0 ; 0x28
	dw 0x68, tss1, 0xe900, 0x0 ; 0x30
	dw 0x40, ldt1, 0xe200, 0x0 ; 0x38
	dw 0x0002, 0x8000, 0x920b, 0x00c0 ; 0x40
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

	times 128 dd 0
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

	times 128 dd 0
krn_stk1:

task0: ; for shell
    mov eax, 0x10
    jmp task0
    ; BUG: 修改ds会导致出错？
    mov ds, eax
    mov eax, [input_position]
    cmp eax, [deal_position]
    jne .mark_need_deal

    mov al, 'N'
    mov bh, LAST_ROW
    mov bl, 60
    call func_write_char_by_pos

    jmp task0
.mark_need_deal: 
    mov [deal_position], eax

    mov al, 'D'
    mov bh, LAST_ROW
    mov bl, 60
    call func_write_char_by_pos

    jmp task0
task1: ;显示时间
	int 0x79
	nop
	jmp task1

	times 128 dd 0
usr_stk1:
