#include<mach-o/loader.h>
#include<stdio.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>

#define FILE_ERROR(fd, format, err) { close(fd); printf(format, err); }

int main(int argc, char* argv[])
{
	int fd = -1;
	struct mach_header head;
	int ret = -1;
	struct load_command cmd;
	int i = 0;
	struct segment_command seg_cmd;
	struct section sect;
	int isect = 0;
	int f_pos = 0;
	char buf[102400];
	int ibuf = 0;
	int fd_out = -1;

	if(argc != 2) {
		printf("use: %s [mach-o filename]\n", argv[0]);
		return -1;
	}

	fd = open(argv[1], O_RDONLY);
	if(fd < 0) {
		printf("open file failed\n");
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

	printf("Commands: LC_UUID(%d) LC_SEGMENT(%d) LC_SEGMENT_64(%d) \n", 
		LC_UUID, LC_SEGMENT,LC_SEGMENT_64);

	printf("sizeof(segment_command): %lu \n", sizeof(struct segment_command));
	printf("sizeof(segment_command_64): %lu \n", sizeof(struct segment_command_64));

	for(i=0; i<head.ncmds; i++) {
		ret = read(fd, &cmd, sizeof(cmd));
		if(ret != sizeof(cmd)) {
			FILE_ERROR(fd, "read[%d] cmd failed\n", i);
			return -1;
		}
		printf("NO: %d cmd:%d cmdsize:%d \n",i, cmd.cmd, cmd.cmdsize);
		if(cmd.cmd == LC_SEGMENT) {
			lseek(fd, -sizeof(cmd), SEEK_CUR);
			ret = read(fd, &seg_cmd, sizeof(seg_cmd));
			if(ret != sizeof(seg_cmd)) {
				FILE_ERROR(fd, "%s", "read seg cmd failed\n");
				return -1;
			}
			printf("segname: %s nsects: %u\n", 
				seg_cmd.segname, seg_cmd.nsects);
			for(isect=0; isect<seg_cmd.nsects; isect++) {
				ret = read(fd, &sect, sizeof(sect));
				if(ret != sizeof(sect)) {
					FILE_ERROR(fd, "read section[%d] failed\n", isect);
					return -1;
				}
				printf("SECT NO: %d sectname: %s segname: %s addr: %x size: %u offset: %d reloff: %d nreloc: %d\n", 
					isect, sect.sectname, sect.segname, sect.addr, sect.size, sect.offset, sect.reloff, sect.nreloc);
				
				//load section data
				f_pos = lseek(fd, 0, SEEK_CUR);
				lseek(fd, sect.offset, SEEK_SET);
				ret = read(fd, buf, sect.size);
				if(ret != sect.size) {
					FILE_ERROR(fd, "read section[%d]'data failed\n", isect);
					return -1;
				}

				fd_out = open(sect.sectname, O_CREAT|O_TRUNC|O_WRONLY);
				if(fd_out<0) {
					FILE_ERROR(fd, "create %s file failed.\n", sect.sectname);
					return -1;
				}
				write(fd_out, buf, sect.size);
				close(fd_out);
				
				for(ibuf=0; ibuf<sect.size; ibuf++) {
					printf("%02x ", (unsigned char)buf[ibuf]);
				}	
				printf("\n");				

				lseek(fd, f_pos, SEEK_SET);		
			} 
		} else {
			lseek(fd, cmd.cmdsize, SEEK_CUR);
		}

	}

	close(fd);
	fd = -1;
	return 0;
}
