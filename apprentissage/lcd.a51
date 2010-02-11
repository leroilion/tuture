;Affichage LCD

lcd_rs					bit p2.0
lcd_rw					bit p2.1
lcd_en					bit p2.2
lcd_data					equ p1
lcd_busy					bit p1.7
diode						bit p3.0

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

init_ecran:				mov lcd_data,#14h				;Definir le mouvement du curseur vers la droite
							lcall en_lcd_code
							mov lcd_data,#0ch				;Allumage du lcd
							lcall en_lcd_code
							mov lcd_data,#38h				;LCD sur 2 lignes
							lcall en_lcd_code
							mov lcd_data,01h				;On efface l'afficheur
							lcall en_lcd_code
							
main:						lcall envoie_message
							lcall wait
							lcall decal_d
							lcall wait
							lcall decal_g
							lcall wait
							lcall lcd_clr
							lcall wait
							sjmp main
							
decal_d:					mov b,#16
decal_d_1:				mov lcd_data,#1ch
							lcall en_lcd_code
							lcall chrono
							dec b
							mov a,b
							jnz decal_d_1
							ret
							
decal_g:					mov b,#16
decal_g_1:				mov lcd_data,#18h
							lcall en_lcd_code
							lcall chrono
							dec b
							mov a,b
							jnz decal_g_1
							ret
							
lcd_clr:					mov lcd_data,#01h				;On efface l'afficheur
							lcall en_lcd_code
							ret


wait:						mov b,#4
wait1:					lcall chrono
							dec b
							mov a,b
							jnz wait1
							ret
							
chrono:					mov a,tmod
							anl a,#11110000b
							orl a,#00000001b
							mov tmod,a
							mov a,#5
chrono1:					mov th0,#3ch
							mov tl0,#0b0h
							clr tf0
							setb tr0
chrono2:					jnb tf0,chrono2
							dec a
							jnz chrono1
							cpl diode
							ret
							
							
envoie_message:		mov lcd_data,#80h				;Encriture sur la première ligne
							lcall en_lcd_code
							mov dptr,#message1
							lcall envoie_data
							mov lcd_data,#0c0h				;Encriture sur la première ligne
							lcall en_lcd_code
							mov dptr,#message2
							lcall envoie_data
							ret			


envoie_data:			clr a
							movc a,@a+dptr
							jz fin
							mov lcd_data,a
							lcall en_lcd_data
							mov lcd_data,#06h
							lcall en_lcd_code
							inc dptr
							sjmp envoie_data
fin:						ret


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
