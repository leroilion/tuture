 ;extraction de racine carrée
 bp		bit		p2.7;inverseur en p2.7
 
 			org		00h
 			ljmp		debut
 			org		30h
 			
debut:						; afficher la valeur sur l'état 0 du BP
			mov		a,p0	; affichage en dcb du nombre en p0
			mov		b,#10	;division par 10 le reste de poids faible est dans B
			div		ab
			orl		b,#10000000b ;masque pour ne pas modifier le BP
			mov		p2,b	;transfert du poids faible sur port P2
			mov		b,#10 ; à nouveau division du reste par 10                                   
			div		ab
			swap		a
			orl		a,b
			mov		p3,a
bpa0:
			jnb		bp, debut
bpa1:
			jb			bp,bpa1
			mov		a,p0
			mov		r1,#1
			mov		r0,#0
boucle:
			jz			aff
			clr		c
			subb		a,r1
			jc			aff
			inc		r1
			inc		r1
			inc		r0
			sjmp		boucle
			
aff:
			mov		a,r0
			mov		b,#10
			div		ab
			swap		a
			orl		a,b
			mov		p1,a
			sjmp		debut
			end	
			
 			
