main:
(__TEXT,__text) section
start:
00001c40	pushl	$0x00
00001c42	movl	%esp,%ebp
00001c44	andl	$0xf0,%esp
00001c47	subl	$0x10,%esp
00001c4a	movl	0x04(%ebp),%ebx
00001c4d	movl	%ebx,(%esp)
00001c50	leal	0x08(%ebp),%ecx
00001c53	movl	%ecx,0x04(%esp)
00001c57	addl	$0x01,%ebx
00001c5a	shll	$0x02,%ebx
00001c5d	addl	%ecx,%ebx
00001c5f	movl	%ebx,0x08(%esp)
00001c63	movl	(%ebx),%eax
00001c65	addl	$0x04,%ebx
00001c68	testl	%eax,%eax
00001c6a	jne	0x00001c63
00001c6c	movl	%ebx,0x0c(%esp)
00001c70	calll	0x00001c80
00001c75	movl	%eax,(%esp)
00001c78	calll	0x00001f46
00001c7d	hlt
00001c7e	nop
00001c7f	nop
_main:
00001c80	pushl	%ebp
00001c81	movl	%esp,%ebp
00001c83	subl	$0x08,%esp
00001c86	calll	0x00001ca0
00001c8b	movl	$0x00000001,0xf8(%ebp)
00001c92	movl	0xf8(%ebp),%eax
00001c95	movl	%eax,0xfc(%ebp)
00001c98	movl	0xfc(%ebp),%eax
00001c9b	addl	$0x08,%esp
00001c9e	popl	%ebp
00001c9f	ret
_getOneValidDevice:
00001ca0	pushl	%ebp
00001ca1	movl	%esp,%ebp
00001ca3	subl	$0x54,%esp
00001ca6	calll	0x00001cab
00001cab	popl	%eax
00001cac	movl	$0x00000000,0xcc(%ebp)
00001cb3	movl	$0x00000000,0xd4(%ebp)
00001cba	movl	%eax,0xac(%ebp)
00001cbd	jmp	0x00001ead
00001cc2	movl	$0x00000000,0xd0(%ebp)
00001cc9	jmp	0x00001e98
00001cce	movl	$0x00000000,0xcc(%ebp)
00001cd5	jmp	0x00001e83
00001cda	movl	0xd4(%ebp),%eax
00001cdd	shll	$0x10,%eax
00001ce0	movl	0xd0(%ebp),%ecx
00001ce3	shll	$0x0b,%ecx
00001ce6	orl	%ecx,%eax
00001ce8	movl	0xcc(%ebp),%ecx
00001ceb	shll	$0x08,%ecx
00001cee	orl	%ecx,%eax
00001cf0	orl	$0x80000000,%eax
00001cf5	movl	%eax,0xc4(%ebp)
00001cf8	movl	0xc4(%ebp),%eax
00001cfb	movl	$0x00000cf8,%ecx
00001d00	movl	%ecx,%edx
00001d02	outl	%eax,%dx
00001d03	movl	$0x00000cfc,%eax
00001d08	movl	%eax,%edx
00001d0a	inl	%dx,%eax
00001d0b	movl	%eax,0xbc(%ebp)
00001d0e	movl	0xbc(%ebp),%eax
00001d11	movl	%eax,0xdc(%ebp)
00001d14	movl	0xdc(%ebp),%eax
00001d17	movw	%ax,0xc8(%ebp)
00001d1b	movw	0xc8(%ebp),%ax
00001d1f	movw	%ax,0xda(%ebp)
00001d23	movw	0xc8(%ebp),%ax
00001d27	cmpw	$0xff,%ax
00001d2b	je	0x00001e7a
00001d31	movl	0xd4(%ebp),%eax
00001d34	shll	$0x10,%eax
00001d37	movl	0xd0(%ebp),%ecx
00001d3a	shll	$0x0b,%ecx
00001d3d	orl	%ecx,%eax
00001d3f	movl	0xcc(%ebp),%ecx
00001d42	shll	$0x08,%ecx
00001d45	orl	%ecx,%eax
00001d47	orl	$0x80000000,%eax
00001d4c	movl	%eax,0xc4(%ebp)
00001d4f	movl	0xc4(%ebp),%eax
00001d52	movl	$0x00000cf8,%ecx
00001d57	movl	%ecx,%edx
00001d59	outl	%eax,%dx
00001d5a	movl	$0x00000cfc,%eax
00001d5f	movl	%eax,%edx
00001d61	inl	%dx,%eax
00001d62	movl	%eax,0xb8(%ebp)
00001d65	movl	0xb8(%ebp),%eax
00001d68	movl	%eax,0xe4(%ebp)
00001d6b	movl	0xe4(%ebp),%eax
00001d6e	shrl	$0x10,%eax
00001d71	movw	%ax,0xca(%ebp)
00001d75	movw	0xca(%ebp),%ax
00001d79	movw	%ax,0xe2(%ebp)
00001d7d	movl	0xd4(%ebp),%eax
00001d80	shll	$0x10,%eax
00001d83	movl	0xd0(%ebp),%ecx
00001d86	shll	$0x0b,%ecx
00001d89	orl	%ecx,%eax
00001d8b	movl	0xcc(%ebp),%ecx
00001d8e	shll	$0x08,%ecx
00001d91	orl	%ecx,%eax
00001d93	orl	$0x80000008,%eax
00001d98	movl	%eax,0xc4(%ebp)
00001d9b	movl	0xc4(%ebp),%eax
00001d9e	movl	$0x00000cf8,%ecx
00001da3	movl	%ecx,%edx
00001da5	outl	%eax,%dx
00001da6	movl	$0x00000cfc,%eax
00001dab	movl	%eax,%edx
00001dad	inl	%dx,%eax
00001dae	movl	%eax,0xb4(%ebp)
00001db1	movl	0xb4(%ebp),%eax
00001db4	movl	%eax,0xec(%ebp)
00001db7	movl	0xec(%ebp),%eax
00001dba	movw	%ax,0xc2(%ebp)
00001dbe	movw	0xc2(%ebp),%ax
00001dc2	movw	%ax,0xea(%ebp)
00001dc6	movl	0xd4(%ebp),%eax
00001dc9	shll	$0x10,%eax
00001dcc	movl	0xd0(%ebp),%ecx
00001dcf	shll	$0x0b,%ecx
00001dd2	orl	%ecx,%eax
00001dd4	movl	0xcc(%ebp),%ecx
00001dd7	shll	$0x08,%ecx
00001dda	orl	%ecx,%eax
00001ddc	orl	$0x80000008,%eax
00001de1	movl	%eax,0xc4(%ebp)
00001de4	movl	0xc4(%ebp),%eax
00001de7	movl	$0x00000cf8,%ecx
00001dec	movl	%ecx,%edx
00001dee	outl	%eax,%dx
00001def	movl	$0x00000cfc,%eax
00001df4	movl	%eax,%edx
00001df6	inl	%dx,%eax
00001df7	movl	%eax,0xb0(%ebp)
00001dfa	movl	0xb0(%ebp),%eax
00001dfd	movl	%eax,0xf4(%ebp)
00001e00	movl	0xf4(%ebp),%eax
00001e03	shrl	$0x10,%eax
00001e06	movw	%ax,0xc0(%ebp)
00001e0a	movw	0xc0(%ebp),%ax
00001e0e	movw	%ax,0xf2(%ebp)
00001e12	movw	0xc2(%ebp),%ax
00001e16	cmpw	$0x10,%ax
00001e1a	jne	0x00001e7a
00001e1c	movw	0xc0(%ebp),%ax
00001e20	movzwl	%ax,%eax
00001e23	andl	$0x000000ff,%eax
00001e28	cmpl	$0x00,%eax
00001e2b	jne	0x00001e7a
00001e2d	movl	0xd4(%ebp),%eax
00001e30	movw	%ax,%dx
00001e33	int	$0x82
00001e35	movl	0xd0(%ebp),%eax
00001e38	movw	%ax,%dx
00001e3b	int	$0x82
00001e3d	movl	0xcc(%ebp),%eax
00001e40	movw	%ax,%dx
00001e43	int	$0x82
00001e45	movw	0xca(%ebp),%ax
00001e49	movw	%ax,%dx
00001e4c	int	$0x82
00001e4e	movw	0xc8(%ebp),%ax
00001e52	movw	%ax,%dx
00001e55	int	$0x82
00001e57	movw	0xc2(%ebp),%ax
00001e5b	movw	%ax,%dx
00001e5e	int	$0x82
00001e60	movw	0xc0(%ebp),%ax
00001e64	movw	%ax,%dx
00001e67	int	$0x82
00001e69	int	$0x83
00001e6b	movl	0xac(%ebp),%eax
00001e6e	leal	0x000002b9(%eax),%ecx
00001e74	movl	%ecx,%edx
00001e76	int	$0x84
00001e78	int	$0x83
00001e7a	movl	0xcc(%ebp),%eax
00001e7d	addl	$0x01,%eax
00001e80	movl	%eax,0xcc(%ebp)
00001e83	movl	0xcc(%ebp),%eax
00001e86	cmpl	$0x07,%eax
00001e89	jbe	0x00001cda
00001e8f	movl	0xd0(%ebp),%eax
00001e92	addl	$0x01,%eax
00001e95	movl	%eax,0xd0(%ebp)
00001e98	movl	0xd0(%ebp),%eax
00001e9b	cmpl	$0x1f,%eax
00001e9e	jbe	0x00001cce
00001ea4	movl	0xd4(%ebp),%eax
00001ea7	addl	$0x01,%eax
00001eaa	movl	%eax,0xd4(%ebp)
00001ead	movl	0xd4(%ebp),%eax
00001eb0	cmpl	$0x000000ff,%eax
00001eb5	jbe	0x00001cc2
00001ebb	movl	0xac(%ebp),%eax
00001ebe	leal	0x000002d1(%eax),%ecx
00001ec4	movl	%ecx,%edx
00001ec6	int	$0x84
00001ec8	int	$0x83
00001eca	movl	$0x00000000,0xf8(%ebp)
00001ed1	movl	0xf8(%ebp),%ecx
00001ed4	movl	%ecx,0xfc(%ebp)
00001ed7	movl	0xfc(%ebp),%eax
00001eda	movzwl	%ax,%eax
00001edd	addl	$0x54,%esp
00001ee0	popl	%ebp
00001ee1	ret
00001ee2	nop
00001ee3	nop
00001ee4	nop
00001ee5	nop
00001ee6	nop
00001ee7	nop
00001ee8	nop
00001ee9	nop
00001eea	nop
00001eeb	nop
00001eec	nop
00001eed	nop
00001eee	nop
00001eef	nop
_memcpy:
00001ef0	pushl	%ebp
00001ef1	movl	%esp,%ebp
00001ef3	subl	$0x1c,%esp
00001ef6	movl	0x10(%ebp),%eax
00001ef9	movl	0x0c(%ebp),%ecx
00001efc	movl	0x08(%ebp),%edx
00001eff	movl	%edx,0xfc(%ebp)
00001f02	movl	%ecx,0xf8(%ebp)
00001f05	movl	%eax,0xf4(%ebp)
00001f08	movl	0xfc(%ebp),%eax
00001f0b	movl	%eax,0xe8(%ebp)
00001f0e	movl	0xf8(%ebp),%eax
00001f11	movl	%eax,0xe4(%ebp)
00001f14	jmp	0x00001f20
00001f16	movl	0xe4(%ebp),%eax
00001f19	movb	(%eax),%al
00001f1b	movl	0xe8(%ebp),%ecx
00001f1e	movb	%al,(%ecx)
00001f20	movl	0xf4(%ebp),%eax
00001f23	subl	$0x01,%eax
00001f26	movl	%eax,0xf4(%ebp)
00001f29	movl	0xf4(%ebp),%eax
00001f2c	cmpl	$0xff,%eax
00001f2f	jne	0x00001f16
00001f31	movl	0xfc(%ebp),%eax
00001f34	movl	%eax,0xec(%ebp)
00001f37	movl	0xec(%ebp),%eax
00001f3a	movl	%eax,0xf0(%ebp)
00001f3d	movl	0xf0(%ebp),%eax
00001f40	addl	$0x1c,%esp
00001f43	popl	%ebp
00001f44	ret
