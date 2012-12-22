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

#define print_return() ({ \
__asm__ volatile ("int $0x83"::); \
})



#define PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, offset, address, value) \
({ \
address = (unsigned long)((lbus << 16) | (lslot << 11) | \
                         (lfunc << 8) | (offset & 0xfc) | ((unsigned int)0x80000000));  \
outd(0xCF8, address); \
value = (unsigned short)((ind(0xCFC) >> ((offset & 2) * 8)) & 0xffff); \
}) 
 


unsigned short pci_config_read_word(unsigned short bus, unsigned short slot,
					unsigned short func, unsigned short offset);

unsigned short pciGetDeviceAndVendor(unsigned short bus, unsigned short slot
				, unsigned short* p_device);
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
	
	for(lbus =0; lbus < 256; lbus++) {
		for(lslot = 0; lslot < 32; lslot++) {
			PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 0, address, vendor);	
			/*vendor = pciConfigReadWord(bus, slot, 0, 0);*/
			if(vendor != 0xFFFF) {
				/* device = pciConfigReadWord(bus, slot, 0, 2); */
				PCI_CONFIG_READ_WORD(lbus, lslot, lfunc, 2, address, device);	
				print_short((unsigned short)lbus);
				print_short((unsigned short)lslot);
				print_short((unsigned short)lfunc);
				print_short(device);
				print_short(vendor);
				print_return();
				/* return vendor; */
			}
		}
	}
	
	return 0;
}


/*
func: check pci vendor
*/
__inline__ __attribute__((always_inline)) unsigned short pciGetDeviceAndVendor(unsigned short bus, unsigned short slot
				, unsigned short* p_device)
{
    unsigned short vendor;
    /* try and read the first configuration register. Since there are no */
    /* vendors that == 0xFFFF, it must be a non-existent device. */
    if ((vendor = pciConfigReadWord(bus,slot,0,0)) != 0xFFFF) {
       *p_device = pciConfigReadWord(bus,slot,0,2);
    } 

    return (vendor);
}

/* 
func: read pci config info
*/
__inline__ __attribute__((always_inline)) unsigned short pci_config_read_word(unsigned short bus, unsigned short slot,
					unsigned short func, unsigned short offset)
{
	unsigned long address;
	unsigned long lbus = (unsigned long)bus;
	unsigned long lslot = (unsigned long)slot;
	unsigned long lfunc = (unsigned long)func;
	unsigned short tmp = 0;

	/* create configuration address */
	/* | ((unsigned int)0x80000000)) - for set bit-31 to the value of 1*/
	address = (unsigned long)((lbus << 16) | (lslot << 11) |
			(lfunc << 8) | (offset & 0xfc) | ((unsigned int)0x80000000));

	/* write out the address */
	outd(0xCF8, address);
	/* read in the data */
	/* ((offset & 2) * 8) = 0 will choose the first word of the 32 bits register */
	tmp = (unsigned short)((ind(0xCFC) >> ((offset & 2) * 8)) & 0xffff);
	return (tmp);
}

