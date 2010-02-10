						org 0000h
						ljmp debut1
						
						org 0030h
message:				db 'LA reponse est 42'
						db 0
						
						org 00ffh		
debut1:				lcall init_ls					
fin:					jb P1.7,fin
						lcall debut
						sjmp fin						
						
debut:				lcall init_ls
						mov dptr,#message
boucle:				clr a
						movc a,@a+dptr
						jz fin
						lcall emi_car
						inc dptr
						sjmp boucle
						
init_ls:				mov 98h,#01000000b
						mov th1,#230
						mov tmod,#00100000b
						setb tr1
						ret

emi_car:				mov c,p
						;mov acc.7,c
						mov sbuf,a
						clr ti
						jb ti,emi_car
						ret
						
						
						end
