section .init
	; crtend.o's .init section
	pop ebp
	ret

section .fini
	; crtend.o's .fini section
	pop ebp
	ret