section .init
global _init
_init:
	push ebp
	mov ebp, esp
	; crtbegin.o's .init section

section .fini
global _fini
_fini:
	push ebp
	mov ebp, esp
	; crtbegin.o's .fini section