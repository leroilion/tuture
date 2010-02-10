						org 0000h
						ljmp init
						
						org 0030h
message:				db 'LA reponse est 42'
						db 0
						
						org 00ffh
init:					mov 98h,#01000010b
						mov th1,#230
						
						
debut:				lcall init_ls
						mov dptr,#message
boucle:				clr a
						movc a,@a+dptr
						jz fin
						lcall emi_car
						inc dptr
						sjmp boucle
						
init_ls:				

emi_car:				jb ti,emi_car
						mov c,p
						mov acc.7,c
						mov sbuf,a
						clr ti
						ret
