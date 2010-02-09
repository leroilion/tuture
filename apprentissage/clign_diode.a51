;******************************************************
;* Faire clignoter une diode pendant 2 secondes			*
;* Auteur : Jérémy												*
;* Version : V0.0													*
;******************************************************



					org 0000h
					ljmp debut
					
					org 000bh
					ljmp interup
					
					org 0030h
debut:			mov tmod,#01h
					lcall chargement
					mov r7,#0
					clr tf0
					setb tr0
					setb ea
					setb et0
					
suite:			clr c
					mov a,r7
					subb a,#100
					jnc suite2
					
					jmp suite
					
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
						

					
