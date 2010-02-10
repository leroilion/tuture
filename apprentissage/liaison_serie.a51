						org 0000h
						ljmp debut1
						
						org 0030h
message:				db 'LA reponse à la vie, l univers et tout le reste est 42'
						db 0dh
						db 0
							
debut1:				lcall init_ls					
fin:					clr p1.6
						jb P1.7,fin
						setb p1.6
						lcall debut
						sjmp fin						
						
debut:				;lcall init_ls
						mov dptr,#message
boucle:				clr a
						movc a,@a+dptr
						jz fin
						lcall emi_car
						inc dptr
						sjmp boucle
					
init_ls:				mov scon,#01000010b
						mov th1,#230
						mov tmod,#00100000b
						mov tl1,#230
						setb tr1
						ret

emi_car:				mov c,p
						mov acc.7,c
						mov sbuf,a
						;clr ti
attente:				jnb ti,attente
						clr ti
						ret
						
						
						end
