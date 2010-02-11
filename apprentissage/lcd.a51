;Affichage LCD

lcd_rs					equ p0.2
lcd_rw					equ p0.1
lcd_en					equ p0.3
lcd_data					equ p1
lcd_busy					equ p1.7

							org 0000h
							ljmp init
							
							org 0030h
message1:				db 'ISE 2010 BONJOUR'
							db 0
message2:				db '  BON  TRAVAIL  '
							db 0
							
init:						mov a,tmod						;Initialisation du timer 1
							anl a,#00001111b
							orl a,#00010000b
							mov tmod,a
							mov th1,#3ch					;Chargement de la bonne valeur dans le timer pour attendre 50 ms au démarrage
							mov tl1,#0b0h
							clr tf1							;Mise à zéro du flag timer 1
							setb tr1                   ;démarrage du timer 1
							
boucle:					jnb tf1,boucle					;Attente des 50ms

debut:					mov lcd_data,#0ch				;Allumage du lcd
							lcall en_lcd_code
							mov lcd_data,#38h				;LCD sur 2 lignes
							lcall en_lcd_code
							mov lcd_data,#80h				;Encriture sur la première ligne
							lcall en_lcd_code
							
							mov dptr,#message1
boucle1:					clr a
							movc a,@a+dptr
							jz suite
							mov lcd_data,a
							lcall en_lcd_data
							mov lcd_data,#06h
							lcall en_lcd_code
							inc dptr
							sjmp boucle1
							
suite:					mov dptr,#message2
boucle2:					clr a
							movc a,@a+dptr
							jz debut
							mov lcd_data,a
							lcall en_lcd_data
							mov lcd_data,#06h
							lcall en_lcd_code
							inc dptr
							sjmp boucle




en_lcd_code:			clr lcd_rs						;Envoie d'une instruction rs=0, rw=0, front descendant sur e
							clr lcd_rw
							setb lcd_en
							clr lcd_en
							lcall test_busy				;Attendre que le traitement par le lcd soit fait
							ret
							
en_lcd_data:			setb lcd_rs						;Envoie d'une data rs=1, rw=0, front descendant sur e
							clr lcd_rw
							setb lcd_en
							clr lcd_en
							lcall test_busy
							ret
							
test_busy:				mov lcd_data,#0ffh			;passage du port en lecture
							clr lcd_rs						;Lire busy e=1, rw=1, rs=0
							setb lcd_rw
							setb lcd_en
check_busy:				jb lcd_busy,check_busy
							clr lcd_en
							ret
							
							
							end

