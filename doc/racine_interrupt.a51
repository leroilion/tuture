 ;extraction de racine carrée"n" du nombre "N" déclenchée par l'interruption /int0
 ;N est présent en binaire sur P0, affiché en dDCB sur P2 et les 4 bits de poids fort
 ;de P3. Le bouton poussoir câblé sur P3.2 déclenche sur son front descendant l'interruption
 ;/int0 qui provoque le calcul de la racine carrée "n" affichée sur P1 en DCB.
 ;les registres: R0 sert de compteur pour "n"; R1 sert pour la succession des nombres impairs.
 
 bp		bit		p3.2;inverseur en p3.2 (/int0) pour un déclenchement
 								;du calcul de la racine carrée par interruption
 								;sur front descendant
 
 			org		00h
 			ljmp		debut
 			
 			org		03h
 			ljmp		pint0	;lors de la détection du front descendant sur p3.2
 								;le bit "ie0" de TCON est mis à 1; il est automatiquement
 								;remis à 0 lors de la prise en compte de l'interruption
 								;par le processeur
 			
 			org		30h 			
debut:	
			setb		it0	;bit de TCON demandant l'interruption /int0 sur front 
								;descendant
			
			setb		ex0	;validation de l'interruption /int0 (bit de IE)
			setb		ea		;validation générale des interruptions
			
aff_N:	mov		a,p0	; affichage en dcb du nombre en p0
			mov		b,#10	;division par 10 pour affichage en DCB.
			div		ab		;quotient dans A et reste dans B.
			xch		a,b	;pour récupérer le premier reste sans perdre le quotient.
			swap		a		;pour plcer le reste en DCB sur les poids forts.		
			orl		a,#00000100b ;masque pour ne pas modifier le BP en p3.2
			mov		p3,a	;transfert du poids faible de N sur port P3
			xch		a,b	;récupération du quotient.
			mov		b,#10 ;pour permettre la division par 10.                                   
			div		ab		;pour expression en DCB du quotient.
			swap		a		;
			orl		a,b	;pour obtenir les poids forts suivis des poids faibles.
			mov		p2,a	; affichage sur P2.
			sjmp		aff_N	
			
pint0:	
			clr		ea	 	;invalidation des interruptions pendant le traitement
								; de pint0		
			mov		a,p0	;reécupération de N
			mov		r1,#1	;initialisation des registres.
			mov		r0,#0
boucle:
			jz			aff	;Si [A]=0 affichage immédiat.
			clr		c		;obligatoire avant une soustraction.
			subb		a,r1	;soustraction d'un nombre impair.
			jc			aff	;si carré non parfait affichage de n
			inc		r0		;incrémentation du compteur.
			inc		r1
			inc		r1		;passage au nombre impair suivant.			
			sjmp		boucle
			
aff:
			mov		a,r0	;transfert de n dans A
			mov		b,#10	;pour affichage en DCB
			div		ab
			swap		a
			orl		a,b
			mov		p1,a	;affichage de n sur P1
			clr		ie0	;pour invalider une éventuelle demande d'interruption
								;survenue pendant le traitement de celle en cours.
			setb		ea		;validation des interruptions pour un nouveau calcul.
			reti				;retour d'interruption
			end	
			
 			
