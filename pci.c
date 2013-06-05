#define ind(port) ({ \
unsigned long _v; \
__asm__ volatile ("in %%dx, %%eax":"=a" (_v):"d" (port)); \
_v; \
})

#define outd(port, value) ({ \
__asm__ volatile ("out %%eax, %%dx"::"d" (port), "a" (value) ); \
})

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

#define hlt() ({ \
__asm__ volatile ("hlt"::); \
})



#define PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, offset, address, value) \
({ \
address = (unsigned long)((lbus << 16) | (lslot << 11) | \
                         (lfunc << 8) | (offset & 0xfc) | ((unsigned int)0x80000000));  \
outd(0xCF8, address); \
value = (unsigned short)((ind(0xCFC) >> ((offset & 2) * 8)) & 0xffff); \
}) 

#define PCI_CONFIG_READ_DWORD(lbus, lslot, lfunc, offset, address, value) \
({ \
address = (unsigned long)((lbus << 16) | (lslot << 11) | \
                         (lfunc << 8) | (offset & 0xfc) | ((unsigned int)0x80000000));  \
outd(0xCF8, address); \
value = ind(0xCFC); \
}) 

#define PCI_CONFIG_WRITE_DWORD(lbus, lslot, lfunc, offset, address, value) \
({ \
address = (unsigned long)((lbus << 16) | (lslot << 11) | \
                         (lfunc << 8) | (offset & 0xfc) | ((unsigned int)0x80000000));  \
outd(0xCF8, address); \
outd(0xCFC, value); \
}) 


/*
func: get a valid device
*/
unsigned short getOneValidDevice(void)
{
	unsigned long lbus;
	unsigned long lslot;
	unsigned long lfunc = 0;
	unsigned short device;
	unsigned short vendor;
	unsigned long address;
	unsigned short class_sub;
	unsigned short progif_rev;
	unsigned short pin_line;
	unsigned long base_address;
	unsigned short cmd;
	unsigned short status;

	print_string(" DEVICE  VENDOR  CMD     STATUS CLASS|SUB PROGIF|REV PIN|LINE BASE_ADDR");
	print_return();

	for (lbus =0; lbus < 256; lbus++) {
		for (lslot = 0; lslot < 32; lslot++) {
			for (lfunc = 0; lfunc < 8; lfunc++) {
				PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x00, address, vendor);	
				/*vendor = pciConfigReadWord(bus, slot, 0, 0);*/
				if(vendor != 0xFFFF) {
					/* device = pciConfigReadWord(bus, slot, 0, 2); */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x02, address, device);	
					/* Class code|subclass */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x0a, address, class_sub);	
					/* Command */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x04, address, cmd);	
					/* Status */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x06, address, status);	
					/* Prog IF| Revision ID */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x08, address, progif_rev);	
					/* Interrupt PIN | Interrupt Line */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x3c, address, pin_line);
					/* base address #0 */
					PCI_CONFIG_READ_DWORD(lbus, lslot, lfunc, 0x10, address, base_address);
	
					// netcard
					if ((device == 0x2000)&&(vendor == 0x1022)) {
						print_short(device);
						print_short(vendor);
						print_short(cmd);
						print_short(status);
						print_short(class_sub);
						print_short(progif_rev);
						print_short(pin_line);
						print_long(base_address & 0xFFFFFFFC);
						print_return();

						// enable netcard, (0x0005) for IO Space
						// PCI_CONFIG_WRITE_DWORD(lbus, lslot, lfunc, 0x04, address, 0x00000001);	
						// PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x04, address, cmd);	
						// print_short(cmd);
						// print_return();
						
						// PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0x06, address, status);	
						// print_short(status);
						// print_return();
					}
					/* return vendor; */
					}
				}
			}
		}
		print_return();
		// print_string(" Today is 20130526, I'm coding for NetCard.");
	    // print_return();

		//hlt();
		return 0;
	}
