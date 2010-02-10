;******************************************************
;* Faire clignoter une diode pendant 2 secondes			*
;* Auteur : Jérémy												*
;* Version : V0.0													*
;******************************************************



					org 0000h
					ljmp init
					
					org 000bh
					ljmp interup
					
					org 0030h
init:				mov tmod,#01h
					lcall chargement
					mov r7,#10
					clr tf0
					setb tr0
					setb ea
					setb et0
					
debut:			lcall chrono
					lcall affich
					sjmp debut
					
affich:			mov a,R1
					mov B,#10
					div ab
					swap a
					orl a,b
					mov P0,a
					mov a,R2
					mov B,#10
					div ab
					swap a
					orl a,b
					mov P1,a
					mov a,R3
					mov B,#10
					div ab
					swap a
					orl a,b
					mov P2,a
					ret				
					
chrono:			clr c
					mov a,R1
					subb a,#100
					jnc debut
					mov r1,#0
					inc r2
					clr c
					mov a,R2
					subb a,#60
					jnc debut
					mov R2,#0
					inc R3
					clr c
					mov a,R3
					subb a,#60
					jnc debut
					mov R3,#0
					ljmp debut
					
chargement:		mov th0,#0d8h
					mov tl0,#0f0h
					ret
				
interup:			clr tr0
					clr tf0
					inc r7
					
continue:		lcall chargement
					setb tr0
					reti
					
					end
						

					
