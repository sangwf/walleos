void *memcpy(void *dest, const void *src, unsigned int count)
{
	char *tmp = dest;
	const char *s = src;
	while (count--)
	  *tmp = *s ;
	return dest;
}
