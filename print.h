#ifndef _PRINT_H
#define _PRINT_H

#define print_short(value) ({ \
__asm__ volatile ("int $0x82"::"d" (value) ); \
})

#define print_long(value) ({ \
__asm__ volatile ("int $0x85"::"d" (value) ); \
})


#define print_string(address) ({ \
__asm__ volatile ("int $0x84"::"d" (address) ); \
})


#define print_return() ({ \
__asm__ volatile ("int $0x83"::); \
})

#endif // _PRINT_H


