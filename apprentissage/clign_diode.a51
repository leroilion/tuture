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
					acall chargement
					mov a,#40
					clr tf0
					setb tr0
					setb ea
					setb et0
					
suite:			jmp suite
				
chargement:		mov th0,#0c3h
					mov tl0,#50h
					ret
				
interup:			clr tr0
					clr tf0
					dec a
					jnz continue
					cpl p3.1
					mov a,#40
continue:		acall chargement
					setb tr0
					reti
					
					end
						

					
