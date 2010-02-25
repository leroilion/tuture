					org	0h 
					ljmp	Debut
					org	30h					

LCD_RS			bit	P0.5
LCD_RW			bit	P0.6
LCD_E				bit	P0.7
comMaitre		bit	p3.1

TG					bit	7fh
TC             bit	7eh
TD					bit	7dh
flag				bit	7ch
Dix				bit	7bh

							;0123456789ABCDEF0123456789ABCDEF01234567
MsgI:				db		'  ISE  EXPRESS  '
					db		0
MsgF:				db		'**Nouveau Tour**'
					db		0
Msg4:				db		'   PAS DE TIR   '
					db		0
MsgD:				db		'  TIR A DROITE  '
					db		0
MsgC:				db		'  TIR AU CENTRE '
					db		0
MsgG:				db		'  TIR A GAUCHE  '
					db		0
MsgT:				db		'Points:'
					db		0
MsgFin:			db		'FIN'
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
					
					anl	TMOD,#0F0h			
					orl	TMOD,#20h
									
					mov	TH1,#0E6h
					mov	TL1,#0E6h
					setb	TR1
					ret 
attendre_3s:	mov 	R7,#75
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
					
init:				clr	P1.3
					clr	P1.2
					clr	Dix
					clr	flag 					
					lcall	attendre_40ms					
					mov	SCON,#01010000b	;partie reception									
					mov	R1,#30h				;initialisation du compteur de points
					mov	R2,#30h
					mov	P2,#14h				;curseur vers droite
					lcall	en_lcd_code
					mov	P2,#0Ch				;allumer ecran
					lcall	en_lcd_code
					mov	P2,#38h				;mode 2 lignes
					lcall	en_lcd_code
					ret


Total:			lcall	ligne_2					
					mov	dptr,#MsgT
					lcall	env_chn
					
					mov	A,R1					
					subb	A,#3Ah
					jc		Points
					
					setb	Dix
					
					add	A,#30h
					mov	R1,A					
					
Points:			jnb	Dix,Chiffre
					mov	P2,#31h
					lcall	en_lcd_data
					lcall	env_chn
					
Chiffre:			mov	P2,R1
					lcall	en_lcd_data
					lcall	env_chn
					
					mov	P2,#20h
					lcall	en_lcd_data
					lcall	env_chn
					
					cjne	R2,#34h,Laps
					mov	dptr,#MsgFin
					lcall env_chn
					sjmp	Fin
					
Laps:				mov	P2,R2
					lcall	en_lcd_data
					lcall	env_chn
					mov	P2,#2fh
					lcall	en_lcd_data
					lcall	env_chn
					mov	P2,#33h
					lcall	en_lcd_data
					lcall	env_chn
					
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


;***************************************************************
;******************debut du programme***************************
;***************************************************************


Debut:			lcall	init

					
					
					
Loop:				clr	p1.3		;arreter la sirene
					clr	p1.2		;eteindre le laser
					
					clr	TG			;flag de tir
					clr	TC       ;flag de tir
					clr	TD       ;flag de tir
					clr	flag
				   lcall effacer
					mov	dptr,#MsgI
					lcall env_chn
					lcall	Total
										
					jnb	RI,$
					
balise:			jnb	RI,Loop	;attente de reception	
					mov	A,SBUF
					clr	ACC.7					
					lcall	ligne_1						
					
					cjne	A,#30h,tir					
					lcall effacer
					mov	dptr,#MsgF
					jb		flag,Restart
					inc	R2
					setb	flag
					clr	comMaitre
					lcall	attendre_3s					
										
					cjne	R2,#34h,att
					lcall effacer

					lcall	Total											
					sjmp	Restart
					
att:				setb	comMaitre
					lcall env_chn
					lcall	Total
					sjmp	Restart

tir:				cjne	A,#34h,tir_droite
					setb	p1.3		;lancer la sirene
					setb	p1.2		;tirer
					lcall ligne_1	;se placer sur la ligne 1			
					lcall effacer
					mov	dptr,#Msg4
					lcall env_chn
					lcall	Total
					sjmp	Restart
					
tir_droite:		cjne	A,#44h,tir_centre
					lcall effacer
					mov	dptr,#MsgD
					lcall env_chn
					jb		TD,Restart
					setb	TD
					inc	R1
					lcall	Total
					sjmp	Restart
					
tir_centre:		cjne	A,#43h,tir_gauche
					lcall effacer
					mov	dptr,#MsgC
					lcall env_chn
					jb		TC,Restart
					setb	TC
					inc	R1
					inc	R1
					inc	R1
					lcall	Total
					sjmp	Restart
					
tir_gauche:		cjne	A,#47h,Restart
					lcall effacer
					mov	dptr,#MsgG
					lcall env_chn
					jb		TG,Restart
					setb	TG
					inc	R1
					lcall effacer
					lcall	Total
					
Restart:			clr	RI
					lcall	attendre_40ms
					ljmp	balise									
					end
					
