#define ind(port) ({ \
unsigned long _v; \
__asm__ volatile ("in %%dx, %%eax":"=a" (_v):"d" (port)); \
_v; \
})

#define outd(port, addr) ({ \
__asm__ volatile ("out %%eax, %%dx"::"d" (port), "a" (addr) ); \
})

#define print_short(value) ({ \
__asm__ volatile ("int $0x82"::"d" (value) ); \
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

	for (lbus =0; lbus < 256; lbus++) {
		for (lslot = 0; lslot < 32; lslot++) {
			for (lfunc = 0; lfunc < 8; lfunc++) {
				PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0, address, vendor);	
				/*vendor = pciConfigReadWord(bus, slot, 0, 0);*/
				if(vendor != 0xFFFF) {
					/* device = pciConfigReadWord(bus, slot, 0, 2); */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 2, address, device);	
					/* Class code|subclass */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 8, address, class_sub);	
					/* Prog IF| Revision ID */
					PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 10, address, progif_rev);	
					/* filter for network card: class code = 0x10 && sub class = 0x00 */
					if ((class_sub == 0x0010)&&((progif_rev&0x00FF)==0x00000)) {
						//if ((class_sub == 0x0010)) {
						print_short((unsigned short)lbus);
						print_short((unsigned short)lslot);
						print_short((unsigned short)lfunc);
						print_short(device);
						print_short(vendor);
						print_short(class_sub);
						print_short(progif_rev);
						print_return();
						print_string("--this is the net card!");
						print_return();
					}
					/* return vendor; */
					}
				}
			}
		}
		print_string("today is 20130126, I can print string in C code.");
		print_return();

		return 0;
	}
