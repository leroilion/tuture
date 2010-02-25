					org	0h
					ljmp	Debut
					org	30h					

LCD_RS			bit	P0.5
LCD_RW			bit	P0.6
LCD_E				bit	P0.7

TG					bit	7fh
TC             bit	7eh
TD					bit	7dh

							;0123456789ABCDEF0123456789ABCDEF01234567
MsgI:				db		'  ISE  EXPRESS  '
					db		0
MsgR:				db		'    RECEPTION   '
					db		0
Msg4:				db		'   PAS DE TIR   '
					db		0
MsgD:				db		'  TIR A DROITE  '
					db		0
MsgC:				db		'  TIR AU CENTRE '
					db		0
MsgG:				db		'  TIR A GAUCHE  '
					db		0
MsgT:				db		'Pts '
					db		0
					;mov	P1,#data
en_lcd_code:	clr	LCD_RS
					clr	LCD_RW
					setb	LCD_E
					clr	LCD_E
					lcall	test_busy
					ret

					;mov	P1,#data
en_lcd_data:	setb	LCD_RS
					clr	LCD_RW
					setb	LCD_E
					clr	LCD_E 
					lcall	test_busy
					ret
					
					
test_busy:		mov	p2,#0ffh
					clr	LCD_RS
					setb	LCD_RW
					setb	LCD_E
check_busy:		jb		p2.7,check_busy	;attente du passage à 0 de BF
					clr	LCD_E
					ret
										
attendre_40ms: anl	TMOD,#0F0h			
					orl	TMOD,#01h
			
					mov	TH0,#063h
					mov	TL0,#0C0h
					setb 	TR0
					
					jnb 	TF0,$
					
					clr	TR0
					clr	TF0
					
					orl	TMOD,#20h
									
					mov	TH1,#0E6h
					mov	TL1,#0E6h
					setb	TR1
					ret

attendre_200ms:mov 	R7,#5
					sjmp  boucle_R7
					
boucle_R7:		lcall	attendre_40ms
					djnz	R7,boucle_R7
					ret

effacer:			mov	P2,#01h				;effacer ecran
					lcall	en_lcd_code
					ret

ligne_1:			mov	P2,#80h			
					lcall	en_lcd_code
					ret

ligne_2:			mov	P2,#0C0h			
					lcall	en_lcd_code
					ret										

inc_curseur:	mov	P2,#06h			
					lcall	en_lcd_code
					ret
					
dec_droite:		mov	P2,#1Dh
					lcall en_lcd_code
					ret	
					
init:				lcall	attendre_40ms
					clr	P1.3
					clr	P1.2
					mov	SCON,#01010000b	;partie reception				
					
					mov	R1,#30h
					mov	R2,#30h
					
					mov	P2,#14h				;curseur vers droite
					lcall	en_lcd_code
					mov	P2,#0Ch				;allumer ecran
					lcall	en_lcd_code
					mov	P2,#38h				;mode 2 lignes
					lcall	en_lcd_code
					
					ret


Total:			;mov	P2,#0Ch				;allumer ecran
					;lcall	en_lcd_code
					lcall	ligne_2					
					mov	dptr,#MsgT
					;lcall	en_lcd_data
					lcall	env_chn
					mov	P2,R1
					lcall	en_lcd_data
					lcall	env_chn
					
					mov	P2,#2fh
					lcall	en_lcd_data
					lcall	env_chn
					
					push	acc
					mov	a,#00h
					mov	b,#2
					jnb	TG,m1
					inc	a
m1:				mul	ab
					jnb	TC,m2
					inc	a
m2:				mul	ab
					jnb	TD,m3
					inc	a
m3:				anl	a,#00000111b
					;jz		Fina
					
					mov	P2,#47h
					lcall	en_lcd_data
					lcall	env_chn
					mov	b,#30h
					jnb	ACC.2,affg
					inc	b
affg:				mov	P2,b
					lcall	en_lcd_data
					lcall	env_chn
					
					mov	P2,#43h
					lcall	en_lcd_data
					lcall	env_chn
					mov	b,#30h
					jnb	ACC.1,affc
					inc	b
affc:				mov	P2,b
					lcall	en_lcd_data
					lcall	env_chn					
					
					mov	P2,#44h
					lcall	en_lcd_data
					lcall	env_chn
					mov	b,#30h
					jnb	ACC.0,affd
					inc	b
affd:				mov	P2,b
					lcall	en_lcd_data
					lcall	env_chn					  

Fina:				mov	P2,#2fh
					lcall	en_lcd_data
					lcall	env_chn
					mov	P2,R2
					lcall	en_lcd_data
					lcall	env_chn
					pop	acc
										
					ret	
						
Env_chn:			clr	a
					movc	a,@a+dptr
					jz		Fin
					mov	P2,a
					lcall	en_lcd_data
					lcall inc_curseur
					inc	dptr
					sjmp	Env_chn

Fin:				ret

Debut:			lcall	init

Loop:				lcall	attendre_40ms
					clr	p1.3		;arreter la sirene
					clr	p1.2		;eteindre le laser
					clr	TG
					clr	TC
					clr	TD
					inc	R2
					lcall effacer
					mov	dptr,#MsgI
					;lcall	en_lcd_data
					lcall env_chn
					lcall	Total
										
					jnb	RI,$
					
tir:				lcall	attendre_40ms
					jnb	RI,Loop
					
					mov	A,SBUF
					clr	ACC.7
					
					setb	p1.3		;lancer la sirene
					setb	p1.2		;tirer

					clr	RI
					lcall	ligne_1

					cjne	A,#34h,tir_droite					
					lcall effacer
					mov	dptr,#Msg4
					;lcall	en_lcd_data
					lcall env_chn
					lcall	Total
					sjmp	Restart
					
tir_droite:		cjne	A,#44h,tir_centre
					jb		TD,Restart
					setb	TD
					inc	R1
					lcall effacer
					mov	dptr,#MsgD
					;lcall	en_lcd_data
					lcall env_chn
					lcall	Total
					sjmp	Restart
					
tir_centre:		cjne	A,#43h,tir_gauche
					jb		TC,Restart
					setb	TC
					inc	R1
					inc	R1
					inc	R1
					lcall effacer
					mov	dptr,#MsgC
					;lcall	en_lcd_data
					lcall env_chn
					lcall	Total
					sjmp	Restart
					
tir_gauche:		cjne	A,#47h,Restart
					jb		TG,Restart
					setb	TG
					inc	R1
					lcall effacer
					mov	dptr,#MsgG
					;lcall	en_lcd_data
					lcall env_chn
					lcall	Total
					
Restart:			sjmp	tir
					
					end
					
