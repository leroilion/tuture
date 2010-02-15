;soustraction et addition sur 16 bits
;commande du moteur et du servo de direction
;l'action sur un bouton poussoir met le bit a 0
;au debut les roues sont droites et le moteur est a l'arret
;l'appui sur BP1 provoque(progressivement) l'acceleration et le braquage
; des roues a gauche la led s'allume
;l'appui sur BP0 provoque(progressivement) a deceleration et le braquage
; des roues a droite la led s'eteind
dir     		    bit     P1.4   ; commande de direction
mot    			 bit     p1.5   ; commande du moteur
tir    			 bit     p3.5   ; commande du tir
ledmC  			 bit     p1.0   ; indique uC actif(led allumee si p1.0=0)
bp0     			 bit     p1.1   ; pour l'etalonnage et calibrage
bp1    			 bit     p1.2   ; pour calibrage
capg   			 bit     p1.7   ; capteur gauche
capd   			 bit     p1.6   ; capteur droit

;bit de flag
finint 			 bit     	7Fh    ; indicateur de preparation du timer0

; declaration des octets
; valeurs de reference a charger dans Timer0
vd1h			equ		0fah		;(65536-1500)			
vd1l			equ		24h		;
vdr1h			equ		0fch		;(65536-1000)
vdr1l			equ		18h
vmr1h			equ		0c1h		;(65536-16000)
vmr1l			equ		80h

;memoires recevant les valeurs a charger dans Timer0 
;pour realiser les durees de:

vd2l			equ		7fh		; la direction
vd2h			equ		7eh
vdr2l			equ		7dh		; reste de la direction
vdr2h			equ		7ch
vm2l			equ		7bh		; du moteur
vm2h			equ		7ah
vmr2l			equ		79h		; reste du moteur
vmr2h			equ		78h

vth0			equ		6eh		;memoire intermediaire recevant les valeurs
vtl0			equ		6fh		;a transferer dans th0 et tl0
;----------------------------------------------------------------------
; plage des interruptions

				org		0000h			;reset
				ljmp		debut
				
				org		0003h			;interruption int0

				org		000Bh			;interruption timer0
				ljmp		pinttimer0

				org		0013h			;interruption int1
                              	         
				org		001Bh			;interruption timer1 

				org		0023h			;interruption liaison serie

				org		0030h
						
;-------------------------------------------------------------------
;programme d'interruption du Timer0. La periode est de 20ms,
;separee en 4 durees:
;d= direction de 1 a 2ms,
;/d= reste de la direction pour completer a 2,5ms,
;m= moteur de 1 a 2ms,
;/m= reste du moteur pour completer a 17,5ms.

pinttimer0:
				push		psw
				push		acc

tr0a0: 
				cjne		r0,#0,tr0a1		;direction
				mov		vtl0,vd2l
				mov		vth0,vd2h
				mov		r0,#1
				setb		dir
				sjmp		relancet0

tr0a1:  
				cjne		r0,#1,tr0a2		;reste de la direction 
       		mov		vtl0,vdr2l
        		mov		vth0,vdr2h
        		mov		r0,#2
       		clr     	dir
       		sjmp		relancet0

tr0a2:  
				cjne		r0,#2,tr0a3		;moteur
       		mov		vtl0,vm2l
        		mov		vth0,vm2h
        		mov		r0,#3
				setb		mot
        		sjmp		relancet0

tr0a3:  
				mov		vtl0,vmr2l		;reste du moteur
				mov		vth0,vmr2h
				clr		mot
				mov		r0,#0
				setb		finint    		;pp peut traiter des nouvelles valeurs 
        
relancet0:
				clr		tr0      ; arret du timer
				mov		a,tl0    ; lecture de la valeur a charger
				add		a,#08		; addition avec le reste du timer
				addc		a,vtl0   ; valeur a ajuster
				mov		tl0,a    ; chargement du poids faible du timer0
				mov		a,vth0   ; lecture de la valeur a charger dans th0
				addc		a,th0    ; pour tenir compte du debordement
				mov		th0,a    ; chargement du poids fort du timer0
				setb		tr0      ; lancement du timer

restit:
				pop		acc
				pop		psw

				reti
;-----------------------------------------------

;augmentation de la durée moteur selon R7
sousmot: 								 
						
				clr		c
				mov		a,vm2l
				subb		a,r7
				mov		vm2l,a
				mov		a,vm2h
				subb		a,#00h
				mov		vm2h,a 
restmot2:
				clr		c
				mov		a,vmr2l
				add		a,r7
				mov		vmr2l,a
				mov		a,vmr2h
				addc		a,#00h
				mov		vmr2h,a
				ret
;-------------------------------------------------------------------
;diminution de la duree moteur selon r7
addmot:
				clr		c
				mov		a,vm2l
				add		a,r7
				mov		vm2l,a
				mov		a,vm2h
				addc		a,#00h
				mov		vm2h,a
restmot3:
				clr		c
				mov		a,vmr2l
				subb		a,r7
				mov		vmr2l,a
				mov		a,vmr2h
				subb		a,#00h
				mov		vmr2h,a
				ret 
;--------------------------------------------------------------------
;virage a gauche selon R6
virgauche:
				clr		c
				mov		a,vd2l
				add		a,r6
				mov		vd2l,a
				mov		a,vd2h
				addc		a,#00h
				mov		vd2h,a
restdir3:
				clr		c
				mov		a,vdr2l
				subb		a,r6
				mov		vdr2l,a
				mov		a,vdr2h
				subb		a,#00h
				mov		vdr2h,a
				ret
;----------------------------------------------------------------------
;virage a droite selon R6
virdroite:
				clr		c
				mov		a,vd2l
				subb		a,r6
				mov		vd2l,a
				mov		a,vd2h
				subb		a,#00h
				mov		vd2h,a 
restdir4:
				clr		c
				mov		a,vdr2l
				add		a,r6
				mov		vdr2l,a
				mov		a,vdr2h
				addc		a,#00h
				mov		vdr2h,a
				ret
 

;----------------------------------------------------------------------
;nombre de fois 20ms

durecom:										 ; gère r1=Nb de commandes
												 ;soit r1*20ms 
				jnb		finint,durecom
				clr		finint
				djnz		r1,durecom 		 ; r1 contient le Nb de commandes 
				ret

;------------------------------------------
debut:
				mov		sp,#30h		;pour sortir de la zone de banque
				mov		tmod,#21h	; T1 mode 2(autoreload),T0 16bits
				mov		th1,#0E6h	; LS a 1200bits/s quartz 12MHz
				mov		tl1,#0E6h	; pour le demarage. 
				mov		scon,#52h	; mode 1 10 bits, ren=1,ti=1
				setb		tr1			; lance timer1 pour diviser fqz(baudrate)
				clr		dir 
				clr		mot
				clr		finint		; pas de fin d'interruption
				
; validation des interruptions du timer 0
				setb		et0			; enable timer0          
        		setb		ea				; enable all ,validation generale
        		clr		pt0			; interruption timer0 en priorite 0
        		
        		cpl		ledmC
        		mov		r6,#2			; increment pour la direction
        		mov		r7,#1			; increment pour la vitesse
				mov		vd2l,#vd1l	; chargement de la valeur de repos 1500us
				mov		vd2h,#vd1h	; pour la direction
				mov		vdr2l,#vdr1l; chargement du complement (1000us)a 2,5ms
				mov		vdr2h,#vdr1h; pour la direction 
			
				mov		vm2l,#vd1l	; chargement de la valeur de repos 1500us
				mov		vm2h,#vd1h	; pour le moteur
				mov		vmr2l,#vmr1l; complement moteur
				mov		vmr2h,#vmr1h
				
				mov		r0,#0			; debut du traitement des signaux dir et mot
				mov		th0,#0FFh	; pour lancement du timer 0 premiere fois
				mov		tl0,#0F0h	; pour lancement du timer 0 premiere fois
				setb		tr0			; lancement du timer0
											; ensuite le timer se relance tout seul
	
				mov		r1,#1      ; 1x20ms = 20ms
				lcall		durecom  

attent1:
				jnb    P1.7,Attent1
				lcall  Adroite
				 
attent2:
				jnb    P1.6,attent2     
				lcall  Agauche 
		 
Adroite :   lcall   ralentir
            lcall   tournegauche 
            
Agauche :   lcall    ralentir 
            lcall    tournedroite



		  
reglage:
				mov		a,p1
				rrc		a
				rrc		a				; recuperation de BP0 dans Carry
				jnc		ralentir		; si BP0 = 0 decelerer
				rrc		a				; recuperation de BP1
				jnc		augmenter	; si BP1 = 0 accelerer
				sjmp		reglage		; attente de l'appui sur un bouton
ralentir:
				cpl		ledmc
				lcall		decelere		; sous prog de decelaration
				lcall		tournedroite	;sous prog de virage a droite
				mov		r1,#1
				lcall		durecom
				sjmp		reglage
augmenter:
				cpl		ledmc
				lcall		accelere		; sous prog d'acceleration
				lcall		tournegauche	;sous prog de virage a gauche
				mov		r1,#1
				lcall		durecom
				sjmp		reglage
;--------------------------------------------------------------------
;deceleration: diminuer la duree m de l'impulsion moteur 
;revient a augmenter la valeur vm a charger dans Timer 0: 
;vm=(65536-m)
decelere:			
				lcall		addmot			;calcul des valeurs a charger dans T0
				mov		a,vm2h			; test a la valeur max de vm
				cjne		a,#0fch,diffh2	; saut si vm2h different de 0fch
				mov		a,vm2l
				cjne		a,#18h,diffl2
				ljmp		sortie_dec
diffl2:
				jc			sortie_dec
				sjmp		suph2
diffh2:
				jc			sortie_dec
suph2:
				mov		vm2h,#0fch	;chargement des valeurs max
				mov		vm2l,#18h	;(65536-1000)=64536d=fc18h
				mov		vmr2h,#0bfh	;reste du moteur
				mov		vmr2l,#8ch	;(65536-16500)=49036d=bf8ch
												
sortie_dec:	            																	
				ret
;-------------------------------------------------------------
;acceleration: augmenter la duree m de l'impulsion moteur revient a
;diminuer la valeur vm a charger dans Timer0: vm=(65536-m)

accelere:
				lcall		sousmot		;calcul des valeurs a charger dans T0
				mov		a,vm2h		; test a la valeur min de vm
				cjne		a,#0f8h,diffh1
				mov		a,vm2l
				cjne		a,#30h,diffl1

diffh1:
				jc			infh1
				ljmp		sortie_acc
diffl1:
				jc			infh1
				ljmp		sortie_acc
infh1:
				mov		vm2h,#0f8h	;chargement de la valeur min 
				mov		vm2l,#30h	;(65536-2000)=63536d=f830h
				mov		vmr2h,#0c3h	;reste de l'impulsion 
				mov		vmr2l,#74h	;(65536-15500)=50036d=c374h
				
sortie_acc:												
        		ret
;------------------------------------------------------------------------
tournedroite:
       		lcall		virdroite		;calcul des valeurs a charger dans T0
            mov		a,vd2h
            cjne		a,#0fch,diffh3
            mov		a,vd2l
            cjne		a,#18h,diffl3
            ljmp		sortie_droite3
diffl3:
				jc			sortie_droite3
				sjmp		suph3
diffh3:
				jc			sortie_droite3
suph3:
				mov		vd2h,#0fch	;chargement des valeurs max
				mov		vd2l,#18h
				mov		vdr2h,#0bfh
				mov		vdr2l,#8ch
				 
sortie_droite3:
				ret
;-------------------------------------------------------------------------					
tournegauche:
				lcall		virgauche	;calcul des valeurs a charger dans T0
				mov		a,vd2h
				cjne		a,#0f8h,diffh4
				mov		a,vd2l
				cjne		a,#30h,diffl4

diffh4:
				jc			infh4
				ljmp		sortie_gauche2
diffl4:
				jc			infh4
				ljmp		sortie_gauche2
infh4:
				mov		vd2h,#0f8h	;charge la valeur max de l'impulsion
				mov		vd2l,#30h	;07d0h=2000d
				mov		vdr2h,#0c3h	;reste de l'impulsion 3c8ch=15500d
				mov		vdr2l,#74h
	
sortie_gauche2:
				ret
;--------------------------------------------------------------------------				
        		end



				

