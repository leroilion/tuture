;************************************************************************
;* Asservissement de la voiture en direction                            *
;* Version : v0.0                                                       *
;* Le 17/02/2010                                                        *
;* Cette partie gère l'interruption du timer0 pour l'asservissement     *
;* du servomoteur et du moteur														*
;************************************************************************



;************************************************************************
;* Definition des ports et des bit													*
;* Entrée : capteur droit et capteur gauche, B.P. droite et gauche		*
;* Sortie : moteur, servo de direction, led d'indication                *
;************************************************************************

moteur						bit	p1.5
direction					bit	p1.4
led							bit	p1.0
bpdroit						bit	p1.1
bpgauche						bit	p1.2
capteur_droit				bit	p3.3														;Sur interruption INT0
capteur_gauche				bit	p3.2              									;Sur interruption INT1

;************************************************************************
;* Definition des variables (octet et bit)										*
;* Bit : mutex																				*
;* Byte : direction (low, high, reste, normal) et idem pour le moteur	*
;************************************************************************

mutex							bit	7fh														;Permet de locker le changement de valeur dans le timer pour ne pas perturber un cycle
dir_ou_mot					bit	7eh														;Pour la conversion pourcentage ==> hexa, permet de savoir s'il s'agit de la direction ou du moteur
dir_low						equ	7fh														;Variable contenant la valeur à charger dans le timer pour la direction
dir_high						equ	7eh
dir_rest_low				equ	7dh
dir_rest_high				equ	7ch
mot_low						equ	7bh
mot_high						equ	7ah
mot_rest_low				equ	79h
mot_rest_high				equ	78h

tim_low						equ	6eh														;Variable intermédiaire pour le timer	
tim_high						equ	6fh

;Le registre R0 servira à connaitre la phase du timer 0
;Les registres R7,R6 et R5,R4serviront de variation par rapport à la valeur par défaut sur les moteurs et la direction (R7,R6 pour mot et R5,R4 pour dir)
;Les registres R3 et R2 serviront pour stocker le PWM sur 8 bit

;************************************************************************
;* Defintion des valeurs (#define)													*
;* Valeur de timer de référence														*
;************************************************************************

dir_ref_low					equ	0fah
dir_ref_high				equ	24h
dir_ref_rest_low			equ	0fch
dir_ref_rest_high			equ	18h
mot_ref_low					equ	0fah
mot_ref_high				equ	24h
mot_ref_rest_low			equ	0c1h
mot_ref_rest_high			equ	80h

;************************************************************************
;* Debut du programme : ou écrire													*
;************************************************************************

								org 	0000h
								ljmp	init
								
								org	0003h														;int 0
								
								org	000bh             									;timer 0
								ljmp	int_timer_0
								
								org	0013h														;int 1
								
								org	001bh														;timer 1
								
								org	0023h														;liaison serie
								
								org	0030h														;C'est ici que l'on va écrire le coeur du programme
								
;************************************************************************
;* Initialisation																			*
;*	Phase d'initialisation des timers (0 pour l'instant)						*
;* Changement de position de la pile												*
;************************************************************************

init:							mov	sp,#30h													;On change le StackPointer de place pour ne pas mettre la pile dans la zone de banque
								clr	direction
								clr	moteur
								clr	mutex

;Activation des interruptions :								
								setb	et0														;activation du timer 0
								setb	ea															;activation de l'ensemble des interruptions
								clr	pt0														;Placer l'interruption timer 0 en priorité
								
;Mise en place des valeurs par défaut :
								mov	dir_low,#dir_ref_low								
								mov	dir_high,#dir_ref_high
								mov	dir_rest_low,#dir_ref_rest_low
								mov	dir_rest_high,#dir_ref_rest_high
								mov	mot_low,#mot_ref_low
								mov	mot_high,#mot_ref_high
								mov	mot_rest_low,#mot_ref_rest_low
								mov	mot_rest_high,#mot_ref_rest_high
								
;Mise en place de la phase 1 pour le cycle asservissement :
								mov	r0,#0

;Lancement du timer 0 :
								mov 	th0,#0ffh												;On le lance proche de la fin pour que le cycle asservissement commence
								mov 	tl0,#0f0h                                    ;le plus rapidement possible
								setb 	tr0
								
;Saut au debut du main :								
								ljmp	main
								
;************************************************************************
;* Main : boucle principal																*
;************************************************************************

main:							mov r2,#128
								mov r3,#128
								setb dir_ou_mot
								lcall conv_pourcent_nb
								clr dir_ou_mot
								lcall conv_pourcent_nb
								lcall chargement
								sjmp main

;************************************************************************
;* Interruption timer 0 pour le cycle asservissement							*
;* Check de r0 pour connaitre la phase dans laquelle nous sommes			*
;* Rechargement du timer 0																*
;*	Prise du mutex de la phase 0 à 3 (une fois la dernière phase lancée,	*
;* On libère le mutex																	*
;************************************************************************

int_timer_0:				push	psw														;Sauvegarde du psw et de l'accumulateur
								push	acc
								
;Prise du mutex
								setb	mutex
								
asserv0:						cjne	r0,#0,asserv1											;Si ce n'est pas la phase 0, on va tester la phase 1
								mov	tim_low,dir_low
								mov	tim_high,dir_high
								mov 	r0,#1
								setb	direction
								sjmp	relancer
								
asserv1:						cjne	r0,#1,asserv2
								mov	tim_low,dir_rest_low
								mov	tim_high,dir_rest_high
								mov 	r0,#2
								clr	direction
								sjmp	relancer		
								
asserv2:						cjne	r0,#2,asserv3
								mov	tim_low,mot_low
								mov	tim_high,mot_high
								mov 	r0,#3
								setb	moteur
								sjmp	relancer		
								
asserv3:						mov	tim_low,mot_rest_low
								mov	tim_high,mot_rest_high
								mov 	r0,#0
								clr	moteur
								clr	mutex
								sjmp	relancer	
								
;Relancer le timer :
relancer:					clr	tr0
								mov	a,tl0
								add	a,#08
								addc	a,tim_low
								mov	tl0,a
								mov	a,tim_high
								addc	a,th0
								mov	th0,a
								setb	tr0
								
;Remise dans la pile de psw et psw
								pop	acc
								pop	psw
								
								reti	
								
								
;***************************************************************
;* Conversin pourcentage tic												*
;* Le but est de passer de la valeur en pourcentage de l'état  *
;* du moteur et direction en nombre à ajouter ou soustraire		*
;* On va utiliser des entiers signé (128 étant le zéro)			*
;***************************************************************

conv_pourcent_nb:			jnb	dir_ou_mot,conv_pourcent_nb_mot		;Si le bit vaut 0, on va faire la conversion pour le moteur
								mov	a,R2
								mov	b,#4
								mul	ab
								mov	r4,a
								mov	r5,b
								ret
								
conv_pourcent_nb_mot:	mov	a,r3
								mov	b,#2
								mul	ab
								mov	r6,a
								mov	r7,b
								
								ret
								
;*********************************************************************
;* Chargement de la nouvelle valeur pour la direction et le moteur   *	
;* si le mutex est libre.															*
;*********************************************************************

chargement:					jb		dir_ou_mot,chargement_fin
;On commence par la direction, normal
								clr 	c
								mov	a,#0dch
								add	a,r4
								mov	6dh,a
								mov	a,#03h
								addc	a,r5
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	dir_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	dir_high,a
								
;Ensuite, le complément de la direction 
								clr 	c
								mov	a,#0e8h
								subb	a,r4
								mov	6dh,a
								mov	a,#05h
								subb	a,r5
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	dir_rest_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	dir_rest_high,a
								
;Puis on s'occupe du moteur
								clr 	c
								mov	a,#0dch
								add	a,r4
								mov	6dh,a
								mov	a,#03h
								addc	a,r5
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	dir_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	dir_high,a
								
;Ensuite, le complément de la direction
								clr 	c
								mov	a,#080h
								subb	a,r4
								mov	6dh,a
								mov	a,#40h
								subb	a,r5
								mov	6ch,a
								clr	c
								mov	a,#0ffh
								subb	a,6dh
								mov	dir_rest_low,a
								mov	a,#0ffh
								subb	a,6ch
								mov	dir_rest_high,a

chargement_fin:			ret
								
								end
