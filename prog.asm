dane1 segment
dane1 ends

		.387
code1 segment

start1:
	;inicjalizacja stosu
	mov 	ax,seg stack1 ; przenieś adres segmentu stack1 do ax ;; seg - daje adres segmentowy z nazwy symbolicznej
	mov		ss,ax
	mov 	sp, offset pstack1
	
	mov		ax, seg lin_c
	mov		es,ax
	mov		si,082h
	mov		di,offset lin_c
	
	xor		cx, cx
	mov		cl, byte ptr ds:[080h] ; cx = ilosc znaków
	
	cmp		cl, 0
	je		dafault


parse1: push cx
	
	mov		al, byte ptr ds:[si] 		; do al przesuń początek si
	mov		byte ptr es:[di], al		; do di, przenieść al
	inc 	si							; przesuń si
	inc 	di							; przesuń di
	pop cx								; zdejmij cx ze stosu
	loop parse1							; pętla do parse1 , cx -= 1, if cx <> 0 
	dec 	di							; zdeinkrementuj di
	mov		byte ptr es:[di], '$'		; na koniec di wstaw znak $ 

	mov		si, offset lin_c			; do si wczytaj offset lin_c

	mov		cx, 20						; do cx wrzuć 20, (ile spacji chcemy maksymalnie pominąć)
	cld									; resetujemy flage direction flag
	push ax								; odkładamy ax, bx, cx na stos
	push bx
	push cx
	mov		di, si						; przesuwam do di, si
	mov		al, ' '						; do al wrzucam znak który chce pomijać
	repz 	scasb						; dopóki wartość w rejestrze di równa się wartości w rejestrze al (spacji) i cx <> 0 zwiększaj di, cx -= 1
	dec		di							; cofnij di o jedna pozycje
	mov		si, di						; przesun di do si
	pop ax								;zdejmij ze stosu ax, bx, cx
	pop bx
	pop cx
	
									
	xor 	ax, ax						;wyzeruj ax
	xor 	bx, bx						; wyzeruj bx
	mov		cx, 10						; do cx przesun 10 będzie to mnożnik pomocny przy wczytywaniu naszych liczb z wejścia
	mov		bl, byte ptr cs:[si]		; przesuń jeden znak si do bl



load_first_num:
	sub		bl, '0' 					; od znaku wczytanego do bl odejmij wartość znaku '0' aby w rejestrze bx uzykac wartosc wczytanej cyfry
	cmp		bl, 10						; sprawdz czy podany znak jest cyfrą
	jge		error						
	cmp		bl, 0						; sprawdz czy podany znak jest cyfrą
	jl		error
	add		ax, bx						; dodaj do ax policzoną cyfre
	inc		si						
	mov		bl, byte ptr cs:[si]		; przesun kolejny znak do bl
	cmp		bl, ' '						; sprawdz czy jest spacją
	je		end_first_load				; jeśli tak to koniec pierwszej liczby
	mul 	cx
	jmp 	load_first_num			; jesli nie koniec pomnóż liczbe przez 10 aby przesunąć wszystkie cyfry w lewo 

end_first_load:
	
										; podziel wczytaną długosć średnicy na dwa żeby obliczyć promień
	mov		bx, 2						
	div		bx
	xor 	ah, ah
	mov		word ptr cs:[rx], ax 		; zapisz wartosć promienia x
	cmp		ax, 100						; sprawdzam czy podany wynik nie jest zbyt duży 
	jg		error
	inc		si
	
skip_spaces:
										; pomijamy kolejne spacje pomiedzy cyframi takim samym sposobem jak wcześniej
	push ax
	push bx
	push cx
	mov		cx, 20
	mov		di, si
	mov		al, ' '
	repz 	scasb
	dec		di
	mov		si, di
	pop ax
	pop bx
	pop cx

	
prepare_to_load_second:
										; zerujemy wartosci wszystkich rejestrów i ponownie tak jak przy pierwszej liczby wczytujemy drugą zapisując ją jako ry
	xor 	ax, ax
	xor	 	bx, bx
	xor		cx, cx
	mov 	cx, 10
	mov		bl, byte ptr cs:[si]

load_second_num:
	sub 	bl, '0'
	cmp		bl, 10
	jge		error
	cmp		bl, 0
	jl		error
	add		ax, bx
	inc		si
	mov		bl, byte ptr cs:[si]
	cmp		bl, '$'
	je		end_second_load
	mul		cx
	
	jmp		load_second_num

	
end_second_load:

	mov		bx, 2
	div		bx
	xor 	ah, ah
	mov		word ptr cs:[ry], ax
	cmp		ax, 100
	jg		error

jmp		change_to_graphic_mode

dafault:
	mov		word ptr cs:[rx], 50
	mov		word ptr cs:[ry], 50
	
change_to_graphic_mode:
	xor 	ax, ax
	mov		al, 13h; tryb o który mi chodzi (tryb tekstowy to 3 | tryb graficzny 13h 320x200 256 kolorow)
	mov		ah, 0 ; zmien tryb graficzny
	int 	10h
	
	
	sub		word ptr cs:[ry], 1
	sub		word ptr cs:[rx], 1
	mov 	word ptr cs:[y_c], 100					;ustaw środek elipsy
	mov 	word ptr cs:[x_c], 160					;ustaw środek elipsy
	mov 	byte ptr cs:[k], 12						;ustaw kolor elipsy
	mov		byte ptr cs:[which_alg], 0				;ustaw algorytm do rysowania elipsy


draw1:
	call 	clr_screen								; wyczysć ekran
	call 	draw_elipse2							; narysuj elipse uzywając równania elipsy 
	jmp		p1										
	
draw2:	
	call 	clr_screen								; wyczysć ekran
	call 	draw_elipse3							; narysuj elipse algorytm brasenhama
	
	
p1:
	in 		al, 60h									; wczytaj wcisnięty przycisk do al
	cmp		al, 1 ; ESC								; jeśli wcisniety był ESC zakoncz program
	jz		exit_p
	
	cmp		al, byte ptr cs:[key1] 					; sprawdz czy wciśniety przycisk jest taki sam jak zapamiętany wczesniej 
	jz 		p1										
	mov		byte ptr cs:[key1], al					
	cmp 	al, 75 ; left							; sprawdz czy kliknięto strzalke w lewo
	jnz 	p2
	
	mov		bx, word ptr cs:[rx]
	cmp		bx, 1
	jle		do_not_dec2
	dec		word ptr cs:[rx]						
do_not_dec2:

p2:
	cmp		al, 77 ; right							; sprawdz czy kliknięto strzalke w prawo
	jnz 	p3
	
	mov		bx, word ptr cs:[rx]
	cmp		bx, 99
	jge		do_not_inc
	inc		word ptr cs:[rx]
do_not_inc:
	
p3:
	cmp		al, 72; up								; sprawdz czy kliknięto strzalke w góre
	jnz 	p4
	mov		bx, word ptr cs:[ry]
	cmp 	bx, 99
	jge		do_not_inc2
	inc		word ptr cs:[ry]
do_not_inc2:

p4:
	cmp		al, 80; down							; sprawdz czy kliknięto strzalke w dół
	jnz 	p5
	
	mov		bx, word ptr cs:[ry]
	cmp 	bx, 1
	jle		do_not_dec
	dec 	word ptr cs:[ry]
	
do_not_dec:

p5:
	cmp		al, 46 ; C								; sprawdz czy kliknięto strzalke w C
	jnz		p6
	cmp		byte ptr cs:[k], 14
	jge		reset_color
	inc		byte ptr cs:[k]
	jmp		p6
	
reset_color:
	mov		byte ptr cs:[k], 6
	
p6:
	cmp		al, 19 ; R							; sprawdz czy kliknięto strzalke w R
	jnz		p7
	
	mov		bl, byte ptr cs:[which_alg]
	cmp		bl, 0
	jne		decrease_alg
	inc		byte ptr cs:[which_alg]
	jmp 	p7
	
decrease_alg:
	dec 	byte ptr cs:[which_alg]
	
p7:
	mov		bl, byte ptr cs:[which_alg]
	cmp		bl, 0
	
	je 		draw1
	
	jmp		draw2
	
exit_p:



	
ending:
	; przywracam tryb tekstowy
	mov		al, 3h; tryb o który mi chodzi (tryb tekstowy to 3 | tryb graficzny 13h 320x200 256 kolorow)
	mov		ah, 0 ; zmien tryb graficzny
	int 	10h

end_program:
	
	mov 	ax,4c00h ; end program
	int 	21h
	

;--------------------------------------------------------
key1		db 		?
lin_c		db 	200 dup('$')
which_alg	db 		?

; input variables
rx 		dt 		?
ry		dt 		?
x_c 	dt		?
y_c 	dt 		?


; function variables

x1 		dt		?
y1		dt 		?

ry_sqr	dt		?
rx_sqr 	dt 		?

d1 		dt		?
d2 		dt		?
dx2 		dt		?
dy 		dt		?


inp_error 	db "Błąd danych wejsciowych!!!$"
usage 		db "Wymagany format %nazwa.exe %srednicax %srednicay$"
usage2		db "Podane wartosci srednic powinny byc z przedzialu (0, 200)$"

;------------------

;------------------

clr_screen:
	mov		ax, 0a000h
	mov		es, ax
	xor 	ax, ax
	mov		di, ax
	cld		;di = di + 1
	mov		cx, 320*200
	rep 	stosb		; byte ptr es:[di],al ; di = di+1 ; while cs <> 0
	
	ret

helper 	dt		?
;-----------



draw_elipse2:
	
	
	mov		word ptr cs:[x1], 0 ; ustaw zmienna x1 = 0
	mov		ax, word ptr cs:[ry] ; ustaw zmienna y1 = ry
	mov		word ptr cs:[y1], ax ; ustaw zmienna y1 = ry
	
	mov		word ptr cs:[d1+2], 0
	mov		word ptr cs:[dx2+2], 0
	mov		word ptr cs:[dy+2], 0
	
	
	; - obliczamy d1 = (ry*ry) - (rx*rx*ry) + 0.25*rx*rx
	finit
	fild	dword ptr cs:[ry]
	fild	dword ptr cs:[ry]
	fmul	
	fild 	dword ptr cs:[rx]
	fild 	dword ptr cs:[rx]
	fmul
	fild 	dword ptr cs:[ry]
	fmul
	fsub

	fild	dword ptr cs:[rx]
	fild	dword ptr cs:[rx]
	fmul	
	mov		word ptr cs:[helper], 4
	fild	dword ptr cs:[helper]
	fdiv	
	fadd
	fist	dword ptr cs:[d1]
	
	; dx = 2 * ry*ry*x
	mov		word ptr cs:[helper], 2
	finit
	fild 	word ptr cs:[helper]
	fild	dword ptr cs:[ry]
	fmul
	fild	dword ptr cs:[ry]
	fmul
	fild	dword ptr cs:[x1]
	fmul
	fist 	dword ptr cs:[dx2]
	
	; dy = 2 * rx*rx*y
	finit
	fild	word ptr cs:[helper]
	fild 	dword ptr cs:[rx]
	fmul
	fild 	dword ptr cs:[rx]
	fmul	
	fild 	dword ptr cs:[y1]
	fmul
	fist 	dword ptr cs:[dy] 			
	
	
l11:
	
	; dx - dy < 0
	finit
	fild		dword ptr cs:[dx2]				; załaduj dx2 
	fild		dword ptr cs:[dy]				; załaduj dy 
	fsub										; wykonaj dx2 - dy
	fist		dword ptr cs:[helper]			; załaduj odpowiedz do helper
	
	fild 		dword ptr cs:[helper]			; załaduj zmienna helper na stos
	fild 		dword ptr cs:[helper]			; załaduj zmienna helper na stos
	fabs										; weź wartosć bezwględną
	fdiv										; podziel wartość w helper przez |helper|
	fist		word ptr cs:[helper]			; zapisz odpowiedz do helper (odpowiedz to -1 lub 1)
	mov			ax, word ptr cs:[helper]		; przenieść wartosć helper do ax i sprawdz warunek
	cmp			ax, 0
	jg			end_check
	

	
	
	call 	switch_on_all_pixel
	
	; d1 < 0
	finit
	fild 	dword ptr cs:[d1] 				; załaduj d1
	fild 	dword ptr cs:[d1] 				; załaduj d1
 	
	fabs ; weź |d1|
	fdiv ; podziel d1/|d1|
	fist	word ptr cs:[helper] 			; zapisz do helper wartość d1/|d1|
	mov		ax, word ptr cs:[helper] 		; przeniesc wartość do ax i porównaj
	cmp		ax, 0							
	jge		else11 							; jeśli d1/|d1| jest wiekszy od zera idz do else11

	

	con11:
		; x += 1
		inc		word ptr cs:[x1]

		; dx = dx + 2 *ry*ry
		finit
		mov		word ptr cs:[helper], 2		
		fild	dword ptr cs:[dx2]
		fild	word ptr cs:[helper]
		fild	dword ptr cs:[ry]
		fmul	
		fild	dword ptr cs:[ry]
		fmul
		fadd
		fist	dword ptr cs:[dx2]
		
		
		;d1 = d1 + dx * ry*ry
		fild 	dword ptr cs:[d1]
		fild	dword ptr cs:[dx2]
		fadd	
		fild	dword ptr cs:[ry]
		fild	dword ptr cs:[ry]
		fmul
		fadd

		fist	dword ptr cs:[d1]
		;ret
		
		jmp l11
	
	else11:
		; x += 1

		inc		word ptr cs:[x1]
		
		; y -= 1

		dec 	word ptr cs:[y1]
		
		; 	dx = dx + 2 * ry*ry
		finit
		mov		word ptr cs:[helper], 2
		fild	dword ptr cs:[dx2]
		fild	word ptr cs:[helper]
		fild	dword ptr cs:[ry]
		fmul	
		fild	dword ptr cs:[ry]
		fmul
		fadd
		mov		word ptr cs:[dx2+2], 0

		fist	dword ptr cs:[dx2]
			
		; dy = dy - 2 * rx*rx
		fild	dword ptr cs:[dy]
		fild	word ptr cs:[helper]
		fild	dword ptr cs:[rx]
		fmul	
		fild	dword ptr cs:[rx]
		fmul
		fsub

		fist	dword ptr cs:[dy]
		
		
		
		;	d1 = d1 + dx - dy + ry*ry
		fild	dword ptr cs:[d1]
		fild	dword ptr cs:[dx2]
		fadd
		fild	dword ptr cs:[dy]
		fsub
		fild	dword ptr cs:[ry]
		fild	dword ptr cs:[ry]
		fmul
		fadd

		fist 	dword ptr cs:[d1]
		
	
		jmp		l11
		
		
	
end_check:
	;ret
	
	; d2 = ry*ry*x*x + rx*rx*(y-1)*(y-1) - rx*rx*ry*ry
	mov		ax, word ptr cs:[y1]
	dec		ax
	mov		word ptr cs:[y1], ax
	
	
	finit
	fild	dword ptr cs:[ry]
	fild	dword ptr cs:[ry]
	fild	dword ptr cs:[x1]
	fild	dword ptr cs:[x1]
	fmul
	fmul
	fmul
	
	fild 	dword ptr cs:[rx]
	fild 	dword ptr cs:[rx]
	fild 	dword ptr cs:[ry]
	fild 	dword ptr cs:[ry]
	fmul
	fmul
	fmul
	fsub
	
	fild	dword ptr cs:[rx]
	fild	dword ptr cs:[rx]
	fild	dword ptr cs:[y1]
	fild	dword ptr cs:[y1]
	
	fmul
	fmul
	fmul
	fadd
	
	fist	dword ptr cs:[d2]
	
	
	mov		ax, word ptr cs:[y1]
	inc		ax
	mov		word ptr cs:[y1], ax
	
	
	
l22:
	
	mov		ax, word ptr cs:[y1]
	cmp		ax, 0
	jl		end_check2
	
	call switch_on_all_pixel


	fild 	dword ptr cs:[d2]
	fild 	dword ptr cs:[d2]
	fabs
	fdiv
	fist	word ptr cs:[helper]
	mov		ax, word ptr cs:[helper]
	cmp		ax, 0
	jl		else22
	
	
	con22:
		; y -= 1
		dec 	word ptr cs:[y1]
		
		
		mov		word ptr cs:[helper], 2
		
		; dy = dy - 2 * rx * rx
		fild	dword ptr cs:[dy]
		fild	dword ptr cs:[rx]
		fild	word ptr cs:[helper]
		fild	dword ptr cs:[rx]
		fmul
		fmul
		fsub

		fist	dword ptr cs:[dy]
		
		; d2 = d2 + rx * rx - dy
		fild	dword ptr cs:[d2]
		fild	dword ptr cs:[rx]
		fild	dword ptr cs:[rx]
		fmul	
		fadd
		fild	dword ptr cs:[dy]
		fsub

		fist	dword ptr cs:[d2]

		
		jmp l22
	
	else22:
		; y -= 1
		dec 	word ptr cs:[y1]
		
		; x += 1
		inc		word ptr cs:[x1]
		
		
		mov		word ptr cs:[helper], 2
		; dx = dx + 2 * ry * ry
		fild	dword ptr cs:[dx2]
		fild	word ptr cs:[helper]
		fild	dword ptr cs:[ry]
		fild	dword ptr cs:[ry]
		fmul
		fmul
		fadd

		fist	dword ptr cs:[dx2]
		
		; dy = dy - 2 * rx * rx
		fild	dword ptr cs:[dy]
		fild	word ptr cs:[helper]
		fild	dword ptr cs:[rx]
		fild	dword ptr cs:[rx]
		fmul
		fmul
		fsub

		fist	dword ptr cs:[dy]
		
		
		; d2 = d2 + dx - dy + rx * rx
		fild 	dword ptr cs:[d2]
		fild 	dword ptr cs:[dx2]
		fadd
		fild 	dword ptr cs:[dy]
		fsub
		
		fild 	dword ptr cs:[rx]
		fild 	dword ptr cs:[rx]
		fmul
		fadd

		fist	dword ptr cs:[d2]
		
		

check_looop22:
	
	jmp		l22
	
	
end_check2:


	ret

	



draw_elipse3:

	; x^2/a^2 + y^2/b^2 = 1
	; x^2 * b^2 + y^2 * a^2 = a^2 * b^2
	; y^2 = a^2 * b^2 - x^2 * b^2
	; y = b * sqrt(a^2 - x^2)
	
	
	mov		cx, word ptr cs:[rx]
	
pentla1:
	push 	cx
	
	
	mov		word ptr cs:[x1], cx
	mov		word ptr cs:[x], cx
		
	finit
	fild	word ptr cs:[ry]
	fld1	
	fild	word ptr cs:[x1]
	fild	word ptr cs:[x1]
	fmul
	fild	word ptr cs:[rx]
	fild	word ptr cs:[rx]
	fmul

	fdiv

	fsub
	fsqrt
	fmul
	fist	word ptr cs:[y] 
		
	mov		ax, word ptr cs:[y]
	mov		word ptr cs:[y1], ax
	
	mov		ax, word ptr cs:[x]
	mov		word ptr cs:[x1], ax
	
	
	call 	switch_on_all_pixel

	
	mov		ax, word ptr cs:[y]
	dec 	ax
	mov		word ptr cs:[y], ax
	
	pop 	cx
	loop pentla1
	



	mov cx, word ptr cs:[ry]

pentla2:
	push 	cx
	mov		word ptr cs:[y1], cx
	mov		word ptr cs:[y], cx
		
	finit
	fild	word ptr cs:[rx]
	fld1	
	fild	word ptr cs:[y1]
	fild	word ptr cs:[y1]
	fmul
	fild	word ptr cs:[ry]
	fild	word ptr cs:[ry]
	fmul

	fdiv

	fsub
	fsqrt
	fmul
	fist	word ptr cs:[x] 
		
	mov		ax, word ptr cs:[y]
	mov		word ptr cs:[y1], ax
	
	mov		ax, word ptr cs:[x]
	mov		word ptr cs:[x1], ax
	
	
	call 	switch_on_all_pixel
	
	mov		ax, word ptr cs:[y]
	dec 	ax
	mov		word ptr cs:[y], ax
	
	pop 	cx
	loop pentla2
	ret


;--------------------------------------------------------

	

;--------------------------------------------------------
x 		dw 		?
y 		dw		?
k		db 		?
;--------------------------------------------------------
switch_on_pixel:

	mov 	ax, 0a000h ; ax ustawiam na adres segmentu
	mov 	es, ax
	mov 	ax, word ptr cs:[y] ; do ax wrzucam współrzedna y ktora chce wykorzystać Y 
	mov 	bx, 320
	mul		bx 	; dx:ax = AX*BX ; ax = 320 * y
	mov 	bx, word ptr cs:[x] ; X
	add		bx, ax ; bx = 320 * y + x
	mov		al, byte ptr cs:[k]
	mov		byte ptr es:[bx], al ; punkt na ekranie ktory mam zapalić

	ret 
;--------------------------------------------------------
	


switch_on_all_pixel:
	mov		ax, word ptr cs:[x1]
	add 	ax, word ptr cs:[x_c]
	mov		word ptr cs:[x], ax
	
	
	mov		ax, word ptr cs:[y1]
	add 	ax, word ptr cs:[y_c]
	mov 	word ptr cs:[y], ax
	
	call 	switch_on_pixel
	
	
	mov		ax, word ptr cs:[x1]
	neg		ax
	mov		word ptr cs:[x], ax
	
	mov		ax, word ptr cs:[x_c]
	add 	word ptr cs:[x], ax

	mov		ax, word ptr cs:[y1]
	mov		word ptr cs:[y], ax
	
	
	mov 	ax, word ptr cs:[y_c]
	add 	word ptr cs:[y], ax
	
	call 	switch_on_pixel
	
	
	mov		ax, word ptr cs:[x1]
	mov		word ptr cs:[x], ax
	
	mov		ax, word ptr cs:[x_c]
	add 	word ptr cs:[x], ax

	mov		ax, word ptr cs:[y1]
	neg		ax
	mov		word ptr cs:[y], ax
	
	
	mov 	ax, word ptr cs:[y_c]
	add 	word ptr cs:[y], ax
	
	call 	switch_on_pixel
	
	mov		ax, word ptr cs:[x1]
	neg		ax
	mov		word ptr cs:[x], ax
	
	mov		ax, word ptr cs:[x_c]
	add 	word ptr cs:[x], ax

	mov		ax, word ptr cs:[y1]
	neg		ax
	mov		word ptr cs:[y], ax
	
	mov 	ax, word ptr cs:[y_c]
	add 	word ptr cs:[y], ax
	
	call 	switch_on_pixel
	ret
	
new_line1 				db 10,13,'$'


print:
	mov ax, seg dane1
	mov ds,ax
	mov ah,9
	int 21h
	ret
	
error:
	mov		dx, offset usage
	call 	print
	mov		dx, offset new_line1
	call 	print
	mov		dx, offset usage2
	call 	print
	mov		dx, offset new_line1
	call 	print
	jmp		end_program
	
	

code1 ends

stack1 segment stack
		dw		300 dup(?)
pstack1 	dw 		?
stack1 ends

end start1