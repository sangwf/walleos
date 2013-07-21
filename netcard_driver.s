RTL8139_REG_COMMAND equ 0x37
RTL8139_REG_TXCONFIG_2 equ 0x42 ; transmit configuration register 2
RTL8139_REG_RXCONFIG   equ 0x44 ; receive configuration register 0
RTL8139_REG_9346CR     equ 0x50 ; serial eeprom 93C46 command register
RTL8139_REG_CONFIG1    equ 0x52 ; configuration register 1
RTL8139_REG_CONFIG4    equ 0x5a ; configuration register 4
RTL8139_REG_HLTCLK     equ 0x5b ; undocumented halt clock register

RTL8139_BIT_LWACT      equ 4 ; see RTL8139_REG_CONFIG1
RTL8139_BIT_PMEn       equ 0 ; power management enabled
RTL8139_BIT_LWPTN      equ 2 ; see RTL8139_REG_CONFIG4

NC_IO_ADDR             equ 0xD8820004 ; netcard io address

RTL8139_BIT_93C46_EEM1 equ 7 ; RTL8139 eeprom operating mode1
RTL8139_BIT_93C46_EEM0 equ 6 ; RTL8139 eeprom operating mode0

EE_93C46_REG_ETH_ID    equ 7 ; MAC offset
EE_93C56_READ_CMD      equ 11000000000b ; 110b + 8bit address
EE_93C56_CMD_LENGTH    equ 11 ; start bit + cmd + 8bit address

VER_RTL8139            equ 1100000b
VER_RTL8139A           equ 1110000b
VER_RTL8139B           equ 1111000b
VER_RTL8130            equ VER_RTL8139B
VER_RTL8139C           equ 1110100b
VER_RTL8100            equ 1111010b
VER_RTL8100B           equ 1110101b
VER_RTL8139D           equ VER_RTL8100B
VER_RTL8139CP          equ 1110110b
VER_RTL8101            equ 1110111b

align 4
hw_ver_array: db VER_RTL8139, VER_RTL8139A, VER_RTL8139B, VER_RTL8139C
              db VER_RTL8100, VER_RTL8139D, VER_RTL8139CP, VER_RTL8101
HW_VER_ARRAY_SIZE equ 8

mac_addr: db 0, 0, 0, 0, 0, 0

func_nc_probe:
    mov edx, NC_IO_ADDR
    add edx, RTL8139_REG_HLTCLK
    mov al, 'R'
    out dx, al

    add edx, RTL8139_REG_9346CR - RTL8139_REG_HLTCLK
    mov al, 1
    shl al, RTL8139_BIT_93C46_EEM1
    mov ah, 1
    shl ah, RTL8139_BIT_93C46_EEM0
    or al, ah
    out dx, al

    add edx, RTL8139_REG_CONFIG1 - RTL8139_REG_9346CR
    in al, dx

    mov ah, 1
    shl ah, RTL8139_BIT_PMEn
    or al, ah
    mov ah, 1
    shl ah, RTL8139_BIT_LWACT
    not ah
    and al, ah
    out dx, al
    add edx, RTL8139_REG_CONFIG4 - RTL8139_REG_CONFIG1
    in al, dx

    mov ah, 1
    shl ah, RTL8139_BIT_LWPTN
    not ah
    and al, ah
    out dx, al

    xor al, al
    mov edx, NC_IO_ADDR
    add edx, RTL8139_REG_9346CR
    out dx, al

    ret

func_nc_reset:
    mov edx, NC_IO_ADDR
    add edx, RTL8139_REG_COMMAND
    in al, dx
; get MAC address
    mov ecx, 2
.mac_read_loop:
    lea eax, [EE_93C46_REG_ETH_ID + ecx]
    push ecx
    call func_eeprom_read
    pop ecx
    mov [mac_addr + ecx * 2], ax
 
   
    dec ecx
    jns .mac_read_loop
   
    ret

; @input al
; @output ax
; suppose 93c56 type
func_eeprom_read:
    movzx ebx, al
    or bx, EE_93C56_READ_CMD
    mov cx, EE_93C56_CMD_LENGTH - 1
    
    mov edx, NC_IO_ADDR + RTL8139_REG_9346CR ; edx = command register address
 
    mov al, 10001000b ; wake up eeprom
    out dx, al

.cmd_loop:
    mov al, 10001000b
    bt bx, cx
    jnc .zero_bit
    or al, 00000010b
.zero_bit:
    out dx, al
    or al, 00000100b
    out dx, al
    dec cx
    jns .cmd_loop

    mov al, 10001000b
    out dx, al
    mov cl, 0xf
.read_loop:
    shl ebx, 1
    mov al, 10001100b
    out dx, al
    in al, dx     
    and al, 00000001b
    jz .dont_set
    inc ebx
.dont_set:
    mov al, 10001000b
    out dx, al
    dec cl
    jns .read_loop
    xor al, al
    out dx, al
    mov ax, bx


    ; for test
    ret
    mov edx, NC_IO_ADDR + RTL8139_REG_RXCONFIG
    in al, dx
    push ecx
    push ebx
    push eax
    mov ch, 0x03
    add cl, 10
    mov bh, cl
    mov bl, 0
    int 0x81
    pop eax
    pop ebx
    pop ecx
 
    ret
