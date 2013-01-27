#include<mach-o/loader.h>
#include<stdio.h>
#include<stdlib.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>
#include <errno.h> 

#define FILE_ERROR(fd, fmt, err...) { close(fd); printf(fmt, ##err); }

struct my_nlist
{
		int32_t n_strx;
		uint8_t n_type;
		uint8_t n_sect;
		int16_t n_desc;
		uint32_t n_value;
};

int main(int argc, char* argv[])
{
	int fd = -1;
	int fd_head = -1;
	struct mach_header head;
	int ret = -1;
	struct load_command cmd;
	int i = 0;
	struct segment_command seg_cmd;
	struct section sect;
	struct symtab_command sym_cmd;
	struct my_nlist sym_nlist;
	int isect = 0;
	int f_pos = 0;
	char buf[102400];
	int ibuf = 0;
	int fd_out = -1;
	int head_size = -1;
	char system_image[102400]; // 100K
	int i_nsyms = 0;
	unsigned int start_address = 0;

	if (argc != 3) {
		printf("Use: %s [head.s filename] [mach-o filename]\n", argv[0]);
		return -1;
	}
	// deal system file
	fd = open(argv[2], O_RDONLY);
	if(fd < 0) {
		printf("open system file failed\n");
		return -1;
	}

	ret = read(fd, &head, sizeof(head));
	if(ret != sizeof(head)) {
		FILE_ERROR(fd, "%s", "read file failed\n");
		return -1;
	}

	printf("head info: magic(%x) filetype(%d) ncmds(%d) sizeofcmds(%d) flags(%x)\n", 
		head.magic, head.filetype, head.ncmds, head.sizeofcmds, head.flags);

	if(head.magic != MH_MAGIC) {
		FILE_ERROR(fd, "%s", "[ERROR] This program just supports 32-bit mach-o file, please use [gcc -m32] for compile.\n");
		return -1;
	}

//	printf("Commands: LC_UUID(%d) LC_SEGMENT(%d) LC_SEGMENT_64(%d) \n", 
//		LC_UUID, LC_SEGMENT,LC_SEGMENT_64);

//	printf("sizeof(segment_command): %lu \n", sizeof(struct segment_command));
//	printf("sizeof(segment_command_64): %lu \n", sizeof(struct segment_command_64));

	for(i=0; i<head.ncmds; i++) {
		ret = read(fd, &cmd, sizeof(cmd));
		if(ret != sizeof(cmd)) {
			printf("read[%d] cmd failed\n", i);
			break; //__LINK_EDIT command may be error;
		}

		//往回退一个cmd的空间
		lseek(fd, -sizeof(cmd), SEEK_CUR);
		printf("\nNO: %d cmd:%d cmdsize:%d \n",i, cmd.cmd, cmd.cmdsize);
		if(cmd.cmd == LC_SEGMENT) {
			ret = read(fd, &seg_cmd, sizeof(seg_cmd));
			if(ret != sizeof(seg_cmd)) {
				FILE_ERROR(fd, "%s", "read seg cmd failed\n");
				return -1;
			}
			printf("segname: %s nsects: %u\n", 
				seg_cmd.segname, seg_cmd.nsects);
			for (isect = 1; isect <= seg_cmd.nsects; isect++) {
				ret = read(fd, &sect, sizeof(sect));
				if (ret != sizeof(sect)) {
					FILE_ERROR(fd, "read section[%d] failed\n", isect);
					return -1;
				}
				printf("SECT NO: %d sectname: %s segname: %s addr: %x size: %u offset: %d reloff: %d nreloc: %d\n", 
					isect, sect.sectname, sect.segname, sect.addr, sect.size, sect.offset, sect.reloff, sect.nreloc);
				
				if (strcmp(sect.sectname, "__text") == 0) {
					//find main address
					start_address = sect.addr + 0x40;
					printf("Program Start Address: %x\n", start_address);
				}

				//load section data
				f_pos = lseek(fd, 0, SEEK_CUR);
				lseek(fd, sect.offset, SEEK_SET);
				//直接映射到内存中
				ret = read(fd, system_image+sect.addr, sect.size);
				if(ret != sect.size) {
					FILE_ERROR(fd, "read section[%d]'data failed\n", isect);
					return -1;
				}

				lseek(fd, f_pos, SEEK_SET);		
			} 
		} else if (cmd.cmd == LC_SYMTAB) {
			//这一个分支对于直接解析执行文件时，是没用的。
			//deal symtab command
			ret = read(fd, &sym_cmd, sizeof(sym_cmd));
			if(ret != sizeof(sym_cmd)) {
				FILE_ERROR(fd, "%s", "read symtab cmd failed\n");
				return -1;
			}
			printf("symoff: %u, nsyms: %u stroff: %u strsize: %u\n", 
						sym_cmd.symoff, sym_cmd.nsyms, sym_cmd.stroff, sym_cmd.strsize);

			// get string table
			f_pos = lseek(fd, 0, SEEK_CUR);
			lseek(fd, sym_cmd.stroff, SEEK_SET);
			ret = read(fd, &buf, sym_cmd.strsize);
			if (ret != sym_cmd.strsize) {
				FILE_ERROR(fd, "read string table failed\n");
				return -1;
			}

			lseek(fd, f_pos, SEEK_SET);		
			//print symtable
			f_pos = lseek(fd, 0, SEEK_CUR);
			lseek(fd, sym_cmd.symoff, SEEK_SET);
			printf("n_strx  string  n_type n_sect n_desc n_value\n");
			for (i_nsyms = 0; i_nsyms < sym_cmd.nsyms; i_nsyms++) {
				ret = read(fd, &sym_nlist, sizeof(sym_nlist));
				if (ret != sizeof(sym_nlist)) {
					FILE_ERROR(fd, "read nlist[%d] failed\n", i_nsyms);
					return -1;
				}

				printf("%-4d %-25s %4x %2u %10d %10u\n",
							sym_nlist.n_strx, buf+sym_nlist.n_strx, sym_nlist.n_type,
							sym_nlist.n_sect, sym_nlist.n_desc,
							sym_nlist.n_desc);

			}
			
			lseek(fd, f_pos, SEEK_SET);		

		} else {
			lseek(fd, cmd.cmdsize, SEEK_CUR);
		}

	}

	close(fd);
	fd = -1;

	// compile head.s with start_address
	snprintf(buf, sizeof(buf), "/usr/bin/nasm -DC_ENTER=0x%x -fbin %s -ohead.bin",
				start_address, argv[1]);
	printf("system: %s \n", buf);
	ret = system(buf);
	if (ret < 0) {
		printf("system: failed ret(%d)\n", ret); 
		return -1;
	}

	// load head.bin to memory and get the head size
	fd_head = open("head.bin", O_RDONLY);
	if (fd_head < 0) {
		printf("open head file failed\n");
		return -1;
	}

	head_size = read(fd_head, system_image, sizeof(system_image));
	if (head_size <= 0) {
		FILE_ERROR(fd_head, "read head.bin failed(%d)\n", head_size);
		return -1;
	}


	//write to system.bin
	fd_out = open("system.bin", O_CREAT|O_TRUNC|O_WRONLY, 00700);
	if(fd_out<0) {
		FILE_ERROR(fd, "create system.bin failed.\n");
		close(fd_out);
		return -1;
	}
	write(fd_out, system_image, sizeof(system_image));
	close(fd_out);

	return 0;
}
